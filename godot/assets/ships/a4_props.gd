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
static var _pending := {}   # not GPU: paths only (path -> true), the loaded scene stays in the ResourceLoader


static func prefetch_beacon() -> void:
	var p := _res(BEACON_CODE)
	if p == "" or _pending.has(p) or ResourceLoader.has_cached(p):
		return
	if ResourceLoader.load_threaded_request(p) == OK:
		_pending[p] = true


static func _collect(p: String) -> Resource:
	_pending.erase(p)
	return ResourceLoader.load_threaded_get(p)   # waits only for what the worker has not read yet


# Issue 1767 (World V2, R419, Ryan Nov 22 2026 "Option A"): station_T2 is the one station on every station cluster, the
# teaching battle and the lone station blocker. T2 is authored in world units for the big 19-hex cluster (size 46, unit
# scale, PR 977). A smaller cluster gets T2 scaled down so its widest reach around the centre stays inside `clearance`
# (the cluster's own radius: the farthest cell centre plus one hex), so it never hangs over a playable hex. O1_37 is only
# the fallback for a checkout with no T2 cache.
const T2_PATH := "res://gen/ships/station_T2.scn"
const T2_DEBRIS_PATH := "res://gen/ships/station_T2_debris.scn"
const T2_REACH := 60.8   # T2's horizontal reach from its centre at unit scale (bounds 99.2 x 70.2: production_checks.json)
const T2_MIN_SCALE := 0.12
# The biome's station kind (rules REGION_BIOME "station": rig, ring, spire). Hook for bespoke kits: when a kind's `scene` is
# installed it replaces T2 for that kind with no board change; until then T2 stands in and the kind only sets a faint
# work light in its colour (rig amber work lamps, ring the Directorate's own blue, spire pale cyan; never purple, R10.9).
const STATION_KINDS := {
	"rig": {"scene": "res://gen/ships/station_rig.scn", "light": Color(1.0, 0.72, 0.42)},
	"ring": {"scene": "res://gen/ships/station_ring.scn", "light": Color(0.56, 0.74, 1.0)},
	"spire": {"scene": "res://gen/ships/station_spire.scn", "light": Color(0.78, 0.94, 1.0)},
}
const KIND_LIGHT_ENERGY := 0.6
static var _reach := {}   # not GPU: scene path -> measured horizontal reach at unit scale


# T2's scale for a cluster: unit for the big cluster (the approved look), else fitted inside the cluster's clearance
static func t2_scale(size: float, clearance: float, reach := T2_REACH) -> float:
	if size >= LARGE_STATION_SIZE:
		return 1.0
	if clearance <= 0.0:
		return clampf(size / LARGE_STATION_SIZE, T2_MIN_SCALE, 1.0)
	return clampf(clearance / maxf(reach, 1.0), T2_MIN_SCALE, 1.0)


# the horizontal reach of a scene's meshes from its origin (every mesh box corner), or `fallback` when it has no mesh
static func horizontal_reach(root: Node3D, fallback := T2_REACH) -> float:
	var best := 0.0
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		var xf := Transform3D.IDENTITY
		var p: Node = mi
		while p != null and p != root:
			xf = (p as Node3D).transform * xf if p is Node3D else xf
			p = p.get_parent()
		var bb := mi.get_aabb()
		for i in 8:
			var v := xf * bb.get_endpoint(i)
			best = maxf(best, Vector2(v.x, v.z).length())
	return best if best > 0.0 else fallback


