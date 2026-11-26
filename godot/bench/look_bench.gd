extends Node
# Issue 351: the look bench. One standing capture set at the three real cameras (170 the battle camera, 60 the middle,
# 26 the closest the game allows; render/camera_rig.gd r and min_r), on a fixed seed and a fixed effect clock, so two
# runs of the same commit give the same pictures and a change shows only where it lands.
#
#   godot --path godot --fixed-fps 60 --disable-vsync --resolution 1920x1080 res://bench/look_bench.tscn -- --out DIR
#         [--part all|moments|fleet] [--only id1,id2] [--commit SHA] [--allow-blocks] [--no-warm] [--fleet-cams 170,110]
# --allow-blocks is for a cloud smoke run of the script only (no hulls there): it draws the blocks instead of stopping.
# --sound (issue 1238): the game's own death sounds play (audio/sfx.gd and audio/death_audio.gd, as the battle wires them)
# and the bench picture is shown in the window, so Godot's --write-movie FILE.avi records a clip with picture and sound.
#
# Parts:
#   moments  every row of bench/look_moments.json (weapons on a hull and on a shield, shield states, death classes, one
#            weapon on every weight, the eight PR 327 looks), each at the three cameras, as 30 frames a second strips:
#            DIR/moments/<id>__c<cam>.png (384x216 cells side by side with a provenance footer below them;
#            camera 170 is a 1 to 1 pixel crop).
#   props    (issue 1767, only when asked: --part props) the live board's stations and hulks at cameras 170 and 26 through
#            render/board.gd itself: DIR/props/<item>__c<cam>.png, 1280x720 at 1 to 1 (VS_1767_OLD=1 draws the old path).
#            A missing still, station or faction writes PROPS_FAILED.txt and exits 4 with no LOOK_BENCH_DONE line
#            (--props-smoke, for a cloud parse run with no pictures, lets it finish).
#   fleet    all 36 hulls of render/hull_table.gd AI_HULLS at the battle camera (170) at true pixel size over every
#            region's sky and a storm map (the sheet maker names the darkest and brightest by measurement):
#            DIR/fleet/<sky>/<nn>_<code>.png (400x240, 1 to 1).
# DIR/bench.json lists every still with its effect time, the run's settings and warnings. The last line is
# LOOK_BENCH_DONE. Stops with "LOOK_BENCH placeholder hull" (exit 3) if any ship would be drawn as a block (no built
# hull: a checkout without godot/gen), so a bench never quietly draws blocks (issue 281 run 6).
#
# Repeatability (the pattern of bench/scene_gate.gd --still and fx/test/vent_look_probe.gd):
#   - the effect clock is manual (fx.manual, one 1/60 s step per drawn frame), seeded (fx.rng 11 and the global RNG
#     2070 before every moment), and every worker job (hull damage rebuilds, death cuts) is waited for before each step;
#   - run with --fixed-fps 60: then the engine's own clock (shader TIME, physics, timers, world_living's clock) also
#     moves exactly 1/60 s per drawn frame, so wreck physics (R118, real time in the game) is frame-locked here;
#   - every part's world is built twice: the first build bakes; the second, on a fixed frame grid, reuses the bakes in
#     one frame, then a fixed 120 frames pass, so bake time on the PC shifts neither the shader clock nor the storm's;
#   - render/ship_view.gd draws its idle bob and station-keeping jets on the wall clock (Time.get_ticks_msec): the
#     bench turns ShipView processing off, so ships hold still (nothing else in a ShipView runs while parked).
#   - before the moments, a warm pass plays every row once at camera 170 and keeps nothing, so no pipeline is still
#     compiling (and drawn with Godot's general shader) while a kept still is taken;
#   - shake is off (as the audit probe); hit pause and death slow motion stay on (they are part of the look).
# The bench draws no hex grid and no HUD (world, ships and effects only); the battle scene with both is
# bench/scene_gate.tscn --still.

