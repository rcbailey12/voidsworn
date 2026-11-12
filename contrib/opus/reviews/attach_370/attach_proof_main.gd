extends SceneTree
# Issue 370: the attach point check. Every point the attach point service (fx/fx_hull.gd, "the attach point service")
# can hand an effect lies on the hull: within TOL_FRAC of the ship's length of its triangles (the export check's own limit,
# tools/recipe/check_export.py tol 0.012), plus the barrel or bell radius for an authored muzzle or engine exit (the point is
# the centre of the mouth, extras.radius from its rim). The core is the exception, as in the export check: it is inside the
# hull, so it must lie inside the hull's box. A skipped effect returns no point at all; skips are counted and reported.
#
# Hulls walked:
#   - every ship the game can build here: the A4 and recipe ships in godot/assets/ships/<CODE>/<CODE>.glb, through the real
#     ShipView when the built ship files (godot/gen) are present (Ryan's PC: all 36), else loaded straight from the glb;
#   - three stand-in shapes made here, so the check bites on GitHub where no ship files exist: a slab (a flat wedge that
#     leaves its box corners empty), a ring (a torus, its box centre in the hole) and a tower (a disc and a tall spire).
#     They carry a few authored points (on the surface by construction) and lack others, so every fallback runs.
# What is walked per hull: every authored point; the gun muzzles for every slot, weapon and 16 target directions (and
# the station rays they fall back to); wing launches; the core; breach anchors and surface samples; every movement jet
# ShipView fires (render/ship_view.gd jet_aims) and the hit-reaction corner jets (fx_ship.gd _rcs); boarding origins.
# Behaviour proofs on the stand-ins: an authored muzzle wins over the ray; more shots than points cycle the points; a ray
# that finds no plating skips and is counted; a point moved off the hull is caught by this check's own distance walk.
#
#   godot --headless --path godot --script res://fx/test/attach_check.gd [-- --only CODE,CODE] [-- --out FILE.json]
# Distance: the shortest of 258 rays cast from the point (a Fibonacci sphere plus the point's own axes) onto the hull's
# triangles, an upper bound on the true distance, so a pass is sound; a point between rays could read long (a loud fail).

const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const HT := preload("res://render/hull_table.gd")
const TOL_FRAC := 0.012
const DIRS := 16

var failures := 0
var fx
var world: Node3D
var report := {"tolerance_of_length": TOL_FRAC, "hulls": {}}
var _sphere: Array = []


class StandIn extends Node3D:
	var code := ""
	var attach = null


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("ATTACH FAIL: " + message)
		print("ATTACH FAIL: " + message)


func _args() -> Dictionary:
	var out := {}
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		if a[i].begins_with("--") and i + 1 < a.size() and not a[i + 1].begins_with("--"):
			out[a[i].substr(2)] = a[i + 1]
			i += 2
		else:
			out[a[i].trim_prefix("--")] = true
			i += 1
	return out


func _run() -> void:
	var args := _args()
	world = Node3D.new()
	root.add_child(world)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "shake": 0.0})
	for k in 256:
		var y := 1.0 - (k + 0.5) / 128.0
		var r := sqrt(maxf(0.0, 1.0 - y * y))
		var t := k * 2.399963
		_sphere.append(Vector3(r * cos(t), y, r * sin(t)))
	_stand_ins()
	var only: Array = str(args.get("only", "")).split(",", false) if args.has("only") else []
	var n_real := 0
	print("[attach] real hulls walked: %d%s" % [n_real, "" if n_real > 0 else " (no ship files in this checkout: stand-ins only)"])
	var skipped := 0
	for code in report["hulls"]:
		skipped += int(report["hulls"][code]["skipped"])
	report["failures"] = failures
	report["skipped_total"] = skipped
	if args.has("out"):
		var f := FileAccess.open(str(args["out"]), FileAccess.WRITE)
		f.store_string(JSON.stringify(report, " ", false))
		f.close()
	print("ATTACH_CHECK %s: %d hulls, %d failures, %d effects skipped by the walk" % ["PASS" if failures == 0 else "FAIL", report["hulls"].size(), failures, skipped])
	fx.release()
	world.queue_free()
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- the walk

