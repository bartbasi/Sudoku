class_name LessonGoal
extends RefCounted
## The answer of one lesson screen while it is played (docs/ARCHITECTURE.md
## section 10, docs/LESSONS.md section 8). It judges each tap against the
## goal, remembers which steps are done, and picks the text for a wrong tap.
## It changes no board: LessonPlayer lets a right tap through to the session
## and stops every other tap.
##
## A tap that completes a step not yet done is right; in a "sequence" goal
## only the first step not yet done counts. Each step counts once, so doing
## a step again is a wrong tap. Once every step is done, every tap is ignored.
## Owner: lessons-dev.

enum Verdict { RIGHT, WRONG, IGNORED }

var screen: LessonScreen = null
var _done: PackedByteArray = PackedByteArray()
## The key (LessonScreen.step_key) of the step done last, "" before any.
var _last_key: String = ""


static func create(for_screen: LessonScreen) -> LessonGoal:
	var goal: LessonGoal = LessonGoal.new()
	goal.screen = for_screen
	if for_screen != null:
		goal._done.resize(for_screen.steps.size())
		goal._done.fill(0)
	return goal


func is_complete() -> bool:
	if screen == null:
		return true
	return done_count() == screen.steps.size()


func done_count() -> int:
	var count: int = 0
	for flag: int in _done:
		count += flag
	return count


func judge(action: BoardAction) -> int:
	if screen == null or action == null or is_complete():
		return Verdict.IGNORED
	return Verdict.RIGHT if _open_step(action) >= 0 else Verdict.WRONG


## Marks the step this tap completes as done. False, and nothing changes,
## when the tap is not right.
func accept(action: BoardAction) -> bool:
	if judge(action) != Verdict.RIGHT:
		return false
	_done[_open_step(action)] = 1
	_last_key = LessonScreen.step_key(action)
	return true


## What {next} reads now: the "after" text of the step done last if the data
## has one, otherwise "start". "" when the screen has no "next".
func next_text() -> String:
	if screen == null or not screen.has_next:
		return ""
	if screen.next_after.has(_last_key):
		return screen.next_after[_last_key]
	return screen.next_start


## The text a wrong tap shows: the first entry of the wrong list that
## matches it, or the fallback, with {d} and {next} filled in. selected_cell
## and board are the lesson's state at the moment of the tap.
func wrong_text(action: BoardAction, board: Board, selected_cell: int) -> String:
	if screen == null or action == null:
		return ""
	var rule: LessonScreen.WrongTap = matching_rule(action, board, selected_cell)
	return fill(rule.text if rule != null else screen.fallback, action)


## The first wrong list entry that matches the tap, or null for the fallback.
func matching_rule(action: BoardAction, board: Board, selected_cell: int) -> LessonScreen.WrongTap:
	if screen == null or action == null:
		return null
	for rule: LessonScreen.WrongTap in screen.wrong:
		if _rule_matches(rule, action, board, selected_cell):
			return rule
	return null


## raw with {d} as the tapped digit (pad taps only) and {next} as next_text().
func fill(raw: String, action: BoardAction) -> String:
	var text: String = raw
	if action != null and action.kind == BoardAction.Kind.PAD:
		text = text.replace("{d}", str(action.digit))
	return text.replace("{next}", next_text())


## Every text a wrong tap could show on this screen, with each possible
## {next} and a one-digit {d}. The lesson card reserves room for the
## longest, so the board does not move when one shows.
func all_wrong_texts() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if screen == null:
		return out
	var nexts: PackedStringArray = PackedStringArray([screen.next_start])
	for value: String in screen.next_after.values():
		nexts.append(value)
	var raws: PackedStringArray = PackedStringArray([screen.fallback])
	for rule: LessonScreen.WrongTap in screen.wrong:
		raws.append(rule.text)
	for raw: String in raws:
		for next: String in nexts:
			var text: String = raw.replace("{d}", "9").replace("{next}", next)
			if not out.has(text):
				out.append(text)
	return out


## The step this tap would complete, or -1.
func _open_step(action: BoardAction) -> int:
	for i: int in screen.steps.size():
		if _done[i] != 0:
			continue
		if _same_step(screen.steps[i], action):
			return i
		if screen.in_sequence:
			return -1
	return -1


static func _same_step(step: BoardAction, action: BoardAction) -> bool:
	if step.kind != action.kind:
		return false
	match step.kind:
		BoardAction.Kind.CELL:
			return step.cell == action.cell
		BoardAction.Kind.PAD:
			return step.digit == action.digit
	return true


static func _rule_matches(rule: LessonScreen.WrongTap, action: BoardAction, board: Board, selected_cell: int) -> bool:
	if rule.kind != action.kind:
		return false
	if action.kind == BoardAction.Kind.PAD:
		if not rule.digits.is_empty() and not rule.digits.has(action.digit):
			return false
		if rule.crossed >= 0:
			var crossed: bool = board != null and Sudoku.is_cell(selected_cell) and board.is_crossed(selected_cell, action.digit)
			if crossed != (rule.crossed == 1):
				return false
	elif action.kind == BoardAction.Kind.CELL:
		if rule.other:
			return not rule.excluded.has(action.cell)
		if not rule.cells.is_empty():
			return rule.cells.has(action.cell)
	return true
