extends Control
## Pop, the four Phase 1 screens: play, lesson, stats and complete.
## Neo-brutalist pop: a lemon page, thick outlines, hard offset shadows,
## tilted stickers, chunky condensed capitals, a scoreboard strip between the
## board and a 2 by 6 key grid (docs/design/direction-pop.md).
##
## One script for the four scenes; each scene sets screen. The capture tool
## sets dark and ring_layout and sizes the root before it enters the tree.
## pad_mode lets a reviewer see the Place look of the pad; the captures use
## Cross Out. Prototype code in tools/, never shipped. Owner: ui-motion-artist.

const Palettes := preload("res://tools/design/directions/palettes.gd")
const SampleState := preload("res://tools/design/directions/sample_state.gd")
const RingLayouts := preload("res://tools/design/directions/ring_layouts.gd")
const Device := preload("res://tools/design/directions/device.gd")
const Kit := preload("res://tools/design/directions/ui/common/kit.gd")
const Block := preload("res://tools/design/directions/ui/common/block.gd")
const Icons := preload("res://tools/design/directions/ui/common/icons.gd")

const DIRECTION: String = "pop"

## Layout rules from the brief, not design tokens.
const KEY_MAX: float = 200.0 ## Keys grow up to this before the header does.
const MAX_GAP: float = 240.0 ## Largest empty band between the board and the controls.
## Icon line weight as a share of the icon side (no token yet): heavy, square.
const ICON_STROKE: float = 0.14
## Sticker tilts from the write-up.
const STICKER_TILT: float = -3.0
const SOLVED_TILT: float = -6.0

@export var screen: String = "play"
var dark: bool = false
var ring_layout: int = RingLayouts.DEFAULT_LAYOUT
var pad_mode: int = SampleState.MODE_CROSS_OUT

var _kit: Kit
var _c: Palettes.Palette
var _s: Palettes.Shape
var _w: float
var _m: float
var _sp: float
var _cw: float ## Width of the faces; hard shadows fall outside it.
var _top: float
var _bottom: float
var _drop: Vector2 ## The hard shadow offset.


func _ready() -> void:
	_kit = Kit.new(DIRECTION, dark, ring_layout, ICON_STROKE, false)
	_c = _kit.colors
	_s = _kit.shape
	_w = size.x
	_m = _s.screen_margin
	_sp = _s.space
	_cw = _s.board_size
	_top = Device.SAFE_TOP
	_bottom = size.y - Device.SAFE_BOTTOM
	_drop = _s.shadow_offset
	_kit.panel(self, Rect2(Vector2.ZERO, size), _c.app_bg, 0.0)
	match screen:
		"play":
			_build_play()
		"lesson":
			_build_lesson()
		"stats":
			_build_stats()
		"complete":
			_build_complete()
		_:
			push_error("Unknown screen: %s" % screen)
	_kit.check.call_deferred(self, screen)


# Screens

func _build_play() -> void:
	var hud: SampleState.Hud = SampleState.hud()
	# A slim top row: the level sticker and a square Pause button.
	var row1: Rect2 = Rect2(_m, _top + _sp * 0.5, _cw, Kit.MIN_TOUCH)
	_sticker(hud.level_name, Palettes.ROLE_BUTTON, _c.tag_bg, _c.tag_text, Vector2(_m, row1.get_center().y), STICKER_TILT)
	_square_button(Rect2(row1.end.x - Kit.MIN_TOUCH + _drop.x, row1.position.y, Kit.MIN_TOUCH, Kit.MIN_TOUCH), Icons.PAUSE, "Pause")
	var board_top: float = row1.end.y + _sp * 0.5
	var board: SampleState.BoardState = SampleState.play_board()
	board.mode = pad_mode
	_kit.board(self, Rect2(_m, board_top, _s.board_size, _s.board_size), board)
	# The scoreboard strip right under the board.
	var strip_y: float = board_top + _s.board_size + _drop.y + _sp
	var strip_h: float = _strip(strip_y, hud)
	var content_bottom: float = strip_y + strip_h + _drop.y
	# Tabs and pad from the bottom; leftover goes above the tabs.
	var key_h: float = Kit.MIN_TOUCH
	var gap: float = _controls_top(key_h) - content_bottom
	if gap > MAX_GAP:
		key_h = minf(KEY_MAX, key_h + (gap - MAX_GAP) * 0.5)
	gap = _controls_top(key_h) - content_bottom
	if gap > MAX_GAP + 1.0:
		_kit.problems.append("empty band of %.0f between the strip and the tabs" % gap)
	_controls(key_h)


