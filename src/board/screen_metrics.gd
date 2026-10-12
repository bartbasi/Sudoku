class_name ScreenMetrics extends RefCounted
## Units and the safe area (docs/ARCHITECTURE.md sections 2 and 8). One canvas
## unit is one dp on every device: apply_dp_scale sets that up, and every
## size in docs/DESIGN_SYSTEM.md is then used as written.
## Owner: board-input-dev. Used by every screen.

## Android's baseline density: 160 dots per inch is one pixel per dp.
const BASELINE_DPI: float = 160.0


## Device pixels per dp: DisplayServer.screen_get_dpi() / 160 on Android, 1.0
## on desktop, where the default window (411 by 914 px) is a typical phone in dp.
static func density() -> float:
	if not OS.has_feature("android"):
		return 1.0
	var dpi: int = DisplayServer.screen_get_dpi()
	if dpi <= 0:
		return 1.0
	return float(dpi) / BASELINE_DPI


## Sets window.content_scale_size to the window size in dp, so one unit is
## one dp. Call at startup and on every size_changed.
static func apply_dp_scale(window: Window) -> void:
	if window == null:
		return
	var d: float = density()
	var px: Vector2i = window.size
	window.content_scale_size = Vector2i(maxi(1, roundi(float(px.x) / d)), maxi(1, roundi(float(px.y) / d)))


## The device safe area (clear of notches, cutouts, the status bar and the
## gesture bar), in units (dp), in viewport's coordinates. On desktop, and
## whenever the system reports no safe area, the whole visible rect.
static func safe_rect(viewport: Viewport) -> Rect2:
	if viewport == null:
		return Rect2()
	var visible: Rect2 = viewport.get_visible_rect()
	if not OS.has_feature("mobile"):
		return visible
	var safe_px: Rect2i = DisplayServer.get_display_safe_area()
	if safe_px.size.x <= 0 or safe_px.size.y <= 0:
		return visible
	var window: Window = viewport as Window
	var origin: Vector2i = window.position if window != null else Vector2i.ZERO
	var local_px: Rect2 = Rect2(Vector2(safe_px.position - origin), Vector2(safe_px.size))
	var units: Rect2 = viewport.get_final_transform().affine_inverse() * local_px
	var clipped: Rect2 = units.intersection(visible)
	return clipped if clipped.has_area() else visible


## Device pixels per unit, for snapping lines to whole pixels. 1.0 when there
## is no window yet.
static func px_per_unit() -> float:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return 1.0
	var scale: float = tree.root.get_final_transform().x.x
	return scale if scale > 0.0 else 1.0
