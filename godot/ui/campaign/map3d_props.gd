extends RefCounted
# Stop objects at full finish for the 3D sector map (G3, R51 round 2; Ryan: "the actual icons still look kind of low
# poly, especially compared to the background"). Built procedurally in Godot, no downloads: an orbital station (spindle,
# habitat ring on spokes, docking arms, solar arrays, heat radiators, an antenna array, running lights), construction
# gantries, a dock frame with work lights, a repair tender's arms and its drones, and asteroids with real displaced
# meshes and craters. Every part carries panel plating, seams, grit and lit windows in its lighting (map3d_shaders.gd
# HULL, SOLAR, RADIATOR, ROCK_HI). Space ships, not naval ships (CLAUDE.md): antenna arrays and heat radiators, no masts
# or funnels. Presentation only; randomness is the map's own generator.

var sys                       # map3d_system.gd (materials, glows, the map's random generator)
var q := 1.0                  # 1 high, 0 low
var blinkers: Array = []      # [glow mesh, phase, period] running lights that blink (map3d animates them)
static var _rock_cache := {}

func _init(system) -> void:
	sys = system; q = system.q

func caster(n: GeometryInstance3D) -> GeometryInstance3D:   # High: parts cast soft shadows from the Hollow Sun
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if q > 0.5 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return n
func hull_mat(base: Color, accent: Color, scale: float = 3.0, windows: float = 0.12, metal: float = 0.6) -> ShaderMaterial:
	return sys.mat("HULL", {"base": base, "accent": accent, "scale": scale, "windows": windows, "metal": metal})
func cyl(r0: float, h: float, r1: float = -1.0, seg: int = 28) -> CylinderMesh:
	var c = CylinderMesh.new(); c.top_radius = r0; c.bottom_radius = r1 if r1 >= 0.0 else r0; c.height = h
	c.radial_segments = seg if q > 0.5 else max(8, seg / 2); c.rings = 1; return c
func box(x: float, y: float, z: float) -> BoxMesh:
	var b = BoxMesh.new(); b.size = Vector3(x, y, z); return b
