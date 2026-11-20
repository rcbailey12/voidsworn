extends SceneTree
## Issue 1289: what a ship arriving mid-battle costs on the PC (GPU, Forward+, 1920x1080), and whether the fix removes it.
## One mode per process, in its own empty profile (an empty shader and shield cache, as a first session):
##   arrival    the battle's load (prepare_battle_hulls and the warm-up, the shooter only), 60 frames of play, then the hull
##              arrives as a reinforcement does (ShipView.setup, fx.add_ship and its sync in the arrival frame) and is
##              killed 6 frames later (issue 1232's case)
##   again      the same hull arrives once, leaves, and arrives a second time 60 frames later: the second arrival is timed
##              (what is first-time-per-hull and what every arrival pays)
##   prewarmed  as arrival, but the load also builds the arriving hull through the fix's kit (render/arrival_warm.gd), as
##              the battle now does for its reinforcement event; skipped (exit 0, "skipped") on a commit without the kit
##   firstkill  the hull is on the board at the load, warmed and cut with the others; killed after 60 frames of play
##   cold       nothing warmed at all: the hull appears and is killed 6 frames later (issue 1077 and 1232's cold rows)
## The arrival frame is timed in parts: view (ShipView.setup), fx_add (fx.add_ship), sync, step (fx.step), render (the rest,
## to frame_post_draw), with the renderer's own CPU and GPU time, the pipelines built by kind, and fx's named long steps.
## Frames are paced to 60 a second. Output: <out>/<mode>_<tpl>.json and one CAPTURE1289 line.
## Usage: -- <mode> <out> [hull tpl, default c_boss (A16, C19_51)]. Built on contrib/opus/cold_kill_1232/capture1232.gd.

class Bench extends "res://bench/look_bench.gd":
	func _ready() -> void:
		pass

	func unit_of(id: String, tpl: String, spec: Dictionary) -> Dictionary:
		return {"id": id, "tpl": tpl, "fac": spec.fac, "cls": spec.cls, "size": spec.size, "facing": 3,
			"hp": spec.hp, "maxHp": spec.hp, "squadron": false, "flagship": false}

	# a ship as battle._make_view builds it, timed in parts (ms)
	func story_ship(id: String, tpl: String, spec: Dictionary, pos: Vector3, parts := {}):
		var t0 := Time.get_ticks_usec()
		var view = SV.new()
		view.name = "ship_" + id
		world.add_child(view)
		view.setup(unit_of(id, tpl, spec), pos, true)
		view.set_process(false)
		var t1 := Time.get_ticks_usec()
		parts["view"] = (t1 - t0) / 1000.0
		if (not view.a4 or _is_block(view)) and OS.get_environment("VS_1289_DRY") == "":   # a cloud dry run allows blocks
			return null
		fx.add_ship(id, view, {"faction": spec.fac, "cls": spec.cls, "code": view.code,
			"size": spec.size, "flagship": spec.get("boss", false), "squadron": false})
		view.fx_engines = true
		fx.set_engine(id, 0.3)
		var t2 := Time.get_ticks_usec()
		parts["fx_add"] = (t2 - t1) / 1000.0
		fx.sync_ship(id, _unit(1.0, 5))
		parts["sync"] = (Time.get_ticks_usec() - t2) / 1000.0
		return view

const API := preload("res://rules/battle_api.gd")
const KIT := "res://render/arrival_warm.gd"
const SHOOTER := "penitent"   # a Sunward Vigil, as in issues 1076, 1077 and 1232

