extends UiScreen
## The play screen (GDD 3 to 12, DESIGN_SYSTEM.md 7.5 to 7.8): the HUD
## header row, PlayArea (board, pad, controller) with the level sticker in
## its band, the hint panel, the full board message and the pause menu.
##
## It drives the timer: add_time() runs in _process only while this screen
## shows with nothing over the board. The hint panel and the full board
## message do not stop it; the pause menu and any other screen do (GDD 8).
## Back opens the pause menu, and in the pause menu Back resumes.
## Owner: ui-systems-dev.

const PlayAreaScene := preload("res://scenes/board/play_area.tscn")
const FULL_BOARD_TEXT: String = "The board is full, but some digits clash. Fix the marked cells."

var session: GameSession = null
var hud: PlayHud = null
var play_area: PlayArea = null
var level_sticker: Control = null
var hint_panel: HintPanel = null
var board_message: PanelContainer = null
var pause_menu: PauseMenu = null
## Where the hint panel and the full board message sit: the info zone.
var zone: ZoneBox = null
## Set at completion: what the completion screen will show.
var completion: CompletionResult = null

var _header: VBoxContainer = null


func build() -> void:
	var s: GameSkin = skin()
	session = app.session if app != null else null

	_header = UiKit.vbox(0.0)
	column.add_child(_header)
	hud = PlayHud.new()
	hud.name = "Hud"
	hud.setup(s)
	hud.hint_pressed.connect(buy_hint)
	hud.pause_pressed.connect(show_pause)
	_header.add_child(hud)

	play_area = PlayAreaScene.instantiate() as PlayArea
	play_area.name = "PlayArea"
	if not is_inside_tree() or get_node_or_null(^"/root/Skins") == null:
		play_area.skin = s
	add_child(play_area)
	play_area.resized.connect(_place_band_items)

	level_sticker = UiKit.sticker(ThemeFactory.STICKER, ThemeFactory.STICKER_LABEL, "", s.sticker_tilt)
	level_sticker.name = "LevelSticker"
	add_child(level_sticker)

	zone = ZoneBox.new()
	zone.name = "InfoZone"
	add_child(zone)
	hint_panel = HintPanel.new()
	hint_panel.name = "HintPanel"
	hint_panel.setup(s)
	hint_panel.close_pressed.connect(_on_hint_close)
	zone.add_child(hint_panel)

	board_message = UiKit.panel(ThemeFactory.BOARD_MESSAGE)
	board_message.name = "BoardMessage"
	board_message.mouse_filter = Control.MOUSE_FILTER_STOP
	var message: Label = UiKit.label(ThemeFactory.BODY_SMALL, FULL_BOARD_TEXT, true)
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	board_message.add_child(message)
	board_message.visible = false
	zone.add_child(board_message)

	pause_menu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	pause_menu.setup(s)
	pause_menu.resume_pressed.connect(resume)
	pause_menu.settings_pressed.connect(func() -> void: app.goto(AppService.SETTINGS))
	pause_menu.menu_pressed.connect(func() -> void: app.goto(AppService.MAIN_MENU))
	add_child(pause_menu)

	resized.connect(_layout)
	if session == null:
		return
	if app != null and app.audio != null:
		play_area.controller.audio = app.audio
	play_area.setup(session)
	play_area.controller.action_applied.connect(_on_action_applied)
	session.hint_changed.connect(_on_hint_changed)
	session.score_changed.connect(_on_score_changed)
	session.full_board_conflict.connect(_on_full_board_conflict)
	session.completed.connect(_on_completed)
	hud.bind(session)
	UiKit.set_text(level_sticker.get_child(0) as Label, Levels.name_of(session.level))
	if session.hint != null:
		hint_panel.show_hint(session.hint)
	_layout()


func _process(delta: float) -> void:
	if is_timer_running():
		session.add_time(delta)
		hud.update_time()


## The timer runs while this screen shows, the puzzle is not finished and
## the pause menu is closed (GDD 8).
func is_timer_running() -> bool:
	return session != null and not session.is_completed and _is_showing() \
		and not pause_menu.is_open()


