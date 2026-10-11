extends Control
## Placeholder screen that proves the capture tool works before the artists'
## scenes exist. It follows the screen contract in the artist briefs (a Control
## root with dark and ring_layout set before it enters the tree) and draws the
## close-up box in every ring layout at true size, as a check of the ring
## geometry. Not a design direction. Owner: senior-graphic-designer.

const Palettes := preload("res://tools/design/directions/palettes.gd")
const RingLayouts := preload("res://tools/design/directions/ring_layouts.gd")
const SampleState := preload("res://tools/design/directions/sample_state.gd")
const Fonts := preload("res://tools/design/directions/fonts.gd")
const Device := preload("res://tools/design/directions/device.gd")

const DIRECTION: String = "gridline"

var dark: bool = false
var ring_layout: int = RingLayouts.DEFAULT_LAYOUT

var _colors: Palettes.Palette
var _shape: Palettes.Shape
var _board: SampleState.BoardState


func _ready() -> void:
	_colors = Palettes.palette(DIRECTION, dark)
	_shape = Palettes.shape(DIRECTION)
	_board = SampleState.closeup_board()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _colors.app_bg)
	# Safe area guides.
	var safe: Rect2 = Device.safe_rect(size)
	draw_rect(Rect2(0.0, 0.0, size.x, safe.position.y), _colors.surface_alt)
	draw_rect(Rect2(0.0, safe.end.y, size.x, size.y - safe.end.y), _colors.surface_alt)

	var title: Palettes.TypeStyle = Palettes.type_style(DIRECTION, Palettes.ROLE_TITLE)
	var body: Palettes.TypeStyle = Palettes.type_style(DIRECTION, Palettes.ROLE_BODY)
	var label: Palettes.TypeStyle = Palettes.type_style(DIRECTION, Palettes.ROLE_LABEL)
	var x: float = _shape.screen_margin
	var y: float = safe.position.y + 80.0
	draw_string(title.font(), Vector2(x, y), "Capture test", HORIZONTAL_ALIGNMENT_LEFT, -1, title.font_size(), _colors.text)
	y += 60.0
	var mode: String = "dark" if dark else "light"
	var line: String = "Not a direction. Font: %s. Colors: %s %s." % [Fonts.family(), DIRECTION, mode]
	draw_string(body.font(), Vector2(x, y), line, HORIZONTAL_ALIGNMENT_LEFT, size.x - 2.0 * x, body.font_size(), _colors.text_muted)
	y += 40.0

	# The close-up box in each ring layout, at true size on a 1080 px phone.
	var pitch: float = _shape.board_size / 9.0
	for layout: int in RingLayouts.COUNT:
		y += 70.0
		var caption: String = RingLayouts.NAMES[layout] + ("  (screens use this one)" if layout == ring_layout else "")
		draw_string(label.font(), Vector2(x, y), label.apply(caption), HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size(), _colors.text)
		y += 20.0
		_draw_box(Vector2(x, y), layout)
		y += pitch * 3.0 + 10.0


## Draws the close-up box with its top-left corner at origin.
func _draw_box(origin: Vector2, layout: int) -> void:
	var box: int = SampleState.CLOSEUP_BOX
	var first_row: int = (box / 3) * 3
	var first_col: int = (box % 3) * 3
	var pitch: float = _shape.board_size / 9.0
	var board_rect: Rect2 = Rect2(origin - Vector2(first_col, first_row) * pitch, Vector2(_shape.board_size, _shape.board_size))
	var candidate_font: Font = Palettes.type_style(DIRECTION, Palettes.ROLE_CANDIDATE).font_at(40.0)
	var given_style: Palettes.TypeStyle = Palettes.type_style(DIRECTION, Palettes.ROLE_GIVEN)
	var placed_style: Palettes.TypeStyle = Palettes.type_style(DIRECTION, Palettes.ROLE_PLACED)
	var ring_side: float = RingLayouts.ring_side(DIRECTION)
	var candidate_size: int = RingLayouts.candidate_font_size(DIRECTION, layout, ring_side, candidate_font)
	candidate_font = Palettes.type_style(DIRECTION, Palettes.ROLE_CANDIDATE).font_at(float(candidate_size))
	for r: int in range(first_row, first_row + 3):
		for c: int in range(first_col, first_col + 3):
			var index: int = r * 9 + c
			var cell: Rect2 = RingLayouts.cell_rect(DIRECTION, board_rect, index)
			draw_rect(cell, _bg_color(_board.cell_bg(index)))
			var digit: int = _board.digit_at(index)
			if digit != 0:
				var style: Palettes.TypeStyle = given_style if _board.is_given(index) else placed_style
				var digit_size: int = roundi(style.size * pitch)
				var color: Color = _colors.digit_given if _board.is_given(index) else _colors.digit_placed
				Fonts.draw_centered(self, style.font_at(float(digit_size)), digit_size, str(digit), cell.get_center(), color)
				continue
			var ring: Rect2 = RingLayouts.ring_box(DIRECTION, board_rect, index)
			for d: int in range(1, 10):
				var center: Vector2 = RingLayouts.slot_center(layout, d, ring, candidate_font, candidate_size)
				var hand: bool = _board.is_crossed(index, d)
				var auto: bool = _board.is_auto_crossed(index, d)
				var color: Color = _colors.candidate_crossed if hand or auto else _colors.candidate_open
				Fonts.draw_centered(self, candidate_font, candidate_size, str(d), center, color)
				var slot: Rect2 = RingLayouts.mark_rect(DIRECTION, layout, d, ring, candidate_font, candidate_size)
				if hand:
					draw_line(slot.position, slot.end, _colors.x_mark, _shape.x_stroke_w, true)
					draw_line(Vector2(slot.end.x, slot.position.y), Vector2(slot.position.x, slot.end.y), _colors.x_mark, _shape.x_stroke_w, true)
				elif auto:
					draw_line(Vector2(slot.position.x, slot.end.y), Vector2(slot.end.x, slot.position.y), _colors.x_mark_auto, _shape.x_stroke_w, true)
	# Lines: cell lines, then the box outline.
	var box_rect: Rect2 = Rect2(origin, Vector2(pitch, pitch) * 3.0)
	for k: int in range(1, 3):
		var offset: float = pitch * float(k)
		draw_line(box_rect.position + Vector2(offset, 0.0), box_rect.position + Vector2(offset, box_rect.size.y), _colors.line_cell, _shape.line_cell_w)
		draw_line(box_rect.position + Vector2(0.0, offset), box_rect.position + Vector2(box_rect.size.x, offset), _colors.line_cell, _shape.line_cell_w)
	draw_rect(box_rect, _colors.line_box, false, _shape.line_box_w)
	# Selection frame, dashed for Cross Out mode.
	if _board.selected >= 0:
		var sel: Rect2 = RingLayouts.cell_rect(DIRECTION, board_rect, _board.selected)
		var corners: PackedVector2Array = PackedVector2Array([sel.position, Vector2(sel.end.x, sel.position.y), sel.end, Vector2(sel.position.x, sel.end.y), sel.position])
		for i: int in 4:
			if _board.mode == SampleState.MODE_CROSS_OUT:
				draw_dashed_line(corners[i], corners[i + 1], _colors.selected_outline, _shape.selected_outline_w, _shape.selected_dash, false)
			else:
				draw_line(corners[i], corners[i + 1], _colors.selected_outline, _shape.selected_outline_w)


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
