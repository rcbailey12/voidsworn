shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_front, shadows_disabled, fog_disabled;
uniform vec3 atmo = vec3(0.4, 0.6, 1.0);
uniform vec3 sun = vec3(0.45, 0.7, 0.55);
uniform float k = 1.0;
uniform float shell = 1.04;
varying vec3 vW;
varying vec3 vC;
void vertex() { vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; vC = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz; }
void fragment() {
	vec3 N = normalize(vW - vC);
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	// back faces of the shell: the ray's closest approach to the centre, in shell radii, says how much air it crossed
	vec3 ro = CAMERA_POSITION_WORLD - vC;
	vec3 rd = -V;
	float R = length(vW - vC);
	float tc = -dot(ro, rd);
	float dmin = length(ro + rd * tc) / R;
	float inner = 1.0 / shell;
	float a = (1.0 - smoothstep(inner, 1.0, dmin));
	a = a * a * smoothstep(inner * 0.985, inner + 0.004, dmin);
	vec3 P = normalize(ro + rd * tc);
	float lit = smoothstep(-0.35, 0.5, dot(P, normalize(sun)));
	ALBEDO = atmo * a * lit * k * 1.4;
}
