extends SceneTree
# Presentation contracts: ordinary hits preserve the skin, heavy section damage
# opens a break, and emitted exhaust stays in space after a turn and a stop.
const FX := preload("res://fx/fx.gd")
const BREACH := preload("res://fx/fx_breach.gd")
var failures := 0

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})
	var body := Node3D.new()
	world.add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(24, 5, 8)
	box.subdivide_width = 17
	box.subdivide_depth = 7
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	mesh.mesh = am
	mesh.material_override = StandardMaterial3D.new()
	body.add_child(mesh)
	fx.add_ship("test", body, {"faction": "hegemony", "cls": "Cruiser", "size": 0.8, "meshes": [mesh]})
	var ship = fx.ship("test")
	# This test exercises live damage and exhaust, without scheduling death cuts.
	fx._later.clear()
	for faction in ["hegemony", "corsair", "chorus"]:
		for hp in [90.0, 70.0, 50.0, 30.0]:
			for weapon in ["lance", "ion", "macro", "plasma", "flak", "spine", "gauss", "torp", "rockets", "ram", "board"]:
				var marks := BREACH.marks_for(ship.hull, weapon, 4, Vector3(0, 2.5, 0), Vector3.UP, Vector3.DOWN, 73.0, faction, 1.6, 1.0 - hp / 100.0)
				for mark in marks:
					check(not mark.has_cut() and mark.kind == BREACH.K_SURFACE, "%s %s at %.0f%% keeps the hull closed" % [faction, weapon, hp])
	for stage in [1, 2, 3]:
		for entry in ship._plan(fx, 1, stage):
			check(not entry.has_cut() and entry.kind == BREACH.K_SURFACE, "section stage %d keeps its original surface" % stage)
	var heavy: Array = ship._plan(fx, 1, 4)
	check(heavy.any(func(e): return e.has_cut()), "near-destroyed section opens a break")
	ship._anchors["a1"] = {"p": Vector3(0, 2.5, 0), "n": Vector3.UP, "t": {}}
	ship.sync(fx, {"hp": 30, "maxHp": 100, "sec": {"eng": {"hp": 100, "max": 100}, "mid": {"hp": 30, "max": 100}, "prow": {"hp": 100, "max": 100}}})
	ship.add_mark(fx, "torp", 4, Vector3(0, 2.5, 0), Vector3.UP, Vector3.DOWN)
	for i in 4:
		if ship._dmg_task >= 0: ship.flush_damage(fx)
	check(ship.stage == [0, 3, 0], "damage follows the struck section")
	check(ship._dmg_job.out.inside == null, "normal damage builds no hollow interior")
	check(ship._dmg_job.out.skin != null, "normal damage leaves a visible surface burn")
	# One sample per nozzle, then a straight flight followed by a turn.
	ship._eng_cur = 1.5
	for i in 12:
		body.position.x += 1.0
		fx.now += 0.06
		ship._update_trails(fx, true)
	var saved: Array = []
	for trail in ship._trails:
		saved.append(trail.hist.duplicate(true))
	body.rotation.y = PI / 2.0
	body.position.z += 3.0
	fx.now += 0.06
	ship._update_trails(fx, true)
	for i in ship._trails.size():
		var trail: Dictionary = ship._trails[i]
		var vertices: PackedVector3Array = trail.mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for j in saved[i].size():
			var old: Array = saved[i][j]
			check(trail.hist[j + 1] == old, "turn keeps the emitted position, age and power")
			check(vertices[(j + 1) * 2] == old[0], "ribbon vertices remain at their emitted world positions")
	ship._eng_cur = 0.0
	fx.now += 0.2
	ship._update_trails(fx, false)
	check(ship._trails[0].mi.visible, "old exhaust remains after the drive stops")
	fx.now += 3.0
	ship._update_trails(fx, false)
	for trail in ship._trails:
		check(trail.hist.is_empty() and not trail.mi.visible, "old exhaust expires by age")
	print("PLAYTEST_BATCH3 failures=%d" % failures)
	fx.queue_free()
	await process_frame
	world.queue_free()
	await process_frame
	FX.clear_static()
	quit(1 if failures else 0)
