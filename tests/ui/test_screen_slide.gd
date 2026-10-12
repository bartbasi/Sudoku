extends "res://tests/unit_test.gd"
## App slides each new screen in from the right (position.x starts at
## space_xl). Layout measures from the screen's resting place, so the content
## column keeps its full width and stays centered during the slide (the bug
## that shifted every screen left on a 344 dp wide phone).
##
## The headless runner works before the root enters the tree, so there is no
## viewport to measure against: the screen gives the slide, and the math is
## checked with the numbers the viewport would give.

const VIEW: Vector2 = Vector2(344, 882)


func _margin() -> float:
	return (load("res://src/skins/pop_light.tres") as GameSkin).page_margin


## The column of a full screen on a VIEW sized viewport, measured while the
## screen sits slide to the right of its resting place.
func _column_while_sliding(slide: float) -> Rect2:
	var screen: UiScreen = UiScreen.new()
	screen.ensure_built()
	screen.position.x = slide
	var moved: Vector2 = UiKit.screen_slide(screen.column)
	assert_eq(moved, Vector2(slide, 0.0), "the column sees its screen's slide")
	var safe: Rect2 = UiKit.safe_rect_in(Rect2(Vector2.ZERO, VIEW), Vector2(slide, 0.0), moved, VIEW)
	screen.free()
	return ScreenColumn.column_in(safe, _margin())


func test_column_is_328_wide_and_centered_on_a_344_viewport_while_sliding() -> void:
	var margin: float = _margin()
	for slide: float in [0.0, 24.0]:
		var col: Rect2 = _column_while_sliding(slide)
		assert_eq(col.size.x, VIEW.x - 2.0 * margin, "column width at slide %s" % slide)
		assert_eq(col.position.x, margin, "column left at slide %s" % slide)
		assert_eq(col.end.x, VIEW.x - margin, "column right at slide %s" % slide)


func test_without_the_slide_the_column_would_lose_it_on_the_right() -> void:
	# The old measurement: the global origin taken as the resting place.
	var safe: Rect2 = UiKit.safe_rect_in(Rect2(Vector2.ZERO, VIEW), Vector2(24, 0), Vector2.ZERO, VIEW)
	assert_eq(ScreenColumn.column_in(safe, _margin()).size.x, VIEW.x - 24.0 - 2.0 * _margin(), "the bug this guards")


func test_a_child_deeper_in_the_screen_sees_the_same_slide() -> void:
	var screen: UiScreen = UiScreen.new()
	screen.ensure_built()
	var inner: Control = Control.new()
	screen.column.add_child(inner)
	screen.position.x = 24.0
	assert_eq(UiKit.screen_slide(inner), Vector2(24, 0), "slide from a nested control")
	screen.free()


func test_no_slide_outside_a_screen() -> void:
	var control: Control = Control.new()
	assert_eq(UiKit.screen_slide(control), Vector2.ZERO, "no screen, no slide")
	control.free()
