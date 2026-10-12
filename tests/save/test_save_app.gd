extends "res://tests/unit_test.gd"
## App loading and saving the four files (GDD 14, docs/ARCHITECTURE.md
## section 12): round trips, and corrupt, truncated, wrong typed and out of
## range data falling back to defaults, one part at a time, without errors
## and never as a finished puzzle.

const Fx := preload("res://tests/save/save_fixtures.gd")


func _app(dir: String) -> AppService:
	var app: AppService = AppService.new()
	app.save_dir = dir
	app.use_thread = false
	return app


func test_puzzle_round_trip_keeps_everything() -> void:
	var dir: String = Fx.fresh_dir("app_round")
	var app: AppService = _app(dir)
	var played: GameSession = Fx.played_session()
	app.session = played
	app.save_session()
	var other: AppService = _app(dir)
	other.load_all()
	var back: GameSession = other.session
	assert_true(back != null, "the puzzle comes back")
	if back != null:
		assert_eq(back.puzzle_id, played.puzzle_id)
		assert_eq(back.level, played.level)
		assert_eq(back.board.digits, played.board.digits)
		assert_eq(back.board.marks, played.board.marks)
		assert_eq(back.mode, GameSession.Mode.CROSS_OUT)
		assert_eq(back.selected, played.selected)
		assert_eq(back.elapsed_seconds(), 83)
		assert_eq(back.hints_bought, 1)
		assert_eq(back.score(), played.score())
		assert_true(back.hint != null, "the hint on screen comes back")
		assert_true(back.can_undo())
		# Undo works all the way back to the start.
		var steps: int = 0
		while back.can_undo():
			back.undo()
			steps += 1
		assert_eq(steps, 5, "five undo steps")
		assert_eq(back.board.digits, back.board.givens)
	app.free()
	other.free()
	Fx.wipe(dir)


func test_settings_stats_and_lessons_round_trip() -> void:
	var dir: String = Fx.fresh_dir("app_parts")
	var app: AppService = _app(dir)
	app.load_all()
	app.set_sound(false)
	app.set_skin(&"pop_dark")
	app.set_auto_cross(true)
	app.answer_first_launch()
	app.stats.record_start(Levels.EASY)
	app.stats.record_completion(Levels.EASY, 300, 276)
	app.reset_stats()
	app.stats.record_start(Levels.HARD)
	app.save_all()
	app.record_lesson_finished("lesson_02")
	var other: AppService = _app(dir)
	other.load_all()
	assert_false(other.settings.sound)
	assert_eq(other.settings.skin_id, &"pop_dark")
	assert_true(other.settings.auto_cross)
	assert_true(other.settings.first_launch_answered)
	assert_eq(other.stats.started(Levels.HARD), 1)
	assert_eq(other.stats.completed_count(Levels.EASY), 0)
	assert_true(other.lessons.is_finished("lesson_02"))
	app.free()
	other.free()
	Fx.wipe(dir)


func test_unreadable_puzzle_gives_no_puzzle_and_keeps_the_rest() -> void:
	var dir: String = Fx.fresh_dir("app_bad_puzzle")
	var app: AppService = _app(dir)
	app.load_all()
	app.set_sound(false)
	app.record_lesson_finished("lesson_01")
	app.stats.record_start(Levels.MEDIUM)
	app.save_all()
	var puzzle_path: String = app.path_of(AppService.PUZZLE_FILE)
	for text: String in ["garbage", "{", Fx.wrap("x"), Fx.wrap([1]), Fx.wrap({}), "{\"format\": 1, \"data\": {\"puzzle_id\": \"1.0.7\""]:
		Fx.write_text(puzzle_path, text)
		var other: AppService = _app(dir)
		other.load_all()
		assert_eq(other.session, null, "no puzzle for %s" % text)
		assert_false(other.has_puzzle_in_progress())
		assert_false(other.settings.sound, "settings still load")
		assert_eq(other.stats.started(Levels.MEDIUM), 1, "stats still load")
		assert_true(other.lessons.is_finished("lesson_01"), "lessons still load")
		other.free()
	app.free()
	Fx.wipe(dir)


