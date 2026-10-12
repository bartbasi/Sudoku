extends "res://tests/unit_test.gd"
## The play screen (GDD 3 to 12, ARCHITECTURE section 11): it opens in both
## skins, the timer runs only while the board shows, Back and the lifecycle
## open the pause menu, the Hint button buys hints and is disabled when it
## must be, the full board message, and completion.

const Fx := preload("res://tests/save/save_fixtures.gd")

var _dirs: Array[String] = []


func _setup(skin_id: StringName = &"pop_light", level: int = Levels.BEGINNER) -> Array:
	var dir: String = Fx.fresh_dir("play")
	_dirs.append(dir)
	var app: AppService = AppService.new()
	app.save_dir = dir
	app.use_thread = false
	app.load_all()
	app.settings.skin_id = skin_id
	app.settings.first_launch_answered = true
	var host: Control = Control.new()
	host.theme = ThemeFactory.build(app.current_skin())
	host.size = Vector2(360, 800)
	(Engine.get_main_loop() as SceneTree).root.add_child(host)
	app.attach_host(host)
	app.start_new_puzzle(level)
	return [app, host]


func _teardown(parts: Array) -> void:
	var host: Control = parts[1]
	host.get_parent().remove_child(host)
	host.free()
	(parts[0] as AppService).free()
	for dir: String in _dirs:
		Fx.wipe(dir)
	_dirs.clear()


func _screen(app: AppService) -> Control:
	return app.current_screen_node()


func _tap(screen: Control, kind: int, cell: int = -1, digit: int = 0) -> void:
	var area: PlayArea = screen.get(&"play_area")
	area.controller.handle(BoardAction.create(kind, cell, digit))


func test_opens_in_both_skins_with_a_new_puzzle() -> void:
	for skin_id: StringName in [&"pop_light", &"pop_dark"]:
		var parts: Array = _setup(skin_id)
		var app: AppService = parts[0]
		assert_eq(app.current_screen(), AppService.PLAY, "the board appears after generation")
		var screen: Control = _screen(app)
		var hud: PlayHud = screen.get(&"hud")
		assert_eq(hud.time_value.text, "0:00")
		assert_eq(hud.score_value.text, "100")
		assert_false(hud.hint_button.disabled, "Hint enabled")
		assert_eq(hud.hint_button.text, "HINT\n−20")
		var area: PlayArea = screen.get(&"play_area")
		assert_false(area.pad.is_undo_enabled(), "Undo disabled")
		assert_eq(UiKit.sticker_label(screen.get(&"level_sticker") as Control).text, "BEGINNER")
		_teardown(parts)


func test_timer_runs_only_while_the_board_shows() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	var screen: Control = _screen(app)
	screen.call(&"_process", 2.5)
	assert_eq(app.session.elapsed_seconds(), 2)
	assert_eq((screen.get(&"hud") as PlayHud).time_value.text, "0:02")
	screen.call(&"show_pause")
	screen.call(&"_process", 30.0)
	assert_eq(app.session.elapsed_seconds(), 2, "paused in the pause menu")
	screen.call(&"resume")
	screen.call(&"_process", 1.0)
	assert_eq(app.session.elapsed_seconds(), 3)
	app.goto(AppService.SETTINGS)
	screen.call(&"_process", 30.0)
	assert_eq(app.session.elapsed_seconds(), 3, "paused under another screen")
	app.go_back()
	assert_eq(app.current_screen(), AppService.PLAY)
	screen.call(&"_process", 1.0)
	assert_eq(app.session.elapsed_seconds(), 4)
	_teardown(parts)


func test_hint_panel_does_not_stop_the_timer() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	var screen: Control = _screen(app)
	screen.call(&"buy_hint")
	screen.call(&"_process", 5.0)
	assert_eq(app.session.elapsed_seconds(), 5)
	_teardown(parts)


func test_back_opens_the_pause_menu_and_back_again_resumes() -> void:
	# GDD AT-38.
	var parts: Array = _setup()
	var app: AppService = parts[0]
	var screen: Control = _screen(app)
	var pause: PauseMenu = screen.get(&"pause_menu")
	var area: PlayArea = screen.get(&"play_area")
	app.go_back()
	assert_true(pause.is_open(), "Back opens the pause menu")
	assert_false(area.visible, "the board is hidden")
	assert_eq(app.current_screen(), AppService.PLAY)
	app.go_back()
	assert_false(pause.is_open(), "Back resumes")
	assert_true(area.visible)
	_teardown(parts)


