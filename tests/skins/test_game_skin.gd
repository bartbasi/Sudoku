extends "res://tests/unit_test.gd"
## GameSkin is exactly the skin schema of docs/DESIGN_SYSTEM.md section 1: the
## three identity fields, then one exported property per row of the "Skin
## tokens" table with the same name, type, order and group. Each skin file sets
## its id, is_dark and every token to the table's value for that skin.

const DESIGN_SYSTEM_PATH: String = "res://docs/DESIGN_SYSTEM.md"
const GAME_SKIN_PATH: String = "res://src/skins/game_skin.gd"
const POP_LIGHT_PATH: String = "res://src/skins/pop_light.tres"
const POP_DARK_PATH: String = "res://src/skins/pop_dark.tres"

## The header row of the token table. The identity table has a different one.
const TABLE_HEADER: String = "| Token | Type | Pop light | Pop dark |"

## The identity fields from ARCHITECTURE section 6, before every token and in
## no group.
const IDENTITY_NAMES: Array[String] = ["id", "display_name", "is_dark"]
const IDENTITY_TYPES: Array[int] = [TYPE_STRING_NAME, TYPE_STRING, TYPE_BOOL]

const FLOAT_TOLERANCE: float = 0.0001
const EXPORTED_USAGE: int = PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR


## One token row of the table, with the group heading it sits under.
class TokenRow:
	var name: String
	var type_name: String
	var light: String
	var dark: String
	var group: String
	var line: int


func test_game_skin_has_exactly_the_identity_fields_and_the_table_tokens() -> void:
	var rows: Array[TokenRow] = _read_token_table()
	var expected: Dictionary[String, int] = {}
	for i: int in IDENTITY_NAMES.size():
		expected[IDENTITY_NAMES[i]] = IDENTITY_TYPES[i]
	for row: TokenRow in rows:
		if expected.has(row.name):
			fail("DESIGN_SYSTEM.md line %d: %s is listed twice" % [row.line, row.name])
			continue
		expected[row.name] = TYPE_COLOR if row.type_name == "Color" else TYPE_FLOAT

	var found: Dictionary[String, bool] = {}
	for info: Dictionary in _game_skin_properties():
		var property: String = info["name"]
		var property_type: int = info["type"]
		var usage: int = info["usage"]
		found[property] = true
		if not expected.has(property):
			fail("GameSkin has %s, which is neither an identity field nor a table token" % property)
			continue
		if property_type != expected[property]:
			fail("GameSkin.%s is %s, the schema says %s" % [property, type_string(property_type), type_string(expected[property])])
		if (usage & EXPORTED_USAGE) != EXPORTED_USAGE:
			fail("GameSkin.%s is not exported" % property)
	for property: String in expected:
		if not found.has(property):
			fail("GameSkin is missing %s (%s)" % [property, type_string(expected[property])])


func test_game_skin_follows_the_table_order_and_groups() -> void:
	var rows: Array[TokenRow] = _read_token_table()
	var expected_names: Array[String] = []
	var expected_groups: Array[String] = []
	for identity: String in IDENTITY_NAMES:
		expected_names.append(identity)
		expected_groups.append("")
	for row: TokenRow in rows:
		expected_names.append(row.name)
		expected_groups.append(row.group)

	var names: Array[String] = []
	var groups: Array[String] = []
	var group: String = ""
	var script: GDScript = load(GAME_SKIN_PATH) as GDScript
	if script == null:
		fail("%s does not load" % GAME_SKIN_PATH)
		return
	for info: Dictionary in script.get_script_property_list():
		var usage: int = info["usage"]
		var entry: String = info["name"]
		if (usage & PROPERTY_USAGE_CATEGORY) != 0:
			continue
		if (usage & PROPERTY_USAGE_SUBGROUP) != 0:
			fail("GameSkin has a subgroup %s; the table has none" % entry)
			continue
		if (usage & PROPERTY_USAGE_GROUP) != 0:
			group = entry
			continue
		names.append(entry)
		groups.append(group)

	assert_eq(names.size(), expected_names.size(), "number of GameSkin properties")
	for i: int in mini(names.size(), expected_names.size()):
		if names[i] != expected_names[i]:
			fail("property %d is %s, the schema has %s there" % [i + 1, names[i], expected_names[i]])
			return
		if groups[i] != expected_groups[i]:
			fail("%s is in group \"%s\", the table puts it under \"%s\"" % [names[i], groups[i], expected_groups[i]])


func test_pop_light_file_matches_the_table() -> void:
	_check_skin_file(POP_LIGHT_PATH, &"pop_light", false)


func test_pop_dark_file_matches_the_table() -> void:
	_check_skin_file(POP_DARK_PATH, &"pop_dark", true)


