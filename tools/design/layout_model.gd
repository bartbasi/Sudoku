extends RefCounted
## A model of the play and lesson screen layout rules in docs/DESIGN_SYSTEM.md
## section 4, in dp. check_samples.gd runs it on the screens we design for and
## on the foldable windows of section 4.11, and checks that everything fits,
## every touch target is 48 dp or more and the candidates meet their floor.
## The real layout is PlayArea (board-input-dev) and the screens
## (ui-systems-dev, lessons-dev); they follow the same rules.
## Study code in tools/, never shipped. Owner: senior-graphic-designer.

const Palettes := preload("res://tools/design/directions/palettes.gd")
const RingLayouts := preload("res://tools/design/directions/ring_layouts.gd")
const Fonts := preload("res://tools/design/directions/fonts.gd")

# Layout constants, dp (DESIGN_SYSTEM.md section 4).
const TOUCH_MIN: float = 48.0
const HEADER_ROW: float = 48.0 ## Touch height of the header row (the play screen's, above PlayArea).
const BAND_MIN: float = 48.0 ## PlayArea's band: header row bottom to the board's outer edge.
const BAND_MAX: float = 112.0
## The info zone is the header row plus the band; the hint panel covers it.
const INFO_ZONE_MIN: float = HEADER_ROW + BAND_MIN
const INFO_ZONE_MAX: float = HEADER_ROW + BAND_MAX
const BOARD_GAP_MIN: float = 12.0 ## Board shadow to the controls.
const BOARD_GAP_MAX: float = 40.0
const KEY_MIN: float = 40.0 ## Key face height; with the 8 dp row gap the touch area is 48.
const KEY_MAX: float = 64.0
const ACTION_RATIO: float = 1.8 ## Right column width as a multiple of a digit key's width.
const ACTION_MIN: float = 116.0
const ACTION_MAX: float = 160.0
const COLUMN_MAX: float = 600.0 ## Widest content column, on tablets.
const HINT_FACE_W: float = 64.0
const ICON_FACE: float = 40.0 ## Pause, back, close: face; touch 48.
const TIME_MIN_W: float = 80.0
const SCORE_MIN_W: float = 60.0
const HEADER_GUARD: float = 12.0 ## Smallest gap on each side of the time and score blocks.
const BODY_SIZES: Array[float] = [14.0, 13.0, 12.0] ## Lesson text steps down on short screens.
const LESSON_BOARD_SHARE: float = 0.8 ## Lesson text steps down while the board is below this share of its width-bound size.
const LESSON_TOP_ROW: float = 32.0 ## Lesson card's top row: sticker, step caption, close face (touch 48).
const LESSON_TITLE_MIN_BOARD: float = 260.0 ## Below this the lesson title line is hidden.
const LESSON_BOARD_FLOOR: float = 220.0 ## Below this the lesson text scrolls inside the card instead.

# Window shapes (DESIGN_SYSTEM.md 4.11, Phase 6).
const COLUMN_MIN: float = 304.0 ## Narrowest column holding the header row and the pad (the 320 dp screen's column), stacked or beside the board.
const SIDE_MAX: float = 360.0 ## Widest side column.
const SIDE_GAP: float = 16.0 ## Board block (with its outer line and shadow) to the side column.
const BOARD_MIN: float = 240.0 ## Smallest play board. Below it in both arrangements the window is too small.
const CONTENT_MIN_H: float = 264.0 ## Shortest content box in any arrangement: the main menu's button stack.
const MENU_WORDMARK: float = 66.0 ## Main menu wordmark with tilt and shadow (7.1).
const MENU_BUTTONS: float = 264.0 ## Main menu buttons: 4 rows of 56, 3 gaps of 12, shadow 4 (7.1).
const HERO_MIN: float = 64.0
const HERO_GAP: float = 24.0 ## space_xl above and below the hero.
const PAUSE_BUTTONS: float = 196.0 ## Pause menu: 3 rows of 56, 2 gaps of 12, shadow 4 (7.8).
const PAUSE_TOP: float = 118.0 ## Pause menu: PAUSED 44, 12, level sticker about 30, 12, time 20.

