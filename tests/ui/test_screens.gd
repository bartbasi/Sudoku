extends "res://tests/unit_test.gd"
## The screens in scenes/ui instantiate in both skins without errors, show
## what the GDD says, and navigate through App: Back closes dialogs first,
## then the screen. Built with an AppService that is not an autoload.

const Fx := preload("res://tests/save/save_fixtures.gd")
const SKIN_IDS: Array[StringName] = [&"pop_light", &"pop_dark"]
const SCREENS: Array[StringName] = [
	AppService.MAIN_MENU, AppService.FIRST_LAUNCH, AppService.LEVEL_SELECT,
	AppService.COMPLETION, AppService.STATS, AppService.SETTINGS,
	AppService.TITLE, AppService.INFO, AppService.ABOUT,
]

var _dirs: Array[String] = []


## A themed host at 360 by 800 dp under the root, and an app drawing into it.
func _setup(skin_id: StringName = &"pop_light") -> Array:
	var dir: String = Fx.fresh_dir("screens")
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
	# These tests start where the pause menu's Menu leads: the main menu.
	app.goto(AppService.MAIN_MENU)
	return [app, host]


func _teardown(parts: Array) -> void:
	var app: AppService = parts[0]
	var host: Control = parts[1]
	host.get_parent().remove_child(host)
	host.free()
	app.free()
	for dir: String in _dirs:
		Fx.wipe(dir)
	_dirs.clear()


func _top(app: AppService) -> Control:
	return app.current_screen_node()


func _find(node: Node, node_name: String) -> Node:
	return node.find_child(node_name, true, false)


func test_every_screen_opens_in_both_skins() -> void:
	for skin_id: StringName in SKIN_IDS:
		var parts: Array = _setup(skin_id)
		var app: AppService = parts[0]
		for screen: StringName in SCREENS:
			var payload: Variant = CompletionResult.new() if screen == AppService.COMPLETION else null
			app.goto(screen, payload)
			assert_eq(app.current_screen(), screen, "%s in %s" % [screen, skin_id])
			var top: Control = _top(app)
			assert_true(top is UiScreen, "%s is a screen" % screen)
			assert_true(top.get_child_count() >= 2, "%s has its page and column" % screen)
		_teardown(parts)


func test_screens_set_only_theme_variations() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	for screen: StringName in SCREENS:
		var payload: Variant = CompletionResult.new() if screen == AppService.COMPLETION else null
		app.goto(screen, payload)
		_check_no_look_overrides(_top(app), String(screen))
	_teardown(parts)


## No color, font or font size override anywhere in the screen.
func _check_no_look_overrides(node: Node, where: String) -> void:
	var control: Control = node as Control
	if control != null:
		for prop: Dictionary in control.get_property_list():
			var prop_name: String = prop["name"]
			if prop_name.begins_with("theme_override_colors/") or prop_name.begins_with("theme_override_fonts/") or prop_name.begins_with("theme_override_font_sizes/") or prop_name.begins_with("theme_override_styles/"):
				if control.get(prop_name) != null:
					fail("%s: %s sets %s" % [where, control.name, prop_name])
	for child: Node in node.get_children():
		_check_no_look_overrides(child, where)


func test_main_menu_shows_continue_only_with_a_puzzle() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	var menu: Control = _top(app)
	assert_eq(app.current_screen(), AppService.MAIN_MENU)
	var continue_button: Button = menu.get(&"continue_button")
	var new_button: Button = menu.get(&"new_button")
	assert_false(continue_button.visible, "no Continue without a puzzle")
	assert_eq(new_button.theme_type_variation, ThemeFactory.BUTTON_PRIMARY)
	app.session = Fx.played_session()
	menu.call(&"refresh")
	assert_true(continue_button.visible)
	assert_eq(new_button.theme_type_variation, ThemeFactory.BUTTON_SECONDARY)
	assert_eq(continue_button.text, "", "Continue has no text of its own (7.1)")
	assert_eq((continue_button.get_node(^"Lines/Label") as Label).text, "CONTINUE")
	assert_eq((continue_button.get_node(^"Lines/Caption") as Label).theme_type_variation, ThemeFactory.PRIMARY_CAPTION)
	assert_eq((menu.get(&"continue_caption") as Label).text, "BEGINNER, 1:23")
	_teardown(parts)


func test_first_launch_skip_answers_and_plays() -> void:
	# GDD 15.3, AT-73: the offer goes over the title screen on PLAY.
	var parts: Array = _setup()
	var app: AppService = parts[0]
	var host: Control = parts[1]
	app.settings.first_launch_answered = false
	app.attach_host(host)
	assert_eq(app.current_screen(), AppService.TITLE)
	app.play_now()
	assert_eq(app.current_screen(), AppService.FIRST_LAUNCH)
	var offer: Control = _top(app)
	(offer.get(&"skip_button") as Button).pressed.emit()
	assert_true(app.settings.first_launch_answered)
	assert_eq(app.current_screen(), AppService.PLAY, "Skip goes straight into a puzzle")
	assert_eq(app.session.level, Levels.EASY)
	assert_eq(app.session.score(), 200)
	assert_eq(app.stats.started(Levels.EASY), 1)
	var again: AppService = AppService.new()
	again.save_dir = app.save_dir
	again.load_all()
	assert_true(again.settings.first_launch_answered, "the answer is saved")
	again.free()
	_teardown(parts)


