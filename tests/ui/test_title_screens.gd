extends "res://tests/unit_test.gd"
## The title screen, Info and About (GDD 15.0 to 15.6, AT-72 to AT-78,
## ARCHITECTURE section 11): every start opens the title screen; PLAY shows
## the lesson offer once, resumes the puzzle in progress or starts one at
## the last level started; Back rules; Info shows the GDD 15.5 text word for
## word; About shows the card text of GDD 15.6 in order and the engine's own
## notices; Buy me a coffee on both screens hands exactly one address to the
## link opener. Built with an AppService that is not an autoload, with a
## recorder as its link opener, so no test opens a browser.

const Fx := preload("res://tests/save/save_fixtures.gd")
const InfoScreen := preload("res://src/ui/info_screen.gd")
const AboutScreen := preload("res://src/ui/about_screen.gd")

var _dirs: Array[String] = []
var _hosts: Array[Control] = []


func _app(dir: String = "") -> AppService:
	if dir == "":
		dir = Fx.fresh_dir("title")
		_dirs.append(dir)
	var app: AppService = AppService.new()
	app.save_dir = dir
	app.use_thread = false
	app.link_opener = _record_link
	app.load_all()
	return app


## Every address handed to the link opener, in order.
var _links: PackedStringArray = PackedStringArray()


func _record_link(url: String) -> void:
	_links.append(url)


func _attach(app: AppService) -> void:
	var host: Control = Control.new()
	host.theme = ThemeFactory.build(app.current_skin())
	host.size = Vector2(360, 800)
	(Engine.get_main_loop() as SceneTree).root.add_child(host)
	_hosts.append(host)
	app.attach_host(host)


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


## Every label under node, in tree order.
func _labels(node: Node) -> Array[Label]:
	var found: Array[Label] = []
	for child: Node in node.get_children():
		if child is Label:
			found.append(child as Label)
		found.append_array(_labels(child))
	return found


func _texts(node: Node) -> PackedStringArray:
	var texts: PackedStringArray = PackedStringArray()
	for label: Label in _labels(node):
		texts.append(label.text)
	return texts


# The title screen and PLAY ------------------------------------------------------

func test_attach_host_opens_the_title_screen_every_time() -> void:
	# AT-72: with or without a puzzle, offer answered or not.
	var app: AppService = _app()
	_attach(app)
	assert_eq(app.current_screen(), AppService.TITLE)
	var title: Control = app.current_screen_node()
	assert_eq((title.get(&"play_button") as Button).text, "PLAY")
	assert_eq((title.get(&"menu_button") as Button).text, "MENU")
	assert_eq((title.get(&"info_button") as Button).text, "INFO")
	assert_eq((title.get(&"about_button") as Button).text, "ABOUT")
	assert_eq((title.get(&"play_button") as Button).theme_type_variation, ThemeFactory.BUTTON_PRIMARY)
	for key: StringName in [&"menu_button", &"info_button", &"about_button"]:
		assert_eq((title.get(key) as Button).theme_type_variation, ThemeFactory.BUTTON_SECONDARY, String(key))
	var order: Array[Node] = []
	for key: StringName in [&"play_button", &"menu_button", &"info_button", &"about_button"]:
		order.append(title.get(key) as Node)
	var parent: Node = order[0].get_parent()
	for i: int in order.size():
		assert_eq(order[i].get_parent(), parent, "one stack")
		assert_eq(order[i].get_index(), i, "PLAY, MENU, INFO, ABOUT top to bottom")
	assert_eq(parent.get_child_count(), 4, "four big buttons, nothing else")
	var coffee: Button = title.get(&"coffee_button") as Button
	assert_eq(coffee.text, "BUY ME A COFFEE", "Buy me a coffee, in the button role's capitals")
	assert_eq(coffee.theme_type_variation, ThemeFactory.BUTTON_SECONDARY)
	assert_eq(coffee.custom_minimum_size.y, Layout.ICON_FACE, "a 40 dp face, shorter than the four")
	var touch: Control = title.get(&"coffee_touch") as Control
	assert_eq(touch.get(&"button"), coffee, "in a touch area")
	assert_true(touch.get_combined_minimum_size().y >= Layout.TOUCH_MIN, "the touch area is 48 dp tall")
	assert_eq(touch.size_flags_horizontal, Control.SIZE_SHRINK_CENTER, "only as wide as its label")
	var block: Node = parent.get_parent()
	assert_eq(touch.get_parent(), block.get_parent(), "stacked: in the buttons' part")
	assert_eq(touch.get_index(), block.get_index() + 1, "right after ABOUT and its shadow room")
	assert_true(title.find_child("Wordmark", true, false) != null, "the wordmark")
	assert_true(title.find_child("Hero", true, false) != null, "the hero")
	assert_true(title.find_child("Continue", true, false) == null, "no Continue")
	app.answer_first_launch()
	app.start_new_puzzle(Levels.MEDIUM)
	app.save_all()
	var again: AppService = _app(app.save_dir)
	_attach(again)
	assert_eq(again.current_screen(), AppService.TITLE, "a puzzle in progress still opens the title screen")
	_free_all([app, again])


