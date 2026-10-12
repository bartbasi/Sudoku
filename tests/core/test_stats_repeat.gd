extends "res://tests/unit_test.gd"
## Stats remembers the last completed puzzle id, so a completion that comes
## back after a crash between writing stats and deleting the save is not
## counted twice.


func _json(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))


func test_same_puzzle_counts_once() -> void:
	var stats: Stats = Stats.new()
	stats.record_start(Levels.EASY)
	assert_false(stats.has_completed("1.1.42"))
	assert_eq(stats.record_completion(Levels.EASY, 300, 276, "1.1.42"), 0)
	assert_true(stats.has_completed("1.1.42"))
	assert_eq(stats.last_completed_id(), "1.1.42")
	var before: String = JSON.stringify(stats.to_dict())
	assert_eq(stats.record_completion(Levels.EASY, 200, 400, "1.1.42"), 0, "repeat gives no bits")
	assert_eq(JSON.stringify(stats.to_dict()), before, "repeat changes nothing")
	assert_eq(stats.completed_count(Levels.EASY), 1)
	assert_eq(stats.best_time(Levels.EASY), 300)


func test_other_puzzles_still_count() -> void:
	var stats: Stats = Stats.new()
	stats.record_completion(Levels.EASY, 300, 276, "1.1.42")
	assert_eq(stats.record_completion(Levels.EASY, 200, 300, "1.1.43"), Stats.NEW_BEST_TIME | Stats.NEW_BEST_SCORE)
	assert_false(stats.has_completed("1.1.42"), "only the last id is kept")
	assert_true(stats.has_completed("1.1.43"))
	assert_eq(stats.completed_count(Levels.EASY), 2)
	# The same seed on another level is another puzzle.
	stats.record_completion(Levels.MEDIUM, 500, 400, "1.2.43")
	assert_eq(stats.completed_count(Levels.MEDIUM), 1)


func test_without_id_always_counts() -> void:
	var stats: Stats = Stats.new()
	stats.record_completion(Levels.EASY, 300, 276, "1.1.42")
	stats.record_completion(Levels.EASY, 300, 276)
	stats.record_completion(Levels.EASY, 300, 276, "")
	assert_eq(stats.completed_count(Levels.EASY), 3)
	assert_eq(stats.last_completed_id(), "1.1.42", "no id keeps the last one")
	assert_false(stats.has_completed(""))


func test_invalid_id_counts_and_is_not_kept() -> void:
	var stats: Stats = Stats.new()
	stats.record_completion(Levels.EASY, 300, 276, "1.1.42")
	for bad: String in ["abc", "1.1.42 ", "1".repeat(33)]:
		stats.record_completion(Levels.EASY, 300, 276, bad)
		stats.record_completion(Levels.EASY, 300, 276, bad)
	assert_eq(stats.completed_count(Levels.EASY), 7)
	assert_eq(stats.last_completed_id(), "1.1.42")


func test_invalid_level_keeps_id() -> void:
	var stats: Stats = Stats.new()
	assert_eq(stats.record_completion(-1, 300, 276, "1.1.42"), 0)
	assert_eq(stats.last_completed_id(), "")


func test_reset_keeps_last_id() -> void:
	var stats: Stats = Stats.new()
	stats.record_completion(Levels.EASY, 300, 276, "1.1.42")
	stats.reset(-1)
	assert_eq(stats.completed_count(Levels.EASY), 0)
	assert_true(stats.has_completed("1.1.42"))


func test_last_id_round_trip() -> void:
	var stats: Stats = Stats.new()
	stats.record_start(Levels.EASY)
	stats.record_completion(Levels.EASY, 300, 276, "1.1.42")
	var data: Variant = _json(stats.to_dict())
	assert_eq((data as Dictionary).get("last_completed"), "1.1.42")
	var loaded: Stats = Stats.from_dict(data)
	assert_true(loaded.has_completed("1.1.42"))
	assert_eq(JSON.stringify(loaded.to_dict()), JSON.stringify(stats.to_dict()))
	assert_eq(Stats.new().to_dict().get("last_completed"), "")


func test_last_id_from_bad_data() -> void:
	var good: Dictionary = _json(Stats.new().to_dict())
	good["last_completed"] = "1.1.42"
	assert_true(Stats.from_dict(good).has_completed("1.1.42"))
	for bad: Variant in [null, 42, 1.5, true, "", "abc", "1".repeat(33), ["1.1.42"], {"id": "1.1.42"}, &"1.1.42"]:
		var data: Dictionary = good.duplicate(true)
		data["last_completed"] = bad
		var loaded: Stats = Stats.from_dict(data)
		assert_eq(loaded.last_completed_id(), "", "last_completed = %s" % str(bad))
	var older: Dictionary = good.duplicate(true)
	older.erase("last_completed")
	assert_eq(Stats.from_dict(older).last_completed_id(), "", "older files have no id")
	# A bad id never costs the level stats.
	var stats: Stats = Stats.new()
	stats.record_start(Levels.EASY)
	stats.record_completion(Levels.EASY, 300, 276)
	var mixed: Dictionary = _json(stats.to_dict())
	mixed["last_completed"] = "x"
	assert_eq(Stats.from_dict(mixed).completed_count(Levels.EASY), 1)