func _check_skin_file(path: String, id: StringName, dark: bool) -> void:
	if not FileAccess.file_exists(path):
		fail("%s does not exist: the senior-graphic-designer has not written it yet" % path)
		return
	var skin: GameSkin = load(path) as GameSkin
	if skin == null:
		fail("%s does not load as a GameSkin" % path)
		return
	var file: String = path.get_file()
	assert_eq(skin.id, id, "%s id" % file)
	assert_eq(skin.is_dark, dark, "%s is_dark" % file)
	for row: TokenRow in _read_token_table():
		var written: String = row.dark if dark else row.light
		var value: Variant = skin.get(row.name)
		if row.type_name == "Color":
			if not Color.html_is_valid(written):
				fail("DESIGN_SYSTEM.md line %d: %s is not a color" % [row.line, written])
			elif not value is Color:
				fail("%s %s: expected a Color, got %s" % [file, row.name, type_string(typeof(value))])
			else:
				var color: Color = value
				var want: String = "#" + Color.html(written).to_html(true).to_upper()
				var got: String = "#" + color.to_html(true).to_upper()
				if got != want:
					fail("%s %s: expected %s, got %s" % [file, row.name, want, got])
		else:
			if not written.is_valid_float():
				fail("DESIGN_SYSTEM.md line %d: %s is not a number" % [row.line, written])
			elif not value is float:
				fail("%s %s: expected a float, got %s" % [file, row.name, type_string(typeof(value))])
			elif absf(float(value) - written.to_float()) > FLOAT_TOLERANCE:
				fail("%s %s: expected %s, got %s" % [file, row.name, written, str(value)])


## The script variables of GameSkin, without its category and group entries.
func _game_skin_properties() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	var script: GDScript = load(GAME_SKIN_PATH) as GDScript
	if script == null:
		fail("%s does not load" % GAME_SKIN_PATH)
		return properties
	var structure: int = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SUBGROUP
	for info: Dictionary in script.get_script_property_list():
		var usage: int = info["usage"]
		if (usage & structure) == 0:
			properties.append(info)
	return properties


## Reads the token table of DESIGN_SYSTEM.md section 1 as section 1 defines it:
## a row whose first cell is bold is a group heading, and a row whose first
## cell is a name in backticks with type Color or float is a token. Any other
## row in the table fails, so a row is never skipped without notice.
func _read_token_table() -> Array[TokenRow]:
	var rows: Array[TokenRow] = []
	if not FileAccess.file_exists(DESIGN_SYSTEM_PATH):
		fail("%s does not exist" % DESIGN_SYSTEM_PATH)
		return rows
	var lines: PackedStringArray = FileAccess.get_file_as_string(DESIGN_SYSTEM_PATH).split("\n")
	var header: int = -1
	for i: int in lines.size():
		if lines[i].strip_edges().begins_with(TABLE_HEADER):
			header = i
			break
	if header < 0:
		fail("%s has no token table starting with \"%s\"" % [DESIGN_SYSTEM_PATH, TABLE_HEADER])
		return rows

	var group: String = ""
	# header + 1 is the separator row under the header.
	for i: int in range(header + 2, lines.size()):
		var line: String = lines[i].strip_edges()
		if not line.begins_with("|"):
			break
		var cells: PackedStringArray = PackedStringArray()
		for cell: String in line.trim_prefix("|").trim_suffix("|").split("|"):
			cells.append(cell.strip_edges())
		var first: String = cells[0]
		if first.length() > 4 and first.begins_with("**") and first.ends_with("**"):
			group = first.substr(2, first.length() - 4)
			continue
		if cells.size() >= 4 and _is_code(first) and (cells[1] == "Color" or cells[1] == "float"):
			var row: TokenRow = TokenRow.new()
			row.name = _unquote(first)
			row.type_name = cells[1]
			row.light = _unquote(cells[2])
			row.dark = _unquote(cells[3])
			row.group = group
			row.line = i + 1
			rows.append(row)
			continue
		fail("DESIGN_SYSTEM.md line %d is neither a group heading nor a token row: %s" % [i + 1, line])

	if rows.is_empty():
		fail("the token table in %s has no token rows" % DESIGN_SYSTEM_PATH)
	return rows


## True for a cell like `page_bg`: one name in backticks, no spaces.
func _is_code(cell: String) -> bool:
	if cell.length() < 3 or not cell.begins_with("`") or not cell.ends_with("`"):
		return false
	var inner: String = _unquote(cell)
	return not inner.contains("`") and not inner.contains(" ")


func _unquote(cell: String) -> String:
	if cell.length() >= 2 and cell.begins_with("`") and cell.ends_with("`"):
		return cell.substr(1, cell.length() - 2)
	return cell