const FX := preload("res://fx/fx.gd")
const HULL := preload("res://fx/fx_hull.gd")
const BREACH := preload("res://fx/fx_breach.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const SV := preload("res://render/ship_view.gd")
const HT := preload("res://render/hull_table.gd")
const LOOK := preload("res://render/look.gd")
const MM_TRIAL := preload("res://render/mm_trial.gd")
const CAMRIG := preload("res://render/camera_rig.gd")
const BL := preload("res://world/board_look.gd")
const LIVING := preload("res://world/world_living.gd")
const WORLD_PATH := "res://world/world.gd"
const MOMENTS := "res://bench/look_moments.json"
const HEX_S := 10.0
const HEX_W := 17.320508
# issue 1877: --size WxH draws smaller (a cloud stand-in run on the software renderer); the PC keeps 1920x1080
var W := 1920
var H := 1080
const STEP := 1.0 / 60.0
const GRID := 900          # every part starts on a multiple of this many drawn frames
const FLEET_CELL := Vector2i(400, 240)
# the skies of the fleet sheet: every region of world/world_sky.gd (each biome is picked so region_for lands on it), then a
# storm map. Which is darkest and brightest on screen is measured by the sheet maker (the region's own numbers do not say:
# PC run 1 showed the "deep" region, faintest by its numbers, brighter behind the ships than the "nebula" region).
const SKIES := [
	["frontier", {"rock": "stone", "planet": 4}, false],
	["nebula", {"rock": "crystal", "planet": 2}, false],
	["world", {"rock": "stone", "planet": 3}, false],
	["boneyard", {"rock": "iron", "planet": 5}, false],
	["deep", {"rock": "carbon", "planet": 6}, false],
	["storm", {"rock": "ice", "planet": 7}, true],        # the gate scene's storm region, ion storm hexes on the ship
]
const STORM_HEXES := ["0,0", "1,0", "-1,0", "0,1", "0,-1", "1,-1", "-1,1", "2,-1", "-2,1"]
# hulls with no faction and class of their own in the battle: drawn from their file at a stated length
const OBJ_LEN := {"S1_51": 2.56, "S2_23": 2.56, "B23_51": 2.56, "O1_37": 46.0, "O2_37": 17.6, "O3_11": 8.0}

var args := {}
var out := ""
var vp: SubViewport
var world: Node3D
var env: Environment
var cam
var fx
var wld = null
var A = null
var T = null
var report := {"stills": [], "warnings": [], "parts": {}}
var _wound := {}   # issue 1741 (Artoo on 6fbf60fe): a wound-aimed row's open cutouts and pose, for its still's report entry
var cfg := {}
var steps := 0
var headless := false
var failed := ""   # issue 1877 (Artoo on PR 1904): a failed clip or strict row fails the run (no LOOK_BENCH_DONE, exit 4)
var sfx: Node = null          # --sound only
var death_audio: Node = null
var _build_d_stub: Node = null   # only used when comparing Nova on a pre-2045 checkout


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		var k := a[i]
		if k.begins_with("--"):
			k = k.substr(2)
			if i + 1 < a.size() and not a[i + 1].begins_with("--"):
				args[k] = a[i + 1]
				i += 1
			else:
				args[k] = true
		i += 1
	out = str(args.get("out", "user://look_bench"))
	if args.has("size"):
		var wh := str(args["size"]).split("x")
		W = int(wh[0])
		H = int(wh[1])
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	OS.low_processor_usage_mode = false
	AudioServer.set_bus_mute(0, not args.has("sound"))
	BL.set_look("cine", false)   # Ryan's board look (Nov 1), whatever user://board_look.cfg says; not saved
	_run.call_deferred()


func _log(s: String) -> void:
	print("[look_bench] " + s)


func _warn(s: String) -> void:
	report["warnings"].append(s)
	_log("WARNING " + s)


func _run() -> void:
	# issue 370: --moments FILE reads another rows file (a job's own rows, e.g. bench/look_moments_attach.json)
	var moments_path := str(args.get("moments", MOMENTS))
	var f := FileAccess.get_file_as_string(moments_path)
	var parsed = JSON.parse_string(f)
	if not (parsed is Dictionary):
		_log("ERROR cannot read " + moments_path)
		get_tree().quit(2)
		return
	cfg = parsed
	# Issue 426: a capital flash is 423 px, taller than the usual 216 px crop. Keep full source pixels at camera 170.
	# Single hits and longer windows make the flash/body clocks measurable without the next shell hiding them.
	if args.has("rebake"):
		cfg["cell"] = [640, 480]
		cfg["crop"] = {"170": [640, 480], "60": [1280, 960], "26": [1920, 1080]}
		for row in cfg["rows"]:
			if row.get("do", "") == "volley":
				row["shots"] = 1
				row["windows"] = [["impact", -0.07, 34]]
			elif row.get("do", "") == "death":
				row["windows"] = [["split", -0.03, 25]]
	var fm := FileAccess.open(out.path_join("moments.json"), FileAccess.WRITE)   # the rows this run used, for the sheet maker
	if fm != null:
		fm.store_string(JSON.stringify(cfg, " ") if args.has("rebake") else f)
		fm.close()
	report["commit"] = str(args.get("commit", ""))
	report["godot"] = Engine.get_version_info().get("string", "")
	report["adapter"] = RenderingServer.get_video_adapter_name()
	report["fixed_fps"] = Engine.get_physics_ticks_per_second()
	report["fleet_lighting"] = LOOK.fleet_lighting_enabled()   # issue 1679: which lighting this run drew (VS_FLEET_LIGHTING)
	report["moments_sha256"] = FileAccess.get_sha256(moments_path)
	report["bench_sha256"] = FileAccess.get_sha256("res://bench/look_bench.gd")
	headless = DisplayServer.get_name() == "headless"
	if headless:
		_warn("headless display: no pictures are drawn (parse and load check only)")
	# every hull the bench will draw must be a real built hull, checked before anything is drawn
	var bad: Array = []
	for key in HT.AI_HULLS:
		var code := str(HT.AI_HULLS[key])
		if not _hull_file_ok(code):
			bad.append(code)
	if not bad.is_empty() and args.has("allow-blocks"):
		_warn("--allow-blocks (a cloud smoke run only): no built hull for " + ", ".join(bad))
	elif not bad.is_empty():
		_placeholder("no built hull file for " + ", ".join(bad))
		return
	_setup_view()
	if args.has("sound"):
		_sound_setup()
	HULL.reset_late()   # issue 376: count only the shaders first built after a warm-up in this run
	var part := str(args.get("part", "all"))
	if part == "all" or part == "fleet":
		await _fleet_part()
	if not MM_TRIAL.has_missing and (part == "all" or part == "moments"):
		await _moments_part()
	if part == "props":   # issue 1767 only (not in "all", so the standing sets do not change)
		await _props_part()
	report["pipelines_compiled"] = _pipelines()
	report["late_shaders_after_warmup"] = HULL.late_shader_count()
	report["late_shader_names"] = HULL.late_shader_names()
	_log("late shaders after warm-up (issue 376): %d; pipelines compiled in this run: %d" % [HULL.late_shader_count(), _pipelines()])
	for line in HULL.late_shader_names():
		_log("  late shader " + str(line))
	if failed != "":
		# the report stays for diagnosis; no DONE line, so look_bench.bat reports the run as failed
		report["failed"] = failed
		_save_report()
		print("LOOK_BENCH_FAILED " + failed)
		await _shutdown(4)
		return
	_save_report()
	_log("stills: %d, warnings: %d" % [report["stills"].size(), report["warnings"].size()])
	if not prop_failures.is_empty() and not args.has("props-smoke"):   # --props-smoke: a cloud parse run, no pictures
		# issue 1767 (Artoo on PR 1772): a props set with a missing still, station or faction never reads as done
		var ff := FileAccess.open(out.path_join("PROPS_FAILED.txt"), FileAccess.WRITE)
		if ff != null:
			ff.store_string("\n".join(PackedStringArray(prop_failures)) + "\n")
			ff.close()
		print("LOOK_BENCH_PROPS_FAILED %d" % prop_failures.size())
		get_tree().quit(4)
		return
	if not MM_TRIAL.has_missing:
		print("LOOK_BENCH_DONE")
	# a clean exit: drop the static caches and the effects' GPU resources while the rendering server is alive (the
	# first PC run ended with an access violation after its last line)
	_clear()
	if fx != null and is_instance_valid(fx):
		world.remove_child(fx)
		fx.queue_free()
	FX.clear_static()
	SV.clear_static()
	await get_tree().process_frame
	get_tree().quit(1 if MM_TRIAL.has_missing else 0)


func _pipelines() -> int:
	var n := 0
	for key in [Performance.PIPELINE_COMPILATIONS_DRAW, Performance.PIPELINE_COMPILATIONS_SPECIALIZATION, Performance.PIPELINE_COMPILATIONS_CANVAS]:
		n += int(Performance.get_monitor(key))
	return n


func _save_report() -> void:
	var fo := FileAccess.open(out.path_join("bench.json"), FileAccess.WRITE)
	if fo != null:
		fo.store_string(JSON.stringify(report, " ") + "\n")
		fo.close()


func _placeholder(why: String) -> void:
	_log("LOOK_BENCH placeholder hull: " + why)
	print("LOOK_BENCH placeholder hull")
	var fo := FileAccess.open(out.path_join("PLACEHOLDER.txt"), FileAccess.WRITE)
	if fo != null:
		fo.store_string("placeholder hull: " + why + "\nCopy godot\\gen and godot\\assets\\ships from a checkout that has the built hulls.\n")
		fo.close()
	report["placeholder"] = why
	_save_report()
	get_tree().quit(3)


# The same lookup order as render/ship_view.gd setup: an A4 kit ship, then the max-detail file, then the game hull.
func _hull_file_ok(code: String) -> bool:
	if code == "":
		return false
	var man: Dictionary = SV.manifest()
	for k in ["ships", "hi", "hulls"]:
		if man.has(k) and (man[k] as Dictionary).has(code):
			var res := str(man[k][code].get("res", ""))
			if res != "" and ResourceLoader.exists(res):
				return true
	return false


# After setup: a ShipView that fell back to its block has one tiny box surface (24 corners).
func _is_block(sv) -> bool:
	var n := 0
	for mi in sv.meshes:
		var m := mi as MeshInstance3D
		if m == null or m.mesh == null:
			continue
		for s in m.mesh.get_surface_count():
			n += m.mesh.surface_get_array_len(s)
	return n <= 36


# ---------------------------------------------------------------- the view (the audit probe's pattern)

func _setup_view() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.02)
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()
	world.add_child(key)
	var fill := DirectionalLight3D.new()
	world.add_child(fill)
	LOOK.apply(env, key, fill, {"quality": "max"})
	key.directional_shadow_max_distance = 600.0
	cam = CAMRIG.new()
	world.add_child(cam)
	cam.input_enabled = false
	cam.keyboard_enabled = false
	cam.current = true
	LIVING.apply_fog(world, env, cam.r, "max")
	_make_fx()


# --sound: the battle's sound player and death observer, and the bench picture on screen for --write-movie.
func _sound_setup() -> void:
	# The death cues are positional (AudioStreamPlayer3D). They are heard only through a listener in their own world:
	# the bench camera lives in the SubViewport, whose 3D listener is off by default, and a player in the root window's
	# world has no camera at all. PC run 1 (issue 1238) recorded digital silence that way. So the sound player lives in
	# the SubViewport's world and that viewport listens.
	vp.audio_listener_enable_3d = true
	sfx = preload("res://audio/sfx.gd").new()
	world.add_child(sfx)
	sfx.cam = cam
	death_audio = preload("res://audio/death_audio.gd").new()
	death_audio.sfx = sfx
	death_audio.fx = fx
	add_child(death_audio)
	var tr := TextureRect.new()
	tr.texture = vp.get_texture()
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(tr)
	_log("sound on: death cues play and the picture shows in the window (for --write-movie)")


# A fresh effects system: every moment starts from the same empty state (no smoke, wrecks or debris left over from the
# moment before, the effect clock at 0).
func _make_fx() -> void:
	_build_d_stub = null
	if fx != null and is_instance_valid(fx):
		world.remove_child(fx)   # _exit_tree releases its GPU resources and waits for its worker jobs
		fx.queue_free()
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	# Issue 376: a fresh effects system builds the warm-up's own pool and death materials again. That is this bench
	# warming a new moment, not a shader first built mid-battle, so the late log stays off until the moment's warm-up.
	HULL.pause_late_watch()
	fx.setup({"camera": cam, "quality": "max", "reduce_flashing": false, "shake": 0.0, "unit": 1.0, "seed": 20261026})
	if death_audio != null:
		death_audio.fx = fx
		death_audio.deaths.clear()
		sfx.stop_all()


func _hex(q: int, r: int) -> Vector3:
	return Vector3(HEX_W * (q + r / 2.0), 0, 1.5 * HEX_S * r)


