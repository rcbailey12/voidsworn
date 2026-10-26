extends Node3D
# Effects for the A2 engine test, built fresh to ../SPEC.md (the cinematic bar, R16). Nothing reused from the game.
#
# Per ship, a 4 s loop staggered 0.5 s in layout order (0.17 s in the crowd runs):
#   engines always on (hot core, flickering plume, long cooling trail; the Corsair sputters and coughs soot)
#   0.0 s  broadside: four port guns ripple 80 ms apart (blast, flame tongue, smoke ring, tracer at 160 u/s, impact)
#   1.25 s beam charge flare, 1.5 s to 2.2 s beam 80 units ahead (white core, faction glow, shimmer, impact flare and sparks)
#   2.4 s  incoming shell hits the starboard side: shield ripple (Corsair patchy), or a hull hit for Chorus and Deathless
#   always a hull breach on the upper port flank (scorched torn hole, hot torn plates, venting gas, debris, fire,
#          spark showers every 2.3 s, a secondary pop every 3.7 s)
# Scene-wide, every 12 s (4 s in the crowd runs): the Hegemony copy above the formation breaks at 12.4 s (flash,
#   shockwave, fireball, four chunks of its own mesh with burning edges and squibs, debris and embers, a drifting
#   burning wreck), and fades back in whole 2 s before the next one.
#
# How it runs: one global shader clock (scene_t). Every glow sprite and ribbon of one kind, for all ships, is one
# MultiMesh (one draw) whose shader computes each instance's position, drift, size and brightness from scene_t and
# the instance's own data; the shields do the same per ship. The breach gas, fire and debris of all ships are three
# shared particle systems emitting from every breach at once; each ship's four guns share one smoke-ring, one spark
# and one debris system. Per frame the script only moves the ship roots and the shared emitters, shows a shield
# while it can be seen, restarts one-shot particle systems when their start time passes, and sets the lights that
# are on.

const LOOP := 4.0
const STAGGER := 0.5
const DRIFT_SPEED := 3.0
const DRIFT_SPAN := 40.0
const DRIFT_FADE := 1.0
const GUN_GAP := 0.08
const SHELL_SPEED := 160.0
const BROADSIDE_RANGE := 70.0
const RING_LIFE := 2.2
const BEAM_AT := 1.5
const BEAM_T := 0.7
const CHARGE_T := 0.25
const BEAM_LEN := 80.0
const HIT_AT := 2.4
const SHIELD_T := 0.6
const INCOMING_T := 60.0 / 160.0
const TRAIL_LEN := 60.0
const BOOM_EVERY := 12.0
const BREAK_OFFSET := 0.4  # the destruction event breaks 0.4 s after each multiple of its period (12.4 s, 24.4 s, ...)
const SPARKS_EVERY := 2.3
const POP_EVERY := 3.7
const WRECK_POS := Vector3(0, 25, 0)
const WRECK_SCALE := 0.6
const BIG_AABB := AABB(Vector3(-60, -60, -60), Vector3(120, 120, 120))
const WORLD_AABB := AABB(Vector3(-2000, -2000, -2000), Vector3(4000, 4000, 4000))

const NOISE := """
float hash12(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x), mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) { return vnoise(p) * 0.55 + vnoise(p * 2.1 + 3.7) * 0.3 + vnoise(p * 4.3 + 7.1) * 0.15; }
vec3 safe_norm(vec3 v, vec3 fallback) { float l = length(v); return l > 1e-6 ? v / l : fallback; }
"""

# The shared clock and the drift every ship follows (3 u/s, looping over 40 units, 1 s fade either side of the jump).
const TIMING := """
global uniform float scene_t;
float drift_x(float t) { return mod(3.0 * t + 20.0, 40.0) - 20.0; }
float drift_fade(float t) { float q = mod(3.0 * t + 20.0, 40.0); return clamp(min(q, 40.0 - q) / 3.0, 0.0, 1.0); }
float loop_age(float tt, float st, float per) { float x = tt - st; return x < 0.0 ? -1.0 : mod(x, per); }
float hash11(float x) { return fract(sin(x * 12.9898) * 43758.5453); }
float sputter(float t) {
	float s = 0.6 + 0.4 * mix(hash11(floor(t * 5.0)), hash11(floor(t * 5.0) + 1.0), smoothstep(0.0, 1.0, fract(t * 5.0)));
	return hash11(floor(t * 6.0)) < 0.18 ? s * 0.2 : s;
}
"""

const SOFT := """
#ifdef SOFT
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
float soft_fade(vec2 suv, vec3 vtx, mat4 inv_proj, float dist) {
	float d = texture(depth_tex, suv).r;
	vec4 v = inv_proj * vec4(suv * 2.0 - 1.0, d, 1.0);
	float scene = -v.z / v.w;
	return clamp((scene + vtx.z) / dist, 0.0, 1.0);
}
#define SOFTF soft_fade(SCREEN_UV, VERTEX, INV_PROJECTION_MATRIX, 1.5)
#else
#define SOFTF 1.0
#endif
"""

const BILLBOARD := """
void vertex() {
	mat4 mw = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	ROTATE
	MODELVIEW_MATRIX = VIEW_MATRIX * mw * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
"""
const PARTICLE_ROTATE := """mw = mw * mat4(vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0),
		vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	seed = INSTANCE_CUSTOM.x;"""

# Clock-driven ribbons, all ships of one kind in one MultiMesh (one draw). Each instance's data rides in its instance
# transform, colour and custom data (the shader never uses them as a transform):
#   MODEL_MATRIX[0] start point in world space (layout position + ship-local offset; the shader adds the drift)
#   MODEL_MATRIX[1] direction times length (kinds 0, 1: kind 1 grows its own length), aim (kind 2), arrival direction (3)
#   MODEL_MATRIX[2] (start width, end width, noise seed)
#   MODEL_MATRIX[3] colour at the start;  COLOR.rgb colour at the end;  INSTANCE_CUSTOM (start time, sputter, -, -)
# kind 0 = fixed to a ship (engine plume and trail, beam), 1 = flame tongue, 2 = tracer (flies from where the gun was
# when it fired), 3 = incoming shell (arrives at the start point at the end of its window).
const RIBBON_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform int kind = 0;
uniform float period = 4.0;
uniform float dur = 1e9;
uniform float env_in = 0.0;
uniform float env_out = 0.0;
uniform int decay_env = 0;
uniform float energy = 4.0;
uniform float core = 0.0;
uniform float noise_amt = 0.0;
uniform float noise_scale = 0.3;
uniform float scroll = 0.0;
uniform float waver = 0.0;
uniform float fade_in = 0.02;
uniform float fade_out = 0.8;
uniform float flicker = 0.0;
uniform float decay = 0.0;
varying float vlen;
varying float valpha;
varying vec3 v_ta;
varying vec3 v_tb;
varying float v_seed;
""" + NOISE + TIMING + """
void vertex() {
	vec3 P = MODEL_MATRIX[0].xyz;
	vec3 D = MODEL_MATRIX[1].xyz;
	vec3 W = MODEL_MATRIX[2].xyz;
	v_ta = MODEL_MATRIX[3].xyz;
	v_tb = COLOR.rgb;
	v_seed = W.z;
	float t0 = INSTANCE_CUSTOM.x;
	float t = scene_t;
	float a = loop_age(t, t0, period);
	float al = (a >= 0.0 && a < dur) ? 1.0 : 0.0;
	if (env_in > 0.0) { al *= smoothstep(0.0, env_in, a); }
	if (env_out > 0.0) { al *= 1.0 - smoothstep(dur - env_out, dur, a); }
	if (decay_env == 1) { al *= clamp(1.0 - a / dur, 0.0, 1.0); }
	vec3 o;
	vec3 ax;
	if (kind == 2) {
		vec3 p0 = P + vec3(drift_x(t - a), 0.0, 0.0);
		float dist = max(length(D), 1e-3);
		vec3 d = D / dist;
		float run = max(a, 0.0) * 160.0;
		float head = min(run, dist);
		float tail = clamp(run - 7.0, 0.0, dist);
		al *= run < dist + 1.0 ? 1.0 : 0.0;
		o = p0 + d * tail;
		ax = d * max(head - tail, 0.05);
	} else if (kind == 3) {
		al = (a >= dur - 0.375 && a < dur) ? 1.0 : 0.0;
		float togo = (dur - a) * 160.0;
		o = P + vec3(drift_x(t), 0.0, 0.0) + D * (togo + 7.0);
		ax = -D * 7.0;
	} else {
		o = P + vec3(drift_x(t), 0.0, 0.0);
		ax = kind == 1 ? D * (3.0 + 5.0 * smoothstep(0.0, 0.05, a)) : D;
	}
	al *= drift_fade(t);
	if (INSTANCE_CUSTOM.y > 0.0) { al *= sputter(t); }
	valpha = al;
	float l2 = max(length(ax), 1e-4);
	vec3 dir = ax / l2;
	float s = VERTEX.x + 0.5;
	vec3 p = o + ax * s;
	vec3 up = abs(dir.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
	vec3 b1 = safe_norm(cross(dir, up), vec3(0.0, 0.0, 1.0));
	vec3 b2 = cross(b1, dir);
	p += (b1 * sin(s * l2 * 0.11 - TIME * 1.9 + v_seed) + b2 * sin(s * l2 * 0.07 - TIME * 1.3 + v_seed * 1.7)) * waver * s * s;
	vec3 side = safe_norm(cross(dir, INV_VIEW_MATRIX[3].xyz - p), b1);
	p += side * VERTEX.y * mix(W.x, W.y, s);
	POSITION = al > 0.0 ? PROJECTION_MATRIX * VIEW_MATRIX * vec4(p, 1.0) : vec4(0.0, 0.0, 2.0, 1.0);
	vlen = l2;
}
void fragment() {
	float s = UV.x;
	float y = abs(UV.y - 0.5) * 2.0;
	float prof = exp(-y * y * 4.0);
	float hot = exp(-y * y * 30.0) * core * (1.0 - s * 0.7);
	float n = 1.0;
	if (noise_amt > 0.0) {
		n = mix(1.0, fbm(vec2(s * vlen * noise_scale - TIME * scroll, y * 1.5 + v_seed)) * 1.7, noise_amt);
	}
	float f = smoothstep(0.0, fade_in, s) * (1.0 - smoothstep(fade_out, 1.0, s));
	float fl = 1.0 - flicker * vnoise(vec2(TIME * 23.0, v_seed * 3.1));
	vec3 col = mix(mix(v_ta, v_tb, s), vec3(1.0), clamp(hot, 0.0, 1.0));
	ALBEDO = clamp(col * energy * (prof + hot) * n * f * fl * valpha * exp(-s * decay), 0.0, 512.0);
	ALPHA = 1.0;
}
"""

# Clock-driven glow sprites (billboards), one MultiMesh per kind:
#   MODEL_MATRIX[3] world position (layout position + ship-local offset; drift added here)
#   MODEL_MATRIX[0] aim (impact sprites)
#   INSTANCE_CUSTOM (start time, size, seed, sputter);  COLOR.rgb tint
# shape 0 = flash that fades over dur, 1 = held with a flicker (beam end), 2 = charge then hold (beam emitter),
# 3 = always on (engine core). at_impact = placed where the broadside shell lands.
const SPRITE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float energy = 8.0;
uniform float spikes = 0.0;
uniform float hot = 1.0;
uniform int at_impact = 0;
uniform int shape = 0;
uniform float period = 4.0;
uniform float dur = 0.1;
uniform float grow = 0.0;
varying float valpha;
varying vec3 v_tint;
""" + SOFT + TIMING + """
void vertex() {
	float t = scene_t;
	float t0 = INSTANCE_CUSTOM.x;
	float size = INSTANCE_CUSTOM.y;
	v_tint = COLOR.rgb;
	float a = loop_age(t, t0, period);
	float al = 0.0;
	float sc = size;
	vec3 o = MODEL_MATRIX[3].xyz + vec3(drift_x(t), 0.0, 0.0);
	if (shape == 3) {
		al = 0.9 + 0.1 * sin(t * 41.0 + INSTANCE_CUSTOM.z);
	} else if (a >= 0.0 && a < dur) {
		if (shape == 0) {
			al = 1.0 - a / dur;
			sc = size * (1.0 + grow * a / dur);
		} else if (shape == 1) {
			al = smoothstep(0.0, 0.05, a) * (1.0 - smoothstep(dur - 0.15, dur, a));
			sc = size * (1.0 + 0.25 * sin(t * 47.0)) * max(al, 0.05);
		} else {
			al = a < 0.25 ? smoothstep(0.0, 0.25, a) : 0.6 + 0.2 * sin(t * 60.0);
			sc = size * (0.5 + 1.5 * al);
		}
	}
	if (at_impact == 1) {
		vec3 aim = MODEL_MATRIX[0].xyz;
		float ai = a - length(aim) / 160.0;
		o = MODEL_MATRIX[3].xyz + vec3(drift_x(t - a), 0.0, 0.0) + aim;
		al = (ai >= 0.0 && ai < dur) ? 1.0 - ai / dur : 0.0;
	} else {
		al *= drift_fade(t);
	}
	if (INSTANCE_CUSTOM.w > 0.0) { al *= sputter(t); }
	valpha = al;
	mat4 mw = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), vec4(o, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * mw * mat4(vec4(sc, 0.0, 0.0, 0.0), vec4(0.0, sc, 0.0, 0.0), vec4(0.0, 0.0, sc, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	if (al <= 0.0) { POSITION = vec4(0.0, 0.0, 2.0, 1.0); } else { POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0); }
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float m = exp(-r * r * 5.0) * (1.0 - smoothstep(0.8, 1.0, r));
	float h = exp(-r * r * 18.0) * hot;
	float sp = spikes * (exp(-abs(p.x) * 30.0) + exp(-abs(p.y) * 30.0)) * (1.0 - smoothstep(0.0, 1.0, r));
	ALBEDO = clamp(mix(v_tint, vec3(1.0), clamp(h, 0.0, 1.0)) * energy * valpha * (m + h + sp), 0.0, 512.0) * SOFTF;
	ALPHA = 1.0;
}
"""

# Debris shards (particles): dark hull metal whose torn rim (UV.x near 1) glows and cools over the particle's life.
# Glowing specks on torn metal (debris particles and the physics bodies): soft-edged spots scattered over the piece
# from a 3D noise in its own space, so nothing traces the piece's outline, dim and cooling fast.
const EMBER := """
float ember_h(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float ember_n(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(ember_h(i), ember_h(i + vec3(1.0, 0.0, 0.0)), f.x), mix(ember_h(i + vec3(0.0, 1.0, 0.0)), ember_h(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(ember_h(i + vec3(0.0, 0.0, 1.0)), ember_h(i + vec3(1.0, 0.0, 1.0)), f.x), mix(ember_h(i + vec3(0.0, 1.0, 1.0)), ember_h(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}
vec3 ember(vec3 pos, float warm) {
	float speck = smoothstep(0.6, 0.88, ember_n(pos * 6.0));
	return clamp(vec3(1.0, 0.34, 0.05) * speck * max(warm, 0.0) * 1.4, 0.0, 16.0);
}
"""

const DEBRIS_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform float hot = 1.0;
varying float heat;
varying vec3 lp;
""" + EMBER + """
void vertex() {
	float k = clamp(1.0 - INSTANCE_CUSTOM.y * 2.5, 0.0, 1.0);
	heat = k * k * hot;
	lp = VERTEX;
}
void fragment() {
	ALBEDO = vec3(0.11, 0.105, 0.10);
	METALLIC = 0.65;
	ROUGHNESS = 0.5;
	EMISSION = ember(lp, heat);
}
"""

# A script-placed glow sprite (the destruction flash and core), brightness set by the script.
const GLOW_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec3 tint = vec3(1.0);
uniform float energy = 8.0;
uniform float alpha = 0.0;
uniform float spikes = 0.0;
uniform float hot = 1.0;
varying float seed;
""" + SOFT + BILLBOARD + """
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float m = exp(-r * r * 5.0) * (1.0 - smoothstep(0.8, 1.0, r));
	float h = exp(-r * r * 18.0) * hot;
	float sp = spikes * (exp(-abs(p.x) * 30.0) + exp(-abs(p.y) * 30.0)) * (1.0 - smoothstep(0.0, 1.0, r));
	ALBEDO = clamp(mix(tint, vec3(1.0), clamp(h, 0.0, 1.0)) * energy * alpha * (m + h + sp), 0.0, 512.0) * SOFTF;
	ALPHA = 1.0;
}
"""

const FLAME_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float energy = 3.5;
varying float seed;
""" + NOISE + SOFT + BILLBOARD + """
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float n = fbm(p * 2.2 + vec2(seed * 3.0, seed * 1.3));
	float m = clamp(1.0 - r / (0.55 + 0.45 * n), 0.0, 1.0);
	ALBEDO = clamp(COLOR.rgb * energy * m * m * COLOR.a * (0.6 + 0.8 * n), 0.0, 512.0) * SOFTF;
	ALPHA = 1.0;
}
"""

# Lit smoke: wispy, eroded by two octaves of noise, lit with a gently domed normal.
const SMOKE_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, specular_disabled;
varying float seed;
""" + NOISE + SOFT + BILLBOARD + """
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float n = fbm(p * 2.4 + vec2(seed * 2.0, seed));
	float n2 = fbm(p * 5.0 + vec2(seed * 5.0, 3.0));
	float body = 1.0 - smoothstep(0.1, 0.95, r);
	float m = smoothstep(0.25, 0.75, body * (0.55 + 0.9 * n) - n2 * 0.25);
	NORMAL = normalize(vec3(p.x * 0.6, -p.y * 0.6, 1.0));
	ALBEDO = clamp(COLOR.rgb, 0.0, 1.0);
	ROUGHNESS = 1.0;
	ALPHA = clamp(COLOR.a * m * 0.8, 0.0, 1.0) * SOFTF;
}
"""

