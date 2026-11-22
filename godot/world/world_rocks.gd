extends RefCounted
# F4 asteroids: the rock library (world/rocks/*.glb, made by world/tools/rockgen.py), a material per rock kind, and
# instanced layers. Every rock of a layer that shares a mesh is one MultiMesh (one draw), with a fixed seeded pose in
# the vertex shader (axis and seed in the instance's custom data). Time and camera movement never turn its geometry.
#
# Kinds (battle.js ROCK_KINDS, the sector's biome):
#   stone   warm ochre S-type silicate rock, dark dust pockets, lighter fresh fracture faces
#   iron    cool dark gunmetal slag crust, bright nickel-iron metal on the fresh ridges (issue 1361)
#   carbon  deep charcoal C-type rock, matte, ash-grey ridge highlights, never tan (issue 1361)
#   ice     dark comet crust with clean pale frost shelves on the fresh faces, faint cold glow in the cracks
#   crystal dark slate host rock, thin glowing mineral veins seated in its crevices, plus clusters of crystal (see CRYSTAL)
# Issue 1361 (World V2, R419): each kind draws on its own subset of the scans (KIND_SCANS) and squeezes them its own way in
# the vertex shader (shape_k: iron chunkier, ice longer and sharper), so the five belts differ in shape as well as colour.
# The scans' COLOR_0.b (facet) is ridge convexity re-baked by world/tools/scan_facet.py, spanning 0 to 1 like rockgen's.
# Far rocks fade into the sky's haze by their distance from the board, so the board's own rocks stay the crispest things
# on screen and the deep field reads as far away (and never as a hex obstacle).

const LIB_DIR := "res://world/rocks/"
# Issue 1361 before/after capture on one commit: VS_1361_OLD=1 draws main's old look (world_rocks_v1.gd shaders and
# kinds, every scan for every kind) from the old rock files in VS_1361_OLD_DIR (the PC job's old checkout). Off in play.
static var OLD := OS.get_environment("VS_1361_OLD") == "1"
static var lib_dir := _lib_dir()


static func _lib_dir() -> String:
	var d := OS.get_environment("VS_1361_OLD_DIR").replace("\\", "/")
	if OS.get_environment("VS_1361_OLD") != "1" or d == "":
		return LIB_DIR
	return d if d.ends_with("/") else d + "/"


static func _v1():
	return load("res://world/world_rocks_v1.gd")

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
# Issue 1361: six scans (scan_06 and the flat boomerang scan_07 were retired; scans.json "retired").
const SCAN_COUNT := 6
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
		if not manifest is Dictionary or manifest.get("rocks", []).size() != (8 if OLD else SCAN_COUNT):
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

