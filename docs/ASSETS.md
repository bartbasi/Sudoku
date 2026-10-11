# Assets log

Owner: senior-graphic-designer. Started 2026-10-11, updated 2026-10-11 after the Phase 1 artist work, again for Phase 2 (docs/DESIGN_SYSTEM.md), and on 2026-10-12 for the icon placeholder and the three icon options.

This log proves that every visual and every sound in the game is made in code. Each entry names the asset, the code file that makes it, its status, and notes. Nothing paid, nothing third party, no image, audio or font files in the game (BRIEF section 2; CLAUDE.md).

Status: **planned** (assigned, not built yet), **prototype** (Phase 1 design work in tools/, never ships), **built** (game code in src/).

## Game assets

| Asset | Made by (code file) | Status | Notes |
| --- | --- | --- | --- |
| App icon: full legacy icon and Android adaptive layers (background, foreground, monochrome) | `src/design/app_icon.gd` (ui-motion-artist), tested by `tests/design/test_app_icon.gd` | placeholder | A neutral placeholder until Bart picks one of three icon options (DESIGN_SYSTEM.md section 9): a Pop blue tile `#1A40D9` with a quiet 3 by 3 grid of lines in `#4362E0`; foreground, a white rounded square holding a 3 by 3 box outline with a lemon center cell. No food, no letters. The three options (Ring, Nine, Box) are prototypes in `tools/design/icon_options/`, rendered to `build/icon_options/` for review, never committed. Whichever Bart picks keeps the Pop blue background. Every foreground and monochrome vertex stays inside the 66 dp safe zone. platform-dev turns it into launcher PNGs at build time only; the PNGs are never committed. To-do: draw the background grid lines at 1.5 percent of the visible 72 dp area (1 percent of the 108 dp layer), so the launcher icon matches the legacy icon. |
| Font | none: Godot's built-in default font (Open Sans SemiBold, compiled into the engine) | built in | No font file in the repo. Weights come from `FontVariation` emboldening (DESIGN_SYSTEM.md section 3). Bart decided at Hard Stop 1: the built-in font, no font files (comparison in `docs/design/font-comparison.md`). |
| Board visuals (BoardPainter) and the skin class (GameSkin) | `src/skins/` scripts (grid-cell-artist) | planned, Phase 3 | Pop, per DESIGN_SYSTEM.md section 2. Drawn with `_draw()`, rects, lines and text; no images. |
| Skin data: Pop light (default) and Pop dark | `src/skins/pop_light.tres`, `src/skins/pop_dark.tres` (senior-graphic-designer), written by `tools/design/write_skins.gd` from DESIGN_SYSTEM.md section 1 | built | Text resources of script class GameSkin: an id, a display name, a dark flag and 103 plain values (66 colors, 37 numbers). A `.tres` of numbers and colors is not an image, audio or font file. Checked by `tests/skins/test_game_skin.gd` and `tools/design/check_contrast.gd`. |
| Theme (ThemeFactory), icons, motion helpers | `src/design/` (ui-motion-artist) | planned, Phase 3 | Pop, per DESIGN_SYSTEM.md sections 3 to 6. Theme built in code from the skin; the disabled hatch and the Cross Out key stripe are drawn in code; icons (ARCHITECTURE section 7) drawn in code; no icon fonts, no textures. |
| Click sound | `src/audio/` (audio-dev) | planned, Phase 3 | Synthesized at startup into an AudioStreamWAV (BRIEF section 8). |

## Phase 1 prototypes (not game assets)

All in `tools/design/`, drawn in code like the game, never shipped. The chosen direction is rebuilt in `src/skins/` and `src/design/`.

