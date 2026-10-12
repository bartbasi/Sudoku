extends "res://tests/unit_test.gd"
## BoardPainter geometry: board_square, cell_rect and cell_at (including the
## box lines, which belong to the cells on either side), and the ring layout
## the painter builds for a cell (layout A, reading rows).

const POP_LIGHT_PATH: String = "res://src/skins/pop_light.tres"

## The judged screen (DESIGN_SYSTEM.md 3.4 and 4.10): a 337 dp board.
const JUDGED_BOARD_DP: float = 337.0
const DENSITIES: Array[float] = [1.0, 2.0, 2.625, 3.0]


func _skin() -> GameSkin:
	return load(POP_LIGHT_PATH) as GameSkin


func test_board_square_is_the_largest_centered_square() -> void:
	assert_eq(BoardPainter.board_square(Rect2(10, 20, 400, 300)), Rect2(60, 20, 300, 300), "wide rect")
	assert_eq(BoardPainter.board_square(Rect2(0, 0, 360, 800)), Rect2(0, 220, 360, 360), "tall rect")
	assert_eq(BoardPainter.board_square(Rect2(5, 5, 100, 100)), Rect2(5, 5, 100, 100), "square")
	assert_eq(BoardPainter.board_square(Rect2(0, 0, 0, 50)).size, Vector2.ZERO, "empty rect")


func test_cell_rect_tiles_the_square_in_reading_order() -> void:
	var square: Rect2 = Rect2(12, 30, 360, 360)
	var skin: GameSkin = _skin()
	for cell: int in 81:
		var rect: Rect2 = BoardPainter.cell_rect(square, cell, skin)
		var expected: Rect2 = Rect2(12.0 + float(cell % 9) * 40.0, 30.0 + float(cell / 9) * 40.0, 40.0, 40.0)
		if not rect.is_equal_approx(expected):
			fail("cell %d is %s, expected %s" % [cell, rect, expected])
	assert_eq(BoardPainter.cell_rect(square, 0, skin).position, square.position, "cell 0 at the top left")
	assert_true(BoardPainter.cell_rect(square, 80, skin).end.is_equal_approx(square.end), "cell 80 ends at the bottom right")
	assert_eq(BoardPainter.cell_rect(square, -1, skin), Rect2(), "cell -1")
	assert_eq(BoardPainter.cell_rect(square, 81, skin), Rect2(), "cell 81")


func test_cell_at_finds_every_cell_center() -> void:
	var square: Rect2 = Rect2(3.5, 41.25, 337, 337)
	var skin: GameSkin = _skin()
	for cell: int in 81:
		var center: Vector2 = BoardPainter.cell_rect(square, cell, skin).get_center()
		assert_eq(BoardPainter.cell_at(square, center, skin), cell, "center of cell %d" % cell)


func test_cell_at_splits_box_lines_and_cell_lines_at_their_center() -> void:
	# A line is centered on the edge between two cells. Every point of it,
	# box lines included, belongs to the cell on its side of the center: no
	# gap between cells returns -1.
	var square: Rect2 = Rect2(0, 0, 360, 360)
	var skin: GameSkin = _skin()
	var pitch: float = 40.0
	for edge: int in range(1, 9):
		var at: float = float(edge) * pitch
		var half: float = (skin.line_box_w if edge % 3 == 0 else skin.line_cell_w) * 0.5
		for row: int in 9:
			var y: float = (float(row) + 0.5) * pitch
			var left_cell: int = row * 9 + edge - 1
			assert_eq(BoardPainter.cell_at(square, Vector2(at - half, y), skin), left_cell, "left half of vertical line %d, row %d" % [edge, row])
			assert_eq(BoardPainter.cell_at(square, Vector2(at - 0.001, y), skin), left_cell, "just left of line %d center" % edge)
			assert_eq(BoardPainter.cell_at(square, Vector2(at, y), skin), left_cell + 1, "line %d center" % edge)
			assert_eq(BoardPainter.cell_at(square, Vector2(at + half, y), skin), left_cell + 1, "right half of vertical line %d" % edge)
		for col: int in 9:
			var x: float = (float(col) + 0.5) * pitch
			var upper_cell: int = (edge - 1) * 9 + col
			assert_eq(BoardPainter.cell_at(square, Vector2(x, at - half), skin), upper_cell, "upper half of horizontal line %d" % edge)
			assert_eq(BoardPainter.cell_at(square, Vector2(x, at + half), skin), upper_cell + 9, "lower half of horizontal line %d" % edge)
	# Where two box lines cross.
	assert_eq(BoardPainter.cell_at(square, Vector2(119.5, 119.5), skin), 20, "box corner, top left side")
	assert_eq(BoardPainter.cell_at(square, Vector2(120.5, 120.5), skin), 30, "box corner, bottom right side")


