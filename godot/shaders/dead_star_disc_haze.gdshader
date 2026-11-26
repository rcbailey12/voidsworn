shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
global uniform float scene_t;

#include "res://shaders/world_noise.gdshaderinc"

uniform float r_in = 1.0;
uniform float r_out = 3.0;
uniform float spin = 0.25;
uniform float gain = 0.35;
uniform float seed = 0.0;
uniform vec3 hot = vec3(1.0, 0.85, 0.65);
uniform vec3 cool = vec3(0.6, 0.16, 0.05);
varying vec3 vL;
varying vec3 vW;
void vertex() { vL = VERTEX; vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 q = vL.xz;
	float r = length(q);
	float u = clamp((r - r_in) / (r_out - r_in), 0.0, 1.0);
	float a = atan(q.y, q.x) + scene_t * spin * 0.8 / pow(max(r / r_in, 1.0), 1.5);
	float n = wfbm(vec2(a * 2.5 + log(r) * 5.0 + seed, r * 1.2 + seed));
	float puff = smoothstep(0.35, 0.8, n);
	float dens = smoothstep(0.0, 0.15, u) * (1.0 - smoothstep(0.5, 1.0, u)) * puff;
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	vec3 Nw = normalize((MODEL_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	float graz = 1.0 - abs(dot(Nw, V));
	vec3 c = mix(hot, cool, smoothstep(0.1, 0.9, u)) * (2.0 - 1.5 * u);
	vec3 tang = normalize((MODEL_MATRIX * vec4(-q.y, 0.0, q.x, 0.0)).xyz);
	c *= 1.0 + 0.6 * dot(tang, V);
	ALBEDO = c * dens * gain * (0.35 + 0.65 * graz);
}
