shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(0.5, 0.86, 0.42, 1.0);
uniform vec4 fac : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform float elite = 0.0;
uniform float dim = 1.0;
uniform float phase = 0.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
float line(float d, float w) { float aa = fwidth(d) * 1.2; return 1.0 - smoothstep(w - aa, w + aa, abs(d)); }
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	p.y *= 0.8;
	float dm = abs(p.x) + abs(p.y);                     // diamond distance
	float t = TIME + phase;
	float o1 = line(dm - 0.62, 0.035);
	float o2 = elite * line(dm - 0.76, 0.022);
	float fillv = (1.0 - smoothstep(0.55, 0.62, dm)) * 0.045;
	float pip = 1.0 - smoothstep(0.16, 0.2, dm);
	// corner ticks just outside the outline, on the four points
	float ticks = 0.0;
	ticks += line(abs(p.y), 0.02) * step(0.7, abs(p.x)) * step(abs(p.x), 0.86);
	ticks += line(abs(p.x), 0.02) * step(0.7, abs(p.y)) * step(abs(p.y), 0.86);
	// scan line sweeping down inside the diamond
	float sy = 0.62 - fract(t * 0.45) * 1.24;
	float scan = line(p.y - sy, 0.012) * (1.0 - smoothstep(0.58, 0.62, dm)) * 0.9;
	// pulse ring going out
	float pr = 0.62 + fract(t * 0.6) * 0.38;
	float pulse = line(dm - pr, 0.018) * (1.0 - fract(t * 0.6)) * 0.7;
	// gold crown bar for an elite
	float crown = elite * line(p.y - 0.86, 0.025) * step(abs(p.x), 0.3);
	vec3 c = col.rgb * (o1 * 2.2 + fillv + ticks * 1.2 + scan + pulse) + fac.rgb * pip * 1.8 + vec3(1.0, 0.78, 0.35) * (o2 * 1.8 + crown * 2.2);
	ALBEDO = c * dim;
}
