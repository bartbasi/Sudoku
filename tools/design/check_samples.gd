extends SceneTree
## Checks the Phase 1 sample content, the candidate ring layouts and the
## board geometry, and prints the candidate sizes quoted in
## docs/design/ring-layouts.md. Since Phase 2 it also runs the play and lesson
## layout rules of docs/DESIGN_SYSTEM.md section 4 (layout_model.gd) on the
## screens we design for, and prints the sizes that section quotes.
##
##   timeout 300 godot --headless --path . --script res://tools/design/check_samples.gd
##
## Exits with 1 if any check fails. Owner: senior-graphic-designer.

const Palettes := preload("res://tools/design/directions/palettes.gd")
const RingLayouts := preload("res://tools/design/directions/ring_layouts.gd")
const SampleState := preload("res://tools/design/directions/sample_state.gd")
const Fonts := preload("res://tools/design/directions/fonts.gd")
const Device := preload("res://tools/design/directions/device.gd")
const LayoutModel := preload("res://tools/design/layout_model.gd")

## The candidate floor in DESIGN_SYSTEM.md section 3, checked on the judged
## screen (360 dp wide, board width-bound). check_contrast.gd checks it too.
const CANDIDATE_FLOOR_DP: float = 11.0

## GDD 9.1: level points and hint cost.
const POINTS: Dictionary[String, int] = {"Beginner": 100, "Easy": 200, "Medium": 400, "Hard": 700, "Expert": 1000}
const PAR_SECONDS: Dictionary[String, int] = {"Beginner": 480, "Easy": 720, "Medium": 1200, "Hard": 1800, "Expert": 2700}

## The GDD's tiny test screen (AT-66), reported for information.
const GDD_TINY_DP_WIDTH: float = 320.0

var _failures: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	var result: Variant = call("_run")
	quit(result if result is int else 1)


func _run() -> int:
	_check_play_board()
	_check_closeup_board()
	_check_hint_board()
	_check_conflict_board()
	_check_lesson_board()
	_check_values()
	_check_layouts()
	_check_geometry()
	_print_sizes()
	_check_final_layout()
	print("")
	if _failures.is_empty():
		print("All sample, layout and geometry checks passed.")
		return 0
	for failure: String in _failures:
		print("FAIL  %s" % failure)
	print("%d check(s) failed." % _failures.size())
	return 1


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


# Sample boards

func _check_play_board() -> void:
	var board: SampleState.BoardState = SampleState.play_board()
	_check_board_basics("play", board, PackedInt32Array())
	var givens: int = 0
	var placed: int = 0
	for i: int in 81:
		givens += 1 if board.givens[i] != 0 else 0
		placed += 1 if board.placed[i] != 0 else 0
		_expect(not board.is_conflict(i), "play: no conflicts on the play board")
		_expect(board.auto_crossed[i] == 0, "play: Auto Cross is off on the play board")
	_expect(_count_solutions(board.givens, 2) == 1, "play: the puzzle must have exactly one solution")
	_expect(board.is_empty(board.selected), "play: the selected cell must be empty")
	_expect(board.mode == SampleState.MODE_CROSS_OUT, "play: the selected cell must be in Cross Out mode")
	var selected_crosses: int = _bits(board.crossed[board.selected])
	_expect(selected_crosses >= 5, "play: the selected cell needs several crosses")
	var heaviest: int = 0
	var crossed_cells: int = 0
	for i: int in 81:
		heaviest = maxi(heaviest, _bits(board.crossed[i]))
		crossed_cells += 1 if board.crossed[i] != 0 else 0
	_expect(heaviest >= 7, "play: one cell needs seven or more crosses")
	_expect(board.hint_target_cells.is_empty() and board.hint_reason_cells.is_empty(), "play: no hint on the play board")
	_expect(_box_of(board.selected) == SampleState.CLOSEUP_BOX, "play: the close-up box must hold the selected cell")
	print("Play board: %d givens, %d placed, %d empty, %d cells with hand crosses, %d on the selected cell, %d on the heaviest." % [givens, placed, 81 - givens - placed, crossed_cells, selected_crosses, heaviest])


func _check_closeup_board() -> void:
	var board: SampleState.BoardState = SampleState.closeup_board()
	_check_board_basics("close-up", board, PackedInt32Array())
	var auto_cells: int = 0
	for i: int in 81:
		if board.auto_crossed[i] != 0:
			auto_cells += 1
			_expect(_box_of(i) == SampleState.CLOSEUP_BOX, "close-up: Auto Cross marks only inside the close-up box")
	_expect(auto_cells == 1, "close-up: one cell with Auto Cross marks")


