extends "res://tests/unit_test.gd"
## Each of the 13 techniques of GDD 11.3 on a small board built from the
## GDD's own example: the solver's first step is that technique with the
## GDD's conclusion. The same board with the pattern broken never reports it.
##
## Boards are either givens (the solver works out candidates) or a blank
## board where every cell has all nine candidates, plus the example's
## candidates. A blank board offers no step at all, so the first step found
## is the pattern under test.

const TS := preload("res://src/puzzles/technique_solver.gd")
const KnownPuzzles := preload("res://tests/puzzles/known_puzzles.gd")


static func cell(row: int, col: int) -> int:
	return (row - 1) * 9 + (col - 1)


static func digits(text: String) -> int:
	var mask: int = 0
	for ch: String in text:
		mask |= 1 << (ch.to_int() - 1)
	return mask


static func empty_cells() -> PackedInt32Array:
	var cells: PackedInt32Array = PackedInt32Array()
	cells.resize(81)
	cells.fill(0)
	return cells


static func blank_candidates() -> PackedInt32Array:
	var cand: PackedInt32Array = PackedInt32Array()
	cand.resize(81)
	cand.fill(0x1FF)
	return cand


## Givens from "r3c7=7" style entries.
static func givens(entries: Array[String]) -> PackedInt32Array:
	var cells: PackedInt32Array = empty_cells()
	for entry: String in entries:
		cells[cell(entry.substr(1, 1).to_int(), entry.substr(3, 1).to_int())] = entry.substr(5, 1).to_int()
	return cells


## Eliminations as "r2c1:5 r4c5:57" in reading order.
static func describe(pairs: PackedInt32Array) -> String:
	var masks: PackedInt32Array = PackedInt32Array()
	masks.resize(81)
	masks.fill(0)
	for k: int in range(0, pairs.size(), 2):
		masks[pairs[k]] |= pairs[k + 1]
	var parts: PackedStringArray = PackedStringArray()
	for i: int in 81:
		if masks[i] == 0:
			continue
		var text: String = "r%dc%d:" % [i / 9 + 1, i % 9 + 1]
		for d: int in range(1, 10):
			if masks[i] & (1 << (d - 1)):
				text += str(d)
		parts.append(text)
	return " ".join(parts)


func first_step_from_givens(cells: PackedInt32Array) -> TechniqueSolver:
	var solver: TechniqueSolver = TechniqueSolver.new()
	assert_true(solver.load_givens(cells), "board loads")
	solver.find_step(TS.MAX_LEVEL)
	return solver


func first_step_from_state(cand: PackedInt32Array) -> TechniqueSolver:
	var solver: TechniqueSolver = TechniqueSolver.new()
	assert_true(solver.load_state(empty_cells(), cand), "board loads")
	solver.find_step(TS.MAX_LEVEL)
	return solver


func expect_placement(solver: TechniqueSolver, technique: int, row: int, col: int, digit: int) -> void:
	var name: StringName = TS.technique_id(technique)
	assert_eq(TS.technique_id(solver.step_technique()), name, "technique")
	assert_eq(solver.step_cell(), cell(row, col), "%s cell" % name)
	assert_eq(solver.step_digit(), digit, "%s digit" % name)
	assert_eq(solver.step_eliminations().size(), 0, "%s eliminates nothing" % name)


func expect_eliminations(solver: TechniqueSolver, technique: int, expected: String) -> void:
	var name: StringName = TS.technique_id(technique)
	assert_eq(TS.technique_id(solver.step_technique()), name, "technique")
	assert_eq(solver.step_cell(), -1, "%s places nothing" % name)
	assert_eq(describe(solver.step_eliminations()), expected, "%s eliminations" % name)


func expect_not(solver: TechniqueSolver, technique: int) -> void:
	assert_ne(solver.step_technique(), technique, "%s is not reported" % TS.technique_id(technique))


# Boards

## 1. Row 3 holds 1 to 6, 8 and 9; r3c7 is empty.
static func last_empty_cell_board(broken: bool) -> PackedInt32Array:
	var entries: Array[String] = ["r3c1=1", "r3c2=2", "r3c3=3", "r3c4=4", "r3c5=5", "r3c6=6", "r3c8=8"]
	if not broken:
		entries.append("r3c9=9")
	return givens(entries)