const SPARK_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float energy = 6.0;
void fragment() {
	ALBEDO = clamp(COLOR.rgb * energy * COLOR.a, 0.0, 512.0);
	ALPHA = 1.0;
}
"""

# Clock-driven shield: on the bubble, close to the hit, two thin ripple rings run out from the impact point and fade
# within a few units; a small soft glow marks the impact. Distances are measured in world units on the bubble (the
# ellipsoid's own radii), so a long ship gets the same small ripple as a short one. Additive and mostly transparent.
const SHIELD_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec3 tint = vec3(1.0);
uniform float energy = 1.0;
uniform float t0 = 0.0;
uniform float period = 4.0;
uniform float patchy = 0.0;
uniform vec3 hit_dir = vec3(0.0, 0.0, -1.0);
uniform vec3 radii = vec3(1.0);
uniform float reach = 6.0;
varying vec3 lp;
varying float age;
varying float strength;
""" + NOISE + TIMING + """
void vertex() {
	lp = VERTEX;
	float a = loop_age(scene_t, t0, period);
	age = a;
	strength = (a >= 0.0 && a < 0.6) ? pow(max(1.0 - a / 0.6, 0.0), 1.5) * drift_fade(scene_t) : 0.0;
	if (strength <= 0.0) { POSITION = vec4(0.0, 0.0, 2.0, 1.0); } else { POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0); }
}
void fragment() {
	vec3 d3 = safe_norm(lp, hit_dir);
	float dist = length((d3 - hit_dir) * radii);
	if (dot(d3, hit_dir) < 0.0) { discard; }
	float partial = 1.0 - smoothstep(reach * 0.35, reach, dist);
	float r1 = (dist - (0.4 + age * 9.0)) / 0.11;
	float r2 = (dist - age * 5.5) / 0.08;
	float rings = exp(-r1 * r1) + exp(-r2 * r2) * 0.5;
	// the rings break into arcs: an angular noise around the impact point (no seam: sampled on a circle)
	vec3 tu = safe_norm(cross(hit_dir, abs(hit_dir.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)), vec3(1.0, 0.0, 0.0));
	vec3 tv = cross(hit_dir, tu);
	vec2 around = safe_norm(vec3(dot(d3, tu), dot(d3, tv), 0.0), vec3(1.0, 0.0, 0.0)).xy;
	float arcs = smoothstep(0.3, 0.7, vnoise(around * 2.2 + vec2(t0 * 3.1, age * 2.0)));
	float spot = exp(-dist * dist / 0.25);
	float cells = 0.65 + 0.35 * vnoise(vec2(atan(d3.z, d3.x + 1e-5) * 18.0, d3.y * 26.0));
	float a = strength * partial * (rings * 0.42 * cells * (0.3 + 0.7 * arcs) + spot * 0.12);
	if (patchy > 0.0) {
		float pn = vnoise(d3.xy * 7.0 + vec2(TIME * 3.0, d3.z * 5.0));
		float flick = step(0.32, vnoise(vec2(TIME * 24.0, 1.7)));
		a *= mix(1.0, smoothstep(0.38, 0.62, pn) * flick, patchy);
	}
	ALBEDO = clamp(tint * energy * a, 0.0, 512.0);
	ALPHA = 1.0;
}
"""

const SHOCK_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float alpha = 0.0;
uniform vec3 tint = vec3(0.85, 0.88, 1.0);
uniform float energy = 1.5;
""" + NOISE + """
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float q1 = (r - 0.92) / 0.03;
	float q2 = (r - 0.82) / 0.14;
	float ring = exp(-q1 * q1);
	float haze = exp(-q2 * q2) * 0.35;
	float n = vnoise(vec2(atan(p.y, p.x + 1e-5) * 9.0, r * 6.0));
	ALBEDO = clamp(tint * energy * alpha * (ring + haze) * (0.6 + 0.8 * n) * (1.0 - step(1.0, r)), 0.0, 512.0);
	ALPHA = 1.0;
}
"""

# Torn hull plates around the breach (one merged mesh per ship): dark metal, glowing hot at the torn ends (UV.x).
const SHARD_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform float seed = 0.0;
void fragment() {
	float h = smoothstep(0.45, 1.0, UV2.x);
	float flick = 0.8 + 0.2 * sin(TIME * 9.0 + seed) * sin(TIME * 5.3 + seed * 2.0);
	ALBEDO = vec3(0.10, 0.095, 0.09);
	METALLIC = 0.6;
	ROUGHNESS = 0.55;
	EMISSION = vec3(1.0, 0.42, 0.08) * h * h * 5.0 * flick;
}
"""

