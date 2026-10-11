# Direction 3: Pop

Owner: senior-graphic-designer. Phase 1 draft, 2026-10-11. Screenshots are added in step 2: `pop-play.png`, `pop-lesson.png`, `pop-stats.png`, `pop-complete.png`, `pop-play-dark.png`, `pop-states.png`, `pop-states-dark.png`.

## Concept

Neo-brutalist pop. A lemon page, thick black outlines, hard offset shadows and flat candy blocks of pink, blue and green. Buttons look like stickers you press into the page. Chunky, condensed capitals. Loud on the outside, while the board itself stays white and calm so the candidates read.

## Palette

Lemon page `#FFE45C`, white board and cards, ink `#111111`, electric blue `#1A40D9` (placed digits, Hint button), bubblegum `#FF5FA2` (score block), pink selection `#FFB3DE`, magenta X `#D1005A`, green level sticker `#2BD47D`. Dark: near-black page `#161616`, board `#1E1E1E`, lemon box lines and lemon hard shadows, pink selection frame `#FF6FB5`, light blue placed digits `#8FB0FF`. Full token table at the end.

## Board, cells and candidates

- A white card with an 8 unit ink outline, rounded outer corners (14) and a hard ink shadow offset 12 by 12. Cell lines 2 units in dark gray, box lines 6 units in ink, square cells.
- Given digits: ink, heavy. Placed digits: electric blue, semibold.
- Candidates: ink, semibold. Crossed by hand: mid gray digit under a magenta X with square ends (4 units). Crossed by Auto Cross: one rising slash in dark gray.
- Selected: pink fill and a 6 unit ink frame. Place mode: solid frame. Cross Out mode: dashed frame.
- Peers: sky blue. Same digit: lilac.
- Conflict: salmon fill, dark red digit, a heavy dark red bar under the digit.
- Hint target: mint with ink corner brackets. Hint reason: paler mint with ink side ticks.

## Type

Godot's default font, emboldened to heavy and condensed for display: timer and headlines 140 units heavy capitals at 84 percent width; titles 72 heavy capitals; HUD values 72 heavy condensed; labels 28 heavy capitals; buttons 36 heavy capitals. Body text stays 40 semibold sentence case so lesson text reads easily. Pad digits 72 heavy.

## Play screen layout

- A slim top row: the level as a green sticker, tilted 3 degrees, with an ink outline and hard shadow; a square Pause button on the right.
- The board right below, 24 unit margin on the left, room for its shadow on the right.
- A scoreboard strip under the board: three outlined blocks with hard shadows, TIME 12:48 (white), SCORE 320 (pink) and the Hint button, HINT 80 (blue, white text).
- Mode tabs: two chunky tabs side by side, PLACE and CROSS OUT. The active tab is ink with white text and sits pressed down without its shadow.
- The pad: two rows of six chunky keys with outlines and shadows: 1 2 3 4 5 UNDO, then 6 7 8 9 and ERASE across two slots.
- Cross Out mode: keys turn ink with white digits and a pink stripe across one corner.

How it differs from the other two: the HUD sits between the board and the pad as a scoreboard, keys are a 2 by 6 grid, the mode switch is a pair of tabs, and depth comes from hard shadows and stickers rather than flat rules or soft shadows.

## Other screens

- Lesson: a LESSON 2 sticker and a close button; the title in condensed capitals; the board; the step text in a white speech-bubble card with an outline and hard shadow, headed STEP 5 OF 8; the tabs and pad in Cross Out mode. No timer, score or hint.
- Stats: STATS in condensed capitals; one outlined block per level with the level name on a colored sticker and the numbers in a grid; a chunky bar for completed out of started; Expert shows dashes. LESSONS COMPLETED 4 OF 5 as five chunky squares.
- Complete: SOLVED! in a pink sticker block tilted against a white starburst with an ink outline; a receipt card with TIME, POINTS, BONUS, a big SCORE and HINTS; PLAY AGAIN (blue) and MENU (white).

## Motion idea

Punchy. Buttons press down into their shadow (shadow from 12 to 3 units in 70 ms) and spring back (160 ms, back out). The X stamps in, scaling from 125 to 100 percent in 90 ms; the Auto Cross slash slides in over 80 ms. On completion the SOLVED sticker slams in with a 6 degree wobble. The pause menu covers the board completely.

## Dark version

Near-black page and board, white digits, lemon box lines, a lemon hard shadow behind the board and the buttons, deep pink selected cell with a pink frame, pink X.

## Full token table

Generated from `tools/design/directions/palettes.gd`, the source of truth.

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
| selected_outline | `#111111` | `#FF6FB5` |
| hint_target_marker | `#111111` | `#5BE08F` |
| hint_reason_marker | `#111111` | `#5BE08F` |
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
