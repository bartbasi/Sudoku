# Functional review, Phase 6

Reviewer: qa-reviewer. Date: 2026-10-12. Commit reviewed: 05c8eb4 (working tree clean).

## Summary

- All 543 tests pass headless. The contrast script passes (945 of 945).
- Every one of the 69 acceptance tests in docs/GDD.md section 16 passes where it can be checked here. 65 have direct test coverage, 3 (AT-17, AT-32, AT-64) are covered in part plus code reading or captures, and 1 (AT-65, rotation) needs a phone in hand.
- No Critical and no High findings.
- 2 Medium and 6 Low findings, listed below.

| Rating | Count |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 2 |
| Low | 6 |

## How I tested

- `timeout 900 godot --headless --path . --script res://tests/run_tests.gd`: Tests: 543, passed: 543, failed: 0, exit 0. One expected warning ("Unknown icon: no_such_icon") from a test that checks exactly that.
- `timeout 300 godot --headless --path . --script res://tools/design/check_contrast.gd`: 945 of 945 pairs and checks pass.
- Read the code behind every rule in the GDD, mainly src/core/game_session.gd, src/ui/app.gd, src/ui/play_screen.gd, src/board/board_controller.gd, src/puzzles/next_step.gd and src/lessons/lesson_player.gd.
- Scratch scripts in build/qa/ (git ignores it), run headless or windowed with their own save folders under user://, never the real saves:
  - qa_perf.gd: generation per level on new seeds, Expert bank load, NextStep.find, Auto Cross.
  - qa_floor.gd: AT-68 in full (seeds 1 to 200, Beginner and Easy).
  - qa_save_perf.gd and qa_save_split.gd: save cost against undo history length.
  - qa_focus.gd: losing focus while a puzzle is being made.
  - qa_window.gd with draw_probe.gd: windowed captures at 320 by 568, 360 by 800, 1024 by 1366 and 700 by 420 (Expert puzzle, times over an hour and over ten hours, a hint with eliminations, a skin switch mid puzzle through Pause and Settings, completion and stats with long times), plus the busy board redraw time. Pictures are in build/qa/shots/.
- Read only on the phone (adb serial R3CWA0Q2JQP): `dumpsys package com.bartbasi.sudoku` shows no requested or runtime permissions. aapt2 on build/sudoku-debug.apk and build/sudoku-release-unsigned.apk: no uses-permission entries, screenOrientation portrait, allowBackup false.

## Findings

### M1. Every tap rewrites the whole save on the main thread, and the cost grows with the undo history (Medium)

- Owner: ui-systems-dev (src/ui/app.gd), with core-logic-dev (GameSession.to_dict, UndoStep.to_dict).
- Where: src/ui/app.gd lines 171 to 174 (save_session) and 309 to 318 (save on board_changed, mode_changed and hint_changed). A placement that closes a hint saves twice in the same tap (board_changed, then hint_changed).
- Expected: a tap answers within a frame for the whole puzzle (BRIEF section 8, 60 fps target; GDD 14 asks for a save after every board change, but not that it blocks the tap).
- Actual, measured on the laptop with the debug editor binary, one save of an Expert puzzle in Cross Out play:

| Undo steps | File size | One save, median | Of that, to_dict plus JSON |
| --- | --- | --- | --- |
| 100 | 5 KB | 4.8 ms | small |
| 1000 | 42 KB | 10.9 ms | 7.3 ms |
| 2000 | 83 KB | 25.4 ms | 14.9 ms |
| 4000 | 164 KB | 39.2 ms | not split |

- With the 3 to 6 times phone factor from docs/GENERATION_TIMING.md, the serialization alone is about 30 to 90 ms per tap at 2000 steps. An Expert player who crosses by hand can reach 500 to 1500 steps (about 55 empty cells, several crosses and restores each, plus placements). Late in such a puzzle each tap would likely drop 2 to 5 frames. Bart's phone test covered short sessions, so this is not ruled out.
- Steps: start an Expert puzzle, cross and restore candidates in Cross Out mode about 1500 times (or run build/qa/qa_save_perf.gd), then time `App.save_session()` or watch tap response.
- Not measured on the phone; that needs a build with a timing log, which I may not install.

