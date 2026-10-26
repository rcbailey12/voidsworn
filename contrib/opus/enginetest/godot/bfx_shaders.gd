extends RefCounted
# Shader code for bfx.gd: a port of the Babylon half's effect shaders (../babylon/index.html, "Effects") to Godot's
# shading language, so both engines draw the same effects from the same particle data. Same noise, same kinds, same
# colours and curves; what changes is only the Godot side of things (built-in names, the depth texture, premultiplied
# alpha through blend_premul_alpha, lit shards and plates through Godot's own lights).

const COMMON := """
global uniform float scene_t;
// Godot's ACES curve applies an exposure bias of 1.8 that Babylon's does not (the hulls' lights are set for it);
// the effects' own colours are scaled by its inverse so they come out as bright as in the Babylon half.
const float FXK = 0.5556;
float spow(float b, float e) { return pow(max(b, 0.0), e); }
vec3 snorm(vec3 v) { float l = length(v); return l > 1e-6 ? v / l : vec3(0.0, 1.0, 0.0); }
float drift(float t) { return mod(3.0 * t + 20.0, 40.0) - 20.0; }
float shipFade(float t) { float ph = mod(3.0 * t + 20.0, 40.0) / 3.0; return clamp(min(ph, 13.333333 - ph), 0.0, 1.0); }
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
vec3 heatRamp(float h) {
	vec3 c = mix(vec3(0.45, 0.04, 0.01), vec3(1.0, 0.32, 0.04), smoothstep(0.0, 0.3, h));
	c = mix(c, vec3(1.0, 0.75, 0.35), smoothstep(0.3, 0.65, h));
	return mix(c, vec3(1.0, 0.96, 0.85), smoothstep(0.65, 1.0, h));
}
"""

# Linear view depth of the opaque scene at this pixel (soft particles, decals and volumes use it).
const DEPTH := """
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
vec3 scene_view_pos(vec2 suv, mat4 inv_proj) {
	float d = texture(depth_tex, suv).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(suv, d) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(suv * 2.0 - 1.0, d);
#endif
	vec4 v = inv_proj * vec4(ndc, 1.0);
	return v.xyz / v.w;
}
"""

const HIDE := "POSITION = vec4(2.0, 2.0, 2.0, 1.0);"

