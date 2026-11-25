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
const WOUNDS := preload("res://fx/fx_wounds_flag.gd")
const IDLE := preload("res://fx/fx_idle.gd")
const DAMAGE_PLUME := preload("res://fx/fx_damage_plume.gd")
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
var hull_pivot: Node3D
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
var _power_shown := -1.0
var _stages_seen := false   # the first stage update is the ship's state as it arrives (a rebuilt view): no blowout
# one-shot wound events for the checks only ([kind, section or nozzle, time]); off in play (Artoo on PR 1631)
var wound_log_on := false
var wound_log: Array = []
var _eng_sputter = false
# Issue 1741 Milestone 3 (R416, Wounds V2, behind VS_WOUNDS_V2=1): what the rules actually took, shown on the hull. The
# knocked-out weapon slots jam their own turrets and kill their own fixed mounts; the drive fails in tiers; a shield
# generator that is out crackles on the midship hull. View only: it reads the view (weapons[i].off, sec, engHit, shieldOff).
var wounds_v2 := wounds_v2_setting()
var eng_tier := 0               # 0 healthy, 1 engine hit or eng stage 2, 2 eng stage 3, 3 engines crippled (stage 4)
var dead_nozzles: Array = []    # nozzles dark at tiers 2 and 3 (never every nozzle: one always gutters on)
var _sick_len := SICK_LEN
var eng_soot := false           # the drive's last build coughs black soot (the Hullbreakers only, under Wounds V2)
var _want_off := {}             # weapon slot -> true: the slots the last view held off
var _exact_slots := false       # the last view carried a weapons list (the old section turret picker stays off)
var _slot_off := {}             # weapon slot -> true, as shown
var _mount_dead := {}           # weapon slot -> {p, n, sec, next}: the fixed mount that smokes and sparks for that slot
var _want_eng_hit := false
var _want_gen := false
var gen_down := false           # the shield generator is out and crackles (shielded ships only)
var _gen_next := 0.0
# Issue 1752 (plan row 4b): capability and breach sounds fire on transitions only. The first capability snapshot is the
# ship as it arrives (a rebuilt view) and is seeded quietly; repairs, death and teardown never sound.
var _cap_seeded := false     # _cap_seen as this sync began (the engine tier step runs after the capability step)
var _cap_seen := false       # the capability step has run once (its first run seeds quietly)
var _gen_loud_at := -99.0    # when the generator's loud first crackle played
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
static var _warned_shield_factions := {}   # not GPU: faction ids already reported
var _hit_i = 0
var _hits = PackedVector4Array()
var _hitw = PackedVector4Array()
var _shield_until = -1.0
# Issue 1446 (R246): the sides the rules route shield power to (struck this round; they catch more and drain the pool
# faster). While any side is routed and the pool holds, the bubble stays up with a quick rim pulse on that side only.
var _route_on := Vector4.ZERO
var _brk_until = -1.0      # issue 1239 (F2.3): until when a shield failure is still playing (a death lets it finish)
# Issue 1078: which shield failure look plays (2 clean collapse, the game's look since R340; 0 the old per-faction break
# and 1 energy shear stay only for side-by-side checks) and the shear's quality (true: the cheaper crack network).
# Read once per ship from the settings (see fail_look_setting).
var _fail_look := 2
var _fail_low := false
var _last_sh = -1.0
var _shield_fraction := -1.0
var _ion_locked := false
var _ion_next := 0.0
var _ion_until := -1.0
var _acid_active := false
var _acid_mist: POOLS.Pool
var _acid_next := 0.0
const ACID_SIZZLE_GAINS := [0.25, 0.125]
var _sizzle_count := 0
var _sizzle_next := 0.0
var _acid_spot_index := 0
var _acid_fallback: Dictionary = {}
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
var _wing_smoke: MeshInstance3D
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
var _damage_surfaces_assigned := false
var _hole_nodes: Array = []
var _hole_lights: Array = []
var _marks: Array = []     # weapon marks on the hull (fx_breach.Ent), oldest first, at most BREACH.MARK_CAP
var _mark_n = 0
var mark_ms: Array = []    # per rebuild: [entries, worker ms, apply ms] (the gallery and probes report it)
# Hit reaction (R50): roll, yaw, pitch and drift in the hull pivot, under the board heading.
# Bare FX fixtures without a hull pivot still use their root as the visual hull.
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
var _show_rcs := false
var _power_dip := 0.0
var _dip_peak := 0.0
var _dip_start := 0.0
var _dip_duration := 0.0
var _ref_mi: MeshInstance3D = null
var _ref0 := Transform3D.IDENTITY
# Issue 1685 (R411): the faction's one idle motion (fx_idle.gd), behind VS_IDLE_MOTION or rendering/effects/idle_motion,
# default off. Read once per ship, like wounds_v2. _idle is {} while off, or {node, mat, rows, motion} once built.
var idle_on := IDLE.enabled()
var _idle: Dictionary = {}
var _idle_key := -1      # Reduce flashing (1) and Reduce motion (2) as the batch was built; a change rebuilds it


# How the hull has moved under the root since the ship was added (ShipView's bob and bank), in the root's frame.
func hull_motion() -> Transform3D:
	if _ref_mi == null or not is_instance_valid(_ref_mi) or not _ref_mi.is_inside_tree():
		return Transform3D.IDENTITY
	return (root.global_transform.affine_inverse() * _ref_mi.global_transform) * _ref0.affine_inverse()


# Hang a node at its pose in the hull's add_ship frame (r18; see setup).
func _attach(n: Node3D, pose := Transform3D.IDENTITY) -> void:
	n.transform = _ref0.affine_inverse() * pose
	if _ref_mi != null and is_instance_valid(_ref_mi):
		_ref_mi.add_child(n)
	else:
		root.add_child(n)


var shield_later := false   # issue 1434: the shield waits for fx.prepare_battle_hulls (see setup)


func build_shield_later(fx) -> void:
	if not shield_later:
		return
	shield_later = false
	if shielded and is_instance_valid(root):
		_build_shield(fx)


static func _new_hull(fx, r: Node3D, sid: String, squad: bool):
	var analysis := HULL.new()
	analysis.stb_z = float(fx.starboard_z)
	analysis.code = str(r.get("code")) if r.get("code") != null else sid
	analysis.formation = squad
	analysis.cache_geometry = true
	return analysis


static func prime_hull(fx, r: Node3D, sid: String, squad: bool, parts: Array) -> bool:
	var analysis = _new_hull(fx, r, sid, squad)
	return analysis.prime(r, parts if not parts.is_empty() else _find_meshes(r))


func setup(fx, sid: String, r: Node3D, info: Dictionary) -> void:
	id = sid
	root = r
	hull_pivot = root.get_node_or_null("hull_pivot") as Node3D
	if "fx_clock" in root:
		root.set("fx_clock", fx)
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
	hull = _new_hull(fx, root, sid, squadron)
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
		if m is MeshInstance3D and not BREACH.is_moving_damage_mesh(self, m):
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
		if fx.defer_initial_cuts and fx.get("defer_shields"):
			# issue 1434: under the load cover the shield is built by fx.prepare_battle_hulls, one ship per slice (a fitted
			# skin's face scan and cache key cost up to about 500 ms in one ship's registration on the PC)
			shield_later = true
		else:
			_build_shield(fx)
	fx.pend("add:shield", t_a)
	_last_pos = root.global_position
	if idle_on:
		_idle_refresh(fx)


# Issue 1685: build (or rebuild) the faction's idle motion batch. Squadrons have none (a wing is craft, not a hull). Reduce
# flashing and Reduce motion change what is built (fx_idle.gd), so a change of either rebuilds the one batch.
func _idle_refresh(fx) -> void:
	if is_instance_valid(_idle.get("node")):
		var old := _idle["node"] as Node
		if old.get_parent() != null:
			old.get_parent().remove_child(old)   # out of the tree now, so the new holder does not get a renamed name
		old.queue_free()
	_idle = {}
	_idle_key = (1 if fx.reduce_flashing else 0) + (2 if _reduce_motion() else 0)
	if squadron or hull == null or not is_instance_valid(_dmg_root):
		return
	_idle = IDLE.build(fx, _dmg_root, hull, faction, fac, _seed, fx.reduce_flashing, _reduce_motion())


func _reduce_motion() -> bool:
	return is_instance_valid(root) and bool(root.get("calm"))   # ShipView.calm, set per view from the Reduce motion setting


func _idle_step(fx) -> void:
	if squadron:
		return
	var key := (1 if fx.reduce_flashing else 0) + (2 if _reduce_motion() else 0)
	if key != _idle_key and not dead and not gone:
		_idle_refresh(fx)
	if not _idle.is_empty() and is_instance_valid(_idle.get("node")):
		(_idle["node"] as Node3D).visible = not dead and not gone


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
	_clear_wing_smoke()
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
	# The shield collapse can outlast the hull's last visible frame (issue 1239).
	if is_instance_valid(_shield_mi):
		var parent := hull_pivot if is_instance_valid(hull_pivot) else root
		if _shield_mi.get_parent() != parent:
			_shield_mi.reparent(parent)
	_hide_meshes()
	_hide_attachments()


func teardown(fx, wait_for_damage := true) -> void:
	gone = true
	end_brownout()
	if is_instance_valid(root) and root.get("fx_clock") == fx:
		root.set("fx_clock", null)
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

