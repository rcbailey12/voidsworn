extends RefCounted
# Where effects sit on a hull, found from the hull's own triangles (in the ship root's frame: bow +X, up +Y, port +Z).
#
# The triangles go into a TriangleMesh (Godot's native BVH), so a ray against the real hull costs microseconds:
#   - visible surface samples: rays from outside at random toward the hull; each hit is a point anyone could see and
#     hit, with its outward normal and its section (eng aft third, mid, prow fore third);
#   - mounts: the outermost hull point on a side at four stations along the length (broadside guns), on the top
#     (turrets) and at the bow (lances, torpedo tubes);
#   - nozzles: the stern face, clustered into 1 to 3 engine bells;
#   - impact points: a ray from the attacker toward a sample in the struck section lands on the real surface.

const SEC_ENG := 0
const SEC_MID := 1
const SEC_PROW := 2
const SEC_NAMES := {"eng": 0, "mid": 1, "prow": 2}

var tm: TriangleMesh
var box = AABB()
var L = 1.0
var W = 1.0
var H = 1.0
var c = Vector3.ZERO
var sp = PackedVector3Array()      # sample points
var sn = PackedVector3Array()      # sample normals
var ssec = PackedInt32Array()      # sample sections
var nozzles: Array = []             # {p, r, d}: exit point, bell radius, plume direction (all in the root frame)
var nozzles_from_kit = false        # true when the nozzles came from A4's hp_eng_* hard points
var bow = Vector3.ZERO
var mounts = {}                    # "port", "stb", "top" -> Array of {p, n}
var tri_count = 0
var _rng = RandomNumberGenerator.new()
var stb_z = 1.0                    # +1: root +Z is starboard (G2), -1: +Z is port

# Shared by live hulls, wreck backs and slag. Stable embers, never lit compartments.
const BURNT := """
float burnt_hash(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
vec3 hull_inside(vec3 Pe, vec3 D, float depth, vec3 cell, float heat, vec3 glow, float tm) {
	vec3 q = Pe / max(abs(cell), vec3(0.001));
	float grain = burnt_hash(floor(q * 23.0));
	float ember = smoothstep(0.982, 1.0, grain);
	float occlusion = exp(-clamp(depth / max(abs(cell.x), 0.001), 0.0, 20.0));
	return clamp(vec3(0.004, 0.003, 0.0025) * (0.65 + grain * 0.35)
		+ vec3(0.16, 0.032, 0.006) * ember * clamp(heat, 0.0, 1.0) * (0.25 + occlusion * 0.75), 0.0, 0.2);
}
"""

const MOUTHS := 64
const EXTERIOR := """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 hull_albedo : source_color = vec4(1.0);
uniform sampler2D hull_color : source_color, hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D hull_normal : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D hull_orm : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D hull_rough : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D hull_metal : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D hull_ao : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D hull_emission : source_color, hint_default_black, filter_linear_mipmap_anisotropic;
uniform vec3 hull_uv_scale = vec3(1.0);
uniform vec3 hull_uv_offset = vec3(0.0);
uniform vec4 hull_emission_color : source_color = vec4(0.0);
uniform float hull_emission_energy = 1.0;
uniform vec4 hull_rough_channel = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 hull_metal_channel = vec4(1.0, 0.0, 0.0, 0.0);
uniform vec4 hull_ao_channel = vec4(1.0, 0.0, 0.0, 0.0);
uniform float hull_roughness = 1.0;
uniform float hull_metallic = 0.0;
uniform float hull_specular = 0.5;
uniform float hull_normal_scale = 1.0;
uniform float hull_rim = 0.0;
uniform float hull_rim_tint = 0.0;
uniform float hull_ao_light = 0.0;
uniform bool hull_has_normal = false;
uniform bool hull_has_orm = false;
uniform bool hull_vertex_color = false;
uniform bool hull_emission_multiply = false;
varying vec4 hull_color_v;
void vertex() { UV = UV * hull_uv_scale.xy + hull_uv_offset.xy; hull_color_v = COLOR; }
void fragment() {
	ALBEDO = hull_albedo.rgb * texture(hull_color, UV).rgb;
	if (hull_vertex_color) { ALBEDO *= hull_color_v.rgb; }
	ROUGHNESS = hull_roughness * dot(texture(hull_rough, UV), hull_rough_channel);
	METALLIC = hull_metallic * dot(texture(hull_metal, UV), hull_metal_channel);
	AO = dot(texture(hull_ao, UV), hull_ao_channel);
	if (hull_has_orm) { vec3 orm = texture(hull_orm, UV).rgb; AO = orm.r; ROUGHNESS = orm.g; METALLIC = orm.b; }
	SPECULAR = hull_specular;
	AO_LIGHT_AFFECT = hull_ao_light;
	RIM = hull_rim; RIM_TINT = hull_rim_tint;
	if (hull_has_normal) { NORMAL_MAP = texture(hull_normal, UV).rgb; NORMAL_MAP_DEPTH = hull_normal_scale; }
	vec3 em = texture(hull_emission, UV).rgb;
	EMISSION = (hull_emission_multiply ? hull_emission_color.rgb * em : hull_emission_color.rgb + em) * hull_emission_energy;
}
"""

