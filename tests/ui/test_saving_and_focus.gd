extends "res://tests/unit_test.gd"
## Phase 6 fixes in App and the hint panel: saves gathered to one per frame
## and written on a worker (QA M1), flushed at once on the lifecycle events
## and before a delete; at completion the stats (with the puzzle's id) are
## written before the saved puzzle is deleted, and a puzzle that comes back
## after a kill in between counts nothing (security Low 5, Phase 6 order);
## a puzzle made while focus was lost opens
## paused (QA L1); no empty technique tag (QA L3).

const Fx := preload("res://tests/save/save_fixtures.gd")
const GeneratingOverlay := preload("res://src/ui/generating_overlay.gd")
const WAIT_MS: int = 20000

var _hosts: Array[Control] = []


## An app with a Beginner puzzle in progress, saved, and then saving the way
## the game does: gathered per frame, written on the worker.
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


## What the end of the frame does: the gathered save goes to the worker.
func _end_frame(app: AppService) -> void:
	app.call(&"_queued_session_save")


## Waits until the worker has written everything handed to it.
func _wait_for_worker(app: AppService) -> void:
	var writer: SaveWriter = _writer(app)
	var waited: int = 0
	while writer.has_pending() and waited < WAIT_MS:
		OS.delay_msec(2)
		waited += 2
	writer.flush()


func _saved_digit(app: AppService, cell: int) -> int:
	var saved: GameSession = app.load_session_file()
	return saved.board.digits[cell] if saved != null else -1


func _place_one(app: AppService) -> int:
	var session: GameSession = app.session
	var cell: int = Fx.empty_cells(session)[0]
	session.set_mode(GameSession.Mode.PLACE)
	session.select(cell)
	session.press_digit(session.solution[cell])
	return cell


func _free(app: AppService, dir: String) -> void:
	app.free()
	for host: Control in _hosts:
		if is_instance_valid(host):
			host.get_parent().remove_child(host)
			host.free()
	_hosts.clear()
	Fx.wipe(dir)


# One save per frame, off the main thread -----------------------------------------

func test_a_board_change_waits_for_the_end_of_the_frame_then_the_worker() -> void:
	var dir: String = Fx.fresh_dir("saving_frame")
	var app: AppService = _app_with_puzzle(dir)
	var cell: int = _place_one(app)
	assert_true(app.is_saving(), "a save is waiting")
	assert_eq(_saved_digit(app, cell), 0, "nothing written during the tap")
	_end_frame(app)
	_wait_for_worker(app)
	assert_eq(_saved_digit(app, cell), app.session.solution[cell], "written by the worker")
	assert_false(app.is_saving())
	_free(app, dir)


func test_a_placement_that_closes_a_hint_saves_once() -> void:
	var dir: String = Fx.fresh_dir("saving_once")
	var app: AppService = _app_with_puzzle(dir)
	var session: GameSession = app.session
	session.buy_hint(NextStep.find(session.solution, session.board))
	_end_frame(app)
	_wait_for_worker(app)
	assert_true(app.load_session_file().hint != null, "the hint is saved")
	var before: int = _writer(app).written_count()
	var cell: int = _place_one(app)
	assert_eq(session.hint, null, "the placement closed the hint")
	_end_frame(app)
	_end_frame(app)
	_wait_for_worker(app)
	assert_eq(_writer(app).written_count(), before + 1, "board_changed and hint_changed make one save")
	var saved: GameSession = app.load_session_file()
	assert_eq(saved.hint, null)
	assert_eq(saved.board.digits[cell], session.solution[cell])
	_free(app, dir)


func test_many_changes_in_one_frame_make_one_save() -> void:
	var dir: String = Fx.fresh_dir("saving_many")
	var app: AppService = _app_with_puzzle(dir)
	var session: GameSession = app.session
	var before: int = _writer(app).written_count()
	session.set_mode(GameSession.Mode.CROSS_OUT)
	var cell: int = Fx.empty_cells(session)[0]
	session.select(cell)
	for d: int in range(1, 10):
		session.press_digit(d)
	_end_frame(app)
	_wait_for_worker(app)
	assert_eq(_writer(app).written_count(), before + 1, "one save for ten changes")
	assert_eq(app.load_session_file().board.marks[cell * 9 + 8], Board.Mark.CROSSED_HAND, "the last change is in it")
	_free(app, dir)


func test_every_lifecycle_event_writes_a_waiting_save_at_once() -> void:
	for what: int in [Node.NOTIFICATION_APPLICATION_PAUSED, Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_WM_CLOSE_REQUEST]:
		var dir: String = Fx.fresh_dir("saving_life_%d" % what)
		var app: AppService = _app_with_puzzle(dir)
		var cell: int = _place_one(app)
		app.notification(what)
		assert_false(app.is_saving(), "nothing left waiting after %d" % what)
		assert_eq(_saved_digit(app, cell), app.session.solution[cell], "on disk at once after %d" % what)
		_free(app, dir)


