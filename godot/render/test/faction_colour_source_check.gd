extends SceneTree
# Issue 1205 (R333): one source for faction colours. hull_table's FAC3D table set engine, weapon and shield colours that
# overrode fx/faction_looks.json (Eclipse all green instead of violet with a green weapon core). This check fails if any
# GDScript under godot/ reads or defines FAC3D again, and proves the colours the old readers now use (fx/faction_look.gd
# engine, weapon, shield) are the json's own, including Eclipse violet and a hit colour for the factions without shields.
const GUARD := preload("res://tools/ci/check_guard.gd")
const FLOOK := preload("res://fx/faction_look.gd")
const FACS := ["voidsworn", "hegemony", "corsair", "chorus", "ithar", "deathless"]
var fails := 0
var checks := 0


func _init() -> void:
	GUARD.arm(self, "faction_colour_source_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		fails += 1
		push_error("FACTION COLOUR FAIL: " + message)


func _scan(dir: String, out: Array) -> void:
	for d in DirAccess.get_directories_at(dir):
		if d.begins_with(".") or d == "gen":
			continue
		_scan(dir.path_join(d), out)
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))


func _run() -> void:
	var files: Array = []
	_scan("res://", files)
	check(files.size() > 50, "found only %d scripts under res://" % files.size())
	var word := "FAC" + "3D"   # split so this file does not match itself
	var re := RegEx.create_from_string("\\b" + word + "\\b")
	for p in files:
		var lines := FileAccess.get_file_as_string(p).split("\n")
		var hits: Array = []
		for i in lines.size():
			var code := lines[i]
			var hash_at := code.find("#")
			if hash_at >= 0:
				code = code.substr(0, hash_at)
			if re.search(code) != null:
				hits.append(i + 1)
		check(hits.is_empty(), "%s line(s) %s use %s; read faction colours from fx/faction_look.gd (faction_looks.json)" % [p, hits, word])
	FLOOK.reload()
	var raw = JSON.parse_string(FileAccess.get_file_as_string(FLOOK.PATH))
	check(raw is Dictionary, "cannot read " + FLOOK.PATH)
	if raw is Dictionary:
		for f in FACS:
			check(FLOOK.has(f), "faction_looks.json has no " + f)
			var src: Dictionary = raw.get(f, {})
			var eng = src.get("engine")
			var wpn = src.get("weapon")
			check(eng is Array and FLOOK.engine(f).is_equal_approx(Color(eng[0], eng[1], eng[2])), f + " engine is not the json's")
			check(wpn is Array and FLOOK.weapon(f).is_equal_approx(Color(wpn[0], wpn[1], wpn[2])), f + " weapon is not the json's")
			var sh = src.get("shield")
			var want: Array = sh if sh is Array else wpn
			check(FLOOK.shield(f).is_equal_approx(Color(want[0], want[1], want[2])), f + " shield (or its weapon stand-in) is not the json's")
	var e := FLOOK.engine("deathless")
	var w := FLOOK.weapon("deathless")
	check(e.b > e.g and e.r > e.g, "Eclipse engines are not violet: %s" % e)
	check(w.b > w.g and w.r > w.g, "Eclipse weapons are not violet: %s" % w)
	check(FLOOK.engine("hegemony").b > FLOOK.engine("hegemony").r, "Hegemony engines are not blue (Oct 26 ruling)")
	print("faction_colour_source_check: %d scripts, %d checks, %d fails" % [files.size(), checks, fails])
	quit(1 if fails > 0 else 0)
