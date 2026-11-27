extends SceneTree

const FX := preload("res://fx/fx.gd")
const Death := preload("res://fx/fx_death.gd")
const Breach := preload("res://fx/fx_breach.gd")

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", label)


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high"})
	fx.compat = false
	fx.defer_initial_cuts = true
	var body := Node3D.new()
	world.add_child(body)
	var mi := MeshInstance3D.new()
	body.add_child(mi)
	var box := BoxMesh.new()
	box.size = Vector3(24, 4, 8)
	box.subdivide_width = 17
	box.subdivide_depth = 7
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	mesh.surface_set_material(0, StandardMaterial3D.new())
	mi.mesh = mesh
	fx.add_ship("box", body, {"faction": "ithar", "cls": "Frigate", "size": 0.8, "meshes": [mi]})
	var ship = fx.ship("box")
	Death.precompute(fx, ship)
	while not Death.finish_precompute(fx, ship):
		await process_frame
	var intact: Array = ship.current_arrays(mi, 0)
	var original_cut: Dictionary = ship.get_meta("cut_job", {})
	for i in 30:
		fx._build_death_pieces()
		if original_cut.get("built", false):
			break
		await process_frame
	_check(original_cut.get("built", false), "fixture has built pieces for an intact cached cut")
	# The old cut is still within its refresh interval. Rebuild a visible dent, then send two more wounds before death.
	ship._cut_t = fx.now
	ship._marks.append(Breach.crater(Vector3(-6, 2, 0), Vector3.UP, 2.1, 0.8, 1.0, Breach.S_DENT))
	ship._dmg_request(fx)
	ship.flush_damage(fx)
	var first: Array = ship.current_arrays(mi, 0)
	_check(first != intact, "fixture visibly changed the hull geometry")
	ship._marks.append(Breach.crater(Vector3(0, 2, 0), Vector3.UP, 2.1, 0.8, 2.0, Breach.S_DENT))
	ship._dmg_request(fx)
	ship._marks.append(Breach.crater(Vector3(6, 2, 0), Vector3.UP, 2.1, 0.8, 3.0, Breach.S_DENT))
	ship._dmg_request(fx)
	_check(ship.current_arrays(mi, 0) == first, "readers see the last published geometry, not in-flight output or intact plating")
	fx.death(ship.id, "blast")
	Death._break_up_when_ready(fx, ship, "blast", Color.WHITE, fx.now + 1.0)
	_check(not ship.has_meta("death_hidden"), "death does not split a stale cached cut while the rebuild is pending")
	mi.position.x += 3.0   # mimic the tell moving the dying mesh before the worker returns
	ship.flush_damage(fx)
	ship.flush_damage(fx)
	var rebuilt: Array = ship.current_arrays(mi, 0)
	var last_job: Dictionary = ship._dmg_job
	var cut: Dictionary = ship.get_meta("cut_job", {})
	_check(cut.get("cap_kind") == Death.CAP_GLASS, "the deferred Glasswright cut keeps its glass fracture faces")
	_check(rebuilt != first and rebuilt != intact and last_job["ents"].size() == 3,
		"the last rebuild includes the wound queued behind the running task")
	var cut_surfs: Array = cut.get("surfs", [])
	_check(not cut_surfs.is_empty() and cut_surfs[0]["arrays"] == rebuilt,
		"the death cut takes the final damaged surface snapshot")
	_check(not cut_surfs.is_empty() and cut_surfs[0]["xf"] == Transform3D.IDENTITY,
		"the cut keeps the death pose without baking in the tell motion")
	while not Death.finish_precompute(fx, ship):
		await process_frame
	for i in 30:
		fx._build_death_pieces()
		if cut.get("built", false):
			break
		await process_frame
	Death._break_up_when_ready(fx, ship, "blast", Color.WHITE, fx.now + 1.0)
	_check(cut.get("built", false) and ship.has_meta("death_hidden"), "death splits when the fresh pieces are ready")
	world.free()
	FX.clear_static()
	if failures == 0:
		print("PASS: death waits for current damage including a queued rebuild, then splits its fresh pieces")
	quit(1 if failures else 0)
