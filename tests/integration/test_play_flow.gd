extends "res://tests/unit_test.gd"
## Phase 4 verify items 1, 3 and 7, end to end through the real screens:
## a full Beginner puzzle from New puzzle to the completion screen, undo
## across placing and crossing, and the stats after a completed and an
## abandoned puzzle.

const Ix := preload("res://tests/integration/integration_fixtures.gd")


func _area(h: Ix.Harness) -> PlayArea:
	return Ix.play_area_of(h.top())


func test_full_beginner_puzzle_from_new_puzzle_to_completion() -> void:
	var dir: String = Ix.new_dir("full")
	Ix.write_settings(dir)
	var h: Ix.Harness = Ix.open_app(dir)
	assert_eq(h.screen_name(), AppService.MAIN_MENU)
	assert_false((h.top().get(&"continue_button") as Button).visible, "no Continue before a puzzle")
	assert_true(Ix.start_from_menu(h, Levels.BEGINNER), "New puzzle, then Beginner")
	assert_eq(h.screen_name(), AppService.PLAY, "the board appears")
	var session: GameSession = h.app.session
	assert_true(session != null)
	if session == null:
		Ix.close(h)
		return
	assert_eq(session.level, Levels.BEGINNER)
	assert_eq(session.selected, -1, "AT-01: nothing selected")
	assert_eq(session.mode, GameSession.Mode.PLACE, "AT-01: Place mode")
	assert_eq(h.app.stats.started(Levels.BEGINNER), 1, "Started counted")
	var screen: Control = h.top()
	var area: PlayArea = _area(h)
	var hud: PlayHud = screen.get(&"hud")
	assert_eq(hud.score_value.text, "100")
	assert_true(area.view.board_square().size.x > 300.0, "the board is laid out at 360 dp")

	# The timer runs while the board shows.
	screen.call(&"_process", 125.6)
	assert_eq(hud.time_value.text, "2:05")

	var clicks_before: int = Ix.clicks(h)
	var empties: PackedInt32Array = Ix.empty_cells(session)
	assert_true(empties.size() > 0)
	var completions: Array[int] = [0]
	session.completed.connect(func(_s: int, _f: int) -> void: completions[0] += 1)
	for cell: int in empties:
		Ix.tap_cell(area, cell)
		assert_eq(session.selected, cell, "the tap selects cell %d" % cell)
		Ix.tap_digit(area, session.solution[cell])
	assert_eq(completions[0], 1, "completed once")
	assert_true(session.is_completed, "every cell filled from the solution completes it")
	assert_eq(session.board.digits, session.solution)
	assert_eq(Ix.clicks(h) - clicks_before, empties.size(), "one click per placement")
	assert_true(area.pad.is_locked(), "the pad locks")
	assert_true(area.view.draw_state().locked, "the board locks")
	assert_true(hud.hint_button.disabled, "Hint disabled at completion")
	assert_false(h.app.has_puzzle_in_progress(), "no Continue")
	assert_false(FileAccess.file_exists(h.app.path_of(AppService.PUZZLE_FILE)), "the save is deleted")
	screen.call(&"_process", 30.0)
	assert_eq(session.elapsed_seconds(), 125, "the timer stopped")

	# The board's wave ends and the completion screen opens (the timer that
	# calls this does not run headless).
	screen.call(&"finish_completion")
	Ix.fit(h)
	assert_eq(h.screen_name(), AppService.COMPLETION)
	var done: Control = h.top()
	var bonus: int = Scoring.time_bonus(Levels.BEGINNER, 125)
	assert_eq((done.get(&"time_value") as Label).text, "2:05")
	assert_eq((done.get(&"points_value") as Label).text, "100", "points after hints")
	assert_eq((done.get(&"bonus_value") as Label).text, str(bonus), "time bonus")
	assert_eq((done.get(&"score_value") as Label).text, str(100 + bonus), "final score")
	assert_eq((done.get(&"hints_value") as Label).text, "0", "hints used")
	assert_false((done.get(&"new_best_time") as Control).visible, "first completion: no label")
	assert_false((done.get(&"new_best_score") as Control).visible)

	# Stats.
	assert_eq(h.app.stats.started(Levels.BEGINNER), 1)
	assert_eq(h.app.stats.completed_count(Levels.BEGINNER), 1)
	assert_eq(h.app.stats.best_time(Levels.BEGINNER), 125)
	assert_eq(h.app.stats.best_score(Levels.BEGINNER), 100 + bonus)
	assert_true(Ix.click(done.get(&"menu_button") as Button))
	Ix.fit(h)
	assert_eq(h.screen_name(), AppService.MAIN_MENU)
	assert_false((h.top().get(&"continue_button") as Button).visible, "no Continue after completion")
	assert_true(Ix.click(h.top().get(&"stats_button") as Button))
	Ix.fit(h)
	assert_eq(h.screen_name(), AppService.STATS)
	var row: Dictionary = (h.top().get(&"values") as Array)[Levels.BEGINNER]
	assert_eq((row["started"] as Label).text, "1")
	assert_eq((row["completed"] as Label).text, "1")
	assert_eq((row["best_score"] as Label).text, UiKit.stat_number(100 + bonus))
	assert_eq((row["best_time"] as Label).text, UiKit.stat_time(125))
	Ix.close(h)


