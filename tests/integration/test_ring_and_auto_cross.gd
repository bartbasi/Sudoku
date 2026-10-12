extends "res://tests/unit_test.gd"
## Phase 4 verify items 2 and 4, end to end: Bart's candidate example (GDD
## 4.4, AT-14) in Cross Out mode on the play screen, and Auto Cross turned on
## and off from Settings without touching hand marks (GDD 5.3, AC-1 to AC-7).
## Position B is resumed from a save, as if an earlier run had left it.

const Ix := preload("res://tests/integration/integration_fixtures.gd")

const X: int = 40         # r5c5
const R5C2: int = 37
const R2C5: int = 13
const OPEN: int = Board.Mark.OPEN
const HAND: int = Board.Mark.CROSSED_HAND
const RESTORED: int = Board.Mark.RESTORED_HAND
const AUTO: int = Board.Mark.CROSSED_AUTO


## Position B in progress, resumed through Continue on the main menu.
func _resume_position_b(tag: String) -> Ix.Harness:
	var dir: String = Ix.new_dir(tag)
	Ix.write_settings(dir)
	Ix.write_session(dir, Ix.position_b_session())
	var h: Ix.Harness = Ix.open_app(dir)
	assert_true(h.app.has_puzzle_in_progress(), "Position B loads as the puzzle in progress")
	var go_on: Button = h.top().get(&"continue_button")
	assert_true(Ix.click(go_on), "Continue")
	Ix.fit(h)
	assert_eq(h.screen_name(), AppService.PLAY)
	return h


func _ring_of(state: BoardDrawState, cell: int) -> Array[int]:
	var out: Array[int] = []
	for d: int in range(1, 10):
		out.append(state.marks[cell * 9 + d - 1])
	return out


func test_barts_example_in_cross_out_mode() -> void:
	var h: Ix.Harness = _resume_position_b("bart")
	var area: PlayArea = Ix.play_area_of(h.top())
	var session: GameSession = h.app.session
	var clicks: int = Ix.clicks(h)
	Ix.tap_cell(area, X)
	assert_eq(session.selected, X)
	Ix.tap_mode(area, GameSession.Mode.CROSS_OUT)
	assert_eq(session.mode, GameSession.Mode.CROSS_OUT)
	assert_eq(session.selected, X, "switching modes keeps the selection")
	for d: int in [2, 3, 4, 6, 9]:
		Ix.tap_digit(area, d)
	var crossed: Array[int] = [OPEN, HAND, HAND, HAND, OPEN, HAND, OPEN, OPEN, HAND]
	assert_eq(Ix.ring(session, X), crossed, "2, 3, 4, 6 and 9 crossed by hand; 1, 5, 7 and 8 open")
	assert_eq(_ring_of(area.view.draw_state(), X), crossed, "the board draws the same ring")
	assert_eq(Ix.clicks(h) - clicks, 5, "a click per cross")
	Ix.tap_mode(area, GameSession.Mode.PLACE)
	Ix.tap_digit(area, 8)
	assert_eq(session.board.digit(X), 8, "X shows 8")
	assert_eq(area.view.draw_state().digits[X], 8)
	Ix.tap_key(area, NumberPad.ERASE)
	assert_eq(session.board.digit(X), 0)
	assert_eq(Ix.ring(session, X), crossed, "Erase brings the ring back as it was")
	assert_eq(_ring_of(area.view.draw_state(), X), crossed)
	assert_eq(Ix.ring(h.app.load_session_file(), X), crossed, "saved")
	Ix.close(h)