func test_play_with_the_offer_unanswered_pushes_it_and_back_returns_unanswered() -> void:
	# AT-73, GDD 15.3.
	var app: AppService = _app()
	_attach(app)
	(app.current_screen_node().get(&"play_button") as Button).pressed.emit()
	assert_eq(app.current_screen(), AppService.FIRST_LAUNCH, "the offer shows")
	assert_false(app.has_puzzle_in_progress())
	app.go_back()
	assert_eq(app.current_screen(), AppService.TITLE, "Back returns to the title screen")
	assert_true(app.current_screen_node().visible)
	assert_false(app.settings.first_launch_answered, "not answered")
	app.play_now()
	assert_eq(app.current_screen(), AppService.FIRST_LAUNCH, "it shows again on the next PLAY")
	_free_all([app])


func test_skip_answers_and_plays_a_new_easy_puzzle() -> void:
	var app: AppService = _app()
	_attach(app)
	app.play_now()
	(app.current_screen_node().get(&"skip_button") as Button).pressed.emit()
	assert_true(app.settings.first_launch_answered)
	assert_eq(app.current_screen(), AppService.PLAY, "no main menu in between")
	assert_eq(app.session.level, Levels.EASY)
	assert_eq(app.session.score(), 200)
	assert_eq(app.session.elapsed_seconds(), 0)
	assert_eq(app.stats.started(Levels.EASY), 1)
	_free_all([app])


func test_skip_with_a_puzzle_in_progress_resumes_it() -> void:
	var app: AppService = _app()
	app.start_new_puzzle(Levels.HARD)
	var session: GameSession = app.session
	_attach(app)
	app.play_now()
	(app.current_screen_node().get(&"skip_button") as Button).pressed.emit()
	assert_eq(app.current_screen(), AppService.PLAY)
	assert_eq(app.session, session, "the same puzzle")
	assert_eq(app.stats.started(Levels.HARD), 1, "no new start")
	_free_all([app])


func test_play_resumes_the_puzzle_in_progress() -> void:
	# AT-74: the same cell, mode and time, no new start, after a restart too.
	var app: AppService = _app()
	app.answer_first_launch()
	app.start_new_puzzle(Levels.MEDIUM)
	var session: GameSession = app.session
	var cells: PackedInt32Array = Fx.empty_cells(session)
	session.select(cells[0])
	session.set_mode(GameSession.Mode.CROSS_OUT)
	session.add_time(120.0)
	_attach(app)
	assert_eq(app.current_screen(), AppService.TITLE)
	app.play_now()
	assert_eq(app.current_screen(), AppService.PLAY)
	assert_eq(app.session, session)
	assert_eq(app.stats.started(Levels.MEDIUM), 1)
	app.save_all()
	var again: AppService = _app(app.save_dir)
	_attach(again)
	again.play_now()
	assert_eq(again.current_screen(), AppService.PLAY)
	assert_eq(again.session.puzzle_id, session.puzzle_id)
	assert_eq(again.session.selected, cells[0])
	assert_eq(again.session.mode, GameSession.Mode.CROSS_OUT)
	assert_eq(again.session.elapsed_seconds(), 120)
	assert_eq(again.stats.started(Levels.MEDIUM), 1, "a resume is not a start")
	_free_all([app, again])


