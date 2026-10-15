extends "res://tests/unit_test.gd"
## Show candidates end to end (GDD 4.5, SC-1, AT-81 and AT-82): on Position
## B the player crosses by hand in Cross Out, turns Show candidates off from
## the pause menu's Settings, and the puzzle goes to Place with the mode
## buttons hidden and no undo step added. Auto Cross keeps working out of
## sight, and turning Show candidates on shows every ring exactly as it is.

const Ix := preload("res://tests/integration/integration_fixtures.gd")

const X: int = 40         # r5c5
const R5C4: int = 39
const R5C2: int = 37
const OPEN: int = Board.Mark.OPEN
const HAND: int = Board.Mark.CROSSED_HAND
const AUTO: int = Board.Mark.CROSSED_AUTO


func _undo_steps(session: GameSession) -> int:
	return (session.to_dict()["undo"] as Array).size()


## Pause, Settings, one switch, Back, Resume: the player's path.
func _set_from_pause(h: Ix.Harness, switch_name: StringName, on: bool) -> void:
	var screen: Control = h.top()
	var hud: PlayHud = screen.get(&"hud")
	assert_true(Ix.click(hud.pause_button), "pause")
	var pause: PauseMenu = screen.get(&"pause_menu")
	assert_true(Ix.click(pause.settings_button), "Settings")
	Ix.fit(h)
	assert_eq(h.screen_name(), AppService.SETTINGS)
	assert_true(Ix.set_switch(h.top().get(switch_name) as CheckButton, on), "the %s switch can be used" % switch_name)
	h.app.go_back()
	assert_eq(h.screen_name(), AppService.PLAY)
	assert_true(Ix.click(pause.resume_button), "Resume")
	Ix.fit(h)


func test_sc1_hidden_marks_and_auto_cross_out_of_sight() -> void:
	var dir: String = Ix.new_dir("show_sc1")
	Ix.write_settings(dir)
	Ix.write_session(dir, Ix.position_b_session())
	var h: Ix.Harness = Ix.open_app(dir)
	assert_true(Ix.click(h.top().get(&"continue_button") as Button), "Continue")
	Ix.fit(h)
	assert_eq(h.screen_name(), AppService.PLAY)
	var area: PlayArea = Ix.play_area_of(h.top())
	var session: GameSession = h.app.session

	# 1. Cross 2, 3, 4, 6 and 9 in X by hand.
	Ix.tap_cell(area, X)
	Ix.tap_mode(area, GameSession.Mode.CROSS_OUT)
	for d: int in [2, 3, 4, 6, 9]:
		Ix.tap_digit(area, d)
	var crossed: Array[int] = [OPEN, HAND, HAND, HAND, OPEN, HAND, OPEN, OPEN, HAND]
	assert_eq(Ix.ring(session, X), crossed)
	var steps: int = _undo_steps(session)
	var all_marks: PackedByteArray = PackedByteArray(session.board.marks)

	# 2. Show candidates off from the pause menu.
	_set_from_pause(h, &"show_candidates_switch", false)
	assert_false(h.app.settings.show_candidates)
	assert_eq(session.mode, GameSession.Mode.PLACE, "Cross Out switched to Place")
	assert_eq(session.selected, X, "X stays selected")
	assert_eq(_undo_steps(session), steps, "the mode switch is not an undo step")
	assert_eq(PackedByteArray(session.board.marks), all_marks, "no mark changed")
	assert_false(area.view.draw_state().show_ring, "the rings are hidden")
	assert_false(area.pad.is_mode_visible(), "the mode buttons are hidden")
	assert_false(area.pad.control_rect_global(NumberPad.CROSS_OUT).has_area(), "Cross Out cannot be reached")
	assert_eq(h.app.load_session_file().mode, GameSession.Mode.PLACE, "Place is saved")

	# 3. A digit tap places; Erase empties X again.
	Ix.tap_digit(area, 8)
	assert_eq(session.board.digit(X), 8, "every tap places")
	Ix.tap_key(area, NumberPad.ERASE)
	assert_eq(session.board.digit(X), 0)
	assert_eq(Ix.ring(session, X), crossed, "the hand marks are as left")

	# 4. Auto Cross on while hidden: it crosses out of sight.
	_set_from_pause(h, &"auto_cross_switch", true)
	assert_true(session.auto_cross)
	assert_true(area.pad.is_mode_visible() == false, "still hidden")
	for d: int in [2, 3, 4, 9]:
		assert_eq(session.board.mark(R5C4, d), AUTO, "r5c4's %d crossed by Auto Cross" % d)
	assert_eq(Ix.ring(session, X), crossed, "Auto Cross leaves hand marks alone")

	# 5. Place 7 in r5c2: X's open 7 is crossed by Auto Cross, out of sight.
	Ix.tap_cell(area, R5C2)
	Ix.tap_digit(area, 7)
	assert_eq(session.board.digit(R5C2), 7)
	assert_eq(session.board.mark(X, 7), AUTO)
	var hidden_marks: PackedByteArray = PackedByteArray(session.board.marks)

	# 6. Show candidates on: every ring exactly as it is, Place still on.
	_set_from_pause(h, &"show_candidates_switch", true)
	assert_true(area.view.draw_state().show_ring, "the rings show again")
	assert_true(area.pad.is_mode_visible(), "the mode buttons show again")
	assert_eq(session.mode, GameSession.Mode.PLACE, "Place stays on")
	assert_eq(area.pad.mode(), GameSession.Mode.PLACE)
	assert_eq(Ix.ring(session, X), [OPEN, HAND, HAND, HAND, OPEN, HAND, AUTO, OPEN, HAND], "SC-1 step 6")
	assert_eq(PackedByteArray(session.board.marks), hidden_marks, "turning it on changed no mark")
	var drawn: Array[int] = []
	var state: BoardDrawState = area.view.draw_state()
	for d: int in range(1, 10):
		drawn.append(state.marks[X * 9 + d - 1])
	assert_eq(drawn, Ix.ring(session, X), "the board draws X's ring as it is")
	Ix.close(h)
