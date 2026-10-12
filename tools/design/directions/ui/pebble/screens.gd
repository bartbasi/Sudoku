extends Control
## Pebble, the four Phase 1 screens: play, lesson, stats and complete.
## Soft and friendly: floating pill chips with soft shadows, a 3 by 3 keypad of
## round keys on a periwinkle panel, a big two-option switch, round buttons,
## sentence case, text centered in chips and keys
## (docs/design/direction-pebble.md).
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

const DIRECTION: String = "pebble"

## Layout rules from the brief, not design tokens.
const KEY_MAX: float = 200.0 ## Keys grow up to this before the header does.
const MAX_GAP: float = 240.0 ## Largest empty band between the board and the controls.
## Icon line weight as a share of the icon side (no token yet): round ends.
const ICON_STROKE: float = 0.11

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
var _cw: float
var _top: float
var _bottom: float
var _chip_h: float ## Visible height of the pills in the top row.


func _ready() -> void:
	_kit = Kit.new(DIRECTION, dark, ring_layout, ICON_STROKE, true)
	_c = _kit.colors
	_s = _kit.shape
	_w = size.x
	_m = _s.screen_margin
	_sp = _s.space
	_cw = _w - 2.0 * _m
	_top = Device.SAFE_TOP
	_bottom = size.y - Device.SAFE_BOTTOM
	_chip_h = Kit.MIN_TOUCH - 2.0 * _m
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
	# Controls first, from the bottom up, so the leftover height is known.
	var controls_bottom: float = _bottom - _sp
	var key: float = Kit.MIN_TOUCH
	var row1: Rect2 = Rect2(0.0, _top + _sp * 0.5, _w, Kit.MIN_TOUCH)
	var row2_h: float = _kit.line_height(Palettes.ROLE_DISPLAY) + _sp
	var one_row_board_top: float = row1.end.y + _sp
	var gap: float = controls_bottom - _keypad_side(key) - (one_row_board_top + _s.board_size)
	if gap > MAX_GAP:
		key = minf(KEY_MAX, key + (gap - MAX_GAP) / 3.0)
	# Grow the header with a second row of chips (the big timer) if there is
	# still too much room.
	gap = controls_bottom - _keypad_side(key) - (one_row_board_top + _s.board_size)
	var two_rows: bool = gap > MAX_GAP
	var board_top: float = one_row_board_top
	if two_rows:
		board_top += row2_h + _sp * 0.5
	# Row 1: level chip on the left; Hint pill and round Pause on the right.
	var chip_y: float = row1.get_center().y - _chip_h * 0.5
	var level: Rect2 = Rect2(_m, chip_y, _kit.text_width(hud.level_name, Palettes.ROLE_BUTTON) + _sp * 3.0, _chip_h)
	_kit.panel(self, level, _c.tag_bg, _s.chip_radius, false, true)
	_kit.text(self, hud.level_name, Palettes.ROLE_BUTTON, _c.tag_text, level)
	var pause_x: float = _w - Kit.MIN_TOUCH
	_round_button(Rect2(pause_x, row1.position.y, Kit.MIN_TOUCH, Kit.MIN_TOUCH), Icons.PAUSE, "Pause")
	var hint_text: String = "Hint %d" % hud.hint_cost
	var hint_w: float = _icon_side() + _sp * 0.5 + _kit.text_width(hint_text, Palettes.ROLE_BUTTON) + _sp * 2.5
	var hint: Rect2 = Rect2(pause_x + _m - _sp * 0.5 - hint_w, chip_y, hint_w, _chip_h)
	_kit.panel(self, hint, _c.button_primary_bg, _s.button_radius, false, true)
	_kit.icon_text(self, Icons.HINT, hint_text, Palettes.ROLE_BUTTON, _c.button_primary_text, hint, _icon_side(), _sp * 0.5)
	_kit.tap(self, Rect2(hint.position.x, row1.position.y, hint.size.x, Kit.MIN_TOUCH), "Hint")
	var time_text: String = SampleState.format_time(hud.elapsed_seconds)
	var score_text: String = SampleState.format_number(hud.score)
	if two_rows:
		# Row 2: the timer in display type with a clock, the score with a star.
		var row2: Rect2 = Rect2(_m, row1.end.y + _sp * 0.25, _cw, row2_h)
		var timer: Rect2 = Rect2(row2.position, Vector2(_cw * 0.62, row2_h))
		_kit.panel(self, timer, _c.hud_bg, _s.chip_radius, false, true)
		_kit.icon_text(self, Icons.CLOCK, time_text, Palettes.ROLE_DISPLAY, _c.hud_text, timer, _icon_side() * 1.4, _sp * 0.75)
		var score: Rect2 = Rect2(timer.end.x + _sp * 0.5, row2.position.y, row2.end.x - timer.end.x - _sp * 0.5, row2_h)
		_kit.panel(self, score, _c.hud_bg, _s.chip_radius, false, true)
		_score_content(score, score_text)
	else:
		_kit.problems.append("the play header fits one row; the timer and score chips are not built for that")
	var board: SampleState.BoardState = SampleState.play_board()
	board.mode = pad_mode
	_kit.board(self, Rect2(_m, board_top, _s.board_size, _s.board_size), board)
	_controls(controls_bottom, key)
	gap = controls_bottom - _keypad_side(key) - (board_top + _s.board_size)
	if gap > MAX_GAP + 1.0:
		_kit.problems.append("empty band of %.0f between the board and the controls" % gap)


