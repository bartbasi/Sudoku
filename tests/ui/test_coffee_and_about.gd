extends "res://tests/unit_test.gd"
## Buy me a coffee and About on more screens (GDD 15.7): the main menu, the
## pause menu, Settings and the completion screen each hand exactly one
## address, the support page, to the link opener and change nothing else;
## every one is ignored while a puzzle is being made. About opens from the
## main menu, the pause menu and Settings, and Back returns to the screen it
## came from. Over a paused puzzle the timer does not run while About or
## Settings shows, and only Resume starts it again. Built with an AppService
## that is not an autoload, with a recorder as its link opener, so no test
## opens a browser. The play screen's coffee cup pauses first, then opens the
## support page; it hides with Pause under the hint panel and the full board
## message. Where the buttons sit is checked by window_check.gd.

const Fx := preload("res://tests/save/save_fixtures.gd")
const URL: String = "https://buymeacoffee.com/playinc"

var _dirs: Array[String] = []
var _hosts: Array[Control] = []
## Every address handed to the link opener, in order.
var _links: PackedStringArray = PackedStringArray()


func _app() -> AppService:
	var dir: String = Fx.fresh_dir("coffee")
	_dirs.append(dir)
	var app: AppService = AppService.new()
	app.save_dir = dir
	app.use_thread = false
	app.link_opener = _record_link
	app.load_all()
	app.answer_first_launch()
	var host: Control = Control.new()
	host.theme = ThemeFactory.build(app.current_skin())
	host.size = Vector2(360, 800)
	(Engine.get_main_loop() as SceneTree).root.add_child(host)
	_hosts.append(host)
	app.attach_host(host)
	return app


func _record_link(url: String) -> void:
	_links.append(url)


func _free_all(apps: Array[AppService]) -> void:
	for host: Control in _hosts:
		if is_instance_valid(host):
			host.get_parent().remove_child(host)
			host.free()
	_hosts.clear()
	for app: AppService in apps:
		app.free()
	for dir: String in _dirs:
		Fx.wipe(dir)
	_dirs.clear()


## A puzzle in progress at 6:20 on the play screen, with the pause menu open.
func _paused(app: AppService) -> Control:
	app.start_new_puzzle(Levels.MEDIUM)
	app.session.add_time(380.0)
	var play: Control = app.current_screen_node()
	play.call(&"show_pause")
	return play


func _pause_menu(play: Control) -> PauseMenu:
	return play.get(&"pause_menu") as PauseMenu


## Runs the play screen's frame step: the timer moves only if it may.
func _tick(play: Control, seconds: float) -> void:
	play.call(&"_process", seconds)


## Starts a puzzle on a worker thread and leaves it being made.
func _start_making(app: AppService) -> void:
	app.use_thread = true
	app.start_new_puzzle(Levels.EASY)
	assert_true(app.is_generating(), "a puzzle is being made")


## Lets the puzzle being made finish, so no thread outlives the test.
func _finish_making(app: AppService) -> void:
	var waited: int = 0
	while app.get(&"_thread") != null and waited < 20000:
		OS.delay_msec(5)
		waited += 5
		app.call(&"_process", 0.0)
	var overlay: Control = app.get(&"_overlay") as Control
	if overlay != null:
		overlay.call(&"step", Motion.MAKING_DELAY)
		overlay.call(&"step", Motion.MAKING_MIN)
	app.call(&"_process", 0.0)


# Buy me a coffee ---------------------------------------------------------------------

func test_main_menu_coffee_opens_the_support_page_once() -> void:
	var app: AppService = _app()
	app.goto(AppService.MAIN_MENU)
	var menu: Control = app.current_screen_node()
	(menu.get(&"coffee_button") as Button).pressed.emit()
	assert_eq(_links, PackedStringArray([URL]), "exactly one address, exactly this one")
	assert_eq(app.current_screen_node(), menu, "the main menu stays")
	assert_false(app.has_puzzle_in_progress(), "no puzzle starts")
	_free_all([app])