enum Arrangement { STACKED, SIDE, TOO_SMALL }
const ARRANGEMENT_NAMES: PackedStringArray = ["stacked", "side by side", "too small"]

## The longest lesson text so far (LESSONS.md, lesson 2, screen 1).
const LESSON_TEXT: String = "See the small digits in each empty cell? We call this the ring. It helps you keep track of which digits might still go in that cell. At the start, all nine are there. Tap the marked cell in the middle of the board."


## A screen or window: size and safe insets, dp.
class Screen extends RefCounted:
	var label: String
	var w: float
	var h: float
	var top: float
	var bottom: float
	var judged: bool ## Readability is judged here (360 dp wide, board width-bound).
	var density: float = 2.0 ## Device pixels per dp, for the candidate size.
	var expected: int = -1 ## The Arrangement the rules must pick here, or -1 when not pinned.


## The result of laying out one screen.
class StackLayout extends RefCounted:
	var screen: Screen
	var arrangement: int = Arrangement.STACKED
	var content: Vector2 ## The content box: the safe area inset by page_margin on every side.
	var content_w: float ## The column holding the header row, the info zone and the pad (stacked: the whole column; side: the side column).
	var menu_w: float ## Width of the main menu's button column.
	var info_zone: float
	var hint_panel: float
	var board: float ## Side of the cell square, dp.
	var board_width_bound: bool
	var gap: float
	var key_h: float
	var key_w: float
	var action_w: float
	var spare: float ## Height left after the stack, split above and below it.
	var spare_x: float ## Side by side: width left after board, gap and side column, split left and right.
	var header_fits: bool
	var problems: PackedStringArray = PackedStringArray()

	func cell() -> float:
		return board / 9.0


static func screens() -> Array[Screen]:
	return [
		_screen("320 x 568, notch and gesture bar", 320.0, 568.0, 32.0, 24.0, false),
		_screen("360 x 640", 360.0, 640.0, 24.0, 24.0, false),
		_screen("360 x 800 (judged)", 360.0, 800.0, 32.0, 24.0, true),
		_screen("411 x 914 (1080 x 2400 px)", 411.43, 914.29, 32.0, 24.0, false),
		_screen("1024 x 1366 tablet", 1024.0, 1366.0, 24.0, 24.0, false),
	]


## Foldable and split screen windows (DESIGN_SYSTEM.md 4.11). Galaxy Z Fold5
## at density 2.625. A window gets the status bar inset (32) only when it
## touches the top of the screen, and the gesture bar inset (24) only when
## it touches the bottom. The last rows sit on either side of each limit.
static func window_screens() -> Array[Screen]:
	var stacked: int = Arrangement.STACKED
	var side: int = Arrangement.SIDE
	var small: int = Arrangement.TOO_SMALL
	return [
		_window("Fold5 cover 344 x 882", 344.0, 882.0, 32.0, 24.0, stacked),
		_window("Fold5 inner 690 x 829", 690.0, 829.0, 32.0, 24.0, stacked),
		_window("Fold5 inner, taskbar 690 x 829", 690.0, 829.0, 32.0, 48.0, stacked),
		_window("inner left/right half 345 x 829", 345.0, 829.0, 32.0, 24.0, stacked),
		_window("inner top half 690 x 400", 690.0, 400.0, 32.0, 0.0, side),
		_window("inner bottom half 690 x 400", 690.0, 400.0, 0.0, 24.0, side),
		_window("cover top half 344 x 430", 344.0, 430.0, 32.0, 0.0, small),
		_window("cover bottom half 344 x 430", 344.0, 430.0, 0.0, 24.0, small),
		_window("inner two thirds wide 460 x 829", 460.0, 829.0, 32.0, 24.0, stacked),
		_window("inner one third wide 230 x 829", 230.0, 829.0, 32.0, 24.0, small),
		_window("inner top two thirds 690 x 553", 690.0, 553.0, 32.0, 0.0, side),
		_window("inner bottom third 690 x 276", 690.0, 276.0, 0.0, 24.0, small),
		_window("cover top two thirds 344 x 588", 344.0, 588.0, 32.0, 0.0, stacked),
		_window("QA L6 window 700 x 420", 700.0, 420.0, 0.0, 0.0, side),
		_window("smallest side by side 583 x 280", 583.0, 280.0, 0.0, 0.0, side),
		_window("too narrow for side 582 x 280", 582.0, 280.0, 0.0, 0.0, small),
		_window("too short 600 x 279", 600.0, 279.0, 0.0, 0.0, small),
		_window("smallest stacked 320 x 507", 320.0, 507.0, 0.0, 0.0, stacked),
		_window("too short for stacked 320 x 506", 320.0, 506.0, 0.0, 0.0, small),
		_window("too narrow 319 x 800", 319.0, 800.0, 0.0, 0.0, small),
	]


