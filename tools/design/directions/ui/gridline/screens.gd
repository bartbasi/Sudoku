extends Control
## Gridline, the four Phase 1 screens: play, lesson, stats and complete.
## A ruled sheet inside a Swiss poster: a full-bleed ultramarine header band,
## square corners, 3 unit ink outlines, no shadows, everything left aligned
## and set in rows like a timetable (docs/design/direction-gridline.md).
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

const DIRECTION: String = "gridline"

## Layout rules from the brief, not design tokens.
const KEY_MIN_H: float = 190.0 ## The single row of nine keys is at least this tall.
const KEY_MAX_H: float = 200.0
const MAX_GAP: float = 240.0 ## Largest empty band between the board and the controls.
## Icon line weight as a share of the icon side (no token yet): thin and
## square ended, like the rules.
const ICON_STROKE: float = 0.09

@export var screen: String = "play"
var dark: bool = false
var ring_layout: int = RingLayouts.DEFAULT_LAYOUT
var pad_mode: int = SampleState.MODE_CROSS_OUT

var _kit: Kit
var _c: Palettes.Palette
var _s: Palettes.Shape
var _w: float
var _m: float ## Screen margin.
var _sp: float ## Base spacing step.
var _cw: float ## Content width.
var _top: float ## Top of the safe area.
var _bottom: float ## Bottom of the safe area.


func _ready() -> void:
	_kit = Kit.new(DIRECTION, dark, ring_layout, ICON_STROKE, false)
	_c = _kit.colors
	_s = _kit.shape
	_w = size.x
	_m = _s.screen_margin
	_sp = _s.space
	_cw = _w - 2.0 * _m
	_top = Device.SAFE_TOP
	_bottom = size.y - Device.SAFE_BOTTOM
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
	var label_cap: float = _kit.cap_height(Palettes.ROLE_LABEL)
	var row1: Rect2 = Rect2(_m, _top + _sp, _cw, Kit.MIN_TOUCH)
	var labels_base: float = row1.end.y + _sp + label_cap
	var value_base: float = labels_base + _sp * 0.75 + _kit.cap_height(Palettes.ROLE_DISPLAY)
	var band_min: float = value_base + _sp * 1.5
	var layout: Dictionary = _fit_controls(band_min, band_min + _sp + _s.board_size)
	var extra: float = layout["band_extra"]
	var band: float = band_min + extra
	_kit.panel(self, Rect2(0.0, 0.0, _w, band), _c.hud_bg, 0.0)
	# Row 1: level tag, then Hint and Pause on the right.
	row1.position.y += extra * 0.25
	_level_tag(hud.level_name, row1)
	var pause: Rect2 = Rect2(row1.end.x - Kit.MIN_TOUCH, row1.position.y, Kit.MIN_TOUCH, Kit.MIN_TOUCH)
	_band_button(pause, Icons.PAUSE, "Pause")
	_hint_button(Rect2(0.0, row1.position.y, 0.0, Kit.MIN_TOUCH), pause.position.x - _sp * 0.5, hud.hint_cost)
	# Row 2: the timer in huge numerals, the score in the next column.
	labels_base += extra * 0.75
	value_base += extra * 0.75
	var column: float = _m + _cw * 0.58
	_kit.text_at_baseline(self, "Time", Palettes.ROLE_LABEL, _c.hud_label, _m, labels_base, column - _m)
	_kit.text_at_baseline(self, SampleState.format_time(hud.elapsed_seconds), Palettes.ROLE_DISPLAY, _c.hud_text, _m, value_base, column - _m)
	# The score's numerals start at the same height as the timer's.
	var score_base: float = labels_base + _sp * 0.75 + _kit.cap_height(Palettes.ROLE_HUD_VALUE)
	_kit.text_at_baseline(self, "Score", Palettes.ROLE_LABEL, _c.hud_label, column, labels_base, _w - _m - column)
	_kit.text_at_baseline(self, SampleState.format_number(hud.score), Palettes.ROLE_HUD_VALUE, _c.hud_text, column, score_base, _w - _m - column)
	# Board, then the controls anchored to the bottom.
	var board: SampleState.BoardState = SampleState.play_board()
	board.mode = pad_mode
	_kit.board(self, Rect2(_m, band + _sp, _s.board_size, _s.board_size), board)
	_controls(layout)


