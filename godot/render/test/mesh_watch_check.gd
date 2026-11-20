extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1204: one shared new-mesh watcher (render/mesh_watch.gd) serves the hull rim lights (render/look_rim.gd, the
# LookRim and LookRimSoft pair) and the nebula fog guard (world/nebula_hulls.gd).
#   1. With both rim lights and the nebula guard in the scene, the tree has one node_added connection for them, not three.
#   2. Twenty new meshes in one frame cost one end-of-frame pass, not one deferred call per mesh per listener.
#   3. A hull whose material is set in the frame it entered gets its rim layer and fog guard (the usual path).
#   4. A hull whose hull material is set two frames after it entered gets them too, through MeshWatch.touch, the way
#      ShipView sets its hull materials.
#   5. A plain mesh (no hull material) is left alone.
#   godot --headless --path godot --script res://render/test/mesh_watch_check.gd
# Prints MESH WATCH PASS or FAIL lines; exit 0 only on PASS.

const LOOK := preload("res://render/look.gd")
const WATCH := preload("res://render/mesh_watch.gd")
const NEBULA := preload("res://world/nebula_hulls.gd")

var fails: Array = []


func _init() -> void:
	GUARD.arm(self, "mesh_watch_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, what: String) -> void:
	if not ok:
		fails.append(what)
		print("MESH WATCH FAIL: " + what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _mesh(mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	mi.mesh = bm
	if mat != null:
		mi.set_surface_override_material(0, mat)
	return mi


func _rim(g: GeometryInstance3D) -> bool:
	return (g.layers & (LOOK.RIM_LAYER | LOOK.RIM_SOFT_LAYER)) != 0


func _fogless(g: MeshInstance3D) -> bool:
	var m := g.get_active_material(0) as BaseMaterial3D
	return m != null and m.disable_fog


func _run() -> void:
	var base_conns := node_added.get_connections().size()
	var scene := Node3D.new()
	root.add_child(scene)
	var key := DirectionalLight3D.new()
	scene.add_child(key)
	check(LOOK.rim_light(key) != null, "LOOK.rim_light made no rim light")
	var neb := Node.new()
	neb.set_script(NEBULA)
	scene.add_child(neb)
	await _frames(2)
	check(scene.get_node_or_null("LookRim") != null and scene.get_node_or_null("LookRimSoft") != null, "the rim light pair is missing")
	var added := node_added.get_connections().size() - base_conns
	check(added == 1, "rim lights and nebula guard added %d node_added connections, want 1" % added)

	# 2 and 3: twenty hulls in one frame, materials set right after they enter
	var w = WATCH.of(self)
	var before: int = w.flushes
	var hulls: Array = []
	for i in 20:
		var mi := _mesh(null)
		scene.add_child(mi)
		mi.set_surface_override_material(0, LOOK.hull(StandardMaterial3D.new(), "voidsworn", true))
		hulls.append(mi)
	var plain := _mesh(StandardMaterial3D.new())
	scene.add_child(plain)
	await _frames(2)
	check(w.flushes - before == 1, "21 new meshes in one frame took %d end-of-frame passes, want 1" % (w.flushes - before))
	var rimmed := 0
	var guarded := 0
	for mi in hulls:
		rimmed += 1 if _rim(mi) else 0
		guarded += 1 if _fogless(mi) else 0
	check(rimmed == 20, "%d of 20 same-frame hulls got the rim layer" % rimmed)
	check(guarded == 20, "%d of 20 same-frame hulls got the nebula fog guard" % guarded)
	check(not _rim(plain) and not _fogless(plain), "a plain mesh was treated as a hull")

	# 4: the hull material arrives two frames after the mesh entered
	var late := _mesh(StandardMaterial3D.new())
	scene.add_child(late)
	await _frames(3)
	check(not _rim(late), "a plain mesh got the rim layer before its hull material was set")
	late.set_surface_override_material(0, LOOK.hull(StandardMaterial3D.new(), "deathless", true))
	WATCH.touch(late)
	WATCH.touch(late)   # twice in a frame queues it once
	before = w.flushes
	await _frames(2)
	check(w.flushes - before == 1, "two touches in one frame took %d passes, want 1" % (w.flushes - before))
	check(_rim(late), "a hull whose material was set two frames late did not get its rim")
	check(_fogless(late), "a hull whose material was set two frames late did not get the nebula fog guard")

	# 5 (issue 1315): a faction with READ rim_light 0 (the Glasswrights) stays off both rim lights but keeps the fog guard
	var pale := _mesh(null)
	scene.add_child(pale)
	pale.set_surface_override_material(0, LOOK.hull(StandardMaterial3D.new(), "ithar", true))
	await _frames(2)
	check(not _rim(pale), "a Glasswright hull joined a rim light layer (READ ithar rim_light is 0)")
	check(_fogless(pale), "a Glasswright hull lost the nebula fog guard")

	scene.queue_free()
	await _frames(2)
	if fails.is_empty():
		print("MESH WATCH PASS: one watcher for rim and nebula, one pass per frame, late hull materials get their rim")
	quit(0 if fails.is_empty() else 1)
