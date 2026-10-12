extends Control
## The ring around each pad control a lesson screen points at
## (DESIGN_SYSTEM.md 7.13): hint_mark_w wide in hint_reason_mark, 4 dp
## outside the face and its shadow, corners radius_control plus 4, fading
## from full to 35 percent and back (LESSON_PULSE) until the step is done.
## Drawn over the pad; it takes no input.
## Internal to src/lessons: no class_name, preloaded by path.
## Owner: lessons-dev.

## How far the ring sits outside the face and its shadow.
const OUTSET: float = 4.0
const PULSE_LOW: float = 0.35

var pad: NumberPad = null
var skin: GameSkin = null
## NumberPad control names (&"mode", &"pad:9" and so on).
var controls: Array[StringName] = []:
	set(value):
		controls = value.duplicate()
		_restart_pulse()
		queue_redraw()
## The ring's opacity, driven by the pulse.
var pulse: float = 1.0:
	set(value):
		pulse = value
		queue_redraw()

var _tween: Tween = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			_restart_pulse()
		NOTIFICATION_EXIT_TREE:
			_stop_pulse()


## Stops the pulse and hides the rings (the step is done).
func clear() -> void:
	controls = []


func _draw() -> void:
	if pad == null or skin == null or controls.is_empty():
		return
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.draw_center = false
	var color: Color = skin.hint_reason_mark
	color.a *= pulse
	box.border_color = color
	box.set_border_width_all(maxi(1, roundi(skin.hint_mark_w)))
	box.set_corner_radius_all(roundi(skin.radius_control + OUTSET))
	box.anti_aliasing = true
	var to_local: Transform2D = get_global_transform().affine_inverse()
	for control: StringName in controls:
		var face: Rect2 = pad.control_rect_global(control)
		if not face.has_area():
			continue
		var local: Rect2 = to_local * face
		var ring: Rect2 = Rect2(local.position - Vector2(OUTSET, OUTSET),
			local.size + Vector2(2.0 * OUTSET + skin.shadow_offset, 2.0 * OUTSET + skin.shadow_offset))
		draw_style_box(box, ring)


func _restart_pulse() -> void:
	_stop_pulse()
	pulse = 1.0
	if controls.is_empty() or not is_inside_tree():
		return
	var half: float = Motion.LESSON_PULSE * 0.5
	_tween = create_tween().set_loops()
	_tween.tween_property(self, ^"pulse", PULSE_LOW, half).set_trans(Motion.trans(&"LESSON_PULSE")).set_ease(Motion.ease_of(&"LESSON_PULSE"))
	_tween.tween_property(self, ^"pulse", 1.0, half).set_trans(Motion.trans(&"LESSON_PULSE")).set_ease(Motion.ease_of(&"LESSON_PULSE"))


func _stop_pulse() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
