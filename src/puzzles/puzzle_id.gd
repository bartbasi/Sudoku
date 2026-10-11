class_name PuzzleId
extends RefCounted
## Puzzle IDs: "<version>.<level>.<seed>" in plain decimal, for example
## "1.3.20481". Version 1 is the current generator. An ID reproduces its puzzle
## exactly through PuzzleGenerator.generate(level, seed).

const VERSION: int = 1
const LEVEL_COUNT: int = 5
## Seeds are 0 to 2^32 - 1.
const MAX_SEED: int = 4294967295
## "1.4.4294967295" is 14 characters. Anything much longer is not an ID.
const MAX_LENGTH: int = 32
## Longest canonical part: the 10 digits of MAX_SEED.
const MAX_PART_LENGTH: int = 10


## The ID for a level (0 to 4) and seed (0 to MAX_SEED) of this version.
static func make(level: int, seed_value: int) -> String:
	return "%d.%d.%d" % [VERSION, level, seed_value]


## Reads an ID, for example from save data. Returns {"version", "level",
## "seed"} as ints, or an empty Dictionary unless the text is exactly what
## make() writes for a valid level and seed: three parts split by dots, ASCII
## digits only, no sign, no spaces, no leading zeros, version 1, level 0 to 4
## and seed 0 to MAX_SEED.
static func parse(id: String) -> Dictionary:
	if id.is_empty() or id.length() > MAX_LENGTH:
		return {}
	var parts: PackedStringArray = id.split(".", true)
	if parts.size() != 3:
		return {}
	for part: String in parts:
		if not _is_canonical_number(part):
			return {}
	var version: int = parts[0].to_int()
	var level: int = parts[1].to_int()
	var seed_value: int = parts[2].to_int()
	if version != VERSION:
		return {}
	if level < 0 or level >= LEVEL_COUNT:
		return {}
	if seed_value < 0 or seed_value > MAX_SEED:
		return {}
	return {"version": version, "level": level, "seed": seed_value}


## True for "0" or ASCII digits without a leading zero, at most 10 of them, so
## to_int() can never overflow.
static func _is_canonical_number(text: String) -> bool:
	var length: int = text.length()
	if length == 0 or length > MAX_PART_LENGTH:
		return false
	for i: int in length:
		var code: int = text.unicode_at(i)
		if code < 48 or code > 57:
			return false
	return length == 1 or text.unicode_at(0) != 48
