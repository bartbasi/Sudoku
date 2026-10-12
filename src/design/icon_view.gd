class_name IconView extends Control
## Draws one icon (Icons) over its whole rect, in the font color of its
## theme_type_variation. Inside a button it follows the button's state: the
## disabled color when the button is disabled, the pressed color while it is
## held or toggled on. Redraws on theme change. It never takes input.
## Owner: ui-motion-artist.

@export var icon: StringName = &"":
	set(value):
		icon = value
		queue_redraw()

var _watched: BaseButton = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			queue_redraw()
		NOTIFICATION_ENTER_TREE:
			_watch(get_parent() as BaseButton)
		NOTIFICATION_EXIT_TREE:
			_watch(null)


func _draw() -> void:
	Icons.draw(self, icon, Rect2(Vector2.ZERO, size), icon_color())


## The color the icon draws in right now.
func icon_color() -> Color:
	var type: StringName = theme_type_variation if theme_type_variation != &"" else &"Label"
	var button: BaseButton = get_parent() as BaseButton
	if button != null:
		var mode: BaseButton.DrawMode = button.get_draw_mode()
		if mode == BaseButton.DRAW_DISABLED:
			return get_theme_color(&"font_disabled_color", type)
		if mode == BaseButton.DRAW_PRESSED or mode == BaseButton.DRAW_HOVER_PRESSED:
			return get_theme_color(&"font_pressed_color", type)
	return get_theme_color(&"font_color", type)


## Redraw whenever the parent button redraws, which it does on every state change.
func _watch(button: BaseButton) -> void:
	if _watched != null and _watched.draw.is_connected(queue_redraw):
		_watched.draw.disconnect(queue_redraw)
	_watched = button
	if _watched != null:
		_watched.draw.connect(queue_redraw)