func test_play_with_none_starts_at_the_last_level_started() -> void:
	# AT-75 (App), with use_thread off.
	var app: AppService = _app()
	app.answer_first_launch()
	_attach(app)
	app.play_now()
	assert_eq(app.session.level, Levels.EASY, "Easy the first time")
	app.abandon_puzzle()
	app.start_new_puzzle(Levels.BEGINNER)
	Fx.solve(app.session)
	app.on_puzzle_completed()
	assert_false(app.has_puzzle_in_progress())
	var again: AppService = _app(app.save_dir)
	_attach(again)
	assert_eq(again.settings.last_level, Levels.BEGINNER, "saved with the settings")
	var started: int = again.stats.started(Levels.BEGINNER)
	again.play_now()
	assert_eq(again.current_screen(), AppService.PLAY)
	assert_eq(again.session.level, Levels.BEGINNER)
	assert_eq(again.session.score(), 100)
	assert_eq(again.session.elapsed_seconds(), 0)
	assert_eq(again.stats.started(Levels.BEGINNER), started + 1)
	_free_all([app, again])


func test_start_new_puzzle_updates_and_saves_the_last_level() -> void:
	var app: AppService = _app()
	assert_eq(app.settings.last_level, Levels.EASY)
	app.start_new_puzzle(Levels.HARD)
	assert_eq(app.settings.last_level, Levels.HARD)
	var saved: Settings = Settings.from_dict(SaveStore.read(app.path_of(AppService.SETTINGS_FILE), SaveStore.MAX_BYTES_OTHER))
	assert_eq(saved.last_level, Levels.HARD, "saved at once")
	app.start_new_puzzle(42)
	assert_eq(app.settings.last_level, Levels.HARD, "an invalid level changes nothing")
	app.abandon_puzzle()
	app.reset_stats()
	assert_eq(app.settings.last_level, Levels.HARD, "abandon and Reset Stats keep it")
	_free_all([app])


func test_play_is_ignored_while_a_puzzle_is_being_made() -> void:
	var app: AppService = _app()
	app.answer_first_launch()
	_attach(app)
	app.use_thread = true
	app.play_now()
	assert_true(app.is_generating())
	app.play_now()
	app.go_back()
	assert_eq(app.current_screen(), AppService.TITLE, "nothing else happened")
	var waited: int = 0
	while app.get(&"_thread") != null and waited < 20000:
		OS.delay_msec(5)
		waited += 5
		app.call(&"_process", 0.0)
	# Let the making a puzzle card's minimum time pass.
	var overlay: Control = app.get(&"_overlay") as Control
	if overlay != null:
		overlay.call(&"step", Motion.MAKING_DELAY)
		overlay.call(&"step", Motion.MAKING_MIN)
	app.call(&"_process", 0.0)
	assert_eq(app.current_screen(), AppService.PLAY)
	assert_eq(app.stats.started(Levels.EASY), 1, "one tap, one puzzle")
	_free_all([app])


func test_the_default_link_opener_is_the_system_one() -> void:
	var app: AppService = AppService.new()
	assert_eq(app.link_opener, Callable(OS, &"shell_open"), "OS.shell_open unless a test swaps it")
	assert_eq(AppService.SUPPORT_URL, "https://buymeacoffee.com/playinc")
	app.free()


func test_title_coffee_opens_the_support_page_once_and_changes_nothing() -> void:
	# GDD 15.0, AT-86.
	var app: AppService = _app()
	_attach(app)
	var title: Control = app.current_screen_node()
	(title.get(&"coffee_button") as Button).pressed.emit()
	assert_eq(_links, PackedStringArray(["https://buymeacoffee.com/playinc"]), "exactly one address, exactly this one")
	assert_eq(app.current_screen(), AppService.TITLE, "no screen changes")
	assert_eq(app.current_screen_node(), title)
	assert_false(app.settings.first_launch_answered, "the offer stays for the first PLAY")
	assert_false(app.has_puzzle_in_progress(), "no puzzle starts")
	assert_false(app.is_generating())
	_free_all([app])


func test_title_coffee_with_a_puzzle_in_progress_changes_nothing() -> void:
	var app: AppService = _app()
	app.answer_first_launch()
	app.start_new_puzzle(Levels.EASY)
	app.session.add_time(120.0)
	var session: GameSession = app.session
	_attach(app)
	(app.current_screen_node().get(&"coffee_button") as Button).pressed.emit()
	assert_eq(_links.size(), 1)
	assert_eq(app.session, session, "the same puzzle")
	assert_eq(app.session.elapsed_seconds(), 120, "the timer unchanged")
	assert_eq(app.stats.started(Levels.EASY), 1, "Started unchanged")
	_free_all([app])


