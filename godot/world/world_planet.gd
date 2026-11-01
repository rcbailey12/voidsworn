extends RefCounted
# F4 planets: the system's planet (gas giant, ice giant, terran, volcanic, barren or ice world, from the sector's biome),
# its rings and its moons, far beyond the board.
#
# Each surface is baked once on the GPU (world_bake.gd) into two equirectangular pictures:
#   A: albedo (rgb, gamma) and ocean (a)        B: clouds (r), city lights (g), relief (b), lava glow (a)
# and drawn by a sphere shader that lights it from the battle's key light: a soft terminator, cloud shadows, the sun's
# glint on oceans, city lights and lava on the night side, the atmosphere's blue or amber haze on the lit limb, and the
# rings' shadow. Rings are lit, see-through and shadowed by the planet. Moons share one baked cratered surface, each
# tinted and turned its own way (never two that look alike).

const NOISE := preload("res://world/world_shaders.gd")

static func bake_code() -> String:
	return BAKE_HEAD + NOISE.NOISE + BAKE_BODY


const BAKE_HEAD := """
shader_type canvas_item;
render_mode unshaded, blend_disabled;
"""
const BAKE_BODY := """
uniform vec2 full_size = vec2(2048.0, 1024.0);
uniform float strip_y0 = 0.0;
uniform float strip_h = 1024.0;
uniform float seed = 0.0;
uniform int kind = 0;       // 0 gas giant, 1 ice giant, 2 terran, 3 volcanic desert, 4 barren cratered, 5 ice world
uniform int pass_id = 0;    // 0: albedo + ocean, 1: clouds, lights, relief, lava
uniform vec3 ca = vec3(0.7, 0.6, 0.4);
uniform vec3 cb = vec3(0.4, 0.3, 0.2);
uniform vec3 cc = vec3(0.9, 0.85, 0.7);

float fb(vec3 p, int oct) { float a = 0.5; float s = 0.0; for (int k = 0; k < 8; k++) { if (k >= oct) break; s += a * wvn3(p); p = p * 2.03 + 1.7; a *= 0.5; } return s; }
float rg(vec3 p, int oct) { float a = 0.5; float s = 0.0; for (int k = 0; k < 6; k++) { if (k >= oct) break; float v = 1.0 - abs(wvn3(p) * 2.0 - 1.0); s += a * v * v; p = p * 2.1 + 3.3; a *= 0.5; } return s; }
float hh(vec3 p) { p = fract(p * 0.1031); p += dot(p, p.zyx + 31.32); return fract((p.x + p.y) * p.z); }

vec3 dir_of(vec2 uv) {
	float phi = (uv.x - 0.5) * 6.28318530718;
	float th = uv.y * 3.14159265359;
	return vec3(sin(th) * sin(phi), cos(th), -sin(th) * cos(phi));
}

// a crater field on the sphere: bowls with rims, many sizes (cells of a 3D grid at three scales)
float craters(vec3 d, float scale, float dens) {
	vec3 p = d * scale;
	vec3 b = floor(p - 0.5);
	float h = 0.0;
	for (int i = 0; i < 8; i++) {
		vec3 c = b + vec3(float(i & 1), float((i >> 1) & 1), float((i >> 2) & 1));
		float k = hh(c + seed);
		if (k > dens) continue;
		vec3 cp = normalize(c + 0.25 + 0.5 * vec3(hh(c + 1.3), hh(c + 2.9), hh(c + 5.1)));
		float r = (0.18 + 0.3 * hh(c + 7.7)) / scale;
		float u = acos(clamp(dot(d, cp), -1.0, 1.0)) / r;
		h += (u < 1.0 ? -(1.0 - u * u) : 0.0) * 0.6 + exp(-pow((u - 1.0) / 0.2, 2.0)) * 0.25;
	}
	return h;
}

void fragment() {
	vec2 px = vec2(UV.x * full_size.x, strip_y0 + UV.y * strip_h);
	vec3 d = dir_of(px / full_size);
	vec3 q = d + seed * 0.37;
	vec3 alb = ca;
	float ocean = 0.0;
	float cloud = 0.0;
	float lights = 0.0;
	float relief = 0.5;
	float lava = 0.0;
	if (kind == 0 || kind == 1) {
		// banded giants: belts and zones bent by turbulence at two scales, festoons and long streaks along the flow,
		// eddies at the band edges, one great storm and a few white ovals
		float g = kind == 0 ? 1.0 : 0.45;
		vec3 w1 = vec3(fb(q * 2.2, 4), fb(q * 2.2 + 7.0, 4), 0.0) - 0.5;
		vec3 w2 = vec3(fb(vec3(d.x * 6.0, d.y * 18.0, d.z * 6.0) + 11.0, 4), 0.0, 0.0) - 0.5;
		float latw = d.y + (w1.x * 0.09 + w2.x * 0.035) * g;
		float belts = 0.5 + 0.5 * sin(latw * (kind == 0 ? 15.0 : 8.0) + fb(vec3(latw * 3.0, seed, 0.0), 3) * 5.0);
		float stream = fb(vec3(d.x * 3.0, latw * 55.0, d.z * 3.0) + w1 * 2.0 + seed, 5);
		float fest = fb(vec3(d.x * 9.0, latw * 120.0, d.z * 9.0) + w2 * 3.0, 3);
		float t = clamp(belts * 0.75 + (stream - 0.5) * 0.55 * g + (fest - 0.5) * 0.25 * g + 0.1, 0.0, 1.0);
		alb = t < 0.5 ? mix(cb, ca, t * 2.0) : mix(ca, cc, (t - 0.5) * 2.0);
		alb *= 0.9 + 0.2 * fb(q * 5.0 + 3.0, 3);
		for (int i = 0; i < 5; i++) {
			vec3 sc = normalize(vec3(hh(vec3(float(i), seed, 1.0)) - 0.5, (hh(vec3(float(i), seed, 2.0)) - 0.5) * 1.1, hh(vec3(float(i), seed, 3.0)) - 0.5));
			float sr = i == 0 ? 0.13 : 0.025 + 0.03 * hh(vec3(float(i), seed, 4.0));
			vec3 e1 = normalize(cross(vec3(0.0, 1.0, 0.0), sc));
			vec3 e2 = cross(sc, e1);
			vec2 sq = vec2(dot(d, e1) / 2.0, dot(d, e2)) / sr;
			float sd = length(sq);
			if (dot(d, sc) > 0.0 && sd < 1.8) {
				float sw = atan(sq.y, sq.x) + sd * 2.5;
				float curl = fb(vec3(cos(sw) * sd, sin(sw) * sd, float(i)) * 3.0, 4);
				vec3 scol = i == 0 ? mix(cb * 1.3, vec3(0.78, 0.38, 0.22), 0.6) : mix(cc, vec3(0.97), 0.5);
				float inside = smoothstep(1.15, 0.75, sd);
				alb = mix(alb, scol * (0.8 + 0.4 * curl), inside * (kind == 0 ? 0.9 : 0.55));
				alb = mix(alb, cc, smoothstep(1.6, 1.1, sd) * (1.0 - inside) * 0.35 * curl);
			}
		}
		relief = 0.5 + (stream - 0.5) * 0.4;
	} else if (kind == 2) {
		// terran: continents from warped noise, mountains, ice caps, deserts by latitude, deep and shallow seas
		vec3 w = vec3(fb(q * 1.2, 4), fb(q * 1.2 + 5.0, 4), fb(q * 1.2 + 9.0, 4)) - 0.5;
		float h = fb(q * 1.5 + w * 1.4, 7) + rg(q * 3.0 + w, 4) * 0.12 - 0.06;
		float sea = 0.52;
		float lat = abs(d.y);
		if (h < sea) {
			float dep = clamp((sea - h) * 5.0, 0.0, 1.0);
			alb = mix(vec3(0.05, 0.16, 0.2), vec3(0.008, 0.03, 0.07), smoothstep(0.0, 0.35, dep));
			ocean = 1.0;
		} else {
			float e = clamp((h - sea) * 4.0, 0.0, 1.0);
			float dry = smoothstep(0.48, 0.66, fb(q * 2.2 + 3.0 + w, 4)) * (1.0 - smoothstep(0.55, 0.8, lat));
			vec3 green = ca * (0.75 + 0.5 * fb(q * 7.0 + 1.0, 3));
			vec3 sand = cc * (0.85 + 0.3 * fb(q * 9.0, 3));
			alb = mix(green, sand, dry);
			alb = mix(alb, vec3(0.32, 0.29, 0.26), smoothstep(0.35, 0.8, e));
			relief = 0.5 + e * 0.5;
			// cities: hive sprawl along coasts and in clusters (a contested, crowded world)
			float coast = smoothstep(0.08, 0.0, h - sea);
			float cl = smoothstep(0.55, 0.8, fb(q * 18.0 + 2.0, 4)) * (0.4 + coast);
			lights = clamp(cl * smoothstep(0.75, 0.6, lat) * (0.6 + 0.6 * hh(floor(d * 900.0))), 0.0, 1.0);
		}
		float ice = smoothstep(0.88, 0.94, lat + (fb(q * 6.0, 3) - 0.5) * 0.1);
		alb = mix(alb, vec3(0.85, 0.88, 0.92), ice);
		ocean *= 1.0 - ice;
		// clouds: swirling bands and storm cells
		vec3 cw = vec3(fb(q * 2.0 + 13.0, 3), fb(q * 2.0 + 17.0, 3), 0.0) - 0.5;
		float c = fb(vec3(d.x * 3.0, d.y * 7.0, d.z * 3.0) + cw * 2.5 + 19.0, 6);
		cloud = smoothstep(0.48, 0.72, c) * 0.95;
	} else if (kind == 3) {
		// volcanic desert: rust plains, dark basalt flows, canyons, glowing fissures
		vec3 w = vec3(fb(q * 1.5, 4), fb(q * 1.5 + 5.0, 4), 0.0) - 0.5;
		float h = fb(q * 2.0 + w, 6);
		float can = rg(q * 4.0 + w * 2.0, 5);
		alb = mix(cb, ca, smoothstep(0.35, 0.65, h));
		alb = mix(alb, cc, smoothstep(0.7, 0.9, fb(q * 6.0 + 2.0, 3)) * 0.5);
		alb *= mix(0.55, 1.0, smoothstep(0.85, 0.6, can));
		relief = h;
		lava = smoothstep(0.88, 0.97, can) * smoothstep(0.45, 0.3, h);
		cloud = smoothstep(0.62, 0.8, fb(q * 3.0 + 9.0 + w, 4)) * 0.35;
	} else if (kind == 4) {
		// barren cratered: highlands and dark maria, three sizes of crater
		float m = smoothstep(0.45, 0.6, fb(q * 1.3, 4));
		float cr = craters(d, 6.0, 0.55) + craters(d, 16.0, 0.6) * 0.6 + craters(d, 45.0, 0.65) * 0.35;
		alb = mix(ca, cb, m) * (1.0 + cr * 0.25) * (0.85 + 0.3 * fb(q * 12.0, 4));
		relief = 0.5 + cr * 0.3;
	} else {
		// ice world: bright ice crossed by long rust-brown ridges and blue fractures
		float lin = rg(q * 2.5 + vec3(fb(q * 2.0, 3)), 5);
		float frac = rg(q * 7.0 + 4.0, 4);
		alb = mix(ca, cb, smoothstep(0.7, 0.9, lin) * 0.8);
		alb = mix(alb, cc, smoothstep(0.85, 0.95, frac) * 0.6);
		alb *= 0.9 + 0.2 * fb(q * 20.0, 3);
		float cr = craters(d, 10.0, 0.3) * 0.3;
		alb *= 1.0 + cr * 0.2;
		relief = 0.5 + lin * 0.3;
		ocean = 0.25;   // a glossy sheen on the ice
	}
	vec4 o;
	if (pass_id == 0) {
		o = vec4(pow(clamp(alb, 0.0, 1.0), vec3(1.0 / 2.2)), ocean);
	} else {
		o = vec4(cloud, lights, clamp(relief, 0.0, 1.0), lava);
	}
	o.rgb += (hh(vec3(px, seed)) - 0.5) / 255.0;
	COLOR = o;
}
"""