func test_back_pops_screens_and_settings_returns_to_where_it_came_from() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	app.goto(AppService.STATS)
	assert_eq(app.current_screen(), AppService.STATS)
	app.go_back()
	assert_eq(app.current_screen(), AppService.MAIN_MENU)
	assert_true(_top(app).visible, "the menu shows again")
	app.goto(AppService.SETTINGS)
	(_find(_top(app), "Back") as Control).get(&"button").pressed.emit()
	assert_eq(app.current_screen(), AppService.MAIN_MENU, "the back button goes back")
	_teardown(parts)


func test_level_select_starts_at_once_without_a_puzzle() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	app.goto(AppService.LEVEL_SELECT)
	var select: Control = _top(app)
	var buttons: Array[Button] = select.get(&"level_buttons")
	assert_eq(buttons.size(), 5, "five levels, all open")
	for button: Button in buttons:
		assert_false(button.disabled)
	buttons[Levels.EASY].pressed.emit()
	assert_true(app.has_puzzle_in_progress())
	assert_eq(app.session.level, Levels.EASY)
	_teardown(parts)


func test_level_select_confirms_before_abandoning() -> void:
	# GDD AT-61.
	var parts: Array = _setup()
	var app: AppService = parts[0]
	app.start_new_puzzle(Levels.MEDIUM)
	var old: GameSession = app.session
	app.goto(AppService.LEVEL_SELECT)
	var select: Control = _top(app)
	var confirm: ConfirmDialog = select.get(&"confirm")
	var buttons: Array[Button] = select.get(&"level_buttons")
	buttons[Levels.HARD].pressed.emit()
	assert_true(confirm.is_open(), "the dialog asks")
	assert_eq(confirm.body.text, "You have a Medium puzzle in progress. Start a new Hard puzzle? The current one will count as started, not completed.")
	assert_eq(app.session, old, "nothing changed yet")
	app.go_back()
	assert_false(confirm.is_open(), "Back means Keep playing")
	assert_eq(app.session, old)
	assert_eq(app.current_screen(), AppService.PLAY, "Keep playing returns to the puzzle")
	app.goto(AppService.LEVEL_SELECT)
	select = _top(app)
	confirm = select.get(&"confirm")
	buttons = select.get(&"level_buttons")
	buttons[Levels.HARD].pressed.emit()
	confirm.cancel_button.pressed.emit()
	assert_eq(app.session, old, "Keep playing changes nothing")
	assert_eq(app.current_screen(), AppService.PLAY)
	app.goto(AppService.LEVEL_SELECT)
	select = _top(app)
	confirm = select.get(&"confirm")
	buttons = select.get(&"level_buttons")
	buttons[Levels.BEGINNER].pressed.emit()
	confirm.confirm_button.pressed.emit()
	assert_ne(app.session, old, "Start new replaced it")
	assert_eq(app.session.level, Levels.BEGINNER)
	assert_eq(app.stats.started(Levels.MEDIUM), 1)
	assert_eq(app.stats.started(Levels.BEGINNER), 1)
	_teardown(parts)


func test_settings_switches_skins_and_reset_confirm() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	app.goto(AppService.SETTINGS)
	var screen: Control = _top(app)
	var sound: CheckButton = screen.get(&"sound_switch")
	var auto: CheckButton = screen.get(&"auto_cross_switch")
	assert_true(sound.button_pressed, "sound on by default")
	assert_false(auto.button_pressed, "Auto Cross off by default")
	sound.button_pressed = false
	assert_false(app.settings.sound)
	auto.button_pressed = true
	assert_true(app.settings.auto_cross)
	var skins: Dictionary = screen.get(&"skin_buttons")
	assert_eq(skins.size(), 2, "exactly two skins")
	assert_true((skins[&"pop_light"] as Button).button_pressed, "Pop light selected")
	(skins[&"pop_dark"] as Button).pressed.emit()
	assert_eq(app.settings.skin_id, &"pop_dark")
	assert_true((skins[&"pop_dark"] as Button).button_pressed)
	assert_false((skins[&"pop_light"] as Button).button_pressed)

	app.stats.record_start(Levels.EASY)
	var confirm: ConfirmDialog = screen.get(&"confirm")
	(screen.get(&"reset_button") as Button).pressed.emit()
	assert_true(confirm.is_open())
	assert_eq(confirm.body.text, "Reset all stats? This cannot be undone.")
	confirm.cancel_button.pressed.emit()
	assert_eq(app.stats.started(Levels.EASY), 1, "Cancel changes nothing")
	(screen.get(&"reset_button") as Button).pressed.emit()
	confirm.confirm_button.pressed.emit()
	assert_eq(app.stats.started(Levels.EASY), 0, "Reset clears")
	_teardown(parts)


