extends RefCounted
# Hull damage that changes the ship itself: the section breaches (Ryan, R39) and every weapon's own mark (R43).
#
# Each piece of damage is an entry (Ent) in the ship root's frame with a kind (what it does to the mesh) and a style
# (how its surface reads):
#   kind 0 dent      skin pushed in with wrinkles; style ram folds it (crumpled bow plating)
#   kind 1 hole      a torn outline cut out of the hull, plates peeled back (bend > 0: outward; < 0: blown inward, a
#                    torpedo), the ring round it buckled, a cavity behind it; breach, gauss entry and exit, boarding hatch
#   kind 2 slot      a narrow burn-through along a line with raised molten lips (lance and laser)
#   kind 3 crater    a melted bowl with a splashed rim, no hole (shells, plasma, rockets)
#   kind 4 cluster   many small pits over an area, a few torn through (flak, acid), spine shafts stuck in (Chorus)
#   kind 5 surface   no shape change, only the surface pattern (ion burns)
# The mesh work runs on a worker thread from the hull's original arrays, visiting only grid cells near the damage:
# triangles inside an outline become zero-area ones, the skin near it is displaced with new normals, and the pieces of
# each cavity (rubble floor, frames and decks, conduits, cables, plate backs, the cut edge) and a thin overlay skin over
# each mark (char, molten metal cooling white to red to black, slag, acid etching, electrical burns) are built. A ship
# carries one interior mesh and one overlay mesh, whatever the number of marks; each vertex carries its mark's data.
# The rebuilt hull keeps its own materials and vertex format, so nothing new compiles.
#
# A4's pre-cut breach parts (API.md 14) replace the generic breach cut where they exist.

const SH := preload("res://fx/fx_shaders.gd")
const POOLS := preload("res://fx/fx_pool.gd")

const PART_CUP := 0.0
const PART_SKIN := 0.25
const PART_WALL := 0.5
const PART_PIPE := 0.75
const PART_BONE := 0.85
const PART_LIP := 1.0

const K_DENT := 0
const K_HOLE := 1
const K_SLOT := 2
const K_CRATER := 3
const K_CLUSTER := 4
const K_SURFACE := 5

# styles (the surface pattern and the inside's glow), shared with the shaders
const S_BREACH := 0
const S_BURN := 1
const S_SHELL := 2
const S_PLASMA := 3
const S_GAUSS_IN := 4
const S_GAUSS_OUT := 5
const S_BLAST := 6
const S_FLAK := 7
const S_ACID := 8
const S_ION := 9
const S_RAM := 10
const S_HATCH := 11
const S_DENT := 12
const S_SCORCH := 13      # the stage ladder's spreading scorch (fx_ship._plan)

const MARK_CAP := 12      # weapon marks per ship (section breaches come on top)
const SEC_MARK_CAP := 4   # ... and per hull section; past it a repeat grows an old mark or the lightest old mark goes
const GROW_MAX := 1.6     # how far repeats can grow a mark (lance slots lengthen, craters widen, ion trees spread)
# The smallest halo per mark style, in world units (the game's scale: hexes 17.3 across; the battle camera sits 170 away,
# about 7.7 pixels a unit at 1080p). Claude's picks, vetoable; tuned on the r5 battle-distance stills.
const HALO_MIN := {S_BURN: 1.1, S_SHELL: 1.3, S_PLASMA: 1.6, S_GAUSS_IN: 1.1, S_GAUSS_OUT: 1.4, S_BLAST: 2.8,
	S_FLAK: 1.7, S_ACID: 1.7, S_ION: 2.3, S_RAM: 2.6, S_HATCH: 1.6}
const HALO_MAX_L := 0.16   # ... but never wider than this share of the ship's length (a frigate is not one big scorch; r8 0.12 to 0.16 so frigate hits carry at 170 units)


class Ent:
	var kind := 1
	var style := 0
	var c := Vector3.ZERO
	var n := Vector3.UP
	var t1 := Vector3.RIGHT
	var t2 := Vector3.BACK
	var R := 1.0           # hole, slot half-width, crater or dent radius; cluster: area radius
	var w := 0.5           # width of the peeled ring or molten lip
	var bend := 1.0        # petals' bend at the tip (radians; negative: blown inward)
	var buckle := 0.1      # ring buckling, in R
	var depth := 0.0       # dent, crater or pit depth
	var th := 0.05         # skin thickness
	var D := 0.8           # cavity depth
	var cut := 0.5         # how far below the skin triangles are removed
	var through := false
	var k := 5.0           # petals
	var square := false
	var dir := Vector3.RIGHT   # slot direction (tangent)
	var hl := 0.0          # slot half length
	var dx := 1.0          # slot direction in (t1, t2)
	var dy := 0.0
	var subs := PackedVector3Array()   # cluster pits: (x, y, radius) in (t1, t2); radius < 0 tears through
	var ov := 0.0          # overlay radius (0: none)
	var heat := 1.0
	var inf2 := 1.0
	var cutr2 := 0.0
	var p := PackedFloat32Array()
	var seed_v := 0.0
	var t0 := 0.0
	var sec := -1
	var walls := false
	var conduits := false
	# how it was made (marks_for), so a repeat hit can rebuild it bigger instead of stacking a twin
	var look := ""
	var wt := 2
	var ldir := Vector3.ZERO
	var part_i := 0
	var grow := 1.0
	# local refinement (r4: coarse kit plates and AI hull panels are a few big triangles, so a hole or crater smaller
	# than a triangle could not be cut or dented): edges longer than tess within treach of the mark get split first
	var tess := 0.0
	var treach := 0.0
	# the soot or etch halo round the mark (world units), so every mark reads from the battle camera (r4: at 170 units
	# a crater the size of its geometry was a pixel or two); 0: none
	var halo := 0.0

	func rh(a: float) -> float:
		return R * (1.0 + 0.16 * sin(3.0 * a + p[0]) + 0.09 * sin(5.0 * a + p[1]) + 0.05 * sin(9.0 * a + p[2]))

	func petal(a: float) -> float:
		var s := 0.5 + 0.5 * sin(k * a + p[3])
		return smoothstep(0.12, 0.8, s) * (0.7 + 0.3 * sin(2.0 * a + p[4]))

	func tear(a: float) -> float:
		return 0.5 + 0.5 * sin(k * a + p[3])

	# signed distance from (x, y) in the tangent plane to this entry's cut outline (negative inside; 1e9: no cut)
	func edge(x: float, y: float) -> float:
		if kind == 1:
			if square:
				var ca := cos(p[5])
				var sa := sin(p[5])
				var u := x * ca + y * sa
				var v := -x * sa + y * ca
				return maxf(absf(u), absf(v)) - R * (1.0 + 0.05 * sin(u * 9.0 / R + p[0]) + 0.05 * sin(v * 7.0 / R + p[1]))
			return sqrt(x * x + y * y) - rh(atan2(y, x))
		if kind == 2:
			var al := clampf(x * dx + y * dy, -hl, hl)
			var qx := x - dx * al
			var qy := y - dy * al
			var taper := 1.0 - 0.7 * pow(absf(al) / maxf(hl, 1e-4), 4.0)
			return sqrt(qx * qx + qy * qy) - R * taper * (1.0 + 0.25 * sin(al * 7.0 / R + p[0]) + 0.12 * sin(al * 19.0 / R + p[1]))
		if kind == 4:
			var best := 1e9
			for s in subs:
				if s.z < 0.0:
					var ex := x - s.x
					var ey := y - s.y
					best = minf(best, sqrt(ex * ex + ey * ey) + s.z * (1.0 + 0.2 * sin(atan2(ey, ex) * 5.0 + p[2])))
			return best
		return 1e9

	func has_cut() -> bool:
		return kind == 1 or kind == 2 or (kind == 4 and cutr2 > 0.0)


static func _phases(seed_v: float) -> PackedFloat32Array:
	var r := RandomNumberGenerator.new()
	r.seed = int(seed_v * 7919.0) + 17
	var out := PackedFloat32Array()
	for i in 8:
		out.append(r.randf() * TAU)
	return out


static func _base(kind: int, style: int, c: Vector3, n: Vector3, R: float, seed_v: float) -> Ent:
	var e := Ent.new()
	e.kind = kind
	e.style = style
	e.c = c
	e.n = n.normalized()
	e.t1 = e.n.cross(Vector3.UP if absf(e.n.y) < 0.9 else Vector3.RIGHT).normalized()
	e.t2 = e.n.cross(e.t1)
	e.R = R
	e.seed_v = seed_v
	e.p = _phases(seed_v)
	return e


