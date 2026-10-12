extends "res://tests/unit_test.gd"
## Regression: App slides each new screen in from x = 24 to 0, and layout runs
## in that first frame. The lesson player and the lessons list must measure
## the safe area from where they come to rest, so they still lay out full
## width and centered on a 344 dp wide screen (the Fold5 cover screen).
## The runner keeps nodes outside the scene tree, where get_global_rect()
## cannot run, so the tests feed the global origin a sliding screen would
## report through LessonPlayer.resting_safe_rect, the conversion both
## screens use.

const Lx := preload("res://tests/lessons/lesson_fixtures.gd")
const WIDTH: float = 344.0
const HEIGHT: float = 882.0
const SLIDE: Vector2 = Vector2(24.0, 0.0)
const VIEWPORT: Rect2 = Rect2(0.0, 0.0, WIDTH, HEIGHT)


func _near(a: float, b: float) -> bool:
	return absf(a - b) < 0.01


## The safe rect a screen at x = 24, a direct child of the viewport, works out.
func _mid_slide_safe() -> Rect2:
	return LessonPlayer.resting_safe_rect(VIEWPORT, SLIDE, SLIDE, Vector2(WIDTH, HEIGHT))


func test_mid_slide_safe_rect_is_the_whole_screen() -> void:
	assert_eq(_mid_slide_safe(), VIEWPORT, "the slide is not taken off the right edge")


func test_safe_rect_keeps_real_insets_mid_slide() -> void:
	# A cutout 30 dp tall at the top and a gesture bar 24 dp at the bottom.
	var safe: Rect2 = Rect2(0.0, 30.0, WIDTH, HEIGHT - 54.0)
	assert_eq(LessonPlayer.resting_safe_rect(safe, SLIDE, SLIDE, Vector2(WIDTH, HEIGHT)), safe)


func test_safe_rect_inside_an_offset_parent() -> void:
	# A screen at rest inside a parent that sits 10 dp down the viewport.
	var got: Rect2 = LessonPlayer.resting_safe_rect(VIEWPORT, Vector2(0.0, 10.0), Vector2.ZERO, Vector2(WIDTH, HEIGHT - 10.0))
	assert_eq(got, Rect2(0.0, 0.0, WIDTH, HEIGHT - 10.0))


func test_lesson_player_mid_slide_lays_out_full_width() -> void:
	var skin: GameSkin = Lx.light()
	var player: LessonPlayer = LessonPlayer.new()
	player.skin = skin
	player.theme = ThemeFactory.build(skin)
	player.size = Vector2(WIDTH, HEIGHT)
	player.position = SLIDE
	player.safe_rect_override = _mid_slide_safe()
	Lx.root().add_child(player)
	player.ensure_built()
	player.start(Lx.lesson(1))
	player.notification(Control.NOTIFICATION_RESIZED)
	assert_true(_near(player.area.position.x, 0.0), "starts at the left edge, got %s" % player.area.position)
	assert_true(_near(player.area.size.x, WIDTH), "full width, got %s" % player.area.size)
	var board: Rect2 = player.area.view.get_rect()
	assert_true(_near(player.area.position.x + board.get_center().x, WIDTH * 0.5), "the board is centered, got %s" % board)


func test_lessons_list_mid_slide_lays_out_centered() -> void:
	var skin: GameSkin = Lx.light()
	var screen: LessonsScreen = LessonsScreen.new()
	screen.skin = skin
	screen.theme = ThemeFactory.build(skin)
	screen.size = Vector2(WIDTH, HEIGHT)
	screen.position = SLIDE
	screen.safe_rect_override = _mid_slide_safe()
	Lx.root().add_child(screen)
	screen.ensure_built()
	screen.notification(Control.NOTIFICATION_RESIZED)
	var expected: float = minf(WIDTH - 2.0 * skin.page_margin, Layout.COLUMN_MAX)
	assert_true(_near(screen.scroll.size.x, expected), "full column width, got %s" % screen.scroll.size)
	var center: float = screen.scroll.position.x + screen.scroll.size.x * 0.5
	assert_true(_near(center, WIDTH * 0.5), "centered across, got center %s" % center)
	assert_true(_near(screen.back_area.position.x, screen.scroll.position.x), "Back lines up with the list")
