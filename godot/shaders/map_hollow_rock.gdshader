shader_type spatial;

#include "res://shaders/map_noise.gdshaderinc"

#include "res://shaders/map_bump.gdshaderinc"

uniform vec3 tint : source_color = vec3(0.3, 0.27, 0.24);
uniform float kind = 0.0;
uniform float q = 1.0;
varying vec3 lp;
varying float crater;
void vertex() { lp = VERTEX; crater = COLOR.r; }

void fragment() {
	if (length(lp.xz) < 0.34 + 0.045 * sin(lp.y * 16.0)) discard;

	int o = q > 0.5 ? 5 : 3;
	float strata = 0.5 + 0.5 * sin(lp.y * 9.0 + mfbm(lp * 2.0, 3) * 6.0);
	float dust = mfbm(lp * 3.5 + 2.0, o);
	float grit = mfbm(lp * 6.5, o);
	vec3 col = tint * (0.7 + 0.35 * dust) * (0.88 + 0.18 * strata);
	col *= 1.0 - crater * 0.45;
	if (kind > 1.5) col = mix(col, vec3(0.75, 0.82, 0.9), smoothstep(0.45, 0.7, dust) * 0.6);
	if (kind > 0.5 && kind < 1.5) col = mix(col, vec3(0.42, 0.3, 0.22), smoothstep(0.55, 0.8, grit) * 0.5);
	float ht = grit * 0.35 + dust * 0.4 + smoothstep(0.6, 0.72, mfbm(lp * 4.0 + 5.0, 3)) * -0.2;
	NORMAL = bump_normal(NORMAL, VERTEX, ht, q > 0.5 ? 0.45 : 0.25);
	ALBEDO = col;
	METALLIC = kind > 0.5 && kind < 1.5 ? 0.55 : 0.05;
	ROUGHNESS = kind > 1.5 ? 0.45 : 0.9;
	float f = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	RIM = 0.4; RIM_TINT = 0.6;
	EMISSION = vec3(1.0, 0.55, 0.3) * pow(f, 5.0) * 0.08;
}
