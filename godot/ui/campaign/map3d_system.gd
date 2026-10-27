extends RefCounted
# The star system behind the 3D sector map (G3, R51): the Hollow Sun at the centre (a dead black star ringed in slow fire,
# a battlefield debris ring round it), orbit lines, the sky and its parallax layers, and the place each stop sits in
# (planets with atmospheres and moons, stations, asteroid fields, nebula pockets, wreck fields). Presentation only:
# its randomness is the map's own generator, never the rules' PRNG.
#
# Faction looks follow lore round 3 (R51): colours and visuals only; ids and names stay as they are (lore is in flux).

const SH := preload("res://ui/campaign/map3d_shaders.gd")

# Lore round 3 faction looks. base: hull and dark tone; main: the faction colour; light: its lights and glows;
# text: a readable colour for its name on the dark UI; look: 0 plain, 1 lights pulse in step, 2 rainbow edges, 3 corona.
const LOOKS := {
	"voidsworn": {"base": Color("#1c1815"), "main": Color("#d8621e"), "light": Color("#ff8a36"), "text": Color("#ff9a4a"), "look": 0},
	"hegemony": {"base": Color("#80868f"), "main": Color("#4a7fbf"), "light": Color("#6eb2ff"), "text": Color("#7ab4f0"), "look": 1},
	"corsair": {"base": Color("#1e1b19"), "main": Color("#9a4a26"), "light": Color("#c0362c"), "text": Color("#d8664a"), "look": 0},
	"chorus": {"base": Color("#22122b"), "main": Color("#6e3584"), "light": Color("#d4cb3c"), "text": Color("#dcd45a"), "look": 0},
	"ithar": {"base": Color("#d6f2ff"), "main": Color("#a8e6ff"), "light": Color("#e8fcff"), "text": Color("#c4f0ff"), "look": 2},
	"deathless": {"base": Color("#1b0f26"), "main": Color("#55287a"), "light": Color("#ffe2a0"), "text": Color("#f0d690"), "look": 3},
}
# sky tints per sector faction: [nebula 1, nebula 2, highlight]
const SKIES := {
	"voidsworn": [Vector3(0.42, 0.14, 0.05), Vector3(0.2, 0.08, 0.1), Vector3(1.0, 0.6, 0.3)],
	"hegemony": [Vector3(0.1, 0.2, 0.42), Vector3(0.3, 0.38, 0.55), Vector3(0.7, 0.85, 1.0)],
	"corsair": [Vector3(0.36, 0.12, 0.06), Vector3(0.42, 0.06, 0.06), Vector3(1.0, 0.55, 0.3)],
	"chorus": [Vector3(0.24, 0.08, 0.32), Vector3(0.42, 0.4, 0.08), Vector3(0.9, 0.88, 0.4)],
	"ithar": [Vector3(0.08, 0.28, 0.4), Vector3(0.32, 0.2, 0.52), Vector3(0.8, 1.0, 1.0)],
	"deathless": [Vector3(0.18, 0.06, 0.3), Vector3(0.32, 0.14, 0.44), Vector3(1.0, 0.86, 0.58)],
}
# planet palettes: [kind, a, b, atmosphere]
const PLANETS := [
	[0, Color(0.55, 0.42, 0.3), Color(0.24, 0.16, 0.11), Color(1.0, 0.62, 0.38)],
	[1, Color(0.36, 0.42, 0.26), Color(0.06, 0.16, 0.32), Color(0.45, 0.7, 1.0)],
	[2, Color(0.78, 0.62, 0.44), Color(0.42, 0.26, 0.18), Color(1.0, 0.75, 0.5)],
	[2, Color(0.52, 0.6, 0.72), Color(0.2, 0.26, 0.4), Color(0.55, 0.75, 1.0)],
	[3, Color(0.8, 0.86, 0.92), Color(0.42, 0.52, 0.62), Color(0.65, 0.85, 1.0)],
	[4, Color(0.2, 0.15, 0.13), Color(0.06, 0.04, 0.04), Color(1.0, 0.45, 0.2)],
	[0, Color(0.5, 0.36, 0.44), Color(0.2, 0.12, 0.18), Color(0.85, 0.55, 1.0)],
]

var q := 1.0                 # 1 high quality, 0 low
var rng: RandomNumberGenerator
var sun_pos := Vector3(0, 1.0, 0)
var _shaders := {}
var _rock_meshes: Array = []

