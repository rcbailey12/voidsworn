shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://shaders/map_noise.gdshaderinc"

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