func test_stats_show_dashes_then_values() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	app.goto(AppService.STATS)
	var screen: Control = _top(app)
	var values: Array[Dictionary] = screen.get(&"values")
	assert_eq((values[Levels.EASY]["best_time"] as Label).text, "-")
	assert_eq((values[Levels.EASY]["best_score"] as Label).text, "-")
	assert_eq((values[Levels.EASY]["started"] as Label).text, "0")
	app.stats.record_start(Levels.EASY)
	app.stats.record_start(Levels.EASY)
	app.stats.record_completion(Levels.EASY, 300, 276)
	app.stats.record_completion(Levels.EASY, 401, 208)
	app.record_lesson_finished("lesson_01")
	screen.call(&"refresh")
	assert_eq((values[Levels.EASY]["started"] as Label).text, "2")
	assert_eq((values[Levels.EASY]["completed"] as Label).text, "2")
	assert_eq((values[Levels.EASY]["best_time"] as Label).text, "5:00")
	assert_eq((values[Levels.EASY]["average_time"] as Label).text, "5:51")
	assert_eq((values[Levels.EASY]["best_score"] as Label).text, "276")
	assert_eq((screen.get(&"lessons_value") as Label).text, "1 of 5")
	_teardown(parts)


func test_completion_shows_the_result_and_new_best_labels() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	var result: CompletionResult = CompletionResult.new()
	result.level = Levels.HARD
	result.seconds = 1350
	result.points_after_hints = 420
	result.time_bonus = 175
	result.final_score = 595
	result.hints_used = 2
	result.new_best = Stats.NEW_BEST_SCORE
	app.goto(AppService.COMPLETION, result)
	var screen: Control = _top(app)
	assert_eq((screen.get(&"time_value") as Label).text, "22:30")
	assert_eq((screen.get(&"points_value") as Label).text, "420")
	assert_eq((screen.get(&"bonus_value") as Label).text, "175")
	assert_eq((screen.get(&"hints_value") as Label).text, "2")
	assert_false((screen.get(&"new_best_time") as Control).visible)
	assert_true((screen.get(&"new_best_score") as Control).visible)
	(screen.get(&"play_again_button") as Button).pressed.emit()
	assert_true(app.has_puzzle_in_progress(), "Play again starts a new puzzle with no dialog")
	assert_eq(app.session.level, Levels.HARD)
	_teardown(parts)


func test_completion_back_goes_to_the_menu() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	app.goto(AppService.COMPLETION, CompletionResult.new())
	app.go_back()
	assert_eq(app.current_screen(), AppService.MAIN_MENU)
	_teardown(parts)


func test_time_format() -> void:
	assert_eq(UiKit.format_time(0), "0:00")
	assert_eq(UiKit.format_time(59), "0:59")
	assert_eq(UiKit.format_time(768), "12:48")
	assert_eq(UiKit.format_time(3725), "1:02:05")
	assert_eq(UiKit.format_time(-4), "0:00")
	assert_eq(UiKit.stat_time(-1), "-")
	assert_eq(UiKit.stat_number(-1), "-")
	assert_eq(UiKit.stat_number(0), "0")


func test_lessons_open_through_app_and_record_progress() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	app.goto(AppService.LESSONS)
	assert_eq(app.current_screen(), AppService.LESSONS)
	app.go_back()
	assert_eq(app.current_screen(), AppService.MAIN_MENU)
	app.open_first_lesson()
	assert_eq(app.current_screen(), AppService.LESSON, "lesson 1 opens")
	var player: Control = _top(app)
	player.emit_signal(&"finished", "lesson_01")
	assert_true(app.lessons.is_finished("lesson_01"), "finished is recorded")
	player.emit_signal(&"closed")
	assert_eq(app.current_screen(), AppService.MAIN_MENU, "closing goes back to the menu")
	_teardown(parts)


func test_first_launch_start_lesson_opens_lesson_one() -> void:
	var parts: Array = _setup()
	var app: AppService = parts[0]
	var host: Control = parts[1]
	app.settings.first_launch_answered = false
	app.attach_host(host)
	app.play_now()
	(_top(app).get(&"start_button") as Button).pressed.emit()
	assert_true(app.settings.first_launch_answered)
	assert_eq(app.current_screen(), AppService.LESSON)
	var lesson: Object = _top(app).get(&"lesson")
	if lesson != null:
		assert_eq(lesson.get(&"id"), "lesson_01")
	# AT-73: leaving the lesson shows the main menu, Back the title screen,
	# and PLAY starts a new Easy puzzle with no offer.
	_top(app).emit_signal(&"closed")
	assert_eq(app.current_screen(), AppService.MAIN_MENU)
	app.go_back()
	assert_eq(app.current_screen(), AppService.TITLE)
	app.play_now()
	assert_eq(app.current_screen(), AppService.PLAY)
	assert_eq(app.session.level, Levels.EASY)
	_teardown(parts)
