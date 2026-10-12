class_name Motion extends RefCounted
## Durations and easing from DESIGN_SYSTEM.md section 6, and the tween helpers
## every area uses. Motion is quick and never blocks input: the helpers never
## change mouse_filter, disable a control or wait for anything. A new call on
## the same thing finishes its running animation at once and starts its own.
##
## Durations are in seconds. CURVES gives each row's Tween transition and ease.
## Owner: ui-motion-artist.

const PRESS_DOWN: float = 0.060
const PRESS_UP: float = 0.140
const PLACE: float = 0.140
const ERASE: float = 0.100
const CROSS: float = 0.100
const RESTORE: float = 0.080
const COMPLETE_WAVE: float = 0.180
const COMPLETE_STAGGER: float = 0.012
const MODE_SWITCH: float = 0.120
const SCORE_CHANGE: float = 0.300
const PANEL_IN: float = 0.200
const PANEL_OUT: float = 0.140
const MARK_POP: float = 0.160
const DIALOG_IN: float = 0.180
const DIALOG_OUT: float = 0.120
const SCREEN_IN: float = 0.200
const SCREEN_OUT: float = 0.120
const PAUSE_IN: float = 0.150
const PAUSE_OUT: float = 0.120
const BURST_IN: float = 0.320
const SOLVED_IN: float = 0.220
const SOLVED_WOBBLE: float = 0.360
const RECEIPT_STAGGER: float = 0.050
const SCORE_COUNT: float = 0.600
const NEW_BEST_IN: float = 0.200
const LESSON_SHAKE: float = 0.240
const PRAISE_IN: float = 0.200
const LESSON_PULSE: float = 1.200

## Details given in the "What moves" column of the same table.
const SCRIM_IN: float = 0.150 ## The scrim fades in over this while a dialog appears.
const RECEIPT_ROW: float = 0.200 ## Each receipt row's own slide and fade.
const DIALOG_FROM_SCALE: float = 0.9 ## A dialog card scales from this to 1.

## Transition and ease per constant: x is the Tween.TransitionType, y the
## Tween.EaseType. COMPLETE_STAGGER is a delay and has none.
const CURVES: Dictionary[StringName, Vector2i] = {
	&"PRESS_DOWN": Vector2i(Tween.TRANS_QUAD, Tween.EASE_OUT),
	&"PRESS_UP": Vector2i(Tween.TRANS_BACK, Tween.EASE_OUT),
	&"PLACE": Vector2i(Tween.TRANS_BACK, Tween.EASE_OUT),
	&"ERASE": Vector2i(Tween.TRANS_QUAD, Tween.EASE_IN),
	&"CROSS": Vector2i(Tween.TRANS_QUAD, Tween.EASE_OUT),
	&"RESTORE": Vector2i(Tween.TRANS_QUAD, Tween.EASE_IN),
	&"COMPLETE_WAVE": Vector2i(Tween.TRANS_SINE, Tween.EASE_IN_OUT),
	&"MODE_SWITCH": Vector2i(Tween.TRANS_QUAD, Tween.EASE_OUT),
	&"SCORE_CHANGE": Vector2i(Tween.TRANS_CUBIC, Tween.EASE_OUT),
	&"PANEL_IN": Vector2i(Tween.TRANS_QUART, Tween.EASE_OUT),
	&"PANEL_OUT": Vector2i(Tween.TRANS_QUART, Tween.EASE_IN),
	&"MARK_POP": Vector2i(Tween.TRANS_BACK, Tween.EASE_OUT),
	&"DIALOG_IN": Vector2i(Tween.TRANS_BACK, Tween.EASE_OUT),
	&"DIALOG_OUT": Vector2i(Tween.TRANS_QUAD, Tween.EASE_IN),
	&"SCREEN_IN": Vector2i(Tween.TRANS_QUART, Tween.EASE_OUT),
	&"SCREEN_OUT": Vector2i(Tween.TRANS_QUAD, Tween.EASE_IN),
	&"PAUSE_IN": Vector2i(Tween.TRANS_QUAD, Tween.EASE_OUT),
	&"PAUSE_OUT": Vector2i(Tween.TRANS_QUAD, Tween.EASE_IN),
	&"BURST_IN": Vector2i(Tween.TRANS_BACK, Tween.EASE_OUT),
	&"SOLVED_IN": Vector2i(Tween.TRANS_BACK, Tween.EASE_OUT),
	&"SOLVED_WOBBLE": Vector2i(Tween.TRANS_SINE, Tween.EASE_OUT),
	&"RECEIPT_STAGGER": Vector2i(Tween.TRANS_QUART, Tween.EASE_OUT),
	&"SCORE_COUNT": Vector2i(Tween.TRANS_QUART, Tween.EASE_OUT),
	&"NEW_BEST_IN": Vector2i(Tween.TRANS_BACK, Tween.EASE_OUT),
	&"LESSON_SHAKE": Vector2i(Tween.TRANS_SINE, Tween.EASE_IN_OUT),
	&"PRAISE_IN": Vector2i(Tween.TRANS_QUART, Tween.EASE_OUT),
	&"LESSON_PULSE": Vector2i(Tween.TRANS_SINE, Tween.EASE_IN_OUT),
}