func _build_lesson() -> void:
	var step: SampleState.LessonStep = SampleState.lesson_step()
	var row1: Rect2 = Rect2(0.0, _top + _sp * 0.5, _w, Kit.MIN_TOUCH)
	_round_button(Rect2(0.0, row1.position.y, Kit.MIN_TOUCH, Kit.MIN_TOUCH), Icons.BACK, "Back")
	var chip_text: String = "Lesson %d · %s" % [step.lesson_number, step.lesson_title]
	var chip_x: float = Kit.MIN_TOUCH - _m + _sp * 0.5
	var chip: Rect2 = Rect2(chip_x, row1.get_center().y - _chip_h * 0.5, _kit.text_width(chip_text, Palettes.ROLE_BUTTON) + _sp * 3.0, _chip_h)
	_kit.panel(self, chip, _c.tag_bg, _s.chip_radius, false, true)
	_kit.text(self, chip_text, Palettes.ROLE_BUTTON, _c.tag_text, chip)
	# Eight step dots, the current one filled, and the step in words.
	var dot: float = _sp * 0.8
	var dot_gap: float = _sp * 0.6
	var dots_y: float = row1.end.y + _sp * 0.5
	var row_h: float = _kit.line_height(Palettes.ROLE_LABEL)
	for i: int in step.step_count:
		var x: float = _m + _sp * 0.5 + float(i) * (dot + dot_gap)
		var rect: Rect2 = Rect2(x, dots_y + (row_h - dot) * 0.5, dot, dot)
		var current: bool = i + 1 == step.step_number
		var pebble: Block = _kit.panel(self, rect, _c.text_accent, 999.0)
		if not current:
			pebble.fill = null
			var ring: Color = _c.text_accent
			var weight: float = _s.x_stroke_w * 0.75
			pebble.over = func(block: Control) -> void:
				block.draw_arc(block.size * 0.5, (block.size.x - weight) * 0.5, 0.0, TAU, 32, ring, weight, true)
	var label_x: float = _m + _sp * 0.5 + float(step.step_count) * (dot + dot_gap) + _sp * 0.5
	_kit.text(self, "Step %d of %d" % [step.step_number, step.step_count], Palettes.ROLE_LABEL, _c.text_muted, Rect2(label_x, dots_y, _w - _m - label_x, row_h), HORIZONTAL_ALIGNMENT_LEFT)
	var board_top: float = dots_y + row_h + _sp * 0.75
	var board: SampleState.BoardState = step.board
	board.mode = pad_mode
	_kit.board(self, Rect2(_m, board_top, _s.board_size, _s.board_size), board)
	# The step text in a speech bubble pointing up at the board's middle
	# column, where the two marked cells are.
	var pointer: float = _sp
	var bubble_top: float = board_top + _s.board_size + _sp * 0.5 + pointer
	var pad: float = _sp * 1.25
	var line_gap: float = _sp * 0.25
	var text_h: float = _kit.paragraph_height(step.text, Palettes.ROLE_BODY, _cw - 2.0 * pad, line_gap)
	var bubble: Rect2 = Rect2(_m, bubble_top, _cw, text_h + 2.0 * pad)
	var face: Block = _kit.panel(self, bubble, _c.surface, _s.card_radius, false, true)
	var tip_color: Color = _c.surface
	face.over = func(block: Control) -> void:
		var x: float = block.size.x * 0.5
		block.draw_colored_polygon(PackedVector2Array([Vector2(x - pointer, 1.0), Vector2(x, -pointer), Vector2(x + pointer, 1.0)]), tip_color)
	_kit.paragraph(self, step.text, Palettes.ROLE_BODY, _c.text, _m + pad, bubble_top + pad, _cw - 2.0 * pad, line_gap, HORIZONTAL_ALIGNMENT_CENTER)
	# A smaller keypad and the switch, anchored to the bottom.
	var key: float = Kit.MIN_TOUCH
	var controls_bottom: float = _bottom - _sp
	var needed: float = maxf(_keypad_side(key), _column_min_h())
	if controls_bottom - needed < bubble.end.y + _sp:
		_kit.problems.append("lesson controls overlap the bubble")
	_controls(controls_bottom, key)


