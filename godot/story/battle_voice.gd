extends RefCounted
# Admiral, enemy flagship, Nemesis, and situational combat lines (R37 + reactive variety upgrade).
# Presentation only: reads rules view() and event stream, never modifies rules state, never touches rules PRNG.

const Tokens := preload("res://story/tokens.gd")
const RivalScript := preload("res://story/rival.gd")

# Run-scoped anti-repeat memory across battles in the same run (keyed by run_key -> pool_id -> Array[int]).
static var _run_memory := {}

var V: Dictionary = {}          # voices.json
var S: Dictionary = {}          # situations.json (optional; graceful fallback if absent)
var rival = RivalScript.new()

var info := {}                  # admiral, admiral_name, fac, enemy_fac, enemy_name, kind, obj, shape, cond, sector, seed, run_key, nem, flagship_name
var units := {}                 # id -> {side, flagship, squadron, nemesis, hp, maxHp, name}
var said := {}                  # moment -> true (each big moment speaks once per battle)
var flag_id := ""               # player's flagship unit id
var player_start_ships := 0     # non-squadron player hulls at battle start
var player_lost_ships := 0      # non-squadron player hulls destroyed this battle
var rounds_seen := 1            # updated from "round" events
var sit_spoken := 0             # throttle mid-battle situational reactions (max 2 per battle)
var _mem_override = null        # optional persistent Dictionary (e.g. career.P["live"]["spoken"])


func _init() -> void:
	V = _load_json("res://story/data/voices.json")
	S = _load_json("res://story/data/situations.json")


static func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


# Optional hook for story.gd to bind persistent run memory across save/quit/resume.
func bind_memory(mem: Dictionary) -> void:
	_mem_override = mem


static func _h(s: String) -> int:
	var h := 2166136261
	for i in s.length():
		h = ((h ^ s.unicode_at(i)) * 16777619) & 0x7fffffff
	h ^= h >> 13
	h = (h * 0x5bd1e995) & 0x7fffffff
	h ^= h >> 15
	return h


func _spoken_bag() -> Dictionary:
	if _mem_override is Dictionary:
		return _mem_override
	var rk := str(info.get("run_key", ""))
	if rk == "":
		return {}
	if not _run_memory.has(rk):
		if _run_memory.size() > 8:
			_run_memory.clear()
		_run_memory[rk] = {}
	return _run_memory[rk]


# Picks from a String or Array[String]. When a run_key (or bound memory) is active, uses a deterministic
# anti-repeat shuffle bag so every line in a pool plays once before any index repeats.
func _pick_from(pool, pool_id: String, extra_salt: String = "") -> String:
	if pool is String:
		return pool
	if not (pool is Array) or pool.is_empty():
		return ""
	var n := pool.size()
	var seed_val := int(info.get("seed", 0))
	var rk := str(info.get("run_key", ""))
	var bag := _spoken_bag()
	if rk == "" and _mem_override == null:
		return str(pool[_h("%s|%s|%d" % [pool_id, extra_salt, seed_val]) % n])
	var used: Array = bag.get(pool_id, [])
	if used.size() >= n:
		used = []
	var avail: Array = []
	for i in n:
		if not used.has(i):
			avail.append(i)
	if avail.is_empty():
		avail = range(n)
		used = []
	var pick_idx: int = avail[_h("%s|%s|%s|%d|%d" % [rk, pool_id, extra_salt, seed_val, used.size()]) % avail.size()]
	used.append(pick_idx)
	bag[pool_id] = used
	return str(pool[pick_idx])


func _has_unseen(pool, pool_id: String) -> bool:
	if not (pool is Array) or pool.is_empty():
		return false
	var bag := _spoken_bag()
	if bag.is_empty():
		return true
	var used: Array = bag.get(pool_id, [])
	return used.size() < pool.size()


