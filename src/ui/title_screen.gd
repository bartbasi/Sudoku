extends UiScreen
## The title screen (GDD 15.0, DESIGN_SYSTEM.md 7.15): every app start opens
## it. The main menu's wordmark and hero, then PLAY, INFO and ABOUT. PLAY
## goes straight into a puzzle (App.play_now); INFO and ABOUT open their
## screens over this one. Back here closes the app (App.go_back). Side by
## side (4.11) the wordmark and hero take the left half and the buttons the
## right half, centered, as on the main menu.
## Owner: ui-systems-dev.

const MainMenu := preload("res://src/ui/main_menu.gd")

var play_button: Button = null
var info_button: Button = null
var about_button: Button = null
## Wordmark and hero first, the buttons second (DESIGN_SYSTEM.md 4.11).
var halves: HalvesBox = null


func build() -> void:
	var s: GameSkin = skin()
	halves = MainMenu.halves_box(s)
	column.add_child(halves)
	halves.add_child(MainMenu.brand(s))
	var buttons: VBoxContainer = UiKit.vbox(s.space_m)
	buttons.name = "Buttons"
	halves.add_child(UiKit.with_shadow_room(buttons, s))
	play_button = UiKit.button(ThemeFactory.BUTTON_PRIMARY, "Play", Layout.BUTTON_TALL)
	play_button.name = "Play"
	play_button.pressed.connect(_on_play)
	buttons.add_child(play_button)
	info_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Info", Layout.BUTTON_TALL)
	info_button.name = "Info"
	info_button.pressed.connect(func() -> void: _open(AppService.INFO))
	buttons.add_child(info_button)
	about_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "About", Layout.BUTTON_TALL)
	about_button.name = "About"
	about_button.pressed.connect(func() -> void: _open(AppService.ABOUT))
	buttons.add_child(about_button)


func _on_play() -> void:
	if app != null:
		app.play_now()


func _open(screen: StringName) -> void:
	if app != null and not app.is_generating():
		app.goto(screen)