static func _thick(hull, c: Vector3, n: Vector3, R: float) -> float:
	if hull == null:
		return 1e9
	var far: Dictionary = hull.ray(c - n * (R * 0.03), -n)
	if far.is_empty():
		return 1e9
	return ((far["p"] as Vector3) - c).length()


static func dent(c: Vector3, n: Vector3, R: float, depth: float, seed_v: float, style := S_DENT) -> Ent:
	var e := _base(K_DENT, style, c, n, R, seed_v)
	e.depth = depth
	e.inf2 = R * R
	e.ov = R * 1.1 if style == S_RAM else 0.0
	e.tess = R * 0.4
	e.treach = R * 0.9
	return e


# A hole at c (outward normal n). bend: petals' bend (0 none, negative blown inward). The cavity depth comes from how
# thick the hull is under the hole; through thin hull the hole goes right through.
static func hole(hull, c: Vector3, n: Vector3, R: float, bend: float, buckle: float, seed_v: float, style := S_BREACH) -> Ent:
	var e := _base(K_HOLE, style, c, n, R, seed_v)
	e.w = R * (0.5 if absf(bend) > 0.05 else 0.25)
	e.bend = bend
	e.buckle = buckle
	e.th = R * 0.05
	var Dt := _thick(hull, c, e.n, R)
	e.through = Dt < R * 0.7
	e.D = minf(R * (1.2 if style == S_BLAST else 0.85), Dt * 0.42)
	e.cut = (Dt + R * 0.4) if e.through else R * 0.55
	e.k = 4.0 + floorf(e.p[5] / TAU * 2.0)
	if style == S_HATCH:
		e.square = true
		e.k = 1.0
	var inf := R * 2.4 + e.w
	e.inf2 = inf * inf
	var cr := R * 1.35 + e.w
	e.cutr2 = cr * cr
	e.walls = R > 0.0 and style in [S_BREACH, S_BLAST]
	e.conduits = style in [S_BREACH, S_BLAST]
	e.ov = R * (2.2 if style in [S_BREACH, S_BLAST] else (3.4 if style == S_GAUSS_IN else 2.6))    # gauss entry: room for its stress ring
	e.tess = R * 0.4
	e.treach = cr
	if style == S_BREACH:
		# the stage breaches get a soot halo too, so a torn edge never reads as a clean paper cut-out (r6 g15c)
		e.halo = R * 2.4
	return e


# A lance or laser burn-through: a slot of half-width R along dir (a tangent), half length hl.
static func slot(hull, c: Vector3, n: Vector3, dir: Vector3, R: float, hl: float, seed_v: float) -> Ent:
	var e := _base(K_SLOT, S_BURN, c, n, R, seed_v)
	var d := (dir - e.n * dir.dot(e.n))
	if d.length_squared() < 1e-6:
		d = e.t1
	e.dir = d.normalized()
	e.dx = e.dir.dot(e.t1)
	e.dy = e.dir.dot(e.t2)
	e.hl = hl
	e.w = R * 1.6
	e.th = R * 0.12
	var Dt := _thick(hull, c, e.n, R)
	e.through = Dt < R * 1.5
	e.D = minf(R * 1.4, Dt * 0.42)
	e.cut = (Dt + R) if e.through else R * 1.2
	var inf := hl + R * 4.0
	e.inf2 = inf * inf
	var cr := hl + R * 2.5 + e.w
	e.cutr2 = cr * cr
	e.ov = R * 6.0
	e.tess = R * 0.9
	e.treach = R * 3.0
	return e


static func crater(c: Vector3, n: Vector3, R: float, depth: float, seed_v: float, style := S_SHELL) -> Ent:
	var e := _base(K_CRATER, style, c, n, R, seed_v)
	e.depth = depth
	var inf := R * 1.6
	e.inf2 = inf * inf
	e.ov = R * (3.4 if style == S_PLASMA else 2.2)    # plasma: room for the droplet fan
	e.tess = R * 0.45
	e.treach = R * 1.3
	return e


# Pits over an area of radius R: n_pits of radius pr (a share of them torn through).
static func cluster(c: Vector3, n: Vector3, R: float, n_pits: int, pr: float, tear_share: float, seed_v: float, style := S_FLAK) -> Ent:
	var e := _base(K_CLUSTER, style, c, n, R, seed_v)
	var r := RandomNumberGenerator.new()
	r.seed = int(seed_v * 1000.0) + 3
	var any_hole := false
	for i in n_pits:
		var an := r.randf() * TAU
		var rr := R * sqrt(r.randf())
		var s := pr * (0.6 + 0.8 * r.randf())
		if r.randf() < tear_share:
			s = -s * 0.7
			any_hole = true
		e.subs.append(Vector3(cos(an) * rr, sin(an) * rr, s))
	e.depth = pr * 0.5
	e.th = pr * 0.15
	e.D = pr * 1.2
	e.w = pr * 0.8
	e.cut = pr * 2.0
	var inf := R + pr * 2.5
	e.inf2 = inf * inf
	e.cutr2 = inf * inf if any_hole else 0.0
	e.ov = R * 1.35
	if any_hole:
		e.tess = pr * 1.2
		e.treach = R + pr * 2.0
	return e


static func surface(c: Vector3, n: Vector3, R: float, seed_v: float, style := S_ION) -> Ent:
	var e := _base(K_SURFACE, style, c, n, R, seed_v)
	e.inf2 = R * R
	e.ov = R
	return e


# ---------------------------------------------------------------- the displacement fields (pure functions of position)

static func _nz(q: Vector3) -> float:
	return sin(q.x + 1.7 * sin(q.y * 0.8 + 0.3)) * sin(q.y * 1.13 + 1.3 * sin(q.z * 0.9 + 1.1)) * sin(q.z * 0.97 + 1.5 * sin(q.x * 0.7 + 2.3))


# Plates peeling back round holes: a point s from the hinge (the outer edge of the torn ring) turns about the hinge by an
# angle that grows toward the tip, so the plates curl (outward, or inward for a blast).
static func peel_at(P: Vector3, ents: Array) -> Vector3:
	var out := Vector3.ZERO
	for x in ents:
		var E: Ent = x
		if E.kind != K_HOLE or absf(E.bend) < 0.05:
			continue
		var d := P - E.c
		if d.length_squared() > E.cutr2:
			continue
		var h := d.dot(E.n)
		if h < -E.R * 0.45 or h > E.R * 0.8:
			continue
		var lx := d.dot(E.t1)
		var ly := d.dot(E.t2)
		var r := sqrt(lx * lx + ly * ly)
		if r < 1e-6:
			continue
		var e := E.edge(lx, ly)
		if e >= E.w:
			continue
		var a := atan2(ly, lx)
		var s := clampf(E.w - e, 0.0, E.w * 1.25)
		var ang := E.bend * E.petal(a) * (s / E.w)
		var rad := (E.t1 * lx + E.t2 * ly) / r
		out += E.n * (s * sin(ang)) + rad * (s * (1.0 - cos(ang)))
	return out