func test_save_session_writes_at_once_and_replaces_a_waiting_save() -> void:
	var dir: String = Fx.fresh_dir("saving_now")
	var app: AppService = _app_with_puzzle(dir)
	var cell: int = _place_one(app)
	_end_frame(app)
	var second: int = Fx.empty_cells(app.session)[0]
	app.session.select(second)
	app.session.press_digit(app.session.solution[second])
	app.save_session()
	assert_false(app.is_saving(), "the gathered save is not needed any more")
	assert_eq(_saved_digit(app, cell), app.session.solution[cell])
	assert_eq(_saved_digit(app, second), app.session.solution[second], "the newest state, written at once")
	_wait_for_worker(app)
	assert_eq(_saved_digit(app, second), app.session.solution[second], "the older queued save never lands after it")
	_free(app, dir)


func test_freeing_the_app_writes_a_waiting_save() -> void:
	var dir: String = Fx.fresh_dir("saving_free")
	var app: AppService = _app_with_puzzle(dir)
	var cell: int = _place_one(app)
	var digit: int = app.session.solution[cell]
	app.free()
	var again: AppService = AppService.new()
	again.save_dir = dir
	again.use_thread = false
	assert_eq(_saved_digit(again, cell), digit)
	again.free()
	Fx.wipe(dir)


func test_abandon_with_a_save_on_the_worker_leaves_no_file() -> void:
	var dir: String = Fx.fresh_dir("saving_abandon")
	var app: AppService = _app_with_puzzle(dir)
	_place_one(app)
	_end_frame(app)
	_place_one(app)
	app.abandon_puzzle()
	assert_false(app.is_saving())
	OS.delay_msec(20)
	_wait_for_worker(app)
	assert_false(FileAccess.file_exists(app.path_of(AppService.PUZZLE_FILE)), "the queued save did not bring it back")
	_free(app, dir)


# Completion (security Low 5) --------------------------------------------------------

func test_completion_writes_the_stats_then_deletes_the_puzzle() -> void:
	var dir: String = Fx.fresh_dir("saving_complete")
	var app: AppService = _app_with_puzzle(dir)
	var id: String = app.session.puzzle_id
	Fx.solve(app.session)
	assert_true(app.session.is_completed)
	assert_true(app.on_puzzle_completed() != null)
	assert_false(FileAccess.file_exists(app.path_of(AppService.PUZZLE_FILE)), "the puzzle is gone")
	var stats: Stats = Stats.from_dict(SaveStore.read(app.path_of(AppService.STATS_FILE), SaveStore.MAX_BYTES_OTHER))
	assert_eq(stats.completed_count(Levels.BEGINNER), 1, "the completion is on disk")
	assert_eq(stats.last_completed_id(), id, "with the puzzle's id")
	_free(app, dir)


func test_a_kill_between_the_stats_and_the_delete_never_counts_twice() -> void:
	var dir: String = Fx.fresh_dir("saving_complete_kill")
	var app: AppService = _app_with_puzzle(dir)
	app.use_thread = false
	var session: GameSession = app.session
	# Play to one digit short and save, as the last save before completion.
	var empties: PackedInt32Array = Fx.empty_cells(session)
	session.set_mode(GameSession.Mode.PLACE)
	for i: int in range(1, empties.size()):
		session.select(empties[i])
		session.press_digit(session.solution[empties[i]])
	app.save_session()
	var one_short: String = FileAccess.get_file_as_string(app.path_of(AppService.PUZZLE_FILE))
	session.select(empties[0])
	session.press_digit(session.solution[empties[0]])
	assert_true(session.is_completed)
	var first: CompletionResult = app.on_puzzle_completed()
	assert_eq(app.stats.completed_count(Levels.BEGINNER), 1)
	# The app died before the delete: the one short save is still there.
	Fx.write_text(app.path_of(AppService.PUZZLE_FILE), one_short)

	var again: AppService = AppService.new()
	again.save_dir = dir
	again.use_thread = false
	again.load_all()
	assert_true(again.has_puzzle_in_progress(), "the puzzle comes back one digit short")
	assert_eq(again.stats.completed_count(Levels.BEGINNER), 1, "counted once so far")
	var back: GameSession = again.session
	back.set_mode(GameSession.Mode.PLACE)
	back.select(empties[0])
	back.press_digit(back.solution[empties[0]])
	assert_true(back.is_completed)
	var repeat: CompletionResult = again.on_puzzle_completed()
	assert_true(repeat != null, "the completion screen still has a result to show")
	assert_eq(repeat.new_best, 0, "no New best label for a repeat")
	assert_eq(again.stats.completed_count(Levels.BEGINNER), 1, "a repeat of the same id records nothing")
	assert_eq(again.stats.started(Levels.BEGINNER), 1, "Started unchanged")
	assert_eq(again.stats.best_time(Levels.BEGINNER), app.stats.best_time(Levels.BEGINNER), "best time unchanged")
	assert_false(FileAccess.file_exists(again.path_of(AppService.PUZZLE_FILE)), "and the save is gone now")
	var third: AppService = AppService.new()
	third.save_dir = dir
	third.use_thread = false
	third.load_all()
	assert_eq(third.session, null, "nothing comes back a second time")
	assert_eq(third.stats.completed_count(Levels.BEGINNER), 1, "still once on disk")
	assert_true(first != null)
	third.free()
	again.free()
	_free(app, dir)


