extends RefCounted
# Hull breaches that change the ship itself (Ryan, R39: "the actual underlying ship looks the same").
#
# A breach is cut into the real hull mesh, not painted on it:
#   - hull triangles inside a torn outline are removed (radial tears between the petals too), so there is a real hole,
#     and through thin parts it goes right through and takes a bite out of the silhouette;
#   - the skin round the hole peels back: plates bent outward on hinges, each petal by its own amount;
#   - a wider ring buckles inward with wrinkles; a dent alone is stage 2;
#   - a cavity behind the hole, built from the removed skin pushed inward (so it always sits inside the hull, whatever
#     its shape): a rubble floor, frames and deck layers sliced through it, conduits (some broken), cables trailing out,
#     the backs of the peeled plates, the torn edge with the hull's thickness; all lit from inside by a fire point;
#   - fire, embers, sparks at the torn conduits and cable ends, gas venting from a broken pipe, thin smoke, from inside.
# The heavy part (removing triangles, displacing the skin, building the cavity) runs on a worker thread from the hull's
# original arrays, so every rebuild starts clean; the main thread only uploads the result. The rebuilt hull keeps the
# hull's own materials and vertex format (no new pipeline to compile mid-fight).
#
# A4's pre-cut damage geometry (API.md 14) replaces the generic cut where it exists.

const SH := preload("res://fx/fx_shaders.gd")
const POOLS := preload("res://fx/fx_pool.gd")

const PART_CUP := 0.0
const PART_SKIN := 0.25
const PART_WALL := 0.5
const PART_PIPE := 0.75
const PART_LIP := 1.0


# One damage entry in the ship root's frame. kind 0 dent, 1 hole.
class Ent:
	var kind := 1
	var c := Vector3.ZERO
	var n := Vector3.UP
	var t1 := Vector3.RIGHT
	var t2 := Vector3.BACK
	var R := 1.0           # hole radius (dent: dent radius)
	var w := 0.5           # width of the peeled ring
	var bend := 1.0        # how far the petals bend back (radians at the tip)
	var buckle := 0.1      # inward buckling of the ring round the hole, in R
	var depth := 0.0       # dent depth
	var th := 0.05         # hull skin thickness
	var D := 0.8           # cavity depth below the skin
	var cut := 0.5         # how far below the skin triangles are removed
	var through := false   # thin hull: the hole goes right through (no cavity)
	var k := 5.0           # petals
	var inf2 := 1.0        # influence radius squared
	var cutr2 := 1.0       # removal test radius squared
	var p := PackedFloat32Array()
	var seed_v := 0.0
	var t0 := 0.0          # when it opened (lip cooling)
	var sec := 0

	func rh(a: float) -> float:
		return R * (1.0 + 0.16 * sin(3.0 * a + p[0]) + 0.09 * sin(5.0 * a + p[1]) + 0.05 * sin(9.0 * a + p[2]))

	func petal(a: float) -> float:
		var s := 0.5 + 0.5 * sin(k * a + p[3])
		return smoothstep(0.12, 0.8, s) * (0.7 + 0.3 * sin(2.0 * a + p[4]))

	func tear(a: float) -> float:
		return 0.5 + 0.5 * sin(k * a + p[3])


class Part:
	var pos := PackedVector3Array()
	var nrm := PackedVector3Array()
	var col := PackedColorArray()
	var cup_f := PackedVector3Array()    # cavity floor, 3 per triangle (for slicing frames and decks)
	var cup_o := PackedVector3Array()    # the skin above each floor point


static func _phases(seed_v: float) -> PackedFloat32Array:
	var r := RandomNumberGenerator.new()
	r.seed = int(seed_v * 7919.0) + 17
	var out := PackedFloat32Array()
	for i in 8:
		out.append(r.randf() * TAU)
	return out


static func _frame(e: Ent) -> void:
	e.t1 = e.n.cross(Vector3.UP if absf(e.n.y) < 0.9 else Vector3.RIGHT).normalized()
	e.t2 = e.n.cross(e.t1)


static func dent(c: Vector3, n: Vector3, R: float, depth: float, seed_v: float) -> Ent:
	var e := Ent.new()
	e.kind = 0
	e.c = c
	e.n = n.normalized()
	_frame(e)
	e.R = R
	e.depth = depth
	e.inf2 = R * R
	e.cutr2 = 0.0
	e.seed_v = seed_v
	e.p = _phases(seed_v)
	return e


# A hole at c (on the hull, outward normal n). The cavity depth comes from how thick the hull is under the hole.
static func hole(hull, c: Vector3, n: Vector3, R: float, bend: float, buckle: float, seed_v: float) -> Ent:
	var e := Ent.new()
	e.kind = 1
	e.c = c
	e.n = n.normalized()
	_frame(e)
	e.R = R
	e.w = R * 0.5
	e.bend = bend
	e.buckle = buckle
	e.th = R * 0.05
	var Dt := 1e9
	if hull != null:
		var far: Dictionary = hull.ray(c - e.n * (R * 0.03), -e.n)
		if not far.is_empty():
			Dt = ((far["p"] as Vector3) - c).length()
	e.through = Dt < R * 0.7
	e.D = minf(R * 0.85, Dt * 0.42)
	e.cut = (Dt + R * 0.4) if e.through else R * 0.55
	e.seed_v = seed_v
	e.p = _phases(seed_v)
	e.k = 4.0 + floorf(e.p[5] / TAU * 2.0)
	var inf := R * 2.4 + e.w
	e.inf2 = inf * inf
	var cr := R * 1.35 + e.w
	e.cutr2 = cr * cr
	return e


