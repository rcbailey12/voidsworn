# Issue 1175: an unmet Nemesis can never be dodged on the sector map. 3,000 seeded sectors (1,000 each of sectors 1 to 3):
# count the sectors where some route reaches the boss without passing a stop nemNodeIs marks as the meeting, with the
# commander unmet and no strike pending. Also checks every boss stop carries its objective and board shape on the map.
#   godot --headless --path godot --script res://campaign/test/nem_dodge_test.gd [-- --report]
# Browser twin: node godot/campaign/test/node/nem_dodge.js (same seeds, same lines; the digest compares the boss rolls).
# --report prints the counts and always exits 0 (used to record the count on main before the fix).
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/battle_api.gd").JSM
const PER_SECTOR := 1000

func _init() -> void:
	var report := OS.get_cmdline_user_args().has("--report")
	var C = CampaignScript.new()
	var err = C.load_tables()
	if err != "": printerr(err); quit(1); return
	var dodge := 0; var total := 0; var boss_bad := 0; var tag_bad := 0; var h := 0
	for s in [1, 2, 3]:
		for i in range(PER_SECTOR):
			JSM.rnd_seed(1175000 + s * 10000 + i)
			C.RUN = null
			var m = C.genSector(s)
			C.RUN = {"sector": s, "map": m, "nemStrike": false}
			var N = {"met": 0, "dead": false}
			total += 1
			if _reach_boss_unmet(C, m, N): dodge += 1
			var cols: Array = m["cols"]; var boss = cols[cols.size() - 1][0]
			for ch in (str(boss.get("enc")) + "/" + str(boss.get("shape")) + ";").to_utf8_buffer(): h = (h * 31 + ch) % 2147483647
			if not (C.jt(boss.get("enc")) and C.jt(boss.get("shape")) and C.TB.BOSS_ENC.has(boss["enc"])): boss_bad += 1
			for n in cols[cols.size() - 3]:
				if C.nemNodeIs(n, N) != (C.nemNodeTag(n, N) == "Nemesis meeting") or not C.nemNodeIs(n, N): tag_bad += 1
	C.RUN = null
	var play_bad := 0 if report else _play_rest_meetings()
	print("nem_dodge: %d of %d sectors let an unmet Nemesis be dodged (%.1f%%)" % [dodge, total, 100.0 * dodge / total])
	print("nem_dodge: %d boss stops without an objective and board shape on the map; %d column 4 stops not marked and tagged as the meeting" % [boss_bad, tag_bad])
	print("nem_dodge: boss roll digest %d" % h)   # node/nem_dodge.js prints the same digest from the browser game
	if report: quit(0); return
	var ok := dodge == 0 and boss_bad == 0 and tag_bad == 0 and play_bad == 0
	print("PASS" if ok else "FAIL")
	quit(0 if ok else 1)

# true when a route from column 0 reaches the boss without entering a meeting stop
func _reach_boss_unmet(C, m, N) -> bool:
	var cols: Array = m["cols"]; var byId := {}
	for col in cols:
		for n in col: byId[n["id"]] = n
	var frontier: Array = []
	for n in cols[0]:
		if not C.nemNodeIs(n, N): frontier.append(n["id"])
	var seen := {}
	while frontier.size() > 0:
		var id = frontier.pop_back()
		if seen.has(id): continue
		seen[id] = true
		if byId[id]["type"] == "boss": return true
		for e in m["edges"]:
			if e[0] == id and not C.nemNodeIs(byId[e[1]], N): frontier.append(e[1])
	return false

# Play the meeting at each kind of column 4 stop that is not a fight: the stop opens his fight (an elite Nemesis battle),
# a won fight returns to the map with the stop done and him met this sector, and the boss fight uses the objective on its stop.
func _play_rest_meetings() -> int:
	var bad := 0
	for kind in ["shipyard", "drydock", "field", "event"]:
		var C = CampaignScript.new(); C.load_tables(); C.fixed_clock = true
		JSM.rnd_seed(1175)
		C.newRun("vex", "voidsworn")
		var cols: Array = C.RUN["map"]["cols"]; var c4: Array = cols[cols.size() - 3]
		var n = c4[0]; n["type"] = kind
		for k in ["enc", "shape", "arch", "mod", "rw", "seed"]: n.erase(k)
		var from = cols[cols.size() - 4][0]
		if not C.RUN["map"]["edges"].any(func(e): return e[0] == from["id"] and e[1] == n["id"]): C.RUN["map"]["edges"].append([from["id"], n["id"]])
		C.RUN["pos"] = from["id"]; from["done"] = true
		var N = C.ensureNemesis(); N["met"] = 0; C.RUN["nemStrike"] = false
		C.mapScreen()
		C.act("enterNode", n["id"])
		var ok1: bool = C.page.get("kind") == "battle" and C.B != null and C.B.get("cfg") is Dictionary and C.jt(C.B["cfg"].get("nemesis"))
		if not ok1: bad += 1; printerr("FAIL: a %s in column 4 did not open the Nemesis fight (page %s)" % [kind, C.page.get("kind")]); continue
		C.act("battle", "win")
		for i in range(30):
			if C.page.get("kind") == "map" and C.modal_d == null: break
			var acts: Array = C.screen_acts().filter(func(a): return a[2] == 1)
			if acts.is_empty(): break
			var a = acts.back()   # the confirm or next button closes each reward step
			for x in acts:
				if x[0] in ["prizeConfirm", "rewardNext", "takeSalvage", "closeModal", "backMap"]: a = x
			C.act(a[0], a[1])
		var ok2: bool = C.page.get("kind") == "map" and C.jt(n.get("done")) and float(C.nemActive()["met"]) >= float(C.RUN["sector"])
		if not ok2: bad += 1; printerr("FAIL: after the meeting at a %s: page %s, done %s" % [kind, C.page.get("kind"), str(n.get("done"))])
	# the flagship fight uses the objective and board its stop showed
	var D = CampaignScript.new(); D.load_tables(); D.fixed_clock = true
	JSM.rnd_seed(11751)
	D.newRun("vex", "voidsworn")
	var dc: Array = D.RUN["map"]["cols"]; var boss = dc[dc.size() - 1][0]
	boss["enc"] = "ambush"; boss["shape"] = "hourglass"
	var prev = D.RUN["map"]["edges"].filter(func(e): return e[1] == boss["id"])[0][0]
	D.RUN["pos"] = prev; D.findNode(prev)["done"] = true
	D.ensureNemesis()["met"] = 1
	D.mapScreen(); D.act("enterNode", boss["id"])
	var bc = D.B["cfg"] if D.B != null and D.B.get("cfg") is Dictionary else {}
	if bc.get("obj") != "ambush" or bc.get("shape") != "hourglass": bad += 1; printerr("FAIL: the boss fight did not use its stop's objective and board: %s %s" % [bc.get("obj"), bc.get("shape")])
	print("nem_dodge: meetings played at a column 4 shipyard, drydock, field and event; boss fight read its stop (%d failed)" % bad)
	return bad