# Build the world twice: the first build bakes the sky and planet (seconds on the PC, cached after); then wait for the
# frame grid; then the second build reuses the bakes inside one frame, and a fixed 120 frames pass. So the shader clock
# (TIME) and the world's own clocks (world_living's storm and gas) stand at the same values on every run.
func _world(biome: Dictionary, terrain: Dictionary, units: Array) -> void:
	for pass_i in 2:
		if wld != null and is_instance_valid(wld):
			world.remove_child(wld)
			wld.queue_free()
			wld = null
			await get_tree().process_frame
		if not ResourceLoader.exists(WORLD_PATH):
			_warn("no world script")
			return
		if pass_i == 1:
			await _grid()
		wld = load(WORLD_PATH).new()
		world.add_child(wld)
		wld.build({"map": {}, "terrain": terrain, "units": units, "round": 1},
			{"biome": biome, "fac": "voidsworn", "hex_world": _hex, "camera": cam, "environment": env, "quality": "max", "seed": 7})
		if pass_i == 0:
			var t0 := Time.get_ticks_msec()
			await get_tree().process_frame
			while int(wld.pending_bakes) > 0 and Time.get_ticks_msec() - t0 < 120000:
				await get_tree().process_frame
			if int(wld.pending_bakes) > 0:
				_warn("world bake still pending after 120 s")
			# the planet and moons bake through the same queue; give it a moment to drain
			for k in 30:
				await get_tree().process_frame
	_log("world: %s" % str(wld.setting.get("region", "?")))
	if int(wld.pending_bakes) > 0:
		_warn("world rebuild did not reuse the bake (pending %d): this part's stills may not repeat" % int(wld.pending_bakes))
	for k in 120:
		await get_tree().process_frame


func _grid() -> void:
	var f := Engine.get_process_frames()
	var target := (f / GRID + 1) * GRID
	while Engine.get_process_frames() < target:
		await get_tree().process_frame
	report["parts"][str(report["parts"].size())] = {"start_frame": Engine.get_process_frames()}


func _step() -> void:
	_settle()
	fx.step(STEP)
	if is_instance_valid(_build_d_stub):
		_build_d_stub._process(STEP)
	if wld != null and is_instance_valid(wld) and wld.has_method("step"):
		wld.step(STEP)
	steps += 1
	if headless:
		await get_tree().process_frame   # no draw signal without a renderer (the cloud smoke run)
	else:
		await RenderingServer.frame_post_draw


# every worker job (hull damage rebuilds, death cuts) finished before the clock moves (scene_gate.gd _settle)
func _settle() -> void:
	for id in fx.ships:
		var sh = fx.ships[id]
		if int(sh._dmg_task) >= 0:
			_wait_task(int(sh._dmg_task), "hull damage rebuild", id)
		if sh.has_meta("cut_task"):
			_wait_task(int(sh.get_meta("cut_task")), "death cut", id)


# issue 1236 (WRECK1 sat 25 minutes with no log): a worker job that keeps the clock waiting names its ship and kind, at
# 5, 10, 20 s and so on; nothing is printed while jobs finish in time (Artoo on PR 1785: the damage wait logs too)
func _wait_task(task: int, kind: String, id) -> void:
	var t0 := Time.get_ticks_msec()
	var told := 5000
	while not WorkerThreadPool.is_task_completed(task):
		OS.delay_usec(300)
		if Time.get_ticks_msec() - t0 > told:
			_log("settle: %s's %s still running after %d s" % [str(id), kind, told / 1000])
			told *= 2


func _clear() -> void:
	for id in fx.ships.keys():
		fx.remove_ship(str(id))
		if fx.has_method("clear_wreck"):
			fx.clear_wreck(str(id))
	for n in world.get_children():
		if n is Node3D and String(n.name).begins_with("ship_"):
			world.remove_child(n)
			n.queue_free()
	A = null
	T = null


# One ship as the battle draws it (G2's ShipView, added to G4's effects as the battle does), or null when it is a block.
func _ship(id: String, fac: String, cls: String, pos: Vector3, facing: int, code := "", cut_on_arrival := false,
		squad_tpl := ""):
	var sv = SV.new()
	sv.name = "ship_" + id
	world.add_child(sv)
	var u := {"id": id, "fac": fac, "cls": cls, "facing": facing, "hp": 100, "maxHp": 100, "size": 1.0}
	if cls == "Squadron":
		u["tpl"] = squad_tpl if squad_tpl != "" else ("spore" if fac == "chorus" else "fighter")
	if code != "":
		u["code"] = code
		u["L"] = float(OBJ_LEN.get(code, 10.0))
	sv.setup(u, pos, true)
	if MM_TRIAL.has_missing:
		return null
	sv.set_process(false)   # its bob and idle jets run on the wall clock (see the header)
	if not sv.squad_kind.is_empty() and sv.hull != null:
		sv.hull.set_process(false)
	if sv.squad_kind.is_empty() and _is_block(sv) and not args.has("allow-blocks"):
		_placeholder("%s %s drew a block (code %s)" % [fac, cls, str(sv.code)])
		return null
	var info := {"faction": fac, "cls": cls, "size": 1.0, "squadron": cls == "Squadron", "flagship": false, "code": sv.code,
		"cut_on_arrival": cut_on_arrival}
	if not sv.a4:
		info["meshes"] = sv.meshes
	fx.add_ship(id, sv, info)
	sv.fx_engines = true
	fx.set_engine(id, 0.3)
	fx.sync_ship(id, _unit(1.0, 5))
	return sv


func _unit(hp: float, sh: int) -> Dictionary:
	return {"hp": 100.0 * hp, "maxHp": 100.0, "burning": false, "sh": [sh, sh, sh, sh],
		"sec": {"prow": {"hp": 30.0 * hp, "max": 30.0}, "mid": {"hp": 40.0 * hp, "max": 40.0}, "eng": {"hp": 30.0 * hp, "max": 30.0, "broken": false}}}


func _cam(focus: Vector3, r: float) -> void:
	cam.a = -PI / 2.0
	cam.b = 0.98
	cam.r = r
	cam.t = Vector3(focus.x, 0, focus.z)
	cam.snap()


func _grab() -> Image:
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		return null
	img.convert(Image.FORMAT_RGB8)
	return img


func _crop(img: Image, size: Vector2i, cell: Vector2i) -> Image:
	var c := img.get_region(Rect2i((W - size.x) / 2, (H - size.y) / 2, size.x, size.y))
	if size != cell:
		c.resize(cell.x, cell.y, Image.INTERPOLATE_LANCZOS)
	return c


# ---------------------------------------------------------------- fleet: all 36 hulls at the battle camera

func _fleet_part() -> void:
	var fleet_cams: Array = [170]
	if args.has("fleet-cams"):
		fleet_cams = []
		for c in str(args["fleet-cams"]).split(",", false):
			if c.is_valid_int() and int(c) >= 26:
				fleet_cams.append(int(c))
		if fleet_cams.is_empty():
			fleet_cams = [170]
	var codes: Array = []
	for key in HT.AI_HULLS:
		codes.append([str(key), str(HT.AI_HULLS[key])])
	for sky in SKIES:
		var terrain := {}
		if bool(sky[2]):
			for k in STORM_HEXES:
				terrain[k] = "storm"
		await _world(sky[1], terrain, [{"q": 0, "r": 0}])
		report["parts"]["fleet_" + str(sky[0])] = {"region": str(wld.setting.get("region", "")), "start_frame": Engine.get_process_frames()}
		var d := out.path_join("fleet").path_join(str(sky[0]))
		DirAccess.make_dir_recursive_absolute(d)
		var n := 0
		for fc in codes:
			_clear()
			seed(2070)
			fx.rng.seed = 11
			var parts := String(fc[0]).split("|")
			var sv
			if parts[0] in ["craft", "obj"]:
				sv = _ship("A", "hegemony", "Frigate", Vector3.ZERO, 0, String(fc[1]))
			else:
				sv = _ship("A", parts[0], parts[1], Vector3.ZERO, 0)
			if sv == null:
				return
			# issue 1679: --fleet-cams 170,110,60 adds stills at more camera radii. Camera 170 keeps its file names and part
			# "fleet" (the sheet maker's 1 to 1 sheets); any other radius is part "fleet_cam", named __c<radius>, cropped to
			# the same framing at true pixels (the cell grows as 170 / radius), so the stock sheets never see it.
			for cr in fleet_cams:
				_cam(Vector3.ZERO, float(cr))
				for k in 8:
					await _step()
				var img := _grab()
				if img == null:
					_warn("empty frame for fleet %s %s c%d" % [sky[0], fc[1], cr])
					continue
				var name := "%02d_%s.png" % [n, fc[1]] if cr == 170 else "%02d_%s__c%d.png" % [n, fc[1], cr]
				var cs := FLEET_CELL if cr == 170 else Vector2i(mini(W, roundi(FLEET_CELL.x * 170.0 / cr)), mini(H, roundi(FLEET_CELL.y * 170.0 / cr)))
				preload("res://tools/picture_provenance.gd").save_png(_crop(img, cs, cs), d.path_join(name), preload("res://tools/picture_provenance.gd").capture_stage())
				report["stills"].append({"part": "fleet" if cr == 170 else "fleet_cam", "cam": cr, "sky": sky[0], "file": "fleet/%s/%s" % [sky[0], name],
					"code": fc[1], "what": fc[0], "length": float(sv.L), "step": steps})
			n += 1
		_log("fleet %s: %d hulls" % [sky[0], n])
	_clear()


