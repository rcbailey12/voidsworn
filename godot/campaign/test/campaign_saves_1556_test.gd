# Issue 1556 (campaign and saves audit, Nov 21): shipyard and refit changes survive a window close, a hull refit taken off and
# on again never adds hull, and Continue inside a shipyard or an event shows the same stock or event. Real save files, cold
# restarts (a window close is a new launch from the file: nothing in memory survives).
#   godot --headless --path godot --script res://campaign/test/campaign_saves_1556_test.gd
# The browser twin's state half: contrib/opus/tools/campaign_saves_1556_tests.js. Every case fails on main d16c734b except the full-ship guard.
extends SceneTree
@warning_ignore_start("untyped_declaration", "unsafe_method_access", "unsafe_call_argument", "inference_on_variant", "unsafe_property_access")
const API = preload("res://rules/battle_api.gd")
const Campaign = preload("res://campaign/campaign.gd")
const DIR := "user://campaign_saves_1556_test"
var fails := 0

func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok: fails += 1

func _fresh(path: String) -> Variant:
	var C = Campaign.new(); C.load_tables(); C.fixed_clock = true; C.persist_on = true; C.save_path = path
	return C

func _cold(path: String) -> Variant:   # the window closed: a new launch from the file, then the title's Continue
	var D = _fresh(path); D.persist_load(); D.titleScreen(); D.act("continueRun")
	return D

func _rmdir(p: String) -> void:
	var g := ProjectSettings.globalize_path(p)
	if DirAccess.dir_exists_absolute(g):
		for f in DirAccess.get_files_at(g): DirAccess.remove_absolute(g.path_join(f))
		DirAccess.remove_absolute(g)

# A run saved on the map with a `want` stop one lane ahead; returns [campaign, target node id].
func _map_save(path: String, seed: int, want: String) -> Array:
	var C = _fresh(path)
	API.JSM.rnd_seed(seed); C.META = C.defaultMeta()
	var adm = null
	for id in C.ADMIRALS.keys():
		if C.ADMIRALS[id].get("fac") == "voidsworn" and adm == null: adm = id
	C.newRun(adm, "voidsworn", {})
	C.RUN["sector"] = 2; C.RUN["map"] = C.genSector(2); C.RUN["pos"] = null; C.RUN["credits"] = 5000
	for i in 2: C.RUN["fleet"].append(C.newShip(C.cheapHull("voidsworn")))
	if C.RUN.get("aspect") == null: C.RUN["aspect"] = C.ASPECTS.keys()[0]
	var target := ""
	for col in C.RUN["map"]["cols"]:
		for n in col:
			if target != "": break
			C.RUN["pos"] = n["id"]
			for id in C.availableNodes():
				var m = C.findNode(id)
				if target == "" and m != null and m["type"] == want and not C.nemNodeIs(m): target = id
			if target != "": n["done"] = true
	C.RUN["curNode"] = null
	C.mapScreen(); C.saveRun()
	return [C, target]

func _acts(C, kind: String) -> Array:
	return C.screen_acts().filter(func(x): return x[0] == kind and int(x[2]) == 1)

func _norm(v) -> String:   # numbers as the save writes them (a whole number reloads as a float)
	return str(JSON.parse_string(JSON.stringify(v)))

func _fleet_sig(C) -> String:
	return _norm(C.RUN["fleet"].map(func(s): return [s["uid"], s["tpl"], s["hp"], s["mk"], s["mods"]])) + " cr " + _norm(C.RUN["credits"]) + " hold " + _norm(C.RUN["inventory"])

func _case_yard() -> void:
	var path := DIR.path_join("yard.json")
	var r := _map_save(path, 1556, "shipyard"); var C = r[0]; var target: String = r[1]
	if target == "":
		_check(false, "yard: no shipyard one lane ahead"); return
	C.act("enterNode", target)
	_check(C.page.get("kind") == "shipyard", "yard: entered the shipyard")
	var st0 = C.findNode(target)["stock"]; var stock := _norm([st0["hulls"], st0["mods"], st0.get("cap")])
	var hull = _acts(C, "buyHull"); var mod = _acts(C, "buyMod")
	if hull.is_empty() or mod.is_empty():
		_check(false, "yard: a hull and a refit are for sale (%d, %d)" % [hull.size(), mod.size()]); return
	C.act("buyHull", hull[0][1]); C.act("buyMod", mod[0][1])
	var s = C.RUN["fleet"][0]; s["hp"] = float(s["hp"]) - 10; C.act("repair", s["uid"])
	C.act("upgradeMk", C.RUN["fleet"][1]["uid"])
	C.act("sellConfirm", C.RUN["fleet"][2]["uid"])
	C.act("yardFleet")
	var eq = _acts(C, "equip")
	if not eq.is_empty(): C.act("equip", eq[0][1])
	var want := _fleet_sig(C)
	var D = _cold(path)   # the window closes inside the yard (no Leave)
	_check(_fleet_sig(D) == want, "(1) a buy, sale, repair, Mk refit and fitted refit survive a window close and Continue\n      want %s\n      got  %s" % [want, _fleet_sig(D)])
	_check(D.page.get("kind") == "shipyard" and str(D.RUN.get("curNode")) == target, "(1) Continue reopens the shipyard (page %s)" % str(D.page.get("kind")))
	var st1 = D.findNode(target)["stock"]
	_check(_norm([st1["hulls"], st1["mods"], st1.get("cap")]) == stock, "(3) Continue inside a shipyard shows the same stock")
	D.act("leaveYard")
	var E = _cold(path)
	_check(E.page.get("kind") == "map" and E.findNode(target)["done"] == true and _fleet_sig(E) == want, "(1) after Leave, Continue opens the map with the yard done and the fleet kept")

