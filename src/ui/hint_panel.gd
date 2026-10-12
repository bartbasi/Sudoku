class_name HintPanel
extends PanelContainer
## The hint panel (GDD 10.2, DESIGN_SYSTEM.md 7.6): two columns. The left
## one holds the technique name in a tag with the lesson title beside it,
## then the hint text; the right one holds the close button alone. The play
## screen places it over the info zone, so it never covers a cell.
##
## The hint text steps down from BODY_SMALL to BODY_SMALL_12 and then
## BODY_SMALL_11, by its type variation only: it uses the first step at
## which the text takes three lines or fewer and the panel fits max_height.
## Owner: ui-systems-dev.

signal close_pressed()

## The text steps, largest first (7.6).
const TEXT_STEPS: Array[StringName] = [ThemeFactory.BODY_SMALL, ThemeFactory.BODY_SMALL_12, ThemeFactory.BODY_SMALL_11]
## The hint text never takes more lines than this at a step it keeps.
const MAX_LINES: int = 3

## The tallest the panel may be: the info zone's height. The play screen
## sets it; INF means only the line rule counts.
var max_height: float = INF:
	set(value):
		if not is_equal_approx(value, max_height):
			max_height = value
			fit_text()

var tag_label: Label = null
var lesson_label: Label = null
var text_label: Label = null
var close_touch: Control = null
var close_button: Button = null

var _fitted_width: float = -1.0


func setup(skin: GameSkin) -> void:
	theme_type_variation = ThemeFactory.HINT_PANEL
	mouse_filter = Control.MOUSE_FILTER_STOP
	var columns: HBoxContainer = UiKit.hbox(0.0)
	add_child(columns)
	var left: VBoxContainer = UiKit.vbox(skin.space_xs)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	var top: HBoxContainer = UiKit.hbox(skin.space_s)
	left.add_child(top)
	var tag: PanelContainer = UiKit.panel(ThemeFactory.HINT_TAG)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag_label = UiKit.label(ThemeFactory.HINT_TAG_LABEL, "")
	tag.add_child(tag_label)
	top.add_child(tag)
	lesson_label = UiKit.label(ThemeFactory.CAPTION, "")
	lesson_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lesson_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lesson_label.custom_minimum_size.x = 1.0
	top.add_child(lesson_label)
	text_label = UiKit.label(ThemeFactory.BODY_SMALL, "", true)
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.resized.connect(_on_text_resized)
	left.add_child(text_label)
	close_touch = UiKit.icon_button(Icons.CLOSE, Layout.CLOSE_FACE)
	close_touch.name = "Close"
	close_touch.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close_button = close_touch.get(&"button") as Button
	close_button.pressed.connect(func() -> void: close_pressed.emit())
	columns.add_child(close_touch)
	visible = false


func show_hint(hint: Hint) -> void:
	UiKit.set_text(tag_label, hint.technique_name)
	UiKit.set_text(lesson_label, hint.lesson_title)
	UiKit.set_text(text_label, hint.text)
	fit_text()
	if not visible:
		UiKit.panel_in(self)


## Picks the text step for the text and the width the label has now: the
## first that wraps to MAX_LINES or fewer with the panel no taller than
## max_height. If none does, the smallest.
func fit_text() -> void:
	if text_label == null:
		return
	_fitted_width = text_label.size.x
	for step: StringName in TEXT_STEPS:
		text_label.theme_type_variation = step
		if text_label.get_line_count() <= MAX_LINES and get_combined_minimum_size().y <= max_height + 0.01:
			return


## The text re-measures when its width changes. A height change alone comes
## from fit_text itself, so it is left alone.
func _on_text_resized() -> void:
	if not is_equal_approx(text_label.size.x, _fitted_width):
		fit_text()
