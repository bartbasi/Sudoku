extends Container
## A touch area of at least Layout.TOUCH_MIN both ways around a smaller
## button face (DESIGN_SYSTEM.md 4.4). The face sits in the middle; a tap on
## the area around it counts as a tap on the button.
## No class_name: preloaded by UiKit.
## Owner: ui-systems-dev.

var button: Button = null


func set_button(face: Button) -> void:
	button = face
	add_child(face)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _get_minimum_size() -> Vector2:
	var inner: Vector2 = button.get_combined_minimum_size() if button != null else Vector2.ZERO
	return inner.max(Vector2(Layout.TOUCH_MIN, Layout.TOUCH_MIN))


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN and button != null:
		var face: Vector2 = button.get_combined_minimum_size()
		fit_child_in_rect(button, Rect2((size - face) * 0.5, face))


func _gui_input(event: InputEvent) -> void:
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT or mouse.pressed:
		return
	if button == null or button.disabled or not button.visible:
		return
	if Rect2(Vector2.ZERO, size).has_point(mouse.position):
		accept_event()
		button.pressed.emit()
