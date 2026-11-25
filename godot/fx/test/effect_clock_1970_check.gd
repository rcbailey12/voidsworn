extends SceneTree

const GUARD := preload("res://tools/ci/check_guard.gd")
const DEATH := preload("res://fx/fx_death.gd")
const STEP := 1.0 / 60.0
const TRAUMA := 0.8


class Playback extends "res://scenes/battle/battle.gd":
	var volley_log_at := -1.0

	func _ready() -> void:
		set_process(false)

	func _log(message: String, _kind: String) -> void:
		if " fires " in message:
			volley_log_at = float(gfx.now)


class Effects extends "res://fx/fx.gd":
	var booked_end := 0.0

	func volley(attacker_id: String, kind: String, target_id: String, opts := {}) -> Dictionary:
		var result := super.volley(attacker_id, kind, target_id, opts)
		booked_end = now + float(result.done)
		return result


class Sound extends Node:
	func gun(_kind: String, _wing: bool, _style, _pos: Vector3, _delay: float, _fac: String, _weapon: String) -> void:
		pass

	func play(_cue: String, _opts: Dictionary) -> void:
		pass


var failures := 0


func _init() -> void:
	GUARD.arm(self, "effect_clock_1970_check", 30.0)
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)


func _ship(fx: Effects, id: String, at: Vector3) -> void:
	var ship := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(12, 3, 4)
	box.subdivide_width = 11
	box.subdivide_height = 2
	box.subdivide_depth = 3
	ship.mesh = box
	ship.position = at
	fx.get_parent().add_child(ship)
	fx.add_ship(id, ship, {"faction": "voidsworn", "cls": "Dreadnought", "size": 1.18, "meshes": [ship]})


func _check_shake(fx: Effects, started: float, label: String) -> void:
	var t: float = fx.now
	var trauma := TRAUMA - (t - started) * 2.4
	var amp := 0.06 * trauma * trauma
	var offs := Vector2(sin(t * 37.0) * 0.6 + sin(t * 61.0 + 1.0) * 0.4,
		sin(t * 43.0 + 2.0) * 0.6 + sin(t * 71.0) * 0.4) * amp * 10.0
	var actual := Vector2(fx.camera.h_offset, fx.camera.v_offset)
	_check(actual.is_equal_approx(offs), "%s: camera shake phase and decay track FX seconds" % label)


func _run() -> void:
	var battle := Playback.new()
	root.add_child(battle)
	battle.cine = "off"
	battle.board = battle.Board.new()
	battle.add_child(battle.board)
	battle.board.props = Node3D.new()
	battle.board.add_child(battle.board.props)
	battle.board.cells = [{"q": 0, "r": 0}]
	battle.board.index["0,0"] = 0
	var fx := Effects.new()
	battle.gfx = fx
	battle.add_child(fx)
	# Test the live shake route, advancing the frames ourselves.
	fx.set_process(false)
	var camera := Camera3D.new()
	battle.add_child(camera)
	fx.setup({"camera": camera, "quality": "low"})
	battle.sfx = Sound.new()
	battle.add_child(battle.sfx)
	_ship(fx, "gun", Vector3.ZERO)
	_ship(fx, "late", Vector3(36, 0, 12))

	# Hold a real capital cut result behind a worker gate, as in kill_slowmo_check.
	var ship = fx.ship("late")
	DEATH.precompute(fx, ship)
	while not DEATH.finish_precompute(fx, ship):
		await process_frame
	var gate := Semaphore.new()
	var cut: int = fx.submit_death_cut(func() -> void:
		var deadline := Time.get_ticks_msec() + 15000
		while Time.get_ticks_msec() < deadline and not gate.try_wait():
			OS.delay_msec(10))
	ship.set_meta("cut_task", cut)
	var cold_cap := DEATH.cold_cut_wall
	DEATH.cold_cut_wall = 30.0
	battle.VU["gun"] = {"name": "Gun", "fac": "voidsworn", "side": "player"}
	battle.VU["late"] = {"name": "Late", "fac": "voidsworn", "side": "enemy"}
	battle._play_fire({"unit": "gun", "target": "late", "kind": "battery", "weapon_id": "battery",
		"weapon": null, "shots": [false, false, false], "quad": 0, "name": "Macro battery"}, [])
	_check(fx.booked_end > fx.now + 0.2, "the volley booked a real shot sequence")

	fx.kill_slowmo = true
	fx.death("late")
	battle.wrecked["late"] = Vector2i.ZERO
	battle._lay_wreck("late")
	_check(battle.board.wrecks.has("late"), "the blocking hex is marked while the cut is still pending")
	var check_at: float = fx.now + battle.WRECK_CHECK_S
	var started: float = fx.now
	fx.hit_pause(started, 3)
	fx.shake(started, TRAUMA, camera.global_position)
	fx.step(0.0)
	fx.step(STEP)
	_check(is_equal_approx(fx.dt, STEP * 0.08), "hit pause uses the 0.08x clock")
	_check_shake(fx, started, "hit pause")
	fx.death_slowmo()
	for i in 9:
		fx.step(STEP)
	_check(fx.dt > STEP * 0.3 and fx.dt < STEP * 0.4, "the kill beat slows the clock after hit pause")
	_check_shake(fx, started, "kill slow-mo")

	await create_timer(maxf(battle.WRECK_CHECK_S, fx.booked_end - started) + 0.1).timeout
	_check(battle.volley_log_at < 0.0, "the volley stays open past its old wall-clock wait")
	_check(not battle.board.wreck_hulls.has("late"), "the old wall-clock deadline cannot lay a second hulk")
	while fx.now < fx.booked_end:
		fx.step(STEP)
		await process_frame
	_check(battle.volley_log_at >= fx.booked_end and battle.volley_log_at <= fx.booked_end + STEP,
		"the volley ends on its booked effect frame")
	while fx.now < check_at + 0.1:
		fx.step(STEP)
		await process_frame
	_check(not fx.wreck_settled("late") and not battle.board.wreck_hulls.has("late"),
		"the wreck check also waits beyond its effect deadline while the cut is pending")

	# Force the real no-pieces pop and verify that the board adds its fallback on that effect frame.
	DEATH.cold_cut_wall = 0.0
	for i in 10:
		fx.step(STEP)
		await process_frame
		if battle.board.wreck_hulls.has("late"):
			break
	_check(fx.wreck_settled("late") and fx.wreck_pieces("late") == 0 and battle.board.wreck_hulls.has("late"),
		"the fallback hulk appears after the no-pieces pop")
	gate.post()
	DEATH.cold_cut_wall = cold_cap
	battle.free()
	print("EFFECT_CLOCK_1970 failures=%d" % failures)
	quit(1 if failures else 0)
