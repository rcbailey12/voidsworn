extends Node
# Voidsworn A2 engine test, Godot half. Built to ../SPEC.md; README.md has the run lines.
#
# Modes (user arguments after "--"):
#   --bench out.json [--seconds 20]  3 s warm-up, then the battle orbit, then write the JSON and quit
#   --shots dir                      the five stills on a fixed clock, then quit
#   (none)                           free viewing: 1 battle orbit, 2 barge close-up, 3 breach close-up, Esc quits
# Other options: --res WxH (render size; always give it), --assets dir, --key energy, --fps N (clock rate for --shots,
#   default 60), --no-relaunch. Relative paths for --bench, --shots and --assets are taken relative to this project folder.

const FX := preload("res://fx.gd")

const SHIP_LEN := 24.0
const FOV := 40.0
const ORBIT_R := 150.0
const ORBIT_H := 70.0
# --stress (SPEC.md "Stress run"): 18 more ships at 0.6 scale in rows z = +60, 0, -60, loops staggered 0.17 s,
# the destruction event every 4 s, a wider orbit
const STRESS_ROWS := [60.0, 0.0, -60.0]
const STRESS_X := [-60.0, -36.0, -12.0, 12.0, 36.0, 60.0]
const STRESS_SCALE := 0.6
const STRESS_R := 190.0
const STRESS_H := 85.0
const AZ0 := 200.0
const AZ_SPAN := 120.0
const ORBIT_T := 20.0
const LOOK := Vector3(0, -5, 0)
const CAMS := {
	"corsair": [Vector3(20, 14, 58), Vector3(45, 0, 30)],
	"breach": [Vector3(12, 10, 52), Vector3(0, 2, 30)],
}
const WARMUP := 3.0
# The five stills (t = 0 when the scene starts), as SPEC.md lists them.
const SHOTS := [
	{"t": 2.0, "cam": "corsair", "file": "t02.0_barge_closeup.png"},
	{"t": 3.0, "cam": "breach", "file": "t03.0_breach_closeup.png"},
	{"t": 5.0, "cam": "battle", "file": "t05.0_battle.png"},
	{"t": 12.0, "cam": "battle", "file": "t12.0_battle.png"},
	{"t": 12.6, "cam": "battle", "file": "t12.6_destruction.png"},
]
# Key light energy: picked so the Hegemony hull (light grey) reads near-white but not clipped up close. Tune with --key.
const KEY_ENERGY := 2.4
const KEY_DIR := Vector3(-0.45, -0.70, -0.55)
const KEY_COL := Color(1.0, 0.96, 0.90)
const FILL_DIR := Vector3(0.6, -0.2, 0.75)
const FILL_COL := Color(0.55, 0.65, 0.85)

# Spec order (rows of three). Colours are linear RGB from ships3d.js FAC3D.
var SHIPS := [
	{"name": "Voidsworn", "files": ["V1b_r_23.glb"], "pos": Vector3(-45, 0, 30), "rot_y": 0.0,
		"weapon": Color(1.0, 0.45, 0.15), "shield": Color(1.0, 0.46, 0.16), "engine": Color(1.0, 0.50, 0.16)},
	{"name": "Hegemony", "files": ["H4_11.glb"], "pos": Vector3(0, 0, 30), "rot_y": 0.0,
		"weapon": Color(0.55, 0.82, 1.0), "shield": Color(0.38, 0.68, 1.0), "engine": Color(0.45, 0.72, 1.0)},
	{"name": "Corsair", "files": ["C19_51_shell.glb", "C19_51_kit.glb"], "pos": Vector3(45, 0, 30), "rot_y": 180.0,
		"weapon": Color(0.95, 0.22, 0.10), "shield": Color(0.85, 0.16, 0.10), "engine": Color(1.0, 0.38, 0.16)},
	{"name": "Chorus", "files": ["B16_23.glb"], "pos": Vector3(-45, 0, -30), "rot_y": 0.0,
		"weapon": Color(0.85, 0.90, 0.30), "shield": null, "engine": Color(0.80, 0.90, 0.28)},
	{"name": "Ithar", "files": ["I8_37.glb"], "pos": Vector3(0, 0, -30), "rot_y": 0.0,
		"weapon": Color(0.75, 1.0, 0.88), "shield": Color(0.72, 1.0, 0.86), "engine": Color(0.62, 1.0, 0.84)},
	{"name": "Deathless", "files": ["D22_23.glb"], "pos": Vector3(45, 0, -30), "rot_y": 0.0,
		"weapon": Color(0.20, 1.0, 0.38), "shield": null, "engine": Color(0.15, 1.0, 0.35)},
]

