extends RefCounted
## App icon option 3, "Box": one 3 by 3 Sudoku box as a white Pop sticker,
## with heavy box lines, three given digits in ink, one placed digit in blue
## and the selected cell in lemon. Prototype in tools/, never shipped.
## Owner: senior-graphic-designer.

const Common := preload("res://tools/design/icon_options/icon_common.gd")

const NAME: String = "Box"
const REASON: String = "The classic Sudoku picture, a box of digits, so anyone scanning the app drawer knows the game at a glance."

## Row-major cells: a given digit, a placed digit (negative), 0 empty.
const CELLS: Array[int] = [5, 0, 0, 0, 0, 3, -7, 9, 0]
## The selected cell, row-major index.
const SELECTED: int = 4
## Cell line weight, share of the sticker outline.
const LINE_SHARE: float = 0.55
## Digit cap height, share of the cell side (digit_size 0.64 of the font).
const DIGIT_CAP_SHARE: float = 0.5


static func draw_full(canvas: CanvasItem, rect: Rect2) -> void:
	Common.draw_full_background(canvas, rect)
	_art(canvas, Common.layer_for_full(rect), false)


static func draw_background(canvas: CanvasItem, rect: Rect2) -> void:
	Common.draw_background(canvas, rect)


static func draw_foreground(canvas: CanvasItem, rect: Rect2) -> void:
	_art(canvas, rect, false)


static func draw_monochrome(canvas: CanvasItem, rect: Rect2) -> void:
	_art(canvas, rect, true)


static func _art(canvas: CanvasItem, layer: Rect2, mono: bool) -> void:
	var s: Common.Sticker = Common.sticker(layer)
	if mono:
		Common.draw_mono_frame(canvas, s, 0.0)
	else:
		Common.draw_sticker(canvas, s, 0.0, Common.WHITE)
	var inner: float = 2.0 * s.half - s.outline
	var cell: float = inner / 3.0
	var origin: Vector2 = -Vector2(inner, inner) * 0.5
	var line: float = maxf(1.0, s.outline * LINE_SHARE)
	var ink: Color = Common.MONO if mono else Common.INK
	# Selected cell under the lines.
	var sx: int = SELECTED % 3
	var sy: int = floori(SELECTED / 3.0)
	var selected: Rect2 = Rect2(origin + Vector2(sx, sy) * cell, Vector2(cell, cell))
	if mono:
		canvas.draw_rect(selected.grow(-line * 1.5), Common.MONO)
	else:
		canvas.draw_rect(selected, Common.LEMON_CELL)
	for i: int in [1, 2]:
		var at: float = origin.x + float(i) * cell
		canvas.draw_rect(Rect2(at - line * 0.5, origin.y, line, inner), ink)
		canvas.draw_rect(Rect2(origin.x, at - line * 0.5, inner, line), ink)
	var size: int = Common.size_for_cap(cell * DIGIT_CAP_SHARE)
	for index: int in CELLS.size():
		var value: int = CELLS[index]
		if value == 0:
			continue
		var center: Vector2 = origin + (Vector2(index % 3, floori(index / 3.0)) + Vector2(0.5, 0.5)) * cell
		if value > 0:
			Common.draw_digit(canvas, center, value, size, Common.HEAVY, ink)
		else:
			Common.draw_digit(canvas, center, -value, size, Common.SEMIBOLD, Common.MONO if mono else Common.PLACED)
	Common.reset_transform(canvas)
