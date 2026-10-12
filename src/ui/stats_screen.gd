extends UiScreen
## The stats screen (GDD 13, DESIGN_SYSTEM.md 7.10): one card per level with
## started, completed, best score, best time and average time, and a bar of
## completed out of started; then lessons completed as "N of M". Every label
## in full words; "-" before a level's first completion. The list scrolls.
## Owner: ui-systems-dev.

## Lessons in v1 (GDD 13.1: "M is the number of lessons, 5 in v1").
const LESSON_COUNT: int = 5

## Per level: the value labels by key, for tests and refresh.
var values: Array[Dictionary] = []
var bars: Array[ProgressBar] = []
var lessons_value: Label = null
var lesson_squares: LessonSquares = null


func build() -> void:
	var s: GameSkin = skin()
	var stack: VBoxContainer = UiKit.vbox(s.space_s)
	column.add_child(stack)
	stack.add_child(UiKit.title_row("Stats", s.space_s, _on_back_pressed))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)
	var cards: VBoxContainer = UiKit.vbox(s.space_m)
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(cards)
	for level: int in Levels.COUNT:
		cards.add_child(_level_card(s, level))
	cards.add_child(_lessons_card(s))
	var shadow_room: Control = Control.new()
	shadow_room.custom_minimum_size.y = s.shadow_offset
	cards.add_child(shadow_room)
	refresh()
	if app != null:
		app.stats_changed.connect(refresh)


func on_shown() -> void:
	refresh()


func refresh() -> void:
	if app == null:
		return
	var stats: Stats = app.stats
	for level: int in Levels.COUNT:
		var row: Dictionary = values[level]
		UiKit.set_text(row["started"], str(stats.started(level)))
		UiKit.set_text(row["completed"], str(stats.completed_count(level)))
		UiKit.set_text(row["best_score"], UiKit.stat_number(stats.best_score(level)))
		UiKit.set_text(row["best_time"], UiKit.stat_time(stats.best_time(level)))
		UiKit.set_text(row["average_time"], UiKit.stat_time(stats.average_time(level)))
		var bar: ProgressBar = bars[level]
		bar.max_value = maxf(1.0, float(stats.started(level)))
		bar.value = float(stats.completed_count(level))
	var done: int = mini(app.lessons.finished_count(), LESSON_COUNT)
	UiKit.set_text(lessons_value, "%d of %d" % [done, LESSON_COUNT])
	lesson_squares.finished = done
	lesson_squares.queue_redraw()


func _level_card(s: GameSkin, level: int) -> PanelContainer:
	var card: PanelContainer = UiKit.panel(ThemeFactory.CARD)
	card.name = Levels.name_of(level)
	var inside: VBoxContainer = UiKit.vbox(s.space_s)
	card.add_child(inside)
	var top: HBoxContainer = UiKit.hbox(s.space_m)
	inside.add_child(top)
	top.add_child(UiKit.sticker(ThemeFactory.STICKER, ThemeFactory.STICKER_LABEL, Levels.name_of(level), s.sticker_tilt if level % 2 == 0 else -s.sticker_tilt))
	var bar: ProgressBar = ProgressBar.new()
	bar.theme_type_variation = ThemeFactory.STAT_BAR
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(bar)
	bars.append(bar)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", roundi(s.space_m))
	grid.add_theme_constant_override(&"v_separation", roundi(s.space_xs))
	inside.add_child(grid)
	var row: Dictionary = {}
	var layout: Array[Array] = [
		[["started", "Started"], ["completed", "Completed"], ["best_score", "Best score"]],
		[["best_time", "Best time"], ["average_time", "Average time"], ["", ""]],
	]
	for line: Array in layout:
		for entry: Array in line:
			var caption: Label = UiKit.label(ThemeFactory.CAPTION, entry[1])
			caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(caption)
		for entry: Array in line:
			var value: Label = UiKit.label(ThemeFactory.VALUE, "")
			value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(value)
			if entry[0] != "":
				row[entry[0]] = value
	values.append(row)
	return card


func _lessons_card(s: GameSkin) -> PanelContainer:
	var card: PanelContainer = UiKit.panel(ThemeFactory.CARD)
	card.name = "Lessons"
	var inside: VBoxContainer = UiKit.vbox(s.space_s)
	card.add_child(inside)
	var top: HBoxContainer = UiKit.hbox(s.space_m)
	inside.add_child(top)
	var caption: Label = UiKit.label(ThemeFactory.CAPTION, "Lessons completed")
	caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(caption)
	lessons_value = UiKit.label(ThemeFactory.VALUE, "")
	top.add_child(lessons_value)
	lesson_squares = LessonSquares.new()
	lesson_squares.total = LESSON_COUNT
	inside.add_child(lesson_squares)
	return card
