# Issue 1333 audit, finding F2: a Standard player's campaign fleets are rolled on the Veteran budget.
#   godot --headless --path godot --script res://../contrib/opus/reviews/codebase_audit_1120/repro_ai_level_fleet.gd
# (or pass the absolute path of this file to --script). Read-only: builds battles in memory, writes nothing.
# It runs the real campaign_host.gd _setup_battle (external battle mode) for a player whose setting is Standard, then builds the same
# battle with the level set first, as battle.js does when it reads the live AI_LEVEL during genEnemyFleet. Exit 1 when the two fleets differ (the bug).
extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const API = preload("res://rules/battle_api.gd")
const Host = preload("res://main/campaign_host.gd")

class FakeMain:
	extends Node
	var settings := {"ai": "standard"}   # main.gd default
const JSM = preload("res://rules/jsm.gd")

var C
var host = null
var asked := false

func _host_setup(run: Dictionary, cfg: Dictionary) -> Dictionary:   # the real campaign_host.gd _setup_battle, with a Standard player
	return host._setup_battle(run, cfg)

func _enemy(api) -> Array:
	var out := []
	for u in api.R.B["units"]:
		if u["side"] == "enemy" and not api.R.jt(u.get("isSq")): out.append(str(u["tpl"]))
	return out

func _cp(api, list: Array) -> float:
	var t := 0.0
	for tpl in list: t += float(api.R.HULLS[tpl].get("cp", 1))
	return t

func _init() -> void:
	var bad := 0; var tried := 0
	for seed in [11, 12, 13, 14, 15, 16, 17, 18]:
		host = Host.new(); host.main = FakeMain.new()
		C = Campaign.new(); C.load_tables(); C.persist_on = false; C.fixed_clock = true; C.META = C.defaultMeta()
		C.battle_mode = "external"; C.battle_setup = _host_setup; asked = false
		C.battle_requested.connect(func(): asked = true)
		JSM.rnd_seed(seed)
		C.titleScreen(); C.act("newRunScreen")
		var clicks := 0
		while not asked and clicks < 200:
			clicks += 1
			var on = C.screen_acts().filter(func(x): return x[2] == 1)
			var pick = null
			for pref in ["startRun", "pickAspect", "closeModal", "enterNode"]:
				for x in on:
					if x[0] == pref and pick == null: pick = x
			if pick == null and on.size() > 0: pick = on[0]
			if pick == null: break
			C.act(pick[0], pick[1])
		if not asked: continue
		tried += 1
		var cfg: Dictionary = C.pending_battle
		var host_level: String = host.api_now.R.AI_LEVEL
		var host_fleet := _enemy(host.api_now)
		var std = API.new(); std.load_rules(); std.R.AI_LEVEL = "standard"   # the player's Standard setting, applied before the roll
		std.new_battle(C.RUN, cfg)
		var std_fleet := _enemy(std)
		print("seed %d: host path rolls at AI_LEVEL=%s: %s (%.0f CP) | Standard set first: %s (%.0f CP)" % [seed, host_level, ", ".join(host_fleet), _cp(host.api_now, host_fleet), ", ".join(std_fleet), _cp(std, std_fleet)])
		if host_level != "standard": bad += 1
	print("RESULT: %d of %d first battles were rolled at the Veteran level although the player chose Standard (main.gd default 'ai': 'standard')" % [bad, tried])
	if tried != 8: print("RESULT: only %d of 8 seeds reached a battle, so nothing was proved" % tried)
	quit(1 if bad > 0 or tried != 8 else 0)
