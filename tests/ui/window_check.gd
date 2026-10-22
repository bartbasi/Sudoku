extends SceneTree
## Layout checks on the window shapes of DESIGN_SYSTEM.md 4.11 and the
## screens of 4.10, in a running scene tree. Not a test file: the test
## runner keeps every node outside the tree, where Godot's box containers do
## not lay out, so tests/ui/test_window_layout.gd runs this script as a child
## process and fails when it does. Run it alone with:
##
##   timeout 300 godot --headless --path . --script res://tests/ui/window_check.gd
##
## For every window the game plays in, it checks the play screen (the
## arrangement, everything inside the safe rect, nothing overlapping, touch
## targets of 48 dp or more, the header row mirrored side by side, the coffee
## cup in the band under Pause), the
## main menu, the first launch offer, the pause menu, the completion screen
## (with About and Buy me a coffee where GDD 15.7 puts them, Settings too),
## the lists and the confirm dialog. Prints one line per failure and exits 0
## only when every check passes. Saves go to user://window_check, which is
## wiped before and after.
## Owner: ui-systems-dev.

const Fx := preload("res://tests/save/save_fixtures.gd")
const Model := preload("res://tools/design/layout_model.gd")
const SAVE_DIR: String = "user://window_check"
## Rects may touch; anything closer than this counts as an overlap.
const SLACK: float = 0.5
## Frames to wait after a change, so every container has sorted.
const SETTLE_FRAMES: int = 4
## The whole run must end well inside this many seconds.
const WATCHDOG_SECONDS: float = 240.0

var _failures: PackedStringArray = PackedStringArray()
var _checks: int = 0
var _app: AppService = null
var _host: Control = null
var _skin: GameSkin = null


## A window shape: label, size, safe rect and the arrangement 4.11 expects.
class Shape extends RefCounted:
	var label: String
	var size: Vector2
	var safe: Rect2
	var expected: int = -1


func _initialize() -> void:
	create_timer(WATCHDOG_SECONDS).timeout.connect(func() -> void:
		print("window_check: FAIL timed out after %d s" % int(WATCHDOG_SECONDS))
		quit(2))
	_run.call_deferred()