# Issue 2042 item 3: per-faction main plume palette (bright core + soft outer wash + style) derived from faction_looks.json.
# style: 0 Sunward ember/frost, 1 Meridian ion spear, 2 Hullbreaker rough overburn, 3 Chorus organic pulse,
#        4 Glasswright crystal violet (no white cold gas), 5 Eclipse violet/white-gold (no green, no orange).
static func plume_palette(fac_id: String, fac_info: Dictionary) -> Dictionary:
	var fid := fac_id.to_lower()
	var eng: Color = fac_info.get("engine", Color(1.0, 0.55, 0.18))
	var acc = fac_info.get("accent")
	var weap: Color = fac_info.get("weapon", eng) if fac_info.get("weapon") is Color else eng
	var dmg: Color = fac_info.get("damage_glow", eng) if fac_info.get("damage_glow") is Color else eng
	match fid:
		"hegemony":
			return {"core": eng.lerp(Color.WHITE, 0.72), "wash": eng.lerp(weap, 0.35), "style": 1}
		"corsair":
			var cw: Color = (acc as Color).lerp(eng, 0.45) if acc is Color else eng
			return {"core": eng.lerp(Color(1.0, 0.94, 0.8), 0.55), "wash": cw, "style": 2}
		"chorus":
			return {"core": dmg.lerp(Color(0.95, 1.0, 0.76), 0.35), "wash": eng * 0.88, "style": 3}
		"ithar":
			return {"core": eng.lerp(weap, 0.58), "wash": eng, "style": 4}
		"deathless":
			var wcore: Color = fac_info.get("weapon_core", eng) if fac_info.get("weapon_core") is Color else eng
			var ew: Color = wcore.lerp(acc as Color, 0.22) if acc is Color else wcore
			return {"core": eng.lerp(Color(0.94, 0.88, 1.0), 0.45), "wash": ew, "style": 5}
		_:
			var vw: Color = (acc as Color).lerp(eng, 0.58) if acc is Color else eng
			return {"core": Color(1.0, 0.96, 0.86).lerp(eng, 0.18), "wash": vw, "style": 0}


static func _apply_plume_palette(mat: ShaderMaterial, fac_id: String, fac_info: Dictionary) -> void:
	var pal := plume_palette(fac_id, fac_info)
	var pc: Color = pal["core"]
	var pw: Color = pal["wash"]
	mat.set_shader_parameter("plume_core", Vector3(pc.r, pc.g, pc.b))
	mat.set_shader_parameter("plume_wash", Vector3(pw.r, pw.g, pw.b))
	mat.set_shader_parameter("plume_style", float(int(pal["style"])))


func _build_engines(fx) -> void:
	if is_instance_valid(_eng_node):
		_eng_node.queue_free()
	var b = POOLS.Batch.new()
	var rb = POOLS.Batch.new()
	var eng: Color = fac["engine"]
	var extra := String(fac.get("engine_extra", "none"))
	# issue 1741 (R416): under Wounds V2 a damaged drive keeps its own faction's exhaust; only the Hullbreakers cough soot
	# (main: any sputtering drive took the Hullbreaker soot, on glass, flesh and obsidian too)
	var corsair = extra == "soot" or (_eng_sputter and not wounds_v2)
	eng_soot = corsair
	var q = POOLS.quad_shape()
	var rs = POOLS.ribbon_shape(14)
	var b_main = b
	var rb_main = rb
	var sb = POOLS.Batch.new()
	var srb = POOLS.Batch.new()
	sick_nozzle = posmod(_seed, hull.nozzles.size()) if _eng_sputter and not hull.nozzles.is_empty() else -1
	dead_nozzles = []
	_sick_len = SICK_LEN
	if wounds_v2:
		_engine_nozzles()
	for ni in hull.nozzles.size():
		if dead_nozzles.has(ni):
			continue   # a dead nozzle is dark: no core, no plume (its bell smokes: _refresh_damage_emitters)
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
		# Issue 2042 item 3: tuck root slightly into the nozzle bell and widen quad for soft outer wash around the bright core.
		var rp: Vector3 = np - nd * (r * 0.12)
		rb.add(rs, POOLS.pack(Vector4(rp.x, rp.y, rp.z, 3 if corsair else 0), Vector4(nd.x, nd.y, nd.z, plume), Vector4(eng.r, eng.g, eng.b, 0.92),
			Vector4(r * 2.15, r * 0.82, fx.rng.randf(), 0), Vector4(-20.0, 1.0, 1.0, 0)))
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
	_apply_plume_palette(_eng_rib_mat, faction, fac)
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
		_apply_plume_palette(_sick_rib_mat, faction, fac)
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
	if idle_on:
		_idle_step(fx)
	_list_step(dt)
	_react_step(fx, dt)
	_power_step(fx)
	_status_step(fx)
	_hide_placeholder_engines()
	var pos := root.global_position
	if hull_pivot == null:
		var parent := root.get_parent_node_3d()
		pos -= parent.global_basis * _app_pos if parent != null else _app_pos
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
		var tk := clampf(_eng_cur / 1.4, 0.15, 1.4)
		_eng_mat.set_shader_parameter("gate", g)
		_eng_rib_mat.set_shader_parameter("gate", g)
		_eng_rib_mat.set_shader_parameter("lenk", clampf(0.5 + 0.5 * _eng_cur, 0.0, 1.8))
		_eng_rib_mat.set_shader_parameter("throttle_k", tk)
		if _sick_mat != null:
			var sk: float = sick_gate(fx.now, fx.reduce_flashing)
			var sg := g * sk
			_sick_mat.set_shader_parameter("gate", sg)
			_sick_rib_mat.set_shader_parameter("gate", sg)
			_sick_rib_mat.set_shader_parameter("lenk", clampf(0.5 + 0.5 * _eng_cur, 0.0, 1.8) * _sick_len)
			_sick_rib_mat.set_shader_parameter("throttle_k", tk * sk)
	var moving_now: bool = _moving > 0.0 and not dead
	if moving_now and not _was_moving and sick_nozzle >= 0 and fx.now >= _cough_next:
		_cough(fx)
		if wounds_v2 and eng_tier >= 3:
			_stern_sparks(fx)
	_was_moving = moving_now
	_wound_step(fx)
	# issue 1581 (Nov 21 audit: rear trails lingered as skid marks while the retros braked): once the battle cuts the
	# drive cold in a flown move, the ribbon behind it shortens fast instead of hanging for its full life
	if _moving > 0.0 and engine_level < 0.12 and not dead:
		_trail_extra += dt * (TRAIL_COLD_AGE - 1.0)
	_update_trails(fx, moved > 1e-4)
	if _shield_mi != null:
		_shield_mi.visible = fx.now < _shield_until or fx.now < _ion_until or (_route_on != Vector4.ZERO and not dead and not gone)


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
	var style: int = 1 if (String(fac.get("engine_extra", "")) == "soot" or (_eng_sputter and not wounds_v2)) else int(fac["trail"])
	for ti in _trails.size():
		var t: Dictionary = _trails[ti]
		var hist: Array = t["hist"]
		var changed := false
		# Neon on PR 1631: the sick nozzle's ribbon gutters with its plume (one trail per nozzle, in order); the dim samples
		# still go in, so the ribbon fades through the gap instead of bridging it bright
		var lvl_t: float = lvl * (sick_gate(fx.now, fx.reduce_flashing) if ti == sick_nozzle else 1.0)
		if dead_nozzles.has(ti):
			lvl_t = 0.0   # issue 1741: a dead nozzle lays no fresh trail (the dim samples let the old ribbon fade out)
		# Issue 2042 item 2: anchor the trail root directly to the live nozzle (no 0.3 * plume stern gap).
		var start: Vector3 = xfm * (t["p"] as Vector3)
		var back_dir: Vector3 = (xfm.basis * (t["d"] as Vector3)).normalized()
		# Each sample belongs to world space for its entire life. Turning, stopping
		# or throttling down never drags old exhaust along with the nozzle.
		# (issue 1581, OpenAI review F4: no fresh exhaust while the battle has the drive cold, even as the plume eases down)
		var active_burn: bool = (not dead or flaring) and lvl > 0.12 and not (_moving > 0.0 and engine_level < 0.12)
		if active_burn:
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
		mat.set_shader_parameter("use_strip_taper", 1.0)
		mat.set_shader_parameter("anchor_head", 1.0 if (active_burn and not dead_nozzles.has(ti)) else 0.0)
		mat.set_shader_parameter("head_world", start)
		mat.set_shader_parameter("head_dir", back_dir)
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
	# Issue 2042 item 2: start at nozzle width and taper cleanly down to a slender tail (never a wide rectangle).
	var w0 := r * 1.25
	var w1 := r * 0.18 * clampf(scale_k(), 0.7, 1.3)
	var denom := maxf(float(n - 1), 1.0)
	for i in n:
		var d = (hist[mini(i + 1, n - 1)][0] - hist[maxi(i - 1, 0)][0]).normalized()
		var along := float(i) / denom
		for sd in [-0.5, 0.5]:
			verts.append(hist[i][0])
			nrm.append(d)
			uv.append(Vector2(clampf((_tclock - float(hist[i][1])) / TRAIL_LIFE, 0.0, 1.0), sd))
			c0.append_array([eng.r, eng.g, eng.b, 0.34 * clampf(float(hist[i][2]), 0.0, 1.5)])
			c1.append_array([w0, w1, float(t["seed"]), along])
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
	var colour = fac.get("shield")
	if not (colour is Color):
		if not _warned_shield_factions.has(faction):
			_warned_shield_factions[faction] = true
			push_warning("FX shield requested for faction '%s' without a shield colour" % faction)
		shielded = false
		return
	var sc: Color = colour
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
	_attach(_shield_mi, _shield_pose)


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
	var frame := _shield_mi.transform * _shield_pose.affine_inverse()
	_shield_pose = Transform3D(Basis.IDENTITY, hull.shield_centre())
	_shield_mi.transform = frame * _shield_pose


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


