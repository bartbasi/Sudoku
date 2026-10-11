class_name TechniqueSolver
extends RefCounted
## Solves a Sudoku step by step the way a person would, using only the 13
## techniques of docs/GDD.md 11.3, and grades it by the hardest one it needed.
##
## Rules (GDD 11.1): the solver keeps its own candidates. It tries the
## techniques in the order of TECHNIQUES, applies the first step it finds and
## starts again from the first technique. A step is one placement, or one
## pattern with every elimination it allows; an elimination step only counts
## if it removes at least one candidate. If it fills the board, the puzzle has
## exactly one solution and its level is the level that introduces the
## hardest technique used.
##
## Fixed search order inside each technique (GDD 11.1, refined here):
## - Groups are boxes 1 to 9, then rows 1 to 9, then columns 1 to 9. Cells in
##   a group are in reading order.
## - Last empty cell: groups in order.
## - Hidden single: groups in order, then digits 1 to 9.
## - Naked single: cells in reading order.
## - Pointing: boxes 1 to 9, then digits 1 to 9, the row case before the
##   column case.
## - Claiming: rows 1 to 9, then columns 1 to 9, then digits 1 to 9.
## - Naked pair and naked triple: groups in order, then cell combinations in
##   reading order (first cell, then second, then third).
## - Hidden pair and hidden triple: groups in order, then digit combinations
##   in ascending order.
## - X-Wing and Swordfish: digits 1 to 9; for each digit rows before columns;
##   then line combinations in ascending order.
## - Y-Wing and XYZ-Wing: pivot cells in reading order, then wing pairs in the
##   reading order of the pivot's peers.
##
## Use grade() for a whole puzzle. For one step at a time (hints), call
## load_givens() or load_state(), then find_step() and read the step. The
## generator's removal checks use solves(), a faster yes or no with the same
## techniques. Instances are not shared: create one per thread.

const Tables := preload("res://src/puzzles/grid_tables.gd")

## Technique ids, easiest first. This is the fixed search order.
const TECHNIQUES: Array[StringName] = [
	&"last_empty_cell", &"hidden_single", &"naked_single", &"pointing", &"claiming",
	&"naked_pair", &"hidden_pair", &"naked_triple", &"hidden_triple", &"x_wing",
	&"y_wing", &"swordfish", &"xyz_wing",
]
## The level that introduces each technique (GDD 11.2), same order.
const TECHNIQUE_LEVELS: PackedInt32Array = [0, 0, 1, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4]

const LAST_EMPTY_CELL: int = 0
const HIDDEN_SINGLE: int = 1
const NAKED_SINGLE: int = 2
const POINTING: int = 3
const CLAIMING: int = 4
const NAKED_PAIR: int = 5
const HIDDEN_PAIR: int = 6
const NAKED_TRIPLE: int = 7
const HIDDEN_TRIPLE: int = 8
const X_WING: int = 9
const Y_WING: int = 10
const SWORDFISH: int = 11
const XYZ_WING: int = 12

const NO_STEP: int = -1
const MAX_LEVEL: int = 4

## Board state: digits, and the solver's own candidates (0 for a filled cell).
var _cells: PackedInt32Array = PackedInt32Array()
var _cand: PackedInt32Array = PackedInt32Array()
## Empty cells left in each of the 27 groups, in Tables.UNITS order.
var _group_empty: PackedInt32Array = PackedInt32Array()
var _empty_count: int = 0
var _loaded: bool = false

## The step find_step() found and apply_step() applies.
var _step: int = NO_STEP
var _step_cell: int = -1
var _step_digit: int = 0
var _elim_cells: PackedInt32Array = PackedInt32Array()
var _elim_masks: PackedInt32Array = PackedInt32Array()
var _elim_count: int = 0

## Totals since the last load.
var _counts: PackedInt32Array = PackedInt32Array()
var _hardest: int = NO_STEP
var _steps: int = 0

## Scratch buffers, allocated once.
var _used: PackedInt32Array = PackedInt32Array()
var _list: PackedInt32Array = PackedInt32Array()
## Where each digit can go, computed once per search and shared by the
## techniques that need it. _group_pos[g * 9 + d] has bit k set if digit
## d + 1 is a candidate in the k-th cell of group g. _row_pos[d * 9 + r] has
## bit c set if it is a candidate in row r, column c; _col_pos[d * 9 + c]
## has bit r set for the same cell.
var _group_pos: PackedInt32Array = PackedInt32Array()
var _row_pos: PackedInt32Array = PackedInt32Array()
var _col_pos: PackedInt32Array = PackedInt32Array()
var _group_pos_ready: bool = false
var _line_pos_ready: bool = false