func _run() -> void:
	Fx.wipe(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_skin = load("res://src/skins/pop_light.tres") as GameSkin
	for window: Shape in _shapes():
		await _check_play(window)
		await _check_title(window)
		await _check_main_menu(window, false)
		await _check_main_menu(window, true)
		await _check_first_launch(window)
		await _check_pause(window)
		await _check_completion(window)
		await _check_lists(window)
		await _check_dialog(window)
	await _check_capped_dialog()
	_end_app()
	Fx.wipe(SAVE_DIR)
	for line: String in _failures:
		print("FAIL ", line)
	print("window_check: %d checks, %d failed" % [_checks, _failures.size()])
	quit(0 if _failures.is_empty() else 1)


# Checks -----------------------------------------------------------------------------

func _ok(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _inside(inner: Rect2, outer: Rect2) -> bool:
	return outer.grow(SLACK).encloses(inner)


func _overlap(a: Rect2, b: Rect2) -> bool:
	return a.grow(-SLACK).intersects(b.grow(-SLACK))


## node's rect in the host's coordinates (the window's).
func _rect(node: Control) -> Rect2:
	return _host.get_global_transform().affine_inverse() * node.get_global_rect()


## A global rect in the host's coordinates.
func _local(global: Rect2) -> Rect2:
	return _host.get_global_transform().affine_inverse() * global


## A button's touch area: its touch target when it has one, else itself.
func _touch(button: Control) -> Rect2:
	var parent: Control = button.get_parent() as Control
	if parent != null and parent.get(&"button") == button:
		return _rect(parent)
	return _rect(button)


func _check_touch(button: Control, where: String) -> void:
	var touch: Rect2 = _touch(button)
	_ok(touch.size.x >= Layout.TOUCH_MIN - SLACK and touch.size.y >= Layout.TOUCH_MIN - SLACK,
		"%s: %s touch area %s is 48 by 48 or more" % [where, button.name, touch.size])


## Visible buttons: inside the safe rect, 48 dp or more, none on another.
func _check_buttons(buttons: Array, safe: Rect2, where: String) -> void:
	var rects: Array[Rect2] = []
	for item: Variant in buttons:
		var button: Control = item as Control
		if button == null or not button.is_visible_in_tree():
			continue
		var rect: Rect2 = _rect(button)
		_ok(_inside(rect, safe), "%s: %s %s inside the safe rect %s" % [where, button.name, rect, safe])
		_check_touch(button, where)
		for other: Rect2 in rects:
			_ok(not _overlap(rect, other), "%s: %s %s overlaps another button %s" % [where, button.name, rect, other])
		rects.append(rect)


## The two halves: side by side only when 4.11 says so, the first part left
## of (or above) the second, and the hero off the second part.
func _check_halves(halves: HalvesBox, window: Shape, where: String) -> void:
	var side: bool = window.expected == Layout.Arrangement.SIDE
	_ok(halves.is_side() == side, "%s: two halves only side by side" % where)
	var first: Rect2 = _rect(halves.get_child(0) as Control)
	var second: Rect2 = _rect(halves.get_child(1) as Control)
	_ok(not _overlap(first, second), "%s: the parts %s and %s do not overlap" % [where, first, second])
	if side:
		_ok(first.end.x <= second.position.x + SLACK, "%s: the first part at the left" % where)
	else:
		_ok(first.end.y <= second.position.y + SLACK, "%s: the first part above" % where)
	var hero: HeroIcon = halves.find_child("Hero", true, false) as HeroIcon
	if hero != null:
		var box: float = hero.box_side()
		_ok(box >= UiSizes.HERO_MIN - SLACK and box <= UiSizes.HERO_MAX + SLACK, "%s: hero %.0f within 64 to 200" % [where, box])
		var drawn: Rect2 = Rect2(_rect(hero).get_center() - Vector2(box, box) * 0.5, Vector2(box, box))
		_ok(_inside(drawn, window.safe), "%s: the hero %s inside the safe rect" % [where, drawn])
		_ok(not _overlap(drawn, second), "%s: the hero stays off the second part" % where)


# Windows ----------------------------------------------------------------------------

func _shape(label: String, w: float, h: float, top: float, bottom: float, expected: int) -> Shape:
	var out: Shape = Shape.new()
	out.label = label
	out.size = Vector2(w, h)
	out.safe = Rect2(0.0, top, w, h - top - bottom)
	out.expected = expected
	return out


## The screens of 4.10 and the 4.11 windows the game plays in.
func _shapes() -> Array[Shape]:
	var out: Array[Shape] = []
	var all: Array = Model.screens()
	all.append_array(Model.window_screens())
	for s: Model.Screen in all:
		if s.expected != Layout.Arrangement.TOO_SMALL:
			out.append(_shape(s.label, s.w, s.h, s.top, s.bottom, s.expected))
	return out


## A fresh app and host for window, with no puzzle and the offer answered.
func _new_app(window: Shape) -> void:
	_end_app()
	Fx.wipe(SAVE_DIR)
	_app = AppService.new()
	_app.save_dir = SAVE_DIR
	_app.use_thread = false
	_app.load_all()
	_app.settings.first_launch_answered = true
	_app.skins = root.get_node_or_null(^"Skins")
	_app.set_skin(&"pop_light")
	_host = Control.new()
	_host.name = "WindowCheckHost"
	_host.theme = ThemeFactory.build(_skin)
	_host.size = window.size
	root.add_child(_host)
	_app.attach_host(_host)


func _end_app() -> void:
	if _host != null:
		root.remove_child(_host)
		_host.free()
		_host = null
	if _app != null:
		_app.free()
		_app = null


## Gives the screen on top the window's safe rect and waits for layout.
func _fit(window: Shape) -> Control:
	var screen: UiScreen = _app.current_screen_node() as UiScreen
	screen.safe_rect_override = window.safe
	_app.apply_window(window.safe)
	await _settle(screen)
	return screen


func _settle(screen: Control) -> void:
	# The screen slides in from the right; put it at rest at once.
	screen.position = Vector2.ZERO
	for tween: Tween in get_processed_tweens():
		tween.kill()
	screen.modulate.a = 1.0
	if screen.has_method(&"relayout"):
		screen.call(&"relayout")
	for i: int in SETTLE_FRAMES:
		await process_frame
	if screen.has_method(&"relayout"):
		screen.call(&"relayout")
	await process_frame


# The play screen ---------------------------------------------------------------------

func _check_play(window: Shape) -> void:
	_new_app(window)
	_app.start_new_puzzle(Levels.MEDIUM)
	_app.session.add_time(3725.0)
	var screen: Control = await _fit(window)
	var where: String = "%s, play" % window.label
	var area: PlayArea = screen.get(&"play_area") as PlayArea
	var hud: PlayHud = screen.get(&"hud") as PlayHud
	hud.refresh()
	await process_frame
	var arrangement: int = area.arrangement()
	_ok(arrangement == window.expected, "%s: arrangement %d, 4.11 says %d" % [where, arrangement, window.expected])
	_ok(not _app.is_too_small(), "%s: no too small layer" % where)
	_ok(_rect(area) == window.safe, "%s: PlayArea %s gets the whole safe rect %s" % [where, _rect(area), window.safe])

	var content: Rect2 = window.safe.grow(-_skin.page_margin)
	var shadow: Vector2 = Vector2(_skin.shadow_offset, _skin.shadow_offset)
	var board: Rect2 = _rect(area.view)
	var faces: Rect2 = _local(area.pad.control_rect_global(&"pad:1").merge(area.pad.control_rect_global(&"erase")))
	var keys: Rect2 = Rect2(faces.position, faces.size + shadow)
	var header: Rect2 = _rect(hud)
	var sticker: Rect2 = _rect(screen.get(&"level_sticker") as Control)
	var zone: Rect2 = _rect(screen.get(&"zone") as Control)
	for pair: Array in [["board", board], ["key faces", faces], ["header row", header], ["sticker", sticker], ["info zone", zone]]:
		_ok(_inside(pair[1] as Rect2, content), "%s: the %s %s inside the content box %s" % [where, pair[0], pair[1], content])
	_ok(_inside(keys, window.safe), "%s: the keys with their shadow inside the safe rect" % where)
	_ok(header == _local(area.header_rect_global()), "%s: the HUD %s sits in the header row %s" % [where, header, _local(area.header_rect_global())])
	_ok(is_equal_approx(header.size.y, Layout.HEADER_ROW), "%s: header row %.1f is 48" % [where, header.size.y])
	_ok(zone == _local(area.info_zone_rect_global()), "%s: the panels cover the info zone" % where)
	var pairs: Array = [["board", board, "keys", keys], ["board", board, "header row", header], ["board", board, "sticker", sticker],
		["board", board, "info zone", zone], ["keys", keys, "info zone", zone], ["keys", keys, "header row", header], ["keys", keys, "sticker", sticker]]
	for pair: Array in pairs:
		_ok(not _overlap(pair[1] as Rect2, pair[3] as Rect2), "%s: the %s %s and the %s %s overlap" % [where, pair[0], pair[1], pair[2], pair[3]])

	# Header row: each control inside the row, none on another, 48 dp touch.
	var time_block: Control = hud.get_node(^"Time") as Control
	var row: Array[Rect2] = []
	for control: Control in [hud.hint_touch, time_block, hud.score_block, hud.pause_touch]:
		var rect: Rect2 = _rect(control)
		_ok(_inside(rect, header), "%s: %s %s inside the header row %s (1:02:05 on the clock)" % [where, control.name, rect, header])
		for other: Rect2 in row:
			_ok(not _overlap(rect, other), "%s: %s %s overlaps a neighbour %s" % [where, control.name, rect, other])
		row.append(rect)
	_check_touch(hud.hint_button, where)
	_check_touch(hud.pause_button, where)
	for key: StringName in [&"pad:1", &"pad:9", &"mode", &"undo", &"erase"]:
		var face: Rect2 = _local(area.pad.control_rect_global(key))
		_ok(face.size.y >= Layout.KEY_MIN - SLACK, "%s: %s face %.1f tall" % [where, key, face.size.y])
	var hint_x: float = _rect(hud.hint_touch).get_center().x
	var pause_x: float = _rect(hud.pause_touch).get_center().x
	var time_x: float = _rect(time_block).get_center().x
	if arrangement == Layout.Arrangement.SIDE:
		_ok(hud.is_mirrored(), "%s: mirrored side by side" % where)
		_ok(pause_x < time_x and time_x < hint_x, "%s: Pause, time and score, then Hint" % where)
		_ok(header.position.x >= board.end.x, "%s: the header row is in the side column" % where)
		_ok(zone.position.x >= board.end.x, "%s: the hint panel sits beside the board" % where)
		_ok(faces.position.x >= board.end.x, "%s: the pad sits beside the board" % where)
	else:
		_ok(not hud.is_mirrored(), "%s: not mirrored stacked" % where)
		_ok(hint_x < time_x and time_x < pause_x, "%s: Hint, time and score, then Pause" % where)
		_ok(zone.end.y <= board.position.y + SLACK, "%s: the hint panel sits above the board" % where)

	# The coffee cup (GDD 15.7): a 48 dp touch area at the top of the band,
	# right under Pause, off the board, the keys, the sticker and the row.
	var cup_button: Button = screen.get(&"coffee_button") as Button
	var cup: Rect2 = _touch(cup_button)
	var band: Rect2 = _local(area.band_rect_global())
	var pause_rect: Rect2 = _rect(hud.pause_touch)
	_ok(cup_button.is_visible_in_tree(), "%s: the coffee cup shows" % where)
	_check_touch(cup_button, where)
	_ok(_inside(cup, window.safe), "%s: the coffee cup %s inside the safe rect" % [where, cup])
	_ok(_inside(cup, band), "%s: the coffee cup %s inside the band %s" % [where, cup, band])
	for pair: Array in [["board", board], ["keys", keys], ["sticker", sticker], ["header row", header]]:
		_ok(not _overlap(cup, pair[1] as Rect2), "%s: the coffee cup %s and the %s %s overlap" % [where, cup, pair[0], pair[1]])
	_ok(absf(cup.get_center().x - pause_rect.get_center().x) <= SLACK and cup.position.y >= pause_rect.end.y - SLACK, "%s: the coffee cup %s right under Pause %s" % [where, cup, pause_rect])
	_ok(_inside(cup, zone.grow_side(SIDE_BOTTOM, _skin.space_s)), "%s: the coffee cup within the info zone the panels cover" % where)
	if arrangement == Layout.Arrangement.SIDE:
		_ok(cup.end.x < sticker.position.x, "%s: side by side the cup at the board's end of the band, the sticker at the far end" % where)
	else:
		_ok(cup.position.x > sticker.end.x, "%s: stacked the sticker at the left, the cup at the right" % where)

	# A hint on screen stays inside the info zone and off the board.
	screen.call(&"buy_hint")
	await process_frame
	await process_frame
	_ok(not cup_button.is_visible_in_tree(), "%s: the hint panel covers the coffee cup with Pause" % where)
	var panel: HintPanel = screen.get(&"hint_panel") as HintPanel
	var panel_rect: Rect2 = _rect(panel)
	_ok(_inside(panel_rect, zone), "%s: the hint panel %s inside the info zone %s" % [where, panel_rect, zone])
	_ok(not _overlap(panel_rect, board), "%s: the hint panel never covers the board" % where)
	_check_touch(panel.close_button, where)


# Menus and overlays --------------------------------------------------------------------

func _check_main_menu(window: Shape, with_puzzle: bool) -> void:
	_new_app(window)
	if with_puzzle:
		_app.start_new_puzzle(Levels.EASY)
	_app.goto(AppService.MAIN_MENU)
	var screen: Control = await _fit(window)
	var where: String = "%s, main menu%s" % [window.label, " with Continue" if with_puzzle else ""]
	var about: Button = screen.get(&"about_button") as Button
	var coffee: Button = screen.get(&"coffee_button") as Button
	_check_buttons([screen.get(&"continue_button"), screen.get(&"new_button"), screen.get(&"lessons_button"), screen.get(&"stats_button"), screen.get(&"settings_button"), about, coffee], window.safe, where)
	var stats: Button = screen.get(&"stats_button") as Button
	var lessons: Button = screen.get(&"lessons_button") as Button
	var settings: Button = screen.get(&"settings_button") as Button
	_ok(absf(_rect(lessons).position.y - _rect(stats).position.y) <= SLACK and absf(_rect(settings).position.y - _rect(about).position.y) <= SLACK, "%s: Lessons and Stats share a row, Settings and About the next" % where)
	_ok(_rect(about).position.y > _rect(stats).end.y and _rect(settings).position.x < _rect(about).position.x, "%s: Settings and About under Lessons and Stats, About at the right" % where)
	var content_end: float = window.safe.grow(-_skin.page_margin).end.x
	for button: Button in [stats, about]:
		_ok(_rect(button).end.x <= content_end + SLACK, "%s: %s ends at %.0f inside the content box %.0f" % [where, button.name, _rect(button).end.x, content_end])
	for button: Button in [lessons, stats, settings, about]:
		_ok(button.get_combined_minimum_size().x <= _rect(button).size.x + SLACK, "%s: %s %.0f wide holds its label (needs %.0f)" % [where, button.name, _rect(button).size.x, button.get_combined_minimum_size().x])
	_check_coffee(coffee, about, screen.find_child("Hero", true, false) as Control, window, where)
	_check_halves(screen.get(&"halves") as HalvesBox, window, where)
	var wordmark: Control = screen.find_child("Wordmark", true, false) as Control
	_ok(_inside(_rect(wordmark), window.safe), "%s: the wordmark inside the safe rect" % where)


## Buy me a coffee (GDD 15.7): a 40 dp face in a touch area inside the
## safe rect. Stacked it sits under last; side by side under first_part (the
## hero or the paused time) and left of last. With first_part null it sits
## under last in both arrangements.
func _check_coffee(coffee: Button, last: Button, first_part: Control, window: Shape, where: String) -> void:
	var touch: Rect2 = _touch(coffee)
	_ok(_inside(touch, window.safe), "%s: the coffee touch area %s inside the safe rect" % [where, touch])
	_ok(absf(_rect(coffee).size.y - Layout.ICON_FACE) <= SLACK, "%s: the coffee face %.1f is 40 dp" % [where, _rect(coffee).size.y])
	if first_part != null and window.expected == Layout.Arrangement.SIDE:
		_ok(touch.position.y >= _rect(first_part).end.y - SLACK and touch.end.x <= _rect(last).position.x, "%s: Buy me a coffee under %s, left of the buttons" % [where, first_part.name])
	else:
		_ok(touch.position.y >= _rect(last).end.y - SLACK, "%s: Buy me a coffee under %s" % [where, last.name])


## The title screen (7.15): PLAY, MENU, INFO, ABOUT and Buy me a coffee,
## the wordmark and hero. Stacked, Buy me a coffee sits under ABOUT; side by
## side, under the hero in the left half.
func _check_title(window: Shape) -> void:
	_new_app(window)
	_ok(_app.current_screen() == AppService.TITLE, "%s: the app opens on the title screen" % window.label)
	var screen: Control = await _fit(window)
	var where: String = "%s, title" % window.label
	var about: Button = screen.get(&"about_button") as Button
	var coffee: Button = screen.get(&"coffee_button") as Button
	_check_buttons([screen.get(&"play_button"), screen.get(&"menu_button"), screen.get(&"info_button"), about, coffee], window.safe, where)
	var coffee_touch: Rect2 = _touch(coffee)
	_ok(_inside(coffee_touch, window.safe), "%s: the coffee touch area %s inside the safe rect" % [where, coffee_touch])
	_ok(absf(_rect(coffee).size.y - Layout.ICON_FACE) <= SLACK, "%s: the coffee face %.1f is 40 dp, shorter than ABOUT" % [where, _rect(coffee).size.y])
	_ok(_rect(coffee).size.x < _rect(about).size.x - SLACK, "%s: the coffee face is narrower than ABOUT" % where)
	var hero: Rect2 = _rect(screen.find_child("Hero", true, false) as Control)
	if window.expected == Layout.Arrangement.SIDE:
		_ok(coffee_touch.position.y >= hero.end.y - SLACK and coffee_touch.end.x <= _rect(about).position.x, "%s: Buy me a coffee under the hero, left of the buttons" % where)
	else:
		_ok(coffee_touch.position.y >= _rect(about).end.y - SLACK, "%s: Buy me a coffee under ABOUT" % where)
	_check_halves(screen.get(&"halves") as HalvesBox, window, where)
	var wordmark: Control = screen.find_child("Wordmark", true, false) as Control
	_ok(_inside(_rect(wordmark), window.safe), "%s: the wordmark inside the safe rect" % where)


func _check_first_launch(window: Shape) -> void:
	_new_app(window)
	_app.goto(AppService.FIRST_LAUNCH)
	var screen: Control = await _fit(window)
	var where: String = "%s, first launch" % window.label
	_check_buttons([screen.get(&"start_button"), screen.get(&"skip_button")], window.safe, where)
	_check_halves(screen.get(&"halves") as HalvesBox, window, where)
	var card: Rect2 = _rect(screen.find_child("Offer", true, false) as Control)
	_ok(_inside(card, window.safe), "%s: the card %s inside the safe rect" % [where, card])


func _check_pause(window: Shape) -> void:
	_new_app(window)
	_app.start_new_puzzle(Levels.HARD)
	var screen: Control = await _fit(window)
	screen.call(&"show_pause")
	await _settle(screen)
	var pause: PauseMenu = screen.get(&"pause_menu") as PauseMenu
	var where: String = "%s, pause menu" % window.label
	_check_buttons([pause.resume_button, pause.settings_button, pause.menu_button, pause.about_button, pause.coffee_button], window.safe, where)
	_ok(_rect(pause.about_button).position.y > _rect(pause.menu_button).end.y, "%s: About under Menu" % where)
	_check_coffee(pause.coffee_button, pause.about_button, pause.time_label, window, where)
	_check_halves(pause.halves, window, where)
	for control: Control in [pause.time_label, pause.level_box]:
		_ok(_inside(_rect(control), window.safe), "%s: %s inside the safe rect" % [where, control.name])


func _completion_result() -> CompletionResult:
	var result: CompletionResult = CompletionResult.new()
	result.level = Levels.EXPERT
	result.seconds = 3725
	result.points_after_hints = 1000
	result.time_bonus = 400
	result.final_score = 1400
	result.hints_used = 5
	result.new_best = Stats.NEW_BEST_TIME | Stats.NEW_BEST_SCORE
	return result


func _check_completion(window: Shape) -> void:
	_new_app(window)
	_app.goto(AppService.COMPLETION, _completion_result())
	var screen: Control = await _fit(window)
	var where: String = "%s, completion" % window.label
	var play_again: Button = screen.get(&"play_again_button") as Button
	var menu: Button = screen.get(&"menu_button") as Button
	var coffee: Button = screen.get(&"coffee_button") as Button
	_check_buttons([play_again, menu, coffee], window.safe, where)
	_check_coffee(coffee, play_again, null, window, where)
	_check_halves(screen.get(&"halves") as HalvesBox, window, where)
	var scroll: ScrollContainer = screen.get(&"receipt_scroll") as ScrollContainer
	var shown: Rect2 = _rect(scroll)
	_ok(_inside(shown, window.safe), "%s: the receipt %s inside the safe rect" % [where, shown])
	_ok(shown.end.y <= _rect(play_again).position.y + SLACK, "%s: the receipt sits above the buttons" % where)
	var content: Rect2 = window.safe.grow(-_skin.page_margin)
	_ok(_touch(coffee).end.y >= content.end.y - 1.0, "%s: Buy me a coffee is pinned at the bottom, the buttons right above it" % where)
	var receipt: Control = screen.find_child("Receipt", true, false) as Control
	if window.expected == Layout.Arrangement.SIDE:
		_ok(scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "%s: the receipt scrolls side by side" % where)
	else:
		_ok(scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "%s: stacked the receipt keeps its size" % where)
		_ok(shown.size.y >= receipt.get_combined_minimum_size().y - SLACK, "%s: the whole receipt shows" % where)
	var burst: Rect2 = _rect(screen.find_child("Starburst", true, false) as Control)
	_ok(_inside(burst, window.safe), "%s: the starburst inside the safe rect" % where)
	_ok(not _overlap(burst, shown), "%s: the starburst stays off the receipt" % where)


## Level select, stats and settings: one scrolling column with the title row
## fixed, in either arrangement.
func _check_lists(window: Shape) -> void:
	for screen_id: StringName in [AppService.LEVEL_SELECT, AppService.STATS, AppService.SETTINGS, AppService.INFO, AppService.ABOUT]:
		_new_app(window)
		_app.goto(screen_id)
		var screen: Control = await _fit(window)
		if screen.has_method(&"build_all_notices"):
			screen.call(&"build_all_notices")
			await _settle(screen)
		var where: String = "%s, %s" % [window.label, screen_id]
		var scroll: ScrollContainer = _first_scroll(screen)
		_ok(scroll != null, "%s: the list scrolls" % where)
		if scroll != null:
			var rect: Rect2 = _rect(scroll)
			_ok(_inside(rect, window.safe), "%s: the list %s inside the safe rect" % [where, rect])
			_ok(rect.size.x <= Layout.COLUMN_MAX + SLACK, "%s: one column at most 600 wide" % where)
			var list: Control = scroll.get_child(0) as Control
			_ok(list.size.x <= rect.size.x + SLACK, "%s: the list %.0f is no wider than its scroll %.0f" % [where, list.size.x, rect.size.x])
		if screen_id == AppService.SETTINGS:
			await _check_settings_end(screen, window, where)
		var back: Control = screen.find_child("Back", true, false) as Control
		_ok(back != null and _inside(_rect(back), window.safe), "%s: the title row's Back inside the safe rect" % where)
		if back != null:
			_ok(_rect(back).size.y >= Layout.TOUCH_MIN - SLACK and _rect(back).size.x >= Layout.TOUCH_MIN - SLACK, "%s: Back is 48 by 48" % where)


## Settings ends with Reset stats, About and Buy me a coffee (GDD 15.7):
## scrolled to the end, all three show inside the list, in that order, none
## on another, each with a 48 dp touch area.
func _check_settings_end(screen: Control, window: Shape, where: String) -> void:
	var scroll: ScrollContainer = _first_scroll(screen)
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await _settle(screen)
	var reset: Button = screen.get(&"reset_button") as Button
	var about: Button = screen.get(&"about_button") as Button
	var coffee: Button = screen.get(&"coffee_button") as Button
	_check_buttons([reset, about, coffee], _rect(scroll), where + " scrolled to the end")
	_ok(_rect(about).position.y >= _rect(reset).end.y + _skin.shadow_offset - SLACK, "%s: About under Reset stats and its shadow" % where)
	_check_coffee(coffee, about, null, window, where)


func _first_scroll(node: Node) -> ScrollContainer:
	if node is ScrollContainer:
		return node as ScrollContainer
	for child: Node in node.get_children():
		var found: ScrollContainer = _first_scroll(child)
		if found != null:
			return found
	return null


# Dialogs --------------------------------------------------------------------------------

## The new puzzle confirm (7.4), the tallest dialog, on the level select.
func _check_dialog(window: Shape) -> void:
	_new_app(window)
	_app.start_new_puzzle(Levels.MEDIUM)
	_app.goto(AppService.MAIN_MENU)
	_app.goto(AppService.LEVEL_SELECT)
	var screen: Control = await _fit(window)
	screen.call(&"choose", Levels.EXPERT)
	await _settle(screen)
	var dialog: ConfirmDialog = screen.get(&"confirm") as ConfirmDialog
	var where: String = "%s, confirm dialog" % window.label
	_check_one_dialog(dialog, window, where)
	_ok(not dialog.is_capped(), "%s: the 7.4 text fits without scrolling" % where)


func _check_one_dialog(dialog: ConfirmDialog, window: Shape, where: String) -> void:
	var card: Rect2 = _rect(dialog.card)
	var content: Rect2 = window.safe.grow(-_skin.page_margin)
	_ok(dialog.is_open(), "%s: open" % where)
	_ok(card.size.y <= content.size.y + SLACK, "%s: the card %.0f is no taller than the content box %.0f" % [where, card.size.y, content.size.y])
	_ok(card.size.x <= UiSizes.DIALOG_MAX_W + SLACK, "%s: at most 328 wide" % where)
	_ok(_inside(card, window.safe), "%s: the card %s inside the safe rect" % [where, card])
	_check_buttons([dialog.cancel_button, dialog.confirm_button], window.safe, where)
	for button: Button in [dialog.cancel_button, dialog.confirm_button]:
		_ok(_inside(_rect(button), card), "%s: %s on the card" % [where, button.name])
	var text: Rect2 = _rect(dialog.body_scroll)
	_ok(_inside(text, card), "%s: the text %s on the card %s" % [where, text, card])
	_ok(not _overlap(text, _rect(dialog.cancel_button)), "%s: the text stays above the buttons" % where)


## A text far too long for the smallest side by side window scrolls, and
## the card and its buttons stay inside the content box.
func _check_capped_dialog() -> void:
	var window: Shape = _shape("smallest side by side 583 x 280", 583.0, 280.0, 0.0, 0.0, Layout.Arrangement.SIDE)
	_new_app(window)
	_app.start_new_puzzle(Levels.MEDIUM)
	_app.goto(AppService.MAIN_MENU)
	_app.goto(AppService.LEVEL_SELECT)
	var screen: Control = await _fit(window)
	screen.call(&"choose", Levels.EXPERT)
	var dialog: ConfirmDialog = screen.get(&"confirm") as ConfirmDialog
	UiKit.set_text(dialog.body, "This is a long question that goes on. ".repeat(30))
	await _settle(screen)
	var where: String = "%s, long dialog" % window.label
	_check_one_dialog(dialog, window, where)
	_ok(dialog.is_capped(), "%s: the text scrolls" % where)
