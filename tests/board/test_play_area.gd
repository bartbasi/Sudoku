extends "res://tests/unit_test.gd"
## PlayArea in the window shapes of DESIGN_SYSTEM.md 4.11: stacked on phones
## and tablets, side by side in wide and short windows, clamped when too
## small. Every window of tools/design/layout_model.gd is checked against the
## model and Layout, plus the wiring to a session and a resize mid-play.

const Fx := preload("res://tests/board/board_fixtures.gd")
const Model := preload("res://tools/design/layout_model.gd")

const PAD_CONTROLS: Array[StringName] = [
	&"pad:1", &"pad:2", &"pad:3", &"pad:4", &"pad:5", &"pad:6", &"pad:7", &"pad:8", &"pad:9",
	&"place", &"cross_out", &"undo", &"erase",
]
const TOLERANCE: float = 0.5

var area: PlayArea


## A PlayArea over the whole safe rect of a screen w by h dp with the given
## top and bottom insets, set up as the play screen sets it (header row
## reserved) unless header is given.
func _build(w: float, h: float, top: float, bottom: float, header: float = Layout.HEADER_ROW) -> void:
	if area != null:
		area.free()
	var skin: GameSkin = Fx.light()
	area = PlayArea.new()
	area.skin = skin
	area.theme = ThemeFactory.build(skin)
	area.header_height = header
	Fx.root().add_child(area)
	_resize(w, h, top, bottom)


func _resize(w: float, h: float, top: float, bottom: float) -> void:
	area.position = Vector2(0.0, top)
	area.size = Vector2(w, h - top - bottom)
	# The runner keeps nodes outside the tree, where Godot sends no RESIZED.
	area.notification(Control.NOTIFICATION_RESIZED)


func _build_screen(screen: Model.Screen) -> void:
	_build(screen.w, screen.h, screen.top, screen.bottom)


func _free() -> void:
	if area != null:
		area.free()
		area = null


func _safe(screen: Model.Screen) -> Rect2:
	return Rect2(0.0, screen.top, screen.w, screen.h - screen.top - screen.bottom)


func _content(screen: Model.Screen) -> Rect2:
	return _safe(screen).grow(-Fx.light().page_margin)


func _board_side() -> float:
	return area.view.board_square().size.x


func _key_height() -> float:
	return area.pad.control_rect_global(&"pad:1").size.y


## Every pad face together.
func _pad_faces() -> Rect2:
	return area.pad.control_rect_global(&"pad:1").merge(area.pad.control_rect_global(&"erase"))


func _contains(outer: Rect2, inner: Rect2) -> bool:
	return inner.position.x >= outer.position.x - 0.001 and inner.position.y >= outer.position.y - 0.001 \
		and inner.end.x <= outer.end.x + 0.001 and inner.end.y <= outer.end.y + 0.001


func _name(screen: Model.Screen) -> String:
	return screen.label


func _expected_board(screen: Model.Screen) -> float:
	var skin: GameSkin = Fx.light()
	var content: Rect2 = _content(screen)
	if Layout.arrangement(content, skin) == Layout.Arrangement.SIDE:
		return Layout.side_board(content, skin)
	return Layout.stacked_board(content, skin)


func test_every_window_gets_the_arrangement_of_4_11() -> void:
	for screen: Model.Screen in Model.window_screens():
		_build_screen(screen)
		assert_eq(area.arrangement(), screen.expected, _name(screen))
	_free()


