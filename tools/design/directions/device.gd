extends RefCounted
## Device frame for the Phase 1 design prototypes: the screen every prototype
## is drawn for, its safe area, and the phones we quote sizes for.
## Prototype data in tools/, never shipped. Owner: senior-graphic-designer.
##
## Design units: the project's base viewport is 1080 by 2400 with the
## canvas_items stretch mode, so one design unit is one pixel on a phone that
## is 1080 px wide, and the layout scales with the screen width on others.

## Size every screen prototype is drawn and captured at, in design units.
const SCREEN_SIZE: Vector2i = Vector2i(1080, 2400)

## Safe area kept free of controls and text (status bar with a camera cutout
## at the top, gesture bar at the bottom). Backgrounds still run edge to edge.
const SAFE_TOP: float = 96.0
const SAFE_BOTTOM: float = 56.0

## Typical phone: 1080 by 2400 px at density 2.625 (420 dpi), 411 dp wide.
const TYPICAL_PHONE_DP_WIDTH: float = 411.43
const TYPICAL_PHONE_PX_WIDTH: float = 1080.0

## Smallest phone we support: 360 dp wide in portrait. The common low end
## version is 720 px wide at density 2.0, which is also the fewest pixels we
## have to draw a candidate with.
const SMALLEST_PHONE_DP_WIDTH: float = 360.0
const SMALLEST_PHONE_PX_WIDTH: float = 720.0

## One dp is 1/160 inch.
const MM_PER_DP: float = 25.4 / 160.0


## Converts design units to dp on a phone of the given width in dp.
static func units_to_dp(units: float, phone_dp_width: float) -> float:
	return units * phone_dp_width / float(SCREEN_SIZE.x)


## Converts design units to device pixels on a phone of the given pixel width.
static func units_to_px(units: float, phone_px_width: float) -> float:
	return units * phone_px_width / float(SCREEN_SIZE.x)


## The rectangle inside the safe area for a screen of the given size.
static func safe_rect(screen_size: Vector2) -> Rect2:
	return Rect2(0.0, SAFE_TOP, screen_size.x, screen_size.y - SAFE_TOP - SAFE_BOTTOM)
