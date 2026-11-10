extends SceneTree
# Deterministic real-asset recordings and a separate readback-free 20-ship 4K profile.
const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const LOOK := preload("res://render/look.gd")
const RIG := preload("res://render/camera_rig.gd")
const PG := preload("res://render/placeholder_guard.gd")
var out: String
var vp: SubViewport
var world: Node3D
var fx
var cam: Camera3D

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _ship(id: String, cls: String, pos: Vector3, faction := "voidsworn") -> Node3D:
	var sv := SV.new()
	world.add_child(sv)
	var size := 0.55 if cls == "Frigate" else (0.8 if cls == "Cruiser" else 1.0)
	sv.setup({"id": id, "fac": faction, "cls": cls, "facing": 0, "hp": 100, "maxHp": 100, "size": size}, pos, true)
	sv.set_process(false)
	fx.add_ship(id, sv, {"faction": faction, "cls": cls, "size": size, "meshes": sv.meshes, "code": sv.code})
	return sv

func _step() -> void:
	fx.step(1.0 / 60.0)
	await RenderingServer.frame_post_draw

func _run() -> void:
	out = OS.get_environment("DEATH_OUT")
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var profile := OS.get_environment("DEATH_PROFILE") == "1"
	vp = SubViewport.new()
	vp.size = Vector2i(3840, 2160) if profile else Vector2i(1280, 720)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.012, 0.025)
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()
	var fill := DirectionalLight3D.new()
	world.add_child(key)
	world.add_child(fill)
	var quality := OS.get_environment("DEATH_QUALITY")
	if quality.is_empty(): quality = "max"
	LOOK.apply(env, key, fill, {"quality": quality})
	cam = RIG.new()
	world.add_child(cam)
	cam.current = true
	cam.set_process(false)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": quality, "shake": 0.0, "seed": 137})
	if profile:
		await _profile()
	elif OS.get_environment("DEATH_STILLS") == "1":
		await _interiors()
	else:
		for spec in [["voidsworn", "Cruiser"], ["voidsworn", "Battleship"], ["voidsworn", "Frigate"], ["chorus", "Frigate"]]:
			var cls: String = spec[1]
			if not OS.get_environment("DEATH_CLASS").is_empty() and cls != OS.get_environment("DEATH_CLASS"): continue
			if not OS.get_environment("DEATH_FACTION").is_empty() and spec[0] != OS.get_environment("DEATH_FACTION"): continue
			for zoom in ["battle", "close"]:
				if not OS.get_environment("DEATH_ZOOM").is_empty() and zoom != OS.get_environment("DEATH_ZOOM"): continue
				var sv := _ship("C", cls, Vector3.ZERO, spec[0])
				if PG.stop_if_any():
					return
				var s = fx.ship("C")
				for i in 300: await _step()
				while s.has_meta("cut_task"): await _step()
				cam.a = -PI / 2.0; cam.b = 0.98
				cam.r = 170.0 if zoom == "battle" else s.hull.L * 1.8
				cam.t = s.to_world(s.hull.c); cam.snap()
				await _step()
				var folder := out.path_join(spec[0] + "_" + cls.to_lower() + "_" + zoom)
				DirAccess.make_dir_recursive_absolute(folder)
				var t: float = fx.now
				fx.death("C", "blast")
				for frame in 300:
					await _step()
					if frame % 2 == 0:
						vp.get_texture().get_image().save_jpg(folder.path_join("frame_%03d.jpg" % (frame / 2)), 0.9)
				print("DEATH_RECORD class=%s zoom=%s duration=%.3f flashes=%s" % [cls, zoom, fx.now-t, fx.flash_log])
				fx.clear_wreck("C"); fx.remove_ship("C"); sv.queue_free()
				for i in 180: await _step()
	fx.release()
	SV.clear_static()
	FX.clear_static()
	PG.finish(0)

