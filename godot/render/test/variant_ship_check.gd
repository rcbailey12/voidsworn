extends SceneTree
# Issue 812. The normal CI run uses tiny cache fixtures. VARIANT_EXPORTS points to
# variant_selftest.py's output for the real GLB -> cache -> ShipView proof.
const GUARD := preload("res://tools/ci/check_guard.gd")
const SV := preload("res://render/ship_view.gd")
const HT := preload("res://render/hull_table.gd")
var fails := 0
var checks := 0
var output := ""
var real_assets := false


func _init() -> void:
	GUARD.arm(self, "variant_ship_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		fails += 1
		print("VARIANT FAIL: " + what)


func fixture(code: String) -> Dictionary:
	var n := Node3D.new()
	var mesh := MeshInstance3D.new()
	var array := ArrayMesh.new()
	array.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, BoxMesh.new().get_mesh_arrays())
	mesh.mesh = array
	n.add_child(mesh)
	mesh.owner = n
	var ps := PackedScene.new()
	ps.pack(n)
	var path := output.path_join(code + ".scn")
	check(ResourceSaver.save(ps, path) == OK, "saved fixture " + code)
	n.free()
	return {"res": path, "mirror": false}


func spawn(tpl: String, cls: String, override := "") -> Node3D:
	var sv := SV.new()
	root.add_child(sv)
	var unit := {"id": "variant-readback", "tpl": tpl, "fac": "deathless", "cls": cls, "facing": 0}
	if override != "":
		unit["code"] = override
	sv.setup(unit, Vector3.ZERO)
	return sv


func _run() -> void:
	var exports := OS.get_environment("VARIANT_EXPORTS")
	real_assets = exports != ""
	var scratch := OS.get_environment("TEMP")
	if scratch == "":
		scratch = "user://"
	output = exports.path_join("godot") if real_assets else scratch.path_join("variant_ship_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var gen := output.path_join("gen")
	var man := {"ships": {}}
	var proof: Dictionary = {}
	if real_assets:
		proof = JSON.parse_string(FileAccess.get_file_as_string(exports.path_join("variant_selftest.json")))
		var log: Array = []
		var status := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
			"--script", "res://render/build_assets.gd", "--", "--ships-only", "--ships", exports.path_join("ships"), "--gen", gen], log, true)
		check(status == 0, "real GLB cache builder: " + str(log).right(600))
		var data = JSON.parse_string(FileAccess.get_file_as_string(gen.path_join("manifest.json")))
		if not data is Dictionary:
			check(false, "asset builder wrote a manifest")
			_done()
			return
		man = data
	else:
		for code in ["D20_23", "D9_23", "D21_23", "d_jackal_h", "d_scythe_s", "d_harvester_t"]:
			man["ships"][code] = fixture(code)
	SV.clear_static()
	SV._manifest = man
	for row in [["d_jackal_h", "Destroyer", "D20_23"], ["d_scythe_s", "Frigate", "D9_23"], ["d_harvester_t", "Cruiser", "D21_23"]]:
		var sv = spawn(row[0], row[1])
		check(sv.code == row[0] and sv.a4, "%s loads its own installed hull from tpl" % row[0])
		check(is_equal_approx(sv.L, float(HT.CLS_LEN[row[1]]) * HT.SHIP_K), "%s keeps its inherited class length" % row[0])
		check(is_equal_approx(sv.hull_lift, float(HT.HULL_LIFT.get(row[2], 0.0))), "%s keeps its base board clearance" % row[0])
		if real_assets:
			var muzzles := 0
			for node in sv.find_children("hp_w*", "", true, false):
				muzzles += 1
			var expected := int(proof["variants"][row[0]]["export"]["hardpoints"]["gun"])
			check(muzzles == expected, "%s draws all %d exported muzzles (got %d)" % [row[0], expected, muzzles])
		sv.free()
		var entry = man["ships"][row[0]]
		man["ships"].erase(row[0])
		sv = spawn(row[0], row[1])
		check(sv.code == row[2], "%s falls back safely when its variant is not installed" % row[0])
		sv.free()
		man["ships"][row[0]] = entry
		sv = spawn(row[0], row[1], row[2])
		check(sv.code == row[2], "explicit code override still wins")
		sv.free()
	if not real_assets:
		# R229 / issue 726: A17's approved claw-tip length survives the real ShipView fit.
		man["ships"]["C15s_23"] = fixture("C15s_23")
		var unit := {"id": "A17-scale", "fac": "corsair", "cls": "Cruiser", "facing": 0}
		var sv := SV.new()
		root.add_child(sv)
		sv.setup(unit, Vector3.ZERO)
		check(sv.code == "C15s_23" and is_equal_approx(sv.L, 23.36), "A17 uses its approved 14.6 length times SHIP_K")
		var mesh := sv.meshes[0] as MeshInstance3D
		var box := mesh.global_transform * mesh.get_aabb()
		check(is_equal_approx(box.size.x, 23.36), "A17's fitted mesh spans 23.36 board units")
		sv.free()
		sv = spawn("missing-cruiser", "Cruiser")
		check(is_equal_approx(sv.L, 23.2), "other cruisers keep their 14.5 class length")
		sv.free()
		unit["code"] = "C15s_23"
		unit["L"] = 12.0
		sv = SV.new()
		root.add_child(sv)
		sv.setup(unit, Vector3.ZERO)
		check(is_equal_approx(sv.L, 12.0), "explicit capture length still overrides the hull length")
		sv.free()
	_done()


func _done() -> void:
	SV.clear_static()
	var result := {"ok": fails == 0, "checks": checks, "failures": fails, "real_glb_assets": real_assets}
	var file := FileAccess.open(output.path_join("variant_ship_check.json"), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result, "  "))
	print("VARIANT SHIP %s: %d checks, %d failures, real GLBs=%s" % ["PASS" if fails == 0 else "FAIL", checks, fails, real_assets])
	quit(0 if fails == 0 else 1)
