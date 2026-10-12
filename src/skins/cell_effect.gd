class_name CellEffect extends RefCounted
## One running board animation (docs/DESIGN_SYSTEM.md section 6). The caller
## drives progress with a Motion tween and asks BoardPainter.draw_effects to
## draw it on a layer above the board.

enum Kind { PLACE, ERASE, CROSS, RESTORE, COMPLETE }

var cell: int
var digit: int
var kind: int
var progress: float                     # 0 to 1, driven by the caller with Motion timings
