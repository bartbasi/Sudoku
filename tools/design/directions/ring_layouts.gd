extends RefCounted
## Candidate ring layouts and board cell geometry for the Phase 1 prototypes.
## Every direction places cells and candidates with these functions, so the
## ring layouts look and measure the same in all three directions.
## Prototype code in tools/, never shipped. Owner: senior-graphic-designer.
## The layouts are explained in docs/design/ring-layouts.md.
##
## A ring layout is a few rows of slots, top to bottom. Each row spreads its
## slots evenly from the left edge of the ring box to the right edge; the
## rows spread evenly from top to bottom. A 0 marks an empty position, which
## keeps the center of the cell open. Every digit sits in the same slot in
## every cell.

const Fonts := preload("res://tools/design/directions/fonts.gd")
const Palettes := preload("res://tools/design/directions/palettes.gd")

enum Layout { ROWS, CLOCKWISE, CLOCKWISE_WIDE }

## The layout the four screens use. The ring close-ups show all of them.
const DEFAULT_LAYOUT: int = Layout.ROWS

const COUNT: int = 3

const SLUGS: Array[String] = ["rows", "clockwise", "clockwise-wide"]
const NAMES: Array[String] = ["Reading rows", "Clockwise", "Clockwise wide"]

## Slot rows per layout, top to bottom. 0 is an empty position.
const _GRIDS: Array = [
	# Reading rows: read it like a page.
	[[1, 2, 3, 4], [5, 0, 6], [7, 8, 9]],
	# Clockwise: 1 2 3 across the top, then around the cell.
	[[1, 2, 3], [9, 0, 4], [8, 0, 5], [7, 0, 6]],
	# Clockwise wide: four across the top, then around the cell.
	[[1, 2, 3, 4], [9, 0, 5], [8, 7, 6]],
]

## Space between neighboring candidate ink boxes, as a share of the font size.
const GAP: float = 0.14


## The slot rows of a layout.
static func rows(layout: int) -> Array[PackedInt32Array]:
	var result: Array[PackedInt32Array] = []
	for row: Array in _GRIDS[layout]:
		result.append(PackedInt32Array(row))
	return result


## Row and column of a digit's slot, and the size of its row:
## Vector3i(row, position in row, positions in that row).
static func slot_of(layout: int, digit: int) -> Vector3i:
	var grid: Array[PackedInt32Array] = rows(layout)
	for r: int in grid.size():
		var position: int = grid[r].find(digit)
		if position != -1:
			return Vector3i(r, position, grid[r].size())
	push_error("Digit %d is not in layout %d" % [digit, layout])
	return Vector3i(0, 0, 1)


## The largest font size at which every candidate fits in a ring box of side
## ring_side without touching its neighbors. Multiply by the direction's
## candidate type size (1.0 in all three) for the size to draw at.
static func fit_font_size(layout: int, ring_side: float, font: Font) -> int:
	# Ink boxes scale linearly with the font size; measure at 100 and scale.
	var unit: Vector2 = Fonts.digit_cell(font, 100) / 100.0
	var grid: Array[PackedInt32Array] = rows(layout)
	var best: float = INF
	for row: PackedInt32Array in grid:
		var n: float = float(row.size())
		best = minf(best, ring_side / (n * unit.x + (n - 1.0) * GAP))
	var r: float = float(grid.size())
	best = minf(best, ring_side / (r * unit.y + (r - 1.0) * GAP))
	return maxi(1, floori(best))


## The font size to draw candidates at, for a direction's candidate style.
static func candidate_font_size(direction: String, layout: int, ring_side: float, font: Font) -> int:
	var style: Palettes.TypeStyle = Palettes.type_style(direction, Palettes.ROLE_CANDIDATE)
	return maxi(1, floori(float(fit_font_size(layout, ring_side, font)) * style.size))


## Center of a digit's slot inside ring_box, for candidates drawn with font
## at font_size. Draw the digit with Fonts.draw_centered() at this point.
static func slot_center(layout: int, digit: int, ring_box: Rect2, font: Font, font_size: int) -> Vector2:
	var cell: Vector2 = Fonts.digit_cell(font, font_size)
	var slot: Vector3i = slot_of(layout, digit)
	var row_count: int = _GRIDS[layout].size()
	var x: float = ring_box.position.x + cell.x * 0.5
	if slot.z > 1:
		x += float(slot.y) * (ring_box.size.x - cell.x) / float(slot.z - 1)
	var y: float = ring_box.position.y + cell.y * 0.5
	if row_count > 1:
		y += float(slot.x) * (ring_box.size.y - cell.y) / float(row_count - 1)
	return Vector2(x, y)


