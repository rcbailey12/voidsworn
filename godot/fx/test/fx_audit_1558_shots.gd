extends SceneTree
# Issue 1558 items 1 and 2: before/after stills at the battle camera (distance 170), effects only, no ships.
#   jets: a Cone B muzzle vent (the gas `aspect` 2 to 4). "before" forces aspect 1, which is what main draws today (the
#         shader replace that applied aspect matched nothing); "after" is this branch.
#   veil: a capital core flash and its gas veil. "before" replays main's code (veil spawned with the flash, born moved
#         0.45 s ahead); "after" is this branch (veil spawned 0.45 s later by fx.later).
# Run (cloud, software Vulkan, or the PC):
#   godot --path godot --resolution 640x360 --script res://fx/test/fx_audit_1558_shots.gd
# Env: SHOTS_OUT (folder, default /tmp/fx1558). Writes <scene>_<variant>_t<ms>.png and prints SHOTS_DONE.

const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const DEATH := preload("res://fx/fx_death.gd")
const LOOK := preload("res://render/look.gd")

var vp: SubViewport
var world: Node3D
var cam: Camera3D
var fx
var out := "/tmp/fx1558"


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var o := OS.get_environment("SHOTS_OUT")
	if o != "": out = o
	DirAccess.make_dir_recursive_absolute(out)
	vp = SubViewport.new()
	vp.size = Vector2i(640, 360)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.02)
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()
	world.add_child(key)
	var fill := DirectionalLight3D.new()
	world.add_child(fill)
	LOOK.apply(env, key, fill, {"quality": "max"})
	cam = Camera3D.new()
	cam.fov = 45.0
	world.add_child(cam)
	cam.current = true
	for v in ["before", "after"]:
		await _scene("jets", v, [0.05, 0.12, 0.25])
		await _scene("veil", v, [0.15, 0.35, 0.6, 1.2])
	print("SHOTS_DONE")
	quit(0)


func _fresh() -> void:
	if fx != null:
		fx.queue_free()
		await process_frame
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max", "reduce_flashing": false, "shake": 0.0, "unit": 1.0})
	await fx.warmup(cam)


func _scene(scene: String, variant: String, times: Array) -> void:
	await _fresh()
	var d := 170.0 if scene == "veil" else 60.0   # the jets sit at the battle camera's close zoom so the shape reads
	cam.position = Vector3(0, 0.557, 0.83).normalized() * d
	cam.look_at(Vector3.ZERO)
	var t0: float = fx.now + 0.05
	if scene == "jets":
		for j in 3:
			var p := Vector3(-14.0 + j * 14.0, 0, 0)
			WEAP._vent(fx, p, Vector3(1, 0, -0.3).normalized(), t0, 7.0, 0.5, Color(1.0, 0.62, 0.3), 0.8, Vector3.ZERO, 0.55, 1.0, 2, null)
	else:
		DEATH._core_flash(fx, Vector3.ZERO, 22.0, 70.0, Color(1.0, 0.8, 0.55), null, Vector3.ZERO, null, "capital")
		if variant == "before":
			var L: float = _stand_in().hull.L
			var gas := DEATH.flipbook(fx, Vector3.ZERO, Vector3.UP, L * 0.8, "cool", 3.6, Vector3.ZERO, 0.38, DEATH.atlas_band(L), null)
			(gas.material_override as ShaderMaterial).set_shader_parameter("born", fx.now + 0.45)
		else:
			fx.later(fx.now + DEATH.CORE_VEIL_DELAY, DEATH._core_gas_veil.bind(fx, _stand_in(), Vector3.ZERO, true, Vector3.ZERO, Transform3D.IDENTITY))
	var start: float = fx.now
	for t in times:
		while fx.now < start + float(t):
			fx.step(1.0 / 60.0)
			if scene == "jets" and variant == "before":
				for n in fx.find_children("fx_weapon_vent*", "MeshInstance3D", true, false):
					((n as MeshInstance3D).material_override as ShaderMaterial).set_shader_parameter("aspect", 1.0)
			await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		var path := out.path_join("%s_%s_t%03d.png" % [scene, variant, int(round(float(t) * 1000.0))])
		preload("res://tools/picture_provenance.gd").save_png(img, path, "cloud direction check")
		print("[shots] ", path)


# A hidden 40-long hull record for the veil (it sizes the gas and takes the spawn record); never drawn.
func _stand_in():
	if fx.ships.has("veil"):
		return fx.ships["veil"]
	var target := Node3D.new()
	target.visible = false
	world.add_child(target)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(40, 6, 10)
	mi.mesh = box
	target.add_child(mi)
	fx.add_ship("veil", target, {"meshes": [mi], "shielded": false, "cls": "Battleship"})
	return fx.ships["veil"]
