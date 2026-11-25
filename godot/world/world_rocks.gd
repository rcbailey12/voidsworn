extends RefCounted
# F4 asteroids: the rock library (world/rocks/*.glb, made by world/tools/rockgen.py), a material per rock kind, and
# instanced layers. Every rock of a layer that shares a mesh is one MultiMesh (one draw), with a fixed seeded pose in
# the vertex shader (axis and seed in the instance's custom data). Time and camera movement never turn its geometry.
#
# Kinds (battle.js ROCK_KINDS, the sector's biome):
#   stone   warm ochre S-type silicate rock, dark dust pockets, lighter fresh fracture faces
#   iron    cool dark gunmetal slag crust, bright nickel-iron metal on the fresh ridges (issue 1361)
#   carbon  deep charcoal C-type rock, matte, ash-grey ridge highlights, never tan (issue 1361)
#   ice     pale: a matte frost coat over most of the rock, clean ice in the fresh breaks, no glow (Wave 0, Nov 23)
#   crystal ice comets (Ryan, Nov 22: the crystals were scrapped): a dark dusty crust with a few dirty ice patches, a faint
#           cold glow only in a few deep vents, and on a few big ones a soft gas tail away from the sun (world.gd comets())
# Issue 1361 (World V2, R419): each kind draws on its own subset of the scans (KIND_SCANS) and squeezes them its own way in
# the vertex shader (shape_k: iron chunkier, ice longer and sharper), so the five belts differ in shape as well as colour.
# The scans' COLOR_0.b (facet) is ridge convexity re-baked by world/tools/scan_facet.py, spanning 0 to 1 like rockgen's.
# Far rocks fade into the sky's haze by their distance from the board, so the board's own rocks stay the crispest things
# on screen and the deep field reads as far away (and never as a hex obstacle).

const LIB_DIR := "res://world/rocks/"
static var lib_dir := LIB_DIR
static var _meshes := {}      # name -> Mesh
static var _lib: Dictionary = {}   # not GPU: rocks.json
static var _detail: Texture3D = null
static var _scans: Array = []   # not GPU: scan names
static var _scans_checked := false
static var fallbacks: Array = []   # not GPU: names mesh() had to draw as a fallback sphere


# Issue 1204: drop what this script's statics hold before the engine shuts down (render/static_caches.gd calls it at quit)
static func clear_static() -> void:
	_meshes.clear()
	_detail = null

# The CC0 scans and their explicit far meshes are one package. A partial
# copy must not make some of the seeded choices turn into fallback spheres.
# Issue 1361: five scans (scan_06 and the flat boomerang scan_07 were retired; scan_00, a rubble pile scanned from above
# with an open base, drew as a torn see-through shell from below in the PC capture ROCKS_H; scans.json "retired").
const SCAN_COUNT := 5
# Issue 1361: the flattest a rock may be drawn after its kind's squeeze (shortest over longest side), as ROCK_SHADER
# enforces it (0.32) and world/test/rock_scan_check.gd checks it with the same formula (Fable M5 on PR 1782).
const DRAWN_ASPECT := 0.32
static func scan_names() -> Array:
	if OS.get_environment("VS_PLANET_REMIX") == "0": return []
	if not _scans_checked:
		_scans_checked = true
		var path := lib_dir + "scans.json"
		if not FileAccess.file_exists(path): return []
		var manifest = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not manifest is Dictionary or manifest.get("rocks", []).size() != SCAN_COUNT:
			push_error("R01 scan manifest is incomplete")
			return []
		for entry in manifest.rocks:
			for suffix in ["", "_lo"]:
				# An exported game packs only the imported scene and its remap, not the .glb itself, so a plain
				# file check fails there; ResourceLoader.exists sees the remap (mesh() loads the same way).
				var glb: String = lib_dir + str(entry.name) + str(suffix) + ".glb"
				if not (ResourceLoader.exists(glb) or FileAccess.file_exists(glb)):
					push_error("Missing scanned rock: " + str(entry.name) + suffix)
					return []
		for entry in manifest.rocks: _scans.append(str(entry.name))
	return _scans

const ROCK_SHADER := preload("res://shaders/asteroid.gdshader")

