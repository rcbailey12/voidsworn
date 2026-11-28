extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1587 (Neon's Nov 21-22 hull FX audit, Refs #1239 Top 6): live hull wounds on box stand-ins, view only.
# 1. engine section at stage 3+: one sick nozzle in its own batches, its gate has dropouts (gentler under reduce flashing),
#    and it coughs once as the ship starts to move (not again within COUGH_GAP)
# 2. mid or prow at stage 3+: one turret there freezes 12 to 25 degrees off its aim and sags, ignores new aims, trails a
#    wisp that takes a smoke slot (the class caps hold), pops a spark every 2 to 4 s; the hull's power flickers (fx_flick)
#    while fx_power keeps the wear's steady value; repaired, the turret tracks again and the wisp node is freed
# 3. a one-shot blowout only when a section crosses into stage 3 or 4: none on a view rebuilt already hurt, none on a
#    repeat sync at the same stage
# 4. an ion hit's crawl: 2 or 3 threads (the dip is the hit's own brownout, issue 1690)
# 5. the shield-break beat (brief section 3) is still 0.08 s on main
const FX := preload("res://fx/fx.gd")
const SHIP := preload("res://fx/fx_ship.gd")
const HULL := preload("res://fx/fx_hull.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
var failures := 0
var fx
var world: Node3D


func _init() -> void:
	# Issue 1741 (Nov 24): Wounds V2 is on by default and its tiered drive (more than one nozzle dims, engine_tier_for) is
	# checked by capability_loss_check.gd; this check keeps the one-sick-nozzle path that V2 off still uses
	OS.set_environment("VS_WOUNDS_V2", "0")
	GUARD.arm(self, "live_wounds_1587_check")
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


# A cruiser stand-in with a turret in the mid section and one on the prow.
func _ship(sid: String, faction: String, pos: Vector3):
	var body := Node3D.new()
	world.add_child(body)
	body.position = pos
	var hull := MeshInstance3D.new()
	hull.name = "hull"
	hull.mesh = _box(Vector3(24, 5, 8), 17)
	body.add_child(hull)
	var meshes: Array = [hull]
	for row in [["turret_1", 9.0], ["turret_2", 0.0]]:
		var tur := Node3D.new()
		tur.name = row[0]
		tur.position = Vector3(row[1], 2.5, 0)
		body.add_child(tur)
		var tm := MeshInstance3D.new()
		tm.name = "turret_mesh"
		tm.mesh = _box(Vector3(2, 1, 2), 2)
		tm.position = Vector3(0, 0.5, 0)
		tur.add_child(tm)
		meshes.append(tm)
	fx.add_ship(sid, body, {"faction": faction, "cls": "Cruiser", "size": 0.8, "meshes": meshes, "shielded": false})
	fx._later.clear()
	var s = fx.ship(sid)
	s.wound_log_on = true
	for i in 3:
		s._anchors["a%d" % i] = {"p": Vector3((i - 1) * 7, 2.5, 0), "n": Vector3.UP, "t": {}}
	return s


# The lowest fx_flick on a ship's live damage meshes (1.0 when it has none).
func _live_flick(s) -> float:
	var lo := 1.0
	for mi: MeshInstance3D in s.meshes:
		var fl = mi.get_instance_shader_parameter(&"fx_flick")
		if fl != null: lo = minf(lo, float(fl))
	return lo


func _state(eng: float, mid: float, prow: float) -> Dictionary:
	return {"hp": (eng + mid + prow) / 3.0, "maxHp": 100.0, "sec": {"eng": {"hp": eng, "max": 100}, "mid": {"hp": mid, "max": 100}, "prow": {"hp": prow, "max": 100}}}


func flush(s) -> void:
	for i in 5:
		if s._dmg_task >= 0:
			s.flush_damage(fx)
		fx.step(0.01)


func settle(secs: float) -> void:
	for i in int(secs / 0.05):
		fx.step(0.05)


func _log(s, kind: String) -> int:
	var n := 0
	for e in s.wound_log:
		if e[0] == kind:
			n += 1
	return n


func _wisps(s) -> int:
	var n := 0
	for c in s._dmg_root.get_children():
		if String(c.name).begins_with("fx_damage_wisp") and not c.is_queued_for_deletion():
			n += 1
	return n


# Damage emitter nodes still standing (a freed one is only queued until the frame ends; this check runs inside one).
func _emitters(s) -> int:
	var n := 0
	for c in s._dmg_root.get_children():
		if String(c.name).begins_with("fx_damage_") and String(c.name) != "fx_damage_marks" and not c.is_queued_for_deletion():
			n += 1
	return n


func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})
	fx.reduce_flashing = false
	settle(1.0)
	var x := 0.0
	for faction in ["voidsworn", "ithar", "chorus", "deathless"]:
		var s = _ship("w_" + faction, faction, Vector3(x, 0, 0))
		x += 60.0
		s.sync(fx, _state(100, 100, 100))
		settle(1.0)
		check(s.sick_nozzle == -1 and s.jammed_turrets().is_empty() and s.power_flicker(fx.now) == 1.0,
			"%s: a healthy ship has no sick nozzle, no jammed turret and steady power" % faction)
		check(s.hull.turret_section(0) == HULL.SEC_PROW and s.hull.turret_section(1) == HULL.SEC_MID,
			"%s: the stand-in has a prow turret and a mid turret" % faction)
		# Neon on PR 1631: an ion hit on a fresh hull (no breach yet, so no damage surfaces) still browns it out; since
		# PR 1699 (Neon item c) the hit's own brownout (hit_power) is the one path
		check(s._damage_surfaces.is_empty(), "%s: a fresh hull has no damage surfaces yet" % faction)
		s.hit_power(fx, true, 0.62, 0.5)
		fx.step(0.05)
		var dip_lo := _live_flick(s)
		check(not s._damage_surfaces.is_empty() and dip_lo < 0.6, "%s: an ion dip on a fresh hull dims its lights (%d surfaces, fx_flick %.2f)" % [faction, s._damage_surfaces.size(), dip_lo])
		settle(1.0)
		var nodes0: int = _emitters(s)

		# 1. the sick engine
		s.sync(fx, _state(30, 100, 100))
		flush(s)
		check(s.stage[0] == 3 and s.sick_nozzle >= 0 and s.sick_nozzle < s.hull.nozzles.size() and s._sick_mat != null,
			"%s: engine section at stage 3 picks one sick nozzle (%d of %d)" % [faction, s.sick_nozzle, s.hull.nozzles.size()])
		var lo := 9.0
		var hi := 0.0
		var dark := 0
		for j in 400:
			var g: float = s.sick_gate(j * 0.005)
			lo = minf(lo, g)
			hi = maxf(hi, g)
			if g < 0.2:
				dark += 1
		check(lo <= 0.15 and hi >= 0.9 and dark > 40 and dark < 160, "%s: the sick nozzle gutters with gaps (%.2f to %.2f, %d of 400 dark)" % [faction, lo, hi, dark])
		var rlo := 9.0
		for j in 400:
			rlo = minf(rlo, s.sick_gate(j * 0.005, true))
		check(rlo >= 0.4, "%s: under reduce flashing it only sways (lowest %.2f)" % [faction, rlo])
		check(absf(SHIP.SICK_LEN - 0.6) < 1e-6, "%s: the sick plume is 60%% as long" % faction)
		settle(1.0)
		var c0 := _log(s, "cough")
		s.root.position += Vector3(1, 0, 0)
		fx.step(0.02)
		check(_log(s, "cough") == c0 + 1, "%s: it coughs as the ship starts to move" % faction)
		for j in 5:
			s.root.position += Vector3(1, 0, 0)
			fx.step(0.02)
		settle(0.5)
		s.root.position += Vector3(1, 0, 0)
		fx.step(0.02)
		check(_log(s, "cough") == c0 + 1, "%s: a stop and start inside the cough gap does not cough again" % faction)
		# Neon on PR 1631: the sick nozzle's trail gutters with its plume (dim samples in the gaps), the others stay steady
		for j in 40:
			s.root.position += Vector3(0.5, 0, 0)
			fx.step(0.05)
		var sick_lv: Array = []
		var well_lv: Array = []
		for ti in s._trails.size():
			var hh: Array = s._trails[ti]["hist"]
			for hp in hh.slice(0, 12):   # the newest samples, after the drive has spooled up
				(sick_lv if ti == s.sick_nozzle else well_lv).append(float(hp[2]))
		check(not sick_lv.is_empty() and sick_lv.min() < 0.5 * sick_lv.max() and (well_lv.is_empty() or well_lv.min() > 0.5 * well_lv.max()),
			"%s: the sick nozzle's trail breaks up with its plume (%.2f to %.2f; the others %s)" % [faction, sick_lv.min() if not sick_lv.is_empty() else -1.0, sick_lv.max() if not sick_lv.is_empty() else -1.0, "steady" if well_lv.is_empty() or well_lv.min() > 0.5 * well_lv.max() else "uneven"])
		# Artoo on PR 1631 (after movement 1581 merged): a wounded ship braking with its drive cold still gutters and
		# its trails still age fast; both paths run in the same update
		var te0: float = s._trail_extra
		s.engine_level = 0.05
		for j in 20:
			s.root.position += Vector3(0.5, 0, 0)
			fx.step(0.05)
		s.engine_level = 1.0
		check(s._trail_extra > te0 + 0.5 and s.sick_nozzle >= 0 and s._sick_mat != null,
			"%s: braking with a cold drive ages the trails fast (%.2f) and the sick nozzle stays" % [faction, s._trail_extra - te0])
		s.sync(fx, _state(100, 100, 100))
		flush(s)
		check(s.sick_nozzle == -1 and s._sick_mat == null, "%s: repaired engines lose the sick nozzle" % faction)

		# 2. a wounded mid section: jammed turret, wisp, sparks, flicker
		s.sync(fx, _state(100, 30, 100))
		flush(s)
		var jt: Array = s.jammed_turrets()
		check(jt.size() == 1 and jt[0] == 1 and s.hull.turret_jammed(1), "%s: the mid turret jams at stage 3 (%s)" % [faction, str(jt)])
		settle(0.5)
		var y: float = s.hull.turrets[1]["yaw"]
		check(absf(y) >= 12.0 - 1e-3 and absf(y) <= 25.0, "%s: it froze %.1f degrees off its aim" % [faction, y])
		var aim: Dictionary = s.hull.turret_aim(1, Vector3(0, 2.5, 40), fx.now)
		settle(1.0)
		check(absf(float(aim["yaw"]) - y) < 1e-3 and absf(float(s.hull.turrets[1]["yaw"]) - y) < 1e-3, "%s: a jammed turret ignores a new aim" % faction)
		var bs: Basis = (s.hull.turrets[1]["node"] as Node3D).transform.basis
		var fwd: Vector3 = bs * Vector3(0, 0, -1)
		check(fwd.y < -0.05, "%s: the jammed turret sags on its mount (%.3f)" % [faction, fwd.y])
		check(not s.hull.turret_jammed(0), "%s: the prow turret still tracks" % faction)
		check(_wisps(s) == 1, "%s: the jammed turret trails one wisp" % faction)
		# the stand-in has no gun points: two on the same slot, one per turret, so gun_turrets must choose
		var tgt := Vector3.ZERO
		for cand in [Vector3(0, 2.5, 40), Vector3(0, 2.5, -40), Vector3(40, 2.5, 0), Vector3(-40, 2.5, 0), Vector3(0, 40, 0)]:
			if s.hull.turret_reaches(0, cand) and s.hull.turret_reaches(1, cand):
				tgt = cand
				break
		var gp_was = s.hull.points.get("gun")
		s.hull.points["gun"] = [{"slot": 0, "weapon": "x", "tur": 0}, {"slot": 0, "weapon": "x", "tur": 1}]
		var trained: Array = s.hull.gun_turrets(0, "x", tgt, 2)
		if gp_was == null: s.hull.points.erase("gun")
		else: s.hull.points["gun"] = gp_was
		check(tgt != Vector3.ZERO and trained == [0], "%s: a Burn and fire never trains the jammed turret (%s)" % [faction, str(trained)])
		var caps: Vector2i = s.damage_caps(fx.cap_k)
		var cnt: Dictionary = s.damage_counts()
		check(cnt.fire <= caps.x and cnt.smoke + cnt.vent <= caps.y, "%s: the wisp stays inside the class caps" % faction)
		var sp0 := _log(s, "spark")
		settle(4.5)
		check(_log(s, "spark") >= sp0 + 1 and _log(s, "spark") <= sp0 + 3, "%s: spark pops every 2 to 4 s (%d in 4.5 s)" % [faction, _log(s, "spark") - sp0])
		var vals := {}
		for j in 120:
			vals[s.power_flicker(fx.now + j * 0.0833)] = true
		var fmin := 1.0
		for v in vals:
			fmin = minf(fmin, float(v))
		check(vals.size() >= 3 and fmin >= 0.5 - 1e-6 and fmin < 0.95, "%s: the power flickers unevenly (%d levels, lowest %.2f)" % [faction, vals.size(), fmin])
		var flick_seen := false
		var power_steady := true
		var want_power: float = 1.0 - HULL.WEAR_POWER * s.hull_wear
		for j in 40:
			fx.step(0.05)
			flick_seen = flick_seen or _live_flick(s) < 0.99
			for key in s._damage_surfaces:
				var e: Array = s._damage_surfaces[key]
				if e.size() > 1 and e[1] is ShaderMaterial:
					var m: ShaderMaterial = e[1]
					power_steady = power_steady and absf(float(m.get_shader_parameter("fx_power")) - want_power) < 1e-4
		check(flick_seen, "%s: the flicker reaches the hull's damage surfaces" % faction)
		check(power_steady, "%s: fx_power keeps the wear's steady value under the flicker" % faction)
		# repaired: the turret tracks again, the wisp goes
		s.sync(fx, _state(100, 100, 100))
		flush(s)
		check(not s.hull.turret_jammed(1) and s.jammed_turrets().is_empty(), "%s: a repaired section frees its turret" % faction)
		settle(1.2)
		check(absf(float(s.hull.turrets[1]["yaw"])) < 0.5, "%s: the freed turret trains back to rest" % faction)
		s.hull.turret_aim(1, Vector3(0, 2.5, 40), fx.now)
		settle(3.0)
		check(absf(float(s.hull.turrets[1]["yaw"])) > 30.0, "%s: and tracks a new aim again" % faction)
		check(_wisps(s) == 0, "%s: the wisp is freed on repair" % faction)
		settle(0.5)
		check(_emitters(s) <= nodes0, "%s: no damage emitter nodes left over once repaired (%d, was %d)" % [faction, _emitters(s), nodes0])
		check(s.power_flicker(fx.now) == 1.0, "%s: repaired power is steady" % faction)

		# 3. blowouts on threshold crossings only
		var b0 := _log(s, "blowout")
		s.sync(fx, _state(100, 50, 100))
		flush(s)
		check(_log(s, "blowout") == b0, "%s: stage 2 does not vent" % faction)
		s.sync(fx, _state(100, 30, 100))
		flush(s)
		check(_log(s, "blowout") == b0 + 1, "%s: crossing into stage 3 vents once" % faction)
		s.sync(fx, _state(100, 28, 100))
		flush(s)
		check(_log(s, "blowout") == b0 + 1, "%s: a repeat sync at stage 3 does not vent again" % faction)
		s.sync(fx, _state(100, 10, 100))
		flush(s)
		check(_log(s, "blowout") == b0 + 2, "%s: crossing into stage 4 vents once more" % faction)
		var cnt4: Dictionary = s.damage_counts()
		check(cnt4.fire <= caps.x and cnt4.smoke + cnt4.vent <= caps.y, "%s: blowouts add no standing emitters" % faction)
		s.sync(fx, _state(100, 100, 100))
		flush(s)
		settle(1.0)

		# 4. the ion crawl
		var r0: int = fx.pools["rib"].emitted
		var pd0 := _log(s, "power_dip")
		WEAP._ion_crawl(fx, s, s.to_world(Vector3(0, 2.5, 0)), Vector3.UP, fx.now, Color(0.5, 0.7, 1.0), 1.0)
		# issue 1690 (Artoo on PR 1699): the hit's own brownout (hit_power) is the ion dip; the crawl adds none of its own
		var r1: int = fx.pools["rib"].emitted
		settle(0.1)
		check(_log(s, "power_dip") == pd0, "%s: the crawl adds no second power dip" % faction)
		check(r1 - r0 >= 2 and r1 - r0 <= 3, "%s: 2 or 3 crawl threads (%d)" % [faction, r1 - r0])
		settle(1.0)

	# a view rebuilt already hurt (Continue): no blowout
	var rb = _ship("rebuilt", "hegemony", Vector3(0, 0, 80))
	rb.sync(fx, _state(30, 10, 30))
	flush(rb)
	check(_log(rb, "blowout") == 0, "a view rebuilt already hurt does not vent")
	# Artoo on PR 1631: a fresh ship whose first sync is healthy and whose very next hit crosses a threshold does vent
	var fr = _ship("fresh", "hegemony", Vector3(60, 0, 80))
	fr.sync(fx, _state(100, 100, 100))
	fr.sync(fx, _state(100, 30, 100))
	flush(fr)
	check(_log(fr, "blowout") == 1, "a real threshold hit right after arrival still vents")
	var quiet = _ship("quiet", "hegemony", Vector3(120, 0, 80))
	quiet.wound_log_on = false
	quiet.sync(fx, _state(100, 100, 100))
	quiet.sync(fx, _state(100, 10, 100))
	settle(5.0)
	check(quiet.wound_log.is_empty(), "the wound history stays off in play")
	# Fable audit Nov 22, finding 1: a hull that dies during a hit brownout, or while a wounded hull flickers, starts its
	# death at full light (the death reuses the hull mesh, fx_flick included)
	for row in [["die_dipped", false], ["die_flicker", true]]:
		var d = _ship(row[0], "hegemony", Vector3(180, 0, 80 + (60 if row[1] else 0)))
		d.sync(fx, _state(100, 100, 100))
		settle(0.5)
		if row[1]:
			d.sync(fx, _state(100, 25, 25))
			flush(d)
			var tries := 0
			while _live_flick(d) > 0.8 and tries < 400:
				fx.step(1.0 / 60.0)
				tries += 1
		else:
			d.hit_power(fx, true, 0.70, 0.6)
			fx.step(0.05)
		var before := _live_flick(d)
		var hull_mi: MeshInstance3D = d.meshes[0]
		fx.death(row[0], "blast")
		fx.step(0.05)
		var flick = hull_mi.get_instance_shader_parameter(&"fx_flick")
		var seen := 0
		var power_down_only := true
		for i in hull_mi.mesh.get_surface_count():
			var m = hull_mi.get_surface_override_material(i)
			if m is ShaderMaterial and m.get_shader_parameter("death_span") != null:
				seen += 1
				power_down_only = power_down_only and not m.shader.code.contains("* fx_flick;")
		check(before < 0.8 and seen > 0 and flick == 1.0 and power_down_only,
			"%s: the death starts at full light (live fx_flick %.2f, death copies %d, new fx_flick %s)" % [row[0], before, seen, flick])
	check(WEAP.BREAK_HULL_BEAT == 0.08, "the shield-break beat is 0.08 s (brief section 3, already on main)")
	print("live_wounds_1587_check: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
