extends "res://tests/unit_test.gd"
## The lesson data test (docs/ARCHITECTURE.md section 10): every file in
## src/lessons/data/ parses; every screen's position (board plus placed
## digits) is legal, solvable and agrees with the solution; every step of
## every answer is accepted by the goal and does something on the real
## session; every cross step crosses a digit ruled out in that cell at that
## moment, and every restore step brings back one that is not; every
## placement step's cell and digit are found by NextStep.placements_by for
## the technique the screen names. Preset crosses are not checked against
## the rules (lesson 2 sets a wrong one on purpose).

const Lx := preload("res://tests/lessons/lesson_fixtures.gd")

## GDD 11.2 and LESSONS.md section 4: lessons 3 to 5 carry the titles hints name.
const TITLES: Dictionary[int, String] = {
	1: "How Sudoku works",
	2: "The ring and Cross Out",
	3: "Last empty cell",
	4: "Hidden single",
	5: "Naked single",
}


func test_every_file_parses() -> void:
	var names: PackedStringArray = Lx.data_file_names()
	assert_eq(names.size(), 5, "v1 has lessons 1 to 5")
	for file_name: String in names:
		var reason: String = LessonLibrary.check(Lx.read(file_name))
		assert_eq(reason, "", "%s is valid" % file_name)


func test_load_all_gives_lessons_one_to_five_in_order() -> void:
	var lessons: Array[Lesson] = LessonLibrary.load_all()
	assert_eq(lessons.size(), 5)
	for i: int in lessons.size():
		var lesson: Lesson = lessons[i]
		assert_eq(lesson.number, i + 1)
		assert_eq(lesson.id, "lesson_%02d" % (i + 1))
		assert_eq(lesson.title, TITLES[i + 1], "title of lesson %d" % (i + 1))
		assert_false(lesson.subtitle.is_empty())


func test_hint_lesson_titles_name_real_lessons() -> void:
	var titles: PackedStringArray = PackedStringArray()
	for lesson: Lesson in LessonLibrary.load_all():
		titles.append("Lesson: " + lesson.title)
	for title: String in NextStep.LESSONS:
		if not title.is_empty():
			assert_true(titles.has(title), "%s names a lesson that exists" % title)


func test_screen_counts_match_lessons_md() -> void:
	var expected: Array[int] = [6, 8, 5, 6, 6]
	var lessons: Array[Lesson] = LessonLibrary.load_all()
	for i: int in mini(lessons.size(), expected.size()):
		assert_eq(lessons[i].screens.size(), expected[i], "screens in lesson %d" % (i + 1))


func test_every_position_is_legal_solvable_and_matches_the_solution() -> void:
	for lesson: Lesson in LessonLibrary.load_all():
		assert_true(Sudoku.is_complete_solution(lesson.solution), "%s solution" % lesson.id)
		for i: int in lesson.screens.size():
			var where: String = "%s screen %d" % [lesson.id, i + 1]
			var screen: LessonScreen = lesson.screens[i]
			var grid: PackedInt32Array = screen.position()
			var board: Board = screen.build_board()
			assert_eq(board.conflict_cells().size(), 0, where + ": no digit repeats in a row, column or box")
			assert_true(Solver.count_solutions(grid, 1) >= 1, where + ": the position can be completed")
			for cell: int in Sudoku.CELLS:
				if grid[cell] != 0 and grid[cell] != lesson.solution[cell]:
					fail("%s: %s is %d, the solution has %d" % [where, LessonLibrary.cell_name(cell), grid[cell], lesson.solution[cell]])


func test_every_answer_plays_and_is_right() -> void:
	for lesson: Lesson in LessonLibrary.load_all():
		for i: int in lesson.screens.size():
			_play_answer(lesson, i)


func test_placements_name_a_technique_and_only_they_do() -> void:
	for lesson: Lesson in LessonLibrary.load_all():
		for i: int in lesson.screens.size():
			var screen: LessonScreen = lesson.screens[i]
			var places: bool = _places_a_digit(screen)
			var where: String = "%s screen %d" % [lesson.id, i + 1]
			if places:
				assert_ne(screen.technique, &"", where + " places a digit, so it names its technique")
			else:
				assert_eq(screen.technique, &"", where + " places nothing, so it names no technique")


func test_text_placeholders_are_used_where_they_can_be_filled() -> void:
	for lesson: Lesson in LessonLibrary.load_all():
		for i: int in lesson.screens.size():
			var screen: LessonScreen = lesson.screens[i]
			var where: String = "%s screen %d" % [lesson.id, i + 1]
			for text: String in [screen.text, screen.praise, screen.next_start]:
				assert_false(text.contains("{"), where + ": no placeholder in step, praise or next text")
			for text: String in screen.next_after.values():
				assert_false(text.contains("{"), where + ": no placeholder in next text")
			assert_false(screen.fallback.contains("{d}"), where + ": {d} only in pad entries")
			if screen.fallback.contains("{next}"):
				assert_true(screen.has_next, where + ": {next} in the fallback needs next")
			for rule: LessonScreen.WrongTap in screen.wrong:
				if rule.text.contains("{d}"):
					assert_eq(rule.kind, BoardAction.Kind.PAD, where + ": {d} only in pad entries: " + rule.text)
				if rule.text.contains("{next}"):
					assert_true(screen.has_next, where + ": {next} needs next: " + rule.text)
				var left: String = rule.text.replace("{d}", "").replace("{next}", "")
				assert_false(left.contains("{") or left.contains("}"), where + ": unknown placeholder in " + rule.text)