## The windows of window_screens() the game supports (not too small), for
## the fit checks in pad_fit.gd and ui_fit.gd.
static func supported_windows(skin: GameSkin) -> Array[Screen]:
	var out: Array[Screen] = []
	for screen: Screen in window_screens():
		if arrangement(content_size(screen, skin), skin) != Arrangement.TOO_SMALL:
			out.append(screen)
	return out


static func _screen(label: String, w: float, h: float, top: float, bottom: float, judged: bool) -> Screen:
	var s: Screen = Screen.new()
	s.label = label
	s.w = w
	s.h = h
	s.top = top
	s.bottom = bottom
	s.judged = judged
	s.expected = Arrangement.STACKED
	return s


static func _window(label: String, w: float, h: float, top: float, bottom: float, expected: int) -> Screen:
	var s: Screen = _screen(label, w, h, top, bottom, false)
	s.density = 2.625
	s.expected = expected
	return s


## The content box: the safe area inset by page_margin on every side.
static func content_size(screen: Screen, skin: GameSkin) -> Vector2:
	var margin: float = skin.page_margin
	return Vector2(screen.w - 2.0 * margin, screen.h - screen.top - screen.bottom - 2.0 * margin)


## The board side the stacked play layout gives in this content box, or 0
## when the column is narrower than COLUMN_MIN.
static func stacked_board(content: Vector2, skin: GameSkin) -> float:
	if content.x < COLUMN_MIN - 0.01:
		return 0.0
	var over: float = skin.line_outer_w + skin.shadow_offset
	var controls_min: float = 3.0 * KEY_MIN + 2.0 * skin.space_s
	var fixed: float = INFO_ZONE_MIN + over + BOARD_GAP_MIN + controls_min
	return maxf(0.0, minf(minf(content.x, COLUMN_MAX) - over, content.y - fixed))


## The board side the side by side play layout gives, or 0 when the side
## column does not fit its minimum height.
static func side_board(content: Vector2, skin: GameSkin) -> float:
	var over: float = skin.line_outer_w + skin.shadow_offset
	var controls_min: float = 3.0 * KEY_MIN + 2.0 * skin.space_s
	if content.y < INFO_ZONE_MIN + controls_min - 0.01:
		return 0.0
	return maxf(0.0, minf(minf(content.y - over, content.x - over - SIDE_GAP - COLUMN_MIN), COLUMN_MAX - over))


## The rule of 4.11: the arrangement with the larger board, stacked on a
## tie; too small when the content box is under CONTENT_MIN_H or neither
## arrangement reaches BOARD_MIN.
static func arrangement(content: Vector2, skin: GameSkin) -> int:
	if content.y < CONTENT_MIN_H - 0.01:
		return Arrangement.TOO_SMALL
	var stacked: float = stacked_board(content, skin)
	var side: float = side_board(content, skin)
	if maxf(stacked, side) < BOARD_MIN - 0.01:
		return Arrangement.TOO_SMALL
	return Arrangement.SIDE if side > stacked + 0.5 else Arrangement.STACKED


