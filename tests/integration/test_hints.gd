extends "res://tests/unit_test.gd"
## Phase 4 verify item 5, end to end: the HUD Hint button charges the score,
## the board highlights the candidates the hint says to cross (hint_crosses
## in the draw state, GDD AT-69), and the button is disabled while a hint
## shows and when the score cannot pay (GDD 10.4, AT-45).

const Ix := preload("res://tests/integration/integration_fixtures.gd")
const TS := preload("res://src/puzzles/technique_solver.gd")

const MEDIUM_SEED: int = 1


## A Medium puzzle resumed from a save, then played through the pad up to
## the first step that needs an elimination (the AT-43 position).
func _medium_at_an_elimination() -> Ix.Harness:
	var puzzle: Puzzle = PuzzleSource.get_puzzle(Levels.MEDIUM, MEDIUM_SEED)
	var dir: String = Ix.new_dir("hint_medium")
	Ix.write_settings(dir)
	Ix.write_session(dir, GameSession.create(puzzle.id, puzzle.level, puzzle.givens, puzzle.solution, false))
	var h: Ix.Harness = Ix.open_app(dir)
	Ix.click(h.top().get(&"continue_button") as Button)
	Ix.fit(h)
	var area: PlayArea = Ix.play_area_of(h.top())
	var solver: TechniqueSolver = TechniqueSolver.new()
	solver.load_givens(puzzle.givens)
	while solver.find_step(TS.MAX_LEVEL) != TS.NO_STEP and solver.step_cell() >= 0:
		solver.apply_step()
	var cells: PackedInt32Array = solver.get_cells()
	for cell: int in Sudoku.CELLS:
		if puzzle.givens[cell] == 0 and cells[cell] != 0:
			Ix.place(area, cell, cells[cell])
	return h


func test_hint_charges_highlights_and_disables() -> void:
	var h: Ix.Harness = _medium_at_an_elimination()
	var screen: Control = h.top()
	var area: PlayArea = Ix.play_area_of(screen)
	var session: GameSession = h.app.session
	var hud: PlayHud = screen.get(&"hud")
	var panel: HintPanel = screen.get(&"hint_panel")
	var cost: int = session.hint_cost()
	assert_eq(cost, Scoring.points(Levels.MEDIUM) / 5, "a fifth of the level's points")
	var score: int = session.score()
	var digits: PackedInt32Array = session.board.digits.duplicate()
	var marks: PackedByteArray = session.board.marks.duplicate()
	assert_false(hud.hint_button.disabled)
	assert_true(Ix.click(hud.hint_button), "Hint")
	assert_eq(session.score(), score - cost, "the hint is paid from the score")
	assert_eq(hud.score_value.text, str(score - cost), "the HUD shows it")
	assert_eq(session.board.digits, digits, "a hint fills nothing in")
	assert_eq(session.board.marks, marks, "a hint crosses nothing")
	var hint: Hint = session.hint
	assert_true(hint != null)
	if hint == null:
		Ix.close(h)
		return
	assert_true(panel.visible, "the panel shows")
	assert_eq(panel.text_label.text, hint.text)
	assert_false(hint.eliminations.is_empty(), "this step crosses candidates")
	var state: BoardDrawState = area.view.draw_state()
	assert_eq(state.hint_crosses, hint.eliminations, "the board highlights the candidates to cross")
	assert_eq(state.hint_targets, hint.targets)
	assert_eq(state.hint_reasons, hint.reasons)
	assert_true(hud.hint_button.disabled, "disabled while a hint shows")
	assert_false(Ix.click(hud.hint_button), "a disabled Hint takes no tap")
	assert_eq(session.hints_bought, 1)

	# Crossing one of them by hand keeps the hint and its list (the painter
	# draws a crossed one as usual).
	var mark: int = hint.eliminations[0]
	Ix.tap_mode(area, GameSession.Mode.CROSS_OUT)
	Ix.tap_cell(area, mark / 9)
	Ix.tap_digit(area, mark % 9 + 1)
	assert_eq(session.board.marks[mark], Board.Mark.CROSSED_HAND)
	assert_true(session.hint != null, "a cross does not close the hint")
	assert_eq(area.view.draw_state().hint_crosses, hint.eliminations)

	# Close, then buy until the score cannot pay.
	assert_true(Ix.click(panel.close_button), "close the hint")
	assert_false(panel.visible)
	assert_true(area.view.draw_state().hint_crosses.is_empty(), "the highlight goes with the hint")
	assert_false(hud.hint_button.disabled)
	for i: int in 4:
		assert_true(Ix.click(hud.hint_button), "hint %d" % (i + 2))
		assert_true(Ix.click(panel.close_button))
	assert_eq(session.score(), 0)
	assert_eq(hud.score_value.text, "0")
	assert_true(hud.hint_button.disabled, "disabled when unaffordable")
	assert_false(Ix.click(hud.hint_button))
	assert_eq(session.hints_bought, 5, "no sixth hint")
	assert_eq(session.score(), 0, "never below zero")
	Ix.close(h)


func test_a_placement_closes_the_hint_and_a_wrong_digit_is_pointed_at() -> void:
	var dir: String = Ix.new_dir("hint_wrong")
	Ix.write_settings(dir)
	var h: Ix.Harness = Ix.open_app(dir)
	Ix.start_from_menu(h, Levels.BEGINNER)
	var screen: Control = h.top()
	var area: PlayArea = Ix.play_area_of(screen)
	var session: GameSession = h.app.session
	var hud: PlayHud = screen.get(&"hud")
	var cell: int = Ix.empty_cells(session)[0]
	var wrong: int = session.solution[cell] % 9 + 1
	Ix.place(area, cell, wrong)
	assert_true(Ix.click(hud.hint_button))
	assert_eq(session.score(), 80)
	assert_eq(session.hint.technique, &"wrong_digit", "AT-41: it points at the wrong digit")
	assert_true(session.hint.targets.has(cell))
	assert_eq(area.view.draw_state().hint_targets, session.hint.targets)
	assert_eq(session.board.digit(cell), wrong, "it does not fix it")
	Ix.tap_digit(area, session.solution[cell])
	assert_eq(session.hint, null, "a replace closes the hint")
	assert_false((screen.get(&"hint_panel") as HintPanel).visible)
	assert_false(hud.hint_button.disabled)
	assert_eq(session.score(), 80, "the charge stays")
	Ix.close(h)
