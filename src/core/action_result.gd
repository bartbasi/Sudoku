class_name ActionResult
extends RefCounted
## What one press_digit, erase or undo did.

## False means nothing happens (GDD Terms): no change, no sound, no undo step.
var applied: bool = false
## True for place, replace, cross and restore (GDD 3.4).
var click: bool = false
## The cell acted on and every cell whose marks changed, ascending.
var changed_cells: PackedInt32Array = PackedInt32Array()
var completed: bool = false
var full_board_conflict: bool = false
var hint_closed: bool = false
