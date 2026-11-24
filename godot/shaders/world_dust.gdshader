shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 col = vec3(0.6, 0.58, 0.55);
uniform float px = 0.0008;
varying float vA;
varying vec2 vQ;
void vertex() {
	vec4 c = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	float size = INSTANCE_CUSTOM.x;
	float depth = max(-c.z, 1.0);
	float mins = depth * px * 1.6;
	float s = max(size, mins);
	float k = clamp(size / mins, 0.0, 1.0);
	vA = k * k * INSTANCE_CUSTOM.y * smoothstep(1600.0, 600.0, depth);
	vQ = VERTEX.xy * 2.0;
	c.xy += VERTEX.xy * s;
	POSITION = PROJECTION_MATRIX * c;
}
void fragment() {
	float r = length(vQ);
	ALBEDO = col * exp(-r * r * 4.0) * vA;
}