func test_title_coffee_is_ignored_while_a_puzzle_is_being_made() -> void:
	var app: AppService = _app()
	app.answer_first_launch()
	_attach(app)
	app.use_thread = true
	var title: Control = app.current_screen_node()
	app.play_now()
	assert_true(app.is_generating())
	(title.get(&"coffee_button") as Button).pressed.emit()
	(title.get(&"coffee_button") as Button).pressed.emit()
	assert_eq(_links.size(), 0, "the opener is never called while a puzzle is made")
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
	assert_eq(app.current_screen(), AppService.PLAY)
	assert_eq(app.stats.started(Levels.EASY), 1, "one puzzle")
	assert_eq(_links.size(), 0)
	_free_all([app])


# Back ------------------------------------------------------------------------------

func test_back_on_the_main_menu_alone_opens_the_title_screen() -> void:
	# AT-76.
	var app: AppService = _app()
	app.answer_first_launch()
	app.start_new_puzzle(Levels.EASY)
	_attach(app)
	app.goto(AppService.MAIN_MENU)
	app.goto(AppService.STATS)
	app.go_back()
	assert_eq(app.current_screen(), AppService.MAIN_MENU, "Back on Stats returns to the main menu")
	app.go_back()
	assert_eq(app.current_screen(), AppService.TITLE, "Back on the main menu opens the title screen")
	assert_eq(app.current_screen_node().get_parent(), _hosts[0])
	assert_true(app.has_puzzle_in_progress(), "the puzzle stays")
	app.play_now()
	assert_eq(app.current_screen(), AppService.PLAY)
	_free_all([app])


func test_menu_opens_the_main_menu_and_changes_nothing() -> void:
	# AT-76: MENU opens the main menu with no offer, no puzzle and no stats
	# change; Back returns to the title screen.
	var app: AppService = _app()
	_attach(app)
	(app.current_screen_node().get(&"menu_button") as Button).pressed.emit()
	assert_eq(app.current_screen(), AppService.MAIN_MENU, "MENU opens the main menu")
	assert_false(app.settings.first_launch_answered, "the offer stays for the first PLAY")
	assert_false(app.has_puzzle_in_progress(), "no puzzle started")
	assert_false((app.current_screen_node().get(&"continue_button") as Button).visible, "no Continue")
	app.go_back()
	assert_eq(app.current_screen(), AppService.TITLE, "Back on the main menu opens the title screen")
	app.play_now()
	assert_eq(app.current_screen(), AppService.FIRST_LAUNCH, "the offer shows on the PLAY after MENU")
	app.go_back()
	app.answer_first_launch()
	app.start_new_puzzle(Levels.MEDIUM)
	var elapsed: float = app.session.elapsed
	app.goto(AppService.TITLE)
	(app.current_screen_node().get(&"menu_button") as Button).pressed.emit()
	assert_eq(app.current_screen(), AppService.MAIN_MENU)
	assert_eq(app.stats.started(Levels.MEDIUM), 1, "Started unchanged")
	assert_eq(app.session.elapsed, elapsed, "the timer unchanged")
	app.go_back()
	assert_eq(app.current_screen(), AppService.TITLE)
	_free_all([app])


func test_back_on_the_title_screen_saves_to_quit() -> void:
	# GDD 15.0: Back on the title screen closes the app, with everything
	# saved. Outside the scene tree the quit itself cannot run; the save can.
	var app: AppService = _app()
	_attach(app)
	app.start_new_puzzle(Levels.EASY)
	app.goto(AppService.TITLE)
	SaveStore.remove(app.path_of(AppService.PUZZLE_FILE))
	app.settings.sound = false
	app.go_back()
	assert_eq(app.current_screen(), AppService.TITLE, "no screen opens: the app closes")
	var again: AppService = _app(app.save_dir)
	assert_false(again.settings.sound, "settings saved")
	assert_true(again.has_puzzle_in_progress(), "the puzzle saved")
	_free_all([app, again])


