extends RefCounted
## The placeholder app icon, used until Bart picks the final Sudoku icon: one
## Sudoku box on a Pop electric blue tile. A white rounded square in the
## middle holds a 3 by 3 box outline in near black, with the center cell
## filled lemon. Behind it sits a quiet 3 by 3 grid of lighter blue lines.
## No letters, no digits. Everything is drawn in code; there is no image file.
## platform-dev renders it to PNG launcher icons at build time.
##
## Call the draw functions from inside a _draw() of canvas. rect is square and
## may be any size from 48 to 512 px.
##
## Adaptive layers use the Android 108 dp canvas: rect is the whole layer. The
## foreground and monochrome layers keep every vertex inside the safe zone, a
## centered circle 66/108 of the side across. The full icon is the visible
## 72 dp middle of the layers, on a rounded tile.
## Owner: ui-motion-artist.

## Pop's electric blue (button_primary_bg), DESIGN_SYSTEM.md section 9.
const BACKGROUND: Color = Color("#1A40D9")
## The quiet grid lines on the background, section 9.
const GRID: Color = Color("#4362E0")
## The rounded square that holds the box.
const TILE: Color = Color("#FFFFFF")
## The box outline, Pop's near black.
const LINE: Color = Color("#111111")
## The center cell, Pop's lemon.
const CENTER: Color = Color("#FFE45C")
## The one color of the monochrome layer.
const MONOCHROME: Color = Color("#FFFFFF")

## Full icon: corner radius of the blue tile, as a share of the side.
const FULL_CORNER: float = 0.22
## Adaptive icon: safe zone diameter as a share of the layer side.
const SAFE_ZONE: float = 66.0 / 108.0
## The visible part of an adaptive layer, as a share of its side.
const VISIBLE: float = 72.0 / 108.0
## Background grid: side and line weight, as shares of the layer side. The
## grid spans the safe zone; its lines are 1 percent of the 108 dp layer, which
## is 1.5 percent of the visible 72 dp.
const GRID_SIDE: float = 66.0 / 108.0
const GRID_WEIGHT: float = 0.01
## White rounded square: side as a share of the layer side, and its corner
## radius as a share of its own side. Its corners reach 31.2 dp from the
## center, inside the 33 dp safe zone radius.
const TILE_SIDE: float = 50.0 / 108.0
const TILE_CORNER: float = 0.2
## The 3 by 3 box: side as a share of the white square's side, and line
## weights as shares of the box side. The outer frame is heavier than the
## lines between cells, like the board's box lines.
const BOX_SIDE: float = 0.66
const BOX_OUTER: float = 0.085
const BOX_INNER: float = 0.045


## A filled polygon in icon pixels.
class Fill extends RefCounted:
	var points: PackedVector2Array
	var color: Color

	func _init(p_points: PackedVector2Array, p_color: Color) -> void:
		points = p_points
		color = p_color


# Public draw functions

## The complete full icon: a rounded blue tile with the grid and the box.
## Transparent outside the tile.
static func draw_full(canvas: CanvasItem, rect: Rect2) -> void:
	var item: RID = canvas.get_canvas_item()
	var corner: float = rect.size.x * FULL_CORNER
	_paint(item, [Fill.new(_rounded_square(rect.get_center(), rect.size.x, corner), BACKGROUND)])
	var layer: Rect2 = _layer_for_full(rect)
	_paint(item, _grid_fills(layer))
	_paint(item, _foreground_fills(layer))


## Adaptive background layer: fills rect with blue and the quiet grid.
static func draw_background(canvas: CanvasItem, rect: Rect2) -> void:
	_paint(canvas.get_canvas_item(), _background_fills(rect))


## Adaptive foreground layer: the white square with the box inside the safe
## zone, transparent everywhere else.
static func draw_foreground(canvas: CanvasItem, rect: Rect2) -> void:
	_paint(canvas.get_canvas_item(), _foreground_fills(rect))


