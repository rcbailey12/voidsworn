extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 592: proves the stage 7 install route refreshes the game's ship cache. With its own ship folder and cache in user://
# (never the project's gen/), it runs the real asset builder (render/build_assets.gd --ships-only) as a separate Godot
# process, exactly as tools/recipe/7_export.bat does after an install:
#   1. an old hull ZZ592 (the turret test ship's glb) with damage and wreck glbs: the cache names all three;
#   2. a new hull is installed the way stage 7 does it (the old damage and wreck glbs moved aside, the new glb copied in):
#      the cache is rebuilt from the new file and names no damage or wreck scene;
#   3. the install readback (render/test/installed_ship_check.gd) passes, and ShipView, reading that cache, draws the new
#      hull's own node and none of the old hull's turrets.
# Each run writes into its own user://install_refresh_check/<time>/ folder and removes nothing.
#   godot --headless --path godot --script res://render/test/install_refresh_check.gd
# Prints INSTALL REFRESH PASS or FAIL; exit 0 only on PASS.

const SV := preload("res://render/ship_view.gd")
const OLD := "res://render/test/fixtures/T560_fx/T560_fx.glb"
const CODE := "ZZ592"

var fails := 0
var run := ""


func _init() -> void:
	GUARD.arm(self, "install_refresh_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func copy(src: String, dst: String) -> void:
	var f := FileAccess.open(dst, FileAccess.WRITE)
	f.store_buffer(FileAccess.get_file_as_bytes(src))
	f.close()


func builder() -> String:
	var out := []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script",
		"res://render/build_assets.gd", "--", "--ships-only", "--ships", run.path_join("ships"), "--gen", run.path_join("gen")], out, true)
	check(code == 0, "the asset builder ran (--ships-only), exit %d" % code)
	return "\n".join(out)


func entry() -> Dictionary:
	var m = JSON.parse_string(FileAccess.get_file_as_string(run.path_join("gen/manifest.json")))
	return (m["ships"].get(CODE, {}) as Dictionary) if m is Dictionary and m.has("ships") else {}


func new_hull(path: String) -> void:
	# a plainly different hull: one box mesh, its own marker node, a core and an engine point
	var r := Node3D.new()
	r.name = CODE
	var mi := MeshInstance3D.new()
	mi.name = "zz592_new_hull"
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.2, 0.3)
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bm.get_mesh_arrays())
	mi.mesh = am
	r.add_child(mi)
	for n in ["hp_core", "hp_eng_0"]:
		var e := Node3D.new()
		e.name = n
		r.add_child(e)
	for c in r.get_children():
		c.owner = r
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	doc.append_from_scene(r, st)
	doc.write_to_filesystem(st, ProjectSettings.globalize_path(path))
	r.free()


func _run() -> void:
	run = "user://install_refresh_check/%d" % int(Time.get_unix_time_from_system())
	var sh := run.path_join("ships").path_join(CODE)
	for d in [sh, run.path_join("gen"), run.path_join("replaced")]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))
	# 1. the old hull, with its breach parts and wreck chunks
	for suf in ["", "_damage", "_wreck"]:
		copy(OLD, sh.path_join(CODE + suf + ".glb"))
	builder()
	var e := entry()
	check(e.has("res") and e.has("damage") and e.has("wreck"), "the old hull is cached with its damage and wreck scenes")
	# 2. the install: the old hull's damage and wreck moved aside, the new hull copied over the old glb
	OS.delay_msec(1100)   # file times count in seconds: the new glb must not share the old one's stamp by chance
	for suf in ["_damage", "_wreck"]:
		DirAccess.rename_absolute(ProjectSettings.globalize_path(sh.path_join(CODE + suf + ".glb")), ProjectSettings.globalize_path(run.path_join("replaced").path_join(CODE + suf + ".glb")))
	var tmp := run.path_join("new_" + CODE + ".glb")
	new_hull(tmp)
	copy(tmp, sh.path_join(CODE + ".glb"))
	var log := builder()
	var e2 := entry()
	check(e2.has("res") and str(e2.get("src", "")) != str(e.get("src", "")), "the cache was rebuilt from the new hull (its source stamp changed)")
	check(not e2.has("damage") and not e2.has("wreck"), "the cache dropped the old hull's damage and wreck scenes")
	# 3. the readback stage 7 runs, and ShipView itself
	var out := []
	var rc := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script",
		"res://render/test/installed_ship_check.gd", "--", CODE, "--ships", run.path_join("ships"), "--gen", run.path_join("gen")], out, true)
	check(rc == 0 and "INSTALL READBACK PASS" in "\n".join(out), "the install readback passes on the new hull")
	SV.manifest_path = run.path_join("gen/manifest.json")
	SV.clear_static()
	var sv = SV.new()
	root.add_child(sv)
	sv.setup({"id": "t592", "fac": "corsair", "cls": "Battle-barge", "facing": 0, "code": CODE}, Vector3.ZERO)
	check(bool(sv.a4) and sv.find_child("zz592_new_hull", true, false) != null, "ShipView draws the new hull from the cache")
	check(sv.find_child("turret_0", true, false) == null, "ShipView draws none of the old hull's turrets")
	sv.queue_free()
	SV.clear_static()
	print("INSTALL REFRESH %s (%s)" % ["PASS" if fails == 0 else "FAIL: %d" % fails, ProjectSettings.globalize_path(run)])
	quit(0 if fails == 0 else 1)