func test_info_and_about_open_over_the_title_screen_and_back_returns() -> void:
	var app: AppService = _app()
	_attach(app)
	for pair: Array in [[&"info_button", AppService.INFO], [&"about_button", AppService.ABOUT]]:
		(app.current_screen_node().get(pair[0]) as Button).pressed.emit()
		assert_eq(app.current_screen(), pair[1])
		app.go_back()
		assert_eq(app.current_screen(), AppService.TITLE, "Android Back returns from %s" % pair[1])
		assert_true(app.current_screen_node().visible)
		(app.current_screen_node().get(pair[0]) as Button).pressed.emit()
		var back: Control = app.current_screen_node().find_child("Back", true, false) as Control
		(back.get(&"button") as Button).pressed.emit()
		assert_eq(app.current_screen(), AppService.TITLE, "the back button returns from %s" % pair[1])
	_free_all([app])


# Info ---------------------------------------------------------------------------------

## GDD 15.5 as [heading, [paragraph, ...]]: from the first bold heading to
## the "Decision:" note after the text, with the bracketed numbers removed.
func _gdd_info() -> Array[Array]:
	var text: String = FileAccess.get_file_as_string("res://docs/GDD.md")
	var sections: Array[Array] = []
	var inside: bool = false
	for raw: String in text.split("\n"):
		var line: String = raw.strip_edges()
		if line.begins_with("### 15.5"):
			inside = true
			continue
		if not inside:
			continue
		if line.begins_with("Decision:") or line.begins_with("### "):
			break
		if line.begins_with("**"):
			var end: int = line.find("**", 2)
			assert_true(line.substr(end + 2).strip_edges().begins_with("["), "GDD heading has its bracketed numbers: %s" % line)
			sections.append([line.substr(2, end - 2), []])
		elif line != "" and not sections.is_empty():
			(sections.back()[1] as Array).append(line)
	return sections


func test_info_text_is_gdd_15_5_word_for_word() -> void:
	var gdd: Array[Array] = _gdd_info()
	assert_eq(gdd.size(), 15, "fifteen headings in the GDD")
	assert_eq(InfoScreen.SECTIONS.size(), gdd.size())
	for i: int in mini(gdd.size(), InfoScreen.SECTIONS.size()):
		assert_eq(InfoScreen.SECTIONS[i][0], gdd[i][0], "heading %d" % i)
		assert_eq(InfoScreen.SECTIONS[i][1], gdd[i][1], "paragraphs of %s" % gdd[i][0])


func test_info_shows_every_heading_in_order_and_no_bracketed_numbers() -> void:
	var app: AppService = _app()
	_attach(app)
	app.goto(AppService.INFO)
	var screen: Control = app.current_screen_node()
	var cards: Array[PanelContainer] = screen.get(&"cards")
	assert_eq(cards.size(), 15)
	var headings: PackedStringArray = ["How to play", "Getting around", "The board", "The candidate ring",
		"Place and Cross out", "Erase and Undo", "Auto Cross", "Mistakes", "Timer and pause", "Score",
		"Hints", "Levels", "Finishing and stats", "Lessons", "Settings"]
	for i: int in mini(cards.size(), headings.size()):
		var labels: Array[Label] = _labels(cards[i])
		assert_eq(labels[0].theme_type_variation, ThemeFactory.HEADING)
		assert_eq(labels[0].text, ThemeFactory.display_text(ThemeFactory.HEADING, headings[i]))
		for label: Label in labels:
			assert_true(label == labels[0] or label.theme_type_variation == ThemeFactory.BODY, "paragraphs in BODY")
			assert_eq(label.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "every label wraps")
	for text: String in _texts(screen):
		assert_false(text.contains("["), "no bracketed numbers: %s" % text.left(40))
		assert_false(text.contains("—") or text.contains("--"), "no em dash or double hyphen")
	var scroll: ScrollContainer = screen.get(&"scroll")
	assert_eq(scroll.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED, "never sideways")
	assert_eq(scroll.scroll_vertical, 0, "opens at the top")
	_free_all([app])


# About ----------------------------------------------------------------------------------

