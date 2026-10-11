# Brief: ui-motion-artist, Phase 1 screens and app icon

From: senior-graphic-designer. Date: 2026-10-11. Launched by the Development Manager.

## Task

1. Build the four screens of each of the three Phase 1 design directions (Gridline, Pebble, Pop) as real Godot scenes drawn in code: play, lesson, stats and complete. Play must also work in dark. Each screen has its direction's theme, HUD, number pad, buttons and icons, and the play and lesson screens embed the board that grid-cell-artist builds. That is 12 light screens plus 3 dark play screens.
2. The app icon is being redesigned (see docs/DESIGN_SYSTEM.md section 9).

The screens are prototypes: they live in tools/ and never ship. The chosen direction is rebuilt in src/design/ in a later phase. The app icon is real game code from the start.

No animation in Phase 1. Every screenshot is static. The motion ideas in the write-ups are for later.

## Read first

- CLAUDE.md
- docs/BRIEF.md, sections 3 and 8
- docs/GDD.md, sections 2.3 (the selected cell shows the mode), 3.1 (controls), 8 (timer and pause), 9 (score), 10.2 to 10.4 (hints and the Hint button), 12 (completion screen), 13 (stats)
- docs/LESSONS.md, section 7, screen 5 (the lesson step shown on the lesson screen)
- docs/design/direction-gridline.md, direction-pebble.md, direction-pop.md: concept, palette, type and the layout of every screen. Follow them.
- docs/design/ring-layouts.md, for context
- The shared data files listed below. Their comments are part of this brief.

## Files you may touch

- Everything under `tools/design/directions/ui/`. Create the folder.
- `src/design/app_icon.gd`
- `tests/design/test_app_icon.gd`

Phase 1 ownership, decided by the Development Manager:

- `tools/design/directions/ui/` belongs to you: theme, HUD, number pad, icons, and the four full screens per direction, which embed the board from `board/`.
- `src/design/app_icon.gd` and its test in `tests/design/` belong to you.
- `tools/design/directions/board/` belongs to grid-cell-artist: the board for all three directions in light and dark, and the ring close-up and state sheet scenes.
- Everything else in `tools/design/` belongs to the senior-graphic-designer: the shared data, the contrast checker, the sample checker and the capture tool.

You must not edit any other file, including the shared data and the board scenes. If you need a token or sample content that is not there, use the closest existing one, keep going, and list what you need in your report. Never hardcode a color, size or font in its place.

## Shared data (read only)

All in `tools/design/directions/`. Load them with `preload`; none has a class_name.

| File | What it gives you |
| --- | --- |
| `palettes.gd` | `Palettes.palette(direction, dark)`: every color, including HUD, buttons, pad keys in both modes and the mode toggle. `Palettes.shape(direction)`: radii, outline weight, shadows, margins, spacing, board size. `Palettes.type_style(direction, role)`: font, size, capitals and tracking per role. |
| `sample_state.gd` | All content: `hud()`, `play_board()`, `lesson_step()`, `stats()`, `completion()`, and `format_time()` and `format_number()` (both return "-" for -1). |
| `fonts.gd` | Every font. Use `TypeStyle.font()`, `TypeStyle.font_size()` and `TypeStyle.apply(text)` (capitals) for each Label and Button through theme overrides. Never rely on the default theme font, so the Inter comparison capture works. |
| `device.gd` | `SCREEN_SIZE` (1080 by 2400), `SAFE_TOP` (96) and `SAFE_BOTTOM` (56). Keep text and controls out of the safe insets; backgrounds run edge to edge. |
| `ring_layouts.gd` | `DEFAULT_LAYOUT`, which you pass on to the board. |

Colors may only be drawn on the backgrounds the contrast checker pairs them with (see `RULES` in `tools/design/check_contrast.gd`): for example `hud_text` and `hud_label` on `hud_bg`, `text` and `text_muted` on `app_bg`, `surface` or `surface_alt`, `pad_key_cross_text` on `pad_key_cross_bg`. If a layout needs another pair, ask in your report.

## 1. The screens

### Contract with the capture tool

- Paths: `res://tools/design/directions/ui/<direction>/<screen>.tscn`, direction one of `gridline`, `pebble`, `pop`, screen one of `play`, `lesson`, `stats`, `complete`. Twelve scenes.
- Root node: `Control` with a statically typed script.
- Properties: `dark: bool = false` and `ring_layout: int = RingLayouts.DEFAULT_LAYOUT`. The capture tool sets both, places the root at (0, 0) and sets its `size` to 1080 by 2400 before adding it to the tree, so `size` is right in `_ready()`. Build the screen in `_ready()`.
- Lay out from the root's `size` and `Device.SAFE_TOP` and `SAFE_BOTTOM`, never from the window or the viewport.
- Every screen except play is captured in light only; play is also captured with `dark = true`.

### Embedding the board (contract with grid-cell-artist)

