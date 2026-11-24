shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform float r_shadow = 0.12;
uniform float r_einstein = 0.2;
uniform float photon = 1.0;
uniform vec3 ring_col = vec3(1.0, 0.8, 0.55);
varying vec2 vUv;
varying vec4 vCenterClip;
void vertex() {
	vec3 c = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float half_size = length(MODEL_MATRIX[0].xyz);
	vec4 vp = VIEW_MATRIX * vec4(c, 1.0);
	vp.xy += VERTEX.xy * half_size * 2.0;
	POSITION = PROJECTION_MATRIX * vp;
	vCenterClip = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(c, 1.0));
	vUv = VERTEX.xy * 2.0;
}
void fragment() {
	float r = length(vUv);
	if (r > 1.0) { discard; }
	vec2 cs = vCenterClip.xy / vCenterClip.w * 0.5 + 0.5;
	vec2 d = SCREEN_UV - cs;
	float k = length(d) / max(r, 1e-4);
	vec2 dir = r > 1e-4 ? d / length(d) : vec2(0.0);
	float th = r;
	float re2 = r_einstein * r_einstein;
	float beta = th - re2 / max(th, 1e-3);
	float edge = smoothstep(1.0, 0.6, r);
	float b = mix(th, beta, edge);
	vec2 suv = cs + dir * b * k;
	float hole_z = -(VIEW_MATRIX * vec4((MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz, 1.0)).z;
	float dsrc = texture(depth_tex, suv).r;
	vec4 vsrc = INV_PROJECTION_MATRIX * vec4(suv * 2.0 - 1.0, dsrc, 1.0);
	float src_z = -vsrc.z / vsrc.w;
	if (src_z < hole_z * 0.98) { suv = SCREEN_UV + dir * 0.02 * edge; }
	vec3 col = textureLod(screen_tex, suv, 0.0).rgb;
	float mag = 1.0 + 0.6 * exp(-pow((th - r_einstein) / (r_einstein * 0.35), 2.0)) * edge;
	col *= mag;
	float sh = smoothstep(r_shadow * 1.02, r_shadow * 0.98, th);
	float ring = exp(-pow((th - r_shadow * 1.05) / (r_shadow * 0.035), 2.0)) * photon;
	float ring2 = exp(-pow((th - r_shadow * 1.12) / (r_shadow * 0.08), 2.0)) * photon * 0.35;
	col = mix(col, vec3(0.0), sh) + ring_col * (ring * 6.0 + ring2 * 2.0) * (0.92 + 0.08 * sin(TIME * 0.7));
	ALBEDO = col;
	ALPHA = smoothstep(1.0, 0.85, r);
}
