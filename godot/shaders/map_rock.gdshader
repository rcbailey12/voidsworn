shader_type spatial;
render_mode shadows_disabled;

#include "res://shaders/map_noise.gdshaderinc"

uniform vec3 tint : source_color = vec3(0.2, 0.19, 0.18);
uniform float metal = 0.1;
uniform float ember = 0.0;
varying vec3 lp;
varying float smoulder;
void vertex() { lp = VERTEX; smoulder = INSTANCE_CUSTOM.r; }
void fragment() {
	float n = mfbm(lp * 3.0, 4);
	ALBEDO = tint * (0.6 + 0.8 * n);
	ROUGHNESS = 0.85 - metal * 0.4;
	METALLIC = metal;
	float e = smoulder * ember * smoothstep(0.55, 0.7, n) * (0.7 + 0.3 * sin(TIME * 1.3 + lp.x * 5.0));
	EMISSION = vec3(1.0, 0.36, 0.08) * e * 2.0;
}
