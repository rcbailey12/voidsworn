extends Node3D
# One ship on the board: its hull (the game's mesh for its faction and class, or the 8K version for a flagship), scaled to
# the class length, turned to its facing, with engine glows, a selection ring, and the animation of its moves.

const HT := preload("res://render/hull_table.gd")

var u: Dictionary
var hull: Node3D
var L := 10.0
var fac := "hegemony"
var code := ""
var ring: MeshInstance3D
var engines: Array = []
var speed_k := 1.0          # the battle's SPEED (Enter or Space hurries a burn already under way)
var cur_yaw := 0.0
var dead := false
var sink := 0.0
var bob_seed := 0.0
var meshes: Array = []
var fade := 1.0
var hull_base := Vector3.ZERO
var hull_basis := Basis.IDENTITY # the hull's fitted basis (scale, mirror, yaw fix); bank and pitch are laid over it
var a4 := false              # an A4 kit ship (not mirrored)

static var _manifest = null


static func manifest() -> Dictionary:
	if _manifest == null:
		_manifest = {}
		if FileAccess.file_exists("res://gen/manifest.json"):
			_manifest = JSON.parse_string(FileAccess.get_file_as_string("res://gen/manifest.json"))
	return _manifest


# drop the static caches before the engine shuts down (resources held in statics outlive the RenderingServer and crash
# the exit on Windows: PC bot runs ended with an access violation after the summary)
static func clear_static() -> void:
	_manifest = null
	_look_cache.clear()
	_gt = null


static func yaw_of(f) -> float:
	return -deg_to_rad(60.0 * float(f))


# unit: a ship from the rules API's view() (id, fac, cls, facing ...)
func setup(unit: Dictionary, world_pos: Vector3, use_hi := true) -> void:
	u = unit
	fac = str(u.get("fac", "hegemony"))
	if not HT.FAC3D.has(fac):
		fac = "hegemony"
	var cls := str(u.get("cls", "Frigate")) if u.get("cls") != null else "Frigate"
	L = HT.CLS_LEN.get(cls, 10.0) * HT.SHIP_K
	code = HT.code_for(fac, cls)
	var squad := cls == "Squadron" or bool(u.get("squadron", false))
	if squad:
		# a strike-craft wing: the game's craft hull for its kind (fighter, bomber, spore), drawn as a small formation
		code = HT.AI_HULLS.get("craft|" + str(u.get("tpl", "fighter")), "S1_51")
		L = HT.CLS_LEN["Squadron"] * HT.SHIP_K * 1.5
	if u.has("code"):
		code = str(u["code"])
		L = float(u.get("L", L))
	bob_seed = randf() * 10.0
	hull = Node3D.new()
	hull.name = "hull"
	add_child(hull)
	var man := manifest()
	var made := false
	# A4's kit ship when it is built (true chirality: no mirror; keeps skin_<n> patches and hp_* hard points for fx)
	if man.has("ships") and man["ships"].has(code):
		var ps0 = load(man["ships"][code]["res"])
		if ps0 is PackedScene:
			var inst0: Node3D = (ps0 as PackedScene).instantiate()
			hull.add_child(inst0)
			made = true
			a4 = true
	if not made and use_hi and man.has("hi") and man["hi"].has(code):
		var ps = load(man["hi"][code]["res"])
		if ps is PackedScene:
			var inst: Node3D = (ps as PackedScene).instantiate()
			hull.add_child(inst)
			made = true
	if not made and man.has("hulls") and man["hulls"].has(code):
		var mesh = load(man["hulls"][code]["res"])
		if mesh is Mesh:
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			hull.add_child(mi)
			made = true
	if not made:
		# no built hull (a copy of the project without gen/): a plain block, as an ArrayMesh like every real hull, since
		# G4's fx reads surface formats and arrays from the ship's meshes (primitive meshes have no surface_get_format)
		var bm := BoxMesh.new()
		bm.size = Vector3(1, 0.25, 0.35)
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bm.get_mesh_arrays())
		var mi := MeshInstance3D.new()
		mi.mesh = am
		hull.add_child(mi)
	_collect(hull)
	_look()
	_fit()
	if squad:
		for off in [Vector3(-L * 1.3, 0.3, L * 1.1), Vector3(-L * 1.3, -0.3, -L * 1.1), Vector3(-L * 2.5, 0.0, 0.0)]:
			var wing: Node3D = hull.duplicate()
			wing.position = hull.position + off
			add_child(wing)
			wings.append([wing, wing.position])
			_collect(wing)
	_engines()
	_ring()
	position = world_pos
	cur_yaw = yaw_of(u["facing"])
	rotation.y = cur_yaw


