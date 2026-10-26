extends RefCounted
# Where effects sit on a hull, found from the hull's own triangles (in the ship root's frame: bow +X, up +Y, port +Z).
#
# The triangles go into a TriangleMesh (Godot's native BVH), so a ray against the real hull costs microseconds:
#   - visible surface samples: rays from outside at random toward the hull; each hit is a point anyone could see and
#     hit, with its outward normal and its section (eng aft third, mid, prow fore third);
#   - mounts: the outermost hull point on a side at four stations along the length (broadside guns), on the top
#     (turrets) and at the bow (lances, torpedo tubes);
#   - nozzles: the stern face, clustered into 1 to 3 engine bells;
#   - impact points: a ray from the attacker toward a sample in the struck section lands on the real surface.

const SEC_ENG := 0
const SEC_MID := 1
const SEC_PROW := 2
const SEC_NAMES := {"eng": 0, "mid": 1, "prow": 2}

var tm: TriangleMesh
var box = AABB()
var L = 1.0
var W = 1.0
var H = 1.0
var c = Vector3.ZERO
var sp = PackedVector3Array()      # sample points
var sn = PackedVector3Array()      # sample normals
var ssec = PackedInt32Array()      # sample sections
var nozzles: Array = []             # {p, r}
var bow = Vector3.ZERO
var mounts = {}                    # "port", "stb", "top" -> Array of {p, n}
var tri_count = 0
var _rng = RandomNumberGenerator.new()
var stb_z = 1.0                    # +1: root +Z is starboard (G2), -1: +Z is port


static func faces_of(root: Node3D, meshes: Array) -> PackedVector3Array:
	var faces = PackedVector3Array()
	var inv = root.global_transform.affine_inverse()
	for m in meshes:
		var mi = m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf = inv * mi.global_transform
		var f = mi.mesh.get_faces()
		if xf.is_equal_approx(Transform3D.IDENTITY):
			faces.append_array(f)
		else:
			faces.append_array(xf * f)
	return faces


func analyse(root: Node3D, meshes: Array, seed_v: int) -> void:
	_rng.seed = seed_v
	var inv = root.global_transform.affine_inverse()
	var first = true
	for m in meshes:
		var mi = m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var bb = (inv * mi.global_transform) * mi.mesh.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	if first:
		box = AABB(Vector3(-6, -1.5, -1.5), Vector3(12, 3, 3))
	L = maxf(box.size.x, 0.1)
	W = maxf(box.size.z, 0.05)
	H = maxf(box.size.y, 0.05)
	c = box.get_center()
	var faces = faces_of(root, meshes)
	tri_count = faces.size() / 3
	tm = TriangleMesh.new()
	if faces.size() >= 3:
		tm.create_from_faces(faces)
	else:
		tm = null
	_samples(900)
	_find_bow()
	_find_nozzles()
	for side in ["port", "stb", "top"]:
		mounts[side] = _mount_row(side)


func section_of(x: float) -> int:
	var u = (x - box.position.x) / L
	return SEC_ENG if u < 1.0 / 3.0 else (SEC_PROW if u > 2.0 / 3.0 else SEC_MID)


func ray(from: Vector3, dir: Vector3) -> Dictionary:
	if tm == null:
		return {}
	var h: Dictionary = tm.intersect_ray(from, dir.normalized())
	if h.is_empty():
		return {}
	var n: Vector3 = h["normal"]
	if n.dot(dir) > 0.0:
		n = -n
	return {"p": h["position"], "n": n.normalized()}


func _samples(n: int) -> void:
	var diag = box.size.length() * 1.5 + 2.0
	var tries = 0
	while sp.size() < n and tries < n * 3:
		tries += 1
		var tgt = c + Vector3((_rng.randf() - 0.5) * box.size.x * 0.9, (_rng.randf() - 0.5) * box.size.y * 0.8, (_rng.randf() - 0.5) * box.size.z * 0.8)
		var d = _rdir()
		var h = ray(tgt - d * diag, d)
		if h.is_empty():
			continue
		sp.append(h["p"])
		sn.append(h["n"])
		ssec.append(section_of((h["p"] as Vector3).x))
	if sp.is_empty():
		# no triangles: a box's faces
		for k in 60:
			var d = _rdir()
			var p = c + d * box.size * 0.5
			sp.append(p)
			sn.append(d)
			ssec.append(section_of(p.x))


func _find_bow() -> void:
	var h = ray(Vector3(box.end.x + 5.0, c.y, c.z), Vector3(-1, 0, 0))
	if h.is_empty():
		var best = -1e9
		for p in sp:
			if p.x > best:
				best = p.x
				bow = p
		if best < -1e8:
			bow = Vector3(box.end.x, c.y, c.z)
	else:
		bow = h["p"]