func test_cell_at_is_minus_one_outside_the_board() -> void:
	var square: Rect2 = Rect2(10, 10, 360, 360)
	var skin: GameSkin = _skin()
	var outside: Array[Vector2] = [
		Vector2(9.99, 100), Vector2(100, 9.99), Vector2(370, 100), Vector2(100, 370),
		Vector2(-5, -5), Vector2(400, 400), Vector2(370, 370),
	]
	for point: Vector2 in outside:
		assert_eq(BoardPainter.cell_at(square, point, skin), -1, "point %s" % point)
	assert_eq(BoardPainter.cell_at(square, Vector2(10, 10), skin), 0, "the top left corner is cell 0")
	assert_eq(BoardPainter.cell_at(square, Vector2(369.99, 369.99), skin), 80, "just inside the bottom right corner")
	assert_eq(BoardPainter.cell_at(Rect2(0, 0, 0, 0), Vector2.ZERO, skin), -1, "empty square")


func test_ring_layout_a_keeps_every_digit_in_its_slot() -> void:
	for density: float in DENSITIES:
		var probe: Probe = Probe.new(density)
		var painter: BoardPainter = probe.begin(_skin(), JUDGED_BOARD_DP)
		if painter == null:
			fail("painter did not start at density %.3f" % density)
			probe.free_all()
			continue
		var slots: Array[Rect2] = painter._slot_rects
		var label: String = "density %.3f" % density
		assert_eq(slots.size(), 9, label)
		if slots.size() == 9:
			var ring_side: float = painter._pitch - 2.0 * painter._ring_inset_px
			var ring: Rect2 = Rect2(Vector2.ZERO, Vector2(ring_side, ring_side))
			# Rows: 1 2 3 4 / 5 . 6 / 7 8 9, left to right and top to bottom.
			for row: Array in [[1, 2, 3, 4], [5, 6], [7, 8, 9]]:
				for i: int in range(1, row.size()):
					var a: Rect2 = slots[row[i - 1] - 1]
					var b: Rect2 = slots[row[i] - 1]
					assert_true(is_equal_approx(a.get_center().y, b.get_center().y), "%s: %d and %d share a row" % [label, row[i - 1], row[i]])
					if density >= 2.0:
						assert_true(b.position.x >= a.end.x, "%s: slots %d and %d do not overlap" % [label, row[i - 1], row[i]])
			assert_true(slots[0].end.y < slots[4].position.y and slots[4].end.y < slots[6].position.y, "%s: the rows do not overlap" % label)
			assert_true(is_equal_approx(slots[0].position.x, 0.0) and is_equal_approx(slots[3].end.x, ring_side), "%s: the top row runs edge to edge" % label)
			for d: int in range(1, 10):
				assert_true(ring.grow(0.01).encloses(slots[d - 1]), "%s: slot %d inside the ring box" % [label, d])
				assert_true(slots[d - 1].encloses(painter._mark_rects[d - 1]), "%s: mark box %d inside its slot" % [label, d])
				assert_false(slots[d - 1].has_point(ring.get_center()), "%s: slot %d leaves the center open" % [label, d])
			# Chips in neighboring rows never touch (judged densities).
			for upper: int in ([1, 5] if density >= 2.0 else []):
				var lower: int = 5 if upper == 1 else 7
				assert_true(painter._chip_rects[lower - 1].position.y - painter._chip_rects[upper - 1].end.y >= 1.0,
					"%s: chips of rows with %d and %d stay 1 px apart" % [label, upper, lower])
			# The candidate size is the one the contrast checker computes: ink
			# boxes measured at 100 px and scaled, rounded down.
			var unit100: Vector2 = painter._digit_cell(painter._candidate_font, 100) / 100.0
			var gap: float = painter._skin.candidate_gap
			var fit: float = minf(ring_side / (4.0 * unit100.x + 3.0 * gap), ring_side / (3.0 * unit100.y + 2.0 * gap))
			assert_eq(painter._candidate_px, maxi(1, floori(fit)), "%s: candidate size" % label)
		probe.free_all()


