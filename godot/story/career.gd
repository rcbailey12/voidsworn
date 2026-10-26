extends RefCounted
# The career profile (R37 step 1): records per admiral, medals, earned titles and a short run history, kept across runs in
# its own file, user://voidsworn_career.json (plus a .bak one save behind). It is separate from the campaign save on
# purpose: nothing here is read by the campaign or battle rules, so campaign parity and battle parity never see it.
#
# Pure logic, no nodes: story.gd feeds it battles and run ends; tests feed it dictionaries (godot/story/test/).
#
# Battle input (record_battle): the rules' B after a campaign battle (fields the rules already keep: cfg, units with side,
# dead, fled, isSq, flagship, nemFlag, captured; usage with kind, fire, aim, ram, board, cap, ord, ab, cmd), plus the run.
# Run input (record_run_end): the campaign's run dictionary at its end screen (fac, admiral, sector, stats, fleet, flagUid,
# heat, t0) and whether it was a victory.

const SAVE_PATH := "user://voidsworn_career.json"
const VERSION := 1
const HISTORY_MAX := 40

var titles_data: Dictionary = {}
var medals_data: Dictionary = {}
var P: Dictionary = {}          # the profile
var save_path := SAVE_PATH
var persist := false            # write the file on every change (the game); tests and bot runs keep it in memory
var new_medals: Array = []      # medal ids earned since the last take_new_medals() (for a toast)


func _init() -> void:
	titles_data = _json("res://story/data/titles.json")
	medals_data = _json("res://story/data/medals.json")
	P = default_profile()


static func _json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("story: missing " + path)
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


static func default_profile() -> Dictionary:
	return {"v": VERSION, "admirals": {}, "medals": {}, "history": [], "live": {}, "won_facs": [],
		"totals": {"runs": 0, "wins": 0, "battles": 0, "kills": 0, "lost": 0, "captures": 0, "flag_kills": 0}, "chronicle": [],
		"arc_rewards": {}, "paint_on": {}}


# ---------------------------------------------------------------- faction arcs (cosmetic rewards; data/arcs.json)

var arcs_data: Dictionary = {}


func arcs() -> Dictionary:
	if arcs_data.is_empty():
		arcs_data = _json("res://story/data/arcs.json")
	return arcs_data


# Every medal the profile can hold: the base twelve plus one per faction arc.
func all_medals() -> Array:
	var out: Array = medals_data.get("medals", []).duplicate()
	for fac in arcs():
		if arcs()[fac] is Dictionary and arcs()[fac].get("medal") is Dictionary:
			out.append(arcs()[fac]["medal"])
	return out


# A faction arc's ending (beat 3 fought). won: the Nemesis's last fight was won, which finishes the arc and pays its
# rewards: the arc medal, the arc title, the flagship paint (switched on), and the unlock id stream B's rules read.
# choices: {beat: option key}, kept for the Chronicle. Returns the Chronicle row.
func record_arc_end(fac: String, admiral: String, rival: String, choices: Dictionary, won: bool) -> Dictionary:
	var A: Dictionary = arcs().get(fac, {})
	var row := {"t": int(Time.get_unix_time_from_system()), "fac": fac, "arc": str(A.get("arc", fac)), "admiral": admiral, "rival": rival, "choices": choices, "won": won}
	P["chronicle"].append(row)
	if P["chronicle"].size() > 60:
		P["chronicle"] = P["chronicle"].slice(P["chronicle"].size() - 60)
	if won and not A.is_empty():
		award(str(A["medal"]["id"]))
		var first: bool = not P["arc_rewards"].has(fac)
		var who: Array = P["arc_rewards"].get(fac, {}).get("admirals", []).duplicate()
		if admiral != "" and not who.has(admiral):
			who.append(admiral)
		P["arc_rewards"][fac] = {"title": str(A.get("title", "")), "paint": str(A.get("paint", {}).get("id", "")), "unlock": str(A.get("unlock_variant", "")),
			"first": P["arc_rewards"].get(fac, {}).get("first", row["t"]), "count": int(P["arc_rewards"].get(fac, {}).get("count", 0)) + 1, "admirals": who}
		if first:
			P["paint_on"][fac] = true
	save_profile()
	return row


# The flagship paint for a faction: {id, n, hull, trim, glow, pattern} when earned and switched on, else {}.
func flagship_paint(fac: String) -> Dictionary:
	if not P["arc_rewards"].has(fac) or not bool(P["paint_on"].get(fac, false)):
		return {}
	return arcs().get(fac, {}).get("paint", {})


func set_paint(fac: String, on: bool) -> void:
	if P["arc_rewards"].has(fac):
		P["paint_on"][fac] = on
		save_profile()


