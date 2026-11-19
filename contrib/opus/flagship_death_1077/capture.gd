extends SceneTree
## Issue 1077. The flagship death prototype on the shipped look bench, read-only like issue 1076's adapter
## (contrib/codex/battle_baseline_1118/capture.gd), which this follows for the ships, cameras and the kill.
## Arguments after --: mode, scratch directory, then for clips the radii (default "170,26").
##   clips   A16 (C19_51, the installed hull) at stage 4 damage, the fatal torpedo, then the death to cold, once on
##           today's path (death_story off) and once with the strain story, at each radius. Frames at 30 a second
##           (1280x720 jpg) and stills (png) in <scratch>/<variant>_c<radius>/, a timeline.json beside them.
##   timing  three A16 side by side at the battle camera, no frame grabs. The first death in a fresh process (the
##           first-use spike), then one, two and three at once. Per frame: wall time between drawn frames, the
##           viewport's CPU and GPU render times. The variant comes from VS_DEATH_STORY ("strain" or off), so each
##           variant runs in its own process. Output: <scratch>/timing_<variant>.json. The preparation frames are
##           timed too, and "prepared" says whether every cut finished before the kills.
##   cold    a fresh process, one A16 killed the frame its damage arrives, nothing prepared (the cold spike).
##           Output: <scratch>/cold_<variant>.json.
## Run with --fixed-fps 60 at 1920x1080, Forward+, through tools/pc/tmo.bat (run.bat beside this file).

class Bench extends "res://bench/look_bench.gd":
	func _ready() -> void:
		pass

	func story_ship(id: String, spec: Dictionary, pos: Vector3):
		var view = SV.new()
		view.name = "ship_" + id
		world.add_child(view)
		view.setup({"id": id, "fac": spec.fac, "cls": spec.cls, "size": spec.size, "facing": 0,
			"hp": spec.hp, "maxHp": spec.hp}, pos, true)
		view.set_process(false)
		if not view.a4 or _is_block(view):
			return null
		fx.add_ship(id, view, {"faction": spec.fac, "cls": spec.cls, "code": view.code,
			"size": spec.size, "flagship": spec.get("boss", false)})
		view.fx_engines = true
		fx.set_engine(id, 0.3)
		fx.sync_ship(id, _unit(1.0, 0))
		return view

const API := preload("res://rules/battle_api.gd")
const CAP := preload("res://tools/picture_provenance.gd")
const TARGET := "c_boss"      # A16, Ashfall Hullbreakers battle-barge (C19_51)
const CODE := "C19_51"
const SHOOTER := "penitent"   # a Sunward Vigil, as in issue 1076

var bench: Bench
var out: String
var folder: String
var frame_number := 0
var row: Dictionary
var failed := false
var hulls: Dictionary
var record := true


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("CAPTURE1077 usage: -- clips|timing <scratch> [radii]")
		quit(2)
		return
	var mode: String = args[0]
	out = args[1]
	DirAccess.make_dir_recursive_absolute(out)
	Engine.max_fps = 0
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Bench.BL.set_look("cine", false)
	var api = API.new()
	if api.load_rules() != "":
		_fail("Could not read shipped hull rules")
		quit(2)
		return
	hulls = api.R.HULLS
	bench = Bench.new()
	root.add_child(bench)
	bench.out = out
	bench._setup_view()
	bench._cam(Vector3.ZERO, 170.0)
	await bench._world({"rock": "stone", "planet": 4}, {}, [])
	var info := {"mode": mode, "commit": _commit(), "ship_manifest_sha256": FileAccess.get_sha256("res://assets/ships/manifest.json"),
		"scene_sha256": FileAccess.get_sha256(str(Bench.SV.manifest().get("ships", {}).get(CODE, {}).get("res", ""))),
		"adapter": RenderingServer.get_video_adapter_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"godot": Engine.get_version_info().string}
	print("CAPTURE1077 ", JSON.stringify(info))
	if mode == "clips":
		var radii := (args[2] if args.size() > 2 else "170,26").split(",", false)
		for r in radii:
			for variant in ["off", "strain"]:
				await _clip(variant, int(r))
				if failed: break
			if failed: break
		_write("capture.json", info, out)
	elif mode == "timing":
		info["timing"] = await _timing()
		# (the rerun at 1236bbc3 lost this file: the cold branch wrote it instead, over the prepared run's numbers)
		_write("timing_%s.json" % ("strain" if OS.get_environment("VS_DEATH_STORY") == "strain" else "off"), info, out)
	elif mode == "cold":
		info["timing"] = await _cold()
		_write("cold_%s.json" % ("strain" if OS.get_environment("VS_DEATH_STORY") == "strain" else "off"), info, out)
	bench._clear()
	bench.queue_free()
	await process_frame
	Bench.FX.clear_static()
	Bench.SV.clear_static()
	print("CAPTURE1077 ", "FAILED" if failed else "DONE")
	quit(1 if failed else 0)


