uniform bool fleet_reflections = false;

vec3 fleet_reflection_gradient(vec3 direction, vec3 sun_direction) {
	float sun_side = dot(direction, sun_direction);
	float warm = smoothstep(0.0, 1.0, sun_side);
	float cool = smoothstep(0.0, 1.0, -sun_side);
	return vec3(0.12, 0.10, 0.075) * warm + vec3(0.025, 0.036, 0.05) * cool;
}
