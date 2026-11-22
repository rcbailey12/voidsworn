extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# R398 (issue 1394). Ryan picked option B for the acid (melt) death on Nov 21 2026: "B but why is there smoke and haze?",
# then "No vapour. The whole hull shouldn't glow green either. Just specific affected areas". A box cruiser and a box
# frigate (Hegemony, and an Eclipse cruiser, whose own death is the violet peel) are hit by acid at one recorded spot and
# killed with cause "melt". Each must:
#   - die in the acid's look whatever its faction (death style "melt", no Eclipse peel, no strain crack, no tear overlay);
#   - glow only where the acid hit: every mesh carries the MELT_GLOW overlay, its first spot is the acid hit, and its
#     radius is a small part of the hull (not the whole hull);
#   - draw no smoke, haze or vapour (no "cool", "vent" or "impact" picture);
#   - still play the faction's own cook-off flash as it breaks, in the faction's colours, never a green one (Ryan, Nov 22
#     5:39 AM CT: "it might still be good to have the faction specific explosion when it breaks off").
# The same hull killed by a plain blast is the control: it must draw smoke and a hard flash, so the probe can see them.
const FX := preload("res://fx/fx.gd")
const SH := preload("res://fx/fx_shaders.gd")
const DEATH := preload("res://fx/fx_death.gd")
const HAZE := ["cool", "vent", "impact"]
const POOLS := preload("res://fx/fx_pool.gd")
const ACID_SPARK := Vector3(0.55, 0.65, 0.12)


# Neon on PR 1646: records every streak's colour as the pool flushes it, so a green cook-off spark is seen.
class SpyPool extends POOLS.Pool:
	var cols: Array = []
	func flush() -> void:
		var rec: int = POOLS.STRIDE * vpp
		for r in n_pending:
			cols.append(Vector3(pending[r * rec + 12], pending[r * rec + 13], pending[r * rec + 14]))
		super.flush()
var failures := 0


