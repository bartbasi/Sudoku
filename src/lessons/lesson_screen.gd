class_name LessonScreen
extends RefCounted
## One validated lesson screen (docs/ARCHITECTURE.md section 10), with every
## cell already converted from rXcY to 0 to 80. Built only by LessonLibrary,
## which has checked every field, so the player can trust it.
## Owner: lessons-dev.


## One entry of the screen's wrong list: what a tap must look like for this
## text to show. Entries are checked in order; the first match wins.
class WrongTap extends RefCounted:
	## BoardAction.Kind of the tap.
	var kind: int = BoardAction.Kind.CELL
	## For a pad tap: the digits it covers. Empty means any digit.
	var digits: PackedInt32Array = PackedInt32Array()
	## For a cell tap: the cells it covers. Empty (and other false) means any cell.
	var cells: PackedInt32Array = PackedInt32Array()
	## "cells": "other": any cell not named in an earlier entry or in the goal.
	var other: bool = false
	## The cells "other" leaves out: those of earlier cell entries and of the goal.
	var excluded: PackedInt32Array = PackedInt32Array()
	## For a pad tap: -1 either way, 0 the digit is open in the selected
	## cell, 1 it is crossed there.
	var crossed: int = -1
	var text: String = ""


## The given digits, 81 values, 0 for empty.
var givens: PackedInt32Array = PackedInt32Array()
## Digits the player placed before this screen, 81 values, 0 elsewhere.
var placed: PackedInt32Array = PackedInt32Array()
## Mark indices (cell * 9 + digit - 1) crossed by hand before this screen.
var crossed: PackedInt32Array = PackedInt32Array()
## The selected cell at the start, or -1.
var selected: int = -1
## GameSession.Mode at the start.
var mode: int = GameSession.Mode.PLACE
var marked_cells: PackedInt32Array = PackedInt32Array()
## Any of &"mode", &"erase", &"undo", &"pad", &"pad:1" to &"pad:9" (NumberPad names).
var marked_controls: Array[StringName] = []
var text: String = ""
## true for "sequence", false for "any".
var in_sequence: bool = false
## The answer: BoardAction values with kind and, for a cell or pad step, cell or digit.
var steps: Array[BoardAction] = []
## The technique that proves this screen's placement, or &"" when none.
var technique: StringName = &""
## Whether the screen has a "next" entry to fill {next}.
var has_next: bool = false
var next_start: String = ""
## Step key (step_key) to the {next} text after that step.
var next_after: Dictionary[String, String] = {}
var praise: String = ""
var wrong: Array[WrongTap] = []
var fallback: String = ""


## The position the screen starts from: givens plus placed digits.
func position() -> PackedInt32Array:
	var grid: PackedInt32Array = givens.duplicate()
	for cell: int in Sudoku.CELLS:
		if placed[cell] != 0:
			grid[cell] = placed[cell]
	return grid


## A fresh board for the start of this screen: the givens, the placed digits
## as the player's own, and the preset hand crosses.
func build_board() -> Board:
	var board: Board = Board.create(givens)
	if board == null:
		return null
	for cell: int in Sudoku.CELLS:
		if placed[cell] != 0:
			board.digits[cell] = placed[cell]
	for index: int in crossed:
		board.marks[index] = Board.Mark.CROSSED_HAND
	return board


## The lesson session for this screen: Auto Cross off, no score, no hints.
func build_session() -> GameSession:
	return GameSession.for_lesson(build_board(), mode, selected)


## The key a step goes by in "next.after": "pad:4", "cell:40", "mode",
## "erase" or "undo". Cells are 0 to 80 here (the data's rXcY are converted).
static func step_key(action: BoardAction) -> String:
	if action == null:
		return ""
	match action.kind:
		BoardAction.Kind.CELL:
			return "cell:%d" % action.cell
		BoardAction.Kind.PAD:
			return "pad:%d" % action.digit
		BoardAction.Kind.MODE:
			return "mode"
		BoardAction.Kind.ERASE:
			return "erase"
		BoardAction.Kind.UNDO:
			return "undo"
	return ""
