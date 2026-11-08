extends RefCounted
# One ship's effects: engines (hot cores, plumes and cooling exhaust left in world space), the shield
# bubble (faction colour and style, hits, breaks, regen), and the staged damage ladder per section (A5 sheets 5):
#   0 intact, 1 scorched, 2 smoking, 3 severe surface damage, 4 hull breach (5 wreck is fx_death.gd).
# Attached effects follow the hull; emitted engine trails stay in world space.

const SH := preload("res://fx/fx_shaders.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const HULL := preload("res://fx/fx_hull.gd")
const DEATH := preload("res://fx/fx_death.gd")
const BREACH := preload("res://fx/fx_breach.gd")

const TRAIL_PTS := 96
const TRAIL_LIFE := 2.6
const IDLE_GLOW := 0.3                    # engine glow of a parked ship, as a share of cruise (r12)

var id = ""
var root: Node3D
var meshes: Array = []
var faction = "voidsworn"
var fac: Dictionary
var weight = 2            # 0 craft, 1 light, 2 medium, 3 heavy, 4 capital
var squadron = false
var shielded = true
var flagship = false
var death_big = false     # R73: class, not draw scale, decides kill slow motion
var hull: HULL
var dead = false
var gone = false
var busy_until = -1.0
var engine_level = 1.0
var _eng_cur = 1.0
var _eng_node: MeshInstance3D = null
var _eng_mat: ShaderMaterial
var _eng_rib_mat: ShaderMaterial
var _eng_sputter = false
var _trails: Array = []    # per nozzle: {mi, hist: Array of [pos, t], seed, r}
var _last_pos = Vector3.INF
var _moving = 0.0
var _shield_mi: MeshInstance3D = null
var _shield_mat: ShaderMaterial = null
var _hit_i = 0
var _hits = PackedVector4Array()
var _hitw = PackedVector4Array()
var _shield_until = -1.0
var _last_sh = -1.0
var section_fraction := [1.0, 1.0, 1.0]
var stage = [0, 0, 0]     # eng, mid, prow
var _sec_nodes = [[], [], []]
var _sec_lights = [[], [], []]
var _burn_nodes: Array = []
var _scar_stage := [0, 0, 0]
var _patch_time := [-1.0, -1.0, -1.0]
var _damage_emitters: Array = []
var _fading_emitters: Array = []
var _squad_smoke := false
var _smoke_next := 0.0
var _emitter_key := ""
var _burning = false
var _dmg_root: Node3D
var _seed = 0
var _anchors = {}          # where each section's damage sits (stays put as the stage grows)
var _ents = [[], [], []]   # the hull damage entries (fx_breach.Ent) per section
var _orig: Array = []      # the hull's original surfaces, gathered at the first damage
var _dmg_task = -1
var _dmg_dirty = false
var _dmg_job: Dictionary = {}
var _hole_nodes: Array = []
var _hole_lights: Array = []
var _marks: Array = []     # weapon marks on the hull (fx_breach.Ent), oldest first, at most BREACH.MARK_CAP
var _mark_n = 0
var mark_ms: Array = []    # per rebuild: [entries, worker ms, apply ms] (the gallery and probes report it)
# hit reaction (R50): a damped angular kick (x roll, y yaw, z pitch, radians) that thrusters arrest, a small drift
# (ship frame) that thrusters stop, and a shudder; fx owns the root's roll and pitch (G2 never writes rotation.x or z),
# and adds yaw and drift only while G2 is not moving the ship (G2 writes position and yaw during a path)
var _ra := Vector3.ZERO
var _rv := Vector3.ZERO
var _pd := Vector3.ZERO
var _pv := Vector3.ZERO
var _shud := 0.0
var _shud_t := 0.0
var _app_pos := Vector3.ZERO
var _app_yaw := 0.0
var _reacting := false
var _rcs_next := 0.0
var _stutter_until := -1.0
var _ref_mi: MeshInstance3D = null
var _ref0 := Transform3D.IDENTITY


# How the hull has moved under the root since the ship was added (ShipView's bob and bank), in the root's frame.
func hull_motion() -> Transform3D:
	if _ref_mi == null or not is_instance_valid(_ref_mi) or not _ref_mi.is_inside_tree():
		return Transform3D.IDENTITY
	return (root.global_transform.affine_inverse() * _ref_mi.global_transform) * _ref0.affine_inverse()


# Hang a node in the hull's frame of add_ship time so it moves with the hull mesh (r18; see setup).
func _attach(n: Node3D) -> void:
	if _ref_mi != null and is_instance_valid(_ref_mi):
		_ref_mi.add_child(n)
		n.transform = _ref0.affine_inverse()
	else:
		root.add_child(n)


func setup(fx, sid: String, r: Node3D, info: Dictionary) -> void:
	id = sid
	root = r
	faction = String(info.get("faction", "voidsworn")).to_lower()
	fac = fx.faction_info(faction)
	squadron = bool(info.get("squadron", false)) or String(info.get("cls", "")) == "Squadron"
	shielded = bool(info.get("shielded", fac["shielded"])) and not squadron
	flagship = bool(info.get("flagship", false))
	death_big = flagship or String(info.get("cls", "")) in ["Cruiser", "Carrier", "Battleship", "Dreadnought", "Super-dreadnought", "Battle-barge", "Bio-titan", "Ark", "Tomb-ark"]
	var sz = float(info.get("size", 0.8))
	weight = 0 if squadron else (1 if sz < 0.65 else (2 if sz < 0.9 else (3 if sz < 1.1 else 4)))
	if flagship:
		weight = maxi(weight, 3)
	meshes = info.get("meshes", [])
	if meshes.is_empty():
		meshes = _find_meshes(root)
	_seed = hash(sid)
	hull = HULL.new()
	hull.stb_z = float(fx.starboard_z)
	hull.analyse(root, meshes, _seed)
	# ShipView bobs and banks the hull node under the root; the hull analysis above is in the pose of this moment, so
	# the damage (overlay skins, cavities, fires) follows the hull's motion from here (r6: the hull bobbed 0.25 units
	# up and down past a mark overlay lifted 0.026, so overlay-only marks such as ion burns kept vanishing into it).
	# r18: the damage and the engines hang under a hull mesh itself (with the inverse of its pose now), so they move
	# with the hull in the same frame, every frame; r6-r17 copied the hull's motion in fx's update, which lagged
	# whenever the hull moved between fx steps (the stills: overlays sank into the bobbing hull at random, which is
	# why marks came and went between runs)
	for m in meshes:
		if m is MeshInstance3D:
			_ref_mi = m
			break
	if _ref_mi != null:
		_ref0 = root.global_transform.affine_inverse() * _ref_mi.global_transform
	_dmg_root = Node3D.new()
	_dmg_root.name = "fx_damage"
	_attach(_dmg_root)
	_hide_placeholder_engines()
	# Detailed wings own one stern trail per moving craft. The hull analyser's
	# single formation-sized engine would put a giant plume between the craft.
	if not squadron or root.get("squad_kind") == null or str(root.get("squad_kind")).is_empty():
		_build_engines(fx)
		_build_trails(fx)
	if shielded:
		_build_shield(fx)
	_last_pos = root.global_position


# ShipView's placeholder engine glows (render/ship_view.gd sv.engines) sit at fixed spots behind the stern, not at the
# real nozzles; fx draws the engines, so they stay hidden while fx runs the ship (API.md 2; Ryan r12: glows and trails
# did not line up with the engines). Checked every frame because ShipView shows them again on revive.
func _hide_placeholder_engines() -> void:
	var es = root.get("engines")
	if es is Array:
		for e in es:
			if e is Node3D and (e as Node3D).visible:
				(e as Node3D).visible = false


func teardown(fx) -> void:
	wait_damage()
	BREACH.clear_nodes(self)
	for t in _trails:
		if is_instance_valid(t["mi"]):
			(t["mi"] as Node).queue_free()
	if is_instance_valid(_dmg_root):
		_dmg_root.queue_free()
	if is_instance_valid(_eng_node):
		_eng_node.queue_free()
	if is_instance_valid(_shield_mi):
		_shield_mi.queue_free()
	for sec in 3:
		_clear_lights(sec)
	for n in _burn_nodes:
		if n is Dictionary:
			n["on"] = false


static func _find_meshes(n: Node) -> Array:
	var out: Array = []
	var stack: Array = [n]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		if c is MeshInstance3D and not String(c.name).begins_with("fx_"):
			out.append(c)
		for ch in c.get_children():
			if not String(ch.name).begins_with("fx_"):
				stack.append(ch)
	return out


func xf() -> Transform3D:
	# the hull's own frame now: the root, plus ShipView's bob and bank since the ship was added
	return root.global_transform * hull_motion()


func to_world(p: Vector3) -> Vector3:
	return xf() * p


func dir_world(d: Vector3) -> Vector3:
	return (xf().basis * d).normalized()


func scale_k() -> float:
	return clampf(hull.L / 24.0, 0.25, 2.5)


# ---------------------------------------------------------------- engines

func _build_engines(fx) -> void:
	if is_instance_valid(_eng_node):
		_eng_node.queue_free()
	var b = POOLS.Batch.new()
	var rb = POOLS.Batch.new()
	var eng: Color = fac["engine"]
	var extra := String(fac.get("engine_extra", "none"))
	var corsair = extra == "soot" or _eng_sputter
	var q = POOLS.quad_shape()
	var rs = POOLS.ribbon_shape(14)
	for nz in hull.nozzles:
		var np: Vector3 = nz["p"]
		var r: float = nz["r"]
		var nd: Vector3 = nz.get("d", Vector3(-1, 0, 0))
		# velocities below are written for a plume along -X; turned onto this nozzle's own direction
		var rot := Basis(Quaternion(Vector3(-1, 0, 0), nd)) if nd.dot(Vector3(-1, 0, 0)) > -0.999 else Basis(Vector3.UP, PI)
		var plume = clampf(1.5 * hull.W, 2.0, 32.0)
		b.add(q, POOLS.pack(Vector4(np.x, np.y, np.z, -20.0), Vector4(0, 0, 0, 1.0), Vector4(eng.r, eng.g, eng.b, 2.0),
			Vector4(r * 2.8, r * 2.8, 11 if corsair else 4, fx.rng.randf()), Vector4(1.0, 0, 0, 0)))
		var acc = fac.get("accent")
		if acc is Color:
			# a corona round the core in the faction's second colour (faction look data, accent; none in use yet)
			b.add(q, POOLS.pack(Vector4(np.x, np.y, np.z, -20.0), Vector4(0, 0, 0, 1.0), Vector4(acc.r, acc.g, acc.b, 0.9),
				Vector4(r * 5.0, r * 5.0, 4, fx.rng.randf()), Vector4(1.0, 0, 0, 0)))
		rb.add(rs, POOLS.pack(Vector4(np.x, np.y, np.z, 3 if corsair else 0), Vector4(nd.x, nd.y, nd.z, plume), Vector4(eng.r, eng.g, eng.b, 0.9),
			Vector4(r * 1.3, r * 0.5, fx.rng.randf(), 0), Vector4(-20.0, 1.0, 1.0, 0)))
		if corsair:
			# soot coughs (the Corsair exception: haphazard, junky)
			for k in 9:
				var tk = -20.0 + k * 0.23 + (k % 3) * 0.05
				var v0 := rot * Vector3(-5 - fx.rng.randf() * 3, fx.rng.randf() - 0.3, fx.rng.randf() - 0.5)
				b.add(q, POOLS.pack(Vector4(np.x, np.y, np.z, tk), Vector4(v0.x, v0.y, v0.z, 1.8),
					Vector4(0.06, 0.05, 0.045, 0.55), Vector4(r * 1.2, r * 4.5, 8, fx.rng.randf()), Vector4(2.1, 0, 0.8, 0)))
		elif extra == "spores":
			for k in 4:
				var v1 := rot * Vector3(-3, fx.rng.randf() - 0.5, fx.rng.randf() - 0.5)
				b.add(q, POOLS.pack(Vector4(np.x, np.y, np.z, -20.0 + k * 0.6), Vector4(v1.x, v1.y, v1.z, 2.0),
					Vector4(eng.r * 0.4, eng.g * 0.4, eng.b * 0.3, 0.35), Vector4(r * 0.8, r * 3.0, 20, fx.rng.randf()), Vector4(2.4, 0, 0.6, 0)))
		elif extra == "embers":
			# embers in the faction's second colour when it has one (Eclipse: white-gold), else hot orange
			var ec: Color = acc if acc is Color else Color(1.0, 0.5, 0.15)
			for k in 3:
				var v2 := rot * Vector3(-6, fx.rng.randf() - 0.5, fx.rng.randf() - 0.5)
				b.add(q, POOLS.pack(Vector4(np.x, np.y, np.z, -20.0 + k * 1.3), Vector4(v2.x, v2.y, v2.z, 0.9),
					Vector4(ec.r, ec.g, ec.b, 2.2), Vector4(r * 0.2, r * 0.1, 19, fx.rng.randf()), Vector4(3.9, 0, 0.5, 0)))
	_eng_mat = fx.mat(SH.SPRITE, 1, "#define SOFT\n" if fx.quality != "low" else "")
	_eng_rib_mat = fx.mat(SH.RIBBON, 1)
	var holder = MeshInstance3D.new()
	holder.name = "fx_engines"
	_attach(holder)
	_eng_node = holder
	b.build(_eng_mat, holder, "fx_eng_cores")
	rb.build(_eng_rib_mat, holder, "fx_eng_plumes")


func _build_trails(fx) -> void:
	for nz in hull.nozzles:
		var mi = MeshInstance3D.new()
		mi.name = "fx_trail_%s" % id
		mi.top_level = true
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.material_override = fx.mat(SH.TRAIL, 1)
		mi.extra_cull_margin = 16384.0
		fx.add_child(mi)
		mi.global_transform = Transform3D.IDENTITY
		_trails.append({"mi": mi, "hist": [], "seed": fx.rng.randf(), "r": nz["r"], "p": nz["p"], "d": nz.get("d", Vector3(-1, 0, 0))})


func update(fx, dt: float) -> void:
	if gone or not is_instance_valid(root):
		return
	_update_damage_emitters(fx)
	_react_step(fx, dt)
	_hide_placeholder_engines()
	var hm := hull_motion()
	if _shield_mi != null and _shield_mi.visible:
		_shield_mi.transform = hm * Transform3D(Basis.from_scale(hull.shield_radii()), hull.c)
	var pos = root.global_position - root.get_parent_node_3d().global_transform.basis * _app_pos if root.get_parent_node_3d() != null else root.global_position
	var moved = pos.distance_to(_last_pos) if _last_pos != Vector3.INF else 0.0
	_last_pos = pos
	_moving = maxf(_moving - dt, 0.0)
	if moved > 1e-4:
		_moving = 0.4
	# the drive glows full only while the ship thrusts (moving, or a burn G2 asks for with set_engine above cruise); a
	# parked ship keeps a dim pilot glow and a short, faint trail (Ryan, r12: engines glowed and trailed at rest)
	var want = 0.0 if dead else ((engine_level if absf(engine_level - 1.0) > 0.05 else 1.6) if _moving > 0.0 else (engine_level if engine_level > 1.05 else IDLE_GLOW * engine_level))
	# rise gently, drop fast: a burn's plume cuts off within about 0.1 s instead of fading over half a second (G2)
	_eng_cur = lerpf(_eng_cur, want, clampf(dt * (4.0 if want > _eng_cur else 14.0), 0.0, 1.0))
	if _eng_mat != null:
		var g := clampf(_eng_cur, 0.0, 2.0)
		if fx.now < _stutter_until:
			# a heavy hit makes the drive stumble: the plume gutters and catches again
			var flick := 1.0 if fposmod(sin(fx.now * 37.0 + float(_seed)) * 43758.5, 1.0) > 0.45 else 0.0
			g *= 0.3 + 0.7 * maxf(flick, smoothstep(_stutter_until - 0.25, _stutter_until, fx.now))
		_eng_mat.set_shader_parameter("gate", g)
		_eng_rib_mat.set_shader_parameter("gate", g)
		_eng_rib_mat.set_shader_parameter("lenk", clampf(0.5 + 0.5 * _eng_cur, 0.0, 1.8))
	_update_trails(fx, moved > 1e-4)
	if _shield_mi != null:
		_shield_mi.visible = fx.now < _shield_until


func _update_trails(fx, moved: bool) -> void:
	var xfm = xf()
	var eng: Color = fac["engine"]
	var lvl = clampf(_eng_cur, 0.0, 2.0)
	for t in _trails:
		var hist: Array = t["hist"]
		var plume = clampf(1.5 * hull.W, 2.0, 32.0)
		var start: Vector3 = xfm * (t["p"] as Vector3) + (xfm.basis * (t["d"] as Vector3)).normalized() * (0.3 * plume)
		# Each sample belongs to world space for its entire life. Turning, stopping
		# or throttling down never drags old exhaust along with the nozzle.
		if not dead and lvl > 0.12:
			if hist.is_empty() or ((hist[0][0] as Vector3).distance_to(start) > 0.03 * fx.unit and (fx.now - float(hist[0][1]) >= 0.05 or (hist[0][0] as Vector3).distance_to(start) > 1.2 * fx.unit)):
				hist.push_front([start, fx.now, lvl])
		while not hist.is_empty() and (hist.size() > TRAIL_PTS or fx.now - float(hist.back()[1]) >= TRAIL_LIFE):
			hist.pop_back()
		_trail_mesh(fx, t, eng)


func _trail_mesh(fx, t: Dictionary, eng: Color) -> void:
	var hist: Array = t["hist"]
	var mi: MeshInstance3D = t["mi"]
	mi.visible = hist.size() >= 2
	if not mi.visible:
		return
	var pts := PackedVector3Array()
	for h in hist:
		pts.append(h[0])
	var n = pts.size()
	var verts = PackedVector3Array()
	var nrm = PackedVector3Array()
	var uv = PackedVector2Array()
	var c0 = PackedFloat32Array()
	var c1 = PackedFloat32Array()
	var idx = PackedInt32Array()
	var r: float = t["r"]
	var style: int = 1 if (String(fac.get("engine_extra", "")) == "soot" or _eng_sputter) else int(fac["trail"])
	var w0 = r * 1.1
	var w1 = r * 2.4 * clampf(scale_k(), 0.6, 1.6)
	for i in n:
		var d = (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		for sd in [-0.5, 0.5]:
			verts.append(pts[i])
			nrm.append(d)
			uv.append(Vector2(clampf((fx.now - float(hist[i][1])) / TRAIL_LIFE, 0.0, 1.0), sd))
			c0.append_array([eng.r, eng.g, eng.b, 0.28 * clampf(float(hist[i][2]), 0.0, 1.5)])
			c1.append_array([w0, w1, float(t["seed"]), float(style)])
	for i in n - 1:
		var q = i * 2
		idx.append_array(PackedInt32Array([q, q + 1, q + 3, q, q + 3, q + 2]))
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = nrm
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_CUSTOM0] = c0
	arr[Mesh.ARRAY_CUSTOM1] = c1
	arr[Mesh.ARRAY_INDEX] = idx
	var fl = (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) | (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT)
	var am: ArrayMesh = (t["mi"] as MeshInstance3D).mesh
	if am == null:
		am = ArrayMesh.new()
		(t["mi"] as MeshInstance3D).mesh = am
	am.clear_surfaces()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, fl)
	am.custom_aabb = POOLS.BIG


