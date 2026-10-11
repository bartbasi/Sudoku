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
## Targets (any number; default: screens states rings icon):
##   screens      <direction>-<screen>.png for play, lesson, stats, complete,
##                plus <direction>-play-dark.png (15 files for 3 directions)
##   states       <direction>-states.png and <direction>-states-dark.png
##                (1080 by 2640, two boards at true size)
##   rings        ring-<layout>.png at true size on a 1080 px phone,
##                ring-<layout>-small.png at true size on a 720 px phone (the
##                smallest we support), ring-<layout>-small-x3.png enlarged
##   icon         app-icon-512.png, app-icon-48.png, and the adaptive layers
##                with the safe zone drawn on: app-icon-adaptive-432.png,
##                app-icon-monochrome-432.png
##   placeholder  placeholder/placeholder.png and placeholder-dark.png from
##                this tool's own test scene, and placeholder/placeholder-icon-*
##                from a stub icon, to prove the icon path
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

const OUT_DIR: String = "res://docs/design/"
const SCREENS: Array[String] = ["play", "lesson", "stats", "complete"]
const SCREEN_PATH: String = "res://tools/design/directions/ui/%s/%s.tscn"
const STATE_SHEET_PATH: String = "res://tools/design/directions/board/state_sheet.tscn"
const RING_CLOSEUP_PATH: String = "res://tools/design/directions/board/ring_closeup.tscn"
const APP_ICON_PATH: String = "res://src/design/app_icon.gd"
const PLACEHOLDER_PATH: String = "res://tools/design/placeholder/placeholder_screen.tscn"
const PLACEHOLDER_ICON_PATH: String = "res://tools/design/placeholder/placeholder_icon.gd"

## The state sheet holds two boards at true size with their notes, so it is
## taller than a phone screen.
const STATE_SHEET_SIZE: Vector2i = Vector2i(1080, 2640)

const DEFAULT_TARGETS: Array[String] = ["screens", "states", "rings", "icon"]
const ALL_TARGETS: Array[String] = ["screens", "states", "rings", "icon", "placeholder"]

## Adaptive icon geometry (Android): 108 dp layers, 66 dp safe zone circle,
## 72 dp visible area.
const ICON_LAYER_PX: int = 432
const SAFE_ZONE_SHARE: float = 66.0 / 108.0
const VISIBLE_SHARE: float = 72.0 / 108.0
## Review guides drawn on the icon previews only. Not part of any design.
const GUIDE_COLOR: Color = Color(1.0, 0.0, 1.0, 0.9)
const PREVIEW_BACKDROP: Color = Color(0.24, 0.24, 0.24, 1.0)

var _suffix: String = ""
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
		if targets.has("states"):
			await _capture_states(directions)
		if targets.has("rings"):
			await _capture_rings()
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
	for dark: bool in [false, true]:
		var node: Control = _instance(PLACEHOLDER_PATH)
		if node == null or not _set_props(node, PLACEHOLDER_PATH, {"dark": dark, "ring_layout": RingLayouts.DEFAULT_LAYOUT}):
			return
		var image: Image = await _render(node, Device.SCREEN_SIZE, false)
		_save(image, "placeholder/placeholder%s" % ("-dark" if dark else ""))
	await _capture_icon(PLACEHOLDER_ICON_PATH, "placeholder/placeholder-icon")


func _capture_screens(directions: Array[String]) -> void:
	for direction: String in directions:
		for screen: String in SCREENS:
			await _capture_screen(direction, screen, false)
		await _capture_screen(direction, "play", true)


func _capture_screen(direction: String, screen: String, dark: bool) -> void:
	var path: String = SCREEN_PATH % [direction, screen]
	var node: Control = _instance(path)
	if node == null or not _set_props(node, path, {"dark": dark, "ring_layout": RingLayouts.DEFAULT_LAYOUT}):
		return
	var image: Image = await _render(node, Device.SCREEN_SIZE, false)
	_save(image, "%s-%s%s" % [direction, screen, "-dark" if dark else ""])


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
	var path: String = OUT_DIR + base_name + _suffix + ".png"
	var absolute: String = ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var error: Error = image.save_png(absolute)
	if error != OK:
		_problems.append("could not save %s (error %d)" % [path, error])
	else:
		_written.append(path)
