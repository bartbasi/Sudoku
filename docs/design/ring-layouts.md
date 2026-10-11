# Candidate ring layouts

Owner: senior-graphic-designer. Final for Hard Stop 1, 2026-10-11. Bart picks one layout.

Every empty cell shows its nine candidates around the inside edge, with the center open (BRIEF section 3, GDD 4.1). Nine slots around a square cannot be perfectly symmetric, so here are three layouts to choose from. All three directions draw the same three layouts from the same data: `tools/design/directions/ring_layouts.gd`.

## Close-ups

Each close-up shows the selected cell's box of the play board in all three directions, light and dark, drawn by the real board code with no scaling. The box holds open, hand-crossed and Auto Cross candidates side by side, the selected cell in Cross Out mode, givens and placed digits.

| Layout | True size, 1080 px wide phone | True size, 720 px wide phone (smallest) | 720 px, enlarged 3 times |
| --- | --- | --- | --- |
| A. Reading rows | [ring-rows.png](ring-rows.png) | [ring-rows-small.png](ring-rows-small.png) | [ring-rows-small-x3.png](ring-rows-small-x3.png) |
| B. Clockwise | [ring-clockwise.png](ring-clockwise.png) | [ring-clockwise-small.png](ring-clockwise-small.png) | [ring-clockwise-small-x3.png](ring-clockwise-small-x3.png) |
| C. Clockwise wide | [ring-clockwise-wide.png](ring-clockwise-wide.png) | [ring-clockwise-wide-small.png](ring-clockwise-wide-small.png) | [ring-clockwise-wide-small-x3.png](ring-clockwise-wide-small-x3.png) |

To judge at real size, view the first two columns at 100 percent on a phone or with the image the width of a phone screen. The enlarged column is for looking at single pixels.

## Rules shared by every layout

- Each digit sits in the same slot in every cell.
- The ring is laid out in a square "ring box" inset from the cell edge. Each row of slots runs edge to edge: the first and last digit touch the sides of the ring box and the rest are spaced evenly. Rows are spaced evenly from top to bottom.
- Candidate size is the largest that fits with a gap of 0.14 of the font size between neighbors. It is measured from the real digit shapes of the font in use, so Inter gets its own fit.
- Every digit is centered on its own visible shape, not on its line box.
- Crossed by hand: an X through the digit. Crossed by Auto Cross: a single rising slash. Both span 80 to 84 percent of the slot, so marks on neighbors never touch. Restored by hand looks exactly like open.
- The digit under a hand X is drawn on top of the X, with a 1 px knockout in the cell's color around its strokes. Drawn the other way round, the two crossing strokes of the X hid the digit at 720 px, worst with four crossed in a row. Now the digit reads clearly and the X still shows at its four tips and between the strokes. The single Auto Cross slash stays on top of its digit, which reads fine under one stroke, and keeps the two marks clearly different.
- Between the cell edge and the ring box is a thin band that holds the selection frame and the hint marks, so they never cover a candidate.

## The layouts

### A. Reading rows (recommended)

```
1  2  3  4
5        6
7   8    9
```

| Digit | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Slot | top, 1st of 4 | top, 2nd of 4 | top, 3rd of 4 | top, 4th of 4 | middle, left | middle, right | bottom, left | bottom, center | bottom, right |

Why it is easy to learn: you read it like a page, top to bottom and left to right, the way the number pad counts. The four corners hold 1, 4, 7 and 9, which anchor the eye. 5 and 6 are the only digits on the sides. The bottom row, 7 8 9, sits where it sits on a phone keypad.

Trade-off: four digits share the top row, so it looks a little denser than the bottom.

### B. Clockwise (the brief's example)

```
1   2   3
9       4
8       5
7       6
```

| Digit | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Slot | top, left | top, center | top, right | right, 2nd row | right, 3rd row | bottom, right | bottom, left | left, 3rd row | left, 2nd row |

Why it is easy to learn: start at the top left and go round, like a clock hand. 1 2 3 across the top, 4 and 5 down the right, 6 and 7 back along the bottom, 8 and 9 up the left, ending next to 1. The only gap is at the bottom center. It is the most ring-like and the most balanced of the three.

Trade-off: it needs four rows, so its digits are the smallest: about 22 percent smaller than A and C.

### C. Clockwise wide

```
1  2  3  4
9        5
8   7    6
```

| Digit | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Slot | top, 1st of 4 | top, 2nd of 4 | top, 3rd of 4 | top, 4th of 4 | middle, right | bottom, right | bottom, center | bottom, left | middle, left |

Why it is easy to learn: the same clock hand rule as B, with four digits on top. 9 sits on the left where it sits on a clock face. It keeps the large digits of A.

Trade-off: the bottom row reads 8 7 6 from left to right, against reading order.

## Screen sizes we design for

**Smallest phone we support: 360 dp wide, portrait.** Most Android phones are 360 to 412 dp wide, and 360 dp is the narrowest width common today. It is where we judge readability and set our minimum sizes. Its low end version is 720 px wide (density 2.0), which is the fewest pixels a candidate gets.

