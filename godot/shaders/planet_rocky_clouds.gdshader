shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled, fog_disabled;
uniform sampler2D surface_data : filter_linear_mipmap, repeat_enable;
uniform vec3 sun = vec3(0.45,0.7,0.55);
varying vec3 local_direction;
varying vec3 world_point;
varying vec3 world_centre;

#include "res://shaders/planet_rocky_surface.gdshaderinc"

void vertex() {
	local_direction = normalize(VERTEX);
	world_point = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	world_centre = MODEL_MATRIX[3].xyz;
}
void fragment() {
	vec3 n = normalize(world_point-world_centre);
	vec3 d = r01_remix(normalize(local_direction));
	float lod = clamp(log2(max(length(dFdx(d)),length(dFdy(d)))*1303.7973),0.0,11.0);
	float coverage = r01_cloud(surface_data,r01_spin(d,TIME*0.009),lod);
	float day = smoothstep(-0.12,0.3,dot(n,normalize(sun)));
	// thick cores whiter, thin wisps take the dust colour
	vec3 tone = mix(vec3(0.5,0.43,0.33), vec3(0.66,0.6,0.5), smoothstep(0.4, 0.9, coverage));
	ALBEDO = tone*(0.045+day*0.72);
	ALPHA = coverage*0.78;
}
