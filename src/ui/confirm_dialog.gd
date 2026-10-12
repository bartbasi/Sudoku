class_name ConfirmDialog
extends Container
## A question with two answers over a scrim (DESIGN_SYSTEM.md 4.9, 7.4 and
## 7.11): the new puzzle confirm and the Reset Stats confirm. A DIALOG card,
## centered in the safe area, at most UiSizes.DIALOG_MAX_W wide and at least
## space_l from its sides. The body text, then two full width buttons: the
## safe answer (BUTTON_SECONDARY) on top and the confirming one below.
## Back and a tap on the scrim mean the safe answer.
##
## The card is never taller than the content box (the safe area less
## page_margin on every side, DESIGN_SYSTEM.md 4.11): when the text would
## make it taller, the text scrolls and the buttons stay in view.
## Owner: ui-systems-dev.

signal confirmed()
signal cancelled()

var scrim: Panel = null
var card: PanelContainer = null
var body: Label = null
## Holds body. As tall as the text, or less when the card is capped.
var body_scroll: ScrollContainer = null
var cancel_button: Button = null
var confirm_button: Button = null
var _side: float = 16.0
var _margin: float = 8.0


## skin gives the spacing. confirm_variation is BUTTON_DANGER for both
## dialogs in v1.
func setup(skin: GameSkin, text: String, cancel_text: String, confirm_text: String, confirm_variation: StringName) -> void:
	_side = skin.space_l
	_margin = skin.page_margin
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	scrim = Panel.new()
	scrim.theme_type_variation = ThemeFactory.SCRIM
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.gui_input.connect(_on_scrim_input)
	add_child(scrim)
	card = UiKit.panel(ThemeFactory.DIALOG)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(card)
	var stack: VBoxContainer = UiKit.vbox(skin.space_m)
	card.add_child(stack)
	body_scroll = ScrollContainer.new()
	body_scroll.name = "BodyScroll"
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	stack.add_child(body_scroll)
	body = UiKit.label(ThemeFactory.BODY, text, true)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.add_child(body)
	stack.add_child(Control.new())
	cancel_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, cancel_text, UiSizes.BUTTON_DIALOG)
	cancel_button.name = "Cancel"
	cancel_button.pressed.connect(cancel)
	stack.add_child(cancel_button)
	confirm_button = UiKit.button(confirm_variation, confirm_text, UiSizes.BUTTON_DIALOG)
	confirm_button.name = "Confirm"
	confirm_button.pressed.connect(_on_confirm)
	stack.add_child(confirm_button)
	visible = false


func show_dialog() -> void:
	visible = true
	queue_sort()
	Motion.appear(scrim)
	Motion.appear(card)


func is_open() -> bool:
	return visible


## The safe answer: closes and emits cancelled.
func cancel() -> void:
	if not visible:
		return
	visible = false
	cancelled.emit()


func _on_confirm() -> void:
	if not visible:
		return
	visible = false
	confirmed.emit()


func _on_scrim_input(event: InputEvent) -> void:
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse != null and mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed:
		cancel()


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN or card == null:
		return
	fit_child_in_rect(scrim, Rect2(Vector2.ZERO, size))
	var safe: Rect2 = UiKit.safe_rect_local(self)
	var width: float = maxf(0.0, minf(UiSizes.DIALOG_MAX_W, safe.size.x - 2.0 * _side))
	var height: float = fit_height(width, maxf(0.0, safe.size.y - 2.0 * _margin))
	var at: Vector2 = safe.position + (safe.size - Vector2(width, height)) * 0.5
	fit_child_in_rect(card, Rect2(at, Vector2(width, height)))


## Sizes the text's scroll area for a card width wide and at most max_height
## tall, and returns the card's height: what the text needs, or max_height
## when that is less (never less than the card without any text).
func fit_height(width: float, max_height: float) -> float:
	# The scroll area measures only its own minimum height, so the card
	# without the text is the card's minimum less that.
	var without_text: float = card.get_combined_minimum_size().y - body_scroll.custom_minimum_size.y
	var inner: float = width - card.get_theme_stylebox(&"panel").get_minimum_size().x
	if not is_equal_approx(body.size.x, maxf(1.0, inner)):
		body.size = Vector2(maxf(1.0, inner), body.size.y)
	var text_h: float = body.get_combined_minimum_size().y
	var height: float = minf(without_text + text_h, maxf(without_text, max_height))
	# Only a real change re-measures the card, so sorting settles.
	if not is_equal_approx(body_scroll.custom_minimum_size.y, height - without_text):
		body_scroll.custom_minimum_size.y = height - without_text
	return height


## True when the text does not fit and scrolls.
func is_capped() -> bool:
	return body_scroll.custom_minimum_size.y + 0.5 < body.get_combined_minimum_size().y
