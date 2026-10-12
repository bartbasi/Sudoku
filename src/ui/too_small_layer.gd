class_name TooSmallLayer
extends Container
## The too small message (GDD 8.1, DESIGN_SYSTEM.md 4.11): a full screen
## layer in PAGE over every screen while the window is too small to play.
## Centered in the safe area: the hero in a HERO_BOX box when the content box
## is at least HERO_MIN_CONTENT tall (hidden below that), and under it the
## message in BODY, centered and wrapped. It takes every tap and nothing on it
## can be tapped, so a tap changes nothing underneath and plays no sound.
## App adds it on top of the host and removes it when the window grows back.
## Owner: ui-systems-dev.

const TEXT: String = "This window is too small. Make it bigger to play."
## The hero's box (4.11).
const HERO_BOX: float = 64.0
## The hero shows only when the content box is at least this tall (4.11).
const HERO_MIN_CONTENT: float = 160.0

## The skin in use. App sets it before the layer enters the tree.
var skin: GameSkin = null

var page: Panel = null
var hero: HeroIcon = null
var message: Label = null
var _stack: VBoxContainer = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	ensure_built()


## Builds the page, the hero and the message, once.
func ensure_built() -> void:
	if page != null:
		return
	if skin == null:
		skin = UiKit.skin_of(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page = Panel.new()
	page.name = "Page"
	page.theme_type_variation = ThemeFactory.PAGE
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page)
	_stack = UiKit.vbox(skin.space_m)
	_stack.name = "Stack"
	_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_stack)
	hero = HeroIcon.new()
	hero.name = "Hero"
	hero.gap = 0.0
	hero.custom_minimum_size = Vector2(HERO_BOX, HERO_BOX)
	hero.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hero.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_stack.add_child(hero)
	message = UiKit.label(ThemeFactory.BODY, TEXT, true)
	message.name = "Message"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stack.add_child(message)


## Every tap ends here: nothing under the layer sees it.
func _gui_input(_event: InputEvent) -> void:
	accept_event()


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN or page == null:
		return
	fit_child_in_rect(page, Rect2(Vector2.ZERO, size))
	var content: Rect2 = UiKit.safe_rect_local(self).grow(-skin.page_margin)
	content.size = content.size.max(Vector2.ZERO)
	hero.visible = content.size.y >= HERO_MIN_CONTENT
	fit_child_in_rect(_stack, content)
