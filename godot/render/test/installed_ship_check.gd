extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 592: the install readback. After stage 7 installs a ship into a Godot project and the asset builder refreshes the
# ship cache (render/build_assets.gd --ships-only), this proves the game will draw the new hull:
#   1. gen/manifest.json has the ship, its cached scene exists, and its source stamp is the installed files' stamp now
#      (build_assets.source_stamp, the builder's own function), so the cache was rebuilt from what was just installed;
#   2. the cache names no damage or wreck scene the ship folder no longer has (the install moves an old hull's away);
#   3. ShipView loads the cached ship or the corresponding faction wing. Every hard point and turret node in the
#      installed GLB is in the scene it draws.
#   godot --headless --path <project> --script res://render/test/installed_ship_check.gd -- CODE [--gen DIR] [--ships DIR]
# Prints INSTALL READBACK PASS or FAIL lines; exit 0 only on PASS.

const BA := preload("res://render/build_assets.gd")
const SV := preload("res://render/ship_view.gd")
const WING := preload("res://render/squadron_wing.gd")

var fails: Array = []


func _init() -> void:
	GUARD.arm(self, "installed_ship_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
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
	var stamp := BA.source_stamp(ships, code)
	check(str(e.get("src", "")) == stamp, "the cache was built from other files than the installed ones (stamp %s, now %s)" % [str(e.get("src", "")), stamp])
	for x in ["damage", "wreck"]:
		var has_src := FileAccess.file_exists(ships.path_join(code).path_join("%s_%s.glb" % [code, x]))
		check(has_src or not e.has(x), "the cache still names an old %s scene (%s) the ship folder no longer has" % [x, str(e.get(x, ""))])
	# what the installed glb carries
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	st.handle_binary_image_mode = GLTFState.HANDLE_BINARY_IMAGE_MODE_EMBED_AS_UNCOMPRESSED
	var want := []
	if BA.append_ship_glb(doc, ships.path_join(code).path_join(code + ".glb"), st) == OK:
		var src: Node = doc.generate_scene(st)
		for n in src.find_children("*", "", true, false):
			if str(n.name).begins_with("hp_") or str(n.name).begins_with("turret_"):
				want.append(str(n.name))
		src.free()
	check(not want.is_empty(), "the installed glb has no hard point nodes to compare")
	# what ShipView draws
	SV.manifest_path = man_p
	SV.clear_static()
	var source_manifest_path := ships.path_join("manifest.json")
	var source_manifest = JSON.parse_string(FileAccess.get_file_as_string(source_manifest_path)) if FileAccess.file_exists(source_manifest_path) else null
	var source_row: Dictionary = source_manifest.get("ships", {}).get(code, {}) if source_manifest is Dictionary else {}
	var role := str(source_row.get("wing_role", ""))
	var sv = SV.new()
	root.add_child(sv)
	if role.is_empty():
		sv.setup({"id": "readback", "fac": "corsair", "cls": "Battle-barge", "facing": 0, "code": code}, Vector3.ZERO)
		check(bool(sv.a4), "ShipView did not load %s from the ship cache (it drew another hull)" % code)
	else:
		WING.ship_manifest_path = source_manifest_path
		WING.ship_cache_dir = str(e["res"]).get_base_dir()
		sv.setup({"id": "readback", "fac": source_row["faction"], "cls": "Squadron", "facing": 0, "tpl": role, "squadron": true}, Vector3.ZERO)
		for craft: Node3D in sv.hull.craft:
			check(craft.has_node(NodePath(code)), "wing craft drew another model in place of %s" % code)
	var have := {}
	for n in sv.find_children("*", "", true, false):
		have[str(n.name)] = true
	var missing := want.filter(func(x): return not have.has(x))
	check(missing.is_empty(), "ShipView's %s lacks %d installed nodes: %s" % [code, missing.size(), str(missing.slice(0, 6))])
	# Issue 1282 (Fable on PR 1184): a turret the sheet lets train (an arc wider than nothing) must be able to leave rest in
	# the game. The clearance test (fx/fx_hull.gd _turret_clearance) locks a turret whose barrels touch the ship at rest; that
	# was only a log line, so CD5's three optics shipped locked. Here it fails the readback.
	if role.is_empty() and sv.has_method("_attach_hull"):
		var at = sv._attach_hull()
		if at != null:
			for t: Dictionary in at.turrets:
				var arc := float(t["hi"]) - float(t["lo"])
				var moves := bool(t["full"]) or float(t["ymax"]) - float(t["ymin"]) > 0.0
				check(arc <= 0.0 or moves, "turret %s (%s) is locked at rest: its barrels touch the ship, but its arc is %.0f to %.0f" % [t["name"], t["id"], float(t["lo"]), float(t["hi"])])
	sv.queue_free()
	_done(code, want.size())


func _done(code: String, nodes: int) -> void:
	SV.clear_static()
	print(("INSTALL READBACK PASS code=%s nodes=%d" % [code, nodes]) if fails.is_empty() else ("INSTALL READBACK FAIL code=%s: %d problems" % [code, fails.size()]))
	quit(0 if fails.is_empty() else 1)
