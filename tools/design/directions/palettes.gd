extends RefCounted
## Design tokens for the three Phase 1 directions: colors for light and dark,
## shape tokens (line weights, radii, spacing) and type styles. Since Phase 2
## it also reads the final skins, pop_light and pop_dark, from their files in
## src/skins/ (see "Final skins" below).
##
## Every color, line weight, radius and font the Phase 1 prototypes draw with
## comes from this file. Never hardcode one. If you need a token that is not
## here, ask the senior-graphic-designer; do not invent it locally.
##
## Prototype data in tools/, never shipped. The final skin values are edited
## in docs/DESIGN_SYSTEM.md section 1 and written into src/skins/ by
## tools/design/write_skins.gd; this file holds no copy of them. The Phase 1
## "pop" palette is derived from the final skins (_POP_PHASE1), so the Phase 1
## prototypes draw Pop's final colors; Gridline and Pebble keep their Phase 1
## values. Owner: senior-graphic-designer.
##
## Usage:
##   const Palettes := preload("res://tools/design/directions/palettes.gd")
##   var colors: Palettes.Palette = Palettes.palette("pebble", dark)
##   var shape: Palettes.Shape = Palettes.shape("pebble")
##   var title: Palettes.TypeStyle = Palettes.type_style("pebble", Palettes.ROLE_TITLE)
##
## Sizes are design units: one unit is one pixel on a 1080 px wide phone
## (see device.gd). Board sizes are for a board drawn at shape.board_size;
## scale them by (drawn board side / board_size) when the board is drawn at
## another size.
##
## Contrast: tools/design/check_contrast.gd checks every foreground token
## against the backgrounds it may sit on. Draw a foreground only on the
## backgrounds listed for it there. Run the checker after any change here.

const Fonts := preload("res://tools/design/directions/fonts.gd")

const DIRECTIONS: Array[String] = ["gridline", "pebble", "pop"]

const DIRECTION_NAMES: Dictionary[String, String] = {
	"gridline": "Gridline",
	"pebble": "Pebble",
	"pop": "Pop",
}

## Board drawing styles.
const STYLE_LINES: String = "lines" ## Cells on a uniform pitch, separated by drawn lines.
const STYLE_TILES: String = "tiles" ## Rounded cell tiles on box cards on a tray, separated by gaps.

## Type roles.
const ROLE_DISPLAY: String = "display" ## Largest numbers: play timer, completion headline.
const ROLE_TITLE: String = "title" ## Screen and lesson titles.
const ROLE_BODY: String = "body" ## Running text: lesson text, explanations.
const ROLE_LABEL: String = "label" ## Small labels: HUD captions, table headers, step counter.
const ROLE_BUTTON: String = "button" ## Text on buttons, the mode toggle and chips.
const ROLE_HUD_VALUE: String = "hud_value" ## Values in the HUD and on stat cards.
const ROLE_PAD_DIGIT: String = "pad_digit" ## Digits on the number pad keys.
const ROLE_GIVEN: String = "given" ## Given digits. size is a share of the cell pitch.
const ROLE_PLACED: String = "placed" ## Placed digits. size is a share of the cell pitch.
const ROLE_CANDIDATE: String = "candidate" ## Candidates. size is a share of the ring layout's fitted size.

const ROLES: Array[String] = [
	ROLE_DISPLAY, ROLE_TITLE, ROLE_BODY, ROLE_LABEL, ROLE_BUTTON,
	ROLE_HUD_VALUE, ROLE_PAD_DIGIT, ROLE_GIVEN, ROLE_PLACED, ROLE_CANDIDATE,
]

## Board roles whose size is relative, not in design units.
const RELATIVE_ROLES: Array[String] = [ROLE_GIVEN, ROLE_PLACED, ROLE_CANDIDATE]


