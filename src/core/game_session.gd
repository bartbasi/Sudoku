class_name GameSession
extends RefCounted
## The whole state of one puzzle or one lesson board, and every rule that
## changes it (GDD sections 2 to 10 and 12).
##
## Signal order: board_changed always comes first, then selection_changed,
## hint_changed, score_changed and undo_available_changed as they apply, and
## completed or full_board_conflict last. State is fully updated before the
## first signal, so a listener that saves on board_changed already sees
## is_completed.
##
## The session never reads the solution; it only stores it for hints.
## A lesson session (level -1) keeps Auto Cross off and has no timer, score,
## hints or completion (GDD 15.4).

const DataCheck := preload("res://src/core/data_check.gd")

enum Mode { PLACE = 0, CROSS_OUT = 1 }

## Upper bound for a saved timer: about 31 years.
const MAX_ELAPSED := 1.0e9
const MAX_PUZZLE_ID_LENGTH := DataCheck.MAX_PUZZLE_ID_LENGTH

signal board_changed(cells: PackedInt32Array)
signal selection_changed(cell: int)
signal mode_changed(mode: int)
signal score_changed(score: int)
signal hint_changed(hint: Hint)
signal undo_available_changed(available: bool)
signal full_board_conflict()
signal completed(final_seconds: int, final_score: int)

var puzzle_id: String = ""
var level: int = -1
var solution: PackedInt32Array = PackedInt32Array()
var board: Board = null
var mode: int = Mode.PLACE
var selected: int = -1
var auto_cross: bool = false
var elapsed: float = 0.0
var hints_bought: int = 0
var hint: Hint = null
var is_completed: bool = false

var _undo: Array[UndoStep] = []


## A new puzzle: no cell selected, Place mode, timer at 0, no hints. With
## Auto Cross on, its rules run at once (not an undo step). Returns null if
## the level is not 0 to 4, givens is not a grid, or solution is not a
## complete solution that agrees with every given.
static func create(new_puzzle_id: String, new_level: int, givens: PackedInt32Array, new_solution: PackedInt32Array, new_auto_cross: bool) -> GameSession:
	if not Levels.is_valid(new_level) or not _solution_fits(new_solution, givens):
		return null
	var session: GameSession = GameSession.new()
	session.puzzle_id = new_puzzle_id
	session.level = new_level
	session.solution = new_solution.duplicate()
	session.board = Board.create(givens)
	session.auto_cross = new_auto_cross
	if new_auto_cross:
		session._run_auto_cross()
	return session


## Wraps a lesson board as it is (not copied). An invalid mode becomes Place
## and an invalid selection becomes -1. Null if board is null.
static func for_lesson(lesson_board: Board, new_mode: int, new_selected: int) -> GameSession:
	if lesson_board == null:
		return null
	var session: GameSession = GameSession.new()
	session.board = lesson_board
	session.mode = new_mode if new_mode == Mode.CROSS_OUT else Mode.PLACE
	session.selected = new_selected if Sudoku.is_cell(new_selected) else -1
	return session


# Selection and mode -----------------------------------------------------------

## Selects any cell, given or not (GDD 2.2). Ignored outside 0 to 80 and
## once the puzzle is complete.
func select(cell: int) -> void:
	if is_completed or not Sudoku.is_cell(cell) or cell == selected:
		return
	selected = cell
	selection_changed.emit(selected)


## Not an undo step; the board and selection stay (GDD 3.3).
func set_mode(new_mode: int) -> void:
	if is_completed or (new_mode != Mode.PLACE and new_mode != Mode.CROSS_OUT) or new_mode == mode:
		return
	mode = new_mode
	mode_changed.emit(mode)


func toggle_mode() -> void:
	set_mode(Mode.CROSS_OUT if mode == Mode.PLACE else Mode.PLACE)


# Actions ----------------------------------------------------------------------

