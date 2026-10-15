# Sudoku

Sudoku (working name in older docs: bartssudoku; Bart may choose a final name later) is a free, offline 9 by 9 Sudoku for Android, portrait only. Signature feature: every empty cell shows all nine candidates around its inside edge, and the player crosses them out. Owner: Bart Basi. The main session is the Development Manager. Full brief and source of truth: docs/BRIEF.md.

## Fixed decisions (ask Bart before changing any)

- Godot 4.7.2 stable, Compatibility renderer. GDScript, statically typed (untyped declarations are compile errors in this project). No C#, no GDExtension.
- v1 is Android, portrait only. Develop and iterate in the editor on Windows.
- Repo: github.com/bartbasi/Sudoku, private.
- Nothing paid, nothing third party. Every visual and every sound is made in code. No image, audio or font files, no asset store downloads, no addons. Text uses Godot's built-in font.
- Puzzles are generated and graded by our own code. No outside puzzle files, packs or databases.
- No network code anywhere. No accounts, ads, analytics or leaderboards. Release builds request no Android permissions.
- Skins are built in only. Light is the default, a dark skin is required. No import of any kind.
- Candidates are crossed by hand by default. Auto Cross is a setting, off by default.
- Hints are paid from the current puzzle's score, never money.
- One puzzle in progress at a time. Starting another asks the player to confirm abandoning it.

## Decisions from Bart after the brief

