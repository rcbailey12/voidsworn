extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const API = preload("res://rules/battle_api.gd")
const CaptainData = preload("res://rules/captain_data.gd")
const Portraits = preload("res://portraits/portraits.gd")
const PreviewOp = preload("res://campaign/preview_op.gd")

var fails := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		fails += 1
		printerr("FAIL: " + label)


func fresh() -> Campaign:
	var c := Campaign.new()
	check(c.load_tables() == "", "load campaign tables")
	c.fixed_clock = true
	c.persist_on = false
	c.META = c.defaultMeta()
	API.JSM.rnd_seed(2078)
	c.newRun("vex", "voidsworn", {})
	return c


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	captains()
	shipyard()
	combat()
	earned_xp()
	print("AAA UI data: " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)


func captains() -> void:
	var c := fresh()
	var sh: Dictionary = c.RUN["fleet"][0]
	var perk: String = c.PERKS.keys()[0]
	sh["cap"] = {"name": "Legacy Captain", "xp": 17, "rank": 1, "perks": [perk], "fac": "voidsworn"}
	c.RUN["reserve"] = [{"from": "Old Hull", "cap": {"name": "Reserve Captain", "xp": 9}}]
	c.RUN["fallen"] = [{"ship": "First Hull", "name": "Fallen Captain", "rank": 2, "fac": "voidsworn"}]
	c.META["fallen"] = c.RUN["fallen"].duplicate(true)
	c.saveRun()
	var other := fresh()
	other.load_save_text(c.save_text())
	var restored: Dictionary = other.SAVED_RUN
	var cap: Dictionary = restored["fleet"][0]["cap"]
	for key in ["captain_id", "portrait_id", "full_name", "callsign", "rank", "xp", "trait_line"]:
		check(cap.has(key), "CaptainData field " + key)
	check(not cap.has("name") and cap["full_name"] == "Legacy Captain" and cap["xp"] == 17, "legacy active captain name and XP retained")
	check(cap["trait_line"] == c.PERKS[perk]["d"], "trait is the authored perk description")
	check(restored["reserve"][0]["cap"]["xp"] == 9 and restored["reserve"][0]["cap"]["full_name"] == "Reserve Captain", "legacy reserve migrated")
	check(restored["fallen"][0]["cap"]["rank"] == 2 and other.META["fallen"][0]["cap"]["full_name"] == "Fallen Captain", "both fallen rolls migrated")
	check(other.migrateRun(restored.duplicate(true)) == restored, "migration is idempotent")
	var used := {}
	var faces := Portraits.captain_pool("voidsworn")
	for i in range(faces.size() + 1):
		var new_cap := CaptainData.make("captain:test:%d" % i, "voidsworn", "Test")
		CaptainData.assign_portrait(new_cap, used)
		check(CaptainData.CALLSIGNS["voidsworn"].has(new_cap["callsign"]), "callsign comes from the captain's faction")
		if i < faces.size():
			check(faces.has(new_cap["portrait_id"]) and Portraits.captain_face(new_cap["portrait_id"]) != null, "assigned indexed face loads without repeating")
		else:
			check(new_cap["portrait_id"] == "" and used.size() == faces.size(), "exhausted pool never repeats a portrait")


func row(rows: Array, key: String) -> Dictionary:
	for item in rows:
		if item["stat_key"] == key: return item
	return {}


func verify_commit(c: Campaign, sh: Dictionary, rows: Array, paid: float, action: String) -> void:
	var actual := PreviewOp._stats(c, sh)
	for item in rows:
		var key: String = item["stat_key"]
		check(item["disabled_reason"] == "" and is_equal_approx(item["new"], actual[key]), action + " committed " + key)
		check(is_equal_approx(item["new"] - item["old"], item["delta"]), action + " delta " + key)
		check(is_equal_approx(item["cost"], paid), action + " cost " + key)


