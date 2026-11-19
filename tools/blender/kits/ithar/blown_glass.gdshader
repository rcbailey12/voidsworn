shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled, fog_disabled;

uniform sampler2D glass_tint : source_color, filter_linear_mipmap_anisotropic, hint_default_white;
uniform sampler2D opaque_scene : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D nebula : repeat_enable, filter_linear_mipmap;
uniform sampler2D panorama : source_color, repeat_enable, filter_linear_mipmap;
uniform mat3 sky_turn = mat3(1.0);
uniform float nebula_gain = 0.0;
uniform float panorama_gain = 0.0;
uniform vec3 sun_direction = vec3(0.45, 0.70, 0.55);
uniform float sun_gain = 1.0;
uniform float smoke = 0.0;
uniform float dispersion = 0.0;
uniform bool reference_glass = false;
uniform bool neutral_glass = false;

vec2 sky_uv(vec3 d) {
	return vec2(atan(d.x, -d.z) / TAU + 0.5, acos(clamp(d.y, -1.0, 1.0)) / PI);
}

vec3 sky_reflection(vec3 ray) {
	vec3 gas = textureLod(nebula, sky_uv(sky_turn * ray), 0.4).rgb;
	vec2 uv = sky_uv(ray);
	vec3 stars = textureLod(panorama, vec2(1.0 - uv.x, uv.y), 0.65).rgb;
	return pow(gas, vec3(2.2)) * nebula_gain + stars * panorama_gain;
}

void fragment() {
	float optical_depth = reference_glass ? 0.22 : 1.0 - smoothstep(0.15, 0.60, texture(glass_tint, UV).r);
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	float facing = clamp(dot(n, v), 0.0, 1.0);
	float rim = pow(1.0 - facing, 4.5);
	float fresnel = 0.042 + 0.958 * rim;
	float thickness = (mix(0.12, 0.75, optical_depth) + smoke * 0.38) / max(facing, 0.32);
	vec3 absorption = mix(vec3(0.14, 0.062, 0.029), vec3(2.15, 1.42, 1.17), smoke);
	if (neutral_glass) {
		absorption = vec3(dot(absorption, vec3(0.2126, 0.7152, 0.0722)));
	}
	vec3 transmission = exp(-absorption * thickness);

	vec3 ray = normalize(mat3(INV_VIEW_MATRIX) * reflect(-v, n));
	vec3 sun = normalize(sun_direction);
	float star = pow(max(dot(ray, sun), 0.0), 430.0);
	float glint = pow(max(dot(ray, sun), 0.0), 125.0);
	vec3 reflected = sky_reflection(ray);
	vec3 key = vec3(1.0, 0.94, 0.84) * (star * 8.0 + glint * 0.19) * sun_gain;
	vec3 reflected_glass = reflected * fresnel + key * max(0.28, fresnel);
	reflected_glass += (neutral_glass ? vec3(0.42) : vec3(0.30, 0.45, 0.58)) * rim;

	vec3 into = refract(-v, n, 1.0 / 1.46);
	vec2 texel = 1.0 / VIEWPORT_SIZE;
	vec2 bend = (into.xy + v.xy) * vec2(1.0, -1.0) * texel * (3.0 + 11.0 * thickness);
	vec2 uv = SCREEN_UV + bend;
	float blur = clamp((thickness - 0.5) * 0.66, 0.0, 1.3);
	vec3 through = textureLod(opaque_scene, uv, blur).rgb;

	// Chromatic separation is visible at grazing edges and around a sharp glint.
	float fringe = dispersion * max(smoothstep(0.12, 0.62, rim), glint);
	if (fringe > 0.015) {
		vec2 split = bend * fringe * 0.54;
		through.r = textureLod(opaque_scene, uv - split, blur).r;
		through.b = textureLod(opaque_scene, uv + split, blur).b;
		vec3 blue_ray = normalize(ray + vec3(0.015, -0.014, 0.0));
		vec3 red_ray = normalize(ray - vec3(0.015, -0.014, 0.0));
		vec3 spectral = pow(max(vec3(dot(red_ray, sun), dot(ray, sun), dot(blue_ray, sun)), 0.0), vec3(990.0));
		reflected_glass += spectral * fringe * 3.8 * sun_gain;
		// Separation at the last few degrees before the silhouette.
		float edge = smoothstep(0.57, 0.92, rim);
		vec3 bands = 0.5 + 0.5 * cos(facing * 36.0 + vec3(0.0, 2.094, 4.189));
		reflected_glass += bands * edge * dispersion * 0.27;
	}
	ALBEDO = through * transmission * (1.0 - fresnel) + reflected_glass;
	ALPHA = 1.0;
}
