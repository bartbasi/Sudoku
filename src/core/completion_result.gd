class_name CompletionResult
extends RefCounted
## What the completion screen shows (GDD 12). App fills it.

var level: int = 0
var seconds: int = 0
var points_after_hints: int = 0
var time_bonus: int = 0
var final_score: int = 0
var hints_used: int = 0
## Stats.NEW_BEST_* bits.
var new_best: int = 0
