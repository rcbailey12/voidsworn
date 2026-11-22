extends RefCounted
# A4 board props (feel pass, Nov 1 2026): the painted A4 ships for the board's station and derelict hulks.
# Ryan's first playtest showed the station as plain grey clay: render/board.gd draws it (and the hulks) from the old hull meshes in
# gen/hulls with a flat material (grey for the station, near black for hulks), while the painted A4 objective O1_37 and every A4 hull
# sit unused in gen/ships. These two calls return the painted scene, or null when it is not built (the caller keeps its old path).
#
# For render/board.gd (F1 owns it; two small edits, announced in port_notes.md):
#   _station():  var n := A4P.station(size)  if n: n.transform = Transform3D(Basis.from_euler(Vector3(0.06, rng.randf() * 6.0, 0.04)), c + Vector3(0, 3, 0)); props.add_child(n); return
#   _hulk():     var n := A4P.hulk(code)     if n: n.transform = Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.5, 0.5), rng.randf() * TAU, rng.randf_range(-0.6, 0.6))).scaled(Vector3.ONE * 11.0), c); props.add_child(n); return
# with const A4P := preload("res://assets/ships/a4_props.gd"). A4 files are true chirality (+Z starboard): no mirrored scale.

const LARGE_STATION_SIZE := 46.0
const BEACON_CODE := "O3_11"

static var _man = null   # not GPU: the parsed ship manifest (JSON)


static func _manifest() -> Dictionary:
	if _man == null:
		_man = {}
		if FileAccess.file_exists("res://gen/manifest.json"):
			_man = JSON.parse_string(FileAccess.get_file_as_string("res://gen/manifest.json"))
	return _man


# the scene file the manifest names for `code`, or "" when the manifest has no row or the file is gone (a stale row in an
# older build: PR 1561 review, so a missing file never logs load errors on every board build)
static func _res(code: String) -> String:
	var m := _manifest()
	if not (m.has("ships") and (m["ships"] as Dictionary).has(code)):
		return ""
	var p := str(m["ships"][code].get("res", ""))
	if p == "" or not ResourceLoader.exists(p):
		return ""
	return p


static func _scene(code: String) -> Node3D:
	var p := _res(code)
	if p == "":
		return null
	var ps = _collect(p) if _pending.has(p) else load(p)
	if not (ps is PackedScene):
		return null
	return (ps as PackedScene).instantiate() as Node3D


# PR 1561 review: the relay beacon file is large, so a Hold battle starts reading it on a worker thread as the battle
# begins (scenes/battle/battle.gd _begin), and the board build only collects it. Paths whose threaded load was requested:
static var _pending := {}


static func prefetch_beacon() -> void:
	var p := _res(BEACON_CODE)
	if p == "" or _pending.has(p) or ResourceLoader.has_cached(p):
		return
	if ResourceLoader.load_threaded_request(p) == OK:
		_pending[p] = true


static func _collect(p: String) -> Resource:
	_pending.erase(p)
	return ResourceLoader.load_threaded_get(p)   # waits only for what the worker has not read yet


# the painted station across a cluster of station hexes
static func station(size: float, debris_clearance := 0.0) -> Node3D:
	# Refs #975. T2 is authored in world units for the large cluster. Smaller
	# clusters and fresh checkouts use the normalized O1_37 at the requested size.
	var t2_path := "res://gen/ships/station_T2.scn"
	if size == LARGE_STATION_SIZE and ResourceLoader.exists(t2_path):
		var t2 := (load(t2_path) as PackedScene).instantiate() as Node3D
		t2.set_meta("station_T2", true)
		# Refs #863. Separate kit/cache leaves PR 977's painted station intact.
		var debris_path := "res://gen/ships/station_T2_debris.scn"
		if ResourceLoader.exists(debris_path):
			var debris := (load(debris_path) as PackedScene).instantiate() as Node3D
			debris.name = "station_T2_debris"
			debris.set_script(load("res://render/station_debris.gd"))
			t2.add_child(debris)
			debris.keep_outside(debris_clearance)
		var look = load("res://render/look.gd")
		var painted := {}
		for child in t2.find_children("*", "MeshInstance3D", true, false):
			for i in child.mesh.get_surface_count():
				var source: Material = child.get_active_material(i)
				if not painted.has(source):
					painted[source] = look.hull(source, "hegemony", true)
				child.set_surface_override_material(i, painted[source])
		for player in t2.find_children("*", "AnimationPlayer", true, false):
			var names: PackedStringArray = player.get_animation_list()
			for anim in names:
				if anim != "RESET":
					player.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
					player.play(anim)
					break
		return t2
	var n := _scene("O1_37")
	if n == null:
		return null
	var root := Node3D.new()
	root.name = "station"
	n.scale = Vector3.ONE * size  # A4 ships are about 1.0 long (+X), so the scale is the size
	root.add_child(n)
	return root


# Issue 1536 (Ryan, Nov 22 2026: "Yes" to showing the Relay in Hold battles): the Navy relay beacon O3_11 for the hold hex, in
# the Navy finish (render/look.gd, as the station), scaled so its length along x is `length`, centred on its own box. Null when
# the build has no O3_11 (the board then keeps its gold hex alone).
static func beacon(length: float) -> Node3D:
	var n := _scene(BEACON_CODE)
	if n == null:
		return null
	var look = load("res://render/look.gd")
	var painted := {}
	var box := AABB()
	var first := true
	for child in n.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var source: Material = mi.get_active_material(i)
			if source != null and not painted.has(source):
				painted[source] = look.hull(source, "hegemony", true)
			if source != null:
				mi.set_surface_override_material(i, painted[source])
		var xf := Transform3D.IDENTITY
		var p: Node = mi
		while p != null and p != n:
			xf = (p as Node3D).transform * xf if p is Node3D else xf
			p = p.get_parent()
		var bb := xf * mi.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	var root := Node3D.new()
	root.name = "relay_beacon"
	var k := length / maxf(box.size.x, 1e-3)
	n.scale = Vector3.ONE * k
	n.position = -box.get_center() * k
	root.add_child(n)
	return root


# a derelict: the A4 hull in its own paint, burnt (darker, rougher, its windows and engines dead), unit length: scale it as the
# board scales its hulks
static func hulk(code: String) -> Node3D:
	var n := _scene(code)
	if n == null:
		return null
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		for i in m.mesh.get_surface_count():
			var src := m.get_active_material(i) as BaseMaterial3D
			if src == null:
				continue
			var b := src.duplicate() as BaseMaterial3D
			b.albedo_color = Color(0.32, 0.29, 0.27)  # soot over the paint; the paint's own pattern still shows
			b.roughness = minf(1.0, b.roughness * 1.2)
			b.emission_enabled = false
			m.set_surface_override_material(i, b)
	return n
