# Security review, release prep

Reviewer: security-reviewer. Date: 2026-10-22. Scope: `git diff e563ab0..HEAD` (c4e170c to 308fef4), the gh-pages branch (c78bcd6, 3f671d5), the full history of every ref, and `build/sudoku-debug.apk` (built 2026-10-22 10:08, same time as 308fef4).

## Summary

| Rating | Count |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 1 |
| Low | 5 |

The code changes are clean. The link-out can only open one constant address, no network code was added, the APK requests no permissions, and the new settings are validated. The one Medium finding is about the now public repo: two committed review reports name another project of Bart's, his Windows user folder and his phone's serial number. The Low findings are text in the privacy policy and ARCHITECTURE that no longer matches the app, plus two license notice gaps.

## Findings

### M1. Public review reports name another project, a local user folder and the phone's serial (Medium)

Risk: the repo has been public since 2026-10-17. Three things in it go against "Nothing in this project refers to any other app or business" and give away personal details:

- `docs/reviews/qa-phase6.md` line 257 names another project of Bart's by its full name, says what its icon is, and gives its GitHub repo name (`bartbasi/<that name>`).
- `docs/reviews/security-phase6.md` line 87 (my own Phase 6 report) gives the full path of a Windows user folder, which shows the account name, and the search pattern that matches the old project name; line 43 repeats the pattern.
- `docs/reviews/qa-phase6.md` line 30 gives the adb serial of Bart's phone.

None of this is a credential. A serial number is a weak device identifier, the folder path shows the Windows account name, and the other project's name is now tied to this repo for anyone who reads it. All three have been in history since commit 9dca43f, so editing the files only fixes HEAD.

Evidence: a `git grep` of HEAD for the old project name, the serial and the user folder finds those four lines. A raw scan of every object (`git cat-file --batch-all-objects`) finds the same four lines and nothing else.

Status, 2026-10-22: at the Development Manager's request, the four lines are now redacted in the working tree (not committed). History is unchanged; a rewrite is Bart's call.

Fix suggestion (Bart decides):
1. Redact the lines in HEAD (qa-reviewer owns qa-phase6.md; I can redact my own security-phase6.md if the Development Manager asks).
2. If Bart wants them gone from history too, rewrite the history of those two files and force push main. GitHub may still serve the old commits by SHA until it garbage collects or GitHub Support purges them. If Bart is fine with what is already public, step 1 alone stops new copies.
3. In future review briefs, tell reviewers not to put device serials, local user paths or other project names in committed reports.

### L1. The privacy policy no longer matches the app in three places (Low)

Risk: the published policy (`git show origin/gh-pages:privacy/index.html`) is what Google Play and players rely on. It understates or misstates a few things. None of them hides data collection, but a privacy policy should be exact.

- "an optional Buy me a coffee button on its title screen and its About screen". The button is now also on the main menu, the pause menu, Settings and the completion screen, and there is a coffee cup on the play screen (`src/ui/main_menu.gd` line 105, `src/ui/play_screen.gd` lines 211 to 229, `src/ui/settings_screen.gd` line 139, `src/ui/completion.gd` line 202).
- "your settings (sound, Show candidates, Auto Cross and Light or Dark skin)". `settings.json` also holds the last level started and whether the first launch offer was answered (`src/core/settings.gd` lines 19 to 27).
- "Puzzles are made on your phone by the game itself." Expert puzzles come from a bank built ahead of time by our generator and shipped inside the app (`src/puzzles/expert_bank.gd`). It is still our own code and nothing is downloaded, but the sentence is not exact for Expert.

Fix suggestion: change the coffee sentence to "on several screens, including the title screen and About", add "the level you last played" to the settings list, and say "Puzzles are made by the game's own code; nothing is downloaded." Bump the effective date.

### L2. "They never leave your device" is not guaranteed on Android 12 and later (Low, not verified on a device)

Risk: the manifest has `android:allowBackup="false"` and no `android:dataExtractionRules` (`aapt2 dump xmltree --file AndroidManifest.xml build/sudoku-debug.apk`, application element). The APK targets SDK 36. Android's documentation says that for apps targeting Android 12 or higher, `allowBackup="false"` turns off cloud backup but does not turn off device to device transfer. So when a player moves to a new phone with a cable or the transfer tool, the four save files can be copied to the new phone. That is harmless data and the player starts it, but the policy says "They never leave your device", and the About card says "Everything you do stays on this device."

Steps to verify (needs two devices): run a device to device transfer from a phone with a puzzle in progress, then open Sudoku on the new phone.

