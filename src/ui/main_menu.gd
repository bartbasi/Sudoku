extends UiScreen
## The main menu (DESIGN_SYSTEM.md 7.1, GDD 15.1): the SUDOKU wordmark, the
## hero, then Continue (only with a puzzle in progress, with its level and
## time), New puzzle, Lessons, and Stats and Settings side by side. Side by
## side (4.11) the wordmark and hero take the left half and the buttons the
## right half, centered.
## Owner: ui-systems-dev.

const WORDMARK: String = "Sudoku"

const PopBox := preload("res://src/design/pop_box.gd")

var continue_button: Button = null
## The level and time line inside Continue.
var continue_caption: Label = null
var new_button: Button = null
var lessons_button: Button = null
var stats_button: Button = null
var settings_button: Button = null
## Wordmark and hero first, the buttons second: one column when stacked, two
## halves side by side (DESIGN_SYSTEM.md 4.11).
var halves: HalvesBox = null


func build() -> void:
	var s: GameSkin = skin()
	halves = halves_box(s)
	column.add_child(halves)
	halves.add_child(brand(s))

	var buttons: VBoxContainer = UiKit.vbox(s.space_m)
	buttons.name = "Buttons"
	halves.add_child(UiKit.with_shadow_room(buttons, s))
	continue_button = _continue_button()
	buttons.add_child(continue_button)
	new_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "New puzzle", Layout.BUTTON_TALL)
	new_button.name = "NewPuzzle"
	new_button.pressed.connect(func() -> void: app.goto(AppService.LEVEL_SELECT))
	buttons.add_child(new_button)
	lessons_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Lessons", Layout.BUTTON_TALL)
	lessons_button.name = "Lessons"
	lessons_button.pressed.connect(func() -> void: app.goto(AppService.LESSONS))
	buttons.add_child(lessons_button)
	var pair: HBoxContainer = UiKit.hbox(s.space_m)
	buttons.add_child(pair)
	stats_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Stats", Layout.BUTTON_TALL)
	stats_button.name = "Stats"
	stats_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_button.pressed.connect(func() -> void: app.goto(AppService.STATS))
	pair.add_child(stats_button)
	settings_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Settings", Layout.BUTTON_TALL)
	settings_button.name = "Settings"
	settings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_button.pressed.connect(func() -> void: app.goto(AppService.SETTINGS))
	pair.add_child(settings_button)
	refresh()


func on_shown() -> void:
	refresh()


## Continue shows only with a puzzle in progress; New puzzle is primary when
## it does not.
func refresh() -> void:
	var has_puzzle: bool = app != null and app.has_puzzle_in_progress()
	continue_button.visible = has_puzzle
	new_button.theme_type_variation = ThemeFactory.BUTTON_SECONDARY if has_puzzle else ThemeFactory.BUTTON_PRIMARY
	if has_puzzle:
		var line: String = "%s, %s" % [Levels.name_of(app.session.level), UiKit.format_time(app.session.elapsed_seconds())]
		UiKit.set_text(continue_caption, line)


## The two halves box of the main menu and the first launch offer: stacked,
## the first part (wordmark and hero) takes the height the second leaves.
static func halves_box(s: GameSkin) -> HalvesBox:
	var box: HalvesBox = HalvesBox.new()
	box.name = "Halves"
	box.skin = s
	box.stacked_mode = HalvesBox.Stacked.FILL_FIRST
	box.side_gap = s.space_xl
	return box


## The wordmark at the top and the hero under it, filling the height left
## (7.1). Also used by the first launch offer.
static func brand(s: GameSkin) -> VBoxContainer:
	var stack: VBoxContainer = UiKit.vbox(0.0)
	stack.name = "Brand"
	stack.add_child(wordmark(s))
	var hero: HeroIcon = HeroIcon.new()
	hero.name = "Hero"
	hero.gap = s.space_xl
	stack.add_child(hero)
	return stack


## The SUDOKU sticker, centered (7.1). Also used by the first launch offer.
static func wordmark(s: GameSkin) -> Control:
	var center: CenterContainer = CenterContainer.new()
	center.name = "Wordmark"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(UiKit.sticker(ThemeFactory.CELEBRATE_STICKER, ThemeFactory.CELEBRATE_DISPLAY, WORDMARK, s.sticker_tilt))
	return center


## Continue (7.1): the button has no text of its own. A centered box with
## CONTINUE in PRIMARY_LABEL over the level and time in PRIMARY_CAPTION
## fills its content rect and follows the face when the button sinks.
func _continue_button() -> Button:
	var button: Button = continue_button_with_lines()
	continue_caption = button.get_node(^"Lines/Caption") as Label
	button.pressed.connect(func() -> void: app.goto(AppService.PLAY))
	return button


## The Continue button with its two lines, without the caption text and
## without a pressed action. Static, so design checks can build the real one.
static func continue_button_with_lines() -> Button:
	var button: Button = UiKit.button(ThemeFactory.BUTTON_PRIMARY, "", Layout.BUTTON_TALL)
	button.name = "Continue"
	var lines: VBoxContainer = UiKit.vbox(0.0)
	lines.name = "Lines"
	lines.alignment = BoxContainer.ALIGNMENT_CENTER
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	var title: Label = UiKit.label(ThemeFactory.PRIMARY_LABEL, "Continue")
	title.name = "Label"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lines.add_child(title)
	var caption: Label = UiKit.label(ThemeFactory.PRIMARY_CAPTION, "")
	caption.name = "Caption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lines.add_child(caption)
	button.add_child(lines)
	_follow_face(button, lines)
	button.draw.connect(func() -> void: _follow_face(button, lines))
	return button


## Puts lines in the button's content rect (the normal style's content
## margins when raised), moved by the face offset of the style the button
## draws now, so the lines sink with the face.
static func _follow_face(button: Button, lines: Control) -> void:
	var normal: StyleBox = button.get_theme_stylebox(&"normal")
	var margins: Rect2 = Rect2(normal.get_margin(SIDE_LEFT), normal.get_margin(SIDE_TOP), normal.get_margin(SIDE_RIGHT), normal.get_margin(SIDE_BOTTOM))
	var normal_pop: PopBox = normal as PopBox
	if normal_pop != null:
		margins = Rect2(normal_pop.pad_left, normal_pop.pad_top, normal_pop.pad_right, normal_pop.pad_bottom)
	var shift: Vector2 = Vector2.ZERO
	var current: PopBox = button.get_theme_stylebox(_draw_style(button)) as PopBox
	if current != null:
		shift = current.face_rect(Rect2()).position
	lines.offset_left = margins.position.x + shift.x
	lines.offset_top = margins.position.y + shift.y
	lines.offset_right = -margins.size.x + shift.x
	lines.offset_bottom = -margins.size.y + shift.y


## The style name for the button's draw mode.
static func _draw_style(button: Button) -> StringName:
	match button.get_draw_mode():
		BaseButton.DRAW_PRESSED:
			return &"pressed"
		BaseButton.DRAW_HOVER:
			return &"hover"
		BaseButton.DRAW_DISABLED:
			return &"disabled"
		BaseButton.DRAW_HOVER_PRESSED:
			return &"hover_pressed" if button.has_theme_stylebox(&"hover_pressed") else &"pressed"
		_:
			return &"normal"
