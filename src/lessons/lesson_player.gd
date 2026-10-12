class_name LessonPlayer
extends Control
## Plays one lesson on the real board (docs/ARCHITECTURE.md section 10,
## docs/LESSONS.md sections 2 and 8, GDD 15.4, the look in DESIGN_SYSTEM.md
## 4.8, 4.11 and 7.13). Scene: scenes/lessons/lesson_player.tscn.
##
## Each screen gets a fresh lesson session (LessonScreen.build_session:
## Auto Cross off, no timer, score or hints) on the shared PlayArea. The
## BoardController's gate shows every tap to this player first:
## - a tap that completes a step of the answer goes through to the session;
## - any other tap is stopped, so nothing changes, and the card shows the
##   screen's wrong tap text with the "Not quite" tag and shakes;
## - once the answer is complete, the praise card and Next cover the
##   controls, and every other tap is ignored with no text.
## The player can never fail. Finishing the last screen's answer emits
## finished at once, even if the player leaves before tapping Next; App
## connects it to record_lesson_finished. Close, and Next on the last
## screen, emit closed; App connects it to go_back.
## Owner: lessons-dev.

signal finished(lesson_id: String)             # the last step's answer is done (GDD 15.4)
signal closed()

const Card := preload("res://src/lessons/lesson_card.gd")
const ControlMarks := preload("res://src/lessons/control_marks.gd")
const TouchArea := preload("res://src/lessons/touch_area.gd")

const NEXT_TEXT: String = "Next"
## The body text steps down through these label variations on short
## screens (4.8): 14, 13, then 12 dp.
const STEP_DOWN: Array[StringName] = [ThemeFactory.BODY, ThemeFactory.BODY_SMALL, ThemeFactory.BODY_SMALL_12]
## The text steps down while the board would be under this share of its
## width-bound size (4.8).
const STEP_DOWN_SHARE: float = 0.8
const SHAKE_DP: float = 4.0
const SHAKES: float = 3.0
const PRAISE_RISE: float = 16.0

## The skin for layout and drawing. Null means the Skins autoload's current
## skin, which is what the game uses; tests and captures set one.
var skin: GameSkin = null
## How many lessons there are, for "Lesson 2 of 5". 0 means count the
## lessons LessonLibrary loads.
var lesson_total: int = 0
## The safe area in this control's coordinates. No area means
## ScreenMetrics.safe_rect, or the whole control outside the tree. Captures
## set it to show a notch and a gesture bar.
var safe_rect_override: Rect2 = Rect2()

var lesson: Lesson = null
var screen_index: int = -1
var session: GameSession = null
var goal: LessonGoal = null

var page: Panel = null
var area: PlayArea = null
var card: Card = null
var close_area: TouchArea = null
var marks: ControlMarks = null
var praise_card: PanelContainer = null
var praise_label: Label = null
var next_button: Button = null

var _finished_sent: bool = false
var _card_x: float = 0.0
var _card_height: float = 0.0
var _praise_y: float = 0.0
var _shake: Tween = null
var _praise_in: Tween = null


func _ready() -> void:
	ensure_built()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED, NOTIFICATION_THEME_CHANGED:
			_layout()


## Makes the controls, once. App calls it right after adding the screen; it
## also works outside the tree, for the tests.
func ensure_built() -> void:
	if page != null:
		return
	page = Panel.new()
	page.name = "Page"
	page.theme_type_variation = ThemeFactory.PAGE
	page.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(page)
	area = PlayArea.new()
	area.name = "PlayArea"
	area.skin = skin
	area.header_height = 0.0
	add_child(area)
	area.controller.gate = _gate
	area.controller.action_applied.connect(_on_action_applied)
	area.pad.gui_input.connect(_on_pad_input)
	marks = ControlMarks.new()
	marks.name = "ControlMarks"
	marks.pad = area.pad
	add_child(marks)
	card = Card.new()
	add_child(card)
	close_area = TouchArea.make(Icons.CLOSE, Layout.CLOSE_FACE, "Close") as TouchArea
	close_area.tapped.connect(close)
	add_child(close_area)
	_build_praise()
	_apply_skin()