func shield_hit(fx, local_p: Vector3, T: float, strength: float, spread: float, life := 0.6, fraction := -1.0) -> void:
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
	var remaining := _shield_fraction if fraction < 0.0 else fraction
	var strained := remaining > 0.0 and remaining < 0.25
	_hitw[_hit_i] = Vector4(strength, life, spread * fx.unit, 1.0 if strained else 0.0)
	if strained:
		fx.later(T, func l_shield_sputter() -> void:
			if not dead and not gone and is_instance_valid(root) and fx.sound() != null:
				fx.sound().play("shield_sputter", {"pos": to_world(hull.shield_centre() + local_p)}))
	_shield_mat.set_shader_parameter("hits", _hits)
	_shield_mat.set_shader_parameter("hitw", _hitw)
	_shield_until = maxf(_shield_until, T + life + 0.05)


# Issue 1078, R340 (Ryan picked it Nov 19 2026): the shield failure is the clean collapse, for every shielded ship of
# every faction and both shield shapes: one even flash, then one band closes from the far side into the breach, a knot
# and a flat ring of sparks. Dev comparison only: rendering/effects/shield_failure (or VS_SHIELD_FAILURE) = "today"
# (the old per-faction break) or "shear" (one connected crack network); rendering/effects/shield_failure_quality="low"
# (or VS_SHIELD_FAILURE_Q=low) gives the shear its cheaper crack network. Anything else plays the collapse.
const FAIL_LOOKS := ["today", "shear", "collapse"]


static func wounds_v2_setting() -> bool:
	return WOUNDS.v2()


# Issue 1741 (JOINT_C, Nov 23: a lime gas plume under the Chorus wound read as neon against R420): with Wounds V2 on,
# the Chorus's smoke, fume and vent gas take its wound accent (ochre over dark olive) in place of the bile lime of
# damage_glow, which stays for its lit glands and fire. Off, the old colour.
func chorus_gas(glow: Color) -> Color:
	if not wounds_v2:
		return glow
	var a = (fac.get("wound", {}) as Dictionary).get("interior_accent", [0.6, 0.52, 0.14]) if fac.get("wound") is Dictionary else [0.6, 0.52, 0.14]
	return Color(float(a[0]), float(a[1]), float(a[2]))


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
	# Playback can break the shield before the next rules view arrives.
	_shield_fraction = 0.0
	hit_power(fx, true)
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
	shield_hit(fx, lp, T, 1.0, rad.length() * 0.8 / fx.unit, 0.9, 0.0)
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
	shield_hit(fx, lp, T, 1.0, rad.length() * 0.6 / fx.unit, 0.6, 0.0)
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
	shield_hit(fx, lp, T, 0.7, rad.length() * 0.3 / fx.unit, 0.5, 0.0)
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
const REACT_SHUDDER_HZ := [6.0, 5.5, 5.0, 4.25, 3.5]
const REACT_SHUDDER_T := 0.22 / 3.0  # 95% of the tremor is gone after 0.22 effect seconds
var _kick_v := Vector3.ZERO     # angular kick still to be delivered (onset)
var _kick_p := Vector3.ZERO     # drift kick still to be delivered
var _brk := Vector3.ZERO        # thrusters' braking rate per axis (rad/s2)
var _brk_p := 0.0               # ... and for the slide (units/s2)
var _brk_at := 0.0              # when the thrusters start braking
var react_clock := 0.0          # seconds of reaction integrated so far (issue 1467: the frame-rate check reads it)


# A hit's physical reaction. impulse: the weapon's momentum (fx_weapons.REACT_IMPULSE: torpedoes and rams shove,
# shells and slugs kick, lances and ions barely at all); lp, ldir: hit point and shot direction in the ship frame.
func hit_react(fx, impulse: float, lp: Vector3, ldir: Vector3, source := "hull") -> void:
	if dead or gone or impulse <= 0.0:
		return
	# Issue 462: where the last hit landed (hull space), so a death can open its tear from the side that was hit.
	if source != "recoil":
		set_meta("last_hit", [lp, ldir, fx.now])
	_show_rcs = _show_rcs or source == "hull"
	var wi := clampi(weight, 0, 4)
	var m: float = REACT_MASS[wi]
	var L: float = maxf(hull.L, 1.0)
	var d := ldir.normalized()
	var r: Vector3 = (lp - hull.c) / L
	# the angular kick: torque from where the hit lands, about the ship's own axes (x roll, y yaw, z pitch)
	# The roll axis sits below mid-hull. Nearby shots on either side of the midline share the same heel.
	r.y += maxf(hull.H / L, 0.05) * 0.35
	var tq := r.cross(d)
	# turning inertia grows faster than mass (a long hull resists spin more than it resists a shove)
	var dv := Vector3(tq.x * 2.4, tq.y * 0.8, tq.z * 1.2) * impulse * 0.25 / pow(m, 1.25)
	var dp := d * impulse * L * 0.0095 / m
	if wi >= 3 or death_tier == "capital":
		dp *= 0.5
	_kick_v += dv
	_kick_p += dp
	# the thrusters brake whatever the ship will be doing once the kick is in, over REACT_ARREST seconds
	var t_ar: float = REACT_ARREST[wi]
	var v_after := _rv + _kick_v
	_brk = Vector3(maxf(_brk.x, absf(v_after.x) / t_ar), maxf(_brk.y, absf(v_after.y) / t_ar), maxf(_brk.z, absf(v_after.z) / t_ar))
	_brk_p = maxf(_brk_p, (_pv + _kick_p).length() / (t_ar * 1.3))
	_brk_at = fx.now + REACT_ONSET[wi] + 0.05
	# The structure rings lower on heavier hulls.
	_shud = maxf(_shudder_at(fx.now), minf(impulse / sqrt(m), 4.0) * 0.0035)
	_shud_t = fx.now
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
			# Exact critically damped return keeps the drift smooth across frame rates.
			var slope := _pv + _pd * wr
			var decay := exp(-wr * h)
			_pd = (_pd + slope * h) * decay
			_pv = (_pv - slope * (wr * h)) * decay
			_ra += _rv * h
			return
	_ra += _rv * h
	_pd += _pv * h


func _shudder_at(t: float) -> float:
	return _shud * exp(-maxf(t - _shud_t, 0.0) / REACT_SHUDDER_T)


func _react_apply(fx, wi: int) -> void:
	var age: float = fx.now - _shud_t
	var sh := _shudder_at(fx.now)
	var phase: float = age * TAU * REACT_SHUDDER_HZ[wi]
	var angles := _ra + Vector3(sh * sin(phase + 1.3), 0.0, sh * 0.7 * sin(phase))
	var idle := _kick_v.length() < 1e-4 and _kick_p.length() < hull.L * 1e-5 and _brk == Vector3.ZERO and _brk_p == 0.0
	if idle and _ra.length() < 6e-4 and _rv.length() < 1e-3 and _pd.length() < hull.L * 3e-4 and _pv.length() < hull.L * 3e-4 and sh < 1e-4:
		angles = Vector3.ZERO
		_ra = Vector3.ZERO
		_rv = Vector3.ZERO
		_pd = Vector3.ZERO
		_pv = Vector3.ZERO
		_shud = 0.0
		_reacting = false
		_show_rcs = false
	if hull_pivot != null:
		hull_pivot.rotation = angles + Vector3(_list, 0.0, 0.0)
		hull_pivot.position = _pd
	else:
		# Bare hulls use the root. Subtract the applied yaw to keep their drift in the base heading.
		var base_yaw := root.rotation.y - _app_yaw
		var want_pos := Basis(Vector3.UP, base_yaw) * _pd
		root.position += want_pos - _app_pos
		root.rotation = angles + Vector3(_list, base_yaw, 0.0)
		_app_pos = want_pos
		_app_yaw = angles.y
	if _show_rcs:
		_rcs(fx)


# Attitude corrections at the hull corners, picked so their thrust opposes the spin and drift.
func _rcs(fx) -> void:
	if squadron or faction == "chorus" or fx.now < _rcs_next:
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
		var axis := dir_world(gd)
		fx.record_spawn(self, wp)
		match faction:
			"ithar":
				fx.spr(wp, fx.now, 0.14, Color(1.0, 0.86, 0.57), 1.5, 0.65 * k, 0.18 * k, 16, axis * k, 0.0, 0.0, 0.0, 13.0)
			"deathless":
				fx.ring(wp, axis, fx.now, 0.2, Color(0.59, 0.38, 1.0), 0.75, 0.20 * k, 0.9 * k, 3)
			_:
				var soot: bool = faction == "corsair"
				var gas := Color(0.53, 0.46, 0.40) if soot else Color(0.85, 0.88, 0.95)
				var core := Color(0.79, 0.69, 0.59) if soot else Color(0.9, 0.95, 1.0)
				var gv: Vector3 = axis * (5.0 + fx.rng.randf() * 3.0) * k
				fx.spr(wp, fx.now, 0.35, gas, 0.6, 0.12 * k, 0.9 * k, 7, gv, 2.5)
				fx.spr(wp, fx.now, 0.06, core, 1.5, 0.08 * k, 0.15 * k, 18)


