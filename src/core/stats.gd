class_name Stats
extends RefCounted
## Per level stats (GDD 13) and the New best rule (GDD 12.1).
## Stored per level: started, completed, best time, total time, best score.
## A best is -1 until the level's first completion.
##
## Stats also remembers the id of the last puzzle it counted, so the same
## puzzle is never counted twice. That lets the app write stats first and
## delete the saved puzzle second: if the app dies in between, the saved
## puzzle comes back one digit short, and finishing it again changes nothing.

const DataCheck := preload("res://src/core/data_check.gd")

const NEW_BEST_TIME := 1
const NEW_BEST_SCORE := 2

var _started: PackedInt64Array = PackedInt64Array()
var _completed: PackedInt64Array = PackedInt64Array()
var _best_time: PackedInt64Array = PackedInt64Array()
var _total_time: PackedInt64Array = PackedInt64Array()
var _best_score: PackedInt64Array = PackedInt64Array()
var _last_completed_id: String = ""


func _init() -> void:
	_started.resize(Levels.COUNT)
	_completed.resize(Levels.COUNT)
	_best_time.resize(Levels.COUNT)
	_total_time.resize(Levels.COUNT)
	_best_score.resize(Levels.COUNT)
	for level: int in Levels.COUNT:
		_clear_level(level)


func started(level: int) -> int:
	return _started[level] if Levels.is_valid(level) else 0


func completed_count(level: int) -> int:
	return _completed[level] if Levels.is_valid(level) else 0


func best_time(level: int) -> int:
	return _best_time[level] if Levels.is_valid(level) else -1


## Total time divided by completed, rounded to the nearest second, halves up.
func average_time(level: int) -> int:
	if not Levels.is_valid(level) or _completed[level] == 0:
		return -1
	var count: int = _completed[level]
	return (2 * _total_time[level] + count) / (2 * count)


func best_score(level: int) -> int:
	return _best_score[level] if Levels.is_valid(level) else -1


## A new puzzle's board first appeared.
func record_start(level: int) -> void:
	if Levels.is_valid(level):
		_started[level] += 1


## The id of the last puzzle record_completion() counted, or "" if none.
func last_completed_id() -> String:
	return _last_completed_id


## True if puzzle_id is the last puzzle counted, so record_completion() with
## it would change nothing. False for "".
func has_completed(puzzle_id: String) -> bool:
	return not puzzle_id.is_empty() and puzzle_id == _last_completed_id


## Records a completion and returns the NEW_BEST_* bits, decided from the
## bests as they were before this completion. A tie gives no bit, and so does
## a level's first completion. A negative time or score counts as 0.
##
## puzzle_id is optional. If it is the last puzzle counted (has_completed),
## nothing changes and the result is 0. Otherwise the completion counts and
## a valid id (DataCheck.is_puzzle_id) becomes the last completed id. Without
## an id, or with an invalid one, the completion always counts and the last
## completed id stays as it was.
func record_completion(level: int, seconds: int, score: int, puzzle_id: String = "") -> int:
	if not Levels.is_valid(level) or has_completed(puzzle_id):
		return 0
	if DataCheck.is_puzzle_id(puzzle_id):
		_last_completed_id = puzzle_id
	var t: int = maxi(seconds, 0)
	var f: int = maxi(score, 0)
	var bits: int = 0
	if _completed[level] > 0:
		if t < _best_time[level]:
			bits |= NEW_BEST_TIME
		if f > _best_score[level]:
			bits |= NEW_BEST_SCORE
	if _completed[level] == 0 or t < _best_time[level]:
		_best_time[level] = t
	if _completed[level] == 0 or f > _best_score[level]:
		_best_score[level] = f
	_completed[level] += 1
	_total_time[level] += t
	# Started counts every board that appeared, so it never trails Completed.
	_started[level] = maxi(_started[level], _completed[level])
	return bits


## Clears every level. The level of a puzzle in progress keeps Started at 1
## (GDD 13.2). Lesson progress is not part of Stats, so it is kept. The last
## completed id is kept too: it guards against counting a puzzle twice, and
## is not a stat the player sees.
func reset(in_progress_level: int) -> void:
	for level: int in Levels.COUNT:
		_clear_level(level)
	if Levels.is_valid(in_progress_level):
		_started[in_progress_level] = 1


func to_dict() -> Dictionary:
	var levels: Array = []
	for level: int in Levels.COUNT:
		levels.append({
			"started": _started[level],
			"completed": _completed[level],
			"best_time": _best_time[level],
			"total_time": _total_time[level],
			"best_score": _best_score[level],
		})
	return {"levels": levels, "last_completed": _last_completed_id}


## Never null. Needs a "levels" list of exactly five entries; otherwise all
## defaults. Each level that is missing a field, has one out of range, or does
## not add up (completed above started, a best without a completion, a total
## below best time times completed, a best score above twice the level's
## points) takes the defaults; the other levels load as saved.
## "last_completed" is optional (older files lack it): "" or a valid puzzle
## id, otherwise "".
static func from_dict(data: Variant) -> Stats:
	var stats: Stats = Stats.new()
	if typeof(data) != TYPE_DICTIONARY:
		return stats
	var last_value: Variant = (data as Dictionary).get("last_completed")
	if DataCheck.is_puzzle_id(last_value):
		stats._last_completed_id = last_value
	var levels_value: Variant = (data as Dictionary).get("levels")
	if typeof(levels_value) != TYPE_ARRAY:
		return stats
	var levels: Array = levels_value
	if levels.size() != Levels.COUNT:
		return stats
	for level: int in Levels.COUNT:
		stats._load_level(level, levels[level])
	return stats


func _clear_level(level: int) -> void:
	_started[level] = 0
	_completed[level] = 0
	_best_time[level] = -1
	_total_time[level] = 0
	_best_score[level] = -1


func _load_level(level: int, value: Variant) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		return
	var dict: Dictionary = value
	var top: int = DataCheck.MAX_EXACT
	for key: String in ["started", "completed", "total_time"]:
		if not DataCheck.int_in(dict.get(key), 0, top):
			return
	for key: String in ["best_time", "best_score"]:
		if not DataCheck.int_in(dict.get(key), -1, top):
			return
	var started_count: int = int(dict["started"])
	var completed: int = int(dict["completed"])
	var best_t: int = int(dict["best_time"])
	var total: int = int(dict["total_time"])
	var best_f: int = int(dict["best_score"])
	if completed > started_count:
		return
	if completed == 0:
		if best_t != -1 or best_f != -1 or total != 0:
			return
	else:
		if best_t < 0 or best_f < 0 or best_f > 2 * Scoring.points(level):
			return
		if best_t > total / completed:
			return
	_started[level] = started_count
	_completed[level] = completed
	_best_time[level] = best_t
	_total_time[level] = total
	_best_score[level] = best_f