func test_board_matches_layout_and_the_model() -> void:
	var skin: GameSkin = Fx.light()
	for screen: Model.Screen in Model.supported_windows(skin) + Model.screens():
		_build_screen(screen)
		var model: Model.StackLayout = Model.play(screen, skin)
		assert_eq(area.arrangement(), model.arrangement, "arrangement at " + _name(screen))
		assert_true(absf(_board_side() - _expected_board(screen)) < TOLERANCE,
			"%s: board %.2f, Layout %.2f" % [_name(screen), _board_side(), _expected_board(screen)])
		assert_true(absf(_board_side() - model.board) < TOLERANCE,
			"%s: board %.2f, model %.2f" % [_name(screen), _board_side(), model.board])
		assert_true(absf(_key_height() - model.key_h) < TOLERANCE,
			"%s: keys %.2f, model %.2f" % [_name(screen), _key_height(), model.key_h])
		var zone: Rect2 = area.info_zone_rect_global()
		assert_true(absf(zone.size.y - model.hint_panel) < TOLERANCE,
			"%s: info zone %.2f, model hint panel %.2f" % [_name(screen), zone.size.y, model.hint_panel])
		var faces_w: float = _pad_faces().size.x
		assert_true(absf(faces_w - (model.content_w - skin.shadow_offset)) < TOLERANCE,
			"%s: pad faces %.2f wide, model %.2f" % [_name(screen), faces_w, model.content_w - skin.shadow_offset])
		var square: Rect2 = area.view.board_square()
		assert_eq(square.size.x, square.size.y, "cells are square")
	_free()


func test_nothing_overlaps_and_everything_is_inside_the_safe_rect() -> void:
	var skin: GameSkin = Fx.light()
	for screen: Model.Screen in Model.supported_windows(skin) + Model.screens():
		_build_screen(screen)
		var label: String = _name(screen)
		var header: Rect2 = area.header_rect_global()
		var band: Rect2 = area.band_rect_global()
		var board: Rect2 = area.view.get_global_rect()
		var faces: Rect2 = _pad_faces()
		# Faces must not overlap anything. The pad's touch areas (its whole
		# rect: faces grown by half a key gap) must not reach the header row,
		# the hint panel's info zone or the board.
		var parts: Dictionary[String, Rect2] = {"header": header, "band": band, "board": board, "keys": faces}
		var names: Array[String] = parts.keys()
		for i: int in names.size():
			for j: int in range(i + 1, names.size()):
				assert_false(parts[names[i]].intersects(parts[names[j]]),
					"%s: %s %s overlaps %s %s" % [label, names[i], parts[names[i]], names[j], parts[names[j]]])
		var touch: Rect2 = area.pad.get_global_rect()
		for part: Rect2 in [header, area.info_zone_rect_global(), board]:
			assert_false(touch.intersects(part), "%s: pad touch areas %s reach %s" % [label, touch, part])
		var safe: Rect2 = _safe(screen)
		var content: Rect2 = _content(screen)
		for part: String in names:
			assert_true(_contains(content, parts[part]), "%s: %s %s inside the content box %s" % [label, part, parts[part], content])
		assert_true(_contains(safe, touch), "%s: pad touch areas inside the safe rect" % label)
		var shadow: Rect2 = Rect2(faces.position, faces.size + Vector2(skin.shadow_offset, skin.shadow_offset))
		assert_true(_contains(safe, shadow), "%s: key shadows inside the safe rect" % label)
		assert_true(shadow.end.x <= content.end.x + 0.001, "%s: key shadows inside the column" % label)
		assert_true(header.size.y >= Layout.HEADER_ROW - 0.001, "%s: header row" % label)
		assert_true(band.size.y >= Layout.BAND_MIN - 0.001, "%s: band at least BAND_MIN" % label)
		assert_true(area.info_zone_rect_global().size.x >= Layout.COLUMN_MIN - 0.001, "%s: info zone width" % label)
	_free()


func test_every_touch_area_is_48_on_every_window() -> void:
	var skin: GameSkin = Fx.light()
	for screen: Model.Screen in Model.supported_windows(skin) + Model.screens():
		_build_screen(screen)
		for control: StringName in PAD_CONTROLS:
			var touch: Rect2 = area.pad.touch_rect_global(control)
			assert_true(touch.size.x >= Layout.TOUCH_MIN - 0.001 and touch.size.y >= Layout.TOUCH_MIN - 0.001,
				"%s at %s: %s" % [control, _name(screen), touch.size])
			assert_true(_contains(_safe(screen), touch), "%s touch area inside the safe rect at %s" % [control, _name(screen)])
	_free()


