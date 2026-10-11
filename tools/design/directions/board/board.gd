extends Control
## Board preview for the Phase 1 design directions, drawn in code from one
## _draw() call: frame, cell backgrounds, lines, digits and candidate rings,
## then the state marks on top. It draws the state it is given. It handles no
## input and holds no game rules.
##
## The scenes gridline/board.tscn, pebble/board.tscn and pop/board.tscn share
## this script and set direction. The contract with ui-motion-artist is in
## docs/design/briefs/grid-cell-artist-phase1.md, section 1.
##
## Every color, weight, radius and font comes from palettes.gd, and every
## position from ring_layouts.gd. Thin straight lines and bands are snapped to
## whole device pixels with a whole number of pixels as their weight, so a
## line keeps one weight across the board at any scale.
##
## Prototype code in tools/, never shipped. Owner: grid-cell-artist.

const Palettes := preload("res://tools/design/directions/palettes.gd")
const RingLayouts := preload("res://tools/design/directions/ring_layouts.gd")
const SampleState := preload("res://tools/design/directions/sample_state.gd")
const Fonts := preload("res://tools/design/directions/fonts.gd")

## Straight segments per quarter circle on rounded strokes and corners.
const ARC_STEPS: int = 8

## Cells in the four corners of the board, for boards with rounded corners.
const CORNER_CELLS: Array[int] = [0, 8, 72, 80]

## Which direction this board draws: "gridline", "pebble" or "pop".
@export var direction: String = "gridline":
	set(value):
		direction = value
		queue_redraw()

var dark: bool = false:
	set(value):
		dark = value
		queue_redraw()

var ring_layout: int = RingLayouts.DEFAULT_LAYOUT:
	set(value):
		ring_layout = value
		queue_redraw()

## The state to draw. Null draws SampleState.play_board().
var state: SampleState.BoardState = null:
	set(value):
		state = value
		queue_redraw()

var _play_board: SampleState.BoardState = null

# Set at the start of every _draw().
var _colors: Palettes.Palette = null
var _shape: Palettes.Shape = null
var _square: Rect2 = Rect2()
var _k: float = 1.0
var _tiles: bool = false
var _round_caps: bool = false
var _snap: bool = false
var _canvas_origin: Vector2 = Vector2.ZERO


## A cell's rect in this control's local coordinates: the pitch rect on lines
## boards, the tile on tiles boards.
func cell_rect(index: int) -> Rect2:
	return RingLayouts.cell_rect(direction, RingLayouts.board_square(size), index)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	_square = RingLayouts.board_square(size)
	if _square.size.x <= 0.0:
		return
	_colors = Palettes.palette(direction, dark)
	_shape = Palettes.shape(direction)
	_k = RingLayouts.board_scale(direction, _square)
	_tiles = _shape.style == Palettes.STYLE_TILES
	_round_caps = _shape.round_caps
	# Snap to device pixels only when the board is drawn unscaled and unrotated.
	var xform: Transform2D = get_global_transform_with_canvas()
	_snap = xform.x.is_equal_approx(Vector2.RIGHT) and xform.y.is_equal_approx(Vector2.DOWN)
	_canvas_origin = xform.origin

	var board: SampleState.BoardState = _board()
	_draw_frame()
	_draw_cell_backgrounds(board)
	if not _tiles:
		_draw_lines()
	_draw_content(board)
	_draw_marks(board)


func _board() -> SampleState.BoardState:
	if state != null:
		return state
	if _play_board == null:
		_play_board = SampleState.play_board()
	return _play_board


# 1. Frame

func _draw_frame() -> void:
	var radius: float = _shape.board_radius * _k
	if _tiles:
		var tray: StyleBoxFlat = _rounded(_colors.board_bg, radius)
		if _shape.shadow_blur > 0.0:
			tray.shadow_color = _colors.shadow
			tray.shadow_size = roundi(_shape.shadow_blur * _k)
			tray.shadow_offset = _shape.shadow_offset * _k
		draw_style_box(tray, _square)
		var card: StyleBoxFlat = _rounded(_colors.line_cell, _shape.box_radius * _k)
		for box: int in 9:
			draw_style_box(card, RingLayouts.box_rect(direction, _square, box))
		return
	var outer: float = _px_width(_shape.line_outer_w * _k)
	var hard_shadow: bool = _shape.shadow_blur <= 0.0 and _shape.shadow_offset != Vector2.ZERO
	if hard_shadow and _colors.shadow.a > 0.0:
		# The card's outer edge (the outside of the outer line), offset.
		var edge: Rect2 = _square.grow(outer * 0.5)
		edge.position += _shape.shadow_offset * _k
		var edge_radius: float = radius + outer * 0.5 if radius > 0.0 else 0.0
		draw_style_box(_rounded(_colors.shadow, edge_radius), edge)
	if radius > 0.0:
		draw_style_box(_rounded(_colors.board_bg, radius), _square)
	else:
		draw_rect(_square, _colors.board_bg)


