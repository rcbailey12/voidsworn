shader_type spatial;

#include "res://shaders/map_noise.gdshaderinc"

#include "res://shaders/map_bump.gdshaderinc"

uniform vec3 heat : source_color = vec3(1.0, 0.38, 0.12);
uniform float gain = 1.0;
void fragment() {
	float fins = abs(fract(UV.x * 14.0) - 0.5);
	float ht = smoothstep(0.1, 0.35, fins);
	NORMAL = bump_normal(NORMAL, VERTEX, ht, 0.6);
	ALBEDO = vec3(0.12, 0.11, 0.11);
	METALLIC = 0.7; ROUGHNESS = 0.5;
	float core = smoothstep(0.5, 0.0, abs(UV.y - 0.5)) * (1.0 - ht * 0.5);
	EMISSION = heat * core * gain * (0.75 + 0.25 * sin(TIME * 0.5 + UV.x * 3.0));
}
