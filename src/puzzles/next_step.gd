class_name NextStep
extends RefCounted
## The hint finder (GDD 10.1 and 10.2, docs/ARCHITECTURE.md section 5).
##
## find() looks, in this order, for:
## 1. a placed digit that differs from the solution, first in reading order
##    (technique wrong_digit);
## 2. the technique solver's next step that the player has not done yet. The
##    solver starts from the digits on the board with its own candidates and
##    never reads the ring, except to check whether an elimination step is
##    already done: a step whose candidates are all crossed on the ring (by
##    hand or by Auto Cross) is applied silently and the search goes on;
## 3. the fallback: the first empty cell and its digit.
##
## A hint never changes the board. Only static functions and per call
## objects, so it is safe on a worker thread.

const Tables := preload("res://src/puzzles/grid_tables.gd")

const NAMES: Array[String] = [
	"Last empty cell", "Hidden single", "Naked single", "Pointing", "Claiming",
	"Naked pair", "Hidden pair", "Naked triple", "Hidden triple", "X-Wing",
	"Y-Wing", "Swordfish", "XYZ-Wing",
]
## Lesson titles for the Beginner and Easy techniques (GDD 11.2).
const LESSONS: Array[String] = [
	"Lesson: Last empty cell", "Lesson: Hidden single", "Lesson: Naked single",
]
const WRONG_DIGIT_NAME: String = "Wrong digit"


## The hint for this board. solution is the puzzle's solution (81 digits 1 to
## 9). Never returns null and never changes the board.
static func find(solution: PackedInt32Array, board: Board) -> Hint:
	var solution_ok: bool = _is_full_grid(solution)
	if solution_ok:
		for i: int in Tables.CELL_COUNT:
			var digit: int = board.digits[i]
			if digit != 0 and not board.is_given(i) and digit != solution[i]:
				return _wrong_digit(i, digit)
	var step: Hint = _next_step(board)
	if step != null:
		return step
	return _fallback(solution if solution_ok else Solver.solve(board.givens), board)


## Every placement (x = cell, y = digit) that one technique finds on this
## grid, with candidates computed from the digits only. Only last_empty_cell,
## hidden_single and naked_single place digits; any other technique, or a
## grid that is not valid, gives an empty list. Sorted by cell, then digit.
static func placements_by(grid: PackedInt32Array, technique: StringName) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var solver: TechniqueSolver = TechniqueSolver.new()
	if not solver.load_givens(grid):
		return out
	var cells: PackedInt32Array = solver.get_cells()
	var cand: PackedInt32Array = solver.get_candidates()
	var found: Dictionary = {}
	match technique:
		&"last_empty_cell":
			for g: int in 27:
				var empty: int = -1
				var count: int = 0
				for k: int in 9:
					var i: int = Tables.UNITS[g * 9 + k]
					if cells[i] == 0:
						empty = i
						count += 1
				if count == 1 and Tables.POPCOUNT[cand[empty]] == 1:
					found[Vector2i(empty, Tables.LOWEST_DIGIT[cand[empty]])] = true
		&"hidden_single":
			for g: int in 27:
				for d: int in range(1, 10):
					var bit: int = 1 << (d - 1)
					var where: int = -1
					var count: int = 0
					for k: int in 9:
						var i: int = Tables.UNITS[g * 9 + k]
						if cand[i] & bit:
							where = i
							count += 1
					if count == 1:
						found[Vector2i(where, d)] = true
		&"naked_single":
			for i: int in Tables.CELL_COUNT:
				if cand[i] != 0 and Tables.POPCOUNT[cand[i]] == 1:
					found[Vector2i(i, Tables.LOWEST_DIGIT[cand[i]])] = true
	for key: Vector2i in found:
		out.append(key)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	return out


static func _is_full_grid(grid: PackedInt32Array) -> bool:
	if grid.size() != Tables.CELL_COUNT:
		return false
	for value: int in grid:
		if value < 1 or value > 9:
			return false
	return true