## Place mode places or replaces; Cross Out mode crosses or restores (GDD 3.2).
func press_digit(d: int) -> ActionResult:
	if not _can_act() or d < 1 or d > 9:
		return ActionResult.new()
	var cell: int = selected
	if board.is_given(cell):
		return ActionResult.new()
	var current: int = board.digits[cell]
	var step: UndoStep = UndoStep.new()
	step.cell = cell
	if mode == Mode.PLACE:
		if current == d:
			return ActionResult.new()
		step.kind = UndoStep.Kind.PLACE if current == 0 else UndoStep.Kind.REPLACE
		step.old_digit = current
		step.new_digit = d
		board.digits[cell] = d
		if auto_cross:
			step.mark_changes = _run_auto_cross()
		return _finish_step(step)
	if current != 0:
		return ActionResult.new()
	var index: int = cell * 9 + d - 1
	var before: int = board.marks[index]
	var after: int = Board.Mark.RESTORED_HAND
	step.kind = UndoStep.Kind.RESTORE
	if before == Board.Mark.OPEN or before == Board.Mark.RESTORED_HAND:
		after = Board.Mark.CROSSED_HAND
		step.kind = UndoStep.Kind.CROSS
	board.marks[index] = after
	step.mark_changes = PackedInt32Array([index, before, after])
	return _finish_step(step)


## Removes a placed digit; the ring shows again (GDD 3.2 and 4.3).
func erase() -> ActionResult:
	if not _can_act():
		return ActionResult.new()
	var cell: int = selected
	if board.is_given(cell) or board.digits[cell] == 0:
		return ActionResult.new()
	var step: UndoStep = UndoStep.new()
	step.kind = UndoStep.Kind.ERASE
	step.cell = cell
	step.old_digit = board.digits[cell]
	step.new_digit = 0
	board.digits[cell] = 0
	if auto_cross:
		step.mark_changes = _run_auto_cross()
	return _finish_step(step)


## Reverses the latest step exactly, then runs Auto Cross if it is on
## (GDD 5.4 and 7.2). Selects the step's cell, keeps the mode, closes a hint.
func undo() -> ActionResult:
	var result: ActionResult = ActionResult.new()
	if not can_undo():
		return result
	var step: UndoStep = _undo.pop_back()
	board.digits[step.cell] = step.old_digit
	var changes: PackedInt32Array = step.mark_changes
	var i: int = changes.size() - 3
	while i >= 0:
		board.marks[changes[i]] = changes[i + 1]
		i -= 3
	var extra: PackedInt32Array = PackedInt32Array()
	if auto_cross:
		extra = _run_auto_cross()
	result.applied = true
	result.changed_cells = _cells_of(step.cell, changes + extra)
	var selection_moved: bool = selected != step.cell
	selected = step.cell
	result.hint_closed = _drop_hint()
	board_changed.emit(result.changed_cells)
	if selection_moved:
		selection_changed.emit(selected)
	if result.hint_closed:
		hint_changed.emit(null)
	if _undo.is_empty():
		undo_available_changed.emit(false)
	return result


func can_undo() -> bool:
	return board != null and not is_completed and not _undo.is_empty()


## Turning Auto Cross on runs its rules now; turning it off changes nothing
## (GDD 5.1). Never an undo step. Ignored by lesson sessions, where Auto
## Cross is always off (GDD 15.4). After completion only the flag changes.
func set_auto_cross(on: bool) -> void:
	if level < 0:
		return
	auto_cross = on
	if not on or is_completed or board == null:
		return
	var changes: PackedInt32Array = _run_auto_cross()
	if not changes.is_empty():
		board_changed.emit(_cells_of(-1, changes))


# Timer ------------------------------------------------------------------------

## Ignored after completion, in lessons, and for a negative or non-finite value.
func add_time(seconds: float) -> void:
	if level < 0 or is_completed or not is_finite(seconds) or seconds <= 0.0:
		return
	elapsed = minf(elapsed + seconds, MAX_ELAPSED)


func elapsed_seconds() -> int:
	return int(floorf(elapsed))


# Score and hints --------------------------------------------------------------

