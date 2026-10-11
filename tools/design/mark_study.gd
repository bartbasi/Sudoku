extends SceneTree
## Design studies for docs/DESIGN_SYSTEM.md, drawn with the final Pop skins at
## true size on the phone readability is judged on: 360 dp wide at density 2,
## 720 px. The board is width-bound there, so its side and every candidate are
## the sizes the game will draw.
##
##   timeout 300 godot --path . --script res://tools/design/mark_study.gd
##
## Headless mode has no renderer, so run it with a window. Writes to
## docs/design/:
##   auto-cross-study.png and -x3.png   Auto Cross mark options on 1 to 9
##   selection-study.png and -x3.png    the selection frame per mode with the
##                                      hint and conflict marks on top
## Owner: senior-graphic-designer. Study code, never shipped. The board code
## that ships is grid-cell-artist's BoardPainter in src/skins/.

const Palettes := preload("res://tools/design/directions/palettes.gd")
const RingLayouts := preload("res://tools/design/directions/ring_layouts.gd")
const Fonts := preload("res://tools/design/directions/fonts.gd")

const OUT_DIR: String = "res://docs/design/"
const DENSITY: float = 2.0 ## px per dp on the judged phone.
const PHONE_DP: float = 360.0
const PAPER: Color = Color("#F6F5F1")
const INK: Color = Color("#111111")
const LABEL_SIZE: int = 14
const PAD: float = 12.0
const LABEL_W: float = 270.0

## Auto Cross mark options. RISING_TOP is the Phase 1 mark.
enum Mark { HAND, RISING_TOP, FALLING_TOP, FALLING_UNDER, STRIKE_TOP }

## Candidate states in a test cell.
const OPEN: int = 0
const HAND: int = 1
const AUTO: int = 2

## [label, mark, color source] per study row. "gray" is the Phase 1 gray,
## "skin" is cross_mark_auto from the skin.
const ROWS: Array = [
	["Hand X, digit on top (Bart)", Mark.HAND, "skin"],
	["A rising slash on top, gray (Phase 1)", Mark.RISING_TOP, "gray"],
	["B falling slash on top, gray", Mark.FALLING_TOP, "gray"],
	["C falling slash under, gray", Mark.FALLING_UNDER, "gray"],
	["D strike on top, gray", Mark.STRIKE_TOP, "gray"],
	["E falling slash on top, blue (chosen)", Mark.FALLING_TOP, "skin"],
	["F falling slash under, blue", Mark.FALLING_UNDER, "skin"],
]

## Phase 1 Auto Cross gray per skin.
const PHASE1_GRAY: Dictionary = {"pop_light": "#4A4A4A", "pop_dark": "#BDBDBD"}

## [skin id, fill token, pattern] per column. "all" crosses every candidate
## with the row's mark; "mixed" is 1 4 7 with the row's mark, 2 6 9 hand X,
## 3 5 8 open.
const COLUMNS: Array = [
	["pop_light", "cell_bg", "all"],
	["pop_light", "cell_selected_bg", "mixed"],
	["pop_light", "cell_peer_bg", "mixed"],
	["pop_dark", "cell_bg", "all"],
	["pop_dark", "cell_selected_bg", "mixed"],
]

var _written: PackedStringArray = PackedStringArray()
var _problems: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_run()


func _run() -> void:
	var auto_sheet: Control = _auto_cross_sheet()
	var image: Image = await _render(auto_sheet)
	_save_pair(image, "auto-cross-study")
	var selection_sheet: Control = _selection_sheet()
	image = await _render(selection_sheet)
	_save_pair(image, "selection-study")
	for path: String in _written:
		print("wrote    %s" % path)
	for problem: String in _problems:
		print("PROBLEM  %s" % problem)
	print("Studies: %d file(s), %d problem(s). Cell %.1f px, candidates %d px (%.1f dp) on a %d px wide phone." % [
		_written.size(), _problems.size(), _cell_px(), _candidate_size(), float(_candidate_size()) / DENSITY, int(PHONE_DP * DENSITY)])
	quit(0 if _problems.is_empty() else 1)


