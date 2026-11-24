shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;
uniform vec3 atmo : source_color = vec3(0.45, 0.7, 1.0);
uniform vec3 sun_pos = vec3(0.0);
uniform float gain = 1.0;
varying vec3 wn;
varying vec3 wp;
void vertex() { wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 n = normalize(wn);
	vec3 v = normalize(CAMERA_POSITION_WORLD - wp);
	float f = 1.0 - clamp(dot(n, v), 0.0, 1.0);
	float lit = clamp(dot(n, normalize(sun_pos - wp)) * 0.9 + 0.2, 0.0, 1.0);
	float rim = pow(f, 7.0) * (1.0 - smoothstep(0.93, 1.0, f));   // a thin bright limb, clear over the face
	ALBEDO = atmo * rim * lit * 4.0 * gain;
}
