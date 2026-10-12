class_name PuzzleSource
extends RefCounted
## Where the game gets a puzzle (docs/ARCHITECTURE.md section 5).
##
## Beginner to Hard are generated on the device. Expert seeds 1 to
## EXPERT_BANK_SIZE come from the pre-built bank in expert_bank.gd, which
## holds the givens PuzzleGenerator.generate(4, k) makes for those seeds, so
## the ids and puzzles are exactly what generating would give, only without
## the wait. A bank line that fails validation is generated instead.
##
## Only static functions, no state, so it is safe on a worker thread.

const ExpertBank := preload("res://src/puzzles/expert_bank.gd")
const EXPERT_BANK_SIZE := 1000
const EXPERT: int = 4
const CELL_COUNT: int = 81


## The seed for a new puzzle. random_u32 is any random int, for example
## randi(). Beginner to Hard: its low 32 bits (0 to PuzzleId.MAX_SEED).
## Expert: 1 + random_u32 % EXPERT_BANK_SIZE, a bank seed. A level outside 0
## to 4 is clamped, as the generator does.
static func pick_seed(level: int, random_u32: int) -> int:
	var value: int = random_u32 & PuzzleId.MAX_SEED
	if clampi(level, 0, EXPERT) == EXPERT:
		return 1 + value % EXPERT_BANK_SIZE
	return value


## The puzzle for a level and seed. Same level and seed always give the same
## puzzle. Never crashes: a bad bank line falls back to generating.
static func get_puzzle(level: int, seed_value: int) -> Puzzle:
	var target: int = clampi(level, 0, EXPERT)
	var seed_used: int = seed_value & PuzzleId.MAX_SEED
	if target == EXPERT and seed_used >= 1 and seed_used <= EXPERT_BANK_SIZE:
		var puzzle: Puzzle = _from_bank(seed_used)
		if puzzle != null:
			return puzzle
	return PuzzleGenerator.generate(target, seed_used)


## The givens of a bank line, or an empty array unless the line is exactly 81
## ASCII digits 0 to 9 and has exactly one solution.
static func givens_from_line(line: String) -> PackedInt32Array:
	var none: PackedInt32Array = PackedInt32Array()
	if line.length() != CELL_COUNT:
		return none
	var givens: PackedInt32Array = PackedInt32Array()
	givens.resize(CELL_COUNT)
	for i: int in CELL_COUNT:
		var code: int = line.unicode_at(i)
		if code < 48 or code > 57:
			return none
		givens[i] = code - 48
	if Solver.count_solutions(givens, 2) != 1:
		return none
	return givens


## The bank line for an Expert seed from 1 to EXPERT_BANK_SIZE, or "" if the
## bank has no such line.
static func bank_line(seed_value: int) -> String:
	var lines: PackedStringArray = ExpertBank.LINES
	if seed_value < 1 or seed_value > lines.size():
		return ""
	return lines[seed_value - 1]


static func _from_bank(seed_value: int) -> Puzzle:
	var givens: PackedInt32Array = givens_from_line(bank_line(seed_value))
	if givens.is_empty():
		push_warning("Expert bank line %d is invalid; generating instead." % seed_value)
		return null
	var solution: PackedInt32Array = Solver.solve(givens)
	if solution.size() != CELL_COUNT:
		return null
	var puzzle: Puzzle = Puzzle.new()
	puzzle.level = EXPERT
	puzzle.seed = seed_value
	puzzle.id = PuzzleId.make(EXPERT, seed_value)
	puzzle.givens = givens
	puzzle.solution = solution
	puzzle.hardest = TechniqueSolver.grade(givens).hardest
	return puzzle
