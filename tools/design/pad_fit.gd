extends SceneTree
## Proves that every number pad label fits its face (DESIGN_SYSTEM.md 3.5 and
## 4.7) on the five screens of section 4.10, with the real Theme from
## ThemeFactory and the face sizes from layout_model.gd.
##
## For each screen it builds the pad's buttons the way NumberPad does (digit
## keys, PLACE and CROSS OUT with icon and label on one line, UNDO and ERASE
## with the icon above the caption) and compares each button's own minimum
## size, with clipping off, against its face, raised and sunk (Godot uses the
## current style box). A minimum larger than the face means Godot grows the
## button past its face, or that the label is clipped.
##
##   timeout 300 godot --headless --path . --script res://tools/design/pad_fit.gd
##       checks the spec of section 3.5, laid over the real Theme in memory
##   timeout 300 godot --headless --path . --script res://tools/design/pad_fit.gd -- current
##       checks the real Theme and NumberPad's own expand_icon flag as they are now
##   timeout 300 godot --path . --script res://tools/design/pad_fit.gd -- render
##       also writes docs/design/pad-fit.png (needs a window); add current
##       for docs/design/pad-fit-current.png
##
## The HUD's Hint button and the other screen fits are checked by ui_fit.gd.
##
## Exits 1 if any label does not fit. Study code in tools/, never shipped.
## Owner: senior-graphic-designer.

const PopBox := preload("res://src/design/pop_box.gd")
const LayoutModel := preload("res://tools/design/layout_model.gd")

# The spec of DESIGN_SYSTEM.md section 3.5, in dp.
const DIGIT_TRIM: int = 6 ## pad_digit line box trimmed this much at the top and at the bottom.
const CAPTION_TRIM: int = 2 ## pad_caption line box trim.
const MODE_SIZE: int = 14
const MODE_WIDTH: float = 0.88
const MODE_TRACKING: float = 0.0
const MODE_PAD_X: float = 4.0 ## MODE_BUTTON side padding inside the outline (space_xs).
const ACTION_PAD_Y: float = 2.0 ## PAD_ACTION top and bottom padding inside the outline.
const ACTION_EXPAND_ICON: bool = true ## NumberPad: Undo and Erase fit their icon to the face.

const RENDER_SCALE: float = 3.0
const OUT_PATH: String = "res://docs/design/pad-fit.png"
const OUT_PATH_CURRENT: String = "res://docs/design/pad-fit-current.png"

var _failures: PackedStringArray = PackedStringArray()
var _frames: int = 0
var _use_spec: bool = true
var _render: bool = false
var _viewport: SubViewport = null
var _rows: Array[Array] = [] ## [label, Button, face size]
var _expand_icon: bool = ACTION_EXPAND_ICON


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_use_spec = not args.has("current")
	_render = args.has("render") and DisplayServer.get_name() != "headless"
	var skin: GameSkin = load("res://src/skins/pop_light.tres") as GameSkin
	var theme: Theme = ThemeFactory.build(skin)
	if _use_spec:
		_apply_spec(theme, skin)
	else:
		_expand_icon = _number_pad_expands_icons()
	var screens: Array[LayoutModel.Screen] = LayoutModel.screens()
	var width: float = 8.0
	var height: float = 8.0
	for screen: LayoutModel.Screen in screens:
		var layout: LayoutModel.StackLayout = LayoutModel.play(screen, skin)
		width = maxf(width, 8.0 + 3.0 * layout.key_w + 2.0 * skin.space_s + skin.group_gap + layout.action_w + 16.0)
		height += 20.0 + 3.0 * layout.key_h + 2.0 * skin.space_s + 16.0
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(ceili(width * RENDER_SCALE), ceili(height * RENDER_SCALE))
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_viewport)
	var page: ColorRect = ColorRect.new()
	page.color = skin.page_bg
	page.size = Vector2(width, height)
	page.scale = Vector2(RENDER_SCALE, RENDER_SCALE)
	page.theme = theme
	_viewport.add_child(page)
	var y: float = 8.0
	for screen: LayoutModel.Screen in screens:
		var layout: LayoutModel.StackLayout = LayoutModel.play(screen, skin)
		var title: Label = Label.new()
		title.theme_type_variation = ThemeFactory.CAPTION
		title.text = screen.label.to_upper()
		title.position = Vector2(8.0, y)
		page.add_child(title)
		y += 20.0
		_add_pad(page, screen.label, layout, skin, Vector2(8.0, y))
		y += 3.0 * layout.key_h + 2.0 * skin.space_s + 16.0


