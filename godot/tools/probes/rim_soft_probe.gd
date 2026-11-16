extends SceneTree
# Issue 601: the rim glare probe. A ship glb drawn as the game draws it (LOOK.hull for its faction, LOOK.apply with both rim lights:
# LookRim for every hull, LookRimSoft for surfaces whose glTF extras carry rim_soft, the paint stack's), at the close cameras b and q of
# a4_shots and the battle camera (camera 170). It loads the glb at run time (GLTFDocument), so it needs no import; give the maps as PNG
# (this Linux build did not decode the glb's JPEG maps at run time).
# usage: godot --path godot --script res://tools/probes/rim_soft_probe.gd -- GLB OUT_DIR LENGTH TAG FACTION
const LOOK := preload("res://render/look.gd")
func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)
func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var glb: String = a[0]; var out: String = a[1]; var L := float(a[2]); var tag: String = a[3]; var fac: String = a[4]
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new(); vp.size = Vector2i(960, 540); vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS; root.add_child(vp)
	var world := Node3D.new(); vp.add_child(world)
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.01, 0.012, 0.02)
	var we := WorldEnvironment.new(); we.environment = env; world.add_child(we)
	var key := DirectionalLight3D.new(); world.add_child(key)
	var fill := DirectionalLight3D.new(); world.add_child(fill)
	var cam := Camera3D.new(); cam.fov = 30.0; cam.near = 0.2; cam.far = 5000.0; world.add_child(cam); cam.current = true
	LOOK.apply(env, key, fill, {"quality": "max"})
	var doc := GLTFDocument.new(); var st := GLTFState.new(); st.base_path = glb.get_base_dir()
	if doc.append_from_file(glb, st) != OK: print("[probe] load failed"); quit(1); return
	var ship := doc.generate_scene(st) as Node3D
	var aabb := AABB()
	for mi in ship.find_children("*", "MeshInstance3D", true, false):
		aabb = aabb.merge((mi as MeshInstance3D).get_aabb())
	ship.scale = Vector3.ONE * (L / maxf(aabb.size.x, 1e-6))
	for mi in ship.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for i in m.mesh.get_surface_count():
			var src := m.get_active_material(i)
			if src != null: m.set_surface_override_material(i, LOOK.hull(src, fac, true))
	world.add_child(ship)
	for k in 3: await process_frame
	var lights := []
	for n in world.get_children():
		if n is DirectionalLight3D: lights.append("%s vis %s spec %.2f mask %d" % [n.name, str(n.visible), n.light_specular, n.light_cull_mask])
	print("[probe] lights ", lights)
	for view in [["b", -0.40, -2.2, 0.0], ["q", 0.45, -0.62, 0.0], ["c170", 0.98, -PI / 2.0, 170.0]]:
		var el: float = view[1]; var az: float = view[2]
		var d := L * 0.62 / tan(deg_to_rad(cam.fov * 0.5)) * 0.62
		if float(view[3]) > 0: d = float(view[3]); el = PI / 2.0 - float(view[1])
		cam.look_at_from_position(Vector3(cos(el) * cos(az), sin(el), cos(el) * sin(az)) * d, Vector3.ZERO, Vector3.UP)
		for k in 8: await process_frame
		await RenderingServer.frame_post_draw
		var p := out.path_join("%s_%s.png" % [tag, view[0]])
		vp.get_texture().get_image().save_png(p); print("[probe] ", p)
	quit(0)