static func look(fac) -> Dictionary: return LOOKS.get(str(fac), LOOKS["voidsworn"])
static func text_col(fac) -> Color: return look(fac)["text"]

func _sh(name: String) -> Shader:
	if not _shaders.has(name):
		var codes = {"SKY": SH.SKY, "STARPTS": SH.STARPTS, "NEB_SHEET": SH.NEB_SHEET, "SUN_CORE": SH.SUN_CORE, "SUN_FIRE": SH.SUN_FIRE, "GLOW": SH.GLOW,
			"PLANET": SH.PLANET, "ATMO": SH.ATMO, "ROCK": SH.ROCK, "ORBIT": SH.ORBIT, "LANE": SH.LANE, "RING": SH.RING, "CLOUD": SH.CLOUD,
			"MARKER": SH.MARKER, "HALO": SH.HALO, "TERR": SH.TERR}
		var s = Shader.new(); s.code = codes[name]; _shaders[name] = s
	return _shaders[name]
func mat(name: String, params: Dictionary = {}) -> ShaderMaterial:
	var m = ShaderMaterial.new(); m.shader = _sh(name)
	for k in params: m.set_shader_parameter(k, params[k])
	return m
func mi(mesh: Mesh, m: Material, at: Vector3 = Vector3.ZERO, sc: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var n = MeshInstance3D.new(); n.mesh = mesh; n.material_override = m; n.position = at; n.scale = sc
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; return n
func sphere(r: float, seg: int = 48, rings: int = 24) -> SphereMesh:
	var s = SphereMesh.new(); s.radius = r; s.height = r * 2.0; s.radial_segments = seg; s.rings = rings; return s
func quad(w: float, h: float) -> QuadMesh:
	var m = QuadMesh.new(); m.size = Vector2(w, h); return m
func flat(w: float, d: float) -> PlaneMesh:
	var p = PlaneMesh.new(); p.size = Vector2(w, d); return p
func std(col: Color, emit: float = 0.0, metal: float = 0.4, rough: float = 0.5) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_color = col; m.metallic = metal; m.roughness = rough
	if emit > 0.0: m.emission_enabled = true; m.emission = col; m.emission_energy_multiplier = emit
	return m

# A strip along a circle arc in the chart plane (UV.x across the strip, UV.y along it).
func arc_mesh(r: float, w: float, a0: float, a1: float, seg: int) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in seg:
		var t0 = float(i) / seg; var t1 = float(i + 1) / seg
		var b0 = lerp(a0, a1, t0); var b1 = lerp(a0, a1, t1)
		var p = [Vector3(cos(b0) * (r - w * 0.5), 0, -sin(b0) * (r - w * 0.5)), Vector3(cos(b0) * (r + w * 0.5), 0, -sin(b0) * (r + w * 0.5)),
			Vector3(cos(b1) * (r - w * 0.5), 0, -sin(b1) * (r - w * 0.5)), Vector3(cos(b1) * (r + w * 0.5), 0, -sin(b1) * (r + w * 0.5))]
		var uv = [Vector2(0, t0), Vector2(1, t0), Vector2(0, t1), Vector2(1, t1)]
		for k in [0, 1, 2, 1, 3, 2]:
			st.set_uv(uv[k]); st.set_normal(Vector3.UP); st.add_vertex(p[k])
	return st.commit()
# A straight ribbon in the chart plane from a to b (UV.x across, UV.y from a to b).
func ribbon(a: Vector3, b: Vector3, w: float) -> ArrayMesh:
	var d = (b - a); d.y = 0.0; var side = Vector3(-d.z, 0, d.x).normalized() * w * 0.5
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var p = [a - side, a + side, b - side, b + side]; var uv = [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]
	for k in [0, 1, 2, 1, 3, 2]:
		st.set_uv(uv[k]); st.set_normal(Vector3.UP); st.add_vertex(p[k])
	return st.commit()
# A small faceted rock (a lumpy low sphere with flat faces).
func rock_mesh(seed_v: int) -> ArrayMesh:
	var r2 = RandomNumberGenerator.new(); r2.seed = seed_v
	var arr = SphereMesh.new(); arr.radius = 1.0; arr.height = 2.0; arr.radial_segments = 9; arr.rings = 6
	var a = arr.get_mesh_arrays(); var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]; var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var el = Vector3(r2.randf_range(0.8, 1.35), r2.randf_range(0.55, 0.9), r2.randf_range(0.75, 1.15))
	var bumps = []
	for i in 6: bumps.append([Vector3(r2.randf_range(-1, 1), r2.randf_range(-1, 1), r2.randf_range(-1, 1)).normalized(), r2.randf_range(-0.3, 0.22)])
	var cache = {}
	for i in v.size():
		var key = (v[i] * 1000.0).round()
		if not cache.has(key):
			var dir = v[i].normalized() if v[i].length() > 0.0001 else Vector3.UP
			var k = 1.0
			for bm in bumps: k += bm[1] * pow(max(0.0, dir.dot(bm[0])), 3.0)
			cache[key] = dir * k * el
		v[i] = cache[key]
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in idx: st.add_vertex(v[i])
	st.generate_normals()
	return st.commit()