# ---------------------------------------------------------------- the displacement fields (pure functions of position)

static func _nz(q: Vector3) -> float:
	return sin(q.x + 1.7 * sin(q.y * 0.8 + 0.3)) * sin(q.y * 1.13 + 1.3 * sin(q.z * 0.9 + 1.1)) * sin(q.z * 0.97 + 1.5 * sin(q.x * 0.7 + 2.3))


# Plates peeling back round each hole: a point s from the hinge (the outer edge of the torn ring) turns about the hinge
# by an angle that grows toward the tip, so the plates curl outward.
static func peel_at(P: Vector3, ents: Array) -> Vector3:
	var out := Vector3.ZERO
	for x in ents:
		var E: Ent = x
		if E.kind != 1:
			continue
		var d := P - E.c
		if d.length_squared() > E.cutr2:
			continue
		var h := d.dot(E.n)
		if h < -E.R * 0.45 or h > E.R * 0.8:
			continue
		var rad := d - E.n * h
		var r := rad.length()
		if r < 1e-6:
			continue
		var a := atan2(rad.dot(E.t2), rad.dot(E.t1))
		var e := r - E.rh(a)
		if e >= E.w:
			continue
		var s := clampf(E.w - e, 0.0, E.w * 1.25)
		var ang := E.bend * E.petal(a) * (s / E.w)
		out += E.n * (s * sin(ang)) + rad / r * (s * (1.0 - cos(ang)))
	return out


# Inward buckling: the ring round a hole, or a dent on its own, with wrinkles.
static func buckle_at(P: Vector3, ents: Array) -> Vector3:
	var out := Vector3.ZERO
	for x in ents:
		var E: Ent = x
		var d := P - E.c
		if d.length_squared() > E.inf2:
			continue
		var h := d.dot(E.n)
		if h < -E.R * 0.6 or h > E.R * 0.6:
			continue
		var rad := d - E.n * h
		var r := rad.length()
		var nzv := _nz(P * (4.0 / E.R) + Vector3(E.p[6], E.p[7], E.p[0]))
		if E.kind == 0:
			var u := r / E.R
			if u >= 1.0:
				continue
			var f := (1.0 - u * u)
			out -= E.n * (E.depth * (f * f * (0.65 + 0.35 * nzv) + 0.22 * sin(u * 13.0 + nzv * 3.0) * (1.0 - u)))
		else:
			var a := atan2(rad.dot(E.t2), rad.dot(E.t1)) if r > 1e-6 else 0.0
			var e := maxf(r - E.rh(a), 0.0)
			var u := e / (E.R * 1.4)
			if u >= 1.0:
				continue
			var amp := E.buckle * E.R * (1.0 - u) * (1.0 - u) * (0.6 + 0.4 * nzv) * (0.3 + 0.7 * smoothstep(0.0, E.w, e))
			amp += E.buckle * E.R * 0.2 * sin(u * 11.0 + nzv * 2.5) * (1.0 - u)
			out -= E.n * amp
	return out


# Which hole removes the triangle whose centre is Q (-1: none): inside the torn outline, or in a radial tear between petals.
static func removed_by(Q: Vector3, ents: Array) -> int:
	for i in ents.size():
		var E: Ent = ents[i]
		if E.kind != 1:
			continue
		var d := Q - E.c
		if d.length_squared() > E.cutr2:
			continue
		var h := d.dot(E.n)
		if h < -E.cut or h > E.R * 0.8:
			continue
		var rad := d - E.n * h
		var r := rad.length()
		var a := atan2(rad.dot(E.t2), rad.dot(E.t1)) if r > 1e-6 else 0.0
		var e := r - E.rh(a)
		if e < 0.0:
			return i
		var tw := E.w * 0.85
		if e < tw and E.tear(a) < 0.1 * (1.0 - e / tw) + 0.01:
			return i
	return -1


# The hole whose torn ring holds P (-1: none).
static func owner_of(P: Vector3, ents: Array) -> int:
	var best := -1
	var bv := 1e9
	for i in ents.size():
		var E: Ent = ents[i]
		if E.kind != 1:
			continue
		var d := P - E.c
		if d.length_squared() > E.cutr2:
			continue
		var h := d.dot(E.n)
		var rad := d - E.n * h
		var r := rad.length()
		var a := atan2(rad.dot(E.t2), rad.dot(E.t1)) if r > 1e-6 else 0.0
		var v := (r - E.rh(a)) / E.R
		if v < bv:
			bv = v
			best = i
	return best


