extends SceneTree
## Builds the Expert bank, src/puzzles/expert_bank.gd (docs/ARCHITECTURE.md
## section 5). Line k is the 81 givens of PuzzleGenerator.generate(4, k), for
## k from 1 to PuzzleSource.EXPERT_BANK_SIZE. Never edit the bank by hand.
##
##   timeout 3600 godot --headless --path . --script res://tools/puzzles/build_expert_bank.gd
##
## Optional arguments after "--": a seed count and an output path, for a quick
## trial run, for example "-- 10 user://bank_trial.gd". The real bank always
## uses the defaults.
##
## Seeds are shared out over worker threads (the generator is thread safe).
## Every line is checked with PuzzleSource.givens_from_line, the same check
## the game uses, and against the generator's solution and level before the
## file is written. Exits 1 if any check fails, and then writes nothing.

const OUT_PATH: String = "res://src/puzzles/expert_bank.gd"
const EXPERT: int = 4


func _initialize() -> void:
	var result: Variant = call("_run")
	quit(result if result is int else 1)


func _run() -> int:
	var count: int = PuzzleSource.EXPERT_BANK_SIZE
	var out_path: String = OUT_PATH
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() >= 1:
		count = clampi(args[0].to_int(), 1, PuzzleSource.EXPERT_BANK_SIZE)
	if args.size() >= 2:
		out_path = args[1]
	var thread_count: int = clampi(OS.get_processor_count() - 1, 1, 16)
	print("Building %d Expert puzzles on %d threads into %s" % [count, thread_count, out_path])
	var start_ms: int = Time.get_ticks_msec()

	var threads: Array[Thread] = []
	for t: int in thread_count:
		var thread: Thread = Thread.new()
		thread.start(_build_part.bind(t, thread_count, count))
		threads.append(thread)
	var lines: PackedStringArray = PackedStringArray()
	lines.resize(count)
	var failures: int = 0
	for t: int in thread_count:
		var part: Dictionary = threads[t].wait_to_finish()
		failures += int(part["failures"])
		var part_lines: PackedStringArray = part["lines"]
		for j: int in part_lines.size():
			lines[t + j * thread_count] = part_lines[j]
	var build_s: float = (Time.get_ticks_msec() - start_ms) / 1000.0
	if failures > 0:
		printerr("%d lines failed their checks. Nothing written." % failures)
		return 1

	var text: String = "extends RefCounted\n"
	text += "## The Expert bank. Written by tools/puzzles/build_expert_bank.gd; never edit\n"
	text += "## by hand. LINES[k - 1] is the 81 givens of PuzzleGenerator.generate(4, k),\n"
	text += "## row by row, 0 for an empty cell. Read only through PuzzleSource.\n\n"
	text += "const LINES: PackedStringArray = [\n"
	for line: String in lines:
		text += "\t\"%s\",\n" % line
	text += "]\n"
	var file: FileAccess = FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		printerr("Cannot write %s (error %d)." % [out_path, FileAccess.get_open_error()])
		return 1
	file.store_string(text)
	file.close()
	print("Wrote %d lines, %d bytes (%.1f KB), in %.0f s." % [count, text.length(), text.length() / 1024.0, build_s])
	return 0


## Generates the seeds t + 1, t + 1 + n, t + 1 + 2n, and so on, and checks
## each line. Returns {"lines": PackedStringArray, "failures": int}.
func _build_part(t: int, n: int, count: int) -> Dictionary:
	var lines: PackedStringArray = PackedStringArray()
	var failures: int = 0
	var k: int = t + 1
	while k <= count:
		var puzzle: Puzzle = PuzzleGenerator.generate(EXPERT, k)
		var line: String = ""
		for value: int in puzzle.givens:
			line += str(value)
		var givens: PackedInt32Array = PuzzleSource.givens_from_line(line)
		var grade: GradeResult = TechniqueSolver.grade(givens)
		if givens != puzzle.givens or Solver.solve(givens) != puzzle.solution or grade.level != EXPERT:
			printerr("Seed %d failed its checks." % k)
			failures += 1
		lines.append(line)
		k += n
	return {"lines": lines, "failures": failures}