| Item | Made by (code file) | Owner |
| --- | --- | --- |
| Design tokens (colors, shapes, type), sample content, ring layouts and cell geometry, device frame, font helper | `tools/design/directions/palettes.gd`, `sample_state.gd`, `ring_layouts.gd`, `device.gd`, `fonts.gd` | senior-graphic-designer |
| Board drawing for Gridline, Pebble and Pop in light and dark: frame, tray and cards, cell backgrounds, lines, digits, candidate rings, hand X, Auto Cross slash, selection frames, hint and conflict marks | `tools/design/directions/board/board.gd`, scenes `board/gridline/board.tscn`, `board/pebble/board.tscn`, `board/pop/board.tscn`. One `_draw()` with rects, lines, polylines, circles, StyleBoxFlat and text. | grid-cell-artist |
| Ring close-up sheet and state sheet | `tools/design/directions/board/ring_closeup.gd` and `.tscn`, `board/state_sheet.gd` and `.tscn` | grid-cell-artist |
| Play, lesson, stats and complete screens of the three directions: HUD, chips, stickers, number pads, mode toggles, buttons, lesson bubble, stats tables and cards, receipts, confetti, starburst | `tools/design/directions/ui/<direction>/screens.gd` with `play.tscn`, `lesson.tscn`, `stats.tscn`, `complete.tscn`; shared parts in `ui/common/kit.gd` (text, StyleBoxFlat panels and keys, tap targets, layout checks) and `ui/common/block.gd` (a face with outline and soft or hard shadow) | ui-motion-artist |
| Icons: pause, hint (bulb), undo, erase (eraser), place (pencil), cross out (crossed box), back (arrow), close, clock, star | `tools/design/directions/ui/common/icons.gd`, drawn by `ui/common/icon_view.gd`. Lines, arcs and polygons; one color each. | ui-motion-artist |
| Contrast checker (final skins and the Phase 1 record), sample, geometry and layout checker, screenshot capture | `tools/design/check_contrast.gd`, `check_samples.gd`, `capture.gd` | senior-graphic-designer |
| Skin file writer: writes the two skin files from the DESIGN_SYSTEM.md tables (Phase 2) | `tools/design/write_skins.gd` | senior-graphic-designer |
| Reader of the final skins for the checker and the studies, and Pop's Phase 1 prototype colors derived from them | `tools/design/directions/palettes.gd`, section "Final skins" | senior-graphic-designer |
| Layout model of the play and lesson screens (Phase 2) | `tools/design/layout_model.gd` | senior-graphic-designer |
| Auto Cross mark study and selection frame study (Phase 2) | `tools/design/mark_study.gd`; lines, rects and text drawn in a SubViewport | senior-graphic-designer |
| Capture tool test fixture | `tools/design/placeholder/` (a stub screen and a stub icon) | senior-graphic-designer |
| Three app icon options for Bart to pick from (2026-10-12): Ring, Nine and Box, each with a legacy full icon, adaptive background and foreground, and a monochrome layer; plus the render script, which also checks every foreground and monochrome pixel against the safe zone | `tools/design/icon_options/icon_common.gd`, `option_ring.gd`, `option_nine.gd`, `option_box.gd`, `render_icons.gd`. Rounded StyleBoxFlat shapes, rects, lines and digits in Godot's built-in font; no image or font file. | senior-graphic-designer |

## Not in the game

These files exist on disk but are not part of the game.

| Item | Where | Notes |
| --- | --- | --- |
| Design screenshots and review sheets, 54 PNGs: 15 screens (12 light, 3 dark), 3 play screens in Place mode, 6 state sheets, 9 ring close-ups, the font comparison set (5 Pop screens in Inter, and Pop's ring close-ups at 720 px, plain and x3, three layouts, in the default font and in Inter, 12 files), and the Phase 2 studies `auto-cross-study.png`, `selection-study.png` and their `-x3` copies | `docs/design/*.png` | Documentation written by `tools/design/capture.gd` and, for the four studies, `tools/design/mark_study.gd`. The Phase 1 screenshots were not recaptured in Phase 2; their Pop colors are the Phase 1 values. Godot ignores `docs/` (`docs/.gdignore`), so they are never imported or exported. The capture tool's own test output (`-- placeholder`) goes to Godot's user data folder (`user://capture_test/`), outside the repo. |
| App icon option renders: per option the full icon, the launcher icon and the themed (monochrome) icon at 512 and 48 px, a layer sheet with the safe zone drawn on, and one comparison sheet, 22 PNGs | `build/icon_options/` | Written by `tools/design/icon_options/render_icons.gd` for Bart's pick. Ignored by git (`/build/`) and by Godot's importer (`.gdignore` written by the script). Never committed, never shipped. |
| Inter font files (SIL Open Font License 1.1) | `build/font_compare/` | Comparison material for the Hard Stop 1 font question only. Ignored by git (`/build/`) and by Godot's importer (`.gdignore`). Read at capture time by `tools/design/directions/fonts.gd` with `FileAccess` and `FontFile.data`, never imported or copied. Nothing in the game references them. Inter appears only in the font comparison images, the files ending in `-inter.png` (see `docs/design/font-comparison.md`); every other image uses Godot's built-in font. |

## Checks

- 2026-10-11: no image, audio or font file (png, jpg, webp, svg, bmp, tga, ktx, exr, hdr, wav, ogg, mp3, ttf, otf, woff, woff2, fnt) anywhere in the repo outside `docs/` and `build/`. `build/font_compare/Inter-Regular.ttf` confirmed ignored by git.
- 2026-10-11, after the Phase 1 artist work: the same search finds no such file outside `docs/`, `build/` and Godot's ignored `.godot/` cache. Every board, screen, icon and the app icon above is drawn in code.
- 2026-10-11, Phase 2 (design system and skin files): the same search finds no such file outside `docs/`, `build/` and `.godot/`. The two skin files are plain text resources of colors and numbers. The four new PNGs are studies in `docs/design/`, written by `tools/design/mark_study.gd`. The design system adds no file of any of these kinds: the hatch, the key stripe, the switch and every icon are drawn in code.
- 2026-10-12, icon cleanup: the four app icon previews (`docs/design/app-icon-*.png`) were deleted; the other 54 PNGs in `docs/design/` were each opened and none shows food or any wordmark. The search for image, audio and font files finds none outside `docs/`, `build/` and `.godot/`. The three icon options are drawn in code and render only to `build/icon_options/`.
