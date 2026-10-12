class_name UndoStep
extends RefCounted
## One undo step (GDD 7.1): the digit change and every candidate the action
## changed, Auto Cross changes included (GDD 5.4).
##
## Cross and restore steps keep old_digit and new_digit at 0 (the cell is
## empty) and hold exactly one mark change, the player's own.
##
## Once GameSession records a step, nothing changes it again. Undo only
## reads and pops it, and GameSession.snapshot_to_dict() relies on this to
## read steps on a worker thread. Keep it that way.

const DataCheck := preload("res://src/core/data_check.gd")

enum Kind { PLACE, REPLACE, ERASE, CROSS, RESTORE }

var kind: int = Kind.PLACE
var cell: int = -1
var old_digit: int = 0
var new_digit: int = 0
## Triples: mark index, old Mark, new Mark.
var mark_changes: PackedInt32Array = PackedInt32Array()


## Short keys keep a long history small on disk (ARCHITECTURE.md section 12).
func to_dict() -> Dictionary:
	return {
		"k": kind,
		"c": cell,
		"o": old_digit,
		"n": new_digit,
		"m": Array(mark_changes),
	}


## Null unless the step is one a session could have made: a known kind, a
## cell 0 to 80, digits that fit the kind, and mark changes that fit it too.
## Placing, replacing and erasing carry only Auto Cross changes (OPEN to
## CROSSED_AUTO or back). Crossing and restoring carry one change in the
## step's own cell: OPEN or RESTORED_HAND to CROSSED_HAND for a cross,
## CROSSED_HAND or CROSSED_AUTO to RESTORED_HAND for a restore.
static func from_dict(data: Variant) -> UndoStep:
	if typeof(data) != TYPE_DICTIONARY:
		return null
	var dict: Dictionary = data
	var k: Variant = dict.get("k")
	var c: Variant = dict.get("c")
	var o: Variant = dict.get("o")
	var n: Variant = dict.get("n")
	if not DataCheck.int_in(k, 0, Kind.RESTORE) or not DataCheck.int_in(c, 0, Sudoku.CELLS - 1):
		return null
	if not DataCheck.int_in(o, 0, 9) or not DataCheck.int_in(n, 0, 9):
		return null
	var changes_value: Variant = DataCheck.int_list(dict.get("m"), 0, Board.MARK_COUNT - 1, Board.MARK_COUNT * 3)
	if changes_value == null:
		return null
	var step: UndoStep = UndoStep.new()
	step.kind = int(k)
	step.cell = int(c)
	step.old_digit = int(o)
	step.new_digit = int(n)
	step.mark_changes = changes_value
	if not step._is_consistent():
		return null
	return step


func _is_consistent() -> bool:
	match kind:
		Kind.PLACE:
			if old_digit != 0 or new_digit == 0:
				return false
		Kind.REPLACE:
			if old_digit == 0 or new_digit == 0 or old_digit == new_digit:
				return false
		Kind.ERASE:
			if old_digit == 0 or new_digit != 0:
				return false
		_:
			if old_digit != 0 or new_digit != 0 or mark_changes.size() != 3:
				return false
	if mark_changes.size() % 3 != 0:
		return false
	for i: int in range(0, mark_changes.size(), 3):
		var before: int = mark_changes[i + 1]
		var after: int = mark_changes[i + 2]
		if before > Board.Mark.CROSSED_AUTO or after > Board.Mark.CROSSED_AUTO:
			return false
		match kind:
			Kind.CROSS:
				if mark_changes[i] / 9 != cell or after != Board.Mark.CROSSED_HAND:
					return false
				if before != Board.Mark.OPEN and before != Board.Mark.RESTORED_HAND:
					return false
			Kind.RESTORE:
				if mark_changes[i] / 9 != cell or after != Board.Mark.RESTORED_HAND:
					return false
				if before != Board.Mark.CROSSED_HAND and before != Board.Mark.CROSSED_AUTO:
					return false
			_:
				var to_auto: bool = before == Board.Mark.OPEN and after == Board.Mark.CROSSED_AUTO
				var to_open: bool = before == Board.Mark.CROSSED_AUTO and after == Board.Mark.OPEN
				if not to_auto and not to_open:
					return false
	return true