func _build_lesson() -> void:
	var step: SampleState.LessonStep = SampleState.lesson_step()
	var row1: Rect2 = Rect2(_m, _top + _sp * 0.5, _cw, Kit.MIN_TOUCH)
	var lesson: String = "Lesson %d of %d" % [step.lesson_number, step.lesson_count]
	_sticker(lesson, Palettes.ROLE_BUTTON, _c.tag_bg, _c.tag_text, Vector2(_m, row1.get_center().y), STICKER_TILT)
	_square_button(Rect2(row1.end.x - Kit.MIN_TOUCH + _drop.x, row1.position.y, Kit.MIN_TOUCH, Kit.MIN_TOUCH), Icons.CLOSE, "Close lesson")
	var title_base: float = row1.end.y + _sp * 0.5 + _kit.cap_height(Palettes.ROLE_TITLE)
	_kit.text_at_baseline(self, step.lesson_title, Palettes.ROLE_TITLE, _c.text, _m, title_base, _cw)
	var board_top: float = title_base + _sp * 1.5
	var board: SampleState.BoardState = step.board
	board.mode = pad_mode
	_kit.board(self, Rect2(_m, board_top, _s.board_size, _s.board_size), board)
	# The step in a speech-bubble card pointing up at the board's middle column.
	var pointer: float = _sp * 1.4
	var bubble_y: float = board_top + _s.board_size + _drop.y + _sp * 0.5 + pointer
	var pad: float = _sp * 1.25
	var label_cap: float = _kit.cap_height(Palettes.ROLE_LABEL)
	var line_gap: float = _sp * 0.3
	var text_w: float = _cw - 2.0 * pad
	var text_h: float = _kit.paragraph_height(step.text, Palettes.ROLE_BODY, text_w, line_gap)
	var bubble: Rect2 = Rect2(_m, bubble_y, _cw, pad + label_cap + _sp * 0.5 + text_h + pad)
	var face: Block = _kit.panel(self, bubble, _c.surface, _s.card_radius, true, true)
	var fill: Color = _c.surface
	var edge: Color = _c.outline
	var weight: float = _s.outline_w
	face.over = func(block: Control) -> void:
		var x: float = block.size.x * 0.5
		var left: Vector2 = Vector2(x - pointer, weight)
		var tip: Vector2 = Vector2(x, -pointer)
		var right: Vector2 = Vector2(x + pointer, weight)
		block.draw_colored_polygon(PackedVector2Array([left, tip, right]), fill)
		block.draw_line(Vector2(left.x - weight * 0.5, weight * 0.5), tip, edge, weight, true)
		block.draw_line(tip, Vector2(right.x + weight * 0.5, weight * 0.5), edge, weight, true)
	var label_base: float = bubble_y + pad + label_cap
	_kit.text_at_baseline(self, "Step %d of %d" % [step.step_number, step.step_count], Palettes.ROLE_LABEL, _c.text_muted, _m + pad, label_base, text_w)
	_kit.paragraph(self, step.text, Palettes.ROLE_BODY, _c.text, _m + pad, label_base + _sp * 0.5, text_w, line_gap)
	var key_h: float = Kit.MIN_TOUCH
	var content_bottom: float = bubble.end.y + _drop.y
	var gap: float = _controls_top(key_h) - content_bottom
	if gap > MAX_GAP:
		key_h = minf(KEY_MAX, key_h + (gap - MAX_GAP) * 0.5)
	elif gap < _sp * 0.5:
		_kit.problems.append("lesson controls overlap the bubble by %.0f" % (_sp * 0.5 - gap))
	_controls(key_h)