func _init() -> void:
	_cells.resize(Tables.CELL_COUNT)
	_cand.resize(Tables.CELL_COUNT)
	_group_empty.resize(27)
	_elim_cells.resize(Tables.CELL_COUNT)
	_elim_masks.resize(Tables.CELL_COUNT)
	_counts.resize(TECHNIQUES.size())
	_used.resize(27)
	_list.resize(9)
	_group_pos.resize(27 * 9)
	_row_pos.resize(Tables.CELL_COUNT)
	_col_pos.resize(Tables.CELL_COUNT)


## Grades a puzzle. Givens that are not a valid grid (wrong size, a value
## outside 0 to 9, or a digit twice in a group) give solved false, level -1.
static func grade(givens: PackedInt32Array) -> GradeResult:
	var solver: TechniqueSolver = TechniqueSolver.new()
	if not solver.load_givens(givens):
		return GradeResult.new()
	solver.run(MAX_LEVEL)
	return solver.result()


## The id of a technique index, for example &"x_wing".
static func technique_id(technique: int) -> StringName:
	if technique < 0 or technique >= TECHNIQUES.size():
		return &""
	return TECHNIQUES[technique]


## Loads a puzzle. Every empty cell starts with the digits its peers do not
## rule out. Returns false, and loads nothing, if givens is not a valid grid.
func load_givens(givens: PackedInt32Array) -> bool:
	return _load(givens, givens, false)


## Loads digits plus a candidate mask per cell (bit d - 1 for digit d). Each
## empty cell keeps only the candidates its peers do not rule out. Masks of
## filled cells are ignored. Returns false, and loads nothing, if the digits
## are not a valid grid or a mask is outside 0 to 511.
func load_state(cells: PackedInt32Array, candidates: PackedInt32Array) -> bool:
	if candidates.size() != Tables.CELL_COUNT:
		_loaded = false
		return false
	return _load(cells, candidates, true)


## Solves with the techniques of max_level and below, step by step, until the
## board is full or no step is found. Returns true if the board is full.
func run(max_level: int = MAX_LEVEL) -> bool:
	if not _loaded:
		return false
	while _empty_count > 0:
		if find_step(max_level) == NO_STEP:
			return false
		apply_step()
	return true


## For the generator: true if the techniques of max_level and below can fill
## the board. It uses the same techniques as run(), but places every single
## it sees in one sweep instead of restarting after each placement (about 1.2
## to 1.6 times faster on generator boards). Its path differs from run(), so
## its counts are not a grade, and in rare boards the order of steps could
## change the answer (it agreed with run() on all 3240 boards checked). The
## generator grades every puzzle it keeps with run().
func solves(max_level: int) -> bool:
	if not _loaded:
		return false
	while _empty_count > 0:
		if _sweep_singles(max_level):
			continue
		_clear_step()
		_step = _find_harder(max_level)
		if _step == NO_STEP:
			return false
		apply_step()
	return true


## Finds the next step with the techniques of max_level and below, in the
## fixed order, without applying it. Returns the technique index, or NO_STEP.
func find_step(max_level: int = MAX_LEVEL) -> int:
	_clear_step()
	if not _loaded or _empty_count == 0:
		return NO_STEP
	if _find_last_empty_cell():
		_step = LAST_EMPTY_CELL
	elif _find_hidden_single():
		_step = HIDDEN_SINGLE
	elif max_level >= 1 and _find_naked_single():
		_step = NAKED_SINGLE
	else:
		_step = _find_harder(max_level)
		if _step == NO_STEP:
			_clear_step()
	return _step


## Applies the step find_step() found, and counts it.
func apply_step() -> void:
	if _step == NO_STEP:
		return
	if _step_cell >= 0:
		_place(_step_cell, _step_digit)
	else:
		for k: int in _elim_count:
			_cand[_elim_cells[k]] &= ~_elim_masks[k]
	_counts[_step] += 1
	_steps += 1
	if _step > _hardest:
		_hardest = _step
	_clear_step()


## The technique of the step found, or NO_STEP.
func step_technique() -> int:
	return _step