## This screen and every parent are visible: no other screen covers it.
func _is_showing() -> bool:
	var at: Node = self
	while at != null:
		var item: CanvasItem = at as CanvasItem
		if item != null and not item.visible:
			return false
		at = at.get_parent()
	return true


## Back: opens the pause menu, or resumes from it. Ignored once the puzzle
## is finished and the completion screen is on its way.
func handle_back() -> bool:
	if session == null or session.is_completed:
		return true
	if pause_menu.is_open():
		resume()
	else:
		show_pause()
	return true


## Opens the pause menu: the board hides on this frame (GDD 8). App calls it
## when the app goes to the background or loses focus.
func show_pause() -> void:
	if session == null or session.is_completed or pause_menu.is_open():
		return
	play_area.visible = false
	level_sticker.visible = false
	pause_menu.show_for(session)
	if app != null:
		app.save_session()


func resume() -> void:
	if not pause_menu.is_open():
		return
	play_area.visible = true
	level_sticker.visible = true
	pause_menu.close()


func on_shown() -> void:
	hud.refresh()


## The Hint button: finds the next step and buys it (ARCHITECTURE section
## 11). NextStep.find is fast enough for the main thread.
func buy_hint() -> void:
	if session == null or not session.can_buy_hint():
		return
	_close_board_message()
	var before: int = session.score()
	var hint: Hint = NextStep.find(session.solution, session.board)
	if session.buy_hint(hint):
		hud.animate_score(before, session.score())
	hud.refresh()


## Hands the completion to App at once (stats, the save deleted), then shows
## the completion screen when the board's wave is over (GDD 12).
func finish_completion() -> void:
	if completion == null or app == null:
		return
	app.goto(AppService.COMPLETION, completion)


func _on_completed(_seconds: int, _score: int) -> void:
	hint_panel.visible = false
	_close_board_message()
	hud.refresh()
	if app == null:
		return
	completion = app.on_puzzle_completed()
	if is_inside_tree():
		var wave: float = Motion.COMPLETE_WAVE + Motion.COMPLETE_STAGGER * 16.0
		get_tree().create_timer(wave).timeout.connect(finish_completion)


func _on_action_applied(_action: BoardAction, result: ActionResult) -> void:
	# The full board message closes at the player's next action (GDD 6.3),
	# not at the placement that opened it.
	if not result.full_board_conflict:
		_close_board_message()


func _on_full_board_conflict() -> void:
	hint_panel.visible = false
	UiKit.panel_in(board_message)
	_layout()


func _close_board_message() -> void:
	UiKit.panel_out(board_message)


func _on_hint_changed(hint: Hint) -> void:
	if hint != null:
		hint_panel.show_hint(hint)
		_layout()
	else:
		UiKit.panel_out(hint_panel)
	hud.refresh()


func _on_hint_close() -> void:
	if session != null:
		session.close_hint()


func _on_score_changed(_score: int) -> void:
	hud.refresh()


## PlayArea takes the whole safe rect below the header row; the header row
## sits page_margin below the safe top, in the content column.
func _layout() -> void:
	if column == null:
		return
	var safe: Rect2 = UiKit.safe_rect_local(self)
	var header_bottom: float = column.column_rect().position.y + _header.get_combined_minimum_size().y
	play_area.position = Vector2(safe.position.x, header_bottom)
	play_area.size = Vector2(safe.size.x, maxf(0.0, safe.end.y - header_bottom))
	_place_band_items()


## The level sticker sits in the band, space_s above the board's left end.
## The hint panel and the full board message cover the info zone: the
## header row and the band, down to space_s above the board.
func _place_band_items() -> void:
	if play_area == null or column == null:
		return
	var s: GameSkin = skin()
	var band: Rect2 = get_global_transform().affine_inverse() * play_area.band_rect_global()
	var sticker_size: Vector2 = level_sticker.get_combined_minimum_size()
	level_sticker.size = sticker_size
	level_sticker.position = Vector2(band.position.x + s.space_s, band.end.y - s.space_s - sticker_size.y)
	var top: float = column.column_rect().position.y
	zone.position = Vector2(band.position.x, top)
	zone.size = Vector2(band.size.x, maxf(0.0, band.end.y - s.space_s - top))
