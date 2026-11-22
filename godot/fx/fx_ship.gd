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
const SHIELD_CACHE := preload("res://fx/fx_shield_cache.gd")
const SHIP_VIEW := preload("res://render/ship_view.gd")

const TRAIL_PTS := 96
const TRAIL_LIFE := 2.6
const TRAIL_COLD_AGE := 3.5   # issue 1581: a moving ship with its drive cold (braking, a slide) ages its trail this much faster
const IDLE_GLOW := 0.3                    # engine glow of a parked ship, as a share of cruise (r12)
# The one scale table's class bands (issue 710, R247; docs/playbooks/scale.md): a death reads as a cruiser or a capital
# by class, and an effect's size follows the drawn hull length through scale_k.
const DEATH_BIG_CLASSES := ["Cruiser", "Carrier", "Battleship", "Dreadnought", "Super-dreadnought", "Battle-barge", "Bio-titan", "Ark", "Tomb-ark"]
const DEATH_CAPITAL_CLASSES := ["Carrier", "Battleship", "Dreadnought", "Super-dreadnought", "Battle-barge", "Bio-titan", "Ark", "Tomb-ark"]
const SCALE_K_DIV := 24.0
const SCALE_K_MIN := 0.25
const SCALE_K_MAX := 2.5

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
var death_tier = ""       # issue 462: "cruiser" or "capital" (deaths_and_hits.md rows), "small", "destroyer" or "wing" below cruiser
var hull: HULL
var dead = false
var gone = false
var busy_until = -1.0
var engine_level = 1.0
var _eng_cur = 1.0
var _eng_node: MeshInstance3D = null
var _eng_mat: ShaderMaterial
var _eng_rib_mat: ShaderMaterial
# Issue 1587: with the engine section at stage 3+, one nozzle (sick_nozzle) is built into its own batches so it can gutter
# on its own: a shorter plume with gaps, and a cough of smoke as the ship starts to move.
var sick_nozzle := -1
var _sick_mat: ShaderMaterial
var _sick_rib_mat: ShaderMaterial
var _cough_next := 0.0
var _was_moving := false
var _jammed := {}            # section -> {"k": turret, "next": the next spark pop} (issue 1587)
var _power_dip_until := -1.0
var _power_shown := -1.0
var _stages_seen := false   # the first stage update is the ship's state as it arrives (a rebuilt view): no blowout
# one-shot wound events for the checks only ([kind, section or nozzle, time]); off in play (Artoo on PR 1631)
var wound_log_on := false
var wound_log: Array = []
var _eng_sputter = false
var _trails: Array = []    # per nozzle: {mi, hist: Array of [pos, t, level], seed, r}
var _trail_extra := 0.0    # issue 1581: extra age the trails carry (they age faster while the drive is cold under way)
static var _trail_indices: Dictionary = {}   # not GPU: index arrays (PackedInt32Array)
var _last_pos = Vector3.INF
var _moving = 0.0
var _shield_mi: MeshInstance3D = null
var _shield_mat: ShaderMaterial = null
var _shield_tm: TriangleMesh = null
var _shield_pose := Transform3D.IDENTITY
# Keep enough recent hulls for a fleet without retaining every asset or pose used in a run.
const SHIELD_SKIN_CACHE_LIMIT := 48
static var _shield_skin_arrays: Dictionary = {}   # not GPU: mesh arrays on the CPU, size capped
var _hit_i = 0
var _hits = PackedVector4Array()
var _hitw = PackedVector4Array()
var _shield_until = -1.0
var _brk_until = -1.0      # issue 1239 (F2.3): until when a shield failure is still playing (a death lets it finish)
# Issue 1078: which shield failure look plays (2 clean collapse, the game's look since R340; 0 the old per-faction break
# and 1 energy shear stay only for side-by-side checks) and the shear's quality (true: the cheaper crack network).
# Read once per ship from the settings (see fail_look_setting).
var _fail_look := 2
var _fail_low := false
var _last_sh = -1.0
var section_fraction := [1.0, 1.0, 1.0]
var stage = [0, 0, 0]     # eng, mid, prow
var death_core_pending := false
var slow_core := false
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
var _damage_surfaces := {}  # mutable breach coordinates are private to each surface
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
	_arr_cache = fx.hull_arrays
	faction = String(info.get("faction", "voidsworn")).to_lower()
	fac = fx.faction_info(faction)
	squadron = bool(info.get("squadron", false)) or String(info.get("cls", "")) == "Squadron"
	shielded = bool(info.get("shielded", fac["shielded"])) and not squadron
	flagship = bool(info.get("flagship", false))
	death_big = flagship or String(info.get("cls", "")) in DEATH_BIG_CLASSES
	# Issue 462: the playbook's capital row covers carriers, barges and the capital classes; a flagship of a smaller
	# class dies as a cruiser.
	death_tier = ("capital" if String(info.get("cls", "")) in DEATH_CAPITAL_CLASSES else "cruiser") if death_big else ("wing" if squadron else ("destroyer" if String(info.get("cls", "")) == "Destroyer" else "small"))
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
	hull.code = str(root.get("code")) if root.get("code") != null else sid
	hull.formation = squadron
	hull.shared = fx.get("hull_shared")
	var t_a := Time.get_ticks_usec()   # issue 1289: an arriving ship's parts, named in fx.prof (the arrival bench reads them)
	hull.analyse(root, meshes, _seed)
	t_a = fx.pend("add:analyse", t_a)
	# issue 370: ShipView's movement jets (braking, side, turning) ask the same attach point service
	if "attach" in root:
		root.set("attach", hull)
	# ShipView bobs and banks the hull node under the root; the hull analysis above is in the pose of this moment, so
	# the damage (overlay skins, cavities, fires) follows the hull's motion from here (r6: the hull bobbed 0.25 units
	# up and down past a mark overlay lifted 0.026, so overlay-only marks such as ion burns kept vanishing into it).
	# r18: the damage and the engines hang under a hull mesh itself (with the inverse of its pose now), so they move
	# with the hull in the same frame, every frame; r6-r17 copied the hull's motion in fx's update, which lagged
	# whenever the hull moved between fx steps (the stills: overlays sank into the bobbing hull at random, which is
	# why marks came and went between runs)
	for m in meshes:
		# (issue 560: never a turret's turning mesh, which turns under the hull and would carry the damage round with it)
		if m is MeshInstance3D and hull._turret_above(m, root) < 0 and hull._door_above(m, root) < 0:
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
	t_a = fx.pend("add:damage_root", t_a)
	if not squadron or root.get("squad_kind") == null or str(root.get("squad_kind")).is_empty():
		_build_engines(fx)
		_build_trails(fx)
	t_a = fx.pend("add:engines", t_a)
	if shielded:
		_build_shield(fx)
	fx.pend("add:shield", t_a)
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


func remove_collider() -> void:
	if not has_meta("collider"):
		return
	var body = get_meta("collider")
	remove_meta("collider")
	if is_instance_valid(body):
		body.collision_layer = 0
		body.queue_free()


func _hide_attachments() -> void:
	remove_collider()
	for node in [_dmg_root, _eng_node, _shield_mi]:
		if is_instance_valid(node):
			node.visible = false
	for t in _trails:
		if is_instance_valid(t["mi"]):
			t["mi"].visible = false
	for sec in 3:
		_clear_lights(sec)
	for l in _hole_lights:
		l["on"] = false
	_hole_lights.clear()
	for n in _burn_nodes:
		if n is Dictionary:
			n["on"] = false


func _hide_meshes() -> void:
	for m in meshes:
		if is_instance_valid(m):
			(m as Node3D).visible = false


func hide_live_hull() -> void:
	_hide_meshes()
	_hide_attachments()


func teardown(fx, wait_for_damage := true) -> void:
	gone = true
	_hide_attachments()
	fx.discard_ship_cut(self)
	if wait_for_damage:
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
	return clampf(hull.L / SCALE_K_DIV, SCALE_K_MIN, SCALE_K_MAX)


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
	var b_main = b
	var rb_main = rb
	var sb = POOLS.Batch.new()
	var srb = POOLS.Batch.new()
	sick_nozzle = posmod(_seed, hull.nozzles.size()) if _eng_sputter and not hull.nozzles.is_empty() else -1
	for ni in hull.nozzles.size():
		var nz: Dictionary = hull.nozzles[ni]
		b = sb if ni == sick_nozzle else b_main
		rb = srb if ni == sick_nozzle else rb_main
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
			# a corona round the core in the faction's second colour (faction look data, accent; three factions set one)
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
	b_main.build(_eng_mat, holder, "fx_eng_cores")
	rb_main.build(_eng_rib_mat, holder, "fx_eng_plumes")
	_sick_mat = null
	_sick_rib_mat = null
	if sick_nozzle >= 0:
		_sick_mat = fx.mat(SH.SPRITE, 1, "#define SOFT\n" if fx.quality != "low" else "")
		_sick_rib_mat = fx.mat(SH.RIBBON, 1)
		sb.build(_sick_mat, holder, "fx_eng_sick_core")
		srb.build(_sick_rib_mat, holder, "fx_eng_sick_plume")


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
		_trails.append({"mi": mi, "hist": [], "seed": fx.rng.randf(), "r": nz["r"], "p": nz["p"],
			"d": nz.get("d", Vector3(-1, 0, 0)), "style": -1})


