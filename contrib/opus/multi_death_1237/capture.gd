extends SceneTree
## Issue 1237: three capitals dying at once, timed on the PC (Forward+, 1920x1080, --fixed-fps 60, GPU solo).
## Built on issue 1077's timing capture (contrib/opus/flagship_death_1077/capture.gd): the same look bench, ships and
## camera (radius 170), three A16 (C19_51, the installed hull) side by side. Runs on main (before) and on the branch
## (after); everything it reads exists on both.
## Arguments after --: mode, output directory.
##   prepared  warm-up at load, every cut job and its pieces built, then all three killed on one frame (Artoo on the
##             issue: this is the run that measures the pool and sleep fix). 12 s window from the kill.
##   cold      a fresh process, no warm-up, nothing prepared, all three killed a few frames after they appear (the stress
##             case; first-use slicing may dominate it, see 1232).
## Per frame: wall time between drawn frames, the viewport's GPU and render CPU times, Jolt's active body count, the
## debris plates still awake. Also: hull pieces and fragments spawned per ship (fractured or the no-piece fallback), the
## 1232 state (cut job before the kill), and on the branch the picture pool's made and reused counts.
## Output: <out>/<mode>.json and one CAPTURE1237 line per result in the log.

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
const BUDGET_MS := 12.5       # the scene gate (issue 1070)

var bench: Bench
var out: String
var failed := false
var hulls: Dictionary


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("CAPTURE1237 usage: -- prepared|cold <out>")
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
	var info := {"mode": mode, "commit": OS.get_environment("CAPTURE1237_SHA"), "adapter": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(), "godot": Engine.get_version_info().string,
		"ship_manifest_sha256": FileAccess.get_sha256("res://assets/ships/manifest.json"), "budget_ms": BUDGET_MS}
	info["result"] = await _three(mode == "prepared")
	_write(mode + ".json", info)
	bench._clear()
	bench.queue_free()
	await process_frame
	Bench.FX.clear_static()
	Bench.SV.clear_static()
	print("CAPTURE1237 ", "FAILED" if failed else "DONE")
	quit(1 if failed else 0)


func _fail(message: String) -> void:
	failed = true
	push_error("CAPTURE1237 " + message)


func _three(prepared: bool) -> Dictionary:
	bench._clear()
	bench._make_fx()
	bench._cam(Vector3.ZERO, 170)
	bench.fx.rng.seed = 11
	seed(2070)
	var ids := ["T0", "T1", "T2"]
	for i in ids.size():
		var v = bench.story_ship(ids[i], hulls[TARGET], Vector3(float(i - 1) * 46.0, 0, 0))
		if v == null or v.code != CODE:
			_fail("A16 did not load its installed hull")
			return {}
	var vrid: RID = bench.vp.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vrid, true)
	var all_built := false
	if prepared:
		await bench.fx.warmup(bench.cam)
		var t_wait := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t_wait < 120000:
			await _frame()
			all_built = true
			for id in ids:
				if not (bench.fx.ship(id).get_meta("cut_job", {}) as Dictionary).get("built", false): all_built = false
			if all_built: break
		if not all_built: _fail("the cut jobs did not finish within 120 s: this prepared run is not valid")
		for i in 60: await _frame()
	else:
		for i in 3: await _frame()
	var before: Array = []
	for id in ids:
		var s = bench.fx.ship(id)
		before.append(s.has_meta("cut_job") or s.has_meta("cut_task"))
	var pics = bench.fx.pictures() if bench.fx.has_method("pictures") else null
	var made0: int = pics.made if pics != null else -1
	var reused0: int = pics.reused if pics != null else -1
	var idle := await _window(60)
	for id in ids: bench.fx.sync_ship(id, bench._unit(0.199, 0))
	var t0 := Time.get_ticks_usec()
	for id in ids: bench.fx.death(id, "big")
	var kill_ms := (Time.get_ticks_usec() - t0) / 1000.0
	var t_kill: float = bench.fx.now
	var w := await _window(12 * 60)
	# the effect-clock time after the kill when Jolt's active body count last reached 0 and stayed there
	var rest_at := -1.0
	var act: Array = w["awake_fx_bodies"]
	var times: Array = w["fx_t"]
	for i in range(act.size() - 1, -1, -1):
		if int(act[i]) > 0:
			rest_at = float(times[i + 1]) - t_kill if i + 1 < times.size() else -1.0
			break
	if act.size() > 0 and int(act.max()) == 0: rest_at = 0.0
	var pieces: Dictionary = {}
	for wr in bench.fx.dstate.get("wrecks", []):
		var n := 0
		var f := 0
		for nd in wr.get("nodes", []): if is_instance_valid(nd): n += 1
		for nd in wr.get("frags", []): if is_instance_valid(nd): f += 1
		pieces[str(wr.get("id", ""))] = {"hull_pieces": n, "fragments": f, "outcome": "fractured" if n > 0 else "fallback (no pieces)"}
	var res := {"path": "prepared: warm-up, cut jobs and pieces built before the kill" if prepared else "cold: fresh process, no warm-up, nothing prepared",
		"prepared": all_built, "cut_job_before_kill": before, "kill_call_ms": kill_ms, "idle": idle, "deaths": w,
		"active_bodies_zero_after_s": rest_at, "pieces": pieces, "late_shaders": Bench.HULL.late_shader_names()}
	if pics != null:
		res["pictures"] = {"made": pics.made - made0, "reused": pics.reused - reused0, "free": pics.free_count()}
	# Artoo on PR 1255: the prepared run is proof only if it was prepared, all three fractured for real, p99 is inside the
	# gate and Jolt is idle within 8 s. The cold run is a stress result: reported, never gated.
	var fractured := 0
	for k in pieces: if String(pieces[k]["outcome"]) == "fractured": fractured += 1
	# INVALID: the fixture did not hold (not prepared, or fewer than three real fractures), so the run measures nothing.
	# MISS: a valid run whose timing or rest is over the line (main's misses are the baseline). Both exit non-zero.
	var bad: Array = []
	var miss: Array = []
	if prepared:
		if not all_built: bad.append("not prepared")
		if fractured < 3: bad.append("%d of 3 fractured" % fractured)
		if float(w.wall.p99) > BUDGET_MS: miss.append("p99 %.2f ms over %.1f" % [w.wall.p99, BUDGET_MS])
		if rest_at < 0.0 or rest_at > 8.0: miss.append("active bodies not 0 within 8 s (%.2f)" % rest_at)
	res["fractured"] = fractured
	if not prepared: res["gate"] = "STRESS (not gated)"
	elif not bad.is_empty(): res["gate"] = "INVALID: " + ", ".join(bad + miss)
	elif not miss.is_empty(): res["gate"] = "MISS: " + ", ".join(miss)
	else: res["gate"] = "PASS"
	if prepared and not (bad.is_empty() and miss.is_empty()): failed = true
	print("CAPTURE1237 GATE %s %s" % ["prepared" if prepared else "cold", res["gate"]])
	print("CAPTURE1237 %s kill=%.1f ms wall p50=%.2f p95=%.2f p99=%.2f worst=%.2f gpu p99=%.2f budget=%.1f within=%s bodies_peak=%d zero_after=%.2f s pieces=%s pictures=%s" % [
		"prepared" if prepared else "cold", kill_ms, w.wall.p50, w.wall.p95, w.wall.p99, w.wall.worst, w.gpu.p99, BUDGET_MS,
		str(w.wall.p99 <= BUDGET_MS), int(act.max()) if not act.is_empty() else 0, rest_at, JSON.stringify(pieces),
		JSON.stringify(res.get("pictures", "n/a on this commit"))])
	return res


