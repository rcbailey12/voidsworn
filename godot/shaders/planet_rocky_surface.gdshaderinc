uniform float remix_turn = 0.0;
uniform float remix_tilt = 0.0;
uniform vec3 remix_tint = vec3(1.0);
uniform float remix_seed = 0.0;
uniform float remix_desat = 0.0;   // an airless barren world drains the data's iron red toward grey rock
uniform float remix_gain = 1.0;    // the look's lift into band 2 (RULEBOOK 3.14) on every face and tint
vec2 r01_uv(vec3 d) {
	return vec2(atan(d.x, -d.z) / 6.28318530718 + 0.5, acos(clamp(d.y, -1.0, 1.0)) / 3.14159265359);
}
vec3 r01_spin(vec3 d, float a) {
	return vec3(cos(a)*d.x + sin(a)*d.z, d.y, -sin(a)*d.x + cos(a)*d.z);
}
// the battle's face of the data: tipped about X, then turned about the pole
vec3 r01_remix(vec3 d) {
	float c = cos(remix_tilt);
	float s = sin(remix_tilt);
	return r01_spin(vec3(d.x, c*d.y - s*d.z, s*d.y + c*d.z), remix_turn);
}
vec4 r01_sample(sampler2D map, vec3 d, float lod) {
	vec2 uv = r01_uv(d);
	// Longitude wraps. Latitude must never blend the opposite hemisphere.
	float pole_pad = exp2(lod) / 8192.0;
	uv.y = clamp(uv.y, pole_pad, 1.0-pole_pad);
	return textureLod(map, uv, lod);
}
float r01_height(vec3 d, sampler2D data_map, float lod) {
	vec2 h = r01_sample(data_map, d, lod).rg;
	return dot(h, vec2(65280.0, 255.0)) / 65535.0;
}

#include "res://shaders/world_noise.gdshaderinc"

// Issue 1765: the R01 cloud field broken into fine wisps. The authored coverage says where weather is; flow-warped noise,
// stretched along the latitude, carves it into thin cyclonic streaks with clear gaps, fading out where the planet is too
// small on screen for the detail to hold still.
float r01_cloud(sampler2D data_map, vec3 s, float lod) {
	float base = r01_sample(data_map, s, lod).a;
	vec3 q = s * 3.1 + remix_seed;
	vec3 w = vec3(wvn3(q), wvn3(q + 5.2), wvn3(q + 9.1)) - 0.5;
	float ang = (w.x + w.y) * 2.4;
	vec3 sw = r01_spin(s, ang * 0.35);
	vec3 p = vec3(sw.x * 11.0, sw.y * 34.0, sw.z * 11.0) + w * 3.0 + remix_seed;
	float f = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) { f += a * wvn3(p); p = p * 2.07 + 1.3; a *= 0.5; }
	float detail = 1.0 - smoothstep(2.5, 6.0, lod);
	float c = mix(base, smoothstep(0.3, 0.72, base + (f - 0.47) * 1.15), detail);
	return c * smoothstep(0.03, 0.22, base);
}
