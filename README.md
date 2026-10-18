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

The debug APK is built and installed from Git Bash on Windows. The Android export preset is in `export_presets.cfg` (preset "Android", package `com.bartbasi.sudoku`, arm64-v8a, no permissions).

The game version is set in two places that must always match: `application/config/version` in `project.godot` (shown on the About screen) and `version/name` in `export_presets.cfg` (the Android version name). When the version changes, change both together, and raise `version/code` in `export_presets.cfg` too.

### One time setup

1. Install the Godot 4.7.2 export templates (Godot editor: Editor > Manage Export Templates > Download and Install).
2. Install JDK 17 (Temurin) and the Android SDK with platform-tools, build-tools 35.0.1, platform android-35 and cmdline-tools.
3. In the Godot editor, open Editor > Editor Settings > Export > Android and set:
   - Java SDK Path, for example `C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot`
   - Android SDK Path, for example `C:/Android/Sdk`
   - Debug Keystore, Debug Keystore User and Debug Keystore Pass. Godot creates a debug keystore in its user data folder (`%APPDATA%\Godot\keystores\debug.keystore`, user `androiddebugkey`, password `android`). If it is missing, make one with:

     ```
     keytool -genkeypair -v -keystore "$APPDATA/Godot/keystores/debug.keystore" -storepass android -alias androiddebugkey -keypass android -keyalg RSA -validity 9999 -dname "CN=Android Debug,O=Android,C=US"
     ```

   Keystores and their passwords never go in this repo.
4. On the phone, turn on USB debugging: Settings > About phone > Software information, tap Build number seven times, then Settings > Developer options > USB debugging. Connect the USB cable and allow this computer when the phone asks. `adb devices` should list the phone as `device`.

### Build and install

```
tools/build/build_debug.sh      # renders the icons, exports build/sudoku-debug.apk
tools/build/install_debug.sh    # installs it on the phone with adb install -r and starts it
```

`build_debug.sh` first runs `tools/build/render_icons.gd`, which draws the launcher icons from `src/design/app_icon.gd` into `build/icons/`. That step needs a window, so a Godot window opens for a moment. The icons are build output and are never committed. The export itself is:

```
godot --headless --path . --export-debug "Android" build/sudoku-debug.apk
```

`install_debug.sh` uses `C:/Android/Sdk/platform-tools/adb`; set `ADB` to use another one. `adb install -r` keeps the app's saved data. To read the app's log after it starts:

```
adb logcat -d --pid=$(adb shell pidof com.bartbasi.sudoku)
```

### Checking permissions

The app requests no Android permissions. To check an APK:

```
C:/Android/Sdk/build-tools/35.0.1/aapt2 dump permissions build/sudoku-debug.apk
```

It prints only the package line, `package: com.bartbasi.sudoku`, with no `uses-permission` lines.

The "Buy me a coffee" button calls `OS.shell_open`, which hands the address to the phone's browser with a standard Android view intent. The browser does the network work, so the game itself needs no permission for it, `INTERNET` included.

## Privacy

The game collects nothing. It has no accounts, ads, analytics or network code, and everything it saves stays on the phone. The privacy policy is at https://bartbasi.github.io/Sudoku/privacy/.

## Support

The game is free. If you enjoy it, you can buy me a coffee at https://buymeacoffee.com/playinc. Never expected, always appreciated.

## Contact

Questions, feedback, privacy and notices: bartbasi@gmail.com

## License

Copyright 2026 Play, Inc. Designed and written by Bart Basi.

Sudoku is free software under the GNU General Public License, version 3, with two additional terms under section 7 of that license:

- 7(b): every copy and every modified version keeps the attributions "Copyright 2026 Play, Inc." and "Designed and written by Bart Basi." in its About screen.
- 7(c): a modified version must be marked as changed from the original, and its About screen must say that it is a modified version of Sudoku.

The full license text is in [COPYING](COPYING). The additional terms, in their exact wording, are in [NOTICE](NOTICE). Both ship inside the app and can be read in its About screen.

The Godot Engine is under the MIT license. The About screen shows the engine's license and the notices for the parts it includes.

