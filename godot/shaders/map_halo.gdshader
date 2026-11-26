shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://shaders/map_noise.gdshaderinc"

uniform vec4 col : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform vec4 col2 : source_color = vec4(1.0, 0.8, 0.5, 1.0);
uniform float look = 0.0;
uniform float r = 0.85;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float d = length(p);
	float ang = atan(p.y, p.x);
	float band = smoothstep(0.03, 0.0, abs(d - r)) * 1.2 + exp(-(((d - r) / 0.08) * ((d - r) / 0.08))) * 0.4;
	vec3 c = mix(col.rgb, col2.rgb, 0.5 + 0.5 * sin(ang * 3.0 + TIME * 0.4));
	if (look > 1.5 && look < 2.5) c = hue(ang / 6.28318 + TIME * 0.05) * 1.2;
	float pl = (look > 0.5 && look < 1.5) ? 0.65 + 0.45 * sin(TIME * 2.4) : 1.0;
	float seg = 0.75 + 0.25 * step(0.5, fract(ang / 6.28318 * 12.0 + TIME * 0.03));
	ALBEDO = c * band * pl * seg * col.a;
}
