extends SceneTree
## Makes the Google Play store graphics from the game's own code into
## docs/store/graphics/ (committed; docs/store/listing.md says where each one
## goes):
##   icon_512.png            the app icon (src/design/app_icon.gd), 512 by 512,
##                           32-bit, a full square (Play rounds the corners)
##   feature_1024x500.png    the feature graphic: the wordmark, a line about
##                           the game and a close up of a real board, no alpha
##   phone_1_play.png ...    six phone screenshots of the real game at
##   phone_6_stats.png       1080 by 1920: the UI at 360 by 640 dp, scaled 3x
##
## Needs a window, because headless mode has no renderer. The window must be
## able to reach 1080 by 1920 px; the script checks every image's size.
##   timeout 300 godot --path . --resolution 1080x1920 --script res://tools/build/store_graphics.gd
## Exits 0 when every file is written at its size, 1 otherwise.
##
## Saves go to user://store_graphics/, which is wiped before and after, so
## the player's saves are never changed. No link is opened: nothing taps a
## button.
##
## The screens are scaled with the window's content_scale_factor. App sets
## content_scale_size to the window size on every resize (one unit is one dp),
## so content_scale_size alone cannot scale the UI; the factor multiplies on
## top of it and App leaves it alone.
## Owner: platform-dev.

const AppIcon: GDScript = preload("res://src/design/app_icon.gd")
const MainMenu: GDScript = preload("res://src/ui/main_menu.gd")

const OUT_DIR: String = "res://docs/store/graphics/"
const SAVE_DIR: String = "user://store_graphics"
const ICON_PX: int = 512
const SHOT: Vector2i = Vector2i(1080, 1920)
const SHOT_SCALE: float = 3.0
const FEATURE: Vector2i = Vector2i(1024, 500)
const FEATURE_SCALE: float = 2.0

