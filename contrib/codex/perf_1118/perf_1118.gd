extends "res://bench/scene_gate.gd"
# Issue 1070. The game is staged with the shared build's installed assets.

const STAMP := preload("res://tools/picture_provenance.gd")
const WORLD := preload("res://world/world.gd")
const METRICS := ["frame_ms", "main_process_ms", "render_cpu_ms", "gpu_ms",
	"visible_draws", "shadow_draws", "visible_objects", "shadow_objects",
	"visible_primitives", "shadow_primitives", "video_bytes", "objects",
	"resources", "nodes", "static_memory_bytes"]
const DENSE := {"seed": 4103, "sector": 1, "admiral": "vex",
	"fleet": ["penitent", "harrow", "warden", "warden"], "fac": "ithar",
	"obj": "rout", "shape": "open", "map": "storm", "dep": "line", "kind": "battle"}
const LARGE := "s4"

class ProcessClock extends Node:
	var stamp := 0
	func _process(_dt: float) -> void:
		stamp = Time.get_ticks_usec()

var first := ProcessClock.new()
var last := ProcessClock.new()
var fixture := ""
var quality := ""
var inventory := {}
var failures := 0
var storm_trace := {}
var storm_frame := 0
var hidden_break_fragments := 0
var draw_layers := {}
var draw_visibility := {}


func _ready() -> void:
	# Keep the same cold-load allowance as the original 1070 replay.
	build_wait_usec = 180_000_000
	first.process_priority = -10000
	last.process_priority = 10000
	add_child(first)
	add_child(last)
	super._ready()


func _run() -> void:
	var file := FileAccess.open(out.path_join("samples.jsonl"), FileAccess.WRITE)
	if file == null:
		push_error("Cannot open fresh samples file: " + out)
		PG.finish(1)
		return
	var vrid := get_viewport().get_viewport_rid()
	var settings := {}
	for prop in ProjectSettings.get_property_list():
		var key: String = prop.name
		if key.begins_with("rendering/") or key.begins_with("display/window/"):
			settings[key] = ProjectSettings.get_setting(key)
	file.store_line(JSON.stringify({"metrics": METRICS, "project_settings": settings,
		"adapter": RenderingServer.get_video_adapter_name(), "vulkan": RenderingServer.get_video_adapter_api_version(),
		"renderer": RenderingServer.get_current_rendering_method(), "godot": Engine.get_version_info(),
		"shield": OS.get_environment("VS_SHIELD_SHAPE"), "session": int(args.get("session", 1)),
		"source_sha256": FileAccess.get_sha256(get_script().resource_path),
		"fx_source_sha256": FileAccess.get_sha256("res://fx/fx.gd"),
		"ship_manifest_sha256": FileAccess.get_sha256("res://assets/ships/manifest.json"),
		"gen_manifest_sha256": FileAccess.get_sha256("res://gen/manifest.json")}))
	file.flush()
	var cases := str(args.get("cases", "gate:max:1:base")).split(",", false)
	for spec in cases:
		var parts := spec.split(":")
		if parts.size() != 4:
			push_error("Expected fixture:quality:scale:variant, got " + spec)
			PG.finish(1)
			return
		fixture = parts[0]
		quality = parts[1]
		if fixture not in ["gate", "dense", "large"] or quality not in ["max", "high", "low"] or parts[2] not in ["1", "2"]:
			push_error("Invalid fixture, quality, or 3D scale: " + spec)
			PG.finish(1)
			return
		var cold := str(args.get("suite", "timing")) == "cold"
		if cold:
			storm_trace = {"event": "storm_first_live", "samples": [], "started": 0, "pre_frames": 0}
			storm_frame = 0
			RenderingServer.frame_post_draw.connect(_watch_storm)
		var built := await _build(parts[3], 4207)
		if PG.stop_if_any():
			return
		if not built or failures > 0:
			push_error("Battle did not finish loading: " + spec)
			PG.finish(1)
			return
		get_viewport().scaling_3d_scale = float(parts[2])
		var changed := _switch(parts[3])
		if changed < 0:
			push_error("Unknown profiling switch: " + parts[3])
			PG.finish(1)
			return
		var row := _describe(spec, changed)
		match str(args.get("suite", "timing")):
			"shots":
				await _review(parts[3])
			"cold":
				row["events"] = await _cold(vrid)
				RenderingServer.frame_post_draw.disconnect(_watch_storm)
				row["events"].append(storm_trace)
			_:
				if parts[3] == "ship_submissions":
					row["ship_submissions"] = await _ship_submissions(vrid)
				else:
					row.merge(await _measure(vrid, parts[3]))
		file.store_line(JSON.stringify(row))
		file.flush()
		print("PERF1070 DONE ", spec, " ", row["effective"])
		if get_tree().node_added.is_connected(_hide_break_fragment):
			get_tree().node_added.disconnect(_hide_break_fragment)
		volleys_on = false
		kill_shadows = false
		if not draw_layers.is_empty() or not draw_visibility.is_empty():
			for node in draw_layers:
				if is_instance_valid(node):
					node.layers = draw_layers[node]
			for node in draw_visibility:
				if is_instance_valid(node):
					node.visible = draw_visibility[node]
			draw_layers.clear()
			draw_visibility.clear()
			for i in 3:
				await get_tree().process_frame
				await _post()
		b.queue_free()
		b = null
		for i in 6:
			await get_tree().process_frame
	file.close()
	PG.finish(0 if failures == 0 else 1)