# ---------------------------------------------------------------- shields

func _build_shield(fx) -> void:
	var sph = SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = 64
	sph.rings = 32
	_shield_mat = fx.mat(SH.SHIELD, 2)
	var sc: Color = fac["shield"]
	_shield_mat.set_shader_parameter("col", Vector3(sc.r, sc.g, sc.b) * 2.2)
	_shield_mat.set_shader_parameter("rad", hull.shield_radii())
	_shield_mat.set_shader_parameter("style", int(fac["shield_style"]))
	var se = fac.get("shield_edge")
	if se is Color:
		_shield_mat.set_shader_parameter("edge_mode", 1)
		_shield_mat.set_shader_parameter("edge_col", Vector3(se.r, se.g, se.b))
	elif se is String and se == "rainbow":
		_shield_mat.set_shader_parameter("edge_mode", 2)
	var hits = PackedVector4Array()
	var hw = PackedVector4Array()
	for i in 6:
		hits.append(Vector4(0, 0, 0, -100))
		hw.append(Vector4(0, 1, 1, 0))
	_hits = hits
	_hitw = hw
	_shield_mat.set_shader_parameter("hits", hits)
	_shield_mat.set_shader_parameter("hitw", hw)
	_shield_mi = MeshInstance3D.new()
	_shield_mi.name = "fx_shield"
	_shield_mi.mesh = sph
	_shield_mi.material_override = _shield_mat
	_shield_mi.position = hull.c
	_shield_mi.scale = hull.shield_radii()
	_shield_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shield_mi.visible = false
	root.add_child(_shield_mi)