func test_every_truncation_of_a_saved_puzzle_gives_no_puzzle() -> void:
	var dir: String = Fx.fresh_dir("app_trunc")
	var app: AppService = _app(dir)
	app.session = Fx.played_session()
	app.save_session()
	var path: String = app.path_of(AppService.PUZZLE_FILE)
	var full: String = Fx.read_text(path)
	var step: int = maxi(1, full.length() / 300)
	for length: int in range(0, full.length(), step):
		Fx.write_text(path, full.substr(0, length))
		assert_eq(app.load_session_file(), null, "truncated at %d" % length)
	Fx.write_text(path, full)
	assert_ne(app.load_session_file(), null, "the whole file loads")
	app.free()
	Fx.wipe(dir)


func test_wrong_typed_and_out_of_range_puzzle_fields_give_no_puzzle() -> void:
	var dir: String = Fx.fresh_dir("app_fields")
	var app: AppService = _app(dir)
	var good: Dictionary = Fx.played_session().to_dict()
	var path: String = app.path_of(AppService.PUZZLE_FILE)
	var board: Dictionary = good["board"]
	var digits_12: String = String(board["digits"])
	var bad_boards: Array[Dictionary] = []
	var b1: Dictionary = board.duplicate()
	b1["digits"] = digits_12.substr(0, 80)
	bad_boards.append(b1)
	var b2: Dictionary = board.duplicate()
	b2["marks"] = String(board["marks"]).substr(0, 728) + "7"
	bad_boards.append(b2)
	var b3: Dictionary = board.duplicate()
	b3["givens"] = 5
	bad_boards.append(b3)
	var changes: Array[Array] = [
		["puzzle_id", 17], ["puzzle_id", ""], ["puzzle_id", "1.3.7"], ["puzzle_id", "../x"], ["puzzle_id", "9.0.7"],
		["level", 7], ["level", -1], ["level", "0"], ["level", 0.5],
		["mode", 2], ["mode", true],
		["selected", 99], ["selected", -2], ["selected", "4"],
		["auto_cross", 1],
		["elapsed", -5], ["elapsed", "12"], ["elapsed", 1.0e12],
		["hints_bought", 6], ["hints_bought", -1],
		["solution", "123"], ["solution", 5],
		["hint", 3], ["hint", {"technique": "teleport"}],
		["undo", "x"], ["undo", [{"k": 9}]], ["undo", []],
		["board", null], ["board", bad_boards[0]], ["board", bad_boards[1]], ["board", bad_boards[2]],
	]
	for change: Array in changes:
		var data: Dictionary = good.duplicate(true)
		data[change[0]] = change[1]
		Fx.write_text(path, Fx.wrap(data))
		assert_eq(app.load_session_file(), null, "%s = %s" % [change[0], str(change[1])])
	# Every field but the hint is required; a missing hint means none on screen.
	for key: String in good.keys():
		if key == "hint":
			continue
		var data: Dictionary = good.duplicate(true)
		data.erase(key)
		Fx.write_text(path, Fx.wrap(data))
		assert_eq(app.load_session_file(), null, "missing %s" % key)
	Fx.write_text(path, Fx.wrap(good))
	assert_ne(app.load_session_file(), null, "the unchanged data loads")
	app.free()
	Fx.wipe(dir)


func test_a_digit_12_in_the_board_gives_no_puzzle() -> void:
	# GDD AT-60: impossible values, such as a digit 12.
	var dir: String = Fx.fresh_dir("app_digit12")
	var app: AppService = _app(dir)
	var data: Dictionary = Fx.played_session().to_dict()
	var path: String = app.path_of(AppService.PUZZLE_FILE)
	var digits: String = data["board"]["digits"]
	var empty_at: int = digits.find("0")
	data["board"]["digits"] = digits.substr(0, empty_at) + "12" + digits.substr(empty_at + 2)
	Fx.write_text(path, Fx.wrap(data))
	assert_eq(app.load_session_file(), null)
	app.free()
	Fx.wipe(dir)


