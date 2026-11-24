shader_type sky;
uniform sampler2D pano : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 sun_dir;

#include "res://shaders/sky_fleet_reflections.gdshaderinc"

void sky() {
	vec3 c = texture(pano, SKY_COORDS).rgb;
	COLOR = min(c * 0.8, vec3(0.6));
	if (AT_CUBEMAP_PASS && fleet_reflections) {
		COLOR += fleet_reflection_gradient(EYEDIR, sun_dir);
	}
}
