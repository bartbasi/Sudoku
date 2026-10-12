extends SceneTree
## Proves that the play screen's header row, the main menu's Continue button
## and the hint panel fit their design (DESIGN_SYSTEM.md 3.6, 7.1, 7.5 and
## 7.6) with the real Theme from ThemeFactory and the real screen code where
## it exists (PlayHud, HintPanel, UiKit), on the five screens of section 4.10.
##
##   timeout 300 godot --headless --path . --script res://tools/design/ui_fit.gd
##       checks the spec of section 3.6, laid over the real Theme in memory
##   timeout 300 godot --headless --path . --script res://tools/design/ui_fit.gd -- current
##       checks the real Theme and screen code as they are now
##   timeout 300 godot --path . --script res://tools/design/ui_fit.gd -- render
##       also writes docs/design/ui-fit.png (needs a window); add current
##       for docs/design/ui-fit-current.png
##
## What it checks:
## - Header row: the Hint button with every level's cost fits its 64 by 40
##   face, raised and sunk; the time block (9:59:59) and the score block
##   (1000) fit 40 dp faces; the whole row fits Layout.HEADER_ROW and the
##   column width.
## - Continue: CONTINUE over the level and time ("EXPERT, 9:59:59") fits
##   the 56 dp face and the column.
## - Hint panel: every hint text the game writes, with its tag and lesson
##   caption, fits the panel at the screen's minimum info zone in three lines
##   at most, at the largest step of body_small that fits (13, 12, 11 dp).
##
## Exits 1 if anything does not fit. Study code in tools/, never shipped.
## Owner: senior-graphic-designer.

const PopBox := preload("res://src/design/pop_box.gd")
const LayoutModel := preload("res://tools/design/layout_model.gd")
const TouchTarget := preload("res://src/ui/touch_target.gd")

# The spec of DESIGN_SYSTEM.md section 3.6, in dp.
const HUD_VALUE_TRIM: int = 4 ## hud_value line box trimmed this much at the top and at the bottom.
const HUD_PAD_Y: float = 2.0 ## HUD_TIME and HUD_SCORE padding at the top and bottom.
const HINT_PAD: float = 2.0 ## HINT_BUTTON padding on every side.
const FACE_H: float = 40.0 ## Header faces: Hint, time, score, Pause.
const CLOSE_FACE: float = 32.0
const CONTINUE_FACE: float = 56.0
const PRIMARY_LABEL: StringName = &"PrimaryLabel"
const PRIMARY_CAPTION: StringName = &"PrimaryCaption"
const BODY_SMALL_12: StringName = &"BodySmall12"
const BODY_SMALL_11: StringName = &"BodySmall11"
const MAX_LINES: int = 3

## Every hint text NextStep writes, with the longest group word and digits.
const HINT_TEXTS: Array[String] = [
	"This 5 is not right. Erase it and look again.",
	"This column has one empty cell left. It must be 5.",
	"In this column, 5 fits in only one cell. It goes here.",
	"Every digit but 5 is ruled out here, so this cell is 5.",
	"In this box, 5 can only go in one column. So cross 5 out in the rest of that column.",
	"In this column, 5 can only go in one box. So cross 5 out in the rest of that box.",
	"These two cells can only hold 5 and 7. So cross 5 and 7 out in the rest of this column.",
	"In this column, 5 and 7 can only go in these two cells. So cross out every other digit in them.",
	"These three cells can only hold 3, 5 and 7. So cross those digits out in the rest of this column.",
	"In this column, 3, 5 and 7 can only go in these three cells. So cross out every other digit in them.",
	"In these two columns, 5 can only go in the same two rows. So cross 5 out in the rest of those rows.",
	"In these three columns, 5 can only go in the same three rows. So cross 5 out in the rest of those rows.",
	"The middle cell is 3 or 7, so one of the other two marked cells must be 5. Cross 5 out in cells that see both.",
	"One of these three cells must be 5. So cross 5 out in cells that see all three.",
	"This cell is 5.",
]
const HINT_TAG_TEXT: String = "Hidden triple"
const HINT_LESSON_TEXT: String = "Lesson: Last empty cell"

const RENDER_SCALE: float = 2.0
const OUT_PATH: String = "res://docs/design/ui-fit.png"
const OUT_PATH_CURRENT: String = "res://docs/design/ui-fit-current.png"

