extends SceneTree
# Issue 234 S-B physics probe: physics step ms and collider cost against body count.
# Bodies match the game's wreck/debris settings: gravity off, altitude locked, Jolt,
# layers 1/2, bounce 0.4, damping REPLACE. Colliders are fx_death's real 50-direction
# convex hull collider. Run headless with --fixed-fps 60 so each loop is one fixed
# physics step; the wall time between physics_frame signals is the step cost.
# Output: PHYSPROBE_JSON=<path> or PROBE_OUT directory.

const FD = preload("res://fx/fx_death.gd")
const COUNTS := [50, 100, 150, 200, 250, 300, 350, 360, 400, 450, 500, 720]
const DAMPS := [0.0, 0.3]
const WARMUP := 60
const SAMPLES := 300

var out_path := ""

func _init() -> void:
	process_frame.connect(_go, CONNECT_ONE_SHOT)

func _go() -> void:
	out_path = OS.get_environment("PHYSPROBE_JSON")
	if out_path == "":
		var d := OS.get_environment("PROBE_OUT")
		if d != "": out_path = d.path_join("physics.json")
	if out_path == "": out_path = "physics.json"
	DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	var rows: Array = []
	print("PHYSPROBE start engine=%s" % ProjectSettings.get_setting("physics/3d/physics_engine"))
	var build_ms := _collider_build_cost()
	print("PHYSPROBE collider_build_ms=%.4f" % build_ms)
	for damp in DAMPS:
		for n in COUNTS:
			var convex := await _measure(n, damp, "convex")
			rows.append(convex)
			_print_row(convex)
			var none := await _measure(n, damp, "none")
			rows.append(none)
			_print_row(none)
			if n == 360:
				var box := await _measure(n, damp, "box")
				rows.append(box)
				_print_row(box)
	var payload := {"engine": ProjectSettings.get_setting("physics/3d/physics_engine"),
		"fixed_fps": 60, "warmup_frames": WARMUP, "sample_frames": SAMPLES,
		"collider_build_ms_per_body": build_ms,
		"collider_points": 50,
		"counts": COUNTS, "damps": DAMPS, "rows": rows}
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "  "))
		f.close()
	print("PHYSPROBE wrote %s rows=%d" % [out_path, rows.size()])
	quit(0)

func _make_cloud(rng: RandomNumberGenerator) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in 900:
		var u := rng.randf() * TAU
		var v := rng.randf_range(-1.0, 1.0)
		var r := sqrt(maxf(0.0, 1.0 - v * v))
		pts.append(Vector3(cos(u) * r * 3.0, v * 0.9, sin(u) * r * 1.1))
	return pts

func _collider_build_cost() -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261112
	var clouds: Array = []
	for i in 40:
		clouds.append(_make_cloud(rng))
	var t0 := Time.get_ticks_usec()
	for c in clouds:
		var s: Shape3D = FD.safe_convex(c)
		if s == null: return -1.0
	return (Time.get_ticks_usec() - t0) / 1000.0 / float(clouds.size())

func _measure(n: int, damp: float, kind: String) -> Dictionary:
	var holder := Node3D.new()
	root.add_child(holder)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777 + n
	var shapes: Array = []
	if kind != "none":
		for i in 16:
			shapes.append(FD.safe_convex(_make_cloud(rng)))
	var bounce := PhysicsMaterial.new()
	bounce.bounce = 0.4
	bounce.friction = 0.4
	var side := int(ceil(pow(float(n), 1.0 / 3.0)))
	var spacing := 2.8
	var t0 := Time.get_ticks_usec()
	for i in n:
		var b := RigidBody3D.new()
		b.gravity_scale = 0.0
		b.axis_lock_linear_y = true
		b.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		b.mass = 5.0
		b.can_sleep = false
		b.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
		b.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
		b.linear_damp = damp
		b.angular_damp = damp
		b.collision_layer = 2
		b.collision_mask = 3
		b.physics_material_override = bounce
		if kind == "convex":
			var cs := CollisionShape3D.new()
			cs.shape = shapes[i % shapes.size()]
			b.add_child(cs)
		elif kind == "box":
			var cs2 := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(2.4, 1.0, 1.0)
			cs2.shape = bs
			b.add_child(cs2)
		holder.add_child(b)
		var ix := i % side
		var iy := int(i / side) % side
		var iz := int(i / (side * side))
		b.position = Vector3(ix, iy, iz) * spacing
		b.linear_velocity = Vector3(rng.randf_range(-3.0, 3.0), 0.0, rng.randf_range(-3.0, 3.0))
		b.angular_velocity = Vector3(rng.randf_range(-3.0, 3.0), rng.randf_range(-3.0, 3.0), rng.randf_range(-3.0, 3.0))
	var create_ms := (Time.get_ticks_usec() - t0) / 1000.0
	holder.force_update_transform()
	for i in WARMUP:
		await physics_frame
	var wall: Array = []
	var prev := Time.get_ticks_usec()
	for i in SAMPLES:
		await physics_frame
		var now := Time.get_ticks_usec()
		wall.append((now - prev) / 1000.0)
		prev = now
	holder.queue_free()
	for i in 4:
		await physics_frame
	wall.sort()
	var sum := 0.0
	for v in wall: sum += v
	var median: float = wall[wall.size() / 2]
	var p95: float = wall[int(wall.size() * 0.95)]
	var out := {"count": n, "damp": damp, "kind": kind, "median_ms": median,
		"p95_ms": p95, "mean_ms": sum / float(wall.size()),
		"max_ms": wall[wall.size() - 1], "min_ms": wall[0],
		"create_ms": create_ms, "bodies": n,
		"colliders": 0 if kind == "none" else n}
	if kind == "convex": out["points_per_shape"] = 50
	return out

func _print_row(r: Dictionary) -> void:
	print("PHYSPROBE n=%d damp=%.1f kind=%s median_ms=%.4f p95_ms=%.4f mean_ms=%.4f create_ms=%.3f" %
		[r["count"], r["damp"], r["kind"], r["median_ms"], r["p95_ms"], r["mean_ms"], r["create_ms"]])