func _build_stats() -> void:
	var stats: SampleState.SampleStats = SampleState.stats()
	var row1: Rect2 = Rect2(0.0, _top + _sp * 0.5, _w, Kit.MIN_TOUCH)
	_round_button(Rect2(0.0, row1.position.y, Kit.MIN_TOUCH, Kit.MIN_TOUCH), Icons.BACK, "Back")
	var title_x: float = Kit.MIN_TOUCH - _m + _sp * 0.5
	_kit.text(self, "Stats", Palettes.ROLE_TITLE, _c.text, Rect2(title_x, row1.position.y, _w - _m - title_x, row1.size.y), HORIZONTAL_ALIGNMENT_LEFT)
	# One rounded card per level with small chips: three on the first row,
	# two on the second, each row filling the card.
	var pad: float = _sp * 1.25
	var chip_h: float = _kit.line_height(Palettes.ROLE_BUTTON) + _sp
	var chip_gap: float = _sp * 0.5
	var name_h: float = _kit.line_height(Palettes.ROLE_HUD_VALUE)
	var card_gap: float = _sp
	var inner: float = _cw - 2.0 * pad
	var y: float = row1.end.y + _sp * 0.5
	for level: SampleState.LevelStats in stats.levels:
		var rows: Array[Array] = [
			[
				["Started", SampleState.format_number(level.started)],
				["Done", SampleState.format_number(level.completed)],
				["Best", SampleState.format_time(level.best_seconds)],
			],
			[
				["Average", SampleState.format_time(level.average_seconds)],
				["Best score", SampleState.format_number(level.best_score)],
			],
		]
		var card_h: float = pad + name_h + _sp * 0.5 + float(rows.size()) * chip_h + float(rows.size() - 1) * chip_gap + pad
		var card: Rect2 = Rect2(_m, y, _cw, card_h)
		_kit.panel(self, card, _c.surface, _s.card_radius, false, true)
		_kit.text(self, level.level_name, Palettes.ROLE_HUD_VALUE, _c.text, Rect2(_m + pad, y + pad, inner, name_h), HORIZONTAL_ALIGNMENT_LEFT)
		var chip_y: float = y + pad + name_h + _sp * 0.5
		for row: Array in rows:
			var count: float = float(row.size())
			var width: float = (inner - chip_gap * (count - 1.0)) / count
			var x: float = _m + pad
			for item: Array in row:
				_stat_chip(Rect2(x, chip_y, width, chip_h), item[0], item[1])
				x += width + chip_gap
			chip_y += chip_h + chip_gap
		y += card_h + card_gap
	# The lessons card: five pebbles, four filled.
	var pebble: float = _sp * 2.5
	var card_h2: float = pad + name_h + _sp * 0.5 + pebble + pad
	var lessons: Rect2 = Rect2(_m, y, _cw, card_h2)
	_kit.panel(self, lessons, _c.surface, _s.card_radius, false, true)
	_kit.text(self, "Lessons completed", Palettes.ROLE_HUD_VALUE, _c.text, Rect2(_m + pad, y + pad, _cw - 2.0 * pad, name_h), HORIZONTAL_ALIGNMENT_LEFT)
	var count: String = "%d of %d" % [stats.lessons_completed, stats.lessons_total]
	_kit.text(self, count, Palettes.ROLE_HUD_VALUE, _c.text_accent, Rect2(_m + pad, y + pad, _cw - 2.0 * pad, name_h), HORIZONTAL_ALIGNMENT_RIGHT)
	var pebble_y: float = y + pad + name_h + _sp * 0.5
	for i: int in stats.lessons_total:
		var rect: Rect2 = Rect2(_m + pad + float(i) * (pebble + _sp), pebble_y, pebble, pebble)
		var dot: Block = _kit.panel(self, rect, _c.chart_bar, 999.0)
		if i >= stats.lessons_completed:
			dot.fill = null
			var ring: Color = _c.chart_bar
			var weight: float = _s.x_stroke_w * 1.5
			dot.over = func(block: Control) -> void:
				block.draw_arc(block.size * 0.5, (block.size.x - weight) * 0.5, 0.0, TAU, 48, ring, weight, true)
	if lessons.end.y > _bottom:
		_kit.problems.append("stats run %.0f past the safe area" % (lessons.end.y - _bottom))


