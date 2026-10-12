extends SceneTree
## Screenshots of PlayArea with a puzzle in progress, and a fit report. Not a
## test file: the runner only runs tests/<area>/test_*.gd. Needs a window
## (headless mode has no renderer):
##
##   timeout 300 godot --path . --script res://tests/board/board_capture.gd
##
## Writes build/board/play-pop_light.png and build/board/play-pop_dark.png:
## a 360 by 800 dp screen at one pixel per dp, with a 32 dp notch inset and a
## 24 dp gesture bar inset. Then, in Pop light, the Galaxy Z Fold5 windows of
## DESIGN_SYSTEM.md 4.11 (WINDOWS below), as build/board/play-<w>x<h>.png.
## PlayArea gets the whole safe rect, as the play screen gives it, with the
## header row reserved and left empty.
##
## To capture other window sizes in Pop light instead, pass them after "--",
## each as WxH or WxH:top:bottom (insets in dp, default 0):
##
##   timeout 300 godot --path . --script res://tests/board/board_capture.gd -- 690x553:32:0 460x829
##
## Then prints, for 320 by 568, 360 by 800 and 1024 by 1366, every pad button
## whose theme content needs more room than its layout face, measured in the
## tree with the real theme. build/ is git ignored.

const Fx := preload("res://tests/board/board_fixtures.gd")

const OUT_DIR: String = "res://build/board/"
const SCREEN: Vector2i = Vector2i(360, 800)
const TOP_INSET: float = 32.0
const BOTTOM_INSET: float = 24.0
## Fold5 windows (tools/design/layout_model.gd window_screens()): width,
## height, top inset, bottom inset, dp.
const WINDOWS: Array[Vector4] = [
	Vector4(344, 882, 32, 24), Vector4(690, 829, 32, 24), Vector4(345, 829, 32, 24), Vector4(690, 400, 32, 0),
]

const NAMES: Array[StringName] = [
	&"pad:1", &"pad:2", &"pad:3", &"pad:4", &"pad:5", &"pad:6", &"pad:7", &"pad:8", &"pad:9",
	&"place", &"cross_out", &"undo", &"erase",
]
const NODE_NAMES: Dictionary[StringName, String] = {
	&"place": "Place", &"cross_out": "CrossOut", &"undo": "Undo", &"erase": "Erase",
}

const ARRANGEMENTS: PackedStringArray = ["stacked", "side by side", "too small"]

var _started: bool = false


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var asked: Array[Vector4] = _asked_windows()
	if asked.is_empty():
		var phone: Vector4 = Vector4(SCREEN.x, SCREEN.y, TOP_INSET, BOTTOM_INSET)
		for skin: GameSkin in [Fx.light(), Fx.dark()]:
			await _capture(skin, phone, "play-%s.png" % skin.id)
		asked = WINDOWS
	for window: Vector4 in asked:
		await _capture(Fx.light(), window, "play-%dx%d.png" % [int(window.x), int(window.y)])
	await _set_window(Vector2i(SCREEN))
	await _fit_report()
	quit(0)


## The windows given after "--", or none.
func _asked_windows() -> Array[Vector4]:
	var out: Array[Vector4] = []
	for arg: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = arg.split(":")
		var size: PackedStringArray = parts[0].to_lower().split("x")
		if size.size() != 2 or not size[0].is_valid_int() or not size[1].is_valid_int():
			push_warning("Ignored %s: expected WxH or WxH:top:bottom" % arg)
			continue
		var top: float = parts[1].to_float() if parts.size() > 1 else 0.0
		var bottom: float = parts[2].to_float() if parts.size() > 2 else 0.0
		out.append(Vector4(size[0].to_int(), size[1].to_int(), top, bottom))
	return out


## Sets the window to size px, one px per dp, and waits until it has it.
func _set_window(size: Vector2i) -> void:
	DisplayServer.window_set_size(size)
	for _i: int in 3:
		await process_frame
	ScreenMetrics.apply_dp_scale(root)
	await process_frame
	if DisplayServer.window_get_size() != size:
		push_warning("The window is %s, not %s (the desktop may be too small)" % [DisplayServer.window_get_size(), size])