# Where a shot from `from_world` meets the bubble (world point and outward normal).
func shield_point(from_world: Vector3, aim_local := Vector3.INF) -> Dictionary:
	var inv = xf().affine_inverse()
	var rad = hull.shield_radii()
	var o = (inv * from_world) - hull.c
	var tgt = (aim_local - hull.c) if aim_local != Vector3.INF else Vector3.ZERO
	var d = (tgt - o).normalized()
	# ray against the unit sphere in scaled space
	var os = o / rad
	var ds = (d / rad)
	var a = ds.dot(ds)
	var b = 2.0 * os.dot(ds)
	var cc = os.dot(os) - 1.0
	var disc = b * b - 4.0 * a * cc
	var lp: Vector3
	if disc < 0.0:
		lp = (-d) * rad
	else:
		var tt = (-b - sqrt(disc)) / (2.0 * a)
		lp = o + d * tt
	var n = (lp / (rad * rad)).normalized()
	return {"p": xf() * (lp + hull.c), "n": (xf().basis * n).normalized(), "local": lp}


func shield_hit(fx, local_p: Vector3, T: float, strength: float, spread: float, life := 0.6) -> void:
	if _shield_mat == null:
		return
	_hits[_hit_i] = Vector4(local_p.x, local_p.y, local_p.z, T)
	_hitw[_hit_i] = Vector4(strength, life, spread * fx.unit, 0)
	_hit_i = (_hit_i + 1) % 6
	_shield_mat.set_shader_parameter("hits", _hits)
	_shield_mat.set_shader_parameter("hitw", _hitw)
	_shield_until = maxf(_shield_until, T + life + 0.05)