const DAMAGE_UNIFORMS := """
uniform mat4 fx_hull_frame;
uniform int fx_mouth_count = 0;
uniform vec4 fx_mouths[64]; // centre, radius
uniform vec4 fx_axes[64]; // outward normal, cut depth
uniform vec4 fx_tangents[64]; // tangent, slot half-length
uniform vec4 fx_shapes[64]; // round/square/slot, phases 0, 1, 2
uniform vec4 fx_tears[64]; // square rotation, phase 3, phase 4, unused
uniform vec3 fx_burnt_cell = vec3(1.0);
varying vec3 fx_hull_p;
float fx_mouth_edge(int i, vec3 p) {
	vec3 d = p - fx_mouths[i].xyz;
	vec3 n = fx_axes[i].xyz;
	float R = max(fx_mouths[i].w, 0.0001);
	float x = dot(d, fx_tangents[i].xyz);
	float y = dot(d, cross(n, fx_tangents[i].xyz));
	vec4 s = fx_shapes[i];
	if (s.x > 2.5) {
		float a = length(vec2(x, y)) > 0.00001 ? atan(y, x) : 0.0;
		return length(vec2(x, y)) - R * (1.0 + 0.2 * sin(a * 5.0 + s.w));
	}
	if (s.x > 1.5) {
		float hl = max(fx_tangents[i].w, 0.0001);
		float al = clamp(x, -hl, hl);
		float taper = 1.0 - 0.7 * pow(clamp(abs(al) / hl, 0.0, 1.0), 4.0);
		return length(vec2(x - al, y)) - R * taper * (1.0 + 0.25 * sin(al * 7.0 / R + s.y) + 0.12 * sin(al * 19.0 / R + s.z));
	}
	if (s.x > 0.5) {
		float ca = cos(fx_tears[i].x), sa = sin(fx_tears[i].x);
		vec2 uv = vec2(x * ca + y * sa, -x * sa + y * ca);
		return max(abs(uv.x), abs(uv.y)) - R * (1.0 + 0.05 * sin(uv.x * 9.0 / R + s.y) + 0.05 * sin(uv.y * 7.0 / R + s.z));
	}
	float a = length(vec2(x, y)) > 0.00001 ? atan(y, x) : 0.0;
	return length(vec2(x, y)) - R * (1.0 + 0.16 * sin(3.0 * a + s.y) + 0.09 * sin(5.0 * a + s.z) + 0.05 * sin(9.0 * a + s.w));
}
"""

