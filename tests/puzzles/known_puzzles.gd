extends RefCounted
## Fixed puzzles and helpers shared by the puzzle tests. Not a test file.
##
## The puzzles were made by our own PuzzleGenerator and copied here, so some
## tests do not depend on the generator, and test_generator.gd can check that
## the generator still makes exactly these (puzzle IDs must never change).

## The givens floor per level (GDD 11.4), written out so the test does not
## read it from the generator.
const GIVENS_FLOOR: PackedInt32Array = [36, 32, 0, 0, 0]

## What each level needs at least one of (GDD 11.2).
const NEEDS: Array = [
	[&"hidden_single"],
	[&"naked_single"],
	[&"pointing", &"claiming", &"naked_pair"],
	[&"hidden_pair", &"naked_triple", &"hidden_triple", &"x_wing", &"y_wing"],
	[&"swordfish", &"xyz_wing"],
]

## PuzzleGenerator.generate(0, 1).givens, ID "1.0.1", with the givens floor
## of GDD 11.4 (replaced once, when the floor was added in Phase 3).
const BEGINNER_1_GIVENS: PackedInt32Array = [
	9, 0, 0, 0, 7, 0, 5, 0, 2,
	0, 0, 0, 0, 5, 4, 0, 0, 9,
	7, 0, 0, 0, 0, 0, 1, 0, 3,
	0, 8, 0, 5, 0, 0, 4, 9, 1,
	0, 4, 3, 9, 8, 1, 2, 7, 5,
	0, 0, 0, 0, 0, 0, 0, 0, 8,
	0, 1, 2, 4, 0, 7, 0, 5, 0,
	4, 0, 0, 0, 1, 0, 0, 0, 7,
	5, 0, 0, 0, 3, 6, 8, 0, 0,
]

## PuzzleGenerator.generate(4, EXPERT_SEED), ID "1.4.1". It needs one
## Swordfish, and Y-Wing, hidden pair and hidden triple steps on the way.
const EXPERT_SEED: int = 1
const EXPERT_GIVENS: PackedInt32Array = [
	9, 0, 0, 0, 1, 0, 4, 0, 0,
	4, 7, 2, 0, 0, 0, 0, 1, 0,
	0, 0, 0, 7, 0, 0, 0, 2, 0,
	3, 0, 0, 0, 0, 9, 0, 5, 0,
	0, 0, 0, 4, 0, 0, 3, 0, 8,
	0, 0, 0, 0, 3, 0, 6, 9, 0,
	6, 0, 0, 0, 9, 0, 1, 0, 5,
	2, 0, 0, 3, 0, 0, 0, 0, 0,
	0, 1, 0, 0, 0, 0, 0, 4, 0,
]
const EXPERT_SOLUTION: PackedInt32Array = [
	9, 8, 5, 2, 1, 3, 4, 6, 7,
	4, 7, 2, 9, 6, 5, 8, 1, 3,
	1, 3, 6, 7, 8, 4, 5, 2, 9,
	3, 6, 8, 1, 7, 9, 2, 5, 4,
	5, 9, 1, 4, 2, 6, 3, 7, 8,
	7, 2, 4, 5, 3, 8, 6, 9, 1,
	6, 4, 7, 8, 9, 2, 1, 3, 5,
	2, 5, 9, 3, 4, 1, 7, 8, 6,
	8, 1, 3, 6, 5, 7, 9, 4, 2,
]
const EXPERT_HARDEST: StringName = &"swordfish"


## A valid full grid from a formula: row r is 1 to 9 shifted by 3r + r / 3.
static func pattern_grid() -> PackedInt32Array:
	var grid: PackedInt32Array = PackedInt32Array()
	for r: int in 9:
		for c: int in 9:
			grid.append((r * 3 + r / 3 + c) % 9 + 1)
	return grid


## True if grid is 81 digits 1 to 9 with no repeat in any row, column or box.
static func is_valid_solution(grid: PackedInt32Array) -> bool:
	if grid.size() != 81:
		return false
	for g: int in 27:
		var seen: int = 0
		for k: int in 9:
			var i: int = 0
			if g < 9:
				i = ((g / 3) * 3 + k / 3) * 9 + (g % 3) * 3 + k % 3
			elif g < 18:
				i = (g - 9) * 9 + k
			else:
				i = k * 9 + (g - 18)
			var digit: int = grid[i]
			if digit < 1 or digit > 9 or seen & (1 << digit):
				return false
			seen |= 1 << digit
	return true


static func count_givens(givens: PackedInt32Array) -> int:
	var count: int = 0
	for value: int in givens:
		if value != 0:
			count += 1
	return count
