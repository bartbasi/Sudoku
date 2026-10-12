extends "res://tests/unit_test.gd"
## The placeholder app icon script loads with its five functions, every layer
## draws at every size we render, the adaptive foreground and monochrome
## layers stay inside the Android safe zone, the foreground is the white
## square with a 3 by 3 box and a lemon center cell, the monochrome layer is
## one color with the cells cut out, and the same rect always gives the same
## shapes.

const ICON_PATH: String = "res://src/design/app_icon.gd"
const AppIcon := preload("res://src/design/app_icon.gd")

const FUNCTIONS: Array[String] = [
	"draw_full", "draw_background", "draw_foreground", "draw_monochrome", "foreground_outline",
]
const DRAW_FUNCTIONS: Array[String] = ["draw_full", "draw_background", "draw_foreground", "draw_monochrome"]

## Safe zone radius as a share of the 108 dp layer side.
const SAFE_RADIUS_SHARE: float = 33.0 / 108.0
const TOLERANCE_PX: float = 0.5
const SIDES: Array[float] = [48.0, 108.0, 432.0, 512.0]


func test_script_loads_with_all_functions() -> void:
	var script: GDScript = load(ICON_PATH) as GDScript
	assert_true(script != null and script.can_instantiate(), "app_icon.gd loads")
	if script == null:
		return
	var icon: Object = script.new()
	for method: String in FUNCTIONS:
		assert_true(icon.has_method(method), "app_icon.gd has %s" % method)


func test_every_layer_draws_at_every_size() -> void:
	var icon: Object = AppIcon.new()
	var canvas: Control = Control.new()
	for side: float in SIDES:
		for method: String in DRAW_FUNCTIONS:
			icon.call(method, canvas, Rect2(5.0, 9.0, side, side))
		RenderingServer.canvas_item_clear(canvas.get_canvas_item())
	canvas.free()
	for side: float in SIDES:
		var rect: Rect2 = Rect2(0.0, 0.0, side, side)
		assert_true(AppIcon._background_fills(rect).size() > 0, "side %d: background has shapes" % side)
		assert_true(AppIcon._foreground_fills(rect).size() > 0, "side %d: foreground has shapes" % side)
		assert_true(AppIcon._monochrome_fills(rect).size() > 0, "side %d: monochrome has shapes" % side)


func test_foreground_inside_safe_zone() -> void:
	for side: float in SIDES:
		_check_safe_zone(Rect2(0.0, 0.0, side, side))


func test_foreground_inside_safe_zone_when_rect_is_offset() -> void:
	_check_safe_zone(Rect2(37.0, 210.0, 108.0, 108.0))


func test_foreground_is_a_centered_square() -> void:
	for side: float in SIDES:
		var rect: Rect2 = Rect2(0.0, 0.0, side, side)
		var points: PackedVector2Array = AppIcon.foreground_outline(rect)
		var box: Rect2 = Rect2(points[0], Vector2.ZERO)
		for point: Vector2 in points:
			box = box.expand(point)
		assert_true(absf(box.size.x - box.size.y) <= TOLERANCE_PX, "side %d: square, %.1f by %.1f" % [side, box.size.x, box.size.y])
		assert_true(box.get_center().distance_to(rect.get_center()) <= TOLERANCE_PX, "side %d: centered" % side)
		# Big enough to read on a launcher: at least 40 percent of the layer.
		assert_true(box.size.x >= 0.4 * side, "side %d: %.0f px wide" % [side, box.size.x])


func test_foreground_colors_and_lemon_center() -> void:
	var rect: Rect2 = Rect2(0.0, 0.0, 432.0, 432.0)
	var allowed: Array[Color] = [AppIcon.TILE, AppIcon.LINE, AppIcon.CENTER]
	var lemon: int = 0
	for fill: AppIcon.Fill in AppIcon._foreground_fills(rect):
		assert_true(allowed.has(fill.color), "foreground color %s is white, near black or lemon" % fill.color.to_html())
		if fill.color == AppIcon.CENTER:
			lemon += 1
			assert_true(Geometry2D.is_point_in_polygon(rect.get_center(), fill.points), "the lemon cell sits in the middle")
	assert_eq(lemon, 1, "exactly one lemon cell")
	assert_eq(AppIcon.BACKGROUND, Color("#1A40D9"), "background is Pop electric blue")
	assert_eq(AppIcon.GRID, Color("#4362E0"), "grid lines as section 9")
	assert_eq(AppIcon.CENTER, Color("#FFE45C"), "center cell is lemon")