func _build_lesson() -> void:
	var step: SampleState.LessonStep = SampleState.lesson_step()
	var row1: Rect2 = Rect2(_m, _top + _sp, _cw, Kit.MIN_TOUCH)
	var title_base: float = row1.end.y + _sp * 0.5 + _kit.cap_height(Palettes.ROLE_TITLE)
	var band: float = title_base + _sp * 1.25
	_kit.panel(self, Rect2(0.0, 0.0, _w, band), _c.hud_bg, 0.0)
	var close: Rect2 = Rect2(row1.end.x - Kit.MIN_TOUCH, row1.position.y, Kit.MIN_TOUCH, Kit.MIN_TOUCH)
	_band_button(close, Icons.CLOSE, "Close lesson")
	var lesson: String = "Lesson %d of %d" % [step.lesson_number, step.lesson_count]
	_kit.text(self, lesson, Palettes.ROLE_LABEL, _c.hud_label, Rect2(_m, row1.position.y, close.position.x - _m - _sp, row1.size.y), HORIZONTAL_ALIGNMENT_LEFT)
	_kit.text_at_baseline(self, step.lesson_title, Palettes.ROLE_TITLE, _c.hud_text, _m, title_base, _cw)
	var step_base: float = band + _sp + _kit.cap_height(Palettes.ROLE_LABEL)
	_kit.text_at_baseline(self, "Step %d of %d" % [step.step_number, step.step_count], Palettes.ROLE_LABEL, _c.text_muted, _m, step_base, _cw)
	var board_top: float = step_base + _sp
	var board: SampleState.BoardState = step.board
	board.mode = pad_mode
	_kit.board(self, Rect2(_m, board_top, _s.board_size, _s.board_size), board)
	# The step text on white with a heavy ink rule on its left.
	var text_top: float = board_top + _s.board_size + _sp
	var rule: float = _s.line_outer_w
	var text_x: float = _m + rule + _sp
	var text_w: float = _w - _m - _sp - text_x
	var line_gap: float = _sp * 0.4
	var text_h: float = _kit.paragraph_height(step.text, Palettes.ROLE_BODY, text_w, line_gap)
	var block: Rect2 = Rect2(_m, text_top, _cw, text_h + _sp * 2.0)
	_kit.panel(self, block, _c.surface, 0.0)
	_kit.panel(self, Rect2(block.position, Vector2(rule, block.size.y)), _c.outline, 0.0)
	_kit.paragraph(self, step.text, Palettes.ROLE_BODY, _c.text, text_x, text_top + _sp, text_w, line_gap)
	_controls(_fit_controls(band, block.end.y))


