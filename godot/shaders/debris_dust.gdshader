shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
// Linear #d4bf86, with actual alpha rather than the old grey additive specks.
uniform vec3 col = vec3(0.658, 0.521, 0.238);
varying vec2 vQ;
varying vec3 vW;
varying flat vec2 vHex;
varying flat float vA;
void vertex() {
	vHex = INSTANCE_CUSTOM.zw;
	vec3 origin = MODEL_MATRIX[3].xyz;
	// 20 percent of the recorded gas drift (0.193 u/s). Wrap only behind a faded footprint edge.
	origin.xz = vHex + mod(origin.xz - vHex + vec2(0.032, 0.018667) * TIME + 10.0, 20.0) - 10.0;
	origin.y = mod(origin.y + 0.010667 * TIME + 5.0, 7.0) - 5.0;
	vec4 c = VIEW_MATRIX * vec4(origin, 1.0);
	vA = INSTANCE_CUSTOM.y;
	vQ = VERTEX.xy * 2.0;
	c.xy += VERTEX.xy * INSTANCE_CUSTOM.x;
	vW = (INV_VIEW_MATRIX * c).xyz;
	POSITION = PROJECTION_MATRIX * c;
}
void fragment() {
	float r = length(vQ);
	if (r > 1.0) { discard; }
	vec2 p = abs(vW.xz - vHex);
	float edge = 8.660254 - max(p.x, p.x * 0.5 + p.y * 0.8660254);
	if (edge <= 0.0) { discard; }
	float high = smoothstep(-4.0, 2.0, vW.y);
	ALBEDO = col * mix(0.38, 0.85, high);
	ALPHA = vA * exp(-r * r * 4.0) * smoothstep(0.0, 0.9, edge) * mix(1.0, 0.25, high);
}
