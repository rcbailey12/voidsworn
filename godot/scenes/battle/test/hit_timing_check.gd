extends SceneTree
# Issue 1211: every hit lands on its own shot. Plays crafted volleys through battle.gd _play_fire with the G4 effects:
#  A. [miss, miss, hit] under a deep hit pause: the HP drop, the sound and the number land when the hitting shot arrives
#     on the effect clock (the target's busy_until is that shot's planned impact), not at the first miss's time and not
#     on the wall clock; the enemy's target is ringed and named while the volley plays, and the ring clears after.
#  B. [hit, hit, hit] where the second hit empties the shield: the shield break and "Shields down" fire once, on that
#     hit, before the third hit lands (they used to wait for the whole volley).
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

	func _land_hit(t_id, h: Dictionary, k: int, land: Dictionary) -> void:
		# the marker as the hit arrives (the last hit lets it go inside the call)
		var sv = views.get(t_id)
		var row := {"k": k, "now": float(gfx.now), "ring": sv != null and sv.ring.visible,
			"col": (sv.ring.material_override as StandardMaterial3D).albedo_color if sv != null else Color.BLACK,
			"aim": {"a": aim.get("a", ""), "t": aim.get("t", "")}}
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


func _fire(b: Probe, a: String, t: String, shots: Array, hits: Array, grp_extra: Array) -> Dictionary:
	var u: Dictionary = b.VU[a]
	var w: Dictionary = (b.api.unit(a)["weapons"] as Array)[0]
	var e := {"t": "fire", "unit": a, "target": t, "kind": str(w.get("k", "battery")), "name": "Test battery",
		"weapon": 0, "weapon_id": str(w.get("id", "")), "shots": shots, "quad": 0, "pd": 0}
	var grp: Array = []
	for h in hits:
		grp.append({"t": "hit", "unit": a, "target": t, "quad": 0, "section": "mid", "shield": h[0], "hull": h[1], "crit": false})
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
			if str(x[0]) == "Shields down":
				sd = float(x[1])
		_check(absf(sd - at2) < 0.001, "B: \"Shields down\" shows on the breaking hit (at %.3f)" % sd)
		_check(int(b.lands[0]["k"]) == 0 and int(b.lands[1]["k"]) == 1 and int(b.lands[2]["k"]) == 2, "B: hits land in order")
		_check(float(b.disp[t]["sh"][0]) == 0.0, "B: the shield reads empty after the break")
	b.free()
	if failures == 0:
		print("hit timing: PASS ([miss, miss, hit] on the effect clock under hit pause; shield break on the second of three hits; target ringed and named)")
	quit(0 if failures == 0 else 1)
