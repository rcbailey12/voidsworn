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
uniform bool clear_glass = false;
uniform float inner_glow = 0.0;
uniform vec3 core_light = vec3(1.0);

instance uniform vec3 core_origin = vec3(0.0);
instance uniform float core_falloff = 0.0;
varying vec3 core_offset;

void vertex() {
	core_offset = mat3(MODEL_MATRIX) * (VERTEX - core_origin) * core_falloff;
}

vec2 sky_uv(vec3 d) {
	return vec2(atan(d.x, -d.z) / TAU + 0.5, acos(clamp(d.y, -1.0, 1.0)) / PI);
}

vec3 sky_reflection(vec3 ray) {
	vec3 gas = textureLod(nebula, sky_uv(sky_turn * ray), 0.4).rgb;
	vec2 uv = sky_uv(ray);
	vec3 stars = textureLod(panorama, vec2(1.0 - uv.x, uv.y), 0.65).rgb;
	vec3 sun = normalize(sun_direction);
	vec3 across = normalize(cross(abs(sun.y) < 0.95 ? vec3(0, 1, 0) : vec3(0, 0, 1), sun));
	vec3 up = cross(sun, across);
	vec3 strip_axis = normalize(sun + 0.55 * across + 0.18 * up);
	float along = dot(ray, up);
	float width = dot(ray, normalize(cross(up, strip_axis)));
	float ends = (1.0 - smoothstep(0.42, 0.82, abs(along))) * smoothstep(0.18, 0.70, dot(ray, strip_axis));
	float broad_band = 1.0 - smoothstep(0.025, 0.115, abs(width + 0.075));
	float soft_band = 1.0 - smoothstep(0.018, 0.065, abs(width - 0.095));
	float bright_line = 1.0 - smoothstep(0.004, 0.020, abs(width - 0.015));
	vec3 strip = vec3(0.66, 0.82, 1.0) * ends * (1.9 * broad_band + 1.15 * soft_band + 3.25 * bright_line);
	return pow(gas, vec3(2.2)) * nebula_gain + stars * panorama_gain + strip;
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
	if (clear_glass) {
		thickness = mix(0.07, 0.52, optical_depth) / max(facing, 0.33);
		absorption = vec3(mix(0.04, 1.35, smoke));
	}
	vec3 transmission = exp(-absorption * thickness);

	vec3 ray = normalize(mat3(INV_VIEW_MATRIX) * reflect(-v, n));
	vec3 sun = normalize(sun_direction);
	float star = pow(max(dot(ray, sun), 0.0), 430.0);
	float glint = pow(max(dot(ray, sun), 0.0), 125.0);
	vec3 lobe_direction = normalize(sun + vec3(-0.10, 0.075, 0.10));
	float broad_lobe = pow(max(dot(ray, lobe_direction), 0.0), 43.0);
	vec3 reflected = sky_reflection(ray);
	vec3 key = (vec3(1.0, 0.94, 0.84) * (star * 8.0 + glint * 0.19)
		+ vec3(0.74, 0.88, 1.0) * broad_lobe * 0.85) * sun_gain;
	vec3 reflected_glass = reflected * fresnel + key * max(0.28, fresnel);
	reflected_glass += (neutral_glass ? vec3(0.42) : vec3(0.30, 0.45, 0.58)) * rim;

	vec3 into = refract(-v, n, 1.0 / 1.46);
	vec2 texel = 1.0 / VIEWPORT_SIZE;
	vec2 bend = (into.xy + v.xy) * vec2(1.0, -1.0) * texel * (3.0 + 11.0 * thickness);
	vec2 uv = SCREEN_UV + bend;
	float blur = clamp((thickness - 0.5) * 0.66, 0.0, 1.3);
	vec3 through = textureLod(opaque_scene, uv, blur).rgb;

	// Chromatic separation is visible at grazing edges and around a sharp glint.
	float edge_fringe = clear_glass ? smoothstep(0.50, 0.89, rim) : smoothstep(0.12, 0.62, rim);
	float fringe = dispersion * (clear_glass ? edge_fringe : max(edge_fringe, glint));
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
	vec3 scatter = vec3(0.0);
	if (inner_glow > 0.0 && core_falloff > 0.0 && !reference_glass) {
		// More of the core's light scatters through the thick glass near its edges.
		float reach = exp(-dot(core_offset, core_offset));
		float glass_depth = 0.25 + 0.75 * max(optical_depth, rim);
		scatter = core_light * inner_glow * reach * glass_depth;
	}
	ALBEDO = through * transmission * (1.0 - fresnel) + reflected_glass + scatter;
	ALPHA = 1.0;
}
