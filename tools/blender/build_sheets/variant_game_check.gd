extends SceneTree
# Read the real stage 7 variants through the game's cache and ShipView. No GPU or project assets are changed.
# godot --headless --path godot --script ../tools/blender/build_sheets/variant_game_check.gd -- VERIFY_DIR
const SV := preload("res://render/ship_view.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
var fails := 0

func _init() -> void:
	GUARD.arm(self, "variant_game_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		fails += 1

func _run() -> void:
	var out := OS.get_cmdline_user_args()[0]
	SV.manifest_path = out.path_join("gen/manifest.json")
	SV.clear_static()
	for row in [["d_jackal", "Destroyer", "D20_23", 0],
		["d_jackal_h", "Destroyer", "D20_23__d_jackal_h", 1],
		["d_scythe_s", "Frigate", "D9_23__d_scythe_s", 2],
		["d_harvester_t", "Cruiser", "D21_23__d_harvester_t", 3]]:
		var sv := SV.new()
		root.add_child(sv)
		sv.setup({"id": row[0], "tpl": row[0], "cls": row[1], "fac": "deathless", "facing": 0}, Vector3.ZERO)
		check(sv.code == row[2] and sv.a4, "%s selects its own installed GLB through ShipView" % row[0])
		var turrets := sv.find_children("turret_*", "Node3D", true, false).filter(func(n): return n.get_meta("extras", {}).get("kind", "") == "turret")
		check(turrets.size() == row[3], "%s retains %d turning mounts" % [row[0], row[3]])
		if row[0] != "d_jackal":
			var muzzle := "hp_w1_doom_T_*" if row[0] == "d_harvester_t" else "hp_w1_gsentry_T_*"
			var points := sv.find_children(muzzle, "Node3D", true, false)
			check(not points.is_empty(), "%s has variant muzzles on its visible weapon" % row[0])
			for p in points:
				check(p.get_parent().name.begins_with("turret_"), "%s muzzle turns under its turret" % row[0])
			var attach = sv._attach_hull()
			check(attach.turrets.size() == row[3], "%s effects recognise its turning mounts" % row[0])
			var shots: Array = attach.guns(1, "doom" if row[0] == "d_harvester_t" else "gsentry", Vector3(30, 0, 30), 1)
			check(shots.size() == 1 and shots[0].get("src") == "hp" and shots[0].has("tur"),
				"%s fires from the authored turning muzzle" % row[0])
		sv.free()
	# An unbuilt variant keeps the installed class hull. Explicit bench codes retain precedence.
	for unit in [{"tpl": "unbuilt_variant"}, {"tpl": "d_jackal_h", "code": "D20_23"}]:
		unit.merge({"id": "fallback", "cls": "Destroyer", "fac": "deathless", "facing": 0})
		var sv := SV.new()
		root.add_child(sv)
		sv.setup(unit, Vector3.ZERO)
		check(sv.code == "D20_23" and sv.a4, "base fallback and explicit code remain usable")
		sv.free()
	SV.clear_static()
	print("PASS variant game readback" if fails == 0 else "FAIL variant game readback: %d" % fails)
	quit(0 if fails == 0 else 1)
