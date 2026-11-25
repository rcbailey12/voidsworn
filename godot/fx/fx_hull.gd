extends RefCounted
const SHD := preload("res://fx/fx_shaders.gd")
const SKEEP := preload("res://render/shader_keep.gd")
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

const SH := preload("res://fx/fx_shaders.gd")

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
var bvh_ranges: Array = []         # The BVH's face ranges, with original geometry and paint for hit fragments.
var authored := false
var seams: Array = []             # version 1, transformed into this hull analysis frame
var machines: Array = []          # issue 600: {name, kind, box (AABB)} from the export, in this hull analysis frame
var _rng = RandomNumberGenerator.new()
var stb_z = 1.0                    # +1: root +Z is starboard (G2), -1: +Z is port
# the attach point service (issue 370)
var code := ""                     # the hull's code (ShipView.code), for the log lines
var formation := false             # a squadron's wing of craft: no hull of its own, so no core to miss
var cache_geometry := false         # FxShip opts in. Standalone analysers do not keep installed meshes alive.
var points := {}                   # point type -> Array of {name, p, n (+Y), f (-Z), i, and for guns slot, weapon, arc}
var core := Vector3.ZERO           # hp_core; else the triangles' centre of volume (a load error, logged); see _find_core
var core_authored := false
var attach_counts := {}            # point type -> {"hp", "ray", "centre", "skip"}: what every request was answered with
var _attach_logged := {}
var _gun_turn := {}                # per slot: the rotating first point (HARDPOINTS.md "When shots outnumber points" 2)

# LOAD38: keep only seed-free geometry across battles and title backdrops. Mesh references
# keep the key's resource identities alive. Bound the cache so old installed kits can age out.
const GEO_LIMIT := 32
static var _hull_geometry := {}


