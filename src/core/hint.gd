class_name Hint
extends RefCounted
## One hint, as data (GDD 10). The puzzles area fills it; the session only
## stores it and shows it.

const DataCheck := preload("res://src/core/data_check.gd")

## Every technique id a hint may carry (ARCHITECTURE.md section 2).
const TECHNIQUE_IDS: PackedStringArray = [
	"last_empty_cell", "hidden_single", "naked_single", "pointing", "claiming",
	"naked_pair", "hidden_pair", "naked_triple", "hidden_triple", "x_wing",
	"y_wing", "swordfish", "xyz_wing", "wrong_digit", "fallback",
]
const MAX_TEXT_LENGTH := 1000

var technique: StringName = &""
var technique_name: String = ""
var text: String = ""
var lesson_title: String = ""
var targets: PackedInt32Array = PackedInt32Array()
var reasons: PackedInt32Array = PackedInt32Array()
var placement_cell: int = -1
var placement_digit: int = 0
var eliminations: PackedInt32Array = PackedInt32Array()


func to_dict() -> Dictionary:
	return {
		"technique": String(technique),
		"technique_name": technique_name,
		"text": text,
		"lesson_title": lesson_title,
		"targets": Array(targets),
		"reasons": Array(reasons),
		"placement_cell": placement_cell,
		"placement_digit": placement_digit,
		"eliminations": Array(eliminations),
	}


## Null unless every field is present and valid: a known technique id,
## texts of at most MAX_TEXT_LENGTH characters, cells 0 to 80, mark indices
## 0 to 728, and a placement that is either none (-1 and 0) or a cell and a
## digit 1 to 9.
static func from_dict(data: Variant) -> Hint:
	if typeof(data) != TYPE_DICTIONARY:
		return null
	var dict: Dictionary = data
	var tech: Variant = dict.get("technique")
	if typeof(tech) != TYPE_STRING or not TECHNIQUE_IDS.has(String(tech)):
		return null
	for key: String in ["technique_name", "text", "lesson_title"]:
		if not DataCheck.is_text(dict.get(key), MAX_TEXT_LENGTH):
			return null
	var new_targets: Variant = DataCheck.int_list(dict.get("targets"), 0, Sudoku.CELLS - 1, Sudoku.CELLS)
	var new_reasons: Variant = DataCheck.int_list(dict.get("reasons"), 0, Sudoku.CELLS - 1, Sudoku.CELLS)
	var new_eliminations: Variant = DataCheck.int_list(dict.get("eliminations"), 0, Board.MARK_COUNT - 1, Board.MARK_COUNT)
	if new_targets == null or new_reasons == null or new_eliminations == null:
		return null
	var cell: Variant = dict.get("placement_cell")
	var digit: Variant = dict.get("placement_digit")
	if not DataCheck.int_in(cell, -1, Sudoku.CELLS - 1) or not DataCheck.int_in(digit, 0, 9):
		return null
	if (int(cell) == -1) != (int(digit) == 0):
		return null
	var hint: Hint = Hint.new()
	hint.technique = StringName(String(tech))
	hint.technique_name = dict["technique_name"]
	hint.text = dict["text"]
	hint.lesson_title = dict["lesson_title"]
	hint.targets = new_targets
	hint.reasons = new_reasons
	hint.placement_cell = int(cell)
	hint.placement_digit = int(digit)
	hint.eliminations = new_eliminations
	return hint
