#!/usr/bin/env bash
# Builds the signed release of Sudoku: build/sudoku.aab for Google Play and
# build/sudoku.apk to share directly (GitHub Releases), then checks both.
# Run from Git Bash on Windows, from any folder:
#   tools/build/build_release.sh
# Needs what tools/build/build_debug.sh needs (see README.md), plus the upload
# key, which lives outside the repo (see docs/release.md):
#   %APPDATA%\Godot\keystores\sudoku-release.keystore           (alias sudoku)
#   %APPDATA%\Godot\keystores\sudoku-release-password.txt       (one line: password: <text>)
# The password is read from that file here and handed to Godot only through
# its GODOT_ANDROID_KEYSTORE_RELEASE_* environment variables, for this run.
# It is never printed and never written into the project.
# The AAB needs Godot's Gradle build template. It is unpacked into android/
# (ignored by git) from the 4.7.2 export templates when it is missing.
# Set GODOT to use another Godot 4.7.2 binary.
# Owner: platform-dev.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

GODOT="${GODOT:-godot}"
SDK="${ANDROID_SDK_ROOT:-C:/Android/Sdk}"
KEYS="${APPDATA:?APPDATA is not set}/Godot/keystores"
KEYSTORE="$KEYS/sudoku-release.keystore"
PASSWORD_FILE="$KEYS/sudoku-release-password.txt"
ALIAS="sudoku"
# The upload certificate's SHA-256, as Play Console will show it.
EXPECTED_SHA256="B6:0C:BB:0A:0E:A7:A0:C5:5C:73:30:45:00:83:49:2F:B0:A5:61:35:0A:9A:7F:68:27:DC:FE:C8:0C:0A:82:23"
VERSION_TAG="4.7.2.stable"
APK="build/sudoku.apk"
AAB="build/sudoku.aab"

fail() {
	echo "FAILED: $*" >&2
	exit 1
}

# Godot's own output, with the password masked in case any tool ever prints
# it. awk reads the password from the environment, not from its arguments.
mask() {
	awk 'BEGIN { p = ENVIRON["GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD"] }
	{
		line = $0
		if (p != "") {
			out = ""
			while ((i = index(line, p)) > 0) {
				out = out substr(line, 1, i - 1) "[password]"
				line = substr(line, i + length(p))
			}
			line = out line
		}
		print line
	}'
}

# The key ------------------------------------------------------------------

[ -f "$KEYSTORE" ] || fail "no release keystore at $KEYSTORE (see docs/release.md)"
[ -f "$PASSWORD_FILE" ] || fail "no password file at $PASSWORD_FILE (see docs/release.md)"
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(sed -n 's/^password: //p' "$PASSWORD_FILE" | tr -d '\r' | head -n 1)"
[ -n "$GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD" ] || fail "no 'password: ' line in $PASSWORD_FILE"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KEYSTORE"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$ALIAS"

# The key must be the upload key Play knows. keytool reads the password from
# the environment variable named after -storepass:env.
key_sha="$(keytool -list -v -keystore "$KEYSTORE" -alias "$ALIAS" -storepass:env GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD 2>/dev/null | sed -n 's/^[[:space:]]*SHA256: //p' | tr -d '\r' | head -n 1)"
[ "$key_sha" = "$EXPECTED_SHA256" ] || fail "the keystore's certificate SHA-256 is not the upload key's (got '${key_sha:-nothing}')"
echo "Upload key: alias $ALIAS, SHA-256 matches."

# The Gradle build template ------------------------------------------------

if [ ! -f android/build/build.gradle ] || [ "$(cat android/.build_version 2>/dev/null || true)" != "$VERSION_TAG" ]; then
	SOURCE_ZIP="$APPDATA/Godot/export_templates/$VERSION_TAG/android_source.zip"
	[ -f "$SOURCE_ZIP" ] || fail "the Android build template is missing: $SOURCE_ZIP"
	echo "Unpacking the Android build template into android/build/..."
	rm -rf android/build
	mkdir -p android/build
	unzip -q "$SOURCE_ZIP" -d android/build
	printf '%s' "$VERSION_TAG" > android/.build_version
fi
# Keep Godot's importer out of the template.
touch android/.gdignore android/build/.gdignore
# Godot waits for Gradle to close its output, and a Gradle background daemon
# keeps it open, so run Gradle without one. This edits the unpacked template,
# which git ignores.
grep -q '^org.gradle.daemon=false' android/build/gradle.properties || printf '\norg.gradle.daemon=false\n' >> android/build/gradle.properties
git check-ignore -q android/build/build.gradle || fail "android/ is not ignored by git; add /android/ to .gitignore"

# Export -------------------------------------------------------------------

mkdir -p build
if [ ! -d .godot ]; then
	echo "Importing the project (first run)..."
	timeout 300 "$GODOT" --headless --path . --import 2>&1 | mask
fi

