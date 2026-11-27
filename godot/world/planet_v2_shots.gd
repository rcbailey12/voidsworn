extends SceneTree
# Issue 1765 (R419, Planets V2): stills of every planet look, capture only (no game default changes).
#   board_<look>_c170: each of the five board planet looks (0 rocky, 1 terran, 3 ice, 4 volcanic, 5 barren) at the
#     battle camera's radius and angle (camera 170, b 0.98), the planet at the board's size (map R 3, radius 50).
#   board_<look>_close: the same planet from 70 units, low over its lit limb.
#   backdrop_<i>: the eight backdrop planets (world_sky.gd PLANETS) as world.gd draws them, side lit.
#   backdrop_alt_<i>: the same for their remixes (PLANETS_ALT); --only board|standin|backdrop|alt|moons picks one set.
#   moon_<i>: the moon looks as world.gd draws them.
# Every frame prints its body's day-side mean (linear, a geometric sphere mask, dark pixels included); an after run fails
# if any leaves R420's band 2, 0.03 to 0.25, or the mask catches under 200 samples.
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
var body_c := Vector3.ZERO    # the body in the frame: centre, radius, toward its sun (for the band 2 mask)
var body_r := 1.0
var body_sun := Vector3.UP
var tag := "now"
var only := ""
var standin := false
var seed_add := 0   # --seed N: another battle's face of each look
var timing := 0   # --timing N: after each board look's camera 170 still, N frames of GPU render time (run the GPU solo)
var mm_trial := false   # --mm-trial: named terran/volcanic stills, fixed weather and verified live detail
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
	var m := _disc_mean(img)
	var lum: float = m[0]
	print("planet v2 shots: band2 %s lit disc mean %.3f linear over %d day-side samples" % [name, lum, int(m[1])])
	if int(m[1]) < 200 or lum < 0.03 or lum > 0.25:
		band_misses.append("%s %.3f (%d samples)" % [name, lum, int(m[1])])
	var path := out.path_join("%s_%s.png" % [name, tag])
	if preload("res://tools/picture_provenance.gd").save_png(img, path, preload("res://tools/picture_provenance.gd").capture_stage()) != OK:
		printerr("planet v2 shots: FAILED to save ", path)
		quit(1)
		return
	print("planet v2 shots: wrote ", path)

# Band 2 (Artoo, PR 1776): the mask is geometric, never chosen by brightness. Each sample pixel's camera ray is hit
# against the body's sphere; a hit on the day side (normal toward the sun past 0.15) counts however dark it renders, so
# black terrain pulls the mean down and air, rings and space never enter. Returns [mean, samples].
func _disc_mean(img: Image) -> Array:
	var sum := 0.0
	var n := 0
	var h := int(img.get_height() * 0.8)   # above the picture stamp
	var scale := Vector2(get_root().get_visible_rect().size) / Vector2(img.get_size())
	for y in range(0, h, 3):
		for x in range(0, img.get_width(), 3):
			var sp := Vector2(x, y) * scale
			var o := cam.project_ray_origin(sp)
			var d := cam.project_ray_normal(sp)
			var oc := o - body_c
			var bq := oc.dot(d)
			var disc := bq * bq - (oc.length_squared() - body_r * body_r)
			if disc < 0.0:
				continue
			var t := -bq - sqrt(disc)
			if t <= 0.0:
				continue
			var nrm := (o + d * t - body_c).normalized()
			if nrm.dot(body_sun) < 0.15:
				continue
			var c := img.get_pixel(x, y).srgb_to_linear()
			sum += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			n += 1
	return [sum / maxf(1.0, float(n)), n]


# GPU render time of the whole frame over N frames at the current view (Board's solo frame-time row, R293)
func _time_frames(name: String) -> void:
	var vp := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	await _frames(30)
	var t: Array = []
	for i in timing:
		await RenderingServer.frame_post_draw
		t.append(RenderingServer.viewport_get_measured_render_time_gpu(vp))
	t.sort()
	var mean := 0.0
	for v in t: mean += float(v)
	mean /= maxf(1.0, float(t.size()))
	print("[timing] %s gpu ms mean %.3f p50 %.3f p99 %.3f max %.3f over %d frames; video memory %.0f MB, static memory peak %.0f MB" % [
		name, mean, float(t[t.size() / 2]), float(t[mini(t.size() - 1, int(t.size() * 0.99))]), float(t[t.size() - 1]), t.size(),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, OS.get_static_memory_peak_usage() / 1048576.0])
	RenderingServer.viewport_set_measure_render_time(vp, false)


