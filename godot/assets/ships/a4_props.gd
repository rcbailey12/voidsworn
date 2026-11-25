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


# Fable on PR 1772 (7c734f53, item 2): station_T2 is large too, so a battle with station hexes or holes starts reading it
# (and its debris) on a worker thread as the battle begins; station() collects it.
static func prefetch_station() -> void:
	for p in [T2_PATH, T2_DEBRIS_PATH]:
		if old_path() or _pending.has(p) or not ResourceLoader.exists(p) or ResourceLoader.has_cached(p):
			continue
		if ResourceLoader.load_threaded_request(p) == OK:
			_pending[p] = true


static func _scene_at(p: String) -> PackedScene:
	return (_collect(p) if _pending.has(p) else load(p)) as PackedScene


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
# scale, PR 977, unchanged). A smaller cluster or a hole gets T2 scaled down until every mesh box of the installed model,
# turned to the board's bearing and projected onto the board, lies inside the cluster's own hexes (Artoo on PR 1772: the
# real footprint, not a circle round the corners), so it never hangs over a playable hex. O1_37 is only the fallback for
# a checkout with no T2 cache.
const T2_PATH := "res://gen/ships/station_T2.scn"
const T2_DEBRIS_PATH := "res://gen/ships/station_T2_debris.scn"
const T2_REACH := 60.8   # T2's horizontal reach from its centre at unit scale (bounds 99.2 x 70.2: production_checks.json)
const BIG_FOOTPRINT_CELLS := 19   # the rules' big station (every hex within 2 of its centre, R314)
const FIT_ANGLES := 720  # rays from the cluster centre used to measure its footprint
# The biome's station kind (rules REGION_BIOME "station": rig, ring, spire). Hook for bespoke kits: when a kind's `scene` is
# installed it replaces T2 for that kind with no board change; until then T2 stands in and the kind only sets a faint
# work light in its colour (rig amber work lamps, ring the Directorate's own blue, spire pale cyan; never purple, R10.9).
const STATION_KINDS := {
	"rig": {"scene": "res://gen/ships/station_rig.scn", "light": Color(1.0, 0.72, 0.42)},
	"ring": {"scene": "res://gen/ships/station_ring.scn", "light": Color(0.56, 0.74, 1.0)},
	"spire": {"scene": "res://gen/ships/station_spire.scn", "light": Color(0.78, 0.94, 1.0)},
}
const KIND_LIGHT_ENERGY := 0.6
# VS_1767_OLD=1: the path before issue 1767 (T2 only on the big cluster, O1_37 elsewhere, four factions' hulks, soot on
# every hulk), for before and after captures on one commit (bench/look_bench.gd --part props). Never set in the game.
const OLD_HULKS := ["H8_23", "V15_37", "C14s_23", "D20_23"]


static func old_path() -> bool:
	return OS.get_environment("VS_1767_OLD") == "1"
static var _reach := {}    # not GPU: scene path -> measured horizontal reach at unit scale
static var _outline := {}  # not GPU: scene path -> PackedVector2Array, its mesh boxes' corners and edge points (x, z)
static var _fit_cache := {}  # not GPU: path|cells|hex_r|bearing -> Vector2(best bearing, scale)
static var _painted_cache := {}  # source material id -> [weakref(source), weakref(painted copy)], owns nothing


# true when board point `p` (x, z) lies in a pointy-top hex of corner radius `hex_r` centred on any of `cells`
static func in_cells(p: Vector2, cells: Array, hex_r: float) -> bool:
	var a := hex_r * sqrt(3.0) / 2.0
	for c in cells:
		var v: Vector2 = p - (c as Vector2)
		if absf(v.x) <= a + 1e-4 and absf(v.y) + absf(v.x) / sqrt(3.0) <= hex_r + 1e-4:
			return true
	return false


