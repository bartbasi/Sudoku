extends "res://tests/unit_test.gd"
## Board: digits, marks, ruled out, conflicts (GDD 2, 4, 6).

const F := preload("res://tests/core/core_fixtures.gd")


func test_create_starts_open_and_copies_givens() -> void:
	var givens: PackedInt32Array = F.position_b_givens()
	var board: Board = Board.create(givens)
	assert_eq(board.givens, givens)
	assert_eq(board.digits, givens)
	assert_eq(board.marks.size(), 729)
	for i: int in 729:
		assert_eq(board.marks[i], Board.Mark.OPEN)
	givens[0] = 5
	assert_eq(board.givens[0], 0, "create copies its input")
	assert_true(board.is_given(F.rc(5, 1)))
	assert_false(board.is_given(F.rc(5, 5)))
	assert_eq(board.digit(F.rc(5, 1)), 9)
	assert_eq(board.digit(-1), 0)
	assert_eq(board.mark(0, 0), Board.Mark.OPEN)
	assert_false(board.is_given(81))


func test_create_rejects_bad_givens() -> void:
	assert_eq(Board.create(PackedInt32Array([1, 2])), null)
	var bad: PackedInt32Array = F.empty_grid()
	bad[3] = 11
	assert_eq(Board.create(bad), null)


func test_bart_example_ruled_out() -> void:
	# AT-14 (core): ruled out in X is exactly 2, 3, 4, 6 and 9.
	var board: Board = Board.create(F.position_b_givens())
	var x: int = F.rc(5, 5)
	var ruled: Array[int] = []
	for d: int in range(1, 10):
		if board.is_ruled_out(x, d):
			ruled.append(d)
	assert_eq(ruled, [2, 3, 4, 6, 9])


func test_cell_never_rules_out_itself() -> void:
	var board: Board = Board.create(F.position_b_givens())
	assert_false(board.is_ruled_out(F.rc(5, 1), 9), "its own 9 does not count")
	board.digits[F.rc(5, 5)] = 7
	assert_false(board.is_ruled_out(F.rc(5, 5), 7))
	assert_true(board.is_ruled_out(F.rc(5, 2), 7))


func test_is_crossed() -> void:
	var board: Board = Board.create(F.empty_grid())
	board.marks[0] = Board.Mark.CROSSED_HAND
	board.marks[1] = Board.Mark.CROSSED_AUTO
	board.marks[2] = Board.Mark.RESTORED_HAND
	assert_true(board.is_crossed(0, 1))
	assert_true(board.is_crossed(0, 2))
	assert_false(board.is_crossed(0, 3))
	assert_false(board.is_crossed(0, 4))


func test_conflicts_example_6_1() -> void:
	# GDD 6.1 example, also AT-34 in core form.
	var givens: PackedInt32Array = F.empty_grid()
	givens[F.rc(1, 3)] = 5
	var board: Board = Board.create(givens)
	assert_eq(board.conflict_cells().size(), 0)
	board.digits[F.rc(1, 8)] = 5
	assert_eq(board.conflict_cells(), PackedInt32Array([F.rc(1, 3), F.rc(1, 8)]))
	board.digits[F.rc(2, 2)] = 5
	assert_eq(board.conflict_cells(), PackedInt32Array([F.rc(1, 3), F.rc(1, 8), F.rc(2, 2)]))
	assert_true(board.is_conflict(F.rc(1, 3)))
	board.digits[F.rc(1, 8)] = 0
	assert_eq(board.conflict_cells(), PackedInt32Array([F.rc(1, 3), F.rc(2, 2)]))
	assert_false(board.is_conflict(F.rc(1, 8)))
	assert_true(board.is_conflict(F.rc(2, 2)))


func test_full_and_solved() -> void:
	var solution: PackedInt32Array = F.solution_b()
	var board: Board = Board.create(solution)
	assert_true(board.is_full())
	assert_true(board.is_solved())
	var holes: PackedInt32Array = solution.duplicate()
	holes[10] = 0
	board = Board.create(holes)
	assert_false(board.is_full())
	assert_false(board.is_solved())
	board.digits[10] = (solution[10] % 9) + 1
	assert_true(board.is_full())
	assert_false(board.is_solved(), "full with a clash")


func test_duplicate_board_is_independent() -> void:
	var board: Board = Board.create(F.position_b_givens())
	board.marks[5] = Board.Mark.CROSSED_HAND
	var copy: Board = board.duplicate_board()
	copy.digits[0] = 3
	copy.marks[5] = Board.Mark.OPEN
	assert_eq(board.digits[0], 0)
	assert_eq(board.marks[5], Board.Mark.CROSSED_HAND)
	assert_eq(copy.givens, board.givens)


func test_round_trip_through_json() -> void:
	var board: Board = Board.create(F.position_b_givens())
	board.digits[F.rc(5, 5)] = 8
	board.marks[F.rc(5, 5) * 9 + 1] = Board.Mark.CROSSED_HAND
	board.marks[F.rc(5, 3) * 9 + 6] = Board.Mark.CROSSED_AUTO
	board.marks[F.rc(9, 9) * 9 + 8] = Board.Mark.RESTORED_HAND
	var text: String = JSON.stringify(board.to_dict())
	var loaded: Board = Board.from_dict(JSON.parse_string(text))
	assert_ne(loaded, null)
	assert_eq(loaded.givens, board.givens)
	assert_eq(loaded.digits, board.digits)
	assert_eq(loaded.marks, board.marks)


func test_from_dict_rejects_bad_data() -> void:
	# AT-60 (core): unreadable or impossible board data gives null.
	var good: Dictionary = Board.create(F.position_b_givens()).to_dict()
	assert_ne(Board.from_dict(good), null)
	assert_eq(Board.from_dict(null), null)
	assert_eq(Board.from_dict("board"), null)
	assert_eq(Board.from_dict([]), null)
	assert_eq(Board.from_dict({}), null)
	for key: String in ["givens", "digits", "marks"]:
		var missing: Dictionary = good.duplicate()
		missing.erase(key)
		assert_eq(Board.from_dict(missing), null, "missing %s" % key)
		var truncated: Dictionary = good.duplicate()
		truncated[key] = String(good[key]).substr(0, 40)
		assert_eq(Board.from_dict(truncated), null, "truncated %s" % key)
		var wrong_type: Dictionary = good.duplicate()
		wrong_type[key] = 12
		assert_eq(Board.from_dict(wrong_type), null, "wrong type %s" % key)
		var letters: Dictionary = good.duplicate()
		letters[key] = "x" + String(good[key]).substr(1)
		assert_eq(Board.from_dict(letters), null, "letter in %s" % key)
	var bad_mark: Dictionary = good.duplicate()
	bad_mark["marks"] = "4" + String(good["marks"]).substr(1)
	assert_eq(Board.from_dict(bad_mark), null, "mark 4 is out of range")
	var given_changed: Dictionary = good.duplicate()
	var digits: String = good["digits"]
	var cell: int = F.rc(5, 1)
	given_changed["digits"] = digits.substr(0, cell) + "1" + digits.substr(cell + 1)
	assert_eq(Board.from_dict(given_changed), null, "a given must stay in digits")
	var given_marked: Dictionary = good.duplicate()
	var marks: String = good["marks"]
	given_marked["marks"] = marks.substr(0, cell * 9) + "1" + marks.substr(cell * 9 + 1)
	assert_eq(Board.from_dict(given_marked), null, "a given has no marks")
