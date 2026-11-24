shader_type spatial;

#include "res://shaders/map_noise.gdshaderinc"

varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	vec2 g = abs(fract(UV * vec2(18.0, 6.0)) - 0.5);
	float grid = smoothstep(0.44, 0.48, max(g.x, g.y));
	vec3 cellc = vec3(0.04, 0.07, 0.16) * (0.85 + 0.3 * mh2(floor(UV * vec2(18.0, 6.0))));
	ALBEDO = mix(cellc, vec3(0.62, 0.64, 0.68), grid);
	METALLIC = mix(0.3, 0.9, grid);
	ROUGHNESS = mix(0.15, 0.4, grid);
}
