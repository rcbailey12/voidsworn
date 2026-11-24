shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://shaders/map_noise.gdshaderinc"

uniform vec4 col : source_color = vec4(1.0);
void fragment() {
	vec2 uv = UV - 0.5;
	float r = length(uv) * 2.0;
	float n = mfbm(vec3(UV * 5.0, TIME * 0.01), 4);
	ALBEDO = col.rgb * col.a * pow(clamp(1.0 - r, 0.0, 1.0), 2.0) * (0.45 + 0.55 * n);
}