# The cavity floor under skin point P of hole E: pushed in deepest at the middle, meeting the skin at the outer ring.
static func cup_at(P: Vector3, E: Ent, ents: Array) -> Vector3:
	var d := P - E.c
	var h := d.dot(E.n)
	var rad := d - E.n * h
	var r := rad.length()
	var a := atan2(rad.dot(E.t2), rad.dot(E.t1)) if r > 1e-6 else 0.0
	var e := r - E.rh(a)
	var deep := smoothstep(E.w * 0.9, -E.R * 0.45, e)
	var rubble := E.D * 0.14 * _nz(P * (6.0 / E.R) + Vector3(E.p[1], E.p[2], E.p[3])) * deep
	return P + buckle_at(P, ents) - E.n * (E.th + E.D * deep + rubble)


# ---------------------------------------------------------------- the worker: cut, peel, buckle and build the cavity

static func _tri(pt: Part, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, want: Vector3, col: Color) -> void:
	# Godot's front faces wind clockwise: the geometric cross product points away from the wanted normal
	if (b - a).cross(c - a).dot(want) > 0.0:
		var t := b
		b = c
		c = t
		var tn := nb
		nb = nc
		nc = tn
	pt.pos.append(a)
	pt.pos.append(b)
	pt.pos.append(c)
	pt.nrm.append(na)
	pt.nrm.append(nb)
	pt.nrm.append(nc)
	pt.col.append(col)
	pt.col.append(col)
	pt.col.append(col)


static func _quad(pt: Part, a: Vector3, b: Vector3, c: Vector3, d: Vector3, nrm: Vector3, col: Color) -> void:
	_tri(pt, a, b, c, nrm, nrm, nrm, nrm, col)
	_tri(pt, a, c, d, nrm, nrm, nrm, nrm, col)


static func _qk(p: Vector3, q: float) -> Vector3i:
	return Vector3i(roundi(p.x / q), roundi(p.y / q), roundi(p.z / q))


static func _edge_key(a: Vector3, b: Vector3, q: float) -> Array:
	var ka := _qk(a, q)
	var kb := _qk(b, q)
	return [ka, kb] if ka < kb else [kb, ka]


# job: {surfs: [{arrays, xf, aabb (ship frame)}], ents: Array of Ent, q: weld size}. Returns {surfs: [new arrays or
# null], parts: [Part per entry]}.
static func compute(job: Dictionary) -> Dictionary:
	var t_ms := Time.get_ticks_msec()
	var ents: Array = job["ents"]
	var q: float = job["q"]
	var parts: Array = []
	for e in ents:
		parts.append(Part.new())
	var out_s: Array = []
	var edges := {}
	for sd in job["surfs"]:
		var aabb: AABB = sd["aabb"]
		var hit := false
		for x in ents:
			var E: Ent = x
			if aabb.grow(sqrt(E.inf2)).has_point(E.c):
				hit = true
				break
		if not hit:
			out_s.append(null)
			continue
		out_s.append(_surface(sd, ents, parts, edges, q))
	# the torn edge: the skin's thickness along every edge between a kept and a removed triangle
	for key in edges:
		var ed: Dictionary = edges[key]
		if int(ed.get("k", 0)) < 1 or int(ed.get("r", 0)) < 1:
			continue
		var E: Ent = ents[int(ed["own"])]
		var pt: Part = parts[int(ed["own"])]
		var a: Vector3 = ed["a"]
		var b: Vector3 = ed["b"]
		var na: Vector3 = ed["na"]
		var nb: Vector3 = ed["nb"]
		var a2 := a - na * E.th
		var b2 := b - nb * E.th
		var mid := (a + b) * 0.5
		var inw: Vector3 = mid - (ed["kc"] as Vector3)
		inw = (inw - na * inw.dot(na)).normalized()
		var col := Color(PART_LIP, 0.5 + 0.5 * _nz(mid * 9.0 / E.R), 0, 1)
		_quad(pt, a, b, b2, a2, inw, col)
		_quad(pt, a, b, b2, a2, -inw, col)
	# frames and deck layers sliced through each cavity
	for i in ents.size():
		var E: Ent = ents[i]
		if E.kind == 1 and not E.through:
			_walls(parts[i], E)
	return {"surfs": out_s, "parts": parts, "ms": Time.get_ticks_msec() - t_ms}


