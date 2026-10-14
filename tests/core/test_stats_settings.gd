extends "res://tests/unit_test.gd"
## Stats (GDD 13), New best labels (GDD 12.1), Settings and LessonProgress (GDD 14).

const BOTH := Stats.NEW_BEST_TIME | Stats.NEW_BEST_SCORE


func _json(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))


func test_empty_stats() -> void:
	var stats: Stats = Stats.new()
	for level: int in Levels.COUNT:
		assert_eq(stats.started(level), 0)
		assert_eq(stats.completed_count(level), 0)
		assert_eq(stats.best_time(level), -1)
		assert_eq(stats.average_time(level), -1)
		assert_eq(stats.best_score(level), -1)
	assert_eq(stats.started(7), 0)
	assert_eq(stats.best_time(-1), -1)


func test_stats_on_completion() -> void:
	# AT-53 (core) and the GDD 13 average example.
	var stats: Stats = Stats.new()
	stats.record_start(Levels.EASY)
	stats.record_start(Levels.EASY)
	stats.record_completion(Levels.EASY, 300, 276)
	stats.record_completion(Levels.EASY, 401, 208)
	assert_eq(stats.started(Levels.EASY), 2)
	assert_eq(stats.completed_count(Levels.EASY), 2)
	assert_eq(stats.best_time(Levels.EASY), 300)
	assert_eq(stats.average_time(Levels.EASY), 351, "350.5 rounds up")
	assert_eq(stats.best_score(Levels.EASY), 276)
	assert_eq(stats.started(Levels.MEDIUM), 0)


func test_average_rounding() -> void:
	var stats: Stats = Stats.new()
	stats.record_start(0)
	stats.record_start(0)
	stats.record_start(0)
	stats.record_completion(0, 100, 50)
	stats.record_completion(0, 100, 50)
	stats.record_completion(0, 101, 50)
	assert_eq(stats.average_time(0), 100, "100.33 rounds down")
	stats.record_start(0)
	stats.record_completion(0, 101, 50)
	assert_eq(stats.average_time(0), 101, "100.5 rounds up")


func test_new_best_labels() -> void:
	# AT-67 (core): the six Easy completions of GDD 12.1, then Reset Stats and one more.
	var stats: Stats = Stats.new()
	var rows: Array[Array] = [[300, 276], [401, 208], [300, 316], [290, 199], [240, 333], [241, 333]]
	var labels: Array[int] = []
	for row: Array in rows:
		stats.record_start(Levels.EASY)
		labels.append(stats.record_completion(Levels.EASY, row[0], row[1]))
	assert_eq(labels, [0, 0, Stats.NEW_BEST_SCORE, Stats.NEW_BEST_TIME, BOTH, 0])
	assert_eq(stats.best_time(Levels.EASY), 240)
	assert_eq(stats.best_score(Levels.EASY), 333)
	stats.reset(-1)
	stats.record_start(Levels.EASY)
	assert_eq(stats.record_completion(Levels.EASY, 401, 208), 0, "first completion after a reset")
	assert_eq(stats.best_time(Levels.EASY), 401)


func test_scores_match_the_12_1_table() -> void:
	# GDD 12.1 table: S + T = F for each row.
	assert_eq(Scoring.final_score(Levels.EASY, 1, 300), 276)
	assert_eq(Scoring.final_score(Levels.EASY, 2, 401), 208)
	assert_eq(Scoring.final_score(Levels.EASY, 0, 300), 316)
	assert_eq(Scoring.final_score(Levels.EASY, 3, 290), 199)
	assert_eq(Scoring.final_score(Levels.EASY, 0, 240), 333)
	assert_eq(Scoring.final_score(Levels.EASY, 0, 241), 333)


func test_zero_is_a_valid_best_score() -> void:
	var stats: Stats = Stats.new()
	stats.record_start(0)
	stats.record_completion(0, 900, 0)
	assert_eq(stats.best_score(0), 0)
	stats.record_start(0)
	assert_eq(stats.record_completion(0, 950, 1), Stats.NEW_BEST_SCORE)


