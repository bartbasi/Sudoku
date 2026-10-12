extends "res://tests/unit_test.gd"
## ThemeFactory builds a Theme for both skins with every style of
## DESIGN_SYSTEM.md section 5, the type roles of section 3.2, the built-in
## font only, and the button states of section 4.2.

const DesignDoc := preload("res://tests/design/design_doc.gd")
const PopBox := preload("res://src/design/pop_box.gd")
const SKIN_PATHS: Array[String] = ["res://src/skins/pop_light.tres", "res://src/skins/pop_dark.tres"]


func _skins() -> Array[GameSkin]:
	var skins: Array[GameSkin] = []
	for path: String in SKIN_PATHS:
		var skin: GameSkin = load(path) as GameSkin
		assert_true(skin != null, "%s loads as a GameSkin" % path)
		if skin != null:
			skins.append(skin)
	return skins


## Section 5 rows as [constant, variation, base, look]. The first table is
## text (Label), the second panels (PanelContainer, PAGE and SCRIM Panel), the
## third controls with their own Base column.
func _style_rows() -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []
	var tables: Array[Array] = DesignDoc.tables("## 5.")
	for t: int in tables.size():
		for cells: PackedStringArray in tables[t]:
			var constant: String = DesignDoc.code(cells[0])
			var variation: String = DesignDoc.quoted(cells[1])
			if constant.is_empty() or variation.is_empty():
				continue
			var base: String = "Label"
			var look: String = cells[cells.size() - 1]
			if t == 1:
				base = "Panel" if constant in ["PAGE", "SCRIM"] else "PanelContainer"
			elif t >= 2:
				base = cells[2].replace("(toggle)", "").strip_edges()
			result.append(PackedStringArray([constant, variation, base, look]))
	return result


func test_design_system_lists_the_styles() -> void:
	assert_eq(_style_rows().size(), 43, "section 5 has 17 text, 12 panel and 14 control styles")


func test_every_style_has_its_constant() -> void:
	var map: Dictionary = (ThemeFactory as Script).get_script_constant_map()
	var rows: Array[PackedStringArray] = _style_rows()
	for row: PackedStringArray in rows:
		assert_true(map.has(row[0]), "ThemeFactory.%s exists" % row[0])
		if map.has(row[0]):
			assert_eq(map[row[0]], StringName(row[1]), "ThemeFactory.%s" % row[0])
			assert_eq(ThemeFactory.VARIATIONS.get(StringName(row[1]), &""), StringName(row[2]), "base of %s" % row[1])
	assert_eq(ThemeFactory.VARIATIONS.size(), rows.size(), "no variation beyond section 5")


func test_every_variation_is_in_the_theme_for_both_skins() -> void:
	for skin: GameSkin in _skins():
		var theme: Theme = ThemeFactory.build(skin)
		for row: PackedStringArray in _style_rows():
			var variation: StringName = StringName(row[1])
			var base: StringName = StringName(row[2])
			var where: String = "%s in %s" % [variation, skin.id]
			assert_true(theme.is_type_variation(variation, base), "%s is a variation of %s" % [where, base])
			match base:
				&"Label":
					assert_true(theme.has_font(&"font", variation), "%s has a font" % where)
					assert_true(theme.has_font_size(&"font_size", variation), "%s has a font size" % where)
					assert_true(theme.has_color(&"font_color", variation), "%s has a font color" % where)
				&"Panel", &"PanelContainer":
					assert_true(theme.has_stylebox(&"panel", variation), "%s has a panel" % where)
				&"Button":
					for item: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]:
						assert_true(theme.has_stylebox(item, variation), "%s has %s" % [where, item])
					for item: StringName in [&"font_color", &"font_pressed_color", &"font_disabled_color", &"icon_normal_color", &"icon_disabled_color"]:
						assert_true(theme.has_color(item, variation), "%s has %s" % [where, item])
					assert_true(theme.has_font(&"font", variation), "%s has a font" % where)
				&"CheckButton":
					for item: StringName in [&"checked", &"unchecked", &"checked_disabled", &"unchecked_disabled"]:
						assert_true(theme.has_icon(item, variation), "%s has %s" % [where, item])
				&"HSeparator":
					assert_true(theme.has_stylebox(&"separator", variation), "%s has a separator" % where)
				&"ProgressBar":
					assert_true(theme.has_stylebox(&"background", variation), "%s has a track" % where)
					assert_true(theme.has_stylebox(&"fill", variation), "%s has a fill" % where)
				_:
					fail("unexpected base %s" % base)