## For a placement step: the cell (row * 9 + col). -1 for an elimination step.
func step_cell() -> int:
	return _step_cell


## For a placement step: the digit 1 to 9. 0 for an elimination step.
func step_digit() -> int:
	return _step_digit


## For an elimination step: pairs of cell and removed candidate mask, as
## [cell, mask, cell, mask, ...]. Empty for a placement step.
func step_eliminations() -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for k: int in _elim_count:
		out.append(_elim_cells[k])
		out.append(_elim_masks[k])
	return out


func is_solved() -> bool:
	return _loaded and _empty_count == 0


## The current digits (a copy).
func get_cells() -> PackedInt32Array:
	return _cells.duplicate()


## The current candidate masks (a copy), 0 for filled cells.
func get_candidates() -> PackedInt32Array:
	return _cand.duplicate()


## The grade of everything applied since the last load.
func result() -> GradeResult:
	var out: GradeResult = GradeResult.new()
	if not _loaded:
		return out
	out.solved = _empty_count == 0
	out.step_count = _steps
	if _hardest != NO_STEP:
		out.hardest = TECHNIQUES[_hardest]
	if out.solved:
		out.level = 0 if _hardest == NO_STEP else TECHNIQUE_LEVELS[_hardest]
	for t: int in TECHNIQUES.size():
		if _counts[t] > 0:
			out.technique_counts[TECHNIQUES[t]] = _counts[t]
	return out


## The number of steps made with a technique since the last load.
func technique_count(technique: int) -> int:
	return _counts[technique]


## The index of the hardest technique used since the last load, or NO_STEP.
func hardest_technique() -> int:
	return _hardest


func _load(cells: PackedInt32Array, candidates: PackedInt32Array, use_candidates: bool) -> bool:
	_loaded = false
	if cells.size() != Tables.CELL_COUNT:
		return false
	# Digits used per row (0 to 8), column (9 to 17) and box (18 to 26).
	var used: PackedInt32Array = _used
	used.fill(0)
	for i: int in Tables.CELL_COUNT:
		var digit: int = cells[i]
		if digit < 0 or digit > 9:
			return false
		if use_candidates and (candidates[i] < 0 or candidates[i] > Tables.ALL_DIGITS):
			return false
		if digit == 0:
			continue
		var bit: int = 1 << (digit - 1)
		var r: int = Tables.ROW_OF[i]
		var c: int = 9 + Tables.COL_OF[i]
		var b: int = 18 + Tables.BOX_OF[i]
		if (used[r] | used[c] | used[b]) & bit:
			return false
		used[r] |= bit
		used[c] |= bit
		used[b] |= bit

	_empty_count = 0
	_group_empty.fill(0)
	for i: int in Tables.CELL_COUNT:
		var digit: int = cells[i]
		_cells[i] = digit
		if digit != 0:
			_cand[i] = 0
			continue
		var r: int = Tables.ROW_OF[i]
		var c: int = Tables.COL_OF[i]
		var b: int = Tables.BOX_OF[i]
		var allowed: int = Tables.ALL_DIGITS & ~(used[r] | used[9 + c] | used[18 + b])
		_cand[i] = allowed & candidates[i] if use_candidates else allowed
		_empty_count += 1
		_group_empty[b] += 1
		_group_empty[9 + r] += 1
		_group_empty[18 + c] += 1

	_counts.fill(0)
	_hardest = NO_STEP
	_steps = 0
	_clear_step()
	_loaded = true
	return true


## Techniques 4 to 13 in order, for max_level and below.
func _find_harder(max_level: int) -> int:
	# The board changed since the last search.
	_group_pos_ready = false
	_line_pos_ready = false
	if max_level < 2:
		return NO_STEP
	if _find_pointing():
		return POINTING
	if _find_claiming():
		return CLAIMING
	if _find_naked_pair():
		return NAKED_PAIR
	if max_level < 3:
		return NO_STEP
	if _find_hidden_pair():
		return HIDDEN_PAIR
	if _find_naked_triple():
		return NAKED_TRIPLE
	if _find_hidden_triple():
		return HIDDEN_TRIPLE
	if _find_x_wing():
		return X_WING
	if _find_y_wing():
		return Y_WING
	if max_level < 4:
		return NO_STEP
	if _find_swordfish():
		return SWORDFISH
	if _find_xyz_wing():
		return XYZ_WING
	return NO_STEP


