# Issue 1175: an unmet Nemesis can never be dodged on the sector map. 3,000 seeded sectors (1,000 each of sectors 1 to 3):
# count the sectors where some route reaches the boss without passing a stop nemNodeIs marks as the meeting, with the
# commander unmet and no strike pending. Also checks every boss stop carries its objective and board shape on the map.
#   godot --headless --path godot --script res://campaign/test/nem_dodge_test.gd [-- --report]
# Browser twin: node godot/campaign/test/node/nem_dodge.js (same seeds, same lines; the digest compares the boss rolls).
# --report prints the counts and always exits 0 (used to record the count on main before the fix).
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/battle_api.gd").JSM
const View = preload("res://campaign/campaign_view.gd")
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
	var play_bad := 0 if report else _play_rest_meetings() + _reload_meetings()
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

# Issue 1177: every service remains open after its Nemesis fight, through a reload of the rewards and the service itself.
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
		if not str(View.stop(C, n)["objective"]).contains("then use the stop"):
			bad += 1; printerr("FAIL: the %s route does not say what follows the fight" % kind)
		C.act("enterNode", n["id"])
		var ok1: bool = C.page.get("kind") == "battle" and C.B != null and C.B.get("cfg") is Dictionary and C.jt(C.B["cfg"].get("nemesis"))
		if not ok1: bad += 1; printerr("FAIL: a %s in column 4 did not open the Nemesis fight (page %s)" % [kind, C.page.get("kind")]); continue
		C.act("battle", "win")
		var stop_id: String = n["id"]
		var D = _fresh()
		D.load_save_text(C.save_text()); D.titleScreen(); D.act("continueRun")
		C = D; n = C.findNode(stop_id)
		for i in range(30):
			if C.RUN.get("reward") == null: break
			var acts: Array = C.screen_acts().filter(func(a): return a[2] == 1 and a[0] in ["prizeConfirm", "takeSalvage", "rewardNext", "takeMod", "takeBoon", "takeRelic", "takePerk"])
			if acts.is_empty(): break
			var a = acts[0]
			C.act(a[0], a[1])
		if C.RUN.get("reward") != null or C.jt(n.get("done")) or not _at_service(C, kind):
			bad += 1; printerr("FAIL: after the meeting at a %s: page %s, modal %s" % [kind, C.page.get("kind"), str(C.modal_d.get("kind")) if C.modal_d != null else "none"]); continue
		var service_acts: Array = C.screen_acts().duplicate(true)
		var event_id = C.cur_event["id"] if kind == "event" else null
		var battles = C.RUN["stats"]["battles"]
		D = _fresh(); D.load_save_text(C.save_text()); D.titleScreen(); D.act("continueRun")
		if not _at_service(D, kind) or D.screen_acts() != service_acts or D.RUN["stats"]["battles"] != battles or (kind == "event" and D.cur_event["id"] != event_id):
			bad += 1; printerr("FAIL: the %s service changed or replayed the battle on reload" % kind); continue
		if kind == "shipyard": D.act("leaveYard")
		elif kind == "event":
			for j in range(D.cur_event["o"].size()):
				var choice = D.cur_event["o"][j]
				if not D.eventOptOk(choice) or (choice.get("r") is Dictionary and D.jt(choice["r"].get("fight"))): continue
				D.act("eventChoice", str(j)); break
		else: D.act("repairStop", "service")
		if not D.jt(D.findNode(stop_id).get("done")) or D.RUN.get("curNode") != null:
			bad += 1; printerr("FAIL: using the %s did not finish the stop" % kind)
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
	print("nem_dodge: the win led to the column 4 shipyard, drydock, field and event and each resumed on reload; boss fight read its stop (%d failed)" % bad)
	return bad

func _at_service(c, kind: String) -> bool:
	if kind == "shipyard": return c.page.get("kind") == "shipyard" and c.modal_d == null
	if c.modal_d == null: return false
	if kind == "event": return c.modal_d["kind"] == "event"
	return c.modal_d["kind"] == "repair_stop" and c.modal_d["data"]["kind"] == kind

# A meeting at a rest stop replays the same fight after a reload (Artoo, PR 1197): the stop carries a battle seed like a fight
# stop. For a map made now and for an old map whose column 4 rest stop has no seed: opening the saved map twice gives the
# same fight, and a reload in the middle of that fight gives it again (seed, objective, board, enemy ships).
func _fight_print(C) -> String:
	if C.B == null or not (C.B.get("cfg") is Dictionary): return "no battle"
	var foes: Array = []
	for u in C.B["units"]:
		if u["side"] == "enemy": foes.append(str(u["tpl"]))
	foes.sort()
	return "%s|%s|%s|%s" % [str(C.B["seed"]), str(C.B["cfg"].get("obj")), str(C.B["cfg"].get("shape")), ",".join(PackedStringArray(foes))]
func _fresh():
	var C = CampaignScript.new(); C.load_tables(); C.fixed_clock = true; C.persist_on = false
	return C
func _reload_meetings() -> int:
	var bad := 0
	for legacy in [false, true]:
		var C = _fresh(); JSM.rnd_seed(11752)
		C.newRun("vex", "voidsworn")
		var cols: Array = C.RUN["map"]["cols"]; var n = cols[cols.size() - 3][0]; n["type"] = "shipyard"
		for k in ["enc", "shape", "arch", "mod", "rw", "seed"]: n.erase(k)
		var from = cols[cols.size() - 4][0]
		if not C.RUN["map"]["edges"].any(func(e): return e[0] == from["id"] and e[1] == n["id"]): C.RUN["map"]["edges"].append([from["id"], n["id"]])
		C.RUN["pos"] = from["id"]; from["done"] = true
		C.ensureNemesis()["met"] = 0; C.RUN["nemStrike"] = false
		if legacy: C.saveRun()   # an old map: the rest stop was saved with no seed
		else: C.mapScreen()      # a map made now: opening it gives every column 4 stop its seed
		var text0: String = C.save_text()
		if legacy:   # the first Continue of the old save opens the map, which gives the stop its seed and saves it
			var L = _fresh(); JSM.rnd_seed(77)
			L.load_save_text(text0); L.titleScreen(); L.act("continueRun"); text0 = L.save_text()
		var tag := "old map" if legacy else "new map"
		var prints: Array = []
		for i in range(2):
			var A = _fresh(); JSM.rnd_seed(500 + i)   # different random state each time: only the saved seed may decide
			A.load_save_text(text0); A.titleScreen(); A.act("continueRun"); A.act("enterNode", n["id"])
			prints.append(_fight_print(A))
			if i == 0:
				var mid: String = A.save_text()
				var Bc = _fresh(); JSM.rnd_seed(900)
				Bc.load_save_text(mid); Bc.titleScreen(); Bc.act("continueRun")
				if Bc.page.get("kind") == "map" and Bc.availableNodes().has(n["id"]): Bc.act("enterNode", n["id"])   # closed mid-fight: Continue, then the same stop
				prints.append(_fight_print(Bc))
		if prints[0] == "no battle" or prints.any(func(x): return x != prints[0]):
			bad += 1; printerr("FAIL: %s: the Nemesis fight at a rest stop changed on reload: %s" % [tag, str(prints)])
		else: print("nem_dodge: %s, rest-stop meeting replays the same fight on reopen and mid-fight reload (%s)" % [tag, prints[0]])
	return bad
