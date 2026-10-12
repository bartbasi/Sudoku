class_name LessonsScreen
extends Control
## The lessons list (docs/LESSONS.md section 3, DESIGN_SYSTEM.md 7.12): every
## lesson in order with its number, title and subtitle, and a check badge on
## each one the player has finished. Every lesson is open from the start;
## tapping a row opens it. Scene: scenes/lessons/lessons_screen.tscn.
##
## App sets app before the screen enters the tree (App.goto). The screen
## reaches App only at its edges: app.lessons for the finished marks,
## app.goto(&"lesson", lesson) to open a lesson and app.go_back() for Back.
## Without an App it still builds and lists the lessons.
## Owner: lessons-dev.

const TouchArea := preload("res://src/lessons/touch_area.gd")
const Card := preload("res://src/lessons/lesson_card.gd")

const TITLE_TEXT: String = "Lessons"
const LESSON_SCREEN: StringName = &"lesson"
## Row height and the number sticker's side (DESIGN_SYSTEM.md 7.12).
const ROW_HEIGHT: float = 72.0
const NUMBER_SIDE: float = 36.0

## The App autoload node, set by App.goto. Null in tests that set none.
var app: Node = null
## Lesson progress to show. Null means app.lessons.
var progress: LessonProgress = null
## The skin for spacing. Null means the Skins autoload's current skin.
var skin: GameSkin = null
## As LessonPlayer.safe_rect_override.
var safe_rect_override: Rect2 = Rect2()

var lessons: Array[Lesson] = []
var rows: Array[Button] = []
var page: Panel = null
var back_area: TouchArea = null
var title_label: Label = null
var scroll: ScrollContainer = null

var _list: VBoxContainer = null
var _badges: Array[Control] = []


func _ready() -> void:
	ensure_built()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED, NOTIFICATION_THEME_CHANGED:
			_layout()


## App calls this before the screen enters the tree. The list needs no payload.
func open(_payload: Variant) -> void:
	pass


## App calls this when the screen shows again, for example after a lesson.
func on_shown() -> void:
	refresh()


func handle_back() -> bool:
	return false


func ensure_built() -> void:
	if page != null:
		return
	page = Panel.new()
	page.name = "Page"
	page.theme_type_variation = ThemeFactory.PAGE
	page.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(page)
	back_area = TouchArea.make(Icons.BACK, Layout.ICON_FACE, "Back") as TouchArea
	back_area.tapped.connect(_on_back)
	add_child(back_area)
	title_label = Label.new()
	title_label.name = "Title"
	title_label.theme_type_variation = ThemeFactory.TITLE
	title_label.text = ThemeFactory.display_text(ThemeFactory.TITLE, TITLE_TEXT)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_label)
	scroll = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(_list)
	lessons = LessonLibrary.load_all()
	for lesson: Lesson in lessons:
		_add_row(lesson)
	refresh()
	_layout()


## Shows the check badge on every finished lesson.
func refresh() -> void:
	var source: LessonProgress = _progress()
	for i: int in lessons.size():
		_badges[i].visible = source != null and source.is_finished(lessons[i].id)
	_layout()


## Opens a lesson, as tapping its row does.
func open_lesson(index: int) -> void:
	if index < 0 or index >= lessons.size():
		return
	Motion.press(rows[index])
	if app != null and app.has_method(&"goto"):
		app.call(&"goto", LESSON_SCREEN, lessons[index])


func is_marked_finished(index: int) -> bool:
	return index >= 0 and index < _badges.size() and _badges[index].visible


func _on_back() -> void:
	if app != null and app.has_method(&"go_back"):
		app.call(&"go_back")


func _progress() -> LessonProgress:
	if progress != null:
		return progress
	if app != null:
		return app.get(&"lessons") as LessonProgress
	return null


