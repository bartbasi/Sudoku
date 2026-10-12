extends "res://tests/unit_test.gd"
## Window shapes (DESIGN_SYSTEM.md 4.11, GDD 2.4 and 8.1), what happens
## rather than where things sit: a window change keeps the puzzle, the
## header row mirrors side by side, and the too small layer (the timer
## stops, the puzzle is saved, the Back rule, back on the pause menu, a
## puzzle made while too small opens paused).
##
## Where things sit is checked by window_check.gd in a running scene tree
## (test_window_layout.gd runs it): the runner keeps nodes outside the tree,
## where box containers do not lay out. PlayArea lays itself out by hand, so
## the play screen's arrangement works here too.

const Fx := preload("res://tests/save/save_fixtures.gd")
const Model := preload("res://tools/design/layout_model.gd")

const COVER: Array = [344.0, 882.0, 32.0, 24.0]
const COVER_HALF: Array = [344.0, 430.0, 32.0, 0.0]
const COVER_HALF_SIZE: Vector2 = Vector2(344, 430)

var _dirs: Array[String] = []


## A window shape: label, size, safe rect and the arrangement 4.11 expects.
class Shape extends RefCounted:
	var label: String
	var size: Vector2
	var safe: Rect2
	var expected: int = -1


func _shape(label: String, w: float, h: float, top: float, bottom: float, expected: int = -1) -> Shape:
	var out: Shape = Shape.new()
	out.label = label
	out.size = Vector2(w, h)
	out.safe = Rect2(0.0, top, w, h - top - bottom)
	out.expected = expected
	return out


## Every window of 4.11 and every screen of 4.10, from the design model.
func _all_shapes() -> Array[Shape]:
	var out: Array[Shape] = []
	var all: Array = Model.screens()
	all.append_array(Model.window_screens())
	for s: Model.Screen in all:
		out.append(_shape(s.label, s.w, s.h, s.top, s.bottom, s.expected))
	return out


func _app(window: Shape) -> Array:
	var dir: String = Fx.fresh_dir("windows")
	_dirs.append(dir)
	var app: AppService = AppService.new()
	app.save_dir = dir
	app.use_thread = false
	app.load_all()
	app.settings.first_launch_answered = true
	var host: Control = Control.new()
	host.theme = ThemeFactory.build(app.current_skin())
	host.size = window.size
	(Engine.get_main_loop() as SceneTree).root.add_child(host)
	app.attach_host(host)
	return [app, host]


func _teardown(parts: Array) -> void:
	var host: Control = parts[1]
	host.get_parent().remove_child(host)
	host.free()
	(parts[0] as AppService).free()
	for dir: String in _dirs:
		Fx.wipe(dir)
	_dirs.clear()


## Gives the screen on top its window and lays it out.
func _fit(app: AppService, window: Shape) -> Control:
	var screen: UiScreen = app.current_screen_node() as UiScreen
	screen.position = Vector2.ZERO
	screen.size = window.size
	screen.safe_rect_override = window.safe
	app.apply_window(window.safe)
	_lay_out(screen)
	return screen


## Lays out a screen: the play screen places PlayArea, PlayArea lays out,
## the play screen places the rest; then every container that can sorts.
func _lay_out(screen: Control) -> void:
	if screen.has_method(&"relayout"):
		screen.call(&"relayout")
		var area: PlayArea = screen.get(&"play_area") as PlayArea
		area.notification(Control.NOTIFICATION_RESIZED)
		screen.call(&"relayout")
	for i: int in 2:
		_theme_and_sort(screen)


func _theme_and_sort(node: Node) -> void:
	if node is Control:
		node.notification(Control.NOTIFICATION_THEME_CHANGED)
	if node is Container:
		node.notification(Container.NOTIFICATION_SORT_CHILDREN)
	for child: Node in node.get_children():
		_theme_and_sort(child)


# The play screen ------------------------------------------------------------------

func _play(window: Shape) -> Array:
	var parts: Array = _app(window)
	var app: AppService = parts[0]
	app.start_new_puzzle(Levels.MEDIUM)
	return parts


## The play screen's arrangement for each window agrees with 4.11, and the
## header row is mirrored exactly when side by side: Pause first, Hint last.
func test_the_header_row_mirrors_side_by_side() -> void:
	for window: Shape in _all_shapes():
		if window.expected == Layout.Arrangement.TOO_SMALL:
			continue
		var parts: Array = _play(window)
		var screen: Control = _fit(parts[0], window)
		var area: PlayArea = screen.get(&"play_area") as PlayArea
		var hud: PlayHud = screen.get(&"hud") as PlayHud
		var side: bool = window.expected == Layout.Arrangement.SIDE
		assert_eq(area.arrangement(), window.expected, "%s: the arrangement of 4.11" % window.label)
		assert_eq(hud.is_mirrored(), side, "%s: mirrored only side by side" % window.label)
		var first: Control = hud.pause_touch if side else hud.hint_touch
		var last: Control = hud.hint_touch if side else hud.pause_touch
		assert_eq(hud.get_child(0), first, "%s: %s first" % [window.label, first.name])
		assert_eq(hud.get_child(hud.get_child_count() - 1), last, "%s: %s at the far end" % [window.label, last.name])
		assert_eq(hud.get_child(2).name, &"Time", "%s: time then score in the middle" % window.label)
		assert_eq(hud.get_child(3), hud.score_block)
		_teardown(parts)


