extends SceneTree
# Issue 1211 follow-up (Artoo's review of PRs 1170 and 1220): two enemy volleys overlap on one shield, on the fitted skin
# and on the egg, with Reduced Flashing off and on. Under a quarter-speed hit pause the first (long) volley lets go before
# its hits land; the second volley (one quick shot, hull only) lands between its first hit and its draining second hit,
# and the check asserts that order. The clean collapse (R340) must start once, on the draining hit, from the shared
# shield code (the ship's brk_t is that hit's effect time), never on a hit that leaves shield standing, never twice.

const GUARD := preload("res://tools/ci/check_guard.gd")
const API := preload("res://rules/battle_api.gd")
const LOOK := preload("res://world/board_look.gd")
const SHIP := preload("res://fx/fx_ship.gd")

class Probe extends "res://scenes/battle/battle.gd":
	var lands: Array = []    # [volley tag, hit index, effect time]
	var breaks: Array = []   # effect times "Shields down" played (battle side)

	func _land_hit(t_id, h: Dictionary, k: int, land: Dictionary) -> void:
		lands.append([str(land.get("tag", "")), k, float(gfx.now)])
		super._land_hit(t_id, h, k, land)

	func _shield_downs(land: Dictionary) -> void:
		if not bool(land.get("downs_played", false)) and not (land["downs"] as Array).is_empty():
			breaks.append(float(gfx.now))
		super._shield_downs(land)

	var _tag := ""

	func _aim_on(a_id, t_id, land: Dictionary) -> void:
		land["tag"] = _tag
		super._aim_on(a_id, t_id, land)

var failures := 0


