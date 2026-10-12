extends "res://tests/unit_test.gd"
## NextStep: the hint finder (GDD 10.1, 10.2, AT-41, AT-43, AT-47, AT-69) and
## placements_by for the lesson data test.

const KnownPuzzles := preload("res://tests/puzzles/known_puzzles.gd")
const Boards := preload("res://tests/puzzles/test_techniques.gd")
const TS := preload("res://src/puzzles/technique_solver.gd")


static func cell(row: int, col: int) -> int:
	return (row - 1) * 9 + (col - 1)


static func mark_index(row: int, col: int, digit: int) -> int:
	return cell(row, col) * 9 + digit - 1


static func expert_board() -> Board:
	return Board.create(KnownPuzzles.EXPERT_GIVENS)


## A Medium puzzle played forward with placements only, up to the first step
## the solver makes by elimination. Returns {"board", "solution", "technique"}.
static func medium_elimination_position() -> Dictionary:
	var puzzle: Puzzle = PuzzleGenerator.generate(2, 1)
	var solver: TechniqueSolver = TechniqueSolver.new()
	solver.load_givens(puzzle.givens)
	while solver.find_step(TS.MAX_LEVEL) != TS.NO_STEP and solver.step_cell() >= 0:
		solver.apply_step()
	var board: Board = Board.create(puzzle.givens)
	var cells: PackedInt32Array = solver.get_cells()
	for i: int in 81:
		if not board.is_given(i):
			board.digits[i] = cells[i]
	return {"board": board, "solution": puzzle.solution, "technique": TS.technique_id(solver.step_technique())}


## The hint for a candidate board from test_techniques.gd, built the way
## find() builds it, on a board whose ring is all open.
func hint_for_candidates(cand: PackedInt32Array) -> Hint:
	var solver: TechniqueSolver = TechniqueSolver.new()
	assert_true(solver.load_state(Boards.empty_cells(), cand), "board loads")
	var technique: int = solver.find_step(TS.MAX_LEVEL)
	var board: Board = Board.create(Boards.empty_cells())
	var open_marks: PackedInt32Array = NextStep._open_eliminations(solver.step_eliminations(), board)
	return NextStep._elimination_hint(solver, technique, open_marks)


func expect_text(hint: Hint, technique: StringName, text: String, reasons: Array[int]) -> void:
	assert_eq(hint.technique, technique)
	assert_eq(hint.text, text, String(technique))
	assert_eq(hint.reasons, PackedInt32Array(reasons), "%s reasons" % technique)
	assert_false(hint.technique_name.is_empty(), "%s name" % technique)


# Wrong digit (AT-41)

func test_wrong_digit_is_the_first_in_reading_order() -> void:
	var board: Board = expert_board()
	# r9c9 and r1c2 are empty; solution 2 and 8.
	board.digits[cell(9, 9)] = 5
	board.digits[cell(1, 2)] = 3
	var hint: Hint = NextStep.find(KnownPuzzles.EXPERT_SOLUTION, board)
	assert_eq(hint.technique, &"wrong_digit")
	assert_eq(hint.targets, PackedInt32Array([cell(1, 2)]))
	assert_eq(hint.text, "This 3 is not right. Erase it and look again.")
	assert_eq(hint.eliminations, PackedInt32Array())
	assert_eq(hint.placement_cell, -1)
	assert_eq(hint.lesson_title, "")


func test_correct_placed_digits_are_not_wrong() -> void:
	var board: Board = expert_board()
	board.digits[cell(1, 2)] = 8
	assert_ne(NextStep.find(KnownPuzzles.EXPERT_SOLUTION, board).technique, &"wrong_digit")


# Next step

func test_beginner_start_is_a_single_with_its_lesson() -> void:
	var puzzle: Puzzle = PuzzleGenerator.generate(0, 1)
	var hint: Hint = NextStep.find(puzzle.solution, Board.create(puzzle.givens))
	assert_true(hint.technique == &"last_empty_cell" or hint.technique == &"hidden_single", "technique")
	assert_true(hint.lesson_title == "Lesson: Last empty cell" or hint.lesson_title == "Lesson: Hidden single")
	assert_eq(hint.targets, PackedInt32Array([hint.placement_cell]))
	assert_eq(hint.placement_digit, puzzle.solution[hint.placement_cell])
	assert_eq(hint.eliminations, PackedInt32Array(), "a placement crosses nothing")