var args := {}
var mode := "view"
var stress := false
var orbit_r := ORBIT_R
var orbit_h := ORBIT_H
var notes: PackedStringArray = []
var res := Vector2i(1920, 1080)
var project_dir := ""
var assets_dir := ""

var vp: SubViewport
var world: Node3D
var cam: Camera3D
var env: Environment
var fx: Node3D
var ships_loaded := 0
var wreck_src := {}   # the Hegemony mesh and its surface arrays, for the destruction event

var started := false
var load_s := 0.0
var clock := 0.0
var frame_n := 0
var fixed_dt := 1.0 / 60.0
var view_cam := "battle"

# bench
var bench_secs := 20.0
var bench_on := false
var bench_last_us := 0
var frame_ms: PackedFloat64Array = []
var gpu_ms_sum := 0.0
var cpu_ms_sum := 0.0
var gpu_ms_n := 0
var gpu_mem_peak := 0.0

# shots
var shot_queue: Array = []
var shots_dir := ""
var shots_pending := 0


func _ready() -> void:
	project_dir = ProjectSettings.globalize_path("res://").trim_suffix("/")
	_parse_args()
	if args.has("bench"):
		mode = "bench"
	elif args.has("shots"):
		mode = "shots"
	stress = args.has("stress")
	if stress:
		orbit_r = STRESS_R
		orbit_h = STRESS_H
	res = _resolve_res()
	if mode == "shots" and not args.has("no-relaunch"):
		# Godot consumes its own options, so --fixed-fps cannot be read back; a fixed clock shows as an exact frame delta.
		await get_tree().process_frame
		await get_tree().process_frame
		var fps := float(args.get("fps", "60"))
		if absf(get_process_delta_time() - 1.0 / fps) > 1e-7:
			_relaunch_with_fixed_fps(int(fps))
			return
	assets_dir = _abs_path(args.get("assets", project_dir.get_base_dir().path_join("assets")))
	if args.has("seconds"):
		bench_secs = float(args["seconds"])
	if args.has("fps"):
		fixed_dt = 1.0 / float(args["fps"])
	print("[enginetest] mode=%s renderer=%s driver=%s res=%dx%d assets=%s" % [mode, RenderingServer.get_current_rendering_method(),
		RenderingServer.get_current_rendering_driver_name(), res.x, res.y, assets_dir])

	_build_viewport()
	_build_environment()
	_build_ships()
	var list: Array = SHIPS
	var opts := {}
	if stress:
		list = SHIPS + _stress_copies()
		opts = {"stagger": 0.17, "boom_every": 4.0}
		notes.append("stress run: 24 ships (18 at 0.6 scale), loops staggered 0.17 s, destruction every 4 s, orbit radius 190 height 85")
	fx = FX.new()
	fx.name = "FX"
	world.add_child(fx)
	var t0 := Time.get_ticks_usec()
	fx.setup(list, wreck_src, mode == "shots", RenderingServer.get_current_rendering_method() == "gl_compatibility", opts)
	for n in fx.notes:
		notes.append(n)
	print("[enginetest] effects built in %.0f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	fx.update(0.0)
	_place_camera(0.0)
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		notes.append("Compatibility renderer: same scene and settings as Forward+ (glow, ACES, 4-split shadows, GPUParticles3D, omni lights); the breach scorch is a projected disc instead of a Decal")

	# load_s: engine start (Time ticks begin at engine init, a few ms after the process starts) to the end of the
	# first frame drawn with all six ships and the sky in the scene.
	await _frame_drawn()
	load_s = Time.get_ticks_usec() / 1e6
	print("[enginetest] first full frame at %.3f s, %d of 6 ships" % [load_s, ships_loaded])
	started = true
	if mode == "shots":
		shots_dir = _abs_path(args["shots"])
		DirAccess.make_dir_recursive_absolute(shots_dir)
		shot_queue = SHOTS.duplicate(true)


func _process(delta: float) -> void:
	if not started:
		return
	if mode == "shots":
		_process_shots()
	elif mode == "bench":
		_process_bench(delta)
	else:
		clock += delta
		_set_cam(view_cam, fmod(clock, ORBIT_T))
		fx.update(clock)


func _process_bench(delta: float) -> void:
	clock += delta
	var now := Time.get_ticks_usec()
	if clock < WARMUP:
		_place_camera(0.0)
	else:
		var tb := clock - WARMUP
		if not bench_on:
			bench_on = true
			bench_last_us = now
			RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
			print("[enginetest] warm-up done, measuring %.0f s" % bench_secs)
		else:
			frame_ms.append((now - bench_last_us) / 1000.0)
			bench_last_us = now
			var g := RenderingServer.viewport_get_measured_render_time_gpu(vp.get_viewport_rid())
			if g > 0.0:
				gpu_ms_sum += g
				cpu_ms_sum += RenderingServer.viewport_get_measured_render_time_cpu(vp.get_viewport_rid())
				gpu_ms_n += 1
			gpu_mem_peak = maxf(gpu_mem_peak, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
		if tb >= bench_secs:
			_finish_bench()
			return
		# the orbit always spans the measured run (20 s by default, as the spec has it)
		_place_camera(clampf(tb / maxf(bench_secs, 0.001), 0.0, 1.0) * ORBIT_T)
	fx.update(clock)


func _process_shots() -> void:
	clock = frame_n * fixed_dt
	frame_n += 1
	if shot_queue.is_empty():
		return
	var s: Dictionary = shot_queue[0]
	_set_cam(s["cam"], minf(clock, ORBIT_T))
	fx.update(clock)
	# The still is taken on the frame whose clock reaches the target time (frames are fixed_dt apart).
	if clock + fixed_dt * 0.5 >= float(s["t"]):
		shot_queue.pop_front()
		_capture(shots_dir.path_join(s["file"]), clock)


func _capture(path: String, t: float) -> void:
	shots_pending += 1
	await _frame_drawn()
	var img: Image = null
	if DisplayServer.get_name() != "headless":
		img = vp.get_texture().get_image()
	if img == null or img.is_empty():
		print("[enginetest] no image for %s (headless or no renderer)" % path)
	else:
		img.convert(Image.FORMAT_RGB8)  # the view's alpha is not coverage; drop it so the PNG is opaque
		img.save_png(path)
		print("[enginetest] wrote %s at t=%.3f (%dx%d)" % [path, t, img.get_width(), img.get_height()])
	shots_pending -= 1
	if shot_queue.is_empty() and shots_pending == 0:
		get_tree().quit()


func _finish_bench() -> void:
	started = false
	var n := frame_ms.size()
	var sorted := frame_ms.duplicate()
	sorted.sort()
	var total := 0.0
	for v in frame_ms:
		total += v
	var avg := total / maxf(n, 1)
	var k := maxi(1, int(ceil(n * 0.01)))
	var worst := 0.0
	for i in k:
		worst += sorted[n - 1 - i] if n > i else 0.0
	worst /= k
	var mem_now := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	if gpu_ms_n > 0:
		notes.append("engine-measured 3D render time per frame: GPU %.2f ms, CPU %.2f ms" % [gpu_ms_sum / gpu_ms_n, cpu_ms_sum / gpu_ms_n])
	notes.append("adapter %s, driver %s %s" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_driver_name(),
		RenderingServer.get_video_adapter_api_version()])
	notes.append("render target %dx%d (%s) in a SubViewport with MSAA 4x, shown in a %dx%d window" % [res.x, res.y,
		"from --res" if args.has("res") else "window size, no --res given", get_window().size.x, get_window().size.y])
	notes.append("vsync mode %d (0 = off)" % DisplayServer.window_get_vsync_mode())
	notes.append("gpu_mem_mb is Performance RENDER_VIDEO_MEM_USED at the end (peak during run %.0f MB)" % (gpu_mem_peak / 1048576.0))
	notes.append("textures loaded uncompressed (RGB8 with mipmaps), as GLTFDocument gives them at runtime")
	var out := {
		"engine": "godot",
		"renderer": RenderingServer.get_current_rendering_method(),
		"width": res.x, "height": res.y,
		"seconds": bench_secs,
		"frames": n,
		"avg_ms": snappedf(avg, 0.001),
		"p99_ms": snappedf(worst, 0.001),
		"max_ms": snappedf(sorted[n - 1] if n > 0 else 0.0, 0.001),
		"fps_avg": snappedf(1000.0 / avg if avg > 0.0 else 0.0, 0.01),
		"load_s": snappedf(load_s, 0.001),
		"gpu_mem_mb": snappedf(mem_now / 1048576.0, 0.1),
		"notes": "; ".join(notes),
	}
	if stress:
		var tagged := {}
		for key in out:
			tagged[key] = out[key]
			if key == "renderer":
				tagged["mode"] = "stress"
		out = tagged
	var path := _abs_path(args["bench"])
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot write %s" % path)
	else:
		f.store_string(JSON.stringify(out, "  ", false) + "\n")
		f.close()
	print("[enginetest] wrote ", path)
	print(JSON.stringify(out, "", false))
	get_tree().quit()


# ---------------------------------------------------------------- scene

func _build_viewport() -> void:
	vp = SubViewport.new()
	vp.name = "Render"
	vp.size = res
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	add_child(vp)
	var show := TextureRect.new()
	show.name = "Show"
	show.texture = vp.get_texture()
	show.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	show.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	show.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(show)
	world = Node3D.new()
	world.name = "World"
	vp.add_child(world)
	cam = Camera3D.new()
	cam.name = "Camera"
	cam.fov = FOV
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.near = 0.5
	cam.far = 3000.0
	world.add_child(cam)
	cam.current = true


func _build_environment() -> void:
	env = Environment.new()
	var sky_path := _find_starfield()
	if sky_path != "":
		var img := Image.load_from_file(sky_path)
		var pano := PanoramaSkyMaterial.new()
		pano.panorama = ImageTexture.create_from_image(img)
		pano.filter = true
		var sky := Sky.new()
		sky.sky_material = pano
		sky.radiance_size = Sky.RADIANCE_SIZE_256
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	else:
		notes.append("starfield_4k.png not found, black background")
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color.BLACK
	var key_e := float(args.get("key", KEY_ENERGY))
	# Ambient: neutral, 0.25 of the key (the starfield is too dark to light anything by itself).
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.25 * key_e
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	# Godot divides its ACES curve by the curve's value at the white point; the default white of 1.0 clips everything
	# above 1.0. 8.0 puts the normalisation near 1, close to the plain ACES fit Babylon uses.
	env.tonemap_white = 8.0
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.8
	env.glow_intensity = 0.8
	env.glow_strength = 1.0
	env.glow_bloom = 0.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	var key := DirectionalLight3D.new()
	key.name = "Key"
	key.transform = Transform3D(Basis.looking_at(KEY_DIR.normalized(), Vector3.UP), Vector3.ZERO)
	key.light_color = KEY_COL
	key.light_energy = key_e
	key.light_specular = 1.0
	key.shadow_enabled = true
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	key.directional_shadow_max_distance = 300.0
	world.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.name = "Fill"
	fill.transform = Transform3D(Basis.looking_at(FILL_DIR.normalized(), Vector3.UP), Vector3.ZERO)
	fill.light_color = FILL_COL
	fill.light_energy = 0.25 * key_e
	fill.light_specular = 1.0
	fill.shadow_enabled = false
	world.add_child(fill)


func _find_starfield() -> String:
	for p in [project_dir.get_base_dir().path_join("starfield_4k.png"), assets_dir.path_join("starfield_4k.png"),
			project_dir.path_join("starfield_4k.png")]:
		if FileAccess.file_exists(p):
			return p
	return ""


func _build_ships() -> void:
	for i in SHIPS.size():
		var s: Dictionary = SHIPS[i]
		var model := Node3D.new()
		model.name = "model"
		var parts := 0
		var pts := PackedVector3Array()
		var nrm := PackedVector3Array()
		for f in s["files"]:
			var r := _load_gltf(assets_dir.path_join(f), s["name"] == "Hegemony")
			if r.is_empty():
				continue
			model.add_child(r["node"])
			pts.append_array(r["pts"])
			nrm.append_array(r["nrm"])
			parts += 1
			if r.has("surfs"):
				wreck_src = {"surfs": r["surfs"]}
		var root := Node3D.new()
		root.name = s["name"]
		root.position = s["pos"]
		var pivot := Node3D.new()
		pivot.name = "pivot"
		root.add_child(pivot)
		pivot.add_child(model)
		world.add_child(root)
		s["root"] = root
		s["model"] = model
		s["meshes"] = _mesh_instances(model)
		var box := _subtree_aabb(model, Transform3D.IDENTITY)
		if parts == 0 or box.size.x <= 0.0:
			notes.append("%s missing" % s["name"])
			s["half"] = Vector3(12, 3, 3)
			_default_points(s)
			continue
		if parts == s["files"].size():
			ships_loaded += 1
		var k := SHIP_LEN / box.size.x
		var rot := Basis(Vector3.UP, deg_to_rad(s["rot_y"]))
		model.position = -box.get_center()
		pivot.basis = rot.scaled(Vector3(k, k, k))
		s["pivot_basis"] = pivot.basis
		s["half"] = box.size * k * 0.5
		if s["name"] == "Hegemony":
			wreck_src["center"] = box.get_center()
			wreck_src["scale"] = k
			wreck_src["mesh"] = (s["meshes"][0] as MeshInstance3D).mesh if s["meshes"].size() > 0 else null
		# hull points in the ship's own frame (bow +x, centred, 24 long), for where the effects sit on the hull
		var lp := PackedVector3Array()
		var ln := PackedVector3Array()
		lp.resize(pts.size())
		ln.resize(pts.size())
		var c := box.get_center()
		for j in pts.size():
			lp[j] = rot * ((pts[j] - c) * k)
			ln[j] = (rot * nrm[j]).normalized()
		_hull_points(s, lp, ln)
		s["pts"] = lp
		s["nrm"] = ln
		print("[enginetest] %s: %s, length %.3f -> scale %.2f, half %s" % [s["name"], ", ".join(s["files"]), box.size.x, k, s["half"]])


# Where the effects sit on each hull, from the hull's own vertices: engine nozzles at the stern, four broadside guns on
# the port side, the beam emitter at the bow, the breach on the upper port flank, the hit point on the starboard side.
func _hull_points(s: Dictionary, p: PackedVector3Array, n: PackedVector3Array) -> void:
	var h: Vector3 = s["half"]
	# stern: the rearmost slice
	var cy := 0.0
	var cz := 0.0
	var zmin := 1e9
	var zmax := -1e9
	var cnt := 0
	for j in p.size():
		if p[j].x < -h.x + 1.2:
			cy += p[j].y
			cz += p[j].z
			zmin = minf(zmin, p[j].z)
			zmax = maxf(zmax, p[j].z)
			cnt += 1
	if cnt > 0:
		cy /= cnt
		cz /= cnt
	var spread := zmax - zmin if cnt > 0 else 0.0
	var noz: Array = []
	if spread > 3.0:
		noz = [Vector3(-h.x - 0.2, cy, cz - spread * 0.22), Vector3(-h.x - 0.2, cy, cz + spread * 0.22)]
	else:
		noz = [Vector3(-h.x - 0.2, cy, cz)]
	s["nozzles"] = noz
	s["noz_size"] = clampf(maxf(spread, h.y) * 0.18, 0.8, 2.2)
	# bow emitter
	var by := 0.0
	var bz := 0.0
	cnt = 0
	for j in p.size():
		if p[j].x > h.x - 1.0:
			by += p[j].y
			bz += p[j].z
			cnt += 1
	s["bow"] = Vector3(h.x + 0.3, by / cnt if cnt > 0 else 0.0, bz / cnt if cnt > 0 else 0.0)
	# broadside guns: the outermost port point near each gun station, kept near the waist
	var guns: Array = []
	var gun_n: Array = []
	for gx in [-6.0, -2.0, 2.0, 6.0]:
		var best := -1
		for j in p.size():
			if absf(p[j].x - gx) < 1.2 and absf(p[j].y) < h.y * 0.6 and n[j].z > 0.3:
				if best < 0 or p[j].z > p[best].z:
					best = j
		if best >= 0:
			guns.append(p[best] + n[best] * 0.2)
			gun_n.append(Vector3(0.0, 0.15, 1.0).normalized())
		else:
			guns.append(Vector3(gx, 0, h.z))
			gun_n.append(Vector3(0, 0.15, 1).normalized())
	s["guns"] = guns
	s["gun_n"] = gun_n
	# breach: upper port flank of the main hull (not the superstructure), a little forward of midships
	var bi := -1
	var bscore := -1e9
	for j in p.size():
		if p[j].x > -3.0 and p[j].x < 5.0 and p[j].y > h.y * 0.05 and p[j].y < h.y * 0.5 and n[j].z > 0.55:
			var sc := p[j].z + p[j].y * 0.3
			if sc > bscore:
				bscore = sc
				bi = j
	if bi >= 0:
		s["breach"] = p[bi]
		s["breach_n"] = n[bi]
	else:
		s["breach"] = Vector3(1, h.y * 0.5, h.z * 0.8)
		s["breach_n"] = Vector3(0, 0.5, 1).normalized()
	# starboard hit point
	var hi := -1
	for j in p.size():
		if absf(p[j].x - 2.0) < 2.0 and absf(p[j].y) < h.y * 0.5:
			if hi < 0 or p[j].z < p[hi].z:
				hi = j
	s["hit"] = p[hi] if hi >= 0 else Vector3(2, 0, -h.z)


# The stress run's 18 extra ships: copies of the loaded flagships (the meshes are shared, not loaded again) at 0.6 scale.
func _stress_copies() -> Array:
	var out: Array = []
	for z in STRESS_ROWS:
		for j in STRESS_X.size():
			var src: Dictionary = SHIPS[j]
			var c := {"name": src["name"], "files": src["files"], "weapon": src["weapon"], "shield": src["shield"],
				"engine": src["engine"], "pos": Vector3(STRESS_X[j], 0, z), "rot_y": src["rot_y"], "scale": STRESS_SCALE}
			var root := Node3D.new()
			root.name = "%s_copy_%d" % [src["name"], out.size()]
			root.position = c["pos"]
			var pivot := Node3D.new()
			root.add_child(pivot)
			world.add_child(root)
			c["root"] = root
			if not src.has("model") or not src.has("pivot_basis"):
				c["half"] = Vector3(12, 3, 3) * STRESS_SCALE
				c["meshes"] = []
				_default_points(c)
				out.append(c)
				continue
			var model: Node3D = (src["model"] as Node3D).duplicate()
			pivot.add_child(model)
			pivot.basis = (src["pivot_basis"] as Basis).scaled(Vector3.ONE * STRESS_SCALE)
			c["meshes"] = _mesh_instances(model)
			c["half"] = (src["half"] as Vector3) * STRESS_SCALE
			var lp := PackedVector3Array()
			var sp: PackedVector3Array = src["pts"]
			lp.resize(sp.size())
			for i in sp.size():
				lp[i] = sp[i] * STRESS_SCALE
			c["pts"] = lp
			c["nrm"] = src["nrm"]
			_hull_points(c, lp, src["nrm"])
			out.append(c)
	return out


func _default_points(s: Dictionary) -> void:
	var h: Vector3 = s["half"]
	s["nozzles"] = [Vector3(-h.x, 0, 0)]
	s["noz_size"] = 1.0
	s["bow"] = Vector3(h.x, 0, 0)
	s["guns"] = [Vector3(-6, 0, h.z), Vector3(-2, 0, h.z), Vector3(2, 0, h.z), Vector3(6, 0, h.z)]
	s["gun_n"] = [Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1)]
	s["breach"] = Vector3(1, h.y * 0.5, h.z * 0.8)
	s["breach_n"] = Vector3(0, 0.5, 1).normalized()
	s["hit"] = Vector3(2, 0, -h.z)


