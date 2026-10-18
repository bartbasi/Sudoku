extends SceneTree
## Screenshots of the ui screens. Not a test file: the runner only runs
## tests/<area>/test_*.gd. Needs a window (headless mode has no renderer):
##
##   timeout 300 godot --path . --script res://tests/ui/capture_screens.gd
##   timeout 300 godot --path . --script res://tests/ui/capture_screens.gd -- 320x568
##   timeout 300 godot --path . --script res://tests/ui/capture_screens.gd -- windows
##   timeout 300 godot --path . --script res://tests/ui/capture_screens.gd -- title <folder>
##   timeout 300 godot --path . --script res://tests/ui/capture_screens.gd -- candidates <folder>
##   timeout 300 godot --path . --script res://tests/ui/capture_screens.gd -- license <folder>
##
## Writes build/ui/<size>-<skin>-<screen>.png. Saves go to
## user://ui_capture/, which is wiped first, so real saves are untouched.
## "windows" captures the main menu, play, pause and completion on the
## DESIGN_SYSTEM.md 4.11 windows in WINDOW_SIZES, then the too small layer
## at TOO_SMALL_SIZE, resizing one window as a fold or a split screen would.
## "title" captures the title screen (Pop light and Pop dark), Info at the
## top and About at the top and partway into the notices, on TITLE_SIZES,
## into the folder given (absolute), or build/ui/ when none is.
## "candidates" captures Settings at 360 by 800, then a Medium puzzle with
## Show candidates off on TITLE_SIZES: with hand crosses hidden, and with an
## elimination hint showing only its candidates to cross (GDD 4.5, SC-3).
## "license" captures About at 360 by 800 in Pop light: the card, then the
## notices scrolled to the Sudoku notice and to the GNU GPL.

const OUT_DIR: String = "res://build/ui/"
const SAVE_DIR: String = "user://ui_capture"
const AboutScreen := preload("res://src/ui/about_screen.gd")

## The 4.11 windows of the "windows" run (no insets on desktop).
const WINDOW_SIZES: Array[Vector2i] = [Vector2i(344, 882), Vector2i(690, 829), Vector2i(345, 829), Vector2i(690, 400)]
const TOO_SMALL_SIZE: Vector2i = Vector2i(344, 430)

## 360 by 800 and 320 by 568 stacked, 690 by 400 side by side.
const TITLE_SIZES: Array[Vector2i] = [Vector2i(360, 800), Vector2i(320, 568), Vector2i(690, 400)]

