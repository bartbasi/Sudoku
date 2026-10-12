# Security review, Phase 6

Reviewer: security-reviewer. Date: 2026-10-12. Commit reviewed: `05c8eb4` (main, clean tree).
APKs reviewed: `build/sudoku-debug.apk` (13:50) and `build/sudoku-release-unsigned.apk` (13:10, built before the last commit; no security relevant change in between).

## Summary

| Rating | Count |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 11 |

No Critical, High or Medium findings. The save system, data loading, Android manifest, secrets, network and third party checks all pass. The Low findings are robustness gaps against a tampered or extreme save file, Godot template details in the manifest, and stale text outside the code.

## What was checked and passed

1. **Save system** (`src/save/save_store.gd`, `src/ui/app.gd` lines 136 to 193, every `from_dict` in `src/core/`).
   - Files are read only with `FileAccess` and parsed only with the `JSON` class. No `str_to_var`, `bytes_to_var`, `ResourceLoader` or `load()` touches save data (repo wide `git grep`).
   - `SaveStore.read` rejects missing, empty, oversized (16 MiB puzzle, 256 KiB others), NUL containing and non JSON files, and anything that is not exactly `{"format": 1, "data": {...}}`.
   - `is_allowed_path` allows only `user://...json` with no `..`, backslash, colon or leading slash. All four paths are built from constants.
   - Writes go to `path.tmp`, are closed, then renamed over the old file. A failed write deletes the temp file and keeps the old one.
   - `Settings`, `Stats`, `LessonProgress`, `GameSession`, `Board`, `UndoStep` and `Hint` check type, range, length and allowed values for every field, with defaults or "no puzzle" as the fallback. Numbers go through `DataCheck` (finite, whole, within 2^53).
   - A finished puzzle cannot come back: `save_session` never writes a completed session (app.gd line 172), `GameSession.from_dict` rejects a solved board (game_session.gd line 324), and `load_session_file` rejects a completed one and an id whose level does not match (app.gd lines 156 to 160).
   - Probe (`build/security/probe_save.gd`): `1e400`, `NaN`, a BOM, duplicate keys, `-0`, a hint text holding BBCode all load safely (rejected, or shown as plain text in a `Label`). No crash.
   - `tests/save` (34 tests) and `test_save_data` (12 tests) pass.
2. **Data loading.**
   - Lesson files (`src/lessons/lesson_library.gd`): `res://` only, 256 KiB cap, JSON class only, unknown keys rejected, every field typed and bounded (screens, steps, wrong rules, text lengths, cells, digits), board and solution cross checked. Nothing can create an object.
   - The Expert bank (`src/puzzles/expert_bank.gd`) is a code constant of 1000 lines, not a data file. `PuzzleSource.givens_from_line` accepts only 81 ASCII digits with exactly one solution and falls back to generating.
   - The only `load()` calls use constant `res://` paths or skin ids filtered through `Settings.SKIN_IDS`. The skin `.tres` files reference only `res://src/skins/game_skin.gd`.
   - Hint and lesson text is shown in plain `Label` nodes. No `RichTextLabel` or BBCode anywhere.
3. **Android** (aapt2 35.0.1 on both APKs).
   - `aapt2 dump permissions` prints only `package: com.bartbasi.sudoku` for both: zero `uses-permission`.
   - `android:allowBackup=false` (preset `user_data_backup/allow=false`).
   - `android:debuggable=true` only in the debug APK; the release manifest has none. The two manifests differ only in that attribute and line numbers.
   - Exported components: the launcher alias `GodotAppLauncher` (needed) and androidx `ProfileInstallReceiver` (guarded by `android.permission.DUMP`). `GodotApp`, `ProcessPhoenix` and both providers are not exported.
   - The pack holds only `.gdc`, `.scn`, the two skin `.res`, the five lesson JSON files, `project.binary` and Godot's caches. No `tests/`, `tools/`, `docs/`, `build/`, images, audio or fonts.
   - Debug APK is signed with the standard Android debug certificate (CN=Android Debug). Release APK is unsigned.