func test_lifecycle_saves_and_opens_the_pause_menu() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	var screen: Control = _screen(app)
	var cell: int = Fx.empty_cells(app.session)[0]
	app.session.select(cell)
	app.session.add_time(42.0)
	for what: int in [Node.NOTIFICATION_APPLICATION_PAUSED, Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_WM_CLOSE_REQUEST]:
		(screen.get(&"pause_menu") as PauseMenu).close()
		SaveStore.remove(app.path_of(AppService.PUZZLE_FILE))
		app.notification(what)
		assert_true((screen.get(&"pause_menu") as PauseMenu).is_open(), "pause menu after %d" % what)
		var saved: GameSession = app.load_session_file()
		assert_true(saved != null, "saved on %d" % what)
		if saved != null:
			assert_eq(saved.elapsed_seconds(), 42)
			assert_eq(saved.selected, cell)
	_teardown(parts)


func test_pause_menu_settings_and_menu() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	var screen: Control = _screen(app)
	var pause: PauseMenu = screen.get(&"pause_menu")
	screen.call(&"show_pause")
	pause.settings_button.pressed.emit()
	assert_eq(app.current_screen(), AppService.SETTINGS)
	app.go_back()
	assert_eq(app.current_screen(), AppService.PLAY)
	assert_true(pause.is_open(), "back from Settings keeps the pause menu")
	pause.menu_button.pressed.emit()
	assert_eq(app.current_screen(), AppService.MAIN_MENU)
	assert_true(app.has_puzzle_in_progress(), "the puzzle stays in progress")
	assert_true((_screen(app).get(&"continue_button") as Button).visible, "Continue shows")
	_teardown(parts)


func test_hint_button_buys_shows_and_disables() -> void:
	# GDD AT-42, AT-44 and AT-45.
	var parts: Array = _setup()
	var app: AppService = parts[0]
	var screen: Control = _screen(app)
	var hud: PlayHud = screen.get(&"hud")
	var panel: HintPanel = screen.get(&"hint_panel")
	var digits: PackedInt32Array = app.session.board.digits.duplicate()
	hud.hint_button.pressed.emit()
	assert_eq(app.session.score(), 80)
	assert_true(panel.visible, "the panel shows")
	assert_ne(panel.text_label.text, "")
	assert_true(hud.hint_button.disabled, "disabled while a hint shows")
	assert_eq(app.session.board.digits, digits, "the board does not change")
	assert_true(app.load_session_file().hint != null, "the hint is saved")
	hud.hint_button.pressed.emit()
	assert_eq(app.session.score(), 80, "a disabled Hint does nothing")
	panel.close_button.pressed.emit()
	assert_false(panel.visible)
	assert_false(hud.hint_button.disabled)
	for i: int in 4:
		hud.hint_button.pressed.emit()
		panel.close_button.pressed.emit()
	assert_eq(app.session.score(), 0)
	assert_true(hud.hint_button.disabled, "disabled at score 0")
	hud.hint_button.pressed.emit()
	assert_eq(app.session.hints_bought, 5, "no sixth hint")
	_teardown(parts)


func test_a_placement_closes_the_hint_panel() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	var screen: Control = _screen(app)
	var panel: HintPanel = screen.get(&"hint_panel")
	screen.call(&"buy_hint")
	var cell: int = Fx.empty_cells(app.session)[0]
	_tap(screen, BoardAction.Kind.CELL, cell)
	assert_true(panel.visible, "selecting keeps it")
	_tap(screen, BoardAction.Kind.PAD, -1, app.session.solution[cell])
	assert_false(panel.visible, "placing closes it")
	_teardown(parts)