# a0 = CUSTOM0 (pos, tStart), a1 = CUSTOM1 (vel, life), a2 = CUSTOM2 (colour, intensity), a3 = CUSTOM3 (size0, size1,
# kind, seed), a4 = (UV, UV2) (period, drift, drag, spin). kinds: 0 flash, 1 flame, 2 fireball core, 3 smoke, 4 engine
# core, 5 squib, 7 vent gas, 8 soot, 11 sputtering core, 12 beam charge, 13 beam impact flare
const SPRITE := """
shader_type spatial;
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform float gate = 1.0;
varying vec2 vUv;
varying vec4 vCol;
varying vec4 vInfo;
#ifdef SOFT
""" + DEPTH + """
#endif
void vertex() {
	vec4 a0 = CUSTOM0; vec4 a1 = CUSTOM1; vec4 a2 = CUSTOM2; vec4 a3 = CUSTOM3; vec4 a4 = vec4(UV, UV2);
	float a = scene_t - a0.w;
	float age = mod(a, max(a4.x, 1e-3));
	float life = a1.w;
	vUv = vec2(0.0); vCol = vec4(0.0); vInfo = vec4(0.0);
	if (a < 0.0 || age >= life || gate <= 0.0) {
		""" + HIDE + """
	} else {
		float t = age / life;
		int k = int(a3.z + 0.5);
		float g = t;
		if (k == 1) { g = 1.0 - spow(1.0 - t, 2.2); }
		else if (k == 2 || k == 5) { g = sqrt(t); }
		else if (k == 3 || k == 7 || k == 8) { g = 1.0 - spow(1.0 - t, 1.6); }
		else if (k == 4 || k == 11 || k == 13) { g = 0.0; }
		else if (k == 12) { g = t * t; }
		float size = mix(a3.x, a3.y, g);
		float dr = a4.z;
		vec3 disp = dr > 0.0 ? a1.xyz * (1.0 - exp(-dr * age)) / dr : a1.xyz * age;
		vec3 c = (MODEL_MATRIX * vec4(a0.xyz + disp, 1.0)).xyz;
		c.x += a4.y * (drift(scene_t - age) + 3.0 * age);
		float ang = a3.w * 6.2831853 + age * a4.w;
		float cs = cos(ang);
		float sn = sin(ang);
		vec2 q = vec2(cs * VERTEX.x - sn * VERTEX.y, sn * VERTEX.x + cs * VERTEX.y);
		vec4 vp = VIEW_MATRIX * vec4(c, 1.0);
		vp.xy += q * size;
		POSITION = PROJECTION_MATRIX * vp;
		vUv = VERTEX.xy * 2.0;
		vCol = vec4(a2.rgb, a2.a * gate * mix(1.0, shipFade(scene_t), a4.y));
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
	} else if (k == 7) {
		float n = fbm(p * 1.6 + vec2(seed * 9.1, seed * 4.3) + vec2(0.0, -age * 1.4));
		float dens = (1.0 - r) * 1.1 + (n - 0.5) * 1.3;
		float m = smoothstep(0.1, 0.75, dens);
		alpha = m * I * smoothstep(0.0, 0.08, t) * spow(1.0 - t, 1.5);
		base = vCol.rgb * (0.8 + 0.4 * n);
	} else if (k == 4 || k == 11) {
		float fl = 0.85 + 0.15 * vnoise(vec2(scene_t * 31.0, seed * 9.0));
		if (k == 11) { fl *= cough(scene_t, seed); }
		add = (vCol.rgb * exp(-r * r * 4.0) + vec3(1.0, 0.95, 0.8) * exp(-r * r * 14.0) * 1.6) * I * fl;
	} else if (k == 5) {
		float f = (1.0 - t) * (1.0 - t) * I;
		add = vec3(1.0, 0.6, 0.25) * exp(-r * r * 6.0) * f + vec3(exp(-r * r * 30.0)) * f + vec3(1.0, 0.7, 0.4) * star * f * 0.6;
	} else if (k == 12) {
		float f = t * t * I;
		float ray = spow(abs(cos(atan(p.y, p.x) * 3.0 + age * 9.0)), 24.0) * (1.0 - r);
		add = vCol.rgb * exp(-r * r * 4.0) * f + vec3(exp(-r * r * 25.0)) * f * 1.5 + vCol.rgb * f * 0.8 * ray;
	} else if (k == 13) {
		float fl = 0.8 + 0.2 * vnoise(vec2(scene_t * 40.0, seed));
		float life = age / max(t, 1e-3);
		float env = smoothstep(0.0, 0.05, age) * (1.0 - smoothstep(life - 0.15, life, age));
		add = (vCol.rgb * exp(-r * r * 3.0) + vec3(exp(-r * r * 12.0)) * 1.5 + vCol.rgb * star * 0.7) * I * fl * env;
	}
	float win = 1.0 - r * r;
	add *= win * win;
#ifdef SOFT
	float scene_z = -scene_view_pos(SCREEN_UV, INV_PROJECTION_MATRIX).z;
	float soft = clamp((scene_z + VERTEX.z) / 0.6, 0.0, 1.0);
	add *= soft;
	alpha *= soft;
#endif
	ALBEDO = clamp(base * alpha + add, 0.0, 512.0) * FXK;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
"""

