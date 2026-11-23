extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1410 (R368): render/hull_age.gd tells a NEW ship layout from an old Nov 1 one by reading the tracked manifest
# (assets/ships/manifest.json), and its guard refuses old hulls in reference runs unless ALLOW_OLD_HULLS=1.
#   godot --headless --path godot --script res://render/test/hull_age_check.gd
# Prints HULL_AGE_CHECK PASS or FAIL; exit 0 only on PASS.

const HullAge := preload("res://render/hull_age.gd")
const SV := preload("res://render/ship_view.gd")

var fails := 0


func _init() -> void:
	GUARD.arm(self, "hull_age_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _run() -> void:
	check(HullAge.layout("V14_23") == "NEW", "V14_23 is NEW")
	check(HullAge.layout("H7_23") == "OLD", "H7_23 is OLD")
	check(HullAge.layout("ZZ1410_NOPE") == "UNLISTED", "an unknown code is UNLISTED")
	check(HullAge.label("V14_23") == "V14_23 NEW", "label of a new hull")
	check(HullAge.label("H7_23") == "H7_23 OLD hull", "label of an old hull")
	check(HullAge.label("ZZ1410_NOPE") == "ZZ1410_NOPE UNLISTED", "label of an unknown code")
	var kept := OS.get_environment("ALLOW_OLD_HULLS")   # the check sets it itself, then puts it back
	OS.unset_environment("ALLOW_OLD_HULLS")
	check(HullAge.guard(["V14_23", "O1_37"]) == "", "guard passes a new hull and the teaching station O1_37")
	var msg := HullAge.guard(["H7_23"])
	check(msg.contains("H7_23"), "guard names H7_23: " + msg)
	check(HullAge.guard(["V14_23", "H7_23", "ZZ1410_NOPE"]).contains("ZZ1410_NOPE"), "guard names an unlisted code too")
	OS.set_environment("ALLOW_OLD_HULLS", "1")
	check(HullAge.guard(["H7_23"]) == "", "ALLOW_OLD_HULLS=1 lets H7_23 through")
	OS.unset_environment("ALLOW_OLD_HULLS")
	check(HullAge.guard(["H7_23"]) != "", "the guard is back on once ALLOW_OLD_HULLS is unset")
	if kept != "":
		OS.set_environment("ALLOW_OLD_HULLS", kept)

	# a ShipView for a code the cache does not know draws the placeholder block (headless has no gen folder)
	var sv := SV.new()
	root.add_child(sv)
	sv.setup({"id": "hull_age_zz", "fac": "hegemony", "cls": "Frigate", "code": "ZZ1410_NOPE", "facing": 0}, Vector3.ZERO)
	var r: Dictionary = HullAge.resolved(sv)
	check(r.get("code") == "ZZ1410_NOPE" and r.get("source") == "placeholder" and r.get("res") == "",
		"resolved() on an unknown code reports placeholder: %s" % str(r))
	check(str(sv.hull_source) == "" and str(sv.hull_res) == "", "the placeholder ShipView recorded no source or resource")
	sv.queue_free()
	await process_frame
	await _known_code_fixture()
	SV.clear_static()
	print("HULL_AGE_CHECK " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)


# Astra audit of PR 1814 (issue 1832): a code the manifest lists under several sections, where the preferred entry loads
# but is the wrong kind (a script where ShipView needs a scene, a scene where it needs a mesh). ShipView draws the next
# tier that does load, and resolved() must report that one, with its resource, not the rejected first entry.
func _known_code_fixture() -> void:
	var dir := "user://hull_age_check_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)
	var mesh_res := dir + "/box.tres"
	check(ResourceSaver.save(BoxMesh.new(), mesh_res) == OK, "the fixture mesh was written")
	var scene := "res://render/test/fixtures/beacon/beacon_stub.tscn"
	var not_a_scene := "res://render/hull_age.gd"   # loads fine, is not a PackedScene and not a Mesh
	var cases := [
		["ZZ1410_SHIPS", {"ships": {"ZZ1410_SHIPS": {"res": scene}}, "hi": {"ZZ1410_SHIPS": {"res": not_a_scene}}}, "ships", scene],
		["ZZ1410_HI", {"ships": {"ZZ1410_HI": {"res": not_a_scene}}, "hi": {"ZZ1410_HI": {"res": scene}}, "hulls": {"ZZ1410_HI": {"res": mesh_res}}}, "hi", scene],
		["ZZ1410_HULLS", {"ships": {"ZZ1410_HULLS": {"res": mesh_res}}, "hi": {"ZZ1410_HULLS": {"res": not_a_scene}}, "hulls": {"ZZ1410_HULLS": {"res": mesh_res}}}, "hulls", mesh_res],
		["ZZ1410_NONE", {"ships": {"ZZ1410_NONE": {"res": mesh_res}}, "hi": {"ZZ1410_NONE": {"res": not_a_scene}}, "hulls": {"ZZ1410_NONE": {"res": scene}}}, "placeholder", ""],
	]
	var kept_path: String = SV.manifest_path
	for c in cases:
		var path := dir + "/manifest_%s.json" % c[0]
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(c[1]))
		f.close()
		SV.manifest_path = path
		SV.clear_static()
		var sv := SV.new()
		root.add_child(sv)
		sv.setup({"id": "hull_age_" + c[0], "fac": "hegemony", "cls": "Frigate", "code": c[0], "facing": 0}, Vector3.ZERO)
		var r: Dictionary = HullAge.resolved(sv)
		check(r.get("code") == c[0] and r.get("source") == c[2] and r.get("res") == c[3],
			"%s drew from %s and resolved() says so: %s" % [c[0], c[2], str(r)])
		sv.queue_free()
		await process_frame
	SV.manifest_path = kept_path
	SV.clear_static()