# Icons need a renderer, so this step opens a window for a moment. They are
# drawn every time, so a fresh clone or an empty build/ gets them too.
echo "Rendering launcher icons into build/icons/..."
timeout 120 "$GODOT" --path . --script res://tools/build/render_icons.gd 2>&1 | mask
for icon in main_192 background_432 foreground_432 monochrome_432; do
	[ -s "build/icons/$icon.png" ] || fail "build/icons/$icon.png was not rendered"
done

rm -f "$APK" "$AAB" "$APK.idsig"
echo "Exporting the signed APK..."
timeout 900 "$GODOT" --headless --path . --export-release "Android" "$APK" 2>&1 | mask
echo "Exporting the signed AAB (Gradle, this takes a few minutes)..."
timeout 1800 "$GODOT" --headless --path . --export-release "Android AAB" "$AAB" 2>&1 | mask
# Godot can exit 0 even when an export fails, so check for the files.
[ -s "$APK" ] || fail "$APK was not made"
[ -s "$AAB" ] || fail "$AAB was not made"
# Godot leaves an APK signature sidecar next to the APK; it is not needed.
rm -f "$APK.idsig"

# Checks -------------------------------------------------------------------

BT="$(ls -d "$SDK"/build-tools/* | sort -V | tail -n 1)"
AAPT2="$BT/aapt2.exe"
[ -e "$AAPT2" ] || AAPT2="$BT/aapt2"
APKSIGNER="$BT/apksigner.bat"
[ -e "$APKSIGNER" ] || APKSIGNER="$BT/apksigner"

echo
ls -l "$APK" "$AAB"

echo
badging="$("$AAPT2" dump badging "$APK" 2>/dev/null)"
echo "$badging" | grep -E "^package:|^minSdkVersion|^targetSdkVersion|^application-label:|^native-code"
[[ "$badging" == "package: name='io.github.bartbasi.sudoku'"* ]] || fail "the APK's package name is wrong"
[[ "$badging" != *application-debuggable* ]] || fail "the APK is debuggable"
echo "Debuggable: no"

perms="$("$AAPT2" dump permissions "$APK" 2>/dev/null | tail -n +2 | grep -v '^$' || true)"
[ -z "$perms" ] || fail "the APK asks for permissions: $perms"
echo "APK permissions: none"

# The AAB's manifest is a protobuf; a permission would show as plain text.
# grep -c reads to the end, so unzip never sees a closed pipe.
aab_perms="$(unzip -p "$AAB" base/manifest/AndroidManifest.xml | grep -a -c "uses-permission" || true)"
[ "$aab_perms" = "0" ] || fail "the AAB manifest asks for permissions"
echo "AAB permissions: none"

# COPYING and NOTICE ship byte for byte in both.
"$ROOT/tools/build/build_debug.sh" --check-only "$APK"
# In the AAB the game's files sit in an install time asset pack, not in base/.
aab_names="$(unzip -Z1 "$AAB")"
for name in COPYING NOTICE; do
	entry="$(echo "$aab_names" | grep -E "(^|/)assets/$name\$" | head -n 1 || true)"
	[ -n "$entry" ] || fail "$AAB holds no assets/$name"
	unzip -p "$AAB" "$entry" | cmp -s - "$name" || fail "$entry in $AAB differs from $name"
done
echo "License check passed for the AAB too."

# Nothing from tests, tools, docs, build or android, and no key files.
forbidden='(^|/)assets/(tests|tools|docs|build|android)/|[.]keystore$|[.]jks$|password'
for out in "$APK" "$AAB"; do
	bad="$(unzip -Z1 "$out" | grep -E "$forbidden" || true)"
	[ -z "$bad" ] || fail "$out holds files that must not ship: $bad"
done
echo "No tests, tools, docs, build, android or key files inside."

echo
certs="$("$APKSIGNER" verify --print-certs "$APK" 2>&1 | tr -d '\r')" || fail "the APK signature does not verify: $certs"
echo "$certs" | grep -E "certificate SHA-256 digest|certificate DN"
apk_sha="$(echo "$certs" | sed -n 's/^Signer #1 certificate SHA-256 digest: //p' | head -n 1 | tr 'a-f' 'A-F' | sed 's/../&:/g; s/:$//')"
[ "$apk_sha" = "$EXPECTED_SHA256" ] || fail "the APK is not signed with the upload key"
echo "APK signature: verified, upload key."
jar_out="$(jarsigner -verify "$AAB" 2>&1 | tr -d '\r')"
[[ "$jar_out" == *"jar verified."* ]] || fail "the AAB signature does not verify: $jar_out"
aab_sha="$(keytool -printcert -jarfile "$AAB" 2>/dev/null | tr -d '\r' | sed -n 's/^[[:space:]]*SHA256: //p' | head -n 1)"
[ "$aab_sha" = "$EXPECTED_SHA256" ] || fail "the AAB is not signed with the upload key (got '${aab_sha:-nothing}')"
echo "AAB signature: verified, upload key."

echo
echo "Release built: $AAB (upload to Google Play) and $APK (GitHub Releases)."
