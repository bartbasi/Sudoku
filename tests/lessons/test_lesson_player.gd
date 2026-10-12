extends "res://tests/unit_test.gd"
## LessonPlayer on the real PlayArea: right taps reach the session and move
## the screen to its praise and Next; wrong taps change nothing and show the
## screen's text with the "Not quite" tag; taps after the answer are
## ignored; finishing the last screen's answer emits finished once, and the
## lesson is recorded through the finished signal as App wires it.

const Lx := preload("res://tests/lessons/lesson_fixtures.gd")

var player: LessonPlayer
var finished_ids: Array[String] = []
var closed_count: int = 0


## A fake App: the parts of App a lesson reaches (App._wire_lesson connects
## finished to record_lesson_finished and closed to go_back).
class FakeApp extends Node:
	var lessons: LessonProgress = LessonProgress.new()
	var backs: int = 0

	func record_lesson_finished(lesson_id: String) -> void:
		lessons.mark_finished(lesson_id)

	func go_back() -> void:
		backs += 1


func _build(w: float = 360.0, h: float = 800.0) -> void:
	var skin: GameSkin = Lx.light()
	player = LessonPlayer.new()
	player.skin = skin
	player.theme = ThemeFactory.build(skin)
	player.size = Vector2(w, h)
	player.safe_rect_override = Rect2(0.0, 32.0, w, h - 56.0)
	Lx.root().add_child(player)
	player.ensure_built()
	player.finished.connect(func(id: String) -> void: finished_ids.append(id))
	player.closed.connect(func() -> void: closed_count += 1)


func _start(lesson: Lesson) -> void:
	player.start(lesson)
	# The runner keeps nodes outside the tree, where Godot sends no RESIZED.
	player.notification(Control.NOTIFICATION_RESIZED)


func _tap(action: BoardAction) -> void:
	player.area.controller.handle(action)


func _cell(cell: int) -> BoardAction:
	return BoardAction.create(BoardAction.Kind.CELL, cell)


func _pad(d: int) -> BoardAction:
	return BoardAction.create(BoardAction.Kind.PAD, -1, d)


func _mode() -> BoardAction:
	return BoardAction.create(BoardAction.Kind.MODE)


func _erase() -> BoardAction:
	return BoardAction.create(BoardAction.Kind.ERASE)


func _undo() -> BoardAction:
	return BoardAction.create(BoardAction.Kind.UNDO)


## The state a wrong tap must leave alone (GDD 15.4).
func _state() -> Array:
	var s: GameSession = player.session
	return [s.board.digits.duplicate(), s.board.marks.duplicate(), s.selected, s.mode, player.screen_index]


func _small() -> Lesson:
	return LessonLibrary.parse(JSON.stringify(Lx.small_lesson()))


func _free() -> void:
	if player != null and is_instance_valid(player):
		player.free()


func test_start_shows_the_first_screen() -> void:
	_build()
	_start(Lx.lesson(2))
	assert_eq(player.screen_index, 0)
	assert_eq(player.session.selected, -1)
	assert_eq(player.session.mode, GameSession.Mode.PLACE)
	assert_false(player.session.auto_cross, "Auto Cross is off in a lesson")
	assert_eq(player.area.view.lesson_marks, PackedInt32Array([40]))
	assert_eq(player.card_text(), Lx.lesson(2).screens[0].text)
	assert_false(player.is_showing_wrong())
	assert_false(player.is_praise_showing())
	assert_eq(player.card.lesson_label.text, "LESSON 2 OF 5")
	assert_eq(player.card.step_label.text, "STEP 1 OF 8")
	_free()