func _build_stats() -> void:
	var stats: SampleState.Stats = SampleState.stats()
	var row1: Rect2 = Rect2(_m, _top + _sp * 0.5, _cw, Kit.MIN_TOUCH)
	_square_button(Rect2(_m - (Kit.MIN_TOUCH - _face_side()) * 0.5, row1.position.y, Kit.MIN_TOUCH, Kit.MIN_TOUCH), Icons.BACK, "Back")
	var title_x: float = _m + _face_side() + _sp * 1.5
	_kit.text(self, "Stats", Palettes.ROLE_TITLE, _c.text, Rect2(title_x, row1.position.y, row1.end.x - title_x, row1.size.y), HORIZONTAL_ALIGNMENT_LEFT)
	# One outlined block per level: a colored sticker, a chunky bar for done
	# out of started, and the numbers in a grid.
	var headers: Array[String] = ["Started", "Done", "Best", "Average", "Best score"]
	var stickers: Array[Array] = [
		[_c.tag_bg, _c.tag_text],
		[_c.accent_2, _c.text_on_accent_2],
		[_c.accent, _c.text_on_accent],
	]
	var pad: float = _sp * 1.2
	var label_cap: float = _kit.cap_height(Palettes.ROLE_LABEL)
	var value_cap: float = _kit.cap_height(Palettes.ROLE_HUD_VALUE)
	var sticker_h: float = _kit.line_height(Palettes.ROLE_BUTTON) + _sp * 0.5
	# Room below the tilted sticker and its shadow before the grid.
	var below_sticker: float = _drop.y + _sp * 1.5
	var block_h: float = pad + sticker_h + below_sticker + label_cap + _sp * 0.6 + value_cap + pad
	var square: float = _sp * 3.0
	var lessons_h: float = pad + label_cap + _sp * 0.75 + square + pad
	# Share the spare height out to the blocks, so the page is not half empty.
	var count_blocks: float = float(stats.levels.size())
	var used: float = (row1.end.y + _sp * 0.5) + count_blocks * (block_h + _drop.y + _sp) + lessons_h + _drop.y
	var spare: float = clampf((_bottom - _sp - used) / (count_blocks + 1.0), 0.0, _sp * 3.0)
	pad += spare * 0.5
	block_h += spare
	lessons_h += spare
	var inner: float = _cw - 2.0 * pad
	var widths: Array[float] = []
	var total: float = 0.0
	for col: int in headers.size():
		var width: float = _kit.text_width(headers[col], Palettes.ROLE_LABEL)
		for level: SampleState.LevelStats in stats.levels:
			width = maxf(width, _kit.text_width(_stat_values(level)[col], Palettes.ROLE_HUD_VALUE))
		widths.append(width)
		total += width
	var col_gap: float = (inner - total) / float(headers.size() - 1)
	if col_gap < _sp * 0.5:
		_kit.problems.append("stats grid is %.0f wide in %.0f" % [total, inner])
	var y: float = row1.end.y + _sp * 0.5
	for i: int in stats.levels.size():
		var level: SampleState.LevelStats = stats.levels[i]
		var block: Rect2 = Rect2(_m, y, _cw, block_h)
		_kit.panel(self, block, _c.surface, _s.card_radius, true, true)
		var colors: Array = stickers[i % stickers.size()]
		var sticker_w: float = _sticker(level.level_name, Palettes.ROLE_BUTTON, colors[0], colors[1], Vector2(_m + pad, y + pad + sticker_h * 0.5), STICKER_TILT if i % 2 == 0 else -STICKER_TILT)
		# Done out of started.
		var bar_x: float = _m + pad + sticker_w + _sp * 1.5
		var bar: Rect2 = Rect2(bar_x, y + pad + sticker_h * 0.5 - _sp, block.end.x - pad - bar_x, _sp * 2.0)
		_kit.panel(self, bar, _c.surface, _s.chip_radius * 0.5, true)
		var share: float = float(level.completed) / float(level.started) if level.started > 0 else 0.0
		if share > 0.0:
			var fill: Rect2 = Rect2(bar.position, Vector2(bar.size.x * share, bar.size.y))
			_kit.panel(self, fill, _c.chart_bar, _s.chip_radius * 0.5, true)
		var label_base: float = y + pad + sticker_h + below_sticker + label_cap
		var value_base: float = label_base + _sp * 0.6 + value_cap
		var x: float = _m + pad
		var values: Array[String] = _stat_values(level)
		for col: int in headers.size():
			_kit.text_at_baseline(self, headers[col], Palettes.ROLE_LABEL, _c.text_muted, x, label_base, widths[col] + 1.0)
			_kit.text_at_baseline(self, values[col], Palettes.ROLE_HUD_VALUE, _c.text, x, value_base, widths[col] + 1.0)
			x += widths[col] + col_gap
		y += block_h + _drop.y + _sp
	# Lessons completed: five chunky squares, four filled.
	var lessons: Rect2 = Rect2(_m, y, _cw, lessons_h)
	_kit.panel(self, lessons, _c.surface, _s.card_radius, true, true)
	var count: String = "Lessons completed %d of %d" % [stats.lessons_completed, stats.lessons_total]
	_kit.text_at_baseline(self, count, Palettes.ROLE_LABEL, _c.text, _m + pad, y + pad + label_cap, inner)
	var square_y: float = y + pad + label_cap + _sp * 0.75
	for i: int in stats.lessons_total:
		var rect: Rect2 = Rect2(_m + pad + float(i) * (square + _sp), square_y, square, square)
		_kit.panel(self, rect, _c.chart_bar if i < stats.lessons_completed else _c.surface, _s.chip_radius * 0.5, true)
	if lessons.end.y + _drop.y > _bottom:
		_kit.problems.append("stats run %.0f past the safe area" % (lessons.end.y + _drop.y - _bottom))


