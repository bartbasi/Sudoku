# QA review: release prep (changes since Phase 6)

Reviewer: qa-reviewer (functional). Date: 2026-10-22. HEAD 308fef4, reviewed range e563ab0..HEAD: c4e170c (title screen), f741f37, 7bc749f (Show candidates, MENU on title), b724502 (Buy me a coffee, Play, Inc. credits), 9d59761 (GPL, COPYING and NOTICE in About), e6e4977 and 308fef4 (coffee everywhere, cup under Pause, About from main menu, pause and Settings, completion sticker fix).

## Test suite

`timeout 900 godot --headless --path . --script res://tests/run_tests.gd`

- Tests: 683, passed: 683, failed: 0. Exit 0.
- window_check (child process): 5347 checks, 0 failed.
- Output has only expected warnings: an unknown icon test, two SaveWriter "not written" tests, and the test harness's own "non-equal opposite anchors" warnings from tests/ui/test_window_shapes.gd. No script errors.

## Extra runs (scratch files under build/qa/, not part of the project)

- build/qa/sweep.gd extends tests/ui/window_check.gd and runs every one of its screen checks (play, title, main menu with and without Continue, first launch, pause, completion with both New best tags, lists, dialog) over 120 window shapes: widths 320, 340, 360, 393, 412, 480, 600 and 800 at heights 480 to 960 every 40 dp (24 dp bars top and bottom), plus wide and short windows 560 to 1200 by 300 to 440. Result: 37663 checks, 0 failed.
- build/qa/probe.gd: five app level probes (results quoted in the findings and passes below).
- build/qa/probe2.gd and probe3.gd: About notice timing.
- build/sudoku-debug.apk inspected with unzip and aapt2 (read only).

## Findings

Counts: Critical 0, High 0, Medium 1, Low 4.

### Medium 1. The About screen drops frames for over a second while its notices build

- Where: src/ui/about_screen.gd:53 (LABELS_PER_FRAME = 24) and :102-127 (_process, _build_some).
- Expected: About scrolls smoothly from the moment it opens (the build is spread over frames so it does not hitch).
- Actual: the notices are 936 items, 1696 nodes and 124,510 characters. Built 24 per frame they take 39 frames. Measured headless on the Windows dev machine (build/qa/probe3.gd, which calls _build_some(24) once per frame as _process does): 34.4 ms per frame on average and 93.3 ms at worst, so about 1.3 s at well under 30 fps even on desktop. A phone is likely slower. Each batch costs more as the list grows (the VBox re-sorts every child), so the frames near the end are the worst. A player who opens About and flicks to the notices at once will see the scroll stutter.
- Steps: open About from any screen and scroll right away; or run `timeout 120 godot --headless --path . --script res://build/qa/probe3.gd`.
- Not measured on the device (see Could not test).

### Low 1. A saved Cross out puzzle with Show candidates off leaves every digit tap crossing a hidden candidate

- Where: src/ui/app.gd:162-171 (load_all keeps the saved mode as it is) and src/ui/play_screen.gd:129-131 (_apply_show_candidates only hides the toggle); the only place that forces Place is app.gd:440-446.
- Expected (GDD 4.5): with Show candidates off, Place is the only mode and every digit tap places.
- Actual: if settings.json has show_candidates false and puzzle.json has mode 1 (Cross out), PLAY opens the puzzle with the mode buttons hidden and the session in Cross out. A digit tap crosses that digit in the hidden ring and places nothing, and the player has no button to switch back. The only way out is to turn Show candidates on.
- Repro (build/qa/probe.gd, probe 1): start an Easy puzzle, select an empty cell, set mode Cross out, save; set settings.show_candidates = false and save the settings; reload the app and call play_now. Output: `mode=1 mode_buttons_visible=false`, then after tapping the cell's solution digit `digit=0 mark=1` (crossed, not placed).
- How it can happen in the field: set_show_candidates writes settings.json first (app.gd:442) and the puzzle with mode Place second (app.gd:445). A kill between the two writes, or a damaged or hand edited puzzle file, leaves this pair. The window is tiny and the release manifest has allowBackup=false, so no backup restore can mix the files. Hence Low, but the result is a stuck looking game, so a load time guard (or forcing Place when the play screen applies the setting) would close it.

