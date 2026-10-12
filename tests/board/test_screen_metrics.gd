extends "res://tests/unit_test.gd"
## ScreenMetrics: pixels to dp and the safe area conversion, with the numbers
## the Galaxy Z Fold5 cover screen reports (904 by 2316 px, 420 dpi, camera
## cutout 85 px tall at the top, immersive mode).

const FOLD_PX: Vector2i = Vector2i(904, 2316)
const FOLD_DENSITY: float = 420.0 / 160.0
const FOLD_SAFE_PX: Rect2i = Rect2i(0, 85, 904, 2231)


## The viewport's final transform for a window of px shown at dp units
## (canvas_items stretch scales each axis to fill the window).
func _final(px: Vector2i, dp: Vector2i) -> Transform2D:
	return Transform2D(0.0, Vector2(float(px.x) / float(dp.x), float(px.y) / float(dp.y)), 0.0, Vector2.ZERO)


func _near(a: float, b: float) -> bool:
	return absf(a - b) < 0.01


func test_fold_cover_dp_size() -> void:
	assert_eq(ScreenMetrics.dp_size(FOLD_PX, FOLD_DENSITY), Vector2i(344, 882))


func test_dp_size_never_zero() -> void:
	assert_eq(ScreenMetrics.dp_size(Vector2i(0, 0), 2.0), Vector2i(1, 1))
	assert_eq(ScreenMetrics.dp_size(Vector2i(400, 800), 0.0), Vector2i(400, 800), "a bad density counts as 1")


func test_fold_cover_safe_rect_is_full_width_and_centered() -> void:
	var dp: Vector2i = ScreenMetrics.dp_size(FOLD_PX, FOLD_DENSITY)
	var visible: Rect2 = Rect2(Vector2.ZERO, Vector2(dp))
	var safe: Rect2 = ScreenMetrics.safe_rect_from(FOLD_SAFE_PX, Vector2i.ZERO, _final(FOLD_PX, dp), visible)
	assert_true(_near(safe.position.x, 0.0), "no left inset")
	assert_true(_near(safe.size.x, 344.0), "full width, got %s" % safe)
	assert_true(_near(safe.get_center().x, visible.get_center().x), "centered across")
	assert_true(_near(safe.position.y, 85.0 * 882.0 / 2316.0), "below the cutout")
	assert_true(_near(safe.end.y, 882.0), "down to the bottom edge")


func test_safe_rect_follows_window_origin() -> void:
	# A window placed at (100, 50) on the screen: the screen's safe area
	# starts at the window's top left corner, so it covers the whole window.
	var final: Transform2D = _final(Vector2i(800, 1600), Vector2i(400, 800))
	var visible: Rect2 = Rect2(0.0, 0.0, 400.0, 800.0)
	var safe: Rect2 = ScreenMetrics.safe_rect_from(Rect2i(100, 50, 800, 1600), Vector2i(100, 50), final, visible)
	assert_eq(safe, visible)


func test_side_insets_scale_to_dp() -> void:
	# Landscape style cutout on the left: 84 px at 2.0 px per dp is 42 dp.
	var final: Transform2D = _final(Vector2i(800, 1600), Vector2i(400, 800))
	var visible: Rect2 = Rect2(0.0, 0.0, 400.0, 800.0)
	var safe: Rect2 = ScreenMetrics.safe_rect_from(Rect2i(84, 0, 716, 1600), Vector2i.ZERO, final, visible)
	assert_true(_near(safe.position.x, 42.0), "left inset in dp")
	assert_true(_near(safe.end.x, 400.0), "right edge kept")


func test_safe_rect_clipped_to_visible() -> void:
	var final: Transform2D = _final(Vector2i(400, 800), Vector2i(400, 800))
	var visible: Rect2 = Rect2(0.0, 0.0, 400.0, 800.0)
	var safe: Rect2 = ScreenMetrics.safe_rect_from(Rect2i(-20, 0, 500, 900), Vector2i.ZERO, final, visible)
	assert_eq(safe, visible)


func test_no_safe_area_gives_visible() -> void:
	var visible: Rect2 = Rect2(0.0, 0.0, 360.0, 800.0)
	assert_eq(ScreenMetrics.safe_rect_from(Rect2i(), Vector2i.ZERO, Transform2D.IDENTITY, visible), visible)
	var away: Rect2 = ScreenMetrics.safe_rect_from(Rect2i(5000, 5000, 10, 10), Vector2i.ZERO, Transform2D.IDENTITY, visible)
	assert_eq(away, visible, "a safe area outside the window falls back to the window")
