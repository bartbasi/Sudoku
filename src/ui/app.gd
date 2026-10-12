class_name AppService
extends Node
## The "App" autoload (docs/ARCHITECTURE.md section 11): settings, stats,
## lesson progress, the puzzle in progress, saving, navigation between
## screens and the Android lifecycle.
##
## The class name is AppService because the autoload itself is called App.
## Screens get this node through their app property, which goto() sets, so
## nothing here needs the autoload names to exist at compile time. Skins and
## Audio are found by path at startup; tests construct an AppService directly
## and point save_dir at a folder of their own under user://.
## Owner: ui-systems-dev.

signal settings_changed()
signal stats_changed()
signal session_changed(session: GameSession)
signal generation_started(level: int)
signal generation_finished(session: GameSession)

const SETTINGS_FILE: String = "settings.json"
const STATS_FILE: String = "stats.json"
const LESSONS_FILE: String = "lessons.json"
const PUZZLE_FILE: String = "puzzle.json"

const MAIN_MENU: StringName = &"main_menu"
const FIRST_LAUNCH: StringName = &"first_launch"
const LEVEL_SELECT: StringName = &"level_select"
const PLAY: StringName = &"play"
const COMPLETION: StringName = &"completion"
const STATS: StringName = &"stats"
const SETTINGS: StringName = &"settings"
const LESSONS: StringName = &"lessons"
const LESSON: StringName = &"lesson"

const SCREEN_PATHS: Dictionary[StringName, String] = {
	MAIN_MENU: "res://scenes/ui/main_menu.tscn",
	FIRST_LAUNCH: "res://scenes/ui/first_launch.tscn",
	LEVEL_SELECT: "res://scenes/ui/level_select.tscn",
	PLAY: "res://scenes/ui/play_screen.tscn",
	COMPLETION: "res://scenes/ui/completion.tscn",
	STATS: "res://scenes/ui/stats_screen.tscn",
	SETTINGS: "res://scenes/ui/settings_screen.tscn",
	LESSONS: "res://scenes/lessons/lessons_screen.tscn",
	LESSON: "res://scenes/lessons/lesson_player.tscn",
}
## Screens that start a fresh stack: nothing sits under them, so Back on
## them never uncovers an old screen.
const ROOT_SCREENS: Array[StringName] = [MAIN_MENU, FIRST_LAUNCH, PLAY, COMPLETION]
const FIRST_LESSON_ID: String = "lesson_01"

const GeneratingOverlay := preload("res://src/ui/generating_overlay.gd")

var settings: Settings = Settings.new()
var stats: Stats = Stats.new()
var lessons: LessonProgress = LessonProgress.new()
var session: GameSession = null

## Folder of the four save files. Always under user://; tests use a folder
## of their own.
var save_dir: String = "user://"
## Generate puzzles on a worker thread. Tests turn it off, because they run
## without frames.
var use_thread: bool = true
## The Skins and Audio services. Found at /root/Skins and /root/Audio when
## App enters the tree, unless a test set them first.
var skins: Node = null
var audio: Node = null

var _host: Control = null
var _stack: Array[Control] = []
var _names: Array[StringName] = []
var _thread: Thread = null
var _overlay: Control = null
var _fallback_skins: Dictionary[StringName, GameSkin] = {}


func _ready() -> void:
	if skins == null:
		skins = get_node_or_null(^"/root/Skins")
	if audio == null:
		audio = get_node_or_null(^"/root/Audio")
	if skins != null and skins.has_signal(&"skin_changed"):
		skins.connect(&"skin_changed", _on_skin_changed)
	set_process(false)
	load_all()
	_apply_audio()
	_apply_skin()
	var window: Window = get_tree().root
	window.size_changed.connect(_on_window_resized)
	_apply_dp_scale()


func _exit_tree() -> void:
	_join_thread()


func _process(_delta: float) -> void:
	if _thread != null and not _thread.is_alive():
		var puzzle: Puzzle = _thread.wait_to_finish() as Puzzle
		_thread = null
		set_process(false)
		_finish_generation(puzzle)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST:
			save_all()
			_pause_play_screen()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			go_back()
		NOTIFICATION_PREDELETE:
			_join_thread()


# Loading and saving -----------------------------------------------------------

## Reads all four files. Each part that is missing or fails validation takes
## its default (for the puzzle: none in progress); the others load as saved.
func load_all() -> void:
	settings = Settings.from_dict(SaveStore.read(path_of(SETTINGS_FILE), SaveStore.MAX_BYTES_OTHER))
	stats = Stats.from_dict(SaveStore.read(path_of(STATS_FILE), SaveStore.MAX_BYTES_OTHER))
	lessons = LessonProgress.from_dict(SaveStore.read(path_of(LESSONS_FILE), SaveStore.MAX_BYTES_OTHER))
	var loaded: GameSession = load_session_file()
	_set_session(loaded)
	if loaded != null:
		# One source of truth for Auto Cross: the setting.
		loaded.set_auto_cross(settings.auto_cross)
	session_changed.emit(session)


