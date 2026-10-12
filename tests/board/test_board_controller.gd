extends "res://tests/unit_test.gd"
## BoardController: input mapped to session calls, the gate, the click, the
## effects it starts, and the pad kept in step with the session.

const Fx := preload("res://tests/board/board_fixtures.gd")

## X = r5c5 and an empty peer r5c2 (0-based cells).
const X: int = 40
const Y: int = 37

var session: GameSession
var view: BoardView
var pad: NumberPad
var controller: BoardController
var audio: Fx.FakeAudio
var applied: Array[BoardAction] = []
var results: Array[ActionResult] = []
var rejected: Array[BoardAction] = []


func _build(new_session: GameSession) -> void:
	session = new_session
	view = BoardView.new()
	view.skin = Fx.light()
	view.size = Vector2(344, 344)
	pad = NumberPad.new()
	pad.skin = Fx.light()
	controller = BoardController.new()
	audio = Fx.FakeAudio.new()
	controller.audio = audio
	var root: Window = Fx.root()
	for node: Node in [view, pad, controller, audio]:
		root.add_child(node)
	controller.action_applied.connect(func(action: BoardAction, result: ActionResult) -> void:
		applied.append(action)
		results.append(result))
	controller.action_rejected.connect(func(action: BoardAction) -> void:
		rejected.append(action))
	controller.setup(session, view, pad)


func _kinds() -> Array[int]:
	var out: Array[int] = []
	for effect: CellEffect in view.running_effects():
		out.append(effect.kind)
	return out


func _last_effect() -> CellEffect:
	var effects: Array[CellEffect] = view.running_effects()
	return effects[effects.size() - 1] if not effects.is_empty() else null


# Mapping ----------------------------------------------------------------------

func test_cell_tap_selects() -> void:
	_build(Fx.session_b())
	view.cell_pressed.emit(X)
	assert_eq(session.selected, X)
	assert_eq(applied.size(), 1)
	assert_eq(applied[0].kind, BoardAction.Kind.CELL)
	assert_eq(applied[0].cell, X)
	assert_true(results[0].applied, "a new selection is applied")
	view.cell_pressed.emit(X)
	assert_eq(session.selected, X, "tapping the selected cell keeps it")
	assert_false(results[1].applied)
	assert_eq(audio.clicks, 0, "selection never clicks")


func test_cell_tap_selects_a_given() -> void:
	_build(Fx.session_b())
	view.cell_pressed.emit(36)
	assert_eq(session.selected, 36)


func test_digit_places_with_click_and_effect() -> void:
	_build(Fx.session_b())
	view.cell_pressed.emit(X)
	pad.digit_pressed.emit(8)
	assert_eq(session.board.digit(X), 8)
	assert_eq(applied[1].kind, BoardAction.Kind.PAD)
	assert_eq(applied[1].digit, 8)
	assert_true(results[1].applied)
	assert_eq(audio.clicks, 1)
	var effect: CellEffect = _last_effect()
	assert_eq(effect.kind, CellEffect.Kind.PLACE)
	assert_eq(effect.cell, X)
	assert_eq(effect.digit, 8)


func test_replace_plays_place_of_new_digit() -> void:
	_build(Fx.session_b())
	view.cell_pressed.emit(X)
	pad.digit_pressed.emit(8)
	pad.digit_pressed.emit(5)
	assert_eq(session.board.digit(X), 5)
	assert_eq(audio.clicks, 2)
	assert_eq(_last_effect().kind, CellEffect.Kind.PLACE)
	assert_eq(_last_effect().digit, 5)
	assert_eq(view.running_effects().size(), 1, "a new effect on the cell ends the old one")


func test_same_digit_again_does_nothing() -> void:
	_build(Fx.session_b())
	view.cell_pressed.emit(X)
	pad.digit_pressed.emit(8)
	var effects_before: int = view.running_effects().size()
	pad.digit_pressed.emit(8)
	assert_false(results[2].applied)
	assert_eq(audio.clicks, 1, "nothing happens: no click")
	assert_eq(view.running_effects().size(), effects_before)


