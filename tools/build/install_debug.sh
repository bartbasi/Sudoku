#!/usr/bin/env bash
# Installs build/sudoku-debug.apk on the phone connected by USB (USB debugging
# on and this computer allowed), keeping the app's saved data, then starts it.
# Run from Git Bash on Windows, from any folder. Set ADB to use another adb.
# Owner: platform-dev.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APK="$ROOT/build/sudoku-debug.apk"
PACKAGE="com.bartbasi.sudoku"
ADB="${ADB:-/c/Android/Sdk/platform-tools/adb}"

if [ ! -f "$APK" ]; then
	echo "No APK at $APK. Run tools/build/build_debug.sh first." >&2
	exit 1
fi

"$ADB" devices -l
# -r replaces the installed app and keeps its data (the saved puzzle).
"$ADB" install -r "$APK"
"$ADB" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
echo "Installed and started $PACKAGE."
