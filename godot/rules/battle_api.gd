# The battle rules API for the game side (scenes, render, UI). See API.md for the contract.
# The renderer never writes rules state: it sends commands here, reads view(), and plays take_events().
# The turn flow is a port of the game's ui3d.js (guard, act, endActivation, aiStep, nextRound), alternating activations.
extends RefCounted
# The JS port keeps JS shapes (untyped Dictionaries, JS-style numbers), so the untyped-code warnings are silenced for this file only.
# Of the six classes the project leaves on, three stay ON here and give 0 warnings (Oct 26, checked by turning them into errors):
# integer_division and narrowing_conversion (the JS-port number traps) and unsafe_property_access. The other three are silenced
# because they are the JS shapes themselves (65 call arguments, 449 method calls, 16 discarded results at Oct 26): unsafe_call_argument
# (Variant into a typed float), unsafe_method_access (calls on untyped values) and return_value_discarded (JS ignores results the same way).
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "shadowed_variable", "shadowed_variable_base_class", "shadowed_global_identifier", "unused_variable", "unused_parameter", "confusable_local_declaration", "confusable_local_usage", "return_value_discarded", "incompatible_ternary")
const JSM = preload("res://rules/jsm.gd")
const RulesScript = preload("res://rules/rules.gd")

var R                       # the rules (rules.gd); read-only for the game side, use view()
var phase := "none"         # "player" | "enemy" | "over" | "none" | "halted" (hard stop, see below)
var _queue: Array = []      # enemy units still to act in the current enemy step
var _mutex := Mutex.new()    # recursive: every public call below holds it (see "Threads" in API.md)
var _hexes: Array = []       # every playable hex {q, r} of this battle's board (fixed at setup; view().hexes, read-only)
var _alt := true              # alternating activations (the game's default) or Classic mode (whole turns)
var _c_order: Array = []; var _c_i := 0; var _c_g := 0; var _c_done: Array = []   # Classic mode: the enemy turn in progress (battle.js aiTurn)

# ---------------- setup ----------------
# ---------------- threads, errors and the hard stop ----------------
# Every public function is a thin wrapper: lock, run the body (_i_<name>), check, unlock. So step() or threat_map() may run on a
# worker thread while the scene calls view(), ui_info() or anything else: the other caller waits for the lock instead of reading
# half-changed state. A runtime error inside the rules returns from the failing function with a default value and execution goes
# on (GDScript has no exceptions), so the wrapper always reaches its unlock; the error itself is caught by a Logger that counts
# script errors raised in res://rules/ during the call.
# Hard stop (on by default in debug builds and for bot runs: set hard_stop = true): a rules script error or a NOT PORTED rule
# (rules.gd np() or an unported maths branch in jsm.gd) during any call halts the battle: phase becomes "halted", view().halt says
# why, an event {t: "halt", why} is emitted, and every command and step() does nothing until the next new_battle. With hard_stop
# off (release builds) the error is still logged and counted, and play goes on.
var hard_stop: bool = OS.is_debug_build()
var halted := ""              # why the battle was halted ("" while it runs)
var version := 0              # bumped after every call that can change the battle; caches below are per version
var _depth := 0
var _err0 := 0
var _ui_cache := {}; var _ui_ver := -1
var _threat_cache := {}; var _threat_ver := -1
class RulesErrors extends Logger:
	var n := 0
	var first := ""
	var mutex := Mutex.new()
	func _log_error(function: String, file: String, line: int, code: String, rationale: String, editor_notify: bool, error_type: int, script_backtraces: Array) -> void:
		if error_type == Logger.ERROR_TYPE_WARNING: return
		var mine := file.begins_with("res://rules/")
		if not mine:
			for bt in script_backtraces:
				if bt is ScriptBacktrace and bt.get_frame_count() > 0 and String(bt.get_frame_file(0)).begins_with("res://rules/"): mine = true
		if not mine: return
		mutex.lock()
		n += 1
		if first == "": first = "%s (%s:%d %s)" % [rationale if rationale != "" else code, file.get_file(), line, function]
		mutex.unlock()
	func count() -> int:
		mutex.lock(); var c := n; mutex.unlock(); return c
	func first_msg() -> String:
		mutex.lock(); var f := first; first = ""; mutex.unlock(); return f
static var _errlog: RulesErrors = null
static var _errlog_mutex := Mutex.new()
static func _errors() -> RulesErrors:
	_errlog_mutex.lock()
	if _errlog == null:
		_errlog = RulesErrors.new(); OS.add_logger(_errlog)
	_errlog_mutex.unlock()
	return _errlog
func _enter() -> void:
	_mutex.lock()
	_depth += 1
	if _depth == 1:
		_err0 = _errors().count(); _errors().first_msg()   # forget an older error's text
func _leave(changes: bool) -> void:
	if _depth == 1:
		if changes: version += 1
		if halted == "" and R != null:
			var why := ""
			if _errors().count() > _err0: why = "rules script error: " + _errors().first_msg()
			elif R.not_ported != "": why = "NOT PORTED: " + R.not_ported
			if why != "" and hard_stop: _halt(why)
	_depth -= 1
	_mutex.unlock()
func _halt(why: String) -> void:
	halted = why; phase = "halted"; _queue.clear(); version += 1
	if R != null: R.emit({"t": "halt", "why": why})
	printerr("BATTLE HALTED (hard stop): ", why)