func test_find_does_not_change_the_board() -> void:
	var board: Board = expert_board()
	board.digits[cell(1, 2)] = 8
	board.marks[mark_index(1, 3, 5)] = Board.Mark.CROSSED_HAND
	var before: Dictionary = board.to_dict()
	NextStep.find(KnownPuzzles.EXPERT_SOLUTION, board)
	assert_eq(board.to_dict(), before)


func test_hints_are_repeatable() -> void:
	var position: Dictionary = medium_elimination_position()
	var a: Hint = NextStep.find(position["solution"], position["board"])
	var b: Hint = NextStep.find(position["solution"], position["board"])
	assert_eq(a.to_dict(), b.to_dict())


func test_steps_already_done_are_skipped() -> void:
	# AT-43.
	var position: Dictionary = medium_elimination_position()
	var board: Board = position["board"]
	var solution: PackedInt32Array = position["solution"]
	var first: Hint = NextStep.find(solution, board)
	assert_eq(first.technique, position["technique"], "first step is the elimination")
	assert_false(first.eliminations.is_empty())
	assert_eq(first.placement_cell, -1)
	for mark: int in first.eliminations:
		board.marks[mark] = Board.Mark.CROSSED_HAND
	var second: Hint = NextStep.find(solution, board)
	assert_ne(second.to_dict(), first.to_dict(), "a different step")
	# A wrong cross: the solution digit of an empty cell.
	for i: int in 81:
		if board.digits[i] == 0:
			board.marks[i * 9 + solution[i] - 1] = Board.Mark.CROSSED_HAND
			break
	assert_eq(NextStep.find(solution, board).to_dict(), second.to_dict(), "a wrong cross changes nothing")


func test_auto_cross_marks_count_as_done() -> void:
	var position: Dictionary = medium_elimination_position()
	var board: Board = position["board"]
	var first: Hint = NextStep.find(position["solution"], board)
	for mark: int in first.eliminations:
		board.marks[mark] = Board.Mark.CROSSED_AUTO
	assert_ne(NextStep.find(position["solution"], board).to_dict(), first.to_dict())


func test_eliminations_list_only_open_candidates() -> void:
	# AT-69: cross one of the step's candidates by hand, restore another.
	var position: Dictionary = medium_elimination_position()
	var board: Board = position["board"]
	var first: Hint = NextStep.find(position["solution"], board)
	if first.eliminations.size() < 2:
		fail("the position needs a step with two candidates to cross")
		return
	var crossed: int = first.eliminations[0]
	var restored: int = first.eliminations[1]
	board.marks[crossed] = Board.Mark.CROSSED_HAND
	board.marks[restored] = Board.Mark.RESTORED_HAND
	var hint: Hint = NextStep.find(position["solution"], board)
	var expected: PackedInt32Array = first.eliminations.duplicate()
	expected.remove_at(0)
	assert_eq(hint.technique, first.technique)
	assert_eq(hint.eliminations, expected)
	var targets: PackedInt32Array = PackedInt32Array()
	for mark: int in expected:
		if not targets.has(mark / 9):
			targets.append(mark / 9)
	assert_eq(hint.targets, targets, "targets are the cells with an open candidate")


func test_fallback_when_no_step() -> void:
	# An empty board offers the solver no step at all.
	var solution: PackedInt32Array = KnownPuzzles.pattern_grid()
	var hint: Hint = NextStep.find(solution, Board.create(Boards.empty_cells()))
	assert_eq(hint.technique, &"fallback")
	assert_eq(hint.targets, PackedInt32Array([0]))
	assert_eq(hint.text, "This cell is %d." % solution[0])
	assert_eq(hint.placement_cell, -1)
	assert_eq(hint.eliminations, PackedInt32Array())