func test_play_again_starts_the_same_level_with_no_dialog() -> void:
	var dir: String = Ix.new_dir("again")
	Ix.write_settings(dir)
	var h: Ix.Harness = Ix.open_app(dir)
	Ix.start_from_menu(h, Levels.BEGINNER)
	var area: PlayArea = _area(h)
	var session: GameSession = h.app.session
	for cell: int in Ix.empty_cells(session):
		Ix.tap_cell(area, cell)
		Ix.tap_digit(area, session.solution[cell])
	h.top().call(&"finish_completion")
	Ix.fit(h)
	assert_true(Ix.click(h.top().get(&"play_again_button") as Button))
	Ix.fit(h)
	assert_eq(h.screen_name(), AppService.PLAY)
	assert_true(h.app.has_puzzle_in_progress())
	assert_eq(h.app.session.level, Levels.BEGINNER)
	assert_ne(h.app.session, session)
	assert_eq(h.app.stats.started(Levels.BEGINNER), 2)
	Ix.close(h)


func test_undo_across_placing_and_crossing() -> void:
	var dir: String = Ix.new_dir("undo")
	Ix.write_settings(dir)
	var h: Ix.Harness = Ix.open_app(dir)
	Ix.start_from_menu(h, Levels.BEGINNER)
	var area: PlayArea = _area(h)
	var session: GameSession = h.app.session
	var empties: PackedInt32Array = Ix.empty_cells(session)
	var a: int = empties[0]
	var b: int = empties[1]
	var c: int = empties[2]
	var right_a: int = session.solution[a]
	var wrong_a: int = right_a % 9 + 1
	var open_ring: Array[int] = Ix.ring(session, b)
	assert_false(area.pad.is_undo_enabled(), "nothing to undo at the start")

	Ix.place(area, a, wrong_a)                  # step 1: place
	Ix.place(area, a, right_a)                  # step 2: replace
	Ix.tap_mode(area, GameSession.Mode.CROSS_OUT)
	assert_eq(session.mode, GameSession.Mode.CROSS_OUT)
	assert_eq(area.pad.mode(), GameSession.Mode.CROSS_OUT, "the pad shows the mode")
	Ix.tap_cell(area, b)
	Ix.tap_digit(area, 1)                       # step 3: cross 1
	Ix.tap_digit(area, 2)                       # step 4: cross 2
	Ix.tap_digit(area, 1)                       # step 5: restore 1
	Ix.tap_mode(area, GameSession.Mode.PLACE)
	Ix.tap_cell(area, c)
	Ix.tap_digit(area, session.solution[c])     # step 6: place
	Ix.tap_key(area, NumberPad.ERASE)           # step 7: erase
	assert_eq(session.board.digit(c), 0)
	assert_eq(session.board.mark(b, 1), Board.Mark.RESTORED_HAND)
	assert_eq(session.board.mark(b, 2), Board.Mark.CROSSED_HAND)
	assert_true(area.pad.is_undo_enabled())

	# Undo, one step at a time, never changing the mode.
	Ix.tap_key(area, NumberPad.UNDO)            # undoes the erase
	assert_eq(session.board.digit(c), session.solution[c], "undo of erase brings the digit back")
	Ix.tap_key(area, NumberPad.UNDO)            # undoes the placement in c
	assert_eq(session.board.digit(c), 0)
	assert_eq(session.selected, c)
	Ix.tap_key(area, NumberPad.UNDO)            # undoes the restore of 1
	assert_eq(session.selected, b, "undo selects the cell it reverses")
	assert_eq(session.board.mark(b, 1), Board.Mark.CROSSED_HAND)
	assert_eq(session.mode, GameSession.Mode.PLACE, "undo never switches modes")
	assert_eq(area.pad.mode(), GameSession.Mode.PLACE)
	Ix.tap_key(area, NumberPad.UNDO)            # undoes the cross of 2
	assert_eq(session.board.mark(b, 2), Board.Mark.OPEN)
	Ix.tap_key(area, NumberPad.UNDO)            # undoes the cross of 1
	assert_eq(Ix.ring(session, b), open_ring, "the ring is as it was")
	Ix.tap_key(area, NumberPad.UNDO)            # undoes the replace
	assert_eq(session.board.digit(a), wrong_a)
	assert_eq(session.selected, a)
	Ix.tap_key(area, NumberPad.UNDO)            # undoes the first placement
	assert_eq(session.board.digit(a), 0)
	assert_false(session.can_undo())
	assert_false(area.pad.is_undo_enabled(), "Undo disabled with nothing left")
	var digits: PackedInt32Array = session.board.digits.duplicate()
	Ix.tap_key(area, NumberPad.UNDO)
	assert_eq(session.board.digits, digits, "a disabled Undo does nothing")
	assert_eq(h.app.load_session_file().board.digits, digits, "every undo is saved")
	Ix.close(h)


