extends UiScreen
## The title screen (GDD 15.0, DESIGN_SYSTEM.md 7.15): every app start opens
## it. The main menu's wordmark and hero, then PLAY, MENU, INFO and ABOUT,
## then a smaller Buy me a coffee button. PLAY goes straight into a puzzle
## (App.play_now); MENU opens the main menu (App.goto(MAIN_MENU)); INFO and
## ABOUT open their screens over this one. Buy me a coffee hands the support
## page to the phone's web browser (App.open_support_page); the game itself
## sends nothing. Back here closes the app (App.go_back). Every button does
## nothing while a puzzle is being made.
##
## Side by side (4.11) the wordmark and hero take the left half and the four
## buttons the right half, centered, as on the main menu. The right half has
## no room left at the smallest height, so there Buy me a coffee moves to
## the bottom of the left half, under the hero. The hero has space_l above
## and below it here, not space_xl, to make room for the fifth button.
## Owner: ui-systems-dev.

const MainMenu := preload("res://src/ui/main_menu.gd")

var play_button: Button = null
var menu_button: Button = null
var info_button: Button = null
var about_button: Button = null
## The face of Buy me a coffee; coffee_touch is its 48 dp touch area.
var coffee_button: Button = null
var coffee_touch: Control = null
## Wordmark and hero first, the buttons second (DESIGN_SYSTEM.md 4.11).
var halves: HalvesBox = null


func build() -> void:
	var s: GameSkin = skin()
	halves = MainMenu.halves_box(s)
	column.add_child(halves)
	var brand: VBoxContainer = MainMenu.brand(s)
	halves.add_child(brand)
	# space_l above and below the hero, not the main menu's space_xl, so the
	# hero keeps its 64 dp minimum over five buttons at 320 by 507.
	(brand.get_node(^"Hero") as HeroIcon).gap = s.space_l
	var second: VBoxContainer = UiKit.vbox(0.0)
	second.name = "Second"
	second.alignment = BoxContainer.ALIGNMENT_CENTER
	halves.add_child(second)
	var buttons: VBoxContainer = UiKit.vbox(s.space_m)
	buttons.name = "Buttons"
	second.add_child(UiKit.with_shadow_room(buttons, s))
	play_button = UiKit.button(ThemeFactory.BUTTON_PRIMARY, "Play", Layout.BUTTON_TALL)
	play_button.name = "Play"
	play_button.pressed.connect(_on_play)
	buttons.add_child(play_button)
	menu_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Menu", Layout.BUTTON_TALL)
	menu_button.name = "Menu"
	menu_button.pressed.connect(func() -> void: _open(AppService.MAIN_MENU))
	buttons.add_child(menu_button)
	info_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Info", Layout.BUTTON_TALL)
	info_button.name = "Info"
	info_button.pressed.connect(func() -> void: _open(AppService.INFO))
	buttons.add_child(info_button)
	about_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "About", Layout.BUTTON_TALL)
	about_button.name = "About"
	about_button.pressed.connect(func() -> void: _open(AppService.ABOUT))
	buttons.add_child(about_button)
	# Under ABOUT's shadow room: a 40 dp face in a 48 dp touch area, only as
	# wide as its label, so it reads as smaller than the four above.
	var coffee: UiKit.TouchTarget = UiKit.coffee_button()
	coffee_touch = coffee
	coffee_button = coffee.button
	coffee_button.pressed.connect(_on_coffee)
	second.add_child(coffee)
	halves.arranged.connect(_on_arranged)


func _on_play() -> void:
	if app != null:
		app.play_now()


func _on_coffee() -> void:
	if app != null and not app.is_generating():
		app.open_support_page()


## Stacked, Buy me a coffee sits under ABOUT; side by side, under the hero.
func _on_arranged(side: bool) -> void:
	MainMenu.move_to_half(halves, coffee_touch, side)


func _open(screen: StringName) -> void:
	if app != null and not app.is_generating():
		app.goto(screen)