4. **Secrets.** `git log --all -p` and a scan of every git object find no keystore, key file, credential file or real password. The only password in history is the public Android debug default `android`, in README instructions. `export_presets.cfg` has every keystore field empty. `.gitignore` covers `export_credentials.cfg`, `.godot/`, `*.keystore`, `*.jks`, `/build/`. The debug keystore is at `%APPDATA%\Godot\keystores\debug.keystore`, set in Godot's editor settings, outside the repo. No key files in the working tree.
5. **No network code.** No `HTTPRequest`, `HTTPClient`, `StreamPeer*`, `PacketPeer*`, `WebSocket*`, `WebRTC*`, `ENet*`, multiplayer, `TCPServer`, `UDPServer`, `OS.shell_open`, `OS.execute`, `OS.create_process`, `JavaClassWrapper` or URLs in `src/`, `scenes/`, `tests/` or `tools/`.
6. **Nothing third party.** No `addons/`. No image, audio or font file anywhere in history except the 58 review captures in `docs/design/` (Godot ignores `docs/` via `.gdignore`). Inter fonts exist only in `build/font_compare/` (git ignored, `.gdignore`d). The APK pack contains no media file.
7. **Old names.** A case insensitive search for `cheese|cracker` over every commit message, author, committer, every blob reachable from any ref, the reflog, and every object in the object store (`git cat-file --batch-all-objects`) finds nothing. `git fsck --unreachable` finds no stray objects. Both APKs are clean too. Every commit uses `Bart Basi <331822203+bartbasi@users.noreply.github.com>`.

## Findings

### L1. A huge puzzle save stalls the game at every launch (Low)

Risk: `puzzle.json` may be up to 16 MiB, and nothing caps the number of undo steps inside it. A file packed with the smallest valid steps loads, slowly, on the main thread, and then every tap rewrites all of it. On a phone this is likely an "app not responding" dialog at each start, or running out of memory, until the app data is cleared. Writing that file needs access to the app's private storage (root, or `run-as` on the debuggable build), so only the device owner can do it.

Steps: `timeout 300 godot --headless --path . --script res://build/security/probe_save.gd`. A 16,774,376 byte file with 441,400 alternating cross and restore steps on one cell: `SaveStore.read` 1,455 ms, `GameSession.from_dict` 7,199 ms, one `SaveStore.write` of the loaded session 4,273 ms (desktop). Code: `src/save/save_store.gd` line 17, `src/core/game_session.gd` lines 497 to 520.

### L2. Saving cost grows with the undo history, and an over-limit save is lost (Low)

Risk: `App.save_session` runs on every `board_changed` and rewrites the whole history synchronously (`src/ui/app.gd` lines 171 to 174, 309 to 318). At 20,000 steps one save took 187 ms on the desktop (`build/security/probe_20k.gd`), more on a phone, on every tap. Separately, `SaveStore.write` (`src/save/save_store.gd` lines 62 to 84) does not check `MAX_BYTES_PUZZLE`, but `read` does. A history that grows past 16 MiB (roughly 50,000 Auto Cross place and erase steps) is written without error and then rejected at the next launch, so the puzzle in progress silently disappears. Both need extreme play, so the risk is small.

### L3. Undo marks and givens are range checked but not cross checked (Low)

Risk: `GameSession.from_dict` checks that each undo step's mark change is a legal transition, but not that its "before" value matches the board as the history is replayed, and it does not check that the givens have one solution or match the puzzle id. A hand edited save loads: a step `[i, 2, 1]` on a cell whose mark is OPEN, or a board with no givens at all, are both accepted (probe items 3 and 4). Undo then writes those marks. There is no crash, and with no leaderboards the only effect is on the editor's own stats, which `stats.json` already allows. ARCHITECTURE section 12 asks only that steps reference valid cells and marks, so this matches the contract. Code: `src/core/game_session.gd` lines 313 to 365 and 497 to 520.

### L4. No flush to disk before the rename (Low)

Risk: `SaveStore.write` calls `file.flush()`, which empties Godot's buffer but does not force the data to the storage device, then renames. After a sudden power loss, some Android file systems can leave the renamed file empty. `read` then returns null and that part falls back to defaults (puzzle lost, or stats reset). Godot has no fsync call, so a fix would be a fallback such as keeping the previous file. Code: `src/save/save_store.gd` lines 74 to 81.

### L5. A kill during completion can count one completion twice (Low)

