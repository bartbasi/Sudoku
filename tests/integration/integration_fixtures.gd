extends RefCounted
## Shared harness for the integration tests. Not a test file (no test_ prefix).
##
## Each test builds a real AppService (the script of the App autoload) with a
## save folder of its own under user://test_scratch, wired to the real Skins
## and Audio autoloads, and a 360 by 800 dp host the real screens go into.
## The real App autoload is never touched, so the player's own save files
## stay as they are.
##
## The headless runner works before the first frame: the root is not inside
## the tree, so Godot sends no RESIZED and runs no timers or tweens. fit()
## sends the resize Godot would send, the way tests/board and tests/lessons
## do. Taps go through each control's real input path: a left mouse press
## event into BoardView._gui_input or NumberPad._gui_input at the centre of
## the cell or key, and a Button's pressed signal only when the button is
## visible and enabled, as a real tap would need.

const Fx := preload("res://tests/save/save_fixtures.gd")
const Bx := preload("res://tests/board/board_fixtures.gd")

const WIDTH: float = 360.0
const HEIGHT: float = 800.0


class Harness extends RefCounted:
	var app: AppService = null
	var host: Control = null
	var dir: String = ""
	var skins: Node = null
	var audio: Node = null
	## The screen attach_host opened: the title screen (GDD 15.0).
	var opened_on: StringName = &""

	## The screen on top.
	func top() -> Control:
		return app.current_screen_node()

	func screen_name() -> StringName:
		return app.current_screen()


static func root() -> Window:
	return (Engine.get_main_loop() as SceneTree).root


## A new save folder. Write files into it before open_app() to start from a
## saved state.
static func new_dir(tag: String) -> String:
	return Fx.fresh_dir("integration_%s" % tag)


## Builds the app on dir and leaves it on the main menu, where most flows
## start. The app opens on the title screen (opened_on); from there the main
## menu is the pause menu's Menu away, so this goes to it directly.
static func open_app(dir: String) -> Harness:
	var h: Harness = open_app_on_title(dir)
	if h.screen_name() == AppService.TITLE:
		h.app.goto(AppService.MAIN_MENU)
		fit(h)
	return h


## Builds the app on dir, as the game does at startup: load every save file,
## apply sound and skin, then attach the host, which opens the first screen.
static func open_app_on_title(dir: String) -> Harness:
	var h: Harness = Harness.new()
	h.dir = dir
	h.skins = root().get_node(^"Skins")
	h.audio = root().get_node(^"Audio")
	var app: AppService = AppService.new()
	app.name = "IntegrationApp"
	app.save_dir = dir
	app.use_thread = false
	app.skins = h.skins
	app.audio = h.audio
	app.load_all()
	# What App._ready does after load_all; _ready does not run outside the tree.
	app.call(&"_apply_audio")
	app.call(&"_apply_skin")
	h.app = app
	var host: Control = Control.new()
	host.name = "IntegrationHost"
	host.theme = ThemeFactory.build(app.current_skin())
	host.size = Vector2(WIDTH, HEIGHT)
	root().add_child(host)
	h.host = host
	app.attach_host(host)
	h.opened_on = app.current_screen()
	fit(h)
	return h


## Frees the app and host without deleting the save folder (a quit).
static func quit(h: Harness) -> void:
	if h.host != null and is_instance_valid(h.host):
		if h.host.get_parent() != null:
			h.host.get_parent().remove_child(h.host)
		h.host.free()
	h.host = null
	if h.app != null and is_instance_valid(h.app):
		h.app.free()
	h.app = null


## Quits, deletes the save folder and puts the shared autoloads back.
static func close(h: Harness) -> void:
	quit(h)
	Fx.wipe(h.dir)
	h.skins.call(&"apply", &"pop_light")
	h.audio.set(&"enabled", true)


## Sends the resize Godot would send when the screen on top appears: the
## screen takes the host's size, then its board and pad lay out.
static func fit(h: Harness) -> void:
	var screen: Control = h.top()
	if screen == null:
		return
	# Screens are anchored to the full rect, which outside the tree resolves
	# against a zero parent rect, so the offsets carry the size.
	_fill(screen, h.host.size)
	screen.notification(Control.NOTIFICATION_RESIZED)
	screen.resized.emit()
	for child: Node in screen.find_children("*", "ScreenColumn", true, false):
		_fill(child as Control, h.host.size)
		child.notification(Container.NOTIFICATION_SORT_CHILDREN)
	var area: PlayArea = play_area_of(screen)
	if area != null:
		area.notification(Control.NOTIFICATION_RESIZED)
		area.pad.notification(Control.NOTIFICATION_RESIZED)
		area.view.notification(Control.NOTIFICATION_RESIZED)