# a3 = (length or blur seconds, width, drag, kind); a4 = (period, drift, 0, 0). kinds: 0 tracer, 1 spark, 3 flame tongue
const STREAK := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
varying vec2 vUv;
varying vec3 vCol;
varying float vK;
void vertex() {
	vec4 a0 = CUSTOM0; vec4 a1 = CUSTOM1; vec4 a2 = CUSTOM2; vec4 a3 = CUSTOM3; vec4 a4 = vec4(UV, UV2);
	float a = scene_t - a0.w;
	float age = mod(a, max(a4.x, 1e-3));
	float life = a1.w;
	vUv = vec2(0.0); vCol = vec3(0.0); vK = 0.0;
	if (a < 0.0 || age >= life) {
		""" + HIDE + """
	} else {
		vec3 v = a1.xyz;
		float sp = max(length(v), 1e-4);
		vec3 dir = v / sp;
		float dr = a3.z;
		int k = int(a3.w + 0.5);
		vec3 head; vec3 tail; float fade = 1.0; float u = age / life;
		if (k == 1) {
			float e = exp(-dr * age);
			head = a0.xyz + v * (1.0 - e) / max(dr, 1e-4);
			float L = max(a3.x * sp * e, 0.1);
			tail = head - dir * L;
			fade = (1.0 - u) * (1.0 - u);
		} else if (k == 3) {
			tail = a0.xyz;
			head = a0.xyz + dir * a3.x * (0.35 + 0.65 * sqrt(u));
			fade = spow(1.0 - u, 1.5);
		} else {
			float tr = sp * age;
			head = a0.xyz + dir * tr;
			tail = head - dir * min(a3.x, tr);
		}
		float off = a4.y * (drift(scene_t - age) + 3.0 * age);
		head.x += off;
		tail.x += off;
		vec3 mid = 0.5 * (head + tail);
		vec3 side = snorm(cross(dir, CAMERA_POSITION_WORLD - mid));
		vec3 p = mix(tail, head, VERTEX.x) + side * VERTEX.y * a3.y;
		vUv = VERTEX.xy;
		vK = a3.w;
		vCol = a2.rgb * a2.a * fade * mix(1.0, shipFade(scene_t), a4.y);
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
		c = vCol * (glow + core) * (along + headB) + vec3(core) * length(vCol) * 0.35 * (along + headB);
	} else if (k == 3) {
		along = (1.0 - vUv.x) * smoothstep(0.0, 0.08, vUv.x) + 0.15;
		float w = 1.0 - vUv.x * 0.6;
		float cc = exp(-x * x * 6.0 / (w * w));
		c = mix(vCol, vec3(length(vCol)) * vec3(1.0, 0.9, 0.75), (1.0 - vUv.x) * 0.6) * cc * along;
	} else {
		along = smoothstep(0.0, 0.45, vUv.x) * (1.0 - smoothstep(0.9, 1.0, vUv.x) * 0.7);
		c = vCol * (glow + core) * along + vec3(core * core) * length(vCol) * 0.25 * along;
	}
	ALBEDO = clamp(c, 0.0, 512.0) * FXK;
}
"""

# Oriented rings: smoke rings (kind 0, alpha) and shockwaves (kind 1, additive), premultiplied.
# a1 = (normal, life); a3 = (size0, size1, kind, seed); a4 = (period, drift, speed, drag)
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
	float age = mod(a, max(a4.x, 1e-3));
	float life = a1.w;
	vUv = vec2(0.0); vCol = vec4(0.0); vInfo = vec4(0.0);
	if (a < 0.0 || age >= life) {
		""" + HIDE + """
	} else {
		float t = age / life;
		vec3 n = snorm(a1.xyz);
		float dr = a4.w;
		float tr = dr > 0.0 ? a4.z * (1.0 - exp(-dr * age)) / dr : a4.z * age;
		vec3 c = a0.xyz + n * tr;
		c.x += a4.y * (drift(scene_t - age) + 3.0 * age);
		vec3 up = abs(n.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
		vec3 t1 = snorm(cross(n, up));
		vec3 t2 = cross(n, t1);
		float g = a3.z < 0.5 ? 1.0 - spow(1.0 - t, 2.0) : 1.0 - spow(1.0 - t, 3.0);
		float size = mix(a3.x, a3.y, g);
		vec3 p = c + (t1 * VERTEX.x + t2 * VERTEX.y) * size;
		POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(p, 1.0));
		vUv = VERTEX.xy * 2.0;
		vCol = vec4(a2.rgb, a2.a * mix(1.0, shipFade(scene_t), a4.y));
		vInfo = vec4(t, a3.z, a3.w, age);
	}
}
void fragment() {
	float t = vInfo.x; float seed = vInfo.z; float age = vInfo.w;
	vec2 p = vUv;
	float r = length(p);
	if (r > 1.0) { discard; }
	float ang = atan(p.y, p.x);
	vec3 add = vec3(0.0); vec3 base = vec3(0.0); float alpha = 0.0;
	if (vInfo.y < 0.5) {
		float n = fbm(vec2(ang * 1.6 + seed * 7.0, r * 3.0 + age * 0.3));
		float w = 0.15 + 0.12 * t;
		float rq = (r - 0.62) / w;
		float rg = exp(-rq * rq);
		float dens = rg * (0.55 + 0.9 * n);
		alpha = clamp(dens, 0.0, 1.0) * vCol.a * smoothstep(0.0, 0.05, t) * spow(1.0 - t, 1.4);
		base = vCol.rgb * (0.75 + 0.5 * n);
		add = vec3(1.0, 0.45, 0.1) * spow(1.0 - t, 10.0) * alpha * 2.0;
	} else {
		float d1 = (r - 0.95) / 0.018;
		float d2 = (r - 0.88) / 0.06;
		float rg = exp(-d1 * d1) * 1.6 + exp(-d2 * d2) * 0.2;
		float n = 0.4 + 1.0 * fbm(vec2(ang * 5.0 + seed, t * 3.0));
		vec3 col = mix(vec3(1.0, 0.85, 0.65), vCol.rgb, sqrt(t));
		add = col * rg * n * spow(1.0 - t, 1.5) * vCol.a;
	}
	ALBEDO = clamp(base * alpha + add, 0.0, 512.0) * FXK;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
"""

