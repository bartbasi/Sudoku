class_name ThemeFactory extends RefCounted
## Builds the game's Theme in code from a GameSkin (ARCHITECTURE section 7,
## DESIGN_SYSTEM.md sections 3 to 5). Every color and size comes from the
## skin; the type scale of section 3.2 and the few fixed shapes of section 5
## live here and nowhere else. Godot's built-in font only.
##
## Screens set theme_type_variation to one of the constants below and never
## set colors, sizes or fonts themselves. Roles set in capitals need the text
## passed through display_text(), because a Theme cannot change letter case.
## Owner: ui-motion-artist.

const PopBox := preload("res://src/design/pop_box.gd")
const SwitchTexture := preload("res://src/design/switch_texture.gd")

# Text (base Label)
const DISPLAY: StringName = &"Display"
const DISPLAY_ACCENT: StringName = &"DisplayAccent"
const TITLE: StringName = &"Title"
const HEADING: StringName = &"Heading"
const BODY: StringName = &"Body"
const BODY_SMALL: StringName = &"BodySmall"
const BODY_MUTED: StringName = &"BodyMuted"
const BODY_SMALL_12: StringName = &"BodySmall12"
const BODY_SMALL_11: StringName = &"BodySmall11"
const CAPTION: StringName = &"Caption"
const VALUE: StringName = &"Value"
const HUD_CAPTION: StringName = &"HudCaption"
const HUD_VALUE: StringName = &"HudValue"
const SCORE_CAPTION: StringName = &"ScoreCaption"
const SCORE_VALUE: StringName = &"ScoreValue"
const STICKER_LABEL: StringName = &"StickerLabel"
const CELEBRATE_LABEL: StringName = &"CelebrateLabel"
const CELEBRATE_DISPLAY: StringName = &"CelebrateDisplay"
const HINT_TAG_LABEL: StringName = &"HintTagLabel"
const PRIMARY_LABEL: StringName = &"PrimaryLabel"
const PRIMARY_CAPTION: StringName = &"PrimaryCaption"

# Panels (base PanelContainer, except PAGE and SCRIM: Panel)
const PAGE: StringName = &"Page"
const SCRIM: StringName = &"Scrim"
const CARD: StringName = &"Card"
const DIALOG: StringName = &"Dialog"
const HINT_PANEL: StringName = &"HintPanel"
const LESSON_CARD: StringName = &"LessonCard"
const BOARD_MESSAGE: StringName = &"BoardMessage"
const HUD_TIME: StringName = &"HudTime"
const HUD_SCORE: StringName = &"HudScore"
const STICKER: StringName = &"Sticker"
const CELEBRATE_STICKER: StringName = &"CelebrateSticker"
const HINT_TAG: StringName = &"HintTag"

# Controls
const BUTTON_PRIMARY: StringName = &"ButtonPrimary"
const BUTTON_SECONDARY: StringName = &"ButtonSecondary"
const BUTTON_DANGER: StringName = &"ButtonDanger"
const HINT_BUTTON: StringName = &"HintButton"
const ICON_BUTTON: StringName = &"IconButton"
const PAD_KEY_PLACE: StringName = &"PadKeyPlace"
const PAD_KEY_CROSS: StringName = &"PadKeyCross"
const PAD_ACTION: StringName = &"PadAction"
const MODE_BUTTON: StringName = &"ModeButton"
const LIST_BUTTON: StringName = &"ListButton"
const SKIN_OPTION: StringName = &"SkinOption"
const SWITCH: StringName = &"Switch"
const RULE: StringName = &"Rule"
const STAT_BAR: StringName = &"StatBar"

