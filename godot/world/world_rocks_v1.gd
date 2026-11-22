extends RefCounted
# Issue 1361: the asteroid look as it was on main before World V2 (world_rocks.gd at the merge base), kept only so the
# PC capture can draw before and after on one commit (VS_1361_OLD=1 with VS_1361_OLD_DIR pointing at the old rock
# files). Nothing in the game reads this file otherwise. Remove it once Ryan has accepted the 1361 captures.

const ROCK_SHADER := """
shader_type spatial;
render_mode cull_back;
// A sphere about the pose's origin bounds every orientation of this batch's mesh.
instance uniform float rock_radius = 1.0;
global uniform float cam_near;
global uniform vec4 cam_eye;
global uniform vec3 cam_fwd;
varying flat float camera_cover;
// #230 option B (issue #541): rocks turn at their stored rate under the cap law by default; VS_ROCK_TUMBLE=0 holds the pose.
uniform float tumble_k = 0.0;
uniform int kind = 0;
uniform vec3 base = vec3(0.09, 0.075, 0.062);
uniform vec3 fresh = vec3(0.16, 0.15, 0.14);
uniform sampler3D detail : filter_linear, repeat_enable;
uniform float q = 1.0;
// Only the living debris material enables this; blockers and far fields keep their finish.
uniform float debris_glint = 0.0;
uniform vec3 sun_v = vec3(0.45, 0.70, 0.55);
uniform bool legacy_debris = false;
uniform bool living_terrain = false;
uniform bool scanned = false;
uniform vec3 board_c = vec3(0.0);
uniform vec2 haze_r = vec2(320.0, 2200.0);
uniform vec3 haze_col = vec3(0.01, 0.012, 0.02);
uniform float haze_max = 0.85;
uniform float depth_haze = 1.0;
uniform vec3 rim_pos = vec3(0.0);
uniform vec3 rim_col = vec3(1.0, 0.6, 0.3);
uniform float rim_k = 0.0;
uniform vec3 glow_col = vec3(0.25, 0.75, 1.0);
uniform sampler2D sky_tex : filter_linear_mipmap, repeat_enable;
uniform float has_sky = 0.0;
uniform float sky_gain = 1.0;
uniform mat3 turn = mat3(1.0);
uniform float lift = 1.0;      // the board's own blockers are lifted a little so terrain reads at a glance
varying vec3 vL;
varying vec4 vC;
varying vec3 vW;
varying float vSeed;
varying float vScale;
uniform float amb = 0.5;       // r8: how much of the scene's flat ambient a rock takes (space rock is dark on its night side)
vec3 rot(vec3 v, vec3 ax, float a) { float c = cos(a); float s = sin(a); return v * c + cross(ax, v) * s + ax * dot(ax, v) * (1.0 - c); }
vec3 h33(vec3 p) { p = fract(p * vec3(0.1031, 0.1030, 0.0973)); p += dot(p, p.yxz + 33.33); return fract((p.xxy + p.yxx) * p.zyx); }
// r8: impact craters in the rock's own space (they stay on its surface): a bowl, a raised rim and a little ejecta, in
// cells of a 3D grid (about half the cells hold one). x: height (object units per cell), y: crater floor, z: rim
vec3 craters(vec3 p, float dens) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 o = vec3(0.0);
	for (int z = -1; z <= 1; z++) {
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec3 g = vec3(float(x), float(y), float(z));
				vec3 hs = h33(i + g);
				if (hs.z > dens) { continue; }
				vec3 c = g + 0.2 + 0.6 * h33(i + g + 17.3);
				float rad = 0.22 + 0.3 * hs.x * hs.x;
				float d = length(c - f) / rad;
				if (d < 1.8) {
					float bowl = d < 1.0 ? d * d - 1.0 : 0.0;
					float rim = exp(-pow((d - 1.0) / 0.2, 2.0));
					float ej = d > 1.0 ? exp(-(d - 1.0) * 4.0) * 0.12 : 0.0;
					o.x += (bowl * 0.55 + rim * 0.22 + ej) * rad * (0.6 + 0.6 * hs.y);
					o.y = max(o.y, d < 1.0 ? 1.0 - d * d : 0.0);
					o.z = max(o.z, rim);
				}
			}
		}
	}
	return o;
}
void vertex() {
	vL = VERTEX;
	vScale = length(MODEL_MATRIX[0].xyz);
	float radius = rock_radius * max(vScale, max(length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz)));
	// Artoo, PR 1306: measure from the gameplay camera the rig publishes, not this pass's own camera, so a shadow pass
	// (seen from the light) fades the rock exactly as the view does. Without a live rig, the pass's camera is used.
	vec3 eye = cam_eye.w > 0.5 ? cam_eye.xyz : CAMERA_POSITION_WORLD;
	vec3 fwd = cam_eye.w > 0.5 ? cam_fwd : -INV_VIEW_MATRIX[2].xyz;
	float clearance = distance(eye, MODEL_MATRIX[3].xyz) - radius;
	// Issue 1264: fade the whole instance before the live near plane (cam_near, set by camera_rig.gd: 1, 5 or 15 by
	// zoom since issue 368) can cut its surface. Depth along the view, not straight-line distance, is what the near
	// plane cuts, so a rock off to the side fades by its depth too.
	float depth_clear = dot(MODEL_MATRIX[3].xyz - eye, fwd) - radius;
	camera_cover = smoothstep(cam_near + 1.5, cam_near + 1.5 + max(1.0, radius * 0.25), min(clearance, depth_clear));
	vC = COLOR;
	vec4 ic = INSTANCE_CUSTOM;
	vSeed = ic.w;
	float axis_length = length(ic.xyz);
	if (axis_length > 1e-6) {
		vec3 ax = ic.xyz / axis_length;
		float a = ic.w * 6.2831 + TIME * axis_length * tumble_k; // Keep the seeded starting pose; the slow law turns from it by default.
		VERTEX = rot(VERTEX, ax, a);
		NORMAL = rot(NORMAL, ax, a);
	}
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
vec3 bump_normal(vec3 n, vec3 pos, float h, float k) {
	vec3 dpdx = dFdx(pos); vec3 dpdy = dFdy(pos);
	float dhx = dFdx(h); float dhy = dFdy(h);
	vec3 r1 = cross(dpdy, n); vec3 r2 = cross(n, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dhx * r1 + dhy * r2);
	return normalize(abs(det) * n - grad * k);
}
void fragment() {
	// The legacy scatter and living clumps are alternative presentations of the same hexes.
	if (legacy_debris && living_terrain) { discard; }
	// Opaque screen-door fade: keep depth and back-face culling, never draw the inside to fill a cut.
	float screen_dither = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
	if (camera_cover <= screen_dither) { discard; }
	vec3 p = vL * 2.2 + vSeed * 13.7;
	float n1 = texture(detail, p * 0.21).r;
	float n2 = texture(detail, p * 0.73 + 0.31).r;
	// the finest grit fades out where it would shimmer (small on screen)
	float fw = length(fwidth(p * 2.6));
	float n3 = mix(texture(detail, p * 2.6 + 0.57).r, 0.5, clamp(fw * 1.2, 0.0, 1.0));
	float cav = vC.r;
	float crat = scanned ? 0.0 : vC.g;
	// r8: shader craters at two sizes, faded out where they would be smaller than a few pixels (no shimmer far away)
	vec3 cp = vL + vSeed * 7.31;
	float fwc = length(fwidth(cp));
	vec3 c1 = vec3(0.0);
	vec3 c2 = vec3(0.0);
	if (!scanned) {
		c1 = craters(cp * 2.6, 0.55);
		c2 = craters(cp * 7.5 + 3.1, 0.6);
	}
	float k1 = 1.0 - smoothstep(0.05, 0.14, fwc * 2.6);
	float k2 = 1.0 - smoothstep(0.04, 0.1, fwc * 7.5);
	float c_h = c1.x / 2.6 * k1 + c2.x / 7.5 * k2;
	float c_fl = max(c1.y * k1, c2.y * k2 * 0.7);
	float c_rim = max(c1.z * k1, c2.z * k2 * 0.7);
	crat = max(crat, c_fl * 0.8);
	float facet = vC.b;
	float patchv = vC.a;
	vec3 a = base * mix(0.72, 1.25, patchv) * (0.78 + 0.45 * n1) * (0.86 + 0.28 * n2);
	a *= 1.0 - crat * 0.25;
	float rough = 0.9;
	float metal = 0.0;
	vec3 em = vec3(0.0);
	float fr = clamp(facet * 0.8 + smoothstep(0.62, 0.8, n1) * 0.25, 0.0, 1.0);
	if (kind == 0) {
		a = mix(a, fresh * (0.85 + 0.3 * n2), fr * 0.7);
		a *= mix(vec3(1.0), vec3(1.06, 0.98, 0.9), smoothstep(0.4, 0.7, n2));
	} else if (kind == 1) {
		float m = clamp(fr + smoothstep(0.6, 0.75, n2) * 0.5, 0.0, 1.0);
		a = mix(a, fresh, m);
		metal = mix(0.15, 0.85, m);
		rough = mix(0.82, 0.38, m) + n3 * 0.1;
	} else if (kind == 2) {
		a *= 1.0 + smoothstep(0.7, 0.85, n3) * 0.8;
		a = mix(a, fresh, fr * 0.3);
		rough = 0.96;
	} else if (kind == 3) {
		// r2: dark dusty crust, clean ice only in the fresh breaks and a few patches, frosty rather than glossy (r1's ice
		// covered most faces at roughness 0.2 and read as pale blue plastic)
		float ice = clamp(fr * 0.85 + smoothstep(0.64, 0.8, n1) * 0.4 - crat * 0.4, 0.0, 1.0);
		ice *= ice;
		a = mix(a, fresh * (0.8 + 0.3 * n2), ice);
		rough = mix(0.88, 0.42, ice);
		float crack = smoothstep(0.93, 0.985, 1.0 - abs(n2 * 2.0 - 1.0));
		em = glow_col * crack * ice * 0.05;
	} else {
		a = mix(a, fresh, fr * 0.5);
		// r2: thinner and dimmer veins, only in the fresh faces (r1 laced every rock with a bright net)
		float vein = smoothstep(0.965, 0.995, 1.0 - abs(n1 * 2.0 - 1.0)) * smoothstep(0.2, 0.7, fr);
		em = glow_col * vein * 0.3;
		rough = mix(0.85, 0.4, fr);
	}
	// r8: fresh, lighter rock on crater rims, a little dust darkening their floors
	a *= (1.0 + c_rim * 0.35) * (1.0 - c_fl * 0.12);
	// r11: a warm cast on stone, iron crust and carbon (the cool ambient and fill light turned them blue-grey)
	if (kind != 3 && kind != 4) { a *= vec3(1.12, 1.0, 0.84); }
	a *= mix(0.4, 1.0, cav) * lift;
	// height in world units (object units times the rock's scale): craters plus grit, so the bump reads the same on a
	// pebble and on a mountain
	float ht = (c_h + (n2 - 0.5) * 0.05 + (n3 - 0.5) * 0.02 - crat * 0.01) * vScale;
	NORMAL = bump_normal(NORMAL, VERTEX, ht, q > 0.5 ? 1.0 : 0.6);
	ALBEDO = a;
	ROUGHNESS = rough;
	METALLIC = metal;
	// r2: a dull dielectric sheen (the default 0.5 caught the cold fill light and turned brown rock grey-blue)
	// r11: less for plain rock (its dull sheen picked up the blue of the sky and the fill light and read as frost)
	SPECULAR = kind == 3 ? 0.5 : (kind == 1 ? 0.3 : 0.12);
	if (debris_glint > 0.0) {
		vec3 sun = normalize((VIEW_MATRIX * vec4(sun_v, 0.0)).xyz);
		vec3 half_v = normalize(sun + VIEW);
		float glint = pow(max(dot(NORMAL, half_v), 0.0), 96.0) * max(dot(NORMAL, sun), 0.0);
		em += vec3(0.55, 0.43, 0.25) * glint * fr * debris_glint;
	}
	// r8: the flat ambient (and the sky's reflection) cut on rock, more in its hollows; the key light keeps full strength,
	// so a rock has a lit side and a dark side like the ships do, instead of an evenly grey-blue lump
	AO = mix(0.35, 1.0, cav) * amb;
	AO_LIGHT_AFFECT = 0.0;
	if (rim_k > 0.0) {
		vec3 nw = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		vec3 L = rim_pos - vW;
		float dl = length(L);
		L /= max(dl, 1e-3);
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
		float face = clamp(dot(nw, L) * 0.8 + 0.2, 0.0, 1.0);
		float fall = 1.0 / (1.0 + dl * dl / 40000.0);
		em += rim_col * rim_k * face * (0.06 + 0.9 * fres) * fall;
	}
	// far rocks sink into the sky behind them (its own colour, read from the baked nebula along the view ray): by distance
	// from the board, and more by how far below its plane they lie, so nothing deep can pass for a rock on a hex
	float dist = length(vW - board_c);
	float below = -(vW.y - board_c.y);
	// r2: weaker than r1, whose far rocks turned into pale see-through ghosts; a far rock now stays a dark solid shape
	// against the gas, which reads as far away without reading as a hole in the sky
	float hz = smoothstep(haze_r.x, haze_r.y, dist) * 0.55 + depth_haze * smoothstep(60.0, 700.0, below) * 0.4;
	vec3 hc = haze_col;
	if (has_sky > 0.5) {
		vec3 d = turn * normalize(vW - CAMERA_POSITION_WORLD);
		vec2 uv = vec2(atan(d.x, -d.z) / 6.28318530718 + 0.5, acos(clamp(d.y, -1.0, 1.0)) / 3.14159265359);
		// r8: a darkened, blurred sky colour (a full-strength sky picture made far rocks look see-through: the fog painted
		// the nebula's own pattern onto them); far rocks now read as dimmer solid shapes against the gas
		hc = pow(textureLod(sky_tex, uv, 4.0).rgb, vec3(2.2)) * sky_gain * 0.4 + haze_col * 0.5;
	}
	FOG = vec4(hc, clamp(hz, 0.0, 1.0) * haze_max);
	// lifted rocks (the board's blockers) catch a soft cool rim from the sky, which separates them from the dark board
	em += vec3(0.05, 0.065, 0.09) * (lift - 1.0) * pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	// glow fades with the haze too (fog does not dim emission enough: deep rocks kept bright veins)
	EMISSION = em * (1.0 - clamp(hz, 0.0, 1.0));
}
"""

