extends RefCounted
## Fonts for the Phase 1 design prototypes. Every font a prototype draws with
## comes from here, so the capture tool can switch the whole set to Inter for
## the Hard Stop 1 font comparison. Prototype code in tools/, never shipped.
## Owner: senior-graphic-designer.
##
## The default family is Godot's built-in font (Open Sans SemiBold, compiled
## into the engine, no file in the repo). Weights are made from it with
## FontVariation.variation_embolden.
##
## The "inter" family reads the Inter files from build/font_compare/ with
## FileAccess and FontFile.data. The files are never imported or copied, and
## nothing outside tools/design/ may load them.

enum Weight { REGULAR, MEDIUM, SEMIBOLD, BOLD, HEAVY }

const FAMILY_DEFAULT: String = "default"
const FAMILY_INTER: String = "inter"

const INTER_DIR: String = "res://build/font_compare/"

## Inter file per weight. HEAVY uses Bold plus a little embolden.
const _INTER_FILES: Dictionary[int, String] = {
	Weight.REGULAR: "Inter-Regular.ttf",
	Weight.MEDIUM: "Inter-Medium.ttf",
	Weight.SEMIBOLD: "Inter-SemiBold.ttf",
	Weight.BOLD: "Inter-Bold.ttf",
	Weight.HEAVY: "Inter-Bold.ttf",
}

## Embolden per weight on the default font, which is SemiBold to start with.
const _DEFAULT_EMBOLDEN: Dictionary[int, float] = {
	Weight.REGULAR: -0.4,
	Weight.MEDIUM: -0.2,
	Weight.SEMIBOLD: 0.0,
	Weight.BOLD: 0.5,
	Weight.HEAVY: 0.9,
}

const _INTER_EXTRA_EMBOLDEN: Dictionary[int, float] = {
	Weight.HEAVY: 0.4,
}

## Average advance of a glyph as a share of the font size, used to pull the
## letters together again when a style is condensed with a transform.
const _AVERAGE_ADVANCE: float = 0.55

static var _family: String = FAMILY_DEFAULT
static var _default_font: Font = null
static var _inter_files: Dictionary[String, FontFile] = {}
static var _variations: Dictionary[String, FontVariation] = {}
static var _ink_cache: Dictionary[String, Rect2] = {}


## Switches every font this file hands out to the given family.
## Returns false (and keeps the current family) if Inter cannot be read.
static func set_family(family: String) -> bool:
	default_font()
	if family == FAMILY_INTER:
		for weight: int in _INTER_FILES:
			if _inter_file(_INTER_FILES[weight]) == null:
				return false
	elif family != FAMILY_DEFAULT:
		push_error("Unknown font family: %s" % family)
		return false
	_family = family
	_variations.clear()
	_ink_cache.clear()
	return true


static func family() -> String:
	return _family


## Godot's built-in font, remembered the first time it is asked for, so it
## survives the capture tool pointing ThemeDB.fallback_font at Inter.
static func default_font() -> Font:
	if _default_font == null:
		_default_font = ThemeDB.fallback_font
	return _default_font


## A font of the given weight. tracking is extra space after every glyph in
## pixels at the size the text is drawn. width below 1.0 condenses the glyphs;
## pass the font size you draw at so the spacing can be pulled in to match.
static func get_font(weight: Weight, tracking: float = 0.0, width: float = 1.0, size_for_width: float = 0.0) -> Font:
	var spacing: int = roundi(tracking)
	if width < 1.0 and size_for_width > 0.0:
		spacing -= roundi(_AVERAGE_ADVANCE * size_for_width * (1.0 - width))
	var key: String = "%s|%d|%d|%.3f" % [_family, weight, spacing, width]
	if _variations.has(key):
		return _variations[key]
	var variation: FontVariation = FontVariation.new()
	if _family == FAMILY_INTER:
		variation.base_font = _inter_file(_INTER_FILES[weight])
		variation.variation_embolden = _INTER_EXTRA_EMBOLDEN.get(weight, 0.0)
		# Inter's default digits are proportional; tabular digits keep timers
		# and scores from jumping as they change.
		var server: TextServer = TextServerManager.get_primary_interface()
		variation.opentype_features = {server.name_to_tag("tnum"): 1}
	else:
		variation.base_font = default_font()
		variation.variation_embolden = _DEFAULT_EMBOLDEN[weight]
	variation.spacing_glyph = spacing
	if width < 1.0:
		variation.variation_transform = Transform2D(Vector2(width, 0.0), Vector2(0.0, 1.0), Vector2.ZERO)
	_variations[key] = variation
	return variation