func test_bad_solution_does_not_crash() -> void:
	var board: Board = expert_board()
	var hint: Hint = NextStep.find(PackedInt32Array([1, 2, 3]), board)
	assert_ne(hint, null)
	assert_ne(hint.technique, &"wrong_digit")


func test_a_whole_puzzle_by_hints() -> void:
	# Follow every hint on a few puzzles: placements are always the
	# solution's digit, eliminations never cross it, and every text is filled.
	var puzzles: Array[Puzzle] = [
		PuzzleSource.get_puzzle(4, KnownPuzzles.EXPERT_SEED),
		PuzzleGenerator.generate(3, 1),
		PuzzleGenerator.generate(2, 2),
	]
	var seen: Dictionary = {}
	for puzzle: Puzzle in puzzles:
		var board: Board = Board.create(puzzle.givens)
		var guard: int = 0
		while not board.is_full() and guard < 1000:
			guard += 1
			var hint: Hint = NextStep.find(puzzle.solution, board)
			seen[hint.technique] = true
			if hint.text.is_empty() or hint.text.contains("%") or hint.technique_name.is_empty():
				fail("%s: %s has no proper text" % [puzzle.id, hint.technique])
				return
			if hint.placement_cell >= 0:
				if hint.placement_digit != puzzle.solution[hint.placement_cell]:
					fail("%s: placement is wrong" % puzzle.id)
					return
				board.digits[hint.placement_cell] = hint.placement_digit
				continue
			if hint.eliminations.is_empty():
				fail("%s: %s neither places nor crosses" % [puzzle.id, hint.technique])
				return
			for mark: int in hint.eliminations:
				if puzzle.solution[mark / 9] == mark % 9 + 1:
					fail("%s: %s crosses the solution" % [puzzle.id, hint.technique])
					return
				if board.is_crossed(mark / 9, mark % 9 + 1):
					fail("%s: lists a candidate already crossed" % puzzle.id)
				board.marks[mark] = Board.Mark.CROSSED_HAND
		assert_true(board.is_solved(), "%s solved by hints" % puzzle.id)
	assert_true(seen.has(&"swordfish"), "the Expert puzzle needs its Swordfish")
	assert_false(seen.has(&"fallback"))
	assert_false(seen.has(&"wrong_digit"))


# Texts and cells for each technique, on the boards of test_techniques.gd

func test_text_last_empty_cell() -> void:
	var hint: Hint = NextStep.find(PackedInt32Array(), Board.create(Boards.last_empty_cell_board(false)))
	var reasons: Array[int] = [18, 19, 20, 21, 22, 23, 25, 26]
	expect_text(hint, &"last_empty_cell", "This row has one empty cell left. It must be 7.", reasons)
	assert_eq(hint.targets, PackedInt32Array([cell(3, 7)]))
	assert_eq(hint.lesson_title, "Lesson: Last empty cell")


func test_text_hidden_single() -> void:
	var hint: Hint = NextStep.find(PackedInt32Array(), Board.create(Boards.hidden_single_board(false)))
	var reasons: Array[int] = [cell(1, 7), cell(2, 5), cell(4, 1), cell(7, 2)]
	expect_text(hint, &"hidden_single", "In this box, 5 fits in only one cell. It goes here.", reasons)
	assert_eq(hint.placement_cell, cell(3, 3))
	assert_eq(hint.placement_digit, 5)
	assert_eq(hint.lesson_title, "Lesson: Hidden single")


func test_text_naked_single() -> void:
	var hint: Hint = NextStep.find(PackedInt32Array(), Board.create(Boards.naked_single_board(false)))
	var reasons: Array[int] = []
	expect_text(hint, &"naked_single", "Every digit but 8 is ruled out here, so this cell is 8.", reasons)
	assert_eq(hint.targets, PackedInt32Array([cell(5, 5)]))
	assert_eq(hint.lesson_title, "Lesson: Naked single")