# G4's per-faction hull fix (render/look.gd: rim light and albedo lift for the dark hulls), one material copy per hull
static var _look_cache := {}


func _look() -> void:
	if not ResourceLoader.exists("res://render/look.gd"):
		return
	var LOOK = load("res://render/look.gd")
	for m in meshes:
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var src: Material = mi.get_active_material(i)
			if src == null:
				continue
			var k := "%d|%s" % [src.get_instance_id(), fac]
			if not _look_cache.has(k):
				_look_cache[k] = LOOK.hull(src, fac, true)
			mi.set_surface_override_material(i, _look_cache[k])


func _collect(n: Node) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			meshes.append(c)
		_collect(c)


# scale the hull so its length along x is the class length, centred, with the mirrored z (see board.gd)
func _fit() -> void:
	var box := AABB()
	var first := true
	for m in meshes:
		var mi := m as MeshInstance3D
		var xf := hull.global_transform.affine_inverse() * mi.global_transform if mi.is_inside_tree() else _rel(mi)
		var bb := xf * mi.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	var k := L / maxf(box.size.x, 1e-3)
	var yaw_fix := 0.0
	if HT.AI_HULL_YAW.has(code) and not a4:
		yaw_fix = -PI / 2.0 * float(HT.AI_HULL_YAW[code])
	var c := box.get_center()
	hull.transform = Transform3D(Basis(Vector3.UP, yaw_fix).scaled(Vector3(k, k, k if a4 else -k)), Vector3.ZERO)
	hull.position = -(hull.transform.basis * c)
	hull_base = hull.position
	hull_basis = hull.transform.basis
	# beam and height for where the RCS jets sit (the long axis is x)
	var side := box.size.z if is_zero_approx(yaw_fix) else box.size.x
	half_w = clampf(side * k * 0.5, L * 0.05, L * 0.3)
	half_h = clampf(box.size.y * k * 0.5, 0.3, L * 0.2)


func _rel(n: Node3D) -> Transform3D:
	var xf := n.transform
	var p := n.get_parent()
	while p != null and p != hull:
		if p is Node3D:
			xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf


func _engines() -> void:
	var col: Color = HT.FAC3D[fac]["eng"]
	var n := 2 if L < 20.0 else 3
	for i in n:
		var s := Sprite3D.new()
		s.texture = _glow_tex()
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.modulate = Color(col.r * 2.2, col.g * 2.2, col.b * 2.2, 1.0)
		s.pixel_size = L * 0.0009
		s.shaded = false
		s.transparent = true
		s.no_depth_test = false
		s.render_priority = 1
		var zoff := (float(i) - (n - 1) * 0.5) * L * 0.09
		s.position = Vector3(-L * 0.52, 0.0, zoff)
		add_child(s)
		engines.append(s)


static var _gt: Texture2D = null


static func _glow_tex() -> Texture2D:
	if _gt != null:
		return _gt
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5).length() / 31.5
			var a := clampf(exp(-d * d * 5.0) + exp(-d * d * 30.0), 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_gt = ImageTexture.create_from_image(img)
	return _gt


func _ring() -> void:
	ring = MeshInstance3D.new()
	ring.name = "fx_ring"  # fx_* names keep G4's mesh walk (fx_ship._find_meshes, A4 ships) off the footprint and marker
	var tm := TorusMesh.new()
	var rr := maxf(8.6, L * 0.56)
	tm.inner_radius = rr
	tm.outer_radius = rr + 0.6
	tm.rings = 64
	tm.ring_segments = 6
	ring.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.82, 0.65, 0.29)
	m.emission_enabled = true
	ring.material_override = m
	ring.position.y = -0.3
	ring.visible = false
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)


# the footprint under every ship (B1 markers): a green ring under yours, a broken violet hex under the enemy's
var marker: MeshInstance3D
var marker_friend := -1