func _init() -> void:
	GUARD.arm(self, "melt_death_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + why)
	if not ok:
		failures += 1
		push_error(why)


func _run() -> void:
	for c in [["hegemony", "Cruiser"], ["deathless", "Cruiser"], ["hegemony", "Frigate"]]:
		var tag := "%s %s" % c
		var m := await _kill(c[0], c[1], "melt")
		var b := await _kill(c[0], c[1], "blast")
		print("MELT %s melt %s | blast %s" % [tag, JSON.stringify(m), JSON.stringify(b)])
		check(m["style"] == "melt", "%s: dies in the acid's look (style %s)" % [tag, m["style"]])
		check(not m["strain"], "%s: no strain crack" % tag)
		check(m["overlay"] == "melt" and m["overlay_all"], "%s: every mesh glows with the melt overlay, no tear (%s)" % [tag, m["overlay"]])
		check(m["spot_err"] < 0.01, "%s: the glow sits on the acid hit (off by %.3f)" % [tag, m["spot_err"]])
		check(m["radius_L"] > 0.0 and m["radius_L"] <= 0.3, "%s: only the hit area glows (radius %.2f of the length)" % [tag, m["radius_L"]])
		check(int(m["haze"]) == 0, "%s: no smoke, haze or vapour (%d pictures; blast drew %d)" % [tag, m["haze"], b["haze"]])
		check(int(m["flash"]) > 0, "%s: the faction's own cook-off flash still plays as it breaks (%d; blast drew %d)" % [tag, m["flash"], b["flash"]])
		check(int(m["green_spark"]) == 0, "%s: no acid-green cook-off sparks (%d)" % [tag, m["green_spark"]])
		check(int(m["green_light"]) == 0, "%s: the cook-off lights the hulls in the faction's colours, never acid green (%d green light frames)" % [tag, m["green_light"]])
		check(int(m["green_flash"]) == 0, "%s: the cook-off is in the faction's colours, never the acid green (%d green)" % [tag, m["green_flash"]])
		check(int(b["haze"]) > 0, "%s control: a blast death's smoke is seen by this probe (%d)" % [tag, b["haze"]])
		check(b["style"] != "melt" and b["overlay"] != "melt", "%s control: a blast death keeps its own look" % tag)
	var late := await _kill("hegemony", "Cruiser", "melt", 20.0)
	check(late["spot_err"] < 0.01, "an acid burn tick kill 20 s after the volley still glows on the acid hit, not the later hit (off by %.3f)" % late["spot_err"])
	var spots := await _acid_volley()
	check(spots >= 1, "a spine volley's hull hits are kept as the target's acid spots (%d)" % spots)
	print("MELT_DEATH %s, %d failures" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)


func _kill(faction: String, cls: String, cause: String, acid_age := 0.0) -> Dictionary:
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.position = Vector3(0, 30, 40)
	cam.look_at(Vector3.ZERO)
	var holder := Node3D.new()
	world.add_child(holder)
	for k in 2:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(10, 4, 6)
		box.subdivide_width = 9
		box.subdivide_height = 3
		box.subdivide_depth = 5
		mi.mesh = box
		mi.position = Vector3(-5.0 + 10.0 * k, 0, 0)
		mi.set_surface_override_material(0, StandardMaterial3D.new())
		holder.add_child(mi)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "camera": cam, "shake": 0.0})
	var quad := PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP, Vector3.ONE])
	var spy := SpyPool.new(4096, StandardMaterial3D.new(), world, "spy_stk", [quad, PackedVector3Array(), PackedInt32Array([0, 1, 2, 2, 1, 3])])
	fx.pools["stk"] = spy
	fx.add_ship("k", holder, {"faction": faction, "cls": cls, "size": 1.0})
	var s = fx.ship("k")
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 60000:
		fx.step(1.0 / 60.0)
		await process_frame
		if (s.get_meta("cut_job", {}) as Dictionary).get("built", false): break
	# the acid hit, recorded the way fx_weapons records one, on the bow's flank
	var spot := Vector3(s.hull.box.position.x + s.hull.L * 0.8, s.hull.c.y, s.hull.box.end.z)
	if cause == "melt": s.set_meta("acid_spots", [[spot, fx.now - acid_age]])
	# a later non-acid hit on the other flank: a fresh acid hit wins over it, and so does a stale one (an acid tick kill)
	s.set_meta("last_hit", [Vector3(s.hull.box.position.x + s.hull.L * 0.2, s.hull.c.y, s.hull.box.position.z), Vector3.FORWARD, fx.now])
	var before := {}
	for n in _pics(world): before[n.get_instance_id()] = float((n as MeshInstance3D).material_override.get_shader_parameter("born")) if (n as MeshInstance3D).material_override is ShaderMaterial else 0.0
	fx.death("k", cause)
	var res := {"style": str(DEATH.dstyle(s).get("style", "")), "strain": s.has_meta("death_strain"), "overlay": "none", "overlay_all": true,
		"spot_err": INF, "radius_L": 0.0, "haze": 0, "hard": 0, "flash": 0, "green_flash": 0, "green_light": 0, "green_spark": 0}
	var first := true
	for mm in s.meshes:
		var ov = (mm as MeshInstance3D).material_overlay
		var kind := "none"
		if ov is ShaderMaterial and (ov as ShaderMaterial).shader != null:
			var code: String = (ov as ShaderMaterial).shader.code
			kind = "melt" if code.contains("uniform vec4 spots[6]") else ("tear" if code.contains("uniform vec2 open_a") else "other")
			if kind == "melt" and first:
				var sp: PackedVector4Array = ov.get_shader_parameter("spots")
				if sp.size() > 0 and int(ov.get_shader_parameter("n_spots")) > 0:
					res["spot_err"] = Vector3(sp[0].x, sp[0].y, sp[0].z).distance_to(spot)
					res["radius_L"] = sp[0].w / s.hull.L
				first = false
		if res["overlay"] == "none": res["overlay"] = kind
		elif res["overlay"] != kind: res["overlay_all"] = false
		if kind != "melt": res["overlay_all"] = false
	var seen := {}
	for i in 5 * 60:
		fx.step(1.0 / 60.0)
		await process_frame
		for e in fx._lev:
			var lc: Color = e[4]
			for g in [Vector3(0.55, 0.65, 0.12), Vector3(0.70, 0.85, 0.45), Vector3(0.45, 0.62, 0.10)]:
				if Vector3(lc.r, lc.g, lc.b).distance_to(g) < 0.03: res["green_light"] += 1
		for n in _pics(world):
			var mi := n as MeshInstance3D
			if not mi.visible or not (mi.material_override is ShaderMaterial): continue
			var born := float(mi.material_override.get_shader_parameter("born"))
			var key := "%d|%.4f" % [mi.get_instance_id(), born]
			if seen.has(key) or (before.has(mi.get_instance_id()) and is_equal_approx(float(before[mi.get_instance_id()]), born)): continue
			seen[key] = true
			var kind := str(mi.get_meta("fx_picture_kind", ""))
			if kind in HAZE: res["haze"] += 1
			if kind == "flash":
				res["flash"] += 1
				var ff = mi.material_override.get_shader_parameter("fac_fire")
				if ff is Color and (ff as Color).a > 0.5 and Vector3(ff.r, ff.g, ff.b).distance_to(Vector3(0.80, 0.95, 0.55)) < 0.05: res["green_flash"] += 1
			if kind == "flash" and float(mi.material_override.get_shader_parameter("soft_flash")) < 0.5: res["hard"] += 1
	for c in spy.cols:
		if (c as Vector3).distance_to(ACID_SPARK) < 0.03: res["green_spark"] += 1
	world.queue_free()
	await process_frame
	return res


# fx_weapons keeps each bio hull hit (spine, tendril, spore bomb) on its target as "acid_spots", in the hull's frame.
func _acid_volley() -> int:
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.position = Vector3(0, 40, 60)
	cam.look_at(Vector3.ZERO)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "camera": cam, "shake": 0.0})
	for id in ["A", "T"]:
		var holder := Node3D.new()
		world.add_child(holder)
		holder.position = Vector3(-30 if id == "A" else 30, 0, 0)
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(12, 4, 6)
		mi.mesh = box
		mi.set_surface_override_material(0, StandardMaterial3D.new())
		holder.add_child(mi)
		fx.add_ship(id, holder, {"faction": "chorus" if id == "A" else "hegemony", "cls": "Cruiser", "size": 1.0})
	fx.volley("A", "bio", "T", {"weapon_id": "bioplasma", "shots": [true, true], "hits": [{"shield": 0, "hull": 1}, {"shield": 0, "hull": 1}]})
	for i in 4 * 60:
		fx.step(1.0 / 60.0)
		await process_frame
	var t = fx.ship("T")
	var n: int = (t.get_meta("acid_spots", []) as Array).size()
	for sp in t.get_meta("acid_spots", []):
		var box: AABB = t.hull.box.grow(t.hull.L * 0.2)
		check(box.has_point(sp[0]), "an acid spot lies on the target's hull (%s)" % str(sp[0]))
	world.queue_free()
	await process_frame
	return n


func _pics(n: Node) -> Array:
	var out := []
	for c in n.find_children("*", "MeshInstance3D", true, false):
		if c.has_meta("fx_picture_kind"): out.append(c)
	return out
