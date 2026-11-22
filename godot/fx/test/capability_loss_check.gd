extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1741 Milestone 3 (R416, Wounds V2 behind VS_WOUNDS_V2=1): what the rules took is what the hull shows. Box stand-ins
# with two turrets (slot 0 on the prow, slot 1 midship), one fixed launcher (slot 2) and three engine bells, all six factions.
# 1. a slot the view holds off (weapons[i].off > 0) jams exactly that slot's turret, with one wisp; a fixed mount of a
#    knocked-out slot smokes and sparks; a repair frees both; a wounded section with no slot off jams nothing
# 2. the drive fails in tiers: an engine hit guttering one nozzle, stage 3 one dark, crippled all but one dark (35% plume),
#    sparks from the dark bells as the ship tries to move; repaired, all burn again
# 3. only the Hullbreakers' drive ever coughs soot (the fx_ship.gd:331 leak), and no trail takes the soot style elsewhere
# 4. a shielded ship's lost generator crackles on the midship plating while the shield stays down (less often under
#    reduce flashing); unshielded factions never crackle
# 5. flag off: main's behaviour (the section's random turret, no slot jams, the old sputter)
# 6. the damage emitters stay inside the class caps and are freed after the repair
const FX := preload("res://fx/fx.gd")
const SHIP := preload("res://fx/fx_ship.gd")
const HULL := preload("res://fx/fx_hull.gd")
const FACTIONS := ["voidsworn", "hegemony", "corsair", "chorus", "ithar", "deathless"]
var failures := 0
var fx
var world: Node3D


func _init() -> void:
	GUARD.arm(self, "capability_loss_check")
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


func _point(parent: Node3D, nm: String, pos: Vector3, yaw_deg := 0.0) -> Node3D:
	var n := Node3D.new()
	n.name = nm
	n.position = pos
	n.rotation_degrees = Vector3(0, yaw_deg, 0)
	parent.add_child(n)
	return n


func _ship(sid: String, faction: String, pos: Vector3, v2: bool):
	var body := Node3D.new()
	world.add_child(body)
	body.position = pos
	var hull := MeshInstance3D.new()
	hull.name = "hull"
	hull.mesh = _box(Vector3(24, 5, 8), 17)
	body.add_child(hull)
	var meshes: Array = [hull]
	for row in [["turret_1", 9.0, "hp_w0_lance_F_0"], ["turret_2", 0.0, "hp_w1_gun_T_0"]]:
		var tur := _point(body, row[0], Vector3(row[1], 2.5, 0))
		var tm := MeshInstance3D.new()
		tm.name = "turret_mesh"
		tm.mesh = _box(Vector3(2, 1, 2), 2)
		tm.position = Vector3(0, 0.5, 0)
		tur.add_child(tm)
		meshes.append(tm)
		_point(tur, row[2], Vector3(0, 0.6, -1.4))
	_point(body, "hp_w2_torp_P_0", Vector3(-3, 0, -4.05), 0.0)
	for k in 3:
		var e := _point(body, "hp_eng_%d" % k, Vector3(-12.05, 0, (k - 1) * 2.5), 90.0)
		e.set_meta("radius", 0.7)
	var shielded: bool = faction in ["voidsworn", "hegemony", "corsair", "ithar"]
	fx.add_ship(sid, body, {"faction": faction, "cls": "Cruiser", "size": 0.8, "meshes": meshes, "shielded": shielded})
	fx._later.clear()
	var s = fx.ship(sid)
	s.wounds_v2 = v2
	s.wound_log_on = true
	for i in 3:
		s._anchors["a%d" % i] = {"p": Vector3((i - 1) * 7, 2.5, 0), "n": Vector3.UP, "t": {}}
	s._anchors["sc01"] = {"p": Vector3(0, 2.5, 2.0), "n": Vector3.UP, "t": {}}
	return s


func _unit(eng: float, mid: float, prow: float, off := [0, 0, 0], eng_hit := false, shield_off := false, eng_broken := false) -> Dictionary:
	var ws: Array = []
	for i in off.size():
		ws.append({"i": i, "id": ["lance", "gun", "torp"][i], "arc": ["F", "T", "P"][i], "off": off[i]})
	return {"hp": (eng + mid + prow) / 3.0, "maxHp": 100.0, "weapons": ws, "engHit": eng_hit, "shieldOff": shield_off,
		"sec": {"eng": {"hp": eng, "max": 100, "broken": eng_broken}, "mid": {"hp": mid, "max": 100}, "prow": {"hp": prow, "max": 100}}}


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


func _nodes(s, prefix: String) -> int:
	var n := 0
	for c in s._dmg_root.get_children():
		if String(c.name).begins_with(prefix) and not c.is_queued_for_deletion():
			n += 1
	return n


func _caps_ok(s) -> bool:
	var caps: Vector2i = s.damage_caps(fx.cap_k)
	var cnt: Dictionary = s.damage_counts()
	return cnt.fire <= caps.x and cnt.smoke + cnt.vent <= caps.y