func test_text_pointing() -> void:
	var board: Board = Board.create(Boards.pointing_board(false))
	# The player already crossed the 7 in r5c9 (GDD 10.2 example).
	board.marks[mark_index(5, 9, 7)] = Board.Mark.CROSSED_HAND
	var hint: Hint = NextStep.find(PackedInt32Array(), board)
	var reasons: Array[int] = [cell(5, 1), cell(5, 2), cell(5, 3)]
	expect_text(hint, &"pointing", "In this box, 7 can only go in one row. So cross 7 out in the rest of that row.", reasons)
	var expected: PackedInt32Array = PackedInt32Array()
	var targets: PackedInt32Array = PackedInt32Array()
	for c: int in range(4, 9):
		expected.append(mark_index(5, c, 7))
		targets.append(cell(5, c))
	assert_eq(hint.eliminations, expected)
	assert_eq(hint.targets, targets)
	assert_eq(hint.lesson_title, "")


func test_text_claiming() -> void:
	var hint: Hint = NextStep.find(PackedInt32Array(), Board.create(Boards.claiming_board(false)))
	var reasons: Array[int] = [cell(1, 1), cell(1, 2), cell(1, 3)]
	expect_text(hint, &"claiming", "In this row, 3 can only go in one box. So cross 3 out in the rest of that box.", reasons)


func test_text_naked_pair() -> void:
	var hint: Hint = hint_for_candidates(Boards.naked_pair_board(false))
	var reasons: Array[int] = [cell(9, 1), cell(9, 2)]
	expect_text(hint, &"naked_pair", "These two cells can only hold 2 and 9. So cross 2 and 9 out in the rest of this box.", reasons)


func test_text_hidden_pair() -> void:
	var hint: Hint = hint_for_candidates(Boards.hidden_pair_board(false))
	var reasons: Array[int] = []
	expect_text(hint, &"hidden_pair", "In this column, 1 and 8 can only go in these two cells. So cross out every other digit in them.", reasons)
	assert_eq(hint.targets, PackedInt32Array([cell(2, 4), cell(7, 4)]))
	assert_eq(hint.eliminations, PackedInt32Array([mark_index(2, 4, 3), mark_index(7, 4, 5), mark_index(7, 4, 9)]))


func test_text_naked_triple() -> void:
	var hint: Hint = hint_for_candidates(Boards.naked_triple_board(false))
	var reasons: Array[int] = [cell(2, 1), cell(2, 5), cell(2, 8)]
	expect_text(hint, &"naked_triple", "These three cells can only hold 4, 6 and 9. So cross those digits out in the rest of this row.", reasons)


func test_text_hidden_triple() -> void:
	var hint: Hint = hint_for_candidates(Boards.hidden_triple_board(false))
	var reasons: Array[int] = []
	expect_text(hint, &"hidden_triple", "In this box, 2, 5 and 7 can only go in these three cells. So cross out every other digit in them.", reasons)
	assert_eq(hint.targets, PackedInt32Array([cell(7, 7), cell(8, 9), cell(9, 8)]))


func test_text_x_wing() -> void:
	var hint: Hint = hint_for_candidates(Boards.x_wing_board(false))
	var reasons: Array[int] = [cell(2, 3), cell(2, 8), cell(7, 3), cell(7, 8)]
	expect_text(hint, &"x_wing", "In these two rows, 4 can only go in the same two columns. So cross 4 out in the rest of those columns.", reasons)


func test_text_y_wing() -> void:
	var hint: Hint = hint_for_candidates(Boards.y_wing_board(false))
	var reasons: Array[int] = [cell(2, 5), cell(5, 1), cell(5, 5)]
	expect_text(hint, &"y_wing", "The middle cell is 2 or 7, so one of the other two marked cells must be 5. Cross 5 out in cells that see both.", reasons)
	assert_eq(hint.targets, PackedInt32Array([cell(2, 1)]))


func test_text_swordfish() -> void:
	var hint: Hint = hint_for_candidates(Boards.swordfish_board(false))
	var reasons: Array[int] = [cell(1, 2), cell(1, 9), cell(4, 2), cell(4, 5), cell(8, 5), cell(8, 9)]
	expect_text(hint, &"swordfish", "In these three rows, 6 can only go in the same three columns. So cross 6 out in the rest of those columns.", reasons)


