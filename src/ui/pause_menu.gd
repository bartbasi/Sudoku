class_name PauseMenu
extends Control
## The pause menu (GDD 8, DESIGN_SYSTEM.md 7.8): a full screen PAGE overlay
## that covers everything, the board included. Centered in the safe area:
## PAUSED, the level sticker and the paused time, then Resume, Settings and
## Menu. The play screen opens it and handles the buttons.
## Owner: ui-systems-dev.

signal resume_pressed()
signal settings_pressed()
signal menu_pressed()

var time_label: Label = null
var level_box: CenterContainer = null
var resume_button: Button = null
var settings_button: Button = null
var menu_button: Button = null

var _column: ScreenColumn = null
var _skin: GameSkin = null
var _open: bool = false


func setup(skin: GameSkin) -> void:
	_skin = skin
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var page: Panel = Panel.new()
	page.theme_type_variation = ThemeFactory.PAGE
	page.mouse_filter = Control.MOUSE_FILTER_STOP
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	_column = ScreenColumn.new()
	_column.margin = skin.page_margin
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_column)
	var stack: VBoxContainer = UiKit.vbox(skin.space_m)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	_column.add_child(stack)
	var title: Label = UiKit.label(ThemeFactory.DISPLAY, "Paused")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)
	level_box = CenterContainer.new()
	level_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(level_box)
	time_label = UiKit.label(ThemeFactory.VALUE, "")
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(time_label)
	var gap: Control = Control.new()
	gap.custom_minimum_size.y = skin.space_xl - skin.space_m
	stack.add_child(gap)
	resume_button = UiKit.button(ThemeFactory.BUTTON_PRIMARY, "Resume", Layout.BUTTON_TALL, Icons.PLAY)
	resume_button.name = "Resume"
	resume_button.pressed.connect(_emit_if_open.bind(resume_pressed))
	stack.add_child(resume_button)
	settings_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Settings", Layout.BUTTON_TALL, Icons.SETTINGS)
	settings_button.name = "Settings"
	settings_button.pressed.connect(_emit_if_open.bind(settings_pressed))
	stack.add_child(settings_button)
	menu_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Menu", Layout.BUTTON_TALL)
	menu_button.name = "Menu"
	menu_button.pressed.connect(_emit_if_open.bind(menu_pressed))
	stack.add_child(menu_button)
	visible = false


## Shows the level and the paused time of session.
func show_for(session: GameSession) -> void:
	for child: Node in level_box.get_children():
		level_box.remove_child(child)
		child.queue_free()
	level_box.add_child(UiKit.sticker(ThemeFactory.STICKER, ThemeFactory.STICKER_LABEL, Levels.name_of(session.level), _skin.sticker_tilt))
	time_label.text = UiKit.format_time(session.elapsed_seconds())
	_open = true
	visible = true
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
	if is_inside_tree():
		modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(self, ^"modulate:a", 1.0, Motion.PAUSE_IN).set_trans(Motion.trans(&"PAUSE_IN")).set_ease(Motion.ease_of(&"PAUSE_IN"))


func is_open() -> bool:
	return _open


## Closes at once: is_open() is false and the buttons stop answering. The
## fade only follows (Motion PAUSE_OUT), over the board already showing.
func close() -> void:
	if not _open:
		return
	_open = false
	# Taps go straight through to the board while it fades.
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	if not is_inside_tree():
		visible = false
		return
	var tween: Tween = create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, Motion.PAUSE_OUT).set_trans(Motion.trans(&"PAUSE_OUT")).set_ease(Motion.ease_of(&"PAUSE_OUT"))
	tween.tween_callback(func() -> void:
		if not _open:
			visible = false
			modulate.a = 1.0)


func _emit_if_open(sig: Signal) -> void:
	if _open:
		sig.emit()