func load_rules(tables_path: String = "res://rules/data/tables.json") -> String:
	_enter(); halted = ""
	if R != null: R.not_ported = ""   # a new battle starts clean
	var r = _i_load_rules(tables_path); _leave(true); return r
func _i_load_rules(tables_path: String = "res://rules/data/tables.json") -> String:
	R = RulesScript.new()
	return R.load_tables(tables_path)

# A battle from a test scenario (rules/test/scenarios.json) or a scenario dictionary with the same fields.
func new_battle_scenario(sc, seed_override: int = -1) -> void:
	_enter(); halted = ""
	if R != null: R.not_ported = ""   # a new battle starts clean
	_i_new_battle_scenario(sc, seed_override); _leave(true)
func _i_new_battle_scenario(sc, seed_override: int = -1) -> void:
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
	if S.get("class_track") != null: run["classTrack"] = S.class_track.duplicate()
	R.RUN = run
	for t in S.fleet: run["fleet"].append(R.newShip(t, R.jt(S.get("vet"))))
	run["flagUid"] = run["fleet"][0]["uid"]
	var cfg := {"kind": S.kind, "fac": S.fac, "col": 3 if S.get("col") == null else S.col, "seed": seed, "obj": S.obj, "shape": S.shape, "map": S.map, "dep": S.dep}
	if R.jt(S.get("arch")): cfg["arch"] = S.arch
	if R.jt(S.get("mod")): cfg["mod"] = S.mod
	if S.get("nemesis") != null: cfg["nemesis"] = S.nemesis.duplicate(true)
	if R.jt(S.get("verb")): cfg["verb"] = S.verb
	if S.get("alt") != null: cfg["alt"] = S.alt   # passed through untouched, so new_battle's type-safe cfg.alt!==false is what decides (s41: a Dictionary)
	if R.jt(S.get("campaign")):
		cfg["campaign"] = true; cfg["event_force"] = S.get("event_force"); cfg["event_war"] = S.get("event_war")
	if S.get("enemies") != null:
		var en := []
		for tpl in S.enemies: en.append({"tpl": tpl})
		cfg["enemies"] = en
	new_battle(run, cfg)

# The config is the one input the rules take from outside (G3's campaign, G2's scenes, saves). The rules compare these fields with
# string literals, and GDScript stops the call on a cross-type ==, so a wrong type is reported here and dropped (treated as unset,
# as JS would treat an unknown value) instead of stopping a battle halfway through its setup. StringName becomes String.
const CFG_STRINGS := ["kind", "fac", "obj", "shape", "map", "dep", "arch", "mod", "verb", "event_force", "biome", "approach", "arena"]
var cfg_errors: Array = []   # what _clean_cfg dropped in the last new_battle (also pushed as engine errors)
func _clean_cfg(cfg: Dictionary) -> Dictionary:
	cfg_errors = []
	var c := cfg.duplicate()
	for k in CFG_STRINGS:
		if not c.has(k) or c[k] == null: continue
		if c[k] is StringName: c[k] = String(c[k])
		elif not (c[k] is String):
			cfg_errors.append("battle config %s must be a String or null, got %s (%s): dropped" % [k, type_string(typeof(c[k])), str(c[k]).left(60)])
			c.erase(k)
	for k in ["seed", "col"]:
		if c.has(k) and c[k] != null and not (c[k] is int or c[k] is float):
			cfg_errors.append("battle config %s must be a number, got %s: dropped" % [k, type_string(typeof(c[k]))]); c.erase(k)
	for k in ["enemies"]:
		if c.has(k) and c[k] != null and not (c[k] is Array):
			cfg_errors.append("battle config %s must be an Array, got %s: dropped" % [k, type_string(typeof(c[k]))]); c.erase(k)
	for k in ["nemesis"]:
		if c.has(k) and c[k] != null and not (c[k] is Dictionary):
			cfg_errors.append("battle config %s must be a Dictionary, got %s: dropped" % [k, type_string(typeof(c[k]))]); c.erase(k)
	if not (c.get("fac") is String and R.FACTIONS.has(c["fac"])):
		cfg_errors.append("battle config fac must name a faction, got %s: the battle cannot be set up" % str(c.get("fac")))
	elif c.get("enemies") == null and c.get("col") == null:
		cfg_errors.append("battle config col (map column) missing for a generated fleet: using 3"); c["col"] = 3
	for e in cfg_errors: push_error(e)
	return c

# A battle from a campaign run (the RUN dictionary: admiral, fac, sector, fleet of ships, relics, boons, ...) and a battle config
# (kind, fac, col, seed, obj, shape, map, dep, arch, mod; enemies optional: without it the enemy fleet is generated).
func new_battle(run: Dictionary, cfg: Dictionary) -> void:
	_enter(); halted = ""
	if R != null: R.not_ported = ""   # a new battle starts clean
	_i_new_battle(run, cfg); _leave(true)
