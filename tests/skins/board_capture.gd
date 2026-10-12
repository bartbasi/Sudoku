extends SceneTree
## Screenshots and redraw timing for BoardPainter. Not a test file: the test
## runner only runs tests/<area>/test_*.gd. It needs a window (headless mode has
## no renderer):
##
##   timeout 300 godot --path . --script res://tests/skins/board_capture.gd
##
## Writes build/skins/board-<skin>-<mode>.png: a busy board on a 1080 px wide
## phone (411 dp, density 2.63) showing selection, peers, same digit, a
## conflict, hint targets, reasons and cross chips, hand Xs with outlined
## digits, a ring crossed all the way round, restored candidates and Auto
## Cross marks. Then times full redraws in the window at 1 px per dp and prints
## the numbers. build/ is git ignored.

const OUT_DIR: String = "res://build/skins/"
const SKINS: Array[String] = ["res://src/skins/pop_light.tres", "res://src/skins/pop_dark.tres"]

const PHONE_PX: int = 1080
const PHONE_DP: int = 411
const BOARD_DP: float = 388.0

const TIMING_FRAMES: int = 240
const TIMING_WARMUP: int = 20

# A valid puzzle and its solution, row by row.
const GIVENS: String = "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
const SOLUTION: String = "534678912672195348198342567859761423426853791713924856961537284287419635345286179"

const MARK_CROSSED_HAND: int = 1
const MARK_RESTORED_HAND: int = 2
const MARK_CROSSED_AUTO: int = 3


## Draws one board with a painter and remembers how long each draw took.
class BoardHost extends Control:
	var painter: BoardPainter = BoardPainter.new()
	var state: BoardDrawState = null
	var skin: GameSkin = null
	var effects: Array[CellEffect] = []
	var timings: PackedInt64Array = PackedInt64Array()
	var board_dp: float = 0.0

	func square() -> Rect2:
		var side: float = board_dp if board_dp > 0.0 else minf(size.x, size.y) - 12.0
		return Rect2((size.x - side - skin.shadow_offset) * 0.5, (size.x - side - skin.shadow_offset) * 0.5, side, side)

	func _draw() -> void:
		if skin == null or state == null:
			return
		draw_rect(Rect2(Vector2.ZERO, size), skin.page_bg)
		var start: int = Time.get_ticks_usec()
		painter.draw_board(self, square(), state, skin)
		timings.append(Time.get_ticks_usec() - start)
		if not effects.is_empty():
			painter.draw_effects(self, square(), effects, skin)


var _problems: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for path: String in SKINS:
		var skin: GameSkin = load(path) as GameSkin
		if skin == null:
			_problems.append("%s does not load" % path)
			continue
		skin = _with_hint_cross_tokens(skin)
		for mode: int in [0, 1]:
			var image: Image = await _render(skin, _busy_state(mode))
			var name: String = "board-%s-%s" % [skin.id, "place" if mode == 0 else "cross"]
			_save(image, name)
	await _capture_effects()
	await _time_redraws()
	for problem: String in _problems:
		print("PROBLEM  %s" % problem)
	quit(0 if _problems.is_empty() else 1)


func _render(skin: GameSkin, state: BoardDrawState, effects: Array[CellEffect] = []) -> Image:
	var viewport: SubViewport = SubViewport.new()
	viewport.size_2d_override = Vector2i(PHONE_DP, PHONE_DP)
	viewport.size_2d_override_stretch = true
	viewport.size = Vector2i(PHONE_PX, PHONE_PX)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var host: BoardHost = BoardHost.new()
	host.skin = skin
	host.state = state
	host.effects = effects
	host.board_dp = BOARD_DP
	host.size = Vector2(PHONE_DP, PHONE_DP)
	viewport.add_child(host)
	root.add_child(viewport)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	viewport.queue_free()
	await process_frame
	return image