## Every color token. A Palette holds one direction in one mode.
class Palette extends RefCounted:
	var direction: String
	var dark: bool

	# Screen surfaces and text
	var app_bg: Color ## Screen background, edge to edge.
	var surface: Color ## Cards and panels: lesson text, stat cards, dialogs.
	var surface_alt: Color ## Secondary panels, table stripes, tracks.
	var text: Color ## Main text on app_bg, surface and surface_alt.
	var text_muted: Color ## Secondary text on the same backgrounds.
	var text_accent: Color ## Text in the accent hue on the same backgrounds.
	var accent: Color ## Main brand fill (bands, primary highlights).
	var text_on_accent: Color ## Text on accent.
	var accent_2: Color ## Second brand fill.
	var text_on_accent_2: Color ## Text on accent_2.
	var tag_bg: Color ## Level tag, chips, stickers.
	var tag_text: Color ## Text on tag_bg.
	var outline: Color ## Outlines of UI shapes (buttons, cards) where a direction draws them.
	var shadow: Color ## Drop or hard shadows. May be translucent. Not checked.
	var chart_bar: Color ## Graphic marks on the stats screen, on surface.
	var chart_bar_alt: Color ## Second graphic mark color, on surface.
	var celebrate_1: Color ## Decoration on the completion screen only. Not checked.
	var celebrate_2: Color ## Decoration on the completion screen only. Not checked.
	var celebrate_3: Color ## Decoration on the completion screen only. Not checked.

	# Board
	var board_bg: Color ## Behind the cells: the board frame or tray.
	var cell_bg: Color ## Plain empty or filled cell.
	var cell_selected_bg: Color ## The selected cell.
	var cell_peer_bg: Color ## Peers: cells in the selected cell's row, column and box.
	var cell_same_digit_bg: Color ## Cells holding the selected cell's digit (GDD 2.3).
	var cell_conflict_bg: Color ## Cells in a conflict, givens included (GDD 6).
	var cell_hint_target_bg: Color ## Hint target cells (GDD 10.2).
	var cell_hint_reason_bg: Color ## Hint reason cells, and cells a lesson screen marks.
	var digit_given: Color ## Given digits.
	var digit_placed: Color ## Digits the player placed.
	var digit_conflict: Color ## A digit in a conflict (given or placed).
	var candidate_open: Color ## Open candidates (and restored by hand, which look the same).
	var candidate_crossed: Color ## The digit under an X or an Auto Cross mark.
	var x_mark: Color ## The X over a candidate the player crossed by hand.
	var x_mark_auto: Color ## The mark over a candidate Auto Cross crossed (a single slash, see the briefs).
	var line_cell: Color ## Lines (or gaps) between cells.
	var line_box: Color ## Lines (or gutters) between 3 by 3 boxes.
	var line_outer: Color ## The board's outer edge.
	var selected_outline: Color ## Frame of the selected cell: solid in Place mode, dashed in Cross Out mode.
	var hint_target_marker: Color ## Corner brackets on hint target cells.
	var hint_reason_marker: Color ## Side ticks on hint reason cells.
	var conflict_marker: Color ## Bar under the digit of a conflict cell.

	# HUD
	var hud_bg: Color ## HUD band, chips or blocks.
	var hud_text: Color ## HUD values on hud_bg.
	var hud_label: Color ## HUD captions on hud_bg.
	var hud_accent_bg: Color ## Emphasized HUD block (score).
	var hud_accent_text: Color ## Text on hud_accent_bg.

	# Buttons
	var button_bg: Color
	var button_text: Color
	var button_primary_bg: Color ## Hint button, New puzzle, Next.
	var button_primary_text: Color
	var button_disabled_bg: Color ## Hint button the player cannot afford.
	var button_disabled_text: Color

	# Number pad and mode toggle
	var pad_bg: Color ## Behind the pad keys.
	var pad_key_place_bg: Color ## Pad key in Place mode.
	var pad_key_place_text: Color
	var pad_key_cross_bg: Color ## Pad key in Cross Out mode.
	var pad_key_cross_text: Color
	var pad_key_cross_mark: Color ## The cross mark drawn on keys in Cross Out mode.
	var mode_toggle_bg: Color ## Toggle track or inactive segment.
	var mode_toggle_text: Color ## Inactive segment label.
	var mode_toggle_active_bg: Color ## Active segment or thumb.
	var mode_toggle_active_text: Color ## Active segment label.


## Shape tokens for one direction, in design units at board_size. Same in
## light and dark.
class Shape extends RefCounted:
	var direction: String
	var style: String ## STYLE_LINES or STYLE_TILES.
	var board_size: float ## Side of the square board on the play screen.
	var board_pad: float ## Tiles: tray padding around the box cards.
	var box_gap: float ## Tiles: gutter between box cards.
	var cell_gap: float ## Tiles: gap between tiles, and card padding around them.
	var line_cell_w: float ## Lines: cell line weight.
	var line_box_w: float ## Lines: box line weight.
	var line_outer_w: float ## Lines: outer line weight, centered on the board edge.
	var cell_radius: float
	var box_radius: float
	var board_radius: float
	var ring_inset: float ## Distance from the cell's pitch rect (lines) or tile (tiles) to the ring box.
	var selected_outline_w: float ## Selection frame weight, centered on the cell edge.
	var selected_dash: float ## Cross Out mode: dash length of the selection frame.
	var selected_gap: float ## Cross Out mode: gap between dashes.
	var marker_w: float ## Weight of hint brackets and hint ticks, drawn just inside the selection frame band.
	var bracket_len: float ## Hint target bracket arm, as a share of the cell side.
	var tick_len: float ## Hint reason tick, as a share of the cell side.
	var conflict_bar_w: float ## Weight of the bar under a conflict digit.
	var conflict_bar_len: float ## Length of that bar, as a share of the cell side.
	var conflict_bar_y: float ## Center of that bar, as a share of the cell side from the cell's top edge.
	var x_stroke_w: float ## Stroke of the hand X and the Auto Cross slash.
	var x_size: float ## The hand X and the Auto Cross slash span this share of the slot box, centered, so neighbors never touch.
	## Candidates crossed by hand: the X is drawn first, then the digit on top
	## with an outline in the cell's background color, so the X stops just short
	## of the digit's strokes and the digit stays readable. This is the outline
	## size passed to draw_string_outline(), in design units: draw it at
	## maxi(1, roundi(crossed_halo_w * board scale)) pixels
	## (Fonts.draw_centered_outlined). The Auto Cross slash is a single stroke
	## and stays on top of its digit.
	var crossed_halo_w: float
	var round_caps: bool ## Round ends on the X, the slash, dashes, ticks, brackets and the conflict bar; square ends when false.
	var screen_margin: float ## Left and right screen margin.
	var space: float ## Base spacing step between blocks.
	var button_radius: float ## 999 means fully round (pill or circle).
	var key_radius: float
	var chip_radius: float
	var card_radius: float
	var outline_w: float ## UI outline weight, 0 for none.
	var shadow_offset: Vector2
	var shadow_blur: float ## 0 for a hard shadow.