## For solves(): places every hidden single (which covers last empty cells)
## and, from Easy up, every naked single, in one pass. Returns true if it
## placed anything. Each placement is checked against the current candidates.
func _sweep_singles(max_level: int) -> bool:
	var group_empty: PackedInt32Array = _group_empty
	var units: PackedInt32Array = Tables.UNITS
	var cand: PackedInt32Array = _cand
	var lowest: PackedInt32Array = Tables.LOWEST_DIGIT
	var placed: bool = false
	for g: int in 27:
		if group_empty[g] == 0:
			continue
		var base: int = g * 9
		var once: int = 0
		var twice: int = 0
		for k: int in 9:
			var mask: int = cand[units[base + k]]
			twice |= once & mask
			once |= mask
		var singles: int = once & ~twice
		while singles != 0:
			var bit: int = singles & -singles
			singles ^= bit
			for k: int in 9:
				var i: int = units[base + k]
				if cand[i] & bit:
					_place(i, lowest[bit])
					placed = true
					break
	if max_level >= 1:
		var popcount: PackedInt32Array = Tables.POPCOUNT
		for i: int in Tables.CELL_COUNT:
			var mask: int = cand[i]
			if mask != 0 and popcount[mask] == 1:
				_place(i, lowest[mask])
				placed = true
	return placed


func _clear_step() -> void:
	_step = NO_STEP
	_step_cell = -1
	_step_digit = 0
	_elim_count = 0


func _place(cell: int, digit: int) -> void:
	var bit: int = 1 << (digit - 1)
	var cand: PackedInt32Array = _cand
	var peers: PackedInt32Array = Tables.PEERS
	_cells[cell] = digit
	cand[cell] = 0
	var base: int = cell * 20
	for k: int in 20:
		cand[peers[base + k]] &= ~bit
	_group_empty[Tables.BOX_OF[cell]] -= 1
	_group_empty[9 + Tables.ROW_OF[cell]] -= 1
	_group_empty[18 + Tables.COL_OF[cell]] -= 1
	_empty_count -= 1


func _record(cell: int, mask: int) -> void:
	_elim_cells[_elim_count] = cell
	_elim_masks[_elim_count] = mask
	_elim_count += 1


func _record_placement(cell: int, bit: int) -> void:
	_step_cell = cell
	_step_digit = Tables.LOWEST_DIGIT[bit]


# 1. Last empty cell: a group with one empty cell gets the missing digit.
func _find_last_empty_cell() -> bool:
	var group_empty: PackedInt32Array = _group_empty
	var units: PackedInt32Array = Tables.UNITS
	var cells: PackedInt32Array = _cells
	var cand: PackedInt32Array = _cand
	for g: int in 27:
		if group_empty[g] != 1:
			continue
		var base: int = g * 9
		for k: int in 9:
			var i: int = units[base + k]
			if cells[i] != 0:
				continue
			# The eight digits of the group are ruled out, so the only
			# candidate left is the missing digit (none if the board is
			# contradictory).
			var mask: int = cand[i]
			if Tables.POPCOUNT[mask] == 1:
				_record_placement(i, mask)
				return true
			break
	return false


# 2. Hidden single: a digit with one possible cell in a group.
func _find_hidden_single() -> bool:
	var group_empty: PackedInt32Array = _group_empty
	var units: PackedInt32Array = Tables.UNITS
	var cand: PackedInt32Array = _cand
	for g: int in 27:
		if group_empty[g] == 0:
			continue
		var base: int = g * 9
		var once: int = 0
		var twice: int = 0
		for k: int in 9:
			var mask: int = cand[units[base + k]]
			twice |= once & mask
			once |= mask
		var singles: int = once & ~twice
		if singles == 0:
			continue
		var bit: int = singles & -singles
		for k: int in 9:
			var i: int = units[base + k]
			if cand[i] & bit:
				_record_placement(i, bit)
				return true
	return false


# 3. Naked single: a cell with one candidate.
func _find_naked_single() -> bool:
	var cand: PackedInt32Array = _cand
	var popcount: PackedInt32Array = Tables.POPCOUNT
	for i: int in Tables.CELL_COUNT:
		var mask: int = cand[i]
		if mask != 0 and popcount[mask] == 1:
			_record_placement(i, mask)
			return true
	return false