# per kind: base albedo (linear), fresh fracture colour, shader kind, shape (shape_k), tone jitter and second tint.
# Issue 1361: iron is cool gunmetal with nickel ridges, carbon charcoal, each with its own tint range (no shared tan).
const KINDS := {
	"stone": {"base": Vector3(0.125, 0.098, 0.074), "fresh": Vector3(0.29, 0.245, 0.2), "k": 0, "shape": 0.0, "tone": 0.2, "tint": Vector3(1.08, 0.96, 0.84)},
	"iron": {"base": Vector3(0.058, 0.061, 0.067), "fresh": Vector3(0.4, 0.395, 0.385), "k": 1, "shape": -0.35, "tone": 0.16, "tint": Vector3(0.94, 0.98, 1.06)},
	"carbon": {"base": Vector3(0.042, 0.041, 0.04), "fresh": Vector3(0.1, 0.1, 0.104), "k": 2, "shape": -0.12, "tone": 0.22, "tint": Vector3(0.94, 0.96, 1.02)},
	"ice": {"base": Vector3(0.07, 0.074, 0.084), "fresh": Vector3(0.6, 0.7, 0.8), "k": 3, "shape": 0.55, "tone": 0.16, "tint": Vector3(0.92, 1.0, 1.08)},
	# the id stays "crystal" (rules and biomes use it); the look is ice comets since Ryan scrapped the crystals (Nov 22)
	"crystal": {"base": Vector3(0.06, 0.062, 0.068), "fresh": Vector3(0.68, 0.72, 0.77), "k": 4, "shape": 0.3, "tone": 0.14, "tint": Vector3(0.94, 0.99, 1.06)},
}

# Issue 1361: which scans each kind draws on, its most typical first (world.gd _pick weights the first ones double).
# By the scans' own boxes (scans.json ext): 02 is chunky and round, 05 and 01 thick, 04 long, 00 and 03 flat slabs.
const KIND_SCANS := {
	"stone": ["scan_02", "scan_01", "scan_03", "scan_04", "scan_05"],
	"iron": ["scan_02", "scan_05", "scan_01", "scan_04"],
	"carbon": ["scan_03", "scan_05", "scan_02", "scan_01"],
	"ice": ["scan_04", "scan_03", "scan_01", "scan_05"],
	"crystal": ["scan_04", "scan_01", "scan_03", "scan_02"],
}


static func lib() -> Dictionary:
	if _lib.is_empty() and FileAccess.file_exists(lib_dir + "rocks.json"):
		var j = JSON.parse_string(FileAccess.get_file_as_string(lib_dir + "rocks.json"))
		if j is Dictionary:
			_lib = j
	return _lib


static func mesh(name: String) -> Mesh:
	if _meshes.has(name):
		return _meshes[name]
	var m: Mesh = null
	var p := lib_dir + name + ".glb"
	var n: Node = null
	if ResourceLoader.exists(p):
		var ps = load(p)
		if ps is PackedScene:
			n = (ps as PackedScene).instantiate()
	elif FileAccess.file_exists(p):
		# not imported (the PC's shared build had its import stop part way on Nov 1, so every rock went missing): read
		# the glTF file itself at run time
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		if doc.append_from_buffer(FileAccess.get_file_as_bytes(p), "", st) == OK:
			n = doc.generate_scene(st)
	if n != null:
		var mi := _find_mesh(n)
		if mi != null:
			m = mi.mesh
		n.free()
	if m == null:
		m = fallback_mesh(name)
		if not fallbacks.has(name):   # one entry per name, so a long session never grows it (Board on PR 1782)
			fallbacks.append(name)   # issue 1361: the rock bench fails on any (Artoo on PR 1782)
	_meshes[name] = m
	return m


