extends StyleBox
## The face of every Pop card, button, key, sticker and tag (DESIGN_SYSTEM.md
## sections 4.1 and 4.2): a rounded face with an outline and a hard offset
## shadow, no blur. Extras drawn inside the outline: the disabled hatch, the
## Cross Out key stripe, the full board message bar and the selected skin
## badge. Built by ThemeFactory; screens never make one.
##
## press runs from 0 (raised) to 1 (sunk): the face moves shadow_offset right
## and down onto its shadow, and the content moves with it. Motion.press
## animates it on a copy of the box. The look properties are exported so
## duplicate() copies them.
## Owner: ui-motion-artist.


const CLEAR: Color = Color(0.0, 0.0, 0.0, 0.0)
## Segments per rounded corner of the clip shape.
const _CORNER_STEPS: int = 6

@export var face: Color = CLEAR
@export var outline: Color = CLEAR
@export var outline_w: float = 0.0
@export var radius: float = 0.0
@export var shadow: Color = CLEAR ## CLEAR means no shadow.
@export var shadow_offset: float = 0.0

@export var hatch: Color = CLEAR ## CLEAR means no hatch.
@export var hatch_w: float = 0.0
@export var hatch_gap: float = 0.0

@export var stripe: Color = CLEAR ## Cross Out key corner stripe; CLEAR means none.
## The stripe runs between these shares of the face width from the top right corner.
@export var stripe_near: float = 0.2
@export var stripe_far: float = 0.4

@export var bar: Color = CLEAR ## Bar along the left inside edge; CLEAR means none.
@export var bar_w: float = 0.0

@export var badge: Color = CLEAR ## Check badge at the bottom right; CLEAR means none.
@export var badge_icon: Color = CLEAR
@export var badge_side: float = 0.0
@export var badge_inset: float = 0.0
@export var badge_icon_side: float = 0.0

## Content padding when raised.
@export var pad_left: float = 0.0
@export var pad_top: float = 0.0
@export var pad_right: float = 0.0
@export var pad_bottom: float = 0.0

@export var press: float = 0.0:
	set(value):
		press = value
		_update_margins()
		emit_changed()

var _fill_box: StyleBoxFlat = null
var _edge_box: StyleBoxFlat = null
var _shadow_box: StyleBoxFlat = null


## Sets the padding and the content margins that follow press.
func set_padding(left: float, top: float, right: float, bottom: float) -> void:
	pad_left = left
	pad_top = top
	pad_right = right
	pad_bottom = bottom
	_update_margins()


## Call after changing any look property, so the cached boxes are rebuilt.
func refresh() -> void:
	_fill_box = null
	_edge_box = null
	_shadow_box = null
	_update_margins()
	emit_changed()


## The face rect for a control rect at the current press.
func face_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position + Vector2(shadow_offset, shadow_offset) * press, rect.size)


func _update_margins() -> void:
	var shift: float = shadow_offset * press
	content_margin_left = pad_left + shift
	content_margin_top = pad_top + shift
	content_margin_right = maxf(0.0, pad_right - shift)
	content_margin_bottom = maxf(0.0, pad_bottom - shift)


func _get_draw_rect(rect: Rect2) -> Rect2:
	var reach: float = shadow_offset + outline_w
	return rect.grow_individual(outline_w, outline_w, reach, reach)


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	_build_boxes()
	var face_at: Rect2 = face_rect(rect)
	if shadow.a > 0.0 and press < 1.0:
		_shadow_box.draw(to_canvas_item, Rect2(rect.position + Vector2(shadow_offset, shadow_offset), rect.size))
	if face.a > 0.0:
		_fill_box.draw(to_canvas_item, face_at)
	var inner: PackedVector2Array = PackedVector2Array()
	if hatch.a > 0.0 or stripe.a > 0.0 or bar.a > 0.0:
		inner = rounded_polygon(face_at.grow(-outline_w), maxf(0.0, radius - outline_w))
	if hatch.a > 0.0:
		_draw_hatch(to_canvas_item, face_at, inner)
	if stripe.a > 0.0:
		_draw_stripe(to_canvas_item, face_at, inner)
	if bar.a > 0.0:
		_draw_bar(to_canvas_item, face_at, inner)
	if outline.a > 0.0 and outline_w > 0.0:
		_edge_box.draw(to_canvas_item, face_at)
	if badge.a > 0.0:
		_draw_badge(to_canvas_item, face_at)