func set_marker(friend: bool) -> void:
	if marker_friend == int(friend):
		return
	marker_friend = int(friend)
	if marker != null:
		marker.queue_free()
	marker = MeshInstance3D.new()
	marker.name = "fx_marker"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r0 := maxf(7.4, L * 0.5)
	var w := 0.5
	if friend:
		for i in 48:
			var a0 := TAU * i / 48.0
			var a1 := TAU * (i + 1) / 48.0
			var p0 := Vector3(cos(a0), 0, sin(a0))
			var p1 := Vector3(cos(a1), 0, sin(a1))
			for v in [p0 * r0, p1 * r0, p1 * (r0 - w), p0 * r0, p1 * (r0 - w), p0 * (r0 - w)]:
				st.add_vertex(v)
	else:
		# a hex outline with each side broken in the middle
		for i in 6:
			var a := Vector3(cos(deg_to_rad(60.0 * i + 30.0)), 0, sin(deg_to_rad(60.0 * i + 30.0)))
			var b := Vector3(cos(deg_to_rad(60.0 * (i + 1) + 30.0)), 0, sin(deg_to_rad(60.0 * (i + 1) + 30.0)))
			for seg in [[0.0, 0.38], [0.62, 1.0]]:
				var p0: Vector3 = a.lerp(b, seg[0])
				var p1: Vector3 = a.lerp(b, seg[1])
				for v in [p0 * (r0 + 0.6), p1 * (r0 + 0.6), p1 * (r0 + 0.6 - w), p0 * (r0 + 0.6), p1 * (r0 + 0.6 - w), p0 * (r0 + 0.6 - w)]:
					st.add_vertex(v)
	marker.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(0.42, 1.0, 0.55, 0.85) if friend else Color(0.62, 0.22, 1.0, 0.9)
	marker.material_override = m
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.position.y = -0.25
	add_child(marker)


var wreck := false


# death: sink and fade, or stay on the board as a dark, listing wreck (blocking terrain)
func die(as_wreck: bool) -> void:
	dead = true
	wreck = as_wreck
	if marker != null:
		marker.visible = false
	ring.visible = false
	for e in engines:
		(e as Sprite3D).visible = false
	if as_wreck:
		sink = 1.0
		hull.rotation.z = 0.22
		hull.rotation.x = 0.08
		for m in meshes:
			var gi := m as GeometryInstance3D
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.07, 0.065, 0.06)
			mat.roughness = 0.9
			mat.metallic = 0.3
			gi.material_override = mat


# a Deathless wreck standing up again: back to its own materials, lights and markers
func revive() -> void:
	dead = false
	wreck = false
	sink = 0.0
	visible = true
	hull.rotation = Vector3.ZERO
	position.y = 0.0
	for m in meshes:
		var gi := m as GeometryInstance3D
		gi.material_override = null
		gi.transparency = 0.0
		gi.visible = true
	for e in engines:
		(e as Sprite3D).visible = true
	if marker != null:
		marker.visible = true


var fleeing := 0.0


func flee() -> void:
	dead = true
	fleeing = 0.001
	if marker != null:
		marker.visible = false
	ring.visible = false


func set_selected(on: bool, col := Color(0.82, 0.65, 0.29)) -> void:
	ring.visible = on
	(ring.material_override as StandardMaterial3D).albedo_color = col
	ring.rotation.y = -rotation.y


# One continuous burn along a path (fx3d.js animPath): position keys on a Hermite curve over the path length, facing keys
# eased between, altitude keys for climbing over rocks or diving under ships; the whole path takes dur seconds.
# keys: [{s, pos: Vector3}] and yaws: [{s, yaw}] and alts: [{s, y}], S the path length.
var path_keys: Array = []
var path_yaws: Array = []
var path_alts: Array = []
var path_S := 1.0
var path_dur := 0.0
var path_t := 0.0
var _tans: Array = []


# Movement: brisk (and strike craft): the earlier motion, eased along the whole path with the facing eased between keys
func play_path(keys: Array, yaws: Array, alts: Array, S: float, dur: float, opts := {}) -> void:
	mass = clampf(float(opts.get("mass", 0.5)), 0.0, 1.0)
	cinematic = false
	segs = []
	_prev_pos = position
	path_keys = keys
	path_yaws = yaws
	path_alts = alts
	path_S = maxf(S, 0.001)
	path_dur = maxf(dur, 0.05)
	path_t = 0.0
	_tans = []
	for i in keys.size():
		var a: Dictionary = keys[maxi(0, i - 1)]
		var b: Dictionary = keys[mini(keys.size() - 1, i + 1)]
		var ds := maxf(0.001, float(b.s) - float(a.s))
		var tn: Vector3 = (b.pos - a.pos) / ds
		if i == 0 or i == keys.size() - 1:
			tn = Vector3.ZERO
		_tans.append(tn)