# Hull variant ids earned by finishing arcs (stream B's rules decide what they do; see godot/story/unlocks.md).
func arc_unlocks() -> Array:
	var out: Array = []
	for fac in P["arc_rewards"]:
		var u := str(P["arc_rewards"][fac].get("unlock", ""))
		if u != "":
			out.append(u)
	return out


# The arc title for a faction; with an admiral id, only when that admiral is the one who finished the arc.
func arc_title(fac: String, admiral: String = "") -> String:
	var rw: Dictionary = P["arc_rewards"].get(fac, {})
	if admiral != "" and not rw.get("admirals", []).has(admiral):
		return ""
	return str(rw.get("title", ""))


# A beat card was shown (variants prefer the version seen less) and a choice made (kept for the Chronicle).
func note_arc_choice(run: Dictionary, beat_id: String, beat_no: int, key: String) -> void:
	if not P.has("arc_seen"):
		P["arc_seen"] = {}
	P["arc_seen"][beat_id] = int(P["arc_seen"].get(beat_id, 0)) + 1
	var L := _live(run)
	if not L.has("arc_choices"):
		L["arc_choices"] = {}
	L["arc_choices"][str(beat_no)] = key
	save_profile()


# How many times an arc of this faction has been played to its end (won or lost).
func arcs_finished(fac: String) -> int:
	return P["chronicle"].filter(func(e): return e is Dictionary and str(e.get("fac", "")) == fac).size()


# The last finished run with this faction: {} or its history row.
func last_run_of(fac: String) -> Dictionary:
	for i in range(P["history"].size() - 1, -1, -1):
		if str(P["history"][i].get("fac", "")) == fac:
			return P["history"][i]
	return {}


# ---------------------------------------------------------------- load and save

func load_profile() -> void:
	P = default_profile()
	for p in [save_path, save_path + ".bak"]:
		if not FileAccess.file_exists(p):
			continue
		var f := FileAccess.open(p, FileAccess.READ)
		if f == null:
			continue
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary and d.get("v") != null:
			P = _migrate(d)
			return


func _migrate(d: Dictionary) -> Dictionary:
	var base := default_profile()
	for k in base.keys():
		if d.get(k) == null or typeof(d[k]) != typeof(base[k]):
			d[k] = base[k]
	for k in base["totals"].keys():
		if not (d["totals"].get(k) is float or d["totals"].get(k) is int):
			d["totals"][k] = 0
	d["v"] = VERSION
	return d


func save_profile() -> void:
	if not persist:
		return
	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save_path), ProjectSettings.globalize_path(save_path + ".bak"))
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(P, " "))


# ---------------------------------------------------------------- the live run

static func run_key(run) -> String:
	if not (run is Dictionary):
		return ""
	return "%s:%s" % [str(run.get("t0", 0)), str(run.get("admiral", ""))]


func _live(run: Dictionary) -> Dictionary:
	var key := run_key(run)
	if str(P["live"].get("key", "")) != key:
		P["live"] = {"key": key, "fac": str(run.get("fac", "")), "admiral": str(run.get("admiral", "")), "sector": int(run.get("sector", 1)),
			"sector_lost": 0, "sector_battles": 0, "battles": 0, "kills": 0, "lost": 0, "unscarred": 0, "captures": 0,
			"kind": {}, "fire": {}, "aim": 0, "ram": 0, "board": 0, "ord": {}, "ab": {}, "cmd": 0}
	return P["live"]


static func _add(d: Dictionary, k: String, n) -> void:
	d[k] = float(d.get(k, 0)) + float(n)


static func _addmap(dst: Dictionary, src) -> void:
	if src is Dictionary:
		for k in src.keys():
			_add(dst, str(k), src[k])


func _adm(id: String) -> Dictionary:
	if not P["admirals"].has(id):
		P["admirals"][id] = {"runs": 0, "wins": 0, "best": 0, "battles": 0, "kills": 0, "lost": 0, "titles": {}, "last_title": "", "flagships": []}
	return P["admirals"][id]


func award(id: String, note: String = "") -> void:
	var m: Dictionary = P["medals"].get(id, {})
	if m.is_empty():
		new_medals.append(id)
		m = {"count": 0, "first": int(Time.get_unix_time_from_system()), "note": note}
	m["count"] = int(m.get("count", 0)) + 1
	P["medals"][id] = m


func take_new_medals() -> Array:
	var out := new_medals.duplicate()
	new_medals.clear()
	return out


