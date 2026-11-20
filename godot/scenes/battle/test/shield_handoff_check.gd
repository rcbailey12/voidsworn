extends SceneTree
# Issue 1239 (Neon's ship damage audit, F2.1 to F2.5): the clean collapse (R340) hands off to the bare hull.
#   F2.1 the collapse aims at the shot that broke the shield (brk_dir is that hit's shield point), not the quadrant's middle;
#   F2.2 a breaking shot that also hurts the hull lays no second ripple on top of the failure's flash;
#   F2.3 a ship killed by the volley that broke its shield keeps the collapse to its end, then the shield goes; a ship
#        killed with no failure playing loses its shield at once, as before;
#   F2.4 a torpedo salvo lands every warhead (one impact per hit, a beat apart), not only the first;
#   F2.5 a shield that drops with no volley (a storm, a special) still plays the failure; a seventh ripple never wipes a
#        ripple that is still to play while a finished slot is free.
# Real battle scene, rules scenario s1, box-free (the scenario's own ships), fitted and egg shields.

const GUARD := preload("res://tools/ci/check_guard.gd")
const API := preload("res://rules/battle_api.gd")
const LOOK := preload("res://world/board_look.gd")
const SHIP := preload("res://fx/fx_ship.gd")
const WEAP := preload("res://fx/fx_weapons.gd")

class Probe extends "res://scenes/battle/battle.gd":
	var downs: Array = []   # [effect time, the land's hit points, its break hit]

	func _shield_downs(land: Dictionary) -> void:
		if not bool(land.get("downs_played", false)) and not (land["downs"] as Array).is_empty():
			downs.append([float(gfx.now), (land.get("pts", []) as Array).duplicate(), int(land["break_k"])])
		super._shield_downs(land)

var failures := 0


