extends "res://tests/unit_test.gd"
## LessonPlayer and LessonsScreen on the window shapes of DESIGN_SYSTEM.md
## 4.11 (foldables and split screen) and the screens of 4.10: every lesson
## screen lays out inside the safe rect with nothing overlapping, the board
## keeps its floor, the card text fits or scrolls by the rules of 4.8 and
## 4.11, the praise card and the control rings follow the pad, and a resize
## in the middle of a lesson keeps the step and the board.

const Lx := preload("res://tests/lessons/lesson_fixtures.gd")
const Model := preload("res://tools/design/layout_model.gd")

## Rects may touch; anything closer than this counts as an overlap.
const SLACK: float = 0.5

var player: LessonPlayer = null


## A window shape: label, size and safe rect, in dp.
class Shape extends RefCounted:
	var label: String
	var size: Vector2
	var safe: Rect2
	var expected: int = -1


func _window(label: String, w: float, h: float, top: float, bottom: float, expected: int = -1) -> Shape:
	var out: Shape = Shape.new()
	out.label = label
	out.size = Vector2(w, h)
	out.safe = Rect2(0.0, top, w, h - top - bottom)
	out.expected = expected
	return out


## The 4.11 windows the game supports and the 4.10 screens, from the
## design model (tools/design/layout_model.gd).
func _windows() -> Array[Shape]:
	var out: Array[Shape] = []
	var all: Array = Model.screens()
	all.append_array(Model.supported_windows(Lx.light()))
	for s: Model.Screen in all:
		out.append(_window(s.label, s.w, s.h, s.top, s.bottom, s.expected))
	return out


func _build(window: Shape) -> void:
	var skin: GameSkin = Lx.light()
	player = LessonPlayer.new()
	player.skin = skin
	player.theme = ThemeFactory.build(skin)
	Lx.root().add_child(player)
	player.ensure_built()
	_resize(window)


## Gives the player a new window, as App does when the window changes.
func _resize(window: Shape) -> void:
	player.size = window.size
	player.safe_rect_override = window.safe
	# The runner keeps nodes outside the tree, where Godot sends no RESIZED.
	player.notification(Control.NOTIFICATION_RESIZED)


func _free() -> void:
	if player != null and is_instance_valid(player):
		player.free()
	player = null


## A rect in the player's coordinates.
func _local(global: Rect2) -> Rect2:
	return player.get_global_transform().affine_inverse() * global


func _inside(inner: Rect2, outer: Rect2) -> bool:
	return outer.grow(SLACK).encloses(inner)


func _overlap(a: Rect2, b: Rect2) -> bool:
	return a.grow(-SLACK).intersects(b.grow(-SLACK))


## The pad's key faces, with their shadow, in the player's coordinates.
func _keys() -> Rect2:
	var pad: NumberPad = player.area.pad
	var keys: Rect2 = _local(pad.control_rect_global(&"pad:1").merge(pad.control_rect_global(&"erase")))
	keys.size += Vector2(player.skin.shadow_offset, player.skin.shadow_offset)
	return keys


## The lesson card with its shadow.
func _card() -> Rect2:
	var rect: Rect2 = player.card.get_rect()
	rect.size += Vector2(player.skin.shadow_offset, player.skin.shadow_offset)
	return rect


