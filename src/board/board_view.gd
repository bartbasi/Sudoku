class_name BoardView extends Control
## The board on screen (docs/ARCHITECTURE.md section 8): draws what the
## session says with one BoardPainter, and reports which cell a tap lands on.
## It decides no rule and changes nothing: taps go out as cell_pressed, and
## the owner (BoardController) passes them to the session.
##
## It redraws only when something changes: a session signal, the lesson
## marks, the skin or its size. Effects run on a child layer above the board,
## so an animation redraws only that layer. No node per cell or candidate.
##
## Its rect holds the board and the board's outer line and shadow: the cell
## square sits half an outer line in from the top left, and the outer line
## and shadow fit inside the bottom and right (DESIGN_SYSTEM.md 2.1).
## Scene: scenes/board/board_view.tscn. Owner: board-input-dev.

signal cell_pressed(cell: int)

const Support := preload("res://src/board/board_support.gd")

## Set by the owner. The view listens to its signals and redraws.
var session: GameSession = null:
	set(value):
		if session == value:
			return
		_watch(session, false)
		session = value
		_watch(session, true)
		_request_redraw()

## Cells a lesson screen points at, drawn in the hint reason look.
var lesson_marks: PackedInt32Array = PackedInt32Array():
	set(value):
		lesson_marks = value.duplicate()
		_request_redraw()

## The skin to draw with. Null means the Skins autoload's current skin, which
## is what the game uses; tests and captures set one directly.
var skin: GameSkin = null:
	set(value):
		skin = value
		_request_redraw()

var _painter: BoardPainter = BoardPainter.new()
var _layer: Control = null
var _effects: Array[CellEffect] = []
var _tweens: Array[Tween] = []
var _watched_service: Node = null
## Counts redraw requests, so tests can see that a change asks for one.
var _redraw_requests: int = 0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	_layer = Control.new()
	_layer.name = "Effects"
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.draw.connect(_draw_effects)
	add_child(_layer, false, Node.INTERNAL_MODE_FRONT)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			_watch_skins(Support.skin_service(self))
		NOTIFICATION_EXIT_TREE:
			_watch_skins(null)
			_stop_effects()
		NOTIFICATION_PREDELETE:
			_stop_effects()
		NOTIFICATION_RESIZED:
			_request_redraw()


func _draw() -> void:
	var current: GameSkin = current_skin()
	if current == null or session == null or session.board == null:
		return
	_painter.draw_board(self, board_square(), draw_state(), current)


func _gui_input(event: InputEvent) -> void:
	var at: Variant = Support.press_position(event)
	if at == null:
		return
	var cell: int = cell_at(at as Vector2)
	if cell < 0:
		return
	accept_event()
	cell_pressed.emit(cell)


## The skin the view draws with now.
func current_skin() -> GameSkin:
	return Support.skin_for(self, skin)


## The cell square, in local coordinates: the largest that fits once the
## outer line and the shadow have room.
func board_square() -> Rect2:
	var current: GameSkin = current_skin()
	if current == null:
		return BoardPainter.board_square(Rect2(Vector2.ZERO, size))
	var line: float = current.line_outer_w
	var over: float = line + current.shadow_offset
	var side: float = maxf(0.0, minf(size.x, size.y) - over)
	var x: float = (size.x - side - over) * 0.5 + line * 0.5
	return Rect2(x, line * 0.5, side, side)


## The cell under a local point, or -1 off the cells.
func cell_at(point: Vector2) -> int:
	return BoardPainter.cell_at(board_square(), point, current_skin())


## A cell's square on screen, for hint panel placement and lesson pointers.
## An empty Rect2 for a cell outside 0 to 80.
func cell_rect_global(cell: int) -> Rect2:
	var local: Rect2 = BoardPainter.cell_rect(board_square(), cell, current_skin())
	if not local.has_area():
		return Rect2()
	return get_global_transform() * local


