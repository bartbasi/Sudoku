extends "res://tests/unit_test.gd"
## SaveStore (docs/ARCHITECTURE.md section 12): the file format, size limits,
## atomic writes, user:// only, and every kind of damaged file coming back as
## null instead of an error.

const Fx := preload("res://tests/save/save_fixtures.gd")


func test_write_then_read_gives_the_data_back() -> void:
	var dir: String = Fx.fresh_dir("store_round")
	var path: String = dir.path_join("a.json")
	var data: Dictionary = {"sound": false, "list": [1, 2, 3], "text": "x"}
	assert_true(SaveStore.write(path, data), "write")
	var back: Variant = SaveStore.read(path, SaveStore.MAX_BYTES_OTHER)
	assert_eq(typeof(back), TYPE_DICTIONARY)
	if typeof(back) == TYPE_DICTIONARY:
		var dict: Dictionary = back
		assert_eq(dict.get("sound"), false)
		assert_eq(dict.get("text"), "x")
		assert_eq((dict.get("list") as Array).size(), 3)
	Fx.wipe(dir)


func test_file_is_format_1_with_data() -> void:
	var dir: String = Fx.fresh_dir("store_format")
	var path: String = dir.path_join("a.json")
	SaveStore.write(path, {"k": 1})
	var parsed: Variant = JSON.parse_string(Fx.read_text(path))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	if typeof(parsed) == TYPE_DICTIONARY:
		var dict: Dictionary = parsed
		assert_eq(dict.get("format"), 1.0)
		assert_eq(typeof(dict.get("data")), TYPE_DICTIONARY)
	Fx.wipe(dir)


func test_write_replaces_the_old_file_and_leaves_no_temp_file() -> void:
	var dir: String = Fx.fresh_dir("store_replace")
	var path: String = dir.path_join("a.json")
	assert_true(SaveStore.write(path, {"n": 1}))
	assert_true(SaveStore.write(path, {"n": 2}), "second write renames over the first")
	var back: Dictionary = SaveStore.read(path, SaveStore.MAX_BYTES_OTHER)
	assert_eq(back.get("n"), 2.0)
	assert_false(FileAccess.file_exists(path + ".tmp"), "no temp file left")
	Fx.wipe(dir)


func test_a_failed_write_keeps_the_old_file() -> void:
	var dir: String = Fx.fresh_dir("store_keep")
	var path: String = dir.path_join("a.json")
	SaveStore.write(path, {"n": 1})
	# A folder where the temp file should go makes the write fail.
	DirAccess.make_dir_absolute(path + ".tmp")
	assert_false(SaveStore.write(path, {"n": 2}), "write fails")
	var back: Dictionary = SaveStore.read(path, SaveStore.MAX_BYTES_OTHER)
	assert_eq(back.get("n"), 1.0, "old file intact")
	DirAccess.remove_absolute(path + ".tmp")
	Fx.wipe(dir)


func test_a_leftover_temp_file_is_ignored_on_read() -> void:
	var dir: String = Fx.fresh_dir("store_leftover")
	var path: String = dir.path_join("a.json")
	SaveStore.write(path, {"n": 1})
	Fx.write_text(path + ".tmp", "{\"format\": 1, \"da")
	var back: Dictionary = SaveStore.read(path, SaveStore.MAX_BYTES_OTHER)
	assert_eq(back.get("n"), 1.0)
	SaveStore.remove(path)
	assert_false(FileAccess.file_exists(path))
	assert_false(FileAccess.file_exists(path + ".tmp"), "remove also clears the temp file")
	Fx.wipe(dir)


func test_missing_file_reads_null() -> void:
	var dir: String = Fx.fresh_dir("store_missing")
	assert_eq(SaveStore.read(dir.path_join("none.json"), SaveStore.MAX_BYTES_OTHER), null)
	Fx.wipe(dir)


func test_damaged_files_read_null() -> void:
	var dir: String = Fx.fresh_dir("store_damaged")
	var path: String = dir.path_join("a.json")
	var cases: Array[String] = [
		"",
		"not json at all",
		"{\"format\": 1, \"data\": {\"sound\": tr",
		"{\"format\": 1, \"data\": {}",
		"[1, 2, 3]",
		"\"just a string\"",
		"12",
		"null",
		"{\"format\": 2, \"data\": {}}",
		"{\"format\": \"1\", \"data\": {}}",
		"{\"format\": 1.5, \"data\": {}}",
		"{\"format\": 1}",
		"{\"data\": {}}",
		"{\"format\": 1, \"data\": []}",
		"{\"format\": 1, \"data\": \"x\"}",
		"{\"format\": 1, \"data\": null}",
		"{\"format\": 1, \"data\": {}, \"extra\": 1}",
		"Object(Node,\"name\":\"x\")",
		"{\"format\": 1, \"data\": Object(Node)}",
	]
	for text: String in cases:
		Fx.write_text(path, text)
		assert_eq(SaveStore.read(path, SaveStore.MAX_BYTES_OTHER), null, "reads null: %s" % text)
	Fx.wipe(dir)


