class_name Icons extends RefCounted
## The game's icons, drawn in code (ARCHITECTURE section 7, DESIGN_SYSTEM.md
## section 4.1). Each is one color and reads by its shape alone. Strokes are
## 0.14 of the icon side with square ends and mitered corners. Every shape is
## built from polygons at draw time, so icons stay crisp at any size. No
## image files, no icon fonts.
## Owner: ui-motion-artist.

const UNDO: StringName = &"undo"
const ERASE: StringName = &"erase"
const MODE_PLACE: StringName = &"mode_place"
const MODE_CROSS_OUT: StringName = &"mode_cross_out"
const HINT: StringName = &"hint"
const PAUSE: StringName = &"pause"
const PLAY: StringName = &"play"
const SETTINGS: StringName = &"settings"
const BACK: StringName = &"back"
const CLOSE: StringName = &"close"
const CHECK: StringName = &"check"
const LOCK: StringName = &"lock"

const ALL: Array[StringName] = [
	UNDO, ERASE, MODE_PLACE, MODE_CROSS_OUT, HINT, PAUSE, PLAY, SETTINGS, BACK, CLOSE, CHECK, LOCK,
]

## Stroke weight as a share of the icon side.
const STROKE: float = 0.14
## Icon side inside buttons, dp.
const SIZE_BUTTON: float = 20.0
## Icon side inside icon buttons, dp.
const SIZE_ICON_BUTTON: float = 24.0

## Longest miter spike, as a multiple of half the stroke.
const _MITER_LIMIT: float = 2.5
## Width of the antialiased line run along each edge to smooth it, dp.
const _EDGE_SMOOTH: float = 0.5

const IconTexture := preload("res://src/design/icon_texture.gd")

const _OPEN: int = 0
const _CLOSED: int = 1
const _FILL: int = 2


## One shape of an icon in the unit square: a stroked line (open or closed)
## or a filled convex polygon.
class Part extends RefCounted:
	var kind: int
	var points: PackedVector2Array

	func _init(p_kind: int, p_points: PackedVector2Array) -> void:
		kind = p_kind
		points = p_points


static func has_icon(icon: StringName) -> bool:
	return ALL.has(icon)


## The icon as a Texture2D of side dp, drawn in code, for a Button's icon
## property. The Button tints it with the theme's icon colors for each state.
static func texture(icon: StringName, side: float = SIZE_BUTTON) -> Texture2D:
	return IconTexture.new(icon, side)


## Draws icon centered in rect (in the largest square that fits) in color.
## Call from inside canvas's _draw().
static func draw(canvas: CanvasItem, icon: StringName, rect: Rect2, color: Color) -> void:
	draw_rid(canvas.get_canvas_item(), icon, rect, color)


## The same, onto a canvas item RID (for StyleBox and Texture2D drawing).
static func draw_rid(item: RID, icon: StringName, rect: Rect2, color: Color) -> void:
	for shape: PackedVector2Array in polygons(icon, rect):
		if shape.size() < 3:
			continue
		var indices: PackedInt32Array = PackedInt32Array()
		for i: int in range(1, shape.size() - 1):
			indices.append_array([0, i, i + 1])
		RenderingServer.canvas_item_add_triangle_array(item, indices, shape, PackedColorArray([color]))
		var ring: PackedVector2Array = shape.duplicate()
		ring.append(shape[0])
		RenderingServer.canvas_item_add_polyline(item, ring, PackedColorArray([color]), _EDGE_SMOOTH, true)


## Every convex polygon the icon fills, in rect's coordinates. Empty for an
## unknown icon.
static func polygons(icon: StringName, rect: Rect2) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	if not has_icon(icon):
		push_warning("Unknown icon: %s" % icon)
		return result
	var side: float = minf(rect.size.x, rect.size.y)
	if side <= 0.0:
		return result
	var origin: Vector2 = rect.get_center() - Vector2(side, side) * 0.5
	var half: float = STROKE * side * 0.5
	for part: Part in _parts(icon):
		var points: PackedVector2Array = PackedVector2Array()
		for unit: Vector2 in part.points:
			points.append(origin + unit * side)
		if part.kind == _FILL:
			result.append(points)
		else:
			result.append_array(_stroke(points, half, part.kind == _CLOSED))
	return result


