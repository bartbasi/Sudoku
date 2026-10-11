extends SceneTree
## Measures puzzle generation time per level on this machine, for the Hard
## Stop 2 decision (docs/GENERATION_TIMING.md).
##
##   timeout 3000 godot --headless --path . --script res://tools/puzzles/measure_generation.gd
##
## Each level generates a fixed list of seeds (FIRST_SEED and up), timing only
## the generate call. Every puzzle is then checked outside the timer: exactly
## one solution and graded at its level. A level stops early if it uses up its
## time budget, and the table says how many it finished. Exits 1 if any check
## failed.

const LEVEL_NAMES: Array[String] = ["Beginner", "Easy", "Medium", "Hard", "Expert"]
const FIRST_SEED: int = 1
## Seeds per level. More for the fast levels.
const SEED_COUNTS: PackedInt32Array = [500, 500, 300, 200, 100]
## Seconds each level may use before it stops early. Total at most 2100 s.
const BUDGET_SECONDS: PackedInt32Array = [150, 150, 300, 500, 1000]


func _initialize() -> void:
	var result: Variant = call("_run")
	quit(result if result is int else 1)


func _run() -> int:
	print("Puzzle generation timing")
	print("Godot %s, %s build" % [Engine.get_version_info()["string"], "debug" if OS.is_debug_build() else "release"])
	print("%s, %s, %d logical cores" % [OS.get_name(), OS.get_processor_name(), OS.get_processor_count()])
	print("")
	var rows: PackedStringArray = PackedStringArray()
	var failures: int = 0
	var run_start: int = Time.get_ticks_msec()
	for level: int in LEVEL_NAMES.size():
		var times: Array[float] = []
		var attempts: int = 0
		var givens_total: int = 0
		var hardest: Dictionary = {}
		var level_start: int = Time.get_ticks_msec()
		for k: int in SEED_COUNTS[level]:
			if Time.get_ticks_msec() - level_start > BUDGET_SECONDS[level] * 1000:
				break
			var seed_value: int = FIRST_SEED + k
			var t0: int = Time.get_ticks_usec()
			var stats: Dictionary = PuzzleGenerator.generate_with_stats(level, seed_value)
			var ms: float = (Time.get_ticks_usec() - t0) / 1000.0
			var puzzle: Puzzle = stats["puzzle"]
			times.append(ms)
			attempts += stats["attempts"]
			for value: int in puzzle.givens:
				if value != 0:
					givens_total += 1
			hardest[puzzle.hardest] = hardest.get(puzzle.hardest, 0) + 1
			if not _check(puzzle, level):
				failures += 1
				print("CHECK FAILED %s" % puzzle.id)
		var count: int = times.size()
		var total_ms: float = 0.0
		for ms: float in times:
			total_ms += ms
		times.sort()
		var row: String = "| %s | %d of %d | %.0f | %.0f | %.0f | %.0f | %.2f | %.1f%% | %.1f |" % [
			LEVEL_NAMES[level], count, SEED_COUNTS[level], total_ms / count, _median(times),
			_percentile(times, 0.9), times[count - 1], float(attempts) / count,
			100.0 * count / attempts, float(givens_total) / count,
		]
		rows.append(row)
		print(row)
		print("    hardest technique: %s" % _describe_counts(hardest, count))
	print("")
	print("| Level | Puzzles | Mean ms | Median ms | 90th pct ms | Worst ms | Attempts per puzzle | Hit rate per attempt | Mean givens |")
	print("| --- | --- | --- | --- | --- | --- | --- | --- | --- |")
	for row: String in rows:
		print(row)
	print("")
	print("Total run %.0f s. Checks failed: %d." % [(Time.get_ticks_msec() - run_start) / 1000.0, failures])
	return 0 if failures == 0 else 1


## Exactly one solution, the stored solution, and graded at its level.
func _check(puzzle: Puzzle, level: int) -> bool:
	if Solver.count_solutions(puzzle.givens, 2) != 1:
		return false
	if Solver.solve(puzzle.givens) != puzzle.solution:
		return false
	var grade: GradeResult = TechniqueSolver.grade(puzzle.givens)
	return grade.solved and grade.level == level and grade.hardest == puzzle.hardest


func _median(sorted: Array[float]) -> float:
	var n: int = sorted.size()
	if n % 2 == 1:
		return sorted[n / 2]
	return (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0


## Nearest rank: the smallest value with at least share of the values at or
## below it.
func _percentile(sorted: Array[float], share: float) -> float:
	var rank: int = ceili(share * sorted.size())
	return sorted[clampi(rank - 1, 0, sorted.size() - 1)]


func _describe_counts(counts: Dictionary, total: int) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for key: StringName in counts:
		parts.append("%s %d (%.0f%%)" % [key, counts[key], 100.0 * counts[key] / total])
	return ", ".join(parts)
