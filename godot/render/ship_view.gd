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
	if use_hi and man.has("hi") and man["hi"].has(code):
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
		var bm := BoxMesh.new()
		bm.size = Vector3(1, 0.25, 0.35)
		var mi := MeshInstance3D.new()
		mi.mesh = bm
		hull.add_child(mi)
	_collect(hull)
	_look()
	_fit()
	if squad:
		for off in [Vector3(-L * 1.3, 0.3, L * 1.1), Vector3(-L * 1.3, -0.3, -L * 1.1), Vector3(-L * 2.5, 0.0, 0.0)]:
			var wing: Node3D = hull.duplicate()
			wing.position = hull.position + off
			add_child(wing)
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
	if HT.AI_HULL_YAW.has(code):
		yaw_fix = -PI / 2.0 * float(HT.AI_HULL_YAW[code])
	var c := box.get_center()
	hull.transform = Transform3D(Basis(Vector3.UP, yaw_fix).scaled(Vector3(k, k, -k)), Vector3.ZERO)
	hull.position = -(hull.transform.basis * c)
	hull_base = hull.position


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


func play_path(keys: Array, yaws: Array, alts: Array, S: float, dur: float) -> void:
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


func busy() -> bool:
	return path_dur > 0.0


func _process(dt: float) -> void:
	if path_dur > 0.0:
		path_t = minf(path_t + dt / (path_dur * speed_k), 1.0)
		# ease in and out over the whole burn (thrust up, cruise, brake)
		var p := path_t
		var e := p * p * (3.0 - 2.0 * p) * 0.6 + p * 0.4
		var x := path_S * e
		var pos := _pos_at(x)
		pos.y = _key_at(path_alts, x, "y")
		position = pos
		cur_yaw = _key_at(path_yaws, x, "yaw")
		rotation.y = cur_yaw
		if path_t >= 1.0:
			path_dur = 0.0
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
	# a slow idle drift, so the fleet does not look parked
	hull.position = hull_base + Vector3(0, sin(Time.get_ticks_msec() / 1000.0 * 0.6 + bob_seed) * 0.25, 0)
	if ring.visible:
		ring.rotation.y = -rotation.y
