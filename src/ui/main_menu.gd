extends UiScreen
## The main menu (DESIGN_SYSTEM.md 7.1, GDD 15.1): the SUDOKU wordmark, the
## hero, then Continue (only with a puzzle in progress, with its level and
## time), New puzzle, Lessons, and Stats and Settings side by side.
## Owner: ui-systems-dev.

const WORDMARK: String = "Sudoku"

var continue_button: Button = null
var new_button: Button = null
var lessons_button: Button = null
var stats_button: Button = null
var settings_button: Button = null


func build() -> void:
	var s: GameSkin = skin()
	var stack: VBoxContainer = UiKit.vbox(0.0)
	column.add_child(stack)
	stack.add_child(wordmark(s))
	var hero: HeroIcon = HeroIcon.new()
	hero.name = "Hero"
	hero.gap = s.space_xl
	stack.add_child(hero)

	var buttons: VBoxContainer = UiKit.vbox(s.space_m)
	buttons.name = "Buttons"
	stack.add_child(buttons)
	continue_button = _continue_button()
	buttons.add_child(continue_button)
	new_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "New puzzle", UiSizes.BUTTON_TALL)
	new_button.name = "NewPuzzle"
	new_button.pressed.connect(func() -> void: app.goto(AppService.LEVEL_SELECT))
	buttons.add_child(new_button)
	lessons_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Lessons", UiSizes.BUTTON_TALL)
	lessons_button.name = "Lessons"
	lessons_button.pressed.connect(func() -> void: app.goto(AppService.LESSONS))
	buttons.add_child(lessons_button)
	var halves: HBoxContainer = UiKit.hbox(s.space_m)
	buttons.add_child(halves)
	stats_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Stats", UiSizes.BUTTON_TALL)
	stats_button.name = "Stats"
	stats_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_button.pressed.connect(func() -> void: app.goto(AppService.STATS))
	halves.add_child(stats_button)
	settings_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Settings", UiSizes.BUTTON_TALL)
	settings_button.name = "Settings"
	settings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_button.pressed.connect(func() -> void: app.goto(AppService.SETTINGS))
	halves.add_child(settings_button)
	# Room for the buttons' hard shadow under the last row.
	var shadow_room: Control = Control.new()
	shadow_room.custom_minimum_size.y = s.shadow_offset
	buttons.add_child(shadow_room)
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
		continue_button.text = ThemeFactory.display_text(ThemeFactory.BUTTON_PRIMARY, "Continue
" + line)


## The SUDOKU sticker, centered (7.1). Also used by the first launch offer.
static func wordmark(s: GameSkin) -> Control:
	var center: CenterContainer = CenterContainer.new()
	center.name = "Wordmark"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(UiKit.sticker(ThemeFactory.CELEBRATE_STICKER, ThemeFactory.CELEBRATE_DISPLAY, WORDMARK, s.sticker_tilt))
	return center


## Continue with its level and time on a second line. Both lines are in
## the button role: no theme style sets a caption line inside a primary
## button yet (see the report).
func _continue_button() -> Button:
	var button: Button = UiKit.button(ThemeFactory.BUTTON_PRIMARY, "Continue", UiSizes.BUTTON_TALL)
	button.name = "Continue"
	button.pressed.connect(func() -> void: app.goto(AppService.PLAY))
	return button
