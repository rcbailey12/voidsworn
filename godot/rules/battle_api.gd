# The battle rules API for the game side (scenes, render, UI). See API.md for the contract.
# The renderer never writes rules state: it sends commands here, reads view(), and plays take_events().
# The turn flow is a port of the game's ui3d.js (guard, act, endActivation, aiStep, nextRound), alternating activations.
extends RefCounted
const JSM = preload("res://rules/jsm.gd")
const RulesScript = preload("res://rules/rules.gd")

var R                       # the rules (rules.gd); read-only for the game side, use view()
var phase := "none"         # "player" | "enemy" | "over" | "none"
var _queue: Array = []      # enemy units still to act in the current enemy step
var _mutex := Mutex.new()
var _alt := true              # alternating activations (the game's default) or Classic mode (whole turns)
var _c_order: Array = []; var _c_i := 0; var _c_g := 0; var _c_done: Array = []   # Classic mode: the enemy turn in progress (battle.js aiTurn)

# ---------------- setup ----------------
func load_rules(tables_path: String = "res://rules/data/tables.json") -> String:
	R = RulesScript.new()
	return R.load_tables(tables_path)

# A battle from a test scenario (rules/test/scenarios.json) or a scenario dictionary with the same fields.
func new_battle_scenario(sc, seed_override: int = -1) -> void:
	var S = sc
	if sc is String:
		S = JSON.parse_string(FileAccess.get_file_as_string("res://rules/test/scenarios.json"))[sc]
	var seed := int(S.seed) if seed_override < 0 else seed_override
	R.UID = 1; JSM.rnd_seed(seed)
	R.AI_LEVEL = S.get("ai") if S.get("ai") != null else "veteran"
	var boons := []
	for x in S.get("boons", []): boons.append(x.duplicate())
	var run := {"admiral": S.admiral, "fac": S.get("fac_player") if S.get("fac_player") != null else "voidsworn", "credits": 0, "cpCap": 40, "sector": int(S.sector), "relics": S.get("relics", []).duplicate(), "inventory": [], "fleet": [], "boons": boons, "patrons": [], "stats": {"battles": 0, "elites": 0, "bosses": 0, "kills": 0}, "fallen": []}
	if R.jt(S.get("aspect")): run["aspect"] = S.aspect
	if S.get("heat") != null: run["heat"] = S.heat.duplicate()
	R.RUN = run
	for t in S.fleet: run["fleet"].append(R.newShip(t, R.jt(S.get("vet"))))
	run["flagUid"] = run["fleet"][0]["uid"]
	var cfg := {"kind": S.kind, "fac": S.fac, "col": 3 if S.get("col") == null else S.col, "seed": seed, "obj": S.obj, "shape": S.shape, "map": S.map, "dep": S.dep}
	if R.jt(S.get("arch")): cfg["arch"] = S.arch
	if R.jt(S.get("mod")): cfg["mod"] = S.mod
	if S.get("alt") == false: cfg["alt"] = false
	if R.jt(S.get("campaign")):
		cfg["campaign"] = true; cfg["event_force"] = S.get("event_force")
	if S.get("enemies") != null:
		var en := []
		for tpl in S.enemies: en.append({"tpl": tpl})
		cfg["enemies"] = en
	new_battle(run, cfg)

# A battle from a campaign run (the RUN dictionary: admiral, fac, sector, fleet of ships, relics, boons, ...) and a battle config
# (kind, fac, col, seed, obj, shape, map, dep, arch, mod; enemies optional: without it the enemy fleet is generated).
func new_battle(run: Dictionary, cfg: Dictionary) -> void:
	R.RUN = run; R.events.clear(); _queue.clear()
	var campaign = R.jt(cfg.get("campaign")); var force = cfg.get("event_force"); _alt = cfg.get("alt") != false
	cfg = cfg.duplicate(); cfg.erase("campaign"); cfg.erase("event_force"); cfg.erase("alt")
	R.startBattle(cfg)
	if campaign: # campaign3d.js battleScreen: a campaign battle may roll a mid-battle event
		R.B["campaign"] = true; R.B["event"] = R.rollBattleEvent(cfg, force)
	R.hook("start")
	_prep()