func test_text_xyz_wing() -> void:
	var hint: Hint = hint_for_candidates(Boards.xyz_wing_board(false))
	var reasons: Array[int] = [cell(2, 5), cell(5, 4), cell(5, 5)]
	expect_text(hint, &"xyz_wing", "One of these three cells must be 5. So cross 5 out in cells that see all three.", reasons)
	assert_eq(hint.targets, PackedInt32Array([cell(4, 5), cell(6, 5)]))


func test_column_fish_says_columns_first() -> void:
	# The X-Wing board turned on its side: columns 2 and 7.
	var cand: PackedInt32Array = Boards.blank_candidates()
	for col: int in [2, 7]:
		for r: int in range(1, 10):
			if r != 3 and r != 8:
				cand[cell(r, col)] &= ~(1 << 3)
	var hint: Hint = hint_for_candidates(cand)
	assert_eq(hint.text, "In these two columns, 4 can only go in the same two rows. So cross 4 out in the rest of those rows.")


func test_hints_save_and_load() -> void:
	var position: Dictionary = medium_elimination_position()
	var hint: Hint = NextStep.find(position["solution"], position["board"])
	var loaded: Hint = Hint.from_dict(hint.to_dict())
	assert_ne(loaded, null, "core accepts the hint")


# placements_by

func test_placements_by_last_empty_cell() -> void:
	var expected: Array[Vector2i] = [Vector2i(cell(3, 7), 7)]
	assert_eq(NextStep.placements_by(Boards.last_empty_cell_board(false), &"last_empty_cell"), expected)
	var none: Array[Vector2i] = []
	assert_eq(NextStep.placements_by(Boards.last_empty_cell_board(true), &"last_empty_cell"), none)


func test_placements_by_hidden_single() -> void:
	var found: Array[Vector2i] = NextStep.placements_by(Boards.hidden_single_board(false), &"hidden_single")
	assert_true(found.has(Vector2i(cell(3, 3), 5)), "r3c3 is 5")
	assert_false(NextStep.placements_by(Boards.hidden_single_board(true), &"hidden_single").has(Vector2i(cell(3, 3), 5)))


func test_placements_by_naked_single() -> void:
	var found: Array[Vector2i] = NextStep.placements_by(Boards.naked_single_board(false), &"naked_single")
	assert_true(found.has(Vector2i(cell(5, 5), 8)), "r5c5 is 8")
	assert_false(NextStep.placements_by(Boards.naked_single_board(true), &"naked_single").has(Vector2i(cell(5, 5), 8)))
	assert_false(NextStep.placements_by(Boards.naked_single_board(false), &"hidden_single").has(Vector2i(cell(5, 5), 8)), "not a hidden single")


func test_placements_by_are_sorted_correct_and_unique() -> void:
	var puzzle: Puzzle = PuzzleGenerator.generate(1, 4)
	for technique: StringName in [&"last_empty_cell", &"hidden_single", &"naked_single"]:
		var found: Array[Vector2i] = NextStep.placements_by(puzzle.givens, technique)
		for k: int in found.size():
			var p: Vector2i = found[k]
			assert_eq(p.y, puzzle.solution[p.x], "%s at %d" % [technique, p.x])
			if k > 0:
				var q: Vector2i = found[k - 1]
				assert_true(q.x < p.x or (q.x == p.x and q.y < p.y), "sorted and unique")
	assert_false(NextStep.placements_by(puzzle.givens, &"hidden_single").is_empty())


func test_placements_by_other_techniques_and_bad_grids() -> void:
	var none: Array[Vector2i] = []
	assert_eq(NextStep.placements_by(Boards.pointing_board(false), &"pointing"), none)
	assert_eq(NextStep.placements_by(Boards.hidden_single_board(false), &"no_such"), none)
	assert_eq(NextStep.placements_by(PackedInt32Array([1, 2]), &"hidden_single"), none)
	var clash: PackedInt32Array = Boards.hidden_single_board(false)
	clash[1] = 5
	clash[2] = 5
	assert_eq(NextStep.placements_by(clash, &"hidden_single"), none)
