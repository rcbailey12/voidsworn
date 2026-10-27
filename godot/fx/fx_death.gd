extends RefCounted
# Ship deaths, drifting wrecks and the physics behind them, plus the shared hull decorations (scorch decals, breach
# holes, bent plates, venting plumes, debris bodies). Static functions; the state lives in fx.dstate.
#
# A death (A5 sheets 6, in-game sequence): a held beat with lights and engines stuttering; a cook-off of internal
# explosions rippling along the hull; the break-up, where the ship's own hull is cut into pieces (each triangle goes to
# the nearest of a few seeds along the length, so the pieces are real parts of the model) that become Jolt rigid bodies
# with glowing cross-sections and charred insides; a final blast for heavy ships; then burning wrecks that drift, vent and
# cool. The cutting is done once per ship on a worker thread soon after add_ship, so the death itself costs only the
# mesh upload.

const SH := preload("res://fx/fx_shaders.gd")
const POOLS := preload("res://fx/fx_pool.gd")

const HULL_LAYER := 1
const DEBRIS_LAYER := 2
const DEBRIS_CAP := 360
const DEBRIS_VARIANTS := 4
const WRECK_COOL := 14.0

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


static func safe_convex(src: PackedVector3Array) -> Shape3D:
	var pts := PackedVector3Array()
	for p in src:
		if is_finite(p.x) and is_finite(p.y) and is_finite(p.z):
			pts.append(p)
	if pts.is_empty():
		var b0 := BoxShape3D.new()
		b0.size = Vector3.ONE * 0.1
		return b0
	var lo := pts[0]
	var hi := pts[0]
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	var ext := hi - lo
	var size := maxf(ext.x, maxf(ext.y, ext.z))
	if _dirs.is_empty():
		# Fibonacci sphere: evenly spread directions
		for i in _HULL_DIRS:
			var y := 1.0 - 2.0 * (float(i) + 0.5) / _HULL_DIRS
			var rr := sqrt(maxf(0.0, 1.0 - y * y))
			var a := float(i) * 2.399963
			_dirs.append(Vector3(cos(a) * rr, y, sin(a) * rr))
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
	var tid = WorkerThreadPool.add_task(func() -> void: job["out"] = _cut(job))
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
	if not s.has_meta("cut_task") or s.dead:
		return
	var tid: int = s.get_meta("cut_task")
	if not WorkerThreadPool.is_task_completed(tid):
		fx.later(fx.now + 0.5, func() -> void: _prebuild(fx, s))
		return
	WorkerThreadPool.wait_for_task_completion(tid)
	s.remove_meta("cut_task")
	var job: Dictionary = s.get_meta("cut_job", {})
	var meshes: Array = []
	for pc in job.get("out", []) if job.get("out") != null else []:
		meshes.append(_piece_mesh(pc))
	job["meshes"] = meshes


# A piece's mesh with the hull's own materials and vertex format (no copies, same compression: anything else would be
# a new shader pipeline to compile mid-fight; r3 still counted 5); the death overlay draws the piece's inside faces.
static func _piece_mesh(pc: Dictionary) -> ArrayMesh:
	var am = ArrayMesh.new()
	for sd in pc["surfs"]:
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, sd["arrays"], [], {}, int(sd.get("fmt", 0)) & Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)
		am.surface_set_material(am.get_surface_count() - 1, sd["mat"])
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
	return pieces


# ---------------------------------------------------------------- the death

