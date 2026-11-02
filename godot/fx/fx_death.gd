extends RefCounted
# Ship deaths, drifting wrecks and the physics behind them, plus the shared hull decorations (scorch decals, breach
# holes, bent plates, venting plumes, debris bodies). Static functions; the state lives in fx.dstate.
#
# Capitals lose power, vent along a thermal tear, split into two sealed halves,
# then flash once. Small hulls spin with a pooled smoke/fire ribbon before breaking.
# Triangle buckets and recessed boundary caps are prepared on a worker before death;
# the wrecks drift, tumble and cool. No worker wait blocks a death frame.

const SH := preload("res://fx/fx_shaders.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const HULL := preload("res://fx/fx_hull.gd")

const HULL_LAYER := 1
const DEBRIS_LAYER := 2
const DEBRIS_CAP := 360
const DEBRIS_VARIANTS := 4
const WRECK_COOL := 14.0

const SLAG := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
global uniform float fx_gain;
uniform float heat = 1.0;
varying vec3 slag_p;
varying vec2 slag_band;
void vertex() { slag_p = VERTEX; slag_band = COLOR.rg; }
float grain(vec3 p) { return fract(sin(dot(floor(p), vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
void fragment() {
	float n = grain(slag_p * 31.0);
	float coarse = 0.5 + 0.25 * sin(dot(slag_p, vec3(8.7, 3.1, 6.3))) * sin(dot(slag_p, vec3(2.3, 12.1, 4.7)));
	float band = clamp(slag_band.x, 0.0, 1.0);
	vec3 base = mix(vec3(0.025, 0.017, 0.012), vec3(0.006, 0.004, 0.003), band) * (0.55 + coarse * 0.65 + n * 0.25);
	float rim = clamp(slag_band.y, 0.0, 1.0) * smoothstep(0.35, 0.8, n);
	float hot = clamp(heat, 0.0, 1.0);
	ALBEDO = clamp(base + vec3(0.9, 0.19, 0.025) * rim * hot * hot * 0.65 * fx_gain
		+ vec3(0.08, 0.013, 0.002) * smoothstep(0.985, 1.0, n) * hot, 0.0, 1.0);
}
"""

const DEBRIS_BODY := """
shader_type spatial;
render_mode cull_disabled;
global uniform float scene_t;
global uniform float fx_gain;
instance uniform float spawn_t = -100.0;
varying vec3 lp;
float eh(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float en(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(eh(i), eh(i + vec3(1.0, 0.0, 0.0)), f.x), mix(eh(i + vec3(0.0, 1.0, 0.0)), eh(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(eh(i + vec3(0.0, 0.0, 1.0)), eh(i + vec3(1.0, 0.0, 1.0)), f.x), mix(eh(i + vec3(0.0, 1.0, 1.0)), eh(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}
varying float rim;
void vertex() { lp = VERTEX; rim = COLOR.r; }
void fragment() {
	// torn plate: sooty bare metal with a little grain; only parts of its torn rim glow, briefly (r3 verdict: no ember
	// speckle over the whole face; r5: a rim glowing all the way round outlined every plate like a cartoon, and a
	// mirror-smooth face caught the sky, so the glow now breaks along the edge and the face is rough and sooty)
	float g = en(lp * 9.0);
	float soot = smoothstep(0.3, 0.7, en(lp * 3.0 + 7.0));
	ALBEDO = mix(vec3(0.11, 0.105, 0.1), vec3(0.025, 0.023, 0.021), soot) * (0.8 + 0.4 * g);
	METALLIC = mix(0.5, 0.2, soot);
	ROUGHNESS = mix(0.62, 0.92, soot);
	float warm = exp(-max(scene_t - spawn_t, 0.0) / 0.55);
	float seg = smoothstep(0.5, 0.7, en(lp * 5.0 + 3.0));
	float edge = smoothstep(0.85, 1.0, rim) * seg * (0.6 + 0.4 * g);
	EMISSION = vec3(1.0, 0.34, 0.05) * edge * warm * 1.3 * fx_gain;
}
"""


# ---------------------------------------------------------------- setup

static func setup_physics(fx) -> void:
	var st: Dictionary = fx.dstate
	st["bounce"] = PhysicsMaterial.new()
	(st["bounce"] as PhysicsMaterial).bounce = 0.4
	(st["bounce"] as PhysicsMaterial).friction = 0.4
	var sh = Shader.new()
	sh.code = DEBRIS_BODY
	var m = ShaderMaterial.new()
	m.shader = sh
	st["debris_mat"] = m
	st["debris_shapes"] = []
	st["debris_meshes"] = []
	var r = RandomNumberGenerator.new()
	r.seed = 77
	# three sizes, four torn shapes each (r5: three meshes in all made every plate the same hexagon)
	for sz in [0.45, 0.8, 1.2]:
		var shapes: Array = []
		var meshes: Array = []
		for v in DEBRIS_VARIANTS:
			var sm = shard_mesh(r, sz)
			shapes.append(safe_convex(sm[1]))
			meshes.append(sm[0])
		st["debris_shapes"].append(shapes)
		st["debris_meshes"].append(meshes)
	st["debris"] = []
	st["debris_next"] = 0
	st["wrecks"] = []
	st["physics_on"] = fx.quality != "low"


# ---------------------------------------------------------------- hull decorations

static func vent_volume(fx, parent: Node3D, p: Vector3, n: Vector3, hole: float, seed_v: float) -> Node3D:
	var box = MeshInstance3D.new()
	box.name = "fx_vent"
	var bm = BoxMesh.new()
	bm.size = Vector3.ONE
	box.mesh = bm
	var m: ShaderMaterial = fx.mat(SH.VOL, 2)
	m.set_shader_parameter("vtype", 1.0)
	m.set_shader_parameter("P", Vector4(0.6, 1.0, seed_v, 0.3))
	box.material_override = m
	box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var y = n.normalized()
	var x = y.cross(Vector3(0, 0, 1) if absf(y.z) < 0.9 else Vector3(1, 0, 0)).normalized()
	var z = x.cross(y)
	box.transform = Transform3D(Basis(x, y, z).scaled_local(Vector3(hole * 2.4, hole * 6.0, hole * 2.4)), p + n * (hole * 3.0 - 0.1))
	parent.add_child(box)
	return box


# A raymarched fireball rolling into smoke (max), freed when done.
static func fireball(fx, p: Vector3, size: float, t0: float, life: float, tint: Color) -> void:
	if fx.quality != "max":
		return
	var box = MeshInstance3D.new()
	box.name = "fx_fireball"
	var bm = BoxMesh.new()
	bm.size = Vector3.ONE
	box.mesh = bm
	var m: ShaderMaterial = fx.mat(SH.VOL, 2)
	m.set_shader_parameter("vtype", 0.0)
	m.set_shader_parameter("t0", t0)
	m.set_shader_parameter("life", life)
	m.set_shader_parameter("P", Vector4(0.0, 1.0, fx.rng.randf() * 10.0, 0.16 * 44.0 / maxf(size * 1.3, 1.0)))
	m.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	box.material_override = m
	box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	box.position = p
	box.scale = Vector3.ONE * size * 1.3
	fx.add_child(box)
	fx.later(t0 + life + 0.1, func() -> void:
		if is_instance_valid(box):
			box.queue_free())


# ---------------------------------------------------------------- debris bodies (Jolt)

static func shard_mesh(rng: RandomNumberGenerator, size: float) -> Array:
	# a torn plate: a ragged outline (notches and teeth, stretched along one axis), creased once so it reads bent
	var n = rng.randi_range(9, 13)
	var ring_pts: Array = []
	var angs: Array = []
	for i in n:
		angs.append(TAU * (i + rng.randf_range(-0.35, 0.35)) / n)
	angs.sort()
	var stretch := rng.randf_range(1.2, 1.9)
	for i in angs.size():
		var a: float = angs[i]
		var r = size * rng.randf_range(0.3, 0.6) * (0.62 if (i % 3 == 1 and rng.randf() < 0.7) else 1.0)
		ring_pts.append(Vector2(cos(a) * r * stretch, sin(a) * r))
	var th = size * rng.randf_range(0.05, 0.1)
	var crease := rng.randf_range(-0.2, 0.25) * size
	var bend := rng.randf_range(0.3, 0.9) * (1.0 if rng.randf() < 0.5 else -1.0)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts = PackedVector3Array()
	for side in [1.0, -1.0]:
		var y: float = th * 0.5 * side
		for i in n:
			var a2: Vector2 = ring_pts[i]
			var b2: Vector2 = ring_pts[(i + 1) % n]
			var tri = [Vector3(0, y, 0), Vector3(a2.x, y, a2.y), Vector3(b2.x, y, b2.y)]
			if side < 0.0:
				tri = [tri[0], tri[2], tri[1]]
			for k in 3:
				# vertex colour: 0 at the plate's middle, 1 on its torn rim (the debris shader glows only the rim)
				st.set_color(Color.BLACK if tri[k].x == 0.0 and tri[k].z == 0.0 else Color.WHITE)
				st.add_vertex(_fold(tri[k], crease, bend))
		for v in ring_pts:
			pts.append(_fold(Vector3(v.x, y, v.y), crease, bend))
	for i in n:
		var a3: Vector2 = ring_pts[i]
		var b3: Vector2 = ring_pts[(i + 1) % n]
		var q = [Vector3(a3.x, th * 0.5, a3.y), Vector3(b3.x, th * 0.5, b3.y), Vector3(b3.x, -th * 0.5, b3.y), Vector3(a3.x, -th * 0.5, a3.y)]
		for tri in [[q[0], q[2], q[1]], [q[0], q[3], q[2]]]:
			for v in tri:
				st.set_color(Color.WHITE)
				st.add_vertex(_fold(v, crease, bend))
	st.generate_normals()
	return [st.commit(), pts]


# Bend a plate along the line x = crease (the part past it lifts by `bend` per unit), as torn plating folds.
static func _fold(v: Vector3, crease: float, bend: float) -> Vector3:
	var d := v.x - crease
	if d <= 0.0:
		return v
	var c := cos(bend)
	var s := sin(bend)
	return Vector3(crease + d * c - v.y * s, d * s + v.y * c, v.z)


static func spawn_debris(fx, pos: Vector3, vel: Vector3, count: int, size: float) -> void:
	var t0 := Time.get_ticks_usec()
	_spawn_debris_inner(fx, pos, vel, count, size)
	fx.pend("debris", t0)


static func _spawn_debris_inner(fx, pos: Vector3, vel: Vector3, count: int, size: float) -> void:
	var st: Dictionary = fx.dstate
	if not bool(st.get("physics_on", false)) or count <= 0:
		return
	var pool: Array = st["debris"]
	var sc = 0 if size < 0.3 * fx.unit else (1 if size < 0.6 * fx.unit else 2)
	for i in count:
		var b: RigidBody3D
		if pool.size() < DEBRIS_CAP:
			b = RigidBody3D.new()
			b.gravity_scale = 0.0
			b.mass = 0.3 + 0.4 * sc
			b.angular_damp = 0.05
			b.linear_damp = 0.02
			b.collision_layer = DEBRIS_LAYER
			b.collision_mask = HULL_LAYER | DEBRIS_LAYER
			b.physics_material_override = st["bounce"]
			var vi: int = fx.rng.randi() % DEBRIS_VARIANTS
			var cs = CollisionShape3D.new()
			cs.shape = st["debris_shapes"][sc][vi]
			b.add_child(cs)
			var mi = MeshInstance3D.new()
			mi.name = "mesh"
			mi.mesh = st["debris_meshes"][sc][vi]
			mi.material_override = st["debris_mat"]
			b.add_child(mi)
			fx.phys_root.add_child(b)
			pool.append(b)
		else:
			b = pool[int(st["debris_next"])]
			st["debris_next"] = (int(st["debris_next"]) + 1) % DEBRIS_CAP
		var d: Vector3 = fx.rdir()
		b.global_transform = Transform3D(Basis(d, fx.rng.randf() * TAU), pos + d * 0.3 * fx.unit)
		b.linear_velocity = vel + d * (2.0 + fx.rng.randf() * 4.0) * fx.unit
		b.angular_velocity = Vector3(fx.rng.randf_range(-6, 6), fx.rng.randf_range(-6, 6), fx.rng.randf_range(-6, 6))
		b.sleeping = false
		b.visible = true
		(b.get_node("mesh") as GeometryInstance3D).set_instance_shader_parameter("spawn_t", fx.now)


# A convex collider Jolt can always build (G2 bot runs: a 900-point hull failed and logged an error). The point cloud is
# cleaned (no NaN or infinite points), cut down to the extreme points along 50 fixed directions (at most 50 points, the
# hull's shape kept), and checked for flat or tiny input; anything degenerate gets its (thickened) bounding box instead.
const _HULL_DIRS := 50
static var _dirs: PackedVector3Array = PackedVector3Array()


# F3 perf: each piece's centre and its collider points (at most _HULL_DIRS extreme points), worked out on the cut's
# worker thread; the break-up used to do this in GDScript on the main thread for every vertex of every piece.
static func _piece_hulls(pieces: Array) -> void:
	for pc in pieces:
		var pts: PackedVector3Array = pc["pts"]
		var cen := Vector3.ZERO
		for p in pts:
			cen += p
		cen /= maxf(pts.size(), 1)
		pc["cen"] = cen
		var hp := _extreme_points(pts)
		for i in hp.size():
			hp[i] -= cen
		pc["hull"] = hp


static func _init_dirs() -> void:
	if not _dirs.is_empty():
		return
	# Fibonacci sphere: evenly spread directions
	var d := PackedVector3Array()
	for i in _HULL_DIRS:
		var y := 1.0 - 2.0 * (float(i) + 0.5) / _HULL_DIRS
		var rr := sqrt(maxf(0.0, 1.0 - y * y))
		var a := float(i) * 2.399963
		d.append(Vector3(cos(a) * rr, y, sin(a) * rr))
	_dirs = d


# The finite points of src that are extreme along any of the fixed directions (thread-safe once _init_dirs has run).
static func _extreme_points(src: PackedVector3Array) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for p in src:
		if is_finite(p.x) and is_finite(p.y) and is_finite(p.z):
			pts.append(p)
	if pts.size() <= 4:
		return pts
	var keep := {}
	for d in _dirs:
		var bi := 0
		var bd := -INF
		for i in pts.size():
			var k := pts[i].dot(d)
			if k > bd:
				bd = k
				bi = i
		keep[bi] = true
	var out := PackedVector3Array()
	for i in keep:
		out.append(pts[i])
	return out


static func safe_convex(src: PackedVector3Array) -> Shape3D:
	_init_dirs()
	var out := _extreme_points(src)
	if out.is_empty():
		var b0 := BoxShape3D.new()
		b0.size = Vector3.ONE * 0.1
		return b0
	var lo := out[0]
	var hi := out[0]
	for p in out:
		lo = lo.min(p)
		hi = hi.max(p)
	var ext := hi - lo
	var size := maxf(ext.x, maxf(ext.y, ext.z))
	# degenerate (a point, a line or a flat sheet): a box from the bounds, never thinner than 2% of the largest side
	var flat := out.size() < 4 or size < 1e-4
	if not flat:
		var a0 := out[0]
		var a1 := a0
		for p in out:
			if p.distance_squared_to(a0) > a1.distance_squared_to(a0):
				a1 = p
		var ax := (a1 - a0).normalized()
		var a2 := a0
		var bd2 := 0.0
		for p in out:
			var w := p - a0
			var dl := (w - ax * w.dot(ax)).length_squared()
			if dl > bd2:
				bd2 = dl
				a2 = p
		var nrm := (a1 - a0).cross(a2 - a0)
		if nrm.length_squared() < 1e-12 or sqrt(bd2) < size * 0.01:
			flat = true
		else:
			nrm = nrm.normalized()
			var off := 0.0
			for p in out:
				off = maxf(off, absf((p - a0).dot(nrm)))
			flat = off < size * 0.01
	if flat:
		# the bounds as an eight-corner hull, so it sits where the points are (a BoxShape3D is centred on the origin)
		var t := (ext.max(Vector3.ONE * maxf(size * 0.02, 0.05)) - ext) * 0.5
		var l2 := lo - t
		var h2 := hi + t
		var bx := ConvexPolygonShape3D.new()
		bx.points = PackedVector3Array([Vector3(l2.x, l2.y, l2.z), Vector3(h2.x, l2.y, l2.z), Vector3(l2.x, h2.y, l2.z), Vector3(h2.x, h2.y, l2.z),
			Vector3(l2.x, l2.y, h2.z), Vector3(h2.x, l2.y, h2.z), Vector3(l2.x, h2.y, h2.z), Vector3(h2.x, h2.y, h2.z)])
		return bx
	var cs := ConvexPolygonShape3D.new()
	cs.points = out
	return cs


# One convex collider per live ship (from its visible hull samples) riding the root, so debris bounces off hulls.
static func add_collider(fx, s) -> void:
	if not bool(fx.dstate.get("physics_on", false)) or s.hull.sp.size() < 8:
		return
	var shape: Shape3D = safe_convex(s.hull.sp)
	var body = AnimatableBody3D.new()
	body.name = "fx_collider"
	body.sync_to_physics = false
	body.collision_layer = HULL_LAYER
	body.collision_mask = 0
	body.physics_material_override = fx.dstate["bounce"]
	var cs = CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	s.root.add_child(body)
	s.set_meta("collider", body)


# ---------------------------------------------------------------- cutting the hull (worker thread)

# Seeds along the length (ship frame); cut: two pieces either side of a slanted plane.
static func seeds_for(s, cause: String, r: RandomNumberGenerator) -> PackedVector3Array:
	var h = s.hull
	var n = [1, 2, 3, 4, 5][clampi(s.weight, 0, 4)]
	if cause == "big" or cause == "flay":
		n = mini(n + 1, 7)
	if cause == "melt" or cause == "dark":
		n = maxi(2, n - 1)
	var out = PackedVector3Array()
	if cause == "cut":
		var nrm = Vector3(1.0, r.randf_range(-0.5, 0.5), r.randf_range(-0.6, 0.6)).normalized()
		var at = h.c + Vector3((r.randf() - 0.5) * 0.3 * h.L, 0, 0)
		out.append(at + nrm * h.L * 0.25)
		out.append(at - nrm * h.L * 0.25)
		return out
	for i in n:
		var u = (i + 0.5) / n + (r.randf() - 0.5) * 0.5 / n
		out.append(Vector3(h.box.position.x + u * h.L, h.c.y + (r.randf() - 0.5) * h.H * 0.6, h.c.z + (r.randf() - 0.5) * h.W * 0.6))
	return out


# Gather the hull's surfaces on the main thread (mesh arrays come from the rendering server), then cut on a worker.
static func precompute(fx, s, cause := "blast") -> void:
	if s.weight <= 0 or s.has_meta("cut_task") or s.has_meta("cut_job"):
		return
	if not is_instance_valid(s.root) or not s.root.is_inside_tree():
		return   # F3: the ship's node was freed before its staggered cut came round
	if s.death_big:
		cause = "cut"  # two prepared halves, and the vents/crack use this same bisector
	var r = RandomNumberGenerator.new()
	r.seed = hash(s.id) + 3
	var seeds = seeds_for(s, cause, r)
	var inv: Transform3D = s.root.global_transform.affine_inverse()
	var surfs: Array = []
	for m in s.meshes:
		var mi = m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf = inv * mi.global_transform
		for si in mi.mesh.get_surface_count():
			var mat: Material = mi.get_active_material(si)
			surfs.append({"arrays": s.current_arrays(mi, si), "xf": xf, "mat": mat, "fmt": (mi.mesh as ArrayMesh).surface_get_format(si) if mi.mesh is ArrayMesh else 0})
	var job = {"seeds": seeds, "surfs": surfs, "cause": cause, "out": null}
	s.set_meta("cut_job", job)
	_init_dirs()
	var tid = WorkerThreadPool.add_task(func() -> void:
		var pieces := _cut(job)
		_piece_hulls(pieces)
		job["out"] = pieces)
	s.set_meta("cut_task", tid)
	fx.later(fx.now + 0.5, func() -> void: _prebuild(fx, s))


static func _collect_later(fx, tid: int) -> void:
	if WorkerThreadPool.is_task_completed(tid):
		WorkerThreadPool.wait_for_task_completion(tid)
		return
	fx.later(fx.now + 0.25, func() -> void: _collect_later(fx, tid))


# When the cut is done, upload the pieces' meshes while the battle is quiet, so the break-up itself only shows them
# (the first break-up cost a 35 ms frame when it built them on the spot).
static func _prebuild(fx, s) -> void:
	if not s.has_meta("cut_task") or s.has_meta("death_hidden"):
		return
	var tid: int = s.get_meta("cut_task")
	if not WorkerThreadPool.is_task_completed(tid):
		fx.later(fx.now + 0.5, func() -> void: _prebuild(fx, s))
		return
	WorkerThreadPool.wait_for_task_completion(tid)
	s.remove_meta("cut_task")
	var job: Dictionary = s.get_meta("cut_job", {})
	var t0 := Time.get_ticks_usec()
	var meshes: Array = []
	for pc in job.get("out", []) if job.get("out") != null else []:
		meshes.append(_piece_mesh(pc))
	job["meshes"] = meshes
	fx.pend("piece_meshes", t0)


# Hull attributes keep their vertex format; private damage materials add burnt backs.
# The opaque slag surface is built here with the piece, before death when possible.
static func _piece_mesh(pc: Dictionary) -> ArrayMesh:
	var am = ArrayMesh.new()
	for sd in pc["surfs"]:
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, sd["arrays"], [], {}, int(sd.get("fmt", 0)) & Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)
		var hull_mat := HULL.damage_material(sd["mat"], Transform3D.IDENTITY, {}, 1.0)
		hull_mat.set_shader_parameter("fx_power", 0.0)
		am.surface_set_material(am.get_surface_count() - 1, hull_mat)
	if pc.has("cap"):
		var mat := ShaderMaterial.new()
		mat.shader = HULL.shared_shader(SLAG)
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, pc["cap"])
		am.surface_set_material(am.get_surface_count() - 1, mat)
		pc["cap_mat"] = mat
	return am


static func _cut(job: Dictionary) -> Array:
	var seeds: PackedVector3Array = job["seeds"]
	var ns = seeds.size()
	var pieces: Array = []
	for c in ns:
		pieces.append({"surfs": [], "pts": PackedVector3Array(), "edge": PackedVector3Array(), "n": 0})
	for sd in job["surfs"]:
		var arr: Array = sd["arrays"]
		var xf: Transform3D = sd["xf"]
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var vl = xf * v
		# a mirrored hull (negative determinant) turns its triangles inside out: flip the winding back
		var flip = xf.basis.determinant() < 0.0
		var idx = PackedInt32Array()
		if arr[Mesh.ARRAY_INDEX] != null and (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() > 0:
			idx = arr[Mesh.ARRAY_INDEX]
		else:
			idx.resize(v.size())
			for i in v.size():
				idx[i] = i
		var buckets: Array = []
		for c in ns:
			buckets.append(PackedInt32Array())
		for t in range(0, idx.size() - 2, 3):
			var a = idx[t]
			var b = idx[t + 1]
			var cc = idx[t + 2]
			var q = (vl[a] + vl[b] + vl[cc]) / 3.0
			var best = 0
			var bd = 1e18
			var bd2 = 1e18
			for c in ns:
				var dd = q.distance_squared_to(seeds[c])
				if dd < bd:
					bd2 = bd
					bd = dd
					best = c
				elif dd < bd2:
					bd2 = dd
			buckets[best].append(a)
			buckets[best].append(cc if flip else b)
			buckets[best].append(b if flip else cc)
			var pc: Dictionary = pieces[best]
			if (pc["edge"] as PackedVector3Array).size() < 64 and sqrt(bd2) - sqrt(bd) < 0.6:
				(pc["edge"] as PackedVector3Array).append(q)
		for c in ns:
			var tri: PackedInt32Array = buckets[c]
			if tri.is_empty():
				continue
			var remap = PackedInt32Array()
			remap.resize(v.size())
			remap.fill(-1)
			var order = PackedInt32Array()
			var nidx = PackedInt32Array()
			nidx.resize(tri.size())
			for i in tri.size():
				var o = tri[i]
				var m = remap[o]
				if m < 0:
					m = order.size()
					remap[o] = m
					order.append(o)
				nidx[i] = m
			var na = []
			na.resize(Mesh.ARRAY_MAX)
			var pv = PackedVector3Array()
			pv.resize(order.size())
			for i in order.size():
				pv[i] = vl[order[i]]
			na[Mesh.ARRAY_VERTEX] = pv
			if arr[Mesh.ARRAY_NORMAL] != null and (arr[Mesh.ARRAY_NORMAL] as PackedVector3Array).size() == v.size():
				var src: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
				var dn = PackedVector3Array()
				dn.resize(order.size())
				for i in order.size():
					dn[i] = (xf.basis * src[order[i]]).normalized()
				na[Mesh.ARRAY_NORMAL] = dn
			if arr[Mesh.ARRAY_TANGENT] != null and (arr[Mesh.ARRAY_TANGENT] as PackedFloat32Array).size() == v.size() * 4:
				var src4: PackedFloat32Array = arr[Mesh.ARRAY_TANGENT]
				var dt = PackedFloat32Array()
				dt.resize(order.size() * 4)
				for i in order.size():
					var o4 = order[i] * 4
					var tv = (xf.basis * Vector3(src4[o4], src4[o4 + 1], src4[o4 + 2])).normalized()
					dt[i * 4] = tv.x
					dt[i * 4 + 1] = tv.y
					dt[i * 4 + 2] = tv.z
					dt[i * 4 + 3] = src4[o4 + 3]
				na[Mesh.ARRAY_TANGENT] = dt
			for key in [Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2]:
				if arr[key] != null and (arr[key] as PackedVector2Array).size() == v.size():
					var s2: PackedVector2Array = arr[key]
					var d2 = PackedVector2Array()
					d2.resize(order.size())
					for i in order.size():
						d2[i] = s2[order[i]]
					na[key] = d2
			if arr[Mesh.ARRAY_COLOR] != null and (arr[Mesh.ARRAY_COLOR] as PackedColorArray).size() == v.size():
				var sc: PackedColorArray = arr[Mesh.ARRAY_COLOR]
				var dc = PackedColorArray()
				dc.resize(order.size())
				for i in order.size():
					dc[i] = sc[order[i]]
				na[Mesh.ARRAY_COLOR] = dc
			na[Mesh.ARRAY_INDEX] = nidx
			var pc: Dictionary = pieces[c]
			pc["surfs"].append({"arrays": na, "mat": sd["mat"], "fmt": int(sd.get("fmt", 0))})
			pc["n"] = int(pc["n"]) + order.size()
			var step = maxi(1, order.size() / 120)
			for i in range(0, order.size(), step):
				(pc["pts"] as PackedVector3Array).append(pv[i])
	for pc in pieces:
		_seal_piece(pc)
	return pieces


# Trace the actual welded boundary loops. Ear clipping uses boundary vertices only:
# no centre vertex, radial bands or centre-point ribs can show through as spokes.
static func _seal_piece(pc: Dictionary) -> void:
	var all_edges := {}
	var welds := {}
	var positions := PackedVector3Array()
	var bounds := AABB()
	var first := true
	for sd in pc["surfs"]:
		for p in sd["arrays"][Mesh.ARRAY_VERTEX]:
			if not (p as Vector3).is_finite(): continue
			if first:
				bounds = AABB(p, Vector3.ZERO)
				first = false
			else: bounds = bounds.expand(p)
	if first: return
	var quantum := maxf(bounds.size.length() * 0.000001, 0.000001)
	for sd in pc["surfs"]:
		var pts: PackedVector3Array = sd["arrays"][Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = sd["arrays"][Mesh.ARRAY_INDEX]
		var ids := PackedInt32Array()
		ids.resize(pts.size())
		ids.fill(-1)
		for i in pts.size():
			if not pts[i].is_finite(): continue
			var key := Vector3i((pts[i] / quantum).round())
			if not welds.has(key):
				welds[key] = positions.size()
				positions.append(pts[i])
			ids[i] = int(welds[key])
		for t in range(0, idx.size() - 2, 3):
			for j in 3:
				var ka := ids[idx[t + j]]
				var kb := ids[idx[t + (j + 1) % 3]]
				if ka < 0 or kb < 0 or ka == kb: continue
				var key := Vector2i(mini(ka, kb), maxi(ka, kb))
				if all_edges.has(key): all_edges.erase(key)
				else: all_edges[key] = true
	pc["boundary_edges"] = all_edges.size()
	var adj := {}
	for key in all_edges:
		for j in 2:
			if not adj.has(key[j]): adj[key[j]] = []
			adj[key[j]].append(key[1 - j])
	var remaining := all_edges.duplicate()
	var cap := {"v": PackedVector3Array(), "n": PackedVector3Array(), "c": PackedColorArray()}
	pc["cap_loops"] = 0
	pc["cap_fallbacks"] = 0
	for start in adj:
		var walk: Array = [start]
		while not walk.is_empty():
			var at: int = walk.back()
			var next := -1
			for other in adj[at]:
				var edge := Vector2i(mini(at, other), maxi(at, other))
				if remaining.has(edge):
					remaining.erase(edge)
					next = other
					break
			if next < 0:
				walk.pop_back()
				continue
			var seen := walk.find(next)
			if seen >= 0:
				var outline := PackedVector3Array()
				for j in range(seen, walk.size()): outline.append(positions[walk[j]])
				if outline.size() >= 3:
					_cap_outline(cap, outline, bounds, quantum, pc)
				walk.resize(seen + 1)
			else: walk.append(next)
	if not (cap["v"] as PackedVector3Array).is_empty():
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = cap["v"]
		arr[Mesh.ARRAY_NORMAL] = cap["n"]
		arr[Mesh.ARRAY_COLOR] = cap["c"]
		pc["cap"] = arr


static func _cap_outline(cap: Dictionary, outline: PackedVector3Array, bounds: AABB, quantum: float, pc: Dictionary) -> void:
	var centre := Vector3.ZERO
	for p in outline: centre += p
	centre /= outline.size()
	var normal := Vector3.ZERO
	var radius := 0.0
	for i in outline.size():
		normal += (outline[i] - centre).cross(outline[(i + 1) % outline.size()] - centre)
		radius = maxf(radius, outline[i].distance_to(centre))
	if normal.length_squared() < 1e-16:
		for i in range(1, outline.size() - 1):
			var n := (outline[i] - outline[0]).cross(outline[i + 1] - outline[0])
			if n.length_squared() > normal.length_squared(): normal = n
	if normal.length_squared() < 1e-20: return
	normal = normal.normalized()
	var inward := normal if normal.dot(bounds.get_center() - centre) >= 0.0 else -normal
	var x := normal.cross(Vector3.UP if absf(normal.y) < 0.9 else Vector3.RIGHT).normalized()
	var y := normal.cross(x)
	var polygon := PackedVector2Array()
	var inset := PackedVector3Array()
	var depth := minf(radius * 0.075, bounds.size.length() * 0.035)
	for p in outline:
		polygon.append(Vector2((p - centre).dot(x), (p - centre).dot(y)))
		# Only the narrow torn lip slopes. The whole face has one material band.
		var rough := sin(p.dot(Vector3(3.1, 5.7, 2.3))) * sin(p.dot(Vector3(8.3, 2.1, 4.7)))
		inset.append(p + (centre - p) * 0.018 + inward * depth * (1.0 + rough * 0.12))
	var indices := Geometry2D.triangulate_polygon(polygon)
	if indices.is_empty():
		# Imported non-planar/self-overlapping loops can fail 2D ear clipping.
		# A boundary-only zipper still seals them without a hub or radial spokes.
		pc["cap_fallbacks"] = int(pc["cap_fallbacks"]) + 1
		var lo := 0
		var hi := outline.size() - 1
		while hi - lo > 1:
			indices.append_array(PackedInt32Array([lo, lo + 1, hi]))
			lo += 1
			if hi - lo > 1:
				indices.append_array(PackedInt32Array([lo, hi - 1, hi]))
				hi -= 1
	for i in range(0, indices.size(), 3):
		_cap_tri(cap, inset[indices[i]], inset[indices[i + 1]], inset[indices[i + 2]], Color(0.9, 0.015, 0, 1))
	for i in outline.size():
		var j := (i + 1) % outline.size()
		_cap_tri(cap, outline[i], outline[j], inset[j], Color(0.25, 0.18, 0, 1))
		_cap_tri(cap, outline[i], inset[j], inset[i], Color(0.25, 0.18, 0, 1))
		# Sparse short, offset spars. Never connect them all to a common centre.
		if i % maxi(1, outline.size() / 4) == 0 and outline[i].distance_to(outline[j]) > quantum * 3.0:
			var a := outline[i].lerp(outline[j], 0.42) + inward * depth * 0.45
			var tangent := (outline[j] - outline[i]).normalized()
			_cap_rib(cap, a, a + tangent * radius * 0.12 + inward * depth * 0.35, -inward, maxf(radius * 0.012, quantum * 2.0))
	pc["cap_loops"] = int(pc["cap_loops"]) + 1


static func _cap_tri(cap: Dictionary, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var n := (b - a).cross(c - a)
	if not a.is_finite() or not b.is_finite() or not c.is_finite() or n.length_squared() < 1e-20: return
	n = n.normalized()
	cap["v"].append_array(PackedVector3Array([a, b, c]))
	cap["n"].append_array(PackedVector3Array([n, n, n]))
	cap["c"].append_array(PackedColorArray([color, color, color]))


static func _cap_rib(cap: Dictionary, a: Vector3, b: Vector3, n: Vector3, width: float) -> void:
	var along := b - a
	if along.length_squared() < 1e-12: return
	var side := along.normalized().cross(n) * width
	var lift := n * width * 1.8
	var p := [a - side, a + side, b + side, b - side, a - side + lift, a + side + lift, b + side + lift, b - side + lift]
	for f in [[0, 1, 2, 3], [4, 7, 6, 5], [0, 4, 5, 1], [1, 5, 6, 2], [2, 6, 7, 3], [3, 7, 4, 0]]:
		_cap_tri(cap, p[f[0]], p[f[1]], p[f[2]], Color(0.45, 0.1, 0, 1))
		_cap_tri(cap, p[f[0]], p[f[2]], p[f[3]], Color(0.45, 0.1, 0, 1))


# ---------------------------------------------------------------- the death

static func death(fx, s, cause: String) -> float:
	var t0 := Time.get_ticks_usec()
	var r = _death_inner(fx, s, cause)
	fx.pend("death", t0)
	return r


static func _death_inner(fx, s, cause: String) -> float:
	if s.dead: return 0.0
	s.dead = true
	var T: float = fx.now
	if s.has_meta("collider"):
		var cb: Node = s.get_meta("collider")
		if is_instance_valid(cb): cb.queue_free()
	var tint := Color(0.95, 0.34, 0.08) if cause != "melt" else Color(0.55, 0.65, 0.12)
	_power_down(s)
	s.set_meta("death_start", T)
	s.engine_level = 0.0
	# All heavy deaths use the same two prepared halves, regardless of damage cause.
	# Class decides this sequence and the R73 beat; draw scale does not.
	var split := 1.38 if s.death_big else (0.72 if s.weight > 0 else 0.55)
	s.set_meta("death_split", T + split)
	if not s.has_meta("cut_task") and not s.has_meta("cut_job"):
		precompute(fx, s, cause)
	if s.death_big:
		var job: Dictionary = s.get_meta("cut_job", {})
		var seeds: PackedVector3Array = job.get("seeds", PackedVector3Array())
		var at: Vector3 = s.hull.c
		var axis := Vector3.RIGHT
		if seeds.size() >= 2:
			at = (seeds[0] + seeds[1]) * 0.5
			axis = (seeds[0] - seeds[1]).normalized()
		_cracks(fx, s, T + 0.4, split - 0.4, tint, at, axis)
		# Ray samples lie on the actual hull at its future split, not on a floating line.
		var tangent := axis.cross(Vector3.UP if absf(axis.y) < 0.9 else Vector3.FORWARD).normalized()
		var up := axis.cross(tangent).normalized()
		for i in 10:
			var angle := TAU * i / 10.0
			var radial := tangent * cos(angle) + up * sin(angle)
			var hit: Dictionary = s.hull.ray(at + radial * s.hull.L * 1.5, -radial)
			if hit.is_empty(): continue
			var lp: Vector3 = hit["p"]
			var ln: Vector3 = hit["n"]
			fx.later(T + 0.25 + i * 0.045, func() -> void: _split_vent(fx, s, lp, ln))
		fx.later(T + split - 0.08, func() -> void: fx.death_slowmo())
	else:
		# Bounded pooled ribbon emissions follow the spinning hull each frame.
		s.set_meta("death_ribbon_next", T)
	fx.later(T + split, func() -> void: _break_up_when_ready(fx, s, cause, tint, T + split + 2.5))
	return split + 0.6


static func _power_down(s) -> void:
	var mats: Array = []
	var poses: Array = []
	var inv: Transform3D = s.root.global_transform.affine_inverse()
	for mesh in s.meshes:
		var mi := mesh as MeshInstance3D
		if not is_instance_valid(mi) or mi.mesh == null: continue
		poses.append({"mi": mi, "pose": inv * mi.global_transform})
		var prepared: Array = []
		for i in mi.mesh.get_surface_count():
			var source: Material = mi.get_active_material(i)
			var mat: ShaderMaterial
			if source is ShaderMaterial and source.has_meta("fx_hull_source"):
				mat = source.duplicate()
			else:
				mat = HULL.damage_material(source, inv * mi.global_transform, {}, s.hull.L)
			prepared.append(mat)
			mats.append(mat)
		mi.material_override = null
		for i in prepared.size(): mi.set_surface_override_material(i, prepared[i])
	s.set_meta("death_power", mats)
	s.set_meta("death_poses", poses)
	s._reacting = false
	s._shield_until = -1.0


static func _split_vent(fx, s, lp: Vector3, ln: Vector3) -> void:
	if not is_instance_valid(s.root) or s.has_meta("death_hidden"): return
	var p: Vector3 = s.to_world(lp)
	var n: Vector3 = s.dir_world(ln)
	var size: float = s.hull.L * 0.022
	for j in 3:
		fx.spr(p, fx.now + j * 0.09, 0.85, Color(0.24, 0.27, 0.3), 0.5,
			size * 0.3, size * 1.7, 7, n * size * 5.0, 0.8)
	fx.stk(p, fx.now, 0.65, Color(0.6, 0.22, 0.045), 1.5, size, size * 0.1, 1, n * size * 9.0, 1.2)


static func _update_dying(fx, s) -> void:
	if not s.dead or s.has_meta("death_hidden") or not s.has_meta("death_start") or not is_instance_valid(s.root): return
	var age: float = maxf(fx.now - float(s.get_meta("death_start")), 0.0)
	var power := 1.0 - smoothstep(0.0, 0.3, age)
	for m in s.get_meta("death_power", []):
		(m as ShaderMaterial).set_shader_parameter("fx_power", power)
	if s.death_big: return
	var rot := Basis.from_euler(Vector3(age * 1.4, age * 0.5, age * 0.85))
	var shift := Vector3(age * s.hull.L * 0.22, -age * s.hull.L * 0.06, 0)
	var motion := Transform3D(rot, shift + s.hull.c - rot * s.hull.c)
	for pose in s.get_meta("death_poses", []):
		if is_instance_valid(pose["mi"]):
			(pose["mi"] as Node3D).global_transform = s.root.global_transform * motion * (pose["pose"] as Transform3D)
	if fx.now >= float(s.get_meta("death_ribbon_next", INF)):
		s.set_meta("death_ribbon_next", fx.now + 0.045)
		var p: Vector3 = s.to_world(s.hull.c + Vector3(-s.hull.L * 0.3, 0, s.hull.W * 0.25))
		var size: float = maxf(s.hull.L * 0.09, 0.12)
		var back: Vector3 = -s.dir_world(Vector3.RIGHT)
		fx.spr(p, fx.now, 1.45, Color(0.17, 0.18, 0.2), 0.85, size * 0.5, size * 1.9, 3,
			back * s.hull.L * 1.1 + Vector3.UP * size * 0.35, 0.3, 0.0, 0.0, 48.0)
		fx.spr(p, fx.now, 0.32, Color(0.8, 0.23, 0.035), 1.8, size * 0.45, size * 0.15, 1,
			back * s.hull.L * 0.3, 0.0, 0.0, 0.0, 18.0)


# An unfinished worker never blocks the death frame, even past its nominal split time.
# A previous completed cut is usable immediately; otherwise hold the dark dying hull.
static func _break_up_when_ready(fx, s, cause: String, tint: Color, deadline: float) -> void:
	if not is_instance_valid(s.root) or fx.ships.get(s.id) != s:
		return
	if s.has_meta("cut_task") and not s.has_meta("cut_prev"):
		if not WorkerThreadPool.is_task_completed(int(s.get_meta("cut_task"))):
			fx.later(fx.now + 0.05, func() -> void: _break_up_when_ready(fx, s, cause, tint, deadline))
			return
	_break_up(fx, s, cause, tint)


# One thermal tear in ship coordinates, on the same bisector as the prepared halves.
static func _cracks(fx, s, t0: float, dur: float, tint: Color, at: Vector3, axis: Vector3) -> void:
	var m: ShaderMaterial = fx.mat(SH.CRACKS, 1)
	m.set_shader_parameter("t0", t0)
	m.set_shader_parameter("dur", maxf(dur, 0.3))
	m.set_shader_parameter("cut_at", at)
	m.set_shader_parameter("cut_axis", axis)
	m.set_shader_parameter("width", maxf(s.hull.L * 0.009, 0.01))
	m.set_shader_parameter("glow", Vector3(tint.r, tint.g, tint.b))
	for mm in s.meshes:
		if is_instance_valid(mm):
			var mi := mm as MeshInstance3D
			var local: ShaderMaterial = m.duplicate()
			local.set_shader_parameter("frame", s.root.global_transform.affine_inverse() * mi.global_transform)
			mi.material_overlay = local


static func _hide_ship(s) -> void:
	s.set_meta("death_hidden", true)
	s.remove_meta("death_power")
	s.remove_meta("death_poses")
	for m in s.meshes:
		if is_instance_valid(m):
			(m as Node3D).visible = false
	if is_instance_valid(s._eng_node):
		s._eng_node.visible = false
	if is_instance_valid(s._dmg_root):
		s._dmg_root.visible = false
	for sec in 3:
		s._clear_lights(sec)
	for l in s._hole_lights:
		l["on"] = false
	s._hole_lights = []
	for t in s._trails:
		if is_instance_valid(t["mi"]):
			(t["mi"] as Node3D).visible = false


static func _break_up(fx, s, cause: String, tint: Color) -> void:
	var t0 := Time.get_ticks_usec()
	_break_up_inner(fx, s, cause, tint)
	fx.pend("break_up", t0)


static func _break_up_inner(fx, s, cause: String, tint: Color) -> void:
	var T: float = fx.now
	var h = s.hull
	var w: int = s.weight
	var k: float = s.scale_k()
	var center: Vector3 = s.to_world(h.c)
	var job: Dictionary = s.get_meta("cut_job", {})
	if s.has_meta("cut_task"):
		var tid: int = int(s.get_meta("cut_task"))
		if not WorkerThreadPool.is_task_completed(tid) and s.has_meta("cut_prev"):
			# r18: a fresher cut is still running; break up along the last finished one (a little out of date, never a
			# stall) and collect the running task when it is done
			job = s.get_meta("cut_prev")
			_collect_later(fx, tid)
		else:
			WorkerThreadPool.wait_for_task_completion(tid)
		s.remove_meta("cut_task")
	var pieces: Array = job.get("out", []) if job.get("out") != null else []
	var seeds: PackedVector3Array = job.get("seeds", PackedVector3Array())
	var xf: Transform3D = s.xf()
	_hide_ship(s)
	# The break is visible first. One short, small core flash follows inside one half.
	# Smoke, ribbons and streamers carry the event; no long central fireball or haze.
	var R: float = h.L * 0.16
	var kp: float = 52.0 if not s.death_big else 68.0
	var core := center + xf.basis * Vector3(h.L * 0.12, 0, 0)
	var core_node: Node3D = null
	var core_local := Vector3.ZERO
	for i in (8 if not s.death_big else 14):
		var bv: Vector3 = fx.rdir() * (5.0 + fx.rng.randf() * 8.0) * maxf(k, 0.6)
		var life: float = 1.1 + fx.rng.randf() * 0.9
		fx.stk(center, T, life, Color(0.9, 0.32, 0.06), 2.0, 0.16, 0.09, 1, bv, 0.4, 0.0, 4.0, 24.0)
		for j in 4:
			fx.spr(center + bv * j * 0.09, T + j * 0.09, 1.2, Color(0.07, 0.075, 0.08), 0.45,
				R * 0.06, R * 0.18, 3, bv * 0.12, 0.6, 0.0, 0.0, 9.0)
	for i in 18 + w * 5:
		fx.stk(center, T + fx.rng.randf() * 0.12, 0.5 + fx.rng.randf(), Color(1, 0.4, 0.1), 2.2,
			0.06, 0.08, 1, fx.rdir() * (6.0 + fx.rng.randf() * 18.0) * maxf(k, 0.6), 0.65)
	spawn_debris(fx, center, Vector3.ZERO, 4 + w * 3, h.L * 0.025)
	fx.punch(T, 0.018 if s.death_big else 0.006, center)
	fx.shake(T, 0.45 if s.death_big else 0.18, center)
	# the pieces: real parts of the hull, as rigid bodies that drift and burn
	var wreck = {"id": s.id, "t0": T, "nodes": [], "mats": [], "lights": [], "fires": [], "speed": 1.0}
	var main_i = -1
	var main_n = -1
	for i in pieces.size():
		if int(pieces[i]["n"]) > main_n:
			main_n = int(pieces[i]["n"])
			main_i = i
	var phys = bool(fx.dstate.get("physics_on", false))
	for i in pieces.size():
		var pc: Dictionary = pieces[i]
		if (pc["surfs"] as Array).is_empty():
			continue
		var pre: Array = job.get("meshes", [])
		var am: ArrayMesh = pre[i] if i < pre.size() else _piece_mesh(pc)
		var cen: Vector3 = pc["cen"] if pc.has("cen") else Vector3.ZERO
		if not pc.has("cen"):
			for p in (pc["pts"] as PackedVector3Array):
				cen += p
			cen /= maxf((pc["pts"] as PackedVector3Array).size(), 1)
		var node: Node3D
		var is_main = i == main_i
		if phys:
			var rb = RigidBody3D.new()
			rb.gravity_scale = 0.0
			rb.mass = maxf(float(pc["n"]) / 400.0, 5.0)
			rb.linear_damp = 0.9 if is_main else 0.06
			rb.angular_damp = 0.4 if is_main else 0.04
			rb.collision_layer = DEBRIS_LAYER
			rb.collision_mask = HULL_LAYER | DEBRIS_LAYER
			rb.physics_material_override = fx.dstate["bounce"]
			var pts: PackedVector3Array = pc["hull"] if pc.has("hull") else PackedVector3Array()
			if not pc.has("hull"):
				for p in (pc["pts"] as PackedVector3Array):
					pts.append(p - cen)
			if pts.size() >= 4:
				var cs = CollisionShape3D.new()
				cs.shape = safe_convex(pts)
				rb.add_child(cs)
			node = rb
		else:
			node = Node3D.new()
		node.name = "fx_wreck_%s_%d" % [s.id, i]
		fx.phys_root.add_child(node)
		node.global_transform = Transform3D(xf.basis, xf * cen)
		if core_node == null and seeds.size() >= 2:
			core_node = node
			var axis := (seeds[0] - seeds[1]).normalized()
			# The recess opens toward the seam. Let light escape from the torn face
			# of this half, rather than burying its sprite behind an opaque hull.
			core_local = (seeds[0] + seeds[1]) * 0.5 - cen - axis * h.L * 0.01
		var mi = MeshInstance3D.new()
		mi.mesh = am
		mi.position = -cen
		node.add_child(mi)
		var cm: ShaderMaterial = fx.mat(SH.CHUNK, 1)
		var sv: Array = []
		for j in 8:
			sv.append(Vector4(seeds[j].x, seeds[j].y, seeds[j].z, 0) if j < seeds.size() else Vector4.ZERO)
		cm.set_shader_parameter("seeds", sv)
		cm.set_shader_parameter("n_seeds", seeds.size())
		cm.set_shader_parameter("me", i)
		cm.set_shader_parameter("width", h.L * 0.02)
		cm.set_shader_parameter("cell", Vector3(h.L * 0.07, h.L * 0.045, h.L * 0.06))
		cm.set_shader_parameter("glow", Vector3(tint.r, tint.g, tint.b))
		mi.material_overlay = cm
		wreck["mats"].append(cm)
		if pc.has("cap_mat"):
			wreck["mats"].append(pc["cap_mat"])
		wreck["nodes"].append(node)
		# motion: away from the centre, the main hulk barely moves (it stays on its hex as terrain)
		var out = (cen - h.c).normalized() if (cen - h.c).length() > 0.01 else fx.rdir()
		var spd: float = (0.7 if is_main else 2.1) * maxf(k, 0.5)
		var vel: Vector3 = xf.basis * (out * spd) + fx.rdir() * 0.3 * k
		if cause == "tidal" and fx.well != Vector3.INF:
			vel += (fx.well - center).normalized() * 3.0 * k
		var ang: Vector3 = fx.rdir() * ((0.22 if is_main else 0.35) if s.death_big else (1.1 if is_main else 1.6))
		if node is RigidBody3D:
			(node as RigidBody3D).linear_velocity = vel
			(node as RigidBody3D).angular_velocity = ang
		else:
			wreck["fires"].append({"node": node, "vel": vel, "ang": ang})
		_wreck_fx(fx, wreck, node, pc, cen, h.L, k, is_main, tint)
	fx.dstate["wrecks"].append(wreck)
	_cap_wrecks(fx)
	fx.later(T + 0.28, func() -> void: _core_flash(fx, core, R, kp, tint, core_node, core_local))
	if pieces.is_empty():
		# Craft have no pre-cut job. Keep one pooled physical shard plus a visible ember.
		spawn_debris(fx, center, xf.basis.x * 2.0, 1, maxf(h.L * 0.15, 0.3))
		fx.spr(center, T, 5.0, tint, 1.2, R * 0.3, R * 0.05, 19, xf.basis.x * 2.0, 0.25, 0.0, 0.0, 12.0)


static func _core_flash(fx, p: Vector3, R: float, px: float, tint: Color, node: Node3D = null, local_p := Vector3.ZERO) -> void:
	# Booking and drawing share the same time, with no other death flashes before/after.
	var T: float = fx.now
	if is_instance_valid(node): p = node.to_global(local_p)
	if fx.flash_ok(T):
		fx.spr(p, T, 0.12, Color(1, 0.65, 0.3), 5.0, R * 0.22, R * 0.7, 0, Vector3.ZERO, 0.0, 0.0, 0.0, px)
		fx.light(p, T, 0.18, 7.0, tint, 0)
	else:
		fx.spr(p, T, 0.4, tint, 1.2, R * 0.2, R * 0.55, 18, Vector3.ZERO, 0.0, 0.0, 0.0, px * 0.7)
	fireball(fx, p, R * 0.7, T, 0.48, tint)


# Fires, smoke, embers and sparks riding a wreck piece, near its broken edge.
static func _wreck_fx(fx, wreck: Dictionary, node: Node3D, pc: Dictionary, cen: Vector3, L: float, k: float, is_main: bool, tint: Color) -> void:
	var edge: PackedVector3Array = pc["edge"]
	if edge.is_empty():
		edge = pc["pts"]
	if edge.is_empty():
		return
	var b = POOLS.Batch.new()
	var bs = POOLS.Batch.new()
	var q = POOLS.quad_shape()
	var qs = POOLS.streak_shape()
	var r = RandomNumberGenerator.new()
	r.seed = hash(node.name)
	var nf = 2 if is_main else 1
	var s = L * 0.022
	for j in nf:
		var p = edge[r.randi() % edge.size()] - cen
		var n = p.normalized() if p.length() > 0.01 else Vector3.UP
		for kk in 10:
			var v = n * (1.0 + r.randf()) + Vector3(r.randf() - 0.5, r.randf() - 0.5, r.randf() - 0.5)
			b.add(q, POOLS.pack(Vector4(p.x, p.y, p.z, -20.0 + kk * 0.08), Vector4(v.x, v.y, v.z, 0.55 + r.randf() * 0.3), Vector4(tint.r, tint.g * 0.9, tint.b, 2.4),
				Vector4(s * 0.25, s * 0.7, 1, r.randf() + (10.0 if is_main else 5.0)), Vector4(0.8 + r.randf() * 0.2, 0, 0, 0)))
		for kk in 3:
			b.add(q, POOLS.pack(Vector4(p.x, p.y, p.z, -20.0 + kk * 0.9), Vector4(n.x * 2.0, n.y * 2.0, n.z * 2.0, 2.7), Vector4(0.08, 0.075, 0.07, 0.5),
				Vector4(s * 0.7, s * 2.3, 3, r.randf() + (20.0 if is_main else 9.0)), Vector4(2.7, 0, 0.5, 0.2)))
		for kk in 6:
			b.add(q, POOLS.pack(Vector4(p.x, p.y, p.z, -20.0 + kk * 0.7 + r.randf()), Vector4((r.randf() - 0.5) * 3.0, (r.randf() - 0.5) * 3.0, (r.randf() - 0.5) * 3.0, 2.0),
				Vector4(1, 0.5, 0.15, 1.8), Vector4(0.25 * k, 0.08 * k, 19, r.randf()), Vector4(4.2, 0, 0.4, 0)))
		# round 2: atmosphere venting from the torn edge, a pale jet that keeps coming for the wreck's life (gated down)
		for kk in 5:
			var vv = (n * (4.0 + r.randf() * 3.0) + Vector3(r.randf() - 0.5, r.randf() - 0.5, r.randf() - 0.5) * 1.5) * k
			b.add(q, POOLS.pack(Vector4(p.x, p.y, p.z, -20.0 + kk * 0.24), Vector4(vv.x, vv.y, vv.z, 1.1), Vector4(0.62, 0.66, 0.74, 0.3),
				Vector4(s * 0.3, s * 2.2, 7, r.randf()), Vector4(1.2, 0, 1.2, 0)))
		var per = 2.5 + r.randf() * 2.0
		for kk in 10:
			var v = (n + Vector3(r.randf() - 0.5, r.randf() - 0.5, r.randf() - 0.5)).normalized() * (5 + r.randf() * 9) * k
			bs.add(qs, POOLS.pack(Vector4(p.x, p.y, p.z, -20.0 + r.randf() * per), Vector4(v.x, v.y, v.z, 0.3 + r.randf() * 0.4),
				Vector4(1, 0.62, 0.25, 6.0), Vector4(0.05, 0.11 * k, 1.8, 1), Vector4(per, 0, 0, 0)))
		if j == 0:
			var holder = Node3D.new()
			holder.position = p + n * 1.0
			node.add_child(holder)
			wreck["lights"].append(fx.light_source(holder, Vector3.ZERO, Color(1, 0.35, 0.07), 0.7 if is_main else 0.4, 0.12))
	var spm: ShaderMaterial = fx.mat(SH.SPRITE, 1, "#define SOFT\n" if fx.quality != "low" else "")
	var mi1 = b.build(spm, node, "fx_wreck_fire")
	var spark_mat: ShaderMaterial = fx.mat(SH.STREAK, 1)
	var mi2 = bs.build(spark_mat, node, "fx_wreck_sparks")
	wreck["fires"].append({"mat": spm, "mi": mi1})
	wreck["fires"].append({"mat": spark_mat, "mi": mi2})


static func _cap_wrecks(fx) -> void:
	var ws: Array = fx.dstate["wrecks"]
	while ws.size() > 24:
		var w: Dictionary = ws.pop_front()
		_free_wreck(w)


static func _free_wreck(w: Dictionary) -> void:
	for l in w["lights"]:
		l["on"] = false
	for n in w["nodes"]:
		if is_instance_valid(n):
			(n as Node).queue_free()


static func clear_wreck(fx, id: String) -> void:
	var ws: Array = fx.dstate["wrecks"]
	var keep: Array = []
	for w in ws:
		if w["id"] == id:
			_free_wreck(w)
		else:
			keep.append(w)
	fx.dstate["wrecks"] = keep


static func update(fx, dt: float) -> void:
	if not fx.dstate.has("wrecks"):
		return
	for ship in fx.ships.values(): _update_dying(fx, ship)
	for w in fx.dstate["wrecks"]:
		var speed: float = maxf(fx.anim_speed(), 0.01)
		var prev: float = float(w.get("speed", 1.0))
		for nd in w["nodes"]:
			if is_instance_valid(nd) and nd is RigidBody3D:
				(nd as RigidBody3D).linear_velocity *= speed / prev
				(nd as RigidBody3D).angular_velocity *= speed / prev
		w["speed"] = speed
		var age: float = fx.now - float(w["t0"])
		# Heat fades over a few seconds. The cold opaque cap remains.
		var heat = exp(-maxf(age, 0.0) / 1.8)
		for m in w["mats"]:
			(m as ShaderMaterial).set_shader_parameter("heat", heat)
		var gate = exp(-maxf(age, 0.0) / 3.5)
		for f in w["fires"]:
			if f.has("mat"):
				(f["mat"] as ShaderMaterial).set_shader_parameter("gate", gate)
			elif f.has("node") and is_instance_valid(f["node"]):
				# no physics: the piece drifts and turns on its own, slowing down
				var n: Node3D = f["node"]
				var v: Vector3 = f["vel"]
				n.global_position += v * dt
				f["vel"] = v * (1.0 - 0.05 * dt)
				var a: Vector3 = f["ang"]
				if a.length() > 1e-5:
					n.global_rotate(a.normalized(), a.length() * dt)
		for l in w["lights"]:
			l["base"] = 0.7 * gate
