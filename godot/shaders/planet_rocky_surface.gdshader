shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, fog_disabled;
uniform sampler2D colour_map : source_color, filter_linear_mipmap, repeat_enable;
// Linear data: RG = 16-bit height, B = roughness, A = cloud coverage.
uniform sampler2D surface_data : filter_linear_mipmap, repeat_enable;
uniform vec3 sun = vec3(0.45, 0.7, 0.55);
uniform float cloud_rate = 0.009;
uniform float shadow_strength = 0.64;
varying vec3 local_direction;
varying vec3 world_point;
varying vec3 world_centre;
varying vec3 local_light;

#include "res://shaders/planet_rocky_surface.gdshaderinc"

void vertex() {
	local_direction = normalize(VERTEX);
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_centre = MODEL_MATRIX[3].xyz;
	local_light = normalize((inverse(MODEL_MATRIX) * vec4(sun, 0.0)).xyz);
}
void fragment() {
	vec3 d = r01_remix(normalize(local_direction));
	// Angular footprint stays finite at poles and the longitude seam. UV
	// derivatives there chose coarse levels in radial bands across the terrain.
	float lod = clamp(log2(max(length(dFdx(d)),length(dFdy(d)))*1303.7973),0.0,11.0);
	vec4 data = r01_sample(surface_data, d, lod);
	vec3 n = normalize(world_point-world_centre);
	vec3 v = normalize(CAMERA_POSITION_WORLD-world_point);
	vec3 l = normalize(sun);
	// Use surface derivatives for relief. This remains stable at the poles and
	// after a board transform, unlike a fixed world-X normal offset.
	float h = r01_height(d, surface_data, lod);
	vec3 dpdx = dFdx(world_point);
	vec3 dpdy = dFdy(world_point);
	vec3 r1 = cross(dpdy,n);
	vec3 r2 = cross(n,dpdx);
	float det = dot(dpdx,r1);
	float radius = length(world_point-world_centre);
	vec3 grad = sign(det)*(dFdx(h)*r1+dFdy(h)*r2);
	vec3 bv = abs(det)*n-grad*radius*0.028;
	vec3 bumped = dot(bv, bv) > 1e-20 ? normalize(bv) : n;   // grazing limb: no NaN into the glow (audit, PR 1776)
	float lambert = max(dot(bumped,l),0.0);
	float day = smoothstep(-0.06,0.18,dot(n,l));
	// The cloud sphere samples this same field, at this same angular rate.
	// A ray from the ground toward the sun reaches the higher cloud layer
	// ahead of the surface sample, separating shadows from the cloud itself.
	vec3 toward_light = r01_remix(normalize(normalize(local_direction) + normalize(local_light)*0.012));
	float shadow = shadow_strength > 0.0 ? r01_cloud(surface_data,r01_spin(toward_light,TIME*cloud_rate),lod) : 0.0;
	vec3 albedo = r01_sample(colour_map,d,lod).rgb;
	albedo = mix(albedo, vec3(dot(albedo, vec3(0.3, 0.55, 0.15))) * 1.5, remix_desat);
	// mineral provinces: broad patches of the battle's tint, so a turned face also reads as a new world
	float prov = smoothstep(0.35, 0.75, wvn3(d * 2.3 + remix_seed));
	albedo *= mix(vec3(1.0), remix_tint, 0.55 + 0.45 * prov) * remix_gain;
	vec3 colour = albedo*(0.022 + lambert*0.88*day)*(1.0-shadow*shadow_strength);
	float spec_power = mix(90.0,7.0,data.b);
	float sheen = pow(max(dot(bumped,normalize(l+v)),0.0),spec_power)*(1.0-data.b)*0.055*day;
	colour += vec3(1.0,0.87,0.72)*sheen;
	float rim = pow(1.0-max(dot(n,v),0.0),4.0)*day;
	colour += vec3(0.32,0.13,0.045)*rim*0.16*step(0.001, shadow_strength);
	ALBEDO = colour;
}
