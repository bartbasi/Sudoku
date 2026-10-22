class_name PauseMenu
extends Control
## The pause menu (GDD 8, DESIGN_SYSTEM.md 7.8): a full screen PAGE overlay
## that covers everything, the board included. Centered in the safe area:
## PAUSED, the level sticker and the paused time, then Resume, Settings,
## Menu and About, then the smaller Buy me a coffee button (GDD 15.7). Side
## by side (4.11) the first three take the left half and the buttons the
## right half; the right half has no room left at the smallest height, so
## there Buy me a coffee moves to the bottom of the left half, under the
## time, as on the title screen. The play screen opens it and handles the
## buttons: About opens over the paused puzzle, and Buy me a coffee hands
## the support page to the browser; the puzzle stays paused for both.
## Owner: ui-systems-dev.

signal resume_pressed()
signal settings_pressed()
signal menu_pressed()
signal about_pressed()
signal coffee_pressed()

const MainMenuScript := preload("res://src/ui/main_menu.gd")

var time_label: Label = null
var level_box: CenterContainer = null
var resume_button: Button = null
var settings_button: Button = null
var menu_button: Button = null
var about_button: Button = null
## The face of Buy me a coffee; coffee_touch is its 48 dp touch area.
var coffee_button: Button = null
var coffee_touch: Control = null
## PAUSED, the level and the time first, the buttons second: centered in one
## column when stacked, two halves side by side (DESIGN_SYSTEM.md 4.11).
var halves: HalvesBox = null

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
	halves = HalvesBox.new()
	halves.name = "Halves"
	halves.skin = skin
	halves.stacked_mode = HalvesBox.Stacked.CENTER
	halves.stacked_gap = skin.space_xl
	halves.side_gap = skin.space_xl
	_column.add_child(halves)
	var info: VBoxContainer = UiKit.vbox(skin.space_m)
	info.name = "Info"
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	halves.add_child(info)
	var title: Label = UiKit.label(ThemeFactory.DISPLAY, "Paused")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_child(title)
	level_box = CenterContainer.new()
	level_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(level_box)
	time_label = UiKit.label(ThemeFactory.VALUE, "")
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_child(time_label)
	var buttons: VBoxContainer = UiKit.vbox(skin.space_m)
	buttons.name = "Buttons"
	var second: VBoxContainer = UiKit.vbox(0.0)
	second.name = "Second"
	second.alignment = BoxContainer.ALIGNMENT_CENTER
	halves.add_child(second)
	second.add_child(UiKit.with_shadow_room(buttons, skin))
	resume_button = UiKit.button(ThemeFactory.BUTTON_PRIMARY, "Resume", Layout.BUTTON_TALL, Icons.PLAY)
	resume_button.name = "Resume"
	resume_button.pressed.connect(_emit_if_open.bind(resume_pressed))
	buttons.add_child(resume_button)
	settings_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Settings", Layout.BUTTON_TALL, Icons.SETTINGS)
	settings_button.name = "Settings"
	settings_button.pressed.connect(_emit_if_open.bind(settings_pressed))
	buttons.add_child(settings_button)
	menu_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Menu", Layout.BUTTON_TALL)
	menu_button.name = "Menu"
	menu_button.pressed.connect(_emit_if_open.bind(menu_pressed))
	buttons.add_child(menu_button)
	about_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "About", Layout.BUTTON_TALL)
	about_button.name = "About"
	about_button.pressed.connect(_emit_if_open.bind(about_pressed))
	buttons.add_child(about_button)
	var coffee: UiKit.TouchTarget = UiKit.coffee_button()
	coffee_touch = coffee
	coffee_button = coffee.button
	coffee_button.pressed.connect(_emit_if_open.bind(coffee_pressed))
	second.add_child(coffee)
	halves.arranged.connect(func(side: bool) -> void: MainMenuScript.move_to_half(halves, coffee_touch, side))
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
