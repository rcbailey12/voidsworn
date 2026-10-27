extends RefCounted
# Shaders for the battle world (G4): the dead star (black hole with lensing and an accretion disc), faceted asteroids,
# the per-battle nebula sky and the backdrop planet.

const NOISE := """
float wh21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float wvn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(wh21(i), wh21(i + vec2(1.0, 0.0)), f.x), mix(wh21(i + vec2(0.0, 1.0)), wh21(i + vec2(1.0, 1.0)), f.x), f.y);
}
float wfbm(vec2 p) { float a = 0.5; float s = 0.0; for (int k = 0; k < 5; k++) { s += a * wvn(p); p = p * 2.03 + vec2(1.7, 9.2); a *= 0.5; } return s; }
// r6: Hoskins' hash13 (the old product hash drew diagonal lattice lines once a shader amplified the noise)
float wh31(vec3 p) { p = fract(p * 0.1031); p += dot(p, p.zyx + 31.32); return fract((p.x + p.y) * p.z); }
float wvn3(vec3 x) {
	vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(wh31(i), wh31(i + vec3(1.0, 0.0, 0.0)), f.x), mix(wh31(i + vec3(0.0, 1.0, 0.0)), wh31(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(wh31(i + vec3(0.0, 0.0, 1.0)), wh31(i + vec3(1.0, 0.0, 1.0)), f.x), mix(wh31(i + vec3(0.0, 1.0, 1.0)), wh31(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}
float wfbm3(vec3 p) { float a = 0.5; float s = 0.0; for (int k = 0; k < 5; k++) { s += a * wvn3(p); p = p * 2.03 + 3.1; a *= 0.5; } return s; }
"""

