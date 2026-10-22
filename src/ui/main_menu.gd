extends UiScreen
## The main menu (DESIGN_SYSTEM.md 7.1, GDD 15.1 and 15.7): the SUDOKU
## wordmark, the hero, then Continue (only with a puzzle in progress, with
## its level and time), New puzzle, then Lessons and Stats, and Settings and
## About, side by side in two rows, then the smaller Buy me a coffee button. About opens
## the About screen over this one; Back there comes back here. Buy me a
## coffee hands the support page to the phone's web browser
## (App.open_support_page); the game itself sends nothing. About and Buy me
## a coffee do nothing while a puzzle is being made.
##
## Side by side (4.11) the wordmark and hero take the left half and the
## buttons the right half, centered. The right half has no room left at the
## smallest height, so there Buy me a coffee moves to the bottom of the left
## half, under the hero, as on the title screen. The hero has space_l above
## and below it here, not space_xl, to make room for Buy me a coffee at 320
## by 507.
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
var about_button: Button = null
## The face of Buy me a coffee; coffee_touch is its 48 dp touch area.
var coffee_button: Button = null
var coffee_touch: Control = null
## Wordmark and hero first, the buttons second: one column when stacked, two
## halves side by side (DESIGN_SYSTEM.md 4.11).
var halves: HalvesBox = null


func build() -> void:
	var s: GameSkin = skin()
	halves = halves_box(s)
	column.add_child(halves)
	var brand_stack: VBoxContainer = brand(s)
	halves.add_child(brand_stack)
	# space_l above and below the hero, as on the title screen, so the hero
	# keeps its 64 dp minimum over the buttons and Buy me a coffee.
	(brand_stack.get_node(^"Hero") as HeroIcon).gap = s.space_l

	var second: VBoxContainer = UiKit.vbox(0.0)
	second.name = "Second"
	second.alignment = BoxContainer.ALIGNMENT_CENTER
	halves.add_child(second)
	var buttons: VBoxContainer = UiKit.vbox(s.space_m)
	buttons.name = "Buttons"
	second.add_child(UiKit.with_shadow_room(buttons, s))
	continue_button = _continue_button()
	buttons.add_child(continue_button)
	new_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "New puzzle", Layout.BUTTON_TALL)
	new_button.name = "NewPuzzle"
	new_button.pressed.connect(func() -> void: app.goto(AppService.LEVEL_SELECT))
	buttons.add_child(new_button)
	# Lessons, Stats, Settings and About in two rows of two, in reading
	# order (GDD 15.7). A row of three does not fit the right half of the
	# smallest side by side window, and a fifth full row has no height there.
	var top_pair: HBoxContainer = UiKit.hbox(s.space_m)
	top_pair.name = "TopPair"
	buttons.add_child(top_pair)
	var bottom_pair: HBoxContainer = UiKit.hbox(s.space_m)
	bottom_pair.name = "BottomPair"
	buttons.add_child(bottom_pair)
	lessons_button = _half(top_pair, "Lessons", func() -> void: app.goto(AppService.LESSONS))
	stats_button = _half(top_pair, "Stats", func() -> void: app.goto(AppService.STATS))
	settings_button = _half(bottom_pair, "Settings", func() -> void: app.goto(AppService.SETTINGS))
	about_button = _half(bottom_pair, "About", _on_about)
	var coffee: UiKit.TouchTarget = UiKit.coffee_button()
	coffee_touch = coffee
	coffee_button = coffee.button
	coffee_button.pressed.connect(_on_coffee)
	second.add_child(coffee)
	halves.arranged.connect(_on_arranged)
	refresh()


func on_shown() -> void:
	refresh()


## A secondary button that takes an equal share of row.
func _half(row: HBoxContainer, text: String, action: Callable) -> Button:
	var button: Button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, text, Layout.BUTTON_TALL)
	button.name = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	row.add_child(button)
	return button


func _on_about() -> void:
	if app != null and not app.is_generating():
		app.goto(AppService.ABOUT)


func _on_coffee() -> void:
	if app != null and not app.is_generating():
		app.open_support_page()


## Stacked, Buy me a coffee sits under the buttons; side by side, under the
## hero.
func _on_arranged(side: bool) -> void:
	move_to_half(halves, coffee_touch, side)


## Moves item to the end of halves' first part when side is true, else to
## the end of its second part. The main menu, the title screen and the
## pause menu use it for Buy me a coffee.
static func move_to_half(box: HalvesBox, item: Control, side: bool) -> void:
	var target: Node = box.get_child(0) if side else box.get_child(1)
	if item.get_parent() == target:
		return
	item.get_parent().remove_child(item)
	target.add_child(item)


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
