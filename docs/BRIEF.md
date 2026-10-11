# bartssudoku: Kickoff Brief

This is Bart Basi's kickoff brief, kept here word for word (markdown formatting added) so every agent can read it. It is the source of truth for the project. Only Bart changes it.

You are the Development Manager for bartssudoku, a free Sudoku game for Android (later iOS, Windows and Linux). You run the team described below, coordinate their work, integrate it, and report to Bart Basi, who owns the project. Read this whole brief before doing anything.

If anything here is unclear, conflicts with something else in this brief, or would force you to guess, stop and ask Bart. Do not pick an interpretation silently.

## 1. What we are building

A classic 9 by 9 Sudoku with one feature that sets it apart: every empty cell starts with all nine candidate digits printed small around the inside edge of the cell, and the player crosses them out as they rule them out. Section 3 describes it.

- Several difficulty levels. Every puzzle has exactly one solution.
- Lessons that teach a beginner the rules and the first solving techniques, on a real board.
- Stats so the player can see how they are doing over time.
- Hints the player pays for with score points, never money.
- An optional Auto Cross mode for players who want the game to do the basic crossing out.
- Light mode first, with built-in skins the player can switch between, including a dark mode.
- One clean, positive click sound, which the player can turn on or off.
- Fully offline. Free. No ads, no purchases.

## 2. Fixed decisions (do not revisit without asking Bart)

| Topic | Decision |
| --- | --- |
| Engine | Godot 4, latest stable 4.x installed on this machine. Record the exact version in README.md. |
| Language | GDScript, statically typed. No C#, no GDExtension. |
| Renderer | Compatibility renderer, for the widest Android device support. |
| Platform for v1 | Android, portrait only. Develop and iterate in the Godot editor on Windows. |
| Dev machine | Windows, Claude Code. |
| Repo | github.com/bartbasi/bartssudoku, private. |
| Assets | Nothing paid. Every visual and every sound is made in code. No image files, no audio files, no asset store downloads, no third-party addons. |
| Puzzles | Generated and graded by our own code. No puzzle files, packs or databases from anywhere else. |
| Network | None. No accounts, no ads, no analytics, no leaderboards. Release builds request no Android permissions. |
| Skins | Built-in only for v1. Light mode is the default. A dark mode skin is required. Player-made skins are a v2 or v3 feature. Do not build import of any kind. |
| Candidates | The player crosses candidates out by hand by default. An Auto Cross setting, off by default, lets the game do the basic crossing (section 3). |
| Hint payment | Cost is deducted from the current puzzle's score. |
| Puzzles in progress | One at a time. Starting a new puzzle while one is in progress asks the player to confirm abandoning it. |

## 3. The candidate ring (the signature feature)

This is the reason the game exists. Get it right before anything else.

**What it is.** Every empty cell shows nine small candidate slots, one per digit 1 to 9, placed around the inside edge of the cell. The center of the cell stays open. At the start of a puzzle every empty cell shows all nine digits.

**Crossing out.** The player can cross out any candidate. A crossed candidate stays visible with an X drawn over it, so the player can see what they already ruled out. The player can restore a crossed candidate. Nothing is crossed automatically unless the player turns on Auto Cross.

**Bart's example.** A cell sits in a row that contains 9 and 3, a column that contains 4 and 6, and a 3 by 3 box that contains 2, 3 and 4. The player can cross out 2, 3, 4, 6 and 9, leaving 1, 5, 7 and 8 open. Use this exact case as a worked example in the GDD and as an acceptance test.

**Auto Cross (optional).** A setting, off by default. When the player turns it on, the game crosses out every candidate that a given or placed digit in the same row, column or box rules out, and keeps doing so as digits are placed.

- It never changes a candidate the player crossed or restored by hand.
- When a digit is erased, it restores only the candidates it crossed itself that nothing else on the board still rules out.
- It only looks at digits already on the board. It never uses the solution and never applies deeper techniques.
- Turning it off leaves the board as it is, and the player continues by hand.

Designer decides whether using Auto Cross affects the score, and whether an automatic X looks different from a manual one.

**Placing a digit.** A placed digit shows large in the center of the cell, and the ring hides while the cell holds a digit. Erasing the digit brings the ring back exactly as the player left it.

