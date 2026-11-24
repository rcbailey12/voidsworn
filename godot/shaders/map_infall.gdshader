shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform float gain = 0.5;
uniform vec3 centre = vec3(0.0);
varying float heat;
void vertex() {
	vec3 p = MODEL_MATRIX[3].xyz - centre;
	float phase = fract(TIME * 0.06 + INSTANCE_CUSTOM.r);
	// Instance positions are in the ring's local space. Shrink their orbit toward its centre, then recycle.
	VERTEX += inverse(mat3(MODEL_MATRIX)) * (-p * phase * 0.6);
	heat = sin(phase * 3.14159265);
}
void fragment() { ALBEDO = vec3(0.7, 0.25, 0.06) * gain * heat; }