func _build_stats() -> void:
	var stats: SampleState.Stats = SampleState.stats()
	var band: float = _title_band("Stats", Icons.BACK, "Back")
	# The ruled table: one row per level, every other row tinted.
	var headers: Array[String] = ["Level", "Started", "Done", "Best", "Average", "Best score"]
	var rows: Array[Array] = []
	for level: SampleState.LevelStats in stats.levels:
		rows.append([
			level.level_name,
			SampleState.format_number(level.started),
			SampleState.format_number(level.completed),
			SampleState.format_time(level.best_seconds),
			SampleState.format_time(level.average_seconds),
			SampleState.format_number(level.best_score),
		])
	var pad: float = _sp
	var inner: float = _cw - 2.0 * pad
	var widths: Array[float] = []
	var total: float = 0.0
	for col: int in headers.size():
		# A header of two words sits on two lines, so the column stays narrow.
		var width: float = 0.0
		for word: String in headers[col].split(" "):
			width = maxf(width, _kit.text_width(word, Palettes.ROLE_LABEL))
		for row: Array in rows:
			width = maxf(width, _kit.text_width(row[col], Palettes.ROLE_BODY))
		widths.append(width)
		total += width
	var col_gap: float = (inner - total) / float(headers.size() - 1)
	if col_gap < _sp * 0.5:
		_kit.problems.append("stats table is %.0f wide in %.0f" % [total, inner])
	var header_h: float = _sp * 5.0
	var row_h: float = _sp * 6.0
	var display_cap: float = _kit.cap_height(Palettes.ROLE_DISPLAY)
	var label_cap: float = _kit.cap_height(Palettes.ROLE_LABEL)
	var seg_h: float = _sp * 2.0
	var block_pad: float = pad
	var block_h: float = block_pad + label_cap + _sp + display_cap + _sp * 1.5 + seg_h + block_pad
	# Share the spare height out to the rows and the lessons block, so the
	# page is not half empty.
	var used: float = band + _sp + header_h + row_h * float(rows.size()) + _sp * 2.0 + block_h
	var spare: float = clampf((_bottom - _sp - used) / float(rows.size() + 2), 0.0, _sp * 2.0)
	row_h += spare
	block_pad += spare
	block_h += spare * 2.0
	var table: Rect2 = Rect2(_m, band + _sp, _cw, header_h + row_h * float(rows.size()))
	_kit.panel(self, table, _c.surface, 0.0)
	for r: int in rows.size():
		var y: float = table.position.y + header_h + row_h * float(r)
		if r % 2 == 1:
			_kit.panel(self, Rect2(_m, y, _cw, row_h), _c.surface_alt, 0.0)
	var x: float = _m + pad
	var header_line: float = _kit.line_height(Palettes.ROLE_LABEL) * 0.9
	var header_base: float = table.position.y + header_h - _sp * 1.25
	for col: int in headers.size():
		var words: PackedStringArray = headers[col].split(" ")
		for k: int in words.size():
			var base: float = header_base - header_line * float(words.size() - 1 - k)
			_kit.text_at_baseline(self, words[k], Palettes.ROLE_LABEL, _c.text_muted, x, base, widths[col] + 1.0)
		for r: int in rows.size():
			var y: float = table.position.y + header_h + row_h * float(r)
			var value: String = rows[r][col]
			_kit.text(self, value, Palettes.ROLE_BODY, _c.text, Rect2(x, y, widths[col] + 1.0, row_h), HORIZONTAL_ALIGNMENT_LEFT)
		x += widths[col] + col_gap
	_kit.panel(self, Rect2(_m, table.position.y + header_h - _s.outline_w * 0.5, _cw, _s.outline_w), _c.outline, 0.0)
	_outline(table)
	# Lessons: a big number and a five-segment bar, right under the table.
	var block: Rect2 = Rect2(_m, table.end.y + _sp * 2.0, _cw, block_h)
	_kit.panel(self, block, _c.surface, 0.0)
	_outline(block)
	var label_base: float = block.position.y + block_pad + label_cap
	_kit.text_at_baseline(self, "Lessons completed", Palettes.ROLE_LABEL, _c.text_muted, _m + pad, label_base, inner)
	var number_base: float = label_base + _sp + display_cap
	var count: String = str(stats.lessons_completed)
	var count_w: float = _kit.text_width(count, Palettes.ROLE_DISPLAY)
	_kit.text_at_baseline(self, count, Palettes.ROLE_DISPLAY, _c.text_accent, _m + pad, number_base, count_w + 1.0)
	var of_text: String = "of %d" % stats.lessons_total
	_kit.text_at_baseline(self, of_text, Palettes.ROLE_TITLE, _c.text, _m + pad + count_w + _sp * 0.75, number_base, _kit.text_width(of_text, Palettes.ROLE_TITLE) + 1.0)
	var seg_y: float = number_base + _sp * 1.5
	var seg_gap: float = _sp * 0.5
	var seg_w: float = (inner - seg_gap * float(stats.lessons_total - 1)) / float(stats.lessons_total)
	for i: int in stats.lessons_total:
		var seg: Rect2 = Rect2(_m + pad + float(i) * (seg_w + seg_gap), seg_y, seg_w, seg_h)
		if i < stats.lessons_completed:
			_kit.panel(self, seg, _c.chart_bar, 0.0)
		else:
			var empty: Block = _kit.panel(self, seg, Color(0.0, 0.0, 0.0, 0.0), 0.0, true, false, _c.chart_bar)
			empty.fill = null