static func buckle_at(P: Vector3, ents: Array) -> Vector3:
	var out := Vector3.ZERO
	for x in ents:
		var E: Ent = x
		if E.kind == K_SURFACE:
			continue
		var d := P - E.c
		if d.length_squared() > E.inf2:
			continue
		var h := d.dot(E.n)
		if E.style != S_RAM and (h < -E.R * 0.6 - E.depth or h > E.R * 0.6 + E.depth):
			continue
		var lx := d.dot(E.t1)
		var ly := d.dot(E.t2)
		var r := sqrt(lx * lx + ly * ly)
		var nzv := _nz(P * (4.0 / E.R) + Vector3(E.p[6], E.p[7], E.p[0]))
		match E.kind:
			K_DENT:
				if E.style == S_RAM:
					# r8: the bow crumples like a concertina. The falloff is by the full distance (a pointed bow runs back
					# along the hit normal, so the flat-dent band cut it off in a step); rings of folds run round the nose,
					# in and out from its axis; the tip is shoved back and kinked to one side. (r7: only a uniform push
					# back along the bow, which left the nose smooth and merely shorter.)
					var u3 := d.length() / E.R
					if u3 >= 1.0:
						continue
					var f3 := 1.0 - u3 * u3
					var rad := d - E.n * h
					var rl := rad.length()
					if rl > 1e-5:
						out += (rad / rl) * E.depth * 0.8 * sin(h / E.R * 9.0 + nzv * 2.2) * f3 * minf(rl / (E.R * 0.12), 1.0)
					out -= E.n * E.depth * f3 * f3 * (0.9 + 0.3 * nzv)
					out += E.t1 * E.depth * 0.9 * f3 * f3 * f3 * (0.5 + 0.5 * sin(E.p[3]))
					out -= E.n * E.depth * 0.2 * sin(lx / E.R * 11.0 + nzv * 1.5) * f3
					continue
				var u := r / E.R
				if u >= 1.0:
					continue
				var f := 1.0 - u * u
				var amp := E.depth * (f * f * (0.65 + 0.35 * nzv) + 0.22 * sin(u * 13.0 + nzv * 3.0) * (1.0 - u))
				out -= E.n * amp
			K_HOLE:
				var e := maxf(E.edge(lx, ly), 0.0)
				var u := e / (E.R * 1.4)
				if u >= 1.0:
					continue
				var amp := E.buckle * E.R * (1.0 - u) * (1.0 - u) * (0.6 + 0.4 * nzv) * (0.3 + 0.7 * smoothstep(0.0, E.w, e))
				amp += E.buckle * E.R * 0.2 * sin(u * 11.0 + nzv * 2.5) * (1.0 - u)
				out -= E.n * amp
			K_SLOT:
				# molten lips: the metal either side of the cut runs up into a ridge, then sags
				var e := E.edge(lx, ly)
				if e < 0.0:
					e = 0.0
				var u := e / E.w
				if u >= 2.5:
					continue
				var lip := E.R * 0.45 * exp(-u * u * 3.0) * (0.75 + 0.25 * nzv)
				var sag := E.R * 0.12 * smoothstep(0.4, 1.2, u) * (1.0 - smoothstep(1.2, 2.5, u))
				out += E.n * (lip - sag)
			K_CRATER:
				var u := r / E.R
				if u >= 1.6:
					continue
				var bowl := 0.0
				if u < 1.0:
					var f := 1.0 - u * u
					bowl = E.depth * f * f * (0.8 + 0.2 * nzv)
				var rim := E.depth * 0.42 * exp(-pow((u - 1.0) / 0.2, 2.0)) * (0.7 + 0.5 * maxf(nzv, 0.0))
				var splash := E.depth * 0.15 * sin(atan2(ly, lx) * 7.0 + E.p[3]) * exp(-pow((u - 1.15) / 0.3, 2.0))
				out -= E.n * (bowl - rim - splash)
			K_CLUSTER:
				for s in E.subs:
					var ex := lx - s.x
					var ey := ly - s.y
					var pr := absf(s.z)
					var u := sqrt(ex * ex + ey * ey) / (pr * 1.6)
					if u >= 1.0:
						continue
					var f := 1.0 - u * u
					var amp := E.depth * f * f * (pr / maxf(E.depth * 2.0, 1e-4))
					if E.style == S_ACID:
						# corroded: bubbled, blistered metal round the pits
						amp -= pr * 0.18 * (0.5 + 0.5 * nzv) * f
					out -= E.n * amp
	return out


# Which entry removes the triangle whose centre is Q (-1: none).
static func removed_by(Q: Vector3, ents: Array) -> int:
	for i in ents.size():
		var E: Ent = ents[i]
		if not E.has_cut():
			continue
		var d := Q - E.c
		if d.length_squared() > E.cutr2:
			continue
		var h := d.dot(E.n)
		if h < -E.cut or h > E.R * 0.8 + E.depth:
			continue
		var lx := d.dot(E.t1)
		var ly := d.dot(E.t2)
		var e := E.edge(lx, ly)
		if e < 0.0:
			return i
		if E.kind == K_HOLE and E.bend > 0.3:
			var tw := E.w * 0.85
			if e < tw and E.tear(atan2(ly, lx)) < 0.1 * (1.0 - e / tw) + 0.01:
				return i
	return -1


# The cut entry whose torn ring holds P (-1: none).
static func owner_of(P: Vector3, ents: Array) -> int:
	var best := -1
	var bv := 1e9
	for i in ents.size():
		var E: Ent = ents[i]
		if not E.has_cut():
			continue
		var d := P - E.c
		if d.length_squared() > E.cutr2:
			continue
		var v := E.edge(d.dot(E.t1), d.dot(E.t2)) / maxf(E.w, 1e-4)
		if v < bv:
			bv = v
			best = i
	return best


# The cavity floor under skin point P of entry E: pushed in deepest inside the outline, meeting the skin at the ring.
static func cup_at(P: Vector3, E: Ent, ents: Array) -> Vector3:
	var d := P - E.c
	var e := E.edge(d.dot(E.t1), d.dot(E.t2))
	var deep := smoothstep(E.w * 0.9, -minf(E.R, E.w) * 0.45, e)
	var rubble := E.D * 0.14 * _nz(P * (6.0 / maxf(E.R, 1e-3)) + Vector3(E.p[1], E.p[2], E.p[3])) * deep
	return P + buckle_at(P, ents) - E.n * (E.th + E.D * deep + rubble)


# Does the triangle centred at Q lie under E's overlay skin?
static func _in_overlay(Q: Vector3, E: Ent) -> bool:
	if E.ov <= 0.0:
		return false
	var d := Q - E.c
	var h := d.dot(E.n)
	if absf(h) > E.ov * 0.6 + E.depth:
		return false
	var lx := d.dot(E.t1)
	var ly := d.dot(E.t2)
	if E.kind == K_SLOT:
		var al := clampf(lx * E.dx + ly * E.dy, -E.hl, E.hl)
		var qx := lx - E.dx * al
		var qy := ly - E.dy * al
		return qx * qx + qy * qy < E.ov * E.ov
	return lx * lx + ly * ly < E.ov * E.ov


# Does triangle abc (centroid Q) reach into E's overlay? The centroid alone missed big plates under a small mark (r4).
static func _tri_in_overlay(a: Vector3, b: Vector3, c: Vector3, Q: Vector3, E: Ent) -> bool:
	if E.ov <= 0.0:
		return false
	if _in_overlay(Q, E) or _in_overlay(a, E) or _in_overlay(b, E) or _in_overlay(c, E):
		return true
	var reach := E.ov + E.hl
	var r2 := reach * reach
	if (a - E.c).length_squared() > r2 * 16.0 and (b - E.c).length_squared() > r2 * 16.0 and (c - E.c).length_squared() > r2 * 16.0:
		# a cheap reject unless the triangle is big enough to span the mark
		var ext := maxf((b - a).length(), maxf((c - b).length(), (a - c).length()))
		if ext < reach * 2.0:
			return false
	if _in_overlay(_closest_on_tri(E.c, a, b, c), E):
		return true
	if E.kind == K_SLOT:
		return _in_overlay(_closest_on_tri(E.c + E.dir * E.hl, a, b, c), E) or _in_overlay(_closest_on_tri(E.c - E.dir * E.hl, a, b, c), E)
	return false


# Closest point to p on triangle abc (Ericson, Real-Time Collision Detection 5.1.5).
static func _closest_on_tri(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab := b - a
	var ac := c - a
	var ap := p - a
	var d1 := ab.dot(ap)
	var d2 := ac.dot(ap)
	if d1 <= 0.0 and d2 <= 0.0:
		return a
	var bp := p - b
	var d3 := ab.dot(bp)
	var d4 := ac.dot(bp)
	if d3 >= 0.0 and d4 <= d3:
		return b
	var vc := d1 * d4 - d3 * d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		return a + ab * (d1 / (d1 - d3))
	var cp := p - c
	var d5 := ab.dot(cp)
	var d6 := ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return c
	var vb := d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		return a + ac * (d2 / (d2 - d6))
	var va := d3 * d6 - d5 * d4
	if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
		return b + (c - b) * ((d4 - d3) / ((d4 - d3) + (d5 - d6)))
	var den := 1.0 / maxf(va + vb + vc, 1e-30)
	return a + ab * (vb * den) + ac * (vc * den)


static func _seg_pt_d2(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-20), 0.0, 1.0)
	return (a + ab * t - p).length_squared()


