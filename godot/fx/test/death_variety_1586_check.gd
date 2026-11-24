extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1586 (Neon's Nov 21-22 death audit): death variety from beats, on box stand-ins with the strained death on.
# 1. faction beats on a big hull: Sunward ember ticks, Navy blackout on one frame at the split, Hullbreaker tether snap and
#    cook-offs, Glasswright fracture web and light shafts, Eclipse inward snap, Chorus twitches; the scene dim stays Eclipse
#    only (R389)
# 2. kill causes: flay (jets along the shot and extra shreds), ram (crush sparks and an off-centre spin on the pieces),
#    tidal (with a star), dark (corridor lights, beacon) and board (a dark hulk with airlock vents, no breaking blast)
# 3. small hulls: four seeded archetypes, the same pick for the same ship and death count, all four in use
# 4. strike craft: the corkscrew; 5. the afterlife: 2 or 3 quiet pops on a big wreck within 10 s of the break
# 6. the battle's view cause: "ram" and "board" only right after their event, the rules' cause otherwise
# 7. (Fable audit of PRs 1631 and 1666) a ram kill cuts like the rules' "big"; loose debris and crush sparks take the
#    faction's own matter: metal shards on metal hulls, glass on Glasswrights, bile flecks (no plate) on the Chorus, cold
#    shards on Eclipse, no brass sparks on those three (R367, R402); Directorate shards are cold and its sparks use
#    the blue-white damage glow (issue 1991)
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const BEATS := preload("res://fx/fx_death_beats.gd")
const POOLS := preload("res://fx/fx_pool.gd")
var failures := 0


func _init() -> void:
	GUARD.arm(self, "death_variety_1586_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + why)
	if not ok:
		failures += 1
		push_error(why)


func _count(beats: Array, prefix: String) -> int:
	var n := 0
	for b in beats:
		if String(b).begins_with(prefix):
			n += 1
	return n


func _has(beats: Array, b: String) -> bool:
	return beats.has(b)


func _run() -> void:
	# 1. faction beats
	var res := {}
	for fac in ["voidsworn", "hegemony", "corsair", "ithar", "deathless", "chorus"]:
		res[fac] = await _kill(fac, "Cruiser", 1.0, "blast", 12.0)
	check(_has(res["voidsworn"]["beats"], "embers"), "voidsworn: ember ticks on the hot seams")
	check(_has(res["hegemony"]["beats"], "blackout"), "hegemony: blackout")
	check(res["hegemony"]["lit_before"] and res["hegemony"]["dark_after"] and int(res["hegemony"]["power_mats"]) >= 2, "hegemony: every light on through the tell, all %d surfaces off on one frame (%s, %s)" % [int(res["hegemony"]["power_mats"]), res["hegemony"]["lit_before"], res["hegemony"]["dark_after"]])
	check(_has(res["corsair"]["beats"], "tether") and _has(res["corsair"]["beats"], "tether_snap"), "corsair: the tether holds, then snaps")
	check(_count(res["corsair"]["beats"], "cookoff") == 2, "corsair: two late cook-offs (%d)" % _count(res["corsair"]["beats"], "cookoff"))
	check(res["hegemony"]["strain_runs"], "hegemony: the plating strain keeps its clock through the blackout tell (Neon on PR 1666)")
	check(_has(res["ithar"]["beats"], "web") and _has(res["ithar"]["beats"], "shafts"), "ithar: fracture web in the tell and light shafts at the split")
	check(res["ithar"]["overlay_on"] and res["ithar"]["overlay_off"], "ithar: tear overlays attach to both hull meshes, then detach at the split")
	# Codex on PR 1666: the ribbons themselves, not only the markers: the white web lines before the split, the prism
	# shafts just after it
	check(int(res["ithar"]["web_ribs"]) >= 5, "ithar: %d white fracture lines drawn before the split" % int(res["ithar"]["web_ribs"]))
	check(int(res["ithar"]["shaft_ribs"]) >= 4, "ithar: %d prism shafts drawn at the split" % int(res["ithar"]["shaft_ribs"]))
	check(int(res["voidsworn"]["web_ribs"]) == 0 and int(res["voidsworn"]["shaft_ribs"]) == 0, "voidsworn: no Glasswright web or shafts")
	check(_has(res["deathless"]["beats"], "implode"), "deathless: the core snaps inward")
	check(_count(res["chorus"]["beats"], "twitch") >= 1 and _count(res["chorus"]["beats"], "twitch_step") >= 16, "chorus: two or three eased twitches really turn the pieces (%d steps)" % _count(res["chorus"]["beats"], "twitch_step"))
	check(int(res["ithar"]["smoke"]) == 0, "ithar: no smoke or vapour from the beats (clean collapse; %d)" % int(res["ithar"]["smoke"]))
	for fac in res:
		check(bool(res[fac]["dimmed"]) == (fac == "deathless"), "%s: scene dim only for Eclipse (%s)" % [fac, res[fac]["dimmed"]])
		if fac != "chorus":
			var planned := 0
			for b in res[fac]["beats"]:
				if String(b).begins_with("after_"): planned = int(String(b).substr(6))
			var fired := _count(res[fac]["beats"], "after") - 1
			check(planned >= 2 and planned <= 3 and fired == planned, "%s: %d quiet afterlife pops within 10 s of the break (%d fired)" % [fac, planned, fired])
	# 2. kill causes
	var fl := await _kill("voidsworn", "Cruiser", 1.0, "flay", 4.0, true)
	check(_has(fl["beats"], "flay") and _count(fl["beats"], "flay_jets_") == 1 and fl["jets"] >= 3, "flay: %d gas jets along the shot" % fl["jets"])
	check(_has(fl["beats"], "shreds_5"), "flay: extra shreds at the break")
	var rm := await _kill("hegemony", "Cruiser", 1.0, "ram", 4.0, true)
	check(_has(rm["beats"], "ram") and absf(float(rm["spin"])) == 1.0, "ram: crush sparks and an off-centre spin (%s)" % str(rm["spin"]))
	var td := await _kill("corsair", "Cruiser", 1.0, "tidal", 3.0, false, Vector3(200, 0, 0))
	check(_has(td["beats"], "tidal"), "tidal: the sunward flare with a star on the board")
	var dk := await _kill("voidsworn", "Cruiser", 1.0, "dark", 8.0)
	check(_has(dk["beats"], "burnout") and _has(dk["beats"], "corridors") and _count(dk["beats"], "beacon") >= 4, "dark: corridor lights stutter out and the beacon blinks (%d)" % _count(dk["beats"], "beacon"))
	check(dk["hulk"], "dark: a cold hulk")
	var bd := await _kill("hegemony", "Cruiser", 1.0, "board", 4.0)
	check(bd["hulk"] and _has(bd["beats"], "board") and _count(bd["beats"], "airlock") >= 2, "board: a dark hulk venting through its airlocks (%d)" % _count(bd["beats"], "airlock"))
	check(not _has(bd["beats"], "blackout"), "board: no breaking blast beats")
	# Chorus (Codex on PR 1666): a ram or the star's pull adds its cue to the rupture; a scuttle leaves a dead hulk
	var cr := await _kill("chorus", "Cruiser", 1.0, "ram", 4.0, true)
	check(_has(cr["beats"], "ram"), "chorus ram: the crush cue on the rupture (%s)" % str(cr["beats"]))
	var ct := await _kill("chorus", "Cruiser", 1.0, "tidal", 3.0, false, Vector3(200, 0, 0))
	check(_has(ct["beats"], "tidal"), "chorus tidal: the sunward flare on the rupture (%s)" % str(ct["beats"]))
	var cb := await _kill("chorus", "Cruiser", 1.0, "board", 4.0)
	check(cb["hulk"] and _has(cb["beats"], "board"), "chorus board: a dead hulk venting, no rupture (%s)" % str(cb["beats"]))
	# the rammer's own recoil death puts the crush at its prow
	var rp := await _kill("hegemony", "Cruiser", 1.0, "ram", 2.0, true, Vector3.INF, "k", false, false, -1, true)
	check(_has(rp["beats"], "ram_prow"), "ram recoil: the rammer's crush is at its prow (%s)" % str(rp["beats"]))
	# Glasswright flay: no vapour from the jets
	var gf := await _kill("ithar", "Cruiser", 1.0, "flay", 4.0, true)
	check(_has(gf["beats"], "flay") and int(gf["smoke"]) == 0, "ithar flay: glass glints, no vapour (%d smoke)" % int(gf["smoke"]))
	# acid melt (R398, Neon on PR 1666): no faction beat, archetype, smoke or vapour on top of the melt
	for fac in ["corsair", "voidsworn", "hegemony", "ithar"]:
		var ml := await _kill(fac, "Cruiser", 1.0, "melt", 12.0)
		check(ml["beats"] == ["melt"], "melt %s: only the melt's own look (%s)" % [fac, str(ml["beats"])])
		check(int(ml["smoke"]) == 0, "melt %s: no smoke or vapour sprites from the beats (%d)" % [fac, int(ml["smoke"])])
		check(ml["overlay_on"] and ml["overlay_off"], "melt %s: acid overlays attach to both hull meshes, then detach at the split" % fac)
	var ms := await _kill("corsair", "Destroyer", 0.6, "melt", 2.0, false, Vector3.INF, "m1")
	check(ms["beats"] == ["melt"], "melt small: no archetype (%s)" % str(ms["beats"]))
	# Reduced Flashing: a burnout's corridor lights hold and fade once, no stutter
	var dr := await _kill("voidsworn", "Cruiser", 1.0, "dark", 3.0, false, Vector3.INF, "k", false, true)
	check(_has(dr["beats"], "corridors") and int(dr["corridor_sprites"]) <= 6 + _count(dr["beats"], "beacon"), "dark, Reduced Flashing: one steady light per corridor point (%d glows, %d beacon pulses)" % [int(dr["corridor_sprites"]), _count(dr["beats"], "beacon")])
	# the roll dies without the big fireball: its own spark end, no smoke body
	var rl := await _kill("corsair", "Destroyer", 0.6, "blast", 2.0, false, Vector3.INF, "r1", false, false, 2)
	check(_has(rl["beats"], "arch_roll") and _has(rl["beats"], "roll_end"), "roll: the small spark end (%s)" % str(rl["beats"]))
	check(int(rl["smoke"]) <= 5, "roll: no smoke body or fireball (%d smoke sprites, the five flank vents only)" % int(rl["smoke"]))
	# the torch keeps its exhaust trail through the flare
	var tc := await _kill("hegemony", "Destroyer", 0.6, "blast", 0.5, false, Vector3.INF, "t1", false, false, 0)
	check(_has(tc["beats"], "arch_torch") and int(tc["trail_pts"]) >= 3, "torch: the drive trail keeps drawing through the flare (%d new points after the kill)" % int(tc["trail_pts"]))
	# 3. small hulls
	var seen := {}
	var fx0 = FX.new()
	root.add_child(fx0)
	fx0.manual = true
	fx0.setup({"quality": "high", "shake": 0.0})
	for i in 40:
		var a := BEATS.pick_arch(fx0, _Probe.new("frig_%d" % i))
		seen[a] = int(seen.get(a, 0)) + 1
		if i < 3:
			check(a == BEATS.pick_arch(fx0, _Probe.new("frig_%d" % i)), "frig_%d: the same archetype every time" % i)
	check(seen.size() == 4, "small hulls: all four archetypes in use over 40 ships (%s)" % str(seen))
	fx0.queue_free()
	var arch_seen := {}
	for i in 8:
		var sm := await _kill(["voidsworn", "hegemony", "corsair", "ithar", "deathless"][i % 5], "Destroyer", 0.6, "blast", 2.0, false, Vector3.INF, "d%d" % i)
		for b in sm["beats"]:
			if String(b).begins_with("arch_"): arch_seen[b] = true
		check(_count(sm["beats"], "arch_") == 1, "small %s: one archetype (%s)" % [sm["fac"], str(sm["beats"])])
	check(arch_seen.size() >= 2, "small hulls die more than one way (%s)" % str(arch_seen.keys()))
	# 4. strike craft
	var wg := await _kill("hegemony", "Squadron", 0.3, "blast", 1.0, true, Vector3.INF, "wing", true)
	check(_has(wg["beats"], "corkscrew") and wg.smoke > 0 and wg.puff, "strike craft: a blast leaves a corkscrew and a puff")
	var acid := await _kill("hegemony", "Squadron", 0.3, "melt", 1.0, true, Vector3.INF, "wing", true)
	check(acid.melting and acid.smoke == 0 and not acid.puff, "acid-killed metal wing: melt, %d smoke sprites, delayed puff %s" % [acid.smoke, acid.puff])
	for fac in ["ithar", "chorus"]:
		var wing := await _kill(fac, "Squadron", 0.3, "blast", 1.0, true, Vector3.INF, "wing", true)
		if fac == "ithar":
			check(wing.shard_tints == [2.0, 2.0], "Glasswright wing sheds two glass shards")
		else:
			check(wing.shard_tints.is_empty() and wing.bile_flecks == 2, "Chorus wing sheds two wet flecks in its damage colour")
	# 6. the battle's view cause: _play_batch reads the marks with view_causes over the whole batch, so these batches are
	# exactly what playback sees, the grouped volley path included (Artoo on PR 1666, recheck of 852fbd8a)
	var B = load("res://scenes/battle/battle.gd")
	var vc: Dictionary = B.view_causes([{"t": "activation", "unit": "a", "side": "player"}, {"t": "ram", "unit": "a", "target": "b"},
		{"t": "float", "unit": "b"}, {"t": "death", "unit": "b", "cause": "big"}])
	check(vc.get("b", "") == "ram", "battle: a ram kill plays the ram death (%s)" % str(vc))
	# a ram both ships survive, then a volley (fire with its grouped hits, played through _play_fire) kills the rammer
	vc = B.view_causes([{"t": "ram", "unit": "c", "target": "d"}, {"t": "fire", "unit": "e", "target": "c", "weapon": 0},
		{"t": "hit", "unit": "e", "target": "c"}, {"t": "death", "unit": "c", "cause": "big", "by": "e"}])
	check(not vc.has("c") and not vc.has("d"), "battle: a volley kill of a ram survivor keeps its own death (%s)" % str(vc))
	# the same, in the next batch: marks never carry over
	vc = B.view_causes([{"t": "death", "unit": "c", "cause": "big"}])
	check(vc.is_empty(), "battle: a later batch starts with no marks")
	# Codex on PR 1666: the kill itself can set off another ship's action before its death event (Rolling Fire, a Brood
	# Tithe wing); those keep the mark, a kill by a ram ship's own next shot does not
	vc = B.view_causes([{"t": "ram", "unit": "a", "target": "b"}, {"t": "fire", "unit": "x", "target": "y", "weapon": 0},
		{"t": "hit", "unit": "x", "target": "y"}, {"t": "death", "unit": "b", "cause": "big", "by": "a"},
		{"t": "death", "unit": "a", "cause": "big", "by": "b"}])
	check(vc.get("b", "") == "ram" and vc.get("a", "") == "ram_prow", "battle: a Rolling Fire shot set off by a ram kill keeps both ram deaths (%s)" % str(vc))
	vc = B.view_causes([{"t": "board", "unit": "f", "target": "g", "result": "scuttle"}, {"t": "wing", "unit": "w1", "parent": "c"},
		{"t": "wreck", "unit": "g"}, {"t": "death", "unit": "g", "cause": "dark", "by": "f"}])
	check(vc.get("g", "") == "board", "battle: a Brood Tithe wing set off by a scuttle keeps the boarding death (%s)" % str(vc))
	vc = B.view_causes([{"t": "ram", "unit": "c", "target": "d"}, {"t": "fire", "unit": "d", "target": "c", "weapon": 0},
		{"t": "death", "unit": "c", "cause": "big", "by": "d"}])
	check(vc.is_empty(), "battle: a rammed ship's own later shot that kills the rammer is a weapon death (%s)" % str(vc))
	vc = B.view_causes([{"t": "ram", "unit": "c", "target": "d"}, {"t": "activation", "unit": "e", "side": "enemy"},
		{"t": "death", "unit": "c", "cause": "big", "by": "c"}])
	check(vc.is_empty(), "battle: a new activation ends the ram marks (%s)" % str(vc))
	vc = B.view_causes([{"t": "board", "unit": "f", "target": "g", "result": "scuttle"}, {"t": "death", "unit": "g", "cause": "dark"},
		{"t": "board", "unit": "f", "target": "h", "result": "raid"}, {"t": "death", "unit": "h", "cause": "dark"}])
	check(vc.get("g", "") == "board" and not vc.has("h"), "battle: a scuttle plays the boarding death, a raid marks nothing (%s)" % str(vc))
	var bt = B.new()
	bt._view_cause = {"b": "ram", "g": "board", "a": "ram_prow"}
	check(bt.view_cause("big", "a") == "ram", "battle: the rammer's mark plays the ram look too")
	check(bt.view_cause("big", "b") == "ram", "battle: view_cause plays the ram look")
	check(bt.view_cause("big", "b") == "big", "battle: the ram mark is used once")
	check(bt.view_cause("flay", "g") == "flay", "battle: a boarding mark only turns a dark kill into the boarding death")
	check(bt.view_cause("flay", "x") == "flay", "battle: any other kill keeps the rules' cause")
	bt.free()
	await _debris_check()
	print("DEATH_VARIETY failures=%d" % failures)
	quit(1 if failures else 0)


func _debris_check() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "camera": cam, "shake": 0.0})
	fx.spr_kinds = {}
	var brass := Color(1.0, 0.82, 0.55)
	var want := {"voidsworn": [1, 0.0], "hegemony": [1, 0.0], "corsair": [1, 0.0], "ithar": [1, 2.0], "deathless": [1, 0.0], "chorus": [0, -1.0]}
	for fac in want:
		var holder := Node3D.new()
		world.add_child(holder)
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(20, 4, 6)
		mi.mesh = box
		holder.add_child(mi)
		fx.add_ship("db_" + fac, holder, {"faction": fac, "cls": "Cruiser", "size": 1.0})
		var s = fx.ship("db_" + fac)
		if fac == "voidsworn":
			var r1 := RandomNumberGenerator.new(); r1.seed = 7
			var r2 := RandomNumberGenerator.new(); r2.seed = 7
			var nb: int = DEATH.seeds_for(s, "big", r1).size()
			var nr: int = DEATH.seeds_for(s, "ram", r2).size()
			check(nr == nb, "ram: cut into as many pieces as a big kill (%d, big %d)" % [nr, nb])
		var pool = fx.pools["shd"]
		var n0: int = int(pool.emitted)
		var k0: int = int((fx.spr_kinds as Dictionary).get(20, 0))
		var launch_heat := 0.6
		BEATS.debris(fx, s, Vector3.ZERO, fx.now, 1.0, Vector3.UP, 0.1, launch_heat)
		var pend: PackedFloat32Array = pool.pending   # one row repeated per vertex: the last 20 floats are the new shard
		var shards: int = int(pool.emitted) - n0
		var w: Array = want[fac]
		check(shards == int(w[0]), "%s: %d debris shard (want %d)" % [fac, shards, int(w[0])])
		if shards == 1:
			var tint: float = pend[pend.size() - 20 + 18]
			var heat: float = pend[pend.size() - 20]
			check(is_equal_approx(tint, float(w[1])), "%s: shard look %.1f (want %.1f)" % [fac, tint, float(w[1])])
			var want_heat := 0.0 if fac in ["deathless", "hegemony"] else launch_heat
			check(is_equal_approx(heat, want_heat), "%s: shard heat %.2f (want %.2f)" % [fac, heat, want_heat])
		else:
			check(int((fx.spr_kinds as Dictionary).get(20, 0)) > k0, "%s: a wet fleck in place of the shard" % fac)
		var sc: Color = BEATS.spark_col(s, brass)
		if fac == "hegemony":
			check(sc.is_equal_approx(s.fac.damage_glow) and not sc.is_equal_approx(brass), "hegemony: crush spark uses blue-white damage glow, not brass (%s)" % str(sc))
		else:
			var brass_sparks: bool = fac in ["voidsworn", "corsair"]
			check(sc.is_equal_approx(brass) == brass_sparks, "%s: crush spark colour %s (brass on Sunward and Hullbreakers only)" % [fac, str(sc)])
	world.queue_free()
	await process_frame


