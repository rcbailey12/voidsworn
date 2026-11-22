extends SceneTree
# Issue 1765 (R419, Planets V2): stills of every planet look, capture only (no game default changes).
#   board_<look>_c170: each of the five board planet looks (0 rocky, 1 terran, 3 ice, 4 volcanic, 5 barren) at the
#     battle camera's radius and angle (camera 170, b 0.98), the planet at the board's size (map R 3, radius 50).
#   board_<look>_close: the same planet from 70 units, low over its lit limb.
#   backdrop_<i>: the eight backdrop planets (world_sky.gd PLANETS) as world.gd draws them, side lit.
#   moon_<i>: the moon looks as world.gd draws them.
# Every frame prints its body's lit disc mean (linear); an after run fails if any leaves R420's band 2, 0.03 to 0.25.
# Runs on both sides of the change: on a checkout without world_planet.gd install_board it draws the old board path
# (the campaign map's icon shader), so one script makes the before and the after.
# godot --path godot --resolution 1280x720 --script res://world/planet_v2_shots.gd -- --out DIR --tag after
# Cloud: VS_WORLD_PREVIEW=1 keeps the bakes small for the software renderer.
const SKY := preload("res://world/world_sky.gd")
const PL := preload("res://world/world_planet.gd")
const BAKER := preload("res://world/world_bake.gd")
const LOOK_KINDS := [0, 1, 3, 4, 5]
const OLD_LOOKS := {
	0: [Color(0.55, 0.42, 0.3), Color(0.22, 0.15, 0.1), Color(0.9, 0.65, 0.4)],
	1: [Color(0.36, 0.42, 0.24), Color(0.07, 0.15, 0.3), Color(0.45, 0.7, 1.0)],
	3: [Color(0.82, 0.88, 0.94), Color(0.42, 0.52, 0.62), Color(0.6, 0.8, 1.0)],
	4: [Color(0.28, 0.2, 0.16), Color(0.08, 0.06, 0.05), Color(1.0, 0.45, 0.2)],
	5: [Color(0.5, 0.48, 0.46), Color(0.2, 0.19, 0.19), Color(0.6, 0.62, 0.7)],
}
# world.gd before issue 1765: two moon palettes
const OLD_MOONS := [
	{"kind": 4, "a": Vector3(0.5, 0.48, 0.45), "b": Vector3(0.22, 0.21, 0.2), "c": Vector3(0.65, 0.62, 0.58)},
	{"kind": 5, "a": Vector3(0.8, 0.84, 0.88), "b": Vector3(0.5, 0.4, 0.32), "c": Vector3(0.6, 0.75, 0.9)},
]
const SUN_DIR := Vector3(0.4, 0.6, 0.7)
var out := "user://planet_v2_shots"
var band_misses: Array = []   # R420 band 2 (RULEBOOK 3.14): each body's lit disc mean, linear, 0.03 to 0.25
var tag := "now"
var only := ""
var started := 0
var cam: Camera3D
var stage: Node3D

func _init() -> void:
	started = Time.get_ticks_msec()
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() - started > 2400000:
		printerr("planet v2 shots: timeout")
		quit(1)
	return false

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _save(name: String) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var lum := _disc_mean(img)
	print("planet v2 shots: band2 %s lit disc mean %.3f linear" % [name, lum])
	if lum < 0.03 or lum > 0.25:
		band_misses.append("%s %.3f" % [name, lum])
	var path := out.path_join("%s_%s.png" % [name, tag])
	if preload("res://tools/picture_provenance.gd").save_png(img, path, preload("res://tools/picture_provenance.gd").capture_stage()) != OK:
		printerr("planet v2 shots: FAILED to save ", path)
		quit(1)
		return
	print("planet v2 shots: wrote ", path)

# mean linear luminance of the pixels the body lights (above a dark floor), over the frame above the stamp
func _disc_mean(img: Image) -> float:
	var sum := 0.0
	var n := 0
	var h := int(img.get_height() * 0.8)
	for y in range(0, h, 4):
		for x in range(0, img.get_width(), 4):
			var c := img.get_pixel(x, y).srgb_to_linear()
			var l := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			if l > 0.004:
				sum += l
				n += 1
	return sum / maxf(1.0, float(n))