func test_a_window_change_keeps_the_puzzle_and_the_hint() -> void:
	# GDD 2.4: a fold or a dragged divider changes only the layout.
	var stacked: Shape = _shape("inner", 690.0, 829.0, 32.0, 24.0, Layout.Arrangement.STACKED)
	var side: Shape = _shape("inner top half", 690.0, 400.0, 32.0, 0.0, Layout.Arrangement.SIDE)
	var parts: Array = _play(stacked)
	var app: AppService = parts[0]
	var screen: Control = _fit(app, stacked)
	var cell: int = Fx.empty_cells(app.session)[4]
	app.session.select(cell)
	app.session.set_mode(GameSession.Mode.CROSS_OUT)
	screen.call(&"_process", 190.0)
	screen.call(&"buy_hint")
	var before: Dictionary = app.session.to_dict()
	screen = _fit(app, side)
	assert_eq((screen.get(&"play_area") as PlayArea).arrangement(), Layout.Arrangement.SIDE)
	assert_eq(app.session.to_dict(), before, "nothing about the puzzle changed")
	assert_true((screen.get(&"hint_panel") as HintPanel).visible, "the hint still shows")
	assert_false(bool(screen.call(&"is_paused")), "a shape change alone does not pause")
	assert_true(bool(screen.call(&"is_timer_running")), "and the timer keeps running")
	assert_true((screen.get(&"hud") as PlayHud).is_mirrored())
	screen = _fit(app, stacked)
	assert_false((screen.get(&"hud") as PlayHud).is_mirrored(), "back in order when stacked again")
	_teardown(parts)


# The too small layer (GDD 8.1) ------------------------------------------------------

func _cover() -> Shape:
	return _shape("cover", COVER[0], COVER[1], COVER[2], COVER[3], Layout.Arrangement.STACKED)


func _cover_half() -> Shape:
	return _shape("cover top half", COVER_HALF[0], COVER_HALF[1], COVER_HALF[2], COVER_HALF[3], Layout.Arrangement.TOO_SMALL)


func test_too_small_windows_are_too_small_and_others_are_not() -> void:
	for window: Shape in _all_shapes():
		var parts: Array = _app(window)
		var app: AppService = parts[0]
		app.apply_window(window.safe)
		var small: bool = window.expected == Layout.Arrangement.TOO_SMALL
		assert_eq(app.is_too_small(), small, "%s: too small is %s" % [window.label, small])
		assert_eq(app.too_small_layer() != null, small, "%s: the layer shows only when too small" % window.label)
		_teardown(parts)


func test_too_small_on_the_play_screen_pauses_saves_and_comes_back_paused() -> void:
	var parts: Array = _play(_cover())
	var app: AppService = parts[0]
	var host: Control = parts[1]
	var screen: Control = _fit(app, _cover())
	screen.call(&"_process", 380.0)
	var cell: int = Fx.empty_cells(app.session)[0]
	app.session.select(cell)
	app.session.set_mode(GameSession.Mode.CROSS_OUT)
	app.session.press_digit(4)
	SaveStore.remove(app.path_of(AppService.PUZZLE_FILE))
	var before: Dictionary = app.session.to_dict()

	app.apply_window(_cover_half().safe)
	assert_true(app.is_too_small())
	var layer: TooSmallLayer = app.too_small_layer()
	assert_true(layer != null and layer.get_parent() == host, "the layer is on the host")
	assert_eq(host.get_child(host.get_child_count() - 1), layer, "above every screen")
	assert_true(bool(screen.call(&"is_paused")), "the pause menu opens under it")
	assert_false(bool(screen.call(&"is_timer_running")), "the timer stops")
	screen.call(&"_process", 120.0)
	assert_eq(app.session.elapsed_seconds(), 380, "and stays at 6:20")
	var saved: GameSession = app.load_session_file()
	assert_true(saved != null, "the puzzle is saved")
	if saved != null:
		assert_eq(saved.elapsed_seconds(), 380)
		assert_eq(saved.selected, cell)

	# Back in the pause menu does nothing while the message shows.
	app.go_back()
	app.go_back()
	assert_true(bool(screen.call(&"is_paused")), "Back does not resume")
	assert_eq(app.current_screen(), AppService.PLAY)
	assert_eq(app.session.to_dict(), before, "nothing about the puzzle changed")

	app.apply_window(_cover().safe)
	assert_false(app.is_too_small())
	assert_eq(app.too_small_layer(), null, "the layer is gone")
	for child: Node in host.get_children():
		assert_false(child is TooSmallLayer, "no layer left on the host")
	assert_true(bool(screen.call(&"is_paused")), "back on the pause menu")
	assert_false(bool(screen.call(&"is_timer_running")), "the timer waits for Resume")
	app.go_back()
	assert_false(bool(screen.call(&"is_paused")), "Back resumes again once the window is big enough")
	screen.call(&"_process", 1.0)
	assert_eq(app.session.elapsed_seconds(), 381, "the timer runs on from 6:20")
	_teardown(parts)


