class_name Lesson
extends RefCounted
## One validated lesson (docs/ARCHITECTURE.md section 10). Built only by
## LessonLibrary from a file in src/lessons/data/.
## Owner: lessons-dev.

## "lesson_01" to "lesson_99", matching number.
var id: String = ""
var number: int = 0
var title: String = ""
var subtitle: String = ""
## The full grid every screen's position agrees with.
var solution: PackedInt32Array = PackedInt32Array()
var screens: Array[LessonScreen] = []
