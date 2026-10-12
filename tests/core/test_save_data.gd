extends "res://tests/unit_test.gd"
## to_dict and from_dict for Hint, UndoStep and GameSession (GDD 14,
## ARCHITECTURE.md section 12). Every round trip goes through JSON text, as
## the save files do. AT-60 (core part): damaged data never loads.

const F := preload("res://tests/core/core_fixtures.gd")
const MAX_BYTES_PUZZLE := 16777216


func _json(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))


func _sample_hint() -> Hint:
	var h: Hint = Hint.new()
	h.technique = &"hidden_single"
	h.technique_name = "Hidden single"
	h.text = "In this box, 5 fits in only one cell. It goes here."
	h.lesson_title = "Lesson: Hidden single"
	h.targets = PackedInt32Array([20])
	h.reasons = PackedInt32Array([6, 13, 27, 64])
	h.placement_cell = 20
	h.placement_digit = 5
	h.eliminations = PackedInt32Array()
	return h


## A mid puzzle session with every kind of state (AT-57 core part).
func _busy_session() -> GameSession:
	var s: GameSession = F.session_b(false)
	F.cross(s, F.rc(5, 5), 1)
	F.cross(s, F.rc(5, 5), 6)
	F.cross(s, F.rc(5, 5), 6)
	s.set_auto_cross(true)
	F.place(s, F.rc(5, 2), 7)
	F.place(s, F.rc(5, 2), 8)
	F.place(s, F.rc(2, 5), 8)
	F.erase_at(s, F.rc(5, 2))
	F.cross(s, F.rc(5, 5), 2)
	s.buy_hint(_sample_hint())
	s.close_hint()
	s.buy_hint(_sample_hint())
	s.select(F.rc(7, 7))
	s.set_mode(GameSession.Mode.CROSS_OUT)
	s.add_time(181.75)
	return s


func _assert_same_session(a: GameSession, b: GameSession) -> void:
	assert_eq(b.puzzle_id, a.puzzle_id)
	assert_eq(b.level, a.level)
	assert_eq(b.solution, a.solution)
	assert_eq(b.board.givens, a.board.givens)
	assert_eq(b.board.digits, a.board.digits)
	assert_eq(b.board.marks, a.board.marks)
	assert_eq(b.mode, a.mode)
	assert_eq(b.selected, a.selected)
	assert_eq(b.auto_cross, a.auto_cross)
	assert_eq(b.elapsed, a.elapsed)
	assert_eq(b.hints_bought, a.hints_bought)
	assert_eq(b.score(), a.score())
	assert_eq(b.can_undo(), a.can_undo())
	assert_eq(b.hint == null, a.hint == null)
	if a.hint != null and b.hint != null:
		assert_eq(b.hint.to_dict(), a.hint.to_dict())


# Hint -------------------------------------------------------------------------

func test_hint_round_trip() -> void:
	var h: Hint = _sample_hint()
	var loaded: Hint = Hint.from_dict(_json(h.to_dict()))
	assert_ne(loaded, null)
	assert_eq(loaded.technique, &"hidden_single")
	assert_eq(loaded.to_dict(), h.to_dict())
	var cross: Hint = Hint.new()
	cross.technique = &"pointing"
	cross.eliminations = PackedInt32Array([0, 728])
	cross.targets = PackedInt32Array([0, 80])
	loaded = Hint.from_dict(_json(cross.to_dict()))
	assert_ne(loaded, null)
	assert_eq(loaded.placement_cell, -1)
	assert_eq(loaded.eliminations, PackedInt32Array([0, 728]))


