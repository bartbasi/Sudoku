extends "res://tests/unit_test.gd"
## PuzzleId round trips and rejects anything that is not exactly an ID.


func test_make_format() -> void:
	assert_eq(PuzzleId.make(0, 0), "1.0.0")
	assert_eq(PuzzleId.make(3, 20481), "1.3.20481")
	assert_eq(PuzzleId.make(4, 4294967295), "1.4.4294967295")


func test_round_trip() -> void:
	for level: int in 5:
		for seed_value: int in [0, 1, 9, 10, 123456, 4294967294, 4294967295]:
			var parsed: Dictionary = PuzzleId.parse(PuzzleId.make(level, seed_value))
			assert_eq(parsed, {"version": 1, "level": level, "seed": seed_value}, "level %d seed %d" % [level, seed_value])


func test_parsed_values_are_ints() -> void:
	var parsed: Dictionary = PuzzleId.parse("1.2.345")
	assert_eq(typeof(parsed["version"]), TYPE_INT)
	assert_eq(typeof(parsed["level"]), TYPE_INT)
	assert_eq(typeof(parsed["seed"]), TYPE_INT)


func test_rejects_malformed_ids() -> void:
	var bad: Array[String] = [
		"", "1", "1.0", "1.0.0.0", "1..0", ".0.0", "1.0.", "1.0.5.",
		"0.0.5", "2.0.5", "9.0.5",
		"1.5.0", "1.9.0", "1.-1.5", "1.0.-5", "-1.0.5",
		"1.0.4294967296", "1.0.9999999999", "1.0.99999999999999999999",
		"01.0.5", "1.00.5", "1.0.05", "1.0.00",
		"+1.0.5", "1.+0.5", "1.0.+5",
		" 1.0.5", "1.0.5 ", "1.0 .5", "1.0.5\n", "1\t.0.5",
		"1,0,5", "1:0:5", "a.b.c", "1.0.x", "1.0.5e3", "1.0.0x10", "1.0.1_000",
		"1.0.١٢", "١.0.0", "1.0.５",
		"1.0.5.5.5.5.5.5.5.5.5.5.5.5.5.5.5",
	]
	for id: String in bad:
		assert_eq(PuzzleId.parse(id), {}, "\"%s\" is rejected" % id.c_escape())


func test_rejects_very_long_text() -> void:
	assert_eq(PuzzleId.parse("1.0." + "1".repeat(5000)), {})
	assert_eq(PuzzleId.parse("1".repeat(100000)), {})