## Every type variation and the Godot class it is based on.
const VARIATIONS: Dictionary[StringName, StringName] = {
	DISPLAY: &"Label", DISPLAY_ACCENT: &"Label", TITLE: &"Label", HEADING: &"Label",
	BODY: &"Label", BODY_SMALL: &"Label", BODY_MUTED: &"Label", CAPTION: &"Label",
	VALUE: &"Label", HUD_CAPTION: &"Label", HUD_VALUE: &"Label", SCORE_CAPTION: &"Label",
	SCORE_VALUE: &"Label", STICKER_LABEL: &"Label", CELEBRATE_LABEL: &"Label",
	CELEBRATE_DISPLAY: &"Label", HINT_TAG_LABEL: &"Label", BODY_SMALL_12: &"Label",
	BODY_SMALL_11: &"Label", PRIMARY_LABEL: &"Label", PRIMARY_CAPTION: &"Label",
	PAGE: &"Panel", SCRIM: &"Panel", CARD: &"PanelContainer", DIALOG: &"PanelContainer",
	HINT_PANEL: &"PanelContainer", LESSON_CARD: &"PanelContainer", BOARD_MESSAGE: &"PanelContainer",
	HUD_TIME: &"PanelContainer", HUD_SCORE: &"PanelContainer", STICKER: &"PanelContainer",
	CELEBRATE_STICKER: &"PanelContainer", HINT_TAG: &"PanelContainer",
	BUTTON_PRIMARY: &"Button", BUTTON_SECONDARY: &"Button", BUTTON_DANGER: &"Button",
	HINT_BUTTON: &"Button", ICON_BUTTON: &"Button", PAD_KEY_PLACE: &"Button",
	PAD_KEY_CROSS: &"Button", PAD_ACTION: &"Button", MODE_BUTTON: &"Button",
	LIST_BUTTON: &"Button", SKIN_OPTION: &"Button", SWITCH: &"CheckButton",
	RULE: &"HSeparator", STAT_BAR: &"ProgressBar",
}

# Type roles (DESIGN_SYSTEM.md section 3.2)
const ROLE_DISPLAY: StringName = &"display"
const ROLE_TITLE: StringName = &"title"
const ROLE_HEADING: StringName = &"heading"
const ROLE_VALUE: StringName = &"value"
const ROLE_BUTTON: StringName = &"button"
const ROLE_MODE: StringName = &"mode"
const ROLE_BODY: StringName = &"body"
const ROLE_BODY_SMALL: StringName = &"body_small"
const ROLE_BODY_SMALL_12: StringName = &"body_small_12"
const ROLE_BODY_SMALL_11: StringName = &"body_small_11"
const ROLE_CAPTION: StringName = &"caption"
const ROLE_PAD_CAPTION: StringName = &"pad_caption"
const ROLE_HUD_VALUE: StringName = &"hud_value"
const ROLE_PAD_DIGIT: StringName = &"pad_digit"

## Weights (section 3.1) as variation_embolden on the built-in font.
const SEMIBOLD: float = 0.0
const BOLD: float = 0.5
const HEAVY: float = 0.9

## Per role: size dp, embolden, capitals, tracking dp, width, line height
## (a multiple of the size).
const ROLES: Dictionary[StringName, Array] = {
	ROLE_DISPLAY: [44, HEAVY, true, -0.5, 0.84, 1.0],
	ROLE_TITLE: [24, HEAVY, true, -0.25, 0.86, 1.1],
	ROLE_HEADING: [16, HEAVY, true, 0.25, 1.0, 1.2],
	ROLE_VALUE: [20, HEAVY, false, 0.0, 0.86, 1.0],
	ROLE_BUTTON: [14, HEAVY, true, 0.5, 1.0, 1.2],
	ROLE_MODE: [14, HEAVY, true, 0.0, 0.88, 1.2],
	ROLE_BODY: [14, SEMIBOLD, false, 0.0, 1.0, 1.3],
	ROLE_BODY_SMALL: [13, SEMIBOLD, false, 0.0, 1.0, 1.3],
	ROLE_BODY_SMALL_12: [12, SEMIBOLD, false, 0.0, 1.0, 1.3],
	ROLE_BODY_SMALL_11: [11, SEMIBOLD, false, 0.0, 1.0, 1.3],
	ROLE_CAPTION: [10, HEAVY, true, 0.75, 1.0, 1.2],
	ROLE_PAD_CAPTION: [10, HEAVY, true, 0.75, 1.0, 1.2],
	ROLE_HUD_VALUE: [20, HEAVY, false, 0.0, 0.86, 1.0],
	ROLE_PAD_DIGIT: [26, HEAVY, false, 0.0, 1.0, 1.0],
}