func _build(mode: String, seed: int) -> bool:
	var vp := get_viewport()
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	vp.scaling_3d_scale = 1.0
	vp.mesh_lod_threshold = float(ProjectSettings.get_setting("rendering/mesh_lod/lod_change/threshold_pixels", 1.0)) if mode == "native_lod" else 0.0
	rng.seed = 2070 + int(args.get("session", 1)) - 1
	volley_t = 0.0
	if fixture == "gate" and quality == "max":
		var start := Time.get_ticks_usec()
		if not await super._build(mode, seed):
			return false
		build_ms = (Time.get_ticks_usec() - start) / 1000.0
		_engagement_camera()
		return true
	HULL.reset_late()
	var sc := {"seed": seed, "sector": 3, "admiral": "vex", "fleet": FLEET,
		"enemies": ENEMIES, "fac": "corsair", "obj": "rout",
		"shape": "open", "map": "storm", "dep": "line", "kind": "battle"}
	if fixture == "dense":
		sc = DENSE.duplicate(true)
	elif fixture == "large":
		var scenarios: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://rules/test/scenarios.json"))
		sc = scenarios[LARGE].duplicate(true)
	var api = API.new()
	var error: String = api.load_rules()
	if not error.is_empty():
		push_error(error)
		return false
	api.new_battle_scenario(sc, int(sc.seed))
	if fixture == "gate":
		for u in api.R.B["units"]:
			if u["side"] == "enemy":
				u["fac"] = str(api.R.HULLS[u["tpl"]].get("fac", u["fac"]))
	elif fixture == "dense":
		api.R.B.terrain = api.R.genTerrain("storm", "open", {"cond": {"terr": "neb"}})
		api.R.B.map = api.R.TERRAIN_META.duplicate(true)
	if fixture in ["gate", "dense"]:
		api.R.B["biome"] = {"rock": "ice", "planet": 7, "station": "ring"}
	b = BattleScene.instantiate()
	b.external = true
	b.args["quality"] = quality
	b.args["no-tips"] = true
	if mode == "fx_off":
		b.args["nofx"] = true
	add_child(b)
	b.tips_off = true
	b.battle_cfg = sc
	var started := Time.get_ticks_usec()
	b.begin_with(api)
	while (b.warming or b.busy) and Time.get_ticks_usec() - started < build_wait_usec:
		await get_tree().process_frame
	if b.warming or b.busy:
		return false
	build_ms = (Time.get_ticks_usec() - started) / 1000.0
	b.cam.input_enabled = false
	b.cam.keyboard_enabled = false
	b.set_process_unhandled_input(false)
	b.set_process_input(false)
	if fixture == "dense":
		b.hud.visible = false
		b.set_process(false)
		b.cam.screen_shift = 0.0
		b.cam.a = -PI / 2.0
		b.cam.b = 0.98
		b.cam.r = 170.0
		b.cam.t = b.world._terr_pts.storm[0]
	else:
		_engagement_camera()
	b.cam.snap()
	side_ids = {"player": [], "enemy": []}
	fac_of.clear()
	for u in b.V.get("units", []):
		var id := str(u["id"])
		if b.views.has(u["id"]) or b.views.has(id):
			side_ids[str(u["side"])].append(id)
			fac_of[id] = str(u["fac"])
	await get_tree().process_frame
	return true