static func clear_static() -> void:
	_hull_geometry.clear()


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
// Issue 1777 (Ship Look V2): the faction micro-detail layer, the same object-space triplanar sum, multiply grain and
// normal mix as Godot's own detail layer on the undamaged hull (render/look.gd _detail_layer), so a first hit never pops it off
uniform bool hull_detail = false;
uniform sampler2D hull_detail_albedo : source_color, hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D hull_detail_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 hull_detail_scale = vec3(1.0);
uniform float hull_detail_sharpness = 4.0;
// Issue 1777: the V2 faction material channels (render/look.gd V2 "pbr"), zero when the hull has none (zero adds nothing)
uniform float hull_aniso = 0.0;
uniform float hull_coat = 0.0;
uniform float hull_coat_rough = 0.3;
uniform vec4 hull_back : source_color = vec4(0.0);
varying vec4 hull_color_v;
varying vec3 hull_tp_pos;
varying vec3 hull_tp_w;
vec4 hull_triplanar(sampler2D s, vec3 w, vec3 p) {
	return texture(s, p.xy) * w.z + texture(s, p.xz) * w.y + texture(s, p.zy * vec2(-1.0, 1.0)) * w.x;
}
void vertex() {
	UV = UV * hull_uv_scale.xy + hull_uv_offset.xy; hull_color_v = COLOR;
	hull_tp_w = pow(abs(NORMAL), vec3(hull_detail_sharpness));
	hull_tp_w /= max(dot(hull_tp_w, vec3(1.0)), 0.0001);
	hull_tp_pos = VERTEX * hull_detail_scale * vec3(1.0, -1.0, 1.0);
}
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
	if (hull_detail) {
		vec4 dt = hull_triplanar(hull_detail_albedo, hull_tp_w, hull_tp_pos);
		vec3 dn = hull_triplanar(hull_detail_normal, hull_tp_w, hull_tp_pos).rgb;
		ALBEDO = mix(ALBEDO, ALBEDO * dt.rgb, dt.a);
		NORMAL_MAP = mix(hull_has_normal ? NORMAL_MAP : vec3(0.5, 0.5, 1.0), dn, dt.a);
		NORMAL_MAP_DEPTH = hull_normal_scale;
	}
	if (hull_aniso > 0.0) { ANISOTROPY = hull_aniso; ANISOTROPY_FLOW = vec2(1.0, 0.0); }
	if (hull_coat > 0.0) { CLEARCOAT = hull_coat; CLEARCOAT_ROUGHNESS = hull_coat_rough; }
	BACKLIGHT = hull_back.rgb;
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
uniform float fx_flick = 1.0; // issue 1587: a wounded hull's uneven power, on top of the wear's fx_power
uniform bool fx_organic = false;
uniform int fx_scorch_count = 0;
uniform vec4 fx_scorch[8]; // issue 484: a death's wound (centre, reach) on a wreck piece
uniform float fx_scorch_heat = 0.0;
uniform vec3 fx_scorch_col = vec3(1.0, 0.30, 0.05);   // R367: the scorch heat in the faction's death colour
uniform int fx_v2 = -1;   // R416 Wounds V2: the faction's wound kind (0 Sunward .. 5 Eclipse); -1 off
uniform float fx_v2_soot = 1.0;
uniform vec3 fx_v2_lift = vec3(0.3);
uniform vec3 fx_v2_accent = vec3(1.0, 0.5, 0.15);
varying vec3 fx_hull_p;
varying vec3 fx_hull_n;
float fx_scorch_at(vec3 p) {
	float s = 0.0;
	for (int i = 0; i < 8; i++) {
		if (i >= fx_scorch_count) { break; }
		float R = max(fx_scorch[i].w, 0.0001);
		vec3 d = p - fx_scorch[i].xyz;
		// The three wobble terms can move the stain out by at most 0.37 R.
		if (dot(d, d) >= (1.38 * R) * (1.38 * R)) { continue; }
		vec3 q = d / R;
		float wob = 0.20 * sin(dot(q, vec3(7.1, 3.3, 5.9))) + 0.12 * sin(dot(q, vec3(-4.3, 13.7, 9.1))) + 0.10 * (burnt_hash(floor(q * 14.0)) - 0.5);
		s = max(s, 1.0 - smoothstep(0.2, 1.0, length(q) + wob));
	}
	return s;
}
float fx_mouth_edge(int i, float x, float y, float R) {
	vec4 s = fx_shapes[i];
	if (s.x > 3.5) {
		// R416: a straight-edged glass pane (fx_tears.w sides, turned by fx_tears.x), as fx_breach Ent.edge
		float seg = 6.2831853 / max(fx_tears[i].w, 3.0);
		float a = length(vec2(x, y)) > 0.00001 ? atan(y, x) : 0.0;
		float a2 = mod(a - fx_tears[i].x, seg) - seg * 0.5;
		return length(vec2(x, y)) * cos(a2) - R * cos(seg * 0.5);
	}
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
static var _shader_refs := {}   # not GPU: weak refs only, nothing is kept alive

# Issue 569: a see-through hull surface (the Glasswright sail membranes, GLB alpha blend, which
# Godot imports as TRANSPARENCY_ALPHA_DEPTH_PRE_PASS) carries its alpha through the damage path
# too. A spatial shader that writes ALPHA is drawn transparent, so the opaque fleet keeps the
# plain EXTERIOR code and only a see-through source gets this variant. The damage shader is
# derived from this code, so it keeps the alpha.
static func exterior_alpha_code() -> String:
	if not _ext_codes.has("exterior_alpha"):
		_ext_codes["exterior_alpha"] = SH.patch(EXTERIOR, "ALBEDO = hull_albedo.rgb * texture(hull_color, UV).rgb;",
			"ALBEDO = hull_albedo.rgb * texture(hull_color, UV).rgb;\n\tALPHA = hull_albedo.a * texture(hull_color, UV).a;")
	return _ext_codes["exterior_alpha"]

# Issue 376: the shader warm-up list is hand kept, so after it ends any shader first built later names itself here, once
# per name, with the frame and the time. A name in this list is a miss in the warm-up list. The flag is off during a
# warm-up (a bench may warm more than once), and logging is once per name so a hot path cannot flood the log.
static var late_watch := false
static var late_stacks := false   # issue 1434: bench/load_1434.gd turns it on, so each late shader names its caller
static var _late := {}   # not GPU: shader names -> frame and time
static var _late_lines: Array = []   # not GPU: log lines


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
	if late_stacks:
		# issue 1434: name the caller (a debug build has the stack; an export prints nothing more)
		var at := PackedStringArray()
		for fr in get_stack().slice(1, 7):
			at.append("%s:%d %s" % [str(fr["source"]).get_file(), int(fr["line"]), str(fr["function"])])
		if not at.is_empty():
			line += " from " + " < ".join(at)
	_late_lines.append(line)
	print("[fx] late shader: " + line)


static func shared_shader(code: String, label := "") -> Shader:
	var shader: Shader = _shader_refs[code].get_ref() if _shader_refs.has(code) else null
	if shader == null and SKEEP.has(code):
		# issue 1434: kept for the session (render/shader_keep.gd), so a later battle or the title does not compile it again
		shader = SKEEP.get_kept(code)
		_shader_refs[code] = weakref(shader)
	if shader == null:
		shader = Shader.new()
		shader.code = code
		_shader_refs[code] = weakref(shader)
		SKEEP.keep(code, shader)
		note_late(label if label != "" else "hull shader " + str(code.hash()))
	return shader


static func clear_shader_cache() -> void:
	_shader_refs.clear()
	_dmg_code.clear()
	_uniform_names.clear()
	_ext_codes.clear()


static func damage_material(src: Material, frame: Transform3D, mouths: Dictionary, L: float, organic := false, fixed_wreck := false) -> ShaderMaterial:
	if src != null and src.has_meta("fx_hull_source"):
		src = src.get_meta("fx_hull_source")
	if src == null:
		src = StandardMaterial3D.new()
	var base: ShaderMaterial = src if src is ShaderMaterial else _exterior(src)
	var mat := ShaderMaterial.new()
	# The fog policy has already marked the painted source by the time this
	# adapter is drawn. Compile with that mode on the first assignment.
	var dmg := _damage_code(base.shader.code, src is BaseMaterial3D and src.disable_fog, fixed_wreck)
	mat.shader = shared_shader(dmg, "damage " + str(dmg.hash()))
	for param in _uniforms_of(base.shader):
		var value = base.get_shader_parameter(param)
		if value != null:
			mat.set_shader_parameter(param, value)
	mat.set_meta("fx_hull_source", src)
	mat.set_shader_parameter("fx_organic", organic)
	mat.set_shader_parameter("fx_burnt_cell", Vector3.ONE * maxf(L * 0.05, 0.001))
	if not fixed_wreck:
		set_damage_pose(mat, frame, mouths)
	return mat


# The same hull substance drives contact effects and live wear (R402).
static func target_substance(faction: String) -> String:
	match faction:
		"ithar": return "glass"
		"chorus": return "bio"
		"deathless": return "obsidian"
	return "metal"


# Every hull's lights dim as it wears. Metal surfaces also darken and collect soot at their hits.
const WEAR_WEATHER := 0.45   # fx_weather at full wear
const WEAR_POWER := 0.65     # the share of the hull's light lost at full wear
# fx_power is the wear's steady value (and the death fade's); a hit's brownout rides on fx_flick (fx_ship hit_power).
static func set_power(mat: ShaderMaterial, wear: float) -> void:
	mat.set_shader_parameter("fx_power", 1.0 - WEAR_POWER * wear)


static func set_wear(mat: ShaderMaterial, wear: float, patches: Array) -> void:
	mat.set_shader_parameter("fx_weather", wear * WEAR_WEATHER if mat.get_meta("fx_metal_wear", true) else 0.0)
	set_power(mat, wear)
	var n := mini(patches.size(), 8)
	mat.set_shader_parameter("fx_scorch_count", n)
	if n > 0:
		var arr: Array = patches.slice(0, 8)
		while arr.size() < 8:
			arr.append(Vector4.ZERO)
		mat.set_shader_parameter("fx_scorch", arr)
	mat.set_shader_parameter("fx_scorch_heat", 0.0)


# R416 (issue 1741): the faction's Wounds V2 profile on a hull damage surface; an empty profile turns it off.
static func set_v2(mat: ShaderMaterial, wv: Dictionary) -> void:
	if wv.is_empty():
		mat.set_shader_parameter("fx_v2", -1)
		mat.set_shader_parameter("fx_v2_soot", 1.0)
		return
	mat.set_shader_parameter("fx_v2", int(wv.get("kind", 0)))
	mat.set_shader_parameter("fx_v2_soot", float(wv.get("soot_weight", 1.0)))
	for k in [["interior_lift", "fx_v2_lift"], ["interior_accent", "fx_v2_accent"]]:
		var v = wv.get(k[0])
		if v is Array and (v as Array).size() >= 3:
			mat.set_shader_parameter(k[1], Vector3(float(v[0]), float(v[1]), float(v[2])))


static func set_damage_pose(mat: ShaderMaterial, frame: Transform3D, mouths: Dictionary) -> void:
	mat.set_shader_parameter("fx_hull_frame", frame)
	mat.set_shader_parameter("fx_mouth_count", int(mouths.get("count", 0)))
	for key in ["mouths", "axes", "tangents", "shapes", "tears"]:
		if mouths.has(key):
			mat.set_shader_parameter("fx_" + key, mouths[key])


# Issue 220: the damage shader's source is a pure function of the hull shader's source, so it is worked out once per
# hull shader and kept (the regex and the character walk in _inject cost about a millisecond per surface, and every
# hull rebuild, death and death piece made one per surface on the main thread). Same code out, same shader.
static var _dmg_code := {}   # not GPU: shader source text
static var _uniform_names := {}   # not GPU: uniform name lists
static var _ext_codes := {}   # not GPU: shader source text


static func _uniforms_of(shader: Shader) -> Array:
	var key := shader.code
	if not _uniform_names.has(key):
		var names: Array = []
		for param in shader.get_shader_uniform_list():
			names.append(param["name"])
		_uniform_names[key] = names
	return _uniform_names[key]


static func _damage_code(source: String, disable_fog := false, fixed_wreck := false) -> String:
	var key := [source, disable_fog, fixed_wreck]
	if _dmg_code.has(key):
		return _dmg_code[key]
	var code: String = source
	var cull := RegEx.new()
	cull.compile("cull_(back|front|disabled)")
	code = cull.sub(code, "cull_disabled", true)
	if not code.contains("cull_disabled"):
		code = code.replace("shader_type spatial;", "shader_type spatial;\nrender_mode cull_disabled;")
	code = code.replace("shader_type spatial;", "shader_type spatial;\n" + BURNT + DAMAGE_UNIFORMS)
	# Board chunks are already cut and never get mouths. Keeping the discard in their shader
	# makes Forward+ compile material-specific depth and shadow shaders for a path that cannot run.
	var hull_pos := "VERTEX" if fixed_wreck else "(fx_hull_frame * vec4(VERTEX, 1.0)).xyz"
	code = _inject(code, "vertex", "", "\nfx_hull_p = %s;\nfx_hull_n = mat3(fx_hull_frame) * NORMAL;\n" % hull_pos)
	var soot := """
float fx_soot = 0.0;
float fx_near = 0.0;   // R416: how close this pixel is to an open mouth (the V2 back-face look stays at the wounds)
// cull_disabled flips back-facing normals in the renderer, including mirrored exteriors.
bool fx_mirrored = determinant(mat3(MODEL_MATRIX)) < 0.0;
bool fx_back_face = FRONT_FACING == fx_mirrored;
if (fx_mirrored) { NORMAL = -NORMAL; }
"""
	if not fixed_wreck:
		soot += """for (int i = 0; i < 64; i++) {
	if (i >= fx_mouth_count) { break; }
	vec3 d = fx_hull_p - fx_mouths[i].xyz;
	float R = max(fx_mouths[i].w, 0.0001);
	float d2 = dot(d, d);
	if (fx_v2 >= 0 && fx_back_face && d2 < (3.0 * R) * (3.0 * R)) {
		fx_near = max(fx_near, 1.0 - smoothstep(R * 1.2, R * 3.0, sqrt(d2)));
	}
	float h = dot(d, fx_axes[i].xyz);
	if (h < -fx_axes[i].w || h > R * 0.8) { continue; }
	float x = dot(d, fx_tangents[i].xyz);
	float y = dot(d, cross(fx_axes[i].xyz, fx_tangents[i].xyz));
	float plane2 = x * x + y * y;
	// Even the square corners are within sqrt(2) * (1.10 + 0.65) R, including the soot rim.
	// A slot can extend its half-length beyond that. Far plating needs none of the cut's trig.
	float reach = 2.5 * R + (fx_shapes[i].x == 2.0 ? fx_tangents[i].w : 0.0);
	if (plane2 >= reach * reach) { continue; }
	// R416 4.2: only plating facing along the cut (or straight against it: the inner liner) is cut, never a wall at
	// right angles or a face standing above the hole. The facing test holds only out past 0.6 R from the centre, so the
	// side faces of raised plates inside the mouth are cut with it, not left as strips across it (Fable review M3)
	vec3 plane_d = d - fx_axes[i].xyz * h;
	if (fx_v2 >= 0 && (h > R * 0.45 || (dot(plane_d, plane_d) > (R * 0.6) * (R * 0.6) && abs(dot(normalize(fx_hull_n), fx_axes[i].xyz)) < 0.25))) { continue; }
	float edge = fx_mouth_edge(i, x, y, R);
	if (edge < -R * 0.035) { discard; }
	fx_soot = max(fx_soot, 1.0 - smoothstep(0.0, R * 0.65, max(edge, 0.0)));
}
"""
	var inside := """
float fx_surface_tone = 1.0 - fx_soot * 0.94 * clamp(fx_v2_soot, 0.0, 1.0);
if (fx_weather > 0.0 && fx_v2 != 1) { fx_surface_tone *= 1.0 - fx_weather * (0.25 + 0.65 * burnt_hash(fx_hull_p * 1.7)); }
ALBEDO *= fx_surface_tone;
EMISSION *= (1.0 - fx_soot) * clamp(fx_power, 0.0, 1.0) * fx_flick;
if (fx_v2 == 4 || fx_v2 == 5) {
	// Colour stays on the cut lip. A broad sheen makes a pearl opening read flat and obsidian read lilac.
	EMISSION += fx_v2_accent * smoothstep(0.83, 1.0, fx_soot) * (fx_v2 == 5 ? 0.12 : 0.05);
}
if (fx_scorch_count > 0) {
	// issue 484: soot black at the wound, heat-stained bronze further out, embers that cool with the torn faces
	float fx_sc = fx_scorch_at(fx_hull_p);
	// bench round 1: a strong bronze ring read as brown cardboard on a white hull; keep the stain faint and the soot dark
	// R416 / R420 (Wounds V2): the stain and soot follow the faction's soot weight (none on Chorus, Glasswrights, Eclipse)
	float fx_sw = clamp(fx_v2_soot, 0.0, 1.0);
	ALBEDO *= mix(vec3(1.0), vec3(0.80, 0.72, 0.70), smoothstep(0.0, 0.35, fx_sc) * fx_sw) * (1.0 - 0.9 * smoothstep(0.25, 0.75, fx_sc) * fx_sw);
	ROUGHNESS = mix(ROUGHNESS, 1.0, fx_sc * fx_sw);
	float fx_em = smoothstep(0.65, 1.0, fx_sc) * step(0.72, burnt_hash(floor(fx_hull_p / max(fx_burnt_cell, vec3(0.001)) * 5.0)));
	// issue 1741 (JOINT_B): a quarter of tiny cells lit read as glitter at camera 26 and 170; with V2, embers stay only
	// on steel (Sunward, Hullbreakers), one cell in twenty, each cell two and a half times bigger
	if (fx_v2 >= 0) { fx_em = (fx_v2 == 0 || fx_v2 == 2) ? smoothstep(0.65, 1.0, fx_sc) * step(0.95, burnt_hash(floor(fx_hull_p / max(fx_burnt_cell, vec3(0.001)) * 2.0))) * 0.6 : 0.0; }
	EMISSION += fx_scorch_col * fx_em * clamp(fx_scorch_heat, 0.0, 1.0) * 2.0;
}
// Mirrored ship models reverse raster winding; keep their outside as the outside.
if (fx_back_face) {
	ALBEDO = vec3(0.0); METALLIC = 0.0; SPECULAR = 0.0; ROUGHNESS = 1.0;
	RIM = 0.0; CLEARCOAT = 0.0; SSS_STRENGTH = 0.0; BACKLIGHT = vec3(0.0);
	// R416 (Nov 24, Ryan's yes): the orange ember speckle on the back of the plating stays on steel only (Sunward,
	// Hullbreakers); every other faction's backface is its own matter, never orange
	EMISSION = hull_inside(fx_hull_p, vec3(0.0), 0.0, fx_burnt_cell, (fx_v2 == 0 || fx_v2 == 2) ? 0.35 : 0.0, vec3(1.0), 0.0);
	vec3 section = fx_hull_p / max(fx_burnt_cell, vec3(0.001));
	float rib = 1.0 - smoothstep(0.02, 0.065, abs(fract(section.y * 0.65) - 0.5));
	float beam = 1.0 - smoothstep(0.015, 0.045, abs(fract(section.z * 0.5) - 0.5));
	vec3 structure = mix(vec3(0.008, 0.006, 0.007), vec3(0.032, 0.025, 0.021), max(rib, beam));
	if (fx_organic) {
		// R416: umber, never magenta (the old magenta flesh is retired, Nov 24)
		float fibre = pow(abs(sin(section.x * 6.0 + sin(section.y * 3.0))), 8.0);
		structure = mix(vec3(0.016, 0.008, 0.004), vec3(0.036, 0.016, 0.008), fibre);
		structure = mix(structure, vec3(0.085, 0.062, 0.033), rib * 0.7);
	}
	EMISSION = max(EMISSION, structure);
	if (fx_v2 >= 0 && fx_near > 0.0) {
		// R416: the back of the plating seen through a cut is the faction's own lit matter, never a flat black (only
		// round the wounds: a single-sided fin or sail seen from behind keeps its old look)
		ALBEDO = mix(ALBEDO, fx_v2_lift * (0.45 + 0.55 * max(rib, beam)), fx_near);
		ROUGHNESS = mix(ROUGHNESS, fx_v2 == 4 ? 0.1 : (fx_v2 == 3 ? 0.25 : 0.6), fx_near);
		METALLIC = mix(METALLIC, (fx_v2 <= 2 || fx_v2 == 5) ? 0.4 : 0.0, fx_near);   // mixed, so no ring at 3 R (M3)
		SPECULAR = 0.4 * fx_near;
		EMISSION = mix(EMISSION, fx_v2_lift * 0.03 + fx_v2_accent * (fx_v2 == 4 ? 0.05 : 0.01), fx_near);
	}
}
"""
	# A write of zero still flags SSS in the renderer, multiplying the PSOs for every
	# already-instanced mesh. Only zero the back face when the source actually writes SSS.
	if not source.contains("SSS_STRENGTH"):
		inside = inside.replace(" SSS_STRENGTH = 0.0;", "")
	code = _inject(code, "fragment", soot, inside)
	if disable_fog and not code.contains("fog_disabled"):
		code = code.replace("shader_type spatial;", "shader_type spatial;\nrender_mode fog_disabled;")
	_dmg_code[key] = code
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
	if m.detail_enabled and m.uv2_triplanar and m.detail_albedo != null and m.detail_normal != null:   # issue 1777
		mat.set_shader_parameter("hull_detail", true)
		mat.set_shader_parameter("hull_detail_albedo", m.detail_albedo)
		mat.set_shader_parameter("hull_detail_normal", m.detail_normal)
		mat.set_shader_parameter("hull_detail_scale", m.uv2_scale)
		mat.set_shader_parameter("hull_detail_sharpness", m.uv2_triplanar_sharpness)
	if m.anisotropy_enabled: mat.set_shader_parameter("hull_aniso", m.anisotropy)
	if m.clearcoat_enabled:
		mat.set_shader_parameter("hull_coat", m.clearcoat)
		mat.set_shader_parameter("hull_coat_rough", m.clearcoat_roughness)
	# subsurface scattering is not mirrored (small at 0.25, and the burnt pass sets its own); a wounded Chorus keeps its
	# backlight and coat
	if m.backlight_enabled: mat.set_shader_parameter("hull_back", m.backlight)
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


# R416 5.3 (issue 1741, Wounds V2): the shared interior shader (fx_shaders INTERIOR) for one authored inside surface,
# with the source's own colour and glow kept underneath. It keeps the source as fx_hull_source, so interior_material()
# still knows it for an inside surface. wreck 1: a dead hull's piece (every surface open, settled into the wreck look).
static func interior_material_v2(src: Material, frame: Transform3D, mouths: Dictionary, wv: Dictionary, L: float, wreck := 0.0) -> ShaderMaterial:
	if src != null and src.has_meta("fx_hull_source"):
		src = src.get_meta("fx_hull_source")
	var m := ShaderMaterial.new()
	m.shader = shared_shader(SHD.INTERIOR, "interior v2")
	var rl := interior_role(src)
	m.set_shader_parameter("role", int(rl[0]))
	m.set_shader_parameter("trusted", bool(rl[1]))
	if src is BaseMaterial3D:
		var b := src as BaseMaterial3D
		m.set_shader_parameter("base_albedo", b.albedo_color)
		if b.albedo_texture != null:
			m.set_shader_parameter("base_tex", b.albedo_texture)
		m.set_shader_parameter("base_rough", b.roughness)
		m.set_shader_parameter("base_metal", b.metallic)
		# Fable review B3: the trim's own maps are read, not dropped (glTF packs occlusion, roughness, metal in one map)
		if b.normal_enabled and b.normal_texture != null:
			m.set_shader_parameter("base_normal", b.normal_texture)
			m.set_shader_parameter("has_normal", true)
		var orm: Texture2D = b.roughness_texture if b.roughness_texture != null else b.metallic_texture
		if orm != null:
			m.set_shader_parameter("base_orm", orm)
			m.set_shader_parameter("has_orm", true)
		if b.emission_enabled:
			m.set_shader_parameter("base_emission", b.emission)
			m.set_shader_parameter("base_emission_energy", b.emission_energy_multiplier)
			if b.emission_texture != null:
				m.set_shader_parameter("base_em_tex", b.emission_texture)
	m.set_shader_parameter("tri_scale", 1.0 / maxf(L * 0.012, 1e-3))
	m.set_shader_parameter("wound_v2", int(wv.get("kind", 0)))
	for key in ["scorch_col", "rim_metal", "interior_lift", "interior_accent"]:
		var v = wv.get(key)
		if v is Array and (v as Array).size() >= 3:
			m.set_shader_parameter("v2_" + key, Vector3(float(v[0]), float(v[1]), float(v[2])))
	m.set_shader_parameter("v2_rough", float(wv.get("interior_rough", 0.6)))
	m.set_shader_parameter("v2_soot", float(wv.get("soot_weight", 1.0)))
	m.set_shader_parameter("v2_wreck_soot", float(wv.get("wreck_soot", 0.3)))
	m.set_shader_parameter("v2_wall_max", float(wv.get("wall_max", 0.11)))
	m.set_shader_parameter("fx_wreck", wreck)
	if wreck > 0.0:
		mouths = {"count": -1}
	set_interior_pose(m, frame, mouths)
	if src != null:
		m.set_meta("fx_hull_source", src)
	return m


# Fable review B3: an inside surface's role for the interior shader, [role, trusted]: 0 wall (deck, frame, machinery),
# 1 bone, 2 core, 3 glass, 4 organ or gland. A surface from the Interior Kit V2 (PR 1763) names its role in the glTF
# material extras (interior_role), and its colour came from the faction role table, so it is trusted and kept; an older
# surface is read from its name and light, and only its texture's light and dark are kept. Godot does not import glTF
# material extras, so _authored copies the role from the hull contract's interior_roles {material name: role} as meta.
const INTERIOR_ROLES := {"bone": 1, "core": 2, "glass": 3, "glass_strut": 3, "organ": 4, "gland": 4}


static func interior_role(src: Material) -> Array:
	if src == null:
		return [0, false]
	var ex = src.get_meta("extras", {})
	var named := str(src.get_meta("interior_role", ex.get("interior_role", "") if ex is Dictionary else ""))
	if named != "":
		return [int(INTERIOR_ROLES.get(named, 0)), true]
	var nm := src.resource_name.to_lower()
	if nm.contains("bone") or nm.contains("rib"):
		return [1, false]
	if nm.contains("core") or nm.contains("reactor"):
		return [2, false]
	if src is BaseMaterial3D:
		var b := src as BaseMaterial3D
		var e := b.emission * b.emission_energy_multiplier
		if b.emission_enabled and maxf(e.r, maxf(e.g, e.b)) >= 1.0:
			return [2, false]
	if nm.contains("vat") or nm.contains("organ") or nm.contains("gland"):
		return [4, false]
	if nm.contains("glass") or nm.contains("gw_in"):
		return [3, false]
	return [0, false]


static func set_interior_pose(m: ShaderMaterial, frame: Transform3D, mouths: Dictionary) -> void:
	m.set_shader_parameter("fx_hull_frame", frame)
	m.set_shader_parameter("fx_mouth_count", int(mouths.get("count", 0)))
	for key in ["mouths", "axes"]:
		if mouths.has(key):
			m.set_shader_parameter("fx_" + key, mouths[key])


func _authored(root: Node3D) -> void:
	authored = false
	seams.clear()
	machines.clear()
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
				if mat != null and mat.resource_name in contract.get("interior_materials", []):
					mat.set_meta("fx_authored_interior", true)
					# Interior Kit V2 (PR 1763): Godot drops glTF material extras, so each inside material's role
					# (wall, deck, frame, machinery, bone, core, glass, organ, gland) rides in the hull contract
					var roles = contract.get("interior_roles", {})
					if roles is Dictionary and roles.has(mat.resource_name): mat.set_meta("interior_role", str(roles[mat.resource_name]))
		var xf: Transform3D = root.global_transform.affine_inverse() * nd.global_transform
		for seam in contract.get("seams", []):
			var p: Array = seam["p"]
			var n: Array = seam["n"]
			var row := {"at": xf * Vector3(p[0], p[1], p[2]),
				"n": (xf.basis.inverse().transposed() * Vector3(n[0], n[1], n[2])).normalized()}
			if seam.has("span"):
				row["span"] = [ (xf * Vector3(seam["span"][0], 0, 0)).x, (xf * Vector3(seam["span"][1], 0, 0)).x ]
			# issue 600 (R226): a transverse seam's plan path, [x, z] points in the GLB ship frame; the death cut follows it
			var path = seam.get("path", [])
			if path is Array and path.size() >= 2 and not seam.has("span"):
				var pp := PackedVector2Array()
				for q in path:
					var w: Vector3 = xf * Vector3(float(q[0]), 0.0, float(q[1]))
					pp.append(Vector2(w.x, w.z))
				if pp[pp.size() - 1].y < pp[0].y: pp.reverse()   # always from -z to +z
				row["path"] = pp
			seams.append(row)
		# issue 600 (R226, RULEBOOK 5.17): each machine's box (gun, turret ring, engine, claw, mast...), so the death rides it
		# whole with one piece. Boxes go through the node transform as eight corners.
		for m in contract.get("machines", []):
			var lo: Array = m.get("lo", [])
			var hi: Array = m.get("hi", [])
			if lo.size() != 3 or hi.size() != 3: continue
			var bb := AABB()
			for k in 8:
				var p := Vector3(float(hi[0] if k & 1 else lo[0]), float(hi[1] if k & 2 else lo[1]), float(hi[2] if k & 4 else lo[2]))
				bb = AABB(xf * p, Vector3.ZERO) if k == 0 else bb.expand(xf * p)
			machines.append({"name": str(m.get("name", "")), "kind": str(m.get("kind", "")), "box": bb})
		authored = not seams.is_empty()
		return


static func faces_of(root: Node3D, meshes: Array, ranges: Variant = null, frames := {}) -> PackedVector3Array:
	var faces = PackedVector3Array()
	var inv = root.global_transform.affine_inverse()
	for m in meshes:
		if not is_instance_valid(m): continue
		var mi = m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var mesh: Mesh = mi.mesh
		var array_mesh := mesh as ArrayMesh
		var record_ranges := ranges != null and array_mesh != null
		var xf: Transform3D = frames.get(mi, inv * mi.global_transform)
		var identity := xf.is_equal_approx(Transform3D.IDENTITY)
		var f := PackedVector3Array()
		var has_inside := false
		for si in mesh.get_surface_count():
			if interior_material(mesh.surface_get_material(si)):
				has_inside = true
				break
		if not has_inside:
			f = mesh.get_faces() # Keep #167's native extraction for older assets.
		if has_inside or record_ranges:
			var start: int = faces.size() / 3
			var to_part := xf.affine_inverse() if record_ranges and not identity else Transform3D.IDENTITY
			for si in mesh.get_surface_count():
				var mat := mesh.surface_get_material(si)
				var primitive := array_mesh.surface_get_primitive_type(si) if array_mesh != null else Mesh.PRIMITIVE_TRIANGLES
				var strip := primitive == Mesh.PRIMITIVE_TRIANGLE_STRIP
				if interior_material(mat) or (primitive != Mesh.PRIMITIVE_TRIANGLES and not strip):
					continue
				var corners: int
				if has_inside:
					# The outside BVH never lands an impact on a deck inside the hull.
					var arr := mesh.surface_get_arrays(si)
					var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
					var idx = arr[Mesh.ARRAY_INDEX]
					var indexed: bool = idx != null and not idx.is_empty()
					corners = idx.size() if indexed else v.size()
					if strip:
						for tri in maxi(corners - 2, 0):
							var ids := face_corners(tri, true)
							for i in [ids.x, ids.y, ids.z]:
								f.append(v[idx[i] if indexed else i])
					elif indexed:
						for i in idx:
							f.append(v[i])
					else:
						f.append_array(v)
				else:
					# Native extraction visits triangles and strips in surface order.
					var indices := array_mesh.surface_get_array_index_len(si)
					corners = indices if indices > 0 else array_mesh.surface_get_array_len(si)
				var count: int = maxi(corners - 2, 0) if strip else corners / 3
				if record_ranges and count > 0:
					var paint := mi.get_active_material(si) as BaseMaterial3D
					if paint == null:
						paint = mat as BaseMaterial3D
					ranges.append({"mi": mi, "surface": si, "mesh": array_mesh, "start": start, "count": count,
						"to_part": to_part, "paint": paint, "strip": strip})
				start += count
		if identity:
			faces.append_array(f)
		else:
			faces.append_array(xf * f)
	return faces


# The positions in the source vertex or index array, in the order used by Mesh.get_faces().
static func face_corners(triangle: int, strip: bool) -> Vector3i:
	var first := triangle if strip else triangle * 3
	if strip and (triangle & 1) != 0:
		return Vector3i(first, first + 2, first + 1)
	return Vector3i(first, first + 1, first + 2)


func analyse(root: Node3D, meshes: Array, seed_v: int) -> void:
	_rng.seed = seed_v
	if code == "" and root.get("code") != null:
		code = str(root.get("code"))
	_authored(root)
	var inv = root.global_transform.affine_inverse()
	var first = true
	for m in meshes:
		if not is_instance_valid(m): continue
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
	bvh_ranges.clear()
	var geo := _geometry(root, meshes)
	var faces: PackedVector3Array
	if not geo.is_empty():
		faces = geo["faces"]
		tm = geo["tm"]
		for r in geo["ranges"]:
			var mi := meshes[int(r["mi_index"])] as MeshInstance3D
			var e: Dictionary = r.duplicate()
			e.erase("mi_index")
			e["mi"] = mi
			var paint := mi.get_active_material(int(r["surface"])) as BaseMaterial3D
			e["paint"] = paint if paint != null else (r["mesh"] as Mesh).surface_get_material(int(r["surface"])) as BaseMaterial3D
			bvh_ranges.append(e)
	else:
		faces = faces_of(root, meshes, bvh_ranges)
		tm = TriangleMesh.new()
		if faces.size() >= 3:
			tm.create_from_faces(faces)
		else:
			tm = null
	tri_count = faces.size() / 3
	_samples(900)
	_find_bow()
	if geo.has("nozzles"):
		nozzles = (geo["nozzles"] as Array).duplicate(true)
	else:
		_find_nozzles()
		if not geo.is_empty():
			geo["nozzles"] = nozzles.duplicate(true)
	_kit_nozzles(root)
	for side in ["port", "stb", "top"]:
		mounts[side] = _mount_row(side)
	_read_turrets(root)
	_read_doors(root)
	_read_points(root)
	_find_core(faces, geo)
	if geo.has("turrets") and (geo["turrets"] as Array).size() == turrets.size():
		for k in turrets.size():
			(turrets[k] as Dictionary).merge((geo["turrets"][k] as Dictionary).duplicate(true), true)
	else:
		_turret_clearance(root, meshes)
		if not geo.is_empty():
			var reach: Array = []
			for t in turrets:
				reach.append({"full": t.get("full"), "ymin": t.get("ymin"), "ymax": t.get("ymax"), "blocked": t.get("blocked", [])})
			geo["turrets"] = reach


# The shared geometry entry for one hull pose: its triangles, the hit BVH and the per-surface ranges (meshes by index).
static func build_geo(root: Node3D, meshes: Array) -> Dictionary:
	var ranges: Array = []
	var faces := faces_of(root, meshes, ranges)
	var tm2: TriangleMesh = TriangleMesh.new()
	if faces.size() >= 3:
		tm2.create_from_faces(faces)
	else:
		tm2 = null
	var keep: Array = []
	for r in ranges:
		var e: Dictionary = r.duplicate()
		e["mi_index"] = meshes.find(r["mi"])
		e.erase("mi")
		e.erase("paint")
		keep.append(e)
	return {"faces": faces, "tm": tm2, "ranges": keep}


# Issue 1434: the sliced load builds the BVH in a separate frame from seeded analysis.
func prime(root: Node3D, meshes: Array) -> bool:
	var key := _geo_key(root, meshes)
	if key.is_empty() or _hull_geometry.has(key):
		return false
	_authored(root)   # mark interior faces before building the outside BVH
	_geometry(root, meshes)
	return true


func _geometry(root: Node3D, meshes: Array) -> Dictionary:
	var key := _geo_key(root, meshes)
	if key.is_empty():
		return {}
	if _hull_geometry.has(key):
		var cached: Dictionary = _hull_geometry[key]
		_hull_geometry.erase(key)
		_hull_geometry[key] = cached
		return cached
	if _hull_geometry.size() >= GEO_LIMIT:
		_hull_geometry.erase(_hull_geometry.keys()[0])
	var geo := build_geo(root, meshes)
	var resources: Array[Mesh] = []
	for m in meshes:
		if not is_instance_valid(m):
			continue
		var mi := m as MeshInstance3D
		if mi != null and mi.mesh != null:
			resources.append(mi.mesh)
	geo["resources"] = resources
	_hull_geometry[key] = geo
	return geo


# Only installed hulls have a stable kit contract. The local frames keep world
# position and facing out of the key, but a different mesh set or pose misses.
func _geo_key(root: Node3D, meshes: Array) -> Array:
	var path = root.get("hull_res")
	if not cache_geometry or code.is_empty() or formation or not path is String or path.is_empty():
		return []
	var parts: Array = [code, path, stb_z]
	for m in meshes:
		if not is_instance_valid(m):
			parts.append(null)
			continue
		var mi := m as MeshInstance3D
		if mi == null or mi.mesh == null:
			parts.append(null)
			continue
		var frame := Transform3D.IDENTITY
		var part: Node3D = mi
		while part != null and part != root:
			if part.top_level:
				return []   # placed in the world, not under the ship: no sharing
			frame = part.transform * frame
			part = part.get_parent_node_3d()
		if part != root:
			return []
		parts.append(mi.mesh.get_instance_id())
		parts.append(frame)
	return parts


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
				# issue 560: a muzzle under a turret node turns with it; keep it in the turret's own frame (at rest)
				var tk := _turret_above(n3, root)
				if tk >= 0:
					var ti: Transform3D = (turrets[tk]["xf"] as Transform3D).affine_inverse()
					row["tur"] = tk
					row["lp"] = ti * xf.origin
					row["lf"] = (ti.basis * f).normalized()
					row["ln"] = (ti.basis * u).normalized()
					(turrets[tk]["muzzles"] as Array).append(nm)
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
func _find_core(faces: PackedVector3Array, geo: Dictionary) -> void:
	var pts: Array = points.get("core", [])
	core_authored = not pts.is_empty()
	if core_authored:
		core = pts[0]["p"]
		return
	core = c
	if faces.size() < 3:
		return
	if geo.has("fallback_core"):
		core = geo["fallback_core"]
	else:
		core = _volume_center(faces)
		if not geo.is_empty():
			geo["fallback_core"] = core
	if not formation:
		_attach_note("core", "load", "hp_core missing on %s (a load error, HARDPOINTS.md); the effects use the centre of volume of its triangles" % _who())


func _volume_center(faces: PackedVector3Array) -> Vector3:
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
		return c + acc / vol
	return c + aacc / area if area > 0.0 else c


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
	var pts := _gun_points(slot, weapon, target_local, d)
	var out: Array = []
	if not pts.is_empty():
		# issue 1587: a jammed turret (a wounded section, see jam_turret) sits out while another muzzle bears
		var free_pts := pts.filter(func(q: Dictionary) -> bool: return not (q.has("tur") and turret_jammed(int(q["tur"]))))
		if not free_pts.is_empty():
			pts = free_pts
		var key := "%d|%s" % [slot, weapon]
		var off: int = int(_gun_turn.get(key, posmod(hash(code + key), pts.size())))
		var aims := {}     # issue 560: each turret this volley uses turns once, toward the target, before its shots
		for i in n:
			var pt: Dictionary = pts[posmod(off + i, pts.size())]
			if pt.has("tur"):
				var tk: int = int(pt["tur"])
				if not aims.has(tk):
					aims[tk] = turret_aim(tk, target_local, turret_clock)
				out.append(_turned(pt, aims[tk]))
			else:
				out.append(_hp(pt))
			_took("gun", "hp")
		_gun_turn[key] = off + 1
		return out
	# no usable authored point: the plating found by the station rays (cast once at analyse, the same each shot)
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


# Every tier checks bearing and reach. The exact slot and weapon win among usable muzzles, followed by the weapon on
# another slot, then another weapon on the requested slot. An empty list sends guns() to the plating fallback.
func _gun_points(slot: int, weapon: String, target_local: Vector3, d: Vector3) -> Array:
	var same: Array = []
	var by_weapon: Array = []
	var by_slot: Array = []
	for pt in points.get("gun", []):
		var ws: bool = weapon != "" and str(pt["weapon"]) == weapon
		var matches_slot: bool = slot >= 0 and int(pt["slot"]) == slot
		if not (ws or matches_slot) or not _bears(pt, target_local, d):
			continue
		if matches_slot:
			by_slot.append(pt)
			if ws:
				same.append(pt)
		if ws:
			by_weapon.append(pt)
	if not same.is_empty():
		return same
	if not by_weapon.is_empty():
		return by_weapon
	return by_slot


func _bears(pt: Dictionary, target_local: Vector3, d: Vector3) -> bool:
	if pt.has("tur"):
		return turret_reaches(int(pt["tur"]), target_local)
	return str(pt.get("arc", "")) == "T" or maxf((pt["f"] as Vector3).dot(d), (pt["n"] as Vector3).dot(d)) > 0.2


# A wing launch: the i-th hangar mouth; else the plating facing up and toward the target, on the line through the core.
func bay(i: int, toward_local: Vector3) -> Dictionary:
	var pts: Array = points.get("bay", [])
	if not pts.is_empty():
		_took("bay", "hp")
		var pt: Dictionary = pts[posmod(i, pts.size())]
		var r := _hp(pt)
		r["bay"] = int(pt["i"])   # issue 1543: which hp_bay_<n>, so launch() opens that mouth's door
		return r
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


# ---------------------------------------------------------------- turrets (issue 560)
# RULEBOOK 6.17 (Ryan, Nov 11 2026, R219: "I agree with your design on turrets"): turret guns turn to face their target when
# they fire; fixed side guns (casemates, broadside batteries) stay fixed. A turret is a node turret_<n> in the ship
# (docs/ship_pipeline/HARDPOINTS.md "Turrets"): its local +Y is the turning axis through the ring centre, its local -Z the
# rest aim, its turning mesh and its hp_w muzzles are its children. A hull without turret nodes (every A4 hull and the round 7
# recipe export) has none here, and its guns never move.
# Before a turret's shots, guns() turns it toward the target: the goal is the target's bearing, clamped to the turret's arc and
# to the yaws where its barrels stay clear of its own ship (checked once at analyse against the hull and the fixed parts); the
# traverse is eased in and out (a cubic that starts at the turret's current speed and ends at rest: never a snap, RULEBOOK 7.1);
# each shot from that turret is held back until the turret arrives (the volley's "lead") and leaves the muzzle where the turned
# barrel puts it; TURN_HOLD after its last shot the turret trains back to rest the same way. Its pose is a pure function of the
# effect clock (fx.now), so a hurried or slowed clock turns it in step with the shots; fx_ship.update writes the pose onto the
# node every frame. The rules never see any of it (RULEBOOK 7.4): the volley's shots, hits and targets are the rules' own.
const TURRET_RE := "^turret_(\\d+)$"
const TURN_RATE := 150.0     # degrees a second: a traverse's average rate (eased, so the peak is 1.5 times this); a tuning value
const TURN_MIN := 0.3        # seconds: the shortest traverse, so even a small correction eases in and out
const TURN_MAX := 2.4        # seconds: the longest (the far way round a blocked sector), so TURN_RATE holds; a tuning value
const TURN_ACC := 900.0      # degrees a second squared: the most a traverse speeds up or slows down (no lurch); a tuning value
const BARREL_KICK_T := 0.19  # seconds from shot to the barrel returning to battery
const TURN_HOLD := 0.9       # seconds a turret holds its aim after its last shot before it trains back to rest
const CLEAR_STEP := 2.0      # degrees between the barrel clearance samples at analyse
var turrets: Array = []      # {node, name, id, rest (its local transform), xf (root frame at rest), lo, hi, ymin, ymax, full, segs, ...}
var turret_clock := 0.0      # the effect clock now (fx.now): fx_ship.update and every volley set it before guns()
var _turret_of := {}         # turret node instance id -> index


func _read_turrets(root: Node3D) -> void:
	turrets = []
	_turret_of = {}
	var inv := root.global_transform.affine_inverse()
	var re := RegEx.new()
	re.compile(TURRET_RE)
	var found: Array = []
	for nd in root.find_children("turret_*", "Node3D", true, false):
		var n3 := nd as Node3D
		var ex = n3.get_meta("extras", {})
		if not ex is Dictionary:
			ex = {}
		var m := re.search(String(n3.name))
		if m == null and str(ex.get("kind", "")) != "turret":
			continue
		found.append([int(m.get_string(1)) if m != null else 1000 + found.size(), n3, ex])
	found.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	for row in found:
		var n3: Node3D = row[1]
		var ex: Dictionary = row[2]
		_turret_of[n3.get_instance_id()] = turrets.size()
		turrets.append({"node": n3, "name": String(n3.name), "id": str(ex.get("id", n3.name)), "rest": n3.transform,
			"xf": inv * n3.global_transform, "lo": float(ex.get("arc_lo", -180.0)), "hi": float(ex.get("arc_hi", 180.0)),
			"muzzles": [], "ymin": -180.0, "ymax": 180.0, "full": true, "blocked": [], "segs": [], "yaw": 0.0, "aims": 0})


# The turret a node hangs under (its nearest turret ancestor below the root), or -1.
func _turret_above(n: Node, root: Node) -> int:
	var p := n.get_parent()
	while p != null and p != root:
		if _turret_of.has(p.get_instance_id()):
			return int(_turret_of[p.get_instance_id()])
		p = p.get_parent()
	return -1


# A direction's bearing from the bow in degrees, + to port (the frame of the arcs: core.js inArc, HARDPOINTS.md "Turrets").
func bearing_of(d: Vector3) -> float:
	return rad_to_deg(atan2(d.dot(Vector3(0, 0, -stb_z)), d.x))


static func _in_arc(b: float, lo: float, hi: float) -> bool:
	for w in [0.0, 360.0, -360.0]:
		if b + w >= lo - 1e-3 and b + w <= hi + 1e-3:
			return true
	return false


# A turret's root-frame transform at a yaw (degrees) about its own +Y.
func turret_xf(k: int, yaw: float) -> Transform3D:
	return (turrets[k]["xf"] as Transform3D) * Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), Vector3.ZERO)