## Starts lesson at its first screen. Placed digits and crosses never carry
## over from an earlier visit (LESSONS.md section 8, item 5).
func start(new_lesson: Lesson) -> void:
	ensure_built()
	lesson = new_lesson
	_finished_sent = false
	if lesson_total <= 0:
		lesson_total = LessonLibrary.load_all().size()
	if lesson == null or lesson.screens.is_empty():
		return
	show_screen(0)


## Shows screen index of the lesson from its start state.
func show_screen(index: int) -> void:
	if lesson == null or index < 0 or index >= lesson.screens.size():
		return
	screen_index = index
	var screen: LessonScreen = lesson.screens[index]
	session = screen.build_session()
	goal = LessonGoal.create(screen)
	area.setup(session)
	area.view.lesson_marks = screen.marked_cells
	marks.controls = screen.marked_controls
	card.set_header("Lesson %d of %d" % [lesson.number, maxi(lesson_total, lesson.number)],
		"Step %d of %d" % [index + 1, lesson.screens.size()], lesson.title)
	card.set_texts(screen.text, goal.all_wrong_texts())
	_hide_praise()
	_layout()


func current_screen() -> LessonScreen:
	if lesson == null or screen_index < 0 or screen_index >= lesson.screens.size():
		return null
	return lesson.screens[screen_index]


func is_last_screen() -> bool:
	return lesson != null and screen_index == lesson.screens.size() - 1


## Whether the praise and Next show (the screen's answer is complete).
func is_praise_showing() -> bool:
	return praise_card != null and praise_card.visible


## The text the card shows now: the step text or a wrong tap text.
func card_text() -> String:
	return card.body.text if card != null else ""


func is_showing_wrong() -> bool:
	return card != null and card.is_showing_wrong()


## Next: the next screen, or on the last screen, leave the lesson.
func press_next() -> void:
	if not is_praise_showing():
		return
	Motion.press(next_button)
	if is_last_screen():
		closed.emit()
	else:
		show_screen(screen_index + 1)


func close() -> void:
	closed.emit()


# The gate ---------------------------------------------------------------------

## BoardController asks before every tap reaches the session.
func _gate(action: BoardAction) -> bool:
	if goal == null or session == null:
		return false
	match goal.judge(action):
		LessonGoal.Verdict.RIGHT:
			goal.accept(action)
			return true
		LessonGoal.Verdict.WRONG:
			_show_wrong(goal.wrong_text(action, session.board, session.selected))
	return false


## NumberPad drops two taps before they reach the gate: Undo while it is
## off, and the mode button that is already on. In a lesson they are wrong
## taps too (LESSONS.md section 8, items 2 and 4), so the player watches the
## pad's input (its gui_input signal comes before the pad handles the tap)
## and shows their text here. Every other tap goes through the gate.
func _on_pad_input(event: InputEvent) -> void:
	var at: Variant = _press_point(event)
	if at != null:
		dropped_pad_tap(area.pad.control_at(at as Vector2))


## Shows the wrong tap text for control (a NumberPad name) when the pad
## drops a tap on it. Nothing happens for a tap the pad passes on, while
## the pad is locked, or once the answer is complete.
func dropped_pad_tap(control: StringName) -> void:
	if goal == null or session == null or area == null or area.pad.is_locked():
		return
	var pad: NumberPad = area.pad
	var kind: int = -1
	if control == NumberPad.UNDO and not pad.is_undo_enabled():
		kind = BoardAction.Kind.UNDO
	elif (control == NumberPad.PLACE and pad.mode() == GameSession.Mode.PLACE) 			or (control == NumberPad.CROSS_OUT and pad.mode() == GameSession.Mode.CROSS_OUT):
		kind = BoardAction.Kind.MODE
	if kind < 0 or goal.is_complete():
		return
	var action: BoardAction = BoardAction.create(kind)
	_show_wrong(goal.wrong_text(action, session.board, session.selected))