func _i_new_battle(run: Dictionary, cfg: Dictionary) -> void:
	cfg = _clean_cfg(cfg)
	if not (cfg.get("fac") is String and R.FACTIONS.has(cfg["fac"])):
		R.events.clear(); _queue.clear(); _halt(cfg_errors[-1]); return
	R.RUN = run; R.events.clear(); _queue.clear()
	var campaign = R.jt(cfg.get("campaign")); var force = cfg.get("event_force"); var war = R.jt(cfg.get("event_war")); _alt = not R.js_false(cfg.get("alt"))   # JS cfg.alt!==false (type-safe: any other value, even a Dictionary, means alternating)
	cfg = cfg.duplicate(); cfg.erase("campaign"); cfg.erase("event_force"); cfg.erase("event_war"); cfg.erase("alt")
	R.startBattle(cfg)
	_hexes = []
	for h in R.boardHexes(): _hexes.append({"q": int(h.q), "r": int(h.r)})
	if campaign: # campaign3d.js battleScreen: a campaign battle may roll a mid-battle event
		R.B["campaign"] = true
		if war: force = ("reinf_enemy" if R.rnd() < 0.6 else "reinf_ally") if cfg.get("kind") != "boss" else null   # a sector at war: drawn after setup, as the browser does
		R.B["event"] = R.rollBattleEvent(cfg, force)
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
	_enter()
	var r = _i_unit(id); _leave(false); return r
func _i_unit(id: String) -> Variant:
	for u in R.B["units"]:
		if u["id"] == id: return u
	return null

# A plain copy for drawing. Safe to keep; never changes behind your back.
func view() -> Dictionary:
	_enter()
	var r = _i_view(); _leave(false); return r
func _i_view() -> Dictionary:
	var B = R.B; var us := []
	for u in B["units"]:
		var ws := []
		for i in range(u["weapons"].size()):
			var w = u["weapons"][i]
			ws.append({"i": i, "id": w["id"], "name": w.get("n"), "kind": w["k"], "arc": w["arc"], "range": w["r"], "ready": R.weaponReady(w), "cd": w.get("cdLeft"), "off": w.get("off")})   # get(): B-20 refits lack them
		us.append({"id": u["id"], "side": u["side"], "tpl": u["tpl"], "name": u["name"], "cls": u.get("cls"), "fac": u["fac"], "size": u["size"], "squadron": R.jt(u.get("isSq")),
			"q": int(u["q"]), "r": int(u["r"]), "facing": int(u["facing"]), "hp": u["hp"], "maxHp": u["maxHp"], "sh": u["sh"].duplicate(), "shMax": u["shMax"],
			"sec": u.get("sec").duplicate(true) if u.get("sec") != null else null, "crew": u.get("crew"), "crewMax": u.get("crewMax"), "dead": R.jt(u.get("dead")), "fled": R.jt(u.get("fled")),
			"activated": R.jt(u.get("activated")), "active": B.get("activeUnit") != null and is_same(B["activeUnit"], u), "braced": R.jt(u.get("braced")), "mp": u["mp"], "turnsLeft": u["turnsLeft"],
			"ab": u.get("ab"), "abCd": u["abCd"], "abReady": R.canAbility(u) if not R.jt(u.get("dead")) else false, "burning": R.z0(u["st"].get("fire")) > 0, "flagship": R.jt(u.get("flagship")) or R.jt(u.get("boss")), "weapons": ws,
			"moveLeft": R.postFireMp(u), "fired": R.jt(u.get("postFire")), "stance": u.get("stance") if (u.get("ab") == "launch" or R.jt(R.g(u.get("fx"), "hive"))) else null, "canStance": R.canStance(u),
			"anchor": R.jt(u.get("anchor")), "inSync": R.inSync(u), "rising": u.get("riseAt"), "nemesis": R.jt(u.get("nemFlag")), "covered": u.get("coverBy")})
	return {"round": int(B["round"]), "side": B["side"], "phase": phase, "over": B["over"] if R.jt(B.get("over")) else null, "terrain": B["terrain"].duplicate(), "map": B["map"].duplicate(true),
		"obj": B["obj"].duplicate(true) if B.get("obj") != null else null, "units": us, "focus": B["aiFocus"]["id"] if B.get("aiFocus") != null else null, "arena": B["arena"], "cut": R.CUT.keys() if R.CUT != null else [], "hexes": _hexes, "torps": _torps(), "zones": _zones(), "halt": halted if halted != "" else null}
func _zones() -> Dictionary: # battle.js objZone: "exit" (breakthrough: jump clear here), "texit" (intercept: transports escape here), "guard" (defend: the ring 2 hexes out)
	var o := {}
	if R.B.get("obj") == null: return o
	for h in _hexes:
		var z = R.objZone(h.q, h.r)
		if z != null: o[str(h.q) + "," + str(h.r)] = z
	return o
func _torps() -> Array: # torpedo salvos in flight: they strike at the start of the firing side's next turn
	var o := []
	for s in (R.B["torps"] if R.B.get("torps") != null else []):
		o.append({"id": s["id"], "side": s["side"], "by": s["by"], "target": s["tid"], "aim": {"q": int(s["aim"]["q"]), "r": int(s["aim"]["r"])}, "from": {"q": int(s["from"]["q"]), "r": int(s["from"]["r"])}, "round": int(s["r"])})
	return o

# Everything that happened since the last call, in order (API.md lists the event types).
func take_events() -> Array:
	_enter()
	var r = _i_take_events(); _leave(false); return r
func _i_take_events() -> Array:
	var e = R.events; R.events = []; return e

