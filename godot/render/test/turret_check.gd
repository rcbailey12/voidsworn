extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 560 (RULEBOOK 6.17, Ryan R219: turret guns turn to face their target when they fire; fixed side guns stay fixed).
# The turret check, headless, on the turret test ship: godot/render/test/fixtures/T560_fx/T560_fx.glb, written by the real
# stage 7 export (tools/recipe/turret_fixture.py: a small test hull with the recipe Hullbreaker kit's own turret parts, two
# fixed casemates and a bow tube). It is loaded the way the game loads a glb and drawn at a cruiser's game size, and the real
# effects system (fx/fx.gd, fx_weapons.gd, the attach point service in fx_hull.gd) fires its guns at a target set at a ring of
# bearings. The proofs, from the real functions (RULEBOOK 12.2):
#   1. the export arrives as the game reads it: two turret nodes, each with its turning mesh and its muzzle; the three fixed guns
#      are not turrets; turA trains through its kit's own arc (-120 to +120); turB's reach stops short of the mast beside it;
#   2. at every shot from a turret, the barrel's bearing (the muzzle node's own aim, read off the turned node) matches the
#      target's bearing within 1 degree when the target is inside the turret's reach, and sits on the reach edge when it is not
#      (turA at a target astern holds +-120; turB at a target behind the mast holds the mast's edge);
#   3. the flash and tracer start at the turned barrel: the shot's start point is the muzzle node's position at its fire time,
#      and each shot fires after its turret has arrived;
#   4. every frame: no turret is past its reach, no barrel line passes through the ship (an independent ray test against the
#      hull and every part that does not turn), and the traverse is smooth: no step over the eased peak rate, no jerk;
#      after its shots each turret trains back to rest;
#   5. fixed guns never move: every muzzle not under a turret keeps its exact transform through the whole run, and a fixed
#      gun's shot starts at its authored muzzle;
#   6. the rules result is unchanged: the same volleys on the same ship with its turret nodes removed (the old fixed guns) hit,
#      miss and strike the same sections; only the look's timing moves (each turret shot waits for its turret);
#   7. the cost: a turret step per frame, in microseconds.
#   godot --headless --path godot --script res://render/test/turret_check.gd [-- --out FILE.json]

const FX := preload("res://fx/fx.gd")
const HULL := preload("res://fx/fx_hull.gd")
const FIX := "res://render/test/fixtures/T560_fx/T560_fx.glb"
const K := 23.2          # the Cruiser class length 14.5 times SHIP_K 1.6 (render/hull_table.gd): the size ShipView draws it at
const DT := 1.0 / 60.0
const RANGE := 140.0

var failures := 0
var fx
var world: Node3D
var report := {"shots": [], "turrets": []}


class StandIn extends Node3D:
	var code := ""
	var attach = null


func _init() -> void:
	GUARD.arm(self, "turret_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TURRET FAIL: " + message)
		print("TURRET FAIL: " + message)


func _load(code: String, at: Vector3, strip_turrets := false) -> StandIn:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	var err := doc.append_from_file(ProjectSettings.globalize_path(FIX), st)
	check(err == OK, "the fixture glb loads (%s)" % FIX)
	var scene: Node3D = doc.generate_scene(st)
	scene.scale = Vector3(K, K, K)
	var node := StandIn.new()
	node.code = code
	node.name = code
	world.add_child(node)
	node.position = at
	node.add_child(scene)
	if strip_turrets:
		# the old export: the turret nodes gone, their meshes and muzzles straight on the ship node where they stood at rest
		for t in scene.find_children("turret_*", "Node3D", true, false):
			if not RegEx.create_from_string("^turret_\\d+$").search(String(t.name)):
				continue
			var ship_node: Node3D = t.get_parent()
			for c in t.get_children():
				var xf: Transform3D = (c as Node3D).global_transform
				t.remove_child(c)
				ship_node.add_child(c)
				(c as Node3D).global_transform = xf
			t.name = "was_" + String(t.name)
	return node


func _box(code: String, at: Vector3) -> StandIn:
	var bm := BoxMesh.new()
	bm.size = Vector3(12, 3, 5)
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bm.get_mesh_arrays())
	var mi := MeshInstance3D.new()
	mi.mesh = am
	var node := StandIn.new()
	node.code = code
	node.name = code
	world.add_child(node)
	node.position = at
	node.add_child(mi)
	return node


