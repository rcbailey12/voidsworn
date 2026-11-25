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
const DEATH := preload("res://fx/fx_death.gd")
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
func _ship(faction: String, authored: bool, shielded := false, separate_deck := false):
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
		if faction == "ithar": im.set_meta("interior_role", "wall")  # use the dark baked trim, not the legacy fallback
		am.surface_set_material(1, im)
	mi.mesh = am
	body.add_child(mi)
	var meshes: Array = [mi]
	if separate_deck:
		var deck := MeshInstance3D.new()
		var deck_mesh := ArrayMesh.new()
		deck_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, am.surface_get_arrays(1))
		deck_mesh.surface_set_material(0, am.surface_get_material(1))
		deck.mesh = deck_mesh
		deck.position.y = -0.2
		deck.lod_bias = 0.75
		body.add_child(deck)
		meshes.append(deck)
	var sid := "v2_%s_%d" % [faction, nship]
	fx.add_ship(sid, body, {"faction": faction, "cls": "Cruiser", "size": 0.8, "meshes": meshes, "shielded": shielded})
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


func _half_hull_openings() -> void:
	for faction in ["voidsworn", "corsair", "deathless", "ithar"]:
		var s = _ship(faction, true)
		s.sync(fx, _state(50, 50, 50))
		flush(s)
		var mi: MeshInstance3D = s.meshes[0]
		var hull_tris := TriangleMesh.new()
		hull_tris.create_from_faces(mi.mesh.get_faces())
		var real_opening := false
		for e: BREACH.Ent in s._dmg_job["ents"]:
			if not e.has_cut() or e.thin_shear:
				continue
			# The rebuilt skin has a gap at the cut, and a deck further in. A surface mark cannot pass this.
			var ray := hull_tris.intersect_segment(e.c + e.n * e.R, e.c - e.n * 3.0)
			if not ray.is_empty() and (e.c - (ray["position"] as Vector3)).dot(e.n) > e.R * 0.3:
				real_opening = true
				if faction == "ithar": _glass_mouth_check(s, e, ray["position"])
				break
		check(real_opening, "%s: at 50%% hull the rebuilt skin opens onto its real deck" % faction)
		fx.remove_ship(s.id)