# The sector changed: an Unbroken medal when the sector before was cleared without a loss.
func note_sector(run: Dictionary) -> void:
	var L := _live(run)
	var s := int(run.get("sector", 1))
	if s > int(L["sector"]):
		if int(L["sector_lost"]) == 0 and int(L["sector_battles"]) > 0:
			award("unbroken", "sector %d" % int(L["sector"]))
		L["sector"] = s
		L["sector_lost"] = 0
		L["sector_battles"] = 0


# One finished campaign battle. result: "win", "loss" or "retreat".
func record_battle(run: Dictionary, B: Dictionary, result: String) -> Dictionary:
	var L := _live(run)
	note_sector(run)
	var lost := 0
	var kills := 0
	var alive := 0
	var flag_kill := false
	var nem_kill := false
	for u in B.get("units", []):
		if not (u is Dictionary) or _t(u.get("isSq")):
			continue
		var dead := _t(u.get("dead")) and not _t(u.get("fled"))
		if str(u.get("side", "")) == "player":
			if dead and not _t(u.get("captured")):
				lost += 1
				if str(L.get("first_lost", "")) == "" and str(u.get("name", "")) != "":
					L["first_lost"] = str(u["name"])
			elif not dead and not _t(u.get("fled")) and not _t(u.get("captured")):
				alive += 1
		elif dead:
			kills += 1
			if _t(u.get("boss")):
				flag_kill = true
			if _t(u.get("nemFlag")):
				nem_kill = true
	var us: Dictionary = B.get("usage", {}) if B.get("usage") is Dictionary else {}
	_addmap(L["kind"], us.get("kind"))
	_addmap(L["fire"], us.get("fire"))
	_addmap(L["ord"], us.get("ord"))
	_addmap(L["ab"], us.get("ab"))
	for k in ["aim", "ram", "board", "cmd"]:
		_add(L, k, us.get(k, 0) if us.get(k) != null else 0)
	var caps := int(us.get("cap", 0)) if us.get("cap") != null else 0
	_add(L, "captures", caps)
	_add(L, "battles", 1)
	_add(L, "kills", kills)
	_add(L, "lost", lost)
	_add(L, "sector_battles", 1)
	_add(L, "sector_lost", lost)
	if lost == 0:
		_add(L, "unscarred", 1)
	var T: Dictionary = P["totals"]
	_add(T, "battles", 1)
	_add(T, "kills", kills)
	_add(T, "lost", lost)
	_add(T, "captures", caps)
	var A := _adm(str(run.get("admiral", "")))
	_add(A, "battles", 1)
	_add(A, "kills", kills)
	_add(A, "lost", lost)
	var kind := str(B.get("cfg", {}).get("kind", "")) if B.get("cfg") is Dictionary else ""
	if result == "win":
		award("first_blood")
		if kind == "boss" or flag_kill:
			_add(T, "flag_kills", 1)
			award("flag_breaker")
		if int(B.get("round", 99)) <= 3:
			award("lightning")
		if alive == 1:
			award("last_stand")
		if nem_kill and int(run.get("sector", 1)) >= 3:
			award("nemesis_slain")
	if int(L["captures"]) >= 3 and not P["medals"].has("prize_master"):
		award("prize_master")
	if float(T["kills"]) >= 100 and not P["medals"].has("centurion"):
		award("centurion")
	save_profile()
	return {"kills": kills, "lost": lost, "alive": alive, "result": result, "flag_kill": flag_kill, "nem_kill": nem_kill}


static func _t(x) -> bool:
	if x == null:
		return false
	if x is bool:
		return x
	if x is int or x is float:
		return x != 0
	if x is String:
		return x != ""
	return true


# ---------------------------------------------------------------- titles

static func _sum(d) -> float:
	var s := 0.0
	if d is Dictionary:
		for v in d.values():
			s += float(v)
	return s


# The numbers each title rule reads, from a live-run record.
static func title_stats(L: Dictionary) -> Dictionary:
	var kind: Dictionary = L.get("kind", {})
	var fire: Dictionary = L.get("fire", {})
	var tot := _sum(kind)
	var ftot := _sum(fire)
	var b := maxf(1.0, float(L.get("battles", 0)))
	return {
		"ram_board": float(L.get("ram", 0)) + float(L.get("board", 0)),
		"captures": float(L.get("captures", 0)),
		"share_lance": (float(kind.get("lance", 0)) + float(kind.get("gauss", 0))) / tot if tot > 0 else 0.0,
		"share_torp": float(kind.get("torp", 0)) / tot if tot > 0 else 0.0,
		"share_sq": float(kind.get("sq", 0)) / tot if tot > 0 else 0.0,
		"share_battery": float(kind.get("battery", 0)) / tot if tot > 0 else 0.0,
		"share_broad": (float(fire.get("Port broadside", 0)) + float(fire.get("Starboard broadside", 0))) / ftot if ftot > 0 else 0.0,
		"aimed": float(L.get("aim", 0)),
		"braces": float(L.get("ord", {}).get("brace", 0)),
		"unscarred": float(L.get("unscarred", 0)),
		"kills_per_battle": float(L.get("kills", 0)) / b,
		"abilities_per_battle": _sum(L.get("ab", {})) / b,
	}


