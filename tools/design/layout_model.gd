extends RefCounted
## A model of the play and lesson screen layout rules in docs/DESIGN_SYSTEM.md
## section 4, in dp. check_samples.gd runs it on the screens we design for and
## checks that everything fits, every touch target is 48 dp or more and the
## candidates meet their floor. The real layout is PlayArea (board-input-dev)
## and the screens (ui-systems-dev, lessons-dev); they follow the same rules.
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

## The longest lesson text so far (LESSONS.md, lesson 2, screen 1).
const LESSON_TEXT: String = "See the small digits in each empty cell? We call this the ring. It helps you keep track of which digits might still go in that cell. At the start, all nine are there. Tap the marked cell in the middle of the board."


## A screen: size and safe insets, dp.
class Screen extends RefCounted:
	var label: String
	var w: float
	var h: float
	var top: float
	var bottom: float
	var judged: bool ## Readability is judged here (360 dp wide, board width-bound).


## The result of laying out one screen.
class StackLayout extends RefCounted:
	var screen: Screen
	var content_w: float
	var info_zone: float
	var hint_panel: float
	var board: float ## Side of the cell square, dp.
	var board_width_bound: bool
	var gap: float
	var key_h: float
	var key_w: float
	var action_w: float
	var spare: float ## Height left after the stack, split above and below it.
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


static func _screen(label: String, w: float, h: float, top: float, bottom: float, judged: bool) -> Screen:
	var s: Screen = Screen.new()
	s.label = label
	s.w = w
	s.h = h
	s.top = top
	s.bottom = bottom
	s.judged = judged
	return s


## The play screen: info zone (header row and band), board, gap, controls.
static func play(screen: Screen, skin: GameSkin) -> StackLayout:
	return _stack(screen, skin, INFO_ZONE_MIN, INFO_ZONE_MAX)


## The lesson screen: the info zone is the lesson card (its top row holds the
## lesson sticker, the step caption and the close button), whose height
## follows its text. On short screens, in this order: the text steps down a
## size while the board is under LESSON_BOARD_SHARE of its width-bound size;
## the title line hides while the board is under LESSON_TITLE_MIN_BOARD; and
## the board never drops under LESSON_BOARD_FLOOR: the text scrolls inside the
## card instead. lesson_scrolls tells whether it had to.
static var lesson_scrolls: bool = false
static var lesson_text_size: float = 0.0
static var lesson_title_shown: bool = true


static func lesson(screen: Screen, skin: GameSkin) -> StackLayout:
	var result: StackLayout = null
	var width_bound: float = minf(screen.w - 2.0 * skin.page_margin, COLUMN_MAX) - skin.line_outer_w - skin.shadow_offset
	lesson_scrolls = false
	lesson_title_shown = true
	for size: float in BODY_SIZES:
		lesson_text_size = size
		var card: float = _card_height(screen, skin, size, true)
		result = _stack(screen, skin, card, card)
		if result.board >= LESSON_BOARD_SHARE * width_bound:
			return result
	if result.board < LESSON_TITLE_MIN_BOARD:
		lesson_title_shown = false
		var short_card: float = _card_height(screen, skin, lesson_text_size, false)
		result = _stack(screen, skin, short_card, short_card)
	if result.board < LESSON_BOARD_FLOOR:
		lesson_scrolls = true
		var zone: float = result.info_zone - (LESSON_BOARD_FLOOR - result.board)
		result = _stack(screen, skin, zone, zone)
	return result


static func _card_height(screen: Screen, skin: GameSkin, body: float, with_title: bool) -> float:
	var content_w: float = minf(screen.w - 2.0 * skin.page_margin, COLUMN_MAX)
	var text_w: float = content_w - skin.shadow_offset - 2.0 * skin.space_m
	var font: Font = Fonts.get_font(Fonts.Weight.SEMIBOLD)
	var size: int = roundi(body)
	var block: Vector2 = font.get_multiline_string_size(LESSON_TEXT, HORIZONTAL_ALIGNMENT_LEFT, text_w, size)
	var title: float = Fonts.get_font(Fonts.Weight.HEAVY).get_height(16) + skin.space_xs if with_title else 0.0
	return 2.0 * skin.space_m + LESSON_TOP_ROW + skin.space_s + title + block.y + skin.shadow_offset + skin.space_s


static func _stack(screen: Screen, skin: GameSkin, zone_min: float, zone_max: float) -> StackLayout:
	var out: StackLayout = StackLayout.new()
	out.screen = screen
	var margin: float = skin.page_margin
	out.content_w = minf(screen.w - 2.0 * margin, COLUMN_MAX)
	var avail: float = screen.h - screen.top - screen.bottom - 2.0 * margin
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
	# Pad: three digit columns, the group gap, the right column.
	var faces: float = out.content_w - skin.shadow_offset
	var rest: float = faces - 2.0 * skin.space_s - skin.group_gap
	out.key_w = rest / (3.0 + ACTION_RATIO)
	out.action_w = ACTION_RATIO * out.key_w
	if out.action_w < ACTION_MIN or out.action_w > ACTION_MAX:
		out.action_w = clampf(out.action_w, ACTION_MIN, ACTION_MAX)
		out.key_w = (rest - out.action_w) / 3.0
	# Header row: Hint, time, score, Pause.
	var header: float = HINT_FACE_W + HEADER_GUARD + TIME_MIN_W + skin.space_s + SCORE_MIN_W + HEADER_GUARD + ICON_FACE
	out.header_fits = header <= faces
	# Checks.
	if out.board <= 0.0:
		out.problems.append("no room for the board")
	if spare < -0.01:
		out.problems.append("the stack is %.0f dp too tall" % -spare)
	if out.key_w + skin.space_s < TOUCH_MIN or out.key_h + skin.space_s < TOUCH_MIN:
		out.problems.append("digit key touch area %.0f x %.0f dp" % [out.key_w + skin.space_s, out.key_h + skin.space_s])
	var undo_w: float = (out.action_w - skin.space_s) * 0.5
	if undo_w + skin.space_s < TOUCH_MIN:
		out.problems.append("Undo and Erase touch areas are %.0f dp wide" % (undo_w + skin.space_s))
	if not out.header_fits:
		out.problems.append("header row needs %.0f dp, has %.0f" % [header, faces])
	if out.hint_panel < 88.0 - 0.01 and zone_min == INFO_ZONE_MIN:
		out.problems.append("hint panel is %.0f dp tall, needs 88" % out.hint_panel)
	return out


## Candidate font size in device pixels for a board of the given side (dp) at
## a density (px per dp), fitted like the board fits it: ring layout A, the
## skin's ring inset and candidate gap, the built-in font.
static func candidate_px(board_dp: float, density: float, skin: GameSkin) -> int:
	var ring: float = (board_dp / 9.0 - 2.0 * skin.ring_inset) * density
	return RingLayouts.fit_font_size(RingLayouts.Layout.ROWS, ring, Fonts.get_font(Fonts.Weight.SEMIBOLD))


## Height of the tallest digit's ink at a candidate font size, in px.
static func ink_px(font_px: int) -> float:
	return Fonts.digit_cell(Fonts.get_font(Fonts.Weight.SEMIBOLD), font_px).y
