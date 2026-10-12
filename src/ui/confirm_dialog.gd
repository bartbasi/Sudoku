class_name ConfirmDialog
extends Container
## A question with two answers over a scrim (DESIGN_SYSTEM.md 4.9, 7.4 and
## 7.11): the new puzzle confirm and the Reset Stats confirm. A DIALOG card,
## centered in the safe area, at most UiSizes.DIALOG_MAX_W wide and at least
## space_l from its sides. The body text, then two full width buttons: the
## safe answer (BUTTON_SECONDARY) on top and the confirming one below.
## Back and a tap on the scrim mean the safe answer.
## Owner: ui-systems-dev.

signal confirmed()
signal cancelled()

var scrim: Panel = null
var card: PanelContainer = null
var body: Label = null
var cancel_button: Button = null
var confirm_button: Button = null
var _side: float = 16.0


## skin gives the spacing. confirm_variation is BUTTON_DANGER for both
## dialogs in v1.
func setup(skin: GameSkin, text: String, cancel_text: String, confirm_text: String, confirm_variation: StringName) -> void:
	_side = skin.space_l
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
	body = UiKit.label(ThemeFactory.BODY, text, true)
	stack.add_child(body)
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
	var width: float = minf(UiSizes.DIALOG_MAX_W, safe.size.x - 2.0 * _side)
	card.size = Vector2(width, 0.0)
	var height: float = card.get_combined_minimum_size().y
	var at: Vector2 = safe.position + (safe.size - Vector2(width, height)) * 0.5
	fit_child_in_rect(card, Rect2(at, Vector2(width, height)))
