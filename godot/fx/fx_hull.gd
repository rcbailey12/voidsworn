extends RefCounted
# Where effects sit on a hull, found from the hull's own triangles (in the ship root's frame: bow +X, up +Y, port +Z).
#
# The triangles go into a TriangleMesh (Godot's native BVH), so a ray against the real hull costs microseconds:
#   - visible surface samples: rays from outside at random toward the hull; each hit is a point anyone could see and
#     hit, with its outward normal and its section (eng aft third, mid, prow fore third);
#   - mounts: the outermost hull point on a side at four stations along the length (broadside guns), on the top
#     (turrets) and at the bow (lances, torpedo tubes);
#   - nozzles: the stern face, clustered into 1 to 3 engine bells;
#   - impact points: a ray from the attacker toward a sample in the struck section lands on the real surface;
#   - the attach point service (issue 370, at the end of this file): where an effect starts on the ship, from the
#     authored hard points first (docs/ship_pipeline/HARDPOINTS.md), else a surface ray, else nowhere (skipped, counted).

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
var authored := false
var seams: Array = []             # version 1, transformed into this hull analysis frame
var _rng = RandomNumberGenerator.new()
var stb_z = 1.0                    # +1: root +Z is starboard (G2), -1: +Z is port
# the attach point service (issue 370)
var code := ""                     # the hull's code (ShipView.code), for the log lines
var formation := false             # a squadron's wing of craft: no hull of its own, so no core to miss
var points := {}                   # point type -> Array of {name, p, n (+Y), f (-Z), i, and for guns slot, weapon, arc}
var core := Vector3.ZERO           # hp_core; else the triangles' centre of volume (a load error, logged); see _find_core
var core_authored := false
var attach_counts := {}            # point type -> {"hp", "ray", "centre", "skip"}: what every request was answered with
var _attach_logged := {}
var _gun_turn := {}                # per slot: the rotating first point (HARDPOINTS.md "When shots outnumber points" 2)

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
uniform float fx_weather = 0.0;
uniform mat4 fx_hull_frame;
uniform int fx_mouth_count = 0;
uniform vec4 fx_mouths[64]; // centre, radius
uniform vec4 fx_axes[64]; // outward normal, cut depth
uniform vec4 fx_tangents[64]; // tangent, slot half-length
uniform vec4 fx_shapes[64]; // round/square/slot, phases 0, 1, 2
uniform vec4 fx_tears[64]; // square rotation, phase 3, phase 4, unused
uniform vec3 fx_burnt_cell = vec3(1.0);
uniform float fx_power = 1.0;
uniform bool fx_organic = false;
uniform int fx_scorch_count = 0;
uniform vec4 fx_scorch[8]; // issue 484: a death's wound (centre, reach) on a wreck piece
uniform float fx_scorch_heat = 0.0;
varying vec3 fx_hull_p;
float fx_scorch_at(vec3 p) {
	float s = 0.0;
	for (int i = 0; i < 8; i++) {
		if (i >= fx_scorch_count) { break; }
		float R = max(fx_scorch[i].w, 0.0001);
		vec3 q = (p - fx_scorch[i].xyz) / R;
		float wob = 0.20 * sin(dot(q, vec3(7.1, 3.3, 5.9))) + 0.12 * sin(dot(q, vec3(-4.3, 13.7, 9.1))) + 0.10 * (burnt_hash(floor(q * 14.0)) - 0.5);
		s = max(s, 1.0 - smoothstep(0.2, 1.0, length(q) + wob));
	}
	return s;
}
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
# Weak cache: identical generated PBR shaders reuse the pipelines warmed by fx.
# Materials keep their own textures/uniforms. No static GPU resource survives shutdown.
static var _shader_refs := {}

