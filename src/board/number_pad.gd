class_name NumberPad extends Control
## The controls under the board (docs/ARCHITECTURE.md section 8, the look in
## docs/DESIGN_SYSTEM.md 7.5): digits 1 to 9 in a 3 by 3 block, and to its
## right the PLACE and CROSS OUT mode buttons over UNDO and ERASE. It only
## reports taps; BoardController maps them to the session and tells the pad
## which mode is on and whether Undo can be used.
##
## Touch areas. Each key's face is the size the layout gives it (at least
## 40 dp tall), and its touch area reaches half a key gap (space_s / 2) past
## the face on every side, over its own shadow, so every touch area is at
## least 48 dp both ways and touch areas never overlap (DESIGN_SYSTEM.md 4.4).
## The pad's own rect is the faces grown by that half gap, so those edges
## take taps too. The buttons themselves take no input: the pad hit tests
## the touch areas and plays the press motion on the button it hits.
##
## The mode buttons: tapping the one that is off emits mode_pressed; tapping
## the one already on does nothing, like any tap that changes nothing.
##
## With Show candidates off (set_mode_visible(false), DESIGN_SYSTEM.md 7.5)
## the mode buttons hide and have no touch area; UNDO on top and ERASE below
## fill the right column, each 1.5 keys plus half a gap tall, icon left of
## the caption. Nothing else moves.
##
## Scene: scenes/board/number_pad.tscn. Owner: board-input-dev.

signal digit_pressed(digit: int)
signal mode_pressed()
signal erase_pressed()
signal undo_pressed()

const Support := preload("res://src/board/board_support.gd")

const MODE: StringName = &"mode"
const PLACE: StringName = &"place"
const CROSS_OUT: StringName = &"cross_out"
const ERASE: StringName = &"erase"
const UNDO: StringName = &"undo"
## The 3 by 3 digit block as one area (lesson data names it "pad").
const PAD: StringName = &"pad"

## The skin whose spacing the pad lays out with. Null means the Skins
## autoload's current skin; tests and captures set one directly.
var skin: GameSkin = null:
	set(value):
		skin = value
		_layout()

var _mode: int = GameSession.Mode.PLACE
var _undo_enabled: bool = false
var _locked: bool = false
var _mode_visible: bool = true

var _digits: Array[Button] = []
var _place: Button = null
var _cross: Button = null
var _undo: Button = null
var _erase: Button = null
## Faces and touch areas in local coordinates, keyed by control name
## ("pad:4", "place"). The faces are where the layout puts the buttons; a
## button whose theme content needs more room still reports its face here.
var _faces: Dictionary[StringName, Rect2] = {}
var _touch: Dictionary[StringName, Rect2] = {}
var _watched_service: Node = null
var _presses: Array[Tween] = []
## The size the faces were last placed for, so a query after a resize the
## pad was not told about (outside the tree) lays it out first.
var _laid_out_for: Vector2 = Vector2(-1.0, -1.0)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	for d: int in range(1, 10):
		var key: Button = _make_button("Digit%d" % d, ThemeFactory.PAD_KEY_PLACE)
		key.text = str(d)
		_digits.append(key)
	_place = _make_button("Place", ThemeFactory.MODE_BUTTON)
	_place.toggle_mode = true
	_place.text = ThemeFactory.display_text(ThemeFactory.MODE_BUTTON, "Place")
	_place.icon = Icons.texture(Icons.MODE_PLACE)
	_cross = _make_button("CrossOut", ThemeFactory.MODE_BUTTON)
	_cross.toggle_mode = true
	_cross.text = ThemeFactory.display_text(ThemeFactory.MODE_BUTTON, "Cross out")
	_cross.icon = Icons.texture(Icons.MODE_CROSS_OUT)
	_undo = _make_button("Undo", ThemeFactory.PAD_ACTION)
	_undo.text = ThemeFactory.display_text(ThemeFactory.PAD_ACTION, "Undo")
	_undo.icon = Icons.texture(Icons.UNDO)
	_undo.expand_icon = true
	_erase = _make_button("Erase", ThemeFactory.PAD_ACTION)
	_erase.text = ThemeFactory.display_text(ThemeFactory.PAD_ACTION, "Erase")
	_erase.icon = Icons.texture(Icons.ERASE)
	_erase.expand_icon = true
	_show_mode()
	_align_actions()
	_undo.disabled = true


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED, NOTIFICATION_THEME_CHANGED:
			_layout()
		NOTIFICATION_ENTER_TREE:
			_watch_skins(Support.skin_service(self))
			_layout()
		NOTIFICATION_EXIT_TREE:
			_watch_skins(null)
		NOTIFICATION_PREDELETE:
			# Outside the tree Motion runs presses on the SceneTree, where
			# they would outlive the pad.
			for tween: Tween in _presses:
				if tween.is_valid():
					tween.kill()