## Where a press lands, as NumberPad reads it: a left mouse press, or a touch
## when touches do not also arrive as mouse presses. Null for anything else.
static func _press_point(event: InputEvent) -> Variant:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		return button.position if button.pressed and button.button_index == MOUSE_BUTTON_LEFT else null
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch != null and touch.pressed 			and not bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", true)):
		return touch.position
	return null


func _on_action_applied(_action: BoardAction, _result: ActionResult) -> void:
	if goal == null:
		return
	if not goal.is_complete():
		card.show_step()
		return
	_show_praise()
	if is_last_screen() and not _finished_sent:
		_finished_sent = true
		finished.emit(lesson.id)


func _show_wrong(text: String) -> void:
	card.show_wrong(text)
	_stop(_shake)
	card.position.x = _card_x
	if not is_inside_tree():
		return
	var base: float = _card_x
	var shake_to: Callable = func(t: float) -> void:
		card.position.x = base + SHAKE_DP * sin(t * TAU * SHAKES)
	_shake = create_tween()
	_shake.tween_method(shake_to, 0.0, 1.0, Motion.LESSON_SHAKE).set_trans(Motion.trans(&"LESSON_SHAKE")).set_ease(Motion.ease_of(&"LESSON_SHAKE"))
	_shake.tween_callback(func() -> void: card.position.x = base)


func _show_praise() -> void:
	card.show_step()
	marks.clear()
	praise_label.text = current_screen().praise
	praise_card.visible = true
	_layout_praise()
	_stop(_praise_in)
	praise_card.modulate.a = 1.0
	if not is_inside_tree():
		return
	praise_card.modulate.a = 0.0
	praise_card.position.y = _praise_y + PRAISE_RISE
	_praise_in = create_tween().set_parallel(true)
	_praise_in.tween_property(praise_card, ^"modulate:a", 1.0, Motion.PRAISE_IN).set_trans(Motion.trans(&"PRAISE_IN")).set_ease(Motion.ease_of(&"PRAISE_IN"))
	_praise_in.tween_property(praise_card, ^"position:y", _praise_y, Motion.PRAISE_IN).set_trans(Motion.trans(&"PRAISE_IN")).set_ease(Motion.ease_of(&"PRAISE_IN"))


func _hide_praise() -> void:
	_stop(_praise_in)
	praise_card.visible = false
	praise_card.modulate.a = 1.0


# Building and layout ----------------------------------------------------------

func _build_praise() -> void:
	praise_card = PanelContainer.new()
	praise_card.name = "PraiseCard"
	praise_card.theme_type_variation = ThemeFactory.CARD
	praise_card.mouse_filter = Control.MOUSE_FILTER_STOP
	praise_card.visible = false
	add_child(praise_card)
	var rows: VBoxContainer = VBoxContainer.new()
	rows.name = "Rows"
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	praise_card.add_child(rows)
	var line: HBoxContainer = HBoxContainer.new()
	line.name = "Line"
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_child(line)
	var check: PanelContainer = PanelContainer.new()
	check.name = "Check"
	check.theme_type_variation = ThemeFactory.STICKER
	check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	check.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	line.add_child(check)
	var icon: IconView = IconView.new()
	icon.icon = Icons.CHECK
	icon.theme_type_variation = ThemeFactory.STICKER_LABEL
	icon.custom_minimum_size = Vector2(Icons.SIZE_BUTTON, Icons.SIZE_BUTTON)
	check.add_child(icon)
	praise_label = Label.new()
	praise_label.name = "Praise"
	praise_label.theme_type_variation = ThemeFactory.BODY
	praise_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Clipping keeps an autowrapped label's own minimum height at one line,
	# so the card takes the height _layout_praise measures for the text.
	praise_label.clip_text = true
	praise_label.custom_minimum_size.x = 1.0
	praise_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	praise_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(praise_label)
	next_button = Button.new()
	next_button.name = "Next"
	next_button.theme_type_variation = ThemeFactory.BUTTON_PRIMARY
	next_button.text = ThemeFactory.display_text(ThemeFactory.BUTTON_PRIMARY, NEXT_TEXT)
	next_button.custom_minimum_size.y = Layout.BUTTON_TALL
	next_button.focus_mode = Control.FOCUS_NONE
	next_button.pressed.connect(press_next)
	rows.add_child(next_button)


