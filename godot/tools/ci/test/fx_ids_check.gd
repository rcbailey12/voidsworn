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
const SPRITE := "Sprite kind"
const WOUND := "Wound style"

var _errors: Array[String] = []


func _init() -> void:
	var table := _read_table()
	if not table.is_empty():
		var sprites := _check_ids(SPRITE, table[SPRITE], SH, _errors)
		var wounds := _check_ids(WOUND, table[WOUND], BREACH, _errors)
		_check_selectors("SPRITE", SH.SPRITE, "k|profile", sprites, _errors)
		_check_selectors("HOLE", SH.HOLE, "style", wounds, _errors)
		_check_selectors("MARK", SH.MARK, "style", wounds, _errors)
	_check_regressions()
	for error in _errors:
		printerr("fx ids: FAIL: ", error)
	if _errors.is_empty():
		print("fx ids: PASS (%d sprite kinds, %d wound styles, zero collisions, regression cases passed)" %
			[table[SPRITE].size(), table[WOUND].size()])
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
	var table := {SPRITE: {}, WOUND: {}}
	var owners := {SPRITE: {}, WOUND: {}}
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
		_remember_id(ids, id, symbol, "API.md", group, _errors)
		if names.has(symbol):
			_errors.append("API.md repeats %s constant %s." % [group, symbol])
		names[symbol] = id
	return table


func _check_ids(group: String, documented: Dictionary, script: GDScript, errors: Array[String]) -> Dictionary:
	var constants := script.get_script_constant_map()
	var seen := {}
	var ids := {}
	var source := script.resource_path.get_file()
	if source.is_empty():
		source = "collision fixture"
	for key in constants:
		var symbol := String(key)
		var value: Variant = constants[key]
		if group == WOUND:
			if not symbol.begins_with("S_"):
				continue
		else:
			# The shader script's other integer IDs have their own namespaces.
			# All remaining integers count, even legacy or future names without SPR_.
			if symbol.begins_with("RING_") or symbol.begins_with("RIB_") or symbol.begins_with("DISTORT_"):
				continue
			if not value is int and not symbol.begins_with("SPR_") and not documented.has(symbol):
				continue
		if not value is int or value < 0:
			errors.append("%s: %s must be a nonnegative integer." % [source, symbol])
			continue
		seen[symbol] = true
		_remember_id(ids, value, symbol, source, group, errors)
		if not documented.has(symbol):
			errors.append("%s: %s is missing from API.md." % [source, symbol])
		elif value != documented[symbol]:
			errors.append("%s: %s is %d but API.md says %d." % [source, symbol, value, documented[symbol]])
	for symbol in documented:
		if not seen.has(symbol):
			errors.append("API.md: %s has no id constant in %s." % [symbol, source])
	return ids


func _remember_id(ids: Dictionary, id: int, symbol: String, source: String, group: String, errors: Array[String]) -> void:
	if ids.has(id):
		errors.append("%s: duplicate %s id %d (%s and %s)." % [source, group.to_lower(), id, ids[id], symbol])
	else:
		ids[id] = symbol


