# Issue 1450 (Ryan, Nov 21 2026, R376): undo a move before firing, through the rules API the battle scene uses.
#   godot --headless --path godot --script res://rules/test/undo_test.gd
# Checks, each printed PASS or FAIL:
#   1. move then undo puts the whole battle state back (every unit, B.usage.moves, the log, the id counter) and the dice untouched;
#      the ship is free again, so another ship may go first
#   2. move, undo, the same move again gives exactly the state of the first move
#   3. a free turn (treeFreeTurn) taken and undone gives the free turn back; a pivot turn gives pivotUsed back
#   4. whole battles played with move, undo, move for every player move end in exactly the same state and dice as without
#   5. undo is refused after a shot, fire on the move (dice), a ram, a boarding, an ability, an order, the Command, after the
#      ship ends, in the enemy phase, and after any other change anywhere (another ship's hull, a log line)
# The browser twin (battle.js) is checked by the parity fixtures s1450_undo, s1450_undo_chorus and s1450_undo_classic.
extends SceneTree
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "shadowed_variable", "shadowed_variable_base_class", "shadowed_global_identifier", "unused_variable", "unused_parameter", "integer_division", "narrowing_conversion", "confusable_local_declaration", "confusable_local_usage", "return_value_discarded", "incompatible_ternary")
const API = preload("res://rules/battle_api.gd")
const JSM = preload("res://rules/jsm.gd")

var fails := 0
func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok: fails += 1

func fresh(name: String) -> Variant:
	var api = API.new(); var err = api.load_rules()
	if err != "": printerr(err); return null
	api.new_battle_scenario(name)
	api.R.UNDO_ON = true   # what battle_api.new_battle sets for the game
	return api

# the whole battle state as the parity records hash it (B without the UI busy counter, every unit, the id counter) plus the dice
func state(api) -> String:
	var R = api.R; var parts := PackedStringArray()
	for u in R.B["units"]: parts.append(JSM.canon(u, "u", {"t": 1, "ship": 1}))
	return JSM.canon(R.B, "b", {"units": 1, "cfg": 1, "prog": 1}) + "|" + ",".join(parts) + "|" + str(R.UID) + "|rng " + str(JSM.rng_u32())

func first_ready(api) -> Variant:
	for u in api.R.alive("player"):
		if not api.R.jt(u.get("isSq")) and not api.R.jt(u.get("activated")) and api._can_use(u): return u
	return null

func a_move(api, u) -> Variant:   # the reach state furthest along, so the move changes hex, facing and movement
	var best = null
	for s in api.reach(u["id"]):
		if s.path.size() > 0 and (best == null or s.cost > best.cost): best = s
	return best

func a_short_move(api, u) -> Variant:   # a one-hex move that leaves movement, so the activation does not end by itself
	for s in api.reach(u["id"]):
		if s.path.size() == 1 and not api.R.jt(s.path[0].get("rot")) and s.cost < u["mp"]: return s
	return a_move(api, u)

func a_ram_move(api, u) -> Variant:   # a move after which the ship can ram straight ahead (looked at with the ship put there for a moment)
	var R = api.R; var keep = [u["q"], u["r"], u["facing"], u["mp"]]
	var found = null
	for s in api.reach(u["id"]):
		if s.path.size() == 0 or s.cost >= keep[3]: continue
		u["q"] = s.q; u["r"] = s.r; u["facing"] = s.f; u["mp"] = keep[3] - s.cost
		var ok = R.ramInfo(u) != null
		u["q"] = keep[0]; u["r"] = keep[1]; u["facing"] = keep[2]; u["mp"] = keep[3]
		if ok: found = s; break
	return found

func run_enemy(api) -> void:
	var g := 0
	while api.phase == "enemy" and g < 400:
		g += 1; api.step()