func rocks_lib() -> Array:
	if _rock_meshes.is_empty():
		for i in 4: _rock_meshes.append(rock_mesh(1000 + i * 77))
	return _rock_meshes
# Scattered instances: items = [[transform, smoulder], ...]
func scatter(parent: Node3D, mesh: Mesh, m: Material, items: Array) -> MultiMeshInstance3D:
	var mm = MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_custom_data = true; mm.mesh = mesh; mm.instance_count = items.size()
	for i in items.size():
		mm.set_instance_transform(i, items[i][0]); mm.set_instance_custom_data(i, Color(items[i][1], 0, 0, 0))
	var n = MultiMeshInstance3D.new(); n.multimesh = mm; n.material_override = m; n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(n); return n
func rand_basis(s: float) -> Basis:
	return Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)).scaled(Vector3.ONE * s)
func glow(parent: Node3D, col: Color, size: float, at: Vector3 = Vector3.ZERO, power: float = 2.0, gain: float = 1.0, pulse: float = 0.0) -> MeshInstance3D:
	var g = mi(quad(1, 1), mat("GLOW", {"col": col, "power": power, "gain": gain, "pulse": pulse}), at, Vector3.ONE * size)
	g.extra_cull_margin = size; parent.add_child(g); return g

# ---------------------------------------------------------------- sky and parallax layers
func sky(env: Environment, fac: String, seed_v: int) -> void:
	var t = SKIES.get(fac, SKIES["hegemony"])
	var m = mat("SKY", {"c1": t[0], "c2": t[1], "c3": t[2], "seed": float(seed_v % 97) * 1.37, "q": q})
	var s = Sky.new(); s.sky_material = m; s.radiance_size = Sky.RADIANCE_SIZE_32; s.process_mode = Sky.PROCESS_MODE_QUALITY
	env.sky = s; env.background_mode = Environment.BG_SKY
func backdrop(parent: Node3D, fac: String, px_scale: float) -> void:
	# near stars on a shell round the chart: they slide against the sky as the camera moves
	var n = 4200 if q > 0.5 else 1400
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_POINTS)
	for i in n:
		var d = Vector3(rng.randfn(), rng.randfn() * 0.8, rng.randfn()).normalized()
		var r = rng.randf_range(260.0, 620.0)
		var t = rng.randf()
		var c = Color(0.65, 0.76, 1.0).lerp(Color(1.0, 0.86, 0.68), t)
		var b = pow(rng.randf(), 3.0)
		st.set_color(Color(c.r * (0.25 + b), c.g * (0.25 + b), c.b * (0.25 + b), 0.4 + b * 0.9)); st.add_vertex(d * r)
	var pts = MeshInstance3D.new(); pts.mesh = st.commit(); pts.material_override = mat("STARPTS", {"px": px_scale}); pts.extra_cull_margin = 2000.0
	pts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; parent.add_child(pts)
	# big soft nebula sheets under the chart, at depth (parallax between the chart and the sky)
	var t2 = SKIES.get(fac, SKIES["hegemony"])
	var sheets = 4 if q > 0.5 else 2
	for i in sheets:
		var a = Color(t2[i % 2].x, t2[i % 2].y, t2[i % 2].z); var b2 = Color(t2[(i + 1) % 2].x, t2[(i + 1) % 2].y, t2[(i + 1) % 2].z)
		var sz = rng.randf_range(160.0, 260.0)
		var sh = mi(flat(sz, sz), mat("NEB_SHEET", {"a": a, "b": b2, "gain": rng.randf_range(0.22, 0.4), "seed": rng.randf() * 50.0, "oct": 5.0 if q > 0.5 else 3.0}),
			Vector3(rng.randf_range(-90, 90), -rng.randf_range(45.0, 130.0), rng.randf_range(-120, 40)))
		sh.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf() * TAU, rng.randf_range(-0.2, 0.2)); sh.extra_cull_margin = sz
		parent.add_child(sh)

