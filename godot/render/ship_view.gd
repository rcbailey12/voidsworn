extends Node3D
# One ship on the board: its hull (the game's mesh for its faction and class, or the 8K version for a flagship), scaled to
# the class length, turned to its facing, with engine glows, a selection ring, and the animation of its moves.

const HT := preload("res://render/hull_table.gd")
const ATTACH := preload("res://fx/fx_hull.gd")
const CRAFT := preload("res://render/squadron_craft.gd")
const WING := preload("res://render/squadron_wing.gd")
const PG := preload("res://render/placeholder_guard.gd")
var squad_kind := ""

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


func _exit_tree() -> void:
	# The dummy renderer can query instance shader parameters during hull teardown,
	# after a damaged mesh's surface materials have been freed. Detach the render
	# instances first, while their nodes and materials are still alive.
	if DisplayServer.get_name() != "headless" and RenderingServer.get_current_rendering_method() != "dummy":
		return
	for mi in meshes:
		if is_instance_valid(mi):
			(mi as MeshInstance3D).set_base(RID())


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
		squad_kind = CRAFT.kind_for(u)
		code = fac + "|" + squad_kind
		L = HT.CLS_LEN["Squadron"] * HT.SHIP_K * 1.5
		bob_seed = float(posmod(hash(str(u.get("id", "wing"))), 10000)) / 1000.0
		hull = WING.new()
		hull.name = "hull"
		add_child(hull)
		hull.setup(fac, squad_kind, L, 6 if fac == "chorus" else 4, bob_seed)
		_collect(hull)
		_ring()
		position = world_pos
		cur_yaw = yaw_of(u.get("facing", 0))
		rotation.y = cur_yaw
		return
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
		var pc := code if code != "" else "%s|%s" % [fac, cls]
		push_error("placeholder hull: %s" % pc)
		PG.note(pc)
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
		if String(c.name).begins_with("fx_"):
			continue
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
	m.albedo_color = Color(0.78, 0.96, 0.23)
	m.emission_enabled = true
	ring.material_override = m
	ring.position.y = -0.3
	ring.visible = false
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)


# the footprint under every ship (B1 markers): a mint ring under yours, a broken violet hex under the enemy's
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
	# your ring is the HUD's FRIEND mint (glass_shell.gd, R149: moved off green so it never reads as the lime accent)
	m.albedo_color = Color(0.32, 0.94, 0.77, 0.85) if friend else Color(0.62, 0.22, 1.0, 0.9)
	marker.material_override = m
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.position.y = -0.25
	add_child(marker)


var wreck := false


# Death effects own the hull replacement. Keep its root on the board throughout.
func die(as_wreck: bool) -> void:
	dead = true
	wreck = as_wreck
	path_dur = 0.0
	glide = false
	thrust = 0.0
	if marker != null:
		marker.visible = false
	ring.visible = false
	for e in engines:
		(e as Sprite3D).visible = false
	if as_wreck:
		hull.rotation.z = 0.22
		hull.rotation.x = 0.08
		for m in meshes:
			var gi := m as GeometryInstance3D
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.07, 0.065, 0.06)
			mat.roughness = 0.9
			mat.metallic = 0.3
			gi.material_override = mat
	else:
		# Without FX, the battle's fallback flash replaces the hull immediately.
		visible = false


# a Deathless wreck standing up again: back to its own materials, lights and markers
func revive() -> void:
	dead = false
	wreck = false
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


func set_selected(on: bool, col := Color(0.78, 0.96, 0.23)) -> void:   # lime: the ship that is up (R149)
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
	glide = false
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
# (That is the old segments mode, now a debug flag; the default flown move is play_glide below, issue 505.)
var mass := 0.5
var cinematic := true
var thrust := 0.0             # main drive 0..1, only while it is actually pushing; the battle feeds G4's engine level
var segs: Array = []
var seg_i := 0
var seg_t := 0.0
var fx_engines := false       # G4 draws the engines at the real nozzles: the old guessed glows stay hidden
var half_w := 1.0             # half the hull's beam and height (from the fitted box), to aim the jets (issue 370)
var half_h := 0.6
var attach = null             # issue 370: the attach point service for this hull (fx/fx_hull.gd), set by fx_ship.setup
var _prev_pos := Vector3.ZERO
var _vel := Vector3.ZERO
var _acc := Vector3.ZERO
var _prev_yaw := 0.0
var _yaw_v := 0.0
var _yaw_a := 0.0
var _puff_cd := {}
var puffs: Array = []


# segments: [{"kind": "turn", "a0", "a1", "w"} | {"kind": "run", "pts": [Vector3 incl. height], "yaw", "w"}]; dur is the
# whole move's time (the B2 pace), shared out by weight
func play_moves(segments: Array, dur: float, opts := {}) -> void:
	mass = clampf(float(opts.get("mass", 0.5)), 0.0, 1.0)
	cinematic = true
	glide = false
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
		for k in range(1, 17):
			var t := k / 16.0
			var q := _run_point(g, i, t)
			cum.append(float(cum[-1]) + q.distance_to(smp[-1]))
			smp.append(q)
	g["smp"] = smp
	g["cum"] = cum
	g["len"] = maxf(float(cum[-1]), 1e-4)