Risk: `App.on_puzzle_completed` saves stats (line 256) before it deletes `puzzle.json` (line 257). `puzzle.json` holds the board one digit before the end, because a completed session is never written. If the app dies between those two lines, the puzzle comes back as Continue one digit short, and finishing it records a second completion. The window is a few milliseconds. Deleting the puzzle file before saving stats would turn the worst case into a lost completion instead. Code: `src/ui/app.gd` lines 245 to 261.

### L6. The exported launcher accepts Godot command line arguments from other apps (Low, not verified on a device)

Risk: Godot's prebuilt template reads a `command_line_params` string array extra from the launch intent (the string `EXTRA_COMMAND_LINE_PARAMS` / `command_line_params` is in `classes.dex`), and the launcher alias is exported. Any app on the phone may be able to start the game with engine arguments (for example `--log-file`, `--write-movie`, `--quit`). The game cannot read other apps' files, so loading foreign code needs a file the game can read, which is unlikely. Remote debugging is not available in release templates. Steps to verify on Bart's phone, debug build: `adb shell am start -n com.bartbasi.sudoku/com.godot.game.GodotAppLauncher --esa command_line_params --verbose` and check `adb logcat` for verbose engine output. This comes from the engine template, not our code.

### L7. Both content providers share one authority (Low, engine template)

Risk: in both APKs `androidx.core.content.FileProvider` and `androidx.startup.InitializationProvider` have `android:authorities="com.bartbasi.sudoku.fileprovider"` (`aapt2 dump xmltree --file AndroidManifest.xml build/sudoku-release-unsigned.apk`, manifest lines 71 and 80). Godot's export rewrites every provider authority to `<package>.fileprovider`. Android registers only the first, so androidx startup initializers (the profile installer) likely do not run. Neither provider is exported and no game code uses them; no data exposure. Noted for awareness only.

### L8. Release manifest is profileable from the shell (Low, informational)

Risk: the release manifest has `<profileable android:enabled="true" android:shell="true">` (line 32), from Godot's template. It lets someone with adb access profile the running release app. It gives no access to app data. No action needed unless Bart wants it off, which needs a Gradle build.

### L9. Committed review images contain text rendered in a third party font (Low)

Risk: twelve PNGs in `docs/design/` ending in `-inter.png` show text rendered in Inter (SIL Open Font License). The font file is not committed and nothing ships, and `docs/ASSETS.md` records it, so this follows Bart's Hard Stop 1 decision. Listed because the rule is "nothing third party": if Bart wants the repo free of any third party material, these twelve files are the only candidates. Files: `git ls-files docs/design | grep inter`.

### L10. The old names still exist outside the repo (Low)

Risk: the repo, its history and both APKs are clean, but `C:\Users\Bart Basi\.claude\projects\C--bart-sudoku\memory\MEMORY.md` and `bartssudoku-phase-status.md` in the same folder each still contain a match for `cheese|cracker`, and this review session was started with a stale copy of CLAUDE.md that still carries the old game name, the old icon decision and the old git author address. An agent working from that stale text could put the old name or address back into code, docs or commits. Not in git, so no history impact. Suggest the Development Manager refreshes the memory files. Also not checkable from here: whether GitHub still holds any pre-rewrite commits (local reflog starts with a push at 2026-10-12 11:03; if older history was ever pushed, GitHub may keep it reachable by SHA).

### L11. docs/ASSETS.md status rows disagree with the code (Low)

Risk: the log meant to prove every asset is made in code is out of date. The app icon row says "port in progress" and that `src/design/app_icon.gd` "still holds the neutral placeholder", but the file holds the final Ring. The board visuals, theme and click sound rows say "planned, Phase 3", but `src/skins/`, `src/design/` and `src/audio/click_synth.gd` are built. The brief's definition of done relies on this log. Owner: senior-graphic-designer. File: `docs/ASSETS.md`, "Game assets" table.

## Could not check

- Behaviour on a real device (L6 intent arguments, L7 provider registration, L1 timing on phone hardware). No device commands were run.
- GitHub's server side copy of the repo (L10). No network access was used.
- The global class cache inside the APK pack is compressed, so its list of class paths was not read; the pack index itself lists no `tests/` or `tools/` files.

Scratch files: `build/security/` (git ignored). The probe cleans up its `user://security_probe` folder.