# ---------------- previews for the UI (no state change) ----------------
func reach(id: String) -> Array:
	_enter()
	var r = _i_reach(id); _leave(false); return r
func _i_reach(id: String) -> Array:          # every end state the ship can move to: {q, r, f, cost, t, path}
	var u = unit(id)
	if u == null or not _can_use(u): return []
	return R.computeReach(u).states
func can_fire(id: String, wi: int, target_id: String) -> bool:
	_enter()
	var r = _i_can_fire(id, wi, target_id); _leave(false); return r
func _i_can_fire(id: String, wi: int, target_id: String) -> bool:
	var u = unit(id); var t = unit(target_id)
	return u != null and t != null and R.canFire(u, u["weapons"][wi], t)
func preview_fire(id: String, wi: int, target_id: String) -> Dictionary:
	_enter()
	var r = _i_preview_fire(id, wi, target_id); _leave(false); return r
func _i_preview_fire(id: String, wi: int, target_id: String) -> Dictionary:   # hit %, expected shield and hull damage, facing quadrant
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

# state: one of reach(id). opts.late_fire = {weapons: [indices], target: id} fires those guns during the burn, as the game's
# attack-move does (about two-thirds of the way along; the move event then has late_fire true and the fire events follow it).
func move(id: String, state: Dictionary, opts: Dictionary = {}) -> bool:
	_enter()
	if halted != "": var h = false; _leave(false); return h
	var r = _i_move(id, state, opts); _leave(true); return r
func _i_move(id: String, state: Dictionary, opts: Dictionary = {}) -> bool:
	var u = unit(id)
	if not _guard(u): return false
	R.B["busy"] = true
	var lf = opts.get("late_fire")
	if lf != null:
		var t = unit(lf.get("target")); var idx = lf.get("weapons", [])
		R.moveUnit(u, state, {"onLate": func():
			var live = R.liveFrom(u)
			if t == null: return
			var fs = []
			for i in idx:
				if R.canFire(u, u["weapons"][int(i)], t): fs.append(int(i))
			for i in fs:
				if R.jt(t.get("dead")) or R.jt(u.get("dead")) or R.jt(R.B.get("over")) or not live.call(): break
				R.fireWeapon(u, i, t)})
	else: R.moveUnit(u, state)
	_after_act(); return true
# ui3d.js attackMovePlan: the best reachable state from which the given guns (default: every ready gun but flak) reach the target.
# Returns {state, guns, of} or null. attack_move(id, target_id) burns there and opens fire on the way, as tapping an enemy does.
func attack_plan(id: String, target_id: String, weapons = null) -> Variant:
	_enter()
	var r = _i_attack_plan(id, target_id, weapons); _leave(false); return r
func _i_attack_plan(id: String, target_id: String, weapons = null) -> Variant:
	var s = unit(id); var t = unit(target_id)
	if s == null or t == null or R.jt(s.get("isSq")) or R.jt(s.get("braced")) or R.jt(t.get("dead")): return null
	var idx = []
	for i in (weapons if weapons != null else range(s["weapons"].size())):
		var w = s["weapons"][int(i)]
		if w["k"] != "flak" and R.weaponReady(w): idx.append(int(i))
	if idx.size() == 0: return null
	var best = null
	R.eval_begin()
	for st in R.computeReach(s).states:
		if st.q == s["q"] and st.r == s["r"]: continue
		var v = R.stateView(s, st); var n = 0
		for i in idx:
			if R.inReach(v, s["weapons"][i], t): n += 1
		if n == 0: continue
		var hx = 0
		for p in st.get("path", []):
			if not R.jt(p.get("rot")): hx += 1
		var sc = n * 100 - st.cost * 3 - R.z0(st.get("t")) + (4 if hx >= 2 else 0)
		if best == null or sc > best.sc: best = {"state": st, "guns": n, "sc": sc, "of": idx.size()}
	R.eval_end()
	return best
func attack_move(id: String, target_id: String, weapons = null) -> bool:
	_enter()
	if halted != "": var h = false; _leave(false); return h
	var r = _i_attack_move(id, target_id, weapons); _leave(true); return r
func _i_attack_move(id: String, target_id: String, weapons = null) -> bool:
	var s = unit(id)
	if s == null or s["side"] != "player" or not _can_use(s): return false
	var am = attack_plan(id, target_id, weapons)
	if am == null: return false
	var idx = weapons if weapons != null else range(s["weapons"].size())
	return move(id, am.state, {"late_fire": {"weapons": idx, "target": target_id}})
func fire(id: String, wi: int, target_id: String, called_section = null) -> bool:
	_enter()
	if halted != "": var h = false; _leave(false); return h
	var r = _i_fire(id, wi, target_id, called_section); _leave(true); return r
func _i_fire(id: String, wi: int, target_id: String, called_section = null) -> bool:
	var u = unit(id); var t = unit(target_id)
	if t == null or not _guard(u): return false
	R.B["busy"] = true; var ok = R.fireWeapon(u, wi, t, {"called": called_section} if called_section != null else {}); _after_act(); return ok
func ability(id: String, arg = null) -> bool:
	_enter()
	if halted != "": var h = false; _leave(false); return h
	var r = _i_ability(id, arg); _leave(true); return r
