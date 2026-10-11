extends Control
## State sheet: the two boards of SampleState.state_sheet() for one direction
## in light or dark, each drawn by the direction's board scene at its
## board_size, with its title, notes and hint line above it. Together they
## show every cell state and the hard combinations.
##
## The capture tool sets the size to 1080 by 2720. Contract:
## docs/design/briefs/grid-cell-artist-phase1.md, section 3.
##
## Prototype code in tools/, never shipped. Owner: grid-cell-artist.

const Palettes := preload("res://tools/design/directions/palettes.gd")
const RingLayouts := preload("res://tools/design/directions/ring_layouts.gd")
const SampleState := preload("res://tools/design/directions/sample_state.gd")
const BoardView := preload("res://tools/design/directions/board/board.gd")

const BOARD_SCENE: String = "res://tools/design/directions/board/%s/board.tscn"

## Notes and the hint line: ROLE_BODY at this size, in units (brief, section 3).
const NOTE_SIZE: float = 30.0

var direction: String = "gridline":
	set(value):
		direction = value
		queue_redraw()

var dark: bool = false:
	set(value):
		dark = value
		queue_redraw()

var ring_layout: int = RingLayouts.DEFAULT_LAYOUT:
	set(value):
		ring_layout = value
		queue_redraw()


## One line or paragraph of text, placed.
class Text extends RefCounted:
	var text: String
	var origin: Vector2 ## Baseline start of the first line.
	var title: bool ## Title style, else note style.


## Everything the sheet places, worked out from the properties and size.
class Plan extends RefCounted:
	var texts: Array[Text] = []
	var boards: Array[Rect2] = []
	var states: Array[SampleState.BoardState] = []
	var bottom: float ## Lowest drawn point, including the board overhang.


func _ready() -> void:
	var plan: Plan = _plan()
	if plan.bottom > size.y:
		push_warning("State sheet for %s needs %d px but has %d." % [direction, ceili(plan.bottom), int(size.y)])
	var packed: PackedScene = load(BOARD_SCENE % direction) as PackedScene
	for n: int in plan.boards.size():
		var board: BoardView = packed.instantiate() as BoardView
		board.dark = dark
		board.ring_layout = ring_layout
		board.state = plan.states[n]
		board.position = plan.boards[n].position
		board.size = plan.boards[n].size
		add_child(board)
	queue_redraw()


func _draw() -> void:
	var colors: Palettes.Palette = Palettes.palette(direction, dark)
	var title: Palettes.TypeStyle = Palettes.type_style(direction, Palettes.ROLE_LABEL)
	var body: Palettes.TypeStyle = Palettes.type_style(direction, Palettes.ROLE_BODY)
	var note_font: Font = body.font_at(NOTE_SIZE)
	var note_size: int = roundi(NOTE_SIZE)
	var width: float = _text_width()
	draw_rect(Rect2(Vector2.ZERO, size), colors.app_bg)
	for text: Text in _plan().texts:
		if text.title:
			draw_string(title.font(), text.origin, text.text, HORIZONTAL_ALIGNMENT_LEFT, width, title.font_size(), colors.text)
		else:
			draw_multiline_string(note_font, text.origin, text.text, HORIZONTAL_ALIGNMENT_LEFT, width, note_size, -1, colors.text_muted)


## Vertical layout: for each entry, a gap, its text block, a gap, its board.
## The gaps are shape.space (plus the board's overhang below a board). If the
## sheet is too short for that, the gaps shrink evenly; the overhang below the
## last board always stays inside the sheet.
func _plan() -> Plan:
	var plan: Plan = Plan.new()
	var shape: Palettes.Shape = Palettes.shape(direction)
	var title: Palettes.TypeStyle = Palettes.type_style(direction, Palettes.ROLE_LABEL)
	var body: Palettes.TypeStyle = Palettes.type_style(direction, Palettes.ROLE_BODY)
	var title_font: Font = title.font()
	var note_font: Font = body.font_at(NOTE_SIZE)
	var note_size: int = roundi(NOTE_SIZE)
	var width: float = _text_width()
	var x: float = shape.screen_margin
	var side: float = shape.board_size
	var overhang: float = _overhang(shape)
	var entries: Array[SampleState.StateBoard] = SampleState.state_sheet()

	# Lines of text per entry, and the height each takes.
	var blocks: Array[PackedStringArray] = []
	var heights: Array[PackedFloat32Array] = []
	var content: float = overhang
	for entry: SampleState.StateBoard in entries:
		var lines: PackedStringArray = PackedStringArray([title.apply(entry.title)])
		var line_heights: PackedFloat32Array = PackedFloat32Array([ceilf(title_font.get_height(title.font_size()))])
		var notes: PackedStringArray = PackedStringArray()
		for note: String in entry.notes:
			notes.append(note)
		if entry.hint != null:
			var hint: String = "Hint: %s. %s" % [entry.hint.technique, entry.hint.text]
			if not entry.hint.lesson.is_empty():
				hint += " " + entry.hint.lesson
			notes.append(hint)
		for note: String in notes:
			var line: String = body.apply(note)
			lines.append(line)
			line_heights.append(ceilf(note_font.get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, width, note_size).y))
		blocks.append(lines)
		heights.append(line_heights)
		for h: float in line_heights:
			content += h
		content += side
	# Gaps above each text block and above each board.
	var gaps: PackedFloat32Array = PackedFloat32Array()
	var wanted: float = 0.0
	for n: int in entries.size():
		var above_text: float = shape.space + (overhang if n > 0 else 0.0)
		gaps.append(above_text)
		gaps.append(shape.space)
		wanted += above_text + shape.space
	var fit: float = clampf((size.y - content) / wanted, 0.0, 1.0) if wanted > 0.0 else 1.0
	if fit < 1.0:
		push_warning("State sheet for %s: gaps shrunk to %d%% to fit %d px." % [direction, roundi(fit * 100.0), int(size.y)])

	var y: float = 0.0
	for n: int in entries.size():
		y += roundf(gaps[n * 2] * fit)
		for line: int in blocks[n].size():
			var text: Text = Text.new()
			text.text = blocks[n][line]
			text.title = line == 0
			var ascent: float = title_font.get_ascent(title.font_size()) if text.title else note_font.get_ascent(note_size)
			text.origin = Vector2(x, roundf(y + ascent))
			plan.texts.append(text)
			y += heights[n][line]
		y += roundf(gaps[n * 2 + 1] * fit)
		plan.boards.append(Rect2(roundf((size.x - side) * 0.5), y, side, side))
		plan.states.append(entries[n].board)
		y += side
	plan.bottom = y + overhang
	return plan


func _text_width() -> float:
	return size.x - 2.0 * Palettes.shape(direction).screen_margin


## How far the board draws below its square: half the outer line and a hard
## shadow for lines boards, the soft shadow for tiles boards.
func _overhang(shape: Palettes.Shape) -> float:
	if shape.shadow_blur > 0.0:
		return shape.shadow_offset.y + shape.shadow_blur
	return shape.line_outer_w * 0.5 + shape.shadow_offset.y
