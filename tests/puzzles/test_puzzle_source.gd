extends "res://tests/unit_test.gd"
## PuzzleSource and the Expert bank (docs/ARCHITECTURE.md section 5).

const KnownPuzzles := preload("res://tests/puzzles/known_puzzles.gd")
const ExpertBank := preload("res://src/puzzles/expert_bank.gd")

## Bank seeds whose generation is quick, so the comparison stays fast.
const QUICK_BANK_SEEDS: Array[int] = [1, 3, 6, 14, 27]
## Expert seeds outside the bank that generate quickly.
const QUICK_OTHER_EXPERT_SEEDS: Array[int] = [1003, 1005]


func test_pick_seed_below_expert_is_the_random_value() -> void:
	for level: int in [0, 1, 2, 3]:
		for value: int in [0, 1, 999, 1000, 123456789, PuzzleId.MAX_SEED]:
			assert_eq(PuzzleSource.pick_seed(level, value), value, "level %d value %d" % [level, value])
	# Only the low 32 bits are used, so the seed always fits an id.
	assert_eq(PuzzleSource.pick_seed(2, (1 << 32) + 7), 7)
	assert_eq(PuzzleSource.pick_seed(0, -1), PuzzleId.MAX_SEED)


func test_pick_seed_for_expert_is_a_bank_seed() -> void:
	assert_eq(PuzzleSource.pick_seed(4, 0), 1)
	assert_eq(PuzzleSource.pick_seed(4, 999), 1000)
	assert_eq(PuzzleSource.pick_seed(4, 1000), 1)
	assert_eq(PuzzleSource.pick_seed(4, PuzzleId.MAX_SEED), 296)
	assert_eq(PuzzleSource.pick_seed(4, -1), 296)
	var rng: SeededRng = SeededRng.new(99)
	for k: int in 500:
		var seed_value: int = PuzzleSource.pick_seed(4, rng.next_u32())
		if seed_value < 1 or seed_value > PuzzleSource.EXPERT_BANK_SIZE:
			fail("Expert seed %d is outside the bank" % seed_value)
			return


func test_pick_seed_clamps_the_level() -> void:
	assert_eq(PuzzleSource.pick_seed(9, 0), 1, "above Expert counts as Expert")
	assert_eq(PuzzleSource.pick_seed(-2, 5000), 5000)


func test_bank_has_one_line_per_seed() -> void:
	assert_eq(ExpertBank.LINES.size(), PuzzleSource.EXPERT_BANK_SIZE)


func test_every_bank_line_is_valid() -> void:
	var bad: int = 0
	for k: int in range(1, PuzzleSource.EXPERT_BANK_SIZE + 1):
		if PuzzleSource.givens_from_line(PuzzleSource.bank_line(k)).is_empty():
			bad += 1
			if bad <= 5:
				fail("bank line %d is invalid" % k)
	assert_eq(bad, 0, "invalid bank lines")


func test_bank_matches_the_generator() -> void:
	for k: int in QUICK_BANK_SEEDS:
		var label: String = "seed %d" % k
		var from_bank: Puzzle = PuzzleSource.get_puzzle(4, k)
		var generated: Puzzle = PuzzleGenerator.generate(4, k)
		assert_eq(from_bank.id, generated.id, label)
		assert_eq(from_bank.level, 4, label)
		assert_eq(from_bank.seed, k, label)
		assert_eq(from_bank.givens, generated.givens, label)
		assert_eq(from_bank.solution, generated.solution, label)
		assert_eq(from_bank.hardest, generated.hardest, label)


func test_bank_seed_1_is_the_fixed_copy() -> void:
	var puzzle: Puzzle = PuzzleSource.get_puzzle(4, KnownPuzzles.EXPERT_SEED)
	assert_eq(puzzle.id, "1.4.1")
	assert_eq(puzzle.givens, KnownPuzzles.EXPERT_GIVENS)
	assert_eq(puzzle.solution, KnownPuzzles.EXPERT_SOLUTION)
	assert_eq(puzzle.hardest, KnownPuzzles.EXPERT_HARDEST)


