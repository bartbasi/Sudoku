extends RefCounted
## Base for every test file. Write tests/<area>/test_*.gd files that extend
## "res://tests/unit_test.gd" and add methods whose names start with test_.
## Each test method runs on a fresh instance.

var failures: Array[String] = []


func fail(message: String) -> void:
	failures.append(message)


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		fail(_describe("expected true", message))


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		fail(_describe("expected false", message))


## Equal means same type and same value, so 1 and 1.0 are not equal.
## Arrays and dictionaries compare by content, objects by identity.
func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if not _same(actual, expected):
		fail(_describe("expected %s, got %s" % [_show(expected), _show(actual)], message))


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	if _same(actual, unexpected):
		fail(_describe("did not expect %s" % _show(unexpected), message))


func _same(a: Variant, b: Variant) -> bool:
	return typeof(a) == typeof(b) and a == b


func _show(value: Variant) -> String:
	if value is String or value is StringName:
		return "\"%s\"" % value
	return str(value)


func _describe(what: String, message: String) -> String:
	return what if message.is_empty() else "%s: %s" % [message, what]
