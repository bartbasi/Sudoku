extends "res://tests/unit_test.gd"
## Auto Cross (GDD 5): rules 1 to 3, the worked examples AC-1 to AC-8 and
## U-1 to U-5, and the acceptance tests that run them.

const F := preload("res://tests/core/core_fixtures.gd")
const OPEN := Board.Mark.OPEN
const HAND := Board.Mark.CROSSED_HAND
const RESTORED := Board.Mark.RESTORED_HAND
const AUTO := Board.Mark.CROSSED_AUTO

var X: int = F.rc(5, 5)
var Y: int = F.rc(5, 3)
var Z: int = F.rc(1, 2)


func _marks(s: GameSession, cell: int) -> Array[int]:
	var out: Array[int] = []
	for d: int in range(1, 10):
		out.append(s.board.mark(cell, d))
	return out


## Every OPEN or CROSSED_AUTO candidate of every non-given cell matches
## "ruled out" (rules 1 and 2).
func _rules_hold(s: GameSession) -> bool:
	for cell: int in 81:
		if s.board.is_given(cell):
			continue
		for d: int in range(1, 10):
			var m: int = s.board.mark(cell, d)
			if m == OPEN and s.board.is_ruled_out(cell, d):
				return false
			if m == AUTO and not s.board.is_ruled_out(cell, d):
				return false
	return true


# The worked examples, each continuing from the one before -------------------

func _ac1() -> GameSession:
	var s: GameSession = F.session_b(false)
	s.select(X)
	s.set_mode(GameSession.Mode.CROSS_OUT)
	s.press_digit(9)
	s.press_digit(1)
	s.press_digit(6)
	s.press_digit(6)
	s.set_auto_cross(true)
	return s


func _ac2() -> GameSession:
	var s: GameSession = _ac1()
	F.place(s, F.rc(5, 2), 7)
	return s


func _ac3() -> GameSession:
	var s: GameSession = _ac2()
	F.place(s, F.rc(5, 2), 8)
	return s


func _ac4() -> GameSession:
	var s: GameSession = _ac3()
	F.place(s, F.rc(2, 5), 8)
	F.erase_at(s, F.rc(5, 2))
	return s


func _ac5() -> GameSession:
	var s: GameSession = _ac4()
	F.cross(s, X, 2)
	F.place(s, F.rc(5, 9), 2)
	return s


func _ac6() -> GameSession:
	var s: GameSession = _ac5()
	F.cross(s, X, 5)
	F.place(s, F.rc(9, 5), 5)
	assert_eq(s.board.mark(X, 5), HAND, "AC-6: hand cross under a peer's 5")
	F.erase_at(s, F.rc(9, 5))
	return s


func test_ac1_turning_on_next_to_hand_marks() -> void:
	# AT-22 (core), AC-1
	var s: GameSession = _ac1()
	assert_eq(F.digits_with(s.board, X, HAND), [1, 9])
	assert_eq(F.digits_with(s.board, X, AUTO), [2, 3, 4])
	assert_eq(F.digits_with(s.board, X, RESTORED), [6])
	assert_eq(F.digits_with(s.board, X, OPEN), [5, 7, 8])
	assert_eq(F.digits_with(s.board, F.rc(5, 4), AUTO), [2, 3, 4, 9])
	assert_true(_rules_hold(s))
	assert_eq(s.score(), 100, "Auto Cross does not change the score")


func test_turning_on_is_not_an_undo_step() -> void:
	# GDD 5.4: the crosses made by turning it on belong to no undo step.
	var s: GameSession = F.session_b(false)
	s.set_auto_cross(true)
	assert_false(s.can_undo())
	assert_eq(F.digits_with(s.board, X, AUTO), [2, 3, 4, 6, 9])