func _prep() -> void: # ui3d.js prepBattle
	var B = R.B
	B["alt"] = _alt
	for x in B["units"]: x["activated"] = false
	if _alt:
		R.startSideTurn("enemy"); R.flush_deferred()
	phase = "over" if R.jt(B.get("over")) else "player"
	R.emit({"t": "round", "round": int(B["round"])}); R.emit({"t": "side", "side": "player"})

# ---------------- reading state ----------------
func unit(id: String) -> Variant:
	for u in R.B["units"]:
		if u["id"] == id: return u
	return null

# A plain copy for drawing. Safe to keep; never changes behind your back.
func view() -> Dictionary:
	var B = R.B; var us := []
	for u in B["units"]:
		var ws := []
		for i in range(u["weapons"].size()):
			var w = u["weapons"][i]
			ws.append({"i": i, "id": w["id"], "name": w.get("n"), "kind": w["k"], "arc": w["arc"], "range": w["r"], "ready": R.weaponReady(w), "cd": w["cdLeft"], "off": w["off"]})
		us.append({"id": u["id"], "side": u["side"], "tpl": u["tpl"], "name": u["name"], "cls": u.get("cls"), "fac": u["fac"], "size": u["size"], "squadron": R.jt(u.get("isSq")),
			"q": int(u["q"]), "r": int(u["r"]), "facing": int(u["facing"]), "hp": u["hp"], "maxHp": u["maxHp"], "sh": u["sh"].duplicate(), "shMax": u["shMax"],
			"sec": u.get("sec").duplicate(true) if u.get("sec") != null else null, "crew": u.get("crew"), "crewMax": u.get("crewMax"), "dead": R.jt(u.get("dead")), "fled": R.jt(u.get("fled")),
			"activated": R.jt(u.get("activated")), "active": B.get("activeUnit") != null and is_same(B["activeUnit"], u), "braced": R.jt(u.get("braced")), "mp": u["mp"], "turnsLeft": u["turnsLeft"],
			"ab": u.get("ab"), "abCd": u["abCd"], "abReady": R.canAbility(u) if not R.jt(u.get("dead")) else false, "burning": R.z0(u["st"].get("fire")) > 0, "flagship": R.jt(u.get("flagship")) or R.jt(u.get("boss")), "weapons": ws})
	return {"round": int(B["round"]), "side": B["side"], "phase": phase, "over": B["over"] if R.jt(B.get("over")) else null, "terrain": B["terrain"].duplicate(), "map": B["map"].duplicate(true),
		"obj": B["obj"].duplicate(true) if B.get("obj") != null else null, "units": us, "focus": B["aiFocus"]["id"] if B.get("aiFocus") != null else null, "arena": B["arena"], "cut": R.CUT.keys() if R.CUT != null else []}

# Everything that happened since the last call, in order (API.md lists the event types).
func take_events() -> Array:
	var e = R.events; R.events = []; return e

# ---------------- previews for the UI (no state change) ----------------
func reach(id: String) -> Array:          # every end state the ship can move to: {q, r, f, cost, t, path}
	var u = unit(id)
	if u == null or not _can_use(u): return []
	return R.computeReach(u).states
func can_fire(id: String, wi: int, target_id: String) -> bool:
	var u = unit(id); var t = unit(target_id)
	return u != null and t != null and R.canFire(u, u["weapons"][wi], t)
func preview_fire(id: String, wi: int, target_id: String) -> Dictionary:   # hit %, expected shield and hull damage, facing quadrant
	var u = unit(id); var t = unit(target_id); var w = u["weapons"][wi]
	var e = R.expectedVs(u, w, t)
	return {"hit": R.hitChance(u, w, t), "shield": e.shield, "hull": e.hull, "quad": e.quad, "rear": e.rear, "can": R.canFire(u, w, t)}