# Where a turret muzzle is, and where it points, with its turret at a yaw: {"p", "n", "f"} in the root frame.
func muzzle_at(pt: Dictionary, yaw: float) -> Dictionary:
	var T := turret_xf(int(pt["tur"]), yaw)
	return {"p": T * (pt["lp"] as Vector3), "f": (T.basis * (pt["lf"] as Vector3)).normalized(), "n": (T.basis * (pt["ln"] as Vector3)).normalized()}


func _turned(pt: Dictionary, aim: Dictionary) -> Dictionary:
	var m := muzzle_at(pt, float(aim["yaw"]))
	m["src"] = "hp"
	m["tur"] = int(pt["tur"])
	m["yaw"] = float(aim["yaw"])
	m["arrive"] = float(aim["arrive"])
	m["clamped"] = bool(aim["clamped"])
	return m


# The barrels' bearing at a yaw (the first muzzle's aim, flattened into the ship's plane).
func _barrel_bearing(k: int, yaw: float) -> float:
	var pt := _first_muzzle(k)
	var f: Vector3 = (turret_xf(k, yaw).basis * ((pt["lf"] as Vector3) if not pt.is_empty() else Vector3(0, 0, -1))).normalized()
	return bearing_of(f)


func _first_muzzle(k: int) -> Dictionary:
	for pt in points.get("gun", []):
		if int(pt.get("tur", -1)) == k:
			return pt
	return {}


