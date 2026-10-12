class_name SaveStore
extends RefCounted
## Reads and writes the save files (docs/ARCHITECTURE.md section 12).
##
## Every file is JSON text of the form {"format": 1, "data": {...}}. Save data
## is untrusted input: it is read only with Godot's JSON class, so nothing in
## a file can create an object or run code. read() hands back the plain
## "data" value, and the caller's from_dict validates every field.
##
## Writes are atomic: the text goes to path + ".tmp", the file is flushed and
## closed, and then the temporary file is renamed over path. A crash in the
## middle leaves the old file as it was. write() refuses anything larger
## than read() accepts. Only paths under user:// are allowed. SaveWriter
## runs write() on a worker thread for the puzzle in progress.
## Owner: ui-systems-dev.

const FORMAT: int = 1
## 16 MiB: undo history has no limit (GDD 7).
const MAX_BYTES_PUZZLE: int = 16777216
## 256 KiB for settings, stats and lessons.
const MAX_BYTES_OTHER: int = 262144
const TEMP_SUFFIX: String = ".tmp"
const ROOT: String = "user://"


## The "data" value of the file, or null when the file is missing, empty,
## larger than max_bytes, holds a NUL byte, is not JSON, not {"format": 1, "data": {...}},
## or the path is not an allowed save path.
static func read(path: String, max_bytes: int) -> Variant:
	if not is_allowed_path(path) or not FileAccess.file_exists(path):
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var length: int = file.get_length()
	if length <= 0 or length > max_bytes:
		file.close()
		return null
	var bytes: PackedByteArray = file.get_buffer(length)
	file.close()
	if bytes.size() != length or bytes.has(0):
		return null
	var json: JSON = JSON.new()
	if json.parse(bytes.get_string_from_utf8()) != OK:
		return null
	var root: Variant = json.data
	if typeof(root) != TYPE_DICTIONARY:
		return null
	var dict: Dictionary = root
	if dict.size() != 2:
		return null
	var format: Variant = dict.get("format")
	if not ((typeof(format) == TYPE_FLOAT or typeof(format) == TYPE_INT) and float(format) == float(FORMAT)):
		return null
	var data: Variant = dict.get("data")
	if typeof(data) != TYPE_DICTIONARY:
		return null
	return data


## Writes {"format": 1, "data": data} to path atomically: path + ".tmp"
## first, flushed and closed, then renamed over path. Returns false, and
## leaves the old file in place, if anything fails, or if the text would be
## larger than max_bytes: read() would drop such a file, so the older one
## that it can still load is kept instead. Pass the same max_bytes the file
## is read with. Safe to call from a worker thread.
##
## Durability: flush() hands Godot's buffer to the operating system before
## the file closes, and the rename happens only after a clean close with no
## error, so a crash or a kill of the app never leaves a half written file
## under path. Godot has no call that forces the data onto the storage
## device (fsync), so after a sudden power loss some file systems may still
## lose the newest write; read() then rejects the damaged file and that part
## falls back to its default.
static func write(path: String, data: Dictionary, max_bytes: int = MAX_BYTES_PUZZLE) -> bool:
	if not is_allowed_path(path):
		return false
	var folder: String = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(folder):
		if DirAccess.make_dir_recursive_absolute(folder) != OK:
			return false
	var bytes: PackedByteArray = JSON.stringify({"format": FORMAT, "data": data}, "", true, true).to_utf8_buffer()
	if bytes.is_empty() or bytes.size() > max_bytes:
		return false
	var temp_path: String = path + TEMP_SUFFIX
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	var stored: bool = file.store_buffer(bytes)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if not stored or error != OK:
		DirAccess.remove_absolute(temp_path)
		return false
	if DirAccess.rename_absolute(temp_path, path) != OK:
		DirAccess.remove_absolute(temp_path)
		return false
	return true


## Deletes the file at path and any temporary file left next to it.
static func remove(path: String) -> void:
	if not is_allowed_path(path):
		return
	for target: String in [path, path + TEMP_SUFFIX]:
		if FileAccess.file_exists(target):
			DirAccess.remove_absolute(target)


## A save path is a .json file under user://, with no "..", no backslash and
## no other scheme.
static func is_allowed_path(path: String) -> bool:
	if not path.begins_with(ROOT) or not path.ends_with(".json"):
		return false
	var rest: String = path.substr(ROOT.length())
	if rest.is_empty() or rest.contains("..") or rest.contains("\\") or rest.contains(":") or rest.begins_with("/"):
		return false
	return true
