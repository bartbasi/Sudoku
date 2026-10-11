# Brief: grid-cell-artist, Phase 1 board prototypes

From: senior-graphic-designer. Date: 2026-10-11. Launched by the Development Manager.

## Task

Build the board for the three Phase 1 design directions (Gridline, Pebble, Pop), each in light and dark, as real Godot scenes drawn in code. Then build two review sheets that use those boards: the ring close-up sheet and the state sheet. ui-motion-artist embeds your boards in the four screens of each direction, so the board contract below is exact. These are prototypes: they live in tools/ and never ship. The chosen direction is rebuilt in src/skins/ in a later phase.

No animation in Phase 1. Every image is static.

## Read first

- CLAUDE.md
- docs/BRIEF.md, sections 3 and 8
- docs/GDD.md, sections 2 (board, selection, highlight states), 4 (candidate ring and its four states), 5.2 (the Auto Cross mark), 6.1 (conflicts)
- docs/design/direction-gridline.md, direction-pebble.md, direction-pop.md: the look of each direction
- docs/design/ring-layouts.md: the three ring layouts
- The shared data files listed below, top to bottom. Their comments are part of this brief.

## Files you may touch

- Everything under `tools/design/directions/board/`. Create the folder.

Phase 1 ownership, decided by the Development Manager:

- `tools/design/directions/board/` belongs to you: board visuals for all three directions in light and dark, and the ring close-up and state sheet scenes.
- `tools/design/directions/ui/` belongs to ui-motion-artist: theme, HUD, number pad, icons and the four screens per direction, which embed your boards.
- `src/design/app_icon.gd` and its test in `tests/design/` belong to ui-motion-artist.
- Everything else in `tools/design/` belongs to the senior-graphic-designer: the shared data, the contrast checker, the sample checker and the capture tool.

You must not edit any other file, including the shared data. If you need a token, a geometry function or sample content that is not there, use the closest existing one, keep going, and list what you need in your report. Never hardcode a color, size or font in its place.

## Shared data (read only)

All in `tools/design/directions/`. Load them with `preload`; none has a class_name.

| File | What it gives you |
| --- | --- |
| `palettes.gd` | `Palettes.palette(direction, dark)`: every color. `Palettes.shape(direction)`: line weights, radii, gaps, mark sizes. `Palettes.type_style(direction, role)`: fonts and sizes. |
| `ring_layouts.gd` | The three ring layouts and all board geometry: `board_square()`, `board_scale()`, `cell_rect()`, `box_rect()`, `ring_box()`, `candidate_font_size()`, `slot_center()`, `slot_rect()`, `mark_rect()`. |
| `sample_state.gd` | `BoardState` (digits, hand and Auto Cross marks, selection, mode, hint cells, and `flags()`, `cell_bg()`, `is_conflict()`), plus `play_board()`, `closeup_board()`, `hint_board()`, `conflict_board()`, `lesson_board()`, `state_sheet()`, `CLOSEUP_BOX`. |
| `fonts.gd` | `Fonts.draw_centered()` to center a digit on its visible shape. Get fonts through `TypeStyle.font()` or `font_at()`, never from the theme or `ThemeDB`, so the Inter comparison capture works. |
| `device.gd` | Screen size, safe area, and the reference phones. |

Directions are the strings `"gridline"`, `"pebble"`, `"pop"` (`Palettes.DIRECTIONS`).

## 1. The board preview scenes

Paths, one per direction:

- `res://tools/design/directions/board/gridline/board.tscn`
- `res://tools/design/directions/board/pebble/board.tscn`
- `res://tools/design/directions/board/pop/board.tscn`

You may share one script between them (for example with an exported `direction` set in each scene).

### Contract

- Root node: `Control`, with a statically typed script.
- Properties, all typed, all settable before the node enters the tree, and redrawing when changed later:
  - `dark: bool = false`
  - `ring_layout: int = RingLayouts.DEFAULT_LAYOUT`
  - `state: SampleState.BoardState = null`. Null means `SampleState.play_board()`.