# The planet sphere, unshaded with its own lighting from the key light, so it sits in the scene's light without the
# scene's shadows or fog. Drawn far beyond the board.
const SPHERE := """
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, fog_disabled;
uniform sampler2D tex_a : source_color, filter_linear, repeat_enable;
uniform sampler2D tex_b : filter_linear, repeat_enable;
uniform float has_tex = 0.0;
uniform vec3 flat_col = vec3(0.3);
uniform vec3 sun = vec3(0.45, 0.7, 0.55);     // toward the sun, world space
uniform vec3 sun_col = vec3(1.0, 0.95, 0.88);
uniform float light = 1.0;
uniform vec3 atmo = vec3(0.4, 0.6, 1.0);
uniform float atmo_k = 1.0;
uniform float spin = 0.004;
uniform vec3 tint = vec3(1.0);
uniform vec3 city = vec3(1.0, 0.72, 0.38);
uniform vec3 lava_col = vec3(1.0, 0.36, 0.08);
uniform vec4 ring = vec4(0.0);           // xyz ring normal (world), w on
uniform vec2 ring_r = vec2(1.3, 2.3);    // in planet radii
uniform float rough = 1.0;
varying vec3 vObj;
varying vec3 vW;
varying vec3 vC;
varying float vR;
void vertex() {
	vObj = VERTEX;
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vC = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vR = length(MODEL_MATRIX[0].xyz);
}
vec2 uv_of(vec3 d) { return vec2(atan(d.x, -d.z) / 6.28318530718 + 0.5, acos(clamp(d.y, -1.0, 1.0)) / 3.14159265359); }
vec3 spun(vec3 d, float a) { float c = cos(a); float s = sin(a); return vec3(c * d.x + s * d.z, d.y, -s * d.x + c * d.z); }
void fragment() {
	vec3 n0 = normalize(vObj);
	vec3 N = normalize(vW - vC);
	vec3 L = normalize(sun);
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	vec3 ds = spun(n0, TIME * spin);
	vec3 alb = flat_col;
	vec4 b = vec4(0.0, 0.0, 0.5, 0.0);
	float ocean = 0.0;
	if (has_tex > 0.5) {
		vec4 a = texture(tex_a, uv_of(ds));
		alb = a.rgb;
		ocean = a.a;
		b = texture(tex_b, uv_of(ds));
	}
	alb *= tint;
	float ndl = dot(N, L);
	// relief: a cheap bump from the baked height, along the surface
	vec3 dsx = spun(normalize(n0 + vec3(0.003, 0.0, 0.0)), TIME * spin);
	vec3 dsy = spun(normalize(n0 + vec3(0.0, 0.003, 0.0)), TIME * spin);
	float hx = has_tex > 0.5 ? texture(tex_b, uv_of(dsx)).b - b.b : 0.0;
	float hy = has_tex > 0.5 ? texture(tex_b, uv_of(dsy)).b - b.b : 0.0;
	vec3 tx = normalize(cross(vec3(0.0, 1.0, 0.0), N) + vec3(1e-4));
	vec3 ty = cross(N, tx);
	vec3 Nb = normalize(N - (tx * hx + ty * hy) * 2.5 * rough * (1.0 - b.r));
	float lam = max(dot(Nb, L), 0.0);
	// the terminator softened by the atmosphere
	float wrap = atmo_k > 0.0 ? smoothstep(-0.12, 0.3, ndl) : smoothstep(-0.02, 0.12, ndl);
	float diff = mix(lam, wrap * lam + wrap * 0.04, 0.5);
	// cloud shadows on the ground: the clouds a little toward the sun
	float cs = 0.0;
	if (has_tex > 0.5 && b.r > 0.0) {
		vec3 dl = spun(normalize(n0 + (transpose(mat3(MODEL_MATRIX[0].xyz, MODEL_MATRIX[1].xyz, MODEL_MATRIX[2].xyz)) * L) / vR * 0.012), TIME * spin);
		cs = texture(tex_b, uv_of(dl)).r;
	}
	vec3 ground = alb * (1.0 - cs * 0.55);
	vec3 col = mix(ground, vec3(0.92, 0.94, 0.97), b.r) * diff * sun_col;
	// the sun's glint on water
	vec3 H = normalize(L + V);
	col += sun_col * ocean * (1.0 - b.r) * pow(max(dot(N, H), 0.0), 90.0) * 1.6 * smoothstep(0.0, 0.1, ndl);
	// ring shadow on the planet
	if (ring.w > 0.5) {
		vec3 rn = normalize(ring.xyz);
		float den = dot(L, rn);
		if (abs(den) > 1e-3) {
			float t = dot(vC - vW, rn) / den;
			if (t > 0.0) {
				float rr = length(vW + L * t - vC) / vR;
				float band = smoothstep(ring_r.x, ring_r.x + 0.08, rr) * smoothstep(ring_r.y, ring_r.y - 0.15, rr);
				col *= 1.0 - band * 0.6;
			}
		}
	}
	// night side: city lights and lava
	float night = smoothstep(0.08, -0.18, ndl);
	col += city * b.g * night * 0.9 * (1.0 - b.r * 0.7);
	col += lava_col * b.a * (0.25 + night * 1.2);
	// the lit limb glows with the atmosphere
	float rim = pow(1.0 - clamp(dot(N, V), 0.0, 1.0), 3.0);
	col += atmo * atmo_k * rim * smoothstep(-0.25, 0.4, ndl) * 0.9;
	col = mix(col, atmo * diff * 0.6, atmo_k * rim * 0.35);
	ALBEDO = col * light;
}
"""

