# Direction 3: Pop

Owner: senior-graphic-designer. Final for Hard Stop 1, 2026-10-11. Bart chose Pop at Hard Stop 1. This page is the Phase 1 record; the final values, layouts and the Phase 2 fixes are in [../DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md), which wins wherever the two differ.

## Screenshots

All at 1080 by 2400 (one design unit is one pixel), ring layout A, Godot's default font.

- Play, Cross Out mode: [pop-play.png](pop-play.png). Dark: [pop-play-dark.png](pop-play-dark.png). Place mode: [pop-play-place.png](pop-play-place.png).
- Lesson step: [pop-lesson.png](pop-lesson.png)
- Stats: [pop-stats.png](pop-stats.png)
- Puzzle complete: [pop-complete.png](pop-complete.png)
- Every board state at true size: [pop-states.png](pop-states.png), dark: [pop-states-dark.png](pop-states-dark.png)
- Ring close-ups (all three directions): [ring-layouts.md](ring-layouts.md)
- Font comparison, Pop's play, lesson, stats and complete screens and its ring close-ups in both fonts: [font-comparison.md](font-comparison.md)

## Concept

Neo-brutalist pop. A lemon page, thick black outlines, hard offset shadows and flat candy blocks of pink, blue and green. Buttons look like stickers you press into the page. Chunky, condensed capitals. Loud on the outside, while the board itself stays white and calm so the candidates read.

## Palette

Lemon page `#FFE45C`, white board and cards, ink `#111111`, electric blue `#1A40D9` (placed digits, selection frame, Hint button), bubblegum `#FF5FA2` (score block), pink selection `#FFB3DE`, magenta X `#D1005A`, green level sticker `#2BD47D`, deep green hint marks `#087A38`. Dark: near-black page `#161616`, board `#1E1E1E`, lemon box lines and lemon hard shadows, pink selection frame `#FF6FB5`, light blue placed digits `#8FB0FF`. Full token table at the end.

## Board, cells and candidates

- A white card with an 8 unit ink outline, rounded outer corners (14) and a hard ink shadow offset 12 by 12. Cell lines 2 units in dark gray, box lines 6 units in ink, square cells.
- Given digits: ink, heavy. Placed digits: electric blue, semibold.
- Candidates: ink, semibold. Crossed by hand: a magenta X with square ends (4 units), and the digit in mid gray drawn on top of it with a 1 px knockout in the cell color, so the digit stays readable while the X shows around it. Crossed by Auto Cross: one rising slash in dark gray over the digit.
- Selected: pink fill and a 6 unit electric blue frame. Place mode: solid frame. Cross Out mode: dashed frame. The frame was ink at first, but its dashes vanished into the ink box lines and the hint brackets fused with it, so in light mode the frame is blue and the hint marks are green.
- Peers: sky blue. Same digit: lilac.
- Conflict: salmon fill, dark red digit, a heavy dark red bar under the digit.
- Hint target: mint with deep green corner brackets. Hint reason: paler mint with deep green side ticks.

## Type

Godot's default font, emboldened to heavy and condensed for display: timer and headlines 140 units heavy capitals at 84 percent width; titles 72 heavy capitals; HUD values 72 heavy condensed; labels 28 heavy capitals; buttons 36 heavy capitals. Body text stays 40 semibold sentence case so lesson text reads easily. Pad digits 72 heavy.

## Play screen layout

- A slim top row: the level as a green sticker, tilted 3 degrees, with an ink outline and hard shadow; a square Pause button on the right.
- The board right below, 24 unit margin on the left, room for its shadow on the right.
- A scoreboard strip under the board: three outlined blocks with hard shadows, TIME 12:48 (white), SCORE 320 (pink) and the Hint button, HINT 80 (blue, white text).
- Mode tabs: two chunky tabs side by side, PLACE and CROSS OUT. The active tab is ink with white text and sits pressed down without its shadow.
- The pad: two rows of six chunky keys with outlines and shadows: 1 2 3 4 5 UNDO, then 6 7 8 9 and ERASE across two slots.
- Cross Out mode: keys turn ink with white digits and a pink stripe across one corner. Place mode: white keys, no stripe.

How it differs from the other two: the HUD sits between the board and the pad as a scoreboard, keys are a 2 by 6 grid, the mode switch is a pair of tabs, and depth comes from hard shadows and stickers rather than flat rules or soft shadows.

## Other screens

- Lesson: a LESSON 2 OF 5 sticker and a close button; the title in condensed capitals; the board; the step text in a white speech-bubble card with an outline and hard shadow, headed STEP 5 OF 8; the tabs and pad in Cross Out mode. No timer, score or hint.
- Stats: STATS in condensed capitals; one outlined block per level with the level name on a colored sticker, a chunky bar for completed out of started, and the numbers in a row; Expert shows dashes. LESSONS COMPLETED 4 OF 5 as five chunky squares.
- Complete: SOLVED! in a pink sticker tilted against a white starburst with an ink outline, the HARD sticker under it; a receipt card with TIME, POINTS AFTER HINTS, TIME BONUS, a rule, a big SCORE and HINTS USED; PLAY AGAIN (blue) and MENU (white).

## Motion idea

Punchy. Buttons press down into their shadow (shadow from 12 to 3 units in 70 ms) and spring back (160 ms, back out). The X stamps in, scaling from 125 to 100 percent in 90 ms; the Auto Cross slash slides in over 80 ms. On completion the SOLVED sticker slams in with a 6 degree wobble. The pause menu covers the board completely.

## Dark version

Near-black page and board, white digits, lemon box lines, a lemon hard shadow behind the board and the buttons, deep pink selected cell with a pink frame, pink X, a lemon Hint button and white pad keys with a magenta corner in Cross Out mode.

