extends "res://tests/unit_test.gd"
## PuzzleGenerator: a small sample per level, each with exactly one solution
## and graded at its level (GDD AT-49), plus reproducibility from level and
## seed.

const KnownPuzzles := preload("res://tests/puzzles/known_puzzles.gd")
const TS := preload("res://src/puzzles/technique_solver.gd")


func test_sample_beginner() -> void:
	for seed_value: int in [1, 2, 3, 4, 5, 6]:
		check_puzzle(PuzzleGenerator.generate(0, seed_value), 0, seed_value)


func test_sample_easy() -> void:
	for seed_value: int in [1, 2, 3, 4, 5, 6]:
		check_puzzle(PuzzleGenerator.generate(1, seed_value), 1, seed_value)


func test_sample_medium() -> void:
	for seed_value: int in [1, 2, 3, 4, 5]:
		check_puzzle(PuzzleGenerator.generate(2, seed_value), 2, seed_value)


func test_sample_hard() -> void:
	for seed_value: int in [1, 2, 3, 4]:
		check_puzzle(PuzzleGenerator.generate(3, seed_value), 3, seed_value)


## Expert seeds that generate quickly, so the suite stays fast. The timing
## tool covers slow seeds.
func test_sample_expert() -> void:
	for seed_value: int in [1, 3, 6, 14, 27]:
		check_puzzle(PuzzleGenerator.generate(4, seed_value), 4, seed_value)


func test_same_level_and_seed_give_the_same_puzzle() -> void:
	for level: int in [0, 2, 3]:
		var a: Puzzle = PuzzleGenerator.generate(level, 4242)
		var b: Puzzle = PuzzleGenerator.generate(level, 4242)
		assert_eq(a.id, b.id)
		assert_eq(a.givens, b.givens, "level %d givens" % level)
		assert_eq(a.solution, b.solution, "level %d solution" % level)
		assert_eq(a.hardest, b.hardest)


func test_known_puzzles_are_reproduced_exactly() -> void:
	# If this fails, the generator changed and old IDs would give different
	# puzzles. That needs a new PuzzleId version, not a new golden value.
	var beginner: Puzzle = PuzzleGenerator.generate(0, 1)
	assert_eq(beginner.givens, KnownPuzzles.BEGINNER_1_GIVENS, "1.0.1 givens")
	var expert: Puzzle = PuzzleGenerator.generate(4, KnownPuzzles.EXPERT_SEED)
	assert_eq(expert.givens, KnownPuzzles.EXPERT_GIVENS, "expert givens")
	assert_eq(expert.solution, KnownPuzzles.EXPERT_SOLUTION, "expert solution")
	assert_eq(expert.hardest, KnownPuzzles.EXPERT_HARDEST)


func test_different_seeds_give_different_puzzles() -> void:
	assert_ne(PuzzleGenerator.generate(1, 1).givens, PuzzleGenerator.generate(1, 2).givens)
	assert_ne(PuzzleGenerator.generate(0, 7).solution, PuzzleGenerator.generate(1, 7).solution, "levels use different sequences")


func test_level_is_clamped_and_seed_is_32_bit() -> void:
	var low: Puzzle = PuzzleGenerator.generate(-3, 5)
	assert_eq(low.level, 0)
	assert_eq(low.givens, PuzzleGenerator.generate(0, 5).givens)
	var wide: Puzzle = PuzzleGenerator.generate(0, (1 << 32) + 5)
	assert_eq(wide.seed, 5)
	assert_eq(wide.id, "1.0.5")
	assert_eq(wide.givens, low.givens)
	var negative: Puzzle = PuzzleGenerator.generate(0, -1)
	assert_eq(negative.seed, PuzzleId.MAX_SEED)
	assert_false(PuzzleId.parse(negative.id).is_empty(), "id parses")


func test_worker_thread_gives_the_same_puzzle() -> void:
	var thread: Thread = Thread.new()
	thread.start(generate_on_thread.bind(2, 77))
	var from_thread: Puzzle = thread.wait_to_finish()
	var from_main: Puzzle = PuzzleGenerator.generate(2, 77)
	assert_eq(from_thread.givens, from_main.givens)
	assert_eq(from_thread.solution, from_main.solution)


func generate_on_thread(level: int, seed_value: int) -> Puzzle:
	return PuzzleGenerator.generate(level, seed_value)


func test_stats_count_attempts() -> void:
	var stats: Dictionary = PuzzleGenerator.generate_with_stats(1, 3)
	assert_true(stats["attempts"] >= 1)
	assert_eq((stats["puzzle"] as Puzzle).givens, PuzzleGenerator.generate(1, 3).givens)


func check_puzzle(puzzle: Puzzle, level: int, seed_value: int) -> void:
	var label: String = "level %d seed %d" % [level, seed_value]
	assert_eq(puzzle.level, level, label)
	assert_eq(puzzle.seed, seed_value, label)
	assert_eq(puzzle.id, PuzzleId.make(level, seed_value), label)
	assert_eq(PuzzleId.parse(puzzle.id), {"version": 1, "level": level, "seed": seed_value}, label)
	assert_true(KnownPuzzles.is_valid_solution(puzzle.solution), "%s: solution is a valid grid" % label)
	assert_eq(puzzle.givens.size(), 81, label)
	for i: int in 81:
		var given: int = puzzle.givens[i]
		if given != 0 and given != puzzle.solution[i]:
			fail("%s: given at %d is not the solution's digit" % [label, i])
			break
	assert_eq(Solver.count_solutions(puzzle.givens, 2), 1, "%s: exactly one solution" % label)
	assert_eq(Solver.solve(puzzle.givens), puzzle.solution, label)
	var grade: GradeResult = TechniqueSolver.grade(puzzle.givens)
	assert_true(grade.solved, "%s: techniques finish it" % label)
	assert_eq(grade.level, level, "%s: grade" % label)
	assert_eq(grade.hardest, puzzle.hardest, label)
	for technique: StringName in grade.technique_counts:
		var technique_level: int = TS.TECHNIQUE_LEVELS[TS.TECHNIQUES.find(technique)]
		assert_true(technique_level <= level, "%s: %s is above the level" % [label, technique])
	var needs: Array = KnownPuzzles.NEEDS[level]
	var used_needed: bool = false
	for technique: StringName in needs:
		if grade.technique_counts.get(technique, 0) > 0:
			used_needed = true
	assert_true(used_needed, "%s: uses a technique the level needs" % label)