static func _surface(sd: Dictionary, ents: Array, parts: Array, edges: Dictionary, q: float):
	var arr: Array = sd["arrays"]
	var xf: Transform3D = sd["xf"]
	var V: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var N := PackedVector3Array()
	if arr[Mesh.ARRAY_NORMAL] != null:
		N = arr[Mesh.ARRAY_NORMAL]
	var has_n := N.size() == V.size()
	var P: PackedVector3Array = xf * V
	var nb: Basis = xf.basis.inverse().transposed()
	var back: Basis = xf.basis.transposed()
	var nv := P.size()
	var near := PackedByteArray()
	near.resize(nv)
	var Dp := P.duplicate()
	var NR := PackedVector3Array()
	NR.resize(nv)
	var pm := PackedFloat32Array()
	pm.resize(nv)
	var N2 := N.duplicate()
	var changed := false
	var eps_r := 1e9
	for x in ents:
		eps_r = minf(eps_r, (x as Ent).R)
	var eps := eps_r * 0.04
	for i in nv:
		var p := P[i]
		var lvl := 0
		for x in ents:
			var E: Ent = x
			var d2 := (p - E.c).length_squared()
			if d2 < E.inf2:
				if lvl == 0:
					lvl = 1
				if E.kind == 1 and d2 < E.cutr2:
					lvl = 2
		if lvl == 0:
			continue
		near[i] = lvl
		var nr := (nb * N[i]).normalized() if has_n else Vector3.UP
		var pv := peel_at(p, ents)
		var dv := pv + buckle_at(p, ents)
		pm[i] = pv.length()
		NR[i] = nr
		if dv.length_squared() < 1e-12:
			continue
		changed = true
		var dp := p + dv
		Dp[i] = dp
		var ta := nr.cross(Vector3.UP if absf(nr.y) < 0.9 else Vector3.RIGHT).normalized()
		var tb := nr.cross(ta)
		var pa := p + ta * eps
		pa += peel_at(pa, ents) + buckle_at(pa, ents)
		var pb := p + tb * eps
		pb += peel_at(pb, ents) + buckle_at(pb, ents)
		var nn := (pa - dp).cross(pb - dp)
		if nn.length_squared() > 1e-20:
			nn = nn.normalized()
			NR[i] = nn
			if has_n:
				N2[i] = (back * nn).normalized()
	var idx := PackedInt32Array()
	if arr[Mesh.ARRAY_INDEX] != null:
		idx = arr[Mesh.ARRAY_INDEX]
	var indexed := idx.size() > 0
	var nt := (idx.size() if indexed else nv) / 3
	var keep := PackedInt32Array()
	var removed_any := false
	var tri_i := PackedInt32Array([0, 0, 0])
	for t in nt:
		var i0 := idx[t * 3] if indexed else t * 3
		var i1 := idx[t * 3 + 1] if indexed else t * 3 + 1
		var i2 := idx[t * 3 + 2] if indexed else t * 3 + 2
		var l0 := near[i0]
		var l1 := near[i1]
		var l2 := near[i2]
		if l0 == 0 and l1 == 0 and l2 == 0:
			keep.append(i0)
			keep.append(i1)
			keep.append(i2)
			continue
		var cz := l0 == 2 or l1 == 2 or l2 == 2
		var a := P[i0]
		var b := P[i1]
		var c := P[i2]
		var Q := (a + b + c) / 3.0
		var ri := removed_by(Q, ents) if cz else -1
		if ri >= 0:
			removed_any = true
			var E: Ent = ents[ri]
			for pr in [[a, b], [b, c], [c, a]]:
				var key := _edge_key(pr[0], pr[1], q)
				var ed: Dictionary = edges.get(key, {})
				ed["r"] = int(ed.get("r", 0)) + 1
				ed["own"] = ri
				edges[key] = ed
			if not E.through:
				_cup_tri(parts[ri], E, ents, a, b, c, _nrm_of(NR, N, nb, has_n, i0) + _nrm_of(NR, N, nb, has_n, i1) + _nrm_of(NR, N, nb, has_n, i2))
			continue
		keep.append(i0)
		keep.append(i1)
		keep.append(i2)
		if not cz:
			continue
		tri_i[0] = i0
		tri_i[1] = i1
		tri_i[2] = i2
		var kc := (Dp[i0] + Dp[i1] + Dp[i2]) / 3.0
		for e3 in 3:
			var ia := tri_i[e3]
			var ib := tri_i[(e3 + 1) % 3]
			var key := _edge_key(P[ia], P[ib], q)
			var ed: Dictionary = edges.get(key, {})
			ed["k"] = int(ed.get("k", 0)) + 1
			ed["a"] = Dp[ia]
			ed["b"] = Dp[ib]
			ed["na"] = _nrm_of(NR, N, nb, has_n, ia)
			ed["nb"] = _nrm_of(NR, N, nb, has_n, ib)
			ed["kc"] = kc
			edges[key] = ed
		var ow := owner_of(Q, ents)
		if ow < 0:
			continue
		var Eo: Ent = ents[ow]
		var n0 := _nrm_of(NR, N, nb, has_n, i0)
		var n1 := _nrm_of(NR, N, nb, has_n, i1)
		var n2 := _nrm_of(NR, N, nb, has_n, i2)
		var nsum := n0 + n1 + n2
		# the back of the skin round the hole (and of the peeled plates), a plate's thickness in
		var pt: Part = parts[ow]
		var shade := 0.35 + 0.3 * _nz(Q * 5.0 / Eo.R)
		_tri(pt, Dp[i0] - n0 * Eo.th, Dp[i1] - n1 * Eo.th, Dp[i2] - n2 * Eo.th, -n0, -n1, -n2, -nsum, Color(PART_SKIN, shade, 0, 1))
		if maxf(pm[i0], maxf(pm[i1], pm[i2])) > Eo.R * 0.01 and not Eo.through:
			_cup_tri(pt, Eo, ents, a, b, c, nsum)
	if not changed and not removed_any:
		return null
	var na := arr.duplicate()
	na[Mesh.ARRAY_VERTEX] = xf.affine_inverse() * Dp
	if has_n:
		na[Mesh.ARRAY_NORMAL] = N2
	na[Mesh.ARRAY_INDEX] = keep
	return na


