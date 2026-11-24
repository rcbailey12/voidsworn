shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, fog_disabled;
uniform sampler2D tex_a : source_color, filter_linear_mipmap, repeat_enable;   // albedo, ocean or ice sheen (a)
uniform sampler2D tex_b : filter_linear_mipmap, repeat_enable;                 // clouds, city lights, relief, lava
uniform sampler2D tex_h : filter_linear_mipmap, repeat_enable;                 // relief, one 32-bit float channel
uniform float has_tex = 0.0;
uniform vec3 flat_col = vec3(0.3);
uniform vec3 sun = vec3(0.45, 0.7, 0.55);
uniform vec3 atmo = vec3(0.4, 0.6, 1.0);
uniform float atmo_k = 0.5;
uniform float bump = 0.03;
uniform float glint = 1.0;
uniform float map_scale = 651.8986;   // map width / TAU
uniform float cloud_rate = 0.006;
uniform float turn = 0.0;
uniform vec3 cloud_col = vec3(1.0);   // ash on a volcanic world, white weather elsewhere
uniform vec3 city = vec3(1.0, 0.72, 0.38);
uniform vec3 lava_col = vec3(1.0, 0.36, 0.08);
// the procedural stand-in (cold cache, a bake that missed the loading cover, no bake possible): the look's own palette
uniform vec3 col_a = vec3(0.4);
uniform vec3 col_b = vec3(0.15);
uniform vec3 col_c = vec3(0.6);
uniform float stand_sea = 0.0;
uniform float stand_clouds = 0.0;
uniform float stand_seed = 0.0;
varying vec3 local_direction;
varying vec3 world_point;
varying vec3 world_centre;
varying vec3 local_light;

#include "res://shaders/world_noise.gdshaderinc"

vec2 bp_uv(vec3 d) { return vec2(atan(d.x, -d.z) / 6.28318530718 + 0.5, acos(clamp(d.y, -1.0, 1.0)) / 3.14159265359); }
vec3 bp_spin(vec3 d, float a) { return vec3(cos(a)*d.x + sin(a)*d.z, d.y, -sin(a)*d.x + cos(a)*d.z); }
vec4 bp_sample(sampler2D map, vec3 d, float lod) {
	vec2 uv = bp_uv(d);
	float pole_pad = exp2(lod) / (map_scale * 6.28318530718);
	uv.y = clamp(uv.y, pole_pad, 1.0 - pole_pad);
	return textureLod(map, uv, lod);
}
void vertex() {
	local_direction = normalize(VERTEX);
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_centre = MODEL_MATRIX[3].xyz;
	local_light = normalize((inverse(MODEL_MATRIX) * vec4(sun, 0.0)).xyz);
}
void fragment() {
	vec3 d = bp_spin(normalize(local_direction), turn);
	float lod = clamp(log2(max(length(dFdx(d)), length(dFdy(d))) * map_scale), 0.0, 10.0);
	vec3 n = normalize(world_point - world_centre);
	vec3 v = normalize(CAMERA_POSITION_WORLD - world_point);
	vec3 l = normalize(sun);
	vec3 alb = flat_col;
	float ocean = 0.0;
	vec4 b = vec4(0.0, 0.0, 0.5, 0.0);
	float h = 0.5;
	float cloud = 0.0;
	float shadow = 0.0;
	if (has_tex > 0.5) {
		vec4 a = bp_sample(tex_a, d, lod);
		alb = a.rgb;
		ocean = a.a;
		b = bp_sample(tex_b, d, lod);
		h = bp_sample(tex_h, d, lod).r;
		cloud = bp_sample(tex_b, bp_spin(d, TIME * cloud_rate), lod).r;
		vec3 toward_light = bp_spin(normalize(normalize(local_direction) + normalize(local_light) * 0.012), turn);
		shadow = bp_sample(tex_b, bp_spin(toward_light, TIME * cloud_rate), lod).r;
	} else {
		// warped noise continents, a second field for highlands or ice, detail fading where the sphere is small on screen
		vec3 p = d * 2.2 + stand_seed;
		vec3 w = vec3(wfbm3(p), wfbm3(p + 4.7), wfbm3(p + 9.3)) - 0.5;
		float fine = 1.0 - smoothstep(1.5, 5.0, lod);
		float t = wfbm3(p * 1.6 + w * 1.8) + (wfbm3(d * 26.0 + stand_seed) - 0.5) * 0.25 * fine;
		float t2 = wfbm3(d * 5.3 + w * 1.2 + stand_seed + 17.0);
		float land = smoothstep(0.44, 0.52, t);
		alb = mix(col_b, col_a, mix(smoothstep(0.3, 0.7, t), land, stand_sea));
		alb = mix(alb, col_c, smoothstep(0.55, 0.72, t2) * (stand_sea > 0.5 ? land : 1.0) * 0.8);
		ocean = stand_sea * (1.0 - land);
		h = mix(t, max(t, 0.48), stand_sea);
		vec3 q = bp_spin(d, TIME * cloud_rate);
		float cf = wfbm3(vec3(q.x * 4.0, q.y * 11.0, q.z * 4.0) + w * 2.5 + stand_seed + 31.0);
		cloud = smoothstep(0.52, 0.72, cf) * stand_clouds;
	}
	// relief from the surface derivatives (stable at the poles and across the wrap); seas stay flat
	vec3 dpdx = dFdx(world_point);
	vec3 dpdy = dFdy(world_point);
	vec3 r1 = cross(dpdy, n);
	vec3 r2 = cross(n, dpdx);
	float det = dot(dpdx, r1);
	float radius = length(world_point - world_centre);
	vec3 grad = sign(det) * (dFdx(h) * r1 + dFdy(h) * r2);
	vec3 bv = abs(det) * n - grad * radius * bump * (1.0 - ocean * 0.85);
	vec3 nb = dot(bv, bv) > 1e-20 ? normalize(bv) : n;   // grazing limb: no NaN into the glow (audit, PR 1776)
	float ndl = dot(n, l);
	float lambert = max(dot(nb, l), 0.0);
	float day = atmo_k > 0.0 ? smoothstep(-0.1, 0.22, ndl) : smoothstep(-0.04, 0.14, ndl);
	vec3 ground = alb * (1.0 - shadow * 0.5);
	vec3 col = ground * (0.02 + lambert * 0.92 * day);
	// clouds: lit tops over the ground, a cool grey toward the terminator
	vec3 ctone = mix(vec3(0.6, 0.63, 0.67), vec3(0.93, 0.94, 0.95), smoothstep(-0.05, 0.4, ndl));
	col = mix(col, ctone * cloud_col * (0.03 + max(ndl, 0.0) * 0.95) * day, cloud * 0.92);
	// the sun on water or ice: a tight glint with a soft halo
	vec3 hv = normalize(l + v);
	float sp = max(dot(mix(n, nb, 0.35), hv), 0.0);
	col += vec3(1.0, 0.95, 0.86) * glint * ocean * (1.0 - cloud) * (pow(sp, 260.0) * 1.1 + pow(sp, 60.0) * 0.05) * day;
	// night side: city lights and lava
	float night = (1.0 - smoothstep(-0.2, 0.06, ndl));
	col += city * b.g * night * 0.85 * (1.0 - cloud * 0.7);
	col += lava_col * b.a * (0.45 + night * 1.2) * (1.0 - cloud * 0.5);
	// the lit limb glows with the atmosphere
	float rim = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 3.0);
	col += atmo * atmo_k * rim * smoothstep(-0.25, 0.4, ndl) * 0.8;
	ALBEDO = col;
}