# ---------------------------------------------------------------- the Hollow Sun
# A dead black star ringed in slow fire, its glow the only light in the system, a ring of battle debris round it.
# Returns {"root", "debris"} (the debris turns in map3d's _process).
func hollow_sun(parent: Node3D, core_r: float = 6.0) -> Dictionary:
	var root = Node3D.new(); root.name = "HollowSun"; root.position = sun_pos; parent.add_child(root)
	root.add_child(mi(sphere(core_r, 64 if q > 0.5 else 32, 32 if q > 0.5 else 16), mat("SUN_CORE")))
	var tilt = Node3D.new(); tilt.rotation = Vector3(deg_to_rad(-9.0), 0, deg_to_rad(5.0)); root.add_child(tilt)
	var r_in = core_r * 1.06; var r_out = core_r * 2.05
	var fire = mi(arc_mesh((r_in + r_out) * 0.5, r_out - r_in, 0.0, TAU, 160 if q > 0.5 else 80), mat("SUN_FIRE", {"r_in": r_in, "r_out": r_out, "q": q}))
	fire.extra_cull_margin = r_out; tilt.add_child(fire)
	# a thinner, fainter outer fire band, slower
	var fire2 = mi(arc_mesh(r_out * 1.18, r_out * 0.35, 0.0, TAU, 120 if q > 0.5 else 60), mat("SUN_FIRE", {"r_in": r_out * 1.0, "r_out": r_out * 1.36, "q": q, "gain": 0.35}))
	fire2.rotation.y = 1.3; tilt.add_child(fire2)
	glow(root, Color(1.0, 0.42, 0.12, 1.0), core_r * 5.2, Vector3.ZERO, 2.4, 0.55)
	glow(root, Color(0.7, 0.16, 0.05, 1.0), core_r * 13.0, Vector3.ZERO, 3.2, 0.22)
	var l = OmniLight3D.new(); l.light_color = Color(1.0, 0.6, 0.32); l.light_energy = 5.0; l.omni_range = 150.0; l.omni_attenuation = 0.55
	l.shadow_enabled = false; root.add_child(l)
	# the battlefield debris ring: rock, torn hull plates and girders, some still smouldering
	var deb = Node3D.new(); deb.name = "debris"; deb.rotation = Vector3(deg_to_rad(-4.0), 0, deg_to_rad(3.0)); root.add_child(deb)
	var r0 = core_r * 2.3; var r1 = core_r * 3.1
	var nk = [520, 420, 160] if q > 0.5 else [140, 110, 40]
	var lib = rocks_lib()
	for k in lib.size():
		var items = []
		for i in nk[0] / lib.size():
			var a = rng.randf() * TAU; var r = lerp(r0, r1, pow(rng.randf(), 0.8)) + sin(a * 5.0) * 0.6
			var p = Vector3(cos(a) * r, rng.randfn() * 0.35, -sin(a) * r)
			items.append([Transform3D(rand_basis(rng.randf_range(0.05, 0.32) * (2.2 if rng.randf() < 0.04 else 1.0)), p), 1.0 if rng.randf() < 0.12 else 0.0])
		scatter(deb, lib[k], mat("ROCK", {"tint": Color(0.16, 0.14, 0.13), "metal": 0.05, "ember": 1.0}), items)
	var plate = BoxMesh.new(); plate.size = Vector3(1.0, 0.06, 0.6)
	var items2 = []
	for i in nk[1]:
		var a = rng.randf() * TAU; var r = lerp(r0, r1, rng.randf())
		items2.append([Transform3D(rand_basis(rng.randf_range(0.2, 0.75)), Vector3(cos(a) * r, rng.randfn() * 0.3, -sin(a) * r)), 1.0 if rng.randf() < 0.18 else 0.0])
	scatter(deb, plate, mat("ROCK", {"tint": Color(0.3, 0.29, 0.28), "metal": 0.7, "ember": 1.0}), items2)
	var girder = BoxMesh.new(); girder.size = Vector3(1.6, 0.07, 0.07)
	var items3 = []
	for i in nk[2]:
		var a = rng.randf() * TAU; var r = lerp(r0, r1, rng.randf())
		items3.append([Transform3D(rand_basis(rng.randf_range(0.4, 1.0)), Vector3(cos(a) * r, rng.randfn() * 0.3, -sin(a) * r)), 0.0])
	scatter(deb, girder, mat("ROCK", {"tint": Color(0.36, 0.34, 0.32), "metal": 0.8, "ember": 0.0}), items3)
	# embers caught in the ring
	if q > 0.5:
		for i in 14:
			var a = rng.randf() * TAU; var r = lerp(r0, r1, rng.randf())
			glow(deb, Color(1.0, 0.45, 0.15, 1.0), rng.randf_range(0.5, 1.1), Vector3(cos(a) * r, rng.randfn() * 0.2, -sin(a) * r), 2.0, 1.4)
	return {"root": root, "debris": deb}

