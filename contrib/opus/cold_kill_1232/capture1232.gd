extends SceneTree
## Issue 1232: frame times of a capital's first death, on the PC (GPU, Forward+, 1920x1080), one mode per process.
##   arrival  the battle-like case: the scene warms up at load with only the shooter, then A16 (C19_51) arrives (as a
##            reinforcement does) and is killed 6 frames after it appears, before its cut is ready.
##   cold     the bench worst case: nothing warmed at all, A16 killed 6 frames after it appears (as issue 1077's cold rows).
## Frames are paced to 60 a second in real time, as the game runs, so the death's cut gets the time it gets in a battle.
## Per frame: wall time and GPU time. Also: pipelines compiled in the window, hull shaders built late (named), whether the
## hull broke into pieces, and when. Output: <out>/<mode>.json and one CAPTURE1232 line.
## Built on contrib/opus/flagship_death_1077/capture.gd (the same bench, ships and kill). Run by OPUS1232_RUN.bat.

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
const TARGET := "c_boss"      # A16, Ashfall Hullbreakers battle-barge (C19_51)
const CODE := "C19_51"
const SHOOTER := "penitent"   # a Sunward Vigil, as in issues 1076 and 1077

var bench: Bench
var failed := false
var hulls: Dictionary
var _last := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2 or not args[0] in ["arrival", "cold"]:
		push_error("CAPTURE1232 usage: -- arrival|cold <out>")
		quit(2)
		return
	var mode: String = args[0]
	var out: String = args[1]
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
	bench._setup_view()
	bench._cam(Vector3.ZERO, 170.0)
	await bench._world({"rock": "stone", "planet": 4}, {}, [])
	var info := {"mode": mode, "commit": _commit(), "adapter": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(), "godot": Engine.get_version_info().string,
		"shield_shape": OS.get_environment("VS_SHIELD_SHAPE") if OS.get_environment("VS_SHIELD_SHAPE") != "" else str(ProjectSettings.get_setting("rendering/effects/shield_shape", "fitted"))}
	info["result"] = await _kill(mode)
	_write(out.path_join(mode + ".json"), info)
	bench._clear()
	bench.queue_free()
	await process_frame
	Bench.FX.clear_static()
	Bench.SV.clear_static()
	print("CAPTURE1232 ", "FAILED" if failed else "DONE")
	quit(1 if failed else 0)