## Roles whose line box is trimmed by this many dp at the top and at the
## bottom, so the label fits its pad or header face (sections 3.5 and 3.6).
const ROLE_TRIMS: Dictionary[StringName, int] = {ROLE_PAD_DIGIT: 6, ROLE_PAD_CAPTION: 2, ROLE_HUD_VALUE: 4}

## The role each text-bearing variation sets its text in.
const VARIATION_ROLES: Dictionary[StringName, StringName] = {
	DISPLAY: ROLE_DISPLAY, DISPLAY_ACCENT: ROLE_DISPLAY, TITLE: ROLE_TITLE, HEADING: ROLE_HEADING,
	BODY: ROLE_BODY, BODY_SMALL: ROLE_BODY_SMALL, BODY_MUTED: ROLE_BODY_SMALL, CAPTION: ROLE_CAPTION,
	BODY_SMALL_12: ROLE_BODY_SMALL_12, BODY_SMALL_11: ROLE_BODY_SMALL_11,
	VALUE: ROLE_VALUE, HUD_CAPTION: ROLE_PAD_CAPTION, HUD_VALUE: ROLE_HUD_VALUE, SCORE_CAPTION: ROLE_PAD_CAPTION,
	SCORE_VALUE: ROLE_HUD_VALUE, STICKER_LABEL: ROLE_BUTTON, CELEBRATE_LABEL: ROLE_CAPTION,
	CELEBRATE_DISPLAY: ROLE_DISPLAY, HINT_TAG_LABEL: ROLE_CAPTION,
	PRIMARY_LABEL: ROLE_BUTTON, PRIMARY_CAPTION: ROLE_CAPTION,
	BUTTON_PRIMARY: ROLE_BUTTON, BUTTON_SECONDARY: ROLE_BUTTON, BUTTON_DANGER: ROLE_BUTTON,
	HINT_BUTTON: ROLE_CAPTION, ICON_BUTTON: ROLE_BUTTON, PAD_KEY_PLACE: ROLE_PAD_DIGIT,
	PAD_KEY_CROSS: ROLE_PAD_DIGIT, PAD_ACTION: ROLE_PAD_CAPTION, MODE_BUTTON: ROLE_MODE,
	LIST_BUTTON: ROLE_HEADING, SKIN_OPTION: ROLE_HEADING, SWITCH: ROLE_HEADING,
	STAT_BAR: ROLE_CAPTION,
}

## Condensing pulls the letters back together by this share of the size
## times (1 minus the width) (section 3.1).
const CONDENSE_PULL: float = 0.55

## Fixed shapes from section 5.
const ICON_BUTTON_FACE: float = Layout.ICON_FACE
const HINT_TAG_PAD_Y: float = 2.0
## HUD_TIME and HUD_SCORE padding at the top and bottom (section 3.6).
const HUD_PAD_Y: float = 2.0
## HINT_BUTTON padding on every side (section 3.6).
const HINT_BUTTON_PAD: float = 2.0
const PAD_ACTION_PAD_Y: float = 2.0
const STRIPE_NEAR: float = 0.2
const STRIPE_FAR: float = 0.4
const STAT_BAR_H: float = 16.0

static var _fonts: Dictionary[StringName, FontVariation] = {}


