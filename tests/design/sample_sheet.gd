extends SceneTree
## Proof sheet for the Theme, the icons and the switch: every button style and
## state, the pad in both modes, panels, stickers, a dialog over its scrim,
## the hint panel, the full board message, the type roles and every icon, in
## Pop light and Pop dark side by side. Everything is built from the
## ThemeFactory constants exactly as a screen would build it.
##
## Needs a window (headless has no renderer):
##   timeout 120 godot --path . --script res://tests/design/sample_sheet.gd
## Writes build/design/sample_sheet.png (git ignored) at density 2.
## Not a test file: the runner only picks up test_*.gd.

const SKIN_PATHS: Array[String] = ["res://src/skins/pop_light.tres", "res://src/skins/pop_dark.tres"]
const COLUMN_W: float = 412.0
const SHEET_H: float = 2090.0
const DENSITY: float = 2.0
const OUT_DIR: String = "res://build/design/"
const OUT_FILE: String = "sample_sheet.png"
const FRAMES_BEFORE_CAPTURE: int = 6

var _viewport: SubViewport = null
var _frames: int = 0


func _initialize() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(roundi(COLUMN_W * 2.0 * DENSITY), roundi(SHEET_H * DENSITY))
	_viewport.size_2d_override = Vector2i(roundi(COLUMN_W * 2.0), roundi(SHEET_H))
	_viewport.size_2d_override_stretch = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.transparent_bg = false
	root.add_child(_viewport)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 0)
	row.size = Vector2(COLUMN_W * 2.0, SHEET_H)
	_viewport.add_child(row)
	for path: String in SKIN_PATHS:
		row.add_child(_column(load(path) as GameSkin))


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < FRAMES_BEFORE_CAPTURE:
		return false
	var image: Image = _viewport.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var ignore: String = ProjectSettings.globalize_path(OUT_DIR + ".gdignore")
	if not FileAccess.file_exists(ignore):
		FileAccess.open(ignore, FileAccess.WRITE).store_string("")
	var out: String = ProjectSettings.globalize_path(OUT_DIR + OUT_FILE)
	var err: Error = image.save_png(out)
	print("sample sheet %s: %s (%d by %d px)" % ["written" if err == OK else "FAILED", out, image.get_width(), image.get_height()])
	quit(0 if err == OK else 1)
	return true


# One column per skin

func _column(skin: GameSkin) -> Control:
	var page: PanelContainer = PanelContainer.new()
	page.custom_minimum_size = Vector2(COLUMN_W, SHEET_H)
	page.theme = ThemeFactory.build(skin)
	# PAGE is a Panel style; a PanelContainer reads it here so the column can
	# hold a layout. Screens use a Panel with PAGE.
	page.add_theme_stylebox_override(&"panel", page.theme.get_stylebox(&"panel", ThemeFactory.PAGE))
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, roundi(skin.space_l))
	page.add_child(margin)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", roundi(skin.space_m))
	margin.add_child(stack)

	stack.add_child(_label(ThemeFactory.TITLE, "Pop %s" % skin.display_name))
	stack.add_child(_caption("Header row: Hint, time, score, Pause"))
	stack.add_child(_header())
	stack.add_child(_caption("Stickers and tags"))
	stack.add_child(_stickers())
	stack.add_child(_caption("Buttons: normal, pressed, disabled"))
	stack.add_child(_buttons())
	stack.add_child(_caption("Icon buttons"))
	stack.add_child(_icon_buttons())
	stack.add_child(_caption("Pad: Place keys, Cross Out keys, locked keys"))
	stack.add_child(_pad())
	stack.add_child(_caption("List button, skin options, switches, rule, stat bar"))
	stack.add_child(_lists())
	stack.add_child(_caption("Type roles in a card"))
	stack.add_child(_type_card())
	stack.add_child(_caption("Dialog over the scrim"))
	stack.add_child(_dialog())
	stack.add_child(_caption("Hint panel and full board message"))
	stack.add_child(_hint_panel())
	stack.add_child(_board_message())
	stack.add_child(_caption("Icons at 20, 24 and 48"))
	stack.add_child(_icons())
	return page


# Parts, built as a screen would: a type variation and text, nothing else
# (layout sizes aside).

