# Issue 1451 (R378, RULEBOOK 9.18): round-start saves give the same battle as no save at all.
#   godot --headless --path godot --script res://campaign/test/round_save_stress.gd -- [first_seed] [last_seed] [reload_percent]
# Defaults: seeds 1 to 120, a reload at 50% of round starts. Exit 0 when every seed passes.
#
# Each seed sets up a campaign run (faction, sector, extra ships, battle, elite, boss or an event fight, and in Sector III the
# story buff spent or unspent, issue 1338) and plays the battle twice through the real campaign and the real rules API, with the
# game's own player-side AI for your ships:
#   run A: no reload.
#   run B: at random round starts the round is saved (campaign.save_battle_round), the player picks Save and quit to title
#          (leave_battle_saved), the save text is read by a brand-new campaign (load_save_text, title, Continue) and the battle
#          goes on from the restored rules API.
# After the battle each run is settled by the campaign (finish_battle) and recorded: every unit at the end, the battle log, the
# shared random stream, and the settled run (fleet uid, hull, XP, rank, career; reserve, fallen, credits, stats, the reward
# offer, the next page). The two records must match exactly. Also checked: a resumed fight never carries a story buff that
# was spent before it (issue 1338), and the round save is gone from the save once the battle is settled.
extends SceneTree
@warning_ignore_start("untyped_declaration", "unsafe_method_access", "unsafe_call_argument", "inference_on_variant", "unsafe_property_access", "return_value_discarded")
const API = preload("res://rules/battle_api.gd")
const JSM = API.JSM
const Campaign = preload("res://campaign/campaign.gd")

var api = null
var reload_pct := 50
var lcg := 1
var reloads := 0
var pack_ms_max := 0.0
var bytes_max := 0

func _setup(run: Dictionary, cfg: Dictionary) -> Dictionary:
	api = API.new(); api.load_rules(); api.set_ai_level("veteran"); api.round_saves = true
	api.new_battle(run, cfg)
	return api.R.B

func _restore(sb: Dictionary) -> Dictionary:
	var a = API.new(); a.load_rules()
	var why: String = a.restore_round(Marshalls.base64_to_raw(sb["data"]), int(sb["size"]), str(sb["fp"]))
	if why != "": return {"error": why}
	a.round_saves = true; api = a
	return {"B": a.R.B, "run": a.R.RUN}

func _fresh() -> Variant:
	var C = Campaign.new(); C.load_tables(); C.persist_on = false; C.fixed_clock = true
	C.battle_mode = "external"; C.battle_setup = _setup; C.battle_restore = _restore
	return C

func _rand(n: int) -> int:
	lcg = (lcg * 1103515245 + 12345) % 2147483648
	return (lcg >> 8) % n

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var s0 := int(a[0]) if a.size() > 0 else 1
	var s1 := int(a[1]) if a.size() > 1 else 120
	reload_pct = int(a[2]) if a.size() > 2 else 50
	var bad := 0; var battles := 0; var rounds := 0; var t0 := Time.get_ticks_msec()
	for s in range(s0, s1 + 1):
		var r := _seed(s)
		if r.has("fail"):
			bad += 1; print("seed %d: FAIL %s" % [s, r["fail"]])
		else:
			battles += 1; rounds += int(r["rounds"])
			print("seed %d: PASS %s, %d rounds, %d reloads, %s" % [s, r["what"], r["rounds"], r["reloads"], r["result"]])
	print("round_save_stress: %d of %d seeds identical, %d rounds, %d reloads, worst pack %.1f ms, biggest snapshot %d KB (packed), %.0f s" % [battles, s1 - s0 + 1, rounds, reloads, pack_ms_max, bytes_max / 1024, (Time.get_ticks_msec() - t0) / 1000.0])
	quit(1 if bad > 0 else 0)