func _engagement_camera() -> void:
	var ships := _views()
	var centre := Vector3.ZERO
	for view in ships:
		centre += view.global_position
	centre /= maxf(1.0, ships.size())
	var radius := 0.0
	for view in ships:
		radius = maxf(radius, Vector2(view.global_position.x - centre.x, view.global_position.z - centre.z).length())
	b.cam.t = Vector3(centre.x, 0, centre.z)
	b.cam.r = clampf(maxf(b.cam.r, radius * 2.0), 60.0, 900.0)
	b.cam.snap()


func _switch(variant: String) -> int:
	var vp := get_viewport()
	var fx = b.gfx
	var living = b.world._living
	var changed := 0
	match variant:
		"base", "native_lod", "fx_off", "death", "shield_hit", "shield_failure", "fragment_burst", "ship_submissions", "materials_idle":
			return 0
		"msaa_2x":
			vp.msaa_3d = Viewport.MSAA_2X
		"msaa_off":
			vp.msaa_3d = Viewport.MSAA_DISABLED
		"lod":
			vp.mesh_lod_threshold = 1.0
		"shadows_off":
			for light in b.find_children("*", "Light3D", true, false):
				if light.shadow_enabled:
					light.shadow_enabled = false
					changed += 1
		"fog_off":
			b.env.volumetric_fog_enabled = false
		"fog_64":
			RenderingServer.environment_set_volumetric_fog_volume_size(64, 128)
		"post_off":
			b.env.ssao_enabled = false
			b.env.ssil_enabled = false
			b.env.glow_enabled = false
			b.env.ssr_enabled = false
		"shields_off":
			for ship in fx.ships.values():
				if is_instance_valid(ship._shield_mi):
					_mask_draw(ship._shield_mi)
					changed += 1
		"meshes_off", "ship_shadows_off", "opaque_material", "opaque_material_idle":
			var flat := StandardMaterial3D.new()
			for sv in _views():
				for node in sv.meshes:
					if not is_instance_valid(node):
						continue
					match variant:
						"meshes_off": _mask_draw(node)
						"ship_shadows_off": node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
						"opaque_material", "opaque_material_idle": node.material_override = flat
					changed += 1
		"ship_process_off":
			for sv in _views():
				if sv.is_processing():
					sv.set_process(false)
					changed += 1
		"battle_process_off":
			b.set_process(false)
		"lights_off":
			for light in b.find_children("*", "Light3D", true, false):
				_mask_draw(light)
				_hide_draw(light)
				changed += 1
			# Dynamic pooled lights toggle visibility during the FX clock.
			for light in fx._lpool:
				if light is Light3D:
					light.light_cull_mask = 0
		"particles_off", "fragments_off":
			for key in fx.pools:
				if (key == "plate") == (variant != "particles_off"):
					_mask_draw(fx.pools[key].mi)
					changed += 1
		"death_without_fragments":
			hidden_break_fragments = 0
			get_tree().node_added.connect(_hide_break_fragment)
		"bolts_draw_off":
			for bolt in living.bolts:
				_mask_draw(bolt.mi)
				changed += 1
		"storm_off", "gas_cards_off", "dust_off":
			for node in living.get_children():
				var is_card: bool = node is MultiMeshInstance3D and living.gas_mats.any(func(g): return g[0] == node.material_override)
				var hide_node: bool = (variant == "gas_cards_off" and is_card) or (variant == "storm_off" and
					(is_card or node is FogVolume) and living.storm_mats.has(node.get("material_override") if is_card else node.get("material")))
				if hide_node or (variant == "dust_off" and str(node.name) in ["DebrisDust", "WellInfall"]):
					_hide_draw(node)
					changed += 1
			if variant == "storm_off":
				for bolt in living.bolts:
					_mask_draw(bolt.mi)
					if bolt.light != null:
						_hide_draw(bolt.light)
					changed += 1
			if variant == "dust_off":
				for node in b.world.get_children():
					if node is MultiMeshInstance3D and node.material_override is ShaderMaterial and node.material_override.shader.code == WORLD.DUST_SHADER:
						_hide_draw(node)
						changed += 1
		_:
			return -1
	return changed


func _mask_draw(node: VisualInstance3D) -> void:
	draw_layers[node] = node.layers
	node.layers = 0


