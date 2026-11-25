extends SceneTree
## Issue 2148: names and numbers must agree with the owner table, including reservations.
## The same number can belong to a sprite and a wound, but never to two of either.

const SH := preload("res://fx/fx_shaders.gd")
const BREACH := preload("res://fx/fx_breach.gd")
const API := "res://fx/API.md"
const BEGIN := "<!-- fx-ids:begin -->"
const END := "<!-- fx-ids:end -->"
const HEADER := "| Namespace | ID | Constant | Owner |"
const DIVIDER := "| --- | --- | --- | --- |"

var _errors: Array[String] = []


func _init() -> void:
	var table := _read_table()
	if not table.is_empty():
		_check_ids("Sprite kind", table["Sprite kind"], SH, "SPR_")
		_check_ids("Wound style", table["Wound style"], BREACH, "S_")
		_check_sprite_selectors(table["Sprite kind"])
	for error in _errors:
		printerr("fx ids: FAIL: ", error)
	if _errors.is_empty():
		print("fx ids: PASS (%d sprite kinds, %d wound styles)" %
			[table["Sprite kind"].size(), table["Wound style"].size()])
	quit(0 if _errors.is_empty() else 1)


func _read_table() -> Dictionary:
	var md := FileAccess.get_file_as_string(API)
	if md.count(BEGIN) != 1 or md.count(END) != 1 or md.find(BEGIN) > md.find(END):
		_errors.append("API.md must have exactly one FX id table.")
		return {}
	var start := md.find(BEGIN) + BEGIN.length()
	var lines := md.substr(start, md.find(END) - start).strip_edges().split("\n")
	if lines.size() < 3 or lines[0].strip_edges() != HEADER or lines[1].strip_edges() != DIVIDER:
		_errors.append("API.md is missing the FX id table header or rows.")
		return {}
	var table := {"Sprite kind": {}, "Wound style": {}}
	var owners := {"Sprite kind": {}, "Wound style": {}}
	for i in range(2, lines.size()):
		var line := lines[i].strip_edges()
		var fields := line.split("|")
		if fields.size() != 6 or not fields[0].is_empty() or not fields[5].is_empty():
			_errors.append("Malformed API.md row: %s" % line)
			continue
		var group := fields[1].strip_edges()
		var number := fields[2].strip_edges()
		var symbol := fields[3].strip_edges()
		if not table.has(group) or not number.is_valid_int() or int(number) < 0 or \
				not symbol.begins_with("`") or not symbol.ends_with("`") or fields[4].strip_edges().is_empty():
			_errors.append("Invalid API.md FX id row: %s" % line)
			continue
		symbol = symbol.substr(1, symbol.length() - 2)
		var id := int(number)
		var names: Dictionary = table[group]
		var ids: Dictionary = owners[group]
		_remember_id(ids, id, symbol, "API.md", group)
		if names.has(symbol):
			_errors.append("API.md repeats %s constant %s." % [group, symbol])
		names[symbol] = id
	return table


func _check_ids(group: String, documented: Dictionary, script: GDScript, prefix: String) -> void:
	var constants := script.get_script_constant_map()
	var seen := {}
	var ids := {}
	var source := script.resource_path.get_file()
	for key in constants:
		var symbol := String(key)
		if not symbol.begins_with(prefix):
			continue
		var value: Variant = constants[key]
		if not value is int or value < 0:
			_errors.append("%s: %s must be a nonnegative integer." % [source, symbol])
			continue
		seen[symbol] = true
		_remember_id(ids, value, symbol, source, group)
		if not documented.has(symbol):
			_errors.append("%s: %s is missing from API.md." % [source, symbol])
		elif value != documented[symbol]:
			_errors.append("%s: %s is %d but API.md says %d." % [source, symbol, value, documented[symbol]])
	for symbol in documented:
		if not seen.has(symbol):
			_errors.append("API.md: %s has no id constant in %s." % [symbol, source])


func _remember_id(ids: Dictionary, id: int, symbol: String, source: String, group: String) -> void:
	if ids.has(id):
		_errors.append("%s: duplicate %s id %d (%s and %s)." % [source, group.to_lower(), id, ids[id], symbol])
	else:
		ids[id] = symbol


func _check_sprite_selectors(documented: Dictionary) -> void:
	# Old branches used bare numbers even when they had no kind constant.
	var selector := RegEx.create_from_string("\\bk\\s*(?:==|!=|>=|<=|>|<)\\s*(\\d+)\\b")
	var ids := documented.values()
	var unknown := {}
	for match_ in selector.search_all(SH.SPRITE):
		var id := int(match_.get_string(1))
		if id not in ids and not unknown.has(id):
			unknown[id] = true
			_errors.append("fx_shaders.gd: SPRITE selects unregistered sprite kind %d." % id)