- 2026-10-12: The game is named Sudoku: the name under the icon, the menu title and the Android package com.bartbasi.sudoku. It is a placeholder; Bart may pick a better name later. Nothing in this project refers to any other app or business. docs/BRIEF.md keeps its original wording.
- Git author for this repo is Bart Basi <331822203+bartbasi@users.noreply.github.com> (set in the repo's own git config).
- App icon: drawn in code (src/design/). It becomes PNG only at build time and is never committed as an image.
- 2026-10-12: The app icon is option 1, Ring (one cell with its candidate ring, two candidates crossed in magenta, on the Pop blue tile), for every form: full icon, Android adaptive layers and the monochrome themed icon. It is drawn in one bolder look at every size, with 3 and 8 crossed (Bart approved the final sheet).
- 2026-10-11: The Hard Stop 1 font comparison shows the team's top-ranked direction in Godot's default font and in Inter (SIL Open Font License). The Inter files live only in build/font_compare/, which git ignores. Nothing in the game references them.
- 2026-10-11: Progress is reported in phase status messages.
- 2026-10-11, Hard Stop 1 (Bart approved every recommendation):
  - Rules: docs/GDD.md is approved. Mistakes show conflicts only. Score is level points minus hint costs, plus a time bonus at completion. A hint never fills anything in; it points to a wrong digit or shows the next logical step, and costs a fifth of the level's points.
  - Reset Stats keeps lesson progress. Erasing a digit brings back every hand mark exactly as left; with Auto Cross on, its own marks update to match the board as it is now.
  - The completion screen shows "New best time" or "New best score" when a result beats the level's previous best.
  - Lessons 1 to 5 only in v1. No lessons for Medium techniques.
  - Design direction: Pop, with the Phase 2 fixes in docs/design/ranking.md. v1 ships Pop light (default) and Pop dark only; no alternate skins.
  - Candidate ring layout A, reading rows (1 2 3 4 / 5 . 6 / 7 8 9).
  - Font: Godot's built-in font. No font files ship.
  - A digit crossed by hand is drawn on top of its X with a thin outline, so it stays readable. This replaces the brief's "X drawn over it" wording.
  - Screens: the game must fit and work at 320 by 568 dp; readability is judged at 360 dp wide.
  - The app icon background follows Pop's palette.
- 2026-10-12, Hard Stop 2 (Bart approved every recommendation):
  - Beginner to Hard are generated on the device. Expert is drawn from a pre-built bank of about 1,000 puzzles made by our own generator, with the same puzzle ids. The bank tool in tools/puzzles/ is approved.
  - The private GitHub repo is created and main is pushed.
  - Beginner and Easy get a floor on the number of givens; the lead game designer tunes the numbers. No symmetric givens in v1.
  - A hint that points to a cell also highlights the candidate to cross out in that cell.
  - Informational, accepted: the lesson wrong-tap tag reads "Not quite".

- 2026-10-12, Phase 6 (Bart):
  - Fix before v1: save speed (saves off the main thread, the size cap enforced on write, no double save), the small bugs (pause after focus loss while a puzzle is made, empty fallback hint tag, completion counted twice if killed mid-completion, durable save write) and docs/ASSETS.md catch-up.
  - Split screen is allowed. The game must lay out well in any window shape a foldable gives it (Galaxy Z Fold5 cover and inner screens, split screen), including wide and short windows. The device orientation stays portrait.
  - Back or a tap outside the "Start a new puzzle?" dialog means Keep playing.
  - Later, not v1: worst-case board redraw time, the tablet hint panel size, the Godot Android template defaults (command line intent extra, provider authority, profileable).
  - Kept as built: the last lesson screen's button says Next; in a lesson, the mode button already on gives the wrong-tap text.

- 2026-10-14, title screen (Bart):
  - Every app start opens a title screen: the wordmark and hero, then PLAY, INFO and ABOUT. Back on it closes the app.
  - PLAY goes straight into a puzzle: it resumes the puzzle in progress, or else starts a new puzzle at the last level started (Easy the first time). The main menu stays as it is, reached from the pause menu's Menu; Back on the main menu now opens the title screen (this replaces "Back on the main menu closes the app").
  - Later the same day: the title screen also has MENU, under PLAY, which opens the main menu (order PLAY, MENU, INFO, ABOUT).
  - INFO explains everything a player needs: scoring, time bonus, hints and their cost, every control, the candidate ring, Cross Out, Auto Cross, mistakes, levels, stats.
  - ABOUT: the game name and version, "Copyright 2026 Bart Basi. All rights reserved.", that it is free, offline and collects nothing, and the open source notices for Godot and what it ships (from the engine's own license data). No GitHub address until the repo is public.

- 2026-10-14, Show candidates (Bart): a Settings switch, on by default, that hides the candidate ring on the play screen.
  - Hidden, the Place / Cross out mode button is hidden too and every tap places a digit (a session in Cross out switches to Place).
  - Marks are kept while hidden and show exactly as left when turned back on. Auto Cross keeps working out of sight.
  - A hint that points to a candidate to cross shows just that candidate in its cell; the rest stay hidden.
  - Lessons always show the ring.

## Ownership

Each path has one owner. Edit only what you own.

| Path | Owner |
| --- | --- |
| CLAUDE.md, docs/BRIEF.md, docs/ARCHITECTURE.md, .claude/agents/, tests/run_tests.gd, tests/unit_test.gd | Development Manager |
| README.md, project.godot, export_presets.cfg, .gitignore, .gitattributes, tools/build/ | platform-dev |
| docs/GDD.md | lead-game-designer |
| docs/LESSONS.md, src/lessons/data/ | lesson-designer |
| docs/DESIGN_SYSTEM.md, docs/ASSETS.md, docs/design/, tools/design/ | senior-graphic-designer |
| src/skins/ (skin Resources and the board drawing code) | grid-cell-artist |
| src/design/ (Theme, code drawn icons, motion helpers) | ui-motion-artist |
| src/core/ | core-logic-dev |
| src/puzzles/, tools/puzzles/ (bank tool only if Bart approves it) | puzzle-engine-dev |
| src/board/ | board-input-dev |
| src/lessons/ except src/lessons/data/ | lessons-dev |
| src/ui/, src/save/ | ui-systems-dev |
| src/audio/ | audio-dev |
| docs/reviews/ | qa-reviewer, security-reviewer |

- scenes/<area>/ belongs to the owner of src/<area>/. tests/<area>/ belongs to the owner of src/<area>/.
- In src/skins/, the scripts belong to grid-cell-artist and the skin data files pop_light.tres and pop_dark.tres belong to senior-graphic-designer.
- scenes/lessons/ holds the lessons list and the lesson player (lessons-dev).
- docs/GENERATION_TIMING.md belongs to puzzle-engine-dev.
- docs/ARCHITECTURE.md is the contract every area builds against.
- The lesson board validity test lives in tests/lessons/ (lessons-dev).
- Autoload and input map entries in project.godot are integration edits made by the Development Manager.
- Phase 1 design prototypes go in the folder each artist's task brief names.

## Rules for the team

- Build against docs/ARCHITECTURE.md once it exists. Need the contract changed? Ask the Development Manager. Never change another area's code.
- If two agents need the same file, the Development Manager splits it or makes the edit.
- Agents never commit. The Development Manager commits after each integration step, once tests pass.
- Every task brief states the task, the files the agent may touch, the docs to read, and how the work will be proven (a test, a screenshot, a command output).
- Keep it simple. No features, settings or abstractions beyond the brief. Extra ideas go to Bart as suggestions.
- Priority for every decision and fix: security and bugs, then readability and fun, then polish.
- No em dashes and no double hyphens in prose: docs, UI text, lesson text, commit messages. Write plainly. Command flags inside code formatting are fine.
- If the brief is unclear, conflicts with itself, or would force a guess, stop and ask. Never pick an interpretation silently.
- Hard stops are real. Do not start the next phase until Bart answers.

## Commands

Run Godot from Bash with `godot` (the 4.7.2 binary on PATH, works headless). Wrap every call in `timeout`, because a script error before `quit()` leaves Godot running.

```
timeout 120 godot --headless --path . --import        # once after a fresh clone
timeout 120 godot --headless --path . --quit          # project opens and runs
timeout 600 godot --headless --path . --script res://tests/run_tests.gd           # all tests
timeout 600 godot --headless --path . --script res://tests/run_tests.gd -- core   # paths containing "core"
```

Headless mode has no renderer. Anything that captures screenshots must run with a window.

## Tests

- Test files are `tests/<area>/test_*.gd`, extending `res://tests/unit_test.gd`.
- Every method whose name starts with `test_` runs on a fresh instance. Tests are synchronous.
- Assertions: `assert_true`, `assert_false`, `assert_eq`, `assert_ne`, `fail`.
- A script error during a test fails it. The runner exits 0 only when every test passes.

## Environment

Windows 11. Godot 4.7.2 with 4.7.2 export templates. Android SDK at C:\Android\Sdk (platform-tools 37.0.1 with adb, build-tools 35.0.1, platform android-35, cmdline-tools). JDK 17 (Temurin). The Android debug keystore lives in Godot's user data folder, never in the repo.