### Low 2. CLAUDE.md does not record the 2026-10-22 decisions the GDD cites

- Where: CLAUDE.md "Decisions from Bart after the brief" ends at 2026-10-18; docs/GDD.md 15.1 and 15.7 cite "Bart, 2026-10-22" (and "later on 2026-10-22") for Buy me a coffee on the main menu, pause menu, Settings and completion screen, the coffee cup in the band under Pause, About on the main menu, pause menu and Settings, and the main menu's two rows of two.
- Expected: the fixed decision list in CLAUDE.md matches the rules the code and GDD follow.
- Actual: CLAUDE.md's 2026-10-17 entry still says the coffee button is "on the title screen (after ABOUT, less prominent) and on the About card". Docs disagree; I did not pick one. The code follows the GDD.

### Low 3. Stale comments about the screen stack and the support link

- src/ui/app.gd:549-553: the goto() comment says "The main menu, the first launch offer, the play screen and the completion screen start a fresh stack". ROOT_SCREENS (app.gd:55) is TITLE, MAIN_MENU, PLAY, COMPLETION; the first launch offer is pushed over the title screen (and that is what GDD 15.3 wants).
- src/ui/app.gd:627-628: open_support_page says "(the title screen and About)". It is now called from seven places (title, main menu, pause menu, Settings, completion, About, the cup).
- docs/ARCHITECTURE.md:681: `ABOUT ... pushed over the title screen`. Line 692 has the full list of places About opens from; line 681 should match.
- Behaviour is right in every case; only the words are out of date, which misleads the next reader.

### Low 4. The release APK in build/ is stale and has no NOTICE or COPYING

- Where: build/sudoku-release-unsigned.apk, dated 2026-10-12 (before c4e170c).
- Expected: any APK that could ship contains assets/NOTICE and assets/COPYING (GPL section 7(b) attributions shown in About).
- Actual: `unzip -l` finds neither file in it, and it predates the title screen, Show candidates and every coffee button. build/sudoku-debug.apk (2026-10-22 10:08) is current and correct (see below). The release APK must be rebuilt before any upload.

## GDD acceptance tests walked against the code

Pass means the code and the tests do what the AT expects; device only steps are listed under Could not test.

| AT | Result | Notes |
| --- | --- | --- |
| 15.0 Title screen | Pass | attach_host always goes to TITLE (app.gd:518-520). PLAY order: offer, puzzle in progress, new at last_level (app.gd:530-538), ignored while generating. Every title button ignores taps while generating (title_screen.gd:79, 89). Back on the title saves and quits. |
| 15.1 Main menu | Pass | Continue, New puzzle, Lessons and Stats, Settings and About, Buy me a coffee (main_menu.gd). Back on the main menu alone opens the title screen (app.gd:607-608). |
| 15.5 Info | Pass | Text compared with GDD 15.5 word for word by test_info_text_is_gdd_15_5_word_for_word; 15 headings in order; no em dashes. |
| 15.6 About | Pass | Card order and texts as listed; NOTICE and COPYING first, then rule, then engine notices; only Back and Buy me a coffee react. The About card's coffee has no is_generating guard (about_screen.gd:189-191) but About cannot be on top while a puzzle is made, so no effect. |
| 15.7 Coffee and About on more screens | Pass | Every coffee button guards is_generating; the cup pauses first, then opens the link, hides with the hint panel and full board message, and does nothing once the puzzle is finished (probe 3: after the last digit the cup press leaves `paused=false` and opens nothing). |
| AT-70 (cup under Pause, all window shapes) | Pass | window_check plus my 120 shape sweep: cup inside the band, under Pause, off the board, keys, sticker and header; 48 dp touch area. |
| AT-72 | Pass in code | Title on every start; background without kill keeps the pause menu (focus out pauses the play screen, app.gd:146-150). Kill and relaunch not run on device. |
| AT-73, AT-74, AT-75 | Pass in code and tests | Offer pushed over title, Back leaves it unanswered; Skip calls play_now; last_level saved at start and validated on load (settings.gd _level_from). |
| AT-76 | Pass | Back chains checked in tests and by reading go_back. |
| AT-77 | Pass | Scrolls, opens at the top, Back returns. |
| AT-78 | Pass (Core part); App part not on device | Version reads "1.0" from project settings; the exported project.binary carries config/version 1.0. |
| AT-79 | Pass | Row order, default on, damaged values load as on. |
| AT-80, AT-81, AT-82, AT-83, AT-84 | Pass in code and tests | Off forces Place with no undo step and saves; marks kept; Auto Cross runs hidden (SC-1 integration test); hint crosses drawn alone in the hint look. See Low 1 for the one gap. |
| AT-85 | Pass | Probe 5: with Show candidates off, the lesson player's PlayArea has show_ring true and the mode buttons visible; lessons never call set_show_candidates. |
| AT-86, AT-87 | Pass in code and tests | Exactly one URL per tap, nothing else changes; ignored while generating; the completion screen's coffee leaves the screen and the stats as they are. |
| AT-88 | Pass in code and tests | Parts 1, 3 and 4 covered by tests and the sweep; part 2 (swipe away from the browser) needs a device. |
| AT-89 | Pass | Probe 2: Pause, Settings, About, focus loss, 30 s of frames: time stays 100 s; Back goes to Settings, Back to the play screen still paused, 30 s more frames, time still 100 s; only the next Back resumes. |