func test_about_shows_version_copyright_and_the_engine_notices() -> void:
	var app: AppService = _app()
	_attach(app)
	app.goto(AppService.ABOUT)
	var screen: Control = app.current_screen_node()
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	assert_ne(version, "", "the project has a version")
	var card: Node = screen.find_child("Card", true, false)
	var card_texts: PackedStringArray = _texts(card)
	assert_eq(card_texts, PackedStringArray([
		ThemeFactory.display_text(ThemeFactory.TITLE, "Sudoku"),
		ThemeFactory.display_text(ThemeFactory.CAPTION, "Version " + version),
		"Designed and written by Bart Basi.",
		"Copyright 2026 Play, Inc.",
		"Sudoku is free. It works offline, with no ads and no accounts, and it collects no data. Everything you do stays on this device.",
		"Sudoku is free software under the GNU General Public License, version 3, with additional terms. It comes with no warranty. The license and its terms are below. Source code: github.com/bartbasi/Sudoku",
		"If you enjoy it and want to support the game, you can buy me a coffee.",
		"Questions, feedback and notices: bartbasi@gmail.com",
		"Privacy policy: bartbasi.github.io/Sudoku/privacy",
		"Made with the Godot Engine.",
	]), "GDD 15.6 card items in order")
	for text: String in card_texts:
		assert_false(text.to_lower().contains("all rights reserved"), "no All rights reserved in the card: %s" % text)
	# The attributions are license terms: whole, as written, and shown.
	for pair: Array in [["Designed and written by Bart Basi.", ThemeFactory.BODY_SMALL], ["Copyright 2026 Play, Inc.", ThemeFactory.BODY_SMALL]]:
		var found: Label = null
		for label: Label in _labels(card):
			if label.text == pair[0]:
				found = label
		assert_true(found != null, "%s in the card" % pair[0])
		assert_eq(found.theme_type_variation, pair[1], "%s in its own style" % pair[0])
		assert_true(found.visible, "%s shown" % pair[0])
		assert_eq(found.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING, "%s never cut" % pair[0])
		assert_eq(found.max_lines_visible, -1, "%s never cut" % pair[0])
	# The button sits right after the support line, before the contact line.
	var coffee: Button = screen.get(&"coffee_button") as Button
	assert_eq(coffee.text, "BUY ME A COFFEE")
	assert_eq(coffee.theme_type_variation, ThemeFactory.BUTTON_SECONDARY)
	var order: Array[String] = []
	for child: Node in coffee.get_parent().get_parent().get_children():
		if child is Label:
			order.append((child as Label).text)
		elif child.is_ancestor_of(coffee):
			order.append("[coffee]")
	assert_eq(order.find("[coffee]"), order.find("If you enjoy it and want to support the game, you can buy me a coffee.") + 1, "the button under the support line")
	assert_eq(order.find("Questions, feedback and notices: bartbasi@gmail.com"), order.find("[coffee]") + 1, "and over the contact line")
	assert_eq(card_texts[card_texts.size() - 1], "Made with the Godot Engine.", "still the last line")
	for text: String in card_texts:
		assert_false(text.contains("http") or text.contains("www"), "no web link in the card: %s" % text)
		assert_eq(text.to_lower().contains("github"), text == "Privacy policy: bartbasi.github.io/Sudoku/privacy" or text == AboutScreen.LICENSE, "github only in the privacy and license lines")
		assert_false(text.contains("—") or text.contains("--"), "no em dash or double hyphen")
	assert_false(bool(screen.call(&"is_complete")), "the notice blocks wait for the frames after the first")
	screen.call(&"build_all_notices")
	assert_true(bool(screen.call(&"is_complete")))
	var notices: Node = screen.get(&"notices")
	var texts: PackedStringArray = _texts(notices)
	assert_eq(texts[0], ThemeFactory.display_text(ThemeFactory.HEADING, "Open source notices"), "the heading first")
	var shown: String = " ".join(texts)
	# The engine's own license, with only white space changed.
	var license: String = " ".join(AboutScreen.notice_paragraphs(Engine.get_license_text()))
	assert_true(license.length() > 100)
	assert_true(shown.contains(license), "the Godot license as the engine gives it")
	assert_true(_squash(shown).contains(_squash(Engine.get_license_text())), "every word of it, in order")
	for entry: Dictionary in Engine.get_copyright_info():
		assert_true(texts.has(ThemeFactory.display_text(ThemeFactory.CAPTION, str(entry["name"]))), "component %s" % entry["name"])
	var licenses: Dictionary = Engine.get_license_info()
	for key: Variant in licenses.keys():
		assert_true(_squash(shown).contains(_squash(str(licenses[key]))), "license %s in full" % key)
	var scroll: ScrollContainer = screen.get(&"scroll")
	for label: Label in _labels(scroll):
		assert_eq(label.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "every label wraps")
		assert_eq(label.custom_minimum_size.x, 1.0, "and is never wider than the page")
		assert_eq(label.mouse_filter, Control.MOUSE_FILTER_IGNORE, "nothing is a link")
	assert_eq(scroll.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED, "never sideways")
	_free_all([app])