func _build_complete() -> void:
	var result: SampleState.Completion = SampleState.completion()
	# Pills anchored to the bottom.
	var pill_w: float = (_cw - _sp * 0.5) * 0.5
	var pills_y: float = _bottom - _sp - Kit.MIN_TOUCH
	var again: Rect2 = Rect2(_m, pills_y, pill_w, Kit.MIN_TOUCH)
	var menu: Rect2 = Rect2(_m + pill_w + _sp * 0.5, pills_y, pill_w, Kit.MIN_TOUCH)
	# The card: rows, the score, the hints chip. It sits above the pills.
	var pad: float = _sp * 1.5
	var row_h: float = _kit.line_height(Palettes.ROLE_HUD_VALUE) + _sp
	var score_h: float = _kit.line_height(Palettes.ROLE_DISPLAY) + _sp * 0.5
	var chip_h: float = _kit.line_height(Palettes.ROLE_BUTTON) + _sp
	var headline_h: float = _kit.line_height(Palettes.ROLE_DISPLAY)
	var card_h: float = pad + row_h * 3.0 + _sp * 0.5 + score_h + _sp * 0.75 + chip_h + pad
	var card: Rect2 = Rect2(_m, pills_y - _sp * 2.0 - card_h, _cw, card_h)
	# "Puzzle solved!" and the level chip in the middle of the room above,
	# with a burst of round confetti dots around them.
	var block_h: float = headline_h + _sp * 0.5 + chip_h
	var block_y: float = _top + (card.position.y - _top - block_h) * 0.5
	var headline: String = "Puzzle solved!"
	var headline_w: float = _kit.text_width(headline, Palettes.ROLE_DISPLAY)
	_confetti(Rect2(_w * 0.5 - headline_w * 0.5, block_y, headline_w, block_h), Rect2(0.0, _top, _w, card.position.y - _top - _sp))
	_kit.text(self, headline, Palettes.ROLE_DISPLAY, _c.text, Rect2(_m, block_y, _cw, headline_h))
	var level_w: float = _kit.text_width(result.level_name, Palettes.ROLE_BUTTON) + _sp * 3.0
	var level: Rect2 = Rect2(_w * 0.5 - level_w * 0.5, block_y + headline_h + _sp * 0.5, level_w, chip_h)
	_kit.panel(self, level, _c.tag_bg, _s.chip_radius, false, true)
	_kit.text(self, result.level_name, Palettes.ROLE_BUTTON, _c.tag_text, level)
	_kit.panel(self, card, _c.surface, _s.card_radius, false, true)
	var inner_x: float = _m + pad
	var inner_w: float = _cw - 2.0 * pad
	var y: float = card.position.y + pad
	var rows: Array[Array] = [
		["Time", SampleState.format_time(result.elapsed_seconds)],
		["Points after hints", SampleState.format_number(result.points_after_hints)],
		["Time bonus", SampleState.format_number(result.time_bonus)],
	]
	for row: Array in rows:
		var rect: Rect2 = Rect2(inner_x, y, inner_w, row_h)
		_kit.text(self, row[0], Palettes.ROLE_BODY, _c.text_muted, rect, HORIZONTAL_ALIGNMENT_LEFT)
		_kit.text(self, row[1], Palettes.ROLE_HUD_VALUE, _c.text, rect, HORIZONTAL_ALIGNMENT_RIGHT)
		y += row_h
	y += _sp * 0.5
	var score: Rect2 = Rect2(inner_x, y, inner_w, score_h)
	_kit.panel(self, Rect2(inner_x - _sp * 0.5, y, inner_w + _sp, score_h), _c.surface_alt, _s.card_radius * 0.75)
	_kit.text(self, "Score", Palettes.ROLE_TITLE, _c.text, score.grow_individual(-_sp * 0.5, 0.0, 0.0, 0.0), HORIZONTAL_ALIGNMENT_LEFT)
	_kit.text(self, SampleState.format_number(result.score), Palettes.ROLE_DISPLAY, _c.text_accent, score.grow_individual(0.0, 0.0, -_sp * 0.5, 0.0), HORIZONTAL_ALIGNMENT_RIGHT)
	y += score_h + _sp * 0.75
	var hints_text: String = "%d hints used" % result.hints_used
	var hints_w: float = _kit.text_width(hints_text, Palettes.ROLE_BUTTON) + _sp * 3.0
	var hints: Rect2 = Rect2(_w * 0.5 - hints_w * 0.5, y, hints_w, chip_h)
	_kit.panel(self, hints, _c.surface_alt, _s.chip_radius)
	_kit.text(self, hints_text, Palettes.ROLE_BUTTON, _c.text, hints)
	# Play again (tangerine) and Menu.
	_kit.panel(self, again, _c.button_primary_bg, _s.button_radius, false, true)
	_kit.text(self, result.buttons[0], Palettes.ROLE_BUTTON, _c.button_primary_text, again)
	_kit.tap(self, again, result.buttons[0])
	_kit.panel(self, menu, _c.button_bg, _s.button_radius, false, true)
	_kit.text(self, result.buttons[1], Palettes.ROLE_BUTTON, _c.button_text, menu)
	_kit.tap(self, menu, result.buttons[1])


