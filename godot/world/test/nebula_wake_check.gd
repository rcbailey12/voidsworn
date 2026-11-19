extends SceneTree
# Issue 1079 (Board and Artoo on PR 1181): the nebula wake prototype must really reach the calm gas when it is on, and
# leave every shader exactly as it was when it is off. A shader rewrite that moves an anchor line would otherwise make
# the wake silently do nothing. Builds the real living terrain on the dense-storm fixture, both ways, and reads the
# shader code of every gas material. Headless, no window, no ship files.
const WORLD := preload("res://world/world.gd")
const API := preload("res://rules/battle_api.gd")
const BL := preload("res://world/board_look.gd")
const WAKE := preload("res://world/nebula_wake.gd")
var failed := 0


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	if not ok:
		failed += 1
		printerr("nebula wake check: FAIL ", why)


func _living(quality: String, wake: bool):
	var api = API.new()
	check(api.load_rules() == "", "rules load")
	api.new_battle_scenario({"seed": 4103, "sector": 1, "admiral": "vex", "fleet": ["warden"], "fac": "ithar", "obj": "rout",
		"shape": "open", "map": "storm", "dep": "line", "kind": "battle"}, 4103)
	api.R.B.terrain = api.R.genTerrain("storm", "open", {"cond": {"terr": "neb"}})
	api.R.B.map = api.R.TERRAIN_META.duplicate(true)
	var world = WORLD.new()
	root.add_child(world)
	var hw := func(q: int, r: int, _y := 0.0) -> Vector3: return Vector3(q * 17.3205 + r * 8.66025, 0, r * 15.0)
	world.build(api.view(), {"hex_world": hw, "quality": quality, "seed": 4103, "nebula_wake": wake})
	BL.set_look("cine", false)
	world.set_look()
	return world


# Every gas material's shader code, split into calm and storm, from the living terrain's own lists.
func _codes(living) -> Dictionary:
	var out := {"calm": [], "storm": []}
	for g in living.gas_mats:
		var m: ShaderMaterial = g[0]
		out["storm" if living.storm_mats.has(m) else "calm"].append(m.shader.code)
	for m in living.fog_mats:
		out["storm" if living.storm_mats.has(m) else "calm"].append(m.shader.code)
	return out


func _run() -> void:
	for quality in ["max", "high", "low"]:
		var off = _living(quality, false)
		var on = _living(quality, true)
		check(off._living != null and on._living != null, "%s: the living terrain is built" % quality)
		if off._living == null or on._living == null:
			continue
		var a := _codes(off._living)
		var b := _codes(on._living)
		check(not (a["calm"] as Array).is_empty() and not (a["storm"] as Array).is_empty(), "%s: the fixture has calm and storm gas" % quality)
		check(on._living._wake != null and off._living._wake == null, "%s: the setting makes the wake (and only the setting)" % quality)
		for code in a["calm"] + a["storm"] + b["storm"]:
			check(not (code as String).contains("wake_at"), "%s: no wake code with the setting off, nor ever in the storm" % quality)
		check(a["storm"] == b["storm"], "%s: storm shaders identical with the wake on" % quality)
		for code in b["calm"]:
			var c := code as String
			var fog := c.contains("shader_type fog;")
			# The function is declared, called, and both its uses (the shifted noise and the thinning) are in place.
			check(c.contains("vec4 wake_at(vec3 w)"), "%s: calm gas declares the wake" % quality)
			check(c.contains("wake_at(WORLD_POSITION)" if fog else "wake_at(vW)"), "%s: calm gas calls the wake" % quality)
			check(c.contains("p -= wk.xyz"), "%s: the wake moves the gas" % quality)
			check(c.contains("DENSITY *= 1.0 - " if fog else "d *= 1.0 - "), "%s: the wake thins the gas" % quality)
		check((b["calm"] as Array).size() == (on._living._wake_mats as Array).size(), "%s: every calm gas material is fed the wake" % quality)
		var u: PackedFloat32Array = on._living._wake.uniforms()
		check(u.size() == 8 * (WAKE.LOW_POINTS if quality == "low" else WAKE.HIGH_POINTS), "%s: bounded point count" % quality)
		off.queue_free()
		on.queue_free()
	if failed == 0:
		print("nebula wake check: PASS (on reaches every calm gas shader at max, high and low; off and storm unchanged)")
	quit(1 if failed > 0 else 0)