# Runtime glTF load (no import step). Three fixes on top of plain GLTFDocument, each to match what the glTF spec asks for:
#  1. a material whose maps all use TEXCOORD_1 gets its UV sets swapped (StandardMaterial3D samples the normal map on UV1 only),
#     with tangents rebuilt on the new UV1;
#  2. textures get mipmaps (GLTFDocument leaves runtime images without them);
#  3. COLOR_0 multiplies base colour (Godot leaves vertex colours off).
# Also returns a sample of the hull's vertices (glTF frame) and, if asked, the surface arrays.
func _load_gltf(path: String, keep_surfs: bool) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("missing " + path)
		notes.append("missing " + path.get_file())
		return {}
	var t0 := Time.get_ticks_usec()
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	st.handle_binary_image_mode = GLTFState.HANDLE_BINARY_IMAGE_MODE_EMBED_AS_UNCOMPRESSED
	var err := doc.append_from_file(path, st)
	if err != OK:
		push_error("glTF load failed %s (%d)" % [path, err])
		notes.append("failed " + path.get_file())
		return {}
	var t1 := Time.get_ticks_usec()
	_fix_uv_sets(st)
	_fix_vertex_colors(st)
	_add_mipmaps(st)
	var out := {"pts": PackedVector3Array(), "nrm": PackedVector3Array()}
	var surfs: Array = []
	for gm in st.get_meshes():
		var im: ImporterMesh = gm.mesh
		for si in im.get_surface_count():
			var arr: Array = im.get_surface_arrays(si)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
			var step := maxi(1, v.size() / 20000)
			for j in range(0, v.size(), step):
				out["pts"].append(v[j])
				out["nrm"].append(nn[j] if j < nn.size() else Vector3.UP)
			if keep_surfs:
				surfs.append([arr, im.get_surface_material(si)])
	if keep_surfs:
		out["surfs"] = surfs
	var t2 := Time.get_ticks_usec()
	out["node"] = doc.generate_scene(st) as Node3D
	print("[enginetest]   %s: parse %.0f ms, fixes %.0f ms, scene %.0f ms" % [path.get_file(), (t1 - t0) / 1000.0, (t2 - t1) / 1000.0,
		(Time.get_ticks_usec() - t2) / 1000.0])
	return out