var bench: Bench
var HEADLESS := DisplayServer.get_name() == "headless"
var failed := false
var hulls: Dictionary
var tpl := "c_boss"
var _pipe0 := {}
var _prof0 := {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2 or not args[0] in ["arrival", "again", "prewarmed", "firstkill", "cold"]:
		push_error("CAPTURE1289 usage: -- arrival|again|prewarmed|firstkill|cold <out> [tpl]")
		quit(2)
		return
	var mode: String = args[0]
	var out: String = args[1]
	if args.size() > 2: tpl = args[2]
	DirAccess.make_dir_recursive_absolute(out)
	if mode == "prewarmed" and not ResourceLoader.exists(KIT):
		_write(out.path_join("%s_%s.json" % [mode, tpl]), {"mode": mode, "tpl": tpl, "skipped": "no render/arrival_warm.gd on this commit"})
		print("CAPTURE1289 %s %s skipped (no kit on this commit)" % [mode, tpl])
		quit(0)
		return
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
	if not hulls.has(tpl):
		_fail("no hull " + tpl)
		quit(2)
		return
	bench = Bench.new()
	root.add_child(bench)
	bench._setup_view()
	bench._cam(Vector3.ZERO, 170.0)
	await bench._world({"rock": "stone", "planet": 4}, {}, [])
	var info := {"mode": mode, "tpl": tpl, "commit": _commit(), "adapter": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(), "godot": Engine.get_version_info().string,
		"cores": OS.get_processor_count()}
	info["result"] = await _go(mode)
	_write(out.path_join("%s_%s.json" % [mode, tpl]), info)
	bench._clear()
	bench.queue_free()
	await process_frame
	Bench.FX.clear_static()
	Bench.SV.clear_static()
	print("CAPTURE1289 ", "FAILED" if failed else "DONE")
	quit(1 if failed else 0)


func _go(mode: String) -> Dictionary:
	bench._clear()
	OS.set_environment("VS_DEATH_STORY", "off")
	bench._make_fx()
	bench._cam(Vector3.ZERO, 170)
	bench.fx.rng.seed = 11
	seed(2070)
	var vrid: RID = bench.vp.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vrid, true)
	Bench.HULL.reset_late()
	var spec: Dictionary = hulls[tpl]
	var res := {"mode": mode}
	var kit = null
	var t_load := Time.get_ticks_usec()
	if mode != "cold":
		# the battle's load: every ship on the board, cut and drawn under the cover (battle._warmup)
		bench.fx.defer_initial_cuts = true
	bench.A = bench.story_ship("A", SHOOTER, hulls[SHOOTER], Vector3(-35.0, 0, 18.0))
	if mode == "firstkill":
		if bench.story_ship("C0", tpl, spec, Vector3.ZERO) == null:
			_fail("%s did not load an installed hull" % tpl)
			return res
	if mode == "prewarmed":
		kit = load(KIT).new()
		kit.prepare(bench.world, bench.fx, [bench.unit_of("arrival_warm_0", tpl, spec)], Vector3(30.0, 0, -20.0))
		for i in 2: await _frame()
	if mode != "cold":
		# the bench's effects are stepped by hand (fx.manual), so frames keep coming while the load's cuts and pieces finish
		var done := [false]
		var prep := func() -> void:
			await bench.fx.prepare_battle_hulls()
			done[0] = true
		prep.call()
		var guard := 0
		while not done[0] and guard < 60 * 120:
			guard += 1
			await _frame()
		res["load_prepare_frames"] = guard
		if not HEADLESS: await bench.fx.warmup(bench.cam)
		if kit != null: kit.park()
		for i in 60: await _frame()
	res["load_ms"] = (Time.get_ticks_usec() - t_load) / 1000.0
	Bench.HULL.start_late_watch()
	var s = null
	if mode == "firstkill":
		s = bench.fx.ship("C0")
	else:
		if mode == "again":
			var first := await _arrive("C9", spec)
			res["first_arrival"] = first
			bench.fx.remove_ship("C9")
			var n9 = bench.world.get_node_or_null("ship_C9")
			if n9 != null:
				bench.world.remove_child(n9)
				n9.queue_free()
			for i in 60: await _frame()
		var arr := await _arrive("C0", spec)
		if arr.is_empty(): return res
		res["arrival"] = arr
		s = bench.fx.ship("C0")
	# the kill (6 frames after the arrival, or after 60 frames of play for firstkill)
	var cut_ready: bool = s.has_meta("cut_job") and not s.has_meta("cut_task")
	_mark()
	var t_kill := Time.get_ticks_usec()
	bench.fx.sync_ship("C0", bench._unit(0.199, 0))
	bench.fx.death("C0", "big")
	var kill_call_ms := (Time.get_ticks_usec() - t_kill) / 1000.0
	var t_fx: float = bench.fx.now
	var seen := {"frame": -1, "t": -1.0}
	var kill := await _window(60 * 9, func(i: int) -> void:
		if int(seen["frame"]) < 0 and s.has_meta("death_hidden"):
			seen["frame"] = i
			seen["t"] = bench.fx.now - t_fx)
	var pieces := 0
	for wr in bench.fx.dstate.get("wrecks", []):
		if wr.get("id", "") != "C0": continue
		for nd in wr.get("nodes", []): if is_instance_valid(nd): pieces += 1
	res["kill"] = {"cut_ready_at_kill": cut_ready, "kill_call_ms": kill_call_ms, "window": kill, "pipelines": _pipes_since(),
		"hidden_after_s": float(seen["t"]), "hull_pieces": pieces,
		"outcome": "unresolved" if int(seen["frame"]) < 0 else ("fractured" if pieces > 0 else "fallback (no pieces)")}
	res["late_shaders"] = Bench.HULL.late_shader_names()
	var a: Dictionary = res.get("arrival", {})
	var f0: Dictionary = a.get("frame0", {})
	var worst_arr := float(a.get("worst_ms", 0.0))
	var worst_kill := maxf(kill_call_ms + float(kill.wall.worst), float(kill.wall.worst))
	res["worst_frame_ms"] = maxf(worst_arr, worst_kill)
	print("CAPTURE1289 %s %s arrive_worst=%.1f [view=%.1f fx_add=%.1f sync=%.1f step=%.1f render=%.1f rs_cpu=%.1f pipes=%s] first_arrival_worst=%.1f kill_call=%.1f kill_worst=%.1f outcome=%s pieces=%d late=%d worst=%.1f" % [
		mode, tpl, worst_arr, float(f0.get("view", 0)), float(f0.get("fx_add", 0)), float(f0.get("sync", 0)), float(f0.get("step", 0)),
		float(f0.get("render", 0)), float(f0.get("rs_cpu", 0)), str(f0.get("pipelines", {})),
		float(res.get("first_arrival", {}).get("worst_ms", -1.0)), kill_call_ms, float(kill.wall.worst), res["kill"]["outcome"], pieces,
		(res["late_shaders"] as Array).size(), float(res["worst_frame_ms"])])
	return res