func shield_break(fx, quad: int) -> void:
	if _shield_mat == null:
		return
	var qd: Vector3 = hull.quad_dir(quad)
	var T: float = fx.now
	_shield_mat.set_shader_parameter("brk_t", T)
	_shield_mat.set_shader_parameter("brk_dir", qd)
	_shield_until = maxf(_shield_until, T + 1.45)
	var rad = hull.shield_radii()
	var lp = qd * rad
	var wp = to_world(lp + hull.c)
	var wn = dir_world(qd)
	var sc: Color = fac["shield"]
	var st: int = fac["shield_style"]
	var k = scale_k()
	fx.pop(wp, T, sc.lerp(Color.WHITE, 0.4), 9.0 * k, 8.0, wn, 0.2)
	fx.light(wp + wn * 2.0, T, 0.6, 7.0, sc, 0)
	fx.shake(T, 0.18, wp)
	match st:
		0:
			# Voidsworn: the gold veil tears with crackling arcs running over the surface
			for i in 40:
				var tang = fx.rcone(wn, 1.4)
				fx.stk(wp + fx.rdir() * 3.0 * k, T + fx.rng.randf() * 0.4, 0.3 + fx.rng.randf() * 0.4, sc.lerp(Color(1, 0.9, 0.6), 0.5), 6.0,
					0.08, 0.14, 1, tang * (8 + fx.rng.randf() * 16) * k, 1.8)
			for i in 24:
				fx.spr(wp + fx.rdir() * 4.0 * k, T + fx.rng.randf() * 0.5, 0.9 + fx.rng.randf() * 0.6, sc, 2.0, 0.25 * k, 0.1 * k, 19, fx.rcone(wn, 1.0) * 3.0 * k, 0.5)
			fx.ring(wp, wn, T, 0.9, sc, 1.0, 2.0 * k, 16.0 * k, 1)
		1:
			# Hegemony: the hex lattice shatters into cells that fly apart
			fx.ring(wp, wn, T, 0.8, sc.lerp(Color.WHITE, 0.3), 1.4, 2.0 * k, 18.0 * k, 3)
			for i in 36:
				fx.spr(wp + fx.rdir() * 5.0 * k, T + fx.rng.randf() * 0.15, 0.6 + fx.rng.randf() * 0.5, sc, 3.0, 0.5 * k, 0.3 * k, 16,
					fx.rcone(wn, 0.9) * (6 + fx.rng.randf() * 10) * k, 0.8)
			fx.ring(wp, wn, T + 0.03, 0.7, sc, 0.8, 1.0 * k, 12.0 * k, 3)
		2:
			# Corsair: it sputters, flickers and dies in patches, with sparks and a dirty puff
			for j in 5:
				var tj = T + j * 0.12 + fx.rng.randf() * 0.05
				var pj = wp + fx.rdir() * 4.0 * k
				fx.pop(pj, tj, sc.lerp(Color(1, 0.6, 0.3), 0.4), 3.0 * k, 4.0, wn, 0.1)
				for i in 8:
					fx.stk(pj, tj, 0.3 + fx.rng.randf() * 0.3, Color(1, 0.6, 0.25), 6.0, 0.05, 0.12, 1, fx.rcone(wn, 1.0) * (8 + fx.rng.randf() * 12) * k, 2.0)
			for i in 4:
				fx.spr(wp + fx.rdir() * 3.0 * k, T + 0.1 + i * 0.1, 2.0, Color(0.1, 0.08, 0.07), 0.5, 2.0 * k, 7.0 * k, 3, fx.rcone(wn, 0.6) * 2.0, 0.6)
		_:
			# Ithar: the mint veil folds and sheets away in prismatic glints
			for i in 30:
				fx.spr(wp + fx.rdir() * 5.0 * k, T + fx.rng.randf() * 0.5, 1.2 + fx.rng.randf() * 0.8, sc, 2.2, 0.7 * k, 0.2 * k, 16,
					fx.rcone(wn, 1.2) * (2 + fx.rng.randf() * 4) * k, 0.4, 1.5)
			fx.ring(wp, wn, T, 1.0, sc, 1.0, 2.0 * k, 20.0 * k, 3)
			fx.spr(wp, T, 1.0, sc, 1.6, 6.0 * k, 14.0 * k, 18)


func _regen(fx) -> void:
	if _shield_mat == null:
		return
	_shield_mat.set_shader_parameter("regen_t", fx.now)
	_shield_until = maxf(_shield_until, fx.now + 1.05)


# ---------------------------------------------------------------- hit reaction (R50)

# How much a ship of this weight resists a shove (craft, light, medium, heavy, capital): capital ships barely move.
const REACT_MASS := [0.6, 1.0, 2.2, 5.0, 12.0]
# The weighty reaction (r4 review; Ryan: no cartoon push back). A hit does not spring the ship out and back. It plays in
# three beats, all slower for heavier hulls:
#   1. onset: the kick builds over a few frames (a frigate jolts, a capital hull's mass soaks it up over a sixth of a
#      second) while a shudder runs through the structure (lower and longer in big hulls);
#   2. arrest: after a short delay the attitude thrusters fire and brake the spin and the slide at a steady rate (a
#      visible burn, not an exponential ease): REACT_ARREST seconds for the biggest hit of the moment;
#   3. recovery: once stopped, the helm brings the ship back level and onto its hex, slowly and without overshoot
#      (critically damped at REACT_RECOVER rad/s).
const REACT_ONSET := [0.03, 0.05, 0.08, 0.12, 0.16]
const REACT_ARREST := [0.35, 0.5, 0.7, 0.95, 1.2]
const REACT_RECOVER := [3.6, 3.0, 2.4, 1.9, 1.5]
const REACT_SHUDDER_HZ := [11.0, 9.0, 7.0, 5.0, 4.0]
const REACT_SHUDDER_T := [0.16, 0.2, 0.28, 0.38, 0.5]
var _kick_v := Vector3.ZERO     # angular kick still to be delivered (onset)
var _kick_p := Vector3.ZERO     # drift kick still to be delivered
var _brk := Vector3.ZERO        # thrusters' braking rate per axis (rad/s2)
var _brk_p := 0.0               # ... and for the slide (units/s2)
var _brk_at := 0.0              # when the thrusters start braking


# A hit's physical reaction. impulse: the weapon's momentum (fx_weapons.REACT_IMPULSE: torpedoes and rams shove,
# shells and slugs kick, lances and ions barely at all); lp, ldir: hit point and shot direction in the ship frame.
func hit_react(fx, impulse: float, lp: Vector3, ldir: Vector3) -> void:
	if dead or gone or impulse <= 0.0:
		return
	var wi := clampi(weight, 0, 4)
	var m: float = REACT_MASS[wi]
	var L: float = maxf(hull.L, 1.0)
	var d := ldir.normalized()
	var r: Vector3 = (lp - hull.c) / L
	# the angular kick: torque from where the hit lands, about the ship's own axes (x roll, y yaw, z pitch)
	# lever arms never vanish: a hull is not a point, and a hit near the middle still rocks it a little
	var hh: float = maxf(hull.H / L, 0.05) * 0.5
	r.y = signf(r.y if absf(r.y) > 1e-4 else 1.0) * maxf(absf(r.y), hh * 0.6)
	r.x = signf(r.x if absf(r.x) > 1e-4 else 1.0) * maxf(absf(r.x), 0.08)
	var tq := r.cross(d)
	# turning inertia grows faster than mass (a long hull resists spin more than it resists a shove)
	var dv := Vector3(tq.x * 2.4, tq.y * 0.8, tq.z * 1.2) * impulse * 0.25 / pow(m, 1.25)
	var dp := d * impulse * L * 0.0095 / m
	_kick_v += dv
	_kick_p += dp
	# the thrusters brake whatever the ship will be doing once the kick is in, over REACT_ARREST seconds
	var t_ar: float = REACT_ARREST[wi]
	var v_after := _rv + _kick_v
	_brk = Vector3(maxf(_brk.x, absf(v_after.x) / t_ar), maxf(_brk.y, absf(v_after.y) / t_ar), maxf(_brk.z, absf(v_after.z) / t_ar))
	_brk_p = maxf(_brk_p, (_pv + _kick_p).length() / (t_ar * 1.3))
	_brk_at = fx.now + REACT_ONSET[wi] + 0.05
	# the shudder: a damped structural vibration (bigger hulls ring lower and longer, and show it more than they move)
	_shud = maxf(_shud * exp(-(fx.now - _shud_t) / REACT_SHUDDER_T[wi]), minf(impulse / sqrt(m), 4.0) * 0.0025)
	_shud_t = fx.now
	if impulse >= 2.5:
		_stutter_until = maxf(_stutter_until, fx.now + 0.8)
	_reacting = true


static func _brake(v: float, b: float, h: float) -> float:
	if absf(v) <= b * h:
		return 0.0
	return v - signf(v) * b * h


