extends PanelContainer
## The lesson card in PlayArea's band (DESIGN_SYSTEM.md 4.8 and 7.13): a top
## row with the lesson sticker, the step caption and room for the close
## button, the lesson title, and the step text. A wrong tap shows its text in
## place of the step text, led by the "Not quite" tag.
##
## The card is as tall as its text. It keeps room for the step text and for
## every wrong tap text of the screen (set_texts), so the board does not
## move when a wrong tap shows. When the player caps the text height on a
## short screen, the text scrolls inside the card, with a fade at the bottom
## and a small down arrow while there is more.
## Internal to src/lessons: no class_name, preloaded by path.
## Owner: lessons-dev.

const TAG_TEXT: String = "Not quite"
## Height of the fade over the bottom of scrolling text.
const FADE_HEIGHT: float = 20.0
const ARROW_SIDE: float = 10.0

var skin: GameSkin = null

var top_row: HBoxContainer = null
var lesson_label: Label = null
var step_label: Label = null
## Where the close button sits; the player puts its touch area over it.
var close_slot: Control = null
var title_label: Label = null
var tag: PanelContainer = null
var body: Label = null
var scroll: ScrollContainer = null
var fade: Control = null

var _rows: VBoxContainer = null
var _text_box: Control = null
var _step_text: String = ""
var _reserve: PackedStringArray = PackedStringArray()
var _font_size: int = 0
var _capped: bool = false


func _init() -> void:
	name = "LessonCard"
	theme_type_variation = ThemeFactory.LESSON_CARD
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rows = VBoxContainer.new()
	_rows.name = "Rows"
	_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rows)

	top_row = HBoxContainer.new()
	top_row.name = "TopRow"
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.custom_minimum_size.y = Layout.LESSON_TOP_ROW
	_rows.add_child(top_row)
	var sticker: PanelContainer = PanelContainer.new()
	sticker.name = "Sticker"
	sticker.theme_type_variation = ThemeFactory.STICKER
	sticker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sticker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_row.add_child(sticker)
	lesson_label = _label("LessonNumber", ThemeFactory.STICKER_LABEL)
	sticker.add_child(lesson_label)
	step_label = _label("Step", ThemeFactory.CAPTION)
	step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	step_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	step_label.clip_text = true
	top_row.add_child(step_label)
	close_slot = Control.new()
	close_slot.name = "CloseSlot"
	close_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_slot.custom_minimum_size = Vector2(Layout.LESSON_TOP_ROW, Layout.LESSON_TOP_ROW)
	top_row.add_child(close_slot)

	title_label = _label("Title", ThemeFactory.HEADING)
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.custom_minimum_size.x = 1.0
	_rows.add_child(title_label)

	_text_box = MarginContainer.new()
	_text_box.name = "TextBox"
	_text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows.add_child(_text_box)
	scroll = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_text_box.add_child(scroll)
	var content: VBoxContainer = VBoxContainer.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	tag = PanelContainer.new()
	tag.name = "Tag"
	tag.theme_type_variation = ThemeFactory.CELEBRATE_STICKER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tag.visible = false
	tag.add_child(_label("TagText", ThemeFactory.CELEBRATE_LABEL, TAG_TEXT))
	content.add_child(tag)
	body = _label("Body", ThemeFactory.BODY)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 1.0
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	fade = Control.new()
	fade.name = "Fade"
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.draw.connect(_draw_fade)
	_text_box.add_child(fade)
	scroll.get_v_scroll_bar().value_changed.connect(func(_value: float) -> void: fade.queue_redraw())
	scroll.get_v_scroll_bar().changed.connect(fade.queue_redraw)


## The skin for custom drawing and the spacing between rows.
func apply_skin(new_skin: GameSkin) -> void:
	skin = new_skin
	if skin == null:
		return
	_rows.add_theme_constant_override(&"separation", roundi(skin.space_xs))
	top_row.add_theme_constant_override(&"separation", roundi(skin.space_s))
	(tag.get_parent() as VBoxContainer).add_theme_constant_override(&"separation", roundi(skin.space_xs))
	fade.queue_redraw()


## The top row and title: "Lesson 2 of 5", "Step 5 of 8", the lesson title.
func set_header(lesson_text: String, step_text: String, title: String) -> void:
	lesson_label.text = ThemeFactory.display_text(ThemeFactory.STICKER_LABEL, lesson_text)
	step_label.text = ThemeFactory.display_text(ThemeFactory.CAPTION, step_text)
	title_label.text = ThemeFactory.display_text(ThemeFactory.HEADING, title)