func test_text_styles_use_the_role_and_token_of_section_5() -> void:
	for skin: GameSkin in _skins():
		var theme: Theme = ThemeFactory.build(skin)
		for row: PackedStringArray in _style_rows():
			if row[2] != "Label":
				continue
			var variation: StringName = StringName(row[1])
			var role: StringName = StringName(row[3].get_slice(" role", 0).strip_edges())
			var token: String = DesignDoc.code(row[3])
			assert_true(ThemeFactory.ROLES.has(role), "%s names role %s" % [variation, role])
			assert_eq(ThemeFactory.VARIATION_ROLES.get(variation, &""), role, "%s role" % variation)
			assert_eq(theme.get_font_size(&"font_size", variation), ThemeFactory.role_size(role), "%s size" % variation)
			assert_eq(theme.get_color(&"font_color", variation), skin.get(token) as Color, "%s color %s in %s" % [variation, token, skin.id])


func test_button_colors_follow_the_skin() -> void:
	var pairs: Dictionary[StringName, Array] = {
		ThemeFactory.BUTTON_PRIMARY: [&"button_primary_bg", &"button_primary_text"],
		ThemeFactory.BUTTON_SECONDARY: [&"button_bg", &"button_text"],
		ThemeFactory.BUTTON_DANGER: [&"button_danger_bg", &"button_danger_text"],
		ThemeFactory.HINT_BUTTON: [&"button_primary_bg", &"button_primary_text"],
		ThemeFactory.ICON_BUTTON: [&"button_bg", &"button_text"],
		ThemeFactory.PAD_KEY_PLACE: [&"pad_key_place_bg", &"pad_key_place_text"],
		ThemeFactory.PAD_KEY_CROSS: [&"pad_key_cross_bg", &"pad_key_cross_text"],
		ThemeFactory.PAD_ACTION: [&"button_bg", &"button_text"],
		ThemeFactory.MODE_BUTTON: [&"mode_toggle_bg", &"mode_toggle_text"],
		ThemeFactory.LIST_BUTTON: [&"button_bg", &"button_text"],
	}
	for skin: GameSkin in _skins():
		var theme: Theme = ThemeFactory.build(skin)
		for type: StringName in pairs:
			var normal: PopBox = theme.get_stylebox(&"normal", type) as PopBox
			assert_true(normal != null, "%s normal is a Pop face" % type)
			if normal == null:
				continue
			assert_eq(normal.face, skin.get(pairs[type][0]) as Color, "%s face in %s" % [type, skin.id])
			assert_eq(theme.get_color(&"font_color", type), skin.get(pairs[type][1]) as Color, "%s text in %s" % [type, skin.id])
			assert_eq(theme.get_color(&"icon_normal_color", type), skin.get(pairs[type][1]) as Color, "%s icon in %s" % [type, skin.id])
		var active: PopBox = theme.get_stylebox(&"pressed", ThemeFactory.MODE_BUTTON) as PopBox
		assert_eq(active.face, skin.mode_toggle_active_bg, "active mode face")
		assert_eq(theme.get_color(&"font_pressed_color", ThemeFactory.MODE_BUTTON), skin.mode_toggle_active_text, "active mode text")