# The atmosphere's outer glow: a slightly larger shell, added, brightest just outside the limb on the lit side.
const ATMO := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_front, shadows_disabled, fog_disabled;
uniform vec3 atmo = vec3(0.4, 0.6, 1.0);
uniform vec3 sun = vec3(0.45, 0.7, 0.55);
uniform float k = 1.0;
uniform float shell = 1.04;
varying vec3 vW;
varying vec3 vC;
void vertex() { vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; vC = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz; }
void fragment() {
	vec3 N = normalize(vW - vC);
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	// back faces of the shell: the ray's closest approach to the centre, in shell radii, says how much air it crossed
	vec3 ro = CAMERA_POSITION_WORLD - vC;
	vec3 rd = -V;
	float R = length(vW - vC);
	float tc = -dot(ro, rd);
	float dmin = length(ro + rd * tc) / R;
	float inner = 1.0 / shell;
	float a = smoothstep(1.0, inner, dmin);
	a = a * a * smoothstep(inner * 0.985, inner + 0.004, dmin);
	vec3 P = normalize(ro + rd * tc);
	float lit = smoothstep(-0.35, 0.5, dot(P, normalize(sun)));
	ALBEDO = atmo * a * lit * k * 1.4;
}
"""

const RING := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 sun = vec3(0.45, 0.7, 0.55);
uniform vec3 col_a = vec3(0.85, 0.78, 0.66);
uniform vec3 col_b = vec3(0.5, 0.42, 0.34);
uniform vec2 ring_r = vec2(1.3, 2.3);
uniform float seed = 0.0;
uniform float light = 1.0;
varying vec3 vL;
varying vec3 vW;
varying vec3 vC;
varying float vR;
void vertex() {
	vL = VERTEX;
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vC = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vR = length(MODEL_MATRIX[0].xyz);
}
float h1(float x) { return fract(sin(x * 127.1 + seed) * 43758.5453); }
float n1(float x) { float i = floor(x); float f = fract(x); f = f * f * (3.0 - 2.0 * f); return mix(h1(i), h1(i + 1.0), f); }
void fragment() {
	float r = length(vL.xz);
	float u = (r - ring_r.x) / (ring_r.y - ring_r.x);
	if (u < 0.0 || u > 1.0) { discard; }
	float dens = 0.0;
	float a = 1.0;
	float f = 4.0;
	for (int k = 0; k < 5; k++) { dens += n1(u * f + float(k) * 3.1) * a; a *= 0.55; f *= 2.3; }
	dens = clamp(dens / 1.9, 0.0, 1.0);
	dens *= smoothstep(0.0, 0.04, u) * smoothstep(1.0, 0.94, u);
	// a dark gap two thirds of the way out (Cassini-like) and a thin faint inner ring
	dens *= 1.0 - 0.9 * exp(-pow((u - 0.66) / 0.018, 2.0));
	dens *= mix(0.35, 1.0, smoothstep(0.08, 0.2, u));
	vec3 L = normalize(sun);
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	// the planet's shadow across the ring
	vec3 rel = vW - vC;
	float t = dot(-rel, L);
	float sh = 1.0;
	if (t > 0.0) {
		float dperp = length(rel + L * t) / vR;
		sh = smoothstep(0.97, 1.03, dperp);
	}
	vec3 c = mix(col_b, col_a, n1(u * 23.0 + 5.0));
	// lit from either side; brighter seen against the light (forward scattering)
	float fwd = pow(max(dot(-V, L), 0.0), 6.0);
	vec3 lit = c * (0.55 + 0.6 * fwd) * sh;
	ALBEDO = lit * light;
	ALPHA = dens * 0.85;
}
"""
