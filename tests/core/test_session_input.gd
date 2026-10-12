extends "res://tests/unit_test.gd"
## GameSession input rules: GDD 3 (every action), 4 (the ring) and 7 (undo),
## with Auto Cross off.

const F := preload("res://tests/core/core_fixtures.gd")
const PLACE := GameSession.Mode.PLACE
const CROSS_OUT := GameSession.Mode.CROSS_OUT


func _all_marks_open(board: Board, cell: int) -> bool:
	for d: int in range(1, 10):
		if board.mark(cell, d) != Board.Mark.OPEN:
			return false
	return true


func test_new_puzzle_start_state() -> void:
	# AT-01 (core part) and GDD 3.3: no selection, Place mode, timer 0, score 100.
	var s: GameSession = F.session_b(false)
	assert_eq(s.selected, -1)
	assert_eq(s.mode, PLACE)
	assert_eq(s.elapsed_seconds(), 0)
	assert_eq(s.score(), 100)
	assert_false(s.can_undo())
	assert_true(s.can_buy_hint())
	assert_false(s.is_completed)
	assert_eq(s.hint, null)
	for cell: int in 81:
		assert_true(_all_marks_open(s.board, cell))
	# The three taps with no cell selected do nothing.
	assert_false(s.press_digit(5).applied)
	assert_false(s.erase().applied)
	assert_false(s.undo().applied)
	assert_eq(s.board.digits, F.position_b_givens())


func test_create_rejects_bad_input() -> void:
	var givens: PackedInt32Array = F.position_b_givens()
	assert_eq(GameSession.create("1.0.1", -1, givens, F.solution_b(), false), null)
	assert_eq(GameSession.create("1.0.1", 5, givens, F.solution_b(), false), null)
	assert_eq(GameSession.create("1.0.1", 0, givens, F.empty_grid(), false), null)
	var other: PackedInt32Array = givens.duplicate()
	other[0] = 1
	assert_eq(GameSession.create("1.0.1", 0, other, F.solution_b(), false), null, "solution must agree with givens")


func test_selection() -> void:
	# GDD 2.2: any cell can be selected; reselecting keeps it.
	var s: GameSession = F.session_b(false)
	var rec: F.SignalLog = F.SignalLog.new()
	rec.watch(s)
	s.select(F.rc(5, 1))
	assert_eq(s.selected, F.rc(5, 1), "a given can be selected")
	s.select(F.rc(5, 1))
	s.select(-1)
	s.select(81)
	assert_eq(s.selected, F.rc(5, 1))
	assert_eq(rec.events, ["selection:36"])


func test_example_3_3() -> void:
	# GDD 3.3 example on r2c3.
	var s: GameSession = F.session_b(false)
	var e: int = F.rc(2, 3)
	var r: ActionResult = F.place(s, e, 4)
	assert_true(r.applied)
	assert_true(r.click)
	assert_eq(s.board.digit(e), 4)
	assert_false(s.press_digit(4).applied, "same digit again: nothing happens")
	r = s.press_digit(7)
	assert_true(r.applied)
	assert_true(r.click)
	assert_eq(s.board.digit(e), 7)
	s.set_mode(CROSS_OUT)
	assert_eq(s.selected, e)
	assert_false(s.press_digit(1).applied, "Cross Out on a cell holding a digit")
	r = s.erase()
	assert_true(r.applied)
	assert_false(r.click, "erase plays no click")
	assert_eq(s.board.digit(e), 0)
	assert_true(_all_marks_open(s.board, e), "ring exactly as before step 1")
	r = s.press_digit(1)
	assert_true(r.applied)
	assert_eq(s.board.mark(e, 1), Board.Mark.CROSSED_HAND)


func test_givens_are_locked() -> void:
	# AT-04 (core part): nothing happens on a given in either mode.
	var s: GameSession = F.session_b(false)
	var given: int = F.rc(5, 1)
	s.select(given)
	for d: int in range(1, 10):
		assert_false(s.press_digit(d).applied)
	assert_false(s.erase().applied)
	s.set_mode(CROSS_OUT)
	for d: int in range(1, 10):
		assert_false(s.press_digit(d).applied)
	assert_eq(s.board.digit(given), 9)
	assert_true(_all_marks_open(s.board, given))
	assert_false(s.can_undo())


func test_invalid_digits_do_nothing() -> void:
	var s: GameSession = F.session_b(false)
	s.select(F.rc(5, 5))
	assert_false(s.press_digit(0).applied)
	assert_false(s.press_digit(10).applied)
	assert_false(s.press_digit(-3).applied)
	assert_false(s.can_undo())