func _build_complete() -> void:
	var result: SampleState.Completion = SampleState.completion()
	# Buttons first: stacked, anchored to the bottom.
	var again: Rect2 = Rect2(_m, _bottom - _sp - Kit.MIN_TOUCH * 2.0 - _sp * 0.5, _cw, Kit.MIN_TOUCH)
	var menu: Rect2 = Rect2(_m, again.end.y + _sp * 0.5, _cw, Kit.MIN_TOUCH)
	# Receipt rows: label, value, role.
	var rows: Array[Array] = [
		["Time", SampleState.format_time(result.elapsed_seconds), Palettes.ROLE_HUD_VALUE],
		["Points after hints", SampleState.format_number(result.points_after_hints), Palettes.ROLE_HUD_VALUE],
		["Time bonus", SampleState.format_number(result.time_bonus), Palettes.ROLE_HUD_VALUE],
		["Score", SampleState.format_number(result.score), Palettes.ROLE_DISPLAY],
		["Hints used", str(result.hints_used), Palettes.ROLE_HUD_VALUE],
	]
	var row_h: float = _sp * 4.5
	var score_h: float = _kit.cap_height(Palettes.ROLE_DISPLAY) + _sp * 2.5
	var rule_h: float = _sp
	var receipt_h: float = _sp + row_h * 4.0 + rule_h + score_h + _sp
	var chip: float = _sp
	# The band takes what is left above the color bar and the receipt.
	var tag_h: float = _kit.line_height(Palettes.ROLE_LABEL) + _sp * 0.75
	var display_cap: float = _kit.cap_height(Palettes.ROLE_DISPLAY)
	var band_min: float = _top + _sp + tag_h + _sp * 2.0 + display_cap + _sp * 2.0
	var free: float = again.position.y - _sp * 2.0 - receipt_h - chip - _sp - band_min - _sp
	var band: float = band_min + maxf(0.0, free * 0.75)
	_kit.panel(self, Rect2(0.0, 0.0, _w, band), _c.hud_bg, 0.0)
	_level_tag(result.level_name, Rect2(_m, _top + _sp, _cw, tag_h))
	_kit.text_at_baseline(self, "SOLVED", Palettes.ROLE_DISPLAY, _c.hud_text, _m, band - _sp * 2.0, _cw)
	# A printer's color bar under the band, the only decoration.
	var bar_y: float = band + _sp
	var swatches: Array[Color] = [_c.celebrate_1, _c.celebrate_2, _c.celebrate_3]
	for i: int in 12:
		_kit.panel(self, Rect2(_m + float(i) * chip, bar_y, chip, chip), swatches[i % 3], 0.0)
	# The receipt.
	var receipt: Rect2 = Rect2(_m, bar_y + chip + _sp, _cw, receipt_h)
	_kit.panel(self, receipt, _c.surface, 0.0)
	_outline(receipt)
	var x: float = _m + _sp
	var column: float = _m + _cw * 0.6
	var y: float = receipt.position.y + _sp
	for row: Array in rows:
		var role: String = row[2]
		var big: bool = role == Palettes.ROLE_DISPLAY
		if big:
			_kit.panel(self, Rect2(x, y + rule_h * 0.5 - _s.outline_w * 0.5, _cw - 2.0 * _sp, _s.outline_w), _c.outline, 0.0)
			y += rule_h
		var height: float = score_h if big else row_h
		var base: float = y + height * 0.5 + _kit.cap_height(role) * 0.5
		var color: Color = _c.text_accent if big else _c.text
		_kit.text_at_baseline(self, row[0], Palettes.ROLE_LABEL, _c.text_muted, x, base, column - x - _sp)
		_kit.text_at_baseline(self, row[1], role, color, column, base, _w - _m - _sp - column)
		y += height
	# Play again (vermilion) and Menu (outlined).
	_kit.panel(self, again, _c.button_primary_bg, 0.0)
	_kit.text(self, result.buttons[0], Palettes.ROLE_BUTTON, _c.button_primary_text, again)
	_kit.tap(self, again, result.buttons[0])
	_kit.panel(self, menu, _c.button_bg, 0.0, true)
	_kit.text(self, result.buttons[1], Palettes.ROLE_BUTTON, _c.button_text, menu)
	_kit.tap(self, menu, result.buttons[1])