# ---------------------------------------------------------------- moments: every row at the three cameras

func _moments_part() -> void:
	var only: Array = []
	if args.has("only"):
		only = Array(str(args["only"]).split(",", false))
	var terrain := {"0,-4": "rock", "-5,3": "rock", "4,3": "debris", "-1,5": "rock"}
	terrain.merge(cfg.get("terrain", {}), true)
	await _world({"rock": "stone", "planet": 4}, terrain,
		[{"q": -3, "r": -2}, {"q": 3, "r": 2}])
	report["parts"]["moments"] = {"region": str(wld.setting.get("region", "")), "start_frame": Engine.get_process_frames()}
	# warm the effect shaders once (fx.warmup), off the measured moments
	_clear()
	A = _ship("A", "voidsworn", "Frigate", Vector3(-34, 0, 0), 0)
	if A == null:
		return
	_cam(Vector3.ZERO, 170.0)
	if not headless:
		await fx.warmup(cam)
	await _grid()
	var d := out.path_join("moments")
	DirAccess.make_dir_recursive_absolute(d)
	var cams: Array = cfg.get("cameras", [170, 60, 26])
	var cell := Vector2i(int(cfg["cell"][0]), int(cfg["cell"][1]))
	# Warm pass: every row once at the battle camera, nothing saved. PC run 3: the first run after an import differed
	# from the next one by up to 1.6 levels on the first moments to use a new effect (the macro, torpedo and plasma rows):
	# Godot draws a pipeline it is still compiling with its general shader for a few frames. After this pass every
	# pipeline the moments need is compiled, whatever the disk cache held.
	if not args.has("no-warm"):
		var wd := out.path_join("warm")
		for row in cfg.get("rows", []):
			if not only.is_empty() and not only.has(str(row["id"])):
				continue
			var okw: bool = await _moment(row, 170.0, cell, cell, wd, false)
			if not okw:
				return
		_log("warm pass done")
		await _grid()
	for row in cfg.get("rows", []):
		if not only.is_empty() and not only.has(str(row["id"])):
			continue
		for c in cams:
			var crop_a: Array = cfg["crop"].get(str(int(c)), cfg["cell"])
			var ok: bool = await _moment(row, float(c), Vector2i(int(crop_a[0]), int(crop_a[1])), cell, d)
			if not ok:
				return
		_save_report()
	_clear()


func _moment_volley(row: Dictionary, faction: String) -> Dictionary:
	var kind := str(row.get("kind", "battery"))
	var wid := str(row.get("weapon", kind))
	var n := int(row.get("shots", 0))
	if n <= 0:
		n = WEAP.default_shots(WEAP.look_of(kind, wid, faction))
	var shots := []
	var pd := int(row.get("pd", 0))
	for i in n:
		shots.append(i >= pd)
	var old_casing := WEAP._old_casing
	if row.has("fallback_casing"):
		WEAP._old_casing = bool(row["fallback_casing"])
	var res: Dictionary = fx.volley("A", kind, "T", {"weapon_id": wid, "shots": shots, "slot": int(row.get("slot", -1)),
		"hits": _hits(n - pd, str(row.get("on", "hull")) == "shield", bool(row.get("crit", false))), "pd": pd})
	WEAP._old_casing = old_casing
	return res


# Build B frames the released shot, not the battle cut-in or the eventual impact.
func _frame_moment_volley(row: Dictionary, res: Dictionary, anchors: Dictionary, r: float) -> bool:
	var id := str(row["id"])
	var impacts: Array = res.get("impacts", [])
	if impacts.is_empty():
		failed = "%s at %d: no impact time to frame the shot" % [id, int(r)]
		return false
	var fire: float = res["fires"][0]
	var muzzle: Vector3 = res["muzzles"][0]["p"]
	var t_ev: float = anchors["fire"]
	anchors["release"] = t_ev + fire
	anchors["flight"] = t_ev + lerpf(fire, float(impacts[0]), 0.5)
	var focus := muzzle
	var shot_focus := str(row["shot_focus"])
	if shot_focus == "ordnance" or shot_focus == "intercept":
		var rounds: Array = fx.dstate.get("proj", [])
		if rounds.is_empty():
			failed = "%s at %d: no ordnance to frame" % [id, int(r)]
			return false
		var round_: Dictionary = rounds[0]
		if shot_focus == "intercept":
			if not is_finite(float(round_["dead_at"])):
				failed = "%s at %d: no scheduled intercept" % [id, int(r)]
				return false
			anchors["intercept"] = float(round_["dead_at"])
			focus = WEAP._down_point(round_)
		else:
			focus = WEAP._bez(round_["a"], round_["b"], round_["c"], WEAP._ease(0.5))
			anchors["flight"] = lerpf(float(round_["t0"]), float(round_["t1"]), 0.5)
	elif shot_focus != "muzzle":
		focus = muzzle.lerp(res["points"][0], float(row.get("flight_focus", 0.5)))
	_cam(focus, r)
	return true


func _hits(n: int, shield: bool, crit: bool) -> Array:
	var h := []
	var secs := ["mid", "prow", "mid", "eng"]
	for i in n:
		h.append({"shield": 8 if shield else 0, "hull": 0 if shield else 9, "section": secs[i % 4], "crit": crit and i == 0})
	return h


# The shared capture script runs on both revisions. New captures use the same camera poses as battle.
# On the pinned earlier revision, reproduce its wide shot and its existing three-quarter kill hold.
func _moment_cut(kind: String) -> void:
	var pa: Vector3 = A.visual_position()
	var pt: Vector3 = T.visual_position()
	var is_kill := kind == "kill"
	var capital: bool = float(T.L) >= 20.0
	if cam.has_method("enter_cut"):
		var pose: Dictionary
		if is_kill:
			pose = cam.impact_cut(pt, T.L, capital, [[pa, A.L]], false, T.cur_yaw)
		else:
			pose = cam.shot_cut(kind, pa, pt, A.L, T.L, false)
		cam.enter_cut(pose, is_kill)
		return
	var cur: float = cam.a
	if is_kill:
		var best := INF
		for q in [PI / 4.0, 3.0 * PI / 4.0, -PI / 4.0, -3.0 * PI / 4.0]:
			var d := angle_difference(cur, float(T.cur_yaw) + float(q))
			if absf(d) < best:
				best = absf(d)
				cam.a = cur + d
		cam.b = 1.12
		cam.r = clampf(maxf(float(T.L), 6.0) / ((1.0 if capital else 0.85) * 2.0 * tan(deg_to_rad(cam.fov) * 0.5)), cam.min_r, 200.0)
		cam.t = pt
		cam.slow_until = cam._clock + 1.2
		return
	var base := atan2(-(pt.z - pa.z), pt.x - pa.x)
	var left := angle_difference(cur, base + PI / 2.0)
	var right := angle_difference(cur, base - PI / 2.0)
	cam.a = cur + (left if absf(left) < absf(right) else right)
	cam.b = 1.02
	cam.r = clampf(Vector2(pt.x - pa.x, pt.z - pa.z).length() * 1.25 + 34.0, 60.0, 200.0)
	cam.t = (pa + pt) * 0.5


