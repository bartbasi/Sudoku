class_name LessonLibrary
extends RefCounted
## Loads the lesson files in src/lessons/data/ (docs/ARCHITECTURE.md
## section 10). The files are treated as untrusted input: they are read with
## FileAccess, parsed with the JSON class, and checked field by field against
## the format. Nothing in them can create an object or run code; a file with
## any unknown key, wrong type, value out of range or digit that disagrees
## with its solution is rejected as a whole.
## Owner: lessons-dev.

const DATA_DIR: String = "res://src/lessons/data/"
const FORMAT: int = 1
## The largest lesson file read, in bytes. The v1 files are about 12 KiB.
const MAX_FILE_BYTES: int = 262144
## Limits on sizes, so a damaged file cannot ask for huge work.
const MAX_TEXT: int = 1000
const MAX_TITLE: int = 100
const MAX_SCREENS: int = 50
const MAX_STEPS: int = 20
const MAX_WRONG: int = 50
const MAX_NUMBER: int = 99
## Techniques a lesson step may name (GDD 11.3: the ones that place a digit).
const TECHNIQUES: Array[StringName] = [&"last_empty_cell", &"hidden_single", &"naked_single"]
const CONTROLS: Array[String] = [
	"mode", "erase", "undo", "pad",
	"pad:1", "pad:2", "pad:3", "pad:4", "pad:5", "pad:6", "pad:7", "pad:8", "pad:9",
]

const LESSON_KEYS: Array[String] = ["format", "id", "number", "title", "subtitle", "solution", "screens"]
const SCREEN_KEYS: Array[String] = ["board", "start", "marked_cells", "marked_controls", "text", "goal", "next", "praise", "wrong", "fallback"]
const SCREEN_REQUIRED: Array[String] = ["board", "start", "text", "goal", "praise", "fallback"]
const START_KEYS: Array[String] = ["selected", "mode", "placed", "crossed"]
const GOAL_KEYS: Array[String] = ["order", "steps", "technique"]
const NEXT_KEYS: Array[String] = ["start", "after"]
const WRONG_KEYS: Array[String] = ["match", "text"]
const MATCH_KEYS: Array[String] = ["action", "digits", "cells", "crossed"]


## Every valid lesson file in DATA_DIR (named lesson_NN.json), sorted by
## number. An invalid file, or a second file with the same number, is
## skipped with push_error.
static func load_all() -> Array[Lesson]:
	var out: Array[Lesson] = []
	var names: PackedStringArray = DirAccess.get_files_at(DATA_DIR)
	var seen: Dictionary[int, bool] = {}
	for file_name: String in names:
		if not _is_lesson_file_name(file_name):
			continue
		var path: String = DATA_DIR + file_name
		var text: Variant = _read_text(path)
		if text == null:
			push_error("Lessons: could not read %s" % path)
			continue
		var reason: String = check(text as String)
		if not reason.is_empty():
			push_error("Lessons: %s is invalid: %s" % [path, reason])
			continue
		var lesson: Lesson = parse(text as String)
		if seen.has(lesson.number):
			push_error("Lessons: %s repeats lesson number %d" % [path, lesson.number])
			continue
		seen[lesson.number] = true
		out.append(lesson)
	out.sort_custom(func(a: Lesson, b: Lesson) -> bool: return a.number < b.number)
	return out


## The lesson in json_text, or null if anything in it is invalid.
static func parse(json_text: String) -> Lesson:
	var parser: Parser = Parser.new()
	return parser.lesson(json_text)


## "" when json_text is a valid lesson, otherwise the first problem found.
## For error messages and the tests.
static func check(json_text: String) -> String:
	var parser: Parser = Parser.new()
	if parser.lesson(json_text) != null:
		return ""
	return parser.error


## The cell for a 1-based "rXcY" name, or -1 if it is not one.
static func cell_from_name(cell_name: String) -> int:
	if cell_name.length() != 4 or cell_name[0] != "r" or cell_name[2] != "c":
		return -1
	var row_char: String = cell_name[1]
	var col_char: String = cell_name[3]
	if row_char < "1" or row_char > "9" or col_char < "1" or col_char > "9":
		return -1
	return Sudoku.cell_at(row_char.to_int() - 1, col_char.to_int() - 1)


## "rXcY" for a cell 0 to 80, "" otherwise.
static func cell_name(cell: int) -> String:
	if not Sudoku.is_cell(cell):
		return ""
	return "r%dc%d" % [Sudoku.row(cell) + 1, Sudoku.col(cell) + 1]