- Board scenes: `res://tools/design/directions/board/<direction>/board.tscn`.
- Root `Control`. Set `dark: bool`, `ring_layout: int` and `state: SampleState.BoardState` (null means the play board). They can be set before or after the board enters the tree.
- The board fills the largest centered square of its rect. Give it a square of `Palettes.shape(direction).board_size` and leave room around it for the overhang: half the outer line on lines-style boards, Pop's hard shadow (`shadow_offset`), Pebble's soft shadow (`shadow_blur`). The screen margins in the write-ups already allow for it.
- `cell_rect(index)` gives a cell's rect in the board's local coordinates, if you need to point at a cell.
- Play passes `SampleState.play_board()`. Lesson passes `SampleState.lesson_step().board`.
- grid-cell-artist works in parallel. Until a board scene exists, show a plain square of the board's size in `board_bg` (check with `ResourceLoader.exists()`), so you can build and capture your screens. The final screenshots are taken in step 2, when both of you are done.

### Content (from `sample_state.gd`, identical in all three directions)

- Play: level "Medium", time "12:48", score 320, Hint button enabled with its cost (80) on it, Pause; the board; the mode toggle showing Cross Out as active; the number pad 1 to 9 in its Cross Out look; Erase and Undo (both enabled).
- Lesson: "Lesson 2 of 5", title "The ring and Cross Out", "Step 5 of 8", the step text from `lesson_step().text`, the board (it marks the two cells the text talks about), and the mode toggle and pad in Cross Out mode. A way out (close or back). No timer, score or Hint button in lessons (GDD 15).
- Stats: a title, one row or card per level with started, completed, best time, average time and best score (Expert shows "-" for the last three), and "Lessons completed: 4 of 5". A back button.
- Complete: level "Hard", time "22:30", points after hints 420, time bonus 175, score 595, hints used 2, and the buttons "Play again" and "Menu" (GDD 12). Do not add a "New best" label; Bart has not approved it.

### Layout and look

Follow the "Play screen layout" and "Other screens" sections of each direction's write-up. They are deliberately different: a header band with a single row of nine keys (Gridline), chips with a 3 by 3 round keypad (Pebble), and a scoreboard strip between the board and a 2 by 6 key grid (Pop). Shared rules:

- Controls the thumb uses (pad, toggle, Undo, Erase) are anchored to the bottom safe edge. Leftover height goes between the board and the controls, but never leave an empty band taller than about 240 units: grow the keys first (up to about 200 units tall), then the header.
- Everything the player taps (keys, buttons, the toggle, tappable chips) has a touch area of at least 144 by 144 units, which is 48 dp on the smallest phone. The visible shape may be smaller if the layout leaves that room around it. One deliberate exception: Gridline's single row of nine keys is about 109 units wide per key (36 dp on the smallest phone), so make those keys at least 190 units tall and keep the gaps between them small. The write-up flags this trade-off for the team ranking.
- The number pad's Place and Cross Out looks must differ by shape or label, not color alone. Each write-up says how (inverted keys with a slash mark, yellow keys with an X badge, ink keys with a corner stripe). The toggle always names the active mode in words.
- Icons are drawn in code (`_draw()`, polygons, lines, arcs), crisp at any size, and readable without color: pause, hint, undo, erase, Place mode, Cross Out mode, back or close, and Pebble's clock and star. No image files, no icon fonts.
- Use `StyleBoxFlat` for panels, chips, keys and buttons: radii from `button_radius`, `key_radius`, `chip_radius`, `card_radius` (999 means fully round), outlines `outline_w` in `outline`, shadows from `shadow`, `shadow_offset`, `shadow_blur`.
- Text never overflows or gets cut off. Use `TypeStyle.apply()` for capitals.

## 2. The app icon

The app icon is being redesigned (see docs/DESIGN_SYSTEM.md section 9).

## How you prove it is done

Run each of these and put the output in your report:

1. `timeout 600 godot --headless --path . --script res://tests/run_tests.gd -- design` passes.
2. `timeout 300 godot --headless --path . --script res://tools/design/check_contrast.gd` exits 0.
3. `timeout 300 godot --path . --script res://tools/design/capture.gd -- screens` exits 0 with no problems. It writes the 15 screenshots `docs/design/<direction>-<screen>.png` and `<direction>-play-dark.png`.
4. `timeout 300 godot --path . --script res://tools/design/capture.gd -- screens --direction=gridline --font=inter` exits 0, to show every text follows the font switch (it writes `-inter` copies; tell me if any text stayed in the default font).
5. Open every PNG with the Read tool and check: nothing under the safe insets, nothing cut off or overlapping, the three directions clearly different in layout, shape and type, the two pad modes told apart without color.
6. Your report lists the files you created, those results, anything you had to approximate, and any token or content you need.

## Out of scope

Animation, the real Theme in src/design/, the pause menu, settings, dialogs, the hint panel, and the board itself (grid-cell-artist). Ideas beyond this brief go in your report as suggestions.