func _react_step(fx, dt: float) -> void:
	if not _reacting:
		return
	var wi := clampi(weight, 0, 4)
	var h := minf(dt, 1.0 / 30.0)
	# 1. onset: deliver the kick over REACT_ONSET (about 95% of it inside that time)
	var f := 1.0 - exp(-h * 3.0 / float(REACT_ONSET[wi]))
	_rv += _kick_v * f
	_kick_v *= 1.0 - f
	_pv += _kick_p * f
	_kick_p *= 1.0 - f
	var wr: float = REACT_RECOVER[wi]
	if fx.now >= _brk_at:
		# 2. arrest: a steady thruster burn against the spin and the slide, per axis
		var ax := [0, 1, 2]
		for k in ax:
			if _brk[k] > 0.0:
				_rv[k] = _brake(_rv[k], _brk[k], h)
				if _rv[k] == 0.0 and _kick_v.length() < 1e-4:
					_brk[k] = 0.0
			else:
				# 3. recovery: back to level, critically damped (no overshoot, no bounce)
				_rv[k] += (-_ra[k] * wr * wr - _rv[k] * 2.0 * wr) * h
		if _brk_p > 0.0:
			var sp := _pv.length()
			if sp <= _brk_p * h:
				_pv = Vector3.ZERO
				if _kick_p.length() < 1e-4:
					_brk_p = 0.0
			else:
				_pv -= _pv / sp * _brk_p * h
		else:
			var wp := wr
			_pv += (-_pd * wp * wp - _pv * 2.0 * wp) * h
	_ra += _rv * h
	_pd += _pv * h
	var age: float = fx.now - _shud_t
	var sh := _shud * exp(-age / float(REACT_SHUDDER_T[wi]))
	var w_sh: float = TAU * float(REACT_SHUDDER_HZ[wi])
	var shx := sh * sin(age * w_sh + 1.3)
	var shz := sh * 0.7 * sin(age * w_sh * 1.27)
	_rcs(fx)
	var busy: bool = root.has_method("busy") and bool(root.call("busy"))
	# Keep the cinematic flight bank under the damage reaction.
	var flight_bank := float(root.get("glide_bank")) if root.get("glide_bank") != null else 0.0
	root.rotation.x = flight_bank + _ra.x + shx
	root.rotation.z = _ra.z + shz
	# yaw and drift: only while G2 is not driving the root (it sets position and yaw itself during a path)
	if busy:
		_app_pos = Vector3.ZERO
		_app_yaw = 0.0
	else:
		var want_pos: Vector3 = Basis(Vector3.UP, root.rotation.y) * _pd
		root.position += want_pos - _app_pos
		_app_pos = want_pos
		root.rotation.y += _ra.y - _app_yaw
		_app_yaw = _ra.y
	var idle: bool = _kick_v.length() < 1e-4 and _kick_p.length() < hull.L * 1e-5 and _brk == Vector3.ZERO and _brk_p == 0.0
	if idle and _ra.length() < 6e-4 and _rv.length() < 1e-3 and _pd.length() < hull.L * 3e-4 and _pv.length() < hull.L * 3e-4 and sh < 1e-4:
		root.rotation.x = flight_bank
		root.rotation.z = 0.0
		if not busy:
			root.position -= _app_pos
			root.rotation.y -= _app_yaw
		_app_pos = Vector3.ZERO
		_app_yaw = 0.0
		_ra = Vector3.ZERO
		_rv = Vector3.ZERO
		_pd = Vector3.ZERO
		_pv = Vector3.ZERO
		_shud = 0.0
		_reacting = false


# Attitude thrusters visibly fighting the spin and the drift: short gas puffs at the hull's corners, picked so their
# thrust opposes the motion, while the ship is still turning or sliding noticeably.
func _rcs(fx) -> void:
	if squadron or fx.now < _rcs_next:
		return
	var spin := _rv.length()
	var slide := _pv.length() / maxf(hull.L, 1.0)
	# while the thrusters brake (beat 2) they burn steadily; in the slow recovery only now and then
	var braking: bool = fx.now >= _brk_at and (_brk != Vector3.ZERO or _brk_p > 0.0)
	if not braking and spin < 0.01 and slide < 0.004:
		return
	if braking and spin < 0.002 and slide < 0.0008:
		return
	_rcs_next = fx.now + (0.05 if braking else 0.12)
	var L: float = hull.L
	var W: float = hull.W
	var H: float = hull.H
	var best: Array = []
	for sx in [-0.32, 0.32]:
		for sy in [-0.45, 0.45]:
			for sz in [-0.5, 0.5]:
				var rp: Vector3 = hull.c + Vector3(sx * L, sy * H, sz * W)
				for t in [Vector3(0, -signf(sy), 0), Vector3(0, 0, -signf(sz))]:
					# thrust t at rp: torque (rp - c) x t must oppose the spin; force t must oppose the drift
					var score: float = ((rp - hull.c) / L).cross(t).dot(_rv) * 4.0 + t.dot(_pv) / L * 40.0
					best.append([score, rp, t])
	best.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var k := scale_k()
	for j in 2:
		if float(best[j][0]) >= 0.0:
			break
		var rp: Vector3 = best[j][1]
		var t: Vector3 = best[j][2]
		var wp: Vector3 = to_world(rp)
		var gv: Vector3 = dir_world(-t) * (5.0 + fx.rng.randf() * 3.0) * k
		fx.spr(wp, fx.now, 0.35, Color(0.85, 0.88, 0.95), 0.6, 0.12 * k, 0.9 * k, 7, gv, 2.5)
		fx.spr(wp, fx.now, 0.06, Color(0.9, 0.95, 1.0), 1.5, 0.08 * k, 0.15 * k, 18)


# ---------------------------------------------------------------- staged damage (API.md 2)

func sync(fx, u: Dictionary) -> void:
	if dead or gone:
		return
	# view() sends null for fields a unit does not have (sec and sh for squadrons): treat them as absent
	var sec: Dictionary = u["sec"] if u.get("sec") is Dictionary else {}
	var maxhp = maxf(float(u["maxHp"]) if u.get("maxHp") != null else 1.0, 1.0)
	var hpf = (float(u["hp"]) if u.get("hp") != null else maxhp) / maxhp
	var want = [0, 0, 0]
	var names = ["eng", "mid", "prow"]
	for i in 3:
		var f = hpf
		var broken = false
		if sec.has(names[i]):
			var s = sec[names[i]]
			if s is Dictionary:
				f = float(s.get("hp", 1.0) if s.get("hp") != null else 1.0) / maxf(float(s.get("max", 1.0) if s.get("max") != null else 1.0), 1.0)
				broken = s.get("broken") == true
		var st = 0 if f > 0.8 else (1 if f > 0.6 else (2 if f > 0.4 else (3 if f > 0.2 else 4)))
		if broken:
			st = 4
		section_fraction[i] = clampf(f, 0.0, 1.0)
		want[i] = st
	_regrade_marks(fx)
	if squadron:
		want = [0, 0, 0]
		_squad_smoke = hpf < 0.5 and not fx.compat
	if fx.now < busy_until:
		var w = want.duplicate()
		fx.later(busy_until + 0.05, func l_stages() -> void: _apply_stages(fx, w))
	else:
		_apply_stages(fx, want)
	# shields: a rise means regen
	var shs = 0.0
	var sh_list = u.get("sh")
	if sh_list is Array:
		for v in sh_list:
			shs += float(v) if v != null else 0.0
	if _last_sh >= 0.0 and shs > _last_sh + 0.5:
		_regen(fx)
	_last_sh = shs
	var burn = u.get("burning") == true
	if burn != _burning:
		_burning = burn
		_set_burning(fx, burn)


func set_stages(fx, st: Array) -> void:
	_apply_stages(fx, [0, 0, 0] if squadron else st)


func _apply_stages(fx, want: Array) -> void:
	if dead or gone:
		return
	for i in 3:
		if int(want[i]) != int(stage[i]):
			var up: bool = int(want[i]) > int(stage[i])
			if int(stage[i]) == 4 and int(want[i]) < 4:
				_patch_time[i] = fx.now
			_scar_stage[i] = maxi(_scar_stage[i], stage[i])
			stage[i] = int(want[i])
			_build_section(fx, i, up)

	_refresh_damage_emitters(fx)
	var sp: bool = int(stage[0]) >= 3
	if sp != _eng_sputter:
		_eng_sputter = sp
		_build_engines(fx)


func _clear_section(i: int) -> void:
	for n in _sec_nodes[i]:
		if is_instance_valid(n):
			(n as Node).queue_free()
	_sec_nodes[i] = []
	_clear_lights(i)