func _glass_mouth_check(s, e: BREACH.Ent, deck_point: Vector3) -> void:
	var job: Dictionary = s._dmg_job
	var part = job["out"]["parts"][job["ents"].find(e)]
	var seams := [0, 0]
	var radii := [0.0, 0.0]
	var rim := false
	var clear := true
	var depth: float = minf(e.cut * 0.88, e.R * 0.9)
	for k in range(0, part.pos.size(), 3):
		var a: Vector3 = part.pos[k]
		var b: Vector3 = part.pos[k + 1]
		var c: Vector3 = part.pos[k + 2]
		var col: Color = part.col[k]
		var d: Vector3 = (a + b + c) / 3.0 - e.c
		var down: float = -d.dot(e.n)
		var r: float = (d + e.n * down).length() / e.R
		if is_equal_approx(col.b, BREACH.GLASS_SEAM):
			var layer := 0 if down < depth * 0.75 else 1
			seams[layer] += 1
			radii[layer] += r
		rim = rim or (is_equal_approx(col.r, BREACH.PART_LIP) and is_equal_approx(col.b, 0.75))
		for direction in [Vector3.ZERO, e.t1, -e.t1, e.t2, -e.t2]:
			var centre: Vector3 = e.c + direction * e.R * 0.22
			clear = clear and Geometry3D.segment_intersects_triangle(centre + e.n * e.R, centre - e.n * e.cut, a, b, c) == null
	check(seams.min() >= e.facets and radii[0] / maxf(seams[0], 1) > radii[1] / maxf(seams[1], 1) + 0.17 and rim,
		"2125: Glasswright opening has a fractured rim and two lit seam bands stepping inward (%s triangles)" % str(seams))
	check(clear, "2125: five rays through the Glasswright centre miss all synthetic dressing")
	var mi: MeshInstance3D = s.meshes[0]
	var interior := mi.get_surface_override_material(1) as ShaderMaterial
	# Headless does not shade pixels. Use the actual deck hit and the live shader's bounds to check the pearl floor.
	var floor_re := RegEx.create_from_string("glass_pearl = v2_interior_lift \\* \\(([0-9.]+) \\+ [0-9.]+ \\* r.x\\);")
	var reveal_re := RegEx.create_from_string("fx_wreck == 0.0 \\? smoothstep\\(([0-9.]+), ([0-9.]+), open_f\\)")
	var code := interior.shader.code if interior != null else ""
	var floor_match := floor_re.search(code)
	var reveal_match := reveal_re.search(code)
	var lift: Vector3 = interior.get_shader_parameter("v2_interior_lift") if interior != null else Vector3.ZERO
	var open_f := 1.0 - smoothstep(1.4, 5.5, e.c.distance_to(deck_point) / e.R)
	var reveal := smoothstep(reveal_match.get_string(1).to_float(), reveal_match.get_string(2).to_float(), open_f) if reveal_match != null else 0.0
	var floor_value := lift.dot(Vector3.ONE) / 3.0 * float(floor_match.get_string(1)) * reveal * maxf(reveal, open_f) if floor_match != null else 0.0
	var hole_node := s._dmg_root.get_node_or_null("fx_damage_inside") as MeshInstance3D
	var hole := hole_node.material_override as ShaderMaterial if hole_node != null else null
	check(floor_value >= 0.08 and floor_value <= 0.16 and hole != null and is_equal_approx(float(interior.get_shader_parameter("v2_wall_max")), 0.45)
		and is_equal_approx(float(hole.get_shader_parameter("v2_wall_max")), 0.45)
		and bool(interior.get_shader_parameter("trusted")) and (interior.get_shader_parameter("base_albedo") as Color).r < 0.03
		and code.contains("lit = mix(lit, glass_pearl, glass_reveal);")
		and code.contains("em += glass_pearl * 0.08 * glass_reveal;"),
		"2175: centre ray hits a shaded pearl deck (%.3f linear), darker than both visible wall steps" % floor_value)


