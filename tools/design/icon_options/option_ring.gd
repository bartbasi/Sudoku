extends RefCounted
## The app icon, final: "Ring", picked by Bart on 2026-10-12, made bolder so
## it reads at launcher size ("make the small one bolder"). One empty cell as
## a Pop sticker, with the nine candidates around its inside edge in ring
## layout A (reading rows) and two of them crossed out with the magenta hand
## X. The center stays open, as on the board.
##
## What changed from the picked version (option_ring_original.gd): a larger
## sticker with rounder corners and a heavier outline, a tighter ring inset,
## Heavy digits instead of Semibold, a tighter gap, and a longer, thicker X.
## One look at every size: a launcher icon is about 48 dp on any phone, so a
## pixel threshold would give a 192 px xxxhdpi icon the thin look at the
## same physical size. docs/DESIGN_SYSTEM.md section 9 is the spec that
## src/design/app_icon.gd follows. Prototype in tools/, never shipped.
## Owner: senior-graphic-designer.

const Common := preload("res://tools/design/icon_options/icon_common.gd")

const NAME: String = "Ring, final"
const REASON: String = "Bolder for launcher size: bigger sticker, Heavy digits, tighter ring, thicker and longer X."

## Ring layout A, reading rows. 0 keeps the center open.
const ROWS: Array = [[1, 2, 3, 4], [5, 0, 6], [7, 8, 9]]
## Candidates crossed out by hand in the icon.
const CROSSED: Array[int] = [3, 8]

## Sticker, shares of the safe zone radius R (33 dp of the 108 dp layer).
## half and corner are measured on the outline's center line, as in
## icon_common.gd. With these values the far corner of the shadow is
## 0.978 R from the layer center, inside the safe zone.
const STICKER_HALF: float = 0.685
const STICKER_CORNER: float = 0.20
const STICKER_OUTLINE: float = 0.07
const STICKER_SHADOW: float = 0.08
## The monochrome frame is this much heavier than the color outline.
const MONO_FRAME: float = 1.4

## Inner edge of the outline to the ring box, share of R.
const RING_INSET: float = 0.09
## Digit ink of the built-in font at Heavy (embolden 0.9), shares of the
## font size: widest digit (the 4 is 0.60, the rest 0.38 to 0.555) and
## height from the baseline (0.77 to 0.785). Measured on 2026-10-12.
const INK_W: float = 0.58
const INK_H: float = 0.78
## Gap between neighboring candidates, share of the font size. Smallest
## across the top row, where four digits must not read as one number.
const GAP: float = 0.32
## Hand X: half its span and its stroke, shares of the font size.
const X_HALF: float = 0.45
const X_STROKE: float = 0.22
## Outline of a crossed digit (cell_bg), share of the font size.
const CROSSED_OUTLINE: float = 0.08


static func draw_full(canvas: CanvasItem, rect: Rect2) -> void:
	Common.draw_full_background(canvas, rect)
	_art(canvas, Common.layer_for_full(rect), false)


static func draw_background(canvas: CanvasItem, rect: Rect2) -> void:
	Common.draw_background(canvas, rect)


static func draw_foreground(canvas: CanvasItem, rect: Rect2) -> void:
	_art(canvas, rect, false)


static func draw_monochrome(canvas: CanvasItem, rect: Rect2) -> void:
	_art(canvas, rect, true)


static func sticker(layer: Rect2) -> Common.Sticker:
	var r: float = Common.safe_radius(layer)
	var s: Common.Sticker = Common.Sticker.new()
	s.half = STICKER_HALF * r
	s.corner = STICKER_CORNER * r
	s.outline = maxf(1.0, STICKER_OUTLINE * r)
	s.shadow = STICKER_SHADOW * r
	# Face and shadow together are centered on the layer.
	s.center = layer.get_center() - Vector2(s.shadow, s.shadow) * 0.5
	return s


static func _art(canvas: CanvasItem, layer: Rect2, mono: bool) -> void:
	var r: float = Common.safe_radius(layer)
	var s: Common.Sticker = sticker(layer)
	if mono:
		_mono_frame(canvas, s)
	else:
		Common.draw_sticker(canvas, s, 0.0, Common.WHITE)
	# Ring box, centered on the face, in sticker space.
	var box: float = 2.0 * (s.half - s.outline * 0.5 - RING_INSET * r)
	var origin: Vector2 = -Vector2(box, box) * 0.5
	var by_width: float = box / (4.0 * INK_W + 3.0 * GAP)
	var by_height: float = box / (3.0 * INK_H + 2.0 * GAP)
	var size: int = maxi(1, roundi(minf(by_width, by_height)))
	var ink: Vector2 = Vector2(INK_W, INK_H) * float(size)
	var x_half: float = X_HALF * float(size)
	var x_stroke: float = maxf(1.0, X_STROKE * float(size))
	var outline: int = maxi(1, roundi(CROSSED_OUTLINE * float(size)))
	var font: FontVariation = Common.font(Common.HEAVY)
	var ink_color: Color = Common.MONO if mono else Common.INK
	var x_color: Color = Common.MONO if mono else Common.MAGENTA
	for row_index: int in ROWS.size():
		var row: Array = ROWS[row_index]
		var y: float = origin.y + ink.y * 0.5 + float(row_index) * (box - ink.y) / float(ROWS.size() - 1)
		for i: int in row.size():
			var digit: int = row[i]
			if digit == 0:
				continue
			var x: float = origin.x + ink.x * 0.5 + float(i) * (box - ink.x) / float(row.size() - 1)
			var at: Vector2 = Vector2(x, y)
			if CROSSED.has(digit):
				canvas.draw_line(at + Vector2(-x_half, -x_half), at + Vector2(x_half, x_half), x_color, x_stroke, true)
				canvas.draw_line(at + Vector2(x_half, -x_half), at + Vector2(-x_half, x_half), x_color, x_stroke, true)
				# Monochrome: the X alone, so it does not merge with the digit.
				if not mono:
					_digit(canvas, font, at, digit, size, ink_color, outline)
			else:
				_digit(canvas, font, at, digit, size, ink_color, 0)
	Common.reset_transform(canvas)


## The monochrome sticker: its outline only, heavier. Leaves the canvas in
## sticker space.
static func _mono_frame(canvas: CanvasItem, s: Common.Sticker) -> void:
	var w: float = s.outline * MONO_FRAME
	var outer: Rect2 = Rect2(-Vector2.ONE * (s.half + w * 0.5), Vector2.ONE * (2.0 * s.half + w))
	canvas.draw_set_transform(s.center, 0.0, Vector2.ONE)
	var frame: StyleBoxFlat = StyleBoxFlat.new()
	frame.draw_center = false
	frame.set_corner_radius_all(roundi(s.corner + w * 0.5))
	frame.corner_detail = 12
	frame.anti_aliasing = true
	frame.set_border_width_all(maxi(1, roundi(w)))
	frame.border_color = Common.MONO
	canvas.draw_style_box(frame, outer)


## One Heavy digit, its ink centered on center: centered on the advance
## across, and on INK_H above the baseline down.
static func _digit(canvas: CanvasItem, font: FontVariation, center: Vector2, digit: int, size: int, color: Color, outline: int) -> void:
	var text: String = str(digit)
	var advance: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline: Vector2 = Vector2(center.x - advance * 0.5, center.y + float(size) * INK_H * 0.5)
	if outline > 0:
		canvas.draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Common.WHITE)
	canvas.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
