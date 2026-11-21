extends SceneTree
# Issue 1379 run 2 (R362, docs/playbooks/ships.md section 9): torpedoes and rockets are built from the faction part kits and
# take the hull finish. Checks, headless: each body file in fx/munition_bodies/ loads, keeps the code casing's frame (+X the nose,
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
		var body: Node3D = W._build_munition(W._load_munition(path, f[0]))
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
	for n in [kit, old, star]:
		n.free()
	# Issue 1531 (Artoo on PR 1532): through the push out the nozzle's baked glow is dark on this shot only; ignition lights it;
	# the cached (shared) materials never change and the marker lights keep their glow.
	for f in BODIES:
		var shot: Node3D = W._projectile_body(fx, f[1], 1.0, Color(1, 0.5, 0.2), f[0])
		var kb: Node = shot.find_child("kit_body", true, false)
		var rows: Array = kb.get_meta("nozzles", []) if kb != null else []
		_ok(rows.size() > 0, "%s %s: the nozzle glow surfaces are found (%d)" % [f[0], f[1], rows.size()])
		W._kit_nozzle_dark(shot, true)
		var dark_ok := true
		var shared_lit := true
		for r in rows:
			var cur := (r[0] as MeshInstance3D).get_surface_override_material(int(r[1])) as BaseMaterial3D
			dark_ok = dark_ok and cur != null and not cur.emission_enabled and cur != r[2]
			shared_lit = shared_lit and (r[2] as BaseMaterial3D).emission_enabled
		_ok(dark_ok, "%s %s: before ignition every nozzle surface is unlit" % f)
		_ok(shared_lit, "%s %s: the shared nozzle materials keep their glow" % f)
		var markers := 0
		var markers_lit := 0
		for m in _meshes(kb):
			for i in m.mesh.get_surface_count():
				var mt := m.get_surface_override_material(i) as BaseMaterial3D
				if mt != null and not rows.any(func(r): return r[0] == m and int(r[1]) == i) and mt.emission_enabled:
					markers_lit += 1
				if mt != null and not rows.any(func(r): return r[0] == m and int(r[1]) == i):
					markers += 1
		var cached_markers := 0
		for part in W._load_munition(W.MUNITIONS_DIR + "%s_%s.glb" % f, f[0]):
			for i in (part["mats"] as Array).size():
				var cm := part["mats"][i] as BaseMaterial3D
				if cm != null and cm.emission_enabled and part["dark"][i] == null:
					cached_markers += 1
		_ok(markers_lit == cached_markers, "%s %s: marker lights stay lit (%d of %d surfaces)" % [f[0], f[1], markers_lit, markers])
		W._kit_nozzle_dark(shot, false)
		var lit_ok := true
		for r in rows:
			lit_ok = lit_ok and (r[0] as MeshInstance3D).get_surface_override_material(int(r[1])) == r[2]
		_ok(lit_ok, "%s %s: ignition puts the lit nozzle back" % f)
		shot.free()
	# Artoo on PR 1416: the cache holds no node, so nothing outlives a battle. Two FX lifecycles each load and fire a body; after
	# each release no kit_body node is left anywhere and the node count is back where it started.
	var cached_nodes := 0
	for v in fx.dstate.values():
		if v is Node:
			cached_nodes += 1
		elif v is Array:
			for e in v:
				if e is Node or (e is Dictionary and (e as Dictionary).values().any(func(x): return x is Node)):
					cached_nodes += 1
	_ok(cached_nodes == 0, "the munition cache holds data only, no nodes")
	fx.release()
	fx.free()
	await process_frame
	var base := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	for life in 2:
		var f2 := Node3D.new()
		f2.set_script(load("res://fx/fx.gd"))
		get_root().add_child(f2)
		await process_frame
		var shot: Node3D = W._projectile_body(f2, "rockets", 1.0, Color(1, 0.5, 0.2), "corsair")
		_ok(shot.find_child("kit_body", true, false) != null, "lifecycle %d: a Hullbreaker rocket flies the kit body" % (life + 1))
		shot.free()
		f2.release()
		f2.free()
		await process_frame
		var now := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		_ok(now <= base, "lifecycle %d: no node left behind (%d nodes, %d before)" % [life + 1, now, base])
	print("MUNITION_BODY_CHECK %s, %d failures" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(1 if fails else 0)