func test_hint_rejects_bad_data() -> void:
	var good: Dictionary = _json(_sample_hint().to_dict())
	assert_eq(Hint.from_dict(null), null)
	assert_eq(Hint.from_dict("hint"), null)
	assert_eq(Hint.from_dict({}), null)
	var cases: Array[Array] = [
		["technique", "magic"], ["technique", 3], ["text", 5], ["text", "x".repeat(1001)],
		["lesson_title", null], ["targets", [81]], ["targets", [-1]], ["targets", "20"],
		["reasons", [1.5]], ["eliminations", [729]], ["placement_cell", 81],
		["placement_cell", -2], ["placement_digit", 10], ["placement_digit", 0],
		["placement_cell", "20"], ["targets", [true]],
	]
	for case: Array in cases:
		var bad: Dictionary = good.duplicate(true)
		bad[case[0]] = case[1]
		assert_eq(Hint.from_dict(bad), null, "%s = %s" % [case[0], case[1]])
	for key: String in good.keys():
		var missing: Dictionary = good.duplicate(true)
		missing.erase(key)
		assert_eq(Hint.from_dict(missing), null, "missing %s" % key)


# UndoStep ---------------------------------------------------------------------

func test_undo_step_round_trip() -> void:
	var step: UndoStep = UndoStep.new()
	step.kind = UndoStep.Kind.REPLACE
	step.cell = 37
	step.old_digit = 7
	step.new_digit = 8
	step.mark_changes = PackedInt32Array([40 * 9 + 6, 3, 0, 40 * 9 + 7, 0, 3])
	var loaded: UndoStep = UndoStep.from_dict(_json(step.to_dict()))
	assert_ne(loaded, null)
	assert_eq(loaded.to_dict(), step.to_dict())


func test_undo_step_rejects_bad_data() -> void:
	var cases: Array[Dictionary] = [
		{"k": 5, "c": 0, "o": 0, "n": 1, "m": []},
		{"k": 0, "c": 81, "o": 0, "n": 1, "m": []},
		{"k": 0, "c": 0, "o": 0, "n": 12, "m": []},
		{"k": 0, "c": 0, "o": 3, "n": 1, "m": []},
		{"k": 0, "c": 0, "o": 0, "n": 0, "m": []},
		{"k": 1, "c": 0, "o": 4, "n": 4, "m": []},
		{"k": 2, "c": 0, "o": 4, "n": 2, "m": []},
		{"k": 0, "c": 0, "o": 0, "n": 1, "m": [9, 0]},
		{"k": 0, "c": 0, "o": 0, "n": 1, "m": [9, 0, 1]},
		{"k": 0, "c": 0, "o": 0, "n": 1, "m": [729, 0, 3]},
		{"k": 0, "c": 0, "o": 0, "n": 1, "m": [9, 0, 4]},
		{"k": 3, "c": 0, "o": 0, "n": 0, "m": []},
		{"k": 3, "c": 0, "o": 0, "n": 0, "m": [9, 0, 1]},
		{"k": 3, "c": 0, "o": 0, "n": 0, "m": [0, 1, 2]},
		{"k": 4, "c": 0, "o": 0, "n": 0, "m": [0, 0, 2]},
		{"k": 3, "c": 0, "o": 1, "n": 0, "m": [0, 0, 1]},
		{"k": "0", "c": 0, "o": 0, "n": 1, "m": []},
		{"k": 0, "c": 0.5, "o": 0, "n": 1, "m": []},
		{"k": 0, "c": 0, "o": 0, "n": 1, "m": "none"},
		{"k": 0, "c": 0, "o": 0, "n": 1},
	]
	for case: Dictionary in cases:
		assert_eq(UndoStep.from_dict(case), null, str(case))
	assert_ne(UndoStep.from_dict({"k": 3, "c": 0, "o": 0, "n": 0, "m": [4, 2, 1]}), null)
	assert_ne(UndoStep.from_dict({"k": 4, "c": 0, "o": 0, "n": 0, "m": [4, 3, 2]}), null)
	assert_eq(UndoStep.from_dict(null), null)


# GameSession ------------------------------------------------------------------

