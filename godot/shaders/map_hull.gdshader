shader_type spatial;

#include "res://shaders/map_noise.gdshaderinc"

#include "res://shaders/map_bump.gdshaderinc"

uniform vec3 base : source_color = vec3(0.45, 0.47, 0.5);
uniform vec3 accent : source_color = vec3(0.3, 0.45, 0.7);
uniform vec3 win_col : source_color = vec3(1.0, 0.82, 0.55);
uniform float scale = 3.0;
uniform float windows = 0.12;
uniform float metal = 0.6;
uniform float glow = 0.0;
uniform float gain = 1.0;   // the brightness of its own light (windows, accent glow, rim): a stop further on is dimmer
varying vec3 lp;
varying vec3 ln;
void vertex() { lp = VERTEX; ln = NORMAL; }
vec2 puv(vec3 p, vec3 n) { vec3 a = abs(n); if (a.x > a.y && a.x > a.z) return p.zy; if (a.y > a.z) return p.xz; return p.xy; }
float panels(vec2 uv, out vec2 cell, out vec2 f) {
	float row = floor(uv.y);
	float w = 2.0 + floor(mh2(vec2(row, 7.7)) * 4.0);   // long plates (2 to 5 rows wide), not bricks
	vec2 q = vec2((uv.x + mh2(vec2(row, 3.1)) * w) / w, uv.y);
	cell = vec2(floor(q.x), row); f = fract(q);
	return min(min(f.x, 1.0 - f.x) * w, min(f.y, 1.0 - f.y));
}
void fragment() {
	vec2 uv = puv(lp, ln) * scale;
	vec2 c1; vec2 f1; float e1 = panels(uv, c1, f1);
	vec2 c2; vec2 f2; float e2 = panels(uv * 2.2 + 11.0, c2, f2);
	float h1 = mh2(c1 + 0.5); float h2 = mh2(c2 + 1.5);
	float seam = 1.0 - smoothstep(0.0, 0.022, e1);
	float seam2 = 1.0 - smoothstep(0.0, 0.03, e2);
	float grime = mfbm(lp * 2.2 + 4.0, 4);
	vec3 col = base * (0.78 + 0.32 * h1) * (0.9 + 0.2 * h2);
	col = mix(col, accent, step(0.95, h1) * 0.55);
	col *= 1.0 - seam * 0.32 - seam2 * 0.08;
	col *= 0.82 + 0.3 * grime;
	float ht = smoothstep(0.0, 0.022, e1) * 0.5 + smoothstep(0.0, 0.03, e2) * 0.2 + step(0.85, h2) * 0.06;   // flat panels, narrow grooves
	NORMAL = bump_normal(NORMAL, VERTEX, ht, 0.35);
	ALBEDO = col;
	METALLIC = metal * (0.5 + 0.5 * h1);
	float wear = mfbm(lp * 7.0 + 9.0, 4);   // scuffed and polished patches, so plates never read as one smooth plastic
	ROUGHNESS = clamp(0.42 + 0.3 * grime + 0.28 * (wear - 0.5) * 2.0 * 0.5 + seam * 0.2 + h2 * 0.12, 0.25, 0.95);
	// window strips in clusters: a run of lit slots along some plates, only where a slow noise says a deck is lived in
	float cluster = smoothstep(0.52, 0.62, mn3(lp * 1.3 + 3.7));
	float strip = step(abs(f1.y - 0.5), 0.06) * step(0.35, fract(f1.x * 7.0)) * step(0.08, f1.x) * step(f1.x, 0.92);
	float wmask = strip * cluster * step(1.0 - windows * 3.0, mh2(c1 + 7.3));
	// a warm rim from the Hollow Sun's disc, so the silhouette reads at full-map distance
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.5);
	EMISSION = (win_col * wmask * 1.6 + accent * glow * (1.0 - seam) * 0.6 + vec3(1.0, 0.62, 0.34) * fr * 0.22) * gain;
}