func _build_complete() -> void:
	var result: SampleState.Completion = SampleState.completion()
	# Buttons at the bottom: Play again (blue) and Menu (white).
	var button_w: float = (_cw - _sp) * 0.5
	var buttons_y: float = _bottom - _sp - Kit.MIN_TOUCH
	var again: Rect2 = Rect2(_m, buttons_y, button_w, Kit.MIN_TOUCH)
	var menu: Rect2 = Rect2(_m + button_w + _sp, buttons_y, button_w, Kit.MIN_TOUCH)
	# The receipt card above them.
	var pad: float = _sp * 1.2
	var row_h: float = _kit.cap_height(Palettes.ROLE_HUD_VALUE) + _sp * 2.0
	var score_h: float = _kit.cap_height(Palettes.ROLE_DISPLAY) + _sp * 2.0
	var receipt_h: float = pad + row_h * 4.0 + _sp + score_h + pad
	var receipt: Rect2 = Rect2(_m, buttons_y - _sp * 1.5 - _drop.y - receipt_h, _cw, receipt_h)
	# SOLVED! on a pink sticker, tilted against a white starburst.
	var room: Rect2 = Rect2(0.0, _top, _w, receipt.position.y - _top - _sp)
	var center: Vector2 = room.get_center()
	var radius_x: float = room.size.x * 0.5 - _m
	var radius_y: float = minf(room.size.y * 0.5 - _drop.y, radius_x * 1.2)
	_starburst(center, Vector2(radius_x, radius_y))
	_sticker("Solved!", Palettes.ROLE_DISPLAY, _c.accent_2, _c.text_on_accent_2, center, SOLVED_TILT, true)
	var level_y: float = center.y + _kit.cap_height(Palettes.ROLE_DISPLAY) * 0.5 + _sp * 4.5
	_sticker(result.level_name, Palettes.ROLE_BUTTON, _c.tag_bg, _c.tag_text, Vector2(center.x, level_y), -SOLVED_TILT * 0.6, true)
	_kit.panel(self, receipt, _c.surface, _s.card_radius, true, true)
	var rows: Array[Array] = [
		["Time", SampleState.format_time(result.elapsed_seconds)],
		["Points after hints", SampleState.format_number(result.points_after_hints)],
		["Time bonus", SampleState.format_number(result.time_bonus)],
	]
	var inner_x: float = _m + pad
	var inner_w: float = _cw - 2.0 * pad
	var y: float = receipt.position.y + pad
	for row: Array in rows:
		var base: float = y + row_h * 0.5 + _kit.cap_height(Palettes.ROLE_HUD_VALUE) * 0.5
		_kit.text_at_baseline(self, row[0], Palettes.ROLE_LABEL, _c.text_muted, inner_x, base, inner_w * 0.6)
		_kit.text_at_baseline(self, row[1], Palettes.ROLE_HUD_VALUE, _c.text, inner_x, base, inner_w, HORIZONTAL_ALIGNMENT_RIGHT)
		y += row_h
	# A chunky rule, then the big score.
	_kit.panel(self, Rect2(inner_x, y + _sp * 0.5 - _s.outline_w * 0.5, inner_w, _s.outline_w), _c.outline, 0.0)
	y += _sp
	var score_base: float = y + score_h * 0.5 + _kit.cap_height(Palettes.ROLE_DISPLAY) * 0.5
	_kit.text_at_baseline(self, "Score", Palettes.ROLE_TITLE, _c.text, inner_x, score_base, inner_w * 0.5)
	_kit.text_at_baseline(self, SampleState.format_number(result.score), Palettes.ROLE_DISPLAY, _c.text_accent, inner_x, score_base, inner_w, HORIZONTAL_ALIGNMENT_RIGHT)
	y += score_h
	var hints_base: float = y + row_h * 0.5 + _kit.cap_height(Palettes.ROLE_HUD_VALUE) * 0.5
	_kit.text_at_baseline(self, "Hints used", Palettes.ROLE_LABEL, _c.text_muted, inner_x, hints_base, inner_w * 0.6)
	_kit.text_at_baseline(self, str(result.hints_used), Palettes.ROLE_HUD_VALUE, _c.text, inner_x, hints_base, inner_w, HORIZONTAL_ALIGNMENT_RIGHT)
	_chunky_button(again, _c.button_primary_bg, _c.button_primary_text, "", result.buttons[0])
	_chunky_button(menu, _c.button_bg, _c.button_text, "", result.buttons[1])


