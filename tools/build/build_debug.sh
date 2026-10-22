#!/usr/bin/env bash
# Builds the Android debug APK: renders the launcher icons from the code
# drawn app icon, then exports build/sudoku-debug.apk with the "Android"
# preset. Run from Git Bash on Windows, from any folder.
# Needs: godot 4.7.2 on PATH, its export templates, and the Android SDK, JDK 17
# and debug keystore set in Godot's Editor Settings (see README.md).
# After the export it checks that the APK carries assets/COPYING and
# assets/NOTICE, byte for byte the same as the repo files, and fails if not.
# To run only that check on an existing APK:
#   tools/build/build_debug.sh --check-only path/to/app.apk
# Owner: platform-dev.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# Fails unless the APK holds assets/COPYING and assets/NOTICE and both match
# the files at the repo root exactly.
check_license_files() {
	local apk="$1"
	local name
	if ! command -v unzip >/dev/null 2>&1; then
		echo "Check failed: unzip is not on PATH, so the APK cannot be checked for COPYING and NOTICE." >&2
		return 1
	fi
	if [ ! -f "$apk" ]; then
		echo "Check failed: $apk does not exist." >&2
		return 1
	fi
	for name in COPYING NOTICE; do
		if ! unzip -l "$apk" "assets/$name" >/dev/null 2>&1; then
			echo "Check failed: $apk does not contain assets/$name." >&2
			return 1
		fi
		if ! unzip -p "$apk" "assets/$name" | cmp -s - "$name"; then
			echo "Check failed: assets/$name in $apk differs from $name in the repo." >&2
			return 1
		fi
	done
	echo "License check passed: assets/COPYING and assets/NOTICE match the repo."
}

if [ "${1:-}" = "--check-only" ]; then
	check_license_files "${2:?usage: build_debug.sh --check-only path/to/app.apk}"
	exit $?
fi

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
check_license_files build/sudoku-debug.apk
echo "Done. Install it with tools/build/install_debug.sh"