func _save(image: Image, base_name: String) -> void:
	var path: String = OUT_DIR + base_name + ".png"
	var error: Error = image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		_problems.append("could not save %s (error %d)" % [path, error])
	else:
		print("wrote    %s" % ProjectSettings.globalize_path(path))


## Every effect kind at half way, on the busy board in Pop light.
func _capture_effects() -> void:
	var skin: GameSkin = _with_hint_cross_tokens(load(SKINS[0]) as GameSkin)
	var state: BoardDrawState = _busy_state(1)
	state.digits[38] = 0  # r5c3 erased: its ring shows again
	var effects: Array[CellEffect] = []
	for spec: Array in [[CellEffect.Kind.PLACE, 30, 6], [CellEffect.Kind.ERASE, 38, 3],
			[CellEffect.Kind.CROSS, 40, 1], [CellEffect.Kind.RESTORE, 40, 2], [CellEffect.Kind.COMPLETE, 1, 3]]:
		var effect: CellEffect = CellEffect.new()
		effect.kind = spec[0]
		effect.cell = spec[1]
		effect.digit = spec[2]
		effect.progress = 0.5
		effects.append(effect)
	var image: Image = await _render(skin, state, effects)
	_save(image, "board-pop_light-effects")


## Until the skin files are written again with the hint cross tokens, use
## the DESIGN_SYSTEM.md table values in memory (the files are not touched).
func _with_hint_cross_tokens(skin: GameSkin) -> GameSkin:
	if skin.hint_cross_pad > 0.0:
		return skin
	var copy: GameSkin = skin.duplicate() as GameSkin
	copy.hint_cross_bg = Color.html("#5BE08F" if skin.is_dark else "#087A38")
	copy.hint_cross_pad = 0.05
	print("note     %s has no hint cross tokens yet; using the DESIGN_SYSTEM.md values in memory" % skin.id)
	return copy


## Full redraws in the main window, one per frame.
func _time_redraws() -> void:
	var skin: GameSkin = _with_hint_cross_tokens(load(SKINS[0]) as GameSkin)
	var cases: Dictionary[String, BoardDrawState] = {
		"busy board (51 rings)": _busy_state(1),
		"every cell empty, every candidate marked (729 candidates)": _all_rings_state(),
	}
	for label: String in cases:
		var host: BoardHost = BoardHost.new()
		host.skin = skin
		host.state = cases[label]
		host.size = Vector2(PHONE_DP, PHONE_DP)
		host.board_dp = BOARD_DP
		root.add_child(host)
		for frame: int in TIMING_FRAMES + TIMING_WARMUP:
			host.queue_redraw()
			await process_frame
		var samples: Array[int] = []
		for i: int in range(TIMING_WARMUP, host.timings.size()):
			samples.append(host.timings[i])
		samples.sort()
		if samples.is_empty():
			_problems.append("no redraws timed for %s" % label)
		else:
			var total: int = 0
			for value: int in samples:
				total += value
			print("timing   %s at %.2f px per dp: median %.2f ms, mean %.2f ms, 95th %.2f ms, max %.2f ms over %d redraws" % [
				label, host.painter._scale,
				float(samples[samples.size() / 2]) / 1000.0, float(total) / float(samples.size()) / 1000.0,
				float(samples[(samples.size() * 95) / 100]) / 1000.0, float(samples[samples.size() - 1]) / 1000.0, samples.size()])
		host.queue_free()
		await process_frame