## The whole Theme for one skin. Cheap enough to call on every skin change.
static func build(skin: GameSkin) -> Theme:
	var theme: Theme = Theme.new()
	theme.default_font = role_font(ROLE_BODY)
	theme.default_font_size = role_size(ROLE_BODY)
	for variation: StringName in VARIATIONS:
		theme.set_type_variation(variation, VARIATIONS[variation])
	_add_defaults(theme, skin)
	_add_labels(theme, skin)
	_add_panels(theme, skin)
	_add_buttons(theme, skin)
	_add_switch(theme, skin)
	_add_rule(theme, skin)
	_add_stat_bar(theme, skin)
	return theme


## The font of a role: the built-in font with the role's weight, width and
## tracking. Shared between builds; it holds no color.
static func role_font(role: StringName) -> FontVariation:
	if _fonts.has(role):
		return _fonts[role]
	var spec: Array = ROLES[role]
	var size: float = float(spec[0])
	var width: float = float(spec[4])
	var font: FontVariation = FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = float(spec[1])
	font.spacing_glyph = roundi(float(spec[3]) - CONDENSE_PULL * size * (1.0 - width))
	if width < 1.0:
		font.variation_transform = Transform2D(Vector2(width, 0.0), Vector2(0.0, 1.0), Vector2.ZERO)
	if ROLE_TRIMS.has(role):
		font.spacing_top = -ROLE_TRIMS[role]
		font.spacing_bottom = -ROLE_TRIMS[role]
	_fonts[role] = font
	return font


static func role_size(role: StringName) -> int:
	return int(ROLES[role][0])


static func role_caps(role: StringName) -> bool:
	return bool(ROLES[role][2])


## Extra space between lines so a line is the role's line height. Measured
## on the role's own font, so a trimmed line box counts as trimmed.
static func role_line_spacing(role: StringName) -> int:
	var size: int = role_size(role)
	return roundi(float(ROLES[role][5]) * float(size) - role_font(role).get_height(size))


## text as a control with this variation shows it: in capitals for the roles
## that set capitals. Source strings stay in sentence case.
static func display_text(variation: StringName, text: String) -> String:
	if VARIATION_ROLES.has(variation) and role_caps(VARIATION_ROLES[variation]):
		return text.to_upper()
	return text


# Defaults for controls with no variation

static func _add_defaults(theme: Theme, skin: GameSkin) -> void:
	_label(theme, &"Label", ROLE_BODY, skin.text)
	_button(theme, &"Button", skin, skin.button_bg, skin.button_text, skin.button_text, ROLE_BUTTON, Vector4(skin.space_m, skin.space_s, skin.space_m, skin.space_s))


# Text

static func _add_labels(theme: Theme, skin: GameSkin) -> void:
	_label(theme, DISPLAY, ROLE_DISPLAY, skin.text)
	_label(theme, DISPLAY_ACCENT, ROLE_DISPLAY, skin.text_accent)
	_label(theme, TITLE, ROLE_TITLE, skin.text)
	_label(theme, HEADING, ROLE_HEADING, skin.text)
	_label(theme, BODY, ROLE_BODY, skin.text)
	_label(theme, BODY_SMALL, ROLE_BODY_SMALL, skin.text)
	_label(theme, BODY_MUTED, ROLE_BODY_SMALL, skin.text_muted)
	_label(theme, BODY_SMALL_12, ROLE_BODY_SMALL_12, skin.text)
	_label(theme, BODY_SMALL_11, ROLE_BODY_SMALL_11, skin.text)
	_label(theme, CAPTION, ROLE_CAPTION, skin.text_muted)
	_label(theme, VALUE, ROLE_VALUE, skin.text)
	_label(theme, HUD_CAPTION, ROLE_PAD_CAPTION, skin.hud_label)
	_label(theme, HUD_VALUE, ROLE_HUD_VALUE, skin.hud_text)
	_label(theme, SCORE_CAPTION, ROLE_PAD_CAPTION, skin.hud_score_text)
	_label(theme, SCORE_VALUE, ROLE_HUD_VALUE, skin.hud_score_text)
	_label(theme, STICKER_LABEL, ROLE_BUTTON, skin.sticker_text)
	_label(theme, CELEBRATE_LABEL, ROLE_CAPTION, skin.celebrate_text)
	_label(theme, CELEBRATE_DISPLAY, ROLE_DISPLAY, skin.celebrate_text)
	_label(theme, HINT_TAG_LABEL, ROLE_CAPTION, skin.hint_tag_text)
	_label(theme, PRIMARY_LABEL, ROLE_BUTTON, skin.button_primary_text)
	_label(theme, PRIMARY_CAPTION, ROLE_CAPTION, skin.button_primary_text)


