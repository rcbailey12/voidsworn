# Thread test for the rules API (battle_api.gd, "Threads" in API.md). Plays a scenario twice through the API with the same simple
# player bot as api_smoke.gd: once on one thread, once with every enemy step() on a worker thread while the main thread keeps calling
# view(), ui_info(), threat_map(), compute_reach() and preview_fire(), as the battle scene does. Both runs must end with the same
# battle state (JSM canonical hash) and the same events, with no script errors and no halt.
#   godot --headless --path godot --script res://rules/test/thread_test.gd -- [scenario ...]
extends SceneTree
# The JS port keeps JS shapes (untyped Dictionaries), so these warnings are expected here and silenced for this file only.
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "shadowed_variable", "unused_variable", "unused_parameter", "confusable_local_declaration", "confusable_local_usage", "return_value_discarded", "incompatible_ternary")
const API = preload("res://rules/battle_api.gd")
const JSM = preload("res://rules/jsm.gd")

func play(name: String, threaded: bool) -> Dictionary:
	var api = API.new(); var err = api.load_rules()
	if err != "": return {"err": err}
	api.hard_stop = true
	api.new_battle_scenario(name)
	var log := []; var guard := 0; var reads := 0
	while api.phase != "over" and api.phase != "halted" and guard < 2000:
		guard += 1
		var evs := []
		if api.phase == "player":
			var v = api.view(); var me = null
			for u in v.units:
				if u.side == "player" and not u.dead and not u.activated and not u.squadron: me = u; break
			if me == null: api.end_activation(); continue
			var states = api.reach(me.id)
			if states.size() > 1: api.move(me.id, states[states.size() / 2])
			for w in me.weapons:
				for t in v.units:
					if t.side == "enemy" and not t.dead and api.can_fire(me.id, w.i, t.id):
						api.fire(me.id, w.i, t.id); break
			if api.phase == "player": api.end_activation(me.id)
			evs = api.take_events()
		elif not threaded:
			evs = api.step()
		else:
			var box := {"ev": []}
			var tid := WorkerThreadPool.add_task(func() -> void: box["ev"] = api.step())
			while not WorkerThreadPool.is_task_completed(tid):   # the scene's frame loop: read while the enemy thinks
				var v = api.view(); reads += 1
				for u in v.units:
					if not u.dead and u.side == "player":
						api.ui_info(u.id); api.compute_reach(u.id)
						for t in v.units:
							if t.side == "enemy" and not t.dead and u.weapons.size() > 0: api.preview_fire(u.id, 0, t.id); break
						break
				api.threat_map()
			WorkerThreadPool.wait_for_task_completion(tid)
			evs = box["ev"]
		for e in evs: log.append(JSON.stringify(e))
	var st = JSM.sha256(JSM.canon(api.view(), "", {}, true) + JSM.canon(api.R.B.get("log", []), "", {}, true))
	return {"phase": api.phase, "halt": api.halted, "hash": st, "events": log, "reads": reads, "round": api.R.B["round"]}

# Hard stop: a NOT PORTED rule or a rules script error halts the battle and blocks commands until the next new_battle.
func halt_check() -> int:
	var api = API.new(); api.load_rules(); api.hard_stop = true
	api.new_battle_scenario("s1")
	var bad := 0
	api.R.np("thread_test fake rule"); var v = api.view()
	var hev = api.step().filter(func(e): return e.t == "halt")
	if api.phase != "halted" or api.view().halt == null or hev.size() != 1: bad += 1
	var me = null
	for u in v.units:
		if u.side == "player" and not u.dead: me = u; break
	api.end_activation(me.id)
	if api.rotate(me.id, 1) or api.phase != "halted": bad += 1
	api.new_battle_scenario("s1")
	if api.phase == "halted" or api.halted != "": bad += 1
	api.R.not_ported = ""
	var run = {"admiral": "vex", "fac": "voidsworn", "credits": 0, "cpCap": 40, "sector": 1, "relics": [], "inventory": [], "fleet": [api.R.newShip("warden", false)], "boons": [], "patrons": [], "stats": {"battles": 0, "elites": 0, "bosses": 0, "kills": 0}, "fallen": []}
	run["flagUid"] = run["fleet"][0]["uid"]
	api.new_battle(run, {"kind": {"bad": 1}, "fac": "hegemony", "col": 3, "seed": 5, "obj": "rout", "shape": "open", "map": "open", "dep": "line"})
	if api.phase != "halted" or api.cfg_errors.size() != 1: bad += 1
	api.new_battle(run, {"kind": "battle", "seed": 5})
	if api.phase != "halted" or not api.halted.contains("fac"): bad += 1
	print("hard stop check: ", "PASS" if bad == 0 else "FAIL (%d)" % bad, " (", api.halted.left(90), ")")
	return bad

func _init() -> void:
	var names := OS.get_cmdline_user_args()
	if names.is_empty(): names = PackedStringArray(["s4", "s23"])
	var bad := halt_check()
	for name in names:
		var a := play(name, false); var b := play(name, true)
		if a.has("err") or b.has("err"):
			print("thread test ", name, ": FAIL ", a.get("err", b.get("err"))); bad += 1; continue
		var same: bool = a.hash == b.hash and a.events == b.events and a.phase == b.phase
		var ok: bool = same and a.halt == "" and b.halt == ""
		print("thread test %s: %s (%s after round %d, %d events, %d reads during enemy steps on a worker%s)" % [name, "PASS" if ok else "FAIL", b.phase, int(b.round), b.events.size(), b.reads, "" if same else "; states differ" if a.hash != b.hash else "; events differ"])
		if a.halt != "" or b.halt != "": print("  halted: ", a.halt, " | ", b.halt)
		if not ok: bad += 1
	quit(0 if bad == 0 else 1)