# Shared parts

## Side of the keypad panel for keys of the given diameter.
func _keypad_side(key: float) -> float:
	return key * 3.0 + _key_gap() * 2.0 + _panel_pad() * 2.0


func _key_gap() -> float:
	return _sp * 0.5


func _panel_pad() -> float:
	return _sp * 0.75


## Height the right column needs: the switch, then Undo and Erase with
## their labels.
func _column_min_h() -> float:
	return _switch_h() + _sp + Kit.MIN_TOUCH + _kit.line_height(Palettes.ROLE_LABEL)


func _switch_h() -> float:
	return Kit.MIN_TOUCH * 2.0 + _switch_pad() * 2.0


func _switch_pad() -> float:
	return _sp * 0.25


## The keypad on the left, the switch and the round Undo and Erase on the
## right, all bottom aligned at bottom.
func _controls(bottom: float, key: float) -> void:
	var side: float = _keypad_side(key)
	var height: float = maxf(side, _column_min_h())
	var top: float = bottom - height
	var panel: Rect2 = Rect2(_m, bottom - side, side, side)
	_keypad(panel, key)
	var col: Rect2 = Rect2(panel.end.x + _sp, top, _w - _m - panel.end.x - _sp, height)
	_switch(Rect2(col.position, Vector2(col.size.x, _switch_h())))
	var label_h: float = _kit.line_height(Palettes.ROLE_LABEL)
	var edit_y: float = col.end.y - label_h - Kit.MIN_TOUCH
	var spread: float = (col.size.x - 2.0 * Kit.MIN_TOUCH) / 3.0
	_round_edit(Rect2(col.position.x + spread, edit_y, Kit.MIN_TOUCH, Kit.MIN_TOUCH), Icons.UNDO, "Undo")
	_round_edit(Rect2(col.position.x + spread * 2.0 + Kit.MIN_TOUCH, edit_y, Kit.MIN_TOUCH, Kit.MIN_TOUCH), Icons.ERASE, "Erase")


