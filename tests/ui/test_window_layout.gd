extends "res://tests/unit_test.gd"
## Runs window_check.gd in a child Godot process, headless, and passes only
## when every check there passes: the play screen, the menus, the lists and
## the dialogs on every window of DESIGN_SYSTEM.md 4.11 and every screen of
## 4.10 (arrangement, inside the safe rect, nothing overlapping, touch
## targets of 48 dp or more, the mirrored header row). It runs in its own
## process because this runner keeps nodes outside the scene tree, where box
## containers do not lay out. The check stops itself after a few minutes.


func test_every_screen_lays_out_on_every_window() -> void:
	var output: Array = []
	var args: PackedStringArray = PackedStringArray([
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/ui/window_check.gd",
	])
	var code: int = OS.execute(OS.get_executable_path(), args, output, true)
	var text: String = "\n".join(PackedStringArray(output))
	var summary: String = ""
	for raw: String in text.split("\n"):
		var line: String = raw.strip_edges()
		if line.begins_with("FAIL "):
			fail(line.substr(5))
		elif line.begins_with("window_check: "):
			summary = line
	print("  ", summary if not summary.is_empty() else "window_check printed no summary")
	assert_eq(code, 0, "window_check exit code")
	assert_true(summary.ends_with(" 0 failed"), "window_check: %s" % summary)
