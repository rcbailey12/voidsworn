shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform float gain = 1.0;
uniform float breath = 0.0;

#include "res://shaders/line_style.gdshaderinc"

varying vec4 vcol;
varying vec3 wp;
varying float vg;
varying float vc;
void vertex() { vcol = COLOR; vc = step(1.5, UV.y); vg = UV.y - 2.0 * vc; wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float fw = max(fwidth(UV.x), 0.0001);
	float d = UV.x + vc * 0.5 * ls_core_w(fw);
	float l = ls_line(d, fw, vg);
	float sh = mix(1.0, ls_breath(wp, TIME), breath);
	ALBEDO = vcol.rgb * vcol.a * gain * sh * l;
}