static func death(fx, s, cause: String) -> float:
	if s.dead:
		return 0.0
	s.dead = true
	var T: float = fx.now
	var h = s.hull
	var w: int = s.weight
	var k: float = s.scale_k()
	var col: Color = s.fac["weapon"]
	if s.has_meta("collider"):
		var cb: Node = s.get_meta("collider")
		if is_instance_valid(cb):
			cb.queue_free()
	if w <= 0:
		_craft_death(fx, s, T)
		return 0.8
	var hold = 0.15
	var cook: float = [0.4, 0.8, 1.2, 1.7, 2.3][w]
	match cause:
		"big": cook *= 0.6
		"dark": cook *= 1.2
		"cut": cook *= 0.7
		"flay": cook *= 0.8
	var TB = T + hold + cook
	var tint = Color(1, 0.55, 0.2)
	if cause == "melt":
		tint = Color(0.68, 0.92, 0.2)
	# 1. the held beat: one dip in the engines and lights
	fx.hit_pause(T, [2, 3, 4, 7, 9][w])
	# 2. cook-off: internal explosions rippling along the hull
	var nb: int = [2, 3, 5, 7, 8][w]
	if cause == "dark":
		nb = maxi(2, nb / 2)
	if cause == "flay":
		nb += 4
	for i in nb:
		var u = float(i) / maxf(nb - 1, 1)
		var ti = T + hold + u * cook * (0.85 + fx.rng.randf() * 0.15)
		var hp: Dictionary = h.random_sample(-1, 0.3)
		var lp: Vector3 = hp["p"]
		var ln: Vector3 = hp["n"]
		fx.later(ti, func() -> void: _cook_burst(fx, s, lp, ln, k * (0.6 if cause == "flay" else 1.0), tint, cause))
	# the cut: a glowing line grows across the hull before it parts
	if cause == "cut":
		var a: Dictionary = h.random_sample(-1, 0.8)
		for j in 24:
			var pj: Vector3 = s.to_world((a["p"] as Vector3) + Vector3(0, 0, (j / 23.0 - 0.5) * h.W * 1.1))
			fx.spr(pj, T + hold + j * cook / 24.0, cook + 0.6 - j * cook / 24.0, Color(1, 0.75, 0.4), 4.0, 0.5 * k, 0.9 * k, 21)
	fx.later(T + hold, func() -> void: s.engine_level = 0.0)
	_cracks(fx, s, T + hold, cook, tint)
	# 3. break-up
	if not s.has_meta("cut_task") and not s.has_meta("cut_job"):
		precompute(fx, s, cause)
	fx.later(TB, func() -> void: _break_up_when_ready(fx, s, cause, tint, TB + 2.5))
	return TB - T + 0.6


# r18: when the ship's first cut is still running on a worker (a busy 20-ship battle), the cook-off holds a little longer
# instead of the main thread waiting for it (the 20-ship bench froze 4 s on such a death); past the deadline it waits.
static func _break_up_when_ready(fx, s, cause: String, tint: Color, deadline: float) -> void:
	if s.has_meta("cut_task") and not s.has_meta("cut_prev") and fx.now < deadline:
		if not WorkerThreadPool.is_task_completed(int(s.get_meta("cut_task"))):
			fx.later(fx.now + 0.05, func() -> void: _break_up_when_ready(fx, s, cause, tint, deadline))
			return
	_break_up(fx, s, cause, tint)


# Glowing fissures spreading over the hull while it cooks off (an overlay on the ship's own meshes; the ship is dying,
# so nothing else needs the overlay slot now).
static func _cracks(fx, s, t0: float, dur: float, tint: Color) -> void:
	var m: ShaderMaterial = fx.mat(SH.CRACKS, 1)
	m.set_shader_parameter("t0", t0)
	m.set_shader_parameter("dur", maxf(dur, 0.3))
	m.set_shader_parameter("scale", 3.5 / maxf(s.hull.L, 1.0))
	m.set_shader_parameter("glow", Vector3(tint.r, tint.g, tint.b))
	for mm in s.meshes:
		if is_instance_valid(mm):
			(mm as GeometryInstance3D).material_overlay = m