static func _run_point(g: Dictionary, i: int, t: float) -> Vector3:
	var pts: Array = g["pts"]
	var p0: Vector3 = pts[maxi(i - 1, 0)]
	var p1: Vector3 = pts[i]
	var p2: Vector3 = pts[i + 1]
	var p3: Vector3 = pts[mini(i + 2, pts.size() - 1)]
	if i == 0:
		p0 -= g.get("drift", Vector3.ZERO) * 2.0
	if i == pts.size() - 2:
		p3 -= g.get("drift", Vector3.ZERO) * 2.0
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)


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
	var f := clampf((d - float(cum[lo])) / span, 0.0, 1.0)
	if g.get("smooth", false):
		return _run_point(g, lo / 16, (lo % 16 + f) / 16.0)
	return (smp[lo] as Vector3).lerp(smp[hi], f)


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


# ---------------------------------------------------------------- flown movement (issue 505; R76 read by its purpose, R189)
# Ryan, Nov 11: "I don't want things to look jerky ... Thrusters should be involved when it makes sense on braking and
# turns. Same with shuffle, it should make sense in space with how they would fly." So a move is flown, never steered:
#   - the hull slides along one smooth curve through the rules' hexes (same route, same end hex), its speed built and
#     bled on eased ramps; a bigger hull takes longer (mass runs past 1 for dreadnoughts, titans and arks);
#   - the heading is flown on its own, separately from the path: every rules turn is a spin at the ship's own rate,
#     started by one pair of turning jets and stopped by the opposite pair. A turn before the run is flown first and the
#     hull sets off as the nose comes round (point, then burn); a turn at a corner is centred on the hull's passage there
#     (a big one brings the hull to rest while it swings); the final facing starts while the hull brakes and finishes
#     after. Sidesteps and back-offs keep the heading: the hull slides on side or retro jets. No roll into turns;
#   - every light has a cause (_glide_thrusters): the main drive from forward acceleration (a hard burn to gain speed, a
#     low hot glow while coasting), retro jets at the bow while it slows, side jets while it is pushed sideways, aft jets
#     to stop a back-off. Every jet level ramps; nothing switches on or off in one frame.
# steps: [{"kind": "turn", "yaw": target (unwrapped), "w"} | {"kind": "move", "p": Vector3 (height included), "w"}], w in
# hexes of the move's time (one hex at cruise is one unit); unit_s the seconds a unit takes (the battle's pace), opts.cap
# the longest a move may take. path_dur is the move's length once set up. Every number below is a tuning value chosen by
# eye from the issue 505 strips, not a limit.
var glide := false
var glide_bank := 0.0        # roll about the bow, shared with the hit-reaction layer (always 0 now: no roll into turns)
var gl_final_yaw := 0.0
var gl_motion_time := 0.0
var gl_ds: PackedFloat32Array = PackedFloat32Array()   # distance along the curve on an even time grid (motion time)
var gl_dtg := 1.0 / 60.0      # that grid's step, in units
var gl_tm0 := 0.0             # when the motion starts on the move's timeline (units)
var gl_turns: Array = []      # [{"t0", "t1", "d"}]: a spin of d radians over timeline units t0..t1
var gl_T := 1.0               # the move's timeline length (units); p in 0..1 runs it in dur seconds
var gl_yaw0 := 0.0
var gl_ta := 0.3
var gl_p := 0.0
var gl_vpk := 0.0             # this move's peak speed, forward acceleration and spin acceleration (per p), for the jets
var gl_apk := 0.0
var gl_yapk := 0.0
var gl_hexd := 1.0
var _gl_run := {}
# what the drive and the jets are doing now (0..1; side and turn signed), for captures and the speed trace
var jet_retro := 0.0
var jet_side := 0.0
var jet_aft := 0.0
var jet_turn := 0.0
var jet_count := 0            # puffs fired by this ship (frame cost evidence)
const MASS_MAX := 1.4         # the size scale runs past 1 for the biggest hulls (issue 505 item 5; battle.gd MOVE_SK_MAX)
const GL_TR := [0.7, 1.7]     # units to build cruise speed from rest, escort and battleship (extended past 1 by mass)
const GL_SPIN := 2.4          # a turn step's weight to units of the move's timeline (the motion's own ramps add as much)
const GL_POINT := 0.5         # a turn before the run: the hull sets off when the nose is within this many radians (29 deg)
const GL_TRAIL := 0.45        # a turn after the run starts this share of its own length before the hull arrives
# (battle.gd passes its own "point" and "trail" for a move flown nose first, issue 521: NF_POINT, NF_TRAIL)
const GL_DWELL := 0.4         # a big turn at a corner (two steps or more): the hull rests this share of the spin there
const GL_COAST := 0.15        # the drive while coasting under way (battle level about 0.6 of 2): hot, never dark
const JET_ON := 0.18          # a jet fires above this level; its puffs carry the level, so they fade in and out
const PUFF_MIN := 2.4         # issue 521: the smallest jet in a flown move, in world units (a frigate's jets read at r 170)
const JET_K := 10.0           # how fast a jet level follows its push (1/s): short ramps, never one-frame switches