static func _wrong_digit(cell: int, digit: int) -> Hint:
	var hint: Hint = Hint.new()
	hint.technique = &"wrong_digit"
	hint.technique_name = WRONG_DIGIT_NAME
	hint.text = "This %d is not right. Erase it and look again." % digit
	hint.targets = PackedInt32Array([cell])
	return hint


## Step 2 of find(), or null if the solver finds no new step.
static func _next_step(board: Board) -> Hint:
	var solver: TechniqueSolver = TechniqueSolver.new()
	if not solver.load_givens(board.digits):
		return null
	while true:
		var technique: int = solver.find_step(TechniqueSolver.MAX_LEVEL)
		if technique == TechniqueSolver.NO_STEP:
			return null
		if solver.step_cell() >= 0:
			return _placement_hint(solver, technique, board)
		var open_marks: PackedInt32Array = _open_eliminations(solver.step_eliminations(), board)
		if not open_marks.is_empty():
			return _elimination_hint(solver, technique, open_marks)
		solver.apply_step()
	return null


## The candidates an elimination step removes that still show open on the
## ring (open or restored by hand), as sorted mark indices.
static func _open_eliminations(pairs: PackedInt32Array, board: Board) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for k: int in range(0, pairs.size(), 2):
		var cell: int = pairs[k]
		var mask: int = pairs[k + 1]
		for d: int in range(1, 10):
			if (mask & (1 << (d - 1))) != 0 and not board.is_crossed(cell, d):
				out.append(cell * 9 + d - 1)
	out.sort()
	return out


static func _placement_hint(solver: TechniqueSolver, technique: int, board: Board) -> Hint:
	var hint: Hint = _base_hint(technique)
	var cell: int = solver.step_cell()
	var digit: int = solver.step_digit()
	var group: int = solver.step_group()
	hint.placement_cell = cell
	hint.placement_digit = digit
	hint.targets = PackedInt32Array([cell])
	match technique:
		TechniqueSolver.LAST_EMPTY_CELL:
			hint.text = "This %s has one empty cell left. It must be %d." % [_group_word(group), digit]
			var reasons: PackedInt32Array = PackedInt32Array()
			for k: int in 9:
				var i: int = Tables.UNITS[group * 9 + k]
				if i != cell:
					reasons.append(i)
			reasons.sort()
			hint.reasons = reasons
		TechniqueSolver.HIDDEN_SINGLE:
			hint.text = "In this %s, %d fits in only one cell. It goes here." % [_group_word(group), digit]
			hint.reasons = _hidden_single_reasons(board.digits, group, cell, digit)
		_:
			hint.text = "Every digit but %d is ruled out here, so this cell is %d." % [digit, digit]
	return hint


## For each other empty cell of the group, a cell holding digit that rules it
## out: one already picked if it does, otherwise its first peer in reading
## order that holds digit. A cell the solver ruled out by an earlier
## elimination rather than by a digit adds no reason cell.
static func _hidden_single_reasons(digits: PackedInt32Array, group: int, cell: int, digit: int) -> PackedInt32Array:
	var reasons: PackedInt32Array = PackedInt32Array()
	for k: int in 9:
		var empty: int = Tables.UNITS[group * 9 + k]
		if empty == cell or digits[empty] != 0:
			continue
		var covered: bool = false
		for r: int in reasons:
			if _sees(r, empty):
				covered = true
				break
		if covered:
			continue
		var base: int = empty * 20
		var best: int = -1
		for p: int in 20:
			var peer: int = Tables.PEERS[base + p]
			if digits[peer] == digit and (best == -1 or peer < best):
				best = peer
		if best >= 0:
			reasons.append(best)
	reasons.sort()
	return reasons


