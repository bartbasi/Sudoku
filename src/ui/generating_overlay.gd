extends Container
## Shown over the current screen while a new puzzle is being made on the
## worker thread (GENERATION_TIMING.md: "a short 'making your puzzle'
## moment"). A scrim that takes every tap, and a DIALOG card with one line.
## No class_name: App preloads it.
## Owner: ui-systems-dev.

const TEXT: String = "Making your puzzle."

var _scrim: Panel = null
var _card: PanelContainer = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim = Panel.new()
	_scrim.theme_type_variation = ThemeFactory.SCRIM
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_scrim)
	_card = UiKit.panel(ThemeFactory.DIALOG)
	var line: Label = UiKit.label(ThemeFactory.BODY, TEXT)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.add_child(line)
	add_child(_card)
	Motion.appear(_scrim)


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN or _card == null:
		return
	fit_child_in_rect(_scrim, Rect2(Vector2.ZERO, size))
	var safe: Rect2 = UiKit.safe_rect_local(self)
	var card_size: Vector2 = _card.get_combined_minimum_size()
	card_size.x = minf(maxf(card_size.x, safe.size.x * 0.5), UiSizes.DIALOG_MAX_W)
	fit_child_in_rect(_card, Rect2(safe.position + (safe.size - card_size) * 0.5, card_size))