func _init() -> void:
	# 1 and 2: the round trip
	var api = fresh("s1")
	var u = first_ready(api); var st = a_short_move(api, u)
	var s0 := state(api); var moves0 = api.R.B["usage"]["moves"]
	api.move(u["id"], st)
	var s1 := state(api)
	check(s1 != s0 and api.can_undo(u["id"]), "1a. a move can be undone")
	check(api.R.B["usage"]["moves"] == moves0 + 1, "1b. the move counted")
	check(api.undo(u["id"]), "1c. undo answers true")
	check(state(api) == s0, "1d. the whole battle state and the dice are exactly as before the move")
	check(api.R.B.get("activeUnit") == null, "1e. the ship is free again (no ship mid-activation)")
	var evs = api.take_events(); var und = evs.filter(func(e): return e.t == "undo")
	check(und.size() == 1 and und[0].q == int(u["q"]) and und[0].r == int(u["r"]) and und[0].f == int(u["facing"]), "1f. an undo event names where the ship stands")
	check(not api.can_undo(u["id"]) and not api.undo(u["id"]), "1g. nothing left to undo")
	api.move(u["id"], st)
	check(state(api) == s1, "2. the same move again gives exactly the first move's state")
	var other = null
	for x in api.R.alive("player"):
		if not api.R.jt(x.get("isSq")) and not is_same(x, u): other = x; break
	api.undo(u["id"])
	var om = a_short_move(api, other)
	api.move(other["id"], om)
	check(api.R.B.get("activeUnit") != null and is_same(api.R.B["activeUnit"], other), "1h. after undo another ship can go first")
	api.undo(other["id"])

	# 3: a free turn and a pivot turn
	api = fresh("s1"); u = first_ready(api)
	u["treeFreeTurn"] = 1
	var s3 := state(api); var mp0 = u["mp"]
	api.rotate(u["id"], 1)
	check(int(u.get("treeFreeTurn", 0)) == 0 and u["mp"] == mp0 and api.can_undo(u["id"]), "3a. a free turn is spent without movement and can be undone")
	api.undo(u["id"])
	check(state(api) == s3 and int(u.get("treeFreeTurn", 0)) == 1, "3b. undo gives the free turn back (whole state equal)")
	api = fresh("s53"); u = first_ready(api)
	var s3c := state(api)
	api.rotate(u["id"], 1)
	check(api.R.jt(u.get("pivotUsed")) and api.can_undo(u["id"]), "3c. a Chorus pivot turn sets pivotUsed and can be undone")
	api.undo(u["id"])
	check(state(api) == s3c and not api.R.jt(u.get("pivotUsed")), "3d. undo gives the pivot back (whole state equal)")
	api.rotate(u["id"], 1); api.rotate(u["id"], 1)
	check(api.R.undoDepth(u) == 2, "3e. two turns, two steps to undo")
	api.undo(u["id"]); api.undo(u["id"])
	check(state(api) == s3c, "3f. both undone, one at a time")

	# 4: identical dice afterwards, whole battles
	for name in ["s1", "s3", "s53", "s8"]:
		var a = play(name, false); var b = play(name, true)
		check(a[0] == b[0] and a[1] > 0, "4. %s: %d player moves each undone and made again; final state and dice identical (%s)" % [name, b[1], a[2]])

	# 5: refusals
	var seen := {}
	for name in ["s1", "s3", "s6", "s8", "s9", "s4", "s33"]:   # s33 added for the boarding refusal: R414 (option C) changed s9's enemy fleet, so its boarding chance went away
		refusals(name, seen)
	for k in ["fire", "attack_move", "ram", "board", "ability", "order", "command", "ended", "enemy phase", "other ship changed", "log line"]:
		check(int(seen.get(k, 0)) > 0 and int(seen.get(k + " bad", 0)) == 0, "5. undo refused after %s (%d cases, %d wrongly allowed)" % [k, int(seen.get(k, 0)), int(seen.get(k + " bad", 0))])
	print("undo test: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(0 if fails == 0 else 1)

# a simple bot (move furthest, fire every gun, end); with undo every move is taken back and made again
func play(name: String, undo: bool) -> Array:
	var api = fresh(name); var R = api.R; var n := 0; var g := 0
	while api.phase != "over" and g < 600:
		g += 1
		if api.phase == "enemy": run_enemy(api); continue
		var u: Variant = first_ready(api)
		if u == null: api.end_activation(); continue
		var st: Variant = a_move(api, u)
		if st != null:
			api.move(u["id"], st)
			if undo and api.can_undo(u["id"]):
				api.undo(u["id"]); api.move(u["id"], st); n += 1
		for i in range(u["weapons"].size()):
			if R.jt(R.B.get("over")) or R.jt(u.get("dead")) or R.jt(u.get("activated")) or api.phase != "player": break
			for t in R.alive("enemy"):
				if R.canFire(u, u["weapons"][i], t): api.fire(u["id"], i, t["id"]); break
		if api.phase == "player" and not R.jt(u.get("activated")) and not R.jt(R.B.get("over")): api.end_activation(u["id"])
	return [state(api), n if undo else 1, "%s after round %d" % [str(R.B.get("over")), int(R.B["round"])]]

# each player activation: move, then one irreversible step, then undo must be refused (and must not change anything)
func refusals(name: String, seen: Dictionary) -> void:
	var api = fresh(name); var R = api.R; var g := 0; var k := 0
	var tally = func(kind: String, u) -> void:
		seen[kind] = int(seen.get(kind, 0)) + 1
		var s := state(api)
		if api.can_undo(u["id"]) or api.undo(u["id"]) or state(api) != s: seen[kind + " bad"] = int(seen.get(kind + " bad", 0)) + 1
	while api.phase != "over" and g < 600:
		g += 1
		if api.phase == "enemy":
			if k > 0 and R.B["side"] == "player":
				pass
			run_enemy(api); continue
		var u: Variant = first_ready(api)
		if u == null: api.end_activation(); continue
		k += 1
		var st: Variant = a_move(api, u)
		if st == null:
			api.end_activation(u["id"]); continue
		# fire on the move first when an enemy is out of reach of every gun (dice during the burn)
		if api._alt and k % 5 == 0:
			var es = R.alive("enemy").filter(func(x): return not R.jt(x.get("isSq")))
			if es.size() > 0 and api.attack_plan(u["id"], es[0]["id"]) != null:
				var am = api.attack_plan(u["id"], es[0]["id"])
				var rng0 := JSM.rng_u32()
				api.attack_move(u["id"], es[0]["id"])
				if JSM.rng_u32() != rng0 and not R.jt(u.get("dead")): tally.call("attack_move", u)
				if api.phase == "player" and not R.jt(u.get("activated")): api.end_activation(u["id"])
				continue
		var rm = a_ram_move(api, u)
		if rm != null: st = rm
		api.move(u["id"], st)
		if R.jt(u.get("activated")) or R.jt(R.B.get("over")):
			if not R.jt(R.B.get("over")): tally.call("ended", u)
			continue
		if not api.can_undo(u["id"]):
			if api.phase == "player" and not R.jt(u.get("activated")): api.end_activation(u["id"])
			continue   # the move itself already did something irreversible (a tree effect, an exit): refused, as it should be
		var done := false
		var kinds := ["other ship changed", "log line", "command", "ram", "board", "ability", "order", "fire"]
		if rm != null: kinds = ["ram"] + kinds
		var pick: String = kinds[k % kinds.size()]
		for attempt in range(kinds.size()):
			var kind: String = kinds[(k + attempt) % kinds.size()]
			match kind:
				"other ship changed":
					var e = R.alive("enemy")[0]; e["hp"] = e["hp"] - 1; tally.call(kind, u); e["hp"] = e["hp"] + 1; done = true
				"log line":
					R.logm("test line"); tally.call(kind, u); R.B["log"].pop_back(); done = true
				"command":
					if api.can_command(): api.command(); tally.call(kind, u); done = true
				"ram":
					if R.ramInfo(u) != null and api.ram(u["id"]): tally.call(kind, u); done = true
				"board":
					var bt = R.boardTargets(u)
					if bt.size() > 0 and api.board(u["id"], bt[0]["id"]): tally.call(kind, u); done = true
				"ability":
					if u.get("ab") != null and R.canAbility(u) and not (u["ab"] in ["nova", "blink", "launch"]) and api.ability(u["id"]): tally.call(kind, u); done = true
				"order":
					if R.canOrder(u, "brace") and api.order(u["id"], "brace"): tally.call(kind, u); done = true
				"fire":
					for i in range(u["weapons"].size()):
						for t in R.alive("enemy"):
							if not done and R.canFire(u, u["weapons"][i], t) and api.fire(u["id"], i, t["id"]): tally.call(kind, u); done = true
			if done: break
		if api.phase == "player" and not R.jt(u.get("activated")) and not R.jt(R.B.get("over")):
			api.end_activation(u["id"])
		if api.phase == "enemy" and not R.jt(R.B.get("over")):
			api.step()   # one enemy activation, then the refusal while the enemy acts
			if api.phase == "enemy" and not R.jt(u.get("dead")):
				seen["enemy phase"] = int(seen.get("enemy phase", 0)) + 1
				if api.can_undo(u["id"]) or api.undo(u["id"]): seen["enemy phase bad"] = int(seen.get("enemy phase bad", 0)) + 1