func _kill(mode: String) -> Dictionary:
	bench._clear()
	OS.set_environment("VS_DEATH_STORY", "off")
	bench._make_fx()
	bench._cam(Vector3.ZERO, 170)
	bench.fx.rng.seed = 11
	seed(2070)
	var vrid: RID = bench.vp.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vrid, true)
	Bench.HULL.reset_late()
	bench.A = bench.story_ship("A", hulls[SHOOTER], Vector3(-35.0, 0, 18.0))
	var load_ms := 0.0
	if mode == "arrival":
		# the loading cover: the battle warms what is on the board (here only the shooter), then play starts
		var t0 := Time.get_ticks_usec()
		await bench.fx.warmup(bench.cam)
		for i in 60:
			await _frame()
		load_ms = (Time.get_ticks_usec() - t0) / 1000.0
	Bench.HULL.start_late_watch()   # every hull shader built from here on is named (cold too)
	var pipes0 := _pipes()
	var v = bench.story_ship("C0", hulls[TARGET], Vector3.ZERO)
	if v == null or v.code != CODE or not bench.fx.ship("C0").hull.authored:
		_fail("A16 did not load its installed hull with its authored seams")
		return {}
	var s = bench.fx.ship("C0")
	var arrive := await _window(6)
	var pipes_arrive := _pipes() - pipes0
	var cut_ready: bool = s.has_meta("cut_job") and not s.has_meta("cut_task")
	var t_kill := Time.get_ticks_usec()
	bench.fx.sync_ship("C0", bench._unit(0.199, 0))
	bench.fx.death("C0", "big")
	var kill_call_ms := (Time.get_ticks_usec() - t_kill) / 1000.0
	var t_fx: float = bench.fx.now
	var seen := {"frame": -1, "t": -1.0}
	# 9 s of frames paced to real time: past the fix's 5 s real-time cap on the wait for a late cut (fx_death.cold_cut_wall)
	var t_watch := Time.get_ticks_usec()
	var kill := await _window(60 * 9, func(i: int) -> void:
		if int(seen["frame"]) < 0 and s.has_meta("death_hidden"):
			seen["frame"] = i
			seen["t"] = bench.fx.now - t_fx)
	var pieces := 0
	var frags := 0
	for wr in bench.fx.dstate.get("wrecks", []):
		if wr.get("id", "") != "C0": continue
		for nd in wr.get("nodes", []): if is_instance_valid(nd): pieces += 1
		for nd in wr.get("frags", []): if is_instance_valid(nd): frags += 1
	var outcome := "unresolved" if int(seen["frame"]) < 0 else ("fractured" if pieces > 0 else "fallback (no pieces)")
	var watched_real_s := (Time.get_ticks_usec() - t_watch) / 1e6
	var res := {"path": mode, "watched_real_s": watched_real_s, "cap_real_s": _cap(), "load_ms": load_ms, "warm_arrival": bench.fx.has_method("warm_arrival"),
		"arrive": arrive, "pipelines_compiled_arrive": pipes_arrive, "cut_ready_at_kill": cut_ready, "kill_call_ms": kill_call_ms,
		"kill": kill, "pipelines_compiled_kill": _pipes() - pipes0 - pipes_arrive, "hidden_after_s": float(seen["t"]),
		"held_for_cut": s.has_meta("death_cut_wait"), "hull_pieces": pieces, "fragments": frags, "outcome": outcome,
		"late_shaders": Bench.HULL.late_shader_names()}
	print("CAPTURE1232 %s watched=%.1fs outcome=%s pieces=%d frags=%d hidden_after=%.2fs held_for_cut=%s cut_ready_at_kill=%s arrive_worst=%.1f kill_call=%.1f kill_worst=%.1f kill_p95=%.1f gpu_worst=%.2f pipes_arrive=%d pipes_kill=%d late=%d" % [
		mode, watched_real_s, outcome, pieces, frags, float(seen["t"]), str(res["held_for_cut"]), str(cut_ready), arrive.wall.worst, kill_call_ms,
		kill.wall.worst, kill.wall.p95, kill.gpu.worst, pipes_arrive, res["pipelines_compiled_kill"], res["late_shaders"].size()])
	return res


# the fix's real-time cap on the wait for a late cut; -1 on a commit without it (the before run)
func _cap() -> float:
	var v = (Bench.FX.DEATH as Script).get("cold_cut_wall")
	return float(v) if v != null else -1.0


func _pipes() -> int:
	var n := 0
	for m in ["PIPELINE_COMPILATIONS_DRAW", "PIPELINE_COMPILATIONS_SPECIALIZATION", "PIPELINE_COMPILATIONS_SURFACE", "PIPELINE_COMPILATIONS_MESH"]:
		if ClassDB.class_has_integer_constant("Performance", m):
			n += int(Performance.get_monitor(ClassDB.class_get_integer_constant("Performance", m)))
	return n


# One frame: a sixtieth of a second of effect time, paced to at least a sixtieth of a second of real time (the game runs
# with vsync), so a worker gets the time it gets in play. Returns the frame's own work time in ms.
func _frame() -> float:
	var t0 := Time.get_ticks_usec()
	bench.fx.step(1.0 / 60.0)
	bench.steps += 1
	await RenderingServer.frame_post_draw
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	if ms < 16.6: OS.delay_usec(int((16.6 - ms) * 1000.0))
	return ms


func _window(frames: int, on_frame := Callable()) -> Dictionary:
	var wall: Array = []
	var gpu: Array = []
	var vrid: RID = bench.vp.get_viewport_rid()
	for i in frames:
		wall.append(await _frame())
		if on_frame.is_valid(): on_frame.call(i)
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vrid))
	return {"frames": frames, "wall": _stats(wall), "gpu": _stats(gpu),
		"wall_ms": wall.map(func(x: float) -> float: return snappedf(x, 0.01))}


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
	push_error("CAPTURE1232 " + message)
