extends SceneTree
# Issue 1582 (battle movement stage 2, a look only): class altitude bands with drop-lines, a lifted hull picks its own
# hex, effects follow the drawn hull, strike craft dive onto their target and climb out, torpedoes fly straight between
# heights (Ryan, Nov 22: kept flat, issue 1713), and six distinct faction thrust personalities.
const GUARD := preload("res://tools/ci/check_guard.gd")
const SV := preload("res://render/ship_view.gd")
const HT := preload("res://render/hull_table.gd")
const ALT := preload("res://render/altitude_band.gd")
const TP := preload("res://fx/thrust_profile.gd")
const FX := preload("res://fx/fx.gd")
const FXW := preload("res://fx/fx_weapons.gd")
const BATTLE := preload("res://scenes/battle/battle.gd")
var fails := 0
var checks := 0


func _init() -> void:
	GUARD.arm(self, "movement_stage2_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		fails += 1
		push_error("STAGE2 FAIL: " + message)


func fixture() -> String:
	var n := Node3D.new()
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(9.5, 2.0, 3.0)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	mi.mesh = mesh
	n.add_child(mi)
	mi.owner = n
	var hp := Node3D.new()
	hp.name = "hp_core"
	n.add_child(hp)
	hp.owner = n
	var packed := PackedScene.new()
	packed.pack(n)
	var path := "user://stage2_fixture.tscn"
	ResourceSaver.save(packed, path)
	n.free()
	return path


func _bands() -> void:
	for cls in ["Dreadnought", "Battleship", "Super-dreadnought", "Battle-barge", "Bio-titan", "Ark", "Tomb-ark"]:
		check(ALT.height({"id": "x" + cls, "cls": cls}) == 0.0, cls + " holds the battle plane")
	var up := 0
	var down := 0
	var seen := {}
	for i in 40:
		for cls in ["Cruiser", "Destroyer", "Frigate"]:
			var id := "u%d" % i
			var y := ALT.height({"id": id, "cls": cls})
			check(y == ALT.height({"id": id, "cls": cls}), "a ship keeps the same height every time (%s)" % id)
			var band: Array = ALT.ESCORT if cls == "Frigate" else ALT.LINE
			var mag := absf(y) if y > 0.0 else absf(y) / ALT.BELOW_K
			check(mag >= float(band[0]) - 1e-4 and mag <= float(band[1]) + 1e-4, "%s %s sits inside its band (%.2f)" % [cls, id, y])
			up += 1 if y > 0.0 else 0
			down += 1 if y < 0.0 else 0
			seen[snappedf(y, 0.1)] = true
	check(up > 20 and down > 20, "escorts and line ships sit both above and below the plane (%d up, %d down)" % [up, down])
	check(seen.size() > 30, "neighbouring ships get distinct heights (%d heights)" % seen.size())
	check(ALT.height({"id": "w", "cls": "Squadron", "squadron": true}) == ALT.WING, "strike craft patrol above the ships")
	check(ALT.WING > float(ALT.ESCORT[1]) + 3.0, "wings sit clearly above the highest escort")


func _view(world: Node3D, cls: String, band: float, origin: Vector3) -> Node3D:
	var sv := SV.new()
	world.add_child(sv)
	sv.setup({"id": "s_" + cls, "fac": "hegemony", "cls": cls, "code": "H9_23", "facing": 1}, origin)
	sv.set_marker(true)
	sv.set_band(band)
	return sv


func _drop(world: Node3D) -> void:
	var origin := Vector3(30, 0, 12)
	var sv := _view(world, "Cruiser", 3.0, origin)
	check(sv.position == origin, "the rules root stays on its hex")
	check(is_equal_approx(sv.marker.position.y, -0.25) and is_equal_approx(sv.ring.position.y, -0.3), "ring and footprint stay on the plane")
	check(is_equal_approx(sv.visual_position().y, 3.0), "the visual centre carries the band")
	var mi: MeshInstance3D = sv.meshes[0]
	var bb: AABB = (sv.global_transform.affine_inverse() * mi.global_transform) * mi.get_aabb()
	check(absf(bb.get_center().y - 3.0) < 0.3, "the drawn hull sits at its band (%.2f)" % bb.get_center().y)
	check(sv.drop != null and sv.drop.visible, "an off-plane hull draws its drop-line")
	var top: float = sv.drop.position.y + sv.drop.transform.basis.y.length() * 0.5
	var bottom: float = sv.drop.position.y - sv.drop.transform.basis.y.length() * 0.5
	check(absf(top - sv.hull.position.y) < 0.05 and absf(bottom - 0.05) < 0.05, "the line runs from the plane to the hull's centre (%.2f to %.2f)" % [bottom, top])
	check(absf(sv.drop_dot.position.y - 0.05) < 1e-3, "its anchor dot sits on the plane under the rules root")
	var rest_a: float = (sv.drop.material_override as StandardMaterial3D).albedo_color.a
	sv.set_hot(true)
	sv._drop_step(1.0)
	var hot_a: float = (sv.drop.material_override as StandardMaterial3D).albedo_color.a
	check(hot_a > rest_a * 2.0, "hover brightens the line (%.2f to %.2f)" % [rest_a, hot_a])
	sv.set_hot(false)
	sv.set_selected(true)
	sv._drop_step(1.0)
	check((sv.drop.material_override as StandardMaterial3D).albedo_color.a > rest_a * 2.0, "selection brightens the line")
	sv.set_selected(false)
	# the line stretches with the hull during a pass-over or a boarding trim
	sv.hull.position.y += 4.0
	sv._drop_step(0.016)
	check(absf(sv.drop.transform.basis.y.length() - (sv.hull.position.y - 0.05)) < 0.05, "the line stretches with the hull")
	sv.hull.position.y -= 4.0
	var low := _view(world, "Destroyer", -2.4, Vector3(-30, 0, 0))
	low._drop_step(0.0)
	check(low.drop.visible and low.drop.position.y < 0.0, "a hull below the plane draws its line up to the plane")
	var cap := _view(world, "Dreadnought", 0.0, Vector3(0, 0, -40))
	check(cap.drop == null, "a capital on the plane draws no line")
	# effects read the drawn hull, so guns and hits pitch between heights
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "shake": 0.0})
	fx.add_ship("hi", sv, {"faction": "hegemony", "cls": "Cruiser", "meshes": sv.meshes})
	fx.add_ship("lo", low, {"faction": "hegemony", "cls": "Destroyer", "meshes": low.meshes})
	var a = fx.ship("hi")
	var b = fx.ship("lo")
	check(absf(a.to_world(a.hull.c).y - 3.0) < 0.4, "the effects' hull centre follows the band up (%.2f)" % a.to_world(a.hull.c).y)
	check(absf(b.to_world(b.hull.c).y + 2.4) < 0.4, "and down (%.2f)" % b.to_world(b.hull.c).y)
	# the hull-first pick: the pointer on a lifted hull picks its own hex, not the hex its image covers
	var battle := BATTLE.new()
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.global_position = Vector3(30, 120, 140)
	cam.look_at(Vector3(30, 0, 12))
	battle.cam = cam
	battle.views = {"hi": sv, "cap": cap}
	battle.VU = {"hi": {"id": "hi", "q": 3, "r": 4, "squadron": false}, "cap": {"id": "cap", "q": 0, "r": 0, "squadron": false}}
	var p: Vector2 = cam.unproject_position(sv.visual_position())
	check(battle._lifted_hull_hex(p) == Vector2i(3, 4), "the pointer on a lifted hull picks its hex")
	check(battle._lifted_hull_hex(p + Vector2(400, 0)).x == 99999, "a pointer away from it picks nothing special")
	var cp: Vector2 = cam.unproject_position(cap.visual_position())
	check(battle._lifted_hull_hex(cp).x == 99999, "a hull on the plane is left to the plane pick")
	battle.free()
	fx.remove_ship("hi")
	fx.remove_ship("lo")
	fx.queue_free()


