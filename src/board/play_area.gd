class_name PlayArea extends Control
## The board, the pad and the controller that joins them to a session, laid
## out as one vertical stack (docs/ARCHITECTURE.md section 8, the rules in
## docs/DESIGN_SYSTEM.md 4.6 and 4.7). Normal play and the lesson player both
## use it.
##
## Its rect is the safe area below the screen's header row: full safe width,
## from the bottom of the header row (on the lesson screen, page_margin below
## the safe top) down to the safe bottom. Inside it, in a column
## min(width - 2 * page_margin, COLUMN_MAX) wide and centered, top to bottom:
## the band, the board with its outer line and shadow, the gap, and the three
## rows of keys, with page_margin kept below the keys.
##
## How the height is shared (4.7): start from BAND_MIN, BOARD_GAP_MIN and
## KEY_MIN; the board takes the rest, up to the column width; leftover height
## grows the keys to KEY_MAX, then half of what is left grows the band up to
## BAND_MAX and the rest grows the gap up to BOARD_GAP_MAX; anything still
## left goes equally above and below the stack.
##
## Scene: scenes/board/play_area.tscn. Owner: board-input-dev.

const Support := preload("res://src/board/board_support.gd")

var view: BoardView = null
var pad: NumberPad = null
var controller: BoardController = null

## The skin whose sizes the layout uses, passed on to the view and the pad.
## Null means the Skins autoload's current skin.
var skin: GameSkin = null:
	set(value):
		skin = value
		if view != null:
			view.skin = value
		if pad != null:
			pad.skin = value
		_layout()

var _band_height: float = -1.0
var _band: Rect2 = Rect2()
var _watched_service: Node = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	view = BoardView.new()
	view.name = "BoardView"
	add_child(view, false, Node.INTERNAL_MODE_FRONT)
	pad = NumberPad.new()
	pad.name = "NumberPad"
	add_child(pad, false, Node.INTERNAL_MODE_FRONT)
	controller = BoardController.new()
	controller.name = "BoardController"
	add_child(controller, false, Node.INTERNAL_MODE_FRONT)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_layout()
		NOTIFICATION_ENTER_TREE:
			_watch_skins(Support.skin_service(self))
			_layout()
		NOTIFICATION_EXIT_TREE:
			_watch_skins(null)


func setup(session: GameSession) -> void:
	controller.setup(session, view, pad)


## The band above the board on screen. The play screen puts the level
## sticker there; the lesson player puts its lesson card there.
func band_rect_global() -> Rect2:
	return get_global_transform() * _band


## The band's height. The lesson player sizes it to its card; the play
## screen leaves the Layout default (BAND_MIN growing to BAND_MAX). Zero or
## less goes back to that default.
func set_band_height(height: float) -> void:
	_band_height = height if height > 0.0 else -1.0
	_layout()


## The band in local coordinates.
func band_rect() -> Rect2:
	return _band


func _layout() -> void:
	var current: GameSkin = Support.skin_for(self, skin)
	if current == null or view == null:
		return
	var margin: float = current.page_margin
	var gap_s: float = current.space_s
	var content_w: float = maxf(0.0, minf(size.x - 2.0 * margin, Layout.COLUMN_MAX))
	var column_x: float = (size.x - content_w) * 0.5
	var avail: float = maxf(0.0, size.y - margin)
	var over: float = current.line_outer_w + current.shadow_offset
	var band_min: float = Layout.BAND_MIN if _band_height < 0.0 else _band_height
	var band_max: float = Layout.BAND_MAX if _band_height < 0.0 else _band_height
	var controls_min: float = 3.0 * Layout.KEY_MIN + 2.0 * gap_s
	var fixed: float = band_min + over + Layout.BOARD_GAP_MIN + controls_min
	var board: float = maxf(0.0, minf(content_w - over, avail - fixed))
	var spare: float = maxf(0.0, avail - fixed - board)
	var key_h: float = Layout.KEY_MIN + minf(spare / 3.0, Layout.KEY_MAX - Layout.KEY_MIN)
	spare -= 3.0 * (key_h - Layout.KEY_MIN)
	var band_add: float = minf(spare * 0.5, band_max - band_min)
	var band: float = band_min + band_add
	spare -= band_add
	var gap_add: float = minf(spare, Layout.BOARD_GAP_MAX - Layout.BOARD_GAP_MIN)
	var gap: float = Layout.BOARD_GAP_MIN + gap_add
	spare -= gap_add
	var top: float = spare * 0.5

	_band = Rect2(column_x, top, content_w, band)
	var block: float = board + over
	view.position = Vector2(column_x + (content_w - block) * 0.5, top + band)
	view.size = Vector2(block, block)
	var inset: float = gap_s * 0.5
	var pad_top: float = top + band + block + gap
	pad.position = Vector2(column_x - inset, pad_top - inset)
	pad.size = Vector2(content_w + 2.0 * inset, 3.0 * key_h + 2.0 * gap_s + 2.0 * inset)


func _on_skin_changed(_skin: GameSkin) -> void:
	_layout()


func _watch_skins(service: Node) -> void:
	if _watched_service != null and is_instance_valid(_watched_service) \
			and _watched_service.is_connected(&"skin_changed", _on_skin_changed):
		_watched_service.disconnect(&"skin_changed", _on_skin_changed)
	_watched_service = service
	if service != null and service.has_signal(&"skin_changed"):
		service.connect(&"skin_changed", _on_skin_changed)
