class_name ZoneBox
extends Container
## Holds the panels that cover the play screen's info zone (the hint panel
## and the full board message) and keeps each one exactly its own size, so
## wrapped text re-measures at the zone's width. It takes no taps itself.
## Owner: ui-systems-dev.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		for child: Node in get_children():
			var control: Control = child as Control
			if control != null:
				fit_child_in_rect(control, Rect2(Vector2.ZERO, size))
