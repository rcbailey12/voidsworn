extends Node
# Voidsworn A2 engine test, Godot half. Built to ../SPEC.md; README.md has the run lines.
#
# Run modes (user arguments after "--"):
#   --bench out.json [--seconds 20]  3 s warm-up, then the battle orbit, then write the JSON and quit
#   --shots dir                      the stills for the chosen scene on a fixed clock, then quit
#   (neither)                        free viewing: 1 battle orbit, 2 barge close-up, 3 breach close-up, Esc quits
# Scenes (combine with either run mode; README.md lists the PC lines):
#   (default) the six-ship main scene      --stress  24 ships      --ships 40  40 ships (any N of 24 or more works)
#   --max     the six ships with rich effects (more lights, volumetric fog, soft particles, parallax breach holes),
#             Godot's best lighting (SSAO, SSIL, SSR, SDFGI, TAA, detail normals), Jolt rigid-body debris and chunks,
#             depth of field on the close-ups, weight-scaled shake and colour grading
#   --physics Jolt debris and chunks alone  --rich  the rich effects alone
#   --board   the game slice: hex board at game scale, top-down camera, native UI labels and bars, hover and click
#   --vsync   capped run: vsync on, reports dropped frames
# Other options: --res WxH (render size; always give it), --assets dir, --key energy, --hex size, --fps N (clock rate for
#   --shots, default 60), --no-relaunch. Relative paths for --bench, --shots and --assets are taken relative to this folder.

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
const HERO_CODES := ["V1b_r_23", "H4_11", "C19_51", "B16_23", "I8_37", "D22_23"]
const PHYS := preload("res://physics.gd")
const BOARD := preload("res://board.gd")
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
const KEY_ENERGY := 2.0
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
var n_ships := 6
var opt_rich := false
var opt_max := false
var opt_board := false
var opt_vsync := false
var opt_physics := false
var mode_name := "main"
var hi_dir := ""
var all_ships: Array = []
var phys: Node3D = null
var board: Node = null
var key_light: DirectionalLight3D
var light_n := 0
var light_sum := 0.0
var light_max := 0
var phys_ms: PackedFloat64Array = []
var body_max := 0
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
var proc_ms: PackedFloat64Array = []
var frame_t: PackedFloat64Array = []
var prewarm_s := 0.0
var last_script_ms := 0.0

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
	_read_scene_options()
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
	if opt_max:
		if DirAccess.dir_exists_absolute(assets_dir.path_join("hi")):
			hi_dir = assets_dir.path_join("hi")
			notes.append("max mode: ships from assets/hi where present")
		else:
			notes.append("max mode: assets/hi not found, today's assets used")
	if args.has("seconds"):
		bench_secs = float(args["seconds"])
	if args.has("fps"):
		fixed_dt = 1.0 / float(args["fps"])
	print("[enginetest] mode=%s scene=%s ships=%d renderer=%s driver=%s res=%dx%d assets=%s" % [mode, mode_name, n_ships,
		RenderingServer.get_current_rendering_method(), RenderingServer.get_current_rendering_driver_name(), res.x, res.y, assets_dir])
	if opt_vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)

	_build_viewport()
	_build_environment()
	_apply_quality()
	_build_ships()
	var list: Array = SHIPS
	var opts := {}
	if stress:
		list = SHIPS + _stress_copies()
		opts = {"stagger": 0.17, "boom_every": 4.0}
		notes.append("%d ships (%d at 0.6 scale), loops staggered 0.17 s, destruction every 4 s, orbit radius %.0f height %.0f" % [
			n_ships, n_ships - 6, orbit_r, orbit_h])
	opts["rich"] = opt_rich or opt_max
	opts["max"] = opt_max
	all_ships = list
	fx = FX.new()
	fx.name = "FX"
	world.add_child(fx)
	if opt_physics:
		phys = PHYS.new()
		phys.name = "Physics"
		world.add_child(phys)
		phys.setup(list, 600)
		fx.phys = phys
	var t0 := Time.get_ticks_usec()
	fx.setup(list, wreck_src, mode == "shots", RenderingServer.get_current_rendering_method() == "gl_compatibility", opts)
	for n in fx.notes:
		notes.append(n)
	print("[enginetest] effects built in %.0f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	if opt_max:
		_apply_presentation()
	if opt_board:
		board = BOARD.new()
		board.name = "Board"
		add_child(board)
		board.setup(vp, world, cam, list, res, float(args.get("hex", "20.0")), mode == "shots")
	fx.update(0.0)
	_set_cam(_default_cam(), 0.0)
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		notes.append("Compatibility renderer: same scene and settings as Forward+ (glow, ACES, 4-split shadows, GPUParticles3D, omni lights); the breach scorch is a projected disc instead of a Decal")

	# load_s: engine start (Time ticks begin at engine init, a few ms after the process starts) to the end of the
	# first frame drawn with all six ships and the sky in the scene.
	await _frame_drawn()
	load_s = Time.get_ticks_usec() / 1e6
	print("[enginetest] first full frame at %.3f s, %d of 6 ships" % [load_s, ships_loaded])
	await _prewarm()
	started = true
	if mode == "shots":
		shots_dir = _abs_path(args["shots"])
		DirAccess.make_dir_recursive_absolute(shots_dir)
		shot_queue = _shot_list()


func _process(delta: float) -> void:
	if not started:
		return
	if mode == "shots":
		_process_shots()
	elif mode == "bench":
		_process_bench(delta)
	else:
		clock += delta
		fx.update(clock)
		_set_cam(view_cam if not opt_board else _default_cam(), fmod(clock, ORBIT_T))
		if board != null:
			board.update(clock, board.mouse_from_window(get_viewport().get_mouse_position(), get_window().size))


func _process_bench(delta: float) -> void:
	clock += delta
	var now := Time.get_ticks_usec()
	if clock >= WARMUP:
		var tb := clock - WARMUP
		if bench_on:
			_sample_stats()
		if not bench_on:
			bench_on = true
			bench_last_us = now
			RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
			print("[enginetest] warm-up done, measuring %.0f s" % bench_secs)
		else:
			frame_ms.append((now - bench_last_us) / 1000.0)
			frame_t.append(clock)
			proc_ms.append(last_script_ms)
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
	var su := Time.get_ticks_usec()
	fx.update(clock)
	last_script_ms = (Time.get_ticks_usec() - su) / 1000.0
	if clock >= WARMUP:
		# the orbit always spans the measured run (20 s by default, as the spec has it)
		_set_cam(_default_cam(), clampf((clock - WARMUP) / maxf(bench_secs, 0.001), 0.0, 1.0) * ORBIT_T)
	else:
		_set_cam(_default_cam(), 0.0)
	if board != null:
		board.update(clock, board.scripted_mouse(clock))


func _process_shots() -> void:
	# The clock follows the engine's (fixed, --fixed-fps) frame step, so Engine.time_scale (the cine slow motion, and the
	# holds that take several stills at one moment) slows the clock, the particles and the physics together.
	if frame_n > 0:
		clock += get_process_delta_time()
	frame_n += 1
	if shot_queue.is_empty():
		return
	var s: Dictionary = shot_queue[0]
	fx.update(clock)
	_set_cam(s["cam"], minf(clock, ORBIT_T))
	if board != null:
		board.update(clock, board.scripted_mouse(clock))
	# The still is taken on the frame whose clock reaches the target time (frames are fixed_dt apart).
	if clock + fixed_dt * 0.5 >= float(s["t"]):
		shot_queue.pop_front()
		# more stills at the same moment: hold the clock (time scale 0) until they are taken
		if not shot_queue.is_empty() and absf(float(shot_queue[0]["t"]) - float(s["t"])) < 1e-4:
			Engine.time_scale = 0.0
		else:
			Engine.time_scale = 1.0
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
	for nn in fx.notes:
		if not notes.has(nn):
			notes.append(nn)
	var ptot := 0.0
	for v in proc_ms:
		ptot += v
	notes.append("effect script per frame (fx.update: ship drift, phase groups, particle triggers, lights) %.3f ms average" % (ptot / maxf(proc_ms.size(), 1)))
	if gpu_ms_n > 0:
		notes.append("engine-measured 3D render time per frame: GPU %.2f ms, render CPU %.2f ms" % [gpu_ms_sum / gpu_ms_n, cpu_ms_sum / gpu_ms_n])
	notes.append("shader warm-up after load took %.1f s (every effect, fade and chunk state drawn once, until pipeline compiles stop)" % prewarm_s)
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
	var tagged := {}
	for key in out:
		tagged[key] = out[key]
		if key == "renderer":
			tagged["mode"] = mode_name
			tagged["ships"] = n_ships
	out = tagged
	out.merge(_extra_results(sorted), false)
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
	_write_trace(path.get_basename() + "_trace.json")
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
		# The starfield as a panorama (same mapping as PanoramaSkyMaterial), capped just under the glow threshold so the
		# stars are not bloomed into larger, brighter dots than the PNG has.
		var sh := Shader.new()
		sh.code = "shader_type sky;\nuniform sampler2D pano : source_color, filter_linear, repeat_enable;\nvoid sky() {\n\tCOLOR = min(texture(pano, SKY_COORDS).rgb, vec3(0.78));\n}\n"
		var pano := ShaderMaterial.new()
		pano.shader = sh
		pano.set_shader_parameter("pano", ImageTexture.create_from_image(img))
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
	key_light = key
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
	if (opt_max or opt_board) and FileAccess.file_exists(assets_dir.path_join("env/sky_deadstar_8k.png")):
		notes.append("sky: env/sky_deadstar_8k.png")
		return assets_dir.path_join("env/sky_deadstar_8k.png")
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
			var path := assets_dir.path_join(f)
			if hi_dir != "" and FileAccess.file_exists(hi_dir.path_join(f)):
				path = hi_dir.path_join(f)
			var r := _load_gltf(path, s["name"] == "Hegemony")
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


# ---------------------------------------------------------------- warm-up and trace

# Before the measured window, draw every material and pipeline variant once: all effect groups shown, every particle
# system fired, the hulls and chunks half transparent (the drift fade and chunk fade states), at several clock times,
# then keep drawing until Godot's pipeline compile counters stop moving. The engine's shader and pipeline caches
# (on by default) keep the results for the next run.
func _prewarm() -> void:
	var t0 := Time.get_ticks_usec()
	fx.show_everything(true)
	for t in [0.05, 0.3, 1.4, 1.8, 2.3, 2.5, 2.7, 12.45, 13.0, 21.9]:
		fx.update(t)
		await _frame_drawn()
	var last := -1.0
	var still := 0
	for i in 600:
		await _frame_drawn()
		var c := 0.0
		for m in [Performance.PIPELINE_COMPILATIONS_CANVAS, Performance.PIPELINE_COMPILATIONS_MESH, Performance.PIPELINE_COMPILATIONS_SURFACE,
				Performance.PIPELINE_COMPILATIONS_DRAW, Performance.PIPELINE_COMPILATIONS_SPECIALIZATION]:
			c += Performance.get_monitor(m)
		if c == last:
			still += 1
			if still >= 20:
				break
		else:
			still = 0
		last = c
	fx.show_everything(false)
	fx.update(0.0)
	await _frame_drawn()
	prewarm_s = (Time.get_ticks_usec() - t0) / 1e6
	print("[enginetest] warm-up drew every variant in %.1f s" % prewarm_s)


func _write_trace(path: String) -> void:
	var secs: Array = []
	var by_s := {}
	for i in frame_ms.size():
		var s := int(floorf(frame_t[i] - WARMUP))
		if not by_s.has(s):
			by_s[s] = []
		by_s[s].append(i)
	var keys := by_s.keys()
	keys.sort()
	for s in keys:
		var ms := PackedFloat64Array()
		var pmax := 0.0
		var over := 0
		for i in by_s[s]:
			ms.append(frame_ms[i])
			pmax = maxf(pmax, proc_ms[i])
			if frame_ms[i] > 16.7:
				over += 1
		ms.sort()
		var tot := 0.0
		for v in ms:
			tot += v
		var k := maxi(1, int(ceil(ms.size() * 0.01)))
		var worst := 0.0
		for j in k:
			worst += ms[ms.size() - 1 - j]
		secs.append({"second": s, "frames": ms.size(), "avg_ms": snappedf(tot / ms.size(), 0.001), "p99_ms": snappedf(worst / k, 0.001),
			"max_ms": snappedf(ms[ms.size() - 1], 0.001), "over_16_7": over, "max_script_ms": snappedf(pmax, 0.001)})
	var order := range(frame_ms.size())
	order.sort_custom(func(x, y): return frame_ms[x] > frame_ms[y])
	var worst_frames: Array = []
	for i in mini(15, order.size()):
		var j: int = order[i]
		worst_frames.append({"ms": snappedf(frame_ms[j], 0.001), "scene_t": snappedf(frame_t[j], 0.001), "script_ms": snappedf(proc_ms[j], 0.001)})
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"per_second": secs, "worst_frames": worst_frames}, "  ", false) + "\n")
		f.close()
		print("[enginetest] wrote ", path)