## The 3 by 3 keypad of round keys on a periwinkle panel. Cross Out: sunny
## yellow keys, each with a raspberry badge holding an X. Place: white keys.
func _keypad(panel: Rect2, key: float) -> void:
	_kit.panel(self, panel, _c.pad_bg, _s.card_radius, false, true)
	var cross: bool = pad_mode == SampleState.MODE_CROSS_OUT
	var badge_bg: Color = _c.pad_key_cross_mark
	var badge_x: Color = _c.pad_key_cross_bg
	var stroke: float = _s.x_stroke_w
	for i: int in 9:
		var x: float = panel.position.x + _panel_pad() + float(i % 3) * (key + _key_gap())
		var y: float = panel.position.y + _panel_pad() + float(i / 3) * (key + _key_gap())
		var rect: Rect2 = Rect2(x, y, key, key)
		var face: Block = _kit.panel(self, rect, _c.pad_key_cross_bg if cross else _c.pad_key_place_bg, _s.key_radius)
		if cross:
			face.over = func(block: Control) -> void:
				var k: float = block.size.x
				var center: Vector2 = Vector2(k * 0.84, k * 0.16)
				block.draw_circle(center, k * 0.14, badge_bg, true, -1.0, true)
				var arm: float = k * 0.055
				for slope: float in [-1.0, 1.0]:
					var a: Vector2 = center + Vector2(-arm, -arm * slope)
					var b: Vector2 = center + Vector2(arm, arm * slope)
					block.draw_line(a, b, badge_x, stroke, true)
					block.draw_circle(a, stroke * 0.5, badge_x, true, -1.0, true)
					block.draw_circle(b, stroke * 0.5, badge_x, true, -1.0, true)
		_kit.text(self, str(i + 1), Palettes.ROLE_PAD_DIGIT, _c.pad_key_cross_text if cross else _c.pad_key_place_text, rect)
		_kit.tap(self, rect, "Key %d" % (i + 1))


## The big two-option switch: Place above, Cross out below, the active one
## on a dark thumb.
func _switch(rect: Rect2) -> void:
	var pad: float = _switch_pad()
	# The track's corners follow the pill-shaped thumb inside it.
	var track_radius: float = minf(_s.button_radius, Kit.MIN_TOUCH * 0.5 + pad)
	_kit.panel(self, rect, _c.mode_toggle_bg, track_radius)
	var names: Array[String] = ["Place", "Cross out"]
	var kinds: Array[String] = [Icons.PLACE, Icons.CROSS_OUT]
	var modes: Array[int] = [SampleState.MODE_PLACE, SampleState.MODE_CROSS_OUT]
	for i: int in 2:
		var option: Rect2 = Rect2(rect.position.x + pad, rect.position.y + pad + float(i) * Kit.MIN_TOUCH, rect.size.x - 2.0 * pad, Kit.MIN_TOUCH)
		var active: bool = modes[i] == pad_mode
		if active:
			_kit.panel(self, option, _c.mode_toggle_active_bg, _s.button_radius, false, true)
		var color: Color = _c.mode_toggle_active_text if active else _c.mode_toggle_text
		_kit.icon_text(self, kinds[i], names[i], Palettes.ROLE_BUTTON, color, option, _icon_side(), _sp * 0.4)
		_kit.tap(self, option, names[i])


## A round Undo or Erase button with its name under it.
func _round_edit(touch: Rect2, kind: String, value: String) -> void:
	var side: float = touch.size.x - _m
	var face: Rect2 = Rect2(touch.get_center() - Vector2(side, side) * 0.5, Vector2(side, side))
	_kit.panel(self, face, _c.button_bg, _s.button_radius, false, true)
	var icon: float = _icon_side() * 1.2
	_kit.icon(self, kind, Rect2(face.get_center() - Vector2(icon, icon) * 0.5, Vector2(icon, icon)), _c.button_text)
	_kit.tap(self, touch, value)
	_kit.text(self, value, Palettes.ROLE_LABEL, _c.text, Rect2(touch.position.x - _sp, touch.end.y, touch.size.x + 2.0 * _sp, _kit.line_height(Palettes.ROLE_LABEL)))


## A round white button (Pause, Back) inside a 144 touch area.
func _round_button(touch: Rect2, kind: String, what: String) -> void:
	var side: float = _chip_h
	var face: Rect2 = Rect2(touch.get_center() - Vector2(side, side) * 0.5, Vector2(side, side))
	_kit.panel(self, face, _c.button_bg, _s.button_radius, false, true)
	var icon: float = _icon_side() * 1.1
	_kit.icon(self, kind, Rect2(face.get_center() - Vector2(icon, icon) * 0.5, Vector2(icon, icon)), _c.button_text)
	_kit.tap(self, touch, what)


