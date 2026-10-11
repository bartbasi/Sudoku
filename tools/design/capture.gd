extends SceneTree
## Screenshot capture for the Phase 1 design directions.
##
## Renders each screen into a SubViewport of exactly 1080 by 2400, so the
## window size does not matter, and saves PNGs to docs/design/. Headless mode
## has no renderer, so run it with a window:
##
##   timeout 300 godot --path . --script res://tools/design/capture.gd
##   timeout 300 godot --path . --script res://tools/design/capture.gd -- placeholder
##   timeout 300 godot --path . --script res://tools/design/capture.gd -- screens rings --direction=pebble --font=inter
##
## Targets (any number; default: screens place states rings icon):
##   screens      <direction>-<screen>.png for play, lesson, stats, complete,
##                plus <direction>-play-dark.png (15 files for 3 directions)
##   place        <direction>-play-place.png: play with the pad and the
##                selected cell in Place mode (the screens show Cross Out)
##   states       <direction>-states.png and <direction>-states-dark.png
##                (1080 by 2720, two boards at true size)
##   rings        ring-<layout>.png at true size on a 1080 px phone,
##                ring-<layout>-small.png at true size on a 720 px phone (the
##                smallest we support), ring-<layout>-small-x3.png enlarged
##   compare      the font comparison set for one direction (needs
##                --direction): its five screens, and ring-<layout>-<direction>-
##                small.png plus -small-x3.png, that direction alone at true
##                size on a 720 px phone. Run it once with the default font and
##                once with --font=inter; the Inter twin of every file has the
##                same name with "-inter" before ".png"
##   icon         app-icon-512.png, app-icon-48.png, and the adaptive layers
##                with the safe zone drawn on: app-icon-adaptive-432.png,
##                app-icon-monochrome-432.png
##   placeholder  placeholder.png and placeholder-dark.png from this tool's
##                own test scene, and placeholder-icon-* from a stub icon, to
##                prove the icon path. Written to user://capture_test/ (Godot's
##                user data folder, outside the repo), never to docs/.
## Options:
##   --direction=<slug>  only that direction (screens and states)
##   --font=inter        draw with Inter from build/font_compare/ (loaded with
##                       FileAccess and FontFile.data, never imported); every
##                       file name gets "-inter" before ".png"
##
## The scene contracts (paths, root node, properties) are defined in
## docs/design/briefs/. Exits with 1 if any capture is missing or failed.
## Owner: senior-graphic-designer.

const Palettes := preload("res://tools/design/directions/palettes.gd")
const RingLayouts := preload("res://tools/design/directions/ring_layouts.gd")
const Fonts := preload("res://tools/design/directions/fonts.gd")
const Device := preload("res://tools/design/directions/device.gd")
const SampleState := preload("res://tools/design/directions/sample_state.gd")

const OUT_DIR: String = "res://docs/design/"
## The tool's own test output stays out of the repo.
const TEST_OUT_DIR: String = "user://capture_test/"
const SCREENS: Array[String] = ["play", "lesson", "stats", "complete"]
const SCREEN_PATH: String = "res://tools/design/directions/ui/%s/%s.tscn"
const STATE_SHEET_PATH: String = "res://tools/design/directions/board/state_sheet.tscn"
const RING_CLOSEUP_PATH: String = "res://tools/design/directions/board/ring_closeup.tscn"
const APP_ICON_PATH: String = "res://src/design/app_icon.gd"
const PLACEHOLDER_PATH: String = "res://tools/design/placeholder/placeholder_screen.tscn"
const PLACEHOLDER_ICON_PATH: String = "res://tools/design/placeholder/placeholder_icon.gd"

## The state sheet holds two boards at true size with their notes, so it is
## taller than a phone screen. Pebble's sheet is the tallest (about 2710).
const STATE_SHEET_SIZE: Vector2i = Vector2i(1080, 2720)

