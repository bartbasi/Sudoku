extends "res://tests/unit_test.gd"
## Phase 6 saving: at the end of the frame App takes GameSession.save_snapshot()
## on the main thread and the SaveWriter worker runs snapshot_to_dict() before
## it writes. The file on disk is exactly what to_dict() would have saved, a
## conversion that fails writes nothing, and the main thread cost stays small
## at a 2000 step undo history (the timing is printed).

const Fx := preload("res://tests/save/save_fixtures.gd")
const WAIT_MS: int = 20000
## The undo history length the main thread cost is measured at.
const STEPS: int = 2000
## Saves timed per method, after one warm up.
const ROUNDS: int = 10


func _app_with_puzzle(dir: String) -> AppService:
	var app: AppService = AppService.new()
	app.save_dir = dir
	app.use_thread = false
	app.load_all()
	app.start_new_puzzle(Levels.BEGINNER)
	app.use_thread = true
	return app


func _writer(app: AppService) -> SaveWriter:
	return app.get(&"_writer") as SaveWriter


func _wait_for_worker(writer: SaveWriter) -> void:
	var waited: int = 0
	while writer.has_pending() and waited < WAIT_MS:
		OS.delay_msec(2)
		waited += 2
	writer.flush()


## What the file holds compared with: to_dict() through the same JSON text.
func _as_saved(data: Dictionary) -> Variant:
	return JSON.parse_string(JSON.stringify(data))


func _saved(app: AppService) -> Variant:
	return SaveStore.read(app.path_of(AppService.PUZZLE_FILE), SaveStore.MAX_BYTES_PUZZLE)


## Grows the undo history to at least count steps: Cross Out on one empty
## cell, one digit at a time, each press one step.
func _grow_history(session: GameSession, count: int) -> void:
	session.set_mode(GameSession.Mode.CROSS_OUT)
	var empties: PackedInt32Array = Fx.empty_cells(session)
	var pressed: int = 0
	while pressed < count:
		session.select(empties[pressed % empties.size()])
		session.press_digit(pressed % 9 + 1)
		pressed += 1


func test_the_snapshot_save_is_exactly_the_old_to_dict_save() -> void:
	var dir: String = Fx.fresh_dir("snapshot_equal")
	var app: AppService = _app_with_puzzle(dir)
	var session: GameSession = app.session
	var empties: PackedInt32Array = Fx.empty_cells(session)
	session.select(empties[0])
	session.press_digit(session.solution[empties[0]])
	session.set_mode(GameSession.Mode.CROSS_OUT)
	session.select(empties[1])
	session.press_digit(3)
	session.press_digit(7)
	session.add_time(95.0)
	session.buy_hint(NextStep.find(session.solution, session.board))
	session.undo()
	app.request_session_save()
	app.call(&"_queued_session_save")
	var expected: Variant = _as_saved(session.to_dict())
	_wait_for_worker(_writer(app))
	assert_eq(_saved(app), expected, "the file holds what to_dict() gives")
	var loaded: GameSession = app.load_session_file()
	assert_true(loaded != null, "and it loads")
	if loaded != null:
		assert_eq(loaded.to_dict(), session.to_dict(), "as the same puzzle")
	app.free()
	Fx.wipe(dir)


func test_playing_on_while_the_worker_writes_changes_nothing_in_the_save() -> void:
	var dir: String = Fx.fresh_dir("snapshot_play_on")
	var app: AppService = _app_with_puzzle(dir)
	var session: GameSession = app.session
	_grow_history(session, 300)
	var writer: SaveWriter = _writer(app)
	# Hold the write lock, as a write in progress would, so the worker waits
	# while the session plays on.
	var lock: Mutex = writer.get(&"_write_lock") as Mutex
	lock.lock()
	app.request_session_save()
	app.call(&"_queued_session_save")
	var expected: Variant = _as_saved(session.to_dict())
	for i: int in 40:
		session.undo()
	_grow_history(session, 25)
	lock.unlock()
	_wait_for_worker(writer)
	assert_eq(_saved(app), expected, "the save is the session as it was at the end of that frame")
	app.free()
	Fx.wipe(dir)


func test_a_conversion_that_gives_no_dictionary_writes_nothing() -> void:
	var dir: String = Fx.fresh_dir("snapshot_bad_convert")
	var path: String = dir.path_join("a.json")
	var writer: SaveWriter = SaveWriter.new()
	writer.write_now(path, {"value": 1}, SaveStore.MAX_BYTES_OTHER)
	var bad: Callable = func(_data: Dictionary) -> Variant: return null
	writer.queue(path, {"value": 2}, SaveStore.MAX_BYTES_OTHER, bad)
	_wait_for_worker(writer)
	var data: Variant = SaveStore.read(path, SaveStore.MAX_BYTES_OTHER)
	assert_eq((data as Dictionary).get("value"), 1.0, "the older file stays")
	var doubled: Callable = func(d: Dictionary) -> Dictionary: return {"value": int(d["value"]) * 2}
	writer.queue(path, {"value": 4}, SaveStore.MAX_BYTES_OTHER, doubled)
	_wait_for_worker(writer)
	data = SaveStore.read(path, SaveStore.MAX_BYTES_OTHER)
	assert_eq((data as Dictionary).get("value"), 8.0, "a conversion runs before the write")
	writer.stop()
	writer.queue(path, {"value": 5}, SaveStore.MAX_BYTES_OTHER, doubled)
	data = SaveStore.read(path, SaveStore.MAX_BYTES_OTHER)
	assert_eq((data as Dictionary).get("value"), 10.0, "and after stop, at once on this thread")
	Fx.wipe(dir)


func test_main_thread_cost_at_2000_steps() -> void:
	var dir: String = Fx.fresh_dir("snapshot_timing")
	var app: AppService = _app_with_puzzle(dir)
	var session: GameSession = app.session
	_grow_history(session, STEPS)
	var steps: int = (session.save_snapshot()["undo"] as Array).size()
	assert_true(steps >= STEPS, "the history has %d steps" % steps)
	var writer: SaveWriter = _writer(app)

	# What runs on the main thread now: the end of frame save hands the
	# snapshot to the worker.
	app.request_session_save()
	app.call(&"_queued_session_save")
	_wait_for_worker(writer)
	var now_us: int = 0
	for i: int in ROUNDS:
		app.request_session_save()
		var start: int = Time.get_ticks_usec()
		app.call(&"_queued_session_save")
		now_us += Time.get_ticks_usec() - start
		_wait_for_worker(writer)

	# What ran on the main thread before: to_dict() of the whole session.
	var before_us: int = 0
	for i: int in ROUNDS:
		var start: int = Time.get_ticks_usec()
		var data: Dictionary = session.to_dict()
		before_us += Time.get_ticks_usec() - start
		assert_true(not data.is_empty())

	var now_ms: float = float(now_us) / float(ROUNDS) / 1000.0
	var before_ms: float = float(before_us) / float(ROUNDS) / 1000.0
	print("  main thread per save at %d steps: snapshot and hand off %.3f ms, to_dict before %.3f ms" % [steps, now_ms, before_ms])
	assert_true(now_ms < before_ms, "the main thread does less than before")
	assert_true(now_ms < 2.0, "well under a frame (%.3f ms)" % now_ms)
	assert_eq(_saved(app), _as_saved(session.to_dict()), "and the file is still exactly to_dict()")
	app.free()
	Fx.wipe(dir)
