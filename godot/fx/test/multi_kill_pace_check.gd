extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1238 (Board review of PR 1243): three Chorus Bio-Titans killed in one volley. Each now reports its class's full
# death (2.67 s) to the turn flow, like a steel capital. The battle's death waits must overlap, not stack: every kill but
# the batch's last waits only its 0.8 s floor, so the next death starts while the last one plays. Measures the real
# seconds the turn flow spends on the three deaths through battle.gd _play_death. Headless.
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

class Stepper extends Node:
	var fx
	func _process(_d: float) -> void:
		fx.step(1.0 / 60.0)

class TestDeathAudio extends Node:
	var fx
	var deaths: Array = []
	func watch(_id: String, _pos: Vector3) -> void:
		pass


func _init() -> void:
	GUARD.arm(self, "multi_kill_pace_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	var battle := BattleFixture.new()
	root.add_child(battle)
	battle.cam = battle.CamRig.new()
	battle.add_child(battle.cam)
	battle.hud = TestHud.new()
	battle.add_child(battle.hud)
	battle.death_audio = TestDeathAudio.new()
	battle.add_child(battle.death_audio)
	battle.speed = 1.0
	battle.cine = "off"   # the kill cut-in's own hold is unchanged here; this measures the turn flow's death waits
	var fx := FX.new()
	battle.gfx = fx
	battle.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low"})
	var stepper := Stepper.new()
	stepper.fx = fx
	battle.add_child(stepper)
	var ids := ["t0", "t1", "t2"]
	var reported := 0.0
	for i in ids.size():
		var id: String = ids[i]
		var sv := SV.new()
		battle.add_child(sv)
		sv.set_process(false)
		sv.ring = MeshInstance3D.new()
		sv.add_child(sv.ring)
		sv.L = 40.0
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(24, 4, 6)
		mi.mesh = bm
		sv.add_child(mi)
		sv.position = Vector3(i * 40.0, 0, 0)
		fx.add_ship(id, sv, {"faction": "chorus", "cls": "Bio-titan", "size": 1.25, "meshes": [mi]})
		battle.views[id] = sv
		battle.VU[id] = {"name": "Titan %d" % i, "side": "enemy", "size": 1.25}
	# what _play_batch counts for a batch with three death events
	battle._deaths_left = ids.size()
	var t0 := Time.get_ticks_msec()
	for id in ids:
		# A settled kill may retire its FX ship inside _play_death (issue 2198), so read the timeline from the same node.
		var ship = fx.ship(id)
		await battle._play_death({"unit": id})
		reported = maxf(reported, float(ship.get_meta("death_timeline").end))
	var spent := (Time.get_ticks_msec() - t0) / 1000.0
	var full := reported * 0.6
	var stacked := full * ids.size()
	var overlapped := 0.8 * (ids.size() - 1) + full
	print("MULTI_KILL three Chorus Bio-Titans: each reports %.2f s; turn flow spent %.2f s (stacked would be %.2f s, overlapped %.2f s)" % [reported, spent, stacked, overlapped])
	_check(absf(reported - 2.67) < 0.02, "a Chorus Bio-Titan reports its capital death (2.67 s)")
	_check(spent < stacked - 1.0, "three kills in one volley overlap instead of stacking")
	_check(spent >= overlapped - 0.4 and spent <= overlapped + 0.3, "the last kill keeps its whole hold")
	_check(battle._deaths_left == 0, "the batch's death count runs down to zero")
	fx.release()
	battle.queue_free()
	await process_frame
	print("MULTI_KILL failures=%d" % failures)
	quit(0 if failures == 0 else 1)
