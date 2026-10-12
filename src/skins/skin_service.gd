extends Node
## The "Skins" autoload: the built-in skins and the one in use
## (docs/ARCHITECTURE.md section 6). Skins are built in only; nothing is ever
## loaded from outside res://.

signal skin_changed(skin: GameSkin)

const DEFAULT_ID := &"pop_light"

## The built-in skin files, in display order.
const SKIN_PATHS: Array[String] = [
	"res://src/skins/pop_light.tres",
	"res://src/skins/pop_dark.tres",
]

var current: GameSkin

var _skins: Array[GameSkin] = []


func _init() -> void:
	for path: String in SKIN_PATHS:
		var skin: GameSkin = load(path) as GameSkin
		if skin == null:
			push_error("Skins: %s does not load as a GameSkin" % path)
			continue
		_skins.append(skin)
	current = get_skin(DEFAULT_ID)
	if current == null and not _skins.is_empty():
		current = _skins[0]


## Every built-in skin, in display order: pop_light, pop_dark.
func all() -> Array[GameSkin]:
	return _skins.duplicate()


## The skin with this id, or null if there is none.
func get_skin(id: StringName) -> GameSkin:
	for skin: GameSkin in _skins:
		if skin.id == id:
			return skin
	return null


## Makes the skin with this id current. An unknown id falls back to
## DEFAULT_ID. Always emits skin_changed.
func apply(id: StringName) -> void:
	var skin: GameSkin = get_skin(id)
	if skin == null:
		skin = get_skin(DEFAULT_ID)
	if skin == null:
		push_error("Skins: the default skin %s is missing" % DEFAULT_ID)
		return
	current = skin
	skin_changed.emit(current)