func _gui_input(event: InputEvent) -> void:
	var at: Variant = Support.press_position(event)
	if at == null:
		return
	accept_event()
	tap(at as Vector2)


## Handles a press at a local point, as a touch or click there would.
func tap(point: Vector2) -> void:
	if _locked:
		return
	var control: StringName = control_at(point)
	if control == &"":
		return
	if String(control).begins_with("pad:"):
		var d: int = String(control).substr(4).to_int()
		_press(_digits[d - 1])
		digit_pressed.emit(d)
	elif control == PLACE or control == CROSS_OUT:
		var wanted: int = GameSession.Mode.PLACE if control == PLACE else GameSession.Mode.CROSS_OUT
		if wanted != _mode:
			mode_pressed.emit()
	elif control == ERASE:
		_press(_erase)
		erase_pressed.emit()
	elif control == UNDO:
		if _undo_enabled:
			_press(_undo)
			undo_pressed.emit()


## The control whose touch area holds a local point: "pad:1" to "pad:9",
## "place", "cross_out", "undo", "erase", or "" for none.
func control_at(point: Vector2) -> StringName:
	_ensure_layout()
	for control: StringName in _touch:
		if _touch[control].has_point(point):
			return control
	return &""


## Shows which mode is on: the active mode button sinks, and the digit keys
## take the Place or Cross Out key look (DESIGN_SYSTEM.md 7.5).
func set_mode(mode: int) -> void:
	_mode = GameSession.Mode.CROSS_OUT if mode == GameSession.Mode.CROSS_OUT else GameSession.Mode.PLACE
	_show_mode()


func set_undo_enabled(enabled: bool) -> void:
	_undo_enabled = enabled
	_undo.disabled = not enabled


## After completion every tap is ignored.
func set_locked(locked: bool) -> void:
	_locked = locked


## False hides PLACE and CROSS OUT (Show candidates off); UNDO and ERASE
## then take the whole right column. Lessons never hide them.
func set_mode_visible(visible: bool) -> void:
	if visible == _mode_visible:
		return
	_mode_visible = visible
	_place.visible = visible
	_cross.visible = visible
	_align_actions()
	_layout()


func is_mode_visible() -> bool:
	return _mode_visible


func mode() -> int:
	return _mode


func is_undo_enabled() -> bool:
	return _undo_enabled


func is_locked() -> bool:
	return _locked


## A control's face on screen, for lesson pointers: "mode" (both mode
## buttons together), "place", "cross_out", "erase", "undo", "pad:1" to
## "pad:9", or "pad" (the digit block). An empty Rect2 for any other name,
## and for "mode", "place" and "cross_out" while the mode buttons are hidden.
func control_rect_global(control: StringName) -> Rect2:
	var local: Rect2 = _face_rect(control)
	if not local.has_area():
		return Rect2()
	return get_global_transform() * local


## A control's touch area on screen, the same names as control_rect_global
## except "mode" and "pad", which are not single controls.
func touch_rect_global(control: StringName) -> Rect2:
	_ensure_layout()
	if not _touch.has(control):
		return Rect2()
	return get_global_transform() * _touch[control]


func _face_rect(control: StringName) -> Rect2:
	_ensure_layout()
	match control:
		MODE:
			return _faces.get(PLACE, Rect2()).merge(_faces.get(CROSS_OUT, Rect2()))
		PAD:
			return _faces.get(&"pad:1", Rect2()).merge(_faces.get(&"pad:9", Rect2()))
	return _faces.get(control, Rect2())


func _press(button: Button) -> void:
	var tween: Tween = Motion.press(button)
	if tween == null:
		return
	_presses.assign(_presses.filter(func(running: Tween) -> bool: return running.is_valid()))
	_presses.append(tween)


func _make_button(node_name: String, variation: StringName) -> Button:
	var button: Button = Button.new()
	button.name = node_name
	button.theme_type_variation = variation
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.focus_mode = Control.FOCUS_NONE
	# Godot counts an icon and its label side by side for a button's minimum
	# width even when the icon sits above the label, which would push the
	# face into its neighbor. Clipping keeps the face at its layout width.
	button.clip_text = variation != ThemeFactory.PAD_KEY_PLACE
	add_child(button, false, Node.INTERNAL_MODE_FRONT)
	return button