func _commit() -> String:
	var f := FileAccess.get_file_as_string("res://build_info.json")
	var j = JSON.parse_string(f) if not f.is_empty() else null
	return str(j.get("commit", "")) if j is Dictionary else ""


func _fail(message: String) -> void:
	failed = true
	push_error("CAPTURE1077 " + message)


func _scene(variant: String, radius: int, targets: Array, warm := true) -> void:
	bench._clear()
	OS.set_environment("VS_DEATH_STORY", variant)
	bench._make_fx()
	bench._cam(Vector3.ZERO, radius)
	bench.fx.rng.seed = 11
	seed(2070)
	bench.A = bench.story_ship("A", hulls[SHOOTER], Vector3(-35.0, 0, 18.0))
	for i in targets.size():
		var v = bench.story_ship(targets[i], hulls[TARGET], Vector3(float(i - (targets.size() - 1) * 0.5) * 46.0, 0, 0))
		if v == null or v.code != CODE:
			_fail("A16 did not load its installed hull (%s)" % str(v.code if v != null else "block"))
			return
		if not bench.fx.ship(targets[i]).hull.authored:
			_fail("A16 has no authored seams")
			return
	if bench.fx.death_story != (variant == "strain"):
		_fail("The death_story switch did not take")
		return
	if warm:
		await bench.fx.warmup(bench.cam)
		for i in 60:
			await bench._step()
	bench.fx.rng.seed = 11
	seed(2070)


func _clip(variant: String, radius: int) -> void:
	folder = out.path_join("%s_c%d" % [variant, radius])
	DirAccess.make_dir_recursive_absolute(folder)
	frame_number = 0
	row = {"variant": variant, "radius": radius, "stills": {}, "chapters": []}
	await _scene(variant, radius, ["T"])
	if failed: return
	var target = bench.fx.ship("T")
	# stage 4 on every section, as issue 1076's stage 4, then the fatal torpedo
	bench.fx.sync_ship("T", bench._unit(0.199, 0))
	await _hold(1.7, "stage4", 1.2)
	_chapter("fatal")
	var at: float = bench.fx.now
	var result: Dictionary = bench.fx.volley("A", "torp", "T", {"weapon_id": "torp", "shots": [true], "quad": 3,
		"hits": [{"shield": 0, "hull": 40, "section": "mid"}]})
	if result.impacts.is_empty():
		_fail("The torpedo had no impact")
		return
	await _hold(at + float(result.impacts[0]) - bench.fx.now + 0.14, "fatal", 0.0)
	_chapter("tell")
	var start: float = bench.fx.now
	bench.fx.death("T", "big")
	var core: float = bench.fx.death_core_at("T")
	var split: float = float(target.get_meta("death_split", start + 2.0))
	var cool: float = float(target.get_meta("death_timeline").cool) if target.has_meta("death_timeline") else 14.0
	var marks := {"strain_early": start + 0.7, "strain_late": start + 1.7, "split": split + 0.18, "core": core + 0.08,
		"wreck": split + 3.8, "settled": split + 8.0, "cold": split + cool}
	row["kill_at"] = start
	row["split_at"] = split
	while bench.fx.now < float(marks.cold) + 0.12:
		await _step(true)
		for key in marks:
			if not row.stills.has(key) and bench.fx.now >= float(marks[key]):
				if key in ["split", "wreck", "cold"]: _chapter(key)
				_still(key)
	row["frames"] = frame_number
	row["wreck"] = _wreck_spread("T", target.hull.L)
	_write("timeline.json", row, folder)
	print("CAPTURE1077 clip ", variant, " r", radius, " frames=", frame_number, " wreck=", JSON.stringify(row["wreck"]))


