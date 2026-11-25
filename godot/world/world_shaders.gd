extends RefCounted
# Shaders for the battle world (G4): the dead star (black hole with lensing and an accretion disc), faceted asteroids,
# the per-battle nebula sky and the backdrop planet.

const HASH_SCALE := "0.1031"
const HASH_BIAS := "31.32"
const NOISE_HASH := """
float wh21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float wvn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	ivec2 ic = ivec2(i);   // whole-number corners, as wvn3 below (issue 1939)
	return mix(mix(wh21(vec2(ic)), wh21(vec2(ic + ivec2(1, 0))), f.x), mix(wh21(vec2(ic + ivec2(0, 1))), wh21(vec2(ic + ivec2(1, 1))), f.x), f.y);
}
float wfbm(vec2 p) { float a = 0.5; float s = 0.0; for (int k = 0; k < 5; k++) { s += a * wvn(p); p = p * 2.03 + vec2(1.7, 9.2); a *= 0.5; } return s; }
// r6: Hoskins' hash13 (the old product hash drew diagonal lattice lines once a shader amplified the noise)
float wh31(vec3 p) {
	p = fract(p * """ + HASH_SCALE + """);
	p += dot(p, p.zyx + """ + HASH_BIAS + """);
	return fract((p.x + p.y) * p.z);
}
"""
const NOISE_CELL := """
float wvn3(vec3 x) {
	vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
"""
# Issue 1939 (Neon, PR 1979 review): on the RTX 5080 the compiler folded "i + offset" into the hash's multiply (one fused
# multiply-add), so a lattice corner hashed from the cell on one side came out a hair different from the same corner
# hashed from the other side; the hash amplifies that ten thousand times and wrapped it, cutting straight seams and
# triangles through clouds, coasts and ash. Each corner is now added up in whole numbers and only then turned into a
# float, so both sides hash exactly the same value. The noise itself is unchanged.
const NOISE_INTERPOLATE := """
	ivec3 ic = ivec3(i);
	return mix(mix(mix(wh31(vec3(ic)), wh31(vec3(ic + ivec3(1, 0, 0))), f.x), mix(wh31(vec3(ic + ivec3(0, 1, 0))), wh31(vec3(ic + ivec3(1, 1, 0))), f.x), f.y),
		mix(mix(wh31(vec3(ic + ivec3(0, 0, 1))), wh31(vec3(ic + ivec3(1, 0, 1))), f.x), mix(wh31(vec3(ic + ivec3(0, 1, 1))), wh31(vec3(ic + ivec3(1, 1, 1))), f.x), f.y), f.z);
}
float wfbm3(vec3 p) { float a = 0.5; float s = 0.0; for (int k = 0; k < 5; k++) { s += a * wvn3(p); p = p * 2.03 + 3.1; a *= 0.5; } return s; }
"""
const NOISE := NOISE_HASH + NOISE_CELL + NOISE_INTERPOLATE

# High gas uses the same hash at the same lattice corners and the same easing.
# Texture filtering interpolates those corners. Outside the baked region the
# original procedural calculation supplies the field, even at long play times.
const NOISE_LATTICE := NOISE_HASH + """
uniform sampler3D gas_hash_lattice : filter_linear, repeat_disable;
uniform vec3 gas_hash_origin;
""" + NOISE_CELL + """
	vec3 tile = i - gas_hash_origin;
	vec3 size = vec3(textureSize(gas_hash_lattice, 0));
	if (all(greaterThanEqual(tile, vec3(0.0))) && all(lessThan(tile, size - vec3(1.0)))) {
		return textureLod(gas_hash_lattice, (tile + f + vec3(0.5)) / size, 0.0).r;
	}
""" + NOISE_INTERPOLATE

# The accretion disc. Opaque where it is dense (so the lensing pass can bend its far side over the shadow, the way a real
# black hole shows the back of its disc as an arc), cut away where thin. Differential rotation (inner faster), spiral
# turbulence, temperature falling outward (white-blue to orange to deep red), Doppler beaming (the side coming toward
# the camera is brighter and bluer). r_in, r_out in local units of the disc mesh (a flat annulus in xz).
const DISC := preload("res://shaders/dead_star_disc.gdshader")

const DISC_SOFT := preload("res://shaders/dead_star_disc_soft.gdshader")

const DISC_HAZE := preload("res://shaders/dead_star_disc_haze.gdshader")

# Gravitational lensing: a camera-facing quad over the hole bends the picture behind it. For a point lens, a ray seen at
# angle theta from the hole comes from beta = theta - thetaE^2 / theta, so the background is pushed outward round the
# Einstein ring and pulled from the far side inside it. Inside the shadow (about 2.6 Schwarzschild radii, projected)
# nothing escapes: black, ringed by the thin bright photon ring.
const LENS := preload("res://shaders/dead_star_lens.gdshader")

