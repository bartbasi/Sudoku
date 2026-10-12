class_name Sudoku
extends RefCounted
## Static helpers for cells, groups and grids.
##
## Cells are 0 to 80, cell = row * 9 + col. Groups are 0 to 8 boxes, 9 to 17
## rows, 18 to 26 columns (the GDD 11.1 search order). The lookup tables are
## built once when the script loads and never written again, so every helper
## is safe on any thread. Public helpers return copies of the tables.

const CELLS := 81
const GROUPS := 27

static var _peers: Array[PackedInt32Array] = _build_peers()
static var _groups: Array[PackedInt32Array] = _build_groups()


static func row(cell: int) -> int:
	return cell / 9


static func col(cell: int) -> int:
	return cell % 9


static func box(cell: int) -> int:
	return (cell / 27) * 3 + (cell % 9) / 3


static func cell_at(row_index: int, col_index: int) -> int:
	return row_index * 9 + col_index


static func is_cell(cell: int) -> bool:
	return cell >= 0 and cell < CELLS


## The 20 peers of a cell, ascending. Empty for a cell outside 0 to 80.
static func peers(cell: int) -> PackedInt32Array:
	if not is_cell(cell):
		return PackedInt32Array()
	return _peers[cell].duplicate()


## The 9 cells of a group, in reading order. Empty for a group outside 0 to 26.
static func group_cells(group: int) -> PackedInt32Array:
	if group < 0 or group >= GROUPS:
		return PackedInt32Array()
	return _groups[group].duplicate()


## 81 values, each 0 to 9.
static func is_grid(grid: PackedInt32Array) -> bool:
	if grid.size() != CELLS:
		return false
	for value: int in grid:
		if value < 0 or value > 9:
			return false
	return true


## 81 digits 1 to 9 with every digit once in every row, column and box.
static func is_complete_solution(grid: PackedInt32Array) -> bool:
	if not is_grid(grid):
		return false
	for group: int in GROUPS:
		var seen: int = 0
		for cell: int in _groups[group]:
			var value: int = grid[cell]
			if value == 0:
				return false
			seen |= 1 << value
		if seen != 0b1111111110:
			return false
	return true


static func _build_peers() -> Array[PackedInt32Array]:
	var out: Array[PackedInt32Array] = []
	for cell: int in CELLS:
		var list: PackedInt32Array = PackedInt32Array()
		for other: int in CELLS:
			if other == cell:
				continue
			if row(other) == row(cell) or col(other) == col(cell) or box(other) == box(cell):
				list.append(other)
		out.append(list)
	return out


static func _build_groups() -> Array[PackedInt32Array]:
	var out: Array[PackedInt32Array] = []
	for group: int in GROUPS:
		var list: PackedInt32Array = PackedInt32Array()
		for cell: int in CELLS:
			var inside: bool = false
			if group < 9:
				inside = box(cell) == group
			elif group < 18:
				inside = row(cell) == group - 9
			else:
				inside = col(cell) == group - 18
			if inside:
				list.append(cell)
		out.append(list)
	return out
