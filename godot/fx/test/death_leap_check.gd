extends SceneTree
# Issue 137 contracts: timed sections, tiers, lifetime, cleanup and vacuum drift.
const FX := preload("res://fx/fx.gd")
var failures := 0

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	for quality in ["max", "high", "low"]:
		var world := Node3D.new()
		root.add_child(world)
		var fx = FX.new()
		world.add_child(fx)
		fx.manual = true
		fx.setup({"quality": quality, "shake": 0.0})
		var probe_mat := preload("res://fx/fx_death.gd").flipbook_material(fx, "flash")
		check(probe_mat.get_shader_parameter("atlas") is Texture2D, "baked atlas is imported")
		var r := Node3D.new()
		world.add_child(r)
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(24, 4, 6)
		box.subdivide_width = 23; box.subdivide_height = 3; box.subdivide_depth = 5
		mi.mesh = box
		r.add_child(mi)
		fx.add_ship("T", r, {"faction": "voidsworn", "cls": "Battleship", "size": 1.0, "meshes": [mi]})
		var s = fx.ship("T")
		for i in 120:
			fx.step(1.0/60.0)
			await process_frame
		var start: float = fx.now
		check(is_equal_approx(fx.death("T", "blast"), 2.05), "capital timeline is bounded at 2.05 s")
		for i in 132:
			fx.step(1.0/60.0)
			await process_frame
			if i == 30: check(not s.has_meta("death_hidden"), "vent precedes structural replacement")
			if i == 66 and not fx.dstate.wrecks.is_empty():
				var w: Dictionary = fx.dstate.wrecks[0]
				check(w.cut_events.size() == 1, "first cut releases only the first section")
		check(fx.dstate.wrecks.size() == 1, "one wreck owns the staged sections")
		var wreck: Dictionary = fx.dstate.wrecks[0]
		check(wreck.nodes.size() == 4 and wreck.cut_events.size() == 4, "battleship has three cuts and four sealed sections")
		check(float(wreck.cut_events.back().t) - float(wreck.cut_events.front().t) >= 0.78, "cuts are separated over 0.8 s")
		check(wreck.mats.is_empty() == (quality == "low"), "max and high have cooling fracture edges")
		for node in wreck.nodes:
			if node is RigidBody3D:
				check(not node.freeze and node.linear_damp == 0.0 and node.angular_damp == 0.0, "released rigid sections keep momentum")
		var kin: Array = wreck.fires.filter(func(f): return f.has("vel") and not f.has("until"))
		if quality == "low":
			check(kin.size() == 4, "low releases all kinematic sections")
			var velocity: Vector3 = kin[0].vel
			fx.step(0.5)
			check(kin[0].vel == velocity, "low tier has no hidden drag")
		check(fx.find_children("fx_baked_vent", "MeshInstance3D", true, false).is_empty(), "finite vent has expired")
		check(fx.find_children("fx_fireball", "MeshInstance3D", true, false).is_empty(), "no raymarched death volume")
		for flash in fx.flash_log:
			var count := 0
			for t in fx.flash_log:
				if t >= flash and t < flash + 1.0: count += 1
			check(count <= 3, "rolling flash cap")
		for i in 32: fx.step(0.5)
		for mat in wreck.mats: check(float(mat.get_shader_parameter("heat")) == 0.0, "fracture faces are cold after 14 s")
		fx.clear_wreck("T")
		await process_frame
		check(fx.dstate.wrecks.is_empty(), "wreck cleanup owns every section")
		print("DEATH_LEAP quality=%s sections=4 staged=ok vacuum_drift=ok cooling=ok" % quality)
		# Dummy renderer teardown has the same guard as ShipView._exit_tree.
		for mesh in world.find_children("*", "MeshInstance3D", true, false): mesh.set_base(RID())
		fx.release()
		world.queue_free()
		await process_frame
	print("DEATH_LEAP failures=%d" % failures)
	quit(1 if failures else 0)
