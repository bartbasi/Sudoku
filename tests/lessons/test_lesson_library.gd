extends "res://tests/unit_test.gd"
## LessonLibrary: the loader takes only the format in docs/ARCHITECTURE.md
## section 10, converts rXcY to cells, and rejects anything else as a whole.

const Lx := preload("res://tests/lessons/lesson_fixtures.gd")


func _parse(data: Variant) -> Lesson:
	return LessonLibrary.parse(JSON.stringify(data))


func _rejects(data: Variant, why: String) -> void:
	var text: String = JSON.stringify(data)
	assert_eq(LessonLibrary.parse(text), null, "rejects " + why)
	assert_ne(LessonLibrary.check(text), "", "explains " + why)


func _screen(data: Dictionary, index: int) -> Dictionary:
	return (data["screens"] as Array)[index] as Dictionary


func test_cell_names_convert_to_cells() -> void:
	assert_eq(LessonLibrary.cell_from_name("r1c1"), 0)
	assert_eq(LessonLibrary.cell_from_name("r1c9"), 8)
	assert_eq(LessonLibrary.cell_from_name("r5c5"), 40)
	assert_eq(LessonLibrary.cell_from_name("r9c9"), 80)
	assert_eq(LessonLibrary.cell_name(40), "r5c5")
	for bad: String in ["", "r0c1", "r1c0", "r10c1", "R1c1", "r1C1", "c1r1", "r1c1 ", "rxcy", "r-1c1"]:
		assert_eq(LessonLibrary.cell_from_name(bad), -1, "not a cell: %s" % bad)


func test_parses_a_valid_lesson() -> void:
	var lesson: Lesson = _parse(Lx.small_lesson())
	assert_ne(lesson, null)
	assert_eq(lesson.id, "lesson_07")
	assert_eq(lesson.number, 7)
	assert_eq(lesson.title, "Test lesson")
	assert_eq(lesson.screens.size(), 2)
	var first: LessonScreen = lesson.screens[0]
	assert_eq(first.selected, -1)
	assert_eq(first.mode, GameSession.Mode.PLACE)
	assert_eq(first.marked_cells, PackedInt32Array([40]))
	assert_eq(first.steps.size(), 1)
	assert_eq(first.steps[0].kind, BoardAction.Kind.CELL)
	assert_eq(first.steps[0].cell, 40)
	assert_false(first.in_sequence)
	assert_false(first.has_next)
	var second: LessonScreen = lesson.screens[1]
	assert_eq(second.selected, 40)
	assert_eq(second.mode, GameSession.Mode.CROSS_OUT)
	assert_eq(second.crossed, PackedInt32Array([40 * 9 + 6]))
	assert_eq(second.marked_controls, [&"pad:9", &"mode"] as Array[StringName])
	assert_true(second.in_sequence)
	assert_eq(second.next_after["pad:9"], "Now cross out 3.")
	assert_eq(second.wrong[0].crossed, 1)
	assert_eq(second.wrong[0].digits, PackedInt32Array([7]))


func test_other_leaves_out_earlier_cells_and_the_goal() -> void:
	var lesson: Lesson = _parse(Lx.small_lesson())
	var other: LessonScreen.WrongTap = lesson.screens[0].wrong[1]
	assert_true(other.other)
	assert_true(other.excluded.has(40), "the goal cell")
	assert_true(other.excluded.has(37), "r5c2 from the earlier entry")
	assert_eq(other.excluded.size(), 2)


func test_next_after_cell_keys_become_cells() -> void:
	var data: Dictionary = Lx.small_lesson()
	_screen(data, 0)["next"] = {"start": "Tap it.", "after": {"cell:r5c5": "Done."}}
	var lesson: Lesson = _parse(data)
	assert_ne(lesson, null)
	assert_eq(lesson.screens[0].next_after["cell:40"], "Done.")


func test_build_board_applies_placed_and_crossed() -> void:
	var data: Dictionary = Lx.small_lesson()
	(_screen(data, 1)["start"] as Dictionary)["placed"] = {"r5c1": 7}
	var lesson: Lesson = _parse(data)
	assert_ne(lesson, null)
	var screen: LessonScreen = lesson.screens[1]
	var board: Board = screen.build_board()
	assert_eq(board.digit(36), 7)
	assert_false(board.is_given(36), "a placed digit is the player's own")
	assert_eq(board.mark(40, 7), Board.Mark.CROSSED_HAND)
	assert_eq(screen.position()[36], 7)
	var session: GameSession = screen.build_session()
	assert_eq(session.selected, 40)
	assert_eq(session.mode, GameSession.Mode.CROSS_OUT)
	assert_false(session.auto_cross)
	assert_eq(session.level, -1)