# The hull's triangles as rays see them: the shortest hit over the sphere of directions and the point's own axes.
func _dist(h, p: Vector3, extra: Array = []) -> float:
	if h.tm == null:
		return INF
	var best := INF
	var dirs: Array = _sphere.duplicate()
	for e in extra:
		if (e as Vector3).length() > 1e-6:
			dirs.append((e as Vector3).normalized())
			dirs.append(-(e as Vector3).normalized())
	var eps: float = maxf(h.L, 1.0) * 1e-4
	for d in dirs:
		var hit: Dictionary = h.tm.intersect_ray(p - d * eps, d)
		if not hit.is_empty():
			best = minf(best, (hit["position"] as Vector3).distance_to(p))
	return best


func _walk(id: String, s, real: bool) -> Dictionary:
	var h = s.hull
	var tol: float = TOL_FRAC * h.L
	var rows: Array = []
	var worst := [0.0]   # (an array: the lambda below writes it)
	var bad: Array = []
	var seen := {}
	var put := func(what: String, pt: Dictionary, allow := 0.0) -> void:
		if pt.is_empty():
			return
		var p: Vector3 = pt["p"]
		var key := "%s|%.3f|%.3f|%.3f" % [what, p.x, p.y, p.z]
		if seen.has(key):
			return
		seen[key] = true
		var d := _dist(h, p, [pt.get("n", Vector3.ZERO), pt.get("f", Vector3.ZERO)])
		rows.append({"what": what, "src": str(pt.get("src", "")), "p": [snappedf(p.x, 0.001), snappedf(p.y, 0.001), snappedf(p.z, 0.001)], "d": snappedf(d, 0.0001)})
		worst[0] = maxf(worst[0], d - allow)
		if d > tol + allow:
			bad.append("%s %s (%s) is %.3f from the hull (limit %.3f)" % [id, what, str(pt.get("src", "")), d, tol + allow])
	# authored points (the core is inside: inside the box)
	if h.get("points") != null:
		for k in h.points:
			for pt in h.points[k]:
				var r: float = float((pt["ex"] as Dictionary).get("radius", 0.0)) if k in ["gun", "engine"] else 0.0
				if k == "core":
					var bx: AABB = h.box.grow(tol)
					check(bx.has_point(pt["p"]), "%s hp_core %s is outside the hull's box" % [id, str(pt["p"])])
					continue
				put.call("hp " + str(pt["name"]), _with(pt, "hp"), r)
	# the station rays (guns with no authored point fall back to these); on main a miss here was a box point
	for side in h.mounts:
		for m in h.mounts[side]:
			put.call("station " + side, _with(m, "ray"))
	var dirs: Array = []
	for i in DIRS:
		var a := TAU * i / DIRS
		dirs.append(h.c + Vector3(cos(a), 0.0, sin(a)) * h.L * 4.0)
	if not h.has_method("guns"):
		for t in dirs:
			for m in h.mounts_for(t, 4):
				put.call("mount", _with(m, "ray"))
		return _close(id, h, rows, bad, worst[0], tol)
	# gun muzzles: every slot the hull has points for, the unknown slot, every weapon it names, and none
	var slots := {-1: true}
	var weapons := {"": true}
	for pt in h.points.get("gun", []):
		slots[int(pt["slot"])] = true
		weapons[str(pt["weapon"])] = true
	for t in dirs:
		for sl in slots:
			for w in weapons:
				for heavy in [false, true]:
					for m in h.guns(int(sl), str(w), t, 6, heavy):
						put.call("gun", m, float(_radius_at(h, m)))
	# wing launches, the core, wounds, boarding
	for t in dirs:
		for i in 3:
			put.call("bay", h.bay(i, t))
		put.call("board", h.board_origin(t))
	var cp: Dictionary = h.core_point()
	if not cp.is_empty():
		check(h.box.grow(tol).has_point(cp["p"]), "%s core %s is outside the hull's box" % [id, str(cp["p"])])
	for sec in 3:
		for nth in 4:
			put.call("breach", h.breach_point(sec, nth))
		put.call("breach up", h.breach_point(sec, 1, Vector2(0.15, 0.75)))
		for j in 12:
			put.call("sample", h.surface_sample(sec, 2.5, "breach"))
	# movement jets: every row ShipView fires, at its own fitted beam and height when it is a ShipView
	var sv = s.root
	var L: float = float(sv.get("L")) if sv.get("L") != null and sv is SV else h.L
	var hw: float = float(sv.get("half_w")) if sv is SV else h.W * 0.5
	var hh: float = float(sv.get("half_h")) if sv is SV else h.H * 0.5
	for kind in ["couple", "retro", "aft", "side"]:
		for sgn in [1.0, -1.0]:
			for j in []:
				var o: Vector3 = (j[2] as Vector3).normalized()
				var aim: Vector3 = j[0]
				var through: Vector3 = aim - o * (aim - (h.core as Vector3)).dot(o)
				put.call("jet " + kind, h.jet(aim, through, o))
	# hit-reaction jets: fx_ship._rcs's corner candidates
	for sx in [-0.32, 0.32]:
		for sy in [-0.45, 0.45]:
			for sz in [-0.5, 0.5]:
				var rp: Vector3 = h.c + Vector3(sx * h.L, sy * h.H, sz * h.W)
				put.call("rcs corner", h.jet(rp, h.c, rp - h.c))
	return _close(id, h, rows, bad, worst[0], tol)


