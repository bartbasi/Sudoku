extends "res://tests/unit_test.gd"
## Layout holds exactly the constants of the first table of DESIGN_SYSTEM.md
## section 4.6, with the same values. The section's second table lists
## UiSizes (src/ui), which are not Layout constants.

const DesignDoc := preload("res://tests/design/design_doc.gd")


func test_constants_match_section_4_6() -> void:
	var tables: Array[Array] = DesignDoc.tables("### 4.6")
	assert_eq(tables.size(), 2, "section 4.6 has the Layout table and the UiSizes table")
	if tables.is_empty():
		return
	var rows: Array = tables[0]
	assert_eq(rows.size(), 22, "section 4.6 lists 22 Layout constants")
	var map: Dictionary = (Layout as Script).get_script_constant_map()
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