func _i_ability(id: String, arg = null) -> bool:       # arg: {hex: {q, r}} for nova, blink and launch; {kind} for launch
	var u = unit(id)
	if not _guard(u): return false
	R.B["busy"] = true; var ok = R.useAbility(u, arg); _after_act(); return ok
func order(id: String, kind: String) -> bool:
	_enter()
	if halted != "": var h = false; _leave(false); return h
	var r = _i_order(id, kind); _leave(true); return r
func _i_order(id: String, kind: String) -> bool:       # "brace" | "full" | "lock" | "helm"
	var u = unit(id)
	if not _guard(u) or not R.canOrder(u, kind): return false
	R.B["busy"] = true; R.giveOrder(u, kind); _after_act(); return true
func ram(id: String) -> bool:
	_enter()
	if halted != "": var h = false; _leave(false); return h
	var r = _i_ram(id); _leave(true); return r
func _i_ram(id: String) -> bool:
	var u = unit(id)
	if not _guard(u): return false
	R.B["busy"] = true; var ok = R.ramUnit(u); _after_act(); return ok
func board(id: String, target_id: String) -> bool:
	_enter()
	if halted != "": var h = false; _leave(false); return h
	var r = _i_board(id, target_id); _leave(true); return r
func _i_board(id: String, target_id: String) -> bool:
	var u = unit(id); var t = unit(target_id)
	if t == null or not _guard(u): return false
	R.B["busy"] = true; var ok = R.boardUnit(u, t); _after_act(); return ok
func rotate(id: String, dir: int) -> bool:
	_enter()
	if halted != "": var h = false; _leave(false); return h
	var r = _i_rotate(id, dir); _leave(true); return r
func _i_rotate(id: String, dir: int) -> bool:          # +1 or -1: turn in place
	var u = unit(id)
	if not _guard(u): return false                  # as the game: the ship becomes the active one even if it cannot turn
	var ok = R.canRotate(u)
	R.B["busy"] = true; R.rotateUnit(u, dir); _after_act(); return ok
# A standing order for one of your wings (ui3d.js wing select then tap): an enemy ship = strike it until it dies,
# one of your own ships = guard it. Pass target_id = null to do nothing. Orders take effect in the wing's next swarm phase.
func wing_order(wing_id: String, target_id: String) -> bool:
	_enter()
	if halted != "": var h = false; _leave(false); return h
	var r = _i_wing_order(wing_id, target_id); _leave(true); return r
func _i_wing_order(wing_id: String, target_id: String) -> bool:
	var w = unit(wing_id); var u = unit(target_id)
	if phase == "over" or w == null or u == null or w["side"] != "player" or not R.jt(w.get("isSq")) or R.jt(w.get("dead")): return false
	if is_same(u, w) or (u["side"] == "player" and R.jt(u.get("isSq"))): return false
	w["wingOrder"] = {"kind": "strike" if u["side"] == "enemy" else "guard", "id": u["id"]}
	if R.jt(R.B.get("usage")): R.B["usage"]["wingOrders"] = R.z0(R.B["usage"].get("wingOrders")) + 1
	R.hook("wing order", w); return true
# B4 wing doctrines: a carrier's stance for its wings ("strike", "screen" or "hunt"), one free change per round (ACT.stance)
func stance(id: String, st: String) -> bool:
	_enter()
	if halted != "": var h = false; _leave(false); return h
	var r = _i_stance(id, st); _leave(true); return r
func _i_stance(id: String, st: String) -> bool:
	var u = unit(id)
	if phase != "player" or u == null or u["side"] != "player" or R.jt(R.B.get("busy")) or R.jt(R.B.get("over")) or not R.canStance(u): return false
	return R.setStance(u, st)
func can_command() -> bool:
	_enter()
	var r = _i_can_command(); _leave(false); return r
func _i_can_command() -> bool: return phase == "player" and R.canCommand("player")
func command() -> bool:
	_enter()
	if halted != "": var h = false; _leave(false); return h
	var r = _i_command(); _leave(true); return r
func _i_command() -> bool:                             # the Admiral's Command (once per battle, from round 1)
	if not can_command() or R.jt(R.B.get("busy")): return false
	R.B["busy"] = true; var ok = R.useCommand("player"); _after_act(); return ok
# ---------------- previews and the threat map (read-only, fresh copies) ----------------
# compute_reach(id) -> {states: [...], map: {"q,r": state}}: every end state the ship can move to (reach() returns the states only).
func compute_reach(id: String) -> Dictionary:
	_enter()
	var r = _i_compute_reach(id); _leave(false); return r
func _i_compute_reach(id: String) -> Dictionary:
	var u = unit(id)
	if u == null: return {"states": [], "map": {}}
	return R.computeReach(u).duplicate(true)
# state_view(id, state) -> a copy of the ship as it would stand at one of compute_reach's states (q, r, facing, hexes moved).
func state_view(id: String, state: Dictionary) -> Dictionary:
	_enter()
	var r = _i_state_view(id, state); _leave(false); return r
func _i_state_view(id: String, state: Dictionary) -> Dictionary:
	var u = unit(id)
	if u == null: return {}
	var v = R.stateView(u, state); var o = v.duplicate(false); o.erase("__view"); return o