# Geometry, from the skin numbers (the same in both skins)

func _skin(id: String) -> GameSkin:
	return Palettes.skin(id)


## Board side in dp on the judged phone: the content width minus the outer
## line and the hard shadow (DESIGN_SYSTEM.md section 4).
func _board_dp() -> float:
	var s: GameSkin = _skin("pop_light")
	return PHONE_DP - 2.0 * s.page_margin - s.shadow_offset - s.line_outer_w


func _cell_px() -> float:
	return _board_dp() / 9.0 * DENSITY


func _px(dp: float) -> float:
	return dp * DENSITY


## A line weight in whole pixels, at least one.
func _w(dp: float) -> float:
	return maxf(1.0, roundf(dp * DENSITY))


func _candidate_font() -> Font:
	return Fonts.get_font(Fonts.Weight.SEMIBOLD)


func _ring_side() -> float:
	return _cell_px() - 2.0 * _px(_skin("pop_light").ring_inset)


func _candidate_size() -> int:
	return RingLayouts.fit_font_size(RingLayouts.Layout.ROWS, _ring_side(), _candidate_font())


# Drawing a cell

## One cell's ring at origin (the cell's top left corner). states[d - 1] is
## OPEN, HAND or AUTO; AUTO uses mark and auto_color.
func _draw_ring(canvas: Control, origin: Vector2, fill: Color, states: Array[int], mark: Mark, auto_color: Color, s: GameSkin) -> void:
	var c: float = _cell_px()
	var inset: float = _px(s.ring_inset)
	var ring: Rect2 = Rect2(origin + Vector2(inset, inset), Vector2(c - 2.0 * inset, c - 2.0 * inset))
	var font: Font = _candidate_font()
	var size: int = _candidate_size()
	var stroke: float = _px(s.cross_mark_w)
	var knockout: int = maxi(1, roundi(_px(s.knockout_w)))
	for digit: int in range(1, 10):
		var slot: Rect2 = RingLayouts.slot_rect(RingLayouts.Layout.ROWS, digit, ring, font, size)
		var span: Vector2 = slot.size * s.cross_mark_span
		var m: Rect2 = Rect2(slot.get_center() - span * 0.5, span)
		var center: Vector2 = slot.get_center()
		var text: String = str(digit)
		var state: int = states[digit - 1]
		if state == OPEN:
			Fonts.draw_centered(canvas, font, size, text, center, s.candidate_open)
			continue
		var kind: Mark = Mark.HAND if state == HAND else mark
		var color: Color = s.cross_mark_hand if kind == Mark.HAND else auto_color
		match kind:
			Mark.HAND:
				canvas.draw_line(m.position, m.end, color, stroke, true)
				canvas.draw_line(Vector2(m.position.x, m.end.y), Vector2(m.end.x, m.position.y), color, stroke, true)
				Fonts.draw_centered_outlined(canvas, font, size, text, center, s.candidate_crossed, knockout, fill)
			Mark.FALLING_UNDER:
				canvas.draw_line(m.position, m.end, color, stroke, true)
				Fonts.draw_centered_outlined(canvas, font, size, text, center, s.candidate_crossed, knockout, fill)
			Mark.RISING_TOP:
				Fonts.draw_centered(canvas, font, size, text, center, s.candidate_crossed)
				canvas.draw_line(Vector2(m.position.x, m.end.y), Vector2(m.end.x, m.position.y), color, stroke, true)
			Mark.FALLING_TOP:
				Fonts.draw_centered(canvas, font, size, text, center, s.candidate_crossed)
				canvas.draw_line(m.position, m.end, color, stroke, true)
			Mark.STRIKE_TOP:
				Fonts.draw_centered(canvas, font, size, text, center, s.candidate_crossed)
				canvas.draw_line(Vector2(m.position.x, center.y), Vector2(m.end.x, center.y), color, stroke, true)