## The live score S (GDD 9.2). 0 in lessons.
func score() -> int:
	if level < 0:
		return 0
	return Scoring.live_score(level, hints_bought)


func hint_cost() -> int:
	return Scoring.hint_cost(level)


## GDD 10.4: a puzzle, not complete, no hint on screen, and score >= cost.
func can_buy_hint() -> bool:
	return level >= 0 and board != null and not is_completed and hint == null \
		and hints_bought < Scoring.MAX_HINTS and score() >= hint_cost()


## Charges one hint and shows it. Not an undo step.
func buy_hint(new_hint: Hint) -> bool:
	if new_hint == null or not can_buy_hint():
		return false
	hints_bought += 1
	hint = new_hint
	hint_changed.emit(hint)
	score_changed.emit(score())
	return true


func close_hint() -> void:
	if _drop_hint():
		hint_changed.emit(null)


## T, after completion. 0 before.
func time_bonus() -> int:
	if not is_completed:
		return 0
	return Scoring.time_bonus(level, elapsed_seconds())


## F = S + T, after completion. 0 before.
func final_score() -> int:
	if not is_completed:
		return 0
	return Scoring.final_score(level, hints_bought, elapsed_seconds())


# Highlights -------------------------------------------------------------------

func peer_cells() -> PackedInt32Array:
	return Sudoku.peers(selected)


## Every other cell holding the selected cell's digit (GDD 2.3).
func same_digit_cells() -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	if board == null:
		return out
	var value: int = board.digit(selected)
	if value == 0:
		return out
	for cell: int in Sudoku.CELLS:
		if cell != selected and board.digits[cell] == value:
			out.append(cell)
	return out


# Saving -----------------------------------------------------------------------

## Everything in GDD 14 for a puzzle in progress, undo history and the hint
## on screen included. The score is stored as hints_bought.
## For a large history on the main thread, use save_snapshot() and
## snapshot_to_dict() instead.
func to_dict() -> Dictionary:
	var steps: Array = []
	for step: UndoStep in _undo:
		steps.append(step.to_dict())
	return {
		"puzzle_id": puzzle_id,
		"level": level,
		"solution": DataCheck.ints_to_text(solution),
		"board": board.to_dict() if board != null else null,
		"mode": mode,
		"selected": selected,
		"auto_cross": auto_cross,
		"elapsed": elapsed,
		"hints_bought": hints_bought,
		"hint": hint.to_dict() if hint != null else null,
		"undo": steps,
	}


## to_dict() with "undo" holding a shallow copy of the UndoStep objects
## instead of their dictionaries. Cheap enough for the main thread at any
## history length: the rest of to_dict() is small and fixed in size.
## Pass the result to snapshot_to_dict(), on any thread, to get to_dict().
func save_snapshot() -> Dictionary:
	return {
		"puzzle_id": puzzle_id,
		"level": level,
		"solution": DataCheck.ints_to_text(solution),
		"board": board.to_dict() if board != null else null,
		"mode": mode,
		"selected": selected,
		"auto_cross": auto_cross,
		"elapsed": elapsed,
		"hints_bought": hints_bought,
		"hint": hint.to_dict() if hint != null else null,
		"undo": _undo.duplicate(),
	}


## Turns a save_snapshot() into exactly what to_dict() returned at that
## moment. Safe on a worker thread while the session keeps playing: the
## snapshot owns its own list, and a recorded UndoStep is never changed
## (undo only pops it, and Auto Cross reruns record their changes in new
## steps or nowhere). Returns a new dictionary; the snapshot is not changed.
## Steps that are already dictionaries are kept as they are.
static func snapshot_to_dict(snapshot: Dictionary) -> Dictionary:
	var out: Dictionary = snapshot.duplicate()
	var steps: Array = []
	var items: Variant = snapshot.get("undo")
	if typeof(items) == TYPE_ARRAY:
		for item: Variant in items as Array:
			if item is UndoStep:
				steps.append((item as UndoStep).to_dict())
			else:
				steps.append(item)
	out["undo"] = steps
	return out