func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})
	fx.reduce_flashing = false
	settle(1.0)
	check(SHIP.engine_tier_for(0, false) == 0 and SHIP.engine_tier_for(0, true) == 1 and SHIP.engine_tier_for(2, false) == 1
		and SHIP.engine_tier_for(3, false) == 2 and SHIP.engine_tier_for(4, false) == 3 and SHIP.engine_tier_for(4, true) == 3,
		"the drive's tiers: hit or stage 2 is 1, stage 3 is 2, stage 4 is 3")
	var x := 0.0
	for faction in FACTIONS:
		var s = _ship("c_" + faction, faction, Vector3(x, 0, 0), true)
		x += 60.0
		s.sync(fx, _unit(100, 100, 100))
		flush(s)
		settle(0.5)
		check(s.hull.turrets.size() == 2 and s.hull.turrets_for_slot(0) == [0] and s.hull.turrets_for_slot(1) == [1]
			and s.hull.turrets_for_slot(2).is_empty() and s.hull.mounts_for_slot(2).size() == 1 and s.hull.nozzles.size() == 3,
			"%s: the stand-in reads slot 0 and 1 turrets, one slot 2 launcher and three bells" % faction)
		var cs: Dictionary = s.capability_state()
		check(cs.off.is_empty() and cs.turrets.is_empty() and cs.eng_tier == 0 and cs.sick == -1 and not cs.gen,
			"%s: a healthy ship shows no lost capability" % faction)
		var base_nodes := _nodes(s, "fx_damage_")

		# 1. exact weapon slots
		s.sync(fx, _unit(100, 100, 100, [0, 2, 0]))
		flush(s)
		cs = s.capability_state()
		check(cs.off == [1] and cs.turrets == [1] and s.hull.turret_jammed(1) and not s.hull.turret_jammed(0),
			"%s: a crit on slot 1 jams that slot's own turret only (%s)" % [faction, str(cs)])
		settle(0.5)
		var fwd: Vector3 = (s.hull.turrets[1]["node"] as Node3D).transform.basis * Vector3(0, 0, -1)
		check(fwd.y < -0.05 and absf(float(s.hull.turrets[1]["yaw"])) >= 12.0 - 1e-3, "%s: it hangs off its aim and sags" % faction)
		check(_nodes(s, "fx_damage_wisp") == 1 and _caps_ok(s), "%s: the jammed turret trails one wisp inside the caps" % faction)
		s.sync(fx, _unit(100, 100, 100, [0, 2, 999]))
		flush(s)
		cs = s.capability_state()
		check(cs.off == [1, 2] and cs.mounts == [2] and _nodes(s, "fx_damage_mount") == 1,
			"%s: a lost launcher slot smokes at its own fixed mount" % faction)
		var ms0 := _log(s, "mount_spark")
		settle(5.0)
		check(_log(s, "mount_spark") >= ms0 + 1 and _log(s, "mount_spark") <= ms0 + 3, "%s: the dead mount sparks every 2 to 4.5 s" % faction)
		s.sync(fx, _unit(100, 100, 100, [0, 0, 0]))
		flush(s)
		settle(1.5)
		cs = s.capability_state()
		check(cs.off.is_empty() and cs.turrets.is_empty() and cs.mounts.is_empty() and not s.hull.turret_jammed(1),
			"%s: repaired, the turret tracks again and the mount is quiet" % faction)
		check(_nodes(s, "fx_damage_wisp") == 0 and _nodes(s, "fx_damage_mount") == 0, "%s: the wisp and mount smoke are freed" % faction)
		# a wounded mid section with no slot off: nothing jams (the old random pick is off when the view lists weapons)
		s.sync(fx, _unit(100, 30, 100))
		flush(s)
		check(s.jammed_turrets().is_empty(), "%s: a stage 3 midship with every slot live jams no turret" % faction)
		s.sync(fx, _unit(100, 100, 100))
		flush(s)
		settle(1.0)

		# 2 and 3. the drive in tiers, soot only on the Hullbreakers
		var soot_ok := true
		s.sync(fx, _unit(100, 100, 100, [0, 0, 0], true))
		flush(s)
		cs = s.capability_state()
		check(cs.eng_tier == 1 and cs.sick >= 0 and cs.dead_nozzles.is_empty() and absf(s._sick_len - 0.65) < 1e-6,
			"%s: an engine hit gutters one nozzle at 65%% (%s)" % [faction, str(cs)])
		soot_ok = soot_ok and s.eng_soot == (faction == "corsair")
		s.sync(fx, _unit(30, 100, 100, [0, 0, 0], true))
		flush(s)
		cs = s.capability_state()
		check(cs.eng_tier == 2 and cs.sick >= 0 and cs.dead_nozzles.size() == 1 and not cs.dead_nozzles.has(cs.sick),
			"%s: engine stage 3 darkens one nozzle and gutters another (%s)" % [faction, str(cs)])
		soot_ok = soot_ok and s.eng_soot == (faction == "corsair")
		s.sync(fx, _unit(0, 100, 100, [0, 0, 0], true, false, true))
		flush(s)
		cs = s.capability_state()
		check(cs.eng_tier == 3 and cs.dead_nozzles.size() == 2 and not cs.dead_nozzles.has(cs.sick) and absf(s._sick_len - SHIP.SICK_LEN_CRIPPLED) < 1e-6,
			"%s: engines crippled: all but one bell dark, the last at 35%% (%s)" % [faction, str(cs)])
		soot_ok = soot_ok and s.eng_soot == (faction == "corsair")
		check(_nodes(s, "fx_damage_bell") >= 1 and _caps_ok(s), "%s: the dark bells smoke inside the caps (%d)" % [faction, _nodes(s, "fx_damage_bell")])
		settle(1.0)
		var ss0 := _log(s, "stern_spark")
		s.root.position += Vector3(1, 0, 0)
		fx.step(0.02)
		check(_log(s, "stern_spark") == ss0 + 1, "%s: the dark bells spark as the crippled ship tries to move" % faction)
		for j in 30:
			s.root.position += Vector3(0.5, 0, 0)
			fx.step(0.05)
		var style_ok := true
		var dead_lv := 0.0
		for ti in s._trails.size():
			var st_t := int(s._trails[ti]["style"])
			style_ok = style_ok and (st_t != 1 or faction == "corsair")
			if s.dead_nozzles.has(ti):
				for hp in (s._trails[ti]["hist"] as Array).slice(0, 8):
					dead_lv = maxf(dead_lv, float(hp[2]))
		check(soot_ok and style_ok, "%s: %s" % [faction, "only the Hullbreakers cough soot" if faction == "corsair" else "no soot from a damaged drive, plume or trail"])
		check(dead_lv == 0.0, "%s: a dark bell lays no fresh trail" % faction)
		s.sync(fx, _unit(100, 100, 100))
		flush(s)
		settle(1.0)
		cs = s.capability_state()
		check(cs.eng_tier == 0 and cs.sick == -1 and cs.dead_nozzles.is_empty() and _nodes(s, "fx_damage_bell") == 0,
			"%s: repaired engines all burn again" % faction)

		# 4. the shield generator
		s.sync(fx, _unit(100, 100, 100, [0, 0, 0], false, true))
		flush(s)
		var g0 := _log(s, "gen_arc")
		settle(6.0)
		var arcs := _log(s, "gen_arc") - g0
		if s.shielded:
			check(s.gen_down and arcs >= 2 and arcs <= 5, "%s: the lost generator crackles every 1.4 to 3 s (%d in 6 s)" % [faction, arcs])
			fx.reduce_flashing = true
			g0 = _log(s, "gen_arc")
			settle(6.0)
			var rarcs := _log(s, "gen_arc") - g0
			fx.reduce_flashing = false
			check(rarcs >= 1 and rarcs < arcs, "%s: less often under reduce flashing (%d)" % [faction, rarcs])
			s.sync(fx, _unit(100, 100, 100))
			flush(s)
			g0 = _log(s, "gen_arc")
			settle(4.0)
			check(not s.gen_down and _log(s, "gen_arc") == g0, "%s: back up, the generator is quiet" % faction)
			# the midship lost (the rules' 999) crackles too, with no shieldOff field (a bench unit)
			var u := _unit(100, 0, 100)
			u.erase("shieldOff")
			u["sec"]["mid"]["broken"] = true
			s.sync(fx, u)
			flush(s)
			check(s.gen_down, "%s: a lost midship takes the generator with it" % faction)
			s.sync(fx, _unit(100, 100, 100))
			flush(s)
			settle(1.5)
		else:
			check(not s.gen_down and arcs == 0, "%s: no shield, no generator crackle" % faction)
		check(_nodes(s, "fx_damage_") <= base_nodes, "%s: no damage emitters left after every repair (%d, was %d)" % [faction, _nodes(s, "fx_damage_"), base_nodes])

	# 5. flag off: main's behaviour
	var o = _ship("c_off", "ithar", Vector3(x, 0, 0), false)
	o.sync(fx, _unit(100, 100, 100, [0, 2, 0]))
	flush(o)
	check(o.capability_state().off.is_empty() and o.jammed_turrets().is_empty(), "flag off: a knocked-out slot jams nothing (main)")
	o.sync(fx, _unit(100, 30, 100))
	flush(o)
	check(o.jammed_turrets() == [1], "flag off: the wounded section's turret still jams (main's issue 1587 picker)")
	o.sync(fx, _unit(30, 100, 100, [0, 0, 0], true))
	flush(o)
	check(o.eng_tier == 0 and o.dead_nozzles.is_empty() and o.sick_nozzle >= 0, "flag off: stage 3 engines keep main's single sick nozzle")
	check(not o.gen_down, "flag off: no generator crackle")
	print("capability_loss_check: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