static func _label(theme: Theme, type: StringName, role: StringName, color: Color) -> void:
	theme.set_font(&"font", type, role_font(role))
	theme.set_font_size(&"font_size", type, role_size(role))
	theme.set_color(&"font_color", type, color)
	theme.set_color(&"font_shadow_color", type, PopBox.CLEAR)
	theme.set_constant(&"line_spacing", type, role_line_spacing(role))


# Panels

static func _add_panels(theme: Theme, skin: GameSkin) -> void:
	var page: PopBox = PopBox.new()
	page.face = skin.page_bg
	page.refresh()
	theme.set_stylebox(&"panel", PAGE, page)
	var scrim: PopBox = PopBox.new()
	scrim.face = skin.scrim
	scrim.refresh()
	theme.set_stylebox(&"panel", SCRIM, scrim)

	var m: float = skin.space_m
	var card: PopBox = _raised(skin, skin.surface_bg, skin.radius_card)
	_pad(card, skin, m, m, m, m)
	theme.set_stylebox(&"panel", CARD, card)
	theme.set_stylebox(&"panel", LESSON_CARD, card.duplicate() as PopBox)

	var dialog: PopBox = _raised(skin, skin.surface_bg, skin.radius_card)
	var l: float = skin.space_l
	_pad(dialog, skin, l, l, l, l)
	theme.set_stylebox(&"panel", DIALOG, dialog)

	var hint_panel: PopBox = _raised(skin, skin.surface_bg, skin.radius_card)
	_pad(hint_panel, skin, m, skin.space_xs, m, skin.space_xs)
	theme.set_stylebox(&"panel", HINT_PANEL, hint_panel)

	var message: PopBox = _raised(skin, skin.surface_bg, skin.radius_card)
	message.bar = skin.conflict_mark
	message.bar_w = skin.conflict_bar_w
	_pad(message, skin, m + skin.conflict_bar_w, skin.space_s, m, skin.space_s)
	theme.set_stylebox(&"panel", BOARD_MESSAGE, message)

	var s: float = skin.space_s
	var hud_time: PopBox = _raised(skin, skin.hud_bg, skin.radius_control)
	_pad(hud_time, skin, s, HUD_PAD_Y, s, HUD_PAD_Y)
	theme.set_stylebox(&"panel", HUD_TIME, hud_time)
	var hud_score: PopBox = _raised(skin, skin.hud_score_bg, skin.radius_control)
	_pad(hud_score, skin, s, HUD_PAD_Y, s, HUD_PAD_Y)
	theme.set_stylebox(&"panel", HUD_SCORE, hud_score)

	var sticker: PopBox = _raised(skin, skin.sticker_bg, skin.radius_control)
	_pad(sticker, skin, s, skin.space_xs, s, skin.space_xs)
	theme.set_stylebox(&"panel", STICKER, sticker)
	var celebrate: PopBox = _raised(skin, skin.celebrate_bg, skin.radius_control)
	_pad(celebrate, skin, s, skin.space_xs, s, skin.space_xs)
	theme.set_stylebox(&"panel", CELEBRATE_STICKER, celebrate)

	var tag: PopBox = PopBox.new()
	tag.face = skin.hint_tag_bg
	tag.radius = skin.radius_control
	tag.set_padding(s, HINT_TAG_PAD_Y, s, HINT_TAG_PAD_Y)
	tag.refresh()
	theme.set_stylebox(&"panel", HINT_TAG, tag)