# Should the edge pa-pb be split? Long against a mark's tess and within its treach. A pure function of the two end
# positions (in either order), so the triangles on both sides of an edge always agree and no crack opens.
static func _want_split(pa: Vector3, pb: Vector3, ents: Array, tess_min: float, lmin2 := 0.0) -> bool:
	var l2 := pa.distance_squared_to(pb)
	if l2 <= lmin2:
		return false
	for x in ents:
		var E: Ent = x
		var tl := maxf(E.tess, tess_min)
		if E.tess <= 0.0 or l2 <= tl * tl:
			continue
		var r2 := E.treach * E.treach
		if E.kind == K_SLOT:
			for k in 7:
				var sp := E.c + E.dir * E.hl * (float(k) / 3.0 - 1.0)
				if _seg_pt_d2(sp, pa, pb) < r2:
					return true
		elif _seg_pt_d2(E.c, pa, pb) < r2:
			return true
	return false


const REFINE_MAX_TRIS := 20000
const REFINE_PASSES := 6


# Split the candidate triangles near marks until their edges are short enough (red-green templates on the edges that
# need it, so neighbours stay conforming). New vertices interpolate every attribute of the surface, so the vertex format
# and the materials stay as they were. Returns {} when nothing needed splitting.
static func _refine(arr: Array, P: PackedVector3Array, idx: PackedInt32Array, cand: PackedInt32Array, ents: Array, tess_min: float) -> Dictionary:
	var any := false
	for x in ents:
		if (x as Ent).tess > 0.0:
			any = true
			break
	if not any:
		return {}
	# the shortest edge any mark asks for: finer edges are rejected before looking at the marks (8K hulls are mostly fine)
	var lmin := 1e9
	for x in ents:
		var E: Ent = x
		if E.tess > 0.0:
			lmin = minf(lmin, maxf(E.tess, tess_min))
	var lmin2 := lmin * lmin
	var nv0 := P.size()
	# attributes to interpolate: [array index, comps, kind] (kind 0 vec3, 1 vec2, 2 color, 3 float comps, 4 copy bytes, 5 copy ints)
	var attrs: Array = []
	var A := arr.duplicate()
	for k in Mesh.ARRAY_MAX:
		if k == Mesh.ARRAY_INDEX or A[k] == null:
			continue
		var v = A[k]
		if v is PackedVector3Array and v.size() == nv0:
			attrs.append([k, 3, 0])
		elif v is PackedVector2Array and v.size() == nv0:
			attrs.append([k, 2, 1])
		elif v is PackedColorArray and v.size() == nv0:
			attrs.append([k, 4, 2])
		elif v is PackedFloat32Array and v.size() > 0 and v.size() % nv0 == 0:
			attrs.append([k, v.size() / nv0, 3])
		elif v is PackedByteArray and v.size() > 0 and v.size() % nv0 == 0:
			attrs.append([k, v.size() / nv0, 4])
		elif v is PackedInt32Array and v.size() > 0 and v.size() % nv0 == 0:
			attrs.append([k, v.size() / nv0, 5])
		else:
			return {}
		A[k] = v.duplicate()
	var P2 := P.duplicate()
	var I2 := idx.duplicate()
	var C2 := cand.duplicate()
	var mids := {}
	var queue: Array = []
	for t in cand:
		queue.append(t)
	var added := 0
	for pass_i in REFINE_PASSES:
		if queue.is_empty() or added > REFINE_MAX_TRIS:
			break
		var nxt: Array = []
		for t in queue:
			if added > REFINE_MAX_TRIS:
				break
			var i0 := I2[t * 3]
			var i1 := I2[t * 3 + 1]
			var i2 := I2[t * 3 + 2]
			if i0 == i1 or i1 == i2 or i0 == i2:
				continue
			var s01 := _want_split(P2[i0], P2[i1], ents, tess_min, lmin2)
			var s12 := _want_split(P2[i1], P2[i2], ents, tess_min, lmin2)
			var s20 := _want_split(P2[i2], P2[i0], ents, tess_min, lmin2)
			var ns := int(s01) + int(s12) + int(s20)
			if ns == 0:
				continue
			var tris: Array = []
			if ns == 3:
				var m01 := _mid(A, attrs, P2, mids, i0, i1)
				var m12 := _mid(A, attrs, P2, mids, i1, i2)
				var m20 := _mid(A, attrs, P2, mids, i2, i0)
				tris = [[i0, m01, m20], [m01, i1, m12], [m20, m12, i2], [m01, m12, m20]]
			else:
				# rotate so the split edges come first: (a, b, c) with ab split, and bc too when two are split
				var a := i0
				var b := i1
				var c := i2
				if ns == 1:
					if s12:
						a = i1; b = i2; c = i0
					elif s20:
						a = i2; b = i0; c = i1
					var m := _mid(A, attrs, P2, mids, a, b)
					tris = [[a, m, c], [m, b, c]]
				else:
					if not s01:
						a = i1; b = i2; c = i0
					elif not s12:
						a = i2; b = i0; c = i1
					var mab := _mid(A, attrs, P2, mids, a, b)
					var mbc := _mid(A, attrs, P2, mids, b, c)
					tris = [[mab, b, mbc], [a, mab, mbc], [a, mbc, c]]
			for j in tris.size():
				var tr: Array = tris[j]
				var slot_t: int = t
				if j > 0:
					slot_t = I2.size() / 3
					I2.append(0)
					I2.append(0)
					I2.append(0)
					C2.append(slot_t)
					added += 1
				I2[slot_t * 3] = tr[0]
				I2[slot_t * 3 + 1] = tr[1]
				I2[slot_t * 3 + 2] = tr[2]
				nxt.append(slot_t)
		queue = nxt
	if added == 0:
		return {}
	return {"arr": A, "P": P2, "idx": I2, "cand": C2}


# The midpoint vertex of edge ia-ib (shared by both triangles on a welded edge), every attribute interpolated.
static func _mid(A: Array, attrs: Array, P2: PackedVector3Array, mids: Dictionary, ia: int, ib: int) -> int:
	var key := Vector2i(mini(ia, ib), maxi(ia, ib))
	var got = mids.get(key)
	if got != null:
		return got
	var ni := P2.size()
	P2.append((P2[ia] + P2[ib]) * 0.5)
	for at in attrs:
		var k: int = at[0]
		var cmp: int = at[1]
		var kind: int = at[2]
		var v = A[k]
		match kind:
			0:
				var m: Vector3 = (v[ia] + v[ib]) * 0.5
				if k == Mesh.ARRAY_NORMAL and m.length_squared() > 1e-12:
					m = m.normalized()
				v.append(m)
			1:
				v.append((v[ia] + v[ib]) * 0.5)
			2:
				v.append((v[ia] as Color).lerp(v[ib], 0.5))
			3:
				var vals := PackedFloat32Array()
				vals.resize(cmp)
				for q in cmp:
					vals[q] = (v[ia * cmp + q] + v[ib * cmp + q]) * 0.5
				if k == Mesh.ARRAY_TANGENT and cmp == 4:
					var tv := Vector3(vals[0], vals[1], vals[2])
					if tv.length_squared() > 1e-12:
						tv = tv.normalized()
					vals[0] = tv.x
					vals[1] = tv.y
					vals[2] = tv.z
					vals[3] = v[ia * cmp + 3]
				v.append_array(vals)
			_:
				for q in cmp:
					v.append(v[ia * cmp + q])
		A[k] = v
	mids[key] = ni
	return ni


# ---------------------------------------------------------------- the worker

class Part:
	var pos := PackedVector3Array()
	var nrm := PackedVector3Array()
	var col := PackedColorArray()
	var opos := PackedVector3Array()     # overlay skin
	var onrm := PackedVector3Array()
	var ocol := PackedColorArray()
	var cup_f := PackedVector3Array()
	var cup_o := PackedVector3Array()


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


static func _otri(pt: Part, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, want: Vector3, col: Color) -> void:
	if (b - a).cross(c - a).dot(want) > 0.0:
		var t := b
		b = c
		c = t
		var tn := nb
		nb = nc
		nc = tn
	pt.opos.append(a)
	pt.opos.append(b)
	pt.opos.append(c)
	pt.onrm.append(na)
	pt.onrm.append(nb)
	pt.onrm.append(nc)
	pt.ocol.append(col)
	pt.ocol.append(col)
	pt.ocol.append(col)


static func _quad(pt: Part, a: Vector3, b: Vector3, c: Vector3, d: Vector3, nrm: Vector3, col: Color) -> void:
	_tri(pt, a, b, c, nrm, nrm, nrm, nrm, col)
	_tri(pt, a, c, d, nrm, nrm, nrm, nrm, col)


static func _qk(p: Vector3, q: float) -> Vector3i:
	return Vector3i(roundi(p.x / q), roundi(p.y / q), roundi(p.z / q))


