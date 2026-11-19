shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled, fog_disabled;

uniform sampler2D glass_tint : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D glass_normal : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D opaque_scene : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D nebula : repeat_enable, filter_linear;
uniform sampler2D panorama : source_color, repeat_enable, filter_linear_mipmap;
uniform mat3 sky_turn = mat3(1.0);
uniform float nebula_gain = 0.0;
uniform float panorama_gain = 0.0;
uniform vec3 sun_direction = vec3(0.45, 0.70, 0.55);
uniform float sun_gain = 1.0;

vec2 nebula_uv(vec3 d) {
	return vec2(atan(d.x, -d.z) / TAU + 0.5, acos(clamp(d.y, -1.0, 1.0)) / PI);
}

vec3 sky_reflection(vec3 ray, float gloss) {
	// Sample the textures and rotation of the sky that lights this fight.
	vec3 gas = texture(nebula, nebula_uv(sky_turn * ray)).rgb;
	vec3 pano = textureLod(panorama, vec2(1.0 - nebula_uv(ray).x, nebula_uv(ray).y), 3.0).rgb;
	float sun = max(dot(ray, normalize(sun_direction)), 0.0);
	vec3 star = vec3(1.0, 0.93, 0.82) * (1.6 * pow(sun, gloss) + 0.18 * pow(sun, 14.0));
	return pow(gas, vec3(2.2)) * nebula_gain + pano * panorama_gain + star * sun_gain;
}

vec3 thin_film(float facing, float thickness) {
	const float ior = 1.46;
	float inside = sqrt(1.0 - (1.0 - facing * facing) / (ior * ior));
	vec3 cycles = (2.0 * ior * thickness * inside) / vec3(650.0, 520.0, 445.0);
	return 0.5 + 0.5 * cos(TAU * cycles);
}

void fragment() {
	vec3 tint = texture(glass_tint, UV).rgb;
	vec2 xy = (texture(glass_normal, UV).rg * 2.0 - 1.0) * vec2(0.55, -0.55);
	vec3 n = normalize(NORMAL + TANGENT * xy.x + BINORMAL * xy.y);
	vec3 v = normalize(VIEW);
	float facing = clamp(dot(n, v), 0.0, 1.0);
	float fresnel = 0.04 + 0.96 * pow(1.0 - facing, 4.4);
	vec3 ray = normalize(mat3(INV_VIEW_MATRIX) * reflect(-v, n));
	vec3 reflected = sky_reflection(ray, mix(65.0, 190.0, facing));
	vec3 refracted = refract(-v, n, 1.0 / 1.46);
	vec2 texel = 1.0 / VIEWPORT_SIZE;
	vec2 bend = (refracted.xy + v.xy) * vec2(1.0, -1.0) * texel * 15.0;
	vec2 uv = SCREEN_UV + bend;
	// Cast the red and blue wavelengths to either side of the green ray.
	vec3 through = texture(opaque_scene, uv).rgb;
	through.r = texture(opaque_scene, uv - bend * 0.38).r;
	through.b = texture(opaque_scene, uv + bend * 0.38).b;
	vec3 film = thin_film(facing, mix(355.0, 485.0, smoothstep(0.04, 0.41, tint.r)));
	vec3 absorption = mix(vec3(0.68, 0.80, 0.94), vec3(0.57, 0.72, 0.88), 1.0 - facing);
	vec3 coating = mix(vec3(0.49, 0.62, 0.80), film, 0.74);
	vec3 scatter = (0.02 + 0.10 * tint) * (0.45 + 0.55 * film);
	vec3 reflection = (reflected * (0.5 + 1.25 * coating) + coating * 0.12) * (0.23 + 0.77 * fresnel);
	ALBEDO = through * absorption * (1.0 - 0.73 * fresnel) + reflection + scatter;
	ALPHA = 1.0;
}
