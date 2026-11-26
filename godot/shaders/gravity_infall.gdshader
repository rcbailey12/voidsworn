shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 well = vec3(0.0);
uniform float r_out = 87.0;
varying vec2 vQ;
varying float fade;
void vertex() {
	float inner = 20.0;
	float cycle = r_out * 0.5 * log((3.0 * r_out - 2.0 * inner) / r_out);
	float phase = fract(TIME / cycle + INSTANCE_CUSTOM.y);
	float radius = r_out * 1.5 - r_out * 0.5 * exp(2.0 * phase * cycle / r_out);
	// dr/dt = -(3 - 2r/R); the tangential speed is one fifth of the inward speed.
	float angle = INSTANCE_CUSTOM.z * 6.2831853 + 0.2 * log(r_out / radius);
	vec3 p = well + vec3(cos(angle) * radius, 9.0 + INSTANCE_CUSTOM.w * 3.0, sin(angle) * radius);
	vec4 c = VIEW_MATRIX * vec4(p, 1.0);
	vQ = VERTEX.xy * 2.0;
	c.xy += VERTEX.xy * INSTANCE_CUSTOM.x;
	POSITION = PROJECTION_MATRIX * c;
	fade = smoothstep(0.0, 0.08, phase) * (1.0 - smoothstep(0.85, 1.0, phase));
}
void fragment() {
	float r = length(vQ);
	if (r > 1.0) { discard; }
	ALBEDO = vec3(0.32, 0.17, 0.12);
	ALPHA = 0.15 * fade * exp(-r * r * 4.0);
}