func _dive(world: Node3D) -> void:
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "shake": 0.0})
	var from := Vector3(0, ALT.WING, 0)
	var to := Vector3(60, -2.0, 8)
	fx.dstate["craft_runs"] = []
	FXW._strafe(fx, "fighter", from, to, fx.now, Color.WHITE, {"engine": Color.ORANGE}, 1.0, 1.0, 1, "hegemony")
	var runs: Array = fx.dstate.get("craft_runs", [])
	check(runs.size() == 3, "an attack pass flies three craft")
	if runs.is_empty():
		return
	var r: Dictionary = runs[0]
	var dive: Dictionary = r["dive"]
	check(not dive.is_empty(), "the pass carries its dive")
	var lowest := INF
	var lowest_u := 0.0
	var prev_y := INF
	var down_ok := true
	for k in 81:
		var u := float(k) / 80.0
		var q: Vector3 = FXW._dive_pos(r["a"], r["b"], dive, u)
		if q.y < lowest:
			lowest = q.y
			lowest_u = u
		if u <= float(dive["pi"]) and q.y > prev_y + 1e-4:
			down_ok = false
		prev_y = q.y
	var start_y: float = FXW._dive_pos(r["a"], r["b"], dive, 0.0).y
	var end_y: float = FXW._dive_pos(r["a"], r["b"], dive, 1.0).y
	check(start_y >= ALT.WING - 1.0, "the pass starts at patrol height (%.1f)" % start_y)
	check(down_ok, "it only descends until the low pass")
	check(lowest < to.y + 4.0, "it dives down to the target's height (low %.1f, target %.1f)" % [lowest, to.y])
	check(end_y > lowest + 8.0 and end_y >= ALT.WING - 1.0, "then climbs back out to patrol height (%.1f)" % end_y)
	var fall := start_y - lowest
	var ground: float = Vector2(r["b"].x - r["a"].x, r["b"].z - r["a"].z).length() * lowest_u
	check(fall / maxf(ground, 1.0) > 0.12 and _steepest(r) > 0.6, "the dive is steep enough to read (drop %.1f over %.1f, steepest %.2f)" % [fall, ground, _steepest(r)])
	# the craft node pitches nose down in the dive and up in the climb
	fx.dstate["craft_runs"] = [r]
	r["t0"] = fx.now
	var node: Node3D = r["node"]
	var pitches: Array = []
	var pi_u := float(dive["pi"])
	for u in [(float(dive["pd"]) + pi_u) * 0.5, (pi_u + float(dive["pc"])) * 0.5]:
		fx.now = float(r["t0"]) + float(r["life"]) * u
		FXW._craft_update(fx, 0.0)
		pitches.append(node.basis.x.normalized().y)
	check(float(pitches[0]) < -0.05 and float(pitches[1]) > 0.05, "the craft pitch down into the dive and up out of it (%.2f, %.2f)" % pitches)
	for rr in runs:
		if is_instance_valid(rr["node"]):
			(rr["node"] as Node).queue_free()
	fx.dstate["craft_runs"] = []
	# a level pass (wing and target at the same height) keeps a shallow run
	FXW._strafe(fx, "fighter", Vector3(0, 0, 0), Vector3(60, 0, 0), fx.now, Color.WHITE, {"engine": Color.ORANGE}, 1.0, 1.0, 1, "hegemony")
	var lr: Dictionary = fx.dstate["craft_runs"][0]
	var drop_lvl: float = FXW._dive_pos(lr["a"], lr["b"], lr["dive"], 0.0).y - FXW._dive_pos(lr["a"], lr["b"], lr["dive"], float(lr["dive"]["pi"])).y
	check(drop_lvl < 3.0, "a level pass stays shallow (%.1f)" % drop_lvl)
	for rr in fx.dstate["craft_runs"]:
		(rr["node"] as Node).queue_free()
	fx.dstate["craft_runs"] = []
	# torpedoes fly straight between heights: never above the higher end (issue 1713 holds between bands)
	var fac := {"engine": Color(1.0, 0.6, 0.3)}
	for ends in [[Vector3(0, 4.5, 0), Vector3(70, -2.4, 10)], [Vector3(0, -2.4, 0), Vector3(70, 4.5, -10)]]:
		fx.dstate["proj"] = []
		FXW._launch(fx, "torp", ends[0], Vector3.UP, ends[1], 1.0, 3.0, Color.WHITE, fac, 1.0, 0, false, null, null, 1.0, "hegemony")
		for pr in fx.dstate["proj"]:
			var top := maxf((pr["a"] as Vector3).y, (pr["c"] as Vector3).y) + 0.05
			var peak := -INF
			for s in 41:
				peak = maxf(peak, FXW._bez(pr["a"], pr["b"], pr["c"], float(s) / 40.0).y)
			check(peak <= top, "a torpedo between bands stays flat (peak %.2f, limit %.2f)" % [peak, top])
			check(absf((pr["c"] as Vector3).y - (ends[1] as Vector3).y) < 0.01, "and lands at its target's height")
			if is_instance_valid(pr["mesh"]):
				(pr["mesh"] as Node).queue_free()
	fx.dstate["proj"] = []
	fx.queue_free()


