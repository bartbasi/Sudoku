extends "res://tests/unit_test.gd"
## Phase 4 verify item 6, end to end: every lesson opens from the lessons
## list (Main menu, Lessons, its row), runs every screen to its praise with
## the screen's answer tapped on the real board and pad, Next moves on, the
## last Next returns to the list, the lesson is recorded, the list shows its
## check and the stats screen counts it. Lesson 2 includes Bart's example
## (GDD AT-14, App steps), including the wrong tap on 5.

const Ix := preload("res://tests/integration/integration_fixtures.gd")


func _open_list(h: Ix.Harness) -> LessonsScreen:
	assert_true(Ix.click(h.top().get(&"lessons_button") as Button), "Lessons")
	Ix.fit(h)
	assert_eq(h.screen_name(), AppService.LESSONS)
	return h.top() as LessonsScreen


## Opens a row of the list as a tap on it does, and lays out the player. In
## the running game the player finds the skin through the Skins autoload,
## which it cannot reach outside the tree, so the test hands it the same skin.
func _open_lesson(h: Ix.Harness, list: LessonsScreen, index: int) -> LessonPlayer:
	assert_true(Ix.click(list.rows[index]), "row %d" % index)
	assert_eq(h.screen_name(), AppService.LESSON)
	var player: LessonPlayer = h.top() as LessonPlayer
	if player == null:
		return null
	player.skin = h.app.current_skin()
	player.call(&"_apply_skin")
	Ix.fit(h)
	player.notification(Control.NOTIFICATION_RESIZED)
	return player


func _do_step(area: PlayArea, step: BoardAction) -> void:
	match step.kind:
		BoardAction.Kind.CELL:
			Ix.tap_cell(area, step.cell)
		BoardAction.Kind.PAD:
			Ix.tap_digit(area, step.digit)
		BoardAction.Kind.MODE:
			var off: int = GameSession.Mode.PLACE if area.pad.mode() == GameSession.Mode.CROSS_OUT else GameSession.Mode.CROSS_OUT
			Ix.tap_mode(area, off)
		BoardAction.Kind.ERASE:
			Ix.tap_key(area, NumberPad.ERASE)
		BoardAction.Kind.UNDO:
			Ix.tap_key(area, NumberPad.UNDO)


func test_every_lesson_runs_start_to_finish_from_the_lessons_list() -> void:
	var dir: String = Ix.new_dir("lessons")
	Ix.write_settings(dir)
	var h: Ix.Harness = Ix.open_app(dir)
	var list: LessonsScreen = _open_list(h)
	var count: int = list.lessons.size()
	assert_eq(count, 5, "lessons 1 to 5")
	for index: int in count:
		var lesson: Lesson = list.lessons[index]
		assert_false(list.is_marked_finished(index), "%s not yet finished" % lesson.id)
		var player: LessonPlayer = _open_lesson(h, list, index)
		if player == null:
			fail("%s did not open" % lesson.id)
			break
		assert_eq(player.lesson, lesson)
		for s: int in lesson.screens.size():
			assert_eq(player.screen_index, s, "%s screen %d" % [lesson.id, s + 1])
			var screen: LessonScreen = lesson.screens[s]
			assert_false(player.is_praise_showing())
			for step: BoardAction in screen.steps:
				_do_step(player.area, step)
				assert_false(player.is_showing_wrong(), "%s screen %d: a right tap is accepted" % [lesson.id, s + 1])
			assert_true(player.is_praise_showing(), "%s screen %d reaches its praise" % [lesson.id, s + 1])
			if not player.is_praise_showing():
				break
			if s == lesson.screens.size() - 1:
				assert_true(h.app.lessons.is_finished(lesson.id), "%s recorded at its last answer" % lesson.id)
			assert_true(Ix.click(player.next_button), "Next")
		assert_eq(h.screen_name(), AppService.LESSONS, "%s: the last Next returns to the list" % lesson.id)
		list = h.top() as LessonsScreen
		Ix.fit(h)
		assert_true(list.is_marked_finished(index), "%s shows its check" % lesson.id)
	assert_eq(h.app.lessons.finished_count(), count)
	h.app.go_back()
	Ix.fit(h)
	assert_eq(h.screen_name(), AppService.MAIN_MENU)
	Ix.click(h.top().get(&"stats_button") as Button)
	Ix.fit(h)
	assert_eq((h.top().get(&"lessons_value") as Label).text, "5 of 5", "the stats screen counts them")
	Ix.quit(h)
	var again: Ix.Harness = Ix.open_app(dir)
	assert_eq(again.app.lessons.finished_count(), count, "lesson progress is saved")
	Ix.close(again)


func test_barts_example_in_lesson_2() -> void:
	var dir: String = Ix.new_dir("lesson2")
	Ix.write_settings(dir)
	var h: Ix.Harness = Ix.open_app(dir)
	var list: LessonsScreen = _open_list(h)
	var index: int = -1
	for i: int in list.lessons.size():
		if list.lessons[i].number == 2:
			index = i
	var player: LessonPlayer = _open_lesson(h, list, index)
	var area: PlayArea = player.area
	var x: int = 40
	# Screens 1 and 2: select r5c5, switch to Cross Out.
	Ix.tap_cell(area, x)
	Ix.click(player.next_button)
	Ix.tap_mode(area, GameSession.Mode.CROSS_OUT)
	Ix.click(player.next_button)
	assert_eq(player.session.mode, GameSession.Mode.CROSS_OUT)
	assert_eq(player.session.selected, x)
	# GDD 15.4: tapping 5 here is wrong; 5 stays open and the step waits.
	Ix.tap_digit(area, 5)
	assert_true(player.is_showing_wrong(), "a note explains")
	assert_eq(player.session.board.mark(x, 5), Board.Mark.OPEN, "5 stays open")
	# The rest of the lesson crosses 2, 3, 4, 6 and 9 by hand.
	var crossed: Array[int] = []
	while player.screen_index < player.lesson.screens.size():
		for step: BoardAction in player.current_screen().steps:
			_do_step(area, step)
		assert_true(player.is_praise_showing(), "screen %d" % (player.screen_index + 1))
		if player.screen_index == 6 or player.is_last_screen():
			crossed.clear()
			for d: int in range(1, 10):
				if player.session.board.mark(x, d) == Board.Mark.CROSSED_HAND:
					crossed.append(d)
		if player.is_last_screen() or not player.is_praise_showing():
			break
		Ix.click(player.next_button)
	assert_true(crossed.has(2) and crossed.has(3) and crossed.has(4) and crossed.has(6) and crossed.has(9),
		"Bart's example: 2, 3, 4, 6 and 9 crossed by hand, got %s" % str(crossed))
	assert_false(crossed.has(5) or crossed.has(8), "an open digit is never crossed in the example")
	Ix.close(h)
