shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform sampler2D noise : filter_linear_mipmap, repeat_enable;
uniform vec3 c_a = vec3(0.4, 0.2, 0.1);
uniform vec3 c_b = vec3(0.1, 0.15, 0.3);
uniform float gain = 0.06;
varying vec4 vI;
varying vec2 vQ;
void vertex() {
	vI = INSTANCE_CUSTOM;
	vec4 c = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	float a = vI.y * 6.2831;
	vec2 q = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * VERTEX.xy;
	vQ = VERTEX.xy * 2.0;
	c.xy += q * vI.x;
	POSITION = PROJECTION_MATRIX * c;
}
void fragment() {
	float r = length(vQ);
	if (r > 1.0) { discard; }
	vec2 uv = vQ * 0.35 + vI.zw * 7.0 + vec2(TIME * 0.0015, 0.0);
	float n = texture(noise, uv).r;
	float m = texture(noise, uv * 2.3 + n * 0.25 + 0.5).r;
	float d = smoothstep(0.42, 0.85, n * 0.65 + m * 0.35) * smoothstep(1.0, 0.25, r);
	ALBEDO = mix(c_b, c_a, smoothstep(0.3, 0.7, m)) * d * gain;
}
