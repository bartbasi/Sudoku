extends SceneTree
## Draws the play screen's layout on the foldable and split screen windows of
## docs/DESIGN_SYSTEM.md section 4.11 as wireframes, from layout_model.gd, and
## writes docs/design/window-shapes.png. One dp is one pixel times SCALE.
## Every window shows its safe insets in gray, the header row (Pause, time and
## score, Hint in the order the arrangement uses), the band with the level
## sticker, the board with its box lines, and the pad; a window that is too
## small shows the message instead.
##
##   timeout 300 godot --path . --script res://tools/design/window_fit.gd
##
## Needs a window (headless has no renderer). check_samples.gd checks the same
## numbers headless. Study code in tools/, never shipped.
## Owner: senior-graphic-designer.

const LayoutModel := preload("res://tools/design/layout_model.gd")

const OUT_PATH: String = "res://docs/design/window-shapes.png"
const SCALE: float = 1.0
const GAP: float = 24.0
const LABEL_H: float = 34.0
const ROW_W: float = 1500.0

var _skin: GameSkin = null


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		print("window_fit.gd needs a window: run without --headless")
		quit(1)
		return
	_skin = load("res://src/skins/pop_light.tres") as GameSkin
	var shown: Array[LayoutModel.Screen] = []
	for screen: LayoutModel.Screen in LayoutModel.window_screens():
		if not screen.label.begins_with("smallest") and not screen.label.begins_with("too "):
			shown.append(screen)
	# Rows of windows, left to right, wrapping at ROW_W.
	var places: Array[Vector2] = []
	var x: float = GAP
	var y: float = GAP
	var row_h: float = 0.0
	for screen: LayoutModel.Screen in shown:
		if x + screen.w > ROW_W and x > GAP:
			x = GAP
			y += row_h + LABEL_H + GAP
			row_h = 0.0
		places.append(Vector2(x, y + LABEL_H))
		x += screen.w + GAP
		row_h = maxf(row_h, screen.h)
	var size: Vector2 = Vector2(ROW_W, y + row_h + LABEL_H + GAP)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(ceili(size.x * SCALE), ceili(size.y * SCALE))
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var page: Control = Control.new()
	page.size = size
	page.scale = Vector2(SCALE, SCALE)
	page.theme = ThemeFactory.build(_skin)
	viewport.add_child(page)
	var sheet: Sheet = Sheet.new()
	sheet.skin = _skin
	sheet.size = size
	for i: int in shown.size():
		sheet.windows.append([shown[i], places[i]])
	page.add_child(sheet)
	for i: int in shown.size():
		var screen: LayoutModel.Screen = shown[i]
		var layout: LayoutModel.StackLayout = LayoutModel.play(screen, _skin)
		var label: Label = Label.new()
		label.theme_type_variation = ThemeFactory.CAPTION
		var detail: String = "too small: message only" if layout.arrangement == LayoutModel.Arrangement.TOO_SMALL \
			else "%s, board %d dp, cell %.1f" % [LayoutModel.ARRANGEMENT_NAMES[layout.arrangement], roundi(layout.board), layout.cell()]
		label.text = "%s\n%s" % [screen.label, detail]
		label.position = places[i] - Vector2(0.0, LABEL_H)
		page.add_child(label)
		if layout.arrangement == LayoutModel.Arrangement.TOO_SMALL:
			var message: Label = Label.new()
			message.theme_type_variation = ThemeFactory.BODY
			message.text = "This window is too small. Make it bigger to play."
			message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			message.position = places[i] + Vector2(24.0, screen.top + 8.0)
			message.size = Vector2(screen.w - 48.0, screen.h - screen.top - screen.bottom - 16.0)
			page.add_child(message)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	var error: Error = image.save_png(ProjectSettings.globalize_path(OUT_PATH))
	if error != OK:
		print("could not write %s (error %d)" % [OUT_PATH, error])
		quit(1)
		return
	print("wrote %s (%d windows)" % [OUT_PATH, shown.size()])
	quit(0)


