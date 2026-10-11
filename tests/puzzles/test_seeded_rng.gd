extends "res://tests/unit_test.gd"
## SeededRng gives the same sequence for the same seed, everywhere. The golden
## values below were checked against an independent implementation of
## xoshiro128** with the same seeding; if they change, every puzzle ID changes.


func _first(seed_value: int, count: int) -> PackedInt64Array:
	var rng: SeededRng = SeededRng.new(seed_value)
	var out: PackedInt64Array = PackedInt64Array()
	for k: int in count:
		out.append(rng.next_u32())
	return out


func test_golden_values() -> void:
	assert_eq(_first(0, 5), PackedInt64Array([2784280318, 1840320879, 3501601933, 2284444085, 3451292126]))
	assert_eq(_first(1, 5), PackedInt64Array([2683346529, 259097878, 2900082871, 909592095, 1367094967]))
	assert_eq(_first(12345, 5), PackedInt64Array([1603689063, 961396028, 3884907255, 4232687519, 3321026810]))
	assert_eq(_first(4294967295, 5), PackedInt64Array([3966350106, 1450154206, 73790565, 226299766, 1041249164]))


func test_negative_and_64_bit_seeds_work() -> void:
	assert_eq(_first(-1, 5), PackedInt64Array([528988879, 4244955438, 4097912560, 2176554539, 34947682]))
	assert_eq(_first((1 << 40) + 7, 5), PackedInt64Array([4015426479, 479116193, 2707316102, 3482988700, 576669045]))


func test_same_seed_same_sequence_and_set_seed_restarts() -> void:
	var a: SeededRng = SeededRng.new(99)
	var b: SeededRng = SeededRng.new(99)
	var first: PackedInt64Array = PackedInt64Array()
	for k: int in 200:
		var value: int = a.next_u32()
		first.append(value)
		assert_eq(value, b.next_u32(), "value %d" % k)
	a.set_seed(99)
	for k: int in 200:
		assert_eq(a.next_u32(), first[k], "after set_seed, value %d" % k)


func test_different_seeds_differ() -> void:
	assert_ne(_first(7, 4), _first(8, 4))


func test_values_are_32_bit() -> void:
	var rng: SeededRng = SeededRng.new(5)
	for k: int in 1000:
		var value: int = rng.next_u32()
		assert_true(value >= 0 and value <= 0xFFFFFFFF, "value %d is %d" % [k, value])


func test_next_int_stays_in_range() -> void:
	var rng: SeededRng = SeededRng.new(3)
	for bound: int in [1, 2, 3, 9, 10, 81, 1000]:
		var seen: Dictionary = {}
		for k: int in 400:
			var value: int = rng.next_int(bound)
			assert_true(value >= 0 and value < bound, "next_int(%d) gave %d" % [bound, value])
			seen[value] = true
		if bound <= 10:
			assert_eq(seen.size(), bound, "next_int(%d) reaches every value" % bound)
	assert_eq(rng.next_int(0), 0)
	assert_eq(rng.next_int(-5), 0)


func test_shuffle_is_a_permutation() -> void:
	var rng: SeededRng = SeededRng.new(11)
	var values: PackedInt32Array = PackedInt32Array()
	for i: int in 81:
		values.append(i)
	rng.shuffle(values)
	var original: PackedInt32Array = PackedInt32Array()
	for i: int in 81:
		original.append(i)
	assert_ne(values, original, "shuffle changed the order")
	var sorted: PackedInt32Array = values.duplicate()
	sorted.sort()
	assert_eq(sorted, original)
