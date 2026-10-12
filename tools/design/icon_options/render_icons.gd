extends SceneTree
## Renders the three app icon options to build/icon_options/ (ignored by git
## and by Godot's importer) for Bart to pick from, and checks that every
## foreground and monochrome pixel stays inside the Android safe zone.
## Needs a window (headless mode has no renderer):
##   timeout 120 godot --path . --script res://tools/design/icon_options/render_icons.gd
## Exits 1 on any problem. Prototype tool, never shipped.
## Owner: senior-graphic-designer.
##
## Per option <slug>:
##   <slug>-full-512.png, <slug>-full-48.png      legacy square icon
##   <slug>-launcher-512.png, <slug>-launcher-48.png
##       background and foreground, visible area, circle mask, as a launcher shows it
##   <slug>-mono-512.png, <slug>-mono-48.png
##       monochrome layer, visible area, on a dark circle, as a themed icon
##   <slug>-layers-432.png    background and foreground with the safe zone
##                            (circle) and visible area (square) drawn on
## And sheet.png: all three side by side, 48 px ones also at 1x.

const OPTIONS: Array[String] = [
	"res://tools/design/icon_options/option_ring.gd",
	"res://tools/design/icon_options/option_nine.gd",
	"res://tools/design/icon_options/option_box.gd",
]
const OUT_DIR: String = "res://build/icon_options/"
const SIZES: Array[int] = [512, 48]
const LAYER_PX: int = 432
const SAFE_SHARE: float = 66.0 / 108.0
const VISIBLE_SHARE: float = 72.0 / 108.0
## Review guides and preview backdrops. Not part of any design.
const GUIDE: Color = Color(1.0, 0.0, 1.0, 0.9)
const THEMED_BACKDROP: Color = Color("#2B2F3A")
const SHEET_BG: Color = Color("#E9E9E9")
const SHEET_TEXT: Color = Color("#111111")
## A pixel counts as drawn above this alpha.
const ALPHA_FLOOR: float = 0.02
## Tolerance on the safe zone radius, px at LAYER_PX.
const SAFE_TOLERANCE: float = 0.5

var _written: PackedStringArray = PackedStringArray()
var _problems: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	# Keep Godot's importer out of the output folder.
	var ignore: FileAccess = FileAccess.open(OUT_DIR + ".gdignore", FileAccess.WRITE)
	if ignore != null:
		ignore.close()
	var sheet_rows: Array[Dictionary] = []
	for path: String in OPTIONS:
		var script: GDScript = load(path) as GDScript
		if script == null or not script.can_instantiate():
			_problems.append("%s does not load" % path)
			continue
		var icon: Object = script.new()
		var missing: bool = false
		for method: String in ["draw_full", "draw_background", "draw_foreground", "draw_monochrome"]:
			if not icon.has_method(method):
				_problems.append("%s has no %s(canvas, rect)" % [path, method])
				missing = true
		if missing:
			continue
		var constants: Dictionary = script.get_script_constant_map()
		var option_name: String = str(constants.get("NAME", path.get_file()))
		var slug: String = option_name.to_lower()
		var row: Dictionary = {"name": option_name, "reason": str(constants.get("REASON", ""))}
		for px: int in SIZES:
			var full: Image = await _render(_canvas(icon, ["draw_full"], Rect2(0, 0, px, px)), Vector2i(px, px))
			_save(full, "%s-full-%d" % [slug, px])
			var launcher: Image = await _launcher(icon, ["draw_background", "draw_foreground"], px)
			_save(launcher, "%s-launcher-%d" % [slug, px])
			var mono: Image = await _launcher(icon, ["draw_monochrome"], px)
			_tint_on_circle(mono)
			_save(mono, "%s-mono-%d" % [slug, px])
			row["full-%d" % px] = full
			row["launcher-%d" % px] = launcher
			row["mono-%d" % px] = mono
		var layer_rect: Rect2 = Rect2(0, 0, LAYER_PX, LAYER_PX)
		var layers: Image = await _render(_canvas(icon, ["draw_background", "draw_foreground"], layer_rect, true), Vector2i(LAYER_PX, LAYER_PX))
		_save(layers, "%s-layers-%d" % [slug, LAYER_PX])
		for method: String in ["draw_foreground", "draw_monochrome"]:
			var alone: Image = await _render(_canvas(icon, [method], layer_rect), Vector2i(LAYER_PX, LAYER_PX))
			var outside: int = _pixels_outside_safe_zone(alone)
			print("%-5s %-16s pixels outside the safe zone: %d" % [option_name, method, outside])
			if outside > 0:
				_problems.append("%s: %s draws %d pixels outside the safe zone" % [option_name, method, outside])
		sheet_rows.append(row)
	if not sheet_rows.is_empty():
		var sheet: Image = await _sheet(sheet_rows)
		_save(sheet, "sheet")

	print("")
	for path: String in _written:
		print("wrote    %s" % path)
	for problem: String in _problems:
		print("PROBLEM  %s" % problem)
	print("Rendered %d file(s), %d problem(s)." % [_written.size(), _problems.size()])
	quit(0 if _problems.is_empty() else 1)