func test_pause_menu_coffee_opens_once_and_the_puzzle_stays_paused() -> void:
	var app: AppService = _app()
	var play: Control = _paused(app)
	var pause: PauseMenu = _pause_menu(play)
	pause.coffee_button.pressed.emit()
	assert_eq(_links, PackedStringArray([URL]), "exactly one address, exactly this one")
	assert_eq(app.current_screen(), AppService.PLAY, "the play screen stays")
	assert_true(pause.is_open(), "the pause menu stays open")
	_tick(play, 30.0)
	assert_eq(app.session.elapsed_seconds(), 380, "the timer has not moved")
	_free_all([app])


func test_settings_coffee_opens_the_support_page_once() -> void:
	var app: AppService = _app()
	app.goto(AppService.MAIN_MENU)
	app.goto(AppService.SETTINGS)
	var settings: Control = app.current_screen_node()
	var before: Dictionary = app.settings.to_dict()
	(settings.get(&"coffee_button") as Button).pressed.emit()
	assert_eq(_links, PackedStringArray([URL]), "exactly one address, exactly this one")
	assert_eq(app.current_screen(), AppService.SETTINGS)
	assert_eq(app.settings.to_dict(), before, "no setting changes")
	_free_all([app])


func test_completion_coffee_opens_once_and_the_screen_stays() -> void:
	var app: AppService = _app()
	var result: CompletionResult = CompletionResult.new()
	result.level = Levels.EASY
	result.seconds = 540
	result.final_score = 210
	app.goto(AppService.COMPLETION, result)
	var screen: Control = app.current_screen_node()
	(screen.get(&"coffee_button") as Button).pressed.emit()
	assert_eq(_links, PackedStringArray([URL]), "exactly one address, exactly this one")
	assert_eq(app.current_screen_node(), screen, "the same completion screen")
	assert_false(app.has_puzzle_in_progress(), "no puzzle starts")
	_free_all([app])


func test_every_coffee_button_is_ignored_while_a_puzzle_is_being_made() -> void:
	for screen_id: StringName in [AppService.MAIN_MENU, AppService.SETTINGS, AppService.COMPLETION]:
		var app: AppService = _app()
		var result: CompletionResult = CompletionResult.new()
		result.level = Levels.EASY
		app.goto(screen_id, result if screen_id == AppService.COMPLETION else null)
		var screen: Control = app.current_screen_node()
		_start_making(app)
		(screen.get(&"coffee_button") as Button).pressed.emit()
		assert_eq(_links.size(), 0, "%s: the opener is never called while a puzzle is made" % screen_id)
		_finish_making(app)
		assert_eq(_links.size(), 0)
		_free_all([app])


func test_pause_menu_coffee_and_about_are_ignored_while_a_puzzle_is_being_made() -> void:
	var app: AppService = _app()
	var play: Control = _paused(app)
	var pause: PauseMenu = _pause_menu(play)
	_start_making(app)
	pause.coffee_button.pressed.emit()
	pause.about_button.pressed.emit()
	assert_eq(_links.size(), 0, "no browser")
	assert_eq(app.current_screen(), AppService.PLAY, "About does not open")
	_finish_making(app)
	_free_all([app])


# About ---------------------------------------------------------------------------------

func test_about_opens_from_the_main_menu_and_back_returns() -> void:
	var app: AppService = _app()
	app.goto(AppService.MAIN_MENU)
	var menu: Control = app.current_screen_node()
	(menu.get(&"about_button") as Button).pressed.emit()
	assert_eq(app.current_screen(), AppService.ABOUT)
	app.go_back()
	assert_eq(app.current_screen(), AppService.MAIN_MENU, "Back returns to the main menu")
	assert_eq(app.current_screen_node(), menu, "the same main menu, as left")
	assert_true(menu.visible)
	_free_all([app])