var _failures: PackedStringArray = PackedStringArray()
var _frames: int = 0
var _use_spec: bool = true
var _render: bool = false
var _skin: GameSkin = null
var _viewport: SubViewport = null
var _page: Control = null
var _huds: Array[Array] = [] ## [screen label, PlayHud, column width]
var _continues: Array[Array] = [] ## [screen label, Button, lines (Control or null), column width]
var _panels: Array[Array] = [] ## [screen label, zone height, text index, step, panel, text Label]
var _shown_panels: Array[Array] = [] ## [screen label, zone height, panel, text Label] for the render
var _steps: Array[StringName] = []


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_use_spec = not args.has("current")
	_render = args.has("render") and DisplayServer.get_name() != "headless"
	_skin = load("res://src/skins/pop_light.tres") as GameSkin
	var theme: Theme = ThemeFactory.build(_skin)
	if _use_spec:
		_apply_spec(theme)
		_steps = [ThemeFactory.BODY_SMALL, BODY_SMALL_12, BODY_SMALL_11]
	else:
		_steps = [ThemeFactory.BODY_SMALL]

	var screens: Array[LayoutModel.Screen] = LayoutModel.screens()
	var shown: Array[LayoutModel.Screen] = [screens[0], screens[2]] ## 320 by 568 and the judged 360 by 800
	var width: float = 8.0 + 344.0 + 8.0
	var height: float = 0.0
	for screen: LayoutModel.Screen in shown:
		var layout: LayoutModel.StackLayout = LayoutModel.play(screen, _skin)
		height += 20.0 + Layout.HEADER_ROW + 12.0 + 20.0 + CONTINUE_FACE + 16.0 + 20.0 + layout.hint_panel + 16.0
	height += 8.0
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(ceili(width * RENDER_SCALE), ceili(height * RENDER_SCALE))
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_viewport)
	_page = Control.new()
	_page.size = Vector2(width, height)
	_page.scale = Vector2(RENDER_SCALE, RENDER_SCALE)
	_page.theme = theme
	_viewport.add_child(_page)
	var bg: ColorRect = ColorRect.new()
	bg.color = _skin.page_bg
	bg.size = _page.size
	_page.add_child(bg)

	# The parts shown in the render: 320 by 568 and 360 by 800.
	var y: float = 8.0
	for screen: LayoutModel.Screen in shown:
		var layout: LayoutModel.StackLayout = LayoutModel.play(screen, _skin)
		_title("%s: HEADER ROW, %d DP COLUMN" % [screen.label.to_upper(), roundi(layout.content_w)], y)
		y += 20.0
		_add_hud(screen.label, layout.content_w, Vector2(8.0, y))
		y += Layout.HEADER_ROW + 12.0
		_title("CONTINUE", y)
		y += 20.0
		_add_continue(screen.label, layout.content_w, Vector2(8.0, y))
		y += CONTINUE_FACE + 16.0
		_title("HINT PANEL AT THE INFO ZONE: %d DP, LONGEST TEXT" % roundi(layout.hint_panel), y)
		y += 20.0
		var panel: PanelContainer = _add_panel(layout.content_w, Vector2(8.0, y), HINT_TEXTS[12], _steps[0])
		_shown_panels.append([screen.label, layout.hint_panel, panel, panel.get_meta(&"text") as Label])
		y += layout.hint_panel + 16.0

	# Every screen and every text, off the render, for the measurements.
	var far: float = height + 100.0
	for screen: LayoutModel.Screen in screens:
		var layout: LayoutModel.StackLayout = LayoutModel.play(screen, _skin)
		if not shown.has(screen):
			_add_hud(screen.label, layout.content_w, Vector2(8.0, far))
			_add_continue(screen.label, layout.content_w, Vector2(8.0, far + 60.0))
		for i: int in HINT_TEXTS.size():
			for step: StringName in _steps:
				var p: PanelContainer = _add_panel(layout.content_w, Vector2(8.0, far + 140.0), HINT_TEXTS[i], step)
				_panels.append([screen.label, layout.hint_panel, i, step, p, p.get_meta(&"text") as Label])


