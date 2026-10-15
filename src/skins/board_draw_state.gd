class_name BoardDrawState extends RefCounted
## Everything BoardPainter needs to draw one board, filled in by the caller
## (board-input-dev's BoardView) from the GameSession. The painter only reads
## it. Cells are 0 to 80, digits 1 to 9, marks are Board.Mark values with
## index cell * 9 + digit - 1 (docs/ARCHITECTURE.md sections 2 and 6).

var digits: PackedInt32Array            # 81, givens and placed digits, 0 where empty
var givens: PackedInt32Array            # 81, 0 where not given
var marks: PackedByteArray              # 729 Board.Mark values
var selected: int = -1
var mode: int = 0                       # GameSession.Mode
var peers: PackedInt32Array
var same_digit: PackedInt32Array
var conflicts: PackedInt32Array
var hint_targets: PackedInt32Array
var hint_reasons: PackedInt32Array
var hint_crosses: PackedInt32Array      # mark indices (cell * 9 + digit - 1) the hint says to cross (Hint.eliminations)
var lesson_marks: PackedInt32Array      # cells a lesson screen points at
var locked: bool = false                # completed board
var show_ring: bool = true              # false: draw no candidate and no X, except each open candidate in hint_crosses,
                                        # drawn in its hint look; digits, highlights and conflicts are unchanged
