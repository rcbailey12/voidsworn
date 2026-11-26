extends SceneTree
# Issue 2171: the two lineage shots must use live guns and cannot bend a bow gun astern.
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "return_value_discarded")
const API := preload("res://rules/battle_api.gd")
var failures := 0


func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok: failures += 1


func battle(name: String):
	var a := API.new()
	assert(a.load_rules() == "")
	a.new_battle_scenario(name)
	return a.R


func _init() -> void:
	for off in [2, 999]:
		var r = battle("t_throatspits")
		var u = r.alive("player")[0]
		var t = r.alive("enemy")[0]
		u["q"] = 0; u["r"] = 0; u["facing"] = 0
		t["q"] = 1; t["r"] = 0
		var gun = u["weapons"].filter(func(w): return w["k"] != "flak")[0]
		u["weapons"] = [gun]
		gun["off"] = off
		check(not r.treeSpit(u) and gun["off"] == off,
			"Throat Spits cannot use a gun with off=%d" % off)
		gun["off"] = 0
		gun["arc"] = "F"
		t["q"] = -1
		check(not r.treeSpit(u) and u["facing"] == 0, "Throat Spits cannot point the bow gun astern")
		gun["arc"] = "T"
		check(r.treeSpit(u) and u["facing"] == 0, "Throat Spits can use a live turret that bears astern")

	var r = battle("t_heg_secondvolley")
	var u = r.alive("player")[0]
	var t = r.alive("enemy")[0]
	u["q"] = 0; u["r"] = 0; u["facing"] = 0
	u["anchor"] = true
	t["q"] = -1; t["r"] = 0
	r.B["tr"]["syncFirst"]["player"] = {"id": t["id"], "r": r.B["round"]}
	var gun = u["weapons"].filter(func(w): return w["arc"] == "F" and w["k"] != "flak")[0]
	check(r.inSync(u) and r.treeHas("secondVolley"), "Second Volley fixture is synced and has the skill")
	check(not r.treeSecondVolleyOK(u, gun, t) and not r.treeExtraShot(u, u["weapons"].find(gun), t, {"forceArc": true}),
		"both manual and forced Second Volley reject a bow shot astern")
	t["q"] = 1; t["r"] = -2
	check(not r.inArc(u, t, gun["arc"]) and r.treeSecondVolleyOK(u, gun, t),
		"Second Volley still reaches past the normal bow arc on a forward bearing")
	gun["off"] = 2
	check(not r.treeSecondVolleyOK(u, gun, t), "manual Second Volley respects a weapon knockout")
	quit(0 if failures == 0 else 1)