func test_bank_puzzles_grade_expert() -> void:
	for k: int in [2, 500, 1000]:
		var puzzle: Puzzle = PuzzleSource.get_puzzle(4, k)
		assert_eq(puzzle.id, "1.4.%d" % k)
		assert_true(KnownPuzzles.is_valid_solution(puzzle.solution), "seed %d solution" % k)
		var grade: GradeResult = TechniqueSolver.grade(puzzle.givens)
		assert_eq(grade.level, 4, "seed %d grade" % k)
		assert_eq(grade.hardest, puzzle.hardest)


func test_validator_accepts_a_good_line() -> void:
	var line: String = to_line(KnownPuzzles.EXPERT_GIVENS)
	assert_eq(PuzzleSource.givens_from_line(line), KnownPuzzles.EXPERT_GIVENS)


func test_validator_rejects_bad_lines() -> void:
	var good: String = to_line(KnownPuzzles.EXPERT_GIVENS)
	var bad: Dictionary = {
		"empty": "",
		"too short": good.substr(0, 80),
		"too long": good + "0",
		"a letter": "a" + good.substr(1),
		"a dot": "." + good.substr(1),
		"a space": " " + good.substr(1),
		"a minus": "-" + good.substr(1),
		"a non-ASCII digit": String.chr(0x0663) + good.substr(1),
		"a repeated digit": "99" + good.substr(2),
		"many solutions": "0".repeat(81),
		"no solution": "12345678" + "0".repeat(8) + "9" + "0".repeat(64),
	}
	for label: String in bad:
		assert_eq(PuzzleSource.givens_from_line(bad[label]), PackedInt32Array(), label)


func test_bank_line_outside_the_bank_is_empty() -> void:
	assert_eq(PuzzleSource.bank_line(0), "")
	assert_eq(PuzzleSource.bank_line(PuzzleSource.EXPERT_BANK_SIZE + 1), "")
	assert_eq(PuzzleSource.bank_line(-5), "")


func test_expert_seeds_outside_the_bank_are_generated() -> void:
	for k: int in QUICK_OTHER_EXPERT_SEEDS:
		var from_source: Puzzle = PuzzleSource.get_puzzle(4, k)
		var generated: Puzzle = PuzzleGenerator.generate(4, k)
		assert_eq(from_source.id, "1.4.%d" % k)
		assert_eq(from_source.givens, generated.givens, "seed %d" % k)
		assert_eq(from_source.solution, generated.solution, "seed %d" % k)


func test_other_levels_are_generated() -> void:
	for level: int in [0, 1, 2, 3]:
		for k: int in [1, 77]:
			var from_source: Puzzle = PuzzleSource.get_puzzle(level, k)
			var generated: Puzzle = PuzzleGenerator.generate(level, k)
			assert_eq(from_source.id, generated.id)
			assert_eq(from_source.givens, generated.givens, "level %d seed %d" % [level, k])
			assert_eq(from_source.solution, generated.solution)


func test_same_level_and_seed_give_the_same_puzzle() -> void:
	var a: Puzzle = PuzzleSource.get_puzzle(4, 321)
	var b: Puzzle = PuzzleSource.get_puzzle(4, 321)
	assert_eq(a.givens, b.givens)
	assert_eq(a.solution, b.solution)
	assert_eq(a.hardest, b.hardest)


func test_worker_thread_gives_the_same_puzzle() -> void:
	var thread: Thread = Thread.new()
	thread.start(get_on_thread.bind(4, 42))
	var from_thread: Puzzle = thread.wait_to_finish()
	var from_main: Puzzle = PuzzleSource.get_puzzle(4, 42)
	assert_eq(from_thread.givens, from_main.givens)
	assert_eq(from_thread.solution, from_main.solution)


func get_on_thread(level: int, seed_value: int) -> Puzzle:
	return PuzzleSource.get_puzzle(level, seed_value)


static func to_line(givens: PackedInt32Array) -> String:
	var line: String = ""
	for value: int in givens:
		line += str(value)
	return line
