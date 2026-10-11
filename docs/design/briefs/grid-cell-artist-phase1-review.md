# Review: grid-cell-artist, Phase 1 board prototypes

From: senior-graphic-designer. Date: 2026-10-11. For the Development Manager to pass on.

## Verdict

The boards pass, with one change before Hard Stop 1. All three directions draw from the shared tokens and geometry, box lines read clearly heavier than cell lines, the Place (solid) and Cross Out (dashed) frames are told apart in every direction, the hand X and the Auto Cross slash differ by shape, no mark covers a candidate, nothing is cut off, and the close-ups are drawn at true size with no scaling. The pixel snapping keeps every line one weight across the board. Thank you for flagging the five problems; they were real.

What I fixed in my own files after your report:

- Pop light: the selection frame is now electric blue `#1A40D9` and both hint marks deep green `#087A38`, so the frame, the hint marks and the ink box lines no longer fuse. The contrast checker now fails any palette where these touching marks share a color (`TOLD_APART` in `check_contrast.gd`).
- Pebble's soft shadow is now `shadow_blur` 16 with `shadow_offset` (0, 6), so it fits the 16 unit screen margin. The checker enforces that too.
- The state sheet is now captured at 1080 by 2720, so Pebble's sheet keeps its full gaps.
- New shape tokens you asked for: `round_caps` and `conflict_bar_y`. Also `crossed_halo_w` for request 1, and `Fonts.draw_centered_outlined()`.

## Change requests

### 1. Must: draw a hand-crossed digit on top of its X, with a thin knockout

Problem: at 720 px wide (the smallest phone), a digit under the hand X cannot be read. The X is 80 to 84 percent of the slot and runs straight through the digit, and in the busiest cells (four crossed in a row, Pebble's yellow selected tile, Gridline dark) the gray digit and the colored X merge into one blot. The brief says a crossed candidate stays visible so the player can see what they ruled out. I prototyped the options at 720 and 1080 px: a thinner X or a darker digit barely help; drawing the digit on top of the X with a 1 px outline in the cell's background color makes every digit readable while the X still shows around it.

Change in `_draw_ring()` of `board.gd`, for a candidate crossed by hand only:

1. Draw the X first, exactly as now (both diagonals of `mark_rect()`, `x_stroke_w`, `x_mark`).
2. Then draw the digit with `Fonts.draw_centered_outlined(self, font, font_size, str(digit), center, _colors.candidate_crossed, outline, cell_bg)`, where `outline` is `maxi(1, roundi(_shape.crossed_halo_w * _k))` and `cell_bg` is the color that cell's background was drawn in (`_bg_color(board.cell_bg(index))`).

Leave open candidates and the Auto Cross slash as they are: the slash is a single stroke, its digit reads fine under it, and keeping it on top keeps the two marks clearly different.

Performance: outlined text costs a little more. Report the full redraw time per direction before and after, the way you measured it in step 1.

### 2. Nice: use the new tokens

- Replace the `_round_caps = _shape.cell_radius > 0.0` inference with `_shape.round_caps`.
- Replace the `CONFLICT_BAR_CENTER` constant with `_shape.conflict_bar_y` (0.84 in all three, so nothing changes on screen).
- In `state_sheet.gd`, the header comment says the capture sets 1080 by 2640; it is now 1080 by 2720.

## Files you may touch

Only `tools/design/directions/board/` (`board.gd`, `state_sheet.gd`, and the scenes there). Everything else in `tools/design/` stays read only, including the shared data and the capture tool.

## How you prove it

Run each and put the output in your report:

1. `timeout 300 godot --headless --path . --script res://tools/design/check_contrast.gd` exits 0.
2. `timeout 300 godot --headless --path . --script res://tools/design/check_samples.gd` exits 0.
3. `timeout 600 godot --path . --script res://tools/design/capture.gd -- rings states screens place` exits 0 with no problems and no state sheet warnings. Screens are included because they embed your board.
4. `timeout 600 godot --path . --script res://tools/design/capture.gd -- screens --direction=gridline --font=inter` exits 0, so the Inter copies match.
5. Open `ring-rows-small-x3.png`, `ring-clockwise-small-x3.png` and `ring-clockwise-wide-small-x3.png` with the Read tool. In all six tiles of each, every crossed digit can be named (for example the 1, 2 and 3 under the X in the cell with four crossed in its top row), the X still shows at all four tips, and the Auto Cross slashes look as before. Check `pebble-states.png` and `gridline-states-dark.png` the same way.
6. The redraw times from request 1.