## A face with the outline and the hard shadow.
static func _raised(skin: GameSkin, face: Color, radius: float) -> PopBox:
	var box: PopBox = PopBox.new()
	box.face = face
	box.outline = skin.outline
	box.outline_w = skin.outline_w
	box.radius = radius
	box.shadow = skin.shadow
	box.shadow_offset = skin.shadow_offset
	box.refresh()
	return box


## Padding inside the outline.
static func _pad(box: PopBox, skin: GameSkin, left: float, top: float, right: float, bottom: float) -> void:
	var o: float = skin.outline_w if box.outline.a > 0.0 else 0.0
	box.set_padding(left + o, top + o, right + o, bottom + o)


# Buttons

static func _add_buttons(theme: Theme, skin: GameSkin) -> void:
	var s: float = skin.space_s
	var m: float = skin.space_m
	var xs: float = skin.space_xs
	var text_pad: Vector4 = Vector4(m, s, m, s)
	_button(theme, BUTTON_PRIMARY, skin, skin.button_primary_bg, skin.button_primary_text, skin.button_primary_text, ROLE_BUTTON, text_pad)
	_button(theme, BUTTON_SECONDARY, skin, skin.button_bg, skin.button_text, skin.button_text, ROLE_BUTTON, text_pad)
	_button(theme, BUTTON_DANGER, skin, skin.button_danger_bg, skin.button_danger_text, skin.button_danger_text, ROLE_BUTTON, text_pad)
	_button(theme, HINT_BUTTON, skin, skin.button_primary_bg, skin.button_primary_text, skin.button_primary_text, ROLE_CAPTION, Vector4(HINT_BUTTON_PAD, HINT_BUTTON_PAD, HINT_BUTTON_PAD, HINT_BUTTON_PAD))
	theme.set_constant(&"h_separation", HINT_BUTTON, roundi(xs))

	var icon_pad: float = (ICON_BUTTON_FACE - Icons.SIZE_ICON_BUTTON) * 0.5 - skin.outline_w
	_button(theme, ICON_BUTTON, skin, skin.button_bg, skin.button_text, skin.button_text, ROLE_BUTTON, Vector4(icon_pad, icon_pad, icon_pad, icon_pad))
	theme.set_constant(&"icon_max_width", ICON_BUTTON, roundi(Icons.SIZE_ICON_BUTTON))

	var key_pad: Vector4 = Vector4(xs, xs, xs, xs)
	_button(theme, PAD_KEY_PLACE, skin, skin.pad_key_place_bg, skin.pad_key_place_text, skin.pad_key_place_text, ROLE_PAD_DIGIT, key_pad)
	var cross_boxes: Array[PopBox] = _button(theme, PAD_KEY_CROSS, skin, skin.pad_key_cross_bg, skin.pad_key_cross_text, skin.pad_key_cross_text, ROLE_PAD_DIGIT, key_pad)
	for box: PopBox in cross_boxes:
		box.stripe = skin.pad_key_cross_mark
		box.stripe_near = STRIPE_NEAR
		box.stripe_far = STRIPE_FAR
		box.refresh()

	_button(theme, PAD_ACTION, skin, skin.button_bg, skin.button_text, skin.button_text, ROLE_PAD_CAPTION, Vector4(xs, PAD_ACTION_PAD_Y, xs, PAD_ACTION_PAD_Y))
	theme.set_constant(&"h_separation", PAD_ACTION, roundi(xs))

	var mode_boxes: Array[PopBox] = _button(theme, MODE_BUTTON, skin, skin.mode_toggle_bg, skin.mode_toggle_text, skin.mode_toggle_active_text, ROLE_MODE, Vector4(xs, xs, xs, xs))
	for box: PopBox in mode_boxes:
		if box.press >= 1.0:
			box.face = skin.mode_toggle_active_bg
			box.refresh()
	theme.set_constant(&"h_separation", MODE_BUTTON, roundi(s))

	_button(theme, LIST_BUTTON, skin, skin.button_bg, skin.button_text, skin.button_text, ROLE_HEADING, Vector4(m, m, m, m))

	var option_boxes: Array[PopBox] = _button(theme, SKIN_OPTION, skin, skin.surface_bg, skin.text, skin.text, ROLE_HEADING, Vector4(m, m, m, m))
	for box: PopBox in option_boxes:
		box.radius = skin.radius_card
		if box.press >= 1.0:
			box.badge = skin.sticker_bg
			box.badge_icon = skin.sticker_text
			box.badge_side = skin.space_xl
			box.badge_inset = skin.space_s
			box.badge_icon_side = skin.space_xl - 2.0 * skin.space_xs
		box.refresh()

	for type: StringName in [BUTTON_PRIMARY, BUTTON_SECONDARY, BUTTON_DANGER, LIST_BUTTON, SKIN_OPTION]:
		theme.set_constant(&"h_separation", type, roundi(s))
	for type: StringName in [BUTTON_PRIMARY, BUTTON_SECONDARY, BUTTON_DANGER, HINT_BUTTON, PAD_ACTION, MODE_BUTTON, LIST_BUTTON, SKIN_OPTION]:
		theme.set_constant(&"icon_max_width", type, roundi(Icons.SIZE_BUTTON))