## Checks one laid out screen. where names it in messages.
func _check_screen(window: Shape, where: String) -> void:
	var skin: GameSkin = player.skin
	var arrangement: int = player.area.arrangement()
	if window.expected >= 0:
		assert_eq(arrangement, window.expected, "%s: the arrangement of 4.11" % where)
	var safe: Rect2 = window.safe
	var board: Rect2 = player.area.view.get_rect()
	board.position += player.area.position
	var side: float = player.area.view.board_square().size.x
	var card: Rect2 = _card()
	var keys: Rect2 = _keys()
	var close: Rect2 = player.close_area.get_rect()
	for pair: Array in [["card", card], ["board", board], ["keys", keys], ["close", close]]:
		assert_true(_inside(pair[1] as Rect2, safe), "%s: the %s %s is inside the safe rect %s" % [where, pair[0], pair[1], safe])
	assert_false(_overlap(card, board), "%s: the card %s and the board %s do not overlap" % [where, card, board])
	assert_false(_overlap(card, keys), "%s: the card %s and the keys %s do not overlap" % [where, card, keys])
	assert_false(_overlap(board, keys), "%s: the board %s and the keys %s do not overlap" % [where, board, keys])
	assert_true(_inside(close.grow(-(Layout.TOUCH_MIN - Layout.CLOSE_FACE) * 0.5), card),
		"%s: the close button's face is on the card" % where)
	var content_h: float = safe.size.y - 2.0 * skin.page_margin
	if arrangement == Layout.Arrangement.SIDE:
		var content: Rect2 = Rect2(Vector2.ZERO, safe.size - 2.0 * Vector2(skin.page_margin, skin.page_margin))
		assert_true(side >= Layout.side_board(content, skin) - SLACK, "%s: the board %.1f is the play board" % [where, side])
		assert_true(side >= Layout.BOARD_MIN - SLACK, "%s: board %.1f at least BOARD_MIN" % [where, side])
		assert_true(card.position.x > board.end.x, "%s: the card sits in the side column" % where)
		assert_true(card.end.y <= keys.position.y + SLACK, "%s: the card sits above the pad" % where)
		var max_card: float = content_h - (3.0 * Layout.KEY_MIN + 2.0 * skin.space_s) - skin.space_s
		assert_true(player.card.size.y <= max_card + SLACK, "%s: the card %.1f leaves the pad its minimum (max %.1f)" % [where, player.card.size.y, max_card])
		if player.card.is_capped():
			assert_false(player.card.title_label.visible, "%s: the title hides before the text scrolls" % where)
			assert_eq(player.card.body.theme_type_variation, ThemeFactory.BODY_SMALL_12, "%s: 12 dp before the text scrolls" % where)
	else:
		assert_true(side >= Layout.LESSON_BOARD_FLOOR - SLACK, "%s: board %.1f at least the floor" % [where, side])
		assert_true(card.end.y <= board.position.y + SLACK, "%s: the card sits above the board" % where)
		if player.card.is_capped():
			assert_true(side <= Layout.LESSON_BOARD_FLOOR + 1.0, "%s: the text scrolls only at the floor (board %.1f)" % [where, side])
	if not player.card.is_capped():
		assert_true(player.card.get_combined_minimum_size().y <= player.card.size.y + SLACK,
			"%s: the card text fits (needs %.1f, has %.1f)" % [where, player.card.get_combined_minimum_size().y, player.card.size.y])
	assert_true(LessonPlayer.STEP_DOWN.has(player.card.body.theme_type_variation), "%s: a step down style" % where)
	for control: StringName in player.marks.controls:
		var face: Rect2 = _local(player.area.pad.control_rect_global(control))
		assert_true(face.has_area() and _inside(face, keys), "%s: the ring for %s is on the pad" % [where, control])


func test_every_lesson_screen_lays_out_at_every_window() -> void:
	var lessons: Array[Lesson] = LessonLibrary.load_all()
	for window: Shape in _windows():
		_build(window)
		for lesson: Lesson in lessons:
			player.start(lesson)
			for i: int in lesson.screens.size():
				player.show_screen(i)
				_check_screen(window, "%s, %s screen %d" % [window.label, lesson.id, i + 1])
		_free()


func test_the_praise_card_covers_the_pad_at_every_window() -> void:
	var lessons: Array[Lesson] = LessonLibrary.load_all()
	for window: Shape in _windows():
		_build(window)
		for lesson: Lesson in lessons:
			player.start(lesson)
			for i: int in lesson.screens.size():
				player.show_screen(i)
				for step: BoardAction in lesson.screens[i].steps:
					player.area.controller.handle(step)
				var where: String = "%s, %s screen %d" % [window.label, lesson.id, i + 1]
				assert_true(player.is_praise_showing(), "%s: the praise shows" % where)
				player.notification(Control.NOTIFICATION_RESIZED)
				var praise: Rect2 = player.praise_card.get_rect()
				var board: Rect2 = player.area.view.get_rect()
				board.position += player.area.position
				# The praise card covers the key faces and their shadow at the
				# right; its own shadow covers theirs below.
				var faces: Rect2 = _keys()
				faces.size.y -= player.skin.shadow_offset
				assert_true(praise.grow(SLACK).encloses(faces), "%s: the praise %s covers the keys %s" % [where, praise, faces])
				praise.size += Vector2(player.skin.shadow_offset, player.skin.shadow_offset)
				assert_true(_inside(praise, window.safe), "%s: the praise %s is inside the safe rect" % [where, praise])
				assert_false(_overlap(praise, board), "%s: the praise %s does not cover the board %s" % [where, praise, board])
		_free()


func test_the_four_windows_of_4_11_pick_their_arrangement() -> void:
	var cases: Array[Shape] = [
		_window("cover 344 x 882", 344.0, 882.0, 32.0, 24.0, Layout.Arrangement.STACKED),
		_window("inner 690 x 829", 690.0, 829.0, 32.0, 24.0, Layout.Arrangement.STACKED),
		_window("inner half 345 x 829", 345.0, 829.0, 32.0, 24.0, Layout.Arrangement.STACKED),
		_window("inner top half 690 x 400", 690.0, 400.0, 32.0, 0.0, Layout.Arrangement.SIDE),
	]
	for window: Shape in cases:
		_build(window)
		player.start(Lx.lesson(2))
		assert_eq(player.area.arrangement(), window.expected, window.label)
		# PlayArea gets the whole safe rect and adds page_margin itself.
		assert_eq(player.area.get_rect(), window.safe, "%s: PlayArea is the safe rect" % window.label)
		var board: Rect2 = player.area.view.get_rect()
		assert_true(board.position.y >= player.skin.page_margin - SLACK, "%s: page_margin above the content" % window.label)
		_free()
	# The board starts page_margin below the safe top when the card is at the top.
	_build(cases[0])
	player.start(Lx.lesson(2))
	assert_true(player.card.position.y >= cases[0].safe.position.y + player.skin.page_margin - SLACK, "one page_margin above the card")
	_free()


