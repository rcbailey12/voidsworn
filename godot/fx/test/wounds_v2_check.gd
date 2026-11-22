extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# R416 (issue 1741), Wounds V2 Milestones 1, 2 and 4, on box stand-ins:
# 1. switch off (VS_WOUNDS_V2=0) keeps the old wounds: no V2 entries, no V2 shader looks, prism keeps its shell crater
# 2. the 8-ray footprint check shrinks or slides a cutout on a narrow plank (an Eclipse shade ring arc stand-in) so its
#    rim sits on plating, and a plate thinner than 0.4 R chips (thin_shear) instead of opening a cavity
# 3. normal gating: a V2 overlay never lands on a face turned away from the hit (the far side of a ring arc)
# 4. an authored-interior hull opens a real cutout at stage 2 and its interior surfaces are never cut; an older hollow
#    hull stays sealed until stage 4; the cutout caps hold (6 per ship, 2 per section)
# 5. the V2 shaders parse (INTERIOR, HOLE, MARK, the hull damage shader); each faction's mouth dressing is its own kind
#    and stays below the plating; faction colours: no magenta on the Chorus, no green on Eclipse, no soot on the
#    Chorus, Glasswrights or Eclipse
# 6. prism, star and null lance leave their own marks (S_PRISM, S_STAR, S_NLANCE)
# 8. a dead ship's inside keeps the faction interior shader (never the matte black wreck copy) with V2 on
# and: an opened V2 ship lights at most two soft inside lights in its interior accent; the interior shader goes on the
# built interior once a mouth is open
const FX := preload("res://fx/fx.gd")
const BREACH := preload("res://fx/fx_breach.gd")
const HULL := preload("res://fx/fx_hull.gd")
const SH := preload("res://fx/fx_shaders.gd")
const WOUNDS := preload("res://fx/fx_wounds_flag.gd")
const FL := preload("res://fx/faction_look.gd")
var failures := 0
var fx
var world: Node3D
var nship := 0


func _init() -> void:
	GUARD.arm(self, "wounds_v2_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("  ok: ", message)


static func _box_faces(size: Vector3, at := Vector3.ZERO) -> PackedVector3Array:
	var bm := BoxMesh.new()
	bm.size = size
	var arr: Array = bm.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var out := PackedVector3Array()
	for i in idx:
		out.append(v[i] + at)
	return out


func _hull_of(faces: PackedVector3Array, L: float):
	var h = HULL.new()
	var tm := TriangleMesh.new()
	tm.create_from_faces(faces)
	h.tm = tm
	h.L = L
	return h


# A box ship; authored: a second, inner surface flagged as built interior, and the hull marked authored.
func _ship(faction: String, authored: bool):
	nship += 1
	var body := Node3D.new()
	world.add_child(body)
	body.position = Vector3(nship * 40.0, 0, 0)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(24, 5, 8)
	bm.subdivide_width = 17
	bm.subdivide_depth = 5
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bm.get_mesh_arrays())
	am.surface_set_material(0, StandardMaterial3D.new())
	if authored:
		var ib := BoxMesh.new()
		ib.size = Vector3(20, 0.3, 6)
		ib.subdivide_width = 9
		var ia: Array = ib.get_mesh_arrays()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ia)
		var im := StandardMaterial3D.new()
		im.resource_name = "deck_interior"
		im.albedo_color = Color(0.02, 0.02, 0.02)
		im.set_meta("fx_authored_interior", true)
		am.surface_set_material(1, im)
	mi.mesh = am
	body.add_child(mi)
	var sid := "v2_%s_%d" % [faction, nship]
	fx.add_ship(sid, body, {"faction": faction, "cls": "Cruiser", "size": 0.8, "meshes": [mi], "shielded": false})
	fx._later.clear()
	var s = fx.ship(sid)
	s.hull.authored = authored
	for i in 3:
		s._anchors["a%d" % i] = {"p": Vector3((i - 1) * 7, 2.5, 0), "n": Vector3.UP, "t": {}}
		s._anchors["b%d" % i] = {"p": Vector3((i - 1) * 7 + 2.0, 2.5, 2.0), "n": Vector3.UP, "t": {}}
	return s