func _check_hint_board() -> void:
	var board: SampleState.BoardState = SampleState.hint_board()
	_check_board_basics("hint", board, PackedInt32Array())
	var target: int = SampleState.cell(SampleState.HINT_TARGET)
	_expect(board.selected == target and board.mode == SampleState.MODE_CROSS_OUT, "hint: the target is selected in Cross Out mode")
	for i: int in 81:
		_expect(not board.is_conflict(i), "hint: no conflicts, so the hint is not a wrong digit hint")
		if board.is_given(i):
			continue
		var ruled: int = _ruled_mask(board, i)
		_expect(board.auto_crossed[i] == ruled & ~board.crossed[i], "hint: Auto Cross marks at %s must be every ruled out candidate not crossed by hand" % SampleState.cell_name(i))
	var step: Dictionary = _first_step(board)
	_expect(step.get("technique", "") == "Hidden single", "hint: the first step in GDD order must be a hidden single, got %s" % str(step))
	_expect(step.get("group", "") == "box", "hint: the hidden single must be in a box (the text says box)")
	_expect(step.get("digit", 0) == 1, "hint: the digit must be 1 (the text says 1)")
	_expect(step.get("target", -1) == target, "hint: the target must be %s" % SampleState.HINT_TARGET)
	var reasons: PackedInt32Array = step.get("reasons", PackedInt32Array())
	var expected: PackedInt32Array = board.hint_reason_cells.duplicate()
	reasons.sort()
	expected.sort()
	_expect(reasons == expected, "hint: reason cells must be %s" % str(Array(reasons).map(SampleState.cell_name)))
	_expect(SampleState.hint_for_hint_board().text.contains("box, 1 fits"), "hint: text must match the step")


func _check_conflict_board() -> void:
	var board: SampleState.BoardState = SampleState.conflict_board()
	var wrong: int = SampleState.cell(SampleState.WRONG_CELL)
	_check_board_basics("conflict", board, PackedInt32Array([wrong]))
	var conflicts: Array[String] = []
	var first_wrong: int = -1
	for i: int in 81:
		if board.is_conflict(i):
			conflicts.append(SampleState.cell_name(i))
		if first_wrong == -1 and board.placed[i] != 0 and board.placed[i] != board.solution[i]:
			first_wrong = i
	conflicts.sort()
	_expect(conflicts == ["r2c5", "r2c8", "r3c5"], "conflict: conflict cells must be r2c5, r2c8 and r3c5, got %s" % str(conflicts))
	_expect(first_wrong == wrong, "conflict: the wrong digit hint must point at the first wrong cell in reading order")
	_expect(board.hint_target_cells == PackedInt32Array([wrong]) and board.hint_reason_cells.is_empty(), "conflict: wrong digit hint has one target and no reason cells")
	_expect(board.selected == wrong and board.mode == SampleState.MODE_PLACE, "conflict: the wrong cell is selected in Place mode")
	var same: int = 0
	for i: int in 81:
		same += 1 if board.flags(i) & SampleState.STATE_SAME_DIGIT else 0
	_expect(same >= 4, "conflict: several cells show the same digit highlight")
	var selected_flags: int = board.flags(wrong)
	_expect(selected_flags & SampleState.STATE_CONFLICT and selected_flags & SampleState.STATE_HINT_TARGET, "conflict: the selected cell is also in conflict and the hint target")
	print("State sheet: hint board (hidden single in box 1, 1 at r1c3) and conflict board (%s conflict, %d same digit cells) are valid." % [", ".join(conflicts), same])


