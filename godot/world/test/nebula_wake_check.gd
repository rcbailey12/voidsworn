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
		for code in a["calm"]:
			check((code as String).count("// WAKE_SHIFT") == 1 and (code as String).count("// WAKE_THIN") == 1, "%s: calm gas keeps its two wake markers" % quality)
			if quality == "high" and not (code as String).contains("shader_type fog;"):
				check((code as String).contains("#define HIGH_GAS_CARDS"), "high: the optimised High cards are the ones checked")
		for code in b["calm"]:
			var c := code as String
			var fog := c.contains("shader_type fog;")
			# The function is declared, called, and both its uses (the shifted noise and the thinning) are in place.
			check(c.contains("vec4 wake_at(vec3 w)"), "%s: calm gas declares the wake" % quality)
			check(not c.contains("// WAKE_SHIFT") and not c.contains("// WAKE_THIN"), "%s: both markers are replaced" % quality)
			check(c.contains("wake_at(WORLD_POSITION)" if fog else "wake_at(vW)"), "%s: calm gas calls the wake" % quality)
			check(c.contains("p -= wk.xyz"), "%s: the wake moves the gas" % quality)
			check(c.contains("DENSITY *= 1.0 - " if fog else "d *= 1.0 - "), "%s: the wake thins the gas" % quality)
		check((b["calm"] as Array).size() == (on._living._wake_mats as Array).size(), "%s: every calm gas material is fed the wake" % quality)
		var u: PackedFloat32Array = on._living._wake.uniforms()
		check(u.size() == WAKE.FLOATS * (WAKE.LOW_POINTS if quality == "low" else WAKE.HIGH_POINTS), "%s: bounded point count" % quality)
		off.queue_free()
		on.queue_free()
	_glsl_check()
	_trail_check()
	_parked_fleet_check("max")
	_parked_fleet_check("low")
	_moved_then_parked_check("max")
	_moved_then_parked_check("low")
	_hitch_check()
	_restart_check()
	if failed == 0:
		print("nebula wake check: PASS (on reaches every calm gas shader at max, high and low; off and storm unchanged; the trail is one unbroken strip; a parked fleet never starves a mover, even after it moved; a hitch never restarts a trail; a restart never moves the old trail)")
	quit(1 if failed > 0 else 0)


# Ryan, Nov 19: the wake must read as one continuous trail, no stages. A capital-sized stand-in flies a curve, stops,
# and flies on. Every frame: its newest segment ends at the hull, each segment starts where the one after it ends with
# the same age there, and nothing in the uniforms is ever more than FADE_S old where it is live.
func _trail_check() -> void:
	var src := GDScript.new()
	src.source_code = "extends Node3D\nvar L := 40.0\nvar dead := false\n"
	src.reload()
	var ship: Node3D = src.new()
	root.add_child(ship)
	var w = WAKE.new("max")
	var dt := 1.0 / 30.0
	var broken := 0
	var tip_off := 0
	var stop_at := Vector3(INF, 0.0, 0.0)
	for k in 300:
		var moving := k < 120 or k >= 160
		var t := float(k if k < 120 else (119 if k < 160 else k - 41)) * dt   # stopped for 40 frames, then on from there
		if moving:
			ship.position = Vector3(cos(t * 0.6) * 60.0, 0.0, sin(t * 0.6) * 60.0)
		if k == 119:
			stop_at = ship.position
		w.update(dt, [ship])
		var h: int = w._head.get(ship.get_instance_id(), -1)
		var d2: Vector2 = w._last[ship.get_instance_id()].dir if w._last.has(ship.get_instance_id()) else Vector2.ZERO
		var bow: Vector3 = ship.position + Vector3(d2.x, 0.0, d2.y) * 40.0 * WAKE.BOW
		if moving and k > 1 and k != 160 and (h < 0 or (w._ring[h].b as Vector3).distance_to(bow) > 0.001):
			tip_off += 1
		# chain: every closed segment of this ship whose b is some other segment's a must agree in time there (except
		# where it stopped: moving on starts a fresh trail from that spot, as the gas there has been settling meanwhile)
		for e in w._ring:
			if (e.a as Vector3).distance_to(e.b) < 0.01 or (e.a as Vector3).distance_to(stop_at) < 0.6 * 40.0:
				continue
			for f in w._ring:
				if f != e and (f.b as Vector3).distance_to(e.a) < 0.001 and absf(float(f.tb) - float(e.ta)) > 0.0001:
					broken += 1
	check(tip_off == 0, "trail: the newest segment always ends at the moving bow (%d frames off)" % tip_off)
	check(broken == 0, "trail: segments meet end to end at the same age (%d seams)" % broken)
	var live := 0
	for e in w._ring:
		if w.clock - float(e.tb) < WAKE.FADE_S and (e.a as Vector3).distance_to(e.b) > 0.01:
			live += 1
	check(live >= 3, "trail: a moving capital keeps several live segments (%d)" % live)
	ship.queue_free()


