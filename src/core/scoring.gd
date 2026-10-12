class_name Scoring
extends RefCounted
## Score numbers and formulas (GDD 9 and 10.3). Every function returns 0 for
## a level outside 0 to 4.

const MAX_HINTS := 5

const _POINTS: PackedInt32Array = [100, 200, 400, 700, 1000]
const _PAR_SECONDS: PackedInt32Array = [480, 720, 1200, 1800, 2700]


static func points(level: int) -> int:
	if not Levels.is_valid(level):
		return 0
	return _POINTS[level]


static func par_seconds(level: int) -> int:
	if not Levels.is_valid(level):
		return 0
	return _PAR_SECONDS[level]


## One fifth of the level's points.
static func hint_cost(level: int) -> int:
	return points(level) / 5


## S = B - H * n, with n held to 0 to 5 so S is never below zero.
static func live_score(level: int, hints_bought: int) -> int:
	var hints: int = clampi(hints_bought, 0, MAX_HINTS)
	return maxi(points(level) - hint_cost(level) * hints, 0)


## T = floor(B * (P - t) / P) when t < P, otherwise 0. A negative t counts as 0.
static func time_bonus(level: int, seconds: int) -> int:
	var par: int = par_seconds(level)
	var t: int = maxi(seconds, 0)
	if par == 0 or t >= par:
		return 0
	return points(level) * (par - t) / par


## F = S + T.
static func final_score(level: int, hints_bought: int, seconds: int) -> int:
	return live_score(level, hints_bought) + time_bonus(level, seconds)
