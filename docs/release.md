# Releasing Sudoku

Everything needed to put Sudoku on Google Play, or to hand the APK to friends directly.

| | |
| --- | --- |
| App name on the phone | Sudoku (store title: see [store/listing.md](store/listing.md)) |
| Package (app ID) | `io.github.bartbasi.sudoku`. It can never change once the app is on Play. |
| Version | `version/code=1`, `version/name="1.0"` in **both** presets in `export_presets.cfg`, and `application/config/version="1.0"` in `project.godot` (shown in About) |
| Android | 7.0 and newer (min SDK 24, target SDK 36), 64-bit ARM phones (arm64-v8a) |
| Permissions | none |
| Network, ads, analytics, accounts | none. The game never goes online. Buy me a coffee only hands a fixed address to the phone's browser. |
| Data stored | small JSON files in the app's private storage: the puzzle in progress, stats, lesson progress and settings. Not in Android's cloud backup (allowBackup is off); deleted on uninstall. |

## 1. Back up the signing key first

The upload key lives outside the repo, in `%APPDATA%\Godot\keystores\`:

- `sudoku-release.keystore` (PKCS12, alias `sudoku`; the key password is the store password)
- `sudoku-release-password.txt` (one line: `password: ...`)

Copy **both** somewhere safe and private, such as a password manager or private cloud storage. Not the repo, not email. Every update on Play has to be signed with this key, and so does every APK you send to friends; a phone refuses an update signed with a different key. With Play App Signing (below), Google can reset a lost upload key, but only after a support request. A lost key for directly shared APKs cannot be recovered: everyone would have to uninstall and lose their stats.

Certificate: `CN=Bart Basi, O="Play, Inc."`, SHA-256
`B6:0C:BB:0A:0E:A7:A0:C5:5C:73:30:45:00:83:49:2F:B0:A5:61:35:0A:9A:7F:68:27:DC:FE:C8:0C:0A:82:23`.

Never print the password, paste it in a chat or commit it. git ignores `*.keystore`, `*.jks` and `*-password.txt`.

## 2. Build

From Git Bash, in the repo:

```bash
tools/build/build_release.sh
```

It writes:

- `build/sudoku.aab`, the Android App Bundle you upload to Play. It is built with Gradle from Godot's Android build template in `android/build/`, which git ignores. The script unpacks it from `%APPDATA%\Godot\export_templates\4.7.2.stable\android_source.zip` when it is missing, and writes `4.7.2.stable` to `android/.build_version`.
- `build/sudoku.apk`, a signed APK to share directly (GitHub Releases).

On the way it checks that the keystore is the upload key above, renders the launcher icons into `build/icons/` (a Godot window opens for a moment), and after the export checks both files: package name, not debuggable, no permissions, COPYING and NOTICE byte for byte, no tests, tools, docs or key files inside, and both signed with the upload key. It stops with `FAILED: ...` if anything is wrong.

The password is read from the password file inside the script and handed to Godot only through its `GODOT_ANDROID_KEYSTORE_RELEASE_*` environment variables, for that one run. Godot's own output is passed through a filter that would mask it. Nothing secret is written into the project.

It needs a few GB free on C: while Gradle runs.

### Checking a build by hand

```bash
C:/Android/Sdk/build-tools/36.1.0/aapt2.exe dump badging build/sudoku.apk | head -5
C:/Android/Sdk/build-tools/36.1.0/aapt2.exe dump permissions build/sudoku.apk
C:/Android/Sdk/build-tools/36.1.0/apksigner.bat verify --print-certs build/sudoku.apk
jarsigner -verify build/sudoku.aab
keytool -printcert -jarfile build/sudoku.aab
```

`dump permissions` prints only `package: io.github.bartbasi.sudoku`. `dump badging` shows `versionCode`, `targetSdkVersion:'36'` and no `application-debuggable` line. The aapt2 warning about `themed_icon.xml` comes from Godot's template and is harmless.

The AAB's manifest is a protobuf file, which aapt2 cannot read inside an AAB. To read it, copy `base/manifest/AndroidManifest.xml` and `base/resources.pb` out of the AAB into a new zip as `AndroidManifest.xml` and `resources.pb`; `aapt2 dump badging`, `dump permissions` and `dump xmltree --file AndroidManifest.xml` then work on that zip.

### Version rule

For every new upload, raise `version/code` by 1 in both `[preset.0.options]` and `[preset.1.options]`. Play rejects a version code it has already seen. When `version/name` changes, change it in both presets and in `application/config/version` in `project.godot` together (README.md, "Android build").

## 3. Store graphics

```bash
timeout 300 godot --path . --resolution 1080x1920 --script res://tools/build/store_graphics.gd
```

It draws the app icon, the feature graphic and six phone screenshots of the real game into `docs/store/graphics/`, with a scratch save folder, so your own saves are never touched. It needs a desktop session (a window opens). Look at every image before uploading.

## 4. Share the APK directly

Send `build/sudoku.apk`. On the phone: open it, then allow installing from that app (Files, Chrome, Gmail and so on) when asked. Play Protect may warn that it does not know the app; "Install anyway" is fine for your own build.

- A debug build installed with `adb` is signed with the debug key, so the release APK will not install over it. Uninstall the debug one first; its puzzle, stats and settings are lost.
- Builds from before 2026-11-06 used the old package `com.bartbasi.sudoku`. Android sees that as a different app, so both can sit on the phone side by side. Uninstall the old one.

## 5. Google Play

### One time setup

1. Sudoku goes on Play, Inc.'s organization account, like the other Play, Inc. games. An organization account needs the company's DUNS number. No Play Console work until the account is ready.
2. Create the app: the name from [store/listing.md](store/listing.md), default language English (US), **Game**, **Free** (free cannot be changed to paid later), then accept the declarations.

### Play App Signing

Play keeps the key that signs what phones download, and `sudoku-release.keystore` becomes the **upload key**. On the first upload, accept the default, "Let Google manage and protect your app signing key". Nothing else is needed: the `.aab` is already signed with the upload key.

### Upload

1. Internal testing first: Testing > Internal testing > Create new release > upload `build/sudoku.aab` > release notes, for example "First release." > Review > Start rollout. Add yourself as a tester, install it from the Play link and check it on the phone.
2. Then Production: Production > Create new release > add the same `.aab` from the library (or a newer one with a higher version code) > Review > Start rollout. A new personal account would first need a closed test; an organization account does not. Check the current rule in the Console.

### Store listing, App content and countries

Everything to paste in (the listing text, contact details, privacy policy URL, and the Data safety, Ads, App access, content rating and target audience answers) is in [store/listing.md](store/listing.md). The privacy policy is published from the gh-pages branch at https://bartbasi.github.io/Sudoku/privacy/. The images are in [store/graphics/](store/graphics/).
