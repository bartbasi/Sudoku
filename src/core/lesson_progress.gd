class_name LessonProgress
extends RefCounted
## Which lessons were finished at least once (GDD 13 and 14). Only ids of the
## form lesson_NN (two ASCII digits) are kept.

var _finished: PackedStringArray = PackedStringArray()


func is_finished(lesson_id: String) -> bool:
	return _finished.has(lesson_id)


## True the first time a valid id is marked; false for a repeat or an
## invalid id, which is not stored.
func mark_finished(lesson_id: String) -> bool:
	if not is_valid_id(lesson_id) or _finished.has(lesson_id):
		return false
	_finished.append(lesson_id)
	_finished.sort()
	return true


func finished_count() -> int:
	return _finished.size()


func to_dict() -> Dictionary:
	return {"finished": Array(_finished)}


## Never null. Keeps each valid id once; ignores anything else.
static func from_dict(data: Variant) -> LessonProgress:
	var progress: LessonProgress = LessonProgress.new()
	if typeof(data) != TYPE_DICTIONARY:
		return progress
	var list: Variant = (data as Dictionary).get("finished")
	if typeof(list) != TYPE_ARRAY:
		return progress
	for item: Variant in list:
		if typeof(item) == TYPE_STRING:
			progress.mark_finished(item)
	return progress


## Matches ^lesson_[0-9]{2}$.
static func is_valid_id(lesson_id: String) -> bool:
	if lesson_id.length() != 9 or not lesson_id.begins_with("lesson_"):
		return false
	for i: int in [7, 8]:
		var code: int = lesson_id.unicode_at(i)
		if code < 48 or code > 57:
			return false
	return true
