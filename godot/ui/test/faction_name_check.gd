# Issue 2029 item 1: no player-facing text says Hegemony. The faction id `hegemony` never changes, but its display name is
# "Meridian Directorate" (contrib/opus/compute/rename_map_final.md). Headless:
#   godot --headless --path godot --script res://ui/test/faction_name_check.gd
# Scans the game's shipped text: every one-line string literal in the GDScript outside test, bench and gallery folders
# (comments, ids such as "hegemony" and shader code are not text), every string VALUE (never a key) in the rules, campaign
# and story data tables, and the text properties in scenes. A hit is a literal with the word Hegemony, or a lower-case
# "hegemony" inside a sentence (it has a space and is not a path). Also holds the table's display name and the map's title.
extends SceneTree
const SKIP_DIRS := ["test", "bench", "gallery", "gen", ".godot", "addons"]
const JSON_ROOTS := ["res://rules/data", "res://campaign/data", "res://story/data"]
var fails := 0
var scanned := 0


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


static func says_hegemony(text: String) -> bool:
	if text.contains("Hegemony"):
		return true
	return text.to_lower().contains("hegemony") and text.contains(" ") and not text.contains("/") and not text.contains("res:")


# One-line string literals of a GDScript file: skips # comments and triple-quoted blocks (shader code, long notes).
static func literals(src: String) -> Array:
	var out: Array = []
	var i := 0
	var n := src.length()
	while i < n:
		var c := src[i]
		if c == "#":
			while i < n and src[i] != "\n":
				i += 1
		elif c == "\"" or c == "'":
			if src.substr(i, 3) == c.repeat(3):
				var j := src.find(c.repeat(3), i + 3)
				i = n if j < 0 else j + 3
				continue
			var j := i + 1
			while j < n and src[j] != c and src[j] != "\n":
				if src[j] == "\\":
					j += 1
				j += 1
			out.append(src.substr(i + 1, j - i - 1))
			i = j + 1
		else:
			i += 1
	return out


func _files(dir: String, exts: Array, out: Array) -> void:
	for d in DirAccess.get_directories_at(dir):
		if d in SKIP_DIRS:
			continue
		_files(dir.path_join(d), exts, out)
	for f in DirAccess.get_files_at(dir):
		if f.get_extension() in exts:
			out.append(dir.path_join(f))


func _strings(v, out: Array) -> void:   # values only, never keys
	if v is String:
		out.append(v)
	elif v is Array:
		for x in v:
			_strings(x, out)
	elif v is Dictionary:
		for k in v:
			_strings(v[k], out)


func _run() -> void:
	# the scanner itself
	_check(says_hegemony("Hegemony Navy") and says_hegemony("the hegemony fleet") and not says_hegemony("hegemony") and not says_hegemony("res://fx/hegemony_a.tres"), "the rule: names and sentences hit, ids and paths do not")
	var lit := literals("var a = \"keep\" # \"Hegemony in a comment\"\nvar b = 'Hegemony Navy'\nvar c = \"\"\"\nHegemony in a block\n\"\"\"\n")
	_check(lit == ["keep", "Hegemony Navy"], "the literal reader skips comments and blocks (%s)" % str(lit))
	# the table's display name, as the rename map says
	var tb = JSON.parse_string(FileAccess.get_file_as_string("res://campaign/data/campaign_tables.json"))
	var fac = tb["tables"]["FACTIONS"]["hegemony"]
	_check(str(fac["n"]) == "Meridian Directorate", "FACTIONS.hegemony.n is Meridian Directorate (%s)" % str(fac["n"]))
	var rt = JSON.parse_string(FileAccess.get_file_as_string("res://rules/data/tables.json"))
	_check(str(rt["tables"]["FACTIONS"]["hegemony"]["n"]) == "Meridian Directorate", "the rules table says the same")
	# GDScript text
	var gd: Array = []
	_files("res://", ["gd"], gd)
	var bad: Array = []
	for path in gd:
		scanned += 1
		for l in literals(FileAccess.get_file_as_string(path)):
			if says_hegemony(l):
				bad.append(path + ": " + l.left(80))
	_check(gd.size() > 100 and bad.is_empty(), "no GDScript text says Hegemony (%d files, %d hits %s)" % [gd.size(), bad.size(), str(bad.slice(0, 5))])
	# data tables
	var js: Array = []
	for r in JSON_ROOTS:
		_files(r, ["json"], js)
	var jbad: Array = []
	for path in js:
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		var vals: Array = []
		_strings(data, vals)
		for s in vals:
			if says_hegemony(s):
				jbad.append(path + ": " + s.left(80))
	_check(js.size() > 3 and jbad.is_empty(), "no data table text says Hegemony (%d files, %d hits %s)" % [js.size(), jbad.size(), str(jbad.slice(0, 5))])
	# scenes
	var sc: Array = []
	_files("res://", ["tscn", "tres"], sc)
	var sbad: Array = []
	for path in sc:
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if line.begins_with("text =") or line.begins_with("title =") or line.begins_with("tooltip_text ="):
				if says_hegemony(line):
					sbad.append(path + ": " + line.left(80))
	_check(sbad.is_empty(), "no scene text says Hegemony (%d files, %d hits)" % [sc.size(), sbad.size()])
	print("faction_name_check: %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)
