extends SceneTree
## Screenshots of the lesson player and the lessons list in Pop light. Not a
## test file: the runner only runs tests/<area>/test_*.gd. Needs a window
## (headless mode has no renderer):
##
##   timeout 300 godot --path . --script res://tests/lessons/lesson_capture.gd
##
## Writes build/lessons/lesson-N.png (one screen of each lesson),
## build/lessons/lessons-list.png and build/lessons/lesson-short.png (the
## smallest screen, 320 by 568, where the text may scroll): screens at one
## pixel per dp, with a 32 dp notch inset and a 24 dp gesture bar inset.
## Prints the board, band and text size of each. build/ is git ignored.

const Lx := preload("res://tests/lessons/lesson_fixtures.gd")

const OUT_DIR: String = "res://build/lessons/"
const TOP_INSET: float = 32.0
const BOTTOM_INSET: float = 24.0

## Lesson number, screen index (0-based), taps to make first, and what to
## show: "" as is, "wrong" after the taps the last one is a wrong tap.
const SHOTS: Array[Array] = [
	[1, 5, [], ""],
	[2, 4, [["pad", 4], ["pad", 2]], "wrong"],
	[3, 3, [], ""],
	[4, 1, [["pad", 7]], ""],
	[5, 5, [], ""],
]

var _started: bool = false


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for shot: Array in SHOTS:
		await _capture_lesson(Vector2i(360, 800), shot, "lesson-%d.png" % int(shot[0]))
	await _capture_lesson(Vector2i(320, 568), [4, 0, [], ""], "lesson-short.png")
	await _capture_list(Vector2i(360, 800))
	quit(0)


func _resize(screen: Vector2i) -> void:
	DisplayServer.window_set_size(screen)
	await process_frame
	ScreenMetrics.apply_dp_scale(root)
	await process_frame


func _capture_lesson(screen: Vector2i, shot: Array, file_name: String) -> void:
	await _resize(screen)
	var skin: GameSkin = Lx.light()
	var player: LessonPlayer = LessonPlayer.new()
	player.skin = skin
	player.theme = ThemeFactory.build(skin)
	player.size = Vector2(screen)
	player.safe_rect_override = Rect2(0.0, TOP_INSET, float(screen.x), float(screen.y) - TOP_INSET - BOTTOM_INSET)
	root.add_child(player)
	player.start(Lx.lesson(int(shot[0])))
	player.show_screen(int(shot[1]))
	await process_frame
	player.notification(Control.NOTIFICATION_RESIZED)
	for tap: Array in shot[2]:
		var action: BoardAction = BoardAction.create(BoardAction.Kind.PAD, -1, int(tap[1])) if tap[0] == "pad" \
			else BoardAction.create(BoardAction.Kind.CELL, LessonLibrary.cell_from_name(String(tap[1])))
		player.area.controller.handle(action)
	for _i: int in 30:
		await process_frame
	var image: Image = root.get_texture().get_image()
	var path: String = OUT_DIR + file_name
	image.save_png(path)
	print("Wrote %s (%d by %d px): lesson %d screen %d, board %.1f dp, band %.1f dp, text %d dp, title %s, scrolls %s, wrong %s, praise %s" % [
		path, image.get_width(), image.get_height(), int(shot[0]), int(shot[1]) + 1,
		player.area.view.board_square().size.x, player.area.band_rect().size.y,
		player.card.body.get_theme_font_size(&"font_size"), player.card.title_label.visible,
		player.card.is_capped(), player.is_showing_wrong(), player.is_praise_showing()])
	var body: Label = player.card.body
	print("  body label: shown %.1f dp tall, needs %.1f dp" % [body.size.y, body.get_combined_minimum_size().y])
	player.free()


func _capture_list(screen: Vector2i) -> void:
	await _resize(screen)
	var skin: GameSkin = Lx.light()
	var progress: LessonProgress = LessonProgress.new()
	progress.mark_finished("lesson_01")
	progress.mark_finished("lesson_02")
	var list: LessonsScreen = LessonsScreen.new()
	list.skin = skin
	list.progress = progress
	list.theme = ThemeFactory.build(skin)
	list.size = Vector2(screen)
	list.safe_rect_override = Rect2(0.0, TOP_INSET, float(screen.x), float(screen.y) - TOP_INSET - BOTTOM_INSET)
	root.add_child(list)
	for _i: int in 10:
		await process_frame
	var image: Image = root.get_texture().get_image()
	var path: String = OUT_DIR + "lessons-list.png"
	image.save_png(path)
	print("Wrote %s (%d by %d px)" % [path, image.get_width(), image.get_height()])
	list.free()
