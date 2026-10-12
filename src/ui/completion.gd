extends UiScreen
## The completion screen (GDD 12, DESIGN_SYSTEM.md 7.9). Shows the
## CompletionResult it is opened with: level, final time, points after
## hints, time bonus, final score, hints used, and NEW BEST TIME or NEW BEST
## SCORE when the result says so. Play again starts a new puzzle at the same
## level with no dialog; Menu and Back go to the main menu. The buttons work
## from the first frame.
## Owner: ui-systems-dev.

var result: CompletionResult = null
var time_value: Label = null
var points_value: Label = null
var bonus_value: Label = null
var score_value: Label = null
var hints_value: Label = null
var new_best_time: Control = null
var new_best_score: Control = null
var play_again_button: Button = null
var menu_button: Button = null


func open(new_payload: Variant) -> void:
	payload = new_payload
	result = new_payload as CompletionResult


func build() -> void:
	if result == null:
		result = CompletionResult.new()
	var s: GameSkin = skin()
	var stack: VBoxContainer = UiKit.vbox(s.space_m)
	column.add_child(stack)

	var burst: Starburst = Starburst.new()
	burst.name = "Starburst"
	stack.add_child(burst)
	var solved_box: CenterContainer = CenterContainer.new()
	solved_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	solved_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.add_child(solved_box)
	var solved: Control = UiKit.sticker(ThemeFactory.CELEBRATE_STICKER, ThemeFactory.CELEBRATE_DISPLAY, "Solved!", s.celebrate_tilt)
	solved.name = "Solved"
	solved_box.add_child(solved)

	var level_box: CenterContainer = CenterContainer.new()
	level_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_box.add_child(UiKit.sticker(ThemeFactory.STICKER, ThemeFactory.STICKER_LABEL, Levels.name_of(result.level), s.sticker_tilt))
	stack.add_child(level_box)

	var receipt: PanelContainer = UiKit.panel(ThemeFactory.CARD)
	receipt.name = "Receipt"
	stack.add_child(receipt)
	var rows: VBoxContainer = UiKit.vbox(s.space_s)
	receipt.add_child(rows)
	time_value = _line(rows, ThemeFactory.CAPTION, "Time", ThemeFactory.VALUE, UiKit.format_time(result.seconds))
	new_best_time = _new_best(rows, s, "New best time", Stats.NEW_BEST_TIME)
	points_value = _line(rows, ThemeFactory.CAPTION, "Points after hints", ThemeFactory.VALUE, str(result.points_after_hints))
	bonus_value = _line(rows, ThemeFactory.CAPTION, "Time bonus", ThemeFactory.VALUE, str(result.time_bonus))
	var rule: HSeparator = HSeparator.new()
	rule.theme_type_variation = ThemeFactory.RULE
	rows.add_child(rule)
	score_value = _line(rows, ThemeFactory.TITLE, "Score", ThemeFactory.DISPLAY_ACCENT, str(result.final_score))
	new_best_score = _new_best(rows, s, "New best score", Stats.NEW_BEST_SCORE)
	hints_value = _line(rows, ThemeFactory.CAPTION, "Hints used", ThemeFactory.VALUE, str(result.hints_used))

	var buttons: HBoxContainer = UiKit.hbox(s.space_m)
	stack.add_child(buttons)
	play_again_button = UiKit.button(ThemeFactory.BUTTON_PRIMARY, "Play again", Layout.BUTTON_TALL)
	play_again_button.name = "PlayAgain"
	play_again_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_again_button.pressed.connect(_on_play_again)
	buttons.add_child(play_again_button)
	menu_button = UiKit.button(ThemeFactory.BUTTON_SECONDARY, "Menu", Layout.BUTTON_TALL)
	menu_button.name = "Menu"
	menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_button.pressed.connect(_on_menu)
	buttons.add_child(menu_button)
	var shadow_room: Control = Control.new()
	shadow_room.custom_minimum_size.y = s.shadow_offset
	stack.add_child(shadow_room)
	_animate(solved)


## Back goes to the main menu: there is nothing under this screen.
func handle_back() -> bool:
	_on_menu()
	return true


func _on_play_again() -> void:
	if app != null:
		app.start_new_puzzle(result.level)


func _on_menu() -> void:
	if app != null:
		app.goto(AppService.MAIN_MENU)


## A receipt line: caption at the left, value at the right.
func _line(rows: VBoxContainer, caption_style: StringName, caption: String, value_style: StringName, value: String) -> Label:
	var line: HBoxContainer = UiKit.hbox(0.0)
	rows.add_child(line)
	var left: Label = UiKit.label(caption_style, caption)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(left)
	var right: Label = UiKit.label(value_style, value)
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(right)
	return right


## A NEW BEST sticker under its line, shown only when the result has the bit.
func _new_best(rows: VBoxContainer, s: GameSkin, text: String, bit: int) -> Control:
	var holder: HBoxContainer = UiKit.hbox(0.0)
	holder.name = text.replace(" ", "")
	var tag: Control = UiKit.sticker(ThemeFactory.CELEBRATE_STICKER, ThemeFactory.CELEBRATE_LABEL, text, s.sticker_tilt)
	holder.add_child(tag)
	holder.visible = (result.new_best & bit) != 0
	rows.add_child(holder)
	return holder


## SOLVED! slams in and the final score counts up (Motion SOLVED_IN and
## SCORE_COUNT). Purely visual; the buttons already work.
func _animate(solved: Control) -> void:
	if not is_inside_tree():
		return
	solved.scale = Vector2(1.6, 1.6)
	var slam: Tween = solved.create_tween()
	slam.tween_property(solved, ^"scale", Vector2.ONE, Motion.SOLVED_IN).set_trans(Motion.trans(&"SOLVED_IN")).set_ease(Motion.ease_of(&"SOLVED_IN"))
	var final_score: int = result.final_score
	var count: Tween = score_value.create_tween()
	count.tween_method(func(value: float) -> void: score_value.text = str(roundi(value)), 0.0, float(final_score), Motion.SCORE_COUNT).set_trans(Motion.trans(&"SCORE_COUNT")).set_ease(Motion.ease_of(&"SCORE_COUNT"))
	for best: Control in [new_best_time, new_best_score]:
		if best.visible:
			best.modulate.a = 0.0
			var pop: Tween = best.create_tween()
			pop.tween_interval(Motion.SCORE_COUNT)
			pop.tween_property(best, ^"modulate:a", 1.0, Motion.NEW_BEST_IN).set_trans(Motion.trans(&"NEW_BEST_IN")).set_ease(Motion.ease_of(&"NEW_BEST_IN"))
