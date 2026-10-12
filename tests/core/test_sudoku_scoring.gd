extends "res://tests/unit_test.gd"
## Sudoku helpers, Levels and Scoring (GDD 9, 10.3, 11.2).

const F := preload("res://tests/core/core_fixtures.gd")


func test_cell_coordinates() -> void:
	assert_eq(Sudoku.row(0), 0)
	assert_eq(Sudoku.col(80), 8)
	assert_eq(Sudoku.row(40), 4)
	assert_eq(Sudoku.col(40), 4)
	assert_eq(Sudoku.box(0), 0)
	assert_eq(Sudoku.box(40), 4)
	assert_eq(Sudoku.box(80), 8)
	assert_eq(Sudoku.box(F.rc(4, 7)), 5)
	assert_eq(Sudoku.cell_at(4, 4), 40)
	for cell: int in 81:
		assert_eq(Sudoku.cell_at(Sudoku.row(cell), Sudoku.col(cell)), cell)


func test_peers_are_twenty_ascending_and_correct() -> void:
	for cell: int in 81:
		var peers: PackedInt32Array = Sudoku.peers(cell)
		assert_eq(peers.size(), 20, "cell %d" % cell)
		for i: int in peers.size():
			var p: int = peers[i]
			assert_ne(p, cell)
			assert_true(Sudoku.row(p) == Sudoku.row(cell) or Sudoku.col(p) == Sudoku.col(cell) or Sudoku.box(p) == Sudoku.box(cell))
			if i > 0:
				assert_true(peers[i - 1] < p, "ascending")
	assert_eq(Sudoku.peers(-1).size(), 0)
	assert_eq(Sudoku.peers(81).size(), 0)


func test_peers_returns_a_copy() -> void:
	var peers: PackedInt32Array = Sudoku.peers(0)
	peers[0] = 99
	assert_eq(Sudoku.peers(0)[0], 1)


func test_group_order_boxes_rows_columns() -> void:
	assert_eq(Sudoku.group_cells(0), PackedInt32Array([0, 1, 2, 9, 10, 11, 18, 19, 20]))
	assert_eq(Sudoku.group_cells(8), PackedInt32Array([60, 61, 62, 69, 70, 71, 78, 79, 80]))
	assert_eq(Sudoku.group_cells(9), PackedInt32Array([0, 1, 2, 3, 4, 5, 6, 7, 8]))
	assert_eq(Sudoku.group_cells(18), PackedInt32Array([0, 9, 18, 27, 36, 45, 54, 63, 72]))
	assert_eq(Sudoku.group_cells(26)[8], 80)
	assert_eq(Sudoku.group_cells(27).size(), 0)


func test_is_grid_and_complete_solution() -> void:
	assert_true(Sudoku.is_grid(F.empty_grid()))
	assert_true(Sudoku.is_grid(F.solution_b()))
	var short: PackedInt32Array = PackedInt32Array([1, 2, 3])
	assert_false(Sudoku.is_grid(short))
	var bad: PackedInt32Array = F.empty_grid()
	bad[5] = 10
	assert_false(Sudoku.is_grid(bad))
	bad[5] = -1
	assert_false(Sudoku.is_grid(bad))
	assert_true(Sudoku.is_complete_solution(F.solution_b()))
	assert_false(Sudoku.is_complete_solution(F.position_b_givens()))
	var swapped: PackedInt32Array = F.solution_b()
	var tmp: int = swapped[0]
	swapped[0] = swapped[1]
	swapped[1] = tmp
	assert_false(Sudoku.is_complete_solution(swapped), "two swapped digits clash in columns")


func test_levels() -> void:
	assert_eq(Levels.COUNT, 5)
	assert_eq(Levels.name_of(Levels.BEGINNER), "Beginner")
	assert_eq(Levels.name_of(Levels.EASY), "Easy")
	assert_eq(Levels.name_of(Levels.MEDIUM), "Medium")
	assert_eq(Levels.name_of(Levels.HARD), "Hard")
	assert_eq(Levels.name_of(Levels.EXPERT), "Expert")
	assert_eq(Levels.name_of(5), "")
	assert_true(Levels.is_valid(0))
	assert_true(Levels.is_valid(4))
	assert_false(Levels.is_valid(-1))
	assert_false(Levels.is_valid(5))