## A puzzle in progress, or null if anything is missing or invalid. Checks
## types and ranges, that the solution is complete and agrees with the
## givens, that the board is not already solved, that no undo step touches a
## given, and that undoing every step in turn leads back to the givens.
static func from_dict(data: Variant) -> GameSession:
	if typeof(data) != TYPE_DICTIONARY:
		return null
	var dict: Dictionary = data
	var id_value: Variant = dict.get("puzzle_id")
	if not DataCheck.is_puzzle_id(id_value):
		return null
	var level_value: Variant = dict.get("level")
	if not DataCheck.int_in(level_value, 0, Levels.COUNT - 1):
		return null
	var new_board: Board = Board.from_dict(dict.get("board"))
	if new_board == null or new_board.is_solved():
		return null
	var new_solution: PackedInt32Array = DataCheck.text_to_ints(dict.get("solution"), Sudoku.CELLS, 9)
	if not _solution_fits(new_solution, new_board.givens):
		return null
	var mode_value: Variant = dict.get("mode")
	var selected_value: Variant = dict.get("selected")
	var auto_value: Variant = dict.get("auto_cross")
	var elapsed_value: Variant = dict.get("elapsed")
	var hints_value: Variant = dict.get("hints_bought")
	if not DataCheck.int_in(mode_value, Mode.PLACE, Mode.CROSS_OUT):
		return null
	if not DataCheck.int_in(selected_value, -1, Sudoku.CELLS - 1):
		return null
	if typeof(auto_value) != TYPE_BOOL:
		return null
	if not DataCheck.number_in(elapsed_value, 0.0, MAX_ELAPSED):
		return null
	if not DataCheck.int_in(hints_value, 0, Scoring.MAX_HINTS):
		return null
	var new_hint: Hint = null
	var hint_value: Variant = dict.get("hint")
	if hint_value != null:
		new_hint = Hint.from_dict(hint_value)
		if new_hint == null:
			return null
	var steps: Variant = _read_undo(dict.get("undo"), new_board)
	if steps == null:
		return null
	var session: GameSession = GameSession.new()
	session.puzzle_id = id_value
	session.level = int(level_value)
	session.solution = new_solution
	session.board = new_board
	session.mode = int(mode_value)
	session.selected = int(selected_value)
	session.auto_cross = auto_value
	session.elapsed = float(elapsed_value)
	session.hints_bought = int(hints_value)
	session.hint = new_hint
	session._undo = steps
	return session


# Internals --------------------------------------------------------------------

func _can_act() -> bool:
	return board != null and not is_completed and Sudoku.is_cell(selected)


## Records a step that was just applied, decides completion, and emits.
func _finish_step(step: UndoStep) -> ActionResult:
	var result: ActionResult = ActionResult.new()
	var had_undo: bool = not _undo.is_empty()
	_undo.append(step)
	result.applied = true
	var is_digit_step: bool = step.kind == UndoStep.Kind.PLACE or step.kind == UndoStep.Kind.REPLACE or step.kind == UndoStep.Kind.ERASE
	var is_placement: bool = step.kind == UndoStep.Kind.PLACE or step.kind == UndoStep.Kind.REPLACE
	result.click = step.kind != UndoStep.Kind.ERASE
	result.changed_cells = _cells_of(step.cell, step.mark_changes)
	if is_digit_step:
		result.hint_closed = _drop_hint()
	if is_placement and level >= 0 and board.is_full():
		if board.conflict_cells().is_empty():
			is_completed = true
			result.completed = true
		else:
			result.full_board_conflict = true
	board_changed.emit(result.changed_cells)
	if result.hint_closed:
		hint_changed.emit(null)
	if result.completed:
		undo_available_changed.emit(false)
	elif not had_undo:
		undo_available_changed.emit(true)
	if result.completed:
		completed.emit(elapsed_seconds(), final_score())
	elif result.full_board_conflict:
		full_board_conflict.emit()
	return result