**Typical phone: 1080 by 2400 px** at density 2.625, which is 411 dp wide. Our design units are its pixels.

**The GDD's tiny test screen (AT-66) is 320 by 568 dp.** Decided by the Development Manager on 2026-10-11: the game must fit and work at 320 by 568 dp (no scrolling, nothing cut off, as AT-66 says), and readability is judged at 360 dp. Bart gets this trade-off at Hard Stop 1 together with the ring layout choice, so the tables below give every size at both widths. What it means:

- At 320 dp, layout B's candidates drop to 8.0 to 8.6 dp, below our 9 dp floor for a single digit at arm's length. Layouts A and C stay at 10.4 to 11.0 dp.
- 320 by 568 is a short 16:9 screen. The board may then be limited by height, not width, and shrink further. If the HUD and pad need about 800 design units, the cells come out near 32 dp and A's candidates near 10 dp. The real play layout decides this in Phase 2.
- 320 dp phones are rare older or very small models. Holding the whole design to them would cost every other player candidate size.

## Sizes

All three directions keep the board width-bound on 18:9 and taller screens. Sizes come from `timeout 300 godot --headless --path . --script res://tools/design/check_samples.gd`, Godot's default font.

### Cells

| Direction | Board (units) | Cell pitch (units) | At 360 dp | At 411 dp (1080 by 2400) | At 320 dp | Ring box (units) |
| --- | --- | --- | --- | --- | --- | --- |
| Gridline | 1032 | 114.7 | 38.2 dp | 43.7 dp (114.7 px) | 34.0 dp | 100.7 |
| Pebble | 1048 | 116.4 (tile 107.1) | 38.8 dp (tile 35.7) | 44.4 dp (tile 107 px) | 34.5 dp | 95.1 |
| Pop | 1012 | 112.4 | 37.5 dp | 42.8 dp (112.4 px) | 33.3 dp | 98.4 |

Pebble's cells are rounded tiles with gaps, so its tile is smaller than its pitch, and its ring box is the smallest.

### Candidates

Font size, then the height of the tallest digit (its ink). One design unit is one pixel on the typical phone.

| Layout | Direction | Typical phone (411 dp) | Smallest phone (360 dp) | 720 px wide phone | GDD tiny (320 dp) |
| --- | --- | --- | --- | --- | --- |
| A Reading rows | Gridline | 37 px font, 14.1 dp; digits 29 px tall | 12.3 dp font; digits 9.7 dp (1.5 mm) | 24.7 px font | 11.0 dp |
| | Pebble | 35 px, 13.3 dp; 27 px tall | 11.7 dp; 9.0 dp (1.4 mm) | 23.3 px | 10.4 dp |
| | Pop | 36 px, 13.7 dp; 28 px tall | 12.0 dp; 9.3 dp (1.5 mm) | 24.0 px | 10.7 dp |
| B Clockwise | Gridline | 29 px, 11.0 dp; 23 px tall | 9.7 dp; 7.7 dp (1.2 mm) | 19.3 px | 8.6 dp |
| | Pebble | 27 px, 10.3 dp; 21 px tall | 9.0 dp; 7.0 dp (1.1 mm) | 18.0 px | 8.0 dp |
| | Pop | 28 px, 10.7 dp; 23 px tall | 9.3 dp; 7.7 dp (1.2 mm) | 18.7 px | 8.3 dp |
| C Clockwise wide | all three | same as A | same as A | same as A | same as A |

With Inter ([font-comparison.md](font-comparison.md)), every size is the same or one unit smaller, because Inter's digits are a little wider.

How each holds up at the smallest board:

- **A and C** hold up well. At 360 dp the digits are about 9 to 10 dp tall, and on a 720 px phone they get 23 to 25 px fonts, enough for crisp shapes. Four crossed digits in a row stay apart because the marks are narrower than the slots.
- **B** is readable at 360 dp but is the weakest: 9.0 to 9.7 dp fonts, digits 7 to 7.7 dp tall. It has the most open space between candidates, which helps scanning, but the digits themselves are small. It passes our 9 dp floor at 360 dp with no margin in Pebble, and fails it at 320 dp.
- In every layout the X stroke is at least 2 px on a 720 px phone and the cell lines at least 1.3 px. The contrast checker enforces these minimums.
- Review of the 720 px close-ups: open candidates read in every layout and direction, light and dark. Crossed digits did not, under the X; that is what the knockout above fixes. Pebble's yellow selected tile and Gridline dark were the hardest cases.

## Recommendation

A, Reading rows. It gives the largest candidates of the three, the most familiar order, and the strongest anchors (the corners). B is the purest ring and looks calm, but its digits are 22 percent smaller, and digit size is what decides readability on a phone. If Bart prefers the clockwise idea, C keeps A's size.

All four screens of every direction use A, so the directions compare on equal terms. The ring close-ups show all three.
