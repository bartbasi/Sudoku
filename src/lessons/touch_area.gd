extends Control
## A touch area of at least Layout.TOUCH_MIN both ways around a smaller icon
## button face (DESIGN_SYSTEM.md 4.4), for the lesson card's close button and
## the lessons list's back button. A tap anywhere in the area counts.
## Internal to src/lessons: no class_name, preloaded by path.
## Owner: lessons-dev.

signal tapped()

var face: Button = null


## An area holding an ICON_BUTTON face of face_side dp with the icon in it.
static func make(icon: StringName, face_side: float, node_name: String) -> Control:
	var area: Control = (load("res://src/lessons/touch_area.gd") as GDScript).new() as Control
	area.name = node_name
	area.mouse_filter = Control.MOUSE_FILTER_STOP
	area.focus_mode = Control.FOCUS_NONE
	area.custom_minimum_size = Vector2(Layout.TOUCH_MIN, Layout.TOUCH_MIN)
	area.size = area.custom_minimum_size
	var button: Button = Button.new()
	button.name = "Face"
	button.theme_type_variation = ThemeFactory.ICON_BUTTON
	button.icon = Icons.texture(icon, Icons.SIZE_ICON_BUTTON)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon = true
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.focus_mode = Control.FOCUS_NONE
	button.size = Vector2(face_side, face_side)
	button.position = (area.size - button.size) * 0.5
	area.add_child(button)
	area.set(&"face", button)
	area.resized.connect(func() -> void: button.position = (area.size - button.size) * 0.5)
	return area


## As if the area had been tapped.
func tap() -> void:
	if face != null:
		Motion.press(face)
	tapped.emit()


func _gui_input(event: InputEvent) -> void:
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT or not mouse.pressed:
		return
	accept_event()
	tap()