func test_reset_keeps_in_progress_started() -> void:
	# GDD 13.2 and AT-55 (core part).
	var stats: Stats = Stats.new()
	for level: int in Levels.COUNT:
		stats.record_start(level)
		stats.record_start(level)
		stats.record_completion(level, 500, 100)
	stats.reset(Levels.MEDIUM)
	for level: int in Levels.COUNT:
		assert_eq(stats.started(level), 1 if level == Levels.MEDIUM else 0)
		assert_eq(stats.completed_count(level), 0)
		assert_eq(stats.best_time(level), -1)
		assert_eq(stats.average_time(level), -1)
		assert_eq(stats.best_score(level), -1)
	stats.record_completion(Levels.MEDIUM, 800, 400)
	assert_eq(stats.started(Levels.MEDIUM), 1)
	assert_eq(stats.completed_count(Levels.MEDIUM), 1)


func test_invalid_level_changes_nothing() -> void:
	var stats: Stats = Stats.new()
	stats.record_start(9)
	assert_eq(stats.record_completion(-1, 10, 10), 0)
	assert_eq(JSON.stringify(stats.to_dict()), JSON.stringify(Stats.new().to_dict()))


func test_stats_round_trip() -> void:
	var stats: Stats = Stats.new()
	stats.record_start(1)
	stats.record_start(1)
	stats.record_completion(1, 300, 276)
	stats.record_start(4)
	var loaded: Stats = Stats.from_dict(_json(stats.to_dict()))
	assert_eq(JSON.stringify(loaded.to_dict()), JSON.stringify(stats.to_dict()))
	assert_eq(loaded.best_time(1), 300)
	assert_eq(loaded.started(4), 1)


func test_stats_from_bad_data() -> void:
	# Never null; a broken level takes defaults, the others load.
	var good_stats: Stats = Stats.new()
	for level: int in Levels.COUNT:
		good_stats.record_start(level)
		good_stats.record_completion(level, 300, 100)
	var good: Dictionary = _json(good_stats.to_dict())
	for data: Variant in [null, "stats", [], {}, {"levels": "x"}, {"levels": [1, 2]}]:
		var loaded: Stats = Stats.from_dict(data)
		assert_ne(loaded, null)
		assert_eq(loaded.started(0), 0)
	var cases: Array[Array] = [
		["started", -1], ["started", "1"], ["completed", 2], ["best_time", -2],
		["best_score", 801], ["best_time", 301], ["total_time", 0.5], ["completed", null],
		["best_score", true],
	]
	for case: Array in cases:
		var bad: Dictionary = good.duplicate(true)
		(bad["levels"] as Array)[2][case[0]] = case[1]
		var loaded: Stats = Stats.from_dict(bad)
		assert_eq(loaded.started(2), 0, "%s = %s resets level 2" % [case[0], case[1]])
		assert_eq(loaded.best_time(2), -1)
		assert_eq(loaded.started(1), 1, "level 1 still loads")
		assert_eq(loaded.best_time(3), 300)
	var no_completion: Dictionary = good.duplicate(true)
	(no_completion["levels"] as Array)[0] = {"started": 3, "completed": 0, "best_time": 100, "total_time": 0, "best_score": -1}
	assert_eq(Stats.from_dict(no_completion).started(0), 0, "a best without a completion")


func test_settings_defaults_and_round_trip() -> void:
	var settings: Settings = Settings.new()
	assert_true(settings.sound)
	assert_eq(settings.skin_id, &"pop_light")
	assert_false(settings.auto_cross, "Auto Cross is off by default")
	assert_false(settings.first_launch_answered)
	settings.sound = false
	settings.skin_id = &"pop_dark"
	settings.auto_cross = true
	settings.first_launch_answered = true
	var loaded: Settings = Settings.from_dict(_json(settings.to_dict()))
	assert_false(loaded.sound)
	assert_eq(loaded.skin_id, &"pop_dark")
	assert_true(loaded.auto_cross)
	assert_true(loaded.first_launch_answered)