## Adaptive monochrome layer: the white square's silhouette in one opaque
## color, with all nine cells cut out so the box reads as lines.
static func draw_monochrome(canvas: CanvasItem, rect: Rect2) -> void:
	_paint(canvas.get_canvas_item(), _monochrome_fills(rect))


## Every vertex the foreground and monochrome layers draw, in rect's
## coordinates.
static func foreground_outline(rect: Rect2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for fill: Fill in _foreground_fills(rect):
		points.append_array(fill.points)
	for fill: Fill in _monochrome_fills(rect):
		points.append_array(fill.points)
	return points


# Layers

## The 108 dp layer whose visible 72 dp middle is rect.
static func _layer_for_full(rect: Rect2) -> Rect2:
	var side: float = rect.size.x / VISIBLE
	return Rect2(rect.get_center() - Vector2(side, side) * 0.5, Vector2(side, side))


static func _background_fills(rect: Rect2) -> Array[Fill]:
	var fills: Array[Fill] = [Fill.new(_box_points(rect.position, rect.end), BACKGROUND)]
	fills.append_array(_grid_fills(rect))
	return fills


## Four horizontal and four vertical lines: one Sudoku box, centered.
static func _grid_fills(rect: Rect2) -> Array[Fill]:
	var fills: Array[Fill] = []
	var side: float = rect.size.x * GRID_SIDE
	var weight: float = rect.size.x * GRID_WEIGHT
	var corner: Vector2 = rect.get_center() - Vector2(side, side) * 0.5
	for k: int in 4:
		var at: float = side * float(k) / 3.0
		var across: Vector2 = corner + Vector2(-weight * 0.5, at - weight * 0.5)
		fills.append(Fill.new(_box_points(across, across + Vector2(side + weight, weight)), GRID))
		var down: Vector2 = corner + Vector2(at - weight * 0.5, -weight * 0.5)
		fills.append(Fill.new(_box_points(down, down + Vector2(weight, side + weight)), GRID))
	return fills


## The white square, the lemon center cell, then the box lines on top.
static func _foreground_fills(rect: Rect2) -> Array[Fill]:
	var fills: Array[Fill] = [Fill.new(_tile_points(rect), TILE)]
	var cells: Array[Rect2] = _cells(rect)
	fills.append(Fill.new(_box_points(cells[4].position, cells[4].end), CENTER))
	for line: Rect2 in _box_lines(rect):
		fills.append(Fill.new(_box_points(line.position, line.end), LINE))
	return fills


## The white square minus the nine cells. A polygon cannot hold a hole, so
## the square is first split by a vertical cut through each column of cells;
## then every cell crosses the edge of the pieces it touches and clips
## cleanly.
static func _monochrome_fills(rect: Rect2) -> Array[Fill]:
	var pieces: Array[PackedVector2Array] = [_tile_points(rect)]
	var cells: Array[Rect2] = _cells(rect)
	for column: int in 3:
		pieces = _split_at_x(pieces, cells[column].get_center().x)
	for cell: Rect2 in cells:
		var cutter: PackedVector2Array = _box_points(cell.position, cell.end)
		var kept: Array[PackedVector2Array] = []
		for piece: PackedVector2Array in pieces:
			kept.append_array(Geometry2D.clip_polygons(piece, cutter))
		pieces = kept
	var fills: Array[Fill] = []
	for piece: PackedVector2Array in pieces:
		fills.append(Fill.new(piece, MONOCHROME))
	return fills


# Geometry

static func _tile_points(rect: Rect2) -> PackedVector2Array:
	var side: float = rect.size.x * TILE_SIDE
	return _rounded_square(rect.get_center(), side, side * TILE_CORNER)


## The box's outer frame and the two lines each way between its cells.
static func _box_lines(rect: Rect2) -> Array[Rect2]:
	var side: float = rect.size.x * TILE_SIDE * BOX_SIDE
	var outer: float = side * BOX_OUTER
	var inner: float = side * BOX_INNER
	var cell: float = (side - 2.0 * outer - 2.0 * inner) / 3.0
	var start: Vector2 = rect.get_center() - Vector2(side, side) * 0.5
	var lines: Array[Rect2] = []
	var offsets: Array[float] = [0.0, outer + cell, outer + 2.0 * cell + inner, side - outer]
	var weights: Array[float] = [outer, inner, inner, outer]
	for k: int in 4:
		lines.append(Rect2(start + Vector2(0.0, offsets[k]), Vector2(side, weights[k])))
		lines.append(Rect2(start + Vector2(offsets[k], 0.0), Vector2(weights[k], side)))
	return lines


## The nine cells inside the box lines, in reading order, so index 4 is the
## center cell.
static func _cells(rect: Rect2) -> Array[Rect2]:
	var side: float = rect.size.x * TILE_SIDE * BOX_SIDE
	var outer: float = side * BOX_OUTER
	var inner: float = side * BOX_INNER
	var cell: float = (side - 2.0 * outer - 2.0 * inner) / 3.0
	var start: Vector2 = rect.get_center() - Vector2(side, side) * 0.5
	var cells: Array[Rect2] = []
	for row: int in 3:
		for column: int in 3:
			var at: Vector2 = Vector2(outer + float(column) * (cell + inner), outer + float(row) * (cell + inner))
			cells.append(Rect2(start + at, Vector2(cell, cell)))
	return cells


static func _rounded_square(center: Vector2, side: float, corner: float) -> PackedVector2Array:
	var half: float = side * 0.5 - corner
	var steps: int = clampi(roundi(corner * 0.75), 6, 24)
	var centers: Array[Vector2] = [
		center + Vector2(half, half), center + Vector2(-half, half),
		center + Vector2(-half, -half), center + Vector2(half, -half),
	]
	var points: PackedVector2Array = PackedVector2Array()
	for k: int in 4:
		for i: int in steps + 1:
			var angle: float = PI * 0.5 * (float(k) + float(i) / float(steps))
			points.append(centers[k] + Vector2(cos(angle), sin(angle)) * corner)
	return points


static func _box_points(top_left: Vector2, bottom_right: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		top_left, Vector2(bottom_right.x, top_left.y), bottom_right, Vector2(top_left.x, bottom_right.y),
	])