# Shapes, in the unit square, y down.

static func _parts(icon: StringName) -> Array[Part]:
	var parts: Array[Part] = []
	match icon:
		UNDO:
			# A U-turn: along the bottom, round the right, back along the top
			# to an arrowhead pointing left.
			var path: PackedVector2Array = PackedVector2Array([Vector2(0.30, 0.78)])
			path.append_array(_arc(Vector2(0.58, 0.58), 0.20, PI * 0.5, -PI * 0.5, 16))
			path.append(Vector2(0.24, 0.38))
			parts.append(Part.new(_OPEN, path))
			parts.append(Part.new(_OPEN, PackedVector2Array([Vector2(0.38, 0.22), Vector2(0.22, 0.38), Vector2(0.38, 0.54)])))
		ERASE:
			# An eraser on its side, its lower end filled, over the line it rubs.
			var c: Vector2 = Vector2(0.5, 0.46)
			var along: Vector2 = Vector2(0.7071, -0.7071) * 0.29
			var across: Vector2 = Vector2(0.7071, 0.7071) * 0.15
			var split: Vector2 = c - along * 0.15
			parts.append(Part.new(_FILL, PackedVector2Array([split - across, split + across, c - along + across, c - along - across])))
			parts.append(Part.new(_CLOSED, PackedVector2Array([c + along - across, c + along + across, c - along + across, c - along - across])))
			parts.append(Part.new(_OPEN, PackedVector2Array([Vector2(0.46, 0.86), Vector2(0.84, 0.86)])))
		MODE_PLACE:
			# A pencil, its point at the lower left.
			var tip: Vector2 = Vector2(0.18, 0.82)
			var axis: Vector2 = Vector2(0.7071, -0.7071)
			var normal: Vector2 = Vector2(0.7071, 0.7071) * 0.12
			var neck: Vector2 = tip + axis * 0.24
			var end: Vector2 = tip + axis * 0.86
			parts.append(Part.new(_CLOSED, PackedVector2Array([tip, neck - normal, end - normal, end + normal, neck + normal])))
			parts.append(Part.new(_OPEN, PackedVector2Array([neck + normal, neck - normal])))
			var band: Vector2 = tip + axis * 0.68
			parts.append(Part.new(_OPEN, PackedVector2Array([band + normal, band - normal])))
		MODE_CROSS_OUT:
			# A box with an X in it, like a crossed candidate.
			parts.append(Part.new(_CLOSED, PackedVector2Array([Vector2(0.18, 0.18), Vector2(0.82, 0.18), Vector2(0.82, 0.82), Vector2(0.18, 0.82)])))
			parts.append(Part.new(_OPEN, PackedVector2Array([Vector2(0.38, 0.38), Vector2(0.62, 0.62)])))
			parts.append(Part.new(_OPEN, PackedVector2Array([Vector2(0.62, 0.38), Vector2(0.38, 0.62)])))
		HINT:
			# A bulb: the glass narrows into a neck, then two base lines.
			var glass: PackedVector2Array = PackedVector2Array([Vector2(0.41, 0.64)])
			glass.append_array(_arc(Vector2(0.5, 0.38), 0.23, deg_to_rad(130.0), deg_to_rad(410.0), 24))
			glass.append(Vector2(0.59, 0.64))
			parts.append(Part.new(_OPEN, glass))
			parts.append(Part.new(_OPEN, PackedVector2Array([Vector2(0.38, 0.70), Vector2(0.62, 0.70)])))
			parts.append(Part.new(_OPEN, PackedVector2Array([Vector2(0.43, 0.84), Vector2(0.57, 0.84)])))
		PAUSE:
			parts.append(Part.new(_FILL, _box(Vector2(0.24, 0.20), Vector2(0.42, 0.80))))
			parts.append(Part.new(_FILL, _box(Vector2(0.58, 0.20), Vector2(0.76, 0.80))))
		PLAY:
			parts.append(Part.new(_FILL, PackedVector2Array([Vector2(0.28, 0.18), Vector2(0.84, 0.5), Vector2(0.28, 0.82)])))
		SETTINGS:
			# A gear: a ring with eight square teeth.
			var ring: PackedVector2Array = _arc(Vector2(0.5, 0.5), 0.20, 0.0, TAU, 32)
			ring.remove_at(ring.size() - 1)
			parts.append(Part.new(_CLOSED, ring))
			for k: int in 8:
				var dir: Vector2 = Vector2.from_angle(TAU * float(k) / 8.0)
				parts.append(Part.new(_OPEN, PackedVector2Array([Vector2(0.5, 0.5) + dir * 0.29, Vector2(0.5, 0.5) + dir * 0.37])))
		BACK:
			parts.append(Part.new(_OPEN, PackedVector2Array([Vector2(0.80, 0.5), Vector2(0.26, 0.5)])))
			parts.append(Part.new(_OPEN, PackedVector2Array([Vector2(0.48, 0.26), Vector2(0.24, 0.5), Vector2(0.48, 0.74)])))
		CLOSE:
			parts.append(Part.new(_OPEN, PackedVector2Array([Vector2(0.26, 0.26), Vector2(0.74, 0.74)])))
			parts.append(Part.new(_OPEN, PackedVector2Array([Vector2(0.74, 0.26), Vector2(0.26, 0.74)])))
		CHECK:
			parts.append(Part.new(_OPEN, PackedVector2Array([Vector2(0.18, 0.52), Vector2(0.40, 0.74), Vector2(0.84, 0.30)])))
		LOCK:
			# A padlock: a filled body under an arched shackle.
			var shackle: PackedVector2Array = PackedVector2Array([Vector2(0.32, 0.48)])
			shackle.append_array(_arc(Vector2(0.5, 0.36), 0.18, PI, TAU, 16))
			shackle.append(Vector2(0.68, 0.48))
			parts.append(Part.new(_OPEN, shackle))
			parts.append(Part.new(_FILL, _box(Vector2(0.18, 0.46), Vector2(0.82, 0.88))))
	return parts


