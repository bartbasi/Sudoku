extends RefCounted
## Stub icon with the same draw functions as src/design/app_icon.gd, so the
## capture tool's icon path can be tested before the real icon exists.
## Plain shapes on purpose: it is not a design. Owner: senior-graphic-designer.

const Palettes := preload("res://tools/design/directions/palettes.gd")


static func draw_full(canvas: CanvasItem, rect: Rect2) -> void:
	draw_background(canvas, rect)
	draw_foreground(canvas, rect)


static func draw_background(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect, Palettes.palette("gridline", false).accent)


static func draw_foreground(canvas: CanvasItem, rect: Rect2) -> void:
	var colors: Palettes.Palette = Palettes.palette("gridline", false)
	canvas.draw_circle(rect.get_center(), rect.size.x * 0.25, colors.celebrate_3)


static func draw_monochrome(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_circle(rect.get_center(), rect.size.x * 0.25, Palettes.palette("gridline", false).surface)
