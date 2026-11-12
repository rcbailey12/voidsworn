extends SceneTree
# Issue 592: the install readback. After stage 7 installs a ship into a Godot project and the asset builder refreshes the
# ship cache (render/build_assets.gd --ships-only), this proves the game will draw the new hull:
#   1. gen/manifest.json has the ship, its cached scene exists, and its source stamp is the installed files' stamp now
#      (build_assets.source_stamp, the builder's own function), so the cache was rebuilt from what was just installed;
#   2. the cache names no damage or wreck scene the ship folder no longer has (the install moves an old hull's away);
#   3. ShipView itself, reading that manifest, loads the ship as a kit ship, and every hard point and turret node the
#      installed glb carries is in the scene it draws.
#   godot --headless --path <project> --script res://render/test/installed_ship_check.gd -- CODE [--gen DIR] [--ships DIR]
# Prints INSTALL READBACK PASS or FAIL lines; exit 0 only on PASS.

const BA := preload("res://render/build_assets.gd")
const SV := preload("res://render/ship_view.gd")

var fails: Array = []


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, what: String) -> void:
	if not ok:
		fails.append(what)
		print("INSTALL READBACK FAIL: " + what)


func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var code := a[0] if a.size() > 0 else ""
	var gen := "res://gen"
	var ships := "res://assets/ships"
	for i in a.size():
		if a[i] == "--gen" and i + 1 < a.size(): gen = a[i + 1]
		if a[i] == "--ships" and i + 1 < a.size(): ships = a[i + 1]
	var man_p := gen.path_join("manifest.json")
	var man = JSON.parse_string(FileAccess.get_file_as_string(man_p)) if FileAccess.file_exists(man_p) else null
	check(man is Dictionary and man.has("ships") and (man["ships"] as Dictionary).has(code), "%s has no ship %s" % [man_p, code])
	if not fails.is_empty():
		_done(code, 0)
		return
	var e: Dictionary = man["ships"][code]
	check(FileAccess.file_exists(str(e.get("res", ""))), "the cached scene %s is missing" % str(e.get("res", "")))
	check(str(e.get("src", "")) == BA.source_stamp(ships, code), "the cache was built from other files than the installed ones (stamp %s, now %s)" % [str(e.get("src", "")), BA.source_stamp(ships, code)])
	for x in ["damage", "wreck"]:
		var has_src := FileAccess.file_exists(ships.path_join(code).path_join("%s_%s.glb" % [code, x]))
		check(has_src or not e.has(x), "the cache still names an old %s scene (%s) the ship folder no longer has" % [x, str(e.get(x, ""))])
	# what the installed glb carries
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	var want := []
	if doc.append_from_file(ProjectSettings.globalize_path(ships.path_join(code).path_join(code + ".glb")), st) == OK:
		var src: Node = doc.generate_scene(st)
		for n in src.find_children("*", "", true, false):
			if str(n.name).begins_with("hp_") or str(n.name).begins_with("turret_"):
				want.append(str(n.name))
		src.free()
	check(not want.is_empty(), "the installed glb has no hard point nodes to compare")
	# what ShipView draws
	SV.manifest_path = man_p
	SV.clear_static()
	var sv = SV.new()
	root.add_child(sv)
	sv.setup({"id": "readback", "fac": "corsair", "cls": "Battle-barge", "facing": 0, "code": code}, Vector3.ZERO)
	check(bool(sv.a4), "ShipView did not load %s from the ship cache (it drew another hull)" % code)
	var have := {}
	for n in sv.find_children("*", "", true, false):
		have[str(n.name)] = true
	var missing := want.filter(func(x): return not have.has(x))
	check(missing.is_empty(), "ShipView's %s lacks %d installed nodes: %s" % [code, missing.size(), str(missing.slice(0, 6))])
	sv.queue_free()
	_done(code, want.size())


func _done(code: String, nodes: int) -> void:
	SV.clear_static()
	print(("INSTALL READBACK PASS code=%s nodes=%d" % [code, nodes]) if fails.is_empty() else ("INSTALL READBACK FAIL code=%s: %d problems" % [code, fails.size()]))
	quit(0 if fails.is_empty() else 1)