# Artoo on PR 1181: parked ships used to take every trail slot, so one moving ship got no trail at all. A full board of
# parked ships (more than there are slots) plus one mover: the mover's trail is live once it has moved a little.
func _parked_fleet_check(quality: String) -> void:
	var src := GDScript.new()
	src.source_code = "extends Node3D\nvar L := 30.0\nvar dead := false\n"
	src.reload()
	var w = WAKE.new(quality)
	var ships := []
	for i in w.points + 4:
		var p: Node3D = src.new()
		root.add_child(p)
		p.position = Vector3(float(i) * 20.0, 0.0, 60.0)
		ships.append(p)
	var mover: Node3D = src.new()
	root.add_child(mover)
	ships.append(mover)
	var live_frames := 0
	for k in 40:
		mover.position = Vector3(float(k) * 0.8, 0.0, 0.0)
		w.update(1.0 / 30.0, ships)
		var u: PackedFloat32Array = w.uniforms()
		for i in w.points:
			var o: int = i * WAKE.FLOATS
			if minf(u[o + 9], u[o + 10]) < WAKE.FADE_S and Vector3(u[o], u[o + 1], u[o + 2]).distance_to(Vector3(u[o + 3], u[o + 4], u[o + 5])) > 0.01:
				live_frames += 1
				break
	check(live_frames >= 38, "%s: with %d parked ships a moving ship still has a trail (%d of 40 frames)" % [quality, w.points + 4, live_frames])
	for p in ships: p.queue_free()


# Artoo on PR 1181: a ship that moves, pauses briefly and moves on must leave its old trail exactly as it was (its push
# and its distance behind the bow) through the stop and the restart; the restart used to drop them to defaults, a jump
# of 0.9 to 21 in the packed push.
func _restart_check() -> void:
	var src := GDScript.new()
	src.source_code = "extends Node3D\nvar L := 40.0\nvar dead := false\n"
	src.reload()
	var ship: Node3D = src.new()
	root.add_child(ship)
	var w = WAKE.new("max")
	var x := 0.0
	var old := []      # the old trail's piece: its two ends, then its packed bow distance and push just before the restart
	var after := []
	for k in 16:
		if k < 6 or k >= 12:   # 1 unit of travel, then 0.2 s still, then on
			x += 1.0 / 6.0 if k < 6 else 0.1
		ship.position = Vector3(x, 0.0, 0.0)
		w.update(1.0 / 30.0, [ship])
		var u: PackedFloat32Array = w.uniforms()
		if k == 5:   # the last frame it moves; the 0.2 s stop then gives its piece back
			var hd: Dictionary = w._ring[w._head[ship.get_instance_id()]]
			old = [hd.a, hd.b]
		for i in w.points:
			var o: int = i * WAKE.FLOATS
			if old.size() >= 2 and Vector3(u[o], u[o + 1], u[o + 2]).distance_to(old[0]) < 0.001 and Vector3(u[o + 3], u[o + 4], u[o + 5]).distance_to(old[1]) < 0.001:
				if k == 5:
					old.append_array([u[o + 8], u[o + 11]])
				elif k == 13:
					after = [u[o + 8], u[o + 11]]
	check(old.size() == 4 and after.size() == 2, "restart: the old trail's piece is still there after the restart")
	if old.size() == 4 and after.size() == 2:
		check(absf(float(after[0]) - float(old[2])) < 0.001 and absf(float(after[1]) - float(old[3])) < 0.001,
			"restart: the old trail keeps its bow distance and push (%.3f, %.3f before; %.3f, %.3f after)" % [old[2], old[3], after[0], after[1]])
	ship.queue_free()