# Stutter is about the hit outcome. Recoil and fully absorbed impacts can still move the hull.
# The one brownout path (Neon on PR 1699, item c): a felt hit sets a transient dip here, and _wound_step writes it onto
# the hull's damage surfaces as fx_flick, multiplied with the wound flicker. A fresh hull gets its damage surfaces first
# (ensure_damage_surfaces, PR 1631), so no painted material is copied or swapped, and fx_power stays the wear's steady
# value and the death fade's.
func hit_power(fx, stutter: bool, dip := 0.0, duration := 0.45) -> void:
	if dead or gone:
		return
	if stutter:
		_stutter_until = maxf(_stutter_until, fx.now + 0.8)
	if dip <= 0.0 or squadron:
		return
	ensure_damage_surfaces(fx)
	_dip_peak = maxf(_power_dip, dip)
	_dip_start = fx.now
	_dip_duration = duration
	_set_power_dip(_dip_peak)
	_wlog(["power_dip", -1, fx.now])


func _power_step(fx) -> void:
	if dead or _dip_duration <= 0.0:
		return
	var age: float = fx.now - _dip_start
	if age >= _dip_duration:
		end_brownout()
		return
	var recovery := 1.0 - smoothstep(0.0, _dip_duration, age)
	var flicker := 1.0 if fx.reduce_flashing else 0.82 + 0.18 * cos(age * TAU * 5.0)
	_set_power_dip(_dip_peak * recovery * flicker)


# The dip reaches the shader through _wound_step (fx_flick) on the same frame: _power_step runs before it in step().
func _set_power_dip(dip: float) -> void:
	_power_dip = dip


func end_brownout() -> void:
	if _dip_duration <= 0.0:
		return
	_dip_duration = 0.0
	_set_power_dip(0.0)


# ---------------------------------------------------------------- hull wear and the crippled list (issue 1235)

# hull_wear (0 above WEAR_FROM of max HP, 1 at WEAR_FULL) dims every hull's lights through fx_power.
# fx_weather darkening and the soot patches at the hit sites apply only to metal (R402). Below LIST_FROM of max HP,
# every hull lists LIST_MIN to LIST_MAX degrees about its bow toward the side last hit.
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
	if _damage_surfaces_assigned or dead or gone or squadron or hull == null or fx == null or fx.compat:
		return
	var static_meshes: Array = []
	for mi in meshes:
		if is_instance_valid(mi) and not BREACH.is_moving_damage_mesh(self, mi):
			static_meshes.append(mi)
	BREACH._inside_overlay(fx, self, static_meshes, [], fac.get("damage_glow", Color(1.0, 0.45, 0.12)))
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
	if hull_wear <= 0.0 or hull == null or HULL.target_substance(faction) != "metal":
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
	if not _reacting:
		var visual := hull_pivot if hull_pivot != null else root
		visual.rotation.x += _list - prev


# ---------------------------------------------------------------- staged damage (API.md 2)

func sync(fx, u: Dictionary) -> void:
	if dead or gone:
		return
	var status = u.get("st")
	_acid_active = status is Dictionary and status.get("acid") != null and float(status["acid"]) > 0.0
	set_regen_lock(u.get("regenLock") != null and float(u["regenLock"]) > 0.0)
	_shield_fraction = -1.0
	if u.get("shp") != null and u.get("shMax") != null and float(u["shMax"]) > 0.0:
		_shield_fraction = float(u["shp"]) / float(u["shMax"])
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
	var marks_changed := _regrade_marks()
	_set_wear(fx, hpf)
	if wounds_v2:
		_read_capability(u, sec)
	if squadron:
		want = [0, 0, 0]
		_squad_smoke = hpf < 0.5 and not fx.compat
	if fx.now < busy_until:
		if marks_changed:
			_dmg_request(fx)
		var w = want.duplicate()
		fx.later(busy_until + 0.05, func l_stages() -> void: _apply_stages(fx, w))
	else:
		_apply_stages(fx, want, marks_changed)
	# shields: a rise means regen
	var shs = 0.0
	var sh_list = u.get("sh")
	if sh_list is Array:
		for v in sh_list:
			shs += float(v) if v != null else 0.0
	if _last_sh >= 0.0 and shs > _last_sh + 0.5:
		_regen(fx)
	_last_sh = shs
	if u.has("route"):
		_set_route(u.get("route"), float(u["shp"]) if u.get("shp") != null else shs)
	var burn = u.get("burning") == true
	if burn != _burning:
		_burning = burn
		_set_burning(fx, burn)


func set_regen_lock(active: bool) -> void:
	_ion_locked = active and _shield_mat != null


# Both statuses use the effect clock. Repeated view syncs leave their cadence alone.
func _status_step(fx) -> void:
	if dead or not _acid_active:
		if _acid_mist != null:
			_acid_mist.mi.hide()
			_acid_mist.mi.queue_free()
			_acid_mist = null
			_acid_fallback.clear()
			_acid_next = 0.0
			_sizzle_count = 0
			_sizzle_next = 0.0
	elif fx.now >= _acid_next:
		_acid_next = fx.now + 0.30
		_emit_acid(fx)
	if dead or not _ion_locked or _shield_fraction <= 0.0 or fx.now < _brk_until:
		if _ion_until >= 0.0:
			_shield_mat.set_shader_parameter("ion_arc", Vector2(-100.0, 0.0))
			_ion_until = -1.0
			_ion_next = 0.0
	elif fx.now >= _ion_next:
		# An upper flank facing the battle camera. The shader draws on the actual shield skin as the ship moves.
		var angle: float = fx.rng.randf_range(-PI, PI)
		if is_instance_valid(fx.camera):
			var eye: Vector3 = xf().affine_inverse() * fx.camera.global_position - hull.shield_centre()
			angle = atan2(eye.z, eye.x) + fx.rng.randf_range(-0.65, 0.65)
		_shield_mat.set_shader_parameter("ion_arc", Vector2(fx.now, angle))
		_ion_until = fx.now + 0.45
		_ion_next = _ion_until + fx.rng.randf_range(0.55, 1.25) * (2.0 if fx.reduce_flashing else 1.0)


func _emit_acid(fx) -> void:
	var spots: Array = get_meta("acid_spots", [])
	var p: Vector3
	var n := Vector3.UP
	if spots.is_empty():
		if fx.now < busy_until: return  # an in-flight shot can still supply its actual contact
		# A restored ship has its rules status but no FX hit history. Find real plating once.
		if _acid_fallback.is_empty():
			if is_instance_valid(fx.camera):
				var eye: Vector3 = xf().affine_inverse() * fx.camera.global_position
				_acid_fallback = hull.surface(hull.core, eye - hull.core)
			if _acid_fallback.is_empty():
				_acid_fallback = hull.surface_sample(-1, 0.5, "acid")
		if _acid_fallback.is_empty(): return
		p = _acid_fallback["p"]
		n = _acid_fallback["n"]
	else:
		var spot: Array = spots[_acid_spot_index % spots.size()]
		_acid_spot_index += 1
		p = spot[0]
		if spot.size() > 2: n = spot[2]
	if _acid_mist == null:
		var material: ShaderMaterial = fx.mat(SH.SPRITE, 1, "#define SOFT\n" if fx.quality != "low" else "")
		_acid_mist = POOLS.Pool.new(8, material, _dmg_root, "fx_acid_mist", POOLS.quad_shape())
	var col := _acid_colour()
	# Lift the expanding mist off the plating so the hull and soft depth fade leave it room to show.
	var origin := p + n * maxf(0.65, hull.L * 0.02)
	var drift: Vector3 = (n + Vector3.UP * 0.70) * hull.L * 0.065
	_acid_mist.emit(POOLS.pack(Vector4(origin.x, origin.y, origin.z, fx.now), Vector4(drift.x, drift.y, drift.z, 1.9),
		Vector4(col.r, col.g, col.b, 0.68), Vector4(hull.L * 0.08, hull.L * 0.23, 20, fx.rng.randf()), Vector4(0, 0, 0.3, 0.15)))
	_acid_mist.flush()
	if _sizzle_count < ACID_SIZZLE_GAINS.size() and fx.now >= _sizzle_next:
		_sizzle_next = fx.now + fx.rng.randf_range(1.7, 2.8)
		if fx.sound() != null:
			fx.sound().play("acid_sizzle", {"pos": to_world(p), "gain": ACID_SIZZLE_GAINS[_sizzle_count]})
		_sizzle_count += 1


func _acid_colour() -> Color:
	return fac["damage_glow"] if faction == "deathless" else Color(0.5, 0.9, 0.2)


# Issue 1446: the routed sides into the bubble's rim pulse (quad order prow, starboard, rear, port, as the rules)
func _set_route(route, pool: float) -> void:
	var on := Vector4.ZERO
	if shielded and not squadron and pool >= 1.0 and route is Array:
		for i in mini((route as Array).size(), 4):
			if route[i] != null and float(route[i]) > 0.0:
				on[i] = 1.0
	if on == _route_on or _shield_mat == null:
		_route_on = on if _shield_mat != null else Vector4.ZERO
		return
	_route_on = on
	_shield_mat.set_shader_parameter("route_on", on)
	_shield_mat.set_shader_parameter("route_dirs", PackedVector3Array([hull.quad_dir(0), hull.quad_dir(1), hull.quad_dir(2), hull.quad_dir(3)]))


func set_stages(fx, st: Array) -> void:
	_apply_stages(fx, [0, 0, 0] if squadron else st)