func _run() -> void:
	var args := {}
	var ua := OS.get_cmdline_user_args()
	for i in ua.size():
		if ua[i] == "--out" and i + 1 < ua.size():
			args["out"] = ua[i + 1]
	world = Node3D.new()
	root.add_child(world)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "shake": 0.0})
	var a_node := _load("T560_fx", Vector3.ZERO)
	fx.add_ship("A", a_node, {"faction": "corsair", "cls": "Cruiser", "size": 1.0, "code": "T560_fx"})
	var tgt := _box("TGT", Vector3(RANGE, 0, 0))
	fx.add_ship("T", tgt, {"faction": "corsair", "cls": "Frigate", "size": 0.6, "shielded": false})
	var A = fx.ship("A")
	var h = A.hull

	# 1. what arrives
	check(h.turrets.size() == 2, "two turret nodes arrive (got %d)" % h.turrets.size())
	if h.turrets.size() != 2:
		_finish(args)
		return
	var ids: Array = []
	for t in h.turrets:
		ids.append(str(t["id"]))
		check((t["muzzles"] as Array).size() == 1, "%s carries its one muzzle (got %s)" % [t["name"], str(t["muzzles"])])
		var meshes: int = 0
		for c in (t["node"] as Node3D).get_children():
			if c is MeshInstance3D:
				meshes += 1
		check(meshes == 1, "%s carries its turning mesh" % t["name"])
	check(ids == ["turA", "turB"], "the turrets are turA and turB (got %s)" % str(ids))
	var fixed := 0
	for pt in h.points["gun"]:
		if not pt.has("tur"):
			fixed += 1
	check(fixed == 3, "the two casemates and the bow tube are fixed guns (got %d fixed)" % fixed)
	var tA: Dictionary = h.turrets[0]
	var tB: Dictionary = h.turrets[1]
	check(not bool(tA["full"]) and absf(float(tA["ymin"]) + 120.0) < 0.6 and absf(float(tA["ymax"]) - 120.0) < 0.6,
		"turA trains through its kit's arc, -120 to +120 (got %.2f to %.2f, full %s)" % [tA["ymin"], tA["ymax"], str(tA["full"])])
	check(not bool(tB["full"]) and not (tB["blocked"] as Array).is_empty(),
		"turB's reach stops at the mast (reach %.1f to %.1f, %d blocked samples)" % [tB["ymin"], tB["ymax"], (tB["blocked"] as Array).size()])
	for t in h.turrets:
		report["turrets"].append({"name": t["name"], "id": t["id"], "arc": [t["lo"], t["hi"]], "reach": [t["ymin"], t["ymax"]],
			"full": t["full"], "blocked_deg": (t["blocked"] as Array).size() * int(HULL.CLEAR_STEP)})

	# the independent barrel test: every mesh that does not turn, and each muzzle node
	var fixed_faces := PackedVector3Array()
	var inv := a_node.global_transform.affine_inverse()
	var fixed_mis: Array = []
	for mi in A.meshes:      # the ship's own meshes (find_children would also return the effects' own meshes)
		if h._turret_above(mi, a_node) < 0:
			fixed_mis.append(mi)
	fixed_faces = HULL.faces_of(a_node, fixed_mis)
	var bvh := TriangleMesh.new()
	bvh.create_from_faces(fixed_faces)
	var muzzle_node := {}
	var fixed_rest := {}
	for nd in a_node.find_children("hp_w*", "Node3D", true, false):
		var k: int = h._turret_above(nd, a_node)
		if k >= 0:
			muzzle_node[k] = nd
		else:
			fixed_rest[String(nd.name)] = (nd as Node3D).global_transform

	# 2 to 4: a ring of target bearings (+ to port), two flak shots a volley (one from each turret)
	var bearings := [0.0, 45.0, 90.0, 150.0, 180.0, -60.0, -120.0, -175.0, 100.0, 20.0]
	var prev_y := [0.0, 0.0]
	var prev_d := [0.0, 0.0]
	var max_rate := 0.0
	var max_jerk := 0.0
	var worst_off := 0.0
	var step_us := 0
	var frames := 0
	var hits_with: Array = []
	for b in bearings:
		var dir := Vector3(cos(deg_to_rad(b)), 0, -sin(deg_to_rad(b)) * float(fx.starboard_z))
		tgt.position = A.to_world(h.core) + dir * RANGE
		var hits := [{"shield": 0, "hull": 1, "section": "mid", "crit": false}, {"shield": 0, "hull": 1, "section": "prow", "crit": false}]
		var T0: float = fx.now
		var r: Dictionary = fx.volley("A", "flak", "T", {"weapon_id": "flak", "slot": 3, "shots": [true, true], "hits": hits})
		hits_with.append([(r["impacts"] as Array).size(), (r["fires"] as Array).size()])
		var pending: Array = []
		for i in (r["muzzles"] as Array).size():
			var m: Dictionary = r["muzzles"][i]
			check(int(m["tur"]) >= 0, "bearing %.0f: flak shot %d leaves a turret" % [b, i])
			pending.append({"i": i, "t": T0 + float(r["fires"][i]), "p": m["p"], "tur": int(m["tur"])})
		var t_end: float = T0 + float((r["fires"] as Array).max()) + HULL.TURN_HOLD + HULL.TURN_MAX + 0.3
		while fx.now < t_end:
			fx.step(DT)
			var us := Time.get_ticks_usec()
			h.turret_step(fx.now)          # (already run by fx.step; run again on its own to time it)
			step_us += Time.get_ticks_usec() - us
			frames += 1
			for k in 2:
				var t: Dictionary = h.turrets[k]
				var y: float = t["yaw"]
				var d := y - float(prev_y[k])
				max_rate = maxf(max_rate, absf(d) / DT)
				max_jerk = maxf(max_jerk, absf(d - float(prev_d[k])))
				prev_d[k] = d
				prev_y[k] = y
				if not bool(t["full"]):
					check(y >= float(t["ymin"]) - 0.05 and y <= float(t["ymax"]) + 0.05, "%s at yaw %.2f is past its reach %.1f to %.1f" % [t["name"], y, t["ymin"], t["ymax"]])
				# the barrel line, read off the turned node: back along its aim from the muzzle, two thirds of its reach
				var mn: Node3D = muzzle_node[k]
				var tn: Node3D = t["node"]
				var tip := inv * mn.global_position
				var fw := (inv.basis * -mn.global_transform.basis.z).normalized()
				var up := (inv.basis * tn.global_transform.basis.y).normalized()
				var piv := inv * tn.global_position
				var rel := tip - piv
				var reach := (rel - up * rel.dot(up)).length()
				if not bvh.intersect_segment(tip - fw * reach * 0.67, tip).is_empty():
					check(false, "%s's barrel runs into the ship at yaw %.1f" % [t["name"], y])
			for pd in pending.duplicate():
				if fx.now + 1e-6 < float(pd["t"]):
					continue
				pending.erase(pd)
				var k: int = pd["tur"]
				var t: Dictionary = h.turrets[k]
				var mn: Node3D = muzzle_node[k]
				var tn: Node3D = t["node"]
				var tip := inv * mn.global_position
				var fw := (inv.basis * -mn.global_transform.basis.z).normalized()
				var got: float = h.bearing_of(Vector3(fw.x, 0, fw.z))
				var piv := inv * tn.global_position
				var want: float = h.bearing_of(inv * tgt.global_position - piv)
				var reaches: bool = h.turret_reaches(k, inv * tgt.global_position)
				var off := absf(wrapf(got - want, -180.0, 180.0))
				var rec := {"bearing": b, "turret": t["id"], "target_bearing": snappedf(want, 0.01), "barrel_bearing": snappedf(got, 0.01),
					"reaches": reaches, "yaw": snappedf(float(t["yaw"]), 0.01)}
				if reaches:
					worst_off = maxf(worst_off, off)
					check(off <= 1.0, "%s at a target on bearing %.1f: its barrel bears %.2f at the shot" % [t["id"], want, got])
				else:
					var edge: float = float(t["ymin"]) if absf(float(t["yaw"]) - float(t["ymin"])) < absf(float(t["yaw"]) - float(t["ymax"])) else float(t["ymax"])
					check(absf(float(t["yaw"]) - edge) < 0.1, "%s at an unreachable bearing %.1f holds its reach edge %.2f (yaw %.2f)" % [t["id"], want, edge, t["yaw"]])
					rec["edge"] = snappedf(edge, 0.01)
				# 3. the shot starts at the turned barrel's muzzle, read through the turned node, and the turret was there first
				var dp := ((pd["p"] as Vector3) - mn.global_position).length()
				rec["muzzle_offset"] = snappedf(dp, 0.0001)
				check(dp < 0.01, "%s's shot starts %.4f from its turned muzzle" % [t["id"], dp])
				check(h._turret_speed(k, fx.now) == 0.0 or absf(h._turret_speed(k, fx.now)) < 1.0, "%s is still turning when it fires" % t["id"])
				report["shots"].append(rec)
		check(pending.is_empty(), "bearing %.0f: every shot was seen fire (%d left)" % [b, pending.size()])
		for k in 2:
			var y: float = h.turrets[k]["yaw"]
			check(absf(y - 360.0 * roundf(y / 360.0)) < 0.05, "%s trains back to rest after its shots (yaw %.2f)" % [h.turrets[k]["name"], y])
			if not bool(h.turrets[k]["full"]):
				check(absf(y) < 0.05, "%s, whose reach is one run, comes home the way it went (yaw %.2f, not a whole turn round)" % [h.turrets[k]["name"], y])
	# 4. smooth: the eased traverse peaks at 1.5 times the average rate; one frame's change of step stays small
	check(max_rate <= HULL.TURN_RATE * 1.5 * 1.05 + 1.0, "no turret turns faster than the eased peak (max %.1f deg/s)" % max_rate)
	var jerk_cap: float = HULL.TURN_ACC * DT * DT * 1.1 + 0.01
	check(max_jerk <= jerk_cap, "no turret lurches: a frame's step changes by %.3f degrees at most (cap %.3f, TURN_ACC)" % [max_jerk, jerk_cap])
	report["max_rate_deg_s"] = snappedf(max_rate, 0.1)
	report["max_step_change_deg"] = snappedf(max_jerk, 0.001)
	report["worst_bearing_error_deg"] = snappedf(worst_off, 0.001)
	report["turret_step_us_per_frame"] = snappedf(float(step_us) / maxf(frames, 1), 0.1)

	# 5. fixed guns: a broadside at a target to port and to starboard, and the bow tube ahead
	for row in [[0, "scatter", 90.0], [1, "scatter", -90.0], [2, "torp", 0.0]]:
		var b: float = row[2]
		tgt.position = A.to_world(h.core) + Vector3(cos(deg_to_rad(b)), 0, -sin(deg_to_rad(b)) * float(fx.starboard_z)) * RANGE
		var r: Dictionary = fx.volley("A", str(row[1]), "T", {"weapon_id": str(row[1]), "slot": int(row[0]), "shots": [true], "hits": [{"shield": 0, "hull": 1, "section": "mid"}]})
		for m in r["muzzles"]:
			check(int(m["tur"]) == -1, "slot %d fires from a fixed gun" % int(row[0]))
			var near := INF
			for nm in fixed_rest:
				near = minf(near, ((fixed_rest[nm] as Transform3D).origin - (m["p"] as Vector3)).length())
			check(near < 0.01, "slot %d's shot starts at its authored muzzle (%.4f away)" % [int(row[0]), near])
		for i in 90:
			fx.step(DT)
	for nd in a_node.find_children("hp_w*", "Node3D", true, false):
		if fixed_rest.has(String(nd.name)):
			check((nd as Node3D).global_transform.is_equal_approx(fixed_rest[String(nd.name)]), "%s (a fixed gun) never moves" % nd.name)

	# 6. the rules result: the same volleys on the ship with no turret nodes (the old export's fixed guns)
	var b_node := _load("T560_fx_fixed", Vector3(0, 0, 400), true)
	fx.add_ship("B", b_node, {"faction": "corsair", "cls": "Cruiser", "size": 1.0, "code": "T560_fx_fixed"})
	var Bs = fx.ship("B")
	check(Bs.hull.turrets.is_empty(), "the copy with its turret nodes removed has no turrets (fixed guns, as before)")
	var tgt2 := _box("TGT2", Vector3(RANGE, 0, 400))
	fx.add_ship("T2", tgt2, {"faction": "corsair", "cls": "Frigate", "size": 0.6, "shielded": false})
	var same := true
	for j in bearings.size():
		var b: float = bearings[j]
		tgt2.position = Bs.to_world(Bs.hull.core) + Vector3(cos(deg_to_rad(b)), 0, -sin(deg_to_rad(b)) * float(fx.starboard_z)) * RANGE
		var hits := [{"shield": 0, "hull": 1, "section": "mid", "crit": false}, {"shield": 0, "hull": 1, "section": "prow", "crit": false}]
		var r: Dictionary = fx.volley("B", "flak", "T2", {"weapon_id": "flak", "slot": 3, "shots": [true, true], "hits": hits})
		if [(r["impacts"] as Array).size(), (r["fires"] as Array).size()] != hits_with[j]:
			same = false
		for i in 60:
			fx.step(DT)
	check(same, "the same volleys with and without turrets land the same shots and hits (only the look's timing moves)")
	_finish(args)


func _finish(args: Dictionary) -> void:
	report["failures"] = failures
	if args.has("out"):
		var f := FileAccess.open(str(args["out"]), FileAccess.WRITE)
		f.store_string(JSON.stringify(report, " ", false))
		f.close()
	for s in report.get("shots", []):
		print("[turret] %s target %7.2f barrel %7.2f yaw %7.2f%s muzzle off %.4f" % [s["turret"], s["target_bearing"], s["barrel_bearing"],
			s["yaw"], "" if s["reaches"] else " (outside its reach: edge %.2f)" % s["edge"], s["muzzle_offset"]])
	print("[turret] max rate %s deg/s, max step change %s deg, worst bearing error %s deg, turret step %s us a frame" % [
		report.get("max_rate_deg_s"), report.get("max_step_change_deg"), report.get("worst_bearing_error_deg"), report.get("turret_step_us_per_frame")])
	print("TURRET_CHECK %s: %d failures" % ["PASS" if failures == 0 else "FAIL", failures])
	fx.release()
	world.queue_free()
	quit(1 if failures > 0 else 0)