## The play screen: info zone (header row and band), board, gap, controls;
## or the board beside a column of header row, band and pad.
static func play(screen: Screen, skin: GameSkin) -> StackLayout:
	var content: Vector2 = content_size(screen, skin)
	var kind: int = arrangement(content, skin)
	if kind == Arrangement.SIDE:
		return _side(screen, skin, INFO_ZONE_MIN, INFO_ZONE_MAX)
	if kind == Arrangement.TOO_SMALL:
		return _too_small(screen, skin)
	return _stack(screen, skin, INFO_ZONE_MIN, INFO_ZONE_MAX)


## The lesson screen: the info zone is the lesson card (its top row holds the
## lesson sticker, the step caption and the close button), whose height
## follows its text. Stacked, on short screens, in this order: the text steps
## down a size while the board is under LESSON_BOARD_SHARE of its width-bound
## size; the title line hides while the board is under LESSON_TITLE_MIN_BOARD;
## and the board never drops under LESSON_BOARD_FLOOR: the text scrolls inside
## the card instead. Side by side the board does not depend on the card: the
## text steps down while the card is taller than the side column leaves it,
## then the title hides, then the text scrolls. lesson_scrolls tells whether
## it had to.
static var lesson_scrolls: bool = false
static var lesson_text_size: float = 0.0
static var lesson_title_shown: bool = true


static func lesson(screen: Screen, skin: GameSkin) -> StackLayout:
	var content: Vector2 = content_size(screen, skin)
	var kind: int = arrangement(content, skin)
	lesson_scrolls = false
	lesson_title_shown = true
	lesson_text_size = BODY_SIZES[0]
	if kind == Arrangement.TOO_SMALL:
		return _too_small(screen, skin)
	if kind == Arrangement.SIDE:
		return _side_lesson(screen, skin, content)
	var result: StackLayout = null
	var column: float = minf(content.x, COLUMN_MAX)
	var width_bound: float = column - skin.line_outer_w - skin.shadow_offset
	for size: float in BODY_SIZES:
		lesson_text_size = size
		var card: float = _card_height(column, skin, size, true)
		result = _stack(screen, skin, card, card)
		if result.board >= LESSON_BOARD_SHARE * width_bound:
			return result
	if result.board < LESSON_TITLE_MIN_BOARD:
		lesson_title_shown = false
		var short_card: float = _card_height(column, skin, lesson_text_size, false)
		result = _stack(screen, skin, short_card, short_card)
	if result.board < LESSON_BOARD_FLOOR:
		lesson_scrolls = true
		var zone: float = result.info_zone - (LESSON_BOARD_FLOOR - result.board)
		result = _stack(screen, skin, zone, zone)
	return result


static func _side_lesson(screen: Screen, skin: GameSkin, content: Vector2) -> StackLayout:
	var over: float = skin.line_outer_w + skin.shadow_offset
	var board: float = side_board(content, skin)
	var side_w: float = clampf(content.x - board - over - SIDE_GAP, COLUMN_MIN, SIDE_MAX)
	var card_max: float = content.y - (3.0 * KEY_MIN + 2.0 * skin.space_s)
	var card: float = 0.0
	for size: float in BODY_SIZES:
		lesson_text_size = size
		card = _card_height(side_w, skin, size, true)
		if card <= card_max + 0.01:
			return _side(screen, skin, card, card)
	lesson_title_shown = false
	card = _card_height(side_w, skin, lesson_text_size, false)
	if card > card_max + 0.01:
		lesson_scrolls = true
		card = card_max
	return _side(screen, skin, card, card)


## The lesson card's height plus the space_s gap under it (the band).
static func _card_height(column: float, skin: GameSkin, body: float, with_title: bool) -> float:
	var text_w: float = column - skin.shadow_offset - 2.0 * skin.space_m
	var font: Font = Fonts.get_font(Fonts.Weight.SEMIBOLD)
	var size: int = roundi(body)
	var block: Vector2 = font.get_multiline_string_size(LESSON_TEXT, HORIZONTAL_ALIGNMENT_LEFT, text_w, size)
	var title: float = Fonts.get_font(Fonts.Weight.HEAVY).get_height(16) + skin.space_xs if with_title else 0.0
	return 2.0 * skin.space_m + LESSON_TOP_ROW + skin.space_s + title + block.y + skin.shadow_offset + skin.space_s


