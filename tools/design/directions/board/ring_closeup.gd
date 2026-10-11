extends Control
## Ring close-up sheet: the close-up box of SampleState.closeup_board() in
## all three directions, light and dark, for one ring layout. Each tile is
## the direction's own board scene at true size (board_size * px_per_unit),
## cropped in a clipping Control, so nothing is scaled: one design unit times
## px_per_unit is one pixel.
##
## The capture tool renders it with px_per_unit 1.0 (a 1080 px wide phone)
## and 720 / 1080 (a 720 px wide phone). Contract:
## docs/design/briefs/grid-cell-artist-phase1.md, section 2.
##
## Prototype code in tools/, never shipped. Owner: grid-cell-artist.

const Palettes := preload("res://tools/design/directions/palettes.gd")
const RingLayouts := preload("res://tools/design/directions/ring_layouts.gd")
const SampleState := preload("res://tools/design/directions/sample_state.gd")
const Device := preload("res://tools/design/directions/device.gd")
const BoardView := preload("res://tools/design/directions/board/board.gd")

const BOARD_SCENE: String = "res://tools/design/directions/board/%s/board.tscn"

## The title and labels are set in Gridline light (brief, section 2).
const LABEL_DIRECTION: String = "gridline"

## Margins and gaps, in pixels (brief, section 2).
const MARGIN: float = 24.0

## Crop around the close-up box, in design units (brief, section 2).
const CROP_GROW: float = 12.0

var ring_layout: int = RingLayouts.DEFAULT_LAYOUT:
	set(value):
		ring_layout = value
		queue_redraw()

var px_per_unit: float = 1.0:
	set(value):
		px_per_unit = value
		queue_redraw()


## One tile of the sheet.
class Tile extends RefCounted:
	var direction: String
	var dark: bool
	var label: String
	var label_origin: Vector2 ## Baseline start of the label.
	var rect: Rect2 ## Where the crop shows on the sheet.
	var board_offset: Vector2 ## The board's position inside the tile.
	var board_side: float


## Everything the sheet places, worked out from the properties alone.
class Plan extends RefCounted:
	var size: Vector2i
	var title: String
	var title_origin: Vector2
	var tiles: Array[Tile] = []


## The size the capture renders. Valid as soon as the properties are set.
func sheet_size() -> Vector2i:
	return _plan().size


func _ready() -> void:
	for tile: Tile in _plan().tiles:
		var crop: ColorRect = ColorRect.new()
		crop.color = Palettes.palette(tile.direction, tile.dark).app_bg
		crop.clip_contents = true
		crop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crop.position = tile.rect.position
		crop.size = tile.rect.size
		add_child(crop)
		var packed: PackedScene = load(BOARD_SCENE % tile.direction) as PackedScene
		var board: BoardView = packed.instantiate() as BoardView
		board.dark = tile.dark
		board.ring_layout = ring_layout
		board.state = SampleState.closeup_board()
		board.position = tile.board_offset
		board.size = Vector2(tile.board_side, tile.board_side)
		crop.add_child(board)
	queue_redraw()


func _draw() -> void:
	var colors: Palettes.Palette = Palettes.palette(LABEL_DIRECTION, false)
	var style: Palettes.TypeStyle = Palettes.type_style(LABEL_DIRECTION, Palettes.ROLE_LABEL)
	var plan: Plan = _plan()
	draw_rect(Rect2(Vector2.ZERO, size), colors.app_bg)
	draw_string(style.font(), plan.title_origin, plan.title, HORIZONTAL_ALIGNMENT_LEFT, -1, style.font_size(), colors.text)
	for tile: Tile in plan.tiles:
		draw_string(style.font(), tile.label_origin, tile.label, HORIZONTAL_ALIGNMENT_LEFT, -1, style.font_size(), colors.text)


func _plan() -> Plan:
	var plan: Plan = Plan.new()
	var style: Palettes.TypeStyle = Palettes.type_style(LABEL_DIRECTION, Palettes.ROLE_LABEL)
	var font: Font = style.font()
	var font_size: int = style.font_size()
	var line_height: float = ceilf(font.get_height(font_size))
	var ascent: float = roundf(font.get_ascent(font_size))
	var phone_px: int = roundi(px_per_unit * float(Device.SCREEN_SIZE.x))
	plan.title = style.apply("%s, true size on a %d px wide phone" % [RingLayouts.NAMES[ring_layout], phone_px])
	var title_width: float = font.get_string_size(plan.title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

	# Crops in whole pixels, so every board lands on the pixel grid. Both
	# columns are as wide as the widest crop or label.
	var crops: Dictionary[String, Rect2] = {}
	var column: float = 0.0
	for direction: String in Palettes.DIRECTIONS:
		var side: float = Palettes.shape(direction).board_size * px_per_unit
		var board: Rect2 = Rect2(Vector2.ZERO, Vector2(side, side))
		var box: Rect2 = RingLayouts.box_rect(direction, board, SampleState.CLOSEUP_BOX).grow(CROP_GROW * px_per_unit)
		var start: Vector2 = box.position.floor()
		crops[direction] = Rect2(start, box.end.ceil() - start)
		column = maxf(column, crops[direction].size.x)
		for dark: bool in [false, true]:
			var label: String = _label(style, direction, dark)
			column = maxf(column, font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	column = ceilf(column)

	var y: float = MARGIN
	plan.title_origin = Vector2(MARGIN, y + ascent)
	y += line_height + MARGIN
	for direction: String in Palettes.DIRECTIONS:
		var crop: Rect2 = crops[direction]
		for dark: bool in [false, true]:
			var tile: Tile = Tile.new()
			var x: float = MARGIN + (column + MARGIN if dark else 0.0)
			tile.direction = direction
			tile.dark = dark
			tile.label = _label(style, direction, dark)
			tile.label_origin = Vector2(x, y + ascent)
			tile.rect = Rect2(Vector2(x, y + line_height), crop.size)
			tile.board_offset = -crop.position
			tile.board_side = Palettes.shape(direction).board_size * px_per_unit
			plan.tiles.append(tile)
		y += line_height + crop.size.y + MARGIN
	var width: float = maxf(2.0 * column + MARGIN, title_width) + 2.0 * MARGIN
	plan.size = Vector2i(ceili(width), ceili(y))
	return plan


func _label(style: Palettes.TypeStyle, direction: String, dark: bool) -> String:
	return style.apply("%s %s" % [Palettes.DIRECTION_NAMES[direction], "dark" if dark else "light"])
