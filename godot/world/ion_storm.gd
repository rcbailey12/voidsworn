extends RefCounted
# Issue 368, R289; upgraded issue 2035 (AAA item 9): multi-height soft drifting storm strata
# with organic non-hex edges and subtle combat-flash scatter. Steel-blue and cyan weather,
# distinct from calm rose nebula gas. Storm lightning and tick flares stay untouched.
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
%COMBAT_LIGHTS%
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
vec2 storm_foot(vec2 xz) {
	vec2 uv = (xz - mask_box.xy) * mask_box.zw;
	vec2 s = texture(mask_tex, uv).rg;
	float inside = step(0.0, uv.x) * step(0.0, uv.y) * step(uv.x, 1.0) * step(uv.y, 1.0);
	return s * inside;
}
void fragment() {
	float radius = length(disc);
	if (radius > 1.0) { discard; }
	vec2 mask0 = storm_foot(world.xz);
	if (mask0.g <= 0.001 && mask0.r <= 0.003) { discard; }
	float cam_d = length(CAMERA_POSITION_WORLD - world);
	float near_cam = smoothstep(10.0, 32.0, cam_d);
	if (near_cam <= 0.001) { discard; }
	float band = floor(cloud.w);
	float layer = gas_layer(band, world.y / height_scale);
	float rs = 1.0 - smoothstep(0.06, 1.0, radius);
	float shape = rs * rs * (3.0 - 2.0 * rs) * layer;
#ifdef HIGH_GAS_CARDS
	if (shape * near_cam * cloud.z < GAS_DENSITY_BOUND) { discard; }
#else
	if (shape * near_cam * cloud.z <= 0.0) { discard; }
#endif
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	vec3 opaque = (INV_VIEW_MATRIX * vec4(view_pos.xyz / view_pos.w, 1.0)).xyz;
	// RULEBOOK 10.4: opaque hulls stay crisp inside storm gas.
	if (depth > 0.000001 && opaque.y > -20.0) { discard; }
	float rate = band < 0.5 ? 0.6 : (band < 1.5 ? 1.0 : (band < 2.5 ? 1.6 : -0.4));
	vec3 p = world * vec3(0.055, 0.075, 0.055) + vec3(0.027, 0.009, 0.015) * gas_time * rate;
	vec3 layer_scale;
	vec3 layer_offset;
	vec2 edge_shift;
	gas_layer_style(band, layer_scale, layer_offset, edge_shift);
	vec3 pl = p * layer_scale + layer_offset;
	float warp = wvn3(gas_rot0(pl * 0.54 + vec3(4.0, 1.3, -2.1)));
	float warp2 = wvn3(gas_rot0(pl * 0.46 - vec3(5.2, -2.7, 3.4)));
	// Organic domain-warped footprint so storm boundaries never echo hex lines.
	vec2 wv = vec2(warp - 0.5, warp2 - 0.5) * 9.0 + edge_shift;
	vec2 fmask = storm_foot(world.xz + wv);
	if (fmask.g <= 0.001) { discard; }
	float close_k = 1.0 - smoothstep(45.0, 150.0, cam_d);
	vec3 warp_v = vec3(warp - 0.5, (warp + warp2 - 1.0) * 0.5, warp2 - 0.5) * 1.10;
	vec2 cn = gas_cloud3(pl + warp_v, close_k);
	float n = cn.x;
	float n_macro = cn.y;
	float bar = mix(0.12, 0.26, smoothstep(0.5, 2.5, band)) + (0.52 - n_macro) * 0.34;
	float foot = fmask.g * smoothstep(bar, bar + 0.38, fmask.r);
	float lo_cut = band < 0.5 ? 0.32 : (band < 1.5 ? 0.35 : (band < 2.5 ? 0.40 : 0.43));
	float field = smoothstep(lo_cut, lo_cut + 0.36, n);
	float density = shape * foot * field * near_cam * cloud.z;
	density *= clamp((-view_pos.z / view_pos.w + VERTEX.z) / 5.0, 0.0, 1.0);
	if (density < MIN_GAS_DENSITY) { discard; }
	float sun_macro = wvn3(gas_rot0(pl + warp_v + vec3(0.24, 0.38, 0.28)));
	float rim = clamp(0.50 + (n_macro - sun_macro) * 2.4, 0.0, 1.0);
	// Broad rolling charge lobes (no grainy high-frequency static at battle distance).
	float charge_lobe = wvn3(gas_rot0(pl * 1.18 + vec3(3.7, 1.2, 7.4)));
	float charge = smoothstep(0.46, 0.72, charge_lobe) * smoothstep(0.36, 0.68, n_macro);
	// Vertical stratification: dark brooding under-stratum below ships, steel-blue rolling core, cool sunlit upper wisps.
	float alt_k = clamp((world.y / height_scale + 6.0) / 22.0, 0.0, 1.0);
	float stratum_lit = band < 0.5 ? 0.68 : (band < 1.5 ? 0.98 : (band < 2.5 ? 1.06 : 0.94));
	vec3 col = mix(vec3(0.006, 0.014, 0.022), vec3(0.032, 0.065, 0.11), field * mix(0.72, 1.02, alt_k));
	col += vec3(0.04, 0.13, 0.18) * rim * field * stratum_lit;
	col += vec3(0.10, 0.42, 0.52) * charge * (0.35 + 0.04 * sin(gas_time * 2.8 + cloud.y * 6.28)) * mix(0.65, 1.0, alt_k);
	float flash = tick_light(world.xz);
	for (int i = 0; i < 8; i++) {
		vec3 delta = world - flashes[i].xyz;
		flash += exp(-dot(delta, delta) / 240.0) * flashes[i].w;
	}
	col += vec3(0.14, 0.55, 1.05) * flash * field * 1.2;
	col += combat_scatter(world, field) * (0.42 * field);
	float weight = band < 0.5 ? 0.52 : (band < 1.5 ? 0.92 : (band < 2.5 ? 0.46 : 0.14));
	ALBEDO = col;
	ALPHA = min(0.54, (1.0 - exp(-density * weight * 2.4)) * gain_a);
}
"""

const FOG := """
shader_type fog;
%COMBAT_LIGHTS%
uniform sampler3D noise_tex : filter_linear, repeat_enable;
uniform sampler2D mask_tex : filter_linear, repeat_disable;
uniform vec4 mask_box;
uniform float gas_time = 0.0;
uniform float gain_a = 1.0;
uniform vec4 flashes[8];
""" + TICK_SHADER + """
void fog() {
	DENSITY = 0.0;
	ALBEDO = vec3(0.0);
	EMISSION = vec3(0.0);
	float height = smoothstep(-7.0, -1.5, WORLD_POSITION.y) * (1.0 - smoothstep(22.0, 31.5, WORLD_POSITION.y));
	// Issue 2035 (run 4): skip 3D noise fetches for froxels outside the rounded storm footprint.
	vec2 uv0 = (WORLD_POSITION.xz - mask_box.xy) * mask_box.zw;
	vec2 foot0 = texture(mask_tex, uv0).rg * step(0.0, uv0.x) * step(0.0, uv0.y) * step(uv0.x, 1.0) * step(uv0.y, 1.0);
	if (height > 0.001 && (foot0.g > 0.001 || foot0.r > 0.002)) {
		vec3 p = WORLD_POSITION * vec3(0.016, 0.022, 0.016) + vec3(0.0021, 0.00075, 0.0012) * gas_time;
		// Altitude wind shear separates lower dark storm deck from upper drifting wisps.
		float alt = clamp((WORLD_POSITION.y + 7.0) / 38.5, 0.0, 1.0);
		vec3 p_alt = p + vec3(0.06, -0.02, 0.04) * alt + vec3(0.0016, 0.0, 0.0009) * gas_time * (alt - 0.35);
		float warp = texture(noise_tex, p_alt * 0.55 + 0.31).r;
		float n = texture(noise_tex, p_alt + vec3(warp - 0.5) * 0.18).r;
		vec2 wv = vec2(warp - 0.5, n - 0.5) * 9.0 + vec2(alt - 0.5, 0.5 - alt) * 3.0;
		vec2 uv = (WORLD_POSITION.xz + wv - mask_box.xy) * mask_box.zw;
		vec2 foot = texture(mask_tex, uv).rg;
		foot *= step(vec2(0.0), uv).x * step(vec2(0.0), uv).y * step(uv, vec2(1.0)).x * step(uv, vec2(1.0)).y;
		// Soft multi-deck vertical density profile instead of a uniform extruded box.
		float strata = 0.78 + 0.22 * cos((alt - 0.28) * 6.28318);
		float field = smoothstep(0.42, 0.64, n);
		float shape = foot.g * smoothstep(0.08, 0.62, foot.r) * height * strata;
		float charge = smoothstep(0.50, 0.72, n) * field;
		float flash = tick_light(WORLD_POSITION.xz);
		for (int i = 0; i < 8; i++) {
			vec3 delta = WORLD_POSITION - flashes[i].xyz;
			flash += exp(-dot(delta, delta) / 240.0) * flashes[i].w;
		}
		DENSITY = field * shape * 0.046 * gain_a;
		ALBEDO = mix(vec3(0.04, 0.085, 0.14), vec3(0.12, 0.36, 0.46), charge);
		EMISSION = mix(vec3(0.006, 0.014, 0.022), vec3(0.015, 0.05, 0.085), field) * mix(0.70, 1.0, alt);
		EMISSION += vec3(0.04, 0.20, 0.27) * charge * mix(0.70, 1.0, alt);
		EMISSION += vec3(0.12, 0.50, 1.0) * flash * field * 2.5;
		EMISSION += combat_scatter(WORLD_POSITION, field) * field * 0.48;
	}
}
"""
