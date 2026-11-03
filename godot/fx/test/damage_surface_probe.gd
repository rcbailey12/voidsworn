extends SceneTree
# Deterministic R80 stills and steady-state 20 real hull frame cost. Output stays
# outside the checkout: DAMAGE_OUT, DAMAGE_MODE=capture|fleet, DAMAGE_LABEL.
const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const CASES := [["hegemony", "Cruiser", 0.8], ["deathless", "Battleship", 1.0],
	["chorus", "Cruiser", 0.8], ["ithar", "Cruiser", 0.8], ["voidsworn", "Cruiser", 0.8]]
var vp: SubViewport
var world: Node3D
var cam: Camera3D
var fx
var out := ""

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	out = OS.get_environment("DAMAGE_OUT")
	if out == "":
		push_error("Set DAMAGE_OUT to a scratch folder")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out)
	seed(66080)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	vp = SubViewport.new()
	vp.size = Vector2i(3840, 2160)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.03, 0.045)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.7)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var light := DirectionalLight3D.new()
	light.light_energy = 2.2
	light.rotation_degrees = Vector3(-55, -30, 0)
	world.add_child(light)
	cam = Camera3D.new()
	cam.fov = 45.0
	cam.current = true
	world.add_child(cam)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max", "shake": 0.0, "seed": 66080})
	if OS.get_environment("DAMAGE_MODE") == "fleet":
		await _fleet()
	else:
		await _capture()
	fx.release()
	world.queue_free()
	await process_frame
	SV.clear_static()
	FX.clear_static()
	quit()

func _ship(sid: String, c: Array, pos: Vector3):
	var sv := SV.new()
	world.add_child(sv)
	# No Eclipse battleship asset entry exists. Use the real D22 at that scale.
	var info := {"id": sid, "fac": c[0], "cls": c[1], "facing": 0}
	if c[0] == "deathless" and c[1] == "Battleship": info["code"] = "D22_23"
	sv.setup(info, pos)
	if not sv.a4:
		push_error("Real A4 hull missing: " + sid)
		quit(2)
	fx.add_ship(sid, sv, {"faction": c[0], "cls": c[1], "size": c[2], "meshes": sv.meshes, "shielded": false})
	var s = fx.ship(sid)
	fx._later.clear() # no unrelated death precompute during damage measurement
	# Repeatable visible anchors on the real top skin in all three sections.
	for i in 3:
		var h = s.hull
		var x: float = h.c.x + (i - 1) * h.L * 0.28
		var z: float = h.c.z + (h.W * 0.22 if c[0] == "deathless" else 0.0)
		var hit: Dictionary = h.ray(Vector3(x, h.c.y + h.H * 3, z), Vector3.DOWN)
		if not hit.is_empty():
			s._anchors["a%d" % i] = {"p": hit.p, "n": hit.n, "t": {}}
	return s

func _flush(s) -> void:
	for i in 5:
		if s._dmg_task >= 0: s.flush_damage(fx)

func _still(name: String) -> void:
	for i in 4:
		await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(out.path_join(name + ".png"))

func _capture() -> void:
	for c in CASES:
		var sid: String = c[0]
		var only := OS.get_environment("DAMAGE_FACTIONS")
		if only != "" and not sid in only.split(","): continue
		var s = _ship(sid, c, Vector3.ZERO)
		print("DAMAGE_HULL %s L=%.2f tris=%d" % [sid, s.hull.L, s.hull.tri_count])
		for st in 5:
			if OS.get_environment("DAMAGE_REPAIRS_ONLY") == "1" and st < 4: continue
			fx.now = 10.0 + st * 10.0
			s.set_stages(fx, [st, st, st])
			_flush(s)
			fx.step(1.4) # compare settled wounds, after transition sparks and lights
			if OS.get_environment("DAMAGE_REPAIRS_ONLY") == "1":
				var a: Dictionary = s._anchor(1, "a")
				var p: Vector3 = s.to_world(a.p)
				cam.look_at_from_position(p + (s.dir_world(a.n) + Vector3(0.15, 0.1, 0.2)).normalized() * s.hull.L * 0.36, p)
				continue
			var center: Vector3 = s.to_world(s.hull.c)
			for zoom in ["battle", "close"]:
				var distance: float = 170.0 if zoom == "battle" else s.hull.L * 1.45
				cam.look_at_from_position(center + Vector3(0.12, 0.8, 0.6).normalized() * distance, center)
				await _still("%s_stage%d_%s" % [sid, st, zoom])
			if st in [3, 4]:
				var a: Dictionary = s._anchor(1, "a")
				var p: Vector3 = s.to_world(a.p)
				var n: Vector3 = s.dir_world(a.n)
				cam.look_at_from_position(p + (n + Vector3(0.15, 0.1, 0.2)).normalized() * s.hull.L * 0.36, p)
				await _still("%s_stage%d_detail" % [sid, st])
		if OS.get_environment("DAMAGE_LABEL") != "baseline":
			s.set_stages(fx, [0, 0, 0])
			_flush(s)
			fx.step(0.1)
			await _still(sid + "_repair_start")
			fx.step(3.2)
			await _still(sid + "_repaired")
		fx.remove_ship(sid)
		s.root.queue_free()
		await process_frame
	print("DAMAGE_CAPTURE_COMPLETE " + out)

func _fleet() -> void:
	var ships: Array = []
	for i in 20:
		var c: Array = CASES[i % CASES.size()].duplicate()
		if i < 10: c = [c[0], "Frigate", 0.55]
		elif i < 16: c = [c[0], "Cruiser", 0.8]
		else: c = [c[0], "Battleship" if c[0] in ["hegemony", "deathless"] else "Carrier", 1.0]
		ships.append(_ship(str(i), c, Vector3((i % 5 - 2) * 29, 0, (i / 5 - 1.5) * 24)))
	cam.look_at_from_position(Vector3(0, 115, 125), Vector3.ZERO)
	var results := {}
	for st in [0, 3, 4]:
		var transition := Time.get_ticks_usec()
		for s in ships:
			s.set_stages(fx, [st, st, st])
			_flush(s)
		var build_ms := (Time.get_ticks_usec() - transition) / 1000.0
		for i in 90:
			fx.step(1.0 / 60.0)
			await RenderingServer.frame_post_draw
		fx.prof_take()
		var times: Array = []
		var cpu: Array = []
		var prev := Time.get_ticks_usec()
		for i in 240:
			var t := Time.get_ticks_usec()
			fx.step(1.0 / 60.0)
			cpu.append((Time.get_ticks_usec() - t) / 1000.0)
			await RenderingServer.frame_post_draw
			var stamp := Time.get_ticks_usec()
			times.append((stamp - prev) / 1000.0)
			prev = stamp
		var total := 0.0
		for t in times: total += t
		times.sort()
		cpu.sort()
		var row := {"avg_ms": total / times.size(), "p99_ms": times[237], "fx_cpu_p99_ms": cpu[237], "build_ms": build_ms, "prof": fx.prof_take()}
		if fx.has_method("damage_counts"): row["emitters"] = fx.damage_counts()
		results[str(st)] = row
		print("DAMAGE_FLEET stage=%d %s" % [st, JSON.stringify(row)])
		await _still("fleet_stage%d" % st)
	results["renderer"] = RenderingServer.get_current_rendering_method()
	results["adapter"] = RenderingServer.get_video_adapter_name()
	FileAccess.open(out.path_join("fleet.json"), FileAccess.WRITE).store_string(JSON.stringify(results, "\t"))