func _init() -> void:
	GUARD.arm(self, "shield_handoff_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)


func _brk(S) -> float:
	var v = S._shield_mat.get_shader_parameter("brk_t")
	return float(v) if v != null else -100.0


func _fire(b: Probe, a: String, t: String, shots: Array, hits: Array, down: bool) -> void:
	var e := {"t": "fire", "unit": a, "target": t, "kind": "battery", "name": "Test gun", "weapon": 0, "weapon_id": "",
		"shots": shots, "quad": 0, "pd": 0}
	var grp: Array = []
	for h in hits:
		grp.append({"t": "hit", "unit": a, "target": t, "quad": 0, "section": "mid", "shield": h[0], "hull": h[1], "crit": false})
	if down:
		grp.append({"t": "shield_down", "unit": t, "quad": 0})
	await b._play_fire(e, grp)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _battle(shape: String):
	OS.set_environment("VS_SHIELD_SHAPE", shape)
	var api := API.new()
	var error := api.load_rules()
	if error != "":
		_check(false, error)
		return null
	api.new_battle_scenario("s1", 1239)
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
	b.set_meta("a", str(foe["id"]))
	b.set_meta("t", str(me["id"]))
	return b


func _case(shape: String) -> void:
	var b = await _battle(shape)
	if b == null:
		return
	var a: String = b.get_meta("a")
	var t: String = b.get_meta("t")
	var fx = b.gfx
	_check(fx != null, "%s: the G4 effects are in the build" % shape)
	if fx == null:
		b.free()
		return
	var S = fx.ships.get(t)
	_check(S != null and S._shield_mat != null and S._fail_look == 2, "%s: the target has a shield and the collapse look" % shape)
	if S == null or S._shield_mat == null:
		b.free()
		return

	# F2.1 and F2.2: the second hit breaks the shield and bleeds 3 into the hull
	var b0 := _brk(S)
	await _fire(b, a, t, [true, true], [[6, 0], [4, 3]], true)
	await _frames(30)
	_check(b.downs.size() == 1, "%s: the shield breaks once (got %d)" % [shape, b.downs.size()])
	if b.downs.size() == 1:
		var pts: Array = b.downs[0][1]
		var bk: int = b.downs[0][2]
		_check(bk == 1 and pts.size() == 2, "%s: the volley gives each hit's shield point (break hit %d, points %s)" % [shape, bk, str(pts)])
		if bk == 1 and pts.size() == 2 and (pts[1] as Vector3).is_finite():
			var want: Vector3 = (pts[1] as Vector3).normalized()
			var got: Vector3 = S._shield_mat.get_shader_parameter("brk_dir")
			_check(got.dot(want) > 0.999, "F2.1 %s: the collapse aims at the breaking shot (brk_dir %s, hit %s, quadrant middle %s)" % [shape, str(got), str(want), str(S.hull.quad_dir(0))])
		else:
			_check(false, "F2.1 %s: the breaking hit has a shield point (%s)" % [shape, str(pts)])
		var bt := _brk(S)
		_check(bt != b0, "%s: the collapse started" % shape)
		# no ripple a moment before the failure's flash (the old "through" ripple sat at T - 0.02)
		var extra := 0
		for i in 6:
			var h: Vector4 = S._hits[i]
			if absf(h.w - (bt - 0.02)) < 0.005:
				extra += 1
		_check(extra == 0, "F2.2 %s: the breaking shot lays no second ripple on the failure (%d)" % [shape, extra])

	# F2.5: a seventh ripple takes a finished slot, never a live one
	var now: float = fx.now
	for i in 6:
		S._hits[i] = Vector4(0, 0, 0, now + 5.0 + i)
		S._hitw[i] = Vector4(1, 1, 1, 0)
	S._hits[3] = Vector4(0, 0, 0, now - 9.0)   # finished long ago
	S.shield_hit(fx, Vector3(1, 0, 0), now, 0.5, 1.0, 0.4)
	_check(S._hit_i == 3, "F2.5 %s: a new ripple takes the finished slot (took %d)" % [shape, S._hit_i])
	S._hits[3] = Vector4(0, 0, 0, now + 20.0)   # every slot live now; slot 0 (now + 5) started earliest
	S.shield_hit(fx, Vector3(1, 0, 0), now, 0.5, 1.0, 0.4)
	_check(S._hit_i == 0, "F2.5 %s: with every slot live, the earliest is replaced (took %d)" % [shape, S._hit_i])

	# F2.5: a shield drop with no volley still plays the failure
	var b1 := _brk(S)
	await _frames(2)
	await b._play_event({"t": "shield_down", "unit": t, "quad": 2})
	_check(_brk(S) != b1, "F2.5 %s: a shield drop with no volley plays the failure" % shape)

	# F2.3: killed on the breaking volley: the collapse runs to its end, then the shield goes
	await _frames(120)   # (the earlier failure is long over)
	S.shield_break(fx, 0)
	await _frames(6)
	var brk_end: float = S._brk_until
	fx.death(t, "blast")
	_check(S._shield_until > fx.now and S._shield_until <= brk_end + 1e-4,
		"F2.3 %s: the dying ship keeps its collapsing shield to the collapse's end (until %.3f, now %.3f, end %.3f)" % [shape, S._shield_until, fx.now, brk_end])
	var guard := 0
	while fx.now < brk_end + 0.05 and guard < 600:
		guard += 1
		await process_frame
	_check(S._shield_mi == null or not S._shield_mi.visible, "F2.3 %s: the shield is gone once the collapse ends" % shape)

	# F2.3, the old path: a ship killed with no failure playing loses its shield at once
	var S2 = fx.ships.get(a)
	if S2 != null and S2._shield_mat != null:
		S2.shield_hit(fx, Vector3(1, 0, 0), fx.now, 0.5, 1.0, 0.6)
		fx.death(a, "blast")
		_check(float(S2._shield_until) < 0.0, "F2.3 %s: a kill with no failure playing drops the shield at once" % shape)
	b.free()
	await _frames(3)


# F2.4: a torpedo salvo of three warheads lands three impacts, TORP_WARHEAD_GAP apart, the shield soaking the first.
func _torps() -> void:
	var b = await _battle("fitted")
	if b == null:
		return
	var a: String = b.get_meta("a")
	var t: String = b.get_meta("t")
	var fx = b.gfx
	if fx == null:
		b.free()
		return
	var T = fx.ship(t)
	fx.torp_lane("L1239", a, T.to_world(T.hull.c), 1)
	fx.torp_launch("L1239")
	await _frames(20)
	var hits := [{"shield": 6, "hull": 0, "section": "mid", "crit": false}, {"shield": 0, "hull": 9, "section": "prow", "crit": false},
		{"shield": 0, "hull": 9, "section": "eng", "crit": true}]
	var r: Dictionary = fx.torp_strike("L1239", t, hits[0], hits.slice(1), 0)
	var imp: Array = r.get("impacts", [])
	_check(imp.size() == 3, "F2.4: three warheads give three impacts (got %s)" % str(imp))
	if imp.size() == 3:
		_check(absf(float(imp[1]) - float(imp[0]) - WEAP.TORP_WARHEAD_GAP) < 1e-4 and absf(float(imp[2]) - float(imp[1]) - WEAP.TORP_WARHEAD_GAP) < 1e-4,
			"F2.4: the warheads land a beat apart (%s)" % str(imp))
	var pts: Array = r.get("hit_pts", [])
	_check(pts.size() == 3 and (pts[0] as Vector3).is_finite(), "F2.4: the first warhead's shield point comes back (%s)" % str(pts))
	var one: Dictionary = fx.torp_strike("L1239", t, hits[0])
	_check((one.get("impacts", []) as Array).size() <= 1, "F2.4: a single warhead still gives one impact")
	b.free()
	await _frames(3)


func _run() -> void:
	LOOK.set_look("cine", false)
	for shape in ["fitted", "egg"]:
		await _case(shape)
	await _torps()
	OS.set_environment("VS_SHIELD_SHAPE", "")
	if failures == 0:
		print("shield handoff: PASS (the collapse aims at the breaking shot, no ripple on its flash, a kill lets it finish, every torpedo warhead lands, a storm drop plays it, ripples keep their slots; fitted and egg)")
	quit(0 if failures == 0 else 1)