- Size: the board is the largest square that fits the control's rect, centered (`RingLayouts.board_square(size)`). The caller sets the size; the board never sets its own. At the play screen size the square side equals `Palettes.shape(direction).board_size`. At any other side, scale every shape token by `RingLayouts.board_scale(direction, square)`; the geometry functions already do.
- Overhang: lines-style boards draw the outer line centered on the square's edge, so half of it falls outside. Pop also draws its hard shadow outside (offset `shadow_offset`). Pebble's soft shadow may spread `shadow_blur` beyond the tray. Nothing else leaves the square.
- Method: `func cell_rect(index: int) -> Rect2`, in the control's local coordinates (`RingLayouts.cell_rect(direction, RingLayouts.board_square(size), index)`).
- No input handling, no game rules. It draws the state it is given.
- Performance: draw the whole board from one `_draw()` (or a few CanvasItems by layer). Never one node per cell or candidate.

### What to draw, in this order

1. Board frame: lines style (Gridline, Pop) is a square board on `board_bg`; tiles style (Pebble) is the tray (`board_bg`, radius `board_radius`), box cards (`line_cell` color, radius `box_radius`, from `RingLayouts.box_rect()`) and tiles (radius `cell_radius`). Pop adds its hard shadow, Pebble its soft shadow, using the `shadow` token.
2. Cell backgrounds from `state.cell_bg(i)`: SELECTED `cell_selected_bg`, CONFLICT `cell_conflict_bg`, HINT_TARGET `cell_hint_target_bg`, HINT_REASON `cell_hint_reason_bg`, SAME_DIGIT `cell_same_digit_bg`, PEER `cell_peer_bg`, PLAIN `cell_bg`.
3. Lines (lines style only): cell lines `line_cell_w` in `line_cell`, box lines `line_box_w` in `line_box`, outer line `line_outer_w` in `line_outer`, all centered on the pitch boundaries. Box lines must read clearly heavier than cell lines.
4. Content:
   - A cell with a digit: the digit centered on the cell with `Fonts.draw_centered()`, size `type_style(..., ROLE_GIVEN or ROLE_PLACED).size` times the cell rect's side. Color `digit_given` or `digit_placed`, or `digit_conflict` when `state.is_conflict(i)`. The ring is hidden, even if marks are stored underneath.
   - An empty cell: its ring. Font from `type_style(..., ROLE_CANDIDATE).font_at(size)` with `size = RingLayouts.candidate_font_size(direction, ring_layout, ring_box.size.x, font)` (measure with any size of the same style, then rebuild the font at the result). Each digit at `RingLayouts.slot_center()`, drawn with `Fonts.draw_centered()`, color `candidate_open`, or `candidate_crossed` when it is marked.
   - Crossed by hand (`state.is_crossed`): an X, both diagonals of `RingLayouts.mark_rect()`, stroke `x_stroke_w`, color `x_mark`.
   - Crossed by Auto Cross (`state.is_auto_crossed`): one rising slash, from the bottom left to the top right of `mark_rect()`, same stroke, color `x_mark_auto`. Same weight and color family for both is fine; the shape is the difference (GDD 5.2).
   - Restored by hand looks exactly like open. There is no field for it.
5. Marks, on top, using `state.flags(i)`. They sit in the band between the cell edge and the ring box, so they never cover a candidate, and each keeps its shape in every combination:
   - Conflict (`STATE_CONFLICT`, only on cells with a digit): a bar under the digit, length `conflict_bar_len` times the cell side, weight `conflict_bar_w`, its center 84 percent of the way down the cell, color `conflict_marker`.
   - Hint target: four corner brackets, each arm `bracket_len` times the cell side, weight `marker_w`, starting `selected_outline_w / 2` inside the cell edge, color `hint_target_marker`.
   - Hint reason (also the cells a lesson screen marks): four ticks centered on the four sides, length `tick_len` times the cell side, same weight and inset, color `hint_reason_marker`.
   - Selection frame, drawn last over everything: centered on the cell edge (the pitch rect for lines, the tile edge for tiles), weight `selected_outline_w`, color `selected_outline`. Solid in `MODE_PLACE`. Dashed in `MODE_CROSS_OUT`, dashes `selected_dash` long with `selected_gap` gaps, laid out from each corner so all four corners are drawn. This is how the selected cell shows the mode (GDD 2.3).
   - Peer and same digit are color only. That is allowed (GDD 2.3).

Line caps, dash ends and small flourishes follow each direction's write-up (round ends for Pebble, square for Gridline and Pop). Positions and sizes come only from the shared geometry and tokens.

## 2. The ring close-up sheet

Path: `res://tools/design/directions/board/ring_closeup.tscn`