# How far the pieces lie from the break, in hull lengths, once the clip ends.
func _wreck_spread(id: String, L: float) -> Dictionary:
	var pts: Array = []
	var frags: Array = []
	for w in bench.fx.dstate.get("wrecks", []):
		if w["id"] != id: continue
		for nd in w["nodes"]:
			if is_instance_valid(nd): pts.append((nd as Node3D).global_position)
		for nd in w.get("frags", []):
			if is_instance_valid(nd): frags.append((nd as Node3D).global_position)
	var mid := Vector3.ZERO
	for p in pts: mid += p
	if not pts.is_empty(): mid /= pts.size()
	var main_max := 0.0
	var frag_max := 0.0
	for p in pts: main_max = maxf(main_max, (p as Vector3).distance_to(mid) / L)
	for p in frags: frag_max = maxf(frag_max, (p as Vector3).distance_to(mid) / L)
	return {"pieces": pts.size(), "fragments": frags.size(), "piece_from_middle_max_L": main_max, "fragment_from_middle_max_L": frag_max}


func _hold(seconds: float, key: String, still_offset: float) -> void:
	var start: float = bench.fx.now
	while bench.fx.now < start + seconds:
		await _step(true)
		if not row.stills.has(key) and bench.fx.now >= start + still_offset:
			_still(key)


func _step(rec: bool) -> void:
	await bench._step()
	if rec and record and bench.steps % 2 == 0:
		var img: Image = bench._grab()
		if img == null:
			_fail("GPU produced an empty frame")
			return
		if row.radius == 170:
			img = bench._crop(img, Vector2i(1280, 720), Vector2i(1280, 720))
		else:
			img.resize(1280, 720, Image.INTERPOLATE_BILINEAR)
		if img.save_jpg(folder.path_join("frame_%04d.jpg" % frame_number), 0.92) != OK:
			_fail("Could not save a clip frame")
		frame_number += 1


func _chapter(key: String) -> void:
	row.chapters.append({"name": key, "frame": frame_number, "fx_time": bench.fx.now})


func _still(key: String) -> void:
	var image: Image = bench._grab()
	if image == null or CAP.save_png(image, folder.path_join(key + ".png")) != OK:
		_fail("Could not stamp the " + key + " still")
		return
	# a light copy for the sheet (the png stays on the PC): the battle camera a 1 to 1 centre crop, the close camera halved
	var small: Image = bench._crop(image, Vector2i(960, 540), Vector2i(960, 540)) if row.radius == 170 else image.duplicate()
	if row.radius != 170: small.resize(960, 540, Image.INTERPOLATE_LANCZOS)
	small.save_jpg(folder.path_join(key + "_sheet.jpg"), 0.9)
	row.stills[key] = {"frame": frame_number, "fx_time": bench.fx.now}


# ---------------------------------------------------------------- timing (solo on the GPU, R293)