**Slot layout.** Nine slots around a square edge with no center slot cannot be perfectly symmetric. The senior graphic designer proposes at least two layouts. In every layout each digit sits in the same spot in every cell, and the order is easy to learn (for example 1, 2, 3 across the top and continuing clockwise). Bart picks one at Hard Stop 1.

**Touch input.** On a phone a cell is roughly 35 to 45 dp wide, so one candidate slot is under 12 dp. Android's minimum comfortable touch target is 48 dp. Tapping individual slots directly will miss often. The required input is:

- The number pad has two modes: Place and Cross Out. A clear toggle switches between them.
- In Cross Out mode, the player selects a cell and taps digits on the pad. Each tap crosses that candidate, or restores it if it is already crossed.

Direct tapping on ring slots is not in v1 unless the board-input-dev shows on Bart's phone that it works reliably, and Bart approves it.

**Readability.** Open candidates, crossed candidates and placed digits must be told apart by shape and size, not by color alone. Open candidate digits meet 4.5:1 contrast against the cell. The X on a crossed candidate meets 3:1. Check both with the contrast script, at the smallest board size we support.

## 4. Game rules (the Lead Game Designer turns this into docs/GDD.md)

The designer fills the gaps marked Designer decides, documents each decision with worked examples, and gets Bart's sign-off at Hard Stop 1.

**Board.** Standard 9 by 9 Sudoku with nine 3 by 3 boxes. Given digits are locked and styled differently from digits the player places.

**Selection.** Tapping a cell selects it. The selected cell's row, column and box are highlighted. Designer decides whether other cells holding the same digit are also highlighted.

**Entering.** Place mode puts the tapped digit in the selected cell, replacing any digit already there. An Erase button clears a placed digit. Cross Out mode works as in section 3.

**Mistakes.** Designer decides, with a recommendation for Bart, between:

- No checking until the board is full.
- Showing conflicts only (two equal digits in one row, column or box), which never reveals the solution.
- Checking each placed digit against the solution.

**Undo.** Undo steps back one action at a time: placing, erasing, crossing and restoring. Designer decides whether undo history survives closing the app.

**Timer.** Shows elapsed time. Pauses when the pause menu is open or the app goes to the background.

**Score.** Designer decides how a puzzle earns points (for example by level, time, and mistakes if mistakes are checked), with worked examples for an easy, a medium and a hard puzzle. The score shows in the HUD during play. Score can never go below zero.

**Hints.** Paid from the current puzzle's score, never money. A hint the player cannot afford is visibly disabled. Designer decides, with a recommendation for Bart:

- What a hint does. One option: the technique solver finds the next logical step, highlights the cells involved, explains it in one or two plain sentences, and names the lesson that teaches it. Another option: fill in one correct digit.
- The cost (flat, or scaled to level), with reasoning and examples from an easy, a medium and a hard puzzle.

**Completion.** When every cell is filled and the board is valid, the puzzle ends with a completion screen showing level, time and score, and stats update.

**Persistence.** The puzzle in progress saves automatically and resumes after the app is closed or killed, including every placed digit, every crossed candidate, the timer, the score, and the current mode. Settings (sound on or off, selected skin, Auto Cross), stats and lesson progress persist.

## 5. Difficulty levels and puzzle generation

**Levels.** Designer decides how many levels (four to six is typical) and their names. Difficulty is set by the hardest solving technique a person needs, not by how many digits are given. The GDD lists which techniques each level allows and which it requires.

**Generator.** The puzzle-engine-dev builds:

- A solver that proves a puzzle has exactly one solution.
- A technique solver that solves step by step the way a person would and reports the hardest technique used. This grades each puzzle into a level.
- A generator that makes a full grid, removes digits, and keeps a puzzle only if it has one solution and grades at the requested level.

The RNG is seedable. Every puzzle has an ID that reproduces it exactly, for tests and bug reports.

**On device or pre-built.** Hard puzzles may take a long time to generate on a phone. Two options, both our own code:

- Generate on the device when the player starts a puzzle.
- A tool in tools/puzzles/ generates a bank of graded puzzles ahead of time, shipped as a data file in the repo.

In Phase 2, measure generation time per level and bring a recommendation to Bart at Hard Stop 2.

## 6. Stats