static func _elimination_hint(solver: TechniqueSolver, technique: int, open_marks: PackedInt32Array) -> Hint:
	var hint: Hint = _base_hint(technique)
	hint.eliminations = open_marks
	var targets: PackedInt32Array = PackedInt32Array()
	for mark: int in open_marks:
		var cell: int = mark / 9
		if targets.is_empty() or targets[targets.size() - 1] != cell:
			targets.append(cell)
	hint.targets = targets
	var group: int = solver.step_group()
	var second: int = solver.step_second_group()
	var digits: PackedInt32Array = _digits_of(solver.step_pattern_digits())
	var pattern: PackedInt32Array = solver.step_pattern_cells()
	pattern.sort()
	var d: int = digits[0] if not digits.is_empty() else 0
	match technique:
		TechniqueSolver.POINTING:
			var line: String = _group_word(second)
			hint.text = "In this box, %d can only go in one %s. So cross %d out in the rest of that %s." % [d, line, d, line]
		TechniqueSolver.CLAIMING:
			hint.text = "In this %s, %d can only go in one box. So cross %d out in the rest of that box." % [_group_word(group), d, d]
		TechniqueSolver.NAKED_PAIR:
			hint.text = "These two cells can only hold %d and %d. So cross %d and %d out in the rest of this %s." % [digits[0], digits[1], digits[0], digits[1], _group_word(group)]
		TechniqueSolver.HIDDEN_PAIR:
			hint.text = "In this %s, %d and %d can only go in these two cells. So cross out every other digit in them." % [_group_word(group), digits[0], digits[1]]
		TechniqueSolver.NAKED_TRIPLE:
			hint.text = "These three cells can only hold %d, %d and %d. So cross those digits out in the rest of this %s." % [digits[0], digits[1], digits[2], _group_word(group)]
		TechniqueSolver.HIDDEN_TRIPLE:
			hint.text = "In this %s, %d, %d and %d can only go in these three cells. So cross out every other digit in them." % [_group_word(group), digits[0], digits[1], digits[2]]
		TechniqueSolver.X_WING:
			hint.text = "In these two %ss, %d can only go in the same two %ss. So cross %d out in the rest of those %ss." % [_group_word(group), d, _group_word(second), d, _group_word(second)]
		TechniqueSolver.SWORDFISH:
			hint.text = "In these three %ss, %d can only go in the same three %ss. So cross %d out in the rest of those %ss." % [_group_word(group), d, _group_word(second), d, _group_word(second)]
		TechniqueSolver.Y_WING:
			var pivot: PackedInt32Array = _digits_of(solver.get_candidates()[solver.step_pattern_cells()[0]])
			hint.text = "The middle cell is %d or %d, so one of the other two marked cells must be %d. Cross %d out in cells that see both." % [pivot[0], pivot[1], d, d]
		TechniqueSolver.XYZ_WING:
			hint.text = "One of these three cells must be %d. So cross %d out in cells that see all three." % [d, d]
	# Hidden pairs and triples have no reason cells (GDD 10.2): their cells
	# are the targets.
	if technique != TechniqueSolver.HIDDEN_PAIR and technique != TechniqueSolver.HIDDEN_TRIPLE:
		hint.reasons = pattern
	return hint


static func _base_hint(technique: int) -> Hint:
	var hint: Hint = Hint.new()
	hint.technique = TechniqueSolver.technique_id(technique)
	hint.technique_name = NAMES[technique]
	hint.lesson_title = LESSONS[technique] if technique < LESSONS.size() else ""
	return hint


static func _fallback(solution: PackedInt32Array, board: Board) -> Hint:
	var hint: Hint = Hint.new()
	hint.technique = &"fallback"
	for i: int in Tables.CELL_COUNT:
		if board.digits[i] == 0:
			hint.targets = PackedInt32Array([i])
			if solution.size() == Tables.CELL_COUNT:
				hint.text = "This cell is %d." % solution[i]
			break
	return hint


static func _group_word(group: int) -> String:
	if group < 9:
		return "box"
	if group < 18:
		return "row"
	return "column"


static func _digits_of(mask: int) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for d: int in range(1, 10):
		if mask & (1 << (d - 1)):
			out.append(d)
	return out


static func _sees(a: int, b: int) -> bool:
	return Tables.ROW_OF[a] == Tables.ROW_OF[b] or Tables.COL_OF[a] == Tables.COL_OF[b] or Tables.BOX_OF[a] == Tables.BOX_OF[b]