func _fix_uv_sets(st: GLTFState) -> void:
	var js: Dictionary = st.json
	var jmats: Array = js.get("materials", [])
	var gmats: Array = st.get_materials()
	var swap := {}
	for mi in jmats.size():
		var m: Dictionary = jmats[mi]
		var sets: Array = []
		for key in ["normalTexture", "occlusionTexture", "emissiveTexture"]:
			if m.has(key):
				sets.append(int(m[key].get("texCoord", 0)))
		var pbr: Dictionary = m.get("pbrMetallicRoughness", {})
		for key in ["baseColorTexture", "metallicRoughnessTexture"]:
			if pbr.has(key):
				sets.append(int(pbr[key].get("texCoord", 0)))
		if sets.is_empty() or mi >= gmats.size():
			continue
		if sets.all(func(v): return v == 1):
			swap[gmats[mi]] = true
		elif sets.has(1):
			notes.append("%s: material %d mixes UV sets, left as Godot loads it" % [st.filename, mi])
	if swap.is_empty():
		return
	for gm in st.get_meshes():
		var im: ImporterMesh = gm.mesh
		var surfs: Array = []
		var touched := false
		for si in im.get_surface_count():
			var mat: Material = im.get_surface_material(si)
			var arr: Array = im.get_surface_arrays(si)
			var prim := im.get_surface_primitive_type(si)
			if swap.has(mat) and arr[Mesh.ARRAY_TEX_UV2] != null:
				var u = arr[Mesh.ARRAY_TEX_UV]
				arr[Mesh.ARRAY_TEX_UV] = arr[Mesh.ARRAY_TEX_UV2]
				arr[Mesh.ARRAY_TEX_UV2] = u
				arr[Mesh.ARRAY_TANGENT] = null
				var tool := SurfaceTool.new()
				tool.create_from_arrays(arr, prim)
				tool.generate_tangents()
				arr = tool.commit_to_arrays()
				if mat is BaseMaterial3D:
					(mat as BaseMaterial3D).ao_on_uv2 = false
				touched = true
			surfs.append([prim, arr, mat, im.get_surface_name(si)])
		if not touched:
			continue
		im.clear()
		for e in surfs:
			im.add_surface(e[0], e[1], [], {}, e[2], e[3])


