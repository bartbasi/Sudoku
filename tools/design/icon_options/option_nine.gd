extends RefCounted
## App icon option 2, "Nine": a lemon Pop sticker, tilted like the SOLVED!
## sticker, holding one heavy ink 9 in the given digit style. Prototype in
## tools/, never shipped. Owner: senior-graphic-designer.

const Common := preload("res://tools/design/icon_options/icon_common.gd")

const NAME: String = "Nine"
const REASON: String = "The boldest shape at 48 px: one big digit on a tilted lemon sticker says number puzzle in the game's own Pop voice."

## celebrate_tilt, counterclockwise.
const TILT_DEG: float = -6.0
## Cap height of the 9, share of the face side.
const DIGIT_CAP_SHARE: float = 0.64
const DIGIT: int = 9


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
	var angle: float = deg_to_rad(TILT_DEG)
	if mono:
		Common.draw_mono_frame(canvas, s, angle)
	else:
		Common.draw_sticker(canvas, s, angle, Common.LEMON)
	var size: int = Common.size_for_cap(2.0 * s.half * DIGIT_CAP_SHARE)
	Common.draw_digit(canvas, Vector2.ZERO, DIGIT, size, Common.HEAVY, Common.MONO if mono else Common.INK)
	Common.reset_transform(canvas)