## 2. 5s at r1c7, r2c5, r4c1 and r7c2; box 1 empty.
static func hidden_single_board(broken: bool) -> PackedInt32Array:
	var entries: Array[String] = ["r1c7=5", "r2c5=5", "r4c1=5"]
	if not broken:
		entries.append("r7c2=5")
	return givens(entries)


## 3. Position B (GDD 4.4) plus r5c9 = 1, r2c5 = 5 and r9c5 = 7.
static func naked_single_board(broken: bool) -> PackedInt32Array:
	var entries: Array[String] = [
		"r5c1=9", "r5c8=3", "r1c5=4", "r8c5=6", "r4c4=2", "r4c6=4", "r6c6=3",
		"r5c9=1", "r2c5=5",
	]
	if not broken:
		entries.append("r9c5=7")
	return givens(entries)


## 4. Box 4 holds 1, 2, 3 in r4c1 to r4c3 and 4, 5, 6 in r6c1 to r6c3.
static func pointing_board(broken: bool) -> PackedInt32Array:
	var entries: Array[String] = ["r4c1=1", "r4c2=2", "r4c3=3"]
	if not broken:
		entries.append_array(["r6c1=4", "r6c2=5", "r6c3=6"])
	return givens(entries)


## 5. Row 1 holds 1, 2, 4, 5, 6 and 7 in r1c4 to r1c9.
static func claiming_board(broken: bool) -> PackedInt32Array:
	var entries: Array[String] = ["r1c4=1", "r1c5=2", "r1c6=4", "r1c7=5", "r1c8=6"]
	if not broken:
		entries.append("r1c9=7")
	return givens(entries)


## 6. r9c1 and r9c2 both have only 2 and 9.
static func naked_pair_board(broken: bool) -> PackedInt32Array:
	var cand: PackedInt32Array = blank_candidates()
	cand[cell(9, 1)] = digits("29")
	cand[cell(9, 2)] = digits("289") if broken else digits("29")
	return cand


## 7. In column 4, 1 and 8 appear only in r2c4 (1, 3, 8) and r7c4 (1, 5, 8, 9).
static func hidden_pair_board(broken: bool) -> PackedInt32Array:
	var cand: PackedInt32Array = blank_candidates()
	for r: int in range(1, 10):
		cand[cell(r, 4)] &= ~digits("18")
	cand[cell(2, 4)] = digits("138")
	cand[cell(7, 4)] = digits("1589")
	if broken:
		cand[cell(5, 4)] |= digits("8")
	return cand


## 8. In row 2, r2c1 has 4 and 6, r2c5 has 6 and 9, r2c8 has 4 and 9.
static func naked_triple_board(broken: bool) -> PackedInt32Array:
	var cand: PackedInt32Array = blank_candidates()
	cand[cell(2, 1)] = digits("46")
	cand[cell(2, 5)] = digits("69")
	cand[cell(2, 8)] = digits("479") if broken else digits("49")
	return cand


## 9. In box 9, 2, 5 and 7 appear only in r7c7 (2, 5, 6), r8c9 (1, 5, 7) and
## r9c8 (2, 4, 7).
static func hidden_triple_board(broken: bool) -> PackedInt32Array:
	var cand: PackedInt32Array = blank_candidates()
	for r: int in range(7, 10):
		for c: int in range(7, 10):
			cand[cell(r, c)] &= ~digits("257")
	cand[cell(7, 7)] = digits("256")
	cand[cell(8, 9)] = digits("157")
	cand[cell(9, 8)] = digits("247")
	if broken:
		cand[cell(9, 9)] |= digits("5")
	return cand


## 10. In rows 2 and 7, 4 is a candidate only in r2c3, r2c8, r7c3 and r7c8.
static func x_wing_board(broken: bool) -> PackedInt32Array:
	var cand: PackedInt32Array = blank_candidates()
	for row: int in [2, 7]:
		for c: int in range(1, 10):
			if c != 3 and c != 8:
				cand[cell(row, c)] &= ~digits("4")
	if broken:
		cand[cell(7, 5)] |= digits("4")
	return cand


## 11. Pivot r5c5 (2, 7), wings r5c1 (2, 5) and r2c5 (5, 7).
static func y_wing_board(broken: bool) -> PackedInt32Array:
	var cand: PackedInt32Array = blank_candidates()
	cand[cell(5, 5)] = digits("27")
	cand[cell(5, 1)] = digits("25")
	cand[cell(2, 5)] = digits("58") if broken else digits("57")
	return cand


