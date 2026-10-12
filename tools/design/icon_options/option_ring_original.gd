extends RefCounted
## App icon option 1, "Ring", exactly as Bart saw it on the 2026-10-12 sheet.
## Kept frozen so render_icons.gd can show it next to the final, bolder Ring
## (option_ring.gd). One empty cell as a Pop sticker, with the nine
## candidates around its inside edge in ring layout A (reading rows) and two
## of them crossed out with the magenta hand X. The center stays open, as on
## the board. Prototype in tools/, never shipped. Owner: senior-graphic-designer.

const Common := preload("res://tools/design/icon_options/icon_common.gd")

const NAME: String = "Ring, as picked"
const REASON: String = "Shows the one thing this Sudoku does that others do not: the candidate ring you cross out."

## Ring layout A, reading rows. 0 keeps the center open.
const ROWS: Array = [[1, 2, 3, 4], [5, 0, 6], [7, 8, 9]]
## Candidates crossed out by hand in the icon.
const CROSSED: Array[int] = [3, 7]
## Cell edge to ring box, share of the face side (the board's ring_inset
## is about 7 percent of a cell; a little more here for the heavier outline).
const RING_INSET: float = 0.09
## Gap between neighboring candidates, share of the font size. Wider than
## the board's candidate_gap, so the four across the top read as four digits
## and not as a number.
const GAP: float = 0.4
## Hand X: half its span as a share of the candidate font size, and stroke.
const X_HALF: float = 0.42
const X_STROKE: float = 0.13


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
	var side: float = 2.0 * s.half
	var box: float = side * (1.0 - 2.0 * RING_INSET) - s.outline
	var origin: Vector2 = -Vector2(box, box) * 0.5
	# Largest size at which four across and three down fit with the gap.
	var by_width: float = box / (4.0 * Common.DIGIT_INK_W + 3.0 * GAP)
	var by_height: float = box / (3.0 * Common.DIGIT_CAP + 2.0 * GAP)
	var size: int = maxi(1, floori(minf(by_width, by_height)))
	var ink: Vector2 = Vector2(Common.DIGIT_INK_W, Common.DIGIT_CAP) * float(size)
	var x_half: float = X_HALF * float(size)
	var x_stroke: float = maxf(1.0, X_STROKE * float(size))
	var outline: int = maxi(1, roundi(float(size) * 0.08))
	for r: int in ROWS.size():
		var row: Array = ROWS[r]
		var y: float = origin.y + ink.y * 0.5 + float(r) * (box - ink.y) / float(ROWS.size() - 1)
		for i: int in row.size():
			var digit: int = row[i]
			if digit == 0:
				continue
			var x: float = origin.x + ink.x * 0.5 + float(i) * (box - ink.x) / float(row.size() - 1)
			var at: Vector2 = Vector2(x, y)
			var crossed: bool = CROSSED.has(digit)
			if crossed:
				var color: Color = Common.MONO if mono else Common.MAGENTA
				canvas.draw_line(at + Vector2(-x_half, -x_half), at + Vector2(x_half, x_half), color, x_stroke, true)
				canvas.draw_line(at + Vector2(x_half, -x_half), at + Vector2(-x_half, x_half), color, x_stroke, true)
				# Monochrome: the X alone, so it does not merge with the digit.
				if not mono:
					Common.draw_digit(canvas, at, digit, size, Common.SEMIBOLD, Common.INK, outline, Common.WHITE)
			else:
				Common.draw_digit(canvas, at, digit, size, Common.SEMIBOLD, Common.MONO if mono else Common.INK)
	Common.reset_transform(canvas)
