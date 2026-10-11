# Direction 1: Gridline

Owner: senior-graphic-designer. Final for Hard Stop 1, 2026-10-11.

## Screenshots

All at 1080 by 2400 (one design unit is one pixel), ring layout A, Godot's default font.

- Play, Cross Out mode: [gridline-play.png](gridline-play.png). Dark: [gridline-play-dark.png](gridline-play-dark.png). Place mode: [gridline-play-place.png](gridline-play-place.png).
- Lesson step: [gridline-lesson.png](gridline-lesson.png)
- Stats: [gridline-stats.png](gridline-stats.png)
- Puzzle complete: [gridline-complete.png](gridline-complete.png)
- Every board state at true size: [gridline-states.png](gridline-states.png), dark: [gridline-states-dark.png](gridline-states-dark.png)
- Ring close-ups (all three directions): [ring-layouts.md](ring-layouts.md)
- Font comparison: shown on Pop, the team's top-ranked direction, in [font-comparison.md](font-comparison.md).

## Concept

A ruled sheet inside a Swiss poster. Precise black rules on white paper, square corners everywhere, one bold ultramarine band across the top, and vermilion for every mark the player makes. Numbers are big and tabular; labels are small tracked capitals. It feels like a well made printed puzzle page that happens to be alive.

## Palette

Paper `#F6F5F1`, white board `#FFFFFF`, ink `#111111`, ultramarine `#2A3BD9` (header band, placed digits, selection), vermilion `#E03E1E` (the hand X, the Hint button in `#D63A1C`). Dark: near black `#111216`, deep ultramarine band `#1D2A9E`, light ultramarine `#9AA6FF` for placed digits and selection, vermilion `#FF6A4D`. Full token table at the end.

## Board, cells and candidates

- Square cells on a uniform pitch. Cell lines 2 units in pale gray, box lines 6 units in ink, outer line 8 units in ink. No radius anywhere.
- Given digits: ink, bold. Placed digits: ultramarine, regular weight. They differ in weight as well as color.
- Candidates: medium weight, dark gray. Crossed by hand: a vermilion X with square ends (3 units), and the digit in mid gray drawn on top of it with a 1 px knockout in the cell color, so the digit stays readable at 720 px while the X shows around it. Crossed by Auto Cross: a single rising slash in gray over the digit. An X is the player's; a slash is the game's.
- Selected: pale ultramarine fill and a 5 unit ultramarine frame on the cell edge. Place mode draws the frame solid; Cross Out mode draws it dashed.
- Peers (row, column, box): a cool gray tint. Same digit: pale yellow.
- Conflict: pale vermilion fill, the digit in dark vermilion, and a heavy vermilion bar under the digit.
- Hint target: green tint with green corner brackets. Hint reason (and cells a lesson marks): lighter green with short green ticks at the middle of each side.

## Type

Godot's default font throughout. Timer 150 units bold with tight spacing. Labels 28 units in tracked capitals (LEVEL, SCORE, CROSS OUT). Titles 64 bold in sentence case. Body 40 regular. Pad digits 64 medium. Everything left aligned.

## Play screen layout

- A full-bleed ultramarine header band from the top edge down to about 490 units: the level tag (white box, ultramarine capitals), the Hint button (vermilion, "HINT 80") and a square Pause button on the first row; the timer in huge white numerals on the left and SCORE 320 on the right below it.
- The board right under the band, 24 unit margins.
- Controls anchored to the bottom: a full-width two-segment bar, PLACE | CROSS OUT, with the active segment in solid ink; one row of nine keys about 200 units tall; a row with Undo and Erase as outlined text buttons with icons.
- Cross Out mode: the keys invert to ink with white digits and a small vermilion slash in each key's corner. Place mode: white keys, no slash.

How it differs from the other two: the only one with a header band and a single row of nine keys. All information is typographic, left aligned, set in rows like a timetable. No shadows, no rounding, no stickers.

## Other screens

- Lesson: the band holds "LESSON 2 OF 5", the title and a close button; STEP 5 OF 8 as a label; the board; the step text on white with a heavy ink rule on its left; the mode bar, keys, Undo and Erase in Cross Out mode. No timer, score or hint.
- Stats: a ruled table, one row per level (LEVEL, STARTED, DONE, BEST, AVERAGE, BEST SCORE) with every other row tinted, "-" where a level has no completion; LESSONS COMPLETED with a big 4 of 5 and a five-segment bar.
- Complete: a tall ultramarine field with the level tag at the top and SOLVED in display type at its foot, like a poster; below, a printer's color bar of small squares and a receipt: time, points after hints, time bonus, a rule, the score in display size, hints used; PLAY AGAIN (vermilion) and MENU (outlined).

## Motion idea

Precise and quick, never bouncy. 120 ms ease-out moves. The selection frame snaps to the new cell in 90 ms. The X draws as two strokes of 60 ms each; the Auto Cross slash fades in. Placed digits fade in over 100 ms. On completion the box rules draw across the board from left to right, like ruling a sheet. The pause menu covers the board completely.

## Dark version

Near-black paper and board, light gray box rules, deep ultramarine band, light ultramarine placed digits and selection, vermilion X, and pad keys that invert to light gray in Cross Out mode. Same shapes and layout.

## Strengths and weaknesses

Strengths:

