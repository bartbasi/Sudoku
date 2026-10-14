extends UiScreen
## The first launch offer (GDD 15.3, DESIGN_SYSTEM.md 7.2): the wordmark and
## the hero as on the main menu, then a card with the offer and two buttons.
## Side by side (4.11) the card takes the right half, centered.
## It goes over the title screen on PLAY while unanswered (GDD 15.3). Either
## answer is final. Back returns to the title screen without answering, and
## closing the app before answering shows it again on the next PLAY.
## Owner: ui-systems-dev.

const MainMenu := preload("res://src/ui/main_menu.gd")
const OFFER: String = "New to Sudoku? Lesson 1 shows you how to play."

var start_button: Button = null
var skip_button: Button = null
## Wordmark and hero first, the offer card second (DESIGN_SYSTEM.md 4.11).
var halves: HalvesBox = null


func build() -> void:
	var s: GameSkin = skin()
	halves = MainMenu.halves_box(s)
	column.add_child(halves)
	halves.add_child(MainMenu.brand(s))
	var stack: VBoxContainer = UiKit.vbox(0.0)
	stack.name = "OfferStack"
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	halves.add_child(stack)
	var card: PanelContainer = UiKit.panel(ThemeFactory.CARD)
	card.name = "Offer"
	stack.add_child(card)
	var inside: VBoxContainer = UiKit.vbox(s.space_m)
	card.add_child(inside)
	inside.add_child(UiKit.label(ThemeFactory.BODY, OFFER, true))
	start_button = UiKit.button(ThemeFactory.BUTTON_PRIMARY, "Start lesson", Layout.BUTTON_TALL)
	start_button.name = "StartLesson"
	start_button.pressed.connect(_on_start)
	inside.add_child(start_button)
	skip_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Skip", Layout.BUTTON_TALL)
	skip_button.name = "Skip"
	skip_button.pressed.connect(_on_skip)
	inside.add_child(skip_button)
	var shadow_room: Control = Control.new()
	shadow_room.custom_minimum_size.y = s.shadow_offset
	stack.add_child(shadow_room)


func _on_start() -> void:
	app.answer_first_launch()
	app.open_first_lesson()


## Skip goes straight into a puzzle, as PLAY does once the offer is
## answered (GDD 15.3).
func _on_skip() -> void:
	app.answer_first_launch()
	app.play_now()
