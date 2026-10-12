extends "res://tests/unit_test.gd"
## Every icon of ARCHITECTURE section 7 exists, builds real shapes that stay
## inside their square at small and large sizes, and draws without error in
## the button colors of both skins, as a direct draw, a texture and an
## IconView.

const CONTRACT: Array[StringName] = [
	&"undo", &"erase", &"mode_place", &"mode_cross_out", &"hint", &"pause",
	&"play", &"settings", &"back", &"close", &"check", &"lock",
]
const SIDES: Array[float] = [10.0, 20.0, 24.0, 48.0, 96.0, 512.0]
const SKIN_PATHS: Array[String] = ["res://src/skins/pop_light.tres", "res://src/skins/pop_dark.tres"]


func _skins() -> Array[GameSkin]:
	var skins: Array[GameSkin] = []
	for path: String in SKIN_PATHS:
		skins.append(load(path) as GameSkin)
	return skins


func test_icon_list_matches_the_contract() -> void:
	assert_eq(Icons.ALL.size(), CONTRACT.size(), "twelve icons")
	for icon: StringName in CONTRACT:
		assert_true(Icons.has_icon(icon), "has %s" % icon)


func test_stroke_and_sizes_match_section_4_1() -> void:
	assert_eq(Icons.STROKE, 0.14, "stroke is 0.14 of the side")
	assert_eq(Icons.SIZE_BUTTON, 20.0, "20 dp in buttons")
	assert_eq(Icons.SIZE_ICON_BUTTON, 24.0, "24 dp in icon buttons")


func test_icons_stay_inside_their_square_at_every_size() -> void:
	for icon: StringName in Icons.ALL:
		for side: float in SIDES:
			var rect: Rect2 = Rect2(13.0, 7.5, side, side)
			var shapes: Array[PackedVector2Array] = Icons.polygons(icon, rect)
			assert_true(shapes.size() > 0, "%s at %d has shapes" % [icon, side])
			var area: float = 0.0
			for shape: PackedVector2Array in shapes:
				assert_true(shape.size() >= 3, "%s at %d: every shape is a polygon" % [icon, side])
				for point: Vector2 in shape:
					assert_true(rect.grow(0.01).has_point(point), "%s at %d: %s lies outside %s" % [icon, side, point, rect])
				area += absf(_area(shape))
			# Ink covers a real share of the square, so it reads at a glance.
			assert_true(area > 0.08 * side * side, "%s at %d covers %.0f percent" % [icon, side, 100.0 * area / (side * side)])


func test_icons_center_in_a_wide_rect() -> void:
	var shapes: Array[PackedVector2Array] = Icons.polygons(Icons.CLOSE, Rect2(0.0, 0.0, 100.0, 20.0))
	for shape: PackedVector2Array in shapes:
		for point: Vector2 in shape:
			assert_true(point.x >= 40.0 and point.x <= 60.0, "drawn in the centered square")


func test_every_icon_has_its_own_shape() -> void:
	var seen: Dictionary[String, StringName] = {}
	for icon: StringName in Icons.ALL:
		var key: String = var_to_str(Icons.polygons(icon, Rect2(0, 0, 24, 24)))
		assert_false(seen.has(key), "%s looks the same as %s" % [icon, seen.get(key, &"")])
		seen[key] = icon


func test_unknown_icon_draws_nothing() -> void:
	assert_eq(Icons.polygons(&"no_such_icon", Rect2(0, 0, 24, 24)).size(), 0, "nothing for an unknown name")


func test_every_icon_draws_in_both_skins() -> void:
	var item: RID = RenderingServer.canvas_item_create()
	for skin: GameSkin in _skins():
		var colors: Array[Color] = [skin.button_text, skin.button_primary_text, skin.button_disabled_text, skin.mode_toggle_active_text, skin.sticker_text]
		for icon: StringName in Icons.ALL:
			for color: Color in colors:
				for side: float in SIDES:
					Icons.draw_rid(item, icon, Rect2(0, 0, side, side), color)
			var texture: Texture2D = Icons.texture(icon, Icons.SIZE_BUTTON)
			assert_eq(texture.get_width(), 20, "%s texture width" % icon)
			assert_eq(texture.get_height(), 20, "%s texture height" % icon)
			texture.draw(item, Vector2.ZERO, skin.button_text)
			texture.draw_rect(item, Rect2(0, 0, 24, 24), false, skin.button_text)
		RenderingServer.canvas_item_clear(item)
	RenderingServer.free_rid(item)


func test_icon_view_follows_its_button_and_theme() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	for skin: GameSkin in _skins():
		var button: Button = Button.new()
		button.theme = ThemeFactory.build(skin)
		button.theme_type_variation = ThemeFactory.PAD_ACTION
		var view: IconView = IconView.new()
		view.icon = Icons.UNDO
		view.theme_type_variation = ThemeFactory.PAD_ACTION
		button.add_child(view)
		root.add_child(button)
		assert_eq(view.mouse_filter, Control.MOUSE_FILTER_IGNORE, "an icon never takes taps")
		assert_eq(view.icon_color(), skin.button_text, "normal color in %s" % skin.id)
		button.disabled = true
		assert_eq(view.icon_color(), skin.button_disabled_text, "disabled color in %s" % skin.id)
		root.remove_child(button)
		button.free()


func _area(points: PackedVector2Array) -> float:
	var total: float = 0.0
	for i: int in points.size():
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		total += a.x * b.y - b.x * a.y
	return total * 0.5
