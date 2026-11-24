shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://shaders/map_noise.gdshaderinc"

uniform vec3 a : source_color = vec3(0.35, 0.6, 1.0);
uniform vec3 b : source_color = vec3(0.7, 0.4, 1.0);
uniform float gain = 0.6;
uniform float seed = 0.0;
uniform float storm = 0.0;
uniform float storm_rate = 3.0;
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
		float k = floor(TIME * storm_rate + seed * 7.0);
		fl = step(0.86, fract(sin(k * 12.9898 + seed) * 43758.5453)) * storm * smoothstep(0.55, 0.75, n);
	}
	ALBEDO = c * m * gain * (1.0 + fl * 3.0);
}
