class_name PuzzleGenerator
extends RefCounted
## Makes a puzzle for a level from a seed. The same level and seed always give
## the same puzzle, on every platform. Every puzzle has exactly one solution
## and grades at exactly its level (GDD 11).
##
## One attempt:
## 1. Fill a full grid at random (backtracking, digits in random order).
## 2. Removal pass: try every given once, in a random order. A removal stays
##    if the technique solver can still finish the board using only the
##    techniques of the target level and below. A board the techniques can
##    finish has exactly one solution.
## 3. Grade the result with every technique, in the GDD's fixed order. Keep
##    it if it grades at the target level (Beginner also needs a hidden
##    single) and the backtracking Solver confirms one solution.
## Otherwise the next attempt starts from a new grid. Everything comes from
## one SeededRng, so the attempts follow each other in a fixed way and the
## loop always ends with the same puzzle. Hit rates and times per level are
## in docs/GENERATION_TIMING.md.
##
## Only static functions and per call objects, so it is safe on a worker
## thread.

const Tables := preload("res://src/puzzles/grid_tables.gd")
const LEVEL_COUNT: int = 5


## The puzzle for level (0 Beginner to 4 Expert) and seed (0 to 2^32 - 1).
## A level outside 0 to 4 is clamped into it, and only the low 32 bits of the
## seed are used, so the returned puzzle's id always parses.
static func generate(level: int, seed_value: int) -> Puzzle:
	return generate_with_stats(level, seed_value)["puzzle"]


## Same as generate(), plus the number of attempts it took, for the timing
## tool: {"puzzle": Puzzle, "attempts": int}.
static func generate_with_stats(level: int, seed_value: int) -> Dictionary:
	var target: int = clampi(level, 0, LEVEL_COUNT - 1)
	var seed_used: int = seed_value & PuzzleId.MAX_SEED
	# Level and seed together pick the random sequence, so one seed gives
	# unrelated puzzles at different levels.
	var rng: SeededRng = SeededRng.new((seed_used << 3) | target)
	var solver: TechniqueSolver = TechniqueSolver.new()
	var attempts: int = 0
	while true:
		attempts += 1
		var solution: PackedInt32Array = _make_full_grid(rng)
		var givens: PackedInt32Array = solution.duplicate()
		_removal_pass(givens, target, rng, solver)
		if _grades_at(givens, target, solver) and Solver.count_solutions(givens, 2) == 1:
			var puzzle: Puzzle = Puzzle.new()
			puzzle.level = target
			puzzle.seed = seed_used
			puzzle.id = PuzzleId.make(target, seed_used)
			puzzle.givens = givens
			puzzle.solution = solution
			puzzle.hardest = TechniqueSolver.technique_id(solver.hardest_technique())
			return {"puzzle": puzzle, "attempts": attempts}
	return {}


## A random full grid: backtracking that takes the cell with the fewest
## candidates and tries its digits in random order.
static func _make_full_grid(rng: SeededRng) -> PackedInt32Array:
	var cells: PackedInt32Array = PackedInt32Array()
	cells.resize(Tables.CELL_COUNT)
	cells.fill(0)
	# Digits used per row (0 to 8), column (9 to 17) and box (18 to 26).
	var used: PackedInt32Array = PackedInt32Array()
	used.resize(27)
	used.fill(0)
	_fill(cells, used, rng)
	return cells


static func _fill(cells: PackedInt32Array, used: PackedInt32Array, rng: SeededRng) -> bool:
	var best: int = -1
	var best_mask: int = 0
	var best_count: int = 10
	for i: int in Tables.CELL_COUNT:
		if cells[i] != 0:
			continue
		var mask: int = Tables.ALL_DIGITS & ~(used[Tables.ROW_OF[i]] | used[9 + Tables.COL_OF[i]] | used[18 + Tables.BOX_OF[i]])
		var count: int = Tables.POPCOUNT[mask]
		if count == 0:
			return false
		if count < best_count:
			best = i
			best_mask = mask
			best_count = count
	if best == -1:
		return true
	var r: int = Tables.ROW_OF[best]
	var c: int = 9 + Tables.COL_OF[best]
	var b: int = 18 + Tables.BOX_OF[best]
	var mask: int = best_mask
	while mask != 0:
		# Take a random one of the digits left.
		var rest: int = mask
		for skip: int in rng.next_int(Tables.POPCOUNT[mask]):
			rest &= rest - 1
		var bit: int = rest & -rest
		mask ^= bit
		cells[best] = Tables.LOWEST_DIGIT[bit]
		used[r] |= bit
		used[c] |= bit
		used[b] |= bit
		if _fill(cells, used, rng):
			return true
		used[r] &= ~bit
		used[c] &= ~bit
		used[b] &= ~bit
		cells[best] = 0
	return false


## Tries to remove every given once, in a random order, keeping each removal
## the techniques of the target level and below can still solve.
static func _removal_pass(givens: PackedInt32Array, target: int, rng: SeededRng, solver: TechniqueSolver) -> void:
	var order: PackedInt32Array = PackedInt32Array()
	order.resize(Tables.CELL_COUNT)
	for i: int in Tables.CELL_COUNT:
		order[i] = i
	rng.shuffle(order)
	for i: int in order:
		var digit: int = givens[i]
		if digit == 0:
			continue
		givens[i] = 0
		solver.load_givens(givens)
		if not solver.solves(target):
			givens[i] = digit


## True if the givens grade at exactly the target level with every technique
## in the fixed order. Leaves the solver holding that grade.
static func _grades_at(givens: PackedInt32Array, target: int, solver: TechniqueSolver) -> bool:
	if not solver.load_givens(givens) or not solver.run(TechniqueSolver.MAX_LEVEL):
		return false
	var hardest: int = solver.hardest_technique()
	if hardest == TechniqueSolver.NO_STEP or TechniqueSolver.TECHNIQUE_LEVELS[hardest] != target:
		return false
	# Beginner needs a hidden single, not only last empty cells (GDD 11.2).
	return target != 0 or solver.technique_count(TechniqueSolver.HIDDEN_SINGLE) > 0