## The spec of section 3.6, laid over the real Theme in memory (nothing in src/ changes).
func _apply_spec(theme: Theme) -> void:
	var o: float = _skin.outline_w
	var value: FontVariation = ThemeFactory.role_font(ThemeFactory.ROLE_VALUE).duplicate() as FontVariation
	value.spacing_top = -HUD_VALUE_TRIM
	value.spacing_bottom = -HUD_VALUE_TRIM
	for type: StringName in [ThemeFactory.HUD_VALUE, ThemeFactory.SCORE_VALUE]:
		theme.set_font(&"font", type, value)
	for type: StringName in [ThemeFactory.HUD_CAPTION, ThemeFactory.SCORE_CAPTION]:
		theme.set_font(&"font", type, ThemeFactory.role_font(ThemeFactory.ROLE_PAD_CAPTION))
	for type: StringName in [ThemeFactory.HUD_TIME, ThemeFactory.HUD_SCORE]:
		var box: PopBox = theme.get_stylebox(&"panel", type) as PopBox
		box.set_padding(_skin.space_s + o, HUD_PAD_Y + o, _skin.space_s + o, HUD_PAD_Y + o)
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		var hint: PopBox = theme.get_stylebox(state, ThemeFactory.HINT_BUTTON) as PopBox
		hint.set_padding(HINT_PAD + o, HINT_PAD + o, HINT_PAD + o, HINT_PAD + o)
	var panel: PopBox = theme.get_stylebox(&"panel", ThemeFactory.HINT_PANEL) as PopBox
	panel.set_padding(_skin.space_m + o, _skin.space_xs + o, _skin.space_m + o, _skin.space_xs + o)
	var body: FontVariation = ThemeFactory.role_font(ThemeFactory.ROLE_BODY_SMALL)
	_label_variation(theme, PRIMARY_LABEL, ThemeFactory.role_font(ThemeFactory.ROLE_BUTTON), ThemeFactory.role_size(ThemeFactory.ROLE_BUTTON), 1.2, _skin.button_primary_text)
	_label_variation(theme, PRIMARY_CAPTION, ThemeFactory.role_font(ThemeFactory.ROLE_CAPTION), ThemeFactory.role_size(ThemeFactory.ROLE_CAPTION), 1.2, _skin.button_primary_text)
	_label_variation(theme, BODY_SMALL_12, body, 12, 1.3, _skin.text)
	_label_variation(theme, BODY_SMALL_11, body, 11, 1.3, _skin.text)


func _label_variation(theme: Theme, type: StringName, font: Font, size: int, line_height: float, color: Color) -> void:
	theme.set_type_variation(type, &"Label")
	theme.set_font(&"font", type, font)
	theme.set_font_size(&"font_size", type, size)
	theme.set_color(&"font_color", type, color)
	theme.set_color(&"font_shadow_color", type, Color(0, 0, 0, 0))
	theme.set_constant(&"line_spacing", type, roundi(line_height * float(size) - font.get_height(size)))


func _title(text: String, y: float) -> void:
	var title: Label = Label.new()
	title.theme_type_variation = ThemeFactory.CAPTION
	title.text = text
	title.position = Vector2(8.0, y)
	_page.add_child(title)


