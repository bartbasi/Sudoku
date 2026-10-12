extends "res://tests/unit_test.gd"
## App flows (docs/ARCHITECTURE.md sections 11 and 14, GDD 12 to 15): start,
## abandon, complete with stats and the New best bits, resume, Reset Stats
## keeping lessons, Auto Cross with one source of truth, and save_session
## never writing a completed session. Built without the autoloads.

const Fx := preload("res://tests/save/save_fixtures.gd")


func _app(dir: String) -> AppService:
	var app: AppService = AppService.new()
	app.save_dir = dir
	app.use_thread = false
	app.load_all()
	return app


func _puzzle_path(app: AppService) -> String:
	return app.path_of(AppService.PUZZLE_FILE)


func test_start_new_puzzle_creates_records_started_and_saves() -> void:
	var dir: String = Fx.fresh_dir("flow_start")
	var app: AppService = _app(dir)
	var seen: Array[GameSession] = []
	app.generation_finished.connect(func(s: GameSession) -> void: seen.append(s))
	app.start_new_puzzle(Levels.EASY)
	assert_true(app.has_puzzle_in_progress())
	assert_eq(seen.size(), 1, "generation_finished once")
	var session: GameSession = app.session
	assert_eq(session.level, Levels.EASY)
	assert_eq(session.selected, -1, "no cell selected")
	assert_eq(session.mode, GameSession.Mode.PLACE)
	assert_eq(session.elapsed_seconds(), 0)
	assert_eq(session.score(), 200)
	assert_eq(PuzzleId.parse(session.puzzle_id).get("level"), Levels.EASY)
	assert_eq(app.stats.started(Levels.EASY), 1)
	assert_true(FileAccess.file_exists(_puzzle_path(app)), "saved when the board appears")
	var stats_file: Variant = SaveStore.read(app.path_of(AppService.STATS_FILE), SaveStore.MAX_BYTES_OTHER)
	assert_eq(Stats.from_dict(stats_file).started(Levels.EASY), 1, "stats saved at start")
	app.start_new_puzzle(99)
	assert_eq(app.session, session, "an invalid level changes nothing")
	app.free()
	Fx.wipe(dir)


func test_every_board_change_mode_switch_and_hint_is_saved() -> void:
	var dir: String = Fx.fresh_dir("flow_autosave")
	var app: AppService = _app(dir)
	app.start_new_puzzle(Levels.BEGINNER)
	var session: GameSession = app.session
	var cell: int = Fx.empty_cells(session)[0]
	session.select(cell)
	session.press_digit(session.solution[cell])
	assert_eq(app.load_session_file().board.digits[cell], session.solution[cell], "a placement is saved at once")
	session.toggle_mode()
	assert_eq(app.load_session_file().mode, GameSession.Mode.CROSS_OUT, "a mode switch is saved")
	session.buy_hint(NextStep.find(session.solution, session.board))
	var back: GameSession = app.load_session_file()
	assert_true(back.hint != null, "a hint bought is saved")
	assert_eq(back.hints_bought, 1)
	session.close_hint()
	assert_eq(app.load_session_file().hint, null, "a hint closed is saved")
	session.undo()
	assert_eq(app.load_session_file().board.digits[cell], 0, "an undo is saved")
	app.free()
	Fx.wipe(dir)


func test_abandon_deletes_the_save_and_keeps_stats() -> void:
	var dir: String = Fx.fresh_dir("flow_abandon")
	var app: AppService = _app(dir)
	app.start_new_puzzle(Levels.MEDIUM)
	var changes: Array[Variant] = []
	app.session_changed.connect(func(s: GameSession) -> void: changes.append(s))
	app.abandon_puzzle()
	assert_eq(app.session, null)
	assert_eq(changes, [null], "session_changed(null)")
	assert_false(FileAccess.file_exists(_puzzle_path(app)), "save deleted")
	assert_eq(app.stats.started(Levels.MEDIUM), 1, "still counts as started")
	assert_eq(app.stats.completed_count(Levels.MEDIUM), 0)
	app.free()
	Fx.wipe(dir)


func test_start_new_over_a_puzzle_in_progress() -> void:
	# GDD AT-54: Medium in progress, then Start new on Easy.
	var dir: String = Fx.fresh_dir("flow_replace")
	var app: AppService = _app(dir)
	app.start_new_puzzle(Levels.MEDIUM)
	var old: GameSession = app.session
	app.abandon_puzzle()
	app.start_new_puzzle(Levels.EASY)
	assert_ne(app.session, old)
	assert_eq(app.session.level, Levels.EASY)
	assert_eq(app.stats.started(Levels.MEDIUM), 1)
	assert_eq(app.stats.started(Levels.EASY), 1)
	assert_eq(app.load_session_file().level, Levels.EASY, "the saved puzzle is the new one")
	# The old session no longer saves anything.
	var cell: int = Fx.empty_cells(old)[0]
	old.select(cell)
	old.press_digit(old.solution[cell])
	assert_eq(app.load_session_file().level, Levels.EASY)
	app.free()
	Fx.wipe(dir)


