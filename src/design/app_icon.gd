extends RefCounted
## The app icon, Ring (Bart, 2026-10-12), in its bolder final look: one empty
## cell as a Pop sticker on the Pop blue tile, with the nine candidates
## around its inside edge in ring layout A (reading rows, the center open)
## and the 3 and the 8 crossed out with the magenta hand X. One look at every
## size; there is no simpler drawing for small icons.
## docs/DESIGN_SYSTEM.md section 9 is the spec, and this is a port of the
## reference drawing tools/design/icon_options/option_ring.gd.
## Everything is drawn in code, digits in Godot's built-in font; there is no
## image file. platform-dev renders it to PNG launcher icons at build time.
##
## Call the draw functions from inside a _draw() of canvas. rect is square and
## may be any size from 48 to 512 px. Like the reference, the digits are
## drawn through a draw transform, and the functions leave the canvas
## transform reset, so call them with no transform of your own set.
##
## Adaptive layers use the Android 108 dp canvas: rect is the whole layer. The
## foreground and monochrome layers stay inside the safe zone, a centered
## circle 66/108 of the side across. The full icon is the visible 72 dp
## middle of the layers, on a rounded tile.
## Owner: ui-motion-artist.

## Pop's electric blue (button_primary_bg), section 9.3.
const BACKGROUND: Color = Color("#1A40D9")
## The quiet grid lines on the background, section 9.3.
const GRID: Color = Color("#4362E0")
## The sticker face and the outline around a crossed digit (cell_bg).
const FACE: Color = Color("#FFFFFF")
## The sticker outline, its hard shadow and the digits (outline, shadow,
## digit_given).
const INK: Color = Color("#111111")
## The hand X (cross_mark_hand).
const CROSS: Color = Color("#D1005A")
## The one color of the monochrome layer.
const MONOCHROME: Color = Color("#FFFFFF")

## Full icon: corner radius of the blue tile, as a share of the side.
const FULL_CORNER: float = 0.22
## Adaptive icon: safe zone diameter as a share of the layer side.
const SAFE_ZONE: float = 66.0 / 108.0
## The visible part of an adaptive layer, as a share of its side.
const VISIBLE: float = 72.0 / 108.0
## Background grid line weight, as a share of the visible side (1 percent of
## the 108 dp layer). The lines sit on the thirds of the visible area.
const GRID_WEIGHT: float = 0.015

## Sticker, shares of the safe zone radius R. half and corner are measured on
## the outline's center line.
const STICKER_HALF: float = 0.685
const STICKER_CORNER: float = 0.20
const STICKER_OUTLINE: float = 0.07
const STICKER_SHADOW: float = 0.08
## The monochrome frame is this much heavier than the color outline.
const MONO_FRAME: float = 1.4
## Inner edge of the outline to the ring box, share of R.
const RING_INSET: float = 0.09

## Ring layout A, reading rows. 0 keeps the center open.
const ROWS: Array = [[1, 2, 3, 4], [5, 0, 6], [7, 8, 9]]
## The candidates crossed out by hand.
const CROSSED: Array[int] = [3, 8]
## Heavy weight of the type scale (section 3.1).
const EMBOLDEN: float = 0.9
## Digit ink of the built-in font at Heavy, shares of the font size: the
## width used for the layout, the widest digit (the 4) and the height above
## the baseline.
const INK_W: float = 0.58
const INK_W_WIDEST: float = 0.60
const INK_H: float = 0.78
## Gap between neighboring candidates, share of the font size.
const GAP: float = 0.32
## Hand X: half its span on each axis and its stroke, shares of the font size.
const X_HALF: float = 0.45
const X_STROKE: float = 0.22
## Outline of a crossed digit, share of the font size.
const CROSSED_OUTLINE: float = 0.08

## Corner detail of the rounded shapes: the full tile and the sticker.
const FULL_CORNER_DETAIL: int = 16
const STICKER_CORNER_DETAIL: int = 12

## Kinds of Part.
enum Kind { RECT, ROUNDED, FRAME, LINE, DIGIT }