func _add_row(lesson: Lesson) -> void:
	var index: int = rows.size()
	var row: Button = Button.new()
	row.name = "Lesson%d" % lesson.number
	row.theme_type_variation = ThemeFactory.LIST_BUTTON
	row.custom_minimum_size.y = ROW_HEIGHT
	row.focus_mode = Control.FOCUS_NONE
	row.pressed.connect(func() -> void: open_lesson(index))
	_list.add_child(row)
	rows.append(row)

	var line: HBoxContainer = HBoxContainer.new()
	line.name = "Line"
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_child(line)
	var number: PanelContainer = PanelContainer.new()
	number.name = "Number"
	number.theme_type_variation = ThemeFactory.STICKER
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.custom_minimum_size = Vector2(NUMBER_SIDE, NUMBER_SIDE)
	number.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(number)
	var digits: Label = _label("Digits", ThemeFactory.STICKER_LABEL, str(lesson.number))
	digits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	digits.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.add_child(digits)
	var words: VBoxContainer = VBoxContainer.new()
	words.name = "Words"
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	words.add_theme_constant_override(&"separation", 0)
	line.add_child(words)
	var title: Label = _label("Title", ThemeFactory.HEADING, lesson.title)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.custom_minimum_size.x = 1.0
	words.add_child(title)
	# The subtitle wraps rather than being cut off; _layout measures it and
	# grows the row when it needs a second line. Clipping keeps the label's
	# own minimum height at one line until then.
	var subtitle: Label = _label("Subtitle", ThemeFactory.BODY_MUTED, lesson.subtitle)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.clip_text = true
	subtitle.custom_minimum_size.x = 1.0
	words.add_child(subtitle)
	var badge: PanelContainer = PanelContainer.new()
	badge.name = "Finished"
	badge.theme_type_variation = ThemeFactory.STICKER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.visible = false
	var icon: IconView = IconView.new()
	icon.icon = Icons.CHECK
	icon.theme_type_variation = ThemeFactory.STICKER_LABEL
	icon.custom_minimum_size = Vector2(Icons.SIZE_BUTTON, Icons.SIZE_BUTTON)
	badge.add_child(icon)
	line.add_child(badge)
	_badges.append(badge)


func _label(node_name: String, variation: StringName, text: String) -> Label:
	var label: Label = Label.new()
	label.name = node_name
	label.theme_type_variation = variation
	label.text = ThemeFactory.display_text(variation, text)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _current_skin() -> GameSkin:
	if skin != null:
		return skin
	if is_inside_tree():
		var service: Node = get_node_or_null(^"/root/Skins")
		if service != null:
			return service.get(&"current") as GameSkin
	return null


func _safe_rect() -> Rect2:
	if safe_rect_override.has_area():
		return safe_rect_override
	var viewport: Viewport = get_viewport() if is_inside_tree() else null
	if viewport == null:
		return Rect2(Vector2.ZERO, size)
	var safe: Rect2 = ScreenMetrics.safe_rect(viewport)
	var local: Rect2 = Rect2(safe.position - get_global_rect().position, safe.size)
	return local.intersection(Rect2(Vector2.ZERO, size))


## Title row (HEADER_ROW) at the top of the safe area inset by page_margin,
## then the list under it, space_s below, in a column at most COLUMN_MAX
## wide. Rows are 72 dp with 12 dp between them.
func _layout() -> void:
	if page == null:
		return
	page.position = Vector2.ZERO
	page.size = size
	var current: GameSkin = _current_skin()
	if current == null:
		return
	var safe: Rect2 = _safe_rect().grow(-current.page_margin)
	var width: float = maxf(0.0, minf(safe.size.x, Layout.COLUMN_MAX))
	var left: float = safe.position.x + (safe.size.x - width) * 0.5
	back_area.size = Vector2(Layout.TOUCH_MIN, Layout.HEADER_ROW)
	back_area.position = Vector2(left, safe.position.y)
	title_label.position = Vector2(left + Layout.TOUCH_MIN + current.space_s, safe.position.y)
	title_label.size = Vector2(maxf(0.0, width - Layout.TOUCH_MIN - current.space_s), Layout.HEADER_ROW)
	var list_top: float = safe.position.y + Layout.HEADER_ROW + current.space_s
	scroll.position = Vector2(left, list_top)
	# Room on the right and below for the rows' shadows.
	scroll.size = Vector2(width, maxf(0.0, safe.end.y - list_top))
	_list.add_theme_constant_override(&"separation", roundi(current.space_m))
	for i: int in rows.size():
		_layout_row(rows[i], _badges[i], width, current)


## A row is ROW_HEIGHT tall, or taller when its subtitle needs two lines.
func _layout_row(row: Button, badge: Control, width: float, current: GameSkin) -> void:
	var line: HBoxContainer = row.get_node(^"Line") as HBoxContainer
	var gap: float = current.space_m
	line.add_theme_constant_override(&"separation", roundi(gap))
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.offset_left = gap
	line.offset_right = -gap - current.shadow_offset
	line.offset_bottom = -current.shadow_offset
	var words_w: float = width - 2.0 * gap - current.shadow_offset - NUMBER_SIDE - gap
	if badge.visible:
		words_w -= badge.get_combined_minimum_size().x + gap
	var title: Label = row.get_node(^"Line/Words/Title") as Label
	var subtitle: Label = row.get_node(^"Line/Words/Subtitle") as Label
	var sub_h: float = Card.text_height(subtitle, subtitle.text, words_w)
	subtitle.custom_minimum_size.y = sub_h
	var needed: float = title.get_combined_minimum_size().y + sub_h + 2.0 * gap + current.shadow_offset
	row.custom_minimum_size.y = maxf(ROW_HEIGHT, ceilf(needed))