## Every BaseButton under node.
func _buttons(node: Node) -> Array[BaseButton]:
	var found: Array[BaseButton] = []
	for child: Node in node.get_children():
		if child is BaseButton:
			found.append(child as BaseButton)
		found.append_array(_buttons(child))
	return found


func test_about_coffee_opens_the_support_page_and_nothing_else_does() -> void:
	# GDD 15.6, AT-78, AT-86: only Back and Buy me a coffee react to a tap.
	var app: AppService = _app()
	_attach(app)
	app.goto(AppService.ABOUT)
	var screen: Control = app.current_screen_node()
	screen.call(&"build_all_notices")
	var coffee: Button = screen.get(&"coffee_button") as Button
	var back: Button = (screen.find_child("Back", true, false) as Control).get(&"button") as Button
	var buttons: Array[BaseButton] = _buttons(screen)
	assert_eq(buttons.size(), 2, "two buttons on the screen")
	assert_true(buttons.has(coffee) and buttons.has(back), "Back and Buy me a coffee")
	# Everything under the page that takes a tap is the coffee button's.
	var scroll: ScrollContainer = screen.get(&"scroll")
	var takers: Array[Control] = []
	_tap_takers(scroll.get_child(0), takers)
	for control: Control in takers:
		assert_true(control == coffee or control == coffee.get_parent(), "%s takes no tap" % control.name)
	assert_eq(_links.size(), 0, "building the screen opens nothing")
	coffee.pressed.emit()
	assert_eq(_links, PackedStringArray(["https://buymeacoffee.com/playinc"]), "exactly one address, exactly this one")
	assert_eq(app.current_screen(), AppService.ABOUT, "the screen stays")
	back.pressed.emit()
	assert_eq(app.current_screen(), AppService.TITLE)
	assert_eq(_links.size(), 1, "Back opens nothing")
	_free_all([app])