## The saved puzzle in progress, or null when there is none or it does not
## validate. Beyond GameSession.from_dict, the id must parse and name the
## same level.
func load_session_file() -> GameSession:
	var data: Variant = SaveStore.read(path_of(PUZZLE_FILE), SaveStore.MAX_BYTES_PUZZLE)
	if data == null:
		return null
	var loaded: GameSession = GameSession.from_dict(data)
	if loaded == null or loaded.is_completed:
		return null
	var parsed: Dictionary = PuzzleId.parse(loaded.puzzle_id)
	if parsed.is_empty() or int(parsed.get("level", -1)) != loaded.level:
		return null
	return loaded


func path_of(file_name: String) -> String:
	return save_dir.path_join(file_name)


## Writes the puzzle in progress. Does nothing when there is none, and never
## writes a completed session, so a finished puzzle cannot come back as
## Continue (GDD 12, AT-51).
func save_session() -> void:
	if session == null or session.is_completed:
		return
	SaveStore.write(path_of(PUZZLE_FILE), session.to_dict())


func save_all() -> void:
	_save_settings()
	_save_stats()
	_save_lessons()
	save_session()


func _save_settings() -> void:
	SaveStore.write(path_of(SETTINGS_FILE), settings.to_dict())


func _save_stats() -> void:
	SaveStore.write(path_of(STATS_FILE), stats.to_dict())


func _save_lessons() -> void:
	SaveStore.write(path_of(LESSONS_FILE), lessons.to_dict())


# The puzzle in progress -------------------------------------------------------

func has_puzzle_in_progress() -> bool:
	return session != null and not session.is_completed


func is_generating() -> bool:
	return _thread != null


## Picks a seed, makes the puzzle (on a worker thread unless use_thread is
## off), creates the session with the Auto Cross setting, records Started,
## saves, emits generation_finished and opens the play screen. Ignored while
## another puzzle is being made. Call abandon_puzzle() first when one is in
## progress; if one still is when the new puzzle is ready, it is abandoned
## then, so there is never more than one.
func start_new_puzzle(level: int) -> void:
	if not Levels.is_valid(level) or is_generating():
		return
	var seed_value: int = PuzzleSource.pick_seed(level, randi())
	generation_started.emit(level)
	if not use_thread:
		_finish_generation(PuzzleSource.get_puzzle(level, seed_value))
		return
	_show_overlay()
	_thread = Thread.new()
	var make: Callable = func() -> Puzzle:
		return PuzzleSource.get_puzzle(level, seed_value)
	if _thread.start(make) != OK:
		_thread = null
		_finish_generation(PuzzleSource.get_puzzle(level, seed_value))
		return
	set_process(true)


## Deletes the saved puzzle and its undo history and drops the session.
## Stats do not change (GDD 13.2).
func abandon_puzzle() -> void:
	_set_session(null)
	SaveStore.remove(path_of(PUZZLE_FILE))
	session_changed.emit(null)


## Call once the session has completed. In GDD 12 order: records the stats
## (the New best bits come from the bests before this completion), saves
## them, deletes the saved puzzle, drops the session, and returns what the
## completion screen shows. Null if there is no completed session.
func on_puzzle_completed() -> CompletionResult:
	if session == null or not session.is_completed:
		return null
	var result: CompletionResult = CompletionResult.new()
	result.level = session.level
	result.seconds = session.elapsed_seconds()
	result.points_after_hints = session.score()
	result.time_bonus = session.time_bonus()
	result.final_score = session.final_score()
	result.hints_used = session.hints_bought
	result.new_best = stats.record_completion(result.level, result.seconds, result.final_score)
	_save_stats()
	SaveStore.remove(path_of(PUZZLE_FILE))
	_set_session(null)
	stats_changed.emit()
	session_changed.emit(null)
	return result


func _finish_generation(puzzle: Puzzle) -> void:
	_hide_overlay()
	var created: GameSession = null
	if puzzle != null:
		created = GameSession.create(puzzle.id, puzzle.level, puzzle.givens, puzzle.solution, settings.auto_cross)
	if created == null:
		push_error("App: the puzzle could not be made")
		generation_finished.emit(null)
		return
	if session != null:
		abandon_puzzle()
	_set_session(created)
	stats.record_start(created.level)
	_save_stats()
	save_session()
	stats_changed.emit()
	session_changed.emit(created)
	generation_finished.emit(created)
	if _host != null:
		goto(PLAY)


