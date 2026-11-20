extends SceneTree
# Cloud preview probe for issue 1316: Glasswright drive glow at full burn (I11_37, I8_37 at cameras 170 and 60).
# Copy to godot/ and run: P_OUT=dir P_FACE=3 xvfb-run -a godot --rendering-driver opengl3 --fixed-fps 60 --script res://_probe1316.gd (needs godot/gen).
const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const LOOK := preload("res://render/look.gd")
const CAMRIG := preload("res://render/camera_rig.gd")
var vp: SubViewport
var world: Node3D
var cam
var fx
func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)
func _run() -> void:
	var out := OS.get_environment("P_OUT")
	DirAccess.make_dir_recursive_absolute(out)
	vp = SubViewport.new(); vp.size = Vector2i(960, 540); vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new(); vp.add_child(world)
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.01, 0.012, 0.02)
	var we := WorldEnvironment.new(); we.environment = env; world.add_child(we)
	var key := DirectionalLight3D.new(); world.add_child(key)
	var fill := DirectionalLight3D.new(); world.add_child(fill)
	LOOK.apply(env, key, fill, {"quality": "max"})
	cam = CAMRIG.new(); world.add_child(cam); cam.input_enabled = false; cam.current = true
	fx = FX.new(); world.add_child(fx); fx.manual = true
	fx.setup({"camera": cam, "quality": "max", "reduce_flashing": false, "shake": 0.0, "unit": 1.0})
	var ships := [["D", "Destroyer", Vector3(-60, 0, 0)], ["K", "Ark", Vector3(60, 0, 0)]]
	for s in ships:
		var sv: Node3D = SV.new(); sv.name = "ship_" + s[0]; world.add_child(sv)
		sv.setup({"id": s[0], "fac": "ithar", "cls": s[1], "facing": int(OS.get_environment("P_FACE")), "hp": 100, "maxHp": 100, "size": 1.0}, s[2], true)
		print("[p1316] ", s[1], " code ", sv.code, " a4 ", sv.a4)
		var info := {"faction": "ithar", "cls": s[1], "size": 1.0, "squadron": false, "flagship": false, "code": sv.code}
		if not sv.a4:
			info["meshes"] = sv.meshes
		fx.add_ship(s[0], sv, info); sv.fx_engines = true
		fx.set_engine(s[0], 1.6)
	for v in [["I11_37_c170", 170.0, Vector3(-60, 0, 0)], ["I11_37_c60", 60.0, Vector3(-60, 0, 0)], ["I8_37_c170", 170.0, Vector3(60, 0, 0)], ["I8_37_c60", 60.0, Vector3(60, 0, 0)]]:
		cam.a = -PI / 2.0; cam.b = 0.98; cam.r = v[1]; cam.t = v[2]; cam.snap()
		for i in 90:
			fx.step(1.0 / 60.0)
			await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png(out.path_join(v[0] + ".png"))
		print("[p1316] saved ", v[0])
	print("P1316_DONE")
	quit(0)
