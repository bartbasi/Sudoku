extends SceneTree
## Writes the two skin files from the tables in docs/DESIGN_SYSTEM.md
## section 1, so the doc is the one place a skin value is edited:
##
##   timeout 300 godot --headless --path . --script res://tools/design/write_skins.gd
##
## Writes src/skins/pop_light.tres and src/skins/pop_dark.tres as text
## resources of script class GameSkin (format 3), with the identity fields and
## then every token in table order. Every value is written, even one that
## equals GameSkin's default, so each file shows the whole skin. Values are
## formatted with var_to_str(), Godot's own text resource writer. A file that
## already exists keeps its uid.
##
## Exits with 1, writing nothing, if the tables do not match GameSkin's
## properties (names, order, types) or a value does not parse.
## Then run check_contrast.gd. Owner: senior-graphic-designer.

const DESIGN_SYSTEM_PATH: String = "res://docs/DESIGN_SYSTEM.md"
const GAME_SKIN_PATH: String = "res://src/skins/game_skin.gd"
const SKIN_DIR: String = "res://src/skins/"
const SKIN_IDS: Array[String] = ["pop_light", "pop_dark"]
const IDENTITY_HEADER: String = "| Field | Type | `pop_light` | `pop_dark` |"
const TOKEN_HEADER: String = "| Token | Type | Pop light | Pop dark |"
const IDENTITY_FIELDS: Array[String] = ["id", "display_name", "is_dark"]


func _initialize() -> void:
	var result: Variant = call("_run")
	quit(result if result is int else 1)


func _run() -> int:
	var problems: PackedStringArray = PackedStringArray()
	var lines: PackedStringArray = FileAccess.get_file_as_string(DESIGN_SYSTEM_PATH).split("\n")
	var identity: Array[PackedStringArray] = _table(lines, IDENTITY_HEADER, problems)
	var tokens: Array[PackedStringArray] = _table(lines, TOKEN_HEADER, problems)
	var rows: Array[PackedStringArray] = identity + tokens
	var properties: Array[Dictionary] = _skin_properties()
	if rows.size() != properties.size():
		problems.append("the tables have %d rows, GameSkin has %d properties" % [rows.size(), properties.size()])
	for n: int in mini(rows.size(), properties.size()):
		var name: String = _unquote(rows[n][0])
		var expected: String = properties[n]["name"]
		if name != expected:
			problems.append("row %d is %s, GameSkin has %s there" % [n + 1, name, expected])
	for side: int in SKIN_IDS.size():
		var values: PackedStringArray = PackedStringArray()
		for n: int in mini(rows.size(), properties.size()):
			var cell: String = _unquote(rows[n][2 + side])
			var text: String = _value_text(cell, properties[n]["type"], problems, rows[n][0])
			values.append("%s = %s" % [properties[n]["name"], text])
		if not problems.is_empty():
			break
		var id: String = SKIN_IDS[side]
		if _unquote(identity[0][2 + side]) != id:
			problems.append("the identity table's id for column %d is not %s" % [side + 1, id])
			break
		_write(id, values, problems)
	for problem: String in problems:
		print("FAIL  %s" % problem)
	if problems.is_empty():
		print("Wrote %d skins with %d tokens each." % [SKIN_IDS.size(), tokens.size()])
		return 0
	return 1


## The rows of the table whose header row starts with header: every row that
## names a field or token in backticks. Bold rows are group headings.
func _table(lines: PackedStringArray, header: String, problems: PackedStringArray) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var start: int = -1
	for i: int in lines.size():
		if lines[i].strip_edges().begins_with(header):
			start = i + 2
			break
	if start < 0:
		problems.append("no table starting with %s" % header)
		return rows
	for i: int in range(start, lines.size()):
		var line: String = lines[i].strip_edges()
		if not line.begins_with("|"):
			break
		var cells: PackedStringArray = PackedStringArray()
		for cell: String in line.trim_prefix("|").trim_suffix("|").split("|"):
			cells.append(cell.strip_edges())
		if cells[0].begins_with("`"):
			rows.append(cells)
	return rows


## GameSkin's exported script variables, in declaration order.
func _skin_properties() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var script: GDScript = load(GAME_SKIN_PATH) as GDScript
	for info: Dictionary in script.get_script_property_list():
		var usage: int = info["usage"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			out.append(info)
	return out


func _value_text(cell: String, kind: int, problems: PackedStringArray, row: String) -> String:
	match kind:
		TYPE_COLOR:
			if not Color.html_is_valid(cell):
				problems.append("%s: %s is not a color" % [row, cell])
				return ""
			return var_to_str(Color.html(cell))
		TYPE_FLOAT:
			if not cell.is_valid_float():
				problems.append("%s: %s is not a number" % [row, cell])
				return ""
			return var_to_str(cell.to_float())
		TYPE_STRING_NAME:
			return var_to_str(StringName(cell))
		TYPE_STRING:
			return var_to_str(cell)
		TYPE_BOOL:
			if cell != "true" and cell != "false":
				problems.append("%s: %s is not true or false" % [row, cell])
			return var_to_str(cell == "true")
	problems.append("%s: GameSkin has a property type the writer does not know" % row)
	return ""


func _write(id: String, values: PackedStringArray, problems: PackedStringArray) -> void:
	var path: String = SKIN_DIR + id + ".tres"
	var uid: String = _existing_uid(path)
	if uid.is_empty():
		uid = ResourceUID.id_to_text(ResourceUID.create_id())
	var script_uid: String = ResourceUID.id_to_text(ResourceLoader.get_resource_uid(GAME_SKIN_PATH))
	var text: String = "[gd_resource type=\"Resource\" script_class=\"GameSkin\" format=3 uid=\"%s\"]\n\n" % uid
	text += "[ext_resource type=\"Script\" uid=\"%s\" path=\"%s\" id=\"1_skin\"]\n\n" % [script_uid, GAME_SKIN_PATH]
	text += "[resource]\nscript = ExtResource(\"1_skin\")\n"
	text += "\n".join(values) + "\n"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		problems.append("could not write %s" % path)
		return
	file.store_string(text)
	file.close()
	print("wrote %s" % path)


func _existing_uid(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var first: String = FileAccess.get_file_as_string(path).get_slice("\n", 0)
	var at: int = first.find("uid=\"")
	if at < 0:
		return ""
	return first.substr(at + 5).get_slice("\"", 0)


func _unquote(cell: String) -> String:
	if cell.length() >= 2 and cell.begins_with("`") and cell.ends_with("`"):
		return cell.substr(1, cell.length() - 2)
	return cell
