extends SceneTree
# Issue 1468: before and after stills for two shader math fixes, capture only (no game default changes).
#   1. The galaxy band (world_sky.gd): the baked sky panorama and a live sky view of the band.
#   2. Planet relief (world_planet.gd): one baked barren, cratered planet lit from the side, seen from its front and from
#      its back. Each view is drawn twice: the game look, and relief only (flat grey ground) so the ridges read clearly.
#      A third view turns the front view's whole scene half way round the view axis: it must match the front view exactly.
# godot --path godot --resolution 1280x720 --script res://world/shader_math_shots.gd -- --out DIR --tag before
# Cloud: VS_WORLD_PREVIEW=1 keeps the bakes small for the software renderer.
const SKY := preload("res://world/world_sky.gd")
const PL := preload("res://world/world_planet.gd")
const BAKER := preload("res://world/world_bake.gd")
var out := "user://shader_math_shots"
var tag := "now"
var started := 0

func _init() -> void:
	started = Time.get_ticks_msec()
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() - started > 1500000:
		printerr("shader math shots: timeout")
		quit(1)
	return false

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _save(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := out.path_join("%s_%s.png" % [name, tag])
	return _stamp(img, path)

# every still goes through the shared stamp; a failed save (or a missing sidecar) fails the whole run
func _stamp(img: Image, path: String) -> bool:
	if preload("res://tools/picture_provenance.gd").save_png(img, path, preload("res://tools/picture_provenance.gd").capture_stage()) != OK or not FileAccess.file_exists(path) \
			or not FileAccess.file_exists(path + ".provenance.json"):
		printerr("shader math shots: FAILED to save ", path)
		quit(1)
		return false
	print("shader math shots: wrote ", path)
	return true

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var argv := OS.get_cmdline_user_args()
	for i in argv.size():
		if argv[i] == "--out" and i + 1 < argv.size(): out = argv[i + 1]
		if argv[i] == "--tag" and i + 1 < argv.size(): tag = argv[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	# a fresh set only: an earlier capture with the same tag must never pass as this one
	for f in DirAccess.get_files_at(out):
		if f.ends_with("_%s.png" % tag) or f.ends_with("_%s.png.provenance.json" % tag):
			printerr("shader math shots: FAILED, %s already holds %s; use a fresh folder or tag" % [out, f])
			quit(1)
			return
	var small := OS.has_environment("VS_WORLD_PREVIEW")
	var baker = BAKER.service(self)

	# ---- the sky: the setting the world_shots planet battle uses (hegemony, open map, seed 4105)
	var st: Dictionary = SKY.setting({"rock": "stone", "planet": 3}, "hegemony", "open", false, 4105)
	var bs: Dictionary = SKY.bake_view(st)
	var lamps: Array = SKY.lamps(bs)
	var size := Vector2i(1024, 512) if small else Vector2i(4096, 2048)
	var params := {"seed": float(int(bs["seed"]) % 997) * 0.37, "c1": bs["c1"], "c2": bs["c2"], "c3": bs["c3"],
		"neb": float(bs["neb"]), "cover": float(bs["cover"]), "dust": float(bs["dust"]), "band": float(bs["band"]),
		"band_n": bs["band_n"], "feature": bs["feature"], "steps": 26 if small else 40,
		"lamp": PackedVector4Array(lamps), "gal": PackedVector4Array(SKY.galaxies(bs))}
	var pano: Image = await baker.bake("1468sky|" + tag, SKY.bake_code(), params, size, 32)
	if pano == null:
		printerr("shader math shots: sky bake failed")
		quit(1)
		return
	var p2 := pano.duplicate()
	p2.convert(Image.FORMAT_RGBA8)
	p2.resize(1280, 640, Image.INTERPOLATE_LANCZOS)
	if not _stamp(p2, out.path_join("sky_panorama_%s.png" % tag)): return

	var scene := Node3D.new()
	root.add_child(scene)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SKY.SKY
	m.shader = sh
	m.set_shader_parameter("lamp", PackedVector4Array(lamps))
	m.set_shader_parameter("seed", float(int(st["seed"]) % 997))
	m.set_shader_parameter("band_n", st["band_n"])
	m.set_shader_parameter("band", float(st["band"]))
	m.set_shader_parameter("star_k", float(st["stars"]))
	m.set_shader_parameter("px", deg_to_rad(45.0) / 720.0)
	m.set_shader_parameter("neb_tex", BAKER.texture(pano))
	m.set_shader_parameter("has_neb", 1.0)
	var sky := Sky.new()
	sky.sky_material = m
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	we.environment = env
	scene.add_child(we)
	var cam := Camera3D.new()
	cam.fov = 70.0
	scene.add_child(cam)
	# look along the band's plane, so the band runs across the frame
	var bn: Vector3 = st["band_n"]
	var along := bn.cross(Vector3(0.31, 0.0, 0.95)).normalized()
	cam.look_at_from_position(Vector3.ZERO, along, bn)
	cam.make_current()
	await _frames(6)
	if not await _save("sky_band_view"): return

	# ---- the planet: barren cratered (kind 4), sun from world +X, camera in front (+Z) and behind (-Z)
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0)
	var P: Dictionary = {"kind": 4, "a": Vector3(0.55, 0.5, 0.45), "b": Vector3(0.35, 0.32, 0.3), "c": Vector3(0.75, 0.7, 0.62)}
	var psize := Vector2i(1024, 512) if small else Vector2i(2048, 1024)
	var pp := {"seed": float(311 % 997) * 0.71, "kind": 4, "ca": P["a"], "cb": P["b"], "cc": P["c"], "pass_id": 0}
	var a: Image = await baker.bake("1468pl|a|" + tag, PL.bake_code(), pp, psize, 16)
	pp["pass_id"] = 1
	var b: Image = await baker.bake("1468pl|b|" + tag, PL.bake_code(), pp, psize, 16)
	if a == null or b == null:
		printerr("shader math shots: planet bake failed")
		quit(1)
		return
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 192
	sm.rings = 96
	mi.mesh = sm
	scene.add_child(mi)
	var looks := {"game": PL.SPHERE, "relief": PL.SPHERE.replace("alb *= tint;", "alb = vec3(0.6);")}
	for look in looks:
		var pm := ShaderMaterial.new()
		var psh := Shader.new()
		psh.code = looks[look]
		pm.shader = psh
		pm.set_shader_parameter("flat_col", (P["a"] as Vector3) * 0.6)
		pm.set_shader_parameter("sun", Vector3(1.0, 0.25, 0.0).normalized())
		pm.set_shader_parameter("atmo", Vector3.ZERO)
		pm.set_shader_parameter("atmo_k", 0.0)
		pm.set_shader_parameter("spin", 0.0)
		pm.set_shader_parameter("light", 1.0)
		pm.set_shader_parameter("rough", 1.0)
		pm.set_shader_parameter("tex_a", BAKER.texture(a))
		pm.set_shader_parameter("tex_b", BAKER.texture(b))
		pm.set_shader_parameter("has_tex", 1.0)
		mi.material_override = pm
		for side in ["front", "back"]:
			var z := 2.6 if side == "front" else -2.6
			cam.fov = 40.0
			cam.look_at_from_position(Vector3(0.0, 0.0, z), Vector3.ZERO, Vector3.UP)
			await _frames(6)
			if not await _save("planet_%s_%s" % [look, side]): return
		# the check: the front view's whole scene (planet, sun and camera) turned half way round the view axis. A correct
		# shader draws exactly the front picture; the old one lit ridges by the world's axes, not the planet's
		mi.transform = Transform3D(Basis(Vector3.BACK, PI), Vector3.ZERO)
		pm.set_shader_parameter("sun", Vector3(-1.0, -0.25, 0.0).normalized())
		cam.look_at_from_position(Vector3(0.0, 0.0, 2.6), Vector3.ZERO, Vector3.DOWN)
		await _frames(6)
		if not await _save("planet_%s_turned" % look): return
		mi.transform = Transform3D.IDENTITY
	print("shader math shots: done")
	quit(0)
