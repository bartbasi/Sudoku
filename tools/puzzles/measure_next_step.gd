extends SceneTree
## Measures NextStep.find on Expert boards (docs/GENERATION_TIMING.md), for
## the 50 ms phone target in docs/ARCHITECTURE.md section 5.
##
##   timeout 900 godot --headless --path . --script res://tools/puzzles/measure_next_step.gd
##
## For each bank puzzle 1 to PUZZLE_COUNT, a player follows every hint from
## the start to the end: places each placement and crosses each elimination.
## Every find() on the way is timed, in two ways:
## - open ring: the player crossed only what hints told them to;
## - crossed ring: the same position, but every candidate that is not the
##   solution is crossed by hand, so every elimination step is already done
##   and find() must apply all of them silently before it reaches a
##   placement. This is the most work find() can have on that position.

const PUZZLE_COUNT: int = 20


func _initialize() -> void:
	print("NextStep.find timing on Expert boards")
	print("Godot %s, %s build, %s" % [Engine.get_version_info()["string"], "debug" if OS.is_debug_build() else "release", OS.get_processor_name()])
	var open_times: Array[float] = []
	var crossed_times: Array[float] = []
	for k: int in range(1, PUZZLE_COUNT + 1):
		var puzzle: Puzzle = PuzzleSource.get_puzzle(4, k)
		var board: Board = Board.create(puzzle.givens)
		while not board.is_full():
			var t0: int = Time.get_ticks_usec()
			var hint: Hint = NextStep.find(puzzle.solution, board)
			open_times.append((Time.get_ticks_usec() - t0) / 1000.0)
			var crossed: Board = _all_wrong_crossed(board, puzzle.solution)
			t0 = Time.get_ticks_usec()
			NextStep.find(puzzle.solution, crossed)
			crossed_times.append((Time.get_ticks_usec() - t0) / 1000.0)
			if hint.placement_cell >= 0:
				board.digits[hint.placement_cell] = hint.placement_digit
			elif not hint.eliminations.is_empty():
				for mark: int in hint.eliminations:
					board.marks[mark] = Board.Mark.CROSSED_HAND
			else:
				printerr("%s: no step (%s)" % [puzzle.id, hint.technique])
				quit(1)
				return
	print("| Ring | Calls | Mean ms | 90th pct ms | Worst ms |")
	print("| --- | --- | --- | --- | --- |")
	print(_row("open", open_times))
	print(_row("every wrong candidate crossed", crossed_times))
	quit(0)


func _all_wrong_crossed(board: Board, solution: PackedInt32Array) -> Board:
	var copy: Board = board.duplicate_board()
	for i: int in 81:
		if copy.digits[i] != 0:
			continue
		for d: int in range(1, 10):
			if d != solution[i]:
				copy.marks[i * 9 + d - 1] = Board.Mark.CROSSED_HAND
	return copy


func _row(label: String, times: Array[float]) -> String:
	var sorted: Array[float] = times.duplicate()
	sorted.sort()
	var total: float = 0.0
	for ms: float in sorted:
		total += ms
	var n: int = sorted.size()
	var p90: float = sorted[clampi(ceili(0.9 * n) - 1, 0, n - 1)]
	return "| %s | %d | %.2f | %.2f | %.2f |" % [label, n, total / n, p90, sorted[n - 1]]
