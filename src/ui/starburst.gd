class_name Starburst
extends Control
## The starburst behind SOLVED! on the completion screen (DESIGN_SYSTEM.md
## 7.9): a star in the CARD colors (surface_bg face, the outline, the hard
## shadow), as large as fits, drawn in code. The child sticker sits on it.
## Owner: ui-systems-dev.

const POINTS: int = 12
## Inner radius as a share of the outer radius.
const INNER: float = 0.72


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	resized.connect(queue_redraw)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()


func _draw() -> void:
	var skin: GameSkin = UiKit.skin_of(self)
	var radius: float = minf(size.x, size.y) * 0.5 - skin.shadow_offset - skin.outline_w
	if radius <= 0.0:
		return
	var center: Vector2 = size * 0.5
	var star: PackedVector2Array = star_points(center, radius)
	var offset: Vector2 = Vector2(skin.shadow_offset, skin.shadow_offset)
	var shadow: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in star:
		shadow.append(p + offset)
	draw_colored_polygon(shadow, skin.shadow)
	draw_colored_polygon(star, skin.surface_bg)
	var outline: PackedVector2Array = star.duplicate()
	outline.append(star[0])
	draw_polyline(outline, skin.outline, skin.outline_w, true)


static func star_points(center: Vector2, radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in POINTS * 2:
		var r: float = radius if i % 2 == 0 else radius * INNER
		var angle: float = TAU * float(i) / float(POINTS * 2) - PI * 0.5
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	return points