func update(fx, dt: float) -> void:
	if gone or not is_instance_valid(root):
		return
	if not hull.turrets.is_empty():
		hull.turret_step(fx.now)    # issue 560: each turret's node at its pose for the effect clock
	if not hull.doors.is_empty():
		hull.door_step(fx.now)      # issue 1543: each launch mouth's door lobes at their pose for the effect clock
	_update_damage_emitters(fx)
	_list_step(dt)
	_react_step(fx, dt)
	_hide_placeholder_engines()
	if _shield_mi != null and _shield_mi.visible:
		_shield_mi.transform = hull_motion() * _shield_pose
	var pos = root.global_position - root.get_parent_node_3d().global_transform.basis * _app_pos if root.get_parent_node_3d() != null else root.global_position
	var moved = pos.distance_to(_last_pos) if _last_pos != Vector3.INF else 0.0
	_last_pos = pos
	_moving = maxf(_moving - dt, 0.0)
	if moved > 1e-4:
		_moving = 0.4
	# the drive glows full only while the ship thrusts (moving, or a burn G2 asks for with set_engine above cruise); a
	# parked ship keeps a dim pilot glow and a short, faint trail (Ryan, r12: engines glowed and trailed at rest)
	var want = 0.0 if dead else ((engine_level if absf(engine_level - 1.0) > 0.05 else 1.6) if _moving > 0.0 else (engine_level if engine_level > 1.05 else IDLE_GLOW * engine_level))
	# Issue 462, the tell: a dying big hull's drive flares once (fx_death sets the flare) and holds it for two frames,
	# then goes black fast.
	if dead and fx.now < float(get_meta("death_flare_until", -1.0)):
		want = _eng_cur
	# rise gently, drop fast: a burn's plume cuts off within about 0.1 s instead of fading over half a second (G2)
	_eng_cur = lerpf(_eng_cur, want, clampf(dt * (4.0 if want > _eng_cur else (30.0 if dead else 14.0)), 0.0, 1.0))
	if _eng_mat != null:
		var g := clampf(_eng_cur, 0.0, 2.0)
		if fx.now < _stutter_until:
			# a heavy hit makes the drive stumble: the plume gutters and catches again
			var flick := 1.0 if fposmod(sin(fx.now * 37.0 + float(_seed)) * 43758.5, 1.0) > 0.45 else 0.0
			g *= 0.3 + 0.7 * maxf(flick, smoothstep(_stutter_until - 0.25, _stutter_until, fx.now))
		_eng_mat.set_shader_parameter("gate", g)
		_eng_rib_mat.set_shader_parameter("gate", g)
		_eng_rib_mat.set_shader_parameter("lenk", clampf(0.5 + 0.5 * _eng_cur, 0.0, 1.8))
		if _sick_mat != null:
			var sg := g * sick_gate(fx.now, fx.reduce_flashing)
			_sick_mat.set_shader_parameter("gate", sg)
			_sick_rib_mat.set_shader_parameter("gate", sg)
			_sick_rib_mat.set_shader_parameter("lenk", clampf(0.5 + 0.5 * _eng_cur, 0.0, 1.8) * SICK_LEN)
	var moving_now: bool = _moving > 0.0 and not dead
	if moving_now and not _was_moving and sick_nozzle >= 0 and fx.now >= _cough_next:
		_cough(fx)
	_was_moving = moving_now
	_wound_step(fx)
	# issue 1581 (Nov 21 audit: rear trails lingered as skid marks while the retros braked): once the battle cuts the
	# drive cold in a flown move, the ribbon behind it shortens fast instead of hanging for its full life
	if _moving > 0.0 and engine_level < 0.12 and not dead:
		_trail_extra += dt * (TRAIL_COLD_AGE - 1.0)
	_update_trails(fx, moved > 1e-4)
	if _shield_mi != null:
		_shield_mi.visible = fx.now < _shield_until


func _update_trails(fx, _moved: bool) -> void:
	var _tclock: float = fx.now + _trail_extra   # the trails' clock (issue 1581)
	if _trails.is_empty():
		return
	var xfm = xf()
	# issue 1586 (Neon on PR 1666): a torch death's over-flaring drive keeps its exhaust while the flare runs, from the
	# nozzles where the spiralling hull really is
	var flaring: bool = dead and not death_big and fx.now < float(get_meta("death_flare_until", -1.0)) and has_meta("death_motion")
	if flaring:   # the same pose fx_death._small_pose gives the dying hull
		xfm = root.global_transform * (get_meta("death_motion") as Transform3D) * (get_meta("death_hull_motion", Transform3D.IDENTITY) as Transform3D)
	var eng: Color = fac["engine"]
	var lvl = clampf(_eng_cur, 0.0, 2.0)
	var plume = clampf(1.5 * hull.W, 2.0, 32.0)
	var style: int = 1 if (String(fac.get("engine_extra", "")) == "soot" or _eng_sputter) else int(fac["trail"])
	for ti in _trails.size():
		var t: Dictionary = _trails[ti]
		var hist: Array = t["hist"]
		var changed := false
		# Neon on PR 1631: the sick nozzle's ribbon gutters with its plume (one trail per nozzle, in order); the dim samples
		# still go in, so the ribbon fades through the gap instead of bridging it bright
		var lvl_t: float = lvl * (sick_gate(fx.now, fx.reduce_flashing) if ti == sick_nozzle else 1.0)
		var start: Vector3 = xfm * (t["p"] as Vector3) + (xfm.basis * (t["d"] as Vector3)).normalized() * (0.3 * plume)
		# Each sample belongs to world space for its entire life. Turning, stopping
		# or throttling down never drags old exhaust along with the nozzle.
		# (issue 1581, OpenAI review F4: no fresh exhaust while the battle has the drive cold, even as the plume eases down)
		if (not dead or flaring) and lvl > 0.12 and not (_moving > 0.0 and engine_level < 0.12):
			if hist.is_empty() or ((hist[0][0] as Vector3).distance_to(start) > 0.03 * fx.unit and (_tclock - float(hist[0][1]) >= 0.05 or (hist[0][0] as Vector3).distance_to(start) > 1.2 * fx.unit)):
				hist.push_front([start, _tclock, lvl_t])
				changed = true
		while not hist.is_empty() and (hist.size() > TRAIL_PTS or _tclock - float(hist.back()[1]) >= TRAIL_LIFE):
			hist.pop_back()
			changed = true
		var mi: MeshInstance3D = t["mi"]
		mi.visible = hist.size() >= 2
		if not mi.visible:
			continue
		var mat := mi.material_override as ShaderMaterial
		if changed:
			t["mesh_time"] = _tclock
			_trail_mesh(fx, t, eng)
		mat.set_shader_parameter("trail_elapsed", (_tclock - float(t["mesh_time"])) / TRAIL_LIFE)
		if int(t["style"]) != style:
			t["style"] = style
			mat.set_shader_parameter("trail_style", float(style))


func _trail_mesh(fx, t: Dictionary, eng: Color) -> void:
	var _tclock: float = fx.now + _trail_extra
	var hist: Array = t["hist"]
	var mi: MeshInstance3D = t["mi"]
	var n := hist.size()
	var verts = PackedVector3Array()
	var nrm = PackedVector3Array()
	var uv = PackedVector2Array()
	var c0 = PackedFloat32Array()
	var c1 = PackedFloat32Array()
	var r: float = t["r"]
	var w0 = r * 1.1
	var w1 = r * 2.4 * clampf(scale_k(), 0.6, 1.6)
	for i in n:
		var d = (hist[mini(i + 1, n - 1)][0] - hist[maxi(i - 1, 0)][0]).normalized()
		for sd in [-0.5, 0.5]:
			verts.append(hist[i][0])
			nrm.append(d)
			uv.append(Vector2(clampf((_tclock - float(hist[i][1])) / TRAIL_LIFE, 0.0, 1.0), sd))
			c0.append_array([eng.r, eng.g, eng.b, 0.28 * clampf(float(hist[i][2]), 0.0, 1.5)])
			c1.append_array([w0, w1, float(t["seed"]), 0.0])
	if not _trail_indices.has(n):
		var idx := PackedInt32Array()
		for i in n - 1:
			var q := i * 2
			idx.append_array(PackedInt32Array([q, q + 1, q + 3, q, q + 3, q + 2]))
		_trail_indices[n] = idx
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = nrm
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_CUSTOM0] = c0
	arr[Mesh.ARRAY_CUSTOM1] = c1
	arr[Mesh.ARRAY_INDEX] = _trail_indices[n]
	var fl = (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) | (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT)
	var am: ArrayMesh = mi.mesh
	if am == null:
		am = ArrayMesh.new()
		mi.mesh = am
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
	# Ryan, Nov 18 (issue 1045): the fitted skin replaces the R297 egg default.
	# Select the egg with rendering/effects/shield_shape="egg" or VS_SHIELD_SHAPE=egg.
	var shape := OS.get_environment("VS_SHIELD_SHAPE")
	if shape.is_empty():
		shape = str(ProjectSettings.get_setting("rendering/effects/shield_shape", "fitted"))
	var skin: Mesh = _shield_skin(fx) if shape == "fitted" else sph
	if skin == null:
		skin = sph
	_shield_mat = fx.mat(SH.SHIELD, 2)
	_shield_mat.set_shader_parameter("fitted_shape", _shield_tm != null)
	var sc: Color = fac["shield"]
	_shield_mat.set_shader_parameter("col", Vector3(sc.r, sc.g, sc.b) * 2.2)
	_shield_mat.set_shader_parameter("rad", hull.shield_radii())
	_shield_mat.set_shader_parameter("style", int(fac["shield_style"]))
	_fail_look = fail_look_setting()
	_fail_low = fail_low_setting()
	_shield_mat.set_shader_parameter("brk_look", _fail_look)
	_shield_mat.set_shader_parameter("brk_low", _fail_low)
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
	_shield_mi.mesh = skin
	_shield_mi.material_override = _shield_mat
	_shield_mi.position = hull.shield_centre()
	_shield_mi.scale = Vector3.ONE if _shield_tm != null else hull.shield_radii()
	_shield_pose = _shield_mi.transform
	_shield_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shield_mi.visible = false
	root.add_child(_shield_mi)


func _shield_skin(fx = null) -> ArrayMesh:
	var frames := {}
	var box := AABB()
	var view := root as SHIP_VIEW
	var visual: Node3D = view.hull if view != null else null
	var bob := visual.position - view.hull_base if visual != null else Vector3.ZERO
	for m in meshes:
		if not is_instance_valid(m): continue
		var mi := m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		# Compose local transforms to avoid roundoff from world position and facing.
		var frame := Transform3D.IDENTITY
		var part: Node3D = mi
		while part != root and part != null and not part.top_level:
			var local := part.transform
			if part == visual:
				local.origin = view.hull_base
			frame = local * frame
			part = part.get_parent_node_3d()
		if part != root:
			frame = root.global_transform.affine_inverse() * mi.global_transform
		var bounds: AABB = frame * mi.mesh.get_aabb()
		box = bounds if frames.is_empty() else box.merge(bounds)
		frames[mi] = frame
	# Issue 1289: the skin's cache key needs every hull triangle (about 55 ms for A16 on the PC); the battle's effects keep
	# it per mesh set and frames (fx.shield_keys), so a later ship of the same hull skips the triangles when it is cached.
	var keys = fx.get("shield_keys") if fx != null else null
	var fkey := ""
	if keys is Dictionary:
		var parts := PackedStringArray()
		for mi in frames:
			parts.append("%d@%s" % [(mi as MeshInstance3D).mesh.get_instance_id(), str(frames[mi])])
		fkey = "|".join(parts)
	var key: String = (keys as Dictionary).get(fkey, "") if fkey != "" else ""
	var faces := PackedVector3Array()
	if key == "":
		faces = HULL.faces_of(root, meshes, null, frames)
		if faces.is_empty():
			return null
		key = SHIELD_CACHE.key_for(box, faces)
		if fkey != "":
			keys[fkey] = key
	var arrays: Array = _shield_skin_arrays.get(key, [])
	if arrays.is_empty() and faces.is_empty():
		faces = HULL.faces_of(root, meshes, null, frames)
	if arrays.is_empty():
		arrays = SHIELD_CACHE.read_skin(key)
		if not arrays.is_empty():
			_remember_shield_skin(key, arrays)
		elif fx != null and fx.defer_initial_cuts:
			fx.queue_shield_skin(self, key, box, faces, bob)
			return null
		else:
			arrays = _bake_shield_skin(box, faces)
			if arrays.is_empty():
				return null
			save_shield_skin(key, arrays)
	return _posed_skin(fx, key, arrays, bob)