func test_button_states_differ_by_more_than_color() -> void:
	for skin: GameSkin in _skins():
		var theme: Theme = ThemeFactory.build(skin)
		for type: StringName in ThemeFactory.VARIATIONS:
			if ThemeFactory.VARIATIONS[type] != &"Button":
				continue
			var normal: PopBox = theme.get_stylebox(&"normal", type) as PopBox
			var pressed: PopBox = theme.get_stylebox(&"pressed", type) as PopBox
			var disabled: PopBox = theme.get_stylebox(&"disabled", type) as PopBox
			assert_eq(normal.press, 0.0, "%s raised" % type)
			assert_eq(normal.shadow, skin.shadow, "%s casts the hard shadow" % type)
			assert_eq(normal.shadow_offset, skin.shadow_offset, "%s shadow offset" % type)
			assert_eq(normal.outline, skin.outline, "%s outline" % type)
			assert_eq(pressed.press, 1.0, "%s sinks when pressed" % type)
			assert_eq(pressed.content_margin_left - normal.content_margin_left, skin.shadow_offset, "%s content moves with the face" % type)
			assert_eq(disabled.shadow.a, 0.0, "%s disabled has no shadow" % type)
			assert_eq(disabled.press, 0.0, "%s disabled face stays put" % type)
			assert_eq(disabled.hatch, skin.button_disabled_hatch, "%s disabled hatch" % type)
			assert_eq(disabled.hatch_w, skin.hatch_w, "%s hatch weight" % type)
			assert_eq(disabled.hatch_gap, skin.hatch_gap, "%s hatch gap" % type)
			assert_eq(disabled.face, skin.button_disabled_bg, "%s disabled face" % type)
			assert_eq(disabled.outline, skin.button_disabled_outline, "%s disabled outline" % type)
			assert_eq(theme.get_color(&"font_disabled_color", type), skin.button_disabled_text, "%s disabled text" % type)
			assert_eq(normal.get_minimum_size(), pressed.get_minimum_size(), "%s keeps its size when pressed" % type)


func test_cross_out_keys_carry_the_stripe_and_place_keys_do_not() -> void:
	for skin: GameSkin in _skins():
		var theme: Theme = ThemeFactory.build(skin)
		var cross: PopBox = theme.get_stylebox(&"normal", ThemeFactory.PAD_KEY_CROSS) as PopBox
		var place: PopBox = theme.get_stylebox(&"normal", ThemeFactory.PAD_KEY_PLACE) as PopBox
		assert_eq(cross.stripe, skin.pad_key_cross_mark, "stripe color")
		assert_true(cross.stripe_near >= 0.2 and cross.stripe_far <= 0.4 and cross.stripe_near < cross.stripe_far, "stripe between 0.2 and 0.4")
		assert_eq(place.stripe.a, 0.0, "Place keys have no stripe")


func test_skin_option_shows_the_badge_only_when_selected() -> void:
	for skin: GameSkin in _skins():
		var theme: Theme = ThemeFactory.build(skin)
		var normal: PopBox = theme.get_stylebox(&"normal", ThemeFactory.SKIN_OPTION) as PopBox
		var pressed: PopBox = theme.get_stylebox(&"pressed", ThemeFactory.SKIN_OPTION) as PopBox
		assert_eq(normal.badge.a, 0.0, "no badge when not selected")
		assert_eq(pressed.badge, skin.sticker_bg, "badge in sticker_bg when selected")
		assert_eq(pressed.badge_icon, skin.sticker_text, "check in sticker_text")
		assert_eq(pressed.radius, skin.radius_card, "skin option is a card")