func shipyard() -> void:
	var c := fresh()
	var sh: Dictionary = c.RUN["fleet"][0]
	var uid: String = sh["uid"]
	c.RUN["credits"] = 5000
	c.RUN["cpCap"] = 100
	c.RUN["inventory"] = ["prow"]
	c.shipyardScreen({"type": "shipyard", "stock": {"hulls": ["warden"], "cap": [], "mods": [], "sold": []}})
	sh["hp"] -= 13
	var before: Dictionary = c.RUN.duplicate(true)
	var rng: int = API.JSM.rng_s
	var repair := c.preview_op("repair", uid)
	check(c.RUN == before and API.JSM.rng_s == rng, "preview does not write run state or spend RNG")
	check(row(repair, "hull")["delta"] == 13 and row(repair, "hull")["is_better"], "repair previews 13 hull")
	var money: float = c.RUN["credits"]
	c.ACT_repair(uid)
	verify_commit(c, sh, repair, money - c.RUN["credits"], "repair")
	check(not c.preview_op("repair", uid)[0]["disabled_reason"].is_empty(), "cannot repair a full hull")
	var mark := c.preview_op("upgradeMk", uid)
	check(row(mark, "mark")["new"] == 2 and row(mark, "shield_pool")["delta"] > 0, "Mk II increases mark and the one shield pool")
	money = c.RUN["credits"]
	c.ACT_upgradeMk(uid)
	verify_commit(c, sh, mark, money - c.RUN["credits"], "Mk II")
	var refit := c.preview_op("refit", uid, 0)
	check(row(refit, "max_hull")["delta"] > 0 and row(refit, "refit_count")["delta"] == 1, "hull refit previews its existing stats")
	var hold: int = c.RUN["inventory"].size()
	c.ACT_equip("0:" + uid)
	verify_commit(c, sh, refit, hold - c.RUN["inventory"].size(), "refit")
	var reserve: Dictionary = c.newCaptain(false, "voidsworn", "reserve-test")
	reserve["perks"] = [c.PERKS.keys()[0]]
	var reserve_id: String = reserve["captain_id"]
	c.RUN["reserve"] = [{"cap": reserve}]
	money = c.RUN["credits"]
	c.RUN["credits"] = 0
	var blocked := c.preview_op("buyHull", "warden")
	check(not blocked[0]["disabled_reason"].is_empty() and row(blocked, "hull")["new"] > 0, "unaffordable hull still previews")
	var fleet_size: int = c.RUN["fleet"].size()
	c.ACT_buyHull("warden")
	check(c.RUN["fleet"].size() == fleet_size and c.RUN["reserve"].size() == 1, "disabled purchase consumes nothing")
	c.RUN["credits"] = money
	var buy := c.preview_op("buyHull", "warden")
	check(c.RUN["reserve"].size() == 1, "new-hull preview does not consume the reserve")
	c.ACT_buyHull("warden")
	var incoming: Dictionary = c.RUN["fleet"].back()
	verify_commit(c, incoming, buy, money - c.RUN["credits"], "new hull")
	check(incoming["cap"]["captain_id"] == reserve_id and c.RUN["reserve"].is_empty(), "purchase installs previewed reserve captain")