# The effect-only replay of the battle events. The bench runs on both revisions, so the before frames use
# the actual old FX methods or the old battle cue, not a look-alike built on the new kit.
func _build_d(row: Dictionary, event: String) -> void:
	var t: float = fx.now
	var p: Vector3 = T.visual_position() + Vector3.UP * 2.0
	var from: Vector3 = A.visual_position() + Vector3.UP * 2.0
	var dest: Vector3 = T.position + Vector3(-24.0, 0.0, -7.0)
	var shared: bool = fx.has_method("rift_in")
	report["build_d"] = "shared" if shared else "legacy"
	match event:
		"nova":
			var impact: Vector3 = T.position + Vector3.UP * 2.0
			if shared:
				fx.nova("A", impact)
			else:
				fx.ability("A", "nova")
				_build_d_stub = load("res://scenes/battle/fx_stub.gd").new()
				fx.add_child(_build_d_stub)
				_build_d_stub.set_process(false)
				fx.later(t + 0.50, func legacy_shell() -> void:
					_build_d_stub.bolt(from, impact, Color(1.0, 0.8, 0.5), 0.35, 0.0, 3.0))
				fx.later(t + 0.85, _build_d_pop.bind(impact, Color(1.0, 0.7, 0.4), 60.0, 0.8))
		"arrival":
			if shared:
				fx.rift_in("T")
			else:
				_build_d_pop(p, Color(1.0, 0.5, 0.4), 24.0, 0.6)
		"risen":
			if shared:
				fx.rift_in("T", 1.0, 0.0, true)
			else:
				_build_d_pop(p, FX.FLOOK.engine("deathless"), 16.0, 0.8)
		"blink":
			if shared:
				fx.fold("T", 1.0, func bench_blink() -> void: T.position = dest)
			else:
				var c := FX.FLOOK.engine("ithar")
				# The explicit-hex ability moved the view before the separate blink event on the old branch.
				fx.ability("T", "blink")
				T.position = dest
				_build_d_pop(T.visual_position() + Vector3.UP * 2.0, c, 18.0, 0.5)
				fx.later(t + 0.30, func legacy_blink() -> void:
					_build_d_pop(T.visual_position() + Vector3.UP * 2.0, c, 18.0, 0.5))
				fx.later(t + 0.55, func legacy_blink_end() -> void:
					_build_d_pop(T.visual_position() + Vector3.UP * 2.0, c, 18.0, 0.5))
		"phase":
			if shared:
				fx.fold("T")
			else:
				fx.ability("T", "phase")
				_build_d_pop(p, Color("#ddc4ff"), 22.0, 0.9)
		"jump":
			fx.jump_out("T")
		"ability":
			fx.ability("T", str(row.get("ability", "")))
		"command":
			fx.command("T")
		"bay":
			fx.launch("A", "T")


func _build_d_pop(p: Vector3, c: Color, size: float, life: float) -> void:
	fx.pop(p, fx.now, c, size * 0.5, 3.0, Vector3.UP, clampf(life * 0.5, 0.1, 0.4))
	fx.light(p, fx.now, life, 2.0, c)


