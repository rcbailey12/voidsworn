extends Node3D

const BATTLE := preload("res://scenes/battle/battle.tscn")
const WORLD := preload("res://world/world.gd")
const SKY := preload("res://world/world_sky.gd")
const BAKER := preload("res://world/world_bake.gd")
const SHIP := preload("res://render/ship_view.gd")
const LIGHTING := preload("probe_lighting.gd")
const SHIPS := [["I8_37", "ithar", "Ark"], ["C19_51", "corsair", "Battle-barge"],
	["B21_11", "chorus", "Cruiser"]]

var battle: Node3D
var render := SubViewport.new()
var lighting := LIGHTING.new()
var output := ""


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or not args[0].is_absolute_path():
		_fail("Pass an absolute scratch folder after --")
		return
	output = args[0]
	var setups := LIGHTING.SETUPS if args.size() == 1 else Array(args).slice(1)
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		_fail("Could not create capture folder")
		return
	AudioServer.set_bus_mute(0, true)
	render.size = Vector2i(1920, 1080)
	render.own_world_3d = true
	render.mesh_lod_threshold = 0.0
	render.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(render)
	battle = BATTLE.instantiate()
	battle.external = true
	battle.showcase = true
	battle.args["nofx"] = true
	render.add_child(battle)
	battle.set_process(false)
	_pose(170.0, 0)
	var world := WORLD.new()
	battle.add_child(world)
	world.quality = "max"
	world.setting = SKY.setting({"rock": "carbon", "planet": 5}, "corsair", "open", true, 7)
	world._yaw = float(world.setting["yaw"])
	world._pano = (battle.env.sky.sky_material as ShaderMaterial).get_shader_parameter("pano")
	world._baker = BAKER.service(get_tree())
	world._make_sky(battle.env)
	var deadline := Time.get_ticks_msec() + 120000
	while world.pending_bakes > 0 and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if world.pending_bakes > 0 or world._sky_tex == null or not lighting.prepare(battle, battle.env, battle.cam):
		_fail("Could not prepare the battle nebula and lights")
		return
	for setup: String in setups:
		if not lighting.apply(setup):
			_fail("Invalid lighting setup " + setup)
			return
		for side in [0, 1]:
			_pose(170.0, side)
			if not await _save("sky_%s_s%d.png" % [setup, side]):
				return
		for spec in SHIPS:
			var ship := SHIP.new()
			battle.add_child(ship)
			ship.setup({"id": spec[0], "code": spec[0], "fac": spec[1], "cls": spec[2],
				"facing": 0, "hp": 100, "maxHp": 100}, Vector3.ZERO, true)
			ship.set_process(false)
			if not ship.a4:
				_fail("Expected isolated A4 build for " + str(spec[0]))
				return
			var materials: Array[ShaderMaterial] = []
			if ship.code == "I8_37":
				materials = lighting.apply_glass(ship)
				if materials.size() != 5:
					_fail("Expected five run 4 glass surfaces")
					return
			for radius in [170, 26]:
				for side in [0, 1]:
					_pose(float(radius), side)
					lighting.aim(materials)
					if not await _save("%s_%s_r%d_s%d.png" % [spec[0], setup, radius, side]):
						return
			battle.remove_child(ship)
			ship.queue_free()
		if not await _reference(setup):
			return
		print("Glass lighting capture complete: ", setup)
	get_tree().quit()


func _pose(radius: float, side: int) -> void:
	battle.cam.a = -PI / 2.0 + side * PI
	battle.cam.b = 0.98
	battle.cam.r = radius
	battle.cam.t = Vector3.ZERO
	battle.cam.screen_shift = 0.0
	battle.cam.input_enabled = false
	battle.cam.keyboard_enabled = false
	battle.cam.snap()


func _reference(setup: String) -> bool:
	var group := Node3D.new()
	battle.add_child(group)
	var material := lighting.reference_glass()
	var ball := SphereMesh.new()
	ball.radius = 1.55
	ball.height = 3.1
	_mesh(group, ball, material, Vector3(2.05, 0, 0))
	var rod := CylinderMesh.new()
	rod.top_radius = 0.68
	rod.bottom_radius = 0.68
	rod.height = 4.5
	_mesh(group, rod, material, Vector3(-2, 0, 0)).rotation_degrees.z = -30.0
	_pose(26.0, 0)
	lighting.aim([material])
	var ok := await _save("I8_37_%s_reference.png" % setup)
	battle.remove_child(group)
	group.queue_free()
	return ok


func _mesh(group: Node3D, mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.material_override = material
	item.position = at
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	group.add_child(item)
	return item


func _save(name: String) -> bool:
	for frame in 30:
		await RenderingServer.frame_post_draw
	var image := render.get_texture().get_image()
	if image == null or image.get_size() != Vector2i(1920, 1080):
		_fail("Wrong capture size for " + name + ": " + str(render.size))
		return false
	if image.save_png(output.path_join(name)) != OK:
		_fail("Could not save " + output.path_join(name))
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