func test_side_by_side_card_is_the_side_column() -> void:
	var window: Shape = _window("inner top half 690 x 400", 690.0, 400.0, 32.0, 0.0)
	_build(window)
	for lesson: Lesson in LessonLibrary.load_all():
		player.start(lesson)
		for i: int in lesson.screens.size():
			player.show_screen(i)
			var where: String = "%s screen %d" % [lesson.id, i + 1]
			assert_eq(player.area.arrangement(), Layout.Arrangement.SIDE, where)
			assert_eq(player.card.size.x, player.area.band_rect().size.x, "%s: the card is the band's width" % where)
			# 4.11: at the inner top half every lesson keeps its title, and no text scrolls.
			assert_true(player.card.title_label.visible, "%s: the title shows" % where)
			assert_false(player.card.is_capped(), "%s: the text does not scroll" % where)
	_free()


## The state a resize must keep: the screen, the board, the selection, the
## mode, the answer's progress and what the card and praise show.
func _state() -> Array:
	var s: GameSession = player.session
	return [player.screen_index, s.board.digits.duplicate(), s.board.marks.duplicate(), s.selected, s.mode,
		player.goal.done_count(), player.card_text(), player.is_showing_wrong(), player.is_praise_showing()]


func test_a_resize_mid_lesson_keeps_the_step_and_the_board() -> void:
	var cover: Shape = _window("cover 344 x 882", 344.0, 882.0, 32.0, 24.0)
	var too_small: Shape = _window("cover top half 344 x 430", 344.0, 430.0, 32.0, 0.0)
	var side: Shape = _window("inner top half 690 x 400", 690.0, 400.0, 32.0, 0.0)
	var tiny: Shape = _window("inner bottom third 690 x 276", 690.0, 276.0, 0.0, 24.0)
	_build(cover)
	var lesson: Lesson = LessonLibrary.parse(JSON.stringify(Lx.small_lesson()))
	player.start(lesson)
	player.area.controller.handle(BoardAction.create(BoardAction.Kind.CELL, 40))
	player.press_next()
	# Screen 2 is a sequence: one tap done, then a wrong tap.
	player.area.controller.handle(BoardAction.create(BoardAction.Kind.PAD, -1, 9))
	player.area.controller.handle(BoardAction.create(BoardAction.Kind.PAD, -1, 7))
	assert_true(player.is_showing_wrong())
	var before: Array = _state()
	var session: GameSession = player.session
	for window: Shape in [too_small, cover, side, tiny, side, cover]:
		_resize(window)
		assert_eq(_state(), before, "a resize to %s keeps the step" % window.label)
		assert_eq(player.session, session, "a resize to %s keeps the session" % window.label)
	assert_eq(player.area.arrangement(), Layout.Arrangement.STACKED)
	_resize(too_small)
	assert_eq(player.area.arrangement(), Layout.Arrangement.TOO_SMALL, "344 x 430 is too small")
	assert_eq(_state(), before)
	# The answer still goes on from where it was.
	_resize(side)
	player.area.controller.handle(BoardAction.create(BoardAction.Kind.PAD, -1, 3))
	player.area.controller.handle(BoardAction.create(BoardAction.Kind.PAD, -1, 7))
	assert_true(player.is_praise_showing())
	var done: Array = _state()
	_resize(too_small)
	_resize(cover)
	assert_eq(_state(), done, "the praise stays through a resize")
	_free()


func test_the_lessons_list_scrolls_at_every_window() -> void:
	var skin: GameSkin = Lx.light()
	for window: Shape in _windows():
		var list: LessonsScreen = LessonsScreen.new()
		list.skin = skin
		list.theme = ThemeFactory.build(skin)
		Lx.root().add_child(list)
		list.ensure_built()
		list.size = window.size
		list.safe_rect_override = window.safe
		list.notification(Control.NOTIFICATION_RESIZED)
		var where: String = window.label
		for pair: Array in [["back", list.back_area.get_rect()], ["title", list.title_label.get_rect()], ["list", list.scroll.get_rect()]]:
			assert_true(_inside(pair[1] as Rect2, window.safe), "%s: the %s is inside the safe rect" % [where, pair[0]])
		assert_true(list.scroll.size.x <= Layout.COLUMN_MAX + SLACK, "%s: one column" % where)
		assert_true(list.scroll.size.y > 0.0, "%s: the list has room" % where)
		assert_ne(list.scroll.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED, "%s: the list scrolls" % where)
		assert_false(_overlap(list.back_area.get_rect(), list.scroll.get_rect()), "%s: the title row stays above the list" % where)
		list.free()
