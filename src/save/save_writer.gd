class_name SaveWriter
extends RefCounted
## Writes save files on a worker thread, so a long undo history never stalls
## a tap (QA M1). The caller hands data over with queue(); the worker turns it
## into JSON and writes it through SaveStore.write. queue() may also take a
## conversion that the worker runs on the data first: App hands over a cheap
## GameSession.save_snapshot() and lets the worker run snapshot_to_dict(),
## so the main thread never builds the undo history's dictionaries. Only the
## newest data per file is kept: a file queued twice before the worker gets
## to it is written once, with the newer data.
##
## write_now(), flush() and remove() run on the calling thread and wait for
## a write in progress, so they always act after every older write. Use them
## on the lifecycle events, when leaving the play screen, and before deleting
## a file: a queued write can never bring a deleted file back.
##
## Two locks: _pending_lock guards the queue and is only held for a moment,
## so queue() never waits for the disk. _write_lock is held for a whole
## write, by the worker and by the calling thread alike, and is always taken
## before _pending_lock.
## Owner: ui-systems-dev.

var _pending_lock: Mutex = Mutex.new()
var _write_lock: Mutex = Mutex.new()
var _wake: Semaphore = Semaphore.new()
var _thread: Thread = null
## Path to [data, max_bytes, convert], newest data only. Guarded by
## _pending_lock. convert is a Callable taking and returning a Dictionary,
## or an empty Callable.
var _pending: Dictionary[String, Array] = {}
var _stopping: bool = false
## How many writes this writer finished, in either thread. For tests.
var _written: int = 0


## Hands data to the worker. The caller must not change data afterwards.
## Returns at once; the file is written soon after on the worker thread.
## When convert is given, the worker writes convert.call(data) instead: it
## must be safe on a worker thread and return a Dictionary.
func queue(path: String, data: Dictionary, max_bytes: int, convert: Callable = Callable()) -> void:
	_pending_lock.lock()
	if _stopping:
		_pending_lock.unlock()
		_write_job(path, data, max_bytes, convert)
		return
	_pending[path] = [data, max_bytes, convert]
	_pending_lock.unlock()
	if _thread == null:
		_thread = Thread.new()
		if _thread.start(_run) != OK:
			_thread = null
			flush()
			return
	_wake.post()


## Writes data to path now, on this thread, after any write in progress.
## Older queued data for the same path is dropped. Returns SaveStore.write's
## result.
func write_now(path: String, data: Dictionary, max_bytes: int) -> bool:
	_write_lock.lock()
	_pending_lock.lock()
	_pending.erase(path)
	_pending_lock.unlock()
	var ok: bool = SaveStore.write(path, data, max_bytes)
	_written += 1
	_write_lock.unlock()
	return ok


## Writes everything still queued, on this thread, after any write in
## progress. When it returns, every queue() call before it is on disk.
func flush() -> void:
	_write_lock.lock()
	_write_pending()
	_write_lock.unlock()


## Drops queued data for path, waits for a write in progress, then deletes
## the file (SaveStore.remove).
func remove(path: String) -> void:
	_write_lock.lock()
	_pending_lock.lock()
	_pending.erase(path)
	_pending_lock.unlock()
	SaveStore.remove(path)
	_write_lock.unlock()


## True while queued data waits for the worker.
func has_pending() -> bool:
	_pending_lock.lock()
	var waiting: bool = not _pending.is_empty()
	_pending_lock.unlock()
	return waiting


func written_count() -> int:
	_write_lock.lock()
	var count: int = _written
	_write_lock.unlock()
	return count


## Writes what is queued and ends the worker. Later queue() calls write at
## once on the calling thread.
func stop() -> void:
	_pending_lock.lock()
	_stopping = true
	_pending_lock.unlock()
	if _thread != null:
		_wake.post()
		_thread.wait_to_finish()
		_thread = null
	flush()


func _run() -> void:
	while true:
		_wake.wait()
		_write_lock.lock()
		_write_pending()
		_write_lock.unlock()
		_pending_lock.lock()
		var done: bool = _stopping
		_pending_lock.unlock()
		if done:
			return


## Call with _write_lock held.
func _write_pending() -> void:
	_pending_lock.lock()
	var jobs: Dictionary[String, Array] = _pending
	_pending = {}
	_pending_lock.unlock()
	for path: String in jobs:
		var job: Array = jobs[path]
		if not _write_job(path, job[0] as Dictionary, int(job[1]), job[2] as Callable):
			push_warning("SaveWriter: %s was not written; the older file stays" % path)
		_written += 1


## data, or convert.call(data) when convert is valid. Null when convert
## gives anything but a Dictionary: then nothing is written and the older
## file stays.
static func _converted(data: Dictionary, convert: Callable) -> Variant:
	if not convert.is_valid():
		return data
	var out: Variant = convert.call(data)
	return out if out is Dictionary else null


## Writes data, converted first if convert is valid. False when it was not
## written.
static func _write_job(path: String, data: Dictionary, max_bytes: int, convert: Callable) -> bool:
	var out: Variant = _converted(data, convert)
	if out == null:
		return false
	return SaveStore.write(path, out as Dictionary, max_bytes)