# Ribbons: engine plumes, exhaust trails and beams (additive). VERTEX = (s along 0..1, side -0.5..0.5);
# a0 = (origin, kind); a1 = (dir, length); a2 = (colour, intensity); a3 = (width0, width1, seed, 0); a4 = (tStart, life, period, 0)
# kinds: 0 plume, 1 trail, 2 beam, 3 sputter plume, 4 sputter trail
const RIBBON := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
varying vec4 vCol;
varying vec3 vInfo;
varying vec2 vInfo2;
varying float vSide;
varying vec2 vAge;
void vertex() {
	vec4 a0 = CUSTOM0; vec4 a1 = CUSTOM1; vec4 a2 = CUSTOM2; vec4 a3 = CUSTOM3; vec4 a4 = vec4(UV, UV2);
	float a = scene_t - a4.x;
	float age = mod(a, max(a4.z, 1e-3));
	vCol = vec4(0.0); vInfo = vec3(0.0); vInfo2 = vec2(0.0); vSide = 0.0; vAge = vec2(0.0);
	if (a < 0.0 || age >= a4.y) {
		""" + HIDE + """
	} else {
		float s = VERTEX.x;
		int k = int(a0.w + 0.5);
		vec3 dir = a1.xyz;
		float seed = a3.z;
		vec3 p = a0.xyz + dir * s * a1.w;
		p.x += drift(scene_t);
		vec3 up = abs(dir.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
		vec3 n1 = snorm(cross(dir, up));
		vec3 n2 = cross(n1, dir);
		if (k == 1 || k == 4) {
			p += (n1 * sin(s * 7.0 - scene_t * 1.3 + seed * 6.0) * 0.9 + n2 * sin(s * 5.0 - scene_t * 0.9 + seed * 3.0) * 0.7) * s * s * 2.2;
		}
		if (k == 0 || k == 3) {
			p += (n1 * (vnoise(vec2(s * 6.0 - scene_t * 18.0, seed)) - 0.5) + n2 * (vnoise(vec2(s * 6.0 - scene_t * 17.0, seed + 3.0)) - 0.5)) * s * a3.x * 0.5;
		}
		float w = mix(a3.x, a3.y, s);
		if (k == 2) { w *= 0.92 + 0.08 * sin(scene_t * 90.0 + s * 40.0); }
		vec3 side = snorm(cross(dir, CAMERA_POSITION_WORLD - p));
		p += side * VERTEX.y * w;
		vInfo2 = vec2(a1.w, w);
		POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(p, 1.0));
		vSide = VERTEX.y * 2.0;
		vCol = vec4(a2.rgb, a2.a * shipFade(scene_t));
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
		float fl = 0.85 + 0.15 * vnoise(vec2(scene_t * 27.0, seed * 5.0));
		if (k == 3) { fl *= cough(scene_t, seed); }
		vec3 hot = mix(vec3(1.0, 0.95, 0.82), vCol.rgb, smoothstep(0.0, 0.3, s));
		c = hot * core * shape * (0.3 + 1.1 * br) * fl * vCol.a;
	} else if (k == 1 || k == 4) {
		float n = fbm(vec2(s * 14.0 - scene_t * 0.6, vSide * 1.2 + seed * 3.0));
		float n2 = fbm(vec2(s * vInfo2.x * 0.18 - scene_t * 0.5, vSide * vInfo2.y * 0.25 + seed * 3.0));
		n = 0.5 * n + 0.5 * n2;
		float across = exp(-x * x * 2.2);
		float fade = spow(1.0 - s, 1.8) * smoothstep(0.0, 0.05, s);
		vec3 col = mix(vCol.rgb, vec3(0.30, 0.38, 0.60), smoothstep(0.0, 0.55, s));
		if (k == 4) { col = mix(col, vec3(0.35, 0.25, 0.18), 0.5) * (0.5 + 0.5 * cough(scene_t - s * 3.0, seed)); }
		c = col * across * fade * smoothstep(0.25, 0.75, n + 0.15) * 1.4 * vCol.a;
	} else {
		float env = smoothstep(0.0, 0.05, age) * (1.0 - smoothstep(life - 0.12, life, age));
		float sh = 0.7 + 0.3 * vnoise(vec2(s * 120.0 - scene_t * 70.0, 0.0));
		float core = exp(-x * x * 60.0) * 5.0;
		float glow = exp(-x * x * 6.0) * 1.0 * sh + exp(-x * x * 1.6) * 0.15;
		float ends = smoothstep(0.0, 0.01, s) * (1.0 - smoothstep(0.985, 1.0, s));
		c = (vec3(1.0, 0.97, 0.92) * core + vCol.rgb * glow) * env * ends * vCol.a;
	}
	ALBEDO = clamp(c, 0.0, 512.0) * FXK;
}
"""

# Debris shards: tumbling 3D chips, lit by Godot's own lights (key, fill, every event light), glowing hot at first.
# a1 = (vel, life); a2 = (spin axis, spin rate); a3 = (size, period, drift, drag); a4 = (heat, seed, 0, 0)
const SHARD := """
shader_type spatial;
render_mode cull_back;
""" + COMMON + """
varying float vHeat;
varying float vSeed;
vec3 rotA(vec3 v, vec3 k, float an) { float c = cos(an); float s = sin(an); return v * c + cross(k, v) * s + k * dot(k, v) * (1.0 - c); }
void vertex() {
	vec4 a0 = CUSTOM0; vec4 a1 = CUSTOM1; vec4 a2 = CUSTOM2; vec4 a3 = CUSTOM3; vec4 a4 = vec4(UV, UV2);
	float a = scene_t - a0.w;
	float age = mod(a, max(a3.y, 1e-3));
	float life = a1.w;
	vHeat = 0.0; vSeed = a4.y;
	if (a < 0.0 || age >= life) {
		VERTEX = vec3(0.0, -5000.0, 0.0);
	} else {
		float t = age / life;
		float sc = a3.x * (1.0 - smoothstep(0.85, 1.0, t)) * mix(1.0, shipFade(scene_t), a3.z);
		vec3 k = snorm(a2.xyz);
		float an = age * a2.w + a4.y * 6.2831853;
		float dr = a3.w;
		vec3 disp = dr > 0.0 ? a1.xyz * (1.0 - exp(-dr * age)) / dr : a1.xyz * age;
		vec3 p = a0.xyz + disp + rotA(VERTEX, k, an) * sc;
		p.x += a3.z * (drift(scene_t - age) + 3.0 * age);
		NORMAL = rotA(NORMAL, k, an);
		VERTEX = p;
		vHeat = a4.x * exp(-age * 6.0);
	}
}
void fragment() {
	ALBEDO = vec3(0.032, 0.032, 0.036) * (0.6 + 0.9 * fract(vSeed * 17.3));
	METALLIC = 0.5;
	ROUGHNESS = 0.45;
	EMISSION = vec3(1.0, 0.33, 0.06) * vHeat * 2.0 * FXK;
}
"""

# Shield: the whole bubble near the hit lights up (a fresnel rim in the faction colour), a bright hit core and three
# ripple rings run out from the impact over 0.6 s. Additive. Corsair's flickers and breaks into patches.
const SHIELD := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform float t0 = 0.0;
uniform float patchy = 0.0;
uniform vec3 hit_off = vec3(0.0);
uniform vec3 col = vec3(1.0);
uniform vec3 rad = vec3(1.0);
varying vec3 vW;
varying vec3 vN;
void vertex() {
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vN = snorm(NORMAL / rad);
}
void fragment() {
	float a = scene_t - t0;
	float age = mod(a, 4.0);
	if (a < 0.0 || age > 0.6) { discard; }
	float f = age / 0.6;
	float fade = (1.0 - f) * (1.0 - f) * smoothstep(0.0, 0.025, age);
	vec3 hitW = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz + hit_off;
	float d = length(vW - hitW);
	float mask = 1.0 - smoothstep(5.0, 15.0, d);
	float hd = d / 1.1;
	float hit = exp(-hd * hd) * 4.0 * (1.0 - f);
	float rg = 0.0;
	for (int i = 0; i < 3; i++) {
		float ai = age - float(i) * 0.08;
		if (ai > 0.0) { float rd = (d - ai * 22.0) / (0.6 + ai * 2.0); rg += exp(-rd * rd) * (i == 0 ? 1.7 : 0.8); }
	}
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	float fres = spow(1.0 - abs(dot(normalize(vN), V)), 5.0);
	float cells = 0.7 + 0.6 * fbm(vW.xy * 0.9 + vW.zx * 0.6);
	float I = (hit + rg * cells * mask + (0.004 + 1.4 * fres) * cells * mask) * fade;
	if (patchy > 0.5) {
		float fl = step(0.3, vnoise(vec2(scene_t * 28.0, 3.0)));
		float pa = smoothstep(0.35, 0.65, fbm(vW.xz * 0.35 + vW.y * 0.2 + scene_t * 0.7));
		I *= mix(0.25, 1.0, fl) * mix(0.1, 1.0, pa);
	}
	if (I < 0.002) { discard; }
	ALBEDO = clamp(col * I, 0.0, 512.0) * FXK;
}
"""

