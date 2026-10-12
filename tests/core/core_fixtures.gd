extends RefCounted
## Shared positions for the core tests. Not a test file (no test_ prefix).

## Position B (GDD 4.4) as givens: r5c1 9, r5c8 3, r1c5 4, r8c5 6, r4c4 2,
## r4c6 4, r6c6 3.
const POSITION_B := [[5, 1, 9], [5, 8, 3], [1, 5, 4], [8, 5, 6], [4, 4, 2], [4, 6, 4], [6, 6, 3]]
## One full grid that agrees with Position B, so create() accepts it.
const SOLUTION_B := "735146892691528347482739651378254169924617538156893274869371425517462983243985716"


## Cell index from the GDD's 1-based rXcY.
static func rc(row: int, col: int) -> int:
	return (row - 1) * 9 + (col - 1)


static func grid(text: String) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(81)
	for i: int in 81:
		var ch: String = text[i]
		out[i] = 0 if ch == "." else int(ch)
	return out


static func empty_grid() -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(81)
	out.fill(0)
	return out


static func position_b_givens() -> PackedInt32Array:
	var out: PackedInt32Array = empty_grid()
	for entry: Array in POSITION_B:
		out[rc(entry[0], entry[1])] = entry[2]
	return out


static func solution_b() -> PackedInt32Array:
	return grid(SOLUTION_B)


## A Beginner session on Position B.
static func session_b(auto_cross: bool) -> GameSession:
	return GameSession.create("1.0.7", Levels.BEGINNER, position_b_givens(), solution_b(), auto_cross)


## A puzzle that is SOLUTION_B with the given cells left empty.
static func session_with_holes(holes: Array[int], level: int = Levels.BEGINNER) -> GameSession:
	var solution: PackedInt32Array = solution_b()
	var givens: PackedInt32Array = solution.duplicate()
	for cell: int in holes:
		givens[cell] = 0
	return GameSession.create("1.%d.9" % level, level, givens, solution, false)


## Selects a cell, sets the mode and presses a digit.
static func tap(session: GameSession, cell: int, mode: int, digit: int) -> ActionResult:
	session.select(cell)
	session.set_mode(mode)
	return session.press_digit(digit)


static func place(session: GameSession, cell: int, digit: int) -> ActionResult:
	return tap(session, cell, GameSession.Mode.PLACE, digit)


static func cross(session: GameSession, cell: int, digit: int) -> ActionResult:
	return tap(session, cell, GameSession.Mode.CROSS_OUT, digit)


static func erase_at(session: GameSession, cell: int) -> ActionResult:
	session.select(cell)
	return session.erase()


## The digits of a cell whose mark equals the given Mark.
static func digits_with(board: Board, cell: int, mark: int) -> Array[int]:
	var out: Array[int] = []
	for d: int in range(1, 10):
		if board.mark(cell, d) == mark:
			out.append(d)
	return out


## Records every signal a session emits, in order, as short strings.
class SignalLog extends RefCounted:
	var events: Array[String] = []

	func watch(session: GameSession) -> void:
		session.board_changed.connect(func(cells: PackedInt32Array) -> void: events.append("board"))
		session.selection_changed.connect(func(cell: int) -> void: events.append("selection:%d" % cell))
		session.mode_changed.connect(func(mode: int) -> void: events.append("mode:%d" % mode))
		session.score_changed.connect(func(score: int) -> void: events.append("score:%d" % score))
		session.hint_changed.connect(func(hint: Hint) -> void: events.append("hint:%s" % ("null" if hint == null else "on")))
		session.undo_available_changed.connect(func(available: bool) -> void: events.append("undo:%s" % available))
		session.full_board_conflict.connect(func() -> void: events.append("full_conflict"))
		session.completed.connect(func(seconds: int, score: int) -> void: events.append("completed:%d:%d" % [seconds, score]))
