extends RefCounted
# F4 asteroids: the rock library (world/rocks/*.glb, made by world/tools/rockgen.py), a material per rock kind, and
# instanced layers. Every rock of a layer that shares a mesh is one MultiMesh (one draw), and tumbles in the vertex shader
# (axis and rate in the instance's custom data), so a field of hundreds costs no CPU time per frame.
#
# Kinds (battle.js ROCK_KINDS, the sector's biome):
#   stone   grey-brown S-type rock, lighter fresh fracture faces
#   iron    dark iron-nickel: bright metal where it broke, a dull brown crust elsewhere
#   carbon  near-black C-type rubble, matte, faint grey speckle
#   ice     dark dirty crust with clean blue-white ice on the fracture faces and in the cliffs, glossy, faint cold glow
#           in the cracks
#   crystal dark stone carrying clusters of glowing crystal (see CRYSTAL)
# Far rocks fade into the sky's haze by their distance from the board, so the board's own rocks stay the crispest things
# on screen and the deep field reads as far away (and never as a hex obstacle).

const LIB_DIR := "res://world/rocks/"

static var _meshes := {}      # name -> Mesh
static var _lib: Dictionary = {}
static var _detail: Texture3D = null

const ROCK_SHADER := """
shader_type spatial;
render_mode cull_back;
uniform int kind = 0;
uniform vec3 base = vec3(0.09, 0.075, 0.062);
uniform vec3 fresh = vec3(0.16, 0.15, 0.14);
uniform sampler3D detail : filter_linear, repeat_enable;
uniform float q = 1.0;
uniform vec3 board_c = vec3(0.0);
uniform vec2 haze_r = vec2(320.0, 2200.0);
uniform vec3 haze_col = vec3(0.01, 0.012, 0.02);
uniform float haze_max = 0.85;
uniform float depth_haze = 1.0;
uniform vec3 rim_pos = vec3(0.0);
uniform vec3 rim_col = vec3(1.0, 0.6, 0.3);
uniform float rim_k = 0.0;
uniform vec3 glow_col = vec3(0.25, 0.75, 1.0);
uniform sampler2D sky_tex : filter_linear_mipmap, repeat_enable;
uniform float has_sky = 0.0;
uniform float sky_gain = 1.0;
uniform mat3 turn = mat3(1.0);
uniform float lift = 1.0;      // the board's own blockers are lifted a little so terrain reads at a glance
varying vec3 vL;
varying vec4 vC;
varying vec3 vW;
varying float vSeed;
vec3 rot(vec3 v, vec3 ax, float a) { float c = cos(a); float s = sin(a); return v * c + cross(ax, v) * s + ax * dot(ax, v) * (1.0 - c); }
void vertex() {
	vL = VERTEX;
	vC = COLOR;
	vec4 ic = INSTANCE_CUSTOM;
	vSeed = ic.w;
	float rate = length(ic.xyz);
	if (rate > 1e-6) {
		vec3 ax = ic.xyz / rate;
		float a = TIME * rate + ic.w * 6.2831;
		VERTEX = rot(VERTEX, ax, a);
		NORMAL = rot(NORMAL, ax, a);
	}
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
vec3 bump_normal(vec3 n, vec3 pos, float h, float k) {
	vec3 dpdx = dFdx(pos); vec3 dpdy = dFdy(pos);
	float dhx = dFdx(h); float dhy = dFdy(h);
	vec3 r1 = cross(dpdy, n); vec3 r2 = cross(n, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dhx * r1 + dhy * r2);
	return normalize(abs(det) * n - grad * k);
}
void fragment() {
	vec3 p = vL * 2.2 + vSeed * 13.7;
	float n1 = texture(detail, p * 0.21).r;
	float n2 = texture(detail, p * 0.73 + 0.31).r;
	// the finest grit fades out where it would shimmer (small on screen)
	float fw = length(fwidth(p * 2.6));
	float n3 = mix(texture(detail, p * 2.6 + 0.57).r, 0.5, clamp(fw * 1.2, 0.0, 1.0));
	float cav = vC.r;
	float crat = vC.g;
	float facet = vC.b;
	float patchv = vC.a;
	vec3 a = base * mix(0.72, 1.25, patchv) * (0.78 + 0.45 * n1) * (0.86 + 0.28 * n2);
	a *= 1.0 - crat * 0.25;
	float rough = 0.9;
	float metal = 0.0;
	vec3 em = vec3(0.0);
	float fr = clamp(facet * 0.8 + smoothstep(0.62, 0.8, n1) * 0.25, 0.0, 1.0);
	if (kind == 0) {
		a = mix(a, fresh * (0.85 + 0.3 * n2), fr * 0.7);
		a *= mix(vec3(1.0), vec3(1.06, 0.98, 0.9), smoothstep(0.4, 0.7, n2));
	} else if (kind == 1) {
		float m = clamp(fr + smoothstep(0.6, 0.75, n2) * 0.5, 0.0, 1.0);
		a = mix(a, fresh, m);
		metal = mix(0.15, 0.85, m);
		rough = mix(0.82, 0.38, m) + n3 * 0.1;
	} else if (kind == 2) {
		a *= 1.0 + smoothstep(0.7, 0.85, n3) * 0.8;
		a = mix(a, fresh, fr * 0.3);
		rough = 0.96;
	} else if (kind == 3) {
		// r2: dark dusty crust, clean ice only in the fresh breaks and a few patches, frosty rather than glossy (r1's ice
		// covered most faces at roughness 0.2 and read as pale blue plastic)
		float ice = clamp(fr * 0.85 + smoothstep(0.64, 0.8, n1) * 0.4 - crat * 0.4, 0.0, 1.0);
		ice *= ice;
		a = mix(a, fresh * (0.8 + 0.3 * n2), ice);
		rough = mix(0.88, 0.42, ice);
		float crack = smoothstep(0.93, 0.985, 1.0 - abs(n2 * 2.0 - 1.0));
		em = glow_col * crack * ice * 0.05;
	} else {
		a = mix(a, fresh, fr * 0.5);
		// r2: thinner and dimmer veins, only in the fresh faces (r1 laced every rock with a bright net)
		float vein = smoothstep(0.965, 0.995, 1.0 - abs(n1 * 2.0 - 1.0)) * smoothstep(0.2, 0.7, fr);
		em = glow_col * vein * 0.3;
		rough = mix(0.85, 0.4, fr);
	}
	a *= mix(0.4, 1.0, cav) * lift;
	float ht = n2 * 0.65 + n3 * 0.25 - crat * 0.2;
	NORMAL = bump_normal(NORMAL, VERTEX, ht, q > 0.5 ? 0.9 : 0.5);
	ALBEDO = a;
	ROUGHNESS = rough;
	METALLIC = metal;
	// r2: a dull dielectric sheen (the default 0.5 caught the cold fill light and turned brown rock grey-blue)
	SPECULAR = kind == 3 ? 0.5 : 0.3;
	AO = cav;
	AO_LIGHT_AFFECT = 0.4;
	if (rim_k > 0.0) {
		vec3 nw = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		vec3 L = rim_pos - vW;
		float dl = length(L);
		L /= max(dl, 1e-3);
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
		float face = clamp(dot(nw, L) * 0.8 + 0.2, 0.0, 1.0);
		float fall = 1.0 / (1.0 + dl * dl / 40000.0);
		em += rim_col * rim_k * face * (0.06 + 0.9 * fres) * fall;
	}
	// far rocks sink into the sky behind them (its own colour, read from the baked nebula along the view ray): by distance
	// from the board, and more by how far below its plane they lie, so nothing deep can pass for a rock on a hex
	float dist = length(vW - board_c);
	float below = -(vW.y - board_c.y);
	// r2: weaker than r1, whose far rocks turned into pale see-through ghosts; a far rock now stays a dark solid shape
	// against the gas, which reads as far away without reading as a hole in the sky
	float hz = smoothstep(haze_r.x, haze_r.y, dist) * 0.55 + depth_haze * smoothstep(60.0, 700.0, below) * 0.4;
	vec3 hc = haze_col;
	if (has_sky > 0.5) {
		vec3 d = turn * normalize(vW - CAMERA_POSITION_WORLD);
		vec2 uv = vec2(atan(d.x, -d.z) / 6.28318530718 + 0.5, acos(clamp(d.y, -1.0, 1.0)) / 3.14159265359);
		// r8: a darkened, blurred sky colour (a full-strength sky picture made far rocks look see-through: the fog painted
		// the nebula's own pattern onto them); far rocks now read as dimmer solid shapes against the gas
		hc = pow(textureLod(sky_tex, uv, 4.0).rgb, vec3(2.2)) * sky_gain * 0.4 + haze_col * 0.5;
	}
	FOG = vec4(hc, clamp(hz, 0.0, 1.0) * haze_max);
	// lifted rocks (the board's blockers) catch a soft cool rim from the sky, which separates them from the dark board
	em += vec3(0.05, 0.065, 0.09) * (lift - 1.0) * pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	// glow fades with the haze too (fog does not dim emission enough: deep rocks kept bright veins)
	EMISSION = em * (1.0 - clamp(hz, 0.0, 1.0));
}
"""