## A big digit (given or placed) centered in the cell.
func _draw_digit(canvas: Control, origin: Vector2, digit: int, given: bool, conflict: bool, s: GameSkin) -> void:
	var c: float = _cell_px()
	var size: int = roundi(s.digit_size * c)
	var weight: int = Fonts.Weight.HEAVY if given else Fonts.Weight.SEMIBOLD
	var color: Color = s.digit_given if given else s.digit_placed
	if conflict:
		color = s.digit_conflict
	Fonts.draw_centered(canvas, Fonts.get_font(weight), size, str(digit), origin + Vector2(c, c) * 0.5, color)


# Sheet 1: Auto Cross marks

func _auto_cross_sheet() -> Control:
	var c: float = _cell_px()
	var col_w: float = ceilf(c) + PAD
	var head: float = 3.0 * 18.0 + PAD
	var sheet: Control = Control.new()
	sheet.size = Vector2(ceilf(PAD + LABEL_W + float(COLUMNS.size()) * col_w), ceilf(head + float(ROWS.size()) * (ceilf(c) + PAD) + PAD))
	var font: Font = Fonts.get_font(Fonts.Weight.SEMIBOLD)
	sheet.draw.connect(func() -> void:
		sheet.draw_rect(Rect2(Vector2.ZERO, sheet.size), PAPER)
		var lines: Array[String] = [
			"Auto Cross mark options, true size, 720 px phone (360 dp, density 2)",
			"Columns: light plain, all marked | light selected, mixed | light peer, mixed | dark plain, all | dark selected, mixed",
			"Mixed: 1 4 7 with the row's mark, 2 6 9 hand X, 3 5 8 open",
		]
		for n: int in lines.size():
			sheet.draw_string(font, Vector2(PAD, PAD + 13.0 + 18.0 * float(n)), lines[n], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, INK)
		for r: int in ROWS.size():
			var row: Array = ROWS[r]
			var y: float = head + float(r) * (ceilf(c) + PAD)
			sheet.draw_string(font, Vector2(PAD, y + c * 0.5 + 5.0), row[0], HORIZONTAL_ALIGNMENT_LEFT, LABEL_W - PAD, LABEL_SIZE, INK)
			for k: int in COLUMNS.size():
				var column: Array = COLUMNS[k]
				var s: GameSkin = _skin(column[0])
				var fill: Color = s.get(column[1])
				var origin: Vector2 = Vector2(PAD + LABEL_W + float(k) * col_w, y).round()
				var frame: float = _w(s.line_cell_w)
				sheet.draw_rect(Rect2(origin - Vector2(frame, frame), Vector2(c, c) + Vector2(frame, frame) * 2.0), s.line_cell)
				sheet.draw_rect(Rect2(origin, Vector2(c, c)), fill)
				var auto_color: Color = Color(PHASE1_GRAY[column[0]]) if row[2] == "gray" else s.cross_mark_auto
				var states: Array[int] = []
				for digit: int in range(1, 10):
					if column[2] == "all":
						states.append(AUTO if row[1] != Mark.HAND else HAND)
					elif [1, 4, 7].has(digit):
						states.append(AUTO if row[1] != Mark.HAND else HAND)
					elif [2, 6, 9].has(digit):
						states.append(HAND)
					else:
						states.append(OPEN)
				_draw_ring(sheet, origin, fill, states, row[1], auto_color, s)
	)
	return sheet


# Sheet 2: selection frame and hint marks

## One 3 by 3 box of cells. Each cell: [fill token, content, flags], content
## is "" (ring, all open), "ring:<pattern>" (hand X on listed digits), or
## "g<d>" / "p<d>" for a given or placed digit. flags: "sel", "target",
## "reason", "conflict".
class Scenario extends RefCounted:
	var title: String
	var skin_id: String
	var cross_mode: bool
	var cells: Array = []


