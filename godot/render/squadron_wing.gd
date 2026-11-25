extends Node3D
# Local flight stays around the wing's anchor. Only ShipView moves the rules unit.
# Each ribbon samples its own craft's stern in world space, including turns.
const CRAFT := preload("res://render/squadron_craft.gd")
const LOOK := preload("res://fx/faction_look.gd")
static var ship_manifest_path := "res://assets/ships/manifest.json"
static var ship_cache_dir := "res://gen/ships"
static var _model_codes: Dictionary = {}   # not GPU: model code strings
static var _indexed_manifest := ""
# Local flight amplitudes, in craft lengths and radians. Formation clearance
# includes the whole weave, bank and (for spores) breathing cycle.
const WEAVE := Vector3(0.12, 0.09, 0.14)
const SPORE_SWAY := 0.24
const BANK := Vector3(0.22, 0.12, 0.065)
const SPORE_BANK := 0.29
const BREATH := 0.025
const CLEARANCE := 0.04 # visible air between swept hull bounds, in craft lengths
# Parked flight: three pockets around the anchor, each with its own pace and turn direction.
# A Chorus swarm uses two staggered tiers of the same three pockets.
const PATROL_PERIODS := [5.2, -6.3, 4.6, -5.8, 4.9, -6.7]
const PATROL_ASPECT := 0.54
const JINK := 0.26
const ROLL_SLOT := 3.65
const ROLL_TIME := 1.45
const TURN_SAMPLE := 0.06
var craft: Array = []
var trails: Array = []
var rests: Array = []
var clock := 0.0
var phase := 0.0
var length := 3.84
var faction := "hegemony"
var active := true
var patrol_limit := 0.0 # battle wings opt in; strike and intercept effects keep their original weave
var patrol_target := 0.0
var _patrol_center := 0.0
var _patrol_span := 0.0
var _patrol_tier := 0.0
var _patrol_axes: Array[Vector3] = []
var _attitudes: Array[Quaternion] = []
var _patrol_blend := 0.0
var sample_t := 0.0
var trail_mat: ShaderMaterial
const TRAIL_LIFE := 0.65
const TRAIL_LIFE_CHORUS := 0.2
var trail_life := TRAIL_LIFE
var _model_scene: PackedScene
var _stern := Vector3(-0.47, 0.0, 0.0)
# issue 221: the ribbon's ageing (drift back along the craft's wake, widening, fading) runs in the vertex shader from
# each sample's birth time (UV2.x) and the wing's clock, so the mesh is rebuilt only when a sample is added or dropped,
# not every frame. Same maths as the old per-frame GDScript build.
const TRAIL := preload("res://shaders/squadron_trail.gdshader")

# issue 1434 (Artoo on PR 1445): setup's main-thread time by stage in microseconds (load, instance, finish, copies), copied
# into ShipView.stage_us for the load bench
var stage_us := {}


func setup(fac: String, kind: String, size: float, count := 4, seed_value := 0.0) -> void:
	stage_us = {}
	faction = fac
	length = size
	phase = seed_value
	trail_mat = ShaderMaterial.new()
	trail_mat.shader = TRAIL
	trail_mat.set_shader_parameter("trail_len", size)
	# Ryan (Nov 20 2026, issue 1373): the long wide Chorus wake made each spore read as a tadpole ("comes off looking like
	# sperm"); a spore now leaves only a short faint shimmer that is gone within a craft length or two
	trail_life = TRAIL_LIFE_CHORUS if fac == "chorus" else TRAIL_LIFE
	trail_mat.set_shader_parameter("width_k", 0.022 if fac == "chorus" else 0.026)
	trail_mat.set_shader_parameter("alpha_k", 0.14 if fac == "chorus" else 0.56)
	trail_mat.set_shader_parameter("life", trail_life)
	if count <= 0:
		return
	var t_make := Time.get_ticks_usec()
	var lead := _make_craft(fac, kind)
	var t_fin := Time.get_ticks_usec()
	finish(lead, fac)
	stage_us["wing_finish"] = Time.get_ticks_usec() - t_fin
	stage_us["wing_make"] = t_fin - t_make
	var t_copies := Time.get_ticks_usec()
	for i in count:
		var n: Node3D = lead if i == 0 else lead.duplicate()
		add_child(n)
		n.scale = Vector3.ONE * size * (0.83 if fac == "chorus" and i % 2 else 1.0)
		craft.append(n)
		var ribbon := MeshInstance3D.new()
		ribbon.name = "fx_craft_trail_%d" % i
		ribbon.top_level = true
		ribbon.mesh = ImmediateMesh.new()
		ribbon.material_override = trail_mat
		ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ribbon.extra_cull_margin = 20.0
		add_child(ribbon)
		ribbon.global_transform = Transform3D.IDENTITY
		trails.append({"node": ribbon, "hist": []})
	stage_us["wing_copies"] = Time.get_ticks_usec() - t_copies
	fit_formation()
	_patrol_blend = patrol_target
	step(0.0)