func test_stacked_at_320_by_568() -> void:
	_build(320.0, 568.0, 32.0, 24.0)
	assert_eq(area.arrangement(), Layout.Arrangement.STACKED)
	assert_true(absf(_board_side() - 245.0) < TOLERANCE, "height-bound board, got %.2f" % _board_side())
	assert_true(is_equal_approx(_key_height(), Layout.KEY_MIN), "keys at KEY_MIN")
	assert_true(is_equal_approx(area.band_rect().size.y, Layout.BAND_MIN))
	var skin: GameSkin = Fx.light()
	assert_true(absf(_pad_faces().end.y + skin.page_margin - (568.0 - 24.0)) < 0.001, "keys page_margin above the safe bottom")
	assert_true(absf(area.header_rect_global().position.y - (32.0 + skin.page_margin)) < 0.001, "header row page_margin below the safe top")


func test_stacked_at_360_by_800() -> void:
	_build(360.0, 800.0, 32.0, 24.0)
	assert_true(absf(_board_side() - 337.0) < TOLERANCE, "width-bound board, got %.2f" % _board_side())
	assert_true(is_equal_approx(_key_height(), Layout.KEY_MAX), "keys at KEY_MAX")
	# DESIGN_SYSTEM.md 4.10: the info zone (header row and band) is 130 dp.
	var zone: float = area.header_rect().size.y + area.band_rect().size.y
	assert_true(absf(zone - 130.0) < 1.0, "info zone %.1f" % zone)
	assert_true(is_equal_approx(area.info_zone_rect().size.y, zone - Fx.light().space_s), "the info zone rect stops space_s short")
	assert_true(is_equal_approx(area.header_rect().end.y, area.band_rect().position.y), "the band starts under the header row")
	assert_true(is_equal_approx(area.band_rect_global().end.y, area.view.get_global_rect().position.y), "the band ends at the board's outer edge")


func test_stacked_on_a_tablet() -> void:
	_build(1024.0, 1366.0, 24.0, 24.0)
	assert_true(absf(_board_side() - 593.0) < TOLERANCE, "board %.2f" % _board_side())
	var column: Rect2 = area.band_rect_global()
	assert_true(is_equal_approx(column.size.x, Layout.COLUMN_MAX), "column capped at COLUMN_MAX")
	assert_true(is_equal_approx(column.position.x, (1024.0 - Layout.COLUMN_MAX) * 0.5), "column centered")
	assert_true(is_equal_approx(area.band_rect().size.y, Layout.BAND_MAX), "band grown to BAND_MAX")
	assert_true(is_equal_approx(_key_height(), Layout.KEY_MAX))


func test_side_by_side_inner_top_half() -> void:
	# DESIGN_SYSTEM.md 4.11: 690 by 400 with the status bar. Board 345,
	# side column 306, keys 64, info zone 144.
	_build(690.0, 400.0, 32.0, 0.0)
	assert_eq(area.arrangement(), Layout.Arrangement.SIDE)
	assert_true(absf(_board_side() - 345.0) < TOLERANCE, "board %.2f" % _board_side())
	assert_true(absf(area.band_rect().size.x - 306.0) < TOLERANCE, "side column %.2f" % area.band_rect().size.x)
	assert_true(is_equal_approx(_key_height(), Layout.KEY_MAX), "keys grow first")
	var zone: float = area.header_rect().size.y + area.band_rect().size.y
	assert_true(absf(zone - 144.0) < TOLERANCE, "info zone %.2f" % zone)
	var board: Rect2 = area.view.get_global_rect()
	assert_true(absf(board.position.y - area.header_rect_global().position.y) < 0.001, "board top and side column top line up")
	assert_true(absf(board.end.y - _pad_faces().end.y) < 0.001, "pad bottom lines up with the board bottom")
	var gap: float = area.header_rect_global().position.x - board.end.x
	assert_true(is_equal_approx(gap, Layout.SIDE_GAP), "SIDE_GAP between board and side column, got %.2f" % gap)


