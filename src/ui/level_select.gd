extends UiScreen
## Level select (GDD 15.2, DESIGN_SYSTEM.md 7.3 and 7.4): five levels, all
## open. With a puzzle in progress, choosing a level asks first; Start new
## abandons the old puzzle and starts the new one, Keep playing changes
## nothing and returns to the puzzle.
## Owner: ui-systems-dev.

const CONFIRM_TEXT: String = "You have a %s puzzle in progress. Start a new %s puzzle? The current one will count as started, not completed."

var level_buttons: Array[Button] = []
var confirm: ConfirmDialog = null
var _chosen: int = -1


func build() -> void:
	var s: GameSkin = skin()
	var stack: VBoxContainer = UiKit.vbox(s.space_s)
	column.add_child(stack)
	stack.add_child(UiKit.title_row("New puzzle", s.space_s, _on_back_pressed))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)
	var rows: VBoxContainer = UiKit.vbox(s.space_m)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for level: int in Levels.COUNT:
		var row: Button = _level_row(s, level)
		rows.add_child(row)
		level_buttons.append(row)
	var shadow_room: Control = Control.new()
	shadow_room.custom_minimum_size.y = s.shadow_offset
	rows.add_child(shadow_room)

	confirm = ConfirmDialog.new()
	confirm.name = "Confirm"
	confirm.setup(s, "", "Keep playing", "Start new", ThemeFactory.BUTTON_DANGER)
	confirm.confirmed.connect(_on_start_new)
	confirm.cancelled.connect(_on_keep_playing)
	add_child(confirm)


func handle_back() -> bool:
	if confirm.is_open():
		confirm.cancel()
		return true
	return false


## A level was chosen: start it, or ask first when a puzzle is in progress.
func choose(level: int) -> void:
	if app.is_generating():
		return
	if not app.has_puzzle_in_progress():
		app.start_new_puzzle(level)
		return
	_chosen = level
	UiKit.set_text(confirm.body, CONFIRM_TEXT % [Levels.name_of(app.session.level), Levels.name_of(level)])
	confirm.show_dialog()


func _on_start_new() -> void:
	var level: int = _chosen
	_chosen = -1
	app.abandon_puzzle()
	app.start_new_puzzle(level)


## Keep playing returns to the puzzle in progress, unchanged.
func _on_keep_playing() -> void:
	_chosen = -1
	if app.has_puzzle_in_progress():
		app.goto(AppService.PLAY)


func _level_row(s: GameSkin, level: int) -> Button:
	var row: Button = UiKit.button(ThemeFactory.LIST_BUTTON, "", UiSizes.ROW)
	row.name = Levels.name_of(level)
	var content: HBoxContainer = UiKit.hbox(s.space_m)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = s.space_m + s.outline_w
	content.offset_right = -(s.space_m + s.outline_w)
	row.add_child(content)
	var words: VBoxContainer = UiKit.vbox(0.0)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(words)
	words.add_child(UiKit.label(ThemeFactory.HEADING, Levels.name_of(level)))
	words.add_child(UiKit.label(ThemeFactory.CAPTION, "%d points" % Scoring.points(level)))
	var pips: LevelPips = LevelPips.new()
	pips.level = level
	pips.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(pips)
	row.pressed.connect(choose.bind(level))
	return row
