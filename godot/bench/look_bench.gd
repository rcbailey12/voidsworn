extends Node
# Issue 351: the look bench. One standing capture set at the three real cameras (170 the battle camera, 60 the middle,
# 26 the closest the game allows; render/camera_rig.gd r and min_r), on a fixed seed and a fixed effect clock, so two
# runs of the same commit give the same pictures and a change shows only where it lands.
#
#   godot --path godot --fixed-fps 60 --disable-vsync --resolution 1920x1080 res://bench/look_bench.tscn -- --out DIR
#         [--part all|moments|fleet] [--only id1,id2] [--commit SHA] [--allow-blocks] [--no-warm]
# --allow-blocks is for a cloud smoke run of the script only (no hulls there): it draws the blocks instead of stopping.
#
# Parts:
#   moments  every row of bench/look_moments.json (weapons on a hull and on a shield, shield states, death classes, one
#            weapon on every weight, the eight PR 327 looks), each at the three cameras, as 30 frames a second strips:
#            DIR/moments/<id>__c<cam>.png (cells side by side, 384x216 each; camera 170 is a 1 to 1 pixel crop).
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
const WEAP := preload("res://fx/fx_weapons.gd")
const SV := preload("res://render/ship_view.gd")
const HT := preload("res://render/hull_table.gd")
const LOOK := preload("res://render/look.gd")
const CAMRIG := preload("res://render/camera_rig.gd")
const BL := preload("res://world/board_look.gd")
const WORLD_PATH := "res://world/world.gd"
const MOMENTS := "res://bench/look_moments.json"
const HEX_S := 10.0
const HEX_W := 17.320508
const W := 1920
const H := 1080
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
var cfg := {}
var steps := 0
var headless := false


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
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	OS.low_processor_usage_mode = false
	AudioServer.set_bus_mute(0, true)
	BL.set_look("cine", false)   # Ryan's board look (Nov 1), whatever user://board_look.cfg says; not saved
	_run.call_deferred()


func _log(s: String) -> void:
	print("[look_bench] " + s)


func _warn(s: String) -> void:
	report["warnings"].append(s)
	_log("WARNING " + s)


func _run() -> void:
	# issue 370: --moments FILE reads another rows file (a job's own rows, e.g. bench/look_moments_attach.json)
	var f := FileAccess.get_file_as_string(str(args.get("moments", MOMENTS)))
	var parsed = JSON.parse_string(f)
	if not (parsed is Dictionary):
		_log("ERROR cannot read " + MOMENTS)
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
	report["moments_sha256"] = FileAccess.get_sha256(MOMENTS)
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
	var part := str(args.get("part", "all"))
	if part == "all" or part == "fleet":
		await _fleet_part()
	if part == "all" or part == "moments":
		await _moments_part()
	report["pipelines_compiled"] = _pipelines()
	report["late_shader_counter"] = "not present at this commit (issue 376)"
	_log("late shader counter (issue 376): not present at this commit; pipelines compiled in this run: %d" % _pipelines())
	_save_report()
	_log("stills: %d, warnings: %d" % [report["stills"].size(), report["warnings"].size()])
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
	get_tree().quit(0)


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
	_make_fx()


# A fresh effects system: every moment starts from the same empty state (no smoke, wrecks or debris left over from the
# moment before, the effect clock at 0).
func _make_fx() -> void:
	if fx != null and is_instance_valid(fx):
		world.remove_child(fx)   # _exit_tree releases its GPU resources and waits for its worker jobs
		fx.queue_free()
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max", "reduce_flashing": false, "shake": 0.0, "unit": 1.0, "seed": 20261026})


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
			while not WorkerThreadPool.is_task_completed(int(sh._dmg_task)):
				OS.delay_usec(300)
		if sh.has_meta("cut_task"):
			while not WorkerThreadPool.is_task_completed(int(sh.get_meta("cut_task"))):
				OS.delay_usec(300)


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
func _ship(id: String, fac: String, cls: String, pos: Vector3, facing: int, code := ""):
	var sv = SV.new()
	sv.name = "ship_" + id
	world.add_child(sv)
	var u := {"id": id, "fac": fac, "cls": cls, "facing": facing, "hp": 100, "maxHp": 100, "size": 1.0}
	if code != "":
		u["code"] = code
		u["L"] = float(OBJ_LEN.get(code, 10.0))
	sv.setup(u, pos, true)
	sv.set_process(false)   # its bob and idle jets run on the wall clock (see the header)
	if _is_block(sv) and not args.has("allow-blocks"):
		_placeholder("%s %s drew a block (code %s)" % [fac, cls, str(sv.code)])
		return null
	var info := {"faction": fac, "cls": cls, "size": 1.0, "squadron": false, "flagship": false, "code": sv.code}
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
			_cam(Vector3.ZERO, 170.0)
			for k in 8:
				await _step()
			var img := _grab()
			if img == null:
				_warn("empty frame for fleet %s %s" % [sky[0], fc[1]])
				continue
			var name := "%02d_%s.png" % [n, fc[1]]
			_crop(img, FLEET_CELL, FLEET_CELL).save_png(d.path_join(name))
			report["stills"].append({"part": "fleet", "sky": sky[0], "file": "fleet/%s/%s" % [sky[0], name], "code": fc[1],
				"what": fc[0], "length": float(sv.L), "step": steps})
			n += 1
		_log("fleet %s: %d hulls" % [sky[0], n])
	_clear()


# ---------------------------------------------------------------- moments: every row at the three cameras