func test_same_digit_again_makes_no_step() -> void:
	# AT-07
	var s: GameSession = F.session_b(false)
	var e: int = F.rc(2, 2)
	F.place(s, e, 5)
	var r: ActionResult = s.press_digit(5)
	assert_false(r.applied)
	assert_false(r.click)
	s.undo()
	assert_eq(s.board.digit(e), 0)
	assert_false(s.can_undo())


func test_erase_rules() -> void:
	# AT-08 (core part): erase, then erase on empty and on a given do nothing, in both modes.
	for mode: int in [PLACE, CROSS_OUT]:
		var s: GameSession = F.session_b(false)
		var e: int = F.rc(2, 2)
		F.place(s, e, 5)
		s.set_mode(mode)
		var r: ActionResult = s.erase()
		assert_true(r.applied)
		assert_false(r.click)
		assert_eq(s.board.digit(e), 0)
		assert_false(s.erase().applied)
		s.select(F.rc(5, 1))
		assert_false(s.erase().applied)


func test_cross_and_restore_with_undo() -> void:
	# AT-09 (core part).
	var s: GameSession = F.session_b(false)
	var e: int = F.rc(2, 2)
	var r: ActionResult = F.cross(s, e, 3)
	assert_true(r.applied)
	assert_true(r.click)
	assert_eq(s.board.mark(e, 3), Board.Mark.CROSSED_HAND)
	r = s.press_digit(3)
	assert_true(r.click)
	assert_eq(s.board.mark(e, 3), Board.Mark.RESTORED_HAND)
	s.undo()
	assert_eq(s.board.mark(e, 3), Board.Mark.CROSSED_HAND)
	s.undo()
	assert_eq(s.board.mark(e, 3), Board.Mark.OPEN)
	assert_false(s.can_undo())


func test_restored_can_be_crossed_again() -> void:
	# GDD 4.3: restored by hand becomes crossed by hand on the next tap.
	var s: GameSession = F.session_b(false)
	var e: int = F.rc(2, 2)
	F.cross(s, e, 3)
	s.press_digit(3)
	s.press_digit(3)
	assert_eq(s.board.mark(e, 3), Board.Mark.CROSSED_HAND)


func test_cross_out_on_a_digit_then_erase() -> void:
	# AT-10 (core part).
	var s: GameSession = F.session_b(false)
	var e: int = F.rc(2, 2)
	F.cross(s, e, 8)
	var before: PackedByteArray = s.board.marks.duplicate()
	F.place(s, e, 6)
	s.set_mode(CROSS_OUT)
	for d: int in range(1, 10):
		assert_false(s.press_digit(d).applied)
	s.erase()
	assert_eq(s.board.marks, before)


func test_mode_toggle_is_not_a_step() -> void:
	# AT-11 (core part).
	var s: GameSession = F.session_b(false)
	var rec: F.SignalLog = F.SignalLog.new()
	s.select(F.rc(2, 2))
	rec.watch(s)
	var digits: PackedInt32Array = s.board.digits.duplicate()
	s.toggle_mode()
	assert_eq(s.mode, CROSS_OUT)
	s.toggle_mode()
	assert_eq(s.mode, PLACE)
	s.set_mode(PLACE)
	s.set_mode(7)
	assert_eq(s.selected, F.rc(2, 2))
	assert_eq(s.board.digits, digits)
	assert_false(s.can_undo())
	assert_false(s.undo().applied)
	assert_eq(rec.events, ["mode:1", "mode:0"])


func test_cross_out_all_nine() -> void:
	# AT-12 (core part).
	var s: GameSession = F.session_b(false)
	var e: int = F.rc(2, 2)
	s.select(e)
	s.set_mode(CROSS_OUT)
	for d: int in range(1, 10):
		assert_true(s.press_digit(d).applied)
	assert_eq(F.digits_with(s.board, e, Board.Mark.CROSSED_HAND), [1, 2, 3, 4, 5, 6, 7, 8, 9])
	s.press_digit(4)
	assert_eq(s.board.mark(e, 4), Board.Mark.RESTORED_HAND)
	s.set_mode(PLACE)
	assert_true(s.press_digit(2).applied, "placing over a crossed candidate works")
	s.erase()
	assert_eq(F.digits_with(s.board, e, Board.Mark.CROSSED_HAND), [1, 2, 3, 5, 6, 7, 8, 9])
	assert_eq(F.digits_with(s.board, e, Board.Mark.RESTORED_HAND), [4])


