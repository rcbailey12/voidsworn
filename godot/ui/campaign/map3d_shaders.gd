extends RefCounted
# Shaders for the 3D sector map (G3, R51): the star system around the Hollow Sun. Presentation only.
# Every shader uses only TIME and its own uniforms (no global uniforms), so the map never depends on the battle world's
# globals. HDR colours above 1 feed the map's glow (bloom).

const NOISE := """
float mh3(vec3 p) { p = fract(p * 0.3183099 + vec3(0.11, 0.17, 0.13)); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float mn3(vec3 x) {
	vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(mh3(i), mh3(i + vec3(1.0, 0.0, 0.0)), f.x), mix(mh3(i + vec3(0.0, 1.0, 0.0)), mh3(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(mh3(i + vec3(0.0, 0.0, 1.0)), mh3(i + vec3(1.0, 0.0, 1.0)), f.x), mix(mh3(i + vec3(0.0, 1.0, 1.0)), mh3(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}
float mfbm(vec3 p, int octs) { float amp = 0.5; float sum = 0.0; for (int k = 0; k < 6; k++) { if (k >= octs) break; sum += amp * mn3(p); p = p * 2.03 + 3.1; amp *= 0.5; } return sum; }
float mh2(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float mn2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mh2(i), mh2(i + vec2(1.0, 0.0)), f.x), mix(mh2(i + vec2(0.0, 1.0)), mh2(i + vec2(1.0, 1.0)), f.x), f.y); }
float mfbm2(vec2 p, int octs) { float amp = 0.5; float sum = 0.0; for (int k = 0; k < 6; k++) { if (k >= octs) break; sum += amp * mn2(p); p = p * 2.03 + vec2(1.7, 9.2); amp *= 0.5; } return sum; }
vec3 hue(float h) { return clamp(abs(fract(h + vec3(0.0, 0.6667, 0.3333)) * 6.0 - 3.0) - 1.0, 0.0, 1.0); }
"""

# The deep background: three star layers (tiny and many, medium, few bright ones with a soft cross), the galaxy's band,
# nebula clouds in the sector's colours, dark dust lanes cutting through them. q = 1 high quality, 0 low.
const SKY := """
shader_type sky;
render_mode use_debanding;
""" + NOISE + """
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
"""