- The cleanest board of the three. White cells, pale cell lines and ink box lines give the strongest box structure, and the board is the largest (1032 units), so candidates are the largest too: 37 unit font, digits 9.7 dp tall on a 360 dp phone.
- Keys run 1 to 9 left to right, the easiest order to hit without looking.
- The cheapest to draw: a full board redraw takes 7 to 11 ms on this laptop.
- Calm and timeless. The poster band gives it a clear identity without decoration.

Weaknesses:

- Each key is about 109 units wide: 36 dp on a 360 dp phone, below Android's 48 dp touch target. The keys are about 200 units (66 dp) tall to make up for it, about the size of keyboard keys, but it is the one place a direction misses the 48 dp rule.
- The plainest of the three. It may feel more like a tool than a game.
- On a 20:9 phone about 240 units of empty paper sit between the board and the controls. Shorter phones close the gap; Phase 2 decides how leftover height is shared.
- The completion screen's big blue field is deliberate but may read as empty.
- In dark mode the light blue selection frame sits close to the light gray box lines (the smallest color distance of any touching pair, 0.40). It passes, but it is the first thing to watch on a real phone.

## Full token table

Generated from `tools/design/directions/palettes.gd`, the source of truth.

| Token | Light | Dark |
| --- | --- | --- |
| app_bg | `#F6F5F1` | `#111216` |
| surface | `#FFFFFF` | `#1A1B21` |
| surface_alt | `#ECEBE5` | `#24252C` |
| text | `#111111` | `#F2F2F4` |
| text_muted | `#55555E` | `#A3A3AD` |
| text_accent | `#2A3BD9` | `#9AA6FF` |
| accent | `#2A3BD9` | `#3A4BE8` |
| text_on_accent | `#FFFFFF` | `#FFFFFF` |
| accent_2 | `#D63A1C` | `#FF6A4D` |
| text_on_accent_2 | `#FFFFFF` | `#111111` |
| tag_bg | `#FFFFFF` | `#F2F2F4` |
| tag_text | `#2A3BD9` | `#1D2A9E` |
| outline | `#111111` | `#E6E6EA` |
| shadow | `#00000000` | `#00000000` |
| chart_bar | `#2A3BD9` | `#9AA6FF` |
| chart_bar_alt | `#D63A1C` | `#FF6A4D` |
| celebrate_1 | `#2A3BD9` | `#3A4BE8` |
| celebrate_2 | `#E03E1E` | `#FF6A4D` |
| celebrate_3 | `#FFC93C` | `#FFC93C` |
| board_bg | `#FFFFFF` | `#16171C` |
| cell_bg | `#FFFFFF` | `#16171C` |
| cell_selected_bg | `#D9E0FF` | `#2A3478` |
| cell_peer_bg | `#EDF0FA` | `#1F2231` |
| cell_same_digit_bg | `#FFF0B3` | `#3A3414` |
| cell_conflict_bg | `#FFE1D8` | `#3D1B14` |
| cell_hint_target_bg | `#CDEBD7` | `#1B3D27` |
| cell_hint_reason_bg | `#E6F4EA` | `#15291C` |
| digit_given | `#111111` | `#F2F2F4` |
| digit_placed | `#2A3BD9` | `#9AA6FF` |
| digit_conflict | `#A82410` | `#FF8A73` |
| candidate_open | `#34343C` | `#C9C9D1` |
| candidate_crossed | `#74747E` | `#8A8A94` |
| x_mark | `#E03E1E` | `#FF6A4D` |
| x_mark_auto | `#4E4E58` | `#A3A3AD` |
| line_cell | `#C6C6CC` | `#3A3B44` |
| line_box | `#111111` | `#E6E6EA` |
| line_outer | `#111111` | `#E6E6EA` |
| selected_outline | `#2A3BD9` | `#9AA6FF` |
| hint_target_marker | `#1C7A3A` | `#5FD08A` |
| hint_reason_marker | `#1C7A3A` | `#5FD08A` |
| conflict_marker | `#BF2C12` | `#FF8A73` |
| hud_bg | `#2A3BD9` | `#1D2A9E` |
| hud_text | `#FFFFFF` | `#FFFFFF` |
| hud_label | `#CBD2FF` | `#C3CAFF` |
| hud_accent_bg | `#FFFFFF` | `#F2F2F4` |
| hud_accent_text | `#2A3BD9` | `#1D2A9E` |
| button_bg | `#FFFFFF` | `#1A1B21` |
| button_text | `#111111` | `#F2F2F4` |
| button_primary_bg | `#D63A1C` | `#FF6A4D` |
| button_primary_text | `#FFFFFF` | `#111111` |
| button_disabled_bg | `#ECEBE5` | `#24252C` |
| button_disabled_text | `#85858C` | `#7D7D86` |
| pad_bg | `#F6F5F1` | `#111216` |
| pad_key_place_bg | `#FFFFFF` | `#1A1B21` |
| pad_key_place_text | `#111111` | `#F2F2F4` |
| pad_key_cross_bg | `#111111` | `#F2F2F4` |
| pad_key_cross_text | `#FFFFFF` | `#111111` |
| pad_key_cross_mark | `#FF6A4D` | `#D63A1C` |
| mode_toggle_bg | `#ECEBE5` | `#24252C` |
| mode_toggle_text | `#55555E` | `#A3A3AD` |
| mode_toggle_active_bg | `#111111` | `#F2F2F4` |
| mode_toggle_active_text | `#FFFFFF` | `#111216` |