func play_glide(steps: Array, unit_s: float, opts := {}) -> void:
	mass = clampf(float(opts.get("mass", 0.5)), 0.0, MASS_MAX)
	cinematic = true
	glide = true
	segs = []
	path_yaws = []
	var p0 := Vector3(position.x, 0.0, position.z)
	# 1. the curve's points; the spins (consecutive turn steps) with the point they turn at
	var pts: Array = [p0]
	var groups: Array = []    # {"k": point index, "w": weight, "d": radians}
	var la := cur_yaw
	var last_turn := false
	for st in steps:
		if st["kind"] == "turn":
			var a1 := float(st["yaw"])
			if not last_turn:
				groups.append({"k": pts.size() - 1, "w": 0.0, "d": 0.0, "n": 0.0, "ws": 0.0})
			groups[-1]["ws"] = float(groups[-1]["ws"]) + float(st["w"])
			groups[-1]["n"] = float(groups[-1]["n"]) + maxf(absf(angle_difference(la, a1)) / (PI / 3.0), 0.5)
			groups[-1]["d"] = float(groups[-1]["d"]) + angle_difference(la, a1)
			# the spin lasts as long as its net angle needs at this ship's rate (the rules' route can turn one way and
			# back inside one group: +60, -60, +60 is flown as one 60 degree spin, not a slow 180 degree crawl)
			groups[-1]["w"] = float(groups[-1]["ws"]) / float(groups[-1]["n"]) * (0.0 if absf(float(groups[-1]["d"])) < 0.01 else maxf(absf(float(groups[-1]["d"])) / (PI / 3.0), 0.5))
			la = a1
			last_turn = true
		else:
			pts.append(st["p"])
			last_turn = false
	if pts.size() > 1 and absf((pts[-1] as Vector3).y) > 0.01:   # a move that ends over an obstacle comes back down
		var lp: Vector3 = pts[-1]
		pts.append(Vector3(lp.x, 0.0, lp.z))
	var n_pts := pts.size()
	# 2. the curve and its speed limits: cruise everywhere, slower at a corner (by how far the course or the heading
	#    swings there), zero at the ends, where the course reverses and where a big turn is flown at a corner
	var run := {"pts": pts}
	_prep_run(run)
	_gl_run = run
	var cum: Array = run["cum"]
	var hexd := 0.0
	for i in n_pts - 1:
		hexd += Vector2((pts[i + 1] as Vector3).x - (pts[i] as Vector3).x, (pts[i + 1] as Vector3).z - (pts[i] as Vector3).z).length()
	hexd = maxf(hexd / maxf(n_pts - 1, 1), 1.0)   # the hex spacing: the cruise speed is one hex a unit
	gl_hexd = hexd
	var tr := lerpf(GL_TR[0], GL_TR[1], mass)   # units to build cruise speed from rest
	var amax := hexd / tr
	var ns := cum.size()
	var vl := PackedFloat32Array()
	vl.resize(ns)
	for i in ns:
		vl[i] = hexd
	vl[0] = 0.0
	vl[ns - 1] = 0.0
	var dwell_at := {}        # point index -> units the hull rests there while a big turn swings it
	for k in range(1, n_pts - 1):
		var din: Vector3 = (pts[k] as Vector3) - (pts[k - 1] as Vector3)
		var dout: Vector3 = (pts[k + 1] as Vector3) - (pts[k] as Vector3)
		din.y = 0.0
		dout.y = 0.0
		var r := 1.0
		if din.length() > 0.01 and dout.length() > 0.01:
			var cth := clampf(din.normalized().dot(dout.normalized()), -1.0, 1.0)
			r = 0.0 if cth < -0.7 else clampf((cth + 0.2) / 1.2, 0.15, 1.0)
		for g in groups:
			if int(g["k"]) == k:
				r = minf(r, lerpf(1.0, 0.3, clampf(absf(float(g["d"])) / (TAU / 3.0), 0.0, 1.0)))
				if absf(float(g["d"])) > PI / 3.0 + 0.1:
					r = 0.0
					dwell_at[k] = float(g["w"]) * GL_SPIN * GL_DWELL
		vl[k * 16] = minf(vl[k * 16], hexd * r)
	# 3. the speed profile, leg by leg (a reversal of course or a big turn splits the move: the hull comes to rest there)
	gl_ds = PackedFloat32Array()
	var cuts: Array = [0]
	for k in range(1, n_pts - 1):
		if vl[k * 16] <= 0.0:
			cuts.append(k * 16)
	cuts.append(ns - 1)
	var hold_mid := {}        # point index -> motion time (units) at the middle of its rest
	if n_pts > 1 and float(cum[ns - 1]) > 1e-4:
		for ci in cuts.size() - 1:
			var leg := _gl_leg(cum, vl, int(cuts[ci]), int(cuts[ci + 1]), amax, tr)
			var off: float = gl_ds[gl_ds.size() - 1] if gl_ds.size() > 0 else 0.0
			for i in range(0 if gl_ds.is_empty() else 1, leg.size()):
				gl_ds.append(off + leg[i])
			var kc := int(cuts[ci + 1]) / 16
			if dwell_at.has(kc) and ci < cuts.size() - 2:
				var nh := maxi(int(round(float(dwell_at[kc]) / gl_dtg)), 1)
				hold_mid[kc] = (gl_ds.size() - 1 + nh * 0.5) * gl_dtg
				var dlast: float = gl_ds[gl_ds.size() - 1]
				for i in nh:
					gl_ds.append(dlast)
	var t_motion := float(maxi(gl_ds.size() - 1, 0)) * gl_dtg
	# 4. the timeline: the heading is flown on its own. A spin before the first run, then the motion once the nose is
	#    nearly round; spins at a corner centred on the hull's passage (or its rest) there; a spin after the last run
	#    starting while the hull still brakes. Each spin runs at the ship's own turn-in-place rate.
	gl_ta = clampf(lerpf(0.3, 0.45, mass), 0.3, 0.5)
	gl_turns = []
	var lead_u := 0.0
	var lead_d := 0.0
	var trail_u := 0.0
	for g in groups:
		if int(g["k"]) == 0 and n_pts > 1:
			lead_u = float(g["w"]) * GL_SPIN
			lead_d = absf(float(g["d"]))
		elif int(g["k"]) == n_pts - 1 and n_pts > 1:
			trail_u += float(g["w"]) * GL_SPIN
	gl_tm0 = 0.0
	if lead_u > 0.0:
		# point, then burn: set off when the nose is within GL_POINT of the new heading (the drive builds slowly anyway)
		var pt := float(opts.get("point", GL_POINT))
		var want := 1.0 - pt / maxf(lead_d, pt * 1.5)
		var lo := 0.0
		var hi := 1.0
		for _i in 24:
			var mid := (lo + hi) * 0.5
			if _spin(mid) < want:
				lo = mid
			else:
				hi = mid
		gl_tm0 = lead_u * clampf(hi, 0.35, 0.9)
	var t_end := gl_tm0 + t_motion
	var t_trail0 := maxf(t_end - minf(trail_u * float(opts.get("trail", GL_TRAIL)), minf(tr, t_motion * 0.5)), gl_tm0)
	var t_cursor := 0.0   # (rotation only: spins one after another)
	for g in groups:
		var k := int(g["k"])
		var su := float(g["w"]) * GL_SPIN
		if n_pts == 1:
			gl_turns.append({"t0": t_cursor, "t1": t_cursor + su, "d": float(g["d"])})
			t_cursor += su
		elif k == 0:
			gl_turns.append({"t0": 0.0, "t1": su, "d": float(g["d"])})
		elif k == n_pts - 1:
			gl_turns.append({"t0": t_trail0, "t1": t_trail0 + su, "d": float(g["d"])})
		else:
			var tc := gl_tm0 + (float(hold_mid[k]) if hold_mid.has(k) else _gl_time_at(float(cum[mini(k * 16, ns - 1)])))
			gl_turns.append({"t0": maxf(tc - su * 0.5, 0.0), "t1": maxf(tc - su * 0.5, 0.0) + su, "d": float(g["d"])})
	gl_T = maxf(t_end, 1e-3)
	for t in gl_turns:
		gl_T = maxf(gl_T, float(t["t1"]))
	gl_yaw0 = cur_yaw
	gl_final_yaw = la
	gl_motion_time = t_motion
	if n_pts > 1:
		var old_length: float = run["len"]
		if n_pts > 2 and Vector2((pts[-1] as Vector3).x - (pts[-2] as Vector3).x, (pts[-1] as Vector3).z - (pts[-2] as Vector3).z).length() < 0.01:
			# The old vertical landing knot made Catmull-Rom overshoot horizontally and reverse.
			# Keep its timing, but bleed altitude during the final approach instead.
			run["pts"] = pts.duplicate()
			run["pts"].pop_back()
			run["land"] = true
		run["smooth"] = true
		_prep_run(run)
		for i in gl_ds.size():
			gl_ds[i] *= float(run["len"]) / old_length
	gl_p = 0.0
	# the move takes as long as its own physics needs at the battle's pace (one unit = unit_s seconds), so a spin or a
	# ramp lasts the same whatever else is in the move; only a move past the cap is played faster as a whole
	path_dur = clampf(gl_T * unit_s, 0.05, float(opts.get("cap", 7.0)))
	_prev_pos = position
	_vel = Vector3.ZERO
	_acc = Vector3.ZERO
	_prev_yaw = cur_yaw
	_yaw_v = 0.0
	_yaw_a = 0.0
	thrust = 0.0
	jet_retro = 0.0
	jet_side = 0.0
	jet_aft = 0.0
	jet_turn = 0.0
	# this flight's peaks, so the drive and the jets read the push as a share of the hardest push in the move
	gl_vpk = 0.0
	gl_apk = 0.0
	gl_yapk = 0.0
	for k in range(0, 241):
		var fo := _gl_force(k / 240.0)
		gl_vpk = maxf(gl_vpk, (fo[0] as Vector3).length())
		gl_apk = maxf(gl_apk, (fo[1] as Vector3).length())
		gl_yapk = maxf(gl_yapk, absf(_gl_yaw_acc(k / 240.0)))