# Breach decal: torn hole, glowing jagged edge, charred ring and soot, projected onto the hull from the depth buffer
# inside a box (Babylon builds a projected decal mesh; this is the same picture). Box axes: x and z span the decal, y is
# the hull normal. POM (rich and max): the cavity as a height field, ray-marched.
const DECAL := """
shader_type spatial;
render_mode unshaded, blend_premul_alpha, depth_draw_never, depth_test_disabled, cull_front, shadows_disabled, fog_disabled;
""" + COMMON + DEPTH + """
uniform float seed = 0.0;
uniform float fade = 1.0;
float holeR(float ang) { return 0.36 + 0.16 * (fbm(vec2(cos(ang), sin(ang)) * 2.2 + seed * 5.0) - 0.5) * 2.0 + 0.035 * sin(ang * 11.0 + seed); }
#ifdef POM
const float DEP = 0.22;
float cav(vec2 uv) {
	vec2 p = uv * 2.0 - 1.0;
	float r = length(p);
	float R = holeR(atan(p.y, p.x));
	float wall = smoothstep(R + 0.005, R - 0.05, r);
	float inner = smoothstep(R - 0.04, R - 0.14, r);
	float rib = smoothstep(0.86, 1.0, abs(sin(p.x * 7.0 + seed))) * 0.55 + smoothstep(0.9, 1.0, abs(sin(p.y * 5.0 + seed * 2.0))) * 0.4;
	return wall * DEP * (0.72 + 0.28 * fbm(p * 5.0 + seed) - rib * inner * 0.7);
}
#endif
void fragment() {
	vec3 vpos = scene_view_pos(SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 wpos = (INV_VIEW_MATRIX * vec4(vpos, 1.0)).xyz;
	mat4 inv_m = inverse(MODEL_MATRIX);
	vec3 lp = (inv_m * vec4(wpos, 1.0)).xyz;
	if (abs(lp.x) > 0.5 || abs(lp.y) > 0.5 || abs(lp.z) > 0.5) { discard; }
	vec3 uN = normalize(MODEL_MATRIX[1].xyz);
	vec3 T = normalize(MODEL_MATRIX[0].xyz);
	vec3 Bt = normalize(MODEL_MATRIX[2].xyz);
	float face_fade = 1.0;
	vec2 vUv = lp.xz + 0.5;
	float fl = 0.8 + 0.2 * vnoise(vec2(scene_t * 9.0, seed)) * vnoise(vec2(scene_t * 23.0, seed + 2.0)) * 2.0;
	vec2 uvh = vUv;
	float dh = 0.0;
	vec3 V2 = normalize(CAMERA_POSITION_WORLD - wpos);
#ifdef POM
	vec3 Vt = vec3(dot(V2, T), dot(V2, Bt), dot(V2, uN));
	vec2 stepUv = -Vt.xy / max(Vt.z, 0.2) * (DEP / 28.0);
	float c = cav(uvh);
	for (int i = 0; i < 28; i++) { if (dh >= c) { break; } uvh += stepUv; dh += DEP / 28.0; c = cav(uvh); }
#endif
	vec2 p = uvh * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float R = holeR(ang);
	float e = r - R;
	vec3 add = vec3(0.0); vec3 base = vec3(0.0); float alpha = 0.0;
	vec3 tv = V2 - uN * dot(V2, uN);
	vec2 par = vec2(dot(tv, T), dot(tv, Bt)) * 0.35;
	bool done = false;
#ifdef POM
	if (dh > 0.004) {
		float dn = clamp(dh / DEP, 0.0, 1.0);
		float emb = spow(fbm(p * 6.0 + seed + vec2(0.0, scene_t * 0.2)), 3.0);
		base = vec3(0.025, 0.022, 0.02) * (0.5 + 0.9 * fbm(p * 11.0)) * (1.0 - 0.6 * dn);
		alpha = 1.0;
		add = (vec3(1.0, 0.25, 0.04) * (emb * 2.6 * dn + 0.12 * dn * dn) + vec3(1.0, 0.5, 0.15) * exp(-dn * 12.0) * 0.6) * fl;
		done = true;
	}
#endif
	if (!done) {
		if (e < 0.0) {
			vec2 q = p - par;
			float deep = smoothstep(0.0, -0.25, e);
			float emb = spow(fbm(q * 5.0 + seed + vec2(0.0, scene_t * 0.2)), 4.0);
			float struts = smoothstep(0.92, 1.0, abs(sin(q.x * 9.0 + seed)));
			base = vec3(0.012, 0.010, 0.010) * (1.0 - deep * 0.6);
			alpha = 1.0;
			add = (vec3(1.0, 0.22, 0.03) * emb * 1.2 * fl + vec3(1.0, 0.4, 0.08) * struts * 0.12 * (1.0 - deep)) * deep;
		} else if (e < 0.05) {
			float h = 1.0 - e / 0.05;
			base = vec3(0.02);
			alpha = 1.0;
			add = mix(vec3(1.0, 0.3, 0.04) * 2.0, vec3(1.0, 0.8, 0.55) * 4.5, h * h) * h * fl;
		} else {
			float n = fbm(p * 4.0 + seed * 3.0);
			float charred = 1.0 - smoothstep(0.05, 0.2 + 0.1 * n, e);
			float crack = smoothstep(0.9, 0.98, 1.0 - abs(fbm(p * 7.0 + seed) * 2.0 - 1.0)) * (1.0 - smoothstep(0.05, 0.12, e));
			float soot = (1.0 - smoothstep(0.08, 0.62, e)) * (0.7 + 0.6 * n);
			alpha = clamp(max(charred, soot * 0.9), 0.0, 1.0);
			base = mix(vec3(0.03, 0.022, 0.018), vec3(0.015, 0.012, 0.01), charred);
			add = vec3(1.0, 0.3, 0.05) * crack * 0.8 * fl;
		}
	}
	float rv = length(vUv * 2.0 - 1.0);
	float edgeFade = (1.0 - smoothstep(0.85, 1.0, rv)) * face_fade;
	alpha *= edgeFade * fade;
	add *= edgeFade * fade;
	ALBEDO = clamp(base * alpha + add, 0.0, 512.0) * FXK;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
"""

