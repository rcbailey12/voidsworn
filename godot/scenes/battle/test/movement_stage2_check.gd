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
	var rest_a: float = (sv.drop_dot.material_override as StandardMaterial3D).albedo_color.a
	sv.set_hot(true)
	sv._drop_step(1.0)
	var hot_a: float = (sv.drop_dot.material_override as StandardMaterial3D).albedo_color.a
	check(hot_a > rest_a * 2.0, "hover brightens the line (%.2f to %.2f)" % [rest_a, hot_a])
	sv.set_hot(false)
	sv.set_selected(true)
	sv._drop_step(1.0)
	check((sv.drop_dot.material_override as StandardMaterial3D).albedo_color.a > rest_a * 2.0, "selection brightens the line")
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
	# Artoo on PR 1874: a low orbit where a lower escort sits right behind a foreground capital on screen
	var oc := Vector3(0, 0, -200)
	cam.global_position = oc + Vector3(0, 14, 120)
	cam.look_at(oc)
	cap.position = oc
	var ray: Vector3 = (oc - cam.global_position).normalized()
	var t_lo := (cam.global_position.y + 2.4) / -ray.y   # where the view ray through the capital's middle is 2.4 below
	var behind := _view(world, "Frigate", -2.4, Vector3.ZERO)
	var bp: Vector3 = cam.global_position + ray * t_lo
	behind.position = Vector3(bp.x, 0, bp.z)
	var front := _view(world, "Frigate", 3.6, Vector3.ZERO)
	var t_hi := (cam.global_position.y - 3.6) / -ray.y   # in front of the capital, 3.6 up, on the same ray
	var fp: Vector3 = cam.global_position + ray * t_hi
	front.position = Vector3(fp.x, 0, fp.z)
	front.visible = false
	battle.views = {"cap": cap, "behind": behind, "front": front}
	battle.VU = {"cap": {"id": "cap", "q": 0, "r": 0, "squadron": false}, "behind": {"id": "behind", "q": 5, "r": 1, "squadron": false},
		"front": {"id": "front", "q": 2, "r": 2, "squadron": false}}
	var op: Vector2 = cam.unproject_position(oc)
	check(cam.unproject_position(behind.visual_position()).distance_to(op) < 2.0, "the escort projects onto the capital's middle")
	check(battle._lifted_hull_hex(op).x == 99999, "a lower escort behind a foreground capital does not steal its click")
	front.visible = true
	check(battle._lifted_hull_hex(op) == Vector2i(2, 2), "a raised escort in front of the capital takes the click")
	front.visible = false
	# the band is set in the shared registration every view path calls (opening roster, reinforcement, revive)
	var fresh := SV.new()
	world.add_child(fresh)
	fresh.setup({"id": "fresh", "fac": "hegemony", "cls": "Cruiser", "code": "H9_23", "facing": 0}, Vector3(60, 0, 0))
	battle._register_fx_ship({"id": "fresh", "fac": "hegemony", "cls": "Cruiser", "size": 2, "squadron": false, "flagship": false}, fresh)
	check(is_equal_approx(fresh.band_y, ALT.height({"id": "fresh", "cls": "Cruiser"})) and absf(fresh.band_y) > 0.5, "shared registration sets the band (%.2f)" % fresh.band_y)
	battle._register_fx_ship({"id": "fresh", "fac": "hegemony", "cls": "Cruiser", "size": 2, "squadron": false, "flagship": false}, fresh)
	check(is_equal_approx(fresh.hull.position.y - fresh.hull_lift, fresh.band_y) or absf(fresh.hull_base.y - fresh.band_y) < 0.01, "registering twice keeps the same height")
	battle.free()
	fx.remove_ship("hi")
	fx.remove_ship("lo")
	fx.queue_free()


