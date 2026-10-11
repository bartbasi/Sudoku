class_name Puzzle
extends RefCounted
## One generated puzzle. PuzzleGenerator.generate(level, seed) rebuilds it
## exactly from its level and seed, so a save only needs the id.

## "<version>.<level>.<seed>", see PuzzleId.
var id: String = ""
## 0 Beginner, 1 Easy, 2 Medium, 3 Hard, 4 Expert.
var level: int = 0
## 0 to 4294967295.
var seed: int = 0
## 81 ints, index = row * 9 + col, 0 for an empty cell.
var givens: PackedInt32Array = PackedInt32Array()
## The one solution, 81 ints from 1 to 9.
var solution: PackedInt32Array = PackedInt32Array()
## The hardest technique the technique solver needed, for example &"x_wing".
var hardest: StringName = &""