func test_points_par_and_cost_table() -> void:
	# GDD 9.1. AT-46: hint cost per level.
	assert_eq([Scoring.points(0), Scoring.points(1), Scoring.points(2), Scoring.points(3), Scoring.points(4)], [100, 200, 400, 700, 1000])
	assert_eq([Scoring.par_seconds(0), Scoring.par_seconds(1), Scoring.par_seconds(2), Scoring.par_seconds(3), Scoring.par_seconds(4)], [480, 720, 1200, 1800, 2700])
	assert_eq([Scoring.hint_cost(0), Scoring.hint_cost(1), Scoring.hint_cost(2), Scoring.hint_cost(3), Scoring.hint_cost(4)], [20, 40, 80, 140, 200])
	assert_eq(Scoring.points(-1), 0)
	assert_eq(Scoring.hint_cost(9), 0)


func test_worked_examples_9_3() -> void:
	# AT-39: the five examples of GDD 9.3.
	assert_eq(Scoring.live_score(Levels.EASY, 1), 160)
	assert_eq(Scoring.time_bonus(Levels.EASY, 540), 50)
	assert_eq(Scoring.final_score(Levels.EASY, 1, 540), 210)
	assert_eq(Scoring.final_score(Levels.MEDIUM, 0, 1500), 400)
	assert_eq(Scoring.time_bonus(Levels.MEDIUM, 900), 100)
	assert_eq(Scoring.final_score(Levels.MEDIUM, 1, 900), 420)
	assert_eq(Scoring.live_score(Levels.HARD, 2), 420)
	assert_eq(Scoring.time_bonus(Levels.HARD, 1350), 175)
	assert_eq(Scoring.final_score(Levels.HARD, 2, 1350), 595)
	assert_eq(Scoring.live_score(Levels.BEGINNER, 5), 0)
	assert_eq(Scoring.time_bonus(Levels.BEGINNER, 420), 12)
	assert_eq(Scoring.final_score(Levels.BEGINNER, 5, 420), 12)


func test_time_bonus_at_and_over_par_and_score_floor() -> void:
	# AT-39: T is 0 at t = P and above; S is never below 0.
	for level: int in Levels.COUNT:
		var par: int = Scoring.par_seconds(level)
		assert_eq(Scoring.time_bonus(level, par), 0)
		assert_eq(Scoring.time_bonus(level, par + 1), 0)
		assert_eq(Scoring.time_bonus(level, 0), Scoring.points(level))
		assert_eq(Scoring.live_score(level, 5), 0)
		assert_eq(Scoring.live_score(level, 6), 0, "more than five hints never goes below 0")
		assert_eq(Scoring.live_score(level, -3), Scoring.points(level))
	assert_eq(Scoring.time_bonus(Levels.EASY, -100), 200, "a negative time counts as 0")


func test_section_10_3_examples() -> void:
	assert_eq(Scoring.live_score(Levels.EASY, 0), 200)
	assert_eq(Scoring.live_score(Levels.EASY, 1), 160)
	assert_eq(Scoring.live_score(Levels.MEDIUM, 2), 240)
	assert_eq(Scoring.live_score(Levels.HARD, 1), 560)


func test_auto_cross_does_not_change_score() -> void:
	# AT-33: same level, time and hints with Auto Cross on, off and switched.
	var scores: Array[int] = []
	for variant: int in 3:
		var holes: Array[int] = [F.rc(9, 9)]
		var session: GameSession = F.session_with_holes(holes, Levels.HARD)
		session.set_auto_cross(variant == 0)
		var a: Hint = Hint.new()
		var b: Hint = Hint.new()
		assert_true(session.buy_hint(a))
		session.close_hint()
		assert_true(session.buy_hint(b))
		session.close_hint()
		if variant == 2:
			session.set_auto_cross(true)
		session.add_time(1350.0)
		if variant == 2:
			session.set_auto_cross(false)
		F.place(session, F.rc(9, 9), F.solution_b()[F.rc(9, 9)])
		assert_true(session.is_completed)
		scores.append(session.final_score())
	assert_eq(scores, [595, 595, 595])