func _pos_at(x: float) -> Vector3:
	var i := 0
	while i < path_keys.size() - 2 and x > float(path_keys[i + 1].s):
		i += 1
	var A: Dictionary = path_keys[i]
	var Bk: Dictionary = path_keys[mini(i + 1, path_keys.size() - 1)]
	var ds := maxf(0.001, float(Bk.s) - float(A.s))
	var t := clampf((x - float(A.s)) / ds, 0.0, 1.0)
	if (Bk.pos - A.pos).length() < 1e-4:
		return A.pos
	var t2 := t * t
	var t3 := t2 * t
	return (2 * t3 - 3 * t2 + 1) * A.pos + (t3 - 2 * t2 + t) * ds * _tans[i] + (-2 * t3 + 3 * t2) * Bk.pos + (t3 - t2) * ds * _tans[mini(i + 1, _tans.size() - 1)]


static func _key_at(arr: Array, x: float, field: String) -> float:
	if arr.is_empty():
		return 0.0
	var i := 0
	while i < arr.size() - 2 and x > float(arr[i + 1].s):
		i += 1
	var A: Dictionary = arr[i]
	var Bk: Dictionary = arr[mini(i + 1, arr.size() - 1)]
	if Bk == A:
		return float(A[field])
	var t := clampf((x - float(A.s)) / maxf(0.001, float(Bk.s) - float(A.s)), 0.0, 1.0)
	var e := t * t * (3.0 - 2.0 * t)
	return float(A[field]) + (float(Bk[field]) - float(A[field])) * e


# burning: the move itself. The battle waits on this.
func burning() -> bool:
	return path_dur > 0.0


# busy: G2 is steering this node (a move under way) and writes its position and yaw itself. G4's hit reactions read
# this (fx_ship._react_step) and add their yaw kick and drift only while it is false.
func busy() -> bool:
	return path_dur > 0.0


# ---------------------------------------------------------------- spaceship motion (R50 round 2, "Movement: cinematic")
# Ryan, Oct 27: "The movement should be how they actually move. Thrusters for sideways, turning that makes sense."
# The rules move a ship in steps that never change its heading (ahead, sidestep, back off) and turn it in place, so a
# move plays as segments, each from rest to rest:
#   - a turn: the hull rotates about its centre on an RCS couple (bow jets one way, stern jets the other) that starts the
#     spin and a counter-couple that stops it; a heavier hull spends more of its time building and bleeding the spin;
#   - a run: the hull slides along a smooth curve through the hexes with its heading fixed.
# Every thruster follows the hull's real acceleration in its own frame: the main drive lights only while it pushes the
# ship ahead on a forward run; braking and backing off use the forward-facing retro jets at the bow; stopping a back-off
# uses small aft jets, never the main drive; sideways pushes use lateral jets in matched bow and stern pairs. No banking.
var mass := 0.5
var cinematic := true
var thrust := 0.0             # main drive 0..1, only while it is actually pushing; the battle feeds G4's engine level
var segs: Array = []
var seg_i := 0
var seg_t := 0.0
var fx_engines := false       # G4 draws the engines at the real nozzles: the old guessed glows stay hidden
var half_w := 1.0             # half the hull's beam and height (from the fitted box), for where the jets sit
var half_h := 0.6
var _prev_pos := Vector3.ZERO
var _vel := Vector3.ZERO
var _acc := Vector3.ZERO
var _prev_yaw := 0.0
var _yaw_v := 0.0
var _yaw_a := 0.0
var _puff_cd := {}
var wings: Array = []         # strike craft beside the lead hull: [node, rest offset]
var puffs: Array = []


# segments: [{"kind": "turn", "a0", "a1", "w"} | {"kind": "run", "pts": [Vector3 incl. height], "yaw", "w"}]; dur is the
# whole move's time (the B2 pace), shared out by weight
func play_moves(segments: Array, dur: float, opts := {}) -> void:
	mass = clampf(float(opts.get("mass", 0.5)), 0.0, 1.0)
	cinematic = true
	var tot := 0.0
	for sg in segments:
		tot += float(sg["w"])
	segs = []
	for sg in segments:
		var g: Dictionary = sg.duplicate()
		g["T"] = maxf(dur * float(g["w"]) / maxf(tot, 1e-4), 0.02)
		if g["kind"] == "run":
			_prep_run(g)
			var pts: Array = g["pts"]
			var net: Vector3 = (pts[-1] as Vector3) - (pts[0] as Vector3)
			net.y = 0.0
			g["dir_l"] = (Basis(Vector3.UP, float(g["yaw"])).inverse() * net).normalized() if net.length() > 0.01 else Vector3(1, 0, 0)
			# the settle: a slight overshoot, about 4% of the hull's length (never more than 2.5% of the run)
			g["settle"] = 0.0 if bool(g.get("flip", false)) else minf(0.025, (0.04 * L + 0.4) / float(g["len"]))
		else:
			g["settle"] = 0.03
		segs.append(g)
	seg_i = 0
	seg_t = 0.0
	path_dur = maxf(dur, 0.05)
	path_yaws = []
	_prev_pos = position
	_vel = Vector3.ZERO
	_acc = Vector3.ZERO
	_prev_yaw = cur_yaw
	_yaw_v = 0.0
	_yaw_a = 0.0


