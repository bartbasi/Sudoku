extends RefCounted
## Icons drawn in code for the Phase 1 screens. Each is one color and reads by
## its shape alone, so it works without color. They are drawn in a square of
## any size, with lines, arcs and polygons, so they stay crisp.
##
## Kinds: pause, hint (a bulb), undo, erase (an eraser), place (a pencil),
## cross_out (a crossed box), back (an arrow), close, clock, star.
##
## stroke is the line weight as a share of the side. round_caps gives round
## line ends and joints (Pebble); otherwise ends are square and corners
## mitered (Gridline, Pop).
## Prototype code in tools/, never shipped. Owner: ui-motion-artist.

const PAUSE: String = "pause"
const HINT: String = "hint"
const UNDO: String = "undo"
const ERASE: String = "erase"
const PLACE: String = "place"
const CROSS_OUT: String = "cross_out"
const BACK: String = "back"
const CLOSE: String = "close"
const CLOCK: String = "clock"
const STAR: String = "star"

const KINDS: Array[String] = [PAUSE, HINT, UNDO, ERASE, PLACE, CROSS_OUT, BACK, CLOSE, CLOCK, STAR]


static func draw(canvas: CanvasItem, kind: String, rect: Rect2, color: Color, stroke: float, round_caps: bool) -> void:
	var side: float = minf(rect.size.x, rect.size.y)
	var origin: Vector2 = rect.get_center() - Vector2(side, side) * 0.5
	var w: float = maxf(1.5, side * stroke)
	var pen: Pen = Pen.new(canvas, origin, side, w, color, round_caps)
	match kind:
		PAUSE:
			var bar: float = maxf(w * 1.5, side * 0.15)
			for x: float in [0.35, 0.65]:
				pen.bar(Vector2(x, 0.24), Vector2(x, 0.76), bar)
		HINT:
			# Bulb: an open circle that narrows into a neck, then two base lines.
			var center: Vector2 = Vector2(0.5, 0.40)
			var radius: float = 0.25
			var start: float = deg_to_rad(140.0)
			var end: float = deg_to_rad(400.0)
			var glass: PackedVector2Array = PackedVector2Array()
			var steps: int = 24
			glass.append(Vector2(0.40, 0.66))
			for i: int in steps + 1:
				var a: float = lerpf(start, end, float(i) / float(steps))
				glass.append(center + Vector2(cos(a), sin(a)) * radius)
			glass.append(Vector2(0.60, 0.66))
			pen.line(glass, false)
			pen.line(PackedVector2Array([Vector2(0.38, 0.70), Vector2(0.62, 0.70)]), false)
			pen.line(PackedVector2Array([Vector2(0.42, 0.84), Vector2(0.58, 0.84)]), false)
		UNDO:
			# A U-turn arrow: shaft from the lower left, round the right, back
			# along the top to an arrowhead pointing left.
			var path: PackedVector2Array = PackedVector2Array([Vector2(0.34, 0.78), Vector2(0.58, 0.78)])
			var turn: Vector2 = Vector2(0.58, 0.58)
			var steps: int = 16
			for i: int in steps + 1:
				var a: float = lerpf(PI * 0.5, -PI * 0.5, float(i) / float(steps))
				path.append(turn + Vector2(cos(a), sin(a)) * 0.20)
			path.append(Vector2(0.20, 0.38))
			pen.line(path, false)
			pen.line(PackedVector2Array([Vector2(0.36, 0.22), Vector2(0.20, 0.38), Vector2(0.36, 0.54)]), false)
		ERASE:
			# An eraser on its side: the outline, the lower half filled, and the
			# surface it rubs on.
			var c: Vector2 = Vector2(0.5, 0.46)
			var along: Vector2 = Vector2(0.7071, -0.7071) * 0.31
			var across: Vector2 = Vector2(0.7071, 0.7071) * 0.16
			var outline: PackedVector2Array = PackedVector2Array([c + along - across, c + along + across, c - along + across, c - along - across])
			var split: Vector2 = c - along * 0.15
			var lower: PackedVector2Array = PackedVector2Array([split - across, split + across, c - along + across, c - along - across])
			pen.fill(lower)
			pen.line(outline, true)
			pen.line(PackedVector2Array([Vector2(0.44, 0.86), Vector2(0.84, 0.86)]), false)
		PLACE:
			# A pencil from the lower left (its point) to the upper right.
			var tip: Vector2 = Vector2(0.16, 0.84)
			var axis: Vector2 = Vector2(0.7071, -0.7071)
			var normal: Vector2 = Vector2(0.7071, 0.7071) * 0.13
			var length: float = 0.96
			var neck: Vector2 = tip + axis * 0.26
			var end: Vector2 = tip + axis * length
			pen.line(PackedVector2Array([tip, neck + normal, end + normal, end - normal, neck - normal]), true)
			pen.line(PackedVector2Array([neck + normal, neck - normal]), false)
			var band: Vector2 = tip + axis * 0.76
			pen.line(PackedVector2Array([band + normal, band - normal]), false)
		CROSS_OUT:
			# A box crossed out, like a candidate under an X.
			pen.line(PackedVector2Array([Vector2(0.16, 0.16), Vector2(0.84, 0.16), Vector2(0.84, 0.84), Vector2(0.16, 0.84)]), true)
			pen.line(PackedVector2Array([Vector2(0.34, 0.34), Vector2(0.66, 0.66)]), false)
			pen.line(PackedVector2Array([Vector2(0.66, 0.34), Vector2(0.34, 0.66)]), false)
		BACK:
			pen.line(PackedVector2Array([Vector2(0.80, 0.5), Vector2(0.22, 0.5)]), false)
			pen.line(PackedVector2Array([Vector2(0.46, 0.26), Vector2(0.22, 0.5), Vector2(0.46, 0.74)]), false)
		CLOSE:
			pen.line(PackedVector2Array([Vector2(0.24, 0.24), Vector2(0.76, 0.76)]), false)
			pen.line(PackedVector2Array([Vector2(0.76, 0.24), Vector2(0.24, 0.76)]), false)
		CLOCK:
			pen.circle(Vector2(0.5, 0.5), 0.36)
			pen.line(PackedVector2Array([Vector2(0.5, 0.28), Vector2(0.5, 0.5), Vector2(0.66, 0.6)]), false)
		STAR:
			var points: PackedVector2Array = PackedVector2Array()
			var inner: float = 0.21 if round_caps else 0.18
			for i: int in 10:
				var a: float = -PI * 0.5 + PI * float(i) / 5.0
				var r: float = 0.44 if i % 2 == 0 else inner
				points.append(Vector2(0.5, 0.54) + Vector2(cos(a), sin(a)) * r)
			pen.fill(points)
			if round_caps:
				pen.line(points, true)
		_:
			push_error("Unknown icon: %s" % kind)


