shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
instance uniform float flash = 0.0;
instance uniform float branch_flash = 0.0;

#include "res://shaders/line_style.gdshaderinc"

varying vec4 vc;
void vertex() { vc = COLOR; }
void fragment() {
	// Red marks branches, green the hot tube, blue the outer corona.
	// Issue 1269 (Ryan's pick 4, Nov 20): the corona is cool cyan-white, not violet,
	// so storm lightning (danger) never shares the nebula's violet (cover).
	// Keep the halo blue-led before the existing weapon bloom integrates it.
	if (vc.g > 0.5 && !FRONT_FACING) { discard; }
	float pulse = mix(flash, branch_flash, vc.r);
	// Issue 1374 (R362): the colours come from the one line style's role table (render/line_style.gd bolt_*)
	vec3 halo = mix(LS_BOLT_SKIRT, LS_BOLT_CORONA, vc.b);
	vec3 radiance = mix(halo, LS_BOLT_CORE, vc.g);
	// The cyan-white corona peaks outside the cyan skirt, never on the hot tube.
	// Stacking it on the core at the center turned the bloom pale white.
	float weight = vc.a;
	if (vc.b > 0.5) { weight = sin(clamp(vc.a / 0.16, 0.0, 1.0) * 3.14159265) * 0.22; }
	ALBEDO = radiance * weight * pulse;
}