func test_about_from_the_pause_menu_keeps_the_puzzle_paused() -> void:
	var app: AppService = _app()
	var play: Control = _paused(app)
	var pause: PauseMenu = _pause_menu(play)
	pause.about_button.pressed.emit()
	assert_eq(app.current_screen(), AppService.ABOUT)
	_tick(play, 60.0)
	assert_eq(app.session.elapsed_seconds(), 380, "the timer does not run while About shows")
	app.go_back()
	assert_eq(app.current_screen(), AppService.PLAY, "Back returns to the play screen")
	assert_eq(app.current_screen_node(), play)
	assert_true(pause.is_open(), "the pause menu shows again")
	_tick(play, 60.0)
	assert_eq(app.session.elapsed_seconds(), 380, "still paused after Back")
	pause.resume_button.pressed.emit()
	_tick(play, 2.0)
	assert_eq(app.session.elapsed_seconds(), 382, "Resume starts the timer from 6:20")
	_free_all([app])


func test_about_from_settings_from_the_pause_menu_keeps_the_puzzle_paused() -> void:
	var app: AppService = _app()
	var play: Control = _paused(app)
	var pause: PauseMenu = _pause_menu(play)
	pause.settings_button.pressed.emit()
	assert_eq(app.current_screen(), AppService.SETTINGS)
	var settings: Control = app.current_screen_node()
	(settings.get(&"about_button") as Button).pressed.emit()
	assert_eq(app.current_screen(), AppService.ABOUT)
	_tick(play, 60.0)
	assert_eq(app.session.elapsed_seconds(), 380, "the timer does not run while About shows")
	app.go_back()
	assert_eq(app.current_screen_node(), settings, "Back returns to Settings")
	_tick(play, 60.0)
	assert_eq(app.session.elapsed_seconds(), 380)
	app.go_back()
	assert_eq(app.current_screen(), AppService.PLAY, "Back again returns to the pause menu")
	assert_true(pause.is_open())
	_tick(play, 60.0)
	assert_eq(app.session.elapsed_seconds(), 380, "still paused")
	_free_all([app])


func test_about_from_settings_from_the_main_menu_and_back_twice() -> void:
	# GDD 15.7: title, MENU, Settings, About; Back, Back, Back.
	var app: AppService = _app()
	(app.current_screen_node().get(&"menu_button") as Button).pressed.emit()
	assert_eq(app.current_screen(), AppService.MAIN_MENU)
	(app.current_screen_node().get(&"settings_button") as Button).pressed.emit()
	(app.current_screen_node().get(&"about_button") as Button).pressed.emit()
	assert_eq(app.current_screen(), AppService.ABOUT)
	app.go_back()
	assert_eq(app.current_screen(), AppService.SETTINGS)
	app.go_back()
	assert_eq(app.current_screen(), AppService.MAIN_MENU)
	app.go_back()
	assert_eq(app.current_screen(), AppService.TITLE)
	_free_all([app])


func test_about_on_the_main_menu_and_settings_is_ignored_while_a_puzzle_is_being_made() -> void:
	var app: AppService = _app()
	app.goto(AppService.MAIN_MENU)
	var menu: Control = app.current_screen_node()
	app.goto(AppService.SETTINGS)
	var settings: Control = app.current_screen_node()
	_start_making(app)
	(menu.get(&"about_button") as Button).pressed.emit()
	(settings.get(&"about_button") as Button).pressed.emit()
	assert_eq(app.current_screen(), AppService.SETTINGS, "About does not open")
	_finish_making(app)
	_free_all([app])


func test_the_order_on_each_screen_ends_with_about_then_coffee() -> void:
	# GDD 15.7: About right after each screen's own buttons, the coffee last.
	var app: AppService = _app()
	var play: Control = _paused(app)
	var pause: PauseMenu = _pause_menu(play)
	var pause_buttons: Node = pause.about_button.get_parent()
	assert_eq(pause.about_button.get_index(), pause_buttons.get_child_count() - 1, "About last of the pause buttons")
	assert_eq(pause.menu_button.get_index(), pause.about_button.get_index() - 1, "right after Menu")
	app.goto(AppService.SETTINGS)
	var settings: Control = app.current_screen_node()
	var about: Button = settings.get(&"about_button") as Button
	var rows: Node = about.get_parent()
	assert_eq((settings.get(&"reset_button") as Button).get_index(), about.get_index() - 1, "About right after Reset stats")
	assert_eq((settings.get(&"coffee_touch") as Control).get_index(), rows.get_child_count() - 1, "Buy me a coffee last")
	app.goto(AppService.MAIN_MENU)
	var menu: Control = app.current_screen_node()
	var reading: Array[Button] = []
	for row: Node in (menu.get(&"new_button") as Button).get_parent().get_children():
		if row is Button:
			reading.append(row as Button)
		for child: Node in row.get_children():
			if child is Button:
				reading.append(child as Button)
	var names: PackedStringArray = PackedStringArray()
	for button: Button in reading:
		names.append(button.name)
	assert_eq(names, PackedStringArray(["Continue", "NewPuzzle", "Lessons", "Stats", "Settings", "About"]), "the main menu in GDD 15.7 reading order")
	assert_eq((menu.get(&"coffee_touch") as Control).get_index(), (menu.get(&"coffee_touch") as Control).get_parent().get_child_count() - 1, "Buy me a coffee last")
	_free_all([app])


