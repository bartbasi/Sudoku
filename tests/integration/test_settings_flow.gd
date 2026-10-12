extends "res://tests/unit_test.gd"
## Phase 4 verify items 8 and 9, end to end: the Sound switch in Settings
## reaches the Audio autoload (Audio.enabled, and a pad tap clicks only with
## sound on), and the skin picker changes the Skins autoload's current skin,
## the saved setting and the skin the next screens and the board are built
## with.

const Ix := preload("res://tests/integration/integration_fixtures.gd")


func test_sound_switch_reaches_audio() -> void:
	var dir: String = Ix.new_dir("sound")
	Ix.write_settings(dir)
	var h: Ix.Harness = Ix.open_app(dir)
	assert_true(bool(h.audio.get(&"enabled")), "sound is on by default")
	Ix.start_from_menu(h, Levels.BEGINNER)
	var area: PlayArea = Ix.play_area_of(h.top())
	var session: GameSession = h.app.session
	var cells: PackedInt32Array = Ix.empty_cells(session)
	var before: int = Ix.clicks(h)
	Ix.place(area, cells[0], session.solution[cells[0]])
	assert_eq(Ix.clicks(h), before + 1, "a placement clicks")

	# Sound off from the pause menu's Settings.
	Ix.click((h.top().get(&"hud") as PlayHud).pause_button)
	Ix.click((h.top().get(&"pause_menu") as PauseMenu).settings_button)
	Ix.fit(h)
	var switch: CheckButton = h.top().get(&"sound_switch")
	assert_true(switch.button_pressed, "the switch shows sound on")
	assert_true(Ix.set_switch(switch, false))
	assert_false(bool(h.audio.get(&"enabled")), "Audio.enabled follows the switch")
	assert_false(h.app.settings.sound)
	h.app.go_back()
	Ix.click((h.top().get(&"pause_menu") as PauseMenu).resume_button)
	before = Ix.clicks(h)
	Ix.place(area, cells[1], session.solution[cells[1]])
	Ix.tap_mode(area, GameSession.Mode.CROSS_OUT)
	Ix.tap_cell(area, cells[2])
	Ix.tap_digit(area, 1)
	assert_eq(session.board.mark(cells[2], 1), Board.Mark.CROSSED_HAND, "the taps still work")
	assert_eq(Ix.clicks(h), before, "no click with sound off")

	# The setting survives a restart and reaches Audio at startup.
	Ix.quit(h)
	h.audio.set(&"enabled", true)
	var again: Ix.Harness = Ix.open_app(dir)
	assert_false(again.app.settings.sound)
	assert_false(bool(again.audio.get(&"enabled")), "Audio is off after reopening")
	Ix.click(again.top().get(&"settings_button") as Button)
	Ix.fit(again)
	assert_true(Ix.set_switch(again.top().get(&"sound_switch") as CheckButton, true))
	assert_true(bool(again.audio.get(&"enabled")), "and on again")
	Ix.close(again)


func test_skin_switch_changes_skins_current_and_the_screens() -> void:
	var dir: String = Ix.new_dir("skin")
	Ix.write_settings(dir)
	var h: Ix.Harness = Ix.open_app(dir)
	var skins: Node = h.skins
	assert_eq((skins.get(&"current") as GameSkin).id, &"pop_light", "Pop light is the default")
	var changes: Array[StringName] = []
	var watch: Callable = func(skin: GameSkin) -> void: changes.append(skin.id)
	skins.connect(&"skin_changed", watch)
	Ix.click(h.top().get(&"settings_button") as Button)
	Ix.fit(h)
	var options: Dictionary = h.top().get(&"skin_buttons")
	assert_true((options[&"pop_light"] as Button).button_pressed, "the picker shows Pop light")
	assert_true(Ix.click(options[&"pop_dark"] as Button), "pick Pop dark")
	assert_eq((skins.get(&"current") as GameSkin).id, &"pop_dark", "Skins.current changes")
	assert_eq(changes, [&"pop_dark"] as Array[StringName], "skin_changed once")
	assert_eq(h.app.settings.skin_id, &"pop_dark")
	assert_true((options[&"pop_dark"] as Button).button_pressed)
	assert_false((options[&"pop_light"] as Button).button_pressed)
	var saved: Settings = Settings.from_dict(SaveStore.read(h.app.path_of(AppService.SETTINGS_FILE), SaveStore.MAX_BYTES_OTHER))
	assert_eq(saved.skin_id, &"pop_dark", "saved")
	# The theme App would put on the root is the dark one.
	var dark: GameSkin = skins.get(&"current") as GameSkin
	var theme: Theme = ThemeFactory.build(dark)
	var light_theme: Theme = ThemeFactory.build(h.app.builtin_skin(&"pop_light"))
	assert_eq(theme.get_color(&"font_color", ThemeFactory.SWITCH), dark.text, "the dark theme uses the dark text color")
	assert_ne(theme.get_color(&"font_color", ThemeFactory.SWITCH),
		light_theme.get_color(&"font_color", ThemeFactory.SWITCH), "and differs from the light theme")

	# A puzzle opened now is built with the dark skin.
	h.app.go_back()
	Ix.fit(h)
	Ix.start_from_menu(h, Levels.BEGINNER)
	var area: PlayArea = Ix.play_area_of(h.top())
	assert_eq(area.view.current_skin().id, &"pop_dark", "the board draws in Pop dark")
	assert_eq(area.pad.skin.id, &"pop_dark")
	assert_true(area.view.current_skin().is_dark)

	# Back to light, and the choice survives a restart.
	h.app.set_skin(&"pop_light")
	assert_eq((skins.get(&"current") as GameSkin).id, &"pop_light")
	h.app.set_skin(&"pop_dark")
	skins.disconnect(&"skin_changed", watch)
	Ix.quit(h)
	skins.call(&"apply", &"pop_light")
	var again: Ix.Harness = Ix.open_app(dir)
	assert_eq((skins.get(&"current") as GameSkin).id, &"pop_dark", "the skin comes back at startup")
	Ix.close(again)