# Torn plates bent outward around the hole: dark metal lit by Godot's lights, glowing hot toward the torn tip.
const PETAL := """
shader_type spatial;
render_mode cull_disabled;
""" + COMMON + """
uniform float seed = 0.0;
void fragment() {
	float fl = 0.75 + 0.25 * vnoise(vec2(scene_t * 11.0, seed + UV.x * 3.0));
	ALBEDO = vec3(0.03, 0.028, 0.026);
	METALLIC = 0.6;
	ROUGHNESS = 0.5;
	EMISSION = vec3(1.0, 0.35, 0.06) * spow(1.0 - UV.y, 6.0) * 4.0 * fl * FXK;
}
"""

# The destruction chunks' burning break: an additive pass over each chunk that glows along the cut planes it borders.
# Planes in the source mesh's own units: x - (a + b y + c z) = 0.
const CHUNK_EDGE := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + COMMON + """
uniform vec3 cen = vec3(0.0);
uniform float heat = 0.0;
uniform float width = 0.012;
uniform vec4 pl0 = vec4(0.0);
uniform vec4 pl1 = vec4(0.0);
uniform vec4 pl2 = vec4(0.0);
varying vec3 vL;
float pd(vec4 pl, vec3 q) { return pl.w > 0.5 ? abs(q.x - (pl.x + pl.y * q.y + pl.z * q.z)) / sqrt(1.0 + pl.y * pl.y + pl.z * pl.z) : 1e3; }
void vertex() { vL = VERTEX - cen; }
void fragment() {
	if (heat <= 0.0) { discard; }
	float d = min(pd(pl0, vL), min(pd(pl1, vL), pd(pl2, vL)));
	float x = d / width;
	if (x > 3.0) { discard; }
	float fl = 0.55 + 0.9 * vnoise(vec2(dot(vL, vec3(31.0, 17.0, 23.0)), scene_t * 3.0));
	vec3 c = mix(vec3(0.9, 0.12, 0.02), vec3(1.0, 0.65, 0.25), clamp(heat * fl - 0.2, 0.0, 1.0));
	ALBEDO = clamp(c * exp(-x * x * 1.5) * fl * heat * 3.0, 0.0, 512.0) * FXK;
}
"""