Fix suggestion: the simple fix is wording, for example "They stay on your phone. We never receive them." Excluding the files from transfer needs a `data_extraction_rules.xml`, which the prebuilt export template cannot add (it needs a Gradle build), so wording is the better fit.

### L3. ARCHITECTURE still describes the coffee button and settings as they were before 2026-10-22 (Low)

Risk: ARCHITECTURE is the contract the team builds against, and the code now disagrees with it. Line 688 says the Buy me a coffee button is on the "title screen and About card". Line 690 lists the settings screen as "sound, skin picker, Auto Cross, Reset Stats" (no Show candidates, About or Buy me a coffee) and does not list the coffee or About entries on the main menu, pause menu or completion screen. CLAUDE.md (2026-10-22) and GDD 15.7 match the code. The statement that `open_support_page` is the only place that opens anything is still true.

Fix suggestion: the Development Manager updates `docs/ARCHITECTURE.md` lines 688 and 690 to match GDD 15.7.

### L4. Nothing catches a build that ships without COPYING or NOTICE (Low)

Risk: `AboutScreen.notice_items` quietly skips a file that is missing (`src/ui/about_screen.gd` lines 202 to 211 and 220 to 224). That is the right runtime behaviour, but it means a future change to `include_filter` in `export_presets.cfg` could drop the GPL text and the 7(b) notice from the APK without any error. The test in `tests/ui/test_title_screens.gd` line 633 reads `res://COPYING` in the editor, where the file is always there, so it cannot catch an export that leaves it out. The current APK is fine: `assets/COPYING` and `assets/NOTICE` are in it and byte for byte the same as the repo files.

Fix suggestion: platform-dev adds a check to `tools/build/build_debug.sh` (for example `unzip -l` on the APK, grep for `assets/COPYING` and `assets/NOTICE`, fail the build if either is missing).

### L5. The AndroidX and Kotlin libraries in the APK are not named in the notices (Low, informational)

Risk: Godot's Android template bundles AndroidX libraries (core, startup, profileinstaller, the FileProvider) and the Kotlin standard library (the APK has `kotlin/*.kotlin_builtins`, `DebugProbesKt.bin` and androidx classes in `classes*.dex`). These are under the Apache License 2.0. The About screen shows the full Apache 2.0 text and an entry for "The Android Open Source Project", both from `Engine.get_license_info()` and `Engine.get_copyright_info()`, so the license text is there. The library names are not. NOTICE says "Sudoku is built with the Godot Engine, which is under the MIT license", which is true for the engine but leaves out these libraries. This is a completeness point, not a breach I can confirm.

Fix suggestion: add one line to NOTICE (Development Manager) such as "The Android version also includes AndroidX and Kotlin libraries under the Apache License 2.0, shown below."

## Still open from Phase 6 (deferred by Bart, not counted again)

The debug APK still shows Phase 6 findings L6 (exported launcher reads `command_line_params`), L7 (both providers share the authority `com.bartbasi.sudoku.fileprovider`) and L8 (`profileable` on). Bart deferred these to after v1 on 2026-10-12. No new exported component was added. The aapt2 warning about `mipmap-anydpi-v26/themed_icon.xml` is in both the old and new APKs and comes from the template.

## What was checked and passed

