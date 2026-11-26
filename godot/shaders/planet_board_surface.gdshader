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
// Issue 1939 (Neon): the battle camera looks down on the planet's cap. Tip the equator up toward it, as the R01 worlds
// do, so the cap never sits on a pole (terran's blank ice cap filled the top of every battle).
uniform float tilt = 0.0;
uniform vec3 cloud_col = vec3(1.0);   // ash on a volcanic world, white weather elsewhere
uniform vec3 city = vec3(1.0, 0.72, 0.38);
uniform vec3 lava_col = vec3(1.0, 0.36, 0.08);
// Issue 1939 (Neon): fine relief and grain drawn live on top of the 4K maps, so a zoomed-in limb keeps crisp ground
// instead of blurring between texels. Each octave fades out before it gets finer than a screen pixel, so the battle
// camera never shimmers. 0 turns it off (the stand-in and the rocky worlds never use it).
uniform float detail = 0.0;
uniform float detail_grain = 0.0;
// Ryan (Nov 24): terran clouds need more detail. Live fine noise frays thin cloud into wisps while thick cores stay
// solid, and each cloud is shaded by its own thickness toward the sun, so its sunward edge is bright and its far side
// falls into shade. Same fade as the ground detail. 0 turns it off.
uniform float cloud_detail = 0.0;
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
vec3 bp_tilt(vec3 d) { float c = cos(tilt); float s = sin(tilt); return vec3(d.x, c*d.y - s*d.z, s*d.y + c*d.z); }
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
	vec3 d = bp_spin(bp_tilt(normalize(local_direction)), turn);
	float lod = clamp(log2(max(length(dFdx(d)), length(dFdy(d))) * map_scale), 0.0, 10.0);
	vec3 n = normalize(world_point - world_centre);
	vec3 v = normalize(CAMERA_POSITION_WORLD - world_point);
	vec3 l = normalize(sun);
	vec3 alb = flat_col;
	float ocean = 0.0;
	vec4 b = vec4(0.0, 0.0, 0.5, 0.0);
	float h = 0.5;
	float cloud = 0.0;
	float cloud_lit = 0.5;
	float shadow = 0.0;
	if (has_tex > 0.5) {
		vec4 a = bp_sample(tex_a, d, lod);
		alb = a.rgb;
		ocean = a.a;
		b = bp_sample(tex_b, d, lod);
		h = bp_sample(tex_h, d, lod).r;
		cloud = bp_sample(tex_b, bp_spin(d, TIME * cloud_rate), lod).r;
		vec3 toward_light = bp_spin(bp_tilt(normalize(normalize(local_direction) + normalize(local_light) * 0.012)), turn);
		shadow = bp_sample(tex_b, bp_spin(toward_light, TIME * cloud_rate), lod).r;
		// lattice cells per screen pixel at the map's own scale; each octave of live detail fades out before it can alias
		float cells = max(length(dFdx(d)), length(dFdy(d))) * map_scale;
		if (cloud_detail > 0.0) {
			vec3 cq = bp_spin(d, TIME * cloud_rate) * map_scale;
			float c_raw = cloud;   // the map's own thickness, compared with the sunward sample on the same scale (Artoo)
			float c1 = 0.0;
			float c2 = 0.0;
			float c3 = 0.0;
			// an octave that has faded out is not computed at all (Artoo, PR 1983); no derivative is taken in here
			float wc1 = 1.0 - smoothstep(0.25, 0.5, cells * 0.9);
			float wc2 = 1.0 - smoothstep(0.25, 0.5, cells * 2.3);
			float wc3 = 1.0 - smoothstep(0.25, 0.5, cells * 5.7);
			if (wc1 > 0.0) c1 = (wvn3(cq * 0.9 + 31.0) - 0.5) * wc1;
			if (wc2 > 0.0) c2 = (wvn3(cq * 2.3 + 47.0) - 0.5) * wc2;
			if (wc3 > 0.0) c3 = (wvn3(cq * 5.7 + 59.0) - 0.5) * wc3;
			float thin = 1.0 - smoothstep(0.4, 0.9, cloud);
			cloud = clamp(cloud + (c1 * 0.5 + c2 * 0.3 + c3 * 0.2) * cloud_detail * (0.35 + thin), 0.0, 1.0);
			cloud = smoothstep(0.08, 0.9, cloud);
			// thickness just sunward of this point: thinner there means this side faces the sun
			vec3 sunward = bp_spin(bp_tilt(normalize(normalize(local_direction) + normalize(local_light) * 0.004)), turn);
			float c_sun = bp_sample(tex_b, bp_spin(sunward, TIME * cloud_rate), lod).r;
			cloud_lit = clamp(0.5 + (c_raw - c_sun) * 5.0, 0.0, 1.0);
			// billows: the same fine noise lights and shades the cloud's own top
			cloud_lit = clamp(cloud_lit + (c1 * 0.6 + c2 * 0.4) * 0.9, 0.0, 1.0);
		}
		if (detail > 0.0) {
			vec3 dp = d * map_scale;
			float n1 = 0.0;
			float n2 = 0.0;
			float n3 = 0.0;
			float w1 = 1.0 - smoothstep(0.25, 0.5, cells * 1.3);
			float w2 = 1.0 - smoothstep(0.25, 0.5, cells * 3.4);
			float w3 = 1.0 - smoothstep(0.25, 0.5, cells * 8.9);
			if (w1 > 0.0) n1 = (wvn3(dp * 1.3 + 5.1) - 0.5) * w1;
			if (w2 > 0.0) n2 = (wvn3(dp * 3.4 + 11.7) - 0.5) * w2;
			if (w3 > 0.0) n3 = (wvn3(dp * 8.9 + 23.3) - 0.5) * w3;
			float land = 1.0 - ocean;
			float dh = n1 * 0.55 + n2 * 0.3 + n3 * 0.15;
			h += dh * detail * land;
			alb *= 1.0 + dh * detail_grain * land;
		}
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
	vec3 ground = alb * (1.0 - shadow * (cloud_detail > 0.0 ? 0.62 : 0.5));
	vec3 col = ground * (0.02 + lambert * 0.92 * day);
	// clouds: lit tops over the ground, a cool grey toward the terminator
	vec3 ctone = mix(vec3(0.6, 0.63, 0.67), vec3(0.93, 0.94, 0.95), smoothstep(-0.05, 0.4, ndl));
	ctone *= cloud_detail > 0.0 ? mix(0.58, 1.12, cloud_lit) : 1.0;
	col = mix(col, ctone * cloud_col * (0.03 + max(ndl, 0.0) * 0.95) * day, cloud * 0.92);
	// the sun on water or ice: a tight glint with a soft halo
	vec3 hv = normalize(l + v);
	float sp = max(dot(mix(n, nb, 0.35), hv), 0.0);
	col += vec3(1.0, 0.95, 0.86) * glint * ocean * (1.0 - cloud) * pow(sp, 260.0) * 1.1 * day;
	// night side: city lights and lava
	float night = (1.0 - smoothstep(-0.2, 0.06, ndl));
	col += city * b.g * night * 0.85 * (1.0 - cloud * 0.7);
	// lava glows by its heat (issue 1939): deep ember red at the cooling edges, orange, then a yellow-white core
	vec3 hot = mix(lava_col * vec3(0.6, 0.25, 0.3), lava_col, smoothstep(0.08, 0.45, b.a));
	hot = mix(hot, vec3(1.0, 0.86, 0.6), smoothstep(0.55, 0.95, b.a) * 0.8);
	col += hot * b.a * (0.45 + night * 1.2) * (1.0 - cloud * 0.5);
	// the lit limb glows with the atmosphere
	float rim = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 3.0);
	col += atmo * atmo_k * rim * smoothstep(-0.25, 0.4, ndl) * 0.8;
	ALBEDO = col;
}