# Issue 1289: posing a fitted skin (copy, offset, upload, hit collider) cost every arriving ship 100 ms or more in its
# arrival frame, cache hit or not. A pose depends only on the cached skin and its offset from the core, so the battle's
# effects keep each pose they built (fx.shield_poses, freed with the battle) and a second ship of the same hull shares it.
# Both are read only after this: the shield draws the mesh with its own material and hit tests read the collider.
func _posed_skin(fx, key: String, arrays: Array, bob: Vector3) -> ArrayMesh:
	var off := bob - hull.shield_centre()
	var pk := "%s|%.3f|%.3f|%.3f" % [key, off.x, off.y, off.z]
	var poses = fx.get("shield_poses") if fx != null else null
	if poses is Dictionary and (poses as Dictionary).has(pk):
		var e: Array = poses[pk]
		_shield_tm = e[1]
		return e[0]
	var skin := _pose_shield_skin(arrays, bob)
	if poses is Dictionary:
		poses[pk] = [skin, _shield_tm]
	return skin


static func _remember_shield_skin(key: String, arrays: Array) -> void:
	if not _shield_skin_arrays.has(key) and _shield_skin_arrays.size() >= SHIELD_SKIN_CACHE_LIMIT:
		_shield_skin_arrays.erase(_shield_skin_arrays.keys()[0])
	_shield_skin_arrays[key] = arrays


static func save_shield_skin(key: String, arrays: Array) -> void:
	_remember_shield_skin(key, arrays)
	SHIELD_CACHE.write_skin(key, arrays)


func install_shield_skin(arrays: Array, bob: Vector3, fx = null, key := "") -> void:
	if not is_instance_valid(_shield_mi) or gone:
		return
	_shield_mi.mesh = _posed_skin(fx, key, arrays, bob) if key != "" else _pose_shield_skin(arrays, bob)
	_shield_mat.set_shader_parameter("fitted_shape", true)
	_shield_pose = Transform3D(Basis.IDENTITY, hull.shield_centre())
	_shield_mi.transform = _shield_pose


func _pose_shield_skin(arrays: Array, bob: Vector3) -> ArrayMesh:
	# The cache is in the unbobbed frame. Hits and the shader use coordinates
	# relative to the active core, just as they do for the egg.
	var posed := arrays.duplicate()
	posed[Mesh.ARRAY_VERTEX] = Transform3D(Basis.IDENTITY, bob - hull.shield_centre()) * (posed[Mesh.ARRAY_VERTEX] as PackedVector3Array)
	var skin := ArrayMesh.new()
	skin.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, posed)
	_shield_tm = TriangleMesh.new()
	_shield_tm.create_from_faces(skin.get_faces())
	return skin


static func _bake_shield_skin(box: AABB, faces: PackedVector3Array) -> Array:
	return finish_shield_geometry(bake_shield_geometry(box, faces))


static func bake_shield_geometry(box: AABB, faces: PackedVector3Array) -> Array:
	# R303: offset sampled hull surfaces, rather than stretching a sphere from the
	# core. Uniform cells along the whole hull preserve waists and open ring holes.
	# Only the outside of the offset volume is meshed, never interior armour skins.
	var surface := TriangleMesh.new()
	if not surface.create_from_faces(faces):
		return []
	var length := maxf(box.size.x, 0.1)
	var cross_span := maxf(minf(box.size.y, box.size.z), 0.05)
	var step := maxf(length / 128.0, minf(length / 96.0, cross_span / 12.0))
	var gap := maxf(cross_span * 0.08, step * 1.5)
	var margin := gap + step * 3.0
	var origin := box.position - Vector3.ONE * margin
	var size := Vector3i((box.size + Vector3.ONE * margin * 2.0) / step) + Vector3i.ONE * 2
	var stride := Vector3i(1, size.x, size.x * size.y)
	var field := PackedFloat32Array()
	field.resize(size.x * size.y * size.z)
	field.fill(pow(gap / step + 2.0, 2.0))
	var sampled := PackedByteArray()
	sampled.resize(field.size())
	# Each sweep visits every intersection, including the inside edge of a ring.
	# The three axes also sample faces edge-on to either of the other two sweeps.
	for axis in 3:
		var u := (axis + 1) % 3
		var v := (axis + 2) % 3
		var direction := Vector3.ZERO
		direction[axis] = 1.0
		for a in size[u]:
			for b in size[v]:
				var start := origin
				start[u] += a * step
				start[v] += b * step
				for crossing in 128:
					var hit := surface.intersect_ray(start, direction)
					if hit.is_empty(): break
					var at: Vector3 = hit["position"]
					var p := (at - origin) / step
					var cell := Vector3i(p).clamp(Vector3i.ZERO, size - Vector3i.ONE)
					var sample_i := cell.x + cell.y * stride.y + cell.z * stride.z
					if sampled[sample_i] == 0:
						sampled[sample_i] = 1
						_shield_sample(field, size, stride, p, gap / step + 1.5)
					start = at + direction * step * 0.04
	# Signed distance to the sampled surface. Flood from empty space, filling only
	# sealed cavities. A ring's through-hole remains connected to outside space.
	var threshold := (gap / step) * (gap / step)
	for i in field.size():
		var value := field[i] - threshold
		# Keep crossings away from exact grid corners, where float rounding can
		# collapse distinct edge vertices into zero-area triangles.
		field[i] = value if absf(value) > 0.001 else (0.001 if value >= 0.0 else -0.001)
	var outside := PackedByteArray()
	outside.resize(field.size())
	var queue := PackedInt32Array([0])
	outside[0] = 1
	var head := 0
	while head < queue.size():
		var i := queue[head]
		head += 1
		var cell := Vector3i(i % size.x, (i / size.x) % size.y, i / stride.z)
		for axis in 3:
			for sign_i in [-1, 1]:
				if cell[axis] + sign_i < 0 or cell[axis] + sign_i >= size[axis]: continue
				var j: int = i + stride[axis] * sign_i
				if outside[j] == 0 and field[j] > 0.0:
					outside[j] = 1
					queue.append(j)
	for i in field.size():
		if outside[i] == 0 and field[i] > 0.0: field[i] = -threshold
	# Marching tetrahedra share every edge vertex, including cell diagonals. This
	# removes the ambiguous saddle faces that can leave seams at thin hull details.
	var plane := stride.z
	var row := stride.y
	var corners := PackedInt32Array([0, 1, row, row + 1, plane, plane + 1, plane + row, plane + row + 1])
	var cases := _shield_cases(corners)
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var shared := {}
	var quad := PackedInt32Array([0, 0, 0, 0])
	for z in range(size.z - 1):
		for y in range(size.y - 1):
			var start := y * row + z * plane
			for x in range(size.x - 1):
				var base := start + x
				var mask := 0
				for k in 8:
					if field[base + corners[k]] <= 0.0:
						mask |= 1 << k
				for polygon in cases[mask]:
					var edges: Array[Vector2i] = polygon[0]
					for i in edges.size():
						var edge := edges[i]
						quad[i] = _shield_vertex(base + edge.x, base + edge.y, field, size, stride, origin, step, shared, vertices)
					_shield_face(quad[0], quad[1], quad[2], polygon[1], vertices, indices)
					if edges.size() == 4:
						_shield_face(quad[0], quad[2], quad[3], polygon[1], vertices, indices)
	if indices.is_empty():
		return []
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays


static func finish_shield_geometry(arrays: Array) -> Array:
	if arrays.is_empty():
		return []
	var raw := ArrayMesh.new()
	raw.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var st := SurfaceTool.new()
	st.create_from(raw, 0)
	st.generate_normals()
	return st.commit().surface_get_arrays(0)


static func _shield_cases(offsets: PackedInt32Array) -> Array[Array]:
	# Every cell uses the same six tetrahedra. Keep their edge order and winding
	# while doing the inside/outside classification only once per corner mask.
	var corners := [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0),
		Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1)]
	var tetrahedra := [[0, 1, 3, 7], [0, 3, 2, 7], [0, 2, 6, 7], [0, 6, 4, 7], [0, 4, 5, 7], [0, 5, 1, 7]]
	var cases: Array[Array] = []
	for mask in 256:
		var polygons := []
		for tet in tetrahedra:
			var inside: Array[int] = []
			var air: Array[int] = []
			for k in tet:
				if mask & (1 << k):
					inside.append(k)
				else:
					air.append(k)
			if inside.is_empty() or air.is_empty():
				continue
			var outward := Vector3.ZERO
			for k in air:
				outward += corners[k] / air.size()
			for k in inside:
				outward -= corners[k] / inside.size()
			var edges: Array[Vector2i] = []
			if inside.size() == 2:
				edges = [Vector2i(offsets[inside[0]], offsets[air[0]]), Vector2i(offsets[inside[0]], offsets[air[1]]),
					Vector2i(offsets[inside[1]], offsets[air[1]]), Vector2i(offsets[inside[1]], offsets[air[0]])]
			else:
				var one := inside[0] if inside.size() == 1 else air[0]
				for other in (air if inside.size() == 1 else inside):
					edges.append(Vector2i(offsets[one], offsets[other]))
			polygons.append([edges, outward])
		cases.append(polygons)
	return cases


static func _shield_vertex(a: int, b: int, field: PackedFloat32Array, size: Vector3i, stride: Vector3i, origin: Vector3, step: float, shared: Dictionary, vertices: PackedVector3Array) -> int:
	var key := mini(a,b) * field.size() + maxi(a,b)
	if shared.has(key): return shared[key]
	var pa := Vector3(a % size.x, (a / size.x) % size.y, a / stride.z)
	var pb := Vector3(b % size.x, (b / size.x) % size.y, b / stride.z)
	var t := clampf(field[a] / (field[a] - field[b]), 0.0, 1.0)
	var index := vertices.size()
	shared[key] = index
	vertices.append(origin + pa.lerp(pb,t) * step)
	return index