func part(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var n = MeshInstance3D.new(); n.mesh = mesh; n.material_override = m; n.position = pos; n.rotation_degrees = rot_deg
	caster(n); parent.add_child(n); return n
# a straight member from a to b (a box of width w)
func beam(parent: Node3D, a: Vector3, b: Vector3, w: float, m: Material) -> MeshInstance3D:
	var d = b - a; var L = d.length()
	var n = part(parent, box(w, w, max(0.01, L)), m, (a + b) * 0.5)
	if L > 0.001:   # local frame: -Z of the box along the member (look_at would work in global space)
		var up = Vector3.UP if abs(d.normalized().dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		n.transform = Transform3D(Basis.looking_at(d.normalized(), up), (a + b) * 0.5)
	return n
# a lattice member from a to b: four rails a square of side w apart, braced by diagonals every bay; one MultiMesh per
# member (a unit box per bar), so a whole gantry is a few draw calls
static var _unit_box: BoxMesh = null
func truss(parent: Node3D, a: Vector3, b: Vector3, w: float, m: Material, bays: int = -1) -> void:
	var d = b - a; var L = d.length()
	if L < 0.01: return
	var ax = d / L; var up = Vector3.UP if abs(ax.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var s1 = ax.cross(up).normalized() * w * 0.5; var s2 = ax.cross(s1).normalized() * w * 0.5
	var corners = [s1 + s2, s1 - s2, -s1 - s2, -s1 + s2]
	var rw = max(0.04, w * 0.16)
	var bars = []   # [from, to, width]
	for cn in corners: bars.append([a + cn, b + cn, rw])
	var nb = bays if bays > 0 else max(1, int(round(L / (w * 1.4))))
	if q < 0.5: nb = max(1, nb / 2)
	for i in nb:
		var p0 = a + d * (float(i) / nb); var p1 = a + d * (float(i + 1) / nb)
		for k in 4: bars.append([p0 + corners[k], p1 + corners[(k + 1) % 4], rw * 0.6])
	if _unit_box == null: _unit_box = box(1, 1, 1)
	var mm = MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.mesh = _unit_box; mm.instance_count = bars.size()
	for i in bars.size():
		var bd = bars[i][1] - bars[i][0]; var bl = bd.length()
		var bu = Vector3.UP if abs(bd.normalized().dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		mm.set_instance_transform(i, Transform3D(Basis.looking_at(bd.normalized(), bu) * Basis.from_scale(Vector3(bars[i][2], bars[i][2], bl)), (bars[i][0] + bars[i][1]) * 0.5))
	var n = MultiMeshInstance3D.new(); n.multimesh = mm; n.material_override = m; caster(n); parent.add_child(n)
func light(parent: Node3D, pos: Vector3, col: Color, size: float = 0.5, blink: bool = false) -> MeshInstance3D:
	var g = sys.glow(parent, col, size, pos, 2.2, 1.6)
	if blink: blinkers.append([g, sys.rng.randf() * TAU, sys.rng.randf_range(1.4, 2.6)])
	return g
func spot(parent: Node3D, pos: Vector3, target: Vector3, col: Color, energy: float = 3.0, rng: float = 6.0) -> void:   # a work floodlight
	var s = SpotLight3D.new(); s.light_color = col; s.light_energy = energy; s.spot_range = rng; s.spot_angle = 32.0; s.spot_attenuation = 0.8
	s.shadow_enabled = false; parent.add_child(s)
	var dv = target - pos
	s.transform = Transform3D(Basis.looking_at(dv.normalized(), Vector3.UP if abs(dv.normalized().y) < 0.95 else Vector3.RIGHT) if dv.length() > 0.01 else Basis(), pos)
	light(parent, pos, col, 0.55)

# ---------------------------------------------------------------- the orbital station (about 7 units across)
func station(parent: Node3D, base: Color, accent: Color) -> Node3D:
	var root = Node3D.new(); parent.add_child(root)
	var hm = hull_mat(base, accent, 1.2, 0.12, 0.3)
	var hm2 = hull_mat(base.darkened(0.15), accent, 1.8, 0.04, 0.4)
	# the spindle and its modules
	part(root, cyl(0.3, 4.6), hm2)
	part(root, cyl(0.62, 0.8), hm, Vector3(0, 1.05, 0)); part(root, cyl(0.55, 0.6), hm, Vector3(0, -0.55, 0))
	part(root, sys.sphere(0.72, 32, 16), hm, Vector3(0, 0.3, 0))
	part(root, cyl(0.38, 0.5, 0.62), hm2, Vector3(0, 1.7, 0)); part(root, cyl(0.62, 0.5, 0.38), hm2, Vector3(0, -1.1, 0))
	# the habitat ring on four spokes
	var ring = Node3D.new(); ring.name = "ring"; ring.position = Vector3(0, 0.3, 0); root.add_child(ring)
	var t = TorusMesh.new(); t.inner_radius = 2.05; t.outer_radius = 2.45; t.rings = 96 if q > 0.5 else 48; t.ring_segments = 18 if q > 0.5 else 10
	part(ring, t, hull_mat(base, accent, 1.6, 0.2, 0.3))
	# greebles on the ring: small boxes (vents, hatches, conduit blocks) scattered over its outer face
	var gitems = []
	for i in (70 if q > 0.5 else 24):
		var ga = sys.rng.randf() * TAU; var gv = sys.rng.randf_range(-0.9, 0.9)
		var gp = Vector3(cos(ga) * (2.25 + 0.2 * cos(gv)), 0.2 * sin(gv), sin(ga) * (2.25 + 0.2 * cos(gv)))
		var gb = Basis(Vector3.UP, -ga) * Basis.from_scale(Vector3(sys.rng.randf_range(0.06, 0.16), sys.rng.randf_range(0.04, 0.08), sys.rng.randf_range(0.08, 0.24)))
		gitems.append([Transform3D(gb, gp), 0.0])
	caster(sys.scatter(ring, box(1, 1, 1), hull_mat(base.darkened(0.25), accent, 6.0, 0.0, 0.5), gitems))
	for i in 4:
		var a = i * TAU / 4.0 + TAU / 8.0
		beam(ring, Vector3(cos(a) * 0.7, 0, sin(a) * 0.7), Vector3(cos(a) * 2.1, 0, sin(a) * 2.1), 0.14, hm2)
		part(ring, box(0.5, 0.34, 0.5), hm, Vector3(cos(a) * 2.25, 0, sin(a) * 2.25), Vector3(0, -rad_to_deg(a), 0))   # ring modules
		light(ring, Vector3(cos(a) * 2.5, 0.12, sin(a) * 2.5), Color(1.0, 0.75, 0.4), 0.35, true)
	# docking arms at the top with their ports
	for i in 3:
		var a = i * TAU / 3.0
		var tip = Vector3(cos(a) * 1.5, 1.95, sin(a) * 1.5)
		beam(root, Vector3(0, 1.9, 0), tip, 0.12, hm2)
		part(root, cyl(0.16, 0.34), hm, tip + Vector3(0, 0.08, 0))
		light(root, tip + Vector3(0, 0.3, 0), Color(0.6, 0.85, 1.0), 0.32, true)
	# the antenna array on top (not a mast: a sensor spine with a dish and a sensor ring)
	part(root, cyl(0.035, 1.3), hm2, Vector3(0, 2.75, 0))
	part(root, cyl(0.42, 0.14, 0.06, 32), hm, Vector3(0, 2.45, 0), Vector3(180, 0, 0))
	light(root, Vector3(0, 3.45, 0), Color(1, 1, 1), 0.5, true)
	# solar arrays below on a truss, heat radiators between
	var y = -1.75
	truss(root, Vector3(-3.4, y, 0), Vector3(3.4, y, 0), 0.3, hm2)
	var sm = sys.mat("SOLAR")
	for sx in [-1.0, 1.0]:
		for k in 2:
			var cx = sx * (1.3 + k * 1.15)
			for sz in [-1.0, 1.0]:
				var pn = MeshInstance3D.new(); var pm = PlaneMesh.new(); pm.size = Vector2(1.05, 0.75); pn.mesh = pm; pn.material_override = sm
				pn.position = Vector3(cx, y, sz * 0.52); pn.rotation_degrees = Vector3(0, 0, 0); caster(pn); root.add_child(pn)
				var back = MeshInstance3D.new(); back.mesh = pm; back.material_override = hm2; back.position = pn.position + Vector3(0, -0.02, 0); back.rotation_degrees = Vector3(180, 0, 0); root.add_child(back)
		light(root, Vector3(sx * 3.5, y, 0), Color(1.0, 0.25, 0.2) if sx < 0 else Color(0.3, 1.0, 0.4), 0.42, true)
	var rm = sys.mat("RADIATOR", {"gain": 0.8})
	for sx in [-1.0, 1.0]:
		var rp = MeshInstance3D.new(); var rq = QuadMesh.new(); rq.size = Vector2(1.3, 0.9); rp.mesh = rq; rp.material_override = rm
		rp.position = Vector3(sx * 0.75, -0.55, 0); rp.rotation_degrees = Vector3(0, 90, 0); caster(rp); root.add_child(rp)
		var rp2 = MeshInstance3D.new(); rp2.mesh = rq; rp2.material_override = rm; rp2.position = rp.position; rp2.rotation_degrees = Vector3(0, -90, 0); root.add_child(rp2)
	return root

# ---------------------------------------------------------------- construction gantry (a slipway frame round a hull)
func gantry(parent: Node3D, L: float, H: float, W: float, base: Color, accent: Color) -> Node3D:
	var root = Node3D.new(); parent.add_child(root)
	var gm = hull_mat(base, accent, 5.0, 0.0, 0.55)
	var bays = 4 if q > 0.5 else 2
	for i in bays + 1:
		var x = -L * 0.5 + L * float(i) / bays
		truss(root, Vector3(x, 0, -W * 0.5), Vector3(x, H, -W * 0.5), 0.28, gm, 3)
		truss(root, Vector3(x, 0, W * 0.5), Vector3(x, H, W * 0.5), 0.28, gm, 3)
		truss(root, Vector3(x, H, -W * 0.5), Vector3(x, H, W * 0.5), 0.28, gm, 3)
	truss(root, Vector3(-L * 0.5, H, -W * 0.5), Vector3(L * 0.5, H, -W * 0.5), 0.28, gm)
	truss(root, Vector3(-L * 0.5, H, W * 0.5), Vector3(L * 0.5, H, W * 0.5), 0.28, gm)
	truss(root, Vector3(-L * 0.5, 0, -W * 0.5), Vector3(L * 0.5, 0, -W * 0.5), 0.28, gm)
	truss(root, Vector3(-L * 0.5, 0, W * 0.5), Vector3(L * 0.5, 0, W * 0.5), 0.28, gm)
	# a crane trolley on the top rails with its hoist
	var cx = sys.rng.randf_range(-L * 0.3, L * 0.3)
	part(root, box(0.5, 0.3, W + 0.3), hull_mat(accent.darkened(0.2), base, 2.5, 0.0, 0.3), Vector3(cx, H + 0.2, 0))
	beam(root, Vector3(cx, H, 0), Vector3(cx, H * 0.55, 0), 0.04, gm)
	# floodlights on the top corners onto the work, and amber warning lights
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			spot(root, Vector3(sx * L * 0.45, H, sz * W * 0.5), Vector3(0, H * 0.3, 0), Color(1.0, 0.93, 0.8), 2.5, H * 2.5)
	for i in 3: light(root, Vector3(-L * 0.5 + L * i / 2.0, H + 0.15, 0), Color(1.0, 0.6, 0.15), 0.35, true)
	return root
# welding sparks: small hot flickering points on the work
func sparks(parent: Node3D, center: Vector3, spread: float, n: int) -> void:
	for i in n:
		var p = center + Vector3(sys.rng.randf_range(-1, 1), sys.rng.randf_range(-0.4, 0.4), sys.rng.randf_range(-1, 1)) * spread
		var g = light(parent, p, Color(0.7, 0.85, 1.0), 0.45, true)
		blinkers[blinkers.size() - 1][2] = sys.rng.randf_range(0.25, 0.6)

# ---------------------------------------------------------------- dock frame (a closed lattice box round a docked hull)
func dock_frame(parent: Node3D, L: float, H: float, W: float, base: Color, accent: Color) -> Node3D:
	var root = Node3D.new(); parent.add_child(root)
	var gm = hull_mat(base, accent, 5.0, 0.0, 0.55)
	var xs = [-L * 0.5, L * 0.5]; var ys = [-H * 0.5, H * 0.5]; var zs = [-W * 0.5, W * 0.5]
	for y in ys:
		for z in zs: truss(root, Vector3(xs[0], y, z), Vector3(xs[1], y, z), 0.26, gm)
	for x in xs:
		for y in ys: truss(root, Vector3(x, y, zs[0]), Vector3(x, y, zs[1]), 0.26, gm, 2)
		for z in zs: truss(root, Vector3(x, ys[0], z), Vector3(x, ys[1], z), 0.26, gm, 2)
	# docking clamps reaching in from the frame
	for sx in [-0.25, 0.25]:
		for sz in [-1.0, 1.0]:
			beam(root, Vector3(sx * L, 0, sz * W * 0.5), Vector3(sx * L, 0, sz * W * 0.18), 0.12, gm)
	# work lights onto the hull, a module with lit windows on one side
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			spot(root, Vector3(sx * L * 0.42, sy * H * 0.5, -W * 0.5), Vector3(0, 0, 0), Color(0.75, 1.0, 0.95), 2.2, L * 1.2)
	part(root, box(L * 0.3, H * 0.35, 0.5), hull_mat(base, accent, 2.2, 0.3, 0.3), Vector3(0, H * 0.5 + 0.3, -W * 0.5))
	return root

# ---------------------------------------------------------------- repair drones
func drone(parent: Node3D, col: Color, base: Color) -> Node3D:
	var d = Node3D.new(); parent.add_child(d)
	var hm = hull_mat(base.lightened(0.15), col, 4.0, 0.0, 0.3)
	part(d, box(0.26, 0.1, 0.34), hm)
	for sx in [-1.0, 1.0]:
		part(d, box(0.04, 0.04, 0.22), hm, Vector3(sx * 0.17, 0, 0.12), Vector3(0, sx * 20.0, 0))   # manipulator arms
		part(d, cyl(0.05, 0.06), hm, Vector3(sx * 0.15, 0, -0.16), Vector3(90, 0, 0))   # thrusters
	light(d, Vector3(0, 0.07, 0), col, 0.42, true)
	return d

# ---------------------------------------------------------------- asteroids: real displaced meshes with craters
# An icosphere, subdivided, pushed by layered noise, with crater bowls and raised rims; COLOR.r carries crater depth.
func _icosphere(sub: int) -> Array:
	var t = (1.0 + sqrt(5.0)) / 2.0
	var v = [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0), Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t), Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	for i in v.size(): v[i] = v[i].normalized()
	var f = [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	for s in sub:
		var mid = {}; var nf = []
		var m = func(a: int, b: int) -> int:
			var k = str(min(a, b)) + "_" + str(max(a, b))
			if mid.has(k): return mid[k]
			v.append(((v[a] + v[b]) * 0.5).normalized()); mid[k] = v.size() - 1; return v.size() - 1
		for tri in f:
			var a = m.call(tri[0], tri[1]); var b = m.call(tri[1], tri[2]); var c = m.call(tri[2], tri[0])
			nf += [[tri[0], a, c], [tri[1], b, a], [tri[2], c, b], [a, b, c]]
		f = nf
	return [v, f]
func rock_meshes() -> Array:
	var key = "hi" if q > 0.5 else "lo"
	if _rock_cache.has(key): return _rock_cache[key]
	var out = []
	var base = _icosphere(3 if q > 0.5 else 2)
	for variant in 6:
		var r = RandomNumberGenerator.new(); r.seed = 9100 + variant * 31
		var nz = FastNoiseLite.new(); nz.seed = 77 + variant; nz.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH; nz.frequency = 1.1
		nz.fractal_type = FastNoiseLite.FRACTAL_FBM; nz.fractal_octaves = 5
		var el = Vector3(r.randf_range(0.8, 1.4), r.randf_range(0.6, 0.95), r.randf_range(0.75, 1.15))
		var craters = []
		for i in r.randi_range(5, 11): craters.append([Vector3(r.randfn(), r.randfn(), r.randfn()).normalized(), r.randf_range(0.18, 0.5), r.randf_range(0.05, 0.14)])
		var vs = []; var cd = []
		for p in base[0]:
			var dirv: Vector3 = p
			var k = 1.0 + nz.get_noise_3dv(dirv * 1.3) * 0.32 + nz.get_noise_3dv(dirv * 4.0 + Vector3(9, 1, 3)) * 0.07
			var dep = 0.0
			for c in craters:
				var ang = acos(clamp(dirv.dot(c[0]), -1.0, 1.0)); var u = ang / c[1]
				if u < 1.35:
					var bowl = (1.0 - u * u) if u < 1.0 else 0.0
					var rim = exp(-pow((u - 1.0) / 0.18, 2.0)) * 0.35
					k += (-bowl + rim) * c[2]; dep = max(dep, bowl)
			vs.append(dirv * k * el); cd.append(dep)
		var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in vs.size():
			st.set_color(Color(cd[i], 0, 0)); st.add_vertex(vs[i])
		for tri in base[1]:
			st.add_index(tri[0]); st.add_index(tri[2]); st.add_index(tri[1])
		st.generate_normals()
		out.append(st.commit())
	_rock_cache[key] = out
	return out
func rock_mat(kind: int) -> ShaderMaterial:
	var tints = [Color(0.36, 0.33, 0.31), Color(0.33, 0.32, 0.32), Color(0.55, 0.6, 0.66)]
	return sys.mat("ROCK_HI", {"tint": tints[kind % 3], "kind": float(kind % 3), "q": q})
# an asteroid field along the sun orbit through a stop, a few big rocks at the stop itself
func belt(parent: Node3D, theta: float, r: float, node_pos: Vector3, kind: int) -> void:
	var meshes = rock_meshes(); var m = rock_mat(kind)
	var n = 90 if q > 0.5 else 30
	for k in meshes.size():
		var items = []
		for i in n / meshes.size():
			var a = theta + sys.rng.randfn() * (5.0 / r) * 1.4; var rr = r + sys.rng.randfn() * 1.5
			var p = Vector3(cos(a) * rr, sys.rng.randfn() * 0.45 + 0.7, -sin(a) * rr) - node_pos
			var s = pow(sys.rng.randf(), 2.2) * 0.38 + 0.06
			items.append([Transform3D(sys.rand_basis(s), p), 0.0])
		if k < 3:   # the big ones at the stop
			items.append([Transform3D(sys.rand_basis(sys.rng.randf_range(0.7, 1.15)), Vector3(sys.rng.randf_range(-1.8, 1.8), sys.rng.randf_range(0.8, 2.0), sys.rng.randf_range(-1.4, 1.4))), 0.0])
		var mm = sys.scatter(parent, meshes[k], m, items)
		caster(mm)
