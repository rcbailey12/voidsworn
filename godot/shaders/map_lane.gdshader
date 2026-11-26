shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(1.0);
uniform float flow = 0.0;
uniform float hazard = 0.0;
uniform float len = 20.0;
uniform float glow = 1.0;
void fragment() {
	float x = abs(UV.x - 0.5) * 2.0;
	float core = exp(-x * x * 140.0);
	float halo = exp(-x * x * 9.0) * 0.35 * glow;
	float y = UV.y * len;
	float pulse = 0.0;
	if (flow > 0.0) {
		float ph = fract(y / 5.0 - TIME * 0.9);
		pulse = smoothstep(0.0, 0.08, ph) * smoothstep(0.34, 0.08, ph) * flow;
	}
	float idle = 0.5 + 0.5 * smoothstep(0.0, 0.06, abs(fract(y / 9.0 - TIME * 0.12) - 0.5));
	vec3 c = col.rgb * (core * 1.5 + halo) * mix(idle, 1.0, flow) + col.rgb * pulse * (core * 2.5 + halo * 1.6);
	// hazard: red chevrons over the last third
	float hz = hazard * smoothstep(0.62, 0.7, UV.y);
	float chev = step(0.5, fract(y * 0.9 - x * 0.9 - TIME * 0.5)) * exp(-x * x * 5.0);
	c = mix(c, vec3(1.6, 0.28, 0.18) * (core * 1.4 + 0.45 * chev + halo), hz * 0.8);
	float ends = smoothstep(0.0, 0.04, UV.y) * smoothstep(1.0, 0.96, UV.y);
	ALBEDO = c * col.a * ends;
}
