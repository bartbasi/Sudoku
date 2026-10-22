extends UiScreen
## The completion screen (GDD 12, DESIGN_SYSTEM.md 7.9). Shows the
## CompletionResult it is opened with: level, final time, points after
## hints, time bonus, final score, hints used, and NEW BEST TIME or NEW BEST
## SCORE when the result says so. Play again starts a new puzzle at the same
## level with no dialog; Menu and Back go to the main menu. Under them the
## smaller Buy me a coffee button hands the support page to the phone's web
## browser (App.open_support_page, GDD 15.7); it does nothing while a puzzle
## is being made, so after Play again it stays quiet. The buttons work from
## the first frame. Side by side (4.11) the starburst takes the left half
## and the receipt, the buttons and Buy me a coffee the right half.
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
## The face of Buy me a coffee; coffee_touch is its 48 dp touch area.
var coffee_button: Button = null
var coffee_touch: Control = null
## The starburst, SOLVED! and the level first; the receipt and the buttons
## second (DESIGN_SYSTEM.md 4.11).
var halves: HalvesBox = null
## Holds the receipt. Side by side it scrolls when the receipt does not fit
## above the buttons; stacked it is as tall as the receipt.
var receipt_scroll: ScrollContainer = null
var _receipt_room: MarginContainer = null


func open(new_payload: Variant) -> void:
	payload = new_payload
	result = new_payload as CompletionResult


func build() -> void:
	if result == null:
		result = CompletionResult.new()
	var s: GameSkin = skin()
	halves = HalvesBox.new()
	halves.name = "Halves"
	halves.skin = s
	halves.stacked_mode = HalvesBox.Stacked.FILL_FIRST
	halves.stacked_gap = s.space_m
	halves.side_gap = s.space_xl
	halves.arranged.connect(_on_arranged)
	column.add_child(halves)
	var stack: VBoxContainer = UiKit.vbox(s.space_m)
	stack.name = "Celebrate"
	halves.add_child(stack)

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

	var results: VBoxContainer = UiKit.vbox(s.space_m)
	results.name = "Results"
	halves.add_child(results)
	receipt_scroll = ScrollContainer.new()
	receipt_scroll.name = "ReceiptScroll"
	receipt_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	results.add_child(receipt_scroll)
	_receipt_room = MarginContainer.new()
	_receipt_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_receipt_room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	receipt_scroll.add_child(_receipt_room)
	_on_arranged(false)

	var receipt: PanelContainer = UiKit.panel(ThemeFactory.CARD)
	receipt.name = "Receipt"
	_receipt_room.add_child(receipt)
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
	buttons.name = "Buttons"
	results.add_child(UiKit.with_shadow_room(buttons, s))
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
	var coffee: UiKit.TouchTarget = UiKit.coffee_button()
	coffee_touch = coffee
	coffee_button = coffee.button
	coffee_button.pressed.connect(_on_coffee)
	results.add_child(coffee)
	_animate(solved)


## Stacked, the receipt keeps its size and nothing scrolls (7.9). Side by
## side the receipt scrolls in the space above the buttons, which stay
## pinned at the bottom of the right half; it keeps room for its shadow
## inside the clipped scroll area.
func _on_arranged(side: bool) -> void:
	var s: GameSkin = skin()
	receipt_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if side else ScrollContainer.SCROLL_MODE_DISABLED
	receipt_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL if side else Control.SIZE_FILL
	receipt_scroll.clip_contents = side
	var room: int = roundi(s.shadow_offset) if side else 0
	_receipt_room.add_theme_constant_override(&"margin_right", room)
	_receipt_room.add_theme_constant_override(&"margin_bottom", room)
	_receipt_room.add_theme_constant_override(&"margin_left", 0)
	_receipt_room.add_theme_constant_override(&"margin_top", 0)


## Back goes to the main menu: there is nothing under this screen.
func handle_back() -> bool:
	_on_menu()
	return true


func _on_play_again() -> void:
	if app != null:
		app.start_new_puzzle(result.level)


func _on_coffee() -> void:
	if app != null and not app.is_generating():
		app.open_support_page()


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