func _check_lesson_board() -> void:
	var step: SampleState.LessonStep = SampleState.lesson_step()
	var board: SampleState.BoardState = step.board
	_check_board_basics("lesson", board, PackedInt32Array())
	var target: int = board.selected
	var row_digits: Array[int] = []
	var col_digits: Array[int] = []
	var box_digits: Array[int] = []
	for i: int in 81:
		var digit: int = board.digit_at(i)
		if digit == 0 or i == target:
			continue
		if i / 9 == target / 9:
			row_digits.append(digit)
		if i % 9 == target % 9:
			col_digits.append(digit)
		if _box_of(i) == _box_of(target):
			box_digits.append(digit)
	row_digits.sort()
	col_digits.sort()
	box_digits.sort()
	_expect(row_digits == [3, 9], "lesson: the row must hold exactly 9 and 3, holds %s" % str(row_digits))
	_expect(col_digits == [4, 6], "lesson: the column must hold exactly 4 and 6, holds %s" % str(col_digits))
	_expect(box_digits == [2, 3, 4], "lesson: the box must hold exactly 2, 3 and 4, holds %s" % str(box_digits))
	var open: Array[int] = []
	for digit: int in range(1, 10):
		if not row_digits.has(digit) and not col_digits.has(digit) and not box_digits.has(digit):
			open.append(digit)
	_expect(open == [1, 5, 7, 8], "lesson: 1, 5, 7 and 8 must stay open, got %s" % str(open))
	_expect(open.has(board.solution[target]), "lesson: the solution digit must be one of the open candidates")
	_expect(board.crossed[target] == (1 << 2) | (1 << 8), "lesson: screen 5 starts with 3 and 9 crossed")
	_expect(board.hint_reason_cells.size() == 2, "lesson: screen 5 marks two cells")
	for marked: int in board.hint_reason_cells:
		_expect(marked % 9 == target % 9 and [4, 6].has(board.digit_at(marked)), "lesson: the marked cells must be the column's 4 and 6")
	print("Lesson board: Bart's example holds (row 9 3, column 4 6, box 2 3 4, open 1 5 7 8).")


func _check_values() -> void:
	var hud: SampleState.Hud = SampleState.hud()
	_expect(hud.score == POINTS[hud.level_name] - hud.hints_used * POINTS[hud.level_name] / 5, "hud: score must be points minus hints bought (GDD 9.2)")
	_expect(hud.hint_cost == POINTS[hud.level_name] / 5, "hud: hint cost must be a fifth of the level's points (GDD 10.3)")
	_expect(hud.hint_affordable(), "hud: the hint button is enabled on the play screen")
	var done: SampleState.Completion = SampleState.completion()
	var points: int = POINTS[done.level_name]
	var par: int = PAR_SECONDS[done.level_name]
	var expected_bonus: int = points * (par - done.elapsed_seconds) / par if done.elapsed_seconds < par else 0
	_expect(done.points_after_hints == points - done.hints_used * points / 5, "completion: points after hints (GDD 9.2)")
	_expect(done.time_bonus == expected_bonus, "completion: time bonus (GDD 9.2)")
	_expect(done.score == done.points_after_hints + done.time_bonus, "completion: score is points plus bonus")
	var stats: SampleState.SampleStats = SampleState.stats()
	_expect(stats.levels.size() == 5, "stats: five levels")
	for row: SampleState.LevelStats in stats.levels:
		_expect(POINTS.has(row.level_name), "stats: unknown level %s" % row.level_name)
		_expect(row.completed <= row.started, "stats: completed cannot exceed started")
		var empty: bool = row.completed == 0
		_expect(empty == (row.best_seconds < 0) and empty == (row.average_seconds < 0) and empty == (row.best_score < 0), "stats: %s shows - exactly until its first completion" % row.level_name)
		_expect(empty or row.best_seconds <= row.average_seconds, "stats: best time cannot be slower than the average")


func _check_board_basics(label: String, board: SampleState.BoardState, wrong_cells: PackedInt32Array) -> void:
	_expect(board.givens.size() == 81 and board.placed.size() == 81 and board.crossed.size() == 81, "%s: arrays must have 81 cells" % label)
	_expect(board.auto_crossed.size() == 81, "%s: auto_crossed must have 81 cells" % label)
	_expect(_valid_solution(board.solution), "%s: the solution must be a valid grid" % label)
	for i: int in 81:
		_expect(board.givens[i] == 0 or board.givens[i] == board.solution[i], "%s: given at %s must match the solution" % [label, SampleState.cell_name(i)])
		if not wrong_cells.has(i):
			_expect(board.placed[i] == 0 or board.placed[i] == board.solution[i], "%s: placed digit at %s must match the solution" % [label, SampleState.cell_name(i)])
		_expect(board.givens[i] == 0 or board.placed[i] == 0, "%s: %s is both given and placed" % [label, SampleState.cell_name(i)])
		_expect(not board.is_given(i) or (board.crossed[i] == 0 and board.auto_crossed[i] == 0), "%s: marks on given %s" % [label, SampleState.cell_name(i)])
		var marks: int = board.crossed[i] | board.auto_crossed[i]
		if marks == 0 or not board.is_empty(i):
			continue
		for digit: int in range(1, 10):
			if board.is_crossed(i, digit) or board.is_auto_crossed(i, digit):
				_expect(_ruled_out(board, i, digit), "%s: crossed %d at %s is not ruled out by a peer" % [label, digit, SampleState.cell_name(i)])
	_expect(board.selected >= 0 and board.selected < 81, "%s: one selected cell" % label)


