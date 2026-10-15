class_name PlayArea extends Control
## The board, the pad and the controller that joins them to a session, laid
## out in one of the window arrangements of docs/DESIGN_SYSTEM.md 4.11
## (docs/ARCHITECTURE.md section 8; the stacked rules in 4.6, 4.7 and 4.8).
## Normal play and the lesson player both use it.
##
## Its rect is the whole safe rect. Inside it, page_margin in from every
## side, is the content box, and Layout.arrangement() on that box picks:
##
## STACKED: in a column min(width, COLUMN_MAX) wide and centered, top to
## bottom: the header row (header_height: the play screen's HUD goes there,
## the lesson player has none), the band, the board with its outer line and
## shadow, the gap and the three rows of keys. Height is shared as in 4.7:
## start from BAND_MIN, BOARD_GAP_MIN and KEY_MIN; the board takes the rest,
## up to the column width; leftover height grows the keys to KEY_MAX, then
## half of what is left grows the band up to BAND_MAX and the rest grows the
## gap up to BOARD_GAP_MAX; anything still left goes equally above and below.
##
## In both arrangements the pad's digit keys are never wider than
## KEY_ASPECT_MAX times their height: on wide columns the pad narrows and is
## centered in its column (DESIGN_SYSTEM.md 4.7).
##
## SIDE: the board at the left, as large as Layout.side_board gives, centered
## vertically when its width limits it; SIDE_GAP; then the side column,
## COLUMN_MIN to SIDE_MAX wide, holding the header row, the band and the pad.
## In the side column the keys grow first, to KEY_MAX, then the band, to
## BAND_MAX; anything left goes equally above and below the column. The board
## and the side column are centered as a group.
##
## TOO_SMALL: laid out stacked with every size clamped at zero or above. The
## App covers it with the too small layer.
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

## Height of the header row reserved above the band: Layout.HEADER_ROW on
## the play screen, 0 on the lesson player. Below zero counts as zero.
var header_height: float = 0.0:
	set(value):
		header_height = maxf(0.0, value)
		_layout()

var _band_height: float = -1.0
var _band: Rect2 = Rect2()
var _header: Rect2 = Rect2()
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


## The Layout.Arrangement for the current rect: STACKED, SIDE or TOO_SMALL.
## STACKED when there is no skin yet.
func arrangement() -> int:
	var current: GameSkin = Support.skin_for(self, skin)
	if current == null:
		return Layout.Arrangement.STACKED
	return Layout.arrangement(_content(current), current)


## Where the play screen puts its header row (the HUD). Zero height when
## header_height is 0.
func header_rect_global() -> Rect2:
	return get_global_transform() * _header


## Show candidates (GDD 4.5): off hides the rings and the mode buttons.
## The play screen calls it; lessons never do, so they always show both.
func set_show_candidates(on: bool) -> void:
	view.show_ring = on
	pad.set_mode_visible(on)


## The band below the header row: the play screen puts the level sticker
## there; the lesson player puts its lesson card there.
func band_rect_global() -> Rect2:
	return get_global_transform() * _band


## The info zone: the header row and the band together, minus space_s at the
## bottom. The hint panel and the full board message cover exactly this.
func info_zone_rect_global() -> Rect2:
	return get_global_transform() * info_zone_rect()


## The band's height. The lesson player sizes it to its card; the play
## screen leaves the Layout default (BAND_MIN growing to BAND_MAX). Zero or
## less goes back to that default.
func set_band_height(height: float) -> void:
	_band_height = height if height > 0.0 else -1.0
	_layout()


## The band in local coordinates.
func band_rect() -> Rect2:
	return _band


## The header row in local coordinates.
func header_rect() -> Rect2:
	return _header


## The info zone in local coordinates.
func info_zone_rect() -> Rect2:
	var current: GameSkin = Support.skin_for(self, skin)
	var gap: float = current.space_s if current != null else 0.0
	var height: float = maxf(0.0, _header.size.y + _band.size.y - gap)
	return Rect2(_header.position, Vector2(_header.size.x, height))


## The content box: the rect inset by page_margin on every side, never
## negative.
func _content(current: GameSkin) -> Rect2:
	var margin: float = current.page_margin
	return Rect2(margin, margin, maxf(0.0, size.x - 2.0 * margin), maxf(0.0, size.y - 2.0 * margin))


func _layout() -> void:
	var current: GameSkin = Support.skin_for(self, skin)
	if current == null or view == null:
		return
	var content: Rect2 = _content(current)
	if Layout.arrangement(content, current) == Layout.Arrangement.SIDE:
		_layout_side(current, content)
	else:
		_layout_stacked(current, content)


