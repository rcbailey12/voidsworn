extends SceneTree
# Issue 1211: every hit lands on its own shot. Plays crafted volleys through battle.gd _play_fire with the G4 effects:
#  A. [miss, miss, hit] under a deep hit pause: the HP drop, the sound and the number land when the hitting shot arrives
#     on the effect clock (the target's busy_until is that shot's planned impact), not at the first miss's time and not
#     on the wall clock; the enemy's target is ringed and named while the volley plays, and the ring clears after.
#  B. [hit, hit, hit] where the second hit empties the shield: the shield break and "Shields down" fire once, on that
#     hit, before the third hit lands (they used to wait for the whole volley).
#  D. a lance volley under the same quarter-speed clock: the charge and the shot cue run on the effect clock, so the
#     shot cue trails the charge by its lead in effect seconds and plays at or after its own planned fire time
#     (Artoo's review of PR 1220: they ran on the wall clock and could fire before the shot during slow motion).
#  E. the combined case after PR 1230 (Artoo's review of PR 1220): an Eclipse null lance [miss, hit, hit] on a Glasswright
#     ship under the quarter-speed clock, the last hit a critical. Exactly one shot cue per beam (the miss too), each on
#     its own effect fire time on the effect clock and before the hit it carries; each hit still lands on its own shot; the critical keeps the glass contact cue with
#     the heavy tail under it. Then an ion lance shield hit carrying the ion lock: the lock reaches the nameplate state
#     when the hit lands and expires at the locked ship's side turn start.
#  F. a critical the armour absorbs, then a normal hull hit: one hull label, never two "Critical" labels.
#  C. the pure helpers: hit_arrivals maps hit k to the k-th true shot; shield_break_hit picks the last absorbed hit.

const GUARD := preload("res://tools/ci/check_guard.gd")
const API := preload("res://rules/battle_api.gd")
const LOOK := preload("res://world/board_look.gd")
const Battle := preload("res://scenes/battle/battle.gd")
const TOL := 0.06   # effect seconds: a landing runs on the first effect frame at or after its planned time

class Probe extends "res://scenes/battle/battle.gd":
	var lands: Array = []    # [{k, now, hp, ring, aim}]
	var breaks: Array = []   # effect times of shield breaks
	var said: Array = []     # [text, effect time]
	var vols: Array = []     # [effect time the volley starts, its land record]

	func _aim_on(a_id, t_id, land: Dictionary) -> void:
		vols.append([float(gfx.now), land])
		super._aim_on(a_id, t_id, land)

	func _land_hit(t_id, h: Dictionary, k: int, land: Dictionary) -> void:
		# the marker as the hit arrives (the last hit lets it go inside the call)
		var sv = views.get(t_id)
		var row := {"k": k, "now": float(gfx.now), "ring": sv != null and sv.ring.visible,
			"col": (sv.ring.material_override as StandardMaterial3D).albedo_color if sv != null else Color.BLACK,
			"aim": {"a": aim.get("a", ""), "t": aim.get("t", "")}, "lock0": bool(disp.get(t_id, {}).get("regenLock", false))}
		super._land_hit(t_id, h, k, land)
		row["hp"] = float(disp[t_id]["hp"])
		lands.append(row)

	func _shield_downs(land: Dictionary) -> void:
		if not bool(land.get("downs_played", false)) and not (land["downs"] as Array).is_empty():
			breaks.append(float(gfx.now))
		super._shield_downs(land)

	func _float(id, text: String, col: Color, dy := 0.0) -> void:
		said.append([text, float(gfx.now)])
		super._float(id, text, col, dy)

	func _float_tally(f, id, text: String, col: Color, dy: float):
		said.append([text, float(gfx.now)])
		return super._float_tally(f, id, text, col, dy)

class RecSfx extends "res://audio/sfx.gd":
	var fx_clock = null
	var heard: Array = []   # [cue name, effect time]
	var lances: Array = []  # [effect time of the call, the fire times the battle passed]

	func lance(ion: bool, fac: String, pos = null, fire_at := -1.0, sched := Callable(), fires := []) -> void:
		lances.append([float(fx_clock.now) if fx_clock != null else -1.0, (fires as Array).duplicate()])
		super.lance(ion, fac, pos, fire_at, sched, fires)

	func play(name: String, o := {}) -> void:
		heard.append([name, float(fx_clock.now) if fx_clock != null else -1.0])
		super.play(name, o)

var failures := 0


