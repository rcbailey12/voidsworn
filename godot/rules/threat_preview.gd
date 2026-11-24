extends RefCounted
## Issue 1859: conditional first weapon targets from the committed battle state.
## view supplies B, run, meta, decoded tables, board_size, cut, solid, level and phase.
## For an enemy step it also supplies the remaining Alternating queue or the Classic
## order, cursor and done list (unit IDs). During the player phase, the order assumes
## the player ends the current activation or turns over the Classic turn now.
## tie_order lists unit IDs, normally in B.units order. Unlisted IDs keep board order.
## Returns an ordered Dictionary of enemy IDs to lists of {id, reason, likelihood}.
## The next enemy batch comes first. Likelihood is an ordinal rank for this position.
## The forecast uses current readiness and projects movement, before actions such
## as round-start effects, abilities, boarding, interception or later shots.

const Rules := preload("res://rules/rules.gd")


static func score(view: Dictionary, current_focus_id: String, tie_order: Array) -> Dictionary:
	if view.get("B") == null or Rules.jt(view["B"].get("over")) or view["phase"] not in ["player", "enemy"]:
		return {}
	return ScoringRead.new(view, current_focus_id, tie_order).targets()


# Reuse damage, arc and movement math on a private receiver. Its input dictionaries
# are borrowed read-only. Even helpers with memoization only write to this receiver.
class ScoringRead extends Rules:
	const TABLE_NAMES := [
		"DIRS", "BLOCKING", "MOVE_BASE", "MOVE_RULES", "SEC_OF_QUAD",
		"CMD_POW", "BOSS_CMD", "FACTION_AI", "RELICS", "LINEAGE_TREES", "TREE_FX",
		"RAM_FAC", "WELL_RIM", "WELL_PULL", "ENC_ROUNDS",
	]

	var view: Dictionary
	var listed: Dictionary = {}
	var units: Dictionary = {}
	var foes: Array = []
	var enemies: Array = []
	var focus: Variant
	var vet: bool

	func _init(input: Dictionary, focus_id: String, tie_order: Array) -> void:
		view = input
		B = view["B"]
		RUN = view["run"]
		META = view["meta"]
		TB = view["tables"]
		for name in TABLE_NAMES:
			set(name, TB[name])
		BW = view["board_size"].x
		BH = view["board_size"].y
		CUT = view["cut"]
		SOLID = view["solid"]
		vet = view["level"] == "veteran"
		for i in range(tie_order.size()):
			if not listed.has(tie_order[i]):
				listed[tie_order[i]] = i
		for u in B["units"]:
			var id: String = u["id"]
			units[id] = u
			if not listed.has(id):
				listed[id] = tie_order.size() + units.size()
		foes = alive("player")
		enemies = alive("enemy")
		foes.sort_custom(_tie_before)
		if vet:
			focus = units.get(focus_id)
			if focus != null and (focus["side"] != "player" or jt(focus.get("dead")) or jt(focus.get("treeOff"))):
				focus = null

	func _tie_before(a: Dictionary, b: Dictionary) -> bool:
		return listed[a["id"]] < listed[b["id"]]

	func targets() -> Dictionary:
		var result := {}
		var next := _activation_order()
		var hull_focus = _refreshed_focus()
		for id in next:
			result[id] = _unit_targets(units[id], hull_focus)
		for u in enemies:
			var id: String = u["id"]
			if result.has(id):
				continue
			var spent: bool = jt(u.get("activated")) if jt(B.get("alt")) else id in view.get("classic_done", [])
			if view["phase"] == "enemy" and not jt(B.get("alt")) and jt(u.get("isSq")):
				spent = id not in view.get("classic_order", []).slice(int(view.get("classic_index", 0)))
			result[id] = [] if spent else _unit_targets(u, hull_focus)
		return result

	# battle_api._ai_step_begin and _c_step. The live Alternating batch has
	# already chosen its hull. Classic chooses again after every activation.
	func _activation_order() -> Array:
		if view["phase"] == "enemy":
			if jt(B.get("alt")):
				return view["queue"]
			var order: Array = view["classic_order"]
			var done: Array = view["classic_done"]
			var pending: Array = []
			for i in range(int(view["classic_index"]), order.size()):
				var unit: Dictionary = units[order[i]]
				if not jt(unit.get("dead")) and jt(unit.get("isSq")):
					pending.append(unit["id"])
			var hulls: Array = []
			for id in order:
				var unit: Dictionary = units[id]
				if id not in done and not jt(unit.get("dead")) and not jt(unit.get("isSq")):
					hulls.append(unit)
			if not hulls.is_empty():
				pending.append(_pick_hull(hulls)["id"])
			return pending
		var wings: Array = []
		var hulls: Array = []
		var alternating := jt(B.get("alt"))
		for u in enemies:
			if alternating and jt(u.get("activated")):
				continue
			if jt(u.get("isSq")):
				wings.append(u)
			else:
				hulls.append(u)
		if alternating and hulls.is_empty():
			return []
		var unacted := 0
		for t in foes:
			if not jt(t.get("isSq")) and not jt(t.get("activated")):
				unacted += 1
		if alternating and unacted <= 1:
			return _ids(wings + hulls)
		hulls.sort_custom(_speed_before)
		if not alternating:
			wings.sort_custom(_speed_before)
		elif vet and hulls.size() > 1:
			# The selection refresh is visible to the wings before the hull acts.
			focus = _refreshed_focus()
		if not hulls.is_empty():
			wings.append(_pick_hull(hulls))
		return _ids(wings)

	func _speed_before(a: Dictionary, b: Dictionary) -> bool:
		return a["speed"] > b["speed"] if a["speed"] != b["speed"] else _tie_before(a, b)

	func _ids(group: Array) -> Array:
		var ids: Array = []
		for u in group:
			ids.append(u["id"])
		return ids

	# rules.aiRefreshFocus, aiFocusVal and aiPickActivation. Refresh returns a
	# local candidate, so the live focus can keep its identity and hysteresis.
	func _refreshed_focus() -> Variant:
		if not vet:
			return null
		var shooters: Array = []
		for u in enemies:
			if not jt(u.get("isSq")) and not jt(u.get("transport")) and not u["weapons"].is_empty():
				shooters.append(u)
		var best = focus
		var value := _focus_value(focus, shooters) * 1.25
		for t in foes:
			if jt(t.get("isSq")) or is_same(t, focus):
				continue
			var candidate := _focus_value(t, shooters)
			if candidate > value:
				value = candidate
				best = t
		return best

	func _focus_value(t, shooters: Array) -> float:
		if t == null or jt(t.get("isSq")):
			return 0.0
		var take: float = max(0.15, braceMul(t) * guardMul(t) * cmdTaken(t))
		var effective_hp: float = t["hp"] / take + float(z0(t.get("shp"))) * 0.3
		var count := 0
		for u in shooters:
			var reach := 0.0
			for w in u["weapons"]:
				if le(w.get("cdLeft"), 1) and le(w.get("off"), 1) and w["k"] != "flak":
					reach = maxf(reach, float(w["r"]))
			if reach > 0.0 and hdist(u, t) <= reach + _speed(u):
				count += 1
		var cp: float = float(t["t"]["cp"]) if jt(t["t"].get("cp")) else 1.0
		var flag_bonus := 20.0 if jt(t.get("flagship")) or jt(t.get("pflag")) else 0.0
		return (cp * 12.0 + flag_bonus) / maxf(20.0, effective_hp) * (1.0 if count >= 2 else (0.8 if count == 1 else 0.4))

	func _speed(u: Dictionary) -> float:
		return float(u["speed"]) if jt(u.get("speed")) else 2.0

	func _pick_hull(hulls: Array) -> Dictionary:
		if not vet or hulls.size() == 1:
			return hulls[0]
		var best: Dictionary = hulls[0]
		var value := -INF
		var aim = _refreshed_focus()
		for u in hulls:
			var ready := readyList(u)
			var offense := 0.0
			for facing in range(6):
				var pose := dup(u)
				pose["facing"] = facing
				offense = maxf(offense, _offense(pose, ready, aim))
			var reach := 0.0
			for t in foes:
				for w in ready:
					if w["k"] != "flak" and hdist(u, t) <= w["r"] + _speed(u):
						reach = maxf(reach, w["dmg"] * w["shots"] * (1.3 if is_same(t, aim) else 1.0))
			var candidate := offense + reach * 0.5 + _incoming(u, false) * 0.25
			if u["hp"] < u["maxHp"] * 0.3:
				candidate += 10.0
			if candidate > value:
				value = candidate
				best = u
		return best

	func _offense(u: Dictionary, ready: Array, aim) -> float:
		var total := 0.0
		for w in ready:
			if w["k"] == "flak":
				continue
			var best := 0.0
			for t in foes:
				if not inReach(u, w, t):
					continue
				var e := _expectedVs_raw(u, w, t)
				var value := float(e.hull + e.shield * 0.3)
				if e.hull >= t["hp"]:
					value += 15.0 + t["maxHp"] * 0.1
				if jt(t.get("isSq")) and not jt(w.get("vsSq")):
					value *= 0.5
				if vet:
					if is_same(t, aim):
						value *= 1.3
					if e.rear:
						value *= 1.1
				best = maxf(best, value)
			total += best
		return total

	func _incoming(u: Dictionary, reach_ahead: bool) -> float:
		var total := 0.0
		for p in foes:
			var distance := hdist(p, u)
			if distance > (13 if reach_ahead else 9):
				continue
			if jt(B.get("alt")) and (jt(p.get("activated")) or jt(p.get("braced"))):
				continue
			for w in p["weapons"]:
				if w["k"] == "flak" or gt(w.get("cdLeft"), 1) or gt(w.get("off"), 1):
					continue
				if jt(B.get("alt")) and (jt(w.get("fired")) or gt(w.get("cdLeft"), 0)):
					continue
				var arc := inArc(p, u, w["arc"]) or (reach_ahead and chaserArc(p, w, u))
				var weight := 1.0
				if not arc or distance > w["r"]:
					if not reach_ahead or distance > w["r"] + maxf(1.0, _speed(p) - 1.0):
						continue
					if (not arc and not _turn_reaches(p, u, w)) or not los(p, u):
						continue
					weight = 0.8
				var e := _expectedVs_raw(p, w, u)
				total += (e.hull + e.shield * 0.2) * weight
		if not jt(u.get("isSq")) and float(z0(u.get("shMax"))) > 0.0 and terr(u["q"], u["r"]) == "storm":
			total += minf(10.0, float(z0(u.get("shp")))) * 0.2
		return total

	func _turn_reaches(p: Dictionary, u: Dictionary, w: Dictionary) -> bool:
		if not gt(p.get("turns"), 0):
			return false
		var pose := dup(p)
		for offset in [1, 5]:
			pose["facing"] = (int(p["facing"]) + offset) % 6
			if inArc(pose, u, w["arc"]):
				return true
		return false

	func _unit_targets(u: Dictionary, hull_focus) -> Array:
		if jt(u.get("dead")) or jt(u.get("treeOff")) or jt(u.get("braced")) or foes.is_empty():
			return []
		var ready: Array = readyList(u).filter(func(w): return w["k"] != "flak")
		if ready.is_empty():
			return []
		if jt(u.get("isSq")):
			return _wing_targets(u, ready)
		return _volley_targets(_firing_pose(u, ready, hull_focus), ready, hull_focus)

	# Mirror aiUnit's pose comparisons without running any of its actions.
	func _firing_pose(u: Dictionary, ready: Array, aim) -> Dictionary:
		var prof: Dictionary = nemProf(u, FACTION_AI.get(u["fac"], FACTION_AI["voidsworn"]))
		var hp_fraction: float = u["hp"] / maxf(1.0, u["maxHp"])
		var hurt := hp_fraction < 0.3 or (hp_fraction <= 0.45 and jt(u.get("aiHurt")))
		var k := 1.0 if hurt else clampf((0.6 - hp_fraction) / 0.3, 0.0, 1.0)
		var weight: float = (0.65 if vet and jt(u.get("flagship")) else lerpf(0.32, 0.6 * prof["hurt"], k * k * (3.0 - 2.0 * k))) * prof["tw"]
		var cliff := 25.0 + 3.0 * (clampf(float(z0(u["t"].get("cp"))), 1.0, 7.0) - 3.0)
		var hulls := foes.filter(func(t): return not jt(t.get("isSq")))
		var field := pathField(hulls)
		var min_range := INF
		for w in ready:
			min_range = minf(min_range, w["opt"])
		var objective = B.get("obj")
		if vet and objective != null and objective["type"] == "break" and objective.get("c0") == null:
			objective = objective.duplicate()
			objective["c0"] = boardBounds()["c0"]
		var escorts: Array = []
		var flag: Variant = null
		if vet and objective != null and objective["type"] == "flagship" and not jt(u.get("flagship")):
			for ally in enemies:
				if jt(ally.get("flagship")):
					flag = ally
					break
			if flag != null:
				for ally in enemies:
					if not is_same(ally, u) and not is_same(ally, flag) and not jt(ally.get("isSq")) and not jt(ally.get("transport")):
						escorts.append(ally)
		var close_escorts := 0
		for ally in escorts:
			if hdist(ally, flag) <= 3:
				close_escorts += 1
		var best := u
		var value := -INF
		for state in computeReach(u, true)["states"]:
			var pose := stateView(u, state)
			var offense := _offense(pose, ready, aim)
			var threat := _incoming(pose, vet)
			var candidate := offense - threat * weight
			if vet and threat >= u["hp"]:
				candidate -= cliff
			var distance := _mind(pose, hulls, 99)
			if jt(prof.get("range")):
				var preferred: float = prof["range"]
				candidate -= maxf(0.0, preferred - distance if preferred > 0.0 else distance + preferred) * prof["rw"]
			if jt(RAM_FAC.get(u["fac"])) and canFade(u):
				var fade: float = float(z0(g(u.get("fx"), "fade")))
				var left: float = floor((u["mp"] - state["cost"]) * (fade if fade > 0.0 else 0.5))
				candidate += ramSetup(pose, u, minf(left, _speed(u) - z0(u["st"].get("engine")))) * prof["rs"]
			if jt(prof.get("rear")):
				candidate += _rear_opportunity(pose, ready, hulls) * prof["rear"]
			if flag != null:
				var d := hdist(pose, flag)
				candidate -= maxf(0.0, d - 3.0) * (0.6 if close_escorts >= 2 else 2.0)
				if d <= 3:
					for ally in escorts:
						if hdist(ally, pose) == 1:
							candidate -= 1.0
			if offense <= 0.0 and not is_same(u, B.get("mapTrialQuarry")):
				candidate -= maxf(0.0, fieldDist(field, pose, distance) - min_range) * 4.0
			candidate -= state["cost"] * 0.05
			candidate -= syncPull(u, pose) * (2.0 if vet else 1.2) * (2.0 if jt(u.get("nem")) and jt(B.get("nemLine")) else 1.0)
			if objective != null:
				candidate += _objective_position(u, pose, hulls, objective)
			var well = B.get("well")
			if well != null:
				var d := hdist(pose, well)
				candidate -= 45.0 if d <= WELL_RIM else (6.0 if d <= WELL_PULL else 0.0)
			if candidate > value:
				value = candidate
				best = pose
		return best

	func _rear_opportunity(pose: Dictionary, ready: Array, hulls: Array) -> float:
		var best := 0.0
		for t in hulls:
			var quad := shieldQuad(t, pose)
			var value := 8.0 if quad == 2 else (3.0 if quad == 1 or quad == 3 else 0.0)
			if value > best and ready.any(func(w): return inReach(pose, w, t)):
				best = value
		return best

	func _objective_position(u: Dictionary, pose: Dictionary, hulls: Array, objective: Dictionary) -> float:
		if jt(u.get("transport")):
			return -(objective["exitR"] - pose["r"]) * 14.0
		var quarry = B.get("mapTrialQuarry")
		if quarry != null:
			if is_same(u, quarry):
				return minf(_mind(pose, hulls, 30), 9.0) - 10.0 * hdist(pose, B["mapTrialBearing"])
			if u.get("mapTrialStart") != null:
				return -80.0 * hdist(pose, u["mapTrialStart"]) if B["round"] < 3 and not jt(quarry.get("dead")) else 0.0
		var progress := clampf((float(B["round"]) - 1.0) / float(objective.get("rounds", ENC_ROUNDS)), 0.0, 1.0)
		match objective["type"]:
			"hunt":
				return minf(_mind(pose, hulls, 30), 9.0) * 3.0 if jt(u.get("flagship")) else 0.0
			"defend":
				var urgency := 1.0 + progress * 1.2 + (0.6 if objective["hp"] <= 2 else 0.0) if vet else 1.0
				return -maxf(0.0, hdist(pose, objective["hex"]) - (stationRad() + 2)) * 3.0 * urgency
			"break":
				if hulls.is_empty():
					return 0.0
				var lead: Dictionary = hulls[0]
				for t in hulls:
					if _column(t) > _column(lead):
						lead = t
				var column := _column(lead)
				var penalty := maxf(0.0, column + 1.0 - _column(pose)) * 1.2
				if not vet:
					return -penalty
				var edge: float = objective["c0"]
				var advance := clampf((column - edge) / maxf(1.0, objective["exitC"] - edge), 0.0, 1.0)
				return -(penalty + maxf(0.0, absf(pose["r"] - lead["r"]) - 2.0) * 0.5) * (1.0 + 1.5 * advance)
			"intercept":
				var transports := enemies.filter(func(ally): return jt(ally.get("transport")))
				if transports.is_empty() or _objective_rank(u, transports) > 1:
					return 0.0
				return -maxf(0.0, _mind(pose, transports, 99) - 3.0) * 1.5
			"hold":
				var hex: Dictionary = objective["hex"]
				var distance := hdist(pose, hex)
				if _objective_rank(u, [hex]) > 1:
					return -maxf(0.0, distance - 5.0) * 0.4
				var urgency := 1.0 + progress * 0.8 + (0.8 if objective["score"] >= 2 else 0.0) + (0.4 if objective["escore"] >= 2 else 0.0) if vet else 1.0
				var held := hdist(u, hex) <= 1 and not hulls.any(func(t): return hdist(t, hex) <= 1)
				return -distance * 1.6 * urgency + (4.0 if held and distance <= 1 else 0.0)
		return 0.0

	func _objective_rank(u: Dictionary, anchors: Array) -> int:
		var distance := _mind(u, anchors, 99)
		var rank := 0
		for ally in enemies:
			if is_same(ally, u) or jt(ally.get("transport")) or jt(ally.get("isSq")):
				continue
			var other := _mind(ally, anchors, 99)
			if other < distance or (other == distance and String(ally["id"]) < String(u["id"])):
				rank += 1
		return rank

	func _column(pose: Dictionary) -> float:
		return pose["q"] + floor(pose["r"] / 2.0)

	# rules.aiPickPrimary, aiGunOrder and the first pick of aiVolley.
	func _volley_targets(u: Dictionary, ready: Array, aim) -> Array:
		var primary: Variant = null
		var primary_score := 0.0
		var last = u.get("aiLastT")
		var last_score := 0.0
		var estimates := {}
		for t in foes:
			var hull := 0.0
			var shield := 0.0
			var hits := {}
			for i in range(ready.size()):
				var w: Dictionary = ready[i]
				if canFire(u, w, t):
					var e := _expectedVs_raw(u, w, t)
					hits[i] = e
					hull += e.hull
					shield += e.shield * 0.3
			estimates[t["id"]] = hits
			if hull == 0.0 and shield == 0.0:
				continue
			var score: float = (minf(hull, t["hp"]) + shield) * (0.6 if jt(t.get("isSq")) else 1.1)
			if hull >= t["hp"]:
				score += 25.0 + t["maxHp"] * 0.15
			score += (10.0 if is_same(t, aim) else 0.0) + (1.0 - t["hp"] / t["maxHp"]) * 15.0 + _nemesis_bonus(u, t)
			if is_same(last, t):
				last_score = score
			if score > primary_score:
				primary_score = score
				primary = t
		if last_score > 0.0 and last_score >= primary_score * TB.AI_STICK:
			primary = last
		var gun := 0
		var best_shield := -INF
		var best_damage := -INF
		for i in range(ready.size()):
			var e = estimates[primary["id"]].get(i) if primary != null else null
			var shield: float = -1.0 if e == null else (Rules.JSM.jsround(e.shield / e.raw * 4.0) if e.raw > 0 else 0.0)
			var damage: float = ready[i]["dmg"] * ready[i]["shots"]
			if shield > best_shield or (shield == best_shield and damage > best_damage):
				gun = i
				best_shield = shield
				best_damage = damage
		var rows: Array = []
		var taunt: Variant = null
		var wing_screen := false
		for t in foes:
			if taunt == null and not jt(t.get("isSq")) and jt(g(t.get("fx"), "taunt")) and hdist(t, u) <= t["fx"]["taunt"]:
				taunt = t
			var e = estimates[t["id"]].get(gun)
			if e == null:
				continue
			wing_screen = wing_screen or jt(t.get("isSq"))
			var value: float = minf(e.hull, t["hp"]) + e.shield * 0.3 + (20.0 if e.hull >= t["hp"] else 0.0)
			if not jt(t.get("isSq")):
				value *= 1.1
			if value > 0.5:
				rows.append({"id": t["id"], "value": value, "reason": "finishing shot" if e.hull >= t["hp"] else "expected damage"})
		if taunt != null and estimates[taunt["id"]].has(gun):
			return _rank(rows, taunt["id"], "taunt")
		if vet and primary != null and estimates[primary["id"]].has(gun):
			if not (wing_screen and not jt(primary.get("isSq")) and z0(ready[gun].get("vsSq")) > 1):
				var split := _split_target(primary, gun, estimates)
				if split != "":
					return _rank(rows, split, "spare a finishing weapon")
				var reason := "fleet focus" if is_same(primary, aim) else ("previous target" if is_same(primary, last) else "volley priority")
				return _rank(rows, primary["id"], reason)
		return _rank(rows)

	func _nemesis_bonus(u: Dictionary, t: Dictionary) -> float:
		if not jt(u.get("nem")):
			return 0.0
		var persona = g(B.get("nemPersona"), "ai")
		var faction = B.get("nemAi")
		var bonus := 0.0
		if jt(g(persona, "focusWeak")) or jt(g(faction, "focusWeak")):
			bonus += 20.0 * (1.0 - float(t["hp"]) / t["maxHp"])
		if jt(g(persona, "focusFlag")) and jt(t.get("pflag")):
			bonus += 25.0
		if jt(g(persona, "rear")) and not jt(t.get("isSq")):
			var quad := shieldQuad(t, u)
			bonus += (10.0 if quad == 2 else (4.0 if quad == 1 or quad == 3 else 0.0)) * persona["rear"]
		if jt(g(faction, "hunt")) and jt(u.get("nemFlag")) and is_same(t, _duel_target()):
			bonus += 30.0
		return bonus

	# nemDuelTarget would change B.nemDuel and can log a retarget.
	func _duel_target() -> Variant:
		if not jt(B.get("nemChallenge")):
			return null
		var previous = units.get(B.get("nemDuel"))
		if previous != null and previous["side"] == "player" and not jt(previous.get("dead")):
			return previous
		var best: Variant = null
		for t in B["units"]:
			if t["side"] != "player" or jt(t.get("dead")):
				continue
			if jt(t.get("pflag")):
				return t
			if jt(t.get("isSq")) or jt(t.get("reinf")):
				continue
			var order := _byCpHp(t, best) if best != null else -1.0
			if order < 0.0 or (order == 0.0 and String(t["id"]) < String(best["id"])):
				best = t
		return best

	func _split_target(primary: Dictionary, gun: int, estimates: Dictionary) -> String:
		var hits: Dictionary = estimates[primary["id"]]
		if hits[gun].hull < primary["hp"] * 2:
			return ""
		var spare := false
		for i in hits:
			if i != gun and hits[i].hull >= primary["hp"]:
				spare = true
				break
		if not spare:
			return ""
		var best := 3.0
		var id := ""
		for t in foes:
			var e = estimates[t["id"]].get(gun)
			if is_same(t, primary) or e == null:
				continue
			var value: float = minf(e.hull, t["hp"]) + e.shield * 0.3 + (20.0 if e.hull >= t["hp"] else 0.0)
			if value > best:
				best = value
				id = t["id"]
		return id

	# rules.sqPlan's attack scoring, including ready weapons, stance and leash.
	func _wing_targets(u: Dictionary, ready: Array) -> Array:
		var carrier = units.get(u.get("parent"))
		if carrier != null and (jt(carrier.get("dead")) or carrier["side"] != u["side"]):
			carrier = null
		var order = u.get("wingOrder")
		var ordered = units.get(order["id"]) if jt(order) else null
		var strike: bool = jt(order) and order["kind"] == "strike"
		if ordered == null or jt(ordered.get("dead")) or ((ordered["side"] != u["side"]) != strike):
			ordered = null
		var stance := wingStance(u) if ordered == null else ""
		var guard = ordered if ordered != null and not strike else (carrier if stance == "screen" else null)
		var leash: float = TB.SQ_LEASH + (2 if ordered != null and strike else 0) + (TB.WING_HUNT_LEASH if stance == "hunt" else 0)
		var guard_range: float = TB.WING_SCREEN_R + 1 if stance == "screen" else 3
		var has_fighters := foes.any(func(t): return jt(t.get("isSq")))
		var scores := {}
		for state in [{"q": u["q"], "r": u["r"], "f": u["facing"], "cost": 0}] + computeReach(u, true)["states"]:
			if guard != null and hdist(state, guard) > guard_range:
				continue
			if guard == null and carrier != null and hdist(state, carrier) > leash:
				continue
			var pose := stateView(u, state)
			for t in foes:
				var forced := strike and is_same(t, ordered)
				var wing := jt(t.get("isSq"))
				var fighter := sqRole(u) == "fighter"
				if not forced and ((not fighter and wing) or (fighter and has_fighters and not wing)):
					continue
				for w in ready:
					if not canFire(pose, w, t):
						continue
					var e := _expectedVs_raw(pose, w, t)
					var v: float = e.hull + e.shield * 0.3 + (25.0 if e.hull >= t["hp"] else 0.0)
					if wing and sqRole(t) == "bomber":
						v *= 1.5
					if is_same(t, focus):
						v *= 1.3
					if vet and sqObjNear(t):
						v += 6.0
					v += (1.0 - t["hp"] / t["maxHp"]) * 10.0 - state["cost"] * 0.01
					if forced:
						v = v * 3.0 + 60.0
					if guard != null and hdist(t, guard) <= 3:
						v = v * 2.0 + 20.0
					if stance == "screen" and wing:
						v *= 2.0
					if stance == "hunt" and not wing and t["hp"] < t["maxHp"] / 2.0:
						v *= 1.6
					scores[t["id"]] = maxf(v, scores.get(t["id"], -INF))
		var rows: Array = []
		for id in scores:
			rows.append({"id": id, "value": scores[id], "reason": "wing strike"})
		return _rank(rows)

	func _rank(rows: Array, preferred := "", reason := "") -> Array:
		rows.sort_custom(func(a, b):
			return a["value"] > b["value"] if a["value"] != b["value"] else _tie_before(a, b))
		var top := float(rows[0]["value"]) if not rows.is_empty() else 0.0
		var result: Array = []
		if preferred != "":
			result.append({"id": preferred, "reason": reason, "likelihood": "leading"})
		for row in rows:
			if row["id"] == preferred:
				continue
			var likelihood := "possible"
			if preferred == "":
				if result.is_empty():
					likelihood = "leading"
				elif row["value"] == top:
					likelihood = "tied"
			result.append({"id": row["id"], "reason": row["reason"], "likelihood": likelihood})
		return result