# one leg's distance along the curve on the time grid (from rest to rest between samples i0 and i1): cruise one hex a
# unit under the limits vl, accel-limited both ways (forward and backward passes), then the speed through a box filter
# twice over zero padding (the total distance is kept), so every push builds and fades instead of switching on and off
func _gl_leg(cum: Array, vl: PackedFloat32Array, i0: int, i1: int, amax: float, tr: float) -> PackedFloat32Array:
	var n := i1 - i0 + 1
	var v := PackedFloat32Array()
	v.resize(n)
	for i in n:
		v[i] = vl[i0 + i]
	v[0] = 0.0
	v[n - 1] = 0.0
	for i in range(1, n):
		v[i] = minf(v[i], sqrt(v[i - 1] * v[i - 1] + 2.0 * amax * (float(cum[i0 + i]) - float(cum[i0 + i - 1]))))
	for i in range(n - 2, -1, -1):
		v[i] = minf(v[i], sqrt(v[i + 1] * v[i + 1] + 2.0 * amax * (float(cum[i0 + i + 1]) - float(cum[i0 + i]))))
	var ts := PackedFloat32Array()
	ts.resize(n)
	ts[0] = 0.0
	for i in range(1, n):
		var ds := float(cum[i0 + i]) - float(cum[i0 + i - 1])
		ts[i] = ts[i - 1] + (2.0 * ds / maxf(v[i] + v[i - 1], 1e-4) if ds > 1e-6 else 0.0)
	var t_raw: float = ts[n - 1]
	var dtg := gl_dtg
	var box := maxi(int(round(0.3 * tr / dtg)), 1)
	var pad := 2 * box + 2
	var m := int(ceil(t_raw / dtg)) + 1
	var vel := PackedFloat32Array()
	vel.resize(m + 2 * pad)
	var j := 0
	var d_prev := 0.0
	var d0 := float(cum[i0])
	var leg_len := float(cum[i1]) - d0
	for gi in m:
		var t := minf(gi * dtg, t_raw)
		while j < n - 2 and ts[j + 1] < t:
			j += 1
		var span := maxf(ts[mini(j + 1, n - 1)] - ts[j], 1e-6)
		var d := float(cum[i0 + j]) - d0 + (float(cum[i0 + mini(j + 1, n - 1)]) - float(cum[i0 + j])) * clampf((t - ts[j]) / span, 0.0, 1.0)
		if gi > 0:
			vel[pad + gi - 1] = (d - d_prev) / dtg
		d_prev = d
	for _pass in 2:
		var acc := 0.0
		var out := PackedFloat32Array()
		out.resize(vel.size())
		for i in vel.size():
			acc += vel[i]
			if i >= box:
				acc -= vel[i - box]
			out[i] = acc / box
		vel = out
	var first := vel.size()
	var last := -1
	for i in vel.size():
		if vel[i] > 1e-5:
			first = mini(first, i)
			last = i
	var res := PackedFloat32Array()
	res.append(0.0)
	if last < first or leg_len <= 1e-5:
		return res
	var dsum := 0.0
	for i in range(first, last + 1):
		dsum += vel[i] * dtg
		res.append(dsum)
	var kd := leg_len / maxf(dsum, 1e-6)
	for i in res.size():
		res[i] = res[i] * kd
	return res