# Preserve hull textures, ORM, normals and faction rim in the actual surface pass.
# Godot does not expose BaseMaterial3D's generated shader to runtime GDScript.
# A surface overlay cannot discard the opaque skin underneath it.
static func damage_material(src: Material, frame: Transform3D, mouths: Dictionary, L: float) -> ShaderMaterial:
	if src != null and src.has_meta("fx_hull_source"):
		src = src.get_meta("fx_hull_source")
	if src == null:
		src = StandardMaterial3D.new()
	var base: ShaderMaterial = src if src is ShaderMaterial else _exterior(src)
	var code: String = base.shader.code
	var shader := Shader.new()
	var cull := RegEx.new()
	cull.compile("cull_(back|front|disabled)")
	code = cull.sub(code, "cull_disabled", true)
	if not code.contains("cull_disabled"):
		code = code.replace("shader_type spatial;", "shader_type spatial;\nrender_mode cull_disabled;")
	code = code.replace("shader_type spatial;", "shader_type spatial;\n" + BURNT + DAMAGE_UNIFORMS)
	code = _inject(code, "vertex", "", "\nfx_hull_p = (fx_hull_frame * vec4(VERTEX, 1.0)).xyz;\n")
	code = _inject(code, "fragment", """
float fx_soot = 0.0;
// cull_disabled flips back-facing normals in the renderer, including mirrored exteriors.
if (determinant(mat3(MODEL_MATRIX)) < 0.0) { NORMAL = -NORMAL; }
for (int i = 0; i < 64; i++) {
	if (i >= fx_mouth_count) { break; }
	float h = dot(fx_hull_p - fx_mouths[i].xyz, fx_axes[i].xyz);
	float R = max(fx_mouths[i].w, 0.0001);
	if (h < -fx_axes[i].w || h > R * 0.8) { continue; }
	float edge = fx_mouth_edge(i, fx_hull_p);
	if (edge < -R * 0.035) { discard; }
	fx_soot = max(fx_soot, 1.0 - smoothstep(0.0, R * 0.65, max(edge, 0.0)));
}
""", """
ALBEDO *= 1.0 - fx_soot * 0.94;
EMISSION *= 1.0 - fx_soot;
// Mirrored ship models reverse raster winding; keep their outside as the outside.
if (FRONT_FACING == (determinant(mat3(MODEL_MATRIX)) < 0.0)) {
	ALBEDO = vec3(0.0); METALLIC = 0.0; SPECULAR = 0.0; ROUGHNESS = 1.0;
	RIM = 0.0; CLEARCOAT = 0.0; SSS_STRENGTH = 0.0; BACKLIGHT = vec3(0.0);
	EMISSION = hull_inside(fx_hull_p, vec3(0.0), 0.0, fx_burnt_cell, 0.35, vec3(1.0), 0.0);
}
""")
	shader.code = code
	var mat := ShaderMaterial.new()
	mat.shader = shader
	for param in base.shader.get_shader_uniform_list():
		var value = base.get_shader_parameter(param["name"])
		if value != null:
			mat.set_shader_parameter(param["name"], value)
	mat.set_meta("fx_hull_source", src)
	mat.set_shader_parameter("fx_hull_frame", frame)
	mat.set_shader_parameter("fx_burnt_cell", Vector3.ONE * maxf(L * 0.05, 0.001))
	mat.set_shader_parameter("fx_mouth_count", int(mouths.get("count", 0)))
	for key in ["mouths", "axes", "tangents", "shapes", "tears"]:
		if mouths.has(key):
			mat.set_shader_parameter("fx_" + key, mouths[key])
	return mat


static func _exterior(src: Material) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = EXTERIOR
	mat.shader = shader
	if not src is BaseMaterial3D: return mat
	var m := src as BaseMaterial3D
	for pair in [["albedo", m.albedo_color], ["uv_scale", m.uv1_scale], ["uv_offset", m.uv1_offset],
		["roughness", m.roughness], ["metallic", m.metallic], ["specular", m.metallic_specular],
		["normal_scale", m.normal_scale], ["has_normal", m.normal_enabled], ["has_orm", m is ORMMaterial3D],
		["vertex_color", m.vertex_color_use_as_albedo], ["rim", m.rim if m.rim_enabled else 0.0], ["rim_tint", m.rim_tint],
		["ao_light", m.ao_light_affect], ["emission_multiply", m.emission_operator == BaseMaterial3D.EMISSION_OP_MULTIPLY]]:
		mat.set_shader_parameter("hull_" + pair[0], pair[1])
	mat.set_shader_parameter("hull_emission_color", m.emission if m.emission_enabled else Color.BLACK)
	mat.set_shader_parameter("hull_emission_energy", m.emission_energy_multiplier)
	var textures := {"color": BaseMaterial3D.TEXTURE_ALBEDO, "normal": BaseMaterial3D.TEXTURE_NORMAL,
		"orm": BaseMaterial3D.TEXTURE_ORM, "rough": BaseMaterial3D.TEXTURE_ROUGHNESS,
		"metal": BaseMaterial3D.TEXTURE_METALLIC}
	if m.ao_enabled: textures["ao"] = BaseMaterial3D.TEXTURE_AMBIENT_OCCLUSION
	if m.emission_enabled: textures["emission"] = BaseMaterial3D.TEXTURE_EMISSION
	for key in textures:
		var tex := m.get_texture(textures[key])
		if tex != null: mat.set_shader_parameter("hull_" + key, tex)
	for pair in [["rough", m.roughness_texture_channel], ["metal", m.metallic_texture_channel], ["ao", m.ao_texture_channel]]:
		var channel := Vector4.ZERO
		if int(pair[1]) < 4: channel[int(pair[1])] = 1.0
		else: channel = Vector4(0.333333, 0.333333, 0.333333, 0.0)
		mat.set_shader_parameter("hull_" + pair[0] + "_channel", channel)
	return mat