# a run's curve: Catmull-Rom through its hexes, sampled by arc length
func _prep_run(g: Dictionary) -> void:
	var pts: Array = g["pts"]
	var smp: Array = [pts[0]]
	var cum: Array = [0.0]
	for i in pts.size() - 1:
		var p0: Vector3 = pts[maxi(i - 1, 0)]
		var p1: Vector3 = pts[i]
		var p2: Vector3 = pts[i + 1]
		var p3: Vector3 = pts[mini(i + 2, pts.size() - 1)]
		for k in range(1, 17):
			var t := k / 16.0
			var t2 := t * t
			var t3 := t2 * t
			var q: Vector3 = 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)
			cum.append(float(cum[-1]) + q.distance_to(smp[-1]))
			smp.append(q)
	g["smp"] = smp
	g["cum"] = cum
	g["len"] = maxf(float(cum[-1]), 1e-4)


static func _curve_at(g: Dictionary, d: float) -> Vector3:
	var cum: Array = g["cum"]
	var smp: Array = g["smp"]
	if d <= 0.0:
		return smp[0]
	var lo := 0
	var hi := cum.size() - 1
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if float(cum[mid]) < d:
			lo = mid
		else:
			hi = mid
	var span := maxf(float(cum[hi]) - float(cum[lo]), 1e-5)
	return (smp[lo] as Vector3).lerp(smp[hi], clampf((d - float(cum[lo])) / span, 0.0, 1.0))


# Easing (Ryan, R55: "the stop is kind of sudden"): every segment thrusts up, coasts, then brakes for as long as it
# thrust up, eased both ways (sine ramps: speed and spin build and bleed smoothly, nothing snaps to rest), and ends in a
# small settle, a slight overshoot that the jets correct. A heavier hull has less thrust for its mass, so its ramps
# take more of the segment.
const SETTLE_T := 0.14        # the settle's share of a segment


func _ta() -> float:
	return lerpf(0.34, 0.44, mass)


func _ramp(p: float) -> float:
	var ta := _ta()
	var vmax := 1.0 / (1.0 - ta)
	if p < ta:
		return vmax * (p * 0.5 - ta / (2.0 * PI) * sin(PI * p / ta))
	if p > 1.0 - ta:
		var q := 1.0 - p
		return 1.0 - vmax * (q * 0.5 - ta / (2.0 * PI) * sin(PI * q / ta))
	return vmax * (ta * 0.5 + (p - ta))


# the fraction covered at time fraction p, the settle included (it can pass 1 for a moment: the overshoot)
func _ease(g: Dictionary, p: float) -> float:
	var d := float(g.get("settle", 0.0))
	if d <= 0.0:
		return _ramp(p)
	var pm := 1.0 - SETTLE_T
	if p < pm:
		return (1.0 + d) * _ramp(p / pm)
	var q := (p - pm) / SETTLE_T
	return 1.0 + d * (1.0 - q * q * (3.0 - 2.0 * q))


# which burn a segment is in at time fraction p: ["up" | "coast" | "down" | "settle", how far through it]
func _phase(g: Dictionary, p: float) -> Array:
	var pm := 1.0 - SETTLE_T if float(g.get("settle", 0.0)) > 0.0 else 1.0
	if p >= pm:
		return ["settle", (p - pm) / maxf(1.0 - pm, 1e-4)]
	var r := p / pm
	var ta := _ta()
	if r < ta:
		return ["up", r / ta]
	if r > 1.0 - ta:
		return ["down", (r - (1.0 - ta)) / ta]
	return ["coast", 0.0]