# ---------------------------------------------------------------- scene options

func _read_scene_options() -> void:
	opt_rich = args.has("rich")
	opt_max = args.has("max")
	opt_board = args.has("board")
	opt_vsync = args.has("vsync")
	opt_physics = opt_max or opt_board or args.has("physics")
	n_ships = 6
	if args.has("ships"):
		n_ships = maxi(24, int(args["ships"]))
	elif args.has("stress"):
		n_ships = 24
	stress = n_ships > 6
	if stress:
		# rows of six every 30 units beyond the stress rows, alternating sides; radius 150 + 40 per row pair past the main rows
		var extra_rows := ceili((n_ships - 24) / 6.0)
		orbit_r = STRESS_R + 20.0 * extra_rows
		orbit_h = STRESS_H if n_ships == 24 else orbit_r * 0.45
	var base := "main"
	if n_ships > 24:
		base = "ships%d" % n_ships
	elif stress:
		base = "stress"
	if opt_board:
		mode_name = "board"
	elif opt_max:
		mode_name = "max" if base == "main" else "max_" + base
	elif opt_rich:
		mode_name = "rich" if base == "main" else "rich_" + base
	else:
		mode_name = base


# Rich and max environment features. All of these are Forward+ only; Compatibility keeps the main scene's look.
func _apply_quality() -> void:
	var compat := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	if opt_rich or opt_max:
		if compat:
			notes.append("rich: no volumetric fog in Compatibility (particle smoke only)")
		else:
			# volumetric fog only where FogVolumes put density (breach vents, smoke rings, the fireball)
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.0
			env.volumetric_fog_albedo = Color(1, 1, 1)
			env.volumetric_fog_length = 260.0
			env.volumetric_fog_detail_spread = 2.0
			env.volumetric_fog_ambient_inject = 0.6
			env.volumetric_fog_temporal_reprojection_enabled = true
			RenderingServer.environment_set_volumetric_fog_volume_size(160, 96)
	if not opt_max:
		return
	if compat:
		notes.append("max: SSAO, SSIL, SSR, SDFGI and TAA are Forward+ only; Compatibility runs without them")
		return
	env.ssao_enabled = true
	env.ssao_radius = 2.0
	env.ssao_intensity = 1.6
	env.ssil_enabled = true
	env.ssil_radius = 6.0
	env.ssr_enabled = true
	env.ssr_max_steps = 96
	env.sdfgi_enabled = true
	env.sdfgi_cascades = 6
	env.sdfgi_min_cell_size = 0.5
	env.sdfgi_use_occlusion = true
	vp.use_taa = true
	key_light.light_angular_distance = 0.5  # soft (PCSS) key shadows; Godot has no screen-space contact shadows
	key_light.shadow_blur = 1.0
	RenderingServer.directional_shadow_atlas_set_size(8192, true)
	notes.append("max: SSAO, SSIL, SSR, SDFGI (6 cascades), TAA on top of MSAA 4x, 8192 shadow atlas with soft (PCSS) key shadows, tiling detail normals on the hulls; no screen-space contact shadows in Godot")