func _find_nozzles() -> void:
	# rays from behind on a grid over the stern cross-section; hits near the aftmost point are the stern face
	var pts: Array = []
	var minx = 1e9
	var hits: Array = []
	for iy in 12:
		for iz in 12:
			var y = box.position.y + (iy + 0.5) / 12.0 * box.size.y
			var z = box.position.z + (iz + 0.5) / 12.0 * box.size.z
			var h = ray(Vector3(box.position.x - 5.0, y, z), Vector3(1, 0, 0))
			if h.is_empty():
				continue
			hits.append(h)
			minx = minf(minx, (h["p"] as Vector3).x)
	for h in hits:
		if (h["p"] as Vector3).x <= minx + 0.08 * L:
			pts.append(h["p"])
	if pts.size() < 2:
		nozzles = [{"p": Vector3(box.position.x - 0.1, c.y, c.z), "r": clampf(0.18 * minf(W, H), 0.3, 3.0)}]
		return
	var K = 3 if W > 0.45 * L else 2
	if pts.size() < 6:
		K = 1
	pts.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z < b.z)
	var cen: Array = []
	for k in K:
		var q: Vector3 = pts[int((k + 0.5) / K * pts.size())]
		cen.append(Vector2(q.y, q.z))
	var asg = PackedInt32Array()
	asg.resize(pts.size())
	for it in 10:
		for i in pts.size():
			var bd = 1e9
			for k in K:
				var dd = Vector2(pts[i].y, pts[i].z).distance_squared_to(cen[k])
				if dd < bd:
					bd = dd
					asg[i] = k
		for k in K:
			var m = Vector2.ZERO
			var cnt = 0
			for i in pts.size():
				if asg[i] == k:
					m += Vector2(pts[i].y, pts[i].z)
					cnt += 1
			if cnt > 0:
				cen[k] = m / cnt
	nozzles = []
	var cell = maxf(box.size.y, box.size.z) / 12.0
	for k in K:
		var mx = 1e9
		var cnt = 0
		for i in pts.size():
			if asg[i] == k:
				mx = minf(mx, pts[i].x)
				cnt += 1
		if cnt == 0:
			continue
		var r = clampf(sqrt(float(cnt)) * cell * 0.45, 0.12 * minf(W, H), 0.3 * minf(W, H))
		nozzles.append({"p": Vector3(mx - 0.05, cen[k].x, cen[k].y), "r": r})


func _mount_row(side: String) -> Array:
	var out: Array = []
	var dir = Vector3(0, 0, -1) if side == "port" else (Vector3(0, 0, 1) if side == "stb" else Vector3(0, -1, 0))
	for f in [0.28, 0.1, -0.08, -0.26]:
		var x = c.x + f * L
		var from: Vector3
		if side == "top":
			from = Vector3(x, box.end.y + 5.0, c.z)
		else:
			from = Vector3(x, c.y + 0.15 * H, c.z - dir.z * (W + 5.0))
		var h = ray(from, dir)
		if h.is_empty():
			h = {"p": Vector3(x, c.y if side != "top" else box.end.y, c.z - dir.z * W * 0.5), "n": -dir}
		out.append(h)
	return out


# The guns that can bear on a point (ship frame), never firing backward: a target to the side gets the broadside on
# that side, a target ahead gets the bow and the forward top mounts, a target behind gets the top turrets.
func mounts_for(target_local: Vector3, n: int) -> Array:
	var d = (target_local - c)
	d = d.normalized() if d.length() > 1e-4 else Vector3(1, 0, 0)
	var row: Array
	if d.x > 0.75:
		row = [{"p": bow, "n": Vector3(1, 0, 0)}]
		for m in mounts["top"]:
			if (m["p"] as Vector3).x > c.x:
				row.append(m)
	elif d.x < -0.6:
		row = mounts["top"]
	else:
		row = mounts["port"] if d.z >= 0.0 else mounts["stb"]
	var out: Array = []
	for i in n:
		out.append(row[i % row.size()])
	return out


# A point on the struck section, on the side facing `from` (ship frame).
func hit_point(from: Vector3, sec: int, quad: int = -1) -> Dictionary:
	var want = (from - c).normalized()
	if quad >= 0:
		want = quad_dir(quad)
	var best = -1
	var bs = -1e9
	for k in 24:
		var i = _rng.randi() % sp.size()
		var s = sn[i].dot(want) + _rng.randf() * 0.5
		if sec >= 0 and ssec[i] != sec:
			s -= 2.0
		if s > bs:
			bs = s
			best = i
	var p = sp[best]
	var h = ray(from, p - from)
	if not h.is_empty() and h["p"].distance_to(p) < 0.25 * L:
		return h
	return {"p": p, "n": sn[best]}


# The facing quad's outward direction in the ship frame: 0 prow, 1 starboard, 2 rear, 3 port.
func quad_dir(quad: int) -> Vector3:
	return [Vector3(1, 0, 0), Vector3(0, 0, stb_z), Vector3(-1, 0, 0), Vector3(0, 0, -stb_z)][posmod(quad, 4)]


func random_sample(sec: int, up_bias := 0.0) -> Dictionary:
	var best = 0
	var bs = -1e9
	for k in 16:
		var i = _rng.randi() % sp.size()
		var s = _rng.randf() + sn[i].y * up_bias
		if sec >= 0 and ssec[i] != sec:
			s -= 3.0
		if s > bs:
			bs = s
			best = i
	return {"p": sp[best], "n": sn[best]}


func shield_radii() -> Vector3:
	return Vector3(L * 0.5 * 1.1 + 0.3, H * 0.5 * 1.35 + 0.5, W * 0.5 * 1.3 + 0.5)


func _rdir() -> Vector3:
	var z = _rng.randf() * 2.0 - 1.0
	var an = _rng.randf() * TAU
	var r = sqrt(1.0 - z * z)
	return Vector3(r * cos(an), r * sin(an), z)
