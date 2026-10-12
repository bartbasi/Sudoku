# Sudoku: Design System

Owner: senior-graphic-designer. Status: Phase 2, 2026-10-11; Phase 3 addition 2026-10-12, the hint cross chip (Bart, Hard Stop 2; sections 1, 2.7 to 2.9); 2026-10-12, the SUDOKU wordmark and the icon placeholder (sections 7.1, 7.2 and 9); 2026-10-12, the final app icon, Ring, made bolder (sections 7.1 and 9); 2026-10-12, number pad labels fit their faces down to 320 by 568 dp (sections 3.2, 3.5, 4.6, 5 and 10); 2026-10-12, Phase 4: the header row, Continue and the hint panel fit their design, the making a puzzle wait, the lesson card's wrong tap tag and height, and which sizes are Layout constants (sections 1, 3.2, 3.6, 4.6, 4.8, 5, 6, 7 and 10); 2026-10-12, Phase 6: window shapes for foldables and split screen, side by side and too small (sections 4.7, 4.8, 4.9, 4.11, 7.6 and 10). This is the contract the artists and developers build Phase 3 from. If something you need is missing or would force a guess, ask the senior-graphic-designer through the Development Manager; do not invent a value locally.

Bart's Hard Stop 1 decisions behind it: direction Pop, with the Phase 2 fixes from [design/ranking.md](design/ranking.md); v1 ships two skins, Pop light (the default) and Pop dark; candidate ring layout A, reading rows; Godot's built-in font, no font files; a digit crossed by hand is drawn on top of its X with a thin outline; the game fits and works at 320 by 568 dp and readability is judged at 360 dp wide; an app icon whose background follows Pop's palette; "New best time" and "New best score" on the completion screen. The game is called Sudoku for now, a placeholder name Bart may change. The app icon is Ring (section 9).

Read with docs/GDD.md (every state that needs a style), docs/ARCHITECTURE.md (section 6 GameSkin and BoardPainter, section 7 ThemeFactory, Icons and Motion, section 8 PlayArea and ScreenMetrics) and docs/LESSONS.md. The Phase 1 record is [design/direction-pop.md](design/direction-pop.md); its values are superseded by this document.

## What changed from Phase 1 Pop

Each line answers a finding from the team review ([design/ranking.md](design/ranking.md)).

- **Hint moved.** It is now at the top left of the header, at least 48 dp above the board, at the far end of the screen from the pad, and in the opposite corner from Pause. Time and score moved up beside it. (Section 7.5.)
- **Pad gap.** The digits are a 3 by 3 block. Mode, Undo and Erase sit in their own column to its right, 20 dp away. (Section 7.5.)
- **Lemon page toned down** from `#FFE45C` to `#FFEB8F`, a third less saturated. (Section 8.)
- **Selected cell is lemon, not pink.** The magenta hand X on it rises from 3.31:1 to 4.42:1 and no longer shares its hue. (Section 8.)
- **Mode cue on the board.** The selection frame is 3 dp: solid blue in Place mode, broken magenta in Cross Out mode, with the gaps filled so grid lines cannot close them. (Section 2.7.)
- **Selected hint target keeps its marks.** Hint brackets and ticks sit on the cell edge and are drawn over the selection frame, as heavy as the frame. (Sections 2.7 to 2.9.)
- **Auto Cross mark.** One falling slash, top left to bottom right, drawn on top of the digit in blue. It crosses the diagonals of 1, 2, 4 and 7 instead of running along them. (Section 2.5.)
- **Hint panel** covers only the zone above the board, so it never covers a target or reason cell, or any cell. (Section 7.6.)
- **Disabled buttons** lose their shadow and get a hatch, so they read as disabled without color. (Section 4.2.)
- **Stats labels** are full words: BEST TIME, AVERAGE TIME, BEST SCORE. (Section 7.10.)
- **Sizes are dp.** Phase 1 used design units of one pixel on a 1080 px phone, which change size from phone to phone. (Section 0.)

## 0. Units, and how the look reaches the screen

- **dp** (density-independent pixels, 1/160 inch) for every size in this document unless it says otherwise. **share** is a fraction of something named in the same row (the cell side, the slot box, the candidate font size). **deg** is degrees.
- One canvas unit is one dp on every device (ARCHITECTURE section 2; `ScreenMetrics.apply_dp_scale` sets it up). Every dp value here is used as written, fonts included.
- Board strokes (lines, the frame, marks, the X, the slash, the conflict bar) snap to whole device pixels: `px = max(1, round(dp * ScreenMetrics.px_per_unit()))`, at least 1 px. Text, radii and UI outlines need no snapping.
- Colors and the numbers in section 1 live in the skin (`GameSkin`). ThemeFactory (ui-motion-artist) builds the Theme from the skin and the type scale of section 3 and exposes the styles of section 5. BoardPainter (grid-cell-artist) reads the skin directly. The layout constants of section 4.6 are the same in every skin, so they are not skin tokens: they are the `Layout` class in src/design (ARCHITECTURE section 7), which PlayArea, the screens and the lesson player all read.

## 1. Skin tokens

This table is the skin schema. `GameSkin` (ARCHITECTURE section 6) has the three identity fields below and then one exported property per row of the token table, with exactly that name and type, in this order. `src/skins/pop_light.tres` and `src/skins/pop_dark.tres` (senior-graphic-designer) hold the values. These two tables are where a value is changed: `tools/design/write_skins.gd` writes both files from them, every property written out. The contrast checker and the skins test (`tests/skins/test_game_skin.gd`) fail if the tables and the files disagree on any name, order, type or value.

Identity fields:

| Field | Type | `pop_light` | `pop_dark` |
| --- | --- | --- | --- |
| `id` | StringName | `pop_light` | `pop_dark` |
| `display_name` | String | Light | Dark |
| `is_dark` | bool | false | true |

`pop_light` is the default (`Skins.DEFAULT_ID`). The skin picker shows the display names.

Tokens. Colors are `#RRGGBB`, or `#RRGGBBAA` for the one translucent token. Every number is the same in both skins.

| Token | Type | Pop light | Pop dark | What it is for |
| --- | --- | --- | --- | --- |
| **Page, surfaces and text** | | | | |
| `page_bg` | Color | `#FFEB8F` | `#161616` | Screen background, edge to edge, under every screen and behind the pause menu. Also the Android boot background. |
| `surface_bg` | Color | `#FFFFFF` | `#232323` | Cards, dialogs, the hint panel, the lesson card, the receipt, list rows, the starburst. |
| `surface_alt_bg` | Color | `#FFF6D1` | `#2E2E2E` | Quiet fills inside cards: stat bar track, empty lesson squares, empty difficulty pips. |
| `outline` | Color | `#111111` | `#F0F0F0` | Outline of every card, button, key, sticker and the switch knob; rules inside cards. |
| `shadow` | Color | `#111111` | `#FFE45C` | Hard offset shadow under cards, buttons, keys, stickers and the board. |
| `scrim` | Color | `#111111A6` | `#000000B8` | Translucent layer behind a dialog. The only translucent token. |
| `text` | Color | `#111111` | `#FFFFFF` | Main text on page_bg, surface_bg and surface_alt_bg. |
| `text_muted` | Color | `#3B3B3B` | `#BDBDBD` | Captions, subtitles and secondary text on the same backgrounds. |
| `text_accent` | Color | `#1A40D9` | `#FFE45C` | The final score on the completion screen. |
| **Stickers, tags and charts** | | | | |
| `sticker_bg` | Color | `#2BD47D` | `#2BD47D` | Level sticker, lesson number sticker, finished check badge, lesson praise tag. |
| `sticker_text` | Color | `#111111` | `#111111` | Text and icons on sticker_bg. |
| `celebrate_bg` | Color | `#FF5FA2` | `#FF6FB5` | SOLVED! sticker, NEW BEST labels, the SUDOKU wordmark sticker, the lesson NOT QUITE tag. |
| `celebrate_text` | Color | `#111111` | `#111111` | Text on celebrate_bg. |
| `hint_tag_bg` | Color | `#087A38` | `#5BE08F` | Technique tag on the hint panel. |
| `hint_tag_text` | Color | `#FFFFFF` | `#111111` | Text on hint_tag_bg. |
| `chart_bar` | Color | `#1A40D9` | `#FFE45C` | Stat bar fill, finished lesson squares, filled difficulty pips. |
| **HUD** | | | | |
| `hud_bg` | Color | `#FFFFFF` | `#232323` | TIME block in the header. |
| `hud_text` | Color | `#111111` | `#FFFFFF` | Time value on hud_bg. |
| `hud_label` | Color | `#3B3B3B` | `#BDBDBD` | TIME caption on hud_bg. |
| `hud_score_bg` | Color | `#FF5FA2` | `#FF6FB5` | SCORE block in the header. |
| `hud_score_text` | Color | `#111111` | `#111111` | Caption and value on hud_score_bg. |
| **Buttons** | | | | |
| `button_bg` | Color | `#FFFFFF` | `#232323` | Secondary buttons: Undo, Erase, Pause, back, close, Menu, Keep playing, Cancel, Skip, list rows. |
| `button_text` | Color | `#111111` | `#FFFFFF` | Label and icon on button_bg. |
| `button_primary_bg` | Color | `#1A40D9` | `#FFE45C` | Primary buttons: Hint, Continue, Resume, Play again, Start lesson, Next. |
| `button_primary_text` | Color | `#FFFFFF` | `#111111` | Label and icon on button_primary_bg. |
| `button_danger_bg` | Color | `#C2004F` | `#FF7A8A` | Destructive confirmations: Start new, Reset. |
| `button_danger_text` | Color | `#FFFFFF` | `#111111` | Label on button_danger_bg. |
| `button_disabled_bg` | Color | `#F4EDCF` | `#262626` | Face of a disabled button (Hint, Undo). |
| `button_disabled_text` | Color | `#67634E` | `#8C8C8C` | Label and icon of a disabled button. |
| `button_disabled_outline` | Color | `#7D7862` | `#727272` | Outline of a disabled button. |
| `button_disabled_hatch` | Color | `#DCD09B` | `#3A3A3A` | Diagonal hatch lines across a disabled face. |
| **Number pad, mode toggle and switch** | | | | |
| `pad_key_place_bg` | Color | `#FFFFFF` | `#232323` | Digit key face in Place mode. |
| `pad_key_place_text` | Color | `#111111` | `#FFFFFF` | Digit on a Place mode key. |
| `pad_key_cross_bg` | Color | `#111111` | `#FFFFFF` | Digit key face in Cross Out mode. |
| `pad_key_cross_text` | Color | `#FFFFFF` | `#111111` | Digit on a Cross Out mode key. |
| `pad_key_cross_mark` | Color | `#FF5FA2` | `#D1005A` | Corner stripe on Cross Out mode keys. |
| `mode_toggle_bg` | Color | `#FFFFFF` | `#232323` | Mode button that is not active (raised). |
| `mode_toggle_text` | Color | `#111111` | `#FFFFFF` | Label and icon on mode_toggle_bg. |
| `mode_toggle_active_bg` | Color | `#111111` | `#FFFFFF` | Active mode button (sunk into its shadow). |
| `mode_toggle_active_text` | Color | `#FFFFFF` | `#111111` | Label and icon on mode_toggle_active_bg. |
| `switch_on_bg` | Color | `#1A40D9` | `#FFE45C` | Switch track when on (knob right). |
| `switch_off_bg` | Color | `#E6DFC2` | `#3A3A3A` | Switch track when off (knob left). |
| `switch_knob` | Color | `#FFFFFF` | `#111111` | Switch knob, drawn with an outline. |
| **Board: frame, lines and cell fills** | | | | |
| `board_bg` | Color | `#FFFFFF` | `#1E1E1E` | Board card under the cells; shows at the rounded corners. |
| `line_cell` | Color | `#4A4A4A` | `#6A6A6A` | Lines between cells. |
| `line_box` | Color | `#111111` | `#FFE45C` | Lines between 3 by 3 boxes. |
| `line_outer` | Color | `#111111` | `#FFE45C` | The board's outer line. |
| `cell_bg` | Color | `#FFFFFF` | `#1E1E1E` | Plain cell. |
| `cell_selected_bg` | Color | `#FFE873` | `#424242` | Selected cell (fill priority 1). |
| `cell_peer_bg` | Color | `#DDF0FF` | `#1B2E3D` | Row, column and box of the selected cell (priority 6). |
| `cell_same_digit_bg` | Color | `#E5DDFF` | `#2E2552` | Other cells holding the selected cell's digit (priority 5). |
| `cell_conflict_bg` | Color | `#FFC6BE` | `#4A1A16` | Cell in a conflict (priority 2). |
| `cell_hint_target_bg` | Color | `#B4F0CB` | `#1D4A30` | Hint target cell (priority 3). |
| `cell_hint_reason_bg` | Color | `#DEF9E8` | `#163324` | Hint reason cell and lesson marked cell (priority 4). |
| **Board: digits, candidates and marks** | | | | |
| `digit_given` | Color | `#111111` | `#FFFFFF` | Given digit (heavy). |
| `digit_placed` | Color | `#1A40D9` | `#8FB0FF` | Placed digit (semibold). |
| `digit_conflict` | Color | `#9E0024` | `#FF96A3` | Given or placed digit in a conflict. |
| `candidate_open` | Color | `#111111` | `#F0F0F0` | Open candidate, and restored by hand. |
| `candidate_crossed` | Color | `#646464` | `#9A9A9A` | Digit of a candidate crossed by hand or by Auto Cross. |
| `cross_mark_hand` | Color | `#D1005A` | `#FF6FB5` | Hand X, drawn under its digit. |
| `cross_mark_auto` | Color | `#1236B8` | `#B3C8FF` | Auto Cross slash, drawn on top of its digit. |
| `selection_frame_place` | Color | `#1A40D9` | `#8FB0FF` | Selection frame in Place mode (solid). |
| `selection_frame_cross` | Color | `#D1005A` | `#FF6FB5` | Selection frame in Cross Out mode (dashed). |
| `hint_target_mark` | Color | `#087A38` | `#5BE08F` | Corner brackets on hint target cells. |
| `hint_reason_mark` | Color | `#087A38` | `#5BE08F` | Side ticks on hint reason cells and lesson marked cells; ring around a lesson marked control. |
| `hint_cross_bg` | Color | `#087A38` | `#5BE08F` | Chip behind an open candidate a hint says to cross, and the outline of its digit. The digit is drawn in `cell_bg`. |
| `conflict_mark` | Color | `#B8002A` | `#FF7A8A` | Bar under a conflict digit; the mark on the full board message. |
| **Board shape** | | | | |
| `line_cell_w` | float | `0.6` | `0.6` | Cell line weight, dp, at least 1 px. |
| `line_box_w` | float | `2.0` | `2.0` | Box line weight, dp. |
| `line_outer_w` | float | `3.0` | `3.0` | Outer line weight, dp, centered on the board edge. |
| `board_radius` | float | `5.0` | `5.0` | Corner radius of the board card, dp. |
| `ring_inset` | float | `2.75` | `2.75` | Cell edge to ring box, dp. |
| `candidate_gap` | float | `0.14` | `0.14` | Gap between neighboring candidate ink boxes, share of the candidate font size. |
| `digit_size` | float | `0.64` | `0.64` | Given and placed digit font size, share of the cell side. |
| `given_embolden` | float | `0.9` | `0.9` | Embolden of given digits (heavy). |
| `placed_embolden` | float | `0.0` | `0.0` | Embolden of placed digits (semibold). |
| `candidate_embolden` | float | `0.0` | `0.0` | Embolden of candidates (semibold). |
| `cross_mark_span` | float | `0.8` | `0.8` | Hand X and Auto Cross slash span this share of the slot box. |
| `cross_mark_w` | float | `1.4` | `1.4` | Stroke of the hand X and the Auto Cross slash, dp. |
| `knockout_w` | float | `0.4` | `0.4` | Outline around a hand-crossed digit, in the cell's fill, dp, at least 1 px. |
| `selection_frame_w` | float | `3.0` | `3.0` | Selection frame weight, dp, centered on the cell edge. |
| `selection_gap` | float | `0.15` | `0.15` | Cross Out frame: each of the two gaps per side, share of the side. |
| `selection_mid_dash` | float | `0.2` | `0.2` | Cross Out frame: the middle dash per side, share of the side. |
| `hint_mark_w` | float | `3.0` | `3.0` | Hint bracket and tick weight, dp, centered on the cell edge. |
| `hint_bracket_len` | float | `0.25` | `0.25` | Hint bracket arm from the corner, share of the side. |
| `hint_tick_len` | float | `0.22` | `0.22` | Hint tick length, share of the side. |
| `hint_cross_pad` | float | `0.05` | `0.05` | Hint cross chip: grows the slot box this share of the candidate font size above and below; its corner radius is twice that. |
| `conflict_bar_w` | float | `2.4` | `2.4` | Conflict bar weight, dp. |
| `conflict_bar_len` | float | `0.4` | `0.4` | Conflict bar length, share of the side. |
| `conflict_bar_y` | float | `0.84` | `0.84` | Conflict bar center from the cell top, share of the side. |
| **UI shape and spacing** | | | | |
| `outline_w` | float | `2.0` | `2.0` | UI outline weight, dp. |
| `shadow_offset` | float | `4.0` | `4.0` | Hard shadow offset right and down, dp. A press moves the face this far. |
| `radius_control` | float | `5.0` | `5.0` | Corner radius of buttons, keys, stickers, tags, switch track, dp. |
| `radius_card` | float | `6.0` | `6.0` | Corner radius of cards, panels and dialogs, dp. |
| `sticker_tilt` | float | `3.0` | `3.0` | Tilt of level stickers, degrees (counterclockwise). |
| `celebrate_tilt` | float | `6.0` | `6.0` | Tilt of the SOLVED! sticker, degrees (counterclockwise). |
| `hatch_w` | float | `1.5` | `1.5` | Disabled hatch line weight, dp. |
| `hatch_gap` | float | `6.0` | `6.0` | Disabled hatch line spacing, center to center, dp. |
| `page_margin` | float | `8.0` | `8.0` | Margin inside the safe area on every side, dp. |
| `space_xs` | float | `4.0` | `4.0` | Spacing step, dp. |
| `space_s` | float | `8.0` | `8.0` | Spacing step: key and row gaps, dp. |
| `space_m` | float | `12.0` | `12.0` | Spacing step: card padding, list gaps, dp. |
| `space_l` | float | `16.0` | `16.0` | Spacing step: dialog padding, dp. |
| `space_xl` | float | `24.0` | `24.0` | Spacing step: section gaps, dp. |
| `group_gap` | float | `20.0` | `20.0` | Gap between the digit keys and the right column of the pad, dp. |