# A real solid blocker even in a partial install. Unit radius matches library rocks.
static func fallback_mesh(key: String) -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 11
	sphere.rings = 6
	var a := sphere.get_mesh_arrays()
	var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var r := RandomNumberGenerator.new()
	r.seed = hash(key)
	var phase := r.randf() * TAU
	for i in v.size():
		var q := v[i]
		v[i] *= 0.84 + 0.12 * sin(q.x * 7.0 + phase) * cos(q.z * 6.0 + q.y * 4.0)
	a[Mesh.ARRAY_VERTEX] = v
	var colors := PackedColorArray()
	colors.resize(v.size())
	colors.fill(Color(0.85, 0.1, 0.6, 0.5))
	a[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	return mesh


static func _find_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var r := _find_mesh(c)
		if r != null:
			return r
	return null


# the names of the rocks a kind draws on (its families first)
static func names_for(kind: String) -> Array:
	var scans := scan_names()
	if not scans.is_empty():
		var out: Array = []
		for nm in KIND_SCANS.get(kind, scans):
			if scans.has(nm): out.append(nm)
		return out if not out.is_empty() else scans.duplicate()
	var L := lib()
	if L.is_empty():
		return ["fallback_" + kind]
	var fams: Array = L.get("kinds", {}).get(kind, ["fragment"])
	var out: Array = []
	for f in fams:
		for r in L["rocks"]:
			if r["family"] == f:
				out.append(r["name"])
	return out


static func detail_tex() -> Texture3D:
	if _detail != null:
		return _detail
	var t := NoiseTexture3D.new()
	t.width = 64
	t.height = 64
	t.depth = 64
	t.seamless = true
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.06
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = 4
	t.noise = n
	t.normalize = true
	_detail = t
	return t


# Issue #230 option B, shipped by #541: rocks turn at the spin rate world.gd and world_living.gd store in each instance
# (the slow cap law; AS10's far-field rates). VS_ROCK_TUMBLE=0 restores the held seeded pose.
static var rock_tumble_k: float = 0.0 if OS.get_environment("VS_ROCK_TUMBLE") == "0" else 1.0


# One material per kind and look (the far layers share it, with their haze)
static func material(kind: String, look: Dictionary) -> ShaderMaterial:
	var K: Dictionary = KINDS.get(kind, KINDS["stone"])
	var m := ShaderMaterial.new()
	m.shader = ROCK_SHADER
	m.set_shader_parameter("kind", int(K["k"]))
	m.set_shader_parameter("base", K["base"])
	m.set_shader_parameter("fresh", K["fresh"])
	m.set_shader_parameter("shape_k", float(K.get("shape", 0.0)))
	m.set_shader_parameter("tone_var", float(K.get("tone", 0.18)))
	m.set_shader_parameter("tint_var", K.get("tint", Vector3.ONE))
	m.set_shader_parameter("detail", detail_tex())
	m.set_shader_parameter("q", 1.0 if str(look.get("quality", "max")) == "max" else 0.0)
	m.set_shader_parameter("scanned", not scan_names().is_empty())
	m.set_shader_parameter("tumble_k", rock_tumble_k)
	m.set_shader_parameter("board_c", look.get("board_c", Vector3.ZERO))
	m.set_shader_parameter("haze_col", look.get("haze", Vector3(0.01, 0.012, 0.02)))
	m.set_shader_parameter("haze_r", look.get("haze_r", Vector2(320, 2200)))
	m.set_shader_parameter("haze_max", float(look.get("haze_max", 0.85)))
	m.set_shader_parameter("glow_col", look.get("glow", Vector3(0.25, 0.75, 1.0)))
	if look.has("rim_pos"):
		m.set_shader_parameter("rim_pos", look["rim_pos"])
		m.set_shader_parameter("rim_k", 1.6)
	return m


# ---------------------------------------------------------------- instanced layers

# Collects rock instances per (mesh, layer) and builds one MultiMeshInstance3D each.
class Batch:
	const Scorch := preload("res://fx/terrain_scorch.gd")
	var groups := {}     # key -> {mesh, mat, shadow, xf: [], cd: []}
	var dust_materials := {}
	var legacy_debris_materials := {}
	var _marked: Array[Dictionary] = []

	func add(mesh_name: String, mat: Material, shadow: bool, xf: Transform3D, spin_axis: Vector3, rate: float, seed_v: float,
			scorch := false, distant_belt := false) -> void:
		# Dust-size rocks keep rockgen's light meshes. Large silhouettes use the
		# scans, at the same radius as the old library, so blocker rules stay put.
		if mesh_name.begins_with("scan_"):
			var scale_v := xf.basis.get_scale().abs()
			if maxf(scale_v.x, maxf(scale_v.y, scale_v.z)) < 1.5:
				mesh_name = "frag_%02d_lo" % (int(seed_v * 65535.0) % 6)
				var mat_id := mat.get_instance_id()
				if not dust_materials.has(mat_id):
					var dust_mat := mat.duplicate() as ShaderMaterial
					dust_mat.set_shader_parameter("scanned", false)
					dust_materials[mat_id] = dust_mat
				mat = dust_materials[mat_id]
		var key := "%s|%d|%d%s" % [mesh_name, mat.get_instance_id(), 1 if shadow else 0, "|scorch" if scorch else ""]
		# The visibility range applies to the whole MultiMesh, so distant groups must be local.
		if distant_belt:
			key += "|belt:" + str((xf.origin / 800.0).floor())
		if not groups.has(key):
			groups[key] = {"mesh": mesh_name, "mat": mat, "shadow": shadow, "xf": [], "cd": [], "scorch": scorch, "distant_belt": distant_belt}
		groups[key]["xf"].append(xf)
		var a := spin_axis.normalized() * rate
		groups[key]["cd"].append(Color(a.x, a.y, a.z, seed_v))

	func build(parent: Node3D, mesh_of: Callable) -> int:
		var n := 0
		for key in groups:
			var g: Dictionary = groups[key]
			var m: Mesh = mesh_of.call(g["mesh"])
			if m == null:
				continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_custom_data = true
			mm.mesh = m
			mm.instance_count = (g["xf"] as Array).size()
			for i in mm.instance_count:
				mm.set_instance_transform(i, g["xf"][i])
				mm.set_instance_custom_data(i, g["cd"][i])
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			mmi.material_override = g["mat"]
			# Bounds about the shader's origin, including off-center crystal clusters. A rigid seeded turn cannot escape it.
			var box := m.get_aabb()
			var radius := box.position.abs().max(box.end.abs()).length()
			mmi.set_instance_shader_parameter("rock_radius", radius)
			if g["mat"] is ShaderMaterial and (g["mat"] as ShaderMaterial).shader.code.contains("rock_ext"):
				mmi.set_instance_shader_parameter("rock_ext", box.size)
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if g["shadow"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if g["distant_belt"]:
				mmi.visibility_range_end = 2200.0
				mmi.visibility_range_end_margin = 350.0
				mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				mmi.lod_bias = 0.75
			# Give the bounds room for the shader's fixed seeded pose.
			mmi.extra_cull_margin = 40.0
			parent.add_child(mmi)
			if g["scorch"]:
				_mark_blockers(mmi, g)
			n += mm.instance_count
		return n

	func _mark_blockers(receiver: MultiMeshInstance3D, group: Dictionary) -> void:
		var mm := receiver.multimesh
		var mat := receiver.material_override as ShaderMaterial
		var shape := float(mat.get_shader_parameter("shape_k"))
		var tumble := float(mat.get_shader_parameter("tumble_k"))
		for i in mm.instance_count:
			var base: Transform3D = group["xf"][i]
			var custom: Color = group["cd"][i]
			var spin := Vector3(custom.r, custom.g, custom.b)
			var axis := spin.normalized() if spin.length_squared() > 0.0 else Vector3.UP
			var angle := TAU * custom.a if spin.length_squared() > 0.0 else 0.0
			var pose := base * Transform3D(Basis(axis, angle), Vector3.ZERO)
			var squash := _scorch_shape(mm.mesh.get_aabb().size, shape, custom.a)
			var hit := Scorch.surface_hit(mm.mesh, receiver.global_transform * pose * Transform3D(squash, Vector3.ZERO))
			var mark := Scorch.stamp(receiver, hit, 3.2, _marked.size() % 2 == 1)
			if mark == null:
				continue
			receiver.layers |= Scorch.RECEIVER
			# Move the seeded tumble into the instance transform so the decal follows the surface.
			mm.set_instance_custom_data(i, Color(0, 0, 0, custom.a))
			mm.set_instance_transform(i, pose)
			_marked.append({"mesh": mm, "index": i, "base": base, "axis": axis, "angle": angle,
				"rate": spin.length() * tumble, "decal": mark, "local": pose.affine_inverse() * mark.transform})

	static func _scorch_shape(extent: Vector3, shape: float, seed_v: float) -> Basis:
		# Same local squeeze as ROCK_SHADER. Include it in the surface query, while the shader still draws it.
		if is_zero_approx(shape):
			return Basis.IDENTITY
		var e := extent.max(Vector3.ONE * 0.001)
		var k := shape * (0.6 + 0.8 * fposmod(seed_v * 431.7, 1.0))
		var ratio := e / e[e.max_axis_index()] if k > 0.0 else Vector3.ONE * e[e.min_axis_index()] / e
		var squeeze := Vector3(pow(ratio.x, absf(k)), pow(ratio.y, absf(k)), pow(ratio.z, absf(k)))
		squeeze = squeeze.clamp(Vector3.ONE * 0.55, Vector3.ONE)
		var drawn := e * squeeze
		squeeze = squeeze.max(Vector3.ONE * (0.32 * drawn[drawn.max_axis_index()]) / e).min(Vector3.ONE)
		return Basis.from_scale(squeeze)

	func step(dt: float) -> void:
		for entry in _marked:
			if is_zero_approx(entry["rate"]):
				continue
			entry["angle"] = fposmod(float(entry["angle"]) + float(entry["rate"]) * dt, TAU)
			var pose: Transform3D = entry["base"] * Transform3D(Basis(entry["axis"], entry["angle"]), Vector3.ZERO)
			(entry["mesh"] as MultiMesh).set_instance_transform(entry["index"], pose)
			(entry["decal"] as Decal).transform = pose * entry["local"]