# the painted station across a cluster of station hexes. `kind` is the biome's station kind, `with_debris` false for a lone
# blocker hex (its torn pieces would drift over open hexes)
static func station(size: float, debris_clearance := 0.0, kind := "", with_debris := true) -> Node3D:
	var info: Dictionary = STATION_KINDS.get(kind, {})
	var path := T2_PATH
	if info.has("scene") and ResourceLoader.exists(str(info["scene"])):
		path = str(info["scene"])
	if ResourceLoader.exists(path):
		var t2 := (load(path) as PackedScene).instantiate() as Node3D
		t2.set_meta("station_T2", true)
		t2.set_meta("station_kind", kind)
		if not _reach.has(path):
			_reach[path] = horizontal_reach(t2)
		var k := t2_scale(size, debris_clearance, float(_reach[path]))
		t2.scale = Vector3.ONE * k
		t2.set_meta("station_scale", k)
		# Refs #863. Separate kit/cache leaves PR 977's painted station intact. The field lives in T2's own (scaled) frame,
		# so the clearance it keeps out of is divided by the same scale.
		if with_debris and path == T2_PATH and ResourceLoader.exists(T2_DEBRIS_PATH):
			var debris := (load(T2_DEBRIS_PATH) as PackedScene).instantiate() as Node3D
			debris.name = "station_T2_debris"
			debris.set_script(load("res://render/station_debris.gd"))
			t2.add_child(debris)
			debris.keep_outside(debris_clearance / k)
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
		if info.has("light"):
			# one faint unshadowed lamp inside the station's own reach, in the kind's colour (light on nearby hulls stays faint, 6.8)
			var lamp := OmniLight3D.new()
			lamp.name = "station_kind_light"
			lamp.light_color = info["light"]
			lamp.light_energy = KIND_LIGHT_ENERGY
			lamp.omni_range = float(_reach[path]) * 0.5 * k
			lamp.scale = Vector3.ONE / k   # world range = the line above, whether or not the engine scales light range
			lamp.shadow_enabled = false
			lamp.position = Vector3(0, 6.0, 0)
			t2.add_child(lamp)
		return t2
	var n := _scene("O1_37")
	if n == null:
		return null
	var root := Node3D.new()
	root.name = "station"
	root.set_meta("station_kind", kind)
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


# Issue 1767 (R419): the derelict hulls a map's hulk hexes draw from, one or two per faction, all six factions (before
# this only the Directorate, Crusade, Hullbreakers and Eclipse ever appeared). Destroyers and cruisers, true chirality.
const HULKS := {
	"hegemony": ["H8_23"],
	"voidsworn": ["V15_37"],
	"corsair": ["C14s_23"],
	"deathless": ["D20_23"],
	"chorus": ["B20_11", "B21_11"],
	"ithar": ["I11_37", "I15_11"],
}
const HULK_LOCAL_PCT := 70   # percent of hulks drawn from the factions in the battle, the rest from any faction


static func hulk_faction(code: String) -> String:
	for fac in HULKS:
		if code in HULKS[fac]:
			return fac
	return ""


# one hulk code from one random draw `v` (so the board keeps its old number of draws): HULK_LOCAL_PCT of the time a hull of
# a faction in `local` (the battle's factions), else any faction's
static func pick_hulk(v: int, local: Array = []) -> String:
	var every: Array = []
	var near: Array = []
	for fac in HULKS:
		every.append_array(HULKS[fac])
		if fac in local:
			near.append_array(HULKS[fac])
	v = absi(v)
	var pool := near if not near.is_empty() and v % 100 < HULK_LOCAL_PCT else every
	return str(pool[(v / 100) % pool.size()])


# a derelict: the A4 hull in its own paint, burnt (darker, rougher, its windows and engines dead), unit length: scale it as the
# board scales its hulks. The burn suits the material (R416, R419 trap 4): metal hulls take soot over the paint; Chorus
# chitin keeps its own colour, darkened and dried; Glasswright crystal keeps its hue, gloss and clarity, only darkened, so
# glass and flesh never read as the same charcoal metal.
static func hulk(code: String) -> Node3D:
	var n := _scene(code)
	if n == null:
		return null
	var fac := hulk_faction(code)
	n.set_meta("hulk_faction", fac)
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		for i in m.mesh.get_surface_count():
			var src := m.get_active_material(i) as BaseMaterial3D
			if src == null:
				continue
			m.set_surface_override_material(i, derelict(src, fac))
	return n


# the burnt copy of one hull material for a faction's derelict
static func derelict(src: BaseMaterial3D, fac: String) -> BaseMaterial3D:
	var b := src.duplicate() as BaseMaterial3D
	b.emission_enabled = false
	match fac:
		"chorus":
			var c := src.albedo_color
			b.albedo_color = Color(c.r * 0.5, c.g * 0.45, c.b * 0.45, c.a)   # dried chitin, its own hue, a touch warmer
			b.roughness = minf(1.0, src.roughness * 1.1)
		"ithar":
			var g := src.albedo_color
			b.albedo_color = Color(g.r * 0.6, g.g * 0.6, g.b * 0.62, g.a)    # dead crystal: darker, same hue, alpha and gloss
		_:
			b.albedo_color = Color(0.32, 0.29, 0.27)  # soot over the paint; the paint's own pattern still shows
			b.roughness = minf(1.0, b.roughness * 1.2)
	return b
