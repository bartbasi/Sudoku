extends "res://tests/unit_test.gd"
## SaveWriter (QA M1, security Low 2): saves written on a worker thread, the
## newest data per file only, and write_now, flush and remove always acting
## after every older write, so a deleted file never comes back.

const Fx := preload("res://tests/save/save_fixtures.gd")
## How long a test waits for the worker before it gives up.
const WAIT_MS: int = 10000


func _wait_for_worker(writer: SaveWriter) -> void:
	var waited: int = 0
	while writer.has_pending() and waited < WAIT_MS:
		OS.delay_msec(2)
		waited += 2
	# The worker took the job; holding the write lock waits for the write.
	writer.flush()


func _value_of(path: String) -> Variant:
	var data: Variant = SaveStore.read(path, SaveStore.MAX_BYTES_PUZZLE)
	if typeof(data) != TYPE_DICTIONARY:
		return null
	return (data as Dictionary).get("value")


func test_queue_writes_on_the_worker_and_returns_at_once() -> void:
	var dir: String = Fx.fresh_dir("writer_queue")
	var path: String = dir.path_join("a.json")
	var writer: SaveWriter = SaveWriter.new()
	writer.queue(path, {"value": 1}, SaveStore.MAX_BYTES_PUZZLE)
	_wait_for_worker(writer)
	assert_eq(_value_of(path), 1.0, "written by the worker")
	assert_false(FileAccess.file_exists(path + SaveStore.TEMP_SUFFIX), "no temp file left")
	writer.stop()
	Fx.wipe(dir)


func test_data_queued_twice_is_written_once_with_the_newer_data() -> void:
	var dir: String = Fx.fresh_dir("writer_coalesce")
	var path: String = dir.path_join("a.json")
	var writer: SaveWriter = SaveWriter.new()
	# Hold the write lock, as a write in progress would, so the worker waits.
	var lock: Mutex = writer.get(&"_write_lock") as Mutex
	lock.lock()
	writer.queue(path, {"value": 1}, SaveStore.MAX_BYTES_PUZZLE)
	writer.queue(path, {"value": 2}, SaveStore.MAX_BYTES_PUZZLE)
	writer.queue(path, {"value": 3}, SaveStore.MAX_BYTES_PUZZLE)
	lock.unlock()
	_wait_for_worker(writer)
	assert_eq(_value_of(path), 3.0, "the newest data")
	assert_eq(writer.written_count(), 1, "one write for three queued saves")
	writer.stop()
	Fx.wipe(dir)


func test_flush_writes_everything_queued_before_it() -> void:
	var dir: String = Fx.fresh_dir("writer_flush")
	var writer: SaveWriter = SaveWriter.new()
	var lock: Mutex = writer.get(&"_write_lock") as Mutex
	lock.lock()
	writer.queue(dir.path_join("a.json"), {"value": 1}, SaveStore.MAX_BYTES_PUZZLE)
	writer.queue(dir.path_join("b.json"), {"value": 2}, SaveStore.MAX_BYTES_PUZZLE)
	lock.unlock()
	writer.flush()
	assert_eq(_value_of(dir.path_join("a.json")), 1.0)
	assert_eq(_value_of(dir.path_join("b.json")), 2.0)
	assert_false(writer.has_pending())
	writer.stop()
	Fx.wipe(dir)


func test_write_now_drops_older_queued_data_for_the_file() -> void:
	var dir: String = Fx.fresh_dir("writer_now")
	var path: String = dir.path_join("a.json")
	var writer: SaveWriter = SaveWriter.new()
	var lock: Mutex = writer.get(&"_write_lock") as Mutex
	lock.lock()
	writer.queue(path, {"value": 1}, SaveStore.MAX_BYTES_PUZZLE)
	lock.unlock()
	assert_true(writer.write_now(path, {"value": 2}, SaveStore.MAX_BYTES_PUZZLE))
	assert_eq(_value_of(path), 2.0, "written at once")
	_wait_for_worker(writer)
	assert_eq(_value_of(path), 2.0, "the older queued data never lands after it")
	writer.stop()
	Fx.wipe(dir)


func test_remove_drops_queued_data_so_the_file_never_comes_back() -> void:
	var dir: String = Fx.fresh_dir("writer_remove")
	var path: String = dir.path_join("a.json")
	var writer: SaveWriter = SaveWriter.new()
	writer.write_now(path, {"value": 1}, SaveStore.MAX_BYTES_PUZZLE)
	var lock: Mutex = writer.get(&"_write_lock") as Mutex
	lock.lock()
	writer.queue(path, {"value": 2}, SaveStore.MAX_BYTES_PUZZLE)
	lock.unlock()
	writer.remove(path)
	assert_false(FileAccess.file_exists(path), "deleted")
	_wait_for_worker(writer)
	OS.delay_msec(20)
	writer.flush()
	assert_false(FileAccess.file_exists(path), "the queued save did not bring it back")
	writer.stop()
	Fx.wipe(dir)


func test_remove_waits_for_a_write_in_progress() -> void:
	var dir: String = Fx.fresh_dir("writer_inflight")
	var path: String = dir.path_join("a.json")
	var writer: SaveWriter = SaveWriter.new()
	# A large save keeps the worker busy for a while.
	var big: Array = []
	for i: int in 200000:
		big.append(i)
	writer.queue(path, {"value": big}, SaveStore.MAX_BYTES_PUZZLE)
	var waited: int = 0
	while writer.has_pending() and waited < WAIT_MS:
		OS.delay_msec(1)
		waited += 1
	writer.remove(path)
	OS.delay_msec(20)
	assert_false(FileAccess.file_exists(path), "gone, not written back after the delete")
	assert_false(FileAccess.file_exists(path + SaveStore.TEMP_SUFFIX), "no temp file either")
	writer.stop()
	Fx.wipe(dir)


func test_stop_writes_what_is_queued_and_later_saves_write_at_once() -> void:
	var dir: String = Fx.fresh_dir("writer_stop")
	var path: String = dir.path_join("a.json")
	var writer: SaveWriter = SaveWriter.new()
	var lock: Mutex = writer.get(&"_write_lock") as Mutex
	lock.lock()
	writer.queue(path, {"value": 1}, SaveStore.MAX_BYTES_PUZZLE)
	lock.unlock()
	writer.stop()
	assert_eq(_value_of(path), 1.0, "written before the worker ended")
	writer.queue(path, {"value": 2}, SaveStore.MAX_BYTES_PUZZLE)
	assert_eq(_value_of(path), 2.0, "after stop, written at once")
	assert_false(writer.has_pending())
	Fx.wipe(dir)


func test_data_over_the_limit_is_not_written_and_the_old_file_stays() -> void:
	var dir: String = Fx.fresh_dir("writer_limit")
	var path: String = dir.path_join("a.json")
	var writer: SaveWriter = SaveWriter.new()
	writer.write_now(path, {"value": 1}, 1000)
	assert_false(writer.write_now(path, {"value": "x".repeat(2000)}, 1000), "refused")
	writer.queue(path, {"value": "y".repeat(2000)}, 1000)
	_wait_for_worker(writer)
	assert_eq(_value_of(path), 1.0, "the old file stays")
	writer.stop()
	Fx.wipe(dir)
