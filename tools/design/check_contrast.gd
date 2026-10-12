extends SceneTree
## Contrast checker for the final skins and the Phase 1 design directions.
##
##   timeout 300 godot --headless --path . --script res://tools/design/check_contrast.gd
##
## Part 1, the final skins: src/skins/pop_light.tres and pop_dark.tres, loaded
## as GameSkin. Every pair in SKIN_RULES, the marks that must differ in color
## (SKIN_TOLD_APART), each file setting every property with opaque colors, the
## sizes on the phone readability is judged on, and that the two tables in
## docs/DESIGN_SYSTEM.md section 1 match the files exactly (names, order,
## types and values). Edit values in the doc, then run write_skins.gd.
##
## Part 2, the Phase 1 record: for every direction in light and dark it
## computes the WCAG 2 contrast
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
## the box lines carry the grouping). Marks that touch on the board (the
## selection frame, hint marks, box and outer lines) must also differ in color
## (TOLD_APART), and a soft shadow must fit inside the screen margin.
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
# The contrast ratio is symmetric, so each pair also covers the reverse
# drawing order: Pebble's pad badge draws pad_key_cross_bg on a
# pad_key_cross_mark disc, which the pad_key_cross_mark rule above covers.

## Marks that touch or overlap on the board must differ in color as well as
## shape, or they fuse into one shape: the selection frame's dashes sit on box
## and outer lines, the hint brackets and ticks sit against the frame, and the
## ticks touch box and outer lines. [token, other tokens, what it is]
const TOLD_APART: Array = [
	["selected_outline", ["line_box", "line_outer"], "selection frame on a box line"],
	["hint_target_marker", ["selected_outline", "line_box", "line_outer"], "hint target mark"],
	["hint_reason_marker", ["selected_outline", "line_box", "line_outer"], "hint reason mark"],
]
## Smallest distance between two such colors, as the length of their RGB
## difference with channels from 0 to 1. Contrast ratio alone cannot judge
## this, because two hues of equal lightness are easy to tell apart.
const MIN_COLOR_DISTANCE: float = 0.3

## Tokens that may be translucent or are decoration only.
const UNCHECKED: Array[String] = ["shadow", "celebrate_1", "celebrate_2", "celebrate_3", "board_bg", "pad_bg"]

## Minimum sizes on the smallest phone we support.
const MIN_CANDIDATE_DP: float = 9.0 ## Candidate font size, in dp.
const MIN_X_STROKE_PX: float = 1.5 ## X stroke, in device pixels at 720 px wide.
const MIN_CELL_LINE_PX: float = 1.0 ## Cell line, in device pixels at 720 px wide.
const MIN_BOX_TO_CELL_WEIGHT: float = 2.5 ## Box separation / cell separation.


# Final skins

const DESIGN_SYSTEM_PATH: String = "res://docs/DESIGN_SYSTEM.md"

## Every fill a cell holding a digit can have.
const DIGIT_FILLS: Array[String] = [
	"cell_bg", "cell_selected_bg", "cell_peer_bg", "cell_same_digit_bg",
	"cell_conflict_bg", "cell_hint_target_bg", "cell_hint_reason_bg",
]
## Every fill a cell showing its ring can have. Same digit and conflict only
## ever fill cells that hold a digit, and those hide their ring.
const RING_FILLS: Array[String] = [
	"cell_bg", "cell_selected_bg", "cell_peer_bg", "cell_hint_target_bg", "cell_hint_reason_bg",
]
const PAGE_BGS: Array[String] = ["page_bg", "surface_bg", "surface_alt_bg"]