# The title a live-run record earns: {id, name, rule, score}.
func title_for(L: Dictionary, fac: String) -> Dictionary:
	var fb: Dictionary = titles_data.get("fallback", {})
	var best := {"id": str(fb.get("id", "steadfast")), "name": str(fb.get("n", {}).get(fac, "the Steadfast")), "rule": str(fb.get("rule", "")), "score": 0.0}
	if float(L.get("battles", 0)) < float(titles_data.get("min_battles", 3)):
		return best
	var st := title_stats(L)
	for t in titles_data.get("titles", []):
		var need := float(t.get("need", 1))
		var sc := float(st.get(str(t.get("stat", "")), 0.0)) / need if need > 0 else 0.0
		if sc >= 1.0 and sc > float(best["score"]):
			best = {"id": str(t["id"]), "name": str(t.get("n", {}).get(fac, t["id"])), "rule": str(t.get("rule", "")), "score": sc}
	return best


func title_name(id: String, fac: String) -> String:
	var fb: Dictionary = titles_data.get("fallback", {})
	if id == str(fb.get("id", "")):
		return str(fb.get("n", {}).get(fac, id))
	for t in titles_data.get("titles", []):
		if str(t["id"]) == id:
			return str(t.get("n", {}).get(fac, id))
	return id


# ---------------------------------------------------------------- the end of a run

static func flagship_name(run: Dictionary) -> String:
	var fu = run.get("flagUid")
	for s in run.get("fleet", []):
		if s is Dictionary and fu != null and str(s.get("uid", "")) == str(fu):
			return str(s.get("name", ""))
	return ""


# Called once per run, at its end screen. Returns the summary row it added to the history.
func record_run_end(run: Dictionary, victory: bool, admiral_name: String = "") -> Dictionary:
	var L := _live(run)
	if bool(L.get("ended", false)):
		return P["history"][P["history"].size() - 1] if P["history"].size() > 0 else {}
	var fac := str(run.get("fac", ""))
	var adm_id := str(run.get("admiral", ""))
	if victory:
		# the last sector counts for Unbroken too
		if int(L["sector_lost"]) == 0 and int(L["sector_battles"]) > 0:
			award("unbroken", "sector %d" % int(L["sector"]))
	var title := title_for(L, fac)
	var A := _adm(adm_id)
	_add(A, "runs", 1)
	A["best"] = maxi(int(A.get("best", 0)), int(run.get("sector", 1)))
	A["titles"][title["id"]] = int(A["titles"].get(title["id"], 0)) + 1
	A["last_title"] = title["id"]
	var fname := flagship_name(run)
	if fname != "" and not A["flagships"].has(fname):
		A["flagships"].append(fname)
		if A["flagships"].size() > 12:
			A["flagships"] = A["flagships"].slice(A["flagships"].size() - 12)
	var T: Dictionary = P["totals"]
	_add(T, "runs", 1)
	if victory:
		_add(A, "wins", 1)
		_add(T, "wins", 1)
		award("victor")
		var heat = run.get("heat", [])
		if heat is Array and heat.size() > 0:
			award("heat_victor")
		if fac != "" and not P["won_facs"].has(fac):
			P["won_facs"].append(fac)
		if P["won_facs"].size() >= 6 and not P["medals"].has("six_banners"):
			award("six_banners")
	if float(T["runs"]) >= 10 and not P["medals"].has("long_service"):
		award("long_service")
	var mins := 0
	if float(run.get("t0", 0)) > 0:
		mins = maxi(1, int(round((Time.get_unix_time_from_system() * 1000.0 - float(run["t0"])) / 60000.0)))
	var row := {"t": int(Time.get_unix_time_from_system()), "admiral": adm_id, "admiral_name": admiral_name, "fac": fac, "victory": victory,
		"sector": int(run.get("sector", 1)), "battles": int(L["battles"]), "kills": int(L["kills"]), "lost": int(L["lost"]),
		"captures": int(L["captures"]), "title": title["id"], "title_name": title["name"], "flagship": fname, "mins": mins}
	P["history"].append(row)
	if P["history"].size() > HISTORY_MAX:
		P["history"] = P["history"].slice(P["history"].size() - HISTORY_MAX)
	L["ended"] = true
	save_profile()
	return row
