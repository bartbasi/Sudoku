extends "res://tests/unit_test.gd"
## LessonsScreen: every lesson in order, finished marks from the lesson
## progress, a row opens its lesson through App.goto, Back through App.go_back.

const Lx := preload("res://tests/lessons/lesson_fixtures.gd")


class FakeApp extends Node:
	var lessons: LessonProgress = LessonProgress.new()
	var opened: Array = []
	var backs: int = 0

	func goto(screen: StringName, payload: Variant = null) -> void:
		opened.append([screen, payload])

	func go_back() -> void:
		backs += 1


var screen: LessonsScreen
var app: FakeApp


func _build() -> void:
	var skin: GameSkin = Lx.light()
	app = FakeApp.new()
	screen = LessonsScreen.new()
	screen.app = app
	screen.skin = skin
	screen.theme = ThemeFactory.build(skin)
	screen.size = Vector2(360.0, 800.0)
	Lx.root().add_child(screen)
	screen.ensure_built()
	screen.notification(Control.NOTIFICATION_RESIZED)


func _free() -> void:
	screen.free()
	app.free()


func test_lists_every_lesson_in_order() -> void:
	_build()
	assert_eq(screen.rows.size(), 5)
	for i: int in screen.lessons.size():
		assert_eq(screen.lessons[i].number, i + 1)
		var title: Label = screen.rows[i].get_node(^"Line/Words/Title") as Label
		assert_eq(title.text, screen.lessons[i].title.to_upper())
		var subtitle: Label = screen.rows[i].get_node(^"Line/Words/Subtitle") as Label
		assert_eq(subtitle.text, screen.lessons[i].subtitle)
	_free()


func test_finished_lessons_show_a_check() -> void:
	_build()
	for i: int in 5:
		assert_false(screen.is_marked_finished(i))
	app.lessons.mark_finished("lesson_02")
	screen.on_shown()
	assert_true(screen.is_marked_finished(1))
	assert_false(screen.is_marked_finished(0))
	_free()


func test_every_lesson_opens_from_the_start() -> void:
	_build()
	for i: int in 5:
		screen.open_lesson(i)
	assert_eq(app.opened.size(), 5, "no lesson is locked")
	assert_eq(app.opened[3][0], &"lesson")
	assert_eq((app.opened[3][1] as Lesson).id, "lesson_04")
	screen.rows[0].pressed.emit()
	assert_eq((app.opened[5][1] as Lesson).id, "lesson_01")
	_free()


func test_back_goes_back() -> void:
	_build()
	screen.back_area.tap()
	assert_eq(app.backs, 1)
	_free()


func test_works_without_an_app() -> void:
	var lone: LessonsScreen = LessonsScreen.new()
	lone.ensure_built()
	lone.open_lesson(0)
	lone.refresh()
	assert_eq(lone.rows.size(), 5)
	assert_false(lone.is_marked_finished(0))
	lone.free()