# in_reach(id, wi, target_id, state = null) -> range, arc and line of sight for gun wi on the target, from the ship's hex or from a state.
func in_reach(id: String, wi: int, target_id: String, state = null) -> bool:
	_enter()
	var r = _i_in_reach(id, wi, target_id, state); _leave(false); return r
func _i_in_reach(id: String, wi: int, target_id: String, state = null) -> bool:
	var u = unit(id); var t = unit(target_id)
	if u == null or t == null or wi < 0 or wi >= u["weapons"].size(): return false
	var v = R.stateView(u, state) if state != null else u
	return R.inReach(v, u["weapons"][wi], t)

# ---------------- UI state for one ship (read-only, fresh copies) ----------------
# ui_info(id): everything the ship's buttons, tooltips and target markers need, so the scene never reads rules.gd directly.
#   orders {brace, full, lock, helm}: can give it; rotate, stance, command: can use; ram: the run-up {target, path, dmg, recoil, soak, section} or null;
#   board: [{target, chance, kill, loss, capture}]; ability {id, ready, cooldown, hexes: [{q, r}] for nova, blink and launch};
#   weapons: [{i, ready, targets: [{id, can, range, inRange, inArc, los, hit, shield, hull, quad, rear, dmgMult}]}] against every living enemy.
func ui_info(id: String) -> Dictionary:
	_enter()
	var r = _i_ui_info(id); _leave(false); return r
func _i_ui_info(id: String) -> Dictionary:
	if _ui_ver != version: _ui_cache.clear(); _ui_ver = version
	if not _ui_cache.has(id): _ui_cache[id] = _ui_info_raw(id)
	return _ui_cache[id].duplicate(true)
func _ui_info_raw(id: String) -> Dictionary:
	var u = unit(id)
	if u == null: return {}
	var o := {"orders": {}, "rotate": R.canRotate(u), "stance": R.canStance(u), "command": can_command()}
	for k in ["brace", "full", "lock", "helm"]: o["orders"][k] = R.canOrder(u, k)
	var ri = R.ramInfo(u)
	if ri != null:
		var e = R.ramEstimate(u, ri.t, ri.path.size())
		o["ram"] = {"target": ri.t["id"], "path": ri.path.duplicate(true), "dmg": e.dmg, "recoil": e.recoil, "soak": e.soak, "section": e.sec}
	else: o["ram"] = null
	var bl := []
	for t in R.boardTargets(u):
		var b = R.boardOdds(u, t); bl.append({"target": t["id"], "chance": b.chance, "kill": b.kill, "loss": b.loss, "capture": b.capture})
	o["board"] = bl
	var hx := []
	if u.get("ab") == "nova": hx = R.novaTargets(u)
	elif u.get("ab") == "blink": hx = R.blinkHexes(u)
	elif u.get("ab") == "launch": hx = R.launchHexes(u)
	var hs := []
	for h in hx: hs.append({"q": int(h.q), "r": int(h.r)})
	o["ability"] = {"id": u.get("ab"), "ready": R.canAbility(u) if not R.jt(u.get("dead")) else false, "cooldown": u.get("abCd"), "hexes": hs}
	var ws := []
	var foes := []
	for t in R.alive("enemy" if u["side"] == "player" else "player"): foes.append(t)
	for i in range(u["weapons"].size()):
		var w = u["weapons"][i]; var ts := []
		for t in foes:
			var d = R.hdist(u, t); var e = R.expectedVs(u, w, t)
			ts.append({"id": t["id"], "can": R.canFire(u, w, t), "range": d, "inRange": d >= 1 and d <= w["r"], "inArc": R.inArc(u, t, w["arc"]), "los": R.los(u, t),
				"hit": R.hitChance(u, w, t), "shield": e.shield, "hull": e.hull, "quad": e.quad, "rear": e.rear, "dmgMult": R.dmgMult(u, w, t, e.rear)})
		ws.append({"i": i, "ready": R.weaponReady(w), "targets": ts})
	o["weapons"] = ws
	return o
# threat_map(only_id = null) -> {"q,r": damage}: the game's threat overlay (ui3d.js computeThreat). For every living enemy ship (or only
# the given one), each hex it could reach and face this turn, the raw damage of its guns (ready or ready next turn) that reach the hex in
# arc with line of sight, taking the best end state per ship and summing over ships.
func threat_map(only_id = null) -> Dictionary:
	_enter()
	var r = _i_threat_map(only_id); _leave(false); return r
func _i_threat_map(only_id = null) -> Dictionary:
	if _threat_ver != version: _threat_cache.clear(); _threat_ver = version
	var ck = str(only_id)
	if not _threat_cache.has(ck): _threat_cache[ck] = _threat_map_raw(only_id)
	return _threat_cache[ck].duplicate()
