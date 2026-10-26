# Story stream checks, headless (no window):
#   godot --headless --path godot --script res://story/test/story_test.gd [-- runs]
# 1. data: every admiral in the campaign tables has every moment; every title names all six factions; no em or en
#    dashes and no empty lines in any story text.
# 2. titles: hand-made run records earn the expected title.
# 3. career: battles and run ends update records and medals; the profile survives a save and load round trip.
# 4. battle voice: a real rules battle (scenario s1, both sides on the game's AI) played event by event through the voice.
# 5. the story layer attached to a real campaign (stub battles) for whole runs: no errors, every battle and run recorded,
#    and the campaign's own state never touched (the run and profile hash the same with and without the story attached).
# Prints PASS or FAIL per check; exit code 0 only when all pass.
extends SceneTree

const Career = preload("res://story/career.gd")
const Voice = preload("res://story/battle_voice.gd")
const StoryScript = preload("res://story/story.gd")
const CampaignScript = preload("res://campaign/campaign.gd")
const API = preload("res://rules/battle_api.gd")

var fails := 0
var MOMENTS := ["pick", "sector", "start", "boss", "nemesis", "kill_flag", "lost", "flag_hurt", "command", "win", "loss"]


func ok(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		fails += 1


func _initialize() -> void:
	var runs := 6
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		runs = int(a[0])
	t_data()
	t_titles()
	t_career()
	t_voice()
	t_campaign(runs)
	t_arc()
	await t_ui()
	print("story_test: %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(0 if fails == 0 else 1)


func _read(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	return f.get_as_text() if f != null else ""


func _strings(x, out: Array) -> void:
	if x is String:
		out.append(x)
	elif x is Array:
		for y in x:
			_strings(y, out)
	elif x is Dictionary:
		for y in x.values():
			_strings(y, out)


# ---------------------------------------------------------------- 1. data

func t_data() -> void:
	for p in ["res://story/data/voices.json", "res://story/data/titles.json", "res://story/data/medals.json", "res://story/outlines.md"]:
		var t := _read(p)
		ok(t != "", "data: %s loads" % p)
		ok(not t.contains("\u2014") and not t.contains("\u2013"), "data: %s has no em or en dashes" % p)
	var V = JSON.parse_string(_read("res://story/data/voices.json"))
	var S = StoryScript.new()
	var missing: Array = []
	for id in S.ADM:
		var A: Dictionary = V["admirals"].get(id, {})
		for m in MOMENTS:
			var v = A.get(m)
			if v == null or (v is String and v.strip_edges() == "") or (v is Array and v.is_empty()):
				missing.append("%s.%s" % [id, m])
	ok(S.ADM.size() == 24, "data: 24 admirals in the campaign tables (got %d)" % S.ADM.size())
	ok(missing.is_empty(), "data: every admiral has every moment %s" % str(missing.slice(0, 8)))
	var facs: Array = S.FACS
	var fac_ok := true
	for f in facs:
		for k in ["boss_hail", "boss_down"]:
			fac_ok = fac_ok and str(V["factions"].get(f, {}).get(k, "")) != ""
	ok(fac_ok, "data: every faction has flagship lines")
	var RL = JSON.parse_string(_read("res://story/data/rival_lines.json"))
	var rl_missing: Array = []
	var n_lines := 0
	for f in facs:
		var F: Dictionary = RL.get(f, {})
		for k in ["hail", "again", "final", "beaten", "death", "gloat", "kill", "signature", "scar"]:
			if not (F.get(k) is Array) or F[k].size() < 2:
				rl_missing.append("%s.%s" % [f, k])
			else:
				n_lines += F[k].size()
		for k in ["lance", "torp", "sq", "ram", "board", "battery", "evasive"]:
			if str(F.get("memory", {}).get(k, "")) == "":
				rl_missing.append("%s.memory.%s" % [f, k])
			n_lines += 1
		for p in RL["personalities"]:
			for k in ["hail", "beaten"]:
				if str(F.get("personality", {}).get(p, {}).get(k, "")) == "":
					rl_missing.append("%s.%s.%s" % [f, p, k])
				n_lines += 1
	ok(rl_missing.is_empty(), "data: Nemesis pools complete for all six factions (%d lines) %s" % [n_lines, str(rl_missing.slice(0, 6))])
	ok(not _read("res://story/data/rival_lines.json").contains("—"), "data: rival_lines.json has no em dashes")
	var T = JSON.parse_string(_read("res://story/data/titles.json"))
	var n_ok := true
	for t in T["titles"] + [T["fallback"]]:
		for f in facs:
			n_ok = n_ok and str(t["n"].get(f, "")) != ""
	ok(n_ok and T["titles"].size() >= 8 and T["titles"].size() <= 12, "data: %d titles (8 to 12), each named for all six factions" % T["titles"].size())
	var strs: Array = []
	_strings(V["admirals"], strs)
	var longest := 0
	for s in strs:
		longest = maxi(longest, s.split(" ", false).size())
	ok(longest <= 22, "data: admiral lines are short (longest %d words)" % longest)
	S.free()


# ---------------------------------------------------------------- 2. titles

func _L(over: Dictionary) -> Dictionary:
	var L := {"battles": 6, "kills": 12, "lost": 3, "unscarred": 2, "captures": 0, "kind": {"battery": 30, "lance": 10, "torp": 5, "sq": 5}, "fire": {"Prow": 25, "Port broadside": 10, "Starboard broadside": 10},
		"aim": 0, "ram": 0, "board": 0, "ord": {}, "ab": {}, "cmd": 2}
	for k in over:
		L[k] = over[k]
	return L


func t_titles() -> void:
	var c = Career.new()
	var cases := [
		[_L({}), "gunline"],
		[_L({"ram": 3, "board": 2}), "brawler"],
		[_L({"captures": 3}), "prizetaker"],
		[_L({"kind": {"lance": 30, "gauss": 5, "battery": 20}}), "lancer"],
		[_L({"kind": {"torp": 20, "battery": 30, "lance": 10}}), "torpedoer"],
		[_L({"kind": {"sq": 40, "battery": 30, "lance": 20}}), "carrier"],
		[_L({"kind": {"battery": 20, "lance": 10, "torp": 6, "sq": 6, "flak": 8}, "fire": {"Prow": 5, "Port broadside": 20, "Starboard broadside": 20}}), "broadside"],
		[_L({"kind": {"battery": 20, "lance": 10, "torp": 6, "sq": 6, "flak": 8}, "aim": 12}), "marksman"],
		[_L({"kind": {"battery": 20, "lance": 10, "torp": 6, "sq": 6, "flak": 8}, "ord": {"brace": 9}}), "anvil"],
		[_L({"kind": {"battery": 20, "lance": 10, "torp": 6, "sq": 6, "flak": 8}, "unscarred": 7, "battles": 7}), "unscarred"],
		[_L({"kind": {"battery": 20, "lance": 10, "torp": 6, "sq": 6, "flak": 8}, "kills": 30}), "butcher"],
		[_L({"kind": {"battery": 20, "lance": 10, "torp": 6, "sq": 6, "flak": 8}, "ab": {"evasive": 10, "reload": 8}}), "tactician"],
		[_L({"kind": {"battery": 20, "lance": 10, "torp": 6, "sq": 6, "flak": 8}}), "steadfast"],
		[_L({"battles": 2, "ram": 9}), "steadfast"],
	]
	var bad: Array = []
	for cs in cases:
		var t: Dictionary = c.title_for(cs[0], "corsair")
		if str(t["id"]) != str(cs[1]):
			bad.append("%s got %s" % [cs[1], t["id"]])
	ok(bad.is_empty(), "titles: %d hand-made runs earn the expected title %s" % [cases.size(), str(bad)])
	ok(c.title_for(_L({"kind": {"sq": 40, "battery": 30}}), "corsair")["name"] == "the Beekeeper", "titles: faction wording (Corsair carriers are the Beekeeper)")


# ---------------------------------------------------------------- 3. career

func _B(kind: String, win: bool, player_dead: int, enemy_dead: int, usage: Dictionary, rounds := 6) -> Dictionary:
	var units: Array = []
	for i in 4:
		units.append({"id": "p%d" % i, "side": "player", "dead": i < player_dead, "flagship": i == 3})
	for i in 5:
		units.append({"id": "e%d" % i, "side": "enemy", "dead": i < enemy_dead, "boss": kind == "boss" and i == 0})
	units.append({"id": "w1", "side": "enemy", "dead": true, "isSq": true})
	return {"cfg": {"kind": kind}, "units": units, "usage": usage, "round": rounds, "over": "win" if win else "loss", "finished": true}


func t_career() -> void:
	var c = Career.new()
	c.save_path = "user://story_test_career.json"
	c.persist = true
	if FileAccess.file_exists(c.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(c.save_path))
	var run := {"t0": 1000, "admiral": "grax", "fac": "corsair", "sector": 1, "heat": ["x"], "flagUid": "u1", "fleet": [{"uid": "u1", "name": "Rust Bucket"}]}
	var us := {"kind": {"battery": 10, "torp": 2}, "fire": {"Prow": 12}, "ram": 2, "board": 1, "cap": 1, "ord": {"brace": 1}, "ab": {"surge": 1}, "aim": 0, "cmd": 1}
	c.record_battle(run, _B("battle", true, 0, 5, us, 3), "win")
	c.record_battle(run, _B("elite", true, 3, 5, us), "win")
	ok(c.P["medals"].has("first_blood") and c.P["medals"].has("lightning") and c.P["medals"].has("last_stand"), "career: first blood, lightning and last stand medals")
	run["sector"] = 2
	c.record_battle(run, _B("boss", true, 0, 5, us), "win")
	ok(not c.P["medals"].has("unbroken"), "career: no Unbroken for a sector with a loss")
	ok(c.P["medals"].has("flag_breaker") and int(c.P["totals"]["flag_kills"]) == 1, "career: flagship breaker")
	ok(c.P["medals"].has("prize_master"), "career: prize master after 3 captures in a run")
	run["sector"] = 3
	c.record_battle(run, _B("battle", true, 0, 2, us), "win")
	ok(c.P["medals"].has("unbroken"), "career: Unbroken for sector II cleared without a loss")
	var row: Dictionary = c.record_run_end(run, true, "Warlord Grax Ironjaw")
	ok(str(row.get("title", "")) == "brawler" and str(row.get("title_name", "")) == "the Breaker", "career: run title (got %s %s)" % [row.get("title"), row.get("title_name")])
	ok(c.P["medals"].has("victor") and c.P["medals"].has("heat_victor"), "career: victor and heat medals")
	ok(int(c.P["admirals"]["grax"]["runs"]) == 1 and int(c.P["admirals"]["grax"]["wins"]) == 1 and c.P["admirals"]["grax"]["flagships"] == ["Rust Bucket"], "career: admiral record")
	ok(int(c.P["totals"]["kills"]) == 17 and int(c.P["totals"]["lost"]) == 3 and int(c.P["totals"]["battles"]) == 4, "career: totals (kills %s, lost %s)" % [c.P["totals"]["kills"], c.P["totals"]["lost"]])
	c.record_run_end(run, true)
	ok(int(c.P["totals"]["runs"]) == 1, "career: a run end is recorded once")
	var c2 = Career.new()
	c2.save_path = c.save_path
	c2.load_profile()
	ok(JSON.stringify(JSON.parse_string(JSON.stringify(c2.P))) == JSON.stringify(JSON.parse_string(JSON.stringify(c.P))), "career: save and load round trip")
	var f := FileAccess.open(c.save_path, FileAccess.WRITE)
	f.store_string("{broken")
	f = null
	var c3 = Career.new()
	c3.save_path = c.save_path
	c3.load_profile()
	ok(int(c3.P["totals"]["battles"]) == 4, "career: a damaged file falls back to the backup (one save behind)")
	# arc rewards (cosmetic side)
	c3.record_arc_end("chorus", "matriarch", "Rear admiral Petra Lindqvist", {"1": "ate"}, false)
	ok(not c3.P["medals"].has("arc_chorus") and c3.flagship_paint("chorus").is_empty(), "arcs: a lost arc pays nothing but is in the Chronicle")
	c3.record_arc_end("ithar", "aelith", "Warlord Bones Sharkey", {"1": "song", "2": "song", "3": "sails"}, true)
	ok(c3.P["medals"].has("arc_ithar") and c3.arc_title("ithar") == "Keeper of the Houses", "arcs: arc medal and title")
	ok(str(c3.flagship_paint("ithar").get("id", "")) == "mourning_pearl" and c3.arc_unlocks() == ["i_carrier_a"], "arcs: paint switched on and unlock reported")
	c3.set_paint("ithar", false)
	ok(c3.flagship_paint("ithar").is_empty() and c3.P["chronicle"].size() == 2, "arcs: paint switched off; two Chronicle rows")
	ok(c3.all_medals().size() == 18, "arcs: 12 medals plus 6 arc medals")
	for p in [c.save_path, c.save_path + ".bak"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


# ---------------------------------------------------------------- 4. battle voice

func t_voice() -> void:
	var v = Voice.new()
	var view := {"units": [{"id": "a", "side": "player", "flagship": true, "hp": 100, "maxHp": 100, "name": "Oathkeeper"}, {"id": "b", "side": "player", "hp": 50, "maxHp": 50, "name": "Vigil"},
		{"id": "x", "side": "enemy", "flagship": true, "hp": 200, "maxHp": 200, "name": "Dominion Prime"}, {"id": "y", "side": "enemy", "hp": 40, "maxHp": 40, "name": "Picket"}]}
	v.setup(view, {"admiral": "vex", "admiral_name": "Admiral Castellan Vex", "fac": "voidsworn", "kind": "boss", "enemy_fac": "hegemony", "sector": 1, "seed": 3, "nem": null})
	var op: Array = v.opening()
	ok(op.size() == 2 and str(op[0]["text"]).begins_with("Dominion Prime:") and str(op[1]["text"]).begins_with("Admiral Castellan Vex:"), "voice: boss opening is the enemy hail then your admiral")
	var lines: Array = []
	lines += v.on_event({"t": "hit", "target": "a", "hull": 65})
	lines += v.on_event({"t": "hit", "target": "a", "hull": 5})
	lines += v.on_event({"t": "death", "unit": "b"})
	lines += v.on_event({"t": "command", "side": "player", "id": "barrage"})
	lines += v.on_event({"t": "death", "unit": "x"})
	var ms: Array = lines.map(func(l): return l["moment"])
	ok(ms == ["flag_hurt", "lost", "command", "boss_down", "kill_flag"], "voice: big moments speak once each, in order %s" % str(ms))
	ok(str(lines[0]["text"]).contains("Oathkeeper"), "voice: {flagship} filled in")
	ok(v.closing(true).ends_with("\"The line held. It always holds.\""), "voice: closing line")
	var vn = Voice.new()
	vn.setup(view, {"admiral": "kassar", "admiral_name": "Grand Admiral Ilsa Kassar", "fac": "hegemony", "kind": "elite", "enemy_fac": "deathless", "sector": 3, "seed": 1,
		"nem": {"name": "Setekh the Patient", "title": "Dynast", "fac": "deathless"}})
	var op2: Array = vn.opening()
	var RL = JSON.parse_string(_read("res://story/data/rival_lines.json"))
	var said_final := false
	for l in RL["deathless"]["final"]:
		said_final = said_final or str(op2[0]["text"]).contains(str(l))
	ok(op2.size() == 2 and said_final and str(op2[1]["text"]).contains("Dynast Setekh the Patient"), "voice: Nemesis opening in sector III uses his final line and his name")
	ok(vn.closing(false).begins_with("Dynast Setekh the Patient:"), "voice: Nemesis gloats on a loss")
	# variety: the same moment across many generated Nemeses and seeds
	var R = load("res://story/rival.gd").new()
	var seen := {}
	for i in 60:
		var nem := {"name": "Name%d" % i, "title": "Warlord", "fac": "corsair", "personality": ["proud", "cruel", "cunning", "zealous", "cold", "mocking"][i % 6], "beaten": 0, "scars": 0}
		seen[R.opening(nem, 1, i)] = true
	ok(seen.size() >= 6, "rival: first-meeting hails vary across Nemeses (%d different lines from 60)" % seen.size())
	var again := {"name": "Scarface", "title": "Warlord", "fac": "corsair", "beaten": 1, "scars": 2, "adapt": ["armor"]}
	var kinds := {}
	for sd in 40:
		var l: String = R.opening(again, 2, sd)
		if l == str(RL["corsair"]["memory"]["ram"]):
			kinds["memory"] = true
		elif l.contains("twice"):
			kinds["scar"] = true
		else:
			kinds["again"] = true
	ok(kinds.size() == 3, "rival: a later meeting mixes memory (rammed him last time), scar ({scars} filled: twice) and rematch lines %s" % str(kinds.keys()))
	ok(R.memory_key({"seen": {"torp": 3, "lance": 9}}) == "lance" and R.memory_key({"last_beat": "board"}) == "board", "rival: memory key from seen counts or stream B's last_beat")
	var vs = Voice.new()
	vs.setup(view, {"admiral": "grax", "admiral_name": "Warlord Grax Ironjaw", "kind": "elite", "enemy_fac": "ithar", "sector": 2, "seed": 4, "nem": {"name": "Ilyra Glasswing", "title": "Starwarden", "fac": "ithar"}})
	var sl: Array = vs.on_event({"t": "nem_signature"})
	sl += vs.on_event({"t": "nem_signature"})
	ok(sl.size() == 1 and str(sl[0]["text"]).begins_with("Starwarden Ilyra Glasswing:"), "voice: his faction signature speaks once")
	# a real rules battle, both sides on the game's AI, every event through the voice
	var api = API.new()
	var e: String = api.load_rules()
	ok(e == "", "voice: rules load (%s)" % e)
	if e != "":
		return
	api.new_battle_scenario("s1")
	var rv = Voice.new()
	rv.setup_from_rules(api.R, api.view())
	var got: Array = rv.opening()
	var n_ev := 0
	var guard := 0
	while api.phase != "over" and guard < 4000:
		guard += 1
		for ev in api.take_events():
			n_ev += 1
			got += rv.on_event(ev)
		if api.phase == "player":
			var acted := false
			for u in api.view()["units"]:
				if u["side"] == "player" and not u["dead"] and not u["squadron"] and not u["activated"]:
					api.ai_activate(u["id"])
					acted = true
					break
			if not acted:
				api.end_activation()
		elif api.phase == "enemy":
			for ev in api.step():
				n_ev += 1
				got += rv.on_event(ev)
	for ev in api.take_events():
		got += rv.on_event(ev)
	var win := str(api.view().get("over", "")) == "win"
	var close: String = rv.closing(win)
	print("      s1: %d events, %d voice lines, result %s: %s" % [n_ev, got.size(), str(api.view().get("over")), str(got.map(func(l): return l["moment"]))])
	ok(api.phase == "over" and got.size() >= 1 and close != "", "voice: a real battle plays through with admiral lines (%d)" % got.size())


# ---------------------------------------------------------------- 7. arc plumbing (tokens, conditions, variants)

func t_arc() -> void:
	var T = load("res://story/tokens.gd")
	var she := {"name": "Petra Lindqvist", "title": "Rear admiral", "fac": "hegemony", "personality": "mocking", "scars": 2}
	var it := {"name": "Hollow Song", "title": "Matriarch", "fac": "chorus"}
	var he := {"name": "Grim Rattigan", "title": "Warlord", "fac": "corsair", "g": "m"}
	ok(T.fill("{He} lost {his} fleet; {he} blames {him}self. Scarred {scars}.", {"nem": she}) == "She lost her fleet; she blames herself. Scarred twice.", "tokens: she/her from the name pool")
	ok(T.fill("{He} ate {his} fill.", {"nem": it}) == "It ate its fill.", "tokens: a Chorus rival is it")
	ok(T.fill("{rival} meets {best_captain} near {first_lost}.", {"nem": he}) == "Warlord Grim Rattigan meets your senior captain near a ship of the line.", "tokens: missing run facts fall back to plain words")
	var a = load("res://story/arc.gd").new()
	ok(a.load_arc("voidsworn", "res://story/test/fixture_arc.json"), "arc: fixture loads")
	var ctx := {"nem": she, "flags": {}, "seed": 3, "seen": {"arc_voidsworn_1B": 1}, "first_lost": "", "arcs_finished": 0}
	var b1: Dictionary = a.render(1, ctx)
	ok(str(b1["b"]).contains("Rear admiral Petra Lindqvist did this. She left a bill, itemised, with a late fee.") and str(b1["b"]).contains("herself"), "arc: beat 1 fills the deed by faction and personality, with pronouns")
	ok(b1["o"][0]["fl"].get("fx_keep") == 1 and b1["o"][1]["fl"].get("greed") == 1 and b1["o"][1]["fl"].get("fx_sell") == 1, "arc: an option's story flag rides in fl (the event system stores it)")
	var seen := {"arc_voidsworn_1A": 2, "arc_voidsworn_1B": 0}
	ctx["seen"] = seen
	ok(str(a.render(1, ctx)["variant"]) == "B", "arc: the less-seen version is picked")
	ctx["prior_loss"] = true
	ok(str(a.render(1, ctx)["b"]).contains("PRIOR-LOSS"), "arc: prior-loss line on beat 1")
	ctx["flags"] = {"fx_keep": 1}
	ctx["first_lost"] = "Oathkeeper"
	var b2: Dictionary = a.render(2, ctx)
	var txt := str(b2["b"])
	ok(txt.contains("KEEP-LINE") and txt.contains("LOST-LINE Oathkeeper") and not txt.contains("SELL-LINE") and not txt.contains("THIRD-COND"), "arc: conditional lines, at most two per card: %s" % txt)
	ok(txt.contains("Rear admiral Petra Lindqvist: \""), "arc: beat 2 carries his line")
	var ks: Array = b2["o"].map(func(o): return o["k"])
	ok(ks == ["x", "blue"] and b2["o"][1].has("need"), "arc: hidden option stays hidden, blue keeps its need %s" % str(ks))
	ctx["flags"] = {"fx_sell": 1, "greed": 2}
	ks = a.render(2, ctx)["o"].map(func(o): return o["k"])
	ok(ks.has("hidden"), "arc: an option shows when its condition holds")
	ctx["nem"] = {"name": "Petra Lindqvist", "title": "Rear admiral", "fac": "hegemony"}
	var b3: Dictionary = a.render(3, ctx)
	ok(str(b3["b"]).contains("You left people behind for a bonus"), "arc: beat 3 hail follows the run's lean (ruthless)")
	ctx["nem"] = {"name": "Grim Rattigan", "title": "Warlord", "fac": "corsair", "beaten": 1}
	ok(str(a.render(3, ctx)["b"]).contains("I had the dents framed"), "arc: beat 3 hail when he remembers you")
	ok(a.ending(true, ctx) == "WIN. WIN-SELL" and a.ending(false, {"flags": {"fx_keep": 1}}) == "LOSS. LOSS-KEEP", "arc: endings follow the choices")
	ctx["arcs_finished"] = 2
	ok(bool(a.render(1, ctx)["skim_first"]), "arc: skim card first after two finished arcs")


# ---------------------------------------------------------------- 6. screens build (headless: layout only)

func t_ui() -> void:
	for p in ["res://ui/career/career_screen.gd", "res://ui/career/rename_dialog.gd", "res://ui/career/crest.gd"]:
		var scr_res = load(p)
		ok(scr_res != null and scr_res.can_instantiate(), "ui: %s compiles" % p)
	var S = StoryScript.new()
	root.add_child(S)
	await process_frame
	S.career.P = Career.default_profile()
	var run := {"t0": 5, "admiral": "aelith", "fac": "ithar", "sector": 3, "flagUid": "u", "fleet": [{"uid": "u", "name": "Glasswing"}]}
	S.career.record_battle(run, _B("boss", true, 0, 5, {"kind": {"sq": 9, "lance": 2}}), "win")
	S.career.record_run_end(run, true, "Aelith Dawnsail")
	S.career.record_arc_end("ithar", "aelith", "Warlord Bones Sharkey", {}, true)
	var scr = S.open_career()
	ok(scr != null, "ui: career screen opens")
	if scr != null:
		var n0 := 0
		for t in ["records", "medals", "titles", "history", "chronicle"]:
			scr.set_tab(t)
			n0 += scr.body.get_child_count()
		ok(n0 > 10, "ui: every career tab builds (%d blocks)" % n0)
	for f in ["voidsworn", "hegemony", "corsair", "chorus", "ithar", "deathless", ""]:
		var c = load("res://ui/career/crest.gd").new()
		c.fac = f
		c.glyph = "V"
		root.add_child(c)
	S.queue_free()


# ---------------------------------------------------------------- 5. attached to a real campaign

func _canon(C) -> String:
	return JSON.stringify([C.RUN, C.META, C.page.get("kind"), C.modal_d.get("kind") if C.modal_d != null else null])


func _play(C, rng: RandomNumberGenerator, max_steps: int) -> int:
	var steps := 0
	while not C.ended and steps < max_steps:
		steps += 1
		var acts: Array = C.screen_acts().filter(func(x): return int(x[2]) == 1 and x[0] not in ["abandonRun", "title", "saveQuit", "legacy", "help", "c3retreat", "progTab", "discardBrokenRun"])
		if acts.is_empty():
			return -steps
		var battle: Array = acts.filter(func(x): return x[0] == "battle")
		var pick: Array
		if not battle.is_empty():
			var r := rng.randi() % 10
			pick = ["battle", "win" if r < 8 else ("partial" if r < 9 else "loss")]
		else:
			var en: Array = acts.filter(func(x): return x[0] == "enterNode")
			pick = en[rng.randi() % en.size()] if (not en.is_empty() and rng.randi() % 3 > 0) else acts[rng.randi() % acts.size()]
		C.act(pick[0], pick[1])
	return steps


func t_campaign(runs: int) -> void:
	var bad := 0
	var recorded_runs := 0
	var same := true
	var battles_seen := 0
	for i in runs:
		var seed := 1000 + i
		var hashes: Array = []
		var S = null
		for with_story in [false, true]:
			var C = CampaignScript.new()
			var err: String = C.load_tables()
			if err != "":
				ok(false, "campaign: tables load (%s)" % err)
				return
			C.fixed_clock = true
			C.META = C.defaultMeta()
			C.META["admirals"] = {}
			for id in C.ADMIRALS:
				C.META["admirals"][id] = true
			var JSM = load("res://rules/jsm.gd")
			JSM.rnd_seed(seed)
			if with_story:
				S = StoryScript.new()
				S.prompt_rename = false
				S.attach(C, false)
			var rng := RandomNumberGenerator.new()
			rng.seed = seed
			C.titleScreen()
			C.act("newRunScreen")
			var steps := _play(C, rng, 3000)
			if steps <= 0 or not C.ended:
				bad += 1
			hashes.append(_canon(C))
			if with_story:
				recorded_runs += int(S.career.P["totals"]["runs"])
				battles_seen += int(S.career.P["totals"]["battles"])
				if int(S.career.P["totals"]["runs"]) != 1 or S.career.P["history"].size() != 1:
					bad += 1
				S.free()
		same = same and hashes[0] == hashes[1]
	ok(bad == 0, "campaign: %d whole runs with the story attached end cleanly and each records one run (%d battles recorded)" % [runs, battles_seen])
	ok(same, "campaign: the campaign's run, profile and screens are identical with and without the story attached")
	ok(battles_seen > 0 and recorded_runs == runs, "campaign: battles and run ends reach the career profile")