func _clear() -> void:
	for c in stage.get_children():
		stage.remove_child(c)
		c.queue_free()

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var argv := OS.get_cmdline_user_args()
	mm_trial = argv.has("--mm-trial")
	for i in argv.size():
		if argv[i] == "--out" and i + 1 < argv.size(): out = argv[i + 1]
		if argv[i] == "--tag" and i + 1 < argv.size(): tag = argv[i + 1]
		if argv[i] == "--only" and i + 1 < argv.size(): only = argv[i + 1]
		if argv[i] == "--timing" and i + 1 < argv.size(): timing = int(argv[i + 1])
		if argv[i] == "--seed" and i + 1 < argv.size(): seed_add = int(argv[i + 1])
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
	if mm_trial and (not new_board or only != "board"):
		printerr("planet v2 shots: --mm-trial needs the baked board path and --only board")
		quit(1)
		return
	if only == "" or only == "board":
		var kinds: Array = PL.MM_DETAIL_TILES.keys() if mm_trial else LOOK_KINDS
		for k in kinds:
			if not await _board(k, new_board):
				quit(1)
				return
	# the procedural stand-in a battle keeps when its maps miss the loading cover (Fable, PR 1776 H11)
	if new_board and (only == "" or only == "standin"):
		standin = true
		for k in LOOK_KINDS:
			await _board(k, new_board)
		standin = false
	if only == "" or only == "backdrop":
		for i in SKY.PLANETS.size():
			await _backdrop("backdrop_%d" % i, SKY.PLANETS[i], 4100 + i, BAKER.PLANET_SIZE, 1.0)
	# the eight remixed backdrop planets (PLANETS_ALT) answer to band 2 too: the alt volcanic sat at 0.017 in Wave 0
	if only == "" or only == "alt":
		for i in SKY.PLANETS_ALT.size():
			await _backdrop("backdrop_alt_%d" % i, SKY.PLANETS_ALT[i], 4100 + i, BAKER.PLANET_SIZE, 1.0)
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
		if mm_trial and tag == "after":
			quit(5)   # a completed trial with a failed grade, for the capture launcher's diagnostics
			return
	quit(0 if band_misses.is_empty() or tag == "before" else 1)

func _board(k: int, new_board: bool) -> bool:
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
	body_c = mi.position
	body_r = rad
	body_sun = SUN_DIR.normalized()
	var seed_v := 7 + k + seed_add
	if new_board:
		var pl_script: GDScript = load("res://world/world_planet.gd")
		if standin: mi.set_meta("planet_frozen", true)
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
	var material := mi.material_override as ShaderMaterial
	if mm_trial:
		var enabled := OS.get_environment("VS_MM_TRIAL") == "1"
		if material == null or material.get_shader_parameter("has_tex") != 1.0 \
				or (material.get_shader_parameter("mm_detail") == true) != enabled:
			printerr("planet v2 shots: baked surface or trial tile missing for ", PL.MM_DETAIL_TILES[k])
			return false
		material.set_shader_parameter("cloud_rate", 0.0)
	# camera 170 at the home view's angle, looking at the planet's cap on the board plane
	var t := Vector3(0, 0, 0)
	cam.position = t + Vector3(0, cos(0.98), sin(0.98)) * 170.0
	cam.look_at(t, Vector3.UP)
	var pre := ("standin" if standin else "board") + ("" if seed_add == 0 else "_s%d" % seed_add)
	var code := str(PL.MM_DETAIL_TILES[k]) if mm_trial else pre + "_%d" % k
	await _save(code + "_c170")
	if timing > 0 and not standin:
		await _time_frames("board_%d_c170" % k)
	if mm_trial:
		# At the stock limb distance the full-size bake's fine detail is already faded out.
		var direction := _trial_ground_direction(material, k)
		var focus := mi.position + direction * (rad - 8.0)
		cam.position = focus + direction * 26.0
		cam.look_at(focus, Vector3.UP)
		await _save(code + "_c26")
		return true
	# close: low over the lit limb
	var limb := Vector3(SUN_DIR.x, 0, SUN_DIR.z).normalized() * rad * 0.55
	cam.position = limb + Vector3(-0.35, 0.55, 0.85).normalized() * 70.0
	cam.look_at(limb + Vector3(0, -8, 0), Vector3.UP)
	await _save(code + "_close")
	return true


# Use the baked sea and cloud masks to frame clear, lit ground on the same face in both passes.
func _trial_ground_direction(material: ShaderMaterial, kind: int) -> Vector3:
	var albedo := (material.get_shader_parameter("tex_a") as Texture2D).get_image()
	var weather := (material.get_shader_parameter("tex_b") as Texture2D).get_image()
	var tilt := float(material.get_shader_parameter("tilt"))
	var turn := float(material.get_shader_parameter("turn"))
	var sun := SUN_DIR.normalized()
	var side := sun.cross(Vector3.UP).normalized()
	var up := side.cross(sun)
	var best := sun
	var best_score := INF
	# Side light shows Terran relief without filling the close view with the high-sun patch that missed on both legs.
	# Keep Volcanic's proven seed-5 framing. Pick from the same baked masks in both legs, never from rendered brightness.
	var terran: bool = PL.MM_DETAIL_TILES[kind] == "terran"
	var extent := 4 if terran else 2
	for y in range(-extent, extent + 1):
		for x in range(-extent, extent + 1):
			var n := (sun + (side * x + up * y) * 0.26).normalized()
			var sun_incidence := sun.dot(n)
			if terran and sun_incidence > 0.70:
				continue
			var tipped := n.rotated(Vector3.RIGHT, tilt)
			var d := tipped.rotated(Vector3.UP, turn)
			var u := fposmod(atan2(d.x, -d.z) / TAU + 0.5, 1.0)
			var v := acos(clampf(d.y, -1.0, 1.0)) / PI
			var px := Vector2i(int(u * albedo.get_width()), mini(int(v * albedo.get_height()), albedo.get_height() - 1))
			var score := albedo.get_pixelv(px).a * 3.0 + weather.get_pixelv(px).r + (1.0 - sun_incidence) * 0.3
			if score < best_score:
				best_score = score
				best = n
	return best


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
	body_c = Vector3.ZERO
	body_r = 1.0
	body_sun = sun
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
	if name.begins_with("moon_"):
		# Wave 0 (Nov 23): a moon is framed whole and centred, with its dark limb in view, so its outline reads round
		far = 3.3
	cam.position = Vector3(0, 0.25 if not name.begins_with("moon_") else 0.0, far)
	cam.look_at(Vector3.ZERO, Vector3.UP)
	await _save(name)