static func _inject(code: String, method: String, start: String, finish: String) -> String:
	var re := RegEx.new()
	re.compile("void\\s+" + method + "\\s*\\(\\s*\\)\\s*\\{")
	var found := re.search(code)
	if found == null:
		return code + "\nvoid " + method + "() {\n" + start + finish + "\n}\n"
	var a := found.get_end()
	var b := a
	var depth := 1
	while b < code.length() and depth > 0:
		if code[b] == "{": depth += 1
		elif code[b] == "}": depth -= 1
		b += 1
	return code.substr(0, a) + start + code.substr(a, b - a - 1) + finish + code.substr(b - 1)


static func faces_of(root: Node3D, meshes: Array) -> PackedVector3Array:
	var faces = PackedVector3Array()
	var inv = root.global_transform.affine_inverse()
	for m in meshes:
		var mi = m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf = inv * mi.global_transform
		var f = mi.mesh.get_faces()
		if xf.is_equal_approx(Transform3D.IDENTITY):
			faces.append_array(f)
		else:
			faces.append_array(xf * f)
	return faces


func analyse(root: Node3D, meshes: Array, seed_v: int) -> void:
	_rng.seed = seed_v
	var inv = root.global_transform.affine_inverse()
	var first = true
	for m in meshes:
		var mi = m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var bb = (inv * mi.global_transform) * mi.mesh.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	if first:
		box = AABB(Vector3(-6, -1.5, -1.5), Vector3(12, 3, 3))
	L = maxf(box.size.x, 0.1)
	W = maxf(box.size.z, 0.05)
	H = maxf(box.size.y, 0.05)
	c = box.get_center()
	var faces = faces_of(root, meshes)
	tri_count = faces.size() / 3
	tm = TriangleMesh.new()
	if faces.size() >= 3:
		tm.create_from_faces(faces)
	else:
		tm = null
	_samples(900)
	_find_bow()
	_find_nozzles()
	_kit_nozzles(root)
	for side in ["port", "stb", "top"]:
		mounts[side] = _mount_row(side)


func section_of(x: float) -> int:
	var u = (x - box.position.x) / L
	return SEC_ENG if u < 1.0 / 3.0 else (SEC_PROW if u > 2.0 / 3.0 else SEC_MID)


func ray(from: Vector3, dir: Vector3) -> Dictionary:
	if tm == null:
		return {}
	var h: Dictionary = tm.intersect_ray(from, dir.normalized())
	if h.is_empty():
		return {}
	var n: Vector3 = h["normal"]
	if n.dot(dir) > 0.0:
		n = -n
	return {"p": h["position"], "n": n.normalized()}


func _samples(n: int) -> void:
	var diag = box.size.length() * 1.5 + 2.0
	var tries = 0
	while sp.size() < n and tries < n * 3:
		tries += 1
		var tgt = c + Vector3((_rng.randf() - 0.5) * box.size.x * 0.9, (_rng.randf() - 0.5) * box.size.y * 0.8, (_rng.randf() - 0.5) * box.size.z * 0.8)
		var d = _rdir()
		var h = ray(tgt - d * diag, d)
		if h.is_empty():
			continue
		sp.append(h["p"])
		sn.append(h["n"])
		ssec.append(section_of((h["p"] as Vector3).x))
	if sp.is_empty():
		# no triangles: a box's faces
		for k in 60:
			var d = _rdir()
			var p = c + d * box.size * 0.5
			sp.append(p)
			sn.append(d)
			ssec.append(section_of(p.x))


