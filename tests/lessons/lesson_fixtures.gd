extends RefCounted
## Shared setup for the lesson tests. Not a test file (no test_ prefix).

const LIGHT_PATH: String = "res://src/skins/pop_light.tres"


static func light() -> GameSkin:
	return load(LIGHT_PATH) as GameSkin


static func root() -> Window:
	return (Engine.get_main_loop() as SceneTree).root


## The lesson file names in src/lessons/data/, sorted.
static func data_file_names() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for file_name: String in DirAccess.get_files_at(LessonLibrary.DATA_DIR):
		if file_name.ends_with(".json"):
			out.append(file_name)
	out.sort()
	return out


static func read(file_name: String) -> String:
	return FileAccess.get_file_as_string(LessonLibrary.DATA_DIR + file_name)


static func lesson(number: int) -> Lesson:
	for item: Lesson in LessonLibrary.load_all():
		if item.number == number:
			return item
	return null


## A small valid lesson as a Dictionary, for the loader tests to break.
## Two screens on lesson 2's board: tap r5c5, then cross out 9.
static func small_lesson() -> Dictionary:
	var board: String = "3..7...9...8..12...2...6..48.6.4..7..9...3....5.2..3.6..9.6..1.1....84...4.5.78.."
	return {
		"format": 1,
		"id": "lesson_07",
		"number": 7,
		"title": "Test lesson",
		"subtitle": "For the tests",
		"solution": "314752698968431257527896134836145972792683541451279386289364715175928463643517829",
		"screens": [
			{
				"board": board,
				"start": {"selected": null, "mode": "place"},
				"marked_cells": ["r5c5"],
				"marked_controls": [],
				"text": "Tap the marked cell.",
				"goal": {"order": "any", "steps": [{"action": "cell", "cell": "r5c5"}], "technique": ""},
				"praise": "Good.",
				"wrong": [
					{"match": {"action": "cell", "cells": ["r5c2"]}, "text": "That is the 9."},
					{"match": {"action": "cell", "cells": "other"}, "text": "Another cell."},
					{"match": {"action": "pad"}, "text": "Pick a cell first."},
				],
				"fallback": "Tap the marked cell.",
			},
			{
				"board": board,
				"start": {"selected": "r5c5", "mode": "cross_out", "placed": {}, "crossed": {"r5c5": [7]}},
				"marked_cells": [],
				"marked_controls": ["pad:9", "mode"],
				"text": "Cross out 9, then 3, then bring back 7.",
				"goal": {"order": "sequence", "steps": [
					{"action": "pad", "digit": 9}, {"action": "pad", "digit": 3}, {"action": "pad", "digit": 7},
				], "technique": ""},
				"next": {"start": "Cross out 9.", "after": {"pad:9": "Now cross out 3.", "pad:3": "Now bring back 7."}},
				"praise": "Done.",
				"wrong": [
					{"match": {"action": "pad", "digits": [7], "crossed": true}, "text": "{d} later. {next}"},
					{"match": {"action": "pad", "crossed": true}, "text": "{d} has an X. {next}"},
					{"match": {"action": "pad"}, "text": "Not {d}. {next}"},
				],
				"fallback": "{next}",
			},
		],
	}