## NumberPad's own Undo and Erase flag, read from a pad built by the game code.
func _number_pad_expands_icons() -> bool:
	var pad: NumberPad = NumberPad.new()
	var expands: bool = true
	var found: int = 0
	for child: Node in pad.get_children(true):
		if child is Button and (child.name == &"Undo" or child.name == &"Erase"):
			expands = expands and (child as Button).expand_icon
			found += 1
	pad.free()
	if found != 2:
		_failures.append("NumberPad has no Undo and Erase buttons to read expand_icon from")
	return expands and found == 2


## The spec, laid over the real Theme in memory (nothing in src/ changes).
func _apply_spec(theme: Theme, skin: GameSkin) -> void:
	var digit: FontVariation = ThemeFactory.role_font(ThemeFactory.ROLE_PAD_DIGIT).duplicate() as FontVariation
	digit.spacing_top = -DIGIT_TRIM
	digit.spacing_bottom = -DIGIT_TRIM
	for type: StringName in [ThemeFactory.PAD_KEY_PLACE, ThemeFactory.PAD_KEY_CROSS]:
		theme.set_font(&"font", type, digit)
	var caption: FontVariation = ThemeFactory.role_font(ThemeFactory.ROLE_CAPTION).duplicate() as FontVariation
	caption.spacing_top = -CAPTION_TRIM
	caption.spacing_bottom = -CAPTION_TRIM
	theme.set_font(&"font", ThemeFactory.PAD_ACTION, caption)
	var mode: FontVariation = FontVariation.new()
	mode.base_font = ThemeDB.fallback_font
	mode.variation_embolden = ThemeFactory.HEAVY
	mode.spacing_glyph = roundi(MODE_TRACKING - ThemeFactory.CONDENSE_PULL * float(MODE_SIZE) * (1.0 - MODE_WIDTH))
	mode.variation_transform = Transform2D(Vector2(MODE_WIDTH, 0.0), Vector2(0.0, 1.0), Vector2.ZERO)
	theme.set_font(&"font", ThemeFactory.MODE_BUTTON, mode)
	theme.set_font_size(&"font_size", ThemeFactory.MODE_BUTTON, MODE_SIZE)
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		var box: PopBox = theme.get_stylebox(state, ThemeFactory.MODE_BUTTON) as PopBox
		box.set_padding(MODE_PAD_X + skin.outline_w, box.pad_top, MODE_PAD_X + skin.outline_w, box.pad_bottom)
		var action: PopBox = theme.get_stylebox(state, ThemeFactory.PAD_ACTION) as PopBox
		action.set_padding(action.pad_left, ACTION_PAD_Y + skin.outline_w, action.pad_right, ACTION_PAD_Y + skin.outline_w)


