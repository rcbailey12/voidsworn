extends RefCounted
# Issue 368, R289. Steel-blue and cyan weather, distinct from calm purple nebula gas.
# Both tiers sample volumes in world space. Charge gathers in broad cloud lobes,
# never in persistent contour lines. Only the intermittent fork meshes draw arcs.
const TICK_FLARE_SLOTS := 8
const TICK_SHADER := """
uniform vec4 tick_flares[%d];
uniform int tick_flare_count = 0;
float tick_light(vec2 world_xz) {
	float light = 0.0;
	for (int i = 0; i < tick_flare_count; i++) {
		vec2 tick_delta = world_xz - tick_flares[i].xz;
		// Overlapping cues must stay within the peak of a single cue.
		light = max(light, 1.8 * tick_flares[i].w * exp(-dot(tick_delta, tick_delta) / 144.0));
	}
	return light;
}
""" % TICK_FLARE_SLOTS

const CARDS := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
%NOISE%
%CARD_SUPPORT%
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D mask_tex : filter_linear, repeat_disable;
uniform vec4 mask_box;
uniform float gas_time = 0.0;
uniform float height_scale = 1.0;
uniform float gain_a = 1.0;
uniform vec4 flashes[8];
""" + TICK_SHADER + """
varying vec4 cloud;
varying vec2 disc;
varying vec3 world;
void vertex() {
	cloud = INSTANCE_CUSTOM;
	vec4 c = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	vec2 q = gas_card_offset(VERTEX.xy, cloud, c, INV_VIEW_MATRIX, height_scale);
	disc = VERTEX.xy * 2.0;
	c.xy += q * cloud.x;
	world = (INV_VIEW_MATRIX * c).xyz;
	POSITION = PROJECTION_MATRIX * c;
}
void fragment() {
	float radius = length(disc);
	if (radius > 1.0) { discard; }
	vec2 uv = (world.xz - mask_box.xy) * mask_box.zw;
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) { discard; }
	vec2 mask = texture(mask_tex, uv).rg;
	float band = floor(cloud.w);
	float foot = mask.g * smoothstep(0.08, 0.55, mask.r);
	float layer = gas_layer(band, world.y / height_scale);
	float shape = (1.0 - smoothstep(0.25, 1.0, radius)) * foot * layer;
#ifdef HIGH_GAS_CARDS
	// Field and contact are at most one. Skip noise for fragments too faint to draw.
	if (shape * cloud.z < GAS_DENSITY_BOUND) { discard; }
#else
	if (shape * cloud.z <= 0.0) { discard; }
#endif
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	vec3 opaque = (INV_VIEW_MATRIX * vec4(view_pos.xyz / view_pos.w, 1.0)).xyz;
	if (depth > 0.000001 && opaque.y > -20.0) { discard; }
	float rate = band < 0.5 ? 0.6 : (band < 1.5 ? 1.0 : (band < 2.5 ? 1.6 : -0.4));
	vec3 p = world * vec3(0.055, 0.075, 0.055) + vec3(0.027, 0.009, 0.015) * gas_time * rate;
	float warp = wfbm3(p * 0.5 + 4.0);
	float n = wfbm3(p + vec3(warp * 0.8));
#ifndef HIGH_GAS_CARDS
	float detail = wfbm3(p * 2.3 + vec3(3.7, 1.2, 7.4));
#endif
	float field = smoothstep(0.38, 0.74, n);
	float density = shape * field * cloud.z;
	density *= clamp((-view_pos.z / view_pos.w + VERTEX.z) / 5.0, 0.0, 1.0);
	if (density < MIN_GAS_DENSITY) { discard; }
#ifdef HIGH_GAS_CARDS
	float detail = wfbm3(p * 2.3 + vec3(3.7, 1.2, 7.4));
#endif
	float sun = wfbm3(p + vec3(warp * 0.8) + vec3(0.12, 0.20, 0.15));
	float rim = clamp(0.45 + (n - sun) * 5.0, 0.0, 1.0);
	float charge = smoothstep(0.47, 0.70, detail) * smoothstep(0.38, 0.65, n);
	vec3 col = mix(vec3(0.006, 0.014, 0.022), vec3(0.032, 0.065, 0.11), field);
	col += vec3(0.04, 0.13, 0.18) * rim * field;
	col += vec3(0.10, 0.42, 0.52) * charge * (0.35 + 0.04 * sin(gas_time * 2.8 + cloud.y * 6.28));
	float flash = tick_light(world.xz);
	for (int i = 0; i < 8; i++) {
		vec3 delta = world - flashes[i].xyz;
		flash += exp(-dot(delta, delta) / 240.0) * flashes[i].w;
	}
	col += vec3(0.14, 0.55, 1.05) * flash * field * 1.2;
	float weight = band < 0.5 ? 0.50 : (band < 1.5 ? 1.0 : (band < 2.5 ? 0.65 : 0.16));
	ALBEDO = col;
	ALPHA = min(0.58, (1.0 - exp(-density * weight * 2.5)) * gain_a);
}
"""

const FOG := """
shader_type fog;
uniform sampler3D noise_tex : filter_linear, repeat_enable;
uniform sampler2D mask_tex : filter_linear, repeat_disable;
uniform vec4 mask_box;
uniform float gas_time = 0.0;
uniform float gain_a = 1.0;
uniform vec4 flashes[8];
""" + TICK_SHADER + """
void fog() {
	vec3 p = WORLD_POSITION * vec3(0.016, 0.022, 0.016) + vec3(0.0021, 0.00075, 0.0012) * gas_time;
	float warp = texture(noise_tex, p * 0.55 + 0.31).r;
	float n = texture(noise_tex, p + vec3(warp * 0.18)).r;
	float detail = texture(noise_tex, p * 2.3 + vec3(0.37, 0.12, 0.74)).r;
	n = mix(n, detail, 0.18);
	vec2 uv = (WORLD_POSITION.xz - mask_box.xy) * mask_box.zw;
	vec2 foot = texture(mask_tex, uv).rg;
	foot *= step(vec2(0.0), uv).x * step(vec2(0.0), uv).y * step(uv, vec2(1.0)).x * step(uv, vec2(1.0)).y;
	float height = smoothstep(-7.0, -2.0, WORLD_POSITION.y) * (1.0 - smoothstep(23.0, 31.5, WORLD_POSITION.y));
	float field = smoothstep(0.44, 0.62, n);
	float shape = foot.g * smoothstep(0.08, 0.65, foot.r) * height;
	float charge = smoothstep(0.48, 0.66, detail) * field;
	float flash = tick_light(WORLD_POSITION.xz);
	for (int i = 0; i < 8; i++) {
		vec3 delta = WORLD_POSITION - flashes[i].xyz;
		flash += exp(-dot(delta, delta) / 240.0) * flashes[i].w;
	}
	DENSITY = field * shape * 0.055 * gain_a;
	ALBEDO = mix(vec3(0.04, 0.085, 0.14), vec3(0.12, 0.36, 0.46), charge);
	EMISSION = mix(vec3(0.006, 0.014, 0.022), vec3(0.015, 0.05, 0.085), field);
	EMISSION += vec3(0.04, 0.20, 0.27) * charge;
	EMISSION += vec3(0.12, 0.50, 1.0) * flash * field * 2.5;
}
"""