# R362 (docs/playbooks/ships.md section 9): strike craft take the hull finish, the same LOOK.hull pass ShipView gives a
# hull (faction brightness band, material rim, and the "look_hull" mark that puts them under the rim light). One material
# copy per source material and faction, shared by every craft of that kind; duplicates of the lead keep the overrides.
static var _finish_cache := {}   # not GPU: weak references to shared materials


static func finish(root: Node, fac: String) -> void:
	if root == null or not ResourceLoader.exists("res://render/look.gd"):
		return
	var LOOK = load("res://render/look.gd")
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or String(mi.name).begins_with("fx_"):
			continue
		for i in mi.mesh.get_surface_count():
			var src: Material = mi.get_active_material(i)
			if src == null or src.has_meta("look_hull"):
				continue
			var k := "%d|%s" % [src.get_instance_id(), fac]
			var done: Material = null
			if _finish_cache.has(k):
				done = _finish_cache[k].get_ref()
			if done == null:
				done = LOOK.hull(src, fac, true)
				if done == src:
					# The code-built fallback skin (a shader) has no brightness band; it still joins the rim light.
					done = src.duplicate()
					done.set_meta("look_hull", fac)
				_finish_cache[k] = weakref(done)
			mi.set_surface_override_material(i, done)


static func _model_code(fac: String, kind: String) -> String:
	if _indexed_manifest != ship_manifest_path:
		_indexed_manifest = ship_manifest_path
		_model_codes.clear()
		if FileAccess.file_exists(ship_manifest_path):
			var manifest = JSON.parse_string(FileAccess.get_file_as_string(ship_manifest_path))
			if manifest is Dictionary and manifest.get("ships") is Dictionary:
				for code in manifest["ships"]:
					var row = manifest["ships"][code]
					if row is Dictionary and row.get("cls") == "Squadron" and row.has("wing_role"):
						var key := "%s|%s" % [row.get("faction", ""), row["wing_role"]]
						# Ambiguous entries fall back to the procedural craft.
						_model_codes[key] = "" if _model_codes.has(key) else code
	return _model_codes.get(fac + "|" + kind, "")


# Ryan (Nov 21 2026, issue 1373): the Hullbreaker fighter, a deep box of plate, read about twice the size of the other factions'
# slim fighters at the same length; it is drawn at 0.7 of the unit length.
const CRAFT_K := {"corsair_KF1": 0.7}


# the installed model scene for this faction and role, or "" (the procedural craft); issue 1434: the battle preloads it
static func model_res(fac: String, kind: String) -> String:
	var code := _model_code(fac, kind)
	var path := ship_cache_dir.path_join(code + ".scn")
	return path if not code.is_empty() and ResourceLoader.exists(path, "PackedScene") else ""