func _moment(row: Dictionary, r: float, crop: Vector2i, cell: Vector2i, d: String, keep := true) -> bool:
	var id := str(row["id"])
	var strict := bool(row.get("strict", false)) or args.has("strict-moments")
	_clear()
	_make_fx()
	# Issue 462: a row may set effect switches (for example reduce flashing). Set by
	# name so a commit without the switch simply ignores it.
	var opts = row.get("fx", {})
	if opts is Dictionary:
		for k in opts:
			fx.set(str(k), opts[k])
	_cam(Vector3.ZERO, r)
	if not headless:
		await fx.warmup(cam)
	await _step()
	seed(2070)
	fx.rng.seed = 11
	var att: Array = row.get("att", ["voidsworn", "Cruiser"])
	var tgt: Array = row.get("tgt", ["deathless", "Cruiser"])
	var aat: Array = row.get("att_at", [-34, 0])
	A = _ship("A", str(att[0]), str(att[1]), Vector3(float(aat[0]), 0, float(aat[1])), 0)
	if A == null:
		return false
	# issue 370: a row may place the target ("tgt_at": [x, z]), for a broadside or a shot from behind
	var tat: Array = row.get("tgt_at", [34, 0])
	# Only the target of a death row can die. Hull and shader warm-up still runs for every ship.
	var fatal := str(row.get("fatal", ""))
	T = _ship("T", str(tgt[0]), str(tgt[1]), Vector3(float(tat[0]), 0, float(tat[1])), int(row.get("tgt_facing", 2)), "",
		row.get("do") == "death" or fatal != "", str(row.get("tgt_tpl", "")))
	if T == null:
		return false
	if row.has("shield_left"):
		var sh := int(row["shield_left"])
		var unit := _unit(1.0, sh)
		if row.has("shield_max"):
			unit["shp"] = sh
			unit["shMax"] = int(row["shield_max"])
		fx.sync_ship("T", unit)
	# Issue 461: a row may park a third ship beside the target ("near": [faction, class, dx, dz] in world units from
	# the target), for example to show a torpedo hit lighting the hull next to it; and may run the engines at a level
	# ("engine": 0 to 1) instead of the parked glow, for the engine flicker rows at the close cameras.
	var near: Array = row.get("near", [])
	if near.size() >= 4:
		if _ship("N", str(near[0]), str(near[1]), T.global_position + Vector3(float(near[2]), 0.0, float(near[3])), 2) == null:
			return false
	if row.has("engine"):
		for sid in fx.ships.keys():
			fx.set_engine(str(sid), float(row["engine"]))
	var focus: Vector3 = (A if str(row.get("focus", "target")) == "attacker" else T).global_position
	if row.get("focus") == "midpoint":
		focus = A.global_position.lerp(T.global_position, 0.55)
	if row.get("focus") == "pair":
		focus = (A.global_position + T.global_position) * 0.5
	# Issue 461: "attacker_engines" centres on the mean of the attacker's engine nozzles (the engine flicker rows)
	if str(row.get("focus", "")) == "attacker_engines" and fx.ship("A") != null:
		var sa = fx.ship("A")
		var sum := Vector3.ZERO
		for nz in sa.hull.nozzles:
			sum += sa.to_world(nz["p"])
		if sa.hull.nozzles.size() > 0:
			focus = sum / float(sa.hull.nozzles.size())
	# issue 560: a row may move the camera's focus off the ship's centre ("focus_off": [x, z] in world units), for a part
	# such as the aft deck turrets
	var fo: Array = row.get("focus_off", [0, 0])
	focus += Vector3(float(fo[0]), 0.0, float(fo[1]))
	_cam(focus, r)
	for k in 72:   # 1.2 s: engines up, and any scheduled cut jobs done
		await _step()
	# Issue 1235 run 2: a row may land hits on the target first ("pre": [[kind, weapon, section], ...], one shot each,
	# 0.75 s apart, each on its named hull section: eng, mid or prow; Artoo on PR 1570: without it every hit took "mid")
	# and then set its hull state ("sync_t": a unit view, as the game's sync sends), for worn-ship rows; "do": "hold"
	# then shows the ship as it stands. A commit without these keys ignores them.
	# Issue 1235 recheck (Artoo on PR 1570): a pre entry may hit the shield ([kind, weapon, section, "shield"]) or be a
	# boarding party (["board"], the game's fx.board), for the list-side and boarding-then-wear rows.
	for pv in row.get("pre", []):
		if str(pv[0]) == "board":
			fx.board("A", "T")
			for k in 90:
				await _step()
			continue
		var ph: Array = _hits(1, (pv as Array).size() > 3 and str(pv[3]) == "shield", false)
		if (pv as Array).size() > 2:
			ph[0]["section"] = str(pv[2])
		fx.volley("A", str(pv[0]), "T", {"weapon_id": str(pv[1]), "shots": [true], "hits": ph})
		for k in 45:
			await _step()
	if row.get("sync_t") is Dictionary:
		fx.sync_ship("T", row["sync_t"])
		for k in 30:
			await _step()
		# Issue 1741: a shot still in flight can defer the hull stages. Finish the rebuild before aiming at a wound.
		var ts = fx.ship("T")
		if ts != null:
			for k in 480:
				if fx.now > float(ts.busy_until) + 0.1:
					break
				await _step()
			if fx.now <= float(ts.busy_until) + 0.1:
				_warn("%s at %d: the target was still waiting on a pre shot after 8 s" % [id, int(r)])
			for k in 3:
				ts.flush_damage(fx)
				await _step()
	# Close wound details face the largest open cutout. Camera 170 keeps the board angle. Log the actual pose so these
	# rows are details, not before/after pairs. The shared bench also loads on revisions without the Wounds V2 API.
	_wound = {}
	var breach: Variant = BREACH
	if str(row.get("focus", "")) == "wound" and r < 100.0 and fx.ship("T") != null and breach.has_method("open_mouths"):
		var st = fx.ship("T")
		var best: Dictionary = {}
		var mouths: Array = breach.open_mouths(st)
		for mo in mouths:
			if best.is_empty() or float(mo["R"]) > float(best["R"]):
				best = mo
		# No open cutout means the detail is incomplete, even though its still is kept. V2 off expects none.
		var v2: bool = breach.v2_on()
		_wound = {"mouths": mouths.size(), "v2": v2, "complete": not best.is_empty()}
		if best.is_empty() and v2:
			_warn("LOOK_BENCH WOUND MISSING %s at %d: no open cutout, default camera kept" % [id, int(r)])
		if not best.is_empty():
			var wc: Vector3 = st.to_world(best["c"])
			var wn: Vector3 = (st.to_world(best["c"] + best["n"]) - wc).normalized()
			cam.a = atan2(-wn.z, wn.x)
			cam.b = clampf(acos(clampf(wn.y, -1.0, 1.0)), 0.35, 1.25)
			cam.r = r
			cam.t = wc
			cam.snap()
			_wound["pose"] = [cam.a, cam.b, cam.r, wc.x, wc.y, wc.z]
			_log("%s wound pose at %d: a %.4f b %.4f r %.1f t (%.2f, %.2f, %.2f)" % [id, int(r), cam.a, cam.b, cam.r, wc.x, wc.y, wc.z])
			for k in 6:
				await _step()
	var cut := str(row.get("cutin", ""))
	if cut != "":
		_moment_cut(cut)
		if cut != "kill":
			for k in 19:   # same 320 ms lead as battle's shot cut
				await _step()
		crop = Vector2i(W, H)   # a cut-in cell shows the whole composition
	fx.rng.seed = 11
	seed(2070)
	var t_ev: float = fx.now
	var impacts: Array = []
	var res := {}
	var what := str(row.get("do", "volley"))
	if what == "volley":
		res = _moment_volley(row, str(att[0]))
		impacts = res.get("impacts", [])
		if impacts.is_empty():
			if strict:
				return _fail_moment(id, r, "the volley reported no impact time")
			_warn("%s: the volley reported no impact time; impact anchor set to fire + 0.6 s" % id)
	elif what == "break":
		# a hit first, so the bubble is up, then the collapse half a second later
		fx.volley("A", "gauss", "T", {"weapon_id": "gauss", "shots": [true], "hits": _hits(1, true, false)})
		for k in 30:
			await _step()
		t_ev = fx.now
		fx.shield_break("T", 3)
	elif what == "death":
		# issue 1586: a row may pick the small-hull archetype ("arch": 0 torch, 1 snap, 2 roll, 3 pop); a commit without
		# the archetypes ignores it
		if row.has("arch") and fx.ship("T") != null:
			fx.ship("T").set_meta("death_arch_force", int(row["arch"]))
		# and may put the Hollow Sun's well near the target ("well": [dx, dy, dz] from the target) for a tidal kill;
		# a strike craft target is a "Squadron" class (fx treats that class as a wing)
		if row.has("well"):
			var wv: Array = row["well"]
			fx.well = T.global_position + Vector3(float(wv[0]), float(wv[1]), float(wv[2]))
		_log("%s: death call at %.2f (step %d)" % [id, fx.now, steps])   # issue 1236: one line a death row
		fx.death("T", str(row.get("cause", "blast")))
		if row.has("well"):
			fx.later(fx.now + 8.0, func l_well_off() -> void: fx.well = Vector3.INF)
		if death_audio != null:
			death_audio.watch("T", T.global_position)
	# issue 370 (attach points): where a launch, the movement jets and the wounds start on the attacker's hull
	elif what == "tick":
		if row.has("well"):
			var wv: Array = row["well"]
			fx.well = T.global_position + Vector3(float(wv[0]), float(wv[1]), float(wv[2]))
		fx.tick("T", str(row["kind"]))
	elif what == "board":
		fx.board("A", "T")
	elif what == "launch":
		fx.launch("A", "T")
	elif what == "jets":
		# every movement jet ShipView fires, at once; the bench keeps ShipView's processing off, so each puff stays where
		# it started unless step_jets is set (issue 2042: steps puffs and fires repeat bursts so motion strings show)
		A._retro_puffs(1.0)
		A._aft_puffs(1.0)
		A._side_puffs(1.0, 1.0)
		A._couple_puffs(1.0, 1.0)
	elif what == "move":
		# issue 2042: drive A forward along +X so moving nozzle trails build and taper cleanly behind the stern
		fx.set_engine("A", float(row.get("engine", 1.6)))
	elif what == "wing":
		# issue 2042: step a live patrol SquadronWing so its craft weave and draw trails on the shared kit
		if A.hull != null and A.hull.has_method("step"):
			A.hull.patrol_limit = 7.5
			A.hull.patrol_target = 1.0
			A.hull.fit_formation()
			A.hull.step(0.0)
			for wk in 24:
				A.hull.step(STEP)
				if fx.has_method("step"):
					await _step()
			t_ev = fx.now
	elif what == "sync":
		# issue 1587: the event is a hull state change ("sync_ev", a unit view as the game's sync sends), for a section
		# crossing into stage 3 or 4 (the one-shot blowout); a commit without this key shows the ship unchanged
		if row.get("sync_ev") is Dictionary:
			fx.sync_ship("T", row["sync_ev"])
	elif what == "wounds":
		fx.sync_ship("A", {"hp": 25.0, "maxHp": 100.0, "burning": false, "sh": [5, 5, 5, 5],
			"sec": {"eng": {"hp": 10, "max": 100}, "mid": {"hp": 10, "max": 100}, "prow": {"hp": 10, "max": 100}}})
	elif what == "build_d":
		_build_d(row, str(row["event"]))
	elif what == "wisp":
		# Isolate the real turret/mount/nozzle picture without a nearby full wound or a spark hiding it.
		var target = fx.ship("T")
		var e := {"id": "bench_wisp"}
		if not target.hull.turrets.is_empty():
			e["tur"] = 0
		elif not target.hull.nozzles.is_empty():
			e["mp"] = target.hull.nozzles[0]["p"]
		else:
			var anchor: Dictionary = target._anchor(1, "a")
			if anchor.is_empty():
				_warn(id + ": no wisp source")
				return false
			e["mp"] = anchor.p
		target._build_wisp(fx, e)
		_cam(target.to_world(e.source), r)
	# Issue 2044: frame the same existing source in both revisions, rather than picking a screen offset per hull.
	match str(row.get("focus_site", "")):
		"mid_wound":
			var target = fx.ship("T")
			var anchor: Dictionary = target._anchor(1, "a")
			if not anchor.is_empty():
				focus = target.to_world(anchor.p)
			_cam(focus, r)
		"wing_lead":
			if not T.hull.craft.is_empty():
				_cam(T.hull.craft[0].global_position, r)
	var anchors := {"fire": t_ev, "event": t_ev, "impact": t_ev + (float(impacts[0]) if impacts.size() > 0 else 0.6)}
	var fatal_at := float(anchors["impact"]) + 0.90 if fatal != "" else INF
	# Issue 504: a row may fire a second volley from A at T during the event ("also": [seconds after the event, kind,
	# weapon]), for example a torpedo landing on a dying capital; the "also" anchor is that volley's first impact.
	var also: Array = row.get("also", [])
	if what == "volley" and row.has("shot_focus") and not _frame_moment_volley(row, res, anchors, r):
		return false
	var wins: Array = []
	var total := 0
	for wv in row.get("windows", [["impact", -0.07, 12]]):
		wins.append({"anchor": str(wv[0]), "at": float(wv[1]), "n": int(wv[2]), "got": 0, "next": -1})
		total += int(wv[2])
	# issue 1877: a "clip" row saves every cell as its own frame (DIR/moments/<id>__c<cam>/f000.png ...) for a video,
	# since a long strip passes Godot's 16384-pixel image limit; the strip is then not made
	var clip := bool(row.get("clip", false))
	var clip_dir := d.path_join("%s__c%d" % [id, int(r)])
	var clip_bad: Array = []   # frames that failed to save (a clip row with any missing frame fails, Artoo on PR 1904)
	# a "strict" still row fails the same way on a blank cell, a window that never opened or a strip that did not save
	# (Artoo on PR 1904: the acid colour proof rows must not pass with a blank cell)
	if clip and keep:
		var mk := DirAccess.make_dir_recursive_absolute(clip_dir)
		if mk != OK or not DirAccess.dir_exists_absolute(clip_dir):
			return _fail_moment(id, r, "clip folder %s could not be made (error %d)" % [clip_dir, mk])
	var strip := Image.create_empty(1 if clip else cell.x * total, cell.y, false, Image.FORMAT_RGB8)
	var ci := 0
	var cells: Array = []
	var focus_by_window: Array = row.get("focus_by_window", [])
	var event_target: Vector3 = Vector3(float(tat[0]), 0, float(tat[1]))
	var guard := 0
	var wi := 0
	var step_jets := what == "jets" and bool(row.get("step_jets", false))
	var jet_burst_t := 0.0
	var move_speed := float(row.get("move_speed", 22.0))
	var move_dur := float(row.get("move_dur", 0.75))
	var brake_at := float(row.get("brake_at", 0.55))
	var focus_mode := str(row.get("focus", "target"))
	var track_hulk := bool(row.get("seek_hulk", false))
	while wi < wins.size() and guard < 900:
		var w: Dictionary = wins[wi]
		if step_jets and is_instance_valid(A):
			A._puffs_step(STEP)
			jet_burst_t += STEP
			if jet_burst_t >= 0.075:
				jet_burst_t = 0.0
				A._retro_puffs(1.0)
				A._couple_puffs(1.0, 1.0)
		elif what == "move" and is_instance_valid(A):
			var elapsed: float = float(fx.now) - t_ev
			if elapsed <= move_dur:
				A.position.x += move_speed * STEP
			if elapsed >= brake_at:
				fx.set_engine("A", 0.0)
			var track_p: Vector3 = A.global_position
			if focus_mode == "attacker_engines" and fx.ship("A") != null:
				var sa2 = fx.ship("A")
				if sa2.hull.nozzles.size() > 0:
					var sum2 := Vector3.ZERO
					for nz in sa2.hull.nozzles:
						sum2 += sa2.to_world(nz["p"])
					track_p = sum2 / float(sa2.hull.nozzles.size())
			_cam(track_p + Vector3(float(fo[0]), 0.0, float(fo[1])), r)
		elif what == "wing" and is_instance_valid(A) and A.hull != null and A.hull.has_method("step"):
			A.hull.step(STEP)
		if fx.now + 1e-4 >= fatal_at:
			fatal_at = INF
			if cut != "":
				_moment_cut("kill")
			fx.death("T", fatal)
			if death_audio != null:
				death_audio.watch("T", T.global_position)
		if w["anchor"] == "core":
			var core: float = fx.death_core_at("T")
			anchors["core"] = core if core >= 0.0 else INF
		if w["anchor"] == "split":
			var sh = fx.ships.get("T")
			var split_t: float = float(sh.get_meta("death_split", t_ev + 1.0)) if sh != null else t_ev + 1.0
			anchors["split"] = split_t
		if also.size() >= 3 and not anchors.has("also_fired") and fx.now + 1e-4 >= t_ev + float(also[0]):
			anchors["also_fired"] = fx.now
			var ares: Dictionary = fx.volley("A", str(also[1]), "T", {"weapon_id": str(also[2]), "shots": [true], "hits": _hits(1, false, false)})
			var aimp: Array = ares.get("impacts", [])
			anchors["also"] = fx.now + (float(aimp[0]) if aimp.size() > 0 else 0.6)
			_log("%s: also volley %s at %.3f, impact at %.3f" % [id, str(also[1]), fx.now - t_ev, float(anchors["also"]) - t_ev])
		var start: float = float(anchors.get(w["anchor"], t_ev)) + float(w["at"])
		if w["anchor"] == "also" and not anchors.has("also"):
			start = INF
		# Long hulk rows step to the next sample after the death beat, then follow the same drifting wreck in both runs.
		if track_hulk and ci > 0 and int(w["got"]) == 0 and start - fx.now > 4.0:
			fx.step(start - fx.now - STEP)
		var take := false
		if int(w["got"]) == 0:
			take = fx.now + 1e-4 >= start
		else:
			take = steps >= int(w["next"])
		if take:
			if not headless and int(w["got"]) == 0 and wi < focus_by_window.size():
				var shot_focus: Vector3 = focus
				match str(focus_by_window[wi]):
					"flight": shot_focus = A.position.lerp(event_target, 0.52)
					"target": shot_focus = event_target
					"blink_end": shot_focus = event_target + Vector3(-24.0, 0.0, -7.0)
				_cam(shot_focus, r)
				await RenderingServer.frame_post_draw
			if track_hulk:
				var hulk: Node3D
				for wreck in fx.dstate.get("wrecks", []):
					if wreck.id == "T" and wreck.get("hulk", false) and not wreck.nodes.is_empty():
						hulk = wreck.nodes[0]
						break
				if not is_instance_valid(hulk):
					return _fail_moment(id, r, "no target hulk at %.2f s" % (fx.now - t_ev))
				_cam(hulk.global_position, r)
				await _step()
			var img := _grab() if keep and not headless else null
			if clip:
				if keep:
					var fp := clip_dir.path_join("f%03d.png" % ci)
					if img == null:
						clip_bad.append("f%03d.png (no frame grabbed)" % ci)
					else:
						var se: Error = preload("res://tools/picture_provenance.gd").save_png(_crop(img, crop, cell), fp,
							preload("res://tools/picture_provenance.gd").capture_stage(), true)
						if se != OK:
							clip_bad.append("f%03d.png (save error %d)" % [ci, se])
			elif img != null:
				strip.blit_rect(_crop(img, crop, cell), Rect2i(Vector2i.ZERO, cell), Vector2i(ci * cell.x, 0))
			elif strict and keep:
				clip_bad.append("cell %d (no frame grabbed)" % ci)
			cells.append({"t": snappedf(fx.now - t_ev, 0.0001), "step": steps})
			ci += 1
			w["got"] = int(w["got"]) + 1
			w["next"] = steps + 2   # 30 frames a second: every second 1/60 s frame
			if int(w["got"]) >= int(w["n"]):
				wi += 1
				continue
		await _step()
		guard += 1
	if wi < wins.size():
		_warn("%s at %d: only %d of %d cells (a window never opened)" % [id, int(r), ci, total])
		if strict and not keep:
			return _fail_moment(id, r, "warm pass took %d of %d cells" % [ci, total])
	if not keep:
		return true
	# issue 1777 (Artoo on PR 1786): record the hull the target resolved to; a row naming "expect_code" says loudly when
	# the faction and class drew a different hull (a later remap), so a capture bat can fail on it
	var tcode := str(T.code) if is_instance_valid(T) else ""
	var acode := str(A.code) if is_instance_valid(A) else ""
	if row.has("expect_code") and tcode != str(row["expect_code"]):
		_warn("%s: target drew %s, the row expects %s" % [id, tcode, str(row["expect_code"])])
		_log("LOOK_BENCH CODE MISMATCH %s: drew %s, expected %s" % [id, tcode, str(row["expect_code"])])
		if strict:
			return _fail_moment(id, r, "target drew %s, expected %s" % [tcode, str(row["expect_code"])])
	if row.has("expect_att_code") and str(A.code) != str(row["expect_att_code"]):
		_warn("%s: attacker drew %s, the row expects %s" % [id, str(A.code), str(row["expect_att_code"])])
		_log("LOOK_BENCH CODE MISMATCH %s: drew %s, expected %s" % [id, str(A.code), str(row["expect_att_code"])])
		if strict:
			return _fail_moment(id, r, "attacker drew %s, expected %s" % [acode, str(row["expect_att_code"])])
	if row.has("expect_craft") and not args.has("allow-blocks"):
		var craft_code := ""
		if is_instance_valid(T) and is_instance_valid(T.hull):
			var craft = T.hull.get("craft")
			if craft is Array and not craft.is_empty() and is_instance_valid(craft[0]):
				craft_code = str(craft[0].get_meta("model_code", ""))
		if craft_code != str(row.expect_craft):
			_warn("%s: wing drew %s, the row expects %s" % [id, craft_code, row.expect_craft])
			if strict:
				return _fail_moment(id, r, "wing drew %s, expected %s" % [craft_code, str(row.expect_craft)])
	if clip:
		# Every numbered frame must be on disk, and a stale frame cannot cover a failed read or save this run.
		for fi in total:
			var fn := "f%03d.png" % fi
			if not FileAccess.file_exists(clip_dir.path_join(fn)) and not clip_bad.any(func(b): return str(b).begins_with(fn)):
				clip_bad.append(fn + " (missing)")
		if ci != total or not clip_bad.is_empty():
			return _fail_moment(id, r, "clip row failed: %d of %d frames taken; bad: %s" % [ci, total, ", ".join(clip_bad)])
		report["stills"].append({"part": "moments", "id": id, "cam": int(r), "file": "moments/%s__c%d/" % [id, int(r)],
			"cells": cells, "impacts": impacts, "clip": true})
		_log("%s at %d: %d clip frames" % [id, int(r), ci])
		return true
	var name := "%s__c%d.png" % [id, int(r)]
	if strict and (ci != total or not clip_bad.is_empty()):
		return _fail_moment(id, r, "strict row failed: %d of %d cells taken; bad: %s" % [ci, total, ", ".join(clip_bad)])
	if not headless:
		var picture := preload("res://tools/picture_provenance.gd")
		var saved := preload("res://tools/picture_provenance.gd").save_png(strip, d.path_join(name), picture.capture_stage(), true)
		if strict and (saved != OK or not FileAccess.file_exists(d.path_join(name))):
			return _fail_moment(id, r, "strict row failed: %s (save error %d)" % [name, saved])
	report["stills"].append({"part": "moments", "id": id, "cam": int(r), "file": "moments/" + name, "cells": cells,
		"impacts": impacts, "code": tcode, "attacker_code": acode})
	if not _wound.is_empty():
		report["stills"][-1]["wound"] = _wound.duplicate()
	_log("%s at %d: %d cells" % [id, int(r), ci])
	return true