static func _nrm_of(NR: PackedVector3Array, N: PackedVector3Array, nb: Basis, has_n: bool, i: int) -> Vector3:
	var v := NR[i]
	if v != Vector3.ZERO:
		return v
	return (nb * N[i]).normalized() if has_n else Vector3.UP


static func _cup_tri(pt: Part, E: Ent, ents: Array, a: Vector3, b: Vector3, c: Vector3, nsum: Vector3) -> void:
	var fa := cup_at(a, E, ents)
	var fb := cup_at(b, E, ents)
	var fc := cup_at(c, E, ents)
	var fn := (fb - fa).cross(fc - fa)
	if fn.length_squared() < 1e-20:
		return
	fn = fn.normalized()
	if fn.dot(nsum + E.n) < 0.0:
		fn = -fn
	var shade := 0.4 + 0.3 * _nz((a + b + c) * (3.0 / E.R))
	_tri(pt, fa, fb, fc, fn, fn, fn, fn, Color(PART_CUP, shade, 0, 1))
	pt.cup_f.append(fa)
	pt.cup_f.append(fb)
	pt.cup_f.append(fc)
	pt.cup_o.append(a + buckle_at(a, ents))
	pt.cup_o.append(b + buckle_at(b, ents))
	pt.cup_o.append(c + buckle_at(c, ents))


# Frames (across the ship) and deck layers (level; stringers when the hole faces up or down) sliced through the cavity:
# each slice of the floor is stood up as a wall to just under the skin, with a jagged broken top, some blown away.
static func _walls(pt: Part, E: Ent) -> void:
	var fam: Array = []
	var ax_a := Vector3.RIGHT if absf(E.n.x) < 0.75 else Vector3.BACK
	fam.append([ax_a, E.R * 0.5, E.p[4] / TAU * E.R * 0.5, 0.55])
	if absf(E.n.y) < 0.7:
		fam.append([Vector3.UP, E.R * 0.7, E.p[5] / TAU * E.R * 0.7, 0.75])
	var tw := E.R * 0.028
	var F := pt.cup_f
	var O := pt.cup_o
	var nt := F.size() / 3
	for f in fam:
		var ax: Vector3 = f[0]
		var spc: float = f[1]
		var off: float = f[2]
		var shade: float = f[3]
		var o := ax * (tw * 0.5)
		for t in nt:
			var f0 := F[t * 3]
			var f1 := F[t * 3 + 1]
			var f2 := F[t * 3 + 2]
			var d0 := f0.dot(ax)
			var d1 := f1.dot(ax)
			var d2 := f2.dot(ax)
			var k0 := ceili((minf(d0, minf(d1, d2)) - off) / spc)
			var k1 := floori((maxf(d0, maxf(d1, d2)) - off) / spc)
			for kk in range(k0, k1 + 1):
				var v := off + kk * spc
				var pf := PackedVector3Array()
				var po := PackedVector3Array()
				for e3 in 3:
					var ia := t * 3 + e3
					var ib := t * 3 + (e3 + 1) % 3
					var da := F[ia].dot(ax) - v
					var db := F[ib].dot(ax) - v
					if da * db < 0.0:
						var u := da / (da - db)
						pf.append(F[ia].lerp(F[ib], u))
						po.append(O[ia].lerp(O[ib], u))
				if pf.size() != 2:
					continue
				var dep := ((po[0] - pf[0]).length() + (po[1] - pf[1]).length()) * 0.5
				if dep < E.th * 2.2:
					continue
				var mid := (pf[0] + pf[1]) * 0.5
				if _nz(mid * (3.0 / E.R) + Vector3(E.p[2], kk, E.p[3])) > 0.3:
					continue
				var tf0 := 0.88 + 0.06 * _nz(pf[0] * (5.0 / E.R))
				var tf1 := 0.88 + 0.06 * _nz(pf[1] * (5.0 / E.R))
				var t0 := pf[0].lerp(po[0], tf0)
				var t1 := pf[1].lerp(po[1], tf1)
				var col := Color(PART_WALL, shade, 0, 1)
				_quad(pt, pf[0] + o, pf[1] + o, t1 + o, t0 + o, ax, col)
				_quad(pt, pf[0] - o, pf[1] - o, t1 - o, t0 - o, -ax, col)
				var up := ((po[0] - pf[0]) + (po[1] - pf[1])).normalized()
				_quad(pt, t0 + o, t1 + o, t1 - o, t0 - o, up, col)


# ---------------------------------------------------------------- main thread: conduits, cables, the emitters

static func _tube(pt: Part, pts: PackedVector3Array, r0: float, r1: float, col: Color) -> void:
	var n := pts.size()
	if n < 2:
		return
	var sides := 6
	var prev_ring: Array = []
	for i in n:
		var tng := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var s1 := tng.cross(Vector3.UP if absf(tng.y) < 0.9 else Vector3.RIGHT).normalized()
		var s2 := tng.cross(s1)
		var rr := lerpf(r0, r1, float(i) / float(n - 1))
		var ring: Array = []
		for k in sides:
			var an := TAU * k / sides
			var dn := s1 * cos(an) + s2 * sin(an)
			ring.append([pts[i] + dn * rr, dn])
		if i > 0:
			for k in sides:
				var a: Array = prev_ring[k]
				var b: Array = prev_ring[(k + 1) % sides]
				var c: Array = ring[(k + 1) % sides]
				var d: Array = ring[k]
				var want: Vector3 = (a[1] as Vector3) + (c[1] as Vector3)
				_tri(pt, a[0], b[0], c[0], a[1], b[1], c[1], want, col)
				_tri(pt, a[0], c[0], d[0], a[1], c[1], d[1], want, col)
		prev_ring = ring


