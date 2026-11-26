shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform float r_shadow = 0.5;
uniform vec3 ring_col = vec3(1.0, 0.8, 0.55);
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
void fragment() {
	float th = length(UV - 0.5) * 2.0;
	float sh = smoothstep(r_shadow * 1.02, r_shadow * 0.98, th);
	float ring = exp(-(((th - r_shadow * 1.05) / (r_shadow * 0.035)) * ((th - r_shadow * 1.05) / (r_shadow * 0.035))));
	float ring2 = exp(-(((th - r_shadow * 1.2) / (r_shadow * 0.15)) * ((th - r_shadow * 1.2) / (r_shadow * 0.15)))) * 0.25;
	ALBEDO = ring_col * (ring * 6.0 + ring2 * 2.0) * (1.0 - sh);
	ALPHA = clamp(sh + ring + ring2, 0.0, 1.0);
}
