extends Texture2D
## An icon as a Texture2D, drawn in code with no image behind it, so a Button
## can hold it in its icon property and tint it with the theme's icon colors
## for each state. The shape is drawn in white times the modulate the Button
## passes in. Made by Icons through ThemeFactory.icon_texture; screens never
## make one directly.
## Owner: ui-motion-artist.

var icon: StringName = &""
var side: float = Icons.SIZE_BUTTON


func _init(p_icon: StringName = &"", p_side: float = Icons.SIZE_BUTTON) -> void:
	icon = p_icon
	side = p_side


func _get_width() -> int:
	return roundi(side)


func _get_height() -> int:
	return roundi(side)


func _has_alpha() -> bool:
	return true


func _is_pixel_opaque(_x: int, _y: int) -> bool:
	return false


func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, _transpose: bool) -> void:
	Icons.draw_rid(to_canvas_item, icon, Rect2(pos, Vector2(side, side)), modulate)


func _draw_rect(to_canvas_item: RID, rect: Rect2, _tile: bool, modulate: Color, _transpose: bool) -> void:
	Icons.draw_rid(to_canvas_item, icon, rect, modulate)


func _draw_rect_region(to_canvas_item: RID, rect: Rect2, _src_rect: Rect2, modulate: Color, _transpose: bool, _clip_uv: bool) -> void:
	Icons.draw_rid(to_canvas_item, icon, rect, modulate)
