shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://shaders/map_noise.gdshaderinc"

uniform float r_in = 1.0;
uniform float r_out = 3.0;
uniform float spin = 0.3;
uniform float gain = 1.0;
uniform float exposure_gain = 1.0;
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
	ALBEDO *= exposure_gain;
}