func _frame() -> float:
	var t0 := Time.get_ticks_usec()
	bench.fx.step(Bench.STEP)
	bench.steps += 1
	await RenderingServer.frame_post_draw
	return (Time.get_ticks_usec() - t0) / 1000.0


func _awake_plates() -> int:
	var n := 0
	for b in bench.fx.dstate.get("debris", []):
		if is_instance_valid(b) and not (b as RigidBody3D).sleeping: n += 1
	return n


# Godot's PHYSICS_3D_ACTIVE_OBJECTS monitor reads 0 under Jolt (TIMING4 on the PC: 0 on every frame, both commits), so the
# rest gate counts fx's own moving bodies: awake plates plus wreck sections still simulated (processing, not frozen,
# not asleep).
func _awake_bodies() -> int:
	var n := _awake_plates()
	for wr in bench.fx.dstate.get("wrecks", []):
		for nd in wr.get("nodes", []):
			if is_instance_valid(nd) and nd is RigidBody3D and nd.can_process() and not nd.freeze and not nd.sleeping: n += 1
	return n


func _window(frames: int) -> Dictionary:
	var wall: Array = []
	var gpu: Array = []
	var cpu: Array = []
	var bodies: Array = []
	var plates: Array = []
	var fxbodies: Array = []
	var ft: Array = []
	var vrid: RID = bench.vp.get_viewport_rid()
	for i in frames:
		wall.append(await _frame())
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vrid))
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(vrid))
		bodies.append(int(Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)))
		plates.append(_awake_plates())
		fxbodies.append(_awake_bodies())
		ft.append(snappedf(bench.fx.now, 0.001))
	return {"frames": frames, "wall": _stats(wall), "gpu": _stats(gpu), "render_cpu": _stats(cpu),
		"wall_ms": wall.map(func(x: float) -> float: return snappedf(x, 0.01)), "gpu_ms": gpu.map(func(x: float) -> float: return snappedf(x, 0.01)),
		"active_bodies": bodies, "awake_plates": plates, "awake_fx_bodies": fxbodies, "fx_t": ft}


func _stats(a: Array) -> Dictionary:
	var s := a.duplicate()
	s.sort()
	if s.is_empty(): return {"p50": 0.0, "p95": 0.0, "p99": 0.0, "worst": 0.0}
	return {"p50": s[s.size() / 2], "p95": s[mini(s.size() - 1, int(s.size() * 0.95))],
		"p99": s[mini(s.size() - 1, int(s.size() * 0.99))], "worst": s[-1]}


func _write(file: String, data: Variant) -> void:
	var output := FileAccess.open(out.path_join(file), FileAccess.WRITE)
	if output == null:
		_fail("Could not write " + file)
		return
	output.store_string(JSON.stringify(data, "  ") + "\n")
