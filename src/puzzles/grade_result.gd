class_name GradeResult
extends RefCounted
## What TechniqueSolver.grade() found.

## True if the techniques filled the board. That proves the puzzle has
## exactly one solution.
var solved: bool = false
## The level that introduces the hardest technique used, 0 Beginner to
## 4 Expert. -1 if the solver got stuck or the givens are not a valid grid.
## A full valid grid needs no technique and grades 0.
var level: int = -1
## The hardest technique used, &"" if none. When stuck, the hardest one used
## before getting stuck.
var hardest: StringName = &""
## Steps taken. A step is one placement, or one pattern with all its
## eliminations.
var step_count: int = 0
## Technique id (StringName) to the number of steps it made. Only techniques
## used at least once are listed.
var technique_counts: Dictionary = {}