func test_whole_numbers_may_come_as_floats() -> void:
	var data: Dictionary = Lx.small_lesson()
	data["number"] = 7.0
	data["format"] = 1.0
	assert_ne(_parse(data), null)


func test_rejects_text_that_is_not_a_lesson_object() -> void:
	for text: String in ["", "not json", "{", "null", "[]", "42", "\"lesson\""]:
		assert_eq(LessonLibrary.parse(text), null, "rejects %s" % text)


func test_rejects_a_text_longer_than_the_limit() -> void:
	var data: Dictionary = Lx.small_lesson()
	data["title"] = "x".repeat(LessonLibrary.MAX_FILE_BYTES)
	_rejects(data, "a huge file")


func test_rejects_bad_top_level_fields() -> void:
	var cases: Dictionary[String, Callable] = {
		"format 2": func(d: Dictionary) -> void: d["format"] = 2,
		"a fractional number": func(d: Dictionary) -> void: d["number"] = 7.5,
		"number 0": func(d: Dictionary) -> void: d["number"] = 0,
		"a string number": func(d: Dictionary) -> void: d["number"] = "7",
		"an id that does not match": func(d: Dictionary) -> void: d["id"] = "lesson_08",
		"an id with a path": func(d: Dictionary) -> void: d["id"] = "../lesson_07",
		"an empty title": func(d: Dictionary) -> void: d["title"] = " ",
		"a title that is not a string": func(d: Dictionary) -> void: d["title"] = ["x"],
		"an unknown key": func(d: Dictionary) -> void: d["script"] = "res://evil.gd",
		"a missing subtitle": func(d: Dictionary) -> void: d.erase("subtitle"),
		"a short solution": func(d: Dictionary) -> void: d["solution"] = (d["solution"] as String).substr(1),
		"an invalid solution": func(d: Dictionary) -> void: d["solution"] = "1".repeat(81),
		"a solution with dots": func(d: Dictionary) -> void: d["solution"] = "." + (d["solution"] as String).substr(1),
		"no screens": func(d: Dictionary) -> void: d["screens"] = [],
		"screens as an object": func(d: Dictionary) -> void: d["screens"] = {},
	}
	for why: String in cases:
		var data: Dictionary = Lx.small_lesson()
		cases[why].call(data)
		_rejects(data, why)


func test_rejects_bad_screens() -> void:
	var cases: Dictionary[String, Callable] = {
		"a board of 80": func(s: Dictionary) -> void: s["board"] = (s["board"] as String).substr(1),
		"a board with a 0": func(s: Dictionary) -> void: s["board"] = "0" + (s["board"] as String).substr(1),
		"a given that disagrees with the solution": func(s: Dictionary) -> void: s["board"] = "4" + (s["board"] as String).substr(1),
		"a missing start": func(s: Dictionary) -> void: s.erase("start"),
		"an unknown mode": func(s: Dictionary) -> void: (s["start"] as Dictionary)["mode"] = "auto",
		"a missing mode": func(s: Dictionary) -> void: (s["start"] as Dictionary).erase("mode"),
		"a bad selected cell": func(s: Dictionary) -> void: (s["start"] as Dictionary)["selected"] = "r0c0",
		"a selected number": func(s: Dictionary) -> void: (s["start"] as Dictionary)["selected"] = 40,
		"a placed digit on a given": func(s: Dictionary) -> void: (s["start"] as Dictionary)["placed"] = {"r1c1": 3},
		"a placed digit the solution disagrees with": func(s: Dictionary) -> void: (s["start"] as Dictionary)["placed"] = {"r5c5": 1},
		"a placed digit of 10": func(s: Dictionary) -> void: (s["start"] as Dictionary)["placed"] = {"r5c5": 10},
		"a crossed digit of 0": func(s: Dictionary) -> void: (s["start"] as Dictionary)["crossed"] = {"r5c5": [0]},
		"crossed in a given cell": func(s: Dictionary) -> void: (s["start"] as Dictionary)["crossed"] = {"r1c1": [2]},
		"crossed as a list": func(s: Dictionary) -> void: (s["start"] as Dictionary)["crossed"] = [1],
		"an unknown start key": func(s: Dictionary) -> void: (s["start"] as Dictionary)["auto_cross"] = true,
		"an unknown marked cell": func(s: Dictionary) -> void: s["marked_cells"] = ["r5c10"],
		"an unknown control": func(s: Dictionary) -> void: s["marked_controls"] = ["hint"],
		"an empty text": func(s: Dictionary) -> void: s["text"] = "",
		"a text too long": func(s: Dictionary) -> void: s["text"] = "x".repeat(LessonLibrary.MAX_TEXT + 1),
		"a missing praise": func(s: Dictionary) -> void: s.erase("praise"),
		"a missing fallback": func(s: Dictionary) -> void: s.erase("fallback"),
		"an unknown screen key": func(s: Dictionary) -> void: s["hint"] = "x",
	}
	for why: String in cases:
		var data: Dictionary = Lx.small_lesson()
		cases[why].call(_screen(data, 0))
		_rejects(data, why)