func _hide_draw(node: Node3D) -> void:
	draw_visibility[node] = node.visible
	node.hide()


func _hide_break_fragment(node: Node) -> void:
	if node is Node3D and str(node.name).begins_with("fx_wreck_frag_"):
		_hide_draw(node)
		hidden_break_fragments += 1


func _describe(spec: String, changed: int) -> Dictionary:
	var vp := get_viewport()
	var env = b.env
	var size := vp.get_visible_rect().size
	var shape := {"viewport": [size.x, size.y], "3d": [size.x * vp.scaling_3d_scale, size.y * vp.scaling_3d_scale],
		"msaa_3d": vp.msaa_3d, "screen_aa": vp.screen_space_aa, "taa": vp.use_taa,
		"mesh_lod_threshold": vp.mesh_lod_threshold, "vsync": DisplayServer.window_get_vsync_mode(),
		"ssao": env.ssao_enabled, "ssil": env.ssil_enabled, "ssr": env.ssr_enabled,
		"glow": env.glow_enabled, "fog": env.volumetric_fog_enabled, "sdfgi": env.sdfgi_enabled,
		"key_shadows": b.key_light.shadow_enabled, "gas_route": b.world._living.gas_route,
		"screen_space_scaling_mode": vp.scaling_3d_mode, "quality": b.world.quality,
		"directional_shadow_atlas": 2048 if quality == "low" else 4096,
		"fog_grid": [64 if spec.ends_with(":fog_64") else 128, 128] if env.volumetric_fog_enabled else []}
	var row := {"case": spec, "build_ms": build_ms, "switch_nodes": changed, "effective": shape,
		"ships": _views().size(), "scenario": b.battle_cfg,
		"storm_hexes": b.world._terr_pts.get("storm", []).size(), "nebula_hexes": b.world._terr_pts.get("neb", []).size(),
		"reduced_flashing": b.reduce_flashing, "camera_radius": b.cam.r}
	var key := fixture + ":" + quality
	if not inventory.has(key) and str(args.get("suite", "timing")) != "shots":
		inventory[key] = true
		row["inventory"] = _scene_stats()
		var living = b.world._living
		var gas_cards := 0
		var fog_volumes := 0
		for node in living.get_children():
			if node is FogVolume:
				fog_volumes += 1
			elif node is MultiMeshInstance3D and living.gas_mats.any(func(g): return g[0] == node.material_override):
				gas_cards += node.multimesh.instance_count
		row["weather_geometry"] = {"gas_cards": gas_cards, "fog_volumes": fog_volumes, "bolts": living.bolts.size()}
		row["shield_geometry"] = []
		if b.gfx != null:
			for ship in b.gfx.ships.values():
				if is_instance_valid(ship._shield_mi) and ship._shield_mi.mesh != null:
					row["shield_geometry"].append({"id": ship.id, "code": ship.hull.code,
						"fitted": ship._shield_tm != null, "triangles": _tris(ship._shield_mi.mesh, 0)})
	return row


func _draw_counts(vrid: RID) -> Vector2i:
	for i in 6:
		await get_tree().process_frame
		await _post()
	return Vector2i(RenderingServer.viewport_get_render_info(vrid, 0, 2),
		RenderingServer.viewport_get_render_info(vrid, 1, 2))


func _ship_submissions(vrid: RID) -> Array:
	# Compare actual viewport submissions while removing just one hull. Keep
	# HUD and effects from animating so they do not change the draw-count delta.
	b.gfx.manual = true
	b.set_process(false)
	b.world._living.set_process(false)
	for view in _views():
		view.set_process(false)
	var rows := []
	for id in b.views:
		var view = b.views[id]
		if not is_instance_valid(view) or not is_instance_valid(view.hull):
			continue
		var before := await _draw_counts(vrid)
		var layers := {}
		for mesh in view.meshes:
			if is_instance_valid(mesh):
				layers[mesh] = mesh.layers
				mesh.layers = 0
		var without := await _draw_counts(vrid)
		for mesh in layers:
			mesh.layers = layers[mesh]
		var after := await _draw_counts(vrid)
		rows.append({"id": str(id), "code": view.code, "visible_draws_removed": before.x - without.x,
			"shadow_draws_removed": before.y - without.y, "before": [before.x, before.y],
			"without": [without.x, without.y], "after": [after.x, after.y], "stable": before == after})
	return rows