func test_judged_screen_meets_the_candidate_floor() -> void:
	# DESIGN_SYSTEM.md 3.4: at least 11 dp, tallest ink at least 8.5 dp, and
	# the sizes it publishes: 23 px at density 2, 31 at 2.625, 35 at 3.
	var published: Dictionary[float, int] = {2.0: 23, 2.625: 31, 3.0: 35}
	for density: float in [2.0, 2.625, 3.0]:
		var probe: Probe = Probe.new(density)
		var painter: BoardPainter = probe.begin(_skin(), JUDGED_BOARD_DP)
		if painter != null:
			assert_eq(painter._candidate_px, published[density], "density %.3f: candidate px" % density)
			var size_dp: float = float(painter._candidate_px) / density
			var ink_dp: float = painter._digit_cell(painter._candidate_font, painter._candidate_px).y / density
			assert_true(size_dp >= 11.0, "density %.3f: candidates %.2f dp" % [density, size_dp])
			assert_true(ink_dp >= 8.5, "density %.3f: tallest candidate ink %.2f dp" % [density, ink_dp])
		else:
			fail("painter did not start at density %.3f" % density)
		probe.free_all()


func test_strokes_snap_to_whole_pixels_and_box_lines_read_heavier() -> void:
	var skin: GameSkin = _skin()
	for density: float in [2.0, 2.625, 3.0]:
		var probe: Probe = Probe.new(density)
		var painter: BoardPainter = probe.begin(skin, JUDGED_BOARD_DP)
		if painter == null:
			fail("painter did not start at density %.3f" % density)
			probe.free_all()
			continue
		assert_true(painter._snap, "density %.3f snaps" % density)
		assert_true(is_equal_approx(painter._scale, density), "density %.3f: scale %.3f" % [density, painter._scale])
		var cell_w: float = painter._weight(skin.line_cell_w)
		var box_w: float = painter._weight(skin.line_box_w)
		assert_eq(cell_w, roundf(cell_w), "whole pixel cell line")
		assert_eq(box_w, roundf(box_w), "whole pixel box line")
		assert_true(box_w >= 2.5 * cell_w, "density %.3f: box line %d px against cell line %d px" % [density, int(box_w), int(cell_w)])
		for i: int in 10:
			var device_x: float = painter._edge_x[i] + painter._origin.x
			assert_true(is_equal_approx(device_x, roundf(device_x)), "edge %d on a whole pixel" % i)
		probe.free_all()


func test_cell_effect_kinds_match_the_contract() -> void:
	assert_eq(CellEffect.Kind.PLACE, 0)
	assert_eq(CellEffect.Kind.ERASE, 1)
	assert_eq(CellEffect.Kind.CROSS, 2)
	assert_eq(CellEffect.Kind.RESTORE, 3)
	assert_eq(CellEffect.Kind.COMPLETE, 4)


func test_painter_mark_and_mode_values_match_core() -> void:
	# core is built in parallel. Compare with Board.Mark and GameSession.Mode
	# once they exist, without a compile time dependency.
	var expected_marks: Dictionary = {"OPEN": BoardPainter.MARK_OPEN, "CROSSED_HAND": BoardPainter.MARK_CROSSED_HAND,
		"RESTORED_HAND": BoardPainter.MARK_RESTORED_HAND, "CROSSED_AUTO": BoardPainter.MARK_CROSSED_AUTO}
	var board_marks: Dictionary = _enum_of("Board", "Mark")
	if not board_marks.is_empty():
		for key: String in expected_marks:
			assert_eq(board_marks.get(key, -1), expected_marks[key], "Board.Mark.%s" % key)
	var modes: Dictionary = _enum_of("GameSession", "Mode")
	if not modes.is_empty():
		assert_eq(modes.get("CROSS_OUT", -1), BoardPainter.MODE_CROSS_OUT, "GameSession.Mode.CROSS_OUT")


func _enum_of(class_title: String, enum_name: String) -> Dictionary:
	for info: Dictionary in ProjectSettings.get_global_class_list():
		if info["class"] == StringName(class_title):
			var script: Script = load(info["path"]) as Script
			if script == null:
				return {}
			var constants: Dictionary = script.get_script_constant_map()
			var value: Variant = constants.get(enum_name, {})
			return value if value is Dictionary else {}
	return {}


## A canvas whose device transform is that of a phone of the given density,
## at a fractional pixel offset, so the painter sees that many device pixels
## per unit and has to snap.
class Probe:
	var density: float
	var canvas: Node2D = Node2D.new()
	var painter: BoardPainter = BoardPainter.new()

	func _init(pixels_per_unit: float) -> void:
		density = pixels_per_unit

	func begin(skin: GameSkin, board_dp: float) -> BoardPainter:
		var to_device: Transform2D = Transform2D(Vector2(density, 0.0), Vector2(0.0, density), Vector2(7.3, 11.6))
		if skin == null or not painter._begin_with(canvas, to_device, Rect2(Vector2(4, 4), Vector2(board_dp, board_dp)), skin):
			return null
		return painter

	func free_all() -> void:
		canvas.free()
