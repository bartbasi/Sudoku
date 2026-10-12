class_name HintPanel
extends PanelContainer
## The hint panel (GDD 10.2, DESIGN_SYSTEM.md 7.6): the technique name in a
## tag, the lesson title when there is one, a close button, and the hint
## text. The play screen places it over the info zone, so it never covers a
## cell.
## Owner: ui-systems-dev.

signal close_pressed()

var tag_label: Label = null
var lesson_label: Label = null
var text_label: Label = null
var close_touch: Control = null
var close_button: Button = null


func setup(skin: GameSkin) -> void:
	theme_type_variation = ThemeFactory.HINT_PANEL
	mouse_filter = Control.MOUSE_FILTER_STOP
	var stack: VBoxContainer = UiKit.vbox(skin.space_xs)
	add_child(stack)
	var top: HBoxContainer = UiKit.hbox(skin.space_s)
	stack.add_child(top)
	var tag: PanelContainer = UiKit.panel(ThemeFactory.HINT_TAG)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag_label = UiKit.label(ThemeFactory.HINT_TAG_LABEL, "")
	tag.add_child(tag_label)
	top.add_child(tag)
	lesson_label = UiKit.label(ThemeFactory.CAPTION, "")
	lesson_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lesson_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(lesson_label)
	close_touch = UiKit.icon_button(Icons.CLOSE, UiSizes.HINT_CLOSE_FACE)
	close_touch.name = "Close"
	close_button = close_touch.get(&"button") as Button
	close_button.pressed.connect(func() -> void: close_pressed.emit())
	top.add_child(close_touch)
	text_label = UiKit.label(ThemeFactory.BODY_SMALL, "", true)
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(text_label)
	visible = false


func show_hint(hint: Hint) -> void:
	UiKit.set_text(tag_label, hint.technique_name)
	UiKit.set_text(lesson_label, hint.lesson_title)
	UiKit.set_text(text_label, hint.text)
	if not visible:
		UiKit.panel_in(self)