func test_settings_from_bad_data() -> void:
	for data: Variant in [null, 3, "x", [], {}]:
		var loaded: Settings = Settings.from_dict(data)
		assert_ne(loaded, null)
		assert_true(loaded.sound)
		assert_eq(loaded.skin_id, &"pop_light")
		assert_false(loaded.auto_cross)
	var mixed: Settings = Settings.from_dict({"sound": "off", "skin_id": "neon", "auto_cross": true, "first_launch_answered": 1})
	assert_true(mixed.sound, "invalid field takes its default")
	assert_eq(mixed.skin_id, &"pop_light")
	assert_true(mixed.auto_cross, "a valid field still loads")
	assert_false(mixed.first_launch_answered)
	assert_eq(Settings.from_dict({"skin_id": 5}).skin_id, &"pop_light")


func test_settings_last_level() -> void:
	assert_eq(Settings.new().last_level, Levels.EASY, "Easy by default")
	for level: int in Levels.COUNT:
		var settings: Settings = Settings.new()
		settings.last_level = level
		assert_eq(settings.to_dict()["last_level"], level)
		assert_eq(Settings.from_dict(_json(settings.to_dict())).last_level, level, "round trip through JSON")
	assert_eq(Settings.from_dict({"last_level": 3}).last_level, Levels.HARD, "an int loads")
	assert_eq(Settings.from_dict({"last_level": 4.0}).last_level, Levels.EXPERT, "a whole float loads")
	assert_eq(Settings.from_dict({"last_level": 0.0}).last_level, Levels.BEGINNER)
	var bad: Array = [null, "3", "Hard", true, false, 2.5, -1, -1.0, 5, 5.0, -0.5, 4.5,
		NAN, INF, -INF, 1e300, -1e300, 9223372036854775807, [], {}]
	for value: Variant in bad:
		assert_eq(Settings.from_dict({"last_level": value}).last_level, Levels.EASY, "%s takes Easy" % [value])
	assert_eq(Settings.from_dict({}).last_level, Levels.EASY, "missing takes Easy")
	var mixed: Settings = Settings.from_dict({"last_level": 2.5, "auto_cross": true})
	assert_true(mixed.auto_cross, "a bad last_level leaves the other fields alone")
	var kept: Settings = Settings.from_dict({"last_level": 0, "sound": "off"})
	assert_eq(kept.last_level, Levels.BEGINNER, "a good last_level loads beside a bad field")


func test_lesson_progress() -> void:
	# AT-56 (core part): counts once per lesson.
	var progress: LessonProgress = LessonProgress.new()
	assert_eq(progress.finished_count(), 0)
	assert_true(progress.mark_finished("lesson_02"))
	assert_false(progress.mark_finished("lesson_02"))
	assert_true(progress.mark_finished("lesson_01"))
	assert_false(progress.mark_finished("lesson_1"))
	assert_false(progress.mark_finished("../lesson_03"))
	assert_true(progress.is_finished("lesson_01"))
	assert_false(progress.is_finished("lesson_03"))
	assert_eq(progress.finished_count(), 2)
	var loaded: LessonProgress = LessonProgress.from_dict(_json(progress.to_dict()))
	assert_eq(loaded.finished_count(), 2)
	assert_true(loaded.is_finished("lesson_02"))


func test_lesson_progress_from_bad_data() -> void:
	for data: Variant in [null, "x", [], {}, {"finished": "lesson_01"}]:
		assert_eq(LessonProgress.from_dict(data).finished_count(), 0)
	var mixed: LessonProgress = LessonProgress.from_dict({"finished": ["lesson_01", "lesson_01", 4, "lesson_xx", "lesson_055", "LESSON_02", "lesson_05", null]})
	assert_eq(mixed.finished_count(), 2)
	assert_true(mixed.is_finished("lesson_01"))
	assert_true(mixed.is_finished("lesson_05"))


func test_reset_stats_keeps_lessons() -> void:
	# Bart, Hard Stop 1: Reset Stats keeps lesson progress. They are separate objects.
	var progress: LessonProgress = LessonProgress.new()
	progress.mark_finished("lesson_01")
	var stats: Stats = Stats.new()
	stats.reset(-1)
	assert_eq(progress.finished_count(), 1)
