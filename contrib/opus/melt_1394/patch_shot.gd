extends SceneTree
## Issue 1394 Wave 0 (Fable and Astra, Nov 23): a direction check of the acid tell's patch edge only. A grey plated slab
## (20 long, a big hull's acid radius 2) carries the MELT_GLOW overlay with two spots, seen from the battle-camera tilt
## and from a grazing one, as the patch spreads. Not the game: no ship, no look.gd. Run in the cloud with lavapipe:
##   VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver vulkan \
##     --path godot --script res://../contrib/opus/melt_1394/patch_shot.gd -- <shaders.gd> <out_prefix>
## Writes <out_prefix>_<view>_<t>.png.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var SH = load(args[0])
	var pre: String = args[1]
	root.size = Vector2i(960, 540)
	var world := Node3D.new()
	root.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.04, 0.07)
	env.ambient_light_color = Color(0.35, 0.38, 0.45)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.9, 0.6, 0.0)
	sun.light_energy = 1.6
	world.add_child(sun)
	var hull := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(20, 2, 6)
	bm.subdivide_width = 80
	bm.subdivide_depth = 24
	hull.mesh = bm
	var plate := StandardMaterial3D.new()
	plate.albedo_color = Color(0.36, 0.39, 0.44)
	plate.metallic = 0.6
	plate.roughness = 0.45
	hull.material_override = plate
	world.add_child(hull)
	# the game registers these in fx; this bare scene has to add them itself
	for g in [["scene_t", 0.0], ["fx_gain", 0.5556], ["fx_calm", 0.0], ["fx_px", 0.001]]:
		if not RenderingServer.global_shader_parameter_get_list().has(StringName(g[0])):
			RenderingServer.global_shader_parameter_add(g[0], RenderingServer.GLOBAL_VAR_TYPE_FLOAT, g[1])
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SH.MELT_GLOW
	m.shader = sh
	var arr := PackedVector4Array()
	var pts := [Vector3(-4.0, 1.0, 0.6), Vector3(3.5, 1.0, -0.8)]
	for i in 6:
		var v: Vector3 = pts[i] if i < pts.size() else Vector3.ZERO
		arr.append(Vector4(v.x, v.y, v.z, 2.0 * (1.0 if i == 0 else 0.8)))
	m.set_shader_parameter("spots", arr)
	m.set_shader_parameter("n_spots", 2)
	m.set_shader_parameter("rise", Vector2(0.0, 0.8))
	m.set_shader_parameter("frame", Transform3D.IDENTITY)
	hull.material_overlay = m
	var cam := Camera3D.new()
	cam.fov = 45.0
	world.add_child(cam)
	cam.current = true
	var views := {"battle": [0.98, 26.0], "grazing": [0.16, 22.0]}
	for vk in views:
		var b: float = views[vk][0]
		var r: float = views[vk][1]
		cam.position = Vector3(cos(b) * r * 0.35, sin(b) * r, cos(b) * r * 0.94)
		cam.look_at(Vector3.ZERO, Vector3.UP)
		for t in [0.15, 0.8]:
			RenderingServer.global_shader_parameter_set("scene_t", t)
			for k in 4: await process_frame
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			img.save_png("%s_%s_%.2f.png" % [pre, vk, t])
	quit(0)
