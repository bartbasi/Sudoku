class_name HalvesBox
extends Container
## Two parts of a menu or full screen overlay, placed by the window's
## arrangement (DESIGN_SYSTEM.md 4.9 and 4.11). The first child is the first
## part and the second child the second; other children are ignored.
##
## Stacked: one column, the first part above the second. FILL_FIRST gives
## the second part its minimum height at the bottom and the first part the
## rest (main menu, first launch offer, completion); CENTER puts both at
## their minimum heights, centered as a group (pause menu).
##
## Side by side: two halves of the column, side_gap apart, each the full
## height: the first part at the left, the second at the right. Each part
## centers or spreads its own content.
## Owner: ui-systems-dev.

## Emitted when the box switches between stacked and side by side, before it
## lays out, so a screen can change how a part measures itself.
signal arranged(side: bool)

enum Stacked { FILL_FIRST, CENTER }

var stacked_mode: int = Stacked.FILL_FIRST
## The gap between the parts when stacked.
var stacked_gap: float = 0.0
## The gap between the halves when side by side (space_xl).
var side_gap: float = 24.0
## The skin whose sizes the arrangement rule uses. The screen sets it.
var skin: GameSkin = null

var _side: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## True while the parts sit side by side.
func is_side() -> bool:
	return _side


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN:
		return
	var first: Control = _part(0)
	var second: Control = _part(1)
	if first == null or second == null:
		return
	var side: bool = skin != null and UiKit.arrangement_of(self, skin) == Layout.Arrangement.SIDE
	if side != _side:
		_side = side
		arranged.emit(side)
	if _side:
		var half: float = maxf(0.0, (size.x - side_gap) * 0.5)
		fit_child_in_rect(first, Rect2(0.0, 0.0, half, size.y))
		fit_child_in_rect(second, Rect2(half + side_gap, 0.0, half, size.y))
		return
	var second_h: float = second.get_combined_minimum_size().y
	if stacked_mode == Stacked.CENTER:
		var first_h: float = first.get_combined_minimum_size().y
		var top: float = maxf(0.0, (size.y - first_h - stacked_gap - second_h) * 0.5)
		fit_child_in_rect(first, Rect2(0.0, top, size.x, first_h))
		fit_child_in_rect(second, Rect2(0.0, top + first_h + stacked_gap, size.x, second_h))
		return
	var first_rest: float = maxf(0.0, size.y - second_h - stacked_gap)
	fit_child_in_rect(first, Rect2(0.0, 0.0, size.x, first_rest))
	fit_child_in_rect(second, Rect2(0.0, size.y - second_h, size.x, second_h))


func _get_minimum_size() -> Vector2:
	return Vector2.ZERO


func _part(index: int) -> Control:
	if get_child_count() <= index:
		return null
	return get_child(index) as Control