func _timing() -> Dictionary:
	record = false
	var ids := ["T0", "T1", "T2", "T3"]
	var variant := "strain" if OS.get_environment("VS_DEATH_STORY") == "strain" else "off"
	await _scene(variant, 170, ids)
	if failed: return {}
	var vrid: RID = bench.vp.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vrid, true)
	for id in ids:
		bench.fx.sync_ship(id, bench._unit(0.199, 0))
	# every cut job done and its pieces built before the first kill, as a battle prepares them under cover. These
	# preparation frames are timed too (Artoo on PR 1171: the prebuild is where a player may pay the cost); a run that
	# times out says so ("prepared": false) instead of timing deaths on unprepared hulls silently.
	var prep_wall: Array = []
	var prep_gpu: Array = []
	var t_wait := Time.get_ticks_msec()
	var all_built := false
	while Time.get_ticks_msec() - t_wait < 120000:
		prep_wall.append(await _frame())
		prep_gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vrid))
		all_built = true
		for id in ids:
			if not (bench.fx.ship(id).get_meta("cut_job", {}) as Dictionary).get("built", false): all_built = false
		if all_built: break
	if not all_built: _fail("the cut jobs did not finish within 120 s: the prepared timing below is not valid")
	var res := {"variant": variant, "path": "prepared: warm-up at load, cut jobs and pieces built before each kill",
		"prepared": all_built, "prepare": {"frames": prep_wall.size(), "wall": _stats(prep_wall), "gpu": _stats(prep_gpu),
			"wall_ms": prep_wall.map(func(x: float) -> float: return snappedf(x, 0.01))}, "idle": await _window(120), "deaths": []}
	# the first death after preparation (first use of the death and fracture materials), then one, two and three at once
	var groups := [["T0"], ["T1"], ["T2", "T3"]]
	await _settle_frames(60)
	for g in groups:
		var t0 := Time.get_ticks_usec()
		for id in g: bench.fx.death(id, "big")
		var kill_ms := (Time.get_ticks_usec() - t0) / 1000.0
		var w := await _window(int(6.5 * 60))
		w["kill_call_ms"] = kill_ms
		w["ships"] = g.size()
		w["first_use"] = res["deaths"].is_empty()
		w["first_use_meaning"] = "first kill in this process after warm-up and prepared pieces; the cold spike is the cold mode"
		res["deaths"].append(w)
		print("CAPTURE1077 timing ", variant, " ships=", g.size(), " first=", w["first_use"], " wall_p50=%.2f p95=%.2f worst=%.2f gpu_p50=%.2f p95=%.2f worst=%.2f" % [
			w.wall.p50, w.wall.p95, w.wall.worst, w.gpu.p50, w.gpu.p95, w.gpu.worst])
		await _settle_frames(240)
	# three at once: a fresh set of three in the same process (cut jobs ready), after the others have cooled
	var trio := ["U0", "U1", "U2"]
	for i in trio.size():
		var v = bench.story_ship(trio[i], hulls[TARGET], Vector3(float(i - 1) * 46.0, 0, 40.0))
		if v == null:
			_fail("A16 did not load for the trio")
			return res
		bench.fx.sync_ship(trio[i], bench._unit(0.199, 0))
	t_wait = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t_wait < 120000:
		await _frame()
		var ready := true
		for id in trio:
			if not (bench.fx.ship(id).get_meta("cut_job", {}) as Dictionary).get("built", false): ready = false
		if ready: break
	await _settle_frames(60)
	var t1 := Time.get_ticks_usec()
	for id in trio: bench.fx.death(id, "big")
	var kill3 := (Time.get_ticks_usec() - t1) / 1000.0
	var w3 := await _window(int(6.5 * 60))
	w3["kill_call_ms"] = kill3
	w3["ships"] = 3
	w3["first_use"] = false
	res["deaths"].append(w3)
	print("CAPTURE1077 timing ", variant, " ships=3 wall_p50=%.2f p95=%.2f worst=%.2f gpu_p50=%.2f p95=%.2f worst=%.2f" % [
		w3.wall.p50, w3.wall.p95, w3.wall.worst, w3.gpu.p50, w3.gpu.p95, w3.gpu.worst])
	res["late_shaders"] = Bench.HULL.late_shader_names()
	return res


