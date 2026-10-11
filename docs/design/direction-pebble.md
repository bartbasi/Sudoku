# Direction 2: Pebble

Owner: senior-graphic-designer. Phase 1 draft, 2026-10-11. Screenshots are added in step 2: `pebble-play.png`, `pebble-lesson.png`, `pebble-stats.png`, `pebble-complete.png`, `pebble-play-dark.png`, `pebble-states.png`, `pebble-states-dark.png`.

## Concept

Soft, friendly and a little toy-like. The board is a bold periwinkle tray holding nine rounded box cards, and every cell is a small rounded tile. Round keys, pill chips, sunny yellow for the selected cell, raspberry for marks, a warm cream page. It should feel like picking up smooth pebbles, calm but bright.

## Palette

Cream page `#FFF6EA`, periwinkle tray `#6656F5`, lavender cards `#E6E1FF`, white tiles, deep indigo text `#1D1846`, violet placed digits `#4B3BE0`, sunny selection `#FFD443`, raspberry X `#CF1D62`, tangerine Hint `#FF8A3D`, mint level chip `#BFF0D8`. Dark: indigo night `#15122B`, dark tiles `#221E40`, bright tray `#7E70FF`, violet selection `#3F3488` with a yellow frame. Full token table at the end.

## Board, cells and candidates

- Tiles, not lines. The tray has rounded corners (32) and 8 units of padding; box cards have radius 20 and sit 10 units apart, so periwinkle gutters separate the boxes; inside a card, white tiles with radius 10 sit 4 units apart on lavender. Box separation (18 units with padding) is four and a half times the cell gap.
- Given digits: deep indigo, bold. Placed digits: violet, medium weight.
- Candidates: semibold indigo gray. Crossed by hand: soft gray digit under a raspberry X with round ends (4 units). Crossed by Auto Cross: one rising slash in gray with round ends.
- Selected: the tile turns sunny yellow with a 3 unit indigo frame on its edge. Place mode: solid frame. Cross Out mode: a frame of short rounded dashes that read as dots.
- Peers: butter yellow tiles. Same digit: soft pink.
- Conflict: rose tile, crimson digit, a rounded crimson bar under the digit.
- Hint target: mint tile with green corner brackets. Hint reason: paler mint with green side ticks.

## Type

Godot's default font, sentence case everywhere, semibold and bold weights only. Timer and headlines 96 bold. Titles 60 bold. Body 42 semibold. Labels 32 semibold. Pad digits 64 bold. Text centered in chips and keys.

## Play screen layout

- A row of floating pill chips with soft shadows at the top: the level (mint), the timer with a clock icon, the score with a star icon, the Hint pill (tangerine, "Hint 80") and a round Pause button.
- The board tray, 16 unit margins.
- Controls at the bottom: on the left a 3 by 3 keypad of round white keys on a periwinkle panel; on the right a column with a big two-option pill switch (Place, Cross out) and round Undo and Erase buttons with small labels under them.
- Cross Out mode: the keys turn sunny yellow, the same yellow as the selected cell, each with a small raspberry X badge.

How it differs from the other two: the only one with tiles and gutters instead of lines, a phone-style 3 by 3 keypad, chips instead of a bar, and rounded shapes everywhere.

## Other screens

- Lesson: a round back button and a chip "Lesson 2 · The ring and Cross Out"; eight step dots, the fifth filled; the board; the step text in a white speech bubble pointing up at the board; a smaller keypad and the switch in Cross Out mode. No timer, score or hint.
- Stats: one rounded card per level with the level name and small chips (Started 17, Done 13, Best 11:05, Average 15:22, Best score 578); Expert shows dashes. A lessons card with five pebbles, four filled.
- Complete: a big rounded card, "Puzzle solved!" in display type with a burst of round confetti dots around it, the level chip, rows for time, points, time bonus and the score, a chip "2 hints used", and pills Play again (tangerine) and Menu.

## Motion idea

Springy and soft. The selected tile pops from 92 to 100 percent with a slight overshoot (220 ms, back out). Keys squish to 94 percent while pressed. The X draws as two rounded strokes of 90 ms each; the Auto Cross slash fades in over 150 ms. On completion the tiles pop in a wave from the center, 40 ms apart, and confetti dots drift down. The pause menu covers the board completely.

## Dark version

Indigo night page and tiles, a brighter periwinkle tray, lavender text, violet selected tile framed in sunny yellow, pink-raspberry X, and yellow pad keys in Cross Out mode.

