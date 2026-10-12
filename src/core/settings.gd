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


func to_dict() -> Dictionary:
	return {
		"sound": sound,
		"skin_id": String(skin_id),
		"auto_cross": auto_cross,
		"first_launch_answered": first_launch_answered,
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
	return settings