# Once per hull: the yaws each turret may reach from rest, walking both ways until its arc ends or a barrel would run into the
# ship (the hull and every part that does not turn; another turret is taken at rest). A turret's reach is one unbroken run of
# yaws through 0 (rest), [ymin, ymax], or the whole circle (full). Its edges are found to a tenth of a degree.
func _turret_clearance(root: Node3D, meshes: Array) -> void:
	if turrets.is_empty():
		return
	var fixed: Array = []
	for m in meshes:
		if not is_instance_valid(m): continue
		var mi := m as MeshInstance3D
		if mi != null and _turret_above(mi, root) < 0:
			fixed.append(mi)
	var faces := faces_of(root, fixed)
	var tmf: TriangleMesh = null
	if faces.size() >= 3:
		tmf = TriangleMesh.new()
		tmf.create_from_faces(faces)
	for k in turrets.size():
		var t: Dictionary = turrets[k]
		var ok_at := func(yaw: float) -> bool: return _turret_ok(k, yaw, tmf)
		if not ok_at.call(0.0):
			print("[turret] %s on %s: its barrels touch the ship at rest; it stays at rest" % [t["name"], _who()])
			t["full"] = false
			t["ymin"] = 0.0
			t["ymax"] = 0.0
			continue
		# walk each way from rest until a yaw is not allowed; the run may pass 180 (the far way round a blocked sector)
		var hi := 0.0
		while hi + CLEAR_STEP <= 360.0 and ok_at.call(hi + CLEAR_STEP):
			hi += CLEAR_STEP
		var lo := 0.0
		while lo - CLEAR_STEP > hi - 360.0 and ok_at.call(lo - CLEAR_STEP):
			lo -= CLEAR_STEP
		t["full"] = hi - lo >= 360.0 - CLEAR_STEP - 1e-3
		if not t["full"]:
			hi = _edge(ok_at, hi, hi + CLEAR_STEP)
			lo = _edge(ok_at, lo, lo - CLEAR_STEP)
		t["ymin"] = lo
		t["ymax"] = hi
		var why := []
		for y in range(-180, 181, int(CLEAR_STEP)):
			if _in_arc(_barrel_bearing(k, float(y)), float(t["lo"]), float(t["hi"])) and not _turret_ok(k, float(y), tmf):
				why.append(y)
		t["blocked"] = why
		print("[turret] %s (%s) on %s: arc %.0f to %.0f, trains %s%s" % [t["name"], t["id"], _who(), t["lo"], t["hi"],
			"all round" if t["full"] else "%.1f to %.1f from rest" % [lo, hi],
			"" if why.is_empty() else "; %d degrees of its arc are kept clear of the ship" % (why.size() * int(CLEAR_STEP))])


