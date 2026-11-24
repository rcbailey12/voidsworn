// render/line_style.gd (issue 1374, R362): one width, glow and fade for every board line
const float LS_CORE_W = 0.32;
const float LS_CORE_PX = 1.4;
const float LS_GLOW_W = 1.9;
const float LS_GLOW_K = 0.3;
const float LS_WIDEN_DIM = 0.6;
const float LS_BREATH = 0.18;
float ls_core_w(float fw) { return max(LS_CORE_W, LS_CORE_PX * fw); }
float ls_dim(float w) { return mix(1.0, LS_CORE_W / w, LS_WIDEN_DIM); }
float ls_line(float d, float fw, float g) {
	float w = ls_core_w(fw);
	float core = smoothstep(-fw, 0.0, d) * (1.0 - smoothstep(w - 0.5 * fw, w + 0.5 * fw, d));
	float gl = g * LS_GLOW_K * clamp(1.0 - (d - w) / LS_GLOW_W, 0.0, 1.0) * step(w, d);
	return max(core, gl) * ls_dim(w);
}
float ls_breath(vec3 wp, float t) { return 1.0 - LS_BREATH + LS_BREATH * sin(t * 1.3 + wp.x * 0.05 + wp.z * 0.04); }
const vec3 LS_MOVE_RIM = vec3(0.30, 0.62, 0.85);
const vec3 LS_MOVE_RIM_HOT = vec3(0.64, 0.88, 1.0);
const vec3 LS_THREAT = vec3(0.941, 0.918, 0.871);
const vec3 LS_BOLT_CORE = vec3(2.2, 2.1, 2.4);
const vec3 LS_BOLT_SKIRT = vec3(0.005, 0.8, 2.0);
const vec3 LS_BOLT_CORONA = vec3(0.40, 0.72, 1.10);