# Crystal clusters: dark glassy prisms lit from inside, brightest at the tips, split into colour at the edges.
const CRYSTAL_SHADER := """
shader_type spatial;
render_mode cull_back;
uniform vec3 glow = vec3(0.3, 0.8, 1.0);
uniform vec3 edge = vec3(0.7, 0.45, 1.0);
uniform vec3 board_c = vec3(0.0);
uniform vec2 haze_r = vec2(320.0, 2200.0);
uniform vec3 haze_col = vec3(0.01);
uniform float haze_max = 0.85;
varying vec4 vC;
varying vec3 vW;
varying float vSeed;
vec3 rot(vec3 v, vec3 ax, float a) { float c = cos(a); float s = sin(a); return v * c + cross(ax, v) * s + ax * dot(ax, v) * (1.0 - c); }
void vertex() {
	vC = COLOR;
	vec4 ic = INSTANCE_CUSTOM;
	vSeed = ic.w;
	float rate = length(ic.xyz);
	if (rate > 1e-6) {
		vec3 ax = ic.xyz / rate;
		float a = TIME * rate + ic.w * 6.2831;
		VERTEX = rot(VERTEX, ax, a);
		NORMAL = rot(NORMAL, ax, a);
	}
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float up = vC.g;
	float f = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.0);
	ALBEDO = vec3(0.02, 0.035, 0.05);
	ROUGHNESS = 0.08;
	METALLIC = 0.3;
	SPECULAR = 0.9;
	float pulse = 0.85 + 0.15 * sin(TIME * 0.7 + vSeed * 17.0);
	EMISSION = (glow * (0.12 + 0.9 * up * up) + mix(glow, edge, f) * f * 0.9) * pulse;
	float dist = length(vW - board_c);
	float below = -(vW.y - board_c.y);
	FOG = vec4(haze_col, clamp(smoothstep(haze_r.x, haze_r.y, dist) * 0.55 + smoothstep(60.0, 700.0, below) * 0.4, 0.0, 1.0) * haze_max);
}
"""