# Shared parts

func _face_side() -> float:
	return Kit.MIN_TOUCH - _drop.y - _sp * 0.5


## The scoreboard: TIME (white), SCORE (pink) and the Hint button (blue),
## each an outlined block with a hard shadow. Returns its height.
func _strip(y: float, hud: SampleState.Hud) -> float:
	var pad: float = _sp
	var label_cap: float = _kit.cap_height(Palettes.ROLE_LABEL)
	var display_cap: float = _kit.cap_height(Palettes.ROLE_DISPLAY)
	var height: float = pad + label_cap + _sp * 0.75 + display_cap + pad
	var label_base: float = y + pad + label_cap
	var value_base: float = y + height - pad
	var time_text: String = SampleState.format_time(hud.elapsed_seconds)
	var score_text: String = SampleState.format_number(hud.score)
	var time_w: float = maxf(_kit.text_width(time_text, Palettes.ROLE_DISPLAY), _kit.text_width("Time", Palettes.ROLE_LABEL)) + pad * 2.0
	var score_w: float = maxf(_kit.text_width(score_text, Palettes.ROLE_HUD_VALUE), _kit.text_width("Score", Palettes.ROLE_LABEL)) + pad * 3.0
	var gap: float = _sp
	var time: Rect2 = Rect2(_m, y, time_w, height)
	var score: Rect2 = Rect2(time.end.x + gap, y, score_w, height)
	var hint: Rect2 = Rect2(score.end.x + gap, y, _m + _cw - score.end.x - gap, height)
	_kit.panel(self, time, _c.hud_bg, _s.chip_radius, true, true)
	_kit.text_at_baseline(self, "Time", Palettes.ROLE_LABEL, _c.hud_label, time.position.x + pad, label_base, time.size.x - 2.0 * pad)
	_kit.text_at_baseline(self, time_text, Palettes.ROLE_DISPLAY, _c.hud_text, time.position.x + pad, value_base, time.size.x - 2.0 * pad)
	_kit.panel(self, score, _c.hud_accent_bg, _s.chip_radius, true, true)
	_kit.text_at_baseline(self, "Score", Palettes.ROLE_LABEL, _c.hud_accent_text, score.position.x + pad, label_base, score.size.x - 2.0 * pad)
	_kit.text_at_baseline(self, score_text, Palettes.ROLE_HUD_VALUE, _c.hud_accent_text, score.position.x + pad, value_base, score.size.x - 2.0 * pad)
	# The Hint button: a big bulb, then HINT over its cost, centered.
	_kit.panel(self, hint, _c.button_primary_bg, _s.button_radius, true, true)
	var cost: String = str(hud.hint_cost)
	var value_cap: float = _kit.cap_height(Palettes.ROLE_HUD_VALUE)
	var icon: float = (label_cap + _sp * 0.6 + value_cap) * 1.15
	var text_w: float = maxf(_kit.text_width("Hint", Palettes.ROLE_LABEL), _kit.text_width(cost, Palettes.ROLE_HUD_VALUE))
	var group_x: float = hint.get_center().x - (icon + _sp * 0.5 + text_w) * 0.5
	var group_top: float = hint.get_center().y - (label_cap + _sp * 0.6 + value_cap) * 0.5
	_kit.icon(self, Icons.HINT, Rect2(group_x, hint.get_center().y - icon * 0.5, icon, icon), _c.button_primary_text)
	var text_x: float = group_x + icon + _sp * 0.5
	_kit.text_at_baseline(self, "Hint", Palettes.ROLE_LABEL, _c.button_primary_text, text_x, group_top + label_cap, text_w + 1.0)
	_kit.text_at_baseline(self, cost, Palettes.ROLE_HUD_VALUE, _c.button_primary_text, text_x, group_top + label_cap + _sp * 0.6 + value_cap, text_w + 1.0)
	_kit.tap(self, Rect2(hint.position, hint.size + _drop), "Hint")
	return height


