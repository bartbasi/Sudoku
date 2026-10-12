extends "res://tests/unit_test.gd"
## PlayArea: the vertical stack at 320 by 568, 360 by 800 and a tablet, with
## notch and gesture bar insets, and the wiring to a session.

const Fx := preload("res://tests/board/board_fixtures.gd")

var area: PlayArea


## A PlayArea in the safe rect below a play screen header row, on a screen
## w by h dp with the given top and bottom insets.
func _build(w: float, h: float, top: float, bottom: float) -> void:
	var skin: GameSkin = Fx.light()
	area = PlayArea.new()
	area.skin = skin
	area.theme = ThemeFactory.build(skin)
	Fx.root().add_child(area)
	area.position = Vector2(0.0, top + skin.page_margin + Layout.HEADER_ROW)
	area.size = Vector2(w, h - top - bottom - skin.page_margin - Layout.HEADER_ROW)
	# The runner keeps nodes outside the tree, where Godot sends no RESIZED.
	area.notification(Control.NOTIFICATION_RESIZED)


func _board_side() -> float:
	return area.view.board_square().size.x


func _key_height() -> float:
	return area.pad.control_rect_global(&"pad:1").size.y


func _check_stack(w: float, h: float, bottom: float) -> void:
	var skin: GameSkin = Fx.light()
	var band: Rect2 = area.band_rect_global()
	var board: Rect2 = area.view.get_global_rect()
	var keys: Rect2 = area.pad.control_rect_global(&"pad:1").merge(area.pad.control_rect_global(&"erase"))
	var safe_bottom: float = h - bottom
	assert_true(band.size.y >= Layout.BAND_MIN - 0.001, "band at least BAND_MIN")
	assert_true(band.end.y <= board.position.y + 0.001, "band above the board")
	assert_true(board.end.y + Layout.BOARD_GAP_MIN <= keys.position.y + 0.001, "gap between board and keys")
	assert_true(keys.end.y + skin.page_margin <= safe_bottom + 0.001, "keys page_margin above the safe bottom")
	assert_true(board.position.x >= skin.page_margin - 0.001 and board.end.x <= w - skin.page_margin + 0.001, "board inside the margins")
	assert_true(keys.position.x >= skin.page_margin - 0.001 and keys.end.x + skin.shadow_offset <= w - skin.page_margin + 0.001, "keys and shadow inside the margins")
	var square: Rect2 = area.view.board_square()
	assert_eq(square.size.x, square.size.y, "cells are square")


func test_layout_at_320_by_568() -> void:
	_build(320.0, 568.0, 32.0, 24.0)
	_check_stack(320.0, 568.0, 24.0)
	assert_true(absf(_board_side() - 245.0) < 0.5, "height-bound board, got %.2f" % _board_side())
	assert_true(is_equal_approx(_key_height(), Layout.KEY_MIN), "keys at KEY_MIN")
	assert_true(is_equal_approx(area.band_rect().size.y, Layout.BAND_MIN))


func test_layout_at_360_by_800() -> void:
	_build(360.0, 800.0, 32.0, 24.0)
	_check_stack(360.0, 800.0, 24.0)
	assert_true(absf(_board_side() - 337.0) < 0.5, "width-bound board, got %.2f" % _board_side())
	assert_true(is_equal_approx(_key_height(), Layout.KEY_MAX), "keys at KEY_MAX")
	# DESIGN_SYSTEM.md 4.10: the info zone (header row and band) is 130 dp.
	assert_true(absf(area.band_rect().size.y + Layout.HEADER_ROW - 130.0) < 1.0, "info zone %.1f" % (area.band_rect().size.y + Layout.HEADER_ROW))


func test_layout_on_a_tablet() -> void:
	_build(1024.0, 1366.0, 24.0, 24.0)
	_check_stack(1024.0, 1366.0, 24.0)
	assert_true(absf(_board_side() - 593.0) < 0.5, "board %.2f" % _board_side())
	var column: Rect2 = area.band_rect_global()
	assert_true(is_equal_approx(column.size.x, Layout.COLUMN_MAX), "column capped at COLUMN_MAX")
	assert_true(is_equal_approx(column.position.x, (1024.0 - Layout.COLUMN_MAX) * 0.5), "column centered")
	assert_true(is_equal_approx(area.band_rect().size.y, Layout.BAND_MAX), "band grown to BAND_MAX")
	assert_true(is_equal_approx(_key_height(), Layout.KEY_MAX))


func test_every_touch_area_is_48_at_every_size() -> void:
	for screen: Vector4 in [Vector4(320, 568, 32, 24), Vector4(360, 800, 32, 24), Vector4(1024, 1366, 24, 24), Vector4(360, 640, 24, 24)]:
		_build(screen.x, screen.y, screen.z, screen.w)
		for control: StringName in [&"pad:1", &"pad:5", &"pad:9", &"place", &"cross_out", &"undo", &"erase"]:
			var touch: Rect2 = area.pad.touch_rect_global(control)
			assert_true(touch.size.x >= 48.0 - 0.001 and touch.size.y >= 48.0 - 0.001,
				"%s at %.0f by %.0f: %s" % [control, screen.x, screen.y, touch.size])
		area.free()


func test_band_height_for_lessons() -> void:
	_build(360.0, 800.0, 32.0, 24.0)
	var full: float = _board_side()
	area.set_band_height(200.0)
	assert_true(is_equal_approx(area.band_rect().size.y, 200.0))
	assert_true(_board_side() < full, "a taller band leaves less for the board")
	_check_stack(360.0, 800.0, 24.0)
	area.set_band_height(0.0)
	assert_true(is_equal_approx(_board_side(), full), "back to the Layout default")


func test_band_rect_global_follows_position() -> void:
	_build(360.0, 800.0, 32.0, 24.0)
	var band: Rect2 = area.band_rect_global()
	assert_true(is_equal_approx(band.position.y, area.position.y + area.band_rect().position.y))
	assert_true(is_equal_approx(band.end.y, area.view.get_global_rect().position.y), "the band ends at the board's outer edge")


func test_setup_wires_the_session() -> void:
	_build(360.0, 800.0, 32.0, 24.0)
	var session: GameSession = Fx.session_b()
	area.setup(session)
	area.controller.audio = Fx.FakeAudio.new()
	Fx.root().add_child(area.controller.audio)
	assert_eq(area.view.session, session)
	var view_center: Vector2 = area.view.get_global_transform().affine_inverse() * area.view.cell_rect_global(40).get_center()
	area.view._gui_input(Fx.press(view_center))
	assert_eq(session.selected, 40)
	area.pad.tap(area.pad.get_global_transform().affine_inverse() * area.pad.control_rect_global(&"pad:8").get_center())
	assert_eq(session.board.digit(40), 8)
	assert_true(area.pad.is_undo_enabled())


func test_scene_file_gives_a_play_area() -> void:
	var node: Node = (load("res://scenes/board/play_area.tscn") as PackedScene).instantiate()
	assert_true(node is PlayArea)
	var play: PlayArea = node as PlayArea
	assert_true(play.view is BoardView)
	assert_true(play.pad is NumberPad)
	assert_true(play.controller is BoardController)
	node.free()