## One drawing step, in icon pixels. RECT is a plain rect; ROUNDED a filled
## rounded rect and FRAME its border only (radius, and width for the border);
## LINE runs from a to b, width wide; DIGIT draws digit at font_size with its
## ink centered on a, with a FACE outline when outline is above 0. Digits are
## drawn in sticker space, translated to origin (the face center), as the
## reference does, so their glyphs land on the same pixels.
class Part extends RefCounted:
	var kind: Kind
	var color: Color
	var rect: Rect2
	var radius: int
	var detail: int
	var a: Vector2
	var b: Vector2
	var width: float
	var digit: int
	var origin: Vector2
	var font_size: int
	var outline: int


static var _font: FontVariation = null


# Public draw functions

## The complete full icon: the rounded blue tile with its grid, and the art
## as it shows through a launcher's visible area. Transparent outside the
## tile.
static func draw_full(canvas: CanvasItem, rect: Rect2) -> void:
	_paint(canvas.get_canvas_item(), _full_parts(rect))


## Adaptive background layer: fills rect with blue and the quiet grid.
static func draw_background(canvas: CanvasItem, rect: Rect2) -> void:
	_paint(canvas.get_canvas_item(), _background_parts(rect))


## Adaptive foreground layer: the cell sticker with its candidate ring,
## inside the safe zone, transparent everywhere else.
static func draw_foreground(canvas: CanvasItem, rect: Rect2) -> void:
	_paint(canvas.get_canvas_item(), _art_parts(rect, false))


## Adaptive monochrome layer, one opaque color: the sticker's frame, the seven
## open digits and the two X. A crossed digit is not drawn, only its X.
static func draw_monochrome(canvas: CanvasItem, rect: Rect2) -> void:
	_paint(canvas.get_canvas_item(), _art_parts(rect, true))