func _seg_step(dt: float) -> void:
	var dts := dt / maxf(speed_k, 0.05)   # Enter or Space hurries a move already under way
	seg_t += dts
	while seg_i < segs.size() and seg_t >= float(segs[seg_i]["T"]):
		seg_t -= float(segs[seg_i]["T"])
		_seg_pose(segs[seg_i], 1.0)
		seg_i += 1
	if seg_i >= segs.size():
		path_dur = 0.0
		segs = []
		thrust = 0.0
		_vel = Vector3.ZERO
		_acc = Vector3.ZERO
		_yaw_v = 0.0
		_yaw_a = 0.0
		return
	var g: Dictionary = segs[seg_i]
	_seg_pose(g, seg_t / float(g["T"]))
	# the hull's real motion, in animation time (the wings' lag reads it)
	var v := (position - _prev_pos) / maxf(dts, 1e-4)
	_acc = _acc.lerp((v - _vel) / maxf(dts, 1e-4), 0.5)
	_vel = v
	_prev_pos = position
	var yv := angle_difference(_prev_yaw, cur_yaw) / maxf(dts, 1e-4)
	_yaw_a = lerpf(_yaw_a, (yv - _yaw_v) / maxf(dts, 1e-4), 0.5)
	_yaw_v = yv
	_prev_yaw = cur_yaw
	_thrusters(g, seg_t / float(g["T"]), dts)


func _seg_pose(g: Dictionary, p: float) -> void:
	if g["kind"] == "turn":
		var f := _ease(g, p) if p < 1.0 else 1.0
		cur_yaw = float(g["a0"]) + angle_difference(float(g["a0"]), float(g["a1"])) * f
		rotation.y = cur_yaw
	elif bool(g.get("flip", false)):
		_flip_pose(g, p)
	else:
		var f := _ease(g, p) if p < 1.0 else 1.0
		position = _curve_at(g, float(g["len"]) * f)
		cur_yaw = float(g["yaw"])
		rotation.y = cur_yaw


# Flip and burn (R55 test, --flip-burn: straight runs of 3+ hexes on cruisers and bigger): burn out, flip end for end on
# the turning jets while coasting, burn the main drive to brake, then flip back to the end heading at rest.
const FLIP := [0.26, 0.22, 0.26]   # shares of the run: burn out, flip, brake burn (the rest is the flip back)


static func _spin_ease(x: float) -> float:
	return 0.5 - 0.5 * cos(PI * clampf(x, 0.0, 1.0))


func _flip_pose(g: Dictionary, p: float) -> void:
	var a: float = FLIP[0]
	var f: float = FLIP[1]
	var b: float = FLIP[2]
	var v := 1.0 / (a * 0.5 + f + b * 0.5)
	var s := 1.0
	if p < a:
		s = v * (p * 0.5 - a / (2.0 * PI) * sin(PI * p / a))
	elif p < a + f:
		s = v * (a * 0.5 + (p - a))
	elif p < a + f + b:
		var q := a + f + b - p
		s = 1.0 - v * (q * 0.5 - b / (2.0 * PI) * sin(PI * q / b))
	position = _curve_at(g, float(g["len"]) * clampf(s, 0.0, 1.0))
	var base := float(g["yaw"])
	var yaw := base
	if p >= 1.0:
		yaw = base
	elif p >= a + f + b:
		yaw = base + PI + PI * _spin_ease((p - a - f - b) / (1.0 - a - f - b))
	elif p >= a + f:
		yaw = base + PI
	elif p >= a:
		yaw = base + PI * _spin_ease((p - a) / f)
	cur_yaw = yaw
	rotation.y = cur_yaw


# The thrusters follow the burn the segment is in, so the jets fire through the whole of each burn: the push is along
# the direction of travel while speed builds and against it while it bleeds (and back and forth in the settle). In the
# ship's frame: a push ahead is the main drive on a forward run's thrust-up, aft jets otherwise (stopping a back-off,
# the settle); a push astern is the bow's retro jets; a push to the side is a matched pair of side jets. A turn's spin
# builds and bleeds on the bow and stern jets (the couple).
func _thrusters(g: Dictionary, p: float, dts: float) -> void:
	for k in _puff_cd.keys():
		_puff_cd[k] = float(_puff_cd[k]) - dts
	thrust = 0.0
	var ph: Array = _phase(g, p)
	var kph := String(ph[0])
	var x := float(ph[1])
	var k := clampf(sin(PI * x), 0.35, 1.0)
	if g["kind"] == "turn":
		var rot := signf(angle_difference(float(g["a0"]), float(g["a1"])))
		match kph:
			"up": _emit("couple", _couple_puffs.bind(rot, k))
			"down": _emit("couple", _couple_puffs.bind(-rot, k))
			"settle": _emit("couple", _couple_puffs.bind(-rot if x < 0.5 else rot, 0.4))
		return
	if bool(g.get("flip", false)):
		_flip_thrusters(p)
		return
	var dl: Vector3 = g.get("dir_l", Vector3(1, 0, 0))   # the direction of travel in the ship's frame
	var push := Vector3.ZERO
	var kk := k
	match kph:
		"up": push = dl
		"down": push = -dl
		"settle":
			push = -dl if x < 0.5 else dl
			kk = 0.45
	if push == Vector3.ZERO:
		return
	if push.x > 0.3:
		if kph == "up" and dl.x > 0.3:
			thrust = clampf(sin(PI * x) * 1.1, 0.0, 1.0)              # the main drive pushes the ship ahead
		else:
			_emit("aft", _aft_puffs.bind(kk))                         # stopping a back-off, the settle: aft jets
	elif push.x < -0.3:
		_emit("retro", _retro_puffs.bind(kk))                         # braking or backing off: the bow's retro jets
	if absf(push.z) > 0.3:
		_emit("side", _side_puffs.bind(signf(push.z), kk))


