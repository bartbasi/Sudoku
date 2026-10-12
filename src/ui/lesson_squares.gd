class_name LessonSquares
extends Control
## The lessons completed squares on the stats screen (DESIGN_SYSTEM.md 7.10):
## one square per lesson, filled in chart_bar for each finished lesson and
## empty in surface_alt_bg, all outlined, so the count shows without color.
## Owner: ui-systems-dev.

var total: int = 5
var finished: int = 0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _get_minimum_size() -> Vector2:
	var gap: float = UiKit.skin_of(self).space_s
	return Vector2(float(total) * UiSizes.LESSON_SQUARE + float(maxi(total - 1, 0)) * gap, UiSizes.LESSON_SQUARE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()


func _draw() -> void:
	var skin: GameSkin = UiKit.skin_of(self)
	for i: int in total:
		var rect: Rect2 = Rect2(float(i) * (UiSizes.LESSON_SQUARE + skin.space_s), 0.0, UiSizes.LESSON_SQUARE, UiSizes.LESSON_SQUARE)
		draw_rect(rect, skin.chart_bar if i < finished else skin.surface_alt_bg)
		draw_rect(rect, skin.outline, false, skin.outline_w)