var _size: Vector2i = Vector2i(360, 800)
var _windows: bool = false
var _title: bool = false
var _candidates: bool = false
var _license: bool = false
var _out_dir: String = OUT_DIR
var _app: AppService = null
var _skins: Node = null


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0 and args[0] == "windows":
		_windows = true
	elif args.size() > 0 and (args[0] == "title" or args[0] == "candidates" or args[0] == "license"):
		_title = args[0] == "title"
		_candidates = args[0] == "candidates"
		_license = args[0] == "license"
		if args.size() > 1:
			_out_dir = args[1].replace("\\", "/")
			if not _out_dir.ends_with("/"):
				_out_dir += "/"
	elif args.size() > 0 and args[0].contains("x"):
		var parts: PackedStringArray = args[0].split("x")
		_size = Vector2i(parts[0].to_int(), parts[1].to_int())
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	_wipe(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	root.size = _size
	root.content_scale_size = _size
	DisplayServer.window_set_size(_size)

	# The Skins and App autoloads drive the main scene; they are made here
	# only if the project has none. Their saves move to SAVE_DIR before
	# anything is written, so real saves are read at startup but never changed.
	_skins = root.get_node_or_null(^"Skins")
	if _skins == null:
		_skins = (load("res://src/skins/skin_service.gd") as GDScript).new() as Node
		_skins.name = "Skins"
		root.add_child(_skins)
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
	var host: Control = (load("res://scenes/ui/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(host)
	await _settle()
	if _windows:
		await _run_windows()
		return
	if _title:
		await _run_title()
		return
	if _candidates:
		await _run_candidates()
		return
	if _license:
		await _run_license()
		return
	await _shot("light", "title")
	_app.play_now()
	await _shot("light", "first_launch")

	_app.answer_first_launch()
	_app.goto(AppService.MAIN_MENU)
	await _shot("light", "main_menu_new")

	_app.start_new_puzzle(Levels.MEDIUM)
	_app.session.add_time(768.0)
	var cells: PackedInt32Array = PackedInt32Array()
	for cell: int in Sudoku.CELLS:
		if _app.session.board.digits[cell] == 0:
			cells.append(cell)
	_app.session.select(cells[3])
	_app.session.press_digit(_app.session.solution[cells[3]])
	_app.session.set_mode(GameSession.Mode.CROSS_OUT)
	_app.session.select(cells[0])
	_app.session.press_digit(1)
	_app.session.press_digit(5)
	await _shot("light", "play")
	var play: Control = _app.current_screen_node()
	play.call(&"buy_hint")
	await _shot("light", "hint_panel")
	_app.session.close_hint()
	play.call(&"show_pause")
	await _shot("light", "pause")
	play.call(&"resume")
	_app.goto(AppService.MAIN_MENU)
	await _shot("light", "main_menu")

	_app.goto(AppService.LEVEL_SELECT)
	await _shot("light", "level_select")
	await _making("light")
	(_app.current_screen_node().get(&"level_buttons") as Array)[Levels.HARD].pressed.emit()
	await _shot("light", "new_puzzle_confirm")
	(_app.current_screen_node().get(&"confirm") as ConfirmDialog).cancel()

	_app.stats.record_start(Levels.EASY)
	_app.stats.record_start(Levels.EASY)
	_app.stats.record_completion(Levels.EASY, 300, 276)
	_app.stats.record_completion(Levels.EASY, 401, 208)
	_app.record_lesson_finished("lesson_01")
	_app.record_lesson_finished("lesson_02")
	_app.goto(AppService.STATS)
	await _shot("light", "stats")

	_app.goto(AppService.SETTINGS)
	await _shot("light", "settings")
	(_app.current_screen_node().get(&"reset_button") as Button).pressed.emit()
	await _shot("light", "reset_confirm")
	(_app.current_screen_node().get(&"confirm") as ConfirmDialog).cancel()

	var result: CompletionResult = CompletionResult.new()
	result.level = Levels.HARD
	result.seconds = 1350
	result.points_after_hints = 420
	result.time_bonus = 175
	result.final_score = 595
	result.hints_used = 2
	result.new_best = Stats.NEW_BEST_TIME | Stats.NEW_BEST_SCORE
	_app.goto(AppService.COMPLETION, result)
	await _shot("light", "completion")

	_app.set_skin(&"pop_dark")
	_app.start_new_puzzle(Levels.EASY)
	_app.session.select(40)
	await _shot("dark", "play")
	_app.goto(AppService.MAIN_MENU)
	await _shot("dark", "main_menu")
	_app.goto(AppService.SETTINGS)
	await _shot("dark", "settings")
	_app.goto(AppService.COMPLETION, result)
	await _shot("dark", "completion")
	_app.goto(AppService.LEVEL_SELECT)
	await _making("dark")

	_app.set_skin(&"pop_light")
	_app.abandon_puzzle()
	_wipe(SAVE_DIR)
	quit(0)


## The 4.11 windows: one Medium puzzle in progress, then for each window the
## main menu, play, pause and completion; last the too small layer over the
## play screen, which opens the pause menu under it.
func _run_windows() -> void:
	_app.answer_first_launch()
	_app.start_new_puzzle(Levels.MEDIUM)
	_app.session.add_time(380.0)
	var cells: PackedInt32Array = PackedInt32Array()
	for cell: int in Sudoku.CELLS:
		if _app.session.board.digits[cell] == 0:
			cells.append(cell)
	_app.session.select(cells[3])
	_app.session.press_digit(_app.session.solution[cells[3]])
	_app.session.set_mode(GameSession.Mode.CROSS_OUT)
	_app.session.select(cells[0])
	_app.session.press_digit(1)
	_app.session.press_digit(5)
	var result: CompletionResult = CompletionResult.new()
	result.level = Levels.HARD
	result.seconds = 1350
	result.points_after_hints = 420
	result.time_bonus = 175
	result.final_score = 595
	result.hints_used = 2
	result.new_best = Stats.NEW_BEST_TIME | Stats.NEW_BEST_SCORE
	for window: Vector2i in WINDOW_SIZES:
		_resize(window)
		_app.goto(AppService.MAIN_MENU)
		await _shot("light", "main_menu")
		_app.goto(AppService.PLAY)
		await _shot("light", "play")
		var play: Control = _app.current_screen_node()
		play.call(&"show_pause")
		await _shot("light", "pause")
		play.call(&"resume")
		_app.goto(AppService.COMPLETION, result)
		await _shot("light", "completion")
	_resize(WINDOW_SIZES[0])
	_app.goto(AppService.PLAY)
	await _settle()
	_resize(TOO_SMALL_SIZE)
	await _shot("light", "too_small")
	_resize(WINDOW_SIZES[0])
	await _shot("light", "too_small_left")
	_app.abandon_puzzle()
	_wipe(SAVE_DIR)
	quit(0)


## The title screen in both skins, Info at the top, About at the top and
## partway into the notices, on each of TITLE_SIZES.
func _run_title() -> void:
	for window: Vector2i in TITLE_SIZES:
		_resize(window)
		for skin_id: StringName in [&"pop_light", &"pop_dark"]:
			_app.set_skin(skin_id)
			_app.goto(AppService.TITLE)
			await _shot(String(skin_id).trim_prefix("pop_"), "title")
		_app.set_skin(&"pop_light")
		_app.goto(AppService.TITLE)
		_app.goto(AppService.INFO)
		await _shot("light", "info")
		_app.go_back()
		_app.goto(AppService.ABOUT)
		await _shot("light", "about")
		var about: Control = _app.current_screen_node()
		var scroll: ScrollContainer = about.get(&"scroll") as ScrollContainer
		await _settle()
		var notices: Control = about.get(&"notices") as Control
		scroll.scroll_vertical = int(notices.get_global_rect().position.y - scroll.get_global_rect().position.y) + 600
		await _shot("light", "about_notices")
		_app.go_back()
	_wipe(SAVE_DIR)
	quit(0)


## About in Pop light at 360 by 800: the card at the top, then the notices
## with the Sudoku caption and then the GPL caption at the top of the page.
func _run_license() -> void:
	_resize(TITLE_SIZES[0])
	_app.set_skin(&"pop_light")
	_app.goto(AppService.TITLE)
	_app.goto(AppService.ABOUT)
	await _shot("light", "about")
	var about: Control = _app.current_screen_node()
	about.call(&"build_all_notices")
	await _settle()
	var scroll: ScrollContainer = about.get(&"scroll") as ScrollContainer
	var notices: Control = about.get(&"notices") as Control
	var names: Array[Array] = [[AboutScreen.NOTICE_CAPTION, "about_sudoku_notice"], [AboutScreen.GPL_CAPTION, "about_gpl"]]
	for pair: Array in names:
		var caption: String = ThemeFactory.display_text(ThemeFactory.CAPTION, pair[0])
		for child: Node in notices.get_children():
			if child is Label and (child as Label).text == caption:
				var top: float = (child as Control).get_global_rect().position.y - scroll.get_global_rect().position.y + float(scroll.scroll_vertical)
				scroll.scroll_vertical = int(top) - 8
				break
		await _shot("light", pair[1])
	_app.go_back()
	_wipe(SAVE_DIR)
	quit(0)


## Settings, then the play screen with Show candidates off, without and with
## an elimination hint on screen. Placement hints are followed by placing
## their digit (no charge) until the next step is an elimination.
func _run_candidates() -> void:
	_resize(TITLE_SIZES[0])
	_app.answer_first_launch()
	_app.goto(AppService.SETTINGS)
	await _shot("light", "settings")
	_app.start_new_puzzle(Levels.MEDIUM)
	var session: GameSession = _app.session
	session.add_time(312.0)
	var cells: PackedInt32Array = PackedInt32Array()
	for cell: int in Sudoku.CELLS:
		if session.board.digits[cell] == 0:
			cells.append(cell)
	var hint: Hint = null
	for i: int in Sudoku.CELLS:
		hint = NextStep.find(session.solution, session.board)
		if hint == null or hint.placement_cell < 0:
			break
		session.select(hint.placement_cell)
		session.press_digit(hint.placement_digit)
	print("next step: ", hint.technique if hint != null else &"none")
	# Hand crosses in the last empty cell, of digits its peers already hold.
	var marked: int = -1
	for cell: int in Sudoku.CELLS:
		if session.board.digits[cell] == 0:
			marked = cell
	session.set_mode(GameSession.Mode.CROSS_OUT)
	session.select(marked)
	var crossed: int = 0
	for peer: int in Sudoku.peers(marked):
		var d: int = session.board.digits[peer]
		if d != 0 and crossed < 3 and session.board.mark(marked, d) == Board.Mark.OPEN:
			session.press_digit(d)
			crossed += 1
	_app.set_show_candidates(false)
	for window: Vector2i in TITLE_SIZES:
		_resize(window)
		_app.goto(AppService.PLAY)
		await _shot("light", "play_hidden")
	var play: Control = _app.current_screen_node()
	play.call(&"buy_hint")
	for window: Vector2i in TITLE_SIZES:
		_resize(window)
		await _shot("light", "hint_hidden")
	_app.set_show_candidates(true)
	_resize(TITLE_SIZES[0])
	await _shot("light", "hint_shown")
	_app.abandon_puzzle()
	_wipe(SAVE_DIR)
	quit(0)


## Gives the window a new size, as a fold or a split screen divider would.
## App hears size_changed and re-checks the arrangement.
func _resize(window: Vector2i) -> void:
	_size = window
	DisplayServer.window_set_size(window)
	root.size = window
	root.content_scale_size = window


## Making a puzzle (DESIGN_SYSTEM.md 7.14) over the level select, after
## MAKING_DELAY, so the card shows. The overlay goes again without a puzzle.
func _making(skin_name: String) -> void:
	_app.call(&"_show_overlay", Levels.HARD)
	var overlay: Control = _app.get(&"_overlay") as Control
	await _shot(skin_name, "making")
	_app.set(&"_overlay", null)
	_app.call(&"_leave_overlay", overlay)
	await _settle()


func _settle() -> void:
	for i: int in 60:
		await process_frame


func _shot(skin_name: String, screen: String) -> void:
	await _settle()
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = _out_dir + "%dx%d-%s-%s.png" % [_size.x, _size.y, skin_name, screen]
	image.save_png(ProjectSettings.globalize_path(path))
	print("wrote ", path)


func _wipe(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for file: String in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file))