static func _stack(screen: Screen, skin: GameSkin, zone_min: float, zone_max: float) -> StackLayout:
	var out: StackLayout = StackLayout.new()
	out.screen = screen
	out.arrangement = Arrangement.STACKED
	out.content = content_size(screen, skin)
	out.content_w = minf(out.content.x, COLUMN_MAX)
	out.menu_w = out.content_w
	var avail: float = out.content.y
	var over: float = skin.line_outer_w + skin.shadow_offset
	var width_bound: float = out.content_w - over
	var controls_min: float = 3.0 * KEY_MIN + 2.0 * skin.space_s
	var fixed: float = zone_min + over + BOARD_GAP_MIN + controls_min
	out.board = minf(width_bound, avail - fixed)
	out.board_width_bound = out.board >= width_bound - 0.01
	var spare: float = avail - fixed - out.board
	out.key_h = KEY_MIN + minf(spare / 3.0, KEY_MAX - KEY_MIN)
	spare -= 3.0 * (out.key_h - KEY_MIN)
	var zone_add: float = minf(spare * 0.5, zone_max - zone_min)
	out.info_zone = zone_min + zone_add
	spare -= zone_add
	var gap_add: float = minf(spare, BOARD_GAP_MAX - BOARD_GAP_MIN)
	out.gap = BOARD_GAP_MIN + gap_add
	spare -= gap_add
	out.spare = spare
	out.hint_panel = out.info_zone - skin.space_s
	_pad_and_checks(out, skin, zone_min)
	if out.content.y < MENU_WORDMARK + 2.0 * HERO_GAP + HERO_MIN + MENU_BUTTONS - 0.01:
		out.problems.append("main menu needs %.0f dp, has %.0f" % [MENU_WORDMARK + 2.0 * HERO_GAP + HERO_MIN + MENU_BUTTONS, out.content.y])
	return out


## Side by side: the board at the left, as tall as the content box allows;
## SIDE_GAP; then the side column, COLUMN_MIN to SIDE_MAX wide, holding the
## header row and band (the info zone) on top and the pad at the bottom.
## Height in the side column: keys grow first to KEY_MAX, then the band to
## its max, and anything left is split above and below the column. Width
## left over is split left and right of the whole group.
static func _side(screen: Screen, skin: GameSkin, zone_min: float, zone_max: float) -> StackLayout:
	var out: StackLayout = StackLayout.new()
	out.screen = screen
	out.arrangement = Arrangement.SIDE
	out.content = content_size(screen, skin)
	var over: float = skin.line_outer_w + skin.shadow_offset
	out.board = side_board(out.content, skin)
	out.board_width_bound = out.board < out.content.y - over - 0.01
	out.content_w = clampf(out.content.x - out.board - over - SIDE_GAP, COLUMN_MIN, SIDE_MAX)
	out.spare_x = out.content.x - (out.board + over + SIDE_GAP + out.content_w)
	out.menu_w = (minf(out.content.x, COLUMN_MAX) - skin.space_xl) * 0.5
	var controls_min: float = 3.0 * KEY_MIN + 2.0 * skin.space_s
	var spare: float = out.content.y - zone_min - controls_min
	out.key_h = KEY_MIN + clampf(spare / 3.0, 0.0, KEY_MAX - KEY_MIN)
	spare -= 3.0 * (out.key_h - KEY_MIN)
	var zone_add: float = clampf(spare, 0.0, zone_max - zone_min)
	out.info_zone = zone_min + zone_add
	spare -= zone_add
	out.gap = 0.0
	out.spare = spare
	out.hint_panel = out.info_zone - skin.space_s
	_pad_and_checks(out, skin, zone_min)
	if out.board < BOARD_MIN - 0.01:
		out.problems.append("side by side board %.0f dp, under BOARD_MIN" % out.board)
	if out.spare_x < -0.01:
		out.problems.append("side by side is %.0f dp too wide" % -out.spare_x)
	if out.content.y < MENU_BUTTONS - 0.01 or out.content.y < MENU_WORDMARK + HERO_GAP + HERO_MIN - 0.01:
		out.problems.append("main menu halves do not fit %.0f dp" % out.content.y)
	if out.content.y < PAUSE_BUTTONS - 0.01 or out.content.y < PAUSE_TOP - 0.01:
		out.problems.append("pause menu halves do not fit %.0f dp" % out.content.y)
	return out