func test_wrong_taps_change_nothing_and_explain() -> void:
	_build()
	var lesson: Lesson = Lx.lesson(2)
	_start(lesson)
	player.show_screen(2)
	var before: Array = _state()
	var texts: Dictionary[String, BoardAction] = {
		"Keep this cell selected. Tap 9 on the number pad.": _cell(0),
		"There is no 5 in this row, column or box. So 5 can still go here. Tap 9.": _pad(5),
		"Stay in Cross Out mode for now. Tap 9 on the number pad.": _mode(),
		"Tap 9 on the number pad.": _erase(),
	}
	for text: String in texts:
		_tap(texts[text])
		assert_eq(_state(), before, "a wrong tap changes nothing: %s" % text)
		assert_eq(player.card_text(), text)
		assert_true(player.is_showing_wrong(), "the Not quite tag shows")
		assert_eq(player.card.tag.get_child(0).get(&"text"), "NOT QUITE")
		assert_false(player.is_praise_showing())
	_tap(_pad(9))
	assert_true(player.session.board.is_crossed(40, 9), "the right tap crosses 9")
	assert_eq(player.session.board.mark(40, 9), Board.Mark.CROSSED_HAND)
	assert_true(player.is_praise_showing())
	assert_eq(player.praise_label.text, lesson.screens[2].praise)
	assert_false(player.is_showing_wrong(), "the step text shows again")
	_free()


func test_taps_after_the_answer_are_ignored_until_next() -> void:
	_build()
	_start(Lx.lesson(2))
	_tap(_cell(40))
	assert_true(player.is_praise_showing())
	var before: Array = _state()
	var text: String = player.card_text()
	for action: BoardAction in [_cell(0), _pad(3), _mode(), _erase(), _undo()]:
		_tap(action)
		assert_eq(_state(), before, "ignored after the answer")
		assert_eq(player.card_text(), text, "no text after the answer")
		assert_false(player.is_showing_wrong())
	player.press_next()
	assert_eq(player.screen_index, 1)
	assert_false(player.is_praise_showing())
	assert_eq(player.session.selected, 40, "screen 2 starts with r5c5 selected")
	_free()


func test_a_sequence_screen_waits_for_each_tap_in_turn() -> void:
	_build()
	_start(_small())
	_tap(_cell(40))
	player.press_next()
	var before: Array = _state()
	_tap(_pad(3))
	assert_eq(_state(), before, "3 before 9 is wrong")
	assert_eq(player.card_text(), "Not 3. Cross out 9.")
	_tap(_pad(9))
	assert_true(player.session.board.is_crossed(40, 9))
	assert_false(player.is_praise_showing(), "two steps still to do")
	assert_false(player.is_showing_wrong(), "a right tap brings the step text back")
	_tap(_pad(9))
	assert_true(player.session.board.is_crossed(40, 9), "9 again would restore it, so it is stopped")
	assert_eq(player.card_text(), "9 has an X. Now cross out 3.")
	_tap(_pad(7))
	assert_eq(player.card_text(), "7 later. Now cross out 3.")
	assert_true(player.session.board.is_crossed(40, 7))
	_tap(_pad(3))
	_tap(_pad(7))
	assert_false(player.session.board.is_crossed(40, 7), "7 is brought back")
	assert_true(player.is_praise_showing())
	_free()


func test_finishing_the_last_answer_records_the_lesson_once() -> void:
	_build()
	var app: FakeApp = FakeApp.new()
	player.finished.connect(app.record_lesson_finished)
	player.closed.connect(app.go_back)
	_start(_small())
	_tap(_cell(40))
	assert_eq(finished_ids.size(), 0, "not finished after the first screen")
	player.press_next()
	for d: int in [9, 3, 7]:
		_tap(_pad(d))
	assert_eq(finished_ids, ["lesson_07"] as Array[String], "finished as soon as the last answer is done")
	assert_true(app.lessons.is_finished("lesson_07"))
	assert_eq(closed_count, 0, "still on the screen until Next")
	_tap(_pad(9))
	assert_eq(finished_ids.size(), 1, "only once")
	player.press_next()
	assert_eq(closed_count, 1, "Next on the last screen leaves the lesson")
	assert_eq(app.backs, 1)
	app.free()
	_free()


