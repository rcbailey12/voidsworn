extends "res://bench/look_bench.gd"
# Issue 372. Uses the standing bench's view, real hulls, camera and effect clock.
# Units, coverage, routing and depletion come from BattleAPI, never a typed unit.
# --out DIR --label before|after [--state-only]
const RULES_API := preload("res://rules/battle_api.gd")
const CASES := [["voidsworn", "reliquary"], ["hegemony", "h_interdictor"],
	["corsair", "c_marauder"], ["ithar", "i_song"]]
var api
var unit: Dictionary
var enemy: Dictionary
var evidence := {"states": [], "captures": []}
var failed := 0

func _check(ok: bool, what: String) -> void:
	if not ok:
		failed += 1
		printerr("SHIELD_BENCH FAIL: ", what)

func _run() -> void:
	_setup_view()
	api = RULES_API.new()
	_check(api.load_rules() == "", "rules load")
	headless = DisplayServer.get_name() == "headless"
	if args.has("bursts"):
		cfg = JSON.parse_string(FileAccess.get_file_as_string(str(args["bursts"])))
		# Reuse the production standing-bench moment driver and lighting, without
		# loading its unrelated sky/rock caches into this shield isolation scene.
		var cell := Vector2i(int(cfg["cell"][0]), int(cfg["cell"][1]))
		var directory := out.path_join("moments")
		DirAccess.make_dir_recursive_absolute(directory)
		for row in cfg["rows"]:
			await _moment(row, 170.0, cell, cell, directory, false)
		for row in cfg["rows"]:
			for radius in cfg["cameras"]:
				var crop: Array = cfg["crop"][str(int(radius))]
				await _moment(row, float(radius), Vector2i(int(crop[0]), int(crop[1])), cell, directory)
		_check(report["stills"].size() == 6, "two production hit moments at all three cameras")
		_save_report()
		_clear()
		# Release the live nodes before their shared caches and the render server.
		world.queue_free()
		for n in 4: await get_tree().process_frame
		fx = null
		wld = null
		FX.clear_static()
		SV.clear_static()
		for n in 4: await get_tree().process_frame
		print("SHIELD_BURSTS_DONE failures=", failed)
		get_tree().quit(1 if failed else 0)
		return
	if args.has("stress"):
		await _stress()
		get_tree().quit(failed)
		return
	for item in CASES:
		_clear()
		_make_fx()
		fx.quality = str(args.get("quality", "max"))
		api.new_battle_scenario({"seed": 372, "admiral": "vex", "fac_player": item[0], "fleet": [item[1]],
			"fac": "hegemony", "enemies": ["h_interdictor"], "obj": "rout", "shape": "open", "map": "open",
			"dep": "line", "kind": "battle", "sector": 1})
		for u in api.R.B["units"]:
			if api.R.jt(u.get("isSq")):
				continue
			if u["side"] == "player": unit = u
			else: enemy = u
		T = SV.new()
		T.name = "ship_T"
		world.add_child(T)
		T.setup(unit, Vector3.ZERO, true)
		T.set_process(false)
		if _is_block(T):
			_placeholder(str(item[0]) + " missing real hull")
			return
		fx.add_ship("T", T, {"faction": item[0], "cls": unit["cls"], "meshes": T.meshes, "size": 1.0})
		_sync_view("T", unit)
		var s = fx.ship("T")
		var initial_pool: float = unit["shp"]
		var hit: Dictionary = api.R.applyHit(enemy, enemy["weapons"][0], unit, 4.0, 0)
		_sync_view("T", unit)
		_check(float(unit["shp"]) < initial_pool, str(item[0]) + " real hit drains pool")
		evidence["states"].append({"faction": item[0], "code": T.code, "pool_before": initial_pool,
			"pool_after": unit["shp"], "coverage": unit["cov"], "catches": unit["sh"], "hit": hit})
		if not headless and not args.has("state-only"):
			await _captures(s, str(item[0]))
			if "_shield_levels" in s:
				await _cap_capture(s, str(item[0]))
		# The real hit path empties the universal pool. All sides must go dark together.
		for n in 512:
			if float(unit["shp"]) == 0.0: break
			api.R.applyHit(enemy, enemy["weapons"][0], unit, 1.0, 0)
		_sync_view("T", unit)
		_check(float(unit["shp"]) == 0.0, str(item[0]) + " pool depleted by hits")
		if "_shield_levels" in s:
			_check(s._shield_levels == Vector4.ZERO, str(item[0]) + " depleted pool opens every side")
			_check(s._shield_mat.get_shader_parameter("levels") == Vector4.ZERO, "real state reaches shader")
			for n in 3: api.R.startSideTurn("player")
			_sync_view("T", unit)
			_check(float(unit["shp"]) > 0.0 and s._shield_levels.length() > 0.0, "real turn regen closes rim")
		if not headless and not args.has("state-only"):
			_cam(Vector3.ZERO, 170.0)
			await _draw()
			_save_crop(str(item[0]) + "_regenerated", _grab())
	_clear()
	var file := FileAccess.open(out.path_join("shield_bench.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence, " ") + "\n")
	file.close()
	print("SHIELD_BENCH_DONE failures=", failed, " real faction states=", evidence["states"].size())
	get_tree().quit(1 if failed else 0)

func _sync_view(sid: String, state: Dictionary) -> void:
	# The renderer receives BattleAPI.view(), not the mutable rules dictionary.
	for shown in api.view()["units"]:
		if str(shown["id"]) == str(state["id"]):
			fx.sync_ship(sid, shown)
			return
	_check(false, "unit missing from real battle view")


func _draw() -> void:
	# Hold the production effect clock across A/B material toggles.
	for n in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw

func _save_crop(name: String, img: Image) -> void:
	if img != null:
		img.get_region(Rect2i(640, 300, 640, 480)).save_png(out.path_join(name + ".png"))

func _captures(s, faction_name: String) -> void:
	var bend = s._shield_mi if "_shield_levels" in s else null
	for radius in [170, 60, 26]:
		_cam(Vector3.ZERO, float(radius))
		fx.now = 2.0
		RenderingServer.global_shader_parameter_set(&"scene_t", fx.now)
		s._shield_until = -1.0
		# A high-frequency opaque chart behind the actual hull makes displacement measurable.
		var chart := MeshInstance3D.new()
		chart.mesh = PlaneMesh.new()
		chart.mesh.size = Vector2(70, 50)
		chart.position = Vector3(0, -3.0, 0)
		var chart_mat := ShaderMaterial.new()
		chart_mat.shader = Shader.new()
		chart_mat.shader.code = "shader_type spatial; render_mode unshaded; void fragment() { float c = mod(floor(UV.x * 140.0) + floor(UV.y * 100.0), 2.0); ALBEDO = mix(vec3(0.008,0.012,0.02),vec3(0.10,0.14,0.18),c); }"
		chart.material_override = chart_mat
		chart.visible = false
		world.add_child(chart)
		# Clear previous hits via their production slots, then let the real update show resting rims.
		for i in s._hits.size(): s._hits[i].w = -100.0
		s._shield_mat.set_shader_parameter("hits", s._hits)
		if bend != null: s._shield_mat.set_shader_parameter("hits", s._hits)
		s.update(fx, 0.0)
		await _draw()
		var resting := _grab()
		s._shield_mi.visible = false
		if bend != null: bend.visible = false
		await _draw()
		_save_crop("%s_c%d_off" % [faction_name, radius], _grab())
		var old_materials := []
		var white := StandardMaterial3D.new()
		white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		white.albedo_color = Color.WHITE
		for mesh in T.meshes:
			old_materials.append(mesh.material_override)
			mesh.material_override = white
		await _draw()
		_save_crop("%s_c%d_hull_mask" % [faction_name, radius], _grab())
		for n in T.meshes.size(): T.meshes[n].material_override = old_materials[n]
		var point: Dictionary = s.shield_point(cam.global_position + Vector3(3, 0, 0), s.hull.c)
		s.shield_hit(fx, point["local"], 2.0, 2.0, s.hull.L * 0.3, 0.7)
		var strip := Image.create_empty(384 * 8, 216, false, Image.FORMAT_RGB8)
		var crop := Vector2i(384, 216) * (1 if radius == 170 else (2 if radius == 60 else 3))
		strip.blit_rect(_crop(resting, crop, Vector2i(384, 216)), Rect2i(0, 0, 384, 216), Vector2i.ZERO)
		var times := [0.03, 0.08, 0.16, 0.26, 0.42, 0.65, 1.0]
		for i in times.size():
			fx.now = 2.0 + times[i]
			RenderingServer.global_shader_parameter_set(&"scene_t", fx.now)
			s.update(fx, 0.0)
			await _draw()
			var im := _grab()
			strip.blit_rect(_crop(im, crop, Vector2i(384, 216)), Rect2i(0, 0, 384, 216), Vector2i((i + 1) * 384, 0))
			if i == 2:
				_save_crop("%s_c%d_lit" % [faction_name, radius], im)
				# Paired readability must hold the effect clock too: engine pilot glows
				# otherwise change between the pre-hit still and the lit still.
				s._shield_mi.visible = false
				await _draw()
				_save_crop("%s_c%d_off" % [faction_name, radius], _grab())
				s._shield_mi.visible = true
				if bend != null:
					chart.visible = true
					await _draw()
					_save_crop("%s_c%d_diagnostic" % [faction_name, radius], _grab())
					s._shield_mat.set_shader_parameter("bend_gain", 0.0)
					await _draw()
					_save_crop("%s_c%d_no_bend" % [faction_name, radius], _grab())
					s._shield_mat.set_shader_parameter("bend_gain", 1.0)
					s._shield_mat.set_shader_parameter("contact_gain", 0.0)
					await _draw()
					_save_crop("%s_c%d_no_contact" % [faction_name, radius], _grab())
					s._shield_mat.set_shader_parameter("contact_gain", 1.0)
					var original_shader: Shader = s._shield_mat.shader
					var plain := Shader.new()
					plain.code = original_shader.code.replace("faction_mask(vL)", "0.0")
					s._shield_mat.shader = plain
					await _draw()
					_save_crop("%s_c%d_no_pattern" % [faction_name, radius], _grab())
					s._shield_mat.shader = original_shader
					if radius == 60:
						var rock = load("res://world/rocks/frag_00.glb").instantiate()
						world.add_child(rock)
						rock.global_position = point["p"] - point["n"] * 0.15
						rock.scale = Vector3.ONE * 0.5
						await _draw()
						_save_crop(faction_name + "_rock_contact", _grab())
						s._shield_mat.set_shader_parameter("contact_gain", 0.0)
						await _draw()
						_save_crop(faction_name + "_rock_no_contact", _grab())
						s._shield_mat.set_shader_parameter("contact_gain", 1.0)
						rock.queue_free()
					chart.visible = false
					await _draw()
		strip.save_png(out.path_join("%s_c%d_strip.png" % [faction_name, radius]))
		evidence["captures"].append({"faction": faction_name, "code": T.code, "camera": radius, "times": [0.0] + times,
			"point": str(point["local"]), "hit_pixel": [cam.unproject_position(point["p"]).x - 640, cam.unproject_position(point["p"]).y - 300],
			"hull_length": s.hull.L, "surface_vertices": s._shield_mi.mesh.get_faces().size()})
		chart.queue_free()
		await get_tree().process_frame


func _cap_capture(s, faction_name: String) -> void:
	# Measure the actual production shader in a linear, unlit black scene, after
	# its tint, gain and six overlapping hits. Exposure is 0.25 to avoid clipping;
	# the shader-written reference below uses the same pipeline and exposure.
	_cam(Vector3.ZERO, 60.0)
	var we: WorldEnvironment
	for child in world.get_children():
		if child is WorldEnvironment: we = child
	var previous := we.environment
	var linear: Environment = previous.duplicate()
	linear.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	linear.tonemap_exposure = 0.25
	linear.glow_enabled = false
	linear.adjustment_enabled = false
	linear.background_mode = Environment.BG_COLOR
	linear.background_color = Color.BLACK
	we.environment = linear
	var materials := []
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	for mesh in T.meshes:
		materials.append(mesh.material_override)
		mesh.material_override = black
	if s._eng_node != null: s._eng_node.visible = false
	for trail in s._trails: trail["mi"].visible = false
	fx.now = 10.0
	var p: Dictionary = s.shield_point(cam.global_position, s.hull.c)
	for n in 6: s.shield_hit(fx, p["local"], 9.92, 100.0, s.hull.L, 1.0)
	RenderingServer.global_shader_parameter_set(&"scene_t", fx.now)
	s.update(fx, 0.0)
	s._shield_mat.set_shader_parameter("col", Vector3.ONE * 1000.0)
	s._shield_mat.set_shader_parameter("edge_col", Vector3.ONE * 1000.0)
	await _draw()
	_save_crop(faction_name + "_linear_cap_stress", _grab())
	# Same exposure and pipeline, with a known shader-written 0.65 linear reference.
	# A shader avoids the UI colour conversion used by Environment.background_color.
	s._shield_mi.visible = false
	var reference := MeshInstance3D.new()
	reference.mesh = QuadMesh.new()
	reference.mesh.size = Vector2(100, 100)
	var refmat := ShaderMaterial.new()
	refmat.shader = Shader.new()
	refmat.shader.code = "shader_type spatial; render_mode unshaded; void fragment() { ALBEDO = vec3(0.65); }"
	reference.material_override = refmat
	world.add_child(reference)
	reference.global_transform = cam.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 0, -2))
	await _draw()
	_save_crop(faction_name + "_linear_cap_reference", _grab())
	reference.queue_free()
	for n in T.meshes.size(): T.meshes[n].material_override = materials[n]
	if s._eng_node != null: s._eng_node.visible = true
	for trail in s._trails: trail["mi"].visible = true
	we.environment = previous
	s._shield_material(s._shield_mat)