# Run 9 lesson: the shader's numbers are filled in by position, and a reordered line once put the bow-wave reach where
# the fade time belongs (the trail faded in 0.35 s). Every number must land in its own place.
func _glsl_check() -> void:
	var g: String = WAKE.glsl(WAKE.HIGH_POINTS)
	var want := {
		"uniform float wake_d[%d];" % (WAKE.HIGH_POINTS * WAKE.FLOATS): "the uniform size",
		"if (min(age_a, age_b) >= %.3f)" % WAKE.FADE_S: "the skip of faded pieces",
		"mix(%.3f, 1.0, smoothstep(0.0, 0.6 * r, behind)) * (1.0 - smoothstep(0.0, %.3f, age))" % [WAKE.BOW_MIN, WAKE.FADE_S]: "the bow ease and the fade time",
		"da * da / (%.3f * %.3f)" % [WAKE.CAP, WAKE.CAP]: "the bow-wave reach",
		"exp((d2 - dmin) / (2.0 * %.3f))" % (WAKE.NEAR * WAKE.NEAR): "the nearest-place blend",
		"(1.0 - smoothstep(%.3f, %.3f, age))" % [WAKE.FADE_S * 0.4, WAKE.FADE_S]: "the hand-over of faded trails",
	}
	for k in want:
		check(g.contains(k), "glsl: %s is in its place (%s)" % [want[k], k])


# Fable on PR 1181: a ship that moved once and then parked kept its newest piece, so once a fleet had each moved, every
# slot was held and a later mover's trail was wiped at every 12 unit seam (about 11 units long instead of 80). A fleet
# bigger than the slot count moves 30 units each, one after another, sits 10 s, then one ship flies 96 units.
func _moved_then_parked_check(quality: String) -> void:
	var src := GDScript.new()
	src.source_code = "extends Node3D\nvar L := 30.0\nvar dead := false\n"
	src.reload()
	var w = WAKE.new(quality)
	var dt := 1.0 / 30.0
	var ships := []
	for i in w.points + 4:
		var p: Node3D = src.new()
		root.add_child(p)
		p.position = Vector3(float(i) * 40.0, 0.0, 200.0)
		ships.append(p)
	var mover: Node3D = src.new()
	root.add_child(mover)
	ships.append(mover)
	w.update(dt, ships)
	for p in ships:
		if p == mover:
			continue
		var start: Vector3 = p.position
		for k in 38:
			p.position = start + Vector3(0.0, 0.0, float(k + 1) * 0.8)
			w.update(dt, ships)
	for k in 300:
		w.update(dt, ships)
	var held := 0
	for e in w._ring:
		if int(e.owner) >= 0:
			held += 1
	check(held == 0, "%s: ships that moved and parked hold no slot after 10 s (%d held)" % [quality, held])
	for k in 120:
		mover.position = Vector3(float(k + 1) * 0.8, 0.0, 0.0)
		w.update(dt, ships)
		if k == 59:
			var key: int = mover.get_instance_id()
			var length := 0.0
			for e in w._ring:
				if int(e.ship) == key and w.clock - float(e.tb) < WAKE.FADE_S:
					length += Vector2(e.b.x - e.a.x, e.b.z - e.a.z).length()
			check(length >= 40.0, "%s: after the fleet moved and parked, a mover's trail is %.1f units long after 48 units (needs 40)" % [quality, length])
	for p in ships: p.queue_free()


# Fable on PR 1181: one long frame (a hitch, or under 10 fps) used to restart a moving ship's trail with a fresh ease-in.
func _hitch_check() -> void:
	var src := GDScript.new()
	src.source_code = "extends Node3D\nvar L := 40.0\nvar dead := false\n"
	src.reload()
	var ship: Node3D = src.new()
	root.add_child(ship)
	var w = WAKE.new("max")
	var x := 0.0
	for k in 60:
		var dt := 0.25 if k == 30 else 1.0 / 30.0
		x += dt * 24.0
		ship.position = Vector3(x, 0.0, 0.0)
		w.update(dt, [ship])
	var trails := int(w._trails.get(ship.get_instance_id(), 0))
	check(trails == 1, "hitch: a 0.25 s frame keeps a moving ship on one trail (%d trails)" % trails)
	ship.queue_free()
