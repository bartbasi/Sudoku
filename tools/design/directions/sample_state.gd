extends RefCounted
## Shared sample content for the Phase 1 design directions. All three
## directions show exactly this content, so Bart compares design, not content.
## Prototype data in tools/, never shipped. Owner: senior-graphic-designer.
##
## Values follow docs/GDD.md (levels, points, hint cost, hint text, completion
## and stats) and docs/LESSONS.md (lesson 2, screen 5).
## tools/design/check_samples.gd proves the boards are valid and the hints
## are the ones the GDD's search order would give.
##
## Cell names use the GDD's notation: rXcY is row X and column Y, both 1 to 9.
## In code, cells are indexes 0 to 80, row by row: index = (X - 1) * 9 + (Y - 1).
## Boxes are indexes 0 to 8 in reading order (GDD box 1 is index 0).

const MODE_PLACE: int = 0
const MODE_CROSS_OUT: int = 1

## Cell state flags. A cell can have several at once (GDD 2.3).
const STATE_SELECTED: int = 1
const STATE_PEER: int = 2 ## Shares a row, column or box with the selected cell.
const STATE_SAME_DIGIT: int = 4 ## Holds the selected cell's digit (only when the selected cell holds one).
const STATE_CONFLICT: int = 8 ## Holds a digit another cell in one of its groups also holds.
const STATE_HINT_TARGET: int = 16
const STATE_HINT_REASON: int = 32

## Cell background, in priority order: the first that applies wins. Marks for
## selected, conflict and the two hint states are drawn on top whatever the
## background is, so each stays recognizable in every combination.
enum CellBg { SELECTED, CONFLICT, HINT_TARGET, HINT_REASON, SAME_DIGIT, PEER, PLAIN }


## Everything the board needs to draw one moment of play.
class BoardState extends RefCounted:
	var givens: PackedInt32Array = PackedInt32Array() ## 81 digits, 0 where not given.
	var placed: PackedInt32Array = PackedInt32Array() ## 81 placed digits, 0 where none.
	var crossed: PackedInt32Array = PackedInt32Array() ## 81 masks of candidates crossed by hand, bit (digit - 1).
	var auto_crossed: PackedInt32Array = PackedInt32Array() ## 81 masks of candidates crossed by Auto Cross.
	var solution: PackedInt32Array = PackedInt32Array() ## 81 digits of the solved grid.
	var selected: int = -1 ## Selected cell index, -1 for none.
	var mode: int = MODE_CROSS_OUT ## MODE_PLACE or MODE_CROSS_OUT. The selected cell shows it.
	var hint_target_cells: PackedInt32Array = PackedInt32Array()
	var hint_reason_cells: PackedInt32Array = PackedInt32Array()

	## The digit shown in a cell (given or placed), 0 if empty.
	func digit_at(index: int) -> int:
		return givens[index] if givens[index] != 0 else placed[index]

	func is_given(index: int) -> bool:
		return givens[index] != 0

	## An empty cell shows its ring. A cell holding a digit hides it, even if
	## crosses are stored underneath.
	func is_empty(index: int) -> bool:
		return digit_at(index) == 0

	## Crossed by hand: draw the hand X. Takes precedence over Auto Cross.
	func is_crossed(index: int, digit: int) -> bool:
		return (crossed[index] >> (digit - 1)) & 1 == 1

	## Crossed by Auto Cross (and not by hand): draw the automatic mark.
	func is_auto_crossed(index: int, digit: int) -> bool:
		return not is_crossed(index, digit) and (auto_crossed[index] >> (digit - 1)) & 1 == 1

	## True if two different cells share a row, column or box.
	func are_peers(a: int, b: int) -> bool:
		if a == b:
			return false
		if a / 9 == b / 9 or a % 9 == b % 9:
			return true
		return (a / 9) / 3 == (b / 9) / 3 and (a % 9) / 3 == (b % 9) / 3

	## True if the cell's digit also sits in one of its groups (givens included).
	func is_conflict(index: int) -> bool:
		var digit: int = digit_at(index)
		if digit == 0:
			return false
		for other: int in 81:
			if digit_at(other) == digit and are_peers(index, other):
				return true
		return false

	## All state flags of a cell.
	func flags(index: int) -> int:
		var result: int = 0
		if index == selected:
			result |= STATE_SELECTED
		if selected >= 0 and are_peers(index, selected):
			result |= STATE_PEER
		if selected >= 0 and index != selected:
			var selected_digit: int = digit_at(selected)
			if selected_digit != 0 and digit_at(index) == selected_digit:
				result |= STATE_SAME_DIGIT
		if is_conflict(index):
			result |= STATE_CONFLICT
		if hint_target_cells.has(index):
			result |= STATE_HINT_TARGET
		if hint_reason_cells.has(index):
			result |= STATE_HINT_REASON
		return result

	## Which background a cell gets. Use this so every direction agrees.
	func cell_bg(index: int) -> CellBg:
		var f: int = flags(index)
		if f & STATE_SELECTED:
			return CellBg.SELECTED
		if f & STATE_CONFLICT:
			return CellBg.CONFLICT
		if f & STATE_HINT_TARGET:
			return CellBg.HINT_TARGET
		if f & STATE_HINT_REASON:
			return CellBg.HINT_REASON
		if f & STATE_SAME_DIGIT:
			return CellBg.SAME_DIGIT
		if f & STATE_PEER:
			return CellBg.PEER
		return CellBg.PLAIN