## 12. In rows 1, 4 and 8, 6 is a candidate only in r1c2, r1c9, r4c2, r4c5,
## r8c5 and r8c9.
static func swordfish_board(broken: bool) -> PackedInt32Array:
	var cand: PackedInt32Array = blank_candidates()
	var keep: Dictionary = {1: [2, 9], 4: [2, 5], 8: [5, 9]}
	for row: int in keep:
		var cols: Array = keep[row]
		for c: int in range(1, 10):
			if not cols.has(c):
				cand[cell(row, c)] &= ~digits("6")
	if broken:
		cand[cell(4, 7)] |= digits("6")
	return cand


## 13. Pivot r5c5 (2, 5, 7), wings r5c4 (2, 5) and r2c5 (5, 7).
static func xyz_wing_board(broken: bool) -> PackedInt32Array:
	var cand: PackedInt32Array = blank_candidates()
	cand[cell(5, 5)] = digits("2578") if broken else digits("257")
	cand[cell(5, 4)] = digits("25")
	cand[cell(2, 5)] = digits("57")
	return cand


# Found where the pattern is

func test_01_last_empty_cell() -> void:
	expect_placement(first_step_from_givens(last_empty_cell_board(false)), TS.LAST_EMPTY_CELL, 3, 7, 7)


func test_02_hidden_single() -> void:
	expect_placement(first_step_from_givens(hidden_single_board(false)), TS.HIDDEN_SINGLE, 3, 3, 5)


func test_03_naked_single() -> void:
	expect_placement(first_step_from_givens(naked_single_board(false)), TS.NAKED_SINGLE, 5, 5, 8)


func test_04_pointing() -> void:
	expect_eliminations(first_step_from_givens(pointing_board(false)), TS.POINTING,
		"r5c4:7 r5c5:7 r5c6:7 r5c7:7 r5c8:7 r5c9:7")


func test_05_claiming() -> void:
	expect_eliminations(first_step_from_givens(claiming_board(false)), TS.CLAIMING,
		"r2c1:3 r2c2:3 r2c3:3 r3c1:3 r3c2:3 r3c3:3")


func test_06_naked_pair() -> void:
	expect_eliminations(first_step_from_state(naked_pair_board(false)), TS.NAKED_PAIR,
		"r7c1:29 r7c2:29 r7c3:29 r8c1:29 r8c2:29 r8c3:29 r9c3:29 r9c4:29 r9c5:29 r9c6:29 r9c7:29 r9c8:29 r9c9:29")


func test_07_hidden_pair() -> void:
	expect_eliminations(first_step_from_state(hidden_pair_board(false)), TS.HIDDEN_PAIR,
		"r2c4:3 r7c4:59")


func test_08_naked_triple() -> void:
	expect_eliminations(first_step_from_state(naked_triple_board(false)), TS.NAKED_TRIPLE,
		"r2c2:469 r2c3:469 r2c4:469 r2c6:469 r2c7:469 r2c9:469")


func test_09_hidden_triple() -> void:
	expect_eliminations(first_step_from_state(hidden_triple_board(false)), TS.HIDDEN_TRIPLE,
		"r7c7:6 r8c9:1 r9c8:4")


func test_10_x_wing() -> void:
	expect_eliminations(first_step_from_state(x_wing_board(false)), TS.X_WING,
		"r1c3:4 r1c8:4 r3c3:4 r3c8:4 r4c3:4 r4c8:4 r5c3:4 r5c8:4 r6c3:4 r6c8:4 r8c3:4 r8c8:4 r9c3:4 r9c8:4")


func test_11_y_wing() -> void:
	expect_eliminations(first_step_from_state(y_wing_board(false)), TS.Y_WING, "r2c1:5")


func test_12_swordfish() -> void:
	expect_eliminations(first_step_from_state(swordfish_board(false)), TS.SWORDFISH,
		"r2c2:6 r2c5:6 r2c9:6 r3c2:6 r3c5:6 r3c9:6 r5c2:6 r5c5:6 r5c9:6 r6c2:6 r6c5:6 r6c9:6 r7c2:6 r7c5:6 r7c9:6 r9c2:6 r9c5:6 r9c9:6")


func test_13_xyz_wing() -> void:
	expect_eliminations(first_step_from_state(xyz_wing_board(false)), TS.XYZ_WING, "r4c5:5 r6c5:5")


# Not reported where the pattern is broken

func test_01_last_empty_cell_absent() -> void:
	expect_not(first_step_from_givens(last_empty_cell_board(true)), TS.LAST_EMPTY_CELL)