func test_leaving_early_records_nothing() -> void:
	_build()
	_start(_small())
	_tap(_cell(40))
	player.press_next()
	player.close_area.tap()
	assert_eq(closed_count, 1, "Close leaves the lesson")
	assert_eq(finished_ids.size(), 0)
	_free()


func test_starting_again_begins_at_screen_one() -> void:
	_build()
	_start(_small())
	_tap(_cell(40))
	player.press_next()
	_tap(_pad(9))
	_start(_small())
	assert_eq(player.screen_index, 0)
	assert_eq(player.session.selected, -1)
	assert_false(player.session.board.is_crossed(40, 9))
	_free()


func test_every_lesson_plays_through_to_finished() -> void:
	_build()
	for lesson: Lesson in LessonLibrary.load_all():
		finished_ids.clear()
		_start(lesson)
		for i: int in lesson.screens.size():
			assert_eq(player.screen_index, i)
			for step: BoardAction in lesson.screens[i].steps:
				assert_false(player.is_praise_showing(), "%s screen %d waits for its answer" % [lesson.id, i + 1])
				_tap(step)
				assert_false(player.is_showing_wrong(), "%s screen %d: the answer is never a wrong tap" % [lesson.id, i + 1])
			assert_true(player.is_praise_showing(), "%s screen %d praises the answer" % [lesson.id, i + 1])
			if i < lesson.screens.size() - 1:
				assert_eq(finished_ids.size(), 0)
				player.press_next()
		assert_eq(finished_ids, [lesson.id] as Array[String], "%s is finished" % lesson.id)
	_free()


func test_placed_digits_are_the_players_own() -> void:
	_build()
	_start(Lx.lesson(1))
	player.show_screen(5)
	_tap(_pad(8))
	var cell: int = LessonLibrary.cell_from_name("r8c6")
	assert_eq(player.session.board.digit(cell), 8)
	assert_false(player.session.board.is_given(cell))
	assert_false(player.session.is_completed, "a lesson never completes like a puzzle")
	_free()


func test_marked_controls_get_a_ring_until_the_step_is_done() -> void:
	_build()
	_start(Lx.lesson(2))
	player.show_screen(1)
	assert_eq(player.marks.controls, [&"mode"] as Array[StringName])
	_tap(_mode())
	assert_eq(player.session.mode, GameSession.Mode.CROSS_OUT)
	assert_true(player.marks.controls.is_empty(), "the ring goes when the step is done")
	_free()


func test_the_card_does_not_move_on_a_wrong_tap() -> void:
	_build()
	_start(Lx.lesson(2))
	player.show_screen(7)
	var band: Rect2 = player.area.band_rect()
	var board: Rect2 = player.area.view.get_rect()
	_tap(_pad(4))
	player.notification(Control.NOTIFICATION_RESIZED)
	assert_true(player.is_showing_wrong())
	assert_eq(player.area.band_rect(), band, "the band keeps its height")
	assert_eq(player.area.view.get_rect(), board, "the board stays put")
	_free()


func test_the_board_never_goes_under_the_floor() -> void:
	for screen_size: Vector2 in [Vector2(320.0, 568.0), Vector2(360.0, 640.0), Vector2(360.0, 800.0)]:
		_build(screen_size.x, screen_size.y)
		for lesson: Lesson in LessonLibrary.load_all():
			_start(lesson)
			for i: int in lesson.screens.size():
				player.show_screen(i)
				var side: float = player.area.view.board_square().size.x
				assert_true(side >= Layout.LESSON_BOARD_FLOOR - 0.5,
					"%s screen %d at %s: board %.1f" % [lesson.id, i + 1, screen_size, side])
				var band: Rect2 = player.area.band_rect()
				assert_true(band.end.y <= player.area.view.position.y + 0.5, "the card sits above the board")
		_free()