func _screen(skin: GameSkin, size: Vector2, top: float, bottom: float) -> Array[Control]:
	var page: Panel = Panel.new()
	page.theme = ThemeFactory.build(skin)
	page.theme_type_variation = ThemeFactory.PAGE
	page.position = Vector2.ZERO
	page.size = size
	root.add_child(page)
	var area: PlayArea = PlayArea.new()
	area.skin = skin
	page.add_child(area)
	area.header_height = Layout.HEADER_ROW
	area.position = Vector2(0.0, top)
	area.size = Vector2(size.x, size.y - top - bottom)
	return [page, area]


## Captures a window (width, height, top inset, bottom inset) to OUT_DIR + file.
func _capture(skin: GameSkin, window: Vector4, file: String) -> void:
	await _set_window(Vector2i(int(window.x), int(window.y)))
	var nodes: Array[Control] = _screen(skin, Vector2(window.x, window.y), window.z, window.w)
	var area: PlayArea = nodes[1] as PlayArea
	var session: GameSession = _puzzle_in_progress()
	area.setup(session)
	area.controller.audio = Fx.FakeAudio.new()
	area.add_child(area.controller.audio)
	for _i: int in 6:
		await process_frame
	var image: Image = root.get_texture().get_image()
	var path: String = OUT_DIR + file
	image.save_png(path)
	print("Wrote %s (%d by %d px, insets %.0f and %.0f dp, %s)" % [path, image.get_width(), image.get_height(),
		window.z, window.w, ARRANGEMENTS[area.arrangement()]])
	print("  board %.1f dp, keys %.1f by %.1f dp, info zone %.1f by %.1f dp" % [area.view.board_square().size.x,
		area.pad.control_rect_global(&"pad:1").size.x, area.pad.control_rect_global(&"pad:1").size.y,
		area.info_zone_rect().size.x, area.info_zone_rect().size.y])
	nodes[0].free()


## An Easy puzzle part way: some digits placed, candidates crossed by hand in
## a few cells, one cell selected in Cross Out mode, and a hint on screen.
func _puzzle_in_progress() -> GameSession:
	var puzzle: Puzzle = PuzzleSource.get_puzzle(Levels.EASY, 7)
	var session: GameSession = GameSession.create(puzzle.id, puzzle.level, puzzle.givens, puzzle.solution, false)
	var placed: int = 0
	for cell: int in Sudoku.CELLS:
		if session.board.digit(cell) == 0 and placed < 8 and cell % 4 == 1:
			session.select(cell)
			session.press_digit(puzzle.solution[cell])
			placed += 1
	session.set_mode(GameSession.Mode.CROSS_OUT)
	var crossed_cells: int = 0
	for cell: int in Sudoku.CELLS:
		if session.board.digit(cell) != 0 or crossed_cells >= 6:
			continue
		session.select(cell)
		for d: int in range(1, 10):
			if session.board.is_ruled_out(cell, d):
				session.press_digit(d)
		crossed_cells += 1
	session.buy_hint(NextStep.find(session.solution, session.board))
	for cell: int in range(40, Sudoku.CELLS):
		if session.board.digit(cell) == 0:
			session.select(cell)
			break
	return session


func _fit_report() -> void:
	print("Fit report: pad buttons whose theme content needs more than their face (dp)")
	var problems: int = 0
	for screen: Vector4 in [Vector4(320, 568, 32, 24), Vector4(360, 800, 32, 24), Vector4(1024, 1366, 24, 24)]:
		var nodes: Array[Control] = _screen(Fx.light(), Vector2(screen.x, screen.y), screen.z, screen.w)
		var area: PlayArea = nodes[1] as PlayArea
		await process_frame
		for control: StringName in NAMES:
			var node_name: String = NODE_NAMES.get(control, "Digit" + String(control).substr(4))
			var button: Button = area.pad.find_child(node_name, true, false) as Button
			var face: Vector2 = area.pad.control_rect_global(control).size
			var clipped: bool = button.clip_text
			button.clip_text = false
			var needed: Vector2 = button.get_combined_minimum_size()
			button.clip_text = clipped
			if needed.x > face.x + 0.5 or needed.y > face.y + 0.5:
				problems += 1
				print("  %.0f by %.0f: %s face %.1f by %.1f, content needs %.0f by %.0f" % [screen.x, screen.y, control, face.x, face.y, needed.x, needed.y])
		nodes[0].free()
	print("  %d found" % problems)