## A window under the limits: no layout, only the too small message.
static func _too_small(screen: Screen, skin: GameSkin) -> StackLayout:
	var out: StackLayout = StackLayout.new()
	out.screen = screen
	out.arrangement = Arrangement.TOO_SMALL
	out.content = content_size(screen, skin)
	out.content_w = minf(maxf(out.content.x, 0.0), COLUMN_MAX)
	out.menu_w = out.content_w
	out.board = maxf(stacked_board(out.content, skin), side_board(out.content, skin))
	return out


## Pad widths in the column, and the checks both arrangements share.
static func _pad_and_checks(out: StackLayout, skin: GameSkin, zone_min: float) -> void:
	var faces: float = out.content_w - skin.shadow_offset
	var rest: float = faces - 2.0 * skin.space_s - skin.group_gap
	out.key_w = rest / (3.0 + ACTION_RATIO)
	out.action_w = ACTION_RATIO * out.key_w
	if out.action_w < ACTION_MIN or out.action_w > ACTION_MAX:
		out.action_w = clampf(out.action_w, ACTION_MIN, ACTION_MAX)
		out.key_w = (rest - out.action_w) / 3.0
	var header: float = HINT_FACE_W + HEADER_GUARD + TIME_MIN_W + skin.space_s + SCORE_MIN_W + HEADER_GUARD + ICON_FACE
	out.header_fits = header <= faces
	if out.board <= 0.0:
		out.problems.append("no room for the board")
	if out.spare < -0.01:
		out.problems.append("the stack is %.0f dp too tall" % -out.spare)
	if out.key_w + skin.space_s < TOUCH_MIN or out.key_h + skin.space_s < TOUCH_MIN:
		out.problems.append("digit key touch area %.0f x %.0f dp" % [out.key_w + skin.space_s, out.key_h + skin.space_s])
	var undo_w: float = (out.action_w - skin.space_s) * 0.5
	if undo_w + skin.space_s < TOUCH_MIN:
		out.problems.append("Undo and Erase touch areas are %.0f dp wide" % (undo_w + skin.space_s))
	if not out.header_fits:
		out.problems.append("header row needs %.0f dp, has %.0f" % [header, faces])
	if out.content_w < COLUMN_MIN - 0.01:
		out.problems.append("column %.0f dp, under COLUMN_MIN" % out.content_w)
	if out.hint_panel < 88.0 - 0.01 and zone_min == INFO_ZONE_MIN:
		out.problems.append("hint panel is %.0f dp tall, needs 88" % out.hint_panel)


## Candidate font size in device pixels for a board of the given side (dp) at
## a density (px per dp), fitted like the board fits it: ring layout A, the
## skin's ring inset and candidate gap, the built-in font.
static func candidate_px(board_dp: float, density: float, skin: GameSkin) -> int:
	var ring: float = (board_dp / 9.0 - 2.0 * skin.ring_inset) * density
	return RingLayouts.fit_font_size(RingLayouts.Layout.ROWS, ring, Fonts.get_font(Fonts.Weight.SEMIBOLD))


## Height of the tallest digit's ink at a candidate font size, in px.
static func ink_px(font_px: int) -> float:
	return Fonts.digit_cell(Fonts.get_font(Fonts.Weight.SEMIBOLD), font_px).y