func test_completion_records_stats_deletes_the_save_and_returns_the_result() -> void:
	var dir: String = Fx.fresh_dir("flow_complete")
	var app: AppService = _app(dir)
	app.start_new_puzzle(Levels.BEGINNER)
	var session: GameSession = app.session
	session.add_time(300.4)
	session.buy_hint(NextStep.find(session.solution, session.board))
	session.close_hint()
	Fx.solve(session)
	assert_true(session.is_completed)
	assert_true(FileAccess.file_exists(_puzzle_path(app)), "the last save before completion is still there")
	var result: CompletionResult = app.on_puzzle_completed()
	assert_true(result != null)
	assert_eq(result.level, Levels.BEGINNER)
	assert_eq(result.seconds, 300)
	assert_eq(result.hints_used, 1)
	assert_eq(result.points_after_hints, 80)
	assert_eq(result.time_bonus, Scoring.time_bonus(Levels.BEGINNER, 300))
	assert_eq(result.final_score, 80 + result.time_bonus)
	assert_eq(result.new_best, 0, "first completion: no label")
	assert_eq(app.session, null)
	assert_false(app.has_puzzle_in_progress(), "no Continue")
	assert_false(FileAccess.file_exists(_puzzle_path(app)), "save deleted")
	assert_eq(app.stats.completed_count(Levels.BEGINNER), 1)
	assert_eq(app.stats.best_time(Levels.BEGINNER), 300)
	var reloaded: AppService = _app(dir)
	assert_eq(reloaded.session, null, "nothing comes back after completion")
	assert_eq(reloaded.stats.completed_count(Levels.BEGINNER), 1, "stats saved")
	assert_eq(app.on_puzzle_completed(), null, "only once")
	app.free()
	reloaded.free()
	Fx.wipe(dir)


func test_new_best_bits_follow_gdd_12_1() -> void:
	# GDD AT-67 (App): one hint, then faster with none, then slower with one.
	var dir: String = Fx.fresh_dir("flow_best")
	var app: AppService = _app(dir)
	var runs: Array[Array] = [[400.0, 1], [200.0, 0], [450.0, 1]]
	var bits: Array[int] = []
	for run: Array in runs:
		app.start_new_puzzle(Levels.BEGINNER)
		var session: GameSession = app.session
		session.add_time(run[0])
		for i: int in int(run[1]):
			session.buy_hint(NextStep.find(session.solution, session.board))
			session.close_hint()
		Fx.solve(session)
		bits.append(app.on_puzzle_completed().new_best)
	assert_eq(bits[0], 0, "first: none")
	assert_eq(bits[1], Stats.NEW_BEST_TIME | Stats.NEW_BEST_SCORE, "second: both")
	assert_eq(bits[2], 0, "third: none")
	assert_eq(app.stats.best_time(Levels.BEGINNER), 200)
	app.free()
	Fx.wipe(dir)


func test_save_session_never_writes_a_completed_session() -> void:
	var dir: String = Fx.fresh_dir("flow_no_completed")
	var app: AppService = _app(dir)
	app.start_new_puzzle(Levels.BEGINNER)
	var session: GameSession = app.session
	var empties: PackedInt32Array = Fx.empty_cells(session)
	var last: int = empties[empties.size() - 1]
	for cell: int in empties:
		if cell != last:
			session.select(cell)
			session.press_digit(session.solution[cell])
	SaveStore.remove(_puzzle_path(app))
	session.select(last)
	session.press_digit(session.solution[last])
	assert_true(session.is_completed)
	assert_false(FileAccess.file_exists(_puzzle_path(app)), "the completing placement is not saved")
	app.save_session()
	app.save_all()
	assert_false(FileAccess.file_exists(_puzzle_path(app)), "save_session skips a completed session")
	app.session = null
	app.save_session()
	assert_false(FileAccess.file_exists(_puzzle_path(app)), "nothing to save")
	app.free()
	Fx.wipe(dir)


func test_resume_brings_the_puzzle_back_unchanged_and_does_not_count_a_start() -> void:
	var dir: String = Fx.fresh_dir("flow_resume")
	var app: AppService = _app(dir)
	app.start_new_puzzle(Levels.EASY)
	var session: GameSession = app.session
	var cells: PackedInt32Array = Fx.empty_cells(session)
	session.select(cells[0])
	session.press_digit(session.solution[cells[0]])
	session.set_mode(GameSession.Mode.CROSS_OUT)
	session.select(cells[1])
	session.press_digit(4)
	session.add_time(61.7)
	app.save_all()
	var again: AppService = _app(dir)
	assert_true(again.has_puzzle_in_progress())
	assert_eq(again.session.board.digits, session.board.digits)
	assert_eq(again.session.board.marks, session.board.marks)
	assert_eq(again.session.selected, cells[1])
	assert_eq(again.session.mode, GameSession.Mode.CROSS_OUT)
	assert_eq(again.session.elapsed_seconds(), 61)
	assert_eq(again.stats.started(Levels.EASY), 1, "a resume is not a start")
	app.free()
	again.free()
	Fx.wipe(dir)


