extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1685 (R411 Priority 3): the faction idle motions (fx/fx_idle.gd, hooked in fx_ship.gd), view only, on box stand-ins.
# 1. off by default: no flag, no setting, no node, no sprite, no change to a ship's children; VS_IDLE_MOTION=0 forces off
# 2. on: each of the six factions builds its own motion (six distinct names) as one batch of kind 18 sprites under the
#    ship's damage root, on the ship (an authored hp_breach point, else plating found by a ray), in the faction's colours
#    (Eclipse all violet, R372), with no sprite on a squadron
# 3. comfort (RULEBOOK 6.2): every sprite under the flash counter's brightness line, none under 0.5 s, at most 2 starts a
#    second per ship, no counted flash spent over ten effect seconds of a 20-ship fleet, and the fleet's lit area (every
#    sprite at the pixel floor, all at once, at camera 170) under the counter's area limit
# 4. Reduce flashing rebuilds softer (longer, dimmer, same size); Reduce motion stops the radar sweep; both back again
#    without leaking a node
# 5. a dead ship's motion is hidden, a revived one's is back, a removed ship's node is freed
# 6. ships pulse out of step; the per-ship step costs next to nothing
const FX := preload("res://fx/fx.gd")
const IDLE := preload("res://fx/fx_idle.gd")
const FACS := ["hegemony", "voidsworn", "corsair", "ithar", "deathless", "chorus"]
var failures := 0
var fx
var world: Node3D
var cam: Camera3D
var _calm_script: GDScript


func _init() -> void:
	GUARD.arm(self, "idle_motion_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("  ok: ", message)


func _box(size: Vector3, sub: int) -> ArrayMesh:
	var bm := BoxMesh.new()
	bm.size = size
	bm.subdivide_width = sub
	bm.subdivide_depth = maxi(sub / 3, 1)
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bm.get_mesh_arrays())
	return am


# A cruiser stand-in 24 long, 5 high, 8 wide, with a root that has the Reduce motion field (calm) the way ShipView does.
# `breach`: authored hp_breach_<n> points on the hull (upper deck and flanks), or none (the ray fallback).
func _ship(sid: String, faction: String, pos: Vector3, breach: bool, cls := "Cruiser"):
	var body := Node3D.new()
	body.set_script(_calm_script)
	world.add_child(body)
	body.position = pos
	var hull := MeshInstance3D.new()
	hull.name = "hull"
	hull.mesh = _box(Vector3(24, 5, 8), 17)
	body.add_child(hull)
	if breach:
		var spots := [[Vector3(8, 2.5, 1.5), Basis.IDENTITY], [Vector3(0, 2.5, -2), Basis.IDENTITY], [Vector3(-8, 2.5, 2), Basis.IDENTITY],
			[Vector3(4, 0.5, 4.0), Basis(Vector3.RIGHT, PI / 2.0)], [Vector3(-4, 0.5, -4.0), Basis(Vector3.RIGHT, -PI / 2.0)]]
		for i in spots.size():
			var hp := Node3D.new()
			hp.name = "hp_breach_%d" % i
			hp.transform = Transform3D(spots[i][1], spots[i][0])
			body.add_child(hp)
	fx.add_ship(sid, body, {"faction": faction, "cls": cls, "size": 0.8, "meshes": [hull], "shielded": false})
	fx._later.clear()
	return fx.ship(sid)


func _idle_nodes(s) -> int:
	var n := 0
	for c in s._dmg_root.get_children():
		if String(c.name).begins_with("fx_idle") and not c.is_queued_for_deletion():
			n += 1
	return n


func settle(secs: float) -> void:
	for i in int(secs / 0.05):
		fx.step(0.05)