func _make_craft(fac: String, kind: String) -> Node3D:
	var code := _model_code(fac, kind)
	var path := ship_cache_dir.path_join(code + ".scn")
	if code.is_empty() or not ResourceLoader.exists(path, "PackedScene"):
		return CRAFT.make(fac, kind)
	var t_load := Time.get_ticks_usec()
	_model_scene = ResourceLoader.load(path, "PackedScene") as PackedScene
	stage_us["wing_load"] = Time.get_ticks_usec() - t_load
	if _model_scene == null:
		return CRAFT.make(fac, kind)
	var t_inst := Time.get_ticks_usec()
	var model := _model_scene.instantiate()
	stage_us["wing_inst"] = Time.get_ticks_usec() - t_inst
	if not model is Node3D:
		model.free()
		return CRAFT.make(fac, kind)
	var body := model as Node3D
	var box := _mesh_bounds(body, body.transform)
	if box.size.x <= 0.0:
		body.free()
		return CRAFT.make(fac, kind)
	# The formation animates a unit-length root. Fit only its model child so
	# all poses, including the shorter effect passes, use the same scale.
	# CRAFT_K: a model drawn smaller than the unit length when its bulk reads too big beside the other factions' craft
	var k: float = CRAFT_K.get(code, 1.0) / box.size.x
	var fit := Transform3D(Basis.from_scale(Vector3.ONE * k), -box.get_center() * k)
	body.transform = fit * body.transform
	_stern = _engine_origin(body)
	var craft_root := Node3D.new()
	craft_root.name = fac + "_" + kind
	craft_root.set_meta("model_code", code)   # issue 1373: acceptance runs assert the installed model, never the code fallback
	craft_root.add_child(body)
	return craft_root


func _engine_origin(model: Node3D) -> Vector3:
	var engines := model.find_children("hp_eng_*", "Node3D", true, false)
	if engines.is_empty():
		return Vector3(-0.5, 0.0, 0.0)
	# One ribbon per craft starts at the centre of its authored exhausts.
	var origin := Vector3.ZERO
	for engine in engines:
		var point: Vector3 = engine.position
		var ancestor := engine.get_parent() as Node3D
		while ancestor != null:
			point = ancestor.transform * point
			ancestor = ancestor.get_parent() as Node3D
		origin += point
	return origin / engines.size()

# Measure in each craft's local frame, including nested mesh transforms and
# off-centre hulls. Never measure the ribbons or the current animated root.
func _mesh_bounds(n: Node3D, xf := Transform3D.IDENTITY) -> AABB:
	var box := AABB()
	if n is MeshInstance3D and n.mesh != null:
		box = xf * n.get_aabb()
	for child in n.get_children():
		if child is Node3D and not String(child.name).begins_with("fx_"):
			var other := _mesh_bounds(child, xf * child.transform)
			if other.size != Vector3.ZERO:
				box = box.merge(other) if box.size != Vector3.ZERO else other
	return box

func _flight_extent(r: Vector3) -> Vector3:
	# Godot's YXZ Euler order applies Z, then X, then Y. Absolute sine
	# bounds cover every rotation in step(), with cosines bounded by one.
	var z := sin(BANK.z)
	var x := sin(SPORE_BANK if faction == "chorus" else BANK.x)
	var y := sin(BANK.y)
	var rz := Vector3(r.x + r.y * z, r.y + r.x * z, r.z)
	var rx := Vector3(rz.x, rz.y + rz.z * x, rz.z + rz.y * x)
	return Vector3(rx.x + rx.z * y, rx.y, rx.z + rx.x * y)