## [foreground, backgrounds, target, what it is]. Frame, hint marks and lines
## sit on the cell edge, so they meet the fills of both cells beside it.
const SKIN_RULES: Array = [
	["digit_given", DIGIT_FILLS, 4.5, "digit"],
	["digit_placed", DIGIT_FILLS, 4.5, "digit"],
	["digit_conflict", DIGIT_FILLS, 4.5, "digit"],
	["candidate_open", RING_FILLS, 4.5, "open candidate"],
	["candidate_crossed", RING_FILLS, 3.0, "crossed digit"],
	["cross_mark_hand", RING_FILLS, 3.0, "hand X"],
	["cross_mark_auto", RING_FILLS, 3.0, "Auto Cross slash"],
	["cross_mark_auto", ["candidate_crossed"], 1.5, "Auto Cross slash on its digit"],
	["selection_frame_place", DIGIT_FILLS, 3.0, "selection frame, Place"],
	["selection_frame_cross", DIGIT_FILLS, 3.0, "selection frame, Cross Out"],
	["hint_target_mark", DIGIT_FILLS, 3.0, "hint target bracket"],
	["hint_reason_mark", DIGIT_FILLS, 3.0, "hint reason tick, lesson mark"],
	["hint_reason_mark", ["page_bg"], 3.0, "lesson mark around a control"],
	["hint_cross_bg", RING_FILLS, 3.0, "hint cross chip"],
	["cell_bg", ["hint_cross_bg"], 4.5, "candidate on a hint cross chip"],
	["conflict_mark", ["cell_conflict_bg", "cell_selected_bg", "surface_bg"], 3.0, "conflict bar, board message mark"],
	["line_box", DIGIT_FILLS, 3.0, "box line"],
	["line_outer", DIGIT_FILLS + ["page_bg"], 3.0, "outer line"],
	["line_cell", ["cell_bg", "cell_peer_bg"], 1.2, "cell line"],
	["text", PAGE_BGS, 4.5, "text"],
	["text_muted", PAGE_BGS, 4.5, "text"],
	["text_accent", PAGE_BGS, 4.5, "text"],
	["sticker_text", ["sticker_bg"], 4.5, "text"],
	["celebrate_text", ["celebrate_bg"], 4.5, "text"],
	["hint_tag_text", ["hint_tag_bg"], 4.5, "text"],
	["chart_bar", ["surface_bg", "surface_alt_bg"], 3.0, "chart mark"],
	["outline", PAGE_BGS + ["switch_off_bg"], 3.0, "UI outline"],
	["hud_text", ["hud_bg"], 4.5, "text"],
	["hud_label", ["hud_bg"], 4.5, "text"],
	["hud_score_text", ["hud_score_bg"], 4.5, "text"],
	["button_text", ["button_bg"], 4.5, "text"],
	["button_primary_text", ["button_primary_bg"], 4.5, "text"],
	["button_danger_text", ["button_danger_bg"], 4.5, "text"],
	["button_disabled_text", ["button_disabled_bg", "button_disabled_hatch"], 3.0, "disabled text"],
	["button_disabled_outline", ["page_bg", "surface_bg"], 3.0, "disabled outline"],
	["button_disabled_hatch", ["button_disabled_bg"], 1.15, "disabled hatch"],
	["pad_key_place_text", ["pad_key_place_bg"], 4.5, "digit"],
	["pad_key_cross_text", ["pad_key_cross_bg"], 4.5, "digit"],
	["pad_key_cross_mark", ["pad_key_cross_bg"], 3.0, "cross mark"],
	["mode_toggle_text", ["mode_toggle_bg"], 4.5, "text"],
	["mode_toggle_active_text", ["mode_toggle_active_bg"], 4.5, "text"],
	["switch_on_bg", ["surface_bg"], 3.0, "switch track"],
	["switch_knob", ["switch_on_bg"], 3.0, "switch knob"],
]

