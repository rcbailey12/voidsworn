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
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const BEATS := preload("res://fx/fx_death_beats.gd")
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
	check(res["hegemony"]["lit_before"] and res["hegemony"]["dark_after"], "hegemony: every light on through the tell, all off on the split frame (%s, %s)" % [res["hegemony"]["lit_before"], res["hegemony"]["dark_after"]])
	check(_has(res["corsair"]["beats"], "tether") and _has(res["corsair"]["beats"], "tether_snap"), "corsair: the tether holds, then snaps")
	check(_count(res["corsair"]["beats"], "cookoff") == 2, "corsair: two late cook-offs (%d)" % _count(res["corsair"]["beats"], "cookoff"))
	check(_has(res["ithar"]["beats"], "web") and _has(res["ithar"]["beats"], "shafts"), "ithar: fracture web in the tell and light shafts at the split")
	check(_has(res["deathless"]["beats"], "implode"), "deathless: the core snaps inward")
	check(_count(res["chorus"]["beats"], "twitch") == 1, "chorus: post-break twitches")
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
	check(_has(wg["beats"], "corkscrew"), "strike craft: the smoky corkscrew")
	# 6. the battle's view cause: _play_batch reads the marks with view_causes over the whole batch, so these batches are
	# exactly what playback sees, the grouped volley path included (Artoo on PR 1666, recheck of 852fbd8a)
	var B = load("res://scenes/battle/battle.gd")
	var vc: Dictionary = B.view_causes([{"t": "activation", "unit": "a", "side": "player"}, {"t": "ram", "unit": "a", "target": "b"},
		{"t": "float", "unit": "b"}, {"t": "death", "unit": "b", "cause": "big"}])
	check(vc.get("b", "") == "ram", "battle: a ram kill plays the ram death (%s)" % str(vc))
	# a ram both ships survive, then a volley (fire with its grouped hits, played through _play_fire) kills the rammer
	vc = B.view_causes([{"t": "ram", "unit": "c", "target": "d"}, {"t": "fire", "unit": "e", "target": "c", "weapon": 0},
		{"t": "hit", "unit": "e", "target": "c"}, {"t": "death", "unit": "c", "cause": "big"}])
	check(not vc.has("c") and not vc.has("d"), "battle: a volley kill of a ram survivor keeps its own death (%s)" % str(vc))
	# the same, in the next batch: marks never carry over
	vc = B.view_causes([{"t": "death", "unit": "c", "cause": "big"}])
	check(vc.is_empty(), "battle: a later batch starts with no marks")
	vc = B.view_causes([{"t": "board", "unit": "f", "target": "g", "result": "scuttle"}, {"t": "death", "unit": "g", "cause": "dark"},
		{"t": "board", "unit": "f", "target": "h", "result": "raid"}, {"t": "death", "unit": "h", "cause": "dark"}])
	check(vc.get("g", "") == "board" and not vc.has("h"), "battle: a scuttle plays the boarding death, a raid marks nothing (%s)" % str(vc))
	var bt = B.new()
	bt._view_cause = {"b": "ram", "g": "board"}
	check(bt.view_cause("big", "b") == "ram", "battle: view_cause plays the ram look")
	check(bt.view_cause("big", "b") == "big", "battle: the ram mark is used once")
	check(bt.view_cause("flay", "g") == "flay", "battle: a boarding mark only turns a dark kill into the boarding death")
	check(bt.view_cause("flay", "x") == "flay", "battle: any other kill keeps the rules' cause")
	bt.free()
	print("DEATH_VARIETY failures=%d" % failures)
	quit(1 if failures else 0)


class _Probe:
	var id: String
	func _init(i: String) -> void:
		id = i


func _kill(fac: String, cls: String, size: float, cause: String, secs: float, shot := false, well := Vector3.INF, sid := "k", wing := false) -> Dictionary:
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
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "camera": cam, "shake": 0.0})
	fx.dstate["physics_on"] = true
	fx.well = well
	fx.add_ship(sid, holder, {"faction": fac, "cls": cls, "size": size, "squadron": wing})
	var s = fx.ship(sid)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 60000 and not wing:
		fx.step(1.0 / 60.0)
		await process_frame
		if (s.get_meta("cut_job", {}) as Dictionary).get("built", false) or not s.death_big: break
	if shot:
		s.set_meta("last_hit", [s.hull.c + Vector3(0, 0, s.hull.W * 0.5), Vector3(0, 0, -1), fx.now])
	var rib0: int = fx.pools["rib"].emitted
	fx.death(sid, cause)
	var T: float = fx.now
	var res := {"fac": fac, "dimmed": false, "lit_before": true, "dark_after": false}
	var split_t := T + (float(s.get_meta("death_timeline").cut) if s.has_meta("death_timeline") else 0.72)
	for i in int(secs * 60.0):
		fx.step(1.0 / 60.0)
		await process_frame
		if fx.get("_dim_t0") != null and float(fx.get("_dim_t0")) >= 0.0: res["dimmed"] = true
		if s.has_meta("death_blackout_at"):
			var at: float = s.get_meta("death_blackout_at")
			for m in s.get_meta("death_power", []):
				var pw = (m as ShaderMaterial).get_shader_parameter("fx_power")
				var v := float(pw) if pw != null else 1.0
				if fx.now < at - 0.02 and v < 1.0: res["lit_before"] = false
				if fx.now > at + 0.02 and v == 0.0: res["dark_after"] = true
	res["beats"] = BEATS.beats(s)
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