## One type style. Sizes are design units, except for the board roles in
## RELATIVE_ROLES.
class TypeStyle extends RefCounted:
	var role: String
	var size: float
	var weight: int ## Fonts.Weight
	var caps: bool ## Set text in capitals.
	var tracking: float ## Extra space after each glyph, in units.
	var width: float ## Below 1.0 condenses the glyphs.

	## The font for this style at its own size.
	func font() -> Font:
		return Fonts.get_font(weight, tracking, width, size)

	## The font for this style at another size (board roles).
	func font_at(font_size: float) -> Font:
		return Fonts.get_font(weight, tracking, width, font_size)

	func font_size() -> int:
		return roundi(size)

	## Text as this style sets it.
	func apply(text: String) -> String:
		return text.to_upper() if caps else text


static var _palettes: Dictionary[String, Palette] = {}
static var _shapes: Dictionary[String, Shape] = {}
static var _types: Dictionary[String, TypeStyle] = {}


## The palette for a direction in light or dark mode.
static func palette(direction: String, dark: bool) -> Palette:
	var key: String = "%s|%s" % [direction, "dark" if dark else "light"]
	if _palettes.has(key):
		return _palettes[key]
	var result: Palette = Palette.new()
	result.direction = direction
	result.dark = dark
	if not DIRECTIONS.has(direction):
		push_error("Unknown direction: %s" % direction)
		return result
	var table: Dictionary = color_table(direction, dark)
	for token: String in color_tokens():
		if not table.has(token):
			push_error("%s is missing color token %s" % [key, token])
			result.set(token, Color.MAGENTA)
			continue
		var hex: String = table[token]
		result.set(token, Color.html(hex))
	_palettes[key] = result
	return result


## The shape tokens for a direction.
static func shape(direction: String) -> Shape:
	if _shapes.has(direction):
		return _shapes[direction]
	var result: Shape = Shape.new()
	result.direction = direction
	if not _SHAPES.has(direction):
		push_error("Unknown direction: %s" % direction)
		return result
	var table: Dictionary = _SHAPES[direction]
	for token: String in shape_tokens():
		if not table.has(token):
			push_error("%s is missing shape token %s" % [direction, token])
			continue
		result.set(token, table[token])
	_shapes[direction] = result
	return result


## The type style for a direction and role.
static func type_style(direction: String, role: String) -> TypeStyle:
	var key: String = "%s|%s" % [direction, role]
	if _types.has(key):
		return _types[key]
	var result: TypeStyle = TypeStyle.new()
	result.role = role
	if not _TYPE.has(direction) or not _TYPE[direction].has(role):
		push_error("Unknown type style: %s" % key)
		result.size = 32.0
		result.weight = Fonts.Weight.SEMIBOLD
		result.width = 1.0
		return result
	var row: Array = _TYPE[direction][role]
	result.size = row[0]
	result.weight = row[1]
	result.caps = row[2]
	result.tracking = row[3]
	result.width = row[4]
	_types[key] = result
	return result


## Names of every color token, in declaration order.
static func color_tokens() -> PackedStringArray:
	return _script_vars(Palette.new(), ["direction", "dark"])


## Names of every shape token, in declaration order.
static func shape_tokens() -> PackedStringArray:
	return _script_vars(Shape.new(), ["direction"])


## Raw hex table of one palette, for the docs and the checker. Pop's comes
## from the final skins through _POP_PHASE1.
static func color_table(direction: String, dark: bool) -> Dictionary:
	if direction == "pop":
		var skin_colors: Dictionary = skin_table("pop_dark" if dark else "pop_light")
		var table: Dictionary = {}
		for token: String in _POP_PHASE1:
			table[token] = skin_colors[_POP_PHASE1[token]]
		return table
	return _COLORS[direction]["dark" if dark else "light"]