# Max mode presentation: colour grading (built-in adjustments), depth of field on the close-up cameras, shake from fx.
func _apply_presentation() -> void:
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		return
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.1
	var curve := Gradient.new()
	curve.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	curve.colors = PackedColorArray([Color(0.0, 0.01, 0.03), Color(0.5, 0.49, 0.47), Color(1.0, 0.97, 0.92)])
	var lut := GradientTexture1D.new()
	lut.gradient = curve
	env.adjustment_color_correction = lut
	notes.append("max: colour grading with Environment adjustments (contrast, saturation, a cool-shadow warm-highlight curve)")


func _cam_attributes(focus: float) -> void:
	if focus < 0.0 or not opt_max or RenderingServer.get_current_rendering_method() == "gl_compatibility":
		cam.attributes = null
		return
	if cam.attributes == null:
		var ca := CameraAttributesPractical.new()
		ca.dof_blur_far_enabled = true
		ca.dof_blur_near_enabled = true
		ca.dof_blur_amount = 0.08
		cam.attributes = ca
	var a := cam.attributes as CameraAttributesPractical
	a.dof_blur_far_distance = focus + 8.0
	a.dof_blur_far_transition = 25.0
	a.dof_blur_near_distance = maxf(focus - 10.0, 1.0)
	a.dof_blur_near_transition = 6.0


