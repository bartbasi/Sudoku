extends UiScreen
## The About screen (GDD 15.6, DESIGN_SYSTEM.md 7.17): a card with the name,
## the version, the credit and copyright lines, the short paragraph, the
## license line with the source code address, the support line with the
## Buy me a coffee button, the contact and privacy lines and the Godot line;
## then the open source notices: the game's own notice and the GNU General
## Public License, version 3, read at run time from res://NOTICE and
## res://COPYING, then the engine's notices, read from the engine
## (Engine.get_license_text, get_copyright_info and get_license_info). No
## notice text is copied into the game.
##
## The credit and copyright lines are license terms (NOTICE, section 7(b)):
## they are never cut, recased, made smaller or hidden.
##
## Only Back and Buy me a coffee react to a tap. Buy me a coffee hands the
## support page to the phone's web browser (App.open_support_page), as on
## the title screen; the game itself sends nothing. The source code, email
## and privacy addresses are plain text, and nothing in the notices can be
## tapped.
##
## The notices are long (about 115,000 characters), so the screen builds the
## card and the notices heading at once and the notice labels after its
## first frame, appended at the bottom for at most FRAME_BUDGET_USEC each
## frame. One label per
## paragraph; every label wraps (smart word wrap, minimum width 1), so
## nothing scrolls sideways. Hard wrapped lines are joined into paragraphs
## (notice_paragraphs); only white space changes.
## Owner: ui-systems-dev.

const NAME: String = "Sudoku"
const CREDIT: String = "Designed and written by Bart Basi."
const COPYRIGHT: String = "Copyright 2026 Play, Inc."
const PARAGRAPH: String = "Sudoku is free. It works offline, with no ads and no accounts, and it collects no data. Everything you do stays on this device."
const LICENSE: String = "Sudoku is free software under the GNU General Public License, version 3, with additional terms. It comes with no warranty. The license and its terms are below. Source code: github.com/bartbasi/Sudoku"
const SUPPORT: String = "If you enjoy it and want to support the game, you can buy me a coffee."
const COFFEE: String = "Buy me a coffee"
const CONTACT: String = "Questions, feedback and notices: bartbasi@gmail.com"
const PRIVACY: String = "Privacy policy: bartbasi.github.io/Sudoku/privacy"
const MADE_WITH: String = "Made with the Godot Engine."
const NOTICES_HEADING: String = "Open source notices"
const NOTICE_CAPTION: String = "Sudoku"
const GPL_CAPTION: String = "GNU General Public License, version 3"
const ENGINE_CAPTION: String = "Godot Engine"
const COMPONENTS_HEADING: String = "Third party components"
const LICENSES_HEADING: String = "Licenses"
## The game's own notice and license, shipped in the package.
const NOTICE_PATH: String = "res://NOTICE"
const COPYING_PATH: String = "res://COPYING"
## In the game's own files, a line shorter than this ends its line instead
## of joining the next (title lines such as "Sudoku" over its copyright).
## Their wrapped prose lines are all longer.
const SHORT_LINE: int = 40
## Time spent making notice labels in one frame after the first frame
## (7.17), in microseconds. At least one label is made each frame, so the
## build always ends; the budget keeps each frame short whatever the
## label sizes.
const FRAME_BUDGET_USEC: int = 4000
## Notice items per block. The items go into small boxes stacked in
## notices, so adding one re-lays out only its own block and the short list
## of blocks, not every label built so far.
const BLOCK_ITEMS: int = 32

## The scrolling page, for tests.
var scroll: ScrollContainer = null
var version_label: Label = null
## The face of Buy me a coffee in the card.
var coffee_button: Button = null
## The notices under the heading: blocks of BLOCK_ITEMS items each, every
## item's gap or rule in the same block as its label.
var notices: VBoxContainer = null
var _block: VBoxContainer = null
var _block_items: int = 0

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
	_build_for(FRAME_BUDGET_USEC)


## True once every notice label is built.
func is_complete() -> bool:
	return _next >= _pending.size()


## Builds every notice label left, now. For tests, which run without frames.
func build_all_notices() -> void:
	_build_some(_pending.size())


## Makes labels until budget_usec has passed, at least one.
func _build_for(budget_usec: int) -> void:
	var s: GameSkin = skin()
	var start: int = Time.get_ticks_usec()
	while _next < _pending.size():
		_add_item(s, _pending[_next])
		_next += 1
		if Time.get_ticks_usec() - start >= budget_usec:
			break
	if is_complete():
		set_process(false)