func _scenarios() -> Array[Scenario]:
	var out: Array[Scenario] = []
	out.append(_scenario("Place mode: solid blue frame", "pop_light", false, [
		["cell_peer_bg", "", []], ["cell_peer_bg", "g7", []], ["cell_peer_bg", "", []],
		["cell_peer_bg", "ring:39", []], ["cell_selected_bg", "ring:39", ["sel"]], ["cell_peer_bg", "p4", []],
		["cell_peer_bg", "", []], ["cell_peer_bg", "g2", []], ["cell_peer_bg", "", []],
	]))
	out.append(_scenario("Cross Out mode: dashed magenta frame", "pop_light", true, [
		["cell_peer_bg", "", []], ["cell_peer_bg", "g7", []], ["cell_peer_bg", "", []],
		["cell_peer_bg", "ring:39", []], ["cell_selected_bg", "ring:39", ["sel"]], ["cell_peer_bg", "p4", []],
		["cell_peer_bg", "", []], ["cell_peer_bg", "g2", []], ["cell_peer_bg", "", []],
	]))
	out.append(_scenario("Cross Out, selected hint target, reason next to it", "pop_light", true, [
		["cell_peer_bg", "", []], ["cell_hint_reason_bg", "g1", ["reason"]], ["cell_peer_bg", "", []],
		["cell_peer_bg", "ring:39", []], ["cell_selected_bg", "ring:2345", ["sel", "target"]], ["cell_hint_target_bg", "", ["target"]],
		["cell_peer_bg", "", []], ["cell_peer_bg", "g2", []], ["cell_bg", "", []],
	]))
	out.append(_scenario("Place, selected wrong digit: conflict and hint target", "pop_light", false, [
		["cell_bg", "", []], ["cell_peer_bg", "g7", []], ["cell_bg", "", []],
		["cell_peer_bg", "ring:39", []], ["cell_selected_bg", "p8", ["sel", "target", "conflict"]], ["cell_conflict_bg", "g8", ["conflict"]],
		["cell_bg", "", []], ["cell_same_digit_bg", "p8", []], ["cell_bg", "", []],
	]))
	out.append(_scenario("Dark, Cross Out, selected hint target", "pop_dark", true, [
		["cell_peer_bg", "", []], ["cell_hint_reason_bg", "g1", ["reason"]], ["cell_peer_bg", "", []],
		["cell_peer_bg", "ring:39", []], ["cell_selected_bg", "ring:2345", ["sel", "target"]], ["cell_hint_target_bg", "", ["target"]],
		["cell_peer_bg", "", []], ["cell_peer_bg", "g2", []], ["cell_bg", "", []],
	]))
	out.append(_scenario("Dark, Place mode", "pop_dark", false, [
		["cell_peer_bg", "", []], ["cell_peer_bg", "g7", []], ["cell_peer_bg", "", []],
		["cell_peer_bg", "ring:39", []], ["cell_selected_bg", "ring:39", ["sel"]], ["cell_peer_bg", "p4", []],
		["cell_peer_bg", "", []], ["cell_peer_bg", "g2", []], ["cell_peer_bg", "", []],
	]))
	return out


func _scenario(title: String, skin_id: String, cross_mode: bool, cells: Array) -> Scenario:
	var scenario: Scenario = Scenario.new()
	scenario.title = title
	scenario.skin_id = skin_id
	scenario.cross_mode = cross_mode
	scenario.cells = cells
	return scenario