func _clear_lights(i: int) -> void:
	for s in _sec_lights[i]:
		s["on"] = false
	_sec_lights[i] = []


# Where a section's damage sits: "a" the main hole, "d" a buckled panel, "b" a bite out of an upper edge (so the
# silhouette changes). Picked once, so a dent becomes a hole becomes a breach in the same place.
func _anchor(i: int, kind: String) -> Dictionary:
	var key = "%s%d" % [kind, i]
	if not _anchors.has(key):
		var h: Dictionary = hull.random_sample(i, 2.5)
		if kind == "b":
			for t in 32:
				var c: Dictionary = hull.random_sample(i, 0.0)
				var ny = (c["n"] as Vector3).y
				if ny > 0.15 and ny < 0.75:
					h = c
					break
		_anchors[key] = {"p": h["p"], "n": h["n"], "t": {}}
	return _anchors[key]


func _t0(a: Dictionary, st: int, fx) -> float:
	if not (a["t"] as Dictionary).has(st):
		a["t"][st] = fx.now
	return float(a["t"][st])


# Homeworld / Armada grading: surface burns through stage 3, an open break only at stage 4.
func _plan(fx, i: int, st: int) -> Array:
	var out: Array = []
	if squadron or weight <= 0:
		return out
	var scar: int = _scar_stage[i]
	var grade := maxi(st, mini(scar, 3))
	if grade == 0: return out
	var L: float = hull.L
	var sd = float(posmod(_seed, 1000)) * 0.01 + i * 3.7
	var a = _anchor(i, "a")
	var sc = BREACH.surface(a.p, a.n, L * (0.03 + 0.034 * grade), sd + 0.7, BREACH.S_SCORCH)
	sc.t0 = _t0(a, -grade, fx)
	sc.sec = i
	sc.heat = [0.0, 0.22, 0.35, 0.55, 0.75][grade] * (0.45 if st < scar else 1.0)
	out.append(sc)
	# Stable samples: increasing a stage never moves the earlier secondary burns.
	for j in mini(grade, 3):
		var h := _anchor(i, "sc%d" % j)
		var s2 = BREACH.surface(h.p, h.n, L * 0.024, sd + 5.0 + j, BREACH.S_SCORCH)
		s2.t0 = sc.t0
		s2.sec = i
		s2.heat = sc.heat * 0.6
		out.append(s2)
	if not fx.compat and grade >= 2 and st < 4 and not (scar == 4 and st < 4):
		var R: float = L * (0.05 if grade == 2 else 0.06)
		var e = BREACH.crater(a.p, a.n, R, R * (0.22 if grade == 2 else 0.35), sd, BREACH.S_DENT)
		if faction == "chorus": e.depth *= 0.65
		e.sec = i
		e.t0 = sc.t0
		out.append(e)
		if grade >= 3:
			var slot = BREACH.slot(hull, a.p, a.n, e.t1, L * 0.009, R * 0.75, sd + 2.3)
			slot.style = BREACH.S_FISSURE
			slot.sec = i
			slot.t0 = sc.t0
			out.append(slot)
	if scar == 4 and st < 4:
		var patch = BREACH.surface(a.p, a.n, L * 0.07, sd, BREACH.S_PATCH)
		patch.t0 = _patch_time[i]
		patch.sec = i
		patch.heat = 0.0
		out.append(patch)
	if st < 4 or fx.compat: return out
	var e = BREACH.hole(hull, a.p, a.n, L * 0.032, 1.0, 0.14, sd)
	e.t0 = _t0(a, st, fx)
	e.sec = i
	if faction == "chorus":
		e.bend = 0.35; e.w = e.R * 0.22; e.buckle = 0.035
	out.append(e)
	if weight >= 2:
		var bt = _anchor(i, "b")
		var eb = BREACH.hole(hull, bt.p, bt.n, L * 0.032, 1.0, 0.12, sd + 2.1)
		eb.t0 = _t0(bt, st, fx)
		eb.sec = i
		out.append(eb)
	return out


# Rebuild the hull from its original arrays with every section's damage, on a worker thread; apply when done.
func _dmg_request(fx) -> void:
	if _dmg_task >= 0:
		_dmg_dirty = true
		return
	var ents: Array = []
	for i in 3:
		ents.append_array(_ents[i])
	for e in _marks:
		var cap: int = [2, 2, 3, 4, 4][stage[e.sec]]
		var used := 0
		for x in ents:
			if x.look != "" and x.sec == e.sec: used += 1
		if used < cap or _scar_stage[e.sec] > stage[e.sec]: ents.append(e)
	if fx.compat:
		var flat: Array = []
		for e in ents:
			var copy = BREACH.surface(e.c, e.n, maxf(e.R, e.halo), e.seed_v, e.style)
			copy.t0 = e.t0; copy.sec = e.sec; copy.heat = e.heat
			copy.dir = e.dir; copy.hl = e.hl
			flat.append(copy)
		ents = flat
	if ents.is_empty() and _orig.is_empty():
		return
	if _orig.is_empty():
		var t_g := Time.get_ticks_usec()
		_orig = BREACH.gather(self)
		fx.pend("hull_gather", t_g)
		if _orig.is_empty():
			return
	var job = {"surfs": _orig, "ents": ents, "q": hull.L * 2e-4, "cell": hull.L / 16.0, "ovl": hull.L * 0.0006, "out": {}, "hull": hull,
		"organic": faction == "chorus", "wound_kind": int(fac.get("wound_kind", 0)), "flat": fx.compat, "mesh_on_worker": DisplayServer.get_name() != "headless"}
	_dmg_job = job
	_dmg_task = WorkerThreadPool.add_task(func() -> void: job["out"] = BREACH.compute(job))
	fx.later(fx.now + 0.02, func l_dmg_poll() -> void: _dmg_poll(fx))


func _dmg_poll(fx) -> void:
	if _dmg_task < 0:
		return
	if not WorkerThreadPool.is_task_completed(_dmg_task):
		fx.later(fx.now + 0.02, func l_dmg_poll() -> void: _dmg_poll(fx))
		return
	flush_damage(fx)


# Finish a pending hull rebuild now (waits for the worker): the gallery calls it before a still, so the still shows the
# damage the moment says.
func flush_damage(fx) -> void:
	if _dmg_task < 0:
		return
	WorkerThreadPool.wait_for_task_completion(_dmg_task)
	_dmg_task = -1
	if dead or gone:
		return
	var t_ap := Time.get_ticks_usec()
	BREACH.apply(fx, self, _dmg_job)
	fx.pend("breach_apply", t_ap)
	mark_ms.append([(_dmg_job["ents"] as Array).size(), int(_dmg_job.get("out", {}).get("ms", -1)), (Time.get_ticks_usec() - t_ap) / 1000.0])
	# the death pieces are cut from the hull as it is now, holes and all. r18 (20-ship bench: 1% lows of 15 fps and a
	# 4 s stall): at most one fresh cut every CUT_REFRESH seconds per ship, not one per hit (each cut is seconds of
	# worker time on a big hull and its pieces' meshes are uploaded on the main thread); the last finished cut is kept
	# so a death never waits for a cut still running
	_cut_stale = true
	_cut_refresh(fx)
	if _dmg_dirty:
		_dmg_dirty = false
		_dmg_request(fx)


const CUT_REFRESH := 6.0
var _cut_stale := false
var _cut_t := -1e9
var _cut_pending := false


func _cut_refresh(fx) -> void:
	if dead or gone or not _cut_stale or not has_meta("cut_job") or has_meta("cut_task"):
		return
	if fx.now - _cut_t < CUT_REFRESH:
		if not _cut_pending:
			_cut_pending = true
			fx.later(_cut_t + CUT_REFRESH, func l_cut_refresh() -> void:
				_cut_pending = false
				_cut_refresh(fx))
		return
	_cut_t = fx.now
	_cut_stale = false
	set_meta("cut_prev", get_meta("cut_job"))
	remove_meta("cut_job")
	var t_c := Time.get_ticks_usec()
	DEATH.precompute(fx, self)
	fx.pend("cut_start", t_c)