# Issue 569: a see-through hull surface (the Glasswright sail membranes, GLB alpha blend, which
# Godot imports as TRANSPARENCY_ALPHA_DEPTH_PRE_PASS) carries its alpha through the damage path
# too. A spatial shader that writes ALPHA is drawn transparent, so the opaque fleet keeps the
# plain EXTERIOR code and only a see-through source gets this variant. The damage shader is
# derived from this code, so it keeps the alpha.
static func exterior_alpha_code() -> String:
	if not _ext_codes.has("exterior_alpha"):
		_ext_codes["exterior_alpha"] = EXTERIOR.replace("ALBEDO = hull_albedo.rgb * texture(hull_color, UV).rgb;",
			"ALBEDO = hull_albedo.rgb * texture(hull_color, UV).rgb;\n\tALPHA = hull_albedo.a * texture(hull_color, UV).a;")
	return _ext_codes["exterior_alpha"]

# Issue 376: the shader warm-up list is hand kept, so after it ends any shader first built later names itself here, once
# per name, with the frame and the time. A name in this list is a miss in the warm-up list. The flag is off during a
# warm-up (a bench may warm more than once), and logging is once per name so a hot path cannot flood the log.
static var late_watch := false
static var _late := {}
static var _late_lines: Array = []


static func start_late_watch() -> void:
	late_watch = true


static func pause_late_watch() -> void:
	late_watch = false


static func reset_late() -> void:
	late_watch = false
	_late.clear()
	_late_lines.clear()


static func late_shader_count() -> int:
	return _late.size()


static func late_shader_names() -> Array:
	return _late_lines.duplicate()


static func note_late(name: String) -> void:
	if not late_watch or _late.has(name):
		return
	var frame := Engine.get_process_frames()
	var ms := Time.get_ticks_usec() / 1000.0
	_late[name] = [frame, ms]
	var line := "%s frame %d %.1f ms" % [name, frame, ms]
	_late_lines.append(line)
	print("[fx] late shader: " + line)


static func shared_shader(code: String, label := "") -> Shader:
	var shader: Shader = _shader_refs[code].get_ref() if _shader_refs.has(code) else null
	if shader == null:
		shader = Shader.new()
		shader.code = code
		_shader_refs[code] = weakref(shader)
		note_late(label if label != "" else "hull shader " + str(code.hash()))
	return shader


static func clear_shader_cache() -> void:
	_shader_refs.clear()
	_dmg_code.clear()
	_uniform_names.clear()
	_ext_codes.clear()


static func damage_material(src: Material, frame: Transform3D, mouths: Dictionary, L: float, organic := false) -> ShaderMaterial:
	if src != null and src.has_meta("fx_hull_source"):
		src = src.get_meta("fx_hull_source")
	if src == null:
		src = StandardMaterial3D.new()
	var base: ShaderMaterial = src if src is ShaderMaterial else _exterior(src)
	var mat := ShaderMaterial.new()
	var dmg := _damage_code(base.shader.code)
	mat.shader = shared_shader(dmg, "damage " + str(dmg.hash()))
	for param in _uniforms_of(base.shader):
		var value = base.get_shader_parameter(param)
		if value != null:
			mat.set_shader_parameter(param, value)
	mat.set_meta("fx_hull_source", src)
	mat.set_shader_parameter("fx_hull_frame", frame)
	mat.set_shader_parameter("fx_organic", organic)
	mat.set_shader_parameter("fx_burnt_cell", Vector3.ONE * maxf(L * 0.05, 0.001))
	mat.set_shader_parameter("fx_mouth_count", int(mouths.get("count", 0)))
	for key in ["mouths", "axes", "tangents", "shapes", "tears"]:
		if mouths.has(key):
			mat.set_shader_parameter("fx_" + key, mouths[key])
	return mat


# Issue 220: the damage shader's source is a pure function of the hull shader's source, so it is worked out once per
# hull shader and kept (the regex and the character walk in _inject cost about a millisecond per surface, and every
# hull rebuild, death and death piece made one per surface on the main thread). Same code out, same shader.
static var _dmg_code := {}
static var _uniform_names := {}
static var _ext_codes := {}