func _state(eng: float, mid: float, prow: float) -> Dictionary:
	return {"hp": (eng + mid + prow) / 3.0, "maxHp": 100.0, "sec": {"eng": {"hp": eng, "max": 100}, "mid": {"hp": mid, "max": 100}, "prow": {"hp": prow, "max": 100}}}


func flush(s) -> void:
	for i in 5:
		if s._dmg_task >= 0:
			s.flush_damage(fx)
		fx.step(0.05)


func _holes(s) -> Array:
	var out: Array = []
	for i in 3:
		for e in s._ents[i]:
			if e.has_cut():
				out.append(e)
	for e in s._marks:
		if e.has_cut():
			out.append(e)
	return out


func _lights(s) -> Array:
	var out: Array = []
	for src in fx._lsrc:
		if bool(src["on"]) and is_instance_valid(src["node"]) and s._dmg_root.is_ancestor_of(src["node"]):
			out.append(src)
	return out


func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})

	# 1. switch off: the old wounds
	OS.set_environment("VS_WOUNDS_V2", "0")
	var s0 = _ship("ithar", true)
	s0.sync(fx, _state(100, 10, 100))
	flush(s0)
	var any_v2 := false
	for i in 3:
		for e in s0._ents[i]:
			any_v2 = any_v2 or e.v2 >= 0 or e.thin_shear or e.facets > 0
	check(not any_v2, "switch off: no entry carries a V2 field")
	var off_mats := true
	for key in s0._damage_surfaces:
		var m: ShaderMaterial = s0._damage_surfaces[key][1]
		off_mats = off_mats and int(m.get_shader_parameter("fx_v2")) == -1
	check(off_mats, "switch off: every hull damage surface keeps fx_v2 at -1 (the old look)")
	var hole_off := true
	for n in s0._hole_nodes:
		if n is MeshInstance3D and (n as MeshInstance3D).material_override is ShaderMaterial:
			var wv = ((n as MeshInstance3D).material_override as ShaderMaterial).get_shader_parameter("wound_v2")
			hole_off = hole_off and (wv == null or int(wv) == -1)
	check(hole_off, "switch off: the hole and mark shaders keep wound_v2 off")
	check(_lights(s0).is_empty(), "switch off: no V2 inside lights")
	var hl = s0.hull
	var pm: Array = BREACH.marks_for(hl, "prism", 2, Vector3(0, 2.5, 0), Vector3.UP, Vector3.DOWN, 1.0, "voidsworn")
	check(pm.size() == 1 and pm[0].style == BREACH.S_SHELL, "switch off: prism keeps its shell crater")
	var interior_kept := true
	for m in s0.meshes:
		var mi0 := m as MeshInstance3D
		if mi0 != null and mi0.get_surface_override_material_count() > 1:
			interior_kept = interior_kept and not (mi0.get_surface_override_material(1) is ShaderMaterial and (mi0.get_surface_override_material(1) as ShaderMaterial).shader.code == SH.INTERIOR)
	check(interior_kept, "switch off: the built interior keeps its own material")

	OS.set_environment("VS_WOUNDS_V2", "1")
	# 2. footprint: a narrow plank 0.3 thick and 2 wide (a shade ring arc stand-in)
	var plank = _hull_of(_box_faces(Vector3(24, 0.3, 2.0)), 24.0)
	var fp := BREACH.validate_footprint(plank, Vector3(0, 0.15, 0.7), Vector3.UP, 1.2)
	check(bool(fp["ok"]) and float(fp["R"]) < 1.2 and int(fp["valid"]) >= BREACH.FOOT_MIN, "footprint: a cutout off the plank's edge shrinks to fit (R %.2f, %d rays)" % [float(fp["R"]), int(fp["valid"])])
	var ring_ok := true
	if bool(fp["ok"]):
		var c: Vector3 = fp["c"]
		for k in 8:
			var an := TAU * k / 8.0
			var q: Vector3 = c + Vector3(cos(an), 0, sin(an)) * float(fp["R"]) * 0.85
			ring_ok = ring_ok and absf(q.z) <= 1.0 + 1e-3 and absf(q.x) <= 12.0
	check(ring_ok, "footprint: the shrunk rim sits on the plank (no part off the hull)")
	check(bool(fp["thin"]), "footprint: a plate under 0.4 R thick is thin")
	var e_thin = BREACH.place_hole(plank, Vector3(0, 0.15, 0), Vector3.UP, 0.8, 1.0, "deathless")
	check(e_thin.has_cut() and e_thin.thin_shear and e_thin.cut < 0.3 and e_thin.v2 == 5, "footprint: the thin plate chips (thin_shear, cut %.2f under its 0.3 thickness)" % e_thin.cut)
	var e_none = BREACH.place_hole(plank, Vector3(0, 0.15, 3.5), Vector3.UP, 1.0, 1.0, "deathless")
	check(not e_none.has_cut(), "footprint: no plating under it at all gives a small surface mark, never a hole over space")
	var slab = _hull_of(_box_faces(Vector3(24, 6, 8)), 24.0)
	var e_ok = BREACH.place_hole(slab, Vector3(0, 3, 0), Vector3.UP, 0.8, 1.0, "voidsworn")
	check(e_ok.has_cut() and not e_ok.thin_shear and e_ok.th >= 24.0 * 0.008 - 1e-4 and e_ok.th <= 0.8 * 0.24 + 1e-4, "rims: a thick hull cuts with a real plate thickness (th %.3f)" % e_ok.th)

	# 3. normal gating
	var E = BREACH.crater(Vector3(0, 0.15, 0), Vector3.UP, 0.5, 0.05, 1.0, BREACH.S_SHELL)
	E.ov = 1.2
	var a := Vector3(-0.2, -0.15, -0.2)
	var b := Vector3(0.2, -0.15, -0.2)
	var cc := Vector3(0.0, -0.15, 0.25)
	var Q := (a + b + cc) / 3.0
	check(BREACH._tri_in_overlay(a, b, cc, Q, E, Vector3.DOWN * 3.0), "normal gating off: the old overlay reaches the plank's underside")
	E.v2 = 5
	check(not BREACH._tri_in_overlay(a, b, cc, Q, E, Vector3.DOWN * 3.0), "normal gating: a V2 overlay never lands on the face turned away")
	check(BREACH._tri_in_overlay(a + Vector3.UP * 0.3, b + Vector3.UP * 0.3, cc + Vector3.UP * 0.3, Q + Vector3.UP * 0.3, E, Vector3.UP * 3.0), "normal gating: the hit face still takes it")

	# 4. mid-battle cutouts on an authored hull, sealed legacy hull
	for faction in ["voidsworn", "hegemony", "corsair", "chorus", "ithar", "deathless"]:
		var s = _ship(faction, true)
		s.sync(fx, _state(100, 100, 100))
		flush(s)
		check(_holes(s).is_empty() and _lights(s).is_empty(), "%s: a healthy authored hull has no cutout and no inside light" % faction)
		s.sync(fx, _state(100, 50, 100))
		flush(s)
		var hs := _holes(s)
		var kind := int(FL.of(faction)["wound"]["kind"])
		check(hs.size() >= 1 and hs[0].v2 == kind, "%s: stage 2 (50%% section HP) opens a V2 cutout (kind %d)" % [faction, kind])
		var job: Dictionary = s._dmg_job
		var cut_interior := false
		var surfs: Array = job.get("surfs", [])
		var outs: Array = job.get("out", {}).get("surfs", [])
		for k in surfs.size():
			if bool(surfs[k].get("interior", false)) and k < outs.size() and outs[k] != null:
				cut_interior = true
		check(not surfs.is_empty() and not cut_interior, "%s: the built interior is never cut" % faction)
		var ls := _lights(s)
		var acc := BREACH.wound_col(FL.of(faction)["wound"], "interior_accent", Color.BLACK)
		var l_ok := ls.size() >= 1 and ls.size() <= BREACH.INSIDE_LIGHTS
		for src in ls:
			l_ok = l_ok and (src["col"] as Color).is_equal_approx(acc) and float(src["reach"]) > 0.0
		check(l_ok, "%s: the open cutout lights its inside softly in the faction accent (%d lights)" % [faction, ls.size()])
		var int_ok := false
		for m in s.meshes:
			var mi1 := m as MeshInstance3D
			if mi1 != null and mi1.get_surface_override_material_count() > 1 and mi1.get_surface_override_material(1) is ShaderMaterial:
				var im: ShaderMaterial = mi1.get_surface_override_material(1)
				int_ok = im.shader.code == SH.INTERIOR and int(im.get_shader_parameter("wound_v2")) == kind and int(im.get_shader_parameter("fx_mouth_count")) >= 1
		check(int_ok, "%s: the built interior takes the faction interior shader once open" % faction)
		var v2_ok := true
		for key in s._damage_surfaces:
			v2_ok = v2_ok and int((s._damage_surfaces[key][1] as ShaderMaterial).get_shader_parameter("fx_v2")) == kind
		check(v2_ok, "%s: the hull damage surfaces carry the faction's V2 kind" % faction)
		# heavy hits: cap 2 per section, 6 per ship
		s.sync(fx, _state(30, 30, 30))
		flush(s)
		for j in 12:
			s.add_mark(fx, "torp", 3, Vector3(-9.0 + j * 1.6, 2.5, -1.5 + (j % 3) * 1.5), Vector3.UP, Vector3.DOWN)
		flush(s)
		var per := [0, 0, 0]
		for e in _holes(s):
			if e.v2 >= 0:
				per[clampi(e.sec, 0, 2)] += 1
		check(per[0] + per[1] + per[2] <= BREACH.V2_HOLES_SHIP and per.max() <= BREACH.V2_HOLES_SEC, "%s: cutouts capped (%s per section)" % [faction, str(per)])
		check(_lights(s).size() <= BREACH.INSIDE_LIGHTS, "%s: still at most %d inside lights" % [faction, BREACH.INSIDE_LIGHTS])
		# Artoo on PR 1755: impact cutouts first, then a stage rise: the caps hold over what the rebuild draws
		var s2 = _ship(faction, true)
		s2.sync(fx, _state(70, 70, 70))
		flush(s2)
		for j in 6:
			s2.add_mark(fx, "torp", 3, Vector3(-9.0 + j * 3.4, 2.5, -1.0 + (j % 2) * 2.0), Vector3.UP, Vector3.DOWN)
		flush(s2)
		s2.sync(fx, _state(8, 8, 8))
		flush(s2)
		var per2 := [0, 0, 0]
		for e in s2._dmg_job.get("ents", []):
			if e.has_cut() and e.v2 >= 0:
				per2[clampi(e.sec, 0, 2)] += 1
		check(per2[0] + per2[1] + per2[2] <= BREACH.V2_HOLES_SHIP and per2.max() <= BREACH.V2_HOLES_SEC, "%s: hits then a stage rise still keep the caps in what is drawn (%s)" % [faction, str(per2)])
	var sl = _ship("voidsworn", false)
	sl.sync(fx, _state(100, 30, 100))
	flush(sl)
	check(_holes(sl).is_empty(), "a legacy hollow hull stays sealed at stage 3")

	# 5. shaders parse; dressing per faction stays below the plating; faction colours
	for pair in [["INTERIOR", SH.INTERIOR], ["HOLE", SH.HOLE], ["MARK", SH.MARK]]:
		var sh := Shader.new()
		sh.code = pair[1]
		var names: Array = []
		for u in sh.get_shader_uniform_list():
			names.append(u["name"])
		check(names.has("wound_v2"), "%s parses with its V2 uniforms" % pair[0])
	var dm := HULL.damage_material(StandardMaterial3D.new(), Transform3D.IDENTITY, {"count": 0}, 24.0)
	var dn: Array = []
	for u in dm.shader.get_shader_uniform_list():
		dn.append(u["name"])
	check(dn.has("fx_v2") and dn.has("fx_v2_soot"), "the hull damage shader parses with its V2 uniforms")
	var want_b := {0: 0.25, 1: 0.25, 2: 0.25, 3: 0.5, 4: 0.75, 5: 1.0}
	for faction in ["voidsworn", "hegemony", "corsair", "chorus", "ithar", "deathless"]:
		var eh = BREACH.place_hole(slab, Vector3(0, 3, 0), Vector3.UP, 1.0, 2.0, faction)
		var pt = BREACH.Part.new()
		var r := RandomNumberGenerator.new()
		r.seed = 5
		BREACH.dress(slab, pt, eh, r)
		var has_b := false
		var below := true
		for k in pt.pos.size():
			var v: Vector3 = pt.pos[k]
			below = below and (v - eh.c).dot(eh.n) <= 1e-3 and Vector2(v.x - eh.c.x, v.z - eh.c.z).length() <= eh.R * 1.6
			has_b = has_b or is_equal_approx(pt.col[k].b, float(want_b[eh.v2]))
		check(not pt.pos.is_empty() and has_b, "%s: the mouth dressing is the faction's own (kind %d)" % [faction, eh.v2])
		check(below, "%s: the mouth dressing stays below the plating and inside the rim" % faction)
	for faction in ["chorus", "ithar", "deathless"]:
		check(float(FL.of(faction)["wound"]["soot_weight"]) == 0.0, "%s: no soot" % faction)
	# R420 (global cohesion law 2): an open wound's inside sits under the interior ceiling, glow capped
	for faction in ["voidsworn", "hegemony", "corsair", "chorus", "ithar", "deathless"]:
		var lift: Array = FL.of(faction)["wound"]["interior_lift"]
		var mean := (float(lift[0]) + float(lift[1]) + float(lift[2])) / 3.0
		check(float(lift.max()) <= 0.11 and mean >= 0.025 and mean <= 0.10, "%s: wound interior lift within the R420 ceiling (mean %.3f)" % [faction, mean])
	check(SH.INTERIOR.contains("lit = min(lit, vec3(0.11))") and SH.INTERIOR.contains("vec3(0.25));"), "R420: the interior shader clamps walls to 0.11 and non-core glow to 0.25")
	var ch: Dictionary = FL.of("chorus")["wound"]
	var mag := false
	for key in ["scorch_col", "rim_metal", "interior_lift", "interior_accent"]:
		var c: Array = ch[key]
		mag = mag or (float(c[0]) > 0.2 and float(c[2]) > 0.2 and float(c[1]) < 0.6 * minf(float(c[0]), float(c[2])))
	check(not mag, "chorus: no magenta in its wound colours")
	var dl: Dictionary = FL.of("deathless")["wound"]
	var green := false
	for key in ["scorch_col", "rim_metal", "interior_lift", "interior_accent"]:
		var c: Array = dl[key]
		green = green or (float(c[1]) > float(c[0]) and float(c[1]) > float(c[2]))
	check(not green, "eclipse: no green in its wound colours")
	# the Chorus V2 branches in MARK, HOLE and INTERIOR use no magenta colour literal (red and blue both over 0.2, green
	# well under both) (audit on PR 1755: the old check could not fail)
	var mag_lits: Array = []
	var re := RegEx.create_from_string("vec3\\(([0-9.]+), ([0-9.]+), ([0-9.]+)\\)")
	for code in [SH.MARK, SH.HOLE, SH.INTERIOR]:
		var at: int = (code as String).find("wound_v2 == 3")
		while at >= 0:
			var chunk: String = (code as String).substr(at, 900)
			for m in re.search_all(chunk):
				var r0 := float(m.get_string(1)); var g0 := float(m.get_string(2)); var b0 := float(m.get_string(3))
				if r0 > 0.2 and b0 > 0.2 and g0 < 0.6 * minf(r0, b0):
					mag_lits.append(m.get_string())
			at = (code as String).find("wound_v2 == 3", at + 1)
	check(mag_lits.is_empty(), "chorus: no magenta colour in its V2 shader branches %s" % str(mag_lits))

	# 6. the folded 1692 (d) marks
	var mp: Array = BREACH.marks_for(hl, "prism", 2, Vector3(0, 2.5, 0), Vector3.UP, Vector3.DOWN, 1.0, "voidsworn")
	var ms: Array = BREACH.marks_for(hl, "star", 3, Vector3(0, 2.5, 0), Vector3.UP, Vector3.DOWN, 1.0, "voidsworn")
	var mn: Array = BREACH.marks_for(hl, "nlance", 3, Vector3(0, 2.5, 0), Vector3.UP, Vector3(0, -1, 0.3), 1.0, "voidsworn")
	check(mp.size() == 1 and mp[0].style == BREACH.S_PRISM, "prism leaves its crystal star fracture (S_PRISM)")
	check(ms.size() == 1 and ms[0].style == BREACH.S_STAR, "star leaves its white-gold sear (S_STAR)")
	var n_ok := mn.size() == 3
	for e in mn:
		n_ok = n_ok and e.style == BREACH.S_NLANCE and e.kind == BREACH.K_SLOT
	check(n_ok, "null lance leaves three parallel cuts (S_NLANCE)")

	# 8. live to wreck, through the game's own death (audit on PR 1755: fx_death threads the faction and length)
	fx.death_story = true
	for faction in ["chorus", "ithar"]:
		var sd = _ship(faction, true)
		sd.sync(fx, _state(20, 15, 20))
		flush(sd)
		fx.death(sd.id, "blast")
		var found := 0
		for k in 240:
			fx.step(0.05)
			for w in fx.dstate.get("wrecks", []):
				if w["id"] != sd.id: continue
				for nd in w["nodes"]:
					if not is_instance_valid(nd): continue
					for mi in (nd as Node3D).find_children("*", "MeshInstance3D", true, false):
						var m: Mesh = (mi as MeshInstance3D).mesh
						for j in (m.get_surface_count() if m != null else 0):
							var sm = m.surface_get_material(j)
							if sm is ShaderMaterial and (sm as ShaderMaterial).shader.code == SH.INTERIOR and float(sm.get_shader_parameter("fx_wreck")) == 1.0:
								found += 1
			if found > 0:
				break
		check(found > 0, "%s: the wreck pieces from a real death carry the faction interior shader (%d surfaces)" % [faction, found])
	# 8b. the cache helper alone
	var src := StandardMaterial3D.new()
	src.set_meta("fx_authored_interior", true)
	for faction in ["ithar", "chorus"]:
		var wm = fx.wreck_interior(src, faction, 24.0)
		check(wm is ShaderMaterial and (wm as ShaderMaterial).shader.code == SH.INTERIOR and float((wm as ShaderMaterial).get_shader_parameter("fx_wreck")) == 1.0, "%s: the wreck keeps the faction interior shader" % faction)
	OS.set_environment("VS_WOUNDS_V2", "0")
	var old = fx.wreck_interior(src, "ithar", 24.0)
	check(old is BaseMaterial3D and (old as BaseMaterial3D).roughness == 1.0, "switch off: the wreck keeps the old sooted copy")
	OS.unset_environment("VS_WOUNDS_V2")
	print("wounds_v2_check: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