func test_side_by_side_board_centered_when_width_bound() -> void:
	# 690 by 400 with the gesture bar: board 347, width-bound, 3 dp above and below.
	_build(690.0, 400.0, 0.0, 24.0)
	assert_eq(area.arrangement(), Layout.Arrangement.SIDE)
	var content: Rect2 = Rect2(0.0, 0.0, 690.0, 376.0).grow(-Fx.light().page_margin)
	var board: Rect2 = area.view.get_global_rect()
	assert_true(absf(board.position.y - content.position.y - (content.end.y - board.end.y)) < 0.001, "centered vertically")
	assert_true(absf(board.position.y - content.position.y - 3.0) < TOLERANCE, "3 dp above, got %.2f" % (board.position.y - content.position.y))
	assert_true(absf(area.band_rect().size.x - Layout.COLUMN_MIN) < 0.001, "side column at COLUMN_MIN")


func test_side_by_side_group_is_centered() -> void:
	# QA L6 window, 700 by 420, no insets: wider than board and side column need.
	_build(700.0, 420.0, 0.0, 0.0)
	assert_eq(area.arrangement(), Layout.Arrangement.SIDE)
	var content: Rect2 = Rect2(0.0, 0.0, 700.0, 420.0).grow(-Fx.light().page_margin)
	var left: float = area.view.get_global_rect().position.x - content.position.x
	var right: float = content.end.x - area.band_rect_global().end.x
	assert_true(absf(left - right) < 0.001, "group centered: %.2f left, %.2f right" % [left, right])
	assert_true(area.band_rect().size.x <= Layout.SIDE_MAX + 0.001, "side column at most SIDE_MAX")


func test_too_small_never_goes_negative() -> void:
	var sizes: Array[Vector2] = [Vector2(344, 430), Vector2(230, 829), Vector2(690, 276), Vector2(100, 100),
		Vector2(10, 10), Vector2(0, 0), Vector2(319, 800)]
	for screen: Vector2 in sizes:
		_build(screen.x, screen.y, 0.0, 0.0)
		assert_eq(area.arrangement(), Layout.Arrangement.TOO_SMALL, "too small at %s" % screen)
		for rect: Rect2 in [area.header_rect(), area.band_rect(), area.info_zone_rect(), area.view.get_rect(), area.pad.get_rect()]:
			assert_true(rect.size.x >= 0.0 and rect.size.y >= 0.0, "no negative size at %s: %s" % [screen, rect])
		assert_true(_board_side() >= 0.0)
		for control: StringName in PAD_CONTROLS:
			var face: Rect2 = area.pad.control_rect_global(control)
			assert_true(face.size.x >= 0.0 and face.size.y >= 0.0, "%s face at %s" % [control, screen])
	_free()


func test_lessons_have_no_header_row() -> void:
	_build(360.0, 640.0, 24.0, 24.0, 0.0)
	assert_eq(area.header_rect().size.y, 0.0)
	assert_true(is_equal_approx(area.band_rect().position.y, area.header_rect().position.y), "the band starts at the top")
	var full: float = _board_side()
	area.set_band_height(200.0)
	assert_true(is_equal_approx(area.band_rect().size.y, 200.0))
	assert_true(_board_side() < full, "a taller band leaves less for the board")
	assert_true(area.band_rect_global().end.y <= area.view.get_global_rect().position.y + 0.001, "the band sits above the board")
	area.set_band_height(0.0)
	assert_true(is_equal_approx(_board_side(), full), "back to the Layout default")
	_free()


func test_lesson_band_side_by_side() -> void:
	_build(690.0, 400.0, 32.0, 0.0, 0.0)
	area.set_band_height(150.0)
	assert_eq(area.arrangement(), Layout.Arrangement.SIDE)
	assert_true(is_equal_approx(area.band_rect().size.y, 150.0))
	assert_true(absf(_board_side() - 345.0) < TOLERANCE, "the board does not depend on the card")
	assert_true(area.band_rect_global().end.y <= _pad_faces().position.y + 0.001, "the card sits above the pad")
	assert_true(area.band_rect_global().position.x >= area.view.get_global_rect().end.x, "the card is right of the board")
	_free()