# ---------------- player commands (the same path the UI uses: ui3d.js guard + act) ----------------
func _can_use(u) -> bool: # ui3d.js canUse
	var B = R.B
	if not R.jt(B.get("alt")) or R.jt(u.get("isSq")): return true
	if R.jt(u.get("activated")): return false
	return B.get("activeUnit") == null or is_same(B["activeUnit"], u)
func _guard(u) -> bool:
	if phase != "player" or u == null or u["side"] != "player" or R.jt(u.get("dead")) or R.jt(R.B.get("busy")): return false
	if _can_use(u):
		if R.jt(R.B.get("alt")) and not R.jt(u.get("isSq")) and R.B.get("activeUnit") == null:
			R.B["activeUnit"] = u; R.emit({"t": "activation", "unit": u["id"], "side": "player"})
		return true
	return false
func _after_act() -> void: # ui3d.js act(): end the activation once the acting ship is done or dead
	var B = R.B
	B["busy"] = false
	if R.jt(B.get("over")):
		_finish(); return
	var a = B.get("activeUnit")
	if R.jt(B.get("alt")) and a != null and (R.jt(a.get("dead")) or _done_raw(a)): end_activation()
func _done_raw(u) -> bool: # ui3d.js isDoneRaw
	if R.jt(u.get("dead")) or R.jt(u.get("braced")): return true
	if u["mp"] > 0: return false
	for w in u["weapons"]:
		if R.weaponReady(w):
			for t in R.alive("enemy"):
				if R.canFire(u, w, t): return false
	return true

func move(id: String, state: Dictionary) -> bool:   # state: one of reach(id)
	var u = unit(id)
	if not _guard(u): return false
	R.B["busy"] = true; R.moveUnit(u, state); _after_act(); return true
func fire(id: String, wi: int, target_id: String, called_section = null) -> bool:
	var u = unit(id); var t = unit(target_id)
	if t == null or not _guard(u): return false
	R.B["busy"] = true; var ok = R.fireWeapon(u, wi, t, {"called": called_section} if called_section != null else {}); _after_act(); return ok
func ability(id: String, arg = null) -> bool:       # arg: {hex: {q, r}} for nova, blink and launch; {kind} for launch
	var u = unit(id)
	if not _guard(u): return false
	R.B["busy"] = true; var ok = R.useAbility(u, arg); _after_act(); return ok
func order(id: String, kind: String) -> bool:       # "brace" | "full" | "lock" | "helm"
	var u = unit(id)
	if not _guard(u) or not R.canOrder(u, kind): return false
	R.B["busy"] = true; R.giveOrder(u, kind); _after_act(); return true
func ram(id: String) -> bool:
	var u = unit(id)
	if not _guard(u): return false
	R.B["busy"] = true; var ok = R.ramUnit(u); _after_act(); return ok
func board(id: String, target_id: String) -> bool:
	var u = unit(id); var t = unit(target_id)
	if t == null or not _guard(u): return false
	R.B["busy"] = true; var ok = R.boardUnit(u, t); _after_act(); return ok
func rotate(id: String, dir: int) -> bool:          # +1 or -1: turn in place
	var u = unit(id)
	if not _guard(u): return false                  # as the game: the ship becomes the active one even if it cannot turn
	var ok = R.canRotate(u)
	R.B["busy"] = true; R.rotateUnit(u, dir); _after_act(); return ok
# A standing order for one of your wings (ui3d.js wing select then tap): an enemy ship = strike it until it dies,
# one of your own ships = guard it. Pass target_id = null to do nothing. Orders take effect in the wing's next swarm phase.
func wing_order(wing_id: String, target_id: String) -> bool:
	var w = unit(wing_id); var u = unit(target_id)
	if phase == "over" or w == null or u == null or w["side"] != "player" or not R.jt(w.get("isSq")) or R.jt(w.get("dead")): return false
	if is_same(u, w) or (u["side"] == "player" and R.jt(u.get("isSq"))): return false
	w["wingOrder"] = {"kind": "strike" if u["side"] == "enemy" else "guard", "id": u["id"]}
	if R.jt(R.B.get("usage")): R.B["usage"]["wingOrders"] = R.z0(R.B["usage"].get("wingOrders")) + 1
	R.hook("wing order", w); return true