# The accretion disc. Opaque where it is dense (so the lensing pass can bend its far side over the shadow, the way a real
# black hole shows the back of its disc as an arc), cut away where thin. Differential rotation (inner faster), spiral
# turbulence, temperature falling outward (white-blue to orange to deep red), Doppler beaming (the side coming toward
# the camera is brighter and bluer). r_in, r_out in local units of the disc mesh (a flat annulus in xz).
const DISC := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
global uniform float scene_t;
""" + NOISE + """
uniform float r_in = 1.0;
uniform float r_out = 3.0;
uniform float spin = 0.25;
uniform float gain = 1.0;
uniform vec3 hot = vec3(1.0, 0.92, 0.8);
uniform vec3 warm = vec3(1.0, 0.55, 0.2);
uniform vec3 cool = vec3(0.55, 0.12, 0.04);
uniform float front_only = 0.0;
uniform vec3 hole_center = vec3(0.0);
varying vec3 vL;
varying vec3 vW;
void vertex() { vL = VERTEX; vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
vec3 disc_col(vec2 q, out float dens) {
	float r = length(q);
	float u = clamp((r - r_in) / (r_out - r_in), 0.0, 1.0);
	float ang = atan(q.y, q.x);
	float w = spin / pow(max(r / r_in, 1.0), 1.5);
	float a2 = ang + scene_t * w;
	float sp = wfbm(vec2(a2 * 3.0 + log(r) * 6.0, r * 1.5));
	float sp2 = wfbm(vec2(a2 * 7.0 - log(r) * 4.0, r * 4.0 + 3.0));
	dens = smoothstep(0.0, 0.06, u) * (1.0 - smoothstep(0.7, 1.0, u)) * (0.55 + 0.7 * sp) * (0.75 + 0.45 * sp2);
	vec3 c = mix(hot, warm, smoothstep(0.0, 0.3, u));
	c = mix(c, cool, smoothstep(0.3, 1.0, u));
	return c * (2.6 - 2.0 * u);
}
void fragment() {
	vec2 q = vL.xz;
	float dens;
	vec3 c = disc_col(q, dens);
	// Doppler beaming: the gas moving toward the camera brightens and blues
	vec3 tang = normalize((MODEL_MATRIX * vec4(-q.y, 0.0, q.x, 0.0)).xyz);
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	float dop = dot(tang, V);
	c *= 1.0 + 0.85 * dop;
	c = mix(c, c * vec3(0.8, 0.95, 1.25), clamp(dop, 0.0, 1.0) * 0.4);
	if (front_only > 0.5) {
		// the overlay: only the half of the disc between the camera and the hole
		vec3 toHole = hole_center - CAMERA_POSITION_WORLD;
		vec3 toFrag = vW - CAMERA_POSITION_WORLD;
		if (length(toFrag) > length(toHole)) { discard; }
	}
	if (dens < 0.035) { discard; }
	ALBEDO = c * dens * gain;
}
"""

# Front-half overlay of the disc, drawn after the lensing pass (additive), so the near side of the disc stays in front.
const DISC_FRONT := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
global uniform float scene_t;
""" + NOISE + """
uniform float r_in = 1.0;
uniform float r_out = 3.0;
uniform float spin = 0.25;
uniform float gain = 1.0;
uniform vec3 hot = vec3(1.0, 0.92, 0.8);
uniform vec3 warm = vec3(1.0, 0.55, 0.2);
uniform vec3 cool = vec3(0.55, 0.12, 0.04);
uniform vec3 hole_center = vec3(0.0);
varying vec3 vL;
varying vec3 vW;
void vertex() { vL = VERTEX; vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 q = vL.xz;
	float r = length(q);
	float u = clamp((r - r_in) / (r_out - r_in), 0.0, 1.0);
	float ang = atan(q.y, q.x);
	float w = spin / pow(max(r / r_in, 1.0), 1.5);
	float a2 = ang + scene_t * w;
	float sp = wfbm(vec2(a2 * 3.0 + log(r) * 6.0, r * 1.5));
	float sp2 = wfbm(vec2(a2 * 7.0 - log(r) * 4.0, r * 4.0 + 3.0));
	float dens = smoothstep(0.0, 0.08, u) * (1.0 - smoothstep(0.75, 1.0, u)) * (0.45 + 0.75 * sp) * (0.7 + 0.5 * sp2);
	vec3 c = mix(hot, warm, smoothstep(0.0, 0.35, u));
	c = mix(c, cool, smoothstep(0.35, 1.0, u)) * (2.4 - 1.8 * u);
	vec3 tang = normalize((MODEL_MATRIX * vec4(-q.y, 0.0, q.x, 0.0)).xyz);
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	float dop = dot(tang, V);
	c *= 1.0 + 0.85 * dop;
	vec3 toHole = hole_center - CAMERA_POSITION_WORLD;
	vec3 toFrag = vW - CAMERA_POSITION_WORLD;
	float front = smoothstep(0.0, 0.08 * length(toHole), length(toHole) - length(toFrag));
	ALBEDO = c * dens * gain * front * 0.9;
}
"""

# Gravitational lensing: a camera-facing quad over the hole bends the picture behind it. For a point lens, a ray seen at
# angle theta from the hole comes from beta = theta - thetaE^2 / theta, so the background is pushed outward round the
# Einstein ring and pulled from the far side inside it. Inside the shadow (about 2.6 Schwarzschild radii, projected)
# nothing escapes: black, ringed by the thin bright photon ring.
const LENS := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
global uniform float scene_t;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform float r_shadow = 0.12;   // shadow radius as a fraction of the quad's half size
uniform float r_einstein = 0.2;
uniform float photon = 1.0;
uniform vec3 ring_col = vec3(1.0, 0.8, 0.55);
varying vec2 vUv;
varying vec4 vCenterClip;
varying float vHalf;
void vertex() {
	vec3 c = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float half_size = length(MODEL_MATRIX[0].xyz);
	vec4 vp = VIEW_MATRIX * vec4(c, 1.0);
	vp.xy += VERTEX.xy * half_size * 2.0;
	POSITION = PROJECTION_MATRIX * vp;
	vCenterClip = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(c, 1.0));
	vUv = VERTEX.xy * 2.0;
	vHalf = half_size;
}
void fragment() {
	float r = length(vUv);
	if (r > 1.0) { discard; }
	vec2 cs = vCenterClip.xy / vCenterClip.w * 0.5 + 0.5;
	vec2 d = SCREEN_UV - cs;
	// screen offset per unit of r (the quad's half size projected)
	float k = length(d) / max(r, 1e-4);
	vec2 dir = r > 1e-4 ? d / length(d) : vec2(0.0);
	float th = r;
	float re2 = r_einstein * r_einstein;
	float beta = th - re2 / max(th, 1e-3);
	// fade the bending out toward the quad edge so there is no seam
	float edge = smoothstep(1.0, 0.6, r);
	float b = mix(th, beta, edge);
	vec2 suv = cs + dir * b * k;
	// only what lies behind the hole is bent: a pixel from something in front of it (a ship) is not used
	float hole_z = -(VIEW_MATRIX * vec4((MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz, 1.0)).z;
	float dsrc = texture(depth_tex, suv).r;
	vec4 vsrc = INV_PROJECTION_MATRIX * vec4(suv * 2.0 - 1.0, dsrc, 1.0);
	float src_z = -vsrc.z / vsrc.w;
	if (src_z < hole_z * 0.98) { suv = SCREEN_UV + dir * 0.02 * edge; }
	vec3 col = textureLod(screen_tex, suv, 0.0).rgb;
	// a little extra brightening near the Einstein ring (lensing magnifies)
	float mag = 1.0 + 0.6 * exp(-pow((th - r_einstein) / (r_einstein * 0.35), 2.0)) * edge;
	col *= mag;
	// the shadow and the photon ring
	float sh = smoothstep(r_shadow * 1.02, r_shadow * 0.98, th);
	float ring = exp(-pow((th - r_shadow * 1.05) / (r_shadow * 0.035), 2.0)) * photon;
	float ring2 = exp(-pow((th - r_shadow * 1.12) / (r_shadow * 0.08), 2.0)) * photon * 0.35;
	col = mix(col, vec3(0.0), sh) + ring_col * (ring * 6.0 + ring2 * 2.0) * (0.92 + 0.08 * sin(scene_t * 0.7));
	ALBEDO = col;
	ALPHA = smoothstep(1.0, 0.85, r);
}
"""

# Faceted asteroid: flat faces (the mesh is split per face), a rock albedo with strata and grit from triplanar noise,
# darker in the cracks, and for crystal rocks glowing spikes. kind: 0 stone, 1 ice, 2 iron, 3 carbon, 4 crystal.
const ROCK := """
shader_type spatial;
render_mode cull_back;
""" + NOISE + """
uniform vec3 base = vec3(0.3, 0.28, 0.26);
uniform int kind = 0;
uniform float seed = 0.0;
varying vec3 vL;
varying vec3 vN;
void vertex() { vL = VERTEX; vN = NORMAL; }
void fragment() {
	vec3 p = vL * 1.3 + seed;
	float n = wfbm3(p * 1.7);
	float g = wfbm3(p * 9.0);
	float strata = 0.5 + 0.5 * sin(vL.y * 7.0 + n * 3.0);
	vec3 a = base * (0.55 + 0.45 * n) * (0.8 + 0.3 * g);
	float rough = 0.85;
	float metal = 0.0;
	if (kind == 0) { a *= 0.85 + 0.25 * strata; }
	if (kind == 1) { a = mix(a, vec3(0.75, 0.85, 0.95), 0.25 + 0.2 * n); rough = 0.35; }
	if (kind == 2) { metal = 0.75; rough = 0.45; a *= 0.9 + 0.2 * g; }
	if (kind == 3) { rough = 0.95; }
	ALBEDO = a;
	ROUGHNESS = rough;
	METALLIC = metal;
	// crack lines: ice glows faintly cold, crystal veins glow
	float crack = smoothstep(0.95, 0.992, 1.0 - abs(wfbm3(p * 2.2) * 2.0 - 1.0));
	if (kind == 1) { EMISSION = vec3(0.12, 0.3, 0.45) * crack * 0.6; }
	if (kind == 4) { EMISSION = vec3(0.2, 0.9, 0.7) * crack * 0.9; }
}
"""

const CRYSTAL := """
shader_type spatial;
render_mode cull_back;
uniform vec3 glow = vec3(0.2, 0.9, 0.7);
void fragment() {
	ALBEDO = vec3(0.05, 0.12, 0.1);
	ROUGHNESS = 0.15;
	METALLIC = 0.2;
	float f = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.0);
	EMISSION = glow * (0.4 + 1.6 * f);
}
"""

# The battle sky: the painted starfield (if given) darkened, with nebula banks tinted per enemy faction (the browser
# game's BIOMES palette), a faint galactic band, and no moving parts (radiance is computed once).
const SKY := """
shader_type sky;
render_mode use_quarter_res_pass;
""" + NOISE + """
uniform sampler2D pano : source_color, filter_linear_mipmap, repeat_enable;
uniform float has_pano = 0.0;
uniform float pano_k = 0.75;
uniform vec3 c1 = vec3(0.13, 0.26, 0.6);
uniform vec3 c2 = vec3(0.62, 0.22, 0.45);
uniform vec3 c3 = vec3(1.0, 0.64, 0.36);
uniform float neb_k = 0.08;
uniform float seed = 0.0;
uniform vec3 sun_dir = vec3(0.45, 0.7, 0.55);
uniform vec3 sun_col = vec3(1.0, 0.9, 0.75);
float stars(vec3 d, float scale, float thr) {
	vec3 p = d * scale;
	vec3 i = floor(p);
	float h = wh31(i + seed);
	vec3 f = fract(p) - 0.5 - (vec3(wh31(i + 1.3), wh31(i + 2.7), wh31(i + 4.1)) - 0.5) * 0.7;
	float s = smoothstep(thr, 1.0, h) * exp(-dot(f, f) * 140.0);
	return s;
}
void sky() {
	vec3 d = EYEDIR;
	vec3 col = vec3(0.0);
	if (has_pano > 0.5) {
		// a contrast curve: faint stars (the "snow") drop away, bright ones stay; the sky between goes darker
		vec3 pc = texture(pano, SKY_COORDS).rgb;
		float lum = max(pc.r, max(pc.g, pc.b));
		float keep = smoothstep(0.12, 0.55, lum);
		col = min(pc * keep * keep, vec3(0.78)) * pano_k + pc * 0.04;
	} else {
		col += vec3(stars(d, 220.0, 0.985)) * 1.2 + vec3(stars(d, 520.0, 0.993)) * 0.7;
	}
	if (AT_QUARTER_RES_PASS || true) {
		float band = exp(-pow(dot(d, normalize(vec3(0.2, 0.9, -0.35))) / 0.28, 2.0));
		float n1 = wfbm3(d * 2.2 + seed);
		float n2 = wfbm3(d * 4.8 + seed * 1.7 + 5.0);
		float neb = smoothstep(0.45, 0.85, n1 * 0.7 + n2 * 0.5) * (0.35 + 0.65 * band);
		vec3 nc = mix(c1, c2, smoothstep(0.3, 0.7, n2));
		nc = mix(nc, c3, smoothstep(0.72, 0.95, n1) * 0.5);
		col += nc * neb * neb_k;
		col += mix(c1, c3, 0.3) * band * 0.012;
	}
	float sd = max(dot(d, normalize(sun_dir)), 0.0);
	col += sun_col * (pow(sd, 900.0) * 6.0 + pow(sd, 40.0) * 0.05);
	COLOR = col;
}
"""

# A backdrop planet far out: banded gas giant or rocky world with an atmosphere rim, lit by the key light.
const PLANET := """
shader_type spatial;
render_mode cull_back, shadows_disabled;
""" + NOISE + """
uniform vec3 a = vec3(0.6, 0.45, 0.3);
uniform vec3 b = vec3(0.3, 0.2, 0.15);
uniform vec3 atmo = vec3(0.4, 0.6, 1.0);
uniform float gas = 1.0;
uniform float seed = 0.0;
varying vec3 vL;
void vertex() { vL = VERTEX; }
void fragment() {
	vec3 p = normalize(vL);
	float n = wfbm3(p * 3.0 + seed);
	float t = gas > 0.5 ? wfbm(vec2(p.y * 9.0 + n * 1.4, seed)) : wfbm3(p * 6.0 + seed);
	ALBEDO = mix(b, a, smoothstep(0.3, 0.7, t)) * (0.8 + 0.4 * n);
	ROUGHNESS = 0.9;
	float f = pow(1.0 - abs(dot(NORMAL, VIEW)), 3.0);
	EMISSION = atmo * f * 0.25;
}
"""
