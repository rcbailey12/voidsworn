shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform float px = 1.0;
varying vec4 vc;
void vertex() { vc = COLOR; POINT_SIZE = max(1.0, COLOR.a * 3.2 * px); }
void fragment() {
	vec2 q = POINT_COORD * 2.0 - 1.0;
	float r = dot(q, q);
	if (r > 1.0) discard;
	float a = exp(-r * 3.5);
	ALBEDO = vc.rgb * a * 1.6;
}
