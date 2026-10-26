extends Node3D
# Effects for the A2 / A3 engine test, ported from the Babylon half (../babylon/index.html, "Effects") so both engines
# draw the same effects from the same particle data, timings, colours and counts (A3 effects-parity proof, R28).
#
# Per ship, a 4 s loop staggered 0.5 s in layout order (0.17 s in the crowd runs):
#   engines always on: hot core, flickering plume (about 1.5 ship widths), a long cooling smoke trail (60 units);
#          the Corsair sputters and coughs soot
#   0.0 s  broadside: four port guns ripple 80 ms apart (blast, fireball, flame tongue, smoke ring and puffs, tracer at
#          160 u/s, impact flash, sparks, hot chips, smoke)
#   1.25 s lance charge flare; 1.5 s to 2.2 s the lance 80 units ahead (white core, faction glow, shimmer, impact flare,
#          44 sparks, smoke)
#   2.4 s  incoming shell on the starboard side: the shield bubble lights up around the hit (fresnel rim, hit core,
#          three ripple rings) in the faction colour (Corsair patchy), or a hull hit for Chorus and Deathless
#   always a hull breach on the upper port flank: a projected torn hole with a glowing jagged edge, charred ring and
#          cracks, thirteen torn plates hot at the tips, a pale venting jet that puffs, debris tumbling out, licking
#          fire, spark showers every 2.3 s, a secondary pop every 3.7 s
# Scene-wide, every 12 s (4 s in the crowd runs): a 0.6 scale Hegemony above the formation breaks at 12.4 s into four
#   chunks of its own mesh (burning break lines, fire and squibs along them), with precursor squibs, a flash, two
#   shockwave rings, a fireball, flames, 110 sparks, 60 hot shards, smoke and smoke trails behind the chunks.
#
# How it runs (as in the Babylon half): one scene clock. Every particle is static data on the GPU (start time, loop
# period, motion, colour, size, kind) in a handful of meshes: smoke sprites, glow sprites, streaks, rings, ribbons,
# shards. The shaders work out each particle's age from the clock, so any frame is a pure function of t (the stills
# are exact and repeatable) and the script only moves the ships, the four chunks and the lights.

const SH := preload("res://bfx_shaders.gd")

const PER := 4.0
const SPARKS_EVERY := 2.3
const POP_EVERY := 3.7
const DC := Vector3(0, 25, 0)
const D_SCALE := 0.6
const BREAK := 0.4
const KEY_DIR := Vector3(-0.45, -0.70, -0.55)
const KEY_COL := Color(1.0, 0.96, 0.90)
const BIG := AABB(Vector3(-3000, -3000, -3000), Vector3(6000, 6000, 6000))
const CORNERS := [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)]
const STREAK_CORNERS := [Vector2(0, -0.5), Vector2(1, -0.5), Vector2(1, 0.5), Vector2(0, 0.5)]
const ENEMY := Color(1.0, 0.72, 0.42)
# light energy per unit of the Babylon event intensity (Babylon's point lights and Godot's omni lights use different
# units; this keeps a muzzle flash about as bright on the hull as the earlier Godot build had it)
const LIGHT_K := 0.9
const POOL_N := 48
const POOL_R := 32.0

var notes: PackedStringArray = []
var phys = null
var rich := false
var maxm := false
var compat := false
var prewarm := false
var stag := 0.5
var dper := 12.0
var dt0 := 12.0
var d_out := 9.0
var d_in := 10.0
var ships: Array = []
var chunks: Array = []
var shields: Array = []
var decals: Array = []
var vols: Array = []
var vol_boom: Dictionary = {}
var flash: OmniLight3D
var pool: Array = []
var _lights: Array = []
var _rng := RandomNumberGenerator.new()
var _mats := {}
var _batch := {}
var _last_t := -1.0
var _fade := -1.0
var _chunk_trails := true
var _anchor_cache := {}
var _tris := PackedVector3Array()
var _tri_bins: Array = []
var _tri_x0 := 0.0
var _tri_dx := 1.0

static var _clock_added := false


static func register_clock() -> void:
	if not _clock_added:
		_clock_added = true
		RenderingServer.global_shader_parameter_add(&"scene_t", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0)


# ---------------------------------------------------------------- static batches

class Batch:
	var pos := PackedVector3Array()
	var nrm := PackedVector3Array()
	var c0 := PackedFloat32Array()
	var c1 := PackedFloat32Array()
	var c2 := PackedFloat32Array()
	var c3 := PackedFloat32Array()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var idx := PackedInt32Array()
	var with_normal := false

	func _init(normals := false) -> void:
		with_normal = normals

	# a = 20 floats: a0 .. a3 (four vec4) and a4 (period, drift, drag, spin and the like)
	func v(p: Vector3, a: PackedFloat32Array, n := Vector3.UP) -> int:
		pos.append(p)
		if with_normal:
			nrm.append(n)
		for k in 4:
			c0.append(a[k])
			c1.append(a[4 + k])
			c2.append(a[8 + k])
			c3.append(a[12 + k])
		uv.append(Vector2(a[16], a[17]))
		uv2.append(Vector2(a[18], a[19]))
		return pos.size() - 1

	func quad(corners: Array, a: PackedFloat32Array) -> void:
		var b := pos.size()
		for i in 4:
			var c: Vector2 = corners[i]
			v(Vector3(c.x, c.y, 0.0), a)
		idx.append_array(PackedInt32Array([b, b + 1, b + 2, b, b + 2, b + 3]))

	func count() -> int:
		return pos.size()

	func build(mat: Material, parent: Node, name: String) -> MeshInstance3D:
		if pos.is_empty():
			return null
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = pos
		if with_normal:
			arr[Mesh.ARRAY_NORMAL] = nrm
		arr[Mesh.ARRAY_TEX_UV] = uv
		arr[Mesh.ARRAY_TEX_UV2] = uv2
		arr[Mesh.ARRAY_CUSTOM0] = c0
		arr[Mesh.ARRAY_CUSTOM1] = c1
		arr[Mesh.ARRAY_CUSTOM2] = c2
		arr[Mesh.ARRAY_CUSTOM3] = c3
		arr[Mesh.ARRAY_INDEX] = idx
		var fl := (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) | (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT) \
			| (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT) | (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT)
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, fl)
		am.custom_aabb = BIG
		var mi := MeshInstance3D.new()
		mi.name = name
		mi.mesh = am
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.extra_cull_margin = 16384.0
		parent.add_child(mi)
		return mi


func _a(p: Vector3, t: float, vel: Vector3, life: float, col: Color, i: float, b0: float, b1: float, b2: float, b3: float,
		per: float, dft: float, e2: float, e3: float) -> PackedFloat32Array:
	return PackedFloat32Array([p.x, p.y, p.z, t, vel.x, vel.y, vel.z, life, col.r, col.g, col.b, i, b0, b1, b2, b3, per, dft, e2, e3])


# o: p, t, life, per, col, i, s0, s1, kind, vel, drag, spin, drift (1 = rides with the ships), seed, batch
func sprite(o: Dictionary) -> void:
	var kind: int = o["kind"]
	var smoky := kind == 3 or kind == 7 or kind == 8
	var b: Batch = o.get("batch", _batch["smk"] if smoky else _batch["spr"])
	b.quad(CORNERS, _a(o["p"], o["t"], o.get("vel", Vector3.ZERO), o["life"], o["col"], o["i"], o["s0"], o["s1"], float(kind),
		o.get("seed", _rng.randf()), o["per"], o.get("drift", 1.0), o.get("drag", 0.0), o.get("spin", 0.0)))


func streak(o: Dictionary) -> void:
	(_batch["stk"] as Batch).quad(STREAK_CORNERS, _a(o["p"], o["t"], o["vel"], o["life"], o["col"], o["i"], o["len"], o["w"],
		o.get("drag", 0.0), float(o["kind"]), o["per"], o.get("drift", 1.0), 0.0, 0.0))


func ring(o: Dictionary) -> void:
	(_batch["rng"] as Batch).quad(CORNERS, _a(o["p"], o["t"], o["n"], o["life"], o["col"], o["i"], o["s0"], o["s1"], float(o["kind"]),
		_rng.randf(), o["per"], o.get("drift", 1.0), o.get("speed", 0.0), o.get("drag", 0.0)))


func ribbon(o: Dictionary) -> void:
	var b: Batch = _batch["rib"]
	var segs: int = o["segs"]
	var base := b.count()
	var d: Vector3 = o["dir"]
	var p: Vector3 = o["p"]
	var col: Color = o["col"]
	var seed := _rng.randf()
	for j in segs + 1:
		for sd in 2:
			b.v(Vector3(float(j) / segs, 0.5 if sd == 1 else -0.5, 0.0), PackedFloat32Array([p.x, p.y, p.z, float(o["kind"]),
				d.x, d.y, d.z, o["len"], col.r, col.g, col.b, o["i"], o["w0"], o["w1"], seed, 0.0, o["t"], o["life"], o["per"], 0.0]))
	for j in segs:
		var q := base + j * 2
		b.idx.append_array(PackedInt32Array([q, q + 1, q + 3, q, q + 3, q + 2]))