func _sample(vrid: RID, elapsed: int) -> Array:
	return [elapsed / 1000.0, (last.stamp - first.stamp) / 1000.0,
		RenderingServer.viewport_get_measured_render_time_cpu(vrid), RenderingServer.viewport_get_measured_render_time_gpu(vrid),
		RenderingServer.viewport_get_render_info(vrid, 0, 2), RenderingServer.viewport_get_render_info(vrid, 1, 2),
		RenderingServer.viewport_get_render_info(vrid, 0, 0), RenderingServer.viewport_get_render_info(vrid, 1, 0),
		RenderingServer.viewport_get_render_info(vrid, 0, 1), RenderingServer.viewport_get_render_info(vrid, 1, 1),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), Performance.get_monitor(Performance.OBJECT_COUNT),
		Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT), Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.MEMORY_STATIC)]


func _measure(vrid: RID, variant: String) -> Dictionary:
	var start := Time.get_ticks_usec()
	volleys_on = fixture != "dense" and b.gfx != null and variant not in ["materials_idle", "opaque_material_idle"]
	var dry := DisplayServer.get_name() == "headless"
	while not dry and Time.get_ticks_usec() - start < 2500000:
		await get_tree().process_frame
	for i in int(args.get("warmup", 180)):
		await get_tree().process_frame
	var fx = b.gfx
	var profiling := args.has("profile") and EngineDebugger.is_active()
	if args.has("profile") and not profiling:
		push_error("Godot profiler needs the local debugger (-d).")
		failures += 1
	if fx != null:
		fx.prof_take()
	var fragments_before: int = fx.pools["plate"].emitted if fx != null else 0
	var pipes_before := _pipes()
	if profiling:
		print("PERF1070 GODOT SCRIPT PROFILER BEGIN")
		EngineDebugger.profiler_enable("scripts", true)
	var samples := []
	var events := []
	var fx_trace := []
	await _post()
	start = Time.get_ticks_usec()
	var previous := start
	while samples.size() < int(args.get("frames", 720)) or Time.get_ticks_usec() - start < int(args.get("min-us", 8000000)):
		var index := samples.size()
		if index in [72, 144, 216, 288, 360, 432]:
			var event := "death" if variant == "death_without_fragments" else variant
			if event in ["death", "shield_hit", "shield_failure", "fragment_burst"]:
				events.append([index, _event(event, index / 72 - 1)])
		await get_tree().process_frame
		await _post()
		var now := Time.get_ticks_usec()
		samples.append(_sample(vrid, now - previous))
		previous = now
		if profiling and fx != null:
			fx_trace.append(fx.prof_take())
		vol_looks.clear()
	if profiling:
		EngineDebugger.profiler_enable("scripts", false)
		print("PERF1070 GODOT SCRIPT PROFILER END")
	return {"samples": samples, "events": events, "seconds": (previous - start) / 1000000.0,
		"fx_us": fx.prof_take() if fx != null else {}, "volleys": fx.stats.volleys if fx != null else 0,
		"pipeline_before": pipes_before, "pipeline_after": _pipes(), "late_shaders": HULL.late_shader_names(),
		"fx_profile_by_frame_us": fx_trace,
		"impact_fragments_emitted": fx.pools["plate"].emitted - fragments_before if fx != null else 0,
		"hidden_break_fragments": hidden_break_fragments if variant == "death_without_fragments" else 0}


func _event(event: String, index: int) -> String:
	var fx = b.gfx
	var ids: Array = side_ids.player
	var id: String = ids[index % ids.size()]
	var ship = fx.ship(id)
	match event:
		"shield_hit":
			var aim: Vector3 = ship.to_world(ship.hull.shield_centre() + Vector3(0, 20, 0))
			var contact: Dictionary = ship.shield_point(aim)
			ship.shield_hit(fx, contact.local, fx.now, 1.0, 3.0)
		"shield_failure":
			fx.shield_break(id, 0)
		"death":
			fx.death(id, "big")
			ids.erase(id)
		"fragment_burst":
			var attacker: String = side_ids.enemy[0]
			fx.volley(attacker, "battery", id, {"weapon_id": LOOKS[fac_of[attacker]][0][1],
				"shots": [true, true, true], "hits": [{"hull": 40, "section": "mid"}, {"hull": 40, "section": "mid"}, {"hull": 40, "section": "mid"}]})
	return id