## The score chip: a star, then "Score" over the number.
func _score_content(chip: Rect2, value: String) -> void:
	var icon: float = _icon_side() * 1.25
	var label_h: float = _kit.line_height(Palettes.ROLE_LABEL)
	var value_h: float = _kit.line_height(Palettes.ROLE_HUD_VALUE)
	var text_w: float = maxf(_kit.text_width("Score", Palettes.ROLE_LABEL), _kit.text_width(value, Palettes.ROLE_HUD_VALUE))
	var total: float = icon + _sp * 0.6 + text_w
	var x: float = chip.get_center().x - total * 0.5
	_kit.icon(self, Icons.STAR, Rect2(x, chip.get_center().y - icon * 0.5, icon, icon), _c.hud_text)
	var text_x: float = x + icon + _sp * 0.6
	var top: float = chip.get_center().y - (label_h + value_h) * 0.5 + _sp * 0.15
	_kit.text(self, "Score", Palettes.ROLE_LABEL, _c.hud_label, Rect2(text_x, top, text_w + 1.0, label_h), HORIZONTAL_ALIGNMENT_LEFT)
	_kit.text(self, value, Palettes.ROLE_HUD_VALUE, _c.hud_text, Rect2(text_x, top + label_h - _sp * 0.3, text_w + 1.0, value_h), HORIZONTAL_ALIGNMENT_LEFT)


## A small stat chip: the name muted, the value bold, centered together.
func _stat_chip(rect: Rect2, label: String, value: String) -> void:
	_kit.panel(self, rect, _c.surface_alt, _s.chip_radius)
	var label_w: float = _kit.text_width(label, Palettes.ROLE_LABEL)
	var value_w: float = _kit.text_width(value, Palettes.ROLE_BUTTON)
	var space: float = _sp * 0.4
	var x: float = rect.get_center().x - (label_w + space + value_w) * 0.5
	if label_w + space + value_w > rect.size.x - _sp:
		_kit.problems.append("stat chip %s %s does not fit" % [label, value])
	_kit.text(self, label, Palettes.ROLE_LABEL, _c.text_muted, Rect2(x, rect.position.y, label_w + 1.0, rect.size.y), HORIZONTAL_ALIGNMENT_LEFT)
	_kit.text(self, value, Palettes.ROLE_BUTTON, _c.text, Rect2(x + label_w + space, rect.position.y, value_w + 1.0, rect.size.y), HORIZONTAL_ALIGNMENT_LEFT)


## A burst of round confetti dots in the three celebration colors: rings of
## dots radiating from the middle of keep_clear, never inside it, and never
## outside room.
func _confetti(keep_clear: Rect2, room: Rect2) -> void:
	var colors: Array[Color] = [_c.celebrate_1, _c.celebrate_2, _c.celebrate_3]
	var center: Vector2 = keep_clear.get_center()
	var clear: Rect2 = keep_clear.grow(_sp)
	var reach: Vector2 = Vector2(room.size.x * 0.5, minf(center.y - room.position.y, room.end.y - center.y))
	var rings: int = 4
	var index: int = 0
	for ring: int in rings:
		var share: float = 0.42 + 0.4 * float(ring) / float(rings - 1)
		var count: int = 10 + ring * 4
		for i: int in count:
			index += 1
			var angle: float = TAU * (float(i) + 0.5 * float(ring % 2)) / float(count) + 0.13 * float(index % 3)
			var jitter: float = 0.9 + 0.1 * float((index * 7) % 3)
			var spot: Vector2 = center + Vector2(cos(angle) * reach.x, sin(angle) * reach.y) * share * jitter
			var radius: float = _sp * (0.2 + 0.12 * float((index * 5) % 4)) * (1.3 - 0.3 * share)
			var dot: Rect2 = Rect2(spot - Vector2(radius, radius), Vector2(radius, radius) * 2.0)
			if dot.intersects(clear) or not room.grow(-_sp * 0.5).encloses(dot):
				continue
			_kit.panel(self, dot, colors[index % 3], 999.0)


func _icon_side() -> float:
	return roundf(_kit.line_height(Palettes.ROLE_BUTTON) * 0.95)