func test_a_saved_hint_shows_again_on_resume() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	_screen(app).call(&"buy_hint")
	var dir: String = app.save_dir
	var host: Control = parts[1]
	var again: AppService = AppService.new()
	again.save_dir = dir
	again.use_thread = false
	again.load_all()
	again.settings.first_launch_answered = true
	var host2: Control = Control.new()
	host2.theme = host.theme
	host2.size = host.size
	host.get_parent().add_child(host2)
	again.attach_host(host2)
	again.goto(AppService.PLAY)
	var panel: HintPanel = _screen(again).get(&"hint_panel")
	assert_true(panel.visible, "the hint is on screen")
	assert_eq(again.session.score(), 80, "charged once")
	host2.get_parent().remove_child(host2)
	host2.free()
	again.free()
	_teardown(parts)


func test_full_board_message_shows_and_closes_on_the_next_action() -> void:
	# GDD AT-36.
	var parts: Array = _setup()
	var app: AppService = parts[0]
	var screen: Control = _screen(app)
	var session: GameSession = app.session
	var empties: PackedInt32Array = Fx.empty_cells(session)
	var last: int = empties[empties.size() - 1]
	for cell: int in empties:
		_tap(screen, BoardAction.Kind.CELL, cell)
		var digit: int = session.solution[cell]
		if cell == last:
			digit = digit % 9 + 1
		_tap(screen, BoardAction.Kind.PAD, -1, digit)
	var message: Control = screen.get(&"board_message")
	assert_true(message.visible, "the message shows")
	assert_false(session.is_completed)
	screen.call(&"_process", 3.0)
	assert_eq(session.elapsed_seconds(), 3, "the timer keeps running")
	_tap(screen, BoardAction.Kind.PAD, -1, session.solution[last])
	assert_false(message.visible, "the next action closes it")
	assert_true(session.is_completed, "the fix completes the puzzle")
	_teardown(parts)


func test_completion_records_and_opens_the_completion_screen() -> void:
	# GDD AT-51.
	var parts: Array = _setup()
	var app: AppService = parts[0]
	var screen: Control = _screen(app)
	var session: GameSession = app.session
	session.add_time(200.0)
	for cell: int in Fx.empty_cells(session):
		_tap(screen, BoardAction.Kind.CELL, cell)
		_tap(screen, BoardAction.Kind.PAD, -1, session.solution[cell])
	assert_true(session.is_completed)
	assert_false(app.has_puzzle_in_progress(), "no Continue")
	assert_false(FileAccess.file_exists(app.path_of(AppService.PUZZLE_FILE)), "save deleted")
	assert_eq(app.stats.completed_count(Levels.BEGINNER), 1)
	var hud: PlayHud = screen.get(&"hud")
	assert_true(hud.hint_button.disabled, "Hint disabled at completion")
	var area: PlayArea = screen.get(&"play_area")
	assert_true(area.pad.is_locked(), "the board locks")
	screen.call(&"_process", 10.0)
	assert_eq(session.elapsed_seconds(), 200, "the timer stopped")
	assert_true(bool(screen.call(&"handle_back")), "Back does nothing now")
	screen.call(&"finish_completion")
	assert_eq(app.current_screen(), AppService.COMPLETION)
	var result: CompletionResult = _screen(app).get(&"result")
	assert_eq(result.seconds, 200)
	assert_eq(result.level, Levels.BEGINNER)
	_teardown(parts)


func test_auto_cross_from_settings_reaches_the_puzzle() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	var screen: Control = _screen(app)
	screen.call(&"show_pause")
	(screen.get(&"pause_menu") as PauseMenu).settings_button.pressed.emit()
	var settings: Control = _screen(app)
	(settings.get(&"auto_cross_switch") as CheckButton).button_pressed = true
	assert_true(app.session.auto_cross)
	assert_true(app.load_session_file().auto_cross)
	_teardown(parts)


func test_play_screen_sets_only_theme_variations() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	var screen: Control = _screen(app)
	screen.call(&"buy_hint")
	screen.call(&"show_pause")
	_check(screen)
	_teardown(parts)


func _check(node: Node) -> void:
	var control: Control = node as Control
	if control != null:
		for prop: Dictionary in control.get_property_list():
			var prop_name: String = prop["name"]
			for prefix: String in ["theme_override_colors/", "theme_override_fonts/", "theme_override_font_sizes/", "theme_override_styles/"]:
				if prop_name.begins_with(prefix) and control.get(prop_name) != null:
					fail("%s sets %s" % [control.name, prop_name])
	for child: Node in node.get_children():
		_check(child)
