extends SceneTree
# Issue 1315 probe (PC, Forward+): what makes CD5's white stern bloom. The a4_shots light rig and close view q on the raw
# installed glb, rendered once per variant; each variant changes one material input on every hull and parts surface.
# Writes <out>/<variant>.png and <out>/bloom_probe.txt (per variant: pixels over 245 and over 200, the shot q measure).
# Run: Godot --path <a project> --resolution 1920x1080 --script <this file> -- <I8_37.glb> <out folder>
const VARIANTS := ["base", "noglow", "noemit", "metal_0.3", "metal_0", "rough_0.45", "noemit_metal_0.3", "nokey", "nofill"]
var ship: Node3D
var mats := []          # [MeshInstance3D, surface, StandardMaterial3D original]
var key: DirectionalLight3D
var fill: DirectionalLight3D
var env: Environment

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _apply(v: String) -> void:
	env.glow_enabled = v != "noglow"
	key.light_energy = 0.0 if v == "nokey" else 2.0
	fill.light_energy = 0.0 if v == "nofill" else 0.5
	for row in mats:
		var src: StandardMaterial3D = row[2]
		var n: StandardMaterial3D = src.duplicate()
		if v.contains("noemit"): n.emission_enabled = false
		if v.contains("metal_"): n.metallic = float(v.get_slice("metal_", 1))
		if v.begins_with("rough_"): n.roughness_texture = null; n.roughness = float(v.get_slice("rough_", 1))
		(row[0] as MeshInstance3D).set_surface_override_material(int(row[1]), n)

func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var path: String = a[0]; var out: String = a[1]
	DirAccess.make_dir_recursive_absolute(out)
	var doc := GLTFDocument.new(); var st := GLTFState.new()
	if doc.append_from_file(path, st) != OK:
		print("BLOOM_PROBE cannot load ", path); quit(1); return
	ship = doc.generate_scene(st)
	for mi in [ship] + ship.find_children("*", "MeshInstance3D", true, false):
		if mi is MeshInstance3D:
			for si in (mi as MeshInstance3D).mesh.get_surface_count():
				var m = (mi as MeshInstance3D).mesh.surface_get_material(si)
				if m is StandardMaterial3D: mats.append([mi, si, m])
	var w := Node3D.new(); root.add_child(w)
	var hull := Node3D.new(); w.add_child(hull); hull.add_child(ship)
	var L := 41.6
	var box := AABB(); var first := true
	for row in mats:
		var mi: MeshInstance3D = row[0]
		var bb: AABB = mi.global_transform * mi.get_aabb()
		box = bb if first else box.merge(bb); first = false
	hull.scale = Vector3.ONE * (L / maxf(box.size.x, 1e-4))
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.01, 0.012, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(1, 1, 1); env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES; env.tonemap_white = 8.0
	var we := WorldEnvironment.new(); we.environment = env; w.add_child(we)
	key = DirectionalLight3D.new(); key.transform = Transform3D(Basis.looking_at(Vector3(-0.45, -0.70, -0.55).normalized(), Vector3.UP), Vector3.ZERO)
	key.light_color = Color(1.0, 0.96, 0.90); key.shadow_enabled = true; w.add_child(key)
	fill = DirectionalLight3D.new(); fill.transform = Transform3D(Basis.looking_at(Vector3(0.6, -0.2, 0.75).normalized(), Vector3.UP), Vector3.ZERO)
	fill.light_color = Color(0.55, 0.65, 0.85); w.add_child(fill)
	get_root().msaa_3d = Viewport.MSAA_4X
	var cam := Camera3D.new(); cam.fov = 30.0; cam.near = 0.2; cam.far = 5000.0; w.add_child(cam); cam.current = true
	var el := 0.45; var az := -0.62
	var d := L * 0.62 / tan(deg_to_rad(15.0)) * 0.62
	cam.look_at_from_position(Vector3(cos(el) * cos(az), sin(el), cos(el) * sin(az)) * d, Vector3.ZERO, Vector3.UP)
	var rep := FileAccess.open(out.path_join("bloom_probe.txt"), FileAccess.WRITE)
	for v in VARIANTS:
		_apply(v)
		for k in 12: await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_texture().get_image()
		img.save_png(out.path_join(v + ".png"))
		var s245 := 0; var s200 := 0
		for y in range(0, img.get_height(), 2):
			for x in range(0, img.get_width(), 2):
				var c := img.get_pixel(x, y); var l := (c.r + c.g + c.b) / 3.0
				if l > 245.0 / 255.0: s245 += 1
				if l > 200.0 / 255.0: s200 += 1
		var line := "BLOOM_PROBE %s over245=%d over200=%d (every 2nd pixel)" % [v, s245, s200]
		print(line); rep.store_line(line)
	rep.close()
	print("BLOOM_PROBE done")
	quit(0)
