class_name ScreenColumn
extends Container
## Lays its children out in the screen's content column (DESIGN_SYSTEM.md
## 4.5, 4.7 and 4.9): the device safe area, inset by the skin's page_margin,
## at most Layout.COLUMN_MAX wide and centered. Every child gets the whole
## column. Put it on a full rect screen.
## Owner: ui-systems-dev.

## The page margin in dp (the skin's page_margin). The screen sets it.
var margin: float = 8.0:
	set(value):
		margin = value
		queue_sort()


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		var area: Rect2 = column_rect()
		for child: Node in get_children():
			var control: Control = child as Control
			if control != null and control.visible and not control.top_level:
				fit_child_in_rect(control, area)
	elif what == NOTIFICATION_RESIZED or what == NOTIFICATION_ENTER_TREE:
		queue_sort()


## The column in this control's own coordinates.
func column_rect() -> Rect2:
	return column_in(UiKit.safe_rect_local(self), margin)


## The column inside safe (local coordinates) with the given page margin.
static func column_in(safe: Rect2, page_margin: float) -> Rect2:
	var inner: Rect2 = safe.grow(-page_margin)
	var width: float = minf(inner.size.x, Layout.COLUMN_MAX)
	inner.position.x += (inner.size.x - width) * 0.5
	inner.size.x = width
	inner.size = inner.size.max(Vector2.ZERO)
	return inner


func _get_minimum_size() -> Vector2:
	return Vector2.ZERO