## The slot box of a digit: the widest and tallest digit ink box, centered on
## the slot.
static func slot_rect(layout: int, digit: int, ring_box: Rect2, font: Font, font_size: int) -> Rect2:
	var cell: Vector2 = Fonts.digit_cell(font, font_size)
	var center: Vector2 = slot_center(layout, digit, ring_box, font, font_size)
	return Rect2(center - cell * 0.5, cell)


## The box the hand X (both diagonals) and the Auto Cross slash (the rising
## diagonal only) are drawn in: the slot box scaled by the direction's
## x_size, centered. Keeps the marks of neighboring candidates apart.
static func mark_rect(direction: String, layout: int, digit: int, ring_box: Rect2, font: Font, font_size: int) -> Rect2:
	var slot: Rect2 = slot_rect(layout, digit, ring_box, font, font_size)
	var mark: Vector2 = slot.size * Palettes.shape(direction).x_size
	return Rect2(slot.get_center() - mark * 0.5, mark)


## Scale from design units to the board as drawn: drawn side / board_size.
static func board_scale(direction: String, board_rect: Rect2) -> float:
	var shape: Palettes.Shape = Palettes.shape(direction)
	return minf(board_rect.size.x, board_rect.size.y) / shape.board_size


## The square the board occupies inside a control of the given size: the
## largest square that fits, centered.
static func board_square(control_size: Vector2) -> Rect2:
	var side: float = minf(control_size.x, control_size.y)
	return Rect2((control_size - Vector2(side, side)) * 0.5, Vector2(side, side))


## The rectangle of cell index (0 to 80, row by row) on a board drawn in
## board_rect. Lines style: the cell's pitch rect (lines are drawn centered on
## its edges). Tiles style: the tile itself.
static func cell_rect(direction: String, board_rect: Rect2, index: int) -> Rect2:
	var shape: Palettes.Shape = Palettes.shape(direction)
	var k: float = board_scale(direction, board_rect)
	var side: float = minf(board_rect.size.x, board_rect.size.y)
	var row: int = index / 9
	var col: int = index % 9
	if shape.style == Palettes.STYLE_TILES:
		var pad: float = shape.board_pad * k
		var gutter: float = shape.box_gap * k
		var gap: float = shape.cell_gap * k
		var card: float = (side - 2.0 * pad - 2.0 * gutter) / 3.0
		var tile: float = (card - 4.0 * gap) / 3.0
		var x: float = pad + float(col / 3) * (card + gutter) + gap + float(col % 3) * (tile + gap)
		var y: float = pad + float(row / 3) * (card + gutter) + gap + float(row % 3) * (tile + gap)
		return Rect2(board_rect.position + Vector2(x, y), Vector2(tile, tile))
	var pitch: float = side / 9.0
	return Rect2(board_rect.position + Vector2(float(col) * pitch, float(row) * pitch), Vector2(pitch, pitch))


## The rectangle of box index (0 to 8, row by row): for tiles, the box card;
## for lines, the area the box lines enclose (centered on the lines).
static func box_rect(direction: String, board_rect: Rect2, box: int) -> Rect2:
	var shape: Palettes.Shape = Palettes.shape(direction)
	var k: float = board_scale(direction, board_rect)
	var side: float = minf(board_rect.size.x, board_rect.size.y)
	var box_row: int = box / 3
	var box_col: int = box % 3
	if shape.style == Palettes.STYLE_TILES:
		var pad: float = shape.board_pad * k
		var gutter: float = shape.box_gap * k
		var card: float = (side - 2.0 * pad - 2.0 * gutter) / 3.0
		var origin: Vector2 = Vector2(pad + float(box_col) * (card + gutter), pad + float(box_row) * (card + gutter))
		return Rect2(board_rect.position + origin, Vector2(card, card))
	var third: float = side / 3.0
	return Rect2(board_rect.position + Vector2(float(box_col) * third, float(box_row) * third), Vector2(third, third))


## The ring box of a cell: the square the nine candidates are laid out in.
static func ring_box(direction: String, board_rect: Rect2, index: int) -> Rect2:
	var shape: Palettes.Shape = Palettes.shape(direction)
	var inset: float = shape.ring_inset * board_scale(direction, board_rect)
	return cell_rect(direction, board_rect, index).grow(-inset)


## Side of the ring box in design units for a board drawn at board_size.
static func ring_side(direction: String) -> float:
	var shape: Palettes.Shape = Palettes.shape(direction)
	var board: Rect2 = Rect2(Vector2.ZERO, Vector2(shape.board_size, shape.board_size))
	return ring_box(direction, board, 0).size.x