func _stress() -> void:
	# Additional isolation, not a replacement for the complete #207 scene gate.
	var fleet := []
	for n in 20: fleet.append("reliquary")
	api.new_battle_scenario({"seed": 372, "admiral": "vex", "fac_player": "voidsworn", "fleet": fleet,
		"fac": "hegemony", "enemies": ["h_interdictor"], "obj": "rout", "shape": "open", "map": "open",
		"dep": "line", "kind": "battle", "sector": 1})
	var index := 0
	for u in api.R.B["units"]:
		if u["side"] != "player" or api.R.jt(u.get("isSq")): continue
		var sv = SV.new()
		sv.name = "ship_%d" % index
		world.add_child(sv)
		sv.setup(u, Vector3((index % 5 - 2) * 24.0, 0, (index / 5 - 1.5) * 22.0), true)
		sv.set_process(false)
		if _is_block(sv):
			_placeholder("stress missing hull " + str(sv.code))
			return
		var sid := str(index)
		fx.add_ship(sid, sv, {"faction": "voidsworn", "cls": u["cls"], "meshes": sv.meshes, "size": 1.0})
		_sync_view(sid, u)
		index += 1
	_check(index == 20, "stress uses 20 real shielded units")
	_cam(Vector3.ZERO, 170.0)
	var rid := vp.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var result := {"ships": index, "rows": []}
	for scale in [1.0, 2.0]:
		vp.scaling_3d_scale = scale
		for mode in ["rest", "hit"]:
			var gpu := []
			var frames := []
			var previous := Time.get_ticks_usec()
			for frame in 600:
				if mode == "hit" and frame % 18 == 0:
					for sid in fx.ships:
						var s = fx.ship(sid)
						var p: Dictionary = s.shield_point(cam.global_position, s.hull.c)
						s.shield_hit(fx, p["local"], fx.now, 2.0, s.hull.L * 0.3, 0.7)
				fx.step(STEP)
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				var now := Time.get_ticks_usec()
				if frame >= 120:
					frames.append((now - previous) / 1000.0)
					gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
				previous = now
			gpu.sort()
			frames.sort()
			result["rows"].append({"mode": mode, "pixels": "1080p" if scale == 1.0 else "4K",
				"gpu_median": gpu[gpu.size() / 2], "frame_median": frames[frames.size() / 2]})
			var im := _grab()
			im.resize(1152, 648, Image.INTERPOLATE_LANCZOS)
			im.save_png(out.path_join("stress_%s_%d.png" % [mode, int(scale)]))
	var file := FileAccess.open(out.path_join("stress.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, " ") + "\n")
	file.close()
	print("SHIELD_STRESS ", JSON.stringify(result))
	_clear()