# 4. Pointing: in a box, digit d only in one row (or column); remove d from
# the rest of that row (column).
func _find_pointing() -> bool:
	var group_empty: PackedInt32Array = _group_empty
	var units: PackedInt32Array = Tables.UNITS
	var cand: PackedInt32Array = _cand
	for b: int in 9:
		if group_empty[b] < 2:
			continue
		var base: int = b * 9
		var m0: int = cand[units[base]]
		var m1: int = cand[units[base + 1]]
		var m2: int = cand[units[base + 2]]
		var m3: int = cand[units[base + 3]]
		var m4: int = cand[units[base + 4]]
		var m5: int = cand[units[base + 5]]
		var m6: int = cand[units[base + 6]]
		var m7: int = cand[units[base + 7]]
		var m8: int = cand[units[base + 8]]
		var r0: int = m0 | m1 | m2
		var r1: int = m3 | m4 | m5
		var r2: int = m6 | m7 | m8
		var c0: int = m0 | m3 | m6
		var c1: int = m1 | m4 | m7
		var c2: int = m2 | m5 | m8
		var row_only0: int = r0 & ~(r1 | r2)
		var row_only1: int = r1 & ~(r0 | r2)
		var row_only2: int = r2 & ~(r0 | r1)
		var col_only0: int = c0 & ~(c1 | c2)
		var col_only1: int = c1 & ~(c0 | c2)
		var col_only2: int = c2 & ~(c0 | c1)
		var digits: int = row_only0 | row_only1 | row_only2 | col_only0 | col_only1 | col_only2
		var first_row: int = Tables.ROW_OF[units[base]]
		var first_col: int = Tables.COL_OF[units[base]]
		while digits != 0:
			var bit: int = digits & -digits
			digits ^= bit
			var line: int = -1
			if row_only0 & bit:
				line = 0
			elif row_only1 & bit:
				line = 1
			elif row_only2 & bit:
				line = 2
			if line >= 0 and _eliminate_in_group_outside_box(9 + first_row + line, b, bit):
				return true
			line = -1
			if col_only0 & bit:
				line = 0
			elif col_only1 & bit:
				line = 1
			elif col_only2 & bit:
				line = 2
			if line >= 0 and _eliminate_in_group_outside_box(18 + first_col + line, b, bit):
				return true
	return false


func _eliminate_in_group_outside_box(group: int, box: int, bit: int) -> bool:
	var units: PackedInt32Array = Tables.UNITS
	var box_of: PackedInt32Array = Tables.BOX_OF
	var cand: PackedInt32Array = _cand
	var base: int = group * 9
	for k: int in 9:
		var i: int = units[base + k]
		if box_of[i] != box and (cand[i] & bit) != 0:
			_record(i, bit)
	return _elim_count > 0


# 5. Claiming: in a row (or column), digit d only in one box; remove d from
# the rest of that box.
func _find_claiming() -> bool:
	var group_empty: PackedInt32Array = _group_empty
	var units: PackedInt32Array = Tables.UNITS
	var cand: PackedInt32Array = _cand
	for line: int in 18:
		var g: int = 9 + line
		if group_empty[g] < 2:
			continue
		var base: int = g * 9
		var s0: int = cand[units[base]] | cand[units[base + 1]] | cand[units[base + 2]]
		var s1: int = cand[units[base + 3]] | cand[units[base + 4]] | cand[units[base + 5]]
		var s2: int = cand[units[base + 6]] | cand[units[base + 7]] | cand[units[base + 8]]
		var only0: int = s0 & ~(s1 | s2)
		var only1: int = s1 & ~(s0 | s2)
		var only2: int = s2 & ~(s0 | s1)
		var digits: int = only0 | only1 | only2
		while digits != 0:
			var bit: int = digits & -digits
			digits ^= bit
			var segment: int = 0
			if only1 & bit:
				segment = 1
			elif only2 & bit:
				segment = 2
			var box: int = Tables.BOX_OF[units[base + segment * 3]]
			var box_base: int = box * 9
			for k: int in 9:
				var i: int = units[box_base + k]
				var in_line: bool = Tables.ROW_OF[i] == line if line < 9 else Tables.COL_OF[i] == line - 9
				if not in_line and (cand[i] & bit) != 0:
					_record(i, bit)
			if _elim_count > 0:
				return true
	return false