func _side_reach(a: Vector3, b: Vector3, delta: float) -> float:
	var bank_x := SPORE_BANK if faction == "chorus" else BANK.x
	var sway := length * (SPORE_SWAY if faction == "chorus" else WEAVE.z)
	var ca := a.y * bank_x + a.x * BANK.y
	var cb := b.y * bank_x + b.x * BANK.y
	# Bank and sway share t. Maximise their combined sinusoid for each sign
	# of the absolute cosine terms, rather than adding impossible extremes.
	# This keeps slim craft (including SB4) at their original offsets.
	var peak := 0.0
	for sa in [-1.0, 1.0]:
		for sb in [-1.0, 1.0]:
			for sw in [-1.0, 1.0]:
				var c: float = ca * sa + cb * sb * cos(delta) - sway * sw * sin(delta)
				var s: float = -cb * sb * sin(delta) + sway * sw * (1.0 - cos(delta))
				peak = maxf(peak, Vector2(c, s).length())
	# sin(angle) <= abs(angle); cos(angle) <= 1. The two small product
	# terms cover roll feeding into pitch and yaw, at every flight phase.
	return a.z + b.z + peak + ((a.x + b.x) * bank_x + (a.y + b.y) * BANK.y) * BANK.z

# Also callable after replacing a preview's craft meshes. Normal play measures
# its actual geometry once at setup, without per-frame mesh walks.
func fit_formation() -> void:
	rests.clear()
	var extents: Array[Vector3] = []
	var radii: Array[Vector3] = []
	var row_length := length
	for i in craft.size():
		var box := _mesh_bounds(craft[i])
		row_length = maxf(row_length, box.size.x * length)
		var scale_k := length * (0.83 if faction == "chorus" and i % 2 else 1.0)
		var r := box.position.abs().max(box.end.abs()) * scale_k * (1.0 + BREATH if faction == "chorus" else 1.0)
		radii.append(r)
		extents.append(_flight_extent(r))
	# A symmetric arrowhead (R280): the leader at the origin, then row 1 holds
	# two craft, row 2 three, and so on, every row centred on the leader's line
	# and spread by the same lateral step. Counts 3 and 6 read as a clean
	# triangle; any other count fills the rows in order (setup accepts any).
	rests.resize(craft.size())
	rests.fill(Vector3.ZERO)
	var idx := 1
	var row := 1
	while idx < craft.size():
		var in_row := row + 1
		for k in in_row:
			if idx >= craft.size():
				break
			var lateral := (float(in_row - 1) * 0.5 - float(k)) * 1.9 * length
			rests[idx] = Vector3(-0.95 * float(row) * row_length,
				(0.12 if idx % 2 else -0.09) * length, lateral)
			idx += 1
		row += 1
	var width_k := 1.0
	var depth_k := 1.0
	for i in craft.size():
		for j in i:
			var apart: Vector3 = (rests[i] - rests[j]).abs()
			var need_x: float = extents[i].x + extents[j].x + (2.0 * WEAVE.x + CLEARANCE) * length
			if is_zero_approx(apart.z):
				# Same lateral line: the leader against an even row's centre
				# craft (R280's wedge). Only more depth can separate them.
				if apart.x > 1e-6:
					depth_k = maxf(depth_k, need_x / apart.x)
			elif apart.x < need_x:
				var reach := _side_reach(radii[i], radii[j], (j - i) * 1.73)
				width_k = maxf(width_k, (reach + CLEARANCE * length) / apart.z)
	for i in rests.size():
		rests[i].z *= width_k
		rests[i].x *= depth_k
	if patrol_limit > 0.0 and not rests.is_empty():
		_fit_patrol(radii)


func _fit_patrol(radii: Array[Vector3]) -> void:
	# A sphere around each measured mesh covers any bank or roll. Every pocket
	# fits inside the hex's incircle, and adjacent pockets on a tier are separated
	# by a plane halfway between their centres.
	var reach := 0.0
	for r in radii:
		reach = maxf(reach, r.length())
	var pad := CLEARANCE * length * 0.5
	var room := maxf(0.0, patrol_limit - reach - pad)
	_patrol_center = room * 0.79
	_patrol_tier = reach + pad
	var half_gap := sqrt(3.0) * 0.5
	var radial_projection := half_gap * PATROL_ASPECT / (1.0 + JINK)
	# Support of the ellipse along the separating plane's normal, plus the jink.
	var toward_neighbor := Vector2(radial_projection, 0.5).length() + radial_projection * JINK
	var hi := clampf((_patrol_center * half_gap - reach - pad) / toward_neighbor, 0.0, 2.9)
	var lo := 0.0
	for attempt in 10:
		var span := (lo + hi) * 0.5
		if Vector2(_patrol_center + span * PATROL_ASPECT, span).length() <= room:
			lo = span
		else:
			hi = span
	_patrol_span = lo
	_patrol_axes.clear()
	for i in rests.size():
		var angle := -TAU * float(i % 3) / 3.0 + (PI / 3.0 if i >= 3 else 0.0)
		_patrol_axes.append(Vector3(cos(angle), 0.0, sin(angle)))


