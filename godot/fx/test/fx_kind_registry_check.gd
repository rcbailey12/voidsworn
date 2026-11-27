extends SceneTree
# Issue 2176: check the shared effect IDs without a renderer.

const FX := preload("res://fx/fx.gd")
const SH := preload("res://fx/fx_shaders.gd")
const SPECIAL := preload("res://fx/fx_special.gd")
const FAMILIES := {
	"SPRITE": FX.SpriteKind, "STREAK": FX.StreakKind, "RING": FX.RingKind,
	"RIBBON": FX.RibbonKind, "DISTORT": FX.DistortKind, "BREACH": FX.BreachStyle,
}
const ENUM_NAMES := {
	"SpriteKind": "SPRITE", "StreakKind": "STREAK", "RingKind": "RING",
	"RibbonKind": "RIBBON", "DistortKind": "DISTORT", "BreachStyle": "BREACH",
}
const PREFIXES := {
	"SPR_": "SPRITE", "STREAK_": "STREAK", "RING_": "RING",
	"RIB_": "RIBBON", "DISTORT_": "DISTORT", "S_": "BREACH",
}
# These pre-registry names are uses of a shipped kind, not separate allocations.
const LEGACY_ALIASES := {
	"fx.gd:HOT_FLECK_SPRITE": ["SPRITE", "EMBER"],
	"fx_idle.gd:KIND": ["SPRITE", "SOFT_LIFT"],
}
# Kind argument (zero-based) in each shared emitter.
const EMITTERS := {
	"spr": ["SPRITE", 7], "sprx": ["SPRITE", 8], "_emit_spr": ["SPRITE", 7],
	"stk": ["STREAK", 7], "flight_streak": ["STREAK", 7], "ring": ["RING", 8],
	"rib": ["RIBBON", 9], "dst": ["DISTORT", 5],
}
const BREACH_EMITTERS := {"hole": 7, "crater": 5, "dent": 5, "cluster": 7, "surface": 4, "place_hole": 6}
const OPERAND := "(-?\\d+|[A-Za-z_]\\w*)"
const OPERATOR := "\\s*(==|!=|<=|>=|<|>)\\s*"

var problems: Array[String] = []


func _initialize() -> void:
	for family: String in FAMILIES:
		var seen := {}
		for kind: String in FAMILIES[family]:
			var id: int = FAMILIES[family][kind]
			if seen.has(id):
				problems.append("%s kind %d is assigned to both %s and %s" % [family, id, seen[id], kind])
			seen[id] = kind

	problems.append_array(_named_kind_problems(_read_fx_scripts()))
	_check_mirrors()
	var k := "\\b(?:k|kind)\\b"
	# The bolt and muzzle helpers receive the same kind as a parameter named profile.
	var weapon_kind := "\\b(?:k|kind|profile)\\b"
	_check_shader("SPRITE", SH.SPRITE, weapon_kind)
	_check_shader("STREAK", SH.STREAK, weapon_kind)
	_check_shader("RING", SH.RING, "\\b(?:k|rk|kind)\\b")
	_check_shader("RIBBON", SH.RIBBON, k)
	_check_shader("DISTORT", SH.DISTORT, k)
	var style := "\\bstyle\\b"
	_check_shader("HOLE", SH.HOLE, "(?:" + style + "|int\\(\\s*CUSTOM2\\.w\\s*\\+\\s*0\\.5\\s*\\))", "BREACH")
	_check_shader("MARK", SH.MARK, style, "BREACH")
	_check_fixtures()

	for problem in problems:
		printerr("FAIL: ", problem)
	if problems.is_empty():
		print("PASS: six kind families, emitter constants, shader arms and collision fixtures")
	quit(0 if problems.is_empty() else 1)


func _read_fx_scripts() -> Dictionary:
	var scripts := {}
	for file in DirAccess.get_files_at("res://fx"):
		if not file.ends_with(".gd"):
			continue
		var script := load("res://fx/" + file) as Script
		if not script or not script.can_instantiate():
			problems.append("Cannot read kind declarations from res://fx/" + file)
			continue
		scripts[file] = {"source": script.source_code, "constants": script.get_script_constant_map()}
	if scripts.is_empty():
		problems.append("No scripts found in res://fx")
	return scripts