func _current_skin() -> GameSkin:
	if skin != null:
		return skin
	if is_inside_tree():
		var service: Node = get_node_or_null(^"/root/Skins")
		if service != null:
			return service.get(&"current") as GameSkin
	return null


func _apply_skin() -> void:
	var current: GameSkin = _current_skin()
	area.skin = skin
	marks.skin = current
	card.apply_skin(current)
	if current == null:
		return
	for box: BoxContainer in [praise_card.get_node(^"Rows") as BoxContainer, praise_card.get_node(^"Rows/Line") as BoxContainer]:
		box.add_theme_constant_override(&"separation", roundi(current.space_s))


## The viewport's safe rect in a screen's own coordinates, measured from
## where the screen comes to rest. App slides a new screen in from x = 24, and
## layout runs in that first frame, so global_origin still holds the slide;
## subtracting position (the slide) keeps the full width. Static so the tests
## can check it without a scene tree.
static func resting_safe_rect(safe: Rect2, global_origin: Vector2, at: Vector2, own_size: Vector2) -> Rect2:
	var local: Rect2 = Rect2(safe.position - (global_origin - at), safe.size)
	return local.intersection(Rect2(Vector2.ZERO, own_size))


func _safe_rect() -> Rect2:
	if safe_rect_override.has_area():
		return safe_rect_override
	var viewport: Viewport = get_viewport() if is_inside_tree() else null
	if viewport == null:
		return Rect2(Vector2.ZERO, size)
	var safe: Rect2 = ScreenMetrics.safe_rect(viewport)
	return resting_safe_rect(safe, get_global_rect().position, position, size)


func _layout() -> void:
	if page == null:
		return
	_apply_skin()
	var current: GameSkin = _current_skin()
	page.position = Vector2.ZERO
	page.size = size
	if current == null:
		return
	# PlayArea takes the whole safe rect and keeps page_margin inside it on
	# every side; a lesson has no header row (4.11).
	var safe: Rect2 = _safe_rect()
	area.position = safe.position
	area.size = safe.size
	_fit_card(current)
	var band: Rect2 = area.band_rect()
	_stop(_shake)
	card.position = area.position + band.position
	card.size = Vector2(band.size.x, _card_height)
	_card_x = card.position.x
	var box: StyleBox = card.get_theme_stylebox(&"panel")
	var pad_right: float = box.get_content_margin(SIDE_RIGHT) if box != null else 0.0
	var pad_top: float = box.get_content_margin(SIDE_TOP) if box != null else 0.0
	var slot_center: Vector2 = card.position + Vector2(band.size.x - pad_right - Layout.LESSON_TOP_ROW * 0.5,
		pad_top + Layout.LESSON_TOP_ROW * 0.5)
	close_area.size = Vector2(Layout.TOUCH_MIN, Layout.TOUCH_MIN)
	close_area.position = slot_center - close_area.size * 0.5
	marks.position = Vector2.ZERO
	marks.size = size
	marks.queue_redraw()
	if praise_card.visible:
		_layout_praise()


## Sizes the card and the band to the text, by the arrangement PlayArea
## picks (DESIGN_SYSTEM.md 4.8 and 4.11). The band is the card plus a
## space_s gap: above the board when stacked, above the pad side by side.
func _fit_card(current: GameSkin) -> void:
	if area.arrangement() == Layout.Arrangement.SIDE:
		_fit_card_side(current)
	else:
		_fit_card_stacked(current)