func _case_map_refit() -> void:
	var path := DIR.path_join("refit.json")
	var r := _map_save(path, 1557, "shipyard"); var C = r[0]
	C.RUN["inventory"].append("prow")
	C.act("fleetScreen")
	var eq = _acts(C, "equip")
	if eq.is_empty():
		_check(false, "refit: the prow refit fits a ship"); return
	C.act("equip", eq[0][1])
	var want := _fleet_sig(C)
	var D = _cold(path)
	_check(_fleet_sig(D) == want, "(1) a refit fitted on the map's fleet screen survives a window close")

func _case_hull() -> void:
	var path := DIR.path_join("hull.json")
	var r := _map_save(path, 1558, "shipyard"); var C = r[0]
	var s = C.RUN["fleet"][0]
	s["mods"] = []; C.RUN["inventory"] = ["prow"]
	C.act("fleetScreen"); C.act("equip", "0:" + str(s["uid"]))
	s["hp"] = 10.0
	var i := (s["mods"] as Array).find("prow")
	C.act("unequip", str(s["uid"]) + ":" + str(i))
	var mid = s["hp"]
	C.act("equip", "0:" + str(s["uid"]))
	_check(float(s["hp"]) <= 10.0 and (s["mods"] as Array).has("prow"), "(2) Reinforced prow off and on again at 10 hull never adds hull (10 to %s to %s)" % [str(mid), str(s["hp"])])
	var full = C.derive(s)["maxHp"]; s["hp"] = full
	C.act("unequip", str(s["uid"]) + ":" + str((s["mods"] as Array).find("prow"))); C.act("equip", "0:" + str(s["uid"]))
	_check(float(s["hp"]) == float(full), "(2) a full ship still comes back full (%s of %s)" % [str(s["hp"]), str(full)])

func _case_event() -> void:
	var path := DIR.path_join("event.json")
	var r := _map_save(path, 1559, "event"); var C = r[0]; var target: String = r[1]
	if target == "":
		_check(false, "event: no event one lane ahead"); return
	C.act("enterNode", target)
	var ev = C.cur_event["id"] if C.cur_event is Dictionary else null
	var seen := str(C.RUN["seenEvents"])
	var D = _cold(path)
	var ev2 = D.cur_event["id"] if D.cur_event is Dictionary else null
	_check(ev != null and ev2 == ev and str(D.RUN["seenEvents"]) == seen, "(3) Continue inside an event shows the same event (%s, then %s)" % [str(ev), str(ev2)])
	var F = _cold(path)
	var ev3 = F.cur_event["id"] if F.cur_event is Dictionary else null
	_check(ev3 == ev, "(3) and again on a second reload (%s)" % str(ev3))

func _case_guards() -> void:
	var path := DIR.path_join("guards.json")
	var r := _map_save(path, 1560, "shipyard"); var C = r[0]; var target: String = r[1]
	if target == "": return
	C.act("enterNode", target)
	var before := _fleet_sig(C)
	C.ACT_buyMod("999"); C.ACT_buyMod("-1"); C.ACT_unequip("nope"); C.ACT_repair("no-such-ship"); C.ACT_upgradeMk("no-such-ship")
	C.ACT_buyHull("not_a_hull")
	var other := ""
	for h in C.HULLS.keys():
		if not C.findNode(target)["stock"]["hulls"].has(h) and float(C.HULLS[h].get("cost", 0)) > 0: other = h; break
	if other != "": C.ACT_buyHull(other)
	_check(_fleet_sig(C) == before, "(4) bad shop arguments and a hull this yard does not sell change nothing")

func _init() -> void:
	_rmdir(DIR); DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_case_yard(); _case_map_refit(); _case_hull(); _case_event(); _case_guards()
	_rmdir(DIR)
	print("Issue 1556 campaign save tests: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails > 0 else 0)