func _threat_map_raw(only_id = null) -> Dictionary:
	var out := {}
	var hexes = R.boardHexes()
	var list = []
	if only_id != null:
		var o = unit(only_id)
		if o != null: list = [o]
	else: list = R.alive("enemy")
	R.eval_begin()
	var losC := {}
	for e in list:
		var ws = []
		for w in e["weapons"]:
			if R.le(w.get("off"), 1) and R.le(w.get("cdLeft"), 1): ws.append(w)   # JS: undefined <= 1 is false (B-20 refits never count)
		if ws.size() == 0: continue
		var seen := {}; var states = []
		var all = [{"q": e["q"], "r": e["r"], "f": e["facing"], "cost": 0, "path": []}]
		if not R.jt(e.get("isSq")): all += R.computeReach(e).states
		for st in all:
			var k = str(int(st.q)) + "," + str(int(st.r)) + "," + str(int(st.f))
			if seen.has(k): continue
			seen[k] = true; states.append(st)
		var per := {}; var maxR = 0.0; var mul = e["dmg"] if R.jt(e.get("dmg")) else 1
		for w in ws: maxR = max(maxR, w["r"])
		for st in states:
			var v = R.stateView(e, st); var fk = str(int(st.q)) + "," + str(int(st.r)) + "|" + str(maxR)
			var lc = losC.get(fk)
			if lc == null:
				lc = {"near": [], "los": {}}
				for h in hexes:
					var d = R.hdist(v, h)
					if d <= maxR: lc["near"].append({"h": h, "d": d, "k": R.hkey(h.q, h.r)})
				losC[fk] = lc
			for n in lc["near"]:
				var val = 0.0
				for w in ws:
					if n.d > w["r"] or not R.inArc(v, n.h, w["arc"]): continue
					val += w["shots"] * w["dmg"] * mul
				if val == 0.0: continue
				var l = lc["los"].get(n.k)
				if l == null:
					l = R.los(v, n.h); lc["los"][n.k] = l
				if l and val > float(per.get(n.k, 0.0)): per[n.k] = val
		for k in per.keys(): out[k] = float(out.get(k, 0.0)) + per[k]
	R.eval_end()
	return out
# world_info(): what the scene needs to build the battlefield beyond view(): the biome (rock kind, planet, station look) and the battle seed.
func world_info() -> Dictionary:
	_enter()
	var r = _i_world_info(); _leave(false); return r
func _i_world_info() -> Dictionary:
	var B = R.B
	return {"biome": B["biome"].duplicate(true) if B.get("biome") is Dictionary else B.get("biome"), "seed": B.get("seed"), "shape": B.get("shape"), "well": B["well"].duplicate(true) if B.get("well") is Dictionary else B.get("well")}

# ---------------- the game's own player-side AI ----------------
# ai_activate(id): one player ship acts on its own, as the game's battle sim plays your side (sim3d.js botUnit: the Admiral's
# Command when it pays, abilities, rams, boarding, the best move for its guns and the objective, every gun at its best target,
# brace when hurt), plus one turn in place when no gun bears. It goes through the same commands as the player, so the
# activation then ends as usual (alternating mode). The game's enemy AI (aiUnit) only ever plays the enemy side.
# Stops early if the enemy phase starts or the round changes.
func ai_activate(id: String) -> void:
	_enter()
	if halted != "": _leave(false); return
	_i_ai_activate(id); _leave(true)
func _i_ai_activate(id: String) -> void:
	var u = unit(id)
	if u == null or u["side"] != "player" or phase != "player": return
	_ai_activate(u)
func _botObj(v) -> float:
	var o = R.B.get("obj")
	if o == null: return 0.0
	if o.type == "hold": return R.hdist(v, o.hex) * 1.6
	if o.type == "break": return max(0.0, o.exitC - (v.q + floor(v.r / 2.0))) * 6.0
	if o.type == "defend": return max(0.0, R.hdist(v, o.hex) - 3) * 1.2
	if o.type == "intercept":
		var tr = []
		for x in R.alive("enemy"):
			if R.jt(x.get("transport")): tr.append(x)
		return R._mind(v, tr) * 2.5 if tr.size() > 0 else 0.0
	if o.type == "hunt":
		for x in R.alive("enemy"):
			if R.jt(x.get("flagship")): return R.hdist(v, x) * 2.5
		return 0.0
	return 0.0