func _init() -> void:
	GUARD.arm(self, "shield_overlap_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)


# Artoo (PR 1288): the overlap is enforced, not assumed: some v2 hit lands after v1's first hit and before v1's
# draining hit (its second), in effect time.
static func interleaved(lands: Array) -> bool:
	var first := INF
	var drain := -INF
	for L in lands:
		if str(L[0]) == "v1" and int(L[1]) == 0:
			first = float(L[2])
		elif str(L[0]) == "v1" and int(L[1]) == 1:
			drain = float(L[2])
	for L in lands:
		if str(L[0]) == "v2" and float(L[2]) > first and float(L[2]) < drain:
			return true
	return false


func _orders() -> void:
	# the order check itself: the interleaved order passes, the old non-interleaved order fails
	_check(interleaved([["v1", 0, 0.7], ["v2", 0, 1.0], ["v1", 1, 1.3]]), "order check: v1, v2, v1 is interleaved")
	_check(not interleaved([["v1", 0, 0.7], ["v1", 1, 0.8], ["v2", 0, 1.0], ["v2", 1, 1.1]]), "order check: v1, v1, v2, v2 is not interleaved")
	_check(not interleaved([["v2", 0, 0.5], ["v1", 0, 0.7], ["v1", 1, 0.8]]), "order check: a v2 hit before v1 starts is not interleaved")


func _brk(S) -> float:
	var v = S._shield_mat.get_shader_parameter("brk_t")
	return float(v) if v != null else -100.0   # (unset: the shader's own default)


func _volley(b: Probe, tag: String, a: String, t: String, shots: Array, hits: Array, down: bool) -> void:
	var e := {"t": "fire", "unit": a, "target": t, "kind": "battery", "name": "Test gun", "weapon": 0, "weapon_id": "",
		"shots": shots, "quad": 0, "pd": 0}
	var grp: Array = []
	for h in hits:
		grp.append({"t": "hit", "unit": a, "target": t, "quad": 0, "section": "mid", "shield": h[0], "hull": h[1], "crit": false})
	if down:
		grp.append({"t": "shield_down", "unit": t, "quad": 0})
	b._tag = tag
	await b._play_fire(e, grp)


func _case(shape: String, calm: bool) -> void:
	var name := "%s, reduced flashing %s" % [shape, "on" if calm else "off"]
	OS.set_environment("VS_SHIELD_SHAPE", shape)
	var api := API.new()
	var error := api.load_rules()
	if error != "":
		_check(false, error)
		return
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
	var a := str(foe["id"])
	var t := str(me["id"])
	_check(b.gfx != null, "%s: the G4 effects are in the build" % name)
	if b.gfx == null:
		b.free()
		return
	b.gfx.reduce_flashing = calm
	var S = b.gfx.ships.get(t)
	_check(S != null and S._shield_mat != null, "%s: the target has a shield" % name)
	if S == null or S._shield_mat == null:
		b.free()
		return
	_check(bool(S._shield_mat.get_shader_parameter("fitted_shape")) == (shape == "fitted"),
		"%s: the target wears the %s shield" % [name, shape])
	_check(S._fail_look == 2, "%s: the clean collapse is the failure look (R340)" % name)
	var brk0 := _brk(S)
	var brk_seen: Array = []
	b.gfx._pause_depth = 0.25
	b.gfx._pause_until = float(b.gfx.now) + 1000.0
	# volley 1 drains the shield on its second hit; volley 2 fires while volley 1's hits are still in flight
	# (a long first volley: its draining hit is its last shot, so the short second volley lands in between)
	await _volley(b, "v1", a, t, [true, false, false, false, false, false, false, true], [[6, 0], [4, 0]], true)
	_check(b.lands.size() < 2, "%s: the first volley's hits are still in flight when the second fires (landed %d)" % [name, b.lands.size()])
	var last := brk0
	await _volley(b, "v2", a, t, [true], [[0, 5]], false)
	for i in 900:
		var bt := _brk(S)
		if bt != last:
			brk_seen.append(bt)
			last = bt
		if b.lands.size() >= 3 and i > 60:
			break
		await process_frame
	b.gfx._pause_until = -1.0
	b.gfx._pause_depth = 1.0
	print("OVERLAP order %s: %s" % [name, str(b.lands)])
	_check(b.lands.size() == 3, "%s: all three hits land (got %s)" % [name, str(b.lands)])
	_check(interleaved(b.lands), "%s: a second-volley hit lands between the first volley's first hit and its draining hit (order %s)" % [name, str(b.lands)])
	var drain := -1.0
	var tags: Array = []
	for L in b.lands:
		tags.append(str(L[0]))
		if str(L[0]) == "v1" and int(L[1]) == 1:
			drain = float(L[2])
	_check(tags.has("v1") and tags.has("v2"), "%s: both volleys land hits (%s)" % [name, str(tags)])
	_check(b.breaks.size() == 1, "%s: \"Shields down\" plays once (got %d)" % [name, b.breaks.size()])
	_check(brk_seen.size() == 1, "%s: the collapse starts once (brk_t changes %s)" % [name, str(brk_seen)])
	if brk_seen.size() == 1 and drain >= 0.0:
		_check(absf(float(brk_seen[0]) - drain) < 0.001,
			"%s: the collapse starts on the draining hit (brk_t %.3f, drain %.3f)" % [name, float(brk_seen[0]), drain])
	if b.breaks.size() == 1 and drain >= 0.0:
		_check(absf(float(b.breaks[0]) - drain) < 0.001, "%s: \"Shields down\" plays on the draining hit" % name)
	_check(float(b.disp[t]["sh"][0]) == 0.0, "%s: the shield reads empty after the break" % name)
	var fc = RenderingServer.global_shader_parameter_get(&"fx_calm")   # (null on the headless dummy renderer)
	_check(bool(b.gfx.reduce_flashing) == calm and (fc == null or is_equal_approx(float(fc), 1.0 if calm else 0.0)),
		"%s: the effects and the shield shader see the comfort setting (fx_calm %s)" % [name, str(fc)])
	b.free()
	for i in 3:
		await process_frame


func _run() -> void:
	LOOK.set_look("cine", false)
	_orders()
	for shape in ["fitted", "egg"]:
		for calm in [false, true]:
			await _case(shape, calm)
	OS.set_environment("VS_SHIELD_SHAPE", "")
	if failures == 0:
		print("shield overlap: PASS (two overlapping volleys; the collapse starts once, on the draining hit, on the fitted and the egg shield, with reduced flashing off and on)")
	quit(0 if failures == 0 else 1)