static func _cook_burst(fx, s, lp: Vector3, ln: Vector3, k: float, tint: Color, cause: String) -> void:
	var T: float = fx.now
	var wp: Vector3 = s.to_world(lp)
	var wn: Vector3 = s.dir_world(ln)
	var sz: float = s.hull.L * 0.08
	fx.pop(wp + wn * 0.3, T, tint.lerp(Color.WHITE, 0.3), sz * 2.0, 8.0, wn, 0.14)
	fx.spr(wp + wn * 0.4, T, 0.45, tint, 5.0, sz * 0.4, sz * 1.6, 2)
	for i in 4:
		fx.spr(wp + fx.rdir() * sz * 0.3, T + fx.rng.randf() * 0.06, 0.6 + fx.rng.randf() * 0.4, tint, 2.6, sz * 0.5, sz * 1.4, 1, fx.rcone(wn, 0.7) * 2.5 * k)
	for i in 16:
		fx.stk(wp, T + fx.rng.randf() * 0.05, 0.3 + fx.rng.randf() * 0.5, Color(1, 0.6, 0.25), 7.0, 0.05, 0.13, 1, fx.rcone(wn, 1.0) * (10 + fx.rng.randf() * 16) * k, 1.8)
	for i in 2:
		fx.spr(wp + wn * 0.8, T + 0.1 + i * 0.1, 2.2, Color(0.1, 0.09, 0.085), 0.55, sz * 0.8, sz * 2.8, 3, wn * 2.0 * k, 0.6)
	for i in 4:
		fx.shd(wp, T, 2.5, fx.rcone(wn, 0.8) * (3 + fx.rng.randf() * 6) * k, s.hull.L * (0.006 + fx.rng.randf() * 0.01), 1.0)
	if cause == "melt":
		for i in 3:
			fx.spr(wp, T, 1.8, Color(0.5, 0.62, 0.12), 0.6, sz * 0.6, sz * 2.2, 20, wn * 1.5 * k, 0.5)
	fx.light(wp + wn * 1.5, T, 0.4, 7.0, tint, 0)
	fx.shake(T, 0.12, wp)
	spawn_debris(fx, wp + wn * 0.5, wn * 4.0 * k, 2, s.hull.L * 0.02)


static func _craft_death(fx, s, T: float) -> void:
	var p: Vector3 = s.to_world(s.hull.c)
	var c: Color = s.fac["engine"]
	var sz: float = maxf(s.hull.L, 1.0)
	fx.pop(p, T, Color(1, 0.75, 0.45), sz * 2.0, 6.0)
	fx.spr(p, T, 0.5, Color(1, 0.6, 0.3), 4.0, sz * 0.5, sz * 1.8, 2)
	for i in 6:
		fx.stk(p, T + fx.rng.randf() * 0.04, 0.3 + fx.rng.randf() * 0.3, Color(1, 0.6, 0.25), 6.0, 0.05, 0.1, 1, fx.rdir() * (6 + fx.rng.randf() * 10), 2.0)
	fx.spr(p, T + 0.1, 1.2, Color(0.12, 0.11, 0.1), 0.45, sz * 0.6, sz * 2.0, 3, Vector3.ZERO, 0.5)
	fx.light(p, T, 0.35, 4.0, c, 0)
	fx.later(T + 0.08, func() -> void: _hide_ship(s))