static func _shield_face(a: int, b: int, c: int, outward: Vector3, vertices: PackedVector3Array, indices: PackedInt32Array) -> void:
	# Godot front faces wind clockwise.
	indices.append(a)
	if (vertices[c] - vertices[a]).cross(vertices[b] - vertices[a]).dot(outward) < 0.0:
		indices.append(c)
		indices.append(b)
	else:
		indices.append(b)
		indices.append(c)


static func _shield_sample(field: PackedFloat32Array, size: Vector3i, stride: Vector3i, p: Vector3, reach: float) -> void:
	var lo := Vector3i(p - Vector3.ONE * reach).max(Vector3i.ZERO)
	var hi := (Vector3i(p + Vector3.ONE * reach) + Vector3i.ONE).min(size - Vector3i.ONE)
	for z in range(lo.z, hi.z + 1):
		for y in range(lo.y, hi.y + 1):
			var start := y * stride.y + z * stride.z
			for x in range(lo.x, hi.x + 1):
				var i := start + x
				field[i] = minf(field[i], Vector3(x,y,z).distance_squared_to(p))


# Where a shot from `from_world` meets the bubble (world point and outward normal).
func shield_point(from_world: Vector3, aim_local := Vector3.INF) -> Dictionary:
	var inv = xf().affine_inverse()
	var rad = hull.shield_radii()
	var o = (inv * from_world) - hull.shield_centre()
	var tgt = (aim_local - hull.shield_centre()) if aim_local != Vector3.INF else Vector3.ZERO
	var d = (tgt - o).normalized()
	if _shield_tm != null:
		var hit := _shield_tm.intersect_ray(o, d)
		if hit.is_empty():
			# A ray at the centre can pass through a ring hole. Aim at real hull
			# instead; never return an invisible egg contact for a fitted skin.
			var nearest := Vector3.ZERO
			var best := INF
			for p in hull.sp:
				var q: Vector3 = p - hull.shield_centre()
				if q.distance_squared_to(o) < best:
					best = q.distance_squared_to(o)
					nearest = q
			d = (nearest - o).normalized()
			hit = _shield_tm.intersect_ray(o, d)
		if hit.is_empty():
			# Degenerate aim or an origin inside the skin: a mesh corner is still
			# on the visible surface. Keep its actual face normal.
			var faces := _shield_tm.get_faces()
			var best := INF
			for i in range(0, faces.size(), 3):
				for corner in 3:
					var p := faces[i + corner]
					if p.distance_squared_to(o) < best:
						best = p.distance_squared_to(o)
						hit = {"position": p, "normal": (faces[i+2] - faces[i]).cross(faces[i+1] - faces[i]).normalized()}
		if not hit.is_empty():
			var hp: Vector3 = hit["position"]
			var hn: Vector3 = hit["normal"]
			if hn.dot(d) > 0.0: hn = -hn
			return {"p": xf() * (hp + hull.shield_centre()), "n": (xf().basis * hn).normalized(), "local": hp}
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
	return {"p": xf() * (lp + hull.shield_centre()), "n": (xf().basis * n).normalized(), "local": lp}


func shield_hit(fx, local_p: Vector3, T: float, strength: float, spread: float, life := 0.6) -> void:
	if _shield_mat == null:
		return
	# issue 1239 (F2.5): the shader has six ripple slots. Take a slot whose ripple has finished first, else the one that
	# started earliest, so focused fire (a lance books three) never wipes a ripple that is still to play
	var slot := -1
	var oldest := INF
	for i in 6:
		var w: Vector4 = _hitw[i]
		var h: Vector4 = _hits[i]
		if w.y <= 0.0 or h.w + w.y < fx.now:
			slot = i
			break
		if h.w < oldest:
			oldest = h.w
			slot = i
	_hit_i = slot
	_hits[_hit_i] = Vector4(local_p.x, local_p.y, local_p.z, T)
	_hitw[_hit_i] = Vector4(strength, life, spread * fx.unit, 0)
	_shield_mat.set_shader_parameter("hits", _hits)
	_shield_mat.set_shader_parameter("hitw", _hitw)
	_shield_until = maxf(_shield_until, T + life + 0.05)


# Issue 1078, R340 (Ryan picked it Nov 19 2026): the shield failure is the clean collapse, for every shielded ship of
# every faction and both shield shapes: one even flash, then one band closes from the far side into the breach, a knot
# and a flat ring of sparks. Dev comparison only: rendering/effects/shield_failure (or VS_SHIELD_FAILURE) = "today"
# (the old per-faction break) or "shear" (one connected crack network); rendering/effects/shield_failure_quality="low"
# (or VS_SHIELD_FAILURE_Q=low) gives the shear its cheaper crack network. Anything else plays the collapse.
const FAIL_LOOKS := ["today", "shear", "collapse"]


static func fail_look_setting() -> int:
	var v := OS.get_environment("VS_SHIELD_FAILURE")
	if v.is_empty():
		v = str(ProjectSettings.get_setting("rendering/effects/shield_failure", "collapse"))
	var i := FAIL_LOOKS.find(v)
	return i if i >= 0 else 2


static func fail_low_setting() -> bool:
	var v := OS.get_environment("VS_SHIELD_FAILURE_Q")
	if v.is_empty():
		v = str(ProjectSettings.get_setting("rendering/effects/shield_failure_quality", "high"))
	return v == "low"


# Issue 1239 (F2.1): where the shield gave way. hit_lp is the breaking hit's point on the shield in the shield's own
# frame (relative to hull.shield_centre(), as shield_point gives it); the failure aims there. Without one (a break no
# shot carries: an ion storm, a special, the benches) it aims at the middle of the struck quadrant, as before.
func _break_aim(quad: int, hit_lp: Vector3) -> Vector3:
	if hit_lp.is_finite() and hit_lp.length() > 1e-4:
		return hit_lp.normalized()
	return hull.quad_dir(quad)


func shield_break(fx, quad: int, hit_lp := Vector3.INF) -> void:
	if _shield_mat == null:
		return
	if _fail_look == 1:
		_break_shear(fx, quad, hit_lp)
		return
	if _fail_look == 2:
		_break_collapse(fx, quad, hit_lp)
		return
	var qd: Vector3 = _break_aim(quad, hit_lp)
	var T: float = fx.now
	_shield_mat.set_shader_parameter("brk_t", T)
	_shield_mat.set_shader_parameter("brk_dir", qd)
	_shield_until = maxf(_shield_until, T + 1.45)
	_shield_mat.set_shader_parameter("brk_win", 1.6)
	var rad = hull.shield_radii()
	var contact := shield_point(to_world(hull.shield_centre() + qd * rad.length() * 2.0))
	var lp: Vector3 = contact["local"]
	var wp: Vector3 = contact["p"]
	var wn: Vector3 = contact["n"]
	shield_hit(fx, lp, T, 1.0, rad.length() * 0.8 / fx.unit, 0.9)
	var sc: Color = fac["shield"]
	var st: int = fac["shield_style"]
	var k = scale_k()
	_shield_flash(fx, wp, T, sc.lerp(Color.WHITE, 0.4), 9.0 * k, 8.0, 0.2)
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
		1:
			# Hegemony: the hex lattice shatters into cells that fly apart
			for i in 36:
				fx.spr(wp + fx.rdir() * 5.0 * k, T + fx.rng.randf() * 0.15, 0.6 + fx.rng.randf() * 0.5, sc, 3.0, 0.5 * k, 0.3 * k, 16,
					fx.rcone(wn, 0.9) * (6 + fx.rng.randf() * 10) * k, 0.8)
		2:
			# Corsair: it sputters, flickers and dies in patches, with sparks only (R297).
			for j in 5:
				var tj = T + j * 0.12 + fx.rng.randf() * 0.05
				var pj = wp + fx.rdir() * 4.0 * k
				_shield_flash(fx, pj, tj, sc.lerp(Color(1, 0.6, 0.3), 0.4), 3.0 * k, 4.0, 0.1)
				for i in 8:
					fx.stk(pj, tj, 0.3 + fx.rng.randf() * 0.3, Color(1, 0.6, 0.25), 6.0, 0.05, 0.12, 1, fx.rcone(wn, 1.0) * (8 + fx.rng.randf() * 12) * k, 2.0)
		_:
			# Ithar: the mint veil folds and sheets away in prismatic glints
			for i in 30:
				fx.spr(wp + fx.rdir() * 5.0 * k, T + fx.rng.randf() * 0.5, 1.2 + fx.rng.randf() * 0.8, sc, 2.2, 0.7 * k, 0.2 * k, 16,
					fx.rcone(wn, 1.2) * (2 + fx.rng.randf() * 4) * k, 0.4, 1.5)
			fx.spr(wp, T, 1.0, sc, 1.6, 6.0 * k, 14.0 * k, 18)


# Issue 1078, shear: one crack network runs from the struck side over the whole field (the shader draws it, timed by
# how far each point is from the struck facing); sparks race along the surface with the front, so the failure reads as
# one connected tear, not scattered pops. Each faction keeps its colour and character (R163): the Navy throws lattice
# cells loose as the crack passes, the Hullbreakers' cracks stutter, the Glasswrights' glint.
const SHEAR_FRONT := 0.55   # seconds for the crack front to cross from the struck facing to the far side (shader too)