func _radius_at(h, m: Dictionary) -> float:
	if m.is_empty() or str(m.get("src", "")) != "hp":
		return 0.0
	for pt in h.points.get("gun", []):
		if (pt["p"] as Vector3).is_equal_approx(m["p"]):
			return float((pt["ex"] as Dictionary).get("radius", 0.0))
	return 0.0


static func _with(pt: Dictionary, src: String) -> Dictionary:
	var out := pt.duplicate()
	out["src"] = src
	return out


func _close(id: String, h, rows: Array, bad: Array, worst: float, tol: float) -> Dictionary:
	for b in bad:
		check(false, b)
	var counts: Dictionary = h.attach_counts.duplicate(true) if h.get("attach_counts") != null else {}
	var sk: int = h.skipped() if h.has_method("skipped") else 0
	var authored := {}
	if h.get("points") != null:
		for k in h.points:
			authored[k] = (h.points[k] as Array).size()
	var line := "[attach] %s: %d points walked, worst %.4f past the limit %.4f, %d off the hull; authored %s; skipped %d; %s" % [
		id, rows.size(), worst, tol, bad.size(), str(authored), sk, str(counts)]
	print(line)
	var out := {"id": id, "length": h.L, "tolerance": tol, "walked": rows.size(), "off_hull": bad.size(), "authored": authored,
		"counts": counts, "skipped": sk, "core_authored": h.get("core_authored") == true, "bad": bad, "rows": rows}
	report["hulls"][id] = out
	return out


# ---------------------------------------------------------------- the stand-in shapes

func _mesh_of(m: PrimitiveMesh, xf := Transform3D.IDENTITY) -> MeshInstance3D:
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, m.get_mesh_arrays())
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.transform = xf
	return mi


func _hp(parent: Node3D, name: String, p: Vector3, fwd: Vector3, up: Vector3, extras := {}) -> Node3D:
	var n := Node3D.new()
	n.name = name
	var z := -fwd.normalized()
	var x := up.normalized().cross(z).normalized()
	n.transform = Transform3D(Basis(x, z.cross(x), z), p)
	if not extras.is_empty():
		n.set_meta("extras", extras)
	parent.add_child(n)
	return n


func _stand(code: String, pos: Vector3, parts: Array) -> StandIn:
	var node := StandIn.new()
	node.code = code
	node.name = code
	world.add_child(node)
	node.position = pos
	for p in parts:
		node.add_child(p)
	return node


func _add(id: String, node: StandIn, cls: String) -> Object:
	var meshes: Array = []
	for c in node.get_children():
		if c is MeshInstance3D:
			meshes.append(c)
	fx.add_ship(id, node, {"faction": "deathless", "cls": cls, "size": 0.8, "meshes": meshes})
	return fx.ship(id)