func _flip_thrusters(p: float) -> void:
	var a: float = FLIP[0]
	var f: float = FLIP[1]
	var b: float = FLIP[2]
	if p < a:
		thrust = clampf(sin(PI * p / a) * 1.1, 0.0, 1.0)            # burn out
	elif p < a + f:
		var q := (p - a) / f
		_emit("couple", _couple_puffs.bind(1.0 if q < 0.5 else -1.0, clampf(sin(PI * fmod(q * 2.0, 1.0)), 0.4, 1.0)))
	elif p < a + f + b:
		thrust = clampf(sin(PI * (p - a - f) / b) * 1.1, 0.0, 1.0)  # the main drive brakes, the ship end for end
	else:
		var q := (p - a - f - b) / (1.0 - a - f - b)
		_emit("couple", _couple_puffs.bind(1.0 if q < 0.5 else -1.0, clampf(sin(PI * fmod(q * 2.0, 1.0)), 0.4, 1.0)))


func _emit(kind: String, f: Callable) -> void:
	if float(_puff_cd.get(kind, 0.0)) > 0.0:
		return
	_puff_cd[kind] = 0.06
	f.call()


func snap_to(p: Vector3, yaw: float) -> void:
	path_dur = 0.0
	segs = []
	path_yaws = []
	_yaw_v = 0.0
	position = p
	_prev_pos = p
	cur_yaw = yaw
	rotation.y = yaw


# ---------------------------------------------------------------- RCS jets: short cold-gas bursts at the hull's corners
# (puffs are left in space where they were fired; they do not ride along with the hull)
func _couple_puffs(sgn: float, k: float) -> void:
	# a positive yaw acceleration needs the bow pushed to -z and the stern to +z: the bow's +z jet and the stern's -z jet
	var bx := L * 0.4
	_puff(Vector3(bx, 0.2, half_w * sgn), Vector3(0, 0, sgn), k)
	_puff(Vector3(-bx, 0.2, -half_w * sgn), Vector3(0, 0, -sgn), k)


func _retro_puffs(k: float) -> void:
	var bx := L * 0.5
	_puff(Vector3(bx, 0.2, half_w * 0.45), Vector3(1, 0, 0.25), k)
	_puff(Vector3(bx, 0.2, -half_w * 0.45), Vector3(1, 0, -0.25), k)


func _aft_puffs(k: float) -> void:
	var bx := -L * 0.48
	_puff(Vector3(bx, half_h * 0.6, half_w * 0.7), Vector3(-1, 0, 0.2), k * 0.8)
	_puff(Vector3(bx, half_h * 0.6, -half_w * 0.7), Vector3(-1, 0, -0.2), k * 0.8)


func _side_puffs(sgn: float, k: float) -> void:
	# pushing the hull to +z vents gas to -z from the jets on that side, a matched pair at bow and stern (no spin)
	for bx in [L * 0.36, -L * 0.36]:
		_puff(Vector3(bx, 0.2, -half_w * sgn), Vector3(0, 0, -sgn), k)


