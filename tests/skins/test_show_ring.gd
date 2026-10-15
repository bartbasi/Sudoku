extends "res://tests/unit_test.gd"
## BoardDrawState.show_ring (Bart, 2026-10-14; DESIGN_SYSTEM.md 2.10 and the
## Show candidates bullet of section 6). With the ring hidden an empty cell
## draws no candidate, no hand X and no Auto Cross slash, except each still
## open candidate in hint_crosses, which draws as its hint cross chip. The
## selection frame is the solid Place frame, PLACE and ERASE have no ring fade
## and CROSS and RESTORE draw nothing. With the ring shown nothing changes.

const CELL: int = 40
const OTHER_CELL: int = 41


func _painter(state: BoardDrawState) -> BoardPainter:
	var painter: BoardPainter = BoardPainter.new()
	painter._read_state(state)
	return painter


## Cell 40 has every kind of mark: 1 open, 2 crossed by hand, 3 restored by
## hand, 4 crossed by Auto Cross, the rest open. The hint says to cross 5 (open),
## 3 (restored), 2 (crossed by hand) and 4 (crossed by Auto Cross) in cell 40.
func _state(show_ring: bool) -> BoardDrawState:
	var state: BoardDrawState = BoardDrawState.new()
	state.digits.resize(81)
	state.givens.resize(81)
	state.marks.resize(729)
	state.digits[0] = 5
	state.givens[0] = 5
	state.marks[_index(CELL, 2)] = BoardPainter.MARK_CROSSED_HAND
	state.marks[_index(CELL, 3)] = BoardPainter.MARK_RESTORED_HAND
	state.marks[_index(CELL, 4)] = BoardPainter.MARK_CROSSED_AUTO
	state.marks[_index(OTHER_CELL, 7)] = BoardPainter.MARK_CROSSED_HAND
	state.hint_crosses = PackedInt32Array([_index(CELL, 5), _index(CELL, 3), _index(CELL, 2), _index(CELL, 4)])
	state.hint_targets = PackedInt32Array([CELL])
	state.selected = CELL
	state.show_ring = show_ring
	return state


func _index(cell: int, digit: int) -> int:
	return cell * 9 + digit - 1


func _effect(kind: int, progress: float) -> CellEffect:
	var effect: CellEffect = CellEffect.new()
	effect.cell = CELL
	effect.digit = 6
	effect.kind = kind
	effect.progress = progress
	return effect


func test_show_ring_defaults_to_true() -> void:
	assert_true(BoardDrawState.new().show_ring)


func test_ring_shown_draws_every_look_as_before() -> void:
	var painter: BoardPainter = _painter(_state(true))
	assert_eq(painter._candidate_look(_index(CELL, 1)), BoardPainter.Look.OPEN, "open")
	assert_eq(painter._candidate_look(_index(CELL, 2)), BoardPainter.Look.CROSSED_HAND, "hand X, hint cross ignored")
	assert_eq(painter._candidate_look(_index(CELL, 3)), BoardPainter.Look.HINT_CHIP, "restored hint cross")
	assert_eq(painter._candidate_look(_index(CELL, 4)), BoardPainter.Look.CROSSED_AUTO, "Auto Cross slash, hint cross ignored")
	assert_eq(painter._candidate_look(_index(CELL, 5)), BoardPainter.Look.HINT_CHIP, "open hint cross")
	assert_eq(painter._candidate_look(_index(OTHER_CELL, 7)), BoardPainter.Look.CROSSED_HAND, "hand X elsewhere")
	assert_eq(painter._candidate_look(_index(OTHER_CELL, 1)), BoardPainter.Look.OPEN, "open elsewhere")