func _fix_vertex_colors(st: GLTFState) -> void:
	for gm in st.get_meshes():
		var im: ImporterMesh = gm.mesh
		for si in im.get_surface_count():
			var arr: Array = im.get_surface_arrays(si)
			var mat := im.get_surface_material(si) as BaseMaterial3D
			if arr[Mesh.ARRAY_COLOR] != null and mat != null:
				mat.vertex_color_use_as_albedo = true


func _add_mipmaps(st: GLTFState) -> void:
	for tex in st.get_images():
		if tex is ImageTexture:
			var img: Image = tex.get_image()
			if img != null and not img.is_empty() and not img.has_mipmaps():
				img.generate_mipmaps()
				(tex as ImageTexture).set_image(img)


func _mesh_instances(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is MeshInstance3D:
			out.append(c)
		out.append_array(_mesh_instances(c))
	return out


func _subtree_aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var has := false
	for c in n.get_children():
		var cxf := xf
		if c is Node3D:
			cxf = xf * (c as Node3D).transform
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var b := cxf * (c as MeshInstance3D).get_aabb()
			out = b if not has else out.merge(b)
			has = true
		var sub := _subtree_aabb(c, cxf)
		if sub.size != Vector3.ZERO:
			out = sub if not has else out.merge(sub)
			has = true
	return out


func _set_cam(which: String, t: float) -> void:
	if CAMS.has(which):
		var c: Array = CAMS[which]
		cam.transform = Transform3D(Basis.looking_at(c[1] - c[0], Vector3.UP), c[0])
	else:
		_place_camera(t)


func _place_camera(t: float) -> void:
	var az := deg_to_rad(AZ0 + AZ_SPAN * clampf(t / ORBIT_T, 0.0, 1.0))
	var p := Vector3(orbit_r * cos(az), orbit_h, orbit_r * sin(az))
	cam.transform = Transform3D(Basis.looking_at(LOOK - p, Vector3.UP), p)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_1:
				view_cam = "battle"
			KEY_2:
				view_cam = "corsair"
			KEY_3:
				view_cam = "breach"
			KEY_ESCAPE:
				get_tree().quit()


# ---------------------------------------------------------------- helpers

func _frame_drawn() -> void:
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw


func _parse_args() -> void:
	var ua := OS.get_cmdline_user_args()
	var i := 0
	while i < ua.size():
		var a: String = ua[i]
		if a.begins_with("--"):
			var key := a.substr(2)
			if i + 1 < ua.size() and not String(ua[i + 1]).begins_with("--"):
				args[key] = ua[i + 1]
				i += 2
				continue
			args[key] = "1"
		i += 1


# Render size: the user option --res WxH. Godot consumes its own --resolution (it only sizes the window, which the OS may
# shrink to fit the screen), so --res is what fixes the render size; without it the window size is used.
func _resolve_res() -> Vector2i:
	var parts := String(args.get("res", "")).split("x")
	if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
		return Vector2i(int(parts[0]), int(parts[1]))
	return get_window().size


func _abs_path(p: String) -> String:
	if p.is_absolute_path():
		return p
	return project_dir.path_join(p).simplify_path()


# --shots needs a fixed clock for the particles too, which only the engine's --fixed-fps gives. If it was left off,
# run again with it (same renderer, size and user options) and wait, so a job that waits on this process still gets its stills.
func _relaunch_with_fixed_fps(fps: int) -> void:
	var a: PackedStringArray = ["--path", project_dir, "--rendering-method", RenderingServer.get_current_rendering_method(),
		"--rendering-driver", RenderingServer.get_current_rendering_driver_name(),
		"--resolution", "%dx%d" % [get_window().size.x, get_window().size.y], "--fixed-fps", str(fps)]
	if DisplayServer.get_name() == "headless":
		a.append("--headless")
	a.append("--")
	for x in OS.get_cmdline_user_args():
		a.append(x)
	if not args.has("res"):
		a.append("--res")
		a.append("%dx%d" % [res.x, res.y])
	a.append("--no-relaunch")
	print("[enginetest] --shots without --fixed-fps: running again with --fixed-fps %d" % fps)
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(), a, out, true)
	for line in out:
		print(line)
	get_tree().quit(code)