func test_box_lines_draw_a_3_by_3_box() -> void:
	var rect: Rect2 = Rect2(0.0, 0.0, 432.0, 432.0)
	var cells: Array[Rect2] = AppIcon._cells(rect)
	assert_eq(cells.size(), 9, "nine cells")
	var lines: Array[Rect2] = AppIcon._box_lines(rect)
	assert_eq(lines.size(), 8, "four lines each way")
	for cell: Rect2 in cells:
		assert_true(cell.size.x > 0.0 and is_equal_approx(cell.size.x, cell.size.y), "cells are square")
		for line: Rect2 in lines:
			assert_false(line.grow(-0.01).intersects(cell.grow(-0.01)), "no line covers a cell")


func test_monochrome_is_one_color_with_cells_cut_out() -> void:
	for side: float in SIDES:
		var rect: Rect2 = Rect2(0.0, 0.0, side, side)
		var fills: Array[AppIcon.Fill] = AppIcon._monochrome_fills(rect)
		var area: float = 0.0
		var tile_clockwise: bool = Geometry2D.is_polygon_clockwise(AppIcon._tile_points(rect))
		for fill: AppIcon.Fill in fills:
			assert_eq(fill.color, AppIcon.MONOCHROME, "side %d: one color" % side)
			assert_eq(fill.color.a, 1.0, "side %d: opaque" % side)
			# A clip result can be a hole polygon, which would draw filled.
			assert_eq(Geometry2D.is_polygon_clockwise(fill.points), tile_clockwise, "side %d: no hole polygons" % side)
			area += absf(AppIcon._area(fill.points))
		var cells: Array[Rect2] = AppIcon._cells(rect)
		for cell: Rect2 in cells:
			for fill: AppIcon.Fill in fills:
				assert_false(Geometry2D.is_point_in_polygon(cell.get_center(), fill.points), "side %d: cell at %s is cut out" % [side, cell.position])
		var expected: float = absf(AppIcon._area(AppIcon._tile_points(rect)))
		for cell: Rect2 in cells:
			expected -= cell.get_area()
		assert_true(absf(area - expected) <= 0.01 * expected, "side %d: area %.1f, expected %.1f" % [side, area, expected])


func test_same_rect_gives_same_shapes() -> void:
	var rect: Rect2 = Rect2(3.0, 4.0, 216.0, 216.0)
	assert_eq(_describe_fills(AppIcon._background_fills(rect)), _describe_fills(AppIcon._background_fills(rect)), "background")
	assert_eq(_describe_fills(AppIcon._foreground_fills(rect)), _describe_fills(AppIcon._foreground_fills(rect)), "foreground")
	assert_eq(_describe_fills(AppIcon._monochrome_fills(rect)), _describe_fills(AppIcon._monochrome_fills(rect)), "monochrome")
	assert_eq(AppIcon.foreground_outline(rect), AppIcon.foreground_outline(rect), "outline")


func _describe_fills(fills: Array[AppIcon.Fill]) -> String:
	var text: String = ""
	for fill: AppIcon.Fill in fills:
		text += var_to_str(fill.points) + fill.color.to_html() + ";"
	return text


func _check_safe_zone(rect: Rect2) -> void:
	var points: PackedVector2Array = AppIcon.foreground_outline(rect)
	assert_true(points.size() > 0, "side %d: outline has points" % rect.size.x)
	var center: Vector2 = rect.get_center()
	var radius: float = rect.size.x * SAFE_RADIUS_SHARE
	var worst: float = -INF
	for point: Vector2 in points:
		worst = maxf(worst, point.distance_to(center) - radius)
	assert_true(worst <= TOLERANCE_PX, "side %d at %s: a point lies %.2f px outside the safe zone" % [rect.size.x, rect.position, worst])