func _moments_part() -> void:
	var only: Array = []
	if args.has("only"):
		only = Array(str(args["only"]).split(",", false))
	await _world({"rock": "stone", "planet": 4}, {"0,-4": "rock", "-5,3": "rock", "4,3": "debris", "-1,5": "rock"},
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


func _hits(n: int, shield: bool, crit: bool) -> Array:
	var h := []
	var secs := ["mid", "prow", "mid", "eng"]
	for i in n:
		h.append({"shield": 8 if shield else 0, "hull": 0 if shield else 9, "section": secs[i % 4], "crit": crit and i == 0})
	return h


func _moment(row: Dictionary, r: float, crop: Vector2i, cell: Vector2i, d: String, keep := true) -> bool:
	var id := str(row["id"])
	_clear()
	_make_fx()
	# Issue 462: a row may set effect switches (for example the capital death's scene dim, or reduce flashing). Set by
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
	A = _ship("A", str(att[0]), str(att[1]), Vector3(-34, 0, 0), 0)
	if A == null:
		return false
	# issue 370: a row may place the target ("tgt_at": [x, z]), for a broadside or a shot from behind
	var tat: Array = row.get("tgt_at", [34, 0])
	T = _ship("T", str(tgt[0]), str(tgt[1]), Vector3(float(tat[0]), 0, float(tat[1])), 2)
	if T == null:
		return false
	if row.has("shield_left"):
		fx.sync_ship("T", _unit(1.0, int(row["shield_left"])))
	var focus: Vector3 = (A if str(row.get("focus", "target")) == "attacker" else T).global_position
	# issue 560: a row may move the camera's focus off the ship's centre ("focus_off": [x, z] in world units), for a part
	# such as the aft deck turrets
	var fo: Array = row.get("focus_off", [0, 0])
	focus += Vector3(float(fo[0]), 0.0, float(fo[1]))
	_cam(focus, r)
	for k in 72:   # 1.2 s: engines up, the first damage and cut jobs done
		await _step()
	fx.rng.seed = 11
	seed(2070)
	var t_ev: float = fx.now
	var impacts: Array = []
	var what := str(row.get("do", "volley"))
	if what == "volley":
		var kind := str(row.get("kind", "battery"))
		var wid := str(row.get("weapon", kind))
		var n := int(row.get("shots", 0))
		if n <= 0:
			n = WEAP.default_shots(WEAP.look_of(kind, wid, str(att[0])))
		var shots := []
		for i in n:
			shots.append(true)
		var res: Dictionary = fx.volley("A", kind, "T", {"weapon_id": wid, "shots": shots, "slot": int(row.get("slot", -1)),
			"hits": _hits(n, str(row.get("on", "hull")) == "shield", bool(row.get("crit", false)))})
		impacts = res.get("impacts", [])
		if impacts.is_empty():
			_warn("%s: the volley reported no impact time; impact anchor set to fire + 0.6 s" % id)
	elif what == "break":
		# a hit first, so the bubble is up, then the collapse half a second later
		fx.volley("A", "gauss", "T", {"weapon_id": "gauss", "shots": [true], "hits": _hits(1, true, false)})
		for k in 30:
			await _step()
		t_ev = fx.now
		fx.shield_break("T", 3)
	elif what == "death":
		fx.death("T", str(row.get("cause", "blast")))
	# issue 370 (attach points): where a launch, the movement jets and the wounds start on the attacker's hull
	elif what == "launch":
		fx.launch("A", "T")
	elif what == "jets":
		# every movement jet ShipView fires, at once; the bench keeps ShipView's processing off, so each puff stays where
		# it started (that start is what this row shows)
		A._retro_puffs(1.0)
		A._aft_puffs(1.0)
		A._side_puffs(1.0, 1.0)
		A._couple_puffs(1.0, 1.0)
	elif what == "wounds":
		fx.sync_ship("A", {"hp": 25.0, "maxHp": 100.0, "burning": false, "sh": [5, 5, 5, 5],
			"sec": {"eng": {"hp": 10, "max": 100}, "mid": {"hp": 10, "max": 100}, "prow": {"hp": 10, "max": 100}}})
	var anchors := {"fire": t_ev, "event": t_ev, "impact": t_ev + (float(impacts[0]) if impacts.size() > 0 else 0.6)}
	# Issue 504: a row may fire a second volley from A at T during the event ("also": [seconds after the event, kind,
	# weapon]), for example a torpedo landing on a dying capital; the "also" anchor is that volley's first impact.
	var also: Array = row.get("also", [])
	var wins: Array = []
	var total := 0
	for wv in row.get("windows", [["impact", -0.07, 12]]):
		wins.append({"anchor": str(wv[0]), "at": float(wv[1]), "n": int(wv[2]), "got": 0, "next": -1})
		total += int(wv[2])
	var strip := Image.create_empty(cell.x * total, cell.y, false, Image.FORMAT_RGB8)
	var ci := 0
	var cells: Array = []
	var guard := 0
	var wi := 0
	while wi < wins.size() and guard < 900:
		var w: Dictionary = wins[wi]
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
		var take := false
		if int(w["got"]) == 0:
			take = fx.now + 1e-4 >= start
		else:
			take = steps >= int(w["next"])
		if take:
			var img := _grab()
			if img != null:
				strip.blit_rect(_crop(img, crop, cell), Rect2i(Vector2i.ZERO, cell), Vector2i(ci * cell.x, 0))
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
	if not keep:
		return true
	var name := "%s__c%d.png" % [id, int(r)]
	strip.save_png(d.path_join(name))
	report["stills"].append({"part": "moments", "id": id, "cam": int(r), "file": "moments/" + name, "cells": cells,
		"impacts": impacts})
	_log("%s at %d: %d cells" % [id, int(r), ci])
	return true