func can_command() -> bool: return phase == "player" and R.canCommand("player")
func command() -> bool:                             # the Admiral's Command (once per battle, from round 1)
	if not can_command() or R.jt(R.B.get("busy")): return false
	R.B["busy"] = true; var ok = R.useCommand("player"); _after_act(); return ok
# Test harness only (the parity bot): run a rules call as one player action, with the same guard and auto end as the commands.
func _bot_act(u, fn: Callable) -> Variant:
	if not _guard(u): return null
	R.B["busy"] = true; var r = fn.call(); _after_act(); return r
func hurry() -> void:                               # Enter or Space: presentation only, the rules do not change
	pass

# ui3d.js endActivation: the acting ship (or the given one, as "Pass") is done, then the enemy side takes its step
func end_activation(id = null) -> void:
	var B = R.B
	if not _alt or phase != "player" or R.jt(B.get("over")): return
	if B.get("activeUnit") != null:
		B["activeUnit"]["activated"] = true; B["activeUnit"] = null
	elif id != null:
		var u = unit(id)
		if u != null and u["side"] == "player" and not R.jt(u.get("isSq")) and not R.jt(u.get("activated")): u["activated"] = true
	B["sel"] = null; B["reach"] = null; B["armed"] = null; B["mode"] = null
	R.hook("end activation")
	_ai_step_begin()

# ---------------- the enemy side ----------------
# After end_activation, phase is "enemy" while enemy ships still have to act. Call step() once per enemy activation; each call
# runs one ship's whole activation (and the round change when a round ends) and returns its events. step() is safe to run on a
# worker thread while the scene animates earlier events, as long as the scene does not call anything else here meanwhile.
func step() -> Array:
	_mutex.lock()
	var B = R.B
	if phase == "enemy" and not _alt: _c_step()
	elif phase == "enemy" and _queue.size() > 0:
		var u = _queue.pop_front()
		if R.jt(B.get("over")):
			_queue.clear()
		else:
			R.emit({"t": "activation", "unit": u["id"], "side": "enemy"})
			R.aiUnit(u); u["activated"] = true; R.hook("activation", u)
		if _queue.size() == 0: _end_batch()
	var e = take_events()
	_mutex.unlock()
	return e

# ---------------- Classic mode (cfg.alt = false): whole turns, ui3d.js endTurn ----------------
# The player moves and fires with any ships in any order, then calls end_turn(). The enemy turn is then stepped one ship per
# step() call, exactly as battle.js aiTurn orders it: its squadrons first, then each next ship picked by opportunity.
func end_turn() -> void:
	var B = R.B
	if _alt or phase != "player" or R.jt(B.get("over")) or R.jt(B.get("busy")): return
	B["busy"] = true; B["sel"] = null; B["armed"] = null; B["mode"] = null; B["inspect"] = null; B["reach"] = null
	B["side"] = "enemy"; R.emit({"t": "side", "side": "enemy"})
	R.startSideTurn("enemy"); R.flush_deferred()
	R.hook("end turn")
	_c_order = R.alive("enemy")
	JSM.ssort(_c_order, func(a, b):
		var d = (0 if R.jt(a.get("isSq")) else 1) - (0 if R.jt(b.get("isSq")) else 1)
		return d if d != 0 else b["speed"] - a["speed"])
	_c_i = 0; _c_g = 0; _c_done = []
	phase = "enemy"
	if R.jt(B.get("over")) or not _c_more(): _c_end()
func _c_left() -> Array:
	var l := []
	for u in _c_order:
		if not R.jt(u.get("isSq")) and not R.jt(u.get("dead")) and not JSM.has_same(_c_done, u): l.append(u)
	return l
func _c_more() -> bool: # is there another enemy activation this turn (aiTurn's loops, looked ahead without side effects)
	for k in range(_c_i, _c_order.size()):
		var u = _c_order[k]
		if not R.jt(u.get("dead")) and R.jt(u.get("isSq")): return true
	return _c_g < _c_order.size() and _c_left().size() > 0