func _set_session(new_session: GameSession) -> void:
	if session != null:
		for pair: Array in _session_links():
			if session.is_connected(pair[0], pair[1]):
				session.disconnect(pair[0], pair[1])
	session = new_session
	if session != null:
		for pair: Array in _session_links():
			session.connect(pair[0], pair[1])


## The session signals that save the puzzle (ARCHITECTURE section 11).
func _session_links() -> Array[Array]:
	return [
		[&"board_changed", _on_board_changed],
		[&"mode_changed", _on_mode_changed],
		[&"hint_changed", _on_hint_changed],
	]


func _on_board_changed(_cells: PackedInt32Array) -> void:
	save_session()


func _on_mode_changed(_mode: int) -> void:
	save_session()


func _on_hint_changed(_hint: Hint) -> void:
	save_session()


func _join_thread() -> void:
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null


# Settings, stats and lessons --------------------------------------------------

func set_sound(on: bool) -> void:
	settings.sound = on
	_apply_audio()
	_save_settings()
	settings_changed.emit()


## Only the built-in skins (Settings.SKIN_IDS); anything else is ignored.
func set_skin(id: StringName) -> void:
	if not Settings.SKIN_IDS.has(id):
		return
	settings.skin_id = id
	_save_settings()
	_apply_skin()
	settings_changed.emit()


## Also applies to the puzzle in progress, at once.
func set_auto_cross(on: bool) -> void:
	settings.auto_cross = on
	_save_settings()
	if session != null:
		session.set_auto_cross(on)
		save_session()
	settings_changed.emit()


## Clears every level's stats; the level of a puzzle in progress keeps
## Started at 1. Lesson progress is kept (Bart, Hard Stop 1).
func reset_stats() -> void:
	stats.reset(session.level if has_puzzle_in_progress() else -1)
	_save_stats()
	stats_changed.emit()


func record_lesson_finished(lesson_id: String) -> void:
	if lessons.mark_finished(lesson_id):
		_save_lessons()
		stats_changed.emit()


func answer_first_launch() -> void:
	settings.first_launch_answered = true
	_save_settings()
	settings_changed.emit()


## The skin in use: the Skins service's current skin, or, without the
## service, the built-in skin the settings name.
func current_skin() -> GameSkin:
	if skins != null:
		var current: GameSkin = skins.get(&"current") as GameSkin
		if current != null:
			return current
	return builtin_skin(settings.skin_id)


## A built-in skin by id, loaded from res://src/skins/; unknown ids give the
## default. Used when the Skins service is missing and for the skin previews.
func builtin_skin(id: StringName) -> GameSkin:
	if skins != null and skins.has_method(&"get_skin"):
		var found: GameSkin = skins.call(&"get_skin", id) as GameSkin
		if found != null:
			return found
	var key: StringName = id if Settings.SKIN_IDS.has(id) else Settings.DEFAULT_SKIN_ID
	if not _fallback_skins.has(key):
		_fallback_skins[key] = load("res://src/skins/%s.tres" % key) as GameSkin
	return _fallback_skins[key]


func _apply_audio() -> void:
	if audio != null:
		audio.set(&"enabled", settings.sound)


func _apply_skin() -> void:
	if skins != null and skins.has_method(&"apply"):
		# Emits skin_changed, which rebuilds the theme.
		skins.call(&"apply", settings.skin_id)
	else:
		_apply_theme()


func _on_skin_changed(_skin: GameSkin) -> void:
	_apply_theme()


func _apply_theme() -> void:
	if is_inside_tree():
		get_tree().root.theme = ThemeFactory.build(current_skin())


# Navigation ---------------------------------------------------------------------

## Called by the main scene: screens go into host. Opens the first launch
## offer until it is answered, otherwise the main menu.
func attach_host(host: Control) -> void:
	_host = host
	goto(MAIN_MENU if settings.first_launch_answered else FIRST_LAUNCH)


func current_screen() -> StringName:
	return _names.back() if not _names.is_empty() else &""


func current_screen_node() -> Control:
	return _stack.back() if not _stack.is_empty() else null


## Opens a screen. The main menu, the first launch offer, the play screen and
## the completion screen start a fresh stack; the others go on top of the
## current screen, which stays under them, hidden, until Back. The payload
## goes to the screen's open() before it enters the tree; a lesson gets it
## through LessonPlayer.start().
func goto(screen: StringName, payload: Variant = null) -> void:
	if _host == null:
		return
	if not SCREEN_PATHS.has(screen):
		push_error("App: unknown screen %s" % screen)
		return
	var path: String = SCREEN_PATHS[screen]
	if not ResourceLoader.exists(path):
		push_warning("App: the %s screen is not built yet" % screen)
		return
	var scene: PackedScene = load(path) as PackedScene
	var node: Control = scene.instantiate() as Control if scene != null else null
	if node == null:
		push_error("App: %s is not a Control scene" % path)
		return
	if "app" in node:
		node.set(&"app", self)
	if node.has_method(&"open"):
		node.call(&"open", payload)
	_leave_top()
	if ROOT_SCREENS.has(screen):
		_clear_stack()
	elif not _stack.is_empty():
		_stack.back().visible = false
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.add_child(node)
	if node.has_method(&"ensure_built"):
		node.call(&"ensure_built")
	_stack.append(node)
	_names.append(screen)
	if screen == LESSON:
		_wire_lesson(node, payload)
	_keep_overlay_on_top()
	_animate_in(node)


