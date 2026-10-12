extends "res://tests/unit_test.gd"
## LessonGoal: right, wrong and ignored taps, each step counting once, the
## order of a sequence, and the wrong tap texts with {d} and {next}.

const Lx := preload("res://tests/lessons/lesson_fixtures.gd")

var lesson: Lesson


func _cell(cell: int) -> BoardAction:
	return BoardAction.create(BoardAction.Kind.CELL, cell)


func _pad(d: int) -> BoardAction:
	return BoardAction.create(BoardAction.Kind.PAD, -1, d)


func _mode() -> BoardAction:
	return BoardAction.create(BoardAction.Kind.MODE)


func _erase() -> BoardAction:
	return BoardAction.create(BoardAction.Kind.ERASE)


func _small() -> Lesson:
	return LessonLibrary.parse(JSON.stringify(Lx.small_lesson()))


func test_a_single_step_goal() -> void:
	var goal: LessonGoal = LessonGoal.create(_small().screens[0])
	assert_false(goal.is_complete())
	assert_eq(goal.judge(_cell(39)), LessonGoal.Verdict.WRONG)
	assert_eq(goal.judge(_pad(5)), LessonGoal.Verdict.WRONG)
	assert_eq(goal.judge(_mode()), LessonGoal.Verdict.WRONG)
	assert_eq(goal.judge(_erase()), LessonGoal.Verdict.WRONG)
	assert_false(goal.accept(_cell(39)), "a wrong tap is not accepted")
	assert_eq(goal.judge(_cell(40)), LessonGoal.Verdict.RIGHT)
	assert_true(goal.accept(_cell(40)))
	assert_true(goal.is_complete())
	assert_eq(goal.judge(_cell(39)), LessonGoal.Verdict.IGNORED, "after the answer every tap is ignored")
	assert_eq(goal.judge(_cell(40)), LessonGoal.Verdict.IGNORED)


func test_a_sequence_takes_its_steps_in_order() -> void:
	var goal: LessonGoal = LessonGoal.create(_small().screens[1])
	assert_eq(goal.judge(_pad(3)), LessonGoal.Verdict.WRONG, "a later step is wrong until its turn")
	assert_eq(goal.judge(_pad(7)), LessonGoal.Verdict.WRONG)
	assert_true(goal.accept(_pad(9)))
	assert_eq(goal.judge(_pad(9)), LessonGoal.Verdict.WRONG, "a step counts once")
	assert_true(goal.accept(_pad(3)))
	assert_eq(goal.done_count(), 2)
	assert_true(goal.accept(_pad(7)))
	assert_true(goal.is_complete())


func test_an_any_order_goal_takes_each_step_once() -> void:
	var screen: LessonScreen = Lx.lesson(2).screens[4]
	assert_false(screen.in_sequence)
	var goal: LessonGoal = LessonGoal.create(screen)
	assert_true(goal.accept(_pad(6)), "6 before 4 is fine")
	assert_eq(goal.judge(_pad(6)), LessonGoal.Verdict.WRONG, "6 again would restore it")
	assert_true(goal.accept(_pad(4)))
	assert_true(goal.is_complete())


func test_next_follows_the_step_done_last() -> void:
	var goal: LessonGoal = LessonGoal.create(Lx.lesson(2).screens[4])
	assert_eq(goal.next_text(), "Cross out 4 and 6.")
	goal.accept(_pad(4))
	assert_eq(goal.next_text(), "Now cross out 6.")
	var other: LessonGoal = LessonGoal.create(Lx.lesson(2).screens[4])
	other.accept(_pad(6))
	assert_eq(other.next_text(), "Now cross out 4.")


func test_wrong_text_takes_the_first_match_and_fills_it_in() -> void:
	var screen: LessonScreen = _small().screens[1]
	var goal: LessonGoal = LessonGoal.create(screen)
	var board: Board = screen.build_board()
	assert_eq(goal.wrong_text(_pad(7), board, 40), "7 later. Cross out 9.", "7 is crossed: the first entry")
	assert_eq(goal.wrong_text(_pad(1), board, 40), "Not 1. Cross out 9.", "1 is open: the third entry")
	assert_eq(goal.wrong_text(_mode(), board, 40), "Cross out 9.", "no match: the fallback")
	goal.accept(_pad(9))
	board.marks[40 * 9 + 8] = Board.Mark.CROSSED_HAND
	assert_eq(goal.wrong_text(_pad(9), board, 40), "9 has an X. Now cross out 3.")
	assert_eq(goal.wrong_text(_pad(9), board, -1), "Not 9. Now cross out 3.", "no selection: nothing is crossed")


func test_cell_entries_and_other() -> void:
	var screen: LessonScreen = _small().screens[0]
	var goal: LessonGoal = LessonGoal.create(screen)
	var board: Board = screen.build_board()
	assert_eq(goal.wrong_text(_cell(37), board, -1), "That is the 9.")
	assert_eq(goal.wrong_text(_cell(0), board, -1), "Another cell.")
	assert_eq(goal.wrong_text(_pad(4), board, -1), "Pick a cell first.")


func test_all_wrong_texts_covers_every_next() -> void:
	var goal: LessonGoal = LessonGoal.create(_small().screens[1])
	var texts: PackedStringArray = goal.all_wrong_texts()
	assert_true(texts.has("Cross out 9."))
	assert_true(texts.has("Now bring back 7."))
	assert_true(texts.has("9 has an X. Now cross out 3."))


func test_lesson_two_wrong_taps_say_what_lessons_md_says() -> void:
	# Screen 3 (cross out 9), with r5c5 selected in Cross Out mode.
	var screen: LessonScreen = Lx.lesson(2).screens[2]
	var goal: LessonGoal = LessonGoal.create(screen)
	var board: Board = screen.build_board()
	assert_eq(goal.wrong_text(_pad(5), board, 40), "There is no 5 in this row, column or box. So 5 can still go here. Tap 9.")
	assert_eq(goal.wrong_text(_pad(4), board, 40), "Yes, this column has a 4. We will get to the column soon. Tap 9 first.")
	assert_eq(goal.wrong_text(_cell(40), board, 40), "The small digits are too small to tap. Tap 9 on the number pad instead.")
	assert_eq(goal.wrong_text(_cell(37), board, 40), "That is the 9 in the row. To cross out 9 in the ring, tap 9 on the number pad.")
	assert_eq(goal.wrong_text(_cell(0), board, 40), "Keep this cell selected. Tap 9 on the number pad.")
	assert_eq(goal.wrong_text(_mode(), board, 40), "Stay in Cross Out mode for now. Tap 9 on the number pad.")
	assert_eq(goal.wrong_text(_erase(), board, 40), "Tap 9 on the number pad.")
