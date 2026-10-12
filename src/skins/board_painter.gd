class_name BoardPainter extends RefCounted
## The board drawing code (docs/ARCHITECTURE.md section 6, the look in
## docs/DESIGN_SYSTEM.md section 2). It draws the BoardDrawState it is given
## with the colors and sizes of a GameSkin. It holds no game rules and handles
## no input, and it never creates a node: everything is drawn into the
## caller's CanvasItem from its _draw().
##
## Sizes in the skin are dp, and one canvas unit is one dp. Internally the
## painter draws in device pixels (a draw transform of 1 / pixels per unit), so
## strokes snap to whole pixels and fonts are sized in whole pixels, as
## DESIGN_SYSTEM.md sections 0 and 3.4 ask.
##
## Use one painter per board. draw_effects() reuses what the last
## draw_board() call worked out (cell fills, digits, rings), so call
## draw_board() first, with the same square.

## Board.Mark values (docs/ARCHITECTURE.md section 4). core's Board is built
## in parallel; these must stay equal to Board.Mark.
const MARK_OPEN: int = 0
const MARK_CROSSED_HAND: int = 1
const MARK_RESTORED_HAND: int = 2
const MARK_CROSSED_AUTO: int = 3

## GameSession.Mode.CROSS_OUT (docs/ARCHITECTURE.md section 4).
const MODE_CROSS_OUT: int = 1

const CELLS: int = 81
const MARKS: int = 729

## Ring layout A, reading rows (DESIGN_SYSTEM.md 2.3), indexed by digit - 1:
##   1 2 3 4
##   5 . 6
##   7 8 9
const SLOT_ROW: Array[int] = [0, 0, 0, 0, 1, 1, 2, 2, 2]
const SLOT_POSITION: Array[int] = [0, 1, 2, 3, 0, 2, 0, 1, 2]
const ROW_POSITIONS: Array[int] = [4, 3, 3]

