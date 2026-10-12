class_name Levels
extends RefCounted
## The five levels (GDD 11.2).

const BEGINNER := 0
const EASY := 1
const MEDIUM := 2
const HARD := 3
const EXPERT := 4
const COUNT := 5

const _NAMES: PackedStringArray = ["Beginner", "Easy", "Medium", "Hard", "Expert"]


## "Beginner" to "Expert", or "" for a level outside 0 to 4.
static func name_of(level: int) -> String:
	if not is_valid(level):
		return ""
	return _NAMES[level]


static func is_valid(level: int) -> bool:
	return level >= 0 and level < COUNT
