extends SceneTree
# Refs #975. Installed art, production lighting/camera and a real fitted cruiser.
const API = preload("res://rules/battle_api.gd")
const SV = preload("res://render/ship_view.gd")
const CAM = preload("res://render/camera_rig.gd")
const LOOK = preload("res://render/look.gd")
const PROPS = preload("res://assets/ships/a4_props.gd")
const PG = preload("res://render/placeholder_guard.gd")
const PROBE = preload("inspect.gd")

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2: quit(1); return
	var out := args[0]
	if RenderingServer.get_current_rendering_method() != "forward_plus": quit(1); return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("080c12")
	world.add_child(env)
	var key := DirectionalLight3D.new()
	world.add_child(key)
	key.look_at(LOOK.KEY_DIR)
	var fill := DirectionalLight3D.new()
	world.add_child(fill)
	fill.look_at(LOOK.FILL_DIR)
	LOOK.apply(env.environment, key, fill)
	var station := PROPS.station(46.0)
	if station == null or not station.has_meta("station_T2"):
		printerr("T2 capture requires the installed production station"); quit(1); return
	world.add_child(station)
	for player in station.find_children("*", "AnimationPlayer", true, false): player.pause()
	var api = API.new()
	var error: String = api.load_rules()
	if error != "": printerr(error); quit(1); return
	api.new_battle_scenario({"seed": 975, "sector": 3, "admiral": "vex", "fleet": ["harrow"],
		"enemies": ["c_marauder"], "fac": "corsair", "obj": "rout", "shape": "open",
		"map": "station", "dep": "line", "kind": "battle"}, 975)
	var unit := {}
	for row in api.view().units:
		if row.cls == "Cruiser" and row.fac == "corsair": unit = row; break
	if unit.is_empty(): printerr("No real cruiser in comparison scenario"); quit(1); return
	var cruiser := SV.new()
	world.add_child(cruiser)
	cruiser.setup(unit, Vector3.ZERO)
	if PG.stop_if_any(): return
	cruiser.set_process(false)
	cruiser.rotation.y = 0
	if cruiser.ring: cruiser.ring.visible = false
	var camera := CAM.new()
	world.add_child(camera)
	camera.set_process(false)
	camera.input_enabled = false
	camera.current = true
	var report := {"stage": "installed in game", "capture_resolution": [1920,1080],
		"closest_radius": camera.min_r, "station_cache": "res://gen/ships/station_T2.scn",
		"cruiser_code": cruiser.code, "cruiser_length": cruiser.L, "views": []}
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[1].path_join("production_manifest.json")))
	if not manifest.has("drums") or not manifest.has("light_clusters"):
		printerr("Production manifest lacks authored capture targets; rerun stage 5"); quit(1); return
	var scale_factor: float = manifest.uniform_scale
	var arrays_target := Vector3.ZERO
	for detail in manifest.details:
		if detail.kind == "dish_array":
			var low: Array = detail.min
			var high: Array = detail.max
			arrays_target = Vector3((low[0]+high[0])*0.5,(low[2]+high[2])*0.5,-(low[1]+high[1])*0.5)*scale_factor
			break
	if arrays_target == Vector3.ZERO:
		printerr("Missing measured dish-array target"); quit(1); return
	var habitat_target := Vector3.ZERO
	var habitat_alpha := -0.61
	for cluster in manifest.light_clusters:
		if cluster.kind == "core" and int(cluster.deck) == 5:
			var drum: Dictionary = manifest.drums[int(cluster.deck)]
			var angle := deg_to_rad(float(cluster.angle))
			habitat_alpha = angle - deg_to_rad(40)
			habitat_target = Vector3((float(drum.radius)+0.11)*cos(angle),
				float(drum.bottom)+float(drum.height)*0.74,-(float(drum.radius)+0.11)*sin(angle))*scale_factor
	if habitat_target == Vector3.ZERO:
		printerr("Missing authored habitat light cluster"); quit(1); return
	var views := [
		{"name":"station_T2_camera170", "radius":170.0, "alpha":-2.08, "target":Vector3(14,4,0)},
		{"name":"station_T2_camera60", "radius":60.0, "alpha":-2.08, "target":Vector3(0,10,5)},
		{"name":"station_T2_closest_docking", "radius":camera.min_r, "alpha":-2.08, "target":Vector3(-24,2,0)*scale_factor},
		{"name":"station_T2_closest_habitat", "radius":camera.min_r, "alpha":habitat_alpha, "target":habitat_target},
		{"name":"station_T2_closest_arrays", "radius":camera.min_r, "alpha":-0.8, "target":arrays_target}]
	var tower: Dictionary = manifest.towers[0]
	views.append({"name":"station_T2_closest_tall_tower", "radius":camera.min_r, "alpha":-2.08,
		"target":Vector3(float(tower.x),float(tower.base)+float(tower.height)*0.65,-float(tower.y))*scale_factor})
	var top_drum: Dictionary = manifest.drums[-1]
	var top_angle := deg_to_rad(-70.0)
	views.append({"name":"station_T2_closest_top_deck", "radius":camera.min_r, "alpha":-2.08,
		"target":Vector3(float(top_drum.radius)*cos(top_angle),float(top_drum.bottom)+float(top_drum.height)*0.82,
			-float(top_drum.radius)*sin(top_angle))*scale_factor})
	for view in views:
		camera.r = view.radius
		camera.a = view.alpha
		camera.b = float(view.get("beta", 0.98))
		camera.t = view.target
		camera.snap()
		var right := camera.global_basis.x
		if camera.r == camera.min_r:
			# Same depth plane: both objects have the same pixels per world unit.
			camera.t = view.target + right * 3
			cruiser.position = view.target + right * 27
		else:
			cruiser.position = Vector3(65, 0, 0) if camera.r == 170 else view.target + right * 28
		camera.snap()
		for i in 60: await process_frame
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		# Native 1080p source lives in TEMP. Review compositor makes 1:1 crops.
		if preload("res://tools/picture_provenance.gd").save_png(image, out.path_join(view.name + ".png"), preload("res://tools/picture_provenance.gd").capture_stage()) != OK:
			quit(1); return
		var draw_calls := RenderingServer.viewport_get_render_info(viewport.get_viewport_rid(), 0, 2)
		station.visible = false
		for i in 5: await process_frame
		await RenderingServer.frame_post_draw
		var without_station := RenderingServer.viewport_get_render_info(viewport.get_viewport_rid(), 0, 2)
		station.visible = true
		report.views.append({"name":view.name,"radius":camera.r,"alpha":camera.a,"beta":camera.b,"fov":camera.fov,
			"cruiser_depth_offset":(cruiser.position-view.target).dot(camera.global_basis.z),
			"target":[camera.t.x,camera.t.y,camera.t.z],
			"visible_draw_calls":draw_calls,"station_draw_call_delta":draw_calls-without_station,
			"cruiser_position":[cruiser.position.x,cruiser.position.y,cruiser.position.z],
			"station_bounds_pixels":bounds(camera, PROBE.mesh_bounds(station,world)),
			"cruiser_bounds_pixels":bounds(camera, PROBE.mesh_bounds(cruiser.hull,world))})
		print("T2 PRODUCTION CAPTURE ", view.name)
	var file := FileAccess.open(out.path_join("production_captures.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t") + "\n")
	quit(0)

func bounds(camera: Camera3D, box: AABB) -> Array:
	var low := Vector2(INF,INF)
	var high := Vector2(-INF,-INF)
	for i in 8:
		var pixel := camera.unproject_position(box.get_endpoint(i))
		low = low.min(pixel)
		high = high.max(pixel)
	return [low.x,low.y,high.x,high.y]