func _apply_stages(fx, want: Array, marks_changed := false) -> void:
	if dead or gone:
		return
	var rebuild := marks_changed
	for i in 3:
		if int(want[i]) != int(stage[i]):
			var up: bool = int(want[i]) > int(stage[i])
			var was: int = int(stage[i])
			if int(stage[i]) == 4 and int(want[i]) < 4:
				_patch_time[i] = fx.now
			_scar_stage[i] = maxi(_scar_stage[i], stage[i])
			stage[i] = int(want[i])
			_build_section(fx, i, up)
			rebuild = true
			# issue 1587: a hit that pushes a section into stage 3 or 4 vents it once (never on the ship's first stage
			# update, which is its state as it arrives: a view rebuilt with the damage already there)
			if up and _stages_seen and ((was < 3 and stage[i] >= 3) or (was < 4 and stage[i] == 4)):
				_blowout(fx, i)
			# issue 1752: a section that newly reaches stage 4 opens its real cutout (_plan), so the breach sounds once, at it
			if up and _stages_seen and was < 4 and stage[i] == 4 and wounds_v2:
				_breach_sound(fx, i)
	_stages_seen = true

	# Issue 2087: snapshot the marks and all changed sections once. Submitting inside the loop built a partial wound,
	# then made the dirty flag start a second full hull rebuild.
	if rebuild:
		_dmg_request(fx)
	_refresh_wounds(fx)
	_cap_seeded = _cap_seen   # false on this ship's first capability snapshot: its engine tier is seeded quietly too
	if wounds_v2:
		_refresh_capability(fx)
		_cap_seen = true
	_refresh_damage_emitters(fx)
	if wounds_v2:
		var tier := engine_tier_for(int(stage[0]), _want_eng_hit) if not squadron else 0
		if tier != eng_tier:
			# issue 1752: a drive that loses a tier (never a repair, never the arriving state, never the Chorus) fails audibly
			if tier > eng_tier and _cap_seeded and not dead and faction != "chorus":
				_cue(fx, "dmg_engine_fail", root.global_position if is_instance_valid(root) else Vector3.ZERO)
			eng_tier = tier
			_eng_sputter = tier >= 1
			_build_engines(fx)
			_refresh_damage_emitters(fx)   # the dead nozzles' bell smoke (the key carries the tier)
			_wlog(["eng_tier", tier, fx.now])
		return
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
	if _clear_spot(h["p"], R):
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
				if not hit.is_empty() and _clear_spot(hit["p"], R):
					return {"p": hit["p"], "n": hit["n"]}
	if sec >= 0:
		for t in 48:
			var c2: Dictionary = hull.random_sample(sec, 0.0)
			if not c2.is_empty() and (c2["n"] as Vector3).dot(nn) > 0.3 and _clear_spot(c2["p"], R):
				return {"p": c2["p"], "n": c2["n"]}
	return {}


# R416 4.3 (Wounds V2 on): a cutout keeps clear of the bay doors too, not only the turrets.
func _clear_spot(p: Vector3, R: float) -> bool:
	return _clear_of_turrets(p, R) and (not BREACH.v2_on() or _clear_of_doors(p, R))


func _clear_of_doors(p: Vector3, R: float) -> bool:
	for b in door_boxes():
		if (b as AABB).grow(R * 1.15).has_point(p):
			return false
	return true


var _door_boxes: Array = []
var _door_boxes_done := false


# Each bay door's box at rest in the ship frame, from its meshes.
func door_boxes() -> Array:
	if _door_boxes_done:
		return _door_boxes
	_door_boxes_done = true
	if hull == null or not ("doors" in hull) or not is_instance_valid(root):
		return _door_boxes
	var inv: Transform3D = root.global_transform.affine_inverse()
	for d in hull.doors:
		var node = d.get("node")
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
			_door_boxes.append(box)
	return _door_boxes


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
	# R416 5.1 (issue 1741, Wounds V2 on): an authored-interior hull opens real cutouts from stage 2 (about 55% section
	# HP), 0.026 L growing to 0.038 L and 0.052 L, each through the footprint check; a second one at stage 3 and up
	# on a heavier ship (two per section at most). Older hollow hulls keep the stage 4 ladder below.
	if BREACH.v2_on() and hull.authored and not fx.compat and st >= 2:
		var R2: float = L * float(BREACH.V2_HOLE_L[clampi(st - 2, 0, 2)])
		var e2 = BREACH.place_hole(hull, a.p, a.n, R2, sd, faction)
		e2.t0 = _t0(a, st, fx)
		e2.sec = i
		if e2.has_cut() and not _clear_spot(e2.c, e2.R):
			e2 = BREACH.crater(a.p, a.n, R2 * 0.6, R2 * 0.12, sd, BREACH.S_DENT)   # the footprint slid it under a turret or door
			e2.v2 = BREACH.wound_of(faction).get("kind", 0)
			e2.t0 = _t0(a, st, fx)
			e2.sec = i
		out.append(e2)
		if weight >= 2 and st >= 3:
			var b2 = _anchor(i, "b")
			if not b2.is_empty():
				var eb2 = BREACH.place_hole(hull, b2.p, b2.n, R2 * 0.8, sd + 2.1, faction)
				eb2.t0 = _t0(b2, st, fx)
				eb2.sec = i
				if not eb2.has_cut() or _clear_spot(eb2.c, eb2.R):
					out.append(eb2)
		if scar == 4 and st < 4:
			var patch2 = BREACH.surface(a.p, a.n, L * 0.07, sd, BREACH.S_PATCH)
			patch2.t0 = _patch_time[i]
			patch2.sec = i
			patch2.heat = 0.0
			out.append(patch2)
		return out
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
	if fx.get("closed") == true or fx.get("passive") == true:   # issue 1435: a released fx takes no new jobs; 1434: nor the backdrop's
		return
	if _dmg_task >= 0:
		_dmg_dirty = true
		return
	var ents: Array = []
	for i in 3:
		ents.append_array(_ents[i])
	ents.append_array(visible_marks(fx))
	ents = BREACH.cap_holes(ents)
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
	_v2_heavy_hole(fx, look, w, es)
	t_m = fx.pend("mark", t_m)
	_dmg_request(fx)
	fx.pend("dmg_request", t_m)


# R416 5.1 (issue 1741, Wounds V2 on): a heavy hit (torpedo, lance, null lance, star, a gauss exit, or any weight 3+
# weapon) on a section under 80% HP opens a real cutout where it struck, on an authored-interior hull only, at most
# V2_HOLES_SHIP per ship and V2_HOLES_SEC per section counting the stage cutouts, clear of turrets and bay doors.
func _v2_heavy_hole(fx, look: String, w: int, es: Array) -> void:
	if not BREACH.v2_on() or fx.compat or not hull.authored or es.is_empty():
		return
	if not (look in ["torp", "lance", "nlance", "star", "gauss"] or w >= 3):
		return
	var at = es[0]
	for e in es:
		if e.style == BREACH.S_GAUSS_OUT:
			at = e
	if look == "gauss" and at.style != BREACH.S_GAUSS_OUT:
		return
	var sec: int = hull.section_of(at.c.x)
	if section_fraction[sec] >= 0.8:
		return
	var all: Array = []
	for i in 3:
		all.append_array(_ents[i])
	all.append_array(_marks)
	if BREACH.count_holes(all) >= BREACH.V2_HOLES_SHIP or BREACH.count_holes(all, sec) >= BREACH.V2_HOLES_SEC:
		return
	var R: float = hull.L * float(BREACH.V2_HOLE_L[0])
	if not _clear_spot(at.c, R):
		return
	var eh = BREACH.place_hole(hull, at.c, at.n, R, at.seed_v + 0.77, faction)
	if not eh.has_cut() or not _clear_spot(eh.c, eh.R):
		return
	eh.t0 = fx.now
	eh.sec = sec
	eh.look = "v2hole"
	eh.wt = maxi(w, 3)
	eh.section_damage = 1.0 - section_fraction[sec]
	_marks.append(eh)


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
		# The three V2 Null Lance cuts overlap the repeat radius. Reheat the matching cut, not its neighbour.
		if e.style == BREACH.S_NLANCE and e.v2 >= 0 and o.part_i != e.part_i:
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
		var surface := template.duplicate() as ShaderMaterial
		# The breach rebuild also applies wear, so the gate travels with the ship's own surface.
		surface.set_meta("fx_metal_wear", HULL.target_substance(faction) == "metal")
		entry = [template, surface]
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
		for j in 4: DEATH.BEATS.debris(fx, self, wp, fx.now, 2.0, fx.rcone(wn, 0.8) * hull.L * 0.07, hull.L * 0.009, 0.8)


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
		if not is_instance_valid(e.get("node")):
			continue
		counts[e.kind] += 1
		counts.particles += e.particles
	return counts