const DIGIT_TEXT: Array[String] = ["", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

## The four corner cells, clipped to the board's rounded corners.
const CORNER_TOP_LEFT: int = 0
const CORNER_TOP_RIGHT: int = 8
const CORNER_BOTTOM_LEFT: int = 72
const CORNER_BOTTOM_RIGHT: int = 80

## Font size the candidate fit is measured at, then scaled (as the contrast
## checker does, so both give the same size).
const FIT_MEASURE_SIZE: int = 100

## Cell state bits.
const F_SELECTED: int = 1
const F_CONFLICT: int = 2
const F_TARGET: int = 4
const F_REASON: int = 8
const F_SAME: int = 16
const F_PEER: int = 32

## Cell fills by priority (DESIGN_SYSTEM.md 2.6).
enum Fill { SELECTED, CONFLICT, HINT_TARGET, HINT_REASON, SAME_DIGIT, PEER, PLAIN }

## Motion details from DESIGN_SYSTEM.md section 6, as shares of each effect.
const PLACE_FROM_SCALE: float = 0.6
const PLACE_RING_SHARE: float = 80.0 / 140.0   # the ring fades out over the first 80 of 140 ms
const ERASE_TO_SCALE: float = 0.8
const ERASE_RING_SHARE: float = 120.0 / 100.0  # the ring fades in over 120 ms from the start of a 100 ms effect
const CROSS_FROM_SCALE: float = 1.3
const RESTORE_TO_SCALE: float = 0.8
const COMPLETE_GROWTH: float = 0.08

# Device mapping, set by _begin() for every draw call.
var _canvas: CanvasItem = null
var _skin: GameSkin = null
var _scale: float = 1.0          # device pixels per canvas unit
var _origin: Vector2 = Vector2.ZERO  # the canvas origin in device pixels
var _snap: bool = true
var _square: Rect2 = Rect2()     # the board square, in pixels
var _pitch: float = 0.0          # cell side, in pixels
var _edge_x: PackedFloat32Array = PackedFloat32Array()  # 10 snapped cell edges
var _edge_y: PackedFloat32Array = PackedFloat32Array()

# Fonts and ring geometry, rebuilt only when the skin or the cell size changes.
var _layout_key: String = ""
var _given_font: Font = null
var _placed_font: Font = null
var _candidate_font: Font = null
var _digit_px: int = 1
var _candidate_px: int = 1
var _ring_inset_px: float = 0.0
var _given_offset: PackedVector2Array = PackedVector2Array()   # per digit: baseline origin from the cell center
var _placed_offset: PackedVector2Array = PackedVector2Array()
var _candidate_origin: PackedVector2Array = PackedVector2Array()  # per digit: baseline origin from the ring box corner
var _slot_rects: Array[Rect2] = []   # per digit, from the ring box corner
var _mark_rects: Array[Rect2] = []
var _chip_rects: Array[Rect2] = []
var _chip_radius: float = 0.0

# What the last draw_board() drew, for draw_effects().
var _state: BoardDrawState = null
var _flags: PackedByteArray = PackedByteArray()
var _fills: PackedByteArray = PackedByteArray()
var _chips: PackedByteArray = PackedByteArray()

var _fonts: Dictionary[String, Font] = {}
var _ink_boxes: Dictionary[String, Rect2] = {}
var _style: StyleBoxFlat = StyleBoxFlat.new()


## The largest square that fits in rect, centered.
static func board_square(rect: Rect2) -> Rect2:
	var side: float = maxf(0.0, minf(rect.size.x, rect.size.y))
	return Rect2(rect.position + (rect.size - Vector2(side, side)) * 0.5, Vector2(side, side))


## The cell's square on a board drawn in square: one ninth of the side, with
## the grid lines centered on its edges, so every cell has the same pitch
## (DESIGN_SYSTEM.md 2.1). An empty Rect2 for a cell outside 0 to 80.
static func cell_rect(square: Rect2, cell: int, _skin: GameSkin) -> Rect2:
	if cell < 0 or cell >= CELLS:
		return Rect2()
	var pitch: Vector2 = square.size / 9.0
	return Rect2(square.position + Vector2(float(cell % 9) * pitch.x, float(cell / 9) * pitch.y), pitch)


## The cell under point, or -1 outside the board square. A point on a line
## belongs to the cell on whichever side of the line's center it lies, so the
## board has no dead strips between cells.
static func cell_at(square: Rect2, point: Vector2, _skin: GameSkin) -> int:
	if square.size.x <= 0.0 or square.size.y <= 0.0:
		return -1
	var local: Vector2 = (point - square.position) / square.size * 9.0
	if local.x < 0.0 or local.y < 0.0 or local.x >= 9.0 or local.y >= 9.0:
		return -1
	return mini(floori(local.y), 8) * 9 + mini(floori(local.x), 8)


## Draws the whole board, bottom to top in the order of DESIGN_SYSTEM.md 2.9.
## Call it from canvas's _draw().
func draw_board(canvas: CanvasItem, square: Rect2, state: BoardDrawState, skin: GameSkin) -> void:
	if state == null or not _begin(canvas, square, skin):
		return
	_read_state(state)
	_push_pixels()
	_draw_card()
	_draw_fills()
	_draw_lines()
	for cell: int in CELLS:
		_draw_cell_content(cell)
	_draw_conflict_bars()
	_draw_selection()
	_draw_hint_marks()
	_pop_pixels()


## Draws the running effects over the board (DESIGN_SYSTEM.md section 6), on
## a layer above it. Uses the state of the last draw_board() call.
func draw_effects(canvas: CanvasItem, square: Rect2, effects: Array[CellEffect], skin: GameSkin) -> void:
	if effects.is_empty() or not _begin(canvas, square, skin):
		return
	if _fills.size() != CELLS:
		_read_state(BoardDrawState.new())
	_push_pixels()
	for effect: CellEffect in effects:
		if effect == null or effect.cell < 0 or effect.cell >= CELLS:
			continue
		match effect.kind:
			CellEffect.Kind.PLACE:
				_draw_place_effect(effect)
			CellEffect.Kind.ERASE:
				_draw_erase_effect(effect)
			CellEffect.Kind.CROSS, CellEffect.Kind.RESTORE:
				_draw_mark_effect(effect)
			CellEffect.Kind.COMPLETE:
				_draw_complete_effect(effect)
	_pop_pixels()


# Setup

## Works out the device mapping and, when needed, the fonts and ring
## geometry. False when there is nothing to draw.
func _begin(canvas: CanvasItem, square: Rect2, skin: GameSkin) -> bool:
	if canvas == null:
		return false
	var to_device: Transform2D = Transform2D.IDENTITY
	if canvas.is_inside_tree():
		to_device = canvas.get_viewport().get_final_transform() * canvas.get_global_transform_with_canvas()
	return _begin_with(canvas, to_device, square, skin)


## _begin() with the canvas to device pixel transform given.
func _begin_with(canvas: CanvasItem, to_device: Transform2D, square: Rect2, skin: GameSkin) -> bool:
	if canvas == null or skin == null or square.size.x <= 0.0 or square.size.y <= 0.0:
		return false
	_canvas = canvas
	_skin = skin
	var axis_aligned: bool = is_zero_approx(to_device.x.y) and is_zero_approx(to_device.y.x) \
		and to_device.x.x > 0.0 and is_equal_approx(to_device.x.x, to_device.y.y)
	if axis_aligned:
		_scale = to_device.x.x
		_snap = true
	else:
		# Rotated or skewed (a tilted preview, say): draw at the average scale
		# and leave strokes unsnapped.
		_scale = sqrt(absf(to_device.determinant()))
		_snap = false
	if _scale <= 0.0:
		_scale = 1.0
	_origin = to_device.origin
	var side: float = minf(square.size.x, square.size.y) * _scale
	_square = Rect2(square.position * _scale, Vector2(side, side))
	_pitch = side / 9.0
	_edge_x.resize(10)
	_edge_y.resize(10)
	for i: int in 10:
		_edge_x[i] = _snap_x(_square.position.x + float(i) * _pitch)
		_edge_y[i] = _snap_y(_square.position.y + float(i) * _pitch)
	var key: String = "%d|%.4f" % [skin.get_instance_id(), _pitch]
	if key != _layout_key:
		_build_layout()
		_layout_key = key
	return true


## Fonts, digit offsets and the ring slots for the current skin and cell size.
func _build_layout() -> void:
	var s: GameSkin = _skin
	_given_font = _font(s.given_embolden)
	_placed_font = _font(s.placed_embolden)
	_candidate_font = _font(s.candidate_embolden)

	_digit_px = maxi(1, roundi(s.digit_size * _pitch))
	_given_offset.resize(9)
	_placed_offset.resize(9)
	for d: int in range(1, 10):
		_given_offset[d - 1] = -_ink_box(_given_font, _digit_px, d).get_center()
		_placed_offset[d - 1] = -_ink_box(_placed_font, _digit_px, d).get_center()

	_ring_inset_px = s.ring_inset * _scale
	var ring_side: float = maxf(1.0, _pitch - 2.0 * _ring_inset_px)
	_candidate_px = _fit_candidate_size(ring_side, s.candidate_gap)
	var slot: Vector2 = _digit_cell(_candidate_font, _candidate_px)
	var pad: float = s.hint_cross_pad * float(_candidate_px)
	_chip_radius = 2.0 * pad
	_candidate_origin.resize(9)
	_slot_rects.clear()
	_mark_rects.clear()
	_chip_rects.clear()
	for d: int in range(1, 10):
		var positions: int = ROW_POSITIONS[SLOT_ROW[d - 1]]
		var center: Vector2 = slot * 0.5
		center.x += float(SLOT_POSITION[d - 1]) * (ring_side - slot.x) / float(positions - 1)
		center.y += float(SLOT_ROW[d - 1]) * (ring_side - slot.y) / float(ROW_POSITIONS.size() - 1)
		_candidate_origin[d - 1] = center - _ink_box(_candidate_font, _candidate_px, d).get_center()
		var slot_rect: Rect2 = Rect2(center - slot * 0.5, slot)
		_slot_rects.append(slot_rect)
		var mark: Vector2 = slot * s.cross_mark_span
		_mark_rects.append(Rect2(center - mark * 0.5, mark))
		_chip_rects.append(slot_rect.grow_individual(0.0, pad, 0.0, pad))


## The largest whole pixel size at which the nine candidates fit the ring box
## with gap times the size between neighbors (DESIGN_SYSTEM.md 2.3).
func _fit_candidate_size(ring_side: float, gap: float) -> int:
	var unit: Vector2 = _digit_cell(_candidate_font, FIT_MEASURE_SIZE) / float(FIT_MEASURE_SIZE)
	var best: float = INF
	for positions: int in ROW_POSITIONS:
		var n: float = float(positions)
		best = minf(best, ring_side / (n * unit.x + (n - 1.0) * gap))
	var rows: float = float(ROW_POSITIONS.size())
	best = minf(best, ring_side / (rows * unit.y + (rows - 1.0) * gap))
	return maxi(1, floori(best))


## Flags and fills of every cell, from the state alone.
func _read_state(state: BoardDrawState) -> void:
	_state = state
	_flags.resize(CELLS)
	_flags.fill(0)
	_set_flag(state.peers, F_PEER)
	_set_flag(state.same_digit, F_SAME)
	_set_flag(state.hint_reasons, F_REASON)
	_set_flag(state.lesson_marks, F_REASON)
	_set_flag(state.hint_targets, F_TARGET)
	for cell: int in state.conflicts:
		# A conflict shows only on a cell holding a digit (DESIGN_SYSTEM.md 2.6).
		if cell >= 0 and cell < CELLS and _digit(cell) != 0:
			_flags[cell] |= F_CONFLICT
	if state.selected >= 0 and state.selected < CELLS:
		_flags[state.selected] |= F_SELECTED

	_fills.resize(CELLS)
	for cell: int in CELLS:
		var f: int = _flags[cell]
		var fill: int = Fill.PLAIN
		if f & F_SELECTED:
			fill = Fill.SELECTED
		elif f & F_CONFLICT:
			fill = Fill.CONFLICT
		elif f & F_TARGET:
			fill = Fill.HINT_TARGET
		elif f & F_REASON:
			fill = Fill.HINT_REASON
		elif f & F_SAME:
			fill = Fill.SAME_DIGIT
		elif f & F_PEER:
			fill = Fill.PEER
		_fills[cell] = fill

	_chips.resize(MARKS)
	_chips.fill(0)
	for index: int in state.hint_crosses:
		if index >= 0 and index < MARKS:
			_chips[index] = 1


func _set_flag(cells: PackedInt32Array, flag: int) -> void:
	for cell: int in cells:
		if cell >= 0 and cell < CELLS:
			_flags[cell] |= flag


# Board layers

func _draw_card() -> void:
	var s: GameSkin = _skin
	var outer: Rect2 = _outer_rect()
	var w: float = _weight(s.line_outer_w)
	var radius: float = s.board_radius * _scale
	var offset: float = s.shadow_offset * _scale
	if _snap:
		offset = roundf(offset)
	_draw_rounded(Rect2(outer.position + Vector2(offset, offset), outer.size), s.shadow, radius + w * 0.5)
	_draw_rounded(_board_rect(), s.board_bg, radius)


func _draw_fills() -> void:
	var radius: int = roundi(_skin.board_radius * _scale)
	for cell: int in CELLS:
		var rect: Rect2 = _cell_px(cell)
		var color: Color = _fill_color(_fills[cell])
		if radius > 0 and (cell == CORNER_TOP_LEFT or cell == CORNER_TOP_RIGHT or cell == CORNER_BOTTOM_LEFT or cell == CORNER_BOTTOM_RIGHT):
			_style.bg_color = color
			_style.draw_center = true
			_style.set_border_width_all(0)
			_style.set_corner_radius_all(0)
			_style.anti_aliasing = true
			match cell:
				CORNER_TOP_LEFT:
					_style.corner_radius_top_left = radius
				CORNER_TOP_RIGHT:
					_style.corner_radius_top_right = radius
				CORNER_BOTTOM_LEFT:
					_style.corner_radius_bottom_left = radius
				CORNER_BOTTOM_RIGHT:
					_style.corner_radius_bottom_right = radius
			_canvas.draw_style_box(_style, rect)
		else:
			_canvas.draw_rect(rect, color)


func _draw_lines() -> void:
	var s: GameSkin = _skin
	var top: float = _edge_y[0]
	var bottom: float = _edge_y[9]
	var left: float = _edge_x[0]
	var right: float = _edge_x[9]
	for pass_box: bool in [false, true]:
		var w: float = _weight(s.line_box_w if pass_box else s.line_cell_w)
		var color: Color = s.line_box if pass_box else s.line_cell
		for i: int in range(1, 9):
			if (i % 3 == 0) != pass_box:
				continue
			var at: float = float(i) * _pitch
			_canvas.draw_rect(Rect2(_snap_x(_square.position.x + at - w * 0.5), top, w, bottom - top), color)
			_canvas.draw_rect(Rect2(left, _snap_y(_square.position.y + at - w * 0.5), right - left, w), color)
	# The outer line, centered on the board edge, half of it outside.
	var outer_w: float = _weight(s.line_outer_w)
	_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	_style.draw_center = false
	_style.border_color = s.line_outer
	_style.set_border_width_all(roundi(outer_w))
	_style.set_corner_radius_all(roundi(s.board_radius * _scale + outer_w * 0.5))
	_style.anti_aliasing = true
	_canvas.draw_style_box(_style, _outer_rect())
	_style.draw_center = true
	_style.set_border_width_all(0)


## A given or placed digit, or the ring of an empty cell.
func _draw_cell_content(cell: int) -> void:
	var digit: int = _digit(cell)
	if digit != 0:
		_draw_digit(cell, digit, _digit_color(cell, digit), 1.0)
		return
	var corner: Vector2 = _ring_corner(cell)
	var fill: Color = _fill_color(_fills[cell])
	for d: int in range(1, 10):
		_draw_candidate(cell, d, corner, fill, 1.0)


func _draw_digit(cell: int, digit: int, color: Color, alpha: float) -> void:
	var given: bool = _is_given(cell)
	var font: Font = _given_font if given else _placed_font
	var offset: Vector2 = _given_offset[digit - 1] if given else _placed_offset[digit - 1]
	_canvas.draw_char(font, _cell_center(cell) + offset, DIGIT_TEXT[digit], _digit_px, _faded(color, alpha))


## One candidate in its slot (DESIGN_SYSTEM.md 2.3 to 2.5 and the hint cross
## chip in 2.7). corner is the ring box's top left corner, fill the cell fill.
func _draw_candidate(cell: int, digit: int, corner: Vector2, fill: Color, alpha: float) -> void:
	var s: GameSkin = _skin
	var index: int = cell * 9 + digit - 1
	var mark: int = _mark(index)
	var text: String = DIGIT_TEXT[digit]
	var at: Vector2 = corner + _candidate_origin[digit - 1]
	var knockout: int = _knockout_px()
	if mark == MARK_CROSSED_HAND:
		_draw_hand_x(corner, digit, 1.0, _faded(s.cross_mark_hand, alpha))
		_canvas.draw_char_outline(_candidate_font, at, text, _candidate_px, knockout, _faded(fill, alpha))
		_canvas.draw_char(_candidate_font, at, text, _candidate_px, _faded(s.candidate_crossed, alpha))
	elif mark == MARK_CROSSED_AUTO:
		_canvas.draw_char(_candidate_font, at, text, _candidate_px, _faded(s.candidate_crossed, alpha))
		var box: Rect2 = _mark_rects[digit - 1]
		_canvas.draw_line(corner + box.position, corner + box.end, _faded(s.cross_mark_auto, alpha), _weight(s.cross_mark_w), true)
	elif _chips[index] != 0:
		_draw_chip(corner, digit, alpha)
		_canvas.draw_char_outline(_candidate_font, at, text, _candidate_px, knockout, _faded(s.hint_cross_bg, alpha))
		_canvas.draw_char(_candidate_font, at, text, _candidate_px, _faded(s.cell_bg, alpha))
	else:
		_canvas.draw_char(_candidate_font, at, text, _candidate_px, _faded(s.candidate_open, alpha))


## The hand X: both diagonals of the mark box, scaled about the slot center.
func _draw_hand_x(corner: Vector2, digit: int, scale: float, color: Color) -> void:
	var box: Rect2 = _mark_rects[digit - 1]
	var center: Vector2 = corner + box.get_center()
	var half: Vector2 = box.size * 0.5 * scale
	var w: float = _weight(_skin.cross_mark_w)
	_canvas.draw_line(center - half, center + half, color, w, true)
	_canvas.draw_line(center + Vector2(-half.x, half.y), center + Vector2(half.x, -half.y), color, w, true)


## The hint cross chip: the slot box grown above and below, edges snapped.
func _draw_chip(corner: Vector2, digit: int, alpha: float) -> void:
	var chip: Rect2 = _chip_rects[digit - 1]
	var left: float = _snap_x(corner.x + chip.position.x)
	var top: float = _snap_y(corner.y + chip.position.y)
	var right: float = _snap_x(corner.x + chip.end.x)
	var bottom: float = _snap_y(corner.y + chip.end.y)
	_draw_rounded(Rect2(left, top, right - left, bottom - top), _faded(_skin.hint_cross_bg, alpha), _chip_radius)


func _draw_conflict_bars() -> void:
	for cell: int in CELLS:
		if _flags[cell] & F_CONFLICT:
			_draw_conflict_bar(cell)


func _draw_conflict_bar(cell: int) -> void:
	var s: GameSkin = _skin
	var w: float = _weight(s.conflict_bar_w)
	var center: Vector2 = Vector2(_cell_center(cell).x, _cell_origin(cell).y + s.conflict_bar_y * _pitch)
	var half: float = s.conflict_bar_len * _pitch * 0.5
	var left: float = _snap_x(center.x - half)
	_canvas.draw_rect(Rect2(left, _snap_y(center.y - w * 0.5), _snap_x(center.x + half) - left, w), s.conflict_mark)


## The selection frame, centered on the cell edge: solid in Place mode,
## broken in Cross Out mode with the band painted in the fill first.
func _draw_selection() -> void:
	var cell: int = _state.selected
	if cell < 0 or cell >= CELLS:
		return
	var s: GameSkin = _skin
	var w: float = _weight(s.selection_frame_w)
	var band: Rect2 = _band_rect(cell, w)
	if _state.mode != MODE_CROSS_OUT:
		_draw_band(band, w, s.selection_frame_place)
		return
	_draw_band(band, w, _fill_color(Fill.SELECTED))
	var corner_dash: float = (1.0 - s.selection_mid_dash - 2.0 * s.selection_gap) * 0.5
	_draw_corner_arms(cell, band, w, corner_dash, s.selection_frame_cross)
	_draw_side_ticks(cell, band, w, s.selection_mid_dash, s.selection_frame_cross)


## Hint ticks on reason and lesson marked cells, then hint brackets on
## targets, so brackets end on top.
func _draw_hint_marks() -> void:
	var s: GameSkin = _skin
	var w: float = _weight(s.hint_mark_w)
	for cell: int in CELLS:
		if _flags[cell] & F_REASON:
			_draw_side_ticks(cell, _band_rect(cell, w), w, s.hint_tick_len, s.hint_reason_mark)
	for cell: int in CELLS:
		if _flags[cell] & F_TARGET:
			_draw_corner_arms(cell, _band_rect(cell, w), w, s.hint_bracket_len, s.hint_target_mark)


## The outside of a band of weight w centered on the cell's edges.
func _band_rect(cell: int, w: float) -> Rect2:
	var origin: Vector2 = _cell_origin(cell)
	var left: float = _snap_x(origin.x - w * 0.5)
	var top: float = _snap_y(origin.y - w * 0.5)
	var right: float = _snap_x(origin.x + _pitch - w * 0.5) + w
	var bottom: float = _snap_y(origin.y + _pitch - w * 0.5) + w
	return Rect2(left, top, right - left, bottom - top)


## All four sides of a band.
func _draw_band(band: Rect2, w: float, color: Color) -> void:
	_canvas.draw_rect(Rect2(band.position.x, band.position.y, band.size.x, w), color)
	_canvas.draw_rect(Rect2(band.position.x, band.end.y - w, band.size.x, w), color)
	_canvas.draw_rect(Rect2(band.position.x, band.position.y, w, band.size.y), color)
	_canvas.draw_rect(Rect2(band.end.x - w, band.position.y, w, band.size.y), color)


## An L at every corner of the band, each arm reaching share of the side from
## the cell corner (plus the half weight past the corner that closes the L).
func _draw_corner_arms(cell: int, band: Rect2, w: float, share: float, color: Color) -> void:
	var origin: Vector2 = _cell_origin(cell)
	var arm_x: float = _snap_x(origin.x + share * _pitch) - band.position.x
	var arm_y: float = _snap_y(origin.y + share * _pitch) - band.position.y
	var p: Vector2 = band.position
	var e: Vector2 = band.end
	var right_arm: float = e.x - _snap_x(origin.x + (1.0 - share) * _pitch)
	var bottom_arm: float = e.y - _snap_y(origin.y + (1.0 - share) * _pitch)
	# Top left, top right, bottom left, bottom right.
	_canvas.draw_rect(Rect2(p.x, p.y, arm_x, w), color)
	_canvas.draw_rect(Rect2(p.x, p.y, w, arm_y), color)
	_canvas.draw_rect(Rect2(e.x - right_arm, p.y, right_arm, w), color)
	_canvas.draw_rect(Rect2(e.x - w, p.y, w, arm_y), color)
	_canvas.draw_rect(Rect2(p.x, e.y - w, arm_x, w), color)
	_canvas.draw_rect(Rect2(p.x, e.y - bottom_arm, w, bottom_arm), color)
	_canvas.draw_rect(Rect2(e.x - right_arm, e.y - w, right_arm, w), color)
	_canvas.draw_rect(Rect2(e.x - w, e.y - bottom_arm, w, bottom_arm), color)


## A dash centered on each side of the band, share of the side long.
func _draw_side_ticks(cell: int, band: Rect2, w: float, share: float, color: Color) -> void:
	var center: Vector2 = _cell_center(cell)
	var half: float = share * _pitch * 0.5
	var x0: float = _snap_x(center.x - half)
	var x1: float = _snap_x(center.x + half)
	var y0: float = _snap_y(center.y - half)
	var y1: float = _snap_y(center.y + half)
	_canvas.draw_rect(Rect2(x0, band.position.y, x1 - x0, w), color)
	_canvas.draw_rect(Rect2(x0, band.end.y - w, x1 - x0, w), color)
	_canvas.draw_rect(Rect2(band.position.x, y0, w, y1 - y0), color)
	_canvas.draw_rect(Rect2(band.end.x - w, y0, w, y1 - y0), color)


# Effects

## PLACE: the ring fades out over the first 80 ms while the digit scales from
## 0.6 to 1 and fades in.
func _draw_place_effect(effect: CellEffect) -> void:
	var cell: int = effect.cell
	if effect.digit < 1 or effect.digit > 9:
		return
	var p: float = effect.progress
	_cover_cell(cell)
	var ring_alpha: float = 1.0 - clampf(p / PLACE_RING_SHARE, 0.0, 1.0)
	if ring_alpha > 0.0:
		_draw_ring_faded(cell, ring_alpha)
	_with_scale(_cell_center(cell), lerpf(PLACE_FROM_SCALE, 1.0, p))
	_draw_digit(cell, effect.digit, _digit_color(cell, effect.digit), clampf(p, 0.0, 1.0))
	_push_pixels()
	_redraw_conflict_bar(cell)


## ERASE: the digit scales to 0.8 and fades out while the ring fades in over
## 120 ms from the start.
func _draw_erase_effect(effect: CellEffect) -> void:
	var cell: int = effect.cell
	if effect.digit < 1 or effect.digit > 9:
		return
	var p: float = effect.progress
	_cover_cell(cell)
	var ring_alpha: float = clampf(p / ERASE_RING_SHARE, 0.0, 1.0)
	if ring_alpha > 0.0 and _digit(cell) == 0:
		_draw_ring_faded(cell, ring_alpha)
	_with_scale(_cell_center(cell), lerpf(1.0, ERASE_TO_SCALE, p))
	_draw_digit(cell, effect.digit, _skin.digit_placed, 1.0 - clampf(p, 0.0, 1.0))
	_push_pixels()
	_redraw_conflict_bar(cell)


## CROSS: the hand X scales from 1.3 to 1 and fades in, the digit is gray at
## once. RESTORE: the hand X scales to 0.8 and fades out, the digit is open
## at once. Both redraw the slot as the board shows it now, the X animated.
func _draw_mark_effect(effect: CellEffect) -> void:
	var cell: int = effect.cell
	var digit: int = effect.digit
	if digit < 1 or digit > 9 or _digit(cell) != 0:
		return
	var s: GameSkin = _skin
	var p: float = effect.progress
	var crossing: bool = effect.kind == CellEffect.Kind.CROSS
	var corner: Vector2 = _ring_corner(cell)
	var fill: Color = _fill_color(_fills[cell])
	var slot: Rect2 = _slot_rects[digit - 1]
	var cover: Rect2 = Rect2(corner + slot.position, slot.size).grow(1.0)
	if _chips[cell * 9 + digit - 1] != 0:
		cover = cover.merge(Rect2(corner + _chip_rects[digit - 1].position, _chip_rects[digit - 1].size).grow(1.0))
	_canvas.draw_rect(cover, fill)
	var mark: int = _mark(cell * 9 + digit - 1)
	var open_look: bool = mark == MARK_OPEN or mark == MARK_RESTORED_HAND
	if not crossing and open_look and _chips[cell * 9 + digit - 1] != 0:
		_draw_chip(corner, digit, 1.0)
	var x_scale: float = lerpf(CROSS_FROM_SCALE, 1.0, p) if crossing else lerpf(1.0, RESTORE_TO_SCALE, p)
	var x_alpha: float = clampf(p, 0.0, 1.0) if crossing else 1.0 - clampf(p, 0.0, 1.0)
	_draw_hand_x(corner, digit, x_scale, _faded(s.cross_mark_hand, x_alpha))
	var text: String = DIGIT_TEXT[digit]
	var at: Vector2 = corner + _candidate_origin[digit - 1]
	var digit_color: Color = s.candidate_crossed if crossing else s.candidate_open
	var outline: Color = fill
	if not crossing and open_look and _chips[cell * 9 + digit - 1] != 0:
		digit_color = s.cell_bg
		outline = s.hint_cross_bg
	_canvas.draw_char_outline(_candidate_font, at, text, _candidate_px, _knockout_px(), outline)
	_canvas.draw_char(_candidate_font, at, text, _candidate_px, digit_color)


## COMPLETE: the digit scales to 1.08 and back.
func _draw_complete_effect(effect: CellEffect) -> void:
	var cell: int = effect.cell
	var digit: int = _digit(cell)
	if digit == 0:
		digit = effect.digit
	if digit < 1 or digit > 9:
		return
	_cover_cell(cell)
	_with_scale(_cell_center(cell), 1.0 + COMPLETE_GROWTH * sin(PI * clampf(effect.progress, 0.0, 1.0)))
	_draw_digit(cell, digit, _digit_color(cell, digit), 1.0)
	_push_pixels()
	_redraw_conflict_bar(cell)


## Paints the inside of a cell in its fill, short of the frame and hint marks.
func _cover_cell(cell: int) -> void:
	var s: GameSkin = _skin
	var inset: float = ceilf(maxf(s.selection_frame_w, s.hint_mark_w) * 0.5 * _scale)
	_canvas.draw_rect(_cell_px(cell).grow(-inset), _fill_color(_fills[cell]))


func _draw_ring_faded(cell: int, alpha: float) -> void:
	var corner: Vector2 = _ring_corner(cell)
	var fill: Color = _fill_color(_fills[cell])
	for d: int in range(1, 10):
		_draw_candidate(cell, d, corner, fill, alpha)


func _redraw_conflict_bar(cell: int) -> void:
	if _flags[cell] & F_CONFLICT:
		_draw_conflict_bar(cell)


# Helpers

## From here on, draw in device pixels relative to the canvas origin.
func _push_pixels() -> void:
	var k: float = 1.0 / _scale
	_canvas.draw_set_transform_matrix(Transform2D(Vector2(k, 0.0), Vector2(0.0, k), Vector2.ZERO))


## Device pixels, scaled by factor about center (in pixels). _push_pixels()
## undoes it.
func _with_scale(center: Vector2, factor: float) -> void:
	var k: float = factor / _scale
	_canvas.draw_set_transform_matrix(Transform2D(Vector2(k, 0.0), Vector2(0.0, k), center * (1.0 - factor) / _scale))


func _pop_pixels() -> void:
	_canvas.draw_set_transform_matrix(Transform2D.IDENTITY)


func _digit(cell: int) -> int:
	if _state == null or _state.digits.size() != CELLS:
		return 0
	var d: int = _state.digits[cell]
	return d if d >= 1 and d <= 9 else 0


func _is_given(cell: int) -> bool:
	return _state != null and _state.givens.size() == CELLS and _state.givens[cell] != 0


func _mark(index: int) -> int:
	if _state == null or _state.marks.size() != MARKS:
		return MARK_OPEN
	return _state.marks[index]


func _digit_color(cell: int, digit: int) -> Color:
	if _digit(cell) == digit:
		if _flags[cell] & F_CONFLICT:
			return _skin.digit_conflict
		if _is_given(cell):
			return _skin.digit_given
	return _skin.digit_placed


func _fill_color(fill: int) -> Color:
	match fill:
		Fill.SELECTED:
			return _skin.cell_selected_bg
		Fill.CONFLICT:
			return _skin.cell_conflict_bg
		Fill.HINT_TARGET:
			return _skin.cell_hint_target_bg
		Fill.HINT_REASON:
			return _skin.cell_hint_reason_bg
		Fill.SAME_DIGIT:
			return _skin.cell_same_digit_bg
		Fill.PEER:
			return _skin.cell_peer_bg
	return _skin.cell_bg


## The cell's top left corner in pixels, unsnapped.
func _cell_origin(cell: int) -> Vector2:
	return _square.position + Vector2(float(cell % 9), float(cell / 9)) * _pitch


func _cell_center(cell: int) -> Vector2:
	return _cell_origin(cell) + Vector2(_pitch, _pitch) * 0.5


func _ring_corner(cell: int) -> Vector2:
	return _cell_origin(cell) + Vector2(_ring_inset_px, _ring_inset_px)


## The cell between its snapped edges.
func _cell_px(cell: int) -> Rect2:
	var col: int = cell % 9
	var row: int = cell / 9
	return Rect2(_edge_x[col], _edge_y[row], _edge_x[col + 1] - _edge_x[col], _edge_y[row + 1] - _edge_y[row])


func _board_rect() -> Rect2:
	return Rect2(_edge_x[0], _edge_y[0], _edge_x[9] - _edge_x[0], _edge_y[9] - _edge_y[0])


## The outside of the outer line, which is centered on the board edge.
func _outer_rect() -> Rect2:
	var w: float = _weight(_skin.line_outer_w)
	var left: float = _snap_x(_square.position.x - w * 0.5)
	var top: float = _snap_y(_square.position.y - w * 0.5)
	var right: float = _snap_x(_square.end.x - w * 0.5) + w
	var bottom: float = _snap_y(_square.end.y - w * 0.5) + w
	return Rect2(left, top, right - left, bottom - top)


func _draw_rounded(rect: Rect2, color: Color, radius: float) -> void:
	_style.bg_color = color
	_style.draw_center = true
	_style.set_border_width_all(0)
	_style.set_corner_radius_all(roundi(radius))
	_style.anti_aliasing = radius > 0.0
	_canvas.draw_style_box(_style, rect)


## A stroke weight in pixels: whole pixels, at least one, when snapping.
func _weight(dp: float) -> float:
	var px: float = dp * _scale
	return maxf(1.0, roundf(px)) if _snap else maxf(1.0, px)


func _knockout_px() -> int:
	return maxi(1, roundi(_skin.knockout_w * _scale))


func _snap_x(x: float) -> float:
	return roundf(x + _origin.x) - _origin.x if _snap else x


func _snap_y(y: float) -> float:
	return roundf(y + _origin.y) - _origin.y if _snap else y


func _faded(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * alpha)


## Godot's built-in font with an embolden, one FontVariation per value.
func _font(embolden: float) -> Font:
	var key: String = "%.4f" % embolden
	if _fonts.has(key):
		return _fonts[key]
	var variation: FontVariation = FontVariation.new()
	variation.base_font = ThemeDB.fallback_font
	variation.variation_embolden = embolden
	_fonts[key] = variation
	return variation


## The ink box of a digit drawn at size, relative to the baseline origin
## draw_char() takes, measured from the glyph's real shape.
func _ink_box(font: Font, size: int, digit: int) -> Rect2:
	var key: String = "%d|%d|%d" % [font.get_instance_id(), size, digit]
	if _ink_boxes.has(key):
		return _ink_boxes[key]
	var box: Rect2 = Rect2()
	var found: bool = false
	var server: TextServer = TextServerManager.get_primary_interface()
	var code: int = DIGIT_TEXT[digit].unicode_at(0)
	for rid: RID in font.get_rids():
		var glyph: int = server.font_get_glyph_index(rid, size, code, 0)
		if glyph == 0:
			continue
		var size_key: Vector2i = Vector2i(size, 0)
		var glyph_size: Vector2 = server.font_get_glyph_size(rid, size_key, glyph)
		if glyph_size.x > 0.0 and glyph_size.y > 0.0:
			box = Rect2(server.font_get_glyph_offset(rid, size_key, glyph), glyph_size)
			found = true
		break
	if not found:
		var line: Vector2 = font.get_string_size(DIGIT_TEXT[digit], HORIZONTAL_ALIGNMENT_LEFT, -1, size)
		box = Rect2(0.0, -font.get_ascent(size), line.x, line.y)
	_ink_boxes[key] = box
	return box


## The widest and the tallest ink box among the digits 1 to 9.
func _digit_cell(font: Font, size: int) -> Vector2:
	var cell: Vector2 = Vector2.ZERO
	for d: int in range(1, 10):
		var box: Rect2 = _ink_box(font, size, d)
		cell = Vector2(maxf(cell.x, box.size.x), maxf(cell.y, box.size.y))
	return cell