# Near stars as round points at a finite distance: when the camera moves they slide against the sky (parallax).
const STARPTS := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform float px = 1.0;
varying vec4 vc;
void vertex() { vc = COLOR; POINT_SIZE = max(1.0, COLOR.a * 3.2 * px); }
void fragment() {
	vec2 q = POINT_COORD * 2.0 - 1.0;
	float r = dot(q, q);
	if (r > 1.0) discard;
	float a = exp(-r * 3.5);
	ALBEDO = vc.rgb * a * 1.6;
}
"""

# A big soft nebula sheet below the chart: a parallax layer between the chart and the sky.
const NEB_SHEET := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + NOISE + """
uniform vec3 a = vec3(0.2, 0.3, 0.6);
uniform vec3 b = vec3(0.6, 0.2, 0.4);
uniform float gain = 0.25;
uniform float seed = 0.0;
uniform float oct = 5.0;
void fragment() {
	vec2 uv = UV - 0.5;
	float r = length(uv) * 2.0;
	float edge = 1.0 - smoothstep(0.35, 1.0, r);
	int o = int(oct);
	vec3 p = vec3(UV * 3.0, seed);
	float n = mfbm(p + mfbm(p * 2.0 + TIME * 0.004, o) * 1.3, o);
	float m = smoothstep(0.38, 0.9, n) * edge;
	float d = smoothstep(0.55, 0.75, mfbm(p * 2.4 + 9.0, o));
	vec3 c = mix(a, b, smoothstep(0.45, 0.8, n)) * m * (1.0 - d * 0.7);
	ALBEDO = c * gain;
}
"""

# The Hollow Sun's core: a dead black sphere, its rim catching the fire round it, faint embers crawling on the dark surface.
const SUN_CORE := """
shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled;
""" + NOISE + """
uniform vec3 ember = vec3(1.0, 0.42, 0.12);
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float f = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(f, 9.0) * 2.6 + pow(f, 4.0) * 0.05;
	vec3 p = normalize(lp);
	float cr = mfbm(p * 5.0 + vec3(0.0, TIME * 0.008, 0.0), 4);
	float cracks = smoothstep(0.018, 0.0, abs(cr - 0.5)) * 0.07 * (1.0 - f);
	ALBEDO = ember * (rim + cracks);
}
"""

# The ring of slow fire round the Hollow Sun: hot at its inner edge, fraying into tongues of flame outward, turning slowly.
const SUN_FIRE := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + NOISE + """
uniform float r_in = 7.0;
uniform float r_out = 12.0;
uniform float q = 1.0;
uniform float gain = 1.0;
varying vec3 vL;
void vertex() { vL = VERTEX; }
void fragment() {
	vec2 p = vL.xz;
	float r = length(p);
	float u = clamp((r - r_in) / (r_out - r_in), 0.0, 1.0);
	float ang = atan(p.y, p.x);
	int o = q > 0.5 ? 5 : 3;
	float t = TIME * 0.018;
	vec2 fp = vec2(ang * 4.0 / 3.14159 + t * 2.0, r * 0.35 - t * 3.0);
	float n = mfbm2(fp * vec2(2.0, 1.0) + mfbm2(fp * 3.0 + 4.0, o) * 0.9, o);
	float n2 = mfbm2(vec2(ang * 9.0 - t * 5.0, r * 1.2), o);
	// density: a broken hot band near the inner edge (bright arcs and dim gaps), ragged tongues of flame reaching out
	float arcs = smoothstep(0.32, 0.72, mfbm2(vec2(ang * 1.6 + t * 1.5, 3.0), 3));
	float core = exp(-pow((u - 0.1) / 0.075, 2.0)) * (0.25 + 0.9 * arcs) * (0.45 + 0.75 * smoothstep(0.3, 0.75, n2));
	float tongues = smoothstep(u * 1.2 + 0.05, u * 1.2 + 0.3, n) * pow(1.0 - u, 1.5) * (0.5 + 0.7 * arcs);
	float dens = clamp(core + tongues * 0.9, 0.0, 2.0) * smoothstep(0.0, 0.03, u);
	vec3 hot = vec3(1.0, 0.86, 0.6);
	vec3 warm = vec3(1.0, 0.42, 0.1);
	vec3 deep = vec3(0.55, 0.08, 0.02);
	vec3 c = mix(hot, warm, smoothstep(0.05, 0.35, u + (1.0 - n) * 0.2));
	c = mix(c, deep, smoothstep(0.3, 0.9, u));
	ALBEDO = c * dens * (1.5 - 1.0 * u) * gain;
}
"""

# A soft radial glow on a camera-facing quad (the Hollow Sun's haze, node halos, light flares).
const GLOW := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform float power = 2.0;
uniform float gain = 1.0;
uniform float pulse = 0.0;
uniform float hole = 0.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float a = pow(clamp(1.0 - r, 0.0, 1.0), power) * (1.0 - hole * smoothstep(0.35, 0.0, r));
	float p = 1.0 + pulse * 0.35 * sin(TIME * 2.4);
	ALBEDO = col.rgb * a * col.a * gain * p;
}
"""

# Planets, lit by the fire round the Hollow Sun: rocky, ocean world, gas giant bands, ice, lava with glowing cracks.
# kind: 0 rock, 1 terran, 2 gas, 3 ice, 4 lava, 5 barren moon.
const PLANET := """
shader_type spatial;
render_mode shadows_disabled;
""" + NOISE + """
uniform vec3 a : source_color = vec3(0.55, 0.42, 0.3);
uniform vec3 b : source_color = vec3(0.22, 0.15, 0.1);
uniform vec3 atmo : source_color = vec3(0.5, 0.7, 1.0);
uniform float kind = 0.0;
uniform float seed = 0.0;
uniform float q = 1.0;
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	vec3 p = normalize(lp);
	int o = q > 0.5 ? 6 : 4;
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
	EMISSION = em + atmo * pow(f, 4.0) * 0.18;
}
"""

