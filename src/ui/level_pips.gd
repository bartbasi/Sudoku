class_name LevelPips
extends Control
## Five square pips on a level select row (DESIGN_SYSTEM.md 7.3): filled in
## chart_bar up to the level, empty in surface_alt_bg, all outlined, so the
## order shows without color. Drawn from the current skin.
## Owner: ui-systems-dev.

var level: int = 0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _get_minimum_size() -> Vector2:
	var gap: float = UiKit.skin_of(self).space_xs
	return Vector2(5.0 * UiSizes.PIP + 4.0 * gap, UiSizes.PIP)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()


func _draw() -> void:
	var skin: GameSkin = UiKit.skin_of(self)
	var gap: float = skin.space_xs
	var top: float = (size.y - UiSizes.PIP) * 0.5
	var left: float = size.x - (5.0 * UiSizes.PIP + 4.0 * gap)
	for i: int in Levels.COUNT:
		var rect: Rect2 = Rect2(left + float(i) * (UiSizes.PIP + gap), top, UiSizes.PIP, UiSizes.PIP)
		draw_rect(rect, skin.chart_bar if i <= level else skin.surface_alt_bg)
		draw_rect(rect, skin.outline, false, skin.outline_w)