const DEFAULT_TARGETS: Array[String] = ["screens", "place", "states", "rings", "icon"]
const ALL_TARGETS: Array[String] = ["screens", "place", "states", "rings", "compare", "icon", "placeholder"]

## The font comparison's single-direction ring close-ups: the same crop as
## the ring close-up sheet (ring_closeup.gd), light and dark side by side.
const BOARD_PATH: String = "res://tools/design/directions/board/%s/board.tscn"
const CLOSEUP_CROP_GROW: float = 12.0 ## Design units around the close-up box.
const SHEET_MARGIN: float = 24.0 ## Pixels.
const SHEET_LINE: float = 40.0 ## Line pitch of the titles, in pixels, the same for every font.
const SHEET_LABEL_DIRECTION: String = "gridline" ## Titles in Gridline light, like the other close-ups.
const FAMILY_NAMES: Dictionary[String, String] = {"default": "Godot default font", "inter": "Inter"}

## The play screen's pad_mode for the place target (SampleState.MODE_PLACE).
const MODE_PLACE: int = 0

## Adaptive icon geometry (Android): 108 dp layers, 66 dp safe zone circle,
## 72 dp visible area.
const ICON_LAYER_PX: int = 432
const SAFE_ZONE_SHARE: float = 66.0 / 108.0
const VISIBLE_SHARE: float = 72.0 / 108.0
## Review guides drawn on the icon previews only. Not part of any design.
const GUIDE_COLOR: Color = Color(1.0, 0.0, 1.0, 0.9)
const PREVIEW_BACKDROP: Color = Color(0.24, 0.24, 0.24, 1.0)

var _suffix: String = ""
var _out_dir: String = OUT_DIR
var _written: PackedStringArray = PackedStringArray()
var _problems: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_run()


func _run() -> void:
	var targets: Array[String] = []
	var direction_filter: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--direction="):
			direction_filter = arg.trim_prefix("--direction=")
		elif arg.begins_with("--font="):
			var family: String = arg.trim_prefix("--font=")
			if not Fonts.set_family(family):
				_problems.append("could not switch the font to %s" % family)
			elif family != Fonts.FAMILY_DEFAULT:
				_suffix = "-" + family
				# Safety net: any text that misses Fonts still gets the family.
				ThemeDB.fallback_font = Fonts.get_font(Fonts.Weight.SEMIBOLD)
		elif ALL_TARGETS.has(arg):
			targets.append(arg)
		else:
			_problems.append("unknown argument: %s" % arg)
	if targets.is_empty():
		targets = DEFAULT_TARGETS.duplicate()
	var directions: Array[String] = []
	for slug: String in Palettes.DIRECTIONS:
		if direction_filter.is_empty() or slug == direction_filter:
			directions.append(slug)
	if directions.is_empty():
		_problems.append("unknown direction: %s" % direction_filter)

	if _problems.is_empty():
		if targets.has("placeholder"):
			await _capture_placeholder()
		if targets.has("screens"):
			await _capture_screens(directions)
		if targets.has("place"):
			for direction: String in directions:
				await _capture_screen(direction, "play", false, MODE_PLACE)
		if targets.has("states"):
			await _capture_states(directions)
		if targets.has("rings"):
			await _capture_rings()
		if targets.has("compare"):
			if directions.size() != 1:
				_problems.append("compare needs one direction: add --direction=<slug>")
			else:
				await _capture_compare(directions[0])
		if targets.has("icon"):
			await _capture_icon(APP_ICON_PATH, "app-icon")

	print("")
	for path: String in _written:
		print("wrote    %s" % path)
	for problem: String in _problems:
		print("PROBLEM  %s" % problem)
	print("Captured %d file(s), %d problem(s). Font: %s." % [_written.size(), _problems.size(), Fonts.family()])
	quit(0 if _problems.is_empty() else 1)


# Targets