# one shard = a jittered octahedron, flat shaded (24 vertices)
func shard(o: Dictionary) -> void:
	var P: Array = []
	for q in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var j := 0.5 + _rng.randf() * 0.5
		P.append(Vector3(q.x * j * (0.5 + _rng.randf() * 0.6), q.y * j * 0.35, q.z * j * (0.5 + _rng.randf() * 0.6)))
	var F := [[0, 2, 4], [4, 2, 1], [1, 2, 5], [5, 2, 0], [4, 3, 0], [1, 3, 4], [5, 3, 1], [0, 3, 5]]
	var ax := _rdir()
	var vel: Vector3 = o["vel"]
	var a := PackedFloat32Array([o["p"].x, o["p"].y, o["p"].z, o["t"], vel.x, vel.y, vel.z, o["life"], ax.x, ax.y, ax.z, o["spin"],
		o["size"], o["per"], o.get("drift", 1.0), o.get("drag", 0.0), o["heat"], _rng.randf(), 0.0, 0.0])
	var b: Batch = _batch["shd"]
	for f in F:
		var pa: Vector3 = P[f[0]]
		var pb: Vector3 = P[f[1]]
		var pc: Vector3 = P[f[2]]
		var n := (pb - pa).cross(pc - pa).normalized()
		var i0 := b.v(pa, a, n)
		b.v(pb, a, n)
		b.v(pc, a, n)
		b.idx.append_array(PackedInt32Array([i0, i0 + 2, i0 + 1]))


func _rdir() -> Vector3:
	var z := _rng.randf() * 2.0 - 1.0
	var an := _rng.randf() * TAU
	var r := sqrt(1.0 - z * z)
	return Vector3(r * cos(an), r * sin(an), z)


func _rcone(axis: Vector3, spread: float) -> Vector3:
	return (axis.normalized() + _rdir() * spread).normalized()


func _tint(c: Color, k: float) -> Color:
	return c.lerp(Color.WHITE, k)


func _drift(t: float) -> float:
	return fposmod(3.0 * t + 20.0, 40.0) - 20.0


func _ship_fade(t: float) -> float:
	var ph := fposmod(3.0 * t + 20.0, 40.0) / 3.0
	return clampf(minf(ph, 40.0 / 3.0 - ph), 0.0, 1.0)


func _stag_of(i: int) -> float:
	return fmod(i * stag, PER)


func _spark_off(i: int) -> float:
	# Babylon's spacing (0.37 s per ship) moved 1.2 s later: Babylon's 0.3 + 0.37 i puts the Hegemony's shower at 2.97,
	# right over the hole in the 3.0 close-up; here it falls at 1.87 and 4.17
	return fposmod(1.5 + 0.37 * i, SPARKS_EVERY)


func _pop_off(i: int) -> float:
	return fposmod(0.6 + 0.55 * i, POP_EVERY)


# ---------------------------------------------------------------- materials

func _shader(code: String, defines := "") -> Shader:
	var s := Shader.new()
	if defines != "":
		var nl := code.find("\n", code.find("render_mode"))
		code = code.substr(0, nl + 1) + defines + code.substr(nl + 1)
	s.code = code
	return s


func _mat(code: String, prio := 0, defines := "") -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(code, defines)
	m.render_priority = prio
	return m


# ---------------------------------------------------------------- setup

func setup(list: Array, wreck_src: Dictionary, _deterministic: bool, is_compat: bool, opts := {}) -> void:
	register_clock()
	rich = bool(opts.get("rich", false))
	maxm = bool(opts.get("max", false))
	compat = is_compat
	stag = float(opts.get("stagger", 0.5))
	dper = float(opts.get("boom_every", 12.0))
	dt0 = dper
	d_out = dper - 3.0
	d_in = dper - 2.0
	_rng.seed = 20261025
	var soft := "#define SOFT\n" if (rich and not compat) else ""
	_mats["smk"] = _mat(SH.SPRITE, -1, soft)
	_mats["spr"] = _mat(SH.SPRITE, 1, soft)
	_mats["stk"] = _mat(SH.STREAK, 1)
	_mats["rng"] = _mat(SH.RING, 0)
	_mats["rib"] = _mat(SH.RIBBON, 1)
	_mats["shd"] = _mat(SH.SHARD, 0)
	for k in ["smk", "spr", "stk", "rng", "rib"]:
		_batch[k] = Batch.new()
	_batch["shd"] = Batch.new(true)
	var use_vols := rich and not compat
	_chunk_trails = phys == null
	for i in list.size():
		ships.append(_build_ship(i, list[i], use_vols))
	_build_destruction(wreck_src)
	var counts := {}
	for k in _batch:
		counts[k] = (_batch[k] as Batch).count()
	_batch["smk"].build(_mats["smk"], self, "fx_smoke")
	_batch["rng"].build(_mats["rng"], self, "fx_rings")
	_batch["spr"].build(_mats["spr"], self, "fx_sprites")
	_batch["stk"].build(_mats["stk"], self, "fx_streaks")
	_batch["rib"].build(_mats["rib"], self, "fx_ribbons")
	_batch["shd"].build(_mats["shd"], self, "fx_shards")
	if use_vols:
		_build_vols()
	_build_lights()
	if maxm:
		_detail_normals(list)
	notes.append("effects ported from the Babylon half: %d sprites, %d streaks, %d rings, %d ribbon vertices, %d shards in 6 static meshes; %d shields, %d breach decals%s" % [
		(counts["smk"] + counts["spr"]) / 4, counts["stk"] / 4, counts["rng"] / 4, counts["rib"], counts["shd"] / 24, shields.size(),
		decals.size(), ", raymarched volumes for the vents, smoke rings and fireball" if use_vols else ""])


# ---------------------------------------------------------------- anchors (as the Babylon half finds them)

# Hull points in the ship's own frame (centred, bow +x). side +1 = port (+z), -1 = starboard (-z): the outermost hull
# point near (x, y) on that side, as a ray cast in from that side would find it.
func _side_hit(pts: PackedVector3Array, nrm: PackedVector3Array, half: Vector3, x: float, y_frac: float, side: int) -> Dictionary:
	var H := half.y * 2.0
	var L := half.x * 2.0
	if not _tris.is_empty():
		# a ray cast in from that side against the hull's triangles (face normal at the hit), as the Babylon half picks it:
		# the ray runs along z, so a triangle is hit where (x, y) falls inside its xy projection
		for tr in [y_frac, y_frac - 0.1, y_frac + 0.1, y_frac - 0.2, 0.0]:
			var y: float = float(tr) * H
			var bi := clampi(int((x - _tri_x0) / _tri_dx), 0, _tri_bins.size() - 1)
			var best := {}
			var bz := -1e9
			for f in (_tri_bins[bi] as PackedInt32Array):
				var a: Vector3 = _tris[f * 3]
				var b: Vector3 = _tris[f * 3 + 1]
				var c: Vector3 = _tris[f * 3 + 2]
				if x < minf(a.x, minf(b.x, c.x)) or x > maxf(a.x, maxf(b.x, c.x)) or y < minf(a.y, minf(b.y, c.y)) or y > maxf(a.y, maxf(b.y, c.y)):
					continue
				var den := (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
				if absf(den) < 1e-12:
					continue
				var w1 := ((b.y - c.y) * (x - c.x) + (c.x - b.x) * (y - c.y)) / den
				var w2 := ((c.y - a.y) * (x - c.x) + (a.x - c.x) * (y - c.y)) / den
				var w3 := 1.0 - w1 - w2
				if w1 < 0.0 or w2 < 0.0 or w3 < 0.0:
					continue
				var z := a.z * w1 + b.z * w2 + c.z * w3
				if z * side > bz:
					bz = z * side
					var n := (b - a).cross(c - a).normalized()
					if n.z * side < 0.0:
						n = -n
					best = {"p": Vector3(x, y, z), "n": n}
			if not best.is_empty():
				return best
	var tx := maxf(0.02 * L, 0.35)
	var ty := maxf(0.04 * H, 0.25)
	for tr in [y_frac, y_frac - 0.1, y_frac + 0.1, y_frac - 0.2, 0.0]:
		var y: float = tr * H
		var best := -1
		var bz := -1e9
		for j in pts.size():
			var p := pts[j]
			if absf(p.x - x) < tx and absf(p.y - y) < ty:
				var z := p.z * side
				if z > bz:
					bz = z
					best = j
		if best >= 0:
			var n := nrm[best] if best < nrm.size() else Vector3(0, 0, side)
			if n.z * side < 0.0:
				n = -n
			return {"p": pts[best], "n": n.normalized()}
	return {"p": Vector3(x, 0, half.z * side), "n": Vector3(0, 0, side)}


func _anchors(s: Dictionary) -> Dictionary:
	var sc: float = s.get("scale", 1.0)
	var key: String = s["name"]
	if _anchor_cache.has(key):
		return _scaled(_anchor_cache[key], sc / float(_anchor_cache[key]["scale"]))
	var pts: PackedVector3Array = s.get("pts", PackedVector3Array())
	var nrm: PackedVector3Array = s.get("nrm", PackedVector3Array())
	var half: Vector3 = s["half"]
	# the hull's triangles in the ship's frame, binned along x for the side rays
	_tris = PackedVector3Array()
	var root: Node3D = s["root"]
	for m in s.get("meshes", []):
		var mi := m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf := root.global_transform.affine_inverse() * mi.global_transform
		var faces := mi.mesh.get_faces()
		for j in faces.size():
			_tris.append(xf * faces[j])
	_tri_bins = []
	_tri_x0 = -half.x - 1.0
	_tri_dx = (half.x * 2.0 + 2.0) / 128.0
	for j in 128:
		_tri_bins.append(PackedInt32Array())
	for f in _tris.size() / 3:
		var lo := minf(_tris[f * 3].x, minf(_tris[f * 3 + 1].x, _tris[f * 3 + 2].x))
		var hi := maxf(_tris[f * 3].x, maxf(_tris[f * 3 + 1].x, _tris[f * 3 + 2].x))
		for bb in range(clampi(int((lo - _tri_x0) / _tri_dx), 0, 127), clampi(int((hi - _tri_x0) / _tri_dx), 0, 127) + 1):
			_tri_bins[bb].append(f)
	var L := half.x * 2.0
	var W := half.z * 2.0
	var out := {"scale": sc, "L": L, "W": W, "H": half.y * 2.0}
	if pts.size() < 16:
		out["bow"] = Vector3(half.x + 0.4, 0, 0)
		out["nozzles"] = [{"p": Vector3(-half.x - 0.15, 0, 0), "r": 1.0}]
		out["guns"] = []
		for f in [0.28, 0.1, -0.08, -0.26]:
			out["guns"].append({"p": Vector3(f * L, 0, half.z + 0.5), "n": Vector3(0, 0, 1)})
		out["breach"] = {"p": Vector3(-0.17 * L, 0, half.z), "n": Vector3(0, 0, 1)}
		out["stb"] = {"p": Vector3(0.05 * L, 0, -half.z), "n": Vector3(0, 0, -1)}
		_anchor_cache[key] = out
		return out
	# bow: mean of the points in the front 2% of the length
	var cut := half.x - 0.02 * L
	var sy := 0.0
	var sz := 0.0
	var n := 0
	for p in pts:
		if p.x >= cut:
			sy += p.y
			sz += p.z
			n += 1
	out["bow"] = Vector3(half.x + 0.4, sy / n if n > 0 else 0.0, sz / n if n > 0 else 0.0)
	# engines: k-means on (y, z) of the aft 5%; 2 nozzles for slim hulls, 3 for wide ones
	var aft: Array = []
	for p in pts:
		if p.x <= -half.x + 0.05 * L:
			aft.append(p)
	var K := 3 if W > 0.45 * L else 2
	aft.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z < b.z)
	var cen: Array = []
	var nozzles: Array = []
	if aft.size() >= K:
		for c in K:
			var q: Vector3 = aft[int((c + 0.5) / K * aft.size())]
			cen.append(Vector2(q.y, q.z))
		var asg := PackedInt32Array()
		asg.resize(aft.size())
		for it in 12:
			for ai in aft.size():
				var bd := 1e9
				var bi := 0
				for c in K:
					var dd := Vector2(aft[ai].y, aft[ai].z).distance_squared_to(cen[c])
					if dd < bd:
						bd = dd
						bi = c
				asg[ai] = bi
			for c in K:
				var m := Vector2.ZERO
				var cnt := 0
				for ai in aft.size():
					if asg[ai] == c:
						m += Vector2(aft[ai].y, aft[ai].z)
						cnt += 1
				if cnt > 0:
					cen[c] = m / cnt
		for c in K:
			var mx := 1e9
			var s2 := 0.0
			var cnt := 0
			for ai in aft.size():
				if asg[ai] == c:
					mx = minf(mx, aft[ai].x)
					s2 += Vector2(aft[ai].y, aft[ai].z).distance_squared_to(cen[c])
					cnt += 1
			if cnt == 0:
				continue
			nozzles.append({"p": Vector3(mx - 0.15, cen[c].x, cen[c].y), "r": clampf(0.55 * sqrt(s2 / cnt), 0.45, 2.4)})
	if nozzles.is_empty():
		nozzles.append({"p": Vector3(-half.x - 0.15, 0, 0), "r": 1.0})
	out["nozzles"] = nozzles
	var guns: Array = []
	for f in [0.28, 0.1, -0.08, -0.26]:
		var h := _side_hit(pts, nrm, half, f * L, 0.15, 1)
		guns.append({"p": (h["p"] as Vector3) + (h["n"] as Vector3) * 0.5, "n": h["n"]})
	out["guns"] = guns
	out["breach"] = _side_hit(pts, nrm, half, -0.17 * L, 0.08, 1)
	out["stb"] = _side_hit(pts, nrm, half, 0.05 * L, 0.05, -1)
	_anchor_cache[key] = out
	return out


