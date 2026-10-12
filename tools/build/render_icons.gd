extends SceneTree
## Renders the Android launcher icons from the code drawn app icon
## (src/design/app_icon.gd) into build/icons/, where the Android export
## preset reads them. The PNGs are build output: git ignores build/ and they
## are never committed.
##
## Needs a window, because headless mode has no renderer:
##   timeout 120 godot --path . --script res://tools/build/render_icons.gd
## Exits 0 when all four files are written and look right, 1 otherwise.
## Owner: platform-dev.
##
## Writes:
##   main_192.png        legacy launcher icon (draw_full)
##   background_432.png  adaptive background layer (draw_background)
##   foreground_432.png  adaptive foreground layer (draw_foreground)
##   monochrome_432.png  adaptive monochrome layer (draw_monochrome)

const AppIcon: GDScript = preload("res://src/design/app_icon.gd")

const OUT_DIR: String = "res://build/icons/"
const MAIN_PX: int = 192
const LAYER_PX: int = 432
## A pixel counts as drawn above this alpha.
const ALPHA_FLOOR: float = 0.02

var _problems: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_problems.append("no renderer in headless mode; run without --headless")
		_finish()
		return
	var error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	if error != OK:
		_problems.append("could not create %s (error %d)" % [OUT_DIR, error])
		_finish()
		return
	# Keep Godot's importer out of the output folder. The export reads the
	# PNG files directly.
	var ignore: FileAccess = FileAccess.open(OUT_DIR + ".gdignore", FileAccess.WRITE)
	if ignore != null:
		ignore.close()
	await _make("main_192", "draw_full", MAIN_PX, false)
	await _make("background_432", "draw_background", LAYER_PX, true)
	await _make("foreground_432", "draw_foreground", LAYER_PX, false)
	await _make("monochrome_432", "draw_monochrome", LAYER_PX, false)
	_finish()


## Renders one draw function into a px square, checks it and saves it.
## opaque: every pixel must be fully drawn (the background layer). Otherwise
## the image must have both drawn and transparent pixels.
func _make(base_name: String, method: String, px: int, opaque: bool) -> void:
	var rect: Rect2 = Rect2(0, 0, px, px)
	var canvas: Control = Control.new()
	canvas.draw.connect(func() -> void: AppIcon.call(method, canvas, rect))
	var image: Image = await _render(canvas, Vector2i(px, px))
	var drawn: int = 0
	for y: int in px:
		for x: int in px:
			if image.get_pixel(x, y).a > ALPHA_FLOOR:
				drawn += 1
	var total: int = px * px
	if opaque and drawn != total:
		_problems.append("%s: %d of %d pixels are transparent" % [base_name, total - drawn, total])
	if not opaque and (drawn == 0 or drawn == total):
		_problems.append("%s: %d of %d pixels drawn, expected a shape on a clear background" % [base_name, drawn, total])
	var path: String = OUT_DIR + base_name + ".png"
	var error: Error = image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		_problems.append("could not save %s (error %d)" % [path, error])
		return
	print("wrote %s (%d by %d, %d pixels drawn)" % [path, px, px, drawn])


func _render(node: Control, pixels: Vector2i) -> Image:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = pixels
	viewport.transparent_bg = true
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


func _finish() -> void:
	for problem: String in _problems:
		printerr("PROBLEM  %s" % problem)
	print("Icons done, %d problem(s)." % _problems.size())
	quit(0 if _problems.is_empty() else 1)