func _capture_placeholder() -> void:
	_out_dir = TEST_OUT_DIR
	for dark: bool in [false, true]:
		var node: Control = _instance(PLACEHOLDER_PATH)
		if node == null or not _set_props(node, PLACEHOLDER_PATH, {"dark": dark, "ring_layout": RingLayouts.DEFAULT_LAYOUT}):
			_out_dir = OUT_DIR
			return
		var image: Image = await _render(node, Device.SCREEN_SIZE, false)
		_save(image, "placeholder%s" % ("-dark" if dark else ""))
	await _capture_icon(PLACEHOLDER_ICON_PATH, "placeholder-icon")
	_out_dir = OUT_DIR


func _capture_screens(directions: Array[String]) -> void:
	for direction: String in directions:
		for screen: String in SCREENS:
			await _capture_screen(direction, screen, false)
		await _capture_screen(direction, "play", true)


## pad_mode -1 leaves the screen's own mode (Cross Out on play and lesson).
func _capture_screen(direction: String, screen: String, dark: bool, pad_mode: int = -1) -> void:
	var path: String = SCREEN_PATH % [direction, screen]
	var node: Control = _instance(path)
	var props: Dictionary = {"dark": dark, "ring_layout": RingLayouts.DEFAULT_LAYOUT}
	if pad_mode >= 0:
		props["pad_mode"] = pad_mode
	if node == null or not _set_props(node, path, props):
		return
	var image: Image = await _render(node, Device.SCREEN_SIZE, false)
	_save(image, "%s-%s%s%s" % [direction, screen, "-dark" if dark else "", "-place" if pad_mode == MODE_PLACE else ""])


func _capture_states(directions: Array[String]) -> void:
	for direction: String in directions:
		for dark: bool in [false, true]:
			var node: Control = _instance(STATE_SHEET_PATH)
			if node == null or not _set_props(node, STATE_SHEET_PATH, {"direction": direction, "dark": dark, "ring_layout": RingLayouts.DEFAULT_LAYOUT}):
				return
			var image: Image = await _render(node, STATE_SHEET_SIZE, false)
			_save(image, "%s-states%s" % [direction, "-dark" if dark else ""])


func _capture_rings() -> void:
	var small: float = Device.SMALLEST_PHONE_PX_WIDTH / float(Device.SCREEN_SIZE.x)
	for layout: int in RingLayouts.COUNT:
		for px_per_unit: float in [1.0, small]:
			var node: Control = _instance(RING_CLOSEUP_PATH)
			if node == null or not _set_props(node, RING_CLOSEUP_PATH, {"ring_layout": layout, "px_per_unit": px_per_unit}):
				return
			if not node.has_method("sheet_size"):
				_problems.append("%s: root script has no sheet_size() method" % RING_CLOSEUP_PATH)
				node.free()
				return
			var sheet: Vector2i = node.call("sheet_size")
			if sheet.x <= 0 or sheet.y <= 0 or sheet.x > 4096 or sheet.y > 4096:
				_problems.append("%s: sheet_size() returned %s" % [RING_CLOSEUP_PATH, sheet])
				node.free()
				return
			var image: Image = await _render(node, sheet, false)
			var base: String = "ring-%s%s" % [RingLayouts.SLUGS[layout], "" if px_per_unit == 1.0 else "-small"]
			_save(image, base)
			if px_per_unit != 1.0:
				var big: Image = image.duplicate()
				big.resize(image.get_width() * 3, image.get_height() * 3, Image.INTERPOLATE_NEAREST)
				_save(big, base + "-x3")