## A hint as the player sees it (GDD 10.2).
class SampleHint extends RefCounted:
	var technique: String
	var text: String ## One or two sentences.
	var lesson: String ## "Lesson: Hidden single", or "" when the technique has no lesson.


## The values in the HUD during play.
class Hud extends RefCounted:
	var level_name: String
	var elapsed_seconds: int
	var score: int
	var hint_cost: int
	var hints_used: int
	var mode: int

	func hint_affordable() -> bool:
		return score >= hint_cost


## One lesson screen: text and the board the player works on.
class LessonStep extends RefCounted:
	var lesson_number: int
	var lesson_count: int
	var lesson_title: String
	var step_number: int
	var step_count: int
	var text: String
	var board: BoardState ## The marked cells are the board's hint reason cells.


## One row of the stats screen. Times and best score are -1 until the first
## completion; show them as "-".
class LevelStats extends RefCounted:
	var level_name: String
	var started: int
	var completed: int
	var best_seconds: int
	var average_seconds: int
	var best_score: int


## The stats screen (GDD 13).
class SampleStats extends RefCounted:
	var levels: Array[LevelStats] = []
	var lessons_completed: int
	var lessons_total: int


## The completion screen (GDD 12).
class Completion extends RefCounted:
	var level_name: String
	var elapsed_seconds: int
	var points_after_hints: int
	var time_bonus: int
	var score: int
	var hints_used: int
	var buttons: Array[String] = []


## One board of the state sheet, with the notes printed above it.
class StateBoard extends RefCounted:
	var title: String
	var notes: Array[String] = []
	var board: BoardState
	var hint: SampleHint ## The hint on screen for this board, or null.


# The play board: a mid-puzzle board from a Medium-style puzzle with one
# solution. Auto Cross is off.
const _PLAY_SOLUTION: Array[String] = [
	"581726493",
	"273549681",
	"946381527",
	"695473812",
	"427815936",
	"138962754",
	"364298175",
	"812657349",
	"759134268",
]

const _PLAY_GIVENS: Array[String] = [
	"000706490",
	"000000081",
	"900301027",
	"000400010",
	"020000000",
	"108900000",
	"004090000",
	"012007349",
	"750004208",
]

const _PLAY_PLACED: Array[String] = [
	"000000003",
	"000000600",
	"000080500",
	"600000000",
	"000000900",
	"030000000",
	"000008000",
	"800600000",
	"009130000",
]

## Candidates the player crossed by hand so far. Every one is ruled out by a
## given or placed digit in the same row, column or box.
const _PLAY_CROSSED: Dictionary[String, String] = {
	"r1c3": "2346789",
	"r1c5": "136789",
	"r2c1": "168",
	"r4c2": "1234568",
	"r4c3": "168",
	"r5c3": "123689",
	"r7c9": "489",
	"r8c5": "12346789",
}

## The selected cell on the play screen, in Cross Out mode. Its 4 is still
## open although column 3 rules it out: the player is about to cross it.
const PLAY_SELECTED: String = "r5c3"

## The box the ring close-ups show (index 3, GDD box 4): the selected cell's
## box. It holds givens, placed digits, the selected cell, a cell with seven
## hand crosses, a partly crossed cell, and (close-up only) a cell whose
## ruled out candidates carry the Auto Cross mark.
const CLOSEUP_BOX: int = 3
const _CLOSEUP_AUTO: Dictionary[String, String] = {
	"r5c1": "1236789",
}

# State sheet board A: the player went on (r7c4, r8c5 and r9c8 placed),
# turned Auto Cross on and asked for a hint. The first step in the GDD's
# search order is a hidden single in box 1: 1 goes in r1c3. The player has
# selected that cell in Cross Out mode.
const _HINT_EXTRA_PLACED: Array[String] = ["r7c4", "r8c5", "r9c8"]
const HINT_TARGET: String = "r1c3"
const _HINT_REASONS: Array[String] = ["r6c1", "r8c2", "r2c9", "r3c6"]

