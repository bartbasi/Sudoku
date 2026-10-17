extends UiScreen
## The About screen (GDD 15.6, DESIGN_SYSTEM.md 7.17): a card with the name,
## the version, the credit and copyright lines, the short paragraph, the
## support line with the Buy me a coffee button, the contact and privacy
## lines and the Godot line; then the open source notices, read from the
## engine at run time (Engine.get_license_text, get_copyright_info and
## get_license_info), so no notice text is copied into the game.
##
## Only Back and Buy me a coffee react to a tap. Buy me a coffee hands the
## support page to the phone's web browser (App.open_support_page), as on
## the title screen; the game itself sends nothing. The email and privacy
## addresses are plain text, and nothing in the notices can be tapped.
##
## The notices are long (about 80,000 characters), so the screen builds the
## card and the notices heading at once and the notice labels after its
## first frame, a few per frame, appended at the bottom. One label per
## paragraph; every label wraps (smart word wrap, minimum width 1), so
## nothing scrolls sideways. The engine's hard wrapped lines are joined into
## paragraphs (notice_paragraphs); only white space changes.
## Owner: ui-systems-dev.

const NAME: String = "Sudoku"
const CREDIT: String = "Designed and written by Bart Basi."
const COPYRIGHT: String = "Copyright 2026 Play, Inc. All rights reserved."
const PARAGRAPH: String = "Sudoku is free. It works offline, with no ads and no accounts, and it collects no data. Everything you do stays on this device."
const SUPPORT: String = "If you enjoy it and want to support the game, you can buy me a coffee."
const COFFEE: String = "Buy me a coffee"
const CONTACT: String = "Questions, feedback and notices: bartbasi@gmail.com"
const PRIVACY: String = "Privacy policy: bartbasi.github.io/Sudoku/privacy"
const MADE_WITH: String = "Made with the Godot Engine."
const NOTICES_HEADING: String = "Open source notices"
const ENGINE_CAPTION: String = "Godot Engine"
const COMPONENTS_HEADING: String = "Third party components"
const LICENSES_HEADING: String = "Licenses"
## Notice labels made per frame after the first frame (7.17).
const LABELS_PER_FRAME: int = 24

## The scrolling page, for tests.
var scroll: ScrollContainer = null
var version_label: Label = null
## The face of Buy me a coffee in the card.
var coffee_button: Button = null
## The notices under the heading; labels are appended here.
var notices: VBoxContainer = null

## Items still to build: [variation, text, gap above]. A RULE variation
## makes a rule instead of a label.
var _pending: Array[Array] = []
var _next: int = 0
var _frames_seen: int = 0


func build() -> void:
	var s: GameSkin = skin()
	var stack: VBoxContainer = UiKit.vbox(s.space_s)
	column.add_child(stack)
	stack.add_child(UiKit.title_row("About", s.space_s, _on_back_pressed))
	scroll = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)
	var page_list: VBoxContainer = UiKit.vbox(s.space_xl)
	page_list.name = "List"
	page_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(page_list)
	page_list.add_child(UiKit.with_shadow_room(_card(s), s))
	# The notices line up with the card's face: the list width less the
	# shadow at the right.
	var room: MarginContainer = MarginContainer.new()
	room.name = "Notices"
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room.add_theme_constant_override(&"margin_right", roundi(s.shadow_offset))
	page_list.add_child(room)
	notices = UiKit.vbox(0.0)
	notices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room.add_child(notices)
	_add_item(s, [ThemeFactory.HEADING, NOTICES_HEADING, 0.0])
	_pending = notice_items(s)
	_next = 0
	set_process(not _pending.is_empty())


func _process(_delta: float) -> void:
	# The first frame shows the screen as built; the notices follow.
	_frames_seen += 1
	if _frames_seen < 2:
		return
	_build_some(LABELS_PER_FRAME)


## True once every notice label is built.
func is_complete() -> bool:
	return _next >= _pending.size()


## Builds every notice label left, now. For tests, which run without frames.
func build_all_notices() -> void:
	_build_some(_pending.size())


func _build_some(count: int) -> void:
	var s: GameSkin = skin()
	var end: int = mini(_next + count, _pending.size())
	while _next < end:
		_add_item(s, _pending[_next])
		_next += 1
	if is_complete():
		set_process(false)


func _add_item(s: GameSkin, item: Array) -> void:
	var gap: float = item[2]
	if gap > 0.0:
		var space: Control = Control.new()
		space.custom_minimum_size.y = gap
		space.mouse_filter = Control.MOUSE_FILTER_IGNORE
		notices.add_child(space)
	var variation: StringName = item[0]
	if variation == ThemeFactory.RULE:
		var rule: HSeparator = HSeparator.new()
		rule.theme_type_variation = ThemeFactory.RULE
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		notices.add_child(rule)
		return
	var line: Label = UiKit.label(variation, item[1], true)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notices.add_child(line)