Per level: puzzles started, puzzles completed, best time, average time, best score. Overall: lessons completed. An abandoned puzzle counts as started, not completed. Designer decides the final list from these and any additions, and Bart approves additions. Settings has a Reset Stats button with a confirmation. All stats stay on the device.

## 7. Lessons for beginners

**Format.** A Lessons screen lists lessons in order. Each lesson is a few short screens of plain text, each paired with a real board where the player does the step being taught. The player cannot fail a lesson. A wrong tap gets a short explanation and another try.

**Sequence.** The lesson designer writes docs/LESSONS.md. It must cover at least:

- The rules of Sudoku.
- Using the candidate ring and Cross Out mode, using Bart's example from section 3.
- Every technique the two easiest levels require (for example last empty cell in a group, naked single, hidden single).

Designer decides whether to add lessons for harder techniques in v1. Each level in the GDD names the lessons that teach its techniques.

**Data.** Lesson boards are written as data in src/lessons/data/. A test checks that every lesson board is valid and that each step's correct answer actually follows from the board.

**First launch.** The game offers lesson 1 on first launch. The player can skip it.

## 8. Visual and sound direction

Design is a top quality bar. It has to look fresh, modern and clean, not like a template. For Sudoku, readability comes first: 81 cells and up to 729 small candidates on one phone screen.

- Light mode first, bold colors. All three design directions (Phase 1) are light and live inside that range but must be clearly different from each other, not three color swaps of one layout.
- Dark mode. Each direction must also work in dark. The chosen direction's dark version ships as a built-in skin, and it passes the same contrast checks.
- Every visual is built in Godot code: StyleBoxFlat, Theme resources, _draw() calls, shaders, Tweens. No image files.
- Box borders must read clearly heavier than cell borders.
- Text and digit contrast is checked by a script, not by eye: 4.5:1 for digits and text, plus the candidate rules in section 3. Color is never the only signal.
- Respect device safe areas (notches, rounded corners, gesture bar).
- Target 60 fps on a mid-range Android phone.
- Fonts. Open question for Bart at Hard Stop 1. A font file, even a free open-license one, is not "made in code". The default is Godot's built-in font or the device's system font. The senior designer shows the chosen direction both ways (system font and one free open-license font) so Bart can decide. Digit legibility at candidate size decides this.

**Click sound.** Synthesized in code at startup into an AudioStreamWAV (short, bright, soft attack, quick decay, roughly 50 to 90 ms, no clipping). It plays when the player places a digit and when they cross or restore a candidate. On by default. The toggle lives in Settings and persists. No other sounds in v1 unless Bart approves them.

## 9. The team

In Phase 0, create one agent file per role in .claude/agents/, using each role below as the source for the file's description and instructions. Each file says what the agent owns, what it reads, what it produces, and that it must not touch files outside its ownership.

Subagents cannot launch other subagents. You, the main session, launch every agent. When the Senior Graphic Designer needs its two artists, it writes their task briefs and you launch them.

**Development Manager** (you, the main session). Owns the plan, docs/ARCHITECTURE.md, integration, git, and all communication with Bart. You launch agents, check their output against the brief, resolve conflicts between them, and enforce hard stops.

**Lead Game Designer** (lead-game-designer). Writes docs/GDD.md from sections 3 to 6. Owns rules, input model, Auto Cross, mistake handling, scoring, hint behavior and costs, levels and their techniques, and stats definitions. Reviews ARCHITECTURE.md and LESSONS.md for rule accuracy. Writes the acceptance test list QA uses. Tools: Read, Write, Edit, Glob, Grep.

**Lesson Designer** (lesson-designer). Writes docs/LESSONS.md and the lesson board data in src/lessons/data/. Writes for someone who has never played Sudoku: short sentences, one idea per screen. Tools: Read, Write, Edit, Glob, Grep.

**Senior Graphic Designer** (senior-graphic-designer). Owns the visual identity. Produces the three design directions and the candidate ring layout options, then docs/DESIGN_SYSTEM.md (color tokens, given and placed digit styles, candidate and crossed-candidate styles, highlight colors, type scale, spacing, corner radii, motion timing and easing). Writes briefs for the two artists and reviews everything they produce. Final say on visual quality below Bart. Tools: Read, Write, Edit, Glob, Grep, Bash.

