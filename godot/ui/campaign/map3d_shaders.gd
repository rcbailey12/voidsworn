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
	float lit = clamp(dot(n, normalize(sun_pos - wp)) * 0.9 + 0.2, 0.0, 1.0);
	float rim = pow(f, 7.0) * (1.0 - smoothstep(0.93, 1.0, f));   // a thin bright limb, clear over the face
	ALBEDO = atmo * rim * lit * 4.0 * gain;
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

# A faction halo on the chart plane round a rival's stop (and the flagship): a ring in the faction's light.
# look: 0 plain, 1 pulses in step (Hegemony), 2 a rainbow ring (Ithar crystal), 3 corona (Deathless).
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

# ---- The Hollow Sun as a black hole (R51 round 2, lore round 4): the same look as G4's dead-star board
# (godot/world/world_shaders.gd DISC, DISC_FRONT, LENS), with TIME in place of the battle's scene_t global.

# The accretion disc of the dead star. Opaque where dense, so the lens pass bends its far side over and under the
# shadow (the arc a real black hole shows); differential rotation, spiral turbulence, temperature falling outward,
# Doppler beaming (the side coming toward the camera brighter and bluer). r_in, r_out in the disc mesh's local units.
const BH_DISC := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
""" + NOISE + """
uniform float r_in = 1.0;
uniform float r_out = 3.0;
uniform float spin = 0.3;
uniform float gain = 1.0;
uniform float front_cut = 0.0;
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
	float a2 = ang + TIME * w;
	float sp = mfbm2(vec2(a2 * 3.0 + log(r) * 6.0, r * 1.5), 5);
	float sp2 = mfbm2(vec2(a2 * 7.0 - log(r) * 4.0, r * 4.0 + 3.0), 5);
	float dens = smoothstep(0.0, 0.06, u) * (1.0 - smoothstep(0.7, 1.0, u)) * (0.55 + 0.7 * sp) * (0.75 + 0.45 * sp2);
	vec3 c = mix(vec3(1.0, 0.92, 0.8), vec3(1.0, 0.55, 0.2), smoothstep(0.0, 0.3, u));
	c = mix(c, vec3(0.55, 0.12, 0.04), smoothstep(0.3, 1.0, u)) * (2.6 - 2.0 * u);
	vec3 tang = normalize((MODEL_MATRIX * vec4(-q.y, 0.0, q.x, 0.0)).xyz);
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	float dop = dot(tang, V);
	c *= 1.0 + 0.85 * dop;
	c = mix(c, c * vec3(0.8, 0.95, 1.25), clamp(dop, 0.0, 1.0) * 0.4);
	if (dens < 0.035) { discard; }
	ALBEDO = c * dens * gain;
}
"""

# The near half of the disc again, added on top after the lens, so the half in front of the hole stays in front.
const BH_FRONT := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + NOISE + """
uniform float r_in = 1.0;
uniform float r_out = 3.0;
uniform float spin = 0.3;
uniform float gain = 1.0;
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
	float a2 = ang + TIME * w;
	float sp = mfbm2(vec2(a2 * 3.0 + log(r) * 6.0, r * 1.5), 5);
	float sp2 = mfbm2(vec2(a2 * 7.0 - log(r) * 4.0, r * 4.0 + 3.0), 5);
	float dens = smoothstep(0.0, 0.08, u) * (1.0 - smoothstep(0.75, 1.0, u)) * (0.45 + 0.75 * sp) * (0.7 + 0.5 * sp2);
	vec3 c = mix(vec3(1.0, 0.92, 0.8), vec3(1.0, 0.55, 0.2), smoothstep(0.0, 0.35, u));
	c = mix(c, vec3(0.55, 0.12, 0.04), smoothstep(0.35, 1.0, u)) * (2.4 - 1.8 * u);
	vec3 tang = normalize((MODEL_MATRIX * vec4(-q.y, 0.0, q.x, 0.0)).xyz);
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	c *= 1.0 + 0.85 * dot(tang, V);
	vec3 toHole = hole_center - CAMERA_POSITION_WORLD;
	vec3 toFrag = vW - CAMERA_POSITION_WORLD;
	float front = smoothstep(0.0, 0.08 * length(toHole), length(toHole) - length(toFrag));
	ALBEDO = c * dens * gain * front * 0.9;
}
"""

# Gravitational lensing on a camera-facing quad over the hole (G4's LENS): the picture behind the hole is pushed out
# round the Einstein ring and pulled in from the far side; inside the shadow nothing escapes, ringed by the photon ring.
# Only what lies behind the hole is bent (depth check), so the chart in front never moves.
const BH_LENS := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform float r_shadow = 0.12;
uniform float r_einstein = 0.2;
uniform float photon = 1.0;
uniform vec3 ring_col = vec3(1.0, 0.8, 0.55);
varying vec2 vUv;
varying vec4 vCenterClip;
void vertex() {
	vec3 c = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float half_size = length(MODEL_MATRIX[0].xyz);
	vec4 vp = VIEW_MATRIX * vec4(c, 1.0);
	vp.xy += VERTEX.xy * half_size * 2.0;
	POSITION = PROJECTION_MATRIX * vp;
	vCenterClip = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(c, 1.0));
	vUv = VERTEX.xy * 2.0;
}
void fragment() {
	float r = length(vUv);
	if (r > 1.0) { discard; }
	vec2 cs = vCenterClip.xy / vCenterClip.w * 0.5 + 0.5;
	vec2 d = SCREEN_UV - cs;
	float k = length(d) / max(r, 1e-4);
	vec2 dir = r > 1e-4 ? d / length(d) : vec2(0.0);
	float th = r;
	float re2 = r_einstein * r_einstein;
	float beta = th - re2 / max(th, 1e-3);
	float edge = smoothstep(1.0, 0.6, r);
	float b = mix(th, beta, edge);
	vec2 suv = cs + dir * b * k;
	float hole_z = -(VIEW_MATRIX * vec4((MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz, 1.0)).z;
	float dsrc = texture(depth_tex, suv).r;
	vec4 vsrc = INV_PROJECTION_MATRIX * vec4(suv * 2.0 - 1.0, dsrc, 1.0);
	float src_z = -vsrc.z / vsrc.w;
	if (src_z < hole_z * 0.98) { suv = SCREEN_UV + dir * 0.02 * edge; }
	vec3 col = textureLod(screen_tex, suv, 0.0).rgb;
	float mag = 1.0 + 0.6 * exp(-pow((th - r_einstein) / (r_einstein * 0.35), 2.0)) * edge;
	col *= mag;
	float sh = smoothstep(r_shadow * 1.02, r_shadow * 0.98, th);
	float ring = exp(-pow((th - r_shadow * 1.05) / (r_shadow * 0.035), 2.0)) * photon;
	float ring2 = exp(-pow((th - r_shadow * 1.12) / (r_shadow * 0.08), 2.0)) * photon * 0.35;
	col = mix(col, vec3(0.0), sh) + ring_col * (ring * 6.0 + ring2 * 2.0) * (0.92 + 0.08 * sin(TIME * 0.7));
	ALBEDO = col;
	ALPHA = smoothstep(1.0, 0.85, r);
}
"""