static func _arc(center: Vector2, radius: float, from_angle: float, to_angle: float, steps: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in steps + 1:
		var a: float = lerpf(from_angle, to_angle, float(i) / float(steps))
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	return points


static func _box(top_left: Vector2, bottom_right: Vector2) -> PackedVector2Array:
	return PackedVector2Array([top_left, Vector2(bottom_right.x, top_left.y), bottom_right, Vector2(top_left.x, bottom_right.y)])


## A line of width 2 * half through points as one quad per segment, with
## mitered corners and square ends.
static func _stroke(points: PackedVector2Array, half: float, closed: bool) -> Array[PackedVector2Array]:
	var count: int = points.size()
	var quads: Array[PackedVector2Array] = []
	if count < 2:
		return quads
	var left: PackedVector2Array = PackedVector2Array()
	var right: PackedVector2Array = PackedVector2Array()
	for i: int in count:
		var p: Vector2 = points[i]
		var has_prev: bool = closed or i > 0
		var has_next: bool = closed or i < count - 1
		var d_in: Vector2 = (p - points[(i - 1 + count) % count]).normalized() if has_prev else Vector2.ZERO
		var d_out: Vector2 = (points[(i + 1) % count] - p).normalized() if has_next else Vector2.ZERO
		if not has_prev:
			# Square start: run back by half a stroke.
			var n_start: Vector2 = Vector2(-d_out.y, d_out.x)
			p -= d_out * half
			left.append(p + n_start * half)
			right.append(p - n_start * half)
		elif not has_next:
			var n_end: Vector2 = Vector2(-d_in.y, d_in.x)
			p += d_in * half
			left.append(p + n_end * half)
			right.append(p - n_end * half)
		else:
			var n_in: Vector2 = Vector2(-d_in.y, d_in.x)
			var n_out: Vector2 = Vector2(-d_out.y, d_out.x)
			var miter: Vector2 = (n_in + n_out).normalized()
			if miter == Vector2.ZERO:
				miter = n_in
			var reach: float = half / maxf(miter.dot(n_in), 1.0 / _MITER_LIMIT)
			left.append(p + miter * reach)
			right.append(p - miter * reach)
	var segments: int = count if closed else count - 1
	for i: int in segments:
		var j: int = (i + 1) % count
		quads.append(PackedVector2Array([left[i], left[j], right[j], right[i]]))
	return quads