## Draws strokes and fills in the icon's unit square.
class Pen extends RefCounted:
	var canvas: CanvasItem
	var origin: Vector2
	var side: float
	var width: float
	var color: Color
	var round_caps: bool

	func _init(p_canvas: CanvasItem, p_origin: Vector2, p_side: float, p_width: float, p_color: Color, p_round: bool) -> void:
		canvas = p_canvas
		origin = p_origin
		side = p_side
		width = p_width
		color = p_color
		round_caps = p_round

	func at(unit: Vector2) -> Vector2:
		return origin + unit * side

	## A line through unit points: round or square ends, round or mitered
	## corners.
	func line(units: PackedVector2Array, closed: bool) -> void:
		var points: PackedVector2Array = PackedVector2Array()
		for unit: Vector2 in units:
			points.append(at(unit))
		var count: int = points.size()
		var segments: int = count if closed else count - 1
		var half: float = width * 0.5
		for i: int in segments:
			var a: Vector2 = points[i]
			var b: Vector2 = points[(i + 1) % count]
			var along: Vector2 = (b - a).normalized()
			if not round_caps and not closed:
				if i == 0:
					a -= along * half
				if i == segments - 1:
					b += along * half
			canvas.draw_line(a, b, color, width, true)
		for i: int in count:
			var interior: bool = closed or (i > 0 and i < count - 1)
			if round_caps:
				canvas.draw_circle(points[i], half, color, true, -1.0, true)
			elif interior:
				_miter(points[(i - 1 + count) % count], points[i], points[(i + 1) % count])

	## Fills the outer corner between two segments meeting at p.
	func _miter(prev: Vector2, p: Vector2, next: Vector2) -> void:
		var d1: Vector2 = (p - prev).normalized()
		var d2: Vector2 = (next - p).normalized()
		var n1: Vector2 = Vector2(-d1.y, d1.x)
		var n2: Vector2 = Vector2(-d2.y, d2.x)
		var side_sign: float = -signf(d2.dot(n1))
		if side_sign == 0.0:
			return
		var half: float = width * 0.5
		var bisector: Vector2 = (n1 + n2).normalized()
		var cos_half: float = maxf(0.25, bisector.dot(n1))
		var tip: Vector2 = p + bisector * side_sign * half / cos_half
		canvas.draw_colored_polygon(PackedVector2Array([p, p + n1 * side_sign * half, tip, p + n2 * side_sign * half]), color)

	## A thick bar with flat or round ends, for the pause icon.
	func bar(from_unit: Vector2, to_unit: Vector2, bar_width: float) -> void:
		var a: Vector2 = at(from_unit)
		var b: Vector2 = at(to_unit)
		if round_caps:
			var r: float = bar_width * 0.5
			var along: Vector2 = (b - a).normalized()
			a += along * r
			b -= along * r
			canvas.draw_line(a, b, color, bar_width, true)
			canvas.draw_circle(a, r, color, true, -1.0, true)
			canvas.draw_circle(b, r, color, true, -1.0, true)
		else:
			canvas.draw_rect(Rect2(Vector2(a.x - bar_width * 0.5, a.y), Vector2(bar_width, b.y - a.y)), color)

	func circle(center_unit: Vector2, radius_unit: float) -> void:
		canvas.draw_arc(at(center_unit), radius_unit * side, 0.0, TAU, 48, color, width, true)

	## A filled polygon with a smoothed edge.
	func fill(units: PackedVector2Array) -> void:
		var points: PackedVector2Array = PackedVector2Array()
		for unit: Vector2 in units:
			points.append(at(unit))
		canvas.draw_colored_polygon(points, color)
		var ring: PackedVector2Array = points.duplicate()
		ring.append(points[0])
		canvas.draw_polyline(ring, color, 1.0, true)