## The HUD as PlayHud builds it, with the widest time, score and cost.
func _add_hud(label: String, column: float, origin: Vector2) -> void:
	var hud: PlayHud = PlayHud.new()
	_page.add_child(hud)
	hud.setup(_skin)
	hud.position = origin
	hud.size = Vector2(column, Layout.HEADER_ROW)
	hud.time_value.text = "9:59:59"
	hud.score_value.text = "1000"
	hud.hint_button.text = _hint_text(4)
	if _use_spec:
		# The ui-systems-dev change of section 7.5: 40 dp block faces, lines centered.
		for block: PanelContainer in [hud.get_node(^"Time") as PanelContainer, hud.score_block]:
			block.custom_minimum_size.y = FACE_H
			(block.get_child(0) as VBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
	_huds.append([label, hud, column])


func _hint_text(level: int) -> String:
	return ThemeFactory.display_text(ThemeFactory.HINT_BUTTON, "Hint\n%s%d" % [PlayHud.MINUS, Scoring.hint_cost(level)])


## Continue: as the main menu builds it now, or as section 7.1 specifies.
func _add_continue(label: String, column: float, origin: Vector2) -> void:
	var line: String = "Expert, 9:59:59"
	var button: Button = null
	var lines: VBoxContainer = null
	if _use_spec:
		button = UiKit.button(ThemeFactory.BUTTON_PRIMARY, "", CONTINUE_FACE)
		lines = UiKit.vbox(0.0)
		lines.alignment = BoxContainer.ALIGNMENT_CENTER
		lines.add_child(_centered(UiKit.label(PRIMARY_LABEL, ThemeFactory.display_text(ThemeFactory.BUTTON_PRIMARY, "Continue"))))
		lines.add_child(_centered(UiKit.label(PRIMARY_CAPTION, ThemeFactory.display_text(ThemeFactory.CAPTION, line))))
		button.add_child(lines)
	else:
		button = UiKit.button(ThemeFactory.BUTTON_PRIMARY, "Continue\n" + line, CONTINUE_FACE)
	_page.add_child(button)
	button.position = origin
	button.size = Vector2(column - _skin.shadow_offset, CONTINUE_FACE)
	if lines != null:
		# Section 7.1: the lines fill the button's content rect.
		var box: StyleBox = button.get_theme_stylebox(&"normal")
		lines.set_anchors_preset(Control.PRESET_FULL_RECT)
		lines.offset_left = box.get_margin(SIDE_LEFT)
		lines.offset_top = box.get_margin(SIDE_TOP)
		lines.offset_right = -box.get_margin(SIDE_RIGHT)
		lines.offset_bottom = -box.get_margin(SIDE_BOTTOM)
	_continues.append([label, button, lines, column])


func _centered(label: Label) -> Label:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


## A hint panel: the real HintPanel now, or the layout of section 7.6.
func _add_panel(column: float, origin: Vector2, text: String, step: StringName) -> PanelContainer:
	var panel: PanelContainer = null
	var text_label: Label = null
	if _use_spec:
		panel = UiKit.panel(ThemeFactory.HINT_PANEL)
		var row: HBoxContainer = UiKit.hbox(0.0)
		panel.add_child(row)
		var left: VBoxContainer = UiKit.vbox(_skin.space_xs)
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(left)
		var top: HBoxContainer = UiKit.hbox(_skin.space_s)
		left.add_child(top)
		var tag: PanelContainer = UiKit.panel(ThemeFactory.HINT_TAG)
		tag.add_child(UiKit.label(ThemeFactory.HINT_TAG_LABEL, HINT_TAG_TEXT))
		top.add_child(tag)
		var lesson: Label = UiKit.label(ThemeFactory.CAPTION, HINT_LESSON_TEXT)
		lesson.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lesson.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lesson.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lesson.custom_minimum_size.x = 1.0
		top.add_child(lesson)
		text_label = UiKit.label(step, text, true)
		left.add_child(text_label)
		var close: TouchTarget = UiKit.icon_button(Icons.CLOSE, CLOSE_FACE)
		close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(close)
	else:
		var hint_panel: HintPanel = HintPanel.new()
		hint_panel.setup(_skin)
		hint_panel.visible = true
		UiKit.set_text(hint_panel.tag_label, HINT_TAG_TEXT)
		UiKit.set_text(hint_panel.lesson_label, HINT_LESSON_TEXT)
		UiKit.set_text(hint_panel.text_label, text)
		text_label = hint_panel.text_label
		panel = hint_panel
	_page.add_child(panel)
	panel.position = origin
	panel.size = Vector2(column - _skin.shadow_offset, 1.0)
	panel.set_meta(&"text", text_label)
	return panel


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 4:
		_measure()
		return false
	if _frames < 8:
		return false
	if _render:
		var path: String = OUT_PATH if _use_spec else OUT_PATH_CURRENT
		var image: Image = _viewport.get_texture().get_image()
		var error: Error = image.save_png(ProjectSettings.globalize_path(path))
		if error != OK:
			_failures.append("could not write %s (error %d)" % [path, error])
		else:
			print("wrote %s" % path)
	var what: String = "spec of section 3.6" if _use_spec else "current Theme and screen code"
	print("")
	if _failures.is_empty():
		print("ui_fit: the header row, Continue and the hint panel fit (%s)" % what)
		quit(0)
	else:
		for failure: String in _failures:
			print("FAIL ", failure)
		print("ui_fit: %d things do not fit (%s)" % [_failures.size(), what])
		quit(1)
	return true


func _measure() -> void:
	print("Header row, dp (needs, then the design)")
	for row: Array in _huds:
		var label: String = row[0]
		var hud: PlayHud = row[1]
		var column: float = row[2]
		var hint: Button = hud.hint_button
		var need: Vector2 = Vector2.ZERO
		var shown: String = hint.text
		var was_toggle: bool = hint.toggle_mode
		hint.toggle_mode = true
		for level: int in range(0, 5):
			hint.text = _hint_text(level)
			for pressed: bool in [false, true]:
				hint.set_pressed_no_signal(pressed)
				need = need.max(hint.get_minimum_size()) ## its own need, without the 64 by 40 minimum PlayHud sets
		hint.set_pressed_no_signal(false)
		hint.toggle_mode = was_toggle
		hint.text = shown
		_check(label, "Hint button", need, Vector2(Layout.HINT_FACE_W, FACE_H))
		var time: Vector2 = (hud.get_node(^"Time") as Control).get_minimum_size()
		_check(label, "time block (9:59:59)", time, Vector2(INF, FACE_H))
		_check(label, "score block (1000)", hud.score_block.get_minimum_size(), Vector2(INF, FACE_H))
		_check(label, "header row", hud.get_combined_minimum_size(), Vector2(column, Layout.HEADER_ROW))

	print("Continue, dp")
	for row: Array in _continues:
		var label: String = row[0]
		var button: Button = row[1]
		var column: float = row[3]
		var need: Vector2 = button.get_minimum_size()
		if row[2] != null:
			var lines: Control = row[2]
			var box: StyleBox = button.get_theme_stylebox(&"normal")
			var margins: Vector2 = Vector2(box.get_margin(SIDE_LEFT) + box.get_margin(SIDE_RIGHT), box.get_margin(SIDE_TOP) + box.get_margin(SIDE_BOTTOM))
			need = margins + lines.get_combined_minimum_size()
		_check(label, "Continue", need, Vector2(column - _skin.shadow_offset, CONTINUE_FACE))

	print("Hint panel, dp: the largest text step that fits, worst text per screen")
	var best: Dictionary[String, Array] = {} ## screen label -> [step index, height, lines, text index] of the worst text
	var chosen: Dictionary[String, StringName] = {}
	var by_screen_text: Dictionary[String, Array] = {}
	for row: Array in _panels:
		var key: String = "%s|%d" % [row[0], row[2]]
		if not by_screen_text.has(key):
			by_screen_text[key] = []
		by_screen_text[key].append(row)
	for key: String in by_screen_text:
		var rows: Array = by_screen_text[key]
		var fitted: bool = false
		for row: Array in rows:
			var zone: float = row[1]
			var panel: PanelContainer = row[4]
			var text_label: Label = row[5]
			var h: float = panel.get_combined_minimum_size().y
			var lines: int = text_label.get_line_count()
			if h <= zone + 0.01 and lines <= MAX_LINES:
				fitted = true
				var step_i: int = _steps.find(row[3] as StringName)
				var screen: String = row[0]
				if not best.has(screen) or step_i > int(best[screen][0]) or (step_i == int(best[screen][0]) and h > float(best[screen][1])):
					best[screen] = [step_i, h, lines, row[2], zone]
				break
		if not fitted:
			var last: Array = rows[rows.size() - 1]
			_failures.append("%s: hint text %d does not fit a %.0f dp panel in %d lines at any step (%.0f dp, %d lines)" % [last[0], last[2], last[1], MAX_LINES, (last[4] as Control).get_combined_minimum_size().y, (last[5] as Label).get_line_count()])
	for screen: String in best:
		var b: Array = best[screen]
		var step: StringName = _steps[int(b[0])]
		chosen[screen] = step
		print("  %-36s panel %5.1f  smallest step used %-12s worst text %2d: %3.0f tall, %d lines  ok" % [screen, float(b[4]), step, int(b[3]), float(b[1]), int(b[2])])
	# The render shows the longest text at the step the rule picks for it.
	for row: Array in _shown_panels:
		for p: Array in _panels:
			if p[0] == row[0] and int(p[2]) == 12:
				var h: float = (p[4] as Control).get_combined_minimum_size().y
				if h <= float(p[1]) + 0.01 and (p[5] as Label).get_line_count() <= MAX_LINES:
					(row[3] as Label).theme_type_variation = p[3]
					break


func _check(screen: String, what: String, need: Vector2, face: Vector2) -> void:
	var fits: bool = need.x <= face.x + 0.01 and need.y <= face.y + 0.01
	var face_text: String = ("%5.1f" % face.x if face.x < INF else "  any") + " x %4.1f" % face.y
	print("  %-36s %-22s needs %5.1f x %4.1f  design %s  %s" % [screen, what, need.x, need.y, face_text, "ok" if fits else "DOES NOT FIT"])
	if not fits:
		_failures.append("%s %s: needs %.1f x %.1f, design %s" % [screen, what, need.x, need.y, face_text])