# Low quality (no lens): a camera-facing black shadow disc with the photon ring and a faint lensed glow round it.
const BH_SHADOW := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform float r_shadow = 0.5;
uniform vec3 ring_col = vec3(1.0, 0.8, 0.55);
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
void fragment() {
	float th = length(UV - 0.5) * 2.0;
	float sh = smoothstep(r_shadow * 1.02, r_shadow * 0.98, th);
	float ring = exp(-pow((th - r_shadow * 1.05) / (r_shadow * 0.035), 2.0));
	float ring2 = exp(-pow((th - r_shadow * 1.2) / (r_shadow * 0.15), 2.0)) * 0.25;
	ALBEDO = ring_col * (ring * 6.0 + ring2 * 2.0) * (1.0 - sh);
	ALPHA = clamp(sh + ring + ring2, 0.0, 1.0);
}
"""

# ---- Stop objects at full finish (R51 round 2, Ryan: "the actual icons still look kind of low poly").
# Bump mapping without textures: the height is computed in the fragment and turned into a normal with screen-space
# derivatives (surface gradient), so every procedural part carries panel seams, grit and craters in its lighting.
const BUMP := """
vec3 bump_normal(vec3 n, vec3 pos, float h, float k) {
	vec3 dpdx = dFdx(pos); vec3 dpdy = dFdy(pos);
	float dhx = dFdx(h); float dhy = dFdy(h);
	vec3 r1 = cross(dpdy, n); vec3 r2 = cross(n, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dhx * r1 + dhy * r2);
	return normalize(abs(det) * n - grad * k);
}
"""

# Space hull plating for stations, gantries, docks, tenders and drones: panels in rows of varied widths on the face's
# main plane, recessed seams, a finer second panel layer, grime, a few accent panels in the faction colour, rows of lit
# windows. Lit by the Hollow Sun (PBR).
const HULL := """
shader_type spatial;
""" + NOISE + BUMP + """
uniform vec3 base : source_color = vec3(0.45, 0.47, 0.5);
uniform vec3 accent : source_color = vec3(0.3, 0.45, 0.7);
uniform vec3 win_col : source_color = vec3(1.0, 0.82, 0.55);
uniform float scale = 3.0;
uniform float windows = 0.12;
uniform float metal = 0.6;
uniform float glow = 0.0;
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
	EMISSION = win_col * wmask * 1.6 + accent * glow * (1.0 - seam) * 0.6 + vec3(1.0, 0.62, 0.34) * fr * 0.22;
}
"""

# Solar arrays: dark blue cells in a silver grid, a glossy sheen.
const SOLAR := """
shader_type spatial;
""" + NOISE + """
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	vec2 g = abs(fract(UV * vec2(18.0, 6.0)) - 0.5);
	float grid = smoothstep(0.44, 0.48, max(g.x, g.y));
	vec3 cellc = vec3(0.04, 0.07, 0.16) * (0.85 + 0.3 * mh2(floor(UV * vec2(18.0, 6.0))));
	ALBEDO = mix(cellc, vec3(0.62, 0.64, 0.68), grid);
	METALLIC = mix(0.3, 0.9, grid);
	ROUGHNESS = mix(0.15, 0.4, grid);
}
"""

# Heat radiators: dark fins whose cores glow a dull ember from the heat they shed.
const RADIATOR := """
shader_type spatial;
""" + NOISE + BUMP + """
uniform vec3 heat : source_color = vec3(1.0, 0.38, 0.12);
uniform float gain = 1.0;
void fragment() {
	float fins = abs(fract(UV.x * 14.0) - 0.5);
	float ht = smoothstep(0.1, 0.35, fins);
	NORMAL = bump_normal(NORMAL, VERTEX, ht, 0.6);
	ALBEDO = vec3(0.12, 0.11, 0.11);
	METALLIC = 0.7; ROUGHNESS = 0.5;
	float core = smoothstep(0.5, 0.0, abs(UV.y - 0.5)) * (1.0 - ht * 0.5);
	EMISSION = heat * core * gain * (0.75 + 0.25 * sin(TIME * 0.5 + UV.x * 3.0));
}
"""

# Asteroid rock at full finish: strata and dust from 3D noise, fine grit and pitting in the lighting (bump), darker in
# the craters the mesh carries (COLOR.r is the crater depth), a faint rim from the sun. kind 0 stone, 1 iron, 2 ice.
const ROCK_HI := """
shader_type spatial;
""" + NOISE + BUMP + """
uniform vec3 tint : source_color = vec3(0.3, 0.27, 0.24);
uniform float kind = 0.0;
uniform float q = 1.0;
varying vec3 lp;
varying float crater;
void vertex() { lp = VERTEX; crater = COLOR.r; }
void fragment() {
	int o = q > 0.5 ? 5 : 3;
	float strata = 0.5 + 0.5 * sin(lp.y * 9.0 + mfbm(lp * 2.0, 3) * 6.0);
	float dust = mfbm(lp * 3.5 + 2.0, o);
	float grit = mfbm(lp * 6.5, o);
	vec3 col = tint * (0.7 + 0.35 * dust) * (0.88 + 0.18 * strata);
	col *= 1.0 - crater * 0.45;
	if (kind > 1.5) col = mix(col, vec3(0.75, 0.82, 0.9), smoothstep(0.45, 0.7, dust) * 0.6);
	if (kind > 0.5 && kind < 1.5) col = mix(col, vec3(0.42, 0.3, 0.22), smoothstep(0.55, 0.8, grit) * 0.5);
	float ht = grit * 0.35 + dust * 0.4 + smoothstep(0.6, 0.72, mfbm(lp * 4.0 + 5.0, 3)) * -0.2;
	NORMAL = bump_normal(NORMAL, VERTEX, ht, q > 0.5 ? 0.45 : 0.25);
	ALBEDO = col;
	METALLIC = kind > 0.5 && kind < 1.5 ? 0.55 : 0.05;
	ROUGHNESS = kind > 1.5 ? 0.45 : 0.9;
	float f = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	RIM = 0.4; RIM_TINT = 0.6;
	EMISSION = vec3(1.0, 0.55, 0.3) * pow(f, 5.0) * 0.08;
}
"""

# A planet's cloud layer: a slightly larger shell, clouds drifting, lit by the sun, transparent between.
const CLOUDS := """
shader_type spatial;
render_mode depth_draw_never, cull_back;
""" + NOISE + """
uniform float cover = 0.5;
uniform float seed = 0.0;
uniform float q = 1.0;
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	vec3 p = normalize(lp);
	int o = q > 0.5 ? 5 : 3;
	float n = mfbm(p * 3.0 + vec3(TIME * 0.006, 0.0, seed) + mfbm(p * 6.0 + seed, 3) * 0.5, o);
	float c = smoothstep(1.0 - cover, 1.0 - cover + 0.25, n);
	ALBEDO = vec3(0.95);
	ROUGHNESS = 0.9;
	ALPHA = c * 0.85;
}
"""

# The lensed image of the disc's far side, drawn on a camera-facing quad behind the shadow: the glowing arc that wraps
# over the top of the shadow and the thinner one under it (brightest above and below, fading where the disc itself
# passes at the sides), the disc's own colours and spin, then the thin bright photon ring at the shadow's edge. No
# screen copy, so nothing on the chart is ever bent and there are no seams at any camera angle. r_shadow is the
# shadow radius as a fraction of the quad's half size.
const BH_LENSED := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + NOISE + """
uniform float r_shadow = 0.25;
uniform float gain = 1.0;
uniform float spin = 0.3;
uniform float tilt_dir = 0.0;   // screen angle of the disc's long axis (radians); arcs sit across it
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	p.y = -p.y;
	float th = length(p) / r_shadow;          // in shadow radii
	float ang = atan(p.y, p.x) - tilt_dir;
	float across = abs(sin(ang));               // 1 above and below the disc's line, 0 along it
	// the upper arc is the big lensed image of the far side, the lower one a thinner secondary image
	float up = step(0.0, sin(ang));
	float w_out = mix(1.32, 1.44, up);   // a defined band, not a halo (NASA Goddard 2019: thin arcs hugging the shadow)
	float band = smoothstep(1.035, 1.06, th) * (1.0 - smoothstep(w_out - 0.06, w_out, th));
	float u = clamp((th - 1.05) / (w_out - 1.05), 0.0, 1.0);
	float a2 = ang * 3.0 + TIME * spin * 2.0;
	float sp = mfbm2(vec2(a2 * 4.0 + log(max(th, 1.0)) * 8.0, th * 7.0), 4);   // streaks along the arc, like the disc's own
	vec3 c = mix(vec3(1.0, 0.92, 0.8), vec3(1.0, 0.55, 0.2), smoothstep(0.0, 0.35, u));
	c = mix(c, vec3(0.55, 0.12, 0.04), smoothstep(0.35, 1.0, u)) * (2.2 - 1.6 * u);
	// the lower arc (the far side seen under the shadow) is thinner and a little fainter than the upper one
	float arc = band * pow(across, 0.8) * (0.45 + 0.8 * sp) * mix(1.0, 1.0, up) * 0.95;   // the lower arc as strong as the upper, so it reads at full-map zoom
	// Doppler beaming: the side of the disc turning toward the camera (screen right) brighter and whiter-blue, the
	// receding side dimmer and redder; kept subtle so the look stays on brand
	float beam = cos(ang + tilt_dir);
	c *= 1.0 + 0.45 * beam;
	c = mix(c, c * vec3(0.85, 0.97, 1.2), clamp(beam, 0.0, 1.0) * 0.35);
	c = mix(c, c * vec3(1.1, 0.8, 0.65), clamp(-beam, 0.0, 1.0) * 0.35);
	// the photon ring: thin, sharp, hugging the shadow, a little brighter on the approaching side
	float ring = exp(-pow((th - 1.02) / 0.011, 2.0)) * 3.2 * (1.0 + 0.25 * beam) + exp(-pow((th - 1.06) / 0.05, 2.0)) * 0.35;
	ALBEDO = (c * arc + vec3(1.0, 0.88, 0.68) * ring) * gain;
}
"""

# The threat marker over a fight (R51 round 3, replaces the lit gem): a crisp holographic diamond outline in the
# danger band's colour, an inner pip in the enemy faction's light, corner ticks, a scan line sweeping down it and a
# soft pulse ring going out. elite draws a second outline and a gold crown bar. Camera-facing.
const THREAT := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(0.5, 0.86, 0.42, 1.0);
uniform vec4 fac : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform float elite = 0.0;
uniform float dim = 1.0;
uniform float phase = 0.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
float line(float d, float w) { float aa = fwidth(d) * 1.2; return 1.0 - smoothstep(w - aa, w + aa, abs(d)); }
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	p.y *= 0.8;
	float dm = abs(p.x) + abs(p.y);                     // diamond distance
	float t = TIME + phase;
	float o1 = line(dm - 0.62, 0.035);
	float o2 = elite * line(dm - 0.76, 0.022);
	float fillv = (1.0 - smoothstep(0.55, 0.62, dm)) * 0.045;
	float pip = 1.0 - smoothstep(0.16, 0.2, dm);
	// corner ticks just outside the outline, on the four points
	float ticks = 0.0;
	ticks += line(abs(p.y), 0.02) * step(0.7, abs(p.x)) * step(abs(p.x), 0.86);
	ticks += line(abs(p.x), 0.02) * step(0.7, abs(p.y)) * step(abs(p.y), 0.86);
	// scan line sweeping down inside the diamond
	float sy = 0.62 - fract(t * 0.45) * 1.24;
	float scan = line(p.y - sy, 0.012) * (1.0 - smoothstep(0.58, 0.62, dm)) * 0.9;
	// pulse ring going out
	float pr = 0.62 + fract(t * 0.6) * 0.38;
	float pulse = line(dm - pr, 0.018) * (1.0 - fract(t * 0.6)) * 0.7;
	// gold crown bar for an elite
	float crown = elite * line(p.y - 0.86, 0.025) * step(abs(p.x), 0.3);
	vec3 c = col.rgb * (o1 * 2.2 + fillv + ticks * 1.2 + scan + pulse) + fac.rgb * pip * 1.8 + vec3(1.0, 0.78, 0.35) * (o2 * 1.8 + crown * 2.2);
	ALBEDO = c * dim;
}
"""