# Reads what it needs from the rules object (godot/rules/rules.gd) without changing it.
func setup_from_rules(R, view: Dictionary) -> void:
	var run = R.RUN if "RUN" in R else null
	var B = R.B if "B" in R else null
	var cfg: Dictionary = B.get("cfg", {}) if B is Dictionary and B.get("cfg") is Dictionary else {}
	var nem = B.get("nem") if B is Dictionary else null
	var adm := str(run.get("admiral", "")) if run is Dictionary else ""
	var ADM = R.ADMIRALS if "ADMIRALS" in R else {}
	var FAC = R.FACTIONS if "FACTIONS" in R else {}
	var obj_dict = B.get("obj") if B is Dictionary else null
	var obj_type := str(obj_dict.get("type", "")) if obj_dict is Dictionary else str(cfg.get("obj", "rout"))
	if obj_type == "":
		obj_type = str(cfg.get("obj", "rout"))
	var shape := str(B.get("shape", cfg.get("shape", "open"))) if B is Dictionary else str(cfg.get("shape", "open"))
	var cond := ""
	if run is Dictionary and run.get("map") is Dictionary:
		cond = str(run["map"].get("cond", ""))
	var rk := ""
	if run is Dictionary:
		rk = "%s:%s" % [str(run.get("t0", 0)), adm]
	setup(view, {
		"admiral": adm,
		"admiral_name": str(ADM.get(adm, {}).get("n", adm)) if ADM is Dictionary else adm,
		"enemy_name": str(FAC.get(str(cfg.get("fac", "")), {}).get("n", "the enemy")) if FAC is Dictionary else "the enemy",
		"fac": str(run.get("fac", "")) if run is Dictionary else "",
		"sector": int(run.get("sector", 1)) if run is Dictionary else 1,
		"kind": str(cfg.get("kind", "")),
		"obj": obj_type,
		"shape": shape,
		"cond": cond,
		"enemy_fac": str(cfg.get("fac", "")),
		"seed": int(B.get("seed", cfg.get("seed", 0))) if B is Dictionary and (B.get("seed") != null or cfg.get("seed") != null) else 0,
		"run_key": rk,
		"nem": nem if nem is Dictionary else null,
		"flagship_name": "",
	})


func setup(view: Dictionary, inf: Dictionary) -> void:
	info = inf
	units.clear()
	said.clear()
	flag_id = ""
	player_start_ships = 0
	player_lost_ships = 0
	rounds_seen = 1
	sit_spoken = 0
	for u in view.get("units", []):
		var id := str(u["id"])
		var side := str(u.get("side", ""))
		var is_sq := bool(u.get("squadron", false))
		var is_flag := bool(u.get("flagship", false))
		units[id] = {
			"side": side,
			"flagship": is_flag,
			"squadron": is_sq,
			"nemesis": bool(u.get("nemesis", false)),
			"hp": float(u.get("hp", 0)),
			"maxHp": maxf(1.0, float(u.get("maxHp", 1))),
			"name": str(u.get("name", "")),
		}
		if side == "player" and not is_sq:
			player_start_ships += 1
		if side == "player" and is_flag and flag_id == "":
			flag_id = id
			if str(info.get("flagship_name", "")) == "":
				info["flagship_name"] = str(u.get("name", ""))


# ---------------------------------------------------------------- lines

func admiral_name() -> String:
	var a: String = str(info.get("admiral", ""))
	return str(info.get("admiral_name", a))


func _fill(t: String) -> String:
	var nem = info.get("nem")
	var rival_name := Tokens.full_name(nem) if nem is Dictionary else ""
	var flag_name := str(info.get("flagship_name", "the flagship"))
	var out := t.replace("{flagship}", flag_name).replace("{rival}", rival_name if rival_name != "" else "the enemy commander").replace("{enemy}", str(info.get("enemy_name", "the enemy")))
	if flag_name.begins_with("The ") or flag_name.begins_with("MDV "):
		out = out.replace("the " + flag_name, flag_name).replace("The " + flag_name, flag_name)
	return out