# Raymarched volumes (rich and max): type 0 the destruction fireball and smoke, 1 a breach's venting plume, 2 a
# broadside's smoke rings. A unit box; back faces drawn, the depth buffer stops the march at the hulls.
const NOISE3 := """
float h31(vec3 p) { p = fract(p * 0.3183099 + vec3(0.11, 0.17, 0.13)); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float vn3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h31(i), h31(i + vec3(1.0, 0.0, 0.0)), f.x), mix(h31(i + vec3(0.0, 1.0, 0.0)), h31(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(h31(i + vec3(0.0, 0.0, 1.0)), h31(i + vec3(1.0, 0.0, 1.0)), f.x), mix(h31(i + vec3(0.0, 1.0, 1.0)), h31(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}
float fbm3(vec3 p) { return 0.5 * vn3(p) + 0.25 * vn3(p * 2.03 + 3.1) + 0.125 * vn3(p * 4.07 + 7.7); }
"""
const VOL := """
shader_type spatial;
render_mode unshaded, blend_premul_alpha, depth_draw_never, depth_test_disabled, cull_front, shadows_disabled, fog_disabled;
""" + COMMON + NOISE3 + DEPTH + """
uniform float vtype = 0.0;
uniform vec4 P = vec4(0.0);
uniform vec3 dir = vec3(0.0, 0.0, 1.0);
uniform float dx = 0.0;
uniform vec3 g0 = vec3(0.0);
uniform vec3 g1 = vec3(0.0);
uniform vec3 g2 = vec3(0.0);
uniform vec3 g3 = vec3(0.0);
uniform vec3 key_dir = vec3(0.0, -1.0, 0.0);
uniform vec3 key_col = vec3(1.0);
uniform vec3 amb = vec3(0.25);
varying vec3 vW;
float smoke_ring(vec3 pw, vec3 G, float k, inout vec3 em) {
	float a = scene_t - (P.x + k * 0.08 + 0.02);
	float age = mod(a, 4.0);
	if (a < 0.0 || age > 2.0) { return 0.0; }
	vec3 c = G + vec3(dx, 0.0, 0.0) + dir * (4.0 * (1.0 - exp(-1.6 * age)) / 1.6);
	float R = 0.3 + 1.4 * (1.0 - exp(-age * 2.5));
	float w = 0.7 + 1.5 * sqrt(age);
	vec3 q = pw - c;
	float h = dot(q, dir);
	float rr = length(q - dir * h);
	float dd = (rr - R) * (rr - R) * 0.6 + h * h * 1.4;
	float dk = exp(-dd / (w * w)) * spow(1.0 - age / 2.0, 1.6) / (1.0 + age);
	em += vec3(1.0, 0.45, 0.1) * dk * max(0.0, 1.0 - age / 0.12) * 6.0;
	return dk;
}
float field(vec3 pw, vec3 pl, inout vec3 em, inout vec3 alb) {
	em = vec3(0.0);
	if (vtype < 0.5) {
		float age = P.x;
		float r = length(pl) * 2.0;
		float rs = 0.25 + 0.6 * (1.0 - exp(-age * 1.6));
		float n = fbm3(pl * 5.0 + vec3(0.0, -age * 0.6, age * 0.3));
		float d = clamp((rs - r) / rs * 1.6 + (n - 0.5) * 1.4, 0.0, 1.0);
		float temp = clamp((1.0 - r / rs) * 1.4 + (n - 0.5), 0.0, 1.0) * exp(-age * 1.1);
		em = heatRamp(temp) * temp * temp * 14.0;
		alb = vec3(0.05, 0.045, 0.04);
		return d * d * 3.0 * P.y;
	}
	if (vtype < 1.5) {
		float y = pl.y + 0.5;
		float rad = 0.12 + 0.38 * y;
		float q = length(pl.xz) / rad;
		float n = fbm3(vec3(pl.x * 4.0, pl.y * 6.0 - scene_t * 2.4, pl.z * 4.0) + P.z);
		float puff = 0.65 + 0.35 * sin(scene_t * 5.0 - y * 10.0 + P.z);
		em = vec3(1.0, 0.45, 0.12) * exp(-y * 9.0) * 1.5;
		alb = vec3(0.55, 0.6, 0.7);
		return max(0.0, (1.0 - q) * 1.5 + (n - 0.5) * 1.6 - 0.3) * (1.0 - smoothstep(0.6, 1.0, y)) * puff * P.x;
	}
	float d = smoke_ring(pw, g0, 0.0, em) + smoke_ring(pw, g1, 1.0, em) + smoke_ring(pw, g2, 2.0, em) + smoke_ring(pw, g3, 3.0, em);
	float nz = fbm3(pw * 0.8 + vec3(0.0, scene_t * 0.35, 0.0));
	alb = vec3(0.25, 0.24, 0.23);
	return d * smoothstep(0.2, 0.75, nz + 0.2 * d) * 2.2 * P.y;
}
void vertex() { vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
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
	float t0 = max(max(max(tmn.x, tmn.y), tmn.z), 0.0);
	float t1 = min(min(tmx.x, tmx.y), tmx.z);
	vec3 svp = scene_view_pos(SCREEN_UV, INV_PROJECTION_MATRIX);
	t1 = min(t1, length(svp));
	if (t1 <= t0) { discard; }
	float dt = (t1 - t0) / 24.0;
	float t = t0 + dt * h21(FRAGCOORD.xy + fract(scene_t * 7.0));
	vec3 lkL = (inv_m * vec4(-key_dir, 0.0)).xyz;
	vec3 col = vec3(0.0);
	float Tr = 1.0;
	float sl = 1.5;
	vec3 em = vec3(0.0);
	vec3 alb = vec3(0.0);
	vec3 em2 = vec3(0.0);
	vec3 alb2 = vec3(0.0);
	for (int i = 0; i < 24; i++) {
		vec3 pw = cam + rd * t;
		vec3 pl = roL + rdL * t;
		float de = field(pw, pl, em, alb);
		if (de > 0.002) {
			float ds = field(pw - key_dir * sl, pl + lkL * sl, em2, alb2);
			float lit = 0.3 + 0.7 * exp(-ds * 2.5);
			float a = 1.0 - exp(-de * P.w * dt);
			col += Tr * a * (alb * (key_col * lit * 0.55 + amb * 0.6) + em);
			Tr *= 1.0 - a;
			if (Tr < 0.02) { break; }
		}
		t += dt;
	}
	ALBEDO = clamp(col, 0.0, 512.0) * FXK;
	ALPHA = clamp(1.0 - Tr, 0.0, 1.0);
}
"""
