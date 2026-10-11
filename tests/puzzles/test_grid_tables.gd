extends "res://tests/unit_test.gd"
## The constant lookup tables in src/puzzles/grid_tables.gd match tables
## rebuilt here from their definitions.

const Tables := preload("res://src/puzzles/grid_tables.gd")


func test_row_col_box_of_each_cell() -> void:
	for i: int in 81:
		var r: int = i / 9
		var c: int = i % 9
		assert_eq(Tables.ROW_OF[i], r, "row of cell %d" % i)
		assert_eq(Tables.COL_OF[i], c, "column of cell %d" % i)
		assert_eq(Tables.BOX_OF[i], (r / 3) * 3 + c / 3, "box of cell %d" % i)


func test_units_are_boxes_then_rows_then_columns_in_reading_order() -> void:
	var expected: PackedInt32Array = PackedInt32Array()
	for b: int in 9:
		for i: int in 81:
			if Tables.BOX_OF[i] == b:
				expected.append(i)
	for r: int in 9:
		for i: int in 81:
			if Tables.ROW_OF[i] == r:
				expected.append(i)
	for c: int in 9:
		for i: int in 81:
			if Tables.COL_OF[i] == c:
				expected.append(i)
	assert_eq(Tables.UNITS, expected)


func test_peers_are_the_20_cells_sharing_a_group_in_reading_order() -> void:
	var expected: PackedInt32Array = PackedInt32Array()
	for i: int in 81:
		for j: int in 81:
			if j != i and (Tables.ROW_OF[i] == Tables.ROW_OF[j] or Tables.COL_OF[i] == Tables.COL_OF[j] or Tables.BOX_OF[i] == Tables.BOX_OF[j]):
				expected.append(j)
	assert_eq(expected.size(), 81 * 20)
	assert_eq(Tables.PEERS, expected)


func test_popcount_and_lowest_digit() -> void:
	assert_eq(Tables.POPCOUNT.size(), 512)
	assert_eq(Tables.LOWEST_DIGIT.size(), 512)
	for mask: int in 512:
		var count: int = 0
		var lowest: int = 0
		for d: int in range(9, 0, -1):
			if mask & (1 << (d - 1)):
				count += 1
				lowest = d
		assert_eq(Tables.POPCOUNT[mask], count, "popcount of %d" % mask)
		assert_eq(Tables.LOWEST_DIGIT[mask], lowest, "lowest digit of %d" % mask)