# motion time (units) at which the hull has gone d along the curve
func _gl_time_at(d: float) -> float:
	var lo := 0
	var hi := gl_ds.size() - 1
	if hi <= 0:
		return 0.0
	if d >= gl_ds[hi]:
		return hi * gl_dtg
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if gl_ds[mid] < d:
			lo = mid
		else:
			hi = mid
	var span := maxf(gl_ds[hi] - gl_ds[lo], 1e-6)
	return (lo + clampf((d - gl_ds[lo]) / span, 0.0, 1.0)) * gl_dtg


func _gl_dist(t: float) -> float:
	var n := gl_ds.size()
	if n == 0:
		return 0.0
	var x := t / gl_dtg
	if x <= 0.0:
		return gl_ds[0]
	if x >= n - 1:
		return gl_ds[n - 1]
	var i := int(x)
	# a smooth read between grid points (Catmull-Rom), so the second difference the jets read is not stepped
	var f := x - i
	var a: float = gl_ds[maxi(i - 1, 0)]
	var b: float = gl_ds[i]
	var c: float = gl_ds[mini(i + 1, n - 1)]
	var e: float = gl_ds[mini(i + 2, n - 1)]
	return 0.5 * ((2.0 * b) + (-a + c) * f + (2.0 * a - 5.0 * b + 4.0 * c - e) * f * f + (-a + 3.0 * b - 3.0 * c + e) * f * f * f)


func _gl_pose(p: float) -> Array:
	var t := p * gl_T
	# the travel runs on its own clock from gl_tm0 (it is not stretched over the spins: a turn first, then the burn)
	var distance := _gl_dist(t - gl_tm0)
	var pos: Vector3 = _curve_at(_gl_run, distance) if gl_ds.size() > 0 else (_gl_run["pts"][0] as Vector3)
	if _gl_run.get("land", false):
		pos.y *= 1.0 - smoothstep(0.7, 1.0, clampf((t - gl_tm0) / maxf(gl_motion_time, 1e-4), 0.0, 1.0))
	var yaw := gl_yaw0
	for tn in gl_turns:
		yaw += float(tn["d"]) * _spin((t - float(tn["t0"])) / maxf(float(tn["t1"]) - float(tn["t0"]), 1e-4))
	return [pos, yaw]


# a spin over its window: the couple builds the spin over gl_ta of it (a heavier hull longer), it coasts, the
# counter-couple bleeds it over the same share (sine ramps: the spin never snaps on or off)
func _spin(x: float) -> float:
	if x <= 0.0:
		return 0.0
	if x >= 1.0:
		return 1.0
	var ta := gl_ta
	var vmax := 1.0 / (1.0 - ta)
	if x < ta:
		return vmax * (x * 0.5 - ta / (2.0 * PI) * sin(PI * x / ta))
	if x > 1.0 - ta:
		var q := 1.0 - x
		return 1.0 - vmax * (q * 0.5 - ta / (2.0 * PI) * sin(PI * q / ta))
	return vmax * (ta * 0.5 + (x - ta))


# pose, velocity and acceleration (per unit of move time fraction), yaw rate and yaw acceleration at p
func _gl_deriv(p: float) -> Array:
	var e := 1.0 / 400.0
	var a0: Array = _gl_pose(maxf(p - e, 0.0))
	var a1: Array = _gl_pose(p)
	var a2: Array = _gl_pose(minf(p + e, 1.0))
	var v: Vector3 = ((a2[0] as Vector3) - (a0[0] as Vector3)) / (2.0 * e)
	var ac: Vector3 = ((a2[0] as Vector3) - 2.0 * (a1[0] as Vector3) + (a0[0] as Vector3)) / (e * e)
	v.y = 0.0
	ac.y = 0.0
	var yv := (float(a2[1]) - float(a0[1])) / (2.0 * e)
	var ya := (float(a2[1]) - 2.0 * float(a1[1]) + float(a0[1])) / (e * e)
	return [a1, v, ac, yv, ya]

