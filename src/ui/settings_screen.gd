extends UiScreen
## Settings (GDD 4.5, 5.2, 13.2 and 14, DESIGN_SYSTEM.md 7.11): Sound, Show
## candidates and Auto Cross with their one line each, the skin picker (Pop light and Pop dark), and Reset
## Stats with its confirmation. Opens from the main menu and from the pause
## menu; Back returns to where it came from.
## Owner: ui-systems-dev.

const SHOW_CANDIDATES_LINE: String = "Shows the candidate ring in empty cells. Off, every tap places a digit. Your marks stay."
const AUTO_CROSS_LINE: String = "Crosses out ring digits the board rules out. Your marks stay."
const RESET_TEXT: String = "Reset all stats? This cannot be undone."

var sound_switch: CheckButton = null
var show_candidates_switch: CheckButton = null
var auto_cross_switch: CheckButton = null
var skin_buttons: Dictionary[StringName, Button] = {}
var reset_button: Button = null
var confirm: ConfirmDialog = null


func build() -> void:
	var s: GameSkin = skin()
	var stack: VBoxContainer = UiKit.vbox(s.space_s)
	column.add_child(stack)
	stack.add_child(UiKit.title_row("Settings", s.space_s, _on_back_pressed))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)
	var rows: VBoxContainer = UiKit.vbox(s.space_m)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)

	var sound_card: PanelContainer = _row_card()
	sound_card.name = "Sound"
	rows.add_child(sound_card)
	sound_switch = _switch("Sound")
	sound_switch.toggled.connect(func(on: bool) -> void: app.set_sound(on))
	sound_card.add_child(sound_switch)

	var show_card: PanelContainer = _row_card()
	show_card.name = "ShowCandidates"
	rows.add_child(show_card)
	var show_box: VBoxContainer = UiKit.vbox(0.0)
	show_card.add_child(show_box)
	show_candidates_switch = _switch("Show candidates")
	show_candidates_switch.toggled.connect(func(on: bool) -> void: app.set_show_candidates(on))
	show_box.add_child(show_candidates_switch)
	show_box.add_child(UiKit.label(ThemeFactory.BODY_MUTED, SHOW_CANDIDATES_LINE, true))

	var auto_card: PanelContainer = _row_card()
	auto_card.name = "AutoCross"
	rows.add_child(auto_card)
	var auto_box: VBoxContainer = UiKit.vbox(0.0)
	auto_card.add_child(auto_box)
	auto_cross_switch = _switch("Auto Cross")
	auto_cross_switch.toggled.connect(func(on: bool) -> void: app.set_auto_cross(on))
	auto_box.add_child(auto_cross_switch)
	auto_box.add_child(UiKit.label(ThemeFactory.BODY_MUTED, AUTO_CROSS_LINE, true))

	rows.add_child(UiKit.label(ThemeFactory.CAPTION, "Skin"))
	var options: HBoxContainer = UiKit.hbox(s.space_m)
	options.name = "Skins"
	rows.add_child(options)
	var group: ButtonGroup = ButtonGroup.new()
	for id: StringName in Settings.SKIN_IDS:
		var option: Button = _skin_option(s, id, group)
		options.add_child(option)
		skin_buttons[id] = option

	var spacer: Control = Control.new()
	spacer.custom_minimum_size.y = s.space_xl - s.space_m
	rows.add_child(spacer)
	reset_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Reset stats", Layout.BUTTON_TALL)
	reset_button.name = "ResetStats"
	reset_button.pressed.connect(_on_reset_pressed)
	rows.add_child(reset_button)
	var shadow_room: Control = Control.new()
	shadow_room.custom_minimum_size.y = s.shadow_offset
	rows.add_child(shadow_room)

	confirm = ConfirmDialog.new()
	confirm.name = "Confirm"
	confirm.setup(s, RESET_TEXT, "Cancel", "Reset", ThemeFactory.BUTTON_DANGER)
	confirm.confirmed.connect(func() -> void: app.reset_stats())
	add_child(confirm)
	refresh()
	if app != null:
		app.settings_changed.connect(refresh)


func handle_back() -> bool:
	if confirm.is_open():
		confirm.cancel()
		return true
	return false


func on_shown() -> void:
	refresh()


## Shows the settings as they are, without sending any change back.
func refresh() -> void:
	if app == null:
		return
	sound_switch.set_pressed_no_signal(app.settings.sound)
	show_candidates_switch.set_pressed_no_signal(app.settings.show_candidates)
	auto_cross_switch.set_pressed_no_signal(app.settings.auto_cross)
	for id: StringName in skin_buttons:
		skin_buttons[id].set_pressed_no_signal(id == app.settings.skin_id)


func _on_reset_pressed() -> void:
	confirm.show_dialog()


func _row_card() -> PanelContainer:
	var card: PanelContainer = UiKit.panel(ThemeFactory.CARD)
	card.custom_minimum_size.y = UiSizes.ROW
	return card


## A row name in heading style with the switch at the right. The switch
## draws its own ON or OFF caption (ThemeFactory SWITCH).
func _switch(text: String) -> CheckButton:
	var node: CheckButton = CheckButton.new()
	node.theme_type_variation = ThemeFactory.SWITCH
	node.text = ThemeFactory.display_text(ThemeFactory.HEADING, text)
	node.focus_mode = Control.FOCUS_NONE
	node.name = text.replace(" ", "")
	return node


func _skin_option(s: GameSkin, id: StringName, group: ButtonGroup) -> Button:
	var option: Button = Button.new()
	option.theme_type_variation = ThemeFactory.SKIN_OPTION
	option.toggle_mode = true
	option.button_group = group
	option.focus_mode = Control.FOCUS_NONE
	option.custom_minimum_size.y = UiSizes.SKIN_OPTION_H
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.name = String(id)
	var own: GameSkin = app.builtin_skin(id) if app != null else load("res://src/skins/%s.tres" % id) as GameSkin
	var inside: VBoxContainer = UiKit.vbox(s.space_s)
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pad: float = s.space_m + s.outline_w
	inside.offset_left = pad
	inside.offset_top = pad
	inside.offset_right = -pad
	inside.offset_bottom = -pad
	option.add_child(inside)
	var preview: SkinPreview = SkinPreview.new()
	preview.skin = own
	inside.add_child(preview)
	inside.add_child(UiKit.label(ThemeFactory.HEADING, own.display_name if own != null else String(id)))
	option.pressed.connect(func() -> void:
		Motion.press(option)
		app.set_skin(id))
	return option