func _guard_orbit(world: Node3D) -> void:
	var carrier := _view(world, "Carrier", 3.0, Vector3(45, 0, 10))
	var wing := SV.new()
	world.add_child(wing)
	var hex := Vector3(31, 0, 20)
	var u := {"id": "guard_fixture", "fac": "hegemony", "cls": "Squadron", "squadron": true}
	wing.setup(u, hex)
	wing.set_band(ALT.height(u))
	wing.guard_carrier = carrier
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low"})
	wing.fx_clock = fx
	var tick := func(real_dt: float) -> void:
		fx.step(real_dt)
		wing._process(real_dt)
	for i in 16:
		tick.call(0.05)
	var center := Vector3(carrier.position.x, ALT.WING, carrier.position.z)
	var first: Vector3 = wing.visual_position() - center
	var period := SV.GUARD_ORBIT_PERIOD
	var radius := float(carrier.L) * 0.55 + SV.GUARD_ORBIT_CLEARANCE
	check(period >= 12.0 and period <= 22.0, "the guard orbit takes a slow %.1f effect seconds" % period)
	check(absf(first.length() - radius) < 0.02 and absf(first.y) < 0.01 and radius > carrier.L * 0.5,
		"the guard wing clears its carrier at %.2f units on its own altitude band" % radius)
	for q in range(1, 5):
		tick.call(period / 4.0)
		var expect := first.rotated(Vector3.DOWN, TAU * q / 4.0)
		check((wing.visual_position() - center).distance_to(expect) < 0.02, "guard orbit quarter %d keeps its radius and period" % q)
	check(wing.position == hex and wing.ring.position.y < 0.0, "orbit leaves the rules hex and footprint on the plane")
	check(wing.hull.global_position.distance_to(wing.visual_position()) < 0.02, "the drawn wing follows its orbital centre")
	var line_end: Vector3 = wing.to_global(wing.drop.position + wing.drop.basis.y * 0.5)
	check(line_end.distance_to(wing.hull.global_position) < 0.02, "the drop-line reaches the orbiting wing, not empty air over its hex")
	carrier.position += Vector3(4.0, 0.0, -3.0)
	tick.call(0.0)
	var held := wing.visual_position()
	check(held.distance_to(center + first + Vector3(4.0, 0.0, -3.0)) < 0.02, "the orbit follows the carrier, not the launch hex")
	fx.hit_pause(fx.now, 3)
	tick.call(0.0)   # the frame that receives the hit starts the pause
	tick.call(0.04)
	check(fx.dt < 0.02 and held.distance_to(wing.visual_position()) < radius * 0.02, "hit pause slows the orbit with the FX clock")
	held = wing.visual_position()
	wing.hold_wing_orbit(fx.now + 1.0)
	tick.call(0.5)
	check(held.is_equal_approx(wing.visual_position()), "a dive holds the drawn anchor and does not also orbit")
	wing.guard_has_target = true
	for i in 30:
		tick.call(0.05)
	check(wing.visual_position().is_equal_approx(hex + Vector3.UP * ALT.WING), "a wing with a live target stays on its hex")
	wing.guard_has_target = false
	for i in 16:
		tick.call(0.05)
	wing.calm = true
	tick.call(0.05)
	check(wing.visual_position().is_equal_approx(hex + Vector3.UP * ALT.WING), "Reduce motion turns the orbit off")
	wing.calm = false
	carrier.dead = true
	tick.call(0.05)
	check(wing.visual_position().is_equal_approx(hex + Vector3.UP * ALT.WING), "a dead carrier cannot take a wing into orbit")
	wing.queue_free()
	carrier.queue_free()
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

# Fable on PR 1874: the paths a hand-made call skips. A wing volley through FXW.volley (hits and misses), the wing's own
# drop-line and pick, the real _ray_hex, the shared line style on the drop-line, and the chips' air.
class StubBoard extends "res://render/board.gd":
	func refresh() -> void:
		pass


func _min_run_y(fx) -> float:
	var lo := INF
	for r in fx.dstate.get("craft_runs", []):
		for k in 41:
			lo = minf(lo, FXW._dive_pos(r["a"], r["b"], r["dive"], float(k) / 40.0).y)
	return lo