func test_a_solved_board_never_comes_back_as_a_puzzle() -> void:
	var dir: String = Fx.fresh_dir("app_solved")
	var app: AppService = _app(dir)
	var session: GameSession = Fx.played_session()
	var data: Dictionary = session.to_dict()
	# A file whose board is already the full solution.
	data["board"]["digits"] = data["solution"]
	data["undo"] = []
	data["hint"] = null
	Fx.write_text(app.path_of(AppService.PUZZLE_FILE), Fx.wrap(data))
	app.load_all()
	assert_eq(app.session, null)
	assert_false(app.has_puzzle_in_progress())
	app.free()
	Fx.wipe(dir)


func test_bad_settings_stats_and_lessons_fall_back_to_defaults() -> void:
	var dir: String = Fx.fresh_dir("app_bad_parts")
	var app: AppService = _app(dir)
	Fx.write_text(app.path_of(AppService.SETTINGS_FILE), Fx.wrap({"sound": "no", "skin_id": "../../evil", "auto_cross": 1, "first_launch_answered": null}))
	Fx.write_text(app.path_of(AppService.STATS_FILE), Fx.wrap({"levels": [{"started": -4}, 1, 2]}))
	Fx.write_text(app.path_of(AppService.LESSONS_FILE), Fx.wrap({"finished": ["lesson_99x", 3, "../lesson_01", "lesson_03"]}))
	app.load_all()
	assert_true(app.settings.sound)
	assert_eq(app.settings.skin_id, &"pop_light")
	assert_false(app.settings.auto_cross)
	assert_false(app.settings.first_launch_answered)
	for level: int in Levels.COUNT:
		assert_eq(app.stats.started(level), 0)
		assert_eq(app.stats.best_time(level), -1)
	assert_eq(app.lessons.finished_count(), 1, "only the valid id is kept")
	assert_true(app.lessons.is_finished("lesson_03"))
	app.free()
	Fx.wipe(dir)


func test_garbage_in_every_file_loads_defaults() -> void:
	var dir: String = Fx.fresh_dir("app_garbage")
	var app: AppService = _app(dir)
	for file: String in [AppService.SETTINGS_FILE, AppService.STATS_FILE, AppService.LESSONS_FILE, AppService.PUZZLE_FILE]:
		Fx.write_bytes(app.path_of(file), PackedByteArray([0xFF, 0xFE, 0x00, 0x7B, 0x22, 0xC3]))
	app.load_all()
	assert_true(app.settings.sound)
	assert_eq(app.stats.started(0), 0)
	assert_eq(app.lessons.finished_count(), 0)
	assert_eq(app.session, null)
	app.free()
	Fx.wipe(dir)


func test_a_20000_step_undo_history_saves_under_the_limit_and_loads() -> void:
	var dir: String = Fx.fresh_dir("app_big_undo")
	var app: AppService = _app(dir)
	var puzzle: Puzzle = PuzzleSource.get_puzzle(Levels.BEGINNER, 3)
	var session: GameSession = GameSession.create(puzzle.id, puzzle.level, puzzle.givens, puzzle.solution, true)
	var empty: int = Fx.empty_cells(session)[0]
	session.select(empty)
	session.set_mode(GameSession.Mode.CROSS_OUT)
	for i: int in 20000:
		session.press_digit(1 + i % 9)
	app.session = session
	app.save_session()
	var path: String = app.path_of(AppService.PUZZLE_FILE)
	var bytes: int = FileAccess.get_file_as_bytes(path).size()
	assert_true(bytes > 0 and bytes < SaveStore.MAX_BYTES_PUZZLE, "%d bytes" % bytes)
	var back: GameSession = app.load_session_file()
	assert_true(back != null, "the long history loads")
	if back != null:
		assert_eq(back.board.marks, session.board.marks)
		var steps: int = 0
		while back.can_undo() and steps < 20001:
			back.undo()
			steps += 1
		assert_eq(steps, 20000)
	app.free()
	Fx.wipe(dir)