func test_ring_hidden_draws_only_open_hint_crosses() -> void:
	var painter: BoardPainter = _painter(_state(false))
	assert_eq(painter._candidate_look(_index(CELL, 5)), BoardPainter.Look.HINT_CHIP, "open hint cross keeps its chip")
	assert_eq(painter._candidate_look(_index(CELL, 3)), BoardPainter.Look.HINT_CHIP, "restored hint cross keeps its chip")
	assert_eq(painter._candidate_look(_index(CELL, 2)), BoardPainter.Look.NONE, "hint cross crossed by hand draws nothing")
	assert_eq(painter._candidate_look(_index(CELL, 4)), BoardPainter.Look.NONE, "hint cross crossed by Auto Cross draws nothing")
	assert_eq(painter._candidate_look(_index(CELL, 1)), BoardPainter.Look.NONE, "open candidate draws nothing")
	assert_eq(painter._candidate_look(_index(OTHER_CELL, 7)), BoardPainter.Look.NONE, "hand X draws nothing")
	var shown: int = 0
	for index: int in BoardPainter.MARKS:
		if painter._candidate_look(index) != BoardPainter.Look.NONE:
			shown += 1
	assert_eq(shown, 2, "only the two open hint crosses draw on the whole board")


func test_ring_hidden_without_a_hint_draws_no_candidate() -> void:
	var state: BoardDrawState = _state(false)
	state.hint_crosses = PackedInt32Array()
	var painter: BoardPainter = _painter(state)
	for index: int in BoardPainter.MARKS:
		if painter._candidate_look(index) != BoardPainter.Look.NONE:
			fail("candidate %d draws with the ring hidden and no hint" % index)
			return


func test_selection_frame_is_place_while_hidden() -> void:
	var state: BoardDrawState = _state(true)
	state.mode = BoardPainter.MODE_CROSS_OUT
	assert_true(_painter(state)._frame_is_cross_out(), "shown, Cross Out: broken frame")
	state.mode = 0
	assert_false(_painter(state)._frame_is_cross_out(), "shown, Place: solid frame")
	state.show_ring = false
	state.mode = BoardPainter.MODE_CROSS_OUT
	assert_false(_painter(state)._frame_is_cross_out(), "hidden, Cross Out: solid frame")
	state.mode = 0
	assert_false(_painter(state)._frame_is_cross_out(), "hidden, Place: solid frame")


func test_effects_while_shown_are_unchanged() -> void:
	var painter: BoardPainter = _painter(_state(true))
	assert_true(painter._mark_effect_draws(), "CROSS and RESTORE draw")
	assert_eq(painter._effect_ring_alpha(_effect(CellEffect.Kind.PLACE, 0.0)), 1.0, "PLACE starts with the ring")
	assert_eq(painter._effect_ring_alpha(_effect(CellEffect.Kind.PLACE, 1.0)), 0.0, "PLACE ends without it")
	var mid: float = painter._effect_ring_alpha(_effect(CellEffect.Kind.PLACE, 0.25))
	assert_true(mid > 0.0 and mid < 1.0, "PLACE fades the ring")
	assert_eq(painter._effect_ring_alpha(_effect(CellEffect.Kind.ERASE, 0.0)), 0.0, "ERASE starts without the ring")
	mid = painter._effect_ring_alpha(_effect(CellEffect.Kind.ERASE, 0.5))
	assert_true(mid > 0.0 and mid < 1.0, "ERASE fades the ring in")


func test_effects_while_hidden_have_no_ring_fade() -> void:
	var painter: BoardPainter = _painter(_state(false))
	assert_false(painter._mark_effect_draws(), "CROSS and RESTORE draw nothing")
	for p: float in [0.0, 0.25, 0.5, 1.0]:
		assert_eq(painter._effect_ring_alpha(_effect(CellEffect.Kind.PLACE, p)), 0.0, "PLACE draws no ring at %.2f" % p)
		# ERASE draws the ring layer as the board does, at once: hidden, that
		# is only the open hint crosses, which change instantly.
		assert_eq(painter._effect_ring_alpha(_effect(CellEffect.Kind.ERASE, p)), 1.0, "ERASE has no fade at %.2f" % p)