func _clear() -> void:
	for c in stage.get_children():
		stage.remove_child(c)
		c.queue_free()

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var argv := OS.get_cmdline_user_args()
	for i in argv.size():
		if argv[i] == "--out" and i + 1 < argv.size(): out = argv[i + 1]
		if argv[i] == "--tag" and i + 1 < argv.size(): tag = argv[i + 1]
		if argv[i] == "--only" and i + 1 < argv.size(): only = argv[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.004, 0.005, 0.008)
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.tonemap_agx_white = 12.0
	env.tonemap_agx_contrast = 1.25
	we.environment = env
	root.add_child(we)
	# a key light along the board's sun (the old board shader was lit; the new ones light themselves from the same sun)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.9, 1.0)
	env.ambient_light_energy = 0.25
	var key := DirectionalLight3D.new()
	root.add_child(key)
	key.look_at_from_position(Vector3.ZERO, -SUN_DIR, Vector3.UP)
	key.light_energy = 1.0
	stage = Node3D.new()
	root.add_child(stage)
	cam = Camera3D.new()
	cam.fov = 45.0
	cam.far = 20000.0
	root.add_child(cam)
	cam.current = true
	BAKER.service(self)
	var pl_script: GDScript = load("res://world/world_planet.gd")
	var new_board := pl_script.get_script_method_list().any(func(m): return m["name"] == "install_board")
	print("planet v2 shots: ", "new board path" if new_board else "old board path (map3d icon shader)")
	if only == "" or only == "board":
		for k in LOOK_KINDS:
			await _board(k, new_board)
	if only == "" or only == "backdrop":
		for i in SKY.PLANETS.size():
			await _backdrop("backdrop_%d" % i, SKY.PLANETS[i], 4100 + i, BAKER.PLANET_SIZE, 1.0)
	if only == "" or only == "moons":
		var W = load("res://world/world.gd")
		var moons: Array = W.MOON_LOOKS if "MOON_LOOKS" in W.get_script_constant_map() else OLD_MOONS
		for i in moons.size():
			var M: Dictionary = (moons[i] as Dictionary).duplicate()
			M["atmo"] = Vector3.ZERO
			M["rings"] = false
			await _backdrop("moon_%d" % i, M, int(M["kind"]) * 1000 + 3 + i * 101, BAKER.MOON_SIZE, 0.0)
	print("planet v2 shots: done in %d s" % ((Time.get_ticks_msec() - started) / 1000))
	if band_misses.is_empty():
		print("planet v2 shots: band 2 PASS")
	else:
		print("planet v2 shots: band 2 MISS: ", ", ".join(band_misses))
	quit(0 if band_misses.is_empty() or tag == "before" else 1)

func _board(k: int, new_board: bool) -> void:
	_clear()
	var rad := 50.0
	var sp := SphereMesh.new()
	sp.radius = rad
	sp.height = rad * 2.0
	sp.radial_segments = 192
	sp.rings = 96
	var mi := MeshInstance3D.new()
	mi.mesh = sp
	mi.position = Vector3(0, -rad * 0.78, 0)
	stage.add_child(mi)
	var shell := MeshInstance3D.new()
	var ss := SphereMesh.new()
	ss.radius = rad * 1.03
	ss.height = rad * 2.06
	ss.radial_segments = 128
	ss.rings = 64
	shell.mesh = ss
	shell.position = mi.position
	stage.add_child(shell)
	var sun := mi.position + SUN_DIR.normalized() * 100000.0
	var seed_v := 7 + k
	if new_board:
		var pl_script: GDScript = load("res://world/world_planet.gd")
		await pl_script.call("install_board", mi, shell, k, seed_v, sun)
		for i in 600:
			if not (mi.material_override is ShaderMaterial) or (mi.material_override as ShaderMaterial).get_shader_parameter("has_tex") != 0.0 \
					or str(mi.get_meta("planet_code", "")) == "R01":
				break
			await process_frame
	else:
		var MS = load("res://ui/campaign/map3d_shaders.gd")
		var look: Array = OLD_LOOKS[k]
		var pm := ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = MS.PLANET
		pm.shader = sh
		pm.set_shader_parameter("kind", float(k))
		pm.set_shader_parameter("a", look[0])
		pm.set_shader_parameter("b", look[1])
		pm.set_shader_parameter("atmo", look[2])
		pm.set_shader_parameter("seed", float(posmod(seed_v, 97)) * 1.37)
		pm.set_shader_parameter("sun_pos", sun)
		pm.set_shader_parameter("q", 1.0)
		mi.material_override = pm
		var am := ShaderMaterial.new()
		var ash := Shader.new()
		ash.code = MS.ATMO
		am.shader = ash
		am.set_shader_parameter("atmo", look[2])
		am.set_shader_parameter("sun_pos", sun)
		am.set_shader_parameter("gain", 1.0)
		shell.material_override = am
	# camera 170 at the home view's angle, looking at the planet's cap on the board plane
	var t := Vector3(0, 0, 0)
	cam.position = t + Vector3(0, cos(0.98), sin(0.98)) * 170.0
	cam.look_at(t, Vector3.UP)
	await _save("board_%d_c170" % k)
	# close: low over the lit limb
	var limb := Vector3(SUN_DIR.x, 0, SUN_DIR.z).normalized() * rad * 0.55
	cam.position = limb + Vector3(-0.35, 0.55, 0.85).normalized() * 70.0
	cam.look_at(limb + Vector3(0, -8, 0), Vector3.UP)
	await _save("board_%d_close" % k)