func test_rejects_bad_goals_and_matches() -> void:
	var cases: Dictionary[String, Callable] = {
		"an unknown order": func(s: Dictionary) -> void: (s["goal"] as Dictionary)["order"] = "random",
		"no steps": func(s: Dictionary) -> void: (s["goal"] as Dictionary)["steps"] = [],
		"an unknown action": func(s: Dictionary) -> void: (s["goal"] as Dictionary)["steps"] = [{"action": "hint"}],
		"a pad step with no digit": func(s: Dictionary) -> void: (s["goal"] as Dictionary)["steps"] = [{"action": "pad"}],
		"a pad step with a cell": func(s: Dictionary) -> void: (s["goal"] as Dictionary)["steps"] = [{"action": "pad", "digit": 3, "cell": "r1c1"}],
		"a mode step with a digit": func(s: Dictionary) -> void: (s["goal"] as Dictionary)["steps"] = [{"action": "mode", "digit": 3}],
		"a cell step with a bad cell": func(s: Dictionary) -> void: (s["goal"] as Dictionary)["steps"] = [{"action": "cell", "cell": "middle"}],
		"a technique that places nothing": func(s: Dictionary) -> void: (s["goal"] as Dictionary)["technique"] = "x_wing",
		"a goal key unknown": func(s: Dictionary) -> void: (s["goal"] as Dictionary)["reward"] = 5,
		"a match with digits on a cell tap": func(s: Dictionary) -> void: s["wrong"] = [{"match": {"action": "cell", "digits": [1]}, "text": "x"}],
		"a match with cells on a pad tap": func(s: Dictionary) -> void: s["wrong"] = [{"match": {"action": "pad", "cells": ["r1c1"]}, "text": "x"}],
		"a match crossed that is not a bool": func(s: Dictionary) -> void: s["wrong"] = [{"match": {"action": "pad", "crossed": 1}, "text": "x"}],
		"a match with cells as another word": func(s: Dictionary) -> void: s["wrong"] = [{"match": {"action": "cell", "cells": "all"}, "text": "x"}],
		"a match with digit 10": func(s: Dictionary) -> void: s["wrong"] = [{"match": {"action": "pad", "digits": [10]}, "text": "x"}],
		"a wrong entry with no text": func(s: Dictionary) -> void: s["wrong"] = [{"match": {"action": "mode"}}],
		"a next with no start": func(s: Dictionary) -> void: s["next"] = {"after": {}},
		"a next after key unknown": func(s: Dictionary) -> void: s["next"] = {"start": "x", "after": {"hint": "y"}},
		"a next after cell unknown": func(s: Dictionary) -> void: s["next"] = {"start": "x", "after": {"cell:r0c0": "y"}},
	}
	for why: String in cases:
		var data: Dictionary = Lx.small_lesson()
		cases[why].call(_screen(data, 0))
		_rejects(data, why)


func test_load_all_reads_only_the_data_folder() -> void:
	var lessons: Array[Lesson] = LessonLibrary.load_all()
	assert_eq(lessons.size(), Lx.data_file_names().size())
	for i: int in range(1, lessons.size()):
		assert_true(lessons[i - 1].number < lessons[i].number, "sorted by number")