# Asteroid rock (r8, matching G3's campaign map rocks, map3d_shaders.gd ROCK_HI): strata and dust from 3D noise, fine
# grit and pitting in the lighting (a bump from the same noise), darker dusty crater floors and brighter worn rims (the
# mesh's COLOR.r and .g), albedo and roughness varied across the body, and a warm rim from the dead star's disc when the
# board has one (rim_pos, its world position; rim_k 0 without it). kind: 0 stone, 1 ice, 2 iron, 3 carbon, 4 crystal.
const ROCK := """
shader_type spatial;
render_mode cull_back;
""" + NOISE + """
uniform vec3 base = vec3(0.3, 0.28, 0.26);
uniform int kind = 0;
uniform float seed = 0.0;
uniform float q = 1.0;
uniform vec3 rim_pos = vec3(0.0);
uniform vec3 rim_col = vec3(1.0, 0.6, 0.3);
uniform float rim_k = 0.0;
varying vec3 vL;
varying vec3 vW;
varying vec2 vC;
void vertex() { vL = VERTEX; vC = COLOR.rg; vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
vec3 bump_normal(vec3 n, vec3 pos, float h, float k) {
	vec3 dpdx = dFdx(pos); vec3 dpdy = dFdy(pos);
	float dhx = dFdx(h); float dhy = dFdy(h);
	vec3 r1 = cross(dpdy, n); vec3 r2 = cross(n, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dhx * r1 + dhy * r2);
	return normalize(abs(det) * n - grad * k);
}
void fragment() {
	vec3 p = vL * 1.3 + seed;
	float dust = wfbm3(p * 2.6);
	float grit = wfbm3(p * 8.0 + 5.0);
	float strata = 0.5 + 0.5 * sin(vL.y * 9.0 + wfbm3(p * 1.5) * 6.0);
	float crater = vC.x;
	float rimw = vC.y;
	vec3 a = base * (0.7 + 0.45 * dust) * (0.86 + 0.2 * strata) * (0.85 + 0.3 * grit);
	// broad patches of lighter and darker regolith across the body
	float patchv = smoothstep(0.35, 0.7, wfbm3(p * 0.8 + 11.0));
	a *= mix(0.8, 1.2, patchv);
	a *= 1.0 - crater * 0.6;
	a *= 1.0 + rimw * 0.25;
	float rough = mix(0.82, 0.95, dust);
	float metal = 0.0;
	if (kind == 0) { a = mix(a, a * vec3(1.08, 0.98, 0.9), strata * 0.5); }
	if (kind == 1) { a = mix(a, vec3(0.7, 0.8, 0.9), smoothstep(0.4, 0.7, dust) * 0.55); rough = mix(0.3, 0.6, crater + grit * 0.4); }
	if (kind == 2) { metal = mix(0.35, 0.75, smoothstep(0.45, 0.7, grit)); rough = mix(0.4, 0.75, dust); a = mix(a, vec3(0.3, 0.2, 0.14), smoothstep(0.55, 0.8, grit) * 0.4); }
	if (kind == 3) { rough = 0.95; a *= mix(0.9, 1.4, smoothstep(0.6, 0.8, grit)); }
	// pitting and grit in the lighting
	float ht = grit * 0.35 + dust * 0.4 - smoothstep(0.6, 0.72, wfbm3(p * 5.0 + 3.0)) * 0.25;
	if (q > 0.5) { ht += wfbm3(p * 22.0) * 0.12; }
	NORMAL = bump_normal(NORMAL, VERTEX, ht, q > 0.5 ? 0.5 : 0.3);
	ALBEDO = a;
	ROUGHNESS = rough;
	METALLIC = metal;
	// crack lines: ice glows faintly cold, crystal veins glow
	float crack = smoothstep(0.95, 0.992, 1.0 - abs(wfbm3(p * 2.2) * 2.0 - 1.0));
	vec3 em = vec3(0.0);
	if (kind == 1) { em = vec3(0.12, 0.3, 0.45) * crack * 0.6; }
	if (kind == 4) { em = vec3(0.2, 0.9, 0.7) * crack * 0.9; }
	// the disc's warm light on the side facing it, strongest at the silhouette (a rim), fading with distance
	if (rim_k > 0.0) {
		vec3 nw = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		vec3 L = rim_pos - vW;
		float dl = length(L);
		L /= max(dl, 1e-3);
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
		float face = clamp(dot(nw, L) * 0.8 + 0.2, 0.0, 1.0);
		float fall = 1.0 / (1.0 + dl * dl / 40000.0);
		em += rim_col * rim_k * face * (0.06 + 0.9 * fres) * fall * (0.6 + 0.4 * (1.0 - crater));
	}
	EMISSION = em;
}
"""