## Every state of a Pop button (section 4.2): normal raised, pressed sunk into
## its shadow, disabled flat and hatched. Returns the normal and pressed
## boxes, which some types then add to. pad is left, top, right, bottom
## inside the outline.
static func _button(theme: Theme, type: StringName, skin: GameSkin, face: Color, text: Color, pressed_text: Color, role: StringName, pad: Vector4) -> Array[PopBox]:
	var normal: PopBox = _raised(skin, face, skin.radius_control)
	_pad(normal, skin, pad.x, pad.y, pad.z, pad.w)
	var pressed: PopBox = normal.duplicate() as PopBox
	pressed.set_padding(normal.pad_left, normal.pad_top, normal.pad_right, normal.pad_bottom)
	pressed.press = 1.0
	pressed.refresh()
	var disabled: PopBox = PopBox.new()
	disabled.face = skin.button_disabled_bg
	disabled.outline = skin.button_disabled_outline
	disabled.outline_w = skin.outline_w
	disabled.radius = skin.radius_control
	disabled.hatch = skin.button_disabled_hatch
	disabled.hatch_w = skin.hatch_w
	disabled.hatch_gap = skin.hatch_gap
	disabled.shadow_offset = skin.shadow_offset
	disabled.set_padding(normal.pad_left, normal.pad_top, normal.pad_right, normal.pad_bottom)
	disabled.refresh()

	theme.set_stylebox(&"normal", type, normal)
	theme.set_stylebox(&"hover", type, normal)
	theme.set_stylebox(&"pressed", type, pressed)
	theme.set_stylebox(&"hover_pressed", type, pressed)
	theme.set_stylebox(&"disabled", type, disabled)
	theme.set_stylebox(&"focus", type, StyleBoxEmpty.new())

	theme.set_font(&"font", type, role_font(role))
	theme.set_font_size(&"font_size", type, role_size(role))
	theme.set_constant(&"line_spacing", type, role_line_spacing(role))
	theme.set_constant(&"outline_size", type, 0)
	for item: StringName in [&"font_color", &"font_hover_color", &"font_focus_color", &"icon_normal_color", &"icon_hover_color", &"icon_focus_color"]:
		theme.set_color(item, type, text)
	for item: StringName in [&"font_pressed_color", &"font_hover_pressed_color", &"icon_pressed_color", &"icon_hover_pressed_color"]:
		theme.set_color(item, type, pressed_text)
	theme.set_color(&"font_disabled_color", type, skin.button_disabled_text)
	theme.set_color(&"icon_disabled_color", type, skin.button_disabled_text)
	return [normal, pressed]


