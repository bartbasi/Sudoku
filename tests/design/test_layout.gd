extends "res://tests/unit_test.gd"
## Layout holds exactly the constants of the first table of DESIGN_SYSTEM.md
## section 4.6, with the same values. The section's second table lists
## UiSizes (src/ui), which are not Layout constants. The window shape
## functions of section 4.11 give the same answers as the design model.

const DesignDoc := preload("res://tests/design/design_doc.gd")
const LayoutModel := preload("res://tools/design/layout_model.gd")
const SKIN_PATHS: Array[String] = ["res://src/skins/pop_light.tres", "res://src/skins/pop_dark.tres"]
const WINDOW_CONSTANTS: Array[String] = ["COLUMN_MIN", "SIDE_MAX", "SIDE_GAP", "BOARD_MIN", "CONTENT_MIN_H", "KEY_ASPECT_MAX"]


func test_constants_match_section_4_6() -> void:
	var tables: Array[Array] = DesignDoc.tables("### 4.6")
	assert_eq(tables.size(), 2, "section 4.6 has the Layout table and the UiSizes table")
	if tables.is_empty():
		return
	var rows: Array = tables[0]
	assert_eq(rows.size(), 28, "section 4.6 lists 28 Layout constants")
	var map: Dictionary = _number_constants()
	for cells: PackedStringArray in rows:
		var constant: String = DesignDoc.code(cells[0])
		assert_true(map.has(constant), "Layout.%s exists" % constant)
		if map.has(constant):
			assert_eq(map[constant], cells[1].to_float(), "Layout.%s" % constant)
	assert_eq(map.size(), rows.size(), "Layout has no constant beyond section 4.6")


func test_ui_sizes_are_not_layout_constants() -> void:
	var tables: Array[Array] = DesignDoc.tables("### 4.6")
	if tables.size() < 2:
		fail("section 4.6 has no UiSizes table")
		return
	var map: Dictionary = (Layout as Script).get_script_constant_map()
	for cells: PackedStringArray in tables[1]:
		for constant: String in DesignDoc.codes(cells[0]):
			assert_false(map.has(constant), "%s is a UiSizes constant, not a Layout one" % constant)


func test_touch_targets_are_at_least_48() -> void:
	assert_true(Layout.TOUCH_MIN >= 48.0, "touch minimum")
	assert_true(Layout.KEY_MIN + 8.0 >= Layout.TOUCH_MIN, "a 40 dp key with 8 dp gaps gives a 48 dp touch area")


func test_header_faces_fit_the_header_row() -> void:
	assert_true(Layout.ICON_FACE <= Layout.HEADER_ROW, "a 40 dp face fits the 48 dp header row")
	assert_true(Layout.CLOSE_FACE < Layout.ICON_FACE, "the close face is the smaller one")
	assert_true(Layout.BUTTON_TALL >= Layout.TOUCH_MIN, "a tall button is a full touch target")
	assert_eq(ThemeFactory.ICON_BUTTON_FACE, Layout.ICON_FACE, "the icon button face comes from Layout")


func test_window_constants_match_the_model() -> void:
	var ours: Dictionary = (Layout as Script).get_script_constant_map()
	var model: Dictionary = (LayoutModel as Script).get_script_constant_map()
	for constant: String in WINDOW_CONSTANTS:
		assert_true(ours.has(constant), "Layout.%s exists" % constant)
		assert_eq(ours.get(constant), model.get(constant), "Layout.%s" % constant)


func test_arrangement_values_match_the_model() -> void:
	assert_eq(Layout.Arrangement.STACKED, LayoutModel.Arrangement.STACKED, "STACKED")
	assert_eq(Layout.Arrangement.SIDE, LayoutModel.Arrangement.SIDE, "SIDE")
	assert_eq(Layout.Arrangement.TOO_SMALL, LayoutModel.Arrangement.TOO_SMALL, "TOO_SMALL")


## Every screen and window the model checks, in both skins: the same boards
## and the same arrangement, and the arrangement each window is pinned to.
func test_window_shapes_match_the_design_model() -> void:
	for path: String in SKIN_PATHS:
		var skin: GameSkin = load(path) as GameSkin
		var supported: Array = LayoutModel.supported_windows(skin)
		assert_true(supported.size() > 0, "the model supports some windows, " + path)
		var windows: Array = []
		windows.append_array(LayoutModel.screens())
		windows.append_array(LayoutModel.window_screens())
		windows.append_array(supported)
		var checked: int = 0
		for screen: RefCounted in windows:
			var size: Vector2 = LayoutModel.content_size(screen, skin)
			var top: float = screen.get("top")
			var content: Rect2 = Rect2(Vector2(skin.page_margin, top + skin.page_margin), size)
			var label: String = "%s, %s" % [screen.get("label"), path.get_file()]
			assert_eq(Layout.stacked_board(content, skin), LayoutModel.stacked_board(size, skin), "stacked board, " + label)
			assert_eq(Layout.side_board(content, skin), LayoutModel.side_board(size, skin), "side board, " + label)
			var kind: int = Layout.arrangement(content, skin)
			assert_eq(kind, LayoutModel.arrangement(size, skin), "arrangement, " + label)
			var expected: int = screen.get("expected")
			if expected >= 0:
				assert_eq(kind, expected, "pinned arrangement, " + label)
			checked += 1
		assert_eq(checked, windows.size(), "every window checked, " + path)


## On every screen and window the model checks, in both skins, play and
## lesson layouts: Layout.pad_faces_width gives the model's pad width.
func test_pad_faces_width_matches_the_design_model() -> void:
	for path: String in SKIN_PATHS:
		var skin: GameSkin = load(path) as GameSkin
		var windows: Array = []
		windows.append_array(LayoutModel.screens())
		windows.append_array(LayoutModel.window_screens())
		windows.append_array(LayoutModel.supported_windows(skin))
		var checked: int = 0
		for screen: RefCounted in windows:
			for out: RefCounted in [LayoutModel.play(screen, skin), LayoutModel.lesson(screen, skin)]:
				if out.get("arrangement") == LayoutModel.Arrangement.TOO_SMALL:
					continue
				var column_w: float = out.get("content_w")
				var key_h: float = out.get("key_h")
				var label: String = "%s, %s" % [screen.get("label"), path.get_file()]
				var ours: float = Layout.pad_faces_width(column_w, key_h, skin)
				assert_eq(ours, LayoutModel.pad_faces_width(column_w, key_h, skin), "pad faces width, " + label)
				assert_eq(ours, out.get("pad_w"), "pad width of the model's layout, " + label)
				checked += 1
		assert_true(checked > 0, "some layouts checked, " + path)


func test_pad_never_makes_a_key_flatter_than_the_cap() -> void:
	var skin: GameSkin = load(SKIN_PATHS[0]) as GameSkin
	var wide: float = Layout.pad_faces_width(600.0, Layout.KEY_MIN, skin)
	assert_true(wide < 600.0 - skin.shadow_offset, "a wide column narrows the pad")
	var narrow: float = Layout.pad_faces_width(Layout.COLUMN_MIN, Layout.KEY_MAX, skin)
	assert_eq(narrow, Layout.COLUMN_MIN - skin.shadow_offset, "a narrow column keeps the full width")
	assert_eq(Layout.pad_faces_width(0.0, Layout.KEY_MIN, skin), 0.0, "never negative")


## Layout's number constants; the Arrangement enum is not a table row.
func _number_constants() -> Dictionary:
	var out: Dictionary = {}
	var map: Dictionary = (Layout as Script).get_script_constant_map()
	for key: String in map:
		if map[key] is float:
			out[key] = map[key]
	return out