func _puff(at: Vector3, dir: Vector3, k := 1.0) -> void:
	if dead or not visible or DisplayServer.get_name() == "headless":
		return
	var sp := Sprite3D.new()
	sp.texture = _glow_tex()
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.shaded = false
	sp.transparent = true
	sp.material_override = _puff_mat()
	sp.modulate = Color(0.85, 0.88, 0.95, 0.75 * k)  # G4's hit-reaction RCS colour (fx_ship._rcs)
	# a jet reads at battle zoom: about 5% of the hull's length as it leaves the nozzle, three times that as it spreads
	sp.pixel_size = clampf(L * 0.07, 1.4, 2.8) / 64.0 * (0.6 + 0.4 * k)
	sp.top_level = true
	add_child(sp)
	sp.global_position = to_global(at + dir.normalized() * maxf(L, 6.0) * 0.03)  # just outside the hull, not inside it
	var vw: Vector3 = global_transform.basis.orthonormalized() * dir.normalized()
	puffs.append({"n": sp, "t": 0.0, "v": vw * maxf(L, 6.0) * 0.8 * (0.6 + 0.4 * k) + _vel * 0.6, "s": sp.pixel_size, "a": 0.75 * k})


static var _pm: StandardMaterial3D = null


# jets glow like hot gas: additive, unshaded, camera-facing, tinted by the sprite's modulate
static func _puff_mat() -> StandardMaterial3D:
	if _pm != null:
		return _pm
	_pm = StandardMaterial3D.new()
	_pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_pm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_pm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_pm.vertex_color_use_as_albedo = true
	_pm.albedo_texture = _glow_tex()
	_pm.no_depth_test = false
	_pm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return _pm


func _puffs_step(dt: float) -> void:
	for i in range(puffs.size() - 1, -1, -1):
		var pf: Dictionary = puffs[i]
		pf.t += dt
		var sp: Sprite3D = pf.n
		var life := 0.4
		sp.global_position += (pf.v as Vector3) * dt * (1.0 - pf.t / life)
		sp.pixel_size = float(pf.s) * (1.0 + pf.t * 5.0)
		sp.modulate.a = maxf(0.0, float(pf.a) * (1.0 - pf.t / life))
		if pf.t >= life:
			sp.queue_free()
			puffs.remove_at(i)


func _process(dt: float) -> void:
	if not puffs.is_empty():
		_puffs_step(dt)
	if path_dur > 0.0 and not segs.is_empty() and not dead:
		_seg_step(dt)
	elif path_dur > 0.0:
		# Movement: brisk (the earlier motion): ease in and out over the whole burn, facing eased between keys
		path_t = minf(path_t + dt / (path_dur * speed_k), 1.0)
		var p := path_t
		var e := p * p * (3.0 - 2.0 * p) * 0.6 + p * 0.4
		var x := path_S * e
		var pos := _pos_at(x)
		pos.y = _key_at(path_alts, x, "y")
		position = pos
		cur_yaw = _key_at(path_yaws, x, "yaw")
		rotation.y = cur_yaw
		thrust = 1.0 if p < 0.3 else 0.3
		if path_t >= 1.0:
			path_dur = 0.0
			thrust = 0.0
	if fleeing > 0.0:
		fleeing += dt
		position += Vector3(cos(-rotation.y), 0, sin(-rotation.y)) * dt * 60.0 * fleeing
		if fleeing > 1.5:
			visible = false
		return
	if dead and not wreck and sink < 1.0:
		sink = minf(sink + dt * 0.35, 1.0)
		hull.rotation.z = sink * 0.5
		position.y = -sink * 6.0
		for m in meshes:
			(m as GeometryInstance3D).transparency = sink
		for e in engines:
			(e as Sprite3D).visible = false
		if sink >= 1.0:
			visible = false
	# a slow idle drift, so the fleet does not look parked (no banking: a spaceship does not lean into a turn)
	var bob := Vector3(0, sin(Time.get_ticks_msec() / 1000.0 * 0.6 + bob_seed) * 0.25, 0)
	hull.position = hull_base + bob
	# the fallback engine glows (only when G4's fx is not drawing the real nozzles) swell only while the drive pushes
	var eg := 0.45 + 1.1 * thrust
	for e in engines:
		(e as Sprite3D).visible = not fx_engines and not dead
		(e as Sprite3D).pixel_size = L * 0.0009 * eg
	# strike craft trail the lead a beat behind while it moves, closing up when it stops
	var spd := clampf(_vel.length() / maxf(L * 1.5, 1.0), 0.0, 1.0)
	for wi in wings.size():
		var wv: Array = wings[wi]
		var back: Vector3 = (wv[1] as Vector3) - Vector3(1, 0, 0) * spd * L * 0.9 * (1.0 + float(wi) * 0.5)
		(wv[0] as Node3D).position = (wv[0] as Node3D).position.lerp(back, clampf(dt * 4.0, 0.0, 1.0))
	if ring.visible:
		ring.rotation.y = -rotation.y