# A hull arrives as a reinforcement does: built inside the frame it appears in, then 6 more frames.
func _arrive(id: String, spec: Dictionary) -> Dictionary:
	bench.fx.defer_initial_cuts = false
	_mark()
	var parts := {}
	var t0 := Time.get_ticks_usec()
	var v = bench.story_ship(id, tpl, spec, Vector3.ZERO, parts)
	if v == null:
		_fail("%s did not load an installed hull" % tpl)
		return {}
	var built_ms := (Time.get_ticks_usec() - t0) / 1000.0
	var f0 := await _frame_parts()
	f0.merge(parts)
	f0["total"] = built_ms + float(f0["step"]) + float(f0["render"])
	f0["pipelines"] = _pipes_since()
	f0["long_steps"] = _prof_since()
	_mark()
	var rest := await _window(6)
	return {"frame0": f0, "next6": rest, "next6_pipelines": _pipes_since(),
		"worst_ms": maxf(float(f0["total"]), float(rest.wall.worst)), "code": v.code}


func _mark() -> void:
	_pipe0 = _pipe_counts()
	_prof0 = bench.fx.prof.duplicate() if bench.fx.get("prof") is Dictionary else {}


func _pipe_counts() -> Dictionary:
	var out := {}
	for m in ["PIPELINE_COMPILATIONS_CANVAS", "PIPELINE_COMPILATIONS_MESH", "PIPELINE_COMPILATIONS_SURFACE", "PIPELINE_COMPILATIONS_DRAW", "PIPELINE_COMPILATIONS_SPECIALIZATION"]:
		if ClassDB.class_has_integer_constant("Performance", m):
			out[m.trim_prefix("PIPELINE_COMPILATIONS_").to_lower()] = int(Performance.get_monitor(ClassDB.class_get_integer_constant("Performance", m)))
	return out