func _fable(world: Node3D) -> void:
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "shake": 0.0})
	var shooter := SV.new()
	world.add_child(shooter)
	shooter.setup({"id": "shooter", "fac": "hegemony", "cls": "Cruiser", "code": "H9_23", "facing": 1}, Vector3.ZERO)
	shooter.set_band(ALT.WING)
	var tgt := SV.new()
	world.add_child(tgt)
	tgt.setup({"id": "tgt", "fac": "corsair", "cls": "Battleship", "code": "H9_23", "facing": 4}, Vector3(70, 0, 10))
	fx.add_ship("shooter", shooter, {"faction": "hegemony", "cls": "Cruiser", "meshes": shooter.meshes})
	fx.add_ship("tgt", tgt, {"faction": "corsair", "cls": "Battleship", "meshes": tgt.meshes})
	var T = fx.ship("tgt")
	var ty: float = T.to_world(T.hull.c).y
	for hit in [false, true]:
		fx.dstate["craft_runs"] = []
		FXW.volley(fx, "shooter", "sq", "tgt", {"weapon_id": "guns", "shots": [hit, hit, hit]})
		var lo := _min_run_y(fx)
		check(fx.dstate["craft_runs"].size() > 0, "a wing volley flies its craft (%s)" % ("hit" if hit else "miss"))
		check(lo > ty - 1.0 and lo > -1.0, "a %s pass never dives under its target or the board (low %.2f, target %.2f)" % ["hit" if hit else "missed", lo, ty])
		check(lo < ty + 4.0, "a %s pass still dives down to its target (low %.2f)" % ["hit" if hit else "missed", lo])
	# Reduce motion: the same pass dives gently and never banks
	var steep := {}
	for calm in [false, true]:
		fx.reduce_motion = calm
		fx.dstate["craft_runs"] = []
		FXW._strafe(fx, "fighter", Vector3(0, ALT.WING, 0), Vector3(60, -2.0, 8), fx.now, Color.WHITE, {"engine": Color.ORANGE}, 1.0, 1.0, 1, "hegemony")
		var rc: Dictionary = fx.dstate["craft_runs"][0]
		steep[calm] = _steepest(rc)
		check(bool(rc["dive"].get("calm", false)) == calm, "the pass knows Reduce motion is %s" % ("on" if calm else "off"))
	check(steep[true] < steep[false] * 0.6, "Reduce motion softens the dive (steepest %.2f against %.2f)" % [steep[true], steep[false]])
	fx.reduce_motion = false
	fx.remove_ship("shooter")
	fx.remove_ship("tgt")
	fx.queue_free()
	# a wing draws a drop-line and the pointer on it picks the wing's hex, through the real ray pick
	var wing := SV.new()
	world.add_child(wing)
	wing.setup({"id": "w1", "fac": "hegemony", "cls": "Squadron", "squadron": true, "facing": 0}, Vector3(30, 0, 0))
	wing.set_marker(true)
	wing.set_band(ALT.height({"id": "w1", "cls": "Squadron", "squadron": true}))
	check(wing.drop != null and wing.drop.visible, "a wing draws its drop-line to its hex")
	check(wing.drop != null and wing.drop.material_override is ShaderMaterial, "the drop-line takes the shared line style")
	if wing.drop != null:
		var lm := wing.drop.material_override as ShaderMaterial
		var rest: float = (lm.get_shader_parameter("col") as Color).a
		check(absf(rest - preload("res://render/line_style.gd").col("drop_ally").a * SV.DROP_A[0]) < 0.01, "its colour and strength are the line style role's")
		wing.set_hot(true)
		wing._drop_step(1.0)
		check(float(lm.get_shader_parameter("wide")) > 1.2 and (lm.get_shader_parameter("col") as Color).a > rest * 2.0, "hover widens and brightens it")
		var bx: Basis = wing.drop.transform.basis
		check(absf(bx.x.dot(bx.y)) < 1e-4, "the line never shears with heading")
		wing.set_hot(false)
	var battle := BATTLE.new()
	var board := StubBoard.new()
	world.add_child(board)
	for q in range(-2, 8):
		for r in range(-4, 6):
			board.index[board.key(q, r)] = q
	battle.board = board
	var cam := Camera3D.new()
	world.add_child(cam)
	var wq: Vector2i = board.world_hex(Vector3(30, 0, 0))
	wing.position = board.hex_world(wq.x, wq.y)
	cam.global_position = wing.position + Vector3(0, 170.0 * cos(0.98), 170.0 * sin(0.98))   # the home camera: 170 out, 0.98 from vertical
	cam.look_at(wing.position)
	cam.current = true
	battle.cam = cam
	battle.views = {"w1": wing}
	battle.VU = {"w1": {"id": "w1", "q": wq.x, "r": wq.y, "squadron": true}}
	var wp: Vector2 = cam.unproject_position(wing.visual_position())
	var ro: Vector3 = cam.project_ray_origin(wp)
	var rn: Vector3 = cam.project_ray_normal(wp)
	var plane_h: Vector2i = board.world_hex(ro + rn * (-ro.y / rn.y))
	check(plane_h != wq, "a wing's picture sits over another hex (the case the pick is for)")
	check(battle._ray_hex(wp) == wq, "the pointer on a wing picks the wing's own hex through the ray pick (%s, want %s)" % [str(battle._ray_hex(wp)), str(wq)])
	battle.views = {}
	check(battle._ray_hex(wp) == plane_h, "with no hull there the ray pick keeps the plane hex")
	battle.free()
	# the chips hang under every ship band and far under the wings' passes
	var BD := preload("res://render/board.gd")
	var lowest_ship: float = float(ALT.ESCORT[1]) * ALT.BELOW_K
	check(float(BD.FRAG_Y[0]) > lowest_ship + 0.8, "depth chips sit under the lowest ship (%.1f below, ships to %.1f)" % [BD.FRAG_Y[0], lowest_ship])
	check(float(BD.FRAG_R[1]) < HT.HEX_S * 0.5, "and close to their own hex's middle")



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
	_guard_orbit(world)
	_dive(world)
	_fable(world)
	_personalities()
	await process_frame
	world.queue_free()
	await process_frame
	SV.clear_static()
	print("STAGE2 %s: %d checks, %d failures" % ["PASS" if fails == 0 else "FAIL", checks, fails])
	quit(1 if fails > 0 else 0)