# Compatibility fallback for the breach scorch (no Decal there): a disc on the hull with the same textures.
const SCORCH_DISC_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;
uniform sampler2D alb : source_color, filter_linear_mipmap;
uniform sampler2D emi : source_color, filter_linear_mipmap;
uniform float emission_energy = 3.0;
void fragment() {
	vec4 a = texture(alb, UV);
	ALBEDO = a.rgb;
	ROUGHNESS = 0.9;
	EMISSION = texture(emi, UV).rgb * clamp(emission_energy * (0.85 + 0.15 * sin(TIME * 9.0)), 0.0, 64.0);
	ALPHA = clamp(a.a, 0.0, 1.0);
}
"""

# Rich: the breach hole with real depth, by parallax occlusion mapping on a disc lying on the hull (the hull itself is not
# cut). A jagged crater height field is ray-marched in tangent space; its floor glows like molten metal.
const HOLE_SHADER := """
shader_type spatial;
render_mode cull_back;
uniform float depth = 0.9;
""" + NOISE + """
float crater(vec2 uv) {
	float r = length(uv);
	float a = atan(uv.y, uv.x + 1e-5);
	float jag = 0.82 + 0.1 * sin(a * 7.0) + 0.08 * vnoise(vec2(a * 3.0, 1.0));
	return smoothstep(jag, jag - 0.25, r) * (0.75 + 0.25 * vnoise(uv * 6.0));
}
void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r0 = length(uv);
	float a0 = atan(uv.y, uv.x + 1e-5);
	if (r0 > 0.82 + 0.1 * sin(a0 * 7.0) + 0.08 * vnoise(vec2(a0 * 3.0, 1.0))) {
		discard;
	}
	vec3 vt = safe_norm(vec3(dot(VIEW, TANGENT), dot(VIEW, -BINORMAL), dot(VIEW, NORMAL)), vec3(0.0, 0.0, 1.0));
	vec2 stepv = -vt.xy / max(vt.z, 0.25) * depth / 24.0;
	float layer = 0.0;
	vec2 p = uv;
	for (int i = 0; i < 24; i++) {
		if (crater(p) <= layer) { break; }
		p += stepv;
		layer += 1.0 / 24.0;
	}
	float d = clamp(layer, 0.0, 1.0);
	ALBEDO = vec3(0.06, 0.05, 0.045) * (1.0 - d * 0.7);
	ROUGHNESS = 0.8;
	METALLIC = 0.5;
	float glow = smoothstep(0.55, 1.0, d) * (0.6 + 0.4 * vnoise(p * 9.0 + TIME * 0.7));
	EMISSION = clamp(vec3(1.0, 0.38, 0.07) * glow * 6.0 * (0.85 + 0.15 * sin(TIME * 9.0)), 0.0, 512.0);
}
"""

const NOISE3 := """
float h31(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float n3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(h31(i), h31(i + vec3(1, 0, 0)), f.x), mix(h31(i + vec3(0, 1, 0)), h31(i + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(h31(i + vec3(0, 0, 1)), h31(i + vec3(1, 0, 1)), f.x), mix(h31(i + vec3(0, 1, 1)), h31(i + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z);
}
"""

# Rich, Forward+: true volumetric gas in Godot's froxel fog, shaped by fog shaders inside FogVolumes.
const VENT_FOG := """
shader_type fog;
uniform float density = 3.0;
""" + NOISE3 + """
void fog() {
	float along = UVW.y;
	float r = length(UVW.xz - 0.5) * 2.0;
	float width = mix(0.3, 1.0, along);
	float puff = 0.45 + 0.55 * n3(vec3(TIME * 2.2, 0.0, 0.0));
	float n = n3(WORLD_POSITION * 0.7 - vec3(0.0, TIME * 3.0, 0.0)) * 0.7 + n3(WORLD_POSITION * 1.9 + TIME) * 0.3;
	DENSITY = max((1.0 - smoothstep(width * 0.5, width, r)) * (1.0 - along) * n * density * puff, 0.0);
	ALBEDO = vec3(0.82, 0.84, 0.88);
}
"""
# The four smoke rings of a ship's broadside, as torus distance fields computed from the clock (no script updates).
const RING_FOG := """
shader_type fog;
uniform vec3 base;
uniform vec3 guns[4];
uniform vec3 n = vec3(0.0, 0.15, 1.0);
uniform float t0 = 0.0;
""" + NOISE3 + TIMING + """
void fog() {
	float d = 0.0;
	for (int i = 0; i < 4; i++) {
		float a = loop_age(scene_t, t0 + 0.08 * float(i), 4.0);
		if (a < 0.0 || a > 2.2) { continue; }
		float grow = 1.0 - exp(-a * 2.5);
		vec3 c = base + guns[i] + vec3(drift_x(scene_t - a), 0.0, 0.0) + n * (1.0 + 4.0 * grow) + vec3(0.0, 0.6 * a, 0.0);
		float R = 0.8 + 3.2 * grow;
		vec3 q = WORLD_POSITION - c;
		float h = dot(q, n);
		float rad = length(q - n * h);
		float tube = R * 0.32;
		float sd = length(vec2(rad - R, h)) - tube;
		d += pow(max(1.0 - a / 2.2, 0.0), 1.3) * (1.0 - smoothstep(-tube, tube * 0.3, sd));
	}
	float nn = n3(WORLD_POSITION * 0.9) * 0.6 + 0.4;
	DENSITY = max(d * nn * 2.0, 0.0);
	ALBEDO = vec3(0.35, 0.34, 0.33);
}
"""
const FIREBALL_FOG := """
shader_type fog;
uniform float age = -1.0;
""" + NOISE3 + """
void fog() {
	if (age < 0.0) { DENSITY = 0.0; } else {
		float r = length(UVW - 0.5) * 2.0;
		float n = n3(WORLD_POSITION * 0.25 + vec3(0.0, -age * 2.0, 0.0)) * 0.65 + n3(WORLD_POSITION * 0.8) * 0.35;
		float body = (1.0 - smoothstep(0.35, 1.0, r + (n - 0.5) * 0.5)) * smoothstep(5.0, 1.5, age);
		float heat = clamp(1.0 - age / 1.2, 0.0, 1.0);
		DENSITY = max(body * 0.9, 0.0);
		ALBEDO = mix(vec3(0.12, 0.11, 0.10), vec3(0.4, 0.2, 0.1), heat);
		EMISSION = clamp(vec3(1.0, 0.45, 0.12) * heat * heat * 6.0 * (1.0 - r), 0.0, 64.0);
	}
}
"""

var notes: PackedStringArray = []
var phys = null
var rich := false
var maxm := false
var stagger := STAGGER
var boom_every := BOOM_EVERY
var fixed_seed := false
var compat := false
var ships: Array = []
var wreck := {}
var prewarm := false
var _now := 0.0
# One-shot particle systems are hidden once their burst is over (fired time + lifetime), so idle systems leave the
# render server's particle update list and its instance updates instead of idling there for 1.2 lifetimes.
var _live := {}

var _lights: Array = []
var _shake: Array = []
var _rows := {}
var _shared: Array = []
var _shards: Array = []
var _quad: QuadMesh
var _strip: QuadMesh
var _box: BoxMesh
var _spark_mesh: BoxMesh
var _plate: BoxMesh
var _sh := {}
var _mats := {}
var _pm := {}
var _seed := 1
var _rng := RandomNumberGenerator.new()


static var _clock_added := false


static func register_clock() -> void:
	if not _clock_added:
		_clock_added = true
		RenderingServer.global_shader_parameter_add(&"scene_t", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0)


func setup(list: Array, wreck_src: Dictionary, deterministic: bool, is_compat: bool, opts := {}) -> void:
	register_clock()
	rich = bool(opts.get("rich", false))
	maxm = bool(opts.get("max", false))
	stagger = float(opts.get("stagger", STAGGER))
	boom_every = float(opts.get("boom_every", BOOM_EVERY))
	fixed_seed = deterministic
	compat = is_compat
	_rng.seed = 2610
	_quad = QuadMesh.new()
	_quad.size = Vector2(1, 1)
	_strip = QuadMesh.new()
	_strip.size = Vector2(1, 1)
	_strip.subdivide_width = 32
	_box = BoxMesh.new()
	_box.size = Vector3(1, 1, 1)
	_spark_mesh = BoxMesh.new()
	_spark_mesh.size = Vector3(0.06, 1.0, 0.06)
	_plate = BoxMesh.new()
	_plate.size = Vector3(1.0, 0.18, 0.6)
	var soft := rich and not compat
	_sh["ribbon"] = _shader(RIBBON_SHADER)
	_sh["sprite"] = _shader(_soft(SPRITE_SHADER, soft))
	_sh["glow"] = _shader(_soft(GLOW_SHADER.replace("ROTATE", ""), soft))
	_sh["shield"] = _shader(SHIELD_SHADER)
	_sh["shock"] = _shader(SHOCK_SHADER)
	_sh["shard"] = _shader(SHARD_SHADER)
	_sh["disc"] = _shader(SCORCH_DISC_SHADER)
	_mats["flame"] = _mat(_shader(_soft(FLAME_SHADER.replace("ROTATE", PARTICLE_ROTATE), soft)))
	_mats["smoke"] = _mat(_shader(_soft(SMOKE_SHADER.replace("ROTATE", PARTICLE_ROTATE), soft)))
	_mats["spark"] = _mat(_shader(SPARK_SHADER))
	if soft:
		notes.append("rich: soft particles (flame, smoke and glow sprites fade into hull depth; hand-written, reads the depth texture)")
	if rich:
		_sh["hole"] = _shader(HOLE_SHADER)
		if not compat:
			_sh["vent_fog"] = _shader(VENT_FOG)
			_sh["ring_fog"] = _shader(RING_FOG)
			_sh["fire_fog"] = _shader(FIREBALL_FOG)
			notes.append("rich: volumetric fog (FogVolume with fog shaders) for breach venting, smoke rings and the fireball")
		notes.append("rich: breach holes with depth by parallax occlusion mapping (hand-written), a light per gun and per impact")
	_mats["debris"] = _ship_mat(_shader(DEBRIS_SHADER), {"hot": 0.25})
	_mats["hot_debris"] = _ship_mat(_shader(DEBRIS_SHADER), {"hot": 1.0})
	for sz in [1.0, 1.0, 1.0]:
		_shards.append(shard_mesh(_rng, sz)[0])
	_build_process_materials()
	for key in ["gas", "breach_fire", "breach_debris", "breach_sparks", "pop", "soot", "hit_sparks", "hit_debris", "puff",
			"fountain", "edge_fire", "edge_smoke", "edge_squib"]:
		(_pm[key] as ParticleProcessMaterial).inherit_velocity_ratio = 1.0
	if maxm:
		_detail_normals(list)
	var tex := _breach_textures()
	for i in list.size():
		ships.append(_build_ship(i, list[i], tex))
	_flush_multimeshes()
	_build_shared_breach()
	_build_wreck(wreck_src)


func _soft(code: String, on: bool) -> String:
	return code.replace("shader_type spatial;", "shader_type spatial;\n#define SOFT") if on else code


# Max: a tiling micro-detail normal layer on every hull material (built-in StandardMaterial3D detail, triplanar so the
# barge without a second UV set gets it too; the noise normal map is generated by Godot's NoiseTexture2D).
func _detail_normals(list: Array) -> void:
	var nt := NoiseTexture2D.new()
	nt.width = 512
	nt.height = 512
	nt.seamless = true
	nt.as_normal_map = true
	nt.bump_strength = 6.0
	var fn := FastNoiseLite.new()
	fn.frequency = 0.05
	fn.fractal_octaves = 4
	nt.noise = fn
	# the detail layer also blends a detail albedo; a white one multiplied in leaves each hull's own colour untouched
	var wimg := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	wimg.fill(Color.WHITE)
	var white := ImageTexture.create_from_image(wimg)
	var done := {}
	for s in list:
		for m in s.get("meshes", []):
			var mesh: Mesh = (m as MeshInstance3D).mesh
			for si in mesh.get_surface_count():
				var mat := mesh.surface_get_material(si) as StandardMaterial3D
				if mat == null or done.has(mat):
					continue
				done[mat] = true
				mat.detail_enabled = true
				mat.detail_albedo = white
				mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
				mat.detail_normal = nt
				mat.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
				mat.uv2_triplanar = true
				mat.uv2_scale = Vector3(30, 30, 30)
	notes.append("max: detail normal layer on %d hull materials" % done.size())


func active_lights() -> int:
	var n := 0
	for l in _lights:
		var o := l as OmniLight3D
		if o.visible and o.light_energy > 0.05 and o.is_visible_in_tree():
			n += 1
	return n


# Weight-scaled screen shake (max mode): every big event pushes an impulse that decays and falls off with distance.
func _kick(t: float, at: Vector3, weight: float) -> void:
	if not maxm:
		return
	_shake.append([t, at, weight])
	if _shake.size() > 48:
		_shake.pop_front()


func shake_offset(t: float, cam_pos: Vector3) -> Vector3:
	var amp := 0.0
	for k in _shake:
		var age: float = t - float(k[0])
		if age < 0.0 or age > 1.5:
			continue
		var dist := cam_pos.distance_to(k[1])
		amp += float(k[2]) * exp(-age * 6.0) / (1.0 + dist / 40.0)
	amp = minf(amp, 3.0)
	return Vector3(sin(t * 61.0) + sin(t * 23.0) * 0.5, sin(t * 53.0 + 1.3) + sin(t * 31.0) * 0.5, sin(t * 47.0 + 2.1)) * amp * 0.5


# ---------------------------------------------------------------- per frame

func update(t: float) -> void:
	RenderingServer.global_shader_parameter_set(&"scene_t", t)
	_now = t
	if prewarm:
		return
	# every ship drifts by the same offset, so the shared breach emitters ride along with one move
	var q := fposmod(DRIFT_SPEED * t + DRIFT_SPAN * 0.5, DRIFT_SPAN)
	var fade := clampf(minf(q, DRIFT_SPAN - q) / DRIFT_SPEED / DRIFT_FADE, 0.0, 1.0)
	var live := fade > 0.02
	for p in _shared:
		var gp := p as GPUParticles3D
		gp.position = Vector3(q - DRIFT_SPAN * 0.5, 0, 0)
		if gp.emitting != live:
			gp.emitting = live
	if _shared.size() > 0:
		(_shared[0] as GPUParticles3D).amount_ratio = maxf(clampf(0.35 + 0.65 * _smooth_noise(t * 2.2), 0.15, 1.0) * fade, 0.001)
		for i in range(1, _shared.size()):
			(_shared[i] as GPUParticles3D).amount_ratio = maxf(fade, 0.001)
	if phys != null:
		phys.now = t
	for i in ships.size():
		_update_ship(ships[i], t, t - stagger * i, q, fade)
	_update_wreck(t)
	_reap()


# Load-time warm-up (main.gd): every effect drawn, every particle system fired, the hulls half transparent, so each
# material and pipeline variant is compiled before the measured window.
func show_everything(on: bool) -> void:
	prewarm = on
	for e in ships:
		if e.has("shield"):
			(e["shield"] as Node3D).visible = on
		for m in e["meshes"]:
			(m as GeometryInstance3D).transparency = 0.5 if on else 0.0
		e["fade"] = -1.0
		for p in e["oneshots"]:
			_fire(p)
		(e["beam_sparks"] as GPUParticles3D).emitting = on
		(e["beam_sparks"] as GPUParticles3D).visible = on
		for l in e["lights"]:
			(l as OmniLight3D).visible = on
			(l as OmniLight3D).light_energy = 1.0
	if not wreck.is_empty():
		for c in wreck["chunks"]:
			(c["node"] as Node3D).visible = on
			(c["mesh"] as GeometryInstance3D).transparency = 0.5 if on else 0.0
			for key in ["fire", "smoke", "squibs"]:
				(c[key] as GPUParticles3D).emitting = on
		for key in ["fireball", "smoke", "embers", "debris", "pre_squibs"]:
			_fire(wreck[key])
		(wreck["whole"] as GeometryInstance3D).transparency = 0.5 if on else 0.0
		for key in ["flash", "core", "shock"]:
			(wreck[key] as Node3D).visible = on
	if phys != null and on:
		phys.spawn(WRECK_POS, Vector3.ZERO, 6, 0.6, 4.0)
	if not on:
		reset_triggers()


func reset_triggers() -> void:
	for e in ships:
		e["last_volley"] = -1
		e["last_impact"] = -1
		e["last_hit"] = -1
		e["breach"]["last_sparks"] = -1
		e["breach"]["last_pop"] = -1
		(e["beam_sparks"] as GPUParticles3D).emitting = false
	if not wreck.is_empty():
		wreck["last_squib"] = 0
		wreck["last_boom"] = -1
	_shake.clear()


func _update_ship(e: Dictionary, t: float, u: float, q: float, fade: float) -> void:
	var root: Node3D = e["root"]
	root.position = e["base"] + Vector3(q - DRIFT_SPAN * 0.5, 0, 0)
	if fade != e["fade"]:
		e["fade"] = fade
		for m in e["meshes"]:
			(m as GeometryInstance3D).transparency = 1.0 - fade
		var br0: Dictionary = e["breach"]
		if br0.has("decal"):
			(br0["decal"] as Decal).modulate = Color(1, 1, 1, fade)
		(br0["shards"] as GeometryInstance3D).transparency = 1.0 - fade
		if e["corsair"]:
			(e["soot"] as GPUParticles3D).emitting = fade > 0.02
	var a := -1.0 if u < 0.0 else fmod(u, LOOP)
	if e["corsair"]:
		(e["soot"] as GPUParticles3D).amount_ratio = clampf((1.2 - _sputter(t)) * fade, 0.05, 1.0)

	# 2. broadside: the volley's smoke rings, the impacts' sparks and debris (one system each, all four guns), the light
	var vc := _cycle(u)
	if vc > int(e["last_volley"]):
		e["last_volley"] = vc
		_fire_at(e["ring_smoke"], root.position)
		_kick(t, root.position + e["guns"][0]["pos"], 0.3)
	var ic := _cycle(u - float(e["flight"]))
	if ic > int(e["last_impact"]):
		e["last_impact"] = ic
		var at: Vector3 = e["base"] + Vector3(_drift_x(t - float(e["flight"])), 0, 0)
		_fire_at(e["impact_sparks"], at)
		_fire_at(e["impact_debris"], at)
		if phys != null:
			for g in e["guns"]:
				phys.spawn(at + g["pos"] + g["aim"], (g["aim"] as Vector3).normalized() * 6.0, 3, 0.25)
	var gun_light := 0.0
	var gun_at := Vector3.ZERO
	if a >= 0.0 and a < 0.6:
		for k in e["guns"].size():
			var g: Dictionary = e["guns"][k]
			var ak: float = a - GUN_GAP * k
			var f := 1.0 - ak / 0.1 if ak >= 0.0 and ak < 0.1 else 0.0
			if f > gun_light:
				gun_light = f
				gun_at = g["pos"] + g["n"] * 1.5
			if g.has("light"):
				var gl2: OmniLight3D = g["light"]
				gl2.visible = f > 0.0
				if f > 0.0:
					gl2.light_energy = 6.0 * f * fade
			if g.has("imp_light"):
				var ai: float = ak - float(g["flight"])
				var il: OmniLight3D = g["imp_light"]
				il.visible = ai >= 0.0 and ai < 0.3
				if il.visible:
					il.position = e["base"] + Vector3(_drift_x(t - ak), 0, 0) + g["pos"] + g["aim"]
					il.light_energy = 5.0 * (1.0 - ai / 0.3)
	if e.has("gun_light"):
		var gl: OmniLight3D = e["gun_light"]
		gl.visible = gun_light > 0.0
		if gl.visible:
			gl.position = gun_at
			gl.light_energy = 6.0 * gun_light * fade

	# 3. beam: sparks on and off, the two lights
	var ab := a - BEAM_AT
	var on := ab >= 0.0 and ab < BEAM_T and fade > 0.0
	var bs: GPUParticles3D = e["beam_sparks"]
	if on != bs.emitting:
		bs.emitting = on
		if on:
			bs.visible = true
			_live.erase(bs)
		else:
			_live[bs] = _now + bs.lifetime + 0.1
		if on:
			_kick(t, root.position + e["bow_at"], 0.25)
	var cf := 0.0
	if ab >= -CHARGE_T and ab < 0.0:
		cf = smoothstep(-CHARGE_T, 0.0, ab)
	elif on:
		cf = 0.7
	var benv := 0.0
	if on:
		benv = smoothstep(0.0, 0.05, ab) * (1.0 - smoothstep(BEAM_T - 0.15, BEAM_T, ab)) * fade
	var bl: OmniLight3D = e["beam_light"]
	bl.visible = cf > 0.0 or on
	if bl.visible:
		bl.light_energy = 3.0 * cf * fade + 5.0 * benv
	var bl2: OmniLight3D = e["beam_hit_light"]
	bl2.visible = on
	if on:
		bl2.light_energy = 4.0 * benv

	# 4. the hit
	var ah := a - HIT_AT
	if e.has("shield"):
		var sv := ah >= 0.0 and ah < SHIELD_T
		var sh: Node3D = e["shield"]
		if sh.visible != sv:
			sh.visible = sv
	var hf := (1.0 - ah / 0.25) * fade if ah >= 0.0 and ah < 0.25 else 0.0
	var hcy := _cycle(u - HIT_AT)
	if hcy > int(e["last_hit"]):
		e["last_hit"] = hcy
		_kick(t, root.position + e["hit_at"], 0.35)
		if not e["shielded"]:
			for key in ["hit_sparks", "hit_debris", "hit_fire"]:
				_fire(e[key])
			if phys != null:
				phys.spawn(root.position + e["hit_at"], Vector3(DRIFT_SPEED, 2, -8), 4, 0.3)
	var hl: OmniLight3D = e["hit_light"]
	hl.visible = hf > 0.0
	if hl.visible:
		hl.light_energy = 5.0 * hf

	# 5. breach: fixed timers with per-ship offsets: a spark shower every 2.3 s (see _spark_off), a secondary pop every
	# 3.7 s from 0.6 + 0.55 i as in the Babylon half (the Hegemony pops at 1.15 and 4.85, so the 3.0 still shows the hole)
	var br: Dictionary = e["breach"]
	var idx: int = e["idx"]
	var sc := _cycle_n(t - _spark_off(idx), SPARKS_EVERY)
	if sc > int(br["last_sparks"]):
		br["last_sparks"] = sc
		_fire(br["sparks"])
	var pt := t - _pop_off(idx)
	var pc := _cycle_n(pt, POP_EVERY)
	var pop := 0.0
	if pt >= 0.0:
		var pa := fmod(pt, POP_EVERY)
		if pa < 0.18:
			pop = 1.0 - pa / 0.18
	if pc > int(br["last_pop"]):
		br["last_pop"] = pc
		_fire(br["pop_fire"])
		_fire(br["sparks"])
		var bf: Node3D = br["frame"]
		_kick(t, bf.global_position, 0.15)
		if phys != null:
			phys.spawn(bf.global_position, bf.global_transform.basis.y * 5.0 + Vector3(DRIFT_SPEED, 0, 0), 2, 0.2)
	var flick := 0.75 + 0.25 * _smooth_noise(t * 9.0 + idx * 3.3)
	(br["light"] as OmniLight3D).light_energy = (1.4 * flick + 7.0 * pop) * fade
	if br.has("decal"):
		(br["decal"] as Decal).emission_energy = 2.6 * flick + 4.0 * pop


func _update_wreck(t: float) -> void:
	if wreck.is_empty():
		return
	var whole: MeshInstance3D = wreck["whole"]
	var tt := t - BREAK_OFFSET  # breaks when tt crosses a multiple of the period
	var since := -1.0  # time since the last break (none yet before the first)
	var p := tt
	if tt >= boom_every:
		since = fmod(tt, boom_every)
		p = since
	var to_next := boom_every - p
	# the whole ship: hidden after a break, fading back in 2 s before the next one
	var vis := 1.0
	if since >= 0.0 and since < boom_every - 2.0:
		vis = 0.0
	elif since >= 0.0:
		vis = clampf(since - (boom_every - 2.0), 0.0, 1.0)
	whole.visible = vis > 0.0
	whole.transparency = 1.0 - vis
	# squibs on the hull from 0.6 s before the break; the flash builds from 0.5 s before and peaks at the break
	var squib_c := int(floorf((tt + 0.6) / boom_every))
	if squib_c > int(wreck["last_squib"]):
		wreck["last_squib"] = squib_c
		_fire(wreck["pre_squibs"])
	var a := since
	var flash := 0.0
	if to_next < 0.5:
		var kk := clampf((0.5 - to_next) / 0.5, 0.0, 1.0)
		flash = kk * kk * (3.0 - 2.0 * kk) * 0.55
	if a >= 0.0:
		flash = maxf(flash, 0.55 + 0.45 * a / 0.05 if a < 0.05 else exp(-(a - 0.05) * 4.0))
	var fl: MeshInstance3D = wreck["flash"]
	fl.visible = flash > 0.003
	if fl.visible:
		fl.scale = Vector3.ONE * (10.0 + 45.0 * flash)
		(fl.material_override as ShaderMaterial).set_shader_parameter("alpha", flash)
	var lt: OmniLight3D = wreck["light"]
	lt.visible = flash > 0.003
	lt.light_energy = 40.0 * flash
	var core: MeshInstance3D = wreck["core"]
	core.visible = a >= 0.0 and a < 0.9
	if core.visible:
		core.scale = Vector3.ONE * 26.0 * (0.3 + 0.7 * smoothstep(0.0, 0.4, a))
		(core.material_override as ShaderMaterial).set_shader_parameter("alpha", pow(maxf(1.0 - a / 0.9, 0.0), 1.5))
	var sw: MeshInstance3D = wreck["shock"]
	sw.visible = a >= 0.0 and a < 2.0
	if sw.visible:
		var r := 4.0 + 75.0 * (1.0 - exp(-a * 1.8))
		sw.scale = Vector3(r * 2.0, 1.0, r * 2.0)
		(sw.material_override as ShaderMaterial).set_shader_parameter("alpha", pow(maxf(1.0 - a / 2.0, 0.0), 3.0))
	var bc := _cycle_n(tt - boom_every, boom_every)
	if bc > int(wreck["last_boom"]):
		wreck["last_boom"] = bc
		for key in ["fireball", "smoke", "embers", "debris"]:
			_fire(wreck[key])
		_kick(t, WRECK_POS, 2.5)
		if phys != null:
			phys.spawn(WRECK_POS, Vector3.ZERO, 30, 0.6, 14.0)
			for c in wreck["chunks"]:
				phys.launch(c["node"], Transform3D(Basis(), WRECK_POS + c["start"]), c["vel"] * 1.6, c["axis"] * c["spin"] * 2.0)
	if wreck.has("fire_light"):
		var fl3: OmniLight3D = wreck["fire_light"]
		fl3.visible = a >= 0.0 and a < 2.5
		if fl3.visible:
			fl3.light_energy = 25.0 * exp(-a * 1.6)
	if wreck.has("fire_fog"):
		var fv2: FogVolume = wreck["fire_fog"]
		fv2.visible = a >= 0.0 and a < 5.0
		if fv2.visible:
			fv2.size = Vector3.ONE * (14.0 + 26.0 * (1.0 - exp(-a * 1.5)))
			(fv2.material as ShaderMaterial).set_shader_parameter("age", a)
	# chunks
	var show_chunks := a >= 0.0 and a < boom_every - 2.0
	for c in wreck["chunks"]:
		var node: Node3D = c["node"]
		node.visible = show_chunks
		var fire: GPUParticles3D = c["fire"]
		var smoke: GPUParticles3D = c["smoke"]
		var squibs: GPUParticles3D = c["squibs"]
		if c.has("light"):
			var cl: OmniLight3D = c["light"]
			cl.visible = show_chunks and a < c["burn_t"]
			if cl.visible:
				cl.light_energy = 3.0 * (0.75 + 0.25 * _smooth_noise(t * 8.0 + float(c["burn_t"])))
		if not show_chunks:
			if fire.emitting or squibs.emitting:
				fire.emitting = false
				smoke.emitting = false
				squibs.emitting = false
			if phys != null and node is RigidBody3D:
				phys.park(node)
			continue
		if not (phys != null and node is RigidBody3D):
			node.transform = Transform3D(Basis(c["axis"], c["spin"] * a), WRECK_POS + c["start"] + c["vel"] * a)
		var cfade := clampf((boom_every - 2.0 - a) / 0.6, 0.0, 1.0)
		(c["mesh"] as GeometryInstance3D).transparency = 1.0 - cfade
		var burning: bool = a < c["burn_t"]
		if fire.emitting != burning:
			fire.emitting = burning
			smoke.emitting = burning
		fire.amount_ratio = clampf(1.0 - a / c["burn_t"] * 0.6, 0.2, 1.0)
		var sq := a < 3.0
		if squibs.emitting != sq:
			squibs.emitting = sq


# ---------------------------------------------------------------- build: ships

func _ship_mat(shader: Shader, params: Dictionary) -> ShaderMaterial:
	var m := _mat(shader)
	for key in params:
		m.set_shader_parameter(key, params[key])
	return m


# The instanced effect kinds: one MultiMesh (one draw) per kind for every ship. Per-kind settings are uniforms; the
# per-instance data (see RIBBON_SHADER and SPRITE_SHADER) is packed into the instance transform, colour and custom data.
func _kinds() -> Dictionary:
	return {
		"core": [_quad, "sprite", {"energy": 6.0, "shape": 3}],
		"plume": [_strip, "ribbon", {"energy": 2.4, "core": 1.0, "noise_amt": 0.85, "noise_scale": 0.6, "scroll": 14.0,
			"fade_in": 0.03, "fade_out": 0.35, "flicker": 0.35, "decay": 3.0}],
		"trail": [_strip, "ribbon", {"energy": 0.35, "core": 0.15, "noise_amt": 0.75, "noise_scale": 0.12, "scroll": 4.0,
			"waver": 2.2, "fade_in": 0.02, "fade_out": 0.25, "decay": 1.2}],
		"flash": [_quad, "sprite", {"energy": 12.0, "shape": 0, "dur": 0.1, "grow": -0.3}],
		"tongue": [_strip, "ribbon", {"kind": 1, "dur": 0.16, "decay_env": 1, "energy": 6.0, "core": 1.0, "noise_amt": 0.5,
			"noise_scale": 1.5, "scroll": 30.0, "fade_in": 0.05, "fade_out": 0.5}],
		"tracer": [_strip, "ribbon", {"kind": 2, "dur": 0.8, "energy": 7.0, "core": 1.0, "fade_in": 0.6, "fade_out": 0.97}],
		"impact": [_quad, "sprite", {"energy": 9.0, "shape": 0, "dur": 0.15, "at_impact": 1}],
		"charge": [_quad, "sprite", {"energy": 10.0, "shape": 2, "dur": CHARGE_T + BEAM_T}],
		"beam_core": [_strip, "ribbon", {"dur": BEAM_T, "env_in": 0.05, "env_out": 0.15, "energy": 9.0, "core": 1.0,
			"noise_amt": 0.25, "noise_scale": 0.6, "scroll": 25.0, "fade_in": 0.01, "fade_out": 0.985, "flicker": 0.15}],
		"beam_glow": [_strip, "ribbon", {"dur": BEAM_T, "env_in": 0.05, "env_out": 0.15, "energy": 3.5, "noise_amt": 0.65,
			"noise_scale": 0.25, "scroll": 18.0, "fade_in": 0.01, "fade_out": 0.97, "flicker": 0.3}],
		"beam_end": [_quad, "sprite", {"energy": 10.0, "shape": 1, "dur": BEAM_T}],
		"incoming": [_strip, "ribbon", {"kind": 3, "dur": HIT_AT, "energy": 7.0, "core": 1.0, "fade_in": 0.6, "fade_out": 0.98}],
		"hit_core": [_quad, "sprite", {"energy": 6.0, "shape": 0, "dur": 0.25, "grow": 0.5}],
		"pop": [_quad, "sprite", {"energy": 5.0, "hot": 0.6, "shape": 0, "period": POP_EVERY, "dur": 0.18, "grow": 0.8}],
	}


func _add(kind: String, c0: Vector3, c1: Vector3, c2: Vector3, origin: Vector3, custom: Color, col: Color) -> void:
	if not _rows.has(kind):
		_rows[kind] = []
	_rows[kind].append([Transform3D(Basis(c0, c1, c2), origin), custom, col])


func _ribbon_row(kind: String, start: Vector3, d: Vector3, wa: float, wb: float, seed: float, ta: Color, tb: Color,
		t0 := -1000.0, sput := 0.0) -> void:
	_add(kind, start, d, Vector3(wa, wb, seed), _v3(ta), Color(t0, sput, 0, 0), tb)


func _sprite_row(kind: String, at: Vector3, size: float, tint: Color, t0 := -1000.0, seed := 0.0, sput := 0.0,
		aim := Vector3.ZERO) -> void:
	_add(kind, aim, Vector3.ZERO, Vector3.ZERO, at, Color(t0, size, seed, sput), tint)


func _flush_multimeshes() -> void:
	var kinds := _kinds()
	for kind in _rows:
		var spec: Array = kinds[kind]
		var rows: Array = _rows[kind]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = spec[0]
		mm.instance_count = rows.size()
		for i in rows.size():
			mm.set_instance_transform(i, rows[i][0])
			mm.set_instance_custom_data(i, rows[i][1])
			mm.set_instance_color(i, rows[i][2])
		mm.custom_aabb = WORLD_AABB
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "fx_" + kind
		mmi.multimesh = mm
		mmi.material_override = _ship_mat(_sh[spec[1]], spec[2])
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.custom_aabb = WORLD_AABB
		add_child(mmi)
	notes.append("effects: %d instanced kinds (one draw each) for %d ships" % [_rows.size(), ships.size()])


# Points texture for a GPUParticles3D emitting from many points at once (EMISSION_SHAPE_POINTS / DIRECTED_POINTS).
func _points_tex(pts: PackedVector3Array) -> ImageTexture:
	var data := PackedFloat32Array()
	for p in pts:
		data.append_array([p.x, p.y, p.z])
	var img := Image.create_from_data(pts.size(), 1, false, Image.FORMAT_RGBF, data.to_byte_array())
	return ImageTexture.create_from_image(img)


func _points_pm(base_pm: ParticleProcessMaterial, pts: PackedVector3Array, nrm: PackedVector3Array) -> ParticleProcessMaterial:
	var m := base_pm.duplicate() as ParticleProcessMaterial
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_DIRECTED_POINTS if nrm.size() > 0 else ParticleProcessMaterial.EMISSION_SHAPE_POINTS
	m.emission_point_texture = _points_tex(pts)
	m.emission_point_count = pts.size()
	if nrm.size() > 0:
		m.emission_normal_texture = _points_tex(nrm)
	return m


# The continuous breach emitters of every ship in three shared systems (gas, fire, tumbling debris), each emitting from
# all the breaches at once; update() moves them with the common drift.
func _build_shared_breach() -> void:
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	var n := 0
	for e in ships:
		var br: Dictionary = e["breach"]
		var p: Vector3 = e["base"] + br["at"]
		var bn: Vector3 = br["n"]
		var sc: float = br["scale"]
		for j in 6:
			var off := Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)) * 0.35 * sc
			pts.append(p + bn * 0.2 + off - bn * off.dot(bn))
			nrm.append(bn)
		n += 1
	if n == 0:
		return
	var gas := _particles(self, _points_pm(_pm["gas"], pts, nrm), 48 * n, 1.4, _quad, _mats["smoke"], Vector3.ZERO, false)
	var fire := _particles(self, _points_pm(_pm["breach_fire"], pts, nrm), 28 * n, 0.45, _quad, _mats["flame"], Vector3.ZERO, false)
	var deb := _particles(self, _points_pm(_pm["breach_debris"], pts, nrm), 10 * n, 3.0, _shards[0], _mats["debris"], Vector3.ZERO, false)
	for p in [gas, fire, deb]:
		(p as GPUParticles3D).visibility_aabb = WORLD_AABB
		(p as GPUParticles3D).emitting = true
	_shared = [gas, fire, deb]


func _build_ship(i: int, s: Dictionary, tex: Dictionary) -> Dictionary:
	var off := stagger * i
	var base: Vector3 = s["pos"]
	var e := {"idx": i, "root": s["root"], "base": base, "meshes": s["meshes"], "fade": 1.0,
		"corsair": s["name"] == "Corsair", "shielded": s["shield"] != null, "last_hit": -1, "last_volley": -1,
		"last_impact": -1, "oneshots": [], "lights": []}
	var root: Node3D = s["root"]
	var half: Vector3 = s["half"]
	var wcol: Color = s["weapon"]
	var ecol: Color = s["engine"]
	var sput := 1.0 if e["corsair"] else 0.0
	# 1. engines (always on)
	var w: float = s["noz_size"]
	var plume_len := clampf(3.0 * half.z, 7.0, 18.0)
	for nz in s["nozzles"]:
		var sd := _rng.randf() * 10.0
		_sprite_row("core", base + nz, w * 2.2, ecol, -1000.0, sd, sput)
		_ribbon_row("plume", base + nz, Vector3(-plume_len, 0, 0), w * 1.2, w * 0.5, sd, ecol.lerp(Color.WHITE, 0.35), ecol, -1000.0, sput)
		_ribbon_row("trail", base + nz, Vector3(-TRAIL_LEN, 0, 0), w * 0.9, w * 0.3, sd + 3.0, ecol * 0.8, Color(0.30, 0.10, 0.05))
	if e["corsair"]:
		var stern := Vector3(-half.x - 0.5, s["nozzles"][0].y, 0)
		var soot := _particles(root, _pm["soot"], 40, 2.5, _quad, _mats["smoke"], stern, false)
		soot.emitting = true
		e["soot"] = soot
	# 2. broadside: four guns; their smoke rings, impact sparks and impact debris each come from one system per ship
	var guns: Array = []
	var ring_pts := PackedVector3Array()
	var ring_nrm := PackedVector3Array()
	var imp_pts := PackedVector3Array()
	for k in s["guns"].size():
		var gp: Vector3 = s["guns"][k]
		var gn: Vector3 = s["gun_n"][k]
		var aim := Vector3(8.0 + 4.0 * k, 3.0 + _rng.randf() * 4.0, BROADSIDE_RANGE)
		var gt0: float = off + GUN_GAP * k
		var g := {"pos": gp, "n": gn, "aim": aim, "flight": aim.length() / SHELL_SPEED}
		_sprite_row("flash", base + gp + gn * 0.8, 5.0, wcol.lerp(Color.WHITE, 0.3), gt0)
		_ribbon_row("tongue", base + gp, gn, 1.6, 0.2, float(k) * 2.1 + i, Color(1.0, 0.9, 0.7), wcol, gt0)
		_ribbon_row("tracer", base + gp, aim, 0.35, 0.9, 0.0, Color(1.0, 0.95, 0.85), wcol, gt0)
		_sprite_row("impact", base + gp, 4.0, wcol.lerp(Color.WHITE, 0.4), gt0, 0.0, 0.0, aim)
		var bx := _basis_y(gn)
		for j in 16:
			var th := TAU * j / 16.0
			var radial := bx * Vector3(cos(th), 0, sin(th))
			ring_pts.append(gp + gn * 0.8 + radial * 0.85)
			ring_nrm.append((radial * 0.55 + gn * 0.83).normalized())
		imp_pts.append(gp + aim)
		guns.append(g)
	e["guns"] = guns
	e["flight"] = (guns[0]["flight"] as float)
	e["ring_smoke"] = _particles(self, _points_pm(_pm["ring_smoke"], ring_pts, ring_nrm), 26 * guns.size(), 2.2, _quad, _mats["smoke"], Vector3.ZERO)
	e["impact_sparks"] = _particles(self, _points_pm(_pm["impact_sparks"], imp_pts, PackedVector3Array()), 20 * guns.size(), 0.6, _spark_mesh, _mats["spark"], Vector3.ZERO)
	e["impact_debris"] = _particles(self, _points_pm(_pm["impact_debris"], imp_pts, PackedVector3Array()), 10 * guns.size(), 1.6, _shards[1], _mats["hot_debris"], Vector3.ZERO)
	for key in ["ring_smoke", "impact_sparks", "impact_debris"]:
		(e[key] as GPUParticles3D).visibility_aabb = AABB(Vector3(-40, -40, -40), Vector3(120, 80, 160))
		e["oneshots"].append(e[key])
	if rich:
		for g in guns:
			g["light"] = _omni(root, wcol.lerp(Color.WHITE, 0.3), 14.0)
			(g["light"] as OmniLight3D).position = g["pos"] + g["n"] * 1.5
			g["imp_light"] = _omni(self, wcol.lerp(Color.WHITE, 0.4), 18.0)
			e["lights"].append_array([g["light"], g["imp_light"]])
		if not compat:
			var gps: Array = []
			for g in guns:
				gps.append(g["pos"])
			var fv := FogVolume.new()
			fv.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
			fv.size = Vector3(DRIFT_SPAN + 30.0, 22.0, 20.0)
			fv.position = base + Vector3(0, 2.0, (guns[0]["pos"] as Vector3).z + 7.0)
			fv.material = _ship_mat(_sh["ring_fog"], {"base": base, "guns": gps, "t0": off})
			add_child(fv)
	else:
		e["gun_light"] = _omni(root, wcol.lerp(Color.WHITE, 0.3), 16.0)
		e["lights"].append(e["gun_light"])
	# 3. beam
	var bow: Vector3 = s["bow"]
	e["bow_at"] = bow
	var bt0 := off + BEAM_AT
	_sprite_row("charge", base + bow, 3.0, wcol.lerp(Color.WHITE, 0.25), bt0 - CHARGE_T)
	_ribbon_row("beam_core", base + bow, Vector3(BEAM_LEN, 0, 0), 0.9, 0.7, 0.0, Color.WHITE, Color.WHITE, bt0)
	_ribbon_row("beam_glow", base + bow, Vector3(BEAM_LEN, 0, 0), 4.0, 3.2, i * 1.3, wcol, wcol, bt0)
	var end := bow + Vector3(BEAM_LEN, 0, 0)
	_sprite_row("beam_end", base + end, 6.0, wcol.lerp(Color.WHITE, 0.3), bt0)
	e["beam_sparks"] = _particles(root, _pm["fountain"], 60, 0.7, _spark_mesh, _mats["spark"], end, false)
	(e["beam_sparks"] as GPUParticles3D).visible = false
	e["beam_light"] = _omni(root, wcol.lerp(Color.WHITE, 0.3), 18.0)
	(e["beam_light"] as OmniLight3D).position = bow
	e["beam_hit_light"] = _omni(root, wcol.lerp(Color.WHITE, 0.3), 20.0)
	(e["beam_hit_light"] as OmniLight3D).position = end
	e["lights"].append_array([e["beam_light"], e["beam_hit_light"]])
	# 4. incoming shell and the hit
	var shell_col := Color(1.0, 0.75, 0.45)
	var from := Vector3(0.35, 0.25, -1.0).normalized()
	if e["shielded"]:
		var radii := half * 1.15 + Vector3(1.5, 1.5, 1.5)
		var hd := Vector3(0.15, 0.2, -1.0).normalized()
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		sphere.radial_segments = 48
		sphere.rings = 24
		var shm := MeshInstance3D.new()
		shm.mesh = sphere
		shm.material_override = _ship_mat(_sh["shield"], {"tint": _v3(s["shield"]), "hit_dir": hd, "t0": off + HIT_AT,
			"patchy": 1.0 if e["corsair"] else 0.0, "radii": radii, "reach": clampf(minf(radii.x, radii.y) * 0.9, 4.0, 7.0)})
		shm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shm.scale = radii
		shm.visible = false
		root.add_child(shm)
		e["shield"] = shm
		e["hit_at"] = hd * radii
	else:
		var hp2: Vector3 = s["hit"]
		e["hit_at"] = hp2
		_sprite_row("hit_core", base + hp2 + Vector3(0, 0, -0.5), 3.0, shell_col, off + HIT_AT)
		var holder := Node3D.new()
		holder.position = hp2
		holder.basis = _basis_y(Vector3(0, 0.2, -1).normalized())
		root.add_child(holder)
		e["hit_sparks"] = _particles(holder, _pm["hit_sparks"], 36, 0.8, _spark_mesh, _mats["spark"], Vector3.ZERO)
		e["hit_debris"] = _particles(holder, _pm["hit_debris"], 16, 2.0, _shards[2], _mats["hot_debris"], Vector3.ZERO)
		e["hit_fire"] = _particles(holder, _pm["puff"], 12, 0.7, _quad, _mats["flame"], Vector3.ZERO)
		e["oneshots"].append_array([e["hit_sparks"], e["hit_debris"], e["hit_fire"]])
	_ribbon_row("incoming", base + e["hit_at"], from, 0.9, 0.35, 0.0, Color(1.0, 0.7, 0.4), Color(1.0, 0.95, 0.85), off)
	e["hit_light"] = _omni(root, shell_col, 16.0)
	(e["hit_light"] as OmniLight3D).position = e["hit_at"]
	e["lights"].append(e["hit_light"])
	# 5. breach
	e["breach"] = _build_breach(root, s, tex, e)
	return e


func _build_breach(root: Node3D, s: Dictionary, tex: Dictionary, e: Dictionary) -> Dictionary:
	var p: Vector3 = s["breach"]
	var n: Vector3 = s["breach_n"]
	var hole := 2.4 * float(s.get("scale", 1.0))  # about 1/10 of the ship's length
	var br := {"last_sparks": -1, "last_pop": -1, "at": p, "n": n, "scale": float(s.get("scale", 1.0))}
	var frame := Node3D.new()
	frame.name = "breach"
	frame.position = p
	frame.basis = _basis_y(n)
	root.add_child(frame)
	br["frame"] = frame
	if not compat:
		var d := Decal.new()
		d.size = Vector3(hole * 2.2, 2.5, hole * 2.2)
		d.texture_albedo = tex["alb"]
		d.texture_emission = tex["emi"]
		d.texture_normal = tex["nrm"]
		d.emission_energy = 2.6
		d.albedo_mix = 1.0
		d.normal_fade = 0.2
		d.upper_fade = 0.3
		d.lower_fade = 0.3
		frame.add_child(d)
		br["decal"] = d
	else:
		var dm := _mat(_sh["disc"])
		dm.set_shader_parameter("alb", tex["alb"])
		dm.set_shader_parameter("emi", tex["emi"])
		var disc := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(hole * 2.2, hole * 2.2)
		disc.mesh = pm
		disc.material_override = dm
		disc.position = Vector3(0, 0.06, 0)
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		frame.add_child(disc)
		if not notes.has("breach scorch drawn as a disc on the hull (no Decal in Compatibility)"):
			notes.append("breach scorch drawn as a disc on the hull (no Decal in Compatibility)")
	# torn plates peeled outward around the hole, hot at their torn ends, each snapped onto the hull point nearest its
	# place on the rim (so none float or sink); merged into one mesh
	var near_p := PackedVector3Array()
	var near_n := PackedVector3Array()
	var pts: PackedVector3Array = s.get("pts", PackedVector3Array())
	var nrms: PackedVector3Array = s.get("nrm", PackedVector3Array())
	for j in pts.size():
		if pts[j].distance_squared_to(p) < 9.0:
			near_p.append(pts[j])
			near_n.append(nrms[j])
	var fb := frame.basis
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 11
	for k in count:
		var th := TAU * k / count + _rng.randf_range(-0.2, 0.2)
		var radial := fb * Vector3(cos(th), 0, sin(th))
		var tilt := _rng.randf_range(0.5, 1.15)
		var plen := _rng.randf_range(0.45, 0.95)
		var pw := _rng.randf_range(0.22, 0.42)
		var want := p + radial * hole * 0.5 * _rng.randf_range(0.85, 1.05)
		var q := want
		var nq := n
		var best := 1e9
		for j in near_p.size():
			var dd := near_p[j].distance_squared_to(want)
			if dd < best:
				best = dd
				q = near_p[j]
				nq = near_n[j]
		var outw := q - p
		outw = outw - nq * outw.dot(nq)
		if outw.length() < 0.01:
			outw = radial
		outw = outw.normalized()
		var xa := (outw * cos(tilt) + nq * sin(tilt)).normalized()
		var za := xa.cross(nq).normalized()
		var ya := za.cross(xa).normalized()
		var xf := Transform3D(Basis(xa * plen, ya * 0.05, za * pw), q + xa * plen * 0.5 - nq * 0.04)
		_box_into(st, Transform3D(fb.inverse(), Vector3.ZERO) * Transform3D(Basis(), -p) * xf)
	st.generate_normals()
	var shards := MeshInstance3D.new()
	shards.mesh = st.commit()
	shards.material_override = _ship_mat(_sh["shard"], {"seed": float(e["idx"]) * 1.7})
	frame.add_child(shards)
	br["shards"] = shards
	br["sparks"] = _particles(frame, _pm["breach_sparks"], 30, 0.8, _spark_mesh, _mats["spark"], Vector3(0, 0.1, 0))
	br["pop_fire"] = _particles(frame, _pm["pop"], 16, 0.6, _quad, _mats["flame"], Vector3(0, 0.3, 0))
	e["oneshots"].append_array([br["sparks"], br["pop_fire"]])
	_sprite_row("pop", s["pos"] + p + n * 0.6, 2.5, Color(1.0, 0.55, 0.2), _pop_off(int(e["idx"])))
	var lt := _omni(frame, Color(1.0, 0.5, 0.15), 7.0)
	lt.position = Vector3(0, 1.4, 0)
	lt.visible = true
	br["light"] = lt
	if rich:
		var hp := PlaneMesh.new()
		hp.size = Vector2(hole * 0.75, hole * 0.75)
		var hmi := MeshInstance3D.new()
		hmi.mesh = hp
		hmi.material_override = _mat(_sh["hole"])
		hmi.position = Vector3(0, 0.05, 0)
		hmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		frame.add_child(hmi)
		if not compat:
			var fv := FogVolume.new()
			fv.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
			fv.size = Vector3(3.0, 9.0, 3.0) * float(s.get("scale", 1.0))
			fv.position = Vector3(0, fv.size.y * 0.5, 0)
			fv.material = _mat(_sh["vent_fog"])
			frame.add_child(fv)
	return br


# Adds a unit box (x from -0.5 to 0.5) under xf to the surface tool, with UV2.x = 0 at the -x end and 1 at the +x end.
func _box_into(st: SurfaceTool, xf: Transform3D) -> void:
	var c := [Vector3(-0.5, -0.5, -0.5), Vector3(0.5, -0.5, -0.5), Vector3(0.5, 0.5, -0.5), Vector3(-0.5, 0.5, -0.5),
		Vector3(-0.5, -0.5, 0.5), Vector3(0.5, -0.5, 0.5), Vector3(0.5, 0.5, 0.5), Vector3(-0.5, 0.5, 0.5)]
	var faces := [[0, 1, 2, 3], [5, 4, 7, 6], [4, 0, 3, 7], [1, 5, 6, 2], [3, 2, 6, 7], [4, 5, 1, 0]]
	for f in faces:
		for tri in [[f[0], f[1], f[2]], [f[0], f[2], f[3]]]:
			for vi in tri:
				var v: Vector3 = c[vi]
				st.set_uv2(Vector2(v.x + 0.5, 0.0))
				st.add_vertex(xf * v)


# Irregular debris shards: a random convex polygon (5 to 7 corners) extruded thin. UV.x is 0 at the middle and 1 on
# the rim and sides, so the debris shader can make the torn edges glow; the points also make the physics collider.
static func shard_mesh(rng: RandomNumberGenerator, size: float) -> Array:
	var n := rng.randi_range(5, 7)
	var ring: Array = []
	var angs: Array = []
	for i in n:
		angs.append(TAU * (i + rng.randf_range(-0.3, 0.3)) / n)
	angs.sort()
	for a in angs:
		var r := size * rng.randf_range(0.35, 0.6)
		ring.append(Vector2(cos(a) * r * 1.4, sin(a) * r))
	var th := size * rng.randf_range(0.08, 0.16)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := PackedVector3Array()
	for side in [1.0, -1.0]:
		var y: float = th * 0.5 * side
		for i in n:
			var a2: Vector2 = ring[i]
			var b2: Vector2 = ring[(i + 1) % n]
			var tri := [Vector3(0, y, 0), Vector3(a2.x, y, a2.y), Vector3(b2.x, y, b2.y)]
			if side < 0.0:
				tri = [tri[0], tri[2], tri[1]]
			for k in 3:
				st.set_uv(Vector2(0.0 if k == 0 and tri[k] == Vector3(0, y, 0) else 1.0, 0.0))
				st.add_vertex(tri[k])
		for v in ring:
			pts.append(Vector3(v.x, y, v.y))
	for i in n:
		var a3: Vector2 = ring[i]
		var b3: Vector2 = ring[(i + 1) % n]
		var q := [Vector3(a3.x, th * 0.5, a3.y), Vector3(b3.x, th * 0.5, b3.y), Vector3(b3.x, -th * 0.5, b3.y), Vector3(a3.x, -th * 0.5, a3.y)]
		for tri in [[q[0], q[2], q[1]], [q[0], q[3], q[2]]]:
			for v in tri:
				st.set_uv(Vector2(1.0, 0.0))
				st.add_vertex(v)
	st.generate_normals()
	return [st.commit(), pts]


# ---------------------------------------------------------------- build: destruction event

func _build_wreck(src: Dictionary) -> void:
	if not src.has("mesh") or src["mesh"] == null or not src.has("surfs"):
		notes.append("destruction event skipped: Hegemony mesh not loaded")
		return
	var k: float = src["scale"] * WRECK_SCALE
	var c0: Vector3 = src["center"]
	var root := Node3D.new()
	root.name = "Wreck"
	add_child(root)
	var whole := MeshInstance3D.new()
	whole.mesh = src["mesh"]
	whole.transform = Transform3D(Basis.from_scale(Vector3(k, k, k)), WRECK_POS - c0 * k)
	root.add_child(whole)
	wreck = {"whole": whole, "last_squib": 0, "last_boom": -1}
	var white := Color(1.0, 0.88, 0.7)
	wreck["flash"] = _glow(self, white, 10.0, WRECK_POS, 40.0, 1.0)
	(wreck["flash"].material_override as ShaderMaterial).set_shader_parameter("spikes", 0.6)
	wreck["core"] = _glow(self, Color(1.0, 0.6, 0.25), 8.0, WRECK_POS, 20.0, 0.7)
	var lt := _omni(self, white, 140.0)
	lt.position = WRECK_POS
	lt.omni_attenuation = 1.2
	wreck["light"] = lt
	var plane := PlaneMesh.new()
	plane.size = Vector2(1, 1)
	var shock := MeshInstance3D.new()
	shock.mesh = plane
	shock.material_override = _mat(_sh["shock"])
	shock.position = WRECK_POS
	shock.custom_aabb = AABB(Vector3(-0.6, -0.1, -0.6), Vector3(1.2, 0.2, 1.2))
	shock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shock.visible = false
	add_child(shock)
	wreck["shock"] = shock
	wreck["fireball"] = _particles(self, _pm["fireball"], 64, 1.8, _quad, _mats["flame"], WRECK_POS)
	wreck["smoke"] = _particles(self, _pm["big_smoke"], 40, 5.0, _quad, _mats["smoke"], WRECK_POS)
	(wreck["smoke"] as GPUParticles3D).draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	wreck["embers"] = _particles(self, _pm["embers"], 120, 2.6, _quad, _mats["flame"], WRECK_POS)
	wreck["debris"] = _particles(self, _pm["big_debris"], 70, 6.0, _shards[0], _mats["hot_debris"], WRECK_POS)
	var squib_pm := _pm["pre_squib"] as ParticleProcessMaterial
	squib_pm.emission_box_extents = Vector3(12.0, 2.0, 3.0) * 0.6
	var pre := _particles(self, squib_pm, 18, 0.5, _quad, _mats["flame"], WRECK_POS)
	pre.explosiveness = 0.6
	wreck["pre_squibs"] = pre
	wreck["chunks"] = _cut_chunks(src, k, root)
	if rich:
		var fl2 := _omni(self, Color(1.0, 0.55, 0.2), 90.0)
		fl2.position = WRECK_POS
		wreck["fire_light"] = fl2
		if not compat:
			var fv := FogVolume.new()
			fv.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
			fv.size = Vector3(30, 30, 30)
			fv.position = WRECK_POS
			fv.material = _mat(_sh["fire_fog"])
			add_child(fv)
			wreck["fire_fog"] = fv


# Cuts the Hegemony mesh into four chunks with three tilted planes (triangles go by their centroid), and puts fire, smoke
# and squib emitters along each chunk's break.
func _cut_chunks(src: Dictionary, k: float, root: Node3D) -> Array:
	var c0: Vector3 = src["center"]
	var p0 := Vector3(-0.16, 0, 0)
	var n0 := Vector3(1.0, 0.35, 0.2).normalized()
	var p1 := Vector3(0.18, 0, 0)
	var n1 := Vector3(1.0, -0.3, 0.25).normalized()
	var p2 := Vector3(0.0, c0.y, 0)
	var n2 := Vector3(0.2, 1.0, 0.3).normalized()
	var buckets := [PackedInt32Array(), PackedInt32Array(), PackedInt32Array(), PackedInt32Array()]
	var edges := [PackedVector3Array(), PackedVector3Array(), PackedVector3Array(), PackedVector3Array()]
	var surf: Array = src["surfs"][0]
	var arr: Array = surf[0]
	var mat: Material = surf[1]
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx := PackedInt32Array()
	if arr[Mesh.ARRAY_INDEX] != null:
		idx = arr[Mesh.ARRAY_INDEX]
	else:
		idx.resize(v.size())
		for j in v.size():
			idx[j] = j
	for ti in range(0, idx.size() - 2, 3):
		var a: int = idx[ti]
		var b: int = idx[ti + 1]
		var c: int = idx[ti + 2]
		var ctr := (v[a] + v[b] + v[c]) / 3.0
		var d0 := (ctr - p0).dot(n0)
		var d1 := (ctr - p1).dot(n1)
		var d2 := (ctr - p2).dot(n2)
		var bi := 0
		var near := false
		if d0 < 0.0:
			bi = 0
			near = d0 > -0.02
		elif d1 > 0.0:
			bi = 3
			near = d1 < 0.02
		else:
			bi = 1 if d2 > 0.0 else 2
			near = absf(d2) < 0.02 or d0 < 0.02 or d1 > -0.02
		buckets[bi].append(a)
		buckets[bi].append(b)
		buckets[bi].append(c)
		if near:
			edges[bi].append(ctr)
	var cmat: Material = mat.duplicate() if mat != null else StandardMaterial3D.new()
	if cmat is BaseMaterial3D:
		(cmat as BaseMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	var chunks: Array = []
	var biggest := 0
	for bi in 4:
		if buckets[bi].size() > buckets[biggest].size():
			biggest = bi
	for bi in 4:
		var bk: PackedInt32Array = buckets[bi]
		if bk.size() < 3:
			continue
		var carr := arr.duplicate()
		carr[Mesh.ARRAY_INDEX] = bk
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, carr)
		am.surface_set_material(0, cmat)
		var cc := Vector3.ZERO
		var cn := 0
		for j in range(0, bk.size(), 9):
			cc += v[bk[j]]
			cn += 1
		cc /= float(cn)
		var node: Node3D = Node3D.new()
		if phys != null:
			var hull_pts := PackedVector3Array()
			for j in range(0, bk.size(), 7):
				hull_pts.append((v[bk[j]] - cc) * k)
			node = phys.make_chunk(hull_pts)
		node.name = "chunk%d" % bi
		node.visible = false
		root.add_child(node)
		var mi := MeshInstance3D.new()
		mi.mesh = am
		mi.transform = Transform3D(Basis.from_scale(Vector3(k, k, k)), -cc * k)
		node.add_child(mi)
		# the break: where the triangles next to a cut plane are
		var ep: PackedVector3Array = edges[bi]
		var emin := cc
		var emax := cc
		if not ep.is_empty():
			emin = ep[0]
			emax = ep[0]
			for q in ep:
				emin = emin.min(q)
				emax = emax.max(q)
		var ec := (emin + emax) * 0.5
		var ext := ((emax - emin) * 0.5 * k).max(Vector3(0.4, 0.4, 0.4))
		var at := (ec - cc) * k
		var fire_pm := (_pm["edge_fire"] as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial
		fire_pm.emission_box_extents = ext
		var smoke_pm := (_pm["edge_smoke"] as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial
		smoke_pm.emission_box_extents = ext
		var squib_pm := (_pm["edge_squib"] as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial
		squib_pm.emission_box_extents = ext
		var is_wreck := bi == biggest
		var fire := _particles(node, fire_pm, 60 if is_wreck else 36, 0.7, _quad, _mats["flame"], at, false)
		var smoke := _particles(node, smoke_pm, 30 if is_wreck else 14, 3.0, _quad, _mats["smoke"], at, false)
		var squibs := _particles(node, squib_pm, 8, 0.15, _quad, _mats["flame"], at, false)
		var dir := ((cc - c0) * k + Vector3(0, 1.5, 0)).normalized()
		var cdict := {}
		if rich:
			var cl := _omni(node, Color(1.0, 0.5, 0.15), 14.0)
			cl.position = at
			cdict["light"] = cl
		chunks.append(cdict)
		cdict.merge({"node": node, "mesh": mi, "fire": fire, "smoke": smoke, "squibs": squibs,
			"start": (cc - c0) * k, "vel": dir * (1.5 if is_wreck else _rng.randf_range(5.0, 9.0)),
			"axis": Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).normalized(),
			"spin": 0.15 if is_wreck else _rng.randf_range(0.5, 1.4),
			"burn_t": maxf(boom_every - 2.5, 1.0) if is_wreck else minf(_rng.randf_range(3.0, 6.0), boom_every - 2.0)})
	return chunks



# ---------------------------------------------------------------- helpers

func _drift_x(t: float) -> float:
	return fposmod(DRIFT_SPEED * t + DRIFT_SPAN * 0.5, DRIFT_SPAN) - DRIFT_SPAN * 0.5


func _cycle(x: float) -> int:
	return -1 if x < 0.0 else int(floorf(x / LOOP))


func _spark_off(idx: int) -> float:
	# Babylon's spacing (0.37 s per ship) moved 1.2 s later: Babylon's 0.3 + 0.37 i puts the Hegemony's shower at 2.97,
	# right over the hole in the 3.0 close-up; here it is at 1.87 and 4.17, so the 3.0 still shows the hole clear
	return fposmod(1.5 + 0.37 * idx, SPARKS_EVERY)


func _pop_off(idx: int) -> float:
	return fposmod(0.6 + 0.55 * idx, POP_EVERY)  # the six heroes are below one period, so this only wraps the copies


func _cycle_n(x: float, period: float) -> int:
	return -1 if x < 0.0 else int(floorf(x / period))


func _hash(x: float) -> float:
	var s := sin(x * 12.9898) * 43758.5453
	return s - floorf(s)


func _smooth_noise(x: float) -> float:
	var i := floorf(x)
	var f := x - i
	f = f * f * (3.0 - 2.0 * f)
	return lerpf(_hash(i), _hash(i + 1.0), f)


# Corsair engines (the soot follows the same cough pattern as the engine shaders' sputter()).
func _sputter(t: float) -> float:
	var s := 0.6 + 0.4 * lerpf(_hash(floorf(t * 5.0)), _hash(floorf(t * 5.0) + 1.0), smoothstep(0.0, 1.0, t * 5.0 - floorf(t * 5.0)))
	if _hash(floorf(t * 6.0)) < 0.18:
		s *= 0.2
	return s


func _fire(p: GPUParticles3D) -> void:
	p.visible = true
	p.restart(fixed_seed)
	p.emitting = true
	if p.one_shot:
		_live[p] = _now + p.lifetime + 0.1


func _reap() -> void:
	if prewarm:
		return
	for p in _live.keys():
		if _now >= float(_live[p]) or _now < float(_live[p]) - 30.0:
			(p as GPUParticles3D).visible = false
			_live.erase(p)


func _fire_at(p: GPUParticles3D, at: Vector3) -> void:
	p.position = at
	_fire(p)


func _v3(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)


func _basis_y(n: Vector3) -> Basis:
	var y := n.normalized()
	var ref := Vector3.UP if absf(y.y) < 0.95 else Vector3(1, 0, 0)
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)


func _shader(code: String) -> Shader:
	var s := Shader.new()
	s.code = code
	return s


func _mat(s: Shader) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = s
	return m


func _glow(parent: Node, col: Color, energy: float, at: Vector3, size: float, hot := 1.0) -> MeshInstance3D:
	var m := _mat(_sh["glow"])
	m.set_shader_parameter("tint", _v3(col))
	m.set_shader_parameter("energy", energy)
	m.set_shader_parameter("hot", hot)
	var n := MeshInstance3D.new()
	n.mesh = _quad
	n.material_override = m
	n.position = at
	n.scale = Vector3.ONE * size
	n.custom_aabb = AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.visible = false
	parent.add_child(n)
	return n


func _omni(parent: Node, col: Color, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.omni_range = rng
	l.light_energy = 0.0
	l.light_specular = 1.0
	l.shadow_enabled = false
	l.visible = false
	parent.add_child(l)
	_lights.append(l)
	return l


func _particles(parent: Node, pmat: ParticleProcessMaterial, amount: int, life: float, mesh: Mesh, mat: Material, at: Vector3,
		one_shot := true) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.one_shot = one_shot
	p.explosiveness = 1.0 if one_shot else 0.0
	p.emitting = false
	p.local_coords = false
	p.fixed_fps = 0
	p.interpolate = false
	p.process_material = pmat
	p.draw_pass_1 = mesh
	p.material_override = mat
	p.visibility_aabb = BIG_AABB
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.use_fixed_seed = fixed_seed
	p.seed = _seed
	_seed += 7919
	p.position = at
	p.visible = not one_shot  # shown when fired (see _fire and _reap)
	parent.add_child(p)
	return p


func _ramp(stops: Array) -> GradientTexture1D:
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for s in stops:
		offs.append(s[0])
		cols.append(s[1])
	var g := Gradient.new()
	g.offsets = offs
	g.colors = cols
	var t := GradientTexture1D.new()
	t.gradient = g
	t.use_hdr = true
	return t


func _curve(points: Array, maxv := 2.0) -> CurveTexture:
	var c := Curve.new()
	c.max_value = maxv
	for p in points:
		c.add_point(Vector2(p[0], p[1]))
	var t := CurveTexture.new()
	t.curve = c
	return t


func _ppm(dir: Vector3, spread: float, vmin: float, vmax: float, damp: float, smin: float, smax: float, radius: float,
		life_rand: float) -> ParticleProcessMaterial:
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = radius
	m.direction = dir
	m.spread = spread
	m.initial_velocity_min = vmin
	m.initial_velocity_max = vmax
	m.gravity = Vector3.ZERO
	m.damping_min = damp
	m.damping_max = damp * 1.4
	m.scale_min = smin
	m.scale_max = smax
	m.lifetime_randomness = life_rand
	return m


func _billboard_spin(m: ParticleProcessMaterial) -> void:
	m.angle_min = 0.0
	m.angle_max = 360.0
	m.angular_velocity_min = -40.0
	m.angular_velocity_max = 40.0


func _tumble(m: ParticleProcessMaterial) -> void:
	m.particle_flag_rotate_y = true
	m.angle_min = 0.0
	m.angle_max = 360.0
	m.angular_velocity_min = -360.0
	m.angular_velocity_max = 360.0


func _build_process_materials() -> void:
	var fire_ramp := [[0.0, Color(1.0, 0.92, 0.7, 1.0)], [0.2, Color(1.0, 0.55, 0.15, 1.0)],
		[0.6, Color(0.7, 0.18, 0.04, 0.7)], [1.0, Color(0.2, 0.05, 0.02, 0.0)]]
	var spark_ramp := [[0.0, Color(1.0, 0.95, 0.8, 1.0)], [0.4, Color(1.0, 0.6, 0.2, 1.0)], [1.0, Color(0.8, 0.2, 0.05, 0.0)]]
	var smoke_ramp := [[0.0, Color(0.20, 0.19, 0.18, 0.0)], [0.12, Color(0.22, 0.21, 0.20, 0.5)],
		[0.6, Color(0.16, 0.155, 0.15, 0.3)], [1.0, Color(0.12, 0.12, 0.12, 0.0)]]
	# broadside impact
	var isp := _ppm(Vector3(0, 0, -1), 70.0, 12.0, 28.0, 20.0, 0.6, 1.1, 0.3, 0.4)
	isp.particle_flag_align_y = true
	isp.color_ramp = _ramp(spark_ramp)
	_pm["impact_sparks"] = isp
	var idb := _ppm(Vector3(0, 0, 1), 180.0, 3.0, 8.0, 1.0, 0.06, 0.18, 0.3, 0.3)
	_tumble(idb)
	idb.scale_curve = _curve([[0.0, 1.0], [0.8, 1.0], [1.0, 0.0]], 1.0)
	_pm["impact_debris"] = idb
	# smoke ring: puffs born on a ring around the muzzle, expanding and drifting out (world space, stays where fired)
	var rs := _ppm(Vector3(0, 0.15, 1).normalized(), 6.0, 2.0, 3.5, 1.4, 0.9, 1.5, 0.9, 0.2)
	rs.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	rs.emission_ring_axis = Vector3(0, 0.15, 1).normalized()
	rs.emission_ring_radius = 0.9
	rs.emission_ring_inner_radius = 0.75
	rs.emission_ring_height = 0.1
	rs.radial_velocity_min = 1.6
	rs.radial_velocity_max = 2.2
	_billboard_spin(rs)
	rs.scale_curve = _curve([[0.0, 0.6], [1.0, 2.4]], 3.0)
	rs.color_ramp = _ramp([[0.0, Color(0.30, 0.29, 0.28, 0.0)], [0.08, Color(0.32, 0.31, 0.30, 0.5)],
		[0.5, Color(0.26, 0.25, 0.24, 0.3)], [1.0, Color(0.2, 0.2, 0.2, 0.0)]])
	_pm["ring_smoke"] = rs
	# beam impact fountain
	var fnt := _ppm(Vector3(-1, 0.3, 0), 55.0, 10.0, 24.0, 8.0, 0.5, 1.0, 0.6, 0.4)
	fnt.particle_flag_align_y = true
	fnt.color_ramp = _ramp(spark_ramp)
	_pm["fountain"] = fnt
	# hull hit (Chorus, Deathless): local +y is out of the hull
	var hs := _ppm(Vector3.UP, 55.0, 9.0, 22.0, 12.0, 0.5, 1.0, 0.3, 0.4)
	hs.particle_flag_align_y = true
	hs.color_ramp = _ramp([[0.0, Color(1.0, 0.8, 0.4, 1.0)], [0.4, Color(1.0, 0.45, 0.1, 1.0)], [1.0, Color(0.6, 0.12, 0.02, 0.0)]])
	_pm["hit_sparks"] = hs
	var hd := _ppm(Vector3.UP, 50.0, 4.0, 10.0, 1.5, 0.15, 0.4, 0.3, 0.3)
	_tumble(hd)
	hd.scale_curve = _curve([[0.0, 1.0], [0.8, 1.0], [1.0, 0.0]], 1.0)
	_pm["hit_debris"] = hd
	var hp := _ppm(Vector3.UP, 60.0, 1.0, 3.0, 2.0, 1.2, 2.0, 0.4, 0.3)
	_billboard_spin(hp)
	hp.scale_curve = _curve([[0.0, 0.5], [1.0, 1.2]])
	hp.color_ramp = _ramp(fire_ramp)
	_pm["puff"] = hp
	# breach: local +y is out of the hull
	var gas := _ppm(Vector3.UP, 9.0, 7.0, 11.0, 2.0, 0.5, 0.9, 0.25, 0.2)
	_billboard_spin(gas)
	gas.scale_curve = _curve([[0.0, 0.6], [1.0, 3.0]], 3.0)
	gas.color_ramp = _ramp([[0.0, Color(0.85, 0.88, 0.92, 0.0)], [0.08, Color(0.85, 0.88, 0.92, 0.45)],
		[0.5, Color(0.75, 0.78, 0.82, 0.22)], [1.0, Color(0.7, 0.72, 0.75, 0.0)]])
	_pm["gas"] = gas
	var bf := _ppm(Vector3.UP, 28.0, 1.5, 3.5, 2.0, 0.6, 1.2, 0.5, 0.3)
	_billboard_spin(bf)
	bf.scale_curve = _curve([[0.0, 0.6], [0.3, 1.0], [1.0, 0.3]], 1.0)
	bf.color_ramp = _ramp(fire_ramp)
	_pm["breach_fire"] = bf
	var bd := _ppm(Vector3.UP, 35.0, 1.5, 3.5, 0.0, 0.1, 0.28, 0.4, 0.3)
	_tumble(bd)
	bd.scale_curve = _curve([[0.0, 1.0], [0.85, 1.0], [1.0, 0.0]], 1.0)
	_pm["breach_debris"] = bd
	var bs := _ppm(Vector3.UP, 50.0, 6.0, 15.0, 10.0, 0.4, 0.8, 0.3, 0.4)
	bs.particle_flag_align_y = true
	bs.color_ramp = _ramp(spark_ramp)
	_pm["breach_sparks"] = bs
	var pop := _ppm(Vector3.UP, 70.0, 3.0, 6.5, 5.0, 1.0, 1.9, 0.4, 0.3)
	_billboard_spin(pop)
	pop.scale_curve = _curve([[0.0, 0.5], [0.3, 1.2], [1.0, 1.4]])
	pop.color_ramp = _ramp(fire_ramp)
	_pm["pop"] = pop
	# Corsair soot (the emitter is not rotated: the stern is -x)
	var soot := _ppm(Vector3(-1, 0.15, 0), 20.0, 4.0, 7.0, 0.5, 0.8, 1.4, 0.6, 0.3)
	_billboard_spin(soot)
	soot.scale_curve = _curve([[0.0, 0.6], [1.0, 3.0]], 3.0)
	soot.color_ramp = _ramp([[0.0, Color(0.06, 0.055, 0.05, 0.0)], [0.1, Color(0.07, 0.065, 0.06, 0.7)],
		[1.0, Color(0.09, 0.09, 0.09, 0.0)]])
	_pm["soot"] = soot
	# destruction event
	var fb := _ppm(Vector3.UP, 180.0, 4.0, 11.0, 4.0, 5.0, 8.0, 3.0, 0.35)
	_billboard_spin(fb)
	fb.scale_curve = _curve([[0.0, 0.4], [0.25, 1.0], [1.0, 1.6]])
	fb.color_ramp = _ramp([[0.0, Color(1.0, 0.95, 0.8, 1.0)], [0.15, Color(1.0, 0.6, 0.18, 1.0)],
		[0.55, Color(0.75, 0.2, 0.05, 0.8)], [1.0, Color(0.15, 0.04, 0.02, 0.0)]])
	_pm["fireball"] = fb
	var bsm := _ppm(Vector3.UP, 180.0, 2.0, 6.0, 0.6, 7.0, 12.0, 4.0, 0.2)
	_billboard_spin(bsm)
	bsm.scale_curve = _curve([[0.0, 0.5], [1.0, 1.8]])
	bsm.color_ramp = _ramp([[0.0, Color(0.10, 0.09, 0.085, 0.0)], [0.15, Color(0.12, 0.11, 0.10, 0.8)],
		[0.6, Color(0.10, 0.095, 0.09, 0.55)], [1.0, Color(0.08, 0.08, 0.08, 0.0)]])
	_pm["big_smoke"] = bsm
	var emb := _ppm(Vector3.UP, 180.0, 10.0, 30.0, 3.0, 0.25, 0.5, 2.0, 0.5)
	emb.color_ramp = _ramp([[0.0, Color(1.0, 0.85, 0.5, 1.0)], [0.5, Color(1.0, 0.45, 0.1, 1.0)], [1.0, Color(0.6, 0.1, 0.02, 0.0)]])
	_pm["embers"] = emb
	var bdb := _ppm(Vector3.UP, 180.0, 6.0, 18.0, 0.3, 0.2, 0.9, 2.0, 0.3)
	_tumble(bdb)
	bdb.scale_curve = _curve([[0.0, 1.0], [0.9, 1.0], [1.0, 0.0]], 1.0)
	_pm["big_debris"] = bdb
	var psq := _ppm(Vector3.UP, 180.0, 1.0, 3.0, 2.0, 1.0, 2.2, 1.0, 0.3)
	psq.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	psq.color_ramp = _ramp(fire_ramp)
	_pm["pre_squib"] = psq
	var ef := _ppm(Vector3.UP, 180.0, 0.5, 2.0, 1.0, 1.0, 2.0, 0.5, 0.3)
	ef.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_billboard_spin(ef)
	ef.scale_curve = _curve([[0.0, 0.5], [0.3, 1.0], [1.0, 0.4]], 1.0)
	ef.color_ramp = _ramp(fire_ramp)
	_pm["edge_fire"] = ef
	var es := _ppm(Vector3.UP, 180.0, 0.5, 1.5, 0.2, 1.5, 3.0, 0.5, 0.2)
	es.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_billboard_spin(es)
	es.scale_curve = _curve([[0.0, 0.5], [1.0, 2.0]])
	es.color_ramp = _ramp(smoke_ramp)
	_pm["edge_smoke"] = es
	var eq := _ppm(Vector3.UP, 180.0, 0.0, 0.5, 0.0, 1.2, 2.4, 0.5, 0.2)
	eq.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	eq.color_ramp = _ramp([[0.0, Color(1.0, 0.95, 0.8, 1.0)], [1.0, Color(1.0, 0.5, 0.1, 0.0)]])
	_pm["edge_squib"] = eq


# Breach decal textures, made once at start (128 x 128): a jagged black hole in a scorched ring, a glowing torn edge
# Breach decal textures, made once at start (128 x 128): a jagged black hole in a scorched ring, a glowing torn edge
# with short hot cracks, and a bowl normal map so the hole reads as a recess.
func _breach_textures() -> Dictionary:
	var sz := 128
	var alb := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var emi := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var nrm := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var nz := FastNoiseLite.new()
	nz.seed = 77
	nz.frequency = 0.06
	for y in sz:
		for x in sz:
			var px := (x + 0.5) / sz * 2.0 - 1.0
			var py := (y + 0.5) / sz * 2.0 - 1.0
			var r := sqrt(px * px + py * py)
			var ang := atan2(py, px)
			var jag := 0.3 + 0.07 * nz.get_noise_2d(cos(ang) * 40.0, sin(ang) * 40.0) + 0.04 * sin(ang * 13.0)
			var n2 := nz.get_noise_2d(x * 1.7, y * 1.7)
			var hole := 1.0 - smoothstep(jag - 0.015, jag + 0.015, r)
			var scorch := (1.0 - smoothstep(0.35, 0.95, r + n2 * 0.18)) * (1.0 - hole)
			var a := clampf(hole + scorch * 0.95, 0.0, 1.0)
			var base := Color(0.02, 0.015, 0.012).lerp(Color(0.10, 0.075, 0.06), clampf((r - jag) * 2.0 + n2 * 0.3, 0.0, 1.0))
			alb.set_pixel(x, y, Color(base.r, base.g, base.b, a))
			var eq := (r - jag) / 0.03
			var edge := exp(-eq * eq)
			var crack := 0.0
			var cr := absf(sin(ang * 7.0 + n2 * 3.0))
			if r > jag and r < jag + 0.22:
				crack = smoothstep(0.96, 1.0, cr) * (1.0 - (r - jag) / 0.22)
			var inner := hole * 0.25 * (1.0 - r / maxf(jag, 0.01))
			var heat := clampf(edge + crack * 0.8 + inner, 0.0, 1.0)
			emi.set_pixel(x, y, Color(heat, 0.42 * heat * heat, 0.08 * heat * heat * heat, 1.0))
			var nx := 0.0
			var ny := 0.0
			if r < jag + 0.04:
				var depth := clampf(r / maxf(jag, 0.01), 0.0, 1.0)
				nx = -px / maxf(r, 0.001) * depth * 0.7
				ny = py / maxf(r, 0.001) * depth * 0.7
			var nzv := sqrt(maxf(0.0, 1.0 - nx * nx - ny * ny))
			nrm.set_pixel(x, y, Color(nx * 0.5 + 0.5, ny * 0.5 + 0.5, nzv * 0.5 + 0.5, 1.0))
	for img in [alb, emi, nrm]:
		img.generate_mipmaps()
	return {"alb": ImageTexture.create_from_image(alb), "emi": ImageTexture.create_from_image(emi), "nrm": ImageTexture.create_from_image(nrm)}