## [token, other tokens, minimum color distance, what it is]. Marks that touch
## must differ in color as well as shape; the selected fill must stand apart
## from its peers.
const SKIN_TOLD_APART: Array = [
	["selection_frame_place", ["line_box", "line_outer", "hint_target_mark", "hint_reason_mark"], 0.3, "Place frame"],
	["selection_frame_cross", ["line_box", "line_outer", "hint_target_mark", "hint_reason_mark"], 0.3, "Cross Out frame"],
	["hint_target_mark", ["line_box", "line_outer"], 0.3, "hint target bracket"],
	["hint_reason_mark", ["line_box", "line_outer"], 0.3, "hint reason tick"],
	["cross_mark_auto", ["cross_mark_hand"], 0.3, "Auto Cross slash and hand X"],
	["hint_cross_bg", ["candidate_crossed", "cross_mark_hand", "cross_mark_auto", "conflict_mark", "digit_conflict", "cell_conflict_bg", "cell_same_digit_bg"], 0.3, "hint cross chip"],
	["cell_selected_bg", ["cell_peer_bg"], 0.15, "selected fill and peer fill"],
]

## Tokens that may be translucent.
const SKIN_TRANSLUCENT: Array[String] = ["scrim"]

## Readability is judged on a 360 dp wide screen tall enough that the width
## sets the board's size (GDD AT-66). Densities: 720, 945 and 1080 px wide.
const JUDGED_DP_WIDTH: float = 360.0
const JUDGED_DENSITIES: Array[float] = [2.0, 2.625, 3.0]
## The floor in DESIGN_SYSTEM.md section 3: the candidate font size the board
## draws with, in dp, on the judged screen.
const CANDIDATE_FLOOR_DP: float = 11.0
## And the ink of the tallest digit at that size, in dp.
const CANDIDATE_INK_FLOOR_DP: float = 8.5
const MIN_KNOCKOUT_PX: float = 1.0
const MIN_RING_CLEARANCE_DP: float = 1.0 ## Ring box clear of the frame and hint marks.
const MIN_RING_LINE_CLEARANCE_DP: float = 0.5 ## Ring box clear of the outer line.
## Hint cross chips (DESIGN_SYSTEM.md 2.7) on the judged screen.
const MIN_CHIP_PAD_PX: float = 1.0 ## Chip above and below the slot box.
const MIN_CHIP_GAP_PX: float = 1.0 ## Between chips in neighboring rows.
const MIN_CHIP_CLEARANCE_DP: float = 0.5 ## Chip clear of the frame and hint marks.


func _initialize() -> void:
	var result: Variant = call("_run")
	quit(result if result is int else 1)


func _run() -> int:
	var final_result: Vector2i = _run_final_skins()
	var total: int = final_result.x
	var failed: int = final_result.y
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
			for rule: Array in TOLD_APART:
				var name_a: String = rule[0]
				var others: Array = rule[1]
				var what: String = rule[2]
				for name_b: String in others:
					var distance: float = color_distance(colors.get(name_a), colors.get(name_b))
					var apart: bool = distance >= MIN_COLOR_DISTANCE
					total += 1
					if not apart:
						failed += 1
					print("  %s  %5.2f  >= %.1f  %-24s vs %-20s (%s, color distance)" % ["PASS" if apart else "FAIL", distance, MIN_COLOR_DISTANCE, name_a, name_b, what])
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


