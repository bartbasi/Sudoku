#!/usr/bin/env bash
# Builds the Android debug APK: renders the launcher icons from the code
# drawn app icon, then exports build/sudoku-debug.apk with the "Android"
# preset. Run from Git Bash on Windows, from any folder.
# Needs: godot 4.7.2 on PATH, its export templates, and the Android SDK, JDK 17
# and debug keystore set in Godot's Editor Settings (see README.md).
# Owner: platform-dev.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
mkdir -p build

# A fresh clone has no .godot/ folder yet; import once so class names resolve.
if [ ! -d .godot ]; then
	echo "Importing the project (first run)..."
	timeout 300 godot --headless --path . --import
fi

# Icons need a renderer, so this step opens a window for a moment.
echo "Rendering launcher icons into build/icons/..."
timeout 120 godot --path . --script res://tools/build/render_icons.gd

echo "Exporting build/sudoku-debug.apk..."
rm -f build/sudoku-debug.apk
timeout 600 godot --headless --path . --export-debug "Android" build/sudoku-debug.apk

# Godot can exit 0 even when an export fails, so check for the file.
if [ ! -f build/sudoku-debug.apk ]; then
	echo "Export failed: build/sudoku-debug.apk was not written." >&2
	exit 1
fi
ls -l build/sudoku-debug.apk
echo "Done. Install it with tools/build/install_debug.sh"