# A weapon's own mark on the hull where a shot landed (R43): look and weight pick it (fx_breach.marks_for); lp, ln and
# ldir are the hit point, its normal and the shot's direction in the ship frame. A fresh hit on an old mark of the same
# style grows and reheats it instead of stacking more geometry (_place_mark has the budget).
func add_mark(fx, look: String, w: int, lp: Vector3, ln: Vector3, ldir: Vector3) -> void:
	if squadron or weight <= 0 or dead or gone:
		return
	_mark_n += 1
	var t_m := Time.get_ticks_usec()
	var es: Array = BREACH.marks_for(hull, look, w, lp, ln, ldir, float(posmod(_seed, 997)) * 0.013 + _mark_n * 1.37, faction, 1.0, 1.0 - section_fraction[hull.section_of(lp.x)])
	if es.is_empty():
		return
	for e in es:
		e.t0 = fx.now
		e.sec = hull.section_of(e.c.x)
		_place_mark(fx, e)
	t_m = fx.pend("mark", t_m)
	_dmg_request(fx)
	fx.pend("dmg_request", t_m)


# One new mark into the ship's list (R43 budget). A repeat of the same style close by (anywhere in the section for a
# torpedo crater or an ion tree) rebuilds the old mark bigger and fresh instead of placing a twin. Entries are never
# changed in place (a worker may be reading them): a grown mark is a new entry. Past SEC_MARK_CAP in a section the
# oldest light mark (shell crater, pockmarks) goes first, then the oldest; past MARK_CAP the oldest on the ship.
func _place_mark(fx, e) -> void:
	var whole_sec: bool = e.style in [BREACH.S_BLAST, BREACH.S_ION]
	for j in _marks.size():
		var o = _marks[j]
		if o.style != e.style or o.sec != e.sec or o.style in [BREACH.S_GAUSS_IN, BREACH.S_GAUSS_OUT]:
			continue
		if whole_sec or o.c.distance_to(e.c) < o.R * 0.8 + e.R * 0.5 + o.hl:
			var g: float = minf(o.grow * 1.2, BREACH.GROW_MAX)
			var es2: Array = BREACH.marks_for(hull, o.look, maxi(o.wt, e.wt), o.hit_origin, o.hit_normal, o.ldir, o.seed_v, faction, g, 1.0 - section_fraction[o.sec])
			if o.part_i < es2.size():
				var n2 = es2[o.part_i]
				n2.t0 = fx.now
				n2.sec = o.sec
				_marks.remove_at(j)
				_marks.append(n2)
				return
	_marks.append(e)
	var in_sec: Array = []
	for o in _marks:
		if o.sec == e.sec:
			in_sec.append(o)
	if in_sec.size() > BREACH.SEC_MARK_CAP:
		var drop = in_sec[0]
		for o in in_sec:
			if o != e and o.style in [BREACH.S_SHELL, BREACH.S_FLAK]:
				drop = o
				break
		_marks.erase(drop)
	while _marks.size() > BREACH.MARK_CAP:
		_marks.pop_front()


# Explicit scar clearing for callers; normal repair keeps the marks.
func _repair_marks(fx, i: int) -> void:
	var keep: Array = []
	for o in _marks:
		if o.sec != i:
			keep.append(o)
	if keep.size() != _marks.size():
		_marks = keep
		_dmg_request(fx)


# A hull surface's arrays, read back once per ship and shared by the damage rebuild and the death cut (reading an 8K
# hull's arrays back costs a long frame, so it happens once, and after damage the cut uses the rebuilt arrays).
var _arr_cache := {}


func arrays_of(am: ArrayMesh, si: int) -> Array:
	var key := "%d:%d" % [am.get_instance_id(), si]
	if not _arr_cache.has(key):
		_arr_cache[key] = am.surface_get_arrays(si)
	return _arr_cache[key]


# The arrays the hull is drawn with now, per mesh instance and surface (rebuilt by damage, or the original).
func current_arrays(mi: MeshInstance3D, si: int) -> Array:
	if not _dmg_job.is_empty():
		var outs: Array = (_dmg_job.get("out", {}) as Dictionary).get("surfs", [])
		var surfs: Array = _dmg_job["surfs"]
		for k in surfs.size():
			if surfs[k]["mi"] == mi and int(surfs[k]["si"]) == si:
				if k < outs.size() and outs[k] != null:
					return outs[k]
				return surfs[k]["arrays"]
	var src = mi.mesh
	if not _orig.is_empty():
		for sd in _orig:
			if sd["mi"] == mi:
				src = sd["mesh"]
				break
	return arrays_of(src, si) if src is ArrayMesh else (src as Mesh).surface_get_arrays(si)


func wait_damage() -> void:
	if _dmg_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_dmg_task)
		_dmg_task = -1


func _build_section(fx, i: int, up: bool) -> void:
	_clear_section(i)
	var st: int = stage[i]
	_ents[i] = _plan(fx, i, st)
	for e in _ents[i]: e.wound_kind = int(fac.get("wound_kind", 0))
	_dmg_request(fx)
	if not up or st < 1 or fx.compat: return
	var a := _anchor(i, "a")
	var wp := to_world(a.p)
	var wn := dir_world(a.n)
	var glow: Color = fac.damage_glow
	# Transition sparks are small pooled events. Continuous wounds never flash.
	for j in (4 if st < 4 else 12):
		if faction == "chorus":
			fx.spr(wp, fx.now, 0.8, glow, 0.3, hull.L * 0.006, hull.L * 0.025, 20, wn * hull.L * 0.035)
		elif faction == "ithar":
			fx.spr(wp, fx.now, 0.7, glow, 0.5, hull.L * 0.004, hull.L * 0.009, 16, fx.rcone(wn, 0.8) * hull.L * 0.1)
		else:
			fx.stk(wp, fx.now, 0.45, glow, 2.0, 0.04, 0.08, 1, fx.rcone(wn, 0.8) * hull.L * 0.18)
	if st == 4 and faction != "chorus":
		for j in 4: fx.shd(wp, fx.now, 2.0, fx.rcone(wn, 0.8) * hull.L * 0.07, hull.L * 0.009, 0.8)


func _set_burning(fx, on: bool) -> void:
	_burning = on
	_refresh_damage_emitters(fx)


func damage_caps() -> Vector2i:
	return Vector2i(1, 2) if weight <= 1 else (Vector2i(2, 3) if weight == 2 else Vector2i(3, 4))


func damage_counts() -> Dictionary:
	var counts := {"fire": 0, "smoke": 0, "vent": 0, "particles": 0}
	for e in _damage_emitters + _fading_emitters:
		counts[e.kind] += 1
		counts.particles += e.particles
	return counts


func _refresh_damage_emitters(fx) -> void:
	var key := str(stage) + str(_burning) + str(fx.compat)
	if key == _emitter_key: return
	_emitter_key = key
	for e in _fading_emitters: e.node.queue_free()
	_fading_emitters.clear()
	var desired: Array = []
	var caps := damage_caps()
	var fires := 0
	var smoke := 0
	if not fx.compat and not squadron:
		# Worst sections claim slots first. Stable ids preserve unchanged emitters.
		for grade in [4, 3, 2]:
			for i in 3:
				var st: int = maxi(stage[i], 3 if _burning and i == 1 else 0)
				if st != grade: continue
				if st >= 3 and fires < caps.x:
					desired.append({"id": "fire%d" % i, "kind": "fire", "sec": i, "st": st})
					fires += 1
				if smoke < caps.y:
					desired.append({"id": "smoke%d" % i, "kind": "smoke", "sec": i, "st": st})
					smoke += 1
		if weight >= 3 and smoke < caps.y:
			for i in 3:
				if stage[i] >= 3 and smoke < caps.y:
					desired.append({"id": "vent%d" % i, "kind": "vent", "sec": i, "st": stage[i]})
					smoke += 1
	var keep: Array = []
	for e in _damage_emitters:
		var match_i := -1
		for j in desired.size():
			if desired[j].id == e.id and desired[j].st == e.st: match_i = j; break
		if match_i >= 0:
			keep.append(e)
			desired.remove_at(match_i)
		else:
			# Old emitters fade only when repairing, with no new replacements in
			# the same slot. Stage upgrades move the source inside immediately.
			if stage[e.sec] < e.st and not fx.compat and desired.is_empty():
				e["until"] = fx.now + 0.8
				_fading_emitters.append(e)
			else: e.node.queue_free()
	for e in desired:
		_build_damage_emitter(fx, e)
		keep.append(e)
	_damage_emitters = keep