## A press on a pad control, sent the way the viewport sends it: the pad's
## gui_input signal, in the pad's own coordinates.
func _press_pad(control: StringName) -> void:
	var pad: NumberPad = player.area.pad
	var rect: Rect2 = pad.touch_rect_global(control)
	assert_true(rect.has_area(), "the pad has a touch area for %s" % control)
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = pad.get_global_transform().affine_inverse() * rect.get_center()
	pad.gui_input.emit(event)


func test_a_tap_on_undo_while_it_is_off_shows_the_fallback() -> void:
	_build()
	var lesson: Lesson = Lx.lesson(2)
	_start(lesson)
	player.show_screen(2)
	assert_false(player.area.pad.is_undo_enabled(), "Undo is off at the start of a screen")
	var before: Array = _state()
	_press_pad(NumberPad.UNDO)
	assert_eq(_state(), before, "the tap changes nothing")
	assert_true(player.is_showing_wrong(), "the Not quite tag shows")
	assert_eq(player.card_text(), lesson.screens[2].fallback)
	_free()


func test_a_tap_on_the_mode_already_on_is_a_wrong_tap() -> void:
	_build()
	var lesson: Lesson = Lx.lesson(2)
	_start(lesson)
	# Screen 3 is in Cross Out mode, and its wrong list has a mode entry.
	player.show_screen(2)
	var before: Array = _state()
	_press_pad(NumberPad.CROSS_OUT)
	assert_eq(_state(), before)
	assert_eq(player.card_text(), "Stay in Cross Out mode for now. Tap 9 on the number pad.")
	# Screen 2's answer is the mode switch; Place, already on, is not it.
	player.show_screen(1)
	before = _state()
	_press_pad(NumberPad.PLACE)
	assert_eq(_state(), before, "the screen does not move on")
	assert_false(player.is_praise_showing())
	assert_eq(player.card_text(), lesson.screens[1].fallback)
	_free()


func test_pad_taps_that_reach_the_gate_are_left_to_it() -> void:
	_build()
	var lesson: Lesson = Lx.lesson(2)
	_start(lesson)
	player.show_screen(1)
	for control: StringName in [&"pad:3", NumberPad.ERASE, NumberPad.CROSS_OUT]:
		player.dropped_pad_tap(control)
		assert_false(player.is_showing_wrong(), "%s goes through the gate, not here" % control)
	_free()


func test_dropped_taps_after_the_answer_show_nothing() -> void:
	_build()
	_start(Lx.lesson(2))
	player.show_screen(2)
	_tap(_pad(9))
	assert_true(player.is_praise_showing())
	player.dropped_pad_tap(NumberPad.CROSS_OUT)
	player.dropped_pad_tap(NumberPad.UNDO)
	assert_false(player.is_showing_wrong(), "every other tap is ignored until Next")
	_free()


func test_the_text_steps_down_by_label_variation() -> void:
	assert_eq(LessonPlayer.STEP_DOWN, [ThemeFactory.BODY, ThemeFactory.BODY_SMALL, ThemeFactory.BODY_SMALL_12] as Array[StringName])
	var seen: Dictionary[StringName, bool] = {}
	for screen_size: Vector2 in [Vector2(320.0, 568.0), Vector2(360.0, 800.0)]:
		_build(screen_size.x, screen_size.y)
		for lesson: Lesson in LessonLibrary.load_all():
			_start(lesson)
			for i: int in lesson.screens.size():
				player.show_screen(i)
				var body: Label = player.card.body
				assert_false(body.has_theme_font_size_override(&"font_size"), "no size override")
				assert_true(LessonPlayer.STEP_DOWN.has(body.theme_type_variation), String(body.theme_type_variation))
				seen[body.theme_type_variation] = true
		_free()
	assert_true(seen.has(ThemeFactory.BODY), "a tall screen keeps the body style")