func _fail_moment(id: String, r: float, why: String) -> bool:
	failed = "%s at %d: %s" % [id, int(r), why]
	_warn("LOOK_BENCH " + failed)
	return false


# ---------------------------------------------------------------- props (issue 1767): stations and hulks on the live board

class PropRules extends RefCounted:
	var v := {}
	var w := {}
	func view() -> Dictionary:
		return v
	func world_info() -> Dictionary:
		return w


const PROP_CELL := Vector2i(1280, 720)


# the real render/board.gd built over `terrain` (and station holes), in the bench world, for one board of the part
func _prop_board(terrain: Dictionary, holes: Array, map: Dictionary, units: Array, kind: String) -> Node3D:
	var hexes := []
	for q in range(-8, 9):
		for r in range(-8, 9):
			if absi(q + r) <= 8:
				hexes.append({"q": q, "r": r})
	var m := map.duplicate()
	m["holes"] = holes
	var rules := PropRules.new()
	rules.v = {"hexes": hexes, "terrain": terrain, "units": units, "map": m}
	rules.w = {"seed": 7, "biome": {"rock": "stone", "planet": 4, "station": kind}}
	var board: Node3D = load("res://render/board.gd").new()
	board.name = "prop_board"
	world.add_child(board)
	board.build(rules)
	return board