func test_turning_on_emits_board_changed_with_changed_cells() -> void:
	var s: GameSession = F.session_b(false)
	var cells: Array[PackedInt32Array] = []
	s.board_changed.connect(func(c: PackedInt32Array) -> void: cells.append(c))
	s.set_auto_cross(true)
	assert_eq(cells.size(), 1)
	assert_true(cells[0].has(X))
	assert_false(cells[0].has(F.rc(5, 1)), "givens never change")
	s.set_auto_cross(true)
	assert_eq(cells.size(), 1, "nothing changed the second time, so no signal")
	s.set_auto_cross(false)
	assert_eq(cells.size(), 1, "turning it off changes nothing")


func test_ac2_placing() -> void:
	# AT-23 (core), AC-2
	var s: GameSession = _ac1()
	var hand_before: Array[int] = F.digits_with(s.board, X, HAND)
	var r: ActionResult = F.place(s, F.rc(5, 2), 7)
	for cell: int in [X, Y, Z]:
		assert_eq(s.board.mark(cell, 7), AUTO, "cell %d" % cell)
	assert_true(r.changed_cells.has(X) and r.changed_cells.has(Y) and r.changed_cells.has(Z))
	assert_eq(F.digits_with(s.board, X, HAND), hand_before)
	assert_eq(s.board.mark(X, 6), RESTORED)
	assert_true(_rules_hold(s))
	# One undo step: undo removes the 7 and reopens every one of those.
	s.undo()
	assert_eq(s.board.digit(F.rc(5, 2)), 0)
	for cell: int in [X, Y, Z]:
		assert_eq(s.board.mark(cell, 7), OPEN)
	assert_true(_rules_hold(s))


func test_ac3_replacing_is_one_step() -> void:
	# AT-24, AC-3
	var s: GameSession = _ac3()
	for cell: int in [X, Y, Z]:
		assert_eq(s.board.mark(cell, 7), OPEN, "no 7 left")
		assert_eq(s.board.mark(cell, 8), AUTO)
	assert_true(_rules_hold(s))
	s.undo()
	assert_eq(s.board.digit(F.rc(5, 2)), 7)
	for cell: int in [X, Y, Z]:
		assert_eq(s.board.mark(cell, 7), AUTO)
		assert_eq(s.board.mark(cell, 8), OPEN)


func test_ac4_erase_while_still_ruled_out() -> void:
	# AT-25 (core), AC-4
	var s: GameSession = _ac4()
	assert_eq(s.board.mark(X, 8), AUTO, "r2c5 still rules it out")
	assert_eq(s.board.mark(Y, 8), OPEN)
	assert_eq(s.board.mark(Z, 8), OPEN)
	assert_true(_rules_hold(s))


func test_ac5_hand_restore_never_recrossed() -> void:
	# AT-26 (core), AC-5
	var s: GameSession = _ac4()
	assert_eq(s.board.mark(X, 2), AUTO)
	F.cross(s, X, 2)
	assert_eq(s.board.mark(X, 2), RESTORED)
	F.place(s, F.rc(5, 9), 2)
	assert_eq(s.board.mark(X, 2), RESTORED)


func test_ac6_hand_cross_outlives_its_digit() -> void:
	# AT-27, AC-6
	var s: GameSession = _ac6()
	assert_eq(s.board.mark(X, 5), HAND)


func test_ac7_off_and_on_again() -> void:
	# AT-28 (core), AC-7
	var s: GameSession = _ac6()
	var before: PackedByteArray = s.board.marks.duplicate()
	s.set_auto_cross(false)
	assert_eq(s.board.marks, before, "turning it off changes nothing")
	F.erase_at(s, F.rc(2, 5))
	assert_eq(s.board.mark(X, 8), AUTO, "nothing reopens while it is off")
	s.set_auto_cross(true)
	assert_eq(s.board.mark(X, 8), OPEN)
	assert_eq(s.board.mark(X, 2), RESTORED)
	assert_eq(s.board.mark(X, 5), HAND)
	assert_true(_rules_hold(s))