const ROCK_SHADER := """
shader_type spatial;
render_mode cull_back;
// A sphere about the pose's origin bounds every orientation of this batch's mesh.
instance uniform float rock_radius = 1.0;
// Issue 1361: the mesh's own box size (Batch.build), so shape_k can squeeze its long or short axes
instance uniform vec3 rock_ext = vec3(2.0);
global uniform float cam_near;
global uniform vec4 cam_eye;
global uniform vec3 cam_fwd;
varying flat float camera_cover;
// Issue 1361: per kind shape. > 0 thins the shorter axes (longer, sharper rocks); < 0 pulls the longer axes in toward
// the shortest (chunkier, heavier rocks). Every factor is at most 1, so a rock never outgrows its scale-table size.
uniform float shape_k = 0.0;
// Issue 1361: rock to rock tone (value jitter) and a second tint inside the kind's own palette
uniform float tone_var = 0.18;
uniform vec3 tint_var = vec3(1.0);
// #230 option B (issue #541): rocks turn at their stored rate under the cap law by default; VS_ROCK_TUMBLE=0 holds the pose.
uniform float tumble_k = 0.0;
uniform int kind = 0;
uniform vec3 base = vec3(0.09, 0.075, 0.062);
uniform vec3 fresh = vec3(0.16, 0.15, 0.14);
uniform sampler3D detail : filter_linear, repeat_enable;
uniform float q = 1.0;
// Only the living debris material enables this; blockers and far fields keep their finish.
uniform float debris_glint = 0.0;
uniform vec3 sun_v = vec3(0.45, 0.70, 0.55);
uniform bool legacy_debris = false;
uniform bool living_terrain = false;
uniform bool scanned = false;
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
varying float vScale;
uniform float amb = 0.5;       // r8: how much of the scene's flat ambient a rock takes (space rock is dark on its night side)
vec3 rot(vec3 v, vec3 ax, float a) { float c = cos(a); float s = sin(a); return v * c + cross(ax, v) * s + ax * dot(ax, v) * (1.0 - c); }
vec3 h33(vec3 p) { p = fract(p * vec3(0.1031, 0.1030, 0.0973)); p += dot(p, p.yxz + 33.33); return fract((p.xxy + p.yxx) * p.zyx); }
// r8: impact craters in the rock's own space (they stay on its surface): a bowl, a raised rim and a little ejecta, in
// cells of a 3D grid (about half the cells hold one). x: height (object units per cell), y: crater floor, z: rim
vec3 craters(vec3 p, float dens) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 o = vec3(0.0);
	for (int z = -1; z <= 1; z++) {
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec3 g = vec3(float(x), float(y), float(z));
				vec3 hs = h33(i + g);
				if (hs.z > dens) { continue; }
				vec3 c = g + 0.2 + 0.6 * h33(i + g + 17.3);
				float rad = 0.22 + 0.3 * hs.x * hs.x;
				float d = length(c - f) / rad;
				if (d < 1.8) {
					float bowl = d < 1.0 ? d * d - 1.0 : 0.0;
					float rim = exp(-pow((d - 1.0) / 0.2, 2.0));
					float ej = d > 1.0 ? exp(-(d - 1.0) * 4.0) * 0.12 : 0.0;
					o.x += (bowl * 0.55 + rim * 0.22 + ej) * rad * (0.6 + 0.6 * hs.y);
					o.y = max(o.y, d < 1.0 ? 1.0 - d * d : 0.0);
					o.z = max(o.z, rim);
				}
			}
		}
	}
	return o;
}
void vertex() {
	vL = VERTEX;
	vScale = length(MODEL_MATRIX[0].xyz);
	float radius = rock_radius * max(vScale, max(length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz)));
	// Artoo, PR 1306: measure from the gameplay camera the rig publishes, not this pass's own camera, so a shadow pass
	// (seen from the light) fades the rock exactly as the view does. Without a live rig, the pass's camera is used.
	vec3 eye = cam_eye.w > 0.5 ? cam_eye.xyz : CAMERA_POSITION_WORLD;
	vec3 fwd = cam_eye.w > 0.5 ? cam_fwd : -INV_VIEW_MATRIX[2].xyz;
	float clearance = distance(eye, MODEL_MATRIX[3].xyz) - radius;
	// Issue 1264: fade the whole instance before the live near plane (cam_near, set by camera_rig.gd: 1, 5 or 15 by
	// zoom since issue 368) can cut its surface. Depth along the view, not straight-line distance, is what the near
	// plane cuts, so a rock off to the side fades by its depth too.
	float depth_clear = dot(MODEL_MATRIX[3].xyz - eye, fwd) - radius;
	camera_cover = smoothstep(cam_near + 1.5, cam_near + 1.5 + max(1.0, radius * 0.25), min(clearance, depth_clear));
	vC = COLOR;
	vec4 ic = INSTANCE_CUSTOM;
	vSeed = ic.w;
	if (shape_k != 0.0) {
		// in the rock's own frame, before its turn, so the shape tumbles with it and never morphs
		vec3 e = max(rock_ext, vec3(1e-3));
		float k = shape_k * (0.6 + 0.8 * fract(ic.w * 431.7));
		vec3 sq = k > 0.0 ? pow(e / max(e.x, max(e.y, e.z)), vec3(k)) : pow(min(e.x, min(e.y, e.z)) / e, vec3(-k));
		sq = clamp(sq, vec3(0.55), vec3(1.0));
		// never flatter than DRAWN_ASPECT (rock_scan_check.gd checks the same rule on every kind's scans): a slab that
		// is already thin keeps its thinnest side at least that share of its longest drawn side
		vec3 d = e * sq;
		sq = min(max(sq, vec3(0.32 * max(d.x, max(d.y, d.z))) / e), vec3(1.0));
		VERTEX *= sq;
		NORMAL = normalize(NORMAL / sq);
	}
	float axis_length = length(ic.xyz);
	if (axis_length > 1e-6) {
		vec3 ax = ic.xyz / axis_length;
		float a = ic.w * 6.2831 + TIME * axis_length * tumble_k; // Keep the seeded starting pose; the slow law turns from it by default.
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
	// The legacy scatter and living clumps are alternative presentations of the same hexes.
	if (legacy_debris && living_terrain) { discard; }
	// Opaque screen-door fade: keep depth and back-face culling, never draw the inside to fill a cut.
	float screen_dither = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
	if (camera_cover <= screen_dither) { discard; }
	vec3 p = vL * 2.2 + vSeed * 13.7;
	float n1 = texture(detail, p * 0.21).r;
	float n2 = texture(detail, p * 0.73 + 0.31).r;
	// the finest grit fades out where it would shimmer (small on screen)
	float fw = length(fwidth(p * 2.6));
	float n3 = mix(texture(detail, p * 2.6 + 0.57).r, 0.5, clamp(fw * 1.2, 0.0, 1.0));
	float cav = vC.r;
	float crat = scanned ? 0.0 : vC.g;
	// r8: shader craters at two sizes, faded out where they would be smaller than a few pixels (no shimmer far away)
	vec3 cp = vL + vSeed * 7.31;
	float fwc = length(fwidth(cp));
	vec3 c1 = vec3(0.0);
	vec3 c2 = vec3(0.0);
	if (!scanned) {
		c1 = craters(cp * 2.6, 0.55);
		c2 = craters(cp * 7.5 + 3.1, 0.6);
	}
	float k1 = 1.0 - smoothstep(0.05, 0.14, fwc * 2.6);
	float k2 = 1.0 - smoothstep(0.04, 0.1, fwc * 7.5);
	float c_h = c1.x / 2.6 * k1 + c2.x / 7.5 * k2;
	float c_fl = max(c1.y * k1, c2.y * k2 * 0.7);
	float c_rim = max(c1.z * k1, c2.z * k2 * 0.7);
	crat = max(crat, c_fl * 0.8);
	float facet = vC.b;
	float patchv = vC.a;
	vec3 a = base * mix(0.72, 1.25, patchv) * (0.78 + 0.45 * n1) * (0.86 + 0.28 * n2);
	a *= 1.0 - crat * 0.25;
	// Issue 1361: rock to rock tone and tint inside the kind (seeded per instance, so a belt is not one rock repeated)
	vec3 rs = h33(vec3(vSeed * 97.31, vSeed * 13.7 + 3.1, 7.7));
	a *= (1.0 - tone_var) + 2.0 * tone_var * rs.x;
	a *= mix(vec3(1.0), tint_var, rs.y);
	// Issue 1361: crisp hairline cracks (a thin ridge of the noise), faded out where they would shimmer
	float ncr = texture(detail, p * 1.35 + 0.83).r;
	float crack_w = clamp(fw * 0.5, 0.0, 1.0);
	float cracks = smoothstep(0.972, 0.994, 1.0 - abs(ncr * 2.0 - 1.0)) * (1.0 - crack_w);
	float rough = 0.9;
	float metal = 0.0;
	vec3 em = vec3(0.0);
	float fr = clamp(facet * 0.8 + smoothstep(0.62, 0.8, n1) * 0.25, 0.0, 1.0);
	if (kind == 0) {
		a = mix(a, fresh * (0.85 + 0.3 * n2), smoothstep(0.35, 0.95, fr) * 0.75);
		a *= mix(vec3(1.0), vec3(1.06, 0.98, 0.9), smoothstep(0.4, 0.7, n2));
		// dark dust pockets in the hollows
		a *= mix(0.7, 1.0, smoothstep(0.05, 0.3, facet));
	} else if (kind == 1) {
		// Issue 1361: cool gunmetal slag crust; bright nickel-iron only on the fresh ridges (metallic 0.65 to 0.9)
		float m = clamp(smoothstep(0.66, 0.95, fr) + smoothstep(0.7, 0.8, n2) * 0.2, 0.0, 1.0);
		a = mix(a, fresh * (0.9 + 0.2 * n3), m);
		metal = mix(0.12, 0.88, m);
		rough = mix(0.8, 0.3, m) + n3 * 0.08;
	} else if (kind == 2) {
		// Issue 1361: deep charcoal, matte; ash-grey only on the sharpest ridges and a faint speckle
		a *= 1.0 + smoothstep(0.72, 0.86, n3) * 0.5;
		a = mix(a, fresh, smoothstep(0.6, 0.98, fr) * 0.55);
		rough = 0.94;
	} else if (kind == 3) {
		// r2: dark dusty crust, clean ice only in the fresh breaks and a few patches, frosty rather than glossy (r1's ice
		// covered most faces at roughness 0.2 and read as pale blue plastic)
		float ice = clamp(smoothstep(0.5, 0.95, fr) + smoothstep(0.7, 0.82, n1) * 0.3 - crat * 0.4, 0.0, 1.0);
		ice *= ice;
		a = mix(a, fresh * (0.8 + 0.3 * n2), ice);
		rough = mix(0.88, 0.42, ice);
		float crack = smoothstep(0.93, 0.985, 1.0 - abs(n2 * 2.0 - 1.0));
		em = glow_col * crack * ice * 0.05;
	} else {
		a = mix(a, fresh, smoothstep(0.4, 0.95, fr) * 0.5);
		// Issue 1361: thin veins seated in the crevices (the scan's low facet values), calibrated to the re-baked facet
		// spread so a rock carries a few lines, never a net over the whole surface
		float vein = smoothstep(0.972, 0.995, 1.0 - abs(n1 * 2.0 - 1.0)) * (1.0 - smoothstep(0.04, 0.16, facet));
		a = mix(a, glow_col * 0.08, vein * 0.6);
		em = glow_col * vein * 0.32;
		rough = mix(0.85, 0.45, fr);
	}
	a *= 1.0 - cracks * 0.6;
	// r8: fresh, lighter rock on crater rims, a little dust darkening their floors
	a *= (1.0 + c_rim * 0.35) * (1.0 - c_fl * 0.12);
	// r11: a warm cast on stone (the cool ambient and fill light turned it blue-grey). Issue 1361: stone only; it had
	// turned iron and carbon the same sandy tan, so three of the five belts read as one rock
	if (kind == 0) { a *= vec3(1.12, 1.0, 0.84); }
	a *= mix(0.4, 1.0, cav) * lift;
	// height in world units (object units times the rock's scale): craters plus grit, so the bump reads the same on a
	// pebble and on a mountain
	float ht = (c_h + (n2 - 0.5) * 0.05 + (n3 - 0.5) * 0.02 - crat * 0.01 - cracks * 0.012) * vScale;
	NORMAL = bump_normal(NORMAL, VERTEX, ht, q > 0.5 ? 1.0 : 0.6);
	ALBEDO = a;
	ROUGHNESS = rough;
	METALLIC = metal;
	// r2: a dull dielectric sheen (the default 0.5 caught the cold fill light and turned brown rock grey-blue)
	// r11: less for plain rock (its dull sheen picked up the blue of the sky and the fill light and read as frost)
	SPECULAR = kind == 3 ? 0.5 : (kind == 1 ? 0.45 : (kind == 2 ? 0.08 : 0.12));
	if (debris_glint > 0.0) {
		vec3 sun = normalize((VIEW_MATRIX * vec4(sun_v, 0.0)).xyz);
		vec3 half_v = normalize(sun + VIEW);
		float glint = pow(max(dot(NORMAL, half_v), 0.0), 96.0) * max(dot(NORMAL, sun), 0.0);
		em += vec3(0.55, 0.43, 0.25) * glint * fr * debris_glint;
	}
	// r8: the flat ambient (and the sky's reflection) cut on rock, more in its hollows; the key light keeps full strength,
	// so a rock has a lit side and a dark side like the ships do, instead of an evenly grey-blue lump
	AO = mix(0.35, 1.0, cav) * amb;
	AO_LIGHT_AFFECT = 0.0;
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
# Issue 1361: the clusters (world/tools/crystal_kit.py) grow out of a rough host collar; COLOR_0.r is 1 on crystal and 0 on
# that rock, B a per-prism value for inner depth. The glow is restrained (a lit core and fresnel edges, no flat cyan).
const CRYSTAL_SHADER := """
shader_type spatial;
render_mode cull_back;
instance uniform float rock_radius = 1.0;
global uniform float cam_near;
global uniform vec4 cam_eye;
global uniform vec3 cam_fwd;
varying flat float camera_cover;
uniform vec3 glow = vec3(0.3, 0.8, 1.0);
uniform vec3 edge = vec3(0.7, 0.45, 1.0);
// issue 1361: the collar is the crystal kind's own host rock (crystal_material sets it from KINDS), not a second copy
uniform vec3 host_rock = vec3(0.046, 0.049, 0.058);
uniform float tumble_k = 0.0;   // as ROCK_SHADER: turns at the stored rate unless VS_ROCK_TUMBLE=0 holds it
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
	float scale = max(length(MODEL_MATRIX[0].xyz), max(length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz)));
	float radius = rock_radius * scale;
	// Artoo, PR 1306: measure from the gameplay camera the rig publishes, not this pass's own camera, so a shadow pass
	// (seen from the light) fades the rock exactly as the view does. Without a live rig, the pass's camera is used.
	vec3 eye = cam_eye.w > 0.5 ? cam_eye.xyz : CAMERA_POSITION_WORLD;
	vec3 fwd = cam_eye.w > 0.5 ? cam_fwd : -INV_VIEW_MATRIX[2].xyz;
	float clearance = distance(eye, MODEL_MATRIX[3].xyz) - radius;
	// Issue 1264: as ROCK_SHADER, fade before the live near plane cuts the surface.
	float depth_clear = dot(MODEL_MATRIX[3].xyz - eye, fwd) - radius;
	camera_cover = smoothstep(cam_near + 1.5, cam_near + 1.5 + max(1.0, radius * 0.25), min(clearance, depth_clear));
	vec4 ic = INSTANCE_CUSTOM;
	vSeed = ic.w;
	float axis_length = length(ic.xyz);
	if (axis_length > 1e-6) {
		vec3 ax = ic.xyz / axis_length;
		float a = ic.w * 6.2831 + TIME * axis_length * tumble_k; // Crystal clusters turn with their rocks under the same law.
		VERTEX = rot(VERTEX, ax, a);
		NORMAL = rot(NORMAL, ax, a);
	}
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float screen_dither = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
	if (camera_cover <= screen_dither) { discard; }
	float up = vC.g;
	float glass = step(0.5, vC.r);
	float f = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.0);
	float depth = mix(0.55, 1.15, vC.b);
	// host collar: dark slate mineral rock, a little mottled
	vec3 rock = host_rock * (0.75 + 0.5 * vC.b);
	ALBEDO = mix(rock, vec3(0.02, 0.035, 0.05), glass);
	ROUGHNESS = mix(0.9, 0.06, glass);
	METALLIC = 0.0;
	// a constant: a varying SPECULAR rendered the whole cluster near black in the GL Compatibility renderer (issue 1361)
	SPECULAR = 0.6;
	// as ROCK_SHADER (r8): the flat ambient cut, so the collar sits as dark as its host rock and the glass stays dark
	AO = 0.4;
	AO_LIGHT_AFFECT = 0.0;
	float pulse = 0.88 + 0.12 * sin(TIME * 0.7 + vSeed * 17.0 + vC.b * 9.0);
	// restrained: dark glass with a lit core rising to the tips and thin fresnel edges, never a flat glowing surface
	vec3 core = glow * (0.01 + 0.35 * pow(up, 3.0)) * depth;
	vec3 rimc = mix(glow, edge, f) * f * 0.2;
	EMISSION = (core + rimc) * pulse * glass;
	float dist = length(vW - board_c);
	float below = -(vW.y - board_c.y);
	FOG = vec4(haze_col, clamp(smoothstep(haze_r.x, haze_r.y, dist) * 0.55 + smoothstep(60.0, 700.0, below) * 0.4, 0.0, 1.0) * haze_max);
}
"""

# per kind: base albedo (linear), fresh fracture colour, shader kind, shape (shape_k), tone jitter and second tint.
# Issue 1361: iron is cool gunmetal with nickel ridges, carbon charcoal, each with its own tint range (no shared tan).
const KINDS := {
	"stone": {"base": Vector3(0.125, 0.098, 0.074), "fresh": Vector3(0.29, 0.245, 0.2), "k": 0, "shape": 0.0, "tone": 0.2, "tint": Vector3(1.08, 0.96, 0.84)},
	"iron": {"base": Vector3(0.058, 0.061, 0.067), "fresh": Vector3(0.4, 0.395, 0.385), "k": 1, "shape": -0.35, "tone": 0.16, "tint": Vector3(0.94, 0.98, 1.06)},
	"carbon": {"base": Vector3(0.042, 0.041, 0.04), "fresh": Vector3(0.1, 0.1, 0.104), "k": 2, "shape": -0.12, "tone": 0.22, "tint": Vector3(0.94, 0.96, 1.02)},
	"ice": {"base": Vector3(0.07, 0.074, 0.084), "fresh": Vector3(0.6, 0.7, 0.8), "k": 3, "shape": 0.55, "tone": 0.16, "tint": Vector3(0.92, 1.0, 1.08)},
	"crystal": {"base": Vector3(0.046, 0.049, 0.058), "fresh": Vector3(0.13, 0.135, 0.15), "k": 4, "shape": 0.0, "tone": 0.15, "tint": Vector3(0.95, 0.98, 1.06)},
}

# Issue 1361: which scans each kind draws on, its most typical first (world.gd _pick weights the first ones double).
# By the scans' own boxes (scans.json ext): 02 is chunky and round, 05 and 01 thick, 04 long, 00 and 03 flat slabs.
const KIND_SCANS := {
	"stone": ["scan_02", "scan_00", "scan_01", "scan_03", "scan_04", "scan_05"],
	"iron": ["scan_02", "scan_05", "scan_01", "scan_04"],
	"carbon": ["scan_00", "scan_03", "scan_05", "scan_02"],
	"ice": ["scan_04", "scan_03", "scan_00", "scan_01"],
	"crystal": ["scan_01", "scan_05", "scan_02", "scan_04"],
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
	if not scans.is_empty() and OLD:
		return scans.duplicate()
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
	var kinds: Dictionary = _v1().KINDS if OLD else KINDS
	var K: Dictionary = kinds.get(kind, kinds["stone"])
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = _v1().ROCK_SHADER if OLD else ROCK_SHADER
	m.shader = sh
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


static func crystal_material(look: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = _v1().CRYSTAL_SHADER if OLD else CRYSTAL_SHADER
	m.shader = sh
	m.set_shader_parameter("tumble_k", rock_tumble_k)
	m.set_shader_parameter("board_c", look.get("board_c", Vector3.ZERO))
	m.set_shader_parameter("haze_col", look.get("haze", Vector3(0.01, 0.012, 0.02)))
	m.set_shader_parameter("haze_r", look.get("haze_r", Vector2(320, 2200)))
	m.set_shader_parameter("host_rock", (_v1().KINDS if OLD else KINDS)["crystal"]["base"])
	if look.has("glow"):
		m.set_shader_parameter("glow", look["glow"])
	return m


# ---------------------------------------------------------------- instanced layers

# Collects rock instances per (mesh, layer) and builds one MultiMeshInstance3D each.
class Batch:
	var groups := {}     # key -> {mesh, mat, shadow, xf: [], cd: []}
	var dust_materials := {}
	var legacy_debris_materials := {}

	func add(mesh_name: String, mat: Material, shadow: bool, xf: Transform3D, spin_axis: Vector3, rate: float, seed_v: float) -> void:
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
			# Bounds about the shader's origin, including off-center crystal clusters. A rigid seeded turn cannot escape it.
			var box := m.get_aabb()
			var radius := box.position.abs().max(box.end.abs()).length()
			mmi.set_instance_shader_parameter("rock_radius", radius)
			if g["mat"] is ShaderMaterial and (g["mat"] as ShaderMaterial).shader.code.contains("rock_ext"):
				mmi.set_instance_shader_parameter("rock_ext", box.size)
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if g["shadow"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# Give the bounds room for the shader's fixed seeded pose.
			mmi.extra_cull_margin = 40.0
			parent.add_child(mmi)
			n += mm.instance_count
		return n