func _shot_list() -> Array:
	if opt_board:
		return [{"t": 3.0, "cam": "board", "file": "board_t03.0.png"}, {"t": 12.6, "cam": "board", "file": "board_t12.6.png"}]
	var prefix := "max_" if opt_max else ("rich_" if opt_rich else "")
	var out: Array = []
	for sh in SHOTS:
		var e: Dictionary = sh.duplicate()
		e["file"] = prefix + String(e["file"])
		out.append(e)
		if opt_max and is_equal_approx(float(e["t"]), 3.0):
			for i in HERO_CODES.size():
				out.append({"t": 3.0, "cam": "hero:%d" % i, "file": "hero_%s.png" % HERO_CODES[i]})
	return out


func _sample_stats() -> void:
	if fx.has_method("active_lights"):
		var n: int = fx.active_lights()
		light_n += 1
		light_sum += n
		light_max = maxi(light_max, n)
	if phys != null:
		phys_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		body_max = maxi(body_max, phys.live_bodies())


func _extra_results(sorted_ms: PackedFloat64Array) -> Dictionary:
	var out := {}
	if opt_vsync:
		var hz := DisplayServer.screen_get_refresh_rate()
		if hz <= 0.0:
			hz = 60.0
		var interval := 1000.0 / hz
		var dropped := 0
		for v in frame_ms:
			dropped += maxi(0, int(round(v / interval)) - 1)
		out["vsync"] = true
		out["refresh_hz"] = snappedf(hz, 0.01)
		out["dropped_frames"] = dropped
	if light_n > 0:
		out["lights_active_avg"] = snappedf(light_sum / light_n, 0.1)
		out["lights_active_max"] = light_max
	if phys_ms.size() > 0:
		var ps := phys_ms.duplicate()
		ps.sort()
		var tot := 0.0
		for v in ps:
			tot += v
		out["physics_ms_avg"] = snappedf(tot / ps.size(), 0.001)
		out["physics_ms_p99"] = snappedf(ps[mini(ps.size() - 1, int(ps.size() * 0.99))], 0.001)
		out["bodies_max"] = body_max
	if board != null:
		out["click_to_ring_frames"] = board.click_frames
	return out