func adm_text(moment: String) -> String:
	var adm := str(info.get("admiral", ""))
	var A: Dictionary = V.get("admirals", {}).get(adm, {})
	var t = A.get(moment)
	if t == null:
		return ""
	var picked := _pick_from(t, "adm:%s:%s" % [adm, moment], moment)
	return _fill(picked) if picked != "" else ""


func sit_text(cat: String, key: String) -> String:
	var fac := str(info.get("fac", ""))
	if fac == "" or key == "" or S.is_empty():
		return ""
	var pool = S.get(cat, {}).get(fac, {}).get(key)
	if pool == null:
		return ""
	var picked := _pick_from(pool, "sit:%s:%s:%s" % [cat, fac, key], key)
	return _fill(picked) if picked != "" else ""


func _adm_line(moment: String) -> Array:
	var t := adm_text(moment)
	if t == "":
		return []
	return [{"text": "%s: \"%s\"" % [admiral_name(), t], "kind": "s", "who": "admiral", "moment": moment}]


func _sit_line(cat: String, key: String, moment: String) -> Array:
	var t := sit_text(cat, key)
	if t == "":
		return []
	return [{"text": "%s: \"%s\"" % [admiral_name(), t], "kind": "s", "who": "admiral", "moment": moment}]


func _enemy_line(who: String, moment: String, text: String) -> Array:
	if text == "":
		return []
	return [{"text": "%s: \"%s\"" % [who, _fill(text)], "kind": "e", "who": "enemy", "moment": moment}]


func _boss_text(key: String) -> String:
	var efac := str(info.get("enemy_fac", ""))
	var fd: Dictionary = V.get("factions", {}).get(efac, {})
	var pool = fd.get(key + "_pool", null)
	if pool is Array and not pool.is_empty():
		return _pick_from(pool, "boss:%s:%s" % [efac, key], key)
	return str(fd.get(key, ""))


func _ctx() -> Dictionary:
	return {
		"you": admiral_name(),
		"flagship": str(info.get("flagship_name", "your flagship")),
		"player_fac": str(info.get("fac", "")),
	}


func _nem_text(k: String) -> String:
	var nem = info.get("nem")
	if not (nem is Dictionary):
		return ""
	var bag = _spoken_bag() if (str(info.get("run_key", "")) != "" or _mem_override != null) else null
	if k == "open":
		return rival.opening(nem, int(info.get("sector", 1)), int(info.get("seed", 0)), _ctx(), bag)
	return rival.line(k, nem, int(info.get("seed", 0)), _ctx(), bag)


func _nem_name() -> String:
	return Tokens.full_name(info.get("nem"))


func _boss_name() -> String:
	for id in units:
		if units[id]["side"] == "enemy" and units[id]["flagship"]:
			return str(units[id]["name"])
	return "The enemy flagship"


# ---------------------------------------------------------------- opening

func opening() -> Array:
	var out: Array = []
	if info.get("nem") is Dictionary:
		out += _enemy_line(_nem_name(), "nem_hail", _nem_text("open"))
		out += _adm_line("nemesis")
	elif str(info.get("kind", "")) == "boss":
		out += _enemy_line(_boss_name(), "boss_hail", _boss_text("boss_hail"))
		out += _adm_line("boss")
	else:
		var open_lines := _situational_opening()
		out += open_lines if not open_lines.is_empty() else _adm_line("start")
	return out