# The coffee cup on the play screen -------------------------------------------------------

func test_the_coffee_cup_pauses_first_then_opens_once() -> void:
	# GDD 15.7: Pause first (timer stopped, pause menu, saved), then the browser.
	var app: AppService = _app()
	app.start_new_puzzle(Levels.MEDIUM)
	app.session.add_time(380.0)
	var play: Control = app.current_screen_node()
	var pause: PauseMenu = _pause_menu(play)
	var paused_at_open: Array[bool] = []
	app.link_opener = func(url: String) -> void:
		paused_at_open.append(pause.is_open())
		_record_link(url)
	var before: Dictionary = app.session.to_dict()
	(play.get(&"coffee_button") as Button).pressed.emit()
	assert_eq(_links, PackedStringArray([URL]), "exactly one address, exactly this one")
	assert_eq(paused_at_open, [true] as Array[bool], "the pause menu was open before the browser")
	assert_true(pause.is_open(), "coming back shows the pause menu")
	assert_false((play.get(&"play_area") as Control).visible, "the board hides")
	assert_false(bool(play.call(&"is_timer_running")), "the timer is stopped")
	_tick(play, 120.0)
	assert_eq(app.session.elapsed_seconds(), 380, "time away never counts")
	assert_eq(app.session.to_dict(), before, "the puzzle is unchanged")
	assert_eq(app.load_session_file().elapsed_seconds(), 380, "the puzzle is saved")
	pause.resume_button.pressed.emit()
	_tick(play, 2.0)
	assert_eq(app.session.elapsed_seconds(), 382, "Resume runs on from 6:20")
	_free_all([app])


func test_the_coffee_cup_hides_with_the_hint_panel_and_the_board_message() -> void:
	var app: AppService = _app()
	app.start_new_puzzle(Levels.MEDIUM)
	var play: Control = app.current_screen_node()
	var cup: Control = play.get(&"coffee_touch") as Control
	assert_true(cup.visible, "the cup shows with nothing over Pause")
	play.call(&"buy_hint")
	assert_false(cup.visible, "the hint panel covers it")
	app.session.close_hint()
	assert_true(cup.visible, "back once the hint closes")
	UiKit.panel_in(play.get(&"board_message") as Control)
	assert_false(cup.visible, "the full board message covers it")
	_free_all([app])


func test_the_coffee_cup_stays_with_show_candidates_off() -> void:
	var app: AppService = _app()
	app.start_new_puzzle(Levels.EASY)
	app.set_show_candidates(false)
	var play: Control = app.current_screen_node()
	assert_true((play.get(&"coffee_touch") as Control).visible)
	(play.get(&"coffee_button") as Button).pressed.emit()
	assert_eq(_links.size(), 1)
	_free_all([app])


func test_the_coffee_cup_is_ignored_while_a_puzzle_is_being_made() -> void:
	var app: AppService = _app()
	app.start_new_puzzle(Levels.MEDIUM)
	var play: Control = app.current_screen_node()
	_start_making(app)
	(play.get(&"coffee_button") as Button).pressed.emit()
	assert_eq(_links.size(), 0, "no browser")
	assert_false(_pause_menu(play).is_open(), "nothing pauses")
	_finish_making(app)
	_free_all([app])