static func _edge_key(a: Vector3, b: Vector3, q: float) -> Array:
	var ka := _qk(a, q)
	var kb := _qk(b, q)
	return [ka, kb] if ka < kb else [kb, ka]


# job: {surfs: [{arrays, xf, aabb}], ents, q (weld size), cell (grid cell), ovl (overlay lift)}. Returns {surfs: [new
# arrays or null], parts: [Part per entry], ms}.
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
			if aabb.grow(sqrt(E.inf2) + E.ov).has_point(E.c):
				hit = true
				break
		if not hit:
			out_s.append(null)
			continue
		out_s.append(_surface(sd, ents, parts, edges, q, float(job.get("cell", 1.0)), float(job.get("ovl", 0.02)), q * 8.0))
	var t_surf := Time.get_ticks_msec() - t_ms
	# the cut edge: the skin's thickness along every edge between a kept and a removed triangle
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
		var col := Color(PART_LIP, 0.5 + 0.5 * _nz(mid * 9.0 / maxf(E.R, 1e-3)), 0, 1)
		_quad(pt, a, b, b2, a2, inw, col)
		_quad(pt, a, b, b2, a2, -inw, col)
	for i in ents.size():
		var E: Ent = ents[i]
		if E.walls and not E.through:
			_walls(parts[i], E)
	# conduits and spines (they read the hull's triangle mesh only), then every mesh, all here on the worker: the main
	# thread only swaps them in (r3 showed the 8K barge's rebuild costing a long frame when the meshes were built there)
	var t_edges := Time.get_ticks_msec() - t_ms
	var hull = job.get("hull")
	var ends_by: Array = []
	var r := RandomNumberGenerator.new()
	for i in ents.size():
		var E: Ent = ents[i]
		r.seed = int(E.seed_v * 1000.0) + 5
		var ends: Array = []
		if E.kind == K_HOLE and E.conduits:
			ends = conduits(hull, parts[i], E, ents, r)
		elif E.kind == K_CLUSTER and E.style == S_ACID:
			spines(hull, parts[i], E, E.dir, r)
		ends_by.append([ends, r.state])
	var t_parts := Time.get_ticks_msec() - t_ms
	var mesh_src := {}
	var surfs: Array = job["surfs"]
	var groups := {}
	for k in surfs.size():
		var key: int = int(surfs[k]["mid"])
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(k)
	for key in groups:
		var ks: Array = groups[key]
		var any := false
		for k in ks:
			if out_s[k] != null:
				any = true
		if not any or int(surfs[ks[0]]["n"]) != ks.size():
			continue
		var src: Array = []
		for k in ks:
			var sd: Dictionary = surfs[k]
			src.append([out_s[k] if out_s[k] != null else sd["arrays"], int(sd["fmt"]) & Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES, sd["mat"]])
		mesh_src[key] = src
	var inside_a = _merged(ents, parts, false)
	var skin_a = _merged(ents, parts, true)
	var res := {"surfs": out_s, "parts": parts, "ends": ends_by, "mesh_src": mesh_src, "inside_a": inside_a, "skin_a": skin_a}
	# the meshes are made here on the worker when the renderer allows it (r3: on the main thread the 8K barge's rebuild
	# cost a long frame); a headless run makes them in apply instead (G2: the headless renderer cannot build meshes on a
	# worker thread, which errored bot runs)
	if bool(job.get("mesh_on_worker", true)):
		build_meshes(res)
	# where the time went (ms from the start): surfaces, cut edges and walls, conduits and spines, then the meshes
	res["ms"] = Time.get_ticks_msec() - t_ms
	res["phases"] = [t_surf, t_edges, t_parts]
	return res


# Turn a rebuild's arrays into meshes (once: on the worker, or in apply on the main thread).
static func build_meshes(res: Dictionary) -> void:
	if res.has("meshes"):
		return
	var meshes := {}
	var mesh_src: Dictionary = res.get("mesh_src", {})
	for key in mesh_src:
		var am := ArrayMesh.new()
		for e in mesh_src[key]:
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, e[0], [], {}, int(e[1]))
			am.surface_set_material(am.get_surface_count() - 1, e[2])
		meshes[key] = am
	res["meshes"] = meshes
	res["inside"] = _mesh_of(res.get("inside_a"))
	res["skin"] = _mesh_of(res.get("skin_a"))


static func _mesh_of(arr) -> ArrayMesh:
	if arr == null:
		return null
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, custom_flags())
	return am