# Shared parts

## Works out the controls: the bottom row (Undo, Erase), the row of nine keys
## and the mode bar, from the bottom up. Leftover height goes between content
## and controls, at most MAX_GAP; beyond that the keys grow, then the band.
func _fit_controls(band_min: float, content_bottom: float) -> Dictionary:
	var edit_top: float = _bottom - _sp - Kit.MIN_TOUCH
	var key_h: float = KEY_MIN_H
	var mode_top: float = edit_top - _sp - key_h - _sp - Kit.MIN_TOUCH
	var gap: float = mode_top - content_bottom
	if gap > MAX_GAP:
		var grow: float = minf(gap - MAX_GAP, KEY_MAX_H - KEY_MIN_H)
		key_h += grow
		gap -= grow
	var band_extra: float = maxf(0.0, gap - MAX_GAP)
	if gap < _sp:
		_kit.problems.append("controls overlap the content by %.0f" % (_sp - gap))
	return {"edit_top": edit_top, "key_h": key_h, "band_extra": band_extra, "band_min": band_min}


func _controls(layout: Dictionary) -> void:
	var edit_top: float = layout["edit_top"]
	var key_h: float = layout["key_h"]
	var keys_top: float = edit_top - _sp - key_h
	var mode_top: float = keys_top - _sp - Kit.MIN_TOUCH
	_mode_bar(Rect2(_m, mode_top, _cw, Kit.MIN_TOUCH))
	_keys(Rect2(_m, keys_top, _cw, key_h))
	var half: float = (_cw - _sp) * 0.5
	_edit_button(Rect2(_m, edit_top, half, Kit.MIN_TOUCH), Icons.UNDO, "Undo")
	_edit_button(Rect2(_m + half + _sp, edit_top, half, Kit.MIN_TOUCH), Icons.ERASE, "Erase")


## PLACE | CROSS OUT: a full-width two-segment bar, the active one in ink.
func _mode_bar(rect: Rect2) -> void:
	var half: float = rect.size.x * 0.5
	var names: Array[String] = ["Place", "Cross out"]
	var kinds: Array[String] = [Icons.PLACE, Icons.CROSS_OUT]
	var modes: Array[int] = [SampleState.MODE_PLACE, SampleState.MODE_CROSS_OUT]
	for i: int in 2:
		var seg: Rect2 = Rect2(rect.position.x + half * float(i), rect.position.y, half, rect.size.y)
		var active: bool = modes[i] == pad_mode
		_kit.panel(self, seg, _c.mode_toggle_active_bg if active else _c.mode_toggle_bg, 0.0)
		var color: Color = _c.mode_toggle_active_text if active else _c.mode_toggle_text
		_kit.icon_text(self, kinds[i], names[i], Palettes.ROLE_BUTTON, color, seg, _icon_side(), _sp * 0.5)
		_kit.tap(self, seg, names[i])
	var frame: Block = _kit.panel(self, rect, Color(0.0, 0.0, 0.0, 0.0), 0.0, true)
	frame.fill = null


## One row of nine tall keys. Cross Out: ink keys with white digits and a
## vermilion slash in the corner. Place: white keys with an ink outline.
func _keys(rect: Rect2) -> void:
	var gap: float = _s.line_box_w
	var key_w: float = (rect.size.x - gap * 8.0) / 9.0
	var cross: bool = pad_mode == SampleState.MODE_CROSS_OUT
	var slash_w: float = _s.line_box_w
	for i: int in 9:
		var key: Rect2 = Rect2(rect.position.x + float(i) * (key_w + gap), rect.position.y, key_w, rect.size.y)
		var face: Block
		if cross:
			face = _kit.panel(self, key, _c.pad_key_cross_bg, 0.0)
			var mark: Color = _c.pad_key_cross_mark
			face.over = func(block: Control) -> void:
				var inset: float = block.size.x * 0.14
				var reach: float = block.size.x * 0.24
				var end: Vector2 = Vector2(block.size.x - inset, inset)
				block.draw_line(end + Vector2(-reach, reach), end, mark, slash_w, true)
		else:
			face = _kit.panel(self, key, _c.pad_key_place_bg, 0.0, true)
		var digit_color: Color = _c.pad_key_cross_text if cross else _c.pad_key_place_text
		_kit.text(self, str(i + 1), Palettes.ROLE_PAD_DIGIT, digit_color, key)
		_kit.tap(self, key, "Key %d" % (i + 1), true)


