class_name Layout extends RefCounted
## The layout constants of DESIGN_SYSTEM.md section 4.6, in dp. They are the
## same in every skin, so they are not skin tokens. PlayArea, the ui screens
## and the lesson player read them from here; nobody repeats a number.
## Owner: ui-motion-artist.

## Smallest touch area, both ways.
const TOUCH_MIN: float = 48.0
## Height of the play screen's header row and of every title row.
const HEADER_ROW: float = 48.0
## PlayArea's band: from the bottom of the header row to the board's outer edge.
const BAND_MIN: float = 48.0
## The most the band grows.
const BAND_MAX: float = 112.0
## Bottom of the board's shadow to the top of the controls.
const BOARD_GAP_MIN: float = 12.0
## The most that gap grows.
const BOARD_GAP_MAX: float = 40.0
## Key face height, smallest.
const KEY_MIN: float = 40.0
## Key face height, largest.
const KEY_MAX: float = 64.0
## Width of the pad's right column, as a multiple of a digit key's width.
const ACTION_RATIO: float = 1.8
## Narrowest right column (CROSS OUT must fit).
const ACTION_MIN: float = 116.0
## Widest right column.
const ACTION_MAX: float = 160.0
## Widest content column, centered, on tablets.
const COLUMN_MAX: float = 600.0
## Width of the Hint button's face.
const HINT_FACE_W: float = 64.0
## Narrowest time block (it grows to fit 1:02:05).
const TIME_MIN_W: float = 80.0
## Narrowest score block.
const SCORE_MIN_W: float = 60.0
## Smallest gap between Hint and the time block, and between the score block and Pause.
const HEADER_GUARD: float = 12.0
## Height of the lesson card's top row.
const LESSON_TOP_ROW: float = 32.0
## The lesson title line hides when the board would be smaller.
const LESSON_TITLE_MIN_BOARD: float = 260.0
## The lesson board never gets smaller; the lesson text scrolls instead.
const LESSON_BOARD_FLOOR: float = 220.0