func test_02_hidden_single_absent() -> void:
	expect_not(first_step_from_givens(hidden_single_board(true)), TS.HIDDEN_SINGLE)


func test_03_naked_single_absent() -> void:
	expect_not(first_step_from_givens(naked_single_board(true)), TS.NAKED_SINGLE)


func test_04_pointing_absent() -> void:
	expect_not(first_step_from_givens(pointing_board(true)), TS.POINTING)


func test_05_claiming_absent() -> void:
	expect_not(first_step_from_givens(claiming_board(true)), TS.CLAIMING)


func test_06_naked_pair_absent() -> void:
	expect_not(first_step_from_state(naked_pair_board(true)), TS.NAKED_PAIR)


func test_07_hidden_pair_absent() -> void:
	expect_not(first_step_from_state(hidden_pair_board(true)), TS.HIDDEN_PAIR)


func test_08_naked_triple_absent() -> void:
	expect_not(first_step_from_state(naked_triple_board(true)), TS.NAKED_TRIPLE)


func test_09_hidden_triple_absent() -> void:
	expect_not(first_step_from_state(hidden_triple_board(true)), TS.HIDDEN_TRIPLE)


func test_10_x_wing_absent() -> void:
	expect_not(first_step_from_state(x_wing_board(true)), TS.X_WING)


func test_11_y_wing_absent() -> void:
	expect_not(first_step_from_state(y_wing_board(true)), TS.Y_WING)


func test_12_swordfish_absent() -> void:
	expect_not(first_step_from_state(swordfish_board(true)), TS.SWORDFISH)


func test_13_xyz_wing_absent() -> void:
	expect_not(first_step_from_state(xyz_wing_board(true)), TS.XYZ_WING)


## The broken boards offer no step at all, so nothing else hides the check.
func test_broken_candidate_boards_offer_no_step() -> void:
	var boards: Array[PackedInt32Array] = [
		naked_pair_board(true), hidden_pair_board(true), naked_triple_board(true),
		hidden_triple_board(true), x_wing_board(true), y_wing_board(true),
		swordfish_board(true), xyz_wing_board(true),
	]
	for k: int in boards.size():
		assert_eq(first_step_from_state(boards[k]).step_technique(), TS.NO_STEP, "broken board %d" % k)


func test_blank_board_offers_no_step() -> void:
	assert_eq(first_step_from_state(blank_candidates()).step_technique(), TS.NO_STEP)


# Levels, order and grading

func test_max_level_hides_harder_techniques() -> void:
	var solver: TechniqueSolver = TechniqueSolver.new()
	solver.load_state(empty_cells(), x_wing_board(false))
	assert_eq(solver.find_step(2), TS.NO_STEP, "X-Wing is Hard, not Medium")
	assert_eq(solver.find_step(3), TS.X_WING)
	solver.load_state(empty_cells(), xyz_wing_board(false))
	assert_eq(solver.find_step(3), TS.NO_STEP, "XYZ-Wing is Expert, not Hard")
	assert_eq(solver.find_step(4), TS.XYZ_WING)
	solver.load_givens(naked_single_board(false))
	assert_eq(solver.find_step(0), TS.NO_STEP, "naked single is Easy, not Beginner")


func test_apply_step_removes_the_candidates() -> void:
	var solver: TechniqueSolver = TechniqueSolver.new()
	solver.load_state(empty_cells(), y_wing_board(false))
	assert_eq(solver.find_step(), TS.Y_WING)
	solver.apply_step()
	assert_eq(solver.get_candidates()[cell(2, 1)], digits("12346789"))
	assert_eq(solver.step_technique(), TS.NO_STEP, "the step is used up")


func test_apply_step_places_the_digit() -> void:
	var solver: TechniqueSolver = TechniqueSolver.new()
	solver.load_givens(hidden_single_board(false))
	solver.find_step()
	solver.apply_step()
	assert_eq(solver.get_cells()[cell(3, 3)], 5)
	assert_eq(solver.get_candidates()[cell(3, 3)], 0)
	assert_eq(solver.get_candidates()[cell(3, 1)] & digits("5"), 0, "peers lose the 5")


func test_technique_order_and_levels_match_the_gdd() -> void:
	assert_eq(TS.TECHNIQUES, [
		&"last_empty_cell", &"hidden_single", &"naked_single", &"pointing", &"claiming",
		&"naked_pair", &"hidden_pair", &"naked_triple", &"hidden_triple", &"x_wing",
		&"y_wing", &"swordfish", &"xyz_wing",
	] as Array[StringName])
	assert_eq(TS.TECHNIQUE_LEVELS, PackedInt32Array([0, 0, 1, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4]))