static func _edge(ok_at: Callable, good: float, bad: float) -> float:
	for i in 10:
		var mid := (good + bad) * 0.5
		if ok_at.call(mid):
			good = mid
		else:
			bad = mid
	return good


# A yaw is allowed when every barrel's bearing is inside the arc and no barrel runs into the ship: the barrel's own line, back
# from just past the muzzle along its aim for two thirds of the muzzle's reach from the turning axis (the outer barrel, clear of
# the housing and the ring), and the same line offset by the barrel's radius on four sides.
func _turret_ok(k: int, yaw: float, tmf: TriangleMesh) -> bool:
	var t: Dictionary = turrets[k]
	if not _in_arc(_barrel_bearing(k, yaw), float(t["lo"]), float(t["hi"])):
		return false
	if tmf == null:
		return true
	var T := turret_xf(k, yaw)
	for pt in points.get("gun", []):
		if int(pt.get("tur", -1)) != k:
			continue
		var lp: Vector3 = pt["lp"]
		var lf: Vector3 = pt["lf"]
		var reach := Vector2(lp.x, lp.z).length()
		var r := maxf(float((pt["ex"] as Dictionary).get("radius", 0.0)), 1e-4) * (T.basis.get_scale().x)
		var fw := (T.basis * lf).normalized()
		var b: Vector3 = T * lp + fw * r * 2.0
		var a: Vector3 = T * (lp - lf.normalized() * reach * 0.67)
		var d := (b - a).normalized()
		var s1 := d.cross(Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT).normalized() * r
		var s2 := d.cross(s1).normalized() * r
		for o in [Vector3.ZERO, s1, -s1, s2, -s2]:
			if not tmf.intersect_segment(a + o, b + o).is_empty():
				return false
	return true


