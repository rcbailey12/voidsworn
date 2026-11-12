extends SceneTree
# Issue 569 capture: one damaged Glasswright (Ithar) cruiser at camera 60 (render/camera_rig.gd r=60),
# with a measured checker behind it so a see-through sail shows what is behind it.
# Set SAIL_ALPHA_OUT (folder) and SAIL_ALPHA_LABEL (before|after); needs godot/gen (the real ship files).
const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const CAM := preload("res://render/camera_rig.gd")
const PG := preload("res://render/placeholder_guard.gd")

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	var out := OS.get_environment("SAIL_ALPHA_OUT")
	var label := OS.get_environment("SAIL_ALPHA_LABEL")
	if out == "":
		push_error("Set SAIL_ALPHA_OUT to a scratch folder")
		quit(1)
		return
	if label == "":
		label = "shot"
	seed(569)
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.03, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.7)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var light := DirectionalLight3D.new()
	light.light_energy = 2.2
	light.rotation_degrees = Vector3(-55, -30, 0)
	world.add_child(light)
	# The measured backdrop: a dark and white checker, so a 0.55 alpha sail plainly shows it through.
	var backdrop := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(140, 90)
	backdrop.mesh = quad
	backdrop.position = Vector3(0, 12, -30)
	var stripes := Shader.new()
	stripes.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
void fragment() {
	vec2 g = step(vec2(0.5), fract(UV * vec2(10.0, 6.0)));
	float bar = abs(g.x - g.y);
	ALBEDO = mix(vec3(0.04, 0.28, 0.34), vec3(0.92, 0.94, 0.9), bar);
}
"""
	var bmat := ShaderMaterial.new()
	bmat.shader = stripes
	backdrop.material_override = bmat
	world.add_child(backdrop)
	var cam = CAM.new()
	world.add_child(cam)
	cam.current = true
	var sv := SV.new()
	world.add_child(sv)
	sv.setup({"id": "I", "fac": "ithar", "cls": "Cruiser", "facing": 0}, Vector3.ZERO)
	if PG.stop_if_any():
		return
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max", "shake": 0.0, "seed": 569})
	fx.add_ship("I", sv, {"faction": "ithar", "cls": "Cruiser", "size": 1.3, "meshes": sv.meshes, "shielded": false})
	var s = fx.ship("I")
	fx._later.clear()
	# Damage anchors on the real hull, as damage_surface_probe does.
	for i in 3:
		var h = s.hull
		var x: float = h.c.x + (i - 1) * h.L * 0.28
		var hit: Dictionary = h.ray(Vector3(x, h.c.y + h.H * 3, h.c.z), Vector3.DOWN)
		if not hit.is_empty():
			s._anchors["a%d" % i] = {"p": hit.p, "n": hit.n, "t": {}}
	fx.now = 10.0
	s.set_stages(fx, [4, 4, 4])
	for i in 5:
		if s._dmg_task >= 0:
			s.flush_damage(fx)
	fx.step(1.4)
	print("SAIL_ALPHA_HULL L=%.2f W=%.2f H=%.2f tris=%d" % [s.hull.L, s.hull.W, s.hull.H, s.hull.tri_count])
	# Paint the damage-material facts into the log so the picture has printed proof beside it.
	var sail_seen := false
	for m in sv.meshes:
		var mi := m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for si in mi.mesh.get_surface_count():
			var base: Material = mi.mesh.surface_get_material(si)
			var mat: Material = mi.get_active_material(si)
			var base_t := -1
			var base_a := -1.0
			if base is BaseMaterial3D:
				base_t = (base as BaseMaterial3D).transparency
				base_a = (base as BaseMaterial3D).albedo_color.a
			var has_alpha := mat is ShaderMaterial and (mat as ShaderMaterial).shader.code.contains("ALPHA = hull_albedo.a")
			print("SAIL_ALPHA_SURFACE mi=%s si=%d base=%s t=%d a=%.2f active=%s alpha=%s" % [mi.name, si,
				base.resource_name if base != null else "<none>", base_t, base_a,
				mat.get_class() if mat != null else "<none>", str(has_alpha)])
			if has_alpha:
				sail_seen = true
	print("SAIL_ALPHA_DAMAGE_MATERIAL writes_alpha=%s" % str(sail_seen))
	if DisplayServer.get_name() == "headless":
		print("SAIL_ALPHA_DRY headless, no picture")
		fx.release()
		world.queue_free()
		await process_frame
		SV.clear_static()
		FX.clear_static()
		PG.finish(0)
		return
	# Camera 60: the game's own rig at r=60, aimed at the hull centre.
	cam.r = 60.0
	cam.t = s.to_world(s.hull.c)
	cam.snap()
	print("SAIL_ALPHA_CAM r=%.1f pos=%s target=%s" % [cam.r, str(cam.global_position), str(cam.t)])
	for i in 6:
		await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(out.path_join("sails_" + label + ".png"))
	print("SAIL_ALPHA_CAPTURE %s -> %s" % [label, out.path_join("sails_" + label + ".png")])
	fx.release()
	world.queue_free()
	await process_frame
	SV.clear_static()
	FX.clear_static()
	PG.finish(0)