## Edge cases hunted (passed)

- The cup pausing before the browser: show_pause runs first (board hidden, pause menu open, save written), then link_opener; a test checks the pause menu was open at the moment the link was handed over. Focus loss when the browser takes the screen saves again and finds the play screen already paused. Coming back shows the pause menu with the time unchanged.
- About over a paused puzzle and over Settings opened from pause: the play screen is hidden under them, so is_timer_running is false (it checks every ancestor's visibility); Back pops back to the still open pause menu. Too small while About shows: the layer covers it; Back under the layer pops About as on the screen underneath, then does nothing on the pause menu (GDD 8.1).
- Taps during generation: the overlay takes every tap, and every new button also checks is_generating (title PLAY, MENU, INFO, ABOUT, coffee; main menu About and coffee; pause About and coffee; Settings About and coffee; completion coffee; the cup). Back is ignored while generating.
- Back on every new path: first launch offer to title, unanswered; Info and About to the screen under them; About from Settings to Settings then to its opener; main menu to title; completion to main menu to title; title quits after save_all.
- Show candidates with hints: the hint keeps its cost and target; only open hint crosses show while hidden (test_show_ring). Toggling while a hint shows keeps it with no new charge. With Auto Cross: switch usable while hidden; Auto Cross marks update out of sight (SC-1 test).
- Completion screen on short windows: the sweep found no overlap, no cut off and no sticker clash in any window. As DESIGN_SYSTEM 7.9 documents, a stacked window up to about 640 dp tall scrolls the receipt when both New best tags show (228 of 311 dp shown at 320 by 560 with 24 dp bars); by design, not a finding.
- Exported build: build/sudoku-debug.apk (built 2026-10-22 10:08, same time as HEAD) contains assets/NOTICE and assets/COPYING, byte identical to the repo files (md5 c7592f20... and 1ebbd3e3...). aapt2 lists no permissions; allowBackup=false; portrait; resizeable. The export preset's include_filter adds COPYING and NOTICE and is the only preset, so a release export picks them up too.
- No changes in src/puzzles since Phase 6, so generation times stand as measured in qa-phase6.md.

## Could not test, and why

- Anything on a real phone. A Galaxy Z Fold5 (SM-F946U1) is attached with com.bartbasi.sudoku installed at 10:34 today, and the game was in the foreground on its title screen when I checked. That is Bart's live device, so I took one read only screen capture (deleted afterwards) and did not tap, install or open the browser on it. Not run therefore: the real browser intent and its logcat line, focus loss and return from the browser, swipe away from recents (AT-88 part 2), airplane mode (AT-78, AT-86, AT-87), kill and relaunch (AT-72 to AT-75), and frame rate on About and with a full board of candidates on the device.
- res://NOTICE and res://COPYING read at run time inside the APK: verified only that the files are in the package and identical to the repo; the About screen reading them on Android was not run.
- Headless has no renderer, so frame times above are CPU only.