func test_reset_stats_keeps_lessons_and_the_puzzle_level_started() -> void:
	# GDD AT-55.
	var dir: String = Fx.fresh_dir("flow_reset")
	var app: AppService = _app(dir)
	app.stats.record_start(Levels.EASY)
	app.stats.record_completion(Levels.EASY, 300, 276)
	app.record_lesson_finished("lesson_01")
	app.start_new_puzzle(Levels.MEDIUM)
	app.stats.record_start(Levels.MEDIUM)
	app.reset_stats()
	for level: int in Levels.COUNT:
		assert_eq(app.stats.started(level), 1 if level == Levels.MEDIUM else 0, Levels.name_of(level))
		assert_eq(app.stats.completed_count(level), 0)
		assert_eq(app.stats.best_score(level), -1)
	assert_eq(app.lessons.finished_count(), 1, "lessons kept")
	assert_true(app.has_puzzle_in_progress(), "the puzzle continues")
	Fx.solve(app.session)
	app.on_puzzle_completed()
	assert_eq(app.stats.started(Levels.MEDIUM), 1)
	assert_eq(app.stats.completed_count(Levels.MEDIUM), 1)
	var reloaded: AppService = _app(dir)
	assert_eq(reloaded.lessons.finished_count(), 1)
	assert_eq(reloaded.stats.completed_count(Levels.EASY), 0)
	app.free()
	reloaded.free()
	Fx.wipe(dir)


func test_auto_cross_has_one_source_of_truth() -> void:
	var dir: String = Fx.fresh_dir("flow_auto")
	var app: AppService = _app(dir)
	app.start_new_puzzle(Levels.BEGINNER)
	assert_false(app.session.auto_cross)
	app.set_auto_cross(true)
	assert_true(app.session.auto_cross, "applies to the puzzle in progress")
	var crossed: int = 0
	for value: int in app.session.board.marks:
		if value == Board.Mark.CROSSED_AUTO:
			crossed += 1
	assert_true(crossed > 0, "its rules ran at once")
	assert_true(app.load_session_file().auto_cross, "saved after the change")
	# A saved session that disagrees with the setting follows the setting.
	app.settings.auto_cross = false
	app.save_all()
	var again: AppService = _app(dir)
	assert_false(again.settings.auto_cross)
	assert_false(again.session.auto_cross, "resume follows the setting")
	again.set_auto_cross(true)
	again.start_new_puzzle(Levels.EASY)
	assert_true(again.session.auto_cross, "new puzzles take the setting")
	app.free()
	again.free()
	Fx.wipe(dir)


func test_lessons_and_first_launch() -> void:
	var dir: String = Fx.fresh_dir("flow_lessons")
	var app: AppService = _app(dir)
	var count: Array[int] = [0]
	app.stats_changed.connect(func() -> void: count[0] += 1)
	app.record_lesson_finished("lesson_02")
	app.record_lesson_finished("lesson_02")
	app.record_lesson_finished("not_a_lesson")
	assert_eq(app.lessons.finished_count(), 1, "first time only")
	assert_eq(count[0], 1, "stats_changed once")
	assert_false(app.settings.first_launch_answered)
	app.answer_first_launch()
	var again: AppService = _app(dir)
	assert_true(again.settings.first_launch_answered, "the answer is saved")
	again.free()
	app.free()
	Fx.wipe(dir)


func test_sound_and_skin_settings() -> void:
	var dir: String = Fx.fresh_dir("flow_settings")
	var app: AppService = _app(dir)
	var audio: Node = (load("res://src/audio/audio_service.gd") as GDScript).new() as Node
	app.audio = audio
	app.set_sound(false)
	assert_false(bool(audio.get(&"enabled")), "Audio follows the setting")
	app.set_skin(&"pop_dark")
	assert_eq(app.current_skin().id, &"pop_dark")
	app.set_skin(&"neon")
	assert_eq(app.settings.skin_id, &"pop_dark", "unknown skins are ignored")
	var again: AppService = _app(dir)
	assert_false(again.settings.sound)
	assert_eq(again.settings.skin_id, &"pop_dark")
	audio.free()
	app.free()
	again.free()
	Fx.wipe(dir)


func test_skins_service_is_used_when_present() -> void:
	var dir: String = Fx.fresh_dir("flow_skins")
	var app: AppService = _app(dir)
	var service: Node = (load("res://src/skins/skin_service.gd") as GDScript).new() as Node
	app.skins = service
	app.set_skin(&"pop_dark")
	assert_eq((service.get(&"current") as GameSkin).id, &"pop_dark")
	assert_eq(app.current_skin().id, &"pop_dark")
	service.free()
	app.free()
	Fx.wipe(dir)
