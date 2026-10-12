class_name BoardController extends Node
## Maps board and pad input to the session (docs/ARCHITECTURE.md section 8):
## a cell tap selects, a digit presses it, the mode button toggles the mode,
## Erase erases and Undo undoes. Every rule is the session's; the controller
## only passes taps on and shows what came back: the click when result.click,
## the matching board effect, and the pad's mode, Undo and lock state, kept in
## step with the session's signals.
##
## A gate (lessons) sees each action first. When it refuses, nothing reaches
## the session and action_rejected is emitted instead.
## Owner: board-input-dev.

signal action_applied(action: BoardAction, result: ActionResult)
signal action_rejected(action: BoardAction)     # only when a gate refuses it

## Optional: func(action: BoardAction) -> bool. Lessons set it. An invalid
## Callable lets every action through.
var gate: Callable = Callable()

## The node whose play_click() plays the click. Null means the Audio autoload.
## Tests set their own.
var audio: Node = null

var _session: GameSession = null
var _view: BoardView = null
var _pad: NumberPad = null


func setup(session: GameSession, view: BoardView, pad: NumberPad) -> void:
	_unlink()
	_session = session
	_view = view
	_pad = pad
	if _view != null:
		_view.session = session
		_view.cell_pressed.connect(_on_cell_pressed)
	if _pad != null:
		_pad.digit_pressed.connect(_on_digit_pressed)
		_pad.mode_pressed.connect(_on_mode_pressed)
		_pad.erase_pressed.connect(_on_erase_pressed)
		_pad.undo_pressed.connect(_on_undo_pressed)
	if _session != null:
		_session.mode_changed.connect(_on_mode_changed)
		_session.undo_available_changed.connect(_on_undo_available_changed)
		_session.completed.connect(_on_completed)
	_sync_pad()


## The session set up last, or null.
func session() -> GameSession:
	return _session


## Runs one action as if it had been tapped: the gate, then the session.
func handle(action: BoardAction) -> void:
	if _session == null or action == null:
		return
	if gate.is_valid() and not bool(gate.call(action)):
		action_rejected.emit(action)
		return
	var board: Board = _session.board
	var digits_before: PackedInt32Array = board.digits.duplicate() if board != null else PackedInt32Array()
	var marks_before: PackedByteArray = board.marks.duplicate() if board != null else PackedByteArray()
	var result: ActionResult = ActionResult.new()
	match action.kind:
		BoardAction.Kind.CELL:
			var was: int = _session.selected
			_session.select(action.cell)
			result.applied = _session.selected != was
		BoardAction.Kind.PAD:
			result = _session.press_digit(action.digit)
		BoardAction.Kind.MODE:
			var old_mode: int = _session.mode
			_session.toggle_mode()
			result.applied = _session.mode != old_mode
		BoardAction.Kind.ERASE:
			result = _session.erase()
		BoardAction.Kind.UNDO:
			result = _session.undo()
	if result.applied and action.kind in [BoardAction.Kind.PAD, BoardAction.Kind.ERASE, BoardAction.Kind.UNDO]:
		_start_effect(digits_before, marks_before, result)
	if result.click:
		_play_click()
	action_applied.emit(action, result)