# The atmosphere's rim: a slightly larger shell, brightest at the planet's edge on the side facing the fire.
const ATMO := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;
uniform vec3 atmo : source_color = vec3(0.45, 0.7, 1.0);
uniform vec3 sun_pos = vec3(0.0);
uniform float gain = 1.0;
varying vec3 wn;
varying vec3 wp;
void vertex() { wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 n = normalize(wn);
	vec3 v = normalize(CAMERA_POSITION_WORLD - wp);
	float f = 1.0 - clamp(dot(n, v), 0.0, 1.0);
	float lit = clamp(dot(n, normalize(sun_pos - wp)) * 0.75 + 0.35, 0.0, 1.0);
	float rim = pow(f, 2.2) * (1.0 - smoothstep(0.82, 1.0, f));
	ALBEDO = atmo * rim * lit * 2.4 * gain;
}
"""

# Lit rocks and hull scraps for belts, wreck fields and the debris ring. INSTANCE_CUSTOM.r > 0.5 makes a scrap smoulder.
const ROCK := """
shader_type spatial;
render_mode shadows_disabled;
""" + NOISE + """
uniform vec3 tint : source_color = vec3(0.2, 0.19, 0.18);
uniform float metal = 0.1;
uniform float ember = 0.0;
varying vec3 lp;
varying float smoulder;
void vertex() { lp = VERTEX; smoulder = INSTANCE_CUSTOM.r; }
void fragment() {
	float n = mfbm(lp * 3.0, 4);
	ALBEDO = tint * (0.6 + 0.8 * n);
	ROUGHNESS = 0.85 - metal * 0.4;
	METALLIC = metal;
	float e = smoulder * ember * smoothstep(0.55, 0.7, n) * (0.7 + 0.3 * sin(TIME * 1.3 + lp.x * 5.0));
	EMISSION = vec3(1.0, 0.36, 0.08) * e * 2.0;
}
"""

# Thin glowing orbit lines round the Hollow Sun (a ring strip in the chart plane: UV.x across, UV.y along).
# bright: 0..1 for the brighter arcs drawn near the stops.
const ORBIT := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(0.6, 0.7, 0.9, 0.2);
uniform float ticks = 0.0;
uniform float fade_ends = 0.0;
void fragment() {
	float x = abs(UV.x - 0.5) * 2.0;
	float line = exp(-x * x * 9.0);
	float t = ticks > 0.5 ? (0.55 + 0.45 * step(0.5, fract(UV.y * ticks))) : 1.0;
	float ends = fade_ends > 0.5 ? smoothstep(0.0, 0.35, UV.y) * smoothstep(1.0, 0.65, UV.y) : 1.0;
	ALBEDO = col.rgb * line * col.a * t * ends;
}
"""

# A jump lane: a glowing ribbon in the chart plane (UV.x across, UV.y from start to end). A bright core, a soft halo,
# energy pulses flowing toward the destination when flow > 0, red chevrons into an elite or the flagship when hazard > 0.
const LANE := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(1.0);
uniform float flow = 0.0;
uniform float hazard = 0.0;
uniform float len = 20.0;
uniform float glow = 1.0;
void fragment() {
	float x = abs(UV.x - 0.5) * 2.0;
	float core = exp(-x * x * 140.0);
	float halo = exp(-x * x * 9.0) * 0.35 * glow;
	float y = UV.y * len;
	float pulse = 0.0;
	if (flow > 0.0) {
		float ph = fract(y / 5.0 - TIME * 0.9);
		pulse = smoothstep(0.0, 0.08, ph) * smoothstep(0.34, 0.08, ph) * flow;
	}
	float idle = 0.5 + 0.5 * smoothstep(0.0, 0.06, abs(fract(y / 9.0 - TIME * 0.12) - 0.5));
	vec3 c = col.rgb * (core * 1.5 + halo) * mix(idle, 1.0, flow) + col.rgb * pulse * (core * 2.5 + halo * 1.6);
	// hazard: red chevrons over the last third
	float hz = hazard * smoothstep(0.62, 0.7, UV.y);
	float chev = step(0.5, fract(y * 0.9 - x * 0.9 - TIME * 0.5)) * exp(-x * x * 5.0);
	c = mix(c, vec3(1.6, 0.28, 0.18) * (core * 1.4 + 0.45 * chev + halo), hz * 0.8);
	float ends = smoothstep(0.0, 0.04, UV.y) * smoothstep(1.0, 0.96, UV.y);
	ALBEDO = c * col.a * ends;
}
"""

# The ring round a stop, drawn on a flat quad: a crisp circle with tick marks, a faint fill, turning dashes when you can
# jump there (dash = 1), a soft pulse. r = ring radius as a fraction of the quad's half size.
const RING := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(1.0, 1.0, 1.0, 0.3);
uniform float r = 0.8;
uniform float dash = 0.0;
uniform float hot = 0.0;
uniform float fill = 0.0;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float d = length(p);
	float ang = atan(p.y, p.x);
	float w = 0.018 + hot * 0.01;
	float ring = smoothstep(w, 0.0, abs(d - r));
	float seg = fract(ang / 6.28318 * 4.0);
	float outer = smoothstep(0.012, 0.0, abs(d - r - 0.1)) * step(abs(seg - 0.5), 0.22);
	float tick = smoothstep(0.03, 0.0, abs(fract(ang / 6.28318 * 24.0) - 0.5) - 0.44) * step(r - 0.07, d) * step(d, r - 0.025);
	float dsh = dash * step(0.5, fract(ang / 6.28318 * 18.0 - TIME * 0.25)) * smoothstep(0.016, 0.0, abs(d - r - 0.045));
	float inner = smoothstep(r, r * 0.2, d) * (0.06 + fill * 0.1);
	float glow = exp(-pow((d - r) / 0.09, 2.0)) * (0.25 + hot * 0.4);
	float a = ring * 1.4 + tick * 0.6 + dsh * 1.5 + inner + glow + outer * 0.5 * (0.4 + hot);
	ALBEDO = col.rgb * a * col.a * 1.6;
}
"""