func test_completion_with_saves_waiting_leaves_no_puzzle() -> void:
	var dir: String = Fx.fresh_dir("saving_complete_wait")
	var app: AppService = _app_with_puzzle(dir)
	_place_one(app)
	_end_frame(app)
	Fx.solve(app.session)
	app.on_puzzle_completed()
	_end_frame(app)
	OS.delay_msec(20)
	_wait_for_worker(app)
	assert_false(FileAccess.file_exists(app.path_of(AppService.PUZZLE_FILE)))
	assert_eq(app.stats.completed_count(Levels.BEGINNER), 1)
	_free(app, dir)


# Focus lost while a puzzle is being made (QA L1) ----------------------------------

func _making_app(dir: String) -> AppService:
	var app: AppService = AppService.new()
	app.save_dir = dir
	app.load_all()
	app.settings.first_launch_answered = true
	var host: Control = Control.new()
	host.theme = ThemeFactory.build(app.current_skin())
	host.size = Vector2(360, 800)
	(Engine.get_main_loop() as SceneTree).root.add_child(host)
	_hosts.append(host)
	app.attach_host(host)
	app.goto(AppService.LEVEL_SELECT)
	app.use_thread = true
	return app


## Runs the making of a puzzle to its end: waits for the worker, then lets
## the card's time pass.
func _finish_making(app: AppService) -> void:
	var overlay: Control = null
	for child: Node in app.get(&"_host").get_children():
		if child.get_script() == GeneratingOverlay:
			overlay = child as Control
	var waited: int = 0
	while app.get(&"_thread") != null and waited < WAIT_MS:
		OS.delay_msec(5)
		waited += 5
		app.call(&"_process", 0.0)
	if overlay != null:
		overlay.call(&"step", Motion.MAKING_DELAY + Motion.MAKING_MIN)
	app.call(&"_process", 0.0)


func test_focus_lost_while_making_opens_the_puzzle_paused() -> void:
	var dir: String = Fx.fresh_dir("making_focus")
	var app: AppService = _making_app(dir)
	app.start_new_puzzle(Levels.BEGINNER)
	assert_true(app.is_generating())
	app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_finish_making(app)
	assert_eq(app.current_screen(), AppService.PLAY, "the puzzle opens")
	var screen: Control = app.current_screen_node()
	assert_true(bool(screen.get(&"pause_menu").call(&"is_open")), "with the pause menu")
	assert_false(bool(screen.call(&"is_timer_running")), "and the timer stopped")
	_free(app, dir)


func test_without_a_focus_loss_the_puzzle_opens_unpaused() -> void:
	var dir: String = Fx.fresh_dir("making_nofocus")
	var app: AppService = _making_app(dir)
	app.start_new_puzzle(Levels.BEGINNER)
	_finish_making(app)
	assert_eq(app.current_screen(), AppService.PLAY)
	var screen: Control = app.current_screen_node()
	assert_false(bool(screen.get(&"pause_menu").call(&"is_open")), "no pause menu")
	# The next puzzle is not paused by an old focus loss either.
	app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	app.call(&"_queued_session_save")
	app.goto(AppService.LEVEL_SELECT)
	app.abandon_puzzle()
	app.start_new_puzzle(Levels.BEGINNER)
	_finish_making(app)
	screen = app.current_screen_node()
	assert_eq(app.current_screen(), AppService.PLAY)
	assert_false(bool(screen.get(&"pause_menu").call(&"is_open")), "a focus loss before the making does not count")
	_free(app, dir)


# Hint panel (QA L3) ------------------------------------------------------------------

func _panel_for(technique: String, lesson: String) -> HintPanel:
	var panel: HintPanel = HintPanel.new()
	panel.setup(load("res://src/skins/pop_light.tres") as GameSkin)
	var hint: Hint = Hint.new()
	hint.technique_name = technique
	hint.lesson_title = lesson
	hint.text = "This cell is 5."
	panel.show_hint(hint)
	return panel


func test_a_hint_with_no_technique_name_shows_no_tag() -> void:
	var panel: HintPanel = _panel_for("", "")
	assert_false(panel.tag_panel.visible, "no empty tag")
	assert_false(panel.top_row.visible, "no empty row")
	assert_true(panel.text_label.visible)
	assert_eq(panel.text_label.text, "This cell is 5.")
	panel.free()


func test_the_tag_comes_back_for_the_next_named_hint() -> void:
	var panel: HintPanel = _panel_for("", "Lesson: Last empty cell")
	assert_false(panel.tag_panel.visible)
	assert_true(panel.top_row.visible, "the lesson title still shows")
	var hint: Hint = Hint.new()
	hint.technique_name = "Naked single"
	hint.text = "This cell is 5."
	panel.show_hint(hint)
	assert_true(panel.tag_panel.visible, "the tag shows for a named hint")
	assert_true(panel.top_row.visible)
	assert_eq(panel.tag_label.text.to_upper(), "NAKED SINGLE")
	panel.free()
