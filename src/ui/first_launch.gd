extends UiScreen
## The first launch offer (GDD 15.3, DESIGN_SYSTEM.md 7.2): the wordmark and
## the hero as on the main menu, then a card with the offer and two buttons.
## Either answer is final. Closing the app before answering shows it again.
## Owner: ui-systems-dev.

const MainMenu := preload("res://src/ui/main_menu.gd")
const OFFER: String = "New to Sudoku? Lesson 1 shows you how to play."

var start_button: Button = null
var skip_button: Button = null


func build() -> void:
	var s: GameSkin = skin()
	var stack: VBoxContainer = UiKit.vbox(0.0)
	column.add_child(stack)
	stack.add_child(MainMenu.wordmark(s))
	var hero: HeroIcon = HeroIcon.new()
	hero.name = "Hero"
	hero.gap = s.space_xl
	stack.add_child(hero)
	var card: PanelContainer = UiKit.panel(ThemeFactory.CARD)
	card.name = "Offer"
	stack.add_child(card)
	var inside: VBoxContainer = UiKit.vbox(s.space_m)
	card.add_child(inside)
	inside.add_child(UiKit.label(ThemeFactory.BODY, OFFER, true))
	start_button = UiKit.button(ThemeFactory.BUTTON_PRIMARY, "Start lesson", UiSizes.BUTTON_TALL)
	start_button.name = "StartLesson"
	start_button.pressed.connect(_on_start)
	inside.add_child(start_button)
	skip_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Skip", UiSizes.BUTTON_TALL)
	skip_button.name = "Skip"
	skip_button.pressed.connect(_on_skip)
	inside.add_child(skip_button)
	var shadow_room: Control = Control.new()
	shadow_room.custom_minimum_size.y = s.shadow_offset
	stack.add_child(shadow_room)


func _on_start() -> void:
	app.answer_first_launch()
	app.open_first_lesson()


func _on_skip() -> void:
	app.answer_first_launch()
	app.goto(AppService.MAIN_MENU)