# A nebula pocket: soft clouds on camera-facing quads, value noise shaped, slowly churning; storm > 0 adds flickers.
const CLOUD := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + NOISE + """
uniform vec3 a : source_color = vec3(0.35, 0.6, 1.0);
uniform vec3 b : source_color = vec3(0.7, 0.4, 1.0);
uniform float gain = 0.6;
uniform float seed = 0.0;
uniform float storm = 0.0;
uniform float oct = 4.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
void fragment() {
	vec2 uv = UV - 0.5;
	float r = length(uv) * 2.0;
	int o = int(oct);
	vec3 p = vec3(uv * 2.4, seed + TIME * 0.02);
	float n = mfbm(p + mfbm(p * 1.7 + 2.0, o) * 0.9, o);
	float m = smoothstep(0.32, 0.8, n) * pow(clamp(1.0 - r, 0.0, 1.0), 1.6);
	vec3 c = mix(a, b, smoothstep(0.4, 0.8, n));
	float fl = 0.0;
	if (storm > 0.0) {
		float k = floor(TIME * 3.0 + seed * 7.0);
		fl = step(0.86, fract(sin(k * 12.9898 + seed) * 43758.5453)) * storm * smoothstep(0.55, 0.75, n);
	}
	ALBEDO = c * m * gain * (1.0 + fl * 3.0);
}
"""

# The threat marker over a fight: a faceted gem lit from inside, in the enemy's colour, with the faction's own light:
# look 0 plain, 1 pulse in step (every Hegemony light keeps the same beat), 2 rainbow edges (Ithar crystal), 3 a white-gold
# corona (Deathless).
const MARKER := """
shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled;
""" + NOISE + """
uniform vec4 col : source_color = vec4(1.0, 0.3, 0.2, 1.0);
uniform vec4 rim : source_color = vec4(1.0, 0.7, 0.5, 1.0);
uniform float look = 0.0;
uniform float dim = 1.0;
void fragment() {
	float f = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 c = col.rgb * (0.7 + 0.6 * f) * 1.8;
	vec3 r = rim.rgb * pow(f, 2.0) * 2.4;
	if (look > 1.5 && look < 2.5) r = hue(f * 1.4 + TIME * 0.12) * pow(f, 1.5) * 3.0;
	float p = 1.0;
	if (look > 0.5 && look < 1.5) p = 0.7 + 0.5 * sin(TIME * 2.4);
	ALBEDO = (c + r) * p * dim;
}
"""

# A faction halo on the chart plane round a rival's stop (and the flagship): a ring in the faction's light.
# look as in MARKER (2 turns the ring into a rainbow, 1 pulses in step).
const HALO := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + NOISE + """
uniform vec4 col : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform vec4 col2 : source_color = vec4(1.0, 0.8, 0.5, 1.0);
uniform float look = 0.0;
uniform float r = 0.85;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float d = length(p);
	float ang = atan(p.y, p.x);
	float band = smoothstep(0.03, 0.0, abs(d - r)) * 1.2 + exp(-pow((d - r) / 0.08, 2.0)) * 0.4;
	vec3 c = mix(col.rgb, col2.rgb, 0.5 + 0.5 * sin(ang * 3.0 + TIME * 0.4));
	if (look > 1.5 && look < 2.5) c = hue(ang / 6.28318 + TIME * 0.05) * 1.2;
	float pl = (look > 0.5 && look < 1.5) ? 0.65 + 0.45 * sin(TIME * 2.4) : 1.0;
	float seg = 0.75 + 0.25 * step(0.5, fract(ang / 6.28318 * 12.0 + TIME * 0.03));
	ALBEDO = c * band * pl * seg * col.a;
}
"""

# Faction territory: a soft wash of the enemy's light over the far end of the chart.
const TERR := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + NOISE + """
uniform vec4 col : source_color = vec4(1.0);
void fragment() {
	vec2 uv = UV - 0.5;
	float r = length(uv) * 2.0;
	float n = mfbm(vec3(UV * 5.0, TIME * 0.01), 4);
	ALBEDO = col.rgb * col.a * pow(clamp(1.0 - r, 0.0, 1.0), 2.0) * (0.45 + 0.55 * n);
}
"""
