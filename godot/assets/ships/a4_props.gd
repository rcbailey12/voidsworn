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

static var _man = null   # not GPU: the parsed ship manifest (JSON)


static func _manifest() -> Dictionary:
	if _man == null:
		_man = {}
		if FileAccess.file_exists("res://gen/manifest.json"):
			_man = JSON.parse_string(FileAccess.get_file_as_string("res://gen/manifest.json"))
	return _man


static func _scene(code: String) -> Node3D:
	var m := _manifest()
	if not (m.has("ships") and (m["ships"] as Dictionary).has(code)):
		return null
	var ps = load(str(m["ships"][code]["res"]))
	if not (ps is PackedScene):
		return null
	return (ps as PackedScene).instantiate() as Node3D


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