# 6. Naked pair: two cells of a group with the same two candidates; remove
# them from every cell that sees both.
func _find_naked_pair() -> bool:
	var group_empty: PackedInt32Array = _group_empty
	var units: PackedInt32Array = Tables.UNITS
	var cand: PackedInt32Array = _cand
	var popcount: PackedInt32Array = Tables.POPCOUNT
	var list: PackedInt32Array = _list
	for g: int in 27:
		if group_empty[g] < 2:
			continue
		var base: int = g * 9
		var n: int = 0
		for k: int in 9:
			var i: int = units[base + k]
			if popcount[cand[i]] == 2:
				list[n] = i
				n += 1
		for a: int in n - 1:
			var cell_a: int = list[a]
			var mask: int = cand[cell_a]
			for b: int in range(a + 1, n):
				var cell_b: int = list[b]
				if cand[cell_b] == mask and _eliminate_seen_by_all(cell_a, cell_b, -1, mask):
					return true
	return false


# 7. Hidden pair: two digits whose only cells in a group are the same two;
# remove every other candidate from those cells.
func _find_hidden_pair() -> bool:
	var group_empty: PackedInt32Array = _group_empty
	var units: PackedInt32Array = Tables.UNITS
	var cand: PackedInt32Array = _cand
	var popcount: PackedInt32Array = Tables.POPCOUNT
	_ensure_group_positions()
	var pos: PackedInt32Array = _group_pos
	for g: int in 27:
		# With two empty cells, nothing else can be removed from them.
		if group_empty[g] < 3:
			continue
		var base: int = g * 9
		for da: int in 8:
			var cells_a: int = pos[base + da]
			if popcount[cells_a] != 2:
				continue
			for db: int in range(da + 1, 9):
				if pos[base + db] != cells_a:
					continue
				var keep: int = (1 << da) | (1 << db)
				var bits: int = cells_a
				while bits != 0:
					var cell_bit: int = bits & -bits
					bits ^= cell_bit
					var i: int = units[base + Tables.LOWEST_DIGIT[cell_bit] - 1]
					var extra: int = cand[i] & ~keep
					if extra != 0:
						_record(i, extra)
				if _elim_count > 0:
					return true
	return false


# 8. Naked triple: three cells of a group whose candidates together are three
# digits; remove those digits from every cell that sees all three.
func _find_naked_triple() -> bool:
	var group_empty: PackedInt32Array = _group_empty
	var units: PackedInt32Array = Tables.UNITS
	var cand: PackedInt32Array = _cand
	var popcount: PackedInt32Array = Tables.POPCOUNT
	var list: PackedInt32Array = _list
	for g: int in 27:
		if group_empty[g] < 3:
			continue
		var base: int = g * 9
		var n: int = 0
		for k: int in 9:
			var i: int = units[base + k]
			var count: int = popcount[cand[i]]
			if count == 2 or count == 3:
				list[n] = i
				n += 1
		for a: int in n - 2:
			var mask_a: int = cand[list[a]]
			for b: int in range(a + 1, n - 1):
				var mask_ab: int = mask_a | cand[list[b]]
				if popcount[mask_ab] > 3:
					continue
				for c: int in range(b + 1, n):
					var mask: int = mask_ab | cand[list[c]]
					if popcount[mask] == 3 and _eliminate_seen_by_all(list[a], list[b], list[c], mask):
						return true
	return false


# 9. Hidden triple: three digits whose cells in a group are three cells
# together; remove every other candidate from those cells.
func _find_hidden_triple() -> bool:
	var group_empty: PackedInt32Array = _group_empty
	var units: PackedInt32Array = Tables.UNITS
	var cand: PackedInt32Array = _cand
	var popcount: PackedInt32Array = Tables.POPCOUNT
	_ensure_group_positions()
	var pos: PackedInt32Array = _group_pos
	var list: PackedInt32Array = _list
	for g: int in 27:
		# With three empty cells, nothing else can be removed from them.
		if group_empty[g] < 4:
			continue
		var base: int = g * 9
		var n: int = 0
		for d: int in 9:
			var count: int = popcount[pos[base + d]]
			if count >= 1 and count <= 3:
				list[n] = d
				n += 1
		for a: int in n - 2:
			var cells_a: int = pos[base + list[a]]
			for b: int in range(a + 1, n - 1):
				var cells_ab: int = cells_a | pos[base + list[b]]
				if popcount[cells_ab] > 3:
					continue
				for c: int in range(b + 1, n):
					var cells_abc: int = cells_ab | pos[base + list[c]]
					if popcount[cells_abc] != 3:
						continue
					var keep: int = (1 << list[a]) | (1 << list[b]) | (1 << list[c])
					var bits: int = cells_abc
					while bits != 0:
						var cell_bit: int = bits & -bits
						bits ^= cell_bit
						var i: int = units[base + Tables.LOWEST_DIGIT[cell_bit] - 1]
						var extra: int = cand[i] & ~keep
						if extra != 0:
							_record(i, extra)
					if _elim_count > 0:
						return true
	return false