## The font comparison set for one direction: its five screens, and its ring
## close-ups on their own at true size on the smallest phone, plain and x3.
func _capture_compare(direction: String) -> void:
	var only: Array[String] = [direction]
	await _capture_screens(only)
	var px_per_unit: float = Device.SMALLEST_PHONE_PX_WIDTH / float(Device.SCREEN_SIZE.x)
	for layout: int in RingLayouts.COUNT:
		var sheet: Control = _direction_closeup(direction, layout, px_per_unit)
		var image: Image = await _render(sheet, Vector2i(sheet.size), false)
		var base: String = "ring-%s-%s-small" % [RingLayouts.SLUGS[layout], direction]
		_save(image, base)
		var big: Image = image.duplicate()
		big.resize(image.get_width() * 3, image.get_height() * 3, Image.INTERPOLATE_NEAREST)
		_save(big, base + "-x3")


## One direction's close-up box, light and dark side by side, drawn by its
## board scene at true size (board_size * px_per_unit) and cropped like
## ring_closeup.gd, under three short title lines: the layout, the direction
## and phone, and the font. Line pitch and width do not depend on the font,
## so the default font and Inter versions line up pixel for pixel. Its size is
## set before it is rendered.
func _direction_closeup(direction: String, layout: int, px_per_unit: float) -> Control:
	var style: Palettes.TypeStyle = Palettes.type_style(SHEET_LABEL_DIRECTION, Palettes.ROLE_LABEL)
	var paper: Palettes.Palette = Palettes.palette(SHEET_LABEL_DIRECTION, false)
	var font: Font = style.font()
	var font_size: int = style.font_size()
	var line_height: float = SHEET_LINE
	var ascent: float = roundf(SHEET_LINE * 0.75)
	var side: float = Palettes.shape(direction).board_size * px_per_unit
	var box: Rect2 = RingLayouts.box_rect(direction, Rect2(Vector2.ZERO, Vector2(side, side)), SampleState.CLOSEUP_BOX).grow(CLOSEUP_CROP_GROW * px_per_unit)
	var crop: Rect2 = Rect2(box.position.floor(), box.end.ceil() - box.position.floor())
	var phone_px: int = roundi(px_per_unit * float(Device.SCREEN_SIZE.x))
	var lines: Array[String] = [
		style.apply(RingLayouts.NAMES[layout]),
		style.apply("%s, %d px phone" % [Palettes.DIRECTION_NAMES[direction], phone_px]),
		style.apply(FAMILY_NAMES.get(Fonts.family(), Fonts.family())),
	]
	var labels: Array[String] = [style.apply("Light"), style.apply("Dark")]
	var tiles_y: float = SHEET_MARGIN + line_height * float(lines.size()) + SHEET_MARGIN + line_height
	var width: float = 2.0 * crop.size.x + 3.0 * SHEET_MARGIN
	for line: String in lines:
		if font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width - 2.0 * SHEET_MARGIN:
			_problems.append("close-up title line too wide for the sheet: %s" % line)
	var sheet: Control = Control.new()
	sheet.size = Vector2(ceilf(width), ceilf(tiles_y + crop.size.y + SHEET_MARGIN))
	for column: int in 2:
		var x: float = SHEET_MARGIN + float(column) * (crop.size.x + SHEET_MARGIN)
		var tile: ColorRect = ColorRect.new()
		tile.color = Palettes.palette(direction, column == 1).app_bg
		tile.clip_contents = true
		tile.position = Vector2(x, tiles_y)
		tile.size = crop.size
		sheet.add_child(tile)
		var board: Control = (load(BOARD_PATH % direction) as PackedScene).instantiate() as Control
		board.set("dark", column == 1)
		board.set("ring_layout", layout)
		board.set("state", SampleState.closeup_board())
		board.position = -crop.position
		board.size = Vector2(side, side)
		tile.add_child(board)
	sheet.draw.connect(func() -> void:
		sheet.draw_rect(Rect2(Vector2.ZERO, sheet.size), paper.app_bg)
		for n: int in lines.size():
			sheet.draw_string(font, Vector2(SHEET_MARGIN, SHEET_MARGIN + line_height * float(n) + ascent), lines[n], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, paper.text)
		for column: int in 2:
			var x: float = SHEET_MARGIN + float(column) * (crop.size.x + SHEET_MARGIN)
			sheet.draw_string(font, Vector2(x, tiles_y - line_height + ascent), labels[column], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, paper.text)
	)
	return sheet


