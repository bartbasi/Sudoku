class_name PlayHud
extends HBoxContainer
## The play screen's header row (DESIGN_SYSTEM.md 7.5): Hint at the left,
## time and score centered, Pause at the right. Hint is visibly disabled
## whenever the session cannot sell a hint (GDD 10.4).
## Owner: ui-systems-dev.

signal hint_pressed()
signal pause_pressed()

## U+2212, the real minus sign, which the built-in font has.
const MINUS: String = "−"

var hint_button: Button = null
var hint_touch: Control = null
var time_value: Label = null
var score_value: Label = null
var score_block: PanelContainer = null
var pause_touch: Control = null
var pause_button: Button = null

var _session: GameSession = null
var _shown_seconds: int = -1
var _shown_score: int = -1


func setup(skin: GameSkin) -> void:
	add_theme_constant_override(&"separation", roundi(skin.space_s))
	custom_minimum_size.y = Layout.HEADER_ROW
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	hint_button = UiKit.button(ThemeFactory.HINT_BUTTON, "", Layout.ICON_FACE, Icons.HINT)
	hint_button.name = "Hint"
	hint_button.custom_minimum_size.x = Layout.HINT_FACE_W
	hint_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint_button.pressed.connect(func() -> void: hint_pressed.emit())
	var touch: Control = UiKit.TouchTarget.new()
	touch.call(&"set_button", hint_button)
	touch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hint_touch = touch
	add_child(touch)

	var guard_left: Control = Control.new()
	guard_left.custom_minimum_size.x = Layout.HEADER_GUARD - skin.space_s
	guard_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guard_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(guard_left)

	var time_block: PanelContainer = _block(ThemeFactory.HUD_TIME, ThemeFactory.HUD_CAPTION, "Time", ThemeFactory.HUD_VALUE, Layout.TIME_MIN_W)
	time_block.name = "Time"
	time_value = time_block.get_meta(&"value") as Label
	add_child(time_block)
	score_block = _block(ThemeFactory.HUD_SCORE, ThemeFactory.SCORE_CAPTION, "Score", ThemeFactory.SCORE_VALUE, Layout.SCORE_MIN_W)
	score_block.name = "Score"
	score_value = score_block.get_meta(&"value") as Label
	add_child(score_block)

	var guard_right: Control = Control.new()
	guard_right.custom_minimum_size.x = Layout.HEADER_GUARD - skin.space_s
	guard_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guard_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(guard_right)

	var pause: Control = UiKit.icon_button(Icons.PAUSE)
	pause.name = "Pause"
	pause.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pause_touch = pause
	pause_button = pause.get(&"button") as Button
	pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	add_child(pause)


func bind(session: GameSession) -> void:
	_session = session
	_shown_seconds = -1
	_shown_score = -1
	refresh()


## Shows the session as it is now: time, score, and whether Hint can be used.
func refresh() -> void:
	if _session == null:
		return
	update_time()
	var score: int = _session.score()
	if score != _shown_score:
		_shown_score = score
		score_value.text = str(score)
	hint_button.text = ThemeFactory.display_text(ThemeFactory.HINT_BUTTON, "Hint\n%s%d" % [MINUS, _session.hint_cost()])
	hint_button.disabled = not _session.can_buy_hint()


## Updates the time label when the whole seconds change.
func update_time() -> void:
	if _session == null:
		return
	var seconds: int = _session.elapsed_seconds()
	if seconds != _shown_seconds:
		_shown_seconds = seconds
		time_value.text = UiKit.format_time(seconds)


## After a hint: the score counts down to its new value and its block does
## a press (Motion SCORE_CHANGE).
func animate_score(from: int, to: int) -> void:
	_shown_score = to
	if not is_inside_tree():
		score_value.text = str(to)
		return
	var tween: Tween = score_value.create_tween()
	tween.tween_method(func(value: float) -> void: score_value.text = str(roundi(value)), float(from), float(to), Motion.SCORE_CHANGE).set_trans(Motion.trans(&"SCORE_CHANGE")).set_ease(Motion.ease_of(&"SCORE_CHANGE"))
	Motion.press(score_block)


## A caption over a value in a HUD block: a Layout.ICON_FACE tall face.
func _block(panel_style: StringName, caption_style: StringName, caption: String, value_style: StringName, min_width: float) -> PanelContainer:
	var block: PanelContainer = UiKit.panel(panel_style)
	# A 40 dp face with the two lines centered in it (7.5).
	block.custom_minimum_size = Vector2(min_width, Layout.ICON_FACE)
	block.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var lines: VBoxContainer = UiKit.vbox(0.0)
	lines.alignment = BoxContainer.ALIGNMENT_CENTER
	block.add_child(lines)
	var top: Label = UiKit.label(caption_style, caption)
	lines.add_child(top)
	var value: Label = UiKit.label(value_style, "")
	lines.add_child(value)
	block.set_meta(&"value", value)
	return block
