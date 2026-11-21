extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Ryan, Nov 21 2026 (in game): frigates and destroyers still broke apart wildly and their pieces spun off very far. With the
# strained death on (the default), a small metal hull's pieces part the calm way a big hull's do. A box frigate and a box
# destroyer are killed at quality high (physics pieces, Jolt), and 10 s later every wreck piece must sit within FAR_MAX of
# the length from where the ship was, turn slower than SPIN_MAX, and be all but still. The old path (death_story off) is
# printed beside it for comparison only.
const FX := preload("res://fx/fx.gd")
const FAR_MAX := 0.7
const SPIN_MAX := 0.3
const SPEED_MAX := 0.02   # lengths a second at 10 s
var failures := 0


func _init() -> void:
	GUARD.arm(self, "small_wreck_calm_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + why)
	if not ok:
		failures += 1
		push_error(why)


func _run() -> void:
	for cls in ["Frigate", "Destroyer"]:
		var calm := await _kill(cls, "strain")
		var old := await _kill(cls, "off")
		print("SMALL_WRECK %s strain %s | off %s" % [cls, JSON.stringify(calm), JSON.stringify(old)])
		check(int(calm["n"]) >= 2, "%s: it breaks into pieces (%d)" % [cls, calm["n"]])
		check(float(calm["far"]) <= FAR_MAX, "%s: pieces stay within %.2f L of the ship after 10 s (%.2f L; old path %.2f L)" % [cls, FAR_MAX, calm["far"], old["far"]])
		check(float(calm["spin_peak"]) <= SPIN_MAX, "%s: pieces turn slowly (peak %.2f rad/s; old path %.2f)" % [cls, calm["spin_peak"], old["spin_peak"]])
		check(float(calm["speed"]) <= SPEED_MAX, "%s: pieces have come to rest by 10 s (%.3f L/s; old path %.3f)" % [cls, calm["speed"], old["speed"]])
	print("SMALL_WRECK failures=%d" % failures)
	quit(1 if failures else 0)


func _kill(cls: String, story: String) -> Dictionary:
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.position = Vector3(0, 30, 40)
	var holder := Node3D.new()
	world.add_child(holder)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(20, 4, 6)
	box.subdivide_width = 19
	box.subdivide_height = 3
	box.subdivide_depth = 5
	mi.mesh = box
	mi.set_surface_override_material(0, StandardMaterial3D.new())
	holder.add_child(mi)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "camera": cam, "shake": 0.0, "death_story": story})
	fx.add_ship("k", holder, {"faction": "hegemony", "cls": cls, "size": 1.0})
	var s = fx.ship("k")
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 60000:
		fx.step(1.0 / 60.0)
		await process_frame
		if (s.get_meta("cut_job", {}) as Dictionary).get("built", false): break
	fx.death("k", "blast")
	var L: float = s.hull.L
	var c0: Vector3 = holder.global_position
	var res := {"n": 0, "far": 0.0, "spin_peak": 0.0, "speed": 0.0}
	var last := {}
	for i in 10 * 60:
		fx.step(1.0 / 60.0)
		await process_frame
		for w in fx.dstate.get("wrecks", []):
			if w["id"] != "k": continue
			res["n"] = (w["nodes"] as Array).size()
			for nd in w["nodes"]:
				if not is_instance_valid(nd): continue
				var p: Vector3 = (nd as Node3D).global_position
				if i == 10 * 60 - 1:
					res["far"] = maxf(float(res["far"]), p.distance_to(c0) / L)
					if last.has(nd.get_instance_id()): res["speed"] = maxf(float(res["speed"]), p.distance_to(last[nd.get_instance_id()]) * 60.0 / L)
				last[nd.get_instance_id()] = p
				var spin := 0.0
				if nd is RigidBody3D and not (nd as RigidBody3D).freeze: spin = (nd as RigidBody3D).angular_velocity.length()
				for f in w.get("fires", []):
					if f.get("node") == nd and f.has("ang"): spin = maxf(spin, (f["ang"] as Vector3).length())
				res["spin_peak"] = maxf(float(res["spin_peak"]), spin)
	world.queue_free()
	await process_frame
	return res