func _break_shear(fx, quad: int, hit_lp := Vector3.INF) -> void:
	var qd: Vector3 = _break_aim(quad, hit_lp)
	var T: float = fx.now
	_shield_mat.set_shader_parameter("brk_win", 1.6)
	_shield_mat.set_shader_parameter("brk_t", T)
	_shield_mat.set_shader_parameter("brk_dir", qd)
	_shield_until = maxf(_shield_until, T + 1.45)
	_brk_until = maxf(_brk_until, T + SHEAR_FRONT + 0.4)
	var rad = hull.shield_radii()
	var reach: float = rad.length() * 2.0
	var contact := shield_point(to_world(hull.shield_centre() + qd * reach))
	var lp: Vector3 = contact["local"]
	var wp: Vector3 = contact["p"]
	var wn: Vector3 = contact["n"]
	shield_hit(fx, lp, T, 1.0, rad.length() * 0.6 / fx.unit, 0.6)
	var sc: Color = fac["shield"]
	var st: int = fac["shield_style"]
	var k = scale_k()
	var hot := sc.lerp(Color.WHITE, 0.55)
	_shield_flash(fx, wp, T, sc.lerp(Color.WHITE, 0.4), 8.0 * k, 8.0, 0.18)
	fx.light(wp + wn * 2.0, T, 0.7, 6.0, sc, 0)
	fx.shake(T, 0.16, wp)
	# the front: points spread from the contact to the far side, each lit when the front reaches it
	var n := 16 if st != 1 else 12
	for i in n:
		var spread := lerpf(0.25, 2.6, float(i) / float(n - 1))
		var d: Vector3 = (qd + fx.rdir() * spread).normalized()
		var ti: float = T + (1.0 - d.dot(qd)) * 0.5 * SHEAR_FRONT
		var pi := shield_point(to_world(hull.shield_centre() + d * reach))
		var pw: Vector3 = pi["p"]
		var nw: Vector3 = pi["n"]
		var run: Vector3 = (pw - wp).slide(nw)
		run = run.normalized() if run.length() > 1e-3 else fx.rcone(nw, 1.5).slide(nw).normalized()
		var stut := 1.0 if st != 2 else (0.5 + 0.5 * float(i % 2))
		for j in 3:
			fx.stk(pw, ti + j * 0.03, 0.22 + fx.rng.randf() * 0.12, hot, 6.0 * stut, 0.1, 0.12, 1,
				(run + fx.rdir() * 0.25) * (14 + fx.rng.randf() * 10) * k, 2.2)
		if st == 1:
			# Navy: a cell of the lattice comes loose where the crack passes
			fx.spr(pw, ti, 0.6 + fx.rng.randf() * 0.4, sc, 2.6, 0.45 * k, 0.25 * k, 16, (nw + run * 0.5) * (4 + fx.rng.randf() * 4) * k, 0.8)
		elif st == 3:
			# Glasswrights: a prismatic glint rides the crack
			fx.spr(pw, ti, 0.9 + fx.rng.randf() * 0.5, sc, 2.0, 0.6 * k, 0.2 * k, 16, nw * (1.5 + fx.rng.randf() * 2) * k, 0.4, 1.5)


# Issue 1078, collapse: the cleaner failure. The field flashes once, evenly, then one bright band closes over it from the
# far side into the breach and the field pinches out there in a small knot and a flat ring of sparks. No crackle, no
# scattered pops; the faction still shows in colour and in the band's pattern.
# R358 (Ryan, Nov 20 2026, issue 1239 pace sheet): 75% slower than R340's first 0.70 s, so the band stays easy to see
const COLLAPSE_CLOSE := 1.225   # seconds until the band reaches the breach (shader: brk_close)
const COLLAPSE_TAIL := 0.25   # issue 1239: the knot's fade after the close (shader: exp(-kt * 5.0))


# Issue 1239 (Ryan, Nov 20: "close the shield collapse by like 50, 75 or 100% so it's slightly more visible"; he picked
# 75% slower, R358): the close time, for dev comparisons only. rendering/effects/shield_collapse_close (or
# VS_SHIELD_CLOSE), in seconds; the game look is COLLAPSE_CLOSE.
static func collapse_close_setting() -> float:
	var v := OS.get_environment("VS_SHIELD_CLOSE")
	if v.is_empty():
		v = str(ProjectSettings.get_setting("rendering/effects/shield_collapse_close", COLLAPSE_CLOSE))
	var c := float(v)
	return clampf(c, 0.3, 2.0) if c > 0.0 else COLLAPSE_CLOSE


func _break_collapse(fx, quad: int, hit_lp := Vector3.INF) -> void:
	var qd: Vector3 = _break_aim(quad, hit_lp)
	var T: float = fx.now
	var close := collapse_close_setting()
	_shield_mat.set_shader_parameter("brk_t", T)
	_shield_mat.set_shader_parameter("brk_dir", qd)
	_shield_mat.set_shader_parameter("brk_close", close)
	_shield_mat.set_shader_parameter("brk_win", maxf(1.6, close + 0.9))
	_shield_until = maxf(_shield_until, T + maxf(1.45, close + 0.75))
	_brk_until = maxf(_brk_until, T + close + COLLAPSE_TAIL)
	var rad = hull.shield_radii()
	var contact := shield_point(to_world(hull.shield_centre() + qd * rad.length() * 2.0))
	var lp: Vector3 = contact["local"]
	var wp: Vector3 = contact["p"]
	if hit_lp.is_finite() and hit_lp.length() > 1e-4:
		# the knot and its sparks sit where the shot struck, not where the radial ray met the skin (a fitted skin is not
		# convex, so the two can differ)
		lp = hit_lp
		wp = xf() * (hit_lp + hull.shield_centre())
	var wn: Vector3 = contact["n"]
	shield_hit(fx, lp, T, 0.7, rad.length() * 0.3 / fx.unit, 0.5)
	var sc: Color = fac["shield"]
	var k = scale_k()
	_shield_flash(fx, wp, T, sc.lerp(Color.WHITE, 0.3), 6.0 * k, 6.0, 0.15)
	fx.light(wp + wn * 2.0, T, 0.4, 4.0, sc, 0)
	fx.shake(T, 0.12, wp)
	# the knot where the field closes, and its ring of sparks flat along the hull
	var Tk: float = T + close
	# the Glasswrights' pale field needs a bigger knot to read against their pale hulls (matches the shader's band)
	var gk: float = 1.5 if int(fac["shield_style"]) == 3 and not fx.reduce_flashing else 1.0
	_shield_flash(fx, wp, Tk, sc.lerp(Color.WHITE, 0.5), 5.0 * k * gk, 7.0, 0.14)
	fx.light(wp + wn * 1.5, Tk, 0.35, 5.0 * gk, sc, 0)
	var t1: Vector3 = wn.cross(Vector3.UP if absf(wn.y) < 0.9 else Vector3.RIGHT).normalized()
	var t2: Vector3 = wn.cross(t1)
	for i in 18:
		var a: float = TAU * (float(i) + fx.rng.randf() * 0.4) / 18.0
		var v: Vector3 = (t1 * cos(a) + t2 * sin(a) + wn * 0.15) * (10 + fx.rng.randf() * 6) * k
		fx.stk(wp, Tk, 0.25 + fx.rng.randf() * 0.1, sc.lerp(Color.WHITE, 0.4), 5.0, 0.08, 0.12, 1, v, 2.5)


# Match pop's comfort booking and soft fallback, without its free-standing disc.
func _shield_flash(fx, p: Vector3, T: float, col: Color, size: float, intensity: float, life: float) -> void:
	if fx.flash_at(p, T, size, SH.flash_sprite_floor(0, 0.0), life):
		fx._emit_spr(p, T, life, col, intensity, size * 0.6, size, 0)
	else:
		fx.spr(p, T, maxf(life * 3.0, 0.4), col, minf(intensity, 3.0) * 0.4, size * 0.5, size * 1.2, 18)


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
var react_clock := 0.0          # seconds of reaction integrated so far (issue 1467: the frame-rate check reads it)


# A hit's physical reaction. impulse: the weapon's momentum (fx_weapons.REACT_IMPULSE: torpedoes and rams shove,
# shells and slugs kick, lances and ions barely at all); lp, ldir: hit point and shot direction in the ship frame.
func hit_react(fx, impulse: float, lp: Vector3, ldir: Vector3) -> void:
	if dead or gone or impulse <= 0.0:
		return
	# Issue 462: where the last hit landed (hull space), so a death can open its tear from the side that was hit.
	set_meta("last_hit", [lp, ldir, fx.now])
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
	# Issue 1467: integrate the whole frame in steps of at most 1/30 s, each on its own clock, so a slow frame keeps
	# the same recoil timeline as a fast one (one step at 30 fps and above; a 15 fps frame takes two).
	var steps := clampi(ceili(dt * 30.0 - 1e-6), 1, 8)
	var h := minf(dt, 8.0 / 30.0) / float(steps)
	for si in steps:
		_react_integrate(fx.now - h * float(steps - 1 - si), h, wi)
	_react_apply(fx, wi)


func _react_integrate(t: float, h: float, wi: int) -> void:
	react_clock += h
	# 1. onset: deliver the kick over REACT_ONSET (about 95% of it inside that time)
	var f := 1.0 - exp(-h * 3.0 / float(REACT_ONSET[wi]))
	_rv += _kick_v * f
	_kick_v *= 1.0 - f
	_pv += _kick_p * f
	_kick_p *= 1.0 - f
	var wr: float = REACT_RECOVER[wi]
	if t >= _brk_at:
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


func _react_apply(fx, wi: int) -> void:
	var age: float = fx.now - _shud_t
	var sh := _shud * exp(-age / float(REACT_SHUDDER_T[wi]))
	var w_sh: float = TAU * float(REACT_SHUDDER_HZ[wi])
	var shx := sh * sin(age * w_sh + 1.3)
	var shz := sh * 0.7 * sin(age * w_sh * 1.27)
	_rcs(fx)
	var busy: bool = root.has_method("busy") and bool(root.call("busy"))
	# Keep the cinematic flight bank under the damage reaction.
	var flight_bank := float(root.get("glide_bank")) if root.get("glide_bank") != null else 0.0
	flight_bank += _list   # issue 1235: a crippled ship's list stays under the hit reaction
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
		# Issue 281 run 7: a hull that does not fill its bounding box (the Eclipse disc and tower) leaves the box
		# corner in empty space, so the old corner puff floated off the ship. Issue 370: the corner only picks the jet;
		# the attach point service starts it at the authored hp_rcs nearest that corner, else on the plating a ray
		# finds on the line from the corner to the hull centre (the run 7 ray), else nowhere (skipped and counted).
		var outward: Vector3 = rp - hull.c
		var h: Dictionary = hull.jet(rp, hull.c, outward)
		if h.is_empty():
			continue
		var wp: Vector3 = to_world(h["p"])
		var n: Vector3 = h["n"]
		# The gas blows away from the plating, never into the hull.
		var gd: Vector3 = -t
		if gd.dot(n) < 0.15:
			gd = n
		var gv: Vector3 = dir_world(gd) * (5.0 + fx.rng.randf() * 3.0) * k
		fx.record_spawn(self, wp)
		fx.spr(wp, fx.now, 0.35, Color(0.85, 0.88, 0.95), 0.6, 0.12 * k, 0.9 * k, 7, gv, 2.5)
		fx.spr(wp, fx.now, 0.06, Color(0.9, 0.95, 1.0), 1.5, 0.08 * k, 0.15 * k, 18)


# ---------------------------------------------------------------- hull wear and the crippled list (issue 1235)

