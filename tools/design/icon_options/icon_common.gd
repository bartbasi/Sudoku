extends RefCounted
## Shared parts of the three app icon options Bart picks from (2026-10-12).
## Prototype code in tools/, never shipped. The chosen option is rebuilt in
## src/design/app_icon.gd by ui-motion-artist, with the same four functions.
## Owner: senior-graphic-designer.
##
## Every option keeps the placeholder's background: Pop blue with a quiet
## 3 by 3 grid of lighter lines. Adaptive layers use the Android 108 dp
## canvas: rect is the whole layer, the visible area is the middle 72 dp and
## all foreground and monochrome art stays inside the 66 dp safe zone circle.
## The legacy full icon shows the same art, with its visible area filling the
## rounded square, so it matches what a launcher shows.

## Pop light colors (docs/DESIGN_SYSTEM.md section 1).
const BLUE: Color = Color("#1A40D9") ## button_primary_bg; the icon background.
const GRID: Color = Color("#4362E0") ## Quiet grid lines on the background.
const INK: Color = Color("#111111") ## outline, shadow, digit_given.
const WHITE: Color = Color("#FFFFFF") ## cell_bg, surface_bg.
const LEMON: Color = Color("#FFE45C") ## Pop's full lemon (the Phase 1 page).
const LEMON_CELL: Color = Color("#FFE873") ## cell_selected_bg.
const MAGENTA: Color = Color("#D1005A") ## cross_mark_hand.
const PLACED: Color = Color("#1A40D9") ## digit_placed.
## The monochrome layer is one opaque color; Android tints it.
const MONO: Color = Color("#FFFFFF")

const SAFE_SHARE: float = 66.0 / 108.0
const VISIBLE_SHARE: float = 72.0 / 108.0
## Corner radius of the legacy full icon, share of its side.
const FULL_CORNER: float = 0.22
## Background grid line weight, share of the visible area (the ASSETS.md to-do).
const GRID_WEIGHT: float = 0.015

## Sticker proportions, shares of the safe zone radius. Sized so the face,
## its outline and its hard shadow stay inside the safe zone at any tilt.
const STICKER_HALF: float = 0.64
const STICKER_CORNER: float = 0.14
const STICKER_OUTLINE: float = 0.06
const STICKER_SHADOW: float = 0.09
## The monochrome frame is a little heavier than the color outline, so it
## holds up alone.
const MONO_FRAME: float = 1.4

## Cap height of the built-in font's digits, share of the font size.
const DIGIT_CAP: float = 0.714
## Ink width of a digit, share of the font size (for the ring layout fit).
const DIGIT_INK_W: float = 0.52

## Embolden values from the type scale (section 3.1).
const SEMIBOLD: float = 0.0
const HEAVY: float = 0.9


## Radius of the safe zone circle of an adaptive layer, px.
static func safe_radius(layer: Rect2) -> float:
	return layer.size.x * SAFE_SHARE * 0.5


## The adaptive layer whose visible area is rect: the full icon draws its art
## into this so it looks like the launcher icon.
static func layer_for_full(rect: Rect2) -> Rect2:
	var side: float = rect.size.x / VISIBLE_SHARE
	return Rect2(rect.get_center() - Vector2(side, side) * 0.5, Vector2(side, side))


## Adaptive background layer: blue, grid lines on the visible area's thirds.
static func draw_background(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect, BLUE)
	_draw_grid(canvas, rect.get_center(), rect.size.x * VISIBLE_SHARE, rect)


## Legacy full icon background: a rounded square, transparent outside it.
static func draw_full_background(canvas: CanvasItem, rect: Rect2) -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = BLUE
	box.set_corner_radius_all(roundi(rect.size.x * FULL_CORNER))
	box.corner_detail = 16
	box.anti_aliasing = true
	canvas.draw_style_box(box, rect)
	# The lines sit on the thirds, clear of the corner curves.
	_draw_grid(canvas, rect.get_center(), rect.size.x, rect)