## Part 1. Returns Vector2i(checks, failures).
func _run_final_skins() -> Vector2i:
	var total: int = 0
	var failed: int = 0
	print("Final skins (src/skins/pop_light.tres and pop_dark.tres), WCAG 2 contrast ratio")
	print("")
	for id: String in Palettes.SKIN_IDS:
		print("%s (%s)" % [id, Palettes.skin_path(id)])
		var problems: PackedStringArray = _check_skin_file(id)
		for problem: String in problems:
			print("  FAIL  %s" % problem)
		total += 1
		failed += 1 if not problems.is_empty() else 0
		var skin: GameSkin = Palettes.skin(id)
		if skin == null:
			print("")
			continue
		var known: PackedStringArray = Palettes.skin_tokens()
		for rule: Array in SKIN_RULES:
			var fg_name: String = rule[0]
			var bg_names: Array = rule[1]
			var target: float = rule[2]
			var kind: String = rule[3]
			for bg_name: String in bg_names:
				if not known.has(fg_name) or not known.has(bg_name):
					total += 1
					failed += 1
					print("  FAIL  %s or %s is not a GameSkin property (%s)" % [fg_name, bg_name, kind])
					continue
				var fg: Color = skin.get(fg_name)
				var bg: Color = skin.get(bg_name)
				var ratio: float = contrast(fg, bg)
				var ok: bool = ratio >= target and fg.a >= 1.0 and bg.a >= 1.0
				total += 1
				failed += 0 if ok else 1
				print("  %s  %5.2f  >= %.2f  %-24s on %-20s (%s)" % ["PASS" if ok else "FAIL", ratio, target, fg_name, bg_name, kind])
		for rule: Array in SKIN_TOLD_APART:
			var name_a: String = rule[0]
			var others: Array = rule[1]
			var minimum: float = rule[2]
			var what: String = rule[3]
			for name_b: String in others:
				if not known.has(name_a) or not known.has(name_b):
					total += 1
					failed += 1
					print("  FAIL  %s or %s is not a GameSkin property (%s)" % [name_a, name_b, what])
					continue
				var distance: float = color_distance(skin.get(name_a), skin.get(name_b))
				var apart: bool = distance >= minimum
				total += 1
				failed += 0 if apart else 1
				print("  %s  %5.2f  >= %.2f  %-24s vs %-20s (%s, color distance)" % ["PASS" if apart else "FAIL", distance, minimum, name_a, name_b, what])
		print("")
	print("Final skin sizes on the judged screen (%d dp wide, width-bound board)" % int(JUDGED_DP_WIDTH))
	var size_problems: PackedStringArray = _check_skin_sizes()
	total += 1
	if size_problems.is_empty():
		print("  PASS  sizes")
	else:
		failed += 1
		for problem: String in size_problems:
			print("  FAIL  %s" % problem)
	print("")
	print("docs/DESIGN_SYSTEM.md section 1 tables against the two skin files")
	var doc_problems: PackedStringArray = _check_design_doc()
	total += 1
	if doc_problems.is_empty():
		print("  PASS  3 identity fields and %d tokens: names, order, types and both values match" % Palettes.skin_tokens().size())
	else:
		failed += 1
		for problem: String in doc_problems:
			print("  FAIL  %s" % problem)
	print("")
	print("Final skins: %d checks, %d failed" % [total, failed])
	print("")
	return Vector2i(total, failed)