# the hull's velocity and acceleration (timeline units) for the jets: from the smooth speed profile along the path (its
# first and second differences over a few grid steps) and the bend of the curve, not from the second difference of the
# position (that carries the curve's arc-length ripple and lit the jets at random while cruising)
func _gl_force(p: float) -> Array:
	if gl_ds.size() < 2:
		return [Vector3.ZERO, Vector3.ZERO]
	var tm := p * gl_T - gl_tm0
	var h := 3.0 * gl_dtg
	var s0 := _gl_dist(tm - h)
	var s1 := _gl_dist(tm)
	var s2 := _gl_dist(tm + h)
	var sp := (s2 - s0) / (2.0 * h)
	var spp := (s2 - 2.0 * s1 + s0) / (h * h)
	var len: float = _gl_run["len"]
	var dl := gl_hexd * 0.12
	var t0 := _gl_tan(clampf(s1 - dl, 0.0, len))
	var t1 := _gl_tan(clampf(s1, 0.0, len))
	var t2 := _gl_tan(clampf(s1 + dl, 0.0, len))
	var bend := (t2 - t0) / (2.0 * dl)
	return [t1 * sp, t1 * spp + bend * sp * sp]


func _gl_tan(d: float) -> Vector3:
	var len: float = _gl_run["len"]
	var e := gl_hexd * 0.05
	var v := _curve_at(_gl_run, minf(d + e, len)) - _curve_at(_gl_run, maxf(d - e, 0.0))
	v.y = 0.0
	return v.normalized() if v.length() > 1e-6 else Vector3.ZERO


func _gl_yaw_acc(p: float) -> float:
	var t := p * gl_T
	var a := 0.0
	for tn in gl_turns:
		var w := maxf(float(tn["t1"]) - float(tn["t0"]), 1e-4)
		var x := (t - float(tn["t0"])) / w
		if x > 0.0 and x < 1.0:
			var ta := gl_ta
			var vmax := 1.0 / (1.0 - ta)
			# the spin's acceleration (per unit of its window, squared): a sine pulse up over ta, down over the last ta
			if x < ta:
				a += float(tn["d"]) * vmax * 0.5 * PI / ta * sin(PI * x / ta) / (w * w)
			elif x > 1.0 - ta:
				a -= float(tn["d"]) * vmax * 0.5 * PI / ta * sin(PI * (1.0 - x) / ta) / (w * w)
	return a


func _glide_step(dt: float) -> void:
	var dts := dt / maxf(speed_k, 0.05)   # Enter or Space hurries a move already under way
	gl_p = minf(gl_p + dts / path_dur, 1.0)
	if gl_p >= 1.0:
		var fin: Array = _gl_pose(1.0)
		position = fin[0]
		cur_yaw = float(fin[1])
		rotation.y = cur_yaw
		glide_bank = 0.0
		path_dur = 0.0
		glide = false
		_vel = Vector3.ZERO
		_acc = Vector3.ZERO
		_yaw_v = 0.0
		_yaw_a = 0.0
		return
	var d: Array = _gl_deriv(gl_p)
	position = (d[0] as Array)[0]
	cur_yaw = float((d[0] as Array)[1])
	rotation.y = cur_yaw
	_vel = (d[1] as Vector3) / path_dur
	_acc = (d[2] as Vector3) / (path_dur * path_dur)
	_yaw_v = float(d[3]) / path_dur
	_yaw_a = float(d[4]) / (path_dur * path_dur)
	# no roll into turns: nothing in space leans a hull into a turn (issue 505 item 4). ShipView never writes the root's
	# roll or pitch (fx/API.md: G4's hit reactions own them); glide_bank stays 0 for fx_ship's read of it
	glide_bank = 0.0
	_prev_pos = position
	_prev_yaw = cur_yaw
	_glide_thrusters(d, dts)


