extends "res://tests/unit_test.gd"
## The app icon, Ring (DESIGN_SYSTEM.md section 9): the script loads with its
## five functions, every layer draws at every size we render, the adaptive
## foreground and monochrome layers stay inside the Android safe zone, the
## layers use only the section 9.3 colors, the ring is layout A with the 3
## and the 8 crossed, the monochrome layer is one opaque color, and the same
## rect always gives the same parts.

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
## Reading order of the open ring: layout A with the center open.
const READING_ORDER: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]


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
		assert_true(AppIcon._full_parts(rect).size() > 0, "side %d: full icon has parts" % side)
		assert_true(AppIcon._background_parts(rect).size() > 0, "side %d: background has parts" % side)
		assert_true(AppIcon._art_parts(rect, false).size() > 0, "side %d: foreground has parts" % side)
		assert_true(AppIcon._art_parts(rect, true).size() > 0, "side %d: monochrome has parts" % side)


func test_foreground_inside_safe_zone() -> void:
	for side: float in SIDES:
		_check_safe_zone(Rect2(0.0, 0.0, side, side))


func test_foreground_inside_safe_zone_when_rect_is_offset() -> void:
	_check_safe_zone(Rect2(37.0, 210.0, 108.0, 108.0))


func test_outline_holds_the_sticker_and_the_x_ends() -> void:
	for side: float in SIDES:
		var rect: Rect2 = Rect2(0.0, 0.0, side, side)
		var center: Vector2 = rect.get_center()
		var radius: float = side * SAFE_RADIUS_SHARE
		var points: PackedVector2Array = AppIcon.foreground_outline(rect)
		var farthest: float = 0.0
		for point: Vector2 in points:
			farthest = maxf(farthest, point.distance_to(center))
		# Section 9.2: the shadow and the frame corners reach about 0.98 R.
		assert_true(farthest >= 0.95 * radius, "side %d: farthest point %.3f R" % [side, farthest / radius])
		for mono: bool in [false, true]:
			for part: AppIcon.Part in AppIcon._art_parts(rect, mono):
				if part.kind == AppIcon.Kind.LINE:
					assert_true(points.has(part.a + (part.b - part.a).normalized().orthogonal() * part.width * 0.5), "side %d: X end in the outline" % side)


func test_parts_use_only_section_9_3_colors() -> void:
	var background: Array[Color] = [Color("#1A40D9"), Color("#4362E0")]
	var foreground: Array[Color] = [Color("#FFFFFF"), Color("#111111"), Color("#D1005A")]
	for side: float in SIDES:
		var rect: Rect2 = Rect2(0.0, 0.0, side, side)
		for part: AppIcon.Part in AppIcon._background_parts(rect):
			assert_true(background.has(part.color), "side %d: background color %s" % [side, part.color.to_html()])
		for part: AppIcon.Part in AppIcon._art_parts(rect, false):
			assert_true(foreground.has(part.color), "side %d: foreground color %s" % [side, part.color.to_html()])
		var full: Array[Color] = background + foreground
		for part: AppIcon.Part in AppIcon._full_parts(rect):
			assert_true(full.has(part.color), "side %d: full icon color %s" % [side, part.color.to_html()])
	assert_eq(AppIcon.BACKGROUND, Color("#1A40D9"), "background is button_primary_bg")
	assert_eq(AppIcon.GRID, Color("#4362E0"), "grid lines as section 9.3")
	assert_eq(AppIcon.FACE, Color("#FFFFFF"), "face is cell_bg")
	assert_eq(AppIcon.INK, Color("#111111"), "outline, shadow and digits")
	assert_eq(AppIcon.CROSS, Color("#D1005A"), "hand X is cross_mark_hand")
	assert_eq(AppIcon.MONOCHROME, Color("#FFFFFF"), "monochrome is white")