## Draws every window's wireframe.
class Sheet extends Control:
	var skin: GameSkin = null
	var windows: Array[Array] = [] ## [Screen, origin]

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#E9E9E9"))
		for entry: Array in windows:
			var screen: LayoutModel.Screen = entry[0]
			var origin: Vector2 = entry[1]
			_window(screen, origin)

	func _window(screen: LayoutModel.Screen, origin: Vector2) -> void:
		var frame: Rect2 = Rect2(origin, Vector2(screen.w, screen.h))
		draw_rect(frame, skin.page_bg)
		var inset: Color = Color("#BDBDBD")
		draw_rect(Rect2(origin, Vector2(screen.w, screen.top)), inset)
		draw_rect(Rect2(origin + Vector2(0.0, screen.h - screen.bottom), Vector2(screen.w, screen.bottom)), inset)
		draw_rect(frame, skin.outline, false, 2.0)
		var layout: LayoutModel.StackLayout = LayoutModel.play(screen, skin)
		if layout.arrangement == LayoutModel.Arrangement.TOO_SMALL:
			return
		var m: float = skin.page_margin
		var box: Vector2 = origin + Vector2(m, screen.top + m)
		var over: float = skin.line_outer_w + skin.shadow_offset
		var block: float = layout.board + over
		var keys_h: float = 3.0 * layout.key_h + 2.0 * skin.space_s
		if layout.arrangement == LayoutModel.Arrangement.STACKED:
			var col_x: float = box.x + (layout.content.x - layout.content_w) * 0.5
			var top: float = box.y + layout.spare * 0.5
			var header: Rect2 = Rect2(col_x, top, layout.content_w, LayoutModel.HEADER_ROW)
			_header(header, false)
			var band: Rect2 = Rect2(col_x, header.end.y, layout.content_w, layout.info_zone - LayoutModel.HEADER_ROW)
			_band(band)
			_board(Rect2(col_x + (layout.content_w - block) * 0.5, band.end.y, block, block))
			_pad(Rect2(col_x, band.end.y + block + layout.gap, layout.content_w, keys_h), layout)
		else:
			var left: float = box.x + layout.spare_x * 0.5
			var board_y: float = box.y + (layout.content.y - block) * 0.5
			_board(Rect2(left, board_y, block, block))
			var side_x: float = left + block + LayoutModel.SIDE_GAP
			var top: float = box.y + layout.spare * 0.5
			var header: Rect2 = Rect2(side_x, top, layout.content_w, LayoutModel.HEADER_ROW)
			_header(header, true)
			var band: Rect2 = Rect2(side_x, header.end.y, layout.content_w, layout.info_zone - LayoutModel.HEADER_ROW)
			_band(band)
			_pad(Rect2(side_x, band.end.y, layout.content_w, keys_h), layout)

	## Hint, time, score and Pause faces, 40 dp tall; Hint at the far end
	## from the board when side by side.
	func _header(row: Rect2, mirrored: bool) -> void:
		var y: float = row.position.y + 4.0
		var hint_x: float = row.end.x - LayoutModel.HINT_FACE_W - skin.shadow_offset if mirrored else row.position.x
		var pause_x: float = row.position.x if mirrored else row.end.x - LayoutModel.ICON_FACE - skin.shadow_offset
		_face(Rect2(hint_x, y, LayoutModel.HINT_FACE_W, 40.0), skin.button_primary_bg)
		_face(Rect2(pause_x, y, LayoutModel.ICON_FACE, 40.0), skin.button_bg)
		var mid: float = row.position.x + row.size.x * 0.5
		_face(Rect2(mid - LayoutModel.TIME_MIN_W - 4.0, y, LayoutModel.TIME_MIN_W, 40.0), skin.hud_bg)
		_face(Rect2(mid + 4.0, y, LayoutModel.SCORE_MIN_W, 40.0), skin.hud_score_bg)

	func _band(band: Rect2) -> void:
		_face(Rect2(band.position.x + skin.space_s, band.end.y - skin.space_s - 26.0, 72.0, 26.0), skin.sticker_bg)

	func _board(block: Rect2) -> void:
		var over: float = skin.line_outer_w + skin.shadow_offset
		var side: float = block.size.x - over
		var b: Rect2 = Rect2(block.position + Vector2(skin.line_outer_w * 0.5, skin.line_outer_w * 0.5), Vector2(side, side))
		draw_rect(Rect2(b.position + Vector2(skin.shadow_offset, skin.shadow_offset), b.size), skin.shadow)
		draw_rect(b, skin.cell_bg)
		var cell: float = side / 9.0
		for i: int in range(1, 9):
			var heavy: bool = i % 3 == 0
			var w: float = skin.line_box_w if heavy else 1.0
			var color: Color = skin.line_box if heavy else skin.line_cell
			draw_line(b.position + Vector2(i * cell, 0.0), b.position + Vector2(i * cell, side), color, w)
			draw_line(b.position + Vector2(0.0, i * cell), b.position + Vector2(side, i * cell), color, w)
		draw_rect(b, skin.line_outer, false, skin.line_outer_w)

	func _pad(rect: Rect2, layout: LayoutModel.StackLayout) -> void:
		var gap: float = skin.space_s
		for i: int in 9:
			_face(Rect2(rect.position.x + float(i % 3) * (layout.key_w + gap), rect.position.y + float(i / 3) * (layout.key_h + gap), layout.key_w, layout.key_h), skin.pad_key_place_bg)
		var right: float = rect.position.x + 3.0 * layout.key_w + 2.0 * gap + skin.group_gap
		_face(Rect2(right, rect.position.y, layout.action_w, layout.key_h), skin.mode_toggle_active_bg)
		_face(Rect2(right, rect.position.y + layout.key_h + gap, layout.action_w, layout.key_h), skin.mode_toggle_bg)
		var half: float = (layout.action_w - gap) * 0.5
		var bottom: float = rect.position.y + 2.0 * (layout.key_h + gap)
		_face(Rect2(right, bottom, half, layout.key_h), skin.button_bg)
		_face(Rect2(right + half + gap, bottom, half, layout.key_h), skin.button_bg)

	## A Pop face: hard shadow, fill, outline.
	func _face(face: Rect2, fill: Color) -> void:
		draw_rect(Rect2(face.position + Vector2(skin.shadow_offset, skin.shadow_offset), face.size), skin.shadow)
		draw_rect(face, fill)
		draw_rect(face, skin.outline, false, skin.outline_w)
