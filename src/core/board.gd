class_name Board
extends RefCounted
## The digits on the board and the ring of every cell (GDD 2, 4 and 6).
## Holds no rules about undo or Auto Cross; GameSession owns those.
##
## marks has 729 entries, index = cell * 9 + digit - 1. Marks are kept for
## every non-given cell, also under a placed digit. A given's marks stay OPEN.

const DataCheck := preload("res://src/core/data_check.gd")

enum Mark { OPEN = 0, CROSSED_HAND = 1, RESTORED_HAND = 2, CROSSED_AUTO = 3 }

const MARK_COUNT := 729

var givens: PackedInt32Array = PackedInt32Array()
var digits: PackedInt32Array = PackedInt32Array()
var marks: PackedByteArray = PackedByteArray()


## A board with these givens, nothing placed and every candidate open.
## Returns null if givens is not 81 values from 0 to 9.
static func create(new_givens: PackedInt32Array) -> Board:
	if not Sudoku.is_grid(new_givens):
		return null
	var board: Board = Board.new()
	board.givens = new_givens.duplicate()
	board.digits = new_givens.duplicate()
	board.marks.resize(MARK_COUNT)
	board.marks.fill(Mark.OPEN)
	return board


func is_given(cell: int) -> bool:
	return Sudoku.is_cell(cell) and givens[cell] != 0


## The given or placed digit, 0 when empty or outside the board.
func digit(cell: int) -> int:
	if not Sudoku.is_cell(cell):
		return 0
	return digits[cell]


## The Mark of candidate d in a cell, OPEN for anything outside the board.
func mark(cell: int, d: int) -> int:
	if not Sudoku.is_cell(cell) or d < 1 or d > 9:
		return Mark.OPEN
	return marks[cell * 9 + d - 1]


## Crossed by hand or by Auto Cross.
func is_crossed(cell: int, d: int) -> bool:
	var value: int = mark(cell, d)
	return value == Mark.CROSSED_HAND or value == Mark.CROSSED_AUTO


## A peer holds d (GDD Terms). A cell never rules out its own candidates.
func is_ruled_out(cell: int, d: int) -> bool:
	if not Sudoku.is_cell(cell) or d < 1 or d > 9:
		return false
	for peer: int in Sudoku.peers(cell):
		if digits[peer] == d:
			return true
	return false


## Every cell, givens included, whose digit another cell in one of its
## groups also holds (GDD 6.1). Ascending.
func conflict_cells() -> PackedInt32Array:
	var flagged: PackedByteArray = PackedByteArray()
	flagged.resize(Sudoku.CELLS)
	flagged.fill(0)
	for group: int in Sudoku.GROUPS:
		var cells: PackedInt32Array = Sudoku.group_cells(group)
		var counts: PackedInt32Array = PackedInt32Array()
		counts.resize(10)
		counts.fill(0)
		for cell: int in cells:
			counts[digits[cell]] += 1
		for cell: int in cells:
			var value: int = digits[cell]
			if value != 0 and counts[value] > 1:
				flagged[cell] = 1
	var out: PackedInt32Array = PackedInt32Array()
	for cell: int in Sudoku.CELLS:
		if flagged[cell] == 1:
			out.append(cell)
	return out


func is_conflict(cell: int) -> bool:
	var value: int = digit(cell)
	if value == 0:
		return false
	for peer: int in Sudoku.peers(cell):
		if digits[peer] == value:
			return true
	return false


func is_full() -> bool:
	for value: int in digits:
		if value == 0:
			return false
	return true


## Full and no conflict.
func is_solved() -> bool:
	return Sudoku.is_complete_solution(digits)


func duplicate_board() -> Board:
	var copy: Board = Board.new()
	copy.givens = givens.duplicate()
	copy.digits = digits.duplicate()
	copy.marks = marks.duplicate()
	return copy


## Compact text: one character per cell or per mark.
func to_dict() -> Dictionary:
	return {
		"givens": DataCheck.ints_to_text(givens),
		"digits": DataCheck.ints_to_text(digits),
		"marks": DataCheck.bytes_to_text(marks),
	}


## Null unless every field is present and valid: 81 givens and digits, 729
## marks from 0 to 3, every given also in digits, and a given's marks all OPEN.
static func from_dict(data: Variant) -> Board:
	if typeof(data) != TYPE_DICTIONARY:
		return null
	var dict: Dictionary = data
	var new_givens: PackedInt32Array = DataCheck.text_to_ints(dict.get("givens"), Sudoku.CELLS, 9)
	var new_digits: PackedInt32Array = DataCheck.text_to_ints(dict.get("digits"), Sudoku.CELLS, 9)
	var new_marks: PackedInt32Array = DataCheck.text_to_ints(dict.get("marks"), MARK_COUNT, 3)
	if new_givens.is_empty() or new_digits.is_empty() or new_marks.is_empty():
		return null
	for cell: int in Sudoku.CELLS:
		if new_givens[cell] == 0:
			continue
		if new_digits[cell] != new_givens[cell]:
			return null
		for i: int in 9:
			if new_marks[cell * 9 + i] != Mark.OPEN:
				return null
	var board: Board = Board.new()
	board.givens = new_givens
	board.digits = new_digits
	board.marks.resize(MARK_COUNT)
	for i: int in MARK_COUNT:
		board.marks[i] = new_marks[i]
	return board