func _ai_activate(u) -> void:
	var r0 = R.B["round"]
	var gone = func(): return R.jt(R.B.get("over")) or R.jt(u.get("dead")) or R.jt(u.get("activated")) or R.B["side"] != "player" or phase != "player" or R.B["round"] != r0
	if gone.call(): return
	if R.canStance(u): R.aiStance(u)
	if R.canCommand("player") and not R.jt(R.B.get("busy")):
		var c = R.commandFor("player"); var pl = []; var en = []
		for x in R.alive("player"):
			if not R.jt(x.get("isSq")): pl.append(x)
		for x in R.alive("enemy"):
			if not R.jt(x.get("isSq")): en.append(x)
		if c != null and pl.size() > 0 and en.size() > 0:
			var near = 0
			for e in en:
				for p in pl:
					if R.hdist(p, e) <= 8:
						near += 1; break
			var hp = 0.0; var mx = 0.0; var hurt = false
			for p in pl:
				hp += p["hp"]; mx += p["maxHp"]
				if p["hp"] < p["maxHp"] * 0.5: hurt = true
			var hpR = hp / mx; var id = c["id"]; var off = id in ["barrage", "hunt", "scramble", "surge"]
			if (off and (near >= 2 or R.B["round"] >= 4)) or (id == "restore" and hpR < 0.6) or (id == "iron" and (hurt or near >= 2)) or R.B["round"] >= 6:
				command()
	if gone.call(): return
	if R.jt(u.get("ab")) and R.canAbility(u) and _can_use(u):
		var arg = null; var skip = false
		if u["ab"] == "launch":
			var hs = R.launchHexes(u)
			if hs.size() > 0: arg = {"hex": hs[0], "kind": ("fighter" if R.rnd() < 0.5 else "bomber") if u["fac"] == "voidsworn" else R.wingKind(u)}
			else: skip = true
		elif u["ab"] == "nova":
			skip = true
			for h in R.novaTargets(u):
				var e1 = false; var p1 = false
				for e in R.alive("enemy"):
					if R.hdist(e, h) <= 1: e1 = true
				for p in R.alive("player"):
					if R.hdist(p, h) <= 1: p1 = true
				if e1 and not p1:
					arg = {"hex": h}; skip = false; break
		if not skip: ability(u["id"], arg)
	if gone.call(): return
	if not R.jt(u.get("isSq")) and R.ramInfo(u) != null: _bot_act(u, func(): return R.tacticRam(u))
	if gone.call(): return
	var foes = R.alive("enemy")
	if foes.size() == 0: return
	var states = R.computeReach(u).states; var best: Variant = null; var bs = -1e9
	R.eval_begin()
	for s in states:
		var v = R.stateView(u, s); var off2 = R.evalOffense(v, R.readyList(u), foes); var th = R.evalThreat(v, foes)
		var nd = R._mind(v, foes); var sc = off2 - th * 0.3 - (0.0 if off2 > 0 else nd * 3.0) - _botObj(v) - R.torpThreat(u, v) * 0.9 - R.syncPull(u, v) * 1.5
		if sc > bs:
			bs = sc; best = s
	R.eval_end()
	if best != null and best.path.size() > 0: move(u["id"], best)
	if gone.call(): return
	var canAny = false
	for w in u["weapons"]:
		if not R.weaponReady(w): continue
		for t in R.alive("enemy"):
			if R.canFire(u, w, t):
				canAny = true; break
		if canAny: break
	if not canAny and R.canRotate(u): rotate(u["id"], 1)
	if gone.call(): return
	if not R.jt(u.get("isSq")) and R.boardTargets(u).size() > 0:
		var b = _bot_act(u, func(): return R.tacticBoard(u))
		if R.jt(b):
			if not gone.call(): end_activation(u["id"])
			pass; return
	for i in range(u["weapons"].size()):
		if gone.call(): return
		var bt = null; var bv = 0.0
		for t in R.alive("enemy"):
			if R.canFire(u, u["weapons"][i], t):
				var e = R.expectedVs(u, u["weapons"][i], t); var v = e.hull + e.shield * 0.3 + (20.0 if e.hull >= t["hp"] else 0.0)
				if v > bv:
					bv = v; bt = t
		if bt != null: fire(u["id"], i, bt["id"])
		pass
	if gone.call(): return
	var anyFired = false
	for w in u["weapons"]:
		if R.jt(w.get("fired")): anyFired = true
	if not R.jt(u.get("isSq")) and not anyFired and u["hp"] < u["maxHp"] * 0.5 and R.canOrder(u, "brace") and R.evalThreat(u, R.alive("enemy")) > 10: order(u["id"], "brace")
	if not gone.call() and not R.jt(u.get("isSq")) and R.canFade(u): _bot_act(u, func(): return R.fadeMove(u))
	if not gone.call(): end_activation(u["id"])

# A rules call run as one player action, with the same guard and auto end as the commands (ai_activate's rams and boarding).
func _bot_act(u, fn: Callable) -> Variant:
	if not _guard(u): return null
	R.B["busy"] = true; var r = fn.call(); _after_act(); return r
func hurry() -> void:
	_enter()
	if halted != "": _leave(false); return
	_i_hurry(); _leave(true)
func _i_hurry() -> void:                               # Enter or Space: presentation only, the rules do not change
	pass

# ui3d.js endActivation: the acting ship (or the given one, as "Pass") is done, then the enemy side takes its step
func end_activation(id = null) -> void:
	_enter()
	if halted != "": _leave(false); return
	_i_end_activation(id); _leave(true)
func _i_end_activation(id = null) -> void:
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
	_enter()
	if halted != "": var h = take_events(); _leave(false); return h
	var r = _i_step(); _leave(true); return r
func _i_step() -> Array:
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
	return e

# ---------------- Classic mode (cfg.alt = false): whole turns, ui3d.js endTurn ----------------
# The player moves and fires with any ships in any order, then calls end_turn(). The enemy turn is then stepped one ship per
# step() call, exactly as battle.js aiTurn orders it: its squadrons first, then each next ship picked by opportunity.
func end_turn() -> void:
	_enter()
	if halted != "": _leave(false); return
	_i_end_turn(); _leave(true)
func _i_end_turn() -> void:
	var B = R.B
	if _alt or phase != "player" or R.jt(B.get("over")) or R.jt(B.get("busy")): return
	B["busy"] = true; B["sel"] = null; B["armed"] = null; B["mode"] = null; B["inspect"] = null; B["reach"] = null
	B["side"] = "enemy"; R.emit({"t": "side", "side": "enemy"})
	R.turnStart("enemy")
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
	R.turnStart("player")
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
	R.roundStartBoth()   # battle.js owns the round start: ticks for both sides, then travelling torpedoes
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
