extends "res://tests/unit_test.gd"
## BoardView: hit testing, cell rects, the draw state it builds from the
## session, and redraw requests only on change.

const Fx := preload("res://tests/board/board_fixtures.gd")

const X: int = 40

var view: BoardView
var session: GameSession
var pressed: Array[int] = []


func _build(side: float = 344.0) -> void:
	session = Fx.session_b()
	view = BoardView.new()
	view.skin = Fx.light()
	view.size = Vector2(side, side)
	Fx.root().add_child(view)
	view.session = session
	view.cell_pressed.connect(func(cell: int) -> void: pressed.append(cell))


func _center(cell: int) -> Vector2:
	var square: Rect2 = view.board_square()
	var pitch: float = square.size.x / 9.0
	return square.position + Vector2((float(cell % 9) + 0.5) * pitch, (float(cell / 9) + 0.5) * pitch)


func test_board_square_leaves_room_for_outer_line_and_shadow() -> void:
	_build()
	var skin: GameSkin = Fx.light()
	var square: Rect2 = view.board_square()
	assert_eq(square.size.x, square.size.y, "cells are square")
	assert_true(is_equal_approx(square.size.x, 344.0 - skin.line_outer_w - skin.shadow_offset))
	assert_true(is_equal_approx(square.position.x, skin.line_outer_w * 0.5))
	assert_true(is_equal_approx(square.position.y, skin.line_outer_w * 0.5))
	assert_true(square.end.x + skin.line_outer_w * 0.5 + skin.shadow_offset <= 344.0 + 0.001)


func test_tap_on_every_cell_center_reports_that_cell() -> void:
	_build()
	for cell: int in 81:
		view._gui_input(Fx.press(_center(cell)))
	assert_eq(pressed.size(), 81)
	for cell: int in 81:
		assert_eq(pressed[cell], cell)


func test_tap_near_cell_edges() -> void:
	_build()
	var square: Rect2 = view.board_square()
	var pitch: float = square.size.x / 9.0
	# Just right of the line between columns 0 and 1 on row 0, and just left.
	view._gui_input(Fx.press(square.position + Vector2(pitch + 0.2, 1.0)))
	view._gui_input(Fx.press(square.position + Vector2(pitch - 0.2, 1.0)))
	# The bottom right corner of the cells.
	view._gui_input(Fx.press(square.end - Vector2(0.1, 0.1)))
	assert_eq(pressed, [1, 0, 80] as Array[int])


func test_tap_off_the_cells_does_nothing() -> void:
	_build()
	var square: Rect2 = view.board_square()
	view._gui_input(Fx.press(Vector2(0.5, 0.5)))                 # on the outer line
	view._gui_input(Fx.press(square.end + Vector2(2.0, 2.0)))     # on the shadow
	view._gui_input(Fx.press(Vector2(-10.0, 50.0)))
	assert_true(pressed.is_empty())


func test_only_a_left_press_selects() -> void:
	_build()
	view._gui_input(Fx.release(_center(X)))
	var right: InputEventMouseButton = Fx.press(_center(X))
	right.button_index = MOUSE_BUTTON_RIGHT
	view._gui_input(right)
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = _center(X)
	view._gui_input(motion)
	assert_true(pressed.is_empty())
	view._gui_input(Fx.press(_center(X)))
	assert_eq(pressed, [X] as Array[int])


func test_touch_counts_once() -> void:
	_build()
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = _center(X)
	view._gui_input(touch)
	# With touch emulated as mouse (the default) the touch itself is skipped,
	# and the mouse event Godot makes from it selects.
	var emulated: bool = bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", true))
	assert_eq(pressed.size(), 0 if emulated else 1)


func test_cell_rect_global_follows_position() -> void:
	_build()
	view.position = Vector2(20.0, 130.0)
	var square: Rect2 = view.board_square()
	var pitch: float = square.size.x / 9.0
	var rect: Rect2 = view.cell_rect_global(X)
	assert_true(rect.position.is_equal_approx(Vector2(20.0, 130.0) + square.position + Vector2(4.0 * pitch, 4.0 * pitch)))
	assert_true(is_equal_approx(rect.size.x, pitch))
	assert_eq(view.cell_rect_global(-1), Rect2())
	assert_eq(view.cell_rect_global(81), Rect2())


func test_draw_state_follows_selection_and_digits() -> void:
	_build()
	var empty: BoardDrawState = view.draw_state()
	assert_eq(empty.selected, -1)
	assert_true(empty.peers.is_empty())
	session.select(36)                                     # the given 9 in r5c1
	session.set_mode(GameSession.Mode.CROSS_OUT)
	var state: BoardDrawState = view.draw_state()
	assert_eq(state.selected, 36)
	assert_eq(state.mode, GameSession.Mode.CROSS_OUT)
	assert_eq(state.peers, Sudoku.peers(36))
	assert_eq(state.digits, session.board.digits)
	assert_eq(state.givens, session.board.givens)
	assert_eq(state.marks, session.board.marks)
	assert_true(state.same_digit.is_empty(), "no other 9 on the board")
	assert_false(state.locked)