static func _draw_grid(canvas: CanvasItem, center: Vector2, visible: float, span: Rect2) -> void:
	var w: float = maxf(1.0, visible * GRID_WEIGHT)
	for i: int in [1, 2]:
		var offset: float = visible * (float(i) / 3.0 - 0.5)
		canvas.draw_rect(Rect2(center.x + offset - w * 0.5, span.position.y, w, span.size.y), GRID)
		canvas.draw_rect(Rect2(span.position.x, center.y + offset - w * 0.5, span.size.x, w), GRID)


## The square sticker of an option, in px: its center (the face is moved up
## and left by half the shadow, so face and shadow together are centered),
## half side, corner radius, outline weight and shadow offset.
class Sticker:
	var center: Vector2
	var half: float
	var corner: float
	var outline: float
	var shadow: float


static func sticker(layer: Rect2) -> Sticker:
	var r: float = safe_radius(layer)
	var s: Sticker = Sticker.new()
	s.half = STICKER_HALF * r
	s.corner = STICKER_CORNER * r
	s.outline = maxf(1.0, STICKER_OUTLINE * r)
	s.shadow = STICKER_SHADOW * r
	s.center = layer.get_center() - Vector2(s.shadow, s.shadow) * 0.5
	return s


## A Pop sticker: hard ink shadow, ink outline, face. angle is radians,
## negative is counterclockwise. Leaves the canvas transform at s.center
## rotated by angle, so the caller can draw the content in sticker space
## (origin at the face center); call reset_transform() after.
static func draw_sticker(canvas: CanvasItem, s: Sticker, angle: float, face: Color) -> void:
	var outer: Rect2 = Rect2(-Vector2.ONE * (s.half + s.outline * 0.5), Vector2.ONE * (2.0 * s.half + s.outline))
	canvas.draw_set_transform(s.center + Vector2(s.shadow, s.shadow), angle, Vector2.ONE)
	canvas.draw_style_box(_rounded(INK, s.corner + s.outline * 0.5), outer)
	canvas.draw_set_transform(s.center, angle, Vector2.ONE)
	canvas.draw_style_box(_rounded(INK, s.corner + s.outline * 0.5), outer)
	var inner: Rect2 = outer.grow(-s.outline)
	canvas.draw_style_box(_rounded(face, maxf(0.0, s.corner - s.outline * 0.5)), inner)


## The monochrome version of a sticker: its outline only, a little heavier.
## Leaves the canvas transform in sticker space like draw_sticker.
static func draw_mono_frame(canvas: CanvasItem, s: Sticker, angle: float) -> void:
	var w: float = s.outline * MONO_FRAME
	var outer: Rect2 = Rect2(-Vector2.ONE * (s.half + s.outline * 0.5), Vector2.ONE * (2.0 * s.half + s.outline))
	canvas.draw_set_transform(s.center, angle, Vector2.ONE)
	var box: StyleBoxFlat = _rounded(MONO, s.corner + s.outline * 0.5)
	box.draw_center = false
	box.set_border_width_all(maxi(1, roundi(w)))
	box.border_color = MONO
	canvas.draw_style_box(box, outer)


static func reset_transform(canvas: CanvasItem) -> void:
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _rounded(color: Color, radius: float) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(roundi(radius))
	box.corner_detail = 12
	box.anti_aliasing = true
	return box


## Godot's built-in font at a weight. No font file.
static func font(embolden: float) -> FontVariation:
	var variation: FontVariation = FontVariation.new()
	variation.base_font = ThemeDB.fallback_font
	variation.variation_embolden = embolden
	return variation


## Font size whose digits are cap_height tall.
static func size_for_cap(cap_height: float) -> int:
	return maxi(1, roundi(cap_height / DIGIT_CAP))


## Draws one digit centered on center (in the current canvas transform).
static func draw_digit(canvas: CanvasItem, center: Vector2, digit: int, size: int, embolden: float, color: Color, outline: int = 0, outline_color: Color = WHITE) -> void:
	var f: FontVariation = font(embolden)
	var text: String = str(digit)
	var advance: float = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline: Vector2 = Vector2(center.x - advance * 0.5, center.y + float(size) * DIGIT_CAP * 0.5)
	if outline > 0:
		canvas.draw_string_outline(f, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, outline_color)
	canvas.draw_string(f, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