## The effect that shows what the action did to the cell it acted on, which
## is the selected cell afterwards (undo selects the cell it reverses).
## Undo therefore plays the effect of the reverse action (DESIGN_SYSTEM.md 6).
## A finished puzzle plays the completion wave over every cell instead.
func _start_effect(digits_before: PackedInt32Array, marks_before: PackedByteArray, result: ActionResult) -> void:
	if _view == null:
		return
	var board: Board = _session.board
	if result.completed:
		for cell: int in Sudoku.CELLS:
			_view.play_effect(CellEffect.Kind.COMPLETE, cell, board.digits[cell])
		return
	var cell: int = _session.selected
	if not Sudoku.is_cell(cell) or digits_before.size() != Sudoku.CELLS:
		return
	var old_digit: int = digits_before[cell]
	var new_digit: int = board.digits[cell]
	if new_digit != 0 and new_digit != old_digit:
		_view.play_effect(CellEffect.Kind.PLACE, cell, new_digit)
		return
	if new_digit == 0 and old_digit != 0:
		_view.play_effect(CellEffect.Kind.ERASE, cell, old_digit)
		return
	if new_digit != 0:
		return
	# A ring change in an empty cell. The effects animate the hand X, so only
	# a change to or from a hand cross gets one; an Auto Cross slash
	# appearing or going (undoing a restore of it, say) changes at once.
	for d: int in range(1, 10):
		var index: int = cell * 9 + d - 1
		var before: int = marks_before[index]
		var after: int = board.marks[index]
		if before == after:
			continue
		if after == Board.Mark.CROSSED_HAND:
			_view.play_effect(CellEffect.Kind.CROSS, cell, d)
		elif before == Board.Mark.CROSSED_HAND:
			_view.play_effect(CellEffect.Kind.RESTORE, cell, d)
		return


func _play_click() -> void:
	var player: Node = audio
	if player == null and is_inside_tree():
		player = get_node_or_null(^"/root/Audio")
	if player != null and player.has_method(&"play_click"):
		player.call(&"play_click")


func _sync_pad() -> void:
	if _pad == null:
		return
	if _session == null:
		_pad.set_mode(GameSession.Mode.PLACE)
		_pad.set_undo_enabled(false)
		_pad.set_locked(true)
		return
	_pad.set_mode(_session.mode)
	_pad.set_undo_enabled(_session.can_undo())
	_pad.set_locked(_session.is_completed)


func _unlink() -> void:
	if _view != null and is_instance_valid(_view) and _view.cell_pressed.is_connected(_on_cell_pressed):
		_view.cell_pressed.disconnect(_on_cell_pressed)
	if _pad != null and is_instance_valid(_pad):
		if _pad.digit_pressed.is_connected(_on_digit_pressed):
			_pad.digit_pressed.disconnect(_on_digit_pressed)
		if _pad.mode_pressed.is_connected(_on_mode_pressed):
			_pad.mode_pressed.disconnect(_on_mode_pressed)
		if _pad.erase_pressed.is_connected(_on_erase_pressed):
			_pad.erase_pressed.disconnect(_on_erase_pressed)
		if _pad.undo_pressed.is_connected(_on_undo_pressed):
			_pad.undo_pressed.disconnect(_on_undo_pressed)
	if _session != null:
		if _session.mode_changed.is_connected(_on_mode_changed):
			_session.mode_changed.disconnect(_on_mode_changed)
		if _session.undo_available_changed.is_connected(_on_undo_available_changed):
			_session.undo_available_changed.disconnect(_on_undo_available_changed)
		if _session.completed.is_connected(_on_completed):
			_session.completed.disconnect(_on_completed)


func _on_cell_pressed(cell: int) -> void:
	handle(BoardAction.create(BoardAction.Kind.CELL, cell))


func _on_digit_pressed(digit: int) -> void:
	handle(BoardAction.create(BoardAction.Kind.PAD, -1, digit))


func _on_mode_pressed() -> void:
	handle(BoardAction.create(BoardAction.Kind.MODE))


func _on_erase_pressed() -> void:
	handle(BoardAction.create(BoardAction.Kind.ERASE))


func _on_undo_pressed() -> void:
	handle(BoardAction.create(BoardAction.Kind.UNDO))


func _on_mode_changed(mode: int) -> void:
	if _pad != null:
		_pad.set_mode(mode)


func _on_undo_available_changed(_available: bool) -> void:
	# Ask the session rather than trust the flag: after completion it is false.
	if _pad != null and _session != null:
		_pad.set_undo_enabled(_session.can_undo())


func _on_completed(_seconds: int, _score: int) -> void:
	if _pad != null:
		_pad.set_locked(true)
		_pad.set_undo_enabled(false)
