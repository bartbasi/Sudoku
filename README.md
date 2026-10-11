# Sudoku

A free, offline Sudoku for Android. Every empty cell shows all nine candidates around its edge, and you cross them out as you rule them out. No ads, no purchases, no network.

## Requirements

- Godot 4.7.2 stable (`4.7.2.stable.official.ed1daf0bf`), standard build (GDScript, no .NET)
- Godot 4.7.2 export templates (for Android builds)
- For Android: JDK 17 and the Android SDK (platform-tools, build-tools 35.0.1, platform android-35, cmdline-tools), set in Godot's Editor Settings under Export > Android

## Open and run

Open the folder in the Godot editor, or from a terminal:

```
godot --headless --path . --import    # once after a fresh clone
godot --path .                        # run the game
```

## Tests

```
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/run_tests.gd -- core   # only test paths containing "core"
```

The runner exits with 0 when every test passes and 1 otherwise.

## Android build

Build steps are added in Phase 5.