static func _script_vars(object: Object, skip: Array[String]) -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	for info: Dictionary in object.get_property_list():
		var usage: int = info["usage"]
		var prop_name: String = info["name"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and not skip.has(prop_name):
			names.append(prop_name)
	return names


# Type table: role: [size, weight, caps, tracking, width]
const _TYPE: Dictionary = {
	"gridline": {
		ROLE_DISPLAY: [150.0, Fonts.Weight.BOLD, false, -4.0, 1.0],
		ROLE_TITLE: [64.0, Fonts.Weight.BOLD, false, -1.0, 1.0],
		ROLE_BODY: [40.0, Fonts.Weight.REGULAR, false, 0.0, 1.0],
		ROLE_LABEL: [28.0, Fonts.Weight.SEMIBOLD, true, 4.0, 1.0],
		ROLE_BUTTON: [32.0, Fonts.Weight.SEMIBOLD, true, 3.0, 1.0],
		ROLE_HUD_VALUE: [64.0, Fonts.Weight.BOLD, false, -1.0, 1.0],
		ROLE_PAD_DIGIT: [64.0, Fonts.Weight.MEDIUM, false, 0.0, 1.0],
		ROLE_GIVEN: [0.62, Fonts.Weight.BOLD, false, 0.0, 1.0],
		ROLE_PLACED: [0.62, Fonts.Weight.REGULAR, false, 0.0, 1.0],
		ROLE_CANDIDATE: [1.0, Fonts.Weight.MEDIUM, false, 0.0, 1.0],
	},
	"pebble": {
		ROLE_DISPLAY: [96.0, Fonts.Weight.BOLD, false, 0.0, 1.0],
		ROLE_TITLE: [60.0, Fonts.Weight.BOLD, false, 0.0, 1.0],
		ROLE_BODY: [42.0, Fonts.Weight.SEMIBOLD, false, 0.0, 1.0],
		ROLE_LABEL: [32.0, Fonts.Weight.SEMIBOLD, false, 0.0, 1.0],
		ROLE_BUTTON: [36.0, Fonts.Weight.BOLD, false, 0.0, 1.0],
		ROLE_HUD_VALUE: [44.0, Fonts.Weight.BOLD, false, 0.0, 1.0],
		ROLE_PAD_DIGIT: [64.0, Fonts.Weight.BOLD, false, 0.0, 1.0],
		ROLE_GIVEN: [0.60, Fonts.Weight.BOLD, false, 0.0, 1.0],
		ROLE_PLACED: [0.60, Fonts.Weight.MEDIUM, false, 0.0, 1.0],
		ROLE_CANDIDATE: [1.0, Fonts.Weight.SEMIBOLD, false, 0.0, 1.0],
	},
	"pop": {
		ROLE_DISPLAY: [140.0, Fonts.Weight.HEAVY, true, -2.0, 0.84],
		ROLE_TITLE: [72.0, Fonts.Weight.HEAVY, true, -1.0, 0.86],
		ROLE_BODY: [40.0, Fonts.Weight.SEMIBOLD, false, 0.0, 1.0],
		ROLE_LABEL: [28.0, Fonts.Weight.HEAVY, true, 2.0, 1.0],
		ROLE_BUTTON: [36.0, Fonts.Weight.HEAVY, true, 1.0, 1.0],
		ROLE_HUD_VALUE: [72.0, Fonts.Weight.HEAVY, false, -1.0, 0.86],
		ROLE_PAD_DIGIT: [72.0, Fonts.Weight.HEAVY, false, 0.0, 1.0],
		ROLE_GIVEN: [0.64, Fonts.Weight.HEAVY, false, 0.0, 1.0],
		ROLE_PLACED: [0.64, Fonts.Weight.SEMIBOLD, false, 0.0, 1.0],
		ROLE_CANDIDATE: [1.0, Fonts.Weight.SEMIBOLD, false, 0.0, 1.0],
	},
}


const _SHAPES: Dictionary = {
	"gridline": {
		"style": STYLE_LINES,
		"board_size": 1032.0,
		"board_pad": 0.0,
		"box_gap": 0.0,
		"cell_gap": 0.0,
		"line_cell_w": 2.0,
		"line_box_w": 6.0,
		"line_outer_w": 8.0,
		"cell_radius": 0.0,
		"box_radius": 0.0,
		"board_radius": 0.0,
		"ring_inset": 7.0,
		"selected_outline_w": 5.0,
		"selected_dash": 14.0,
		"selected_gap": 9.0,
		"marker_w": 3.0,
		"bracket_len": 0.3,
		"tick_len": 0.22,
		"conflict_bar_w": 6.0,
		"conflict_bar_len": 0.4,
		"conflict_bar_y": 0.84,
		"x_stroke_w": 3.0,
		"x_size": 0.8,
		"crossed_halo_w": 1.0,
		"round_caps": false,
		"screen_margin": 24.0,
		"space": 24.0,
		"button_radius": 0.0,
		"key_radius": 0.0,
		"chip_radius": 0.0,
		"card_radius": 0.0,
		"outline_w": 3.0,
		"shadow_offset": Vector2(0.0, 0.0),
		"shadow_blur": 0.0,
	},
	"pebble": {
		"style": STYLE_TILES,
		"board_size": 1048.0,
		"board_pad": 8.0,
		"box_gap": 10.0,
		"cell_gap": 4.0,
		"line_cell_w": 0.0,
		"line_box_w": 0.0,
		"line_outer_w": 0.0,
		"cell_radius": 10.0,
		"box_radius": 20.0,
		"board_radius": 32.0,
		"ring_inset": 6.0,
		"selected_outline_w": 3.0,
		"selected_dash": 7.0,
		"selected_gap": 7.0,
		"marker_w": 3.0,
		"bracket_len": 0.3,
		"tick_len": 0.22,
		"conflict_bar_w": 6.0,
		"conflict_bar_len": 0.4,
		"conflict_bar_y": 0.84,
		"x_stroke_w": 4.0,
		"x_size": 0.84,
		"crossed_halo_w": 1.0,
		"round_caps": true,
		"screen_margin": 16.0,
		"space": 24.0,
		"button_radius": 999.0,
		"key_radius": 999.0,
		"chip_radius": 999.0,
		"card_radius": 32.0,
		"outline_w": 0.0,
		# The soft shadow spreads shadow_blur around the shape, so it must not
		# be wider than screen_margin, or it is cut off at the screen edge.
		"shadow_offset": Vector2(0.0, 6.0),
		"shadow_blur": 16.0,
	},
	"pop": {
		"style": STYLE_LINES,
		"board_size": 1012.0,
		"board_pad": 0.0,
		"box_gap": 0.0,
		"cell_gap": 0.0,
		"line_cell_w": 2.0,
		"line_box_w": 6.0,
		"line_outer_w": 8.0,
		"cell_radius": 0.0,
		"box_radius": 0.0,
		"board_radius": 14.0,
		"ring_inset": 7.0,
		"selected_outline_w": 6.0,
		"selected_dash": 16.0,
		"selected_gap": 10.0,
		"marker_w": 3.0,
		"bracket_len": 0.3,
		"tick_len": 0.22,
		"conflict_bar_w": 7.0,
		"conflict_bar_len": 0.4,
		"conflict_bar_y": 0.84,
		"x_stroke_w": 4.0,
		"x_size": 0.8,
		"crossed_halo_w": 1.0,
		"round_caps": false,
		"screen_margin": 24.0,
		"space": 20.0,
		"button_radius": 14.0,
		"key_radius": 14.0,
		"chip_radius": 14.0,
		"card_radius": 18.0,
		"outline_w": 5.0,
		"shadow_offset": Vector2(12.0, 12.0),
		"shadow_blur": 0.0,
	},
}


const _COLORS: Dictionary = {
	"gridline": {
		"light": {
			"app_bg": "#F6F5F1",
			"surface": "#FFFFFF",
			"surface_alt": "#ECEBE5",
			"text": "#111111",
			"text_muted": "#55555E",
			"text_accent": "#2A3BD9",
			"accent": "#2A3BD9",
			"text_on_accent": "#FFFFFF",
			"accent_2": "#D63A1C",
			"text_on_accent_2": "#FFFFFF",
			"tag_bg": "#FFFFFF",
			"tag_text": "#2A3BD9",
			"outline": "#111111",
			"shadow": "#00000000",
			"chart_bar": "#2A3BD9",
			"chart_bar_alt": "#D63A1C",
			"celebrate_1": "#2A3BD9",
			"celebrate_2": "#E03E1E",
			"celebrate_3": "#FFC93C",
			"board_bg": "#FFFFFF",
			"cell_bg": "#FFFFFF",
			"cell_selected_bg": "#D9E0FF",
			"cell_peer_bg": "#EDF0FA",
			"cell_same_digit_bg": "#FFF0B3",
			"cell_conflict_bg": "#FFE1D8",
			"cell_hint_target_bg": "#CDEBD7",
			"cell_hint_reason_bg": "#E6F4EA",
			"digit_given": "#111111",
			"digit_placed": "#2A3BD9",
			"digit_conflict": "#A82410",
			"candidate_open": "#34343C",
			"candidate_crossed": "#74747E",
			"x_mark": "#E03E1E",
			"x_mark_auto": "#4E4E58",
			"line_cell": "#C6C6CC",
			"line_box": "#111111",
			"line_outer": "#111111",
			"selected_outline": "#2A3BD9",
			"hint_target_marker": "#1C7A3A",
			"hint_reason_marker": "#1C7A3A",
			"conflict_marker": "#BF2C12",
			"hud_bg": "#2A3BD9",
			"hud_text": "#FFFFFF",
			"hud_label": "#CBD2FF",
			"hud_accent_bg": "#FFFFFF",
			"hud_accent_text": "#2A3BD9",
			"button_bg": "#FFFFFF",
			"button_text": "#111111",
			"button_primary_bg": "#D63A1C",
			"button_primary_text": "#FFFFFF",
			"button_disabled_bg": "#ECEBE5",
			"button_disabled_text": "#85858C",
			"pad_bg": "#F6F5F1",
			"pad_key_place_bg": "#FFFFFF",
			"pad_key_place_text": "#111111",
			"pad_key_cross_bg": "#111111",
			"pad_key_cross_text": "#FFFFFF",
			"pad_key_cross_mark": "#FF6A4D",
			"mode_toggle_bg": "#ECEBE5",
			"mode_toggle_text": "#55555E",
			"mode_toggle_active_bg": "#111111",
			"mode_toggle_active_text": "#FFFFFF",
		},
		"dark": {
			"app_bg": "#111216",
			"surface": "#1A1B21",
			"surface_alt": "#24252C",
			"text": "#F2F2F4",
			"text_muted": "#A3A3AD",
			"text_accent": "#9AA6FF",
			"accent": "#3A4BE8",
			"text_on_accent": "#FFFFFF",
			"accent_2": "#FF6A4D",
			"text_on_accent_2": "#111111",
			"tag_bg": "#F2F2F4",
			"tag_text": "#1D2A9E",
			"outline": "#E6E6EA",
			"shadow": "#00000000",
			"chart_bar": "#9AA6FF",
			"chart_bar_alt": "#FF6A4D",
			"celebrate_1": "#3A4BE8",
			"celebrate_2": "#FF6A4D",
			"celebrate_3": "#FFC93C",
			"board_bg": "#16171C",
			"cell_bg": "#16171C",
			"cell_selected_bg": "#2A3478",
			"cell_peer_bg": "#1F2231",
			"cell_same_digit_bg": "#3A3414",
			"cell_conflict_bg": "#3D1B14",
			"cell_hint_target_bg": "#1B3D27",
			"cell_hint_reason_bg": "#15291C",
			"digit_given": "#F2F2F4",
			"digit_placed": "#9AA6FF",
			"digit_conflict": "#FF8A73",
			"candidate_open": "#C9C9D1",
			"candidate_crossed": "#8A8A94",
			"x_mark": "#FF6A4D",
			"x_mark_auto": "#A3A3AD",
			"line_cell": "#3A3B44",
			"line_box": "#E6E6EA",
			"line_outer": "#E6E6EA",
			"selected_outline": "#9AA6FF",
			"hint_target_marker": "#5FD08A",
			"hint_reason_marker": "#5FD08A",
			"conflict_marker": "#FF8A73",
			"hud_bg": "#1D2A9E",
			"hud_text": "#FFFFFF",
			"hud_label": "#C3CAFF",
			"hud_accent_bg": "#F2F2F4",
			"hud_accent_text": "#1D2A9E",
			"button_bg": "#1A1B21",
			"button_text": "#F2F2F4",
			"button_primary_bg": "#FF6A4D",
			"button_primary_text": "#111111",
			"button_disabled_bg": "#24252C",
			"button_disabled_text": "#7D7D86",
			"pad_bg": "#111216",
			"pad_key_place_bg": "#1A1B21",
			"pad_key_place_text": "#F2F2F4",
			"pad_key_cross_bg": "#F2F2F4",
			"pad_key_cross_text": "#111111",
			"pad_key_cross_mark": "#D63A1C",
			"mode_toggle_bg": "#24252C",
			"mode_toggle_text": "#A3A3AD",
			"mode_toggle_active_bg": "#F2F2F4",
			"mode_toggle_active_text": "#111216",
		},
	},
	"pebble": {
		"light": {
			"app_bg": "#FFF6EA",
			"surface": "#FFFFFF",
			"surface_alt": "#F1EDFF",
			"text": "#1D1846",
			"text_muted": "#5A5582",
			"text_accent": "#4B3BE0",
			"accent": "#6656F5",
			"text_on_accent": "#FFFFFF",
			"accent_2": "#FF8A3D",
			"text_on_accent_2": "#1D1846",
			"tag_bg": "#BFF0D8",
			"tag_text": "#1D1846",
			"outline": "#1D1846",
			"shadow": "#1D18462E",
			"chart_bar": "#6656F5",
			"chart_bar_alt": "#E8691C",
			"celebrate_1": "#FFD443",
			"celebrate_2": "#FF5C8A",
			"celebrate_3": "#6656F5",
			"board_bg": "#6656F5",
			"cell_bg": "#FFFFFF",
			"cell_selected_bg": "#FFD443",
			"cell_peer_bg": "#FFF1C4",
			"cell_same_digit_bg": "#FFE0EC",
			"cell_conflict_bg": "#FFD5D9",
			"cell_hint_target_bg": "#C4EEDB",
			"cell_hint_reason_bg": "#E3F7EE",
			"digit_given": "#1D1846",
			"digit_placed": "#4B3BE0",
			"digit_conflict": "#A8152F",
			"candidate_open": "#36305E",
			"candidate_crossed": "#736E96",
			"x_mark": "#CF1D62",
			"x_mark_auto": "#6C6790",
			"line_cell": "#E6E1FF",
			"line_box": "#6656F5",
			"line_outer": "#6656F5",
			"selected_outline": "#1D1846",
			"hint_target_marker": "#0E7A4E",
			"hint_reason_marker": "#0E7A4E",
			"conflict_marker": "#BE1E3A",
			"hud_bg": "#FFFFFF",
			"hud_text": "#1D1846",
			"hud_label": "#5A5582",
			"hud_accent_bg": "#FF8A3D",
			"hud_accent_text": "#1D1846",
			"button_bg": "#FFFFFF",
			"button_text": "#1D1846",
			"button_primary_bg": "#FF8A3D",
			"button_primary_text": "#1D1846",
			"button_disabled_bg": "#EEEAF6",
			"button_disabled_text": "#87839F",
			"pad_bg": "#6656F5",
			"pad_key_place_bg": "#FFFFFF",
			"pad_key_place_text": "#1D1846",
			"pad_key_cross_bg": "#FFD443",
			"pad_key_cross_text": "#1D1846",
			"pad_key_cross_mark": "#CF1D62",
			"mode_toggle_bg": "#ECE7FF",
			"mode_toggle_text": "#5A5582",
			"mode_toggle_active_bg": "#1D1846",
			"mode_toggle_active_text": "#FFFFFF",
		},
		"dark": {
			"app_bg": "#15122B",
			"surface": "#211D3D",
			"surface_alt": "#2B2650",
			"text": "#F4F2FF",
			"text_muted": "#ABA6D1",
			"text_accent": "#B8B0FF",
			"accent": "#8C80FF",
			"text_on_accent": "#15122B",
			"accent_2": "#FF9A57",
			"text_on_accent_2": "#15122B",
			"tag_bg": "#7FE0B4",
			"tag_text": "#15122B",
			"outline": "#F4F2FF",
			"shadow": "#00000066",
			"chart_bar": "#8C80FF",
			"chart_bar_alt": "#FF9A57",
			"celebrate_1": "#FFD443",
			"celebrate_2": "#FF5C9A",
			"celebrate_3": "#8C80FF",
			"board_bg": "#7E70FF",
			"cell_bg": "#221E40",
			"cell_selected_bg": "#3F3488",
			"cell_peer_bg": "#2C2752",
			"cell_same_digit_bg": "#47233F",
			"cell_conflict_bg": "#4A1E2A",
			"cell_hint_target_bg": "#173E34",
			"cell_hint_reason_bg": "#163430",
			"digit_given": "#F4F2FF",
			"digit_placed": "#B8B0FF",
			"digit_conflict": "#FF8FA3",
			"candidate_open": "#DAD6F5",
			"candidate_crossed": "#8D88B3",
			"x_mark": "#FF5C9A",
			"x_mark_auto": "#9C97C2",
			"line_cell": "#34305A",
			"line_box": "#7E70FF",
			"line_outer": "#7E70FF",
			"selected_outline": "#FFD443",
			"hint_target_marker": "#4FD6A0",
			"hint_reason_marker": "#4FD6A0",
			"conflict_marker": "#FF8FA3",
			"hud_bg": "#211D3D",
			"hud_text": "#F4F2FF",
			"hud_label": "#ABA6D1",
			"hud_accent_bg": "#FF9A57",
			"hud_accent_text": "#15122B",
			"button_bg": "#2B2650",
			"button_text": "#F4F2FF",
			"button_primary_bg": "#FFD443",
			"button_primary_text": "#15122B",
			"button_disabled_bg": "#2B2650",
			"button_disabled_text": "#8A85B0",
			"pad_bg": "#2B2650",
			"pad_key_place_bg": "#3A3466",
			"pad_key_place_text": "#F4F2FF",
			"pad_key_cross_bg": "#FFD443",
			"pad_key_cross_text": "#15122B",
			"pad_key_cross_mark": "#C2185B",
			"mode_toggle_bg": "#211D3D",
			"mode_toggle_text": "#ABA6D1",
			"mode_toggle_active_bg": "#FFD443",
			"mode_toggle_active_text": "#15122B",
		},
	},
	# Pop's Phase 1 palette is derived from the final skins: see _POP_PHASE1.
}


# Final skins
#
# The two built-in skins live in src/skins/pop_light.tres and pop_dark.tres
# (script class GameSkin, docs/ARCHITECTURE.md section 6). Their values are
# the tables of docs/DESIGN_SYSTEM.md section 1, written into the files by
# tools/design/write_skins.gd. This file only reads them: for the checker,
# the studies, and Pop's Phase 1 prototype colors (_POP_PHASE1).

## The built-in skins, in display order. pop_light is the default.
const SKIN_IDS: Array[String] = ["pop_light", "pop_dark"]

const SKIN_IDENTITY_FIELDS: Array[String] = ["id", "display_name", "is_dark"]


## Path of a skin file.
static func skin_path(id: String) -> String:
	return "res://src/skins/%s.tres" % id


## A final skin by id ("pop_light" or "pop_dark"), loaded from its file.
## Null if the file is missing or is not a GameSkin.
static func skin(id: String) -> GameSkin:
	if not SKIN_IDS.has(id):
		push_error("Unknown skin: %s" % id)
		return null
	var path: String = skin_path(id)
	if not ResourceLoader.exists(path):
		push_error("Missing skin file %s; run tools/design/write_skins.gd" % path)
		return null
	return load(path) as GameSkin


## Names of every skin token, in GameSkin's (and the table's) order.
static func skin_tokens() -> PackedStringArray:
	return _script_vars(GameSkin.new(), SKIN_IDENTITY_FIELDS.duplicate())


## "Color" or "float", as GameSkin declares it.
static func skin_token_type(token: String) -> String:
	for info: Dictionary in GameSkin.new().get_property_list():
		if info["name"] == token:
			var kind: int = info["type"]
			return "Color" if kind == TYPE_COLOR else ("float" if kind == TYPE_FLOAT else "")
	return ""


## Raw values of one skin: "#RRGGBB" (or "#RRGGBBAA" when translucent) for
## each color, a float for each number.
static func skin_table(id: String) -> Dictionary:
	var table: Dictionary = {}
	var loaded: GameSkin = skin(id)
	if loaded == null:
		return table
	for token: String in skin_tokens():
		var value: Variant = loaded.get(token)
		if value is Color:
			var color: Color = value
			table[token] = "#" + color.to_html(color.a < 1.0).to_upper()
		else:
			table[token] = value
	return table


## Phase 1 Pop token -> final skin token. The Phase 1 prototypes keep drawing
## from Palette; for Pop they now get the final colors. Phase 1 shapes and
## type for Pop are unchanged (they are in design units, not dp).
const _POP_PHASE1: Dictionary[String, String] = {
	"app_bg": "page_bg",
	"surface": "surface_bg",
	"surface_alt": "surface_alt_bg",
	"text": "text",
	"text_muted": "text_muted",
	"text_accent": "text_accent",
	"accent": "button_primary_bg",
	"text_on_accent": "button_primary_text",
	"accent_2": "celebrate_bg",
	"text_on_accent_2": "celebrate_text",
	"tag_bg": "sticker_bg",
	"tag_text": "sticker_text",
	"outline": "outline",
	"shadow": "shadow",
	"chart_bar": "chart_bar",
	"chart_bar_alt": "cross_mark_hand",
	"celebrate_1": "celebrate_bg",
	"celebrate_2": "sticker_bg",
	"celebrate_3": "digit_placed",
	"board_bg": "board_bg",
	"cell_bg": "cell_bg",
	"cell_selected_bg": "cell_selected_bg",
	"cell_peer_bg": "cell_peer_bg",
	"cell_same_digit_bg": "cell_same_digit_bg",
	"cell_conflict_bg": "cell_conflict_bg",
	"cell_hint_target_bg": "cell_hint_target_bg",
	"cell_hint_reason_bg": "cell_hint_reason_bg",
	"digit_given": "digit_given",
	"digit_placed": "digit_placed",
	"digit_conflict": "digit_conflict",
	"candidate_open": "candidate_open",
	"candidate_crossed": "candidate_crossed",
	"x_mark": "cross_mark_hand",
	"x_mark_auto": "cross_mark_auto",
	"line_cell": "line_cell",
	"line_box": "line_box",
	"line_outer": "line_outer",
	"selected_outline": "selection_frame_place",
	"hint_target_marker": "hint_target_mark",
	"hint_reason_marker": "hint_reason_mark",
	"conflict_marker": "conflict_mark",
	"hud_bg": "hud_bg",
	"hud_text": "hud_text",
	"hud_label": "hud_label",
	"hud_accent_bg": "hud_score_bg",
	"hud_accent_text": "hud_score_text",
	"button_bg": "button_bg",
	"button_text": "button_text",
	"button_primary_bg": "button_primary_bg",
	"button_primary_text": "button_primary_text",
	"button_disabled_bg": "button_disabled_bg",
	"button_disabled_text": "button_disabled_text",
	"pad_bg": "page_bg",
	"pad_key_place_bg": "pad_key_place_bg",
	"pad_key_place_text": "pad_key_place_text",
	"pad_key_cross_bg": "pad_key_cross_bg",
	"pad_key_cross_text": "pad_key_cross_text",
	"pad_key_cross_mark": "pad_key_cross_mark",
	"mode_toggle_bg": "mode_toggle_bg",
	"mode_toggle_text": "mode_toggle_text",
	"mode_toggle_active_bg": "mode_toggle_active_bg",
	"mode_toggle_active_text": "mode_toggle_active_text",
}