# Conduits running fore and aft across the cavity (some torn apart), and cables trailing out of the hole. Returns the
# torn ends and cable tips, where the sparks go: [[pos, dir], ...].
static func conduits(hull, pt: Part, E: Ent, ents: Array, r: RandomNumberGenerator) -> Array:
	var ends: Array = []
	if E.through or hull == null:
		return ends
	var u := (Vector3.RIGHT - E.n * E.n.x)
	if u.length_squared() < 0.05:
		u = E.t1
	u = u.normalized()
	var v := E.n.cross(u)
	var npipe := 2 + (1 if E.R > 1.2 else 0)
	for j in npipe:
		var off := (r.randf() - 0.5) * E.R * 1.1
		var lf := 0.3 + r.randf() * 0.4
		var pr := E.R * (0.03 + r.randf() * 0.03)
		var broken := r.randf() < 0.75
		var gc := (r.randf() - 0.5) * E.R * 0.8
		var gw := E.R * (0.12 + r.randf() * 0.25) if broken else 0.0
		var pts: Array = []      # per sample: a point, or 0 (torn gap), or 1 (no hull under it)
		var s := -E.R * 1.4
		var col := Color(PART_PIPE, 0.3 + 0.5 * r.randf(), 0, 1)
		while s <= E.R * 1.4 + 1e-4:
			if absf(s - gc) < gw:
				pts.append(0)
			else:
				var Q := E.c + u * s + v * off
				var h: Dictionary = hull.ray(Q + E.n * E.R * 1.5, -E.n)
				if h.is_empty():
					pts.append(1)
				else:
					var Os: Vector3 = h["p"]
					var dd := Os - E.c
					var rad := dd - E.n * dd.dot(E.n)
					var rr := rad.length()
					var a := atan2(rad.dot(E.t2), rad.dot(E.t1)) if rr > 1e-6 else 0.0
					if rr - E.rh(a) > E.w * 0.9:
						pts.append(Os + buckle_at(Os, ents) - E.n * (E.th + pr * 1.3))
					else:
						var Fp := cup_at(Os, E, ents)
						var dep := (Os - Fp).dot(E.n)
						pts.append(Fp + E.n * clampf(dep * lf, pr * 1.2, maxf(dep - E.th - pr, pr * 1.2)))
			s += E.R * 0.15
		var k0 := 0
		while k0 < pts.size():
			if not (pts[k0] is Vector3):
				k0 += 1
				continue
			var k1 := k0
			var seg := PackedVector3Array()
			while k1 < pts.size() and pts[k1] is Vector3:
				seg.append(pts[k1])
				k1 += 1
			if seg.size() >= 2:
				_tube(pt, seg, pr, pr, col)
				if k0 > 0 and pts[k0 - 1] is int and int(pts[k0 - 1]) == 0:
					ends.append([seg[0], -u])
				if k1 < pts.size() and pts[k1] is int and int(pts[k1]) == 0:
					ends.append([seg[seg.size() - 1], u])
			k0 = k1
	var ncab := 1 + (1 if E.bend > 1.0 else 0)
	for j in ncab:
		var an := r.randf() * TAU
		var rr := E.R * (0.25 + r.randf() * 0.35)
		var Q := E.c + (E.t1 * cos(an) + E.t2 * sin(an)) * rr
		var h: Dictionary = hull.ray(Q + E.n * E.R * 1.5, -E.n)
		if h.is_empty():
			continue
		var Fp := cup_at(h["p"], E, ents)
		var dep := ((h["p"] as Vector3) - Fp).dot(E.n)
		var st := Fp + E.n * dep * 0.25
		var rd := (E.t1 * cos(an) + E.t2 * sin(an))
		var side := E.n.cross(rd)
		var Lc := E.R * (0.45 + r.randf() * 0.35) + dep
		var ph := r.randf() * TAU
		var pts := PackedVector3Array()
		for k in 8:
			var tt := k / 7.0
			pts.append(st + E.n * (tt * Lc * 0.75) + rd * (tt * tt * Lc * 0.6) + side * (sin(tt * 4.0 + ph) * Lc * 0.08))
		_tube(pt, pts, E.R * 0.024, E.R * 0.018, Color(PART_PIPE, 0.15, 0, 1))
		ends.append([pts[7], (pts[7] - pts[6]).normalized()])
	return ends


