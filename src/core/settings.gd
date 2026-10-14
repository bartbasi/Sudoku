class_name Settings
extends RefCounted
## The player's settings (GDD 14).

## The built-in skins (CLAUDE.md: Pop light, the default, and Pop dark).
const SKIN_IDS: Array[StringName] = [&"pop_light", &"pop_dark"]
const DEFAULT_SKIN_ID := &"pop_light"

var sound: bool = true
var skin_id: StringName = DEFAULT_SKIN_ID
var auto_cross: bool = false
var first_launch_answered: bool = false
## The level of the last puzzle started; PLAY starts here.
var last_level: int = Levels.EASY


func to_dict() -> Dictionary:
	return {
		"sound": sound,
		"skin_id": String(skin_id),
		"auto_cross": auto_cross,
		"first_launch_answered": first_launch_answered,
		"last_level": last_level,
	}


## Never null. Each field that is missing or invalid takes its default; the
## others load as saved.
static func from_dict(data: Variant) -> Settings:
	var settings: Settings = Settings.new()
	if typeof(data) != TYPE_DICTIONARY:
		return settings
	var dict: Dictionary = data
	var sound_value: Variant = dict.get("sound")
	if typeof(sound_value) == TYPE_BOOL:
		settings.sound = sound_value
	var skin_value: Variant = dict.get("skin_id")
	if typeof(skin_value) == TYPE_STRING and SKIN_IDS.has(StringName(String(skin_value))):
		settings.skin_id = StringName(String(skin_value))
	var auto_value: Variant = dict.get("auto_cross")
	if typeof(auto_value) == TYPE_BOOL:
		settings.auto_cross = auto_value
	var answered_value: Variant = dict.get("first_launch_answered")
	if typeof(answered_value) == TYPE_BOOL:
		settings.first_launch_answered = answered_value
	settings.last_level = _level_from(dict.get("last_level"))
	return settings


## An int, or a float with no fractional part (JSON gives floats), that is a
## valid level. Anything else gives the default, Easy.
static func _level_from(value: Variant) -> int:
	if typeof(value) == TYPE_INT:
		var level: int = value
		return level if Levels.is_valid(level) else Levels.EASY
	if typeof(value) == TYPE_FLOAT:
		var number: float = value
		# Range check on the float first, so NaN, infinity and huge values never
		# reach the int conversion.
		if is_finite(number) and number == floorf(number) and number >= 0.0 and number < float(Levels.COUNT):
			return int(number)
	return Levels.EASY