## Full token table

Generated from `tools/design/directions/palettes.gd`, the source of truth.

| Token | Light | Dark |
| --- | --- | --- |
| app_bg | `#FFF6EA` | `#15122B` |
| surface | `#FFFFFF` | `#211D3D` |
| surface_alt | `#F1EDFF` | `#2B2650` |
| text | `#1D1846` | `#F4F2FF` |
| text_muted | `#5A5582` | `#ABA6D1` |
| text_accent | `#4B3BE0` | `#B8B0FF` |
| accent | `#6656F5` | `#8C80FF` |
| text_on_accent | `#FFFFFF` | `#15122B` |
| accent_2 | `#FF8A3D` | `#FF9A57` |
| text_on_accent_2 | `#1D1846` | `#15122B` |
| tag_bg | `#BFF0D8` | `#7FE0B4` |
| tag_text | `#1D1846` | `#15122B` |
| outline | `#1D1846` | `#F4F2FF` |
| shadow | `#1D18462E` | `#00000066` |
| chart_bar | `#6656F5` | `#8C80FF` |
| chart_bar_alt | `#E8691C` | `#FF9A57` |
| celebrate_1 | `#FFD443` | `#FFD443` |
| celebrate_2 | `#FF5C8A` | `#FF5C9A` |
| celebrate_3 | `#6656F5` | `#8C80FF` |
| board_bg | `#6656F5` | `#7E70FF` |
| cell_bg | `#FFFFFF` | `#221E40` |
| cell_selected_bg | `#FFD443` | `#3F3488` |
| cell_peer_bg | `#FFF1C4` | `#2C2752` |
| cell_same_digit_bg | `#FFE0EC` | `#47233F` |
| cell_conflict_bg | `#FFD5D9` | `#4A1E2A` |
| cell_hint_target_bg | `#C4EEDB` | `#173E34` |
| cell_hint_reason_bg | `#E3F7EE` | `#163430` |
| digit_given | `#1D1846` | `#F4F2FF` |
| digit_placed | `#4B3BE0` | `#B8B0FF` |
| digit_conflict | `#A8152F` | `#FF8FA3` |
| candidate_open | `#36305E` | `#DAD6F5` |
| candidate_crossed | `#736E96` | `#8D88B3` |
| x_mark | `#CF1D62` | `#FF5C9A` |
| x_mark_auto | `#6C6790` | `#9C97C2` |
| line_cell | `#E6E1FF` | `#34305A` |
| line_box | `#6656F5` | `#7E70FF` |
| line_outer | `#6656F5` | `#7E70FF` |
| selected_outline | `#1D1846` | `#FFD443` |
| hint_target_marker | `#0E7A4E` | `#4FD6A0` |
| hint_reason_marker | `#0E7A4E` | `#4FD6A0` |
| conflict_marker | `#BE1E3A` | `#FF8FA3` |
| hud_bg | `#FFFFFF` | `#211D3D` |
| hud_text | `#1D1846` | `#F4F2FF` |
| hud_label | `#5A5582` | `#ABA6D1` |
| hud_accent_bg | `#FF8A3D` | `#FF9A57` |
| hud_accent_text | `#1D1846` | `#15122B` |
| button_bg | `#FFFFFF` | `#2B2650` |
| button_text | `#1D1846` | `#F4F2FF` |
| button_primary_bg | `#FF8A3D` | `#FFD443` |
| button_primary_text | `#1D1846` | `#15122B` |
| button_disabled_bg | `#EEEAF6` | `#2B2650` |
| button_disabled_text | `#87839F` | `#8A85B0` |
| pad_bg | `#6656F5` | `#2B2650` |
| pad_key_place_bg | `#FFFFFF` | `#3A3466` |
| pad_key_place_text | `#1D1846` | `#F4F2FF` |
| pad_key_cross_bg | `#FFD443` | `#FFD443` |
| pad_key_cross_text | `#1D1846` | `#15122B` |
| pad_key_cross_mark | `#CF1D62` | `#C2185B` |
| mode_toggle_bg | `#ECE7FF` | `#211D3D` |
| mode_toggle_text | `#5A5582` | `#ABA6D1` |
| mode_toggle_active_bg | `#1D1846` | `#FFD443` |
| mode_toggle_active_text | `#FFFFFF` | `#15122B` |