# The save text a seed starts from: the run set up and saved at the fight's stop (as entering the stop saves it).
func _start_text(s: int) -> Dictionary:
	var C = _fresh()
	C.rng.rnd_seed(s * 7919); C.META = C.defaultMeta()
	var facs := ["voidsworn", "corsair", "ithar", "deathless", "chorus", "hegemony"]
	var fac: String = facs[s % facs.size()]
	var adm = null
	for id in C.ADMIRALS.keys():
		if C.ADMIRALS[id].get("fac") == fac and adm == null: adm = id
	C.newRun(adm, fac, {})
	if C.RUN == null: return {"fail": "no run for " + fac}
	var sector := 1 + (s % 3)
	C.RUN["sector"] = sector; C.RUN["map"] = C.genSector(sector); C.RUN["pos"] = null
	for i in range((sector - 1) * 2 + (s % 2)):
		var sh = C.newShip(C.cheapHull(fac)); C.RUN["fleet"].append(sh)
	var want := "battle"
	if s % 10 == 0: want = "boss"
	elif s % 4 == 1: want = "elite"
	var what := want
	var node = null
	for col in C.RUN["map"]["cols"]:
		for n in col:
			if node == null and n["type"] == want: node = n
	if node == null:
		for col in C.RUN["map"]["cols"]:
			for n in col:
				if node == null and n["type"] == "battle": node = n
		what = "battle"
	var story := ""
	if sector == 3 and C.TB.STORY_BEAT3.has(fac):
		var beat = C.TB.STORY_BEAT3[fac]
		C.RUN["flags"][beat["id"]] = "0"
		if s % 2 == 0:
			C.RUN["storyNext"] = C._story_modifiers(beat["o"][0]["r"], {}); story = "buff unspent"
		else:
			C.RUN["storyNext"] = null; story = "buff spent"
	if s % 7 == 3:   # an event fight (the event stop resumes as its fight, campaign.gd _resume_node)
		var ev_node = null
		for col in C.RUN["map"]["cols"]:
			for n in col:
				if ev_node == null and n["type"] == "event": ev_node = n
		var found = null
		for e in C.EVENTS:
			var ev = C._event_for_faction(e)
			for i in range(ev["o"].size()):
				var o = ev["o"][i]
				if found == null and o.get("r") is Dictionary and C.jt(o["r"].get("fight")): found = [e["id"], C.or_(o.get("k"), str(i))]
		if ev_node != null and found != null:
			node = ev_node; what = "event fight " + str(found[0])
			if not (C.RUN.get("seenEvents") is Array): C.RUN["seenEvents"] = []
			C.RUN["seenEvents"].append(found[0]); C.RUN["flags"][found[0]] = found[1]
	if node == null: return {"fail": "no fight stop"}
	C.RUN["pos"] = node["id"]; C.RUN["curNode"] = node["id"]
	C.saveRun()
	return {"text": C.save_text(), "what": what + (" " + fac) + (" sector %d" % sector) + ((", " + story) if story != "" else ""), "story": story}

func _seed(s: int) -> Dictionary:
	var st := _start_text(s)
	if st.has("fail"): return st
	var ra := _play(st["text"], false, s)
	if ra.has("fail"): return {"fail": "run A: " + ra["fail"]}
	var rb := _play(st["text"], true, s)
	if rb.has("fail"): return {"fail": "run B: " + rb["fail"]}
	if st["story"] == "buff spent" and (ra["mods"] != null or rb["mods"] != null): return {"fail": "issue 1338: a spent story buff came back (%s, %s)" % [str(ra["mods"]), str(rb["mods"])]}
	if st["story"] == "buff unspent" and (ra["mods"] == null or rb["mods"] == null): return {"fail": "the unspent story buff was not in the fight"}
	for k in ra["rec"].keys():
		if JSON.stringify(ra["rec"][k]) != JSON.stringify(rb["rec"].get(k)):
			var xa: String = JSON.stringify(ra["rec"][k]); var xb: String = JSON.stringify(rb["rec"].get(k))
			var i := 0
			while i < mini(xa.length(), xb.length()) and xa[i] == xb[i]: i += 1
			return {"fail": "%s differs (%d reloads): ...%s... vs ...%s..." % [k, rb["reloads"], xa.substr(maxi(0, i - 80), 140), xb.substr(maxi(0, i - 80), 140)]}
	var da: String = JSON.stringify(ra["rec"]); var db: String = JSON.stringify(rb["rec"])
	if da != db:
		var la := da.split(","); var lb := db.split(",")
		for i in range(mini(la.size(), lb.size())):
			if la[i] != lb[i]: return {"fail": "records differ at field %d: %s vs %s (%d reloads)" % [i, la[i], lb[i], rb["reloads"]]}
		return {"fail": "records differ in length"}
	return {"what": st["what"], "rounds": ra["rounds"], "reloads": rb["reloads"], "result": ra["result"]}

