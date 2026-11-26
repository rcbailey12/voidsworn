shader_type spatial;
render_mode depth_draw_never, cull_back;

#include "res://shaders/map_noise.gdshaderinc"

uniform float cover = 0.5;
uniform float seed = 0.0;
uniform float q = 1.0;
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	vec3 p = normalize(lp);
	int o = q > 0.5 ? 5 : 3;
	float n = mfbm(p * 3.0 + vec3(TIME * 0.006, 0.0, seed) + mfbm(p * 6.0 + seed, 3) * 0.5, o);
	float c = smoothstep(1.0 - cover, 1.0 - cover + 0.25, n);
	ALBEDO = vec3(0.22, 0.25, 0.28);
	ROUGHNESS = 0.9;
	ALPHA = c * 0.85;
}
