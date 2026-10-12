class_name HeroIcon
extends Control
## The main menu and first launch hero (DESIGN_SYSTEM.md 7.1 and 7.2): the
## app icon's foreground, drawn by app_icon.gd, in a square box centered in
## this control. The box is the height left less space_xl above and below,
## clamped to UiSizes.HERO_MIN to HERO_MAX. Not tappable.
## Owner: ui-systems-dev.

const AppIcon := preload("res://src/design/app_icon.gd")

## The gap above and below the box (the skin's space_xl). The screen sets it.
var gap: float = 24.0:
	set(value):
		gap = value
		update_minimum_size()
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	resized.connect(queue_redraw)


func _get_minimum_size() -> Vector2:
	return Vector2(UiSizes.HERO_MIN, UiSizes.HERO_MIN + 2.0 * gap)


## The side of the hero box at the current size.
func box_side() -> float:
	return clampf(minf(size.y - 2.0 * gap, size.x), UiSizes.HERO_MIN, UiSizes.HERO_MAX)


func _draw() -> void:
	var side: float = box_side()
	var center: Vector2 = size * 0.5
	var layer: float = side * UiSizes.HERO_LAYER
	AppIcon.draw_foreground(self, Rect2(center - Vector2(layer, layer) * 0.5, Vector2(layer, layer)))