# Neon's damage audit F1.2: as hull HP falls the whole ship looks worn, not only its breach anchors. hull_wear (0 above
# WEAR_FROM of max HP, 1 at WEAR_FULL) drives, through HULL.set_wear, the damage shader's own uniforms (fx_hull.gd DAMAGE_UNIFORMS): fx_weather
# darkens and mottles the plating, fx_power dims the hull's lights and glowing panels, and fx_scorch lays soot patches
# where the ship was actually hit (wear_patches). The scorch heat stays 0 on a live ship, so no faction gets orange
# embers from this (the faction's own wound colour stays on its marks and holes). Below LIST_FROM of max HP the hull
# lists LIST_MIN to LIST_MAX degrees about its bow toward the side last hit: the view only, the rules never see it.
const WEAR_FROM := 0.8
const WEAR_FULL := 0.2
const LIST_FROM := 0.35
const LIST_MIN := 2.0        # degrees, at LIST_FROM
const LIST_MAX := 5.0        # degrees, near 0 HP
const LIST_T := 2.5          # seconds for the list to settle
var hull_wear := 0.0
var _wear_shown := -1.0
var _wear_marks := -1
var list_target := 0.0       # radians about the bow
var _list := 0.0
# the side (+1 starboard, -1 port) of the last HULL hit, set only by add_mark (a shield-only hit never reaches it;
# Sol review of PR 1570: hit_react's last_hit also takes shield hits); 0 while unknown (a view rebuilt after Continue)
var _hull_side := 0.0
var _list_side := 0.0        # held from the moment the list starts until the ship is repaired above LIST_FROM


func _set_wear(fx, hpf: float) -> void:
	if squadron or weight <= 0:
		return
	hull_wear = clampf((WEAR_FROM - hpf) / (WEAR_FROM - WEAR_FULL), 0.0, 1.0)
	if hpf < LIST_FROM and hpf > 0.0:
		var k := clampf((LIST_FROM - hpf) / LIST_FROM, 0.0, 1.0)
		# the side is picked once, when the list starts, and held (no flip on every later hit): the last hull hit's
		# side, or, when no hull hit is known (a view rebuilt after Continue), a fixed side from the ship's id, so the
		# same ship always leans the same way
		if _list_side == 0.0:
			_list_side = _hull_side if _hull_side != 0.0 else (1.0 if posmod(_seed, 2) == 0 else -1.0)
		list_target = deg_to_rad(lerpf(LIST_MIN, LIST_MAX, k)) * _list_side
	else:
		list_target = 0.0
		_list_side = 0.0
	# a refresh also whenever wear reaches or leaves zero (Sol review: a small last repair left fx_weather at 0.0075)
	if absf(hull_wear - _wear_shown) > 0.02 or _wear_marks != _marks.size() or ((hull_wear == 0.0) != (_wear_shown == 0.0)):
		if hull_wear > 0.0:
			ensure_damage_surfaces(fx)   # Neon on PR 1631: spread damage can wear a hull before any section breaches
		_apply_wear()


# Issue 1587 (Neon on PR 1631): the hull's lights (fx_flick, the wear) live on its damage surfaces, which only a breach used
# to build. A fresh or lightly hit hull gets them here once, with no mouths (no holes): the same materials a first breach
# makes, so the brownout and the wear show before any section is cut.
func ensure_damage_surfaces(fx) -> void:
	if not _damage_surfaces.is_empty() or dead or gone or squadron or hull == null or fx == null or fx.compat:
		return
	BREACH._inside_overlay(fx, self, meshes, [], fac.get("damage_glow", Color(1.0, 0.45, 0.12)))
	_power_shown = -1.0
	_wear_shown = -1.0


# Push the wear onto every damage surface this ship has now (a rebuild applies it to new ones in fx_breach).
func _apply_wear() -> void:
	_wear_shown = hull_wear
	_power_shown = -1.0     # issue 1587: new surfaces get the flicker (fx_flick) on the next frame
	_wear_marks = _marks.size()
	var patches := wear_patches()
	for key in _damage_surfaces:
		var entry: Array = _damage_surfaces[key]
		if entry.size() > 1 and entry[1] is ShaderMaterial:
			HULL.set_wear(entry[1], hull_wear, patches)


# Soot patches on the sides that were hit: per hurt section (worst first), up to WEAR_PATCHES_SEC of its drawn marks,
# heavy then newest, one patch per spot (marks closer than a patch merge); at most 8 on the ship (the shader's array).
const WEAR_PATCHES_SEC := 3
func wear_patches() -> Array:
	var out: Array = []
	if hull_wear <= 0.0 or hull == null:
		return out
	var L: float = hull.L
	var secs := [0, 1, 2]
	secs.sort_custom(func(a: int, b: int) -> bool: return section_fraction[a] < section_fraction[b])
	for sec in secs:
		var f: float = section_fraction[sec]
		if f >= WEAR_FROM:
			continue
		var hurt := clampf((WEAR_FROM - f) / (WEAR_FROM - WEAR_FULL), 0.0, 1.0)
		var R: float = L * (0.045 + 0.06 * hurt) * (0.6 + 0.4 * hull_wear)
		var idx: Array = []
		for j in _marks.size():
			if _marks[j].sec == sec:
				idx.append(j)
		idx.sort_custom(func(a: int, b: int) -> bool:
			var ha := _heavy_mark(_marks[a])
			var hb := _heavy_mark(_marks[b])
			if ha != hb:
				return ha
			return a > b)
		var n := 0
		for j in idx:
			if n >= WEAR_PATCHES_SEC or out.size() >= 8:
				break
			var c: Vector3 = _marks[j].c
			var near := false
			for q in out:
				if Vector3(q.x, q.y, q.z).distance_to(c) < R * 0.8:
					near = true
					break
			if near:
				continue
			out.append(Vector4(c.x, c.y, c.z, R))
			n += 1
	return out


func _list_step(dt: float) -> void:
	if absf(list_target - _list) < 1e-5:
		return
	var prev := _list
	_list += (list_target - _list) * (1.0 - exp(-dt * 3.0 / LIST_T))
	if absf(list_target - _list) < 1e-4:
		_list = list_target
	if not _reacting and is_instance_valid(root):
		root.rotation.x += _list - prev


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
	_set_wear(fx, hpf)
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
			var was: int = int(stage[i])
			if int(stage[i]) == 4 and int(want[i]) < 4:
				_patch_time[i] = fx.now
			_scar_stage[i] = maxi(_scar_stage[i], stage[i])
			stage[i] = int(want[i])
			_build_section(fx, i, up)
			# issue 1587: a hit that pushes a section into stage 3 or 4 vents it once (never on the ship's first stage
			# update, which is its state as it arrives: a view rebuilt with the damage already there)
			if up and _stages_seen and ((was < 3 and stage[i] >= 3) or (was < 4 and stage[i] == 4)):
				_blowout(fx, i)
	_stages_seen = true

	_refresh_wounds(fx)
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
		# issue 370: where the hull opens comes from the section's authored breach anchors (hp_breach_*): "a" the main
		# hole on the first, "b" the second hole on the next one that faces part way up. Else, and for the secondary
		# scorches ("sc0" to "sc2", marks on the plate, not openings), a seen surface sample: a ray hit, as before.
		var h: Dictionary = {}
		if kind == "a":
			h = hull.breach_point(i, 0)
		elif kind == "b":
			h = hull.breach_point(i, 1, Vector2(0.15, 0.75))
		if h.is_empty():
			h = hull.surface_sample(i, 2.5, "breach" if kind in ["a", "b"] else "scorch")
			if kind == "b" and not h.is_empty():
				for t in 32:
					var c: Dictionary = hull.random_sample(i, 0.0)
					var ny = (c["n"] as Vector3).y
					if ny > 0.15 and ny < 0.75:
						h = {"p": c["p"], "n": c["n"]}
						break
		if h.is_empty():
			return {}
		if kind in ["a", "b"]:
			h = _off_turrets(h, hull.L * BREACH.STAGE4_HOLE_L, i)
			if h.is_empty():
				_anchors[key] = {}   # no clear plating: this anchor opens nothing (kept, so it is not searched again)
				return {}
		_anchors[key] = {"p": h["p"], "n": h["n"], "t": {}}
	return _anchors[key]


# Issue 1235 (Board review of PR 1245): turret meshes take no baked damage (they turn), so a stage 4 hole opened under a
# turret's foot would leave the whole turret standing over the hole. A breach anchor inside any turret's footprint (its
# meshes' box seen from above, at rest, plus the hole's radius) is moved: first to points round the footprints it is in,
# cast back onto the plating, then to other plating samples of its section; every candidate is checked against EVERY
# footprint (Artoo, PR 1245: two seats side by side could push it from one into the other). If no clear spot is found
# the section opens no hole there ({}), never one under a turret.
func _off_turrets(h: Dictionary, R: float, sec := -1) -> Dictionary:
	if _clear_of_turrets(h["p"], R):
		return h
	var nn: Vector3 = h["n"]
	var p0: Vector3 = h["p"]
	for f in turret_feet():
		var c: Vector3 = f[0]
		var rad: float = float(f[1]) + R * 1.15
		if Vector2(p0.x - c.x, p0.z - c.z).length() >= rad:
			continue
		var d0 := Vector3(p0.x - c.x, 0.0, p0.z - c.z)
		var a0 := atan2(d0.z, d0.x) if d0.length() > 1e-3 else 0.0
		for k in 16:
			var an := a0 + (k + 1) / 2 * (TAU / 16.0) * (1.0 if k % 2 == 0 else -1.0)
			for grow in [1.0, 1.5, 2.2]:
				var q := Vector3(c.x + cos(an) * rad * grow, p0.y, c.z + sin(an) * rad * grow)
				var hit: Dictionary = hull.ray(q + nn * hull.L, -nn)
				if not hit.is_empty() and _clear_of_turrets(hit["p"], R):
					return {"p": hit["p"], "n": hit["n"]}
	if sec >= 0:
		for t in 48:
			var c2: Dictionary = hull.random_sample(sec, 0.0)
			if not c2.is_empty() and (c2["n"] as Vector3).dot(nn) > 0.3 and _clear_of_turrets(c2["p"], R):
				return {"p": c2["p"], "n": c2["n"]}
	return {}


func _clear_of_turrets(p: Vector3, R: float) -> bool:
	for f in turret_feet():
		var c: Vector3 = f[0]
		if Vector2(p.x - c.x, p.z - c.z).length() < float(f[1]) + R * 1.15 - 1e-4:
			return false
	return true


var _feet: Array = []
var _feet_done := false