func test_no_selection_does_nothing() -> void:
	_build(Fx.session_b())
	pad.digit_pressed.emit(5)
	pad.erase_pressed.emit()
	pad.undo_pressed.emit()
	assert_eq(audio.clicks, 0)
	assert_true(view.running_effects().is_empty())
	for result: ActionResult in results:
		assert_false(result.applied)
	assert_false(session.can_undo())


func test_given_is_locked() -> void:
	_build(Fx.session_b())
	view.cell_pressed.emit(36)
	for d: int in range(1, 10):
		pad.digit_pressed.emit(d)
	pad.erase_pressed.emit()
	pad.mode_pressed.emit()
	for d: int in range(1, 10):
		pad.digit_pressed.emit(d)
	assert_eq(session.board.digit(36), 9)
	assert_eq(audio.clicks, 0)
	assert_true(view.running_effects().is_empty())
	assert_false(pad.is_undo_enabled())


func test_mode_toggles_and_pad_follows() -> void:
	_build(Fx.session_b())
	view.cell_pressed.emit(X)
	pad.mode_pressed.emit()
	assert_eq(session.mode, GameSession.Mode.CROSS_OUT)
	assert_eq(pad.mode(), GameSession.Mode.CROSS_OUT)
	assert_eq(session.selected, X, "the selection stays")
	assert_eq(applied[1].kind, BoardAction.Kind.MODE)
	pad.mode_pressed.emit()
	assert_eq(session.mode, GameSession.Mode.PLACE)
	assert_eq(pad.mode(), GameSession.Mode.PLACE)
	assert_eq(audio.clicks, 0, "mode switches never click")
	assert_false(pad.is_undo_enabled(), "not an undo step")


func test_pad_follows_mode_set_elsewhere() -> void:
	_build(Fx.session_b())
	session.set_mode(GameSession.Mode.CROSS_OUT)
	assert_eq(pad.mode(), GameSession.Mode.CROSS_OUT)


func test_cross_and_restore() -> void:
	_build(Fx.session_b())
	view.cell_pressed.emit(X)
	pad.mode_pressed.emit()
	pad.digit_pressed.emit(3)
	assert_eq(session.board.mark(X, 3), Board.Mark.CROSSED_HAND)
	assert_eq(audio.clicks, 1)
	assert_eq(_last_effect().kind, CellEffect.Kind.CROSS)
	assert_eq(_last_effect().digit, 3)
	pad.digit_pressed.emit(3)
	assert_eq(session.board.mark(X, 3), Board.Mark.RESTORED_HAND)
	assert_eq(audio.clicks, 2)
	assert_eq(_last_effect().kind, CellEffect.Kind.RESTORE)


func test_cross_out_on_a_digit_does_nothing() -> void:
	_build(Fx.session_b())
	view.cell_pressed.emit(X)
	pad.digit_pressed.emit(6)
	pad.mode_pressed.emit()
	var clicks: int = audio.clicks
	pad.digit_pressed.emit(1)
	assert_eq(audio.clicks, clicks)
	assert_eq(session.board.mark(X, 1), Board.Mark.OPEN)


func test_erase_plays_erase_without_click() -> void:
	_build(Fx.session_b())
	view.cell_pressed.emit(X)
	pad.digit_pressed.emit(7)
	pad.erase_pressed.emit()
	assert_eq(session.board.digit(X), 0)
	assert_eq(audio.clicks, 1, "only the placement clicked")
	assert_eq(_last_effect().kind, CellEffect.Kind.ERASE)
	assert_eq(_last_effect().digit, 7)
	pad.erase_pressed.emit()
	assert_false(results[results.size() - 1].applied, "erasing an empty cell does nothing")