**Grid and Cell Artist** (grid-cell-artist). Builds the board visuals in code: grid and box lines, cell states (given, placed, empty, selected, highlighted, conflict), the candidate ring, the X mark, and placement effects. Builds the skin system as data (one Resource per skin) that the developers read from. Tools: Read, Write, Edit, Glob, Grep, Bash.

**UI and Motion Artist** (ui-motion-artist). Builds the Godot Theme for menus, HUD, number pad, buttons and dialogs, draws icons in code (undo, erase, mode toggle, settings, pause), and builds shared animation helpers from the design system. Tools: Read, Write, Edit, Glob, Grep, Bash.

**Core Logic Developer** (core-logic-dev). Pure game rules with no UI and no Node dependencies: board model, givens, placed digits, candidate state per cell, Auto Cross, conflict detection, undo, completion check, timer model, score, hint affordability and cost deduction, stats math. Unit tests for all of it. Tools: Read, Write, Edit, Glob, Grep, Bash.

**Puzzle Engine Developer** (puzzle-engine-dev). Uniqueness solver, technique solver and grader, generator with seedable RNG, the next-step finder that hints use, the generation timing measurement, and the bank tool in tools/puzzles/ if Bart picks that option. No UI. Unit tests for all of it. Tools: Read, Write, Edit, Glob, Grep, Bash.

**Board and Input Developer** (board-input-dev). The board scene and number pad: touch and mouse input, cell selection, Place and Cross Out modes, highlighting (including hint highlights), applying core results to the view, scaling to screen size and safe area. Uses the artists' visuals; never hardcodes colors or sizes. Tools: Read, Write, Edit, Glob, Grep, Bash.

**Lessons Developer** (lessons-dev). The lesson player: reads lesson data, runs each step on the shared board scene, checks the player's input, gives feedback, records lesson progress. Does not write lesson content. Tools: Read, Write, Edit, Glob, Grep, Bash.

**UI Systems Developer** (ui-systems-dev). HUD (level, timer, score, hint button, pause), main menu, level select, pause, completion screen, stats screen, settings (sound toggle, skin picker, Auto Cross toggle, reset stats), save and load, Android lifecycle (save on pause or focus loss, back button). Tools: Read, Write, Edit, Glob, Grep, Bash.

**Audio Developer** (audio-dev). The synthesized click, a small audio service the game calls, and the persisted toggle hook. Small job; finish it fully. Tools: Read, Write, Edit, Glob, Grep, Bash.

**Platform Developer** (platform-dev). project.godot settings, Android export preset, debug keystore setup per current Godot docs, .gitignore, build and install scripts, README build steps. Verifies the release preset requests no permissions. Tools: Read, Write, Edit, Glob, Grep, Bash.

**Functional Reviewer** (qa-reviewer). Runs all tests, walks the GDD acceptance list, hunts edge cases (cross out all nine candidates in a cell, restore after crossing, erase a digit and check the ring comes back unchanged, undo across mode switches, resume mid-puzzle after the app is killed, abandon a puzzle and check stats, hint at zero score, Auto Cross turned on and off mid-puzzle, Auto Cross next to manual crosses, erase with Auto Cross on, lesson wrong answers, rotation lock, tiny and huge screens), and checks performance including puzzle generation time. Writes reports only to docs/reviews/. Does not fix code. Tools: Read, Glob, Grep, Bash, Write.

**Security Reviewer** (security-reviewer). Reviews the save system (JSON only via the JSON class; never str_to_var, bytes_to_var or any loader that can instantiate objects from file data; full validation of loaded data with safe fallback; atomic writes), the puzzle bank and lesson data loading if they are files, Android manifest and permissions, secrets and keystores kept out of git, no network code anywhere, and that nothing third party entered the repo. Writes reports only to docs/reviews/. Does not fix code. Tools: Read, Glob, Grep, Bash, Write.

## 10. Repo layout and file ownership