func _prop_still(item: String, focus: Vector3, cams: Array) -> void:
	var d := out.path_join("props")
	DirAccess.make_dir_recursive_absolute(d)
	for r in cams:
		_cam(focus, float(r))
		for k in 8:
			await _step()
		var img := _grab()
		if img == null:
			_prop_fail("empty frame for %s c%d" % [item, int(r)])
			continue
		var name := "%s__c%d.png" % [item, int(r)]
		var path := d.path_join(name)
		# Artoo on PR 1772: a still counts only when the writer says OK and both the picture and its sidecar are on disk
		var err := preload("res://tools/picture_provenance.gd").save_png(_crop(img, PROP_CELL, PROP_CELL), path, preload("res://tools/picture_provenance.gd").capture_stage())
		if err != OK or not FileAccess.file_exists(path) or not FileAccess.file_exists(path + ".provenance.json"):
			_prop_fail("%s not saved (writer %d)" % [name, int(err)])
			continue
		report["stills"].append({"part": "props", "id": item, "cam": int(r), "file": "props/" + name, "step": steps,
			"old_path": OS.get_environment("VS_1767_OLD") == "1"})


var prop_failures: Array = []


func _prop_fail(why: String) -> void:
	prop_failures.append(why)
	_warn("props FAIL " + why)


func _props_part() -> void:
	var tag := "old" if OS.get_environment("VS_1767_OLD") == "1" else "new"
	prop_failures.clear()
	var want := 0
	await _world({"rock": "stone", "planet": 4}, {}, [{"q": 0, "r": 0}])
	report["parts"]["props"] = {"region": str(wld.setting.get("region", "")), "path": tag}
	var stations := [
		# item, terrain cells, holes, map, ship hex (the next hex out, for lamp spill), biome kind
		["ST1_teaching_3hex", ["0,0", "1,0", "0,1"], [], {"station": {"q": 0, "r": 0}, "stationR": 1}, Vector2i(1, 1), "rig"],
		["ST2_big_19hex", [], [], {"station": {"q": 0, "r": 0}, "stationR": 2}, Vector2i(3, 0), "ring"],
		["ST3_hole_1hex", [], [{"kind": "station", "cells": [[0, 0]]}], {}, Vector2i(1, 0), "spire"],
	]
	for st in stations:
		var cells: Array = st[1]
		if str(st[0]).begins_with("ST2"):
			for q in range(-2, 3):
				for r in range(-2, 3):
					if absi(q + r) <= 2:
						cells.append("%d,%d" % [q, r])
		var terrain := {}
		for k in cells:
			terrain[k] = "station"
		_clear()
		seed(2070)
		fx.rng.seed = 11
		var board := _prop_board(terrain, st[2], st[3], [], str(st[5]))
		var sh: Vector2i = st[4]
		var sp := _hex(sh.x, sh.y)
		var sv = _ship("A", "hegemony", "Cruiser", sp, 3)
		if sv == null:
			return
		# the station the item is about must be the path's own: T2 after; before, O1_37 off the big cluster
		var t2n := 0
		var o1n := 0
		for n in board.find_children("*", "Node3D", true, false):
			if n.has_meta("station_T2"):
				t2n += 1
				report["parts"]["props"]["%s_scale" % st[0]] = snappedf(float(n.get_meta("station_scale", n.scale.x)), 0.001)
			elif n.name.begins_with("StationDock"):
				# Fable on PR 1772 (item 7): a station hex no mesh covers gets a grey dock drum; count them per item
				report["parts"]["props"]["%s_docks" % st[0]] = int(report["parts"]["props"].get("%s_docks" % st[0], 0)) + 1
			elif n.has_meta("station_kind"):
				o1n += 1
		var big := str(st[0]).begins_with("ST2")
		if (tag == "new" or big) and t2n != 1:
			_prop_fail("%s: %d station_T2 drawn, want 1" % [st[0], t2n])
		if tag == "old" and not big and o1n != 1:
			_prop_fail("%s: %d old O1_37 drawn, want 1" % [st[0], o1n])
		want += 2
		var centre := Vector3.ZERO
		for k in cells:
			var qr: PackedStringArray = str(k).split(",")
			centre += _hex(int(qr[0]), int(qr[1]))
		centre = centre / float(cells.size()) if not cells.is_empty() else _hex(0, 0)
		await _prop_still("%s_%s" % [st[0], tag], (centre + sp) * 0.5, [170, 26])
		world.remove_child(board)
		board.queue_free()
	# a graveyard: 31 hulk hexes, no fleet (every faction may be drawn); one overview, then each faction's first hulk
	var field := {}
	for q in range(-6, 7):
		for r in range(-6, 7):
			if absi(q + r) <= 6 and (q * 7 + r * 3) % 4 == 0:
				field["%d,%d" % [q, r]] = "hulk"
	_clear()
	var gy := _prop_board(field, [], {}, [], "")
	await _prop_still("HK0_graveyard_%s" % tag, Vector3.ZERO, [170])
	want += 1
	var seen := {}
	for n in gy.find_children("*", "Node3D", true, false):
		var fac := str(n.get_meta("hulk_faction", "")) if n.has_meta("hulk_faction") else ""
		if fac != "" and not seen.has(fac):
			seen[fac] = true
			await _prop_still("HK_%s_%s" % [fac, tag], (n as Node3D).global_position, [170, 26])
			want += 2
	report["parts"]["props"]["hulk_factions"] = seen.keys()
	var facs_want := 4 if tag == "old" else 6
	if seen.size() != facs_want:
		_prop_fail("graveyard drew %d factions' hulks %s, want %d" % [seen.size(), str(seen.keys()), facs_want])
	var got: int = report["stills"].filter(func(x): return x.get("part") == "props").size()
	if got != want:
		_prop_fail("%d props stills saved, want %d" % [got, want])
	report["parts"]["props"]["failures"] = prop_failures.duplicate()
	_log("props %s: hulk factions %s" % [tag, str(seen.keys())])
	world.remove_child(gy)
	gy.queue_free()
	_clear()