func _glass_layer_check() -> void:
	# Two close pearl layers above a recessed room. The first inward ray hits the second layer, not the room.
	var faces := _box_faces(Vector3(9.0, 0.01, 9.0), Vector3(0, -0.005, 0))
	faces.append_array(_box_faces(Vector3(9.0, 0.01, 9.0), Vector3(0, -0.255, 0)))
	faces.append_array(_box_faces(Vector3(9.0, 0.01, 9.0), Vector3(0, -2.005, 0)))
	var stack = _hull_of(faces, 24.0)
	var glass := BREACH.place_hole(stack, Vector3.ZERO, Vector3.UP, 1.1, 3.0, "ithar")
	check(glass.has_cut() and not glass.thin_shear and glass.cut > 0.26 and glass.cut < 2.0,
		"2175: the faceted cut opens through stacked shell layers without puncturing the room deck (depth %.3f)" % glass.cut)


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
		var s = _ship(faction, true, false, faction == "hegemony")
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
		if faction == "hegemony":
			var deck: MeshInstance3D = s.meshes[1]
			var deck_mat := deck.get_surface_override_material(0) as ShaderMaterial
			check(is_equal_approx(deck.lod_bias, 0.75) and deck_mat != null and deck_mat.shader.code == SH.INTERIOR,
				"2125: an interior-only mesh keeps its own LOD and still receives the V2 wound light")
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
		fx.remove_ship(s.id)   # one faction at a time, so the battle light cap below is tested on its own
		fx.remove_ship(s2.id)
	# Fable review M2: the battle cap on breach lights, across every ship
	var many: Array = []
	for j in 6:
		var sm = _ship(["voidsworn", "corsair", "deathless"][j % 3], true)
		sm.sync(fx, _state(30, 30, 30))
		flush(sm)
		many.append(sm)
	var lit_all := 0
	for sm in many:
		lit_all += _lights(sm).size()
	check(lit_all >= 1 and lit_all <= BREACH.BATTLE_HOLE_LIGHTS, "M2: six opened ships light %d breach lights in all (cap %d)" % [lit_all, BREACH.BATTLE_HOLE_LIGHTS])
	for sm in many:
		fx.remove_ship(sm.id)
	var sl = _ship("voidsworn", false)
	sl.sync(fx, _state(100, 30, 100))
	flush(sl)
	check(_holes(sl).is_empty(), "a legacy hollow hull stays sealed at stage 3")
	_glass_layer_check()
	_half_hull_openings()

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
	check(dm.shader.code.contains("(fx_v2 == 0 || fx_v2 == 2) ? smoothstep(0.65, 1.0, fx_sc) * step(0.95,") and dm.shader.code.contains("float fx_sw = clamp(fx_v2_soot, 0.0, 1.0);"), "JOINT_B: with V2 the scorch keeps the faction soot weight and only steel keeps sparse embers")
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
	for faction in ["hegemony", "chorus", "ithar", "deathless"]:
		check(float(FL.of(faction)["wound"]["soot_weight"]) == 0.0, "%s: no soot on wounds" % faction)
	for faction in ["hegemony", "chorus", "ithar"]:
		check(float(FL.of(faction)["wound"]["wreck_soot"]) == 0.0, "%s: no soot on wreck interiors" % faction)
	# R420 (global cohesion law 2): an open wound's inside sits under the interior ceiling, glow capped
	for faction in ["voidsworn", "hegemony", "corsair", "chorus", "ithar", "deathless"]:
		var lift: Array = FL.of(faction)["wound"]["interior_lift"]
		var mean := (float(lift[0]) + float(lift[1]) + float(lift[2])) / 3.0
		# Ryan Nov 24 (Glasswright interiors pick): Glasswright insides are pale pearl glass, ceiling 0.45; the rest 0.11
		var ceil_w: float = 0.45 if faction == "ithar" else 0.11
		var floor_w: float = 0.2 if faction == "ithar" else 0.025
		check(float(lift.max()) <= ceil_w and mean >= floor_w and mean <= ceil_w - 0.01, "%s: wound interior lift within its ceiling %.2f (mean %.3f)" % [faction, ceil_w, mean])
		# Artoo on 8361e0c8: the ceiling is asserted through the real material parameter, 0.45 exactly for the
		# Glasswrights and 0.11 for the rest; a built-interior table entry (1743) must agree with the wound profile
		var wmat := HULL.interior_material_v2(StandardMaterial3D.new(), Transform3D.IDENTITY, {}, BREACH.wound_of(faction), 24.0)
		var wm: float = float(wmat.get_shader_parameter("v2_wall_max"))
		var want_wm: float = 0.45 if faction == "ithar" else 0.11
		var iv = FL.of(faction).get("interior", {})
		var table_ok: bool = not (iv is Dictionary and (iv as Dictionary).has("wall_max")) or is_equal_approx(float(iv["wall_max"]), want_wm)
		check(is_equal_approx(wm, want_wm) and table_ok, "%s: the interior material's wall ceiling is %.2f (want %.2f; interior table agrees %s)" % [faction, wm, want_wm, str(table_ok)])
	check(SH.INTERIOR.contains("lit *= lm > v2_wall_max ? v2_wall_max / lm : 1.0;") and SH.INTERIOR.contains("uniform float v2_wall_max = 0.11;") and SH.INTERIOR.contains("soft *= pk > 0.25 ? 0.25 / pk : 1.0;"), "R420: the interior shader holds walls to the faction ceiling (0.11 default) and non-core glow to 0.25 by scaling the colour")
	check(not SH.INTERIOR.contains("vec3(0.09, 0.1, 0.1) * r.x"), "Ryan Nov 24: a Glasswright wreck's inside goes to pale frosted pearl, never dark grey")
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
	for faction in ["chorus", "ithar", "hegemony"]:
		var sd = _ship(faction, true)
		sd.sync(fx, _state(20, 15, 20))
		flush(sd)
		var death_request: float = fx.now
		fx.death(sd.id, "blast")
		var found := 0
		var timed := true
		var plating: Array = []
		for k in 600:
			fx.step(0.05)
			OS.delay_msec(10)   # the death cut runs on a worker thread: give it wall time, not only game time
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
								var stamp := float(sm.get_shader_parameter("fx_wreck_t0"))
								timed = timed and stamp >= death_request - 0.06 and stamp <= fx.now + 0.06
							elif sm is ShaderMaterial and (sm as ShaderMaterial).shader.code.contains("uniform int fx_v2"):
								plating.append(int(sm.get_shader_parameter("fx_v2")))
			if found > 0:
				break
		check(found > 0, "%s: the wreck pieces from a real death carry the faction interior shader (%d surfaces)" % [faction, found])
		if faction in ["chorus", "hegemony"]:
			check(found > 0 and timed, "%s: actual wreck pieces settle their interior on the death clock" % faction)
		# JOINT_B (Nov 23): the wreck plating carries the faction's wound kind, so its scorch keeps the faction soot
		# weight and only steel keeps embers (no glitter of rim-coloured dots)
		var kind: int = int(BREACH.wound_of(faction).get("kind", -9))
		check(not plating.is_empty() and plating.all(func(v: int) -> bool: return v == kind), "%s: the wreck plating carries wound kind %d (%s)" % [faction, kind, str(plating.slice(0, 6))])
	# 8a. Neon's work audit (PR 1902, Fable M2): a death whose piece meshes were built ahead still settles its wreck look in
	# from the death, not from when the meshes were built
	var sp = _ship("ithar", true)
	sp.sync(fx, _state(20, 15, 20))
	flush(sp)
	var DEATH_S = preload("res://fx/fx_death.gd")
	DEATH_S.precompute(fx, sp)   # the cut made ahead of the death, as the game warms it on load
	for k in 1200:
		fx.step(0.05)
		OS.delay_msec(5)
		# this check steps fx by hand, so it finishes the cut and builds the pieces as fx._process would
		if sp.has_meta("cut_task"): DEATH_S.finish_precompute(fx, sp)
		fx._build_death_pieces()
		if (sp.get_meta("cut_job", {}) as Dictionary).get("built", false) and fx.now > 8.0: break
	var pre_built: bool = not ((sp.get_meta("cut_job", {}) as Dictionary).get("meshes", []) as Array).is_empty()
	for k in 60: fx.step(0.05)   # 3 s later, so a stamp from the build and one from the death differ
	var t_death: float = fx.now
	fx.death(sp.id, "blast")
	var t0s: Array = []
	for k in 600:
		fx.step(0.05)
		OS.delay_msec(10)
		for w in fx.dstate.get("wrecks", []):
			if w["id"] != sp.id: continue
			for nd in w["nodes"]:
				if not is_instance_valid(nd): continue
				for mi in (nd as Node3D).find_children("*", "MeshInstance3D", true, false):
					var m: Mesh = (mi as MeshInstance3D).mesh
					for j in (m.get_surface_count() if m != null else 0):
						var sm = m.surface_get_material(j)
						if sm is ShaderMaterial and (sm as ShaderMaterial).shader.code == SH.INTERIOR and float(sm.get_shader_parameter("fx_wreck")) == 1.0:
							t0s.append(float(sm.get_shader_parameter("fx_wreck_t0")))
		if not t0s.is_empty(): break
	check(pre_built and not t0s.is_empty() and t0s.all(func(v: float) -> bool: return v >= t_death - 0.11), "a death with meshes built ahead settles its wreck look from the death (built ahead %s, death %.2f, starts %s)" % [pre_built, t_death, str(t0s.slice(0, 4))])
	# 8b. the cache helper alone
	var src := StandardMaterial3D.new()
	src.set_meta("fx_authored_interior", true)
	for faction in ["ithar", "chorus"]:
		var wm = fx.wreck_interior(src, faction, 24.0)
		check(wm is ShaderMaterial and (wm as ShaderMaterial).shader.code == SH.INTERIOR and float((wm as ShaderMaterial).get_shader_parameter("fx_wreck")) == 1.0, "%s: the wreck keeps the faction interior shader" % faction)
		if faction == "chorus" and wm is ShaderMaterial:
			# Headless does not render fragments. Check the final outputs of the actual wreck shader, not the ORM inputs.
			var finish := RegEx.create_from_string("if \\(wound_v2 == 3\\) \\{\\s*ROUGHNESS = role == 1 \\? ([0-9.]+) : ([0-9.]+);\\s*METALLIC = ([0-9.]+);")
			var finish_match := finish.search((wm as ShaderMaterial).shader.code)
			check(int((wm as ShaderMaterial).get_shader_parameter("wound_v2")) == 3 and finish_match != null
				and minf(float(finish_match.get_string(1)), float(finish_match.get_string(2))) >= 0.7
				and is_zero_approx(float(finish_match.get_string(3))), "chorus: wreck bone and tissue are rough (at least 0.7) and non-metallic")
	var white_panel := StandardMaterial3D.new()
	white_panel.set_meta("extras", {"interior_role": "core"})
	white_panel.emission_enabled = true
	white_panel.emission = Color.WHITE
	white_panel.emission_energy_multiplier = 4.0
	var directorate := fx.wreck_interior(white_panel, "hegemony", 24.0) as ShaderMaterial
	check(int(directorate.get_shader_parameter("role")) == 2 and float(directorate.get_shader_parameter("base_emission_energy")) > 1.0
		and directorate.shader.code.contains("bool directorate_wreck = wound_v2 == 1 && fx_wreck > 0.0;")
		and directorate.shader.code.contains("vec3 bem = vec3(0.0);\n\tif (!directorate_wreck) {"),
		"2125: the first Directorate wreck frame cuts the full-face white emission even on a bright authored core")
	OS.set_environment("VS_WOUNDS_V2", "0")
	var old = fx.wreck_interior(src, "ithar", 24.0)
	check(old is BaseMaterial3D and (old as BaseMaterial3D).roughness == 1.0, "switch off: the wreck keeps the old sooted copy")
	OS.unset_environment("VS_WOUNDS_V2")
	_retired_looks()
	_review_fixes()
	print("wounds_v2_check: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# Fable's blind review of the cohesion package (Nov 22, board/1774/fable_cohesion_review.md): B2, B3, H5, M2
func _review_fixes() -> void:
	OS.set_environment("VS_WOUNDS_V2", "1")
	# JOINT_C (Nov 23): Chorus gas takes its ochre wound accent with V2 on, never the bile lime of damage_glow
	var cg = _ship("chorus", true)
	var lime: Color = cg.fac.damage_glow
	cg.wounds_v2 = true
	var gas_on: Color = cg.chorus_gas(lime)
	cg.wounds_v2 = false
	check(gas_on.is_equal_approx(Color(0.6, 0.52, 0.14)) and cg.chorus_gas(lime) == lime and gas_on.g < lime.g * 0.6, "JOINT_C: Chorus gas is ochre with V2 on (%s), the old bile with it off" % str(gas_on))
	fx.remove_ship(cg.id)
	# JOINT_D's straight-edged fracture cue is still on sealed skin. Actual apertures are checked by _glass_mouth_check.
	check(SH.MARK.contains("vec2 vc = v2cells(q / R * 3.0 + seed);") and not SH.HOLE.contains("bool popped"),
		"JOINT_D / 2125: fracture facets stay on sealed skin, not as dark tiles across an opening")
	# Wave 0 regression set: a shield-only hit leaves no hull mark; a ship removed and added again (revive) starts clean
	var sq = _ship("hegemony", true, true)
	sq.sync(fx, {"hp": 100, "maxHp": 100, "sh": [10, 10, 10, 10], "sec": {}})
	var sa = _ship("voidsworn", false)
	sa.root.position = sq.root.position + Vector3(0, 0, -30)   # a separate attacker, off the target's side
	var marks0: int = sq._marks.size()
	var vs: Dictionary = fx.volley(sa.id, "battery", sq.id, {"weapon_id": "battery", "shots": [true], "hits": [{"shield": 8, "hull": 0, "section": "mid", "crit": false}]})
	var hp_s: Array = vs.get("hit_pts", [])
	var on_bubble: bool = int(vs.get("skipped", 0)) == 0 and (vs.get("impacts", []) as Array).size() == 1 and hp_s.size() == 1 and (hp_s[0] as Vector3).is_finite()
	for k in 120:
		fx.step(1.0 / 60.0)
	check(on_bubble and float(sq._shield_until) > 0.0, "Wave 0: the shield-only shot meets the bubble (one impact, finite shield point, ripple played)")
	check(sq._marks.size() == marks0, "Wave 0: a shield-only hit leaves no hull mark (%d marks)" % (sq._marks.size() - marks0))
	# the companion hull hit on the same fixture does leave a mark, so the check above can fail
	fx.volley(sa.id, "battery", sq.id, {"weapon_id": "battery", "shots": [true], "hits": [{"shield": 0, "hull": 9, "section": "mid", "crit": false}]})
	for k in 120:
		fx.step(1.0 / 60.0)
	check(sq._marks.size() > marks0, "Wave 0: the companion hull hit on the same fixture leaves a mark (%d)" % (sq._marks.size() - marks0))
	fx.remove_ship(sa.id)
	var rid: String = sq.id
	sq.sync(fx, _state(30, 25, 30))
	flush(sq)
	sq.add_mark(fx, "torp", 3, Vector3(0, 2.5, 0), Vector3.UP, Vector3.DOWN)
	var had: int = BREACH.open_mouths(sq).size() + sq._marks.size()
	var body: Node3D = sq.root
	fx.remove_ship(rid)
	fx.add_ship(rid, body, {"faction": "hegemony", "cls": "Cruiser", "size": 0.8, "meshes": sq.meshes, "shielded": false})
	var rv = fx.ship(rid)
	check(had > 0 and rv != null and rv._marks.is_empty() and BREACH.open_mouths(rv).is_empty(), "Wave 0: a revived ship (removed and added again) starts with no marks or open cutouts (had %d)" % had)
	fx.remove_ship(rid)
	# B2: the pattern's line() is 1 on a seam and 0 across the panel (the shader's own text, mirrored here)
	var code: String = SH.INTERIOR
	check(code.contains("float line(float x, float w) { return smoothstep(0.0, w, abs(fract(x) - 0.5) * 2.0 - (1.0 - w * 2.0)); }"), "B2: the interior seam line is not inverted")
	var on_seam := smoothstep(0.0, 0.03, absf(fposmod(0.0, 1.0) - 0.5) * 2.0 - (1.0 - 0.03 * 2.0))
	var mid_panel := smoothstep(0.0, 0.03, absf(fposmod(0.5, 1.0) - 0.5) * 2.0 - (1.0 - 0.03 * 2.0))
	var lit := 0
	for k in 1000:
		var x := float(k) / 1000.0
		lit += 1 if smoothstep(0.0, 0.025, absf(fposmod(x, 1.0) - 0.5) * 2.0 - (1.0 - 0.025 * 2.0)) > 0.5 else 0
	check(on_seam > 0.99 and mid_panel < 0.01 and lit < 40, "B2: a 0.025 line lights %d of 1000 samples (seam %.2f, panel %.2f)" % [lit, on_seam, mid_panel])
	# B3: surface roles. A role-table surface (glTF extras interior_role) is trusted; an older one is read by name and light
	var bone := StandardMaterial3D.new()
	bone.set_meta("extras", {"interior_role": "bone"})
	var core := StandardMaterial3D.new()
	core.resource_name = "C19_51_inside_8"
	core.emission_enabled = true
	core.emission = Color(1, 0.75, 0.2)
	core.emission_energy_multiplier = 4.0
	var wall := StandardMaterial3D.new()
	wall.resource_name = "C19_51_inside_3"
	# the role rides in the hull contract (Godot drops material extras): _authored copies it onto the material
	var cdoc := GLTFDocument.new()
	var cst := GLTFState.new()
	var cbytes := FileAccess.get_file_as_bytes("res://fx/test/fixtures/C19_51_unbaked.glb.gz").decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	cdoc.append_from_buffer(cbytes, "res://", cst)
	var cship := cdoc.generate_scene(cst) as Node3D
	for nd in [cship] + cship.find_children("*", "Node3D", true, false):
		var ex = nd.get_meta("extras", {})
		if ex is Dictionary and ex.has("voidsworn_destruct"):
			var con: Dictionary = ex["voidsworn_destruct"]
			con["interior_roles"] = {"C19_51_inside_2": "bone"}
			ex["voidsworn_destruct"] = con
			nd.set_meta("extras", ex)
	var ch = HULL.new()
	ch._authored(cship)
	var crole := []
	for mi in cship.find_children("*", "MeshInstance3D", true, false):
		var cm: Mesh = (mi as MeshInstance3D).mesh
		for j in cm.get_surface_count():
			var cmat := cm.surface_get_material(j)
			if cmat != null and cmat.resource_name == "C19_51_inside_2":
				crole = HULL.interior_role(cmat)
	check(crole == [1, true], "B3: a role in the hull contract's interior_roles reaches the material (%s)" % str(crole))
	cship.free()
	check(HULL.interior_role(bone) == [1, true] and HULL.interior_role(core) == [2, false] and HULL.interior_role(wall) == [0, false], "B3: bone from the role table, a lit inside as a core, a plain inside as a wall")
	var im: ShaderMaterial = HULL.interior_material_v2(core, Transform3D.IDENTITY, {"count": 1, "mouths": [Vector4.ZERO], "axes": [Vector4(0, 1, 0, 1)]}, BREACH.wound_of("deathless"), 20.0)
	check(int(im.get_shader_parameter("role")) == 2 and not bool(im.get_shader_parameter("trusted")), "B3: the shader gets the surface role")
	check(code.contains("vec3 lit = surf * mix(1.0, r.x * ao") and not code.contains("lit = min(lit, vec3(0.11))"), "B3 and H2: the pattern multiplies over the surface; the wall ceiling scales, never clips per channel")
	check(code.contains("v2_interior_accent / max(am, 1e-3) * bl"), "H3: an older surface's own light is recoloured to the faction accent")
	check(code.contains("ALBEDO = mix(trusted ? baked : lit * 0.15, lit, open_f);") and code.contains("bn = dot(bn, bn) > 1e-12 ? normalize(bn) : NORMAL;"), "audit 1755: no diagram colour away from a mouth, no NaN normal on a grazing face")
	var hole: String = SH.HOLE
	check(hole.contains("em_hdr") and not hole.contains("vec3(wound_v2 >= 0 ? 0.25 : 0.35)"), "H2: the breach glow scales to 0.25 and rim heat, bus tips and burns pass")
	# M2: the oldest open holes keep their place; a newer one past the cap seals
	var hl = _hull_of(_box_faces(Vector3(24, 5, 8)), 24.0)
	var ents: Array = []
	for k in 3:
		var e = BREACH.place_hole(hl, Vector3(-6 + k * 4, 2.5, 0), Vector3.UP, 0.9, float(k), "voidsworn")
		e.sec = 1
		e.t0 = [5.0, 1.0, 3.0][k]
		ents.append(e)
	var capped: Array = BREACH.cap_holes(ents)
	check(capped.size() == 3, "M2: every entry keeps its place in the list")
	check(not capped[0].has_cut() and capped[1].has_cut() and capped[2].has_cut(), "M2: the newest hole (t0 5) seals, the two older ones stay open")
	# H5: on the real C19_51 export (the A16 fixture, outer plating only in the hull reader), a midship cutout opens
	var path := "res://fx/test/fixtures/C19_51_unbaked.glb.gz"
	var bytes := FileAccess.get_file_as_bytes(path).decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	check(not bytes.is_empty() and doc.append_from_buffer(bytes, path.get_base_dir(), st) == OK, "H5: the C19_51 fixture loads")
	var ship := doc.generate_scene(st) as Node3D
	var holder := Node3D.new()
	world.add_child(holder)
	holder.position = Vector3(0, 0, 300)
	holder.add_child(ship)
	fx.add_ship("c19_fixture", holder, {"faction": "corsair", "cls": "Battle-barge", "size": 1.22, "shielded": false})
	fx._later.clear()
	var sf = fx.ship("c19_fixture")
	check(sf.hull.authored, "H5: the fixture reads as an authored-interior hull")
	var L: float = sf.hull.L
	var opened := 0
	var tried := 0
	var notes: Array = []
	for x in [-0.08, 0.0, 0.08]:
		for d in [Vector3.UP, Vector3.BACK, Vector3.FORWARD]:
			var hit: Dictionary = sf.hull.ray(Vector3(x * L, 0, 0) + d * L, -d)
			if hit.is_empty():
				continue
			tried += 1
			var eh = BREACH.place_hole(sf.hull, hit["p"], hit["n"], L * BREACH.V2_HOLE_L[1], 0.3, "corsair")
			var fp: Dictionary = BREACH.validate_footprint(sf.hull, hit["p"], hit["n"], L * BREACH.V2_HOLE_L[1])
			notes.append("x%.2f %s Dt/R %.2f %s" % [x, str(d), float(fp["Dt"]) / maxf(float(fp["R"]), 1e-4), "open" if eh.has_cut() and not eh.thin_shear else ("thin" if eh.thin_shear else "mark")])
			if eh.has_cut() and not eh.thin_shear:
				opened += 1
	print("  H5 midship: ", ", ".join(notes))
	# V2B PC run: the warm-up's interior material is kept for the battle, so the first breach never compiles late
	var tmpn := Node3D.new()
	world.add_child(tmpn)
	fx._warm_hull_meshes(tmpn, sf, {}, 0)
	tmpn.free()
	var kept := 0
	for key in fx._damage_templates:
		if str(key).begins_with("interior_v2_") and (fx._damage_templates[key] as ShaderMaterial).shader.code == SH.INTERIOR:
			kept += 1
	check(kept >= 1, "the warm-up keeps its interior material, so the interior shader is not made again late (%d kept)" % kept)
	check(tried > 0 and opened == tried, "H5: midship cutouts on the real hull open into the ship, not chip (%d of %d)" % [opened, tried])
	OS.unset_environment("VS_WOUNDS_V2")


# Nov 24 (Ryan's yes, Morning Pick Sheet item 5): V2 is on by default and the old wound looks are gone from the code
func _retired_looks() -> void:
	OS.unset_environment("VS_WOUNDS_V2")
	check(WOUNDS.v2(), "default: Wounds V2 is on with the switch unset")
	OS.set_environment("VS_WOUNDS_V2", "0")
	check(not WOUNDS.v2(), "default: VS_WOUNDS_V2=0 still turns it off")
	OS.unset_environment("VS_WOUNDS_V2")
	check(not SH.HOLE.contains("muscle") and not SH.HOLE.contains("float bus ="), "retired: HOLE has no old Chorus flesh or Eclipse bus look")
	check(not SH.MARK.contains("float circuit") and not SH.MARK.contains("float web ="), "retired: MARK has no Eclipse square grid or Glasswright sine web")
	var dc: String = HULL._damage_code(HULL.EXTERIOR)
	check(not dc.contains("fx_v2 >= 0 ? clamp(fx_v2_soot"), "retired: the 94% soot collar always follows the faction soot weight")
	check(not dc.contains("vec3(0.018, 0.003, 0.009)"), "retired: no magenta flesh on the back of the plating")
	check(dc.contains("(fx_v2 == 0 || fx_v2 == 2) ? 0.35 : 0.0"), "retired: orange backface embers on steel only")
	check(not DEATH.SLAG.contains("vec3(0.025, 0.005, 0.013)"), "retired: SLAG has no magenta organic face")
