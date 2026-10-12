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
## A digit key's face is never wider than this many times its height. When
## the column would make it wider, the pad narrows and is centered in its
## column (DESIGN_SYSTEM.md 4.7).
const KEY_ASPECT_MAX: float = 1.6
## Widest content column, centered, on tablets.
const COLUMN_MAX: float = 600.0
## Width of the Hint button's face.
const HINT_FACE_W: float = 64.0
## Face of every icon button (Pause, back, close on screens) and height of
## the header faces (Hint, time, score). Its touch area is TOUCH_MIN.
const ICON_FACE: float = 40.0
## Face of the close button on the hint panel and the lesson card. Touch
## area TOUCH_MIN.
const CLOSE_FACE: float = 32.0
## Face height of full width buttons: main menu, pause menu, completion, the
## first launch offer, the lesson NEXT button.
const BUTTON_TALL: float = 56.0
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

# Window shapes, DESIGN_SYSTEM.md section 4.11 (Phase 6: split screen and
# foldables). Every screen asks arrangement() so they always agree.

## Narrowest column holding the header row and the pad, stacked or beside the board.
const COLUMN_MIN: float = 304.0
## Widest side column.
const SIDE_MAX: float = 360.0
## From the board's outer line and shadow to the side column.
const SIDE_GAP: float = 16.0
## Smallest play board in either arrangement. Under it the window is too small.
const BOARD_MIN: float = 240.0
## Shortest content box in any arrangement: the main menu's button stack.
const CONTENT_MIN_H: float = 264.0

## STACKED: info zone, board, gap and pad in one column. SIDE: the board at
## the left, the side column (header row, band, pad) at the right.
## TOO_SMALL: the window only shows the too small message.
enum Arrangement { STACKED, SIDE, TOO_SMALL }



## The board side the stacked play layout gives in this content box (the
## safe rect minus page_margin on every side), or 0 when the box is narrower
## than COLUMN_MIN.
## Breakpoint comparisons allow 0.01 dp of float slack, as layout_model.gd does.
static func stacked_board(content: Rect2, skin: GameSkin) -> float:
	var size: Vector2 = content.size
	if size.x < COLUMN_MIN - 0.01:
		return 0.0
	var over: float = _over(skin)
	var fixed: float = HEADER_ROW + BAND_MIN + over + BOARD_GAP_MIN + _pad_min(skin)
	return maxf(0.0, minf(minf(size.x, COLUMN_MAX) - over, size.y - fixed))


## The board side the side by side play layout gives, or 0 when the box is
## shorter than the side column's minimum (header row, BAND_MIN, the pad at KEY_MIN).
static func side_board(content: Rect2, skin: GameSkin) -> float:
	var size: Vector2 = content.size
	if size.y < HEADER_ROW + BAND_MIN + _pad_min(skin) - 0.01:
		return 0.0
	var over: float = _over(skin)
	return maxf(0.0, minf(minf(size.y - over, size.x - over - SIDE_GAP - COLUMN_MIN), COLUMN_MAX - over))


## The arrangement with the larger board, stacked on a tie; TOO_SMALL when
## the box is under CONTENT_MIN_H or neither board reaches BOARD_MIN.
static func arrangement(content: Rect2, skin: GameSkin) -> int:
	if content.size.y < CONTENT_MIN_H - 0.01:
		return Arrangement.TOO_SMALL
	var stacked: float = stacked_board(content, skin)
	var side: float = side_board(content, skin)
	if maxf(stacked, side) < BOARD_MIN - 0.01:
		return Arrangement.TOO_SMALL
	return Arrangement.SIDE if side > stacked + 0.5 else Arrangement.STACKED


## The width of the pad's faces in a column this wide with keys this tall:
## the column minus the shadow, but never so wide that a digit key is wider
## than KEY_ASPECT_MAX times its height (DESIGN_SYSTEM.md 4.7).
static func pad_faces_width(column_w: float, key_h: float, skin: GameSkin) -> float:
	var full: float = maxf(0.0, column_w - skin.shadow_offset)
	var key_w: float = KEY_ASPECT_MAX * key_h
	var widest: float = 3.0 * key_w + 2.0 * skin.space_s + skin.group_gap + clampf(ACTION_RATIO * key_w, ACTION_MIN, ACTION_MAX)
	return minf(full, widest)


## What the board block adds past the cells: the outer line and the shadow.
static func _over(skin: GameSkin) -> float:
	return skin.line_outer_w + skin.shadow_offset


## The pad at its smallest: three rows of KEY_MIN with two space_s gaps.
static func _pad_min(skin: GameSkin) -> float:
	return 3.0 * KEY_MIN + 2.0 * skin.space_s