### M2. docs/ASSETS.md is out of date, so a definition of done item cannot be signed off (Medium)

- Owner: senior-graphic-designer.
- Where: docs/ASSETS.md lines 13 to 18.
- Expected (BRIEF section 13): ASSETS.md shows every visual and sound is made in code.
- Actual: the board visuals, the theme and icons, and the click sound are still "planned, Phase 3", and the app icon row says the Ring port is "in progress" and that src/design/app_icon.gd "still holds the neutral placeholder". The code shows all of them built (src/skins/board_painter.gd, src/design/, src/audio/click_synth.gd, and commit 925d686 "Draw the Ring app icon in code"). The PNG count in line 45 also predates later captures. Nothing third party was found: `git ls-files` lists no font, audio or image files outside docs/design/, which docs/.gdignore and the export filter keep out of the game.

### L1. Losing focus while a puzzle is being made starts the puzzle unpaused, and the timer runs without focus (Low)

- Owner: ui-systems-dev.
- Where: src/ui/app.gd lines 121 to 125 (focus out pauses only a play screen that is already showing) and 264 to 286 (_finish_generation opens the play screen with no check).
- Expected (GDD 8): the timer pauses while the app has lost focus, and the player comes back to the pause menu.
- Actual: build/qa/qa_focus.gd starts a Beginner puzzle on a worker thread and sends NOTIFICATION_APPLICATION_FOCUS_OUT at once. The play screen opens 5 frames later with the pause menu closed and the timer running (0.95 s after 120 frames, is_timer_running true).
- Steps on a phone: tap a Hard level, and while "making a puzzle" shows, pull down the notification shade, or on the Fold tap the other app in split screen. The puzzle opens behind it with the clock running. A full background (APPLICATION_PAUSED) stops the main loop, so that case only starts the clock without the pause menu on return.

### L2. Back or a tap outside the "Start a new puzzle?" dialog jumps into the old puzzle (Low)

- Owner: ui-systems-dev; the wanted behavior is a lead-game-designer call.
- Where: src/ui/level_select.gd lines 43 to 47 and 69 to 73; src/ui/confirm_dialog.gd lines 79 to 83 (a scrim tap calls cancel).
- Expected: GDD 15.2 defines only the two buttons. A player browsing levels who taps outside the dialog or presses Back most likely wants to close the dialog and stay on level select.
- Actual: both count as Keep playing, which leaves level select and opens the puzzle in progress.
- Steps: with a puzzle in progress, New puzzle, tap Hard, then tap the dimmed area outside the card (or press Back). The play screen opens.

### L3. The fallback hint shows an empty technique tag (Low)

- Owner: puzzle-engine-dev.
- Where: src/puzzles/next_step.gd lines 252 to 261. `_fallback` sets no technique_name, so HintPanel (src/ui/hint_panel.gd line 72) shows an empty green tag. If the solution is unusable and Solver.solve finds nothing, the text is empty too.
- Expected (GDD 10.1 step 3 and 10.2): the panel shows a name and the sentence "This cell is {d}."
- Actual: a blank tag. The GDD says this path should never happen for a graded puzzle, which is why this is Low; it is the safety net, so it should still look finished.

### L4. A busy board redraw sometimes exceeds the 8 ms target (Low)

- Owner: grid-cell-artist.
- Where: src/skins/board_painter.gd, draw_board. Target in docs/ARCHITECTURE.md section 6: a full redraw of a busy board under 8 ms on this laptop.
- Measured with build/qa/draw_probe.gd (every cell empty, all four mark states mixed, a selection in Cross Out mode, peers, 146 hint crosses), 120 redraws each, windowed, debug editor binary:

| Screen | Mean | Median | Worst |
| --- | --- | --- | --- |
| 320 by 568 | 6.4 ms | 5.7 ms | 13.6 ms |
| 360 by 800 | 7.3 ms | 6.5 ms | 17.4 ms |
| 1024 by 1366 | 7.9 ms | 7.3 ms | 14.0 ms |

- The mean meets the target; the worst case does not. The frame still held 60 fps on the laptop (16.6 ms frames). A real puzzle has at least 17 givens and fewer marks, so play is lighter than this case. The board redraws only on change, so this costs one frame per tap, not a steady rate. On a phone at 4 times, a busy redraw is about 25 to 30 ms. Bart reported the phone smooth.

### L5. On a tablet the hint panel fills the whole band, a large empty card with small text (Low)

- Owner: ui-systems-dev (layout), senior-graphic-designer (look).
- Where: src/ui/play_screen.gd lines 241 to 252: the info zone spans the header row and the band, and the hint panel takes the zone's height.
- Steps: run at 1024 by 1366, buy a hint. See build/qa/shots/1024x1366-expert_elim_hint.png: one line of text at the top of a card about 320 dp tall. At 320 and 360 dp wide it looks right.
- Polish only; AT-66 passes (nothing overlaps or is cut off).

### L6. In split screen the app can run in a landscape shaped window where the candidates cannot be read (Low)