func _col_ok(faction: String, c: Color) -> bool:
	match faction:
		"deathless": return c.b >= c.r and c.r > c.g and c.b > 0.9 * maxf(c.r, c.g)   # violet, never green or gold (R372)
		"hegemony": return c.b > c.r and c.b >= c.g              # steel blue
		"voidsworn", "corsair": return c.r > c.g and c.g > c.b   # ember, red
		"chorus": return c.g > c.b and c.g >= c.r * 0.9          # bile green-yellow
		"ithar": return c.r > 0.5 and c.g > 0.5 and c.b > 0.5    # pale, stored light
	return false


func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	_calm_script = GDScript.new()
	_calm_script.source_code = "extends Node3D\nvar calm := false\n"
	_calm_script.reload()
	cam = Camera3D.new()
	cam.fov = 45.0
	world.add_child(cam)
	cam.current = true
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "high", "shake": 0.0})
	fx.reduce_flashing = false
	settle(1.0)

	# 1. off by default
	OS.unset_environment("VS_IDLE_MOTION")
	check(not bool(ProjectSettings.get_setting("rendering/effects/idle_motion", false)), "the project setting is off (default)")
	check(not IDLE.enabled(), "no switch and no setting: idle motion is off")
	var off_nodes := 0
	for faction in FACS:
		var s = _ship("off_" + faction, faction, Vector3(0, 0, 0), true)
		settle(0.5)
		off_nodes += s._dmg_root.get_child_count()
		check(not s.idle_on and s._idle.is_empty() and _idle_nodes(s) == 0, "%s: off by default, nothing built" % faction)
		fx.remove_ship("off_" + faction)
	OS.set_environment("VS_IDLE_MOTION", "0")
	check(not IDLE.enabled(), "VS_IDLE_MOTION=0 is off")
	OS.set_environment("VS_IDLE_MOTION", "true")
	check(IDLE.enabled(), "VS_IDLE_MOTION=true is on")
	OS.set_environment("VS_IDLE_MOTION", "1")
	check(IDLE.enabled(), "VS_IDLE_MOTION=1 is on")

	# 2. on, each faction
	var names := {}
	var ships := {}
	var x := 0.0
	for faction in FACS:
		for authored in [true, false]:
			var sid := "on_%s_%s" % [faction, "hp" if authored else "ray"]
			var s = _ship(sid, faction, Vector3(x, 0, 0), authored)
			x += 40.0
			settle(0.3)
			var m: Dictionary = IDLE.motion_of(faction)
			check(s.idle_on and not s._idle.is_empty() and _idle_nodes(s) == 1,
				"%s (%s): the motion is built, one holder" % [faction, "authored points" if authored else "plating rays"])
			if s._idle.is_empty():
				continue
			names[s._idle["motion"]] = true
			ships[sid] = s
			var rows: Array = s._idle["rows"]
			check(rows.size() >= 1 and rows.size() <= IDLE.MAX_SPRITES, "%s: %d sprites (1 to %d)" % [faction, rows.size(), IDLE.MAX_SPRITES])
			var mi := (s._idle["node"] as Node3D).get_child(0) as MeshInstance3D
			check(mi != null and mi.mesh.get_surface_count() == 1 and mi.get_parent().get_parent() == s._dmg_root,
				"%s: one mesh in one draw call, under the damage root" % faction)
			var colours := true
			var on_ship := true
			var kinds := true
			var hbox: AABB = s.hull.box.grow(s.hull.L * 0.12)
			for r in rows:
				colours = colours and _col_ok(faction, r["col"])
				on_ship = on_ship and hbox.has_point(r["p"])
				kinds = kinds and int(r["kind"]) == IDLE.KIND
			check(colours, "%s: the glow colours are the faction's own%s" % [faction, " (all violet, R372)" if faction == "deathless" else ""])
			check(on_ship, "%s: every sprite sits on the ship, not in empty space" % faction)
			check(kinds, "%s: every sprite is the soft kind (18)" % faction)
			if authored and faction != "hegemony" and faction != "deathless":
				# the authored hard points are where the sprites sit
				var near := 0
				for r in rows:
					for i in 5:
						var hp: Node3D = s.root.get_node("hp_breach_%d" % i)
						if hp.position.distance_to(r["p"]) <= r["s1"] * 0.75:
							near += 1
							break
				# the stand-in has three upward breach points; the motion uses them first and fills the rest from plating rays
				check(near >= mini(rows.size(), 3), "%s: sprites sit on its upward hp_breach points (%d of %d, the rest from plating)" % [faction, near, rows.size()])
			# 3. comfort
			var st := IDLE.stats(rows)
			check(st["max_i"] < FX.FLASH_I and st["max_i"] <= IDLE.MAX_I, "%s: brightest %.2f, under the counter's line %.1f" % [faction, st["max_i"], FX.FLASH_I])
			check(st["min_life"] >= IDLE.MIN_LIFE, "%s: shortest pulse %.2f s (at least %.2f)" % [faction, st["min_life"], IDLE.MIN_LIFE])
			check(st["starts_per_s"] <= IDLE.MAX_STARTS_PER_S, "%s: %.2f pulse starts a second (at most %.1f)" % [faction, st["starts_per_s"], IDLE.MAX_STARTS_PER_S])
	check(names.size() == 6, "six factions, six different motions (%s)" % ", ".join(names.keys()))
	var sq = _ship("on_squad", "hegemony", Vector3(x, 0, 80), true, "Squadron")
	settle(0.2)
	check(sq.squadron and sq._idle.is_empty() and _idle_nodes(sq) == 0, "a strike craft wing has no idle motion")

	# phase: the same faction's ships do not pulse together
	var offs := {}
	for i in 8:
		var s = _ship("ph_%d" % i, "chorus", Vector3(i * 30.0, 0, -120), true)
		offs[snappedf(float(s._idle["rows"][0]["t"]), 0.01)] = true
	check(offs.size() >= 5, "eight Chorus ships start at %d different phases" % offs.size())

	# 4. Reduce flashing and Reduce motion
	var h = ships["on_hegemony_hp"]
	var base_rows: Array = (h._idle["rows"] as Array).duplicate(true)
	check(base_rows.size() == 4, "Hegemony: the radar sweeps through four blips")
	fx.reduce_flashing = true
	fx.step(0.05)
	var soft_rows: Array = h._idle["rows"]
	check(soft_rows.size() == base_rows.size() and soft_rows[0]["life"] > base_rows[0]["life"] * 1.4 and soft_rows[0]["i"] < base_rows[0]["i"] * 0.7
		and is_equal_approx(soft_rows[0]["s1"], base_rows[0]["s1"]), "Reduce flashing: longer, dimmer, same size")
	check(IDLE.stats(soft_rows)["starts_per_s"] < IDLE.stats(base_rows)["starts_per_s"], "Reduce flashing: fewer starts a second")
	check(_idle_nodes(h) == 1, "Reduce flashing: one holder after the rebuild")
	for faction in FACS:
		var sr: Array = ships["on_%s_hp" % faction]._idle["rows"]
		var stt := IDLE.stats(sr)
		check(stt["min_life"] >= IDLE.MIN_LIFE and stt["max_i"] < FX.FLASH_I and stt["starts_per_s"] <= IDLE.MAX_STARTS_PER_S,
			"%s: Reduce flashing keeps every comfort limit" % faction)
	fx.reduce_flashing = false
	fx.step(0.05)
	check((h._idle["rows"] as Array)[0]["life"] == base_rows[0]["life"] and _idle_nodes(h) == 1, "Reduce flashing off: back to the normal motion, one holder")
	h.root.calm = true
	fx.step(0.05)
	check((h._idle["rows"] as Array).size() == 1 and _idle_nodes(h) == 1, "Reduce motion: the sweep stops (one steady blip)")
	h.root.calm = false
	fx.step(0.05)
	check((h._idle["rows"] as Array).size() == 4 and _idle_nodes(h) == 1, "Reduce motion off: the sweep is back")
	var v = ships["on_voidsworn_hp"]
	var v_before: int = (v._idle["rows"] as Array).size()
	v.root.calm = true
	fx.step(0.05)
	check((v._idle["rows"] as Array).size() == v_before, "Reduce motion leaves a swell alone")
	v.root.calm = false
	fx.step(0.05)

	# 5. death, revive, removal
	var dd = ships["on_deathless_hp"]
	var node: Node3D = dd._idle["node"]
	check(node.visible, "a live ship shows its motion")
	dd.dead = true
	fx.step(0.05)
	check(not node.visible, "a dead ship's motion is hidden")
	dd.dead = false
	fx.step(0.05)
	check(node.visible, "a revived ship's motion is back")
	var gone_node: Node3D = node
	fx.remove_ship("on_deathless_hp")
	check(not is_instance_valid(gone_node) or gone_node.is_queued_for_deletion() or not gone_node.is_inside_tree() or dd._dmg_root.is_queued_for_deletion(),
		"removing the ship frees its motion with its damage root")

	# 3 again, as a fleet: twenty ships, ten effect seconds, no counted flash, the lit area under the limit
	for k in ships.keys():
		fx.remove_ship(k)
	for i in 8:
		fx.remove_ship("ph_%d" % i)
	fx.remove_ship("on_squad")
	settle(0.2)
	cam.look_at_from_position(Vector3(0, 140, 100), Vector3.ZERO)
	var fleet: Array = []
	for i in 20:
		var faction: String = FACS[i % FACS.size()]
		var s = _ship("fl_%d" % i, faction, Vector3((i % 5 - 2) * 16.0, 0, (i / 5 - 1.5) * 14.0), i % 2 == 0)
		fleet.append(s)
	var flashes0: int = fx.flash_log.size()
	var counted0: int = fx.flash_log.size()
	settle(10.0)
	check(fx.flash_log.size() == counted0, "20 ships idle for 10 s: no counted flash spent (%d)" % (fx.flash_log.size() - flashes0))
	var worst_starts := 0.0
	var sprites := 0
	var peak := 0.0
	# every 0.1 s of a 12 s window: the area of the sprites more than half lit at that instant, each at the pixel floor
	for k in 120:
		var tt := float(k) * 0.1
		var area := 0.0
		for s in fleet:
			for r in s._idle["rows"]:
				var age := fposmod(tt - float(r["t"]), float(r["period"]))
				if age < float(r["life"]) and sin(PI * age / float(r["life"])) > 0.5:
					var disc: PackedFloat64Array = fx._flash_disc(s.to_world(r["p"]), float(r["s1"]), 10.0)
					if not disc.is_empty():
						area += PI * 0.25 * disc[2] * disc[2]
		peak = maxf(peak, area)
	for s in fleet:
		var st := IDLE.stats(s._idle["rows"])
		worst_starts = maxf(worst_starts, st["starts_per_s"])
		sprites += (s._idle["rows"] as Array).size()
	var limit: float = fx.flash_limit_px2()
	check(sprites > 20 and peak < limit, "the fleet's lit area at its worst instant (sprites over half lit, each at the pixel floor): %.0f px2 of %.0f allowed (%d sprites)" % [peak, limit, sprites])
	check(worst_starts <= IDLE.MAX_STARTS_PER_S, "no ship starts more than %.1f pulses a second (worst %.2f)" % [IDLE.MAX_STARTS_PER_S, worst_starts])

	# 6. cost: the per-ship step is a compare and nothing else
	var t0 := Time.get_ticks_usec()
	for k in 200:
		for s in fleet:
			s._idle_step(fx)
	var per_us := float(Time.get_ticks_usec() - t0) / 4000.0
	check(per_us < 20.0, "the per-ship idle step costs %.2f us" % per_us)
	print("idle_motion_check: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	OS.unset_environment("VS_IDLE_MOTION")
	quit(1 if failures > 0 else 0)