Notes:

- 105 tokens: 67 colors and 38 numbers. A token row is one whose first cell is a name in backticks and whose type is Color or float; the rows in bold are group headings, not tokens.
- Shadows are hard: a copy of the shape in `shadow`, moved `shadow_offset` right and down, no blur.
- The fill priority numbers are explained in section 2.6.
- Draw a foreground only on the backgrounds the checker pairs it with (`SKIN_RULES` in `tools/design/check_contrast.gd`). Need another pair? Ask, and the checker gets it first.

## 2. The board

BoardPainter draws everything here from the skin. Sizes scale with nothing but the cell side, so the same rules hold from a 245 dp board on a 320 by 568 dp screen to a 593 dp board on a tablet.

### 2.1 Frame and lines

- The board is a square of 81 square cells. The cell side is the board side divided by 9. Lines are centered on cell edges, so every cell has the same pitch.
- The board card: `board_bg`, corners rounded by `board_radius` (the corner cells clip to it). The outer line, `line_outer_w` in `line_outer`, is centered on the board edge, so half of it falls outside. Behind it, the hard shadow in `shadow`, offset `shadow_offset`.
- Box lines: `line_box_w` in `line_box`. Cell lines: `line_cell_w` in `line_cell`. After pixel snapping the box line is at least 2.5 times the cell line at every density (the checker proves it at 2, 2.625 and 3); at density 2 that is 4 px against 1 px.

### 2.2 Digits

- Given and placed digits sit large in the center of the cell, centered on their ink box (the visible shape), not on the line box.
- Font size `digit_size` times the cell side.
- Given: `given_embolden` (heavy) in `digit_given`, ink black in light. Placed: `placed_embolden` (semibold) in `digit_placed`, electric blue. They differ by weight as well as color.
- In a conflict: the digit turns `digit_conflict` and gets the conflict bar (2.7).

### 2.3 The candidate ring

Layout A, reading rows. Every digit sits in the same slot in every cell; the center stays open.

```
1  2  3  4
5        6
7   8    9
```

- The ring box is the cell inset by `ring_inset` on every side. Each row of slots runs edge to edge in the ring box; rows are spread evenly top to bottom (as in `tools/design/directions/ring_layouts.gd`, which BoardPainter may copy).
- Candidate font size: the largest whole pixel size at which every digit's ink box fits with `candidate_gap` times the font size between neighbors, measured from the real digit shapes of the font with `candidate_embolden`. The size floor is in section 3.4.
- Open, and restored by hand: the digit in `candidate_open`. Restored by hand looks exactly like open.
- The slot box of a digit is the widest and tallest digit ink box centered on the slot. The mark box is the slot box scaled by `cross_mark_span`, centered, so marks on neighbors never touch.

### 2.4 Crossed by hand

1. Draw the X: both diagonals of the mark box, `cross_mark_w`, square ends, `cross_mark_hand`.
2. Draw the digit on top in `candidate_crossed`, with an outline of `knockout_w` (at least 1 px) in the color the cell is filled with right now (after the fill priority of 2.6).