func _situational_opening() -> Array:
	var fac := str(info.get("fac", ""))
	if fac == "" or S.is_empty():
		return []
	var shape := str(info.get("shape", "open"))
	var obj := str(info.get("obj", "rout"))
	var efac := str(info.get("enemy_fac", ""))
	var seed_val := int(info.get("seed", 0))
	# 1. Hollow Sun gravity well: always comment the first time we enter a deadstar arena this run
	if shape == "deadstar" and _has_unseen(S.get("events", {}).get(fac, {}).get("deadstar"), "sit:events:%s:deadstar" % fac):
		return _sit_line("events", "deadstar", "start")
	# 2. Special objective (non-rout): prioritize objective briefing while variants remain unseen
	if obj != "" and obj != "rout":
		var obj_pool = S.get("by_objective", {}).get(fac, {}).get(obj)
		if obj_pool != null and (_has_unseen(obj_pool, "sit:by_objective:%s:%s" % [fac, obj]) or _h("obj|%d" % seed_val) % 3 != 0):
			return _sit_line("by_objective", obj, "start")
	# 3. Faction matchup: favor rivalry line on first contact with a faction, then blend 50/50 with admiral's start pool
	if efac != "":
		var ef_pool = S.get("by_enemy", {}).get(fac, {}).get(efac)
		var ef_id := "sit:by_enemy:%s:%s" % [fac, efac]
		var bag := _spoken_bag()
		var first_vs: bool = bag.get(ef_id, []).is_empty()
		if ef_pool != null and (first_vs or (_has_unseen(ef_pool, ef_id) and _h("vs|%s|%d" % [efac, seed_val]) % 2 == 0)):
			return _sit_line("by_enemy", efac, "start")
	return []


# ---------------------------------------------------------------- live event stream

func _try_sit_event(key: String) -> Array:
	if sit_spoken >= 2 or said.has("sit_" + key):
		return []
	var lines := _sit_line("events", key, "sit_" + key)
	if not lines.is_empty():
		said["sit_" + key] = true
		sit_spoken += 1
	return lines


func _nem_down_key() -> String:
	var nem = info.get("nem")
	var nfac := str(nem.get("fac", "")) if nem is Dictionary else ""
	var sec := int(info.get("sector", 1))
	if nfac == "deathless" and sec >= 3 and not bool(nem.get("revived", false)):
		return "beaten"
	if nfac == "voidsworn":
		return "death"
	return "death" if sec >= 3 else "beaten"