func _build_boxes() -> void:
	if _fill_box != null:
		return
	_fill_box = _flat(face, radius)
	_edge_box = _flat(CLEAR, radius)
	_edge_box.draw_center = false
	_edge_box.set_border_width_all(maxi(1, roundi(outline_w)))
	_edge_box.border_color = outline
	_shadow_box = _flat(shadow, radius)


static func _flat(color: Color, corner: float) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(roundi(corner))
	box.corner_detail = 8
	box.anti_aliasing = true
	return box


## A rounded rectangle as a polygon, for clipping.
static func rounded_polygon(rect: Rect2, corner: float) -> PackedVector2Array:
	var r: float = minf(corner, minf(rect.size.x, rect.size.y) * 0.5)
	var points: PackedVector2Array = PackedVector2Array()
	if r <= 0.0:
		return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var centers: Array[Vector2] = [
		Vector2(rect.end.x - r, rect.position.y + r),
		Vector2(rect.end.x - r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.position.y + r),
	]
	for c: int in 4:
		var start: float = -PI * 0.5 + PI * 0.5 * float(c)
		for i: int in _CORNER_STEPS + 1:
			var a: float = start + PI * 0.5 * float(i) / float(_CORNER_STEPS)
			points.append(centers[c] + Vector2(cos(a), sin(a)) * r)
	return points


## Diagonal lines rising at 45 degrees, hatch_gap apart center to center,
## clipped to the face inside its outline.
func _draw_hatch(item: RID, rect: Rect2, inner: PackedVector2Array) -> void:
	if hatch_gap <= 0.0 or inner.size() < 3:
		return
	var step: float = hatch_gap * sqrt(2.0)
	var low: float = rect.position.x + rect.position.y
	var high: float = rect.end.x + rect.end.y
	var c: float = low + step * 0.5
	while c < high:
		# The line x + y = c across the whole rect.
		var line: PackedVector2Array = PackedVector2Array([
			Vector2(c - rect.end.y, rect.end.y), Vector2(c - rect.position.y, rect.position.y),
		])
		for piece: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(line, inner):
			if piece.size() >= 2:
				RenderingServer.canvas_item_add_line(item, piece[0], piece[piece.size() - 1], hatch, hatch_w, true)
		c += step


func _draw_stripe(item: RID, rect: Rect2, inner: PackedVector2Array) -> void:
	var w: float = rect.size.x
	var corner: Vector2 = Vector2(rect.end.x, rect.position.y)
	var band: PackedVector2Array = PackedVector2Array([
		corner + Vector2(-w * stripe_far, 0.0), corner + Vector2(-w * stripe_near, 0.0),
		corner + Vector2(0.0, w * stripe_near), corner + Vector2(0.0, w * stripe_far),
	])
	for piece: PackedVector2Array in Geometry2D.intersect_polygons(band, inner):
		_fill(item, piece, stripe)


func _draw_bar(item: RID, rect: Rect2, inner: PackedVector2Array) -> void:
	var left: float = rect.position.x + outline_w
	var strip: PackedVector2Array = PackedVector2Array([
		Vector2(left, rect.position.y), Vector2(left + bar_w, rect.position.y),
		Vector2(left + bar_w, rect.end.y), Vector2(left, rect.end.y),
	])
	for piece: PackedVector2Array in Geometry2D.intersect_polygons(strip, inner):
		_fill(item, piece, bar)


func _draw_badge(item: RID, rect: Rect2) -> void:
	var at: Vector2 = rect.end - Vector2(badge_inset + badge_side, badge_inset + badge_side)
	var square: Rect2 = Rect2(at, Vector2(badge_side, badge_side))
	var box: StyleBoxFlat = _flat(badge, radius)
	box.set_border_width_all(maxi(1, roundi(outline_w)))
	box.border_color = outline
	box.draw(item, square)
	var icon_rect: Rect2 = Rect2(square.get_center() - Vector2(badge_icon_side, badge_icon_side) * 0.5, Vector2(badge_icon_side, badge_icon_side))
	Icons.draw_rid(item, Icons.CHECK, icon_rect, badge_icon)


static func _fill(item: RID, points: PackedVector2Array, color: Color) -> void:
	if points.size() < 3:
		return
	RenderingServer.canvas_item_add_polygon(item, points, PackedColorArray([color]))