## Undo and Erase: outlined text buttons with icons.
func _edit_button(rect: Rect2, kind: String, value: String) -> void:
	_kit.panel(self, rect, _c.button_bg, 0.0, true)
	_kit.icon_text(self, kind, value, Palettes.ROLE_BUTTON, _c.button_text, rect, _icon_side(), _sp * 0.5)
	_kit.tap(self, rect, value)


## The level tag: a white box with ultramarine capitals, left in rect.
func _level_tag(level: String, rect: Rect2) -> void:
	var pad: float = _sp * 0.75
	var height: float = _kit.line_height(Palettes.ROLE_LABEL) + _sp * 0.5
	var tag: Rect2 = Rect2(rect.position.x, rect.get_center().y - height * 0.5, _kit.text_width(level, Palettes.ROLE_LABEL) + pad * 2.0, height)
	_kit.panel(self, tag, _c.tag_bg, 0.0)
	_kit.text(self, level, Palettes.ROLE_LABEL, _c.tag_text, tag)


## The Hint button on the band: vermilion, "HINT 80", right edge at right.
func _hint_button(row: Rect2, right: float, cost: int) -> void:
	var value: String = "Hint %d" % cost
	var face_h: float = Kit.MIN_TOUCH - _sp
	var width: float = _icon_side() + _sp * 0.5 + _kit.text_width(value, Palettes.ROLE_BUTTON) + _sp * 2.5
	var touch: Rect2 = Rect2(right - width, row.position.y, width, Kit.MIN_TOUCH)
	var face: Rect2 = Rect2(touch.position.x, touch.get_center().y - face_h * 0.5, width, face_h)
	_kit.panel(self, face, _c.button_primary_bg, 0.0)
	_kit.icon_text(self, Icons.HINT, value, Palettes.ROLE_BUTTON, _c.button_primary_text, face, _icon_side(), _sp * 0.5)
	_kit.tap(self, touch, "Hint")


## A square outlined button on the band (Pause, Close, Back).
func _band_button(touch: Rect2, kind: String, what: String) -> void:
	var face_side: float = Kit.MIN_TOUCH - _sp
	var face: Rect2 = Rect2(touch.get_center() - Vector2(face_side, face_side) * 0.5, Vector2(face_side, face_side))
	var frame: Block = _kit.panel(self, face, _c.hud_bg, 0.0, true, false, _c.hud_text)
	frame.fill = null
	var side: float = _icon_side() * 1.15
	_kit.icon(self, kind, Rect2(face.get_center() - Vector2(side, side) * 0.5, Vector2(side, side)), _c.hud_text)
	_kit.tap(self, touch, what)


## A band with a button on the left of the first row and a title below.
## Returns the band's bottom.
func _title_band(title: String, kind: String, what: String) -> float:
	var row1: Rect2 = Rect2(_m, _top + _sp, _cw, Kit.MIN_TOUCH)
	var title_base: float = row1.end.y + _sp * 0.5 + _kit.cap_height(Palettes.ROLE_TITLE)
	var band: float = title_base + _sp * 1.25
	_kit.panel(self, Rect2(0.0, 0.0, _w, band), _c.hud_bg, 0.0)
	# The button's face lines up with the margin.
	var face_inset: float = _sp * 0.5
	_band_button(Rect2(_m - face_inset, row1.position.y, Kit.MIN_TOUCH, Kit.MIN_TOUCH), kind, what)
	_kit.text_at_baseline(self, title, Palettes.ROLE_TITLE, _c.hud_text, _m, title_base, _cw)
	return band


func _outline(rect: Rect2) -> void:
	var frame: Block = _kit.panel(self, rect, Color(0.0, 0.0, 0.0, 0.0), 0.0, true)
	frame.fill = null


func _icon_side() -> float:
	return roundf(_kit.line_height(Palettes.ROLE_BUTTON) * 1.05)
