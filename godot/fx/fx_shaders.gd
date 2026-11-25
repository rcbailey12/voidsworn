extends RefCounted
# Shader code for the G4 effects library (godot/fx). Grown from the A3 port of the Babylon effect shaders
# (contrib/opus/enginetest/godot/bfx_shaders.gd): same noise, curves and kinds, generalised so a particle can live in
# world space (the dynamic pools) or in a ship's own frame (MODEL_MATRIX, the attached batches), play once (period 0) or
# loop, and so every weapon family gets its own look.
#
# Particle attributes (one particle = one quad or one strip; every vertex of it carries the same 20 floats):
#   a0 = CUSTOM0 (pos, tStart)   a1 = CUSTOM1 (vel, life)   a2 = CUSTOM2 (colour, intensity)
#   a3 = CUSTOM3 (size0, size1, kind, seed)   a4 = (UV, UV2) = (period, accel, drag, spin)
# period 0 = once; accel = acceleration along the velocity direction (u/s2, torpedo boost, rockets)
# Brightness: every effect colour is multiplied by the global fx_gain (look.gd sets it per tonemapper; 0.5556 matches
# the A3 proof under Godot's ACES, which applies an exposure bias of 1.8 that Babylon's curve does not).

static func patch(code: String, target: String, replacement: String) -> String:
	if not code.contains(target):
		push_error("FX shader patch target missing: " + target)
		return code
	return code.replace(target, replacement)


const COMMON := """
global uniform float scene_t;
global uniform float fx_gain;
global uniform float fx_calm;
global uniform float fx_px;
float spow(float b, float e) { return pow(max(b, 0.0), e); }
vec3 snorm(vec3 v) { float l = length(v); return l > 1e-6 ? v / l : vec3(0.0, 1.0, 0.0); }
// F3: the world size of `px` screen pixels at view depth d on a 1080-line screen. The flash counter in fx.gd uses
// this same projection scale and depth. fx_px scales every floor; 0 turns them off.
float px_world(float px, float d, mat4 P) {
	float p11 = max(abs(P[1][1]), 1e-4);
	float dd = P[3][3] > 0.5 ? 1.0 : max(d, 0.01);
	return px * fx_px * 2.0 * dd / (p11 * 1080.0);
}
float frame_world(float px, float d, mat4 P, float height) {
	float dd = P[3][3] > 0.5 ? 1.0 : max(d, 0.01);
	return px * 2.0 * dd / (max(abs(P[1][1]), 0.0001) * max(height, 1.0));
}
float h21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float a = 0.5;
	float s = 0.0;
	for (int k = 0; k < 4; k++) { s += a * vnoise(p); p = p * 2.03 + vec2(1.7, 9.2); a *= 0.5; }
	return s;
}
float cough(float t, float s) {
	float c = 0.6 + 0.4 * vnoise(vec2(t * 6.0, s * 13.0));
	if (h21(vec2(floor(t * 5.0), s)) < 0.22) { c *= 0.12; }
	return c;
}
// reduce-flashing: fast flicker becomes slow breathing (fx_calm = 1)
float flick(float fast, float slow_t, float seed) {
	return mix(fast, 0.9 + 0.1 * sin(slow_t * 2.2 + seed * 6.0), fx_calm);
}
vec3 heatRamp(float h) {
	vec3 c = mix(vec3(0.45, 0.04, 0.01), vec3(1.0, 0.32, 0.04), smoothstep(0.0, 0.3, h));
	c = mix(c, vec3(1.0, 0.75, 0.35), smoothstep(0.3, 0.65, h));
	return mix(c, vec3(1.0, 0.96, 0.85), smoothstep(0.65, 1.0, h));
}
float pAge(float a, float per) { return per > 0.0 ? mod(a, per) : a; }
vec3 pDisp(vec3 v, float dr, float acc, float age) {
	vec3 d = dr > 0.0 ? v * (1.0 - exp(-dr * age)) / dr : v * age;
	return d + snorm(v) * 0.5 * acc * age * age;
}
"""

const DEPTH := """
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
vec3 scene_view_pos(vec2 suv, mat4 inv_proj) {
	float d = texture(depth_tex, suv).r;
	vec3 ndc = vec3(suv * 2.0 - 1.0, d);
	vec4 v = inv_proj * vec4(ndc, 1.0);
	return v.xyz / v.w;
}
"""

const HIDE := "POSITION = vec4(2.0, 2.0, 2.0, 1.0);"

# Offline Mantaflow, 16 frames, bidirectional motion vectors and optical thickness.
# COMPAT omits depth sampling; all tiers keep the same baked visual language.
# Issue 1211: fog_disabled here and on the hull marks (SHARD, HIT_FRAGMENT, HOLE, MARK), like the streaks and the hulls
# (nebula_hulls.gd, R82), so a nebula never dulls a fireball or a scar.
const DEATH_FLIPBOOK := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform sampler2D atlas : source_color, filter_linear, repeat_disable;
uniform sampler2D motion : filter_linear, repeat_disable;
uniform sampler2D thickness : filter_linear, repeat_disable;
#ifndef COMPAT
uniform sampler2D death_depth : hint_depth_texture, filter_nearest;
#endif
uniform float born = 0.0;
uniform float lifetime = 0.4;
uniform float extent = 1.0;
uniform float intensity = 1.0;
uniform float plasma = 0.0;
uniform vec3 velocity = vec3(0.0);
uniform vec3 tear_normal = vec3(0.0, 1.0, 0.0);
uniform float directional = 0.0;
uniform float ignition = 0.0;
uniform vec4 atlas_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float min_pixels = 0.0;
uniform float size_divisor = 1.0;
uniform float soft_flash = 0.0;
// Opt-in for a weapon flash or its body. A setting change can dim an existing picture without restarting its clock.
uniform float calm_intensity = 0.0;
// Issue 484 (owner: the secondaries' smoke "looks a little too even and weird"): a picture can be turned, stretched and
// toned so a cluster of them never repeats one round shape. Defaults leave every other caller as it was.
uniform float pic_spin = 0.0;
uniform vec2 pic_shape = vec2(1.0);
uniform float smoke_tone = 1.0;
// R367 (issue 1399): a faction's own death. fac_fire.a 1 turns the hot gas from the baked orange to fac_mid (cooler) and
// fac_fire.rgb (hottest), fac_prism puts a rainbow edge on it, fac_smoke keeps that share of the smoke. Defaults: today's.
uniform vec4 fac_fire = vec4(1.0, 1.0, 1.0, 0.0);
uniform vec3 fac_mid = vec3(1.0);
uniform float fac_prism = 0.0;
uniform float fac_smoke = 1.0;
varying float elapsed;
varying float particle_depth;
vec2 cell_uv(vec2 uv, float frame) {
	// Half-texel gutter prevents neighbouring cells bleeding under interpolation.
	return (vec2(mod(frame, 4.0), floor(frame / 4.0)) + clamp(uv, vec2(0.001), vec2(0.999))) / 4.0;
}
void vertex() {
	elapsed = max(scene_t - born, 0.0);
	vec3 centre = MODEL_MATRIX[3].xyz + velocity * elapsed;
	vec3 view_c = (VIEW_MATRIX * vec4(centre, 1.0)).xyz;
	particle_depth = -view_c.z;
	float size = max(extent, px_world(min_pixels, -view_c.z, PROJECTION_MATRIX));
	size /= size_divisor;
	vec2 axis = (VIEW_MATRIX * vec4(tear_normal, 0.0)).xy;
	axis = length(axis) > 0.01 ? normalize(axis) : vec2(0.0, 1.0);
	vec2 up = mix(vec2(0.0, 1.0), axis, directional);
	vec2 right = vec2(up.y, -up.x);
	vec2 local = vec2(VERTEX.x, VERTEX.y) * pic_shape;
	local = vec2(local.x * cos(pic_spin) - local.y * sin(pic_spin), local.x * sin(pic_spin) + local.y * cos(pic_spin));
	vec2 offset = (right * local.x * mix(1.0, 0.6, directional) + up * local.y) * size;
	POSITION = PROJECTION_MATRIX * vec4(view_c + vec3(offset, 0.0), 1.0);
}
void fragment() {
	float age = clamp(elapsed / max(lifetime, 0.001), 0.0, 1.0);
	float live_calm = step(0.001, calm_intensity) * fx_calm;
	float softened = max(soft_flash, live_calm);
	float power = mix(intensity, min(intensity, calm_intensity), live_calm);
	float frame = mix(age * 15.0, 3.0 + sqrt(age) * 12.0, plasma);
#ifdef ROUTE_BAKED
	// A softened flash keeps the same first-cell diameter while it rises, then cools through the sequence.
	frame = mix(age, max(0.0, (age - 0.5) * 2.0), softened) * 15.0;
#endif
	float a = floor(frame); float b = min(a + 1.0, 15.0); float blend = fract(frame);
	vec2 uv = atlas_rect.xy + vec2(UV.x, mix(UV.y, 1.0 - UV.y, directional)) * atlas_rect.zw;
	vec2 fa = (texture(motion, cell_uv(uv, a)).rg - 0.5) * 0.25;
	vec2 fb = (texture(motion, cell_uv(uv, b)).ba - 0.5) * 0.25;
	vec2 ua = cell_uv(uv - fa * blend, a);
	vec2 ub = cell_uv(uv - fb * (1.0 - blend), b);
	vec4 gas = mix(texture(atlas, ua), texture(atlas, ub), blend);
	vec3 thick = mix(texture(thickness, ua).rgb, texture(thickness, ub).rgb, blend);
	// Thickness gradients make a coarse volume normal, shaded by the battle sun.
	vec2 e = vec2(1.0 / float(textureSize(thickness, 0).x), 0.0);
	float dx = texture(thickness, ua + e.xy).r - texture(thickness, ua - e.xy).r;
	float dy = texture(thickness, ua + e.yx).r - texture(thickness, ua - e.yx).r;
	vec3 normal = normalize(vec3(-dx * 26.0, dy * 26.0, 0.5));
	vec3 sun = normalize((VIEW_MATRIX * vec4(0.45, 0.70, 0.55, 0.0)).xyz);
	float lit = 0.25 + 0.55 * max(dot(normal, sun), 0.0) + thick.g * 0.2;
	vec3 smoke = mix(vec3(0.12, 0.085, 0.18), vec3(0.42, 0.36, 0.50), lit);
	vec3 core = mix(vec3(0.65, 0.76, 0.93), vec3(0.9, 0.83, 0.68), age);
	core = mix(core, mix(fac_fire.rgb, fac_mid, age), fac_fire.a);
	ALBEDO = smoke * (1.0 - plasma) * power * fx_gain;
	// One fast ignition, then only cool gas. The caller books both bright
	// phases through flash_ok; an unbooked vent has no emissive pulse.
	float pulse = plasma * (1.0 - smoothstep(0.12, 0.85, age)) + ignition * exp(-elapsed / 0.055);
	ALBEDO += core * (0.9 + gas.r * 1.6) * pulse * power * fx_gain;
	float keep = clamp(pulse * 3.0, 0.0, 1.0);
#ifdef ROUTE_BAKED
	// Route B keeps the baked colour and heat: smoke sees the sun, the short core emits light.
	ALBEDO = gas.rgb * mix(0.55 + 0.9 * lit, 1.2 * power, thick.b) * fx_gain;
	ALBEDO *= mix(smoke_tone, 1.0, clamp(thick.b, 0.0, 1.0));
	keep = clamp(thick.b, 0.0, 1.0);
	if (fac_fire.a > 0.0) {
		// the baked heat keeps its shape and brightness and takes the faction's colours; its smoke keeps its shading but
		// loses the baked fire's warm cast (issue 1399 round 2: a Hegemony break bloomed rose-pink), so it reads as soot
		float lum = dot(ALBEDO, vec3(0.3, 0.55, 0.15));
		vec3 ramp = mix(fac_mid, fac_fire.rgb, smoothstep(0.12, 1.1, lum)) * lum * 1.5;
		vec2 c = UV - 0.5;
		vec3 bow = 0.55 + 0.45 * cos(6.2831853 * (atan(c.y, c.x) / 6.2831853 + vec3(0.0, 0.33, 0.67)));
		ramp = mix(ramp, bow * lum * 1.7, fac_prism * smoothstep(0.12, 0.42, length(c)) * 0.85);
		vec3 soot = mix(ALBEDO, vec3(lum), 0.85);
		ALBEDO = mix(ALBEDO, mix(soot, ramp, keep), fac_fire.a);
	}
#endif
	ALBEDO *= mix(1.0, sin(age * 3.14159265), softened);
	float fade = 1.0 - smoothstep(0.70, 1.0, age);
	float soft = 1.0;
#ifndef COMPAT
	float z = texture(death_depth, SCREEN_UV).r;
	vec4 hit = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, z, 1.0);
	soft = clamp((-hit.z / hit.w - particle_depth) / max(extent * 0.1, 0.05), 0.0, 1.0);