The X shows at its four tips and between the strokes, and the digit reads clearly, even with all nine crossed (Bart's rule from Hard Stop 1).

### 2.5 Crossed by Auto Cross

1. Draw the digit in `candidate_crossed`, with no outline.
2. Draw one falling slash on top of it: the mark box's diagonal from top left to bottom right, `cross_mark_w`, square ends, `cross_mark_auto`.

Why this mark. The Phase 1 mark was a rising slash, bottom left to top right. It runs almost along the diagonal stroke of 7, and close to the strokes of 1, 2 and 4, so an auto-crossed 7 looked like a heavier 7. The study [design/auto-cross-study.png](design/auto-cross-study.png) (and [x3](design/auto-cross-study-x3.png)) draws six options on all nine digits at true size on a 720 px phone, in light and dark, on plain, selected and peer cells, next to hand Xs:

| Option | 1, 4 and 7 at 720 px | Verdict |
| --- | --- | --- |
| A rising slash on top, gray (Phase 1) | 1 and 7 read as italic digits, not crossed | Rejected |
| B falling slash on top, gray | Crosses 1, 4, 7, but gray on gray fuses: 7 turns into an X shape | Rejected |
| C falling slash under the digit, gray, with knockout | Digits read, but the slash breaks into short bits that look like noise | Rejected |
| D horizontal strike on top | 1 reads as a plus sign, the strike vanishes into the bar of 4, and a struck 7 is a normal European 7 | Rejected |
| E falling slash on top, blue | 1, 4 and 7 read as themselves and clearly crossed, light and dark | **Chosen** |
| F falling slash under, blue, with knockout | Same breakup as C | Rejected |

The falling direction crosses the rising strokes most digits have (1, 2, 4, 7, the tails of 6 and 9) instead of following them. The blue keeps the slash from fusing with the gray digit: it differs by hue, and by at least 1.5:1 in lightness (1.58:1 light, 1.69:1 dark; a checker rule), so it still separates in grayscale. Against the hand X it differs by shape (one stroke on top, against two strokes under the digit) and by color (blue against magenta).

### 2.6 Cell fills and their priority

A cell has one fill: the first that applies.

| Priority | State (GDD 2.3) | Fill | Only on |
| --- | --- | --- | --- |
| 1 | Selected | `cell_selected_bg` (lemon in light) | The selected cell |
| 2 | Conflict | `cell_conflict_bg` | Cells holding a digit |
| 3 | Hint target | `cell_hint_target_bg` | Hint target cells |
| 4 | Hint reason, lesson marked | `cell_hint_reason_bg` | Hint reason cells, lesson marked cells |
| 5 | Same digit | `cell_same_digit_bg` | Cells holding the selected cell's digit |
| 6 | Peer | `cell_peer_bg` | Row, column and box of the selected cell |
| 7 | Plain | `cell_bg` | Every other cell |

The fill is never the only sign of selected, conflict, hint target or hint reason: each has its own mark (2.7), drawn whatever the fill is. Same digit and peer are helpers and are shown by fill alone, which the GDD allows.

### 2.7 Marks

All marks except the hint cross chip are drawn on the cell edge or inside the cell's edge band (the band between the cell edge and the ring box). None covers a candidate: the ring box clears the frame and the marks by at least 1 dp (a checker rule). The hint cross chip is the one mark inside the ring; it sits behind its own candidate and clears the frame and the hint marks too.

**Selection frame.** `selection_frame_w`, centered on the cell edge. It shows the mode on the board, by shape and by color:

- Place mode: a solid frame in `selection_frame_place` (blue in light).
- Cross Out mode: a broken frame in `selection_frame_cross` (magenta, the color of the hand X and of the corner stripe on the Cross Out keys). Each side has a corner dash, a gap, a middle dash, a gap and a corner dash. The gaps are `selection_gap` of the side each, the middle dash `selection_mid_dash`, and each corner dash takes the rest, 0.25 of the side, joining the next side's corner dash into an L. First paint the whole frame band in the selected cell's fill, then the dashes on top, so the gaps show the fill and never a grid line underneath. In Phase 1 the lines showing through the gaps made the dashed frame look solid.

At arm's length the frame reads as a closed blue square or an open magenta one ([design/selection-study.png](design/selection-study.png), [x3](design/selection-study-x3.png)).

**Hint target.** Four corner brackets in `hint_target_mark`, `hint_mark_w` heavy, centered on the cell edge, each arm `hint_bracket_len` of the side long (it covers a corner dash of the Cross Out frame exactly).

**Hint reason, and lesson marked cells.** A tick centered on each side in `hint_reason_mark`, `hint_mark_w` heavy, centered on the cell edge, `hint_tick_len` of the side long (it covers a middle dash).

**Hint cross chip.** When a hint step crosses candidates, each candidate in `BoardDrawState.hint_crosses` (Hint.eliminations) that is still open, or restored by hand, is drawn inverted on a small solid chip. A candidate already crossed, by hand or by Auto Cross, is drawn as usual (2.4, 2.5) and gets no chip. The chip only ever appears in hint target cells, because GDD 10.2 makes every cell with a candidate to cross a target, so it always sits inside the green brackets.

1. The chip: the candidate's slot box (2.3), its full width, grown above and below by `hint_cross_pad` times the candidate font size, with corners rounded by twice that. Filled in `hint_cross_bg`. Snap its edges to whole device pixels.
2. The digit on top, in the slot, at the candidate font size and weight, in `cell_bg` (white in light, near black in dark), with an outline of `knockout_w` (at least 1 px) in `hint_cross_bg`. The outline keeps a rim of chip color around the ink wherever the digit's ink reaches the chip's sides, so a wide digit (2, 3, 4, 7, 8, 9 fill the slot box) never melts into the cell fill.

The chip does not grow sideways. In the top row (1 2 3 4) the slot boxes are only about 1.3 px apart at density 2 on the judged screen, so a wider chip would touch its neighbor's ink. Above and below there is room: the checker requires chips in neighboring rows to stay at least 1 px apart and every chip to clear the frame and the hint marks by at least 0.5 dp, at every judged density. Two highlighted neighbors in a row read as a short green band with two white digits in it, still 1 px apart; that is intended.

Why it reads, and what it is never confused with:

- **The highlight is a fill, everything else is a stroke.** An open candidate is dark ink on the cell fill. A crossed candidate is gray ink under a magenta X or a blue slash. A hint cross is a solid green block with the digit punched out of it, light on dark in light mode and dark on light in dark mode. No other state on the board puts a filled shape behind a candidate, so it differs from crossed by shape (filled block, no strokes) and by lightness (the digit flips), not only by color.
- **It is not the conflict state.** Conflict lives only in cells holding a digit, which show no ring, and uses red: a red digit, a red bar under it and a salmon fill. The chip is green, sits behind a small candidate in an empty cell, and has no bar.
- **It is not the same digit helper.** Same digit fills whole cells holding a digit in lilac. The chip marks one candidate inside an empty cell and is the hint green.
- **It belongs to the hint.** It is the same green as the brackets around it and the technique tag on the hint panel, so the player sees "the hint says: cross these".
- The checker holds `hint_cross_bg` at 3:1 against every fill a ring can sit on, `cell_bg` at 4.5:1 on the chip (the open candidate target), and `hint_cross_bg` at least 0.3 apart in color from the crossed digit, the hand X, the Auto Cross slash, the conflict colors and the same digit fill.

When the player crosses a highlighted candidate, its chip goes at once and the candidate draws as crossed, with the usual CROSS effect on top (section 6). Restoring it while the hint is still on screen brings the chip back. The chips appear and go with the hint, with no animation of their own (section 6: highlights change instantly).

**Conflict.** A bar under the digit in `conflict_mark`: `conflict_bar_w` heavy, `conflict_bar_len` of the side long, centered on `conflict_bar_y` of the side from the top. Only on cells holding a digit.

The hint marks are as heavy as the frame and drawn after it, so on a selected cell they replace the frame where they lie and stay whole; the frame still shows between them. The checker requires `hint_mark_w` at least `selection_frame_w`, brackets at least as long as the corner dash and ticks at least as long as the middle dash, and the frame, the hint marks and the box lines to differ in color.

### 2.8 How the states combine

| Cell | Fill | What else shows |
| --- | --- | --- |
| Selected, Place mode | Lemon | Solid blue frame |
| Selected, Cross Out mode | Lemon | Broken magenta frame |
| Selected and hint target | Lemon | Frame in its mode; green brackets over its corners |
| Hint target with candidates to cross, not selected | Mint | Green brackets; each open candidate the hint names sits on a green chip with its digit in white (near black in dark); every other candidate as usual |
| Selected hint target with candidates to cross, Place mode | Lemon | Solid blue frame; green brackets over its corners; the green chips |
| Selected hint target with candidates to cross, Cross Out mode | Lemon | Broken magenta frame; green brackets; the green chips. Crossing a chipped candidate takes its chip away at once and shows the hand X look || Selected and hint reason, or lesson marked | Lemon | Frame in its mode; green ticks over the middle of each side |
| Selected, in conflict, and hint target (wrong digit hint) | Lemon | Red digit and red bar; frame; green brackets. Never a chip: the cell holds a digit, so it shows no ring, and a wrong digit hint names nothing to cross |
| Conflict and hint target, not selected | Salmon | Red digit and red bar; green brackets. Never a chip, for the same reason |
| Hint target next to the selected cell | Mint | Its brackets are drawn over the selected cell's frame on the shared edge |
| Hint target and hint reason (if a hint ever names both) | Mint | Brackets and ticks |
| Same digit or peer | Lilac or sky blue | Nothing else |

Dark mode is the same with its own colors: a lifted gray selected cell, a light blue Place frame and a pink Cross Out frame.

### 2.9 Draw order

Bottom to top: board shadow and card; cell fills; cell lines; box lines; outer line; digits and rings (per candidate: the X, then the outlined digit; or the digit, then the slash; or, for a hint cross, the chip, then the outlined digit in `cell_bg`; or the plain digit); conflict bars; selection frame; hint ticks; hint brackets. Effects (section 6) draw last, through `draw_effects` on a layer above the board, so an animation never forces the whole board to redraw.

## 3. Type

### 3.1 Font and weights

Godot's built-in font only (Open Sans SemiBold, compiled into the engine). No font files ship. Weights and widths are made with `FontVariation`:

| Weight | `variation_embolden` | Used for |
| --- | --- | --- |
| Semibold | 0.0 | Body text, placed digits, candidates |
| Bold | 0.5 | Not used in v1; kept for a later need |
| Heavy | 0.9 | Display, titles, headings, buttons, captions, values, pad digits, given digits |

- Width below 1.0 condenses: `variation_transform` scales x by the width, and `spacing_glyph` pulls the letters back together by 0.55 times the font size times (1 minus the width), in pixels at the drawn size.
- Tracking is extra `spacing_glyph`, in dp converted to the drawn size.
- Capitals: the role sets text in capitals at display time (`to_upper()`); the source strings stay in sentence case.
- The default font's digits all have the same width, so the timer and scores do not jitter.

### 3.2 Roles

Sizes in dp. Line height is a multiple of the font size. ThemeFactory turns each role into the font settings of the styles in section 5.

| Role | Size | Weight | Capitals | Tracking | Width | Line height | Used for |
| --- | --- | --- | --- | --- | --- | --- | --- |
| display | 44 | Heavy | Yes | -0.5 | 0.84 | 1.0 | SOLVED!, PAUSED, the final score, the wordmark |
| title | 24 | Heavy | Yes | -0.25 | 0.86 | 1.1 | Screen titles |
| heading | 16 | Heavy | Yes | 0.25 | 1.0 | 1.2 | Level names, lesson titles, settings row names |
| value | 20 | Heavy | No | 0 | 0.86 | 1.0 | Stats values, receipt values |
| button | 14 | Heavy | Yes | 0.5 | 1.0 | 1.2 | Button labels, stickers, tags |
| mode | 14 | Heavy | Yes | 0 | 0.88 | 1.2 | PLACE and CROSS OUT on the mode buttons (3.5) |
| body | 14 | Semibold | No | 0 | 1.0 | 1.3 | Lesson text, dialog text, the first launch offer |
| body_small | 13 | Semibold | No | 0 | 1.0 | 1.3 | Hint text, subtitles, setting descriptions |
| body_small_12 | 12 | Semibold | No | 0 | 1.0 | 1.3 | Step down of body_small and body (below) |
| body_small_11 | 11 | Semibold | No | 0 | 1.0 | 1.3 | Last step down of body_small (below) |
| caption | 10 | Heavy | Yes | 0.75 | 1.0 | 1.2 | BEST TIME and other labels, STEP 5 OF 8, the level and time on Continue |
| pad_caption | 10 | Heavy | Yes | 0.75 | 1.0 | 1.2 | UNDO and ERASE under their icons, and TIME and SCORE in the header; line box trimmed by 2 dp at the top and the bottom (3.5, 3.6) |
| hud_value | 20 | Heavy | No | 0 | 0.86 | 1.0 | Time and score in the header: the value role with its line box trimmed by 4 dp at the top and the bottom (3.6) |
| pad_digit | 26 | Heavy | No | 0 | 1.0 | 1.0 | Digits on the pad keys; line box trimmed by 6 dp at the top and the bottom (3.5) |

Text that can be long steps down instead of overflowing: body to 13 and then 12 dp in the lesson card (section 4.8), body_small to 12 and then 11 dp in the hint panel (7.6). A step down is a change of `theme_type_variation`, never a font or size override: body (`BODY`) steps to `BODY_SMALL` (13 dp, the same 1.3 line height) and then `BODY_SMALL_12`; body_small (`BODY_SMALL`) steps to `BODY_SMALL_12` and then `BODY_SMALL_11`. Each variation carries its own line spacing, so a stepped text keeps its 1.3 line height. Nothing is ever cut off.

### 3.3 Board type

From the skin, because BoardPainter does not read the Theme: given and placed digits at `digit_size` of the cell side with `given_embolden` and `placed_embolden`; candidates fitted to the ring box (2.3) with `candidate_embolden`.

### 3.4 Candidate size floor

The floor GDD AT-66 checks against:

- **The candidate font size is at least 11 dp,** and the tallest candidate digit's ink is at least 8.5 dp tall.
- **Where:** on a screen 360 dp wide and tall enough that its width sets the board's size, for example 360 by 800 dp.
- **How it is measured:** the font size BoardPainter passes to `draw_string` for candidates, in device pixels, divided by the density. Or, on a screenshot, the height in pixels of the tallest digit's ink (the 4, 7 or 9) divided by the density.
- **What the design gives:** a 337 dp board, 37.4 dp cells and candidates of 11.5 dp at density 2 (23 px, tallest digit 19 px), 11.8 dp at 2.625 (31 px) and 11.7 dp at 3 (35 px). The checker computes this from the skin and fails below the floor.
- Candidate size is not judged on 320 by 568 dp, where it is 8.0 dp, or on 16:9 screens whose height limits the board (11.0 dp at 360 by 640).

### 3.5 Pad type: every label fits its face

Every pad label must fit inside its face on every screen, raised and sunk, so Godot never grows a button past its face and never clips a label. The faces stay as section 4.6 and 4.7 give them (no Layout constant changes): keys 40 to 64 dp tall, the right column at least 116 dp, Undo and Erase at least 54 dp wide. The look stays the same: same sizes, same weight, same icons, same layout.

How Godot sizes a pad button, in dp. The margins are the outline (2) plus the padding inside it, on each side. When the face sinks, the content moves 4 dp right and down, so the top and left margins grow by 4 and the bottom and right margins shrink by 4; the total stays the same while the padding is 2 dp or more. A line box is the font's ascent plus descent.

- Digit key height: margins plus the line box.
- Mode button width: margins plus the icon (20), the gap (`h_separation`, 8) and the label.
- Undo and Erase height, with the icon above the caption: Godot counts the line box twice (the text, then one more font height) and the icon at its full size. With `expand_icon` on, the icon is not counted and Godot fits it into the room the caption leaves, at most `icon_max_width` (20).

The fix:

1. **Digit keys: the pad_digit line box is trimmed** by 6 dp at the top and 6 at the bottom (`FontVariation.spacing_top` and `spacing_bottom` of -6). Digits have no descenders and nothing above their top, so the trim removes only empty space. The digit's ink keeps its place in the face: before and after, the ink sits 0.7 dp below the center of the line box, and the box is centered in the face.
2. **Mode buttons use the mode role:** 14 dp Heavy capitals like the button role, condensed to width 0.88 with no tracking, the same condensing as the value role. The side padding drops from `space_s` to `space_xs`. The label size and height do not change.
3. **Undo and Erase: the pad_caption line box is trimmed** by 2 dp at the top and the bottom (caption text is all capitals, so nothing below the baseline is used), their padding is 2 dp at the top and bottom, and their icon is fitted to the face (`expand_icon`). On 64 dp faces the icon draws as it does now; on 40 dp faces it steps down to about 14 dp, with the caption under it.

The arithmetic (measured with the real Theme by `tools/design/pad_fit.gd`; Godot rounds text sizes to whole dp):

| Button | Part | Before | After |
| --- | --- | --- | --- |
| Digit key, height | margins (2 + 4) x 2 | 12 | 12 |
| | pad_digit line box (ascent 28 + descent 8; trimmed 22 + 2) | 36 | 24 |
| | needs | 48 | 36 |
| CROSS OUT, width | margins: before (2 + 8) x 2, after (2 + 4) x 2 | 20 | 12 |
| | icon 20 and gap 8 | 28 | 28 |
| | label: button role 87, mode role 71 | 87 | 71 |
| | needs | 135 | 111 |
| PLACE, width | the same, label 48 then 40 | 96 | 80 |
| Mode buttons, height | margins (2 + 4) x 2 and the 20 dp line box | 32 | 32 |
| Undo and Erase, height | margins: before (2 + 4) x 2, after (2 + 2) x 2 | 12 | 8 |
| | icon: 20, then fitted to the room left | 20 | 0 |
| | caption line box counted twice: 14 + 14, then 10 + 10 | 28 | 20 |
| | needs | 60 | 28 |
| Undo and Erase, width | margins (2 + 4) x 2 and UNDO or ERASE, 35 | 47 | 47 |

What each screen gives and needs (face, then need, in dp):

| Screen | Digit key | PLACE | CROSS OUT | Undo and Erase |
| --- | --- | --- | --- | --- |
| 320 by 568 | 49.3 by 40; 27 by 36 | 116 by 40; 80 by 32 | 116 by 40; 111 by 32 | 54 by 40; 47 by 28 |
| 360 by 640 | 62.7 by 40; 27 by 36 | 116 by 40; 80 by 32 | 116 by 40; 111 by 32 | 54 by 40; 47 by 28 |
| 360 by 800 (judged) | 62.7 by 64; 27 by 36 | 116 by 64; 80 by 32 | 116 by 64; 111 by 32 | 54 by 64; 47 by 28 |
| 411 by 914 | 74 by 64; 27 by 36 | 133.3 by 64; 80 by 32 | 133.3 by 64; 111 by 32 | 62.6 by 64; 47 by 28 |
| 1024 by 1366 tablet | 133.3 by 64; 27 by 36 | 160 by 64; 80 by 32 | 160 by 64; 111 by 32 | 76 by 64; 47 by 28 |

The tightest fit is CROSS OUT, with 5 dp to spare on a 116 dp face; then the digit keys, with 4 dp in height on 40 dp faces. Touch areas do not change: every face plus the 8 dp gaps is at least 48 by 48. Before the fix, 26 pad labels on these five screens did not fit (`pad_fit.gd -- current`). Renders: [design/pad-fit.png](design/pad-fit.png) after, [design/pad-fit-current.png](design/pad-fit-current.png) before.

The mode names stay Place and Cross Out (GDD); nothing is shortened.

### 3.6 Header, Continue and hint panel: every label fits

Phase 4 found three places where the Theme made a control taller or wider than its design: the play screen's header row (62 dp against 48, so the board shrank), the Continue button (57 against 56) and the hint panel (124 dp against an 88 dp minimum). The fix is the pad's (3.5): trimmed line boxes, smaller paddings, and variations instead of overrides. The design does not change: the header row stays 48 dp with 40 dp faces, Continue stays 56, the hint panel stays inside the info zone. `tools/design/ui_fit.gd` measures all of it with the real Theme and the real PlayHud, HintPanel and UiKit code on the five screens of 4.10. Renders: [design/ui-fit.png](design/ui-fit.png) after, [design/ui-fit-current.png](design/ui-fit-current.png) before.

The fix:

1. **Time and score blocks** (`HUD_TIME`, `HUD_SCORE`): padding `space_s` at the sides and 2 dp at the top and bottom. Their captions use the pad_caption role (line box trimmed to 10 dp; TIME and SCORE are capitals, nothing below the baseline). Their values use the hud_value role: the value role with its line box trimmed by 4 dp at the top and the bottom (digits and the colon have no descenders and nothing above the digit top). The faces are 40 dp tall, the two lines centered in them.
2. **Hint button** (`HINT_BUTTON`): padding 2 dp on every side. The icon stays 20 dp at the left, the HINT caption and the cost stay in the caption role, untrimmed.
3. **Continue**: the second line gets its own variation; see 7.1.
4. **Hint panel**: padding `space_xs` at the top and bottom, and the close button moves out of the top row into its own column at the right; see 7.6.

The arithmetic, in dp (margins are the outline, 2, plus the padding, on each side):

| Control | Part | Before | After |
| --- | --- | --- | --- |
| Time and score block, height | margins: before (2 + 8) x 2, after (2 + 2) x 2 | 20 | 8 |
| | caption line box: caption 14, then pad_caption 10 | 14 | 10 |
| | value line box: value 28, then hud_value 20 | 28 | 20 |
| | needs (face 40) | 62 | 38 |
| Hint button, width | margins: before (2 + 4) x 2, after (2 + 2) x 2 | 12 | 8 |
| | icon 20, gap 4, HINT 28 (the cost is at most 27, "−200"), rounding 1 | 53 | 53 |
| | needs (face 64) | 65 | 61 |
| Hint button, height | margins, then two caption lines 14 + 14 less 2 of line spacing | 12 + 26 | 8 + 26 |
| | needs (face 40) | 38 | 34 |
| Header row, width at 320 by 568 | Hint 64, guard 4, time 80 (9:59:59 needs 79), score 61 (1000), guard 4, Pause 48, five gaps of 8 | 302 | 301 |
| | column | 304 | 304 |
| Header row, height | the tallest of: the blocks, the 48 dp touch areas of Hint and Pause | 62 | 48 |

What the header costs the board (4.7 rules, with the 32 dp notch and the 24 dp gesture bar):

| Screen | Header 62 (before) | Header 48 (after, the design) |
| --- | --- | --- |
| 320 by 568: 496 dp inside the margins, less info zone, 7 of outer line and shadow, gap 12, keys 136 | info zone 110, board 231, cells 25.7 | info zone 96, board 245, cells 27.2 |
| 360 by 800: 728 dp inside the margins | board 337 (width-bound), band 75, info zone 137, gap 39 | board 337, band 82, info zone 130, gap 40 |

On the judged screen the board keeps its size either way; the header only ate band. On 320 by 568 it cost the board 14 dp, a cell 1.5 dp and the candidates about half a dp, which is why the header must hold 48.

## 4. Shape, spacing, touch targets, safe areas and adaptation

### 4.1 Outlines, shadows, radii and stickers

- Every card, button, key, sticker, tag and the switch knob has an outline of `outline_w` in `outline`. Rules inside cards use the same weight and color.
- Cards, buttons, keys, stickers and the board cast a hard shadow (`shadow`, offset `shadow_offset` right and down). Tags, the scrim and the hatch cast none.
- Radii: `radius_control` for buttons, keys, stickers, tags and the switch track; `radius_card` for cards, panels and dialogs; `board_radius` for the board.
- Stickers tilt counterclockwise by `sticker_tilt`; the SOLVED! sticker by `celebrate_tilt`. Alternate stickers in a list tilt the other way.
- Icons (ARCHITECTURE section 7) are one color, with a stroke of 0.14 of the icon side, square ends and mitered corners, 20 dp in buttons and 24 dp in icon buttons.

### 4.2 Button states

| State | Look | Shown by more than color |
| --- | --- | --- |
| Normal | Face, outline and hard shadow | |
| Pressed | The face moves `shadow_offset` right and down into its shadow and the shadow hides; it springs back on release (section 6) | Position |
| Disabled | No shadow, the face stays where it is. Fill `button_disabled_bg`, outline `button_disabled_outline`, label and icon `button_disabled_text`. Diagonal hatch lines across the face: `hatch_w` heavy, `hatch_gap` apart center to center, rising at 45 degrees, in `button_disabled_hatch`, clipped to the face inside its outline and drawn under the label | No shadow and the hatch |
| Active (mode buttons, the selected skin) | Fill and text swap to the active colors and the face stays pressed into its shadow | Position, and the label names the mode |

The hatch needs code: a StyleBox subclass that draws the lines in `_draw` is one way (ui-motion-artist decides). Disabled never looks like active: active is pressed and solid, disabled is flat and hatched. Hint and Undo use the disabled state (GDD 10.4 and 7.2); tapping a disabled button does nothing and plays no press motion.

### 4.3 Spacing

The scale is `space_xs` 4, `space_s` 8, `space_m` 12, `space_l` 16 and `space_xl` 24 dp, plus `page_margin` 8 and `group_gap` 20. Key and row gaps are `space_s`; card padding and list gaps `space_m`; dialog padding `space_l`; gaps between sections `space_xl`.

### 4.4 Touch targets

- Everything the player taps has a touch area of at least 48 by 48 dp. The face may be smaller; its touch area then extends into the gaps around it and over its own shadow, never into another control's touch area.
- Keys: faces at least 40 dp tall, with 8 dp gaps, so each touch area is at least 48 dp. Icon buttons (Pause, back, close): 40 dp faces, 48 dp touch areas.
- Cells are not held to 48 dp (they are 27 to 66 dp); the board's 81 cells are the one deliberate exception, as on every Sudoku.

### 4.5 Safe areas

- `ScreenMetrics.safe_rect(viewport)` gives the safe area. The page color, the board's shadow and full screen overlays run edge to edge; every control, all text and the board stay inside the safe area, inset by `page_margin`.
- Nothing sits under a notch, a camera cutout, the status bar or the gesture bar. The bottom row of keys sits at least `page_margin` above the safe area's bottom edge.

### 4.6 Layout constants

The same in every skin, so not skin tokens. They are the constants of the `Layout` class in src/design (ARCHITECTURE section 7). All dp.

| Constant | Value | What it is |
| --- | --- | --- |
| `TOUCH_MIN` | 48 | Smallest touch area, both ways |
| `HEADER_ROW` | 48 | Height of the play screen's header row and of every title row |
| `BAND_MIN` | 48 | PlayArea's band: from the bottom of the header row to the board's outer edge. The header row plus the band is the info zone, at least 96 |
| `BAND_MAX` | 112 | The most the band grows (info zone 160) |
| `BOARD_GAP_MIN` | 12 | Bottom of the board's shadow to the top of the controls |
| `BOARD_GAP_MAX` | 40 | The most that gap grows |
| `KEY_MIN` | 40 | Key face height, smallest (every pad label fits a 40 dp face, 3.5) |
| `KEY_MAX` | 64 | Key face height, largest |
| `ACTION_RATIO` | 1.8 | Width of the pad's right column, as a multiple of a digit key's width |
| `ACTION_MIN` | 116 | Narrowest right column (CROSS OUT must fit: it needs 111, 3.5) |
| `ACTION_MAX` | 160 | Widest right column |
| `COLUMN_MAX` | 600 | Widest content column, centered, on tablets |
| `HINT_FACE_W` | 64 | Width of the Hint button's face |
| `ICON_FACE` | 40 | Face of every icon button (Pause, back, close on screens) and height of the header faces (Hint, time, score); its touch area is `TOUCH_MIN` |
| `CLOSE_FACE` | 32 | Face of the close button on the hint panel and the lesson card; touch area `TOUCH_MIN` |
| `BUTTON_TALL` | 56 | Face height of full width buttons: main menu, pause menu, completion, the first launch offer, the lesson NEXT button |
| `TIME_MIN_W` | 80 | Narrowest time block (it grows to fit 1:02:05) |
| `SCORE_MIN_W` | 60 | Narrowest score block |
| `HEADER_GUARD` | 12 | Smallest gap between Hint and the time block, and between the score block and Pause |
| `LESSON_TOP_ROW` | 32 | Height of the lesson card's top row |
| `LESSON_TITLE_MIN_BOARD` | 260 | The lesson title line hides when the board would be smaller |
| `LESSON_BOARD_FLOOR` | 220 | The lesson board never gets smaller; the lesson text scrolls instead |

`tools/design/layout_model.gd` implements these rules for the play and lesson screens, and `check_samples.gd` runs it on the screens in 4.10.

**Which sizes are Layout constants** (Phase 4 decision). A size goes in `Layout` when more than one area reads it, so no two areas keep their own copy of a number. `ICON_FACE`, `CLOSE_FACE` and `BUTTON_TALL` moved there for that reason: src/ui, src/lessons and ThemeFactory each had their own 40, 32 and 56. A size that one area alone uses stays a named constant in that area's code, as long as this document gives its value. Today that is `UiSizes` in src/ui (ui-systems-dev):

| UiSizes constant | Value | Section |
| --- | --- | --- |
| `BUTTON_DIALOG` | 48 | Dialog button faces (7.4, 7.11) |
| `ROW` | 64 | Level select rows and settings rows (7.3, 7.11) |
| `SKIN_OPTION_H` | 120 | Skin option cards (7.11) |
| `PIP` | 10 | Level select pips (7.3) |
| `LESSON_SQUARE` | 24 | Lessons completed squares (7.10) |
| `DIALOG_MAX_W` | 328 | Widest dialog card (4.9) |
| `HERO_MIN`, `HERO_MAX` | 64, 200 | The hero on the main menu and first launch offer (7.1, 7.2) |
| `HERO_LAYER` | 108/66 | Hero drawing rect against its box (7.1) |

And in src/lessons (lessons-dev): the lessons list row (72) and number sticker (36) of 7.12. If a second area ever needs one of these, it moves to `Layout` first.

### 4.7 The play screen, and how it adapts

Top to bottom inside the safe area, inset by `page_margin`, in a column `min(width, COLUMN_MAX)` wide and centered:

1. **Info zone:** the header row (Hint, time and score, Pause; the play screen's own) and below it the band, the top of PlayArea (`band_rect_global()`), which holds the level sticker. The hint panel and the full board message cover the whole info zone, header row and band together (7.6).
2. **Board:** the largest square that fits, plus its outer line and shadow.
3. **Gap.**
4. **Controls:** three rows of keys.

This is the stacked arrangement. Wide and short windows put the pad beside the board instead, and very small windows show a message; section 4.11 says when. From Phase 6 PlayArea receives the whole safe rect, reserves the header row at the top of its column (the play screen sets its height to `HEADER_ROW`, the lesson player to 0) and lays out items 1 to 4; the numbers below do not change. How the height is shared:

1. Start from the minimums: band `BAND_MIN`, gap `BOARD_GAP_MIN`, keys `KEY_MIN`.
2. The board takes the rest, up to the column width minus its outer line and shadow. On tall screens it is width-bound; on short ones the height limits it.
3. Leftover height grows the keys to `KEY_MAX`.
4. Then half of what is left grows the band, up to `BAND_MAX` (the Hint button moves further from the board), and the rest grows the gap, up to `BOARD_GAP_MAX`.
5. Anything still left is split equally above and below the whole stack.

Widths: the three digit columns, the `group_gap`, and the right column share the column width minus the shadow; the right column is `ACTION_RATIO` times a key's width, clamped to `ACTION_MIN` and `ACTION_MAX`.

### 4.8 The lesson screen, and how it adapts

The same stack, with no header row: the lesson card sits in PlayArea's band, and the band is as tall as the card. The card holds a top row (the lesson sticker, the step caption and the close button), the lesson title and the step text.

**Height: the card reserves room for its tallest text** (Phase 4 decision, approving lessons-dev's approach). The card is as tall as the tallest of: the step text, and each wrong tap text of the same screen with the NOT QUITE tag above it. So the board never moves when a wrong tap shows or goes. The text sits at the top of its room; when a shorter text shows, the room under it stays empty card. That empty space is the price of a board that never jumps, and a still board matters more (readability first). Two limits keep it small: the room is per screen, never per lesson, and only that screen's wrong tap texts count. If a screen leaves more than about two empty lines under its step text, the fix is shorter wrong tap text (lesson-designer), not a moving board.

Side by side (4.11) the card sits in the side column, with a simpler rule; see 4.11. Stacked, on short screens, in this order:

1. The text steps down from 14 to 13 to 12 dp (`BODY`, then `BODY_SMALL`, then `BODY_SMALL_12`; section 3.2) while the board would be under 80 percent of its width-bound size.
2. The title line hides when the board would be under `LESSON_TITLE_MIN_BOARD`. The lesson sticker still says which lesson it is.
3. The board never goes under `LESSON_BOARD_FLOOR`. If the text still does not fit, the card stops growing and the text scrolls inside it, with a fade at the bottom edge and a small down arrow while there is more. This happens only on screens as short as 320 by 568 dp.

### 4.9 Every other screen

- Title row (`HEADER_ROW`): a back or close icon button at the left, the title in title style beside it.
- Lists (level select, stats, lessons list, settings) scroll when they do not fit; the title row stays put. At 360 by 800 dp every list fits without scrolling except stats.
- Dialogs: centered, at most 328 dp wide and at least 16 dp from the safe area's sides, over the scrim.
- Full screen overlays (the pause menu, the first launch offer) fill the screen in `page_bg` and center their content in the safe area.
- The same `COLUMN_MAX` and centering apply on tablets.
- In wide and short windows the main menu, the first launch offer, the pause menu and the completion screen split into two halves; lists and dialogs do not change (4.11).

### 4.10 Sizes on the screens we design for

From `check_samples.gd`, with insets for a notch (24 to 32 dp) and a gesture bar (24 dp). Candidates at density 2.

| Screen | Board | Cell | Candidates | Info zone | Keys (face) | Right column |
| --- | --- | --- | --- | --- | --- | --- |
| 320 by 568 | 245 (height-bound) | 27.2 | 8.0 dp | 96 | 49 by 40 | 116 |
| 360 by 640 | 325 (height-bound) | 36.1 | 11.0 dp | 96 | 63 by 40 | 116 |
| 360 by 800 (judged) | 337 (width-bound) | 37.4 | 11.5 dp | 130 | 63 by 64 | 116 |
| 411 by 914 (1080 by 2400 px) | 388 (width-bound) | 43.2 | 13.5 dp | 160 | 74 by 64 | 133 |
| 1024 by 1366 tablet | 593 (width-bound) | 65.9 | 22.0 dp | 160 | 133 by 64 | 160 |

Lesson screen boards: 220 dp at 320 by 568 (12 dp text, no title line, the text scrolls), 277 dp at 360 by 640, and the full width-bound board from 360 by 800 up.

### 4.11 Window shapes: foldables and split screen

Bart, Phase 6: split screen is allowed, and the game must lay out well in any window a foldable gives it (Galaxy Z Fold5 cover and inner screens, split screen on either), including wide and short windows. The device stays portrait; the window shape varies. Two arrangements cover every shape, and below a floor the game says the window is too small.

**The content box.** Every rule here starts from the content box: the window's safe area (4.5) inset by `page_margin` on every side. W and H are its width and height in dp. Every screen gets the arrangement from one shared function (below), so the play screen, the lesson player and the menus always agree.

**The two arrangements.**

- **Stacked** (4.7, 4.8, unchanged): info zone, board, gap, pad, top to bottom, in a column `min(W, COLUMN_MAX)` wide.
- **Side by side**: the board at the left, as large as H allows; then `SIDE_GAP`; then the **side column**, `COLUMN_MIN` to `SIDE_MAX` wide, holding top to bottom the header row, the band (together the info zone, as on the stacked screen) and the pad. The board's top and the side column's top line up, and the pad's bottom lines up with the board's bottom whenever the side column is full.

```
┌───────────────────────────────────────────────────────────────┐
│ ┌───────────────────────────┐  [II] [TIME][SCORE]    [HINT ]  │ header row 48, mirrored:
│ │                           │                                 │ Hint at the far end from the board
│ │                           │  (MEDIUM)                       │ band: level sticker; the hint panel
│ │        board 345          │                                 │ covers header row and band
│ │                           │  [1][2][3]   20   [ PLACE     ] │
│ │                           │  [4][5][6]        [ CROSS OUT ] │ the same pad, side column width
│ │                           │  [7][8][9]        [UNDO][ERASE] │
│ └───────────────────────────┘                                 │
└───────────────────────────────────────────────────────────────┘
  board 345 + 7          16          side column 306           (inner top half, 690 by 400)
```

**Which one.** Work out the play board both ways and take the larger; stacked on a tie:

- Stacked board: `Bs = min(min(W, COLUMN_MAX) - 7, H - 251)`, or 0 when `W < COLUMN_MIN`. 7 is the outer line (3) plus the shadow (4); 251 is the header row 48, `BAND_MIN` 48, the 7, `BOARD_GAP_MIN` 12 and the pad at its minimum, 3 keys of 40 and 2 gaps of 8, 136.
- Side by side board: `Bw = min(H - 7, W - 7 - SIDE_GAP - COLUMN_MIN, COLUMN_MAX - 7)`, that is `min(H - 7, W - 327, 593)`, or 0 when H is under the side column's minimum, 48 + 48 + 136 = 232.
- **Side by side when `Bw > Bs`**, otherwise stacked.
- **Too small** when `H < CONTENT_MIN_H` or `max(Bs, Bw) < BOARD_MIN`.

The breakpoints, in content box dp:

- Stacked works from 304 wide and 491 tall: a window of 320 by 507 plus its insets. 320 by 568 with a 32 dp status bar and a 24 dp gesture bar is inside that (H 496, board 245), so the Hard Stop 1 promise holds.
- Side by side works from 567 wide and 264 tall: a window of 583 by 280 plus its insets, board 240.
- Between them, side by side wins whenever `min(H - 7, W - 327) > min(min(W, 600) - 7, H - 251)`. Roughly: once the window is wider than about its height plus 76 dp, and H is under about 600.
- No hysteresis: Android split screen snaps to fixed ratios, so the shape does not wobble around a breakpoint.

**New Layout constants.** ui-motion-artist adds them to `Layout`. When that lands, these rows move into the first table of 4.6 and `tests/design/test_layout.gd` counts 27 constants instead of 22, in the same integration step, so the test never sees one without the other.

| Constant | Value | What it is |
| --- | --- | --- |
| `COLUMN_MIN` | 304 | Narrowest column that holds the header row and the pad, stacked or beside the board. It is the 320 dp screen's column, where both are proven to fit (3.5; 3.6: the header row needs 301) |
| `SIDE_MAX` | 360 | Widest side column. Wider windows center the board and the side column as a group |
| `SIDE_GAP` | 16 | From the board's outer line and shadow to the side column |
| `BOARD_MIN` | 240 | Smallest play board in either arrangement. Under it the window is too small |
| `CONTENT_MIN_H` | 264 | Shortest content box in any arrangement: the main menu's button stack (4 rows of 56, 3 gaps of 12, the 4 dp shadow) |

`LESSON_BOARD_FLOOR` (220) stays for the stacked lesson screen, under `BOARD_MIN` on purpose: a window that can play can always show a lesson, because the lesson card can scroll.

**The shared function.** `Layout.arrangement(content: Vector2, skin: GameSkin) -> int` returns `Layout.Arrangement.STACKED`, `SIDE` or `TOO_SMALL` by the rule above, with `Layout.stacked_board(content, skin)` and `Layout.side_board(content, skin)` beside it (the skin gives the outer line, the shadow and `space_s`). `tools/design/layout_model.gd` holds the reference version of all three; the code must give the same answers on every window in the table below.

#### The play screen, side by side

- PlayArea lays out everything from the whole safe rect: the board at the left, the side column at the right, the two centered as a group when the content box is wider than they need. When the board's width limits it, the board is centered vertically in H.
- The side column's height is shared like the stacked one, with no board in it: start from the header row 48, `BAND_MIN` and the pad at `KEY_MIN`; the keys grow first, to `KEY_MAX`; then the band, to `BAND_MAX`; anything left is split above and below the side column.
- **Header row, mirrored:** Pause at the left, next to the board; time and score centered; Hint at the right end. Hint must never sit next to the board, where a slip from a cell would buy a hint (the reason Hint moved in Phase 2). Next to the board, Pause is harmless: a slip there only pauses. Faces, guards and sizes are those of 7.5.
- **Band:** the level sticker, `space_s` above the pad's left end, as it sits above the board when stacked.
- **Hint panel and full board message:** they cover the side column's info zone (header row and band, down to `space_s` above the pad): the 7.6 rule in a different place. They never cover a cell. The panel is the side column's width, and its text steps down by the 7.6 rule (`ui_fit.gd` measures every hint text on every window below; side by side the longest need 12 dp, as at 320 by 568).
- **Pad:** NumberPad does not change; it lays out in the side column's width with the 4.7 widths.
- Touch areas stay at least 48 by 48. The pad is never narrower than at 320 by 568.

#### The lesson player, side by side

- The board sits at the left like the play board. The side column holds the lesson card (there is no header row) and the pad.
- The card takes the height its text needs (4.8: the tallest of the step text and the wrong tap texts), up to H minus the pad at its minimum (136). If it does not fit, in this order: the text steps from 14 to 13 to 12 dp; the title line hides; the text scrolls in the card (4.8). The board does not change with the card, so the stacked rule "while the board is under 80 percent" does not apply here.
- The keys grow from what the card leaves. The praise card and NEXT cover the pad as on the stacked screen (7.13), growing upward over the lesson card when needed. The pulsing ring around a marked control follows the control.

#### Menus, lists, dialogs and overlays

Every screen reads the same arrangement. Stacked, every screen is as in section 7. Side by side:

- **Main menu and first launch offer:** two halves of the column `min(W, COLUMN_MAX)`, `space_xl` apart. Left: the wordmark at the top and the hero under it, filling the height left (64 to 200, 7.1). Right: the buttons (on the first launch offer, the card and its two buttons), centered vertically. At the inner top half the halves are 288 wide; the left has 352 - 66 - 48 = 238 for the hero, so it is 200; the buttons take 264 of 352.
- **Pause menu:** two halves the same way. Left: PAUSED, the level sticker and the paused time (about 118). Right: RESUME, SETTINGS and MENU (196), centered.
- **Completion:** two halves. Left: the starburst with SOLVED! and the level sticker, shrinking to the height. Right: the receipt, then PLAY AGAIN and MENU pinned at the bottom. When the receipt with both NEW BEST labels does not fit above the buttons, the receipt scrolls; the buttons never move.
- **Lists** (level select, stats, settings, lessons list): no change. One column `min(W, COLUMN_MAX)` wide, the title row fixed, the list scrolls (all four already scroll).
- **Dialogs** (7.4, the Reset dialog of 7.11, the making a puzzle card of 7.14): no change in either arrangement; centered, at most 328 wide. A dialog card is never taller than the content box: if it would be, its text scrolls and its buttons stay in view. At the smallest supported height, 264, the tallest one (7.4: three lines of text and two 48 dp buttons) needs about 215.

#### Smaller than that: the too small message

When the window is too small, the game does not squeeze the board. At 344 by 430 the best board would be 131 dp, with cells of 14.6 dp and candidates under 4 dp: nobody can read that. Instead:

- A full screen layer over every screen, in `PAGE` (`page_bg`), takes every tap. Centered in the safe area: the hero (the app icon foreground) in a 64 dp box when the content box is at least 160 tall, hidden below that; under it, in `BODY`, centered and wrapped: "This window is too small. Make it bigger to play." (the lead-game-designer owns the exact words in the GDD). Nothing on it is tappable. Its colors are a pair the checker already holds (`text` on `page_bg`).
- On the play screen the timer stops at once and the pause menu opens under the layer, exactly as when the app loses focus (GDD 8). When the window grows back, the layer goes and the player is on the pause menu. A puzzle that is being made when the window shrinks opens paused, as for focus loss (Phase 6 fix).
- Android Back does what it does on the screen underneath.
- Layout underneath still runs, clamped so no size goes below zero; the layer covers it.

#### The windows, with the arithmetic

Fold5 density is 2.625 (the cover is 904 by 2316 px, the inner screen 1812 by 2176 px). A window gets the 32 dp status bar inset only when it touches the top of the screen, and the 24 dp gesture bar inset only when it touches the bottom; the taskbar row assumes 48 at the bottom of the inner screen. W = width - 16; H = height - insets - 16. Candidates in dp at 2.625. Numbers from `check_samples.gd`.

| Window | W by H | Bs (stacked) | Bw (side by side) | Result | Board, cell, candidates | Column, keys, info zone |
| --- | --- | --- | --- | --- | --- | --- |
| Cover, 344 by 882 | 328 by 810 | min(321, 810 - 251 = 559) = **321** | min(803, 328 - 327 = 1) = 1 | Stacked | 321 width-bound, 35.7, 11.0 dp | column 328; keys 57 by 64; info zone 160, gap 40, 37 spare above and below |
| Inner, 690 by 829 | 674 by 757 | min(600 - 7 = 593, 757 - 251 = 506) = **506** | min(750, 674 - 327 = 347) = 347 | Stacked | 506 height-bound, 56.2, 18.7 dp | column 600; keys 133 by 40; info zone 96 |
| Inner, taskbar shown | 674 by 733 | **482** | 347 | Stacked | 482, 53.6, 17.5 dp | as above |
| Inner left or right half, 345 by 829 | 329 by 757 | min(322, 506) = **322** | min(750, 2) = 2 | Stacked | 322 width-bound, 35.8, 11.0 dp | column 329; keys 58 by 64; info zone 152 |
| Inner top half, 690 by 400 (status bar) | 674 by 352 | min(593, 352 - 251 = 101) = 101 | min(345, 347) = **345** | Side by side | 345 height-bound, 38.3, 11.8 dp | side column 674 - 352 - 16 = 306; keys 50 by 64; info zone 144 (hint panel 136) |
| Inner bottom half, 690 by 400 (gesture bar) | 674 by 360 | 109 | min(353, 347) = **347** | Side by side | 347 width-bound, 38.6, 12.2 dp | side column 304; keys 49 by 64; info zone 152; board centered, 3 above and below |
| Cover top half, 344 by 430 | 328 by 382 | 131 | 1 | **Too small** | | message |
| Cover bottom half, 344 by 430 | 328 by 390 | 139 | 1 | **Too small** | | message |
| Inner two thirds wide, 460 by 829 | 444 by 757 | **437** | 117 | Stacked | 437, 48.6, 15.6 dp | |
| Inner one third wide, 230 by 829 | 214 by 757 | 0 (under 304 wide) | 0 | **Too small** | | message |
| Inner top two thirds, 690 by 553 | 674 by 505 | 254 | **347** | Side by side | 347 width-bound, 38.6, 12.2 dp | side column 304; info zone 160 |
| Inner bottom third, 690 by 276 | 674 by 236 | 0 | 229 | **Too small** (H under 264) | | message |
| Cover top two thirds, 344 by 588 | 328 by 540 | **289** | 1 | Stacked | 289 height-bound, 32.1, 9.5 dp | |
| QA L6 window, 700 by 420, no insets | 684 by 404 | 153 | **357** | Side by side | 357, 39.7, 12.6 dp | the board there is about 160 today (QA L6) |

The lesson screen on the same windows: the cover and the inner halves keep the full board, 14 dp text and the title; the full inner screen gets a 448 dp board with 12 dp text (424 with the taskbar); the inner top half, side by side, a 345 dp board with 13 dp text and the title; the cover top two thirds a 224 dp board, 12 dp text, no title line, all text showing.

**Readability.** The judgment stays at 360 dp wide (3.4) and does not move. On the windows Bart uses: 11.0 dp candidates on the cover screen and on an inner half (exactly the 11 dp floor, at 344 and 345 dp wide), 11.8 to 12.6 dp side by side on the inner screen, and 18.7 dp on the full inner screen. The smallest supported boards (240 dp, about 7.6 dp candidates) are like 320 by 568: they fit and work, and are not judged.

Picture: [design/window-shapes.png](design/window-shapes.png), drawn by `tools/design/window_fit.gd` from the model. The faces are drawn at their real sizes; digits and labels are left out.

## 5. Theme styles

`ThemeFactory` exposes one type variation per row as a constant (ARCHITECTURE section 7). Screens set `theme_type_variation` and never set colors, sizes or fonts. Names are final: the constant, and the variation name in quotes.

Text (base `Label`):

| Constant | Variation | Look |
| --- | --- | --- |
| `DISPLAY` | "Display" | display role, `text` |
| `DISPLAY_ACCENT` | "DisplayAccent" | display role, `text_accent` (the final score) |
| `TITLE` | "Title" | title role, `text` |
| `HEADING` | "Heading" | heading role, `text` |
| `BODY` | "Body" | body role, `text` |
| `BODY_SMALL` | "BodySmall" | body_small role, `text` |
| `BODY_MUTED` | "BodyMuted" | body_small role, `text_muted` |
| `BODY_SMALL_12` | "BodySmall12" | body_small_12 role, `text` (step down, 3.2) |
| `BODY_SMALL_11` | "BodySmall11" | body_small_11 role, `text` (last step down of the hint text, 3.2) |
| `CAPTION` | "Caption" | caption role, `text_muted` |
| `VALUE` | "Value" | value role, `text` |
| `HUD_CAPTION` | "HudCaption" | pad_caption role (trimmed, 3.6), `hud_label` |
| `HUD_VALUE` | "HudValue" | hud_value role (trimmed, 3.6), `hud_text` |
| `SCORE_CAPTION` | "ScoreCaption" | pad_caption role, `hud_score_text` |
| `SCORE_VALUE` | "ScoreValue" | hud_value role, `hud_score_text` |
| `STICKER_LABEL` | "StickerLabel" | button role, `sticker_text` |
| `CELEBRATE_LABEL` | "CelebrateLabel" | caption role, `celebrate_text` (NEW BEST labels, the lesson NOT QUITE tag) |
| `CELEBRATE_DISPLAY` | "CelebrateDisplay" | display role, `celebrate_text` (SOLVED!, the SUDOKU wordmark) |
| `HINT_TAG_LABEL` | "HintTagLabel" | caption role, `hint_tag_text` |
| `PRIMARY_LABEL` | "PrimaryLabel" | button role, `button_primary_text`: a label inside a primary button (the first line of Continue, 7.1) |
| `PRIMARY_CAPTION` | "PrimaryCaption" | caption role, `button_primary_text`: a caption line inside a primary button (the level and time on Continue, 7.1) |

Panels (base `PanelContainer`, except `PAGE` and `SCRIM`, base `Panel`):

| Constant | Variation | Look |
| --- | --- | --- |
| `PAGE` | "Page" | `page_bg`, no outline, no shadow |
| `SCRIM` | "Scrim" | `scrim` |
| `CARD` | "Card" | `surface_bg`, outline, shadow, `radius_card`, padding `space_m` |
| `DIALOG` | "Dialog" | as `CARD`, padding `space_l` |
| `HINT_PANEL` | "HintPanel" | as `CARD`, padding `space_xs` at the top and bottom, `space_m` at the sides (3.6) |
| `LESSON_CARD` | "LessonCard" | as `CARD` |
| `BOARD_MESSAGE` | "BoardMessage" | as `HINT_PANEL`, with a bar in `conflict_mark` along its left inside edge, `conflict_bar_w` wide (the full board message) |
| `HUD_TIME` | "HudTime" | `hud_bg`, outline, shadow, `radius_control`, padding `space_s` at the sides and 2 dp at the top and bottom (3.6) |
| `HUD_SCORE` | "HudScore" | `hud_score_bg`, outline, shadow, `radius_control`, padding as `HUD_TIME` |
| `STICKER` | "Sticker" | `sticker_bg`, outline, shadow, `radius_control`, padding `space_s` by `space_xs` |
| `CELEBRATE_STICKER` | "CelebrateSticker" | as `STICKER` in `celebrate_bg` |
| `HINT_TAG` | "HintTag" | `hint_tag_bg`, no outline, no shadow, `radius_control`, padding `space_s` by 2 dp |

Controls:

| Constant | Variation | Base | Look |
| --- | --- | --- | --- |
| `BUTTON_PRIMARY` | "ButtonPrimary" | Button | `button_primary_bg` and `button_primary_text`, button role, all states of 4.2 |
| `BUTTON_SECONDARY` | "ButtonSecondary" | Button | `button_bg` and `button_text` |
| `BUTTON_DANGER` | "ButtonDanger" | Button | `button_danger_bg` and `button_danger_text` |
| `HINT_BUTTON` | "HintButton" | Button | as `BUTTON_PRIMARY`; holds the hint icon (20 dp, at the left) and two caption role lines, HINT and the cost, all in `button_primary_text`; padding 2 dp on every side, `h_separation` `space_xs` (3.6) |
| `ICON_BUTTON` | "IconButton" | Button | as `BUTTON_SECONDARY`, a `Layout.ICON_FACE` (40 dp) square face, a 24 dp icon |
| `PAD_KEY_PLACE` | "PadKeyPlace" | Button | `pad_key_place_bg` and `pad_key_place_text`, `radius_control`, pad_digit role with its trimmed line box (3.5), padding `space_xs` |
| `PAD_KEY_CROSS` | "PadKeyCross" | Button | `pad_key_cross_bg` and `pad_key_cross_text`, and a stripe in `pad_key_cross_mark` across the top right corner, between 0.2 and 0.4 of the face width from the corner, drawn inside the outline |
| `PAD_ACTION` | "PadAction" | Button | as `BUTTON_SECONDARY`; the icon over a caption in the pad_caption role (Undo, Erase); padding `space_xs` at the sides and 2 dp at the top and bottom; `icon_max_width` 20 and the icon fitted to the face (`expand_icon`, set by the pad), so it is 20 dp at most (3.5) |
| `MODE_BUTTON` | "ModeButton" | Button (toggle) | normal: `mode_toggle_bg` and `mode_toggle_text`, raised; pressed: `mode_toggle_active_bg` and `mode_toggle_active_text`, sunk; icon and label on one line, the label in the mode role; padding `space_xs` on every side, `h_separation` `space_s` (3.5) |
| `LIST_BUTTON` | "ListButton" | Button | as `BUTTON_SECONDARY`, content left aligned, padding `space_m` (level select and lesson rows) |
| `SKIN_OPTION` | "SkinOption" | Button (toggle) | a card that sinks when selected and shows the check icon in a `sticker_bg` badge |
| `SWITCH` | "Switch" | CheckButton | track `radius_control`, 44 by 26 dp, `switch_off_bg` or `switch_on_bg` with the outline; a 20 dp square knob in `switch_knob` with the outline, left when off and right when on; an OFF or ON caption beside it. Drawn in code, no textures |
| `RULE` | "Rule" | HSeparator | `outline`, `outline_w` |
| `STAT_BAR` | "StatBar" | ProgressBar | track `surface_alt_bg` with the outline, fill `chart_bar`, 16 dp tall, `radius_control` |

## 6. Motion

Motion is quick and never blocks input:

- The game state changes the moment the input arrives; animations only show it. The click plays at once.
- A new input finishes any running animation on the same thing at once and starts its own. Input is never queued behind an animation, and no control waits for one before it accepts taps.
- No single animation runs longer than 400 ms, except the completion score count (600 ms) and two loops: the lesson mark pulse and the rocking hero while a puzzle is made (7.14).
- Board effects run through `CellEffect` and `BoardPainter.draw_effects` on a layer above the board, so the board itself does not redraw every frame.
- Undo plays the effect of the reverse action (undoing a placement plays ERASE).
- Selection, highlights, hint cross chips, the selection frame's mode, conflicts and Auto Cross marks change instantly, with no animation.

`Motion` holds these as constants. Times in ms; transition and ease are Godot `Tween` names.

| Constant | Time | Transition, ease | What moves |
| --- | --- | --- | --- |
| `PRESS_DOWN` | 60 | QUAD, OUT | Face into its shadow on touch down |
| `PRESS_UP` | 140 | BACK, OUT | Face springs back on release |
| `PLACE` | 140 | BACK, OUT | Placed digit scales from 0.6 to 1 and fades in; the ring fades out over the first 80 ms |
| `ERASE` | 100 | QUAD, IN | Digit scales to 0.8 and fades out; the ring fades in over 120 ms from the start |
| `CROSS` | 100 | QUAD, OUT | Hand X scales from 1.3 to 1 around the slot center and fades in; the digit turns gray at once |
| `RESTORE` | 80 | QUAD, IN | Hand X scales to 0.8 and fades out; the digit turns open at once |
| `COMPLETE_WAVE` | 180 | SINE, IN_OUT | Each digit scales to 1.08 and back |
| `COMPLETE_STAGGER` | 12 | | Delay per step of row plus column, from the top left (the wave ends after 372 ms) |
| `MODE_SWITCH` | 120 | QUAD, OUT | Pad keys cross-fade between their Place and Cross Out looks; the corner stripe slides in from the corner |
| `SCORE_CHANGE` | 300 | CUBIC, OUT | The score value counts down to its new value after a hint, and its block does a press |
| `PANEL_IN` | 200 | QUART, OUT | Hint panel and full board message slide down from above the info zone and fade in |
| `PANEL_OUT` | 140 | QUART, IN | Reverse |
| `MARK_POP` | 160 | BACK, OUT | Hint brackets and ticks scale from 1.4 to 1 around their cell as the panel opens |
| `DIALOG_IN` | 180 | BACK, OUT | Dialog card scales from 0.9 to 1 and fades in; the scrim fades in over 150 ms (`Motion.appear`) |
| `DIALOG_OUT` | 120 | QUAD, IN | Reverse (`Motion.disappear`) |
| `SCREEN_IN` | 200 | QUART, OUT | New screen slides 24 dp from the side it comes from and fades in; input goes to it at once |
| `SCREEN_OUT` | 120 | QUAD, IN | Old screen fades out, at the same time |
| `PAUSE_IN` | 150 | QUAD, OUT | Pause menu fades in. The board is hidden on the frame of the tap, not faded |
| `PAUSE_OUT` | 120 | QUAD, IN | Pause menu fades out on Resume; the board is already showing under it |
| `BURST_IN` | 320 | BACK, OUT | Starburst scales from 0.6 to 1 and turns from -15 to 0 degrees |
| `SOLVED_IN` | 220 | BACK, OUT | SOLVED! sticker slams in, scaling from 1.6 to 1 |
| `SOLVED_WOBBLE` | 360 | SINE, OUT | Then it rocks 3 degrees either side of its tilt, twice, settling |
| `RECEIPT_STAGGER` | 50 | QUART, OUT | Receipt rows slide up 8 dp and fade in, 50 ms apart, 200 ms each |
| `SCORE_COUNT` | 600 | QUART, OUT | The final score counts up from 0 |
| `NEW_BEST_IN` | 200 | BACK, OUT | NEW BEST labels pop from 0.4 to 1 when the count ends |
| `LESSON_SHAKE` | 240 | SINE, IN_OUT | Lesson card shakes 4 dp left and right, three times, after a wrong tap |
| `PRAISE_IN` | 200 | QUART, OUT | Praise card and Next button slide up 16 dp and fade in over the controls |
| `LESSON_PULSE` | 1200 | SINE, IN_OUT | Ring around a lesson marked control fades from full to 35 percent and back, looping until the step is done |
| `MAKING_DELAY` | 300 | | Wait before the making a puzzle card shows; a puzzle made sooner shows no card at all (7.14) |
| `MAKING_MIN` | 400 | | Once the card shows, it stays at least this long, so it never blinks (7.14) |
| `MAKING_LOOP` | 900 | SINE, IN_OUT | The hero on the making a puzzle card rocks from 4 degrees counterclockwise to 4 clockwise and back, looping while the card shows (7.14) |

The completion screen's buttons work from its first frame, whatever is still moving.

## 7. Screens and overlays

Sketches are at 360 by 800 dp, the judged screen, with a 32 dp notch inset and a 24 dp gesture bar. Numbers are dp. The page is `page_bg` everywhere.

### 7.1 Main menu

```
┌──────────────────────────────────────┐ safe top + 8
│                                      │
│         ╔══════════════╗             │ SUDOKU: CELEBRATE_STICKER +
│         ║   SUDOKU     ║             │ CELEBRATE_DISPLAY, tilted
│         ╚══════════════╝             │ sticker_tilt, centered
│                                      │
│            ┌────────┐                │ hero: the app icon foreground
│            │  icon  │                │ (app_icon.gd draw_foreground),
│            └────────┘                │ 64 to 200 square
│                                      │
│ [ CONTINUE                         ] │ BUTTON_PRIMARY, 56: PRIMARY_LABEL
│ [ MEDIUM, 12:48                    ] │ over PRIMARY_CAPTION
│ [ NEW PUZZLE                       ] │ BUTTON_SECONDARY, 56
│ [ LESSONS                          ] │ 56
│ [ STATS          ] [ SETTINGS      ] │ two halves, 56
└──────────────────────────────────────┘ safe bottom - 8
```

- **Wordmark.** One word, SUDOKU, on one sticker: a `CELEBRATE_STICKER` panel (pink `celebrate_bg`, outline, hard shadow, `radius_control`) holding a `CELEBRATE_DISPLAY` label (display role, capitals, `celebrate_text`), tilted counterclockwise by `sticker_tilt` and centered in the column. The source string is "Sudoku"; the display role sets it in capitals. Its face is about 184 by 52 dp (the word about 168 dp wide at 44 dp, plus the sticker padding); with the tilt and the shadow it takes about 66 dp of height. It reuses the SOLVED! look, so its contrast is already checked (`celebrate_text` on `celebrate_bg`, both skins). It is not tappable.
- **Hero.** The app icon's foreground, Ring (section 9), drawn in code by `app_icon.gd` `draw_foreground`: the white cell sticker with its ink outline and hard shadow, the nine Heavy candidates and the two magenta X, straight on the lemon page. It reads at both ends of its range: at 64 dp the candidates are about 11 dp Heavy, larger than on the board; at 200 dp they are about 34 dp. Checked on `build/icon_options/ring-final-sheet.png` (last row). The hero is a square box, centered. The foreground's art sits inside the 66 dp safe zone of a 108 dp layer, so the painter passes `draw_foreground` a rect 108/66 times the box side, centered on the box; the art then fills the box. No background layer and no tile: the art sits straight on `page_bg`. It is not tappable.
- Buttons are full width with 12 dp gaps and sit at the bottom: 4 rows of 56, 3 gaps of 12 and the 4 dp shadow, 264 dp in all. The wordmark sits at the top. The hero takes the height between them less a `space_xl` (24 dp) gap above and below it, clamped to 64 to 200 dp, and is centered in that space when it stops at 200.
- **Continue** has two lines in two styles, set with variations only. The `BUTTON_PRIMARY` button has no text of its own. It holds a centered `VBoxContainer` (separation 0, mouse filter ignore) with two centered labels: CONTINUE in `PRIMARY_LABEL` (button role) and the level and time, "MEDIUM, 12:48", in `PRIMARY_CAPTION` (caption role); both in `button_primary_text`, a pair the checker already holds at 4.5:1. The box fills the button's content rect (the normal style's content margins), and it follows the face when the button sinks: on every draw of the button, move the box by the current style's `PopBox.face_rect(Rect2()).position` (the style for `get_draw_mode()`, which includes the press copy `Motion.press` puts on). Height: margins (2 + 8) x 2 = 20, plus 20 and 14 for the two lines, 54 of the 56 dp face. Before, both lines in the button role needed 57.
- With no puzzle in progress there is no CONTINUE, and NEW PUZZLE becomes primary.
- At 360 by 800 (32 dp notch, 24 dp gesture bar): 744 safe, 728 inside the margins; 728 minus 66, 264 and 48 leaves 350, so the hero is 200 dp.
- At 320 by 568 with the same insets: 512 safe, 496 inside the margins; 496 minus 66, 264 and 48 leaves 118, so the hero is about 118 dp, or 186 dp with no CONTINUE row (one row and one gap fewer). Everything fits.

### 7.2 First launch lesson offer

A full screen before the main menu (GDD 15.3). The SUDOKU wordmark and the hero as on the main menu; below them a `CARD` with the GDD text in body ("New to Sudoku? Lesson 1 shows you how to play.") and two full width buttons, 12 dp apart: START LESSON (`BUTTON_PRIMARY`) and SKIP (`BUTTON_SECONDARY`). The hero takes the height left between the wordmark and the card, less a 24 dp gap above and below, clamped to 64 to 200 dp; at 320 by 568 it may stop at 64 when the card text wraps to three lines, and it never pushes the buttons out of the safe area.

### 7.3 Level select

```
│ [<]  NEW PUZZLE                      │ title row 48
│                                      │
│ [ BEGINNER                  ■□□□□ ] │ LIST_BUTTON, 64, gaps 12
│ [ 100 POINTS                       ] │ caption under the name
│ [ EASY                      ■■□□□ ] │
│ [ MEDIUM                    ■■■□□ ] │
│ [ HARD                      ■■■■□ ] │
│ [ EXPERT                    ■■■■■ ] │
```

- Each row: the level name in heading style, its points in caption style under it ("400 POINTS"), and five 10 dp square pips on the right, filled in `chart_bar` up to the level and empty in `surface_alt_bg`, all outlined. The pips show the order without color.
- All five levels are open. Height: 48 + 8 + 5 rows of 64 + 4 gaps of 12 = 424, which fits 320 by 568.

### 7.4 New puzzle confirm dialog

Over the level select, behind a `SCRIM`. A `DIALOG` card, centered, 328 dp wide at most: the GDD 15.2 text in body ("You have a Medium puzzle in progress. Start a new Hard puzzle? The current one will count as started, not completed."), then two full width buttons, 48 dp faces, 12 dp apart: KEEP PLAYING (`BUTTON_SECONDARY`) on top, START NEW (`BUTTON_DANGER`) below. Back and a tap on the scrim mean Keep playing.

### 7.5 Play screen

```
┌────────────────────────────────────────┐ y 40 (safe top 32 + 8)
│ [ HINT ]  [ TIME   ][ SCORE ]    [ II ] │ header row 48: faces 40, shadows 4
│ [ -80  ]  [ 12:48  ][ 320   ]           │
│                                         │ band
│  (MEDIUM)                               │ level sticker, 8 above the board
├─────────────────────────────────────────┤ info zone 130 from y 40
│                                         │
│              board 337                  │ cells 37.4, candidates 11.5
│                                         │
└─────────────────────────────────────────┘ + outer line and 4 shadow
                 gap 40
 [ 1 ][ 2 ][ 3 ]    20    [ PLACE      ]   keys 63 by 64, gaps 8
 [ 4 ][ 5 ][ 6 ]          [ CROSS OUT  ]   right column 116
 [ 7 ][ 8 ][ 9 ]          [UNDO][ERASE ]   54 each
                                           bottom: safe bottom 24 + 8
```

Header row (the HUD), left to right:

- **Hint** (`HINT_BUTTON`): a 64 by 40 face with the hint icon, a HINT caption and the cost under it as "−80" (a real minus sign, U+2212, which the font has). At the top left, the corner farthest from the pad, at least 48 dp above the board (the band) and the whole header away from Pause. The band and the gaps around Hint hold nothing tappable, so a slip toward the board lands on nothing. Disabled when GDD 10.4 says (4.2).
- **Time** (`HUD_TIME`): TIME caption over the value, a 40 dp tall face (`Layout.ICON_FACE`) with the two lines centered in it, at least 80 wide, growing to fit 9:59:59.
- **Score** (`HUD_SCORE`): SCORE caption over the value, the same 40 dp face, at least 60 wide. Time and score are centered between Hint and Pause, at least 12 from each.
- The row is `HEADER_ROW` (48) tall at every screen size; nothing in it may make it taller (3.6).
- **Pause** (`ICON_BUTTON`): at the top right.

The band below holds the level name on a `STICKER`, tilted, 8 dp above the board's left end. It is not tappable.

The pad:

- Digits 1 to 9 in a 3 by 3 block, in the phone's order (1 2 3 on top). `PAD_KEY_PLACE` in Place mode, `PAD_KEY_CROSS` in Cross Out mode: white keys against ink keys with a pink corner stripe, so the pad shows the mode by fill and by the stripe.
- The right column, `group_gap` (20) from the digits: PLACE and CROSS OUT as two `MODE_BUTTON`s, each with its icon (pencil, crossed box) and label, the active one sunk and inverted; under them UNDO and ERASE as two `PAD_ACTION`s side by side, icon over caption. The columns line up with the digit rows.
- The 20 dp gap leaves 12 dp between touch areas, with nothing tappable in it, between every digit and Undo, Erase or the mode buttons.

When the puzzle completes, the board locks and the completion screen follows (6, `COMPLETE_WAVE`).

### 7.6 Hint panel

```
┌────────────────────────────────────────┐ covers the info zone,
│ [HIDDEN SINGLE] LESSON: HIDDEN SI…  (x) │ from y 40 to 8 above the board
│ In this box, 1 fits in only one         │ body_small, 3 lines at most;
│ cell. It goes here.                     │ close in its own column
└────────────────────────────────────────┘
├─────────────────────────────────────────┤ board: never covered
```

- A `HINT_PANEL` over the whole info zone, from the top of the header row to 8 dp above the board (the header row's rect joined with `band_rect_global()`), full column width: at least 88 dp tall (122 at 360 by 800). The band alone is too short for it at its minimum (48 dp). It covers the header row, never any cell, so it can never cover a target or reason cell.
- Two columns side by side (an `HBoxContainer`, separation 0). The left column fills the width: the top row, then 4 dp (`space_xs`), then the hint text. The right column is the close button alone: an `ICON_BUTTON` with a `Layout.CLOSE_FACE` (32 dp) face in its 48 by 48 touch area, at the top of the column (size flags shrink begin). Its touch area is the column's width, so the text never runs under it.
- Top row: the technique name in a `HINT_TAG`, then the lesson title in caption style when the GDD gives one ("LESSON: HIDDEN SINGLE"), cut with an ellipsis when it is too long. The row is as tall as the tag, 18 dp.
- Then the hint text in `BODY_SMALL`, three lines at most. Before it would need a fourth line, or would make the panel taller than the info zone, it steps down to `BODY_SMALL_12` and then `BODY_SMALL_11`, by changing the label's `theme_type_variation` (3.2). The rule: use the first of the three at which the text wraps to three lines or fewer at the column's width and the panel fits the info zone.
- Height at the smallest info zone, 88 dp (320 by 568 and 360 by 640): outline and padding (2 + 4) x 2 = 12, the top row 18, the gap 4, and three lines of 13 dp text 52, 86 in all. At 320 by 568 the longest texts need `BODY_SMALL_12` (three lines, 83 dp); everywhere else every hint text the game writes fits at 13 dp. `ui_fit.gd` checks every hint text template on all five screens. The 11 dp step is kept for safety; no text needs it today.
- Side by side (4.11) the info zone is at the top of the side column, so the panel is the side column's width (304 to 360) and sits beside the board, never over it.
- While it shows, the Hint button is covered (it is disabled anyway, GDD 10.2), as are the time, score and Pause. The timer keeps running; Android Back still opens the pause menu.
- The board marks the targets and reasons (2.7) for as long as the panel shows. Motion: `PANEL_IN`, `MARK_POP`, `PANEL_OUT`.

### 7.7 Full board message

The GDD 6.3 text ("The board is full, but some digits clash. Fix the marked cells.") in a `BOARD_MESSAGE` panel in the same place and size as the hint panel, so it never covers a conflict cell. No close button: it closes at the player's next action (GDD 6.3). The two never show together, because the placement that fills the board closes any hint first.

### 7.8 Pause menu

A full screen overlay in `PAGE` that covers everything, the board included (GDD 8). Centered in the safe area: PAUSED in display style; the level `STICKER` and the paused time in value style under it; then full width buttons with 56 dp faces, 12 apart: RESUME (`BUTTON_PRIMARY`), SETTINGS and MENU (`BUTTON_SECONDARY`). Back resumes.

### 7.9 Completion

```
│              ✶ starburst ✶             │ CARD colors, outline, shadow
│            ╔═══════════════╗           │
│            ║   SOLVED!     ║           │ CELEBRATE_STICKER, tilted 6 deg
│            ╚═══════════════╝           │
│                 (HARD)                 │ STICKER
│ ┌────────────────────────────────────┐ │ receipt: CARD
│ │ TIME                         22:30 │ │ caption left, value right
│ │ [NEW BEST TIME]                    │ │ only when it is a new best
│ │ POINTS AFTER HINTS             420 │ │
│ │ TIME BONUS                     175 │ │
│ │ ────────────────────────────────── │ │ RULE
│ │ SCORE                          595 │ │ title left, DISPLAY_ACCENT right
│ │ [NEW BEST SCORE]                   │ │
│ │ HINTS USED                       2 │ │
│ └────────────────────────────────────┘ │
│ [ PLAY AGAIN        ] [ MENU         ] │ PRIMARY and SECONDARY, 56
```

- The NEW BEST labels are small `CELEBRATE_STICKER`s with `CELEBRATE_LABEL` text, "NEW BEST TIME" under the TIME caption and "NEW BEST SCORE" under the SCORE title, tilted like stickers. They show only when `CompletionResult` says so (GDD 12.1), and they are words, not color.
- The starburst and SOLVED! take the height above the receipt, shrinking on short screens; the receipt and buttons keep their size.

### 7.10 Stats

```
│ [<]  STATS                             │ title row
│ ┌────────────────────────────────────┐ │ one CARD per level, gaps 12
│ │ (MEDIUM)  [██████████████░░░░░░]   │ │ STICKER, STAT_BAR completed/started
│ │ STARTED     COMPLETED   BEST SCORE │ │ captions
│ │ 17          13          578        │ │ values
│ │ BEST TIME   AVERAGE TIME           │ │
│ │ 11:05       15:22                  │ │
│ └────────────────────────────────────┘ │
│ ...Beginner to Expert...               │
│ ┌────────────────────────────────────┐ │
│ │ LESSONS COMPLETED   4 OF 5         │ │ caption, value
│ │ ■ ■ ■ ■ □                          │ │ five 24 dp squares
│ └────────────────────────────────────┘ │
```

- Every label is in full words. "BEST TIME" is never shortened to "BEST", and "BEST SCORE" sits apart from it.
- Before a level's first completion, its best time, average time and best score show "-" (GDD 13.1), and its bar is empty.
- The list scrolls when it does not fit (most phones); the title row stays.

### 7.11 Settings

```
│ [<]  SETTINGS                          │
│ ┌────────────────────────────────────┐ │ CARD rows, 64, gaps 12
│ │ SOUND                     ON [  ■] │ │ heading, caption, SWITCH
│ └────────────────────────────────────┘ │
│ ┌────────────────────────────────────┐ │
│ │ AUTO CROSS               OFF [■  ] │ │
│ │ One line about what it does        │ │ BODY_MUTED
│ └────────────────────────────────────┘ │
│ SKIN                                   │ caption
│ ┌───────────────┐ ┌───────────────┐    │ two SKIN_OPTIONs, 120 tall
│ │  mini board   │ │  mini board   │    │ each drawn in its own skin
│ │  LIGHT    (✓) │ │  DARK         │    │ check badge on the selected one
│ └───────────────┘ └───────────────┘    │
│                                        │ 24
│ [ RESET STATS                        ] │ BUTTON_SECONDARY
```

- Switches show on and off by the knob's side and the ON or OFF caption as well as by color.
- The Auto Cross description text is the lead-game-designer's to write (one short line); the row grows to fit it.
- Each skin card draws a 3 by 3 corner of a board in that skin (a given, a placed digit, a ring with a hand X, the selected cell) on that skin's page color, with its display name. Selecting one switches the skin at once (`Skins.apply`).
- RESET STATS opens a `DIALOG` with the GDD 13.2 text ("Reset all stats? This cannot be undone.") and CANCEL (`BUTTON_SECONDARY`) over RESET (`BUTTON_DANGER`), laid out like 7.4.
- Settings opens from the main menu and from the pause menu; back returns to where it came from.

### 7.12 Lessons list

```
│ [<]  LESSONS                           │
│ [ (1)  HOW SUDOKU WORKS           (✓) ] │ LIST_BUTTON, 72, gaps 12
│ [      Rows, columns and boxes        ] │ subtitle in BODY_MUTED
│ [ (2)  THE RING AND CROSS OUT         ] │
│ ...                                    │
```

Each row: the lesson number on a 36 dp `STICKER`, the title in heading style and the subtitle in body_small muted under it, and for a finished lesson the check icon on a `sticker_bg` badge at the right (an icon, not color). 48 + 8 + 5 rows of 72 + 4 gaps of 12 = 464, which fits 320 by 568.

### 7.13 Lesson screen

```
┌────────────────────────────────────────┐
│ ┌────────────────────────────────────┐ │ LESSON_CARD
│ │ (LESSON 2 OF 5)  STEP 5 OF 8   (x) │ │ top row 32: STICKER, caption, close
│ │ THE RING AND CROSS OUT             │ │ heading (hides on short screens)
│ │ A column can have each digit only  │ │ body 14
│ │ once, too. This column has a 4 and │ │
│ │ a 6. Cross out 4 and 6.            │ │
│ └────────────────────────────────────┘ │
├─────────────────────────────────────────┤ board, as on the play screen
│                                         │ marked cells: mint fill and ticks
└─────────────────────────────────────────┘
 [ 1 ][ 2 ][ 3 ]          [ PLACE      ]   the same pad as play
 [ 4 ][ 5 ][ 6 ]          [ CROSS OUT  ]
 [ 7 ][ 8 ][ 9 ]          [UNDO][ERASE ]
```

- No timer, score or Hint (GDD 15.4). Close leaves the lesson.
- Marked cells use the hint reason look (2.6, 2.7). A marked control (the mode buttons, a digit key, Undo, Erase) gets a ring around its face: `hint_mark_w` in `hint_reason_mark`, 4 dp outside the face and its shadow, corners `radius_control` plus 4, pulsing (`LESSON_PULSE`).
- A wrong tap: the card shows the wrong tap text in place of the step text, led by a pink `CELEBRATE_STICKER` tag that says NOT QUITE (the source string is "Not quite", Bart, Hard Stop 2; `CELEBRATE_LABEL` sets it in capitals), and shakes (`LESSON_SHAKE`). Nothing else changes, and the card does not change height (4.8).
- After the right tap: the controls are covered by a `CARD` with the praise line in body, a green check `STICKER`, and a full width NEXT `BUTTON_PRIMARY` (56 dp face) under it (`PRAISE_IN`). The board stays in view.
- Adaptation: section 4.8.

### 7.14 Making a puzzle

A new puzzle is made on a worker thread after the player picks a level (level select, Start new in the confirm dialog, or Play again). Expert comes from the bank and is ready at once; Beginner to Medium usually take well under half a second; Hard can take a second or two, about 4 at worst on a mid-range phone (docs/GENERATION_TIMING.md). So most waits should show nothing at all, and a long one should show that the game is working, not frozen.

```
│                                        │ the screen the player was on,
│ ┌────────────────────────────────────┐ │ under the SCRIM
│ │              (HARD)                │ │ STICKER, tilted sticker_tilt
│ │            ┌────────┐              │ │
│ │            │  icon  │              │ │ hero, 64, rocking (MAKING_LOOP)
│ │            └────────┘              │ │
│ │        Making your puzzle.         │ │ BODY, centered
│ └────────────────────────────────────┘ │ DIALOG, centered
```

1. **At once** (the frame of the tap): a clear layer over the whole screen takes every tap, so nothing else can start. Nothing is drawn on it. The button that was tapped plays its normal press.
2. **If the puzzle is ready within `MAKING_DELAY` (300 ms)**: the play screen comes in (`SCREEN_IN`) and nothing else ever showed. This is every Expert puzzle and most others.
3. **Otherwise, at 300 ms**: the `SCRIM` fades in and a `DIALOG` card appears (`Motion.appear`, `DIALOG_IN`), centered in the safe area, as wide as a dialog (at most `UiSizes.DIALOG_MAX_W`, at least 16 dp from the safe area's sides). In it, centered, `space_m` apart: the level name on a `STICKER` (tilted `sticker_tilt`), so the player sees which level is coming; the hero, the app icon's foreground (as on the main menu, 7.1) in a 64 dp box, rocking 4 degrees either side (`MAKING_LOOP`, around its center); and "Making your puzzle." in `BODY`. Nothing on it is tappable: there is no Cancel, because the longest wait is a few seconds.
4. **When the puzzle is ready**: if the card has shown for less than `MAKING_MIN` (400 ms), wait until it has; then the play screen comes in (`SCREEN_IN`) while the card and scrim go (`Motion.disappear`). The timer starts when the board first appears (GDD 8), so none of this counts.

Every color here is a pair the checker already holds (`sticker_text` on `sticker_bg`, `text` on `surface_bg`). The hero rocks by rotating its Control; it redraws nothing, so it costs nothing at 60 fps.

## 8. Two color decisions

**The lemon page.** Phase 1's `#FFE45C` is a saturated lemon (64 percent saturation) that fills every screen edge to edge; over a 45 minute puzzle it is tiring and tints everything around it. `page_bg` is now `#FFEB8F`: the same hue, 44 percent saturation, a little lighter (relative luminance 0.83 against 0.78). Pop's character stays: the page is still lemon, and the black outlines, hard shadows, stickers and condensed capitals are unchanged. The full lemon moves to where it says "here": the selected cell. Ink text on the page is 15.8:1 and muted text 9.4:1. In dark, lemon stays the line and shadow color, as before.

**The magenta X on the selected cell.** In Phase 1 the selected cell was pink `#FFB3DE`, so the magenta hand X `#D1005A` on it had 3.31:1, just over the 3:1 floor, and the same hue, which made it the softest X on the board in the cell the player works in. The selected cell is now lemon `#FFE873`: the X has 4.42:1 and a hue far from its background, and the crossed digit on it 4.80:1. In dark, the selected cell is a lifted gray `#424242` (Phase 1: deep pink `#5E1F48`), for the same reason: the pink X `#FF6FB5` on it has 3.92:1 and a different hue. The checker covers both.

## 9. App icon and boot background

The app icon is **Ring** (Bart, 2026-10-12): one empty cell as a Pop sticker, with the nine candidates around its inside edge in ring layout A and two of them crossed out with the magenta hand X. Bart's one change was "make the small one bolder", and this spec is the bolder version. The reference drawing is `tools/design/icon_options/option_ring.gd` (it uses `icon_common.gd`); `src/design/app_icon.gd` (ui-motion-artist) ports it exactly, with the same four draw functions and `foreground_outline` (ARCHITECTURE section 7), so the main menu hero (7.1) follows with no other change. Ring as Bart saw it is kept in `option_ring_original.gd` for comparison only. Renders (never committed): `timeout 120 godot --path . --script res://tools/design/icon_options/render_icons.gd` writes `build/icon_options/ring-final-*.png` and `ring-final-sheet.png`.

### 9.1 What made it bolder, and why there is one look

A launcher icon is about 48 dp on every phone, roughly 7 to 8 mm, whatever its pixel count. The 48 px renders on a laptop are about that physical size, so their "cell with specks" is what people would see on a home screen. A pixel size threshold would not help: an xxxhdpi launcher draws 192 px at the same 48 dp. So the icon has **one look at every size**, and that look is bolder for everyone:

| | Ring as picked | Ring final | Why |
| --- | --- | --- | --- |
| Sticker half side | 0.64 R | 0.685 R | More white cell, still inside the safe zone |
| Sticker corner | 0.14 R | 0.20 R | Rounder corners let the square grow inside the circle |
| Outline | 0.06 R | 0.07 R | The cell edge holds at 48 dp |
| Ring inset (from the outline's inner edge) | 9 percent of the face side, about 0.12 R | 0.09 R | Digits closer to the edge, as on the board |
| Candidate weight | Semibold (embolden 0) | Heavy (embolden 0.9) | Strokes survive the downscale |
| Gap between candidates | 0.40 of the font size | 0.32 | Bigger digits; the four across the top still read as four |
| Font size at a 48 dp launcher icon | about 6 dp | about 7.5 dp, Heavy | Digits read as digits, not dots |
| X half span, stroke | 0.42 and 0.13 of the font size | 0.45 and 0.22 | The magenta X is the second thing you see after the cell |
| Crossed digits | 3 and 7 | 3 and 8 | Away from the corners, so the longer X never touches the outline |

R is the safe zone radius. The background is unchanged.

### 9.2 Geometry

All values are shares of the adaptive layer side L (the 108 dp layer; `rect` of `draw_background`, `draw_foreground` and `draw_monochrome`), with the safe zone radius R = 33/108 L = 0.3056 L given too. Pixel values are not rounded unless stated.

| Part | Value |
| --- | --- |
| Safe zone radius R | 0.3056 L, centered |
| Visible area | the middle 72/108 = 0.6667 L |
| Face center | layer center minus (0.04 R, 0.04 R) = minus (0.0122 L, 0.0122 L), so face and shadow together are centered |
| Sticker half side, on the outline's center line | 0.685 R = 0.2093 L (outer edge of the outline 0.72 R = 0.2200 L) |
| Sticker corner radius, on the outline's center line | 0.20 R = 0.0611 L (outer edge 0.235 R; face inner corner 0.165 R) |
| Outline | 0.07 R = 0.0214 L, at least 1 px, centered on the half side line |
| Hard shadow | the outline's outer shape in ink, offset (0.08 R, 0.08 R) = (0.0244 L, 0.0244 L) down and right, drawn first |
| Ring box | a centered square inside the face, side 2 times (0.685 minus 0.035 minus 0.09) R = 1.12 R = 0.3422 L; its edge is 0.09 R inside the outline's inner edge |
| Candidate font size | `roundi(min(box / 3.28, box / 2.98))` = `roundi(box / 3.28)` = about 0.3415 R = 0.1043 L; 3.28 is 4 digits of 0.58 plus 3 gaps of 0.32, 2.98 is 3 rows of 0.78 plus 2 gaps of 0.32 |
| Digit ink, Heavy, shares of the font size s | width 0.58 (the widest, the 4, is 0.60), height 0.78 above the baseline |
| Rows | 1 2 3 4 / 5 (open) 6 / 7 8 9. Row r of 3 has its ink center at y = box top + 0.39 s + r (box minus 0.78 s) / 2 |
| Columns | in a row of n digits, digit i has its ink center at x = box left + 0.29 s + i (box minus 0.58 s) / (n minus 1). The middle row counts as n = 3 with its middle slot empty: the 5 at the left edge, the 6 at the right edge |
| Drawing a digit | baseline x = center x minus half the string advance at s; baseline y = center y + 0.39 s |
| Crossed candidates | 3 and 8 |
| Hand X | two lines through the digit center, half span 0.45 s on each axis, stroke 0.22 s (at least 1 px), antialiased, plain ends |
| Crossed digit outline | `roundi(0.08 s)`, at least 1 px, in white |
| Monochrome frame | the outline alone, no fill, no shadow, stroke 1.4 times the outline (0.098 R = 0.0299 L, rounded to whole px, at least 1), its center line on the 0.685 R half side, corner radius 0.20 R + half the stroke on the outer edge; same face center |
| Farthest point drawn | foreground 0.980 R (the shadow's far corner), monochrome 0.991 R (the frame's top left corner); both inside R. Checked on pixels by `render_icons.gd` |

The full legacy icon: a rounded square over the whole rect, corner radius 0.22 of its side, Pop blue; the grid lines on its thirds; then the same art drawn into the layer whose visible area is the rect (layer side = rect side times 108/72, centered).

### 9.3 Colors and weights

| Part | Color | Pop token |
| --- | --- | --- |
| Background layer | `#1A40D9` | `button_primary_bg` |
| Background grid lines, on the thirds of the visible area, 1.5 percent of the visible side wide (1 percent of L), at least 1 px | `#4362E0` | quiet blue, icon only |
| Sticker face | `#FFFFFF` | `cell_bg` |
| Outline and hard shadow | `#111111` | `outline`, `shadow` |
| Open candidates | `#111111`, Godot's built-in font, `FontVariation` embolden 0.9 (Heavy, section 3.1) | `digit_given` |
| Hand X | `#D1005A` | `cross_mark_hand` |
| Crossed digit | `#111111` drawn over its X, with a `#FFFFFF` outline (as on the board, 2.4) | |
| Monochrome layer | one opaque color, `#FFFFFF`: the frame, the seven open digits and the two X. A crossed digit is not drawn in monochrome, only its X, so the two do not merge into one blob | |

Draw order, foreground: shadow, outline, face, then per candidate in reading order the X and its outlined digit, or the plain digit.

### 9.4 Porting notes for app_icon.gd

- `foreground_outline` and the safe zone test: digits are text and have no vertices. The farthest digit ink (the corner of the 1) is about 0.85 R from the center and the X ends stay within about 0.7 R, so the points that matter are the shadow corner and the frame corner. Include the X end points and the sticker shapes in `foreground_outline`.
- The font size is an int (`draw_string`), rounded from the float; positions use the float box, so the layout stays centered at every size.
- No size threshold and no second look. Do not swap to a simpler drawing below some pixel size.

### 9.5 Boot background

- Boot background (ARCHITECTURE section 13): `#FFEB8F`, Pop light's `page_bg`, so the first frame matches the main menu. platform-dev sets it.

## 10. Checks and studies

To change a skin value, edit the tables in section 1, then write the files and run the checks:

```
timeout 300 godot --headless --path . --script res://tools/design/write_skins.gd
timeout 300 godot --headless --path . --script res://tools/design/check_contrast.gd
timeout 300 godot --headless --path . --script res://tools/design/check_samples.gd
timeout 300 godot --headless --path . --script res://tools/design/pad_fit.gd
timeout 300 godot --headless --path . --script res://tools/design/ui_fit.gd
timeout 300 godot --path . --script res://tools/design/mark_study.gd
timeout 300 godot --path . --script res://tools/design/window_fit.gd
```

- `write_skins.gd`: writes `src/skins/pop_light.tres` and `pop_dark.tres` from the two tables in section 1 (every property, in table order, in Godot's own text format), keeping each file's uid. It refuses to write if the tables and GameSkin disagree.
- `check_contrast.gd`, part 1, on the two skin files loaded as GameSkin: every file sets every property, and every final skin pair (digits and text 4.5:1; open candidates 4.5:1 on every fill a ring can have; the hand X, the Auto Cross slash and crossed digits 3:1; frame, marks, lines, outlines and chart marks 3:1; disabled text 3:1; the slash 1.5:1 on its own digit), the marks that must differ in color, the sizes on the judged screen at densities 2, 2.625 and 3 (the candidate floor, stroke and line weights, the box to cell line ratio, the ring clear of the frame and marks), and that both tables in section 1 match the files. Part 2 keeps the Phase 1 record for all three directions. Exits 1 on any failure.
- `check_samples.gd`: the Phase 1 sample content, and the layout rules of section 4 on the five screens of 4.10, with the touch targets and the candidate floor; since Phase 6 also the windows of 4.11, each of which must pick its pinned arrangement (stacked, side by side or too small) and, when supported, fit with 48 dp touch targets, a board of at least `BOARD_MIN`, the main menu and the pause menu.
- `pad_fit.gd`: builds the number pad's buttons with the real Theme on the five screens of 4.10 and checks that every label fits its face, raised and sunk (3.5). By default it lays the spec of 3.5 over the Theme in memory; `-- current` checks the Theme as it is. With a window, `-- render` writes docs/design/pad-fit.png (`-- render current` writes pad-fit-current.png).
- `ui_fit.gd`: builds the play screen's header row (the real PlayHud), the main menu's Continue button and the hint panel with the real Theme on the five screens of 4.10, with the widest time (9:59:59), score (1000), Hint cost and every hint text the game writes, and checks that they fit their design (3.6, 7.1, 7.5, 7.6). By default it lays the spec of 3.6 over the Theme in memory; `-- current` checks the Theme and screen code as they are. With a window, `-- render` writes docs/design/ui-fit.png (`-- render current` writes ui-fit-current.png).
- `mark_study.gd`: writes the two studies quoted above to docs/design/. It needs a window.
- `window_fit.gd`: draws the play screen's wireframe on the windows of 4.11 into docs/design/window-shapes.png. It needs a window.
- `pad_fit.gd` and `ui_fit.gd` also measure the pad, the header row, Continue (at the main menu's half width when side by side) and every hint text on each window of 4.11 the game supports.
