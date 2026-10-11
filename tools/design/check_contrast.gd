extends SceneTree
## Contrast checker for the Phase 1 design directions.
##
##   timeout 300 godot --headless --path . --script res://tools/design/check_contrast.gd
##
## For every direction in light and dark it computes the WCAG 2 contrast
## ratio of each foreground token against every background it can sit on,
## prints one line per pair, and exits with 1 if any pair misses its target.
## It also checks that every palette defines every token, that checked colors
## are opaque, and the minimum sizes at the smallest board we support.
##
## Targets: digits and text 4.5:1; open candidates 4.5:1; the X on a crossed
## candidate 3:1 (brief, sections 3 and 8). Our own additions: the digit
## under an X 3:1, so it stays readable; outlines, markers, box lines and
## chart marks 3:1 (WCAG non-text contrast); disabled button text 3:1 (WCAG
## exempts it, we still want it legible); cell lines 1.2:1 (quiet structure,
## the box lines carry the grouping).
##
## Contrast ratios do not depend on size, so one check covers every board
## size. The size checks below cover the smallest board.
## Owner: senior-graphic-designer.

const Palettes := preload("res://tools/design/directions/palettes.gd")
const RingLayouts := preload("res://tools/design/directions/ring_layouts.gd")
const Fonts := preload("res://tools/design/directions/fonts.gd")
const Device := preload("res://tools/design/directions/device.gd")

## Every background a cell can have (sample_state.gd CellBg).
const CELL_BGS: Array[String] = [
	"cell_bg", "cell_selected_bg", "cell_peer_bg", "cell_same_digit_bg",
	"cell_conflict_bg", "cell_hint_target_bg", "cell_hint_reason_bg",
]
const TEXT_BGS: Array[String] = ["app_bg", "surface", "surface_alt"]

## [foreground, backgrounds, target, what it is]
## Marks are checked against every background their cell can have under the
## background priority: a hint target can also be selected or in conflict, and
## so on. The selection frame straddles the cell edge, so it is checked
## against every cell background its neighbors can have.
const RULES: Array = [
	["digit_given", CELL_BGS, 4.5, "digit"],
	["digit_placed", CELL_BGS, 4.5, "digit"],
	["digit_conflict", CELL_BGS, 4.5, "digit"],
	["candidate_open", CELL_BGS, 4.5, "open candidate"],
	["candidate_crossed", CELL_BGS, 3.0, "digit under an X"],
	["x_mark", CELL_BGS, 3.0, "hand X"],
	["x_mark_auto", CELL_BGS, 3.0, "Auto Cross mark"],
	["selected_outline", CELL_BGS, 3.0, "selection frame"],
	["hint_target_marker", ["cell_hint_target_bg", "cell_selected_bg", "cell_conflict_bg"], 3.0, "hint target mark"],
	["hint_reason_marker", ["cell_hint_reason_bg", "cell_selected_bg", "cell_conflict_bg"], 3.0, "hint reason mark"],
	["conflict_marker", ["cell_conflict_bg", "cell_selected_bg"], 3.0, "conflict mark"],
	["line_box", ["cell_bg", "cell_peer_bg"], 3.0, "box line"],
	["line_outer", ["cell_bg", "cell_peer_bg", "app_bg"], 3.0, "outer line"],
	["line_cell", ["cell_bg"], 1.2, "cell line"],
	["text", TEXT_BGS, 4.5, "text"],
	["text_muted", TEXT_BGS, 4.5, "text"],
	["text_accent", TEXT_BGS, 4.5, "text"],
	["text_on_accent", ["accent"], 4.5, "text"],
	["text_on_accent_2", ["accent_2"], 4.5, "text"],
	["tag_text", ["tag_bg"], 4.5, "text"],
	["outline", ["app_bg", "surface"], 3.0, "UI outline"],
	["chart_bar", ["surface"], 3.0, "chart mark"],
	["chart_bar_alt", ["surface"], 3.0, "chart mark"],
	["hud_text", ["hud_bg"], 4.5, "text"],
	["hud_label", ["hud_bg"], 4.5, "text"],
	["hud_accent_text", ["hud_accent_bg"], 4.5, "text"],
	["button_text", ["button_bg"], 4.5, "text"],
	["button_primary_text", ["button_primary_bg"], 4.5, "text"],
	["button_disabled_text", ["button_disabled_bg"], 3.0, "disabled text"],
	["pad_key_place_text", ["pad_key_place_bg"], 4.5, "digit"],
	["pad_key_cross_text", ["pad_key_cross_bg"], 4.5, "digit"],
	["pad_key_cross_mark", ["pad_key_cross_bg"], 3.0, "cross mark"],
	["mode_toggle_text", ["mode_toggle_bg"], 4.5, "text"],
	["mode_toggle_active_text", ["mode_toggle_active_bg"], 4.5, "text"],
]

## Tokens that may be translucent or are decoration only.
const UNCHECKED: Array[String] = ["shadow", "celebrate_1", "celebrate_2", "celebrate_3", "board_bg", "pad_bg"]

## Minimum sizes on the smallest phone we support.
const MIN_CANDIDATE_DP: float = 9.0 ## Candidate font size, in dp.
const MIN_X_STROKE_PX: float = 1.5 ## X stroke, in device pixels at 720 px wide.
const MIN_CELL_LINE_PX: float = 1.0 ## Cell line, in device pixels at 720 px wide.
const MIN_BOX_TO_CELL_WEIGHT: float = 2.5 ## Box separation / cell separation.