func _interiors() -> void:
	for faction in ["voidsworn", "hegemony", "corsair", "deathless", "ithar", "chorus"]:
		var sv := _ship("C", "Cruiser" if faction != "chorus" else "Frigate", Vector3.ZERO, faction)
		if PG.stop_if_any():
			return
		var s = fx.ship("C")
		for i in 300: await _step()
		while s.has_meta("cut_task"): await _step()
		# Same persistent stage-4 holes as battle, with no lethal damage.
		s.set_stages(fx, [4, 4, 4])
		while s._dmg_task >= 0:
			s.flush_damage(fx)
			await _step()
		for i in 60: await _step()
		cam.a = -0.9; cam.b = 1.1; cam.r = s.hull.L * 1.5
		cam.t = s.to_world(s.hull.c); cam.snap()
		await _step()
		vp.get_texture().get_image().save_png(out.path_join(faction + "_alive.png"))
		while s.has_meta("cut_task"): await _step()
		for pc in s.get_meta("cut_job", {}).get("out", []):
			print("INTERIOR faction=%s vertices=%d edges=%d loops=%d fallbacks=%d cap_vertices=%d" % [faction, pc.n, pc.get("boundary_edges", 0), pc.get("cap_loops", 0), pc.get("cap_fallbacks", 0), pc.get("cap", [PackedVector3Array()])[0].size()])
		fx.death("C", "blast")
		for i in 210: await _step()
		for angle in [0, 1]:
			cam.a = -0.5 if angle == 0 else 2.6; cam.snap()
			await _step()
			vp.get_texture().get_image().save_png(out.path_join(faction + "_cut%d.png" % angle))
		fx.clear_wreck("C"); fx.remove_ship("C"); sv.queue_free()
		for i in 180: await _step()

func _profile() -> void:
	for i in 20:
		_ship(str(i), "Battleship" if i == 7 else ("Cruiser" if i % 3 == 0 else "Frigate"), Vector3((i % 5 - 2) * 30.0, 0, (i / 5 - 1.5) * 26.0))
	if PG.stop_if_any():
		return
	await fx.warmup(cam)
	for i in 600: await _step()
	for s in fx.ships.values():
		while s.has_meta("cut_task"): await _step()
	cam.r = 170; cam.snap()
	for i in 120: await _step()
	var baseline: Array = []
	for i in 120:
		var stamp := Time.get_ticks_usec()
		await _step()
		baseline.append((Time.get_ticks_usec()-stamp)/1000.0)
	var samples: Array = []
	var death_window: Array = []
	var t: float = fx.now
	var lethal_stamp := Time.get_ticks_usec()
	fx.death("7", "blast")
	var death_call_ms := (Time.get_ticks_usec() - lethal_stamp) / 1000.0
	for i in 300:
		var stamp := lethal_stamp if i == 0 else Time.get_ticks_usec()
		await _step()
		var ms := (Time.get_ticks_usec()-stamp)/1000.0
		samples.append(ms)
		if fx.now-t <= 2.1: death_window.append(ms)
		if ms > 12.0: print("DEATH_HITCH frame=%d age=%.3f ms=%.3f fx=%s" % [i,fx.now-t,ms,fx.prof_take()])
	# Readback is after measurement. No fixed-fps cap is used in profile mode.
	vp.get_texture().get_image().save_png(out.path_join("fleet_4k.png"))
	var report := {"ships": 20, "resolution": [3840,2160], "adapter": RenderingServer.get_video_adapter_name(), "renderer": RenderingServer.get_current_rendering_method(), "death_call_ms": death_call_ms, "baseline": _stats(baseline), "capital_first_2s": _stats(death_window), "whole_5s": _stats(samples), "target_ms": 1000.0/60.0}
	print("DEATH_PROFILE ", JSON.stringify(report))
	FileAccess.open(out.path_join("frame_times.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))

func _stats(samples: Array) -> Dictionary:
	samples.sort()
	var total := 0.0
	for x in samples: total += x
	return {"frames": samples.size(), "mean_ms": total/samples.size(), "p95_ms": samples[int(samples.size()*.95)], "p99_ms": samples[int(samples.size()*.99)], "max_ms": samples.back(), "frames_over_target": samples.filter(func(x): return x > 1000.0/60.0).size()}