## Every control under node whose mouse filter is not IGNORE.
func _tap_takers(node: Node, found: Array[Control]) -> void:
	for child: Node in node.get_children():
		if child is Control and (child as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			found.append(child as Control)
		_tap_takers(child, found)


## text with all white space removed, to compare words in order.
func _squash(text: String) -> String:
	var out: String = text
	for space: String in [" ", "\n", "\r", "\t"]:
		out = out.replace(space, "")
	return out


func test_notice_paragraphs_join_lines_and_keep_dividers() -> void:
	var text: String = "First line\n  goes on here.\n\nSecond one.\n--------\nThird\r\npart.\n\n\n"
	var got: PackedStringArray = AboutScreen.notice_paragraphs(text)
	assert_eq(got, PackedStringArray(["First line goes on here.", "Second one.", "--------", "Third part."]))
	assert_eq(AboutScreen.notice_paragraphs(""), PackedStringArray())
	# Windows line ends split exactly like plain ones.
	assert_eq(AboutScreen.notice_paragraphs("a b\r\nc d\r\n\r\ne f"), PackedStringArray(["a b c d", "e f"]))
	assert_eq(AboutScreen.notice_paragraphs("a b\r\nc d\r\n\r\ne f"), AboutScreen.notice_paragraphs("a b\nc d\n\ne f"))
	for paragraph: String in got:
		assert_false(paragraph.contains("\r") or paragraph.contains("\n"), "no line break left: %s" % paragraph)


func test_notice_paragraphs_keep_short_title_lines_in_the_game_files() -> void:
	var text: String = "Sudoku\r\nCopyright 2026 Play, Inc.\r\nDesigned and written by Bart Basi.\r\n\r\nThis is a long wrapped line of prose that goes past forty\r\ncharacters and joins.\r\n"
	assert_eq(AboutScreen.notice_paragraphs(text, true), PackedStringArray([
		"Sudoku\nCopyright 2026 Play, Inc.\nDesigned and written by Bart Basi.",
		"This is a long wrapped line of prose that goes past forty characters and joins.",
	]))
	# Without it (the engine's text) every line joins, as before.
	assert_eq(AboutScreen.notice_paragraphs(text)[0], "Sudoku Copyright 2026 Play, Inc. Designed and written by Bart Basi.")


## text with every run of white space made one space, ends trimmed.
func _words(text: String) -> String:
	var out: String = text.replace("\r", " ").replace("\n", " ").replace("\t", " ")
	while out.contains("  "):
		out = out.replace("  ", " ")
	return out.strip_edges()


func test_about_files_ship_and_are_read() -> void:
	for path: String in [AboutScreen.NOTICE_PATH, AboutScreen.COPYING_PATH]:
		assert_true(FileAccess.file_exists(path), "%s in the project" % path)
		assert_true(AboutScreen.read_text(path).length() > 1000, "%s read and not empty" % path)
	assert_eq(AboutScreen.read_text("res://no_such_notice_file"), "", "a missing file reads as nothing")
	assert_eq(AboutScreen.notice_paragraphs(AboutScreen.read_text("res://no_such_notice_file"), true), PackedStringArray())


func test_about_shows_the_sudoku_notice_and_the_gpl_before_godot() -> void:
	var app: AppService = _app()
	_attach(app)
	app.goto(AppService.ABOUT)
	var screen: Control = app.current_screen_node()
	screen.call(&"build_all_notices")
	var notices: Node = screen.get(&"notices")
	var texts: PackedStringArray = _texts(notices)
	var sudoku: int = texts.find(ThemeFactory.display_text(ThemeFactory.CAPTION, "Sudoku"))
	var gpl: int = texts.find(ThemeFactory.display_text(ThemeFactory.CAPTION, "GNU General Public License, version 3"))
	var godot: int = texts.find(ThemeFactory.display_text(ThemeFactory.CAPTION, "Godot Engine"))
	assert_eq(sudoku, 1, "the Sudoku notice right under the heading")
	assert_true(gpl > sudoku and godot > gpl, "then the GPL, then Godot")
	# Each section holds its file word for word; only line breaks are joined.
	var notice_text: String = AboutScreen.read_text(AboutScreen.NOTICE_PATH)
	var gpl_text: String = AboutScreen.read_text(AboutScreen.COPYING_PATH)
	var notice_shown: PackedStringArray = texts.slice(sudoku + 1, gpl)
	var gpl_shown: PackedStringArray = texts.slice(gpl + 1, godot)
	assert_eq(_words(" ".join(notice_shown)), _words(notice_text), "NOTICE word for word")
	assert_eq(_words(" ".join(gpl_shown)), _words(gpl_text), "COPYING word for word")
	assert_eq(notice_shown, AboutScreen.notice_paragraphs(notice_text, true), "one label per paragraph")
	assert_eq(gpl_shown, AboutScreen.notice_paragraphs(gpl_text, true), "one label per paragraph")
	assert_true(_words(gpl_text).contains("TERMS AND CONDITIONS"), "the real license")
	assert_true(" ".join(notice_shown).contains("Copyright 2026 Play, Inc.") and " ".join(notice_shown).contains("Designed and written by Bart Basi."), "the attributions in the notice")
	# Paragraph labels in the small notice style, captions as captions, and
	# a rule between the GPL and Godot.
	var labels: Array[Label] = _labels(notices)
	# Each caption sits space_xl under what is above it (7.17), the first
	# one too, as the Godot caption did when it came first.
	var space_xl: float = (screen.call(&"skin") as GameSkin).space_xl
	assert_true(space_xl > 0.0)
	for i: int in [sudoku, gpl]:
		var gap: Control = notices.get_child(labels[i].get_index() - 1) as Control
		assert_false(gap is Label, "a gap above caption %d" % i)
		assert_eq(gap.custom_minimum_size.y, space_xl, "space_xl above caption %d" % i)
	var godot_index: int = labels[godot].get_index()
	assert_true(notices.get_child(godot_index - 2) is HSeparator, "a rule right before the Godot section")
	for i: int in labels.size():
		if i == sudoku or i == gpl:
			assert_eq(labels[i].theme_type_variation, ThemeFactory.CAPTION, "a caption")
		elif i > sudoku and i < godot:
			assert_eq(labels[i].theme_type_variation, ThemeFactory.BODY_SMALL_12, "notice paragraph style")
		assert_eq(labels[i].mouse_filter, Control.MOUSE_FILTER_IGNORE, "nothing is a link")
	_free_all([app])