var _problems: PackedStringArray = PackedStringArray()
var _app: AppService = null
var _host: Control = null
## The light play screenshot and the board's middle box in it, in pixels,
## for the feature graphic's close up.
var _play_image: Image = null
var _box_px: Rect2 = Rect2()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_problems.append("no renderer in headless mode; run without --headless")
		_finish()
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_wipe(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	await _icon()
	await _start_app()
	await _screenshots()
	await _feature()
	_wipe(SAVE_DIR)
	_finish()


# The icon --------------------------------------------------------------------

## The full icon as a square: the adaptive background and foreground layers,
## sized so their visible 72 dp middle fills the image, as draw_full does
## but without its rounded corners.
func _icon() -> void:
	var side: float = float(ICON_PX) / AppIcon.VISIBLE
	var layer: Rect2 = Rect2(Vector2(ICON_PX, ICON_PX) * 0.5 - Vector2(side, side) * 0.5, Vector2(side, side))
	var canvas: Control = Control.new()
	canvas.draw.connect(func() -> void:
		AppIcon.draw_background(canvas, layer)
		AppIcon.draw_foreground(canvas, layer))
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(ICON_PX, ICON_PX)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	canvas.size = Vector2(ICON_PX, ICON_PX)
	root.add_child(viewport)
	viewport.add_child(canvas)
	await _frames(3)
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	viewport.queue_free()
	image.convert(Image.FORMAT_RGBA8)
	for y: int in [0, ICON_PX / 2, ICON_PX - 1]:
		for x: int in [0, ICON_PX / 2, ICON_PX - 1]:
			if image.get_pixel(x, y).a < 0.99:
				_problems.append("icon_512: pixel %d,%d is not opaque" % [x, y])
	_save(image, "icon_512.png", Vector2i(ICON_PX, ICON_PX))


# Screenshots -----------------------------------------------------------------

## The Skins and App autoloads, with saves moved to SAVE_DIR before anything
## is written, and the main scene.
func _start_app() -> void:
	var skins: Node = root.get_node_or_null(^"Skins")
	if skins == null:
		skins = (load("res://src/skins/skin_service.gd") as GDScript).new() as Node
		skins.name = "Skins"
		root.add_child(skins)
	_app = root.get_node_or_null(^"App") as AppService
	if _app == null:
		_app = AppService.new()
		_app.name = "App"
		root.add_child(_app)
	_app.save_dir = SAVE_DIR
	_app.use_thread = false
	_app.load_all()
	_app.set_skin(&"pop_light")
	await process_frame
	_host = (load("res://scenes/ui/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(_host)
	await _resize(SHOT, SHOT_SCALE)


func _screenshots() -> void:
	_app.answer_first_launch()
	_app.start_new_puzzle(Levels.MEDIUM)
	var session: GameSession = _app.session
	if session == null:
		_problems.append("no puzzle was made")
		return
	session.add_time(9.0 * 60.0 + 42.0)
	_work(session, 4, 54)
	_app.goto(AppService.PLAY)
	_play_image = await _shot("phone_1_play.png")
	var play: Control = _app.current_screen_node()
	var boards: Array[Node] = play.find_children("*", "BoardView", true, false)
	if boards.is_empty():
		_problems.append("no BoardView on the play screen")
	else:
		# Cells 30 and 50 are the middle box's top left and bottom right.
		var view: BoardView = boards[0] as BoardView
		var box: Rect2 = view.cell_rect_global(30).merge(view.cell_rect_global(50))
		_box_px = Rect2(box.position * SHOT_SCALE, box.size * SHOT_SCALE)

	play.call(&"buy_hint")
	await _shot("phone_2_hint.png")
	session.close_hint()

	_app.goto(AppService.LESSONS)
	await _settle()
	_app.current_screen_node().call(&"open_lesson", 1)
	await _settle()
	var player: Node = _app.current_screen_node()
	if player.has_method(&"show_screen"):
		player.call(&"show_screen", 1)
	await _shot("phone_3_lesson.png")
	_app.go_back()
	await _settle()

	# Pop dark, on a fresh Hard puzzle with less work done.
	_app.set_skin(&"pop_dark")
	_app.start_new_puzzle(Levels.HARD)
	if _app.session == null:
		_problems.append("no Hard puzzle was made")
		return
	_app.session.add_time(4.0 * 60.0 + 17.0)
	_work(_app.session, 2, 27)
	_app.goto(AppService.PLAY)
	await _shot("phone_4_dark.png")
	_app.set_skin(&"pop_light")

	var result: CompletionResult = CompletionResult.new()
	result.level = Levels.HARD
	result.seconds = 1350
	result.points_after_hints = 420
	result.time_bonus = 175
	result.final_score = 595
	result.hints_used = 1
	result.new_best = Stats.NEW_BEST_TIME | Stats.NEW_BEST_SCORE
	_app.goto(AppService.COMPLETION, result)
	await _shot("phone_5_completion.png")

	var games: Array[Array] = [
		[Levels.BEGINNER, 9, 9, 240, 330], [Levels.EASY, 14, 12, 420, 450],
		[Levels.MEDIUM, 11, 8, 760, 610], [Levels.HARD, 6, 4, 1350, 595],
		[Levels.EXPERT, 3, 1, 2460, 780]]
	for game: Array in games:
		for i: int in int(game[1]):
			_app.stats.record_start(int(game[0]))
		for i: int in int(game[2]):
			_app.stats.record_completion(int(game[0]), int(game[3]) + i * 37, int(game[4]) - i * 9)
	for id: String in ["lesson_01", "lesson_02", "lesson_03"]:
		_app.record_lesson_finished(id)
	_app.goto(AppService.STATS)
	await _shot("phone_6_stats.png")
	_app.abandon_puzzle()


## A player's work: placed right digits (one in every fourth empty cell from
## the top, up to placed of them), then in Cross Out mode hand crosses in
## every empty cell before cell crossed_end, of the digits its row, column and
## box already hold. Later cells keep their full rings. The last crossed cell
## stays selected.
func _work(session: GameSession, placed: int, crossed_end: int) -> void:
	var count: int = 0
	for cell: int in Sudoku.CELLS:
		if count < placed and session.board.digits[cell] == 0 and cell % 4 == 1:
			session.select(cell)
			session.press_digit(session.solution[cell])
			count += 1
	session.set_mode(GameSession.Mode.CROSS_OUT)
	var last: int = -1
	for cell: int in range(0, crossed_end):
		if session.board.digits[cell] != 0:
			continue
		session.select(cell)
		for peer: int in Sudoku.peers(cell):
			var d: int = session.board.digits[peer]
			if d != 0 and session.board.mark(cell, d) == Board.Mark.OPEN:
				session.press_digit(d)
		last = cell
	if last >= 0:
		session.select(last)


# The feature graphic ---------------------------------------------------------

## 1024 by 500 at 2x (512 by 250 dp): the Pop page, the wordmark sticker and a
## line about the game on the left, and on the right the middle box of the
## board from the light play screenshot on a card, at one image pixel per
## screen pixel.
func _feature() -> void:
	if _play_image == null or _box_px.size.x <= 0.0:
		_problems.append("feature: no play screenshot to take the board from")
		return
	_app.set_skin(&"pop_light")
	_app.goto(AppService.TITLE)
	await _resize(FEATURE, FEATURE_SCALE)
	_host.visible = false
	var s: GameSkin = _app.current_skin()

	var page: Panel = Panel.new()
	page.theme_type_variation = ThemeFactory.PAGE
	root.add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg: ColorRect = ColorRect.new()
	bg.color = s.page_bg
	page.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var row: HBoxContainer = UiKit.hbox(s.space_l)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	page.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, roundi(s.space_l))

	var left: VBoxContainer = UiKit.vbox(s.space_l)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.custom_minimum_size = Vector2(236, 0)
	row.add_child(left)
	left.add_child(MainMenu.wordmark(s))
	var line: Label = UiKit.label(ThemeFactory.HEADING, "Every empty cell shows its candidates. Cross them out by hand.", true)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.custom_minimum_size = Vector2(236, 0)
	left.add_child(line)

	# The middle box of the board, with its thick box lines all round.
	var box: Rect2 = _box_px.grow(s.line_box_w * SHOT_SCALE)
	var crop: Rect2i = Rect2i(Vector2i(box.position.round()), Vector2i(box.size.round()))
	var close_up: Image = _play_image.get_region(crop)
	var card: PanelContainer = UiKit.panel(ThemeFactory.CARD)
	var picture: TextureRect = TextureRect.new()
	picture.texture = ImageTexture.create_from_image(close_up)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.custom_minimum_size = Vector2(crop.size) / FEATURE_SCALE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	card.add_child(picture)
	var holder: CenterContainer = CenterContainer.new()
	holder.add_child(card)
	row.add_child(holder)
	await _settle()
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	_save(image, "feature_1024x500.png", FEATURE)
	page.queue_free()
	_host.visible = true


# Helpers ---------------------------------------------------------------------

## A window of px pixels showing the UI at factor times its dp size.
func _resize(px: Vector2i, factor: float) -> void:
	DisplayServer.window_set_size(px)
	root.size = px
	await _frames(4)
	root.content_scale_factor = factor
	await _settle()
	var units: Vector2 = root.get_visible_rect().size
	print("window %s px, %s units" % [root.size, units])
	if root.size != px:
		_problems.append("the window is %s, not %s; the screen may be too small" % [root.size, px])


func _shot(file_name: String) -> Image:
	await _settle()
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	_save(image, file_name, SHOT)
	return image


## Saves image without alpha (Play wants none on the feature graphic and
## screenshots) unless it is the icon, after checking its size.
func _save(image: Image, file_name: String, want: Vector2i) -> void:
	if image == null or image.get_size() != want:
		_problems.append("%s: got %s, want %s" % [file_name, image.get_size() if image != null else Vector2i.ZERO, want])
		return
	var copy: Image = image.duplicate() as Image
	if file_name != "icon_512.png":
		copy.convert(Image.FORMAT_RGB8)
	var path: String = ProjectSettings.globalize_path(OUT_DIR + file_name)
	var error: Error = copy.save_png(path)
	if error != OK:
		_problems.append("could not save %s (error %d)" % [path, error])
		return
	print("wrote %s (%d by %d)" % [OUT_DIR + file_name, want.x, want.y])


func _settle() -> void:
	await _frames(60)


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _wipe(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for file: String in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file))


func _finish() -> void:
	for problem: String in _problems:
		printerr("PROBLEM  %s" % problem)
	print("Store graphics done, %d problem(s)." % _problems.size())
	quit(0 if _problems.is_empty() else 1)