# The drive and the jets, from the forces on the hull (+x is the bow). All in the ship's own frame, each as a share of
# this move's hardest push, each level eased (JET_K) so nothing lights or dies in one frame:
#   main drive: forward push while the hull is not backing (a hard burn), and a low hot glow while it coasts;
#   retro jets at the bow: backward push (braking, or setting off on a back-off);
#   aft jets: forward push while the hull backs (stopping a back-off; the main drive stays low);
#   side jets, a matched bow and stern pair: sideways push (slides, the drift at a dogleg);
#   turning jets, bow one way and stern the other: spin acceleration (one pair starts a turn, the opposite pair stops it).
func _glide_thrusters(d: Array, dts: float) -> void:
	for k in _puff_cd.keys():
		_puff_cd[k] = float(_puff_cd[k]) - dts
	var yw := float((d[0] as Array)[1])
	var bow := Vector3(cos(yw), 0, -sin(yw))
	var stb := Vector3(sin(yw), 0, cos(yw))       # the ship's +z
	var fo := _gl_force(gl_p)
	var v: Vector3 = fo[0]
	var a: Vector3 = fo[1]
	var ak := 1.0 / maxf(gl_apk, 1e-4)
	var fwd := a.dot(bow) * ak
	var lat := a.dot(stb) * ak
	var v_fwd := v.dot(bow) / maxf(gl_vpk, 1e-4)
	var backing := v_fwd < -0.05
	var turn := _gl_yaw_acc(gl_p) / gl_yapk if gl_yapk > 1e-6 else 0.0
	var e := 1.0 - exp(-dts * JET_K)
	var burn := 0.0 if backing else clampf(fwd, 0.0, 1.0)
	# the coast glow follows the forward part of the speed: a ship sliding sideways or backing is not coasting on its drive
	var want := maxf(burn, GL_COAST * smoothstep(0.0, 0.3, maxf(v_fwd, 0.0)))
	thrust = lerpf(thrust, want, 1.0 - exp(-dts * (8.0 if want > thrust else 5.0)))
	jet_retro = lerpf(jet_retro, clampf(-fwd, 0.0, 1.0), e)
	jet_aft = lerpf(jet_aft, clampf(fwd, 0.0, 1.0) if backing else 0.0, e)
	# fewer, clearer jets: while the turning pair works, the side pair stays quiet
	jet_side = lerpf(jet_side, clampf(lat, -1.0, 1.0) * (1.0 - clampf(absf(turn), 0.0, 1.0)), e)
	jet_turn = lerpf(jet_turn, clampf(turn, -1.0, 1.0), e)
	if jet_retro > JET_ON:
		_emit_jet("retro", _retro_puffs.bind(jet_retro))
	if jet_aft > JET_ON:
		_emit_jet("aft", _aft_puffs.bind(jet_aft))
	if absf(jet_side) > JET_ON:
		_emit_jet("side", _side_puffs.bind(signf(jet_side), absf(jet_side)))
	if absf(jet_turn) > JET_ON:
		_emit_jet("couple", _couple_puffs.bind(signf(jet_turn), absf(jet_turn)))


# a jet under way is a stream of puffs: one every 0.07 s (a capital's every 0.1 s, longer and bigger)
func _emit_jet(kind: String, f: Callable) -> void:
	if float(_puff_cd.get(kind, 0.0)) > 0.0:
		return
	_puff_cd[kind] = lerpf(0.07, 0.1, clampf(mass / MASS_MAX, 0.0, 1.0))
	f.call()


func snap_to(p: Vector3, yaw: float) -> void:
	path_dur = 0.0
	glide_bank = 0.0
	glide = false
	segs = []
	path_yaws = []
	_yaw_v = 0.0
	position = p
	_prev_pos = p
	cur_yaw = yaw
	rotation.y = yaw


# ---------------------------------------------------------------- RCS jets: short cold-gas bursts on the hull
# (puffs are left in space where they were fired; they do not ride along with the hull)
# Issue 370 (R150, RULEBOOK 6.7): each jet starts on the ship. The spot each one is named by below (a station along the
# length, a side, from the fitted box) only aims: the attach point service (fx/fx_hull.gd jet) gives the authored hp_rcs
# nearest it, else the plating a ray finds on that side at that station, else no puff (logged and counted). Before
# this, the puff sat at the box spot itself, which on the barge and other hulls that do not fill their box is empty space.
func _couple_puffs(sgn: float, k: float) -> void:
	_jets("couple", sgn, k)


func _retro_puffs(k: float) -> void:
	_jets("retro", 1.0, k)


func _aft_puffs(k: float) -> void:
	_jets("aft", 1.0, k)


func _side_puffs(sgn: float, k: float) -> void:
	_jets("side", sgn, k)


func _jets(kind: String, sgn: float, k: float) -> void:
	for j in jet_aims(kind, sgn, L, half_w, half_h):
		_puff(j[0], j[1], k * float(j[3]), j[2])


# Every movement jet, one row each: [aim, gas direction, the side it vents from, strength], in this node's frame.
# One source for the jets and for the attach check (fx/test/attach_check.gd walks every row).
static func jet_aims(kind: String, sgn: float, l: float, hw: float, hh: float) -> Array:
	match kind:
		"couple":
			# a positive yaw acceleration needs the bow pushed to -z and the stern to +z: the bow's +z jet and the stern's -z jet
			var bx := l * 0.4
			return [[Vector3(bx, 0.2, hw * sgn), Vector3(0, 0, sgn), Vector3(0, 0, sgn), 1.0],
				[Vector3(-bx, 0.2, -hw * sgn), Vector3(0, 0, -sgn), Vector3(0, 0, -sgn), 1.0]]
		"retro":
			var bx := l * 0.5
			return [[Vector3(bx, 0.2, hw * 0.45), Vector3(1, 0, 0.25), Vector3(1, 0, 0), 1.0],
				[Vector3(bx, 0.2, -hw * 0.45), Vector3(1, 0, -0.25), Vector3(1, 0, 0), 1.0]]
		"aft":
			var bx := -l * 0.48
			return [[Vector3(bx, hh * 0.6, hw * 0.7), Vector3(-1, 0, 0.2), Vector3(-1, 0, 0), 0.8],
				[Vector3(bx, hh * 0.6, -hw * 0.7), Vector3(-1, 0, -0.2), Vector3(-1, 0, 0), 0.8]]
		"side":
			# pushing the hull to +z vents gas to -z from the jets on that side, a matched pair at bow and stern (no spin)
			return [[Vector3(l * 0.36, 0.2, -hw * sgn), Vector3(0, 0, -sgn), Vector3(0, 0, -sgn), 1.0],
				[Vector3(-l * 0.36, 0.2, -hw * sgn), Vector3(0, 0, -sgn), Vector3(0, 0, -sgn), 1.0]]
	return []