#endif
	ALPHA = gas.a * fade * soft * (elapsed < lifetime ? 1.0 : 0.0);
	ALPHA *= mix(fac_smoke, 1.0, keep);
}
"""

const DEATH_PARTICLES := """
shader_type particles;
uniform vec3 axis = vec3(0.0, 1.0, 0.0);
uniform vec3 inherited = vec3(0.0);
uniform float spread = 0.3;
uniform float speed = 4.0;
uniform float size = 0.05;
uniform vec4 tint : source_color = vec4(0.9, 0.6, 0.2, 1.0);
uniform float seed_value = 1.0;
float random_v(float n) { return fract(sin(n * 127.1 + seed_value) * 43758.5453); }
void start() {
	float id = float(NUMBER) + 1.0;
	vec3 jitter = vec3(random_v(id), random_v(id + 3.0), random_v(id + 7.0)) * 2.0 - 1.0;
	VELOCITY = normalize(axis + jitter * spread) * speed * (0.6 + random_v(id + 13.0) * 0.4) + inherited;
	TRANSFORM = EMISSION_TRANSFORM;
	TRANSFORM[0].xyz *= size;
	TRANSFORM[1].xyz *= size;
	TRANSFORM[2].xyz *= size;
	COLOR = tint;
	CUSTOM.y = 0.0;
}
void process() {
	CUSTOM.y += DELTA / LIFETIME;
	COLOR.a = tint.a * (1.0 - smoothstep(0.1, 1.0, CUSTOM.y));
}
"""

# Sprites (camera-facing). kinds:
#  0 flash   1 flame   2 fireball core   3 smoke   4 engine core   5 squib   7 vent gas   8 soot   11 sputtering core
#  12 beam charge   13 beam impact flare   14 plasma bolt   15 bio glob   16 prism glint   17 star ball
#  18 soft lift (reduce-flashing pop: a gentle glow, no peak)   19 ember   20 acid fume   21 heat glow (cooling metal)
#  22 coil glow (gauss charge, stepped)   23 craft (a tiny strike craft silhouette with an engine dot)
#  24 death core (counted, short plateau)   25 death fire (steady ribbon/edge flame)
#  26 faction-coloured plasma fire (Eclipse damage, steady)   27 directional hit gas (no emission)
const TICK_EMBER := 30
const TICK_DROPLET := 31
# The flash budget and SPRITE share these defaults for the bright kinds.
const FLASH_SPRITE_FLOORS := {0: 14.0, 2: 12.0, 12: 10.0, 13: 12.0, 24: 56.0}


static func flash_sprite_floor(kind: int, px: float) -> float:
	return maxf(FLASH_SPRITE_FLOORS[kind], floorf(clampf(px, 0.0, 4000.0)))


const SPRITE := """
shader_type spatial;
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform float gate = 1.0;
uniform sampler2D kit_flake : filter_linear, repeat_disable;
varying vec2 vUv;
varying vec4 vCol;
varying vec4 vInfo;
varying float vLife;
varying float vDepth;
#ifdef SOFT
""" + DEPTH + """
#endif
void vertex() {
	vec4 a0 = CUSTOM0; vec4 a1 = CUSTOM1; vec4 a2 = CUSTOM2; vec4 a3 = CUSTOM3; vec4 a4 = vec4(UV, UV2);
	float a = scene_t - a0.w;
	float age = pAge(a, a4.x);
	float life = a1.w;
	vUv = vec2(0.0); vCol = vec4(0.0); vInfo = vec4(0.0); vLife = life;
	if (a < 0.0 || age >= life || gate <= 0.0 || a2.a <= 0.0) {
		""" + HIDE + """
	} else {
		float t = age / life;
		int k = int(a3.z + 0.5);
		float g = t;
		if (k == 1 || k == 20 || k == 25 || k == 26) { g = 1.0 - spow(1.0 - t, 2.2); }
		else if (k == 2 || k == 5 || k == 18) { g = sqrt(t); }
		else if (k == 3 || k == 7 || k == 8) { g = 1.0 - spow(1.0 - t, 1.6); }
		else if (k == 4 || k == 11 || k == 13 || k == 14 || k == 15 || k == 16 || k == 17 || k == 19 || k == 21 || k == 22 || k == 23) { g = 0.0; }
		else if (k == 12) { g = t * t; }
		float size = mix(a3.x, a3.y, g);
		// F3 round 2: a3.w carries the seed in its fraction and, in its whole part, an explicit on-screen floor in pixels
		// for this one sprite (impact, muzzle and kill flashes that must read from the battle camera); 0 means the kind's
		float sd = fract(a3.w);
		float fpx = floor(a3.w);
		vec3 disp = pDisp(a1.xyz, a4.z, a4.y, age);
		vec3 lp = a0.xyz + disp;
		if (k == 15) { lp += vec3(sin(age * 9.0 + sd * 20.0), cos(age * 7.0 + sd * 13.0), sin(age * 8.0 + sd * 5.0)) * size * 0.12; }
		vec3 c = (MODEL_MATRIX * vec4(lp, 1.0)).xyz;
		float ang = sd * 6.2831853 + age * a4.w;
		vec4 vp = VIEW_MATRIX * vec4(c, 1.0);
		// POSITION is projected manually. Fragment VERTEX still belongs to the
		// batch origin, so soft particles need this particle's actual depth.
		vDepth = -vp.z;
		// F3: a minimum on-screen size per kind (diameter in pixels at 1080 lines), so a frigate's muzzle flash, a bolt or a
		// spark never shrinks below a few pixels (sub-pixel quads drop out of the raster and vanish at distance). A sprite
		// grown to the floor dims as it grows, but by less than its area (pops and bolts get f times their light, the rest
		// f^0.8), so distant and small effects read brighter without blowing out. Smoke, soot and gas have no floor (no haze).
		float flo = 0.0;
		if (k == 24) { flo = %.1f; }
		else if (k == 25 || k == 26) { flo = 24.0; }
		else if (k == 0 || k == 17) { flo = %.1f; }
		else if (k == 2 || k == 14) { flo = %.1f; }
		else if (k == 13) { flo = %.1f; }
		else if (k == 12 || k == 15 || k == 18) { flo = %.1f; }
""" % [FLASH_SPRITE_FLOORS[24], FLASH_SPRITE_FLOORS[0], FLASH_SPRITE_FLOORS[2], FLASH_SPRITE_FLOORS[13], FLASH_SPRITE_FLOORS[12]] + """
		else if (k == 5 || k == 16 || k == 23) { flo = 9.0; }
		else if (k == 1) { flo = 8.0; }
		else if (k == 22) { flo = 6.0; }
		else if (k == 19 || k == 21 || k == 30) { flo = 4.5; }
		else if (k == 4 || k == 11) { flo = 3.0; }
		bool own = fpx > flo;
		flo = max(flo, fpx);
		float boost = 1.0;
		if (flo > 0.0) {
			float mn = px_world(flo, -vp.z, PROJECTION_MATRIX);
			if (size < mn) {
				float gf = mn / max(size, 1e-5);
				// pops and bolts keep their brightness per pixel falling only as 1/f (their total light grows with the
				// floor); the rest dims a little faster (f^-1.2). A sprite with its own floor (round 2: the moments that
				// must land) dims only as f^-0.5, so a far hit is a big bright flash, not a big faint one.
				float dimx = (k == 0 || k == 2 || k == 5 || k == 13 || k == 14 || k == 16 || k == 17) ? -1.0 : -1.2;
				if (own) { dimx = -0.5; }
				boost = (k == 15 || k == 23) ? 1.0 : clamp(spow(gf, dimx), 0.03, 1.0);
				size = mn;
			}
		}
		// Death cores and narrow fires keep their surface brightness at the floor.
		// Enlarging an almost subpixel craft flame must not make it a faint dot.
		// Explicit smoke/gas floors preserve opacity, without adding any light.
		if (k == 24 || k == 25 || k == 26 || (own && (k == 3 || k == 7 || k == 8))) { boost = 1.0; }
		vec2 q = VERTEX.xy;
		if (k == 14 || k == 15 || k == 23 || k == 27) {
			// stretched along the screen-space motion (bolts and globs read as moving, not as dots)
			vec3 vw = (MODEL_MATRIX * vec4(a1.xyz, 0.0)).xyz;
			vec2 sv = (VIEW_MATRIX * vec4(vw, 0.0)).xy;
			float sl = length(sv);
			vec2 dx = sl > 1e-4 ? sv / sl : vec2(1.0, 0.0);
			vec2 dy = vec2(-dx.y, dx.x);
			float st = k == 23 ? 1.4 : (k == 14 ? 1.0 + clamp(sl * 0.012, 0.0, 1.6) : 1.0 + clamp(sl * 0.006, 0.0, 0.6));
			q = k == 27 ? dx * VERTEX.x * 1.85 + dy * VERTEX.y * 0.62 : dx * VERTEX.x * st + dy * VERTEX.y;
		} else {
			float cs = cos(ang);
			float sn = sin(ang);
			q = vec2(cs * VERTEX.x - sn * VERTEX.y, sn * VERTEX.x + cs * VERTEX.y);
		}
		vp.xy += q * size;
		POSITION = PROJECTION_MATRIX * vp;
		vUv = VERTEX.xy * 2.0;
		float power = a2.a;
		// Pooled flashes may have been submitted before the option changed. Keep the size and soften the remaining pulse.
		if (fx_calm > 0.5 && (k == 0 || (k == 13 && power > 1.25) || (life <= 0.6 && power >= 4.0 && (k == 2 || k == 12 || k == 24)))) {
			power = min(power, 1.25) * sin(t * 3.14159265);
		}
		vCol = vec4(a2.rgb, power * gate * boost);
		vInfo = vec4(t, a3.z, sd, age);
	}
}
void fragment() {
	float t = vInfo.x; int k = int(vInfo.y + 0.5); float seed = vInfo.z; float age = vInfo.w; float I = vCol.a;
	vec2 p = vUv;
	float r = length(p);
	if (r > 1.0) { discard; }
	vec3 add = vec3(0.0); vec3 base = vec3(0.0); float alpha = 0.0;
	float star = exp(-abs(p.x) * 40.0) * exp(-abs(p.y) * 3.0) + exp(-abs(p.y) * 40.0) * exp(-abs(p.x) * 3.0);
	if (k == 0) {
		float f = (1.0 - t) * (1.0 - t) * I;
		add = vCol.rgb * exp(-r * r * 5.0) * f + vec3(exp(-r * r * 30.0)) * f * 0.8 + vCol.rgb * f * 0.5 * star;
	} else if (k == 24) {
		float f = (1.0 - smoothstep(0.18, 1.0, t)) * I;
		add = (vCol.rgb * exp(-r * r * 5.0) + vec3(1.0, 0.88, 0.65) * exp(-r * r * 22.0) * 0.7) * f;
	} else if (k == 1 || k == 25 || k == 26) {
		float n = fbm(p * 1.7 + vec2(seed * 13.1, seed * 7.7) + vec2(0.0, -t * 1.2));
		float dens = (1.0 - r) * 1.4 + (n - 0.5) * 1.15;
		float thr = t * 1.1;
		float m = smoothstep(thr, thr + 0.35, dens);
		float heat = clamp(dens - thr, 0.0, 1.0) * (1.0 - t * 0.6);
		vec3 flame = k == 26 ? vCol.rgb * (0.5 + 1.8 * heat) + vec3(0.8, 0.7, 1.0) * pow(heat, 4.0) * 0.3 : heatRamp(heat) * mix(vec3(1.0), vCol.rgb * 1.6, 0.25);
		add = flame * I * (0.5 + 2.6 * heat * heat) * m * smoothstep(0.0, 0.05, t);
	} else if (k == 2) {
		float f = spow(1.0 - t, 1.5) * I;
		add = vCol.rgb * exp(-r * r * 3.0) * f + vec3(exp(-r * r * 10.0)) * f;
	} else if (k == 3 || k == 8) {
		float n = fbm(p * 1.3 + vec2(seed * 11.3, seed * 5.1) + vec2(t * 0.4, 0.0));
		float dens = (1.0 - r) * 1.25 + (n - 0.5) * 0.95;
		float m = smoothstep(0.05, 0.55, dens);
		alpha = m * I * smoothstep(0.0, 0.12, t) * spow(1.0 - t, 1.3);
		base = vCol.rgb * (0.7 + 0.6 * n);
		if (k == 3) { add = vec3(1.0, 0.4, 0.1) * spow(1.0 - t, 6.0) * 0.9 * alpha; }
	} else if (k == 27) {
		// A tapered, ragged sheet, stretched in the hit's outward velocity direction in vertex().
		vec2 flow = p + vec2(seed * 9.1, seed * 4.3);
		float n = fbm(flow * 2.2 + vec2(-t * 0.8, t * 0.2));
		float taper = 0.7 + 0.3 * p.x;
		float edge = length(vec2(p.x, p.y / taper));
		float dens = (1.0 - edge) + (n - 0.5) * 1.7;
		alpha = smoothstep(0.05, 0.7, dens) * I * smoothstep(0.0, 0.035, t) * spow(1.0 - t, 0.85);
		base = vCol.rgb * (0.65 + 0.55 * n);
	} else if (k == 7 || k == 20) {
		float n = fbm(p * 1.6 + vec2(seed * 9.1, seed * 4.3) + vec2(0.0, -age * 1.4));
		float dens = (1.0 - r) * 1.1 + (n - 0.5) * 1.3;
		float m = smoothstep(0.1, 0.75, dens);
		alpha = m * I * smoothstep(0.0, 0.08, t) * spow(1.0 - t, 1.5);
		base = vCol.rgb * (0.8 + 0.4 * n);
		if (k == 20) { add = vCol.rgb * 0.35 * alpha * (0.5 + n); }
	} else if (k == 4 || k == 11) {
		// issue 461 (found by the issue 504 worker): the engine core's fast flicker swings 0.95 to 1.0, not 0.85 to 1.0, so
		// the white centre can never add up to a general flash at the close cameras (60 and 26) with many engines on screen
		float fl = flick(0.95 + 0.05 * vnoise(vec2(scene_t * 31.0, seed * 9.0)), scene_t, seed);
		if (k == 11) { fl *= mix(cough(scene_t, seed), 0.7, fx_calm); }
		add = (vCol.rgb * exp(-r * r * 4.0) + vec3(1.0, 0.95, 0.8) * exp(-r * r * 14.0) * 1.6) * I * fl;
	} else if (k == 5) {
		float f = (1.0 - t) * (1.0 - t) * I;
		add = vec3(1.0, 0.6, 0.25) * exp(-r * r * 6.0) * f + vec3(exp(-r * r * 30.0)) * f + vec3(1.0, 0.7, 0.4) * star * f * 0.6;
	} else if (k == 12) {
		float f = t * t * I;
		float ray = spow(abs(cos(atan(p.y, p.x) * 3.0 + age * 9.0)), 24.0) * (1.0 - r);
		add = vCol.rgb * exp(-r * r * 4.0) * f + vec3(exp(-r * r * 25.0)) * f * 1.5 + vCol.rgb * f * 0.8 * ray;
	} else if (k == 13) {
		float fl = flick(0.8 + 0.2 * vnoise(vec2(scene_t * 40.0, seed)), scene_t, seed);
		float env = smoothstep(0.0, 0.05, age) * (1.0 - smoothstep(vLife - 0.15, vLife, age));
		add = (vCol.rgb * exp(-r * r * 3.0) + vec3(exp(-r * r * 12.0)) * 1.5 + vCol.rgb * star * 0.7) * I * fl * env;
	} else if (k == 14) {
		// plasma: a churning molten core and a wobbling corona, nothing like a laser's hard line
		float n = fbm(p * 2.2 + vec2(seed * 7.0 - age * 6.0, age * 3.0));
		float n2 = fbm(p * 4.5 + vec2(age * 9.0, seed * 3.0));
		float core = smoothstep(0.55, 0.0, r + (n - 0.5) * 0.35);
		float corona = exp(-r * r * 2.2) * (0.55 + 0.6 * n2) * smoothstep(1.0, 0.6, r + (n2 - 0.5) * 0.4);
		vec3 hot = mix(vCol.rgb, vec3(0.88, 0.96, 1.0), core * core * 0.6);
		add = (hot * core * 1.8 + vCol.rgb * corona * 1.1) * I;
	} else if (k == 15 || k == 31) {
		// bio glob: a wet, dark-skinned body with a bioluminescent heart and a wobbling rim
		float n = fbm(p * 2.0 + vec2(seed * 5.0, age * 2.0));
		float body = smoothstep(0.85, 0.55, r + (n - 0.5) * 0.45);
		float heart = exp(-r * r * 6.0) * (0.6 + 0.4 * sin(age * 11.0 + seed * 9.0));
		float rim = smoothstep(0.45, 0.8, r + (n - 0.5) * 0.3) * body;
		alpha = body * I * 0.9;
		base = (k == 31 ? vCol.rgb * 0.075 : vec3(0.05, 0.06, 0.03)) * (0.6 + n);
		add = vCol.rgb * (heart * 1.8 + rim * 0.6) * I;
	} else if (k == 16) {
		// A filled tumbling chip, with broad facets rather than thin cross arms.
		vec3 facet = texture(kit_flake, p * 0.5 + 0.5).rgb;
		float pulse = 0.8 + 0.2 * sin(age * 8.0 + seed * 17.0);
		float fade = spow(1.0 - t, 1.3) * I;
		add = (vCol.rgb * facet.b * 1.5 + mix(vCol.rgb, vec3(1.0), 0.75) * facet.r) * fade * pulse;
	} else if (k == 17) {
		// star torpedo: a little sun, churning surface, corona rays
		float n = fbm(p * 3.0 + vec2(age * 2.0, seed * 4.0));
		float sphere = smoothstep(0.42, 0.36, r);
		float ray = spow(abs(cos(atan(p.y, p.x) * 6.0 + age * 1.5 + seed * 4.0)), 18.0) * exp(-r * 2.5);
		add = (mix(vCol.rgb, vec3(1.0, 0.98, 0.9), 0.6) * sphere * (1.2 + 0.8 * n) + vCol.rgb * exp(-r * r * 4.0) * 0.8 + vCol.rgb * ray * 1.2) * I;
	} else if (k == 18) {
		float f = sin(3.14159 * t) * I;
		add = vCol.rgb * exp(-r * r * 2.5) * f;
	} else if (k == 19 || k == 30) {
		float f = spow(1.0 - t, 1.2) * I;
		vec3 c = k == 30 ? mix(vCol.rgb, vec3(1.0), (1.0 - t) * 0.25) : mix(vec3(1.0, 0.85, 0.5), vCol.rgb, t);
		add = c * (exp(-r * r * 18.0) * 1.5 + exp(-r * r * 4.0) * 0.25) * f;
	} else if (k == 21) {
		float f = I * (1.0 - t);
		add = heatRamp(1.0 - t) * exp(-r * r * 3.0) * f;
	} else if (k == 22) {
		float st = floor(t * 4.0) / 4.0 + 0.25;
		add = (vCol.rgb * exp(-r * r * 5.0) * st + vec3(exp(-r * r * 24.0)) * st * st) * I;
	} else if (k == 23) {
		float body = smoothstep(0.32, 0.22, length(p * vec2(0.55, 1.9)));
		float eng = exp(-dot(p + vec2(0.55, 0.0), p + vec2(0.55, 0.0)) * 30.0);
		alpha = body * I;
		base = vec3(0.09, 0.09, 0.1);
		add = vCol.rgb * eng * 2.5 * I;
	}
	float win = 1.0 - r * r;
	add *= win * win;
#ifdef SOFT
	float scene_z = -scene_view_pos(SCREEN_UV, INV_PROJECTION_MATRIX).z;
	float soft = clamp((scene_z - vDepth) / 0.6, 0.0, 1.0);
	add *= soft;
	alpha *= soft;
#endif
	ALBEDO = clamp(base * alpha + add * fx_gain, 0.0, 512.0);
	ALPHA = clamp(alpha, 0.0, 1.0);
}
"""

# Camera-facing textured heads and tails. a3 = (length or blur seconds, width, drag, kind).
# kinds: 0 shell/tracer   1 spark   3 flame tongue   4 textured las dart
# Kind 5 now routes to NULL_SLUG; its old vertex branch below is unused there.
#        6 droplet (bio, falls off a glob)   7 molten drip (lance trench)   8 hull-hit spark
const STREAK_VERTEX := """
uniform float gate = 1.0;
uniform sampler2D kit_tail : filter_linear, repeat_disable;
varying vec2 vUv;
varying vec3 vCol;
varying float vK;
varying float vU;
void vertex() {
	vec4 a0 = CUSTOM0; vec4 a1 = CUSTOM1; vec4 a2 = CUSTOM2; vec4 a3 = CUSTOM3; vec4 a4 = vec4(UV, UV2);
	float a = scene_t - a0.w;
	// Keep a scheduled null shot's first sample when float clock rounding
	// places it a few microseconds before zero. The life still excludes f2.
	if (int(a3.w + 0.5) == 5 && a > -0.0001) { a = max(a, 0.0); }
	float age = pAge(a, a4.x);
	float life = a1.w;
	vUv = vec2(0.0); vCol = vec3(0.0); vK = 0.0; vU = 0.0;
	if (a < 0.0 || age >= life || gate <= 0.0) {
		""" + HIDE + """
	} else {
		vec3 v = a1.xyz;
		float sp = max(length(v), 1e-4);
		vec3 dir = v / sp;
		float dr = a3.z;
		int k = int(a3.w + 0.5);
		vec3 head; vec3 tail; float fade = 1.0; float u = age / life;
		if (k == 8) {
			float last = max(0.0, age - a3.x * mix(1.0, 0.37, u));
			head = a0.xyz + pDisp(v, dr, 0.0, age) - vec3(0.0, 1.2 * age * age, 0.0);
			tail = a0.xyz + pDisp(v, dr, 0.0, last) - vec3(0.0, 1.2 * last * last, 0.0);
			dir = snorm(v * exp(-dr * age) - vec3(0.0, 2.4 * age, 0.0));
			fade = mix(1.0, 0.62, fx_calm) * spow(1.0 - u, 1.5);
		} else if (k == 1 || k == 6 || k == 7) {
			float e = exp(-dr * age);
			head = a0.xyz + pDisp(v, dr, 0.0, age);
			head.y -= 1.2 * age * age;
			dir = snorm(v * e + vec3(0.0, -2.4 * age, 0.0));
			float L = max(a3.x * sp * e, 0.05);
			tail = head - dir * L;
			fade = (1.0 - u) * (1.0 - u);
		} else if (k == 3) {
			tail = a0.xyz;
			head = a0.xyz + dir * a3.x * (0.35 + 0.65 * sqrt(u));
			fade = spow(1.0 - u, 1.5);
		} else if (k == 5) {
			// Two-frame travelling tracer, never a persistent full-path line.
			float travel = clamp((age + 1.0 / 60.0) / life, 0.0, 1.0);
			head = a0.xyz + dir * a3.x * travel;
			tail = head - dir * min(3.0, a3.x);
			fade = 1.0;
		} else {
			float tr = sp * age + 0.5 * a4.y * age * age;
			head = a0.xyz + dir * tr;
			tail = head - dir * min(a3.x, tr);
		}
		head = (MODEL_MATRIX * vec4(head, 1.0)).xyz;
		tail = (MODEL_MATRIX * vec4(tail, 1.0)).xyz;
		vec3 wdir = snorm((MODEL_MATRIX * vec4(dir, 0.0)).xyz);
		float dv = max(-(VIEW_MATRIX * vec4(0.5 * (head + tail), 1.0)).z, 0.01);
		if (k == 8) {
			// Lay out hull sparks in view space so their width survives foreshortening.
			vec3 h = (VIEW_MATRIX * vec4(head, 1.0)).xyz;
			vec3 t = (VIEW_MATRIX * vec4(tail, 1.0)).xyz;
			float frame_ratio = VIEWPORT_SIZE.y / 1080.0;
			float pixel = frame_world(1.0, dv, PROJECTION_MATRIX, VIEWPORT_SIZE.y);
			vec4 hc = PROJECTION_MATRIX * vec4(h, 1.0);
			vec4 tc = PROJECTION_MATRIX * vec4(t, 1.0);
			vec2 projected = (hc.xy / max(hc.w, 1e-4) - tc.xy / max(tc.w, 1e-4)) * VIEWPORT_SIZE * 0.5;
			float len = length(projected);
			vec2 screen_motion = (VIEW_MATRIX * vec4(wdir, 0.0)).xy;
			float motion_length = length(screen_motion);
			vec2 axis = vec2(1.0, 0.0);
			if (len > 1e-3) {
				axis = projected / len;
			} else if (motion_length > 1e-5) {
				axis = screen_motion / motion_length;
			}
			float cap_px = mix(20.0, 49.0, clamp(a3.x * 6.5, 0.0, 1.0)) * frame_ratio;
			if (len > cap_px) {
				float ratio = cap_px / len;
				float f = ratio * hc.w / max(tc.w * (1.0 - ratio) + ratio * hc.w, 1e-4);
				t = mix(h, t, clamp(f, 0.0, 1.0));
			}
			float min_len = max(2.5 * pixel, px_world(mix(5.0, 9.0, clamp(a3.x * 6.5, 0.0, 1.0)), dv, PROJECTION_MATRIX));
			t.xy -= axis * max(min_len - min(len, cap_px) * pixel, 0.0);
			float width = max(a3.y * 2.8, max(3.0 * pixel, px_world(3.8, dv, PROJECTION_MATRIX)));
			vec3 p = mix(t, h, VERTEX.x);
			p.xy += vec2(-axis.y, axis.x) * VERTEX.y * width;
			vUv = VERTEX.xy;
			vK = a3.w;
			vU = u;
			vCol = a2.rgb * a2.a * fade * clamp(gate, 0.0, 1.0);
			POSITION = PROJECTION_MATRIX * vec4(p, 1.0);
		} else {
			// Kit floors describe the whole mask quad, including its soft halo.
			// The separate projected-length cap below uses actual framebuffer pixels.
			float wf = k == 4 ? 7.0 : (k == 5 ? 22.0 : (k == 0 ? 8.0 : 6.0));
			float lf = (k == 0 || k == 4 || k == 5) ? 14.0 : 5.0;
			// round 2: a4.z and a4.w carry this streak's own width and length floors (pixels), for fatter tracer cores and
			// bolder sparks; a line grown to its own floor dims only as f^-0.3
			bool own = a4.z > wf;
			wf = max(wf, a4.z);
			lf = max(lf, a4.w);
			float sw = a3.y;
			float bw = 1.0;
			float wmin = max(px_world(wf, dv, PROJECTION_MATRIX), frame_world(5.0, dv, PROJECTION_MATRIX, VIEWPORT_SIZE.y));
			if (sw < wmin) {
				bw = clamp(spow(wmin / max(sw, 1e-5), -0.15), 0.05, 1.0);
				sw = wmin;
		}
		float lmin = px_world(lf, dv, PROJECTION_MATRIX);
		if (lf > 0.0 && length(head - tail) < lmin) {
			tail = head - wdir * lmin;
		}
		// Cap projected head-to-tail distance, including perspective. The cap is in 1080-line pixels like the width
		// and length floors (issue 1211: it was raw pixels, so 4K streaks were half length), it never clips the streak's
		// own length floor (the macro shell asks 26), and it holds with fx_px disabled.
		float cap_px = max(k == 4 ? 32.0 : (k == 5 ? 26.0 : (k == 0 ? 22.0 : 16.0)), lf) * (VIEWPORT_SIZE.y / 1080.0);
		vec4 hc = PROJECTION_MATRIX * VIEW_MATRIX * vec4(head, 1.0);
		vec4 tc = PROJECTION_MATRIX * VIEW_MATRIX * vec4(tail, 1.0);
		float projected = length((hc.xy / max(hc.w, 0.0001) - tc.xy / max(tc.w, 0.0001)) * VIEWPORT_SIZE * 0.5);
		if (projected > cap_px) {
			float ratio = cap_px / projected;
			float f = ratio * hc.w / max(tc.w * (1.0 - ratio) + ratio * hc.w, 0.0001);
			tail = mix(head, tail, clamp(f, 0.0, 1.0));
		}
		vec3 mid = 0.5 * (head + tail);
		vec3 wd = snorm(head - tail);
		vec3 side = snorm(cross(wd, CAMERA_POSITION_WORLD - mid));
		vec3 p = mix(tail, head, VERTEX.x) + side * VERTEX.y * sw;
		vUv = VERTEX.xy;
		vK = a3.w;
		vU = u;
		vCol = a2.rgb * a2.a * fade * bw * clamp(gate, 0.0, 1.0);
		POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(p, 1.0));
		}
	}
}
"""

const STREAK := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
""" + STREAK_VERTEX + """
void fragment() {
	int k = int(vK + 0.5);
	if (k == 8) {
		// Analytic coverage of a tapered trail and rounded hot head. The small
		// halo is confined to the head; the rest is a crisp cooling thread.
		float x = vUv.x;
		float bend = sin(x * 3.14159265) * 0.055 * vU;
		float radius = mix(0.038, 0.19, sqrt(clamp(x, 0.0, 1.0)));
		float y = abs(vUv.y - bend);
		float edge_aa = clamp(fwidth(vUv.y) * 0.62, 0.012, 0.29);
		float head = 1.0 - smoothstep(0.84, 0.995, x);
		float thread = (1.0 - smoothstep(radius - edge_aa, radius + edge_aa, y)) * smoothstep(0.015, 0.68, x) * head;
		float heat = 1.0 - smoothstep(0.06, 0.72, vU);
		float white = heat * smoothstep(0.45, 0.90, x) * 0.93;
		float energy = max(vCol.r, max(vCol.g, vCol.b));
		float halo_x = (x - 0.86) * 2.1;
		float halo = exp(-13.0 * halo_x * halo_x - 17.0 * y * y) * head * heat * 0.13;
		ALBEDO = (mix(vCol, vec3(energy), white) * thread + vCol * halo) * fx_gain;
	} else {
		// The baked tail is displaced across its quad to curve the cooling
		// history. The hot head stays on the true ballistic position.
		float bend = (k == 1 || k == 6 || k == 7) ? sin(vUv.x * 3.14159265) * 0.18 : 0.0;
		vec2 uv = vec2(vUv.x, vUv.y + 0.5 + bend);
		vec3 mask = texture(kit_tail, uv).rgb;
		float crawl = 0.85 + 0.15 * sin(vUv.x * 23.0 - scene_t * 19.0);
		vec3 hot = mix(vCol, vec3(length(vCol)), 0.68);
		vec3 c = hot * mask.r * 0.7 + vCol * (mask.g * 0.8 + mask.b * 0.65) * crawl;
		if (k == 4) {
			// Las keeps its hard dart identity, with an irregular scrolling core.
			float x = abs(vUv.y * 2.0);
			float ends = smoothstep(0.0, 0.13, vUv.x) * (1.0 - smoothstep(0.90, 1.0, vUv.x));
			c += (hot * exp(-x*x*12.0) * 0.18 + vCol * exp(-x*x*2.8) * 0.22) * ends * crawl;
	} else if (k == 3) {
		c *= 0.65 + 0.35 * sin(vUv.x * 13.0 - scene_t * 8.0);
	}
	ALBEDO = clamp(c * fx_gain, 0.0, 512.0);
	}
}
"""

# Oriented rings. a1 = (normal, life); a3 = (size0, size1, kind, seed); a4 = (period, speed, drag, 0).
# kinds: 0 smoke ring (alpha)   1 shockwave   2 soft pop ring (reduce-flashing replacement)   3 thin pale ring (gauss
#        muzzle shock, sonic boom)   4 hex-cell ring (Hegemony shield shatter)
const RING := """
shader_type spatial;
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
varying vec2 vUv;
varying vec4 vCol;
varying vec4 vInfo;
void vertex() {
	vec4 a0 = CUSTOM0; vec4 a1 = CUSTOM1; vec4 a2 = CUSTOM2; vec4 a3 = CUSTOM3; vec4 a4 = vec4(UV, UV2);
	float a = scene_t - a0.w;
	float age = pAge(a, a4.x);
	float life = a1.w;
	vUv = vec2(0.0); vCol = vec4(0.0); vInfo = vec4(0.0);
	if (a < 0.0 || age >= life) {
		""" + HIDE + """
	} else {
		float t = age / life;
		vec3 n = snorm(a1.xyz);
		float dr = a4.z;
		float tr = dr > 0.0 ? a4.y * (1.0 - exp(-dr * age)) / dr : a4.y * age;
		vec3 c = a0.xyz + n * tr;
		vec3 up = abs(n.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
		vec3 t1 = snorm(cross(n, up));
		vec3 t2 = cross(n, t1);
		float g = a3.z < 0.5 ? 1.0 - spow(1.0 - t, 2.0) : 1.0 - spow(1.0 - t, 3.0);
		float size = mix(a3.x, a3.y, g);
		// F3: shock fronts, soft pops and pale shock rings keep at least 12 px across (1080 lines), dimming as they grow
		float rb = 1.0;
		int rk = int(a3.z + 0.5);
		if (rk >= 1 && rk <= 3) {
			// round 2: a4.w is this ring's own final size in pixels (kill shock rings, shield ripples): the floor grows with
			// the ring's own easing (15% to 100% of it), so a far ring still visibly expands; grown to it, it dims as f^-0.5
			float dv = max(-(VIEW_MATRIX * (MODEL_MATRIX * vec4(c, 1.0))).z, 0.01);
			float mn = px_world(12.0, dv, PROJECTION_MATRIX);
			if (a4.w > 12.0) { mn = max(mn, px_world(a4.w, dv, PROJECTION_MATRIX) * mix(0.15, 1.0, g)); }
			if (size < mn) {
				rb = clamp(spow(mn / max(size, 1e-5), a4.w > 12.0 ? -0.5 : -1.0), 0.05, 1.0);
				size = mn;
			}
		}
		vec3 p = c + (t1 * VERTEX.x + t2 * VERTEX.y) * size;
		POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * (MODEL_MATRIX * vec4(p, 1.0)));
		vUv = VERTEX.xy * 2.0;
		vCol = vec4(a2.rgb, a2.a * rb);
		vInfo = vec4(t, a3.z, a3.w, age);
	}
}
void fragment() {
	float t = vInfo.x; float seed = vInfo.z; float age = vInfo.w; int k = int(vInfo.y + 0.5);
	vec2 p = vUv;
	float r = length(p);
	if (r > 1.0) { discard; }
	float ang = atan(p.y, p.x);
	vec3 add = vec3(0.0); vec3 base = vec3(0.0); float alpha = 0.0;
	if (k == 0) {
		float n = fbm(vec2(ang * 1.6 + seed * 7.0, r * 3.0 + age * 0.3));
		float w = 0.15 + 0.12 * t;
		float rq = (r - 0.62) / w;
		float rg = exp(-rq * rq);
		float dens = rg * (0.55 + 0.9 * n);
		alpha = clamp(dens, 0.0, 1.0) * vCol.a * smoothstep(0.0, 0.05, t) * spow(1.0 - t, 1.4);
		base = vCol.rgb * (0.75 + 0.5 * n);
		add = vec3(1.0, 0.45, 0.1) * spow(1.0 - t, 10.0) * alpha * 2.0;
	} else if (k == 1) {
		// a shock front of hot gas, broken into arcs and soft (r4 review: a thin neon circle read as a cartoon)
		float d1 = (r - 0.93) / (0.04 + 0.03 * t);
		float d2 = (r - 0.8) / 0.14;
		float rg = exp(-d1 * d1) * 0.9 + exp(-d2 * d2) * 0.25;
		float n = smoothstep(0.3, 0.75, fbm(vec2(ang * 3.0 + seed * 5.0, t * 2.0 + r * 2.0))) * 1.3;
		vec3 col = mix(vec3(1.0, 0.85, 0.65), vCol.rgb, sqrt(t));
		add = col * rg * n * spow(1.0 - t, 1.5) * vCol.a;
	} else if (k == 2) {
		float d1 = (r - 0.9) / 0.08;
		add = vCol.rgb * exp(-d1 * d1) * sin(3.14159 * t) * vCol.a + vCol.rgb * exp(-r * r * 3.0) * 0.15 * sin(3.14159 * t) * vCol.a;
	} else if (k == 3) {
		float d1 = (r - 0.93) / 0.03;
		add = vCol.rgb * exp(-d1 * d1) * spow(1.0 - t, 2.0) * vCol.a;
	} else {
		// a ring of hex cells that flies apart (shield shatter)
		vec2 q = p * 7.0;
		vec2 h = vec2(q.x * 1.1547, q.y + q.x * 0.57735);
		vec2 f = fract(h) - 0.5;
		float cell = max(abs(f.x), abs(f.y));
		float edge = smoothstep(0.38, 0.5, cell);
		float id = h21(floor(h) + seed);
		float ringm = exp(-spow((r - (0.4 + 0.55 * t + id * 0.1)) / 0.18, 2.0));
		float live = step(id, 1.0 - t * 0.9);
		add = vCol.rgb * (edge * 1.6 + 0.25) * ringm * live * spow(1.0 - t, 1.2) * vCol.a;
	}
	ALBEDO = clamp(base * alpha + add * fx_gain, 0.0, 512.0);
	ALPHA = clamp(alpha, 0.0, 1.0);
}
"""

