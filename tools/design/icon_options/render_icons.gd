extends SceneTree
## Renders the final app icon, Ring (Bart's pick, 2026-10-12, made bolder),
## to build/icon_options/ (ignored by git and by Godot's importer), next to
## Ring as Bart picked it, and checks that every foreground and monochrome
## pixel stays inside the Android safe zone.
## Needs a window (headless mode has no renderer):
##   timeout 120 godot --path . --script res://tools/design/icon_options/render_icons.gd
## Exits 1 on any problem. Prototype tool, never shipped.
## Owner: senior-graphic-designer.
##
## Writes, for the final Ring, at 512, 192, 144, 96 and 48 px:
##   ring-final-full-<px>.png       legacy square icon
##   ring-final-launcher-<px>.png   background and foreground, visible area,
##                                  circle mask, as a launcher shows it
##   ring-final-mono-<px>.png       monochrome layer, visible area, on a dark
##                                  circle, as a themed icon
## plus ring-final-layers-432.png (the safe zone circle and the visible area
## square drawn on), and ring-final-sheet.png: every form at every size at
## 1x, the picked Ring row above each final row, and the main menu hero
## (draw_foreground on page_bg) at 64 and 200 px.
## option_nine.gd and option_box.gd stay in the folder as the record of the
## pick; this script no longer renders them.

const ORIGINAL: String = "res://tools/design/icon_options/option_ring_original.gd"
const FINAL: String = "res://tools/design/icon_options/option_ring.gd"
const SLUG: String = "ring-final"
const OUT_DIR: String = "res://build/icon_options/"
const SIZES: Array[int] = [512, 192, 144, 96, 48]
const FORMS: Array[String] = ["full", "launcher", "mono"]
const FORM_NAMES: Dictionary = {"full": "Full icon", "launcher": "Launcher (circle mask)", "mono": "Themed (monochrome)"}
const HERO_SIZES: Array[int] = [64, 200]
const LAYER_PX: int = 432
const SAFE_SHARE: float = 66.0 / 108.0
const VISIBLE_SHARE: float = 72.0 / 108.0
## Pop light page_bg, behind the main menu hero.
const PAGE_BG: Color = Color("#FFEB8F")
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
	var original: Object = _load(ORIGINAL)
	var final_icon: Object = _load(FINAL)
	if original == null or final_icon == null:
		_finish()
		return
	var renders: Dictionary = {}
	for version: String in ["original", "final"]:
		var icon: Object = original if version == "original" else final_icon
		for px: int in SIZES:
			var full: Image = await _render(_canvas(icon, ["draw_full"], Rect2(0, 0, px, px)), Vector2i(px, px))
			var launcher: Image = await _launcher(icon, ["draw_background", "draw_foreground"], px)
			var mono: Image = await _launcher(icon, ["draw_monochrome"], px)
			_tint_on_circle(mono)
			renders["%s-full-%d" % [version, px]] = full
			renders["%s-launcher-%d" % [version, px]] = launcher
			renders["%s-mono-%d" % [version, px]] = mono
			if version == "final":
				_save(full, "%s-full-%d" % [SLUG, px])
				_save(launcher, "%s-launcher-%d" % [SLUG, px])
				_save(mono, "%s-mono-%d" % [SLUG, px])
		for px: int in HERO_SIZES:
			renders["%s-hero-%d" % [version, px]] = await _hero(icon, px)
	var layer_rect: Rect2 = Rect2(0, 0, LAYER_PX, LAYER_PX)
	var layers: Image = await _render(_canvas(final_icon, ["draw_background", "draw_foreground"], layer_rect, true), Vector2i(LAYER_PX, LAYER_PX))
	_save(layers, "%s-layers-%d" % [SLUG, LAYER_PX])
	for method: String in ["draw_foreground", "draw_monochrome"]:
		var alone: Image = await _render(_canvas(final_icon, [method], layer_rect), Vector2i(LAYER_PX, LAYER_PX))
		var outside: int = _pixels_outside_safe_zone(alone)
		print("Ring final %-16s pixels outside the safe zone: %d, farthest drawn pixel %.3f R" % [method, outside, _farthest(alone)])
		if outside > 0:
			_problems.append("Ring final: %s draws %d pixels outside the safe zone" % [method, outside])
	var sheet: Image = await _sheet(renders)
	_save(sheet, "%s-sheet" % SLUG)
	_finish()