# One surface: displace the skin near the damage, mark removed triangles zero-area, collect cavities and overlay skins.
# Only triangles in grid cells near the damage are visited (the grid and the ship-frame positions are built once per
# surface and kept in sd), so an 8K hull costs about what a game hull does.
static func _surface(sd: Dictionary, ents: Array, parts: Array, edges: Dictionary, q: float, cell: float, ovl: float, tess_min := 0.0):
	var arr: Array = sd["arrays"]
	var xf: Transform3D = sd["xf"]
	var V: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var N := PackedVector3Array()
	if arr[Mesh.ARRAY_NORMAL] != null:
		N = arr[Mesh.ARRAY_NORMAL]
	var has_n := N.size() == V.size()
	var nv := V.size()
	if not sd.has("P"):
		sd["P"] = xf * V
	var P: PackedVector3Array = sd["P"]
	var idx := PackedInt32Array()
	if arr[Mesh.ARRAY_INDEX] != null:
		idx = arr[Mesh.ARRAY_INDEX]
	if idx.is_empty():
		if not sd.has("ident"):
			var ident := PackedInt32Array()
			ident.resize(nv)
			for i in nv:
				ident[i] = i
			sd["ident"] = ident
		idx = sd["ident"]
	var nt := idx.size() / 3
	if not sd.has("grid"):
		# every triangle goes into each cell its box overlaps (r4: a big kit plate's centroid can sit cells away from a
		# mark on it, so centroid bucketing missed it), up to 64 cells; past that, its centroid's cell
		var grid := {}
		for t in nt:
			var a0 := P[idx[t * 3]] / cell
			var a1 := P[idx[t * 3 + 1]] / cell
			var a2 := P[idx[t * 3 + 2]] / cell
			var lo := Vector3i(floori(minf(a0.x, minf(a1.x, a2.x))), floori(minf(a0.y, minf(a1.y, a2.y))), floori(minf(a0.z, minf(a1.z, a2.z))))
			var hi := Vector3i(floori(maxf(a0.x, maxf(a1.x, a2.x))), floori(maxf(a0.y, maxf(a1.y, a2.y))), floori(maxf(a0.z, maxf(a1.z, a2.z))))
			var span := (hi - lo) + Vector3i.ONE
			if span.x * span.y * span.z > 64:
				var cq := (a0 + a1 + a2) / 3.0
				lo = Vector3i(floori(cq.x), floori(cq.y), floori(cq.z))
				hi = lo
			for gx in range(lo.x, hi.x + 1):
				for gy in range(lo.y, hi.y + 1):
					for gz in range(lo.z, hi.z + 1):
						var key := Vector3i(gx, gy, gz)
						if not grid.has(key):
							grid[key] = []
						(grid[key] as Array).append(t)
		sd["grid"] = grid
	var grid: Dictionary = sd["grid"]
	var tmark := PackedByteArray()
	tmark.resize(nt)
	var cand := PackedInt32Array()
	# which marks reach each grid cell (r5: an 8K hull's damaged region holds tens of thousands of vertices, and testing
	# every one against all 20 or so marks cost seconds; each triangle now only meets the marks of its own cell)
	var cell_ents := {}
	for ei in ents.size():
		var E: Ent = ents[ei]
		var rr := maxf(sqrt(E.inf2), E.ov + E.hl) + cell
		var lo := (E.c - Vector3.ONE * rr) / cell
		var hi := (E.c + Vector3.ONE * rr) / cell
		for cx in range(floori(lo.x), floori(hi.x) + 1):
			for cy in range(floori(lo.y), floori(hi.y) + 1):
				for cz in range(floori(lo.z), floori(hi.z) + 1):
					var key := Vector3i(cx, cy, cz)
					if not grid.has(key):
						continue
					if not cell_ents.has(key):
						cell_ents[key] = PackedInt32Array()
					var ce: PackedInt32Array = cell_ents[key]
					ce.append(ei)
					cell_ents[key] = ce
	# per triangle, the index of its cell's mark list (-2: all marks, for a triangle in several cells' reach)
	var lists: Array = [ents]
	var maps: Array = [PackedInt32Array(range(ents.size()))]
	var tl := PackedInt32Array()
	tl.resize(nt)
	for key in cell_ents:
		var ce: PackedInt32Array = cell_ents[key]
		var sub: Array = []
		for ei in ce:
			sub.append(ents[ei])
		var li := lists.size()
		lists.append(sub)
		maps.append(ce)
		for t in grid[key]:
			if tmark[t] == 0:
				tmark[t] = 1
				cand.append(t)
				tl[t] = li
			elif tl[t] != li:
				tl[t] = 0
	if cand.is_empty():
		return null
	# split the big triangles near cutting and denting marks first, so a hole smaller than a plate can still be cut
	var rf: Dictionary = _refine(arr, P, idx, cand, ents, tess_min)
	if not rf.is_empty():
		arr = rf["arr"]
		P = rf["P"]
		idx = rf["idx"]
		cand = rf["cand"]
		N = arr[Mesh.ARRAY_NORMAL] if has_n else N
		nv = P.size()
		nt = idx.size() / 3
		# the split triangles meet every mark (a split triangle came from a big one, near several)
		var old_nt := tl.size()
		tl.resize(nt)
		for t in range(old_nt, nt):
			tl[t] = 0
		for t in cand:
			if t < old_nt and tl[t] > 0:
				tl[t] = 0
	var nb: Basis = xf.basis.inverse().transposed()
	var back: Basis = xf.basis.transposed()
	var near := PackedByteArray()
	near.resize(nv)
	var seen := PackedByteArray()
	seen.resize(nv)
	var Dp := P.duplicate()
	var NR := PackedVector3Array()
	NR.resize(nv)
	var pm := PackedFloat32Array()
	pm.resize(nv)
	var N2 := N.duplicate()
	var changed := false
	for t in cand:
		var lents: Array = lists[tl[t]]
		for j in 3:
			var i := idx[t * 3 + j]
			if seen[i] == 1:
				continue
			seen[i] = 1
			var p := P[i]
			var lvl := 0
			var eps := 1e9
			for x in lents:
				var E: Ent = x
				# surface-only marks (ion burns, the stage scorch) never move the skin: they only need the overlay
				if E.kind == K_SURFACE:
					continue
				var d2 := (p - E.c).length_squared()
				if d2 < E.inf2:
					if lvl == 0:
						lvl = 1
					eps = minf(eps, (E.w if E.kind == K_CLUSTER else E.R) * 0.04)
					if E.has_cut() and d2 < E.cutr2:
						lvl = 2
			var nr := (nb * N[i]).normalized() if has_n else Vector3.UP
			NR[i] = nr
			if lvl == 0:
				continue
			near[i] = lvl
			var pv := peel_at(p, lents)
			var dv := pv + buckle_at(p, lents)
			pm[i] = pv.length()
			if dv.length_squared() < 1e-12:
				continue
			changed = true
			var dp := p + dv
			Dp[i] = dp
			var ta := nr.cross(Vector3.UP if absf(nr.y) < 0.9 else Vector3.RIGHT).normalized()
			var tb := nr.cross(ta)
			var pa := p + ta * eps
			pa += peel_at(pa, lents) + buckle_at(pa, lents)
			var pb := p + tb * eps
			pb += peel_at(pb, lents) + buckle_at(pb, lents)
			var nn := (pa - dp).cross(pb - dp)
			if nn.length_squared() > 1e-20:
				nn = nn.normalized()
				NR[i] = nn
				if has_n:
					N2[i] = (back * nn).normalized()
	var nidx := idx.duplicate()
	var removed_any := false
	var tri_i := PackedInt32Array([0, 0, 0])
	for t in cand:
		var lents: Array = lists[tl[t]]
		var lmap: PackedInt32Array = maps[tl[t]]
		var i0 := idx[t * 3]
		var i1 := idx[t * 3 + 1]
		var i2 := idx[t * 3 + 2]
		var a := P[i0]
		var b := P[i1]
		var c := P[i2]
		var Q := (a + b + c) / 3.0
		var cz := near[i0] == 2 or near[i1] == 2 or near[i2] == 2
		var ri := removed_by(Q, lents) if cz else -1
		if ri >= 0:
			ri = lmap[ri]
		var n0 := NR[i0]
		var n1 := NR[i1]
		var n2 := NR[i2]
		if ri >= 0:
			removed_any = true
			# a removed triangle stays in the buffer as a zero-area one (no index rebuild)
			nidx[t * 3 + 1] = i0
			nidx[t * 3 + 2] = i0
			var E: Ent = ents[ri]
			for pr in [[a, b], [b, c], [c, a]]:
				var key := _edge_key(pr[0], pr[1], q)
				var ed: Dictionary = edges.get(key, {})
				ed["r"] = int(ed.get("r", 0)) + 1
				ed["own"] = ri
				edges[key] = ed
			if not E.through:
				_cup_tri(parts[ri], E, lents, a, b, c, n0 + n1 + n2)
			continue
		# the overlay skin over each mark this triangle lies under, lifted a hair off the hull
		var DQ := (Dp[i0] + Dp[i1] + Dp[i2]) / 3.0
		var tr2 := maxf(Q.distance_squared_to(a), maxf(Q.distance_squared_to(b), Q.distance_squared_to(c)))
		var trr := sqrt(tr2)
		for lj in lents.size():
			var Em: Ent = lents[lj]
			if Em.ov <= 0.0:
				continue
			var reach := Em.ov + Em.hl + trr
			if Q.distance_squared_to(Em.c) > reach * reach:
				continue
			if _tri_in_overlay(a, b, c, Q, Em):
				_otri(parts[lmap[lj]], Dp[i0] + n0 * ovl, Dp[i1] + n1 * ovl, Dp[i2] + n2 * ovl, n0, n1, n2, n0 + n1 + n2, Color(float(Em.style) / 16.0, 0, 0, 1))
		if not cz:
			continue
		tri_i[0] = i0
		tri_i[1] = i1
		tri_i[2] = i2
		for e3 in 3:
			var ia := tri_i[e3]
			var ib := tri_i[(e3 + 1) % 3]
			var key := _edge_key(P[ia], P[ib], q)
			var ed: Dictionary = edges.get(key, {})
			ed["k"] = int(ed.get("k", 0)) + 1
			ed["a"] = Dp[ia]
			ed["b"] = Dp[ib]
			ed["na"] = NR[ia]
			ed["nb"] = NR[ib]
			ed["kc"] = DQ
			edges[key] = ed
		var ow := owner_of(Q, lents)
		if ow < 0:
			continue
		ow = lmap[ow]
		var Eo: Ent = ents[ow]
		var nsum := n0 + n1 + n2
		# the back of the skin round the cut (and of the peeled plates), a plate's thickness in
		var pt: Part = parts[ow]
		var shade := 0.35 + 0.3 * _nz(Q * 5.0 / maxf(Eo.R, 1e-3))
		_tri(pt, Dp[i0] - n0 * Eo.th, Dp[i1] - n1 * Eo.th, Dp[i2] - n2 * Eo.th, -n0, -n1, -n2, -nsum, Color(PART_SKIN, shade, 0, 1))
		if maxf(pm[i0], maxf(pm[i1], pm[i2])) > Eo.R * 0.01 and not Eo.through:
			_cup_tri(pt, Eo, lents, a, b, c, nsum)
	if not changed and not removed_any:
		return null
	var na := arr.duplicate()
	na[Mesh.ARRAY_VERTEX] = xf.affine_inverse() * Dp
	if has_n:
		na[Mesh.ARRAY_NORMAL] = N2
	na[Mesh.ARRAY_INDEX] = nidx
	return na


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
	var shade := 0.4 + 0.3 * _nz((a + b + c) * (3.0 / maxf(E.R, 1e-3)))
	_tri(pt, fa, fb, fc, fn, fn, fn, fn, Color(PART_CUP, shade, 0, 1))
	if E.walls:
		pt.cup_f.append(fa)
		pt.cup_f.append(fb)
		pt.cup_f.append(fc)
		pt.cup_o.append(a + buckle_at(a, ents))
		pt.cup_o.append(b + buckle_at(b, ents))
		pt.cup_o.append(c + buckle_at(c, ents))


# Frames (across the ship) and deck layers (level, when the hole faces sideways) sliced through a cavity: each slice of
# the floor stood up as a wall to just under the skin, with a ragged top, some blown away.
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
			var d0 := F[t * 3].dot(ax)
			var d1 := F[t * 3 + 1].dot(ax)
			var d2 := F[t * 3 + 2].dot(ax)
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