func test_ac8_ring_hidden_under_a_digit_auto_on() -> void:
	# AT-29, AC-8 with Auto Cross on from the start.
	var s: GameSession = F.session_b(true)
	assert_eq(F.digits_with(s.board, X, AUTO), [2, 3, 4, 6, 9])
	F.cross(s, X, 1)
	F.place(s, X, 5)
	F.place(s, F.rc(5, 2), 7)
	assert_eq(s.board.mark(X, 7), AUTO, "the hidden ring follows the board too")
	F.erase_at(s, X)
	assert_eq(F.digits_with(s.board, X, HAND), [1])
	assert_eq(F.digits_with(s.board, X, AUTO), [2, 3, 4, 6, 7, 9])
	assert_eq(F.digits_with(s.board, X, OPEN), [5, 8])


func test_ac8_ring_hidden_under_a_digit_auto_off() -> void:
	# AT-29, AC-8 with Auto Cross off throughout.
	var s: GameSession = F.session_b(false)
	F.cross(s, X, 1)
	F.place(s, X, 5)
	F.place(s, F.rc(5, 2), 7)
	F.erase_at(s, X)
	assert_eq(F.digits_with(s.board, X, HAND), [1])
	assert_eq(F.digits_with(s.board, X, OPEN), [2, 3, 4, 5, 6, 7, 8, 9])


func test_erase_with_auto_cross_on_keeps_hand_marks() -> void:
	# GDD 4.3 and Bart's Hard Stop 1 answer 2: hand marks exactly as left,
	# Auto Cross marks match the board as it is now.
	var s: GameSession = F.session_b(true)
	var e: int = F.rc(2, 2)
	F.cross(s, e, 1)
	F.cross(s, e, 4)
	F.cross(s, e, 4)
	F.place(s, e, 6)
	F.place(s, F.rc(2, 7), 3)
	F.erase_at(s, e)
	assert_eq(F.digits_with(s.board, e, HAND), [1])
	assert_eq(F.digits_with(s.board, e, RESTORED), [4])
	assert_eq(s.board.mark(e, 3), AUTO, "r2c7 now holds 3")
	assert_true(_rules_hold(s))


func test_u1_undo_with_auto_on() -> void:
	# AT-30, U-1
	var s: GameSession = F.session_b(true)
	F.place(s, F.rc(5, 2), 7)
	for cell: int in [X, Y, Z]:
		assert_eq(s.board.mark(cell, 7), AUTO)
	s.undo()
	assert_eq(s.board.digit(F.rc(5, 2)), 0)
	for cell: int in [X, Y, Z]:
		assert_eq(s.board.mark(cell, 7), OPEN)


func test_u2_undo_after_turning_off() -> void:
	# AT-30, U-2
	var s: GameSession = F.session_b(true)
	F.place(s, F.rc(5, 2), 7)
	s.set_auto_cross(false)
	s.undo()
	assert_eq(s.board.digit(F.rc(5, 2)), 0)
	for cell: int in [X, Y, Z]:
		assert_eq(s.board.mark(cell, 7), OPEN)


func test_u3_undo_after_turning_on() -> void:
	# AT-30, U-3
	var s: GameSession = F.session_b(false)
	F.place(s, F.rc(5, 2), 7)
	s.set_auto_cross(true)
	for cell: int in [X, Y, Z]:
		assert_eq(s.board.mark(cell, 7), AUTO)
	s.undo()
	assert_eq(s.board.digit(F.rc(5, 2)), 0)
	for cell: int in [X, Y, Z]:
		assert_eq(s.board.mark(cell, 7), OPEN)


func test_u4_undo_after_on_then_off() -> void:
	# AT-30, U-4
	var s: GameSession = F.session_b(false)
	F.place(s, F.rc(5, 2), 7)
	s.set_auto_cross(true)
	s.set_auto_cross(false)
	s.undo()
	assert_eq(s.board.digit(F.rc(5, 2)), 0)
	for cell: int in [X, Y, Z]:
		assert_eq(s.board.mark(cell, 7), AUTO, "turning it on made them, not the placement")
	s.set_auto_cross(true)
	for cell: int in [X, Y, Z]:
		assert_eq(s.board.mark(cell, 7), OPEN)