# 2. Cell backgrounds

func _draw_cell_backgrounds(board: SampleState.BoardState) -> void:
	var tile: StyleBoxFlat = null
	if _tiles:
		tile = _rounded(_colors.cell_bg, _shape.cell_radius * _k)
	var board_radius: float = _shape.board_radius * _k
	for index: int in 81:
		var rect: Rect2 = RingLayouts.cell_rect(direction, _square, index)
		var color: Color = _bg_color(board.cell_bg(index))
		if _tiles:
			# One style, recolored: draw_style_box() records the shape at once.
			tile.bg_color = color
			draw_style_box(tile, rect)
		elif board_radius > 0.0 and CORNER_CELLS.has(index):
			draw_style_box(_corner_cell(color, index, board_radius), rect)
		else:
			draw_rect(rect, color)


func _bg_color(bg: SampleState.CellBg) -> Color:
	match bg:
		SampleState.CellBg.SELECTED:
			return _colors.cell_selected_bg
		SampleState.CellBg.CONFLICT:
			return _colors.cell_conflict_bg
		SampleState.CellBg.HINT_TARGET:
			return _colors.cell_hint_target_bg
		SampleState.CellBg.HINT_REASON:
			return _colors.cell_hint_reason_bg
		SampleState.CellBg.SAME_DIGIT:
			return _colors.cell_same_digit_bg
		SampleState.CellBg.PEER:
			return _colors.cell_peer_bg
	return _colors.cell_bg


