extends SceneTree
## Headless test runner. Finds every tests/<area>/test_*.gd, runs each method
## named test_* on a fresh instance, and exits 0 only if every test passes.
##
## All tests:   godot --headless --path . --script res://tests/run_tests.gd
## One area:    godot --headless --path . --script res://tests/run_tests.gd -- core
## The filter keeps only test files whose path contains the given text.

const UnitTest := preload("res://tests/unit_test.gd")
const TESTS_ROOT := "res://tests"


## Counts script errors (bad calls, null access, failed assert()) so a test
## that crashes partway counts as failed instead of passing silently.
class ScriptErrorCounter extends Logger:
	var _count: int = 0
	var _mutex: Mutex = Mutex.new()

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_SCRIPT:
			_mutex.lock()
			_count += 1
			_mutex.unlock()

	func count() -> int:
		_mutex.lock()
		var value: int = _count
		_mutex.unlock()
		return value


func _initialize() -> void:
	# call() returns null if the runner itself hits a script error,
	# so a broken runner still exits with a failure instead of hanging.
	var result: Variant = call("_run")
	var exit_code: int = result if result is int else 1
	quit(exit_code)


func _run() -> int:
	var filter: String = ""
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	if user_args.size() > 0:
		filter = user_args[0]

	var files: Array[String] = []
	_find_test_files(TESTS_ROOT, files)
	files.sort()

	var counter: ScriptErrorCounter = ScriptErrorCounter.new()
	OS.add_logger(counter)

	var total: int = 0
	var failed: int = 0
	for path: String in files:
		if not filter.is_empty() and not path.contains(filter):
			continue
		var script: GDScript = load(path) as GDScript
		if script == null or not script.can_instantiate():
			total += 1
			failed += 1
			print("FAIL %s: could not load the script (see errors above)" % path)
			continue
		var probe: Variant = script.new()
		if not probe is UnitTest:
			total += 1
			failed += 1
			print("FAIL %s: does not extend res://tests/unit_test.gd" % path)
			continue
		for method: String in _test_methods(script):
			total += 1
			var failures: Array[String] = _run_one(script, method, counter)
			if not failures.is_empty():
				failed += 1
				print("FAIL %s :: %s" % [path, method])
				for message: String in failures:
					print("    %s" % message)

	OS.remove_logger(counter)

	if total == 0:
		print("No tests found%s." % ("" if filter.is_empty() else " matching \"%s\"" % filter))
	print("Tests: %d, passed: %d, failed: %d" % [total, total - failed, failed])
	return 0 if failed == 0 else 1


## Runs one test method and returns its failure messages (empty means passed).
func _run_one(script: GDScript, method: String, counter: ScriptErrorCounter) -> Array[String]:
	var test: UnitTest = script.new()
	var nodes_before: int = root.get_child_count()
	var errors_before: int = counter.count()

	test.call(method)

	var script_errors: int = counter.count() - errors_before
	if script_errors > 0:
		test.fail("%d script error(s), see the log above" % script_errors)

	# Free any nodes the test left in the tree so tests stay independent.
	while root.get_child_count() > nodes_before:
		var leftover: Node = root.get_child(root.get_child_count() - 1)
		root.remove_child(leftover)
		leftover.free()

	return test.failures


func _test_methods(script: GDScript) -> Array[String]:
	var names: Array[String] = []
	for info: Dictionary in script.get_script_method_list():
		var method_name: String = info["name"]
		if method_name.begins_with("test_") and not names.has(method_name):
			names.append(method_name)
	return names


func _find_test_files(dir_path: String, out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		if not sub.begins_with("."):
			_find_test_files(dir_path.path_join(sub), out)
	for file: String in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			out.append(dir_path.path_join(file))