func test_place_over_crossed_candidate() -> void:
	# AT-16 (core form).
	var s: GameSession = F.session_b(false)
	var e: int = F.rc(2, 2)
	F.cross(s, e, 7)
	F.place(s, e, 7)
	assert_eq(s.board.digit(e), 7)
	s.erase()
	assert_eq(s.board.mark(e, 7), Board.Mark.CROSSED_HAND)


func test_bart_example_cross_out_mode() -> void:
	# AT-14 (core): Bart's example in Cross Out mode, then place 8 and erase.
	var s: GameSession = F.session_b(false)
	var x: int = F.rc(5, 5)
	s.select(x)
	s.set_mode(CROSS_OUT)
	for d: int in [2, 3, 4, 6, 9]:
		assert_true(s.press_digit(d).applied)
	assert_eq(F.digits_with(s.board, x, Board.Mark.CROSSED_HAND), [2, 3, 4, 6, 9])
	assert_eq(F.digits_with(s.board, x, Board.Mark.OPEN), [1, 5, 7, 8])
	s.set_mode(PLACE)
	s.press_digit(8)
	assert_eq(s.board.digit(x), 8)
	s.erase()
	assert_eq(F.digits_with(s.board, x, Board.Mark.CROSSED_HAND), [2, 3, 4, 6, 9])
	assert_eq(F.digits_with(s.board, x, Board.Mark.OPEN), [1, 5, 7, 8])


func test_bart_example_with_auto_cross() -> void:
	# AT-14 (core), last part: a fresh Position B with Auto Cross turned on.
	var s: GameSession = F.session_b(false)
	s.set_auto_cross(true)
	var x: int = F.rc(5, 5)
	assert_eq(F.digits_with(s.board, x, Board.Mark.CROSSED_AUTO), [2, 3, 4, 6, 9])
	assert_eq(F.digits_with(s.board, x, Board.Mark.OPEN), [1, 5, 7, 8])


func test_erase_brings_ring_back_unchanged() -> void:
	# AT-15
	var s: GameSession = F.session_b(false)
	var e: int = F.rc(2, 2)
	var f: int = F.rc(2, 7)
	s.select(e)
	s.set_mode(CROSS_OUT)
	s.press_digit(1)
	s.press_digit(4)
	s.press_digit(9)
	s.press_digit(4)
	var before: PackedByteArray = s.board.marks.duplicate()
	F.place(s, e, 6)
	F.place(s, f, 3)
	F.erase_at(s, e)
	assert_eq(F.digits_with(s.board, e, Board.Mark.CROSSED_HAND), [1, 9])
	assert_eq(s.board.mark(e, 3), Board.Mark.OPEN)
	assert_eq(s.board.marks, before, "every mark exactly as before the 6")


func test_undo_across_mode_switches() -> void:
	# AT-18 and GDD 7.2 example.
	var s: GameSession = F.session_b(false)
	var e: int = F.rc(2, 2)
	var f: int = F.rc(3, 7)
	var g: int = F.rc(7, 3)
	F.place(s, e, 5)
	s.set_mode(CROSS_OUT)
	s.select(f)
	s.press_digit(2)
	s.set_mode(PLACE)
	s.select(g)
	s.press_digit(7)
	s.select(F.rc(9, 9))
	var r: ActionResult = s.undo()
	assert_true(r.applied)
	assert_false(r.click, "undo plays no click")
	assert_eq(s.board.digit(g), 0)
	assert_eq(s.selected, g)
	assert_eq(s.mode, PLACE)
	s.undo()
	assert_eq(s.board.mark(f, 2), Board.Mark.OPEN)
	assert_eq(s.selected, f)
	assert_eq(s.mode, PLACE)
	s.undo()
	assert_eq(s.board.digit(e), 0)
	assert_eq(s.selected, e)
	assert_eq(s.mode, PLACE)
	assert_false(s.can_undo())


func test_undo_of_each_kind() -> void:
	# AT-19
	var s: GameSession = F.session_b(false)
	var e: int = F.rc(2, 2)
	var f: int = F.rc(3, 7)
	F.place(s, e, 4)
	s.press_digit(7)
	s.erase()
	F.cross(s, f, 3)
	s.press_digit(3)
	s.undo()
	assert_eq(s.board.mark(f, 3), Board.Mark.CROSSED_HAND)
	s.undo()
	assert_eq(s.board.mark(f, 3), Board.Mark.OPEN)
	s.undo()
	assert_eq(s.board.digit(e), 7)
	s.undo()
	assert_eq(s.board.digit(e), 4)
	s.undo()
	assert_eq(s.board.digit(e), 0)
	assert_false(s.can_undo())


