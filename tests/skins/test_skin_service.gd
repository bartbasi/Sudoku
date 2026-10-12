extends "res://tests/unit_test.gd"
## The Skins autoload script (docs/ARCHITECTURE.md section 6): the list of
## built-in skins, lookup by id, and apply with its fallback and signal.

const SERVICE_PATH: String = "res://src/skins/skin_service.gd"


func _service() -> Node:
	var script: GDScript = load(SERVICE_PATH) as GDScript
	return script.new() as Node


func test_all_lists_the_built_in_skins_in_display_order() -> void:
	var service: Node = _service()
	var skins: Array[GameSkin] = service.all()
	assert_eq(skins.size(), 2, "number of skins")
	if skins.size() == 2:
		assert_eq(skins[0].id, &"pop_light")
		assert_eq(skins[1].id, &"pop_dark")
		assert_eq(skins[0].display_name, "Light")
		assert_eq(skins[1].display_name, "Dark")
		assert_false(skins[0].is_dark)
		assert_true(skins[1].is_dark)
	skins.clear()
	assert_eq(service.all().size(), 2, "all() hands out a copy")
	service.free()


func test_current_starts_as_the_default_skin() -> void:
	var service: Node = _service()
	assert_eq(service.DEFAULT_ID, &"pop_light")
	var current: GameSkin = service.current
	assert_true(current != null, "current is set before the autoload enters the tree")
	if current != null:
		assert_eq(current.id, &"pop_light")
	service.free()


func test_get_skin_finds_known_ids_only() -> void:
	var service: Node = _service()
	var dark: GameSkin = service.get_skin(&"pop_dark")
	assert_true(dark != null and dark.id == &"pop_dark", "pop_dark")
	assert_true(service.get_skin(&"pop_light") != null, "pop_light")
	assert_true(service.get_skin(&"neon") == null, "unknown id")
	assert_true(service.get_skin(&"") == null, "empty id")
	service.free()


func test_apply_switches_and_emits() -> void:
	var service: Node = _service()
	var seen: Array[GameSkin] = []
	service.skin_changed.connect(func(skin: GameSkin) -> void: seen.append(skin))
	service.apply(&"pop_dark")
	var current: GameSkin = service.current
	assert_eq(current.id, &"pop_dark", "current after apply")
	assert_eq(seen.size(), 1, "one signal")
	if seen.size() == 1:
		assert_true(seen[0] == current, "the signal carries the current skin")
	service.apply(&"pop_light")
	current = service.current
	assert_eq(current.id, &"pop_light")
	assert_eq(seen.size(), 2)
	service.free()


func test_apply_falls_back_to_the_default_for_unknown_ids() -> void:
	var service: Node = _service()
	service.apply(&"pop_dark")
	var seen: Array[GameSkin] = []
	service.skin_changed.connect(func(skin: GameSkin) -> void: seen.append(skin))
	service.apply(&"does_not_exist")
	var current: GameSkin = service.current
	assert_eq(current.id, &"pop_light", "unknown id falls back to pop_light")
	assert_eq(seen.size(), 1, "the fallback still emits")
	service.free()
