extends "res://tests/unit_test.gd"
## The app icon script loads with its five functions, and the adaptive
## foreground and monochrome layers stay inside the Android safe zone at every
## size we render.

const ICON_PATH: String = "res://src/design/app_icon.gd"
const AppIcon := preload("res://src/design/app_icon.gd")

const FUNCTIONS: Array[String] = [
	"draw_full", "draw_background", "draw_foreground", "draw_monochrome", "foreground_outline",
]

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


func test_foreground_inside_safe_zone() -> void:
	for side: float in SIDES:
		_check_safe_zone(Rect2(0.0, 0.0, side, side))


func test_foreground_inside_safe_zone_when_rect_is_offset() -> void:
	_check_safe_zone(Rect2(37.0, 210.0, 108.0, 108.0))


func test_wedge_is_at_least_55_percent_as_tall_as_wide() -> void:
	for side: float in SIDES:
		var points: PackedVector2Array = AppIcon.foreground_outline(Rect2(0.0, 0.0, side, side))
		var box: Rect2 = Rect2(points[0], Vector2.ZERO)
		for point: Vector2 in points:
			box = box.expand(point)
		assert_true(box.size.y >= 0.55 * box.size.x, "side %d: wedge is %.0f by %.0f" % [side, box.size.x, box.size.y])


func _check_safe_zone(rect: Rect2) -> void:
	var points: PackedVector2Array = AppIcon.foreground_outline(rect)
	assert_true(points.size() > 0, "side %d: outline has points" % rect.size.x)
	var center: Vector2 = rect.get_center()
	var radius: float = rect.size.x * SAFE_RADIUS_SHARE
	var worst: float = -INF
	for point: Vector2 in points:
		worst = maxf(worst, point.distance_to(center) - radius)
	assert_true(worst <= TOLERANCE_PX, "side %d at %s: a point lies %.2f px outside the safe zone" % [rect.size.x, rect.position, worst])
