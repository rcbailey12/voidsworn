extends SceneTree

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const BREACH := preload("res://fx/fx_breach.gd")
const DEATH := preload("res://fx/fx_death.gd")

var failures := 0


# Stop the real rebuild inside its first dent pass, without blocking main-thread reads of the entry.
class HeldDent extends BREACH.Ent:
	var main_thread := OS.get_thread_caller_id()
	var entered := Semaphore.new()
	var release := Semaphore.new()
	var held := false

	func has_cut() -> bool:
		if OS.get_thread_caller_id() != main_thread and not held:
			held = true
			entered.post()
			var deadline := Time.get_ticks_msec() + 8000
			while not release.try_wait() and Time.get_ticks_msec() < deadline:
				OS.delay_msec(1)
		return false


func _init() -> void:
	GUARD.arm(self, "damage_worker_flicker_2199_check", 30.0)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _ship(fx: FX, id: String, multiple_surfaces := false) -> MeshInstance3D:
	var body := Node3D.new()
	fx.add_child(body)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(24, 5, 8)
	box.subdivide_width = 17
	box.subdivide_depth = 7
	var mesh := ArrayMesh.new()
	var arrays := box.get_mesh_arrays()
	if multiple_surfaces:
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var split := (indices.size() / 6) * 3
		arrays[Mesh.ARRAY_INDEX] = indices.slice(0, split)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arrays[Mesh.ARRAY_INDEX] = indices.slice(split)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mi.mesh = mesh
	body.add_child(mi)
	fx.add_ship(id, body, {"faction": "voidsworn", "cls": "Cruiser", "meshes": [mi], "shielded": false})
	return mi


func _worker_check(fx: FX) -> void:
	var mi := _ship(fx, "rebuild")
	var ship = fx.ship("rebuild")
	var original := mi.mesh.surface_get_arrays(0)
	ship._ents[1] = [BREACH.dent(Vector3(0, 2.5, 0), Vector3.UP, 5.0, 0.8, 2.0)]
	ship._dmg_request(fx)
	var prepared: bool = not ship._orig.is_empty() and (ship._orig[0] as Dictionary).has("grid")
	ship.flush_damage(fx)
	var drawn: Array = ship.current_arrays(mi, 0)
	_check(drawn[Mesh.ARRAY_VERTEX] != original[Mesh.ARRAY_VERTEX], "first rebuild really changes the drawn hull")

	var next := HeldDent.new()
	next.kind = BREACH.K_DENT
	next.style = BREACH.S_DENT
	next.c = Vector3(4, 2.5, 0)
	next.R = 5.0
	next.inf2 = 25.0
	next.depth = 1.1
	next.p = BREACH._phases(3.0)
	ship._ents[1] = [next]
	ship._dmg_request(fx)
	var task: int = ship._dmg_task
	var deadline := Time.get_ticks_msec() + 5000
	var entered := false
	while not entered and Time.get_ticks_msec() < deadline and not WorkerThreadPool.is_task_completed(task):
		entered = next.entered.try_wait()
		if not entered:
			await process_frame
	_check(entered and not WorkerThreadPool.is_task_completed(task), "second real rebuild is inside its worker pass")
	_check(prepared, "surface cache is prepared before the first rebuild is joined")
	DEATH.precompute(fx, ship, "blast", true)
	var cut: Dictionary = ship.get_meta("cut_job", {})
	var surfaces: Array = cut.get("surfs", [])
	_check(not surfaces.is_empty() and surfaces[0]["arrays"] == drawn and not WorkerThreadPool.is_task_completed(task),
		"death precompute gets the last drawn dent while the newer rebuild is still in flight")
	next.release.post()
	while not WorkerThreadPool.is_task_completed(task):
		await process_frame
	_check(ship._dmg_job.get("out", {}).is_empty() and ship.current_arrays(mi, 0) == drawn,
		"a finished worker does not publish geometry before the main-thread flush")
	ship.flush_damage(fx)
	var rebuilt: Array = ship.current_arrays(mi, 0)
	_check(rebuilt[Mesh.ARRAY_VERTEX] != drawn[Mesh.ARRAY_VERTEX], "flush hands over the new dent")
	fx.remove_ship("rebuild")
	mi.get_parent().queue_free()


func _material_flick_call_sites() -> int:
	# ShaderMaterial's native setter is not virtual and emits no change signal. Count call sites as well as
	# observing the material values on every frame, so a same-value write cannot sneak past the check.
	var setter := RegEx.new()
	setter.compile("\\.set_shader_parameter\\s*\\(\\s*&?[\"']fx_flick[\"']")
	var count := 0
	for file in ["fx_ship", "fx_breach", "fx_death", "fx_hull"]:
		var code := FileAccess.get_file_as_string("res://fx/%s.gd" % file)
		if code.is_empty():
			return -1
		count += setter.search_all(code).size()
	return count


func _flicker_check(fx: FX) -> void:
	var mi := _ship(fx, "flicker", true)
	var ship = fx.ship("flicker")
	ship.stage[1] = 3
	var matches := true
	var levels := {}
	var material_values := 0
	for reduce in [false, true]:
		fx.reduce_flashing = reduce
		ship.hit_power(fx, false, 0.62, 0.45)
		var start: float = fx.now
		for i in 90:
			fx.step(1.0 / 60.0)
			var age: float = fx.now - start
			var dip := 0.62 * (1.0 - smoothstep(0.0, 0.45, age))
			if not reduce:
				dip *= 0.82 + 0.18 * cos(age * TAU * 5.0)
			var expected: float = ship.power_flicker(fx.now, reduce) * (1.0 - dip)
			var actual = mi.get_instance_shader_parameter(&"fx_flick")
			matches = matches and actual != null and is_equal_approx(float(actual), expected)
			if age > 0.45:
				levels[actual] = true
			for si in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(si) as ShaderMaterial
				if mat != null and mat.get_shader_parameter(&"fx_flick") != null:
					material_values += 1
	for si in mi.mesh.get_surface_count():
		var mat := mi.get_active_material(si) as ShaderMaterial
		var code := mat.shader.code if mat != null else ""
		matches = matches and code.contains("instance uniform float fx_flick") and code.contains("* fx_flick;")
	var sites := _material_flick_call_sites()
	_check(matches and levels.size() >= 4 and ship._damage_surfaces.size() == 2,
		"one mesh multiplier keeps the brownout and the stepped flicker in both flashing modes")
	_check(sites == 0 and material_values == 0,
		"fx_flick material setter call sites %d, observed material values %d (180 frames, two surfaces)" % [sites, material_values])


func _run() -> void:
	var fx := FX.new()
	root.add_child(fx)
	fx.manual = true
	fx.defer_initial_cuts = true
	fx.setup({"quality": "high", "shake": 0.0})
	await _worker_check(fx)
	_flicker_check(fx)
	fx.release()
	print("damage_worker_flicker_2199_check: %d failure(s)" % failures)
	quit(1 if failures else 0)