func test_foreground_draw_order_and_crossed_digits() -> void:
	var parts: Array[AppIcon.Part] = AppIcon._art_parts(Rect2(0.0, 0.0, 432.0, 432.0), false)
	# Shadow, outline, face.
	assert_eq(parts[0].kind, AppIcon.Kind.ROUNDED, "shadow first")
	assert_eq(parts[0].color, AppIcon.INK, "shadow is ink")
	assert_eq(parts[1].color, AppIcon.INK, "then the outline")
	assert_eq(parts[2].color, AppIcon.FACE, "then the face")
	assert_true(parts[0].rect.position.x > parts[1].rect.position.x and parts[0].rect.position.y > parts[1].rect.position.y, "shadow sits down and right")
	var digits: Array[int] = []
	for i: int in range(3, parts.size()):
		var part: AppIcon.Part = parts[i]
		if part.kind != AppIcon.Kind.DIGIT:
			continue
		digits.append(part.digit)
		var crossed: bool = part.digit == 3 or part.digit == 8
		assert_eq(part.color, AppIcon.INK, "digit %d is ink" % part.digit)
		assert_eq(part.outline > 0, crossed, "digit %d outlined only when crossed" % part.digit)
		if crossed:
			# The two X strokes come right before their digit, through its center.
			for back: int in [1, 2]:
				var stroke: AppIcon.Part = parts[i - back]
				assert_eq(stroke.kind, AppIcon.Kind.LINE, "digit %d has its X before it" % part.digit)
				assert_eq(stroke.color, AppIcon.CROSS, "the X is magenta")
				assert_true(((stroke.a + stroke.b) * 0.5).distance_to(part.a) < 0.01, "the X goes through digit %d" % part.digit)
	assert_eq(digits, READING_ORDER, "nine candidates in reading order")


func test_ring_is_layout_a() -> void:
	var parts: Array[AppIcon.Part] = AppIcon._art_parts(Rect2(0.0, 0.0, 432.0, 432.0), false)
	var at: Dictionary[int, Vector2] = {}
	for part: AppIcon.Part in parts:
		if part.kind == AppIcon.Kind.DIGIT:
			at[part.digit] = part.a
	# Rows 1 2 3 4 / 5 . 6 / 7 8 9.
	for row: Array in [[1, 2, 3, 4], [5, 6], [7, 8, 9]]:
		for digit: int in row:
			assert_true(absf(at[digit].y - at[row[0]].y) < 0.01, "%d shares its row" % digit)
	assert_true(at[1].y < at[5].y and at[5].y < at[7].y, "rows go down")
	assert_true(absf(at[1].x - at[5].x) < 0.01 and absf(at[5].x - at[7].x) < 0.01, "left column")
	assert_true(absf(at[4].x - at[6].x) < 0.01 and absf(at[6].x - at[9].x) < 0.01, "right column")
	# The ring is centered on the face, whose center sits up and left of the
	# layer center by half the shadow.
	var face: Rect2 = parts[2].rect
	assert_true(((at[1] + at[9]) * 0.5).distance_to(face.get_center()) < 0.01, "ring centered on the face")


func test_monochrome_is_one_color_without_crossed_digits() -> void:
	for side: float in SIDES:
		var rect: Rect2 = Rect2(0.0, 0.0, side, side)
		var digits: Array[int] = []
		var lines: int = 0
		var frames: int = 0
		for part: AppIcon.Part in AppIcon._art_parts(rect, true):
			assert_eq(part.color, AppIcon.MONOCHROME, "side %d: one color" % side)
			assert_eq(part.color.a, 1.0, "side %d: opaque" % side)
			assert_ne(part.kind, AppIcon.Kind.ROUNDED, "side %d: no filled shapes" % side)
			match part.kind:
				AppIcon.Kind.DIGIT:
					digits.append(part.digit)
					assert_eq(part.outline, 0, "side %d: no outlined digits" % side)
				AppIcon.Kind.LINE:
					lines += 1
				AppIcon.Kind.FRAME:
					frames += 1
					assert_true(part.width >= 1.0, "side %d: frame at least 1 px" % side)
		assert_eq(frames, 1, "side %d: one frame" % side)
		assert_eq(lines, 4, "side %d: two X" % side)
		assert_eq(digits, [1, 2, 4, 5, 6, 7, 9] as Array[int], "side %d: seven open digits" % side)


func test_same_rect_gives_same_parts() -> void:
	var rect: Rect2 = Rect2(3.0, 4.0, 216.0, 216.0)
	assert_eq(_describe_parts(AppIcon._full_parts(rect)), _describe_parts(AppIcon._full_parts(rect)), "full")
	assert_eq(_describe_parts(AppIcon._background_parts(rect)), _describe_parts(AppIcon._background_parts(rect)), "background")
	assert_eq(_describe_parts(AppIcon._art_parts(rect, false)), _describe_parts(AppIcon._art_parts(rect, false)), "foreground")
	assert_eq(_describe_parts(AppIcon._art_parts(rect, true)), _describe_parts(AppIcon._art_parts(rect, true)), "monochrome")
	assert_eq(AppIcon.foreground_outline(rect), AppIcon.foreground_outline(rect), "outline")


func _describe_parts(parts: Array[AppIcon.Part]) -> String:
	var text: String = ""
	for part: AppIcon.Part in parts:
		text += var_to_str([part.kind, part.color, part.rect, part.radius, part.detail, part.a, part.b, part.width, part.digit, part.font_size, part.outline]) + ";"
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
