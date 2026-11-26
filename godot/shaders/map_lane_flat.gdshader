shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(1.0);
uniform float px = 0.6;
void fragment() {
	float d = abs(UV.x - 0.5) / max(fwidth(UV.x), 0.00001);
	float line = 1.0 - smoothstep(px - 0.5, px + 0.5, d);
	float ends = smoothstep(0.0, 0.02, UV.y) * smoothstep(1.0, 0.98, UV.y);
	ALBEDO = col.rgb;
	ALPHA = col.a * line * ends;
}
