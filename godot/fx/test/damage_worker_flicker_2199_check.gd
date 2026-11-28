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
	var first := _held_dent(-5.0)
	ship._ents[1] = [first]
	ship._dmg_request(fx)
	var task: int = ship._dmg_task
	var entered := await _wait_for_dent(first, task)
	_check(entered and not WorkerThreadPool.is_task_completed(task), "the first real rebuild is held after its grid preparation")
	_check(not ship._orig.is_empty() and not ship._orig[0].has("grid") and ship._dmg_surface_cache.is_empty(),
		"first-hit prep leaves the original surface untouched and the cache with the worker")
	first.release.post()
	ship.flush_damage(fx)
	var drawn: Array = ship.current_arrays(mi, 0)
	_check(drawn[Mesh.ARRAY_VERTEX] != original[Mesh.ARRAY_VERTEX], "first rebuild really changes the drawn hull")
	var cached: Dictionary = ship._dmg_surface_cache.get(0, {})
	_check(cached.has("grid") and not ship._orig[0].has("grid"), "only the joined worker copy holds the prepared grid")

	var next := _held_dent(1.0)
	ship._ents[1] = [first, next]
	ship._dmg_request(fx)
	task = ship._dmg_task
	entered = await _wait_for_dent(next, task)
	_check(entered and not WorkerThreadPool.is_task_completed(task), "second real rebuild is inside its worker pass")
	DEATH.precompute(fx, ship, "blast", true)
	_check(not ship.has_meta("cut_job") and ship.has_meta("cut_after_damage") and ship.current_arrays(mi, 0, true) == drawn,
		"death precompute during the held rebuild defers the cut and sees only drawn arrays")
	var last := BREACH.dent(Vector3(8, 2.5, 0), Vector3.UP, 4.0, 0.8, 4.0)
	ship._ents[1] = [first, next, last]
	ship._dmg_request(fx)
	fx.death(ship.id, "blast")
	var live_mesh := mi.mesh
	_check(ship._dmg_dirty and not ship.has_meta("cut_job") and not WorkerThreadPool.is_task_completed(task),
		"kill waits for both the in-flight and queued damage revisions")
	next.release.post()
	while not WorkerThreadPool.is_task_completed(task):
		await process_frame
	_check(ship._dmg_job.get("out", {}).is_empty() and ship.current_arrays(mi, 0, true) == drawn,
		"a finished worker does not publish geometry before the main-thread flush")
	ship.flush_damage(fx)
	var intermediate: Array = ship.current_arrays(mi, 0, true)
	_check(ship.damage_pending() and not ship.has_meta("cut_job"), "joining the first task still does not cut over queued damage")
	ship.flush_damage(fx)
	var cut: Dictionary = ship.get_meta("cut_job", {})
	var surfaces: Array = cut.get("surfs", [])
	var final_arrays: Array = ship._dmg_job["out"]["surfs"][0]
	_check(ship.cut_matches_damage(cut) and ship._dmg_job["ents"].size() == 3 and not surfaces.is_empty()
		and surfaces[0]["arrays"] == final_arrays and final_arrays != intermediate and final_arrays != drawn,
		"death cuts the latest joined revision including the queued hit")
	_check(mi.mesh == live_mesh and ship.current_arrays(mi, 0) == drawn,
		"the death cut receives final geometry without swapping the dying hull")
	_check(is_same(cached, ship._dmg_surface_cache.get(0)) and not ship._orig[0].has("grid"),
		"later rebuilds reuse the same private grid without updating original surfaces")
	fx.remove_ship("rebuild")
	mi.get_parent().queue_free()


func _held_dent(x: float) -> HeldDent:
	var dent := HeldDent.new()
	dent.kind = BREACH.K_DENT
	dent.style = BREACH.S_DENT
	dent.c = Vector3(x, 2.5, 0)
	dent.R = 5.0
	dent.inf2 = 25.0
	dent.depth = 1.1
	dent.p = BREACH._phases(3.0)
	return dent


func _wait_for_dent(dent: HeldDent, task: int) -> bool:
	var deadline := Time.get_ticks_msec() + 5000
	var entered := false
	while not entered and Time.get_ticks_msec() < deadline and not WorkerThreadPool.is_task_completed(task):
		entered = dent.entered.try_wait()
		if not entered:
			await process_frame
	return entered



func _apply_early_return_check(fx: FX) -> void:
	var mi := _ship(fx, "skipped_apply")
	var ship = fx.ship("skipped_apply")
	ship._ents[1] = [BREACH.dent(Vector3(-5, 2.5, 0), Vector3.UP, 5.0, 0.8, 2.0)]
	ship._dmg_request(fx)
	ship.flush_damage(fx)
	var drawn_mesh := mi.mesh
	var drawn: Array = ship.current_arrays(mi, 0)
	ship._ents[1] = [BREACH.dent(Vector3(5, 2.5, 0), Vector3.UP, 5.0, 0.8, 3.0)]
	ship._dmg_request(fx)
	var damage_root: Node3D = ship._dmg_root
	ship._dmg_root = null  # Apply cannot attach anything after the damage root goes away.
	ship.flush_damage(fx)
	ship._dmg_root = damage_root
	var skipped: Array = ship._dmg_job["out"]["surfs"][0]
	_check(skipped != drawn and mi.mesh == drawn_mesh and ship.current_arrays(mi, 0) == drawn,
		"early-return apply leaves both the mesh and its drawn arrays on the previous revision")
	DEATH.precompute(fx, ship, "blast", true)
	var surfaces: Array = ship.get_meta("cut_job", {}).get("surfs", [])
	_check(not surfaces.is_empty() and surfaces[0]["arrays"] == drawn, "a cut after skipped apply uses the actual drawn arrays")
	fx.remove_ship("skipped_apply")
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
	_apply_early_return_check(fx)
	_flicker_check(fx)
	fx.release()
	print("damage_worker_flicker_2199_check: %d failure(s)" % failures)
	quit(1 if failures else 0)