func _selection_sheet() -> Control:
	var c: float = _cell_px()
	var box: float = ceilf(3.0 * c)
	var scenarios: Array[Scenario] = _scenarios()
	var per_row: int = 3
	var cell_w: float = box + 2.0 * PAD
	var title_h: float = 22.0
	var sheet: Control = Control.new()
	var rows: int = ceili(float(scenarios.size()) / float(per_row))
	sheet.size = Vector2(ceilf(PAD + float(per_row) * cell_w), ceilf(PAD + 18.0 + float(rows) * (title_h + box + 2.0 * PAD)))
	var font: Font = Fonts.get_font(Fonts.Weight.SEMIBOLD)
	sheet.draw.connect(func() -> void:
		sheet.draw_rect(Rect2(Vector2.ZERO, sheet.size), PAPER)
		sheet.draw_string(font, Vector2(PAD, PAD + 12.0), "Selection frame and marks, true size, 720 px phone (360 dp, density 2)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, INK)
		for n: int in scenarios.size():
			var x: float = PAD + float(n % per_row) * cell_w
			var y: float = PAD + 18.0 + float(n / per_row) * (title_h + box + 2.0 * PAD)
			sheet.draw_string(font, Vector2(x, y + 15.0), scenarios[n].title, HORIZONTAL_ALIGNMENT_LEFT, cell_w - PAD, 11, INK)
			var s: GameSkin = _skin(scenarios[n].skin_id)
			var origin: Vector2 = Vector2(x + PAD, y + title_h + PAD).round()
			sheet.draw_rect(Rect2(origin - Vector2(PAD, PAD), Vector2(box, box) + Vector2(PAD, PAD) * 2.0), s.page_bg)
			_draw_box(sheet, origin, scenarios[n], s)
	)
	return sheet


## Draw order, bottom to top: fills, cell lines, box lines, digits and rings,
## conflict bars, the selection frame, hint ticks, hint brackets.
func _draw_box(canvas: Control, origin: Vector2, scenario: Scenario, s: GameSkin) -> void:
	var c: float = _cell_px()
	var fills: Array[Color] = []
	for i: int in 9:
		var fill: Color = s.get(scenario.cells[i][0])
		fills.append(fill)
		canvas.draw_rect(Rect2(origin + _cell_pos(i), Vector2(c, c)), fill)
	var cw: float = _w(s.line_cell_w)
	for n: int in [1, 2]:
		var at: float = roundf(float(n) * c - cw * 0.5)
		canvas.draw_rect(Rect2(origin + Vector2(at, 0.0), Vector2(cw, 3.0 * c)), s.line_cell)
		canvas.draw_rect(Rect2(origin + Vector2(0.0, at), Vector2(3.0 * c, cw)), s.line_cell)
	var bw: float = _w(s.line_box_w)
	var side: float = 3.0 * c
	canvas.draw_rect(Rect2(origin + Vector2(-bw * 0.5, -bw * 0.5), Vector2(side + bw, bw)).abs(), s.line_box)
	canvas.draw_rect(Rect2(origin + Vector2(-bw * 0.5, side - bw * 0.5), Vector2(side + bw, bw)), s.line_box)
	canvas.draw_rect(Rect2(origin + Vector2(-bw * 0.5, -bw * 0.5), Vector2(bw, side + bw)), s.line_box)
	canvas.draw_rect(Rect2(origin + Vector2(side - bw * 0.5, -bw * 0.5), Vector2(bw, side + bw)), s.line_box)
	for i: int in 9:
		var content: String = scenario.cells[i][1]
		var at: Vector2 = origin + _cell_pos(i)
		var flags: Array = scenario.cells[i][2]
		if content.begins_with("g") or content.begins_with("p"):
			_draw_digit(canvas, at, content.substr(1).to_int(), content.begins_with("g"), flags.has("conflict"), s)
		else:
			var states: Array[int] = []
			var crossed: String = content.trim_prefix("ring:") if content.begins_with("ring:") else ""
			for digit: int in range(1, 10):
				states.append(HAND if crossed.contains(str(digit)) else OPEN)
			_draw_ring(canvas, at, fills[i], states, Mark.HAND, s.cross_mark_auto, s)
	for i: int in 9:
		if scenario.cells[i][2].has("conflict"):
			var at: Vector2 = origin + _cell_pos(i)
			var half: float = s.conflict_bar_len * c * 0.5
			var h: float = _w(s.conflict_bar_w)
			var cy: float = roundf(at.y + s.conflict_bar_y * c - h * 0.5)
			canvas.draw_rect(Rect2(roundf(at.x + c * 0.5 - half), cy, roundf(2.0 * half), h), s.conflict_mark)
	for i: int in 9:
		if scenario.cells[i][2].has("sel"):
			_draw_selection(canvas, Rect2(origin + _cell_pos(i), Vector2(c, c)), fills[i], scenario.cross_mode, s)
	for i: int in 9:
		if scenario.cells[i][2].has("reason"):
			_draw_ticks(canvas, Rect2(origin + _cell_pos(i), Vector2(c, c)), s)
	for i: int in 9:
		if scenario.cells[i][2].has("target"):
			_draw_brackets(canvas, Rect2(origin + _cell_pos(i), Vector2(c, c)), s)


func _cell_pos(i: int) -> Vector2:
	var c: float = _cell_px()
	return Vector2(float(i % 3) * c, float(i / 3) * c)


## The frame straddles the cell edge. Place: solid. Cross Out: the band is
## first painted in the cell's fill, so the gaps show the fill and not the
## grid lines, then the dashes go on top: a corner dash, a gap, a middle dash,
## a gap and a corner dash per side.
func _draw_selection(canvas: Control, cell: Rect2, fill: Color, cross: bool, s: GameSkin) -> void:
	var color: Color = s.selection_frame_cross if cross else s.selection_frame_place
	var w: float = _w(s.selection_frame_w)
	_edge_bands(canvas, cell, w, 0.0, 1.0, fill if cross else color)
	if not cross:
		return
	var gap: float = s.selection_gap
	var mid: float = s.selection_mid_dash
	var corner: float = (1.0 - mid - 2.0 * gap) * 0.5
	_edge_bands(canvas, cell, w, 0.0, corner, color)
	_edge_bands(canvas, cell, w, corner + gap, corner + gap + mid, color)
	_edge_bands(canvas, cell, w, 1.0 - corner, 1.0, color)


## Hint target: brackets on the four corners, centered on the cell edge and as
## heavy as the frame, so they cover it and stay whole on a selected cell.
func _draw_brackets(canvas: Control, cell: Rect2, s: GameSkin) -> void:
	var w: float = _w(s.hint_mark_w)
	_edge_bands(canvas, cell, w, 0.0, s.hint_bracket_len, s.hint_target_mark)
	_edge_bands(canvas, cell, w, 1.0 - s.hint_bracket_len, 1.0, s.hint_target_mark)


## Hint reason (and lesson marks): a tick centered on each side, on the edge.
func _draw_ticks(canvas: Control, cell: Rect2, s: GameSkin) -> void:
	var w: float = _w(s.hint_mark_w)
	var half: float = s.hint_tick_len * 0.5
	_edge_bands(canvas, cell, w, 0.5 - half, 0.5 + half, s.hint_reason_mark)


## The same stretch of all four sides, from share a to share b along each
## side, as bands of weight w centered on the edge. Stretches that touch a
## corner run on past it by half the weight, so corners close.
func _edge_bands(canvas: Control, cell: Rect2, w: float, a: float, b: float, color: Color) -> void:
	var side: float = cell.size.x
	var half: float = w * 0.5
	var from: float = a * side - (half if a <= 0.0 else 0.0)
	var to: float = b * side + (half if b >= 1.0 else 0.0)
	var p: Vector2 = cell.position
	var e: Vector2 = cell.end
	canvas.draw_rect(Rect2(Vector2(p.x + from, p.y - half).round(), Vector2(to - from, w).round()), color)
	canvas.draw_rect(Rect2(Vector2(p.x + from, e.y - half).round(), Vector2(to - from, w).round()), color)
	canvas.draw_rect(Rect2(Vector2(p.x - half, p.y + from).round(), Vector2(w, to - from).round()), color)
	canvas.draw_rect(Rect2(Vector2(e.x - half, p.y + from).round(), Vector2(w, to - from).round()), color)


# Rendering

func _render(node: Control) -> Image:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(node.size)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.add_child(node)
	node.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	viewport.queue_free()
	await process_frame
	return image


func _save_pair(image: Image, base_name: String) -> void:
	_save(image, base_name)
	var big: Image = image.duplicate()
	big.resize(image.get_width() * 3, image.get_height() * 3, Image.INTERPOLATE_NEAREST)
	_save(big, base_name + "-x3")


func _save(image: Image, base_name: String) -> void:
	var path: String = OUT_DIR + base_name + ".png"
	var error: Error = image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		_problems.append("could not save %s (error %d)" % [path, error])
	else:
		_written.append(path)
