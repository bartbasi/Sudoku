extends "res://tests/unit_test.gd"
## The Phase 4 fit fixes (DESIGN_SYSTEM.md 3.6, 7.1, 7.5, 7.6) and making a
## puzzle (7.14): the header row stays 48 dp, Continue holds two lines that
## follow its face, the hint panel steps its text down to fit, and the
## making a puzzle overlay blocks taps at once, shows its card only after
## MAKING_DELAY and keeps it up for MAKING_MIN.

const Fx := preload("res://tests/save/save_fixtures.gd")
const MainMenuScript := preload("res://src/ui/main_menu.gd")
const GeneratingOverlay := preload("res://src/ui/generating_overlay.gd")
const PopBox := preload("res://src/design/pop_box.gd")
const SKIN_IDS: Array[StringName] = [&"pop_light", &"pop_dark"]
const LONG_TEXT: String = "The middle cell is 3 or 7, so one of the other two marked cells must be 5. Cross 5 out in cells that see both."
const SHORT_TEXT: String = "This cell is 5."

var _hosts: Array[Control] = []
var _dirs: Array[String] = []


func _skin(skin_id: StringName) -> GameSkin:
	return load("res://src/skins/%s.tres" % skin_id) as GameSkin


## A themed host under the root, as the main scene makes it.
func _host(skin: GameSkin, host_size: Vector2 = Vector2(360, 800)) -> Control:
	var host: Control = Control.new()
	host.theme = ThemeFactory.build(skin)
	host.size = host_size
	(Engine.get_main_loop() as SceneTree).root.add_child(host)
	_hosts.append(host)
	return host


func _free_all() -> void:
	for host: Control in _hosts:
		if is_instance_valid(host):
			host.get_parent().remove_child(host)
			host.free()
	_hosts.clear()
	for dir: String in _dirs:
		Fx.wipe(dir)
	_dirs.clear()


## Unit tests run before the root enters the tree, so Godot sends no
## THEME_CHANGED: deliver it to node and everything under it, so every
## control measures with the host's Theme.
func _theme(node: Node) -> void:
	if node is Control:
		node.notification(Control.NOTIFICATION_THEME_CHANGED)
	for child: Node in node.get_children():
		_theme(child)


## Lays out node and every container under it now, top down, as the next
## frame would.
func _sort(node: Node) -> void:
	if node is Container:
		node.notification(Container.NOTIFICATION_SORT_CHILDREN)
	for child: Node in node.get_children():
		_sort(child)


# Header row (7.5) -----------------------------------------------------------------

func test_header_row_is_48_with_40_dp_faces() -> void:
	for skin_id: StringName in SKIN_IDS:
		var skin: GameSkin = _skin(skin_id)
		var host: Control = _host(skin)
		var hud: PlayHud = PlayHud.new()
		host.add_child(hud)
		hud.setup(skin)
		hud.time_value.text = "9:59:59"
		hud.score_value.text = "1000"
		_theme(hud)
		for block: PanelContainer in [hud.get_node(^"Time") as PanelContainer, hud.score_block]:
			assert_eq(block.custom_minimum_size.y, Layout.ICON_FACE, "%s face height in %s" % [block.name, skin_id])
			var lines: VBoxContainer = block.get_child(0) as VBoxContainer
			assert_eq(lines.alignment, BoxContainer.ALIGNMENT_CENTER, "%s lines centered" % block.name)
			# What the block needs: its margins and its two lines.
			var need: float = block.get_theme_stylebox(&"panel").get_minimum_size().y
			for label: Node in lines.get_children():
				need += (label as Label).get_minimum_size().y
			assert_true(need <= Layout.ICON_FACE, "%s needs %.0f of its 40 dp face in %s" % [block.name, need, skin_id])
		assert_eq(hud.hint_button.custom_minimum_size.y, Layout.ICON_FACE, "Hint face height")
		assert_true(hud.hint_button.get_minimum_size().y <= Layout.ICON_FACE, "Hint needs no more than its face")
		assert_eq(hud.custom_minimum_size.y, Layout.HEADER_ROW, "header row 48")
		for touch: Control in [hud.hint_touch, hud.pause_touch]:
			assert_true(touch.get_minimum_size().y <= Layout.HEADER_ROW, "%s touch area fits the row" % touch.name)
	_free_all()


