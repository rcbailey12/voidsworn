# Issue 1480 (R381, R384; RULEBOOK 11.8 and 11.11), Godot twin of contrib/opus/tools/retreat_nemesis_1480_tests.js (both read
# fixtures/issue_1480/retreat_nemesis.json): a retreat sends the fleet back to the stop it came from with the fight kept, a
# retreat is not the Nemesis meeting, a Nemesis-held service stop survives a retreat, and the revived Eclipse rival's last
# fight is the Sector 3 boss battle. Godot only: the "nemesis_slain" medal waits for the kill that ends him (item 2), and
# entering the boss stop with him revived starts a boss battle that carries his Nemesis settings (item 1).
# Prints PASS or FAIL lines; exit 0 when all pass.
#   godot --headless --path godot --script res://campaign/test/retreat_nemesis_1480.gd
extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const Career = preload("res://story/career.gd")
const JSM = preload("res://rules/battle_api.gd").JSM

var c = Campaign.new()
var fails := 0


func _initialize() -> void: _run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok: fails += 1


func _fresh(fx: Dictionary) -> Array:
	JSM.rnd_seed(int(fx["seed"]))
	c.META["admirals"][fx["admiral"]] = true
	c.newRun(fx["admiral"], fx["fac"])
	var all: Array = []
	for col in c.RUN["map"]["cols"]:
		for n in col: all.append(n)
	for i in all.size(): all[i]["seed"] = 1000 + i
	return all


func _edge_from(id) -> Variant:
	for e in c.RUN["map"]["edges"]:
		if e[0] == id: return e
	return null


func _edge_to(id) -> Variant:
	for e in c.RUN["map"]["edges"]:
		if e[1] == id: return e
	return null


func _walk(col: int) -> Array:
	var cols: Array = c.RUN["map"]["cols"]
	var prev = null
	var cur = cols[0][0]
	for k in range(1, col + 1):
		prev = cur
		cur = c.findNode(_edge_from(prev["id"])[1])
	var p = cols[0][0]
	while p != null and not is_same(p, cur):
		p["done"] = true
		var e = _edge_from(p["id"])
		p = c.findNode(e[1]) if e != null else null
	return [prev, cur]


func _leave(n: Dictionary) -> bool:
	c.RUN["pos"] = n["id"]; c.RUN["curNode"] = n["id"]
	if not c.has_method("retreatBack"): return false
	c.retreatBack()
	return true


func _run() -> void:
	var err: String = c.load_tables()
	if err != "":
		_check(false, err); quit(1); return
	c.fixed_clock = true
	c.persist_on = false
	var fx = JSON.parse_string(FileAccess.get_file_as_string("res://campaign/test/fixtures/issue_1480/retreat_nemesis.json"))
	if fx == null:
		_check(false, "the 1480 fixture reads"); quit(1); return
	for cs in fx["cases"]:
		_fresh(fx)
		var name: String = cs["name"]
		var ex: Dictionary = cs["expect"]
		var c4: int = c.RUN["map"]["cols"].size() - 3
		match str(cs["kind"]):
			"retreat":
				var pc := _walk(int(cs["col"]))
				var prev = pc[0]
				var cur = pc[1]
				var seed = cur["seed"]
				var ok := _leave(cur)
				var want = prev["id"] if ex["pos"] == "from" else null
				_check(ok and c.RUN["pos"] == want and c.RUN["curNode"] == null, name + ": back on the stop it came from")
				_check(ok and c.jt(cur.get("done")) == bool(ex["done"]) and cur["seed"] == seed and c.availableNodes().has(cur["id"]) == bool(ex["avail"]), name + ": the fight stays on the map, same seed, and can be taken again")
			"nem_retreat":
				var N = c.ensureNemesis(); N["met"] = 0; c.RUN["nemClock"] = 2; c.RUN["nemStrike"] = true
				var out: Array = c.nemAfterBattle("retreat", false, {})
				var n = null
				for x in c.RUN["map"]["cols"][c4]:
					if x["type"] == "battle" or x["type"] == "elite": n = x; break
				if n == null: n = c.RUN["map"]["cols"][c4][0]
				_check(float(N["met"]) == float(ex["met"]) and float(c.RUN["nemClock"]) == float(ex["nemClock"]) and c.jt(c.RUN.get("nemStrike")) == bool(ex["nemStrike"]) and N.get("gloat") == ex["gloat"] and out.size() == 1, name + ": no meeting recorded, the clock and strike stand")
				_check(c.nemNodeIs(n) == bool(ex["stillHis"]), name + ": his stops are still his")
			"nem_stop_retreat":
				var N = c.ensureNemesis(); N["met"] = 0
				var stop = null
				for x in c.RUN["map"]["cols"][c4]:
					if x["type"] != "battle" and x["type"] != "elite": stop = x; break
				if stop == null: stop = c.RUN["map"]["cols"][c4][0]
				var prev = c.findNode(_edge_to(stop["id"])[0]); prev["done"] = true
				var ok := _leave(stop)
				if ok: c.nemAfterBattle("retreat", false, {})
				_check(ok and c.jt(stop.get("done")) == bool(ex["done"]) and c.nemNodeIs(stop) == bool(ex["stillHis"]), name + ": the stop is not used up and is still his")
				_check(ok and c.RUN["pos"] == prev["id"] and c.availableNodes().has(stop["id"]) == bool(ex["avail"]), name + ": it can be taken again from where the fleet stands")
			"eclipse_boss":
				c.RUN["sector"] = 3
				var N = c.ensureNemesis(); N["fac"] = "deathless"; N["revived"] = bool(cs["revived"]); N["dead"] = false; N["met"] = 2 if bool(cs["revived"]) else 3
				var boss = null
				for col in c.RUN["map"]["cols"]:
					for x in col:
						if x["type"] == "boss": boss = x
				_check(c.nemNodeIs(boss) == bool(ex["boss"]) and c.nemNodeTag(boss) == ex["tag"], name)
				if bool(cs["revived"]):
					# entering the boss stop starts the boss battle with his settings (the rules add his flagship: scenario s1480)
					c.battle_mode = "external"
					c.RUN["curNode"] = boss["id"]
					c._enter_battle_node(boss)
					var cfg = c.B.get("cfg") if c.B is Dictionary else null
					_check(cfg is Dictionary and cfg.get("kind") == "boss" and cfg.get("nemesis") is Dictionary and cfg["nemesis"].get("fac") == "deathless", name + ": entering it starts the boss battle with his Nemesis settings (%s)" % str(cfg.get("kind") if cfg is Dictionary else cfg))
					c.battle_mode = ""
	# item 2: the medal waits for the kill that ends him
	for dead in [false, true]:
		var k := Career.new()
		var run := {"sector": 3, "nem": {"dead": dead}, "t0": "t1480"}
		var B := {"cfg": {"kind": "elite"}, "round": 6, "units": [
			{"id": "a", "side": "player", "name": "Oath", "dead": false},
			{"id": "b", "side": "enemy", "name": "Pale Regent Sorrow", "dead": true, "nemFlag": true}]}
		k.record_battle(run, B, "win")
		_check(k.P["medals"].has("nemesis_slain") == dead, "item 2: the Nemesis medal %s when his Sector 3 flagship falls and he is %s" % ["comes" if dead else "waits", "dead" if dead else "reassembling"])
	print("RETREAT_NEMESIS_1480 fails=%d" % fails)
	quit(1 if fails else 0)