func test_session_round_trip_and_undo_after_resume() -> void:
	# AT-57 (core part) and GDD 7.3: everything comes back, undo works to the start.
	var s: GameSession = _busy_session()
	var loaded: GameSession = GameSession.from_dict(_json(s.to_dict()))
	assert_ne(loaded, null)
	_assert_same_session(s, loaded)
	assert_false(loaded.is_completed)
	assert_eq(loaded.hint.technique, &"hidden_single")
	var steps: int = 0
	while s.can_undo():
		s.undo()
		var r: ActionResult = loaded.undo()
		assert_true(r.applied)
		assert_eq(loaded.board.digits, s.board.digits)
		assert_eq(loaded.board.marks, s.board.marks)
		assert_eq(loaded.selected, s.selected)
		steps += 1
	assert_false(loaded.can_undo())
	assert_eq(steps, 8)
	assert_eq(loaded.board.digits, loaded.board.givens)


func test_example_7_3() -> void:
	# GDD 7.3: place 5 in E, cross 2 in F, save, reload; undo restores F's 2, then empties E.
	var s: GameSession = F.session_b(false)
	var e: int = F.rc(2, 2)
	var f: int = F.rc(3, 7)
	F.place(s, e, 5)
	F.cross(s, f, 2)
	var loaded: GameSession = GameSession.from_dict(_json(s.to_dict()))
	loaded.undo()
	assert_eq(loaded.board.mark(f, 2), Board.Mark.OPEN)
	assert_eq(loaded.board.digit(e), 5)
	loaded.undo()
	assert_eq(loaded.board.digit(e), 0)
	assert_false(loaded.can_undo())


func test_fresh_session_round_trip() -> void:
	var s: GameSession = F.session_b(true)
	var loaded: GameSession = GameSession.from_dict(_json(s.to_dict()))
	assert_ne(loaded, null)
	_assert_same_session(s, loaded)
	assert_eq(loaded.hint, null)
	assert_false(loaded.can_undo())


func test_session_rejects_corrupt_data() -> void:
	# AT-60 (core part).
	var good: Dictionary = _json(_busy_session().to_dict())
	assert_ne(GameSession.from_dict(good), null)
	assert_eq(GameSession.from_dict(null), null)
	assert_eq(GameSession.from_dict("{not json"), null)
	assert_eq(GameSession.from_dict([]), null)
	assert_eq(GameSession.from_dict({}), null)
	for key: String in good.keys():
		if key == "hint":
			continue
		var missing: Dictionary = good.duplicate(true)
		missing.erase(key)
		assert_eq(GameSession.from_dict(missing), null, "missing %s" % key)
	var cases: Array[Array] = [
		["puzzle_id", ""], ["puzzle_id", 7], ["puzzle_id", "1.0.7; rm"], ["puzzle_id", "1".repeat(33)],
		["level", -1], ["level", 5], ["level", 1.5], ["level", "0"],
		["solution", "1".repeat(81)], ["solution", 12], ["solution", String(good["solution"]).substr(0, 80)],
		["mode", 2], ["mode", true], ["selected", 99], ["selected", -2], ["selected", null],
		["auto_cross", 1], ["auto_cross", "true"], ["elapsed", -1.0], ["elapsed", "180"], ["elapsed", 2.0e9],
		["hints_bought", 6], ["hints_bought", -1], ["hints_bought", 2.5],
		["hint", "hint"], ["hint", {"technique": "magic"}], ["undo", "steps"], ["undo", [12]],
		["board", null], ["board", {"givens": "0"}],
	]
	for case: Array in cases:
		var bad: Dictionary = good.duplicate(true)
		bad[case[0]] = case[1]
		assert_eq(GameSession.from_dict(bad), null, "%s = %s" % [case[0], str(case[1]).substr(0, 40)])


