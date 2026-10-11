extends Control
## A panel, chip, key or button face drawn with StyleBoxFlat. The fill style
## carries a soft shadow when the direction has one; a hard offset shadow is
## drawn as a second box behind. Decoration can be drawn between the fill and
## the outline (under) or on top of everything (over).
## Prototype code in tools/, never shipped. Owner: ui-motion-artist.

var fill: StyleBoxFlat = null
var border: StyleBoxFlat = null ## Outline only, or null for none.
var hard_shadow: StyleBoxFlat = null ## Null for none.
var hard_offset: Vector2 = Vector2.ZERO
var under: Callable = Callable() ## func(block: Control) -> void
var over: Callable = Callable() ## func(block: Control) -> void


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	if hard_shadow != null:
		draw_style_box(hard_shadow, Rect2(hard_offset, size))
	if fill != null:
		draw_style_box(fill, rect)
	if under.is_valid():
		under.call(self)
	if border != null:
		draw_style_box(border, rect)
	if over.is_valid():
		over.call(self)