# State sheet board B: the player placed a wrong 8 in r2c5. It clashes with
# the given 8 in r2c8 (row 2) and the placed 8 in r3c5 (column 5 and box 2).
# The hint points at the wrong digit. The player has selected it in Place mode,
# so every other 8 shows the same digit highlight.
const WRONG_CELL: String = "r2c5"
const WRONG_DIGIT: int = 8

# The lesson board: docs/LESSONS.md lesson 2, used on every screen of it.
# Bart's example: r5c5 sits in a row holding only 9 and 3, a column holding
# only 4 and 6, and a box holding only 2, 3 and 4.
const _LESSON_SOLUTION: Array[String] = [
	"314752698",
	"968431257",
	"527896134",
	"836145972",
	"792683541",
	"451279386",
	"289364715",
	"175928463",
	"643517829",
]

const _LESSON_GIVENS: Array[String] = [
	"300700090",
	"008001200",
	"020006004",
	"806040070",
	"090003000",
	"050200306",
	"009060010",
	"100008400",
	"040507800",
]

const LESSON_SELECTED: String = "r5c5"

## Screen 5 starts with the row's 9 and 3 crossed.
const _LESSON_CROSSED: Dictionary[String, String] = {
	"r5c5": "39",
}

## Screen 5 marks the column's 4 and 6.
const _LESSON_MARKED: Array[String] = ["r4c5", "r7c5"]


## Cell index from a GDD name like "r5c3".
static func cell(cell_name: String) -> int:
	var row: int = cell_name.substr(1, 1).to_int()
	var col: int = cell_name.substr(3, 1).to_int()
	return (row - 1) * 9 + (col - 1)


## GDD name of a cell index.
static func cell_name(index: int) -> String:
	return "r%dc%d" % [index / 9 + 1, index % 9 + 1]


## The board on the play screen.
static func play_board() -> BoardState:
	var board: BoardState = BoardState.new()
	board.solution = _digits(_PLAY_SOLUTION)
	board.givens = _digits(_PLAY_GIVENS)
	board.placed = _digits(_PLAY_PLACED)
	board.crossed = _masks(_PLAY_CROSSED)
	board.auto_crossed = _masks({})
	board.selected = cell(PLAY_SELECTED)
	board.mode = MODE_CROSS_OUT
	return board


## The board the ring close-ups crop: the play board plus Auto Cross marks
## in one cell, so the hand X and the automatic mark sit side by side.
static func closeup_board() -> BoardState:
	var board: BoardState = play_board()
	board.auto_crossed = _masks(_CLOSEUP_AUTO)
	return board


## State sheet board A: hint (target and reason cells), Auto Cross on,
## selected cell in Cross Out mode.
static func hint_board() -> BoardState:
	var board: BoardState = play_board()
	for name: String in _HINT_EXTRA_PLACED:
		var index: int = cell(name)
		board.placed[index] = board.solution[index]
	board.auto_crossed = _ruled_out_masks(board)
	board.selected = cell(HINT_TARGET)
	board.mode = MODE_CROSS_OUT
	board.hint_target_cells = PackedInt32Array([cell(HINT_TARGET)])
	for name: String in _HINT_REASONS:
		board.hint_reason_cells.append(cell(name))
	return board


static func hint_for_hint_board() -> SampleHint:
	var hint: SampleHint = SampleHint.new()
	hint.technique = "Hidden single"
	hint.text = "In this box, 1 fits in only one cell. It goes here."
	hint.lesson = "Lesson: Hidden single"
	return hint


## State sheet board B: conflicts and the same digit highlight, selected cell
## in Place mode, with the wrong digit hint on screen.
static func conflict_board() -> BoardState:
	var board: BoardState = play_board()
	board.placed[cell(WRONG_CELL)] = WRONG_DIGIT
	board.selected = cell(WRONG_CELL)
	board.mode = MODE_PLACE
	board.hint_target_cells = PackedInt32Array([cell(WRONG_CELL)])
	return board


static func hint_for_conflict_board() -> SampleHint:
	var hint: SampleHint = SampleHint.new()
	hint.technique = "Wrong digit"
	hint.text = "This %d is not right. Erase it and look again." % WRONG_DIGIT
	hint.lesson = ""
	return hint


## The two boards of the state sheet, with their notes.
static func state_sheet() -> Array[StateBoard]:
	var a: StateBoard = StateBoard.new()
	a.title = "Hint, Auto Cross on, Cross Out mode"
	a.notes = [
		"r1c3: selected in Cross Out mode, and the hint target.",
		"r6c1, r8c2, r2c9, r3c6: hint reason cells.",
		"Rings: hand X where the player crossed, Auto Cross mark on the rest.",
	]
	a.board = hint_board()
	a.hint = hint_for_hint_board()
	var b: StateBoard = StateBoard.new()
	b.title = "Conflict and same digit, Place mode"
	b.notes = [
		"r2c5: wrong 8, selected in Place mode, conflict and hint target.",
		"r2c8 (given) and r3c5: in conflict with it.",
		"Every other 8: same digit highlight.",
	]
	b.board = conflict_board()
	b.hint = hint_for_conflict_board()
	return [a, b]