# Can turret k bring its barrels onto a point (root frame) without clamping?
func turret_reaches(k: int, target_local: Vector3) -> bool:
	var t: Dictionary = turrets[k]
	return bool(t["full"]) or not _in_reach(t, _want_yaw(k, target_local), 0.0).is_empty()


# The yaws equal to `want` (whole turns apart) inside a turret's reach, nearest `near` first: [] when it cannot get there.
static func _in_reach(t: Dictionary, want: float, near: float) -> Array:
	var out: Array = []
	for j in [-1, 0, 1]:
		var y: float = want + 360.0 * j
		if y >= float(t["ymin"]) - 0.05 and y <= float(t["ymax"]) + 0.05:
			out.append(clampf(y, float(t["ymin"]), float(t["ymax"])))
	out.sort_custom(func(a: float, b: float) -> bool: return absf(a - near) < absf(b - near))
	return out


# A traverse's length: at most TURN_RATE on average, never under TURN_MIN, and long enough that the eased cubic (which starts
# at speed v0 and ends at rest) never speeds up or slows down faster than TURN_ACC.
static func _traverse_time(dy: float, v0: float) -> float:
	var T := clampf(maxf(absf(dy) / TURN_RATE, sqrt(6.0 * absf(dy) / TURN_ACC)), TURN_MIN, TURN_MAX)
	for i in 40:
		var a0 := absf(6.0 * dy - 4.0 * v0 * T) / (T * T)
		var a1 := absf(-6.0 * dy + 2.0 * v0 * T) / (T * T)
		if maxf(a0, a1) <= TURN_ACC:
			break
		T *= 1.08
	return T


# The yaw (degrees, -180 to 180) that turns turret k's rest aim onto a point: about the turret's own axis, from its pivot.
func _want_yaw(k: int, target_local: Vector3) -> float:
	var q: Vector3 = (turrets[k]["xf"] as Transform3D).affine_inverse() * target_local
	var pt := _first_muzzle(k)
	var lf: Vector3 = (pt["lf"] as Vector3) if not pt.is_empty() else Vector3(0, 0, -1)
	# the barrel's own rest direction in the turret's plane (a kit may rest a barrel a little off the node's -Z)
	var rest := atan2(-lf.x, -lf.z)
	return wrapf(rad_to_deg(atan2(-q.x, -q.z) - rest), -180.0, 180.0)