func _backdrop(name: String, P: Dictionary, bake_seed: int, size: Vector2i, spin: float) -> void:
	_clear()
	if OS.has_environment("VS_WORLD_PREVIEW"): size = size / 4
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 128
	sm.rings = 64
	mi.mesh = sm
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = PL.SPHERE
	m.shader = sh
	var sun := Vector3(0.88, 0.33, 0.34).normalized()
	m.set_shader_parameter("flat_col", (P["a"] as Vector3) * 0.6)
	m.set_shader_parameter("sun", sun)
	var atmo: Vector3 = P.get("atmo", Vector3.ZERO)
	m.set_shader_parameter("atmo", atmo)
	m.set_shader_parameter("atmo_k", 0.0 if atmo.length() < 0.01 else (0.8 if int(P["kind"]) == 2 else 0.55))
	m.set_shader_parameter("spin", 0.0)
	m.set_shader_parameter("light", 0.6)
	m.set_shader_parameter("rough", 1.0 if int(P["kind"]) >= 2 else 0.25)
	var tilt := Basis(Vector3(0, 0, 1), 0.3) * Basis(Vector3(1, 0, 0), -0.12)
	if bool(P.get("rings", false)):
		var up := tilt * Vector3.UP
		m.set_shader_parameter("ring", Vector4(up.x, up.y, up.z, 1.0))
		m.set_shader_parameter("ring_r", Vector2(1.3, 2.3))
	mi.material_override = m
	mi.transform = Transform3D(tilt, Vector3.ZERO)
	stage.add_child(mi)
	if atmo.length() > 0.01:
		var sh2 := MeshInstance3D.new()
		var sm2 := SphereMesh.new()
		sm2.radius = 1.035
		sm2.height = 2.07
		sh2.mesh = sm2
		var am := ShaderMaterial.new()
		var ash := Shader.new()
		ash.code = PL.ATMO
		am.shader = ash
		am.set_shader_parameter("atmo", atmo)
		am.set_shader_parameter("sun", sun)
		am.set_shader_parameter("shell", 1.035)
		am.set_shader_parameter("k", 0.9 if int(P["kind"]) == 2 else 0.6)
		sh2.material_override = am
		stage.add_child(sh2)
	if bool(P.get("rings", false)):
		var ring := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(4.8, 4.8)
		ring.mesh = pm
		var rm := ShaderMaterial.new()
		var rsh := Shader.new()
		rsh.code = PL.RING
		rm.shader = rsh
		rm.set_shader_parameter("sun", sun)
		rm.set_shader_parameter("col_a", (P["c"] as Vector3) * 0.9)
		rm.set_shader_parameter("col_b", (P["b"] as Vector3) * 1.2)
		rm.set_shader_parameter("seed", 11.0)
		rm.set_shader_parameter("ring_r", Vector2(1.3, 2.3))
		rm.set_shader_parameter("light", 0.55)
		ring.material_override = rm
		ring.transform = Transform3D(tilt, Vector3.ZERO)
		stage.add_child(ring)
	var baker = BAKER.service(self)
	var params := {"seed": float(bake_seed % 997) * 0.71, "kind": int(P["kind"]), "ca": P["a"], "cb": P["b"], "cc": P["c"], "pass_id": 0}
	var code := PL.bake_code()
	var a: Image = await baker.bake("v2shot|" + name + "|a", code, params, size, 16)
	params["pass_id"] = 1
	var b: Image = await baker.bake("v2shot|" + name + "|b", code, params, size, 16)
	if a != null and b != null:
		m.set_shader_parameter("tex_a", BAKER.texture(a))
		m.set_shader_parameter("tex_b", BAKER.texture(b))
		m.set_shader_parameter("has_tex", 1.0)
	else:
		printerr("planet v2 shots: bake failed for ", name)
	var far := 3.4 if bool(P.get("rings", false)) else 2.7
	cam.position = Vector3(0, 0.25, far)
	cam.look_at(Vector3.ZERO, Vector3.UP)
	await _save(name)
