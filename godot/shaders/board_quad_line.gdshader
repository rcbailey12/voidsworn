shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col = vec4(1.0);
uniform float qw = 3.0;
uniform float wide = 1.0;
#include "res://shaders/line_style.gdshaderinc"
void fragment() {
	float x = abs(UV.x - 0.5) * qw;
	float fw = max(fwidth(x), 0.0001);
	float w = ls_core_w(fw) * wide;
	float l = (1.0 - smoothstep(0.5 * w - 0.5 * fw, 0.5 * w + 0.5 * fw, x)) * ls_dim(w / wide);
	ALBEDO = col.rgb * col.a * l;
}