## Top of the tabs, for keys of the given height.
func _controls_top(key_h: float) -> float:
	return _pad_top(key_h) - _sp - Kit.MIN_TOUCH


func _pad_top(key_h: float) -> float:
	return _bottom - _sp - _drop.y - key_h * 2.0 - _sp


func _controls(key_h: float) -> void:
	var tabs_y: float = _controls_top(key_h)
	_tabs(Rect2(_m, tabs_y, _cw, Kit.MIN_TOUCH))
	_pad(Rect2(_m, _pad_top(key_h), _cw, key_h * 2.0 + _sp), key_h)


## PLACE and CROSS OUT as two chunky tabs. The active one is pressed down
## into its shadow: moved by the shadow offset, with no shadow of its own.
func _tabs(rect: Rect2) -> void:
	var gap: float = _sp
	var tab_w: float = (rect.size.x - gap) * 0.5
	var face_h: float = rect.size.y - _drop.y
	var names: Array[String] = ["Place", "Cross out"]
	var kinds: Array[String] = [Icons.PLACE, Icons.CROSS_OUT]
	var modes: Array[int] = [SampleState.MODE_PLACE, SampleState.MODE_CROSS_OUT]
	for i: int in 2:
		var touch: Rect2 = Rect2(rect.position.x + float(i) * (tab_w + gap), rect.position.y, tab_w + _drop.x, rect.size.y)
		var active: bool = modes[i] == pad_mode
		var face: Rect2 = Rect2(touch.position, Vector2(tab_w, face_h))
		if active:
			face.position += _drop
			_kit.panel(self, face, _c.mode_toggle_active_bg, _s.button_radius, true)
		else:
			_kit.panel(self, face, _c.mode_toggle_bg, _s.button_radius, true, true)
		var color: Color = _c.mode_toggle_active_text if active else _c.mode_toggle_text
		_kit.icon_text(self, kinds[i], names[i], Palettes.ROLE_BUTTON, color, face, _icon_side(), _sp * 0.5)
		_kit.tap(self, touch, names[i])