```
bartssudoku/
  CLAUDE.md              standing rules for every session (you)
  README.md              build and run steps (platform-dev)
  project.godot          (platform-dev)
  export_presets.cfg     (platform-dev)
  docs/
    GDD.md               (lead-game-designer)
    LESSONS.md           (lesson-designer)
    ARCHITECTURE.md      (you)
    DESIGN_SYSTEM.md     (senior-graphic-designer)
    ASSETS.md            log proving every asset is made in code (senior-graphic-designer)
    design/              direction screenshots (senior-graphic-designer)
    reviews/             (qa-reviewer, security-reviewer)
  src/
    core/                (core-logic-dev)
    puzzles/             (puzzle-engine-dev)
    board/               (board-input-dev)
    lessons/             (lessons-dev)
    lessons/data/        (lesson-designer)
    ui/                  (ui-systems-dev)
    save/                (ui-systems-dev)
    audio/               (audio-dev)
    skins/               (grid-cell-artist)
    design/              theme, icons, motion helpers (ui-motion-artist)
  scenes/                each scene owned by the dev of the matching src/ folder
  tests/                 run_tests.gd plus one folder per src/ area, owned by that area's dev
  tools/
    design/              contrast checker, screenshot capture (senior-graphic-designer)
    puzzles/             puzzle bank tool, only if approved (puzzle-engine-dev)
```

Tests use a small headless runner we write ourselves (tests/run_tests.gd, extending SceneTree). No test framework addon.

## 11. Rules for running the team

- Before parallel development starts, write docs/ARCHITECTURE.md: the data model, every class each area exposes, every signal with its arguments, the lesson data format, and how skins and the theme are read. Agents build against this contract. If an agent needs the contract changed, it asks you; it does not change another area's code.
- Each agent edits only the files it owns. If two agents need the same file, you split the file or do the integration edit yourself.
- Agents do not commit. You commit after each integration step, with a clear message, once tests pass.
- Every agent brief you write states the task, the files it may touch, the docs it must read, and how it will prove the work is done (a test, a screenshot, a command output).
- Keep it simple. No features, settings or abstractions beyond this brief. If an agent proposes extra scope, bring it to Bart as a suggestion.
- Priority order for all decisions and fixes: security and bugs first, then readability and fun, then polish.
- No em dashes and no double hyphens in any prose: docs, UI text, lesson text, commit messages. Write plainly, like a person.
- Use the Claude Code task list so Bart can see progress at a glance. At the end of each phase, post a short status: what is done, what was verified, what is next, anything blocking.

## 12. Phases

### Phase 0: Environment and scaffold

- Check for git, gh (logged in as bartbasi), the Godot 4 console executable, Godot export templates, the Android SDK with adb, and the JDK version the current Godot Android export docs require. If anything is missing, stop and give Bart exact install steps. Do not install software without asking.
- Create the folder layout, CLAUDE.md (sections 2, 10 and 11 condensed), .gitignore (.godot/, build/, *.keystore, *.jks, and any file Godot uses for export credentials), the agent files from section 9, and an empty Godot project that opens and runs.
- git init locally. Create nothing on GitHub yet.
- Verify: godot --headless --path . --quit exits cleanly. The test runner runs and reports zero tests.

### Phase 1: Rules, lesson outline and design directions (in parallel)

- Lead Game Designer writes docs/GDD.md, including every "Designer decides" item and the acceptance test list.
- Lesson Designer writes the LESSONS.md outline: lesson titles, the technique each one teaches, and one fully written lesson (lesson 2, the candidate ring) as a sample.
- Senior Graphic Designer plans three distinct light, bold directions and the candidate ring layout options, and briefs the two artists. Each direction is built as real Godot scenes, not pictures, showing four screens: a mid-puzzle board with some candidates crossed, a cell selected in Cross Out mode, and the score and hint button in the HUD; a lesson step; the stats screen; and puzzle complete. Each direction also shows the mid-puzzle board in dark mode.
- A capture scene in tools/design/ renders each screen at 1080 by 2400 to PNG in docs/design/, plus a close-up of each ring layout at true phone size. The contrast script checks every color pair, including candidates and the X mark, and must pass.
- Each direction gets a one-page write-up: name, concept in a few sentences, palette tokens with hex values, cell and candidate styles, type, motion idea.
- Team review: the senior designer, the lead game designer and you each rank the three directions with short reasons. Combine these into a recommendation.
- Verify: GDD has every decision with examples, including Bart's candidate example. Fifteen screenshots (twelve light, three dark) and the ring close-ups exist. Contrast script passes for all three directions in light and dark.