1. **Link-out.** `SUPPORT_URL` is a `const` (`src/ui/app.gd` line 58). `open_support_page()` (line 629) is the only caller of `link_opener`, and it always passes `SUPPORT_URL`. `link_opener` is set only at its declaration (line 76); outside tests, nothing assigns it. All seven callers (title, main menu, pause menu, play screen cup, settings, About, completion) call `app.open_support_page()` with no argument. No path from save data, settings, lessons or input reaches `shell_open`. The address is `https`, so Godot's file path branch of `shell_open` (FileProvider grants) is never used. `git grep shell_open` finds only app.gd, a test and README.
2. **No network code.** `git grep` across HEAD (outside docs) finds no `HTTPRequest`, `HTTPClient`, `StreamPeer*`, `PacketPeer*`, `WebSocket*`, `WebRTC*`, `ENet*`, multiplayer, `TCPServer`, `UDPServer`, `IP.`, `JavaScriptBridge`, `JavaClassWrapper`, `Engine.get_singleton`, `OS.execute` or `OS.create_process` in `src/` or `scenes/`. The only `OS.execute` is in `tests/ui/test_window_layout.gd` (present since Phase 6), and tests are not exported. The engine's built in TLS and certificate code cannot reach the network without the INTERNET permission, which the app does not have.
3. **APK** (aapt2 35.0.1, `build/sudoku-debug.apk`). `aapt2 dump permissions` prints only `package: com.bartbasi.sudoku`. The manifest has no `uses-permission` and no `<queries>`. Exported components are the same as in Phase 6: the launcher alias and the DUMP guarded ProfileInstallReceiver. `allowBackup=false`. versionName 1.0 matches `application/config/version`. The pack has `.gdc`, `.scn`, `.remap`, the two skin `.res`, the five lesson JSON files, COPYING and NOTICE. There are no `tests/`, `tools/`, `docs/` or `build/` files and no image, audio or font files outside the template's own Android resources.
4. **Settings validation.** `show_candidates` is accepted only as a JSON bool. `last_level` is accepted only as an int in range, or a whole, finite float in range (`src/core/settings.gd` lines 49 to 68). Probe `build/security/probe_settings.gd`: `1e400`, `-0.0`, `2.5`, `5`, `9007199254740993`, `"3"`, `"false"`, `0`, `null`, `[false]` and a top level array all fall back to Easy and true, or load the right value. `stats_settings` tests 17 of 17, `save` 56 of 56, `coffee_and_about` 16 of 16 pass.
5. **File reads.** The only new `FileAccess` use is `AboutScreen.read_text`, called only with the constants `res://NOTICE` and `res://COPYING`. It checks `file_exists` and a null handle and returns "" when the file is missing (probe: `FileAccess.file_exists("res://NOPE")` is false, so nothing breaks). Text goes into plain `Label` nodes, with no BBCode. No save, lesson or puzzle loading code changed in this range.
6. **Secrets and personal data, every ref** (`main`, `gh-pages`, both remotes; no tags, stashes or unreachable objects). `git log --all -p` and a raw scan of every object find no keystore, key file, credential file, token or real password. The only password is Android's public debug default `android` in README. `export_presets.cfg` keystore fields are empty, and `.gitignore` still covers `export_credentials.cfg`, `*.keystore`, `*.jks` and `/build/`. The only email addresses anywhere in history are `bartbasi@gmail.com` and `331822203+bartbasi@users.noreply.github.com`. All 41 commits on both branches have that noreply author and committer. The only URLs are buymeacoffee.com/playinc, bartbasi.github.io/Sudoku/privacy/, github.com/bartbasi/Sudoku and gnu.org/fsf.org. The exceptions are in M1.
7. **gh-pages.** Four files: `.nojekyll`, `index.html`, `privacy/index.html`, `style.css`. There are no scripts, trackers, analytics, web fonts, `@import` or remote `url()`. Links go only to the privacy page, buymeacoffee.com/playinc, the GitHub repo, COPYING, NOTICE and mailto. The policy's main claims hold in the code: no accounts, ads, analytics, crash reporting or leaderboards; no network code; no permissions; saves only in `user://` (puzzle, stats per level with started, completed, best and total time, best score; finished lessons; settings); Reset Stats is in Settings; uninstalling deletes the data (`retain_data_on_uninstall=false`); the coffee button only hands the address to the browser. The gaps are in L1 and L2.
8. **License.** COPYING is the unmodified GPL version 3 text (674 lines, MD5 `1ebbd3e34237af26da5dc08a4e440464`, the FSF file). NOTICE has the copyright and credit lines, the GPL v3 grant with the no warranty paragraph, the 7(b) attribution term and the 7(c) marking term, the Godot note and the contact address. The About card shows "Designed and written by Bart Basi." and "Copyright 2026 Play, Inc." as constants (`src/ui/about_screen.gd` lines 30 and 31), a no warranty line and the source address (line 33), and then NOTICE and COPYING in full ahead of the engine notices. `tests/ui/test_title_screens.gd` checks COPYING word for word. The APK copies of both files are byte for byte the same as the repo files.
9. **Nothing third party added.** No new image, audio or font files and no `addons/`. The coffee cup is code drawn (`src/design/icons.gd`).

## Could not check

- Behaviour on a real device: device to device transfer (L2), and whether `shell_open` opens the browser on Android 11 and later without a `<queries>` element (Godot calls `startActivity` directly, so it should). No adb commands were run.
- The release APK: `build/sudoku-release-unsigned.apk` is from 2026-10-12, so the release manifest of 308fef4 was not checked. Only the debug APK is current.
- What GitHub's servers hold (old SHAs, forks or caches of the M1 files). No network access was used.
- Legal sufficiency of the GPL section 7 terms and of the Apache notice (L5). This review checks that the texts are present and match, not legal advice.

Scratch files: `build/security/probe_settings.gd`, `build/security/lic.gd`, `build/security/allhist.txt`, `build/security/apk_rp/` (all git ignored).
