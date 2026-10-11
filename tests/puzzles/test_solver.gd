extends "res://tests/unit_test.gd"
## The backtracking Solver on puzzles with one, several and no solutions, and
## on input that is not a grid.

const KnownPuzzles := preload("res://tests/puzzles/known_puzzles.gd")


static func pattern_grid() -> PackedInt32Array:
	return KnownPuzzles.pattern_grid()


static func empty_grid() -> PackedInt32Array:
	var grid: PackedInt32Array = PackedInt32Array()
	grid.resize(81)
	grid.fill(0)
	return grid


static func cell(row: int, col: int) -> int:
	return (row - 1) * 9 + (col - 1)


func test_pattern_grid_is_valid() -> void:
	assert_true(KnownPuzzles.is_valid_solution(pattern_grid()))


func test_full_grid_has_one_solution() -> void:
	var grid: PackedInt32Array = pattern_grid()
	assert_eq(Solver.count_solutions(grid), 1)
	assert_eq(Solver.solve(grid), grid)


func test_one_hole_per_row_has_one_solution() -> void:
	var full: PackedInt32Array = pattern_grid()
	var grid: PackedInt32Array = full.duplicate()
	for r: int in range(1, 10):
		grid[cell(r, r)] = 0
	assert_eq(Solver.count_solutions(grid, 5), 1)
	assert_eq(Solver.solve(grid), full)


func test_generated_expert_puzzle_has_one_solution() -> void:
	# Made by our own generator and kept in known_puzzles.gd.
	var puzzle: PackedInt32Array = KnownPuzzles.EXPERT_GIVENS
	var solution: PackedInt32Array = KnownPuzzles.EXPERT_SOLUTION
	assert_eq(Solver.count_solutions(puzzle, 2), 1)
	assert_eq(Solver.solve(puzzle), solution)


func test_input_grid_is_not_changed() -> void:
	var grid: PackedInt32Array = KnownPuzzles.EXPERT_GIVENS.duplicate()
	Solver.solve(grid)
	Solver.count_solutions(grid, 2)
	assert_eq(grid, KnownPuzzles.EXPERT_GIVENS)


func test_empty_grid_has_many_solutions() -> void:
	assert_eq(Solver.count_solutions(empty_grid(), 2), 2)
	assert_eq(Solver.count_solutions(empty_grid(), 7), 7)
	assert_true(KnownPuzzles.is_valid_solution(Solver.solve(empty_grid())))


func test_swappable_rectangle_has_exactly_two_solutions() -> void:
	# Rows 1 and 2 hold 1, 4, 7 and 4, 7, 1 in columns 1, 4 and 7, so those
	# six cells can be swapped between the rows. Emptying them leaves exactly
	# two solutions.
	var grid: PackedInt32Array = pattern_grid()
	for c: int in [1, 4, 7]:
		grid[cell(1, c)] = 0
		grid[cell(2, c)] = 0
	assert_eq(Solver.count_solutions(grid, 10), 2)
	assert_eq(Solver.count_solutions(grid, 2), 2)
	assert_eq(Solver.solve(grid), pattern_grid(), "first solution in digit order")


func test_limit_stops_counting() -> void:
	assert_eq(Solver.count_solutions(empty_grid(), 1), 1)
	assert_eq(Solver.count_solutions(empty_grid(), 0), 1, "a limit below 1 counts as 1")


func test_conflicting_givens_have_no_solution() -> void:
	var grid: PackedInt32Array = empty_grid()
	grid[cell(1, 1)] = 5
	grid[cell(1, 9)] = 5
	assert_eq(Solver.count_solutions(grid), 0, "same digit twice in a row")
	assert_eq(Solver.solve(grid), PackedInt32Array())
	grid = empty_grid()
	grid[cell(1, 1)] = 5
	grid[cell(9, 1)] = 5
	assert_eq(Solver.count_solutions(grid), 0, "same digit twice in a column")
	grid = empty_grid()
	grid[cell(1, 1)] = 5
	grid[cell(3, 3)] = 5
	assert_eq(Solver.count_solutions(grid), 0, "same digit twice in a box")


func test_cell_with_no_candidate_has_no_solution() -> void:
	# r1c2 to r1c9 hold 1 to 8 and r5c1 holds 9, so r1c1 can hold nothing.
	var grid: PackedInt32Array = empty_grid()
	for c: int in range(2, 10):
		grid[cell(1, c)] = c - 1
	grid[cell(5, 1)] = 9
	assert_eq(Solver.count_solutions(grid), 0)
	assert_eq(Solver.solve(grid), PackedInt32Array())


func test_full_grid_with_a_clash_has_no_solution() -> void:
	var grid: PackedInt32Array = pattern_grid()
	var swap: int = grid[0]
	grid[0] = grid[1]
	grid[1] = swap
	assert_eq(Solver.count_solutions(grid), 0)


func test_input_that_is_not_a_grid_has_no_solution() -> void:
	assert_eq(Solver.count_solutions(PackedInt32Array()), 0)
	var short: PackedInt32Array = empty_grid()
	short.resize(80)
	assert_eq(Solver.count_solutions(short), 0)
	var long: PackedInt32Array = empty_grid()
	long.append(0)
	assert_eq(Solver.count_solutions(long), 0)
	var high: PackedInt32Array = empty_grid()
	high[40] = 10
	assert_eq(Solver.count_solutions(high), 0)
	var negative: PackedInt32Array = empty_grid()
	negative[40] = -1
	assert_eq(Solver.count_solutions(negative), 0)
	assert_eq(Solver.solve(negative), PackedInt32Array())