# ---------------------------------------------------------------- main thread: conduits, cables, spines, emitters

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


# Conduits running fore and aft across a cavity (some torn apart) and cables trailing out of the hole. Returns the torn
# ends and cable tips, where the sparks go: [[pos, dir], ...].
static func conduits(hull, pt: Part, E: Ent, ents: Array, r: RandomNumberGenerator) -> Array:
	var ends: Array = []
	if E.through or hull == null or not E.conduits:
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
					if E.edge(dd.dot(E.t1), dd.dot(E.t2)) > E.w * 0.9:
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
		var cp := PackedVector3Array()
		for k in 8:
			var tt := k / 7.0
			cp.append(st + E.n * (tt * Lc * 0.75) + rd * (tt * tt * Lc * 0.6) + side * (sin(tt * 4.0 + ph) * Lc * 0.08))
		_tube(pt, cp, E.R * 0.024, E.R * 0.018, Color(PART_PIPE, 0.15, 0, 1))
		ends.append([cp[7], (cp[7] - cp[6]).normalized()])
	return ends


# Chorus spine shafts stuck in the hull at a cluster's pits, leaning back the way they came.
static func spines(hull, pt: Part, E: Ent, back_dir: Vector3, r: RandomNumberGenerator) -> void:
	if hull == null:
		return
	var nsp := 0
	for s in E.subs:
		if nsp >= 4 or r.randf() < 0.4:
			continue
		var Q := E.c + E.t1 * s.x + E.t2 * s.y
		var h: Dictionary = hull.ray(Q + E.n * E.R, -E.n)
		if h.is_empty():
			continue
		var base: Vector3 = (h["p"] as Vector3) - E.n * absf(s.z) * 0.8
		var d := (back_dir.normalized() * 0.7 + E.n * 0.5 + Vector3(r.randf() - 0.5, r.randf() - 0.5, r.randf() - 0.5) * 0.3).normalized()
		var ln := E.R * (0.5 + r.randf() * 0.5)
		var sp := PackedVector3Array()
		for k in 5:
			sp.append(base + d * ln * (k / 4.0) + E.n.cross(d) * sin(k * 0.9) * ln * 0.03)
		_tube(pt, sp, absf(s.z) * 0.55, absf(s.z) * 0.08, Color(PART_BONE, 0.4 + 0.4 * r.randf(), 0, 1))
		nsp += 1


# Fire, embers, thin smoke, venting gas and sparks for a breach or blast hole, all from inside it (repeating on the
# effect clock, so a rebuild does not restart them).
static func emitters(b: POOLS.Batch, bs: POOLS.Batch, E: Ent, ents: Array, ends: Array, r: RandomNumberGenerator, glow: Color) -> void:
	var q := POOLS.quad_shape()
	var qs := POOLS.streak_shape()
	var R := E.R
	var hot := absf(E.bend) > 1.0 or E.style == S_BLAST
	var floor_pts: Array = []
	for j in (3 if hot else 2):
		var an := r.randf() * TAU
		var p := E.c + (E.t1 * cos(an) + E.t2 * sin(an)) * R * r.randf() * 0.45
		floor_pts.append(cup_at(p, E, ents) + E.n * R * 0.05 if not E.through else p)
	for fp in floor_pts:
		var P: Vector3 = fp
		for kk in 9:
			var v := E.n * R * (1.3 + r.randf() * 0.9) + E.t1 * (r.randf() - 0.5) * R * 0.5 + E.t2 * (r.randf() - 0.5) * R * 0.5
			b.add(q, POOLS.pack(Vector4(P.x, P.y, P.z, -20.0 + kk * 0.09), Vector4(v.x, v.y, v.z, 0.55 + r.randf() * 0.3),
				Vector4(glow.r, glow.g, glow.b, 2.0), Vector4(R * 0.22, R * 0.55, 1, r.randf()), Vector4(0.8, 0, 0, 0)))
	var P0: Vector3 = floor_pts[0]
	for kk in (10 if hot else 6):
		var v := (E.n * 1.0 + Vector3(r.randf() - 0.5, r.randf() - 0.5, r.randf() - 0.5) * 0.9).normalized() * R * (0.5 + r.randf() * 0.9)
		b.add(q, POOLS.pack(Vector4(P0.x, P0.y, P0.z, -20.0 + kk * 0.37 + r.randf() * 0.2), Vector4(v.x, v.y, v.z, 3.2),
			Vector4(glow.r, glow.g, glow.b, 2.0), Vector4(R * 0.07, R * 0.03, 19, r.randf()), Vector4(3.9, 0, 0.3, 0)))
	for kk in 3:
		var v := E.n * R * 1.4 + Vector3(0, R * 0.2, 0)
		b.add(q, POOLS.pack(Vector4(P0.x, P0.y, P0.z, -20.0 + kk * 0.9 + r.randf() * 0.2), Vector4(v.x, v.y, v.z, 2.7),
			Vector4(0.1, 0.095, 0.09, 0.2), Vector4(R * 0.35, R * 1.7, 3, r.randf()), Vector4(2.7, 0, 0.7, 0.3)))
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
	for e2 in ends:
		var sp: Vector3 = e2[0]
		var sd: Vector3 = e2[1]
		var per := 0.9 + r.randf() * 1.6
		var off := r.randf() * per
		for kk in 7:
			var v := (sd + E.n * 0.4 + Vector3(r.randf() - 0.5, r.randf() - 0.5, r.randf() - 0.5) * 0.9).normalized() * R * (2.5 + r.randf() * 4.0)
			bs.add(qs, POOLS.pack(Vector4(sp.x, sp.y, sp.z, off + r.randf() * 0.06), Vector4(v.x, v.y, v.z, 0.25 + r.randf() * 0.3),
				Vector4(1.0, 0.75, 0.45, 3.5), Vector4(0.035, R * 0.025, 2.2, 1), Vector4(per, 0, 0, 0)))
		b.add(q, POOLS.pack(Vector4(sp.x, sp.y, sp.z, off), Vector4(0, 0, 0, 0.12), Vector4(1.0, 0.8, 0.55, 2.5),
			Vector4(R * 0.05, R * 0.12, 2, r.randf()), Vector4(per, 0, 0, 0)))


# ---------------------------------------------------------------- ship side: gather, rebuild, apply

static func gather(s) -> Array:
	var out: Array = []
	# in the hull's pose when the ship was added (the frame of its analysis and of the damage root, which follows it)
	var inv: Transform3D = s.hull_motion().affine_inverse() * s.root.global_transform.affine_inverse()
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
			out.append({"mi": mi, "mid": mi.get_instance_id(), "si": si, "arrays": s.arrays_of(am, si), "xf": xf, "aabb": aabb,
				"fmt": am.surface_get_format(si), "mat": am.surface_get_material(si), "mesh": am,
				"ov": mi.get_surface_override_material(si), "n": am.get_surface_count()})
	return out


# One mesh's arrays from every entry's parts (the interior, or the overlay skins), each vertex carrying its entry's data:
# CUSTOM0 (centre, R), CUSTOM1 (normal, opened at), CUSTOM2 (cavity depth, heat, seed, style), CUSTOM3 (slot dir, half length).
static func _merged(ents: Array, parts: Array, overlay: bool):
	var pos := PackedVector3Array()
	var nrm := PackedVector3Array()
	var col := PackedColorArray()
	var c0 := PackedFloat32Array()
	var c1 := PackedFloat32Array()
	var c2 := PackedFloat32Array()
	var c3 := PackedFloat32Array()
	for i in ents.size():
		var E: Ent = ents[i]
		var pt: Part = parts[i]
		var pp: PackedVector3Array = pt.opos if overlay else pt.pos
		if pp.is_empty():
			continue
		pos.append_array(pp)
		nrm.append_array(pt.onrm if overlay else pt.nrm)
		col.append_array(pt.ocol if overlay else pt.col)
		var cnt := pp.size()
		c0.append_array(_rep4(Vector4(E.c.x, E.c.y, E.c.z, E.R), cnt))
		c1.append_array(_rep4(Vector4(E.n.x, E.n.y, E.n.z, E.t0), cnt))
		# the overlay's CUSTOM2.x is the halo extent in units of R (the interior's is the cavity depth)
		var c2x: float = (E.halo / maxf(E.R, 1e-4)) if overlay else (E.D if not E.through else E.R * 0.2)
		c2.append_array(_rep4(Vector4(c2x, E.heat, E.seed_v, float(E.style)), cnt))
		c3.append_array(_rep4(Vector4(E.dir.x, E.dir.y, E.dir.z, E.hl), cnt))
	if pos.size() < 3:
		return null
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = pos
	arr[Mesh.ARRAY_NORMAL] = nrm
	arr[Mesh.ARRAY_COLOR] = col
	arr[Mesh.ARRAY_CUSTOM0] = c0
	arr[Mesh.ARRAY_CUSTOM1] = c1
	arr[Mesh.ARRAY_CUSTOM2] = c2
	arr[Mesh.ARRAY_CUSTOM3] = c3
	return arr