func _refresh_damage_emitters(fx) -> void:
	var key := str(stage) + str(_burning) + str(fx.compat) + str(_jammed.keys()) + str(_mount_dead.keys()) + str(dead_nozzles)
	if key == _emitter_key: return
	_emitter_key = key
	for e in _fading_emitters:
		if is_instance_valid(e.get("node")):
			e.node.queue_free()
	_fading_emitters.clear()
	var desired: Array = []
	var caps := damage_caps(fx.cap_k)
	var fires := 0
	var smoke := 0
	if not fx.compat and not squadron:
		# Worst sections claim slots first. Stable ids preserve unchanged emitters.
		for grade in [4, 3, 2, 1]:
			for i in 3:
				var st: int = maxi(stage[i], 3 if _burning and i == 1 else 0)
				if st != grade: continue
				if st >= 3 and fires < caps.x:
					desired.append({"id": "fire%d" % i, "kind": "fire", "sec": i, "st": st})
					fires += 1
				# The hot wound already includes the smoke sheath. Do not draw it again at the same point.
				elif smoke < caps.y:
					desired.append({"id": "smoke%d" % i, "kind": "smoke", "sec": i, "st": st})
					smoke += 1
		if weight >= 3 and smoke < caps.y:
			for i in 3:
				if stage[i] >= 3 and smoke < caps.y:
					desired.append({"id": "vent%d" % i, "kind": "vent", "sec": i, "st": stage[i]})
					smoke += 1
		# issue 1587: a jammed turret's thin smoke wisp takes a smoke slot (the class caps hold)
		for i in _jammed:
			var jsec: int = int(_jammed[i].get("sec", i))
			if smoke < caps.y and bool(_jammed[i].get("wisp", true)):
				desired.append({"id": "wisp" + str(i), "kind": "smoke", "sec": jsec, "st": stage[jsec], "tur": int(_jammed[i]["k"])})
				smoke += 1
		# issue 1741: a knocked-out slot's fixed mount, and each dead nozzle's bell, smoke the same thin wisp
		for slot in _mount_dead:
			var md: Dictionary = _mount_dead[slot]
			if smoke < caps.y:
				desired.append({"id": "mount%d" % slot, "kind": "smoke", "sec": int(md["sec"]), "st": stage[int(md["sec"])], "mp": md["p"]})
				smoke += 1
		for ni in dead_nozzles:
			if smoke < caps.y:
				desired.append({"id": "bell%d" % ni, "kind": "smoke", "sec": 0, "st": stage[0], "mp": hull.nozzles[ni]["p"]})
				smoke += 1
	var keep: Array = []
	for e in _damage_emitters:
		# Keep an expired stage 1 ticket until the stage changes, so another section cannot replay it.
		if not is_instance_valid(e.get("node")) and e.form != DAMAGE_PLUME.Form.SCORCH:
			continue
		var match_i := -1
		for j in desired.size():
			if desired[j].id == e.id and desired[j].st == e.st: match_i = j; break
		if match_i >= 0:
			keep.append(e)
			desired.remove_at(match_i)
		elif is_instance_valid(e.get("node")):
			# Old emitters fade only when repairing, with no new replacements in
			# the same slot. Stage upgrades move the source inside immediately.
			if stage[e.sec] < e.st and not fx.compat and desired.is_empty():
				e["until"] = fx.now + 0.8
				_fading_emitters.append(e)
			else: e.node.queue_free()
	for e in desired:
		if _build_damage_emitter(fx, e):
			keep.append(e)
	_damage_emitters = keep


func _build_damage_emitter(fx, e: Dictionary) -> bool:
	if e.has("tur") or e.has("mp"):
		_build_wisp(fx, e)
		return true
	var a := _anchor(e.sec, "a")
	if a.is_empty(): return false
	var p: Vector3 = a.p
	var n: Vector3 = a.n
	var form := DAMAGE_PLUME.Form.DENT
	var length: float = hull.L * 0.12
	var axis := (n + Vector3.UP * 0.45).normalized()
	if e.kind == "fire":
		form = DAMAGE_PLUME.Form.WOUND
		length = hull.L * (0.19 if e.st == 4 else 0.15)
		if e.st == 4: p -= n * hull.L * 0.018
	elif e.kind == "vent":
		form = DAMAGE_PLUME.Form.VENT
		length = hull.L * 0.19
		axis = n
	elif e.st == 1:
		form = DAMAGE_PLUME.Form.SCORCH
		length = hull.L * 0.075
	_attach_damage_plume(fx, e, p, axis, length, form)
	if form == DAMAGE_PLUME.Form.WOUND:
		var light_pos: Vector3 = a.p + n * hull.L * 0.025
		e["light"] = fx.light_source(e.node, light_pos - p, fac.damage_glow, 0.32,
			0.20, hull.L * 0.13 / fx.unit, e.phase * TAU)
	return true


func _attach_damage_plume(fx, e: Dictionary, p: Vector3, axis: Vector3, length: float, form: DAMAGE_PLUME.Form) -> void:
	var phase := float(posmod(hash(e.id) + _seed, 127)) / 127.0
	var plume := DAMAGE_PLUME.build(fx, _dmg_root, p, axis, length, form, fac, phase, "fx_damage_" + e.id)
	e["node"] = plume
	e["mat"] = plume.material_override
	e["particles"] = 1
	e["form"] = form
	e["source"] = p
	e["phase"] = phase


func _update_damage_emitters(fx) -> void:
	if dead or gone:
		for e in _damage_emitters + _fading_emitters:
			if is_instance_valid(e.get("node")):
				e.node.visible = false
		_clear_wing_smoke()
		return
	for j in range(_fading_emitters.size() - 1, -1, -1):
		var e: Dictionary = _fading_emitters[j]
		if not is_instance_valid(e.get("node")):
			_fading_emitters.remove_at(j)
			continue
		var gate: float = clampf((e.until - fx.now) / 0.8, 0.0, 1.0)
		e.mat.set_shader_parameter("gate", gate)
		if e.has("light"):
			e.light["base"] = 0.32 * gate
		if gate <= 0.0:
			e.node.queue_free()
			_fading_emitters.remove_at(j)
	if squadron:
		if not _squad_smoke or fx.compat:
			_clear_wing_smoke()
		elif not is_instance_valid(_wing_smoke):
			_build_wing_smoke(fx)


func _build_wing_smoke(fx) -> void:
	var visual = root.get("hull")
	var exhaust: Dictionary = visual.damage_exhaust() if is_instance_valid(visual) and visual.has_method("damage_exhaust") else {}
	var parent: Node3D = exhaust.get("parent", _dmg_root)
	var length: float = 1.65
	var p: Vector3
	if exhaust.is_empty():
		# Minimal or legacy wings use their analysed stern, rather than a point between the craft.
		var aft: Dictionary = hull.surface(hull.c, Vector3.LEFT)
		if aft.is_empty():
			return
		p = aft.p
		length = hull.L * 0.55
	else:
		p = exhaust.p
	var phase := float(posmod(_seed, 127)) / 127.0
	_wing_smoke = DAMAGE_PLUME.build(fx, parent, p, Vector3.LEFT, length, DAMAGE_PLUME.Form.WING,
		fac, phase, "fx_wing_damage_smoke")


func _clear_wing_smoke() -> void:
	if is_instance_valid(_wing_smoke):
		_wing_smoke.hide()
		_wing_smoke.queue_free()
	_wing_smoke = null


# ---------------------------------------------------------------- live wounds (issue 1587)
# Neon's Nov 21-22 hull FX audit (issue 1587, Refs #1239 Top 6): a wounded ship looks like a failing warship, not a dimmed
# mesh. View only; the rules never see any of it. Everything here is one-shot pool sprites or a uniform write, except the
# jammed turret's wisp, which takes one of the ship's smoke slots (damage_caps), so steady-state counts do not grow.
#   - engine section at stage 3+: one nozzle (sick_nozzle) gutters with gaps and a plume SICK_LEN as long, and coughs smoke
#     as the ship starts to move
#   - mid or prow section at stage 3+: one turret there freezes off its aim and sags (fx_hull jam_turret), trails a thin
#     wisp and pops a spark every 2 to 4 s; the hull's lights flicker unevenly (fx_flick, multiplied onto the wear's fx_power)
#   - a hit that pushes a section into stage 3 or 4: a one-shot blowout jet of vapour and a few tumbling bits
#   - a felt hull hit (crit, ion, lance, heavy shot): hit_power browns the hull's lights out (fx_flick) for about half a second
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
		if wounds_v2 and faction == "voidsworn":
			col = Color(0.13, 0.115, 0.10)    # issue 1741: forged-iron drive smoke, grey, never the Hullbreaker soot
		elif wounds_v2 and faction == "hegemony":
			col = Color(0.30, 0.36, 0.44); kind = 7   # issue 1741: the Directorate's cold vapour (no soot, no orange)
		if faction == "deathless":
			col = Color(0.055, 0.025, 0.09); kind = 8
		elif faction == "chorus":
			col = chorus_gas(glow) * 0.45; kind = 20
		for j in 4:
			fx.spr(p + d * r * 0.5, fx.now + j * 0.06, 0.9 + 0.2 * fx.rng.randf(), col, 0.55, r * 1.1, r * 4.2, kind,
				fx.rcone(d, 0.35) * r * (5.0 + 3.0 * fx.rng.randf()), 2.0)
	for j in (0 if wounds_v2 and faction == "chorus" else 5):   # issue 1741: a Chorus drive coughs spores, no sparks
		fx.stk(p + d * r * 0.4, fx.now + fx.rng.randf() * 0.12, 0.18 + 0.12 * fx.rng.randf(), eng.lerp(Color.WHITE, 0.3), 3.0,
			0.06, 0.08, 1, fx.rcone(d, 0.6) * r * (8.0 + 6.0 * fx.rng.randf()), 2.0)
	_wlog(["cough", sick_nozzle, fx.now])