# GDD 10.1 and 11.1: the first step in the fixed search order, for the two
# techniques the sample needs (last empty cell, hidden single).
func _first_step(board: SampleState.BoardState) -> Dictionary:
	var groups: Array[PackedInt32Array] = _groups()
	for g: int in 27:
		var empties: PackedInt32Array = PackedInt32Array()
		for c: int in groups[g]:
			if board.is_empty(c):
				empties.append(c)
		if empties.size() == 1:
			return {"technique": "Last empty cell", "target": empties[0]}
	for g: int in 27:
		var present: Array[int] = []
		for c: int in groups[g]:
			present.append(board.digit_at(c))
		for digit: int in range(1, 10):
			if present.has(digit):
				continue
			var spots: PackedInt32Array = PackedInt32Array()
			for c: int in groups[g]:
				if board.is_empty(c) and not _ruled_out(board, c, digit):
					spots.append(c)
			if spots.size() == 1:
				var reasons: PackedInt32Array = PackedInt32Array()
				for c: int in groups[g]:
					if not board.is_empty(c) or c == spots[0]:
						continue
					for other: int in 81:
						if board.digit_at(other) == digit and board.are_peers(c, other) and not reasons.has(other):
							reasons.append(other)
				var group_kind: String = "box" if g < 9 else ("row" if g < 18 else "column")
				return {"technique": "Hidden single", "group": group_kind, "digit": digit, "target": spots[0], "reasons": reasons}
	return {}


func _groups() -> Array[PackedInt32Array]:
	var out: Array[PackedInt32Array] = []
	for g: int in 27:
		var cells: PackedInt32Array = PackedInt32Array()
		for k: int in 9:
			if g < 9:
				cells.append((g / 3) * 27 + (g % 3) * 3 + (k / 3) * 9 + k % 3)
			elif g < 18:
				cells.append((g - 9) * 9 + k)
			else:
				cells.append(k * 9 + (g - 18))
		out.append(cells)
	return out


func _ruled_out(board: SampleState.BoardState, index: int, digit: int) -> bool:
	return (_ruled_mask(board, index) >> (digit - 1)) & 1 == 1


func _ruled_mask(board: SampleState.BoardState, index: int) -> int:
	var mask: int = 0
	for other: int in 81:
		var digit: int = board.digit_at(other)
		if digit != 0 and board.are_peers(index, other):
			mask |= 1 << (digit - 1)
	return mask


func _box_of(index: int) -> int:
	return (index / 27) * 3 + (index % 9) / 3


func _valid_solution(grid: PackedInt32Array) -> bool:
	if grid.size() != 81:
		return false
	for unit: int in 9:
		var row_seen: int = 0
		var col_seen: int = 0
		var box_seen: int = 0
		for k: int in 9:
			row_seen |= 1 << grid[unit * 9 + k]
			col_seen |= 1 << grid[k * 9 + unit]
			var r: int = (unit / 3) * 3 + k / 3
			var c: int = (unit % 3) * 3 + k % 3
			box_seen |= 1 << grid[r * 9 + c]
		if row_seen != 0b1111111110 or col_seen != 0b1111111110 or box_seen != 0b1111111110:
			return false
	return true


func _count_solutions(givens: PackedInt32Array, limit: int) -> int:
	var grid: PackedInt32Array = givens.duplicate()
	return _search(grid, limit)


func _search(grid: PackedInt32Array, limit: int) -> int:
	var index: int = grid.find(0)
	if index == -1:
		return 1
	var found: int = 0
	for digit: int in range(1, 10):
		if _fits(grid, index, digit):
			grid[index] = digit
			found += _search(grid, limit - found)
			grid[index] = 0
			if found >= limit:
				break
	return found