func _scaled(a: Dictionary, k: float) -> Dictionary:
	var o := {"scale": float(a["scale"]) * k, "L": float(a["L"]) * k, "W": float(a["W"]) * k, "H": float(a["H"]) * k,
		"bow": (a["bow"] as Vector3) * k}
	o["nozzles"] = []
	for nz in a["nozzles"]:
		o["nozzles"].append({"p": (nz["p"] as Vector3) * k, "r": float(nz["r"]) * k})
	o["guns"] = []
	for g in a["guns"]:
		var n: Vector3 = g["n"]
		o["guns"].append({"p": ((g["p"] as Vector3) - n * 0.5) * k + n * 0.5, "n": n})
	o["breach"] = {"p": (a["breach"]["p"] as Vector3) * k, "n": a["breach"]["n"]}
	o["stb"] = {"p": (a["stb"]["p"] as Vector3) * k, "n": a["stb"]["n"]}
	return o


# ---------------------------------------------------------------- per-ship effects

func _build_ship(i: int, s: Dictionary, use_vols: bool) -> Dictionary:
	var an := _anchors(s)
	var base: Vector3 = s["pos"]
	var L: float = an["L"]
	var W: float = an["W"]
	var H: float = an["H"]
	var T0 := _stag_of(i)
	var wc: Color = s["weapon"]
	var eng: Color = s["engine"]
	var corsair: bool = s["name"] == "Corsair"
	var d := {"i": i, "root": s["root"], "meshes": s.get("meshes", []), "base": base, "L": L, "weapon": wc, "engine": eng,
		"shield": s["shield"], "fade": -1.0}
	# 1. engines
	for nz in an["nozzles"]:
		var np: Vector3 = base + (nz["p"] as Vector3)
		var r: float = nz["r"]
		var plume_l := clampf(1.5 * W, 6.0, 32.0)
		sprite({"p": np, "t": -20.0, "life": 1.0, "per": 1.0, "col": eng, "i": 2.0, "s0": r * 2.8, "s1": r * 2.8, "kind": 11 if corsair else 4})
		ribbon({"p": np, "dir": Vector3(-1, 0, 0), "len": plume_l, "segs": 14, "kind": 3 if corsair else 0, "col": eng, "i": 0.9,
			"w0": r * 1.3, "w1": r * 0.5, "t": -20.0, "life": 1.0, "per": 1.0})
		ribbon({"p": np + Vector3(-0.3 * plume_l, 0, 0), "dir": Vector3(-1, 0, 0), "len": 60.0, "segs": 40, "kind": 4 if corsair else 1,
			"col": eng, "i": 0.22, "w0": r * 1.1, "w1": r * 2.4, "t": -20.0, "life": 1.0, "per": 1.0})
		if corsair:
			for k in 9:
				var tk := -20.0 + k * 0.23 + (k % 3) * 0.05
				sprite({"p": np + _rdir() * 0.3, "t": tk, "life": 1.8, "per": 2.1, "vel": Vector3(-5 - _rng.randf() * 3, _rng.randf() - 0.3, _rng.randf() - 0.5),
					"drag": 0.8, "col": Color(0.06, 0.05, 0.045), "i": 0.55, "s0": r * 1.2, "s1": r * 4.5, "kind": 8})
	# 2. broadside at 0.0: four guns ripple 80 ms apart, bow to stern
	var tgts: Array = []
	var tis: Array = []
	var fire_dir := Vector3(0, 0, 1)
	var gun_ps: Array = []
	for gi in an["guns"].size():
		var g: Dictionary = an["guns"][gi]
		var gp: Vector3 = base + (g["p"] as Vector3)
		gun_ps.append(gp)
		var tg: float = T0 + gi * 0.08
		var tgt := gp + Vector3(4 - gi * 2, 3 + _rng.randf() * 2, 70 + _rng.randf() * 4)
		var dv := tgt - gp
		var dist := dv.length()
		var dir := dv / dist
		fire_dir = dir
		sprite({"p": gp + dir * 0.6, "t": tg, "life": 0.09, "per": PER, "col": _tint(wc, 0.25), "i": 11.0, "s0": 3.2, "s1": 5.0, "kind": 0})
		sprite({"p": gp + dir * 1.2, "t": tg, "life": 0.16, "per": PER, "col": Color(1, 0.7, 0.4), "i": 5.0, "s0": 1.6, "s1": 3.2, "kind": 2})
		streak({"p": gp, "t": tg, "vel": dir, "life": 0.13, "per": PER, "col": _tint(wc, 0.35), "i": 5.0, "len": 4.5, "w": 1.5, "kind": 3})
		if not use_vols:
			ring({"p": gp + dir * 1.0, "n": dir, "t": tg + 0.02, "life": 2.0, "per": PER, "col": Color(0.24, 0.23, 0.22), "i": 0.55, "s0": 1.0,
				"s1": 5.5, "kind": 0, "speed": 5.0, "drag": 1.4})
		tgts.append(tgt)
		tis.append(gi * 0.08 + dist / 160.0)
		for k in 3:
			sprite({"p": gp + dir * (1.0 + k), "t": tg + 0.03 + k * 0.03, "life": 1.6 + _rng.randf() * 0.4, "per": PER, "vel": _rcone(dir, 0.5) * (2 + _rng.randf() * 2),
				"drag": 1.0, "col": Color(0.20, 0.19, 0.18), "i": 0.4, "s0": 1.2, "s1": 4.0 + _rng.randf() * 2, "kind": 3})
		streak({"p": gp, "t": tg, "vel": dir * 160.0, "life": dist / 160.0, "per": PER, "col": _tint(wc, 0.3), "i": 16.0, "len": 9.0, "w": 0.6, "kind": 0})
		var ti: float = tg + dist / 160.0
		sprite({"p": tgt, "t": ti, "life": 0.14, "per": PER, "col": _tint(wc, 0.4), "i": 9.0, "s0": 2.5, "s1": 4.5, "kind": 0})
		for k in 12:
			var sd := _rcone(dir * -0.4, 1.0)
			streak({"p": tgt, "t": ti + _rng.randf() * 0.03, "vel": sd * (14 + _rng.randf() * 18), "life": 0.3 + _rng.randf() * 0.35, "per": PER,
				"col": Color(1, 0.62, 0.28), "i": 7.0, "len": 0.04, "w": 0.13, "drag": 2.2, "kind": 1})
		for k in 6:
			shard({"p": tgt, "t": ti, "life": 2.2, "per": PER, "vel": _rcone(dir * -0.3, 1.0) * (4 + _rng.randf() * 6), "drag": 0.4,
				"spin": 3 + _rng.randf() * 6, "size": 0.08 + _rng.randf() * 0.12, "heat": 0.8})
		sprite({"p": tgt, "t": ti + 0.04, "life": 1.1, "per": PER, "vel": _rdir() * 1.5, "drag": 1.0, "col": Color(0.18, 0.17, 0.16), "i": 0.35,
			"s0": 1.2, "s1": 3.5, "kind": 3})
	d["tgt"] = tgts
	d["ti"] = tis
	d["guns"] = gun_ps
	d["gun_n"] = []
	for g in an["guns"]:
		d["gun_n"].append(g["n"])
	d["fire_dir"] = fire_dir
	# 3. lance at 1.5 for 0.7 s, charge flare from 1.25
	var bow: Vector3 = base + (an["bow"] as Vector3)
	var tb := T0 + 1.5
	var end := bow + Vector3(80, 0, 0)
	d["bow"] = bow
	d["end"] = end
	sprite({"p": bow, "t": tb - 0.25, "life": 0.25, "per": PER, "col": _tint(wc, 0.2), "i": 9.0, "s0": 0.6, "s1": 5.0, "kind": 12})
	sprite({"p": bow, "t": tb, "life": 0.7, "per": PER, "col": _tint(wc, 0.3), "i": 7.0, "s0": 4.5, "s1": 4.5, "kind": 13})
	ribbon({"p": bow, "dir": Vector3(1, 0, 0), "len": 80.0, "segs": 24, "kind": 2, "col": wc, "i": 2.4, "w0": 2.4, "w1": 2.0, "t": tb, "life": 0.7, "per": PER})
	sprite({"p": end, "t": tb + 0.03, "life": 0.67, "per": PER, "col": _tint(wc, 0.4), "i": 9.0, "s0": 7.0, "s1": 7.0, "kind": 13})
	for k in 44:
		var sd := _rcone(Vector3(-0.6, 0.2, 0), 1.1)
		streak({"p": end, "t": tb + 0.04 + k * 0.015, "vel": sd * (14 + _rng.randf() * 22), "life": 0.35 + _rng.randf() * 0.5, "per": PER,
			"col": wc.lerp(Color(1, 0.8, 0.5), 0.5), "i": 7.0, "len": 0.05, "w": 0.14, "drag": 1.6, "kind": 1})
	for k in 4:
		sprite({"p": end, "t": tb + 0.1 + k * 0.15, "life": 1.2, "per": PER, "vel": _rdir() * 2.5, "drag": 0.8, "col": Color(0.2, 0.19, 0.18),
			"i": 0.35, "s0": 2.0, "s1": 6.0, "kind": 3})
	# 4. incoming shell, then a shield hit (or a hull hit) on the starboard side at 2.4
	var th := T0 + 2.4
	var hp: Vector3 = base + (an["stb"]["p"] as Vector3)
	var in_dir := Vector3(-0.25, 0.22, -1).normalized()
	if s["shield"] != null:
		var sc: Color = s["shield"]
		var rad := Vector3(L * 0.5 * 1.12 + 1.0, H * 0.5 * 1.3 + 1.2, W * 0.5 * 1.3 + 1.2)
		var ctr := base
		var hit_pt := Vector3(hp.x, ctr.y + (hp.y - ctr.y) * 0.5, ctr.z - rad.z)
		streak({"p": hit_pt + in_dir * 80.0, "t": th - 0.5, "vel": in_dir * -160.0, "life": 0.5, "per": PER, "col": ENEMY, "i": 14.0, "len": 9.0, "w": 0.55, "kind": 0})
		var sph := SphereMesh.new()
		sph.radius = 1.0
		sph.height = 2.0
		sph.radial_segments = 64
		sph.rings = 32
		var sm := _mat(SH.SHIELD, 2)
		sm.set_shader_parameter("t0", th)
		sm.set_shader_parameter("patchy", 1.0 if corsair else 0.0)
		sm.set_shader_parameter("hit_off", hit_pt - ctr)
		sm.set_shader_parameter("col", Vector3(sc.r, sc.g, sc.b) * 2.2)
		sm.set_shader_parameter("rad", rad)
		var shm := MeshInstance3D.new()
		shm.name = "shield"
		shm.mesh = sph
		shm.material_override = sm
		shm.scale = rad
		shm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shm.visible = false
		(s["root"] as Node3D).add_child(shm)
		shields.append({"mesh": shm, "t0": th})
		sprite({"p": hit_pt, "t": th, "life": 0.16, "per": PER, "col": sc.lerp(Color.WHITE, 0.4), "i": 7.0, "s0": 2.5, "s1": 4.5, "kind": 0})
		for k in 10:
			streak({"p": hit_pt, "t": th + _rng.randf() * 0.03, "vel": _rcone(Vector3(0, 0, -1), 0.9) * (10 + _rng.randf() * 14), "life": 0.25 + _rng.randf() * 0.3,
				"per": PER, "col": sc.lerp(Color.WHITE, 0.5), "i": 6.0, "len": 0.04, "w": 0.12, "drag": 2.5, "kind": 1})
		d["hit"] = hit_pt
	else:
		streak({"p": hp + in_dir * 80.0, "t": th - 0.5, "vel": in_dir * -160.0, "life": 0.5, "per": PER, "col": ENEMY, "i": 14.0, "len": 9.0, "w": 0.55, "kind": 0})
		var hn: Vector3 = an["stb"]["n"]
		sprite({"p": hp + hn * 0.3, "t": th, "life": 0.12, "per": PER, "col": Color(1, 0.75, 0.45), "i": 12.0, "s0": 3.0, "s1": 5.5, "kind": 0})
		sprite({"p": hp + hn * 0.4, "t": th, "life": 0.3, "per": PER, "col": Color(1, 0.7, 0.4), "i": 6.0, "s0": 1.2, "s1": 3.6, "kind": 2})
		for k in 22:
			streak({"p": hp, "t": th + _rng.randf() * 0.05, "vel": _rcone(hn, 0.9) * (9 + _rng.randf() * 18), "life": 0.3 + _rng.randf() * 0.45, "per": PER,
				"col": Color(1, 0.55, 0.15), "i": 8.0, "len": 0.04, "w": 0.13, "drag": 2.2, "kind": 1})
		if phys == null:
			for k in 12:
				shard({"p": hp + hn * 0.2, "t": th, "life": 2.6, "per": PER, "vel": _rcone(hn, 0.8) * (3 + _rng.randf() * 7), "drag": 0.3,
					"spin": 2 + _rng.randf() * 6, "size": 0.15 + _rng.randf() * 0.25, "heat": 1.0})
		for k in 3:
			sprite({"p": hp + hn * 0.5, "t": th + 0.03 * k, "life": 0.6, "per": PER, "vel": hn * 2.0 + _rdir() * 0.6, "col": Color(1, 0.5, 0.15),
				"i": 3.0, "s0": 1.0, "s1": 2.8, "kind": 1})
		sprite({"p": hp + hn * 0.6, "t": th + 0.1, "life": 1.6, "per": PER, "vel": hn * 2.0, "drag": 0.6, "col": Color(0.12, 0.11, 0.1), "i": 0.5,
			"s0": 1.5, "s1": 5.0, "kind": 3})
		d["hit"] = hp
		d["hit_n"] = hn
	# 5. persistent breach on the upper port flank (about 1/10 of the length across)
	var brp: Vector3 = base + (an["breach"]["p"] as Vector3)
	var bn: Vector3 = an["breach"]["n"]
	var hole := L / 10.0
	d["breach"] = brp
	d["breach_n"] = bn
	var t1 := bn.cross(Vector3(0, 1, 0) if absf(bn.y) < 0.9 else Vector3(1, 0, 0)).normalized()
	var t2 := bn.cross(t1)
	_build_decal(d, brp - base, bn, hole)
	_build_petals(d, brp - base, bn, t1, t2, hole)
	var P := brp + bn * 0.2
	var up := Vector3(0, 1, 0)
	if not use_vols:
		for k in 40:
			var tk := -20.0 + k * 0.045
			var wav := sin(k * 0.45) * 0.25
			var puff := 0.7 + 0.3 * sin(k * 0.9)
			var vd := (bn + t1 * wav + up * 0.25).normalized() * ((9 + _rng.randf() * 3) * puff)
			sprite({"p": P, "t": tk, "life": 1.8, "per": 1.8, "vel": vd, "drag": 0.7, "col": Color(0.62, 0.68, 0.78), "i": 0.3 * puff,
				"s0": hole * 0.2, "s1": hole * 1.1, "kind": 7, "spin": _rng.randf() - 0.5})
	if phys == null:
		for k in 9:
			shard({"p": P, "t": -20.0 + k * 0.37, "life": 3.3, "per": 3.3, "vel": _rcone(bn + up * 0.2, 0.6) * (2.5 + _rng.randf() * 3),
				"spin": 1 + _rng.randf() * 4, "size": hole * (0.05 + _rng.randf() * 0.07), "heat": 0.7})
	for k in 14:
		var fa := _rng.randf() * TAU
		var off := t1 * (cos(fa) * hole * 0.42) + t2 * (sin(fa) * hole * 0.42)
		sprite({"p": brp + off + bn * 0.1, "t": -20.0 + k * 0.064, "life": 0.45 + _rng.randf() * 0.3, "per": 0.9,
			"vel": bn * (1.2 + _rng.randf()) + up * 1.2 + off * 0.6, "col": Color(1, 0.5, 0.15), "i": 2.4, "s0": hole * 0.15, "s1": hole * 0.5, "kind": 1})
	var s_off := _spark_off(i)
	var p_off := _pop_off(i)
	for k in 18:
		streak({"p": P, "t": s_off + _rng.randf() * 0.12, "vel": _rcone(bn + up * 0.3, 0.8) * (6 + _rng.randf() * 12), "life": 0.35 + _rng.randf() * 0.5,
			"per": SPARKS_EVERY, "col": Color(1, 0.62, 0.25), "i": 8.0, "len": 0.05, "w": 0.12, "drag": 1.5, "kind": 1})
	var Pp := P + bn * 0.5
	sprite({"p": Pp, "t": p_off, "life": 0.12, "per": POP_EVERY, "col": Color(1, 0.75, 0.45), "i": 10.0, "s0": hole * 0.8, "s1": hole * 1.6, "kind": 0})
	sprite({"p": Pp, "t": p_off, "life": 0.35, "per": POP_EVERY, "col": Color(1, 0.7, 0.4), "i": 6.0, "s0": hole * 0.3, "s1": hole * 1.3, "kind": 2})
	for k in 5:
		sprite({"p": Pp + _rdir() * hole * 0.2, "t": p_off + _rng.randf() * 0.05, "life": 0.6 + _rng.randf() * 0.3, "per": POP_EVERY,
			"vel": _rcone(bn, 0.7) * (2 + _rng.randf() * 2), "col": Color(1, 0.55, 0.2), "i": 3.2, "s0": hole * 0.4, "s1": hole * 1.1, "kind": 1})
	for k in 12:
		streak({"p": Pp, "t": p_off + _rng.randf() * 0.04, "vel": _rcone(bn, 1.0) * (8 + _rng.randf() * 14), "life": 0.3 + _rng.randf() * 0.4,
			"per": POP_EVERY, "col": Color(1, 0.6, 0.25), "i": 7.0, "len": 0.04, "w": 0.12, "drag": 2.0, "kind": 1})
	for k in 3:
		sprite({"p": Pp, "t": p_off + 0.1, "life": 1.5, "per": POP_EVERY, "vel": _rcone(bn, 0.6) * 2.5, "drag": 0.7, "col": Color(0.12, 0.11, 0.1),
			"i": 0.45, "s0": hole * 0.5, "s1": hole * 2.0, "kind": 3})
	d["pop_off"] = p_off
	d["hole"] = hole
	d["t1"] = t1
	return d