func _add_pad(page: Control, label: String, layout: LayoutModel.StackLayout, skin: GameSkin, origin: Vector2) -> void:
	var gap: float = skin.space_s
	var key: Vector2 = Vector2(layout.key_w, layout.key_h)
	for i: int in 9:
		var variation: StringName = ThemeFactory.PAD_KEY_CROSS if i % 2 == 1 else ThemeFactory.PAD_KEY_PLACE
		var at: Vector2 = origin + Vector2(float(i % 3) * (key.x + gap), float(i / 3) * (key.y + gap))
		_button(page, "%s digit %d" % [label, i + 1], variation, str(i + 1), &"", false, Rect2(at, key))
	var right: float = origin.x + 3.0 * key.x + 2.0 * gap + skin.group_gap
	var half: float = (layout.action_w - gap) * 0.5
	var place: Button = _button(page, "%s PLACE" % label, ThemeFactory.MODE_BUTTON, "Place", Icons.MODE_PLACE, false, Rect2(right, origin.y, layout.action_w, key.y))
	place.toggle_mode = true
	place.button_pressed = true
	_button(page, "%s CROSS OUT" % label, ThemeFactory.MODE_BUTTON, "Cross out", Icons.MODE_CROSS_OUT, false, Rect2(right, origin.y + key.y + gap, layout.action_w, key.y))
	var bottom: float = origin.y + 2.0 * (key.y + gap)
	_button(page, "%s UNDO" % label, ThemeFactory.PAD_ACTION, "Undo", Icons.UNDO, true, Rect2(right, bottom, half, key.y))
	_button(page, "%s ERASE" % label, ThemeFactory.PAD_ACTION, "Erase", Icons.ERASE, true, Rect2(right + half + gap, bottom, half, key.y))


func _button(page: Control, label: String, variation: StringName, text: String, icon: StringName, stacked: bool, face: Rect2) -> Button:
	var button: Button = Button.new()
	button.theme_type_variation = variation
	button.text = ThemeFactory.display_text(variation, text)
	if icon != &"":
		button.icon = Icons.texture(icon)
	if stacked:
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.expand_icon = _expand_icon
	button.clip_text = variation != ThemeFactory.PAD_KEY_PLACE
	page.add_child(button)
	button.position = face.position
	_rows.append([label, button, face.size])
	return button


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 2:
		for row: Array in _rows:
			(row[1] as Button).size = row[2] as Vector2
	if _frames < 5:
		return false
	_measure()
	if _render:
		var path: String = OUT_PATH if _use_spec else OUT_PATH_CURRENT
		var image: Image = _viewport.get_texture().get_image()
		var error: Error = image.save_png(ProjectSettings.globalize_path(path))
		if error != OK:
			_failures.append("could not write %s (error %d)" % [path, error])
		else:
			print("wrote %s" % path)
	var what: String = "spec of section 3.5" if _use_spec else "current Theme"
	print("")
	if _failures.is_empty():
		print("pad_fit: every pad label fits its face (%s)" % what)
		quit(0)
	else:
		for failure: String in _failures:
			print("FAIL ", failure)
		print("pad_fit: %d labels do not fit (%s)" % [_failures.size(), what])
		quit(1)
	return true


func _measure() -> void:
	print("Pad fit, dp: face, then what the label needs, raised or sunk, with clipping off")
	for row: Array in _rows:
		var button: Button = row[1]
		var face: Vector2 = row[2]
		var was_pressed: bool = button.button_pressed
		var was_toggle: bool = button.toggle_mode
		var was_clip: bool = button.clip_text
		button.toggle_mode = true
		button.clip_text = false
		var need: Vector2 = Vector2.ZERO
		for pressed: bool in [false, true]:
			button.set_pressed_no_signal(pressed)
			need = need.max(button.get_combined_minimum_size())
		button.set_pressed_no_signal(was_pressed)
		button.toggle_mode = was_toggle
		button.clip_text = was_clip
		var fits: bool = need.x <= face.x + 0.01 and need.y <= face.y + 0.01
		var label: String = row[0]
		if not label.contains("digit") or label.ends_with("digit 1") or label.ends_with("digit 2"):
			print("  %-50s face %5.1f x %4.1f  needs %3.0f x %2.0f  spare %5.1f x %4.1f  %s" % [label, face.x, face.y, need.x, need.y, face.x - need.x, face.y - need.y, "ok" if fits else "DOES NOT FIT"])
		if not fits:
			_failures.append("%s: face %.1f x %.1f, needs %.0f x %.0f" % [label, face.x, face.y, need.x, need.y])