func test_header_height_change_lays_out_again() -> void:
	_build(360.0, 800.0, 32.0, 24.0, 0.0)
	var band_top: float = area.band_rect().position.y
	area.header_height = Layout.HEADER_ROW
	assert_true(is_equal_approx(area.header_rect().size.y, Layout.HEADER_ROW))
	assert_true(area.band_rect().position.y > band_top, "the band moves under the header row")
	area.header_height = -5.0
	assert_eq(area.header_height, 0.0, "below zero counts as zero")
	_free()


func test_resize_mid_play_keeps_the_session() -> void:
	_build(690.0, 829.0, 32.0, 24.0)
	var session: GameSession = Fx.session_b()
	area.setup(session)
	area.controller.audio = Fx.FakeAudio.new()
	Fx.root().add_child(area.controller.audio)
	_tap_cell(40)
	area.pad.tap(_pad_point(&"pad:8"))
	_tap_cell(0)
	area.pad.tap(_pad_point(&"cross_out"))
	area.pad.tap(_pad_point(&"pad:5"))
	assert_eq(session.board.digit(40), 8)
	assert_eq(session.mode, GameSession.Mode.CROSS_OUT)
	assert_true(session.board.is_crossed(0, 5), "5 crossed in r1c1")
	var before: Dictionary = session.to_dict()
	assert_eq(area.arrangement(), Layout.Arrangement.STACKED)
	_resize(690.0, 400.0, 32.0, 0.0)
	assert_eq(area.arrangement(), Layout.Arrangement.SIDE)
	assert_eq(session.to_dict(), before, "going side by side leaves the session alone")
	assert_eq(area.view.session, session)
	assert_eq(area.pad.mode(), GameSession.Mode.CROSS_OUT)
	assert_true(area.pad.is_undo_enabled())
	# Input still lands on the right cell and key in the new arrangement.
	_tap_cell(2)
	assert_eq(session.selected, 2)
	_tap_cell(0)
	before = session.to_dict()
	_resize(690.0, 829.0, 32.0, 24.0)
	assert_eq(area.arrangement(), Layout.Arrangement.STACKED)
	assert_eq(session.to_dict(), before, "going back to stacked leaves the session alone")
	area.pad.tap(_pad_point(&"pad:5"))
	assert_false(session.board.is_crossed(0, 5), "tapping 5 again restores it")
	area.controller.audio.free()
	_free()


func test_setup_wires_the_session() -> void:
	_build(360.0, 800.0, 32.0, 24.0)
	var session: GameSession = Fx.session_b()
	area.setup(session)
	area.controller.audio = Fx.FakeAudio.new()
	Fx.root().add_child(area.controller.audio)
	assert_eq(area.view.session, session)
	_tap_cell(40)
	assert_eq(session.selected, 40)
	area.pad.tap(_pad_point(&"pad:8"))
	assert_eq(session.board.digit(40), 8)
	assert_true(area.pad.is_undo_enabled())
	area.controller.audio.free()
	_free()


func test_scene_file_gives_a_play_area() -> void:
	var node: Node = (load("res://scenes/board/play_area.tscn") as PackedScene).instantiate()
	assert_true(node is PlayArea)
	var play: PlayArea = node as PlayArea
	assert_true(play.view is BoardView)
	assert_true(play.pad is NumberPad)
	assert_true(play.controller is BoardController)
	assert_eq(play.header_height, 0.0, "no header row unless the screen asks for one")
	node.free()


func _tap_cell(cell: int) -> void:
	var at: Vector2 = area.view.get_global_transform().affine_inverse() * area.view.cell_rect_global(cell).get_center()
	area.view._gui_input(Fx.press(at))


func _pad_point(control: StringName) -> Vector2:
	return area.pad.get_global_transform().affine_inverse() * area.pad.control_rect_global(control).get_center()