# The attach point service for this hull: fx_ship.setup hands over its own; a ShipView with no effects system makes one.
func _attach_hull():
	if attach == null and not meshes.is_empty():
		attach = ATTACH.new()
		attach.code = code
		attach.formation = not squad_kind.is_empty()
		attach.analyse(self, meshes, hash(code))
	return attach


# Where the jet named by `aim` (this node's frame) starts, on the hull as it sits now (ShipView bobs it), or INF for none.
func jet_point(aim: Vector3, out: Vector3) -> Vector3:
	var a = _attach_hull()
	if a == null:
		return Vector3.INF
	var o := out.normalized()
	var through := aim - o * (aim - (a.core as Vector3)).dot(o)
	var h: Dictionary = a.jet(aim, through, o)
	if h.is_empty():
		return Vector3.INF
	return (h["p"] as Vector3) + (hull.position - hull_base)


func _puff(aim: Vector3, dir: Vector3, k := 1.0, out := Vector3.ZERO) -> void:
	jet_count += 1
	if dead or not visible or DisplayServer.get_name() == "headless":
		return
	var at := jet_point(aim, out if out != Vector3.ZERO else dir)
	if at == Vector3.INF:
		return
	var sp := Sprite3D.new()
	sp.texture = _glow_tex()
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.shaded = false
	sp.transparent = true
	sp.material_override = _puff_mat()
	sp.modulate = Color(0.85, 0.88, 0.95, 0.75 * k)  # G4's hit-reaction RCS colour (fx_ship._rcs)
	# a jet reads at battle zoom: about 5% of the hull's length as it leaves the nozzle, three times that as it spreads
	# (in a flown move a capital's jets are bigger and last longer: a heavy burn, not a puff)
	var mk := clampf(mass / MASS_MAX, 0.0, 1.0) if glide else 0.0
	# issue 521 (carried item 2): in a flown move no jet starts smaller than PUFF_MIN world units, about 18 px at the
	# battle camera (r 170), so a frigate's small jets read; the bigger hulls were already past it
	sp.pixel_size = clampf(L * lerpf(0.07, 0.1, mk), PUFF_MIN if glide else 1.4, lerpf(2.8, 4.6, mk)) / 64.0 * (0.6 + 0.4 * k)
	sp.top_level = true
	add_child(sp)
	sp.global_position = to_global(at + dir.normalized() * maxf(L, 6.0) * 0.03)  # just outside the hull, not inside it
	var vw: Vector3 = global_transform.basis.orthonormalized() * dir.normalized()
	puffs.append({"n": sp, "t": 0.0, "v": vw * maxf(L, 6.0) * 0.8 * (0.6 + 0.4 * k) + _vel * 0.6, "s": sp.pixel_size, "a": 0.75 * k, "life": lerpf(0.4, 0.55, mk) if glide else 0.4})


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
		var life: float = pf.get("life", 0.4)
		sp.global_position += (pf.v as Vector3) * dt * (1.0 - pf.t / life)
		sp.pixel_size = float(pf.s) * (1.0 + pf.t * 5.0)
		sp.modulate.a = maxf(0.0, float(pf.a) * (1.0 - pf.t / life))
		if pf.t >= life:
			sp.queue_free()
			puffs.remove_at(i)


func _process(dt: float) -> void:
	if not puffs.is_empty():
		_puffs_step(dt)
	if dead:
		path_dur = 0.0
		glide = false
		thrust = 0.0
	if not squad_kind.is_empty():
		hull.active = not dead and visible
	if path_dur > 0.0 and glide:
		_glide_step(dt)
	elif thrust + jet_retro + jet_aft + absf(jet_side) + absf(jet_turn) > 0.0 and path_dur <= 0.0:
		# after a flown move the drive and jet levels fade out (no puffs are fired; the last ones fade on their own)
		var k := exp(-dt * JET_K)
		thrust = thrust * k if thrust > 0.01 else 0.0
		jet_retro = jet_retro * k if jet_retro > 0.01 else 0.0
		jet_aft = jet_aft * k if jet_aft > 0.01 else 0.0
		jet_side = jet_side * k if absf(jet_side) > 0.01 else 0.0
		jet_turn = jet_turn * k if absf(jet_turn) > 0.01 else 0.0
	elif path_dur > 0.0 and not segs.is_empty():
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
	# Sparse matched station-keeping jets, independent of the smooth flight curve.
	if not dead and visible and path_dur <= 0.0 and squad_kind.is_empty():
		var idle_t := Time.get_ticks_msec() / 1000.0
		if idle_t >= float(_puff_cd.get("idle_at", 0.0)):
			_side_puffs(1.0 if sin(idle_t + bob_seed) > 0.0 else -1.0, 0.32)
			_puff_cd["idle_at"] = idle_t + 1.6 + fposmod(bob_seed, 0.8)
	# A slow idle drift, separate from the cinematic flight bank.
	var bob := Vector3(0, sin(Time.get_ticks_msec() / 1000.0 * 0.6 + bob_seed) * 0.25, 0)
	if not dead:
		hull.position = hull_base + bob
	# the fallback engine glows (only when G4's fx is not drawing the real nozzles) swell only while the drive pushes
	var eg := 0.45 + 1.1 * thrust
	for e in engines:
		(e as Sprite3D).visible = not fx_engines and not dead
		(e as Sprite3D).pixel_size = L * 0.0009 * eg
	if ring.visible:
		ring.rotation.y = -rotation.y