func _build_some(count: int) -> void:
	var s: GameSkin = skin()
	var end: int = mini(_next + count, _pending.size())
	while _next < end:
		_add_item(s, _pending[_next])
		_next += 1
	if is_complete():
		set_process(false)


func _add_item(s: GameSkin, item: Array) -> void:
	if _block == null or _block_items >= BLOCK_ITEMS:
		_block = UiKit.vbox(0.0)
		_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		notices.add_child(_block)
		_block_items = 0
	_block_items += 1
	var gap: float = item[2]
	if gap > 0.0:
		var space: Control = Control.new()
		space.custom_minimum_size.y = gap
		space.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_block.add_child(space)
	var variation: StringName = item[0]
	if variation == ThemeFactory.RULE:
		var rule: HSeparator = HSeparator.new()
		rule.theme_type_variation = ThemeFactory.RULE
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_block.add_child(rule)
		return
	var line: Label = UiKit.label(variation, item[1], true)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_block.add_child(line)


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
		[ThemeFactory.BODY, PARAGRAPH], [ThemeFactory.BODY_SMALL, LICENSE], [ThemeFactory.BODY, SUPPORT],
		[&"", COFFEE], [ThemeFactory.BODY_SMALL, CONTACT], [ThemeFactory.BODY_SMALL, PRIVACY],
		[ThemeFactory.BODY, MADE_WITH]]
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


## The text of a file shipped in the package, or "" when it is missing or
## cannot be read. Read as plain text only.
static func read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


## Every notice item under the heading, in order (7.17): the game's notice,
## the GNU General Public License, version 3, then the engine's license,
## the third party components with their copyright and license lines (no
## file lists), then every license text. A missing file shows nothing.
static func notice_items(s: GameSkin) -> Array[Array]:
	var items: Array[Array] = []
	var own: bool = false
	for pair: Array in [[NOTICE_CAPTION, NOTICE_PATH], [GPL_CAPTION, COPYING_PATH]]:
		var text: String = read_text(pair[1])
		if notice_paragraphs(text, true).is_empty():
			continue
		items.append([ThemeFactory.CAPTION, pair[0], s.space_xl])
		_add_text(items, text, s.space_xs, s, true)
		own = true
	if own:
		items.append([ThemeFactory.RULE, "", s.space_xl])
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


static func _add_text(items: Array[Array], text: String, first_gap: float, s: GameSkin, keep_short_lines: bool = false) -> void:
	var first: bool = true
	for paragraph: String in notice_paragraphs(text, keep_short_lines):
		items.append([ThemeFactory.BODY_SMALL_12, paragraph, first_gap if first else s.space_s])
		first = false


## Splits a hard wrapped text into paragraphs (7.17): at blank lines, and
## around any line with no letter or digit (a divider), which stays a
## paragraph of its own. Inside a paragraph the lines are joined with one
## space. With keep_short_lines (the game's own files), a line shorter than
## SHORT_LINE ends with a line break instead. Only white space changes:
## every word stays, in order.
static func notice_paragraphs(text: String, keep_short_lines: bool = false) -> PackedStringArray:
	var paragraphs: PackedStringArray = PackedStringArray()
	var current: String = ""
	var open: bool = false
	for raw: String in text.replace("\r\n", "\n").split("\n"):
		var line: String = raw.strip_edges()
		var divider: bool = not line.is_empty() and not _has_letter_or_digit(line)
		if line.is_empty() or divider:
			if open:
				paragraphs.append(current)
				current = ""
				open = false
			if divider:
				paragraphs.append(line)
			continue
		if open:
			current += line
		else:
			current = line
			open = true
		# The joint after this line, dropped if the paragraph ends here.
		if keep_short_lines and line.length() < SHORT_LINE:
			current += "\n"
		else:
			current += " "
	if open:
		paragraphs.append(current)
	for i: int in paragraphs.size():
		paragraphs[i] = paragraphs[i].rstrip(" \n")
	return paragraphs


## True when line holds a digit or a letter of any script.
static func _has_letter_or_digit(line: String) -> bool:
	for i: int in line.length():
		var one: String = line.substr(i, 1)
		if one.is_valid_int() or one.to_upper() != one.to_lower():
			return true
	return false