# the footprint's distance from its centre along FIT_ANGLES rays (the cells round the centre are star-shaped from it)
static func footprint_rays(cells: Array, hex_r: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(FIT_ANGLES)
	for i in FIT_ANGLES:
		var d := Vector2.from_angle(TAU * float(i) / float(FIT_ANGLES))
		var lo := 0.0
		var hi := hex_r * 2.0 * (1.0 + float(cells.size()))
		for _j in 24:
			var mid := (lo + hi) * 0.5
			if in_cells(d * mid, cells, hex_r):
				lo = mid
			else:
				hi = mid
		out[i] = lo
	return out


# corners and edge points of every mesh box of `root` at unit scale, projected onto the board (x, z)
static func outline_points(root: Node3D) -> PackedVector2Array:
	var out := PackedVector2Array()
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null or mi.get_parent().name == "station_T2_debris":
			continue
		var xf := Transform3D.IDENTITY
		var p: Node = mi
		while p != null and p != root:
			xf = (p as Node3D).transform * xf if p is Node3D else xf
			p = p.get_parent()
		var bb := mi.get_aabb()
		var corners: Array[Vector3] = []
		for i in 8:
			corners.append(xf * bb.get_endpoint(i))
		for i in 8:
			for j in range(i + 1, 8):
				# box edges join corners that differ in one axis bit
				if [1, 2, 4].has(i ^ j):
					for t in 16:   # dense enough that an edge cannot cut across a cluster's notch between samples
						var v: Vector3 = corners[i].lerp(corners[j], float(t) / 16.0)
						out.append(Vector2(v.x, v.z))
		out.append(Vector2(corners[7].x, corners[7].z))
	return out


# the largest scale (at most 1) that keeps every outline point, turned by `bearing` about the vertical, inside the cells
# (positions relative to the station's centre)
static func fit_scale(points: PackedVector2Array, cells: Array, hex_r: float, bearing: float) -> float:
	var rays := footprint_rays(cells, hex_r)
	var k := 1.0
	var basis := Basis.from_euler(Vector3(0, bearing, 0))
	for p in points:
		var v := basis * Vector3(p.x, 0, p.y)
		var q := Vector2(v.x, v.z)
		var r := q.length()
		if r < 1e-4:
			continue
		var f := fposmod(q.angle() / TAU, 1.0) * FIT_ANGLES
		var i0 := int(floor(f)) % FIT_ANGLES
		var d := minf(rays[i0], rays[(i0 + 1) % FIT_ANGLES])
		k = minf(k, d / r)
	return k * 0.98   # a hair inside the edge


# The turn, from `bearing` plus a multiple of TAU / FIT_TURNS, whose fit_scale is largest, as Vector2(bearing, scale). The
# outline points are binned once by angle at the rays' own resolution, keeping each bin's farthest point; a turn by a whole
# number of bins moves every point by whole rays, so each candidate's scale is the same as fit_scale's (no second pass).
# Ties keep the drawn bearing first.
const FIT_TURNS := 24
static func best_bearing(points: PackedVector2Array, cells: Array, hex_r: float, bearing: float) -> Vector2:
	var rays := footprint_rays(cells, hex_r)
	var far := PackedFloat32Array()
	far.resize(FIT_ANGLES)
	var basis := Basis.from_euler(Vector3(0, bearing, 0))
	for p in points:
		var v := basis * Vector3(p.x, 0, p.y)
		var q := Vector2(v.x, v.z)
		var r := q.length()
		if r < 1e-4:
			continue
		var i0 := int(floor(fposmod(q.angle() / TAU, 1.0) * FIT_ANGLES)) % FIT_ANGLES
		far[i0] = maxf(far[i0], r)
	var step := FIT_ANGLES / FIT_TURNS
	var best := Vector2(bearing, -1.0)
	for j in FIT_TURNS:
		var k := 1.0
		for i in FIT_ANGLES:
			if far[i] <= 0.0:
				continue
			# a turn of j * TAU / FIT_TURNS more lowers every point's angle by j * step rays
			var a := posmod(i - j * step, FIT_ANGLES)
			k = minf(k, minf(rays[a], rays[(a + 1) % FIT_ANGLES]) / far[i])
		if k * 0.98 > best.y + 1e-6:
			best = Vector2(bearing + TAU * float(j) / float(FIT_TURNS), k * 0.98)
	return best


# The painted station across a cluster of station hexes. `kind` is the biome's station kind, `with_debris` false for a lone
# blocker hex (its torn pieces would drift over open hexes). `cells` are the cluster's hex centres relative to the station
# centre (x, z), `hex_r` their corner radius and `bearing` the turn the caller will give it: when `cells` is set and the
# cluster is smaller than the big station, T2 is fitted inside them.
static func station(size: float, debris_clearance := 0.0, kind := "", with_debris := true, cells: Array = [], hex_r := 10.0, bearing := 0.0) -> Node3D:
	if old_path():
		if size != LARGE_STATION_SIZE:
			return _o1(size, "")
		kind = ""
	var info: Dictionary = STATION_KINDS.get(kind, {})
	var path := T2_PATH
	if info.has("scene") and ResourceLoader.exists(str(info["scene"])):
		path = str(info["scene"])
	if ResourceLoader.exists(path):
		var t2 := _scene_at(path).instantiate() as Node3D
		t2.set_meta("station_T2", true)
		t2.set_meta("station_kind", kind)
		if not _reach.has(path):
			_outline[path] = outline_points(t2)
			var far := 0.0
			for q in _outline[path]:
				far = maxf(far, (q as Vector2).length())
			_reach[path] = far if far > 0.0 else T2_REACH
		var k := 1.0
		# only the approved big 19-hex station keeps unit scale; any other cluster that names its cells is fitted (a 5 to
		# 18 hex cluster too: Fable on PR 1772, L2)
		var fit := cells.size() < BIG_FOOTPRINT_CELLS if not cells.is_empty() else size < LARGE_STATION_SIZE
		if fit:
			if not cells.is_empty() and not (_outline[path] as PackedVector2Array).is_empty():
				# Wave 0 on Sheet M (Fable, Astra, Neon, Nov 23): a fitted T2 read small and left the teaching cluster's
				# outer hexes empty, so it is turned to the best of FIT_TURNS bearings from the drawn one (the largest
				# exact fit); the caller turns it by the "station_bearing" this records
				# one fit per path, cells, hex size and drawn bearing (every station hole asks the same: Fable, item 3)
				var fk := "%s|%s|%s|%s" % [path, str(cells), str(hex_r), str(bearing)]
				if not _fit_cache.has(fk):
					_fit_cache[fk] = best_bearing(_outline[path], cells, hex_r, bearing)
				var best: Vector2 = _fit_cache[fk]
				bearing = best.x
				# never a zero-size station (a cluster whose centre lies outside its own hexes: Fable, item 9)
				if best.y < 0.05:
					push_warning("a4_props: station fit %.3f below 0.05 for %d cells, held at 0.05" % [best.y, cells.size()])
				k = clampf(best.y, 0.05, 1.0)
			else:
				k = clampf(size / LARGE_STATION_SIZE, 0.05, 1.0)
		t2.scale = Vector3.ONE * k
		t2.set_meta("station_scale", k)
		t2.set_meta("station_bearing", bearing)
		# Refs #863. Separate kit/cache leaves PR 977's painted station intact. The field lives in T2's own (scaled) frame,
		# so the clearance it keeps out of is divided by the same scale.
		if with_debris and path == T2_PATH and ResourceLoader.exists(T2_DEBRIS_PATH):
			var debris := _scene_at(T2_DEBRIS_PATH).instantiate() as Node3D
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
					painted[source] = _painted_shared(look, source)
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
	return _o1(size, kind)


# T2's Directorate finish, one copy per source material shared by every station on the board (Fable on PR 1772, item 3),
# held weakly like the derelict copies so the cache keeps nothing alive
static func _painted_shared(look, source: Material) -> Material:
	if source == null:
		return null
	var key := source.get_instance_id()
	var hit = _painted_cache.get(key)
	if hit != null and (hit[0] as WeakRef).get_ref() == source:
		var live = (hit[1] as WeakRef).get_ref()
		if live != null:
			return live
	for k in _painted_cache.keys():
		if (_painted_cache[k][0] as WeakRef).get_ref() == null or (_painted_cache[k][1] as WeakRef).get_ref() == null:
			_painted_cache.erase(k)
	var made: Material = look.hull(source, "hegemony", true)
	_painted_cache[key] = [weakref(source), weakref(made)]
	return made


# the old normalized O1_37 at `size` (the fallback when T2 is not built)
static func _o1(size: float, kind: String) -> Node3D:
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
static func pick_hulk(v: int, local: Array = [], own := "") -> String:
	v = absi(v)
	if old_path():
		return OLD_HULKS[v % OLD_HULKS.size()]
	# a ship that dies in battle leaves its own faction's hulk (Fable on PR 1772, item 8), from the same one draw
	if HULKS.has(own):
		var mine: Array = HULKS[own]
		return str(mine[(v / 100) % mine.size()])
	# the faction first, then one of its hulls, so a faction with two hulls is drawn no more often (Fable on PR 1772, L2)
	var every: Array = HULKS.keys()
	var near: Array = every.filter(func(f): return f in local)
	var pool: Array = near if not near.is_empty() and v % 100 < HULK_LOCAL_PCT else every
	var rest := v / 100
	var codes: Array = HULKS[pool[rest % pool.size()]]
	return str(codes[(rest / pool.size()) % codes.size()])


# a derelict: the A4 hull in its own paint, burnt (darker, rougher, its windows and engines dead), unit length: scale it as the
# board scales its hulks. The burn suits the material (R416, R420 Law 3): the paint is dimmed and pulled toward the
# faction's own scorch colour by its wreck_soot, so Chorus chitin and Glasswright glass (wreck_soot 0) keep their own
# hue and gloss and Eclipse keeps its violet-black (never the old shared warm soot), then held in the dull band.
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
			m.set_surface_override_material(i, derelict_shared(src, fac))
	return n


# PR 1772 LOAD probe (Board, Nov 22): a graveyard reuses one burnt copy per source material and faction, so 31 hulks of
# 8 hulls make one material per hull surface, not one per hulk surface. Nothing changes a hulk's material afterwards.
# The cache owns nothing: each entry holds weak references to its source and to the burnt copy, so the copies live only
# as long as the hulks wearing them. When a battle ends (to the map, or into a battle with no hulks) they go with the
# board, and dead entries are dropped on the next lookup (Antigravity audit and Artoo on PR 1772, Nov 23).
static var _derelict_cache := {}   # key -> [weakref(source material), weakref(burnt copy)]
static func derelict_shared(src: BaseMaterial3D, fac: String) -> BaseMaterial3D:
	var key := "%d|%s|%s" % [src.get_instance_id(), fac, old_path()]
	var hit = _derelict_cache.get(key)
	if hit != null and (hit[0] as WeakRef).get_ref() == src:
		var live = (hit[1] as WeakRef).get_ref()
		if live != null:
			return live
	for k in _derelict_cache.keys():
		if (_derelict_cache[k][0] as WeakRef).get_ref() == null or (_derelict_cache[k][1] as WeakRef).get_ref() == null:
			_derelict_cache.erase(k)
	var made := derelict(src, fac)
	_derelict_cache[key] = [weakref(src), weakref(made)]
	return made



# R420 Law 1 band 3 (contrib/opus/plans/global_cohesion_standard.md): a lit hulk is a dead hull, so its effective base
# albedo (paint texture times tint) is its own paint dimmed (DEAD_DIM, then the faction's burn) and held under a dull
# ceiling, 0.045 linear, so no faction's derelict (the Glasswrights' pale glass above all: Fable on PR 1772, H9) is the
# brightest thing in a graveyard. The ceiling was 0.12 until the PROPS_E pictures (Nov 22 2026), then 0.07 until PROPS_G.
# R425 (Ryan, Nov 23 2026): a wreck is never lighter than its dimmed live paint; the floor only stops pure black. The
# 0.04 floor (and R423's 0.025 for Chorus) had lifted dark paint back up: the Chorus body (about 0.021 live) rendered
# undimmed and the Hullbreaker hull went from 0.027 live to 0.040 dead (CHORUSMAT probe, PR 1772).
const HULK_BAND := Vector2(0.005, 0.045)
# R423 (Ryan, Nov 23 2026): Chorus hulks sit lower still, the tan chitin wrecks under a 0.03 ceiling (PROPS_I).
const CHORUS_HULK_BAND := Vector2(0.005, 0.03)
# Eclipse obsidian keeps the floor it was approved on (R421, unchanged by R425): about 0.04
const OBSIDIAN_BAND := Vector2(0.04, 0.045)
# Visible burn: scorch patches multiplied over the hull's own UVs, their share of the hull growing with wreck_soot
# (Hullbreakers most, Navy least); a faction with wreck_soot 0 (Chorus, Glasswrights) and Eclipse obsidian get none.
const BURN_EDGE := Vector2(0.4, 0.35)  # ramp edge = x + y * wreck_soot: the burnt share of the noise (heavier after PROPS_G)
const BURN_DARK := 2.5                 # the patch multiplier is the faction's scorch colour times this, capped at 1
const BURN_FREQ := 0.012               # about three patches across the hull's UV square
static var _burn_cache := {}
const DEAD_DIM := 0.6   # a dead hull with no lights: its paint dimmed before any soot
const OBSIDIAN := Color(0.22, 0.19, 0.28)   # an Eclipse hulk's effective albedo: violet-black obsidian (R420 Law 3)
const OBSIDIAN_ROUGH := 0.3                 # obsidian keeps a glassy sheen
const CHITIN_DRY_ROUGH := 0.85
const DEAD_METAL_DIM := 0.4    # dead metal (wreck_soot above 0) keeps at most this share of its paint before the band
const DEAD_METAL_KEEP := 0.5   # and this share of its metalness
const DEAD_SPECULAR := 0.2     # and at most this dielectric sheen (Godot's default is 0.5)
const DEAD_GLASS_SPEC := 0.6   # Glasswright dead glass: its sheen times this, gloss kept              # a dead Chorus hull is dry, matte chitin
# The burn comes from the faction's own wound profile (fx/faction_looks.json "wound": scorch_col, wreck_soot; PR 1755,
# issue 1741), the one home for how a faction's hull scorches. Until that block is on main these are its values.
const WOUND_FALLBACK := {
	"voidsworn": {"scorch_col": [0.1, 0.08, 0.07], "wreck_soot": 0.55},
	"hegemony": {"scorch_col": [0.16, 0.18, 0.22], "wreck_soot": 0.25},
	"corsair": {"scorch_col": [0.09, 0.06, 0.045], "wreck_soot": 0.7},
	"chorus": {"scorch_col": [0.2, 0.13, 0.07], "wreck_soot": 0.0},
	"ithar": {"scorch_col": [0.8, 0.86, 0.95], "wreck_soot": 0.0},
	"deathless": {"scorch_col": [0.1, 0.07, 0.14], "wreck_soot": 0.15},
}
static var _tex_mean := {}   # not GPU: albedo texture resource path or id -> its mean colour


static func wound_of(fac: String) -> Dictionary:
	var w = load("res://fx/faction_look.gd").of(fac).get("wound", {}) if fac != "" else {}
	if not (w is Dictionary) or not (w as Dictionary).has("wreck_soot"):
		w = WOUND_FALLBACK.get(fac, WOUND_FALLBACK["voidsworn"])
	return w


# the mean colour of a material's albedo texture (white when it has none), cached per texture. Artoo on PR 1772: only a
# small mip is decompressed and averaged (a 4 x 4 to 8 x 8 level, 16 to 64 pixels), never the whole map; a texture
# without mips is averaged from a nearest-sampled 16 x 16 copy.
static func texture_mean(m: BaseMaterial3D) -> Color:
	var t := m.albedo_texture
	if t == null:
		return Color.WHITE
	var key: String = t.resource_path if t.resource_path != "" else str(t.get_instance_id())
	if _tex_mean.has(key):
		return _tex_mean[key]
	var out := Color.WHITE
	var img := t.get_image()
	if img != null and not img.is_empty():
		out = image_mean(img)
	_tex_mean[key] = out
	return out


static func image_mean(img: Image) -> Color:
	var small: Image = null
	if img.has_mipmaps():
		var w := img.get_width()
		var h := img.get_height()
		var count := img.get_mipmap_count()
		var level := 0
		for l in range(count + 1):
			if maxi(1, w >> l) >= 4 and maxi(1, h >> l) >= 4:
				level = l
		var data := img.get_data()
		var start := img.get_mipmap_offset(level) if level > 0 else 0
		var end := img.get_mipmap_offset(level + 1) if level < count else data.size()
		small = Image.create_from_data(maxi(1, w >> level), maxi(1, h >> level), false, img.get_format(), data.slice(start, end))
	else:
		small = img.duplicate() as Image
		if small.is_compressed():
			small.decompress()
		small.resize(16, 16, Image.INTERPOLATE_NEAREST)
	if small.is_compressed():
		small.decompress()
	small.convert(Image.FORMAT_RGBAF)
	var acc := Color(0, 0, 0, 0)
	for y in small.get_height():
		for x in small.get_width():
			acc += small.get_pixel(x, y)
	var n := float(small.get_width() * small.get_height())
	return Color(acc.r / n, acc.g / n, acc.b / n, acc.a / n)


static func linear_luma(c: Color) -> float:
	var l := c.srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b


# the luminance the shader actually lights: texture and tint each decoded to linear, then multiplied (Artoo on PR 1772 at
# deddb79b: multiplying the encoded values first measured one space and corrected in another)
static func effective_luma(mean: Color, tint: Color) -> float:
	var m := mean.srgb_to_linear()
	var t := tint.srgb_to_linear()
	return 0.2126 * m.r * t.r + 0.7152 * m.g * t.g + 0.0722 * m.b * t.b


# scale a tint (same hue and alpha) so the effective albedo, linear texture times linear tint, lies inside the band
static func into_band(c: Color, mean := Color.WHITE, band := HULK_BAND) -> Color:
	var y := effective_luma(mean, c)
	if y <= 1e-5:
		return c
	var want := clampf(y, band.x, band.y)
	if is_equal_approx(want, y):
		return c
	var l := c.srgb_to_linear()
	var k := want / y
	var out := Color(minf(l.r * k, 1.0), minf(l.g * k, 1.0), minf(l.b * k, 1.0), 1.0).linear_to_srgb()
	out.a = c.a
	return out


# the burnt copy of one hull material for a faction's derelict
static func derelict(src: BaseMaterial3D, fac: String) -> BaseMaterial3D:
	var b := src.duplicate() as BaseMaterial3D
	b.emission_enabled = false
	if old_path():
		b.albedo_color = Color(0.32, 0.29, 0.27)  # the old shared soot (VS_1767_OLD before pictures only)
		b.roughness = minf(1.0, b.roughness * 1.2)
		return b
	var w := wound_of(fac)
	var soot := clampf(float(w.get("wreck_soot", 0.0)), 0.0, 1.0)
	var sc: Array = w.get("scorch_col", [0.1, 0.1, 0.1])
	var c := src.albedo_color
	var mean := texture_mean(src)
	if fac == "deathless":
		# Ryan, Nov 22 2026 (Astra's cleanup, item 4): an Eclipse hulk is dark obsidian, violet-black and glossy, never a
		# dimmed paint that reads brown; the tint is solved so paint times tint lands on OBSIDIAN, then held in the band
		var t := Color(minf(1.0, OBSIDIAN.r / maxf(mean.r, 0.02)), minf(1.0, OBSIDIAN.g / maxf(mean.g, 0.02)),
			minf(1.0, OBSIDIAN.b / maxf(mean.b, 0.02)), c.a)
		# held to the exact tint Ryan approved on PROPS_E (R421): its band step keeps the encoded-space measure it was
		# approved with, so the linear-space fix below (Artoo at deddb79b) leaves the Eclipse look unchanged
		var ye := linear_luma(Color(mean.r * t.r, mean.g * t.g, mean.b * t.b))
		var we := clampf(ye, OBSIDIAN_BAND.x, OBSIDIAN_BAND.y)
		if ye > 1e-5 and not is_equal_approx(we, ye):
			var lt := t.srgb_to_linear()
			var ke := we / ye
			t = Color(minf(lt.r * ke, 1.0), minf(lt.g * ke, 1.0), minf(lt.b * ke, 1.0), 1.0).linear_to_srgb()
			t.a = c.a
		b.albedo_color = t
		b.roughness = minf(src.roughness, OBSIDIAN_ROUGH)
		return b
	var burn := Color(DEAD_DIM, DEAD_DIM, DEAD_DIM).lerp(Color(float(sc[0]), float(sc[1]), float(sc[2])), soot)
	if soot > 0.0:
		# dead metal keeps at most DEAD_METAL_DIM of its paint's light (Wave 0 on Sheet M, Nov 23: Fable, Astra and Neon saw
		# the Directorate wrecks read silver-white at c170; their pale blue-grey scorch at the lightest soot left them at
		# about half their paint). Darker only, so it stays inside R425 (never lighter than 60% of live paint; the floor
		# only stops pure black); Hullbreakers and Sunward already sit under it.
		burn = Color(minf(burn.r, DEAD_METAL_DIM), minf(burn.g, DEAD_METAL_DIM), minf(burn.b, DEAD_METAL_DIM))
	b.albedo_color = into_band(Color(c.r * burn.r, c.g * burn.g, c.b * burn.b, c.a), mean,
		CHORUS_HULK_BAND if fac == "chorus" else HULK_BAND)
	b.roughness = minf(1.0, src.roughness * (1.0 + 0.35 * soot))   # soot dulls metal; glass and chitin keep their gloss
	if fac == "chorus":
		# dead chitin dries out (Board on PROPS_H, Nov 23: the Chorus wrecks still pop in the field); with R425 it is darkened
		# too (CHORUS_HULK_BAND), and the wet sheen goes as well.
		b.roughness = maxf(b.roughness, CHITIN_DRY_ROUGH)
	if soot > 0.0:
		# a dead metal hull loses its polish: half its metal and a dull dielectric sheen, so the sky no longer paints a
		# silver gleam on it at the battle camera (the same Wave 0 finding; its roughness map is kept)
		b.metallic = src.metallic * DEAD_METAL_KEEP
		b.metallic_specular = minf(src.metallic_specular, DEAD_SPECULAR)
	elif fac == "ithar":
		# dead glass keeps its clarity and gloss (roughness untouched) but its lights are out, so its glints soften
		b.metallic_specular = src.metallic_specular * DEAD_GLASS_SPEC
	if soot > 0.0:
		b.detail_enabled = true
		b.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		b.detail_uv_layer = BaseMaterial3D.DETAIL_UV_1
		b.detail_albedo = burn_texture(fac, soot, sc)
		# the detail layer mixes its own normal in where it lays scorch, and with none it would flatten the hull's relief
		# (Fable on PR 1772, item 5): it gets the hull's own normal map on the same UVs, so the relief is unchanged
		if src.normal_enabled and src.normal_texture != null:
			b.detail_normal = src.normal_texture
	return b


# Issue 1204: drop the burn textures before the engine shuts down (render/static_caches.gd calls it at quit; Artoo on
# PR 1772 at 2449bcb0)
static func clear_static() -> void:
	_burn_cache.clear()
	_derelict_cache.clear()
	_painted_cache.clear()


# one scorch-patch texture per faction (white = untouched paint, the scorch multiplier where burnt), built once
static func burn_texture(fac: String, soot: float, sc: Array) -> Texture2D:
	if _burn_cache.has(fac):
		return _burn_cache[fac]
	var dark := Color(minf(1.0, float(sc[0]) * BURN_DARK), minf(1.0, float(sc[1]) * BURN_DARK),
		minf(1.0, float(sc[2]) * BURN_DARK))
	var edge := clampf(BURN_EDGE.x + BURN_EDGE.y * soot, 0.05, 0.9)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, edge, minf(edge + 0.12, 1.0), 1.0])
	g.colors = PackedColorArray([dark, dark, Color.WHITE, Color.WHITE])
	var nz := FastNoiseLite.new()
	nz.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	nz.frequency = BURN_FREQ
	nz.fractal_octaves = 4
	nz.seed = hash(fac) & 0xffff
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.noise = nz
	t.color_ramp = g
	_burn_cache[fac] = t
	return t