func on_event(e: Dictionary) -> Array:
	var out: Array = []
	match str(e.get("t", "")):
		"round":
			rounds_seen = maxi(rounds_seen, int(e.get("round", rounds_seen)))
		"tick":
			var tid := str(e.get("unit", ""))
			if units.has(tid):
				units[tid]["hp"] = maxf(0.0, float(units[tid]["hp"]) - float(e.get("hull", 0)))
		"hit":
			var id := str(e.get("target", ""))
			if units.has(id):
				units[id]["hp"] = float(units[id]["hp"]) - float(e.get("hull", 0))
				if id == flag_id and not said.has("flag_hurt") and float(units[id]["hp"]) > 0 and float(units[id]["hp"]) < 0.4 * float(units[id]["maxHp"]):
					said["flag_hurt"] = true
					out += _adm_line("flag_hurt")
		"ram":
			var aid := str(e.get("unit", ""))
			var tid := str(e.get("target", ""))
			var dmg := float(e.get("dmg", 0))
			if units.has(aid) and units.has(tid):
				units[tid]["hp"] = float(units[tid]["hp"]) - dmg
				if units[aid]["side"] == "player" and units[tid]["side"] == "enemy" and not bool(units[tid].get("squadron", false)) and float(units[tid]["hp"]) <= 0:
					out += _try_sit_event("ram_kill")
		"death":
			var id := str(e.get("unit", ""))
			var u: Dictionary = units.get(id, {})
			if u.is_empty() or bool(u.get("squadron", false)):
				return out
			u["hp"] = 0.0
			if u["side"] == "enemy" and (bool(u.get("nemesis", false)) and info.get("nem") is Dictionary):
				if not said.has("nem_down"):
					said["nem_down"] = true
					out += _enemy_line(_nem_name(), "nem_down", _nem_text(_nem_down_key()))
					out += _adm_line("kill_flag")
			elif u["side"] == "enemy" and bool(u.get("flagship", false)):
				if not said.has("flag_down"):
					said["flag_down"] = true
					out += _enemy_line(str(u["name"]), "boss_down", _boss_text("boss_down"))
					out += _adm_line("kill_flag")
			elif u["side"] == "player":
				player_lost_ships += 1
				if not said.has("lost"):
					said["lost"] = true
					if info.get("nem") is Dictionary:
						out += _enemy_line(_nem_name(), "nem_kill", _nem_text("kill"))
					out += _adm_line("lost")
		"nem_signature", "nem_act":
			if info.get("nem") is Dictionary and not said.has("nem_signature"):
				said["nem_signature"] = true
				out += _enemy_line(_nem_name(), "nem_signature", _nem_text("signature"))
		"command":
			if str(e.get("side", "")) == "player" and not said.has("command"):
				said["command"] = true
				out += _adm_line("command")
		"command_warning":
			if str(e.get("side", "")) == "enemy":
				out += _try_sit_event("enemy_cmd_warn")
		"risen":
			var rid := str(e.get("unit", ""))
			if units.has(rid) and units[rid]["side"] == "enemy":
				units[rid]["hp"] = float(units[rid]["maxHp"]) * 0.5
				out += _try_sit_event("enemy_risen")
		"fled":
			var fid := str(e.get("unit", ""))
			if units.has(fid) and units[fid]["side"] == "enemy" and not bool(units[fid].get("squadron", false)):
				units[fid]["hp"] = 0.0
				out += _try_sit_event("enemy_flee")
		"board":
			if str(e.get("result", "")) == "capture":
				var t := str(e.get("target", ""))
				var a := str(e.get("unit", ""))
				if units.has(t) and units.has(a):
					var new_side: String = units[a]["side"]
					units[t]["side"] = new_side
					if new_side == "player":
						out += _try_sit_event("capture")
		"log":
			var txt := str(e.get("text", ""))
			if txt.begins_with("Solar flare!"):
				out += _try_sit_event("flare")
			elif txt.begins_with("Enemy reinforcements jump in"):
				out += _try_sit_event("reinf_enemy")
			elif txt.begins_with("A friendly ship jumps in"):
				out += _try_sit_event("reinf_ally")
	return out


# ---------------------------------------------------------------- closing

func _player_alive_count() -> int:
	var n := 0
	for id in units:
		var u: Dictionary = units[id]
		if u["side"] == "player" and not bool(u.get("squadron", false)) and float(u["hp"]) > 0.0:
			n += 1
	return n


func _flag_hp_ratio() -> float:
	if flag_id == "" or not units.has(flag_id):
		return 1.0
	return float(units[flag_id]["hp"]) / maxf(1.0, float(units[flag_id]["maxHp"]))


func closing(win: bool) -> String:
	if not win and info.get("nem") is Dictionary:
		var g := _nem_text("gloat")
		if g != "":
			return "%s: \"%s\"" % [_nem_name(), g]
	if win and str(info.get("run_key", "")) != "" and not S.is_empty():
		var alive_n := _player_alive_count()
		var outcome_key := ""
		if player_start_ships >= 2 and alive_n == 1:
			outcome_key = "win_last_stand"
		elif player_lost_ships >= 2 or _flag_hp_ratio() < 0.35:
			outcome_key = "win_bloody"
		elif rounds_seen <= 3:
			outcome_key = "win_fast"
		elif player_lost_ships == 0:
			outcome_key = "win_clean"
		if outcome_key != "":
			# Dramatic outcomes always speak; clean wins alternate 50/50 with the admiral's personal win pool
			var use_outcome := outcome_key != "win_clean" or _h("close|%d" % int(info.get("seed", 0))) % 2 == 0
			if use_outcome:
				var st := sit_text("outcome", outcome_key)
				if st != "":
					return "%s: \"%s\"" % [admiral_name(), st]
	var t := adm_text("win" if win else "loss")
	return "%s: \"%s\"" % [admiral_name(), t] if t != "" else ""