static func _hide_ship(s) -> void:
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
	var xf: Transform3D = s.root.global_transform
	_hide_ship(s)
	# the final blast (bigger for heavy ships and torpedo or ram kills; quiet for burn-outs)
	var big = 1.0 + (0.6 if cause == "big" else 0.0) - (0.6 if cause == "dark" else 0.0) + (0.4 if s.flagship else 0.0)
	var R: float = h.L * 0.35 * big
	if fx.flash_ok(T):
		fx.spr(center, T, 0.3, Color(1, 0.9, 0.75), 18.0 * big, R * 0.8, R * 2.4, 0)
	else:
		fx.spr(center, T, 0.9, Color(1, 0.8, 0.6), 3.0, R * 0.6, R * 2.0, 18)
	fx.spr(center, T, 0.6, tint.lerp(Color(1, 0.8, 0.55), 0.5), 8.0 * big, R * 0.3, R * 0.9, 2)
	fx.ring(center, s.dir_world(Vector3(0.12, 1, 0.08)), T, 1.0, Color(0.45, 0.6, 1.0), 0.8 * big, R * 0.1, R * 4.5, 1)
	if w >= 2:
		fx.ring(center, s.dir_world(Vector3(0.6, 0.5, -0.4)), T + 0.05, 0.8, Color(1.0, 0.6, 0.3), 0.45 * big, R * 0.1, R * 2.2, 1)
		fx.dst(center, T, 0.9, R * 0.3, R * 4.0, 0, 1.0 * big)
	fireball(fx, center, R * 2.2, T, 4.0 + w * 0.5, tint)
	# a rolling fireball of flame sprites too (reads at any zoom, and on high quality without volumes)
	for i in 10 + w * 3:
		fx.spr(center + fx.rdir() * R * 0.35, T + fx.rng.randf() * 0.25, 1.4 + fx.rng.randf() * 0.8, tint, 3.0, R * 0.4, R * 1.2, 1, fx.rdir() * (2.0 + fx.rng.randf() * 4.0) * k, 0.5)
	if fx.quality != "max":
		for i in 10:
			fx.spr(center + fx.rdir() * R * 0.3, T + 0.2 + fx.rng.randf() * 0.4, 3.0 + fx.rng.randf(), Color(0.07, 0.065, 0.06), 0.75, R * 0.4, R * 1.4, 3, fx.rdir() * 2.0 * k, 0.35)
	for i in int(14 * big) + w * 3:
		fx.spr(center + fx.rdir() * R * 0.25, T + fx.rng.randf() * 0.15, 1.3 + fx.rng.randf(), tint, 2.4, R * 0.25, R * 0.7, 1, fx.rdir() * (3 + fx.rng.randf() * 5) * k, 0.6, (fx.rng.randf() - 0.5) * 1.5)
	for i in int(60 * big) + w * 20:
		fx.stk(center + fx.rdir() * R * 0.15, T + fx.rng.randf() * 0.2, 1.0 + fx.rng.randf() * 2.0, Color(1, 0.55 + fx.rng.randf() * 0.15, 0.22), 6.0, 0.05, 0.16, 1, fx.rdir() * (15 + fx.rng.randf() * 35) * k, 0.5)
	for i in 30 + w * 10:
		fx.spr(center + fx.rdir() * R * 0.3, T + fx.rng.randf() * 0.3, 2.0 + fx.rng.randf() * 2.0, Color(1, 0.5, 0.15), 2.0, 0.3 * k, 0.1 * k, 19, fx.rdir() * (4 + fx.rng.randf() * 10) * k, 0.3)
	for i in 20 + w * 8:
		fx.shd(center + fx.rdir() * R * 0.2, T + fx.rng.randf() * 0.1, 6.0, fx.rdir() * (4 + fx.rng.randf() * 14) * k, h.L * (0.01 + fx.rng.randf() * 0.03), 1.0, 3.0, 0.15)
	spawn_debris(fx, center, Vector3.ZERO, 6 + w * 6, h.L * 0.03)
	fx.light(center, T, 1.6, 26.0 * big, Color(1, 0.8, 0.55), 0)
	fx.light(center, T + 0.2, 4.0, 5.0, tint, 1)
	fx.shake(T, [0.2, 0.3, 0.45, 0.7, 0.9][w] * big, center)
	fx.hit_pause(T, [0, 2, 4, 8, 10][w])
	# the pieces: real parts of the hull, as rigid bodies that drift and burn
	var wreck = {"id": s.id, "t0": T, "nodes": [], "mats": [], "lights": [], "fires": []}
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
		var cen = Vector3.ZERO
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
			var pts = PackedVector3Array()
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
		cm.set_shader_parameter("glow", Vector3(tint.r, tint.g, tint.b))
		mi.material_overlay = cm
		wreck["mats"].append(cm)
		wreck["nodes"].append(node)
		# motion: away from the centre, the main hulk barely moves (it stays on its hex as terrain)
		var out = (cen - h.c).normalized() if (cen - h.c).length() > 0.01 else fx.rdir()
		var spd: float = (0.4 if is_main else [0.0, 2.6, 3.4, 4.0, 4.6][w]) * k * (1.7 if cause == "big" else (0.6 if cause == "cut" or cause == "dark" else 1.0))
		var vel: Vector3 = xf.basis * (out * spd) + fx.rdir() * 0.3 * k
		if cause == "tidal" and fx.well != Vector3.INF:
			vel += (fx.well - center).normalized() * 3.0 * k
		var ang: Vector3 = fx.rdir() * (0.05 if is_main else (0.15 + fx.rng.randf() * 0.35))
		if node is RigidBody3D:
			(node as RigidBody3D).linear_velocity = vel
			(node as RigidBody3D).angular_velocity = ang
		else:
			wreck["fires"].append({"node": node, "vel": vel, "ang": ang})
		_wreck_fx(fx, wreck, node, pc, cen, h.L, k, is_main, tint)
	fx.dstate["wrecks"].append(wreck)
	_cap_wrecks(fx)


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
	var nf = 3 if is_main else 2
	var s = L * 0.04
	for j in nf:
		var p = edge[r.randi() % edge.size()] - cen
		var n = p.normalized() if p.length() > 0.01 else Vector3.UP
		for kk in 10:
			var v = n * (1.0 + r.randf()) + Vector3(r.randf() - 0.5, r.randf() - 0.5, r.randf() - 0.5)
			b.add(q, POOLS.pack(Vector4(p.x, p.y, p.z, -20.0 + kk * 0.08), Vector4(v.x, v.y, v.z, 0.55 + r.randf() * 0.3), Vector4(tint.r, tint.g * 0.9, tint.b, 2.4),
				Vector4(s * 0.4, s * 1.2, 1, r.randf()), Vector4(0.8 + r.randf() * 0.2, 0, 0, 0)))
		for kk in 3:
			b.add(q, POOLS.pack(Vector4(p.x, p.y, p.z, -20.0 + kk * 0.9), Vector4(n.x * 2.0, n.y * 2.0, n.z * 2.0, 2.7), Vector4(0.08, 0.075, 0.07, 0.5),
				Vector4(s * 0.8, s * 3.6, 3, r.randf()), Vector4(2.7, 0, 0.5, 0.2)))
		for kk in 6:
			b.add(q, POOLS.pack(Vector4(p.x, p.y, p.z, -20.0 + kk * 0.7 + r.randf()), Vector4((r.randf() - 0.5) * 3.0, (r.randf() - 0.5) * 3.0, (r.randf() - 0.5) * 3.0, 2.0),
				Vector4(1, 0.5, 0.15, 1.8), Vector4(0.25 * k, 0.08 * k, 19, r.randf()), Vector4(4.2, 0, 0.4, 0)))
		var per = 2.5 + r.randf() * 2.0
		for kk in 10:
			var v = (n + Vector3(r.randf() - 0.5, r.randf() - 0.5, r.randf() - 0.5)).normalized() * (5 + r.randf() * 9) * k
			bs.add(qs, POOLS.pack(Vector4(p.x, p.y, p.z, -20.0 + r.randf() * per), Vector4(v.x, v.y, v.z, 0.3 + r.randf() * 0.4),
				Vector4(1, 0.62, 0.25, 6.0), Vector4(0.05, 0.11 * k, 1.8, 1), Vector4(per, 0, 0, 0)))
		if j == 0:
			var holder = Node3D.new()
			holder.position = p + n * 1.0
			node.add_child(holder)
			wreck["lights"].append(fx.light_source(holder, Vector3.ZERO, Color(1, 0.5, 0.15), 2.0 if is_main else 1.2, 0.45))
	var spm: ShaderMaterial = fx.mat(SH.SPRITE, 1, "#define SOFT\n" if fx.quality != "low" else "")
	var mi1 = b.build(spm, node, "fx_wreck_fire")
	var mi2 = bs.build(fx.mat(SH.STREAK, 1), node, "fx_wreck_sparks")
	wreck["fires"].append({"mat": spm, "mi": mi1})


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
	for w in fx.dstate["wrecks"]:
		var age: float = fx.now - float(w["t0"])
		# the cut faces cool from white-orange to a dull red glow that stays
		var heat = 0.15 + 0.85 * exp(-age / (WRECK_COOL * 0.35))
		for m in w["mats"]:
			(m as ShaderMaterial).set_shader_parameter("heat", heat)
		var gate = clampf(1.0 - age / 40.0, 0.45, 1.0)
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
			l["base"] = 2.0 * gate
