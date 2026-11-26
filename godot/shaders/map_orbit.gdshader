shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(0.6, 0.7, 0.9, 0.2);
uniform float ticks = 0.0;
uniform float fade_ends = 0.0;
void fragment() {
	float x = abs(UV.x - 0.5) * 2.0;
	float line = exp(-x * x * 9.0);
	float t = ticks > 0.5 ? (0.55 + 0.45 * step(0.5, fract(UV.y * ticks))) : 1.0;
	float ends = fade_ends > 0.5 ? smoothstep(0.0, 0.35, UV.y) * smoothstep(1.0, 0.65, UV.y) : 1.0;
	ALBEDO = col.rgb * line * col.a * t * ends;
}