func _capture_icon(script_path: String, prefix: String) -> void:
	if not ResourceLoader.exists(script_path):
		_problems.append("missing %s" % script_path)
		return
	var script: GDScript = load(script_path) as GDScript
	if script == null or not script.can_instantiate():
		_problems.append("%s does not load" % script_path)
		return
	var icon: Object = script.new()
	for method: String in ["draw_full", "draw_background", "draw_foreground", "draw_monochrome"]:
		if not icon.has_method(method):
			_problems.append("%s has no %s(canvas, rect)" % [script_path, method])
			return
	for px: int in [512, 48]:
		var image: Image = await _render(_icon_canvas(icon, ["draw_full"], false, false), Vector2i(px, px), true)
		_save(image, "%s-%d" % [prefix, px])
	var layers: Image = await _render(_icon_canvas(icon, ["draw_background", "draw_foreground"], true, false), Vector2i(ICON_LAYER_PX, ICON_LAYER_PX), true)
	_save(layers, "%s-adaptive-%d" % [prefix, ICON_LAYER_PX])
	var mono: Image = await _render(_icon_canvas(icon, ["draw_monochrome"], true, true), Vector2i(ICON_LAYER_PX, ICON_LAYER_PX), true)
	_save(mono, "%s-monochrome-%d" % [prefix, ICON_LAYER_PX])


## A Control that calls the icon's draw functions over its whole rect, and
## optionally draws the adaptive icon guides on top.
func _icon_canvas(icon: Object, methods: Array[String], guides: bool, backdrop: bool) -> Control:
	var canvas: Control = Control.new()
	canvas.draw.connect(func() -> void:
		var rect: Rect2 = Rect2(Vector2.ZERO, canvas.size)
		if backdrop:
			canvas.draw_rect(rect, PREVIEW_BACKDROP)
		for method: String in methods:
			icon.call(method, canvas, rect)
		if guides:
			var center: Vector2 = rect.get_center()
			canvas.draw_arc(center, rect.size.x * SAFE_ZONE_SHARE * 0.5, 0.0, TAU, 96, GUIDE_COLOR, 2.0, true)
			var visible: Vector2 = rect.size * VISIBLE_SHARE
			canvas.draw_rect(Rect2(center - visible * 0.5, visible), GUIDE_COLOR, false, 2.0)
	)
	return canvas


# Helpers

func _instance(path: String) -> Control:
	if not ResourceLoader.exists(path):
		_problems.append("missing %s" % path)
		return null
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		_problems.append("%s is not a scene" % path)
		return null
	var node: Node = packed.instantiate()
	if not node is Control:
		_problems.append("%s: root must be a Control, is %s" % [path, node.get_class()])
		node.free()
		return null
	return node as Control


## Sets the contract properties before the node enters the tree.
func _set_props(node: Control, path: String, props: Dictionary) -> bool:
	for key: String in props:
		if not key in node:
			_problems.append("%s: root has no property %s" % [path, key])
			node.free()
			return false
		node.set(key, props[key])
	return true


## Renders a Control at an exact pixel size. The node is sized before it
## enters the tree, so its size is right in _ready().
func _render(node: Control, pixels: Vector2i, transparent: bool) -> Image:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = pixels
	viewport.transparent_bg = transparent
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	node.position = Vector2.ZERO
	node.size = Vector2(pixels)
	root.add_child(viewport)
	viewport.add_child(node)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	viewport.queue_free()
	await process_frame
	return image


func _save(image: Image, base_name: String) -> void:
	var path: String = _out_dir + base_name + _suffix + ".png"
	var absolute: String = ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var error: Error = image.save_png(absolute)
	if error != OK:
		_problems.append("could not save %s (error %d)" % [path, error])
	else:
		_written.append(path)