func _named_kind_problems(scripts: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var claims := {}
	var uses := _emitter_uses(scripts)
	var enum_alias := RegEx.create_from_string(
		"(?m)^\\s*const\\s+(\\w+)(?:\\s*:\\s*int)?\\s*:?=\\s*(?:\\w+\\.)?(\\w+)\\.(\\w+)\\s*(?:#.*)?$")
	for file: String in scripts:
		var aliases := {}
		for entry in enum_alias.search_all(scripts[file]["source"]):
			if ENUM_NAMES.has(entry.get_string(2)):
				aliases[entry.get_string(1)] = [ENUM_NAMES[entry.get_string(2)], entry.get_string(3)]
		for name: String in scripts[file]["constants"]:
			var value: Variant = scripts[file]["constants"][name]
			if not value is int:
				continue
			var location := "%s:%s" % [file, name]
			var alias: Array = aliases.get(name, LEGACY_ALIASES.get(location, []))
			var used_families: Array = uses.get(location, [])
			var meaning: Array = alias if not alias.is_empty() else _named_meaning(name, "")
			if meaning.is_empty() and not used_families.is_empty():
				meaning = _named_meaning(name, used_families[0])
			# Unprefixed integers in the shared shader source are sprite allocations unless
			# a registry name, family prefix or emitter identifies another family.
			if meaning.is_empty() and file == "fx_shaders.gd":
				meaning = ["SPRITE", name]
			if meaning.is_empty():
				continue
			var family: String = meaning[0]
			var kind: String = meaning[1]
			for used_family: String in used_families:
				if used_family != family:
					errors.append("%s is a %s kind used in a %s emitter" % [location, family, used_family])
			var id: int = value
			var expected: Variant = FAMILIES[family].get(kind)
			if id != expected:
				var owner := _kind_at(family, id)
				errors.append("%s %s uses ID %d%s%s" % [family, location, id,
					" already registered to " + owner if not owner.is_empty() else " (unregistered)",
					", expected %s = %d" % [kind, expected] if expected != null else ", no entry for " + kind])
			if alias.is_empty():
				var key := "%s:%d" % [family, id]
				if claims.has(key):
					errors.append("%s ID %d is claimed by both %s and %s" % [family, id, claims[key], location])
				else:
					claims[key] = location
	return errors


func _named_meaning(name: String, used_family: String) -> Array:
	if name.begins_with("BOLT_"):
		var bolt_family := "STREAK" if FX.StreakKind.has(name) else "SPRITE"
		return [used_family if not used_family.is_empty() else bolt_family, name]
	if name.begins_with("MUZZLE_") or name.begins_with("TICK_"):
		return ["SPRITE", name]
	for prefix: String in PREFIXES:
		if name.begins_with(prefix):
			var family: String = PREFIXES[prefix]
			return [family, name.trim_prefix(prefix)]
	if not used_family.is_empty():
		return [used_family, name]
	var matching: Array[String] = []
	for family: String in FAMILIES:
		if FAMILIES[family].has(name):
			matching.append(family)
	return [matching[0], name] if matching.size() == 1 else []


func _emitter_uses(scripts: Dictionary) -> Dictionary:
	# Also find a plain name like VENT_JET or NEW_GLOB passed in the kind slot.
	var call := RegEx.create_from_string("\\b(?:(\\w+)\\.)?(" + "|".join(EMITTERS.keys())
		+ "|" + "|".join(BREACH_EMITTERS.keys()) + ")\\s*\\(")
	var symbol := RegEx.create_from_string("^\\s*(?:(\\w+)\\.)?([A-Z][A-Z0-9_]*)\\s*$")
	var choice := RegEx.create_from_string("(?s)^(.+?)\\s+if\\s+.+\\s+else\\s+(.+)$")
	var ignored := RegEx.create_from_string("(?s:\"\"\".*?\"\"\")|\"(?:\\\\.|[^\"\\\\])*\"|'(?:\\\\.|[^'\\\\])*'|#[^\\n]*")
	var uses := {}
	for file: String in scripts:
		var code: String = scripts[file]["source"]
		code = ignored.sub(code, "\"\"", true)
		for hit in call.search_all(code):
			var method := hit.get_string(2)
			var emitter: Array = EMITTERS.get(method, [])
			if emitter.is_empty():
				if _constant_file(file, hit.get_string(1), scripts) != "fx_breach.gd":
					continue
				emitter = ["BREACH", BREACH_EMITTERS[method]]
			var argument := _call_arg(code, hit.get_end(), emitter[1])
			var branches := choice.search(argument)
			for expression: String in [branches.get_string(1), branches.get_string(2)] if branches else [argument]:
				var name := symbol.search(expression)
				if not name:
					continue
				var target := _constant_file(file, name.get_string(1), scripts)
				if not target.is_empty():
					var location := "%s:%s" % [target, name.get_string(2)]
					var families: Array = uses.get_or_add(location, [])
					if emitter[0] not in families:
						families.append(emitter[0])
	return uses


func _constant_file(file: String, qualifier: String, scripts: Dictionary) -> String:
	if qualifier in ["", "self"]:
		return file
	if qualifier == "fx":
		return "fx.gd"
	var receiver: Variant = scripts[file]["constants"].get(qualifier)
	if receiver is Script and receiver.resource_path.get_base_dir() == "res://fx":
		return receiver.resource_path.get_file()
	return ""


func _call_arg(code: String, start: int, slot: int) -> String:
	var depth := 0
	var first := start
	for i in range(start, code.length()):
		var token := code[i]
		if token in ["(", "[", "{"]:
			depth += 1
		elif depth == 0 and token in [",", ")"]:
			if slot == 0:
				return code.substr(first, i - first)
			if token == ")":
				break
			first = i + 1
			slot -= 1
		elif token in [")", "]", "}"]:
			depth -= 1
	return ""


func _kind_at(family: String, id: int) -> String:
	for kind: String in FAMILIES[family]:
		if FAMILIES[family][kind] == id:
			return kind
	return ""


func _check_mirrors() -> void:
	var breach := load("res://fx/fx_breach.gd") as Script
	var constants := breach.get_script_constant_map()
	for kind: String in FX.BreachStyle:
		if constants.get("S_" + kind) != FX.BreachStyle[kind]:
			problems.append("BREACH S_%s does not match fx.gd" % kind)
	for shape: String in SPECIAL.RIFT_SHAPES:
		if FX.RingKind.get("RIFT_" + shape.to_upper()) != SPECIAL.RIFT_SHAPES[shape]:
			problems.append("RING rift shape %s does not match fx.gd" % shape)


func _check_shader(label: String, source: String, selector: String, family := "") -> void:
	problems.append_array(_shader_problems(label, source, selector, family if not family.is_empty() else label))


func _shader_problems(label: String, source: String, selector: String, family: String, kinds: Dictionary = {}) -> Array[String]:
	# Skip the common math helpers, which have their own unrelated loop index k.
	var comments := RegEx.create_from_string("(?s:/\\*.*?\\*/)|//[^\\n]*")
	var code := comments.sub(source.replace(SH.COMMON, ""), "", true)
	if kinds.is_empty():
		kinds = FAMILIES[family]
	var constants := {}
	var errors: Array[String] = []
	var declaration := RegEx.create_from_string("(?:\\bconst\\s+int\\s+(\\w+)\\s*=\\s*|#define\\s+(\\w+)\\s+)(-?\\d+)\\b(?!\\.)")
	for entry in declaration.search_all(code):
		var name := entry.get_string(1) if entry.get_string(1) != "" else entry.get_string(2)
		if constants.has(name):
			errors.append("%s shader declares %s more than once" % [label, name])
		constants[name] = entry.get_string(3).to_int()

	var right := RegEx.create_from_string(selector + OPERATOR + OPERAND + "(?![\\w.])")
	var left := RegEx.create_from_string("(?<![\\w.])" + OPERAND + OPERATOR + selector)
	var checked_names := {}
	for direction in [[right, 2], [left, 1]]:
		for comparison: RegExMatch in direction[0].search_all(code):
			var value := comparison.get_string(direction[1])
			var id: Variant = _resolve_id(value, constants)
			if not kinds.values().has(id):
				errors.append("%s shader uses an unregistered kind in %s" % [label, comparison.get_string()])
			elif not value.is_valid_int() and not checked_names.has(value):
				checked_names[value] = true
				var meaning := _named_meaning(value, family)
				if kinds.get(meaning[1]) != id:
					errors.append("%s shader %s uses ID %d, not its registered kind" % [label, value, id])
	errors.append_array(_dispatch_problems(label, code, kinds, constants, right, left))
	return errors


func _resolve_id(value: String, constants: Dictionary) -> Variant:
	return value.to_int() if value.is_valid_int() else constants.get(value)


func _dispatch_problems(label: String, code: String, kinds: Dictionary, constants: Dictionary,
		right: RegEx, left: RegEx) -> Array[String]:
	var errors: Array[String] = []
	var tokens := RegEx.create_from_string("(\\belse\\s+)?\\bif\\s*\\(|\\bvoid\\s+fragment\\s*\\(\\s*\\)\\s*\\{|[{}]")
	var rift := RegEx.create_from_string("bool is_rift_ring\\(int k\\)\\s*\\{\\s*return\\s+([^;]+);").search(code)
	var scopes: Array[Dictionary] = [{"chain": {}, "fragment_root": false, "arms": {}}]
	var cursor := 0
	while true:
		var hit := tokens.search(code, cursor)
		if not hit:
			break
		var token := hit.get_string()
		cursor = hit.get_end()
		if token == "{":
			scopes.append({"chain": {}, "fragment_root": false, "arms": {}})
		elif token.begins_with("void"):
			scopes.append({"chain": {}, "fragment_root": true, "arms": {}})
		elif token == "}":
			scopes.pop_back()
		else:
			var condition := _call_arg(code, cursor, 0)
			# The first argument reader is also a balanced parenthesis reader for shader conditions.
			cursor += condition.length()
			var scope: Dictionary = scopes.back()
			if hit.get_string(1).is_empty():
				scope["chain"] = {}
			var predicate := condition
			if rift:
				for selector: String in ["k", "rk"]:
					predicate = predicate.replace("is_rift_ring(%s)" % selector,
						"(" + rift.get_string(1).replace("k ", selector + " ") + ")")
			for id: int in _arm_ids(predicate, kinds, constants, right, left):
				if id not in kinds.values():
					errors.append("%s shader dispatch arm (%s) selects unregistered ID %d" % [label, condition.strip_edges(), id])
					continue
				var previous: String = scope["chain"].get(id, "")
				# Sibling top-level fragment arms compete even in separate if statements.
				# Vertex and nested passes can adjust separate properties of one kind (e.g. MARK).
				if previous.is_empty() and scope["fragment_root"]:
					previous = scope["arms"].get(id, "")
				var arm := condition.strip_edges()
				if not previous.is_empty():
					errors.append("%s shader ID %d has competing dispatch arms (%s) and (%s)" % [label, id, previous, arm])
				scope["chain"][id] = arm
				scope["arms"][id] = arm
	return errors


func _arm_ids(condition: String, kinds: Dictionary, constants: Dictionary, right: RegEx, left: RegEx) -> Array[int]:
	# A dispatch arm uses only the kind, with equality, alternatives, or a bounded range.
	# Mixed guards, nested refinements and other passes are not competing owners.
	var ids: Array[int] = []
	var boundaries: Array[int] = []
	var reverse := {"==": "==", "!=": "!=", "<": ">", "<=": ">=", ">": "<", ">=": "<="}
	var replacements := {}
	var lower := false
	var upper := false
	var equal := false
	for direction in [[right, 2, 1], [left, 1, 2]]:
		for hit: RegExMatch in direction[0].search_all(condition):
			var id: Variant = _resolve_id(hit.get_string(direction[1]), constants)
			var op := hit.get_string(direction[2])
			# The comparison pass reports missing bounds. Only enumerate ranges with known bounds.
			if id not in kinds.values() or op == "!=":
				return ids
			boundaries.append(id)
			if direction[1] == 1:
				op = reverse[op]
			lower = lower or op.begins_with(">")
			upper = upper or op.begins_with("<")
			equal = equal or op == "=="
			replacements[hit.get_start()] = [hit.get_end(), "selected %s %d" % [op, id]]
	if not equal and not (lower and upper and condition.contains("&&")):
		return ids
	var normalized := condition
	var starts := replacements.keys()
	starts.sort()
	starts.reverse()
	for start: int in starts:
		var replacement: Array = replacements[start]
		normalized = normalized.substr(0, start) + replacement[1] + normalized.substr(replacement[0])
	var safe_syntax := RegEx.create_from_string("^(?:\\s|selected\\b|[()0-9=<>|&-])+$")
	if not safe_syntax.search(normalized):
		return ids
	var expression := Expression.new()
	if expression.parse(normalized, PackedStringArray(["selected"])) != OK:
		return ids
	var lo: int = boundaries.min()
	var hi: int = boundaries.max()
	if expression.execute([lo - 1], null, false, true) == true or expression.execute([hi + 1], null, false, true) == true:
		return ids
	for id in range(lo, hi + 1):
		if expression.execute([id], null, false, true) == true:
			ids.append(id)
	return ids


func _check_fixtures() -> void:
	var named := {
		"fx_shaders.gd": {"source": "const VENT_JET := 40", "constants": {"VENT_JET": FX.SpriteKind.VENT_JET}},
		"fx_fixture.gd": {"source": "const SPR_NOVA_LEGACY := 40", "constants": {"SPR_NOVA_LEGACY": FX.SpriteKind.VENT_JET}},
	}
	var errors := _named_kind_problems(named)
	var named_collision := false
	for error in errors:
		named_collision = named_collision or (error.contains("claimed by both") and error.contains("VENT_JET")
			and error.contains("SPR_NOVA_LEGACY"))
	if not named_collision:
		problems.append("Fixture allowed legacy VENT_JET and SPR_NOVA_LEGACY to claim one ID")
	named.erase("fx_fixture.gd")
	named["fx_fixture.gd"] = {
		"source": "const NEW_GLOB := 40\nfunc emit(fx):\n\tfx.spr(p, t, life, col, i, s0, s1, NEW_GLOB if wet else 15)",
		"constants": {"NEW_GLOB": FX.SpriteKind.VENT_JET},
	}
	errors = _named_kind_problems(named)
	if not errors.any(func(error: String) -> bool: return error.contains("claimed by both") and error.contains("NEW_GLOB")):
		problems.append("Fixture missed an unprefixed constant in the emitter's kind slot")
	named["fx_fixture.gd"] = {
		"source": "const JET := FX.SpriteKind.VENT_JET\nfunc emit(fx):\n\tfx.spr(p, t, life, col, i, s0, s1, JET)",
		"constants": {"JET": FX.SpriteKind.VENT_JET},
	}
	if not _named_kind_problems(named).is_empty():
		problems.append("Fixture rejected a direct alias of the registered kind")

	var k := "\\b(?:k|kind|profile)\\b"
	var kind := FX.SpriteKind.BOLT_PLASMA
	var bomb := FX.SpriteKind.BOLT_BOMB
	var legal := "void vertex() { if (k == %d) { shape(); } }\nvoid fragment() { if (%d == k) { plasma(); } }" % [kind, kind]
	if not _shader_problems("fixture", legal, k, "SPRITE").is_empty():
		problems.append("Fixture rejected legal vertex and fragment reuse")
	var arms := [
		"if (k == %d) { plasma(); } else if (%d == k) { rupture(); }" % [kind, kind],
		"if (k >= %d && k <= %d) { bolt(); } if (k == %d) { rupture(); }" % [kind, bomb, kind],
	]
	for pair: String in arms:
		errors = _shader_problems("fixture", "void fragment() { " + pair + " }", k, "SPRITE")
		if errors.size() != 1 or not errors[0].contains("competing dispatch arms"):
			problems.append("Fixture did not reject competing shader arms: " + pair)
	errors = _shader_problems("fixture", "void vertex() { " + arms[0] + " }", k, "SPRITE")
	if errors.size() != 1 or not errors[0].contains("competing dispatch arms"):
		problems.append("Fixture did not reject competing arms within a vertex dispatch")

	# The #2148 overlap check also covered a wrong symbolic owner and a gap inside a range.
	var wrong_owner := "const int SPR_NOVA_LEGACY = %d; void fragment() { if (k == SPR_NOVA_LEGACY) {} }" % FX.SpriteKind.VENT_JET
	errors = _shader_problems("fixture", wrong_owner, k, "SPRITE")
	if errors.size() != 1 or not errors[0].contains("not its registered kind"):
		problems.append("Fixture allowed a shader symbol to take another kind's ID")
	var gap := "void bolt_mask(int profile) { if (profile >= 0 && profile <= 2) {} }"
	errors = _shader_problems("fixture", gap, k, "SPRITE", {"LOW": 0, "HIGH": 2})
	if errors.size() != 1 or not errors[0].contains("selects unregistered ID 1"):
		problems.append("Fixture missed an unregistered ID inside a dispatch range")