func _label(variation: StringName, text: String) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.text = ThemeFactory.display_text(variation, text)
	return label


func _caption(text: String) -> Label:
	return _label(ThemeFactory.CAPTION, text)


func _button(variation: StringName, text: String, icon: StringName = &"", icon_side: float = Icons.SIZE_BUTTON) -> Button:
	var button: Button = Button.new()
	button.theme_type_variation = variation
	button.text = ThemeFactory.display_text(variation, text)
	button.focus_mode = Control.FOCUS_NONE
	if icon != &"":
		button.icon = Icons.texture(icon, icon_side)
	return button


func _panel(variation: StringName, child: Control) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = variation
	panel.add_child(child)
	return panel


func _row(gap: float = 12.0) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", roundi(gap))
	return row


func _two_lines(top_variation: StringName, top: String, bottom_variation: StringName, bottom: String) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 0)
	box.add_child(_label(top_variation, top))
	box.add_child(_label(bottom_variation, bottom))
	return box


func _header() -> Control:
	var row: HBoxContainer = _row(Layout.HEADER_GUARD)
	var hint: Button = _button(ThemeFactory.HINT_BUTTON, "Hint\n−80", Icons.HINT)
	hint.custom_minimum_size = Vector2(Layout.HINT_FACE_W, 40.0)
	row.add_child(hint)
	var hint_off: Button = _button(ThemeFactory.HINT_BUTTON, "Hint\n−80", Icons.HINT)
	hint_off.custom_minimum_size = Vector2(Layout.HINT_FACE_W, 40.0)
	hint_off.disabled = true
	row.add_child(hint_off)
	var time: PanelContainer = _panel(ThemeFactory.HUD_TIME, _two_lines(ThemeFactory.HUD_CAPTION, "Time", ThemeFactory.HUD_VALUE, "12:48"))
	time.custom_minimum_size.x = Layout.TIME_MIN_W
	row.add_child(time)
	var score: PanelContainer = _panel(ThemeFactory.HUD_SCORE, _two_lines(ThemeFactory.SCORE_CAPTION, "Score", ThemeFactory.SCORE_VALUE, "320"))
	score.custom_minimum_size.x = Layout.SCORE_MIN_W
	row.add_child(score)
	row.add_child(_button(ThemeFactory.ICON_BUTTON, "", Icons.PAUSE, Icons.SIZE_ICON_BUTTON))
	return row


func _stickers() -> Control:
	var row: HBoxContainer = _row()
	var level: PanelContainer = _panel(ThemeFactory.STICKER, _label(ThemeFactory.STICKER_LABEL, "Medium"))
	row.add_child(_tilted(level, 3.0))
	var best: PanelContainer = _panel(ThemeFactory.CELEBRATE_STICKER, _label(ThemeFactory.CELEBRATE_LABEL, "New best time"))
	row.add_child(_tilted(best, -3.0))
	row.add_child(_panel(ThemeFactory.HINT_TAG, _label(ThemeFactory.HINT_TAG_LABEL, "Hidden single")))
	return row


## Stickers tilt counterclockwise; the screen sets the rotation.
func _tilted(control: Control, degrees: float) -> Control:
	var holder: CenterContainer = CenterContainer.new()
	holder.add_child(control)
	control.resized.connect(func() -> void:
		control.pivot_offset = control.size * 0.5
		control.rotation_degrees = -degrees)
	return holder


func _buttons() -> Control:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", 12)
	grid.add_theme_constant_override(&"v_separation", 12)
	for variation: StringName in [ThemeFactory.BUTTON_PRIMARY, ThemeFactory.BUTTON_SECONDARY, ThemeFactory.BUTTON_DANGER]:
		var label: String = {ThemeFactory.BUTTON_PRIMARY: "Continue", ThemeFactory.BUTTON_SECONDARY: "Menu", ThemeFactory.BUTTON_DANGER: "Start new"}[variation]
		var normal: Button = _button(variation, label)
		normal.custom_minimum_size = Vector2(110.0, 48.0)
		grid.add_child(normal)
		var pressed: Button = _button(variation, label)
		pressed.toggle_mode = true
		pressed.button_pressed = true
		pressed.custom_minimum_size = Vector2(110.0, 48.0)
		grid.add_child(pressed)
		var off: Button = _button(variation, label)
		off.disabled = true
		off.custom_minimum_size = Vector2(110.0, 48.0)
		grid.add_child(off)
	return grid


