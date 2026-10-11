extends Control
## Draws one code-drawn icon over its whole rect. See icons.gd.
## Prototype code in tools/, never shipped. Owner: ui-motion-artist.

const Icons := preload("res://tools/design/directions/ui/common/icons.gd")

var kind: String = ""
var color: Color = Color.BLACK
var stroke: float = 0.1 ## Stroke as a share of the icon's side.
var round_caps: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	Icons.draw(self, kind, Rect2(Vector2.ZERO, size), color, stroke, round_caps)
