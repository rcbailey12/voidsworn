extends SceneTree
# Issue 1336: the campaign host rolls each enemy fleet at the player's AI setting. It used to build the battle at the API's
# default (Veteran) and set the level only later in the battle scene, so Standard players met Veteran-sized fleets. The map's
# danger bands follow the same setting, and Veteran's bands carry RAMP.vet as battle.js genEnemyFleet does.
# Read-only: no save is written (persist_on off), battles are built in memory.

const Host := preload("res://main/campaign_host.gd")
const Campaign := preload("res://campaign/campaign.gd")
const API := preload("res://rules/battle_api.gd")
const JSM := preload("res://rules/jsm.gd")
const Intel := preload("res://ui/campaign/map_intel.gd")

class FakeMain:
	extends Node
	var settings := {"ai": "standard"}

var failures := 0


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok   ", what)
	else:
		failures += 1
		print("  FAIL ", what)


func _enemy(api) -> Array:
	var out := []
	for u in api.R.B["units"]:
		if u["side"] == "enemy" and not api.R.jt(u.get("isSq")): out.append(str(u["tpl"]))
	return out


# Plays from the title to the first battle with the host's battle setup, as the game does. Returns [host, campaign, cfg].
func _first_battle(level: String, seed: int) -> Array:
	var m := FakeMain.new(); m.settings["ai"] = level
	var h = Host.new(); h.main = m
	var C = Campaign.new(); C.load_tables(); C.persist_on = false; C.fixed_clock = true; C.META = C.defaultMeta()
	C.battle_mode = "external"; C.battle_setup = h._setup_battle
	var asked := [false]
	C.battle_requested.connect(func(): asked[0] = true)
	JSM.rnd_seed(seed)
	C.titleScreen(); C.act("newRunScreen")
	var clicks := 0
	while not asked[0] and clicks < 200:
		clicks += 1
		var on = C.screen_acts().filter(func(x): return x[2] == 1)
		var pick = null
		for pref in ["startRun", "pickAspect", "closeModal", "enterNode"]:
			for x in on:
				if x[0] == pref and pick == null: pick = x
		if pick == null and on.size() > 0: pick = on[0]
		if pick == null: break
		C.act(pick[0], pick[1])
	return [h, C, C.pending_battle if asked[0] else null, m]


func _initialize() -> void:
	var tried := 0
	for level in ["standard", "veteran"]:
		for seed in [11, 12, 13, 14]:
			var r := _first_battle(level, seed)
			var h = r[0]; var C = r[1]; var cfg = r[2]
			if cfg == null or h.api_now == null:
				_check(false, "%s seed %d reached its first battle" % [level, seed]); continue
			tried += 1
			_check(str(h.api_now.R.AI_LEVEL) == level, "%s seed %d: the fleet was rolled at %s (got %s)" % [level, seed, level, str(h.api_now.R.AI_LEVEL)])
			var ref = API.new(); ref.load_rules(); ref.R.AI_LEVEL = level
			ref.new_battle(C.RUN, cfg)
			_check(_enemy(h.api_now) == _enemy(ref), "%s seed %d: the fleet matches one built at %s from the start: %s" % [level, seed, level, ", ".join(_enemy(h.api_now))])
			r[3].free(); h.free()
	_check(tried == 8, "all 8 first battles were reached")
	# the screens and the map's danger bands get the same level
	var m := FakeMain.new(); var h = Host.new(); h.main = m
	_check(h.ai_level() == "standard", "the host reads Standard from the settings")
	m.settings["ai"] = "veteran"
	_check(h.ai_level() == "veteran", "the host reads Veteran from the settings")
	var hn = Host.new()
	_check(hn.ai_level() == "veteran", "no main (a bare host) falls back to Veteran, the API default")
	m.free(); h.free(); hn.free()
	var r2 := _first_battle("standard", 11)
	var C2 = r2[1]
	var node = null
	for col in C2.RUN["map"]["cols"]:
		for n in col:
			if n["type"] == "battle" and not C2.jt(n.get("done")) and node == null: node = n
	if node == null:
		_check(false, "a battle node for the danger check")
	else:
		var std = Intel.new(C2); std.ai_level = "standard"
		var vet = Intel.new(C2); vet.ai_level = "veteran"
		var ds = std.danger(node); var dv = vet.danger(node)
		var vet_f := float(C2.TB["RAMP"]["vet"]); var std_f := float(C2.TB["RAMP"]["std"])
		_check(not ds.is_empty() and not dv.is_empty(), "danger reads for both levels")
		if not ds.is_empty() and not dv.is_empty():
			_check(absf(float(dv["threat"]) / float(ds["threat"]) - vet_f / std_f) < 0.001, "Veteran's threat is RAMP.vet / RAMP.std (%.3f) times Standard's" % (vet_f / std_f))
			_check(dv["why"].any(func(w): return w[0] == "Veteran AI"), "the hover card names the Veteran AI factor")
	r2[3].free(); r2[0].free()
	print("ai_level_fleet_check: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