## Stacked (4.8): the text steps down from 14 to 13 to 12 dp while the board
## would be under 80 percent of its width-bound size; then the title hides
## while the board would be under LESSON_TITLE_MIN_BOARD; and the board never
## goes under LESSON_BOARD_FLOOR: past that the card stops growing and the
## text scrolls. The too small arrangement lays out the same way, clamped.
func _fit_card_stacked(current: GameSkin) -> void:
	var width: float = maxf(0.0, minf(area.size.x - 2.0 * current.page_margin, Layout.COLUMN_MAX))
	var width_bound: float = width - current.line_outer_w - current.shadow_offset
	var gap: float = current.space_s
	var variation: StringName = STEP_DOWN[0]
	var height: float = 0.0
	var board: float = 0.0
	for candidate: StringName in STEP_DOWN:
		variation = candidate
		height = card.configure(width, variation, true)
		board = _board_for(height + gap)
		if board >= STEP_DOWN_SHARE * width_bound:
			break
	var show_title: bool = true
	if board < Layout.LESSON_TITLE_MIN_BOARD:
		show_title = false
		height = card.configure(width, variation, false)
		board = _board_for(height + gap)
	if board < Layout.LESSON_BOARD_FLOOR:
		height = card.configure(width, variation, show_title, height - (Layout.LESSON_BOARD_FLOOR - board))
	_card_height = height
	area.set_band_height(height + gap)


## Side by side (4.11): the card is the side column's width and as tall as
## its text, up to the content height minus the pad at its minimum and the
## space_s gap above the pad. Past that, in order: the text steps down from
## 14 to 13 to 12 dp, the title hides, the text scrolls. The board does not
## depend on the card here.
func _fit_card_side(current: GameSkin) -> void:
	var gap: float = current.space_s
	area.set_band_height(0.0)
	var width: float = area.band_rect().size.x
	var content_h: float = maxf(0.0, area.size.y - 2.0 * current.page_margin)
	var pad_min: float = 3.0 * Layout.KEY_MIN + 2.0 * gap
	var max_height: float = maxf(0.0, content_h - pad_min - gap)
	var variation: StringName = STEP_DOWN[0]
	var height: float = 0.0
	for candidate: StringName in STEP_DOWN:
		variation = candidate
		height = card.configure(width, variation, true)
		if height <= max_height:
			break
	if height > max_height:
		height = card.configure(width, variation, false)
	if height > max_height:
		height = card.configure(width, variation, false, max_height)
	_card_height = height
	area.set_band_height(height + gap)


func _board_for(band_height: float) -> float:
	area.set_band_height(band_height)
	return area.view.board_square().size.x


## The praise card covers the pad's keys; it grows upward when its text
## needs more room than the keys take.
func _layout_praise() -> void:
	var current: GameSkin = _current_skin()
	var to_local: Transform2D = get_global_transform().affine_inverse()
	var keys: Rect2 = to_local * area.pad.control_rect_global(&"pad:1").merge(area.pad.control_rect_global(&"erase"))
	if current != null:
		keys.size.x += current.shadow_offset
	var box: StyleBox = praise_card.get_theme_stylebox(&"panel")
	var pad_x: float = box.get_content_margin(SIDE_LEFT) + box.get_content_margin(SIDE_RIGHT) if box != null else 0.0
	var pad_y: float = box.get_content_margin(SIDE_TOP) + box.get_content_margin(SIDE_BOTTOM) if box != null else 0.0
	var gap: float = current.space_s if current != null else 0.0
	var check_w: float = (praise_card.get_node(^"Rows/Line/Check") as Control).get_combined_minimum_size().x
	var text_w: float = keys.size.x - pad_x - check_w - gap
	# The praise steps down with the card's text, so on short screens it
	# does not grow up over the board (7.13: the board stays in view).
	praise_label.theme_type_variation = card.body.theme_type_variation
	var text_h: float = Card.text_height(praise_label, praise_label.text, text_w, praise_label.theme_type_variation)
	praise_label.custom_minimum_size = Vector2(1.0, text_h)
	var needed: float = pad_y + text_h + gap + Layout.BUTTON_TALL
	var height: float = maxf(keys.size.y, needed)
	praise_card.size = Vector2(keys.size.x, height)
	praise_card.position = Vector2(keys.position.x, keys.end.y - height)
	_praise_y = praise_card.position.y


static func _stop(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