func _check_selectors(shader: String, code: String, variables: String, owners: Dictionary, errors: Array[String]) -> void:
	# COMMON's noise loop has its own k. The sprite code includes its bolt and muzzle masks.
	var comments := RegEx.create_from_string("(?s)/\\*.*?\\*/|//[^\\r\\n]*")
	code = comments.sub(code.replace(SH.COMMON, ""), "", true)
	var declarations := RegEx.create_from_string("\\bconst\\s+int\\s+(\\w+)\\s*=\\s*(-?\\d+)\\s*;")
	var shader_ids := {}
	for entry in declarations.search_all(code):
		shader_ids[entry.get_string(1)] = int(entry.get_string(2))

	var operand := "(-?\\d+|[A-Za-z_]\\w*)\\b"
	var bound := RegEx.create_from_string("\\b(%s)\\s*(>=|>)\\s*%s\\s*&&\\s*\\1\\s*(<=|<)\\s*%s" %
		[variables, operand, operand])
	var unknown := {}
	for entry in bound.search_all(code):
		var lo := _selector_id(shader, entry.get_string(3), shader_ids, owners, errors)
		var hi := _selector_id(shader, entry.get_string(5), shader_ids, owners, errors)
		if lo < 0 or hi < 0:
			continue
		lo += 1 if entry.get_string(2) == ">" else 0
		hi -= 1 if entry.get_string(4) == "<" else 0
		if hi < lo or hi - lo >= owners.size():
			errors.append("%s: invalid selector range %s." % [shader, entry.get_string()])
			continue
		for id in range(lo, hi + 1):
			_check_owner(shader, id, owners, unknown, errors)

	var comparison := RegEx.create_from_string("\\b(?:%s)\\s*(==|!=|>=|<=|>|<)\\s*%s" % [variables, operand])
	for entry in comparison.search_all(bound.sub(code, "", true)):
		var op := entry.get_string(1)
		if op not in ["==", "!="]:
			errors.append("%s: unbounded selector %s." % [shader, entry.get_string()])
			continue
		var id := _selector_id(shader, entry.get_string(2), shader_ids, owners, errors)
		if id >= 0:
			_check_owner(shader, id, owners, unknown, errors)


func _selector_id(shader: String, token: String, shader_ids: Dictionary, owners: Dictionary, errors: Array[String]) -> int:
	if token.is_valid_int() and int(token) >= 0:
		return int(token)
	if shader_ids.has(token) and owners.get(shader_ids[token]) == token:
		return shader_ids[token]
	errors.append("%s: selector %s does not match a registered owner." % [shader, token])
	return -1


func _check_owner(shader: String, id: int, owners: Dictionary, unknown: Dictionary, errors: Array[String]) -> void:
	if not owners.has(id) and not unknown.has(id):
		unknown[id] = true
		errors.append("%s: selects unregistered id %d." % [shader, id])


func _check_regressions() -> void:
	# PR #2069 before its fix: a non-SPR_ emitter and a new SPR_ emitter both owned 40.
	var fixture := GDScript.new()
	fixture.source_code = "extends RefCounted\nconst VENT_JET := 40\nconst SPR_NOVA_LEGACY := 40\n"
	if fixture.reload() != OK:
		_errors.append("Could not load the legacy/new sprite collision fixture.")
		return
	var errors: Array[String] = []
	_check_ids(SPRITE, {"VENT_JET": 40, "SPR_NOVA_LEGACY": 41}, fixture, errors)
	if not errors.any(func(error: String) -> bool:
		return "duplicate sprite kind id 40" in error and "VENT_JET" in error and "SPR_NOVA_LEGACY" in error):
		_errors.append("Regression: accepting a shared VENT_JET/SPR_NOVA_LEGACY id.")

	errors.clear()
	var owners := {30: "SPR_BOLT_PLASMA", 32: "SPR_BOLT_BOMB", 40: "VENT_JET", 41: "SPR_NOVA_LEGACY"}
	_check_selectors("fixture", "const int SPR_NOVA_LEGACY = 41; if (k == SPR_NOVA_LEGACY) {}", "k", owners, errors)
	if not errors.is_empty():
		_errors.append("Regression: rejecting a shader selector that matches its named owner.")

	errors.clear()
	_check_selectors("fixture", "const int SPR_NOVA_LEGACY = 40; if (k == SPR_NOVA_LEGACY || (k >= 30 && k <= 32)) {}",
		"k", owners, errors)
	if "fixture: selector SPR_NOVA_LEGACY does not match a registered owner." not in errors or \
			"fixture: selects unregistered id 31." not in errors:
		_errors.append("Regression: accepting a mismatched shader constant or an unowned id inside a range.")