# the steepest downward slope of the dive (drop per ground unit)
func _steepest(r: Dictionary) -> float:
	var best := 0.0
	var prev: Vector3 = FXW._dive_pos(r["a"], r["b"], r["dive"], 0.0)
	for k in range(1, 201):
		var q: Vector3 = FXW._dive_pos(r["a"], r["b"], r["dive"], float(k) / 200.0)
		var g := Vector2(q.x - prev.x, q.z - prev.z).length()
		if g > 1e-4:
			best = maxf(best, (prev.y - q.y) / g)
		prev = q
	return best


func _personalities() -> void:
	var styles := {}
	var igns := {}
	for f in ["voidsworn", "hegemony", "corsair", "ithar", "chorus", "deathless"]:
		check(TP.TABLE.has(f), f + " has a thrust personality")
		var p := TP.of(f)
		styles[f] = p["style"]
		igns[f] = float(p["ign"])
	check(styles["chorus"] == "pulse" and styles["deathless"] == "ripple" and styles["ithar"] == "glint", "Chorus, Eclipse and the Glasswrights throw no gas")
	check(igns["voidsworn"] > igns["hegemony"] and igns["hegemony"] > igns["deathless"] and igns["corsair"] < igns["hegemony"], "Sunward spools slowest, Hullbreakers kick, Eclipse is all but instant")
	check(int(TP.of("corsair")["sparks"]) > 0 and int(TP.of("hegemony")["sparks"]) == 0, "only the Hullbreakers throw grit")
	var sig := {}
	for f in TP.TABLE:
		var p := TP.of(f)
		sig[str([p["style"], p["ign"], p["size"], p["life"], p["spread"], p["speed"]])] = true
	check(sig.size() == 6, "six distinct signatures")
	# the ignition beat follows the profile on a real flown move
	var world := Node3D.new()
	root.add_child(world)
	var beats := {}
	for f in ["voidsworn", "hegemony", "deathless"]:
		var sv := SV.new()
		world.add_child(sv)
		sv.setup({"id": "ign_" + f, "fac": f, "cls": "Cruiser", "code": "H9_23", "facing": 0}, Vector3.ZERO)
		sv.set_process(false)
		sv.play_glide([{"kind": "run", "p": Vector3(17.3, 0, 0)}, {"kind": "run", "p": Vector3(34.6, 0, 0)}], 0.5, {"mass": 0.6})
		beats[f] = float(sv.gl_ign_u)
	check(beats["voidsworn"] > beats["hegemony"] and beats["hegemony"] > beats["deathless"], "a flown move's ignition beat follows the faction (%s)" % str(beats))
	world.queue_free()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var man := {"ships": {"H9_23": {"res": fixture()}}}
	SV._manifest = man
	_bands()
	_drop(world)
	_dive(world)
	_personalities()
	await process_frame
	world.queue_free()
	await process_frame
	SV.clear_static()
	print("STAGE2 %s: %d checks, %d failures" % ["PASS" if fails == 0 else "FAIL", checks, fails])
	quit(1 if fails > 0 else 0)