func test_stats_after_a_completed_and_an_abandoned_puzzle() -> void:
	var dir: String = Ix.new_dir("stats")
	Ix.write_settings(dir)
	var h: Ix.Harness = Ix.open_app(dir)

	# Completed: Beginner.
	Ix.start_from_menu(h, Levels.BEGINNER)
	var area: PlayArea = _area(h)
	var session: GameSession = h.app.session
	h.top().call(&"_process", 61.0)
	for cell: int in Ix.empty_cells(session):
		Ix.tap_cell(area, cell)
		Ix.tap_digit(area, session.solution[cell])
	h.top().call(&"finish_completion")
	Ix.fit(h)
	Ix.click(h.top().get(&"menu_button") as Button)
	Ix.fit(h)

	# Abandoned: Easy, left through the pause menu, then replaced by Medium.
	Ix.start_from_menu(h, Levels.EASY)
	area = _area(h)
	var easy: GameSession = h.app.session
	var cell: int = Ix.empty_cells(easy)[0]
	Ix.place(area, cell, easy.solution[cell])
	var pause: PauseMenu = h.top().get(&"pause_menu")
	assert_true(Ix.click((h.top().get(&"hud") as PlayHud).pause_button), "the pause button")
	assert_true(pause.is_open())
	assert_true(Ix.click(pause.menu_button))
	Ix.fit(h)
	assert_eq(h.screen_name(), AppService.MAIN_MENU)
	assert_true((h.top().get(&"continue_button") as Button).visible, "Continue shows the Easy puzzle")
	Ix.click(h.top().get(&"new_button") as Button)
	Ix.fit(h)
	var select: Control = h.top()
	Ix.click((select.get(&"level_buttons") as Array)[Levels.MEDIUM] as Button)
	var confirm: ConfirmDialog = select.get(&"confirm")
	assert_true(confirm.is_open(), "AT-61: the dialog asks first")
	assert_eq(h.app.session, easy, "nothing changes until the answer")
	assert_true(Ix.click(confirm.confirm_button), "Start new")
	Ix.fit(h)
	assert_eq(h.screen_name(), AppService.PLAY)
	assert_eq(h.app.session.level, Levels.MEDIUM)

	var stats: Stats = h.app.stats
	assert_eq(stats.started(Levels.BEGINNER), 1)
	assert_eq(stats.completed_count(Levels.BEGINNER), 1)
	assert_eq(stats.best_time(Levels.BEGINNER), 61)
	assert_eq(stats.started(Levels.EASY), 1, "the abandoned puzzle counts as started")
	assert_eq(stats.completed_count(Levels.EASY), 0, "and not completed")
	assert_eq(stats.best_time(Levels.EASY), -1)
	assert_eq(stats.started(Levels.MEDIUM), 1)

	# The stats screen shows it, from the pause menu's Menu.
	Ix.click((h.top().get(&"hud") as PlayHud).pause_button)
	Ix.click((h.top().get(&"pause_menu") as PauseMenu).menu_button)
	Ix.fit(h)
	Ix.click(h.top().get(&"stats_button") as Button)
	Ix.fit(h)
	var rows: Array = h.top().get(&"values")
	assert_eq(((rows[Levels.EASY] as Dictionary)["started"] as Label).text, "1")
	assert_eq(((rows[Levels.EASY] as Dictionary)["completed"] as Label).text, "0")
	assert_eq(((rows[Levels.BEGINNER] as Dictionary)["completed"] as Label).text, "1")
	assert_eq(((rows[Levels.MEDIUM] as Dictionary)["started"] as Label).text, "1")

	# The stats survive a restart.
	Ix.quit(h)
	var again: Ix.Harness = Ix.open_app(dir)
	assert_eq(again.app.stats.started(Levels.EASY), 1)
	assert_eq(again.app.stats.completed_count(Levels.EASY), 0)
	assert_eq(again.app.stats.completed_count(Levels.BEGINNER), 1)
	assert_eq(again.app.session.level, Levels.MEDIUM, "the Medium puzzle is in progress")
	Ix.close(again)