# 10. X-Wing: two rows where d fits in the same two columns only; remove d
# from the rest of those columns. Then the same with rows and columns swapped.
func _find_x_wing() -> bool:
	_ensure_line_positions()
	for d: int in 9:
		if _x_wing_in(_row_pos, d, true) or _x_wing_in(_col_pos, d, false):
			return true
	return false


func _x_wing_in(line_pos: PackedInt32Array, d: int, base_is_row: bool) -> bool:
	var popcount: PackedInt32Array = Tables.POPCOUNT
	var base: int = d * 9
	for l1: int in 8:
		var cross: int = line_pos[base + l1]
		if popcount[cross] != 2:
			continue
		for l2: int in range(l1 + 1, 9):
			if line_pos[base + l2] == cross and _eliminate_fish(cross, (1 << l1) | (1 << l2), 1 << d, base_is_row):
				return true
	return false


# 11. Y-Wing: pivot {x, y}, wings {x, z} and {y, z} that each see the pivot;
# remove z from every cell that sees both wings.
func _find_y_wing() -> bool:
	var cand: PackedInt32Array = _cand
	var peers: PackedInt32Array = Tables.PEERS
	var popcount: PackedInt32Array = Tables.POPCOUNT
	for p: int in Tables.CELL_COUNT:
		var pivot: int = cand[p]
		if popcount[pivot] != 2:
			continue
		var base: int = p * 20
		for a: int in 19:
			var wing_a: int = peers[base + a]
			var mask_a: int = cand[wing_a]
			if popcount[mask_a] != 2 or mask_a == pivot:
				continue
			var shared: int = mask_a & pivot
			if shared == 0:
				continue
			var z: int = mask_a & ~pivot
			var wanted: int = (pivot & ~shared) | z
			for b: int in range(a + 1, 20):
				var wing_b: int = peers[base + b]
				if cand[wing_b] == wanted and _eliminate_seen_by_all(wing_a, wing_b, -1, z):
					return true
	return false


# 12. Swordfish: three rows where d fits in two or three cells each, all in
# the same three columns; remove d from the rest of those columns. Then the
# same with rows and columns swapped.
func _find_swordfish() -> bool:
	_ensure_line_positions()
	for d: int in 9:
		if _swordfish_in(_row_pos, d, true) or _swordfish_in(_col_pos, d, false):
			return true
	return false


func _swordfish_in(line_pos: PackedInt32Array, d: int, base_is_row: bool) -> bool:
	var popcount: PackedInt32Array = Tables.POPCOUNT
	var list: PackedInt32Array = _list
	var base: int = d * 9
	var n: int = 0
	for l: int in 9:
		var count: int = popcount[line_pos[base + l]]
		if count == 2 or count == 3:
			list[n] = l
			n += 1
	for a: int in n - 2:
		var cross_a: int = line_pos[base + list[a]]
		for b: int in range(a + 1, n - 1):
			var cross_ab: int = cross_a | line_pos[base + list[b]]
			if popcount[cross_ab] > 3:
				continue
			for c: int in range(b + 1, n):
				var cross: int = cross_ab | line_pos[base + list[c]]
				if popcount[cross] != 3:
					continue
				var lines: int = (1 << list[a]) | (1 << list[b]) | (1 << list[c])
				if _eliminate_fish(cross, lines, 1 << d, base_is_row):
					return true
	return false