func test_u5_undo_of_restore() -> void:
	# AT-30, U-5
	var s: GameSession = F.session_b(true)
	assert_eq(s.board.mark(X, 2), AUTO)
	F.cross(s, X, 2)
	assert_eq(s.board.mark(X, 2), RESTORED)
	s.undo()
	assert_eq(s.board.mark(X, 2), AUTO)


func test_restore_is_remembered() -> void:
	# AT-13 (core): cross and restore a digit of the row, then turn Auto Cross on.
	var s: GameSession = F.session_b(false)
	F.cross(s, X, 9)
	F.cross(s, X, 9)
	assert_eq(s.board.mark(X, 9), RESTORED)
	s.set_auto_cross(true)
	assert_eq(s.board.mark(X, 9), RESTORED)
	assert_eq(F.digits_with(s.board, X, AUTO), [2, 3, 4, 6])


func test_trusts_wrong_digits_and_never_reads_solution() -> void:
	# AT-31: a wrong 7 in r2c2 (its answer is 9) crosses every open 7 around
	# it, also in r2c9 whose answer is 7. The solution is wiped first, so
	# nothing can read it.
	var s: GameSession = F.session_b(true)
	s.solution = PackedInt32Array()
	var e: int = F.rc(2, 2)
	var answer_cell: int = F.rc(2, 9)
	assert_eq(F.solution_b()[answer_cell], 7)
	F.place(s, F.rc(8, 9), 7)
	F.place(s, e, 7)
	assert_eq(s.board.conflict_cells().size(), 0, "clashes with nothing")
	for peer: int in Sudoku.peers(e):
		if not s.board.is_given(peer) and s.board.digit(peer) == 0:
			assert_eq(s.board.mark(peer, 7), AUTO, "peer %d" % peer)
	F.erase_at(s, e)
	assert_eq(s.board.mark(answer_cell, 7), AUTO, "r8c9 still rules it out")
	assert_eq(s.board.mark(F.rc(2, 1), 7), OPEN)
	assert_eq(s.board.mark(F.rc(1, 1), 7), OPEN)
	assert_true(_rules_hold(s))


func test_rules_hold_through_random_play() -> void:
	# Rules 1 to 3 after every action and every undo, across Auto Cross
	# switches, from a fixed seed. Hand marks only change by the player's
	# own cross or restore, or by undoing one.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261012
	var s: GameSession = F.session_b(true)
	for i: int in 400:
		var before: PackedByteArray = s.board.marks.duplicate()
		var roll: int = rng.randi_range(0, 99)
		var player_index: int = -1
		if roll < 3:
			s.set_auto_cross(not s.auto_cross)
		elif roll < 20:
			var r: ActionResult = s.undo()
			if r.applied:
				continue
		else:
			s.select(rng.randi_range(0, 80))
			s.set_mode(rng.randi_range(0, 1))
			var d: int = rng.randi_range(1, 9)
			if rng.randi_range(0, 9) == 0:
				s.erase()
			else:
				if s.mode == GameSession.Mode.CROSS_OUT:
					player_index = s.selected * 9 + d - 1
				s.press_digit(d)
			if s.is_completed:
				break
		if s.auto_cross:
			assert_true(_rules_hold(s), "step %d" % i)
		for index: int in 729:
			if index == player_index:
				continue
			var old_hand: bool = before[index] == HAND or before[index] == RESTORED
			var new_hand: bool = s.board.marks[index] == HAND or s.board.marks[index] == RESTORED
			if old_hand or new_hand:
				assert_eq(s.board.marks[index], before[index], "hand mark %d changed at step %d" % [index, i])