## The board on the lesson screen: lesson 2, screen 5.
static func lesson_board() -> BoardState:
	var board: BoardState = BoardState.new()
	board.solution = _digits(_LESSON_SOLUTION)
	board.givens = _digits(_LESSON_GIVENS)
	board.placed = _masks({})
	board.crossed = _masks(_LESSON_CROSSED)
	board.auto_crossed = _masks({})
	board.selected = cell(LESSON_SELECTED)
	board.mode = MODE_CROSS_OUT
	for name: String in _LESSON_MARKED:
		board.hint_reason_cells.append(cell(name))
	return board


## HUD on the play screen: Medium starts at 400 points, one hint (80) bought.
static func hud() -> Hud:
	var values: Hud = Hud.new()
	values.level_name = "Medium"
	values.elapsed_seconds = 12 * 60 + 48
	values.score = 320
	values.hint_cost = 80
	values.hints_used = 1
	values.mode = MODE_CROSS_OUT
	return values


static func lesson_step() -> LessonStep:
	var step: LessonStep = LessonStep.new()
	step.lesson_number = 2
	step.lesson_count = 5
	step.lesson_title = "The ring and Cross Out"
	step.step_number = 5
	step.step_count = 8
	step.text = "A column can have each digit only once, too. This column has a 4 and a 6. Cross out 4 and 6."
	step.board = lesson_board()
	return step


static func stats() -> SampleStats:
	var result: SampleStats = SampleStats.new()
	result.levels = [
		_level("Beginner", 12, 12, 3 * 60 + 48, 5 * 60 + 10, 152),
		_level("Easy", 24, 22, 6 * 60 + 2, 8 * 60 + 40, 299),
		_level("Medium", 17, 13, 11 * 60 + 5, 15 * 60 + 22, 578),
		_level("Hard", 9, 5, 21 * 60 + 47, 29 * 60 + 10, 751),
		_level("Expert", 2, 0, -1, -1, -1),
	]
	result.lessons_completed = 4
	result.lessons_total = 5
	return result


## GDD 12 example: "Hard, 22:30, points 420, time bonus 175, score 595, 2 hints".
static func completion() -> Completion:
	var result: Completion = Completion.new()
	result.level_name = "Hard"
	result.elapsed_seconds = 22 * 60 + 30
	result.points_after_hints = 420
	result.time_bonus = 175
	result.score = 595
	result.hints_used = 2
	result.buttons = ["Play again", "Menu"]
	return result


## "12:48" for minutes and seconds, "1:02:05" from one hour, "-" for -1.
static func format_time(seconds: int) -> String:
	if seconds < 0:
		return "-"
	var hours: int = seconds / 3600
	var minutes: int = (seconds % 3600) / 60
	var secs: int = seconds % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	return "%d:%02d" % [minutes, secs]


## "1,240": thousands separated by commas. "-" for -1 (no completion yet).
static func format_number(value: int) -> String:
	if value < 0:
		return "-"
	var digits: String = str(value)
	var out: String = ""
	while digits.length() > 3:
		out = "," + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return digits + out


static func _level(level_name: String, started: int, completed: int, best: int, average: int, best_score: int) -> LevelStats:
	var row: LevelStats = LevelStats.new()
	row.level_name = level_name
	row.started = started
	row.completed = completed
	row.best_seconds = best
	row.average_seconds = average
	row.best_score = best_score
	return row


static func _digits(grid_rows: Array[String]) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for row: String in grid_rows:
		for i: int in row.length():
			out.append(row.substr(i, 1).to_int())
	return out


static func _masks(per_cell: Dictionary[String, String]) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(81)
	out.fill(0)
	for name: String in per_cell:
		var digits: String = per_cell[name]
		var mask: int = 0
		for i: int in digits.length():
			mask |= 1 << (digits.substr(i, 1).to_int() - 1)
		out[cell(name)] = mask
	return out


## What Auto Cross would cross on this board: every ruled out candidate of
## every empty cell that the player has not crossed by hand.
static func _ruled_out_masks(board: BoardState) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(81)
	out.fill(0)
	for index: int in 81:
		if board.is_given(index):
			continue
		var mask: int = 0
		for other: int in 81:
			var digit: int = board.digit_at(other)
			if digit != 0 and board.are_peers(index, other):
				mask |= 1 << (digit - 1)
		out[index] = mask & ~board.crossed[index]
	return out
