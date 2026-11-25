shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(1.0, 1.0, 1.0, 0.3);
uniform float r = 0.8;
uniform float dash = 0.0;
uniform float hot = 0.0;
uniform float fill = 0.0;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float d = length(p);
	float ang = atan(p.y, p.x);
	float w = 0.018 + hot * 0.01;
	float ring = smoothstep(w, 0.0, abs(d - r));
	float seg = fract(ang / 6.28318 * 4.0);
	float outer = smoothstep(0.012, 0.0, abs(d - r - 0.1)) * step(abs(seg - 0.5), 0.22);
	float tick = smoothstep(0.03, 0.0, abs(fract(ang / 6.28318 * 24.0) - 0.5) - 0.44) * step(r - 0.07, d) * step(d, r - 0.025);
	float dsh = dash * step(0.5, fract(ang / 6.28318 * 18.0 - TIME * 0.25)) * smoothstep(0.016, 0.0, abs(d - r - 0.045));
	float inner = smoothstep(r, r * 0.2, d) * (0.06 + fill * 0.1);
	float glow = exp(-(((d - r) / 0.09) * ((d - r) / 0.09))) * (0.25 + hot * 0.4);
	float a = ring * 1.4 + tick * 0.6 + dsh * 1.5 + inner + glow + outer * 0.5 * (0.4 + hot);
	ALBEDO = col.rgb * a * col.a * 1.6;
}