# ---------------------------------------------------------------- orbits
func orbit(parent: Node3D, r: float, col: Color, w: float = 0.3, ticks: float = 0.0) -> MeshInstance3D:
	var o = mi(arc_mesh(r, w, 0.0, TAU, int(clamp(r * 4.0, 64, 360))), mat("ORBIT", {"col": col, "ticks": ticks}), Vector3(0, 0.02, 0) + Vector3(sun_pos.x, 0, sun_pos.z))
	o.extra_cull_margin = r; parent.add_child(o); return o
func orbit_arc(parent: Node3D, r: float, a0: float, a1: float, col: Color, w: float = 0.4) -> MeshInstance3D:
	var o = mi(arc_mesh(r, w, a0, a1, 32), mat("ORBIT", {"col": col, "fade_ends": 1.0}), Vector3(sun_pos.x, 0.03, sun_pos.z))
	parent.add_child(o); return o

# ---------------------------------------------------------------- bodies
func planet(parent: Node3D, pal: Array, radius: float, at: Vector3, with_atmo: bool = true) -> Node3D:
	var body = Node3D.new(); body.position = at; body.name = "body"; parent.add_child(body)
	var seg = 64 if q > 0.5 else 32
	var p = mi(sphere(radius, seg, seg / 2), mat("PLANET", {"a": pal[1], "b": pal[2], "atmo": pal[3], "kind": float(pal[0]), "seed": rng.randf() * 40.0, "q": q}))
	p.name = "spin"; p.rotation = Vector3(deg_to_rad(rng.randf_range(-20, 20)), 0, deg_to_rad(rng.randf_range(-25, 25))); body.add_child(p)
	if with_atmo:
		body.add_child(mi(sphere(radius * 1.09, seg, seg / 2), mat("ATMO", {"atmo": pal[3], "sun_pos": sun_pos, "gain": 0.6 if int(pal[0]) == 5 else 1.0})))
	if int(pal[0]) == 2 and rng.randf() < 0.55:   # rings round some gas giants
		var rg = mi(arc_mesh(radius * 1.75, radius * 0.9, 0.0, TAU, 96), mat("ORBIT", {"col": Color(pal[1].lerp(Color.WHITE, 0.3), 0.55)}))
		rg.rotation = Vector3(deg_to_rad(rng.randf_range(12, 28)), 0, deg_to_rad(rng.randf_range(-20, 20))); body.add_child(rg)
	return body
func moon(parent: Node3D, center: Vector3, orbit_r: float, radius: float) -> Node3D:
	var piv = Node3D.new(); piv.name = "moon"; piv.position = center; piv.rotation = Vector3(deg_to_rad(rng.randf_range(10, 24)), rng.randf() * TAU, 0); parent.add_child(piv)
	var pal = [5, Color(0.62, 0.6, 0.58), Color(0.3, 0.29, 0.28), Color(0.6, 0.6, 0.65)]
	var m = mi(sphere(radius, 24, 12), mat("PLANET", {"a": pal[1], "b": pal[2], "atmo": pal[3], "kind": 5.0, "seed": rng.randf() * 40.0, "q": q}), Vector3(orbit_r, 0, 0))
	piv.add_child(m)
	piv.add_child(mi(arc_mesh(orbit_r, 0.08, 0.0, TAU, 64), mat("ORBIT", {"col": Color(0.7, 0.78, 0.95, 0.35)})))
	return piv