func _card(s: GameSkin) -> PanelContainer:
	var card: PanelContainer = UiKit.panel(ThemeFactory.CARD)
	card.name = "Card"
	var inside: VBoxContainer = UiKit.vbox(0.0)
	card.add_child(inside)
	var title: Label = UiKit.label(ThemeFactory.TITLE, NAME, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inside.add_child(title)
	version_label = UiKit.label(ThemeFactory.CAPTION, version_line(), true)
	version_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inside.add_child(version_label)
	# Each entry space_s below the one above. An empty variation is the
	# Buy me a coffee button, right under the support line.
	var entries: Array[Array] = [[ThemeFactory.BODY_SMALL, CREDIT], [ThemeFactory.BODY_SMALL, COPYRIGHT],
		[ThemeFactory.BODY, PARAGRAPH], [ThemeFactory.BODY, SUPPORT], [&"", COFFEE],
		[ThemeFactory.BODY_SMALL, CONTACT], [ThemeFactory.BODY_SMALL, PRIVACY], [ThemeFactory.BODY, MADE_WITH]]
	for entry: Array in entries:
		var space: Control = Control.new()
		space.custom_minimum_size.y = s.space_s
		space.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inside.add_child(space)
		var variation: StringName = entry[0]
		if variation == &"":
			inside.add_child(_coffee())
			continue
		var line: Label = UiKit.label(variation, entry[1], true)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inside.add_child(line)
	return card


## Buy me a coffee as on the title screen: a 40 dp face in a 48 dp touch
## area, only as wide as its label, at the card's left edge.
func _coffee() -> Control:
	var touch: UiKit.TouchTarget = UiKit.small_button(ThemeFactory.BUTTON_SECONDARY, COFFEE, Layout.ICON_FACE)
	touch.name = "Coffee"
	touch.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	coffee_button = touch.button
	coffee_button.name = "CoffeeButton"
	coffee_button.pressed.connect(func() -> void:
		if app != null:
			app.open_support_page())
	return touch


## "Version " and the version in the project settings.
static func version_line() -> String:
	return "Version %s" % str(ProjectSettings.get_setting("application/config/version", ""))


## Every notice item under the heading, in order (7.17): the engine's
## license, the third party components with their copyright and license
## lines (no file lists), then every license text.
static func notice_items(s: GameSkin) -> Array[Array]:
	var items: Array[Array] = []
	items.append([ThemeFactory.CAPTION, ENGINE_CAPTION, s.space_xl])
	_add_text(items, Engine.get_license_text(), s.space_xs, s)
	items.append([ThemeFactory.RULE, "", s.space_xl])
	items.append([ThemeFactory.HEADING, COMPONENTS_HEADING, s.space_xl])
	for entry: Dictionary in Engine.get_copyright_info():
		items.append([ThemeFactory.CAPTION, str(entry.get("name", "")), s.space_m])
		var first: bool = true
		for part: Variant in entry.get("parts", []):
			if typeof(part) != TYPE_DICTIONARY:
				continue
			var lines: PackedStringArray = PackedStringArray()
			for holder: Variant in (part as Dictionary).get("copyright", []):
				lines.append("Copyright %s" % str(holder))
			lines.append("License: %s" % str((part as Dictionary).get("license", "")))
			for line: String in lines:
				items.append([ThemeFactory.BODY_SMALL_12, line, s.space_xs if first else 0.0])
				first = false
	items.append([ThemeFactory.RULE, "", s.space_xl])
	items.append([ThemeFactory.HEADING, LICENSES_HEADING, s.space_xl])
	var licenses: Dictionary = Engine.get_license_info()
	for license_name: Variant in licenses.keys():
		items.append([ThemeFactory.CAPTION, str(license_name), s.space_m])
		_add_text(items, str(licenses[license_name]), s.space_xs, s)
	return items


static func _add_text(items: Array[Array], text: String, first_gap: float, s: GameSkin) -> void:
	var first: bool = true
	for paragraph: String in notice_paragraphs(text):
		items.append([ThemeFactory.BODY_SMALL_12, paragraph, first_gap if first else s.space_s])
		first = false


## Splits a hard wrapped text into paragraphs (7.17): at blank lines, and
## around any line with no letter or digit (a divider), which stays a
## paragraph of its own. Inside a paragraph the lines are joined with one
## space. Only white space changes: every word stays, in order.
static func notice_paragraphs(text: String) -> PackedStringArray:
	var paragraphs: PackedStringArray = PackedStringArray()
	var current: Array[String] = []
	for raw: String in text.replace("
", "
").split("
"):
		var line: String = raw.strip_edges()
		var divider: bool = not line.is_empty() and not _has_letter_or_digit(line)
		if line.is_empty() or divider:
			if not current.is_empty():
				paragraphs.append(" ".join(PackedStringArray(current)))
				current.clear()
			if divider:
				paragraphs.append(line)
			continue
		current.append(line)
	if not current.is_empty():
		paragraphs.append(" ".join(PackedStringArray(current)))
	return paragraphs


## True when line holds a digit or a letter of any script.
static func _has_letter_or_digit(line: String) -> bool:
	for i: int in line.length():
		var one: String = line.substr(i, 1)
		if one.is_valid_int() or one.to_upper() != one.to_lower():
			return true
	return false