func test_undo_plays_the_reverse_effect() -> void:
	_build(Fx.session_b())
	view.cell_pressed.emit(X)
	pad.digit_pressed.emit(8)          # place
	pad.digit_pressed.emit(5)          # replace
	view.cell_pressed.emit(Y)
	pad.mode_pressed.emit()
	pad.digit_pressed.emit(2)          # cross in Y
	var clicks: int = audio.clicks
	pad.undo_pressed.emit()
	assert_eq(session.board.mark(Y, 2), Board.Mark.OPEN)
	assert_eq(_last_effect().kind, CellEffect.Kind.RESTORE, "undoing a cross plays RESTORE")
	assert_eq(_last_effect().cell, Y)
	pad.undo_pressed.emit()
	assert_eq(session.selected, X, "undo selects the cell it reverses")
	assert_eq(session.board.digit(X), 8)
	assert_eq(_last_effect().kind, CellEffect.Kind.PLACE, "undoing a replace places the old digit")
	assert_eq(_last_effect().digit, 8)
	pad.undo_pressed.emit()
	assert_eq(session.board.digit(X), 0)
	assert_eq(_last_effect().kind, CellEffect.Kind.ERASE, "undoing a placement plays ERASE")
	assert_eq(_last_effect().digit, 8)
	assert_eq(audio.clicks, clicks, "undo never clicks")
	assert_eq(session.mode, GameSession.Mode.CROSS_OUT, "undo never changes the mode")


func test_undo_of_erase_plays_place() -> void:
	_build(Fx.session_b())
	view.cell_pressed.emit(X)
	pad.digit_pressed.emit(7)
	pad.erase_pressed.emit()
	pad.undo_pressed.emit()
	assert_eq(session.board.digit(X), 7)
	assert_eq(_last_effect().kind, CellEffect.Kind.PLACE)
	assert_eq(_last_effect().digit, 7)


func test_undo_of_restoring_an_auto_cross_plays_no_hand_x() -> void:
	_build(Fx.session_b(true))
	view.cell_pressed.emit(X)
	pad.mode_pressed.emit()
	assert_eq(session.board.mark(X, 2), Board.Mark.CROSSED_AUTO)
	pad.digit_pressed.emit(2)
	assert_eq(session.board.mark(X, 2), Board.Mark.RESTORED_HAND)
	assert_true(view.running_effects().is_empty(), "the slash goes at once; no hand X fades out")
	pad.undo_pressed.emit()
	assert_eq(session.board.mark(X, 2), Board.Mark.CROSSED_AUTO)
	assert_true(view.running_effects().is_empty(), "the slash comes back at once")


func test_undo_state_follows_the_session() -> void:
	_build(Fx.session_b())
	assert_false(pad.is_undo_enabled(), "nothing to undo at the start")
	view.cell_pressed.emit(X)
	pad.digit_pressed.emit(4)
	assert_true(pad.is_undo_enabled())
	pad.digit_pressed.emit(4)
	assert_true(pad.is_undo_enabled())
	pad.undo_pressed.emit()
	assert_false(pad.is_undo_enabled(), "back at the start")


func test_setup_takes_the_state_of_a_resumed_session() -> void:
	var resumed: GameSession = Fx.session_b()
	resumed.select(X)
	resumed.press_digit(6)
	resumed.set_mode(GameSession.Mode.CROSS_OUT)
	_build(resumed)
	assert_eq(pad.mode(), GameSession.Mode.CROSS_OUT)
	assert_true(pad.is_undo_enabled())
	assert_false(pad.is_locked())
	assert_eq(view.session, resumed, "the view draws the same session")


func test_setup_again_lets_go_of_the_old_session() -> void:
	_build(Fx.session_b())
	var old: GameSession = session
	var fresh: GameSession = Fx.session_b()
	controller.setup(fresh, view, pad)
	view.cell_pressed.emit(X)
	assert_eq(fresh.selected, X)
	assert_eq(old.selected, -1, "taps no longer reach the old session")
	old.set_mode(GameSession.Mode.CROSS_OUT)
	assert_eq(pad.mode(), GameSession.Mode.PLACE, "the old session no longer drives the pad")
	assert_eq(view.session, fresh)


