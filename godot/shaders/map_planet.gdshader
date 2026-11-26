shader_type spatial;
render_mode shadows_disabled;

#include "res://shaders/map_noise.gdshaderinc"

uniform vec3 a : source_color = vec3(0.55, 0.42, 0.3);
uniform vec3 b : source_color = vec3(0.22, 0.15, 0.1);
uniform vec3 atmo : source_color = vec3(0.5, 0.7, 1.0);
uniform float kind = 0.0;
uniform float seed = 0.0;
uniform float q = 1.0;
uniform vec3 sun_pos = vec3(0.0);
uniform float night = 1.0;
varying vec3 lp;
varying vec3 wn;
varying vec3 wp;
void vertex() { lp = VERTEX; wn = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz; wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 p = normalize(lp);
	int o = q > 0.5 ? 6 : 4;
	float dark = smoothstep(0.05, -0.3, dot(normalize(wn), normalize(sun_pos - wp)));   // the night side
	float city = 0.0;
	vec3 s = p * 2.3 + seed;
	vec3 col; float rough = 0.85; vec3 em = vec3(0.0);
	if (kind > 1.5 && kind < 2.5) {
		float t = p.y * 7.0 + mfbm(p * vec3(1.5, 6.0, 1.5) + seed, o) * 1.6;
		float bands = 0.5 + 0.5 * sin(t * 2.6) * (0.7 + 0.3 * sin(t * 7.3));
		col = mix(b, a, bands);
		col = mix(col, atmo * 0.6, smoothstep(0.75, 0.95, mfbm(p * 6.0 + seed, o)) * 0.4);
		rough = 0.7;
	} else {
		float h = mfbm(s + mfbm(s * 2.0, o) * 0.6, o);
		float det = mfbm(p * 11.0 + seed, o);
		if (kind > 0.5 && kind < 1.5) {
			float land = smoothstep(0.49, 0.53, h);
			city = land * step(0.74, mn3(p * 46.0 + seed)) * smoothstep(0.55, 0.62, det + 0.2);
			col = mix(b, mix(a, a * 0.6, det), land);
			rough = mix(0.3, 0.9, land);
			float cl = smoothstep(0.5, 0.75, mfbm(p * 3.2 + vec3(TIME * 0.004, 0.0, seed), o));
			col = mix(col, vec3(0.92), cl * 0.75);
			col = mix(col, vec3(0.95), smoothstep(0.78, 0.9, abs(p.y)));
		} else if (kind > 2.5 && kind < 3.5) {
			col = mix(b, a, smoothstep(0.3, 0.7, h)) * (0.85 + 0.3 * det);
			rough = 0.45;
		} else if (kind > 3.5 && kind < 4.5) {
			col = mix(b, a, smoothstep(0.35, 0.7, h)) * (0.7 + 0.3 * det);
			float ridge = smoothstep(0.04, 0.0, abs(mfbm(p * 5.0 + seed, o) - 0.5));
			em = vec3(1.0, 0.35, 0.06) * ridge * 2.2;
		} else {
			col = mix(b, a, smoothstep(0.3, 0.7, h)) * (0.75 + 0.45 * det);
			float cr = smoothstep(0.62, 0.66, mfbm(p * 7.0 + seed + 2.0, o));
			col *= 1.0 - cr * 0.35;
		}
	}
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = 0.3;
	float f = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	EMISSION = em * (0.35 + 0.65 * dark) + atmo * pow(f, 4.0) * 0.18 + vec3(1.0, 0.72, 0.38) * city * dark * night * 2.4;
}
