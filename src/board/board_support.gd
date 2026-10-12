extends RefCounted
## Small helpers shared by the board scripts (BoardView, NumberPad, PlayArea).
## Internal to src/board: no class_name, preloaded by path.
## Owner: board-input-dev.


## Where a press landed, in the control's local coordinates, or null when
## event is not the start of a press. Touch and mouse both count. On a phone
## Godot turns touches into mouse events (emulate_mouse_from_touch, on by
## default); if a project turns that off, the touch events are read instead,
## so a tap is never counted twice.
static func press_position(event: InputEvent) -> Variant:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			return button.position
		return null
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch != null and touch.pressed and not _touch_becomes_mouse():
		return touch.position
	return null


static func _touch_becomes_mouse() -> bool:
	return bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", true))


## The skin a board control draws with: the one set on it, or else the Skins
## autoload's current skin (docs/ARCHITECTURE.md section 6). Null when there
## is neither, as in a test that sets none.
static func skin_for(node: Node, chosen: GameSkin) -> GameSkin:
	if chosen != null:
		return chosen
	var service: Node = skin_service(node)
	if service == null:
		return null
	return service.get(&"current") as GameSkin


## The Skins autoload, or null when it is not registered or node is outside
## the tree.
static func skin_service(node: Node) -> Node:
	if node == null or not node.is_inside_tree():
		return null
	return node.get_node_or_null(^"/root/Skins")