func test_panels_follow_section_5() -> void:
	for skin: GameSkin in _skins():
		var theme: Theme = ThemeFactory.build(skin)
		var faces: Dictionary[StringName, Color] = {
			ThemeFactory.PAGE: skin.page_bg, ThemeFactory.SCRIM: skin.scrim, ThemeFactory.CARD: skin.surface_bg,
			ThemeFactory.DIALOG: skin.surface_bg, ThemeFactory.HINT_PANEL: skin.surface_bg,
			ThemeFactory.LESSON_CARD: skin.surface_bg, ThemeFactory.BOARD_MESSAGE: skin.surface_bg,
			ThemeFactory.HUD_TIME: skin.hud_bg, ThemeFactory.HUD_SCORE: skin.hud_score_bg,
			ThemeFactory.STICKER: skin.sticker_bg, ThemeFactory.CELEBRATE_STICKER: skin.celebrate_bg,
			ThemeFactory.HINT_TAG: skin.hint_tag_bg,
		}
		for type: StringName in faces:
			var box: PopBox = theme.get_stylebox(&"panel", type) as PopBox
			assert_true(box != null, "%s is a Pop face" % type)
			if box == null:
				continue
			assert_eq(box.face, faces[type], "%s face in %s" % [type, skin.id])
			var flat: bool = type in [ThemeFactory.PAGE, ThemeFactory.SCRIM, ThemeFactory.HINT_TAG]
			assert_eq(box.shadow.a > 0.0, not flat, "%s shadow" % type)
			assert_eq(box.outline.a > 0.0, not flat, "%s outline" % type)
		var card: PopBox = theme.get_stylebox(&"panel", ThemeFactory.CARD) as PopBox
		var dialog: PopBox = theme.get_stylebox(&"panel", ThemeFactory.DIALOG) as PopBox
		assert_eq(card.pad_left, skin.space_m + skin.outline_w, "card padding")
		assert_eq(dialog.pad_left, skin.space_l + skin.outline_w, "dialog padding")
		assert_eq(card.radius, skin.radius_card, "card radius")
		var message: PopBox = theme.get_stylebox(&"panel", ThemeFactory.BOARD_MESSAGE) as PopBox
		assert_eq(message.bar, skin.conflict_mark, "full board message bar color")
		assert_eq(message.bar_w, skin.conflict_bar_w, "full board message bar width")


func test_roles_match_section_3_2() -> void:
	var rows: Array[PackedStringArray] = DesignDoc.rows("### 3.2")
	assert_eq(rows.size(), ThemeFactory.ROLES.size(), "one role per row")
	for cells: PackedStringArray in rows:
		var role: StringName = StringName(cells[0])
		assert_true(ThemeFactory.ROLES.has(role), "role %s exists" % role)
		if not ThemeFactory.ROLES.has(role):
			continue
		var spec: Array = ThemeFactory.ROLES[role]
		assert_eq(int(spec[0]), cells[1].to_int(), "%s size" % role)
		var embolden: float = ThemeFactory.HEAVY if cells[2] == "Heavy" else ThemeFactory.SEMIBOLD
		assert_eq(float(spec[1]), embolden, "%s weight" % role)
		assert_eq(bool(spec[2]), cells[3] == "Yes", "%s capitals" % role)
		assert_eq(float(spec[3]), cells[4].to_float(), "%s tracking" % role)
		assert_eq(float(spec[4]), cells[5].to_float(), "%s width" % role)
		assert_eq(float(spec[5]), cells[6].to_float(), "%s line height" % role)


func test_weights_match_section_3_1() -> void:
	for cells: PackedStringArray in DesignDoc.rows("### 3.1"):
		var expected: float = DesignDoc.code(cells[1]).to_float() if DesignDoc.code(cells[1]) != "" else cells[1].to_float()
		match cells[0]:
			"Semibold":
				assert_eq(ThemeFactory.SEMIBOLD, expected, "semibold")
			"Bold":
				assert_eq(ThemeFactory.BOLD, expected, "bold")
			"Heavy":
				assert_eq(ThemeFactory.HEAVY, expected, "heavy")


func test_fonts_are_the_built_in_font_only() -> void:
	for skin: GameSkin in _skins():
		var theme: Theme = ThemeFactory.build(skin)
		var fonts: Array[Font] = [theme.default_font]
		for type: StringName in theme.get_font_type_list():
			for font_name: StringName in theme.get_font_list(type):
				fonts.append(theme.get_font(font_name, type))
		for font: Font in fonts:
			var variation: FontVariation = font as FontVariation
			assert_true(variation != null, "every font is a FontVariation")
			if variation != null:
				assert_eq(variation.base_font, ThemeDB.fallback_font, "every font is the built-in font")


