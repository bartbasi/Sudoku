class_name Solver
extends RefCounted
## Backtracking solver that counts solutions, used to prove a puzzle has
## exactly one. It always picks the empty cell with the fewest candidates and
## tries digits from 1 to 9, so its results are the same on every run.
##
## A grid is a PackedInt32Array of 81 ints, index = row * 9 + col, 0 for an
## empty cell. Anything else (wrong size, a value outside 0 to 9, or the same
## digit twice in a row, column or box) has no solutions.

const Tables := preload("res://src/puzzles/grid_tables.gd")

var _cells: PackedInt32Array = PackedInt32Array()
## Digits used in each row, column and box, as masks.
var _row_used: PackedInt32Array = PackedInt32Array()
var _col_used: PackedInt32Array = PackedInt32Array()
var _box_used: PackedInt32Array = PackedInt32Array()
## The cells empty in the input. Filled ones are skipped while searching.
var _empties: PackedInt32Array = PackedInt32Array()
var _limit: int = 1
var _count: int = 0
var _first: PackedInt32Array = PackedInt32Array()


## Counts solutions, stopping at limit. limit 2 answers "exactly one?".
## A limit below 1 counts as 1.
static func count_solutions(grid: PackedInt32Array, limit: int = 2) -> int:
	var solver: Solver = Solver.new()
	if not solver._load(grid):
		return 0
	solver._limit = maxi(limit, 1)
	solver._search()
	return solver._count


## The first solution in the solver's fixed search order, or an empty array
## if there is none. Check count_solutions() first if uniqueness matters.
static func solve(grid: PackedInt32Array) -> PackedInt32Array:
	var solver: Solver = Solver.new()
	if not solver._load(grid):
		return PackedInt32Array()
	solver._limit = 1
	solver._search()
	return solver._first


func _load(grid: PackedInt32Array) -> bool:
	if grid.size() != Tables.CELL_COUNT:
		return false
	_cells = grid.duplicate()
	_row_used.resize(9)
	_col_used.resize(9)
	_box_used.resize(9)
	_row_used.fill(0)
	_col_used.fill(0)
	_box_used.fill(0)
	_empties.clear()
	for i: int in Tables.CELL_COUNT:
		var digit: int = _cells[i]
		if digit == 0:
			_empties.append(i)
			continue
		if digit < 0 or digit > 9:
			return false
		var bit: int = 1 << (digit - 1)
		var r: int = Tables.ROW_OF[i]
		var c: int = Tables.COL_OF[i]
		var b: int = Tables.BOX_OF[i]
		if (_row_used[r] | _col_used[c] | _box_used[b]) & bit:
			return false
		_row_used[r] |= bit
		_col_used[c] |= bit
		_box_used[b] |= bit
	return true


func _search() -> void:
	var cells: PackedInt32Array = _cells
	var row_used: PackedInt32Array = _row_used
	var col_used: PackedInt32Array = _col_used
	var box_used: PackedInt32Array = _box_used
	var row_of: PackedInt32Array = Tables.ROW_OF
	var col_of: PackedInt32Array = Tables.COL_OF
	var box_of: PackedInt32Array = Tables.BOX_OF
	var popcount: PackedInt32Array = Tables.POPCOUNT

	# The empty cell with the fewest candidates.
	var best: int = -1
	var best_mask: int = 0
	var best_count: int = 10
	for i: int in _empties:
		if cells[i] != 0:
			continue
		var mask: int = Tables.ALL_DIGITS & ~(row_used[row_of[i]] | col_used[col_of[i]] | box_used[box_of[i]])
		var count: int = popcount[mask]
		if count < best_count:
			best = i
			best_mask = mask
			best_count = count
			if count <= 1:
				break
	if best == -1:
		_count += 1
		if _count == 1:
			_first = cells.duplicate()
		return
	if best_count == 0:
		return

	var r: int = row_of[best]
	var c: int = col_of[best]
	var b: int = box_of[best]
	var mask: int = best_mask
	while mask != 0:
		var bit: int = mask & -mask
		mask ^= bit
		cells[best] = Tables.LOWEST_DIGIT[bit]
		row_used[r] |= bit
		col_used[c] |= bit
		box_used[b] |= bit
		_search()
		row_used[r] &= ~bit
		col_used[c] &= ~bit
		box_used[b] &= ~bit
		cells[best] = 0
		if _count >= _limit:
			return