func _icon_buttons() -> Control:
	var row: HBoxContainer = _row()
	for icon: StringName in [Icons.PAUSE, Icons.BACK, Icons.CLOSE, Icons.SETTINGS, Icons.PLAY]:
		row.add_child(_button(ThemeFactory.ICON_BUTTON, "", icon, Icons.SIZE_ICON_BUTTON))
	var off: Button = _button(ThemeFactory.ICON_BUTTON, "", Icons.LOCK, Icons.SIZE_ICON_BUTTON)
	off.disabled = true
	row.add_child(off)
	var held: Button = _button(ThemeFactory.ICON_BUTTON, "", Icons.CHECK, Icons.SIZE_ICON_BUTTON)
	held.toggle_mode = true
	held.button_pressed = true
	row.add_child(held)
	return row


func _pad() -> Control:
	var row: HBoxContainer = _row(20.0)
	var keys: GridContainer = GridContainer.new()
	keys.columns = 3
	keys.add_theme_constant_override(&"h_separation", 8)
	keys.add_theme_constant_override(&"v_separation", 8)
	for digit: int in range(1, 10):
		var variation: StringName = ThemeFactory.PAD_KEY_PLACE if digit <= 3 else ThemeFactory.PAD_KEY_CROSS
		var key: Button = _button(variation, str(digit))
		key.custom_minimum_size = Vector2(62.0, 52.0)
		if digit == 2 or digit == 5:
			key.toggle_mode = true
			key.button_pressed = true
		if digit >= 7:
			key.disabled = true
		keys.add_child(key)
	row.add_child(keys)
	var actions: VBoxContainer = VBoxContainer.new()
	actions.add_theme_constant_override(&"separation", 8)
	var place: Button = _button(ThemeFactory.MODE_BUTTON, "Place", Icons.MODE_PLACE)
	place.toggle_mode = true
	place.button_pressed = true
	place.custom_minimum_size = Vector2(130.0, 52.0)
	actions.add_child(place)
	var cross: Button = _button(ThemeFactory.MODE_BUTTON, "Cross out", Icons.MODE_CROSS_OUT)
	cross.toggle_mode = true
	cross.custom_minimum_size = Vector2(130.0, 52.0)
	actions.add_child(cross)
	var small: HBoxContainer = _row(8.0)
	var undo: Button = _button(ThemeFactory.PAD_ACTION, "Undo", Icons.UNDO)
	undo.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	undo.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	undo.custom_minimum_size = Vector2(61.0, 52.0)
	undo.disabled = true
	small.add_child(undo)
	var erase: Button = _button(ThemeFactory.PAD_ACTION, "Erase", Icons.ERASE)
	erase.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	erase.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	erase.custom_minimum_size = Vector2(61.0, 52.0)
	small.add_child(erase)
	actions.add_child(small)
	row.add_child(actions)
	return row


func _lists() -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 12)
	var list: Button = _button(ThemeFactory.LIST_BUTTON, "Beginner")
	list.alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(list)
	var skins: HBoxContainer = _row()
	var light: Button = _button(ThemeFactory.SKIN_OPTION, "Light")
	light.toggle_mode = true
	light.button_pressed = true
	light.custom_minimum_size = Vector2(150.0, 64.0)
	light.alignment = HORIZONTAL_ALIGNMENT_LEFT
	skins.add_child(light)
	var dark: Button = _button(ThemeFactory.SKIN_OPTION, "Dark")
	dark.toggle_mode = true
	dark.custom_minimum_size = Vector2(150.0, 64.0)
	dark.alignment = HORIZONTAL_ALIGNMENT_LEFT
	skins.add_child(dark)
	box.add_child(skins)
	var switches: HBoxContainer = _row(24.0)
	var sound: CheckButton = CheckButton.new()
	sound.theme_type_variation = ThemeFactory.SWITCH
	sound.text = ThemeFactory.display_text(ThemeFactory.SWITCH, "Sound")
	sound.button_pressed = true
	sound.focus_mode = Control.FOCUS_NONE
	switches.add_child(sound)
	var auto_cross: CheckButton = CheckButton.new()
	auto_cross.theme_type_variation = ThemeFactory.SWITCH
	auto_cross.text = ThemeFactory.display_text(ThemeFactory.SWITCH, "Auto Cross")
	auto_cross.focus_mode = Control.FOCUS_NONE
	switches.add_child(auto_cross)
	box.add_child(switches)
	var rule: HSeparator = HSeparator.new()
	rule.theme_type_variation = ThemeFactory.RULE
	box.add_child(rule)
	var bar: ProgressBar = ProgressBar.new()
	bar.theme_type_variation = ThemeFactory.STAT_BAR
	bar.show_percentage = false
	bar.value = 65.0
	box.add_child(bar)
	return box


