extends RefCounted
## Small checks shared by every from_dict in core. Save data is untrusted, so
## each value is checked for type and range before it is used.
## No class_name: preload it by path.
##
## JSON gives every number back as a float, so an "int" here is a real int or
## a float with no fraction, inside the range a float holds exactly.

const MAX_EXACT := 9007199254740991  # 2^53 - 1


static func is_int(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return absi(value) <= MAX_EXACT
	if typeof(value) == TYPE_FLOAT:
		var number: float = value
		return is_finite(number) and number == floorf(number) and absf(number) <= float(MAX_EXACT)
	return false


static func int_in(value: Variant, low: int, high: int) -> bool:
	if not is_int(value):
		return false
	var number: int = int(value)
	return number >= low and number <= high


## A finite number (int or float) from low to high.
static func number_in(value: Variant, low: float, high: float) -> bool:
	var number: float = 0.0
	if typeof(value) == TYPE_INT:
		number = float(int(value))
	elif typeof(value) == TYPE_FLOAT:
		number = value
	else:
		return false
	return is_finite(number) and number >= low and number <= high


## A String (not a StringName) of at most max_length characters.
static func is_text(value: Variant, max_length: int) -> bool:
	return typeof(value) == TYPE_STRING and String(value).length() <= max_length


## Digits 0 to 9 as text, one character each.
static func ints_to_text(values: PackedInt32Array) -> String:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(values.size())
	for i: int in values.size():
		bytes[i] = 48 + clampi(values[i], 0, 9)
	return bytes.get_string_from_ascii()


static func bytes_to_text(values: PackedByteArray) -> String:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(values.size())
	for i: int in values.size():
		bytes[i] = 48 + clampi(values[i], 0, 9)
	return bytes.get_string_from_ascii()


## Reads text of exactly length characters, each "0" to max_digit.
## Returns an empty array if anything is wrong.
static func text_to_ints(value: Variant, length: int, max_digit: int) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	if typeof(value) != TYPE_STRING:
		return out
	var text: String = value
	if text.length() != length:
		return out
	out.resize(length)
	for i: int in length:
		var code: int = text.unicode_at(i)
		if code < 48 or code > 48 + max_digit:
			return PackedInt32Array()
		out[i] = code - 48
	return out


## Reads an array of ints, each from low to high, at most max_size of them.
## Returns null if anything is wrong.
static func int_list(value: Variant, low: int, high: int, max_size: int) -> Variant:
	if typeof(value) != TYPE_ARRAY:
		return null
	var items: Array = value
	if items.size() > max_size:
		return null
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(items.size())
	for i: int in items.size():
		if not int_in(items[i], low, high):
			return null
		out[i] = int(items[i])
	return out