# Turn turret k toward a point (root frame), starting at time now on the effect clock. Returns {"yaw", "arrive", "clamped"}:
# the yaw it will hold, when it gets there and whether the target lay outside its reach (it then holds the nearest edge).
# Issue 1581 (OpenAI review F3): the turrets a volley of n shots from this slot and weapon would use, without aiming or
# counting anything (the same pick as guns(): the same points, the same rotation offset). [] for fixed guns.
func gun_turrets(slot: int, weapon: String, target_local: Vector3, n: int) -> Array:
	var d := target_local - core
	d = d.normalized() if d.length() > 1e-4 else Vector3(1, 0, 0)
	var pts := _gun_points(slot, weapon, target_local, d)
	var out: Array = []
	if pts.is_empty():
		return out
	# Neon on PR 1631: the same jammed-turret filter as guns(), so a Burn and fire never trains a jammed turret
	var free_pts := pts.filter(func(q: Dictionary) -> bool: return not (q.has("tur") and turret_jammed(int(q["tur"]))))
	if not free_pts.is_empty():
		pts = free_pts
	var key := "%d|%s" % [slot, weapon]
	var off: int = int(_gun_turn.get(key, posmod(hash(code + key), pts.size())))
	for i in maxi(n, 1):
		var pt: Dictionary = pts[posmod(off + i, pts.size())]
		if pt.has("tur") and not out.has(int(pt["tur"])):
			out.append(int(pt["tur"]))
	return out


# Issue 1581: seconds turret k needs from its pose at `now` to bear on target_local (0 when it already does).
func turret_need(k: int, target_local: Vector3, now: float) -> float:
	var t: Dictionary = turrets[k]
	var want := _want_yaw(k, target_local)
	var y0 := turret_yaw(k, now)
	var goal := want + 360.0 * roundf((y0 - want) / 360.0) if bool(t["full"]) else want
	if absf(goal - y0) <= 0.25:
		return 0.0
	return _traverse_time(goal - y0, _turret_speed(k, now))


func turret_aim(k: int, target_local: Vector3, now: float) -> Dictionary:
	var t: Dictionary = turrets[k]
	if t.has("jam"):
		# issue 1587: a jammed turret stays where it froze and never tracks
		return {"yaw": float(t["jam"]["yaw"]), "arrive": now, "clamped": true}
	var want := _want_yaw(k, target_local)
	now = maxf(now, float(t.get("busy", -INF)))    # never swing away under shots an earlier volley still has to fire
	var y0 := turret_yaw(k, now)
	var v0 := _turret_speed(k, now)
	var goal := want
	var clamped := false
	if bool(t["full"]):
		goal = want + 360.0 * roundf((y0 - want) / 360.0)      # the nearest turn to where it already points
	else:
		var lo: float = t["ymin"]
		var hi: float = t["ymax"]
		var can := _in_reach(t, want, y0)
		if not can.is_empty():
			goal = can[0]
		else:
			# out of reach: the edge whose bearing is nearer the target's; when the two are within 10 degrees of each other,
			# the one the turret reaches with less turning
			clamped = true
			var dlo := absf(wrapf(want - lo, -180.0, 180.0))
			var dhi := absf(wrapf(want - hi, -180.0, 180.0))
			if absf(dlo - dhi) < 10.0:
				goal = lo if absf(lo - y0) < absf(hi - y0) else hi
			else:
				goal = lo if dlo < dhi else hi
	var segs: Array = t["segs"]
	# a new aim replaces whatever was planned after now (a pending return to rest, an older aim)
	while not segs.is_empty() and float(segs[-1]["t0"]) > now:
		segs.pop_back()
	var arrive := now
	if absf(goal - y0) > 0.25 or absf(v0) > 1.0:
		var dur := _traverse_time(goal - y0, v0)
		segs.append({"t0": now, "t1": now + dur, "y0": y0, "y1": goal, "v0": v0})
		arrive = now + dur
	elif not segs.is_empty():
		arrive = maxf(now, float(segs[-1]["t1"]))
	t["aims"] = int(t["aims"]) + 1
	return {"yaw": goal, "arrive": arrive, "clamped": clamped}


# After its shots: turret k holds its aim through its last shot (fired at `last`) and TURN_HOLD more, then trains back to rest
# (the nearest whole turn).
func turret_release(k: int, last: float) -> void:
	var t: Dictionary = turrets[k]
	if t.has("jam"):
		return
	t["busy"] = maxf(float(t.get("busy", -INF)), last)
	var at := last + TURN_HOLD
	var segs: Array = t["segs"]
	while not segs.is_empty() and float(segs[-1]["t0"]) > at:
		segs.pop_back()
	var y := turret_yaw(k, at)
	# home: rest itself for a turret whose reach is one run (it goes back the way it came), the nearest whole turn otherwise
	var home := 360.0 * roundf(y / 360.0) if bool(t["full"]) else 0.0
	if absf(y - home) < 0.25:
		return
	var v := _turret_speed(k, at)
	segs.append({"t0": at, "t1": at + _traverse_time(home - y, v), "y0": y, "y1": home, "v0": v})


# Turret k's yaw (degrees from rest) and speed (degrees a second) at time t on the effect clock.
func turret_yaw(k: int, t: float) -> float:
	var s := _seg_at(k, t)
	if s.is_empty():     # nothing has started yet: the pose before the first planned segment (rest when none)
		var segs: Array = turrets[k]["segs"]
		return 0.0 if segs.is_empty() else float(segs[0]["y0"])
	var T := float(s["t1"]) - float(s["t0"])
	var u := clampf((t - float(s["t0"])) / maxf(T, 1e-4), 0.0, 1.0)
	var y := (2.0 * u * u * u - 3.0 * u * u + 1.0) * float(s["y0"]) + (u * u * u - 2.0 * u * u + u) * T * float(s["v0"]) \
		+ (-2.0 * u * u * u + 3.0 * u * u) * float(s["y1"])
	var tt: Dictionary = turrets[k]
	if not bool(tt["full"]):
		y = clampf(y, float(tt["ymin"]), float(tt["ymax"]))    # a reversal that would swing past the reach edge holds at it
	return y


func _turret_speed(k: int, t: float) -> float:
	var s := _seg_at(k, t)
	if s.is_empty() or t >= float(s["t1"]):
		return 0.0
	var T := float(s["t1"]) - float(s["t0"])
	var u := clampf((t - float(s["t0"])) / maxf(T, 1e-4), 0.0, 1.0)
	return ((6.0 * u * u - 6.0 * u) * float(s["y0"]) + (3.0 * u * u - 4.0 * u + 1.0) * T * float(s["v0"]) + (-6.0 * u * u + 6.0 * u) * float(s["y1"])) / maxf(T, 1e-4)


# The segment in force at t: the last one that has started (its end pose holds until the next one starts).
func _seg_at(k: int, t: float) -> Dictionary:
	var segs: Array = turrets[k]["segs"]
	for i in range(segs.size() - 1, -1, -1):
		if float(segs[i]["t0"]) <= t:
			return segs[i]
	return {}


# Move the authored barrel assembly and its muzzle sockets under the fixed turning ring.
# sockets false (the light kick of a gun without its own recoil) leaves the muzzle sockets still, so the next shot still
# leaves from the turned muzzle; the heavy kick moves them with the barrels.
func turret_fire(k: int, t: float, travel: float, sockets := true) -> void:
	var tt: Dictionary = turrets[k]
	if not tt.has("kick_parts"):
		var muzzle := _first_muzzle(k)
		var axis: Vector3 = muzzle.get("lf", Vector3.FORWARD)
		var world_scale := ((tt["xf"] as Transform3D).basis * axis).length()
		tt["kick_axis"] = -axis / maxf(world_scale, 0.001)
		tt["kicks"] = []
		var parts := []
		var n: Node3D = tt["node"]
		for child in n.get_children():
			if child is Node3D and (child.name == String(n.name) + "_turn" or String(child.name).begins_with("hp_w")):
				parts.append([child, child.position])
		if not parts.any(func(pt: Array) -> bool: return not String((pt[0] as Node).name).begins_with("hp_w")):
			# Neon on PR 1699: a turret whose barrel mesh has another name (no "<turret>_turn" child) still kicks: its
			# visible mesh children with its muzzle sockets, or the turret node itself when it is the mesh (from its rest
			# position, so the per-frame yaw pose is untouched)
			var meshes_n := 0
			for child in n.get_children():
				if child is MeshInstance3D and (child as MeshInstance3D).visible:
					parts.append([child, child.position])
					meshes_n += 1
			if meshes_n == 0 and n is MeshInstance3D:
				parts = [[n, (tt["rest"] as Transform3D).origin, true]]   # its sockets ride along as its children
		tt["kick_parts"] = parts
	(tt["kicks"] as Array).append(Vector3(t, travel, 1.0 if sockets else 0.0))


func _turret_kick(tt: Dictionary, t: float) -> void:
	var kicks: Array = tt["kicks"]
	var travel := 0.0
	var sock_travel := 0.0
	for i in range(kicks.size() - 1, -1, -1):
		var pulse: Vector3 = kicks[i]
		var age := t - pulse.x
		if age >= BARREL_KICK_T:
			kicks.remove_at(i)
		elif age >= 0.0:
			var stroke := smoothstep(0.0, 0.035, age) * (1.0 - smoothstep(0.035, BARREL_KICK_T, age))
			travel = maxf(travel, pulse.y * stroke)
			if pulse.z > 0.0:
				sock_travel = maxf(sock_travel, pulse.y * stroke)
	if travel == 0.0 and not bool(tt.get("kicking", false)):
		return
	tt["kicking"] = travel > 0.0
	var offset: Vector3 = (tt["kick_axis"] as Vector3) * travel
	var sock_offset: Vector3 = (tt["kick_axis"] as Vector3) * sock_travel
	for part: Array in tt["kick_parts"]:
		if is_instance_valid(part[0]):
			var nd := part[0] as Node3D
			if String(nd.name).begins_with("hp_w"):
				nd.position = (part[1] as Vector3) + sock_offset
			elif part.size() > 2:   # the turret node itself: its stroke along its own (turned) axis, from its rest point
				nd.position = (part[1] as Vector3) + nd.basis * offset
			else:
				nd.position = (part[1] as Vector3) + offset