const CRYSTAL_SHADER := """
shader_type spatial;
render_mode cull_back;
instance uniform float rock_radius = 1.0;
global uniform float cam_near;
global uniform vec4 cam_eye;
global uniform vec3 cam_fwd;
varying flat float camera_cover;
uniform vec3 glow = vec3(0.3, 0.8, 1.0);
uniform vec3 edge = vec3(0.7, 0.45, 1.0);
uniform float tumble_k = 0.0;   // as ROCK_SHADER: turns at the stored rate unless VS_ROCK_TUMBLE=0 holds it
uniform vec3 board_c = vec3(0.0);
uniform vec2 haze_r = vec2(320.0, 2200.0);
uniform vec3 haze_col = vec3(0.01);
uniform float haze_max = 0.85;
varying vec4 vC;
varying vec3 vW;
varying float vSeed;
vec3 rot(vec3 v, vec3 ax, float a) { float c = cos(a); float s = sin(a); return v * c + cross(ax, v) * s + ax * dot(ax, v) * (1.0 - c); }
void vertex() {
	vC = COLOR;
	float scale = max(length(MODEL_MATRIX[0].xyz), max(length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz)));
	float radius = rock_radius * scale;
	// Artoo, PR 1306: measure from the gameplay camera the rig publishes, not this pass's own camera, so a shadow pass
	// (seen from the light) fades the rock exactly as the view does. Without a live rig, the pass's camera is used.
	vec3 eye = cam_eye.w > 0.5 ? cam_eye.xyz : CAMERA_POSITION_WORLD;
	vec3 fwd = cam_eye.w > 0.5 ? cam_fwd : -INV_VIEW_MATRIX[2].xyz;
	float clearance = distance(eye, MODEL_MATRIX[3].xyz) - radius;
	// Issue 1264: as ROCK_SHADER, fade before the live near plane cuts the surface.
	float depth_clear = dot(MODEL_MATRIX[3].xyz - eye, fwd) - radius;
	camera_cover = smoothstep(cam_near + 1.5, cam_near + 1.5 + max(1.0, radius * 0.25), min(clearance, depth_clear));
	vec4 ic = INSTANCE_CUSTOM;
	vSeed = ic.w;
	float axis_length = length(ic.xyz);
	if (axis_length > 1e-6) {
		vec3 ax = ic.xyz / axis_length;
		float a = ic.w * 6.2831 + TIME * axis_length * tumble_k; // Crystal clusters turn with their rocks under the same law.
		VERTEX = rot(VERTEX, ax, a);
		NORMAL = rot(NORMAL, ax, a);
	}
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float screen_dither = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
	if (camera_cover <= screen_dither) { discard; }
	float up = vC.g;
	float f = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.0);
	ALBEDO = vec3(0.02, 0.035, 0.05);
	ROUGHNESS = 0.08;
	METALLIC = 0.3;
	SPECULAR = 0.9;
	float pulse = 0.85 + 0.15 * sin(TIME * 0.7 + vSeed * 17.0);
	EMISSION = (glow * (0.12 + 0.9 * up * up) + mix(glow, edge, f) * f * 0.9) * pulse;
	float dist = length(vW - board_c);
	float below = -(vW.y - board_c.y);
	FOG = vec4(haze_col, clamp(smoothstep(haze_r.x, haze_r.y, dist) * 0.55 + smoothstep(60.0, 700.0, below) * 0.4, 0.0, 1.0) * haze_max);
}
"""

const KINDS := {
	"stone": {"base": Vector3(0.12, 0.098, 0.078), "fresh": Vector3(0.27, 0.235, 0.2), "k": 0},
	"iron": {"base": Vector3(0.085, 0.066, 0.054), "fresh": Vector3(0.44, 0.41, 0.38), "k": 1},
	"carbon": {"base": Vector3(0.045, 0.041, 0.038), "fresh": Vector3(0.09, 0.085, 0.08), "k": 2},
	"ice": {"base": Vector3(0.085, 0.086, 0.092), "fresh": Vector3(0.5, 0.62, 0.74), "k": 3},
	"crystal": {"base": Vector3(0.06, 0.058, 0.064), "fresh": Vector3(0.14, 0.14, 0.16), "k": 4},
}
