extends RefCounted
## Shared helpers for the save and ui tests: a scratch folder under user://
## per test, raw file writes for damaged data, and a valid session to save.
## Not a test file.

const ROOT: String = "user://test_scratch"


## An empty folder of its own under user://test_scratch.
static func fresh_dir(tag: String) -> String:
	var dir: String = ROOT.path_join("%s_%d" % [tag, Time.get_ticks_usec()])
	wipe(dir)
	DirAccess.make_dir_recursive_absolute(dir)
	return dir


## Deletes every file in dir, then dir itself.
static func wipe(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for file: String in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file))
	DirAccess.remove_absolute(dir)


static func write_text(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


static func write_bytes(path: String, bytes: PackedByteArray) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()


static func read_text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


## The JSON text of a save file holding data.
static func wrap(data: Variant) -> String:
	return JSON.stringify({"format": 1, "data": data})


## A new Beginner session from a fixed seed, with some play on it: two
## placements, a cross, a restore, a hint bought, Cross Out mode and a cell
## selected.
static func played_session() -> GameSession:
	var puzzle: Puzzle = PuzzleSource.get_puzzle(Levels.BEGINNER, 7)
	var session: GameSession = GameSession.create(puzzle.id, puzzle.level, puzzle.givens, puzzle.solution, false)
	var empties: PackedInt32Array = empty_cells(session)
	session.select(empties[0])
	session.press_digit(puzzle.solution[empties[0]])
	session.select(empties[1])
	session.press_digit(puzzle.solution[empties[1]] % 9 + 1)
	session.set_mode(GameSession.Mode.CROSS_OUT)
	session.select(empties[2])
	session.press_digit(1)
	session.press_digit(2)
	session.press_digit(2)
	session.add_time(83.5)
	session.buy_hint(NextStep.find(session.solution, session.board))
	return session


static func empty_cells(session: GameSession) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for cell: int in Sudoku.CELLS:
		if session.board.digits[cell] == 0:
			out.append(cell)
	return out


## Fills every empty cell with its solution digit, which completes the puzzle.
static func solve(session: GameSession) -> void:
	session.set_mode(GameSession.Mode.PLACE)
	for cell: int in Sudoku.CELLS:
		if session.board.digits[cell] != session.solution[cell]:
			session.select(cell)
			session.press_digit(session.solution[cell])