func _pipes_since() -> Dictionary:
	var now := _pipe_counts()
	var out := {}
	for k in now:
		var d := int(now[k]) - int(_pipe0.get(k, 0))
		if d != 0: out[k] = d
	return out


# fx's own named long steps (issue 220 prof) since the mark, over 2 ms
func _prof_since() -> Dictionary:
	var out := {}
	var p = bench.fx.get("prof")
	if not (p is Dictionary): return out
	for k in p:
		var d := (int(p[k]) - int(_prof0.get(k, 0))) / 1000.0
		if d >= 2.0: out[str(k)] = snappedf(d, 0.1)
	return out


# One frame in parts: fx.step, then the render to frame_post_draw (the rest of the engine's frame).
func _frame_parts() -> Dictionary:
	var vrid: RID = bench.vp.get_viewport_rid()
	var t0 := Time.get_ticks_usec()
	bench.fx.step(1.0 / 60.0)
	bench.steps += 1
	var t1 := Time.get_ticks_usec()
	if HEADLESS: await process_frame   # a dry run of the steps only: the headless renderer never posts a draw
	else: await RenderingServer.frame_post_draw
	var t2 := Time.get_ticks_usec()
	var ms := (t2 - t0) / 1000.0
	if ms < 16.6: OS.delay_usec(int((16.6 - ms) * 1000.0))
	return {"step": (t1 - t0) / 1000.0, "render": (t2 - t1) / 1000.0,
		"rs_cpu": RenderingServer.viewport_get_measured_render_time_cpu(vrid),
		"gpu": RenderingServer.viewport_get_measured_render_time_gpu(vrid)}


func _frame() -> float:
	var p := await _frame_parts()
	return float(p["step"]) + float(p["render"])


func _window(frames: int, on_frame := Callable()) -> Dictionary:
	var wall: Array = []
	var gpu: Array = []
	var vrid: RID = bench.vp.get_viewport_rid()
	for i in frames:
		wall.append(await _frame())
		if on_frame.is_valid(): on_frame.call(i)
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vrid))
	return {"frames": frames, "wall": _stats(wall), "gpu": _stats(gpu),
		"over_100ms": wall.filter(func(x: float) -> bool: return x > 100.0).size(),
		"wall_ms": wall.slice(0, 30).map(func(x: float) -> float: return snappedf(x, 0.01))}


func _stats(a: Array) -> Dictionary:
	var s := a.duplicate()
	s.sort()
	if s.is_empty(): return {"p50": 0.0, "p95": 0.0, "worst": 0.0}
	return {"p50": s[s.size() / 2], "p95": s[mini(s.size() - 1, int(s.size() * 0.95))], "worst": s[-1]}


func _write(path: String, data: Variant) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_fail("Could not write " + path)
		return
	f.store_string(JSON.stringify(data, "  ") + "\n")


func _commit() -> String:
	var f := FileAccess.get_file_as_string("res://build_info.json")
	var j = JSON.parse_string(f) if not f.is_empty() else null
	return str(j.get("commit", "")) if j is Dictionary else ""


func _fail(message: String) -> void:
	failed = true
	push_error("CAPTURE1289 " + message)