func _fits(grid: PackedInt32Array, index: int, digit: int) -> bool:
	var row: int = index / 9
	var col: int = index % 9
	for k: int in 9:
		if grid[row * 9 + k] == digit or grid[k * 9 + col] == digit:
			return false
	var box_row: int = (row / 3) * 3
	var box_col: int = (col / 3) * 3
	for r: int in range(box_row, box_row + 3):
		for c: int in range(box_col, box_col + 3):
			if grid[r * 9 + c] == digit:
				return false
	return true


func _bits(mask: int) -> int:
	var count: int = 0
	var m: int = mask
	while m != 0:
		count += m & 1
		m >>= 1
	return count


# Ring layouts and geometry

func _check_layouts() -> void:
	var font: Font = Fonts.get_font(Fonts.Weight.SEMIBOLD)
	for layout: int in RingLayouts.COUNT:
		var digits: Array[int] = []
		for row: PackedInt32Array in RingLayouts.rows(layout):
			for digit: int in row:
				if digit != 0:
					digits.append(digit)
		digits.sort()
		_expect(digits == [1, 2, 3, 4, 5, 6, 7, 8, 9], "layout %s must hold 1 to 9 once each" % RingLayouts.SLUGS[layout])
		# Fit, overlap and open center, at a few ring sizes.
		for side: float in [60.0, 95.0, 140.0]:
			var ring: Rect2 = Rect2(Vector2.ZERO, Vector2(side, side))
			var size: int = RingLayouts.fit_font_size(layout, side, font)
			var rects: Array[Rect2] = []
			for digit: int in range(1, 10):
				var slot: Rect2 = RingLayouts.slot_rect(layout, digit, ring, font, size)
				_expect(ring.grow(0.5).encloses(slot), "layout %s: slot %d leaves the ring box" % [RingLayouts.SLUGS[layout], digit])
				_expect(not slot.has_point(ring.get_center()), "layout %s: slot %d covers the center" % [RingLayouts.SLUGS[layout], digit])
				for other: Rect2 in rects:
					_expect(not slot.grow(-0.5).intersects(other), "layout %s: slot %d overlaps another slot" % [RingLayouts.SLUGS[layout], digit])
				rects.append(slot)


## The mark band runs from the inner half of the selection frame (centered on
## the cell edge) inward by marker_w. The ring box must clear it by 1 unit
## and clear every line by 2 units.
func _check_geometry() -> void:
	for direction: String in Palettes.DIRECTIONS:
		var shape: Palettes.Shape = Palettes.shape(direction)
		var board: Rect2 = Rect2(Vector2.ZERO, Vector2(shape.board_size, shape.board_size))
		var band_end: float = shape.selected_outline_w * 0.5 + shape.marker_w
		_expect(shape.ring_inset - band_end >= 1.0, "%s: ring box must clear the mark band by 1 unit, clears %.1f" % [direction, shape.ring_inset - band_end])
		if shape.style == Palettes.STYLE_LINES:
			var line_clearance: float = shape.ring_inset - maxf(shape.line_box_w, shape.line_outer_w) * 0.5
			_expect(line_clearance >= 2.0, "%s: ring box must clear the lines by 2 units, clears %.1f" % [direction, line_clearance])
		else:
			# The ring box corner must stay inside the rounded tile.
			var r: float = shape.cell_radius
			if shape.ring_inset < r:
				var distance: float = Vector2(r - shape.ring_inset, r - shape.ring_inset).length()
				_expect(distance <= r - 1.0, "%s: ring box corner pokes out of the rounded tile" % direction)
		_expect(shape.selected_dash > 0.0 and shape.selected_gap > 0.0, "%s: Cross Out frame needs dashes" % direction)
		for index: int in 81:
			var cell: Rect2 = RingLayouts.cell_rect(direction, board, index)
			var ring: Rect2 = RingLayouts.ring_box(direction, board, index)
			_expect(board.encloses(cell), "%s: cell %d leaves the board" % [direction, index])
			_expect(cell.encloses(ring), "%s: ring box %d leaves its cell" % [direction, index])


# Final layout (DESIGN_SYSTEM.md section 4)