func _layout_stacked(current: GameSkin, content: Rect2) -> void:
	var gap_s: float = current.space_s
	var column_w: float = minf(content.size.x, Layout.COLUMN_MAX)
	var column_x: float = content.position.x + (content.size.x - column_w) * 0.5
	var over: float = current.line_outer_w + current.shadow_offset
	var band_min: float = Layout.BAND_MIN if _band_height < 0.0 else _band_height
	var band_max: float = Layout.BAND_MAX if _band_height < 0.0 else _band_height
	var controls_min: float = 3.0 * Layout.KEY_MIN + 2.0 * gap_s
	var fixed: float = header_height + band_min + over + Layout.BOARD_GAP_MIN + controls_min
	var board: float = maxf(0.0, minf(column_w - over, content.size.y - fixed))
	var spare: float = maxf(0.0, content.size.y - fixed - board)
	var key_h: float = Layout.KEY_MIN + minf(spare / 3.0, Layout.KEY_MAX - Layout.KEY_MIN)
	spare -= 3.0 * (key_h - Layout.KEY_MIN)
	var band_add: float = minf(spare * 0.5, band_max - band_min)
	spare -= band_add
	var gap_add: float = minf(spare, Layout.BOARD_GAP_MAX - Layout.BOARD_GAP_MIN)
	spare -= gap_add
	var top: float = content.position.y + spare * 0.5

	_header = Rect2(column_x, top, column_w, header_height)
	_band = Rect2(column_x, _header.end.y, column_w, band_min + band_add)
	var block: float = board + over
	view.position = Vector2(column_x + (column_w - block) * 0.5, _band.end.y)
	view.size = Vector2(block, block)
	_place_pad(current, column_x, _band.end.y + block + Layout.BOARD_GAP_MIN + gap_add, column_w, key_h)


func _layout_side(current: GameSkin, content: Rect2) -> void:
	var gap_s: float = current.space_s
	var over: float = current.line_outer_w + current.shadow_offset
	var block: float = minf(Layout.side_board(content, current) + over, content.size.y)
	var side_w: float = clampf(content.size.x - block - Layout.SIDE_GAP, Layout.COLUMN_MIN, Layout.SIDE_MAX)
	var group_w: float = block + Layout.SIDE_GAP + side_w
	var left: float = content.position.x + maxf(0.0, content.size.x - group_w) * 0.5
	view.position = Vector2(left, content.position.y + (content.size.y - block) * 0.5)
	view.size = Vector2(block, block)

	var band_min: float = Layout.BAND_MIN if _band_height < 0.0 else _band_height
	var band_max: float = Layout.BAND_MAX if _band_height < 0.0 else _band_height
	var controls_min: float = 3.0 * Layout.KEY_MIN + 2.0 * gap_s
	var spare: float = content.size.y - header_height - band_min - controls_min
	var key_h: float = Layout.KEY_MIN + clampf(spare / 3.0, 0.0, Layout.KEY_MAX - Layout.KEY_MIN)
	spare -= 3.0 * (key_h - Layout.KEY_MIN)
	var band_add: float = clampf(spare, 0.0, band_max - band_min)
	spare -= band_add
	var side_x: float = left + block + Layout.SIDE_GAP
	var top: float = content.position.y + maxf(0.0, spare) * 0.5

	_header = Rect2(side_x, top, side_w, header_height)
	_band = Rect2(side_x, _header.end.y, side_w, band_min + band_add)
	_place_pad(current, side_x, _band.end.y, side_w, key_h)


## The pad in a column from x to x + width, from top down: three rows of
## key_h with space_s between them. Its faces are as wide as the column
## allows, but no wider than keys of KEY_ASPECT_MAX times key_h need
## (Layout.pad_faces_width); a narrowed pad is centered in the column. The
## pad's rect is the faces and their shadow grown by half a key gap, so every
## touch area reaches 48 dp.
func _place_pad(current: GameSkin, x: float, top: float, width: float, key_h: float) -> void:
	var gap_s: float = current.space_s
	var inset: float = gap_s * 0.5
	var faces_w: float = Layout.pad_faces_width(width, key_h, current)
	var block: float = faces_w + current.shadow_offset
	var left: float = x + (width - block) * 0.5
	pad.position = Vector2(left - inset, top - inset)
	pad.size = Vector2(block + 2.0 * inset, 3.0 * key_h + 2.0 * gap_s + 2.0 * inset)


func _on_skin_changed(_skin: GameSkin) -> void:
	_layout()


func _watch_skins(service: Node) -> void:
	if _watched_service != null and is_instance_valid(_watched_service) \
			and _watched_service.is_connected(&"skin_changed", _on_skin_changed):
		_watched_service.disconnect(&"skin_changed", _on_skin_changed)
	_watched_service = service
	if service != null and service.has_signal(&"skin_changed"):
		service.connect(&"skin_changed", _on_skin_changed)