# Switch, rule and stat bar

static func _add_switch(theme: Theme, skin: GameSkin) -> void:
	var on: SwitchTexture = _switch_texture(skin, true)
	var off: SwitchTexture = _switch_texture(skin, false)
	for item: StringName in [&"checked", &"checked_mirrored", &"checked_disabled", &"checked_disabled_mirrored"]:
		theme.set_icon(item, SWITCH, on)
	for item: StringName in [&"unchecked", &"unchecked_mirrored", &"unchecked_disabled", &"unchecked_disabled_mirrored"]:
		theme.set_icon(item, SWITCH, off)
	# No face: the row is the card it sits in. The empty box only sets the
	# touch height.
	var row: StyleBoxEmpty = StyleBoxEmpty.new()
	var spare: float = maxf(0.0, (Layout.TOUCH_MIN - SwitchTexture.TRACK_H) * 0.5)
	row.content_margin_top = spare
	row.content_margin_bottom = spare
	for item: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus", &"hover_mirrored", &"normal_mirrored", &"pressed_mirrored", &"hover_pressed_mirrored", &"disabled_mirrored"]:
		theme.set_stylebox(item, SWITCH, row)
	theme.set_font(&"font", SWITCH, role_font(ROLE_HEADING))
	theme.set_font_size(&"font_size", SWITCH, role_size(ROLE_HEADING))
	for item: StringName in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(item, SWITCH, skin.text)
	theme.set_color(&"font_disabled_color", SWITCH, skin.button_disabled_text)
	theme.set_constant(&"h_separation", SWITCH, roundi(skin.space_s))
	theme.set_constant(&"check_v_offset", SWITCH, 0)


static func _switch_texture(skin: GameSkin, on: bool) -> SwitchTexture:
	var texture: SwitchTexture = SwitchTexture.new()
	texture.on = on
	texture.track = skin.switch_on_bg if on else skin.switch_off_bg
	texture.knob = skin.switch_knob
	texture.outline = skin.outline
	texture.outline_w = skin.outline_w
	texture.radius = skin.radius_control
	texture.caption_font = role_font(ROLE_CAPTION)
	texture.caption_size = role_size(ROLE_CAPTION)
	texture.caption_color = skin.text_muted
	texture.caption_gap = skin.space_s
	return texture


static func _add_rule(theme: Theme, skin: GameSkin) -> void:
	var line: StyleBoxLine = StyleBoxLine.new()
	line.color = skin.outline
	line.thickness = maxi(1, roundi(skin.outline_w))
	theme.set_stylebox(&"separator", RULE, line)
	theme.set_constant(&"separation", RULE, maxi(1, roundi(skin.outline_w)))


static func _add_stat_bar(theme: Theme, skin: GameSkin) -> void:
	var track: PopBox = PopBox.new()
	track.face = skin.surface_alt_bg
	track.outline = skin.outline
	track.outline_w = skin.outline_w
	track.radius = skin.radius_control
	track.set_padding(0.0, STAT_BAR_H * 0.5, 0.0, STAT_BAR_H * 0.5)
	track.refresh()
	var fill: PopBox = PopBox.new()
	fill.face = skin.chart_bar
	fill.outline = skin.outline
	fill.outline_w = skin.outline_w
	fill.radius = skin.radius_control
	fill.refresh()
	theme.set_stylebox(&"background", STAT_BAR, track)
	theme.set_stylebox(&"fill", STAT_BAR, fill)
	theme.set_font(&"font", STAT_BAR, role_font(ROLE_CAPTION))
	theme.set_font_size(&"font_size", STAT_BAR, role_size(ROLE_CAPTION))
	theme.set_color(&"font_color", STAT_BAR, skin.text)
