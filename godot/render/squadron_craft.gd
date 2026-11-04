extends RefCounted
# Small craft built in the game frame: bow +X, up +Y. Parts are merged by
# material, so a whole detailed craft is one mesh with five surfaces.
const LOOK := preload("res://fx/faction_look.gd")
const DEFAULT_KIND := {"voidsworn": "fighter", "hegemony": "fighter", "corsair": "bomber", "chorus": "spore", "ithar": "fighter", "deathless": ""}
static var _meshes := {} # Weak references share geometry without holding GPU resources at exit.
const SKIN := """
shader_type spatial;
uniform vec4 paint : source_color;
uniform float organic = 0.0;
varying vec3 local;
void vertex() { local = VERTEX; }
void fragment() {
    float grain = fract(sin(dot(floor(local * 420.0), vec3(12.989, 78.233, 41.17))) * 43758.54);
    float patch = fract(sin(dot(floor(local * 27.0), vec3(19.43, 17.71, 83.11))) * 43758.54);
    float vein = 1.0 - smoothstep(0.03, 0.11, abs(sin(local.x * 48.0 + sin(local.z * 39.0) * 2.2 + local.y * 17.0)));
    float scratch = step(0.987, grain) * (1.0 - organic);
    ALBEDO = paint.rgb * (0.84 + grain * 0.18 + patch * 0.15) * (1.0 - vein * organic * 0.28) + scratch * 0.11;
    ROUGHNESS = mix(0.62, 0.45, organic) + (grain - 0.5) * 0.16;
    METALLIC = mix(0.48, 0.03, organic);
}
"""

static func kind_for(unit: Dictionary) -> String:
	var faction := str(unit.get("fac", "hegemony"))
	# The spore's sq field says bomber (its combat role), never its model.
	if faction == "chorus": return "spore"
	var tpl := str(unit.get("tpl", ""))
	if tpl in ["fighter", "bomber", "spore"]: return tpl
	return DEFAULT_KIND.get(faction, "fighter")

static func make(faction: String, kind: String) -> Node3D:
	var key := faction + "|" + kind
	if _meshes.has(key):
		var cached = _meshes[key].get_ref()
		if cached != null: return _node(faction, kind, cached)
	var builder = load("res://render/squadron_craft.gd").new()
	return builder.build(faction, kind)

static func _node(faction: String, kind: String, mesh: ArrayMesh) -> Node3D:
	var n := Node3D.new()
	n.name = faction + "_" + kind
	var mi := MeshInstance3D.new()
	mi.name = "craft_skin"
	mi.mesh = mesh
	n.add_child(mi)
	return n

var groups: Array = []
var materials: Array = []

func _part(mesh: PrimitiveMesh, at: Vector3, size: Vector3, mat: int, rot := Vector3.ZERO) -> void:
	groups[mat].append_from(mesh, 0, Transform3D(Basis.from_euler(rot).scaled(size), at))

func _box(at: Vector3, size: Vector3, mat: int, rot := Vector3.ZERO) -> void:
	var b := BoxMesh.new()
	b.size = Vector3.ONE
	_part(b, at, size, mat, rot)

func _orb(at: Vector3, size: Vector3, mat: int) -> void:
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 16
	s.rings = 8
	_part(s, at, size, mat)

func _tube(at: Vector3, length: float, radius: float, mat: int, tip := -1.0) -> void:
	var c := CylinderMesh.new()
	c.height = length
	c.bottom_radius = radius
	c.top_radius = radius if tip < 0.0 else tip
	c.radial_segments = 12
	_part(c, at, Vector3.ONE, mat, Vector3(0, 0, -PI / 2.0))