func _initialize() -> void:
	var result: Variant = call("_run")
	quit(result if result is int else 1)


func _run() -> int:
	var total: int = 0
	var failed: int = 0
	print("Contrast check, Phase 1 directions (WCAG 2 contrast ratio)")
	print("")
	for direction: String in Palettes.DIRECTIONS:
		for dark: bool in [false, true]:
			var mode: String = "dark" if dark else "light"
			print("%s %s" % [direction, mode])
			var problems: PackedStringArray = _check_table(direction, dark)
			for problem: String in problems:
				print("  FAIL  %s" % problem)
			total += problems.size()
			failed += problems.size()
			var colors: Palettes.Palette = Palettes.palette(direction, dark)
			for rule: Array in RULES:
				var fg_name: String = rule[0]
				var bg_names: Array = rule[1]
				var target: float = rule[2]
				var kind: String = rule[3]
				for bg_name: String in bg_names:
					var fg: Color = colors.get(fg_name)
					var bg: Color = colors.get(bg_name)
					var ratio: float = contrast(fg, bg)
					var ok: bool = ratio >= target and fg.a >= 1.0 and bg.a >= 1.0
					total += 1
					if not ok:
						failed += 1
					print("  %s  %5.2f  >= %.1f  %-24s on %-20s (%s)" % ["PASS" if ok else "FAIL", ratio, target, fg_name, bg_name, kind])
			print("")

	print("Size checks at the smallest board (%d dp phone, %d px wide)" % [int(Device.SMALLEST_PHONE_DP_WIDTH), int(Device.SMALLEST_PHONE_PX_WIDTH)])
	for direction: String in Palettes.DIRECTIONS:
		var size_problems: PackedStringArray = _check_sizes(direction)
		total += 1
		if size_problems.is_empty():
			print("  PASS  %s" % direction)
		else:
			failed += 1
			for problem: String in size_problems:
				print("  FAIL  %s: %s" % [direction, problem])
	print("")
	print("Pairs and checks: %d, passed: %d, failed: %d" % [total, total - failed, failed])
	return 0 if failed == 0 else 1


## Every token present, no unknown tokens, checked colors opaque and valid.
func _check_table(direction: String, dark: bool) -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	var table: Dictionary = Palettes.color_table(direction, dark)
	var tokens: PackedStringArray = Palettes.color_tokens()
	for token: String in tokens:
		if not table.has(token):
			problems.append("missing token %s" % token)
			continue
		var hex: String = table[token]
		if not Color.html_is_valid(hex):
			problems.append("%s is not a color: %s" % [token, hex])
		elif not UNCHECKED.has(token) and Color.html(hex).a < 1.0:
			problems.append("%s must be opaque: %s" % [token, hex])
	for key: String in table:
		if not tokens.has(key):
			problems.append("unknown token %s" % key)
	return problems


func _check_sizes(direction: String) -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	var shape: Palettes.Shape = Palettes.shape(direction)
	var font: Font = Palettes.type_style(direction, Palettes.ROLE_CANDIDATE).font_at(40.0)
	var ring: float = RingLayouts.ring_side(direction)
	for layout: int in RingLayouts.COUNT:
		var size_units: float = float(RingLayouts.candidate_font_size(direction, layout, ring, font))
		var size_dp: float = Device.units_to_dp(size_units, Device.SMALLEST_PHONE_DP_WIDTH)
		if size_dp < MIN_CANDIDATE_DP:
			problems.append("%s candidates are %.1f dp, below %.1f dp" % [RingLayouts.SLUGS[layout], size_dp, MIN_CANDIDATE_DP])
	var x_px: float = Device.units_to_px(shape.x_stroke_w, Device.SMALLEST_PHONE_PX_WIDTH)
	if x_px < MIN_X_STROKE_PX:
		problems.append("X stroke is %.2f px, below %.1f px" % [x_px, MIN_X_STROKE_PX])
	var cell_separation: float
	var box_separation: float
	if shape.style == Palettes.STYLE_TILES:
		cell_separation = shape.cell_gap
		box_separation = shape.box_gap + 2.0 * shape.cell_gap
	else:
		cell_separation = shape.line_cell_w
		box_separation = shape.line_box_w
	var line_px: float = Device.units_to_px(cell_separation, Device.SMALLEST_PHONE_PX_WIDTH)
	if line_px < MIN_CELL_LINE_PX:
		problems.append("cell separation is %.2f px, below %.1f px" % [line_px, MIN_CELL_LINE_PX])
	if box_separation < MIN_BOX_TO_CELL_WEIGHT * cell_separation:
		problems.append("box separation %.1f is not %.1f times the cell separation %.1f" % [box_separation, MIN_BOX_TO_CELL_WEIGHT, cell_separation])
	return problems


## WCAG 2 contrast ratio of two opaque colors.
static func contrast(a: Color, b: Color) -> float:
	var la: float = luminance(a)
	var lb: float = luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## WCAG 2 relative luminance of an sRGB color.
static func luminance(c: Color) -> float:
	return 0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b)


static func _channel(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