# ---------------------------------------------------------------- capability loss (issue 1741 Milestone 3, R416)
# Behind VS_WOUNDS_V2=1 (rendering/effects/wounds_v2). The rules' own lost systems drive what the hull shows, so a
# "Forward weapons silenced" or "Engines crippled" line in the log has a picture on the ship:
#   - a weapon slot the view holds off (weapons[i].off > 0: a crit's 2, a lost section's 999) jams every turret that slot
#     owns (its hp_w<slot>_* muzzles hang under them) and kills its fixed mounts (one smokes and sparks for the slot);
#     a repair (off back to 0) frees them. Without a weapons list (a bench unit) the old section picker stays.
#   - the drive fails in tiers (engine_tier_for): one nozzle gutters, then one goes dark, then all but one are dark.
#   - a shielded ship whose generator is out (shieldOff, or the midship lost) crackles on the midship plating.
const SICK_LEN_CRIPPLED := 0.35   # the last nozzle's plume when the engines are crippled
const GEN_GAP := Vector2(1.4, 3.0)          # seconds between two generator crackles (reduce flashing: twice as long)


# The drive's damage tier: 1 an engine hit or the engine section at stage 2, 2 at stage 3, 3 at stage 4 (crippled).
static func engine_tier_for(eng_stage: int, engine_hit: bool) -> int:
	if eng_stage >= 4:
		return 3
	if eng_stage == 3:
		return 2
	return 1 if eng_stage == 2 or engine_hit else 0


# Which nozzles gutter and which are dark for this tier (sick_nozzle, dead_nozzles, _sick_len). One nozzle always burns.
func _engine_nozzles() -> void:
	var n: int = hull.nozzles.size()
	if eng_tier <= 0 or n == 0 or squadron:
		sick_nozzle = -1
		return
	sick_nozzle = posmod(_seed, n)
	if eng_tier == 1:
		_sick_len = 0.65
	elif eng_tier == 2:
		_sick_len = SICK_LEN
		if n >= 2:
			dead_nozzles = [(sick_nozzle + 1) % n]
	else:
		_sick_len = SICK_LEN_CRIPPLED
		for ni in n:
			if ni != sick_nozzle:
				dead_nozzles.append(ni)


# What the view says the ship has lost (read in sync; shown when the stages apply, after the volley's hits land).
func _read_capability(u: Dictionary, sec: Dictionary) -> void:
	_exact_slots = u.get("weapons") is Array
	_want_off = {}
	if _exact_slots:
		var ws: Array = u["weapons"]
		for j in ws.size():
			var w = ws[j]
			if w is Dictionary and w.get("off") != null and float(w["off"]) > 0.0:
				_want_off[int(w.get("i", j)) if w.get("i") != null else j] = str(w.get("arc", "")) if w.get("arc") != null else ""
	_want_eng_hit = u.get("engHit") == true
	var mid_lost: bool = sec.get("mid") is Dictionary and (sec["mid"] as Dictionary).get("broken") == true
	_want_gen = shielded and not squadron and (u.get("shieldOff") == true or mid_lost)


func _refresh_capability(fx) -> void:
	if hull == null or squadron:
		return
	var want: Dictionary = _want_off if _exact_slots else {}
	var knocked := []   # issue 1752: the slots newly off this sync (one knockout sound per ship per sync)
	for slot in _slot_off.keys():
		if want.has(slot):
			continue
		for key in _jammed.keys():
			if int(_jammed[key].get("slot", -1)) == int(slot):
				hull.unjam_turret(int(_jammed[key]["k"]), fx.now)
				_jammed.erase(key)
		_mount_dead.erase(slot)
		_slot_off.erase(slot)
		_wlog(["slot_on", slot, fx.now])
	for slot in want:
		if _slot_off.has(slot):
			continue
		_slot_off[slot] = true
		var ks: Array = hull.turrets_for_slot(int(slot))
		for ti in ks.size():
			var k: int = ks[ti]
			if hull.turret_jammed(k):
				continue
			var h := absi(_seed + int(slot) * 7919 + k * 104729)
			var off := (12.0 + float(h % 13)) * (1.0 if (h >> 4) % 2 == 0 else -1.0)
			var droop := 4.0 + float((h >> 6) % 4)
			hull.jam_turret(k, hull.turret_yaw(k, fx.now) + off, droop, fx.now)
			# two wisps per slot at most (the smoke slots are shared with the sections' own smoke)
			_jammed["s%d_t%d" % [int(slot), k]] = {"k": k, "next": fx.now + 1.0 + fx.rng.randf() * 2.0,
				"sec": hull.turret_section(k), "slot": int(slot), "wisp": ti < 2}
		var ms: Array = hull.mounts_for_slot(int(slot))
		if ks.is_empty() and ms.is_empty():
			# a hull with no point for this slot (an old A4 build): the slot's own section by its rules arc (F the prow,
			# P and S the midship, as the rules' section losses), else nothing; counted in the log, never silent
			var sec_for := {"F": HULL.SEC_PROW, "P": HULL.SEC_MID, "S": HULL.SEC_MID}
			var arc := str(want[slot])
			var picked := -1
			if sec_for.has(arc):
				# Artoo on PR 1749: only a turret no slot owns (an old hull's turret with no muzzle points); a turret that
				# belongs to a live slot never jams for another slot's loss
				for k in hull.turrets.size():
					if hull.turret_section(k) == int(sec_for[arc]) and not hull.turret_jammed(k) and not hull.turret_owned(k):
						picked = k
						break
			if picked >= 0:
				var h2 := absi(_seed + int(slot) * 7919)
				hull.jam_turret(picked, hull.turret_yaw(picked, fx.now) + (12.0 + float(h2 % 13)) * (1.0 if (h2 >> 4) % 2 == 0 else -1.0), 4.0 + float((h2 >> 6) % 4), fx.now)
				_jammed["s%d_t%d" % [int(slot), picked]] = {"k": picked, "next": fx.now + 1.0 + fx.rng.randf() * 2.0,
					"sec": hull.turret_section(picked), "slot": int(slot), "wisp": true}
			elif sec_for.has(arc):
				# no unowned turret: the section's plating smokes and sparks for the slot, no gun's state changes
				var sa := _anchor(int(sec_for[arc]), "sc1")
				if not sa.is_empty():
					_mount_dead[slot] = {"p": sa["p"], "n": sa["n"], "sec": int(sec_for[arc]), "next": fx.now + 0.6 + fx.rng.randf() * 1.5}
			_wlog(["slot_fallback", slot, picked])
		if not ms.is_empty() and not _mount_dead.has(slot):
			var pt: Dictionary = ms[ms.size() / 2]
			var mp: Vector3 = pt["p"]
			_mount_dead[slot] = {"p": mp, "n": pt.get("n", Vector3.UP), "sec": hull.section_of(mp.x),
				"next": fx.now + 0.6 + fx.rng.randf() * 1.5}
		_wlog(["slot_off", slot, fx.now])
		knocked.append(slot)
	# issue 1752: metal hulls only (the Chorus throw no sparks, glass and obsidian are not plated guns); once per sync
	if not knocked.is_empty() and _cap_seen and not dead and HULL.target_substance(faction) == "metal":
		var md = _mount_dead.get(knocked[0])
		_cue(fx, "dmg_turret_knockout", to_world(md["p"]) if md is Dictionary else root.global_position)
	var g: bool = _want_gen and not dead
	if g != gen_down:
		# issue 1752: the generator's false-to-true edge crackles at full level once; its repeats are quiet
		if g and _cap_seen:
			_cue(fx, "dmg_shield_burnout", root.global_position)
			_gen_loud_at = fx.now
		gen_down = g
		_gen_next = fx.now + 0.15   # the generator's first crackle comes right as it goes
		_wlog(["gen", 1 if g else 0, fx.now])


# Every frame (from _wound_step): sparks at the dead fixed mounts and the failing generator's crackle.
func _capability_step(fx) -> void:
	for slot in _mount_dead:
		var md: Dictionary = _mount_dead[slot]
		if fx.now < float(md["next"]):
			continue
		md["next"] = fx.now + 2.0 + fx.rng.randf() * 2.5
		_wlog(["mount_spark", slot, fx.now])
		if faction == "chorus":
			continue   # flesh: the mount's spore wisp only, no metal sparks (R416 trap 2)
		var p := to_world(md["p"])
		var n := dir_world(md["n"]).normalized()
		var sc: Color = (fac["engine"] as Color).lerp(Color.WHITE, 0.55)
		for j in 3:
			fx.stk(p, fx.now + fx.rng.randf() * 0.05, 0.18 + fx.rng.randf() * 0.12, sc, 3.5, 0.05, 0.07, 1,
				(fx.rcone(n, 0.7)) * hull.L * (0.06 + 0.05 * fx.rng.randf()), 2.0)
	if gen_down and fx.now >= _gen_next:
		var k: float = 2.0 if fx.reduce_flashing else 1.0
		_gen_next = fx.now + (GEN_GAP.x + fx.rng.randf() * (GEN_GAP.y - GEN_GAP.x)) * k
		_gen_crackle(fx)
		# the quiet repeats (the visual's first crackle, 0.15 s after the edge, is covered by the loud one)
		if faction != "chorus" and fx.now - _gen_loud_at > 0.6:
			_cue(fx, "dmg_shield_burnout", root.global_position, 0.35)