func test_completion_locks_and_plays_the_wave() -> void:
	_build(Fx.one_left(0))
	view.cell_pressed.emit(0)
	pad.digit_pressed.emit(Fx.solution_digit(0))
	assert_true(session.is_completed)
	assert_true(results[1].completed)
	assert_true(pad.is_locked())
	assert_false(pad.is_undo_enabled())
	assert_eq(audio.clicks, 1)
	var kinds: Array[int] = _kinds()
	assert_eq(kinds.size(), 81, "one wave effect per cell")
	for kind: int in kinds:
		assert_eq(kind, CellEffect.Kind.COMPLETE)
	assert_true(view.draw_state().locked)


func test_full_board_with_a_clash_does_not_lock() -> void:
	_build(Fx.one_left(0))
	view.cell_pressed.emit(0)
	var wrong: int = 1 if Fx.solution_digit(0) != 1 else 2
	pad.digit_pressed.emit(wrong)
	assert_true(results[1].full_board_conflict)
	assert_false(pad.is_locked())
	assert_eq(_last_effect().kind, CellEffect.Kind.PLACE)


# The gate ---------------------------------------------------------------------

func test_gate_refusal_changes_nothing() -> void:
	_build(Fx.session_b())
	view.cell_pressed.emit(X)
	var seen: Array[BoardAction] = []
	controller.gate = func(action: BoardAction) -> bool:
		seen.append(action)
		return false
	view.cell_pressed.emit(Y)
	pad.digit_pressed.emit(5)
	pad.mode_pressed.emit()
	pad.erase_pressed.emit()
	pad.undo_pressed.emit()
	assert_eq(session.selected, X, "the selection stays")
	assert_eq(session.board.digit(X), 0)
	assert_eq(session.mode, GameSession.Mode.PLACE)
	assert_eq(audio.clicks, 0)
	assert_true(view.running_effects().is_empty())
	assert_eq(rejected.size(), 5)
	assert_eq(applied.size(), 1, "only the tap before the gate was applied")
	assert_eq(seen.size(), 5)
	assert_eq(seen[0].kind, BoardAction.Kind.CELL)
	assert_eq(seen[0].cell, Y)
	assert_eq(seen[1].kind, BoardAction.Kind.PAD)
	assert_eq(seen[1].digit, 5)
	assert_eq(seen[2].kind, BoardAction.Kind.MODE)
	assert_eq(seen[3].kind, BoardAction.Kind.ERASE)
	assert_eq(seen[4].kind, BoardAction.Kind.UNDO)


func test_gate_lets_through_what_it_accepts() -> void:
	_build(Fx.session_b())
	controller.gate = func(action: BoardAction) -> bool:
		return action.kind == BoardAction.Kind.CELL or (action.kind == BoardAction.Kind.PAD and action.digit == 8)
	view.cell_pressed.emit(X)
	pad.digit_pressed.emit(5)
	pad.digit_pressed.emit(8)
	assert_eq(session.board.digit(X), 8)
	assert_eq(rejected.size(), 1)
	assert_eq(rejected[0].digit, 5)
	assert_eq(audio.clicks, 1)


func test_lesson_session_works_through_the_controller() -> void:
	var board: Board = Board.create(Fx.position_b())
	_build(GameSession.for_lesson(board, GameSession.Mode.CROSS_OUT, X))
	assert_eq(pad.mode(), GameSession.Mode.CROSS_OUT)
	for d: int in [2, 3, 4, 6, 9]:
		pad.digit_pressed.emit(d)
	for d: int in [2, 3, 4, 6, 9]:
		assert_eq(board.mark(X, d), Board.Mark.CROSSED_HAND)
	assert_eq(audio.clicks, 5)