func combat() -> void:
	var c := fresh()
	var api := API.new()
	check(api.load_rules() == "", "load battle rules")
	api.new_battle(c.RUN, {"campaign": true, "seed": 2078, "kind": "battle", "obj": "rout",
		"col": 2, "map": "storm", "shape": "open", "arena": "strip", "fac": "hegemony",
		"enemies": [{"tpl": "h_picket"}, {"tpl": "h_picket"}, {"tpl": "h_picket"}]})
	var r = api.R
	var b: Dictionary = r.B
	var players: Array = r.caps("player")
	var enemies: Array = r.caps("enemy")
	if enemies.size() < 3 or players.size() < 2:
		check(false, "test fight deployed")
		return
	var target: Dictionary = players[0]
	var gun: Dictionary = enemies[2]["weapons"][0].duplicate()
	gun.merge({"pierce": 0.5, "ion": false, "crit": -1000, "acid": false, "ignite": false}, true)
	target["armor"] = 0.0
	target["hp"] = 20.0
	target["shp"] = 30.0
	target["route"] = [0, 0, 0, 0]
	r.syncShields(target)
	var taken_at_start: float = b.get("ship_rollups", {}).get(target["id"], {}).get("damage_taken", 0.0)
	var first: Dictionary = r.applyHit(enemies[0], gun, target, 10, 0)["combat_event"]
	var shield_after_first: float = target["shp"]
	var second: Dictionary = r.applyHit(enemies[1], gun, target, 8, 0)["combat_event"]
	check(first["shield_applied"] == 5 and first["hull_applied"] == 5 and first["damage_applied"] == 10, "one hit records shield and hull once")
	var second_applied: float = 4 + shield_after_first - float(target["shp"])
	check(is_equal_approx(second["damage_applied"], second_applied) and second["timestamp"] == first["timestamp"] + 1, "next hit records actual shield routing loss and hull once in order")
	var hull_left: float = target["hp"]
	var shield_left: float = target["shp"]
	var before: int = b["combat_events"].size()
	var quad := 0 # Avoid a mid-section break draining the remaining pool outside the shot.
	var res := {"hull": 0, "shield": 0, "hits": 0, "misses": 0, "crits": 0, "sys": null}
	r.landVolley(enemies[2], gun, target, {"shots": [true, false, true], "quad": quad,
		"called": null, "res": res, "shBefore": shield_left, "per": func(_rear): return 1000.0, "torp": true})
	var report := api.combat_report()
	var events: Array = report["combat_events"]
	check(events.size() == before + 2, "only the two landed volley hits are recorded once")
	var fatal: Dictionary = events[before]
	check(fatal["is_killing_blow"] and fatal["hull_applied"] == hull_left, "first fatal hit counts remaining hull, never overkill")
	check(not events[before + 1]["is_killing_blow"] and events[before + 1]["hull_applied"] == 0, "post-lethal hit cannot take more hull or claim a second kill")
	check(is_equal_approx(fatal["damage_applied"], hull_left + fatal["shield_applied"]), "fatal damage is applied shield plus hull")
	var totals: Dictionary = report["ship_rollups"]
	check(totals[enemies[2]["id"]]["kills"] == 1, "one kill in the attacker's rollup")
	check(is_equal_approx(totals[target["id"]]["damage_taken"], taken_at_start + 10 + second_applied + hull_left + shield_left - float(target["shp"])), "target rollup sums applied damage")
	check(is_equal_approx(totals[enemies[2]["id"]]["damage_dealt"], fatal["damage_applied"] + events[before + 1]["damage_applied"]), "attacker rollup sums applied damage, with no volley double count")
	if c.RUN["timeline"].is_empty():
		check(false, "loss recorded in run timeline at the kill")
		return
	var lost: Dictionary = c.RUN["timeline"][0]
	check(lost["weapon_name"] == gun["n"] and lost["killer_ship_name"] == enemies[2]["name"] and lost["killer_ship_class"] == enemies[2]["cls"], "killmail snapshots the in-game weapon and killer")
	check(lost["battle"] == 1 and lost["round"] == b["round"] and lost["final_damage"] == fatal["damage_applied"], "killmail snapshots the battle, round and final applied damage")
	check(lost["assists"].size() == 2 and lost["assists"][0]["ship_id"] == enemies[0]["id"], "top two assists ranked by applied damage")
	check(is_equal_approx(lost["assists"][0]["damage_share"], 10.0 / totals[target["id"]]["damage_taken"]), "assist share uses all damage applied to the victim")
	var name_at_loss: String = target["ship"]["cap"]["full_name"]
	target["ship"]["cap"]["full_name"] = "Changed later"
	b["combat_events"][before]["weapon_name"] = "Changed later"
	check(lost["captain"]["full_name"] == name_at_loss and lost["fatal_event"]["weapon_name"] == gun["n"], "killmail has no live captain or event references")
	check(report["combat_events"][before]["weapon_name"] == gun["n"], "public report is a copy")
	var hazard: Dictionary = players[1]
	hazard["hp"] = 1.0
	b["well"] = {"q": hazard["q"], "r": hazard["r"]}
	r.wellTick(hazard, [])
	var tidal: Dictionary = c.RUN["timeline"].back()
	check(tidal["ship_id"] == hazard["ship"]["uid"] and tidal["hazard_name"] == "Dead star", "environmental kill names the hazard")
	check(tidal["killer_ship_id"] == "" and tidal["final_damage"] == 1.0, "environmental final damage is capped with no killer ship")
	r.flush_deferred()
	b["well"] = null
	check(r.legionRise(hazard, true), "returning hull finds room to reassemble")
	check(c.RUN["timeline"].size() == 1 and c.RUN["timeline"][0] == lost, "a reassembled ship no longer counts as a fleet loss")


func earned_xp() -> void:
	var c := fresh()
	var api := API.new()
	check(api.load_rules() == "", "load rules for XP settlement")
	c.battle_mode = "external"
	api.new_battle(c.RUN, {"campaign": true, "seed": 25, "kind": "battle", "obj": "rout",
		"col": 2, "map": "belt", "shape": "open", "arena": "strip", "fac": "corsair"})
	var unit: Dictionary = api.R.caps("player")[0]
	var before: float = unit["ship"]["cap"]["xp"]
	c.finish_battle("win", api.R.B)
	var report: Dictionary = c.RUN.get("last_battle_report", {})
	check(report.get("result") == "win", "settled result available after the battle rules are released")
	if report.is_empty(): return
	var ship_row: Dictionary = report["ship_rollups"][unit["id"]]
	check(ship_row["captain_xp"] > 0 and ship_row["captain_xp"] == unit["ship"]["cap"]["xp"] - before, "rollup carries XP actually awarded")
	check(ship_row["captain"]["captain_id"] == unit["ship"]["cap"]["captain_id"], "rollup names the ship and captain without a battle lookup")
