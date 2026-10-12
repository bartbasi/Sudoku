extends "res://tests/unit_test.gd"
## GameSession: conflicts (GDD 6), timer (8), score and hints (9, 10),
## completion (12).

const F := preload("res://tests/core/core_fixtures.gd")


func _hint(technique: StringName) -> Hint:
	var h: Hint = Hint.new()
	h.technique = technique
	h.text = "test"
	return h


## Fills every empty cell with its solution digit except the last one.
func _fill_all_but_last(s: GameSession) -> int:
	var last: int = -1
	for cell: int in 81:
		if s.board.digit(cell) == 0:
			last = cell
	for cell: int in 81:
		if s.board.digit(cell) == 0 and cell != last:
			F.place(s, cell, F.solution_b()[cell])
	return last


func test_conflicts_shown_and_cleared() -> void:
	# AT-34 (core): given 9 at r5c1. E in its row outside its box, F in its box outside its row.
	var s: GameSession = F.session_b(false)
	var given: int = F.rc(5, 1)
	var e: int = F.rc(5, 6)
	var f: int = F.rc(4, 2)
	F.place(s, e, 9)
	assert_eq(s.board.conflict_cells(), PackedInt32Array([given, e]))
	F.place(s, f, 9)
	assert_eq(s.board.conflict_cells(), PackedInt32Array([f, given, e]))
	F.erase_at(s, e)
	assert_eq(s.board.conflict_cells(), PackedInt32Array([f, given]))
	assert_eq(s.score(), 100)
	s.undo()
	assert_eq(s.board.conflict_cells(), PackedInt32Array([f, given, e]), "undo brings the clash back")


func test_no_check_against_solution() -> void:
	# AT-35: a wrong digit that clashes with nothing shows nothing.
	var s: GameSession = F.session_b(false)
	var e: int = F.rc(2, 2)
	assert_ne(F.solution_b()[e], 7)
	F.place(s, e, 7)
	assert_eq(s.board.conflict_cells().size(), 0)
	assert_false(s.board.is_conflict(e))
	assert_eq(s.score(), 100)


func test_full_board_with_clash_then_fix() -> void:
	# AT-36 (core) and GDD 6.3.
	var holes: Array[int] = [F.rc(1, 1), F.rc(3, 4), F.rc(9, 8), F.rc(9, 9)]
	var s: GameSession = F.session_with_holes(holes)
	var last: int = _fill_all_but_last(s)
	assert_eq(last, F.rc(9, 9))
	var right: int = F.solution_b()[last]
	var wrong: int = (right % 9) + 1
	var rec: F.SignalLog = F.SignalLog.new()
	rec.watch(s)
	s.add_time(10.0)
	var r: ActionResult = F.place(s, last, wrong)
	assert_true(r.applied)
	assert_true(r.full_board_conflict)
	assert_false(r.completed)
	assert_false(s.is_completed)
	assert_eq(rec.events, ["selection:80", "board", "full_conflict"])
	s.add_time(5.0)
	assert_eq(s.elapsed_seconds(), 15, "the timer keeps running")
	rec.events.clear()
	r = s.press_digit(right)
	assert_true(r.completed)
	assert_false(r.full_board_conflict)
	assert_true(s.is_completed)
	assert_eq(rec.events, ["board", "undo:false", "completed:15:%d" % (100 + Scoring.time_bonus(0, 15))])


func test_completion_locks_the_board() -> void:
	# GDD 12: the timer stops, the board locks, Undo and Hint are disabled.
	var s: GameSession = F.session_with_holes([F.rc(2, 2), F.rc(7, 7)] as Array[int])
	F.place(s, F.rc(2, 2), F.solution_b()[F.rc(2, 2)])
	assert_true(s.buy_hint(_hint(&"hidden_single")))
	s.add_time(100.4)
	var seen: Dictionary = {"completed": false, "completed_when_board_changed": false}
	var on_board: Callable = func(_c: PackedInt32Array) -> void: seen["completed_when_board_changed"] = s.is_completed
	s.board_changed.connect(on_board)
	s.completed.connect(func(_t: int, _f: int) -> void: seen["completed"] = true)
	var r: ActionResult = F.place(s, F.rc(7, 7), F.solution_b()[F.rc(7, 7)])
	s.board_changed.disconnect(on_board)
	assert_true(r.completed)
	assert_true(r.hint_closed)
	assert_true(seen["completed"])
	assert_true(seen["completed_when_board_changed"], "is_completed is set before board_changed, so App never saves it")
	assert_eq(s.hint, null)
	assert_false(s.can_undo())
	assert_false(s.can_buy_hint())
	assert_false(s.undo().applied)
	s.add_time(50.0)
	assert_eq(s.elapsed_seconds(), 100, "the timer stops for good")
	s.select(F.rc(1, 1))
	s.toggle_mode()
	assert_eq(s.selected, F.rc(7, 7), "no input after completion")
	assert_eq(s.mode, GameSession.Mode.PLACE)
	assert_false(s.erase().applied)
	assert_eq(s.time_bonus(), Scoring.time_bonus(0, 100))
	assert_eq(s.final_score(), 80 + Scoring.time_bonus(0, 100))


func test_erase_and_undo_never_complete() -> void:
	# GDD 7.2: only a placement or a replacement can complete.
	var s: GameSession = F.session_with_holes([F.rc(2, 2)] as Array[int])
	var e: int = F.rc(2, 2)
	var wrong: int = (F.solution_b()[e] % 9) + 1
	F.place(s, e, wrong)
	assert_false(s.is_completed)
	s.undo()
	assert_false(s.is_completed)
	F.place(s, e, F.solution_b()[e])
	assert_true(s.is_completed)