const _META_PRESS: StringName = &"_motion_press"
const _META_SHOW: StringName = &"_motion_show"
const _META_EFFECTS: StringName = &"_motion_effects"

## Styles a press animates: the raised looks only. A held button already
## shows its theme's pressed look.
const _BUTTON_STYLES: Array[StringName] = [&"normal", &"hover"]
const _PANEL_STYLES: Array[StringName] = [&"panel"]

const PopBox := preload("res://src/design/pop_box.gd")


static func trans(constant: StringName) -> Tween.TransitionType:
	return CURVES[constant].x as Tween.TransitionType


static func ease_of(constant: StringName) -> Tween.EaseType:
	return CURVES[constant].y as Tween.EaseType


## Duration of a board effect, its stagger delay not included.
static func effect_duration(kind: int) -> float:
	match kind:
		CellEffect.Kind.PLACE:
			return PLACE
		CellEffect.Kind.ERASE:
			return ERASE
		CellEffect.Kind.CROSS:
			return CROSS
		CellEffect.Kind.RESTORE:
			return RESTORE
		_:
			return COMPLETE_WAVE


## The press: the face moves into its shadow (PRESS_DOWN) and springs back
## (PRESS_UP), with the shadow staying where it is. Works on any Control
## whose theme style is a Pop face (buttons, the HUD blocks, stickers). For a
## Button, call it on pressed: the theme already shows the held look, and
## this plays the spring. Returns null, and plays nothing, for a disabled
## button or a node with no Pop face.
static func press(node: CanvasItem) -> Tween:
	var control: Control = node as Control
	if control == null:
		return null
	var button: BaseButton = control as BaseButton
	if button != null and button.disabled:
		return null
	_finish(control, _META_PRESS)
	var names: Array[StringName] = _BUTTON_STYLES if button != null else _PANEL_STYLES
	var copies: Dictionary[StringName, PopBox] = {}
	for style_name: StringName in names:
		var box: PopBox = control.get_theme_stylebox(style_name, _type_of(control)) as PopBox
		if box != null:
			copies[style_name] = box.duplicate() as PopBox
	if copies.is_empty():
		return null
	for style_name: StringName in copies:
		control.add_theme_stylebox_override(style_name, copies[style_name])
	var set_press: Callable = func(amount: float) -> void:
		for copy: PopBox in copies.values():
			copy.press = amount
	var tween: Tween = _tween_for(control)
	tween.tween_method(set_press, 0.0, 1.0, PRESS_DOWN).set_trans(trans(&"PRESS_DOWN")).set_ease(ease_of(&"PRESS_DOWN"))
	tween.tween_method(set_press, 1.0, 0.0, PRESS_UP).set_trans(trans(&"PRESS_UP")).set_ease(ease_of(&"PRESS_UP"))
	tween.finished.connect(func() -> void:
		for style_name: StringName in copies:
			if is_instance_valid(control) and control.get_theme_stylebox(style_name, _type_of(control)) == copies[style_name]:
				control.remove_theme_stylebox_override(style_name))
	control.set_meta(_META_PRESS, tween)
	return tween


## Shows node: a dialog card fades in and scales from 0.9 to 1 (DIALOG_IN);
## a SCRIM panel only fades in (SCRIM_IN). The node is visible and takes
## input from the first frame.
static func appear(node: CanvasItem) -> Tween:
	_finish(node, _META_SHOW)
	node.visible = true
	var tween: Tween = _tween_for(node)
	tween.set_parallel(true)
	if _is_scrim(node):
		node.modulate.a = 0.0
		tween.tween_property(node, ^"modulate:a", 1.0, SCRIM_IN).set_trans(trans(&"DIALOG_IN")).set_ease(ease_of(&"DIALOG_IN"))
	else:
		_center_pivot(node)
		node.modulate.a = 0.0
		node.set(&"scale", Vector2(DIALOG_FROM_SCALE, DIALOG_FROM_SCALE))
		# The fade takes the dialog's time without BACK's overshoot, which
		# would push the opacity past 1.
		tween.tween_property(node, ^"modulate:a", 1.0, DIALOG_IN).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, ^"scale", Vector2.ONE, DIALOG_IN).set_trans(trans(&"DIALOG_IN")).set_ease(ease_of(&"DIALOG_IN"))
	node.set_meta(_META_SHOW, tween)
	return tween


