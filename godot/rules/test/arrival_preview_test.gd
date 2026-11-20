# Issue 1289: battle_api.arrival_previews() names the hull a battle's reinforcement event brings, at the battle's start,
# without touching the battle: the dice and the view are the same after the call, and the ship that later arrives is
# the named hull and faction. Enemy and ally reinforcements, and a battle with no arrival.
#   godot --headless --path godot --script res://rules/test/arrival_preview_test.gd
extends SceneTree
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_call_argument", "return_value_discarded")
const Campaign := preload("res://campaign/campaign.gd")
const API := preload("res://rules/battle_api.gd")
const GUARD = preload("res://tools/ci/check_guard.gd")
var failures := 0


func _initialize() -> void:
	GUARD.arm(self, "arrival_preview_test")
	var c := Campaign.new()
	var error := c.load_tables()
	if error != "":
		_check(false, "campaign tables: " + error)
	else:
		for force in ["reinf_enemy", "reinf_ally", ""]:
			_case(c, force)
	print("ARRIVAL_PREVIEW ", "PASS" if failures == 0 else "FAIL %d" % failures)
	quit(0 if failures == 0 else 1)


func _check(ok: bool, why: String) -> void:
	if not ok:
		failures += 1
		push_error("ARRIVAL_PREVIEW " + why)


func _case(c: Campaign, force: String) -> void:
	API.JSM.rnd_seed(1289)
	c.META = c.defaultMeta()
	for id in c.ADMIRALS:
		if c.ADMIRALS[id]["fac"] == "voidsworn":
			c.newRun(id, "voidsworn")
			break
	var api := API.new()
	if api.load_rules() != "":
		_check(false, "rules did not load")
		return
	var cfg := {"kind": "battle", "fac": "hegemony", "seed": 1289, "enemies": [{"tpl": "h_picket"}]}
	if force != "":
		cfg["campaign"] = true
		cfg["event_force"] = force
	api.new_battle(c.RUN, cfg)
	var rng0: int = API.JSM.rng_s
	var view0 := JSON.stringify(api.view())
	var prev: Array = api.arrival_previews()
	_check(API.JSM.rng_s == rng0 and JSON.stringify(api.view()) == view0, "%s: arrival_previews changed the battle" % force)
	if force == "":
		_check(prev.is_empty(), "no event, yet a preview: %s" % [prev])
		return
	if prev.size() != 1:
		_check(false, "%s: expected one preview, got %s" % [force, prev])
		return
	var p: Dictionary = prev[0]
	var side := "enemy" if force == "reinf_enemy" else "player"
	_check(p["side"] == side, "%s: preview side %s" % [force, p["side"]])
	# play rounds until the event brings its ship
	var ids := {}
	for u in api.view()["units"]: ids[u["id"]] = true
	var arrived = null
	var guard := 0
	while arrived == null and api.phase != "over" and guard < 4000:
		guard += 1
		if api.phase == "player":
			var me = null
			for u in api.view()["units"]:
				if u["side"] == "player" and not u["dead"] and not u["activated"] and not u["squadron"]:
					me = u
					break
			if me == null: api.end_activation()
			else: api.end_activation(me["id"])
		else:
			api.step()
		api.take_events()
		for u in api.view()["units"]:
			if not ids.has(u["id"]) and not u["squadron"]:
				arrived = u
				break
	if arrived == null:
		_check(false, "%s: the reinforcement never arrived (phase %s)" % [force, api.phase])
		return
	_check(arrived["tpl"] == p["tpl"] and arrived["fac"] == p["fac"] and arrived["cls"] == p["cls"] and arrived["side"] == side,
		"%s: arrived %s %s %s, preview said %s %s %s" % [force, arrived["tpl"], arrived["fac"], arrived["cls"], p["tpl"], p["fac"], p["cls"]])
	_check(api.arrival_previews().is_empty(), "%s: a preview after the event fired" % force)
	print("ARRIVAL_PREVIEW %s: %s (%s %s) arrived as previewed" % [force, p["tpl"], p["fac"], p["cls"]])