func _init() -> void:
	GUARD.arm(self, "hit_timing_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)


func _helpers() -> void:
	var arr: Array = Battle.hit_arrivals([false, false, true], [0.4, 0.5, 0.9], 1)
	_check(arr == [0.9], "hit_arrivals: one hit after two misses rides the third shot (got %s)" % str(arr))
	arr = Battle.hit_arrivals([true, false, true, true], [0.1, 0.2, 0.3, 0.4], 3)
	_check(arr == [0.1, 0.3, 0.4], "hit_arrivals: hits skip the miss between them (got %s)" % str(arr))
	arr = Battle.hit_arrivals([true], [], 2)
	_check(arr == [0.3, 0.3], "hit_arrivals: no fx times falls back to 0.3 s (got %s)" % str(arr))
	var hs := [{"shield": 5}, {"shield": 3}, {"shield": 0}]
	_check(Battle.shield_break_hit(hs) == 1, "shield_break_hit: the last absorbed hit breaks the shield")
	_check(Battle.shield_break_hit([{"shield": 0}, {"shield": 0}]) == 1, "shield_break_hit: none absorbed gives the last hit")


func _setup() -> Array:
	var api := API.new()
	var error := api.load_rules()
	if error != "":
		_check(false, error)
		return []
	api.new_battle_scenario("s1", 1211)
	api.R.B["terrain"].clear()
	var me: Dictionary = api.R.alive("player")[0]
	var foe: Dictionary = api.R.alive("enemy")[0]
	me.merge({"q": 2, "r": 6, "facing": 0}, true)
	foe.merge({"q": 5, "r": 6, "facing": 3}, true)
	var b := Probe.new()
	b.cine = "off"
	b.follow = false
	root.add_child(b)
	await b._begin(api)
	b.cam.t = b._pos(me["id"])
	b.cam.r = 120.0
	b.cam.snap()
	return [b, str(foe["id"]), str(me["id"])]


func _fire(b: Probe, a: String, t: String, shots: Array, hits: Array, grp_extra: Array, kind := "", wid := "") -> Dictionary:
	var u: Dictionary = b.VU[a]
	var w: Dictionary = (b.api.unit(a)["weapons"] as Array)[0]
	var e := {"t": "fire", "unit": a, "target": t, "kind": kind if kind != "" else str(w.get("k", "battery")), "name": "Test gun",
		"weapon": 0, "weapon_id": wid if kind != "" else str(w.get("id", "")), "shots": shots, "quad": 0, "pd": 0}
	var grp: Array = []
	for h in hits:
		var g := {"t": "hit", "unit": a, "target": t, "quad": 0, "section": "mid", "shield": h[0], "hull": h[1],
			"crit": h.size() > 2 and bool(h[2])}
		if h.size() > 3 and bool(h[3]):
			g["regenLock"] = true
		grp.append(g)
	grp.append_array(grp_extra)
	var Tg = b.gfx.ship(t)
	if Tg != null:
		Tg.busy_until = -1.0
	b.lands.clear()
	b.breaks.clear()
	b.said.clear()
	var t0 := float(b.gfx.now)
	await b._play_fire(e, grp)
	var ended := float(b.gfx.now)
	var lands_at_end := b.lands.size()
	var aim_after: Dictionary = b.aim.duplicate()   # (A: the slowed hit has not landed yet, so the marker still holds)
	# hits on a slowed clock can land after the volley lets go; wait (bounded) for them
	for i in 600:
		if b.lands.size() >= hits.size():
			break
		await process_frame
	for i in 5:
		await process_frame
	return {"t0": t0, "ended": ended, "lands_at_end": lands_at_end, "busy": float(Tg.busy_until) if Tg != null else -1.0,
		"has_tg": Tg != null, "aim_after": aim_after, "aim_final": b.aim.duplicate(), "u": u}


func _run() -> void:
	LOOK.set_look("cine", false)
	_helpers()
	var s: Array = await _setup()
	if s.is_empty():
		quit(1)
		return
	var b: Probe = s[0]
	var a: String = s[1]
	var t: String = s[2]
	_check(b.gfx != null, "the G4 effects are in the build")
	if b.gfx == null:
		quit(1)
		return

	# A: [miss, miss, hit] with the effect clock at a quarter speed for the whole volley
	b.gfx._pause_depth = 0.25
	b.gfx._pause_until = float(b.gfx.now) + 1000.0
	var hp0 := float(b.disp[t]["hp"])
	var r := await _fire(b, a, t, [false, false, true], [[0, 7]], [])
	b.gfx._pause_until = -1.0
	b.gfx._pause_depth = 1.0
	_check(r["has_tg"], "A: the target is a G4 ship (busy_until carries the hit's planned impact)")
	_check(b.lands.size() == 1, "A: the one hit lands once (got %d)" % b.lands.size())
	if b.lands.size() == 1 and r["has_tg"]:
		var L: Dictionary = b.lands[0]
		var busy := float(r["busy"])
		_check(busy > float(r["t0"]), "A: the fx planned an impact for the hitting shot")
		_check(float(L["now"]) >= busy - 0.001 and float(L["now"]) <= busy + TOL,
			"A: the hit lands on its own shot's arrival on the effect clock (landed %.3f, planned %.3f)" % [float(L["now"]), busy])
		_check(is_equal_approx(float(L["hp"]), hp0 - 7.0), "A: the HP drop lands with the hit (%.1f to %.1f)" % [hp0, float(L["hp"])])
		var num := -1.0
		for x in b.said:
			if str(x[0]) == "−7 hull":
				num = float(x[1])
		_check(absf(num - float(L["now"])) < 0.001, "A: the hull number rises on the hit (at %.3f, hit %.3f)" % [num, float(L["now"])])
		_check(bool(L["ring"]) and (L["col"] as Color).is_equal_approx(Battle.AIM_RING),
			"A: the enemy's target is ringed in the danger colour while the volley plays")
		_check(str((L["aim"] as Dictionary).get("t", "")) == t and str((L["aim"] as Dictionary).get("a", "")) == a,
			"A: the volley names its attacker and target (aim %s)" % str(L["aim"]))
	_check(int(r["lands_at_end"]) == 0 and not (r["aim_after"] as Dictionary).is_empty(),
		"A: a hit still landing after the volley lets go keeps the target marked (landed %d, aim %s)" % [int(r["lands_at_end"]), str(r["aim_after"])])
	_check((r["aim_final"] as Dictionary).is_empty(), "A: the target marker clears once the volley's last hit has landed")
	var ring = b.views[t].ring
	_check(not ring.visible or not (ring.material_override as StandardMaterial3D).albedo_color.is_equal_approx(Battle.AIM_RING),
		"A: the danger ring clears once the volley's last hit has landed")

	# B: three hits, the second empties the shield
	var down := {"t": "shield_down", "unit": t, "quad": 0}
	r = await _fire(b, a, t, [true, true, true], [[5, 0], [3, 0], [0, 6]], [down])
	_check(b.lands.size() == 3, "B: three hits land (got %d)" % b.lands.size())
	_check(b.breaks.size() == 1, "B: the shield breaks once (got %d)" % b.breaks.size())
	if b.lands.size() == 3 and b.breaks.size() == 1:
		var at2 := float(b.lands[1]["now"])
		var at3 := float(b.lands[2]["now"])
		_check(absf(float(b.breaks[0]) - at2) < 0.001, "B: the break fires on the second hit (break %.3f, hit 2 %.3f)" % [float(b.breaks[0]), at2])
		_check(float(b.breaks[0]) < at3 or is_equal_approx(at2, at3), "B: the break comes before the third hit (%.3f vs %.3f)" % [float(b.breaks[0]), at3])
		var sd := -1.0
		for x in b.said:
			if str(x[0]).begins_with("Shields down") and sd < 0.0:
				sd = float(x[1])
		_check(absf(sd - at2) < 0.001, "B: \"Shields down\" shows on the breaking hit (at %.3f)" % sd)
		var lone := 0
		for x in b.said:
			if str(x[0]) == "Shields down":
				lone += 1
		_check(lone == 0, "B: \"Shields down\" joins the shield count's label instead of a second label on top of it (%s)" % str(b.said))
		_check(int(b.lands[0]["k"]) == 0 and int(b.lands[1]["k"]) == 1 and int(b.lands[2]["k"]) == 2, "B: hits land in order")
		_check(float(b.disp[t]["sh"][0]) == 0.0, "B: the shield reads empty after the break")
	# D: a lance at quarter speed; the cue recorder replaces the battle's sound player
	var rec := RecSfx.new()
	rec.cam = b.cam
	rec.fx_clock = b.gfx
	b.add_child(rec)
	b.sfx = rec
	b.gfx._pause_depth = 0.25
	b.gfx._pause_until = float(b.gfx.now) + 1000.0
	r = await _fire(b, a, t, [true], [[0, 9]], [], "lance")
	for i in 240:
		if not b.lands.is_empty() and float(b.gfx.now) >= float(b.lands[-1]["now"]) + rec.CRIT_BEAT + TOL:
			break
		await process_frame
	b.gfx._pause_until = -1.0
	b.gfx._pause_depth = 1.0
	var charge := -1.0
	var shot := -1.0
	for x in rec.heard:
		var nm := str(x[0])
		if nm == "lance_charge" and charge < 0.0:
			charge = float(x[1])
		elif nm.begins_with("lance") and nm != "lance_charge" and shot < 0.0:
			shot = float(x[1])
	_check(shot >= 0.0, "D: the lance shot cue plays (heard %s)" % str(rec.heard))
	if rec.cues.has("lance_charge"):
		_check(charge >= 0.0 and shot - charge > 0.26 * 0.75,
			"D: the shot trails its charge by the lead in effect time, not wall time (charge %.3f, shot %.3f)" % [charge, shot])
	if b.lands.size() == 1 and shot >= 0.0:
		_check(shot <= float(b.lands[0]["now"]) + 0.001, "D: the shot cue plays before its hit lands (%.3f vs %.3f)" % [shot, float(b.lands[0]["now"])])
		_check(shot >= float(r["t0"]) + 0.26 * 0.75, "D: the shot cue waits for the effect's fire time on the slowed clock (%.3f after start)" % (shot - float(r["t0"])))
	# E: the combined case (null lance cues, hit pause, a miss before the hits, a glass critical, then an ion lock)
	b.VU[a]["fac"] = "deathless"
	b.VU[t]["fac"] = "ithar"
	rec.heard.clear()
	rec.lances.clear()
	b.gfx._pause_depth = 0.25
	b.gfx._pause_until = float(b.gfx.now) + 1000.0
	r = await _fire(b, a, t, [false, true, true], [[0, 5], [0, 8, true]], [], "lance", "nlance")
	for i in 120:
		await process_frame
	b.gfx._pause_until = -1.0
	b.gfx._pause_depth = 1.0
	var dark: Array = []
	var glass: Array = []
	var heavy: Array = []
	for x in rec.heard:
		match str(x[0]):
			"lance_dark":
				dark.append(float(x[1]))
			"hit_glass":
				glass.append(float(x[1]))
			"hit_heavy":
				heavy.append(float(x[1]))
	_check(b.lands.size() == 2, "E: both null lance hits land (got %d)" % b.lands.size())
	# Artoo (PR 1220): every beam has a cue, the missing one too, each on its own fire time on the effect clock
	# the fire times come from the effect itself (the volley's record), not from what the battle passed to the cues
	var vol: Array = b.vols[-1] if not b.vols.is_empty() else [0.0, {}]
	var fires: Array = (vol[1] as Dictionary).get("fires", [])
	_check(fires.size() == 3, "E: the effect gives a fire time for all three beams, the miss too (got %s)" % str(fires))
	_check(rec.lances.size() == 1 and (rec.lances[0][1] as Array).size() == 3,
		"E: the battle asks for the null lance cues once, for all three beams (got %s)" % str(rec.lances))
	_check(dark.size() == 3, "E: the null lance plays exactly one shot cue per beam (heard %s)" % str(rec.heard))
	if fires.size() == 3 and dark.size() == 3:
		var v0 := float(vol[0])
		var want: Array = fires.map(func(x): return v0 + float(x))
		want.sort()
		dark.sort()
		for i in 3:
			_check(float(dark[i]) >= float(want[i]) - 0.001 and float(dark[i]) <= float(want[i]) + TOL,
				"E: beam %d's cue plays on its own fire time on the effect clock (heard %.3f, fire %.3f)" % [i, float(dark[i]), float(want[i])])
		_check(float(want[0]) - v0 > 0.1 * 0.75, "E: the first beam fires after a slowed lead, so a wall-clock cue would show")
	if b.lands.size() == 2 and dark.size() == 3:
		_check(float(b.lands[0]["now"]) < float(b.lands[1]["now"]), "E: the hits land in shot order")
		_check(float(dark[1]) <= float(b.lands[0]["now"]) + 0.001 and float(dark[2]) <= float(b.lands[1]["now"]) + 0.001,
			"E: each hitting beam's cue plays before its hit lands")
	_check(glass.size() == 2, "E: each hit on glass plays the glass contact cue, the critical too (heard %d)" % glass.size())
	if b.lands.size() == 2 and glass.size() == 2:
		_check(absf(glass[1] - float(b.lands[1]["now"])) < 0.001, "E: the critical's glass cue lands with its hit")
	_check(heavy.size() == 1, "E: the critical adds one heavy tail under the glass cue (got %d)" % heavy.size())
	if glass.size() == 2 and heavy.size() == 1:
		var gap := float(heavy[0]) - float(glass[1])
		_check(gap >= rec.CRIT_BEAT - 0.001 and gap <= rec.CRIT_BEAT + TOL,
			"E: the critical tail waits %.2f effect seconds under hit pause (heard %.3f)" % [rec.CRIT_BEAT, gap])
		print("critical audio trace (effect seconds): glass=%.3f heavy=%.3f gap=%.3f" % [glass[1], heavy[0], gap])
	# the ion lock: an ion lance shield hit locks the target's regen when it lands
	b.VU[a]["fac"] = "hegemony"
	b.disp[t]["regenLock"] = false
	b.gfx._pause_depth = 0.25
	b.gfx._pause_until = float(b.gfx.now) + 1000.0
	r = await _fire(b, a, t, [true], [[4, 0, false, true]], [], "lance", "ion")
	b.gfx._pause_until = -1.0
	b.gfx._pause_depth = 1.0
	_check(b.lands.size() == 1, "E: the ion hit lands (got %d)" % b.lands.size())
	if b.lands.size() == 1:
		_check(not bool(b.lands[0]["lock0"]), "E: the ion lock is not shown before its hit lands")
	_check(bool(b.disp[t].get("regenLock", false)), "E: the ion lock reaches the nameplate state when its hit lands")
	_check(b.gfx.ship(t)._ion_locked, "E: the landed ion enables shield arcs during volley playback")
	# Play events from the actual rules turn-start path. Both sides can hold a lock independently.
	var rules = b.api.R
	var target: Dictionary = rules.alive("player")[0]
	var other: Dictionary = rules.alive("enemy")[0]
	other["regenLock"] = 1
	target["regenLock"] = 1
	b.disp[a]["regenLock"] = true
	b.bot = true
	await b._play_event({"t": "round", "round": 1})
	_check(b.disp[a]["regenLock"] and b.disp[t]["regenLock"], "E: the round banner leaves both locks active")
	b.api.take_events()
	for side in ["enemy", "player"]:
		rules.startSideTurn(side)
		var events: Array = b.api.take_events()
		var unlocks: Array = events.filter(func(e: Dictionary) -> bool: return e["t"] == "regen_unlock")
		var unit_id: String = a if side == "enemy" else t
		_check(unlocks == [{"t": "regen_unlock", "unit": unit_id}], "E: %s turn emits only its ship's unlock" % side)
		for event in unlocks:
			await b._play_event(event)
		var unit: Dictionary = other if side == "enemy" else target
		_check(unit.get("regenLock") == null, "E: %s rules cleared the lock" % side)
		_check(not b.disp[unit_id]["regenLock"], "E: %s nameplate clears when its side starts" % side)
		if side == "enemy":
			_check(b.disp[t]["regenLock"], "E: enemy turn start leaves the player lock active")
	var late_land: Dictionary = (b.vols[-1][1] as Dictionary).duplicate()
	late_land.merge({"numbers": false, "left": 1}, true)
	b._land_hit(t, {"target": t, "regenLock": true, "hull": 0, "shield": 1, "quad": 0}, 0, late_land)
	_check(not b.disp[t]["regenLock"], "E: a late hit from before the expiry cannot restore the icon")
	_check(not b.gfx.ship(t)._ion_locked, "E: an expired ion hit cannot restart shield arcs")
	# F: Artoo (PR 1256): a critical the armour absorbs, then a normal hull hit; one hull label, never two "Critical"
	r = await _fire(b, a, t, [true, true], [[0, 0, true], [0, 5]], [])
	var crits: Array = []
	for x in b.said:
		if str(x[0]).begins_with("Critical"):
			crits.append(str(x[0]))
	_check(b.lands.size() == 2, "F: both hits land (got %d)" % b.lands.size())
	_check(crits == ["Critical", "Critical", "Critical −5 hull"] or crits == ["Critical", "Critical −5 hull"],
		"F: the absorbed critical and the next hull hit share one label, rewritten (got %s)" % str(crits))
	var labels := 0
	for f in b.floats:
		if is_instance_valid(f["lbl"]) and str((f["lbl"] as Label).text).begins_with("Critical"):
			labels += 1
	_check(labels <= 1, "F: never two critical labels on screen (got %d)" % labels)
	b.free()
	if failures == 0:
		print("hit timing: PASS ([miss, miss, hit] on the effect clock under hit pause; shield break on the second of three hits; target ringed and named; lance cues on the effect clock; null lance, glass critical and ion lock combined)")
	quit(0 if failures == 0 else 1)
