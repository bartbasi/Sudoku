extends "res://tests/unit_test.gd"
## NumberPad: taps mapped to signals through the touch areas, the mode and
## Undo state it shows, the lock, and the faces lessons point at.

const Fx := preload("res://tests/board/board_fixtures.gd")

const CONTROLS: Array[StringName] = [
	&"pad:1", &"pad:2", &"pad:3", &"pad:4", &"pad:5", &"pad:6", &"pad:7", &"pad:8", &"pad:9",
	&"place", &"cross_out", &"undo", &"erase",
]

var pad: NumberPad
var log: Array[String] = []


## A pad as PlayArea lays it out for a content column content_w wide with
## keys key_h tall.
func _build(content_w: float = 344.0, key_h: float = 64.0) -> void:
	pad = NumberPad.new()
	pad.skin = Fx.light()
	pad.theme = ThemeFactory.build(Fx.light())
	Fx.root().add_child(pad)
	pad.size = Vector2(content_w + 8.0, 3.0 * key_h + 16.0 + 8.0)
	pad.digit_pressed.connect(func(d: int) -> void: log.append("digit %d" % d))
	pad.mode_pressed.connect(func() -> void: log.append("mode"))
	pad.erase_pressed.connect(func() -> void: log.append("erase"))
	pad.undo_pressed.connect(func() -> void: log.append("undo"))


func _local_center(control: StringName) -> Vector2:
	return pad.get_global_transform().affine_inverse() * pad.control_rect_global(control).get_center()


func test_each_key_emits_its_signal() -> void:
	_build()
	pad.set_undo_enabled(true)
	for d: int in range(1, 10):
		pad._gui_input(Fx.press(_local_center(StringName("pad:%d" % d))))
	pad._gui_input(Fx.press(_local_center(&"erase")))
	pad._gui_input(Fx.press(_local_center(&"undo")))
	pad._gui_input(Fx.press(_local_center(&"cross_out")))
	var expected: Array[String] = ["digit 1", "digit 2", "digit 3", "digit 4", "digit 5", "digit 6", "digit 7", "digit 8", "digit 9", "erase", "undo", "mode"]
	assert_eq(log, expected)


func test_digits_sit_in_phone_order() -> void:
	_build()
	var one: Rect2 = pad.control_rect_global(&"pad:1")
	var three: Rect2 = pad.control_rect_global(&"pad:3")
	var seven: Rect2 = pad.control_rect_global(&"pad:7")
	assert_true(three.position.x > one.position.x, "1 2 3 across the top")
	assert_true(is_equal_approx(three.position.y, one.position.y))
	assert_true(seven.position.y > one.position.y, "7 8 9 at the bottom")


func test_only_the_mode_that_is_off_switches() -> void:
	_build()
	pad.tap(_local_center(&"place"))
	assert_true(log.is_empty(), "Place is already on")
	pad.tap(_local_center(&"cross_out"))
	assert_eq(log, ["mode"] as Array[String])
	pad.set_mode(GameSession.Mode.CROSS_OUT)
	log.clear()
	pad.tap(_local_center(&"cross_out"))
	assert_true(log.is_empty(), "Cross Out is already on")
	pad.tap(_local_center(&"place"))
	assert_eq(log, ["mode"] as Array[String])


func test_set_mode_changes_the_keys_look() -> void:
	_build()
	var key: Button = pad.find_child("Digit5", true, false) as Button
	var place: Button = pad.find_child("Place", true, false) as Button
	var cross: Button = pad.find_child("CrossOut", true, false) as Button
	assert_eq(key.theme_type_variation, ThemeFactory.PAD_KEY_PLACE)
	assert_true(place.button_pressed)
	assert_false(cross.button_pressed)
	pad.set_mode(GameSession.Mode.CROSS_OUT)
	assert_eq(key.theme_type_variation, ThemeFactory.PAD_KEY_CROSS)
	assert_false(place.button_pressed)
	assert_true(cross.button_pressed)
	assert_eq(pad.mode(), GameSession.Mode.CROSS_OUT)


func test_disabled_undo_does_nothing() -> void:
	_build()
	assert_false(pad.is_undo_enabled(), "off until the session says otherwise")
	pad.tap(_local_center(&"undo"))
	assert_true(log.is_empty())
	var undo: Button = pad.find_child("Undo", true, false) as Button
	assert_true(undo.disabled, "shows the disabled look")
	pad.set_undo_enabled(true)
	assert_false(undo.disabled)
	pad.tap(_local_center(&"undo"))
	assert_eq(log, ["undo"] as Array[String])


