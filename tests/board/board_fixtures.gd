extends RefCounted
## Shared setup for the board tests. Not a test file (no test_ prefix).

const LIGHT_PATH: String = "res://src/skins/pop_light.tres"
const DARK_PATH: String = "res://src/skins/pop_dark.tres"

## Position B (GDD 4.4): r5c1 9, r5c8 3, r1c5 4, r8c5 6, r4c4 2, r4c6 4, r6c6 3,
## as 0-based cells and digits.
const POSITION_B: Array[Vector2i] = [
	Vector2i(36, 9), Vector2i(43, 3), Vector2i(4, 4), Vector2i(67, 6),
	Vector2i(30, 2), Vector2i(32, 4), Vector2i(50, 3),
]
## One full grid that agrees with Position B.
const SOLUTION_B: String = "735146892691528347482739651378254169924617538156893274869371425517462983243985716"


## Counts clicks in place of the Audio autoload.
class FakeAudio extends Node:
	var clicks: int = 0

	func play_click() -> void:
		clicks += 1


static func light() -> GameSkin:
	return load(LIGHT_PATH) as GameSkin


static func dark() -> GameSkin:
	return load(DARK_PATH) as GameSkin


static func root() -> Window:
	return (Engine.get_main_loop() as SceneTree).root


static func grid(text: String) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(81)
	for i: int in 81:
		out[i] = 0 if text[i] == "." else int(text[i])
	return out


static func position_b() -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(81)
	out.fill(0)
	for entry: Vector2i in POSITION_B:
		out[entry.x] = entry.y
	return out


## A Beginner session on Position B.
static func session_b(auto_cross: bool = false) -> GameSession:
	return GameSession.create("1.0.1", 0, position_b(), grid(SOLUTION_B), auto_cross)


## A session whose only empty cell is the given one.
static func one_left(empty_cell: int) -> GameSession:
	var givens: PackedInt32Array = grid(SOLUTION_B)
	givens[empty_cell] = 0
	return GameSession.create("1.0.2", 0, givens, grid(SOLUTION_B), false)


static func solution_digit(cell: int) -> int:
	return int(SOLUTION_B[cell])


## A press of the left mouse button at a local point.
static func press(at: Vector2) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = at
	return event


static func release(at: Vector2) -> InputEventMouseButton:
	var event: InputEventMouseButton = press(at)
	event.pressed = false
	return event