# Plays the seed's fight from its start text; with reload, saves and resumes at random round starts.
func _play(text: String, reload: bool, s: int) -> Dictionary:
	lcg = s * 2654435761 % 2147483648
	var C = _fresh(); api = null
	C.seed_rng(s * 31337)
	C.load_save_text(text); C.titleScreen(); C.act("continueRun")
	if C.pending_battle == null or api == null: return {"fail": "Continue did not start the fight (page %s)" % str(C.page.get("kind"))}
	var mods = C.B["cfg"].get("storyMods")
	var n_rel := 0; var seen := 0; var guard := 0
	if OS.get_environment("RS_DEBUG") == "1": print("  start: alt %s kind %s" % [str(api._alt), str(C.B["cfg"].get("kind"))])
	while api.phase != "over" and guard < 20000:
		guard += 1
		if api.phase == "halted": return {"fail": "battle halted: " + str(api.halted)}
		if api.phase == "player":
			if api.round_snap_round > seen:
				seen = api.round_snap_round
				var snap: Dictionary = api.take_round_snapshot()
				if snap.is_empty(): return {"fail": "round %d has no snapshot: %s" % [seen, api.round_snap_error]}
				pack_ms_max = maxf(pack_ms_max, float(snap["ms"])); bytes_max = maxi(bytes_max, snap["bytes"].size())
				C.save_battle_round(snap)   # both runs save: only run B reloads
				if reload and _rand(100) < reload_pct:
					C.leave_battle_saved()
					if C.page.get("kind") != "title": return {"fail": "Save and quit did not reach the title"}
					var t2: String = C.save_text()
					var D = _fresh(); api = null
					D.seed_rng(_rand(1 << 30))   # a new launch: the stream is restored from the save, not from here
					D.load_save_text(t2); D.titleScreen(); D.act("continueRun")
					if D.pending_battle == null or api == null: return {"fail": "Continue did not resume round %d (page %s)" % [seen, str(D.page.get("kind"))]}
					if int(api.R.B["round"]) != seen: return {"fail": "resumed round %d, saved %d" % [int(api.R.B["round"]), seen]}
					C = D; n_rel += 1; reloads += 1
					api.take_events()
					continue
			var me = null
			for u in api.view()["units"]:
				if u["side"] == "player" and not u["dead"] and not u["activated"] and not u["squadron"]:
					me = u; break
			if me == null:
				if api._alt: api.end_activation()
				else: api.end_turn()
				api.take_events(); continue
			var r0 = int(api.R.B["round"])
			api.ai_activate(me["id"])
			# a ship the AI left idle is passed, as the battle scene's bot does, but only in the same round: when the AI's
			# activation ended the round, the ship belongs to the new round (and the round save already holds that start)
			if api.phase == "player" and int(api.R.B["round"]) == r0 and api.unit(me["id"]) != null and not C.jt(api.unit(me["id"]).get("activated")): api.end_activation(me["id"])
			api.take_events()
		else:
			api.step()
	if api.phase != "over": return {"fail": "no end after %d steps" % guard}
	var B = api.R.B
	var rec := {"round": B["round"], "over": B["over"], "rng_battle": api.R.rng.rng_s, "log": str(B.get("log", [])).md5_text(), "units": []}
	for u in B["units"]:
		rec["units"].append([u["id"], u["tpl"], u["side"], u["hp"], u["sh"], u["q"], u["r"], u["facing"], C.jt(u.get("dead")), C.jt(u.get("fled")), C.jt(u.get("exited")), u.get("dealt"), u.get("kills")])
	var raw := str(api.battle_result())
	var res := raw if raw in ["win", "loss", "retreat"] else "loss"
	C.finish_battle(res, B)
	if C.saved_battle != null: return {"fail": "the round save outlived the settled battle"}
	rec["rng_after"] = C.rng.rng_s
	if C.RUN != null:
		var fl := []
		for sh in C.RUN["fleet"]:
			fl.append([sh["uid"], sh["tpl"], sh["hp"], sh["cap"]["rank"], sh["cap"].get("xp"), sh.get("car")])
		rec["fleet"] = fl
		rec["run"] = [C.RUN.get("credits"), C.RUN.get("reserve"), C.RUN.get("fallen"), C.RUN.get("stats"), C.RUN.get("reward"), C.RUN.get("storyNext"), C.RUN.get("curNode"), C.RUN.get("pos")]
	rec["page"] = [C.page.get("kind"), C.modal_d.get("kind") if C.modal_d != null else null, C.ended]
	return {"rec": rec, "rounds": int(B["round"]), "reloads": n_rel, "result": res, "mods": mods}