# Each turret's footprint at rest in the ship frame: [centre, radius], from its meshes' boxes.
func turret_feet() -> Array:
	if _feet_done:
		return _feet
	_feet_done = true
	if hull == null or not ("turrets" in hull) or not is_instance_valid(root):
		return _feet
	var inv: Transform3D = root.global_transform.affine_inverse()
	for t in hull.turrets:
		var node = t.get("node")
		if not is_instance_valid(node):
			continue
		var box := AABB()
		var any := false
		for m in (node as Node).find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			if mi.mesh == null:
				continue
			var b: AABB = (inv * mi.global_transform) * mi.mesh.get_aabb()
			box = b if not any else box.merge(b)
			any = true
		if any:
			var cen := box.get_center()
			_feet.append([cen, 0.5 * Vector2(box.size.x, box.size.z).length()])
	return _feet


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
	if a.is_empty(): return out   # issue 370: a hull with no plating has nowhere to show damage
	var sc = BREACH.surface(a.p, a.n, L * (0.03 + 0.034 * grade), sd + 0.7, BREACH.S_SCORCH)
	sc.t0 = _t0(a, -grade, fx)
	sc.sec = i
	sc.heat = [0.0, 0.22, 0.35, 0.55, 0.75][grade] * (0.45 if st < scar else 1.0)
	out.append(sc)
	# Stable samples: increasing a stage never moves the earlier secondary burns.
	for j in mini(grade, 3):
		var h := _anchor(i, "sc%d" % j)
		if h.is_empty(): continue
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
	var e = BREACH.hole(hull, a.p, a.n, L * BREACH.STAGE4_HOLE_L, 1.0, 0.14, sd)
	e.t0 = _t0(a, st, fx)
	e.sec = i
	if faction == "chorus":
		e.bend = 0.35; e.w = e.R * 0.22; e.buckle = 0.035
	out.append(e)
	if weight >= 2:
		var bt = _anchor(i, "b")
		if bt.is_empty(): return out
		var eb = BREACH.hole(hull, bt.p, bt.n, L * BREACH.STAGE4_HOLE_L, 1.0, 0.12, sd + 2.1)
		eb.t0 = _t0(bt, st, fx)
		eb.sec = i
		out.append(eb)
	return out


# The weapon marks drawn now: per section at most [2, 2, 3, 4, 4][stage] (all of them on a repaired, scarred section).
# Issue 1235 (Neon audit F1.3): the cap kept the OLDEST marks, so after two early grazes a later torpedo was stored,
# rebuilt for, and never drawn. Heavy marks (blast, ion, ram, a weight 3+ weapon) come first, then the newest; the
# kept marks are returned in their stored order, so the rebuilt geometry does not reshuffle.
func visible_marks(fx) -> Array:
	var pick := {}
	for sec in 3:
		var cap: int = int(round(float([2, 2, 3, 4, 4][stage[sec]]) * fx.cap_k))
		if _scar_stage[sec] > stage[sec]:
			cap = 1 << 20
		var idx: Array = []
		for j in _marks.size():
			if _marks[j].sec == sec:
				idx.append(j)
		idx.sort_custom(func(a: int, b: int) -> bool:
			var ha := _heavy_mark(_marks[a])
			var hb := _heavy_mark(_marks[b])
			if ha != hb:
				return ha
			return a > b)
		for k in mini(cap, idx.size()):
			pick[idx[k]] = true
	var out: Array = []
	for j in _marks.size():
		# a mark with no hull section (one placed by hand, not through add_mark) is never capped
		if pick.has(j) or int(_marks[j].sec) < 0 or int(_marks[j].sec) > 2:
			out.append(_marks[j])
	return out


static func _heavy_mark(e) -> bool:
	return e.style in [BREACH.S_BLAST, BREACH.S_ION, BREACH.S_RAM] or int(e.wt) >= 3


# Rebuild the hull from its original arrays with every section's damage, on a worker thread; apply when done.
func _dmg_request(fx) -> void:
	if fx.get("closed") == true:   # issue 1435: a released fx takes no new jobs
		return
	if _dmg_task >= 0:
		_dmg_dirty = true
		return
	var ents: Array = []
	for i in 3:
		ents.append_array(_ents[i])
	ents.append_array(visible_marks(fx))
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
func add_mark(fx, look: String, w: int, lp: Vector3, ln: Vector3, ldir: Vector3, hatch_k := 1.0) -> void:
	if squadron or weight <= 0 or dead or gone:
		return
	_mark_n += 1
	var t_m := Time.get_ticks_usec()
	var es: Array = BREACH.marks_for(hull, look, w, lp, ln, ldir, float(posmod(_seed, 997)) * 0.013 + _mark_n * 1.37, faction, 1.0, 1.0 - section_fraction[hull.section_of(lp.x)], hatch_k)
	if es.is_empty():
		return
	if absf(lp.z) > 1e-3:
		_hull_side = signf(lp.z)
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
			var es2: Array = BREACH.marks_for(hull, o.look, maxi(o.wt, e.wt), o.hit_origin, o.hit_normal, o.ldir, o.seed_v, faction, g, 1.0 - section_fraction[o.sec], o.hatch_k)
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
	if in_sec.size() > int(BREACH.SEC_MARK_CAP * fx.cap_k):
		var drop = in_sec[0]
		for o in in_sec:
			if o != e and o.style in [BREACH.S_SHELL, BREACH.S_FLAK]:
				drop = o
				break
		_marks.erase(drop)
	while _marks.size() > int(BREACH.MARK_CAP * fx.cap_k):
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


# Read a hull surface once per battle. Fragments keep sampling these original
# UVs even when the damage rebuild and death cut need the changed surface.
var _arr_cache := {}


func arrays_of(am: ArrayMesh, si: int) -> Array:
	var key := [am.get_instance_id(), si]
	if not _arr_cache.has(key):
		_arr_cache[key] = am.surface_get_arrays(si)
	return _arr_cache[key]


func damage_surface(fx, mi: MeshInstance3D, si: int, src: Material) -> ShaderMaterial:
	var template: ShaderMaterial = fx.hull_damage_template(src, hull.L, faction == "chorus")
	var key := [mi.get_instance_id(), si]
	var entry: Array = _damage_surfaces.get(key, [])
	if entry.is_empty() or entry[0] != template:
		entry = [template, template.duplicate()]
		_damage_surfaces[key] = entry
	return entry[1]


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
	if a.is_empty(): return
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


# Issue 232 E12/E13: the caps are now the 4x step measured on the #207 gate scene (the old EVE-derived 1x caps are in
# the fx stress README). The renderer's three sections per ship bound the live count long before these caps, so the
# visible board stays at the measured 2x/4x row; the 4x value is the measured-safe ceiling, not a new art pass.
func damage_caps(k := 1.0) -> Vector2i:
	var c := Vector2i(4, 8) if weight <= 1 else (Vector2i(8, 12) if weight == 2 else Vector2i(12, 16))
	return Vector2i(maxi(1, int(round(c.x * k))), maxi(1, int(round(c.y * k))))


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
	var caps := damage_caps(fx.cap_k)
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
		# issue 1587: a jammed turret's thin smoke wisp takes a smoke slot (the class caps hold)
		for i in _jammed:
			if smoke < caps.y:
				desired.append({"id": "wisp%d" % i, "kind": "smoke", "sec": i, "st": stage[i], "tur": int(_jammed[i]["k"])})
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
	if e.has("tur"):
		_build_wisp(fx, e)
		return
	var a := _anchor(e.sec, "a")
	if a.is_empty(): return
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


# ---------------------------------------------------------------- live wounds (issue 1587)
# Neon's Nov 21-22 hull FX audit (issue 1587, Refs #1239 Top 6): a wounded ship looks like a failing warship, not a dimmed
# mesh. View only; the rules never see any of it. Everything here is one-shot pool sprites or a uniform write, except the
# jammed turret's wisp, which takes one of the ship's smoke slots (damage_caps), so steady-state counts do not grow.
#   - engine section at stage 3+: one nozzle (sick_nozzle) gutters with gaps and a plume SICK_LEN as long, and coughs smoke
#     as the ship starts to move
#   - mid or prow section at stage 3+: one turret there freezes off its aim and sags (fx_hull jam_turret), trails a thin
#     wisp and pops a spark every 2 to 4 s; the hull's lights flicker unevenly (fx_flick, multiplied onto the wear's fx_power)
#   - a hit that pushes a section into stage 3 or 4: a one-shot blowout jet of vapour and a few tumbling bits
#   - an ion hull hit: power_dip browns the hull's lights out for half a second (fx_weapons _beam_burn)
const SICK_LEN := 0.6          # the sick nozzle's plume length against the others (the brief: about 40% shorter)
const COUGH_GAP := 0.7         # seconds between two coughs of the sick nozzle
const BLOWOUT_LIFE := 1.2


# The sick nozzle's gate (0 to 1) at time t: a steady stutter of dropouts (about a fifth of each cycle near dark) plus a fast
# gutter. Gentler under reduce flashing: no dropouts, a slow sway.
func sick_gate(t: float, reduce := false) -> float:
	var sf := float(posmod(_seed, 997)) * 0.013
	if reduce:
		return 0.6 + 0.15 * sin(t * 3.1 + sf)
	var cyc := fposmod(t * 1.7 + sf, 1.0)
	if cyc < 0.22:
		return 0.12
	var fl := fposmod(sin(t * 29.0 + sf * 7.0) * 43758.5, 1.0)
	return 0.62 + 0.38 * fl


# The sick nozzle coughs as the ship starts to move: smoke (the faction's own kind of smoke) and a few sputter sparks.
func _cough(fx) -> void:
	_cough_next = fx.now + COUGH_GAP
	var nz: Dictionary = hull.nozzles[sick_nozzle]
	var r: float = nz["r"]
	var p := to_world(nz["p"])
	var d := dir_world(nz.get("d", Vector3(-1, 0, 0))).normalized()
	var eng: Color = fac["engine"]
	var glow: Color = fac["damage_glow"]
	if faction != "ithar":
		var col := Color(0.06, 0.05, 0.045)
		var kind := 3
		if faction == "deathless":
			col = Color(0.055, 0.025, 0.09); kind = 8
		elif faction == "chorus":
			col = glow * 0.45; kind = 20
		for j in 4:
			fx.spr(p + d * r * 0.5, fx.now + j * 0.06, 0.9 + 0.2 * fx.rng.randf(), col, 0.55, r * 1.1, r * 4.2, kind,
				fx.rcone(d, 0.35) * r * (5.0 + 3.0 * fx.rng.randf()), 2.0)
	for j in 5:
		fx.stk(p + d * r * 0.4, fx.now + fx.rng.randf() * 0.12, 0.18 + 0.12 * fx.rng.randf(), eng.lerp(Color.WHITE, 0.3), 3.0,
			0.06, 0.08, 1, fx.rcone(d, 0.6) * r * (8.0 + 6.0 * fx.rng.randf()), 2.0)
	_wlog(["cough", sick_nozzle, fx.now])


