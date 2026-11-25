uniform bool fleet_reflections = false;
// Issue 1777 (Ship Look V2): more lobes on top of the 1679 gradient, seen only by the reflection probe (cubemap pass):
// a tight warm sun lobe for a real specular highlight on metal plates, a cool bounce band low on the far side (the
// nebula and planet light), and dark-space troughs straight up and straight down so curved armor keeps deep contrast.
uniform bool fleet_reflections_v2 = false;

vec3 fleet_reflection_gradient(vec3 direction, vec3 sun_direction) {
	float sun_side = dot(direction, sun_direction);
	float warm = smoothstep(0.0, 1.0, sun_side);
	float cool = smoothstep(0.0, 1.0, -sun_side);
	vec3 c = vec3(0.12, 0.10, 0.075) * warm + vec3(0.025, 0.036, 0.05) * cool;
	if (fleet_reflections_v2) {
		float fr_lobe = pow(max(sun_side, 0.0), 24.0);   // neutral warm-white (Ryan, Nov 22: the orange lobe browned Eclipse)
		float fr_bd = (direction.y + 0.18) / 0.22;   // Artoo on PR 1786: square by multiplying (pow of a negative base is undefined)
		float fr_band = exp(-fr_bd * fr_bd) * (1.0 - smoothstep(-0.6, 0.2, sun_side));   // and smoothstep edges in order
		float fr_trough = smoothstep(0.55, 0.95, abs(direction.y));
		c = c * (1.0 - 0.75 * fr_trough) + vec3(0.86, 0.83, 0.78) * fr_lobe + vec3(0.045, 0.07, 0.11) * fr_band;
	}
	return c;
}