func _stand_ins() -> void:
	# slab: a flat wedge (bow +X), 24 long, 1 thick, 12 wide at the stern: its box corners at the bow are empty
	var wedge := PrismMesh.new()
	wedge.size = Vector3(12.0, 24.0, 1.0)   # the triangle's base 12 (z after the turn), its height 24 (x), 1 thick (y)
	wedge.left_to_right = 0.5
	var slab_xf := Transform3D(Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)), Vector3.ZERO)   # mesh x to z, y to x, z to y
	var slab := _stand("ST_slab", Vector3(-60, 0, 0), [_mesh_of(wedge, slab_xf)])
	# its authored muzzles: slot 0 two macro barrels on the top face, slot 1 one lance at the bow tip, and a core
	_hp(slab, "hp_w0_hbattery_T_0", Vector3(-4, 0.5, 1.0), Vector3(1, 0, 0), Vector3.UP, {"radius": 0.1})
	_hp(slab, "hp_w0_hbattery_T_1", Vector3(-4, 0.5, -1.0), Vector3(1, 0, 0), Vector3.UP, {"radius": 0.1})
	_hp(slab, "hp_w1_lance_F_0", Vector3(12, 0, 0), Vector3(1, 0, 0), Vector3.UP)
	_hp(slab, "hp_core", Vector3(-4, 0, 0), Vector3(1, 0, 0), Vector3.UP)
	# ring: a torus 18 across with a 3 thick tube, lying flat; nothing at its centre
	var torus := TorusMesh.new()
	torus.inner_radius = 6.0
	torus.outer_radius = 9.0
	torus.rings = 48
	torus.ring_segments = 16
	var ring := _stand("ST_ring", Vector3(0, 0, 0), [_mesh_of(torus)])
	_hp(ring, "hp_w0_torp_F_0", Vector3(9, 0, 0), Vector3(1, 0, 0), Vector3.UP, {"radius": 0.2})
	_hp(ring, "hp_breach_0", Vector3(0, 0, -9), Vector3(1, 0, 0), Vector3(0, 0, -1), {"section": "mid", "side": "P"})
	_hp(ring, "hp_breach_1", Vector3(7.5, 1.5, 0), Vector3(1, 0, 0), Vector3.UP, {"section": "prow", "side": "S"})
	# tower: a disc 16 across and 1 thick, a spire 1.6 across rising 14 above it; no authored points at all
	var disc := CylinderMesh.new()
	disc.top_radius = 8.0
	disc.bottom_radius = 8.0
	disc.height = 1.0
	disc.radial_segments = 48
	var spire := CylinderMesh.new()
	spire.top_radius = 0.6
	spire.bottom_radius = 0.8
	spire.height = 14.0
	spire.radial_segments = 16
	var tower := _stand("ST_tower", Vector3(60, 0, 0), [_mesh_of(disc), _mesh_of(spire, Transform3D(Basis(), Vector3(0, 7.5, 0)))])
	_add("slab", slab, "Cruiser")
	_add("ring", ring, "Tomb-ark")
	_add("tower", tower, "Cruiser")
	for id in ["slab", "ring", "tower"]:
		_walk(id, fx.ship(id), false)


# ---------------------------------------------------------------- every real hull present

func _real_hulls(only: Array) -> int:
	var base := "res://assets/ships"
	var da := DirAccess.open(base)
	if da == null:
		return 0
	var man: Dictionary = SV.manifest()
	var by_code := {}
	for key in HT.AI_HULLS:
		by_code[str(HT.AI_HULLS[key])] = str(key).split("|")
	var n := 0
	var x := 0.0
	for code in da.get_directories():
		if not only.is_empty() and not only.has(code):
			continue
		var glb := base.path_join(code).path_join(code + ".glb")
		var built: bool = man.has("ships") and (man["ships"] as Dictionary).has(code)
		if not built and not FileAccess.file_exists(glb):
			continue
		var fc: Array = by_code.get(code, ["hegemony", "Cruiser"])
		var fac := str(fc[0]) if HT.FAC3D.has(str(fc[0])) else "hegemony"
		var cls := str(fc[1]) if fc[0] in HT.FAC3D else "Cruiser"
		var root3: Node3D
		x += 80.0
		if built:
			var sv = SV.new()
			world.add_child(sv)
			sv.setup({"id": code, "fac": fac, "cls": cls, "facing": 0, "code": code, "L": float(HT.CLS_LEN.get(cls, 10.0)) * HT.SHIP_K}, Vector3(x, 0, 200), true)
			sv.set_process(false)
			root3 = sv
		else:
			var doc := GLTFDocument.new()
			var st := GLTFState.new()
			if doc.append_from_file(ProjectSettings.globalize_path(glb), st) != OK:
				check(false, "%s: its glb does not load" % code)
				continue
			var scene: Node = doc.generate_scene(st)
			var node := StandIn.new()
			node.code = code
			world.add_child(node)
			node.position = Vector3(x, 0, 200)
			node.add_child(scene)
			root3 = node
		fx.add_ship("real_" + code, root3, {"faction": fac, "cls": cls, "size": 1.0, "code": code})
		var s = fx.ship("real_" + code)
		_walk("real_" + code, s, true)
		fx.remove_ship("real_" + code)
		root3.queue_free()
		n += 1
	return n