func _c_step() -> void:
	var B = R.B
	var u = null
	while _c_i < _c_order.size():
		var x = _c_order[_c_i]; _c_i += 1
		if not R.jt(x.get("dead")) and R.jt(x.get("isSq")):
			u = x; break
	if u == null:
		_c_g += 1; u = R.aiPickActivation(_c_left()); _c_done.append(u)
	R.emit({"t": "activation", "unit": u["id"], "side": "enemy"})
	R.aiUnit(u)
	if R.jt(B.get("over")) or not _c_more(): _c_end()
func _c_end() -> void:
	var B = R.B
	B["aiActive"] = null; _c_order = []; _c_done = []
	if R.jt(B.get("over")):
		B["busy"] = false; _finish(); return
	B["round"] = B["round"] + 1; B["side"] = "player"; R.emit({"t": "round", "round": int(B["round"])})
	R.startSideTurn("player"); R.flush_deferred()
	if R.jt(B.get("over")):
		B["busy"] = false; _finish(); return
	R.swarmPhase("player"); R.flush_deferred()
	B["busy"] = false; R.hook("round")
	if R.jt(B.get("over")):
		_finish(); return
	phase = "player"; R.emit({"t": "side", "side": "player"})

func _pendingP() -> Array:
	var o := []
	for u in R.alive("player"):
		if not R.jt(u.get("isSq")) and not R.jt(u.get("activated")) and not (R.B.get("activeUnit") != null and is_same(u, R.B["activeUnit"])): o.append(u)
	return o
func _pendingE() -> Array:
	var o := []
	for u in R.alive("enemy"):
		if not R.jt(u.get("isSq")) and not R.jt(u.get("activated")): o.append(u)
	return o
func _ai_step_begin() -> void: # ui3d.js aiStep, first half
	var B = R.B
	var pe = _pendingE(); var pp = _pendingP()
	if pe.size() > 0:
		B["busy"] = true; B["side"] = "enemy"; R.emit({"t": "side", "side": "enemy"})
		var sqs := []
		for u in R.alive("enemy"):
			if R.jt(u.get("isSq")) and not R.jt(u.get("activated")): sqs.append(u)
		var batch: Array
		if pp.size() > 0:
			JSM.ssort(pe, func(a, b): return b["speed"] - a["speed"])
			batch = [R.aiPickActivation(pe)]
		else: batch = pe
		_queue = sqs + batch; phase = "enemy"
	else: _after_batch()
func _end_batch() -> void: # ui3d.js aiStep, second half
	var B = R.B
	B["aiActive"] = null; B["side"] = "player"; B["busy"] = false
	if R.jt(B.get("over")):
		_finish(); return
	R.emit({"t": "side", "side": "player"})
	_after_batch()
func _after_batch() -> void:
	if _pendingP().size() == 0 and _pendingE().size() == 0: _next_round()
	elif _pendingP().size() == 0: _ai_step_begin()
	else: phase = "player"
func _next_round() -> void: # ui3d.js nextRound
	var B = R.B
	B["round"] = B["round"] + 1
	for x in B["units"]: x["activated"] = false
	B["activeUnit"] = null; B["busy"] = true
	R.emit({"t": "round", "round": int(B["round"])})
	R.startSideTurn("player")
	if not R.jt(B.get("over")): R.startSideTurn("enemy")
	R.flush_deferred()
	if R.jt(B.get("over")):
		B["busy"] = false; _finish(); return
	B["busy"] = true; R.swarmPhase("player")
	if not R.jt(B.get("over")): R.swarmPhase("enemy")
	R.flush_deferred()
	B["busy"] = false
	R.hook("round")
	if R.jt(B.get("over")):
		_finish(); return
	phase = "player"
	R.emit({"t": "side", "side": "player"})
func _finish() -> void:
	phase = "over"; _queue.clear(); R.emit({"t": "end", "result": R.B["over"]})