static func _fill(control: Control, area: Vector2) -> void:
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = area.x
	control.offset_bottom = area.y


static func play_area_of(screen: Control) -> PlayArea:
	if screen == null:
		return null
	if screen is LessonPlayer:
		return (screen as LessonPlayer).area
	if "play_area" in screen:
		return screen.get(&"play_area") as PlayArea
	return null


## Whether a control and all its parents are visible (outside the tree,
## is_visible_in_tree() is always false).
static func showing(control: Control) -> bool:
	var at: Node = control
	while at != null:
		var item: CanvasItem = at as CanvasItem
		if item != null and not item.visible:
			return false
		at = at.get_parent()
	return true


## Taps a button as a player would: only a visible, enabled button reacts.
## Returns whether the tap reached it.
static func click(button: BaseButton) -> bool:
	if button == null or button.disabled or not showing(button):
		return false
	if button.toggle_mode:
		button.button_pressed = not button.button_pressed
	button.pressed.emit()
	return true


## Turns a switch (CheckButton) to on or off, as a tap on it would.
static func set_switch(button: CheckButton, on: bool) -> bool:
	if button == null or button.disabled or not showing(button):
		return false
	if button.button_pressed != on:
		button.button_pressed = on
	return true


## A tap on a cell of the board: a left press at the cell's centre.
static func tap_cell(area: PlayArea, cell: int) -> void:
	var view: BoardView = area.view
	var rect: Rect2 = BoardPainter.cell_rect(view.board_square(), cell, view.current_skin())
	view._gui_input(Bx.press(rect.get_center()))


## A tap on a pad control: "pad:1" to "pad:9", "place", "cross_out",
## "erase" or "undo", at the centre of its face.
static func tap_key(area: PlayArea, control: StringName) -> void:
	var pad: NumberPad = area.pad
	var face: Rect2 = pad.get_global_transform().affine_inverse() * pad.control_rect_global(control)
	pad._gui_input(Bx.press(face.get_center()))


static func tap_digit(area: PlayArea, digit: int) -> void:
	tap_key(area, StringName("pad:%d" % digit))


## Taps the mode button for mode (it does nothing if that mode is on).
static func tap_mode(area: PlayArea, mode: int) -> void:
	tap_key(area, NumberPad.CROSS_OUT if mode == GameSession.Mode.CROSS_OUT else NumberPad.PLACE)


## Selects a cell and places a digit in Place mode.
static func place(area: PlayArea, cell: int, digit: int) -> void:
	tap_mode(area, GameSession.Mode.PLACE)
	tap_cell(area, cell)
	tap_digit(area, digit)


## The clicks Audio was asked to play while sound was on.
static func clicks(h: Harness) -> int:
	return int(h.audio.get(&"_click_requests"))


static func empty_cells(session: GameSession) -> PackedInt32Array:
	return Fx.empty_cells(session)


## Writes a puzzle in progress into dir, as an earlier run of the game would
## have left it.
static func write_session(dir: String, session: GameSession) -> void:
	SaveStore.write(dir.path_join(AppService.PUZZLE_FILE), session.to_dict())


## Writes settings with the first launch offer already answered.
static func write_settings(dir: String, auto_cross: bool = false) -> void:
	var settings: Settings = Settings.new()
	settings.first_launch_answered = true
	settings.auto_cross = auto_cross
	SaveStore.write(dir.path_join(AppService.SETTINGS_FILE), settings.to_dict())


## Position B (GDD 4.4) as a Beginner puzzle in progress, nothing selected.
static func position_b_session() -> GameSession:
	return GameSession.create("1.0.1", Levels.BEGINNER, Bx.position_b(), Bx.grid(Bx.SOLUTION_B), false)


## Main menu, New puzzle, then the level's row.
static func start_from_menu(h: Harness, level: int) -> bool:
	if h.screen_name() != AppService.MAIN_MENU:
		return false
	if not click(h.top().get(&"new_button") as Button):
		return false
	fit(h)
	var rows: Array = h.top().get(&"level_buttons")
	var ok: bool = click(rows[level] as Button)
	fit(h)
	return ok


## The marks of one cell, digits 1 to 9.
static func ring(session: GameSession, cell: int) -> Array[int]:
	var out: Array[int] = []
	for d: int in range(1, 10):
		out.append(session.board.mark(cell, d))
	return out