## The step text, and every wrong tap text the card keeps room for.
func set_texts(step_text: String, wrong_texts: PackedStringArray) -> void:
	_step_text = step_text
	_reserve = wrong_texts.duplicate()
	show_step()


func show_step() -> void:
	tag.visible = false
	body.text = _step_text
	scroll.scroll_vertical = 0
	fade.queue_redraw()


func show_wrong(text: String) -> void:
	tag.visible = true
	body.text = text
	scroll.scroll_vertical = 0
	fade.queue_redraw()


func is_showing_wrong() -> bool:
	return tag.visible


## Sets the body text size and whether the title shows, sizes the text box
## for width (the card's outer width), and returns the card's height. With
## max_height, the text box shrinks so the card fits it, and the text scrolls.
func configure(width: float, font_size: int, show_title: bool, max_height: float = INF) -> float:
	_font_size = font_size
	body.add_theme_font_size_override(&"font_size", font_size)
	title_label.visible = show_title
	var box: StyleBox = get_theme_stylebox(&"panel")
	var pad_x: float = box.get_content_margin(SIDE_LEFT) + box.get_content_margin(SIDE_RIGHT) if box != null else 0.0
	var pad_y: float = box.get_content_margin(SIDE_TOP) + box.get_content_margin(SIDE_BOTTOM) if box != null else 0.0
	var gap: float = float(_rows.get_theme_constant(&"separation"))
	var inner_w: float = maxf(1.0, width - pad_x)
	var fixed: float = pad_y + Layout.LESSON_TOP_ROW + gap
	if show_title:
		fixed += title_label.get_combined_minimum_size().y + gap
	var text_h: float = text_area_height(inner_w)
	_capped = fixed + text_h > max_height
	if _capped:
		text_h = maxf(0.0, max_height - fixed)
	_text_box.custom_minimum_size.y = text_h
	fade.queue_redraw()
	return fixed + text_h


func is_capped() -> bool:
	return _capped


## The height the text needs at this width: the step text, or the tag and
## the longest wrong tap text, whichever is taller.
func text_area_height(width: float) -> float:
	var tallest: float = text_height(body, _step_text, width, _font_size)
	var content: VBoxContainer = tag.get_parent() as VBoxContainer
	var gap: float = float(content.get_theme_constant(&"separation")) if content != null else 0.0
	var tag_h: float = tag.get_combined_minimum_size().y + gap
	for text: String in _reserve:
		tallest = maxf(tallest, tag_h + text_height(body, text, width, _font_size))
	return ceilf(tallest)


## How tall label would be with text wrapped at width, in its font at
## font_size (0 means the label's theme size).
static func text_height(label: Label, text: String, width: float, font_size: int) -> float:
	var font: Font = label.get_theme_font(&"font")
	if font == null or text.is_empty():
		return 0.0
	var size_px: int = font_size if font_size > 0 else label.get_theme_font_size(&"font_size")
	var paragraph: TextParagraph = TextParagraph.new()
	paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	paragraph.width = maxf(1.0, width)
	paragraph.add_string(text, font, size_px)
	var lines: int = paragraph.get_line_count()
	var height: float = 0.0
	for i: int in lines:
		height += paragraph.get_line_size(i).y
	# Label puts its line spacing between lines only; it may be negative.
	height += float(label.get_theme_constant(&"line_spacing")) * float(maxi(lines - 1, 0))
	return ceilf(height)


func _label(node_name: String, variation: StringName, text: String = "") -> Label:
	var label: Label = Label.new()
	label.name = node_name
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = ThemeFactory.display_text(variation, text)
	return label


## The fade over the bottom of the text and the down arrow, while more text
## is below.
func _draw_fade() -> void:
	if skin == null or not _capped:
		return
	var bar: VScrollBar = scroll.get_v_scroll_bar()
	if bar.value + bar.page >= bar.max_value - 0.5:
		return
	var w: float = fade.size.x
	var bottom: float = fade.size.y
	var top: float = maxf(0.0, bottom - FADE_HEIGHT)
	var clear: Color = skin.surface_bg
	clear.a = 0.0
	fade.draw_polygon(
		PackedVector2Array([Vector2(0.0, top), Vector2(w, top), Vector2(w, bottom), Vector2(0.0, bottom)]),
		PackedColorArray([clear, clear, skin.surface_bg, skin.surface_bg]))
	var tip: Vector2 = Vector2(w - ARROW_SIDE, bottom - 2.0)
	fade.draw_polyline(PackedVector2Array([
		tip + Vector2(-ARROW_SIDE * 0.5, -ARROW_SIDE * 0.5), tip, tip + Vector2(ARROW_SIDE * 0.5, -ARROW_SIDE * 0.5),
	]), skin.text_muted, 2.0, true)