func _build_decal(d: Dictionary, local_p: Vector3, bn: Vector3, hole: float) -> void:
	var box := MeshInstance3D.new()
	box.name = "breach_decal"
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	box.mesh = bm
	var m := _mat(SH.DECAL, -2, "#define POM\n" if rich else "")
	m.set_shader_parameter("seed", _rng.randf() * 10.0)
	box.material_override = m
	box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var y := bn.normalized()
	var x := y.cross(Vector3(0, 1, 0) if absf(y.y) < 0.9 else Vector3(1, 0, 0)).normalized()
	var z := x.cross(y)
	var b := Basis(x, y, z).rotated(y, _rng.randf() * TAU)
	box.transform = Transform3D(b.scaled_local(Vector3(hole * 2.6, hole * 1.5, hole * 2.6)), local_p)
	(d["root"] as Node3D).add_child(box)
	decals.append(m)
	d["decal"] = m


func _build_petals(d: Dictionary, local_p: Vector3, bn: Vector3, t1: Vector3, t2: Vector3, hole: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 13:
		var an := k / 13.0 * TAU + _rng.randf() * 0.4
		var rr := hole * (0.4 + _rng.randf() * 0.08)
		var radial := t1 * cos(an) + t2 * sin(an)
		var tang := t1 * -sin(an) + t2 * cos(an)
		var bw := hole * (0.03 + _rng.randf() * 0.05)
		var ln := hole * (0.1 + _rng.randf() * 0.18)
		var base := local_p + radial * rr + bn * -0.03
		var out_d := (radial * 0.9 + bn * (0.25 + _rng.randf() * 0.45)).normalized()
		var a := base + tang * bw
		var b := base - tang * bw
		var tip := base + out_d * ln + tang * ((_rng.randf() - 0.5) * bw)
		var nn := (b - a).cross(tip - a).normalized()
		for q in [[a, Vector2(0, 0)], [b, Vector2(1, 0)], [tip, Vector2(0.5, 1)]]:
			st.set_normal(nn)
			st.set_uv(q[1])
			st.add_vertex(q[0])
	var mi := MeshInstance3D.new()
	mi.name = "breach_plates"
	mi.mesh = st.commit()
	var m := _mat(SH.PETAL, 0)
	m.set_shader_parameter("seed", _rng.randf() * 10.0)
	mi.material_override = m
	(d["root"] as Node3D).add_child(mi)
	d["petals"] = mi


# ---------------------------------------------------------------- destruction

const CUTS := [Vector3(0.22, 0.25, 0.0), Vector3(0.0, 0.1, -0.3), Vector3(-0.24, -0.2, 0.15)]   # x - (a + b y + c z)


func _cut_side(j: int, q: Vector3) -> float:
	var c: Vector3 = CUTS[j]
	return q.x - (c.x + c.y * q.y + c.z * q.z)


func _build_destruction(src: Dictionary) -> void:
	if not src.has("surfs") or src["surfs"].is_empty() or not src.has("center"):
		notes.append("destruction event skipped: Hegemony mesh not loaded")
		return
	var k: float = float(src["scale"]) * D_SCALE
	var c0: Vector3 = src["center"]
	var surf: Array = src["surfs"][0]
	var arr: Array = surf[0]
	var mat: Material = surf[1]
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx := PackedInt32Array()
	if arr[Mesh.ARRAY_INDEX] != null:
		idx = arr[Mesh.ARRAY_INDEX]
	else:
		idx.resize(v.size())
		for j in v.size():
			idx[j] = j
	var tris := [PackedInt32Array(), PackedInt32Array(), PackedInt32Array(), PackedInt32Array()]
	var near := [PackedVector3Array(), PackedVector3Array(), PackedVector3Array(), PackedVector3Array()]
	var sums := [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	var cnts := [0, 0, 0, 0]
	for ti in range(0, idx.size() - 2, 3):
		var q := (v[idx[ti]] + v[idx[ti + 1]] + v[idx[ti + 2]]) / 3.0 - c0
		var ci := 3
		for j in 3:
			if _cut_side(j, q) > 0.0:
				ci = j
				break
		tris[ci].append_array(PackedInt32Array([idx[ti], idx[ti + 1], idx[ti + 2]]))
		sums[ci] += q
		cnts[ci] += 1
		var dmin := 1e9
		for j in mini(ci + 1, 3):
			var c: Vector3 = CUTS[j]
			dmin = minf(dmin, absf(_cut_side(j, q)) / sqrt(1.0 + c.y * c.y + c.z * c.z))
		if dmin < 0.015 and near[ci].size() < 400:
			near[ci].append(q)
	var cmat: Material = mat.duplicate() if mat != null else StandardMaterial3D.new()
	if cmat is BaseMaterial3D:
		(cmat as BaseMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	var root := Node3D.new()
	root.name = "Destruction"
	add_child(root)
	for ci in 4:
		if cnts[ci] == 0:
			continue
		var cen: Vector3 = sums[ci] / float(cnts[ci])
		var carr := arr.duplicate()
		carr[Mesh.ARRAY_INDEX] = tris[ci]
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, carr)
		am.surface_set_material(0, cmat)
		var node: Node3D = Node3D.new()
		if phys != null:
			var hp := PackedVector3Array()
			var step := maxi(1, tris[ci].size() / 800)
			for j in range(0, tris[ci].size(), step):
				hp.append((v[tris[ci][j]] - c0 - cen) * k)
			node = phys.make_chunk(hp)
		node.name = "chunk%d" % ci
		root.add_child(node)
		var mi := MeshInstance3D.new()
		mi.mesh = am
		mi.transform = Transform3D(Basis.from_scale(Vector3(k, k, k)), -(c0 + cen) * k)
		node.add_child(mi)
		# burning break lines: an additive pass glowing along the cut planes this chunk borders
		var em := _mat(SH.CHUNK_EDGE, 1)
		em.set_shader_parameter("cen", c0)
		em.set_shader_parameter("width", 0.22 / k)
		for j in 3:
			var c: Vector3 = CUTS[j]
			em.set_shader_parameter("pl%d" % j, Vector4(c.x, c.y, c.z, 1.0 if (j <= ci) else 0.0))
		mi.material_overlay = em
		# fire and squibs along the break, in the chunk's own frame (they ride with it)
		var cb := Batch.new()
		var fmat := _mat(SH.SPRITE, 1)
		fmat.set_shader_parameter("gate", 0.0)
		var mids: PackedVector3Array = near[ci]
		if mids.is_empty():
			mids.append(cen)
		for kk in 16:
			var m0: Vector3 = mids[_rng.randi() % mids.size()] - cen
			sprite({"batch": cb, "p": m0, "t": kk * 0.05, "life": 0.5 + _rng.randf() * 0.3, "per": 0.8, "vel": _rdir() * (1.2 / k),
				"col": Color(1, 0.5, 0.15), "i": 2.8, "s0": 0.6, "s1": 2.0, "kind": 1, "drift": 0.0})
		for kk in 10:
			var m1: Vector3 = mids[_rng.randi() % mids.size()] - cen
			sprite({"batch": cb, "p": m1, "t": dt0 + BREAK + 0.1 + _rng.randf() * (d_out - 1.0), "life": 0.2, "per": dper,
				"col": Color(1, 0.7, 0.4), "i": 7.0, "s0": 0.6, "s1": 2.6, "kind": 5, "drift": 0.0})
		var fire := cb.build(fmat, node, "fire")
		fire.scale = Vector3(k, k, k)
		var rest := DC + cen * k
		var out := (cen * k + _rdir() * 1.5).normalized()
		var wreck := ci == 2
		var c := {"node": node, "mesh": mi, "rest": rest, "edge": em, "fire": fmat,
			"vel": out * (1.2 if wreck else 4.0 + _rng.randf() * 3.0) + Vector3(0, -0.3 if wreck else _rng.randf() * 1.5, 0),
			"axis": _rdir(), "w": 0.22 if wreck else 0.5 + _rng.randf() * 0.7}
		node.position = rest
		chunks.append(c)
	# precursor squibs on the hull, the flash, shockwaves, fireball, smoke, flames, sparks and shards (world space, no drift)
	var rest_v: Array = []
	for kk in 6:
		var vv := v[idx[_rng.randi() % idx.size()]]
		rest_v.append(DC + (vv - c0) * k)
	var tss := [0.05, 0.13, 0.22, 0.3, 0.36]
	for kk in tss.size():
		var p: Vector3 = rest_v[kk]
		sprite({"p": p, "t": dt0 + tss[kk], "life": 0.18, "per": dper, "col": Color(1, 0.7, 0.4), "i": 9.0, "s0": 1.0, "s1": 4.0, "kind": 5, "drift": 0.0})
		for j in 8:
			streak({"p": p, "t": dt0 + tss[kk], "vel": _rdir() * (10 + _rng.randf() * 15), "life": 0.3 + _rng.randf() * 0.3, "per": dper,
				"col": Color(1, 0.6, 0.25), "i": 7.0, "len": 0.04, "w": 0.12, "drag": 2.0, "kind": 1, "drift": 0.0})
	var TB := dt0 + BREAK
	var DL := func(x: float) -> float: return minf(x, dper - 0.1)
	sprite({"p": DC, "t": TB, "life": 0.3, "per": dper, "col": Color(1, 0.9, 0.75), "i": 26.0, "s0": 22.0, "s1": 60.0, "kind": 0, "drift": 0.0})
	sprite({"p": DC, "t": TB, "life": 0.6, "per": dper, "col": Color(1, 0.8, 0.55), "i": 10.0, "s0": 6.0, "s1": 18.0, "kind": 2, "drift": 0.0})
	ring({"p": DC, "n": Vector3(0.12, 1, 0.08), "t": TB, "life": 1.8, "per": dper, "col": Color(0.45, 0.6, 1.0), "i": 0.8, "s0": 2.0, "s1": 110.0, "kind": 1, "drift": 0.0})
	ring({"p": DC, "n": Vector3(0.6, 0.5, -0.4), "t": TB + 0.05, "life": 1.1, "per": dper, "col": Color(1.0, 0.6, 0.3), "i": 0.45, "s0": 2.0, "s1": 55.0, "kind": 1, "drift": 0.0})
	if not (rich and not compat):
		for kk in 12:
			sprite({"p": DC + _rdir() * (_rng.randf() * 3), "t": TB + 0.25 + _rng.randf() * 0.5, "life": DL.call(3.8 + _rng.randf() * 1.2) - 0.75, "per": dper,
				"vel": _rdir() * (2 + _rng.randf() * 3), "drag": 0.35, "col": Color(0.07, 0.065, 0.06), "i": 0.75, "s0": 7.0, "s1": 24.0 + _rng.randf() * 8, "kind": 3, "drift": 0.0})
	for kk in 18:
		sprite({"p": DC + _rdir() * (_rng.randf() * 3.5), "t": TB + _rng.randf() * 0.15, "life": 1.5 + _rng.randf() * 1.0, "per": dper,
			"vel": _rdir() * (3 + _rng.randf() * 5), "drag": 0.6, "col": Color(1, 0.55, 0.2), "i": 2.4, "s0": 5 + _rng.randf() * 3, "s1": 13 + _rng.randf() * 5,
			"kind": 1, "drift": 0.0, "spin": (_rng.randf() - 0.5) * 1.5})
	for kk in 110:
		streak({"p": DC + _rdir() * (_rng.randf() * 2), "t": TB + _rng.randf() * 0.2, "vel": _rdir() * (15 + _rng.randf() * 35), "life": DL.call(1.2 + _rng.randf() * 2.2) - 0.6,
			"per": dper, "col": Color(1, 0.55 + _rng.randf() * 0.15, 0.22), "i": 6.0, "len": 0.05, "w": 0.16, "drag": 0.5, "kind": 1, "drift": 0.0})
	if phys == null:
		for kk in 60:
			shard({"p": DC + _rdir() * (_rng.randf() * 3), "t": TB + _rng.randf() * 0.1, "life": DL.call(7.0) - 0.5, "per": dper, "vel": _rdir() * (4 + _rng.randf() * 14),
				"drag": 0.15, "spin": 1 + _rng.randf() * 5, "size": 0.2 + _rng.randf() * 0.9, "heat": 1.0, "drift": 0.0})
		for ci in chunks.size():
			var c: Dictionary = chunks[ci]
			for kk in (26 if ci == 2 else 14):
				var dtt := 0.15 + kk * 0.28
				if BREAK + dtt + 2.6 > dper - 0.1:
					break
				sprite({"p": (c["rest"] as Vector3) + (c["vel"] as Vector3) * dtt, "t": TB + dtt, "life": 2.6, "per": dper, "vel": _rdir() * 0.6,
					"col": Color(0.09, 0.085, 0.08), "i": 0.5, "s0": 2.0, "s1": 6.0, "kind": 3, "drift": 0.0})
	flash = OmniLight3D.new()
	flash.name = "destruction_flash"
	flash.light_color = Color(1.0, 0.85, 0.62)
	flash.omni_range = 140.0
	flash.light_energy = 0.0
	flash.position = DC
	flash.visible = false
	add_child(flash)


# ---------------------------------------------------------------- volumes (rich and max)

func _vol(type: float, parent: Node) -> Dictionary:
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	box.mesh = bm
	# drawn after the glow sprites, as the Babylon half's sorting ends up drawing them from the battle camera, so a dense
	# fireball covers the flash behind it instead of being washed white by it
	var m := _mat(SH.VOL, 2)
	m.set_shader_parameter("vtype", type)
	m.set_shader_parameter("key_dir", KEY_DIR.normalized())
	m.set_shader_parameter("key_col", Vector3(KEY_COL.r, KEY_COL.g, KEY_COL.b) * 3.2)
	m.set_shader_parameter("amb", Vector3(0.8, 0.8, 0.8))
	box.material_override = m
	box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(box)
	var o := {"mesh": box, "mat": m, "P": Vector4.ZERO}
	vols.append(o)
	return o


func _build_vols() -> void:
	vol_boom = _vol(0.0, self)
	(vol_boom["mesh"] as Node3D).position = DC
	(vol_boom["mesh"] as Node3D).scale = Vector3.ONE * 44.0
	vol_boom["P"] = Vector4(0, 0, 0, 0.16)
	vol_boom["boom"] = true
	for d in ships:
		var hole: float = d["hole"]
		var bn: Vector3 = d["breach_n"]
		var v := _vol(1.0, d["root"])
		var y := bn.normalized()
		var x := y.cross(Vector3(0, 0, 1) if absf(y.z) < 0.9 else Vector3(1, 0, 0)).normalized()
		var z := x.cross(y)
		(v["mesh"] as Node3D).transform = Transform3D(Basis(x, y, z).scaled_local(Vector3(hole * 2.4, hole * 6.0, hole * 2.4)),
			(d["breach"] as Vector3) - (d["base"] as Vector3) + bn * (hole * 3.0 - 0.1))
		v["P"] = Vector4(0.6, 0, d["i"] * 1.7, 0.3)
		v["ship"] = d
		var gmin: Vector3 = d["guns"][0]
		var gmax: Vector3 = d["guns"][0]
		for g in d["guns"]:
			gmin = gmin.min(g)
			gmax = gmax.max(g)
		var dir: Vector3 = d["fire_dir"]
		var r := _vol(2.0, self)
		var mid := (gmin + gmax) * 0.5 + dir * 5.5
		(r["mesh"] as Node3D).position = mid
		(r["mesh"] as Node3D).scale = Vector3(gmax.x - gmin.x + 14.0, 14.0, 14.0)
		r["P"] = Vector4(_stag_of(d["i"]), 1, 0, 0.35)
		r["base"] = mid
		r["ship"] = d
		var rm: ShaderMaterial = r["mat"]
		rm.set_shader_parameter("dir", dir)
		for k in 4:
			rm.set_shader_parameter("g%d" % k, (d["guns"][k] as Vector3) + dir * 1.0)


# ---------------------------------------------------------------- lights

func _omni(parent: Node, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.omni_range = rng
	l.light_energy = 0.0
	l.light_specular = 1.0
	l.shadow_enabled = false
	l.visible = false
	parent.add_child(l)
	_lights.append(l)
	return l


func _build_lights() -> void:
	for d in ships:
		d["gun_p"] = []
		for gi in d["guns"].size():
			d["gun_p"].append((d["guns"][gi] as Vector3) + (d["gun_n"][gi] as Vector3) * 1.5)
		d["p_breach"] = (d["breach"] as Vector3) + (d["breach_n"] as Vector3) * 1.5
		d["p_pop"] = (d["breach"] as Vector3) + (d["breach_n"] as Vector3) * 2.0
		d["p_charge"] = (d["bow"] as Vector3) + Vector3(1, 0, 0)
		d["p_beam"] = (d["bow"] as Vector3) + Vector3(1.5, 0, 0)
		d["p_hit"] = (d["hit"] as Vector3) + Vector3(0, 0, -1.5)
		d["c_gun"] = (d["weapon"] as Color).lerp(Color.WHITE, 0.4)
		d["c_hit"] = d["shield"] if d["shield"] != null else Color(1, 0.6, 0.3)
		if not rich:
			var l := _omni(self, 26.0)
			d["light"] = l
	if rich:
		for k in POOL_N:
			pool.append(_omni(self, POOL_R))
	if flash != null:
		_lights.append(flash)


const LC_BREACH := Color(1, 0.45, 0.12)
const LC_POP := Color(1, 0.6, 0.3)
const LC_FIRE := Color(1, 0.5, 0.15)


# every light event this frame: [position, intensity, colour]
func _events(t: float, dx: float, gate: float) -> Array:
	var ev: Array = []
	var off := Vector3(dx, 0, 0)
	for d in ships:
		var i: int = d["i"]
		var lt := t - _stag_of(i)
		ev.append([(d["p_breach"] as Vector3) + off, 0.7 + 0.3 * sin(t * 23.0 + i) * sin(t * 7.1 + i * 2), LC_BREACH])
		var dp := fposmod(t - float(d["pop_off"]), POP_EVERY)
		if t >= float(d["pop_off"]) and dp < 0.3:
			ev.append([(d["p_pop"] as Vector3) + off, 6.0 * pow(1.0 - dp / 0.3, 2.0), LC_POP])
		if lt < 0.0:
			continue
		var tu := fmod(lt, PER)
		for g in d["gun_p"].size():
			var gt: float = tu - g * 0.08
			if gt >= 0.0 and gt < 0.14:
				ev.append([(d["gun_p"][g] as Vector3) + off, 7.0 * pow(1.0 - gt / 0.14, 2.0), d["c_gun"]])
			var di := tu - float(d["ti"][g])
			if di >= 0.0 and di < 0.2:
				ev.append([(d["tgt"][g] as Vector3) + off, 6.0 * pow(1.0 - di / 0.2, 2.0), d["c_gun"]])
		if tu >= 1.25 and tu < 1.5:
			ev.append([(d["p_charge"] as Vector3) + off, 3.0 * pow((tu - 1.25) / 0.25, 2.0), d["weapon"]])
		if tu >= 1.5 and tu < 2.2:
			var bi := 4.0 * (0.85 + 0.15 * sin(t * 60.0))
			ev.append([(d["p_beam"] as Vector3) + off, bi, d["weapon"]])
			ev.append([(d["end"] as Vector3) + off, bi * 1.2, d["weapon"]])
		if tu >= 2.4 and tu < 2.75:
			ev.append([(d["p_hit"] as Vector3) + off, 6.0 * pow(1.0 - (tu - 2.4) / 0.35, 2.0), d["c_hit"]])
	if gate > 0.0:
		for c in chunks:
			ev.append([(c["node"] as Node3D).global_position, 1.6 * gate, LC_FIRE])
	return ev


func _ship_light(d: Dictionary, t: float) -> Array:
	var i: int = d["i"]
	var lt := t - _stag_of(i)
	var best := 0.7 + 0.3 * sin(t * 23.0 + i) * sin(t * 7.1 + i * 2)
	var p: Vector3 = d["p_breach"]
	var c: Color = LC_BREACH
	var dp := fposmod(t - float(d["pop_off"]), POP_EVERY)
	if t >= float(d["pop_off"]) and dp < 0.3:
		var I := 6.0 * pow(1.0 - dp / 0.3, 2.0)
		if I > best:
			best = I
			p = d["p_pop"]
			c = LC_POP
	if lt >= 0.0:
		var tau := fmod(lt, PER)
		for g in d["gun_p"].size():
			var gt: float = tau - g * 0.08
			if gt >= 0.0 and gt < 0.14:
				var I := 7.0 * pow(1.0 - gt / 0.14, 2.0)
				if I > best:
					best = I
					p = d["gun_p"][g]
					c = d["c_gun"]
		if tau >= 1.25 and tau < 1.5:
			var I := 3.0 * pow((tau - 1.25) / 0.25, 2.0)
			if I > best:
				best = I
				p = d["p_charge"]
				c = d["weapon"]
		if tau >= 1.5 and tau < 2.2:
			var I := 4.0 * (0.85 + 0.15 * sin(t * 60.0))
			if I > best:
				best = I
				p = d["p_beam"]
				c = d["weapon"]
		if tau >= 2.4 and tau < 2.75:
			var I := 6.0 * pow(1.0 - (tau - 2.4) / 0.35, 2.0)
			if I > best:
				best = I
				p = d["p_hit"]
				c = d["c_hit"]
	return [p, best, c]


# ---------------------------------------------------------------- per frame

func update(t: float) -> void:
	RenderingServer.global_shader_parameter_set(&"scene_t", t)
	var dx := _drift(t)
	var fade := _ship_fade(t)
	for d in ships:
		var root: Node3D = d["root"]
		root.position.x = (d["base"] as Vector3).x + dx
	if fade != _fade:
		_fade = fade
		for d in ships:
			for m in d["meshes"]:
				(m as GeometryInstance3D).transparency = 1.0 - fade
			(d["decal"] as ShaderMaterial).set_shader_parameter("fade", fade)
			(d["petals"] as Node3D).visible = fade > 0.5
	for sh in shields:
		var a := t - float(sh["t0"])
		var age := fposmod(a, PER)
		(sh["mesh"] as Node3D).visible = prewarm or (a >= 0.0 and age <= 0.62)
	# destruction
	var tau := fmod(t - dt0, dper) if t >= dt0 else -1.0
	var broke := tau >= BREAK and tau < d_in
	var vis := 1.0
	if tau >= d_out and tau < d_in:
		vis = 1.0 - (tau - d_out)
	elif tau >= d_in:
		vis = (tau - d_in) / 2.0
	var heat := 0.0
	var gate := 0.0
	var bdt := tau - BREAK
	if broke:
		heat = 0.35 + 0.65 * exp(-bdt * 0.8)
		gate = clampf((d_out - tau) / 0.8, 0.0, 1.0)
	if prewarm:
		heat = maxf(heat, 0.5)
		gate = maxf(gate, 0.5)
	var crossed_break := _crossed(_last_t, t, dt0 + BREAK, dper)
	var crossed_in := _crossed(_last_t, t, dt0 + d_in, dper)
	for c in chunks:
		var node: Node3D = c["node"]
		var physical: bool = phys != null and node is RigidBody3D
		if physical:
			if crossed_break and not prewarm:
				phys.launch(node, Transform3D(Basis(), c["rest"]), (c["vel"] as Vector3) * 1.4, (c["axis"] as Vector3) * float(c["w"]) * 2.0)
			elif crossed_in or not broke:
				if not (node as RigidBody3D).freeze or crossed_in:
					(node as RigidBody3D).freeze = true
				node.global_transform = Transform3D(Basis(), c["rest"])
		elif broke:
			node.transform = Transform3D(Basis((c["axis"] as Vector3), float(c["w"]) * bdt), (c["rest"] as Vector3) + (c["vel"] as Vector3) * bdt)
		else:
			node.transform = Transform3D(Basis(), c["rest"])
		var mi: GeometryInstance3D = c["mesh"]
		mi.visible = vis > 0.01 or prewarm
		mi.transparency = 1.0 - vis if not prewarm else 0.5
		(c["edge"] as ShaderMaterial).set_shader_parameter("heat", heat * vis if not prewarm else heat)
		(c["fire"] as ShaderMaterial).set_shader_parameter("gate", gate * vis if not prewarm else gate)
	if flash != null:
		var fl := 0.0
		if tau >= 0.0 and tau < BREAK:
			fl = 1.2 * absf(sin(tau * 40.0)) * (tau / BREAK)
		elif tau >= BREAK:
			fl = 9.0 * exp(-bdt * 5.0) + 1.6 * exp(-bdt * 0.9)
		flash.visible = fl > 0.02 or prewarm
		flash.light_energy = fl * 4.5 * LIGHT_K
	# lights
	if rich:
		_assign_pool(_events(t, dx, gate), fade)
	else:
		for d in ships:
			var r := _ship_light(d, t)
			var l: OmniLight3D = d["light"]
			l.position = (r[0] as Vector3) + Vector3(dx, 0, 0)
			l.light_energy = float(r[1]) * fade * LIGHT_K
			l.light_color = r[2]
			l.visible = l.light_energy > 0.03 or prewarm
	# volumes
	if not vols.is_empty():
		var b_age := tau - BREAK if tau >= BREAK else -1.0
		var bp: Vector4 = vol_boom["P"]
		bp.x = b_age
		bp.y = 0.0 if b_age < 0.0 else minf(1.0, b_age / 0.15) * clampf((d_out - 0.5 - b_age) / 1.0, 0.0, 1.0)
		if prewarm:
			bp = Vector4(0.5, 1.0, 0.0, 0.16)
		vol_boom["P"] = bp
		(vol_boom["mesh"] as Node3D).visible = (b_age >= 0.0 and bp.y > 0.0) or prewarm
		for v in vols:
			if v.has("boom"):
				(v["mat"] as ShaderMaterial).set_shader_parameter("P", v["P"])
				continue
			var P: Vector4 = v["P"]
			if v.has("base"):
				(v["mesh"] as Node3D).position.x = (v["base"] as Vector3).x + dx
				(v["mat"] as ShaderMaterial).set_shader_parameter("dx", dx)
				P.y = fade
				# the smoke rings live 2 s after each broadside: the box is skipped the rest of the loop
				var ra := t - P.x
				(v["mesh"] as Node3D).visible = prewarm or (ra >= 0.0 and fposmod(ra, PER) < 2.4 and fade > 0.0)
			else:
				P.x = 0.6 * fade
				(v["mesh"] as Node3D).visible = prewarm or fade > 0.0
			v["P"] = P
			(v["mat"] as ShaderMaterial).set_shader_parameter("P", P)
	# physics debris events (max and board): hull hits throw chips, every breach sheds one, the destruction throws 40
	if phys != null:
		phys.now = t
		if _last_t >= 0.0 and t > _last_t and not prewarm:
			if crossed_break:
				for kk in 40:
					var dd := _rdir()
					phys.spawn(DC + dd * 2.0, dd * (4.0 + _rng.randf() * 14.0), 1, [0.2, 0.4, 0.9][kk % 3], 1.0)
			for d in ships:
				var i: int = d["i"]
				if d["shield"] == null and _crossed(_last_t, t, _stag_of(i) + 2.4, PER):
					var hn: Vector3 = d.get("hit_n", Vector3(0, 0, -1))
					phys.spawn((d["hit"] as Vector3) + Vector3(dx, 0, 0) + hn * 0.6, hn * 5.0 + Vector3(3, 0, 0), 8, 0.3, 4.0)
				if _crossed(_last_t, t, 0.1 + i * 0.11, 0.7):
					var bn: Vector3 = d["breach_n"]
					phys.spawn((d["breach"] as Vector3) + Vector3(dx, 0, 0) + bn * 0.8, bn * 3.5 + Vector3(3, 0, 0), 1, 0.2, 1.5)
	_last_t = t


func _crossed(t0: float, t1: float, start: float, per: float) -> bool:
	if t1 < start or t1 <= t0:
		return false
	var tk := start + floorf((t1 - start) / per) * per
	return tk > t0 and tk <= t1


func _assign_pool(ev: Array, fade: float) -> void:
	ev.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) > float(b[1]))
	for k in pool.size():
		var l: OmniLight3D = pool[k]
		if k < ev.size() and float(ev[k][1]) > 0.03:
			l.position = ev[k][0]
			l.light_energy = float(ev[k][1]) * fade * LIGHT_K
			l.light_color = ev[k][2]
			l.visible = true
		else:
			l.visible = prewarm
			l.light_energy = 0.0 if not prewarm else 1.0


# ---------------------------------------------------------------- interface used by main.gd

func show_everything(on: bool) -> void:
	prewarm = on
	for d in ships:
		for m in d["meshes"]:
			(m as GeometryInstance3D).transparency = 0.5 if on else 0.0
	if not on:
		_fade = -1.0
		_last_t = -1.0


func reset_triggers() -> void:
	_last_t = -1.0


func active_lights() -> int:
	var n := 0
	for l in _lights:
		var o := l as OmniLight3D
		if o.visible and o.light_energy > 0.05:
			n += 1
	return n


# presentation (max): screen shake scaled by weapon weight and distance, a pure function of t (as in the Babylon half)
func shake_offset(t: float, cp: Vector3) -> Vector3:
	var S := 0.0
	for i in mini(ships.size(), 24):
		var d: Dictionary = ships[i]
		var lt := t - _stag_of(i)
		if lt < 0.0:
			continue
		var tu := fmod(lt, PER)
		var w := 0.0
		for g in 4:
			var gt: float = tu - g * 0.08
			if gt >= 0.0 and gt < 0.25:
				w += 0.25 * (1.0 - gt / 0.25)
		if tu >= 1.5 and tu < 1.8:
			w += 0.5 * (1.0 - (tu - 1.5) / 0.3)
		if tu >= 2.4 and tu < 2.8:
			w += 0.6 * (1.0 - (tu - 2.4) / 0.4)
		if w > 0.0:
			var sp := Vector3((d["base"] as Vector3).x + _drift(t), 0, (d["base"] as Vector3).z)
			S += w / (1.0 + Vector3(sp.x - cp.x, cp.y, sp.z - cp.z).length() / 50.0)
	var tau := fmod(t - dt0, dper) if t >= dt0 else -1.0
	if tau >= BREAK and tau < BREAK + 1.2:
		var q := 1.0 - (tau - BREAK) / 1.2
		S += 2.5 * q * q / (1.0 + (DC - cp).length() / 50.0)
	var A := minf(S, 3.0) * 0.35
	return Vector3(A * (sin(t * 37.0) * 0.6 + sin(t * 61.0 + 1.0) * 0.4), A * (sin(t * 43.0 + 2.0) * 0.6 + sin(t * 71.0) * 0.4), A * sin(t * 53.0 + 3.0) * 0.5)


# max mode: a tiling detail normal layer on the hulls (StandardMaterial3D detail, triplanar, so the hi files' single UV
# atlas does not matter)
func _detail_normals(list: Array) -> void:
	var nt := NoiseTexture2D.new()
	nt.width = 512
	nt.height = 512
	nt.seamless = true
	nt.as_normal_map = true
	nt.bump_strength = 6.0
	var fn := FastNoiseLite.new()
	fn.frequency = 0.05
	fn.fractal_octaves = 4
	nt.noise = fn
	var wimg := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	wimg.fill(Color.WHITE)
	var white := ImageTexture.create_from_image(wimg)
	var done := {}
	for s in list:
		for m in s.get("meshes", []):
			var mesh: Mesh = (m as MeshInstance3D).mesh
			for si in mesh.get_surface_count():
				var mat := mesh.surface_get_material(si) as StandardMaterial3D
				if mat == null or done.has(mat):
					continue
				done[mat] = true
				mat.detail_enabled = true
				mat.detail_albedo = white
				mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
				mat.detail_normal = nt
				mat.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
				mat.uv2_triplanar = true
				mat.uv2_scale = Vector3(30, 30, 30)
	notes.append("max: detail normal layer on %d hull materials" % done.size())


# ---------------------------------------------------------------- shared with physics.gd

# Glowing specks on torn metal (the physics bodies): soft-edged spots from a 3D noise in the piece's own space.
const EMBER := """
float ember_h(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float ember_n(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(ember_h(i), ember_h(i + vec3(1.0, 0.0, 0.0)), f.x), mix(ember_h(i + vec3(0.0, 1.0, 0.0)), ember_h(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(ember_h(i + vec3(0.0, 0.0, 1.0)), ember_h(i + vec3(1.0, 0.0, 1.0)), f.x), mix(ember_h(i + vec3(0.0, 1.0, 1.0)), ember_h(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}
vec3 ember(vec3 pos, float warm) {
	float speck = smoothstep(0.6, 0.88, ember_n(pos * 6.0));
	return clamp(vec3(1.0, 0.34, 0.05) * speck * max(warm, 0.0) * 1.4, 0.0, 16.0);
}
"""


# An irregular convex shard (a random polygon, extruded thin); returns [mesh, corner points for a convex collider].
static func shard_mesh(rng: RandomNumberGenerator, size: float) -> Array:
	var n := rng.randi_range(5, 7)
	var ring_pts: Array = []
	var angs: Array = []
	for i in n:
		angs.append(TAU * (i + rng.randf_range(-0.3, 0.3)) / n)
	angs.sort()
	for a in angs:
		var r := size * rng.randf_range(0.35, 0.6)
		ring_pts.append(Vector2(cos(a) * r * 1.4, sin(a) * r))
	var th := size * rng.randf_range(0.08, 0.16)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := PackedVector3Array()
	for side in [1.0, -1.0]:
		var y: float = th * 0.5 * side
		for i in n:
			var a2: Vector2 = ring_pts[i]
			var b2: Vector2 = ring_pts[(i + 1) % n]
			var tri := [Vector3(0, y, 0), Vector3(a2.x, y, a2.y), Vector3(b2.x, y, b2.y)]
			if side < 0.0:
				tri = [tri[0], tri[2], tri[1]]
			for k in 3:
				st.add_vertex(tri[k])
		for v in ring_pts:
			pts.append(Vector3(v.x, y, v.y))
	for i in n:
		var a3: Vector2 = ring_pts[i]
		var b3: Vector2 = ring_pts[(i + 1) % n]
		var q := [Vector3(a3.x, th * 0.5, a3.y), Vector3(b3.x, th * 0.5, b3.y), Vector3(b3.x, -th * 0.5, b3.y), Vector3(a3.x, -th * 0.5, a3.y)]
		for tri in [[q[0], q[2], q[1]], [q[0], q[3], q[2]]]:
			for v in tri:
				st.add_vertex(v)
	st.generate_normals()
	return [st.commit(), pts]
