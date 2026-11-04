extends RefCounted
# Small craft built in their own faction language. Bow is +X, dimensions are in
# craft lengths. One cached mesh per faction/kind, shared by every wingmate.
static var _cache := {}
const FINISH := """
shader_type spatial;
uniform vec4 paint : source_color;
uniform float organic = 0.0;
uniform float glow = 0.0;
varying vec3 part_p;
float grain(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
void vertex() { part_p = VERTEX; }
void fragment() {
	float fine = grain(floor(part_p * 370.0));
	float mottle = sin(part_p.x * 53.0 + sin(part_p.z * 71.0)) * sin(part_p.y * 92.0 + part_p.z * 47.0);
	float pores = smoothstep(0.83, 0.98, fine) * organic;
	float ribs = pow(0.5 + 0.5 * sin(part_p.x * 110.0 + part_p.z * 27.0), 12.0) * organic;
	ALBEDO = paint.rgb * (0.88 + 0.14 * fine + 0.10 * mottle - pores * 0.16 - ribs * 0.12);
	METALLIC = mix(0.5, 0.0, organic);
	ROUGHNESS = mix(0.56, 0.4, organic) + fine * 0.12;
	EMISSION = paint.rgb * glow * (0.7 + 0.3 * mottle);
}
"""

static func kind_for(faction: String, tpl: String) -> String:
	# The spore HULLS entry has sq=bomber for combat behaviour, but its model is
	# always organic, including the brief launch-event view before view() arrives.
	if faction == "chorus" or tpl == "spore": return "spore"
	if tpl in ["fighter", "bomber"]: return tpl
	return "bomber" if faction == "corsair" else "fighter"

static func clear_static() -> void:
	_cache.clear()

static func nozzles(kind: String) -> Array:
	if kind == "spore": return [Vector3(-0.72, 0, 0)]
	var z := 0.1 if kind == "bomber" else 0.075
	return [Vector3(-0.515, 0, z), Vector3(-0.515, 0, -z)]

static func mesh_for(faction: String, kind: String) -> ArrayMesh:
	var key := faction + "|" + kind
	if _cache.has(key): return _cache[key]
	var parts := {}
	var colors: Array = {
		"voidsworn": [Color("514942"), Color("bc652f"), Color("242a30"), Color("ffc16e")],
		"hegemony": [Color("bbc5ce"), Color("366ba3"), Color("283747"), Color("88cfff")],
		"corsair": [Color("753e30"), Color("bb8e4d"), Color("323436"), Color("ff8d45")],
		"ithar": [Color("e6ede5"), Color("b6a66e"), Color("4b7a7c"), Color("9effd4")],
		"chorus": [Color("535c2e"), Color("8b9642"), Color("333e27"), Color("d5df50")],
		"deathless": [Color("303c37"), Color("65766c"), Color("18201c"), Color("54ff83")]
	}.get(faction, [Color.GRAY, Color.SILVER, Color.DIM_GRAY, Color.WHITE])
	var mats: Array = []
	var shader := Shader.new()
	shader.code = FINISH
	for i in 4:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("paint", colors[i].darkened(0.18) if faction == "chorus" and i == 3 else colors[i])
		m.set_shader_parameter("organic", 1.0 if faction == "chorus" else 0.0)
		m.set_shader_parameter("glow", (0.14 if faction == "chorus" else 0.7) if i == 3 else 0.0)
		mats.append(m)
	if kind == "spore":
		_bio(parts)
	else:
		_machine(parts, faction, kind)
	var result := ArrayMesh.new()
	for slot in parts:
		var st: SurfaceTool = parts[slot]
		st.generate_tangents()
		st.commit(result)
		result.surface_set_material(result.get_surface_count() - 1, mats[slot])
	_cache[key] = result
	return result

static func _part(parts: Dictionary, shape: PrimitiveMesh, at: Vector3, dims: Vector3, slot: int, rot := Basis.IDENTITY) -> void:
	if shape is BoxMesh: shape.size = Vector3.ONE
	if shape is PrismMesh: shape.size = Vector3.ONE
	if not parts.has(slot):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		parts[slot] = st
	(parts[slot] as SurfaceTool).append_from(shape, 0, Transform3D(rot.scaled(dims), at))