# The cold case (Artoo on PR 1171): a fresh process, no warm-up and no prepared cut (the game warms and cuts every ship
# under the loading cover, or a few tenths of a second after it is added, so this is the worst case, not the usual
# one): one A16 killed a few frames after it appears; the death starts the cut itself and the break waits for it.
# Records whether anything was prepared at the kill, so the path that ran is stated.
func _cold() -> Dictionary:
	record = false
	var variant := "strain" if OS.get_environment("VS_DEATH_STORY") == "strain" else "off"
	await _scene(variant, 170, ["C0"], false)
	if failed: return {}
	var vrid: RID = bench.vp.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vrid, true)
	var idle := await _window(6)
	var s = bench.fx.ship("C0")
	var had_job: bool = s.has_meta("cut_job") or s.has_meta("cut_task")
	var t0 := Time.get_ticks_usec()
	bench.fx.sync_ship("C0", bench._unit(0.199, 0))
	bench.fx.death("C0", "big")
	var kill_ms := (Time.get_ticks_usec() - t0) / 1000.0
	# Artoo on PR 1171: death_split is the planned cut time, and since #1138 a worker that misses its deadline ends in the
	# no-pieces pop, which also hides the hull. So the hide is observed here (frame and time after the kill), the real
	# pieces are counted, and the row is labelled fractured, fallback (no pieces) or unresolved.
	var seen := {"frame": -1, "t": -1.0}
	var t_kill: float = bench.fx.now
	var w := await _window(int(6.5 * 60), func(i: int) -> void:
		if int(seen["frame"]) < 0 and s.has_meta("death_hidden"):
			seen["frame"] = i
			seen["t"] = bench.fx.now - t_kill)
	var pieces := 0
	var frags := 0
	for wr in bench.fx.dstate.get("wrecks", []):
		if wr.get("id", "") != "C0": continue
		for nd in wr.get("nodes", []): if is_instance_valid(nd): pieces += 1
		for nd in wr.get("frags", []): if is_instance_valid(nd): frags += 1
	var outcome := "unresolved" if int(seen["frame"]) < 0 else ("fractured" if pieces > 0 else "fallback (no pieces)")
	w["kill_call_ms"] = kill_ms
	w["ships"] = 1
	w["first_use"] = true
	w["cut_job_before_kill"] = had_job
	w["planned_split_s"] = float(s.get_meta("death_split", 0.0)) - float(s.get_meta("death_start", 0.0)) if s.has_meta("death_start") else -1.0
	w["hidden_frame"] = int(seen["frame"])
	w["hidden_after_s"] = float(seen["t"])
	w["hull_pieces"] = pieces
	w["fragments"] = frags
	w["outcome"] = outcome
	print("CAPTURE1077 cold ", variant, " prepared_before_kill=", had_job, " outcome=", outcome, " hidden_frame=", seen["frame"],
		" hidden_after=%.2fs pieces=%d frags=%d" % [float(seen["t"]), pieces, frags],
		" wall_p50=%.2f p95=%.2f worst=%.2f gpu_worst=%.2f" % [w.wall.p50, w.wall.p95, w.wall.worst, w.gpu.worst])
	return {"variant": variant, "path": "cold: fresh process, no warm-up, killed with no prepared cut", "idle": idle, "deaths": [w],
		"late_shaders": Bench.HULL.late_shader_names()}


func _frame() -> float:
	var t0 := Time.get_ticks_usec()
	bench.fx.step(Bench.STEP)
	bench.steps += 1
	await RenderingServer.frame_post_draw
	return (Time.get_ticks_usec() - t0) / 1000.0


func _settle_frames(n: int) -> void:
	for i in n: await _frame()


func _window(frames: int, on_frame := Callable()) -> Dictionary:
	var wall: Array = []
	var gpu: Array = []
	var cpu: Array = []
	var vrid: RID = bench.vp.get_viewport_rid()
	for i in frames:
		wall.append(await _frame())
		if on_frame.is_valid(): on_frame.call(i)
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vrid))
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(vrid))
	return {"frames": frames, "wall": _stats(wall), "gpu": _stats(gpu), "render_cpu": _stats(cpu),
		"wall_ms": wall.map(func(x: float) -> float: return snappedf(x, 0.01)), "gpu_ms": gpu.map(func(x: float) -> float: return snappedf(x, 0.01))}


func _stats(a: Array) -> Dictionary:
	var s := a.duplicate()
	s.sort()
	if s.is_empty(): return {"p50": 0.0, "p95": 0.0, "worst": 0.0}
	return {"p50": s[s.size() / 2], "p95": s[mini(s.size() - 1, int(s.size() * 0.95))], "worst": s[-1]}


func _write(file: String, data: Variant, directory: String) -> void:
	var output := FileAccess.open(directory.path_join(file), FileAccess.WRITE)
	if output == null:
		_fail("Could not write " + file)
		return
	output.store_string(JSON.stringify(data, "  ") + "\n")
