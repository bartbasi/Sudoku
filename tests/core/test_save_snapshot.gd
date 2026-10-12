extends "res://tests/unit_test.gd"
## GameSession.save_snapshot() and snapshot_to_dict(): the snapshot taken on
## the main thread turns into exactly to_dict(), even after the session keeps
## playing, and the conversion is safe on a worker thread.

const F := preload("res://tests/core/core_fixtures.gd")


func _hint() -> Hint:
	var h: Hint = Hint.new()
	h.technique = &"hidden_single"
	h.technique_name = "Hidden single"
	h.text = "In this box, 5 fits in only one cell. It goes here."
	h.targets = PackedInt32Array([20])
	h.placement_cell = 20
	h.placement_digit = 5
	return h


## Exact: same keys, same types and same values, down to int versus float.
func _assert_exact(actual: Dictionary, expected: Dictionary, message: String) -> void:
	assert_true(actual == expected, message + " (==)")
	assert_eq(var_to_str(actual), var_to_str(expected), message + " (var_to_str)")
	assert_eq(JSON.stringify(actual), JSON.stringify(expected), message + " (JSON)")


## One random player action: select, mode, digit, erase, undo, Auto Cross,
## hint, or time. Leaves the session as a player could.
func _random_action(s: GameSession, rng: RandomNumberGenerator) -> void:
	var roll: int = rng.randi_range(0, 99)
	if roll < 30:
		F.place(s, rng.randi_range(0, 80), rng.randi_range(1, 9))
	elif roll < 60:
		F.cross(s, rng.randi_range(0, 80), rng.randi_range(1, 9))
	elif roll < 70:
		F.erase_at(s, rng.randi_range(0, 80))
	elif roll < 82:
		s.undo()
	elif roll < 87:
		s.set_auto_cross(not s.auto_cross)
	elif roll < 91:
		s.buy_hint(_hint())
	elif roll < 94:
		s.close_hint()
	elif roll < 97:
		s.toggle_mode()
	else:
		s.add_time(rng.randf_range(0.0, 3.0))


## A session with exactly `count` undo steps, built from places, erases and
## crosses with Auto Cross on, so most steps carry Auto Cross changes.
func _session_with_steps(count: int) -> GameSession:
	var s: GameSession = F.session_b(true)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 77
	var guard: int = 0
	while _undo_count(s) < count and guard < count * 20:
		guard += 1
		var cell: int = rng.randi_range(0, 80)
		if s.board.is_given(cell):
			continue
		if s.board.digits[cell] != 0:
			F.erase_at(s, cell)
		elif rng.randi_range(0, 2) == 0:
			F.cross(s, cell, rng.randi_range(1, 9))
		else:
			F.place(s, cell, rng.randi_range(1, 9))
	return s


func _undo_count(s: GameSession) -> int:
	var dict: Dictionary = s.save_snapshot()
	return (dict["undo"] as Array).size()


# Equality ---------------------------------------------------------------------

func test_fresh_and_lesson_sessions() -> void:
	var s: GameSession = F.session_b(false)
	_assert_exact(GameSession.snapshot_to_dict(s.save_snapshot()), s.to_dict(), "fresh")
	s = F.session_b(true)
	_assert_exact(GameSession.snapshot_to_dict(s.save_snapshot()), s.to_dict(), "fresh, Auto Cross on")
	var lesson: GameSession = GameSession.for_lesson(Board.create(F.position_b_givens()), GameSession.Mode.CROSS_OUT, 4)
	F.cross(lesson, 0, 3)
	_assert_exact(GameSession.snapshot_to_dict(lesson.save_snapshot()), lesson.to_dict(), "lesson")
	var bare: GameSession = GameSession.new()
	_assert_exact(GameSession.snapshot_to_dict(bare.save_snapshot()), bare.to_dict(), "no board")


func test_random_sessions_match_to_dict() -> void:
	for seed_value: int in [1, 2, 3, 4, 5, 6]:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = seed_value
		var s: GameSession = F.session_b(seed_value % 2 == 0)
		for i: int in 1500:
			_random_action(s, rng)
			if i % 50 == 49:
				_assert_exact(GameSession.snapshot_to_dict(s.save_snapshot()), s.to_dict(), "seed %d step %d" % [seed_value, i])
		# A hint on screen at the end.
		s.close_hint()
		s.buy_hint(_hint())
		_assert_exact(GameSession.snapshot_to_dict(s.save_snapshot()), s.to_dict(), "seed %d with hint" % seed_value)