## The ink box of text drawn at font_size, relative to the baseline origin
## that draw_string() takes. Measured from the glyph outlines, so a digit can
## be centered on its visible shape rather than on its line box.
static func ink_box(font: Font, font_size: int, text: String) -> Rect2:
	var key: String = "%d|%d|%s" % [font.get_instance_id(), font_size, text]
	if _ink_cache.has(key):
		return _ink_cache[key]
	var server: TextServer = TextServerManager.get_primary_interface()
	var rids: Array[RID] = font.get_rids()
	var box: Rect2 = Rect2()
	var has_box: bool = false
	var pen_x: float = 0.0
	for i: int in text.length():
		var code: int = text.unicode_at(i)
		var rid: RID = RID()
		var glyph: int = 0
		for candidate: RID in rids:
			glyph = server.font_get_glyph_index(candidate, font_size, code, 0)
			if glyph != 0:
				rid = candidate
				break
		if not rid.is_valid():
			pen_x += font.get_char_size(code, font_size).x
			continue
		var size_key: Vector2i = Vector2i(font_size, 0)
		var offset: Vector2 = server.font_get_glyph_offset(rid, size_key, glyph)
		var glyph_size: Vector2 = server.font_get_glyph_size(rid, size_key, glyph)
		var advance: Vector2 = server.font_get_glyph_advance(rid, font_size, glyph)
		if glyph_size.x > 0.0 and glyph_size.y > 0.0:
			var glyph_box: Rect2 = Rect2(Vector2(pen_x, 0.0) + offset, glyph_size)
			box = glyph_box if not has_box else box.merge(glyph_box)
			has_box = true
		pen_x += advance.x
	if not has_box:
		var line_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		box = Rect2(0.0, -font.get_ascent(font_size), line_size.x, line_size.y)
	_ink_cache[key] = box
	return box


## Draws text so the center of its ink box lands on center. Use it for
## digits on the board, where the line box would put them off center.
static func draw_centered(canvas: CanvasItem, font: Font, font_size: int, text: String, center: Vector2, color: Color) -> void:
	var box: Rect2 = ink_box(font, font_size, text)
	var origin: Vector2 = center - box.get_center()
	canvas.draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## Like draw_centered(), with an outline drawn first: outline_size pixels
## around every stroke, in outline_color. The board draws a crossed candidate
## with it on top of its mark, with outline_color set to the cell's
## background, so the mark stops just short of the digit's strokes and both
## stay readable.
static func draw_centered_outlined(canvas: CanvasItem, font: Font, font_size: int, text: String, center: Vector2, color: Color, outline_size: int, outline_color: Color) -> void:
	var box: Rect2 = ink_box(font, font_size, text)
	var origin: Vector2 = center - box.get_center()
	if outline_size > 0:
		canvas.draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
	canvas.draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## Size of the widest and the tallest ink box among the digits 1 to 9.
## The ring layouts use it to fit and space candidates.
static func digit_cell(font: Font, font_size: int) -> Vector2:
	var widest: float = 0.0
	var tallest: float = 0.0
	for digit: int in range(1, 10):
		var box: Rect2 = ink_box(font, font_size, str(digit))
		widest = maxf(widest, box.size.x)
		tallest = maxf(tallest, box.size.y)
	return Vector2(widest, tallest)


static func _inter_file(file_name: String) -> FontFile:
	if _inter_files.has(file_name):
		return _inter_files[file_name]
	var path: String = INTER_DIR + file_name
	if not FileAccess.file_exists(path):
		push_error("Inter is missing: %s (see build/font_compare/README.txt)" % path)
		return null
	var font: FontFile = FontFile.new()
	font.data = FileAccess.get_file_as_bytes(path)
	_inter_files[file_name] = font
	return font