func _drop_hint() -> bool:
	if hint == null:
		return false
	hint = null
	return true


## Applies Auto Cross rules 1 and 2 to every candidate of every non-given
## cell, rings under placed digits included (GDD 5.1). Rule 3: hand marks
## never change. Returns the changes as triples (index, old, new).
func _run_auto_cross() -> PackedInt32Array:
	var changes: PackedInt32Array = PackedInt32Array()
	# How many cells of each row, column and box hold each digit.
	var counts: PackedInt32Array = PackedInt32Array()
	counts.resize(Sudoku.GROUPS * 10)
	counts.fill(0)
	var digits: PackedInt32Array = board.digits
	for cell: int in Sudoku.CELLS:
		var value: int = digits[cell]
		if value != 0:
			counts[Sudoku.box(cell) * 10 + value] += 1
			counts[(9 + Sudoku.row(cell)) * 10 + value] += 1
			counts[(18 + Sudoku.col(cell)) * 10 + value] += 1
	for cell: int in Sudoku.CELLS:
		if board.givens[cell] != 0:
			continue
		var box_base: int = Sudoku.box(cell) * 10
		var row_base: int = (9 + Sudoku.row(cell)) * 10
		var col_base: int = (18 + Sudoku.col(cell)) * 10
		var own: int = digits[cell]
		for d: int in range(1, 10):
			var index: int = cell * 9 + d - 1
			var before: int = board.marks[index]
			if before != Board.Mark.OPEN and before != Board.Mark.CROSSED_AUTO:
				continue
			# The cell's own digit never rules out its own candidate.
			var self_count: int = 1 if own == d else 0
			var ruled_out: bool = counts[box_base + d] > self_count \
				or counts[row_base + d] > self_count or counts[col_base + d] > self_count
			var after: int = Board.Mark.CROSSED_AUTO if ruled_out else Board.Mark.OPEN
			if after != before:
				board.marks[index] = after
				changes.append(index)
				changes.append(before)
				changes.append(after)
	return changes


## The cell (if any) plus every cell named in mark change triples, ascending.
static func _cells_of(cell: int, changes: PackedInt32Array) -> PackedInt32Array:
	var flagged: PackedByteArray = PackedByteArray()
	flagged.resize(Sudoku.CELLS)
	flagged.fill(0)
	if Sudoku.is_cell(cell):
		flagged[cell] = 1
	for i: int in range(0, changes.size(), 3):
		flagged[changes[i] / 9] = 1
	var out: PackedInt32Array = PackedInt32Array()
	for c: int in Sudoku.CELLS:
		if flagged[c] == 1:
			out.append(c)
	return out


static func _solution_fits(grid: PackedInt32Array, givens: PackedInt32Array) -> bool:
	if not Sudoku.is_complete_solution(grid) or not Sudoku.is_grid(givens):
		return false
	for cell: int in Sudoku.CELLS:
		if givens[cell] != 0 and givens[cell] != grid[cell]:
			return false
	return true


## Reads the undo history and checks it against the board: no step touches a
## given, and walking back from the current digits through every step gives
## each step's new digit before it and ends at the givens. Null if invalid.
static func _read_undo(value: Variant, on_board: Board) -> Variant:
	if typeof(value) != TYPE_ARRAY:
		return null
	var items: Array = value
	var steps: Array[UndoStep] = []
	for item: Variant in items:
		var step: UndoStep = UndoStep.from_dict(item)
		if step == null or on_board.givens[step.cell] != 0:
			return null
		for i: int in range(0, step.mark_changes.size(), 3):
			if on_board.givens[step.mark_changes[i] / 9] != 0:
				return null
		steps.append(step)
	var work: PackedInt32Array = on_board.digits.duplicate()
	var k: int = steps.size() - 1
	while k >= 0:
		var step: UndoStep = steps[k]
		if work[step.cell] != step.new_digit:
			return null
		work[step.cell] = step.old_digit
		k -= 1
	if work != on_board.givens:
		return null
	return steps