- Root: `Control`. Properties: `ring_layout: int`, `px_per_unit: float`. The capture tool renders it with `px_per_unit` 1.0 (true size on a 1080 px wide phone) and 720 / 1080 (true size on the smallest supported phone, 720 px wide).
- Method: `func sheet_size() -> Vector2i`, valid as soon as the properties are set, before the node enters the tree. The capture renders exactly that size, at most 4096 by 4096.
- Content: three rows (Gridline, Pebble, Pop) by two columns (light, dark). Each tile shows `SampleState.CLOSEUP_BOX` of `SampleState.closeup_board()`, drawn by that direction's board scene at side `board_size * px_per_unit`, cropped to `RingLayouts.box_rect(direction, board_square, CLOSEUP_BOX).grow(12 * px_per_unit)`. Behind the crop, the direction's `app_bg`. Above each tile a one-line label, for example "Pebble dark". At the top one title line: the layout name from `RingLayouts.NAMES` and "true size on a 1080 px wide phone" or "720 px". Margins and gaps 24 px; labels and title in Gridline light `text` on Gridline light `app_bg`, `ROLE_LABEL` style.
- No scaling anywhere: one design unit times `px_per_unit` is one pixel. The easiest way is to instance each board scene at its full side inside a `Control` with `clip_contents = true`, offset so only the crop shows.

## 3. The state sheet

Path: `res://tools/design/directions/board/state_sheet.tscn`

- Root: `Control`. Properties: `direction: String`, `dark: bool`, `ring_layout: int`. The capture tool sets its size to 1080 by 2640.
- Content: on the direction's `app_bg`, for each entry of `SampleState.state_sheet()` (two of them): its title (`ROLE_LABEL`, `text`), its notes (`ROLE_BODY` at 30 units, `text_muted`), one hint line "Hint: {technique}. {text} {lesson}" (lesson only when not empty), then that board at the direction's `board_size`, centered across the width. Text at `screen_margin`.
- It shows every state and the hard combinations: selected in both modes, hint target and reason, conflict on a given and on placed digits, same digit, hand X next to Auto Cross marks, and selected plus conflict plus hint target on one cell.

## Contract with ui-motion-artist

ui-motion-artist relies on exactly this:

- Board scene paths: `res://tools/design/directions/board/<direction>/board.tscn`, direction one of `gridline`, `pebble`, `pop`.
- Root `Control`; properties `dark: bool`, `ring_layout: int`, `state: SampleState.BoardState` (null means the play board); set before or after entering the tree.
- The board fills the largest centered square of its rect. The screen sizes it to `Palettes.shape(direction).board_size` square and leaves room for the overhang (half the outer line, Pop's shadow, Pebble's soft shadow).
- `cell_rect(index)` gives a cell's rect in the board's local coordinates.
- The screens pass `SampleState.play_board()` on play and `SampleState.lesson_step().board` on lesson.

The screens the capture tool expects from ui-motion-artist are `res://tools/design/directions/ui/<direction>/<screen>.tscn` for `play`, `lesson`, `stats` and `complete`, root `Control` with `dark` and `ring_layout`. That is their work, not yours.

## How you prove it is done

Run each of these and put the output in your report:

1. `timeout 300 godot --headless --path . --script res://tools/design/check_contrast.gd` exits 0.
2. `timeout 300 godot --headless --path . --script res://tools/design/check_samples.gd` exits 0.
3. `timeout 300 godot --path . --script res://tools/design/capture.gd -- rings states` exits 0 with no problems. It writes `docs/design/ring-<layout>.png`, `ring-<layout>-small.png`, `ring-<layout>-small-x3.png` for the three layouts and `docs/design/<direction>-states.png` and `<direction>-states-dark.png` for the three directions.
4. Open every PNG with the Read tool and check, in light and dark: box lines clearly heavier than cell lines; every candidate readable and none touching its neighbor; the X and the Auto Cross slash told apart by shape; Place (solid) and Cross Out (dashed) frames told apart; conflict, hint target and hint reason visible as shapes in every combination on the state sheet; no mark covering a candidate; nothing cut off.
5. Your report lists the files you created, those results, anything you had to approximate, and any token or geometry you need.

No tests are required for Phase 1 prototypes. The captures are the proof, and the senior-graphic-designer reviews them in step 2.

## Out of scope

Input, animation, the skin Resources in src/skins/, the screens and HUD (ui-motion-artist), and any change to the shared data. Ideas beyond this brief go in your report as suggestions.