static func custom_flags() -> int:
	var f := Mesh.ARRAY_CUSTOM_RGBA_FLOAT
	return (f << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) | (f << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT) | (f << Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT) | (f << Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT)


static func _rep4(v: Vector4, n: int) -> PackedFloat32Array:
	var one := PackedFloat32Array([v.x, v.y, v.z, v.w])
	return POOLS.repeat_f(one, n)


static func apply(fx, s, job: Dictionary) -> void:
	var res: Dictionary = job.get("out", {})
	if res.is_empty():
		return
	build_meshes(res)
	var orig: Array = job["surfs"]
	var meshes: Dictionary = res.get("meshes", {})
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
		var sd0: Dictionary = orig[ks[0]]
		# the damage overlay copies the full-detail triangles: an imported hull drawn at a lower automatic LOD would cover
		# it (r6: ion burns and flak pocks, which leave the mesh itself unchanged, vanished on the 8K hulls), so a damaged
		# hull always draws its full detail (the rebuilt meshes carry no LODs anyway)
		(mi as MeshInstance3D).lod_bias = 128.0
		var am = meshes.get(int(sd0["mid"]))
		if am == null:
			if mi.mesh != sd0["mesh"]:
				mi.mesh = sd0["mesh"]
				_restore_overrides(mi, orig, ks)
			continue
		mi.mesh = am
		_restore_overrides(mi, orig, ks)
	clear_nodes(s)
	var ents: Array = job["ents"]
	var ends_by: Array = res.get("ends", [])
	var glow: Color = s.fac.get("damage_glow", Color(1.0, 0.45, 0.12))
	var b := POOLS.Batch.new()
	var bs := POOLS.Batch.new()
	var r := RandomNumberGenerator.new()
	for i in ents.size():
		var E: Ent = ents[i]
		if E.kind == K_HOLE and E.conduits and i < ends_by.size():
			r.state = ends_by[i][1]
			emitters(b, bs, E, ents, ends_by[i][0], r, glow)
			var holder := Node3D.new()
			holder.position = E.c + E.n * E.R * 0.35
			s._dmg_root.add_child(holder)
			s._hole_nodes.append(holder)
			s._hole_lights.append(fx.light_source(holder, Vector3.ZERO, Color(glow.r, glow.g * 0.9, glow.b), 1.3 + 0.7 * float(absf(E.bend) > 1.0 or E.style == S_BLAST), 0.4))
	var inside = res.get("inside")
	if inside != null:
		var mi := MeshInstance3D.new()
		mi.name = "fx_damage_inside"
		mi.mesh = inside
		var m: ShaderMaterial = fx.mat(SH.HOLE, 0)
		m.set_shader_parameter("glow", Vector3(glow.r, glow.g, glow.b))
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		s._dmg_root.add_child(mi)
		s._hole_nodes.append(mi)
	var skin = res.get("skin")
	if skin != null:
		var mo := MeshInstance3D.new()
		mo.name = "fx_damage_marks"
		mo.mesh = skin
		var m2: ShaderMaterial = fx.mat(SH.MARK, 1)
		var wc: Color = s.fac.get("weapon", Color(1, 0.6, 0.3))
		m2.set_shader_parameter("glow", Vector3(glow.r, glow.g, glow.b))
		m2.set_shader_parameter("weapon", Vector3(wc.r, wc.g, wc.b))
		mo.material_override = m2
		mo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		s._dmg_root.add_child(mo)
		s._hole_nodes.append(mo)
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


# ---------------------------------------------------------------- weapon marks (R43)

# The mark a hit leaves, by look and weight, at a hull point (ship frame). dir: the shot's direction (ship frame).
# Returns the entries to add (a gauss slug makes two: the entry and the spalled exit).
static func marks_for(hull, look: String, w: int, p: Vector3, n: Vector3, dir: Vector3, seed_v: float, faction := "", grow := 1.0) -> Array:
	var L: float = hull.L
	var out: Array = []
	var wk: float = [0.7, 0.85, 1.0, 1.25, 1.5][clampi(w, 0, 4)]
	var g := grow
	var tang := (dir - n * dir.dot(n))
	if tang.length_squared() < 0.01:
		tang = n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT)
	tang = tang.normalized()
	match look:
		"lance", "needle", "pulsar", "las":
			# the beam drags across the plate: the cut runs across the line of fire; repeats lengthen it
			var cut_dir := n.cross(tang)
			var R: float = L * 0.0045 * wk * (0.6 if look in ["needle", "las"] else 1.0) * sqrt(g)
			out.append(slot(hull, p, n, cut_dir, R, L * 0.035 * wk * g, seed_v))
		"ion", "doom":
			out.append(surface(p, n, L * 0.06 * wk * g, seed_v, S_ION))
		"macro", "battery", "auto", "scatter", "prism", "guns":
			if look in ["auto", "scatter", "guns"]:
				# light guns chip and scratch; they never open the hull (pits only, nothing torn through)
				out.append(cluster(p, n, L * 0.025 * wk * g, 7, L * 0.004, 0.0, seed_v, S_FLAK))
			else:
				out.append(crater(p, n, L * 0.016 * wk * g, L * 0.007 * wk, seed_v, S_SHELL))
		"plasma":
			var e := crater(p, n, L * 0.02 * wk * g, L * 0.009 * wk, seed_v, S_PLASMA)
			e.dir = tang
			out.append(e)
		"flak", "pflak", "mflak", "gflak":
			# a stippled patch that grows in area, never in depth, and never exposes structure
			out.append(cluster(p, n, L * 0.04 * wk * g, 10, L * 0.0045, 0.0, seed_v, S_FLAK))
		"spine", "tendril", "sporeb", "spores":
			var e := cluster(p, n, L * 0.03 * wk * g, 7, L * 0.006, 0.35, seed_v, S_ACID)
			e.dir = -dir if look in ["spine", "tendril"] else Vector3.ZERO
			out.append(e)
		"gauss":
			out.append(hole(hull, p, n, L * 0.005 * wk, 0.0, 0.04, seed_v, S_GAUSS_IN))
			var far: Dictionary = hull.ray(p + dir.normalized() * (hull.L + hull.W) * 2.0, -dir.normalized())
			if not far.is_empty():
				out.append(hole(hull, far["p"], far["n"], L * 0.011 * wk, 1.1, 0.12, seed_v + 0.5, S_GAUSS_OUT))
		"torp", "star":
			out.append(hole(hull, p, n, L * 0.04 * wk * g, -1.1 * minf(g, 1.3), 0.18, seed_v, S_BLAST))
		"rockets":
			out.append(crater(p, n, L * 0.022 * wk * g, L * 0.012 * wk, seed_v, S_SHELL))
		"ram":
			out.append(dent(p, n, L * 0.1 * g, L * 0.03 * g, seed_v, S_RAM))
		"ram_self":
			# the rammer's own bow folds too, a smaller crumple
			out.append(dent(p, n, L * 0.06 * g, L * 0.012 * g, seed_v, S_RAM))
		"board":
			out.append(hole(hull, p, n, L * 0.012 * g, 1.4, 0.06, seed_v, S_HATCH))
	for j in out.size():
		var e: Ent = out[j]
		# the halo that makes it read at battle distance: at least HALO_MIN world units, grows with the weapon's weight
		var hm: float = minf(float(HALO_MIN.get(e.style, 0.0)) * wk * sqrt(g), L * HALO_MAX_L)
		if hm > 0.0:
			e.halo = maxf(hm, e.ov * 0.9)
			e.ov = maxf(e.ov, e.halo * (1.15 if e.kind != K_SLOT else 0.9))  # the halo's noisy rim reaches 1.15 halo
		e.look = look
		e.wt = w
		e.ldir = dir
		e.part_i = j
		e.grow = g
	return out