## A corner cell's background with the board's rounded corner, so it never
## pokes out past the rounded outer line.
func _corner_cell(color: Color, index: int, radius: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = _rounded(color, 0.0)
	style.anti_aliasing = true
	var r: int = roundi(radius)
	match index:
		0:
			style.corner_radius_top_left = r
		8:
			style.corner_radius_top_right = r
		72:
			style.corner_radius_bottom_left = r
		80:
			style.corner_radius_bottom_right = r
	return style


# 3. Lines (lines style only)

func _draw_lines() -> void:
	var s: Rect2 = _square
	var cell_w: float = _shape.line_cell_w * _k
	var box_w: float = _shape.line_box_w * _k
	for n: int in range(1, 9):
		if n % 3 == 0:
			continue
		var at: float = s.size.x * float(n) / 9.0
		draw_rect(_band_v(s.position.x + at, cell_w, s.position.y, s.end.y), _colors.line_cell)
		draw_rect(_band_h(s.position.y + at, cell_w, s.position.x, s.end.x), _colors.line_cell)
	for n: int in [3, 6]:
		var at: float = s.size.x * float(n) / 9.0
		draw_rect(_band_v(s.position.x + at, box_w, s.position.y, s.end.y), _colors.line_box)
		draw_rect(_band_h(s.position.y + at, box_w, s.position.x, s.end.x), _colors.line_box)
	_draw_outer_line()


## The outer line, centered on the board's edge, so half of it falls outside.
func _draw_outer_line() -> void:
	var s: Rect2 = _square
	var w: float = _px_width(_shape.line_outer_w * _k)
	var radius: float = _shape.board_radius * _k
	if radius > 0.0:
		var style: StyleBoxFlat = _rounded(Color(0.0, 0.0, 0.0, 0.0), radius + w * 0.5)
		style.draw_center = false
		style.border_color = _colors.line_outer
		style.set_border_width_all(roundi(w))
		draw_style_box(style, s.grow(w * 0.5))
		return
	var half: float = w * 0.5
	draw_rect(_band_h(s.position.y, w, s.position.x - half, s.end.x + half), _colors.line_outer)
	draw_rect(_band_h(s.end.y, w, s.position.x - half, s.end.x + half), _colors.line_outer)
	draw_rect(_band_v(s.position.x, w, s.position.y - half, s.end.y + half), _colors.line_outer)
	draw_rect(_band_v(s.end.x, w, s.position.y - half, s.end.y + half), _colors.line_outer)


# 4. Content: digits and candidate rings

func _draw_content(board: SampleState.BoardState) -> void:
	var given: Palettes.TypeStyle = Palettes.type_style(direction, Palettes.ROLE_GIVEN)
	var placed: Palettes.TypeStyle = Palettes.type_style(direction, Palettes.ROLE_PLACED)
	var candidate: Palettes.TypeStyle = Palettes.type_style(direction, Palettes.ROLE_CANDIDATE)
	# Every ring box has the same side. Measure with the style's font at any
	# size, then rebuild the font at the fitted size.
	var first_ring: Rect2 = RingLayouts.ring_box(direction, _square, 0)
	var candidate_size: int = RingLayouts.candidate_font_size(direction, ring_layout, first_ring.size.x, candidate.font_at(candidate.size))
	var candidate_font: Font = candidate.font_at(float(candidate_size))
	# Slot centers and mark boxes, relative to the ring box's corner. They
	# are the same in every cell, so work them out once per draw.
	var slots: PackedVector2Array = PackedVector2Array()
	var marks: Array[Rect2] = []
	for digit: int in range(1, 10):
		slots.append(RingLayouts.slot_center(ring_layout, digit, first_ring, candidate_font, candidate_size) - first_ring.position)
		var mark: Rect2 = RingLayouts.mark_rect(direction, ring_layout, digit, first_ring, candidate_font, candidate_size)
		marks.append(Rect2(mark.position - first_ring.position, mark.size))
	for index: int in 81:
		var cell: Rect2 = RingLayouts.cell_rect(direction, _square, index)
		var digit: int = board.digit_at(index)
		if digit == 0:
			var corner: Vector2 = RingLayouts.ring_box(direction, _square, index).position
			_draw_ring(board, index, corner, slots, marks, candidate_font, candidate_size)
			continue
		var is_given: bool = board.is_given(index)
		var style: Palettes.TypeStyle = given if is_given else placed
		var digit_size: int = roundi(style.size * cell.size.x)
		var color: Color = _colors.digit_given if is_given else _colors.digit_placed
		if board.is_conflict(index):
			color = _colors.digit_conflict
		Fonts.draw_centered(self, style.font_at(float(digit_size)), digit_size, str(digit), cell.get_center(), color)


## One cell's ring. corner is the ring box's top left corner; slots and marks
## are the slot centers and mark boxes of digits 1 to 9 relative to it.
##
## Open: the digit. Crossed by hand: the X first, then the digit on top of it
## with a thin outline in the cell's background color, so the X stops just
## short of the digit's strokes and both stay readable. Crossed by Auto Cross:
## the digit, then one rising slash on top (GDD 5.2).
func _draw_ring(board: SampleState.BoardState, index: int, corner: Vector2, slots: PackedVector2Array, marks: Array[Rect2], font: Font, font_size: int) -> void:
	var stroke: float = _shape.x_stroke_w * _k
	var halo: int = maxi(1, roundi(_shape.crossed_halo_w * _k))
	var cell_bg: Color = _colors.cell_bg
	if board.crossed[index] != 0:
		cell_bg = _bg_color(board.cell_bg(index))
	for digit: int in range(1, 10):
		var center: Vector2 = corner + slots[digit - 1]
		var text: String = str(digit)
		var mark: Rect2 = Rect2(corner + marks[digit - 1].position, marks[digit - 1].size)
		var bottom_left: Vector2 = Vector2(mark.position.x, mark.end.y)
		var top_right: Vector2 = Vector2(mark.end.x, mark.position.y)
		if board.is_crossed(index, digit):
			_stroke(mark.position, mark.end, _colors.x_mark, stroke)
			_stroke(bottom_left, top_right, _colors.x_mark, stroke)
			Fonts.draw_centered_outlined(self, font, font_size, text, center, _colors.candidate_crossed, halo, cell_bg)
		elif board.is_auto_crossed(index, digit):
			Fonts.draw_centered(self, font, font_size, text, center, _colors.candidate_crossed)
			_stroke(bottom_left, top_right, _colors.x_mark_auto, stroke)
		else:
			Fonts.draw_centered(self, font, font_size, text, center, _colors.candidate_open)


# 5. Marks

func _draw_marks(board: SampleState.BoardState) -> void:
	for index: int in 81:
		var flags: int = board.flags(index)
		var cell: Rect2 = RingLayouts.cell_rect(direction, _square, index)
		if (flags & SampleState.STATE_CONFLICT) != 0 and not board.is_empty(index):
			_draw_conflict_bar(cell)
		if (flags & SampleState.STATE_HINT_TARGET) != 0:
			_draw_brackets(cell)
		if (flags & SampleState.STATE_HINT_REASON) != 0:
			_draw_ticks(cell)
	# The selection frame goes over everything.
	if board.selected >= 0 and board.selected < 81:
		var cell: Rect2 = RingLayouts.cell_rect(direction, _square, board.selected)
		_draw_selection(cell, board.mode == SampleState.MODE_CROSS_OUT)


## A bar under the digit of a cell in a conflict.
func _draw_conflict_bar(cell: Rect2) -> void:
	var side: float = cell.size.x
	var half: float = _shape.conflict_bar_len * side * 0.5
	var weight: float = _shape.conflict_bar_w * _k
	var center: Vector2 = Vector2(cell.get_center().x, cell.position.y + _shape.conflict_bar_y * side)
	if _round_caps:
		_stroke(center - Vector2(half, 0.0), center + Vector2(half, 0.0), _colors.conflict_marker, weight)
	else:
		draw_rect(_band_h(center.y, weight, center.x - half, center.x + half), _colors.conflict_marker)


## Hint target: four corner brackets just inside the selection frame band.
func _draw_brackets(cell: Rect2) -> void:
	var arm: float = _shape.bracket_len * cell.size.x
	var weight: float = _shape.marker_w * _k
	var color: Color = _colors.hint_target_marker
	if _tiles:
		var path: RoundedPath = _mark_path(cell, weight)
		var r: float = path.radius
		# From a corner's middle to the arm's end, minus the cap.
		var half: float = (arm - r) + PI * r * 0.25 - _cap(weight)
		for corner: int in 4:
			var at: float = path.corner_middle(corner)
			_path_stroke(path.cut(at - half, at + half), color, weight)
		return
	var inner: Rect2 = _frame_inner(cell)
	var w: float = _px_width(weight)
	var a: float = roundf(arm) if _snap else arm
	var p: Vector2 = inner.position
	var e: Vector2 = inner.end
	var arms: Array[Rect2] = [
		Rect2(p.x, p.y, a, w), Rect2(p.x, p.y, w, a),
		Rect2(e.x - a, p.y, a, w), Rect2(e.x - w, p.y, w, a),
		Rect2(e.x - a, e.y - w, a, w), Rect2(e.x - w, e.y - a, w, a),
		Rect2(p.x, e.y - w, a, w), Rect2(p.x, e.y - a, w, a),
	]
	for rect: Rect2 in arms:
		draw_rect(rect, color)


## Hint reason (and cells a lesson marks): a tick centered on each side, just
## inside the selection frame band.
func _draw_ticks(cell: Rect2) -> void:
	var tick: float = _shape.tick_len * cell.size.x
	var weight: float = _shape.marker_w * _k
	var color: Color = _colors.hint_reason_marker
	if _tiles:
		var path: RoundedPath = _mark_path(cell, weight)
		var half: float = tick * 0.5 - _cap(weight)
		for side: int in 4:
			var at: float = path.side_middle(side)
			_path_stroke(path.cut(at - half, at + half), color, weight)
		return
	var inner: Rect2 = _frame_inner(cell)
	var w: float = _px_width(weight)
	var t: float = roundf(tick) if _snap else tick
	var c: Vector2 = inner.get_center()
	var x: float = _snap_x(c.x - t * 0.5)
	var y: float = _snap_y(c.y - t * 0.5)
	draw_rect(Rect2(x, inner.position.y, t, w), color)
	draw_rect(Rect2(x, inner.end.y - w, t, w), color)
	draw_rect(Rect2(inner.position.x, y, w, t), color)
	draw_rect(Rect2(inner.end.x - w, y, w, t), color)


## The selection frame, centered on the cell edge: solid in Place mode, dashed
## in Cross Out mode with the dashes laid out from every corner.
func _draw_selection(cell: Rect2, dashed: bool) -> void:
	var weight: float = _shape.selected_outline_w * _k
	var color: Color = _colors.selected_outline
	var dash: float = _shape.selected_dash * _k
	var gap: float = _shape.selected_gap * _k
	if _tiles:
		var path: RoundedPath = RoundedPath.new(cell, _shape.cell_radius * _k)
		if not dashed:
			draw_polyline(path.cut(0.0, path.perimeter), color, weight, true)
			return
		for corner: int in 4:
			var start: float = path.corner_middle(corner)
			for span: Vector2 in _dash_spans(path.side, dash, gap):
				var from: float = start + span.x + _cap(weight)
				var to: float = start + span.y - _cap(weight)
				_path_stroke(path.cut(from, to), color, weight)
		return
	var w: float = _px_width(weight)
	var half: float = w * 0.5
	var p: Vector2 = cell.position
	var e: Vector2 = cell.end
	if not dashed:
		draw_rect(_band_h(p.y, w, p.x - half, e.x + half), color)
		draw_rect(_band_h(e.y, w, p.x - half, e.x + half), color)
		draw_rect(_band_v(p.x, w, p.y - half, e.y + half), color)
		draw_rect(_band_v(e.x, w, p.y - half, e.y + half), color)
		return
	var side: float = cell.size.x
	for span: Vector2 in _dash_spans(side, dash, gap):
		# Dashes that touch a corner reach past it by half the weight, so the
		# two sides meet in a closed corner.
		var from: float = span.x - (half if is_zero_approx(span.x) else 0.0)
		var to: float = span.y + (half if is_equal_approx(span.y, side) else 0.0)
		draw_rect(_band_h(p.y, w, p.x + from, p.x + to), color)
		draw_rect(_band_h(e.y, w, p.x + from, p.x + to), color)
		draw_rect(_band_v(p.x, w, p.y + from, p.y + to), color)
		draw_rect(_band_v(e.x, w, p.y + from, p.y + to), color)


## Dashes along one side of the given length: the first starts at 0, the last
## ends at length, and the gaps stretch or shrink a little to fit.
func _dash_spans(length: float, dash: float, gap: float) -> Array[Vector2]:
	var spans: Array[Vector2] = []
	var count: int = maxi(2, roundi((length + gap) / (dash + gap)))
	var fitted_gap: float = (length - float(count) * dash) / float(count - 1)
	if fitted_gap <= 0.0:
		spans.append(Vector2(0.0, length))
		return spans
	for n: int in count:
		var start: float = float(n) * (dash + fitted_gap)
		spans.append(Vector2(start, start + dash))
	return spans


## Lines style: the inside edge of the selection frame band. Hint marks start
## here, selected_outline_w / 2 inside the cell edge.
func _frame_inner(cell: Rect2) -> Rect2:
	var w: float = _px_width(_shape.selected_outline_w * _k)
	var left: float = _snap_x(cell.position.x - w * 0.5) + w
	var top: float = _snap_y(cell.position.y - w * 0.5) + w
	var right: float = _snap_x(cell.end.x - w * 0.5)
	var bottom: float = _snap_y(cell.end.y - w * 0.5)
	return Rect2(left, top, right - left, bottom - top)


## Tiles style: the path the hint marks run along, the center of a band of
## the given weight that starts selected_outline_w / 2 inside the tile edge.
func _mark_path(cell: Rect2, weight: float) -> RoundedPath:
	var inset: float = _shape.selected_outline_w * _k * 0.5 + weight * 0.5
	return RoundedPath.new(cell.grow(-inset), maxf(0.0, _shape.cell_radius * _k - inset))


# Drawing helpers

## A straight stroke from one point to another: square ends, or round ends
## that stay inside the two points.
func _stroke(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	if not _round_caps:
		draw_line(from, to, color, width, true)
		return
	var inset: Vector2 = (to - from).normalized() * width * 0.5
	_path_stroke(PackedVector2Array([from + inset, to - inset]), color, width)


## A polyline, with round ends when the direction has round_caps. Round ends
## reach half the width past the first and last points.
func _path_stroke(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() > 1:
		draw_polyline(points, color, width, true)
	if not _round_caps or points.is_empty():
		return
	draw_circle(points[0], width * 0.5, color, true, -1.0, true)
	draw_circle(points[points.size() - 1], width * 0.5, color, true, -1.0, true)


## How far a stroke's end reaches past its last point: half the width for
## round ends, nothing for flat ones.
func _cap(width: float) -> float:
	return width * 0.5 if _round_caps else 0.0


func _rounded(color: Color, radius: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(roundi(radius))
	style.corner_detail = ARC_STEPS * 2
	style.anti_aliasing = radius > 0.0
	return style


## A horizontal band of the given weight centered on center_y, from x0 to x1.
func _band_h(center_y: float, weight: float, x0: float, x1: float) -> Rect2:
	var w: float = _px_width(weight)
	var left: float = _snap_x(x0)
	return Rect2(left, _snap_y(center_y - w * 0.5), _snap_x(x1) - left, w)


## A vertical band of the given weight centered on center_x, from y0 to y1.
func _band_v(center_x: float, weight: float, y0: float, y1: float) -> Rect2:
	var w: float = _px_width(weight)
	var top: float = _snap_y(y0)
	return Rect2(_snap_x(center_x - w * 0.5), top, w, _snap_y(y1) - top)


## A weight in whole device pixels, at least one, when snapping.
func _px_width(weight: float) -> float:
	return maxf(1.0, roundf(weight)) if _snap else weight


func _snap_x(x: float) -> float:
	return roundf(x + _canvas_origin.x) - _canvas_origin.x if _snap else x


func _snap_y(y: float) -> float:
	return roundf(y + _canvas_origin.y) - _canvas_origin.y if _snap else y


## The center line of a rounded square, clockwise from the middle of its top
## edge, run around twice so any stretch of it can be cut out without
## wrapping. Corners and sides are numbered clockwise from the top right
## corner and the top side.
class RoundedPath extends RefCounted:
	var radius: float
	var side: float ## Length from one corner's middle to the next.
	var perimeter: float
	var _points: PackedVector2Array = PackedVector2Array()
	var _lengths: PackedFloat32Array = PackedFloat32Array()

	func _init(rect: Rect2, corner_radius: float) -> void:
		radius = clampf(corner_radius, 0.0, minf(rect.size.x, rect.size.y) * 0.5)
		var centers: PackedVector2Array = PackedVector2Array([
			Vector2(rect.end.x - radius, rect.position.y + radius),
			Vector2(rect.end.x - radius, rect.end.y - radius),
			Vector2(rect.position.x + radius, rect.end.y - radius),
			Vector2(rect.position.x + radius, rect.position.y + radius),
		])
		var top_middle: Vector2 = Vector2(rect.get_center().x, rect.position.y)
		_points.append(top_middle)
		for turn: int in 2:
			for corner: int in 4:
				var start: float = -PI * 0.5 + PI * 0.5 * float(corner)
				for step: int in ARC_STEPS + 1:
					var angle: float = start + PI * 0.5 * float(step) / float(ARC_STEPS)
					_points.append(centers[corner] + Vector2(cos(angle), sin(angle)) * radius)
			_points.append(top_middle)
		_lengths.append(0.0)
		for n: int in range(1, _points.size()):
			_lengths.append(_lengths[n - 1] + _points[n - 1].distance_to(_points[n]))
		perimeter = _lengths[_lengths.size() - 1] * 0.5
		side = perimeter * 0.25

	## Distance along the path to the middle of a corner.
	func corner_middle(corner: int) -> float:
		return side * (0.5 + float(corner))

	## Distance along the path to the middle of a side.
	func side_middle(side_index: int) -> float:
		return side * float(side_index)

	## The stretch of the path between two distances along it. Distances
	## may run up to one turn before 0 or past the end of the first turn.
	func cut(from: float, to: float) -> PackedVector2Array:
		var out: PackedVector2Array = PackedVector2Array()
		if to <= from or to - from > perimeter:
			return out
		if from < 0.0:
			from += perimeter
			to += perimeter
		for n: int in _points.size() - 1:
			var a: float = _lengths[n]
			var b: float = _lengths[n + 1]
			if b <= a or b < from:
				continue
			if a > to:
				break
			var p0: Vector2 = _points[n] if a >= from else _points[n].lerp(_points[n + 1], (from - a) / (b - a))
			var p1: Vector2 = _points[n + 1] if b <= to else _points[n].lerp(_points[n + 1], (to - a) / (b - a))
			if out.is_empty():
				out.append(p0)
			out.append(p1)
		return out