# Ribbons along a straight line: plumes, beams, arcs. VERTEX = (s along 0..1, side -0.5..0.5).
# a0 = (origin, kind); a1 = (dir, length); a2 = (colour, intensity); a3 = (width0, width1, seed, 0);
# a4 = (tStart, life, period, 0)
# kinds: 0 plume   1 straight trail (idle)   2 beam (lance)   3 sputter plume   5 ion beam (beam plus crawling arcs)
#        6 doom arc (jagged lightning)   7 pulsar (beam in travelling pulses)   8 needle beam (thin, prismatic)
#        9 tendril (bio lash: thick, organic, wriggling)
const RIBBON := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform float gate = 1.0;
uniform sampler2D kit_flow : filter_linear, repeat_enable;
varying float vPixels;
uniform float lenk = 1.0;
varying vec4 vCol;
varying vec3 vInfo;
varying vec2 vInfo2;
varying float vSide;
varying vec2 vAge;
void vertex() {
	vec4 a0 = CUSTOM0; vec4 a1 = CUSTOM1; vec4 a2 = CUSTOM2; vec4 a3 = CUSTOM3; vec4 a4 = vec4(UV, UV2);
	float a = scene_t - a4.x;
	float age = pAge(a, a4.z);
	vPixels = 1.0; vCol = vec4(0.0); vInfo = vec3(0.0); vInfo2 = vec2(0.0); vSide = 0.0; vAge = vec2(0.0);
	if (a < 0.0 || age >= a4.y || gate <= 0.001) {
		""" + HIDE + """
	} else {
		float s = VERTEX.x;
		int k = int(a0.w + 0.5);
		vec3 dir = snorm(a1.xyz);
		float seed = a3.z;
		float L = a1.w * (k == 0 || k == 3 ? lenk : 1.0);
		if (k == 9) { L *= smoothstep(0.0, 0.25, age) * (1.0 - smoothstep(a4.y - 0.25, a4.y, age)); }
		vec3 p = a0.xyz + dir * s * L;
		vec3 up = abs(dir.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
		vec3 n1 = snorm(cross(dir, up));
		vec3 n2 = cross(n1, dir);
		if (k == 1) {
			p += (n1 * sin(s * 7.0 - scene_t * 1.3 + seed * 6.0) * 0.9 + n2 * sin(s * 5.0 - scene_t * 0.9 + seed * 3.0) * 0.7) * s * s * 2.2;
		}
		if (k == 0 || k == 3) {
			p += (n1 * (vnoise(vec2(s * 6.0 - scene_t * 18.0, seed)) - 0.5) + n2 * (vnoise(vec2(s * 6.0 - scene_t * 17.0, seed + 3.0)) - 0.5)) * s * a3.x * 0.5;
		}
		if (k == 6) {
			// lightning: a jagged path that re-strikes every 70 ms, pinned at both ends
			float strike = floor(age / mix(0.07, 0.23, fx_calm));
			float j = (vnoise(vec2(s * 9.0, strike * 3.1 + seed)) - 0.5) * 2.0 + (vnoise(vec2(s * 31.0, strike * 1.7 + seed)) - 0.5) * 0.6;
			float j2 = (vnoise(vec2(s * 8.0 + 4.0, strike * 2.3 + seed)) - 0.5) * 2.0;
			float pin = sin(3.14159 * s);
			p += (n1 * j + n2 * j2) * pin * L * 0.06;
		}
		if (k == 9) {
			// A broad bend runs out to the tip, snaps taut on contact, then curls back.
			// Keep both ends on the firing line while the middle sweeps across it.
			float slack = 1.0 - 0.8 * smoothstep(0.16, 0.25, age) * (1.0 - smoothstep(0.28, 0.57, age));
			float bend = sin(3.14159265 * s) * min(L * 0.18, a3.x * 7.0) * slack;
			float wave = s * 7.0 - age * 12.0 + seed * 6.2831853;
			p += (n1 * sin(wave) + n2 * (0.5 * cos(wave * 0.75))) * bend;
		}
		float w = mix(a3.x, a3.y, s);
		if (k == 2 || k == 5 || k == 8) { w *= 0.92 + 0.08 * sin(scene_t * 90.0 + s * 40.0); }
		vec3 wp = (MODEL_MATRIX * vec4(p, 1.0)).xyz;
		vec3 wdir = snorm((MODEL_MATRIX * vec4(dir, 0.0)).xyz);
		vec3 side = snorm(cross(wdir, CAMERA_POSITION_WORLD - wp));
		// Screen-resolved hot core and sheath, including at camera 170.
		// Fragment widths below are FWHM in render-target pixels.
		// Doom's wider quad is room for forks, not a wider white trunk.
		float rf = k == 6 ? 64.0 : (k == 8 ? 12.0 : (k == 1 ? 10.0 : ((k == 0 || k == 3) ? 12.0 : 16.0)));
		float bw = 1.0;
		float pixel_unit = frame_world(1.0, max(-(VIEW_MATRIX * vec4(wp, 1.0)).z, 0.01), PROJECTION_MATRIX, VIEWPORT_SIZE.y);
		w = max(w, max(px_world(rf, max(-(VIEW_MATRIX * vec4(wp, 1.0)).z, 0.01), PROJECTION_MATRIX), pixel_unit * rf));
		vPixels = w / max(pixel_unit, 0.00001);
		wp += side * VERTEX.y * w;
		vInfo2 = vec2(L, w);
		POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(wp, 1.0));
		vSide = VERTEX.y * 2.0;
		vCol = vec4(a2.rgb, a2.a * gate * bw);
		vInfo = vec3(s, a0.w, seed);
		vAge = vec2(age, a4.y);
	}
}
void fragment() {
	float s = vInfo.x; int k = int(vInfo.y + 0.5); float seed = vInfo.z;
	float life = max(vAge.y, 0.001); float age = vAge.x;
	float x = abs(vSide);
	// Fixed beam details use 1080-line pixels (issue 1211).
	float fr = max(VIEWPORT_SIZE.y / 1080.0, 0.0001);
	float beam_pixels = vPixels;
	if (k == 5 || k == 8 || k == 11) {
		beam_pixels /= fr;
	}
	float px = x * beam_pixels * 0.5;
	float hot_floor = k == 8 ? 2.0 : 3.0;
	float hot_width = k == 6 ? 3.0 * fr : max(hot_floor, beam_pixels * 0.17);
	float glow_width = k == 6 ? 11.0 * fr : max(7.0, beam_pixels * 0.48);
	float core = exp(-2.772589 * px * px / (hot_width * hot_width));
	float sheath = exp(-2.772589 * px * px / (glow_width * glow_width));
	float fast = texture(kit_flow, vec2(fract(s * 3.0 - age * 2.4 + seed), vSide * 0.5 + 0.5)).g;
	float slow = texture(kit_flow, vec2(fract(s * 2.0 + age * 0.7 + seed), vSide * 0.5 + 0.5)).b;
	float env = smoothstep(0.0, mix(0.025, 0.12, fx_calm), age) * (1.0 - smoothstep(max(life - 0.16, 0.0), life, age));
	float ends = smoothstep(0.0, 0.025, s) * (1.0 - smoothstep(0.95, 1.0, s));
	vec3 hot = mix(vec3(1.0, 0.97, 0.92), vCol.rgb, 0.14);
	vec3 tint = vCol.rgb;
	float motion = 0.75 + 0.5 * fast;
	float fork_hot = 0.0; float fork_glow = 0.0;
	if (k == 0 || k == 3) {
		float turbulence = fbm(vec2(s * 9.0 - age * 8.0, vSide * 3.0 + seed));
		float shape = spow(1.0 - s, 1.25) * smoothstep(0.22, 0.65, turbulence + 0.2);
		core *= shape * (0.8 + 0.3 * sin(s * 29.0 - age * 9.0));
		sheath *= shape;
		if (k == 3) { motion *= mix(cough(scene_t - s * 0.2, seed), 0.8, fx_calm); }
		ends = 1.0 - smoothstep(0.72, 1.0, s);
	} else if (k == 1) {
		float fade = spow(1.0 - s, 1.5);
		core *= fade * 0.4;
		sheath *= fade * (0.4 + slow);
	} else if (k == 6) {
		// Keep the faction hue in the sheath without whitening it into the
		// trunk. Forks reach outside the trunk's bloom footprint.
		tint /= max(max(tint.r, tint.g), max(tint.b, 0.0001));
		tint = mix(tint, tint * tint * tint * tint, 0.8);
		float strike = floor(age / mix(0.07, 0.23, fx_calm));
		motion = flick(0.75 + 0.25 * h21(vec2(strike, seed)), age, seed);
		// Forks grow from the live jagged path. They occupy distinct filled
		// pixels inside the wider sheath, and never detach from the trunk.
		float q = fract(s * 4.0 + seed);
		float sign_side = mod(floor(s * 4.0 + seed), 2.0) * 2.0 - 1.0;
		float target = sign_side * q * 1.7;
		float d = (vSide - target) * vPixels * 0.5 / fr;
		float window = smoothstep(0.0, 0.04, q) * (1.0 - smoothstep(0.32, 0.55, q));
		fork_hot = exp(-2.772589 * d*d / 4.0) * window;
		fork_glow = exp(-2.772589 * d*d / 25.0) * window;
	} else if (k == 5) {
		// Broken crawling filaments, replacing the regular diagonal bands.
		float arc = sin(s * 27.0 - age * 17.0 + seed) * 0.55;
		float d = (vSide - arc) * beam_pixels * 0.5;
		fork_hot = exp(-2.772589 * d*d / 4.0) * smoothstep(0.45, 0.7, fast);
	} else if (k == 7) {
		float pulse = spow(0.5 + 0.5 * sin(s * 30.0 - age * 25.0), 3.0);
		motion *= 0.35 + pulse;
		vec3 rainbow = clamp(abs(fract(x * 0.45 + s * 0.6 - age * 0.4 + seed + vec3(0.0, 0.333, 0.667)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
		tint = mix(tint, rainbow, 0.65);
	} else if (k == 8) {
		motion *= 0.7 + 0.5 * spow(0.5 + 0.5 * sin(s * 63.0 - age * 28.0), 6.0);
		// A white needle with a thin, moving spectrum along either edge.
		vec3 rainbow = clamp(abs(fract(vSide * 0.30 + s * 0.45 - age * 0.35 + seed + vec3(0.0, 0.333, 0.667)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
		tint = mix(tint, rainbow, smoothstep(1.1, 3.0, px) * 0.90);
	} else if (k == 9) {
		float tissue = fbm(vec2(s * 14.0 - age * 3.0, vSide * 2.0 + seed));
		core *= 0.5 + tissue;
		sheath *= smoothstep(0.2, 0.7, tissue + 0.2);
		hot = mix(hot, tint, 0.5);
	} else if (k == 11) {
		// Null lance: two pinched rails around a violet-white core.
		float pinch = 2.0 + 3.5 * sin(s * 3.14159);
		float d = (px - pinch) / 1.15;
		float rails = exp(-d*d) * (0.75 + 0.25 * fast);
		hot = mix(hot, tint, 0.45);
		core *= 0.8;
		sheath = sheath * 0.30 + rails * 1.35;
		motion = 1.0;
	}
	vec3 colour = hot * (core * 1.35 + fork_hot) + tint * (sheath * (0.55 + slow * 0.7) + fork_glow * 0.5);
	ALBEDO = clamp(colour * vCol.a * motion * env * ends * fx_gain, 0.0, 512.0);
}
"""

# Engine exhaust trails that follow a moving ship: a strip through the nozzle's recent positions (world space).
# VERTEX = centre point; NORMAL = the path's direction there; UV = (s along 0..1, side -0.5..0.5);
# CUSTOM0 = (colour, intensity); CUSTOM1 = (width0, width1, seed, style) with style 0 clean, 1 sooty sputter, 2 spore puffs,
# 3 guttering embers.
const TRAIL := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled, skip_vertex_transform;
""" + COMMON + """
uniform float trail_elapsed = 0.0;
uniform float trail_style = 0.0;
varying vec4 vCol;
varying vec4 vInfo;
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 wd = snorm((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float s = clamp(UV.x + trail_elapsed, 0.0, 1.0);
	float w = mix(CUSTOM1.x, CUSTOM1.y, s);
	vec3 side = snorm(cross(wd, CAMERA_POSITION_WORLD - wp));
	float seed = CUSTOM1.z;
	float du = frame_world(1.0, max(-(VIEW_MATRIX * vec4(wp, 1.0)).z, 0.01), PROJECTION_MATRIX, VIEWPORT_SIZE.y);
	float trail_floor = du * 10.0 * (VIEWPORT_SIZE.y / 1080.0);
	w = max(w, trail_floor);
	wp += side * UV.y * w;
	VERTEX = (VIEW_MATRIX * vec4(wp, 1.0)).xyz;
	vCol = CUSTOM0;
	vInfo = vec4(s, UV.y * 2.0, seed, trail_style);
}
void fragment() {
	float s = vInfo.x; float x = abs(vInfo.y); float seed = vInfo.z; int st = int(vInfo.w + 0.5);
	float n = fbm(vec2(s * 14.0 - scene_t * 0.6, vInfo.y * 1.2 + seed * 3.0));
	float n2 = fbm(vec2(s * 40.0 - scene_t * 0.5, vInfo.y * 2.0 + seed * 3.0));
	n = 0.5 * n + 0.5 * n2;
	float across = exp(-x * x * 2.2);
	float fade = spow(1.0 - s, 1.8);
	vec3 col = mix(vCol.rgb, vec3(0.30, 0.38, 0.60), smoothstep(0.0, 0.55, s));
	float m = smoothstep(0.25, 0.75, n + 0.15);
	if (st == 1) {
		col = mix(col, vec3(0.35, 0.25, 0.18), 0.5) * (0.5 + 0.5 * mix(cough(scene_t - s * 3.0, seed), 0.7, fx_calm));
	} else if (st == 2) {
		m *= 0.6 + 0.8 * smoothstep(0.55, 0.8, fbm(vec2(s * 22.0 - scene_t * 0.4, seed)));
	} else if (st == 3) {
		col *= 0.55 + 0.45 * vnoise(vec2(s * 9.0 - scene_t * 2.0, seed));
		col += vec3(1.0, 0.5, 0.15) * spow(vnoise(vec2(s * 60.0 - scene_t, seed * 3.0)), 12.0) * 2.0;
	}
	float root = smoothstep(0.0, 0.025, s);
	vec3 hot = mix(col, vec3(1.0, 0.94, 0.82), 0.6) * exp(-x*x*16.0) * 0.5;
	ALBEDO = clamp((col * across * m * 1.4 + hot) * root * fade * vCol.a * fx_gain, 0.0, 512.0);
}
"""

# Issue 1558 item 8: a kit torpedo/rocket trail. Same look as TRAIL, but the strip is one shared fixed mesh (point i
# in VERTEX.x, side in UV.y) and its samples come in the `pts` array (xyz world position, w birth time), so a moving
# round only uploads a small uniform each frame instead of building a new ArrayMesh. Samples past `count` collapse
# onto the last one with no width, so the unused end of the strip has no area.
static func kit_trail_code(points: int) -> String:
	var c: String = TRAIL.replace("uniform float trail_elapsed = 0.0;",
		"uniform vec4 pts[%d];\nuniform int count = 0;\nuniform float life = 0.38;\nuniform vec4 eng = vec4(1.0);\nuniform vec3 widths = vec3(0.1, 0.2, 0.0);" % points)
	c = c.replace("""	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 wd = snorm((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float s = clamp(UV.x + trail_elapsed, 0.0, 1.0);
	float w = mix(CUSTOM1.x, CUSTOM1.y, s);""", """	int n = max(count, 1);
	int i = int(VERTEX.x + 0.5);
	int k = min(i, n - 1);
	vec3 wp = pts[k].xyz;
	vec3 wd = snorm(pts[min(k + 1, n - 1)].xyz - pts[max(k - 1, 0)].xyz);
	float s = clamp((scene_t - pts[k].w) / max(life, 0.001), 0.0, 1.0);
	float w = i < n ? mix(widths.x, widths.y, s) : 0.0;""")
	c = c.replace("w = max(w, trail_floor);", "w = i < n ? max(w, trail_floor) : 0.0;")
	c = c.replace("float seed = CUSTOM1.z;", "float seed = widths.z;")
	c = c.replace("vCol = CUSTOM0;", "vCol = eng;")
	assert(c.contains("uniform vec4 pts[") and c.contains("vCol = eng;") and c.contains("float seed = widths.z;") and c.contains("i < n ? max(w"))
	return c


# Strike-craft history from squadron_wing's real stern samples. Kept here so
# attack runs and live wings use the same kit without changing their movement.
const CRAFT_TRAIL := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform sampler2D kit_flow : filter_linear, repeat_enable;
uniform float clock_now = 0.0;
uniform float newest_birth = 0.0;
uniform float trail_len = 1.0;
uniform float width_k = 0.026;
uniform float alpha_k = 0.56;
uniform float anchor_ready = 0.0;
uniform vec3 head_world = vec3(0.0);
varying vec2 vFromHead;
varying float vSide;
varying float vAge;
varying vec3 vTint;
void vertex() {
	float age = max(clock_now - UV2.x, 0.0);
	vec3 p = VERTEX + NORMAL * age * trail_len * 1.2;
	// The newest pair stays on the actual stern between 30 Hz samples.
	if (abs(UV2.x - newest_birth) < 0.0001) { p = head_world; }
	vec3 back = snorm(NORMAL);
	vec3 side = snorm(cross(back, CAMERA_POSITION_WORLD - p));
	float depth = max(-(VIEW_MATRIX * vec4(p, 1.0)).z, 0.01);
	float width = max(trail_len * width_k * (1.0 + age), max(px_world(10.0, depth, PROJECTION_MATRIX), frame_world(8.0, depth, PROJECTION_MATRIX, VIEWPORT_SIZE.y)));
	vec4 pc = PROJECTION_MATRIX * VIEW_MATRIX * vec4(p, 1.0);
	vec4 hc = PROJECTION_MATRIX * VIEW_MATRIX * vec4(head_world, 1.0);
	// issue 1211: in 1080-line pixels, so the 24 px tail and its flow keep their shape at 4K
	vFromHead = (pc.xy / max(pc.w, 0.0001) - hc.xy / max(hc.w, 0.0001)) * VIEWPORT_SIZE * 0.5 * (1080.0 / max(VIEWPORT_SIZE.y, 1.0));
	vSide = UV.y * 2.0 - 1.0;
	vAge = age;
	vTint = COLOR.rgb;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(p + side * vSide * width * 0.5, 1.0);
}
void fragment() {
	float distance_px = length(vFromHead);
	if (anchor_ready < 0.5 || distance_px >= 24.0 || vAge >= 0.65) { discard; }
	float fade = spow(1.0 - distance_px / 24.0, 1.35) * (1.0 - vAge / 0.65);
	float flow = texture(kit_flow, vec2(fract(distance_px / 18.0 - clock_now * 1.4), vSide * 0.5 + 0.5)).g;
	float core = exp(-vSide * vSide * 16.0);
	float sheath = exp(-vSide * vSide * 2.4);
	vec3 hot = mix(vTint, vec3(1.0, 0.96, 0.86), 0.65);
	ALBEDO = (hot * core * 1.4 + vTint * sheath * (0.6 + flow)) * fade * alpha_k * 2.0 * fx_gain;
}
"""

# Debris chips: tumbling 3D shards lit by the scene lights, hot at first.
# a1 = (vel, life); a2 = (spin axis, spin rate); a3 = (size, period, tint, drag); a4 = (heat, seed, 0, 0)
const SHARD := """
shader_type spatial;
render_mode cull_back, fog_disabled;
""" + COMMON + """
varying float vHeat;
varying float vSeed;
varying float vTint;
vec3 rotA(vec3 v, vec3 k, float an) { float c = cos(an); float s = sin(an); return v * c + cross(k, v) * s + k * dot(k, v) * (1.0 - c); }
void vertex() {
	vec4 a0 = CUSTOM0; vec4 a1 = CUSTOM1; vec4 a2 = CUSTOM2; vec4 a3 = CUSTOM3; vec4 a4 = vec4(UV, UV2);
	float a = scene_t - a0.w;
	float age = pAge(a, a3.y);
	float life = a1.w;
	vHeat = 0.0; vSeed = a4.y; vTint = a3.z;
	if (a < 0.0 || age >= life) {
		VERTEX = vec3(0.0, -50000.0, 0.0);
	} else {
		float t = age / life;
		float size = a3.x;
		if (a3.z >= 3.0) {
			// Hit plates must remain pieces at camera 170 after cooling, rather than disappearing into the stars.
			vec3 centre = a0.xyz + (a3.w > 0.0 ? a1.xyz * (1.0 - exp(-a3.w * age)) / a3.w : a1.xyz * age);
			float depth = -(VIEW_MATRIX * MODEL_MATRIX * vec4(centre, 1.0)).z;
			size = max(size, px_world(8.0, depth, PROJECTION_MATRIX));
		}
		float sc = size * (1.0 - smoothstep(0.85, 1.0, t));
		vec3 k = snorm(a2.xyz);
		float an = age * a2.w + a4.y * 6.2831853;
		float dr = a3.w;
		vec3 disp = dr > 0.0 ? a1.xyz * (1.0 - exp(-dr * age)) / dr : a1.xyz * age;
		VERTEX = a0.xyz + disp + rotA(VERTEX, k, an) * sc;
		NORMAL = rotA(NORMAL, k, an);
		vHeat = a4.x * exp(-age * (a3.z >= 3.0 ? 0.85 : 3.5));
	}
}
void fragment() {
	vec3 alb = vec3(0.032, 0.032, 0.036) * (0.6 + 0.9 * fract(vSeed * 17.3));
	if (vTint > 0.5) { alb = vec3(0.05, 0.06, 0.035) * (0.6 + 0.9 * fract(vSeed * 17.3)); }
	if (vTint >= 3.0) { alb = vec3(0.19, 0.16, 0.13) * (0.65 + 0.55 * fract(vSeed * 17.3)); }
	ALBEDO = alb;
	METALLIC = 0.5;
	ROUGHNESS = 0.45;
	EMISSION = vec3(1.0, 0.33, 0.06) * vHeat * 1.2 * fx_gain;
	if ((vTint > 1.5 && vTint < 2.5) || vTint > 3.5) {
		ALBEDO = vec3(0.3, 0.45, 0.6); METALLIC = 0.1; ROUGHNESS = 0.08;
		EMISSION = mix(vec3(0.2, 0.8, 1.0), vec3(0.9, 0.3, 1.0), abs(dot(NORMAL, VIEW))) * (0.08 + vHeat * 0.3) * fx_gain;
	}
}
"""

# Hull-hit fragments. The old SHARD material also serves other effects, so it has its own shader.
# a0 = (origin, born); a1 = (velocity, life); a2 = (tumble axis, spin); a3 = (size, phase, profile key, drag).
# a4 = (linear hull paint, fracture heat); the remaining texels carry the hit UV and finish.
# Negative profile keys mark the lead pieces.
const HIT_FRAGMENT := """
shader_type spatial;
render_mode cull_back, fog_disabled;
""" + COMMON + """
uniform sampler2D fragment_meshes : filter_nearest, repeat_disable;
uniform sampler2D fragment_instances : filter_nearest, repeat_disable;
uniform int glass_profile;
// FINISH_SAMPLERS
varying vec4 part_pos; // template position and distance from cap centre toward the rim
varying flat vec4 surface_data; // surface class, glass, heat, visibility
varying flat vec3 paint;
varying flat vec4 finish_tint; // ship albedo multiplier and roughness
varying flat vec4 finish_orm; // metallic, specular, packed ORM present, source slot
varying flat float normal_scale;
varying vec2 paint_uv;
varying vec2 tear_uv;
vec3 turn_fragment(vec3 v, vec3 k, float c, float s) {
	return v * c + cross(k, v) * s + k * dot(k, v) * (1.0 - c);
}
vec4 particle_data(int column, int slot_index) {
	return texelFetch(fragment_instances, ivec2(column, slot_index), 0);
}
void vertex() {
	int slot_index = INSTANCE_ID;
	vec4 a0 = particle_data(1, slot_index);
	vec4 a1 = particle_data(2, slot_index);
	float age = scene_t - a0.w;
	if (age < 0.0 || age >= a1.w) {
		VERTEX = vec3(0.0, -50000.0, 0.0);
	} else {
		vec4 a2 = particle_data(3, slot_index);
		vec4 a3 = particle_data(4, slot_index);
		vec4 a4 = particle_data(0, slot_index);
		bool lead = a3.z < 0.0;
		int profile = int(lead ? -1.0 - a3.z : a3.z);
		int row = profile * 3;
		vec4 points = texelFetch(fragment_meshes, ivec2(VERTEX_ID, row), 0);
		vec4 normals = texelFetch(fragment_meshes, ivec2(VERTEX_ID, row + 1), 0);
		tear_uv = texelFetch(fragment_meshes, ivec2(VERTEX_ID, row + 2), 0).xy;
		vec3 centre = a0.xyz + pDisp(a1.xyz, a3.w, 0.0, age);
		float depth = -(VIEW_MATRIX * MODEL_MATRIX * vec4(centre, 1.0)).z;
		float pixel = frame_world(1.0, depth, PROJECTION_MATRIX, 1080.0);
		// Mid-sized pieces get a smaller boost. Flecks still follow their world size.
		float floor_px = lead ? 10.0 : 6.5 * smoothstep(0.21, 0.45, a3.x);
		float scale = max(a3.x, px_world(floor_px, depth, PROJECTION_MATRIX));
		float distance_fade = lead ? 1.0 : smoothstep(0.55, 1.45, scale / pixel);
		float t = age / a1.w;
		vec3 axis = snorm(a2.xyz);
		float angle = a3.y * 6.2831853 + age * a2.w;
		float c = cos(angle);
		float s = sin(angle);
		VERTEX = centre + turn_fragment(points.xyz, axis, c, s) * scale;
		NORMAL = turn_fragment(normals.xyz, axis, c, s);
		part_pos = points;
		paint = a4.rgb * mix(0.65, 1.05, a3.y);
		vec4 patch_u = particle_data(5, slot_index);
		vec4 patch_v = particle_data(6, slot_index);
		// Use the real size in the source patch even when the battle camera lifts the image size.
		vec2 offset = (points.xz + vec2(a3.y - 0.5, fract(a3.y * 7.0) - 0.5) * 0.55) * a3.x;
		paint_uv = patch_u.xy + patch_u.zw * offset.x + patch_v.xy * offset.y;
		finish_tint = particle_data(7, slot_index);
		finish_orm = vec4(particle_data(8, slot_index).xyz, patch_v.z);
		normal_scale = patch_v.w;
		float heat = a4.w * (1.0 - smoothstep(0.08, 1.05, age));
		surface_data = vec4(normals.w, float(profile >= glass_profile), heat, distance_fade * (1.0 - smoothstep(0.55, 1.0, t)));
	}
}

// Build the normal-map basis from the same UV gradients as the material. This also
// follows the smooth cap normals through folds and preserves the wall's hard normals.
vec3 mapped_normal(vec3 n, vec3 dx, vec3 dy, vec2 ux, vec2 uy, vec2 tilt) {
	vec3 t = cross(dy, n) * ux.x + cross(n, dx) * uy.x;
	vec3 b = cross(dy, n) * ux.y + cross(n, dx) * uy.y;
	float scale = max(dot(t, t), dot(b, b));
	return normalize(n + (t * tilt.x + b * tilt.y) * inversesqrt(max(scale, 1e-12)));
}

void fragment() {
	float fade = surface_data.w;
	vec2 dx = dFdx(paint_uv);
	vec2 dy = dFdy(paint_uv);
	vec2 tx = dFdx(tear_uv);
	vec2 ty = dFdy(tear_uv);
	vec3 px = dFdx(VERTEX);
	vec3 py = dFdy(VERTEX);
	float lip_width = min(0.12, fwidth(part_pos.w) * 0.35);
	if (fade < 1.0 && fade <= h21(floor(FRAGCOORD.xy))) {
		discard;
	}
	float wall = step(1.5, surface_data.x);
	float inside = step(0.5, surface_data.x) - wall;
	int slot = int(finish_orm.w);
	float heat = surface_data.z * mix(1.0, 0.45, fx_calm);
	float wear = vnoise(part_pos.xz * vec2(16.0, 29.0) + part_pos.y * 11.0);
	float scorch = smoothstep(0.78, 1.0, part_pos.w) * mix(0.25, 0.69, wear);
	float lip = smoothstep(mix(0.87, 0.96, wear) - lip_width, 1.0, part_pos.w);
	vec3 baked = paint * mix(0.64, 1.15, wear);
	vec3 orm = vec3(1.0);
	vec2 map_normal = vec2(0.0);
	// FINISH_SAMPLES
	if (slot >= 0) {
		baked *= finish_tint.rgb;
	}
	vec3 charred = baked * 0.11 + vec3(0.023, 0.018, 0.014);
	ALBEDO = mix(baked, charred, max(scorch, inside));
	METALLIC = mix(0.23, 0.63, wall);
	ROUGHNESS = mix(0.79 - 0.15 * wear, 0.38, wall);
	if (slot >= 0) {
		float packed = finish_orm.z;
		AO = mix(1.0, orm.r, packed * (1.0 - wall));
		METALLIC = mix(clamp(finish_orm.x * mix(1.0, orm.b, packed), 0.0, 1.0), 0.36, max(inside, wall));
		ROUGHNESS = clamp(finish_tint.a * mix(1.0, orm.g, packed) + 0.13 * scorch, 0.18, 0.96);
		SPECULAR = finish_orm.y;
	}
	if (wall > 0.5) {
		// Thin paint and a darker liner frame the bright torn alloy. Filter the
		// cross-section boundaries and directional scratch normals at pixel scale.
		float band_aa = max(0.022, (abs(tx.y) + abs(ty.y)) * 0.55);
		float skin = smoothstep(0.38 - band_aa, 0.38 + band_aa, tear_uv.y);
		float liner = 1.0 - smoothstep(-0.44 - band_aa, -0.44 + band_aa, tear_uv.y);
		vec2 grain = tear_uv * vec2(108.0, 4.0);
		float scratch = vnoise(grain);
		float grain_filter = 1.0 - smoothstep(0.28, 1.15, length(fwidth(grain)));
		vec3 alloy = vec3(0.29, 0.25, 0.21) * mix(0.58, 1.35, mix(0.5, scratch, grain_filter));
		ALBEDO = mix(mix(alloy, charred * 0.62, liner), baked * 0.59, skin);
		METALLIC = mix(0.83, 0.27, max(skin, liner));
		ROUGHNESS = mix(0.32 + 0.15 * scratch, 0.72, max(skin, liner));
		vec2 grain_normal = vec2(scratch - vnoise(grain + vec2(0.37, 0.0)), (scratch - 0.5) * 0.18);
		NORMAL = mapped_normal(NORMAL, px, py, tx, ty, grain_normal * (0.85 * grain_filter) + map_normal * 0.13);
	} else {
		float ribs = cos((part_pos.z * 22.0 + part_pos.x * 3.0) * 6.2831853);
		float rib_mask = 1.0 - smoothstep(0.10, 0.42, fwidth(part_pos.z * 22.0 + part_pos.x * 3.0));
		ALBEDO *= 1.0 + ribs * 0.27 * inside * rib_mask;
		ROUGHNESS = mix(ROUGHNESS, 0.62 + 0.16 * wear, inside);
		NORMAL = mapped_normal(NORMAL, px, py, dx, dy, map_normal * normal_scale * mix(1.0, 0.62, inside));
		if (inside > 0.5) {
			NORMAL = mapped_normal(NORMAL, px, py, tx, ty, vec2(0.0, ribs * 0.29 * rib_mask));
		}
	}
	vec3 hot_edge = mix(vec3(0.78, 0.055, 0.009), vec3(1.0, 0.24, 0.045), clamp(heat * 1.7, 0.0, 1.0));
	EMISSION = hot_edge * heat * mix(2.1 * lip, 3.7, wall) * mix(0.52, 1.0, wear) * fx_gain;
	if (surface_data.y > 0.5) {
		float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float prism = clamp(rim + part_pos.x * 0.55 + part_pos.z * 0.35, 0.0, 1.0);
		vec3 spectral = mix(vec3(0.32, 0.78, 0.90), vec3(0.78, 0.57, 0.92), prism);
		ALBEDO = mix(ALBEDO, spectral, 0.32 * rim + 0.28 * wall);
		METALLIC = 0.10;
		ROUGHNESS = mix(clamp(ROUGHNESS * 0.55, 0.10, 0.32), 0.23, wall);
		float glint = smoothstep(0.32, 0.86, rim) * (0.28 + 0.39 * lip);
		EMISSION = EMISSION * 0.47 + spectral * (0.045 + glint) * fx_gain;
	}
}
"""


# Bind the original textures for every live finish, using fixed sampler names.
# Explicit gradients keep mip selection correct when neighbouring pieces use different maps.
static func hit_fragment_code(slots: int) -> String:
	var samplers := ""
	var samples := ""
	for i in slots:
		samplers += "uniform sampler2D hull_color_%d : source_color, filter_linear_mipmap_anisotropic, repeat_enable;\n" % i
		samplers += "uniform sampler2D hull_orm_%d : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;\n" % i
		samplers += "uniform sampler2D hull_normal_%d : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;\n" % i
		samples += """
	if (slot == %d) {
		baked = textureGrad(hull_color_%d, paint_uv, dx, dy).rgb;
		orm = textureGrad(hull_orm_%d, paint_uv, dx, dy).rgb;
		map_normal = textureGrad(hull_normal_%d, paint_uv, dx, dy).xy * 2.0 - 1.0;
	}
""" % [i, i, i, i]
	return HIT_FRAGMENT.replace("// FINISH_SAMPLERS", samplers).replace("// FINISH_SAMPLES", samples)


# Shield bubble (one per shielded ship, an ellipsoid round the hull). Up to 6 hits at once, each with a bright core and
# ripple rings out from the impact; a fresnel rim lights near the hit. style: 0 Voidsworn (gold veil, crackling),
# 1 Hegemony (clean hex lattice), 2 Corsair (patchy, flickering), 3 Ithar (smooth prismatic veil).
# Break (brk_t, brk_dir): that facing flares, then tears away.
const SHIELD := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform vec3 col = vec3(1.0);
uniform vec3 rad = vec3(1.0);
uniform bool fitted_shape = false;
uniform int style = 0;
uniform vec4 hits[6];
uniform vec4 hitw[6];
uniform vec2 ion_arc = vec2(-100.0, 0.0); // start time and azimuth in the shield's frame
uniform float brk_t = -100.0;
uniform vec3 brk_dir = vec3(1.0, 0.0, 0.0);
uniform float regen_t = -100.0;
// issue 1078, R340: the failure look is 2, the clean collapse; 0 the old per-faction break and 1 energy shear stay only
// for dev comparisons; brk_low gives the shear its cheaper crack network
uniform int brk_look = 2;
uniform bool brk_low = false;
// issue 1239: the collapse's close time (COLLAPSE_CLOSE, fx_ship.gd) and how long the break plays in all (1.6 s, longer for a slower close)
uniform float brk_close = 1.225;
uniform float brk_win = 1.6;
// the bubble's rim (faction look data, shield_edge): 0 none, 1 a colour, 2 rainbow (reserved for the coming lore looks)
uniform int edge_mode = 0;
uniform vec3 edge_col = vec3(1.0);
// issue 1446 (R246): the sides shield power is routed to (fx_ship.gd _set_route) pulse quickly at the rim
uniform vec4 route_on = vec4(0.0);
uniform vec3 route_dirs[4];
varying vec3 vL;
varying vec3 vW;
varying vec3 vN;
void vertex() {
	// The fitted mesh is in hull units; the egg keeps its original unit-sphere coordinates.
	vL = fitted_shape ? VERTEX / rad : VERTEX;
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vN = fitted_shape ? snorm(MODEL_NORMAL_MATRIX * NORMAL) : snorm((MODEL_MATRIX * vec4(NORMAL / rad, 0.0)).xyz);
}
float hexcell(vec2 q) {
	vec2 h = vec2(q.x * 1.1547, q.y + q.x * 0.57735);
	vec2 f = fract(h) - 0.5;
	return max(abs(f.x), max(abs(f.y), abs(f.x + f.y)));
}
vec3 h33(vec3 p) { p = fract(p * vec3(0.1031, 0.1030, 0.0973)); p += dot(p, p.yxz + 33.33); return fract((p.xxy + p.yxx) * p.zyx); }
// 3D cells on the bubble: x = distance to the nearest cell border, y = the cell's id
vec2 vor3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	float d1 = 8.0;
	float d2 = 8.0;
	float id = 0.0;
	for (int a = -1; a <= 1; a++) {
		for (int b = -1; b <= 1; b++) {
			for (int c = -1; c <= 1; c++) {
				vec3 g = vec3(float(a), float(b), float(c));
				vec3 o = h33(i + g);
				vec3 r = g + o - f;
				float d = dot(r, r);
				if (d < d1) { d2 = d1; d1 = d; id = o.x; } else if (d < d2) { d2 = d; }
			}
		}
	}
	return vec2(sqrt(d2) - sqrt(d1), id);
}
void fragment() {
	vec3 lp = vL * rad;
	float I = 0.0;
	float maxR = length(rad);
	float web = 0.0;
	float strain = 0.0;
	// F3: hits read at distance and on small ships: the hot core, the ripple and its spread never shrink below a few
	// pixels (wpx = world units per pixel here), and every hit lights the whole bubble faintly in the faction's colour
	// and pattern for half a second (more when the camera is far out), so a shield hit reads as that ship's shield
	float wpx = px_world(1.0, -VERTEX.z, PROJECTION_MATRIX);
	float far = smoothstep(0.08, 0.45, wpx);
	for (int i = 0; i < 6; i++) {
		vec4 h = hits[i];
		float age = scene_t - h.w;
		float life = max(hitw[i].y, 1e-3);   // (F3: an empty or zero-life slot never divides by zero)
		if (age < 0.0 || age > life) { continue; }
		float f = age / life;
		float fade = (1.0 - f) * (1.0 - f) * smoothstep(0.0, 0.025, age);
		float d = length(lp - h.xyz);
		float S = hitw[i].x;
		float spread = max(hitw[i].z, wpx * 22.0);
		float mask = 1.0 - smoothstep(spread * 0.35, spread, d);
		float hd = d / max(0.9 + S * 0.4, wpx * 5.0);
		float core = exp(-hd * hd) * 4.0 * (1.0 - f) * mix(1.0, 0.25, fx_calm);
		float rg = 0.0;
		for (int j = 0; j < 3; j++) {
			float aj = age - float(j) * 0.08;
			if (aj > 0.0) {
				// R303: the moving band is evaluated only on this shield surface.
				float rd = (d - aj / life * spread) / max(0.35 + aj * 0.6, wpx * 1.5);
				rg += exp(-rd * rd) * (j == 0 ? 1.7 : 0.8);
			}
		}
		float ga = clamp(age / min(life, 0.55), 0.0, 1.0);
		float glow_all = (1.0 - ga) * (1.0 - ga) * smoothstep(0.0, 0.04, age) * (0.10 + 0.22 * far) * mix(1.0, 0.5, fx_calm);
		float ripple_fade = pow(1.0 - f, 1.3) * smoothstep(0.0, 0.025, age);
		I += (core * fade + rg * mask * (0.6 + 0.4 * S) * ripple_fade + glow_all) * S;
		if (hitw[i].w > 0.5) {
			// Two uneven surges on the edge near this contact. A single soft lift under reduce flashing.
			float beat = 0.3 + 0.7 * pow(0.5 + 0.5 * cos(age * 28.0), 2.0);
			float side = smoothstep(0.45, 0.8, dot(snorm(vL), snorm(h.xyz / rad)));
			strain = max(strain, side * mask * fade * mix(beat, 0.55, fx_calm));
		}
		// shear look: each hit briefly lights the crack network round it, so the hit already shows how this shield fails
		web += mask * (1.0 - f) * (1.0 - f) * S;
	}
	// regen shimmer: a band sweeping the bubble from stern to bow
	float ra = scene_t - regen_t;
	if (ra > 0.0 && ra < 1.0) {
		float band = (vL.x * 0.5 + 0.5) - ra * 1.3 + 0.15;
		I += exp(-band * band * 60.0) * 0.6 * (1.0 - ra);
	}
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	float fres = spow(1.0 - abs(dot(normalize(vN), V)), 4.0);
	I += strain * (0.25 + 2.0 * fres);
	if (dot(route_on, route_on) > 0.0) {
		vec3 un = normalize(vL);
		float side = 0.0;
		for (int q = 0; q < 4; q++) {
			side = max(side, route_on[q] * smoothstep(0.45, 0.85, dot(un, route_dirs[q])));
		}
		float beat = 0.6 + 0.4 * sin(scene_t * mix(5.5, 2.0, fx_calm));
		I += side * (0.25 + 1.6 * fres) * beat;   // issue 1446 pictures: the routed side reads at camera distance, not as an even glow
	}
	float pat = 1.0;
	vec2 hexId = vec2(0.0);
	float hexEdge = 1.0;
	if (style == 0) {
		float cr = spow(1.0 - abs(fbm(lp.xy * 0.6 + lp.zx * 0.4 + scene_t * 0.4) * 2.0 - 1.0), 8.0);
		pat = 0.6 + 1.4 * cr;
	} else if (style == 1) {
		vec2 hp = vec2(atan(lp.z, lp.y) * 0.5 * (rad.y + rad.z), lp.x) / 1.5;
		const vec2 hs = vec2(1.0, 1.7320508);
		vec4 hcc = floor(vec4(hp, hp - vec2(0.5, 1.0)) / hs.xyxy) + 0.5;
		vec4 hh = vec4(hp - hcc.xy * hs, hp - (hcc.zw + 0.5) * hs);
		bool firstCell = dot(hh.xy, hh.xy) < dot(hh.zw, hh.zw);
		vec2 hq = abs(firstCell ? hh.xy : hh.zw);
		float hd = 0.5 - max(dot(hq, hs * 0.5), hq.x);
		hexId = firstCell ? hcc.xy : hcc.zw + 0.5;
		hexEdge = hd;
		pat = 0.45 + 1.7 * smoothstep(0.07, 0.0, hd);
	} else if (style == 2) {
		float fl = mix(step(0.3, vnoise(vec2(scene_t * 28.0, 3.0))), 0.8, fx_calm);
		float pa = smoothstep(0.35, 0.65, fbm(lp.xz * 0.35 + lp.y * 0.2 + scene_t * 0.7));
		pat = mix(0.5, 1.0, fl) * mix(0.35, 1.2, pa);
	} else {
		float sw = 0.6 + 0.4 * sin(lp.x * 0.8 + lp.y * 0.6 + scene_t * 1.4);
		pat = 0.7 + 0.5 * sw;
	}
	vec3 C = col;
	if (style == 3) {
		float hue = fract(dot(vN, vec3(0.3, 0.5, 0.2)) + scene_t * 0.1);
		C = mix(col, clamp(abs(fract(hue + vec3(0.0, 0.333, 0.667)) * 6.0 - 3.0) - 1.0, 0.0, 1.0) * length(col) * 0.6, 0.3);
	}
	if (edge_mode == 1) {
		C = mix(C, edge_col * length(col) * 0.577, smoothstep(0.1, 0.6, fres));
	} else if (edge_mode == 2) {
		float eh = fract(dot(vN, vec3(0.5, 0.3, 0.7)) * 1.5 + fres * 0.8);
		C = mix(C, clamp(abs(fract(eh + vec3(0.0, 0.333, 0.667)) * 6.0 - 3.0) - 1.0, 0.0, 1.0) * length(col) * 0.7, smoothstep(0.15, 0.7, fres));
	}
	float total = I * pat * (0.9 + 1.2 * fres);
	float ba = scene_t - brk_t;
	bool breaking = ba > 0.0 && ba < brk_win;
	// issue 1078, shear: one connected crack network over the whole shield (cell borders join up, so a crack never
	// ends in open field), coarser than any faction's pattern so it reads as a tear, not as the pattern lighting up
	// (r1: the Navy's tear along its own hex lattice looked like today's look). x = distance to the crack, y = plate.
	vec2 net = vec2(1.0, 0.0);
	float hot = 0.0;
	if (brk_look == 1 && (breaking || web > 0.002)) {
		if (brk_low) {
			// the cheaper network: ridge lines of one noise field (one 2D lookup set against 27 cell tests)
			float rn = fbm(lp.xy * 0.32 + lp.zx * 0.24 + vec2(4.1, 2.7));
			net = vec2(abs(rn * 2.0 - 1.0) * 0.22, floor(rn * 7.0) / 7.0);
		} else {
			net = vor3(normalize(vL) * 2.6 + vec3(4.3, 1.7, 8.2));
		}
		float wl = smoothstep(0.05, 0.0, net.x) * min(web, 1.5);
		total += wl * 1.4 * (0.7 + 0.3 * pat);
		hot += wl * 0.4;
	}
	// break (r4 review: three factions tore the same noise holes in a bright, nearly opaque bubble). Each faction now
	// breaks in its own way, spreading from the struck facing over the bubble, and the bubble stays see-through:
	//   0 Voidsworn: the gold veil cracks into sheets; cracks run white-gold ahead of the front, each sheet flares as it
	//     peels loose, then is gone;
	//   1 Hegemony: the hex lattice shatters cell by cell; each cell fills bright for an instant and pops out, its
	//     border glowing as the front nears (the shards fly as particles);
	//   2 Corsair: it sputters out in patches; each patch stutters on and off (slow breathing with reduce flashing) and
	//     dies, dirty red, until nothing is left;
	//   3 Ithar: the veil sheets away from the struck side (left as it was: the Ithar look is changing).
	if (breaking && brk_look != 0) {
		vec3 un = normalize(vL);
		float facing = dot(un, normalize(brk_dir));
		float dist = (1.0 - facing) * 0.5;
		float life = 1.0 - ba / brk_win;
		float calm = mix(1.0, 0.3, fx_calm);
		float add = exp(-ba * 7.0) * exp(-dist * dist * 40.0) * 1.4 * calm;
		float alive = 1.0;
		// the Hullbreakers' field stutters (low contrast and slow, flash rules), whichever look plays
		// (per patch: the shear's plates, or coarse patches for the collapse, so the whole field never strobes)
		float pid = brk_look == 1 ? net.y : h21(floor(un.xy * 2.5) + floor(un.z * 2.5) * 7.0);
		float stut = style == 2 ? mix(mix(0.45, 1.0, step(0.45, h21(vec2(pid * 31.0 + 1.0, floor(scene_t * 4.5))))), 0.8, fx_calm) : 1.0;
		if (brk_look == 1) {
			// the crack front leaves the struck facing and crosses to the far side in 0.55 s (SHEAR_FRONT)
			float ct = ba - (dist * 0.55 + net.y * 0.05);
			float line = smoothstep(0.06, 0.0, net.x);
			// white-hot where the front is running along the cracks, faction colour behind it, then cooling
			float lead = line * exp(-ct * ct * 160.0) * 3.0 * calm;
			float glow = line * step(0.0, ct) * exp(-ct * 2.6) * 1.7;
			// each plate the crack frees flares, then shears away along the front and is gone (staggered per plate)
			float pt = ct - net.y * 0.12;
			alive = pt < 0.0 ? 1.0 : exp(-pt * 8.0);
			vec3 along = cross(un, normalize(brk_dir));
			float sh = pt > 0.0 ? exp(-pt * 4.0) * (0.5 + 0.5 * sin(dot(un, along) * 34.0 + net.y * 20.0 - ba * 16.0)) * 0.6 * calm : 0.0;
			float flare = smoothstep(-0.05, 0.0, pt) * exp(-max(pt, 0.0) * 9.0) * 0.9 * calm;
			add += ((lead + glow) * (0.65 + 0.35 * pat) + (sh + flare) * pat) * stut;
			hot += lead * 0.5;
		} else {
			// collapse: one even flash, then a single clean band closes from the far side into the breach in 1.225 s
			// (COLLAPSE_CLOSE); nothing is left behind it; the field pinches out in a knot at the breach
			// (r1: a strong flash and a wide band at the far side read as a solid white slab at +0.1 s)
			// the Glasswrights' pale prismatic field barely read against their pale hulls (Board, R340 sheets): their band
			// and knot are brighter and a little wider, and keep the prismatic colour instead of burning toward white
			// Under reduce flashing the band softens for every faction and the Glasswrights' extra brightness (band and
			// knot) is dropped (their wider band and knot stay); Artoo on PR 1170: the band is not a sprite flash, so the flash budget never saw it
			float gw = style == 3 ? 1.0 : 0.0;
			float flash = exp(-ba * 12.0) * 0.3 * calm;
			float bp = 1.0 - clamp((ba - 0.08) / max(brk_close - 0.08, 0.05), 0.0, 1.0);
			float bw = 0.03 + 0.025 * bp + 0.02 * gw;
			float bd = (dist - bp) / bw;
			float band = exp(-bd * bd) * 2.4 * (1.0 + gw * (1.0 - fx_calm)) * mix(1.0, 0.6, fx_calm) * smoothstep(0.06, 0.2, ba) * step(0.001, bp);
			alive = smoothstep(bp + bw, bp - bw, dist);
			float kt = ba - brk_close;
			float knot = kt > 0.0 ? exp(-dist * dist * mix(600.0, 300.0, gw)) * exp(-kt * 5.0) * 3.0 * (1.0 + gw * (1.0 - fx_calm)) * calm : 0.0;
			add += (flash * pat * 0.5 + band * (0.55 + 0.45 * pat)) * stut + knot;
			hot += (band * 0.25 + knot * 0.5) * (1.0 - gw);
		}
		// what is left of the field stays faintly visible until the failure reaches it
		add += alive * 0.28 * pat * (0.3 + 0.7 * fres);
		total = total * alive + add * life * (0.55 + 0.45 * fres);
	} else if (breaking) {
		vec3 un = normalize(vL);
		float facing = dot(un, normalize(brk_dir));
		float dist = (1.0 - facing) * 0.5;
		float life = 1.0 - ba / brk_win;
		float calm = mix(1.0, 0.3, fx_calm);
		// a local flare where it gave way (not the whole hemisphere)
		float add = exp(-ba * 7.0) * exp(-dist * dist * 40.0) * 1.6 * calm;
		float alive = 1.0;
		if (style == 0) {
			vec2 vc = vor3(un * 3.2 + vec3(7.1, 3.3, 1.9));
			float ct = ba - (dist * 0.7 + vc.y * 0.2);
			float crack = smoothstep(0.07, 0.0, vc.x) * smoothstep(-0.25, 0.0, ct) * exp(-max(ct, 0.0) * 2.5) * 2.4;
			float sheet = ct < 0.0 ? 0.0 : exp(-ct * 5.0) * 0.9 * calm;
			alive = ct < 0.0 ? 1.0 : exp(-ct * 6.0);
			add += crack * (0.6 + 0.4 * pat) + sheet * pat * 0.6;
		} else if (style == 1) {
			float cid = h21(hexId + vec2(3.7, 1.3));
			float ct = ba - (dist * 0.9 + cid * 0.25);
			float rim = smoothstep(0.08, 0.0, hexEdge) * smoothstep(-0.3, 0.0, ct) * step(ct, 0.0) * 1.6;
			float pop = smoothstep(-0.06, 0.0, ct) * step(ct, 0.0) * 1.8 * calm;
			alive = step(ct, 0.0);
			add += (rim + pop) * alive;
		} else if (style == 2) {
			// irregular patches (r6: axis-aligned blocks read as a checkerboard)
			vec2 pv = vor3(un * 4.5 + vec3(2.3, 5.1, 0.7));
			float pid = pv.y;
			float tdie = dist * 0.7 + pid * 0.45;
			float ct = ba - tdie;
			// the stutter stays low contrast and slow enough that the whole bubble never strobes (flash rules)
			float stut = mix(0.35, 1.0, step(0.45, h21(vec2(pid * 31.0, floor(scene_t * 4.5)))));
			float on = mix(stut, 0.5 + 0.5 * cos(min(ba, tdie) * 3.0), fx_calm);
			alive = ct < 0.0 ? on * smoothstep(0.0, -0.35, ct) + 0.15 : 0.0;
			float seam = smoothstep(0.06, 0.0, pv.x) * step(ct, 0.0) * 0.6;
			add += alive * (0.5 + 0.5 * pat) * 0.45 + seam + smoothstep(-0.05, 0.0, ct) * step(ct, 0.0) * 0.8 * calm;
		} else {
			float zone = smoothstep(-0.1, 0.5, facing);
			float tear = smoothstep(ba * 1.3 - 0.1, ba * 1.3, 1.0 - facing + (fbm(lp.xy * 0.5 + lp.zx * 0.5) - 0.5) * 0.4);
			float edge = exp(-spow((1.0 - facing - ba * 1.3) / 0.08, 2.0)) * 2.5 * life;
			add += zone * (exp(-ba * 6.0) * 1.4 * calm * pat + edge) * tear;
			alive = tear;
		}
		// what is left of the veil stays faintly visible, so the break reads as the bubble coming apart
		if (style != 2) { add += alive * 0.3 * pat * (0.3 + 0.7 * fres); }
		total = total * alive + add * life * (0.55 + 0.45 * fres);
	}
	float ion = 0.0;
	float ia = scene_t - ion_arc.x;
	if (!breaking && ia >= 0.0 && ia < 0.45) {
		// A short jagged filament across this flank, in the same coordinates on the egg and the fitted skin.
		vec3 un = snorm(vL);
		vec2 axis = vec2(cos(ion_arc.y), sin(ion_arc.y));
		float along = dot(un.xz, vec2(-axis.y, axis.x));
		float jag = vnoise(vec2(along * 21.0, ion_arc.x + floor(ia * mix(8.0, 0.0, fx_calm))));
		float line = un.y - (0.48 + along * 0.20 + (jag - 0.5) * 0.20);
		float width = max(fwidth(line), 0.018);
		ion = (1.0 - smoothstep(0.0, width * 1.5, abs(line))) * smoothstep(0.50, 0.76, dot(un.xz, axis));
		ion *= smoothstep(0.0, 0.07, ia) * (1.0 - smoothstep(0.23, 0.45, ia)) * 0.85;
	}
	if (total + ion < 0.002) { discard; }
	// the shear's running crack and the collapse's band burn toward white (zero in today's look)
	C = mix(C, vec3(length(col)) * 0.62, clamp(hot, 0.0, 0.75));
	ALBEDO = clamp((C * total + vec3(0.52, 0.73, 1.0) * ion) * fx_gain, 0.0, 512.0);
}
"""

# Inside hull damage (fx_breach.gd): cavity floors, the backs of the skin and peeled plates, frames and decks, conduits,
# cables and spines, the cut edge. One mesh per ship; each vertex carries its mark: CUSTOM0 (centre, R), CUSTOM1 (outward
# normal, opened at), CUSTOM2 (cavity depth, heat, seed, style). COLOR.r is the part (0 floor, 0.25 skin back, 0.5 frame
# or deck, 0.75 conduit, 0.85 bone, 1 cut edge), COLOR.g a shade. Lit by the scene (the hull shadows it) plus a fire
# point inside that the scene's lights cannot give; deeper is darker. Fires settle to a smoulder; a lance cut glows
# white, then red, then goes black; acid keeps a faint green working glow.
const HOLE := """
shader_type spatial;
render_mode cull_disabled, fog_disabled;
""" + COMMON + """
uniform int wound_kind = 0;
uniform vec3 glow = vec3(1.0, 0.45, 0.12);
uniform int wound_v2 = -1;   // R416 Wounds V2 faction kind (0 Sunward .. 5 Eclipse); -1 off (the old look)
uniform vec3 v2_scorch_col = vec3(0.1);
uniform vec3 v2_rim_metal = vec3(0.6);
uniform vec3 v2_interior_lift = vec3(0.3);
uniform vec3 v2_interior_accent = vec3(1.0, 0.5, 0.15);
uniform float v2_rough = 0.6;
uniform float v2_soot = 1.0;
uniform float v2_wreck_soot = 0.3;
// JOINT_D (Nov 23): straight-edged cells for the Glasswright fracture facets: x the distance to the nearest cell edge
// in cells, y and z the cell's own random values
vec3 gw_cells(vec2 p) {
	vec2 ip = floor(p);
	vec2 fp = fract(p);
	vec2 mb = vec2(0.0);
	vec2 mr = vec2(0.0);
	float md = 8.0;
	for (int j = -1; j <= 1; j++) {
		for (int k = -1; k <= 1; k++) {
			vec2 g = vec2(float(k), float(j));
			vec2 r = g + vec2(h21(ip + g), h21(ip + g + 17.3)) - fp;
			float d = dot(r, r);
			if (d < md) { md = d; mr = r; mb = g; }
		}
	}
	md = 8.0;
	for (int j = -2; j <= 2; j++) {
		for (int k = -2; k <= 2; k++) {
			vec2 g = mb + vec2(float(k), float(j));
			vec2 r = g + vec2(h21(ip + g), h21(ip + g + 17.3)) - fp;
			if (dot(mr - r, mr - r) > 1e-5) { md = min(md, dot(0.5 * (mr + r), normalize(r - mr))); }
		}
	}
	return vec3(md, h21(ip + mb + 3.1), h21(ip + mb + 9.7));
}
varying vec3 vL;
varying vec3 vNl;
varying vec4 vC;
varying vec4 vA;
varying vec4 vB;
varying vec4 vD;
void vertex() {
	if (wound_kind == 1 && int(CUSTOM2.w + 0.5) == 14) {
		float knit = smoothstep(0.0, 3.0, max(scene_t - CUSTOM1.w, 0.0));
		VERTEX += CUSTOM1.xyz * CUSTOM0.w * 0.18 * (1.0 - knit) * (1.0 - COLOR.r);
	}
	vL = VERTEX; vNl = NORMAL; vC = COLOR; vA = CUSTOM0; vB = CUSTOM1; vD = CUSTOM2;
}
void fragment() {
	vec3 centre = vA.xyz;
	float R = max(vA.w, 1e-3);
	vec3 axis = vB.xyz;
	float t0 = vB.w;
	float heat = vD.y;
	float seed = vD.z;
	int style = int(vD.w + 0.5);
	vec3 fire = centre - axis * vD.x * 0.55;
	float part = vC.r;
	float age = max(scene_t - t0, 0.0);
	float hot = heat * mix(0.45, 1.0, exp(-age / 10.0));
	float fl = flick(0.7 + 0.3 * vnoise(vec2(scene_t * 7.0, seed)) * vnoise(vec2(scene_t * 17.0, seed + 3.0)) * 2.0, scene_t, seed);
	vec3 p = vL / R;
	float n1 = fbm(p.xy * 3.1 + p.zx * 2.3 + seed);
	float n2 = fbm(p.yz * 9.0 + p.xy * 5.0 + seed * 2.0);
	float deep = clamp(dot(centre - vL, axis) / R, 0.0, 1.5);
	float ao = mix(1.0, 0.25, smoothstep(0.0, 0.9, deep));
	// r3 verdict: the frames and decks inside were lost in black; a little more albedo lets the fire light pick them out
	vec3 base = vec3(0.012, 0.009, 0.007) * (0.6 + 0.8 * vC.g) * (0.7 + 0.6 * n1);
	float rough = 0.72;
	float metal = 0.25;
	if (part > 0.2 && part < 0.3) { base *= 1.8; metal = 0.6; rough = 0.5; }
	if (part > 0.95) { base = vec3(0.06, 0.057, 0.054) * (0.8 + 0.4 * n2); rough = 0.55; metal = 0.5; ao = 0.8; }
	else if (part > 0.8) { base = vec3(0.025, 0.019, 0.013) * (0.75 + 0.35 * n2); rough = 0.45; metal = 0.0; ao = 1.0; }
	else if (part > 0.6) { base = mix(vec3(0.014, 0.01, 0.007), vec3(0.008, 0.008, 0.009), vC.g) * (0.8 + 0.4 * n2); rough = 0.5; }
	else if (part > 0.4) { base *= 1.2; }
	vec3 toF = fire - vL;
	float dist = length(toF) / R;
	if (part < 0.8) { base *= mix(0.5, 1.0, smoothstep(0.2, 1.4, dist)); }
	vec3 Nl = snorm(vNl) * (FRONT_FACING ? 1.0 : -1.0);
	float lam = 0.25 + 0.75 * max(dot(Nl, toF / max(length(toF), 1e-4)), 0.0);
	float fall = 1.0 / (1.0 + dist * dist * 5.0);
	float emb = smoothstep(0.66, 0.88, fbm(p.xy * 6.0 + p.zx * 4.0 + vec2(seed, scene_t * 0.12))) * (part < 0.3 ? 1.0 : 0.3);
	vec3 gc = glow;
	if (style == 8) { gc = vec3(0.42, 0.46, 0.08); hot *= 0.2; }
	if (style == 4 || style == 11) { hot *= 0.3; }
	vec3 em = gc * (lam * fall * 0.6 * fl * (0.3 + 0.7 * smoothstep(0.1, 0.8, deep)) + emb * 0.8 * (0.6 + 0.4 * fl) * (1.0 - smoothstep(0.3, 1.4, dist))) * hot;
	if (style == 1) {
		// a lance cut: the metal round the burn-through is molten, white, then orange, then dull red, then black
		float cool = exp(-age / 3.0);
		float m = cool * (part > 0.95 ? 1.0 : 0.6) * (1.0 - smoothstep(0.3, 2.5, dist));
		em = heatRamp(m) * m * 4.0;
		base *= 1.0 - 0.5 * cool;
	} else if (style == 5 || style == 6 || style == 0) {
		if (part > 0.95) { em += gc * exp(-age / 0.7) * 0.35 * heat * (0.7 + 0.3 * fl); }
	}
	if (wound_v2 >= 0) {
		// R416: the V2 look below replaces the old faction looks
	} else if (wound_kind == 1) {
		base = mix(vec3(0.018, 0.002, 0.009), vec3(0.07, 0.012, 0.023), n1);
		rough = 0.23; metal = 0.0;
		float muscle = pow(abs(sin(p.x * 22.0 + n1 * 5.0)), 8.0);
		em = glow * (0.07 + 0.04 * sin(scene_t * 2.3 + seed)) * muscle;
		if (part > 0.8 && part < 0.9) { base = vec3(0.17, 0.13, 0.07); }
	} else if (wound_kind == 2) {
		base = part < 0.3 ? vec3(0.005, 0.004, 0.022) : glow * 0.12;
		rough = 0.09; metal = 0.15;
		em = mix(glow, vec3(0.3, 0.65, 1.0), n2) * (part < 0.3 ? emb * 0.06 : 0.16);
	} else if (wound_kind == 3) {
		base = part < 0.3 ? vec3(0.004, 0.002, 0.008) : vec3(0.045, 0.035, 0.06);
		rough = 0.48; metal = 0.7;
		float bus = pow(abs(sin(p.x * 19.0 + floor(p.y * 4.0))), 24.0);
		em = glow * (emb * 0.06 + bus * 0.15) * flick(0.7 + n2 * 0.3, scene_t, seed);
	}
	vec3 em_hdr = vec3(0.0);   // Fable B-review H2: rim heat, bus tips and fresh burns ride above the 0.25 soft cap
	if (wound_v2 >= 0) {
		// R416 5.2: the inside of an open wound in the faction's own matter, lit (never a black portal): the cut edge shows
		// the plate's bare thickness, the mouth dressing its own material (COLOR.b: 0.25 beam or cable, 0.5 tendon,
		// 0.75 crystal shard, 1 power bus), a soft accent glow from deep inside, no fire on glass, flesh or obsidian
		float dress = vC.b;
		bool metalk = wound_v2 <= 2;
		base = v2_interior_lift * (0.35 + 0.5 * n1) * (part < 0.3 ? 0.6 : 1.0) * (0.75 + 0.5 * vC.g);
		rough = v2_rough;
		metal = metalk ? 0.55 : (wound_v2 == 5 ? 0.6 : 0.0);
		if (part > 0.95) { base = v2_rim_metal * (0.75 + 0.35 * n2); rough = metalk ? 0.38 : 0.2; metal = metalk ? 0.85 : 0.1; ao = 1.0; }
		if (dress > 0.2 && dress < 0.3) { base = v2_rim_metal * (0.35 + 0.3 * vC.g); metal = wound_v2 == 5 ? 0.5 : 0.75; rough = 0.45; ao = 0.9; }
		if (part > 0.8 && part < 0.9) {
			// R420: wet crimson-umber tendon; dry weathered ochre-ivory bone (0.14 to 0.18 linear, no glow)
			base = dress > 0.4 ? vec3(0.075, 0.03, 0.022) * (0.8 + 0.4 * n2) : vec3(0.17, 0.15, 0.11) * (0.85 + 0.2 * n2);
			rough = dress > 0.4 ? 0.2 : 0.5; metal = 0.0; ao = 1.0;
		}
		if (dress > 0.7 && dress < 0.8) { base = min(v2_rim_metal * 0.2, vec3(0.18)); rough = 0.05; metal = 0.25; ao = 1.0; }
		float v2hot = metalk ? hot : 0.0;
		em = v2_interior_accent * (lam * fall * 0.45 * (0.6 + 0.4 * fl) * (0.3 + 0.7 * smoothstep(0.1, 0.8, deep)));
		em_hdr += gc * emb * 0.5 * (0.6 + 0.4 * fl) * (1.0 - smoothstep(0.3, 1.4, dist)) * v2hot;
		if (dress > 0.9) { em_hdr += v2_interior_accent * (0.9 + 0.3 * flick(0.7 + n2 * 0.3, scene_t, seed)); base *= 0.5; }
		if (dress > 0.7 && dress < 0.8) { em += v2_interior_accent * 0.22 * (0.6 + 0.4 * vC.g); }
		if (wound_v2 == 3) { em += v2_interior_accent * 0.05 * pow(abs(sin(p.x * 22.0 + n1 * 5.0)), 8.0) * (0.8 + 0.2 * sin(scene_t * 2.3 + seed)); }
		if (wound_v2 == 4 && part < 0.95 && !(dress > 0.7 && dress < 0.8)) {
			// JOINT_C and D (Nov 23; deaths_and_hits.md 1: "straight-edged crystalline fracture facets and popped mosaic
			// panes over braided light cores"): the crater and walls of a Glasswright cut are glass panes, each its own
			// pale tone and tilt with a lit seam between; a few panes are popped (dark, the stored light behind them);
			// the faction's stored light (glow) rises from deep inside. Never a charcoal disc, no soot
			vec3 ax = snorm(axis);
			vec3 t1 = snorm(cross(ax, abs(ax.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
			vec3 t2 = cross(ax, t1);
			vec3 dl = vL - centre;
			// wedge-shaped panes: cells in angle and distance round the cut, so the cracks run out from it like a star
			vec2 pq = vec2(dot(dl, t1), dot(dl, t2));
			vec3 gq = gw_cells(vec2(atan(pq.y, pq.x) * 1.9, length(pq) / R * 2.2) + vec2(seed * 7.0, seed * 3.0));
			float seam = 1.0 - smoothstep(0.0, 0.035, gq.x);
			bool popped = gq.y > 0.8 && part < 0.3;
			// R431 (Nov 23, the I8_37 family): pale pearl panes; coloured glass shows only in the seams, and only near
			// the opening (a spectral hue round the cut), with the deep glow below; never rainbow tiles across the crater
			vec3 pearl = v2_rim_metal * vec3(1.0, 0.97, 0.93);
			base = mix(pearl * 0.16, pearl * 0.36, gq.z) * (popped ? 0.25 : 1.0);
			base = mix(base, pearl * 0.55, seam * 0.4);
			rough = popped ? 0.3 : 0.06; metal = 0.1; ao = mix(ao, 1.0, 0.6);
			float near_cut = 1.0 - smoothstep(1.0, 1.9, length(pq) / R);
			vec3 hue = 0.5 + 0.5 * cos(6.2832 * (atan(pq.y, pq.x) / 6.2832 + gq.y * 0.35 + vec3(0.0, 0.33, 0.67)));
			em += mix(mix(v2_interior_accent, gc, 0.5) * 0.12, hue * 0.25, near_cut) * seam + gc * (popped ? 0.2 : 0.0);
			em_hdr += gc * 0.45 * smoothstep(0.7, 1.3, deep) * (0.85 + 0.15 * fl);
			vec3 tilt = (t1 * (gq.y - 0.5) + t2 * (gq.z - 0.5)) * 0.9;
			NORMAL = snorm(NORMAL + mat3(VIEW_MATRIX) * (mat3(MODEL_MATRIX) * tilt));
		}
		if (style == 1) {
			// a fresh lance burn-through: the ember ramp only on Sunward and Hullbreaker steel; Directorate burns
			// blue-white, the other factions glow in their own accent (audit, PR 1755: no orange on them)
			float cool = exp(-age / 3.0);
			float m = cool * (1.0 - smoothstep(0.3, 2.5, dist));
			vec3 hc = (wound_v2 == 0 || wound_v2 == 2) ? heatRamp(cool) : (wound_v2 == 1 ? mix(vec3(0.35, 0.6, 1.0), vec3(0.9, 0.95, 1.0), cool) : v2_interior_accent);
			em_hdr += hc * m * (metalk ? 2.0 : 0.6);
		}
	} else {
	if (part > 0.95) { em += glow * 0.025; base *= 0.6 + n2 * 0.4; }
	if (part > 0.4 && part < 0.9) { em += glow * 0.07; }
	}
	if (style == 14) {
		base = wound_kind == 1 ? vec3(0.22, 0.19, 0.10) : (wound_kind == 2 ? vec3(0.48, 0.53, 0.62) : vec3(0.13, 0.15, 0.17));
		em = glow * 0.015;
		em_hdr = vec3(0.0);
	}
	ALBEDO = base;
	ROUGHNESS = rough;
	METALLIC = metal;
	AO = ao;
	AO_LIGHT_AFFECT = 1.0;
	SPECULAR = 0.3 * ao;
	if (wound_v2 >= 0) {
		// R420 with V2 on: the soft cavity glow is held to 0.25 by scaling the colour (never per channel, so a violet
		// stays violet); rim heat, bus tips and fresh burns are the HDR band and pass (Fable review H2)
		vec3 soft = max(em, vec3(0.0)) * 0.5 * fx_gain;
		float pk = max(soft.r, max(soft.g, soft.b));
		EMISSION = soft * (pk > 0.25 ? 0.25 / pk : 1.0) + max(em_hdr, vec3(0.0)) * 0.5 * fx_gain;
	} else {
		EMISSION = clamp(em * 0.5 * fx_gain, vec3(0.0), vec3(0.35));
	}
}
"""

# Each mark's surface (fx_breach.gd): a thin skin over the hull round the mark, blended on top. Per style: char and
# soot fans, molten metal along a lance cut cooling white to red to black with temper colours past it, glowing slag
# pockets that set dark and glassy, spall rings and radial cracks round a gauss exit, flak pockmarks and scratches,
# acid etching that bubbles and glows faintly, branching electrical burns that crackle and die (ion), scraped bare
# metal (ram). Same vertex data as HOLE plus CUSTOM3 (slot direction, half length).
const MARK := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, shadows_disabled, fog_disabled;
""" + COMMON + """
float segd(vec2 p, vec2 a, vec2 b) { vec2 pa = p - a; vec2 ba = b - a; float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0); return length(pa - ba * h); }
// An electrical burn (Lichtenberg figure): trunks forking out from the strike point, two levels of branches, jagged.
// q in units of the mark's radius. Returns (distance to the nearest branch scaled by its width, level of that branch).
vec2 ionTree(vec2 q, float seed) {
	float best = 1e9;
	float lev = 0.0;
	for (int i = 0; i < 6; i++) {
		float fi = float(i);
		float a0 = fi * 1.0472 + (h21(vec2(fi, seed)) - 0.5) * 0.8;
		vec2 p0 = vec2(0.0);
		float an = a0;
		for (int j = 0; j < 4; j++) {
			float fj = float(j);
			float len = 0.24 * (1.0 - fj * 0.12);
			an += (h21(vec2(fi * 7.0 + fj, seed + 3.0)) - 0.5) * 0.9;
			vec2 p1 = p0 + vec2(cos(an), sin(an)) * len;
			float w0 = 0.035 * (1.0 - fj * 0.18);
			float d = segd(q, p0, p1) / w0;
			if (d < best) { best = d; lev = 0.0; }
			// a fork off each joint, and a twig off each fork
			float sgn = h21(vec2(fi + fj * 3.0, seed + 9.0)) > 0.5 ? 1.0 : -1.0;
			float ab = an + sgn * (0.6 + 0.5 * h21(vec2(fj, fi + seed)));
			vec2 b1 = p1 + vec2(cos(ab), sin(ab)) * len * 0.75;
			d = segd(q, p1, b1) / (w0 * 0.6);
			if (d < best) { best = d; lev = 1.0; }
			float at = ab - sgn * 0.7;
			vec2 b2 = b1 + vec2(cos(at), sin(at)) * len * 0.45;
			d = segd(q, b1, b2) / (w0 * 0.35);
			if (d < best) { best = d; lev = 2.0; }
			p0 = p1;
		}
	}
	return vec2(best, lev);
}
uniform int wound_kind = 0;
uniform vec3 glow = vec3(1.0, 0.45, 0.12);
uniform vec3 weapon = vec3(1.0, 0.6, 0.3);
uniform int wound_v2 = -1;   // R416 Wounds V2 faction kind (0 Sunward .. 5 Eclipse); -1 off (the old look)
uniform vec3 v2_scorch_col = vec3(0.1);
uniform vec3 v2_rim_metal = vec3(0.6);
uniform vec3 v2_interior_lift = vec3(0.3);
uniform vec3 v2_interior_accent = vec3(1.0, 0.5, 0.15);
uniform float v2_rough = 0.6;
uniform float v2_soot = 1.0;
uniform float v2_wreck_soot = 0.3;
// Straight-edged cells (Voronoi): x the distance to the nearest cell edge in cells, y the cell's own random value.
vec2 v2cells(vec2 p) {
	vec2 g = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0, d2 = 8.0;
	float id = 0.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 o = vec2(float(i), float(j));
			vec2 c = o + vec2(h21(g + o), h21(g + o + 17.3)) - f;
			float d = dot(c, c);
			if (d < d1) { d2 = d1; d1 = d; id = h21(g + o + 5.1); } else if (d < d2) { d2 = d; }
		}
	}
	return vec2(sqrt(d2) - sqrt(d1), id);
}
// Straight radial cracks from the strike point: n of them, each a straight line (no sine waves).
float v2rays(vec2 q, float n, float seed, float w) {
	float best = 1.0;
	for (int i = 0; i < 9; i++) {
		if (float(i) >= n) { break; }
		float an = (float(i) + h21(vec2(float(i), seed)) * 0.7) * 6.2831853 / n;
		vec2 dir = vec2(cos(an), sin(an));
		float along = dot(q, dir);
		float len = 0.7 + 0.9 * h21(vec2(seed, float(i) + 3.0));
		float side = abs(dot(q, vec2(-dir.y, dir.x)));
		float on = step(0.0, along) * (1.0 - smoothstep(len * 0.8, len, along));
		best = min(best, mix(1.0, side / w, on));
	}
	return 1.0 - smoothstep(0.4, 1.0, best);
}
varying vec3 vL;
varying vec4 vA;
varying vec4 vB;
varying vec4 vD;
varying vec4 vE;
varying float vH;
void vertex() { vL = VERTEX; vA = CUSTOM0; vB = CUSTOM1; vD = CUSTOM2; vE = CUSTOM3; vH = CUSTOM2.x; }
void fragment() {
	vec3 centre = vA.xyz;
	float R = max(vA.w, 1e-3);
	vec3 axis = normalize(vB.xyz);
	float age = max(scene_t - vB.w, 0.0);
	float seed = vD.z;
	int style = int(vD.w + 0.5);
	vec3 t1 = normalize(cross(axis, abs(axis.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
	vec3 t2 = cross(axis, t1);
	vec3 d = vL - centre;
	vec2 q = vec2(dot(d, t1), dot(d, t2));
	float r = length(q);
	float u = r / R;
	float ang = atan(q.y, q.x);
	float n1 = fbm(q / R * 1.7 + seed);
	float a = 0.0;
	vec3 alb = vec3(0.02);
	vec3 em = vec3(0.0);
	float rough = 0.85;
	float hd = u;
	if (style == 1) {
		vec2 dd = vec2(dot(vE.xyz, t1), dot(vE.xyz, t2));
		float al = clamp(dot(q, dd), -vE.w, vE.w);
		float s = length(q - dd * al) / R;
		hd = s;
		float streak = fbm(vec2(dot(q, dd) / R * 0.4, s * 2.0) + seed);
		float charr = 1.0 - smoothstep(0.8, 3.2 + 1.6 * n1, s);
		alb = mix(vec3(0.05, 0.045, 0.04), vec3(0.012), smoothstep(3.0, 0.8, s));
		float cool = exp(-age / 3.0);
		float mol = exp(-max(s - 0.9, 0.0) * 2.4);
		em = heatRamp(cool * mol) * mol * cool * 5.0;
		// issue 1587: a dull cherry tail so the cut keeps a faint glow to about 10 s before it goes to cold char
		em += vec3(0.45, 0.05, 0.01) * mol * 0.5 * exp(-age / 6.0) * (1.0 - cool);
		alb += vec3(0.05, 0.035, 0.07) * smoothstep(1.4, 2.4, s) * (1.0 - smoothstep(2.4, 3.8, s)) * (1.0 - cool) * (0.5 + streak);
		a = max(charr * (0.7 + 0.3 * streak), mol * cool);
	} else if (style == 7) {
		vec2 g = q / (R * 0.11);
		vec2 gi = floor(g);
		vec2 gf = fract(g) - 0.5;
		float hh = h21(gi + seed);
		float sz = 0.1 + 0.22 * h21(gi + 11.3);
		float spot = hh > 0.62 ? smoothstep(sz, sz * 0.3, length(gf + (vec2(h21(gi + 3.1), h21(gi + 7.7)) - 0.5) * 0.6) * (0.8 + 0.4 * vnoise(q / R * 30.0))) : 0.0;
		float scratch = smoothstep(0.82, 0.97, fbm(vec2(dot(q, vec2(0.8, 0.6)) / R * 7.0, dot(q, vec2(-0.6, 0.8)) / R * 0.7) + seed));
		float fall = 1.0 - smoothstep(0.6, 1.3, u + (n1 - 0.5) * 0.3);
		a = (max(spot, scratch * 0.7) + 0.3 * n1) * fall;
		alb = mix(vec3(0.03), vec3(0.14, 0.135, 0.13), scratch * 0.6);
		em = vec3(1.0, 0.5, 0.15) * spot * exp(-age / 0.8) * 2.0 * fall;
	} else if (style == 8) {
		// the acid keeps eating for a few seconds (the patch spreads), then visibly stops: the wet edge goes matte inward
		float spread = mix(0.7, 1.0, smoothstep(0.0, 6.0, age));
		float ue = u / spread;
		float etch = fbm(q / R * 4.0 + seed + vec2(0.0, min(age, 6.0) * 0.05));
		float pits = smoothstep(0.58, 0.74, etch);
		float bub = smoothstep(0.72, 0.9, vnoise(q / R * 14.0 + vec2(scene_t * 0.7, -scene_t * 0.5) + seed)) * exp(-age / 8.0);
		float fall = 1.0 - smoothstep(0.55, 1.3, ue + (n1 - 0.5) * 0.4);
		float wet = exp(-age / 9.0);
		// issue 1877 (Ryan, Nov 24: the flat lime slab "looks a bit cheesy"): an etched burn, not a glowing patch. Dark
		// eaten pits in a crazed, ochre-brown corroded skin; only the wet rims of fresh pits keep a faint bile glow, and
		// that is gone in a few seconds
		float craze = 1.0 - smoothstep(0.0, 0.06, abs(fbm(q / R * 9.0 + seed * 1.3) - 0.5));
		float rimp = smoothstep(0.5, 0.6, etch) * (1.0 - pits);
		a = fall * (0.55 + 0.45 * max(pits, craze * 0.8));
		alb = mix(vec3(0.034, 0.027, 0.012), vec3(0.004, 0.0035, 0.002), max(pits, craze * 0.7));
		rough = mix(0.85, 0.35, wet * smoothstep(1.0, 0.4, ue) * pits);
		em = vec3(0.42, 0.46, 0.08) * (rimp * 0.35 + bub * 0.3) * fall * exp(-age / 2.5);
	} else if (style == 9) {
		// ion: a branching electrical burn; fresh, arcs crawl it blue-white, then it sets as a dark etched fern
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		// safe mode: a cheaper burn (radial jagged streaks) instead of the full branching tree
		float spoke = 1.0 - abs(fbm(vec2(ang * 3.0 + seed, u * 2.0)) * 2.0 - 1.0);
		vec2 tr = vec2(mix(4.0, 0.0, smoothstep(0.8, 0.97, spoke)), 0.0);
#else
		vec2 tr = ionTree(q / R, seed);
#endif
		float line = 1.0 - smoothstep(0.6, 1.6, tr.x);
		float halo = (1.0 - smoothstep(1.0, 5.0, tr.x)) * 0.35;
		float core = 1.0 - smoothstep(0.0, 0.12, u);
		float fall = 1.0 - smoothstep(0.85, 1.05, u);
		a = (max(line, core * 0.85) + halo) * fall;
		alb = mix(vec3(0.03, 0.032, 0.04), vec3(0.008, 0.009, 0.012), line);
		rough = mix(0.85, 0.35, line);
		float live = exp(-age / 2.5);
		float crawl = step(0.5, vnoise(vec2(scene_t * 14.0 + tr.y * 3.0, dot(q, vec2(3.1, 1.7)) / R * 2.0)));
		em = vec3(0.5, 0.75, 1.0) * (line * (0.5 + 1.5 * mix(crawl, 0.5, fx_calm)) + core * 0.8) * live * 2.2 * fall;
		em += vec3(0.25, 0.4, 0.9) * line * 0.06 * exp(-age / 30.0);
	} else if (style == 10) {
		float sc = smoothstep(0.72, 0.95, fbm(vec2(q.x / R * 0.5, q.y / R * 9.0) + seed));
		a = sc * (1.0 - smoothstep(0.6, 1.1, u)) * 0.85 + 0.2 * (1.0 - smoothstep(0.3, 1.0, u));
		alb = mix(vec3(0.03), vec3(0.2, 0.19, 0.18), sc * 0.6);
		rough = 0.5;
	} else if (style == 13) {
		// stage scorch: soot fanning out in streaks over the plating, a darker burnt core, embers that cool to black
		float fan = fbm(vec2(ang * 2.5 + seed, u * 1.2 + seed));
		float reach = 0.55 + 0.45 * fan;
		a = (1.0 - smoothstep(reach * 0.6, reach, u)) * (0.75 + 0.25 * n1);
		alb = mix(vec3(0.05, 0.045, 0.04), vec3(0.008, 0.007, 0.006), smoothstep(reach, 0.15, u));
		rough = 0.92;
		float emb = smoothstep(0.7, 0.9, fbm(q / R * 6.0 + seed * 2.0)) * (1.0 - smoothstep(0.1, 0.5, u));
		em = vec3(1.0, 0.35, 0.06) * emb * vD.y * mix(0.25, 1.0, exp(-age / 6.0)) * 3.0;
	} else if (style == 16) {
		// R416 (1692 d) prism: a crystal star fracture, straight cracks and facet cells catching a spectral glint, no soot
		float cr = v2rays(q / R, 8.0, seed, 0.035);
		vec2 vc = v2cells(q / R * 3.2 + seed);
		float cell = (1.0 - smoothstep(0.0, 0.06, vc.x)) * (1.0 - smoothstep(0.5, 1.1, u));
		float fall = 1.0 - smoothstep(0.9, 1.6, u);
		a = max(cr * fall, cell * 0.7);
		alb = mix(vec3(0.22, 0.25, 0.3), vec3(0.75, 0.82, 0.9), max(cr, cell));
		rough = 0.1;
		vec3 spec = 0.5 + 0.5 * cos(6.2831853 * (vec3(0.0, 0.33, 0.67) + ang / 6.2831853 + vc.y));
		em = (vec3(0.85, 0.92, 1.0) * cr * 1.2 + spec * cell * 0.5) * mix(0.12, 1.0, exp(-age / 2.0)) * fall;
	} else if (style == 17) {
		// R416 (1692 d) star: a white-gold heat bloom that cools to bleached, glazed alloy (never a black soot ring)
		float cool = exp(-age / 2.5);
		float bloom = 1.0 - smoothstep(0.2, 1.3 + 0.3 * n1, u);
		a = bloom * (0.6 + 0.4 * n1);
		alb = mix(vec3(0.34, 0.31, 0.27), vec3(0.62, 0.58, 0.5), smoothstep(0.9, 0.2, u));
		rough = mix(0.6, 0.2, bloom);
		em = mix(vec3(1.0, 0.62, 0.25), vec3(1.0, 0.95, 0.82), cool) * bloom * (cool * 3.0 + 0.04);
	} else if (style == 18) {
		// R416 (1692 d) null lance: a narrow cold violet-black trench with a violet-white rim that fades
		vec2 dd = vec2(dot(vE.xyz, t1), dot(vE.xyz, t2));
		float al = clamp(dot(q, dd), -vE.w, vE.w);
		float s = length(q - dd * al) / R;
		hd = s;
		a = 1.0 - smoothstep(0.8, 1.6, s);
		alb = vec3(0.012, 0.008, 0.02);
		rough = 0.4;
		float sd = (s - 1.0) / 0.22;   // issue 2092: d * d, never pow of a possibly negative base
		em = vec3(0.62, 0.5, 1.0) * exp(-(sd * sd)) * (0.15 + 1.2 * exp(-age / 3.0));
	} else if (style == 12) {
		a = 0.4 * (1.0 - smoothstep(0.3, 1.0, u + (n1 - 0.5) * 0.4));
	} else {
		// craters, holes and breaches: char fanning out in streaks, slag, spall and cracks by style
		float fan = fbm(vec2(ang * 3.0 + seed, u * 0.8));
		float reach = (style == 3 ? 2.4 : (style == 4 ? 1.5 : 2.0)) * (0.7 + 0.6 * fan);
		float charr = 1.0 - smoothstep(0.6, reach, u);
		a = charr * 0.9;
		alb = mix(vec3(0.045, 0.04, 0.036), vec3(0.01), smoothstep(reach, 0.5, u));
		if (style == 2 || style == 3) {
			float cool = exp(-age / (style == 3 ? 4.5 : 1.6));
			float slag = smoothstep(0.55, 0.78, fbm(q / R * 3.0 + seed * 3.0)) * (1.0 - smoothstep(0.7, 1.35, u));
			// plasma burns light blue (Ryan, Oct 26): blue-white when fresh, deep blue as it sets, then dark glass
			vec3 pr = mix(vec3(0.08, 0.2, 0.55), vec3(0.45, 0.78, 1.0), smoothstep(0.0, 0.5, cool));
			pr = mix(pr, vec3(0.88, 0.96, 1.0), smoothstep(0.6, 1.0, cool));
			vec3 hc = style == 3 ? pr : heatRamp(cool * 0.8);
			slag *= 1.0 - smoothstep(0.3, 1.0, u);
			em = hc * slag * cool * (style == 3 ? 1.8 : 1.1);
			a = max(a, slag);
			rough = mix(rough, 0.25, slag);
			// slag runs: drips trailing down the plate from the crater
			float run = smoothstep(0.86, 1.0, 1.0 - abs(sin(q.x / R * 6.0 + seed * 4.0))) * smoothstep(0.6, 1.0, u) * (1.0 - smoothstep(1.0, 2.2, u)) * step(q.y, 0.0);
			a = max(a, run * 0.8);
			em += hc * run * cool * 1.5;
			if (style == 3) {
				// the splash's signature: a fan of droplet spots thrown out along the shot, dark first, freckling the skirt
				vec2 fd = normalize(vec2(dot(vE.xyz, t1), dot(vE.xyz, t2)) + vec2(1e-4, 0.0));
				float along = dot(q, fd) / R;
				float side = abs(dot(q, vec2(-fd.y, fd.x))) / R;
				float cone = smoothstep(0.75, 0.2, side / max(along, 0.05)) * smoothstep(0.8, 1.2, along) * (1.0 - smoothstep(2.4, 3.3, along));
				vec2 g = q / (R * 0.16);
				vec2 gi = floor(g);
				vec2 gf = fract(g) - 0.5;
				float dsz = 0.08 + 0.2 * h21(gi + seed + 2.0);
				float drop = h21(gi + seed) > 0.45 ? smoothstep(dsz, dsz * 0.4, length(gf + (vec2(h21(gi + 5.3), h21(gi + 9.1)) - 0.5) * 0.5)) : 0.0;
				drop *= cone;
				a = max(a, drop * 0.95);
				em += pr * drop * exp(-age / 1.5) * 2.0;
				rough = mix(rough, 0.2, drop);
			}
		}
		if (style == 4) {
			// a gauss entry: a pale stress ring with short radial cracks round a clean small hole (reads at fleet distance)
			// broken and uneven (spalled paint and stressed metal, never a clean drawn circle)
			float wob = fbm(vec2(ang * 2.0 + seed, seed * 3.0));
			float ring = smoothstep(1.15, 1.5, u + (wob - 0.5) * 0.5) * (1.0 - smoothstep(1.7, 2.6, u + (n1 - 0.5) * 0.9));
			ring *= smoothstep(0.3, 0.6, fbm(vec2(ang * 4.0, u * 2.0) + seed * 5.0));
			float crack = smoothstep(0.93, 1.0, 1.0 - abs(sin(ang * 7.0 + n1 * 4.0 + seed))) * smoothstep(1.0, 1.3, u) * (1.0 - smoothstep(1.4, 3.2, u + (wob - 0.5)));
			float pale = max(ring * 0.6, crack * 0.9);
			a = max(charr * 0.5, pale);
			alb = mix(alb, vec3(0.42, 0.43, 0.45), pale);
			rough = mix(rough, 0.3, pale);
			em = vec3(0.85, 0.92, 1.0) * pale * exp(-age / 0.6) * 1.5;
		}
		if (style == 5) {
			float crack = smoothstep(0.92, 1.0, 1.0 - abs(sin(ang * 7.0 + n1 * 3.0))) * (1.0 - smoothstep(0.8, 2.4, u));
			a = max(a, crack);
		}
	}
	// The halo (r4 review): every mark carries a wide, broken field in its own signature so it reads from the battle
	// camera, 170 units away, where the mark's own detail is a few pixels: soot round shells, torpedo holes and lance
	// cuts; dark blue glass freckles round plasma; a grey rash round flak; green-black etch round acid; a blue-black
	// scorched fern field round ion burns; bright scraped metal round a ram; a pale spalled field round a gauss exit.
	float H = vH;
	float hs = 0.0;   // the halo's share of this pixel (soot is matte: no metal, little specular; r13)
	if (H > 0.05) {
		float hb = fbm(q / R * (0.55 / max(H * 0.25, 0.5)) + seed * 1.7);
		float hn = fbm(q / R * (2.2 / max(H * 0.25, 0.5)) + seed * 3.1);
		float hu = hd / H + (hb - 0.5) * 0.35;
		float ha = (1.0 - smoothstep(0.25, 1.0, hu)) * (0.55 + 0.45 * hn);
		vec2 hq = q / (R * H);   // the plane in halo units (1 at the halo's edge)
		vec3 hc = vec3(0.016, 0.014, 0.013);
		float hr = 0.95;
		vec3 hem = vec3(0.0);
		float live = exp(-age / 4.0);
		if (style == 3) {
			// plasma: a glaze of dark blue glass with brighter slag freckles and a faint cold sheen that lasts
			float fr = smoothstep(0.5, 0.72, hn);
			hc = mix(vec3(0.012, 0.025, 0.055), vec3(0.05, 0.13, 0.26), fr);
			hr = mix(0.3, 0.12, fr);
			hem = vec3(0.3, 0.6, 1.0) * (0.03 + fr * (0.1 + 0.6 * live)) * (1.0 - smoothstep(0.2, 0.85, hu));
		} else if (style == 7) {
			// flak: salt and pepper, dark pits and bright chipped-metal specks, so the rash reads on light and dark hulls
			// alike (r6: a mid-grey rash vanished on the grey Voidsworn deck)
			// r8: round pocks of mixed sizes scattered off a jittered grid (r7 drew the grid cells themselves: square
			// pixels, a digital-camouflage look)
			vec2 fg = q / R * 5.5;
			vec2 fi = floor(fg);
			vec2 ff = fract(fg) - 0.5;
			float cellv = h21(fi + seed);
			vec2 jo = (vec2(h21(fi + seed + 3.7), h21(fi + seed + 8.1)) - 0.5) * 0.45;
			float rr = length(ff - jo) * (0.85 + 0.3 * vnoise(q / R * 40.0 + seed));
			float pr = 0.07 + 0.3 * pow(h21(fi + seed + 5.9), 2.0);
			float spot = smoothstep(pr, pr * 0.5, rr);
			// r12 (Opus): the pocks gather into one darker peppered patch (denser pits on a sooty ground), so the patch
			// reads as a whole from the battle camera instead of as isolated specks; a faint warm rim edges it (below)
			float pit = step(0.22, cellv) * step(cellv, 0.88) * spot;
			float chip = step(0.88, cellv) * spot;
			hc = vec3(0.03, 0.029, 0.028);
			hc = mix(hc, vec3(0.008), pit);
			hc = mix(hc, vec3(0.42, 0.41, 0.4), chip);
			ha = min(1.0, ha * 1.8) * mix(0.72, 1.0, max(pit, chip));
			hr = mix(0.95, 0.35, chip);
			// r18 (Muse audit B4.3): the signature at the battle camera is a dotted patch: coarse black pocks a fifth of
			// the halo across (a few pixels each at 170 units), a few still glowing, over the fine pepper
			vec2 cg = hq * 5.0;
			vec2 ci = floor(cg);
			vec2 cf = fract(cg) - 0.5;
			float cv = h21(ci + seed + 17.0);
			vec2 cj = (vec2(h21(ci + seed + 2.3), h21(ci + seed + 6.1)) - 0.5) * 0.4;
			float cdot = smoothstep(0.3, 0.16, length(cf - cj)) * step(0.3, cv) * (1.0 - smoothstep(0.55, 0.85, length(hq)));
			hc = mix(hc, vec3(0.005), cdot);
			ha = max(ha, cdot);
			hem += vec3(1.0, 0.42, 0.1) * cdot * step(0.78, cv) * (0.3 * exp(-age / 300.0) + 0.9 * live);
		} else if (style == 8) {
			float pit = smoothstep(0.58, 0.72, hn);
			hc = mix(vec3(0.026, 0.021, 0.01), vec3(0.005, 0.004, 0.002), pit);
			hr = mix(0.9, 0.4, exp(-age / 9.0) * pit);
			hem = vec3(0.42, 0.46, 0.08) * pit * 0.12 * exp(-age / 2.5);
			// r18 (Muse audit B4.3): the signature is a green stain with drips running off it, down the hull side (or
			// aft along a deck), long enough to read as streaks from the battle camera
			vec3 dn = vec3(0.0, -1.0, 0.0);
			vec2 gd = vec2(dot(dn, t1), dot(dn, t2));
			if (length(gd) < 0.3) { gd = vec2(dot(vec3(-1.0, 0.0, 0.0), t1), dot(vec3(-1.0, 0.0, 0.0), t2)); }
			gd = normalize(gd + vec2(1e-4, 0.0));
			float along = dot(hq, gd);
			float acr = dot(hq, vec2(-gd.y, gd.x));
			float lane = vnoise(vec2(acr * 8.0 + seed * 3.0, seed));
			float drip = smoothstep(0.55, 0.75, lane) * smoothstep(-0.05, 0.1, along) * (1.0 - smoothstep(0.35 + 0.6 * lane, 1.1, along)) * (1.0 - smoothstep(0.3, 0.55, abs(acr)));
			float stain = 1.0 - smoothstep(0.12, 0.42, length(hq) + (hn - 0.5) * 0.25);
			float ac2 = max(drip, stain);
			// issue 1877: the stain and drips are dark corroded runs, not a lasting lime glow
			hc = mix(hc, vec3(0.012, 0.009, 0.004), ac2 * 0.85);
			ha = max(ha, max(drip * 0.9, stain));
			hem += vec3(0.42, 0.46, 0.08) * drip * 0.15 * exp(-age / 2.5);
		} else if (style == 9) {
			hc = vec3(0.012, 0.015, 0.03);
			hem = vec3(0.3, 0.5, 1.0) * smoothstep(0.62, 0.8, hn) * (0.03 + 0.5 * live);
			// r18 (Muse audit B4.3): the signature is a starburst, seven jagged spokes out to the halo's edge, dark with a
			// cold blue glow along them, a shape no other weapon leaves
			float ang2 = atan(hq.y, hq.x);
			float rr2 = length(hq);
			float sector = floor((ang2 + PI) / TAU * 7.0);
			float acen = (sector + 0.5) / 7.0 * TAU - PI + (h21(vec2(sector, seed)) - 0.5) * 0.5;
			float jag = (vnoise(vec2(rr2 * 10.0, sector * 3.1 + seed)) - 0.5) * 0.3;
			float dang = abs(mod(ang2 - acen - jag + PI, TAU) - PI) * max(rr2, 0.05);
			float spoke = (1.0 - smoothstep(0.035, 0.07, dang)) * smoothstep(0.06, 0.14, rr2) * (1.0 - smoothstep(0.55 + 0.4 * h21(vec2(sector, seed + 3.0)), 1.0, rr2));
			hc = mix(hc, vec3(0.004, 0.006, 0.02), spoke);
			ha = max(ha, spoke);
			hem += vec3(0.4, 0.62, 1.0) * spoke * (0.35 * exp(-age / 300.0) + 1.0 * live);
		} else if (style == 10) {
			// a ram scrapes the paint off: bright streaked bare metal, no soot. r18 (Muse audit B4.3): long bright
			// gouges along the ship's length, wide and pale enough to read from the battle camera, still hot at first
			vec2 sdv = vec2(dot(vec3(1.0, 0.0, 0.0), t1), dot(vec3(1.0, 0.0, 0.0), t2));
			if (length(sdv) < 0.3) { sdv = vec2(1.0, 0.0); }
			sdv = normalize(sdv);
			float al = dot(hq, sdv);
			float ac = dot(hq, vec2(-sdv.y, sdv.x));
			float st = smoothstep(0.5, 0.78, fbm(vec2(al * 1.2, ac * 8.0) + seed)) * (1.0 - smoothstep(0.45, 0.85, abs(ac)));
			hc = mix(vec3(0.05), vec3(0.62, 0.6, 0.57), st);
			hr = mix(0.7, 0.25, st);
			ha = max(ha * 0.6, st);
			hem += vec3(1.0, 0.55, 0.25) * st * 0.6 * live;
		} else if (style == 5) {
			hc = mix(vec3(0.03), vec3(0.3, 0.3, 0.31), smoothstep(0.55, 0.8, hn));
			hr = 0.5;
		} else if (style == 1) {
			// lance: soot along the cut, with temper colours (straw, purple, blue) banding the metal near it
			float tb = clamp(hd / max(H * 0.45, 1.0), 0.0, 1.0);
			vec3 temper = mix(vec3(0.16, 0.12, 0.05), vec3(0.09, 0.05, 0.12), smoothstep(0.2, 0.55, tb));
			temper = mix(temper, vec3(0.04, 0.06, 0.14), smoothstep(0.55, 0.9, tb));
			hc = mix(temper, vec3(0.014), smoothstep(0.75, 1.0, tb) * 0.7);
			hr = 0.45;
		}
		if (style == 16) { hc = vec3(0.3, 0.34, 0.4); hr = 0.15; }
		else if (style == 17) { hc = vec3(0.3, 0.27, 0.22); hr = 0.4; }
		else if (style == 18) { hc = vec3(0.02, 0.012, 0.035); hr = 0.4; hem += vec3(0.5, 0.4, 0.9) * smoothstep(0.62, 0.8, hn) * 0.05; }
		// r8 (Opus): every mark carries a short-lived glowing scorch, broken by the halo noise, in the weapon's own
		// heat colour, so a fresh hit reads from the battle camera even on a frigate. It comes up softly over a quarter
		// second and cools over several (no flash: it never jumps, so the flash budget is untouched). The soot under
		// it is darker and denser than before as well.
		vec3 sc = vec3(1.0, 0.4, 0.1);
		float scl = 6.0;
		float sk = 1.0;
		if (style == 1) { sc = vec3(1.0, 0.48, 0.14); scl = 5.0; }
		else if (style == 3) { sc = vec3(0.35, 0.65, 1.0); scl = 6.0; }
		else if (style == 8) { sc = vec3(0.42, 0.46, 0.08); scl = 2.5; sk = 0.45; }
		else if (style == 9) { sc = vec3(0.45, 0.65, 1.0); scl = 6.0; sk = 1.3; }
		else if (style == 7) { sk = 1.0; scl = 6.0; }
		else if (style == 6 || style == 11) { scl = 9.0; sk = 1.2; }
		else if (style == 10) { sc = vec3(1.0, 0.55, 0.25); scl = 5.0; sk = 1.1; }
		else if (style == 12 || style == 13) { sk = 0.0; }
		else if (style == 16) { sc = vec3(0.8, 0.9, 1.0); scl = 3.0; }
		else if (style == 17) { sc = vec3(1.0, 0.85, 0.5); scl = 5.0; }
		else if (style == 18) { sc = vec3(0.6, 0.45, 1.0); scl = 4.0; }
		// ... and a dim glow that lingers for most of a minute, so a hit ship still shows its hits from the battle camera
		// r16: the scorch is brief and tight (r9-r15 kept a wide orange wash for most of a minute that flattened whole
		// panels of a frigate in close-up); what lasts is the darker matte char and the thin edge ring below
		float sglow = smoothstep(0.0, 0.25, age) * exp(-age / scl) * sk;
		float sband = (1.0 - smoothstep(0.1, 0.42, hu)) * (0.35 + 0.65 * smoothstep(0.42, 0.68, hn));
		hem += sc * sband * sglow * 2.0;
		if (style != 10 && style != 7 && style != 16 && style != 17) { hc *= 0.7; ha = min(1.0, ha * 1.25); }
		// r12 (Opus): plasma, shell and gauss scars stay stronger once cooled: darker, denser char
		if (style == 2 || style == 3 || style == 4 || style == 5) { hc *= 0.6; ha = min(1.0, ha * 1.3); }
		if (style == 6 || style == 11 || style == 5) {
			// torn holes keep a dull ember ring for a long while, so a hit ship still shows where it was holed
			hem += vec3(1.0, 0.32, 0.06) * smoothstep(0.62, 0.8, hn) * (1.0 - smoothstep(0.15, 0.5, hu)) * (0.08 + 0.5 * live) * exp(-age / 40.0);
		}
		float at = a + ha * (1.0 - a);
		hs = style == 10 ? 0.0 : ha * (1.0 - a) / max(at, 1e-4);
		alb = (alb * a + hc * ha * (1.0 - a)) / max(at, 1e-4);
		rough = mix(hr, rough, a / max(at, 1e-4));
		em += hem * ha * (1.0 - a);
		a = at;
		// r12 (Opus): a dim broken edge that lasts the battle (about five minutes to half), so a cooled plasma, shell,
		// gauss or flak scar still shows from the battle camera: round the char for the craters and holes, round the
		// outside of the peppered patch for flak. It comes up with the scorch, never jumps (no flash).
		float le = 0.0;
		vec2 eb = vec2(0.25, 0.45);
		if (style == 2) { le = 0.32; }
		else if (style == 3) { le = 0.36; }
		else if (style == 4 || style == 5) { le = 0.3; }
		else if (style == 7) { le = 0.5; eb = vec2(0.55, 0.8); }
		// r17: and a small smouldering core that lasts the battle, tight round the mark's centre, so a frigate still
		// carries its hits from the battle camera without the wide wash of r9-r15
		float lc = (style == 2 || style == 3 || style == 4 || style == 5 || style == 7) ? 0.7 : (style == 9 ? 0.4 : 0.0);
		if (lc > 0.0) {
			float core = (1.0 - smoothstep(0.04, 0.22, hu)) * (0.5 + 0.5 * smoothstep(0.35, 0.65, hn));
			em += sc * core * lc * smoothstep(0.0, 0.25, age) * exp(-age / 300.0);
		}
		if (le > 0.0) {
			float ew = (eb.y - eb.x) * 0.3;
			float edge = smoothstep(eb.x, eb.x + ew, hu) * (1.0 - smoothstep(eb.y - ew, eb.y, hu));
			edge *= 0.35 + 0.65 * smoothstep(0.42, 0.66, hn);
			em += sc * edge * le * 0.6 * ha * smoothstep(0.0, 0.25, age) * exp(-age / 420.0);
		}
	}
	if (style == 15) {
		vec2 dd = vec2(dot(vE.xyz, t1), dot(vE.xyz, t2));
		float along = clamp(dot(q, dd), -vE.w, vE.w);
		float trench = length(q - dd * along) / R;
		alb = vec3(0.008, 0.006, 0.009);
		a = 1.0 - smoothstep(0.7, 1.5, trench);
		float td = (trench - 0.9) / 0.2;
		em = glow * 0.06 * exp(-(td * td));
	}
	if (a < 0.003 && dot(em, vec3(1.0)) < 0.003) { discard; }
	if (wound_v2 >= 0) {
		// R416: the V2 look below replaces the old faction looks
	} else if (wound_kind == 1) {
		float vein = pow(abs(sin(q.x / R * 28.0 + n1 * 6.0)), 12.0);
		alb = mix(vec3(0.06, 0.012, 0.07), vec3(0.12, 0.025, 0.045), n1);
		rough = style == 13 ? 0.55 : 0.2;
		em = glow * (0.025 + 0.06 * vein) * (0.8 + 0.2 * sin(scene_t * 2.3 + seed)) * a;
	} else if (wound_kind == 2) {
		float fracture = pow(abs(sin(ang * 7.0 + n1 * 2.0)), 32.0);
		float web = pow(abs(sin(u * 26.0 + ang * 3.0)), 24.0);
		alb = mix(vec3(0.28, 0.36, 0.48), glow * 0.8, max(fracture, web));
		rough = 0.14;
		a *= 0.18 + 0.82 * max(fracture, web);
		em = glow * max(fracture, web) * a * 0.3;
	} else if (wound_kind == 3) {
		vec2 grid = abs(fract(q / R * 3.0 + seed) - 0.5);
		float circuit = smoothstep(0.46, 0.49, max(grid.x, grid.y));
		alb = vec3(0.012, 0.006, 0.02) * (0.6 + n1 * 0.4);
		rough = 0.48;
		a = max(a, (1.0 - smoothstep(0.7, 1.05, max(abs(q.x), abs(q.y)) / R)) * 0.9);
		em = glow * circuit * 0.22 * flick(0.7 + n1 * 0.3, scene_t, seed);
		if (vD.y > 0.3) {
			float jagged = u - 0.72 + 0.07 * sin(ang * 13.0 + seed);
			float ja = jagged / 0.018;
			float arc = exp(-(ja * ja)) * smoothstep(0.1, 0.4, sin(ang * 6.0 + scene_t * 1.6 + seed));
			em += mix(glow, vec3(0.9, 0.85, 1.0), 0.4) * arc * 0.65 * flick(0.6 + 0.4 * n1, scene_t, seed);
		}
	}
	if (wound_v2 >= 0 && style != 16 && style != 17 && style != 18) {
		// R416 3 and 5: each faction's marks in its own matter. Sunward keeps the dark soot and ember. Directorate: cool
		// steel scorch, a pale-blue electrical burn, no orange. Hullbreakers: heavy soot, rust grime, red-amber slag.
		// Chorus: cracked chitin flakes over umber and maroon-brown hide, no soot, no magenta. Glasswrights: straight
		// fracture planes that catch the light, no soot, no black, no sine webs. Eclipse: a stepped obsidian chip with a
		// thin cold violet-white seam, no grid, no green, no soot wash.
		float lum = dot(em, vec3(0.3, 0.5, 0.2));
		if (wound_v2 == 1) {
			em = vec3(lum) * vec3(0.55, 0.78, 1.0);
			alb = mix(alb, v2_scorch_col, 0.5 * hs);
		} else if (wound_v2 == 2) {
			alb = mix(alb * vec3(1.2, 0.88, 0.72), v2_scorch_col, 0.4 * hs);
			em = vec3(lum) * vec3(1.0, 0.32, 0.08);
			a = min(1.0, a * 1.15);
		} else if (wound_v2 == 3) {
			vec2 vc = v2cells(q / R * 2.6 + seed);
			float crack = 1.0 - smoothstep(0.0, 0.07, vc.x);
			float flake = step(0.62, vc.y) * (1.0 - smoothstep(0.4, 1.0, u));
			alb = mix(vec3(0.20, 0.13, 0.07), vec3(0.17, 0.065, 0.04), n1);
			alb = mix(alb, vec3(0.62, 0.55, 0.38), max(crack * 0.85, flake * 0.6));
			a *= 0.3 + 0.7 * max(crack, flake);
			rough = 0.3;
			em = v2_interior_accent * crack * 0.05 * (0.8 + 0.2 * sin(scene_t * 2.3 + seed)) * a;
			hs = 0.0;
		} else if (wound_v2 == 4) {
			float cr = v2rays(q / R, 7.0 + floor(h21(vec2(seed, 2.0)) * 3.0), seed, 0.03);
			vec2 vc = v2cells(q / R * 3.0 + seed);
			float plane = (1.0 - smoothstep(0.0, 0.05, vc.x)) * (1.0 - smoothstep(0.6, 1.2, u));
			float gone = step(0.8, vc.y) * (1.0 - smoothstep(0.2, 0.7, u));
			float m = max(max(cr, plane), gone * 0.8);
			alb = mix(v2_rim_metal * 0.55, vec3(0.9, 0.94, 1.0), max(cr, plane));
			a *= 0.12 + 0.88 * m;
			rough = 0.06;
			vec3 spec = 0.5 + 0.5 * cos(6.2831853 * (vec3(0.0, 0.33, 0.67) + vc.y));
			em = (v2_interior_accent * (cr * 0.35 + gone * 0.25) + spec * plane * 0.06) * a;
			hs = 0.0;
		} else if (wound_v2 == 5) {
			float st = max(abs(q.x), abs(q.y)) / R;
			float step3 = floor(st * 3.0 + n1 * 0.4);
			float seam = 1.0 - smoothstep(0.0, 0.06, abs(fract(st * 3.0 + n1 * 0.4) - 0.5) * 2.0 - 0.88);
			alb = mix(vec3(0.05, 0.04, 0.07), vec3(0.012, 0.008, 0.02), clamp(step3 / 3.0, 0.0, 1.0));
			a = max(a * 0.5, (1.0 - smoothstep(0.85, 1.05, st)) * 0.85);
			rough = 0.32;
			em = v2_interior_accent * seam * 0.12 * (1.0 - smoothstep(0.6, 1.05, st)) * flick(0.7 + n1 * 0.3, scene_t, seed);
			hs = 0.0;
		}
		if (v2_soot <= 0.01) { hs = 0.0; }
	}
	if (style == 14) {
		float rg = (u - 0.9) / 0.05;
		float ridge = exp(-(rg * rg));
		alb = wound_kind == 1 ? vec3(0.24, 0.21, 0.12) : (wound_kind == 2 ? vec3(0.5, 0.55, 0.64) : vec3(0.16, 0.18, 0.2));
		a = (1.0 - smoothstep(0.88, 1.0, u)) * (wound_kind == 1 ? smoothstep(0.0, 3.0, age) : 0.7);
		em = glow * ridge * 0.035;
		if (wound_kind == 3) {
			float panel = floor((q.x / R + 1.0) * 2.0);
			float reboot = smoothstep(panel * 0.3, panel * 0.3 + 0.5, age);
			em += glow * ridge * reboot * 0.05;
		}
	}
	ALBEDO = alb;
	ALPHA = clamp(a, 0.0, 1.0);
	ROUGHNESS = rough;
	// r13: soot and char are matte and barely reflect; the old flat metallic 0.35 let the key light's glancing sheen turn
	// a dark halo light grey on the PC frigate, so the darkening never showed
	METALLIC = mix(0.35, 0.0, hs);
	SPECULAR = mix(0.5, 0.1, hs);
	EMISSION = em * fx_gain;
}
"""

# R416 5.3 (issue 1741, Wounds V2 only): the one interior shader for authored inside surfaces (decks, bulkheads, rooms,
# organs, bone hoops, light cores) once a ship is holed or dying; intact ships keep their own material. The surfaces have
# no UVs, so the detail is triplanar in the hull frame: floors and decks one pattern, walls another, per faction
# (wound_v2 0 Sunward iron grating and riveted panels, 1 Directorate pale panels and blue strips, 2 Hullbreakers bolted
# scrap and red-amber seams, 3 Chorus wet muscle, bone and bile veins, 4 Glasswright facets and braided light, 5 Eclipse
# milled obsidian ribs and violet seams), with a bump from the pattern and cavity shading in its grooves. Live
# (fx_wreck 0), only what an open mouth looks into is lifted out of the dark (fx_mouths, the same list the hull's cut
# uses); fx_mouth_count < 0 lifts it all (a wreck piece). fx_wreck 1 settles it into the faction's own wreck look.
const INTERIOR := """
shader_type spatial;
render_mode cull_disabled, fog_disabled;
""" + COMMON + """
uniform vec4 base_albedo : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform sampler2D base_tex : source_color, hint_default_white;
uniform vec4 base_emission : source_color = vec4(0.0);
uniform float base_emission_energy = 1.0;
uniform sampler2D base_em_tex : source_color, hint_default_white;
uniform sampler2D base_normal : hint_normal;
uniform bool has_normal = false;
uniform sampler2D base_orm : hint_default_white;
uniform bool has_orm = false;
uniform float base_metal = 0.0;
uniform float base_rough = 0.8;
// Fable review B3: the surface's role (0 wall, deck, frame or machinery; 1 bone; 2 core; 3 glass; 4 organ or gland) and
// whether its colour came from the faction role table (Interior Kit V2, PR 1763) and so is kept, not replaced
uniform int role = 0;
uniform bool trusted = false;
uniform int wound_v2 = 0;
uniform vec3 v2_scorch_col = vec3(0.1);
uniform vec3 v2_rim_metal = vec3(0.6);
uniform vec3 v2_interior_lift = vec3(0.3);
uniform vec3 v2_interior_accent = vec3(1.0, 0.5, 0.15);
uniform float v2_wall_max = 0.11;   // the faction's interior wall ceiling (R420 0.11; Glasswrights 0.45, Ryan Nov 24)
uniform float v2_rough = 0.6;
uniform float v2_soot = 1.0;
uniform float v2_wreck_soot = 0.3;
uniform float tri_scale = 1.0;
uniform mat4 fx_hull_frame;
uniform int fx_mouth_count = 0;
uniform vec4 fx_mouths[64];
uniform vec4 fx_axes[64];
uniform float fx_wreck = 0.0;
uniform float fx_wreck_t0 = -1.0;   // the death moment (scene_t): the wreck look settles in over 4 s from it; < 0 at once
uniform float fx_power = 1.0;
varying vec3 vP;
varying vec3 vN;
float ih(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float inz(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(ih(i), ih(i + vec2(1.0, 0.0)), f.x), mix(ih(i + vec2(0.0, 1.0)), ih(i + vec2(1.0, 1.0)), f.x), f.y);
}
// 1 on a seam line (within w of a whole number of x), 0 across the panel (Fable review B2: it was inverted)
float line(float x, float w) { return smoothstep(0.0, w, abs(fract(x) - 0.5) * 2.0 - (1.0 - w * 2.0)); }
vec2 icells(vec2 p) {
	vec2 g = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0, d2 = 8.0, id = 0.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 o = vec2(float(i), float(j));
			vec2 c = o + vec2(ih(g + o), ih(g + o + 17.3)) - f;
			float d = dot(c, c);
			if (d < d1) { d2 = d1; d1 = d; id = ih(g + o + 5.1); } else if (d < d2) { d2 = d; }
		}
	}
	return vec2(sqrt(d2) - sqrt(d1), id);
}
// One plane of the pattern: x shade, y groove (1 deep in a seam), z glowing line, w roughness offset.
vec4 pat(vec2 uv, bool flat_f) {
	vec4 r = vec4(1.0, 0.0, 0.0, 0.0);
	float n = inz(uv * 3.0);
	if (wound_v2 == 0) {
		if (flat_f) { float slat = line(uv.x * 4.0, 0.25); float bar = line(uv.y * 0.5, 0.06); r.y = max(slat, bar) * 0.8; r.x = 0.85 + 0.3 * n; }
		else {
			vec2 pc = fract(uv * vec2(1.0, 1.6));
			float seam = max(line(uv.x, 0.04), line(uv.y * 1.6, 0.05));
			float rivet = 1.0 - smoothstep(0.03, 0.05, min(length(pc - vec2(0.08)), length(pc - vec2(0.92, 0.08))));
			float rib = line(uv.x * 0.25, 0.08);
			r.y = max(seam, rib * 0.7); r.x = 0.8 + 0.4 * n + rivet * 0.5; r.z = seam * step(0.85, inz(uv * 0.7)) * 0.6;
		}
	} else if (wound_v2 == 1) {
		if (flat_f) { r.y = max(line(uv.x, 0.03), line(uv.y, 0.03)); r.x = 1.05 + 0.1 * n; r.w = -0.1; }
		else {
			vec2 pc = fract(uv * vec2(1.0, 0.5));
			float louver = step(0.2, pc.x) * step(pc.x, 0.8) * step(0.3, pc.y) * step(pc.y, 0.7) * line(uv.y * 8.0, 0.3);
			r.y = max(max(line(uv.x, 0.03), line(uv.y * 0.5, 0.03)), louver * 0.6);
			r.x = 1.05 + 0.1 * n;
			r.z = line(uv.y * 0.5 + 0.5, 0.025) * 1.2;
		}
	} else if (wound_v2 == 2) {
		vec2 sz = vec2(0.7 + ih(floor(uv * 0.5)) * 0.8, 0.5 + ih(floor(uv * 0.5) + 3.1) * 0.7);
		vec2 pc = fract(uv / sz);
		float edge = max(line(uv.x / sz.x, 0.05), line(uv.y / sz.y, 0.06));
		float bolt = (1.0 - smoothstep(0.03, 0.06, abs(pc.y - 0.07))) * step(0.5, fract(pc.x * 6.0));
		float rust = smoothstep(0.55, 0.8, inz(uv * 1.3 + 7.0));
		r.y = max(edge, bolt * 0.5); r.x = (0.7 + 0.5 * ih(floor(uv / sz))) * (1.0 - rust * 0.3); r.w = 0.1 + rust * 0.15;
		r.z = edge * step(0.8, inz(uv * 0.5 + 3.0)) * 0.7;
	} else if (wound_v2 == 3) {
		float wv = uv.x * 5.0 + sin(uv.y * 1.3 + n * 2.0) * 1.2;
		float fibre = pow(abs(sin(wv)), 6.0);
		vec2 cc = icells(uv * 2.2);
		float bump = smoothstep(0.0, 0.25, cc.x);
		float vein = 1.0 - smoothstep(0.0, 0.04, abs(sin(uv.y * 0.9 + inz(uv * 0.8) * 4.0)) - 0.0);
		r.x = 0.7 + 0.4 * fibre + 0.2 * bump; r.y = (1.0 - fibre) * 0.4 + (1.0 - bump) * 0.4; r.z = vein * 0.9; r.w = -0.1;
	} else if (wound_v2 == 4) {
		vec2 cc = icells(uv * 1.6);
		float edge = 1.0 - smoothstep(0.0, 0.05, cc.x);
		float braid = pow(abs(sin(uv.x * 3.0 + sin(uv.y * 2.0) * 1.5)), 48.0) + pow(abs(sin(uv.x * 3.0 - sin(uv.y * 2.0) * 1.5 + 1.0)), 48.0);
		// sanity frame (Nov 22): the braid at 0.8 lit the whole wall as a lattice; a faint thread, the cell edges carry it
		r.x = 0.75 + 0.5 * cc.y; r.y = edge * 0.5; r.z = edge * 0.35 + braid * 0.2; r.w = -0.2;
	} else {
		float rib = line(uv.y * 6.0, 0.18);
		vec2 g = fract(uv * 1.5);
		float chan = max(line(uv.x * 1.5, 0.03) * step(0.3, inz(uv * 2.0)), line(uv.y * 1.5, 0.03) * step(0.6, inz(uv * 2.0 + 4.0)));
		r.x = 0.8 + 0.25 * n; r.y = max(rib * 0.6, chan); r.z = chan * 0.9;
	}
	return r;
}
void vertex() {
	vP = (fx_hull_frame * vec4(VERTEX, 1.0)).xyz;
	vN = normalize(mat3(fx_hull_frame) * NORMAL);
}
void fragment() {
	vec3 w = pow(abs(vN), vec3(4.0));
	w /= max(w.x + w.y + w.z, 1e-4);
	vec3 p = vP * tri_scale;
	bool flat_f = abs(vN.y) > 0.7;
	vec4 r = pat(p.zy, false) * w.x + pat(p.xz, flat_f) * w.y + pat(p.xy, false) * w.z;
	if (role == 1 || role == 2 || role == 3) { r.z = 0.0; }   // bone, cores and glass carry no glowing pattern lines
	if (role == 1) { r.y *= 0.4; }
	// how open this spot is to the outside: near an open mouth and below it
	float open_f = fx_mouth_count < 0 ? 1.0 : 0.0;
	float near = 0.0;
	for (int i = 0; i < 64; i++) {
		if (i >= fx_mouth_count) { break; }
		vec3 d = vP - fx_mouths[i].xyz;
		float R = max(fx_mouths[i].w, 1e-4);
		float h = dot(d, fx_axes[i].xyz);
		float o = (1.0 - smoothstep(R * 1.4, R * 5.5, length(d))) * (1.0 - smoothstep(R * 0.2, R * 0.6, h));
		open_f = max(open_f, o);
		near = max(near, 1.0 - smoothstep(0.0, R * 3.0, length(d)));
	}
	vec3 tex = texture(base_tex, UV).rgb;
	vec3 baked = base_albedo.rgb * tex;
	float ao = 1.0 - r.y * 0.65;
	float wr = clamp(fx_wreck, 0.0, 1.0) * (fx_wreck_t0 < 0.0 ? 1.0 : smoothstep(0.0, 4.0, scene_t - fx_wreck_t0));
	// Fable review B3: the pattern multiplies over the surface instead of replacing it. A role-table surface keeps its own
	// colour and trim; an older diagram-coloured surface keeps only its texture's light and dark (luma against the
	// texture's own mean, its last mip), in the faction's interior colour, so no diagram hue leaks into a breach
	float tl = dot(tex, vec3(0.2126, 0.7152, 0.0722));
	float tm = dot(textureLod(base_tex, UV, 14.0).rgb, vec3(0.2126, 0.7152, 0.0722));
	float detail = clamp(tl / max(tm, 0.02), 0.4, 1.8);
	vec3 hue = v2_interior_lift;
	if (role == 1) { hue = vec3(0.17, 0.15, 0.11); }                       // dry weathered bone, never flesh
	else if (role == 2) { hue = v2_interior_lift * 0.6; }                  // a core's housing is dark; its light does the work
	else if (role == 4 && wound_v2 == 3) { hue = vec3(0.075, 0.03, 0.022); }   // wet crimson-umber organ
	vec3 surf = trusted ? baked : hue * detail;
	vec3 lit = surf * mix(1.0, r.x * ao, trusted ? 0.5 : 1.0);
	vec3 wreck = lit * (1.0 - v2_wreck_soot);
	if (wound_v2 == 3) { wreck = mix(lit, vec3(0.1, 0.09, 0.07) * r.x, 0.35); }    // dull pale bone and wet dark tissue
	if (wound_v2 == 4) { wreck = mix(lit, v2_rim_metal * vec3(1.0, 0.97, 0.93) * 0.4 * (0.6 + 0.4 * r.x), 0.4); }   // pale frosted pearl glass, never dark grey (Ryan Nov 24)
	lit = mix(lit, wreck, wr);
	// R420: walls at most the faction's ceiling (0.11 linear mean; Glasswrights 0.45), held by scaling the colour so the
	// hue stays; bone and glass are exempt
	if (role == 0 || role == 2 || role == 4) {
		float lm = (lit.r + lit.g + lit.b) / 3.0;
		lit *= lm > v2_wall_max ? v2_wall_max / lm : 1.0;
	}
	// an older surface never shows its diagram colour, even away from a mouth: it fades toward a darker faction tone
	// (Antigravity audit on PR 1755, finding 1); a role-table surface keeps its own colour there
	ALBEDO = mix(trusted ? baked : lit * 0.15, lit, open_f);
	vec3 orm = has_orm ? texture(base_orm, UV).rgb : vec3(1.0, base_rough, base_metal);
	float rough = clamp(v2_rough + r.w, 0.04, 1.0);
	if (has_orm) { rough = mix(rough, orm.g, 0.5); }
	if (role == 1) { rough = 0.55; }
	if (wound_v2 <= 2) { rough = mix(rough, 0.92, wr * v2_wreck_soot); }
	ROUGHNESS = mix(base_rough, rough, open_f);
	float metal = (role == 1 || role == 4) ? 0.0 : ((wound_v2 <= 2 || wound_v2 == 5) ? 0.45 : 0.0);
	if (has_orm) { metal = mix(metal, orm.b, 0.5); }
	METALLIC = mix(base_metal, metal, open_f);
	SPECULAR = 0.5 * ao;
	AO = ao * (has_orm ? orm.r : 1.0);
	AO_LIGHT_AFFECT = 0.6;
	// bump from the pattern's grooves (screen-space derivatives: no tangents needed), over the trim's own normal map
	if (has_normal) { NORMAL_MAP = texture(base_normal, UV).rgb; }
	float hgt = -r.y * 0.6;
	vec3 sx = dFdx(VERTEX);
	vec3 sy = dFdy(VERTEX);
	vec3 r1 = cross(sy, NORMAL);
	vec3 r2 = cross(NORMAL, sx);
	float det = dot(sx, r1);
	vec3 grad = sign(det) * (dFdx(hgt) * r1 + dFdy(hgt) * r2);
	vec3 bn = abs(det) * NORMAL - grad * 1.5;
	bn = dot(bn, bn) > 1e-12 ? normalize(bn) : NORMAL;   // a grazing face (det 0) keeps its normal, never NaN (audit finding 2)
	NORMAL = normalize(mix(NORMAL, bn, open_f * (trusted ? 0.4 : 0.8)));
	float pulse = 0.75 + 0.25 * sin(scene_t * (wound_v2 == 3 ? 2.3 : 1.1) + vP.x * 0.4);
	float fade = wound_v2 == 4 ? mix(1.0, 0.25, wr) : (1.0 - wr * 0.85);
	float pw = clamp(fx_power, 0.0, 1.0);
	vec3 em = v2_interior_accent * r.z * pulse * fade * open_f * 0.35 * pw;
	em += v2_interior_accent * near * 0.04 * (1.0 - wr);
	// Fable review H3: the surface's own light keeps only its brightness, in the faction accent (no green Eclipse cores,
	// no lime Chorus vats from the old diagram colours); a role-table surface's light is already in faction colour
	vec3 bsrc = base_emission.rgb * base_emission_energy * texture(base_em_tex, UV).rgb;
	float bl = max(bsrc.r, max(bsrc.g, bsrc.b));
	float am = max(v2_interior_accent.r, max(v2_interior_accent.g, v2_interior_accent.b));
	vec3 bem = (trusted ? bsrc : v2_interior_accent / max(am, 1e-3) * bl) * pw * (1.0 - wr);
	bem *= mix(0.15, 1.0, open_f);
	// R420: non-core light at most 0.25, held by scaling (Fable review H2); a core is the HDR band and passes
	vec3 soft = em + (role == 2 ? vec3(0.0) : bem);
	float pk = max(soft.r, max(soft.g, soft.b));
	soft *= pk > 0.25 ? 0.25 / pk : 1.0;
	EMISSION = soft + (role == 2 ? bem : vec3(0.0));
}
"""

# Issue 462, the tell: a tear along one or two break lines (a capital has two), drawn as an overlay on the dying hull. It
# grows across the hull from the hit side (grow, half_span: -1 at the hit side, +1 across), white-hot at its moving tip
# and ember behind, at least two pixels wide at any camera. straight = 1 for a lance cut (the beam's own line).
# R398 (issue 1394, Ryan Nov 21: "The whole hull shouldn't glow green either. Just specific affected areas"): an acid
# kill's tell. Up to six spots in the ship's frame (xyz, radius), each a sick green patch with a ragged, eaten edge that
# spreads from a third of its radius to all of it between rise.x and rise.y (scene_t). No line, no white.
const MELT_GLOW := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform mat4 frame;
uniform vec4 spots[6];
uniform int n_spots = 0;
uniform vec2 rise = vec2(0.0, 1.0);
uniform vec3 hot = vec3(0.62, 0.85, 0.18);
uniform vec3 deep = vec3(0.26, 0.40, 0.05);
varying vec3 hp;
void vertex() {
	hp = (frame * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float u = clamp((scene_t - rise.x) / max(rise.y - rise.x, 0.0001), 0.0, 1.0);
	float g = 0.0;
	for (int i = 0; i < 6; i++) {
		if (i >= n_spots) { break; }
		float rad = max(spots[i].w, 0.001);
		float r = rad * (0.35 + 0.65 * u);
		vec3 q = (hp - spots[i].xyz) / rad;
		float eaten = (vnoise(q.xy * 3.1 + q.z * 1.7 + float(i) * 4.3) - 0.5) * 0.55;
		float d = distance(hp, spots[i].xyz) / r + eaten;
		g = max(g, 1.0 - smoothstep(0.35, 1.0, d));
	}
	float pulse = 0.88 + 0.12 * sin(scene_t * 4.5 + hp.x * 0.7);
	ALBEDO = clamp(mix(deep, hot, g * g) * g * u * pulse * 1.5 * fx_gain, 0.0, 8.0);
}
"""


const TEAR := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform mat4 frame;
uniform vec2 open_a = vec2(0.3, 1.33);
uniform vec3 cut_at = vec3(0.0);
uniform vec3 cut_axis = vec3(1.0, 0.0, 0.0);
uniform vec2 open_b = vec2(-1.0, 1.0);
uniform vec3 cut_at_b = vec3(0.0);
uniform vec3 cut_axis_b = vec3(1.0, 0.0, 0.0);
uniform vec3 grow = vec3(0.0, 0.0, -1.0);
uniform float half_span = 1.0;
uniform float width = 0.1;
uniform float straight = 0.0;
uniform vec3 tip = vec3(1.0, 0.94, 0.82);
uniform vec3 ember = vec3(1.0, 0.36, 0.07);
varying vec3 cut_p;
varying float view_d;
void vertex() {
	cut_p = (frame * vec4(VERTEX, 1.0)).xyz;
	view_d = -(MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z;
}
vec3 tear_line(vec3 at, vec3 axis, vec2 open, float pxw) {
	float u = (scene_t - open.x) / max(open.y - open.x, 0.0001);
	if (u <= 0.0) { return vec3(0.0); }
	float w = max(width, pxw * 3.2);
	float wig = (1.0 - straight) * (sin(dot(cut_p, vec3(1.7, 8.3, 5.1))) * 0.6 + sin(dot(cut_p, vec3(5.3, 2.9, 11.7))) * 0.4);
	float d = abs(dot(cut_p - at, axis) + wig * w * 0.9);
	float s = dot(cut_p - at, grow) / max(half_span, 0.001);
	float front = mix(-1.15, 1.15, clamp(u, 0.0, 1.0));
	float behind = front - s;
	if (behind < 0.0) { return vec3(0.0); }
	float core = 1.0 - smoothstep(w * 0.3, w, d);
	float halo = 1.0 - smoothstep(w, w * 4.0, d);
	float hot = exp(-behind * behind / 0.04) * (1.0 - smoothstep(1.0, 1.25, u));
	float age = clamp(behind / 2.3, 0.0, 1.0);
	vec3 c = mix(ember * 1.4, ember * vec3(0.7, 0.45, 0.35), age);
	c = mix(c, tip * 2.4, hot);
	return c * (core * 3.6 + halo * 0.9) * smoothstep(0.0, 0.06, u);
}
void fragment() {
	float pxw = px_world(1.0, view_d, PROJECTION_MATRIX);
	vec3 col = tear_line(cut_at, cut_axis, open_a, pxw);
	if (open_b.x >= 0.0) { col += tear_line(cut_at_b, cut_axis_b, open_b, pxw); }
	if (dot(col, col) < 1e-6) { discard; }
	ALBEDO = clamp(col * fx_gain, 0.0, 8.0);
}
"""

# Issue 1077: a ragged, stepped offset along a cut's axis, so a tear line wanders across the plates: value noise over the
# cut plane in plate-sized cells, eased so each plate holds a level and the line steps between them, plus a finer octave.
# fx_jag.x is the reach (ship units), fx_jag.y the plate size; zero reach is a straight line.
const JAG_FN := """
uniform vec2 fx_jag = vec2(0.0, 1.0);
float fxj_hash(vec3 p) { p = fract(p * 0.1031); p += dot(p, p.zyx + 31.32); return fract((p.x + p.y) * p.z); }
float fxj_vn(vec3 x) {
	vec3 i = floor(x);
	vec3 f = smoothstep(0.3, 0.7, fract(x));
	return mix(mix(mix(fxj_hash(i), fxj_hash(i + vec3(1.0, 0.0, 0.0)), f.x), mix(fxj_hash(i + vec3(0.0, 1.0, 0.0)), fxj_hash(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(fxj_hash(i + vec3(0.0, 0.0, 1.0)), fxj_hash(i + vec3(1.0, 0.0, 1.0)), f.x), mix(fxj_hash(i + vec3(0.0, 1.0, 1.0)), fxj_hash(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}
float fx_jag_offset(vec3 p, vec3 axis) {
	if (fx_jag.x <= 0.0) { return 0.0; }
	vec3 q = (p - axis * dot(p, axis)) / max(fx_jag.y, 1e-4);
	float v = 0.7 * fxj_vn(q) + 0.3 * fxj_vn(q * 2.7 + 5.3);
	return (v - 0.5) * 2.0 * fx_jag.x;
}
"""

# Issue 1077 (prototype, off by default: rendering/effects/death_story): structural strain before a big hull splits. The
# plating along each break line bulges a little and ripples (outward only, so it never sinks into the authored decks),
# and the dying hull's power-down material and the tear overlay move it the same way. Ship-space points and normals.
const STRAIN_FN := """
uniform vec4 fx_strain_at[3];
uniform vec4 fx_strain_n[3];
uniform vec3 fx_strain_k = vec3(0.0, 1.0, 0.0);
uniform vec2 fx_strain_t = vec2(1e9, 1e9);
float fx_strain_amount(float t) { return smoothstep(fx_strain_t.x, fx_strain_t.y, t); }
float fx_strain_band(int i, vec3 p) {
	if (fx_strain_at[i].w <= 0.0) { return 0.0; }
	float d = dot(p - fx_strain_at[i].xyz, fx_strain_n[i].xyz);
	float e = 1.0 - smoothstep(0.0, max(fx_strain_n[i].w, 0.0001), abs(d));
	return e * e;
}
vec3 fx_strain_offset(vec3 p, vec3 n, float t) {
	float a = fx_strain_amount(t) * fx_strain_k.x;
	if (a <= 0.0) { return vec3(0.0); }
	float f = max(fx_strain_band(0, p), max(fx_strain_band(1, p), fx_strain_band(2, p)));
	if (f <= 0.0) { return vec3(0.0); }
	float w = fx_strain_k.y;
	float rip = sin(dot(p, vec3(1.0, 0.37, 0.71)) * w) * sin(dot(p, vec3(-0.43, 1.0, 0.29)) * w * 1.37);
	return n * a * f * (0.35 + 0.65 * rip * rip);
}
"""


# Issue 1077: the tear overlay for the strain prototype. The same tear, on plating moved exactly as the power-down
# material moves it (plus a hair outward, so the additive overlay never loses its depth test), and hairline stress
# cracks along every break line, broken into dashes and flickering, that appear while the hull strains.
static func tear_strain_code() -> String:
	var c := patch(TEAR, "uniform mat4 frame;", "uniform mat4 frame;\n" + STRAIN_FN + "uniform vec3 fx_hair = vec3(0.02, 1.0, 0.0);\n" + JAG_FN)
	# Ryan on pass 4B: "the two straight clean lines of the glow and break". The tear and the hairlines run on a ragged,
	# stepped line across the plates (fx_jag: its reach and its plate size), not on the straight cut plane
	c = patch(c, "\tfloat d = abs(dot(cut_p - at, axis) + wig * w * 0.9);", "\tfloat d = abs(dot(cut_p - at, axis) + wig * w * 0.9 + fx_jag_offset(cut_p, axis));")
	c = patch(c, "\tcut_p = (frame * vec4(VERTEX, 1.0)).xyz;\n",
		"\tcut_p = (frame * vec4(VERTEX, 1.0)).xyz;\n\tvec3 sn = normalize(mat3(frame) * NORMAL);\n\tvec3 so = fx_strain_offset(cut_p, sn, scene_t);\n\tVERTEX += inverse(mat3(frame)) * (so * 1.08 + sn * fx_strain_k.x * 0.04 * fx_strain_amount(scene_t));\n")
	c = patch(c, "\tif (dot(col, col) < 1e-6) { discard; }",
		"""\tfloat amt = fx_strain_amount(scene_t);
	if (amt > 0.0) {
		float hw = max(fx_hair.x, pxw * 1.3);
		for (int i = 0; i < 3; i++) {
			if (fx_strain_at[i].w <= 0.0) { continue; }
			float wig = sin(dot(cut_p, vec3(2.3, 9.1, 4.7))) * 0.6 + sin(dot(cut_p, vec3(6.1, 3.7, 12.9))) * 0.4;
			float d = abs(dot(cut_p - fx_strain_at[i].xyz, fx_strain_n[i].xyz) + wig * hw * 1.2 + fx_jag_offset(cut_p, fx_strain_n[i].xyz));
			float line = 1.0 - smoothstep(hw * 0.3, hw, d);
			float dash = smoothstep(0.15, 0.75, sin(dot(cut_p, vec3(3.1, 7.7, 5.3)) * fx_hair.y + float(i) * 1.7) * 0.5 + 0.5);
			float flick = 0.65 + 0.35 * sin(scene_t * 23.0 + float(i) * 2.1 + dot(cut_p, vec3(0.9, 1.3, 0.7)));
			col += ember * fx_hair.z * line * dash * flick * amt;
			// far away the band itself carries the tell (the hairlines are under a pixel at the battle camera): it brightens as a
			// pixel grows towards a tenth of the band's half width
			float far = clamp(pxw / max(fx_strain_n[i].w * 0.1, 1e-4), 0.0, 1.0);
			col += ember * vec3(0.6, 0.45, 0.35) * (0.12 + 0.33 * far) * flick * fx_strain_band(i, cut_p + fx_strain_n[i].xyz * fx_jag_offset(cut_p, fx_strain_n[i].xyz)) * amt;
		}
	}
	if (dot(col, col) < 1e-6) { discard; }""")
	return c


# Screen-space distortion: shockwave rings and heat haze bend the picture behind them (max only).
# Per quad: a0 = (pos, tStart), a1 = (normal, life), a3 = (size0, size1, kind, strength): kind 0 ring, 1 haze blob.
const DISTORT := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
varying vec2 vUv;
varying vec4 vInfo;
void vertex() {
	vec4 a0 = CUSTOM0; vec4 a1 = CUSTOM1; vec4 a3 = CUSTOM3; vec4 a4 = vec4(UV, UV2);
	float a = scene_t - a0.w;
	float age = pAge(a, a4.x);
	float life = a1.w;
	vUv = vec2(0.0); vInfo = vec4(0.0);
	if (a < 0.0 || age >= life) {
		""" + HIDE + """
	} else {
		float t = age / life;
		float size = mix(a3.x, a3.y, 1.0 - spow(1.0 - t, 2.5));
		vec3 c = (MODEL_MATRIX * vec4(a0.xyz, 1.0)).xyz;
		vec4 vp = VIEW_MATRIX * vec4(c, 1.0);
		vp.xy += VERTEX.xy * size;
		POSITION = PROJECTION_MATRIX * vp;
		vUv = VERTEX.xy * 2.0;
		vInfo = vec4(t, a3.z, a3.w, age);
	}
}
void fragment() {
	vec2 p = vUv;
	float r = length(p);
	if (r > 1.0) { discard; }
	float t = vInfo.x; int k = int(vInfo.y + 0.5); float S = vInfo.z;
	vec2 off = vec2(0.0);
	if (k == 0) {
		float d = (r - 0.8) / 0.12;
		off = normalize(p + 1e-5) * exp(-d * d) * S * 0.03 * (1.0 - t);
	} else {
		float n1 = vnoise(p * 4.0 + vec2(0.0, scene_t * 3.0)) - 0.5;
		float n2 = vnoise(p * 4.0 + vec2(5.2, scene_t * 2.6)) - 0.5;
		off = vec2(n1, n2) * S * 0.012 * (1.0 - r) * sin(3.14159 * t);
	}
	ALBEDO = textureLod(screen_tex, SCREEN_UV + off, 0.0).rgb;
	ALPHA = clamp((1.0 - r) * 4.0, 0.0, 1.0);
}
"""


# Eclipse weapons, issue 815. Separate alpha materials keep the violet-black
# occluding sheath local to Doom; all other beam kinds retain their shaders.
const ECLIPSE_ARC := """
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform float gate = 1.0;
uniform vec3 eclipse_sheath;
uniform sampler2D kit_flow : filter_linear, repeat_enable;
varying vec4 vCol;
varying vec4 vArc;
varying float vWidth;
varying float vSeed;
void vertex() {
	vec4 a0 = CUSTOM0; vec4 a1 = CUSTOM1; vec4 a2 = CUSTOM2; vec4 a3 = CUSTOM3; vec4 a4 = vec4(UV, UV2);
	float age = scene_t - a4.x;
	vCol = vec4(0.0); vArc = vec4(0.0); vWidth = 1.0; vSeed = a3.z;
	if (age < 0.0 || age >= a4.y || gate <= 0.001) {
		""" + HIDE + """
	} else {
		float s = VERTEX.x;
		vec3 dir = snorm(a1.xyz);
		vec3 n1 = snorm(cross(dir, abs(dir.y) < 0.9 ? vec3(0,1,0) : vec3(1,0,0)));
		vec3 n2 = cross(n1, dir);
		float flow_t = age * mix(1.0, 0.35, fx_calm);
		// Held aim, with small eddies carried down the discharge channel.
		float jag = (vnoise(vec2(s * 15.0, a3.z * 7.0)) - 0.5) * 1.7;
		jag += (vnoise(vec2(s * 45.0 - flow_t * 6.0, a3.z * 13.0)) - 0.5) * 0.45;
		vec3 p = a0.xyz + dir * s * a1.w;
		p += (n1 * jag + n2 * sin(s * 21.0 - flow_t * 3.0 + a3.z) * 0.28) * sin(s * 3.141593) * a1.w * 0.033;
		vec3 wp = (MODEL_MATRIX * vec4(p, 1.0)).xyz;
		vec3 wd = snorm((MODEL_MATRIX * vec4(dir, 0.0)).xyz);
		vec3 side = snorm(cross(wd, CAMERA_POSITION_WORLD - wp));
		float du = frame_world(1.0, max(-(VIEW_MATRIX * vec4(wp,1)).z, 0.01), PROJECTION_MATRIX, 1080.0);
		float width = max(mix(a3.x, a3.y, s), du * 84.0);
		vWidth = width / du;
		wp += side * VERTEX.y * width;
		POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(wp, 1.0);
		vCol = vec4(a2.rgb, a2.a * gate);
		vArc = vec4(s, VERTEX.y * 2.0, age, a4.y);
	}
}
void fragment() {
	float s = vArc.x; float age = vArc.z; float life = vArc.w;
	float y = vArc.y * vWidth * 0.5;
	float t = age * mix(1.0, 0.35, fx_calm);
	float advect = s * 32.0 - t * 8.0;
	float env = smoothstep(0.0, mix(0.035, 0.14, fx_calm), age);
	env *= 1.0 - smoothstep(max(0.0, life - 0.20), life, age);
	float ends = smoothstep(0.0, 0.012, s) * (1.0 - smoothstep(0.985, 1.0, s));
	ends *= 1.0 - smoothstep(age / 0.03 - 0.04, age / 0.03 + 0.04, s);
	// Independent scales swell, pinch and erode the edge. There is no rim line.
	float broad = vnoise(vec2(advect * 0.28, vSeed * 21.0));
	float grain = vnoise(vec2(advect * 2.3, y * 0.42 + vSeed * 9.0));
	float wisps = texture(kit_flow, vec2(s * 8.0 - t * 1.6, y * 0.035 + vSeed)).b;
	// R277: the hot braids sit inside a wider, noise-eroded violet body.
	float radius = 10.0 + broad * 13.0;
	float edge = radius - abs(y) + (grain - 0.5) * 8.0 + (wisps - 0.5) * 5.0;
	float sheath = smoothstep(-2.0, 3.0, edge) * (0.55 + grain * 0.4);
	float haze = exp(-y*y / (radius*radius*1.8)) * (0.18 + wisps * 0.12);
	float pulse = 0.65 + 0.35 * sin(s * 24.0 - t * 19.0);
	// Three slender braided filaments, with independent turbulent centres.
	float twist = s * 46.0 - t * 11.0 + vSeed * 6.0;
	float centre = (grain - 0.5) * 1.5;
	float spread = 2.0 + broad * 6.0;
	float f0 = centre + sin(twist) * spread;
	float f1 = centre + sin(twist * 1.13 + 2.094) * spread * 0.82 + (wisps - 0.5) * 2.0;
	float f2 = centre + sin(twist * 0.91 + 4.189) * spread * 1.12 - (grain - 0.5) * 1.8;
	float d0 = y - f0;
	float d1 = y - f1;
	float d2 = y - f2;
	float hot0 = exp(-((d0 / 0.95) * (d0 / 0.95)));
	float hot1 = exp(-((d1 / 0.75) * (d1 / 0.75)));
	float hot2 = exp(-((d2 / 0.85) * (d2 / 0.85)));
	float filaments = hot0 + hot1 * 0.85 + hot2 * 0.7;
	float glow = exp(-((d0 / 2.7) * (d0 / 2.7))) + exp(-((d1 / 2.2) * (d1 / 2.2))) * 0.6;
	float white = exp(-((d0 / 0.28) * (d0 / 0.28)));
	// A fork's tip expires within 3 to 5 frames. Clocks are staggered by root.
	float lane = floor(s * 13.0); float q = fract(s * 13.0);
	float beat = fract(t * 10.0 + h21(vec2(lane, vSeed)));
	float alive = smoothstep(0.0, 0.10, beat) * (1.0 - smoothstep(0.26, 0.55, beat));
	float branch = (mod(lane, 2.0) * 2.0 - 1.0) * (3.0 + sqrt(q) * 25.0);
	branch += sin(q * 27.0 + lane) * 1.5;
	float fb = (y - branch) / 0.65;
	float fork = exp(-(fb * fb)) * (1.0 - smoothstep(0.32, 0.65, q)) * alive;
	vec3 core_col = vCol.rgb;
	// The weapon_core colour (deep violet since issue 1503) stays on the hot strands; the surrounding flow is violet.
	vec3 violet = eclipse_sheath / max(max(eclipse_sheath.r, eclipse_sheath.g), max(eclipse_sheath.b, 0.0001));
	vec3 colour = eclipse_sheath * (0.45 + grain * 1.3);
	colour += violet * (sheath * (0.18 + wisps * 0.28 + grain * 0.22) + haze * 0.22);
	colour += core_col * (glow * 0.5 + filaments * (2.0 + pulse * 1.5) + fork * 2.0);
	colour += vec3(0.95, 0.90, 1.0) * white * (0.5 + pulse * 0.8);
	ALBEDO = colour * fx_gain;
	ALPHA = clamp((sheath * 0.85 + haze + filaments + fork) * env * ends * min(vCol.a, 1.0), 0.0, 0.98);
}
"""

# One ballistic head and its deposited, cooling history. a3.z is flight time.
# The R271 tracer supersedes the old two-frame/26 px rule for kind 5 only.
const NULL_SLUG := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform float gate = 1.0;
varying vec4 vTrace;
varying vec4 vTint;
varying vec3 vShape;
void vertex() {
	vec4 a0 = CUSTOM0; vec4 a1 = CUSTOM1; vec4 a2 = CUSTOM2; vec4 a3 = CUSTOM3; vec4 a4 = vec4(UV, UV2);
	float age = scene_t - a0.w;
	if (age > -0.0001) { age = max(age, 0.0); }
	vTrace = vec4(0.0); vTint = vec4(0.0); vShape = vec3(0.0);
	if (age < 0.0 || age >= a1.w || gate <= 0.0) {
		""" + HIDE + """
	} else {
		float flight = max(a3.z, 0.016667);
		float head_s = clamp(age / flight, 0.0, 1.0);
		vec3 dir = snorm(a1.xyz);
		vec3 tail = (MODEL_MATRIX * vec4(a0.xyz, 1.0)).xyz;
		vec3 head = (MODEL_MATRIX * vec4(a0.xyz + dir * a3.x * head_s, 1.0)).xyz;
		vec3 wd = snorm((MODEL_MATRIX * vec4(dir, 0.0)).xyz);
		float du = frame_world(1.0, max(-(VIEW_MATRIX * vec4(head,1)).z, 0.01), PROJECTION_MATRIX, 1080.0);
		// A tiny head quad exists even at t=0, rooted at the muzzle.
		tail -= wd * du * 12.0;
		vec3 front = head + wd * du * 12.0;
		vec3 side = snorm(cross(wd, CAMERA_POSITION_WORLD - head));
		float width = max(a3.y, du * 20.0);
		vec3 p = mix(tail, front, VERTEX.x) + side * VERTEX.y * width;
		POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(p, 1.0);
		float along = mix(-du * 12.0, a3.x * head_s + du * 12.0, VERTEX.x) / max(a3.x, 0.001);
		vTrace = vec4(along, VERTEX.y * width / du, age, flight);
		vShape = vec3(head_s, a3.x / du, a1.w);
		vTint = vec4(a2.rgb, a2.a * gate);
	}
}
void fragment() {
	float s = vTrace.x; float y = vTrace.y; float age = vTrace.z; float flight = vTrace.w;
	float lag = max(age - s * flight, 0.0);
	float end_age = max(age - flight, 0.0);
	float rear = smoothstep(0.0, 0.14, s);
	float taper = mix(0.28, 1.0, smoothstep(0.0, 0.30, s));
	float ys = y / (1.8 * taper);
	float streak = exp(-(ys * ys)) * rear;
	float passed = 1.0 - smoothstep(vShape.x, vShape.x + 0.003, s);
	streak *= passed;
	streak *= exp(-lag * 4.8) * (1.0 - smoothstep(0.32, 0.52, end_age));
	float head_x = (vShape.x - s) * vShape.y;
	float hx = head_x / 5.0;
	float hy = y / 3.5;
	float head = exp(-(hx * hx) - (hy * hy));
	head *= 1.0 - smoothstep(flight, flight + 0.018, age);
	float yw = y / 4.6;
	float wake = exp(-(yw * yw)) * rear * exp(-lag * 3.0) * passed;
	wake *= 1.0 - smoothstep(0.45, 0.70, end_age);
	float ions = 0.7 + 0.3 * sin(s * 85.0 - age * 5.0);
	vec3 violet = vTint.rgb;
	vec3 colour = violet * (streak * 3.0 + wake * ions * 0.18);
	colour += vec3(0.92, 0.86, 1.0) * (head * 5.5 + streak * 1.3);
	ALBEDO = colour * fx_gain * min(vTint.a / 3.0, 1.0);
	ALPHA = clamp(max(head, max(streak, wake * 0.15)), 0.0, 1.0);
}
"""