static func _box(p: Dictionary, at: Vector3, dims: Vector3, slot: int) -> void:
	_part(p, BoxMesh.new(), at, dims, slot)

static func _ellipsoid(p: Dictionary, at: Vector3, dims: Vector3, slot: int) -> void:
	var s := SphereMesh.new()
	s.height = 1.0
	s.radius = 0.5
	s.radial_segments = 16
	s.rings = 8
	_part(p, s, at, dims, slot)

static func _tube(p: Dictionary, a: Vector3, b: Vector3, r0: float, r1: float, slot: int) -> void:
	var c := CylinderMesh.new()
	c.bottom_radius = r0
	c.top_radius = r1
	c.height = a.distance_to(b)
	c.radial_segments = 10
	var axis := (b - a).normalized()
	var rot := Basis(Quaternion(Vector3.UP, axis))
	_part(p, c, (a + b) * 0.5, Vector3.ONE, slot, rot)

# A bevelled, pointed fuselage with crisp chines rather than a box or an AI blob.
static func _body(p: Dictionary, width: float, height: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for section in [[-0.5, 0.65], [-0.32, 1.0], [0.12, 0.8], [0.5, 0.06]]:
		var ring: Array = []
		for yz in [Vector2(0.5, 1), Vector2(-0.5, 1), Vector2(-1, 0.45), Vector2(-1, -0.45), Vector2(-0.5, -1), Vector2(0.5, -1), Vector2(1, -0.45), Vector2(1, 0.45)]:
			ring.append(Vector3(section[0], yz.x * height * section[1], yz.y * width * section[1]))
		rings.append(ring)
	for i in 3:
		for j in 8:
			var k := (j + 1) % 8
			for v in [rings[i][j], rings[i + 1][j], rings[i + 1][k], rings[i][j], rings[i + 1][k], rings[i][k]]:
				st.set_uv(Vector2(v.x + 0.5, v.z + 0.5))
				st.add_vertex(v)
	for end in [0, 3]:
		for j in 8:
			var triangle: Array = [Vector3(-0.5 if end == 0 else 0.5, 0, 0), rings[end][j], rings[end][(j + 1) % 8]]
			if end == 0: triangle.reverse()
			for v in triangle:
				st.set_uv(Vector2(v.y + 0.5, v.z + 0.5))
				st.add_vertex(v)
	st.generate_normals()
	# append_from() adds indexed primitive parts below. Index the loft first or
	# those later indices silently exclude every original fuselage triangle.
	st.index()
	if not p.has(0): p[0] = st
	else: (p[0] as SurfaceTool).append_from(st.commit(), 0, Transform3D.IDENTITY)

static func _machine(p: Dictionary, faction: String, kind: String) -> void:
	var bomber := kind == "bomber"
	_body(p, 0.18 if bomber else 0.12, 0.085)
	# Canopy, dorsal panel, nose sensor and paired forward gun housings.
	_ellipsoid(p, Vector3(0.12, 0.085, 0), Vector3(0.24, 0.095, 0.12), 2)
	_box(p, Vector3(-0.12, 0.086, 0), Vector3(0.2, 0.028, 0.11), 1)
	_box(p, Vector3(0.36, 0.045, 0), Vector3(0.035, 0.02, 0.055), 3)
	for sign_z in [-1.0, 1.0]:
		var z: float = sign_z * (0.2 if bomber else 0.15)
		_tube(p, Vector3(0.0, -0.025, z), Vector3(0.42, -0.025, z), 0.022, 0.014, 2)
		_box(p, Vector3(-0.02, 0, z), Vector3(0.18, 0.07, 0.07), 0)
		# Nozzles and radiator ribs are attached to the hull, not floating lights.
		_tube(p, Vector3(-0.32, 0, z * 0.5), Vector3(-0.5, 0, z * 0.5), 0.055, 0.045, 2)
		_tube(p, Vector3(-0.501, 0, z * 0.5), Vector3(-0.51, 0, z * 0.5), 0.03, 0.03, 3)
		for rib in 4:
			_box(p, Vector3(-0.26 + rib * 0.042, 0.08, sign_z * 0.085), Vector3(0.018, 0.02, 0.04), 2)
		match faction:
			"ithar":
				# Long swept light sails, with a pale spar and a luminous edge.
				_tube(p, Vector3(0.14, 0, z), Vector3(-0.43, 0.1, sign_z * 0.53), 0.025, 0.012, 1)
				_part(p, PrismMesh.new(), Vector3(-0.18, 0.045, sign_z * 0.32), Vector3(0.45, 0.035, 0.4), 0, Basis(Vector3.UP, sign_z * 0.5))
				_tube(p, Vector3(-0.08, 0.06, sign_z * 0.29), Vector3(-0.45, 0.11, sign_z * 0.53), 0.009, 0.004, 3)
			"voidsworn":
				_box(p, Vector3(-0.18, 0, sign_z * 0.23), Vector3(0.39, 0.08, 0.15), 0)
				_box(p, Vector3(-0.1, 0.05, sign_z * 0.23), Vector3(0.28, 0.02, 0.035), 1)
				_part(p, PrismMesh.new(), Vector3(-0.3, 0.14, sign_z * 0.15), Vector3(0.23, 0.18, 0.035), 0)
			"corsair":
				_box(p, Vector3(-0.16, 0, sign_z * 0.25), Vector3(0.42 if sign_z > 0 else 0.33, 0.08, 0.21), 0)
				_box(p, Vector3(-0.1, 0.055, sign_z * 0.25), Vector3(0.19, 0.025, 0.16), 1)
				for bolt in 3:
					_ellipsoid(p, Vector3(-0.2 + bolt * 0.08, 0.076, sign_z * 0.29), Vector3(0.02, 0.012, 0.02), 2)
			_:
				_part(p, PrismMesh.new(), Vector3(-0.12, 0, sign_z * 0.22), Vector3(0.46, 0.055, 0.27), 0, Basis(Vector3.UP, sign_z * 0.22))
				_box(p, Vector3(-0.18, 0.037, sign_z * 0.24), Vector3(0.22, 0.012, 0.045), 1)
		if bomber:
			_tube(p, Vector3(-0.23, -0.1, sign_z * 0.14), Vector3(0.26, -0.1, sign_z * 0.14), 0.044, 0.028, 1)
			_box(p, Vector3(0.0, -0.06, sign_z * 0.14), Vector3(0.16, 0.07, 0.045), 2)

static func _bio(p: Dictionary) -> void:
	_ellipsoid(p, Vector3(0.02, 0, 0), Vector3(0.85, 0.32, 0.42), 2)
	# Overlapping chitin lobes, exposed bile sacs, vein ribs and three tendrils.
	for i in 5:
		var x := 0.28 - i * 0.14
		# Broad overlapping plates taper toward the stern, rather than a row of
		# identical beads. Raised ridges and organic pores catch the battle light.
		_ellipsoid(p, Vector3(x, 0.055, 0), Vector3(0.29, 0.25 - i * 0.024, 0.35 - i * 0.035), 0)
		_tube(p, Vector3(x + 0.07, 0.17 - i * 0.012, 0), Vector3(x - 0.09, 0.14 - i * 0.012, 0), 0.025, 0.012, 1)
		for side in [-1.0, 1.0]:
			_ellipsoid(p, Vector3(x - 0.02, -0.075, side * 0.14), Vector3(0.17, 0.14 + sin(i * 2.1) * 0.025, 0.13), 3)
			_tube(p, Vector3(x, 0.07, side * 0.12), Vector3(x - 0.1, -0.1, side * 0.18), 0.012, 0.008, 1)
	for j in 3:
		var prev := Vector3(-0.3, -0.03, (j - 1) * 0.1)
		for k in 5:
			var next := Vector3(-0.4 - k * 0.105, sin(k * 0.8 + j) * 0.045, (j - 1) * (0.12 + k * 0.035))
			_tube(p, prev, next, 0.027 - k * 0.004, 0.023 - k * 0.004, 1)
			prev = next