func _build_damage_emitter(fx, e: Dictionary) -> void:
	var a := _anchor(e.sec, "a")
	var p: Vector3 = a.p
	var n: Vector3 = a.n
	var glow: Color = fac.damage_glow
	var b := POOLS.Batch.new()
	var kind := 3
	var color := Color(0.13, 0.12, 0.11)
	var intensity := 0.36
	var size0: float = hull.L * 0.014
	var size1: float = hull.L * 0.065
	var life := 2.5
	var count := 5
	var velocity: Vector3 = (n * 0.7 + Vector3.UP * 0.3) * hull.L * 0.10
	if faction == "deathless": color = Color(0.055, 0.025, 0.09); kind = 8
	if faction == "deathless" and e.st == 2:
		kind = 7; color = glow * 0.55
		size0 = hull.L * 0.004; size1 = hull.L * 0.018
		velocity = n * hull.L * 0.045
	if faction == "chorus": color = glow * 0.45; kind = 20
	if faction == "ithar": color = glow * 0.7; kind = 7; intensity = 0.24
	if e.kind == "fire":
		kind = 25
		color = glow
		count = 8
		life = 1.0
		intensity = 0.8
		size0 = hull.L * 0.009
		size1 = hull.L * 0.04
		velocity = (n * 0.7 + Vector3.UP * 0.3) * hull.L * 0.06
		if e.st == 4: p -= n * hull.L * 0.018
		if faction == "deathless": kind = 26
		if faction == "chorus": kind = 20; intensity = 0.35
		if faction == "ithar": kind = 7; intensity = 0.3
	elif e.kind == "vent":
		kind = 7; color = glow.lerp(Color.WHITE, 0.75); intensity = 0.22
		count = 4; life = 0.8
		velocity = n * hull.L * 0.13
		if faction == "chorus": kind = 20; color = glow * 0.6
	var period := life if e.kind != "vent" else 3.2
	for j in count:
		var t: float = fx.now - life + float(j) / count * period
		b.add(POOLS.quad_shape(), POOLS.pack(Vector4(p.x, p.y, p.z, t),
			Vector4(velocity.x, velocity.y, velocity.z, life), Vector4(color.r, color.g, color.b, intensity),
			Vector4(size0, size1, kind, j * 0.137), Vector4(period, 0, 0, 0.1)))
	var holder := Node3D.new()
	holder.name = "fx_damage_" + e.id
	_dmg_root.add_child(holder)
	var material: ShaderMaterial = fx.mat(SH.SPRITE, 1, "#define SOFT\n" if fx.quality != "low" else "")
	b.build(material, holder, "fx_section_particles")
	e["node"] = holder
	e["mat"] = material
	e["particles"] = b.particle_count
	e["sprite_kind"] = kind
	e["source"] = p


func _update_damage_emitters(fx) -> void:
	if dead or gone:
		for e in _damage_emitters: e.node.visible = false
		for e in _fading_emitters: e.node.visible = false
		return
	for j in range(_fading_emitters.size() - 1, -1, -1):
		var e: Dictionary = _fading_emitters[j]
		var gate: float = clampf((e.until - fx.now) / 0.8, 0.0, 1.0)
		e.mat.set_shader_parameter("gate", gate)
		if gate <= 0.0:
			e.node.queue_free()
			_fading_emitters.remove_at(j)
	if squadron and _squad_smoke and not fx.compat and fx.now >= _smoke_next:
		_smoke_next = fx.now + 0.12
		# World-space pooled samples form a short ribbon that stays behind a wing.
		fx.spr(to_world(hull.c - Vector3.RIGHT * hull.L * 0.2), fx.now, 1.2,
			Color(0.12, 0.12, 0.13), 0.32, hull.L * 0.015, hull.L * 0.10, 3,
			dir_world(Vector3.LEFT) * hull.L * 0.20)


# ---------------------------------------------------------------- small events

func pulse(fx, strength: float) -> void:
	var c: Color = fac["weapon"]
	var p = to_world(hull.c)
	var k = scale_k()
	fx.ring(p, dir_world(Vector3.UP), fx.now, 0.9, c, 1.2 * strength, hull.L * 0.3, hull.L * 0.9, 2)
	fx.spr(p, fx.now, 0.8, c, 1.0 * strength, hull.L * 0.4, hull.L * 0.8, 18)
	fx.light(p, fx.now, 0.7, 3.0 * strength, c, 1)


func tick_flare(fx, kind: String) -> void:
	var h: Dictionary = hull.random_sample(-1, 0.5)
	var wp = to_world(h["p"])
	var wn = dir_world(h["n"])
	var k = scale_k()
	var T: float = fx.now
	match kind:
		"acid":
			for i in 6:
				fx.spr(wp + fx.rdir() * 1.5 * k, T + i * 0.05, 1.6, Color(0.5, 0.9, 0.2), 0.6, 1.0 * k, 4.0 * k, 20, wn * 1.5, 0.5)
		"tidal":
			for i in 20:
				fx.stk(wp + fx.rdir() * 3.0 * k, T + fx.rng.randf() * 0.3, 0.5, Color(0.7, 0.8, 1.0), 4.0, 0.15, 0.1, 1, fx.rdir() * 6.0, 0.5)
		"storm":
			if _shield_mat != null:
				shield_hit(fx, shield_point(wp + wn * 30.0)["local"], T, 0.6, 14.0, 0.8)
		_:
			for i in 8:
				fx.spr(wp, T + i * 0.05, 0.7, Color(1, 0.5, 0.15), 2.4, 0.8 * k, 2.4 * k, 1, wn * 2.0 + fx.rdir(), 0.0)
			fx.light(wp + wn, T, 0.6, 3.0, Color(1, 0.5, 0.15), 1)


func jump_out(fx) -> void:
	var T: float = fx.now
	var bow = dir_world(Vector3(1, 0, 0))
	var c: Color = fac["engine"]
	var p = to_world(hull.c)
	for t in hull.nozzles:
		var np = to_world(t["p"])
		fx.spr(np, T, 0.5, c, 6.0, 2.0, 8.0, 2)
	fx.light(p, T, 0.6, 6.0, c, 0)
	fx.stk(p, T + 0.35, 0.4, c.lerp(Color.WHITE, 0.5), 10.0, hull.L * 3.0, hull.W * 0.4, 0, bow * hull.L * 20.0)
	fx.ring(p, bow, T + 0.35, 0.6, c, 1.5, hull.L * 0.2, hull.L * 1.2, 1)
	fx.later(T + 0.4, func l_jump() -> void:
		gone = true
		for m in meshes:
			if is_instance_valid(m):
				(m as Node3D).visible = false
		if is_instance_valid(_eng_node):
			_eng_node.visible = false
		for tr in _trails:
			(tr["mi"] as Node3D).visible = false)


# A mark's geometry follows the section's actual damage, including repairs.
# Recreate entries rather than mutating entries a worker may be reading.
func _regrade_marks(fx) -> void:
	var changed := false
	var updated: Array = []
	for e in _marks:
		var damage: float = 1.0 - section_fraction[e.sec]
		if absf(e.section_damage - damage) > 0.025:
			var entries := BREACH.marks_for(hull, e.look, e.wt, e.hit_origin, e.hit_normal, e.ldir, e.seed_v, faction, e.grow, damage)
			if e.part_i < entries.size():
				var replacement = entries[e.part_i]
				replacement.t0 = e.t0
				replacement.sec = e.sec
				updated.append(replacement)
				changed = true
		else: updated.append(e)
	if changed:
		_marks = updated
		_dmg_request(fx)