func test_what_is_not_an_undo_step() -> void:
	# AT-20 (core part): selecting, mode switches, a hint, a tap on a given.
	var s: GameSession = F.session_b(false)
	var e: int = F.rc(2, 2)
	F.place(s, e, 5)
	s.select(F.rc(8, 8))
	s.toggle_mode()
	s.toggle_mode()
	assert_true(s.buy_hint(Hint.new()))
	s.close_hint()
	s.add_time(5.0)
	s.select(F.rc(5, 1))
	s.press_digit(3)
	s.set_auto_cross(true)
	s.set_auto_cross(false)
	s.undo()
	assert_eq(s.board.digit(e), 0)
	assert_false(s.can_undo())
	assert_eq(s.score(), 80, "the hint is not refunded")


func test_undo_does_not_change_timer() -> void:
	var s: GameSession = F.session_b(false)
	F.place(s, F.rc(2, 2), 5)
	s.add_time(12.5)
	s.undo()
	assert_eq(s.elapsed_seconds(), 12)


func test_changed_cells_and_signals_for_place() -> void:
	var s: GameSession = F.session_b(false)
	s.select(F.rc(2, 2))
	var rec: F.SignalLog = F.SignalLog.new()
	rec.watch(s)
	var r: ActionResult = s.press_digit(5)
	assert_eq(r.changed_cells, PackedInt32Array([F.rc(2, 2)]))
	assert_eq(rec.events, ["board", "undo:true"])
	rec.events.clear()
	s.press_digit(6)
	assert_eq(rec.events, ["board"], "undo was already available")
	s.select(0)
	rec.events.clear()
	s.undo()
	assert_eq(rec.events, ["board", "selection:10"])
	rec.events.clear()
	s.undo()
	assert_eq(rec.events, ["board", "undo:false"])


func test_nothing_happens_emits_nothing() -> void:
	var s: GameSession = F.session_b(false)
	s.select(F.rc(5, 1))
	var rec: F.SignalLog = F.SignalLog.new()
	rec.watch(s)
	s.press_digit(2)
	s.erase()
	s.undo()
	assert_eq(rec.events, [])


func test_peer_and_same_digit_cells() -> void:
	# GDD 2.3 same digit highlight (AT-03 core part).
	var s: GameSession = F.session_b(false)
	assert_eq(s.peer_cells().size(), 0)
	assert_eq(s.same_digit_cells().size(), 0)
	s.select(F.rc(1, 5))
	assert_eq(s.peer_cells(), Sudoku.peers(F.rc(1, 5)))
	assert_eq(s.same_digit_cells(), PackedInt32Array([F.rc(4, 6)]), "the other 4")
	s.select(F.rc(5, 5))
	assert_eq(s.same_digit_cells().size(), 0, "empty cell: no same digit highlight")
	s.press_digit(3)
	assert_eq(s.same_digit_cells(), PackedInt32Array([F.rc(5, 8), F.rc(6, 6)]))


func test_lesson_session() -> void:
	# GDD 15.4: no Auto Cross, timer, score, hints or completion in lessons.
	var board: Board = Board.create(F.position_b_givens())
	var s: GameSession = GameSession.for_lesson(board, CROSS_OUT, F.rc(5, 5))
	assert_eq(s.board, board)
	assert_eq(s.mode, CROSS_OUT)
	assert_eq(s.selected, F.rc(5, 5))
	assert_eq(s.level, -1)
	assert_eq(s.puzzle_id, "")
	assert_false(s.auto_cross)
	s.set_auto_cross(true)
	assert_false(s.auto_cross, "Auto Cross is always off in lessons")
	assert_true(_all_marks_open(board, F.rc(5, 5)))
	s.add_time(30.0)
	assert_eq(s.elapsed_seconds(), 0)
	assert_eq(s.score(), 0)
	assert_false(s.can_buy_hint())
	assert_false(s.buy_hint(Hint.new()))
	assert_true(s.press_digit(2).applied)
	assert_true(s.can_undo())
	assert_eq(GameSession.for_lesson(null, 0, 0), null)
	var odd: GameSession = GameSession.for_lesson(board, 9, 200)
	assert_eq(odd.mode, PLACE)
	assert_eq(odd.selected, -1)