# per kind: base albedo (linear), fresh fracture colour, shader kind, crystal glow
const KINDS := {
	"stone": {"base": Vector3(0.12, 0.098, 0.078), "fresh": Vector3(0.27, 0.235, 0.2), "k": 0},
	"iron": {"base": Vector3(0.085, 0.066, 0.054), "fresh": Vector3(0.44, 0.41, 0.38), "k": 1},
	"carbon": {"base": Vector3(0.045, 0.041, 0.038), "fresh": Vector3(0.09, 0.085, 0.08), "k": 2},
	"ice": {"base": Vector3(0.085, 0.086, 0.092), "fresh": Vector3(0.5, 0.62, 0.74), "k": 3},
	"crystal": {"base": Vector3(0.06, 0.058, 0.064), "fresh": Vector3(0.14, 0.14, 0.16), "k": 4},
}


static func lib() -> Dictionary:
	if _lib.is_empty() and FileAccess.file_exists(LIB_DIR + "rocks.json"):
		var j = JSON.parse_string(FileAccess.get_file_as_string(LIB_DIR + "rocks.json"))
		if j is Dictionary:
			_lib = j
	return _lib


static func mesh(name: String) -> Mesh:
	if _meshes.has(name):
		return _meshes[name]
	var m: Mesh = null
	var p := LIB_DIR + name + ".glb"
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
		push_warning("[world] rock mesh missing: " + p)
	_meshes[name] = m
	return m


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
	var L := lib()
	if L.is_empty():
		return []
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


# One material per kind and look (the far layers share it, with their haze)
static func material(kind: String, look: Dictionary) -> ShaderMaterial:
	var K: Dictionary = KINDS.get(kind, KINDS["stone"])
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = ROCK_SHADER
	m.shader = sh
	m.set_shader_parameter("kind", int(K["k"]))
	m.set_shader_parameter("base", K["base"])
	m.set_shader_parameter("fresh", K["fresh"])
	m.set_shader_parameter("detail", detail_tex())
	m.set_shader_parameter("q", 1.0 if str(look.get("quality", "max")) == "max" else 0.0)
	m.set_shader_parameter("board_c", look.get("board_c", Vector3.ZERO))
	m.set_shader_parameter("haze_col", look.get("haze", Vector3(0.01, 0.012, 0.02)))
	m.set_shader_parameter("haze_r", look.get("haze_r", Vector2(320, 2200)))
	m.set_shader_parameter("haze_max", float(look.get("haze_max", 0.85)))
	m.set_shader_parameter("glow_col", look.get("glow", Vector3(0.25, 0.75, 1.0)))
	if look.has("rim_pos"):
		m.set_shader_parameter("rim_pos", look["rim_pos"])
		m.set_shader_parameter("rim_k", 1.6)
	return m


static func crystal_material(look: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = CRYSTAL_SHADER
	m.shader = sh
	m.set_shader_parameter("board_c", look.get("board_c", Vector3.ZERO))
	m.set_shader_parameter("haze_col", look.get("haze", Vector3(0.01, 0.012, 0.02)))
	m.set_shader_parameter("haze_r", look.get("haze_r", Vector2(320, 2200)))
	if look.has("glow"):
		m.set_shader_parameter("glow", look["glow"])
	return m


# ---------------------------------------------------------------- instanced layers

# Collects rock instances per (mesh, layer) and builds one MultiMeshInstance3D each.
class Batch:
	var groups := {}     # key -> {mesh, mat, shadow, xf: [], cd: []}

	func add(mesh_name: String, mat: Material, shadow: bool, xf: Transform3D, spin_axis: Vector3, rate: float, seed_v: float) -> void:
		var key := "%s|%d|%d" % [mesh_name, mat.get_instance_id(), 1 if shadow else 0]
		if not groups.has(key):
			groups[key] = {"mesh": mesh_name, "mat": mat, "shadow": shadow, "xf": [], "cd": []}
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
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if g["shadow"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# the rocks tumble in the shader: give the bounds room for it
			mmi.extra_cull_margin = 40.0
			parent.add_child(mmi)
			n += mm.instance_count
		return n