func test_snapshot_survives_more_play() -> void:
	# A snapshot taken now still converts to the to_dict() of now, whatever the
	# session does afterwards: undo, Auto Cross toggles, new steps, hints.
	for seed_value: int in [11, 12, 13]:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = seed_value
		var s: GameSession = F.session_b(true)
		for i: int in 800:
			_random_action(s, rng)
		s.close_hint()
		s.buy_hint(_hint())
		var expected: Dictionary = s.to_dict()
		var text: String = var_to_str(expected)
		var snapshot: Dictionary = s.save_snapshot()
		while s.can_undo():
			s.undo()
		s.set_auto_cross(false)
		s.set_auto_cross(true)
		for i: int in 800:
			_random_action(s, rng)
		while s.can_undo():
			s.undo()
			s.set_auto_cross(not s.auto_cross)
		_assert_exact(GameSession.snapshot_to_dict(snapshot), expected, "seed %d after more play" % seed_value)
		assert_eq(var_to_str(expected), text, "to_dict result is not shared with the session")


func test_conversion_does_not_change_the_snapshot() -> void:
	var s: GameSession = _session_with_steps(30)
	var snapshot: Dictionary = s.save_snapshot()
	var first: Dictionary = GameSession.snapshot_to_dict(snapshot)
	assert_true((snapshot["undo"] as Array)[0] is UndoStep, "snapshot still holds steps")
	_assert_exact(GameSession.snapshot_to_dict(snapshot), first, "converting twice")
	_assert_exact(GameSession.snapshot_to_dict(first), first, "converting a converted dict")
	assert_eq(GameSession.snapshot_to_dict({}), {"undo": []})


func test_snapshot_loads_like_to_dict() -> void:
	var s: GameSession = _session_with_steps(200)
	var data: Variant = JSON.parse_string(JSON.stringify(GameSession.snapshot_to_dict(s.save_snapshot())))
	var loaded: GameSession = GameSession.from_dict(data)
	assert_ne(loaded, null)
	if loaded != null:
		assert_eq(JSON.stringify(loaded.to_dict()), JSON.stringify(s.to_dict()), "loaded")


func test_convert_on_worker_thread_while_playing() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 21
	var s: GameSession = _session_with_steps(2000)
	var expected: Dictionary = s.to_dict()
	var snapshot: Dictionary = s.save_snapshot()
	var thread: Thread = Thread.new()
	thread.start(GameSession.snapshot_to_dict.bind(snapshot))
	# The main thread keeps playing and undoing meanwhile.
	for i: int in 400:
		_random_action(s, rng)
		s.undo()
	var converted: Variant = thread.wait_to_finish()
	assert_eq(typeof(converted), TYPE_DICTIONARY)
	if typeof(converted) == TYPE_DICTIONARY:
		_assert_exact(converted, expected, "worker thread")


# Timing -----------------------------------------------------------------------

func test_snapshot_timing() -> void:
	# Prints the cost on this machine; the only checks are the step count and
	# that the snapshot still converts exactly.
	for count: int in [100, 1000, 2000]:
		var s: GameSession = _session_with_steps(count)
		assert_eq(_undo_count(s), count)
		var runs: int = 20
		var start: int = Time.get_ticks_usec()
		var snapshot: Dictionary = {}
		for i: int in runs:
			snapshot = s.save_snapshot()
		var snap_us: float = float(Time.get_ticks_usec() - start) / runs
		start = Time.get_ticks_usec()
		var converted: Dictionary = {}
		for i: int in runs:
			converted = GameSession.snapshot_to_dict(snapshot)
		var convert_us: float = float(Time.get_ticks_usec() - start) / runs
		start = Time.get_ticks_usec()
		var full: Dictionary = {}
		for i: int in runs:
			full = s.to_dict()
		var full_us: float = float(Time.get_ticks_usec() - start) / runs
		print("  save timing, %d steps: save_snapshot %.3f ms, snapshot_to_dict %.3f ms, to_dict %.3f ms" \
			% [count, snap_us / 1000.0, convert_us / 1000.0, full_us / 1000.0])
		_assert_exact(converted, full, "%d steps" % count)
