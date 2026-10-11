extends RefCounted
## Building blocks shared by the Phase 1 screen prototypes of all three
## directions: text set in the direction's type styles, panels and keys drawn
## with StyleBoxFlat, invisible tap targets, code-drawn icons and the embedded
## board. Every color, font and shape token comes from the shared data in
## tools/design/directions/. After a screen is built, check() reports text or
## controls under the safe insets, text wider than its box or cut off, and
## tap targets under 144 by 144 units.
## Prototype code in tools/, never shipped. Owner: ui-motion-artist.

const Palettes := preload("res://tools/design/directions/palettes.gd")
const SampleState := preload("res://tools/design/directions/sample_state.gd")
const Fonts := preload("res://tools/design/directions/fonts.gd")
const Device := preload("res://tools/design/directions/device.gd")
const Block := preload("res://tools/design/directions/ui/common/block.gd")
const IconView := preload("res://tools/design/directions/ui/common/icon_view.gd")

const BOARD_SCENE: String = "res://tools/design/directions/board/%s/board.tscn"

## Smallest touch area: 48 dp on the smallest phone we support (brief).
const MIN_TOUCH: float = 144.0

## Line breaking that matches Label's AUTOWRAP_WORD_SMART.
const WRAP_FLAGS: int = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE

var direction: String
var dark: bool
var ring_layout: int
var colors: Palettes.Palette
var shape: Palettes.Shape
## Icon line weight as a share of the icon side, and line ends. There is no
## token for these yet; each direction passes its own (see the report).
var icon_stroke: float
var icon_round: bool
var problems: PackedStringArray = PackedStringArray()


func _init(p_direction: String, p_dark: bool, p_ring_layout: int, p_icon_stroke: float, p_icon_round: bool) -> void:
	direction = p_direction
	dark = p_dark
	ring_layout = p_ring_layout
	colors = Palettes.palette(direction, dark)
	shape = Palettes.shape(direction)
	icon_stroke = p_icon_stroke
	icon_round = p_icon_round


# Type

func type(role: String) -> Palettes.TypeStyle:
	return Palettes.type_style(direction, role)


## Width of text set in a role (capitals applied).
func text_width(value: String, role: String) -> float:
	var style: Palettes.TypeStyle = type(role)
	return style.font().get_string_size(style.apply(value), HORIZONTAL_ALIGNMENT_LEFT, -1, style.font_size()).x


## Line height of a role.
func line_height(role: String) -> float:
	var style: Palettes.TypeStyle = type(role)
	return style.font().get_height(style.font_size())


## Height of a capital or digit in a role, measured from the glyph.
func cap_height(role: String) -> float:
	var style: Palettes.TypeStyle = type(role)
	return Fonts.ink_box(style.font(), style.font_size(), "H").size.y