## Strengths and weaknesses

Strengths:

- The most fun and the most distinctive. Stickers, hard shadows and the starburst make every screen feel like a game, and completion is a real moment.
- A readable board: white cells, candidates in pure ink (the highest contrast of the three), a 36 unit candidate font, almost the same as Gridline's.
- Big keys that meet the touch target: about 160 by 200 units (54 by 66 dp on a 360 dp phone), with Undo and Erase in the same grid.
- Time, score and Hint sit together right under the board, where the eye already is.

Weaknesses:

- Loud. A full lemon page may tire the eye over a long session, and neo-brutalism is a current trend that may date.
- The Hint block is large and sits just above the mode tabs, which the thumb uses all the time. A hint costs points the moment it is tapped, so a stray tap is expensive. Phase 2 should make it smaller or move it away from the tabs.
- The board is the smallest of the three lines boards (1012 units), because the hard shadow needs room on the right.
- Ink everywhere left no ink for the selection frame and the hint marks; they had to take blue and green, so the board is less purely black and white than the concept.
- On a 20:9 phone about 245 units of empty lemon sit between the scoreboard and the tabs. Shorter phones close the gap; Phase 2 decides how leftover height is shared.

## Full token table

The Phase 1 values, as captured in the screenshots above. Since Phase 2, `tools/design/directions/palettes.gd` holds the final skins and derives Pop's prototype colors from them; the final values are in DESIGN_SYSTEM.md section 1.

| Token | Light | Dark |
| --- | --- | --- |
| app_bg | `#FFE45C` | `#161616` |
| surface | `#FFFFFF` | `#232323` |
| surface_alt | `#FFF5C2` | `#2E2E2E` |
| text | `#111111` | `#FFFFFF` |
| text_muted | `#3B3B3B` | `#BDBDBD` |
| text_accent | `#1A40D9` | `#FFE45C` |
| accent | `#1A40D9` | `#FFE45C` |
| text_on_accent | `#FFFFFF` | `#111111` |
| accent_2 | `#FF5FA2` | `#FF6FB5` |
| text_on_accent_2 | `#111111` | `#111111` |
| tag_bg | `#2BD47D` | `#2BD47D` |
| tag_text | `#111111` | `#111111` |
| outline | `#111111` | `#F0F0F0` |
| shadow | `#111111` | `#FFE45C` |
| chart_bar | `#1A40D9` | `#FFE45C` |
| chart_bar_alt | `#D1005A` | `#FF6FB5` |
| celebrate_1 | `#FF5FA2` | `#FFE45C` |
| celebrate_2 | `#2BD47D` | `#FF6FB5` |
| celebrate_3 | `#1A40D9` | `#6E8CFF` |
| board_bg | `#FFFFFF` | `#1E1E1E` |
| cell_bg | `#FFFFFF` | `#1E1E1E` |
| cell_selected_bg | `#FFB3DE` | `#5E1F48` |
| cell_peer_bg | `#DDF0FF` | `#1B2E3D` |
| cell_same_digit_bg | `#E5DDFF` | `#2E2552` |
| cell_conflict_bg | `#FFC6BE` | `#4A1A16` |
| cell_hint_target_bg | `#B4F0CB` | `#1D4A30` |
| cell_hint_reason_bg | `#DEF9E8` | `#163324` |
| digit_given | `#111111` | `#FFFFFF` |
| digit_placed | `#1A40D9` | `#8FB0FF` |
| digit_conflict | `#9E0024` | `#FF96A3` |
| candidate_open | `#111111` | `#F0F0F0` |
| candidate_crossed | `#5A5A5A` | `#9A9A9A` |
| x_mark | `#D1005A` | `#FF6FB5` |
| x_mark_auto | `#4A4A4A` | `#BDBDBD` |
| line_cell | `#4A4A4A` | `#6A6A6A` |
| line_box | `#111111` | `#FFE45C` |
| line_outer | `#111111` | `#FFE45C` |
| selected_outline | `#1A40D9` | `#FF6FB5` |
| hint_target_marker | `#087A38` | `#5BE08F` |
| hint_reason_marker | `#087A38` | `#5BE08F` |
| conflict_marker | `#B8002A` | `#FF7A8A` |
| hud_bg | `#FFFFFF` | `#232323` |
| hud_text | `#111111` | `#FFFFFF` |
| hud_label | `#3B3B3B` | `#BDBDBD` |
| hud_accent_bg | `#FF5FA2` | `#FF6FB5` |
| hud_accent_text | `#111111` | `#111111` |
| button_bg | `#FFFFFF` | `#232323` |
| button_text | `#111111` | `#FFFFFF` |
| button_primary_bg | `#1A40D9` | `#FFE45C` |
| button_primary_text | `#FFFFFF` | `#111111` |
| button_disabled_bg | `#EFE6B8` | `#2E2E2E` |
| button_disabled_text | `#6E6A55` | `#7A7A7A` |
| pad_bg | `#FFE45C` | `#161616` |
| pad_key_place_bg | `#FFFFFF` | `#232323` |
| pad_key_place_text | `#111111` | `#FFFFFF` |
| pad_key_cross_bg | `#111111` | `#FFFFFF` |
| pad_key_cross_text | `#FFFFFF` | `#111111` |
| pad_key_cross_mark | `#FF5FA2` | `#D1005A` |
| mode_toggle_bg | `#FFFFFF` | `#232323` |
| mode_toggle_text | `#111111` | `#BDBDBD` |
| mode_toggle_active_bg | `#111111` | `#FF6FB5` |
| mode_toggle_active_text | `#FFFFFF` | `#111111` |