# The interior's mesh, with its own material (the fire point and the opening time live in its uniforms).
static func interior_node(fx, parent: Node3D, pt: Part, E: Ent, glow: Color) -> MeshInstance3D:
	if pt.pos.size() < 3:
		return null
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = pt.pos
	arr[Mesh.ARRAY_NORMAL] = pt.nrm
	arr[Mesh.ARRAY_COLOR] = pt.col
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.name = "fx_breach_inside"
	mi.mesh = am
	var m: ShaderMaterial = fx.mat(SH.HOLE, 0)
	m.set_shader_parameter("fire", E.c - E.n * (E.D * 0.55 if not E.through else E.R * 0.2))
	m.set_shader_parameter("R", E.R)
	m.set_shader_parameter("centre", E.c)
	m.set_shader_parameter("axis", E.n)
	m.set_shader_parameter("t0", E.t0)
	m.set_shader_parameter("heat", 1.0 if E.bend > 1.0 else 0.75)
	m.set_shader_parameter("seed", E.seed_v)
	m.set_shader_parameter("glow", Vector3(glow.r, glow.g, glow.b))
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


# Fire, embers, thin smoke, venting gas and sparks for one hole, all from inside it (repeating on the effect clock, so a
# rebuild does not restart them).
static func emitters(b: POOLS.Batch, bs: POOLS.Batch, E: Ent, ents: Array, ends: Array, r: RandomNumberGenerator, glow: Color) -> void:
	var q := POOLS.quad_shape()
	var qs := POOLS.streak_shape()
	var R := E.R
	var hot := E.bend > 1.0
	var floor_pts: Array = []
	for j in (3 if hot else 2):
		var an := r.randf() * TAU
		var p := E.c + (E.t1 * cos(an) + E.t2 * sin(an)) * R * r.randf() * 0.45
		floor_pts.append(cup_at(p, E, ents) + E.n * R * 0.05 if not E.through else p)
	# flames licking up out of the hole
	for fp in floor_pts:
		var P: Vector3 = fp
		for kk in 9:
			var v := E.n * R * (1.3 + r.randf() * 0.9) + E.t1 * (r.randf() - 0.5) * R * 0.5 + E.t2 * (r.randf() - 0.5) * R * 0.5
			b.add(q, POOLS.pack(Vector4(P.x, P.y, P.z, -20.0 + kk * 0.09), Vector4(v.x, v.y, v.z, 0.55 + r.randf() * 0.3),
				Vector4(glow.r, glow.g, glow.b, 2.0), Vector4(R * 0.22, R * 0.55, 1, r.randf()), Vector4(0.8, 0, 0, 0)))
	# embers drifting off
	var P0: Vector3 = floor_pts[0]
	for kk in (10 if hot else 6):
		var v := (E.n * 1.0 + Vector3(r.randf() - 0.5, r.randf() - 0.5, r.randf() - 0.5) * 0.9).normalized() * R * (0.5 + r.randf() * 0.9)
		b.add(q, POOLS.pack(Vector4(P0.x, P0.y, P0.z, -20.0 + kk * 0.37 + r.randf() * 0.2), Vector4(v.x, v.y, v.z, 3.2),
			Vector4(glow.r, glow.g, glow.b, 2.0), Vector4(R * 0.07, R * 0.03, 19, r.randf()), Vector4(3.9, 0, 0.3, 0)))
	# thin smoke: a few soft wisps that rise and thin out
	for kk in 3:
		var v := E.n * R * 1.4 + Vector3(0, R * 0.2, 0)
		b.add(q, POOLS.pack(Vector4(P0.x, P0.y, P0.z, -20.0 + kk * 0.9 + r.randf() * 0.2), Vector4(v.x, v.y, v.z, 2.7),
			Vector4(0.1, 0.095, 0.09, 0.2), Vector4(R * 0.35, R * 1.7, 3, r.randf()), Vector4(2.7, 0, 0.7, 0.3)))
	# gas venting from a torn conduit (or the floor), puffing
	var vp: Vector3 = P0
	var vd: Vector3 = E.n
	if not ends.is_empty():
		vp = ends[0][0]
		vd = ((ends[0][1] as Vector3) * 0.5 + E.n).normalized()
	for kk in 16:
		var tk := -20.0 + kk * 0.08
		var puff := 0.7 + 0.3 * sin(kk * 0.9)
		var v := (vd + E.t1 * sin(kk * 0.45) * 0.15).normalized() * R * (3.2 + r.randf()) * puff
		b.add(q, POOLS.pack(Vector4(vp.x, vp.y, vp.z, tk), Vector4(v.x, v.y, v.z, 1.1), Vector4(0.62, 0.68, 0.78, 0.22 * puff),
			Vector4(R * 0.07, R * 0.7, 7, r.randf()), Vector4(1.3, 0, 0.8, r.randf() - 0.5)))
	# sparks at torn conduit ends and cable tips, each on its own beat
	for e2 in ends:
		var sp: Vector3 = e2[0]
		var sd: Vector3 = e2[1]
		var per := 0.9 + r.randf() * 1.6
		var off := r.randf() * per
		for kk in 7:
			var v := (sd + E.n * 0.4 + Vector3(r.randf() - 0.5, r.randf() - 0.5, r.randf() - 0.5) * 0.9).normalized() * R * (2.5 + r.randf() * 4.0)
			bs.add(qs, POOLS.pack(Vector4(sp.x, sp.y, sp.z, off + r.randf() * 0.06), Vector4(v.x, v.y, v.z, 0.25 + r.randf() * 0.3),
				Vector4(1.0, 0.75, 0.45, 5.0), Vector4(0.035, R * 0.035, 2.2, 1), Vector4(per, 0, 0, 0)))
		b.add(q, POOLS.pack(Vector4(sp.x, sp.y, sp.z, off), Vector4(0, 0, 0, 0.12), Vector4(1.0, 0.8, 0.55, 2.5),
			Vector4(R * 0.05, R * 0.12, 2, r.randf()), Vector4(per, 0, 0, 0)))


