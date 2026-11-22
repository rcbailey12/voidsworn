extends SceneTree
# Issue 1589 (Ryan, Nov 22 2026): plan the whole turn on the ghost, then commit, and it plays out as one event. Test battle
# s1 in the real battle scene (headless). Checks: a click on a blue hex plans (the ghost, with its outline) and the rules do
# not change; an enemy clicked while the move is planned is aimed from the ghost; a second enemy takes the guns still free;
# Backspace takes back one step at a time (the second pick, the first pick, then the move); Esc clears the plan; the commit
# sends the move and every planned volley as one batch (move first, then fire), and afterwards the ship stands on the
# planned hex. Prints PASS or FAIL lines; exit 0 when all pass.
# Run: godot --headless --path godot --script res://scenes/battle/test/plan_commit_check.gd
const BattleScene = preload("res://scenes/battle/battle.tscn")
var b
var fails := 0


func _init() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _idle() -> bool:
	return b.api != null and not b.warming and not b.busy and not b.thinking and b.batches.is_empty() and b.api.phase == "player" \
		and not b._threat_busy


func _wait_idle(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while not _idle() and Time.get_ticks_msec() - t0 < ms:
		await process_frame
	for k in 10:
		await process_frame


func _rules() -> String:
	return JSON.stringify(b.api.view())


func _enemies() -> Array:
	var out: Array = []
	for u in b.V["units"]:
		if u["side"] == "enemy" and not u["dead"]:
			out.append(str(u["id"]))
	return out


func _click_unit(id: String) -> void:
	var u: Dictionary = b.VU[id]
	_click_hex(int(u["q"]), int(u["r"]))


func _click_hex(q: int, r: int) -> void:
	b.hover = Vector2i(q, r)
	b._on_click()


func _run() -> void:
	b = BattleScene.instantiate()
	b.tips_off = true
	b.external = true
	root.add_child(b)
	b.args["scenario"] = "s1"
	b.args["seed"] = 1001
	b.start_default()
	await _wait_idle(120000)
	if not _idle():
		_check(false, "the battle reached the player's turn")
		quit(1)
		return
	# bring two enemies a few hexes ahead of the first ready ship and clear the terrain, so a short planned move puts both
	# under its guns (s1 opens with the fleets far apart). Rules fixture only; the scene reads it back from the view.
	var R = b.api.R
	var me = null
	for u in R.alive("player"):
		if not R.jt(u.get("isSq")) and not R.jt(u.get("activated")):
			me = u
			break
	R.B["terrain"].clear()
	var foes: Array = R.alive("enemy")
	var f := int(me["facing"])
	var d0: Array = R.DIRS[f]
	var d1: Array = R.DIRS[(f + 1) % 6]
	var spots := [Vector2i(int(me["q"]) + d0[0] * 4, int(me["r"]) + d0[1] * 4),
		Vector2i(int(me["q"]) + d0[0] * 4 + d1[0] * 2, int(me["r"]) + d0[1] * 4 + d1[1] * 2)]
	spots.append(Vector2i(int(me["q"]) + d0[0] * 9, int(me["r"]) + d0[1] * 9))   # a third, out of reach (Burn and fire)
	for i in mini(3, foes.size()):
		if b.api.R.onBoard(spots[i].x, spots[i].y):
			foes[i]["q"] = spots[i].x
			foes[i]["r"] = spots[i].y
	b.V = b.api.view()
	b._index_view()
	# the ship and planned hex where the most enemies come under the guns, so two picks can be made
	var ship := ""
	var best = null
	var best_n := 0
	for u in b.V["units"]:
		if u["side"] != "player" or u["dead"] or u["activated"] or u["squadron"]:
			continue
		b.select(str(u["id"]), "roster")
		await _wait_idle(5000)
		for k in b.reach_map:
			var st = b.reach_map[k]
			if int(st.q) == int(u["q"]) and int(st.r) == int(u["r"]):
				continue
			if b._unit_at(int(st.q), int(st.r)).size() > 0:
				continue
			b.plan = st
			var n := 0
			var used := {}
			for e in _enemies():
				var g: Array = b._firing_set(e)
				var fresh := false
				for i in g:
					if not used.has(int(i)):
						fresh = true
				if fresh:
					n += 1
					for i in g:
						used[int(i)] = true
			b.plan = null
			if n > best_n:
				best_n = n
				best = st
				ship = str(u["id"])
		if best_n >= 2:
			break
	_check(best != null, "a planned hex with an enemy under the guns exists (%d enemies)" % best_n)
	if best == null:
		quit(1)
		return
	b.select(ship, "roster")
	await _wait_idle(5000)
	# a turn in place is planned too, a skill's free turn included (Codex on PR 1643): E turns the ghost and nothing reaches
	# the rules; Backspace takes it back; a click on the ghost on the ship's own hex commits it through the rules' rotate,
	# which spends the free turn and no movement and leaves the move counter alone
	var ru = b.api.unit(ship)
	var mp0 = ru["mp"]
	var f0 := int(ru["facing"])
	ru["treeFreeTurn"] = 1
	var moves0 := int(b.api.R.B.get("usage", {}).get("moves", 0))
	var r0 := _rules()
	b.hover = Vector2i(99999, 99999)
	b._rotate(1)
	ru = b.api.unit(ship)
	_check(b.plan != null and b.plan.has("rot") and int(b.plan.f) == posmod(f0 + 1, 6) and _rules() == r0 and int(ru["facing"]) == f0
		and float(b._z0(ru.get("treeFreeTurn"))) == 1.0, "E turns the ghost in place; the rules and the free turn are untouched")
	b._on_key(KEY_BACKSPACE)
	_check(b.plan == null and _rules() == r0, "Backspace takes the planned turn back")
	b._rotate(1)
	_click_hex(int(ru["q"]), int(ru["r"]))
	await _wait_idle(30000)
	ru = b.api.unit(ship)
	_check(b.plan == null and int(ru["facing"]) == posmod(f0 + 1, 6) and ru["mp"] == mp0 and float(b._z0(ru.get("treeFreeTurn"))) == 0.0
		and int(b.api.R.B.get("usage", {}).get("moves", 0)) == moves0,
		"a click on the turned ghost commits it: the rules' rotate spends the free turn, no movement, and no move is counted")
	var tw := Time.get_ticks_msec()
	while not _idle() and Time.get_ticks_msec() - tw < 30000:   # the threat map restarts after the turn; undo waits for it
		await process_frame
	b._on_key(KEY_BACKSPACE)
	await _wait_idle(30000)
	ru = b.api.unit(ship)
	_check(int(ru["facing"]) == f0, "with no plan open, Backspace takes the played turn back (R376)")
	ru["treeFreeTurn"] = 0
	# a two-step turn whose middle heading leaves no movement and no shot is refused before commit: the rules would end the
	# activation after the first step (Codex run 2, Artoo on PR 1643: a free first step included)
	var keep := {"mp": ru["mp"], "turnsLeft": ru["turnsLeft"], "pivotUsed": ru.get("pivotUsed"), "fac": ru["fac"]}
	var fired_keep: Array = []
	for w in ru["weapons"]:
		fired_keep.append(w.get("fired"))
		w["fired"] = true
	ru["mp"] = 0
	ru["turnsLeft"] = 2
	ru["treeFreeTurn"] = 1
	ru["fac"] = "chorus"   # the Chorus' free pivot makes the second step legal on its own, as in Codex's fixture
	ru["pivotUsed"] = false
	var one: bool = b._turns_ok(1)
	var two: bool = b._turns_ok(2)
	_check(one and not two, "a free first turn is allowed, a second step through a dead middle heading is refused (%s, %s)" % [one, two])
	for i in ru["weapons"].size():
		ru["weapons"][i]["fired"] = fired_keep[i]
	ru["mp"] = keep["mp"]
	ru["turnsLeft"] = keep["turnsLeft"]
	ru["pivotUsed"] = keep["pivotUsed"]
	ru["fac"] = keep["fac"]
	ru["treeFreeTurn"] = 0
	b.select(ship, "roster")
	await _wait_idle(5000)
	var before := _rules()
	_click_hex(int(best.q), int(best.r))
	var bk: String = b.board.key(int(best.q), int(best.r))
	_check(b.plan != null and b.plan_k == bk, "one click on a blue hex plans the move")
	b._overlay()
	var g = b.ghost
	_check(g != null and is_instance_valid(g) and g.visible, "the ghost stands on the planned hex")
	var edged := false
	if g != null:
		for n in g.find_children("*", "MeshInstance3D", true, false):
			var m = (n as MeshInstance3D).material_override
			if m is StandardMaterial3D and m.next_pass is StandardMaterial3D and (m.next_pass as StandardMaterial3D).grow:
				edged = true
				break
	_check(edged, "the ghost has its bright outline (pick 3b)")
	# aim from the ghost
	var picks: Array = []
	for e in _enemies():
		if not b._firing_set(e).is_empty():
			_click_unit(e)
			picks.append(e)
			if picks.size() == 2:
				break
	_check(b.aims.size() == 2 and picks.size() == 2, "two enemies clicked become two picks from the ghost (%d)" % b.aims.size())
	if b.aims.size() == 2:
		var a0: Array = b.aims[0]["guns"]
		var a1: Array = b.aims[1]["guns"]
		var overlap := false
		for i in a1:
			if i in a0:
				overlap = true
		_check(not overlap, "the second pick takes only the guns still free")
	_check(_rules() == before, "planning and aiming changed nothing in the rules")
	var c: Dictionary = b._card_info()
	var go := ""
	for x in c.get("buttons", []):
		if x.get("primary", false):
			go = str(x.get("text", ""))
	_check(go.begins_with("Move and fire"), "the card's button commits the move and the fire together (%s)" % go)
	# step back, one at a time
	var n0: int = b.aims.size()
	b._on_key(KEY_BACKSPACE)
	_check(b.aims.size() == n0 - 1 and b.plan != null, "Backspace takes the last pick back and keeps the move")
	while b.aims.size() > 0:
		b._on_key(KEY_BACKSPACE)
	b._on_key(KEY_BACKSPACE)
	_check(b.plan == null and b.aims.is_empty(), "Backspace then takes the planned move back")
	_check(_rules() == before, "stepping back changed nothing in the rules")
	# Esc clears the plan
	_click_hex(int(best.q), int(best.r))
	_click_unit(picks[0])
	b._on_key(KEY_ESCAPE)
	_check(b.plan == null and b.aims.is_empty() and b.plan_steps.is_empty(), "Esc clears the whole plan")
	# plan again and commit: one batch, the move then the fire
	# a Burn and fire replaced by a planned move (Codex on PR 1643): its target is no pick, so the next enemy click aims
	var far := ""
	for e in _enemies():
		if e not in picks and b._firing_set(e).is_empty() and b._attack_move(e) != null:
			far = e
			break
	_check(far != "", "an enemy out of reach that a Burn and fire can reach exists")
	if far != "":
		_click_unit(far)
		_check(b.atk != null and b.target == far, "a click on it plans a Burn and fire")
		# Q/E with the Burn and fire planned (pointer on the target, then off the board): nothing reaches the rules
		var fu: Dictionary = b.VU[far]
		b.api.unit(ship)["treeFreeTurn"] = 1
		var rf := _rules()
		b.hover = Vector2i(int(fu["q"]), int(fu["r"]))
		b._rotate(1)
		b.hover = Vector2i(99999, 99999)
		b._rotate(-1)
		_check(b.atk != null and b.batches.is_empty() and _rules() == rf and float(b._z0(b.api.unit(ship).get("treeFreeTurn"))) == 1.0,
			"Q/E with a Burn and fire planned change nothing in the rules and keep the free turn")
		b.api.unit(ship)["treeFreeTurn"] = 0
		_click_hex(int(best.q), int(best.r))
		_check(b.atk == null and b.target == "" and b.plan != null, "a click on a blue hex replaces it with the planned move")
		_click_unit(far)
		_check(b.batches.is_empty() and _rules() == before, "a click on the old Burn and fire target commits nothing")
		while b.atk != null:
			b._on_key(KEY_BACKSPACE)
		_click_unit(picks[0])
		_check(b.aims.size() >= 1 and b.batches.is_empty() and _rules() == before, "the next enemy click aims from the ghost; nothing is committed")
		b._on_key(KEY_ESCAPE)
	_click_hex(int(best.q), int(best.r))
	for e in picks:
		_click_unit(e)
	var want_picks: int = b.aims.size()
	b._refresh_ui()
	var card_plan = b.hud._last.get("set_card", [{}])[0]
	var keys_say := str((card_plan as Dictionary).get("keys", "")) if card_plan is Dictionary else ""
	_check("Enter" in keys_say and "Backspace" in keys_say and "Esc" in keys_say, "the open plan's card names its keys on screen (%s)" % keys_say)
	# Artoo on PR 1643: the keys must be drawn, whole and on the sheet, at the compact and the full width
	var L = b.hud.ledger
	var keep_size: Vector2 = L.size
	for sz in [Vector2(1280, 720), Vector2(1920, 1080)]:
		L.size = sz
		L.layout()
		var shown := false
		for it in L.items:
			if str(it.get("role", "")) == "keys" and str(it["t"]) == keys_say and float(it["y"]) + float(it["h"]) <= sz.y:
				shown = true
		_check(shown, "at %dx%d the plan's keys are drawn whole under the action" % [int(sz.x), int(sz.y)])
	L.size = keep_size
	L.layout()
	b.hold = true
	b._confirm()
	_check(b.batches.size() == 1, "the commit makes one batch (%d)" % b.batches.size())
	var kinds: Array = []
	var hit_ids := {}
	if b.batches.size() >= 1:
		for ev in b.batches[0]["events"]:
			var t := str(ev.get("t", ""))
			if t == "fire" and str(ev.get("unit", "")) == ship:
				hit_ids[str(ev.get("target", ""))] = true
			if t in ["move", "fire"] and str(ev.get("unit", ev.get("by", ev.get("src", ship)))) == ship:
				if kinds.is_empty() or kinds[-1] != t:
					kinds.append(t)
	_check(kinds.size() >= 2 and kinds[0] == "move" and kinds[1] == "fire", "in that batch the move plays first, then the fire (%s)" % str(kinds))
	var all_fired := want_picks == picks.size()
	for e in picks:
		if not hit_ids.has(e):
			all_fired = false
	_check(picks.size() == 2 and all_fired, "every planned target is fired on in that batch (%s)" % str(hit_ids.keys()))
	_check(b.plan == null and b.aims.is_empty(), "the plan is cleared once it is sent")
	var card_now = b.hud._last.get("set_card", [{"open": true}])[0]
	_check(card_now is Dictionary and (card_now as Dictionary).is_empty(), "the card leaves as soon as the event starts (Ryan, Nov 22)")
	# issue 1708 (Ryan, Nov 22): the whole bottom ship sheet steps aside while the scene plays
	var Lp = b.hud.ledger
	Lp.layout()
	var ship_name: String = str(b._name(ship))
	var sheet_drawn := false
	for it in Lp.items:
		if str(it["t"]).to_upper() == ship_name.to_upper() and float(it["y"]) >= Lp.sheet_r.position.y:
			sheet_drawn = true
	_check(bool(Lp.playing) and not sheet_drawn, "the bottom ship sheet is hidden while the event plays (playing %s)" % str(Lp.playing))
	b.hold = false
	await _wait_idle(90000)
	var u1: Dictionary = b.VU.get(ship, {})
	Lp.layout()
	var back := false
	for it in Lp.items:
		if float(it["y"]) >= Lp.sheet_r.position.y and str(it["t"]).strip_edges() != "":
			back = true
	_check(not bool(Lp.playing) and back, "the bottom sheet pops back once the event has played")
	_check(not u1.is_empty() and int(u1["q"]) == int(best.q) and int(u1["r"]) == int(best.r), "the ship stands on the planned hex")
	_check(want_picks >= 1 and bool(u1.get("fired", false)), "the ship fired")
	var unknown: Dictionary = b.get_meta("unknown_events", {})
	_check(unknown.is_empty(), "no unknown event kind warning (%s)" % str(unknown.keys()))
	# Ryan (Nov 22): a ship on the arc's line looked outside the drawn cone. The rules count it (inArc, 60.5 degrees), so
	# each side of the drawn fan runs half a hex outside that line: the hexes on it sit wholly inside the drawing.
	var HW: float = b.board.HW
	var fan = b._fan_edge(-60.5, 60.5, 4.0 * HW + 0.5, Color.WHITE)
	var vs: PackedVector3Array = fan.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var fan_ok := vs.size() >= 12
	for side in 2:
		if not fan_ok:
			break
		var o := vs.size() - 12 + side * 6
		var p0 := Vector2((vs[o].x + vs[o + 5].x) * 0.5, (vs[o].z + vs[o + 5].z) * 0.5)
		var p1 := Vector2((vs[o + 1].x + vs[o + 2].x) * 0.5, (vs[o + 1].z + vs[o + 2].z) * 0.5)
		var ang := deg_to_rad(-60.0 if side == 0 else 60.0)
		for k in range(1, 5):
			var hc := Vector2(cos(ang), sin(ang)) * HW * k   # the centre of the k-th hex on the arc's line
			var dir := (p1 - p0).normalized()
			var dist := absf(dir.cross(hc - p0))
			if dist < HW * 0.5 - 0.05 or dist > HW * 0.6:
				fan_ok = false
				print("  fan side %d hex %d: %.2f from the line (want about %.2f)" % [side, k, dist, HW * 0.5])
	fan.free()
	_check(fan_ok, "the drawn cone's sides run along the far edge of the hexes on the arc's line, not through them")
	print("plan commit check: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(0 if fails == 0 else 1)