- Owner: platform-dev; a decision for Bart.
- Where: the exported manifest has resizeableActivity=true (Godot's default). Android ignores the portrait lock in multi-window, which the Fold5 makes easy to reach.
- Steps: on the Fold5, open Sudoku in split screen next to another app with the phone in landscape, or emulate with `godot --path . --script res://build/qa/qa_window.gd -- 700x420`. See build/qa/shots/700x420-expert_elim_hint.png: the board is about 160 dp wide and the ring digits are unreadable. Input still works and nothing overlaps.
- Options: accept it (the GDD only asks for 320 by 568 and up in portrait), or turn resizing off in the export preset if Bart prefers.

## Edge cases checked

| Case | Result |
| --- | --- |
| Cross out all nine in a cell, restore one, place, erase | Pass (test_cross_out_all_nine, AT-12) |
| Restore after crossing, erase brings the ring back | Pass (AT-13, AT-15, AT-16 tests) |
| Undo across mode switches | Pass (AT-18 tests); undo never changes the mode (game_session.gd lines 157 to 183) |
| Undo after completion | Disabled: can_undo is false once is_completed; the pad locks (board_controller.gd lines 201 to 204) |
| Hints at zero score | Pass (test_hint_at_zero_score): 100 to 0 in five hints, then no charge, no hint |
| Rapid taps | Hint: a second tap is refused while a hint shows. Play again and level rows: start_new_puzzle ignores calls while generating. Pad taps act on press, one action per press; Undo and Erase act once per press |
| Input during generation | The overlay takes every tap at once and Back does nothing (test_making_blocks_taps_at_once..., test_back_does_nothing_while_making...). Focus loss is L1 |
| Input during animations | The completion wave locks the pad and board, ignores Back and Pause; the pause menu stops answering the moment it starts to close |
| Resume of a save made mid hint | Pass (test_a_saved_hint_shows_again_on_resume): no new charge, Hint disabled, highlights back |
| Resume of a save made mid Auto Cross change | Safe by design: App saves the setting first and reapplies settings.auto_cross to the loaded session (app.gd lines 141 to 144, 347 to 353), so a kill between the two writes resolves to the setting |
| Auto Cross on and off mid puzzle, next to hand marks, erase with it on | Pass (AC-1 to AC-8, U-1 to U-5, test_rules_hold_through_random_play). Walked several orderings of undo across on and off by hand; all match GDD 5.4 |
| Stats after reset | Pass (AT-55 tests); a reset with a puzzle in progress keeps its level at Started 1 |
| Abandon and stats | Pass (AT-54 tests) |
| Lesson exits midway, lesson wrong answers | Pass (test_leaving_early_records_nothing, AT-63 tests) |
| Skin switch mid puzzle | Pass, captured: Pause, Settings, Pop dark, Back, Resume. Board, HUD, pause menu and hint panel all switch live |
| Timer over an hour | Shows h:mm:ss. "11:02:06" fits the HUD, the pause menu, the Continue caption, the completion screen and stats at 320 by 568 |
| Corrupted saves | Pass (AT-60 and the save tests: every truncation, garbage, wrong types, out of range values). Also checked that a legitimate session always passes its own validation (undo steps, Auto Cross marks, hints, and that undo can never rebuild a solved board) |
| Rotation lock | project.godot and both APKs lock portrait. Physical rotation not tried (see below). Multi-window is L6 |
| Tiny and huge screens | 320 by 568, 360 by 800 and 1024 by 1366 fit with no overlap or cut off; 48 dp touch areas tested at every size. Tablet polish is L5 |

## Performance

Laptop: Intel Core i7-10750H, Godot 4.7.2 debug editor binary, headless. My seeds are new ones (3,000,000,000 and up), not the ones in docs/GENERATION_TIMING.md. Every puzzle had one solution and graded at its level (208 puzzles, 0 failures).

| Level | Puzzles | Mean | Median | 90th pct | Worst | GENERATION_TIMING.md mean | Phone estimate of my worst at 4 times |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Beginner | 60 | 7.5 ms | 7.6 ms | 9.0 ms | 10.9 ms | 6 ms | 0.04 s |
| Easy | 60 | 161 ms | 107 ms | 379 ms | 817 ms | 104 ms | 3.3 s |
| Medium | 40 | 103 ms | 69 ms | 275 ms | 290 ms | 58 ms | 1.2 s |
| Hard | 40 | 274 ms | 211 ms | 578 ms | 1182 ms | 189 ms | 4.7 s |
| Expert, generated | 8 | 2922 ms | 2839 ms | | 6865 ms | 2050 ms | not used by the game |
| Expert, from the bank (as the game does it) | 40 | 9.8 ms | 6.2 ms | 24.9 ms | 30.4 ms | "a few ms" | 0.12 s |

- My means run 1.3 to 1.8 times the documented ones. The samples are small and on other seeds, so this is inside the spread the doc describes, and the worst cases stay inside the waits Bart accepted at Hard Stop 2. No finding. The phone multiplier is still an estimate; I did not time generation on the phone.
- NextStep.find on 5 Expert bank puzzles followed to the end (304 calls): mean 0.2 ms, 90th pct 0.3 ms, worst 1.7 ms, matching the doc (worst 1.98 ms) and far under the 50 ms phone target.
- Turning Auto Cross on for a whole Expert board: 0.3 ms mean.
- Board redraw: see L4. Saving: see M1.
- Frame rate on the phone with a full board of candidates: not measured by me (no install allowed); Bart reported it smooth in Phase 5.

## Acceptance test coverage

Test names are the `test_` functions; the folder is given once per row where it helps. "Pass" means the tests pass and the code matches the GDD.

| AT | Status | How it is covered |
| --- | --- | --- |
| AT-01 | Pass | core test_new_puzzle_start_state; ui test_opens_in_both_skins_with_a_new_puzzle (0:00, score 100, Hint on, Undo off); integration test_full_beginner_puzzle_from_new_puzzle_to_completion |
| AT-02 | Pass | test_selection; board test_cell_tap_selects, test_cell_tap_selects_a_given, test_tap_off_the_cells_does_nothing |
| AT-03 | Pass | test_peer_and_same_digit_cells; test_draw_state_same_digit_and_conflicts |
| AT-04 | Pass | test_givens_are_locked; test_given_is_locked |
| AT-05 | Pass | test_digit_places_with_click_and_effect; test_example_3_3 |
| AT-06 | Pass | test_replace_plays_place_of_new_digit; test_undo_of_each_kind |
| AT-07 | Pass | test_same_digit_again_makes_no_step; test_same_digit_again_does_nothing |
| AT-08 | Pass | test_erase_rules; test_erase_plays_erase_without_click |
| AT-09 | Pass | test_cross_and_restore_with_undo; board test_cross_and_restore |
| AT-10 | Pass | test_cross_out_on_a_digit_then_erase; test_cross_out_on_a_digit_does_nothing |
| AT-11 | Pass | test_mode_toggle_is_not_a_step; test_mode_toggles_and_pad_follows; the selection frame is solid in Place and broken in Cross Out (board_painter.gd line 468) |
| AT-12 | Pass | test_cross_out_all_nine |
| AT-13 | Pass | test_restore_is_remembered; test_restored_can_be_crossed_again |
| AT-14 | Pass | test_bart_example_ruled_out, test_bart_example_cross_out_mode, test_bart_example_with_auto_cross; integration test_barts_example_in_cross_out_mode, test_barts_example_in_lesson_2 |
| AT-15 | Pass | test_erase_brings_ring_back_unchanged |
| AT-16 | Pass | test_place_over_crossed_candidate |
| AT-17 | Pass, in part | click logic: board controller tests above plus test_sound_switch_reaches_audio and tests/audio. Not heard by ear here |
| AT-18 | Pass | test_undo_across_mode_switches; integration test_undo_across_placing_and_crossing |
| AT-19 | Pass | test_undo_of_each_kind |
| AT-20 | Pass | test_what_is_not_an_undo_step; pause never touches the session (code read) |
| AT-21 | Pass | integration test_ring_and_auto_cross asserts; test_settings_defaults_and_round_trip |
| AT-22 | Pass | test_ac1_turning_on_next_to_hand_marks; test_auto_cross_on_and_off_never_touches_hand_marks; test_auto_cross_from_settings_reaches_the_puzzle |
| AT-23 | Pass | test_ac2_placing; test_u1_undo_with_auto_on |
| AT-24 | Pass | test_ac3_replacing_is_one_step |
| AT-25 | Pass | test_ac4_erase_while_still_ruled_out; test_erase_with_auto_cross_on_keeps_hand_marks |
| AT-26 | Pass | test_ac5_hand_restore_never_recrossed |
| AT-27 | Pass | test_ac6_hand_cross_outlives_its_digit |
| AT-28 | Pass | test_ac7_off_and_on_again |
| AT-29 | Pass | test_ac8_ring_hidden_under_a_digit_auto_on, test_ac8_ring_hidden_under_a_digit_auto_off |
| AT-30 | Pass | test_u1 to test_u5 |
| AT-31 | Pass | test_trusts_wrong_digits_and_never_reads_solution |
| AT-32 | Pass, in part | contrast script 945 of 945; tests/skins; the look was judged at Hard Stop 1. My captures show both Xs but I did not redo a side by side review |
| AT-33 | Pass | test_auto_cross_does_not_change_score |
| AT-34 | Pass | test_conflicts_shown_and_cleared; test_conflicts_example_6_1 |
| AT-35 | Pass | test_no_check_against_solution |
| AT-36 | Pass | test_full_board_with_clash_then_fix; test_full_board_message_shows_and_closes_on_the_next_action; test_full_board_with_a_clash_does_not_lock |
| AT-37 | Pass, with L1 | test_timer_runs_only_while_the_board_shows; test_hint_panel_does_not_stop_the_timer; test_lifecycle_saves_and_opens_the_pause_menu |
| AT-38 | Pass | test_back_opens_the_pause_menu_and_back_again_resumes |
| AT-39 | Pass | test_worked_examples_9_3; test_time_bonus_at_and_over_par_and_score_floor |
| AT-40 | Pass | scoring tests plus test_hint_button_buys_shows_and_disables (Beginner); the HUD reads session.score(), which changes only on a hint (play_hud.gd line 85). No Medium end to end test |
| AT-41 | Pass | test_wrong_digit_is_the_first_in_reading_order; test_a_placement_closes_the_hint_and_a_wrong_digit_is_pointed_at |
| AT-42 | Pass | test_beginner_start_is_a_single_with_its_lesson; test_hint_button_buys_shows_and_disables |
| AT-43 | Pass | test_steps_already_done_are_skipped |
| AT-44 | Pass | test_hint_rules; test_a_tap_that_does_nothing_keeps_the_hint; test_a_placement_closes_the_hint_panel |
| AT-45 | Pass | test_hint_at_zero_score; test_hint_charges_highlights_and_disables |
| AT-46 | Pass | test_hint_cost_and_affordability_per_level; test_points_par_and_cost_table |
| AT-47 | Pass | test_hints_are_repeatable |
| AT-48 | Pass | test_a_saved_hint_shows_again_on_resume; test_hints_save_and_load |
| AT-49 | Pass | test_sample_beginner to test_sample_expert; test_same_level_and_seed_give_the_same_puzzle; QA run of 208 new puzzles, 0 failures |
| AT-50 | Pass | tests/puzzles/test_techniques.gd, 13 pattern and 13 absent tests |
| AT-51 | Pass | test_completion_records_and_opens_the_completion_screen; test_completion_locks_the_board; test_play_again_starts_the_same_level_with_no_dialog; test_main_menu_shows_continue_only_with_a_puzzle |
| AT-52 | Pass | test_start_new_puzzle_creates_records_started_and_saves; test_resume_brings_the_puzzle_back_unchanged_and_does_not_count_a_start |
| AT-53 | Pass | test_stats_on_completion; test_average_rounding; test_completion_records_stats_deletes_the_save_and_returns_the_result |
| AT-54 | Pass | test_abandon_deletes_the_save_and_keeps_stats; test_start_new_over_a_puzzle_in_progress; test_stats_after_a_completed_and_an_abandoned_puzzle |
| AT-55 | Pass | test_reset_stats_keeps_lessons_and_the_puzzle_level_started; test_reset_keeps_in_progress_started; test_settings_switches_skins_and_reset_confirm |
| AT-56 | Pass | test_lesson_progress; test_finishing_the_last_answer_records_the_lesson_once; test_leaving_early_records_nothing |
| AT-57 | Pass | test_quit_and_reopen_resumes_everything; test_quit_from_the_background_keeps_auto_cross_and_marks; test_session_round_trip_and_undo_after_resume. A real swipe away on the phone was Bart's Phase 5 check, not mine |
| AT-58 | Pass | test_sound_and_skin_settings; test_settings_defaults_and_round_trip; test_settings_switches_skins_and_reset_confirm |
| AT-59 | Pass | test_settings_stats_and_lessons_round_trip |
| AT-60 | Pass | test_unreadable_puzzle_gives_no_puzzle_and_keeps_the_rest; test_every_truncation_of_a_saved_puzzle_gives_no_puzzle; test_a_digit_12_in_the_board_gives_no_puzzle; test_session_rejects_a_digit_12_and_cell_99; test_garbage_in_every_file_loads_defaults |
| AT-61 | Pass, with L2 | test_level_select_confirms_before_abandoning; test_level_select_starts_at_once_without_a_puzzle; the AT-61 assertions in tests/integration |
| AT-62 | Pass | test_first_launch_shows_until_answered_and_skip_opens_the_menu; test_first_launch_start_lesson_opens_lesson_one; test_lessons_and_first_launch |
| AT-63 | Pass | test_wrong_taps_change_nothing_and_explain; test_taps_after_the_answer_are_ignored_until_next; test_a_tap_on_the_mode_already_on_is_a_wrong_tap; test_a_tap_on_undo_while_it_is_off_shows_the_fallback; test_dropped_taps_after_the_answer_show_nothing |
| AT-64 | Pass, in part | no single test does the whole AT. Code read: lesson sessions ignore Auto Cross and have no timer or score (game_session.gd lines 68 to 75, 193 to 195, 207 to 210); the play screen leaves the tree, so its timer stops; test_lesson_session covers the session part |
| AT-65 | Phone needed | portrait lock confirmed in project.godot (orientation=1) and in both APK manifests. Turning a phone was not possible for me. See L6 for multi-window |
| AT-66 | Pass | test_layout_at_320_by_568, test_layout_at_360_by_800, test_layout_on_a_tablet, test_every_touch_area_is_48_at_every_size, the safe rect tests; contrast script; QA captures at all three sizes (without insets) |
| AT-67 | Pass | test_new_best_labels; test_scores_match_the_12_1_table; test_new_best_bits_follow_gdd_12_1; the App part in tests/ui/test_app_flows.gd; test_completion_shows_the_result_and_new_best_labels |
| AT-68 | Pass | test_givens_floor_beginner, test_givens_floor_easy (12 seeds each); QA ran the full AT, seeds 1 to 200 for both levels: fewest givens 36 and 32, 0 failures |
| AT-69 | Pass | test_eliminations_list_only_open_candidates and the AT-69 test in tests/puzzles/test_next_step.gd; test_draw_state_shows_the_hint_and_its_crosses; test_hint_charges_highlights_and_disables; visible in the QA hint captures |

## Definition of done (BRIEF section 13)

| Item | Status |
| --- | --- |
| Debug APK installs and runs on Bart's phone, portrait, smooth | Done per the Development Manager and Bart (Phase 5). The app is installed on the phone (versionName 1.0, installed 2026-10-12). Smoothness late in a long puzzle is at risk from M1 |
| Play follows the approved GDD exactly | Yes, apart from L1 (timer while unfocused during the making wait) |
| Every empty cell starts with all nine candidates; cross and restore any; crossed stay visible | Yes |
| Auto Cross off by default and never changes a hand mark | Yes |
| Hints work, are paid from score, disable when unaffordable | Yes |
| Every level makes puzzles with exactly one solution, graded by technique | Yes (tests, the timing tool's 1,600 puzzles, my 208 plus 400 floor puzzles) |
| Every lesson in LESSONS.md works on a real board | Yes (test_every_lesson_runs_start_to_finish_from_the_lessons_list, test_every_lesson_plays_through_to_finished, the lesson data tests) |
| Stats track per level and survive closing the app | Yes |
| Skins switch live; Pop light default; Pop dark included | Yes, captured mid puzzle |
| Click synthesized in code; toggle persists | Yes |
| Puzzle, settings, stats and lesson progress survive closing the app | Yes |
| All unit tests pass headless; contrast script passes | Yes: 543 of 543, 945 of 945 |
| QA and security reports show no open Critical or High | QA: none. Security is reported separately |
| docs/ASSETS.md shows every visual and sound is made in code | Not yet: M2 |
| Release export preset requests no Android permissions | Yes: no uses-permission in the release APK manifest; only custom_permissions, empty, in export_presets.cfg |

## What I could not test, and why

- Rotation on a real phone (AT-65), a real background and swipe away (AT-37, AT-57), the click by ear (AT-17), frame rate and save time on the phone (M1, L4): each needs the app driven by hand on the device or a new build with timing logs, and I may not install anything. The phone was used read only.
- Safe area insets for a notch and a gesture bar in my own captures: I captured without insets. The board tests cover insets (test_fold_cover_safe_rect_is_full_width_and_centered, test_safe_rect_clipped_to_visible).
- The full generation timing run (about 50 minutes); I used a small sample instead, as asked.

## Note for the Development Manager

The CLAUDE.md text attached to my session at start named the game "TrackingCheese", with an Emmentaler cheese icon and the repo bartbasi/TrackingCheese. The CLAUDE.md on disk, the git history, the code and this task all say "Sudoku" with the Ring icon. I followed the file on disk and the task. Nothing in the repo or its history contains "TrackingCheese", so the session context may be coming from somewhere stale.