# Every frame (fx_ship.update): put each turret's node at its pose for the effect clock and drop finished segments.
func turret_step(t: float) -> void:
	turret_clock = t
	for k in turrets.size():
		var tt: Dictionary = turrets[k]
		var n = tt["node"]
		if not is_instance_valid(n):
			continue
		var segs: Array = tt["segs"]
		while segs.size() > 1 and float(segs[1]["t0"]) <= t:
			segs.pop_front()
		var y := turret_yaw(k, t)
		var droop := 0.0
		if tt.has("jam"):
			# issue 1587: frozen off its aim and sagging on its mount, eased in over a third of a second
			var jm: Dictionary = tt["jam"]
			var u := smoothstep(float(jm["t0"]), float(jm["t0"]) + 0.35, t)
			y = lerpf(float(jm["from"]), float(jm["yaw"]), u)
			droop = float(jm["droop"]) * u
		tt["yaw"] = y
		var bs := Basis(Vector3.UP, deg_to_rad(y))
		if droop != 0.0:
			bs = bs * Basis(Vector3.RIGHT, deg_to_rad(-droop))
		(n as Node3D).transform = (tt["rest"] as Transform3D) * Transform3D(bs, Vector3.ZERO)
		if tt.has("kicks"):
			_turret_kick(tt, t)   # issue 1690 (Wave 1A): the barrel kick, on top of 1587's jam sag


# Issue 1587: a wounded section's turret freezes a little off its aim and sags (view only; the rules never see it). jam_turret
# holds it at yaw (degrees from rest) dipped by droop degrees from time now; unjam_turret frees it to track and return to rest.
func jam_turret(k: int, yaw: float, droop: float, now: float) -> void:
	if k < 0 or k >= turrets.size():
		return
	var t: Dictionary = turrets[k]
	var from := turret_yaw(k, now)
	if not bool(t["full"]):
		yaw = clampf(yaw, float(t["ymin"]), float(t["ymax"]))
	t["segs"] = []
	t["jam"] = {"yaw": yaw, "droop": droop, "t0": now, "from": from}


func unjam_turret(k: int, now: float) -> void:
	if k < 0 or k >= turrets.size() or not turrets[k].has("jam"):
		return
	var t: Dictionary = turrets[k]
	var y := float(t["jam"]["yaw"])
	t.erase("jam")
	t["segs"] = [{"t0": now, "t1": now + _traverse_time(-y, 0.0), "y0": y, "y1": 0.0, "v0": 0.0}]


func turret_jammed(k: int) -> bool:
	return k >= 0 and k < turrets.size() and turrets[k].has("jam")


# Which section a turret sits in (SEC_ENG, SEC_MID or SEC_PROW), from its pivot.
func turret_section(k: int) -> int:
	return section_of((turrets[k]["xf"] as Transform3D).origin.x)


# Issue 1741 (R416): the turrets one weapon slot owns (its hp_w<slot>_* muzzles hang under them), in turret order. The slot
# is the rules' weapon index (HARDPOINTS.md), so a knocked-out weapon jams its own guns, never a random one.
func turrets_for_slot(slot: int) -> Array:
	var out: Array = []
	for pt in points.get("gun", []):
		if int(pt.get("slot", -1)) == slot and pt.has("tur") and not out.has(int(pt["tur"])):
			out.append(int(pt["tur"]))
	out.sort()
	return out


# Issue 1741 (Artoo on PR 1749): true when some weapon slot's muzzle hangs under turret k.
func turret_owned(k: int) -> bool:
	for pt in points.get("gun", []):
		if pt.has("tur") and int(pt["tur"]) == k:
			return true
	return false


# Issue 1741: the fixed mounts (casemates, launchers, spinal muzzles: gun points under no turret) of one weapon slot.
func mounts_for_slot(slot: int) -> Array:
	var out: Array = []
	for pt in points.get("gun", []):
		if int(pt.get("slot", -1)) == slot and not pt.has("tur"):
			out.append(pt)
	return out


# ---------------------------------------------------------------- doors (issue 1543)
# Ryan (Nov 21 2026): a launch mouth has a flesh door "in sections with the opening spreading from the middle", closed between
# launches, plain flesh. A door reaches the game as a node door_<n> (docs/ship_pipeline/HARDPOINTS.md "Doors"; extras: the bay
# it opens for and open_deg) with one node door_<n>_lobe_<k> per lobe at its hinge: local +X the hinge line, -Z toward the
# door's centre, +Y out of the mouth; a turn of open_deg (negative: the tip folds down into the bore) about +X opens it.
# launch() opens the door of the bay a squadron leaves from (door_cycle): the lobes ease open before the first craft leaves,
# hold while the squadron is out, then ease shut. Like a turret's, a door's pose is a pure function of the effect clock (fx.now);
# fx_ship.update writes it onto the lobe nodes every frame. The rules never see a door (RULEBOOK 7.4).
const DOOR_RE := "^door_(\\d+)$"
const DOOR_OPEN := 0.28      # seconds to open (the first craft leaves 0.3 after the launch call: fx_weapons.launch)
const DOOR_CLOSE := 0.5      # seconds to shut, after the hold
var doors: Array = []        # {node, name, id, bay, deg, lobes: [{node, rest}], wins: [[t_open, t_shut]], f}
var _door_of := {}           # door node instance id -> index


func _read_doors(root: Node3D) -> void:
	doors = []
	_door_of = {}
	var re := RegEx.new()
	re.compile(DOOR_RE)
	var found: Array = []
	for nd in root.find_children("door_*", "Node3D", true, false):
		var m := re.search(String(nd.name))
		if m == null:
			continue
		var ex = (nd as Node3D).get_meta("extras", {})
		if not ex is Dictionary:
			ex = {}
		found.append([int(m.get_string(1)), nd, ex])
	found.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	for row in found:
		var d3: Node3D = row[1]
		var ex: Dictionary = row[2]
		var lobes: Array = []
		var lre := RegEx.create_from_string("^%s_lobe_(\\d+)$" % String(d3.name))
		for c in d3.get_children():
			if c is Node3D and lre.search(String(c.name)) != null:
				lobes.append({"node": c, "rest": (c as Node3D).transform})
		_door_of[d3.get_instance_id()] = doors.size()
		doors.append({"node": d3, "name": String(d3.name), "id": str(ex.get("id", d3.name)), "bay": int(ex.get("bay", row[0])),
			"deg": float(ex.get("open_deg", -100.0)), "lobes": lobes, "wins": [], "f": 0.0})


# The door a node belongs to (itself or its nearest door ancestor below the root), or -1.
func _door_above(n: Node, root: Node) -> int:
	var p := n
	while p != null and p != root:
		if _door_of.has(p.get_instance_id()):
			return int(_door_of[p.get_instance_id()])
		p = p.get_parent()
	return -1


# The door that opens for bay i (hp_bay_<i>), or -1.
func door_for_bay(i: int) -> int:
	for k in doors.size():
		if int(doors[k]["bay"]) == i:
			return k
	return -1


# Open bay i's door from t_open, hold it open until t_hold (the last craft clear), then shut it. A second launch from the same
# bay while the door is still held open extends that hold, so it never shuts between squadrons. One that comes while the door is
# closing gets its own window: the door's pose is the most open of its windows, so it reopens from where it is (it keeps
# closing until the new opening passes it, then opens), never jumping back to fully open (Artoo on PR 1544).
func door_cycle(i: int, t_open: float, t_hold: float) -> void:
	var k := door_for_bay(i)
	if k < 0:
		return
	var wins: Array = doors[k]["wins"]
	for w in wins:
		if t_open >= float(w[0]) and t_open <= float(w[1]):
			w[1] = maxf(float(w[1]), t_hold)
			return
	wins.append([t_open, t_hold])


# How far door k is open at time t: 0 shut, 1 open; eased in and out (smoothstep), never a snap (RULEBOOK 7.1).
func door_open_at(k: int, t: float) -> float:
	var f := 0.0
	for w in doors[k]["wins"]:
		var a := float(w[0])
		var b := float(w[1])
		var g := 0.0
		if t < a or t > b + DOOR_CLOSE:
			g = 0.0
		elif t < a + DOOR_OPEN:
			g = smoothstep(0.0, 1.0, (t - a) / DOOR_OPEN)
		elif t <= b:
			g = 1.0
		else:
			g = 1.0 - smoothstep(0.0, 1.0, (t - b) / DOOR_CLOSE)
		f = maxf(f, g)
	return f


func door_step(t: float) -> void:
	for k in doors.size():
		var d: Dictionary = doors[k]
		var wins: Array = d["wins"]
		while not wins.is_empty() and float(wins[0][1]) + DOOR_CLOSE < t - 1.0:
			wins.pop_front()
		var f := door_open_at(k, t)
		if f == float(d["f"]) and f == 0.0:
			continue
		d["f"] = f
		var b := Basis(Vector3.RIGHT, deg_to_rad(float(d["deg"]) * f))
		for lb in d["lobes"]:
			if is_instance_valid(lb["node"]):
				(lb["node"] as Node3D).transform = (lb["rest"] as Transform3D) * Transform3D(b, Vector3.ZERO)