## What the painter draws, built from the session now. Copies of the board's
## arrays, never the live ones.
func draw_state() -> BoardDrawState:
	var state: BoardDrawState = BoardDrawState.new()
	state.lesson_marks = lesson_marks.duplicate()
	if session == null or session.board == null:
		return state
	var board: Board = session.board
	state.digits = board.digits.duplicate()
	state.givens = board.givens.duplicate()
	state.marks = board.marks.duplicate()
	state.selected = session.selected
	state.mode = session.mode
	if Sudoku.is_cell(session.selected):
		state.peers = session.peer_cells()
		state.same_digit = session.same_digit_cells()
	state.conflicts = board.conflict_cells()
	var hint: Hint = session.hint
	if hint != null:
		state.hint_targets = hint.targets.duplicate()
		state.hint_reasons = hint.reasons.duplicate()
		state.hint_crosses = hint.eliminations.duplicate()
	state.locked = session.is_completed
	return state


## Starts a board effect (CellEffect.Kind) on a cell. The effect draws on the
## layer above the board while Motion's tween runs, then goes away. A new
## effect on a cell ends the one running there.
func play_effect(kind: int, cell: int, digit: int) -> void:
	if not Sudoku.is_cell(cell):
		return
	for running: CellEffect in _effects.duplicate():
		if running.cell == cell:
			_effects.erase(running)
	var effect: CellEffect = CellEffect.new()
	effect.kind = kind
	effect.cell = cell
	effect.digit = digit
	_effects.append(effect)
	var tween: Tween = Motion.effect_tween(self, effect, _layer.queue_redraw)
	tween.finished.connect(_end_effect.bind(effect, tween))
	_tweens.append(tween)
	_layer.queue_redraw()


## The effects running now, oldest first.
func running_effects() -> Array[CellEffect]:
	return _effects.duplicate()


func _end_effect(effect: CellEffect, tween: Tween) -> void:
	_effects.erase(effect)
	_tweens.erase(tween)
	if is_instance_valid(_layer):
		_layer.queue_redraw()


## Leaving the screen, or being freed, ends every effect with nothing left
## running. Motion runs a view's tweens on the SceneTree while the view is
## outside the tree, so they would outlive it.
func _stop_effects() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	_effects.clear()


func _draw_effects() -> void:
	var current: GameSkin = current_skin()
	if current == null or _effects.is_empty():
		return
	_painter.draw_effects(_layer, board_square(), _effects, current)


## Board first, then the effects layer, so in a shared frame the effects use
## the board's new state.
func _request_redraw() -> void:
	_redraw_requests += 1
	queue_redraw()
	if _layer != null and not _effects.is_empty():
		_layer.queue_redraw()


func _on_board_changed(_cells: PackedInt32Array) -> void:
	_request_redraw()


func _on_cell_changed(_cell: int) -> void:
	_request_redraw()


func _on_hint_changed(_hint: Hint) -> void:
	_request_redraw()


func _on_completed(_seconds: int, _score: int) -> void:
	_request_redraw()


func _on_skin_changed(_skin: GameSkin) -> void:
	_request_redraw()


func _watch(target: GameSession, on: bool) -> void:
	if target == null:
		return
	var links: Array[Array] = [
		[target.board_changed, _on_board_changed],
		[target.selection_changed, _on_cell_changed],
		[target.mode_changed, _on_cell_changed],
		[target.hint_changed, _on_hint_changed],
		[target.completed, _on_completed],
	]
	for link: Array in links:
		var sig: Signal = link[0]
		var handler: Callable = link[1]
		if on and not sig.is_connected(handler):
			sig.connect(handler)
		elif not on and sig.is_connected(handler):
			sig.disconnect(handler)


func _watch_skins(service: Node) -> void:
	if _watched_service != null and is_instance_valid(_watched_service) \
			and _watched_service.is_connected(&"skin_changed", _on_skin_changed):
		_watched_service.disconnect(&"skin_changed", _on_skin_changed)
	_watched_service = service
	if service != null and service.has_signal(&"skin_changed"):
		service.connect(&"skin_changed", _on_skin_changed)