**HARD STOP 1.** Show Bart the GDD summary, the mistake-handling, scoring and hint recommendations, the lesson outline and sample lesson, the fifteen screenshots, the ring layout options, the team ranking, and the font comparison. Bart approves the rules, picks a direction and a ring layout, and decides the font question. Also ask Bart whether the two unpicked directions should become alternate built-in skins. Do not start Phase 2 until he answers.

### Phase 2: Contract, design system, lessons and generation timing

- You write docs/ARCHITECTURE.md. The lead game designer checks it against the GDD.
- The senior designer turns the chosen direction into docs/DESIGN_SYSTEM.md and the skin Resources, including its dark mode skin.
- The lesson designer finishes LESSONS.md and the lesson data. The lead game designer checks it for rule accuracy.
- The puzzle-engine-dev builds a first generator and measures average and worst generation time per level on Windows, then estimates phone times.
- Verify: all three docs exist, every area in section 10 has its interface listed, and the timing table exists.

**HARD STOP 2 (generation approach and first push).** Show Bart the timing table and your recommendation: generate on device or ship a pre-built bank. Ask Bart before creating the GitHub repo or pushing. When approved: gh repo create bartbasi/bartssudoku --private, then push.

### Phase 3: Build (developers and artists in parallel)

- Launch the six developers and the two artists against the contract.
- Core logic and puzzle engine reach full unit test coverage of the GDD rules before you integrate them. Tests include: a sample of generated puzzles per level each has exactly one solution and grades at its level; the same seed always produces the same puzzle; every lesson board passes its validity test.
- Verify: all tests pass headless: godot --headless --path . --script res://tests/run_tests.gd.

### Phase 4: Integration, playable on Windows

- Wire everything together. Play it in the editor on Windows with a mouse.
- Verify: a full puzzle from new game to completion works at the easiest level; Bart's candidate example works in Cross Out mode; undo works across placing and crossing; Auto Cross works on and off without touching manual crosses; hints deduct score and disable when unaffordable; every lesson runs start to finish; stats update after a completed and an abandoned puzzle; the sound toggle works; the skin switch works; quitting and reopening resumes the puzzle with every crossed candidate intact.

### Phase 5: Android

- Platform developer builds a debug APK: godot --headless --path . --export-debug "Android" build/bartssudoku-debug.apk.
- Give Bart the steps to enable USB debugging on his phone, then install with adb install -r build/bartssudoku-debug.apk.
- Verify: Bart confirms it installs and plays on his phone. Check candidate readability at arm's length, Cross Out mode feel, frame rate, safe areas, back button, puzzle generation wait time at the hardest level, and resume after the app is swiped away.

### Phase 6: Functional and security review

- Launch qa-reviewer and security-reviewer in parallel. Each writes a report in docs/reviews/ with findings rated Critical, High, Medium or Low, each with steps to reproduce or the file and line.
- Assign every Critical and High finding to the owning agent. Re-review each fix. Repeat until no Critical or High remain.
- Give Bart the Medium and Low list so he can decide what to fix now.

## 13. Definition of done for v1

- Debug APK installs and runs on Bart's Android phone, portrait, smooth.
- Play follows the approved GDD exactly.
- Every empty cell starts with all nine candidates around its edge; the player can cross out and restore any of them; crossed candidates stay visible.
- Auto Cross is off by default and never changes a candidate the player set by hand.
- Hints work, are paid from score, and disable when unaffordable.
- Every level produces puzzles with exactly one solution, graded by technique.
- Every lesson in LESSONS.md works on a real board.
- Stats track per level and survive closing the app.
- Built-in skins switch live; the default is the approved light direction, and its dark mode skin is included.
- The click sound is synthesized in code and the toggle persists.
- The puzzle in progress, settings, stats and lesson progress survive closing the app.
- All unit tests pass headless. Contrast script passes.
- QA and security reports show no open Critical or High findings.
- docs/ASSETS.md shows every visual and sound is made in code, with no third-party files.
- Release export preset requests no Android permissions.

## 14. Out of scope for v1

Daily puzzles, Sudoku variants (Killer, diagonal and others), player-made skins, any file import, online features of any kind, ads, in-app purchases, iOS, Windows and Linux builds, store listings, release signing keys, and any Play Console work. Store-related work needs Bart's explicit go-ahead.