func _type_card() -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 2)
	box.add_child(_two_lines(ThemeFactory.DISPLAY, "Paused", ThemeFactory.DISPLAY_ACCENT, "595"))
	var solved: PanelContainer = _panel(ThemeFactory.CELEBRATE_STICKER, _label(ThemeFactory.CELEBRATE_DISPLAY, "Solved!"))
	box.add_child(_tilted(solved, 6.0))
	box.add_child(_label(ThemeFactory.HEADING, "The ring and Cross Out"))
	var body: Label = _label(ThemeFactory.BODY, "A column can have each digit only once, too. This column has a 4 and a 6. Cross out 4 and 6.")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	box.add_child(_label(ThemeFactory.BODY_SMALL, "In this box, 1 fits in only one cell."))
	box.add_child(_label(ThemeFactory.BODY_MUTED, "Rows, columns and boxes"))
	box.add_child(_two_lines(ThemeFactory.CAPTION, "Best time", ThemeFactory.VALUE, "11:05"))
	return _panel(ThemeFactory.CARD, box)


func _dialog() -> Control:
	var scrim: Panel = Panel.new()
	scrim.theme_type_variation = ThemeFactory.SCRIM
	scrim.custom_minimum_size = Vector2(0.0, 196.0)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 12)
	var text: Label = _label(ThemeFactory.BODY, "Reset all stats? This cannot be undone.")
	text.custom_minimum_size.x = 300.0
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text)
	var cancel: Button = _button(ThemeFactory.BUTTON_SECONDARY, "Cancel")
	cancel.custom_minimum_size.y = 48.0
	box.add_child(cancel)
	var reset: Button = _button(ThemeFactory.BUTTON_DANGER, "Reset")
	reset.custom_minimum_size.y = 48.0
	box.add_child(reset)
	center.add_child(_panel(ThemeFactory.DIALOG, box))
	return scrim


func _hint_panel() -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 6)
	var top: HBoxContainer = _row(8.0)
	top.add_child(_panel(ThemeFactory.HINT_TAG, _label(ThemeFactory.HINT_TAG_LABEL, "Hidden single")))
	var lesson: Label = _label(ThemeFactory.CAPTION, "Lesson: Hidden single")
	lesson.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(lesson)
	top.add_child(_button(ThemeFactory.ICON_BUTTON, "", Icons.CLOSE, Icons.SIZE_ICON_BUTTON))
	box.add_child(top)
	var text: Label = _label(ThemeFactory.BODY_SMALL, "In this box, 1 fits in only one cell. It goes here.")
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text)
	return _panel(ThemeFactory.HINT_PANEL, box)


func _board_message() -> Control:
	var text: Label = _label(ThemeFactory.BODY_SMALL, "The board is full, but some digits clash. Fix the marked cells.")
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return _panel(ThemeFactory.BOARD_MESSAGE, text)


func _icons() -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 8)
	for side: float in [Icons.SIZE_BUTTON, Icons.SIZE_ICON_BUTTON, 48.0]:
		var grid: GridContainer = GridContainer.new()
		grid.columns = 12 if side < 48.0 else 6
		grid.add_theme_constant_override(&"h_separation", 8)
		grid.add_theme_constant_override(&"v_separation", 8)
		for icon: StringName in Icons.ALL:
			var view: IconView = IconView.new()
			view.icon = icon
			view.custom_minimum_size = Vector2(side, side)
			grid.add_child(view)
		box.add_child(grid)
	return box