## A Control that calls the icon's draw functions into rect, optionally with
## the safe zone circle and the visible area square drawn on.
func _canvas(icon: Object, methods: Array[String], rect: Rect2, guides: bool = false) -> Control:
	var canvas: Control = Control.new()
	canvas.draw.connect(func() -> void:
		for method: String in methods:
			icon.call(method, canvas, rect)
		if guides:
			var center: Vector2 = rect.get_center()
			canvas.draw_arc(center, rect.size.x * SAFE_SHARE * 0.5, 0.0, TAU, 96, GUIDE, 2.0, true)
			var visible: Vector2 = rect.size * VISIBLE_SHARE
			canvas.draw_rect(Rect2(center - visible * 0.5, visible), GUIDE, false, 2.0)
	)
	return canvas


## The adaptive layers as a launcher shows them: the visible area of the
## 108 dp layer at px, masked to a circle.
func _launcher(icon: Object, methods: Array[String], px: int) -> Image:
	var layer: float = float(px) / VISIBLE_SHARE
	var offset: float = (layer - float(px)) * 0.5
	var image: Image = await _render(_canvas(icon, methods, Rect2(-offset, -offset, layer, layer)), Vector2i(px, px))
	var center: Vector2 = Vector2(px, px) * 0.5
	var radius: float = float(px) * 0.5
	for y: int in px:
		for x: int in px:
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(center)
			var cover: float = clampf(radius - d + 0.5, 0.0, 1.0)
			if cover < 1.0:
				var c: Color = image.get_pixel(x, y)
				c.a *= cover
				image.set_pixel(x, y, c)
	return image


## A themed icon preview: the monochrome layer over a dark circle.
func _tint_on_circle(image: Image) -> void:
	var px: int = image.get_width()
	var center: Vector2 = Vector2(px, px) * 0.5
	var radius: float = float(px) * 0.5
	for y: int in px:
		for x: int in px:
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(center)
			var cover: float = clampf(radius - d + 0.5, 0.0, 1.0)
			var top: Color = image.get_pixel(x, y)
			var mixed: Color = THEMED_BACKDROP.lerp(Color(top.r, top.g, top.b, 1.0), top.a)
			mixed.a = cover
			image.set_pixel(x, y, mixed)


func _pixels_outside_safe_zone(image: Image) -> int:
	var center: Vector2 = Vector2(LAYER_PX, LAYER_PX) * 0.5
	var radius: float = float(LAYER_PX) * SAFE_SHARE * 0.5 + SAFE_TOLERANCE
	var count: int = 0
	for y: int in LAYER_PX:
		for x: int in LAYER_PX:
			if image.get_pixel(x, y).a <= ALPHA_FLOOR:
				continue
			# The nearest point of the pixel square to the center.
			var near: Vector2 = Vector2(clampf(center.x, float(x), float(x + 1)), clampf(center.y, float(y), float(y + 1)))
			if near.distance_to(center) > radius:
				count += 1
	return count


## One sheet for the review: per option, the full icon, the launcher icon and
## the themed icon at 192 px (scaled from 512), and the same three at 48 px, 1x.
func _sheet(rows: Array[Dictionary]) -> Image:
	var big: int = 192
	var margin: int = 24
	var label_h: int = 56
	var cell_w: int = big + margin
	var width: int = margin + 3 * cell_w + 3 * (48 + margin)
	var row_h: int = label_h + big + margin
	var height: int = margin + rows.size() * row_h
	var textures: Array[Dictionary] = []
	for row: Dictionary in rows:
		var entry: Dictionary = {}
		for key: String in ["full-512", "launcher-512", "mono-512", "full-48", "launcher-48", "mono-48"]:
			var image: Image = (row[key] as Image).duplicate() as Image
			if image.get_width() != 48:
				image.resize(big, big, Image.INTERPOLATE_LANCZOS)
			entry[key] = ImageTexture.create_from_image(image)
		textures.append(entry)
	var canvas: Control = Control.new()
	canvas.draw.connect(func() -> void:
		canvas.draw_rect(Rect2(0, 0, width, height), SHEET_BG)
		var font: Font = ThemeDB.fallback_font
		for r: int in rows.size():
			var top: float = float(margin + r * row_h)
			var title: String = "%d. %s" % [r + 1, rows[r]["name"]]
			canvas.draw_string(font, Vector2(margin, top + 20.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, SHEET_TEXT)
			canvas.draw_string(font, Vector2(margin, top + 44.0), str(rows[r]["reason"]), HORIZONTAL_ALIGNMENT_LEFT, float(width - 2 * margin), 15, SHEET_TEXT)
			var y: float = top + float(label_h)
			var keys: Array[String] = ["full", "launcher", "mono"]
			for k: int in keys.size():
				var x_big: float = float(margin + k * cell_w)
				canvas.draw_texture_rect(textures[r][keys[k] + "-512"] as Texture2D, Rect2(x_big, y, big, big), false)
				var x_small: float = float(margin + 3 * cell_w + k * (48 + margin))
				canvas.draw_texture(textures[r][keys[k] + "-48"] as Texture2D, Vector2(x_small, y + float(big - 48) * 0.5))
	)
	return await _render(canvas, Vector2i(width, height), false)


## Renders a Control at an exact pixel size, transparent unless opaque.
func _render(node: Control, pixels: Vector2i, transparent: bool = true) -> Image:
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
	image.convert(Image.FORMAT_RGBA8)
	return image


func _save(image: Image, base_name: String) -> void:
	var path: String = OUT_DIR + base_name + ".png"
	var error: Error = image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		_problems.append("could not save %s (error %d)" % [path, error])
	else:
		_written.append(path)