# A closed, faceted diamond with real thickness, also used for crystal vanes.
func _blade(at: Vector3, size: Vector3, mat: int) -> void:
	var p := [Vector3(0.5, 0, 0), Vector3(-0.5, 0, 0), Vector3(-0.18, 0, 0.5), Vector3(-0.18, 0, -0.5), Vector3(-0.12, 0.5, 0), Vector3(-0.12, -0.5, 0)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in [[0, 4, 2], [2, 4, 1], [1, 4, 3], [3, 4, 0], [2, 5, 0], [1, 5, 2], [3, 5, 1], [0, 5, 3]]:
		for i in [tri[2], tri[1], tri[0]]: st.add_vertex(at + p[i] * size)
	st.generate_normals()
	st.index()
	# Every part is indexed before merging. Mixing loose vertices into an
	# indexed primitive group silently drops those faces at draw time.
	groups[mat].append_from(st.commit(), 0, Transform3D.IDENTITY)

func build(faction: String, kind: String) -> Node3D:
	var palette := {
		"voidsworn": [Color("343238"), Color("d4dce4"), Color("15171c")],
		"hegemony": [Color("acb9c9"), Color("356398"), Color("222c3b")],
		"corsair": [Color("6f382d"), Color("ab744e"), Color("242329")],
		"chorus": [Color("42472b"), Color("a08d45"), Color("282d1c")],
		"ithar": [Color("bbc9df"), Color("dbcda5"), Color("354256")],
		"deathless": [Color("30283d"), Color("e9c88d"), Color("15131d")]}
	var colors: Array = palette.get(faction, palette.hegemony).duplicate()
	var glow: Color = LOOK.of(faction).engine
	colors.append(glow)
	colors.append(Color("b9d8ed") if faction == "ithar" else Color("101c29"))
	for i in colors.size():
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		groups.append(st)
		var m := StandardMaterial3D.new()
		m.albedo_color = colors[i]
		m.metallic = 0.05 if faction == "chorus" else 0.55
		m.roughness = 0.48 if faction == "chorus" else 0.62
		if i == 3:
			m.emission_enabled = true
			m.emission = glow
			m.emission_energy_multiplier = 1.6
		if i == 4:
			m.metallic = 0.75
			m.roughness = 0.2
		if i < 3:
			var skin := ShaderMaterial.new()
			var shader := Shader.new()
			shader.code = SKIN
			skin.shader = shader
			skin.set_shader_parameter("paint", colors[i])
			skin.set_shader_parameter("organic", 1.0 if faction == "chorus" else 0.0)
			materials.append(skin)
		else:
			materials.append(m)
	if faction == "chorus":
		_bio()
	elif faction == "ithar":
		_crystal(kind)
	else:
		_metal(faction, kind)
	var mesh := ArrayMesh.new()
	for i in groups.size():
		var arrays: Array = groups[i].commit_to_arrays()
		if arrays[Mesh.ARRAY_VERTEX] == null or arrays[Mesh.ARRAY_VERTEX].is_empty(): continue
		groups[i].generate_normals()
		groups[i].set_material(materials[i])
		groups[i].commit(mesh)
	_meshes[faction + "|" + kind] = weakref(mesh)
	return _node(faction, kind, mesh)

func _metal(faction: String, kind: String) -> void:
	var bomber := kind == "bomber"
	_blade(Vector3.ZERO, Vector3(0.98, 0.21, 0.34 if bomber else 0.24), 0)
	_box(Vector3(-0.18, 0.025, 0), Vector3(0.4, 0.18, 0.26), 0)
	_blade(Vector3(0.13, 0.13, 0), Vector3(0.29, 0.12, 0.14), 4)
	for side in [-1.0, 1.0]:
		var z: float = side * (0.27 if bomber else 0.23)
		_blade(Vector3(-0.13, -0.025, z), Vector3(0.5, 0.055, 0.42), 0)
		_box(Vector3(-0.23, 0.01, z * 1.2), Vector3(0.26, 0.065, 0.075), 1)
		_tube(Vector3(-0.32, 0, z), 0.28, 0.065, 2)
		_tube(Vector3(-0.468, 0, z), 0.035, 0.047, 3)
		# Forward barrels sit in matching wing-root mounts.
		_box(Vector3(0.04, 0.02, side * 0.16), Vector3(0.16, 0.09, 0.075), 2)
		_tube(Vector3(0.19, 0.02, side * 0.16), 0.19, 0.018, 2)
		_tube(Vector3(0.29, 0.02, side * 0.16), 0.025, 0.024, 1)
		for j in 5:
			_box(Vector3(-0.32 + j * 0.047, 0.117, side * 0.075), Vector3(0.018, 0.014, 0.055), 2)
		for j in 3:
			_box(Vector3(-0.26 + j * 0.11, 0.034, z * 1.55), Vector3(0.075, 0.018, 0.09), 1 if j == 1 else 0)
		_box(Vector3(-0.04, 0.024, side * 0.438), Vector3(0.034, 0.025, 0.022), 3)
		if bomber:
			for j in 3:
				_tube(Vector3(-0.1, -0.105, side * (0.19 + j * 0.048)), 0.29, 0.019, 1, 0.009)
	if faction == "voidsworn":
		# Iron spine, paired frost armour and a small ember reliquary.
		_blade(Vector3(-0.17, 0.18, 0), Vector3(0.47, 0.19, 0.08), 0)
		_box(Vector3(0.02, 0.14, 0), Vector3(0.12, 0.02, 0.025), 1)
		_box(Vector3(0.0, 0.14, 0), Vector3(0.025, 0.022, 0.12), 1)
		_orb(Vector3(-0.18, 0.235, 0), Vector3(0.045, 0.055, 0.045), 3)
	elif faction == "corsair":
		for j in 5:
			_box(Vector3(-0.28 + j * 0.105, 0.128, 0.04 if j % 2 else -0.05), Vector3(0.075, 0.023, 0.1), 1, Vector3(0, 0.14 * (j - 2), 0))
		_box(Vector3(-0.22, 0.16, -0.11), Vector3(0.14, 0.05, 0.065), 2)
	else:
		_box(Vector3(-0.24, 0.145, 0), Vector3(0.12, 0.025, 0.17), 1)

func _bio() -> void:
	_orb(Vector3(-0.04, 0, 0), Vector3(0.78, 0.34, 0.35), 0)
	_blade(Vector3(0.3, 0, 0), Vector3(0.4, 0.16, 0.2), 1)
	for side in [-1.0, 1.0]:
		for j in 4:
			var x := -0.26 + j * 0.14
			_orb(Vector3(x, 0.015, side * 0.153), Vector3(0.18, 0.25, 0.17), 1)
			# Bile sacs nestled into the carapace, no guns or engines.
			_orb(Vector3(x, -0.065, side * 0.22), Vector3(0.13, 0.145, 0.13), 3)
			_blade(Vector3(x - 0.05, 0.02, side * 0.29), Vector3(0.25, 0.065, 0.26), 0)
		for j in 3:
			_orb(Vector3(-0.4 - j * 0.06, 0.025 * sin(j), side * (0.1 + j * 0.035)), Vector3(0.14, 0.055 - j * 0.012, 0.055 - j * 0.012), 0)
	for j in 6:
		_blade(Vector3(-0.29 + j * 0.105, 0.165, 0), Vector3(0.14, 0.11, 0.17), 1)
		_orb(Vector3(-0.29 + j * 0.105, 0.19, 0), Vector3(0.055, 0.035, 0.045), 3)

func _crystal(kind: String) -> void:
	_blade(Vector3.ZERO, Vector3(1.0, 0.16, 0.18), 0)
	_blade(Vector3(-0.05, 0.09, 0), Vector3(0.66, 0.11, 0.09), 4)
	for side in [-1.0, 1.0]:
		_blade(Vector3(-0.15, 0, side * 0.25), Vector3(0.55, 0.07, 0.53), 4)
		_blade(Vector3(-0.12, 0.04, side * 0.25), Vector3(0.46, 0.025, 0.035), 1)
		for j in 4:
			_blade(Vector3(-0.32 + j * 0.09, 0.045, side * (0.18 + j * 0.035)), Vector3(0.17, 0.035, 0.035), 3)
		_blade(Vector3(-0.4, 0, side * 0.15), Vector3(0.25, 0.065, 0.1), 1)
		_orb(Vector3(-0.44, 0.01, side * 0.15), Vector3(0.065, 0.045, 0.045), 3)
		if kind == "bomber":
			_blade(Vector3(0.04, -0.09, side * 0.14), Vector3(0.32, 0.09, 0.09), 3)
	_orb(Vector3(0.12, 0.11, 0), Vector3(0.11, 0.08, 0.1), 3)