## Back: the screen on top handles it first (a dialog closes, the play
## screen opens or closes its pause menu). Otherwise the top screen closes
## and the one under it shows again. On the last screen Back leaves the app,
## after saving.
func go_back() -> void:
	if is_generating() or _stack.is_empty():
		return
	var top: Control = _stack.back()
	if top.has_method(&"handle_back") and bool(top.call(&"handle_back")):
		return
	if _stack.size() > 1:
		_pop()
	elif is_inside_tree():
		save_all()
		get_tree().quit()


## Opens lesson 1 over the main menu (the first launch offer's Start lesson).
## Falls back to the lessons list, or the main menu, if the lessons are not
## available.
func open_first_lesson() -> void:
	goto(MAIN_MENU)
	var lesson: Object = _find_lesson(FIRST_LESSON_ID)
	if lesson != null:
		goto(LESSON, lesson)
	else:
		goto(LESSONS)


func _pop() -> void:
	_leave_top()
	var top: Control = _stack.pop_back()
	_names.pop_back()
	_host.remove_child(top)
	top.queue_free()
	if not _stack.is_empty():
		var under: Control = _stack.back()
		under.visible = true
		if under.has_method(&"on_shown"):
			under.call(&"on_shown")


func _clear_stack() -> void:
	for node: Control in _stack:
		_host.remove_child(node)
		node.queue_free()
	_stack.clear()
	_names.clear()


## The play screen is being covered or closed: save the puzzle (GDD 14).
func _leave_top() -> void:
	if current_screen() == PLAY:
		save_session()


func _pause_play_screen() -> void:
	var top: Control = current_screen_node()
	if current_screen() == PLAY and top != null and top.has_method(&"show_pause"):
		top.call(&"show_pause")


func _wire_lesson(node: Control, payload: Variant) -> void:
	if node.has_signal(&"finished"):
		node.connect(&"finished", record_lesson_finished)
	if node.has_signal(&"closed"):
		node.connect(&"closed", go_back)
	if payload != null and node.has_method(&"start"):
		node.call(&"start", payload)


## Finds a lesson through LessonLibrary (lessons-dev), looked up by name so
## this file does not depend on it being built.
func _find_lesson(lesson_id: String) -> Object:
	var library: Script = global_script(&"LessonLibrary")
	if library == null:
		return null
	var all: Variant = library.call(&"load_all")
	if typeof(all) != TYPE_ARRAY:
		return null
	for item: Variant in all:
		if item is Object and (item as Object).get(&"id") == lesson_id:
			return item
	return null


## A script with a global class_name, or null if there is none.
static func global_script(class_id: StringName) -> Script:
	for info: Dictionary in ProjectSettings.get_global_class_list():
		if StringName(info.get("class", "")) == class_id:
			return load(String(info.get("path", ""))) as Script
	return null


func _animate_in(node: Control) -> void:
	if not node.is_inside_tree():
		return
	var shift: float = current_skin().space_xl
	node.modulate.a = 0.0
	node.position.x = shift
	var tween: Tween = node.create_tween().set_parallel(true)
	tween.tween_property(node, ^"modulate:a", 1.0, Motion.SCREEN_IN).set_trans(Motion.trans(&"SCREEN_IN")).set_ease(Motion.ease_of(&"SCREEN_IN"))
	tween.tween_property(node, ^"position:x", 0.0, Motion.SCREEN_IN).set_trans(Motion.trans(&"SCREEN_IN")).set_ease(Motion.ease_of(&"SCREEN_IN"))


func _show_overlay() -> void:
	if _host == null or _overlay != null:
		return
	_overlay = GeneratingOverlay.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.add_child(_overlay)


func _hide_overlay() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null


func _keep_overlay_on_top() -> void:
	if _overlay != null and _host != null:
		_host.move_child(_overlay, -1)


# Screen size ----------------------------------------------------------------------

func _on_window_resized() -> void:
	_apply_dp_scale()


## One canvas unit is one dp (ARCHITECTURE section 2).
func _apply_dp_scale() -> void:
	if is_inside_tree():
		ScreenMetrics.apply_dp_scale(get_tree().root)