## Hides node, the reverse of appear (DIALOG_OUT). At the end it is hidden
## with its opacity and scale put back, ready for the next appear.
static func disappear(node: CanvasItem) -> Tween:
	_finish(node, _META_SHOW)
	var tween: Tween = _tween_for(node)
	tween.set_parallel(true)
	tween.tween_property(node, ^"modulate:a", 0.0, DIALOG_OUT).set_trans(trans(&"DIALOG_OUT")).set_ease(ease_of(&"DIALOG_OUT"))
	if not _is_scrim(node):
		_center_pivot(node)
		tween.tween_property(node, ^"scale", Vector2(DIALOG_FROM_SCALE, DIALOG_FROM_SCALE), DIALOG_OUT).set_trans(trans(&"DIALOG_OUT")).set_ease(ease_of(&"DIALOG_OUT"))
	tween.chain().tween_callback(func() -> void:
		node.visible = false
		node.modulate.a = 1.0
		if "scale" in node:
			node.set(&"scale", Vector2.ONE))
	node.set_meta(_META_SHOW, tween)
	return tween


## Drives effect.progress from 0 to 1 with the effect's duration and easing,
## and calls on_step() (no arguments) after every change so the caller can
## redraw its effects layer. COMPLETE waits COMPLETE_STAGGER for every step
## of row plus column first. progress is eased: PLACE uses BACK, so it runs
## a little past 1 before settling on 1. A new effect on the same cell
## finishes the running one at once.
static func effect_tween(owner: Node, effect: CellEffect, on_step: Callable) -> Tween:
	var running: Dictionary = owner.get_meta(_META_EFFECTS, {}) as Dictionary
	var old: Tween = running.get(effect.cell, null) as Tween
	if old != null and old.is_valid():
		_finish_tween(old)
	var curve: StringName = _effect_curve(effect.kind)
	var tween: Tween = _tween_for(owner)
	effect.progress = 0.0
	if effect.kind == CellEffect.Kind.COMPLETE:
		# Row plus column of the cell (cell = row * 9 + col).
		var steps: int = effect.cell / 9 + effect.cell % 9
		if steps > 0:
			tween.tween_interval(COMPLETE_STAGGER * float(steps))
	var step: Callable = func(value: float) -> void:
		effect.progress = value
		if on_step.is_valid():
			on_step.call()
	tween.tween_method(step, 0.0, 1.0, effect_duration(effect.kind)).set_trans(trans(curve)).set_ease(ease_of(curve))
	running[effect.cell] = tween
	owner.set_meta(_META_EFFECTS, running)
	# A weak reference, so the tween does not keep itself alive through its
	# own signal.
	var mine: WeakRef = weakref(tween)
	tween.finished.connect(func() -> void:
		if is_instance_valid(owner) and owner.has_meta(_META_EFFECTS):
			var now: Dictionary = owner.get_meta(_META_EFFECTS) as Dictionary
			if now.get(effect.cell, null) == mine.get_ref():
				now.erase(effect.cell))
	return tween


static func _effect_curve(kind: int) -> StringName:
	match kind:
		CellEffect.Kind.PLACE:
			return &"PLACE"
		CellEffect.Kind.ERASE:
			return &"ERASE"
		CellEffect.Kind.CROSS:
			return &"CROSS"
		CellEffect.Kind.RESTORE:
			return &"RESTORE"
		_:
			return &"COMPLETE_WAVE"


## A tween bound to node, so it pauses and ends with it. A node outside the
## tree gets a tween on the SceneTree instead, so the animation still runs
## at once and never waits for the node to be added.
static func _tween_for(node: Node) -> Tween:
	if node.is_inside_tree():
		return node.create_tween()
	return (Engine.get_main_loop() as SceneTree).create_tween()


## The theme type a control looks its styles up under.
static func _type_of(control: Control) -> StringName:
	return control.theme_type_variation if control.theme_type_variation != &"" else StringName(control.get_class())


static func _is_scrim(node: CanvasItem) -> bool:
	var control: Control = node as Control
	return control != null and control.theme_type_variation == ThemeFactory.SCRIM


static func _center_pivot(node: CanvasItem) -> void:
	var control: Control = node as Control
	if control != null:
		control.pivot_offset = control.size * 0.5


## Finishes the tween stored on node under key, so its end state shows now.
static func _finish(node: Object, key: StringName) -> void:
	if not node.has_meta(key):
		return
	var tween: Tween = node.get_meta(key) as Tween
	node.remove_meta(key)
	if tween != null and tween.is_valid():
		_finish_tween(tween)


static func _finish_tween(tween: Tween) -> void:
	# A step longer than any animation runs every tweener and callback to its end.
	tween.custom_step(3600.0)
	if tween.is_valid():
		tween.kill()
