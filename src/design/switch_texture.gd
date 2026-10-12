extends Texture2D
## The Switch look (DESIGN_SYSTEM.md section 5, SWITCH), drawn in code with no
## image behind it: an OFF or ON caption, then the track with its outline and
## the square knob, left when off and right when on. ThemeFactory makes one
## for each state and gives them to CheckButton as its check icons, so on and
## off differ by the knob's side and the caption as well as by color.
## Owner: ui-motion-artist.

const TRACK_W: float = 44.0
const TRACK_H: float = 26.0
const KNOB: float = 20.0

var on: bool = false
var track: Color = Color.WHITE
var knob: Color = Color.WHITE
var outline: Color = Color.BLACK
var outline_w: float = 2.0
var radius: float = 5.0
var caption_font: Font = null
var caption_size: int = 10
var caption_color: Color = Color.BLACK
var caption_gap: float = 8.0
var on_text: String = "ON"
var off_text: String = "OFF"


## Width kept for the caption: the wider of the two, so the track never moves.
func caption_width() -> float:
	if caption_font == null:
		return 0.0
	var on_w: float = caption_font.get_string_size(on_text, HORIZONTAL_ALIGNMENT_LEFT, -1, caption_size).x
	var off_w: float = caption_font.get_string_size(off_text, HORIZONTAL_ALIGNMENT_LEFT, -1, caption_size).x
	return ceilf(maxf(on_w, off_w))


func _get_width() -> int:
	return ceili(caption_width() + caption_gap + TRACK_W)


func _get_height() -> int:
	return ceili(TRACK_H)


func _has_alpha() -> bool:
	return true


func _is_pixel_opaque(_x: int, _y: int) -> bool:
	return false


func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, _transpose: bool) -> void:
	_paint(to_canvas_item, Rect2(pos, Vector2(_get_width(), _get_height())), modulate)


func _draw_rect(to_canvas_item: RID, rect: Rect2, _tile: bool, modulate: Color, _transpose: bool) -> void:
	_paint(to_canvas_item, rect, modulate)


func _draw_rect_region(to_canvas_item: RID, rect: Rect2, _src_rect: Rect2, modulate: Color, _transpose: bool, _clip_uv: bool) -> void:
	_paint(to_canvas_item, rect, modulate)


## Draws into rect, keeping the natural size, centered vertically. Only the
## modulate's opacity is used, so the skin colors stay exact.
func _paint(item: RID, rect: Rect2, modulate: Color) -> void:
	var fade: float = modulate.a
	var top: float = rect.position.y + (rect.size.y - TRACK_H) * 0.5
	var caption_w: float = caption_width()
	if caption_font != null:
		var text: String = on_text if on else off_text
		var text_w: float = caption_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, caption_size).x
		var baseline: float = top + TRACK_H * 0.5 + (caption_font.get_ascent(caption_size) - caption_font.get_descent(caption_size)) * 0.5
		var x: float = rect.position.x + caption_w - text_w
		caption_font.draw_string(item, Vector2(x, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, caption_size, _faded(caption_color, fade))
	var track_rect: Rect2 = Rect2(rect.position.x + caption_w + caption_gap, top, TRACK_W, TRACK_H)
	_box(_faded(track, fade), _faded(outline, fade), radius).draw(item, track_rect)
	var inset: float = (TRACK_H - KNOB) * 0.5
	var knob_x: float = track_rect.end.x - inset - KNOB if on else track_rect.position.x + inset
	# The knob's corners follow the track's, inset by the same gap.
	_box(_faded(knob, fade), _faded(outline, fade), maxf(0.0, radius - inset)).draw(item, Rect2(knob_x, top + inset, KNOB, KNOB))


func _box(fill: Color, edge: Color, corner: float) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(maxi(1, roundi(outline_w)))
	box.set_corner_radius_all(roundi(corner))
	box.corner_detail = 8
	box.anti_aliasing = true
	return box


static func _faded(color: Color, alpha: float) -> Color:
	return Color(color, color.a * alpha)