func test_condensed_roles_pull_letters_together() -> void:
	var display: FontVariation = ThemeFactory.role_font(ThemeFactory.ROLE_DISPLAY)
	assert_true(is_equal_approx(display.variation_transform.x.x, 0.84), "display width")
	assert_eq(display.spacing_glyph, -4, "display spacing: -0.5 tracking, -3.9 for width")
	assert_true(is_equal_approx(ThemeFactory.role_font(ThemeFactory.ROLE_HEADING).variation_embolden, ThemeFactory.HEAVY), "heading is heavy")
	assert_eq(ThemeFactory.role_font(ThemeFactory.ROLE_BODY).variation_embolden, ThemeFactory.SEMIBOLD, "body is semibold")


func test_display_text_sets_capitals_by_role() -> void:
	assert_eq(ThemeFactory.display_text(ThemeFactory.TITLE, "New puzzle"), "NEW PUZZLE")
	assert_eq(ThemeFactory.display_text(ThemeFactory.BUTTON_PRIMARY, "Continue"), "CONTINUE")
	assert_eq(ThemeFactory.display_text(ThemeFactory.BODY, "New to Sudoku?"), "New to Sudoku?")
	assert_eq(ThemeFactory.display_text(ThemeFactory.VALUE, "12:48"), "12:48")
	assert_eq(ThemeFactory.display_text(&"NotAStyle", "Keep"), "Keep")


func test_skins_give_different_themes() -> void:
	var skins: Array[GameSkin] = _skins()
	if skins.size() < 2:
		return
	var light: Theme = ThemeFactory.build(skins[0])
	var dark: Theme = ThemeFactory.build(skins[1])
	var light_page: PopBox = light.get_stylebox(&"panel", ThemeFactory.PAGE) as PopBox
	var dark_page: PopBox = dark.get_stylebox(&"panel", ThemeFactory.PAGE) as PopBox
	assert_ne(light_page.face, dark_page.face, "page color follows the skin")


func test_every_stylebox_and_icon_draws_without_error() -> void:
	var item: RID = RenderingServer.canvas_item_create()
	for skin: GameSkin in _skins():
		var theme: Theme = ThemeFactory.build(skin)
		for type: StringName in theme.get_stylebox_type_list():
			for box_name: StringName in theme.get_stylebox_list(type):
				var box: StyleBox = theme.get_stylebox(box_name, type)
				for rect: Rect2 in [Rect2(0, 0, 40, 40), Rect2(3.5, 7.25, 337, 64), Rect2(0, 0, 8, 8)]:
					box.draw(item, rect)
		for type: StringName in theme.get_icon_type_list():
			for icon_name: StringName in theme.get_icon_list(type):
				var texture: Texture2D = theme.get_icon(icon_name, type)
				assert_true(texture.get_width() > 0 and texture.get_height() > 0, "%s %s has a size" % [type, icon_name])
				texture.draw(item, Vector2(10, 10))
				texture.draw_rect(item, Rect2(0, 0, 90, 26), false)
		RenderingServer.canvas_item_clear(item)
	RenderingServer.free_rid(item)


func test_press_does_not_change_size() -> void:
	var box: PopBox = ThemeFactory.build(_skins()[0]).get_stylebox(&"normal", ThemeFactory.BUTTON_PRIMARY) as PopBox
	var copy: PopBox = box.duplicate() as PopBox
	var raised: Vector2 = copy.get_minimum_size()
	copy.press = 0.5
	assert_eq(copy.get_minimum_size(), raised, "half pressed keeps the size")
	assert_eq(copy.face, box.face, "duplicate keeps the look")
	assert_eq(copy.face_rect(Rect2(0, 0, 10, 10)).position, Vector2(box.shadow_offset, box.shadow_offset) * 0.5, "face moves with press")