func _roll_progress(i: int, t: float) -> float:
	# Only one craft breaks into a climbing roll at a time, then another takes a turn.
	var count := mini(craft.size(), PATROL_PERIODS.size())
	var beat := fposmod(t + phase, ROLL_SLOT * count)
	return smoothstep(0.0, ROLL_TIME, beat - i * ROLL_SLOT)


func _patrol_position(i: int, t: float) -> Vector3:
	var p := phase + i * 2.41
	var a: float = t * TAU / PATROL_PERIODS[i % PATROL_PERIODS.size()] + p
	# A quicker cut across one part of the loop, with a slower return to the wing.
	a += 0.28 * sin(a + p) + 0.11 * sin(2.0 * a - p)
	var spread := 0.76 + 0.24 * sin(t * 0.58 + phase) * cos(t * 0.22 + p)
	var span := _patrol_span * (1.0 - 0.12 * float(i % 3))
	var minor := (cos(a) + JINK * sin(2.0 * a + p)) / (1.0 + JINK)
	var radial := _patrol_center + span * PATROL_ASPECT * (spread * minor - 0.6 * (1.0 - spread))
	var axis := _patrol_axes[i]
	var rise := sin(a + p) * (0.44 + 0.13 * float(i % 3))
	var climb := 1.65 * pow(sin(PI * _roll_progress(i, t)), 2.0)
	# Keep the tiers apart even during the dive or climb, without shrinking the spores.
	var y := rise + climb
	if craft.size() > 3:
		y = (_patrol_tier + 0.7 + y) * (-1.0 if i >= 3 else 1.0)
	return axis * radial + axis.cross(Vector3.UP) * (span * spread * sin(a)) + Vector3.UP * y


func _patrol_attitude(i: int, pos: Vector3) -> Quaternion:
	var enter := (pos - _patrol_position(i, clock - TURN_SAMPLE)).normalized()
	var leave := (_patrol_position(i, clock + TURN_SAMPLE) - pos).normalized()
	# Bow along the flight path; use signed curvature for the ordinary bank.
	var bow := (enter + leave).normalized()
	var side := bow.cross(Vector3.UP).normalized()
	var bank := clampf(-enter.cross(leave).y * 4.5, -0.68, 0.68)
	var roll := TAU * _roll_progress(i, clock) * (1.0 if i % 2 == 0 else -1.0)
	return (Basis(bow, side.cross(bow), side) * Basis(Vector3.RIGHT, bank + roll)).get_rotation_quaternion()

func _process(dt: float) -> void:
	step(dt)


