extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 521 (R193 "Hold and slow"; R73): the slow-motion beat plays at the core flash of a cruiser, capital or flagship
# kill once the battle turns it on (fx.kill_slowmo), never for a small hull, never while it is off (reduce motion), and a
# key or a click (skip_death_slowmo) ends it and stops a queued one. Headless.
#   godot --headless --path godot --script res://fx/test/kill_slowmo_check.gd
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const SV := preload("res://render/ship_view.gd")
var failures := 0

class BattleFixture extends "res://scenes/battle/battle.gd":
	func _ready() -> void:
		set_process(false)

class TestHud extends CanvasLayer:
	func letterbox(_on: bool) -> void:
		pass

	func remove_plate(_id: String) -> void:
		pass

class TestDeathAudio extends Node:
	var fx
	func watch(_id: String, _pos: Vector3) -> void:
		pass


func _init() -> void:
	GUARD.arm(self, "kill_slowmo_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _ship(world: Node3D, fx, id: String, cls: String, size: float, r: Node3D = null) -> void:
	if r == null:
		r = Node3D.new()
		world.add_child(r)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(12, 3, 4)
	bm.subdivide_width = 11
	bm.subdivide_height = 2
	bm.subdivide_depth = 3
	mi.mesh = bm
	r.add_child(mi)
	fx.add_ship(id, r, {"faction": "voidsworn", "cls": cls, "size": size, "meshes": [mi]})


# Plays a death with the beat on or off; returns [planned core, first slow frame, last slow frame].
func _play(cls: String, size: float, on: bool, skip_at := -1.0) -> Array:
	var world := Node3D.new()
	root.add_child(world)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low"})
	fx.kill_slowmo = on
	_ship(world, fx, "T", cls, size)
	var s = fx.ship("T")
	DEATH.precompute(fx, s)
	while not DEATH.finish_precompute(fx, s):
		await process_frame
	var t0: float = fx.now
	fx.death("T", "blast")
	var core: float = fx.death_core_at("T")
	var first := -1.0
	var last := -1.0
	var real_t := 0.0
	while real_t < 5.0:
		fx.step(1.0 / 60.0)
		real_t += 1.0 / 60.0
		if skip_at >= 0.0 and absf(real_t - skip_at) < 0.5 / 60.0:
			fx.skip_death_slowmo()
		if fx._death_slow_left > 0.0:
			if first < 0.0:
				first = fx.now - t0
				_check(is_equal_approx(_core_picture(fx, s.death_tier), fx.now), "on-time slow beat starts on the core picture's birth frame")
			last = fx.now - t0
	fx.release()
	world.queue_free()
	await process_frame
	return [core - t0 if core >= 0.0 else -1.0, first, last]


func _core_picture(fx, tier: String) -> float:
	for node in fx.get_children():
		if node.get_meta("fx_picture_kind", "") == "flash":
			var mat := (node as MeshInstance3D).material_override as ShaderMaterial
			if is_equal_approx(float(mat.get_shader_parameter("min_pixels")), float(DEATH.CORE_FLASH_PX[tier])):
				return float(mat.get_shader_parameter("born"))
	return -1.0


func _late_cut(stall_through_deadline: bool, release_past_deadline := false) -> void:
	var before := failures
	DEATH.cold_cut_wall = 1.0 if stall_through_deadline else 5.0
	var battle := BattleFixture.new()
	root.add_child(battle)
	battle.cam = battle.CamRig.new()
	battle.add_child(battle.cam)
	battle.hud = TestHud.new()
	battle.add_child(battle.hud)
	battle.death_audio = TestDeathAudio.new()
	battle.add_child(battle.death_audio)
	var fx := FX.new()
	battle.gfx = fx
	battle.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low"})
	var sv := SV.new()
	battle.add_child(sv)
	sv.set_process(false)
	sv.ring = MeshInstance3D.new()
	sv.add_child(sv.ring)
	_ship(battle, fx, "late", "Cruiser", 0.76, sv)
	battle.views["late"] = sv
	battle.VU["late"] = {"name": "Late", "side": "enemy", "size": 0.76}
	var s = fx.ship("late")
	DEATH.precompute(fx, s)
	while not DEATH.finish_precompute(fx, s):
		await process_frame
	# Keep a real fracture result behind a gate so the late path is independent of CPU speed.
	var gate := Semaphore.new()
	var work := func() -> void: gate.wait()
	var tid: int = fx.call("submit_death_cut", work) if fx.has_method("submit_death_cut") else WorkerThreadPool.add_task(work)
	s.set_meta("cut_task", tid)
	battle._play_death({"unit": "late"})
	var nominal := fx.death_core_at("late")
	var early := false
	while fx.now < nominal + 0.15:
		fx.step(1.0 / 60.0)
		early = early or fx._death_slow_left > 0.0
	_check(not early and _core_picture(fx, "cruiser") < 0.0, "a blocked cut has neither the nominal core nor an early slow beat")
	# Let the old wall-clock hold expire while the actual split is still pending.
	await create_timer(nominal + 0.9).timeout
	_check(not battle.cine_saved.is_empty(), "camera still holds after its old nominal release time")
	if not stall_through_deadline and not release_past_deadline:
		gate.post()
		while not WorkerThreadPool.is_task_completed(tid):
			await process_frame
	var born := -1.0
	if release_past_deadline:
		# issue 1232: a cut that finishes after the deadline still gives the hull its pieces; the tell holds until then
		var dl: float = float(s.get_meta("death_start")) + float(s.get_meta("death_timeline").end)
		while fx.now < dl + 0.5:
			fx.step(1.0 / 60.0)
			await process_frame
		_check(not s.has_meta("death_hidden"), "the hull holds its tell past the deadline while its cut runs")
		gate.post()
		while fx.has_method("submit_death_cut") and fx._death_cut_tasks.has(tid) and not WorkerThreadPool.is_task_completed(tid):
			await process_frame
	while born < 0.0 and fx.now < 4.0:
		fx.step(1.0 / 60.0)
		born = _core_picture(fx, "cruiser")
		await process_frame
	if release_past_deadline:
		_check(born > 0.0 and not fx.dstate.wrecks.is_empty() and not fx.dstate.wrecks[0].nodes.is_empty(),
			"the late cut breaks the hull into its pieces")
	if stall_through_deadline:
		# issue 1232: a cut still running at the deadline is waited for (in real time, DEATH.cold_cut_wall, lowered for this
		# check); a stuck one still ends in the no-pieces pop. This death started over cold_cut_wall ago, so it pops on time.
		var deadline: float = s.get_meta("death_timeline").end
		_check(born >= deadline and born <= deadline + 1.0 / 60.0 and not fx.dstate.wrecks.is_empty() and fx.dstate.wrecks[0].nodes.is_empty(),
			"a stuck worker past the deadline and the real-time wait uses the no-pieces fallback")
		gate.post()
	_check(born > nominal + 0.15 and fx._death_slow_left == FX.DEATH_SLOW_S, "slow motion starts on the real core birth")
	_check(not battle.cine_saved.is_empty(), "camera holds on the real core birth")
	await create_timer(1.0).timeout
	_check(battle.cine_saved.is_empty(), "camera returns after the actual core and its tail")
	battle.free()
	DEATH.cold_cut_wall = 5.0
	print("%s %s" % ["PASS" if before == failures else "FAIL", "late cut past the deadline keeps its pieces" if release_past_deadline else ("deadline fallback cue" if stall_through_deadline else "late core flash, slow motion and camera hold")])


func _run() -> void:
	var cr: Array = await _play("Cruiser", 0.76, true)
	_check(absf(float(cr[0]) - 1.66) < 0.02, "a cruiser's core flash is at 1.66 s (got %.2f)" % cr[0])
	_check(float(cr[1]) >= float(cr[0]) - 0.02 and float(cr[1]) <= float(cr[0]) + 0.05, "a cruiser kill's beat starts at the core flash (%.2f, flash %.2f)" % [cr[1], cr[0]])
	var cap: Array = await _play("Dreadnought", 1.18, true)
	_check(absf(float(cap[0]) - 2.28) < 0.02, "a capital's core flash is at 2.28 s (got %.2f)" % cap[0])
	_check(float(cap[1]) >= float(cap[0]) - 0.02 and float(cap[1]) <= float(cap[0]) + 0.05, "a capital kill's beat starts at the core flash (%.2f, flash %.2f)" % [cap[1], cap[0]])
	var small: Array = await _play("Frigate", 0.46, true)
	_check(float(small[0]) < 0.0 and float(small[1]) < 0.0, "a frigate kill has no core flash and no beat")
	var off: Array = await _play("Cruiser", 0.76, false)
	_check(float(off[1]) < 0.0, "with the beat off (reduce motion) a cruiser kill plays at full speed")
	var skipped: Array = await _play("Cruiser", 0.76, true, 1.0)
	_check(float(skipped[1]) < 0.0, "a key or a click before the core flash stops the queued beat")
	var mid: Array = await _play("Cruiser", 0.76, true, 1.8)
	_check(float(mid[1]) >= 0.0 and float(mid[2]) < float(mid[1]) + 0.1, "a key or a click during the beat ends it (%.2f to %.2f)" % [mid[1], mid[2]])
	await _late_cut(false)
	await _late_cut(false, true)
	await _late_cut(true)
	print("KILL_SLOWMO cruiser core %.2f beat %.2f-%.2f | capital core %.2f beat %.2f-%.2f | failures=%d" % [cr[0], cr[1], cr[2], cap[0], cap[1], cap[2], failures])
	quit(1 if failures > 0 else 0)
