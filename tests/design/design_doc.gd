extends RefCounted
## Reads the tables of docs/DESIGN_SYSTEM.md, so the design tests check the
## code against the document itself rather than against a copy of its numbers.

const PATH: String = "res://docs/DESIGN_SYSTEM.md"


## The body rows of every table in the section whose heading starts with
## heading (for example "### 4.6" or "## 5."), up to the next heading of the
## same or a higher level. Each row is its cells, trimmed.
static func rows(heading: String) -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []
	for table: Array[PackedStringArray] in tables(heading):
		result.append_array(table)
	return result


## The same rows, one array per table, in document order.
static func tables(heading: String) -> Array[Array]:
	var result: Array[Array] = []
	var text: String = FileAccess.get_file_as_string(PATH)
	if text.is_empty():
		return result
	var level: int = heading.find(" ")
	var inside: bool = false
	var in_table: bool = false
	for line: String in text.split("\n"):
		var trimmed: String = line.strip_edges()
		if trimmed.begins_with("#"):
			var hashes: int = trimmed.find(" ")
			if inside and hashes <= level:
				break
			if trimmed.begins_with(heading):
				inside = true
			in_table = false
			continue
		if not inside:
			continue
		if not trimmed.begins_with("|"):
			in_table = false
			continue
		if not in_table:
			var fresh: Array[PackedStringArray] = []
			result.append(fresh)
			in_table = true
			continue # the header row
		var cells: PackedStringArray = PackedStringArray()
		var parts: PackedStringArray = trimmed.split("|")
		for i: int in range(1, parts.size() - 1):
			cells.append(parts[i].strip_edges())
		if cells.is_empty() or cells[0].begins_with("---"):
			continue
		(result[result.size() - 1] as Array[PackedStringArray]).append(cells)
	return result


## Text inside the first pair of backticks, or "" if none.
static func code(cell: String) -> String:
	var start: int = cell.find("`")
	var end: int = cell.find("`", start + 1)
	if start < 0 or end < 0:
		return ""
	return cell.substr(start + 1, end - start - 1)


## Text inside the first pair of double quotes, or "" if none.
static func quoted(cell: String) -> String:
	var start: int = cell.find("\"")
	var end: int = cell.find("\"", start + 1)
	if start < 0 or end < 0:
		return ""
	return cell.substr(start + 1, end - start - 1)


## Every backticked name in a cell.
static func codes(cell: String) -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	var parts: PackedStringArray = cell.split("`")
	for i: int in range(1, parts.size(), 2):
		found.append(parts[i])
	return found