static func _is_lesson_file_name(file_name: String) -> bool:
	if file_name.length() != 14 or not file_name.begins_with("lesson_") or not file_name.ends_with(".json"):
		return false
	var digits: String = file_name.substr(7, 2)
	return digits[0] >= "0" and digits[0] <= "9" and digits[1] >= "0" and digits[1] <= "9"


## The file's text, or null when it is missing or larger than MAX_FILE_BYTES.
static func _read_text(path: String) -> Variant:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	if file.get_length() > MAX_FILE_BYTES:
		return null
	var text: String = file.get_as_text()
	file.close()
	return text


## Checks one file's data and builds the lesson. Holds the first error.
class Parser extends RefCounted:
	var error: String = ""

	func lesson(json_text: String) -> Lesson:
		error = ""
		if json_text.length() > MAX_FILE_BYTES:
			return _fail("the text is too long")
		var json: JSON = JSON.new()
		if json.parse(json_text) != OK:
			return _fail("not JSON: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		var data: Variant = json.data
		if not _is_dict(data, "the file", LESSON_KEYS, LESSON_KEYS):
			return null
		var root: Dictionary = data as Dictionary
		if _int(root["format"], 1, 1, "format") < 0:
			return null
		var out: Lesson = Lesson.new()
		out.number = _int(root["number"], 1, MAX_NUMBER, "number")
		if out.number < 0:
			return null
		out.id = _text(root["id"], MAX_TITLE, "id")
		if out.id.is_empty():
			return null
		if out.id != "lesson_%02d" % out.number:
			return _fail("id %s does not match number %d" % [out.id, out.number])
		out.title = _text(root["title"], MAX_TITLE, "title")
		out.subtitle = _text(root["subtitle"], MAX_TITLE, "subtitle")
		if out.title.is_empty() or out.subtitle.is_empty():
			return null
		out.solution = _grid(root["solution"], false, "solution")
		if out.solution.is_empty():
			return null
		if not Sudoku.is_complete_solution(out.solution):
			return _fail("solution is not a complete valid grid")
		var screens: Variant = root["screens"]
		if not _is_array(screens, 1, MAX_SCREENS, "screens"):
			return null
		var index: int = 0
		for item: Variant in screens as Array:
			index += 1
			var screen: LessonScreen = _screen(item, out.solution, "screen %d" % index)
			if screen == null:
				return null
			out.screens.append(screen)
		return out

	func _screen(data: Variant, solution: PackedInt32Array, where: String) -> LessonScreen:
		if not _is_dict(data, where, SCREEN_KEYS, SCREEN_REQUIRED):
			return null
		var raw: Dictionary = data as Dictionary
		var screen: LessonScreen = LessonScreen.new()
		screen.givens = _grid(raw["board"], true, where + " board")
		if screen.givens.is_empty():
			return null
		for cell: int in Sudoku.CELLS:
			if screen.givens[cell] != 0 and screen.givens[cell] != solution[cell]:
				return _fail_screen("%s board: %s is %d but the solution has %d" % [where, LessonLibrary.cell_name(cell), screen.givens[cell], solution[cell]])
		if not _start(raw["start"], screen, solution, where + " start"):
			return null
		screen.marked_cells = _cells(raw.get("marked_cells", []), where + " marked_cells")
		if error != "":
			return null
		var controls: Variant = raw.get("marked_controls", [])
		if not _is_array(controls, 0, CONTROLS.size(), where + " marked_controls"):
			return null
		for item: Variant in controls as Array:
			if typeof(item) != TYPE_STRING or not CONTROLS.has(item as String):
				return _fail_screen("%s marked_controls: unknown control %s" % [where, str(item)])
			var control: StringName = StringName(item as String)
			if not screen.marked_controls.has(control):
				screen.marked_controls.append(control)
		screen.text = _text(raw["text"], MAX_TEXT, where + " text")
		screen.praise = _text(raw["praise"], MAX_TEXT, where + " praise")
		screen.fallback = _text(raw["fallback"], MAX_TEXT, where + " fallback")
		if screen.text.is_empty() or screen.praise.is_empty() or screen.fallback.is_empty():
			return null
		if not _goal(raw["goal"], screen, where + " goal"):
			return null
		if raw.has("next") and not _next(raw["next"], screen, where + " next"):
			return null
		if not _wrong(raw.get("wrong", []), screen, where + " wrong"):
			return null
		return screen

	func _start(data: Variant, screen: LessonScreen, solution: PackedInt32Array, where: String) -> bool:
		if not _is_dict(data, where, START_KEYS, ["mode"]):
			return false
		var raw: Dictionary = data as Dictionary
		match raw["mode"]:
			"place":
				screen.mode = GameSession.Mode.PLACE
			"cross_out":
				screen.mode = GameSession.Mode.CROSS_OUT
			_:
				return _fail_bool("%s mode must be place or cross_out" % where)
		var selected: Variant = raw.get("selected", null)
		if selected == null:
			screen.selected = -1
		else:
			screen.selected = _cell(selected, where + " selected")
			if screen.selected < 0:
				return false
		screen.placed.resize(Sudoku.CELLS)
		screen.placed.fill(0)
		var placed: Variant = raw.get("placed", {})
		if typeof(placed) != TYPE_DICTIONARY:
			return _fail_bool("%s placed must be an object" % where)
		for key: Variant in (placed as Dictionary).keys():
			var cell: int = _cell(key, where + " placed")
			if cell < 0:
				return false
			var d: int = _int((placed as Dictionary)[key], 1, 9, "%s placed %s" % [where, str(key)])
			if d < 0:
				return false
			if screen.givens[cell] != 0:
				return _fail_bool("%s placed: %s holds a given digit" % [where, str(key)])
			if d != solution[cell]:
				return _fail_bool("%s placed: %s is %d but the solution has %d" % [where, str(key), d, solution[cell]])
			screen.placed[cell] = d
		var crossed: Variant = raw.get("crossed", {})
		if typeof(crossed) != TYPE_DICTIONARY:
			return _fail_bool("%s crossed must be an object" % where)
		for key: Variant in (crossed as Dictionary).keys():
			var cell: int = _cell(key, where + " crossed")
			if cell < 0:
				return false
			if screen.givens[cell] != 0 or screen.placed[cell] != 0:
				return _fail_bool("%s crossed: %s is not empty" % [where, str(key)])
			var list: Variant = (crossed as Dictionary)[key]
			if not _is_array(list, 1, 9, "%s crossed %s" % [where, str(key)]):
				return false
			for item: Variant in list as Array:
				var d: int = _int(item, 1, 9, "%s crossed %s" % [where, str(key)])
				if d < 0:
					return false
				var index: int = cell * 9 + d - 1
				if not screen.crossed.has(index):
					screen.crossed.append(index)
		return true

	func _goal(data: Variant, screen: LessonScreen, where: String) -> bool:
		if not _is_dict(data, where, GOAL_KEYS, ["order", "steps"]):
			return false
		var raw: Dictionary = data as Dictionary
		match raw["order"]:
			"any":
				screen.in_sequence = false
			"sequence":
				screen.in_sequence = true
			_:
				return _fail_bool("%s order must be any or sequence" % where)
		var steps: Variant = raw["steps"]
		if not _is_array(steps, 1, MAX_STEPS, where + " steps"):
			return false
		for item: Variant in steps as Array:
			var step: BoardAction = _step(item, where + " step")
			if step == null:
				return false
			screen.steps.append(step)
		var technique: Variant = raw.get("technique", "")
		if typeof(technique) != TYPE_STRING:
			return _fail_bool("%s technique must be a string" % where)
		if (technique as String).is_empty():
			screen.technique = &""
		elif TECHNIQUES.has(StringName(technique as String)):
			screen.technique = StringName(technique as String)
		else:
			return _fail_bool("%s technique %s is not one that places a digit" % [where, technique])
		return true

	func _step(data: Variant, where: String) -> BoardAction:
		if typeof(data) != TYPE_DICTIONARY:
			return _fail_action("%s must be an object" % where)
		var raw: Dictionary = data as Dictionary
		var kind: int = _kind(raw.get("action", null), where)
		if kind < 0:
			return null
		var allowed: Array[String] = ["action"]
		if kind == BoardAction.Kind.CELL:
			allowed.append("cell")
		elif kind == BoardAction.Kind.PAD:
			allowed.append("digit")
		if not _is_dict(data, where, allowed, allowed):
			return null
		var step: BoardAction = BoardAction.create(kind)
		if kind == BoardAction.Kind.CELL:
			step.cell = _cell(raw["cell"], where)
			if step.cell < 0:
				return null
		elif kind == BoardAction.Kind.PAD:
			step.digit = _int(raw["digit"], 1, 9, where + " digit")
			if step.digit < 0:
				return null
		return step

	func _next(data: Variant, screen: LessonScreen, where: String) -> bool:
		if not _is_dict(data, where, NEXT_KEYS, ["start"]):
			return false
		var raw: Dictionary = data as Dictionary
		screen.has_next = true
		screen.next_start = _text(raw["start"], MAX_TEXT, where + " start")
		if screen.next_start.is_empty():
			return false
		var after: Variant = raw.get("after", {})
		if typeof(after) != TYPE_DICTIONARY:
			return _fail_bool("%s after must be an object" % where)
		if (after as Dictionary).size() > MAX_STEPS:
			return _fail_bool("%s after has too many entries" % where)
		for key: Variant in (after as Dictionary).keys():
			var step_key: String = _after_key(key, where)
			if step_key.is_empty():
				return false
			var value: String = _text((after as Dictionary)[key], MAX_TEXT, "%s after %s" % [where, str(key)])
			if value.is_empty():
				return false
			screen.next_after[step_key] = value
		return true

	## "pad:<d>", "cell:rXcY", "mode", "erase" or "undo", as a step key
	## with the cell converted (LessonScreen.step_key). "" if invalid.
	func _after_key(key: Variant, where: String) -> String:
		if typeof(key) != TYPE_STRING:
			return _fail_text("%s: a key is not a string" % where)
		var text: String = key as String
		if text == "mode" or text == "erase" or text == "undo":
			return text
		if text.length() == 5 and text.begins_with("pad:") and text[4] >= "1" and text[4] <= "9":
			return text
		if text.begins_with("cell:"):
			var cell: int = LessonLibrary.cell_from_name(text.substr(5))
			if cell >= 0:
				return "cell:%d" % cell
		return _fail_text("%s: unknown key %s" % [where, text])

	func _wrong(data: Variant, screen: LessonScreen, where: String) -> bool:
		if not _is_array(data, 0, MAX_WRONG, where):
			return false
		var named: PackedInt32Array = PackedInt32Array()
		for step: BoardAction in screen.steps:
			if step.kind == BoardAction.Kind.CELL and not named.has(step.cell):
				named.append(step.cell)
		var index: int = 0
		for item: Variant in data as Array:
			index += 1
			var at: String = "%s %d" % [where, index]
			if not _is_dict(item, at, WRONG_KEYS, WRONG_KEYS):
				return false
			var rule: LessonScreen.WrongTap = _match((item as Dictionary)["match"], named, at + " match")
			if rule == null:
				return false
			rule.text = _text((item as Dictionary)["text"], MAX_TEXT, at + " text")
			if rule.text.is_empty():
				return false
			for cell: int in rule.cells:
				if not named.has(cell):
					named.append(cell)
			screen.wrong.append(rule)
		return true

	func _match(data: Variant, named: PackedInt32Array, where: String) -> LessonScreen.WrongTap:
		if typeof(data) != TYPE_DICTIONARY:
			return _fail_rule("%s must be an object" % where)
		var raw: Dictionary = data as Dictionary
		var rule: LessonScreen.WrongTap = LessonScreen.WrongTap.new()
		rule.kind = _kind(raw.get("action", null), where)
		if rule.kind < 0:
			return null
		var allowed: Array[String] = ["action"]
		if rule.kind == BoardAction.Kind.PAD:
			allowed.append_array(["digits", "crossed"])
		elif rule.kind == BoardAction.Kind.CELL:
			allowed.append("cells")
		if not _is_dict(data, where, allowed, ["action"]):
			return null
		if raw.has("digits"):
			var digits: Variant = raw["digits"]
			if not _is_array(digits, 1, 9, where + " digits"):
				return null
			for item: Variant in digits as Array:
				var d: int = _int(item, 1, 9, where + " digits")
				if d < 0:
					return null
				if not rule.digits.has(d):
					rule.digits.append(d)
		if raw.has("crossed"):
			if typeof(raw["crossed"]) != TYPE_BOOL:
				return _fail_rule("%s crossed must be true or false" % where)
			rule.crossed = 1 if bool(raw["crossed"]) else 0
		if raw.has("cells"):
			var cells: Variant = raw["cells"]
			if typeof(cells) == TYPE_STRING and cells == "other":
				rule.other = true
				rule.excluded = named.duplicate()
			else:
				rule.cells = _cells(cells, where + " cells")
				if error != "":
					return null
				if rule.cells.is_empty():
					return _fail_rule("%s cells is empty" % where)
		return rule

	# Field helpers. Each records the first error and returns a value that
	# tells the caller it failed (-1, "", an empty array or null).

	func _is_dict(data: Variant, where: String, allowed: Array[String], required: Array[String]) -> bool:
		if typeof(data) != TYPE_DICTIONARY:
			return _fail_bool("%s must be an object" % where)
		for key: Variant in (data as Dictionary).keys():
			if typeof(key) != TYPE_STRING or not allowed.has(key as String):
				return _fail_bool("%s has an unknown key %s" % [where, str(key)])
		for key: String in required:
			if not (data as Dictionary).has(key):
				return _fail_bool("%s is missing %s" % [where, key])
		return true

	func _is_array(data: Variant, min_size: int, max_size: int, where: String) -> bool:
		if typeof(data) != TYPE_ARRAY:
			return _fail_bool("%s must be a list" % where)
		var count: int = (data as Array).size()
		if count < min_size or count > max_size:
			return _fail_bool("%s must have %d to %d entries" % [where, min_size, max_size])
		return true

	## A whole number from min_value to max_value, or -1. JSON numbers come
	## in as floats, so a float with no fraction counts.
	func _int(data: Variant, min_value: int, max_value: int, where: String) -> int:
		var value: int = 0
		if typeof(data) == TYPE_INT:
			value = data as int
		elif typeof(data) == TYPE_FLOAT and is_finite(data as float) and (data as float) == floorf(data as float) \
				and absf(data as float) <= 1.0e6:
			value = int(data as float)
		else:
			return _fail_int("%s must be a whole number" % where)
		if value < min_value or value > max_value:
			return _fail_int("%s must be %d to %d" % [where, min_value, max_value])
		return value

	## A non-empty string of at most max_length characters, or "".
	func _text(data: Variant, max_length: int, where: String) -> String:
		if typeof(data) != TYPE_STRING:
			return _fail_text("%s must be a string" % where)
		var text: String = data as String
		if text.strip_edges().is_empty():
			return _fail_text("%s is empty" % where)
		if text.length() > max_length:
			return _fail_text("%s is longer than %d characters" % [where, max_length])
		return text

	## 81 characters: digits 1 to 9, and "." for empty when dots is true.
	## Empty array if invalid.
	func _grid(data: Variant, dots: bool, where: String) -> PackedInt32Array:
		var out: PackedInt32Array = PackedInt32Array()
		if typeof(data) != TYPE_STRING or (data as String).length() != Sudoku.CELLS:
			_fail_text("%s must be 81 characters" % where)
			return out
		var text: String = data as String
		out.resize(Sudoku.CELLS)
		for i: int in Sudoku.CELLS:
			var ch: String = text[i]
			if ch >= "1" and ch <= "9":
				out[i] = ch.to_int()
			elif dots and ch == ".":
				out[i] = 0
			else:
				_fail_text("%s has %s at position %d" % [where, ch, i + 1])
				return PackedInt32Array()
		return out

	func _cell(data: Variant, where: String) -> int:
		if typeof(data) != TYPE_STRING:
			return _fail_int("%s: a cell must be a string like r5c5" % where)
		var cell: int = LessonLibrary.cell_from_name(data as String)
		if cell < 0:
			return _fail_int("%s: %s is not a cell" % [where, data])
		return cell

	## A list of cell names as cells, duplicates dropped. Sets error if invalid.
	func _cells(data: Variant, where: String) -> PackedInt32Array:
		var out: PackedInt32Array = PackedInt32Array()
		if not _is_array(data, 0, Sudoku.CELLS, where):
			return out
		for item: Variant in data as Array:
			var cell: int = _cell(item, where)
			if cell < 0:
				return PackedInt32Array()
			if not out.has(cell):
				out.append(cell)
		return out

	func _kind(data: Variant, where: String) -> int:
		match data:
			"cell":
				return BoardAction.Kind.CELL
			"pad":
				return BoardAction.Kind.PAD
			"mode":
				return BoardAction.Kind.MODE
			"erase":
				return BoardAction.Kind.ERASE
			"undo":
				return BoardAction.Kind.UNDO
		return _fail_int("%s: action must be cell, pad, mode, erase or undo" % where)

	func _fail(message: String) -> Lesson:
		_note(message)
		return null

	func _fail_screen(message: String) -> LessonScreen:
		_note(message)
		return null

	func _fail_bool(message: String) -> bool:
		_note(message)
		return false

	func _fail_int(message: String) -> int:
		_note(message)
		return -1

	func _fail_text(message: String) -> String:
		_note(message)
		return ""

	func _fail_action(message: String) -> BoardAction:
		_note(message)
		return null

	func _fail_rule(message: String) -> LessonScreen.WrongTap:
		_note(message)
		return null

	func _note(message: String) -> void:
		if error.is_empty():
			error = message