func _check_final_layout() -> void:
	var skin: GameSkin = Palettes.skin("pop_light")
	print("")
	print("Final layout, play and lesson screens (dp; candidates in dp at density 2 and 3)")
	for screen: LayoutModel.Screen in LayoutModel.screens():
		for kind: String in ["play", "lesson"]:
			var layout: LayoutModel.StackLayout = LayoutModel.play(screen, skin) if kind == "play" else LayoutModel.lesson(screen, skin)
			var px2: int = LayoutModel.candidate_px(layout.board, 2.0, skin)
			var px3: int = LayoutModel.candidate_px(layout.board, 3.0, skin)
			var dp2: float = float(px2) / 2.0
			var dp3: float = float(px3) / 3.0
			print("  %-34s %-6s board %5.1f (%s), cell %4.1f, candidates %4.1f / %4.1f, info zone %5.1f, hint panel %5.1f, keys %4.1f x %4.1f, right column %5.1f, gap %4.1f, spare %5.1f" % [
				screen.label, kind, layout.board, "width" if layout.board_width_bound else "height", layout.cell(), dp2, dp3,
				layout.info_zone, layout.hint_panel, layout.key_w, layout.key_h, layout.action_w, layout.gap, layout.spare])
			if kind == "lesson":
				print("  %-34s        lesson text %d dp, title %s, %s" % ["", int(LayoutModel.lesson_text_size),
					"shown" if LayoutModel.lesson_title_shown else "hidden",
					"text scrolls in the card" if LayoutModel.lesson_scrolls else "all text shows"])
			for problem: String in layout.problems:
				_failures.append("%s %s: %s" % [screen.label, kind, problem])
			if screen.judged and kind == "play":
				_expect(layout.board_width_bound, "%s: the board must be width-bound on the judged screen" % screen.label)
				_expect(minf(dp2, dp3) >= CANDIDATE_FLOOR_DP, "%s: candidates %.2f dp, below the %.1f dp floor" % [screen.label, minf(dp2, dp3), CANDIDATE_FLOOR_DP])


# Sizes for the ring layout doc

func _print_sizes() -> void:
	print("")
	print("Candidate sizes (design units; dp on 360 dp and 411 dp phones, and on the GDD's 320 dp test screen; px on a 720 px phone)")
	print("Ink is the widest and tallest digit. Board width-bound in all cases.")
	for family: String in [Fonts.FAMILY_DEFAULT, Fonts.FAMILY_INTER]:
		if not Fonts.set_family(family):
			print("  (Inter not found, skipped)")
			continue
		for direction: String in Palettes.DIRECTIONS:
			var shape: Palettes.Shape = Palettes.shape(direction)
			var pitch: float = shape.board_size / 9.0
			var cell: Rect2 = RingLayouts.cell_rect(direction, Rect2(Vector2.ZERO, Vector2(shape.board_size, shape.board_size)), 40)
			var ring: float = RingLayouts.ring_side(direction)
			print("  %s, %s font: board %d, cell pitch %.1f (%.1f dp at 360, %.1f dp at 411, %.1f dp at 320), cell %.1f, ring box %.1f" % [
				direction, family, int(shape.board_size), pitch,
				Device.units_to_dp(pitch, Device.SMALLEST_PHONE_DP_WIDTH),
				Device.units_to_dp(pitch, Device.TYPICAL_PHONE_DP_WIDTH),
				Device.units_to_dp(pitch, GDD_TINY_DP_WIDTH),
				cell.size.x, ring])
			var font: Font = Palettes.type_style(direction, Palettes.ROLE_CANDIDATE).font_at(40.0)
			for layout: int in RingLayouts.COUNT:
				var size: int = RingLayouts.candidate_font_size(direction, layout, ring, font)
				var ink: Vector2 = Fonts.digit_cell(font, size)
				print("    %-15s font %3d: %.1f dp at 360, %.1f dp at 411, %.1f dp at 320, %.1f px at 720 px; ink %.0f x %.0f (%.1f x %.1f dp at 360)" % [
					RingLayouts.SLUGS[layout], size,
					Device.units_to_dp(float(size), Device.SMALLEST_PHONE_DP_WIDTH),
					Device.units_to_dp(float(size), Device.TYPICAL_PHONE_DP_WIDTH),
					Device.units_to_dp(float(size), GDD_TINY_DP_WIDTH),
					Device.units_to_px(float(size), Device.SMALLEST_PHONE_PX_WIDTH),
					ink.x, ink.y,
					Device.units_to_dp(ink.x, Device.SMALLEST_PHONE_DP_WIDTH),
					Device.units_to_dp(ink.y, Device.SMALLEST_PHONE_DP_WIDTH)])
	Fonts.set_family(Fonts.FAMILY_DEFAULT)
