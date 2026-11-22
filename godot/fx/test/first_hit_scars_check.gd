extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1235 (Neon's damage audit, top fix 1): a ship looks hit from the first hit, on box stand-ins, no ship files.
# 1. a first torpedo on a healthy section leaves a mark at least BREACH.MARK_FLOOR of its full size (F1.1), capped at
#    BREACH.CRATER_MAX_L so it stays clearly under the stage 4 hole
# 2. the per-section cap keeps the heavy and the newest marks, not the oldest (F1.3)
# 3. a bomber run leaves a mark (F1.4)
# 4. a turret's turning mesh is never gathered into the static damage rebuild (F3.4)
# 5. only the meshes a damage entry reaches lose their automatic LOD (F1.5)
# 6. the stage 4 hole is BREACH.STAGE4_HOLE_L of the ship's length (F1.2)
# 7. a breach anchor under a turret's foot moves off it, so no whole turret stands over a stage 4 hole
const FX := preload("res://fx/fx.gd")
const BREACH := preload("res://fx/fx_breach.gd")
var failures := 0
var fx
var world: Node3D


func _init() -> void:
	GUARD.arm(self, "first_hit_scars_check")
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


# A cruiser stand-in: a hull box, a far tail box (a second mesh nothing hits) and a turret with its own turning mesh.
func _ship(sid: String, faction: String, pos: Vector3):
	var body := Node3D.new()
	world.add_child(body)
	body.position = pos
	var hull := MeshInstance3D.new()
	hull.name = "hull"
	hull.mesh = _box(Vector3(24, 5, 8), 17)
	body.add_child(hull)
	var tail := MeshInstance3D.new()
	tail.name = "tail"
	tail.mesh = _box(Vector3(4, 2, 3), 3)
	tail.position = Vector3(-15, 0, 0)
	body.add_child(tail)
	var tur := Node3D.new()
	tur.name = "turret_1"
	tur.position = Vector3(6, 2.5, 0)
	body.add_child(tur)
	var tm := MeshInstance3D.new()
	tm.name = "turret_mesh"
	tm.mesh = _box(Vector3(2, 1, 2), 2)
	tm.position = Vector3(0, 0.5, 0)
	tur.add_child(tm)
	var meshes: Array = [hull, tail, tm]
	fx.add_ship(sid, body, {"faction": faction, "cls": "Cruiser", "size": 0.8, "meshes": meshes, "shielded": false})
	fx._later.clear()
	var s = fx.ship(sid)
	for i in 3:
		s._anchors["a%d" % i] = {"p": Vector3((i - 1) * 7, 2.5, 0), "n": Vector3.UP, "t": {}}
	return [s, hull, tail, tm]


func _state(mid: float) -> Dictionary:
	return {"hp": 100.0, "maxHp": 100.0, "sec": {"eng": {"hp": 100, "max": 100}, "mid": {"hp": mid, "max": 100}, "prow": {"hp": 100, "max": 100}}}


func flush(s) -> void:
	for i in 5:
		if s._dmg_task >= 0:
			s.flush_damage(fx)
		fx.step(0.01)


func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})

	# 1. first hit size, against the same hit on a broken section
	for faction in ["voidsworn", "ithar", "chorus"]:
		var row: Array = _ship("first_" + faction, faction, Vector3(0, 0, 0))
		var s = row[0]
		s.sync(fx, _state(100.0))
		s.add_mark(fx, "torp", 4, Vector3(0, 2.5, 0), Vector3.UP, Vector3.DOWN)
		flush(s)
		var fresh: float = s._marks[0].R
		var full: Array = BREACH.marks_for(s.hull, "torp", 4, Vector3(0, 2.5, 0), Vector3.UP, Vector3.DOWN, 1.0, faction, 1.0, 1.0)
		var want: float = minf((full[0] as BREACH.Ent).R * BREACH.MARK_FLOOR, s.hull.L * BREACH.CRATER_MAX_L)
		check(fresh >= want - 1e-4 and fresh >= s.hull.L * 0.04 * 1.5 * 0.12 * 3.0,
			"%s: first torpedo on a healthy section reads (%.3f, at least %.3f and 3x the old 12%% mark)" % [faction, fresh, want])
		check(fresh <= s.hull.L * BREACH.CRATER_MAX_L + 1e-4 and fresh < s.hull.L * BREACH.STAGE4_HOLE_L * 0.65,
			"%s: the first-hit crater stays clearly under the stage 4 hole (%.3f L against %.3f L)" % [faction, fresh / s.hull.L, BREACH.STAGE4_HOLE_L])
		check(s._marks[0].halo >= float(BREACH.HALO_MIN[BREACH.S_BLAST]) - 1e-4, "%s: the first torpedo keeps its full battle-distance halo" % faction)
		# the sync right after the volley (a 10% section loss) does not regrade and rebuild the mark again
		var before = s._marks[0]
		s.sync(fx, _state(90.0))
		check(s._marks[0] == before, "%s: a small section loss does not rebuild the first mark a second time" % faction)
		# it still grows when the section is badly hurt
		s.sync(fx, _state(15.0))
		flush(s)
		check(s._marks[0].R > fresh * 1.2, "%s: a badly hurt section still grows the mark" % faction)
		# 6. the stage 4 hole
		var holes := 0
		for e in s._dmg_job["ents"]:
			if e.has_cut():
				holes += 1
				check(absf(e.R - s.hull.L * BREACH.STAGE4_HOLE_L) < 1e-3, "%s: the stage 4 hole is %.3f of the ship's length" % [faction, BREACH.STAGE4_HOLE_L])
		check(holes > 0, "%s: a broken section opens a hole" % faction)
		s.root.get_parent().queue_free()

	# 2. the cap keeps heavy and new marks (stage 0: two marks a section)
	var row2: Array = _ship("cap", "hegemony", Vector3(40, 0, 0))
	var c = row2[0]
	c.sync(fx, _state(100.0))
	c.add_mark(fx, "auto", 1, Vector3(-2, 2.5, 2), Vector3.UP, Vector3.DOWN)
	c.add_mark(fx, "auto", 1, Vector3(2, 2.5, -2), Vector3.UP, Vector3.DOWN)
	c.add_mark(fx, "macro", 2, Vector3(1, 2.5, 3), Vector3.UP, Vector3.DOWN)
	var newest = c._marks[c._marks.size() - 1]
	var vis: Array = c.visible_marks(fx)
	check(vis.has(newest), "the newest mark on a capped section is drawn")
	check(vis.size() == 2, "a stage 0 section draws two marks (%d)" % vis.size())
	c.add_mark(fx, "torp", 4, Vector3(-1, 2.5, 0), Vector3.UP, Vector3.DOWN)
	var torp = c._marks[c._marks.size() - 1]
	c.add_mark(fx, "auto", 1, Vector3(3, 2.5, 1), Vector3.UP, Vector3.DOWN)
	c.add_mark(fx, "auto", 1, Vector3(-3, 2.5, -1), Vector3.UP, Vector3.DOWN)
	vis = c.visible_marks(fx)
	check(vis.has(torp), "a torpedo crater stays drawn after later light hits")
	check(vis.has(c._marks[c._marks.size() - 1]), "the newest light hit is drawn beside the torpedo")
	flush(c)
	var job_marks := 0
	for e in c._dmg_job["ents"]:
		if e.look != "" and e.sec == torp.sec:
			job_marks += 1
	check(job_marks == 2 and (c._dmg_job["ents"] as Array).has(torp), "the hull rebuild carries only the drawn marks of the capped section")

	# 3. bombs
	var bm: Array = BREACH.marks_for(c.hull, "bombs", 2, Vector3(0, 2.5, 0), Vector3.UP, Vector3.DOWN, 2.0, "hegemony", 1.0, 0.0)
	check(not bm.is_empty(), "a bomber run leaves a mark")

	# 4. turret meshes stay out of the static rebuild
	var tm: MeshInstance3D = row2[3]
	var gathered := false
	var hull_in := false
	for sd in c._orig:
		if sd["mi"] == tm:
			gathered = true
		if sd["mi"] == row2[1]:
			hull_in = true
	check(not c._orig.is_empty() and hull_in, "the hull mesh is gathered for damage")
	check(not gathered, "a turret's turning mesh is never gathered into the static damage")

	# 5. LOD: the hit hull draws full detail, the untouched tail keeps its own LOD
	var hm: MeshInstance3D = row2[1]
	var tail: MeshInstance3D = row2[2]
	check(hm.lod_bias >= 128.0, "the damaged mesh draws its full detail")
	check(tail.lod_bias < 2.0, "a mesh no damage reaches keeps its automatic LOD (%.1f)" % tail.lod_bias)

	# 7. a breach under a turret's foot moves to the footprint's edge, onto the plating
	var feet: Array = c.turret_feet()
	check(feet.size() == 1, "the turret's footprint is measured (%d)" % feet.size())
	if feet.size() == 1:
		var fc: Vector3 = feet[0][0]
		var fr: float = feet[0][1]
		var Rh: float = c.hull.L * BREACH.STAGE4_HOLE_L
		var moved: Dictionary = c._off_turrets({"p": Vector3(fc.x, 2.5, fc.z), "n": Vector3.UP}, Rh)
		var dxz := Vector2(moved["p"].x - fc.x, moved["p"].z - fc.z).length()
		check(dxz >= fr + Rh - 1e-3, "a hole at a turret's foot moves clear of the turret (%.2f from its centre, foot %.2f + hole %.2f)" % [dxz, fr, Rh])
		check(absf(moved["p"].y - 2.5) < 0.05 and (moved["n"] as Vector3).y > 0.9, "the moved hole sits on the plating")
		var free: Dictionary = c._off_turrets({"p": Vector3(-8, 2.5, 0), "n": Vector3.UP}, Rh)
		check((free["p"] as Vector3).is_equal_approx(Vector3(-8, 2.5, 0)), "a hole away from every turret stays put")
		c._anchors.erase("a2")
		var a2: Dictionary = c._anchor(2, "a")
		if not a2.is_empty():
			var d2 := Vector2(a2["p"].x - fc.x, a2["p"].z - fc.z).length()
			check(d2 >= fr + Rh - 1e-3, "a sampled stage 4 anchor in the turret's section is clear of the turret (%.2f)" % d2)

	# 7b. two seats side by side (Artoo, PR 1245): a move out of one footprint must not land in the other
	var row3: Array = _ship("pair", "voidsworn", Vector3(0, 0, 40))
	var pr = row3[0]
	var t2 := Node3D.new()
	t2.name = "turret_2"
	t2.position = Vector3(9, 2.5, 0)
	(row3[3] as Node).get_parent().get_parent().add_child(t2)
	var tm2 := MeshInstance3D.new()
	tm2.mesh = _box(Vector3(2, 1, 2), 2)
	tm2.position = Vector3(0, 0.5, 0)
	t2.add_child(tm2)
	pr.hull._read_turrets(pr.root)
	pr._feet_done = false
	var pf: Array = pr.turret_feet()
	check(pf.size() == 2, "both seats of the pair are measured (%d)" % pf.size())
	var Rp: float = pr.hull.L * BREACH.STAGE4_HOLE_L
	for x in [6.0, 7.5, 9.0]:
		var hp: Dictionary = pr._off_turrets({"p": Vector3(x, 2.5, 0), "n": Vector3.UP}, Rp, 2)
		check(hp.is_empty() or pr._clear_of_turrets(hp["p"], Rp), "a hole between two seats (x %.1f) ends clear of both, or opens nowhere" % x)
		if not hp.is_empty():
			check(absf(hp["p"].y - 2.5) < 0.05, "the moved hole between two seats sits on the plating")
	for k in 3:
		pr._anchors.erase("a%d" % k)
		var ak: Dictionary = pr._anchor(k, "a")
		check(ak.is_empty() or pr._clear_of_turrets(ak["p"], Rp), "section %d's sampled stage 4 anchor is clear of both seats" % k)

	print("first_hit_scars_check: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
