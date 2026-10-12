class_name UiSizes
extends RefCounted
## The screen sizes of docs/DESIGN_SYSTEM.md section 7 that are not in
## Layout (section 4.6) or in the skin, in dp, in one place so no screen
## repeats a number. Spacing, outlines and radii come from the skin; touch
## sizes, icon and close faces, tall buttons and the header row from Layout.
## Owner: ui-systems-dev.

## Dialog buttons (7.4) and other buttons with a 48 dp face.
const BUTTON_DIALOG: float = 48.0
## Level select rows (7.3) and settings rows (7.11).
const ROW: float = 64.0
## Skin option cards (7.11).
const SKIN_OPTION_H: float = 120.0
## Level select pips (7.3).
const PIP: float = 10.0
## Lessons completed squares on the stats screen (7.10).
const LESSON_SQUARE: float = 24.0
## Dialog card width, at most (4.9, 7.4).
const DIALOG_MAX_W: float = 328.0
## The main menu and first launch hero, smallest and largest (7.1, 7.2).
const HERO_MIN: float = 64.0
const HERO_MAX: float = 200.0
## The app icon foreground's art fills a 66 dp safe zone of a 108 dp layer
## (7.1), so the hero box is drawn with a layer this many times its side.
const HERO_LAYER: float = 108.0 / 66.0