## Points on the edge of everything the foreground and monochrome layers
## draw, in rect's coordinates: the shadow, outline and frame shapes, the
## corners of each X stroke and each digit's ink box. Digits are text with no
## vertices, so their box comes from the measured ink shares.
static func foreground_outline(rect: Rect2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for mono: bool in [false, true]:
		for part: Part in _art_parts(rect, mono):
			points.append_array(_part_outline(part))
	return points


# Layers

## The 108 dp layer whose visible 72 dp middle is rect.
static func _layer_for_full(rect: Rect2) -> Rect2:
	var side: float = rect.size.x / VISIBLE
	return Rect2(rect.get_center() - Vector2(side, side) * 0.5, Vector2(side, side))


static func _full_parts(rect: Rect2) -> Array[Part]:
	var parts: Array[Part] = [_rounded(rect, roundi(rect.size.x * FULL_CORNER), FULL_CORNER_DETAIL, BACKGROUND)]
	# The lines sit on the thirds, clear of the corner curves.
	parts.append_array(_grid_parts(rect.get_center(), rect.size.x, rect))
	parts.append_array(_art_parts(_layer_for_full(rect), false))
	return parts


static func _background_parts(rect: Rect2) -> Array[Part]:
	var parts: Array[Part] = [_plain(rect, BACKGROUND)]
	parts.append_array(_grid_parts(rect.get_center(), rect.size.x * VISIBLE, rect))
	return parts


## Two lines each way on the thirds of the visible side, across span.
static func _grid_parts(center: Vector2, visible: float, span: Rect2) -> Array[Part]:
	var parts: Array[Part] = []
	var w: float = maxf(1.0, visible * GRID_WEIGHT)
	for i: int in [1, 2]:
		var offset: float = visible * (float(i) / 3.0 - 0.5)
		parts.append(_plain(Rect2(center.x + offset - w * 0.5, span.position.y, w, span.size.y), GRID))
		parts.append(_plain(Rect2(span.position.x, center.y + offset - w * 0.5, span.size.x, w), GRID))
	return parts


## The sticker and its ring, in draw order: shadow, outline, face (or the
## monochrome frame), then per candidate in reading order the X and its
## outlined digit, or the plain digit.
static func _art_parts(layer: Rect2, mono: bool) -> Array[Part]:
	var r: float = layer.size.x * SAFE_ZONE * 0.5
	var half: float = STICKER_HALF * r
	var corner: float = STICKER_CORNER * r
	var outline: float = maxf(1.0, STICKER_OUTLINE * r)
	var shadow: float = STICKER_SHADOW * r
	# Face and shadow together are centered on the layer.
	var center: Vector2 = layer.get_center() - Vector2(shadow, shadow) * 0.5
	var parts: Array[Part] = []
	if mono:
		var w: float = outline * MONO_FRAME
		var frame: Part = _rounded(_square(center, half + w * 0.5), roundi(corner + w * 0.5), STICKER_CORNER_DETAIL, MONOCHROME)
		frame.kind = Kind.FRAME
		frame.width = float(maxi(1, roundi(w)))
		parts.append(frame)
	else:
		var outer: Rect2 = _square(center, half + outline * 0.5)
		var outer_radius: int = roundi(corner + outline * 0.5)
		parts.append(_rounded(Rect2(outer.position + Vector2(shadow, shadow), outer.size), outer_radius, STICKER_CORNER_DETAIL, INK))
		parts.append(_rounded(outer, outer_radius, STICKER_CORNER_DETAIL, INK))
		parts.append(_rounded(outer.grow(-outline), roundi(maxf(0.0, corner - outline * 0.5)), STICKER_CORNER_DETAIL, FACE))
	# Ring box, centered on the face. The font size is whole px; positions
	# use the float box, so the layout stays centered at every size.
	var box: float = 2.0 * (half - outline * 0.5 - RING_INSET * r)
	var origin: Vector2 = center - Vector2(box, box) * 0.5
	var by_width: float = box / (4.0 * INK_W + 3.0 * GAP)
	var by_height: float = box / (3.0 * INK_H + 2.0 * GAP)
	var size: int = maxi(1, roundi(minf(by_width, by_height)))
	var ink: Vector2 = Vector2(INK_W, INK_H) * float(size)
	var x_half: float = X_HALF * float(size)
	var x_stroke: float = maxf(1.0, X_STROKE * float(size))
	var digit_outline: int = maxi(1, roundi(CROSSED_OUTLINE * float(size)))
	var ink_color: Color = MONOCHROME if mono else INK
	var x_color: Color = MONOCHROME if mono else CROSS
	for row_index: int in ROWS.size():
		var row: Array = ROWS[row_index]
		var y: float = origin.y + ink.y * 0.5 + float(row_index) * (box - ink.y) / float(ROWS.size() - 1)
		for i: int in row.size():
			var digit: int = row[i]
			if digit == 0:
				continue
			var at: Vector2 = Vector2(origin.x + ink.x * 0.5 + float(i) * (box - ink.x) / float(row.size() - 1), y)
			if CROSSED.has(digit):
				parts.append(_line(at + Vector2(-x_half, -x_half), at + Vector2(x_half, x_half), x_stroke, x_color))
				parts.append(_line(at + Vector2(x_half, -x_half), at + Vector2(-x_half, x_half), x_stroke, x_color))
				# Monochrome: the X alone, so it does not merge with the digit.
				if not mono:
					parts.append(_digit(at, center, digit, size, digit_outline, ink_color))
			else:
				parts.append(_digit(at, center, digit, size, 0, ink_color))
	return parts


# Parts

static func _square(center: Vector2, half: float) -> Rect2:
	return Rect2(center - Vector2(half, half), Vector2(half, half) * 2.0)


static func _plain(rect: Rect2, color: Color) -> Part:
	var part: Part = Part.new()
	part.kind = Kind.RECT
	part.rect = rect
	part.color = color
	return part


static func _rounded(rect: Rect2, radius: int, detail: int, color: Color) -> Part:
	var part: Part = _plain(rect, color)
	part.kind = Kind.ROUNDED
	part.radius = radius
	part.detail = detail
	return part


static func _line(from: Vector2, to: Vector2, width: float, color: Color) -> Part:
	var part: Part = Part.new()
	part.kind = Kind.LINE
	part.a = from
	part.b = to
	part.width = width
	part.color = color
	return part


static func _digit(center: Vector2, origin: Vector2, digit: int, size: int, outline: int, color: Color) -> Part:
	var part: Part = Part.new()
	part.kind = Kind.DIGIT
	part.a = center
	part.origin = origin
	part.digit = digit
	part.font_size = size
	part.outline = outline
	part.color = color
	return part


## Edge points of one part, for foreground_outline.
static func _part_outline(part: Part) -> PackedVector2Array:
	match part.kind:
		Kind.ROUNDED, Kind.FRAME:
			return _rounded_points(part.rect, float(part.radius))
		Kind.LINE:
			var across: Vector2 = (part.b - part.a).normalized().orthogonal() * part.width * 0.5
			return PackedVector2Array([part.a + across, part.b + across, part.b - across, part.a - across])
		Kind.DIGIT:
			var half: Vector2 = Vector2(INK_W_WIDEST, INK_H) * float(part.font_size) * 0.5
			var grow: Vector2 = Vector2.ONE * float(part.outline)
			var box: Rect2 = Rect2(part.a - half - grow, (half + grow) * 2.0)
			return PackedVector2Array([box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)])
	return PackedVector2Array([part.rect.position, Vector2(part.rect.end.x, part.rect.position.y), part.rect.end, Vector2(part.rect.position.x, part.rect.end.y)])