func test_locked_pad_ignores_every_tap() -> void:
	_build()
	pad.set_undo_enabled(true)
	pad.set_locked(true)
	for control: StringName in CONTROLS:
		pad.tap(_local_center(control))
	assert_true(log.is_empty())


func test_touch_areas_reach_past_the_faces() -> void:
	_build(304.0, 40.0)
	var face: Rect2 = pad.control_rect_global(&"pad:5")
	var local: Rect2 = pad.get_global_transform().affine_inverse() * face
	pad.tap(Vector2(local.position.x - 3.5, local.get_center().y))
	pad.tap(Vector2(local.get_center().x, local.end.y + 3.5))
	assert_eq(log, ["digit 5", "digit 5"] as Array[String], "a slip into the gap still counts")


func test_nothing_tappable_between_digits_and_right_column() -> void:
	_build()
	var three: Rect2 = pad.control_rect_global(&"pad:3")
	var place: Rect2 = pad.control_rect_global(&"place")
	var gap: float = place.position.x - three.end.x
	assert_true(is_equal_approx(gap, Fx.light().group_gap), "group_gap between the blocks")
	var middle: Vector2 = Vector2((three.end.x + place.position.x) * 0.5, three.get_center().y)
	pad.tap(pad.get_global_transform().affine_inverse() * middle)
	assert_true(log.is_empty())


func _check_touch_areas(content_w: float, key_h: float) -> void:
	_build(content_w, key_h)
	var rects: Array[Rect2] = []
	for control: StringName in CONTROLS:
		var touch: Rect2 = pad.touch_rect_global(control)
		var face: Rect2 = pad.control_rect_global(control)
		assert_true(touch.size.x >= Layout.TOUCH_MIN - 0.001 and touch.size.y >= Layout.TOUCH_MIN - 0.001,
			"%s touch area %s at %.0f wide" % [control, touch.size, content_w])
		assert_true(touch.encloses(face), "%s touch area holds its face" % control)
		assert_true(face.size.y >= Layout.KEY_MIN - 0.001, "%s face at least KEY_MIN tall" % control)
		assert_true(Rect2(Vector2.ZERO, pad.size).encloses(pad.get_global_transform().affine_inverse() * touch),
			"%s touch area inside the pad" % control)
		for other: Rect2 in rects:
			assert_false(touch.grow(-0.01).intersects(other), "%s overlaps another touch area" % control)
		rects.append(touch)


func test_touch_areas_at_320_wide() -> void:
	_check_touch_areas(304.0, 40.0)


func test_touch_areas_at_360_wide() -> void:
	_check_touch_areas(344.0, 64.0)


func test_touch_areas_on_a_tablet() -> void:
	_check_touch_areas(600.0, 64.0)


func test_right_column_width() -> void:
	_build(304.0, 40.0)
	assert_true(is_equal_approx(pad.control_rect_global(&"place").size.x, Layout.ACTION_MIN), "clamped to ACTION_MIN at 320")
	pad.size = Vector2(608.0, pad.size.y)
	assert_true(is_equal_approx(pad.control_rect_global(&"place").size.x, Layout.ACTION_MAX), "clamped to ACTION_MAX on a tablet")


func test_mode_rect_spans_both_mode_buttons() -> void:
	_build()
	var both: Rect2 = pad.control_rect_global(&"mode")
	assert_true(both.encloses(pad.control_rect_global(&"place")))
	assert_true(both.encloses(pad.control_rect_global(&"cross_out")))
	assert_true(pad.control_rect_global(&"pad").encloses(pad.control_rect_global(&"pad:9")))
	assert_eq(pad.control_rect_global(&"pad:0"), Rect2())
	assert_eq(pad.control_rect_global(&"pad:x"), Rect2())
	assert_eq(pad.control_rect_global(&"hint"), Rect2())


func test_texts_come_from_the_theme_roles() -> void:
	_build()
	assert_eq((pad.find_child("Place", true, false) as Button).text, "PLACE")
	assert_eq((pad.find_child("CrossOut", true, false) as Button).text, "CROSS OUT")
	assert_eq((pad.find_child("Undo", true, false) as Button).text, "UNDO")
	assert_eq((pad.find_child("Erase", true, false) as Button).text, "ERASE")


func test_scene_file_gives_a_number_pad() -> void:
	var node: Node = (load("res://scenes/board/number_pad.tscn") as PackedScene).instantiate()
	assert_true(node is NumberPad)
	node.free()