func _find_bow() -> void:
	var h = ray(Vector3(box.end.x + 5.0, c.y, c.z), Vector3(-1, 0, 0))
	if h.is_empty():
		var best = -1e9
		for p in sp:
			if p.x > best:
				best = p.x
				bow = p
		if best < -1e8:
			bow = Vector3(box.end.x, c.y, c.z)
	else:
		bow = h["p"]


func _find_nozzles() -> void:
	# rays from behind on a grid over the stern cross-section; hits near the aftmost point are the stern face
	var pts: Array = []
	var minx = 1e9
	var hits: Array = []
	for iy in 12:
		for iz in 12:
			var y = box.position.y + (iy + 0.5) / 12.0 * box.size.y
			var z = box.position.z + (iz + 0.5) / 12.0 * box.size.z
			var h = ray(Vector3(box.position.x - 5.0, y, z), Vector3(1, 0, 0))
			if h.is_empty():
				continue
			hits.append(h)
			minx = minf(minx, (h["p"] as Vector3).x)
	for h in hits:
		if (h["p"] as Vector3).x <= minx + 0.08 * L:
			pts.append(h["p"])
	if pts.size() < 2:
		nozzles = [{"p": Vector3(box.position.x - 0.1, c.y, c.z), "r": clampf(0.18 * minf(W, H), 0.3, 3.0), "d": Vector3(-1, 0, 0)}]
		return
	var K = 3 if W > 0.45 * L else 2
	if pts.size() < 6:
		K = 1
	pts.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z < b.z)
	var cen: Array = []
	for k in K:
		var q: Vector3 = pts[int((k + 0.5) / K * pts.size())]
		cen.append(Vector2(q.y, q.z))
	var asg = PackedInt32Array()
	asg.resize(pts.size())
	for it in 10:
		for i in pts.size():
			var bd = 1e9
			for k in K:
				var dd = Vector2(pts[i].y, pts[i].z).distance_squared_to(cen[k])
				if dd < bd:
					bd = dd
					asg[i] = k
		for k in K:
			var m = Vector2.ZERO
			var cnt = 0
			for i in pts.size():
				if asg[i] == k:
					m += Vector2(pts[i].y, pts[i].z)
					cnt += 1
			if cnt > 0:
				cen[k] = m / cnt
	nozzles = []
	var cell = maxf(box.size.y, box.size.z) / 12.0
	for k in K:
		var mx = 1e9
		var cnt = 0
		for i in pts.size():
			if asg[i] == k:
				mx = minf(mx, pts[i].x)
				cnt += 1
		if cnt == 0:
			continue
		var r = clampf(sqrt(float(cnt)) * cell * 0.45, 0.12 * minf(W, H), 0.3 * minf(W, H))
		nozzles.append({"p": Vector3(mx - 0.05, cen[k].x, cen[k].y), "r": r, "d": Vector3(-1, 0, 0)})


# A4's kit ships carry an empty node per engine exit, hp_eng_<n> (tools/blender/a4/K1_DECISIONS.md: -Z points out of the
# bell along the plume, extras.radius is the bell radius). When a hull has them, the engines and trails come out of those
# real nozzles instead of the stern-face guess above (Ryan, r12: trails did not line up with the engines).
func _kit_nozzles(root: Node3D) -> void:
	var inv = root.global_transform.affine_inverse()
	var found: Array = []
	for nd in root.find_children("hp_eng*", "Node3D", true, false):
		var n3 = nd as Node3D
		if n3 == null or String(n3.name).begins_with("fx_"):
			continue
		var xf: Transform3D = inv * n3.global_transform
		var d: Vector3 = -(xf.basis.z)
		var k: float = d.length()
		if k < 1e-6:
			continue
		d /= k
		var r = 0.0
		var ex = n3.get_meta("extras", {})
		if ex is Dictionary and (ex as Dictionary).has("radius"):
			r = float(ex["radius"]) * k
		elif n3.has_meta("radius"):
			r = float(n3.get_meta("radius")) * k
		if r <= 0.0:
			r = clampf(0.12 * minf(W, H), 0.05, 3.0)
		found.append({"p": xf.origin, "r": r, "d": d})
	if not found.is_empty():
		nozzles = found
		nozzles_from_kit = true


