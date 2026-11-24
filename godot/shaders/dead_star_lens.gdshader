shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
global uniform float scene_t;

#include "res://shaders/world_noise.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform float r_shadow = 0.12;   // shadow radius as a fraction of the quad's half size
uniform float r_einstein = 0.2;
uniform float photon = 1.0;
uniform vec3 ring_col = vec3(1.0, 0.88, 0.68);
// the disc (r6, to match G3's map): its world basis (y is its normal), its radii (world units), and the arcs' strength
uniform mat3 disc_basis = mat3(1.0);
uniform float disc_r_mid = 3.0;
uniform float disc_reach = 5.0;
uniform float arc_gain = 0.8;
uniform float spin = 0.35;
varying vec2 vUv;
varying vec4 vCenterClip;
varying float vHalf;
void vertex() {
	vec3 c = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float half_size = length(MODEL_MATRIX[0].xyz);
	vec4 vp = VIEW_MATRIX * vec4(c, 1.0);
	vp.xy += VERTEX.xy * half_size * 2.0;
	POSITION = PROJECTION_MATRIX * vp;
	vCenterClip = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(c, 1.0));
	vUv = VERTEX.xy * 2.0;
	vHalf = half_size;
}
void fragment() {
	float r = length(vUv);
	if (r > 1.0) { discard; }
	vec2 cs = vCenterClip.xy / vCenterClip.w * 0.5 + 0.5;
	vec2 d = SCREEN_UV - cs;
	// screen offset per unit of r (the quad's half size projected)
	float k = length(d) / max(r, 1e-4);
	vec2 dir = r > 1e-4 ? d / length(d) : vec2(0.0);
	float th = r;
	float re2 = r_einstein * r_einstein;
	float beta = th - re2 / max(th, 1e-3);
	// fade the bending out toward the quad edge so there is no seam
	float edge = smoothstep(1.0, 0.6, r);
	// F4 r8: and as the camera comes near the hole (zoomed in on a ship beside it): within about three shadow radii the
	// bent picture sampled the disc itself and folded it into hard-edged slabs; up close the plain view is cleaner
	float cam_d = length(CAMERA_POSITION_WORLD - (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz);
	float r_sh_w = r_shadow * vHalf;
	edge *= smoothstep(3.6 * r_sh_w, 5.0 * r_sh_w, cam_d);
	float b = mix(th, beta, edge);
	vec2 suv = cs + dir * b * k;
	// only the far background is bent: a source pixel nearer than the far edge of the disc (a ship, the disc itself) is
	// not used, so nothing in front of the hole moves and the disc is never folded into fragments (r6: r4's g01 showed
	// torn copies of the disc round the shadow); its lensed image is drawn below instead, as arcs over and under the shadow
	vec3 H = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float hole_z = -(VIEW_MATRIX * vec4(H, 1.0)).z;
	float dsrc = texture(depth_tex, suv).r;
	vec4 vsrc = INV_PROJECTION_MATRIX * vec4(suv * 2.0 - 1.0, dsrc, 1.0);
	float src_z = -vsrc.z / vsrc.w;
	// F4 r8: nor is a pixel that is itself near (a rock or ship beside or in front of the hole): it was overwritten by bent
	// sky whenever its borrowed pixel was far, which sliced the rocks round the dead star in half
	float dcur = texture(depth_tex, SCREEN_UV).r;
	vec4 vcur = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, dcur, 1.0);
	float cur_z = -vcur.z / vcur.w;
	bool near_px = cur_z < hole_z + disc_reach;
	if (src_z < hole_z + disc_reach || near_px) { suv = SCREEN_UV; }
	// whatever stands in front of the hole hides its shadow, ring and lensed arcs (a ship crossing the dead star)
	float front = 1.0 - smoothstep(hole_z - r_sh_w * 1.6, hole_z - r_sh_w * 1.1, cur_z);
	vec3 col = textureLod(screen_tex, suv, 0.0).rgb;
	// a little extra brightening near the Einstein ring (lensing magnifies)
	float me = (th - r_einstein) / (r_einstein * 0.35);   // signed: squared by hand, pow() is undefined for a negative base
	float mag = 1.0 + 0.6 * exp(-me * me) * edge * (near_px ? 0.0 : 1.0);
	col *= mag;
	// the disc's far side, lensed: a broad arc over the shadow and a thin secondary arc under it (the same recipe as
	// G3's map, BH_LENSED), with Doppler beaming (the side turning toward the camera brighter and bluer)
	vec3 N = normalize(disc_basis[1]);
	vec3 Vd = normalize(H - CAMERA_POSITION_WORLD);
	vec3 fdir = Vd - N * dot(Vd, N);
	fdir = length(fdir) > 1e-4 ? normalize(fdir) : vec3(0.0, 0.0, 1.0);
	vec3 A = normalize(cross(N, Vd));
	vec2 hv = (VIEW_MATRIX * vec4(H, 1.0)).xy;
	vec2 up2 = normalize((VIEW_MATRIX * vec4(H + fdir * disc_r_mid, 1.0)).xy - hv + vec2(0.0, 1e-5));
	vec2 ax2 = normalize((VIEW_MATRIX * vec4(H + A * disc_r_mid, 1.0)).xy - hv + vec2(1e-5, 0.0));
	vec2 pd = r > 1e-4 ? vUv / r : vec2(0.0, 1.0);
	float ts = th / max(r_shadow, 1e-4);         // in shadow radii
	float across = abs(pd.x * ax2.y - pd.y * ax2.x);
	// F4: a smooth change from the upper arc to the lower one (a hard step drew a seam at top-dead-centre, Argon 4.1)
	float up = smoothstep(-0.35, 0.35, dot(pd, up2));
	float w_out = mix(1.4, 1.62, up);
	float band = smoothstep(1.035, 1.07, ts) * (1.0 - smoothstep(w_out - 0.12, w_out, ts));
	float u = clamp((ts - 1.05) / (w_out - 1.05), 0.0, 1.0);
	float ang = atan(pd.y, pd.x);
	float a2 = ang * 3.0 + scene_t * spin * 2.0;
	float sp = wfbm(vec2(a2 * 4.0 + log(max(ts, 1.0)) * 8.0, ts * 7.0));
	vec3 c = mix(vec3(1.0, 0.92, 0.8), vec3(1.0, 0.55, 0.2), smoothstep(0.0, 0.35, u));
	c = mix(c, vec3(0.55, 0.12, 0.04), smoothstep(0.35, 1.0, u)) * (2.2 - 1.6 * u);
	float arc = band * pow(across, 0.7) * (0.55 + 0.7 * sp) * mix(0.8, 1.0, up);
	// which end of the long axis turns toward the camera
	vec3 endp = H + A * disc_r_mid;
	vec3 qE = transpose(disc_basis) * (endp - H);
	vec3 tW = disc_basis * vec3(-qE.z, 0.0, qE.x);
	float dopR = dot(normalize(tW), normalize(CAMERA_POSITION_WORLD - endp)) * sign(spin);
	float beam = clamp(dopR * 2.0, -1.0, 1.0) * dot(pd, ax2);
	c *= 1.0 + 0.45 * beam;
	c = mix(c, c * vec3(0.85, 0.97, 1.2), clamp(beam, 0.0, 1.0) * 0.35);
	c = mix(c, c * vec3(1.1, 0.8, 0.65), clamp(-beam, 0.0, 1.0) * 0.35);
	// the shadow and the photon ring: thin, sharp, hugging the shadow, a little brighter on the approaching side
	float sh = smoothstep(1.02, 0.98, ts);
	float r1 = (ts - 1.02) / 0.011;   // signed: squared by hand, never pow()
	float r2 = (ts - 1.06) / 0.05;
	float ring = (exp(-r1 * r1) * 3.2 * (1.0 + 0.25 * beam) + exp(-r2 * r2) * 0.35) * photon;
	vec3 lensed = mix(col, vec3(0.0), sh) + (c * arc * arc_gain + ring_col * ring) * (0.95 + 0.05 * sin(scene_t * 0.7));
	col = mix(lensed, col, front);
	ALBEDO = col;
	ALPHA = smoothstep(1.0, 0.85, r);
}
