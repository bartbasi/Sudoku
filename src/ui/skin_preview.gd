class_name SkinPreview
extends Control
## The mini board on a skin option card (DESIGN_SYSTEM.md 7.11): the top left
## 3 by 3 corner of a board drawn by BoardPainter in that card's own skin, on
## that skin's page color: a given, a placed digit, a ring with hand Xs and
## the selected cell.
## Owner: ui-systems-dev.

## Cells the preview shows across, a little more than three so the box line
## shows at the right and bottom.
const CELLS_SHOWN: float = 3.15
const GIVEN_CELL: int = 0
const PLACED_CELL: int = 1
const RING_CELL: int = 10
const GIVEN_DIGIT: int = 5
const PLACED_DIGIT: int = 3
const CROSSED_DIGITS: PackedInt32Array = [2, 7]

var skin: GameSkin = null

var _painter: BoardPainter = BoardPainter.new()
var _state: BoardDrawState = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_state = _make_state()
	resized.connect(_on_resized)


## Stays square: as wide as the card lets it be tall.
func _on_resized() -> void:
	if not is_equal_approx(custom_minimum_size.x, size.y):
		custom_minimum_size.x = size.y
	queue_redraw()


func _draw() -> void:
	if skin == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), skin.page_bg)
	var inset: float = skin.space_s
	var cell: float = maxf(1.0, (minf(size.x, size.y) - inset) / CELLS_SHOWN)
	var square: Rect2 = Rect2(Vector2(inset, inset), Vector2(cell, cell) * 9.0)
	_painter.draw_board(self, square, _state, skin)


static func _make_state() -> BoardDrawState:
	var state: BoardDrawState = BoardDrawState.new()
	var givens: PackedInt32Array = PackedInt32Array()
	givens.resize(Sudoku.CELLS)
	givens[GIVEN_CELL] = GIVEN_DIGIT
	var digits: PackedInt32Array = givens.duplicate()
	digits[PLACED_CELL] = PLACED_DIGIT
	var marks: PackedByteArray = PackedByteArray()
	marks.resize(Sudoku.CELLS * 9)
	for d: int in CROSSED_DIGITS:
		marks[RING_CELL * 9 + d - 1] = Board.Mark.CROSSED_HAND
	state.givens = givens
	state.digits = digits
	state.marks = marks
	state.selected = RING_CELL
	state.peers = Sudoku.peers(RING_CELL)
	return state