## The file loads as a GameSkin, writes every property itself (so a change to
## a default in game_skin.gd can never change a skin silently), has the right
## identity, and every color is opaque except the scrim.
func _check_skin_file(id: String) -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	var path: String = Palettes.skin_path(id)
	if not FileAccess.file_exists(path):
		problems.append("%s does not exist; run tools/design/write_skins.gd" % path)
		return problems
	var skin: GameSkin = Palettes.skin(id)
	if skin == null:
		problems.append("%s does not load as a GameSkin" % path)
		return problems
	var written: Dictionary[String, bool] = {}
	for line: String in FileAccess.get_file_as_string(path).split("
"):
		if line.contains(" = "):
			written[line.get_slice(" = ", 0).strip_edges()] = true
	var names: PackedStringArray = PackedStringArray(Palettes.SKIN_IDENTITY_FIELDS)
	names.append_array(Palettes.skin_tokens())
	for name: String in names:
		if not written.has(name):
			problems.append("%s does not set %s" % [path.get_file(), name])
	for token: String in Palettes.skin_tokens():
		var kind: String = Palettes.skin_token_type(token)
		if kind == "":
			problems.append("%s has no type" % token)
		elif kind == "Color":
			var color: Color = skin.get(token)
			if not SKIN_TRANSLUCENT.has(token) and color.a < 1.0:
				problems.append("%s must be opaque" % token)
	if String(skin.id) != id or skin.display_name.is_empty():
		problems.append("identity fields not set")
	if skin.is_dark != (id == "pop_dark"):
		problems.append("is_dark is wrong")
	return problems


## Board geometry and stroke sizes on the judged screen, at every density in
## JUDGED_DENSITIES. The numbers are the same in both skins.
func _check_skin_sizes() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	var s: GameSkin = Palettes.skin("pop_light")
	var dark: GameSkin = Palettes.skin("pop_dark")
	if s == null or dark == null:
		problems.append("the skin files do not load")
		return problems
	for token: String in Palettes.skin_tokens():
		if Palettes.skin_token_type(token) == "float" and s.get(token) != dark.get(token):
			problems.append("%s differs between the skins; the size checks assume one value" % token)
	var board_dp: float = JUDGED_DP_WIDTH - 2.0 * s.page_margin - s.shadow_offset - s.line_outer_w
	var font: Font = Fonts.get_font(Fonts.Weight.SEMIBOLD)
	var has_chip_pad: bool = Palettes.skin_tokens().has("hint_cross_pad")
	if not has_chip_pad:
		problems.append("hint_cross_pad is not a GameSkin property")
	for density: float in JUDGED_DENSITIES:
		var ring_px: float = (board_dp / 9.0 - 2.0 * s.ring_inset) * density
		var size_px: int = RingLayouts.fit_font_size(RingLayouts.Layout.ROWS, ring_px, font)
		var size_dp: float = float(size_px) / density
		var ink_dp: float = Fonts.digit_cell(font, size_px).y / density
		print("  density %.3f: board %.1f dp, cell %.2f dp, candidates %d px = %.2f dp (floor %.1f), tallest digit %.2f dp" % [
			density, board_dp, board_dp / 9.0, size_px, size_dp, CANDIDATE_FLOOR_DP, ink_dp])
		if has_chip_pad:
			problems.append_array(_check_chip(s, density, ring_px, size_px, font))
		if ink_dp < CANDIDATE_INK_FLOOR_DP:
			problems.append("the tallest candidate digit is %.2f dp at density %.3f, below the %.1f dp floor" % [ink_dp, density, CANDIDATE_INK_FLOOR_DP])
		if size_dp < CANDIDATE_FLOOR_DP:
			problems.append("candidates are %.2f dp at density %.3f, below the %.1f dp floor" % [size_dp, density, CANDIDATE_FLOOR_DP])
		var cell_px: float = maxf(1.0, roundf(s.line_cell_w * density))
		var box_px: float = maxf(1.0, roundf(s.line_box_w * density))
		if box_px < MIN_BOX_TO_CELL_WEIGHT * cell_px:
			problems.append("box line %d px is not %.1f times the cell line %d px at density %.3f" % [int(box_px), MIN_BOX_TO_CELL_WEIGHT, int(cell_px), density])
		if s.cross_mark_w * density < MIN_X_STROKE_PX:
			problems.append("mark stroke %.2f px at density %.3f, below %.1f px" % [s.cross_mark_w * density, density, MIN_X_STROKE_PX])
		if maxf(1.0, roundf(s.knockout_w * density)) < MIN_KNOCKOUT_PX:
			problems.append("knockout under 1 px")
	if not is_equal_approx(s.candidate_gap, RingLayouts.GAP):
		problems.append("candidate_gap %.2f differs from the fitting gap %.2f in ring_layouts.gd" % [s.candidate_gap, RingLayouts.GAP])
	var frame_in: float = s.selection_frame_w * 0.5
	var marks_in: float = s.hint_mark_w * 0.5
	if s.ring_inset - frame_in < MIN_RING_CLEARANCE_DP or s.ring_inset - marks_in < MIN_RING_CLEARANCE_DP:
		problems.append("ring box clears the frame and marks by %.2f dp, needs %.1f" % [s.ring_inset - maxf(frame_in, marks_in), MIN_RING_CLEARANCE_DP])
	if s.ring_inset - s.line_outer_w * 0.5 < MIN_RING_LINE_CLEARANCE_DP:
		problems.append("ring box clears the outer line by %.2f dp" % (s.ring_inset - s.line_outer_w * 0.5))
	if s.hint_mark_w < s.selection_frame_w:
		problems.append("hint marks (%.1f dp) must be at least as heavy as the frame (%.1f dp) to cover it" % [s.hint_mark_w, s.selection_frame_w])
	var corner_dash: float = (1.0 - s.selection_mid_dash - 2.0 * s.selection_gap) * 0.5
	if corner_dash <= 0.0:
		problems.append("Cross Out frame has no corner dashes")
	if s.hint_bracket_len + 0.001 < corner_dash:
		problems.append("hint brackets (%.2f) must cover the corner dashes (%.2f)" % [s.hint_bracket_len, corner_dash])
	if s.hint_tick_len + 0.001 < s.selection_mid_dash:
		problems.append("hint ticks (%.2f) must cover the middle dashes (%.2f)" % [s.hint_tick_len, s.selection_mid_dash])
	var box_cell_dp: float = s.line_box_w / s.line_cell_w
	print("  box line %.1f dp / cell line %.1f dp = %.1f; Cross Out frame: corner dash %.2f, gap %.2f, middle dash %.2f of the side" % [
		s.line_box_w, s.line_cell_w, box_cell_dp, corner_dash, s.selection_gap, s.selection_mid_dash])
	return problems


## The hint cross chip at one density: the slot box, full width, grown above
## and below by hint_cross_pad times the candidate font size (2.7). It must
## grow by at least a pixel, keep chips in neighboring rows apart, and clear
## the selection frame and the hint marks on the cell edge.
func _check_chip(s: GameSkin, density: float, ring_px: float, size_px: int, font: Font) -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	var pad: float = s.get("hint_cross_pad")
	var pad_px: float = pad * float(size_px)
	var slot: Vector2 = Fonts.digit_cell(font, size_px)
	var rows: float = float(RingLayouts.rows(RingLayouts.Layout.ROWS).size())
	var row_gap_px: float = (ring_px - rows * slot.y) / (rows - 1.0)
	var chip_gap_px: float = row_gap_px - 2.0 * pad_px
	var edge_in_px: float = maxf(s.selection_frame_w, s.hint_mark_w) * 0.5 * density
	var clearance_dp: float = (s.ring_inset * density - edge_in_px - pad_px) / density
	var top_row: PackedInt32Array = RingLayouts.rows(RingLayouts.Layout.ROWS)[0]
	var side_gap_px: float = (ring_px - float(top_row.size()) * slot.x) / float(top_row.size() - 1)
	print("    hint cross chip %.0f by %.1f px: pad %.2f px, %.2f px between rows, %.2f px between top row chips, %.2f dp clear of the frame and marks" % [
		slot.x, slot.y + 2.0 * pad_px, pad_px, chip_gap_px, side_gap_px, clearance_dp])
	if pad_px < MIN_CHIP_PAD_PX:
		problems.append("hint cross chip grows %.2f px at density %.3f, needs %.1f px" % [pad_px, density, MIN_CHIP_PAD_PX])
	if chip_gap_px < MIN_CHIP_GAP_PX:
		problems.append("hint cross chips in neighboring rows are %.2f px apart at density %.3f, need %.1f px" % [chip_gap_px, density, MIN_CHIP_GAP_PX])
	if clearance_dp < MIN_CHIP_CLEARANCE_DP:
		problems.append("hint cross chip clears the frame and marks by %.2f dp at density %.3f, needs %.1f dp" % [clearance_dp, density, MIN_CHIP_CLEARANCE_DP])
	return problems


## The two tables in section 1 of docs/DESIGN_SYSTEM.md against the skin
## files. Identity rows look like: | `id` | StringName | `pop_light` | `pop_dark` |
## Token rows look like: | `token` | Color | `#RRGGBB` | `#RRGGBB` | what |
## The token rows must list exactly GameSkin's tokens, in its order, with its
## types and both files' values.
func _check_design_doc() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	if not FileAccess.file_exists(DESIGN_SYSTEM_PATH):
		problems.append("%s does not exist" % DESIGN_SYSTEM_PATH)
		return problems
	var light_skin: GameSkin = Palettes.skin("pop_light")
	var dark_skin: GameSkin = Palettes.skin("pop_dark")
	if light_skin == null or dark_skin == null:
		problems.append("the skin files do not load")
		return problems
	var lines: PackedStringArray = FileAccess.get_file_as_string(DESIGN_SYSTEM_PATH).split("
")
	var in_section: bool = false
	var rows: Array[PackedStringArray] = []
	var identity: Array[PackedStringArray] = []
	for line: String in lines:
		if line.begins_with("## "):
			in_section = line.begins_with("## 1.")
			continue
		if not in_section or not line.begins_with("| `"):
			continue
		var cells: PackedStringArray = PackedStringArray()
		for cell: String in line.trim_prefix("|").trim_suffix("|").split("|"):
			cells.append(cell.strip_edges())
		if cells.size() < 4:
			continue
		if cells[1] == "Color" or cells[1] == "float":
			rows.append(cells)
		elif cells[1] in ["StringName", "String", "bool"]:
			identity.append(cells)
	if identity.size() != Palettes.SKIN_IDENTITY_FIELDS.size():
		problems.append("the identity table has %d rows, GameSkin has %d identity fields" % [identity.size(), Palettes.SKIN_IDENTITY_FIELDS.size()])
	for cells: PackedStringArray in identity:
		var field: String = _unquote(cells[0])
		for side: int in 2:
			var skin: GameSkin = light_skin if side == 0 else dark_skin
			var written: String = _unquote(cells[2 + side])
			var actual: String = str(skin.get(field)) if field != "is_dark" else ("true" if skin.is_dark else "false")
			if written != actual:
				problems.append("%s %s: the table says %s, the file %s" % [field, Palettes.SKIN_IDS[side], written, actual])
	var tokens: PackedStringArray = Palettes.skin_tokens()
	if rows.size() != tokens.size():
		problems.append("the table has %d token rows, GameSkin has %d tokens" % [rows.size(), tokens.size()])
	var light: Dictionary = Palettes.skin_table("pop_light")
	var dark: Dictionary = Palettes.skin_table("pop_dark")
	for n: int in mini(rows.size(), tokens.size()):
		var cells: PackedStringArray = rows[n]
		var token: String = _unquote(cells[0])
		if token != tokens[n]:
			problems.append("row %d is %s, GameSkin has %s there" % [n + 1, token, tokens[n]])
			continue
		var kind: String = Palettes.skin_token_type(token)
		if cells[1] != kind:
			problems.append("%s: the table says %s, GameSkin %s" % [token, cells[1], kind])
		for side: int in 2:
			var written: String = _unquote(cells[2 + side])
			var expected: Variant = (light if side == 0 else dark)[token]
			var where: String = Palettes.SKIN_IDS[side]
			if kind == "Color":
				if written.to_upper() != String(expected).to_upper():
					problems.append("%s %s: the table says %s, the file %s" % [token, where, written, expected])
			elif not written.is_valid_float() or not is_equal_approx(written.to_float(), float(expected)):
				problems.append("%s %s: the table says %s, the file %s" % [token, where, written, str(expected)])
	return problems


static func _unquote(cell: String) -> String:
	if cell.length() >= 2 and cell.begins_with("`") and cell.ends_with("`"):
		return cell.substr(1, cell.length() - 2)
	return cell


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
	# A soft shadow spreads shadow_blur around its shape; it must not reach
	# past the screen margin, where the screen edge would cut it off.
	if shape.shadow_blur > 0.0 and shape.shadow_blur + absf(shape.shadow_offset.x) > shape.screen_margin:
		problems.append("soft shadow spreads %.0f units sideways, past the %.0f unit screen margin" % [shape.shadow_blur + absf(shape.shadow_offset.x), shape.screen_margin])
	return problems


## WCAG 2 contrast ratio of two opaque colors.
static func contrast(a: Color, b: Color) -> float:
	var la: float = luminance(a)
	var lb: float = luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## Length of the RGB difference of two colors, channels from 0 to 1.
static func color_distance(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


## WCAG 2 relative luminance of an sRGB color.
static func luminance(c: Color) -> float:
	return 0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b)


static func _channel(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