# ---------------------------------------------------------------- ship side: gather, rebuild, apply

# The hull's original surfaces, once per ship (reusing the death cut's copy when it has one).
static func gather(s) -> Array:
	var out: Array = []
	var inv: Transform3D = s.root.global_transform.affine_inverse()
	for m in s.meshes:
		var mi := m as MeshInstance3D
		if mi == null or not (mi.mesh is ArrayMesh) or not mi.is_inside_tree():
			continue
		var am: ArrayMesh = mi.mesh
		if am.get_blend_shape_count() > 0:
			continue
		var xf: Transform3D = inv * mi.global_transform
		var aabb: AABB = xf * am.get_aabb()
		for si in am.get_surface_count():
			if am.surface_get_primitive_type(si) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			out.append({"mi": mi, "si": si, "arrays": am.surface_get_arrays(si), "xf": xf, "aabb": aabb,
				"fmt": am.surface_get_format(si), "mat": am.surface_get_material(si), "mesh": am,
				"ov": mi.get_surface_override_material(si), "n": am.get_surface_count()})
	return out


# Put the worker's result on the ship: the rebuilt hull meshes (or the originals back where nothing is damaged now),
# then the cavities, conduits, emitters and lights.
static func apply(fx, s, job: Dictionary) -> void:
	var res: Dictionary = job.get("out", {})
	if res.is_empty():
		return
	var orig: Array = job["surfs"]
	var outs: Array = res["surfs"]
	var by_mi := {}
	for k in orig.size():
		var sd: Dictionary = orig[k]
		var mi: MeshInstance3D = sd["mi"]
		if not is_instance_valid(mi):
			continue
		if not by_mi.has(mi):
			by_mi[mi] = []
		(by_mi[mi] as Array).append(k)
	for mi in by_mi:
		var ks: Array = by_mi[mi]
		var any := false
		for k in ks:
			if outs[k] != null:
				any = true
		var sd0: Dictionary = orig[ks[0]]
		var src: ArrayMesh = sd0["mesh"]
		if not any:
			if mi.mesh != src:
				mi.mesh = src
				_restore_overrides(mi, orig, ks)
			continue
		if int(sd0["n"]) != ks.size():
			continue   # a surface we could not rebuild (not triangles): leave this mesh whole
		var am := ArrayMesh.new()
		for k in ks:
			var sd: Dictionary = orig[k]
			var arrays: Array = outs[k] if outs[k] != null else sd["arrays"]
			var flags := int(sd["fmt"]) & Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
			am.surface_set_material(am.get_surface_count() - 1, sd["mat"])
		mi.mesh = am
		_restore_overrides(mi, orig, ks)
	# the cavities and everything that comes out of them
	clear_nodes(s)
	var ents: Array = job["ents"]
	var parts: Array = res["parts"]
	var glow := Color(0.55, 1.0, 0.2) if s.faction == "chorus" else Color(1.0, 0.45, 0.12)
	var b := POOLS.Batch.new()
	var bs := POOLS.Batch.new()
	var r := RandomNumberGenerator.new()
	for i in ents.size():
		var E: Ent = ents[i]
		if E.kind != 1:
			continue
		r.seed = int(E.seed_v * 1000.0) + 5
		var pt: Part = parts[i]
		var ends: Array = conduits(s.hull, pt, E, ents, r)
		var mi := interior_node(fx, s._dmg_root, pt, E, glow)
		if mi != null:
			s._hole_nodes.append(mi)
		emitters(b, bs, E, ents, ends, r, glow)
		var holder := Node3D.new()
		holder.position = E.c + E.n * E.R * 0.35
		s._dmg_root.add_child(holder)
		s._hole_nodes.append(holder)
		s._hole_lights.append(fx.light_source(holder, Vector3.ZERO, Color(glow.r, glow.g * 0.9, glow.b), 1.3 + 0.7 * float(E.bend > 1.0), 0.4))
	var hb := Node3D.new()
	hb.name = "fx_breach_fx"
	s._dmg_root.add_child(hb)
	s._hole_nodes.append(hb)
	b.build(fx.mat(SH.SPRITE, 1, "#define SOFT\n" if fx.quality != "low" else ""), hb, "fx_breach_sprites")
	bs.build(fx.mat(SH.STREAK, 1), hb, "fx_breach_sparks")


static func _restore_overrides(mi: MeshInstance3D, orig: Array, ks: Array) -> void:
	for k in ks:
		var sd: Dictionary = orig[k]
		if sd["ov"] != null and int(sd["si"]) < mi.get_surface_override_material_count():
			mi.set_surface_override_material(int(sd["si"]), sd["ov"])


static func clear_nodes(s) -> void:
	for n in s._hole_nodes:
		if is_instance_valid(n):
			(n as Node).queue_free()
	s._hole_nodes = []
	for l in s._hole_lights:
		l["on"] = false
	s._hole_lights = []