## The demo position: the puzzle with some digits placed, one wrong digit in
## conflict, Auto Cross marks for every ruled out candidate, hand marks, a
## hint on screen and r5c5 selected.
func _busy_state(mode: int) -> BoardDrawState:
	var state: BoardDrawState = BoardDrawState.new()
	state.givens = _grid(GIVENS)
	state.digits = state.givens.duplicate()
	var solution: PackedInt32Array = _grid(SOLUTION)
	for cell: int in [10, 12, 22, 30, 32, 38, 42, 50, 58, 66, 70]:
		state.digits[cell] = solution[cell]
	state.digits[2] = 5  # r1c3: a wrong 5, clashing with the given 5 at r1c1
	state.marks = PackedByteArray()
	state.marks.resize(729)
	for cell: int in 81:
		if state.digits[cell] != 0:
			continue
		for d: int in range(1, 10):
			if _ruled_out(state.digits, cell, d):
				state.marks[cell * 9 + d - 1] = MARK_CROSSED_AUTO
	# Hand marks: r5c5 has 1 and 9 crossed by hand and 2 restored by hand;
	# r9c1 is crossed all the way round; a few more hand Xs.
	_set_marks(state, 40, {1: MARK_CROSSED_HAND, 9: MARK_CROSSED_HAND, 2: MARK_RESTORED_HAND})
	for d: int in range(1, 10):
		state.marks[72 * 9 + d - 1] = MARK_CROSSED_HAND
	_set_marks(state, 20, {3: MARK_CROSSED_HAND, 7: MARK_CROSSED_HAND})
	_set_marks(state, 61, {4: MARK_CROSSED_HAND, 8: MARK_CROSSED_HAND})
	state.selected = 40
	state.mode = mode
	state.peers = _peers(40)
	state.same_digit = PackedInt32Array()
	state.conflicts = PackedInt32Array([0, 2])
	# A hint on screen: targets r5c2, r5c5 (selected) and r5c8, reasons r5c1
	# and r5c9. Each target gets chips on its first two open candidates, and
	# one candidate already crossed (drawn as crossed, without a chip).
	state.hint_targets = PackedInt32Array([37, 40, 43])
	state.hint_reasons = PackedInt32Array([36, 44])
	var crosses: PackedInt32Array = PackedInt32Array()
	for cell: int in state.hint_targets:
		var open_found: int = 0
		for d: int in range(1, 10):
			var index: int = cell * 9 + d - 1
			var mark: int = state.marks[index]
			if (mark == 0 or mark == MARK_RESTORED_HAND) and open_found < 2:
				crosses.append(index)
				open_found += 1
		crosses.append(cell * 9 + 8)
	state.hint_crosses = crosses
	return state


## The worst case for drawing: no digits, every candidate in some state.
func _all_rings_state() -> BoardDrawState:
	var state: BoardDrawState = BoardDrawState.new()
	state.givens = PackedInt32Array()
	state.givens.resize(81)
	state.digits = PackedInt32Array()
	state.digits.resize(81)
	state.marks = PackedByteArray()
	state.marks.resize(729)
	for i: int in 729:
		state.marks[i] = i % 4
	state.selected = 40
	state.mode = 1
	state.peers = _peers(40)
	state.hint_targets = PackedInt32Array([0, 1, 2])
	state.hint_reasons = PackedInt32Array([9, 10, 11])
	state.hint_crosses = PackedInt32Array([0, 2, 9 + 4, 18 + 6])
	return state


func _set_marks(state: BoardDrawState, cell: int, marks: Dictionary) -> void:
	for d: int in marks:
		state.marks[cell * 9 + d - 1] = marks[d]


func _grid(text: String) -> PackedInt32Array:
	var grid: PackedInt32Array = PackedInt32Array()
	for i: int in 81:
		grid.append(text.unicode_at(i) - 48)
	return grid


func _peers(cell: int) -> PackedInt32Array:
	var peers: PackedInt32Array = PackedInt32Array()
	for other: int in 81:
		if other != cell and _sees(cell, other):
			peers.append(other)
	return peers


func _sees(a: int, b: int) -> bool:
	return a / 9 == b / 9 or a % 9 == b % 9 or ((a / 27) == (b / 27) and (a % 9) / 3 == (b % 9) / 3)


func _ruled_out(digits: PackedInt32Array, cell: int, d: int) -> bool:
	for other: int in 81:
		if other != cell and digits[other] == d and _sees(cell, other):
			return true
	return false