func _finish() -> void:
	print("")
	for path: String in _written:
		print("wrote    %s" % path)
	for problem: String in _problems:
		print("PROBLEM  %s" % problem)
	print("Rendered %d file(s), %d problem(s)." % [_written.size(), _problems.size()])
	quit(0 if _problems.is_empty() else 1)


func _load(path: String) -> Object:
	var script: GDScript = load(path) as GDScript
	if script == null or not script.can_instantiate():
		_problems.append("%s does not load" % path)
		return null
	var icon: Object = script.new()
	for method: String in ["draw_full", "draw_background", "draw_foreground", "draw_monochrome"]:
		if not icon.has_method(method):
			_problems.append("%s has no %s(canvas, rect)" % [path, method])
			return null
	return icon


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


## The main menu hero (DESIGN_SYSTEM.md 7.1): draw_foreground with a rect
## 108/66 of the box side, centered on the box, on page_bg, no background
## layer. The image has a 20 px page margin around the box.
func _hero(icon: Object, box: int) -> Image:
	var pad: int = 20
	var side: int = box + 2 * pad
	var layer: float = float(box) / SAFE_SHARE
	var offset: float = (layer - float(side)) * 0.5
	var canvas: Control = Control.new()
	canvas.draw.connect(func() -> void:
		canvas.draw_rect(Rect2(0, 0, side, side), PAGE_BG)
		icon.call("draw_foreground", canvas, Rect2(-offset, -offset, layer, layer))
	)
	return await _render(canvas, Vector2i(side, side), false)


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


## Farthest drawn pixel center from the layer center, share of the safe
## zone radius.
func _farthest(image: Image) -> float:
	var center: Vector2 = Vector2(LAYER_PX, LAYER_PX) * 0.5
	var radius: float = float(LAYER_PX) * SAFE_SHARE * 0.5
	var far: float = 0.0
	for y: int in LAYER_PX:
		for x: int in LAYER_PX:
			if image.get_pixel(x, y).a > ALPHA_FLOOR:
				far = maxf(far, Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(center))
	return far / radius


## The comparison sheet: for each form, the picked Ring row and then the
## final row, every size at 1x; then the hero on page_bg at 64 and 200 px.
func _sheet(renders: Dictionary) -> Image:
	var margin: int = 24
	var label_h: int = 30
	var big: int = SIZES[0]
	var width: int = margin
	for px: int in SIZES:
		width += px + margin
	var row_h: int = label_h + big + margin
	var hero_h: int = label_h + HERO_SIZES[HERO_SIZES.size() - 1] + 40 + margin
	var height: int = margin + FORMS.size() * 2 * row_h + hero_h
	var size_list: String = ""
	for px: int in SIZES:
		size_list += ("" if size_list.is_empty() else ", ") + str(px)
	var textures: Dictionary = {}
	for key: String in renders.keys():
		textures[key] = ImageTexture.create_from_image(renders[key] as Image)
	var canvas: Control = Control.new()
	canvas.draw.connect(func() -> void:
		canvas.draw_rect(Rect2(0, 0, width, height), SHEET_BG)
		var font: Font = ThemeDB.fallback_font
		var top: float = float(margin)
		for form: String in FORMS:
			for version: String in ["original", "final"]:
				var which: String = "Ring as picked" if version == "original" else "Ring final"
				var title: String = "%s, %s: %s px at 1x" % [FORM_NAMES[form], which, size_list]
				canvas.draw_string(font, Vector2(margin, top + 20.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, SHEET_TEXT)
				var x: float = float(margin)
				var y: float = top + float(label_h)
				for px: int in SIZES:
					var texture: Texture2D = textures["%s-%s-%d" % [version, form, px]] as Texture2D
					canvas.draw_texture(texture, Vector2(x, y + float(big - px) * 0.5))
					x += float(px + margin)
				top += float(row_h)
		canvas.draw_string(font, Vector2(margin, top + 20.0), "Main menu hero on page_bg, 64 and 200 px: Ring as picked, then Ring final", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, SHEET_TEXT)
		var hx: float = float(margin)
		for version: String in ["original", "final"]:
			for px: int in HERO_SIZES:
				var texture: Texture2D = textures["%s-hero-%d" % [version, px]] as Texture2D
				canvas.draw_texture(texture, Vector2(hx, top + float(label_h)))
				hx += float(px + 40 + margin)
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