func _show_mode() -> void:
	var variation: StringName = ThemeFactory.PAD_KEY_CROSS if _mode == GameSession.Mode.CROSS_OUT else ThemeFactory.PAD_KEY_PLACE
	for key: Button in _digits:
		key.theme_type_variation = variation
	_place.set_pressed_no_signal(_mode == GameSession.Mode.PLACE)
	_cross.set_pressed_no_signal(_mode == GameSession.Mode.CROSS_OUT)


## Undo and Erase put the icon over the caption on their small faces beside
## the mode buttons, and to the left of it, as the mode buttons do, on the
## tall faces they get when the mode buttons hide (DESIGN_SYSTEM.md 7.5).
func _align_actions() -> void:
	for button: Button in [_undo, _erase]:
		if _mode_visible:
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
			button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT


## Places every face from the pad's size (DESIGN_SYSTEM.md 4.7 widths): the
## three digit columns, the group gap and the right column share the width,
## the right column ACTION_RATIO times a key, clamped to ACTION_MIN and
## ACTION_MAX. Three rows of keys with space_s between them. With the mode
## buttons hidden, UNDO and ERASE split the right column's height instead.
func _layout() -> void:
	var current: GameSkin = Support.skin_for(self, skin)
	if current == null or _place == null:
		return
	_laid_out_for = size
	var gap: float = current.space_s
	var inset: float = gap * 0.5
	var faces_w: float = maxf(0.0, size.x - 2.0 * inset - current.shadow_offset)
	var key_h: float = maxf(0.0, (size.y - 2.0 * inset - 2.0 * gap) / 3.0)
	var rest: float = maxf(0.0, faces_w - 2.0 * gap - current.group_gap)
	var key_w: float = rest / (3.0 + Layout.ACTION_RATIO)
	var action_w: float = Layout.ACTION_RATIO * key_w
	if action_w < Layout.ACTION_MIN or action_w > Layout.ACTION_MAX:
		action_w = minf(clampf(action_w, Layout.ACTION_MIN, Layout.ACTION_MAX), rest)
		key_w = (rest - action_w) / 3.0
	_faces.clear()
	_touch.clear()
	for i: int in 9:
		var face: Rect2 = Rect2(inset + float(i % 3) * (key_w + gap), inset + float(i / 3) * (key_h + gap), key_w, key_h)
		_place_button(_digits[i], face)
		_faces[StringName("pad:%d" % (i + 1))] = face
		_touch[StringName("pad:%d" % (i + 1))] = face.grow(inset)
	var right_x: float = inset + 3.0 * key_w + 2.0 * gap + current.group_gap
	var half_w: float = maxf(0.0, (action_w - gap) * 0.5)
	var faces: Dictionary[StringName, Rect2] = {}
	if _mode_visible:
		faces[PLACE] = Rect2(right_x, inset, action_w, key_h)
		faces[CROSS_OUT] = Rect2(right_x, inset + key_h + gap, action_w, key_h)
		faces[UNDO] = Rect2(right_x, inset + 2.0 * (key_h + gap), half_w, key_h)
		faces[ERASE] = Rect2(right_x + half_w + gap, inset + 2.0 * (key_h + gap), half_w, key_h)
	else:
		var tall: float = 1.5 * key_h + 0.5 * gap
		faces[UNDO] = Rect2(right_x, inset, action_w, tall)
		faces[ERASE] = Rect2(right_x, inset + tall + gap, action_w, tall)
	var buttons: Dictionary[StringName, Button] = {PLACE: _place, CROSS_OUT: _cross, UNDO: _undo, ERASE: _erase}
	for control: StringName in faces:
		_place_button(buttons[control], faces[control])
		_faces[control] = faces[control]
		_touch[control] = faces[control].grow(inset)


func _ensure_layout() -> void:
	if size != _laid_out_for:
		_layout()


func _place_button(button: Button, face: Rect2) -> void:
	button.position = face.position
	button.size = face.size


func _on_skin_changed(_skin: GameSkin) -> void:
	_layout()


func _watch_skins(service: Node) -> void:
	if _watched_service != null and is_instance_valid(_watched_service) \
			and _watched_service.is_connected(&"skin_changed", _on_skin_changed):
		_watched_service.disconnect(&"skin_changed", _on_skin_changed)
	_watched_service = service
	if service != null and service.has_signal(&"skin_changed"):
		service.connect(&"skin_changed", _on_skin_changed)