# 13. XYZ-Wing: pivot {x, y, z}, wings {x, z} and {y, z} that each see the
# pivot; remove z from every cell that sees all three.
func _find_xyz_wing() -> bool:
	var cand: PackedInt32Array = _cand
	var peers: PackedInt32Array = Tables.PEERS
	var popcount: PackedInt32Array = Tables.POPCOUNT
	for p: int in Tables.CELL_COUNT:
		var pivot: int = cand[p]
		if popcount[pivot] != 3:
			continue
		var base: int = p * 20
		for a: int in 19:
			var wing_a: int = peers[base + a]
			var mask_a: int = cand[wing_a]
			if popcount[mask_a] != 2 or (mask_a & ~pivot) != 0:
				continue
			for b: int in range(a + 1, 20):
				var wing_b: int = peers[base + b]
				var mask_b: int = cand[wing_b]
				if popcount[mask_b] != 2 or (mask_b & ~pivot) != 0 or mask_b == mask_a:
					continue
				if _eliminate_seen_by_all(p, wing_a, wing_b, mask_a & mask_b):
					return true
	return false


## Records mask for every cell other than a, b and c that sees a, b and c
## (c = -1 for two cells). Returns true if anything was recorded.
func _eliminate_seen_by_all(a: int, b: int, c: int, mask: int) -> bool:
	var cand: PackedInt32Array = _cand
	var peers: PackedInt32Array = Tables.PEERS
	var row_of: PackedInt32Array = Tables.ROW_OF
	var col_of: PackedInt32Array = Tables.COL_OF
	var box_of: PackedInt32Array = Tables.BOX_OF
	var rb: int = row_of[b]
	var cb: int = col_of[b]
	var bb: int = box_of[b]
	var rc: int = -1
	var cc: int = -1
	var bc: int = -1
	if c >= 0:
		rc = row_of[c]
		cc = col_of[c]
		bc = box_of[c]
	var base: int = a * 20
	for k: int in 20:
		var p: int = peers[base + k]
		var removed: int = cand[p] & mask
		if removed == 0 or p == b or p == c:
			continue
		var rp: int = row_of[p]
		var cp: int = col_of[p]
		var bp: int = box_of[p]
		if rp != rb and cp != cb and bp != bb:
			continue
		if c >= 0 and rp != rc and cp != cc and bp != bc:
			continue
		_record(p, removed)
	return _elim_count > 0


## Records bit for every cell on the cross lines that is not on a base line.
## With base_is_row, base lines are rows and cross lines are columns.
func _eliminate_fish(cross: int, base_lines: int, bit: int, base_is_row: bool) -> bool:
	var cand: PackedInt32Array = _cand
	var bits: int = cross
	while bits != 0:
		var cross_bit: int = bits & -bits
		bits ^= cross_bit
		var x: int = Tables.LOWEST_DIGIT[cross_bit] - 1
		for y: int in 9:
			if base_lines & (1 << y):
				continue
			var i: int = y * 9 + x if base_is_row else x * 9 + y
			if cand[i] & bit:
				_record(i, bit)
	return _elim_count > 0


## Fills _group_pos for every group, once per search.
func _ensure_group_positions() -> void:
	if _group_pos_ready:
		return
	_group_pos_ready = true
	var units: PackedInt32Array = Tables.UNITS
	var lowest: PackedInt32Array = Tables.LOWEST_DIGIT
	var cand: PackedInt32Array = _cand
	var pos: PackedInt32Array = _group_pos
	pos.fill(0)
	for g: int in 27:
		if _group_empty[g] == 0:
			continue
		var base: int = g * 9
		for k: int in 9:
			var mask: int = cand[units[base + k]]
			var cell_bit: int = 1 << k
			while mask != 0:
				var bit: int = mask & -mask
				mask ^= bit
				pos[base + lowest[bit] - 1] |= cell_bit


## Fills _row_pos and _col_pos, once per search.
func _ensure_line_positions() -> void:
	if _line_pos_ready:
		return
	_line_pos_ready = true
	var cand: PackedInt32Array = _cand
	var lowest: PackedInt32Array = Tables.LOWEST_DIGIT
	var row_pos: PackedInt32Array = _row_pos
	var col_pos: PackedInt32Array = _col_pos
	row_pos.fill(0)
	col_pos.fill(0)
	for i: int in Tables.CELL_COUNT:
		var mask: int = cand[i]
		if mask == 0:
			continue
		var r: int = Tables.ROW_OF[i]
		var c: int = Tables.COL_OF[i]
		var col_bit: int = 1 << c
		var row_bit: int = 1 << r
		while mask != 0:
			var bit: int = mask & -mask
			mask ^= bit
			var d: int = lowest[bit] - 1
			row_pos[d * 9 + r] |= col_bit
			col_pos[d * 9 + c] |= row_bit