static func _uniforms_of(shader: Shader) -> Array:
	var key := shader.code
	if not _uniform_names.has(key):
		var names: Array = []
		for param in shader.get_shader_uniform_list():
			names.append(param["name"])
		_uniform_names[key] = names
	return _uniform_names[key]


static func _damage_code(source: String) -> String:
	if _dmg_code.has(source):
		return _dmg_code[source]
	var code: String = source
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
ALBEDO *= (1.0 - fx_soot * 0.94) * (1.0 - fx_weather * (0.25 + 0.65 * burnt_hash(fx_hull_p * 1.7)));
EMISSION *= (1.0 - fx_soot) * clamp(fx_power, 0.0, 1.0);
if (fx_scorch_count > 0) {
	// issue 484: soot black at the wound, heat-stained bronze further out, embers that cool with the torn faces
	float fx_sc = fx_scorch_at(fx_hull_p);
	// bench round 1: a strong bronze ring read as brown cardboard on a white hull; keep the stain faint and the soot dark
	ALBEDO *= mix(vec3(1.0), vec3(0.80, 0.72, 0.70), smoothstep(0.0, 0.35, fx_sc)) * (1.0 - 0.9 * smoothstep(0.25, 0.75, fx_sc));
	ROUGHNESS = mix(ROUGHNESS, 1.0, fx_sc);
	float fx_em = smoothstep(0.65, 1.0, fx_sc) * step(0.72, burnt_hash(floor(fx_hull_p / max(fx_burnt_cell, vec3(0.001)) * 5.0)));
	EMISSION += vec3(1.0, 0.30, 0.05) * fx_em * clamp(fx_scorch_heat, 0.0, 1.0) * 2.0;
}
// Mirrored ship models reverse raster winding; keep their outside as the outside.
if (FRONT_FACING == (determinant(mat3(MODEL_MATRIX)) < 0.0)) {
	ALBEDO = vec3(0.0); METALLIC = 0.0; SPECULAR = 0.0; ROUGHNESS = 1.0;
	RIM = 0.0; CLEARCOAT = 0.0; SSS_STRENGTH = 0.0; BACKLIGHT = vec3(0.0);
	EMISSION = hull_inside(fx_hull_p, vec3(0.0), 0.0, fx_burnt_cell, 0.35, vec3(1.0), 0.0);
	vec3 section = fx_hull_p / max(fx_burnt_cell, vec3(0.001));
	float rib = 1.0 - smoothstep(0.02, 0.065, abs(fract(section.y * 0.65) - 0.5));
	float beam = 1.0 - smoothstep(0.015, 0.045, abs(fract(section.z * 0.5) - 0.5));
	vec3 structure = mix(vec3(0.008, 0.006, 0.007), vec3(0.032, 0.025, 0.021), max(rib, beam));
	if (fx_organic) {
		float fibre = pow(abs(sin(section.x * 6.0 + sin(section.y * 3.0))), 8.0);
		structure = mix(vec3(0.018, 0.003, 0.009), vec3(0.042, 0.009, 0.017), fibre);
		structure = mix(structure, vec3(0.085, 0.062, 0.033), rib * 0.7);
	}
	EMISSION = max(EMISSION, structure);
}
""")
	_dmg_code[source] = code
	return code


static func _exterior(src: Material) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	var m := src as BaseMaterial3D
	# The glTF importer gives an alphaMode BLEND material TRANSPARENCY_ALPHA_DEPTH_PRE_PASS,
	# so every transparency mode except DISABLED must carry its alpha into the damage shader.
	var see_through := m != null and m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.shader = shared_shader(exterior_alpha_code() if see_through else EXTERIOR, "exterior_alpha" if see_through else "exterior")
	if m == null: return mat
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


static func interior_material(mat: Material) -> bool:
	if mat != null and mat.has_meta("fx_hull_source"): mat = mat.get_meta("fx_hull_source")
	return mat != null and bool(mat.get_meta("fx_authored_interior", false))


func _authored(root: Node3D) -> void:
	authored = false
	seams.clear()
	var nodes: Array = [root]
	nodes.append_array(root.find_children("*", "Node3D", true, false))
	for nd in nodes:
		var extras = nd.get_meta("extras", {})
		var contract = nd.get_meta("voidsworn_destruct", extras.get("voidsworn_destruct", {}))
		if not contract is Dictionary or int(contract.get("version", 0)) != 1: continue
		var parts: Array = [nd]
		parts.append_array(nd.find_children("*", "MeshInstance3D", true, false))
		for part in parts:
			if not part is MeshInstance3D or part.mesh == null: continue
			for si in part.mesh.get_surface_count():
				var mat: Material = part.mesh.surface_get_material(si)
				if mat != null and mat.resource_name in contract.get("interior_materials", []): mat.set_meta("fx_authored_interior", true)
		var xf: Transform3D = root.global_transform.affine_inverse() * nd.global_transform
		for seam in contract.get("seams", []):
			var p: Array = seam["p"]
			var n: Array = seam["n"]
			var row := {"at": xf * Vector3(p[0], p[1], p[2]),
				"n": (xf.basis.inverse().transposed() * Vector3(n[0], n[1], n[2])).normalized()}
			if seam.has("span"):
				row["span"] = [ (xf * Vector3(seam["span"][0], 0, 0)).x, (xf * Vector3(seam["span"][1], 0, 0)).x ]
			seams.append(row)
		authored = not seams.is_empty()
		return


static func faces_of(root: Node3D, meshes: Array) -> PackedVector3Array:
	var faces = PackedVector3Array()
	var inv = root.global_transform.affine_inverse()
	for m in meshes:
		var mi = m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf = inv * mi.global_transform
		var f := PackedVector3Array()
		var has_inside := false
		for si in mi.mesh.get_surface_count():
			if interior_material(mi.mesh.surface_get_material(si)): has_inside = true
		if not has_inside:
			f = mi.mesh.get_faces() # Keep #167's native extraction unchanged for every older asset.
		else:
			for si in mi.mesh.get_surface_count():
				# The outside BVH must never land an impact on a deck inside the hull.
				if interior_material(mi.mesh.surface_get_material(si)): continue
				var arr: Array = mi.mesh.surface_get_arrays(si)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var idx = arr[Mesh.ARRAY_INDEX]
				if idx == null or idx.is_empty(): f.append_array(v)
				else:
					for i in idx: f.append(v[i])
		if xf.is_equal_approx(Transform3D.IDENTITY):
			faces.append_array(f)
		else:
			faces.append_array(xf * f)
	return faces


func analyse(root: Node3D, meshes: Array, seed_v: int) -> void:
	_rng.seed = seed_v
	_authored(root)
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
	if code == "" and root.get("code") != null:
		code = str(root.get("code"))
	_read_points(root)
	_find_core(faces)


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
		# issue 370: a station whose ray misses (a spire, a ring's hole) used to fall back to a point on the bounding box,
		# which on a hull that does not fill its box is empty space. Now it takes the seen surface sample (a ray hit)
		# nearest the station whose plating faces that side, or is left out when no plating faces that side at all.
		if h.is_empty():
			var bd := INF
			for i in sp.size():
				if sn[i].dot(-dir) < 0.25:
					continue
				var dd := absf(sp[i].x - x)
				if dd < bd:
					bd = dd
					h = {"p": sp[i], "n": sn[i]}
		if not h.is_empty():
			out.append(h)
	return out


# The guns that can bear on a point (ship frame), never firing backward: a target to the side gets the broadside on
# that side, a target ahead gets the bow and the forward top mounts, a target behind gets the top turrets.
# These are surface ray stations, the fallback for a hull with no authored gun points; effects ask guns() below.
# Returns [] when no station on that side found plating.
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
	if row.is_empty():
		return out
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
	# issue 370: the bubble is centred on the core (shield_centre); it grows by the core's offset from the box centre so
	# it still covers the whole hull (its shape is issue 371's: a skin on the hull, HARDPOINTS.md "The shield surface")
	var o: Vector3 = (core - c).abs()
	return Vector3(L * 0.5 * 1.1 + 0.3 + o.x, H * 0.5 * 1.35 + 0.5 + o.y, W * 0.5 * 1.3 + 0.5 + o.z)


func shield_centre() -> Vector3:
	return core


func _rdir() -> Vector3:
	var z = _rng.randf() * 2.0 - 1.0
	var an = _rng.randf() * TAU
	var r = sqrt(1.0 - z * z)
	return Vector3(r * cos(an), r * sin(an), z)


# ---------------------------------------------------------------- the attach point service (issue 370)
# Every effect that starts on the ship asks here where it starts (RULEBOOK 6.7, "effects start on the ship"; the contract
# is docs/ship_pipeline/HARDPOINTS.md). The order of trust, for every point type:
#   1. the authored hard point for that weapon slot, bay, core, breach anchor, braking jet or boarding hatch;
#   2. else a surface ray onto the hull's own triangles (the hit and its outward normal);
#   3. else nothing: the effect is skipped, one line is logged per hull and point type, and the skip is counted.
# No path returns a point on the bounding box or a fraction of it. The box only aims the fallback rays; what a request
# gets back is either an authored point or a point a ray found on the plating. All in the root's frame, like the rest of
# this file. A request returns {"p", "n" (away from the hull), "f" (the effect's forward), "src"}, or {} for a skip.
# The engines read their hp_eng_* points in _kit_nozzles above (they already did before this job).

const HP_RE := {
	"gun": "^hp_w(\\d+)_([A-Za-z0-9_]+)_([FTPS])_(\\d+)$",
	"engine": "^hp_eng_(\\d+)$",
	"bay": "^hp_bay_(\\d+)$",
	"breach": "^hp_breach_(\\d+)$",
	"core": "^hp_core$",
	"rcs": "^hp_rcs_(\\d+)$",
	"board": "^hp_board_(\\d+)$",
}


func _read_points(root: Node3D) -> void:
	points = {}
	for k in HP_RE:
		points[k] = []
	var inv := root.global_transform.affine_inverse()
	var res := {}
	for k in HP_RE:
		var re := RegEx.new()
		re.compile(HP_RE[k])
		res[k] = re
	for nd in root.find_children("hp_*", "Node3D", true, false):
		var n3 := nd as Node3D
		var nm := String(n3.name)
		for k in res:
			var m: RegExMatch = (res[k] as RegEx).search(nm)
			if m == null:
				continue
			var xf: Transform3D = inv * n3.global_transform
			var f: Vector3 = -xf.basis.z
			var u: Vector3 = xf.basis.y
			if f.length() < 1e-6 or u.length() < 1e-6:
				break   # a point with no axes is a broken point (HARDPOINTS.md "The frame and the node axes")
			var ex = n3.get_meta("extras", {})
			if not ex is Dictionary:
				ex = {}
			var row := {"name": nm, "p": xf.origin, "n": u.normalized(), "f": f.normalized(), "ex": ex, "i": 0}
			if k == "gun":
				row["slot"] = int(ex.get("slot", m.get_string(1)))
				row["weapon"] = str(ex.get("weapon", m.get_string(2)))
				row["arc"] = str(ex.get("arc", m.get_string(3)))
				row["i"] = int(m.get_string(4))
			elif k != "core":
				row["i"] = int(m.get_string(1))
			(points[k] as Array).append(row)
			break
	for k in points:
		(points[k] as Array).sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("slot", 0)) * 10000 + int(a["i"]) < int(b.get("slot", 0)) * 10000 + int(b["i"]))


# The core: hp_core when the hull has one. The contract gives the core no ray fallback (the death explosion has to start
# inside the hull) and calls a missing core a load error; an old hull without one still plays, from the centre of volume
# of its own triangles (never the box centre), and says so once.
func _find_core(faces: PackedVector3Array) -> void:
	var pts: Array = points.get("core", [])
	core_authored = not pts.is_empty()
	if core_authored:
		core = pts[0]["p"]
		return
	core = c
	if faces.size() < 3:
		return
	var vol := 0.0
	var acc := Vector3.ZERO
	var area := 0.0
	var aacc := Vector3.ZERO
	var i := 0
	while i + 2 < faces.size():
		var a: Vector3 = faces[i] - c
		var b: Vector3 = faces[i + 1] - c
		var d: Vector3 = faces[i + 2] - c
		var v := a.dot(b.cross(d)) / 6.0
		vol += v
		acc += (a + b + d) * (v * 0.25)
		var ar := (b - a).cross(d - a).length() * 0.5
		area += ar
		aacc += (a + b + d) * (ar / 3.0)
		i += 3
	if absf(vol) > 1e-6 * maxf(L * W * H, 1e-6):
		core = c + acc / vol
	elif area > 0.0:
		core = c + aacc / area
	if not formation:
		_attach_note("core", "load", "hp_core missing on %s (a load error, HARDPOINTS.md); the effects use the centre of volume of its triangles" % _who())


func _who() -> String:
	return code if code != "" else "this hull"


# One count per request; one log line per hull, point type and outcome (a fallback, a skip) per battle.
func _took(kind: String, how: String) -> void:
	var row: Dictionary = attach_counts.get(kind, {"hp": 0, "ray": 0, "centre": 0, "skip": 0})
	row[how] = int(row.get(how, 0)) + 1
	attach_counts[kind] = row
	if how == "ray":
		if not HP_RE.has(kind):
			_attach_note(kind, how, "%s on %s: placed on the plating (a surface sample; not a hard point type)" % [kind, _who()])
		elif not (points.get(kind, []) as Array).is_empty():
			_attach_note(kind, how, "hp_%s on %s: no authored point fits this request; using the surface ray" % [_kind_name(kind), _who()])
		else:
			_attach_note(kind, how, "hp_%s missing on %s; using the surface ray" % [_kind_name(kind), _who()])
	elif how == "skip":
		_attach_note(kind, how, "hp_%s on %s: no authored point and the surface ray missed; effect skipped" % [_kind_name(kind), _who()])


func _attach_note(kind: String, how: String, line: String) -> void:
	var key := kind + "|" + how
	if _attach_logged.has(key):
		return
	_attach_logged[key] = true
	print("[attach] " + line)


static func _kind_name(kind: String) -> String:
	return {"gun": "w", "engine": "eng"}.get(kind, kind)


# Every skip this hull made (the per-battle report, fx.gd attach_report).
func skipped() -> int:
	var n := 0
	for k in attach_counts:
		n += int(attach_counts[k].get("skip", 0))
	return n


# The plating a ray finds on the line through `through`, coming in from the `out` side: {p, n} or {}.
func surface(through: Vector3, out: Vector3) -> Dictionary:
	if out.length() < 1e-6:
		return {}
	var d := out.normalized()
	return ray(through + d * (box.size.length() + 5.0), -d)


func _hp(pt: Dictionary) -> Dictionary:
	return {"p": pt["p"], "n": pt["n"], "f": pt["f"], "src": "hp"}


# Gun muzzles for one volley: n entries, one per shot (HARDPOINTS.md "When shots outnumber points"). slot is the weapon's
# index in the ship's data.js list (the rules' fire event "weapon"; -1 when unknown), weapon its id. bow_first: a heavy
# forward weapon (lance, torpedo) with a target ahead, which on a hull with no authored point fires from the bow.
# Every entry is {} when the hull has neither a point nor plating that bears: the volley's effects are skipped.
func guns(slot: int, weapon: String, target_local: Vector3, n: int, bow_first := false) -> Array:
	n = maxi(n, 1)
	var d := target_local - core
	d = d.normalized() if d.length() > 1e-4 else Vector3(1, 0, 0)
	var pts := _gun_points(slot, weapon, d)
	var out: Array = []
	if not pts.is_empty():
		var key := "%d|%s" % [slot, weapon]
		var off: int = int(_gun_turn.get(key, posmod(hash(code + key), pts.size())))
		for i in n:
			out.append(_hp(pts[posmod(off + i, pts.size())]))
			_took("gun", "hp")
		_gun_turn[key] = off + 1
		return out
	# no authored point for this weapon: the plating found by the station rays (cast once at analyse, the same each shot)
	# (the bow is a ray hit too: _find_bow's ray from ahead, or the foremost surface sample when that ray finds a hole)
	var from_bow := bow_first and d.x > 0.5
	var row: Array = [{"p": bow, "n": Vector3(1, 0, 0)}] if from_bow else mounts_for(target_local, n)
	for i in n:
		if row.is_empty() or tm == null:
			out.append({})
			_took("gun", "skip")
		else:
			var m: Dictionary = row[i % row.size()]
			out.append({"p": m["p"], "n": m["n"], "f": d, "src": "bow" if from_bow else "ray"})
			_took("gun", "ray")
	return out


# The authored muzzles for a weapon: that slot's points for that weapon; else that weapon's points on any slot that bear
# on the target; else that slot's points (the hull was built for a sister ship whose slot holds another weapon).
func _gun_points(slot: int, weapon: String, d: Vector3) -> Array:
	var all: Array = points.get("gun", [])
	if all.is_empty():
		return []
	var same: Array = []
	var by_weapon: Array = []
	var by_slot: Array = []
	for pt in all:
		var ws: bool = weapon != "" and str(pt["weapon"]) == weapon
		if slot >= 0 and int(pt["slot"]) == slot:
			by_slot.append(pt)
			if ws:
				same.append(pt)
		if ws and _bears(pt, d):
			by_weapon.append(pt)
	if not same.is_empty():
		return same
	if not by_weapon.is_empty():
		return by_weapon
	return by_slot


static func _bears(pt: Dictionary, d: Vector3) -> bool:
	return str(pt.get("arc", "")) == "T" or maxf((pt["f"] as Vector3).dot(d), (pt["n"] as Vector3).dot(d)) > 0.2


# A wing launch: the i-th hangar mouth; else the plating facing up and toward the target, on the line through the core.
func bay(i: int, toward_local: Vector3) -> Dictionary:
	var pts: Array = points.get("bay", [])
	if not pts.is_empty():
		_took("bay", "hp")
		return _hp(pts[posmod(i, pts.size())])
	var d := toward_local - core
	d.y = 0.0
	var out := (d.normalized() + Vector3.UP).normalized() if d.length() > 1e-4 else Vector3.UP
	var h := surface(core, out)
	if h.is_empty():
		h = surface(core, Vector3.UP)   # a ring's hole or a wing's gaps: the deck seen from straight above
	if h.is_empty() and tm != null:
		var bs := -INF
		for j in sp.size():   # the seen sample (a ray hit) that faces most up and toward the craft's way
			var sc: float = sn[j].dot(out)
			if sc > bs:
				bs = sc
				h = {"p": sp[j], "n": sn[j]}
	if h.is_empty():
		_took("bay", "skip")
		return {}
	_took("bay", "ray")
	return {"p": h["p"], "n": h["n"], "f": h["n"], "src": "ray"}


# The core: launches aim at it, the shield centres on it, the ship's own pulses and jump flash start there.
func core_point() -> Dictionary:
	if core_authored:
		_took("core", "hp")
		return {"p": core, "n": Vector3.UP, "f": Vector3(1, 0, 0), "src": "hp"}
	if tm == null:
		_took("core", "skip")
		return {}
	_took("core", "centre")
	return {"p": core, "n": Vector3.UP, "f": Vector3(1, 0, 0), "src": "centre"}


# A breach anchor of a section (0 eng, 1 mid, 2 prow): the nth authored anchor there, or, with ny set (a bite out of an
# upper edge), the first anchor from the nth on whose outward normal points that far up. {} when the section has none
# left: the caller then takes a surface sample (surface_sample).
func breach_point(sec: int, nth: int, ny := Vector2(-2.0, 2.0)) -> Dictionary:
	var list: Array = []
	for pt in points.get("breach", []):
		var s := int(SEC_NAMES.get(str((pt["ex"] as Dictionary).get("section", "")), section_of((pt["p"] as Vector3).x)))
		if s == sec:
			list.append(pt)
	for j in range(nth, list.size()):
		var y: float = (list[j]["n"] as Vector3).y
		if y > ny.x and y < ny.y:
			_took("breach", "hp")
			return _hp(list[j])
	return {}


# A seen point of a section from the visible surface samples (each one a ray hit on the plating), for wounds where the
# hull has no anchor left; {} on a hull with no triangles, whose samples are box faces.
func surface_sample(sec: int, up_bias := 0.0, kind := "breach") -> Dictionary:
	if tm == null:
		_took(kind, "skip")
		return {}
	_took(kind, "ray")
	var h := random_sample(sec, up_bias)
	return {"p": h["p"], "n": h["n"], "f": h["n"], "src": "ray"}


# A braking, side or turning jet: the authored hp_rcs on that side nearest `near` (and on the same end of the hull);
# else the plating on the line through `through` seen from the `out` side; else nothing. `out` is the side the gas
# leaves from. near and through are aims only: what comes back is an authored point or a ray hit.
func jet(near: Vector3, through: Vector3, out: Vector3) -> Dictionary:
	var best := {}
	var bd := INF
	for pt in points.get("rcs", []):
		var p: Vector3 = pt["p"]
		if (p - core).dot(out) <= 0.0:
			continue
		if signf(p.x - core.x) != signf(near.x - core.x) and absf(p.x - near.x) > 0.25 * L:
			continue
		var dd := p.distance_to(near)
		if dd < bd:
			bd = dd
			best = pt
	if not best.is_empty():
		_took("rcs", "hp")
		return {"p": best["p"], "n": out.normalized(), "f": best["f"], "src": "hp"}
	var h := surface(through, out)
	if h.is_empty() and tm != null:
		# a tower's spire or a ring's hole: the seen sample (a ray hit) nearest the aim whose plating faces the gas's way
		var o2 := out.normalized()
		var bd2 := INF
		for j in sp.size():
			if sn[j].dot(o2) < 0.25:
				continue
			var dd2: float = sp[j].distance_to(near)
			if dd2 < bd2:
				bd2 = dd2
				h = {"p": sp[j], "n": sn[j]}
	if h.is_empty():
		_took("rcs", "skip")
		return {}
	_took("rcs", "ray")
	return {"p": h["p"], "n": h["n"], "f": h["n"], "src": "ray"}


# Where a boarding party leaves this hull for a target at toward_local: the authored hatch on the side facing it; else the
# side plating facing it on the line through the core; else nothing.
func board_origin(toward_local: Vector3) -> Dictionary:
	var d := toward_local - core
	d.y = 0.0
	d = d.normalized() if d.length() > 1e-4 else Vector3(0, 0, stb_z)
	var best := {}
	var bs := 0.0
	for pt in points.get("board", []):
		var s: float = ((pt["p"] as Vector3) - core).normalized().dot(d)
		if s > bs:
			bs = s
			best = pt
	if not best.is_empty():
		_took("board", "hp")
		return _hp(best)
	var h := surface(core, d)
	if h.is_empty():
		_took("board", "skip")
		return {}
	_took("board", "ray")
	return {"p": h["p"], "n": h["n"], "f": h["n"], "src": "ray"}