func test_next_after_keys_name_steps_of_the_goal() -> void:
	for lesson: Lesson in LessonLibrary.load_all():
		for i: int in lesson.screens.size():
			var screen: LessonScreen = lesson.screens[i]
			var keys: PackedStringArray = PackedStringArray()
			for step: BoardAction in screen.steps:
				keys.append(LessonScreen.step_key(step))
			for key: String in screen.next_after.keys():
				assert_true(keys.has(key), "%s screen %d: next.after %s is a step of the goal" % [lesson.id, i + 1, key])


func test_marked_cells_and_selection_are_on_the_board() -> void:
	for lesson: Lesson in LessonLibrary.load_all():
		for screen: LessonScreen in lesson.screens:
			for cell: int in screen.marked_cells:
				assert_true(Sudoku.is_cell(cell))
			assert_true(screen.selected == -1 or Sudoku.is_cell(screen.selected))
			for control: StringName in screen.marked_controls:
				assert_true(LessonLibrary.CONTROLS.has(String(control)))


func test_text_follows_the_writing_rules() -> void:
	for lesson: Lesson in LessonLibrary.load_all():
		var texts: PackedStringArray = PackedStringArray([lesson.title, lesson.subtitle])
		for screen: LessonScreen in lesson.screens:
			texts.append_array([screen.text, screen.praise, screen.fallback, screen.next_start])
			for value: String in screen.next_after.values():
				texts.append(value)
			for rule: LessonScreen.WrongTap in screen.wrong:
				texts.append(rule.text)
		for text: String in texts:
			assert_false(text.contains("—") or text.contains("--"), "%s: no em dash or double hyphen: %s" % [lesson.id, text])


# Helpers ------------------------------------------------------------------------

## Plays a screen's answer on its real session, in the listed order (one
## order an "any" goal allows), checking every step as it goes.
func _play_answer(lesson: Lesson, index: int) -> void:
	var screen: LessonScreen = lesson.screens[index]
	var where: String = "%s screen %d" % [lesson.id, index + 1]
	var session: GameSession = screen.build_session()
	var goal: LessonGoal = LessonGoal.create(screen)
	assert_eq(session.auto_cross, false, where + ": Auto Cross off")
	for step: BoardAction in screen.steps:
		var label: String = "%s step %s" % [where, LessonScreen.step_key(step)]
		assert_eq(goal.judge(step), LessonGoal.Verdict.RIGHT, label + " is judged right")
		var cell: int = session.selected
		match step.kind:
			BoardAction.Kind.CELL:
				session.select(step.cell)
				assert_eq(session.selected, step.cell, label + " selects the cell")
			BoardAction.Kind.MODE:
				var before: int = session.mode
				session.toggle_mode()
				assert_ne(session.mode, before, label + " changes the mode")
			BoardAction.Kind.PAD:
				_check_pad_step(lesson, screen, session, step.digit, label)
			_:
				fail(label + ": Erase and Undo change nothing a lesson can check, so no step uses them")
		assert_true(goal.accept(step), label + " is accepted")
		if step.kind != BoardAction.Kind.PAD:
			assert_true(cell == session.selected or step.kind == BoardAction.Kind.CELL, label + " keeps the selection")
	assert_true(goal.is_complete(), where + ": the answer completes the goal")
	assert_false(session.is_completed, where + ": a lesson never completes like a puzzle")


func _check_pad_step(lesson: Lesson, screen: LessonScreen, session: GameSession, d: int, label: String) -> void:
	var cell: int = session.selected
	if not Sudoku.is_cell(cell):
		fail(label + ": a pad step needs a selected cell")
		return
	if session.board.digit(cell) != 0 and session.mode == GameSession.Mode.CROSS_OUT:
		fail(label + ": crossing in a cell that holds a digit does nothing")
		return
	if session.board.is_given(cell):
		fail(label + ": a given cell cannot change")
		return
	if session.mode == GameSession.Mode.PLACE:
		var grid: PackedInt32Array = session.board.digits.duplicate()
		assert_eq(grid[cell], 0, label + ": places into an empty cell")
		assert_eq(d, lesson.solution[cell], label + ": the placed digit is the solution's")
		var found: Array[Vector2i] = NextStep.placements_by(grid, screen.technique)
		assert_true(found.has(Vector2i(cell, d)), "%s: %s finds %d in %s" % [label, screen.technique, d, LessonLibrary.cell_name(cell)])
		var result: ActionResult = session.press_digit(d)
		assert_true(result.applied, label + " places the digit")
		assert_eq(session.board.digit(cell), d)
		return
	var was_crossed: bool = session.board.is_crossed(cell, d)
	var ruled_out: bool = session.board.is_ruled_out(cell, d)
	if was_crossed:
		assert_false(ruled_out, "%s: restores %d, which nothing rules out in %s" % [label, d, LessonLibrary.cell_name(cell)])
	else:
		assert_true(ruled_out, "%s: crosses %d, which is ruled out in %s" % [label, d, LessonLibrary.cell_name(cell)])
	var applied: ActionResult = session.press_digit(d)
	assert_true(applied.applied, label + " changes the ring")
	assert_eq(session.board.is_crossed(cell, d), not was_crossed)


## Whether playing the answer places a digit: a pad step while the mode is
## Place, following the mode steps before it.
func _places_a_digit(screen: LessonScreen) -> bool:
	var mode: int = screen.mode
	for step: BoardAction in screen.steps:
		if step.kind == BoardAction.Kind.MODE:
			mode = GameSession.Mode.CROSS_OUT if mode == GameSession.Mode.PLACE else GameSession.Mode.PLACE
		elif step.kind == BoardAction.Kind.PAD and mode == GameSession.Mode.PLACE:
			return true
	return false