func _mount_row(side: String) -> Array:
	var out: Array = []
	var dir = Vector3(0, 0, -1) if side == "port" else (Vector3(0, 0, 1) if side == "stb" else Vector3(0, -1, 0))
	for f in [0.28, 0.1, -0.08, -0.26]:
		var x = c.x + f * L
		var from: Vector3
		if side == "top":
			from = Vector3(x, box.end.y + 5.0, c.z)
		else:
			from = Vector3(x, c.y + 0.15 * H, c.z - dir.z * (W + 5.0))
		var h = ray(from, dir)
		if h.is_empty():
			h = {"p": Vector3(x, c.y if side != "top" else box.end.y, c.z - dir.z * W * 0.5), "n": -dir}
		out.append(h)
	return out


# The guns that can bear on a point (ship frame), never firing backward: a target to the side gets the broadside on
# that side, a target ahead gets the bow and the forward top mounts, a target behind gets the top turrets.
func mounts_for(target_local: Vector3, n: int) -> Array:
	var d = (target_local - c)
	d = d.normalized() if d.length() > 1e-4 else Vector3(1, 0, 0)
	var row: Array
	if d.x > 0.75:
		row = [{"p": bow, "n": Vector3(1, 0, 0)}]
		for m in mounts["top"]:
			if (m["p"] as Vector3).x > c.x:
				row.append(m)
	elif d.x < -0.6:
		row = mounts["top"]
	else:
		row = mounts["port"] if d.z >= 0.0 else mounts["stb"]
	var out: Array = []
	for i in n:
		out.append(row[i % row.size()])
	return out


# A point on the struck section, on the side facing `from` (ship frame).
# view (ship frame, optional): the direction toward the camera. F3: a hit also favours plating the camera can see, so a
# blast never goes off wholly behind the hull (d2: a torpedo on the underside of the Eclipse Tomb-ark's ring, facing
# down and away from the battle camera, was hidden by the ring itself).
func hit_point(from: Vector3, sec: int, quad: int = -1, view := Vector3.ZERO) -> Dictionary:
	var want = (from - c).normalized()
	if quad >= 0:
		want = quad_dir(quad)
	var best = -1
	var bs = -1e9
	for k in 24:
		var i = _rng.randi() % sp.size()
		var s = sn[i].dot(want) + _rng.randf() * 0.5 + maxf(sn[i].dot(view), -0.2) * 0.6
		if sec >= 0 and ssec[i] != sec:
			s -= 2.0
		if s > bs:
			bs = s
			best = i
	var p = sp[best]
	# the shot strikes the first plating on its line (F3: before, a point more than a quarter of the length behind other
	# hull was kept, so on a ring hull such as the Eclipse Tomb-ark a torpedo's whole blast went off hidden behind the rim)
	var h = ray(from, p - from)
	if not h.is_empty():
		return h
	return {"p": p, "n": sn[best]}


# The facing quad's outward direction in the ship frame: 0 prow, 1 starboard, 2 rear, 3 port.
func quad_dir(quad: int) -> Vector3:
	return [Vector3(1, 0, 0), Vector3(0, 0, stb_z), Vector3(-1, 0, 0), Vector3(0, 0, -stb_z)][posmod(quad, 4)]


func random_sample(sec: int, up_bias := 0.0) -> Dictionary:
	var best = 0
	var bs = -1e9
	for k in 16:
		var i = _rng.randi() % sp.size()
		var s = _rng.randf() + sn[i].y * up_bias
		if sec >= 0 and ssec[i] != sec:
			s -= 3.0
		if s > bs:
			bs = s
			best = i
	return {"p": sp[best], "n": sn[best]}


func shield_radii() -> Vector3:
	return Vector3(L * 0.5 * 1.1 + 0.3, H * 0.5 * 1.35 + 0.5, W * 0.5 * 1.3 + 0.5)


func _rdir() -> Vector3:
	var z = _rng.randf() * 2.0 - 1.0
	var an = _rng.randf() * TAU
	var r = sqrt(1.0 - z * z)
	return Vector3(r * cos(an), r * sin(an), z)