# Battle wings are stepped by ShipView and attack runs by FX, both in effect seconds.
func step(dt: float) -> void:
	clock += dt
	sample_t += dt
	# Issue 1467: cap the pose correction on a slow frame. Weave and trail age keep the full effect time.
	var pose_dt := minf(dt, 1.0 / 30.0)
	var sample := sample_t >= 1.0 / 30.0
	if sample: sample_t = 0.0
	trail_mat.set_shader_parameter("clock_now", clock)
	var gain := 0.0
	if active and _patrol_span > 0.0:
		_patrol_blend = maxf(patrol_target, _patrol_blend - 2.0 * dt)
		gain = smoothstep(0.0, 1.0, _patrol_blend)
	for i in craft.size():
		var n: Node3D = craft[i]
		if active:
			var t := clock * (1.8 if faction == "chorus" else 1.25) + phase + i * 1.73
			var sway := SPORE_SWAY if faction == "chorus" else WEAVE.z
			var pos: Vector3 = rests[i] + length * Vector3(sin(t * 0.77) * WEAVE.x, sin(t * 1.19) * WEAVE.y, sin(t) * sway)
			# Bow follows the weave; roll anticipates the next turn.
			var bank := Vector3(-cos(t) * (SPORE_BANK if faction == "chorus" else BANK.x), -cos(t) * BANK.y, cos(t * 1.19) * BANK.z)
			var facing := Basis.from_euler(bank)
			var attitude := facing.get_rotation_quaternion() if _patrol_span > 0.0 else Quaternion.IDENTITY
			if gain > 0.0:
				var parked := _patrol_position(i, clock)
				pos = pos.lerp(parked, gain)
				attitude = attitude.slerp(_patrol_attitude(i, parked), gain)
				# Filter the hand-off when a craft turns through the travel pose's back side.
				if pose_dt > 0.0:
					var last := _attitudes[i]
					var weight := 1.0 - exp(-24.0 * pose_dt)
					if gain < 1.0:
						var turn := 2.0 * acos(clampf(absf(last.dot(attitude)), 0.0, 1.0))
						weight = minf(weight, 12.0 * pose_dt / maxf(turn, 0.001))
					attitude = last.slerp(attitude, weight).normalized()
				facing = Basis(attitude)
			if _patrol_span > 0.0:
				if i == _attitudes.size(): _attitudes.append(attitude)
				else: _attitudes[i] = attitude
			var size := length * ((0.83 if i % 2 else 1.0) * (1.0 + BREATH * sin(t * 2.0)) if faction == "chorus" else 1.0)
			n.transform = Transform3D(facing.scaled(Vector3.ONE * size), pos)
		var tr: Dictionary = trails[i]
		var hist: Array = tr.hist
		var stern := n.to_global(_stern)
		var changed := false
		if not hist.is_empty() and stern.distance_to(hist[0][0]) > length * 8.0:
			hist.clear()
			changed = true
		if active and sample:
			hist.push_front([stern, clock, -n.global_basis.x.normalized()])
			changed = true
		# issue 1558 item 9: drop old samples on the same 30 Hz step that adds one, so the mesh is rebuilt once per sample,
		# not on the frames between (the oldest sample lingers at most 1/30 s past its life, where the shader has faded it)
		while not hist.is_empty() and (sample or not active) and (clock - float(hist[-1][1]) > trail_life or hist.size() > 20):
			hist.pop_back()
			changed = true
		# issue 221: the shader ages the ribbon; the mesh only changes with its samples
		if changed or not tr.get("built", false):
			_draw_trail(tr)

func _draw_trail(tr: Dictionary) -> void:
	tr["built"] = true
	var mesh: ImmediateMesh = tr.node.mesh
	mesh.clear_surfaces()
	var hist: Array = tr.hist
	if hist.size() < 2: return
	var col: Color = LOOK.of(faction).engine
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for j in hist.size():
		# the sample's stern point, its wake direction and birth time; the vertex shader drifts, widens and fades it
		var p: Vector3 = hist[j][0]
		var back: Vector3 = hist[j][2]
		var born := float(hist[j][1])
		mesh.surface_set_color(Color(col.r, col.g, col.b, 1.0))
		mesh.surface_set_normal(back)
		mesh.surface_set_uv(Vector2(0, 0))
		mesh.surface_set_uv2(Vector2(born, 0))
		mesh.surface_add_vertex(p)
		mesh.surface_set_color(Color(col.r, col.g, col.b, 1.0))
		mesh.surface_set_normal(back)
		mesh.surface_set_uv(Vector2(0, 1))
		mesh.surface_set_uv2(Vector2(born, 0))
		mesh.surface_add_vertex(p)
	mesh.surface_end()
