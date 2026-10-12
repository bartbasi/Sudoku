extends "res://tests/unit_test.gd"
## Motion holds the timings and easing of DESIGN_SYSTEM.md section 6, and its
## helpers return tweens that run exactly those durations, finish early when
## called again, and never block input.

const DesignDoc := preload("res://tests/design/design_doc.gd")
const PopBox := preload("res://src/design/pop_box.gd")
const STEP: float = 0.004

var _nodes: Array[Node] = []


func _root() -> Window:
	return (Engine.get_main_loop() as SceneTree).root


func _skin() -> GameSkin:
	return load("res://src/skins/pop_light.tres") as GameSkin


func _add(node: Node) -> Node:
	_root().add_child(node)
	_nodes.append(node)
	return node


func _clean() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.get_parent().remove_child(node)
			node.free()
	_nodes.clear()


## Checks that tween still runs just before duration and is done just after.
func _runs_for(tween: Tween, duration: float, what: String) -> void:
	assert_true(tween != null, "%s returns a tween" % what)
	if tween == null:
		return
	tween.custom_step(duration - STEP)
	assert_true(tween.is_running(), "%s still runs at %.3f s" % [what, duration - STEP])
	tween.custom_step(STEP * 2.0)
	assert_false(tween.is_running(), "%s is done at %.3f s" % [what, duration + STEP])


func test_constants_match_section_6() -> void:
	var rows: Array[PackedStringArray] = DesignDoc.rows("## 6.")
	assert_eq(rows.size(), 28, "section 6 lists 28 timings")
	var map: Dictionary = (Motion as Script).get_script_constant_map()
	for cells: PackedStringArray in rows:
		var constant: String = DesignDoc.code(cells[0])
		assert_true(map.has(constant), "Motion.%s exists" % constant)
		if not map.has(constant):
			continue
		assert_true(is_equal_approx(map[constant] as float, cells[1].to_float() / 1000.0), "Motion.%s is %s ms" % [constant, cells[1]])
		var curve: String = cells[2].strip_edges()
		if curve.is_empty():
			assert_false(Motion.CURVES.has(StringName(constant)), "%s has no easing" % constant)
			continue
		var parts: PackedStringArray = curve.split(",")
		var trans: int = ClassDB.class_get_integer_constant(&"Tween", StringName("TRANS_" + parts[0].strip_edges()))
		var ease: int = ClassDB.class_get_integer_constant(&"Tween", StringName("EASE_" + parts[1].strip_edges()))
		assert_true(Motion.CURVES.has(StringName(constant)), "%s has easing" % constant)
		assert_eq(int(Motion.trans(StringName(constant))), trans, "%s transition" % constant)
		assert_eq(int(Motion.ease_of(StringName(constant))), ease, "%s ease" % constant)
	assert_eq(Motion.CURVES.size(), rows.size() - 1, "easing for every timed row")


func test_nothing_runs_longer_than_allowed() -> void:
	var map: Dictionary = (Motion as Script).get_script_constant_map()
	for constant: String in map:
		if map[constant] is float and constant not in ["DIALOG_FROM_SCALE", "SCORE_COUNT", "LESSON_PULSE"]:
			assert_true((map[constant] as float) <= 0.4, "%s is at most 400 ms" % constant)


func test_effect_tweens_run_their_documented_time() -> void:
	var owner: Node = _add(Node.new())
	var expected: Dictionary[int, float] = {
		CellEffect.Kind.PLACE: Motion.PLACE, CellEffect.Kind.ERASE: Motion.ERASE,
		CellEffect.Kind.CROSS: Motion.CROSS, CellEffect.Kind.RESTORE: Motion.RESTORE,
		CellEffect.Kind.COMPLETE: Motion.COMPLETE_WAVE,
	}
	for kind: int in expected:
		var effect: CellEffect = CellEffect.new()
		effect.cell = 0
		effect.kind = kind
		var steps: Array[int] = [0]
		var tween: Tween = Motion.effect_tween(owner, effect, func() -> void: steps[0] += 1)
		_runs_for(tween, expected[kind], "effect %d" % kind)
		assert_true(is_equal_approx(effect.progress, 1.0), "effect %d ends at progress 1" % kind)
		assert_true(steps[0] > 0, "effect %d calls on_step" % kind)
	_clean()


func test_complete_wave_staggers_by_row_plus_column() -> void:
	var owner: Node = _add(Node.new())
	var effect: CellEffect = CellEffect.new()
	effect.cell = 80
	effect.kind = CellEffect.Kind.COMPLETE
	var tween: Tween = Motion.effect_tween(owner, effect, Callable())
	tween.custom_step(Motion.COMPLETE_STAGGER * 16.0 - STEP)
	assert_eq(effect.progress, 0.0, "the last cell waits 16 steps")
	tween.custom_step(STEP * 2.0)
	_runs_for(tween, Motion.COMPLETE_WAVE - STEP * 2.0, "the last cell wave")
	assert_true(is_equal_approx(Motion.COMPLETE_STAGGER * 16.0 + Motion.COMPLETE_WAVE, 0.372), "the wave ends after 372 ms")
	_clean()