func test_session_rejects_a_digit_12_and_cell_99() -> void:
	# AT-60: "a digit 12, a cell index 99, a negative timer".
	var good: Dictionary = _json(_busy_session().to_dict())
	var bad_step: Dictionary = good.duplicate(true)
	(bad_step["undo"] as Array)[0] = {"k": 0, "c": 99, "o": 0, "n": 5, "m": []}
	assert_eq(GameSession.from_dict(bad_step), null)
	var bad_digit: Dictionary = good.duplicate(true)
	(bad_digit["undo"] as Array)[3] = {"k": 0, "c": 37, "o": 0, "n": 12, "m": []}
	assert_eq(GameSession.from_dict(bad_digit), null)
	var negative: Dictionary = good.duplicate(true)
	negative["elapsed"] = -30
	assert_eq(GameSession.from_dict(negative), null)


func test_session_cross_checks() -> void:
	var good: Dictionary = _json(_busy_session().to_dict())
	# The solution must agree with the givens.
	var other: Dictionary = good.duplicate(true)
	var sol: String = other["solution"]
	var given: int = F.rc(5, 1)
	other["solution"] = sol.substr(0, given) + "1" + sol.substr(given + 1)
	assert_eq(GameSession.from_dict(other), null)
	# The undo history must lead back to the givens.
	var short_history: Dictionary = good.duplicate(true)
	(short_history["undo"] as Array).remove_at(3)
	assert_eq(GameSession.from_dict(short_history), null)
	var shuffled: Dictionary = good.duplicate(true)
	var steps: Array = shuffled["undo"]
	var first: Variant = steps[3]
	steps[3] = steps[4]
	steps[4] = first
	assert_eq(GameSession.from_dict(shuffled), null)
	# No step may touch a given.
	var on_given: Dictionary = good.duplicate(true)
	(on_given["undo"] as Array).append({"k": 3, "c": given, "o": 0, "n": 0, "m": [given * 9, 0, 1]})
	assert_eq(GameSession.from_dict(on_given), null)
	var auto_on_given: Dictionary = good.duplicate(true)
	(auto_on_given["undo"] as Array)[3]["m"] = [given * 9, 0, 3]
	assert_eq(GameSession.from_dict(auto_on_given), null)
	# A placed digit with no undo step behind it does not add up.
	var extra_digit: Dictionary = good.duplicate(true)
	var digits: String = extra_digit["board"]["digits"]
	extra_digit["board"]["digits"] = digits.substr(0, 0) + "1" + digits.substr(1)
	assert_eq(GameSession.from_dict(extra_digit), null)


func test_session_rejects_a_finished_board() -> void:
	# A completed puzzle never comes back as one in progress (GDD 12, AT-51).
	var s: GameSession = F.session_with_holes([F.rc(1, 1)] as Array[int])
	var data: Dictionary = _json(s.to_dict())
	assert_ne(GameSession.from_dict(data), null)
	F.place(s, F.rc(1, 1), F.solution_b()[F.rc(1, 1)])
	assert_true(s.is_completed)
	assert_eq(GameSession.from_dict(_json(s.to_dict())), null)


func test_long_undo_history_stays_small() -> void:
	# ARCHITECTURE.md section 12: 20,000 steps fit well under MAX_BYTES_PUZZLE and load.
	var s: GameSession = F.session_b(true)
	var e: int = F.rc(5, 2)
	for i: int in 10000:
		F.place(s, e, 7)
		F.erase_at(s, e)
	var text: String = JSON.stringify(s.to_dict())
	assert_true(text.length() < MAX_BYTES_PUZZLE, "%d bytes" % text.length())
	var loaded: GameSession = GameSession.from_dict(JSON.parse_string(text))
	assert_ne(loaded, null)
	var count: int = 0
	while loaded.can_undo() and count < 3:
		loaded.undo()
		count += 1
	assert_eq(loaded.board.digit(e), 7)
	assert_eq(loaded.board.mark(F.rc(5, 5), 7), Board.Mark.CROSSED_AUTO)