func test_score_before_completion_is_zero_bonus() -> void:
	var s: GameSession = F.session_b(false)
	assert_eq(s.time_bonus(), 0)
	assert_eq(s.final_score(), 0)


func test_timer() -> void:
	# GDD 8: whole seconds; the caller adds time; bad values are ignored.
	var s: GameSession = F.session_b(false)
	s.add_time(0.6)
	assert_eq(s.elapsed_seconds(), 0)
	s.add_time(0.6)
	assert_eq(s.elapsed_seconds(), 1)
	s.add_time(-5.0)
	s.add_time(NAN)
	s.add_time(INF)
	assert_eq(s.elapsed_seconds(), 1)
	s.add_time(251.0)
	assert_eq(s.elapsed_seconds(), 252)


func test_hint_cost_and_affordability_per_level() -> void:
	# AT-46
	var costs: Array[int] = [20, 40, 80, 140, 200]
	for level: int in Levels.COUNT:
		var s: GameSession = F.session_with_holes([F.rc(1, 1)] as Array[int], level)
		assert_eq(s.hint_cost(), costs[level])
		assert_eq(s.score(), Scoring.points(level))
		for n: int in 5:
			assert_true(s.score() >= s.hint_cost())
			assert_true(s.can_buy_hint())
			assert_true(s.buy_hint(_hint(&"hidden_single")))
			s.close_hint()
		assert_eq(s.score(), 0)
		assert_true(s.score() < s.hint_cost())
		assert_false(s.can_buy_hint())


func test_hint_at_zero_score() -> void:
	# AT-45 (core part): 100, 80, 60, 40, 20, 0, then nothing; completing gives the time bonus alone.
	var s: GameSession = F.session_with_holes([F.rc(4, 4) + 1] as Array[int])
	var scores: Array[int] = [s.score()]
	var charged: Array[int] = []
	s.score_changed.connect(func(value: int) -> void: charged.append(value))
	for n: int in 5:
		assert_true(s.buy_hint(_hint(&"hidden_single")))
		s.close_hint()
		scores.append(s.score())
	assert_eq(scores, [100, 80, 60, 40, 20, 0])
	assert_eq(charged, [80, 60, 40, 20, 0])
	var hint_signals: Array[int] = []
	s.hint_changed.connect(func(_h: Hint) -> void: hint_signals.append(1))
	assert_false(s.buy_hint(_hint(&"hidden_single")))
	assert_eq(s.score(), 0)
	assert_eq(s.hints_bought, 5)
	assert_eq(hint_signals.size(), 0, "no charge, no hint")
	assert_eq(charged.size(), 5)
	s.add_time(420.0)
	var cell: int = F.rc(4, 4) + 1
	F.place(s, cell, F.solution_b()[cell])
	assert_true(s.is_completed)
	assert_eq(s.final_score(), 12, "the time bonus alone (GDD 9.3 Beginner row)")


func test_hint_rules() -> void:
	# GDD 10.2 and 10.4, AT-44 (core part): stays through select, cross and
	# restore; closes on place, replace, erase, undo and close; disabled while shown.
	var s: GameSession = F.session_b(false)
	var e: int = F.rc(2, 2)
	assert_false(s.buy_hint(null))
	assert_eq(s.score(), 100)
	var rec: F.SignalLog = F.SignalLog.new()
	rec.watch(s)
	assert_true(s.buy_hint(_hint(&"hidden_single")))
	assert_eq(rec.events, ["hint:on", "score:80"])
	assert_false(s.can_buy_hint(), "disabled while a hint is on screen")
	assert_false(s.buy_hint(_hint(&"hidden_single")))
	assert_eq(s.score(), 80)
	assert_false(s.can_undo(), "buying a hint is not an undo step")
	s.select(e)
	var r: ActionResult = F.cross(s, e, 3)
	assert_false(r.hint_closed)
	F.cross(s, e, 3)
	assert_ne(s.hint, null, "crossing and restoring keep the hint")
	r = F.place(s, e, 4)
	assert_true(r.hint_closed)
	assert_eq(s.hint, null)
	s.buy_hint(_hint(&"hidden_single"))
	r = s.press_digit(5)
	assert_true(r.hint_closed, "replace closes it")
	s.buy_hint(_hint(&"hidden_single"))
	r = s.erase()
	assert_true(r.hint_closed, "erase closes it")
	s.buy_hint(_hint(&"hidden_single"))
	r = s.undo()
	assert_true(r.hint_closed, "undo closes it")
	assert_eq(s.score(), 20, "closing never refunds, asking again costs again")
	s.buy_hint(_hint(&"hidden_single"))
	rec.events.clear()
	s.close_hint()
	assert_eq(s.hint, null)
	assert_eq(rec.events, ["hint:null"])
	s.close_hint()
	assert_eq(rec.events, ["hint:null"], "closing twice emits once")
	assert_eq(s.score(), 0)


func test_a_tap_that_does_nothing_keeps_the_hint() -> void:
	var s: GameSession = F.session_b(false)
	s.buy_hint(_hint(&"hidden_single"))
	s.select(F.rc(5, 1))
	s.press_digit(4)
	s.erase()
	assert_ne(s.hint, null)