## A rounded rect as points, eight steps per corner.
static func _rounded_points(rect: Rect2, radius: float) -> PackedVector2Array:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var inner: Rect2 = rect.grow(-r)
	var centers: Array[Vector2] = [inner.end, Vector2(inner.position.x, inner.end.y), inner.position, Vector2(inner.end.x, inner.position.y)]
	var points: PackedVector2Array = PackedVector2Array()
	var steps: int = 8
	for k: int in 4:
		for i: int in steps + 1:
			var angle: float = PI * 0.5 * (float(k) + float(i) / float(steps))
			points.append(centers[k] + Vector2(cos(angle), sin(angle)) * r)
	return points


# Drawing

## Heavy weight of Godot's built-in font. No font file.
static func _heavy() -> FontVariation:
	if _font == null:
		_font = FontVariation.new()
		_font.base_font = ThemeDB.fallback_font
		_font.variation_embolden = EMBOLDEN
	return _font


## Adds every part to item, in order. Works on any canvas item, so the layers
## can also be drawn onto a texture's item.
static func _paint(item: RID, parts: Array[Part]) -> void:
	for part: Part in parts:
		match part.kind:
			Kind.RECT:
				RenderingServer.canvas_item_add_rect(item, part.rect, part.color)
			Kind.ROUNDED, Kind.FRAME:
				var style: StyleBoxFlat = StyleBoxFlat.new()
				style.set_corner_radius_all(part.radius)
				style.corner_detail = part.detail
				style.anti_aliasing = true
				if part.kind == Kind.FRAME:
					style.draw_center = false
					style.set_border_width_all(roundi(part.width))
					style.border_color = part.color
				else:
					style.bg_color = part.color
				style.draw(item, part.rect)
			Kind.LINE:
				RenderingServer.canvas_item_add_line(item, part.a, part.b, part.color, part.width, true)
			Kind.DIGIT:
				var font: FontVariation = _heavy()
				var text: String = str(part.digit)
				var advance: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, part.font_size).x
				var local: Vector2 = part.a - part.origin
				var baseline: Vector2 = Vector2(local.x - advance * 0.5, local.y + float(part.font_size) * INK_H * 0.5)
				RenderingServer.canvas_item_add_set_transform(item, Transform2D(0.0, part.origin))
				if part.outline > 0:
					font.draw_string_outline(item, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, part.font_size, part.outline, FACE)
				font.draw_string(item, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, part.font_size, part.color)
				RenderingServer.canvas_item_add_set_transform(item, Transform2D.IDENTITY)