func _watch_storm() -> void:
	var now := Time.get_ticks_usec()
	var previous := storm_frame
	storm_frame = now
	if b == null or not is_instance_valid(b.world) or not is_instance_valid(b.world._living) or previous == 0:
		return
	var living = b.world._living
	var frames: Array = storm_trace.samples
	if int(storm_trace.started) == 0:
		for bolt in living.bolts:
			if float(bolt.start) >= 0 and living.clock > float(bolt.start):
				storm_trace.started = now
				storm_trace.pre_frames = frames.size()
				storm_trace.loading = b.warming
				storm_trace.storm_clock = living.clock
				storm_trace.pipe_before = _pipes()
				break
	if int(storm_trace.started) > 0 and now - int(storm_trace.started) >= 650000:
		return
	frames.append(_sample(get_viewport().get_viewport_rid(), now - previous))
	if int(storm_trace.started) == 0 and frames.size() > 16:
		frames.pop_front()
	if int(storm_trace.started) > 0:
		storm_trace.pipe_after = _pipes()


func _cold(vrid: RID) -> Array:
	var events := []
	var fx = b.gfx
	if fixture == "dense":
		# The dense case reproduces the prior storm timing fixture's idle flight.
		var weather_start := Time.get_ticks_usec()
		while (int(storm_trace.started) == 0 or Time.get_ticks_usec() - int(storm_trace.started) < 650000) and Time.get_ticks_usec() - weather_start < 8000000:
			await get_tree().process_frame
		return events
	for event in ["shield_hit", "shield_failure", "fragment_burst", "death"]:
		var samples := []
		var fx_trace := []
		var pipes_before := _pipes()
		var fragments_before: int = fx.pools["plate"].emitted
		var original_wrecks: int = fx.dstate.wrecks.size()
		var first_fragment := -1
		var first_wreck := -1
		await _post()
		fx.prof_take()
		var start := Time.get_ticks_usec()
		var previous := start
		var target := _event(event, 0)
		while Time.get_ticks_usec() - start < (6500000 if event == "death" else 2300000):
			await get_tree().process_frame
			await _post()
			var now := Time.get_ticks_usec()
			if first_fragment < 0 and fx.pools["plate"].emitted > fragments_before:
				first_fragment = samples.size()
			if first_wreck < 0 and fx.dstate.wrecks.size() > original_wrecks:
				first_wreck = samples.size()
			samples.append(_sample(vrid, now - previous))
			previous = now
			fx_trace.append(fx.prof_take())
		events.append({"event": event, "target": target, "samples": samples, "pipe_before": pipes_before,
			"pipe_after": _pipes(), "fragments_emitted": fx.pools["plate"].emitted - fragments_before,
			"first_fragment_frame": first_fragment, "first_wreck_frame": first_wreck,
			"wrecks_added": fx.dstate.wrecks.size() - original_wrecks, "fx_profile_by_frame_us": fx_trace})
	return events


func _review(variant: String) -> void:
	var fx = b.gfx
	var ship = fx.ship(side_ids.player[0])
	fx.manual = true
	fx.rng.seed = 2070
	b.set_process(false)
	for view in _views():
		view.set_process(false)
		if view.squad_kind.is_empty():
			view.hull.position = view.hull_base
	var living = b.world._living
	living.set_process(false)
	living.clock = 0.08
	for burst in living._storm_bursts:
		burst.next = 1000.0
	for bolt in living.bolts:
		bolt.start = -10.0
	b.cam.t = ship.root.global_position if fixture != "dense" else b.world._terr_pts.storm[0]
	if fixture == "dense":
		var nearest = living.bolts[0]
		for bolt in living.bolts:
			if bolt.pos.distance_to(b.cam.t) < nearest.pos.distance_to(b.cam.t):
				nearest = bolt
		nearest.start = living.clock - 0.025
	living._process(0.0)
	b.cam.screen_shift = 0.0
	for radius in [170, 26]:
		b.cam.r = radius
		b.cam.snap()
		_event("shield_hit", 0)
		for i in 20:
			fx.step(1.0 / 60.0)
			await get_tree().process_frame
		await _post()
		var image := get_viewport().get_texture().get_image()
		var name := "PERF1070_%s_%s_c%d.png" % [fixture, variant, radius]
		if image == null or image.is_empty() or STAMP.save_png(image, out.path_join(name), STAMP.capture_stage()) != OK:
			failures += 1
