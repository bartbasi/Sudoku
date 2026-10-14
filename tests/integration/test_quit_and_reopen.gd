extends "res://tests/unit_test.gd"
## Phase 4 verify item 10, end to end: play a puzzle through the real
## screens (digits, crosses and a restore by hand in several cells, Cross Out
## mode, time on the clock, a hint on screen), quit the way the system closes
## the app, then build a fresh App from the save files in the same folder.
## The puzzle resumes through Continue with every crossed candidate, the
## mode, the selection, the timer, the hint and the undo history intact.

const Ix := preload("res://tests/integration/integration_fixtures.gd")


func test_quit_and_reopen_resumes_everything() -> void:
	var dir: String = Ix.new_dir("reopen")
	Ix.write_settings(dir)
	var h: Ix.Harness = Ix.open_app(dir)
	Ix.start_from_menu(h, Levels.EASY)
	var screen: Control = h.top()
	var area: PlayArea = Ix.play_area_of(screen)
	var session: GameSession = h.app.session
	var cells: PackedInt32Array = Ix.empty_cells(session)
	Ix.place(area, cells[0], session.solution[cells[0]])
	Ix.place(area, cells[1], session.solution[cells[1]] % 9 + 1)
	Ix.tap_mode(area, GameSession.Mode.CROSS_OUT)
	for i: int in range(2, 6):
		Ix.tap_cell(area, cells[i])
		for d: int in [1, 5, 9]:
			Ix.tap_digit(area, d)
	Ix.tap_digit(area, 5)                          # a restore in the last cell
	Ix.tap_cell(area, cells[6])
	Ix.tap_digit(area, 7)
	screen.call(&"_process", 97.8)
	assert_true(Ix.click((screen.get(&"hud") as PlayHud).hint_button), "a hint on screen")
	var hint: Hint = session.hint
	assert_true(hint != null)
	var digits: PackedInt32Array = session.board.digits.duplicate()
	var marks: PackedByteArray = session.board.marks.duplicate()
	var selected: int = session.selected
	var crossed: int = 0
	for value: int in marks:
		if value == Board.Mark.CROSSED_HAND:
			crossed += 1
	assert_eq(crossed, 12, "twelve crosses by hand, after one restore")
	assert_eq(session.board.mark(cells[5], 5), Board.Mark.RESTORED_HAND)

	# The system closes the app: App saves everything and pauses the board.
	h.app.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_true((screen.get(&"pause_menu") as PauseMenu).is_open(), "the pause menu opens")
	Ix.quit(h)

	var again: Ix.Harness = Ix.open_app_on_title(dir)
	assert_eq(again.screen_name(), AppService.TITLE, "reopens on the title screen")
	var play: Button = again.top().get(&"play_button")
	assert_true(Ix.click(play), "PLAY")
	Ix.fit(again)
	assert_eq(again.screen_name(), AppService.PLAY)
	var back: GameSession = again.app.session
	var screen2: Control = again.top()
	var area2: PlayArea = Ix.play_area_of(screen2)
	assert_eq(back.board.digits, digits, "every digit")
	assert_eq(back.board.marks, marks, "every crossed and restored candidate")
	assert_eq(area2.view.draw_state().marks, marks, "and the board draws them")
	assert_eq(back.mode, GameSession.Mode.CROSS_OUT, "the mode")
	assert_eq(area2.pad.mode(), GameSession.Mode.CROSS_OUT, "the pad shows it")
	assert_eq(back.selected, selected, "the selection")
	assert_eq(back.elapsed_seconds(), 97, "the timer")
	assert_eq((screen2.get(&"hud") as PlayHud).time_value.text, "1:37")
	assert_eq(back.hints_bought, 1, "charged once")
	assert_eq(back.score(), Scoring.points(Levels.EASY) - back.hint_cost())
	assert_true(back.hint != null, "the hint")
	if back.hint != null:
		assert_eq(back.hint.to_dict(), hint.to_dict())
		assert_true((screen2.get(&"hint_panel") as HintPanel).visible, "on screen")
		assert_eq(area2.view.draw_state().hint_targets, hint.targets)
		assert_eq(area2.view.draw_state().hint_crosses, hint.eliminations)
	assert_true((screen2.get(&"hud") as PlayHud).hint_button.disabled, "Hint stays disabled while it shows")
	assert_eq(again.app.stats.started(Levels.EASY), 1, "a resume is not a start")

	# The timer runs on, and the undo history came back too (GDD 7.3).
	screen2.call(&"_process", 3.0)
	assert_eq(back.elapsed_seconds(), 100)
	assert_true(area2.pad.is_undo_enabled(), "Undo works after reopening")
	Ix.tap_key(area2, NumberPad.UNDO)
	assert_eq(back.board.mark(cells[6], 7), Board.Mark.OPEN, "the last cross is undone")
	assert_eq(back.hint, null, "undo closes the hint")
	Ix.close(again)


func test_quit_from_the_background_keeps_auto_cross_and_marks() -> void:
	# Auto Cross on, hand marks next to its marks, then the app goes to the
	# background (NOTIFICATION_APPLICATION_PAUSED) and is killed.
	var dir: String = Ix.new_dir("reopen_auto")
	Ix.write_settings(dir, true)
	Ix.write_session(dir, Ix.position_b_session())
	var h: Ix.Harness = Ix.open_app(dir)
	Ix.click(h.top().get(&"continue_button") as Button)
	Ix.fit(h)
	var area: PlayArea = Ix.play_area_of(h.top())
	var session: GameSession = h.app.session
	assert_true(session.auto_cross)
	Ix.tap_cell(area, 40)
	Ix.tap_mode(area, GameSession.Mode.CROSS_OUT)
	Ix.tap_digit(area, 1)
	Ix.tap_digit(area, 2)
	var ring: Array[int] = Ix.ring(session, 40)
	assert_eq(ring[0], Board.Mark.CROSSED_HAND)
	assert_eq(ring[1], Board.Mark.RESTORED_HAND)
	assert_eq(ring[2], Board.Mark.CROSSED_AUTO)
	var marks: PackedByteArray = session.board.marks.duplicate()
	h.app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	Ix.quit(h)
	var again: Ix.Harness = Ix.open_app(dir)
	assert_true(again.app.session.auto_cross)
	assert_eq(again.app.session.board.marks, marks, "every mark, hand and Auto Cross")
	assert_eq(again.app.session.mode, GameSession.Mode.CROSS_OUT)
	Ix.close(again)