func test_draw_state_same_digit_and_conflicts() -> void:
	_build()
	session.select(X)
	session.press_digit(9)                                 # clashes with r5c1 in row 5
	var state: BoardDrawState = view.draw_state()
	assert_eq(state.same_digit, PackedInt32Array([36]))
	assert_eq(state.conflicts, PackedInt32Array([36, X]))


func test_draw_state_holds_copies() -> void:
	_build()
	session.select(X)
	var state: BoardDrawState = view.draw_state()
	session.press_digit(5)
	assert_eq(state.digits[X], 0, "a state already built does not change with the board")


func test_draw_state_shows_the_hint_and_its_crosses() -> void:
	_build()
	var hint: Hint = Hint.new()
	hint.technique = &"pointing"
	hint.targets = PackedInt32Array([39, 41])
	hint.reasons = PackedInt32Array([30, 32])
	hint.eliminations = PackedInt32Array([39 * 9 + 6, 41 * 9 + 6])
	assert_true(session.buy_hint(hint))
	var state: BoardDrawState = view.draw_state()
	assert_eq(state.hint_targets, hint.targets)
	assert_eq(state.hint_reasons, hint.reasons)
	assert_eq(state.hint_crosses, hint.eliminations)
	session.close_hint()
	state = view.draw_state()
	assert_true(state.hint_targets.is_empty())
	assert_true(state.hint_crosses.is_empty())


func test_lesson_marks_reach_the_state() -> void:
	_build()
	var marks: PackedInt32Array = PackedInt32Array([31, 49])
	view.lesson_marks = marks
	marks[0] = 0
	assert_eq(view.draw_state().lesson_marks, PackedInt32Array([31, 49]), "kept as a copy")


func test_redraw_requested_on_every_change() -> void:
	_build()
	var count: int = view._redraw_requests
	session.select(X)
	assert_true(view._redraw_requests > count, "selection")
	count = view._redraw_requests
	session.toggle_mode()
	assert_true(view._redraw_requests > count, "mode")
	count = view._redraw_requests
	session.press_digit(1)
	assert_true(view._redraw_requests > count, "board")
	count = view._redraw_requests
	var hint: Hint = Hint.new()
	hint.targets = PackedInt32Array([0])
	session.buy_hint(hint)
	assert_true(view._redraw_requests > count, "hint")
	count = view._redraw_requests
	view.lesson_marks = PackedInt32Array([3])
	assert_true(view._redraw_requests > count, "lesson marks")


func test_nothing_happening_requests_no_redraw() -> void:
	_build()
	session.select(X)
	var count: int = view._redraw_requests
	session.select(X)                     # already selected
	session.erase()                       # empty cell
	session.press_digit(0)                # not a digit
	session.add_time(5.0)
	assert_eq(view._redraw_requests, count)


func test_new_session_replaces_the_old_one() -> void:
	_build()
	var old: GameSession = session
	view.session = Fx.session_b()
	var count: int = view._redraw_requests
	old.select(X)
	assert_eq(view._redraw_requests, count, "the old session is no longer watched")


func test_completed_board_is_locked() -> void:
	_build()
	session = Fx.one_left(0)
	view.session = session
	session.select(0)
	session.press_digit(Fx.solution_digit(0))
	assert_true(view.draw_state().locked)


func test_play_effect_ignores_bad_cells_and_replaces_on_the_same_cell() -> void:
	_build()
	view.play_effect(CellEffect.Kind.PLACE, -1, 3)
	view.play_effect(CellEffect.Kind.PLACE, 81, 3)
	assert_true(view.running_effects().is_empty())
	view.play_effect(CellEffect.Kind.CROSS, X, 3)
	view.play_effect(CellEffect.Kind.RESTORE, X, 3)
	view.play_effect(CellEffect.Kind.CROSS, 0, 1)
	var effects: Array[CellEffect] = view.running_effects()
	assert_eq(effects.size(), 2)
	assert_eq(effects[0].kind, CellEffect.Kind.RESTORE)
	assert_eq(effects[1].cell, 0)


func test_scene_file_gives_a_board_view() -> void:
	var node: Node = (load("res://scenes/board/board_view.tscn") as PackedScene).instantiate()
	assert_true(node is BoardView)
	node.free()


func test_show_ring_reaches_the_state_and_redraws() -> void:
	_build()
	assert_true(view.draw_state().show_ring, "the ring shows by default")
	var count: int = view._redraw_requests
	view.show_ring = false
	assert_true(view._redraw_requests > count, "hiding the ring redraws")
	assert_false(view.draw_state().show_ring)
	count = view._redraw_requests
	view.show_ring = false
	assert_eq(view._redraw_requests, count, "no change, no redraw")
	view.show_ring = true
	assert_true(view.draw_state().show_ring)
	assert_true(view._redraw_requests > count, "showing it again redraws")