func _wlog(e: Array) -> void:
	if wound_log_on:
		wound_log.append(e)


# Jam one turret in each mid or prow section at stage 3+, free it when the section is repaired below 3.
func _refresh_wounds(fx) -> void:
	if hull == null:
		return
	for sec in [1, 2]:
		var hurt: bool = not squadron and int(stage[sec]) >= 3
		if hurt and not _jammed.has(sec):
			var ks: Array = []
			for k in hull.turrets.size():
				if hull.turret_section(k) == sec and not hull.turret_jammed(k):
					ks.append(k)
			if ks.is_empty():
				continue
			var h := absi(_seed + sec * 7919)
			var k: int = ks[h % ks.size()]
			var off := (12.0 + float(h % 13)) * (1.0 if (h >> 4) % 2 == 0 else -1.0)
			var droop := 4.0 + float((h >> 6) % 4)
			hull.jam_turret(k, hull.turret_yaw(k, fx.now) + off, droop, fx.now)
			_jammed[sec] = {"k": k, "next": fx.now + 1.0 + fx.rng.randf() * 2.0}
		elif not hurt and _jammed.has(sec):
			hull.unjam_turret(int(_jammed[sec]["k"]), fx.now)
			_jammed.erase(sec)


func jammed_turrets() -> Array:
	var out: Array = []
	for sec in _jammed:
		out.append(int(_jammed[sec]["k"]))
	return out


# A jammed turret's wisp: a thin looping smoke from its base (a damage emitter entry, so it fades and frees like one).
func _build_wisp(fx, e: Dictionary) -> void:
	var k: int = e["tur"]
	var p: Vector3 = (hull.turrets[k]["xf"] as Transform3D).origin + Vector3.UP * hull.L * 0.01
	var glow: Color = fac.damage_glow
	var kind := 3
	var color := Color(0.15, 0.14, 0.13)
	var intensity := 0.26
	if faction == "deathless": color = Color(0.055, 0.025, 0.09); kind = 8
	if faction == "chorus": color = glow * 0.45; kind = 20
	if faction == "ithar": color = glow * 0.7; kind = 7; intensity = 0.18
	var life := 2.2
	var count := 3
	var v: Vector3 = Vector3.UP * hull.L * 0.05
	var b := POOLS.Batch.new()
	for j in count:
		b.add(POOLS.quad_shape(), POOLS.pack(Vector4(p.x, p.y, p.z, fx.now - life + float(j) / count * life),
			Vector4(v.x, v.y, v.z, life), Vector4(color.r, color.g, color.b, intensity),
			Vector4(hull.L * 0.004, hull.L * 0.022, kind, j * 0.211), Vector4(life, 0, 0, 0.1)))
	var holder := Node3D.new()
	holder.name = "fx_damage_" + String(e.id)
	_dmg_root.add_child(holder)
	var material: ShaderMaterial = fx.mat(SH.SPRITE, 1, "#define SOFT\n" if fx.quality != "low" else "")
	b.build(material, holder, "fx_turret_wisp")
	e["node"] = holder
	e["mat"] = material
	e["particles"] = b.particle_count
	e["sprite_kind"] = kind
	e["source"] = p


# Every frame: spark pops on jammed turrets and the hull's uneven power (fx_flick: the damage shader multiplies it onto
# the wear's steady fx_power, so the wear and the death fade keep their own uniform). Written only when it changes.
func _wound_step(fx) -> void:
	if gone:
		return
	if dead:
		_write_flick(1.0)
		return
	for sec in _jammed:
		var jm: Dictionary = _jammed[sec]
		if fx.now < float(jm["next"]):
			continue
		jm["next"] = fx.now + 2.0 + fx.rng.randf() * 2.0
		var k: int = jm["k"]
		var p := to_world((hull.turrets[k]["xf"] as Transform3D).origin)
		var sc := Color(0.75, 0.85, 1.0)
		for j in 4:
			fx.stk(p, fx.now + fx.rng.randf() * 0.05, 0.2 + fx.rng.randf() * 0.15, sc, 4.0, 0.05, 0.08, 1,
				(fx.rdir() + Vector3.UP * 0.6).normalized() * hull.L * (0.08 + 0.06 * fx.rng.randf()), 2.0)
		if not fx.reduce_flashing:
			fx.light(p, fx.now, 0.15, 1.5, sc, 1)
		_wlog(["spark", k, fx.now])
	_write_flick(power_flicker(fx.now, fx.reduce_flashing))


func _write_flick(f: float) -> void:
	if f == _power_shown or _damage_surfaces.is_empty():
		return
	_power_shown = f
	for key in _damage_surfaces:
		var entry: Array = _damage_surfaces[key]
		if entry.size() > 1 and entry[1] is ShaderMaterial:
			(entry[1] as ShaderMaterial).set_shader_parameter("fx_flick", f)


# The power multiplier (1 steady) at time t: with mid or prow at stage 3+, uneven brownouts in steps of 1/12 s (a small dip
# most of the time, now and then a deep one); an ion dip holds it low. Under reduce flashing, slower and shallower steps.
func power_flicker(t: float, reduce := false) -> float:
	var f := 1.0
	if not squadron and (int(stage[1]) >= 3 or int(stage[2]) >= 3):
		var rate := 4.0 if reduce else 12.0
		var n := fposmod(sin(floorf(t * rate) * 12.9898 + float(posmod(_seed, 991))) * 43758.5453, 1.0)
		if n > 0.9:
			f = 0.8 if reduce else 0.5
		elif n > 0.7:
			f = 0.9 if reduce else 0.78
		elif n > 0.45:
			f = 0.95 if reduce else 0.9
	if t < _power_dip_until:
		f = minf(f, 0.7 if reduce else 0.35)
	return f


# An ion hit browns the hull out for dur seconds (fx_weapons _beam_burn).
func power_dip(fx, dur := 0.5) -> void:
	if dead or gone:
		return
	ensure_damage_surfaces(fx)   # Neon on PR 1631: an ion hit on a fresh hull browns it out too
	_power_dip_until = maxf(_power_dip_until, fx.now + dur)
	_wlog(["power_dip", -1, fx.now])


# A section pushed into stage 3 or 4 vents once: a 1.2 s jet of bright vapour along its breach normal, 3 or 4 tumbling
# interior bits and a soft light. One-shot pool sprites only.
func _blowout(fx, i: int) -> void:
	if squadron or hull == null:
		return
	var a := _anchor(i, "a")
	if a.is_empty():
		return
	var p := to_world(a.p)
	var n := dir_world(a.n).normalized()
	var L: float = hull.L
	var glow: Color = fac.damage_glow
	var col := glow.lerp(Color.WHITE, 0.75)
	var kind := 7
	if faction == "chorus":
		col = glow * 0.6; kind = 20
	var heavy := int(stage[i]) == 4
	for j in 7:
		var t: float = fx.now + j * 0.08
		fx.spr(p + n * L * 0.01, t, BLOWOUT_LIFE - j * 0.08, col, 0.55 if heavy else 0.45, L * 0.008, L * (0.06 if heavy else 0.045),
			kind, fx.rcone(n, 0.22) * L * (0.38 - j * 0.03), 1.6)
	for j in 3 + posmod(_seed + i, 2):
		fx.shd(p, fx.now + j * 0.05, 1.6, fx.rcone(n, 0.6) * L * (0.10 + 0.05 * fx.rng.randf()), L * 0.006, 0.5)
	fx.light(p + n * L * 0.03, fx.now, 0.35, 2.5, glow.lerp(Color.WHITE, 0.5), 1)
	_wlog(["blowout", i, fx.now])


# ---------------------------------------------------------------- small events

func pulse(fx, strength: float) -> void:
	var c: Color = fac["weapon"]
	var cp: Dictionary = hull.core_point()   # issue 370: the ship's own pulse starts at its core
	if cp.is_empty():
		return
	var p = to_world(cp["p"])
	var k = scale_k()
	fx.ring(p, dir_world(Vector3.UP), fx.now, 0.9, c, 1.2 * strength, hull.L * 0.3, hull.L * 0.9, 2)
	fx.spr(p, fx.now, 0.8, c, 1.0 * strength, hull.L * 0.4, hull.L * 0.8, 18)
	fx.light(p, fx.now, 0.7, 3.0 * strength, c, 1)


func tick_flare(fx, kind: String) -> void:
	var h: Dictionary = hull.surface_sample(-1, 0.5, "flare")   # issue 370: a seen point on the plating, or none
	if h.is_empty():
		return
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
	if dead or gone:
		return
	var T: float = fx.now
	var bow = dir_world(Vector3(1, 0, 0))
	var c: Color = fac["engine"]
	var p = to_world(hull.core)   # issue 370: the jump flash at the core (hp_core, else the centre of volume)
	for t in hull.nozzles:
		var np = to_world(t["p"])
		fx.spr(np, T, 0.5, c, 6.0, 2.0, 8.0, 2)
	fx.light(p, T, 0.6, 6.0, c, 0)
	fx.stk(p, T + 0.35, 0.4, c.lerp(Color.WHITE, 0.5), 10.0, hull.L * 3.0, hull.W * 0.4, 0, bow * hull.L * 20.0)
	fx.ring(p, bow, T + 0.35, 0.6, c, 1.5, hull.L * 0.2, hull.L * 1.2, 1)
	fx.later(T + 0.4, func l_jump() -> void:
		if fx.ships.get(id) == self and not dead and not gone:
			_hide_meshes()
			teardown(fx, false))  # damage polling can finish its own job; do not block the jump frame


# A mark's geometry follows the section's actual damage, including repairs.
# Recreate entries rather than mutating entries a worker may be reading.
func _regrade_marks(fx) -> void:
	var changed := false
	var updated: Array = []
	for e in _marks:
		var damage: float = 1.0 - section_fraction[e.sec]
		# issue 1235 (F1.1): regrade only when the size really changes (a repair, or a section badly hurt since), so
		# the sync right after a volley does not rebuild the hull a second time for a few percent
		if absf(BREACH.mark_scale(e.section_damage) - BREACH.mark_scale(damage)) > 0.05:
			var entries := BREACH.marks_for(hull, e.look, e.wt, e.hit_origin, e.hit_normal, e.ldir, e.seed_v, faction, e.grow, damage, e.hatch_k)
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
