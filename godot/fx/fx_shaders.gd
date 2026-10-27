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

const COMMON := """
global uniform float scene_t;
global uniform float fx_gain;
global uniform float fx_calm;
float spow(float b, float e) { return pow(max(b, 0.0), e); }
vec3 snorm(vec3 v) { float l = length(v); return l > 1e-6 ? v / l : vec3(0.0, 1.0, 0.0); }
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

# Sprites (camera-facing). kinds:
#  0 flash   1 flame   2 fireball core   3 smoke   4 engine core   5 squib   7 vent gas   8 soot   11 sputtering core
#  12 beam charge   13 beam impact flare   14 plasma bolt   15 bio glob   16 prism glint   17 star ball
#  18 soft lift (reduce-flashing pop: a gentle glow, no peak)   19 ember   20 acid fume   21 heat glow (cooling metal)
#  22 coil glow (gauss charge, stepped)   23 craft (a tiny strike craft silhouette with an engine dot)
const SPRITE := """
shader_type spatial;
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform float gate = 1.0;
varying vec2 vUv;
varying vec4 vCol;
varying vec4 vInfo;
varying float vLife;
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
		if (k == 1 || k == 20) { g = 1.0 - spow(1.0 - t, 2.2); }
		else if (k == 2 || k == 5 || k == 18) { g = sqrt(t); }
		else if (k == 3 || k == 7 || k == 8) { g = 1.0 - spow(1.0 - t, 1.6); }
		else if (k == 4 || k == 11 || k == 13 || k == 14 || k == 15 || k == 16 || k == 17 || k == 19 || k == 21 || k == 22 || k == 23) { g = 0.0; }
		else if (k == 12) { g = t * t; }
		float size = mix(a3.x, a3.y, g);
		vec3 disp = pDisp(a1.xyz, a4.z, a4.y, age);
		vec3 lp = a0.xyz + disp;
		if (k == 15) { lp += vec3(sin(age * 9.0 + a3.w * 20.0), cos(age * 7.0 + a3.w * 13.0), sin(age * 8.0 + a3.w * 5.0)) * size * 0.12; }
		vec3 c = (MODEL_MATRIX * vec4(lp, 1.0)).xyz;
		float ang = a3.w * 6.2831853 + age * a4.w;
		vec4 vp = VIEW_MATRIX * vec4(c, 1.0);
		vec2 q = VERTEX.xy;
		if (k == 14 || k == 15 || k == 23) {
			// stretched along the screen-space motion (bolts and globs read as moving, not as dots)
			vec3 vw = (MODEL_MATRIX * vec4(a1.xyz, 0.0)).xyz;
			vec2 sv = (VIEW_MATRIX * vec4(vw, 0.0)).xy;
			float sl = length(sv);
			vec2 dx = sl > 1e-4 ? sv / sl : vec2(1.0, 0.0);
			vec2 dy = vec2(-dx.y, dx.x);
			float st = k == 23 ? 1.4 : (k == 14 ? 1.0 + clamp(sl * 0.012, 0.0, 1.6) : 1.0 + clamp(sl * 0.006, 0.0, 0.6));
			q = dx * VERTEX.x * st + dy * VERTEX.y;
		} else {
			float cs = cos(ang);
			float sn = sin(ang);
			q = vec2(cs * VERTEX.x - sn * VERTEX.y, sn * VERTEX.x + cs * VERTEX.y);
		}
		vp.xy += q * size;
		POSITION = PROJECTION_MATRIX * vp;
		vUv = VERTEX.xy * 2.0;
		vCol = vec4(a2.rgb, a2.a * gate);
		vInfo = vec4(t, a3.z, a3.w, age);
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
	} else if (k == 1) {
		float n = fbm(p * 1.7 + vec2(seed * 13.1, seed * 7.7) + vec2(0.0, -t * 1.2));
		float dens = (1.0 - r) * 1.4 + (n - 0.5) * 1.15;
		float thr = t * 1.1;
		float m = smoothstep(thr, thr + 0.35, dens);
		float heat = clamp(dens - thr, 0.0, 1.0) * (1.0 - t * 0.6);
		add = heatRamp(heat) * mix(vec3(1.0), vCol.rgb * 1.6, 0.25) * I * (0.5 + 2.6 * heat * heat) * m * smoothstep(0.0, 0.05, t);
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
	} else if (k == 7 || k == 20) {
		float n = fbm(p * 1.6 + vec2(seed * 9.1, seed * 4.3) + vec2(0.0, -age * 1.4));
		float dens = (1.0 - r) * 1.1 + (n - 0.5) * 1.3;
		float m = smoothstep(0.1, 0.75, dens);
		alpha = m * I * smoothstep(0.0, 0.08, t) * spow(1.0 - t, 1.5);
		base = vCol.rgb * (0.8 + 0.4 * n);
		if (k == 20) { add = vCol.rgb * 0.35 * alpha * (0.5 + n); }
	} else if (k == 4 || k == 11) {
		float fl = flick(0.85 + 0.15 * vnoise(vec2(scene_t * 31.0, seed * 9.0)), scene_t, seed);
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
	} else if (k == 15) {
		// bio glob: a wet, dark-skinned body with a bioluminescent heart and a wobbling rim
		float n = fbm(p * 2.0 + vec2(seed * 5.0, age * 2.0));
		float body = smoothstep(0.85, 0.55, r + (n - 0.5) * 0.45);
		float heart = exp(-r * r * 6.0) * (0.6 + 0.4 * sin(age * 11.0 + seed * 9.0));
		float rim = smoothstep(0.45, 0.8, r + (n - 0.5) * 0.3) * body;
		alpha = body * I * 0.9;
		base = vec3(0.05, 0.06, 0.03) * (0.6 + n);
		add = vCol.rgb * (heart * 1.8 + rim * 0.6) * I;
	} else if (k == 16) {
		// prism glint: a glassy four-point glint whose colour slides through the spectrum
		float f = (1.0 - t) * I;
		float hue = fract(seed + age * 1.7 + r * 0.6);
		vec3 spec = clamp(abs(fract(hue + vec3(0.0, 0.333, 0.667)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
		vec3 col = mix(vCol.rgb, spec, 0.45);
		add = (col * exp(-r * r * 9.0) * 1.4 + col * star * 1.2 + vec3(exp(-r * r * 60.0))) * f;
	} else if (k == 17) {
		// star torpedo: a little sun, churning surface, corona rays
		float n = fbm(p * 3.0 + vec2(age * 2.0, seed * 4.0));
		float sphere = smoothstep(0.42, 0.36, r);
		float ray = spow(abs(cos(atan(p.y, p.x) * 6.0 + age * 1.5 + seed * 4.0)), 18.0) * exp(-r * 2.5);
		add = (mix(vCol.rgb, vec3(1.0, 0.98, 0.9), 0.6) * sphere * (1.2 + 0.8 * n) + vCol.rgb * exp(-r * r * 4.0) * 0.8 + vCol.rgb * ray * 1.2) * I;
	} else if (k == 18) {
		float f = sin(3.14159 * t) * I;
		add = vCol.rgb * exp(-r * r * 2.5) * f;
	} else if (k == 19) {
		float f = spow(1.0 - t, 1.2) * I;
		vec3 c = mix(vec3(1.0, 0.85, 0.5), vCol.rgb, t);
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
	float soft = clamp((scene_z + VERTEX.z) / 0.6, 0.0, 1.0);
	add *= soft;
	alpha *= soft;
#endif
	ALBEDO = clamp(base * alpha + add * fx_gain, 0.0, 512.0);
	ALPHA = clamp(alpha, 0.0, 1.0);
}
"""

# Streaks (camera-facing lines). a3 = (length or blur seconds, width, drag, kind).
# kinds: 0 tracer   1 spark   3 flame tongue   4 las bolt (hard white core, short)   5 gauss wake (near invisible, fades
#        back to front)   6 droplet (bio, falls off a glob)   7 molten drip (lance trench)
const STREAK := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
varying vec2 vUv;
varying vec3 vCol;
varying float vK;
varying float vU;
void vertex() {
	vec4 a0 = CUSTOM0; vec4 a1 = CUSTOM1; vec4 a2 = CUSTOM2; vec4 a3 = CUSTOM3; vec4 a4 = vec4(UV, UV2);
	float a = scene_t - a0.w;
	float age = pAge(a, a4.x);
	float life = a1.w;
	vUv = vec2(0.0); vCol = vec3(0.0); vK = 0.0; vU = 0.0;
	if (a < 0.0 || age >= life) {
		""" + HIDE + """
	} else {
		vec3 v = a1.xyz;
		float sp = max(length(v), 1e-4);
		vec3 dir = v / sp;
		float dr = a3.z;
		int k = int(a3.w + 0.5);
		vec3 head; vec3 tail; float fade = 1.0; float u = age / life;
		if (k == 1 || k == 6 || k == 7) {
			float e = exp(-dr * age);
			head = a0.xyz + v * (1.0 - e) / max(dr, 1e-4);
			float L = max(a3.x * sp * e, 0.05);
			tail = head - dir * L;
			fade = (1.0 - u) * (1.0 - u);
		} else if (k == 3) {
			tail = a0.xyz;
			head = a0.xyz + dir * a3.x * (0.35 + 0.65 * sqrt(u));
			fade = spow(1.0 - u, 1.5);
		} else if (k == 5) {
			// the whole path appears at once and fades from the muzzle end toward the target
			tail = a0.xyz;
			head = a0.xyz + v * a3.x;
			fade = 1.0 - u;
		} else {
			float tr = sp * age + 0.5 * a4.y * age * age;
			head = a0.xyz + dir * tr;
			tail = head - dir * min(a3.x, tr);
		}
		head = (MODEL_MATRIX * vec4(head, 1.0)).xyz;
		tail = (MODEL_MATRIX * vec4(tail, 1.0)).xyz;
		vec3 mid = 0.5 * (head + tail);
		vec3 wd = snorm(head - tail);
		vec3 side = snorm(cross(wd, CAMERA_POSITION_WORLD - mid));
		vec3 p = mix(tail, head, VERTEX.x) + side * VERTEX.y * a3.y;
		vUv = VERTEX.xy;
		vK = a3.w;
		vU = u;
		vCol = a2.rgb * a2.a * fade;
		POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(p, 1.0));
	}
}
void fragment() {
	float x = abs(vUv.y) * 2.0;
	float core = exp(-x * x * 22.0);
	float glow = exp(-x * x * 4.0) * 0.45;
	int k = int(vK + 0.5);
	float along;
	vec3 c;
	if (k == 0) {
		along = spow(vUv.x, 2.5) * (1.0 - smoothstep(0.95, 1.0, vUv.x) * 0.5);
		float headB = exp(-spow((1.0 - vUv.x) * 9.0, 2.0)) * 2.0;
		// white-hot core, faction colour in the outer glow (A5 readability rule)
		c = vCol * glow * (along + headB) + vec3(core) * length(vCol) * 0.6 * (along + headB);
	} else if (k == 3) {
		along = (1.0 - vUv.x) * smoothstep(0.0, 0.08, vUv.x) + 0.15;
		float w = 1.0 - vUv.x * 0.6;
		float cc = exp(-x * x * 6.0 / (w * w));
		c = mix(vCol, vec3(length(vCol)) * vec3(1.0, 0.9, 0.75), (1.0 - vUv.x) * 0.6) * cc * along;
	} else if (k == 4) {
		along = smoothstep(0.0, 0.15, vUv.x) * (1.0 - smoothstep(0.85, 1.0, vUv.x));
		float hc = exp(-x * x * 60.0);
		c = (vec3(hc) * length(vCol) * 0.8 + vCol * exp(-x * x * 6.0) * 0.8) * along;
	} else if (k == 5) {
		float wake = smoothstep(vU * 1.2 - 0.2, vU * 1.2, vUv.x);
		float hc = exp(-x * x * 80.0);
		c = (vec3(hc) * length(vCol) * 0.7 + vCol * exp(-x * x * 10.0) * 0.25) * wake;
	} else if (k == 6) {
		along = smoothstep(0.0, 0.5, vUv.x);
		c = vCol * (glow + core) * along;
	} else {
		along = smoothstep(0.0, 0.45, vUv.x) * (1.0 - smoothstep(0.9, 1.0, vUv.x) * 0.7);
		c = vCol * (glow + core) * along + vec3(core * core) * length(vCol) * 0.25 * along;
	}
	ALBEDO = clamp(c * fx_gain, 0.0, 512.0);
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
		vec3 p = c + (t1 * VERTEX.x + t2 * VERTEX.y) * size;
		POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * (MODEL_MATRIX * vec4(p, 1.0)));
		vUv = VERTEX.xy * 2.0;
		vCol = vec4(a2.rgb, a2.a);
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
	vCol = vec4(0.0); vInfo = vec3(0.0); vInfo2 = vec2(0.0); vSide = 0.0; vAge = vec2(0.0);
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
			float strike = floor(age / 0.07);
			float j = (vnoise(vec2(s * 9.0, strike * 3.1 + seed)) - 0.5) * 2.0 + (vnoise(vec2(s * 31.0, strike * 1.7 + seed)) - 0.5) * 0.6;
			float j2 = (vnoise(vec2(s * 8.0 + 4.0, strike * 2.3 + seed)) - 0.5) * 2.0;
			float pin = sin(3.14159 * s);
			p += (n1 * j + n2 * j2) * pin * L * 0.06;
		}
		if (k == 9) {
			p += (n1 * sin(s * 9.0 - scene_t * 8.0 + seed) + n2 * cos(s * 7.0 - scene_t * 6.0)) * sin(3.14159 * s) * 1.2;
		}
		float w = mix(a3.x, a3.y, s);
		if (k == 2 || k == 5 || k == 8) { w *= 0.92 + 0.08 * sin(scene_t * 90.0 + s * 40.0); }
		vec3 wp = (MODEL_MATRIX * vec4(p, 1.0)).xyz;
		vec3 wdir = snorm((MODEL_MATRIX * vec4(dir, 0.0)).xyz);
		vec3 side = snorm(cross(wdir, CAMERA_POSITION_WORLD - wp));
		wp += side * VERTEX.y * w;
		vInfo2 = vec2(L, w);
		POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(wp, 1.0));
		vSide = VERTEX.y * 2.0;
		vCol = vec4(a2.rgb, a2.a * gate);
		vInfo = vec3(s, a0.w, seed);
		vAge = vec2(age, a4.y);
	}
}
void fragment() {
	float s = vInfo.x; int k = int(vInfo.y + 0.5); float seed = vInfo.z; float life = vAge.y; float age = vAge.x;
	float x = abs(vSide);
	vec3 c = vec3(0.0);
	if (k == 0 || k == 3) {
		float n = fbm(vec2(s * 5.0 - scene_t * 9.0, vSide * 1.5 + seed * 7.0));
		float core = exp(-x * x * (5.0 + s * 9.0));
		float shape = spow(1.0 - s, 2.4);
		float br = smoothstep(0.2, 0.7, n + 0.25 * (1.0 - s));
		float fl = flick(0.85 + 0.15 * vnoise(vec2(scene_t * 27.0, seed * 5.0)), scene_t, seed);
		if (k == 3) { fl *= mix(cough(scene_t, seed), 0.7, fx_calm); }
		// faint shock diamonds in the hot part of the plume
		float dia = 1.0 + 0.35 * spow(abs(sin(s * 38.0 - scene_t * 3.0)), 6.0) * (1.0 - smoothstep(0.0, 0.4, s));
		vec3 hot = mix(vec3(1.0, 0.95, 0.82), vCol.rgb, smoothstep(0.0, 0.3, s));
		c = hot * core * shape * (0.3 + 1.1 * br) * fl * dia * vCol.a;
	} else if (k == 1) {
		float n = fbm(vec2(s * 14.0 - scene_t * 0.6, vSide * 1.2 + seed * 3.0));
		float n2 = fbm(vec2(s * vInfo2.x * 0.18 - scene_t * 0.5, vSide * vInfo2.y * 0.25 + seed * 3.0));
		n = 0.5 * n + 0.5 * n2;
		float across = exp(-x * x * 2.2);
		float fade = spow(1.0 - s, 1.8) * smoothstep(0.0, 0.05, s);
		vec3 col = mix(vCol.rgb, vec3(0.30, 0.38, 0.60), smoothstep(0.0, 0.55, s));
		c = col * across * fade * smoothstep(0.25, 0.75, n + 0.15) * 1.4 * vCol.a;
	} else if (k == 6) {
		float env = smoothstep(0.0, 0.03, age) * (1.0 - smoothstep(life - 0.1, life, age));
		float strike = floor(age / 0.07);
		float flash = mix(0.6 + 0.4 * h21(vec2(strike, seed)), 0.85, fx_calm);
		float core = exp(-x * x * 40.0) * 4.0;
		float glow = exp(-x * x * 3.0) * 0.8;
		c = (vec3(0.9, 1.0, 0.92) * core + vCol.rgb * glow) * env * flash * vCol.a;
	} else if (k == 9) {
		float env = smoothstep(0.0, 0.08, age) * (1.0 - smoothstep(life - 0.15, life, age));
		float n = fbm(vec2(s * 12.0 - scene_t * 3.0, vSide * 2.0 + seed));
		float body = smoothstep(1.0, 0.4, x + (n - 0.5) * 0.6);
		c = vCol.rgb * (body * 0.6 + exp(-x * x * 10.0) * 1.2) * env * vCol.a;
	} else {
		float env = smoothstep(0.0, 0.05, age) * (1.0 - smoothstep(life - 0.12, life, age));
		float sh = 0.7 + 0.3 * vnoise(vec2(s * 120.0 - scene_t * 70.0, 0.0));
		float core = exp(-x * x * 60.0) * 5.0;
		float glow = exp(-x * x * 6.0) * 1.0 * sh + exp(-x * x * 1.6) * 0.15;
		float ends = smoothstep(0.0, 0.01, s) * (1.0 - smoothstep(0.985, 1.0, s));
		vec3 coreC = vec3(1.0, 0.97, 0.92);
		if (k == 5) {
			// ion: crawling blue-white arcs wrapped around the beam
			float arc = spow(abs(sin(s * vInfo2.x * 0.9 - scene_t * 40.0 + vSide * 3.0 + seed)), 30.0) * exp(-x * x * 1.2);
			glow += arc * 2.5 * (0.5 + 0.5 * vnoise(vec2(s * 30.0, scene_t * 25.0)));
		} else if (k == 7) {
			float puls = smoothstep(0.35, 0.0, abs(fract(s * vInfo2.x / 9.0 - age * 6.0) - 0.5) - 0.15);
			core *= 0.35 + puls;
			glow *= 0.4 + puls * 1.2;
		} else if (k == 8) {
			core = exp(-x * x * 140.0) * 6.0;
			glow = exp(-x * x * 10.0) * 0.7 * sh;
			float hue = fract(s * 3.0 - scene_t * 2.0 + seed);
			coreC = mix(coreC, clamp(abs(fract(hue + vec3(0.0, 0.333, 0.667)) * 6.0 - 3.0) - 1.0, 0.0, 1.0), 0.25);
		}
		c = (coreC * core + vCol.rgb * glow) * env * ends * vCol.a;
	}
	ALBEDO = clamp(c * fx_gain, 0.0, 512.0);
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
varying vec4 vCol;
varying vec4 vInfo;
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 wd = snorm((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float s = UV.x;
	float w = mix(CUSTOM1.x, CUSTOM1.y, s);
	vec3 side = snorm(cross(wd, CAMERA_POSITION_WORLD - wp));
	vec3 up = abs(wd.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
	vec3 n1 = snorm(cross(wd, up));
	vec3 n2 = cross(n1, wd);
	float seed = CUSTOM1.z;
	wp += (n1 * sin(s * 7.0 - scene_t * 1.3 + seed * 6.0) * 0.9 + n2 * sin(s * 5.0 - scene_t * 0.9 + seed * 3.0) * 0.7) * s * s * 2.2;
	wp += side * UV.y * w;
	VERTEX = (VIEW_MATRIX * vec4(wp, 1.0)).xyz;
	vCol = CUSTOM0;
	vInfo = vec4(s, UV.y * 2.0, seed, CUSTOM1.w);
}
void fragment() {
	float s = vInfo.x; float x = abs(vInfo.y); float seed = vInfo.z; int st = int(vInfo.w + 0.5);
	float n = fbm(vec2(s * 14.0 - scene_t * 0.6, vInfo.y * 1.2 + seed * 3.0));
	float n2 = fbm(vec2(s * 40.0 - scene_t * 0.5, vInfo.y * 2.0 + seed * 3.0));
	n = 0.5 * n + 0.5 * n2;
	float across = exp(-x * x * 2.2);
	float fade = spow(1.0 - s, 1.8) * smoothstep(0.0, 0.04, s);
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
	ALBEDO = clamp(col * across * fade * m * 1.4 * vCol.a * fx_gain, 0.0, 512.0);
}
"""

# Debris chips: tumbling 3D shards lit by the scene lights, hot at first.
# a1 = (vel, life); a2 = (spin axis, spin rate); a3 = (size, period, tint, drag); a4 = (heat, seed, 0, 0)
const SHARD := """
shader_type spatial;
render_mode cull_back;
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
		float sc = a3.x * (1.0 - smoothstep(0.85, 1.0, t));
		vec3 k = snorm(a2.xyz);
		float an = age * a2.w + a4.y * 6.2831853;
		float dr = a3.w;
		vec3 disp = dr > 0.0 ? a1.xyz * (1.0 - exp(-dr * age)) / dr : a1.xyz * age;
		VERTEX = a0.xyz + disp + rotA(VERTEX, k, an) * sc;
		NORMAL = rotA(NORMAL, k, an);
		vHeat = a4.x * exp(-age * 3.5);
	}
}
void fragment() {
	vec3 alb = vec3(0.032, 0.032, 0.036) * (0.6 + 0.9 * fract(vSeed * 17.3));
	if (vTint > 0.5) { alb = vec3(0.05, 0.06, 0.035) * (0.6 + 0.9 * fract(vSeed * 17.3)); }
	ALBEDO = alb;
	METALLIC = 0.5;
	ROUGHNESS = 0.45;
	EMISSION = vec3(1.0, 0.33, 0.06) * vHeat * 1.2 * fx_gain;
}
"""

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
uniform int style = 0;
uniform vec4 hits[6];
uniform vec4 hitw[6];
uniform float brk_t = -100.0;
uniform vec3 brk_dir = vec3(1.0, 0.0, 0.0);
uniform float regen_t = -100.0;
// the bubble's rim (faction look data, shield_edge): 0 none, 1 a colour, 2 rainbow (reserved for the coming lore looks)
uniform int edge_mode = 0;
uniform vec3 edge_col = vec3(1.0);
varying vec3 vL;
varying vec3 vW;
varying vec3 vN;
void vertex() {
	vL = VERTEX;
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vN = snorm((MODEL_MATRIX * vec4(NORMAL / rad, 0.0)).xyz);
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
	for (int i = 0; i < 6; i++) {
		vec4 h = hits[i];
		float age = scene_t - h.w;
		float life = hitw[i].y;
		if (age < 0.0 || age > life) { continue; }
		float f = age / life;
		float fade = (1.0 - f) * (1.0 - f) * smoothstep(0.0, 0.025, age);
		float d = length(lp - h.xyz);
		float S = hitw[i].x;
		float spread = hitw[i].z;
		float mask = 1.0 - smoothstep(spread * 0.35, spread, d);
		float hd = d / (0.9 + S * 0.4);
		float core = exp(-hd * hd) * 4.0 * (1.0 - f) * mix(1.0, 0.25, fx_calm);
		float rg = 0.0;
		for (int j = 0; j < 3; j++) {
			float aj = age - float(j) * 0.08;
			if (aj > 0.0) { float rd = (d - aj * spread * 1.6) / (0.5 + aj * 2.0); rg += exp(-rd * rd) * (j == 0 ? 1.7 : 0.8); }
		}
		I += (core + rg * mask * (0.6 + 0.4 * S)) * fade * S;
	}
	// regen shimmer: a band sweeping the bubble from stern to bow
	float ra = scene_t - regen_t;
	if (ra > 0.0 && ra < 1.0) {
		float band = (vL.x * 0.5 + 0.5) - ra * 1.3 + 0.15;
		I += exp(-band * band * 60.0) * 0.6 * (1.0 - ra);
	}
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	float fres = spow(1.0 - abs(dot(normalize(vN), V)), 4.0);
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
	// break (r4 review: three factions tore the same noise holes in a bright, nearly opaque bubble). Each faction now
	// breaks in its own way, spreading from the struck facing over the bubble, and the bubble stays see-through:
	//   0 Voidsworn: the gold veil cracks into sheets; cracks run white-gold ahead of the front, each sheet flares as it
	//     peels loose, then is gone;
	//   1 Hegemony: the hex lattice shatters cell by cell; each cell fills bright for an instant and pops out, its
	//     border glowing as the front nears (the shards fly as particles);
	//   2 Corsair: it sputters out in patches; each patch stutters on and off (slow breathing with reduce flashing) and
	//     dies, dirty red, until nothing is left;
	//   3 Ithar: the veil sheets away from the struck side (left as it was: the Ithar look is changing).
	float ba = scene_t - brk_t;
	if (ba > 0.0 && ba < 1.6) {
		vec3 un = normalize(vL);
		float facing = dot(un, normalize(brk_dir));
		float dist = (1.0 - facing) * 0.5;
		float life = 1.0 - ba / 1.6;
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
	if (total < 0.002) { discard; }
	ALBEDO = clamp(C * total * fx_gain, 0.0, 512.0);
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
render_mode cull_back;
""" + COMMON + """
uniform vec3 glow = vec3(1.0, 0.45, 0.12);
varying vec3 vL;
varying vec3 vNl;
varying vec4 vC;
varying vec4 vA;
varying vec4 vB;
varying vec4 vD;
void vertex() { vL = VERTEX; vNl = NORMAL; vC = COLOR; vA = CUSTOM0; vB = CUSTOM1; vD = CUSTOM2; }
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
	vec3 base = vec3(0.07, 0.066, 0.062) * (0.6 + 0.8 * vC.g) * (0.7 + 0.6 * n1);
	float rough = 0.72;
	float metal = 0.25;
	if (part > 0.2 && part < 0.3) { base *= 1.8; metal = 0.6; rough = 0.5; }
	if (part > 0.95) { base = vec3(0.06, 0.057, 0.054) * (0.8 + 0.4 * n2); rough = 0.55; metal = 0.5; ao = 0.8; }
	else if (part > 0.8) { base = vec3(0.62, 0.58, 0.48) * (0.75 + 0.35 * n2); rough = 0.45; metal = 0.0; ao = 1.0; }
	else if (part > 0.6) { base = mix(vec3(0.05, 0.042, 0.034), vec3(0.03, 0.03, 0.034), vC.g) * (0.8 + 0.4 * n2); rough = 0.5; }
	else if (part > 0.4) { float seam = smoothstep(0.9, 1.0, abs(sin(dot(vL, vec3(1.0, 1.3, 0.7)) * 9.0 / R))); base *= 1.15 - 0.4 * seam; }
	vec3 toF = fire - vL;
	float dist = length(toF) / R;
	if (part < 0.8) { base *= mix(0.5, 1.0, smoothstep(0.2, 1.4, dist)); }
	vec3 Nl = normalize(vNl) * (FRONT_FACING ? 1.0 : -1.0);
	float lam = 0.25 + 0.75 * max(dot(Nl, toF / max(length(toF), 1e-4)), 0.0);
	float fall = 1.0 / (1.0 + dist * dist * 5.0);
	float emb = smoothstep(0.66, 0.88, fbm(p.xy * 6.0 + p.zx * 4.0 + vec2(seed, scene_t * 0.12))) * (part < 0.3 ? 1.0 : 0.3);
	vec3 gc = glow;
	if (style == 8) { gc = vec3(0.45, 1.0, 0.2); hot *= 0.35; }
	if (style == 4 || style == 11) { hot *= 0.3; }
	vec3 em = gc * (lam * fall * 0.6 * fl * (0.3 + 0.7 * smoothstep(0.1, 0.8, deep)) + emb * 0.8 * (0.6 + 0.4 * fl) * smoothstep(1.4, 0.3, dist)) * hot;
	if (style == 1) {
		// a lance cut: the metal round the burn-through is molten, white, then orange, then dull red, then black
		float cool = exp(-age / 3.0);
		float m = cool * (part > 0.95 ? 1.0 : 0.6) * smoothstep(2.5, 0.3, dist);
		em = heatRamp(m) * m * 4.0;
		base *= 1.0 - 0.5 * cool;
	} else if (style == 5 || style == 6 || style == 0) {
		if (part > 0.95) { em += gc * exp(-age / 0.7) * 0.35 * heat * (0.7 + 0.3 * fl); }
	}
	ALBEDO = base;
	ROUGHNESS = rough;
	METALLIC = metal;
	AO = ao;
	AO_LIGHT_AFFECT = 1.0;
	SPECULAR = 0.3 * ao;
	EMISSION = em * fx_gain;
}
"""

# Each mark's surface (fx_breach.gd): a thin skin over the hull round the mark, blended on top. Per style: char and
# soot fans, molten metal along a lance cut cooling white to red to black with temper colours past it, glowing slag
# pockets that set dark and glassy, spall rings and radial cracks round a gauss exit, flak pockmarks and scratches,
# acid etching that bubbles and glows faintly, branching electrical burns that crackle and die (ion), scraped bare
# metal (ram). Same vertex data as HOLE plus CUSTOM3 (slot direction, half length).
const MARK := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, shadows_disabled;
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
uniform vec3 glow = vec3(1.0, 0.45, 0.12);
uniform vec3 weapon = vec3(1.0, 0.6, 0.3);
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
		a = fall * (0.5 + 0.5 * pits);
		alb = mix(vec3(0.05, 0.07, 0.025), vec3(0.01, 0.015, 0.005), pits);
		rough = mix(0.8, 0.25, wet * smoothstep(1.0, 0.4, ue));
		em = vec3(0.45, 1.0, 0.2) * (pits * 0.25 + bub * 1.2) * fall * mix(0.15, 1.0, exp(-age / 6.0));
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
		} else if (style == 8) {
			float pit = smoothstep(0.58, 0.72, hn);
			hc = mix(vec3(0.03, 0.045, 0.012), vec3(0.006, 0.01, 0.003), pit);
			hr = mix(0.85, 0.3, exp(-age / 9.0) * pit);
			hem = vec3(0.4, 1.0, 0.2) * pit * (0.04 + 0.4 * exp(-age / 6.0));
		} else if (style == 9) {
			hc = vec3(0.012, 0.015, 0.03);
			hem = vec3(0.3, 0.5, 1.0) * smoothstep(0.62, 0.8, hn) * (0.03 + 0.5 * live);
		} else if (style == 10) {
			// a ram scrapes the paint off: bright streaked bare metal, no soot
			float st = smoothstep(0.5, 0.85, fbm(vec2(q.x / R * 0.35, q.y / R * 5.0) + seed));
			hc = mix(vec3(0.1, 0.1, 0.1), vec3(0.42, 0.41, 0.4), st);
			hr = mix(0.6, 0.3, st);
			ha *= 0.5 + 0.5 * st;
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
		// r8 (Opus): every mark carries a short-lived glowing scorch, broken by the halo noise, in the weapon's own
		// heat colour, so a fresh hit reads from the battle camera even on a frigate. It comes up softly over a quarter
		// second and cools over several (no flash: it never jumps, so the flash budget is untouched). The soot under
		// it is darker and denser than before as well.
		vec3 sc = vec3(1.0, 0.4, 0.1);
		float scl = 6.0;
		float sk = 1.0;
		if (style == 1) { sc = vec3(1.0, 0.48, 0.14); scl = 5.0; }
		else if (style == 3) { sc = vec3(0.35, 0.65, 1.0); scl = 6.0; }
		else if (style == 8) { sc = vec3(0.45, 1.0, 0.2); scl = 8.0; sk = 1.3; }
		else if (style == 9) { sc = vec3(0.45, 0.65, 1.0); scl = 6.0; sk = 1.3; }
		else if (style == 7) { sk = 1.0; scl = 6.0; }
		else if (style == 6 || style == 11) { scl = 9.0; sk = 1.2; }
		else if (style == 10) { sc = vec3(1.0, 0.55, 0.25); scl = 5.0; sk = 1.1; }
		else if (style == 12 || style == 13) { sk = 0.0; }
		// ... and a dim glow that lingers for most of a minute, so a hit ship still shows its hits from the battle camera
		float sglow = smoothstep(0.0, 0.25, age) * (exp(-age / scl) + 0.12 * exp(-age / 45.0)) * sk;
		float sband = (1.0 - smoothstep(0.2, 0.7, hu)) * (0.35 + 0.65 * smoothstep(0.42, 0.68, hn));
		hem += sc * sband * sglow * 2.4;
		if (style != 10 && style != 7) { hc *= 0.7; ha = min(1.0, ha * 1.25); }
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
		if (le > 0.0) {
			float ew = (eb.y - eb.x) * 0.3;
			float edge = smoothstep(eb.x, eb.x + ew, hu) * (1.0 - smoothstep(eb.y - ew, eb.y, hu));
			edge *= 0.35 + 0.65 * smoothstep(0.42, 0.66, hn);
			em += sc * edge * le * smoothstep(0.0, 0.25, age) * exp(-age / 420.0);
		}
	}
	if (a < 0.003 && dot(em, vec3(1.0)) < 0.003) { discard; }
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

# Death pieces: an overlay on each piece of the broken hull. Front faces glow along the break (distance to the
# boundary between this piece's seed and its nearest neighbour's); back faces seen through the open cut draw as a dark,
# charred interior with embers, so the pieces read as solid. heat cools from 1 to 0 over the wreck's life.
const CHUNK := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform vec4 seeds[8];
uniform int n_seeds = 2;
uniform int me = 0;
uniform float heat = 1.0;
uniform float width = 0.4;
uniform vec3 glow = vec3(1.0, 0.45, 0.1);
varying vec3 vL;
void vertex() { vL = VERTEX; }
void fragment() {
	vec3 s1 = seeds[me].xyz;
	float best = 1e9;
	for (int i = 0; i < 8; i++) {
		if (i >= n_seeds || i == me) { continue; }
		vec3 s2 = seeds[i].xyz;
		vec3 dv = s2 - s1;
		float l = length(dv);
		if (l < 1e-4) { continue; }
		float d = abs(dot(vL - 0.5 * (s1 + s2), dv / l));
		best = min(best, d);
	}
	float x = best / width;
	float fl = flick(0.55 + 0.9 * vnoise(vec2(dot(vL, vec3(3.1, 1.7, 2.3)), scene_t * 3.0)), scene_t, 1.0);
	if (!FRONT_FACING) {
		float n = fbm(vL.xy * 1.3 + vL.zx * 0.9);
		// embers only near the break: elsewhere a back face is just the hull's dark inside (r2: glowing specks round the
		// silhouette, where back faces show past the front at grazing angles)
		float near_cut = exp(-x * 1.2);
		float emb = smoothstep(0.62, 0.8, n) * heat * near_cut;
		ALBEDO = vec3(0.012, 0.010, 0.009) * (0.6 + n) + (glow * emb * 1.6 * fl + glow * exp(-x * 3.0) * heat * 1.0) * fx_gain;
		ALPHA = 1.0;
	} else {
		if (x > 3.0 || heat <= 0.01) { discard; }
		float g = exp(-x * x * 1.5);
		vec3 c = mix(vec3(0.9, 0.12, 0.02), vec3(1.0, 0.75, 0.35), clamp(heat * fl - 0.2, 0.0, 1.0));
		ALBEDO = clamp(c * 3.0 * heat * fl * fx_gain, 0.0, 64.0);
		ALPHA = clamp(g * (0.4 + 0.6 * heat), 0.0, 1.0);
	}
}
"""

const CRACKS := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform float t0 = 0.0;
uniform float dur = 1.5;
uniform float scale = 0.5;
uniform vec3 glow = vec3(1.0, 0.45, 0.1);
varying vec3 vL;
float h3(vec3 p) { p = fract(p * 0.3183099 + vec3(0.11, 0.17, 0.13)); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float n3(vec3 x) {
	vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1.0, 0.0, 0.0)), f.x), mix(h3(i + vec3(0.0, 1.0, 0.0)), h3(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(h3(i + vec3(0.0, 0.0, 1.0)), h3(i + vec3(1.0, 0.0, 1.0)), f.x), mix(h3(i + vec3(0.0, 1.0, 1.0)), h3(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}
void vertex() { vL = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float u = clamp((scene_t - t0) / dur, 0.0, 1.0);
	if (u <= 0.0) { discard; }
	vec3 p = vL * scale;
	float r = 1.0 - abs(n3(p) * 2.0 - 1.0);
	float r2 = 1.0 - abs(n3(p * 2.3 + 4.0) * 2.0 - 1.0);
	float crack = smoothstep(1.0 - 0.05 * u, 1.0, r) + smoothstep(1.0 - 0.03 * u, 1.0, r2) * 0.7;
	float fl = flick(0.7 + 0.3 * n3(p * 3.0 + scene_t * 4.0), scene_t, 2.0);
	vec3 c = mix(glow, vec3(1.0, 0.85, 0.6), smoothstep(0.5, 1.0, crack));
	ALBEDO = clamp(c * crack * (1.5 + 4.0 * u) * fl * fx_gain, 0.0, 64.0);
}
"""

const NOISE3 := """
// r5: a better hash (Hoskins' hash13), quintic fades and rotated octaves; the old product hash and cubic fade drew a
// diagonal lattice through the fireballs once their emission amplified the noise (r4 g21: a grid of hard diamonds)
float h31(vec3 p) { p = fract(p * 0.1031); p += dot(p, p.zyx + 31.32); return fract((p.x + p.y) * p.z); }
float vn3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(mix(h31(i), h31(i + vec3(1.0, 0.0, 0.0)), f.x), mix(h31(i + vec3(0.0, 1.0, 0.0)), h31(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(h31(i + vec3(0.0, 0.0, 1.0)), h31(i + vec3(1.0, 0.0, 1.0)), f.x), mix(h31(i + vec3(0.0, 1.0, 1.0)), h31(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}
const mat3 NROT = mat3(vec3(0.00, 0.80, 0.60), vec3(-0.80, 0.36, -0.48), vec3(-0.60, -0.48, 0.64));
float fbm3(vec3 p) { return 0.5 * vn3(p) + 0.25 * vn3(NROT * p * 2.03 + 3.1) + 0.125 * vn3(NROT * NROT * p * 4.07 + 7.7); }
"""

# Raymarched volumes (max): type 0 a fireball rolling into dark smoke, 1 a breach's venting gas plume. A unit box, back
# faces drawn; the depth buffer stops the march at the hulls. P = (age or strength, visibility, seed, density).
const VOL := """
shader_type spatial;
render_mode unshaded, blend_premul_alpha, depth_draw_never, depth_test_disabled, cull_front, shadows_disabled, fog_disabled;
""" + COMMON + NOISE3 + DEPTH + """
uniform float vtype = 0.0;
uniform float t0 = 0.0;
uniform float life = 4.0;
uniform vec4 P = vec4(0.0, 1.0, 0.0, 0.16);
uniform vec3 tint = vec3(1.0, 0.55, 0.2);
uniform vec3 key_dir = vec3(-0.45, -0.70, -0.55);
uniform vec3 key_col = vec3(3.2);
uniform vec3 amb = vec3(0.8);
float field(vec3 pl, float age, inout vec3 em, inout vec3 alb) {
	em = vec3(0.0);
	if (vtype < 0.5) {
		float r = length(pl) * 2.0;
		// the ball grows to a little over half the box, and density fades to nothing before the box's faces, so its noisy
		// edge never meets them (r2: hard straight box edges)
		float rs = 0.2 + 0.42 * (1.0 - exp(-age * 1.6));
		float n = fbm3(pl * 5.0 + vec3(P.z, -age * 0.6, age * 0.3));
		// a finer billow so the fire breaks into lobes and smoke pockets instead of one flat bright disc (r5)
		float nb = vn3(pl * 13.0 + vec3(-age * 0.9, P.z * 2.0, age * 0.5));
		float d = clamp((rs - r) / rs * 1.6 + (n - 0.5) * 1.4 + (nb - 0.5) * 0.4, 0.0, 1.0) * smoothstep(0.98, 0.72, r);
		float temp = clamp((1.0 - r / rs) * 1.3 + (n - 0.5) * 1.2 + (nb - 0.5) * 0.5, 0.0, 1.0) * exp(-age * 1.25);
		em = mix(heatRamp(temp), heatRamp(temp) * tint * 1.4, 0.3) * temp * temp * 10.0 * (0.55 + 0.9 * nb);
		alb = vec3(0.065, 0.058, 0.052) * (0.7 + 0.6 * nb);
		float vis = smoothstep(0.0, 0.15, age) * (1.0 - smoothstep(life - 1.0, life, age));
		return d * d * 3.0 * vis;
	}
	float y = pl.y + 0.5;
	// curl the column: the plume wanders and twists as it rises
	vec2 sway = vec2(fbm3(vec3(y * 2.0 - scene_t * 0.7, P.z, 1.0)) - 0.5, fbm3(vec3(y * 2.0 - scene_t * 0.6, P.z, 7.0)) - 0.5) * y * 0.5;
	vec2 xz = pl.xz - sway;
	float rad = 0.05 + 0.42 * y;
	float q = length(xz) / rad;
	float n = fbm3(vec3(xz.x * 5.0, pl.y * 7.0 - scene_t * 2.8, xz.y * 5.0) + P.z);
	float n2 = fbm3(vec3(xz.x * 11.0, pl.y * 13.0 - scene_t * 4.0, xz.y * 11.0) + P.z * 2.0);
	float puff = 0.6 + 0.4 * sin(scene_t * 4.0 - y * 9.0 + P.z);
	em = vec3(1.0, 0.45, 0.12) * exp(-y * 14.0) * 2.0;
	alb = mix(vec3(0.42, 0.38, 0.34), vec3(0.3, 0.33, 0.38), smoothstep(0.0, 0.5, y));
	float body = (1.0 - q) * 1.3 + (n - 0.5) * 1.8 + (n2 - 0.5) * 0.9 - 0.35;
	float fade = (1.0 - smoothstep(0.35, 1.0, y)) * smoothstep(0.0, 0.04, y);
	return max(0.0, body) * fade * puff * P.x * mix(1.0, 0.45, y);
}
varying vec3 vW;
void vertex() { vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float age = scene_t - t0;
	if (vtype < 0.5 && (age < 0.0 || age > life)) { discard; }
	vec3 cam = CAMERA_POSITION_WORLD;
	vec3 rd = normalize(vW - cam);
	mat4 inv_m = inverse(MODEL_MATRIX);
	vec3 roL = (inv_m * vec4(cam, 1.0)).xyz;
	vec3 rdL = (inv_m * vec4(rd, 0.0)).xyz;
	vec3 inv = 1.0 / (abs(rdL) + 1e-6) * sign(rdL + 1e-12);
	vec3 ta = (vec3(-0.5) - roL) * inv;
	vec3 tb = (vec3(0.5) - roL) * inv;
	vec3 tmn = min(ta, tb);
	vec3 tmx = max(ta, tb);
	float t0r = max(max(max(tmn.x, tmn.y), tmn.z), 0.0);
	float t1r = min(min(tmx.x, tmx.y), tmx.z);
	vec3 svp = scene_view_pos(SCREEN_UV, INV_PROJECTION_MATRIX);
	t1r = min(t1r, length(svp));
	if (t1r <= t0r) { discard; }
	float dt = (t1r - t0r) / 24.0;
	float t = t0r + dt * h21(FRAGCOORD.xy + fract(scene_t * 7.0));
	vec3 lkL = (inv_m * vec4(-key_dir, 0.0)).xyz;
	vec3 col = vec3(0.0);
	float Tr = 1.0;
	float sl = 0.12;
	vec3 em = vec3(0.0);
	vec3 alb = vec3(0.0);
	vec3 em2 = vec3(0.0);
	vec3 alb2 = vec3(0.0);
	float scale = length(MODEL_MATRIX[0].xyz);
	for (int i = 0; i < 24; i++) {
		vec3 pl = roL + rdL * t;
		float de = field(pl, age, em, alb);
		if (de > 0.002) {
			float ds = field(pl + normalize(lkL) * sl, age, em2, alb2);
			float lit = 0.3 + 0.7 * exp(-ds * 2.5);
			float a = 1.0 - exp(-de * P.w * dt * 44.0 / max(scale, 1e-3));
			col += Tr * a * (alb * (key_col * lit * 0.55 + amb * 0.6) + em * fx_gain);
			Tr *= 1.0 - a;
			if (Tr < 0.02) { break; }
		}
		t += dt;
	}
	ALBEDO = clamp(col, 0.0, 512.0);
	ALPHA = clamp(1.0 - Tr, 0.0, 1.0);
}
"""

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