# The stress run's 18 extra ships: copies of the loaded flagships (the meshes are shared, not loaded again) at 0.6 scale.
func _stress_copies() -> Array:
	var out: Array = []
	var rows: Array = STRESS_ROWS.duplicate()
	for r in ceili((n_ships - 24) / 6.0):
		rows.append((90.0 + 30.0 * (r / 2)) * (1.0 if r % 2 == 0 else -1.0))
	for z in rows:
		for j in STRESS_X.size():
			if 6 + out.size() >= n_ships:
				break
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
#  1. textures get mipmaps (GLTFDocument leaves runtime images without them);
#  2. COLOR_0 multiplies base colour (Godot leaves vertex colours off);
#  3. a primitive with no material (only the unpainted sandbox barge) gets metal 0, rough 0.75, as the Babylon half does.
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
	# (No UV-set fix: Godot 4.7's GLTFDocument already puts a material's TEXCOORD_1 maps on its first UV set.)
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


func _fix_vertex_colors(st: GLTFState) -> void:
	var no_mats: bool = not st.json.has("materials")
	for gm in st.get_meshes():
		var im: ImporterMesh = gm.mesh
		for si in im.get_surface_count():
			var arr: Array = im.get_surface_arrays(si)
			var mat := im.get_surface_material(si) as BaseMaterial3D
			if arr[Mesh.ARRAY_COLOR] != null and mat != null:
				mat.vertex_color_use_as_albedo = true
			if no_mats and mat != null:
				mat.metallic = 0.0
				mat.roughness = 0.75


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


func _default_cam() -> String:
	if opt_board:
		return "board"
	return "battle"


func _set_cam(which: String, t: float) -> void:
	if which == "board" and board != null:
		cam.transform = board.camera_pose()
		return
	if which.begins_with("hero:"):
		var i := int(which.substr(5))
		var sp: Vector3 = (all_ships[i]["root"] as Node3D).position
		var side := 20.0 if sp.z > 0.0 else -20.0
		var from := Vector3(sp.x - 8.0, 6.0, sp.z + side)
		cam.transform = Transform3D(Basis.looking_at(sp - from, Vector3.UP), from)
		_cam_attributes((sp - from).length())
		return
	if CAMS.has(which):
		var c: Array = CAMS[which]
		cam.transform = Transform3D(Basis.looking_at(c[1] - c[0], Vector3.UP), c[0])
		_cam_attributes((c[1] - c[0]).length())
	else:
		_place_camera(t)
		_cam_attributes(-1.0)
		if opt_max:
			cam.transform.origin += fx.shake_offset(clock, cam.transform.origin)


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