## Splits every piece along the vertical line at x.
static func _split_at_x(pieces: Array[PackedVector2Array], x: float) -> Array[PackedVector2Array]:
	var far: float = 1.0e5
	var left: PackedVector2Array = PackedVector2Array([Vector2(x - far, -far), Vector2(x, -far), Vector2(x, far), Vector2(x - far, far)])
	var right: PackedVector2Array = PackedVector2Array([Vector2(x, -far), Vector2(x + far, -far), Vector2(x + far, far), Vector2(x, far)])
	var result: Array[PackedVector2Array] = []
	for piece: PackedVector2Array in pieces:
		result.append_array(Geometry2D.intersect_polygons(piece, left))
		result.append_array(Geometry2D.intersect_polygons(piece, right))
	return result


# Drawing

## Fills each polygon and runs a thin antialiased line around it, which
## smooths the edge the polygon fill leaves jagged. Works on any canvas item,
## so the layers can also be drawn onto a texture's item.
static func _paint(item: RID, fills: Array[Fill]) -> void:
	for fill: Fill in fills:
		if fill.points.size() < 3 or absf(_area(fill.points)) < 0.05:
			continue
		var indices: PackedInt32Array = Geometry2D.triangulate_polygon(fill.points)
		if indices.is_empty():
			continue
		RenderingServer.canvas_item_add_triangle_array(item, indices, fill.points, PackedColorArray([fill.color]))
		var ring: PackedVector2Array = fill.points.duplicate()
		ring.append(fill.points[0])
		RenderingServer.canvas_item_add_polyline(item, ring, PackedColorArray([fill.color]), 1.0, true)


static func _area(points: PackedVector2Array) -> float:
	var total: float = 0.0
	for i: int in points.size():
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		total += a.x * b.y - b.x * a.y
	return total * 0.5