## Two rows of six chunky keys: 1 2 3 4 5 UNDO, then 6 7 8 9 and ERASE
## across two slots. Cross Out: ink keys with white digits and a pink
## stripe across the top right corner. Place: white keys.
func _pad(rect: Rect2, key_h: float) -> void:
	var gap: float = _sp
	var key_w: float = (rect.size.x - gap * 5.0) / 6.0
	var cross: bool = pad_mode == SampleState.MODE_CROSS_OUT
	var stripe: Color = _c.pad_key_cross_mark
	for i: int in 9:
		var row: int = 0 if i < 5 else 1
		var col: int = i if i < 5 else i - 5
		var key: Rect2 = Rect2(rect.position.x + float(col) * (key_w + gap), rect.position.y + float(row) * (key_h + gap), key_w, key_h)
		var face: Block = _kit.panel(self, key, _c.pad_key_cross_bg if cross else _c.pad_key_place_bg, _s.key_radius, true, true)
		if cross:
			face.under = func(block: Control) -> void:
				var w: float = block.size.x
				var near: float = w * 0.2
				var far: float = w * 0.4
				block.draw_colored_polygon(PackedVector2Array([Vector2(w - far, 0.0), Vector2(w - near, 0.0), Vector2(w, near), Vector2(w, far)]), stripe)
		_kit.text(self, str(i + 1), Palettes.ROLE_PAD_DIGIT, _c.pad_key_cross_text if cross else _c.pad_key_place_text, key)
		_kit.tap(self, Rect2(key.position, key.size + _drop), "Key %d" % (i + 1))
	var undo: Rect2 = Rect2(rect.position.x + 5.0 * (key_w + gap), rect.position.y, key_w, key_h)
	_chunky_button(undo, _c.button_bg, _c.button_text, Icons.UNDO, "Undo", true)
	var erase: Rect2 = Rect2(rect.position.x + 4.0 * (key_w + gap), rect.position.y + key_h + gap, key_w * 2.0 + gap, key_h)
	_chunky_button(erase, _c.button_bg, _c.button_text, Icons.ERASE, "Erase", true)