class _Probe:
	var id: String
	func _init(i: String) -> void:
		id = i


func _kill(fac: String, cls: String, size: float, cause: String, secs: float, shot := false, well := Vector3.INF, sid := "k", wing := false, calm := false, arch := -1, prow := false) -> Dictionary:
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.position = Vector3(0, 30, 40)
	var holder := Node3D.new()
	world.add_child(holder)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(20, 4, 6) * (1.0 if size >= 0.9 else 0.4)
	box.subdivide_width = 19
	box.subdivide_height = 3
	box.subdivide_depth = 5
	mi.mesh = box
	mi.set_surface_override_material(0, StandardMaterial3D.new())
	holder.add_child(mi)
	var mi2 := MeshInstance3D.new()   # a second surface, so the blackout check sees two go dark together
	mi2.mesh = box
	mi2.position = Vector3(0, box.size.y * 0.9, 0)
	mi2.scale = Vector3(0.5, 0.5, 0.5)
	mi2.set_surface_override_material(0, StandardMaterial3D.new())
	holder.add_child(mi2)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "camera": cam, "shake": 0.0, "reduce_flashing": calm})
	fx.dstate["physics_on"] = true
	fx.spr_kinds = {}
	fx.rib_log = []
	fx.well = well
	fx.add_ship(sid, holder, {"faction": fac, "cls": cls, "size": size, "squadron": wing})
	var s = fx.ship(sid)
	if arch >= 0: s.set_meta("death_arch_force", arch)
	if prow: s.set_meta("death_ram_prow", true)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 60000 and not wing:
		fx.step(1.0 / 60.0)
		await process_frame
		if (s.get_meta("cut_job", {}) as Dictionary).get("built", false) or not s.death_big: break
	if shot:
		s.set_meta("last_hit", [s.hull.c + Vector3(0, 0, s.hull.W * 0.5), Vector3(0, 0, -1), fx.now])
	var rib0: int = fx.pools["rib"].emitted
	var spr0 := _kinds(fx)
	var shard_start: int = fx.pools["shd"].pending.size()
	var smoke_start: int = fx.pools["smk"].pending.size()
	fx.death(sid, cause)
	var T: float = fx.now
	var res := {"fac": fac, "dimmed": false, "lit_before": true, "dark_after": false, "strain_runs": false, "power_mats": 0, "smoke": 0, "corridor_sprites": 0, "trail_pts": 0}
	res["overlay_on"] = mi.material_overlay != null and mi2.material_overlay != null
	if wing:
		res["melting"] = DEATH.melting(s)
		res["puff"] = false
		res["shard_tints"] = []
		# Read one packed vertex per new particle. Shards carry the tint at 18, sprites carry the kind there and RGB at 12.
		var shards: PackedFloat32Array = fx.pools["shd"].pending
		for row in range(shard_start, shards.size(), fx.pools["shd"].vpp * POOLS.STRIDE):
			res.shard_tints.append(shards[row + 18])
		var smoke: PackedFloat32Array = fx.pools["smk"].pending
		var bile: Color = s.fac.damage_glow * 0.6
		res["bile_flecks"] = 0
		for row in range(smoke_start, smoke.size(), fx.pools["smk"].vpp * POOLS.STRIDE):
			if smoke[row + 18] == 20 and Vector3(smoke[row + 12], smoke[row + 13], smoke[row + 14]).is_equal_approx(Vector3(bile.r, bile.g, bile.b)):
				res.bile_flecks += 1
	var split_t := T + (float(s.get_meta("death_timeline").cut) if s.has_meta("death_timeline") else 0.72)
	for i in int(secs * 60.0):
		fx.step(1.0 / 60.0)
		await process_frame
		if wing and not res.puff:
			for pic in world.find_children("fx_beat_impact*", "MeshInstance3D", true, false):
				if pic.visible and pic.get_meta("fx_picture_kind", "") == "impact":
					res.puff = true
		if fx.get("_dim_t0") != null and float(fx.get("_dim_t0")) >= 0.0: res["dimmed"] = true
		if s.has_meta("death_blackout_at"):
			var at: float = s.get_meta("death_blackout_at")
			var mats_now: Array = s.get_meta("death_power", [])
			res["power_mats"] = maxi(int(res["power_mats"]), mats_now.size())
			var all_dark := mats_now.size() > 0
			for m in mats_now:
				var pv = (m as ShaderMaterial).get_shader_parameter("fx_power")
				if pv == null or float(pv) != 0.0: all_dark = false
			if fx.now > at + 0.02 and all_dark: res["dark_after"] = true
			for m in mats_now:
				var pw = (m as ShaderMaterial).get_shader_parameter("fx_power")
				var v := float(pw) if pw != null else 1.0
				if fx.now < at - 0.02 and v < 1.0: res["lit_before"] = false
				var da = (m as ShaderMaterial).get_shader_parameter("death_age")
				if fx.now < at - 0.1 and da != null and float(da) > 0.3: res["strain_runs"] = true
		if s.has_method("_update_trails") and "_trails" in s:
			for tr in s._trails:
				var fresh := 0
				for hp in tr["hist"]:
					if float(hp[1]) > T + float(s._trail_extra) + 0.01: fresh += 1
				res["trail_pts"] = maxi(int(res["trail_pts"]), fresh)
	res["beats"] = BEATS.beats(s)
	res["overlay_off"] = mi.material_overlay == null and mi2.material_overlay == null
	var web_c := Color(0.95, 0.97, 1.0)
	var shaft_c := [Color(1.0, 0.75, 0.8), Color(0.75, 1.0, 0.85), Color(0.75, 0.82, 1.0), Color(1.0, 0.95, 0.75)]
	res["web_ribs"] = 0
	res["shaft_ribs"] = 0
	for r in fx.rib_log:
		var rt: float = float(r[0])
		if (r[1] as Color).is_equal_approx(web_c) and rt < split_t: res["web_ribs"] += 1
		if shaft_c.any(func(c): return (r[1] as Color).is_equal_approx(c)) and rt >= split_t - 0.05: res["shaft_ribs"] += 1
	var spr1 := _kinds(fx)
	res["smoke"] = int(spr1.get(3, 0)) - int(spr0.get(3, 0)) + int(spr1.get(7, 0)) - int(spr0.get(7, 0))
	res["corridor_sprites"] = int(spr1.get(18, 0)) - int(spr0.get(18, 0))
	res["spin"] = s.get_meta("death_spin", 0.0)
	res["hulk"] = bool(s.get_meta("death_hulk", false))
	var jets := 0
	for b in res["beats"]:
		if String(b).begins_with("flay_jets_"): jets = int(String(b).substr(10))
	res["jets"] = jets
	res["ribs"] = fx.pools["rib"].emitted - rib0
	print("DEATH_VARIETY ", fac, " ", cause, " ", JSON.stringify(res["beats"]))
	world.queue_free()
	await process_frame
	return res


# Sprites emitted so far, by kind (fx.spr_kinds, on for this check).
func _kinds(fx) -> Dictionary:
	return (fx.spr_kinds as Dictionary).duplicate()
