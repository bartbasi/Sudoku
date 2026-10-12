extends "res://tests/unit_test.gd"
## Layout holds exactly the constants of DESIGN_SYSTEM.md section 4.6, with
## the same values.

const DesignDoc := preload("res://tests/design/design_doc.gd")


func test_constants_match_section_4_6() -> void:
	var rows: Array[PackedStringArray] = DesignDoc.rows("### 4.6")
	assert_eq(rows.size(), 19, "section 4.6 lists 19 constants")
	var map: Dictionary = (Layout as Script).get_script_constant_map()
	for cells: PackedStringArray in rows:
		var constant: String = DesignDoc.code(cells[0])
		assert_true(map.has(constant), "Layout.%s exists" % constant)
		if map.has(constant):
			assert_eq(map[constant], cells[1].to_float(), "Layout.%s" % constant)
	assert_eq(map.size(), rows.size(), "Layout has no constant beyond section 4.6")


func test_touch_targets_are_at_least_48() -> void:
	assert_true(Layout.TOUCH_MIN >= 48.0, "touch minimum")
	assert_true(Layout.KEY_MIN + 8.0 >= Layout.TOUCH_MIN, "a 40 dp key with 8 dp gaps gives a 48 dp touch area")