# A failed shield emitter arcs on the midship plating: a short jagged run of small sparks in the shield's own colour (a dim
# local light with it, none under reduce flashing). Small and brief: never a big flash (RULEBOOK 6.2).
func _gen_crackle(fx) -> void:
	if faction == "chorus":
		return   # flesh throws no sparks (R416 trap 2); the Chorus carry no shield today, this keeps it true if one is given
	var a := _anchor(1, "sc0")
	if a.is_empty():
		var c: Dictionary = hull.core_point()
		if c.is_empty():
			return
		a = {"p": c["p"], "n": Vector3.UP}
	var n: Vector3 = (a["n"] as Vector3).normalized()
	var tng := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
	var p0 := to_world(a["p"] + n * hull.L * 0.004)
	var col: Color = fac.get("shield") if fac.get("shield") is Color else (fac["engine"] as Color)
	col = col.lerp(Color.WHITE, 0.45)
	var wt := dir_world(tng).normalized()
	var wn := dir_world(n).normalized()
	var step: float = hull.L * 0.012
	var p := p0
	for j in 5:
		var jag: Vector3 = (wt + wn * (fx.rng.randf() - 0.3) * 0.8).normalized()
		fx.stk(p, fx.now + j * 0.02, 0.12 + 0.06 * fx.rng.randf(), col, 4.0, step * 1.2, 0.05, 1, jag * step * 6.0, 0.5)
		p += jag * step
	if not fx.reduce_flashing:
		fx.light(p0, fx.now, 0.12, 0.9, col, 1)
	_wlog(["gen_arc", 1, fx.now])


# Engines crippled: as the ship tries to move, the dark bells spit a few sparks.
func _stern_sparks(fx) -> void:
	_wlog(["stern_spark", dead_nozzles.size(), fx.now])
	if faction == "chorus":
		return   # a dead Chorus drive only coughs its spores (_cough)
	var eng: Color = (fac["engine"] as Color).lerp(Color.WHITE, 0.4)
	for ni in dead_nozzles:
		var nz: Dictionary = hull.nozzles[ni]
		var p := to_world(nz["p"])
		var d := dir_world(nz.get("d", Vector3(-1, 0, 0))).normalized()
		for j in 3:
			fx.stk(p, fx.now + fx.rng.randf() * 0.1, 0.16 + 0.1 * fx.rng.randf(), eng, 3.0, 0.05, 0.07, 1,
				fx.rcone(d, 0.7) * float(nz["r"]) * (6.0 + 4.0 * fx.rng.randf()), 2.0)


# The knocked-out slots as shown, the turrets jammed for them and the slots whose fixed mount smokes (for the checks).
func capability_state() -> Dictionary:
	var tur: Array = []
	for key in _jammed:
		if _jammed[key].has("slot"):
			tur.append(int(_jammed[key]["k"]))
	tur.sort()
	var off: Array = _slot_off.keys()
	off.sort()
	var md: Array = _mount_dead.keys()
	md.sort()
	return {"off": off, "turrets": tur, "mounts": md, "eng_tier": eng_tier, "sick": sick_nozzle,
		"dead_nozzles": dead_nozzles.duplicate(), "gen": gen_down}


# Issue 1752: a damage sound through the battle's sound node (fx.sound(), as the missed-shot pass-by), if there is one.
func _cue(fx, name: String, p: Vector3, gain := 1.0) -> void:
	_wlog(["sound", name, fx.now])
	var sx = fx.sound() if fx.has_method("sound") else null
	if sx != null:
		sx.play(name, {"pos": p, "gain": gain})


# Issue 1752 (plan row 3): the stage 4 cutout opening. Every hull vents; metal hulls also shear (glass, bio and obsidian
# opening sounds come from their own impact cue, so no metal sound on a Chorus or Glasswright breach).
func _breach_sound(fx, i: int) -> void:
	if squadron or weight <= 0 or hull == null or fx.compat or dead:
		return
	var a := _anchor(i, "a")
	if a.is_empty():
		return
	var p := to_world(a.p)
	_cue(fx, "dmg_breach_vent", p)
	if HULL.target_substance(faction) == "metal":
		_cue(fx, "dmg_breach_shear", p)


func _wlog(e: Array) -> void:
	if wound_log_on:
		wound_log.append(e)


# Jam one turret in each mid or prow section at stage 3+, free it when the section is repaired below 3.
func _refresh_wounds(fx) -> void:
	if hull == null:
		return
	if wounds_v2 and _exact_slots:
		# issue 1741: the view says which slots are out, so the section's random turret is never jammed
		for sec in [1, 2]:
			if _jammed.has(sec):
				hull.unjam_turret(int(_jammed[sec]["k"]), fx.now)
				_jammed.erase(sec)
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
			_jammed[sec] = {"k": k, "next": fx.now + 1.0 + fx.rng.randf() * 2.0, "sec": sec}
		elif not hurt and _jammed.has(sec):
			hull.unjam_turret(int(_jammed[sec]["k"]), fx.now)
			_jammed.erase(sec)


func jammed_turrets() -> Array:
	var out: Array = []
	for sec in _jammed:
		out.append(int(_jammed[sec]["k"]))
	return out


# Jammed turrets and dead mounts/nozzles hand their existing attachment to the shared thin plume.
func _build_wisp(fx, e: Dictionary) -> void:
	var p: Vector3 = (e["mp"] as Vector3) if e.has("mp") else (hull.turrets[int(e["tur"])]["xf"] as Transform3D).origin + Vector3.UP * hull.L * 0.01
	_attach_damage_plume(fx, e, p, Vector3.UP, hull.L * 0.095, DAMAGE_PLUME.Form.WISP)


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
		if wounds_v2 and faction == "deathless":
			sc = (fac["damage_glow"] as Color).lerp(Color.WHITE, 0.4)   # issue 1741: Eclipse sparks in its own violet
		if wounds_v2 and faction == "chorus":
			_wlog(["spark", k, fx.now])   # issue 1741 (R416 trap 2): flesh does not throw metal sparks; the wisp carries it
			continue
		for j in 4:
			fx.stk(p, fx.now + fx.rng.randf() * 0.05, 0.2 + fx.rng.randf() * 0.15, sc, 4.0, 0.05, 0.08, 1,
				(fx.rdir() + Vector3.UP * 0.6).normalized() * hull.L * (0.08 + 0.06 * fx.rng.randf()), 2.0)
		if not fx.reduce_flashing:
			fx.light(p, fx.now, 0.15, 1.5, sc, 1)
		_wlog(["spark", k, fx.now])
	if wounds_v2:
		_capability_step(fx)
	_write_flick(power_flicker(fx.now, fx.reduce_flashing) * (1.0 - _power_dip))


func _write_flick(f: float) -> void:
	if f == _power_shown or _damage_surfaces.is_empty():
		return
	_power_shown = f
	for key in _damage_surfaces:
		var entry: Array = _damage_surfaces[key]
		if entry.size() > 1 and entry[1] is ShaderMaterial:
			(entry[1] as ShaderMaterial).set_shader_parameter("fx_flick", f)


# The power multiplier (1 steady) at time t: with mid or prow at stage 3+, uneven brownouts in steps of 1/12 s (a small dip
# most of the time, now and then a deep one). Under reduce flashing, slower and shallower steps. A hit's brownout
# (hit_power) multiplies onto this in _wound_step.
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
	return f


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
	var eclipse_wound := wounds_v2 and faction == "deathless"
	if eclipse_wound:
		glow = BREACH.wound_col(fac["wound"], "interior_accent", glow)
		col = glow
	if faction == "chorus":
		col = chorus_gas(glow) * 0.6; kind = 20
	var heavy := int(stage[i]) == 4
	for j in 7:
		var t: float = fx.now + j * 0.08
		fx.spr(p + n * L * 0.01, t, BLOWOUT_LIFE - j * 0.08, col, 0.55 if heavy else 0.45, L * 0.008, L * (0.06 if heavy else 0.045),
			kind, fx.rcone(n, 0.22) * L * (0.38 - j * 0.03), 1.6)
	for j in 3 + posmod(_seed + i, 2):
		DEATH.BEATS.debris(fx, self, p, fx.now + j * 0.05, 1.6, fx.rcone(n, 0.6) * L * (0.10 + 0.05 * fx.rng.randf()), L * 0.006, 0.5)
	fx.light(p + n * L * 0.03, fx.now, 0.35, 2.5, glow if eclipse_wound else glow.lerp(Color.WHITE, 0.5), 1)
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
	if dead or gone or hull == null:
		return
	var h: Dictionary = {}
	if kind == "acid":
		var spots: Array = get_meta("acid_spots", [])
		if not spots.is_empty() and spots.back().size() > 2:
			h = {"p": spots.back()[0], "n": spots.back()[2]}
	elif kind == "tidal" and fx.well.is_finite():
		var local_well: Vector3 = xf().affine_inverse() * fx.well
		h = hull.surface(hull.core, (local_well - hull.core).normalized())
	if h.is_empty():
		h = hull.surface_sample(-1, 0.65, "flare")
	if h.is_empty():
		return
	STATUS_TICK.play(fx, self, kind, h)
	# Keep the tidal spark site for the shared spark upgrade. Living hulls shed glowing organic motes only.
	if kind == "tidal" and faction != "chorus":
		var wp := to_world(h["p"])
		var k := scale_k()
		var T: float = fx.now
		for i in 20:
			fx.stk(wp + fx.rdir() * 3.0 * k, T + fx.rng.randf() * 0.3, 0.5, Color(0.7, 0.8, 1.0), 4.0, 0.15, 0.1, 1, fx.rdir() * 6.0, 0.5)


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
func _regrade_marks() -> bool:
	var changed := false
	var updated: Array = []
	for e in _marks:
		if e.look == "v2hole":
			updated.append(e)   # a V2 cutout keeps its size: it is not regraded from a weapon look
			continue
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
	return changed
