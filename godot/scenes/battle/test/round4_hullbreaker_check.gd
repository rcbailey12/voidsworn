extends SceneTree
# Issue 1982: keep round 4 of the Hullbreaker replay off the frame thread.

const GUARD := preload("res://tools/ci/check_guard.gd")


class Replay extends "res://scenes/battle/battle.gd":
	var round4_steps := 0
	var round4_worker_steps := 0
	var round4_sync_commands := 0
	var evasive := false
	var salvos := {}

	func _args() -> void:
		# Issue 2033: Veteran called shots changed seed 7. Seed 16 still plays an evasive action and a screened salvo in round 4.
		args = {"bot": true, "fac": "corsair", "obj": "ambush", "map": "open",
			"seed": 16, "movement": "brisk", "no-tips": true, "noworld": true}

	func _bot_step() -> void:
		var round4 := int(V.get("round", 0)) == 4
		super._bot_step()
		if round4:
			round4_steps += 1
			if thinking and _think_tid >= 0:
				round4_worker_steps += 1

	func _cmd(action: Callable) -> bool:
		if int(V.get("round", 0)) == 4:
			round4_sync_commands += 1
		return super._cmd(action)

	func _play_fire(e: Dictionary, group: Array) -> void:
		if int(V.get("round", 0)) == 4 and e["kind"] == "torp":
			salvos[e["unit"]] = [e["target"], e["shots"].size(), int(e.get("pd", 0))]
		await super._play_fire(e, group)

	func _play_event(e: Dictionary, batch_view := {}) -> void:
		if int(V.get("round", 0)) == 4 and e["t"] == "ability" and e.get("unit") == "x06" and e.get("ab") == "evasive":
			evasive = true
		await super._play_event(e, batch_view)


func _init() -> void:
	GUARD.arm(self, "round4_hullbreaker_check", 90.0)
	_run.call_deferred()


func _run() -> void:
	Engine.time_scale = 6.0
	var battle := Replay.new()
	root.add_child(battle)
	while int(battle.V.get("round", 0)) < 5 and battle.errors.is_empty() and not battle.ended:
		await process_frame
	var expected := {"x011": ["x04", 3, 0], "x05": ["x08", 1, 0], "x08": ["x06", 3, 2]}
	var on_worker := battle.round4_steps > 0 and battle.round4_steps == battle.round4_worker_steps and battle.round4_sync_commands == 0
	var reached_round5 := battle.errors.is_empty() and int(battle.V.get("round", 0)) >= 5
	var ok := on_worker and reached_round5 and battle.salvos == expected and battle.evasive
	print("%s: round 4 salvos=%s evasive=%s worker actions=%d/%d synchronous commands=%d errors=%s" %
		["PASS" if ok else "FAIL", battle.salvos, battle.evasive, battle.round4_worker_steps,
		battle.round4_steps, battle.round4_sync_commands, battle.errors])
	battle._quit(0 if ok else 1)