func test_auto_cross_on_and_off_never_touches_hand_marks() -> void:
	var h: Ix.Harness = _resume_position_b("auto")
	var screen: Control = h.top()
	var area: PlayArea = Ix.play_area_of(screen)
	var session: GameSession = h.app.session
	assert_false(session.auto_cross, "AT-21: off by default")

	# AC-1: hand marks first, then Auto Cross on from Settings.
	Ix.tap_cell(area, X)
	Ix.tap_mode(area, GameSession.Mode.CROSS_OUT)
	for d: int in [9, 1, 6, 6]:
		Ix.tap_digit(area, d)
	var hand_x: Array[int] = [HAND, OPEN, OPEN, OPEN, OPEN, RESTORED, OPEN, OPEN, HAND]
	assert_eq(Ix.ring(session, X), hand_x)
	_set_auto_cross(h, true)
	assert_true(session.auto_cross, "the setting reaches the puzzle in progress")
	assert_eq(Ix.ring(session, X), [HAND, AUTO, AUTO, AUTO, OPEN, RESTORED, OPEN, OPEN, HAND] as Array[int], "AC-1")
	assert_eq(Ix.ring(session, 39).slice(1, 4), [AUTO, AUTO, AUTO], "AC-1: r5c4 gets 2, 3 and 4")
	assert_eq(session.board.mark(39, 9), AUTO, "AC-1: r5c4 gets 9")
	assert_eq(_ring_of(area.view.draw_state(), X), Ix.ring(session, X), "the board redraws at once")
	assert_true(h.app.load_session_file().auto_cross, "saved")

	# AC-2: placing 7 in r5c2 crosses every open 7 around it.
	Ix.place(area, R5C2, 7)
	assert_eq(session.board.mark(X, 7), AUTO, "AC-2")
	assert_eq(session.board.mark(X, 9), HAND, "no hand mark changes")
	assert_eq(session.board.mark(X, 6), RESTORED)

	# AC-7 style: turning it off changes nothing; then an erase reopens nothing.
	var before_off: PackedByteArray = session.board.marks.duplicate()
	_set_auto_cross(h, false)
	assert_false(session.auto_cross)
	assert_eq(session.board.marks, before_off, "turning it off changes nothing on the board")
	Ix.tap_cell(area, R5C2)
	Ix.tap_key(area, NumberPad.ERASE)
	assert_eq(session.board.digit(R5C2), 0)
	assert_eq(session.board.mark(X, 7), AUTO, "off: nothing reopens")

	# Back on: X's 7 opens, the hand marks stay.
	_set_auto_cross(h, true)
	assert_eq(Ix.ring(session, X), [HAND, AUTO, AUTO, AUTO, OPEN, RESTORED, OPEN, OPEN, HAND] as Array[int], "AC-7: 7 opens")

	# AC-5: restore an Auto Cross X by hand; it is never crossed again.
	Ix.tap_cell(area, X)
	Ix.tap_mode(area, GameSession.Mode.CROSS_OUT)
	Ix.tap_digit(area, 2)
	assert_eq(session.board.mark(X, 2), RESTORED)
	Ix.place(area, 44, 2)    # r5c9 = 2 rules it out again
	assert_eq(session.board.mark(X, 2), RESTORED, "AC-5")

	# Off again: a hand cross survives everything.
	_set_auto_cross(h, false)
	assert_eq(session.board.mark(X, 1), HAND)
	assert_eq(session.board.mark(X, 9), HAND)
	assert_eq(session.board.mark(X, 6), RESTORED)
	assert_false(h.app.load_session_file().auto_cross)
	assert_false(h.app.settings.auto_cross)
	Ix.close(h)


func test_auto_cross_switch_from_the_main_menu_settings_applies_on_resume() -> void:
	var dir: String = Ix.new_dir("auto_menu")
	Ix.write_settings(dir)
	Ix.write_session(dir, Ix.position_b_session())
	var h: Ix.Harness = Ix.open_app(dir)
	assert_true(Ix.click(h.top().get(&"settings_button") as Button))
	Ix.fit(h)
	assert_true(Ix.set_switch(h.top().get(&"auto_cross_switch") as CheckButton, true))
	h.app.go_back()
	Ix.fit(h)
	Ix.click(h.top().get(&"continue_button") as Button)
	Ix.fit(h)
	var session: GameSession = h.app.session
	assert_true(session.auto_cross)
	assert_eq(session.board.mark(X, 4), AUTO, "the puzzle in progress follows the setting")
	Ix.close(h)


## Pause, Settings, the Auto Cross switch, Back, Resume: the player's path.
func _set_auto_cross(h: Ix.Harness, on: bool) -> void:
	var screen: Control = h.top()
	var hud: PlayHud = screen.get(&"hud")
	assert_true(Ix.click(hud.pause_button), "pause")
	var pause: PauseMenu = screen.get(&"pause_menu")
	assert_true(Ix.click(pause.settings_button), "Settings")
	Ix.fit(h)
	assert_eq(h.screen_name(), AppService.SETTINGS)
	var switch: CheckButton = h.top().get(&"auto_cross_switch")
	assert_true(Ix.set_switch(switch, on), "the switch")
	assert_eq(h.app.settings.auto_cross, on)
	h.app.go_back()
	assert_eq(h.screen_name(), AppService.PLAY)
	assert_true(Ix.click(pause.resume_button), "Resume")
	assert_false(pause.is_open())