func test_grade_rejects_input_that_is_not_a_grid() -> void:
	var short: PackedInt32Array = empty_cells()
	short.resize(80)
	var high: PackedInt32Array = empty_cells()
	high[0] = 10
	var clash: PackedInt32Array = givens(["r1c1=3", "r2c2=3"])
	for grid: PackedInt32Array in [PackedInt32Array(), short, high, clash]:
		var result: GradeResult = TechniqueSolver.grade(grid)
		assert_false(result.solved)
		assert_eq(result.level, -1)
		assert_eq(result.step_count, 0)
		assert_eq(result.hardest, &"")
		assert_eq(result.technique_counts, {})


func test_load_state_rejects_bad_masks() -> void:
	var solver: TechniqueSolver = TechniqueSolver.new()
	var cand: PackedInt32Array = blank_candidates()
	cand[5] = 512
	assert_false(solver.load_state(empty_cells(), cand))
	cand[5] = -1
	assert_false(solver.load_state(empty_cells(), cand))
	var short: PackedInt32Array = blank_candidates()
	short.resize(80)
	assert_false(solver.load_state(empty_cells(), short))
	assert_eq(solver.find_step(), TS.NO_STEP, "nothing loaded, nothing found")


func test_grade_empty_grid_is_stuck() -> void:
	var result: GradeResult = TechniqueSolver.grade(empty_cells())
	assert_false(result.solved)
	assert_eq(result.level, -1)
	assert_eq(result.step_count, 0)


func test_grade_full_grid_needs_nothing() -> void:
	var result: GradeResult = TechniqueSolver.grade(KnownPuzzles.EXPERT_SOLUTION)
	assert_true(result.solved)
	assert_eq(result.level, 0)
	assert_eq(result.hardest, &"")
	assert_eq(result.step_count, 0)


func test_grade_one_hole_is_last_empty_cell() -> void:
	var grid: PackedInt32Array = KnownPuzzles.EXPERT_SOLUTION.duplicate()
	grid[cell(4, 6)] = 0
	var result: GradeResult = TechniqueSolver.grade(grid)
	assert_true(result.solved)
	assert_eq(result.level, 0)
	assert_eq(result.hardest, &"last_empty_cell")
	assert_eq(result.step_count, 1)
	assert_eq(result.technique_counts, {&"last_empty_cell": 1})


func test_grade_known_expert_puzzle() -> void:
	var result: GradeResult = TechniqueSolver.grade(KnownPuzzles.EXPERT_GIVENS)
	assert_true(result.solved)
	assert_eq(result.level, 4)
	assert_eq(result.hardest, KnownPuzzles.EXPERT_HARDEST)
	var total: int = 0
	for technique: StringName in result.technique_counts:
		total += result.technique_counts[technique]
	assert_eq(total, result.step_count, "counts add up to the steps")
	var empties: int = 0
	for value: int in KnownPuzzles.EXPERT_GIVENS:
		if value == 0:
			empties += 1
	var placements: int = 0
	for technique: StringName in [&"last_empty_cell", &"hidden_single", &"naked_single"]:
		placements += result.technique_counts.get(technique, 0)
	assert_eq(placements, empties, "one placement per empty cell")


func test_grade_is_stuck_with_two_solutions() -> void:
	# The six swappable cells of test_solver.gd: two solutions, so no
	# technique can finish the board.
	var grid: PackedInt32Array = KnownPuzzles.pattern_grid()
	for c: int in [1, 4, 7]:
		grid[cell(1, c)] = 0
		grid[cell(2, c)] = 0
	var result: GradeResult = TechniqueSolver.grade(grid)
	assert_false(result.solved)
	assert_eq(result.level, -1)
	assert_eq(result.step_count, 0)


func test_solves_agrees_with_run_on_the_known_puzzle() -> void:
	var solver: TechniqueSolver = TechniqueSolver.new()
	for level: int in 5:
		solver.load_givens(KnownPuzzles.EXPERT_GIVENS)
		assert_eq(solver.solves(level), level == 4, "solves(%d)" % level)
		solver.load_givens(KnownPuzzles.EXPERT_GIVENS)
		assert_eq(solver.run(level), level == 4, "run(%d)" % level)