## An outlined button with a hard shadow. face is the visible face; the touch
## area includes the shadow. With stacked, the icon sits above the label.
func _chunky_button(face: Rect2, bg: Color, fg: Color, kind: String, value: String, stacked: bool = false) -> void:
	var rect: Rect2 = face
	if face.size.y >= Kit.MIN_TOUCH and not stacked:
		rect = Rect2(face.position, face.size - _drop)
	_kit.panel(self, rect, bg, _s.button_radius, true, true)
	if kind.is_empty():
		_kit.text(self, value, Palettes.ROLE_BUTTON, fg, rect)
	elif stacked:
		var icon: float = _icon_side() * 1.2
		var label_h: float = _kit.line_height(Palettes.ROLE_BUTTON)
		var total: float = icon + label_h * 0.85
		var top: float = rect.get_center().y - total * 0.5
		_kit.icon(self, kind, Rect2(rect.get_center().x - icon * 0.5, top, icon, icon), fg)
		_kit.text(self, value, Palettes.ROLE_BUTTON, fg, Rect2(rect.position.x, top + icon - label_h * 0.1, rect.size.x, label_h))
	else:
		_kit.icon_text(self, kind, value, Palettes.ROLE_BUTTON, fg, rect, _icon_side(), _sp * 0.5)
	_kit.tap(self, Rect2(rect.position, rect.size + _drop), value)


## A square button with an icon, its face and shadow inside the touch area.
func _square_button(touch: Rect2, kind: String, what: String) -> void:
	var side: float = _face_side()
	var face: Rect2 = Rect2(touch.get_center() - Vector2(side, side) * 0.5 - _drop * 0.5, Vector2(side, side))
	_kit.panel(self, face, _c.button_bg, _s.button_radius, true, true)
	var icon: float = _icon_side() * 1.25
	_kit.icon(self, kind, Rect2(face.get_center() - Vector2(icon, icon) * 0.5, Vector2(icon, icon)), _c.button_text)
	_kit.tap(self, touch, what)


## A tilted sticker with an outline and a hard shadow. anchor is its left
## middle point, or its center when centered. Returns its width.
func _sticker(value: String, role: String, bg: Color, fg: Color, anchor: Vector2, tilt: float, centered: bool = false) -> float:
	var pad_x: float = _sp * 1.5 if role == Palettes.ROLE_DISPLAY else _sp
	var height: float = _kit.cap_height(role) + _sp * (3.0 if role == Palettes.ROLE_DISPLAY else 2.2)
	var width: float = _kit.text_width(value, role) + pad_x * 2.0
	var origin: Vector2 = anchor - Vector2(width * 0.5 if centered else 0.0, height * 0.5)
	var sticker: Block = _kit.panel(self, Rect2(origin, Vector2(width, height)), bg, _s.chip_radius, true, true)
	sticker.pivot_offset = sticker.size * 0.5
	sticker.rotation_degrees = tilt
	_kit.text(sticker, value, role, fg, Rect2(Vector2.ZERO, sticker.size))
	return width


## A white starburst with an ink outline and a hard shadow.
func _starburst(center: Vector2, radius: Vector2) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var spikes: int = 16
	for i: int in spikes * 2:
		var angle: float = -PI * 0.5 + PI * float(i) / float(spikes)
		var r: float = 1.0 if i % 2 == 0 else 0.8
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y) * r)
	var burst: Block = Block.new()
	burst.position = center
	burst.size = Vector2.ZERO
	var fill: Color = _c.surface
	var edge: Color = _c.outline
	var shadow: Color = _c.shadow
	var drop: Vector2 = _drop
	var weight: float = _s.outline_w
	burst.over = func(block: Control) -> void:
		var shifted: PackedVector2Array = Transform2D(0.0, drop) * points
		block.draw_colored_polygon(shifted, shadow)
		block.draw_colored_polygon(points, fill)
		var ring: PackedVector2Array = points.duplicate()
		ring.append(points[0])
		block.draw_polyline(ring, edge, weight, true)
	add_child(burst)


func _stat_values(level: SampleState.LevelStats) -> Array[String]:
	return [
		SampleState.format_number(level.started),
		SampleState.format_number(level.completed),
		SampleState.format_time(level.best_seconds),
		SampleState.format_time(level.average_seconds),
		SampleState.format_number(level.best_score),
	]


func _icon_side() -> float:
	return roundf(_kit.line_height(Palettes.ROLE_BUTTON) * 0.95)
