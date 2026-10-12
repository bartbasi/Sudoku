extends "res://tests/unit_test.gd"
## The Audio autoload script: toggle, no-op when off, safe headless.

const AudioService := preload("res://src/audio/audio_service.gd")


func _make_in_tree() -> Node:
	var service: Node = AudioService.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(service)
	return service


func _drop(service: Node) -> void:
	if service.is_inside_tree():
		service.get_parent().remove_child(service)
	service.free()


func _player(service: Node) -> AudioStreamPlayer:
	return service.get("_player") as AudioStreamPlayer


func test_sound_is_on_by_default() -> void:
	var service: Node = AudioService.new()
	assert_eq(service.get("enabled"), true, "enabled by default")
	service.free()


func test_toggle_state() -> void:
	var service: Node = AudioService.new()
	service.set("enabled", false)
	assert_eq(service.get("enabled"), false, "off")
	service.set("enabled", true)
	assert_eq(service.get("enabled"), true, "on again")
	service.free()


func test_click_stream_is_built_once() -> void:
	var service: Node = _make_in_tree()
	var player: AudioStreamPlayer = _player(service)
	assert_true(player != null, "player exists")
	assert_true(player.stream is AudioStreamWAV, "stream is the synthesized click")
	var before: AudioStream = player.stream
	for i: int in 20:
		service.call("play_click")
	assert_true(player.stream == before, "fast taps reuse the same stream")
	assert_eq(service.get_child_count(), 1, "fast taps add no nodes")
	assert_true(player.max_polyphony <= 2, "overlap is capped")
	_drop(service)


## The runner works inside SceneTree._initialize, where nothing is inside the
## tree yet, so these tests prove play_click never errors and that the toggle
## gates it. Any engine or script error here fails the test.
func test_play_click_when_on_is_safe_headless() -> void:
	var service: Node = _make_in_tree()
	service.call("play_click")
	service.call("play_click")
	assert_eq(service.get("_click_requests"), 2, "both clicks went through the toggle")
	_drop(service)


func test_play_click_when_off_plays_nothing() -> void:
	var service: Node = _make_in_tree()
	service.set("enabled", false)
	for i: int in 5:
		service.call("play_click")
	assert_eq(service.get("_click_requests"), 0, "no click asked for when sound is off")
	assert_false(_player(service).playing, "nothing plays when sound is off")
	service.set("enabled", true)
	service.call("play_click")
	assert_eq(service.get("_click_requests"), 1, "turning sound back on works")
	_drop(service)


func test_play_click_outside_tree_is_safe() -> void:
	var service: Node = AudioService.new()
	service.call("play_click")
	assert_false(_player(service).playing, "nothing plays before the service is in the tree")
	service.free()
