class_name BoardAction extends RefCounted
## One player input on the board or the pad, before it reaches the session
## (docs/ARCHITECTURE.md section 8). BoardController builds one per tap and
## shows it to the gate (lessons) before mapping it to a GameSession call.
## Owner: board-input-dev.

enum Kind { CELL, PAD, MODE, ERASE, UNDO }

var kind: int
## The tapped cell, 0 to 80, for CELL. -1 for every other kind.
var cell: int = -1
## The tapped digit, 1 to 9, for PAD. 0 for every other kind.
var digit: int = 0


static func create(new_kind: int, new_cell: int = -1, new_digit: int = 0) -> BoardAction:
	var action: BoardAction = BoardAction.new()
	action.kind = new_kind
	action.cell = new_cell
	action.digit = new_digit
	return action