func test_binary_garbage_and_nul_bytes_read_null() -> void:
	var dir: String = Fx.fresh_dir("store_binary")
	var path: String = dir.path_join("a.json")
	var bytes: PackedByteArray = PackedByteArray()
	for i: int in 300:
		bytes.append((i * 37 + 11) % 256)
	Fx.write_bytes(path, bytes)
	assert_eq(SaveStore.read(path, SaveStore.MAX_BYTES_OTHER), null, "garbage")
	var nul: PackedByteArray = "{\"format\": 1, \"data\": {}}".to_utf8_buffer()
	nul.append(0)
	Fx.write_bytes(path, nul)
	assert_eq(SaveStore.read(path, SaveStore.MAX_BYTES_OTHER), null, "NUL byte")
	# A var_to_bytes blob must never be decoded into anything.
	Fx.write_bytes(path, var_to_bytes({"format": 1, "data": {}}))
	assert_eq(SaveStore.read(path, SaveStore.MAX_BYTES_OTHER), null, "binary Variant")
	Fx.wipe(dir)


func test_every_truncation_of_a_good_file_reads_null() -> void:
	var dir: String = Fx.fresh_dir("store_truncated")
	var path: String = dir.path_join("a.json")
	var full: String = Fx.wrap({"sound": true, "skin_id": "pop_dark", "list": [1, 2, 3]})
	for length: int in full.length():
		Fx.write_text(path, full.substr(0, length))
		assert_eq(SaveStore.read(path, SaveStore.MAX_BYTES_OTHER), null, "truncated at %d" % length)
	Fx.write_text(path, full)
	assert_ne(SaveStore.read(path, SaveStore.MAX_BYTES_OTHER), null, "the whole file reads")
	Fx.wipe(dir)


func test_a_file_over_the_size_limit_reads_null() -> void:
	var dir: String = Fx.fresh_dir("store_size")
	var path: String = dir.path_join("a.json")
	var filler: String = "x".repeat(2000)
	Fx.write_text(path, Fx.wrap({"pad": filler}))
	assert_eq(SaveStore.read(path, 1000), null, "over the limit")
	assert_ne(SaveStore.read(path, 4000), null, "under the limit")
	Fx.wipe(dir)


## Security Low 2: write enforces the limit read enforces, so it never
## writes a file the next launch would drop; the old file stays instead.
func test_write_refuses_data_over_the_limit_and_keeps_the_old_file() -> void:
	var dir: String = Fx.fresh_dir("store_write_limit")
	var path: String = dir.path_join("a.json")
	assert_true(SaveStore.write(path, {"pad": "old"}, 1000))
	assert_false(SaveStore.write(path, {"pad": "x".repeat(2000)}, 1000), "over the limit")
	var back: Variant = SaveStore.read(path, 1000)
	assert_true(back is Dictionary and (back as Dictionary).get("pad") == "old", "the old file stays")
	assert_false(FileAccess.file_exists(path + SaveStore.TEMP_SUFFIX), "no temp file")
	# Exactly at the limit is written and reads back.
	var text: String = JSON.stringify({"format": SaveStore.FORMAT, "data": {"pad": "y"}}, "", true, true)
	var limit: int = text.to_utf8_buffer().size()
	assert_true(SaveStore.write(path, {"pad": "y"}, limit), "at the limit")
	assert_ne(SaveStore.read(path, limit), null)
	assert_false(SaveStore.write(path, {"pad": "yy"}, limit), "one byte over")
	Fx.wipe(dir)


func test_write_counts_utf8_bytes_not_characters() -> void:
	var dir: String = Fx.fresh_dir("store_write_utf8")
	var path: String = dir.path_join("a.json")
	# 300 two byte characters: 300 characters but over 600 bytes.
	assert_false(SaveStore.write(path, {"pad": "é".repeat(300)}, 500))
	assert_false(FileAccess.file_exists(path))
	Fx.wipe(dir)


func test_write_defaults_to_the_puzzle_limit() -> void:
	var dir: String = Fx.fresh_dir("store_write_default")
	var path: String = dir.path_join("a.json")
	assert_false(SaveStore.write(path, {"pad": "x".repeat(SaveStore.MAX_BYTES_PUZZLE)}), "over 16 MiB")
	assert_false(FileAccess.file_exists(path))
	assert_true(SaveStore.write(path, {"pad": "x".repeat(1000)}))
	Fx.wipe(dir)


func test_deep_nesting_reads_null_or_plain_data_without_crashing() -> void:
	var dir: String = Fx.fresh_dir("store_deep")
	var path: String = dir.path_join("a.json")
	Fx.write_text(path, "{\"format\": 1, \"data\": {\"a\": " + "[".repeat(5000) + "]".repeat(5000) + "}}")
	var back: Variant = SaveStore.read(path, SaveStore.MAX_BYTES_OTHER)
	assert_true(back == null or typeof(back) == TYPE_DICTIONARY)
	Fx.wipe(dir)


func test_only_user_json_paths_are_allowed() -> void:
	assert_true(SaveStore.is_allowed_path("user://settings.json"))
	assert_true(SaveStore.is_allowed_path("user://test_scratch/x/a.json"))
	for path: String in ["res://settings.json", "C:/settings.json", "/tmp/a.json", "user://../a.json", "user://a/../../b.json", "user://a.txt", "user://", "user:///etc/a.json", "user://a\\b.json", "user://c:/a.json"]:
		assert_false(SaveStore.is_allowed_path(path), path)
	assert_false(SaveStore.write("res://should_not_exist.json", {}), "no write outside user://")
	assert_false(FileAccess.file_exists("res://should_not_exist.json"))
	assert_eq(SaveStore.read("res://project.godot", SaveStore.MAX_BYTES_OTHER), null)