# Continue (7.1) -------------------------------------------------------------------

func test_continue_holds_two_lines_that_follow_the_face() -> void:
	for skin_id: StringName in SKIN_IDS:
		var host: Control = _host(_skin(skin_id))
		var button: Button = MainMenuScript.continue_button_with_lines()
		host.add_child(button)
		_theme(button)
		button.size = Vector2(340, Layout.BUTTON_TALL)
		var lines: VBoxContainer = button.get_node(^"Lines") as VBoxContainer
		UiKit.set_text(button.get_node(^"Lines/Caption") as Label, "Expert, 9:59:59")
		assert_eq(button.text, "", "no text of its own")
		assert_eq(lines.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the lines take no taps")
		assert_eq(lines.get_theme_constant(&"separation"), 0, "separation 0")
		assert_eq((lines.get_child(0) as Label).theme_type_variation, ThemeFactory.PRIMARY_LABEL)
		assert_eq((lines.get_child(1) as Label).theme_type_variation, ThemeFactory.PRIMARY_CAPTION)
		var normal: PopBox = button.get_theme_stylebox(&"normal") as PopBox
		assert_true(normal != null, "the primary button face is a PopBox")
		if normal == null:
			continue
		var need: float = normal.pad_top + normal.pad_bottom
		for label: Node in lines.get_children():
			need += (label as Label).get_minimum_size().y
		assert_true(need <= Layout.BUTTON_TALL, "the two lines need %.0f of the 56 dp face in %s" % [need, skin_id])
		assert_eq(button.custom_minimum_size.y, Layout.BUTTON_TALL, "Continue stays 56")

		button.draw.emit()
		assert_eq(lines.offset_left, normal.pad_left, "raised: left at the content margin")
		assert_eq(lines.offset_top, normal.pad_top, "raised: top at the content margin")
		assert_eq(lines.offset_right, -normal.pad_right)
		assert_eq(lines.offset_bottom, -normal.pad_bottom)

		# The press copy Motion.press puts on, fully sunk.
		var sunk: PopBox = normal.duplicate() as PopBox
		sunk.press = 1.0
		button.add_theme_stylebox_override(&"normal", sunk)
		button.draw.emit()
		assert_eq(lines.offset_left, normal.pad_left + sunk.shadow_offset, "sunk: the lines move right with the face")
		assert_eq(lines.offset_top, normal.pad_top + sunk.shadow_offset, "sunk: and down")
		assert_eq(lines.offset_right, -normal.pad_right + sunk.shadow_offset)
		assert_eq(lines.offset_bottom, -normal.pad_bottom + sunk.shadow_offset)
		button.remove_theme_stylebox_override(&"normal")
		button.draw.emit()
		assert_eq(lines.offset_top, normal.pad_top, "back up with the face")
	_free_all()


# Hint panel (7.6) -----------------------------------------------------------------

func _panel(skin: GameSkin, width: float, zone: float, text: String) -> HintPanel:
	var host: Control = _host(skin)
	var panel: HintPanel = HintPanel.new()
	panel.setup(skin)
	host.add_child(panel)
	panel.max_height = zone
	var hint: Hint = Hint.new()
	hint.technique_name = "Hidden triple"
	hint.lesson_title = "Lesson: Last empty cell"
	hint.text = text
	panel.visible = true
	UiKit.set_text(panel.tag_label, hint.technique_name)
	UiKit.set_text(panel.lesson_label, hint.lesson_title)
	UiKit.set_text(panel.text_label, hint.text)
	_theme(panel)
	panel.size = Vector2(width, 1.0)
	_sort(panel)
	panel.fit_text()
	return panel


func test_hint_panel_has_its_close_in_a_column_of_its_own() -> void:
	var skin: GameSkin = _skin(&"pop_light")
	var panel: HintPanel = _panel(skin, 340.0, 122.0, SHORT_TEXT)
	var columns: HBoxContainer = panel.get_child(0) as HBoxContainer
	assert_true(columns != null, "two columns in an HBox")
	if columns == null:
		_free_all()
		return
	assert_eq(columns.get_theme_constant(&"separation"), 0, "separation 0")
	var left: VBoxContainer = columns.get_child(0) as VBoxContainer
	assert_true(left != null and left.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "the left column expands")
	assert_eq(left.get_theme_constant(&"separation"), roundi(skin.space_xs), "space_xs under the top row")
	assert_eq(columns.get_child(1), panel.close_touch, "the close button is the right column")
	assert_eq(panel.close_touch.size_flags_vertical, Control.SIZE_SHRINK_BEGIN, "at the top")
	assert_eq(panel.close_button.custom_minimum_size, Vector2(Layout.CLOSE_FACE, Layout.CLOSE_FACE), "32 dp face")
	assert_true(panel.close_touch.get_combined_minimum_size().x >= Layout.TOUCH_MIN, "48 dp touch area")
	assert_eq(panel.text_label.get_parent(), left, "the text sits in the left column only")
	_free_all()


func test_hint_text_steps_are_the_three_body_small_variations() -> void:
	assert_eq(HintPanel.TEXT_STEPS, [ThemeFactory.BODY_SMALL, ThemeFactory.BODY_SMALL_12, ThemeFactory.BODY_SMALL_11] as Array[StringName], "largest first")
	assert_eq(HintPanel.MAX_LINES, 3)
	var skin: GameSkin = _skin(&"pop_light")
	var panel: HintPanel = _panel(skin, 300.0, 88.0, SHORT_TEXT)
	for label: Label in [panel.text_label, panel.tag_label, panel.lesson_label]:
		assert_false(label.has_theme_font_override(&"font") or label.has_theme_font_size_override(&"font_size"), "no font overrides on %s" % label.name)
	assert_true(_is_step(panel.text_label.theme_type_variation), "the text uses one of the steps")
	# With no room at all no step fits, so it ends on the smallest.
	panel.max_height = 1.0
	assert_eq(panel.text_label.theme_type_variation, ThemeFactory.BODY_SMALL_11, "the smallest when nothing fits")
	_free_all()


func _is_step(variation: StringName) -> bool:
	return HintPanel.TEXT_STEPS.has(variation)


# Making a puzzle (7.14) -------------------------------------------------------------

func _overlay(skin_id: StringName = &"pop_light") -> Control:
	var skin: GameSkin = _skin(skin_id)
	var host: Control = _host(skin)
	var overlay: Control = GeneratingOverlay.new()
	overlay.set(&"level", Levels.HARD)
	overlay.set(&"skin", skin)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(overlay)
	overlay.call(&"ensure_built")
	_theme(overlay)
	return overlay


func test_making_blocks_taps_at_once_and_draws_nothing_before_the_delay() -> void:
	var overlay: Control = _overlay()
	assert_eq(overlay.mouse_filter, Control.MOUSE_FILTER_STOP, "takes every tap from the first frame")
	assert_false(bool(overlay.call(&"is_card_shown")))
	assert_false((overlay.get_node(^"Scrim") as Control).visible, "no scrim yet")
	assert_false((overlay.get_node(^"Card") as Control).visible, "no card yet")
	overlay.call(&"step", Motion.MAKING_DELAY - 0.05)
	assert_false(bool(overlay.call(&"is_card_shown")), "nothing before MAKING_DELAY")
	assert_eq(float(overlay.call(&"hold_left")), 0.0, "a puzzle ready now opens at once")
	overlay.call(&"leave")
	assert_eq(overlay.mouse_filter, Control.MOUSE_FILTER_IGNORE, "stops taking taps when it leaves")
	_free_all()


func test_making_card_shows_after_the_delay_and_holds_its_minimum() -> void:
	for skin_id: StringName in SKIN_IDS:
		var overlay: Control = _overlay(skin_id)
		overlay.call(&"step", Motion.MAKING_DELAY)
		assert_true(bool(overlay.call(&"is_card_shown")), "the card shows at MAKING_DELAY in %s" % skin_id)
		var card: PanelContainer = overlay.get_node(^"Card") as PanelContainer
		assert_true(card.visible)
		assert_eq(card.theme_type_variation, ThemeFactory.DIALOG)
		assert_true((overlay.get_node(^"Scrim") as Control).visible, "the scrim shows")
		var sticker: Control = card.find_child("LevelSticker", true, false) as Control
		assert_true(sticker != null, "the level sticker")
		if sticker != null:
			assert_eq(UiKit.sticker_label(sticker).text, "HARD")
			assert_ne((sticker.get_node(^"Face") as Control).rotation, 0.0, "the sticker is tilted")
		var hero: Control = card.find_child("Hero", true, false) as Control
		assert_true(hero != null and hero.custom_minimum_size == Vector2(64, 64), "a 64 dp hero")
		if hero != null:
			assert_true(absf(hero.rotation) > 0.0, "the hero rocks")
		var found: bool = false
		for node: Node in card.find_children("*", "Label", true, false):
			if (node as Label).text == GeneratingOverlay.TEXT and (node as Label).theme_type_variation == ThemeFactory.BODY:
				found = true
		assert_true(found, "Making your puzzle. in BODY")
		assert_true(is_equal_approx(float(overlay.call(&"hold_left")), Motion.MAKING_MIN), "holds MAKING_MIN from when it showed")
		overlay.call(&"step", 0.25)
		assert_true(is_equal_approx(float(overlay.call(&"hold_left")), Motion.MAKING_MIN - 0.25))
		overlay.call(&"step", 1.0)
		assert_eq(float(overlay.call(&"hold_left")), 0.0, "then it may go")
		overlay.call(&"leave")
		if hero != null:
			assert_eq(hero.rotation, 0.0, "the rock stops and the hero stands straight")
		for node: Node in card.find_children("*", "BaseButton", true, false):
			fail("nothing on the card is tappable: %s" % node.name)
		_free_all()


func test_back_does_nothing_while_making_a_puzzle_and_the_card_holds_the_play_screen() -> void:
	var dir: String = Fx.fresh_dir("making")
	_dirs.append(dir)
	var app: AppService = AppService.new()
	app.save_dir = dir
	app.load_all()
	app.settings.first_launch_answered = true
	var host: Control = _host(app.current_skin())
	app.attach_host(host)
	app.goto(AppService.LEVEL_SELECT)
	app.use_thread = true
	app.start_new_puzzle(Levels.EXPERT)
	assert_true(app.is_generating(), "making a puzzle")
	var overlay: Control = null
	for child: Node in host.get_children():
		if child.get_script() == GeneratingOverlay:
			overlay = child as Control
	assert_true(overlay != null, "the overlay is up at once")
	if overlay == null:
		app.free()
		_free_all()
		return
	assert_eq(host.get_child(host.get_child_count() - 1), overlay, "on top of the screen")
	app.go_back()
	assert_eq(app.current_screen(), AppService.LEVEL_SELECT, "Back does nothing while making a puzzle")
	# The card shows, then the puzzle is ready before MAKING_MIN has passed.
	overlay.call(&"step", Motion.MAKING_DELAY)
	var waited: int = 0
	while app.get(&"_thread") != null and waited < 20000:
		OS.delay_msec(5)
		waited += 5
		app.call(&"_process", 0.0)
	assert_true(app.is_generating(), "still making while the card holds")
	assert_eq(app.current_screen(), AppService.LEVEL_SELECT, "the play screen waits for MAKING_MIN")
	app.go_back()
	assert_eq(app.current_screen(), AppService.LEVEL_SELECT, "Back still does nothing")
	overlay.call(&"step", Motion.MAKING_MIN)
	app.call(&"_process", 0.0)
	assert_false(app.is_generating(), "done")
	assert_eq(app.current_screen(), AppService.PLAY, "the play screen comes in")
	assert_true(app.session != null and app.session.level == Levels.EXPERT)
	assert_eq(overlay.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the leaving overlay takes no taps")
	app.free()
	_free_all()
