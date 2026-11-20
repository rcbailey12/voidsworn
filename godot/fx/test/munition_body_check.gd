extends SceneTree
# Issue 1379 run 2 (R362, docs/playbooks/ships.md section 9): torpedoes and rockets are built from the faction part kits and
# take the hull finish. Checks, headless: each body file in fx/munitions/ loads, keeps the code casing's frame (+X the nose,
# about 2.3 long, round about X), every surface carries the faction's hull look (LOOK.hull's "look_hull" mark), a projectile
# of that faction and look uses the kit body (no code casing mesh in it), and a faction with no file keeps the code casing.
# Rebuild the files: tools/blender/build_sheets/munitions/munitions.py.

const W := preload("res://fx/fx_weapons.gd")
const BODIES := [["voidsworn", "torp"], ["corsair", "rockets"]]

var fails := 0


func _ok(cond: bool, what: String) -> void:
	print(("ok    " if cond else "FAIL  ") + what)
	if not cond:
		fails += 1


func _meshes(n: Node) -> Array:
	return n.find_children("*", "MeshInstance3D", true, false)


func _init() -> void:
	for f in BODIES:
		var path := W.MUNITIONS_DIR + "%s_%s.glb" % f
		_ok(FileAccess.file_exists(path), "%s exists" % path)
		var body: Node3D = W._load_munition(path, f[0])
		_ok(body != null, "%s %s body loads" % f)
		if body == null:
			continue
		var box := AABB()
		var surfaces := 0
		var finished := 0
		for m in _meshes(body):
			var b: AABB = m.transform * m.mesh.get_aabb()
			box = b if box.size == Vector3.ZERO else box.merge(b)
			for i in m.mesh.get_surface_count():
				surfaces += 1
				var mt: Material = m.get_surface_override_material(i)
				if mt != null and str(mt.get_meta("look_hull", "")) == f[0]:
					finished += 1
		_ok(box.size.x > 2.1 and box.size.x < 2.5, "%s %s is the casing's length (%.2f)" % [f[0], f[1], box.size.x])
		_ok(box.end.x > 1.0 and box.position.x < -1.0, "%s %s nose at +X, drive at -X" % f)
		_ok(box.size.y < 1.0 and box.size.z < 1.0, "%s %s stays slim (%.2f x %.2f)" % [f[0], f[1], box.size.y, box.size.z])
		_ok(surfaces > 0 and finished == surfaces, "%s %s: %d of %d surfaces take the hull finish" % [f[0], f[1], finished, surfaces])
		body.free()
	# a projectile uses the kit body for its faction, the code casing for a faction without one
	var fx := Node3D.new()
	fx.set_script(load("res://fx/fx.gd"))
	get_root().add_child(fx)
	await process_frame
	var kit: Node3D = W._projectile_body(fx, "torp", 1.0, Color(1, 0.5, 0.2), "voidsworn")
	_ok(kit.find_child("kit_body", true, false) != null, "a Sunward torpedo flies the kit body")
	var casing := 0
	for m in _meshes(kit):
		if m.mesh == fx.dstate.get("weapon_torp_casing"):
			casing += 1
	_ok(casing == 0, "and no code casing beside it")
	var old: Node3D = W._projectile_body(fx, "torp", 1.0, Color(1, 0.5, 0.2), "hegemony")
	_ok(old.find_child("kit_body", true, false) == null and fx.dstate.has("weapon_torp_casing"), "a faction with no body keeps the code casing")
	var star: Node3D = W._projectile_body(fx, "star", 1.0, Color(1, 0.5, 0.2), "ithar")
	_ok(star.find_child("kit_body", true, false) == null, "the Glasswright star torpedo stays an effect")
	print("MUNITION_BODY_CHECK %s, %d failures" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(1 if fails else 0)