func test_too_small_over_settings_from_the_pause_menu() -> void:
	var parts: Array = _play(_cover())
	var app: AppService = parts[0]
	var screen: Control = _fit(app, _cover())
	screen.call(&"show_pause")
	app.goto(AppService.SETTINGS)
	app.apply_window(_cover_half().safe)
	assert_eq(app.current_screen(), AppService.SETTINGS, "Settings stays")
	# Back does what it does on Settings: back to the pause menu.
	app.go_back()
	assert_eq(app.current_screen(), AppService.PLAY)
	assert_true(bool(screen.call(&"is_paused")), "on the pause menu")
	app.go_back()
	assert_true(bool(screen.call(&"is_paused")), "and there Back does nothing")
	app.apply_window(_cover().safe)
	assert_true(bool(screen.call(&"is_paused")), "the puzzle comes back paused")
	_teardown(parts)


func test_back_elsewhere_does_what_the_screen_underneath_does() -> void:
	var parts: Array = _app(_cover())
	var app: AppService = parts[0]
	app.goto(AppService.LEVEL_SELECT)
	app.apply_window(_cover_half().safe)
	app.go_back()
	assert_eq(app.current_screen(), AppService.MAIN_MENU, "Back closes the level select as usual")
	assert_true(app.too_small_layer() != null, "the layer still shows")
	_teardown(parts)


func test_a_dialog_stays_open_under_the_layer() -> void:
	var parts: Array = _play(_cover())
	var app: AppService = parts[0]
	app.goto(AppService.MAIN_MENU)
	app.goto(AppService.LEVEL_SELECT)
	var select: Control = app.current_screen_node()
	select.call(&"choose", Levels.HARD)
	var dialog: ConfirmDialog = select.get(&"confirm") as ConfirmDialog
	assert_true(dialog.is_open())
	app.apply_window(_cover_half().safe)
	app.apply_window(_cover().safe)
	assert_true(dialog.is_open(), "the dialog stays open with nothing chosen")
	assert_true(app.has_puzzle_in_progress(), "the puzzle is untouched")
	_teardown(parts)


func test_a_puzzle_made_while_too_small_opens_paused() -> void:
	var parts: Array = _app(_cover())
	var app: AppService = parts[0]
	var host: Control = parts[1]
	app.goto(AppService.LEVEL_SELECT)
	app.apply_window(_cover_half().safe)
	app.start_new_puzzle(Levels.BEGINNER)
	assert_eq(app.current_screen(), AppService.PLAY, "the puzzle opens")
	var screen: Control = app.current_screen_node()
	assert_true(bool(screen.call(&"is_paused")), "paused")
	assert_eq(app.session.elapsed_seconds(), 0, "at 0:00")
	assert_eq(app.stats.started(Levels.BEGINNER), 1, "Started counts it")
	assert_eq(host.get_child(host.get_child_count() - 1), app.too_small_layer(), "the layer stays on top of the new screen")
	_teardown(parts)


func test_the_layer_takes_every_tap_and_shows_the_message() -> void:
	var parts: Array = _app(_cover())
	var app: AppService = parts[0]
	app.apply_window(_cover_half().safe)
	var layer: TooSmallLayer = app.too_small_layer()
	assert_eq(layer.mouse_filter, Control.MOUSE_FILTER_STOP, "takes every tap")
	assert_eq(layer.message.text, "This window is too small. Make it bigger to play.")
	assert_eq(layer.message.theme_type_variation, ThemeFactory.BODY)
	assert_eq(layer.page.theme_type_variation, ThemeFactory.PAGE)
	_assert_nothing_tappable(layer)
	layer.size = COVER_HALF_SIZE
	_lay_out(layer)
	assert_true(layer.hero.visible, "the hero shows when the content box is 160 tall or more")
	assert_eq(layer.hero.custom_minimum_size, Vector2(64, 64))
	var short: Shape = _shape("690 x 150", 690.0, 150.0, 0.0, 0.0, Layout.Arrangement.TOO_SMALL)
	layer.size = short.size
	_lay_out(layer)
	assert_false(layer.hero.visible, "and hides below that")
	_teardown(parts)



func _assert_nothing_tappable(node: Node) -> void:
	for child: Node in node.get_children():
		if child is BaseButton:
			fail("%s is a button" % child.name)
		if child is Control and (child as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			fail("%s takes taps itself" % child.name)
		_assert_nothing_tappable(child)