func clouds(parent: Node3D, a: Color, b: Color, n: int, spread: float, at: Vector3, gain: float = 0.6, storm: float = 0.0) -> Node3D:
	var w = Node3D.new(); w.position = at; parent.add_child(w)
	for i in n:
		var s = rng.randf_range(2.6, 4.6) * spread
		var c = mi(quad(1, 1), mat("CLOUD", {"a": a, "b": b, "gain": gain * rng.randf_range(0.7, 1.1), "seed": rng.randf() * 30.0, "storm": storm, "oct": 4.0 if q > 0.5 else 3.0}),
			Vector3(rng.randf_range(-1, 1) * spread, rng.randf_range(-0.3, 0.5) * spread, rng.randf_range(-1, 1) * spread), Vector3.ONE * s)
		c.extra_cull_margin = s; w.add_child(c)
	return w
# rocks spread along the sun orbit through a stop (an asteroid field), plus a few big ones at the stop itself
func belt(parent: Node3D, theta: float, r: float, node_pos: Vector3, kind: int) -> void:
	var tints = [Color(0.3, 0.27, 0.24), Color(0.34, 0.31, 0.3), Color(0.5, 0.56, 0.62)]
	var lib = rocks_lib(); var n = 70 if q > 0.5 else 26
	for k in 2:
		var items = []
		for i in n / 2:
			var a = theta + rng.randfn() * (5.0 / r) * 1.4; var rr = r + rng.randfn() * 1.4
			var p = Vector3(cos(a) * rr, rng.randfn() * 0.4 + 0.6, -sin(a) * rr) - node_pos
			items.append([Transform3D(rand_basis(rng.randf_range(0.08, 0.34)), p), 0.0])
		for i in 3:
			items.append([Transform3D(rand_basis(rng.randf_range(0.5, 0.95)), Vector3(rng.randf_range(-1.6, 1.6), rng.randf_range(0.6, 1.8), rng.randf_range(-1.2, 1.2))), 0.0])
		scatter(parent, lib[(k + kind) % lib.size()], mat("ROCK", {"tint": tints[kind % 3], "metal": 0.1 if kind != 1 else 0.5}), items)
func wreck_scraps(parent: Node3D, n: int, spread: float) -> void:
	var plate = BoxMesh.new(); plate.size = Vector3(1.0, 0.06, 0.5)
	var items = []
	for i in n:
		items.append([Transform3D(rand_basis(rng.randf_range(0.15, 0.55)), Vector3(rng.randfn() * spread, rng.randf_range(0.3, 2.2), rng.randfn() * spread * 0.7)), 1.0 if rng.randf() < 0.3 else 0.0])
	scatter(parent, plate, mat("ROCK", {"tint": Color(0.28, 0.27, 0.26), "metal": 0.7, "ember": 1.0}), items)
func marker(parent: Node3D, at: Vector3, size: float, fac: String, elite: bool) -> MeshInstance3D:
	var L = look(fac)
	var gem = mi(sphere(size, 4, 2), mat("MARKER", {"col": Color("#ff3a2a") if elite else Color("#e8402e"), "rim": L["light"], "look": float(L["look"])}), at)
	gem.scale = Vector3(1.0, 1.35, 1.0); gem.name = "bob"; parent.add_child(gem)
	glow(parent, Color(1.0, 0.25, 0.15, 1.0), size * 4.5, at, 2.2, 0.55)
	if int(L["look"]) == 3: glow(parent, L["light"], size * 7.0, at, 3.0, 0.45)   # the Deathless white-gold corona
	return gem
func halo(parent: Node3D, fac: String, radius: float, at: Vector3 = Vector3(0, 0.04, 0)) -> MeshInstance3D:
	var L = look(fac); var h = radius / 0.85
	var m = mi(flat(h * 2.0, h * 2.0), mat("HALO", {"col": L["light"], "col2": L["main"].lerp(L["light"], 0.4), "look": float(L["look"])}), at)
	m.extra_cull_margin = h; parent.add_child(m); return m
