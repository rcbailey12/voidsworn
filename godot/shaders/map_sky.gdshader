shader_type sky;
render_mode use_debanding;

#include "res://shaders/map_noise.gdshaderinc"

uniform vec3 c1 = vec3(0.2, 0.3, 0.6);
uniform vec3 c2 = vec3(0.6, 0.2, 0.4);
uniform vec3 c3 = vec3(1.0, 0.6, 0.35);
uniform float seed = 0.0;
uniform float q = 1.0;
vec3 star_layer(vec3 d, float scale, float keep, float size, float gain) {
	vec3 p = d * scale;
	vec3 cell = floor(p);
	float h = mh3(cell + seed);
	if (h > keep) return vec3(0.0);
	vec3 sp = cell + 0.3 + 0.4 * vec3(mh3(cell + 1.7), mh3(cell + 4.1), mh3(cell + 8.3));
	float dd = length(p - sp);
	float b = exp(-dd * dd / (size * size));
	float t = mh3(cell + 12.9);
	vec3 col = mix(vec3(0.62, 0.74, 1.0), vec3(1.0, 0.86, 0.66), t);
	col = mix(col, vec3(1.0, 0.62, 0.45), step(0.92, t));
	float tw = mh3(cell + 3.3);
	return col * b * gain * (0.35 + 1.4 * pow(1.0 - h / keep, 3.0)) * (0.7 + 0.6 * tw);
}
void sky() {
	vec3 d = EYEDIR;
	int oct = q > 0.5 ? 5 : 3;
	vec3 col = vec3(0.0035, 0.005, 0.011);
	// the galaxy's band, tilted across the sky
	vec3 gn = normalize(vec3(0.32, 1.0, 0.18));
	float gb = dot(d, gn);
	float band = exp(-gb * gb * 9.0);
	float bn = mfbm(d * 3.5 + seed, oct);
	col += vec3(0.05, 0.05, 0.07) * band * (0.4 + bn);
	// nebula: two layers in the sector's colours, warped
	vec3 w = d * 1.7 + vec3(seed * 0.37);
	float n1 = mfbm(w + mfbm(w * 1.9, oct) * 1.2, oct);
	float n2 = mfbm(d * 3.1 + vec3(5.2, seed, 1.3) + n1 * 1.4, oct);
	float neb = smoothstep(0.42, 0.85, n1) * (0.55 + 0.6 * band);
	col += c1 * neb * 0.32;
	col += c2 * smoothstep(0.5, 0.95, n2) * neb * 0.5;
	col += c3 * pow(smoothstep(0.62, 1.0, n2 * n1 * 1.9), 2.0) * 0.18;
	// dark dust lanes
	float dust = smoothstep(0.48, 0.72, mfbm(d * 5.3 + vec3(2.0, seed, 7.0), oct));
	col *= 1.0 - dust * 0.75 * (0.4 + band);
	// stars
	vec3 s = star_layer(d, 520.0, 0.42, 0.10, 0.55);
	s += star_layer(d, 230.0, 0.16, 0.11, 1.1);
	if (q > 0.5) s += star_layer(d, 1100.0, 0.5, 0.09, 0.28);
	vec3 bp = d * 70.0; vec3 bc = floor(bp);
	if (mh3(bc + seed + 0.5) < 0.05) {
		vec3 sp = bc + 0.35 + 0.3 * vec3(mh3(bc + 2.2), mh3(bc + 5.5), mh3(bc + 9.9));
		vec3 off = bp - sp; float dd = length(off);
		float core = exp(-dd * dd / 0.004);
		float cross = exp(-abs(off.x) * 60.0) * exp(-abs(off.y) * 6.0) + exp(-abs(off.y) * 60.0) * exp(-abs(off.x) * 6.0);
		vec3 bcol = mix(vec3(0.7, 0.8, 1.0), vec3(1.0, 0.85, 0.7), mh3(bc + 7.0));
		s += bcol * (core * 3.0 + cross * 0.35) * (1.0 - dust * 0.6);
	}
	col += s * (1.0 - dust * 0.5);
	COLOR = col;
}