## One line of text centered vertically in rect, aligned horizontally as asked.
## The box grows to the line height if it is shorter, keeping its center.
func text(parent: Control, value: String, role: String, color: Color, rect: Rect2, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var style: Palettes.TypeStyle = type(role)
	var label: Label = _label(style, value, color)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var height: float = style.font().get_height(style.font_size())
	var box: Rect2 = rect
	if box.size.y < height:
		box = box.grow_individual(0.0, (height - box.size.y) * 0.5, 0.0, (height - box.size.y) * 0.5)
	var width: float = text_width(value, role)
	if width > box.size.x + 0.5:
		problems.append("\"%s\" is %.0f wide in a %.0f box" % [label.text, width, box.size.x])
	label.position = box.position
	label.size = box.size
	parent.add_child(label)
	return label


## One line of text whose baseline sits at y = baseline.
func text_at_baseline(parent: Control, value: String, role: String, color: Color, x: float, baseline: float, width: float, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var style: Palettes.TypeStyle = type(role)
	var font: Font = style.font()
	var label: Label = _label(style, value, color)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var measured: float = text_width(value, role)
	if measured > width + 0.5:
		problems.append("\"%s\" is %.0f wide in a %.0f box" % [label.text, measured, width])
	label.position = Vector2(x, baseline - font.get_ascent(style.font_size()))
	label.size = Vector2(width, font.get_height(style.font_size()))
	parent.add_child(label)
	return label


## Wrapped text with its top at y. Its height fits its lines exactly.
func paragraph(parent: Control, value: String, role: String, color: Color, x: float, y: float, width: float, line_gap: float, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var style: Palettes.TypeStyle = type(role)
	var label: Label = _label(style, value, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_constant_override("line_spacing", roundi(line_gap))
	label.position = Vector2(x, y)
	label.size = Vector2(width, paragraph_height(value, role, width, line_gap))
	parent.add_child(label)
	return label


func paragraph_height(value: String, role: String, width: float, line_gap: float) -> float:
	var style: Palettes.TypeStyle = type(role)
	var font: Font = style.font()
	var size: int = style.font_size()
	var block: Vector2 = font.get_multiline_string_size(style.apply(value), HORIZONTAL_ALIGNMENT_LEFT, width, size, -1, WRAP_FLAGS)
	var line: float = font.get_height(size)
	var lines: int = maxi(1, roundi(block.y / line))
	return float(lines) * line + float(lines - 1) * roundf(line_gap)


func _label(style: Palettes.TypeStyle, value: String, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = style.apply(value)
	label.add_theme_font_override("font", style.font())
	label.add_theme_font_size_override("font_size", style.font_size())
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


# Shapes

func style_box(bg: Color, radius: float) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(roundi(radius))
	box.corner_detail = clampi(roundi(radius / 3.0), 8, 24)
	box.anti_aliasing = true
	return box


## A panel, chip, key or button face. radius 999 means fully round. outline
## draws the direction's UI outline (in outline_color if given, for shapes
## that sit on a colored band); shadow draws its soft or hard shadow.
func panel(parent: Control, rect: Rect2, bg: Color, radius: float, outline: bool = false, shadow: bool = false, outline_color: Color = Color(0.0, 0.0, 0.0, 0.0)) -> Block:
	var block: Block = Block.new()
	block.position = rect.position
	block.size = rect.size
	block.fill = style_box(bg, radius)
	if outline and shape.outline_w > 0.0:
		var edge: StyleBoxFlat = style_box(Color(0.0, 0.0, 0.0, 0.0), radius)
		edge.draw_center = false
		edge.set_border_width_all(roundi(shape.outline_w))
		edge.border_color = outline_color if outline_color.a > 0.0 else colors.outline
		block.border = edge
	if shadow and colors.shadow.a > 0.0:
		if shape.shadow_blur > 0.0:
			block.fill.shadow_color = colors.shadow
			block.fill.shadow_size = roundi(shape.shadow_blur)
			block.fill.shadow_offset = shape.shadow_offset
		elif shape.shadow_offset != Vector2.ZERO:
			block.hard_shadow = style_box(colors.shadow, radius)
			block.hard_offset = shape.shadow_offset
	parent.add_child(block)
	return block


## An invisible tap target over rect. The visible face may be smaller; this
## is the touch area. small_ok marks the one deliberate exception (Gridline's
## row of nine keys).
func tap(parent: Control, rect: Rect2, what: String, small_ok: bool = false) -> Button:
	var button: Button = Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = what
	button.position = rect.position
	button.size = rect.size
	button.set_meta("small_ok", small_ok)
	if not small_ok and (rect.size.x < MIN_TOUCH - 0.5 or rect.size.y < MIN_TOUCH - 0.5):
		problems.append("tap target %s is %.0f by %.0f" % [what, rect.size.x, rect.size.y])
	parent.add_child(button)
	return button


func icon(parent: Control, kind: String, rect: Rect2, color: Color) -> IconView:
	var view: IconView = IconView.new()
	view.kind = kind
	view.color = color
	view.stroke = icon_stroke
	view.round_caps = icon_round
	view.position = rect.position
	view.size = rect.size
	parent.add_child(view)
	return view


## A centered row of an icon and a label inside rect. Returns the label.
func icon_text(parent: Control, kind: String, value: String, role: String, color: Color, rect: Rect2, icon_side: float, gap: float) -> Label:
	var width: float = text_width(value, role)
	var total: float = icon_side + gap + width
	var x: float = rect.position.x + (rect.size.x - total) * 0.5
	icon(parent, kind, Rect2(x, rect.get_center().y - icon_side * 0.5, icon_side, icon_side), color)
	return text(parent, value, role, color, Rect2(x + icon_side + gap, rect.position.y, width + 1.0, rect.size.y), HORIZONTAL_ALIGNMENT_LEFT)


# Board

## The direction's board scene in rect (a square of board_size). Falls back to
## a plain square in board_bg while the board scene is missing or broken.
func board(parent: Control, rect: Rect2, state: SampleState.BoardState) -> Control:
	var path: String = BOARD_SCENE % direction
	var node: Control = null
	if ResourceLoader.exists(path):
		var packed: PackedScene = load(path) as PackedScene
		if packed != null:
			var instance: Node = packed.instantiate()
			if instance is Control and instance.get_script() != null and "state" in instance:
				node = instance as Control
			elif instance != null:
				instance.free()
	if node == null:
		print("NOTE %s: board scene %s is missing or broken, drew the plain square" % [direction, path])
		return panel(parent, rect, colors.board_bg, 0.0)
	node.set("dark", dark)
	node.set("ring_layout", ring_layout)
	node.set("state", state)
	node.position = rect.position
	node.size = rect.size
	parent.add_child(node)
	return node


# Checks

## Reports layout problems found while building and in the finished tree.
## Prints nothing when the screen is clean.
func check(root: Control, screen: String) -> void:
	var safe: Rect2 = Device.safe_rect(root.size).grow(0.5)
	_walk(root, safe)
	for problem: String in problems:
		print("LAYOUT %s %s%s: %s" % [direction, screen, " dark" if dark else "", problem])


func _walk(node: Node, safe: Rect2) -> void:
	for child: Node in node.get_children():
		if child is Label or child is Button or child is IconView:
			var control: Control = child as Control
			var rect: Rect2 = control.get_global_rect()
			if not safe.encloses(rect):
				var what: String = (control as Label).text if control is Label else control.get_class()
				problems.append("\"%s\" at %s is outside the safe area" % [what, rect])
		if child is Label:
			var label: Label = child as Label
			if label.autowrap_mode != TextServer.AUTOWRAP_OFF and label.get_visible_line_count() < label.get_line_count():
				problems.append("\"%s\" is cut off: %d of %d lines show" % [label.text, label.get_visible_line_count(), label.get_line_count()])
		_walk(child, safe)