func test_a_new_effect_on_the_same_cell_finishes_the_old_one() -> void:
	var owner: Node = _add(Node.new())
	var first: CellEffect = CellEffect.new()
	first.cell = 40
	first.kind = CellEffect.Kind.PLACE
	var old: Tween = Motion.effect_tween(owner, first, Callable())
	old.custom_step(0.02)
	var second: CellEffect = CellEffect.new()
	second.cell = 40
	second.kind = CellEffect.Kind.ERASE
	var tween: Tween = Motion.effect_tween(owner, second, Callable())
	assert_true(is_equal_approx(first.progress, 1.0), "the old effect jumps to its end")
	assert_false(old.is_running(), "the old tween stops")
	assert_true(tween.is_valid(), "the new one runs")
	tween.custom_step(1.0)
	_clean()


func test_press_runs_down_and_up_and_cleans_up() -> void:
	var button: Button = _add(Button.new()) as Button
	button.theme = ThemeFactory.build(_skin())
	button.theme_type_variation = ThemeFactory.BUTTON_PRIMARY
	var tween: Tween = Motion.press(button)
	assert_true(button.has_theme_stylebox_override(&"normal"), "the press animates a copy")
	tween.custom_step(Motion.PRESS_DOWN)
	var copy: PopBox = button.get_theme_stylebox(&"normal", ThemeFactory.BUTTON_PRIMARY) as PopBox
	assert_true(is_equal_approx(copy.press, 1.0), "sunk after PRESS_DOWN")
	_runs_for(tween, Motion.PRESS_UP, "the spring back")
	assert_false(button.has_theme_stylebox_override(&"normal"), "the theme look comes back")
	assert_eq((button.get_theme_stylebox(&"normal", ThemeFactory.BUTTON_PRIMARY) as PopBox).press, 0.0, "raised again")
	_clean()


func test_press_works_on_a_panel_and_skips_disabled_buttons() -> void:
	var block: PanelContainer = _add(PanelContainer.new()) as PanelContainer
	block.theme = ThemeFactory.build(_skin())
	block.theme_type_variation = ThemeFactory.HUD_SCORE
	_runs_for(Motion.press(block), Motion.PRESS_DOWN + Motion.PRESS_UP, "the score block press")
	var button: Button = _add(Button.new()) as Button
	button.theme = block.theme
	button.disabled = true
	assert_true(Motion.press(button) == null, "a disabled button plays no press")
	assert_true(Motion.press(_add(Node2D.new()) as Node2D) == null, "nothing to press on a Node2D")
	_clean()


func test_appear_and_disappear() -> void:
	var dialog: PanelContainer = _add(PanelContainer.new()) as PanelContainer
	dialog.theme = ThemeFactory.build(_skin())
	dialog.theme_type_variation = ThemeFactory.DIALOG
	dialog.visible = false
	var tween: Tween = Motion.appear(dialog)
	assert_true(dialog.visible, "visible at once, so it takes taps from the first frame")
	assert_eq(dialog.mouse_filter, Control.MOUSE_FILTER_STOP, "input is not blocked")
	_runs_for(tween, Motion.DIALOG_IN, "appear")
	assert_true(is_equal_approx(dialog.modulate.a, 1.0), "fully shown")
	assert_true(dialog.scale.is_equal_approx(Vector2.ONE), "full size")
	_runs_for(Motion.disappear(dialog), Motion.DIALOG_OUT, "disappear")
	assert_false(dialog.visible, "hidden at the end")
	assert_eq(dialog.modulate.a, 1.0, "opacity put back")
	assert_eq(dialog.scale, Vector2.ONE, "scale put back")
	_clean()


func test_scrim_only_fades() -> void:
	var scrim: Panel = _add(Panel.new()) as Panel
	scrim.theme_type_variation = ThemeFactory.SCRIM
	var tween: Tween = Motion.appear(scrim)
	assert_eq(scrim.scale, Vector2.ONE, "the scrim does not scale")
	_runs_for(tween, Motion.SCRIM_IN, "scrim fade")
	_clean()


func test_a_new_appear_finishes_a_running_disappear() -> void:
	var dialog: PanelContainer = _add(PanelContainer.new()) as PanelContainer
	var out: Tween = Motion.disappear(dialog)
	out.custom_step(0.03)
	var back: Tween = Motion.appear(dialog)
	assert_false(out.is_running(), "the old animation is finished at once")
	assert_true(dialog.visible, "and the new one shows the dialog")
	back.custom_step(1.0)
	_clean()
