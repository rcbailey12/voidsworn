extends Node3D
# Effects for the A2 engine test, built fresh to ../SPEC.md (the cinematic bar, R16). Nothing reused from the game.
#
# Per ship, a 4 s loop staggered 0.5 s in layout order:
#   engines always on (hot core, flickering plume, long cooling trail; the Corsair sputters and coughs soot)
#   0.0 s  broadside: four port guns ripple 80 ms apart (blast, flame tongue, smoke ring, tracer at 160 u/s, impact)
#   1.25 s beam charge flare, 1.5 s to 2.2 s beam 80 units ahead (white core, faction glow, shimmer, impact flare and sparks)
#   2.4 s  incoming shell hits the starboard side: shield ripple (Corsair patchy), or a hull hit for Chorus and Deathless
#   always a hull breach on the upper port flank (scorched torn hole, hot torn plates, venting gas, debris, fire,
#          spark showers, a secondary pop every 3 s)
# Scene-wide, every 12 s: the Hegemony copy above the formation is destroyed (squibs from 11.6 s, pre-flash from 11.9 s,
#   flash, shockwave, fireball, four chunks of its own mesh with burning edges and squibs, debris and embers, a drifting
#   burning wreck), and it fades back in whole 2 s before the next one.
# Everything with a fixed lifetime follows the clock directly; particle systems are restarted when the clock crosses
# their start time, and the continuous ones run all the time.

const LOOP := 4.0
const STAGGER := 0.5
const DRIFT_SPEED := 3.0
const DRIFT_SPAN := 40.0
const DRIFT_FADE := 1.0
const GUN_GAP := 0.08
const SHELL_SPEED := 160.0
const BROADSIDE_RANGE := 70.0
const RING_LIFE := 2.2
const BEAM_AT := 1.5
const BEAM_T := 0.7
const CHARGE_T := 0.25
const BEAM_LEN := 80.0
const HIT_AT := 2.4
const SHIELD_T := 0.6
const INCOMING_LEN := 60.0
const TRAIL_LEN := 60.0
const BOOM_EVERY := 12.0
const BREAK_AT := 12.4  # first break of the destruction event, then every 12 s
const SPARKS_EVERY := 2.3
const POP_EVERY := 3.7
const WRECK_POS := Vector3(0, 25, 0)
const WRECK_SCALE := 0.6
const BIG_AABB := AABB(Vector3(-60, -60, -60), Vector3(120, 120, 120))

const NOISE := """
float hash12(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x), mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) { return vnoise(p) * 0.55 + vnoise(p * 2.1 + 3.7) * 0.3 + vnoise(p * 4.3 + 7.1) * 0.15; }
"""

const BILLBOARD := """
void vertex() {
	mat4 mw = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	ROTATE
	MODELVIEW_MATRIX = VIEW_MATRIX * mw * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
"""
const PARTICLE_ROTATE := """mw = mw * mat4(vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0),
		vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	seed = INSTANCE_CUSTOM.x;"""

# A camera-facing ribbon from the node origin along its x axis (whose length is the ribbon length), on a subdivided quad.
const RIBBON_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec3 tint_a = vec3(1.0);
uniform vec3 tint_b = vec3(1.0);
uniform float energy = 4.0;
uniform float alpha = 1.0;
uniform float width_a = 1.0;
uniform float width_b = 1.0;
uniform float core = 0.0;
uniform float noise_amt = 0.0;
uniform float noise_scale = 0.3;
uniform float scroll = 0.0;
uniform float waver = 0.0;
uniform float fade_in = 0.02;
uniform float fade_out = 0.8;
uniform float seed = 0.0;
uniform float flicker = 0.0;
uniform float decay = 0.0;
varying float vlen;
""" + NOISE + """
void vertex() {
	vec3 o = MODEL_MATRIX[3].xyz;
	vec3 ax = MODEL_MATRIX[0].xyz;
	float len = max(length(ax), 1e-4);
	vec3 dir = ax / len;
	float s = VERTEX.x + 0.5;
	vec3 p = o + ax * s;
	vec3 up = abs(dir.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
	vec3 b1 = normalize(cross(dir, up));
	vec3 b2 = cross(b1, dir);
	p += (b1 * sin(s * len * 0.11 - TIME * 1.9 + seed) + b2 * sin(s * len * 0.07 - TIME * 1.3 + seed * 1.7)) * waver * s * s;
	vec3 side = normalize(cross(dir, INV_VIEW_MATRIX[3].xyz - p));
	p += side * VERTEX.y * mix(width_a, width_b, s);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(p, 1.0);
	vlen = len;
}
void fragment() {
	float s = UV.x;
	float y = abs(UV.y - 0.5) * 2.0;
	float prof = exp(-y * y * 4.0);
	float hot = exp(-y * y * 30.0) * core * (1.0 - s * 0.7);
	float n = 1.0;
	if (noise_amt > 0.0) {
		n = mix(1.0, fbm(vec2(s * vlen * noise_scale - TIME * scroll, y * 1.5 + seed)) * 1.7, noise_amt);
	}
	float f = smoothstep(0.0, fade_in, s) * (1.0 - smoothstep(fade_out, 1.0, s));
	float fl = 1.0 - flicker * vnoise(vec2(TIME * 23.0, seed * 3.1));
	vec3 col = mix(mix(tint_a, tint_b, s), vec3(1.0), clamp(hot, 0.0, 1.0));
	ALBEDO = col * energy * (prof + hot) * n * f * fl * alpha * exp(-s * decay);
	ALPHA = 1.0;
}
"""

const SPRITE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec3 tint = vec3(1.0);
uniform float energy = 8.0;
uniform float alpha = 0.0;
uniform float spikes = 0.0;
uniform float hot = 1.0;
""" + BILLBOARD + """
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float m = exp(-r * r * 5.0) * (1.0 - smoothstep(0.8, 1.0, r));
	float h = exp(-r * r * 18.0) * hot;
	float sp = spikes * (exp(-abs(p.x) * 30.0) + exp(-abs(p.y) * 30.0)) * (1.0 - smoothstep(0.0, 1.0, r));
	ALBEDO = mix(tint, vec3(1.0), clamp(h, 0.0, 1.0)) * energy * alpha * (m + h + sp);
	ALPHA = 1.0;
}
"""

const FLAME_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float energy = 3.5;
varying float seed;
""" + NOISE + BILLBOARD + """
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float n = fbm(p * 2.2 + vec2(seed * 3.0, seed * 1.3));
	float m = clamp(1.0 - r / (0.55 + 0.45 * n), 0.0, 1.0);
	ALBEDO = COLOR.rgb * energy * m * m * COLOR.a * (0.6 + 0.8 * n);
	ALPHA = 1.0;
}
"""

# Lit smoke puffs: a billboard with a sphere-like normal so the key light shades it like a volume.
const SMOKE_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, specular_disabled;
varying float seed;
""" + NOISE + BILLBOARD + """
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float n = fbm(p * 1.8 + vec2(seed * 2.0, seed));
	float m = 1.0 - smoothstep(0.2, 1.0, r / (0.6 + 0.4 * n));
	NORMAL = normalize(vec3(p.x, -p.y, sqrt(max(0.0, 1.0 - r * r)) + 0.3));
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
	ALPHA = clamp(COLOR.a * m * (0.55 + 0.6 * n), 0.0, 1.0);
}
"""

const SPARK_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float energy = 6.0;
void fragment() {
	ALBEDO = COLOR.rgb * energy * COLOR.a;
	ALPHA = 1.0;
}
"""

const SHIELD_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec3 tint = vec3(1.0);
uniform float energy = 1.4;
uniform float strength = 0.0;
uniform float age = 0.0;
uniform float patchy = 0.0;
uniform vec3 hit_dir = vec3(0.0, 0.0, -1.0);
varying vec3 lp;
""" + NOISE + """
void vertex() {
	lp = VERTEX;
}
void fragment() {
	vec3 d3 = normalize(lp);
	float d = acos(clamp(dot(d3, hit_dir), -1.0, 1.0));
	float partial = 1.0 - smoothstep(1.0, 1.7, d);
	float impact = exp(-d * d * 10.0);
	float ring = exp(-pow((d - age * 3.0) * 6.0, 2.0));
	float ring2 = exp(-pow((d - age * 1.7) * 9.0, 2.0)) * 0.5;
	float fres = pow(1.0 - abs(dot(NORMAL, VIEW)), 3.0);
	float cells = 0.75 + 0.25 * vnoise(vec2(atan(d3.z, d3.x) * 9.0, d3.y * 14.0));
	float a = strength * partial * (0.05 + fres * 0.45 + impact * 1.6 + (ring * 0.9 + ring2) * cells);
	if (patchy > 0.0) {
		float pn = vnoise(d3.xy * 7.0 + vec2(TIME * 3.0, d3.z * 5.0));
		float flick = step(0.32, vnoise(vec2(TIME * 24.0, 1.7)));
		a *= mix(1.0, smoothstep(0.38, 0.62, pn) * flick, patchy);
	}
	ALBEDO = mix(tint, vec3(1.0), impact * 0.35 * strength) * energy * a;
	ALPHA = 1.0;
}
"""

const RING_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, specular_disabled;
uniform float alpha = 0.0;
uniform vec3 col = vec3(0.30, 0.29, 0.28);
uniform float seed = 0.0;
varying vec3 lp;
""" + NOISE + """
void vertex() {
	lp = VERTEX;
}
void fragment() {
	float n = fbm(vec2(atan(lp.z, lp.x) * 2.5 + seed, lp.y * 4.0 + seed * 2.0));
	float soft = pow(abs(dot(NORMAL, VIEW)), 2.0);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	ALPHA = clamp(alpha * soft * smoothstep(0.2, 0.75, n) * 1.6, 0.0, 1.0);
}
"""

const SHOCK_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float alpha = 0.0;
uniform vec3 tint = vec3(0.85, 0.88, 1.0);
uniform float energy = 1.5;
""" + NOISE + """
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ring = exp(-pow((r - 0.92) / 0.03, 2.0));
	float haze = exp(-pow((r - 0.82) / 0.14, 2.0)) * 0.35;
	float n = vnoise(vec2(atan(p.y, p.x) * 9.0, r * 6.0));
	ALBEDO = tint * energy * alpha * (ring + haze) * (0.6 + 0.8 * n) * (1.0 - step(1.0, r));
	ALPHA = 1.0;
}
"""

# Torn hull plates around the breach: dark metal, glowing hot at the torn (free) end.
const SHARD_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform float heat = 1.0;
varying float lx;
void vertex() {
	lx = VERTEX.x;
}
void fragment() {
	float h = smoothstep(-0.05, 0.5, lx);
	ALBEDO = vec3(0.10, 0.095, 0.09);
	METALLIC = 0.6;
	ROUGHNESS = 0.55;
	EMISSION = vec3(1.0, 0.42, 0.08) * h * h * 5.0 * heat;
}
"""

# Compatibility fallback for the breach scorch (no Decal there): a disc on the hull with the same textures.
const SCORCH_DISC_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;
uniform sampler2D alb : source_color, filter_linear_mipmap;
uniform sampler2D emi : source_color, filter_linear_mipmap;
uniform float emission_energy = 3.0;
uniform float fade = 1.0;
void fragment() {
	vec4 a = texture(alb, UV);
	ALBEDO = a.rgb;
	ROUGHNESS = 0.9;
	EMISSION = texture(emi, UV).rgb * emission_energy;
	ALPHA = a.a * fade;
}
"""

var notes: PackedStringArray = []
var fixed_seed := false
var compat := false
var ships: Array = []
var wreck := {}

var _quad: QuadMesh
var _strip: QuadMesh
var _box: BoxMesh
var _spark_mesh: BoxMesh
var _plate: BoxMesh
var _sh := {}
var _mats := {}
var _pm := {}
var _seed := 1
var _rng := RandomNumberGenerator.new()


func setup(list: Array, wreck_src: Dictionary, deterministic: bool, is_compat: bool) -> void:
	fixed_seed = deterministic
	compat = is_compat
	_rng.seed = 2610
	_quad = QuadMesh.new()
	_quad.size = Vector2(1, 1)
	_strip = QuadMesh.new()
	_strip.size = Vector2(1, 1)
	_strip.subdivide_width = 32
	_box = BoxMesh.new()
	_box.size = Vector3(1, 1, 1)
	_spark_mesh = BoxMesh.new()
	_spark_mesh.size = Vector3(0.06, 1.0, 0.06)
	_plate = BoxMesh.new()
	_plate.size = Vector3(1.0, 0.18, 0.6)
	_sh["ribbon"] = _shader(RIBBON_SHADER)
	_sh["sprite"] = _shader(SPRITE_SHADER.replace("ROTATE", ""))
	_sh["shield"] = _shader(SHIELD_SHADER)
	_sh["ring"] = _shader(RING_SHADER)
	_sh["shock"] = _shader(SHOCK_SHADER)
	_sh["shard"] = _shader(SHARD_SHADER)
	_sh["disc"] = _shader(SCORCH_DISC_SHADER)
	_mats["flame"] = _mat(_shader(FLAME_SHADER.replace("ROTATE", PARTICLE_ROTATE)))
	_mats["smoke"] = _mat(_shader(SMOKE_SHADER.replace("ROTATE", PARTICLE_ROTATE)))
	_mats["spark"] = _mat(_shader(SPARK_SHADER))
	var deb := StandardMaterial3D.new()
	deb.albedo_color = Color(0.16, 0.15, 0.14)
	deb.metallic = 0.6
	deb.roughness = 0.5
	_mats["debris"] = deb
	var hot_deb := StandardMaterial3D.new()
	hot_deb.albedo_color = Color(0.12, 0.1, 0.09)
	hot_deb.metallic = 0.5
	hot_deb.roughness = 0.6
	hot_deb.emission_enabled = true
	hot_deb.emission = Color(1.0, 0.35, 0.06)
	hot_deb.emission_energy_multiplier = 0.6
	_mats["hot_debris"] = hot_deb
	_build_process_materials()
	for key in ["gas", "breach_fire", "breach_debris", "breach_sparks", "pop", "soot", "hit_sparks", "hit_debris", "puff",
			"muzzle_smoke", "fountain", "edge_fire", "edge_smoke", "edge_squib"]:
		(_pm[key] as ParticleProcessMaterial).inherit_velocity_ratio = 1.0
	var tex := _breach_textures()
	for i in list.size():
		ships.append(_build_ship(i, list[i], tex))
	_build_wreck(wreck_src)


# ---------------------------------------------------------------- per frame

func update(t: float) -> void:
	for i in ships.size():
		_update_ship(ships[i], t, t - STAGGER * i)
	_update_wreck(t)


func _drift_x(t: float) -> float:
	return fposmod(DRIFT_SPEED * t + DRIFT_SPAN * 0.5, DRIFT_SPAN) - DRIFT_SPAN * 0.5


func _update_ship(e: Dictionary, t: float, u: float) -> void:
	# drift along +x at 3 u/s, looping over 40 units (x offset -20 to +20, 0 at t = 0) with a 2 s fade at the loop point
	var q := fposmod(DRIFT_SPEED * t + DRIFT_SPAN * 0.5, DRIFT_SPAN)
	var root: Node3D = e["root"]
	root.position = e["base"] + Vector3(q - DRIFT_SPAN * 0.5, 0, 0)
	var fade := clampf(minf(q, DRIFT_SPAN - q) / DRIFT_SPEED / DRIFT_FADE, 0.0, 1.0)
	if fade != e["fade"]:
		e["fade"] = fade
		for m in e["meshes"]:
			(m as GeometryInstance3D).transparency = 1.0 - fade
	var a := -1.0 if u < 0.0 else fmod(u, LOOP)
	var cyc := -1 if u < 0.0 else int(floorf(u / LOOP))

	# 1. engines
	var sput := 1.0
	if e["corsair"]:
		sput = _sputter(t)
		(e["soot"] as GPUParticles3D).amount_ratio = clampf((1.2 - sput) * fade, 0.05, 1.0)
	for en in e["engines"]:
		(en["core_m"] as ShaderMaterial).set_shader_parameter("alpha", fade * sput * (0.9 + 0.1 * sin(t * 41.0 + en["seed"])))
		(en["plume_m"] as ShaderMaterial).set_shader_parameter("alpha", fade * sput)
		(en["trail_m"] as ShaderMaterial).set_shader_parameter("alpha", fade * (0.6 + 0.4 * sput))

	# 2. broadside
	var gun_light := 0.0
	var gun_light_at := Vector3.ZERO
	for k in e["guns"].size():
		var g: Dictionary = e["guns"][k]
		var ak: float = a - GUN_GAP * k
		if ak < 0.0 and cyc > 0:
			ak += LOOP  # the previous volley's smoke rings are still drifting
		var fc := _cycle(u - GUN_GAP * k)
		if fc > int(g["last_fire"]):
			g["last_fire"] = fc
			_fire(g["smoke"])
		var fl: MeshInstance3D = g["flash"]
		fl.visible = ak >= 0.0 and ak < 0.1
		if fl.visible:
			var f: float = 1.0 - ak / 0.1
			fl.scale = Vector3.ONE * 5.0 * (0.7 + 0.3 * f)
			(fl.material_override as ShaderMaterial).set_shader_parameter("alpha", f * fade)
			if f > gun_light:
				gun_light = f
				gun_light_at = g["pos"] + g["n"] * 1.5
		var tg: MeshInstance3D = g["tongue"]
		tg.visible = ak >= 0.0 and ak < 0.16
		if tg.visible:
			var tl := 3.0 + 5.0 * smoothstep(0.0, 0.05, ak)
			tg.transform = _ribbon_xf(g["pos"], g["n"], tl)
			(tg.material_override as ShaderMaterial).set_shader_parameter("alpha", (1.0 - ak / 0.16) * fade)
		# world-space parts start where the gun was when it fired
		var p0: Vector3 = e["base"] + Vector3(_drift_x(t - ak), 0, 0) + g["pos"]
		var nn: Vector3 = g["n"]
		var ring: MeshInstance3D = g["ring"]
		ring.visible = ak >= 0.0 and ak < RING_LIFE
		if ring.visible:
			var grow := 1.0 - exp(-ak * 2.5)
			var r := 0.8 + 3.2 * grow
			var thick := 0.6 + 1.6 * grow
			ring.transform = Transform3D(_basis_y(nn) * Basis.from_scale(Vector3(r, thick, r)),
				p0 + nn * (1.0 + 4.0 * grow) + Vector3(0, 0.6 * ak, 0))
			(ring.material_override as ShaderMaterial).set_shader_parameter("alpha", 0.4 * pow(1.0 - ak / RING_LIFE, 1.3))
		var target: Vector3 = p0 + g["aim"]
		var dist := p0.distance_to(target)
		var dir := (target - p0) / dist
		var run: float = ak * SHELL_SPEED
		var tr: MeshInstance3D = g["tracer"]
		tr.visible = ak >= 0.0 and run < dist + 1.0
		if tr.visible:
			var head := minf(run, dist)
			var tail := clampf(run - 7.0, 0.0, dist)
			tr.transform = _ribbon_xf(p0 + dir * tail, dir, maxf(head - tail, 0.05))
		var flight := dist / SHELL_SPEED
		var ai: float = ak - flight
		var imp: MeshInstance3D = g["impact"]
		imp.visible = ai >= 0.0 and ai < 0.15
		if imp.visible:
			imp.position = target
			imp.scale = Vector3.ONE * 4.0
			(imp.material_override as ShaderMaterial).set_shader_parameter("alpha", 1.0 - ai / 0.15)
		var ic := _cycle(u - GUN_GAP * k - flight)
		if ic > int(g["last"]):
			g["last"] = ic
			_fire_at(g["sparks"], target)
			_fire_at(g["debris"], target)
	var gl: OmniLight3D = e["gun_light"]
	gl.visible = gun_light > 0.0
	if gl.visible:
		gl.position = gun_light_at
		gl.light_energy = 6.0 * gun_light * fade

	# 3. beam
	var ab := a - BEAM_AT
	var charge: MeshInstance3D = e["charge"]
	var cf := 0.0
	if ab >= -CHARGE_T and ab < 0.0:
		cf = smoothstep(-CHARGE_T, 0.0, ab)
	elif ab >= 0.0 and ab < BEAM_T:
		cf = 0.6 + 0.2 * sin(t * 60.0)
	cf *= fade
	charge.visible = cf > 0.0
	if charge.visible:
		charge.scale = Vector3.ONE * (1.5 + 4.5 * cf)
		(charge.material_override as ShaderMaterial).set_shader_parameter("alpha", cf)
	var on := ab >= 0.0 and ab < BEAM_T and fade > 0.0
	var benv := 0.0
	if on:
		benv = smoothstep(0.0, 0.05, ab) * (1.0 - smoothstep(BEAM_T - 0.15, BEAM_T, ab)) * fade
	for key in ["beam_core", "beam_glow"]:
		var bm: MeshInstance3D = e[key]
		bm.visible = on
		if on:
			(bm.material_override as ShaderMaterial).set_shader_parameter("alpha", benv)
	var bh: MeshInstance3D = e["beam_hit"]
	bh.visible = on
	if on:
		bh.scale = Vector3.ONE * (6.0 + 1.5 * sin(t * 47.0)) * maxf(benv, 0.05)
		(bh.material_override as ShaderMaterial).set_shader_parameter("alpha", benv)
	var bs: GPUParticles3D = e["beam_sparks"]
	if on != bs.emitting:
		bs.emitting = on
	var bl: OmniLight3D = e["beam_light"]
	bl.visible = cf > 0.0 or on
	if bl.visible:
		bl.light_energy = 3.0 * cf + 5.0 * benv
	var bl2: OmniLight3D = e["beam_hit_light"]
	bl2.visible = on
	if on:
		bl2.light_energy = 4.0 * benv

	# 4. incoming shell and the hit
	var ah := a - HIT_AT
	var inc: MeshInstance3D = e["incoming"]
	var inc_t := INCOMING_LEN / SHELL_SPEED
	inc.visible = ah >= -inc_t and ah < 0.0 and fade > 0.0
	if inc.visible:
		var hp: Vector3 = e["hit_at"]
		var from: Vector3 = e["incoming_dir"]
		var togo := -ah * SHELL_SPEED
		inc.transform = _ribbon_xf(hp + from * (togo + 7.0), -from, 7.0)
	var hl: OmniLight3D = e["hit_light"]
	var hf := 0.0
	if e["shielded"]:
		var sh: MeshInstance3D = e["shield"]
		sh.visible = ah >= 0.0 and ah < SHIELD_T and fade > 0.0
		if sh.visible:
			var sm: ShaderMaterial = sh.material_override
			sm.set_shader_parameter("strength", pow(1.0 - ah / SHIELD_T, 1.5) * fade)
			sm.set_shader_parameter("age", ah)
		var core: MeshInstance3D = e["hit_core"]
		core.visible = ah >= 0.0 and ah < 0.25 and fade > 0.0
		if core.visible:
			hf = (1.0 - ah / 0.25) * fade
			core.scale = Vector3.ONE * (3.0 + 3.0 * (1.0 - hf))
			(core.material_override as ShaderMaterial).set_shader_parameter("alpha", hf)
	else:
		var hfl: MeshInstance3D = e["hit_flash"]
		hfl.visible = ah >= 0.0 and ah < 0.2 and fade > 0.0
		if hfl.visible:
			hf = (1.0 - ah / 0.2) * fade
			hfl.scale = Vector3.ONE * (4.0 + 2.0 * (1.0 - hf))
			(hfl.material_override as ShaderMaterial).set_shader_parameter("alpha", hf)
		var hc := _cycle(u - HIT_AT)
		if hc > int(e["last_hit"]):
			e["last_hit"] = hc
			for key in ["hit_sparks", "hit_debris", "hit_fire"]:
				_fire(e[key])
	hl.visible = hf > 0.0
	if hl.visible:
		hl.light_energy = 5.0 * hf

	# 5. breach (persistent)
	var br: Dictionary = e["breach"]
	var idx: int = e["idx"]
	var puff := clampf(0.35 + 0.65 * _smooth_noise(t * 2.2 + idx * 7.0), 0.15, 1.0)
	var live := fade > 0.02
	for cp in [br["gas"], br["fire"], br["debris"]]:
		if (cp as GPUParticles3D).emitting != live:
			(cp as GPUParticles3D).emitting = live
	if e["corsair"] and (e["soot"] as GPUParticles3D).emitting != live:
		(e["soot"] as GPUParticles3D).emitting = live
	(br["gas"] as GPUParticles3D).amount_ratio = maxf(puff * fade, 0.001)
	(br["fire"] as GPUParticles3D).amount_ratio = maxf(fade, 0.001)
	(br["debris"] as GPUParticles3D).amount_ratio = maxf(fade, 0.001)
	# fixed timers, staggered like the loop: a spark shower every 2.3 s, a secondary pop every 3.7 s
	var pt := t - STAGGER * idx
	var sc := _cycle_n(pt, SPARKS_EVERY)
	if sc > int(br["last_sparks"]):
		br["last_sparks"] = sc
		_fire(br["sparks"])
	var pc := _cycle_n(pt, POP_EVERY)
	var pop := 0.0
	if pt >= 0.0:
		var pa := fmod(pt, POP_EVERY)
		if pa < 0.18:
			pop = 1.0 - pa / 0.18
	if pc > int(br["last_pop"]):
		br["last_pop"] = pc
		_fire(br["pop_fire"])
		_fire(br["sparks"])
	var pf: MeshInstance3D = br["pop_flash"]
	pf.visible = pop > 0.0 and fade > 0.0
	if pf.visible:
		pf.scale = Vector3.ONE * (2.5 + 2.0 * (1.0 - pop))
		(pf.material_override as ShaderMaterial).set_shader_parameter("alpha", pop * fade)
	var flick := 0.75 + 0.25 * _smooth_noise(t * 9.0 + idx * 3.3)
	(br["light"] as OmniLight3D).light_energy = (1.4 * flick + 7.0 * pop) * fade
	if br.has("decal"):
		var dc: Decal = br["decal"]
		dc.emission_energy = 2.6 * flick + 4.0 * pop
		dc.modulate = Color(1, 1, 1, fade)
	else:
		var dm: ShaderMaterial = br["disc_m"]
		dm.set_shader_parameter("emission_energy", 2.6 * flick + 4.0 * pop)
		dm.set_shader_parameter("fade", fade)
	for sm2 in br["shard_m"]:
		(sm2 as ShaderMaterial).set_shader_parameter("heat", (0.8 + 0.4 * flick) * fade)
	for sh2 in br["shards"]:
		(sh2 as GeometryInstance3D).transparency = 1.0 - fade


func _update_wreck(t: float) -> void:
	if wreck.is_empty():
		return
	var whole: MeshInstance3D = wreck["whole"]
	var tt := t - (BREAK_AT - BOOM_EVERY)  # breaks when tt crosses 12, 24, ...
	var since := -1.0  # time since the last break (none yet before t = 12.4)
	var p := tt
	if tt >= BOOM_EVERY:
		since = fmod(tt, BOOM_EVERY)
		p = since
	var to_next := BOOM_EVERY - p
	# the whole ship: hidden after a break, fading back in 2 s before the next one
	var vis := 1.0
	if since >= 0.0 and since < BOOM_EVERY - 2.0:
		vis = 0.0
	elif since >= 0.0:
		vis = clampf(since - (BOOM_EVERY - 2.0), 0.0, 1.0)
	whole.visible = vis > 0.0
	whole.transparency = 1.0 - vis
	# squibs on the hull from 0.6 s before the break; the flash builds from 0.5 s before and peaks at the break
	var squib_c := int(floorf((tt + 0.6) / BOOM_EVERY))
	if squib_c > int(wreck["last_squib"]):
		wreck["last_squib"] = squib_c
		_fire(wreck["pre_squibs"])
	var a := since
	var flash := 0.0
	if to_next < 0.5:
		var kk := clampf((0.5 - to_next) / 0.5, 0.0, 1.0)
		flash = kk * kk * (3.0 - 2.0 * kk) * 0.55
	if a >= 0.0:
		flash = maxf(flash, 0.55 + 0.45 * a / 0.05 if a < 0.05 else exp(-(a - 0.05) * 4.0))
	var fl: MeshInstance3D = wreck["flash"]
	fl.visible = flash > 0.003
	if fl.visible:
		fl.scale = Vector3.ONE * (10.0 + 45.0 * flash)
		(fl.material_override as ShaderMaterial).set_shader_parameter("alpha", flash)
	var lt: OmniLight3D = wreck["light"]
	lt.visible = flash > 0.003
	lt.light_energy = 40.0 * flash
	var core: MeshInstance3D = wreck["core"]
	core.visible = a >= 0.0 and a < 0.9
	if core.visible:
		core.scale = Vector3.ONE * 26.0 * (0.3 + 0.7 * smoothstep(0.0, 0.4, a))
		(core.material_override as ShaderMaterial).set_shader_parameter("alpha", pow(1.0 - a / 0.9, 1.5))
	var sw: MeshInstance3D = wreck["shock"]
	sw.visible = a >= 0.0 and a < 2.0
	if sw.visible:
		var r := 4.0 + 75.0 * (1.0 - exp(-a * 1.8))
		sw.scale = Vector3(r * 2.0, 1.0, r * 2.0)
		(sw.material_override as ShaderMaterial).set_shader_parameter("alpha", pow(1.0 - a / 2.0, 3.0))
	var bc := _cycle12(tt)
	if bc > int(wreck["last_boom"]):
		wreck["last_boom"] = bc
		for key in ["fireball", "smoke", "embers", "debris"]:
			_fire(wreck[key])
	# chunks
	var show_chunks := a >= 0.0 and a < BOOM_EVERY - 2.0
	for c in wreck["chunks"]:
		var node: Node3D = c["node"]
		node.visible = show_chunks
		var fire: GPUParticles3D = c["fire"]
		var smoke: GPUParticles3D = c["smoke"]
		var squibs: GPUParticles3D = c["squibs"]
		if not show_chunks:
			if fire.emitting or squibs.emitting:
				fire.emitting = false
				smoke.emitting = false
				squibs.emitting = false
			continue
		node.transform = Transform3D(Basis(c["axis"], c["spin"] * a), WRECK_POS + c["start"] + c["vel"] * a)
		var cfade := clampf((BOOM_EVERY - 2.0 - a) / 0.6, 0.0, 1.0)
		(c["mesh"] as GeometryInstance3D).transparency = 1.0 - cfade
		var burning: bool = a < c["burn_t"]
		if fire.emitting != burning:
			fire.emitting = burning
			smoke.emitting = burning
		fire.amount_ratio = clampf(1.0 - a / c["burn_t"] * 0.6, 0.2, 1.0)
		var sq := a < 3.0
		if squibs.emitting != sq:
			squibs.emitting = sq


# ---------------------------------------------------------------- build: ships

func _build_ship(i: int, s: Dictionary, tex: Dictionary) -> Dictionary:
	var e := {"idx": i, "root": s["root"], "base": s["pos"], "meshes": s["meshes"], "fade": 1.0,
		"corsair": s["name"] == "Corsair", "shielded": s["shield"] != null, "last_hit": -1}
	var root: Node3D = s["root"]
	var half: Vector3 = s["half"]
	var wcol: Color = s["weapon"]
	var ecol: Color = s["engine"]
	# 1. engines
	var engines: Array = []
	var w: float = s["noz_size"]
	var plume_len := clampf(3.0 * half.z, 7.0, 18.0)
	for nz in s["nozzles"]:
		var en := {"seed": _rng.randf() * 10.0}
		var core := _sprite(root, ecol, 6.0, nz, w * 2.2)
		core.visible = true
		en["core_m"] = core.material_override
		var plume := _ribbon(root, {"tint_a": _v3(ecol.lerp(Color.WHITE, 0.35)), "tint_b": _v3(ecol), "energy": 2.4,
			"width_a": w * 1.2, "width_b": w * 0.5, "core": 1.0, "noise_amt": 0.85, "noise_scale": 0.6, "scroll": 14.0,
			"fade_in": 0.03, "fade_out": 0.35, "flicker": 0.35, "decay": 3.0, "seed": en["seed"]}, 25.0)
		plume.transform = _ribbon_xf(nz, Vector3(-1, 0, 0), plume_len)
		plume.visible = true
		en["plume_m"] = plume.material_override
		var trail := _ribbon(root, {"tint_a": _v3(ecol) * 0.8, "tint_b": Vector3(0.30, 0.10, 0.05), "energy": 0.35,
			"width_a": w * 0.9, "width_b": w * 0.3, "core": 0.15, "noise_amt": 0.75, "noise_scale": 0.12, "scroll": 4.0,
			"waver": 2.2, "fade_in": 0.02, "fade_out": 0.25, "decay": 1.2, "seed": en["seed"] + 3.0}, 30.0)
		trail.transform = _ribbon_xf(nz, Vector3(-1, 0, 0), TRAIL_LEN)
		trail.visible = true
		en["trail_m"] = trail.material_override
		engines.append(en)
	e["engines"] = engines
	if e["corsair"]:
		var stern := Vector3(-half.x - 0.5, s["nozzles"][0].y, 0)
		var soot := _particles(root, _pm["soot"], 40, 2.5, _quad, _mats["smoke"], stern, false)
		soot.emitting = true
		e["soot"] = soot
	# 2. broadside
	var guns: Array = []
	for k in s["guns"].size():
		var gp: Vector3 = s["guns"][k]
		var gn: Vector3 = s["gun_n"][k]
		var g := {"pos": gp, "n": gn, "last": -1, "last_fire": -1, "aim": Vector3(8.0 + 4.0 * k, 3.0 + _rng.randf() * 4.0, BROADSIDE_RANGE)}
		g["flash"] = _sprite(root, wcol.lerp(Color.WHITE, 0.3), 12.0, gp + gn * 0.8, 5.0, 1.0)
		g["tongue"] = _ribbon(root, {"tint_a": Vector3(1.0, 0.9, 0.7), "tint_b": _v3(wcol), "energy": 6.0, "width_a": 1.6,
			"width_b": 0.2, "core": 1.0, "noise_amt": 0.5, "noise_scale": 1.5, "scroll": 30.0, "fade_in": 0.05, "fade_out": 0.5,
			"seed": float(k) * 2.1 + i}, 10.0)
		var rm := _mat(_sh["ring"])
		rm.set_shader_parameter("seed", _rng.randf() * 10.0)
		var torus := TorusMesh.new()
		torus.inner_radius = 0.45
		torus.outer_radius = 1.0
		torus.rings = 32
		torus.ring_segments = 10
		var ring := MeshInstance3D.new()
		ring.mesh = torus
		ring.material_override = rm
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.visible = false
		add_child(ring)
		g["ring"] = ring
		g["tracer"] = _ribbon(self, {"tint_a": Vector3(1.0, 0.95, 0.85), "tint_b": _v3(wcol), "energy": 7.0, "width_a": 0.35,
			"width_b": 0.9, "core": 1.0, "fade_in": 0.6, "fade_out": 0.97}, 5.0)
		var ms := Node3D.new()
		ms.basis = _basis_y(gn)
		ms.position = gp + gn * 0.8
		root.add_child(ms)
		g["smoke"] = _particles(ms, _pm["muzzle_smoke"], 8, 2.0, _quad, _mats["smoke"], Vector3.ZERO)
		g["impact"] = _sprite(self, wcol.lerp(Color.WHITE, 0.4), 9.0, Vector3.ZERO, 4.0, 1.0)
		g["sparks"] = _particles(self, _pm["impact_sparks"], 20, 0.6, _spark_mesh, _mats["spark"], Vector3.ZERO)
		g["debris"] = _particles(self, _pm["impact_debris"], 10, 1.6, _plate, _mats["hot_debris"], Vector3.ZERO)
		guns.append(g)
	e["guns"] = guns
	e["gun_light"] = _omni(root, wcol.lerp(Color.WHITE, 0.3), 16.0)
	# 3. beam
	var bow: Vector3 = s["bow"]
	e["charge"] = _sprite(root, wcol.lerp(Color.WHITE, 0.25), 10.0, bow, 3.0, 1.0)
	var bc := _ribbon(root, {"tint_a": Vector3(1, 1, 1), "tint_b": Vector3(1, 1, 1), "energy": 9.0, "width_a": 0.9, "width_b": 0.7,
		"core": 1.0, "noise_amt": 0.25, "noise_scale": 0.6, "scroll": 25.0, "fade_in": 0.01, "fade_out": 0.985, "flicker": 0.15}, 6.0)
	bc.transform = _ribbon_xf(bow, Vector3(1, 0, 0), BEAM_LEN)
	e["beam_core"] = bc
	var bg := _ribbon(root, {"tint_a": _v3(wcol), "tint_b": _v3(wcol), "energy": 3.5, "width_a": 4.0, "width_b": 3.2,
		"noise_amt": 0.65, "noise_scale": 0.25, "scroll": 18.0, "fade_in": 0.01, "fade_out": 0.97, "flicker": 0.3, "seed": i * 1.3}, 8.0)
	bg.transform = _ribbon_xf(bow, Vector3(1, 0, 0), BEAM_LEN)
	e["beam_glow"] = bg
	var end := bow + Vector3(BEAM_LEN, 0, 0)
	e["beam_hit"] = _sprite(root, wcol.lerp(Color.WHITE, 0.3), 10.0, end, 6.0, 1.0)
	e["beam_sparks"] = _particles(root, _pm["fountain"], 60, 0.7, _spark_mesh, _mats["spark"], end, false)
	e["beam_light"] = _omni(root, wcol.lerp(Color.WHITE, 0.3), 18.0)
	(e["beam_light"] as OmniLight3D).position = bow
	e["beam_hit_light"] = _omni(root, wcol.lerp(Color.WHITE, 0.3), 20.0)
	(e["beam_hit_light"] as OmniLight3D).position = end
	# 4. incoming shell and the hit
	var shell_col := Color(1.0, 0.75, 0.45)
	e["incoming_dir"] = Vector3(0.35, 0.25, -1.0).normalized()
	e["incoming"] = _ribbon(root, {"tint_a": Vector3(1.0, 0.7, 0.4), "tint_b": Vector3(1.0, 0.95, 0.85), "energy": 7.0,
		"width_a": 0.9, "width_b": 0.35, "core": 1.0, "fade_in": 0.6, "fade_out": 0.98}, 5.0)
	if e["shielded"]:
		var radii := half * 1.15 + Vector3(1.5, 1.5, 1.5)
		var hd := Vector3(0.15, 0.2, -1.0).normalized()
		var sm := _mat(_sh["shield"])
		sm.set_shader_parameter("tint", _v3(s["shield"]))
		sm.set_shader_parameter("hit_dir", hd)
		sm.set_shader_parameter("patchy", 1.0 if e["corsair"] else 0.0)
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		sphere.radial_segments = 48
		sphere.rings = 24
		var shm := MeshInstance3D.new()
		shm.mesh = sphere
		shm.material_override = sm
		shm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shm.scale = radii
		shm.visible = false
		root.add_child(shm)
		e["shield"] = shm
		var hp := hd * radii
		e["hit_at"] = hp
		var scol: Color = s["shield"]
		e["hit_core"] = _sprite(root, scol.lerp(Color.WHITE, 0.4), 10.0, hp, 3.0, 1.0)
	else:
		var hp2: Vector3 = s["hit"]
		e["hit_at"] = hp2
		e["hit_flash"] = _sprite(root, shell_col, 10.0, hp2 + Vector3(0, 0, -0.5), 4.0, 1.0)
		var holder := Node3D.new()
		holder.position = hp2
		holder.basis = _basis_y(Vector3(0, 0.2, -1).normalized())
		root.add_child(holder)
		e["hit_sparks"] = _particles(holder, _pm["hit_sparks"], 36, 0.8, _spark_mesh, _mats["spark"], Vector3.ZERO)
		e["hit_debris"] = _particles(holder, _pm["hit_debris"], 16, 2.0, _plate, _mats["hot_debris"], Vector3.ZERO)
		e["hit_fire"] = _particles(holder, _pm["puff"], 12, 0.7, _quad, _mats["flame"], Vector3.ZERO)
	e["hit_light"] = _omni(root, shell_col, 16.0)
	(e["hit_light"] as OmniLight3D).position = e["hit_at"]
	# 5. breach
	e["breach"] = _build_breach(root, s, tex)
	return e


func _build_breach(root: Node3D, s: Dictionary, tex: Dictionary) -> Dictionary:
	var br := {"last_sparks": -1, "last_pop": -1}
	var p: Vector3 = s["breach"]
	var n: Vector3 = s["breach_n"]
	var hole := 2.4  # about 1/10 of the ship's length
	var frame := Node3D.new()
	frame.name = "breach"
	frame.position = p
	frame.basis = _basis_y(n)
	root.add_child(frame)
	if not compat:
		var d := Decal.new()
		d.size = Vector3(hole * 2.2, 2.5, hole * 2.2)
		d.texture_albedo = tex["alb"]
		d.texture_emission = tex["emi"]
		d.texture_normal = tex["nrm"]
		d.emission_energy = 2.6
		d.albedo_mix = 1.0
		d.normal_fade = 0.2
		d.upper_fade = 0.3
		d.lower_fade = 0.3
		frame.add_child(d)
		br["decal"] = d
	else:
		var dm := _mat(_sh["disc"])
		dm.set_shader_parameter("alb", tex["alb"])
		dm.set_shader_parameter("emi", tex["emi"])
		var disc := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(hole * 2.2, hole * 2.2)
		disc.mesh = pm
		disc.material_override = dm
		disc.position = Vector3(0, 0.06, 0)
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		frame.add_child(disc)
		br["disc_m"] = dm
		if not notes.has("breach scorch drawn as a disc on the hull (no Decal in Compatibility)"):
			notes.append("breach scorch drawn as a disc on the hull (no Decal in Compatibility)")
	# torn plates peeled outward around the hole, hot at their torn ends, each snapped onto the hull point nearest its
	# place on the rim (so none float or sink)
	var near_p := PackedVector3Array()
	var near_n := PackedVector3Array()
	var pts: PackedVector3Array = s.get("pts", PackedVector3Array())
	var nrms: PackedVector3Array = s.get("nrm", PackedVector3Array())
	for j in pts.size():
		if pts[j].distance_squared_to(p) < 9.0:
			near_p.append(pts[j])
			near_n.append(nrms[j])
	var fb := frame.basis
	var shard_m: Array = []
	var shards: Array = []
	var count := 11
	for k in count:
		var th := TAU * k / count + _rng.randf_range(-0.2, 0.2)
		var radial := fb * Vector3(cos(th), 0, sin(th))
		var tilt := _rng.randf_range(0.5, 1.15)
		var plen := _rng.randf_range(0.45, 0.95)
		var pw := _rng.randf_range(0.22, 0.42)
		var want := p + radial * hole * 0.5 * _rng.randf_range(0.85, 1.05)
		var q := want
		var nq := n
		var best := 1e9
		for j in near_p.size():
			var d := near_p[j].distance_squared_to(want)
			if d < best:
				best = d
				q = near_p[j]
				nq = near_n[j]
		var outw := q - p
		outw = outw - nq * outw.dot(nq)
		if outw.length() < 0.01:
			outw = radial
		outw = outw.normalized()
		var xa := (outw * cos(tilt) + nq * sin(tilt)).normalized()
		var za := xa.cross(nq).normalized()
		var ya := za.cross(xa).normalized()
		var sm := _mat(_sh["shard"])
		var mi := MeshInstance3D.new()
		mi.mesh = _box
		mi.material_override = sm
		mi.transform = Transform3D(Basis(xa * plen, ya * 0.05, za * pw), q + xa * plen * 0.5 - nq * 0.04)
		root.add_child(mi)
		shard_m.append(sm)
		shards.append(mi)
	br["shard_m"] = shard_m
	br["shards"] = shards
	var gas := _particles(frame, _pm["gas"], 48, 1.4, _quad, _mats["smoke"], Vector3(0, 0.2, 0), false)
	gas.emitting = true
	br["gas"] = gas
	var fire := _particles(frame, _pm["breach_fire"], 28, 0.45, _quad, _mats["flame"], Vector3(0, 0.1, 0), false)
	fire.emitting = true
	br["fire"] = fire
	var deb := _particles(frame, _pm["breach_debris"], 10, 3.0, _plate, _mats["debris"], Vector3.ZERO, false)
	deb.emitting = true
	br["debris"] = deb
	br["sparks"] = _particles(frame, _pm["breach_sparks"], 30, 0.8, _spark_mesh, _mats["spark"], Vector3(0, 0.1, 0))
	br["pop_fire"] = _particles(frame, _pm["pop"], 16, 0.6, _quad, _mats["flame"], Vector3(0, 0.3, 0))
	br["pop_flash"] = _sprite(frame, Color(1.0, 0.55, 0.2), 5.0, Vector3(0, 0.6, 0), 3.0, 0.6)
	var lt := _omni(frame, Color(1.0, 0.5, 0.15), 7.0)
	lt.position = Vector3(0, 1.4, 0)
	lt.visible = true
	br["light"] = lt
	return br


# ---------------------------------------------------------------- build: destruction event

func _build_wreck(src: Dictionary) -> void:
	if not src.has("mesh") or src["mesh"] == null or not src.has("surfs"):
		notes.append("destruction event skipped: Hegemony mesh not loaded")
		return
	var k: float = src["scale"] * WRECK_SCALE
	var c0: Vector3 = src["center"]
	var root := Node3D.new()
	root.name = "Wreck"
	add_child(root)
	var whole := MeshInstance3D.new()
	whole.mesh = src["mesh"]
	whole.transform = Transform3D(Basis.from_scale(Vector3(k, k, k)), WRECK_POS - c0 * k)
	root.add_child(whole)
	wreck = {"whole": whole, "last_squib": 0, "last_boom": -1}
	var white := Color(1.0, 0.88, 0.7)
	wreck["flash"] = _sprite(self, white, 10.0, WRECK_POS, 40.0, 1.0)
	(wreck["flash"].material_override as ShaderMaterial).set_shader_parameter("spikes", 0.6)
	wreck["core"] = _sprite(self, Color(1.0, 0.6, 0.25), 8.0, WRECK_POS, 20.0, 0.7)
	var lt := _omni(self, white, 140.0)
	lt.position = WRECK_POS
	lt.omni_attenuation = 1.2
	wreck["light"] = lt
	var sm := _mat(_sh["shock"])
	var plane := PlaneMesh.new()
	plane.size = Vector2(1, 1)
	var shock := MeshInstance3D.new()
	shock.mesh = plane
	shock.material_override = sm
	shock.position = WRECK_POS
	shock.custom_aabb = AABB(Vector3(-0.6, -0.1, -0.6), Vector3(1.2, 0.2, 1.2))
	shock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shock.visible = false
	add_child(shock)
	wreck["shock"] = shock
	wreck["fireball"] = _particles(self, _pm["fireball"], 64, 1.8, _quad, _mats["flame"], WRECK_POS)
	wreck["smoke"] = _particles(self, _pm["big_smoke"], 40, 5.0, _quad, _mats["smoke"], WRECK_POS)
	(wreck["smoke"] as GPUParticles3D).draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	wreck["embers"] = _particles(self, _pm["embers"], 120, 2.6, _quad, _mats["flame"], WRECK_POS)
	wreck["debris"] = _particles(self, _pm["big_debris"], 70, 6.0, _plate, _mats["hot_debris"], WRECK_POS)
	var squib_pm := _pm["pre_squib"] as ParticleProcessMaterial
	squib_pm.emission_box_extents = Vector3(12.0, 2.0, 3.0) * 0.6
	var pre := _particles(self, squib_pm, 18, 0.5, _quad, _mats["flame"], WRECK_POS)
	pre.explosiveness = 0.6
	wreck["pre_squibs"] = pre
	wreck["chunks"] = _cut_chunks(src, k, root)


# Cuts the Hegemony mesh into four chunks with three tilted planes (triangles go by their centroid), and puts fire, smoke
# and squib emitters along each chunk's break.
func _cut_chunks(src: Dictionary, k: float, root: Node3D) -> Array:
	var c0: Vector3 = src["center"]
	var p0 := Vector3(-0.16, 0, 0)
	var n0 := Vector3(1.0, 0.35, 0.2).normalized()
	var p1 := Vector3(0.18, 0, 0)
	var n1 := Vector3(1.0, -0.3, 0.25).normalized()
	var p2 := Vector3(0.0, c0.y, 0)
	var n2 := Vector3(0.2, 1.0, 0.3).normalized()
	var buckets := [PackedInt32Array(), PackedInt32Array(), PackedInt32Array(), PackedInt32Array()]
	var edges := [PackedVector3Array(), PackedVector3Array(), PackedVector3Array(), PackedVector3Array()]
	var surf: Array = src["surfs"][0]
	var arr: Array = surf[0]
	var mat: Material = surf[1]
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx := PackedInt32Array()
	if arr[Mesh.ARRAY_INDEX] != null:
		idx = arr[Mesh.ARRAY_INDEX]
	else:
		idx.resize(v.size())
		for j in v.size():
			idx[j] = j
	for ti in range(0, idx.size() - 2, 3):
		var a: int = idx[ti]
		var b: int = idx[ti + 1]
		var c: int = idx[ti + 2]
		var ctr := (v[a] + v[b] + v[c]) / 3.0
		var d0 := (ctr - p0).dot(n0)
		var d1 := (ctr - p1).dot(n1)
		var d2 := (ctr - p2).dot(n2)
		var bi := 0
		var near := false
		if d0 < 0.0:
			bi = 0
			near = d0 > -0.02
		elif d1 > 0.0:
			bi = 3
			near = d1 < 0.02
		else:
			bi = 1 if d2 > 0.0 else 2
			near = absf(d2) < 0.02 or d0 < 0.02 or d1 > -0.02
		buckets[bi].append(a)
		buckets[bi].append(b)
		buckets[bi].append(c)
		if near:
			edges[bi].append(ctr)
	var cmat: Material = mat.duplicate() if mat != null else StandardMaterial3D.new()
	if cmat is BaseMaterial3D:
		(cmat as BaseMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	var chunks: Array = []
	var biggest := 0
	for bi in 4:
		if buckets[bi].size() > buckets[biggest].size():
			biggest = bi
	for bi in 4:
		var bk: PackedInt32Array = buckets[bi]
		if bk.size() < 3:
			continue
		var carr := arr.duplicate()
		carr[Mesh.ARRAY_INDEX] = bk
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, carr)
		am.surface_set_material(0, cmat)
		var cc := Vector3.ZERO
		var cn := 0
		for j in range(0, bk.size(), 9):
			cc += v[bk[j]]
			cn += 1
		cc /= float(cn)
		var node := Node3D.new()
		node.name = "chunk%d" % bi
		node.visible = false
		root.add_child(node)
		var mi := MeshInstance3D.new()
		mi.mesh = am
		mi.transform = Transform3D(Basis.from_scale(Vector3(k, k, k)), -cc * k)
		node.add_child(mi)
		# the break: where the triangles next to a cut plane are
		var ep: PackedVector3Array = edges[bi]
		var emin := cc
		var emax := cc
		if not ep.is_empty():
			emin = ep[0]
			emax = ep[0]
			for q in ep:
				emin = emin.min(q)
				emax = emax.max(q)
		var ec := (emin + emax) * 0.5
		var ext := ((emax - emin) * 0.5 * k).max(Vector3(0.4, 0.4, 0.4))
		var at := (ec - cc) * k
		var fire_pm := (_pm["edge_fire"] as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial
		fire_pm.emission_box_extents = ext
		var smoke_pm := (_pm["edge_smoke"] as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial
		smoke_pm.emission_box_extents = ext
		var squib_pm := (_pm["edge_squib"] as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial
		squib_pm.emission_box_extents = ext
		var is_wreck := bi == biggest
		var fire := _particles(node, fire_pm, 60 if is_wreck else 36, 0.7, _quad, _mats["flame"], at, false)
		var smoke := _particles(node, smoke_pm, 30 if is_wreck else 14, 3.0, _quad, _mats["smoke"], at, false)
		var squibs := _particles(node, squib_pm, 8, 0.15, _quad, _mats["flame"], at, false)
		var dir := ((cc - c0) * k + Vector3(0, 1.5, 0)).normalized()
		chunks.append({"node": node, "mesh": mi, "fire": fire, "smoke": smoke, "squibs": squibs,
			"start": (cc - c0) * k, "vel": dir * (1.5 if is_wreck else _rng.randf_range(5.0, 9.0)),
			"axis": Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).normalized(),
			"spin": 0.15 if is_wreck else _rng.randf_range(0.5, 1.4),
			"burn_t": BOOM_EVERY - 2.5 if is_wreck else _rng.randf_range(3.0, 6.0)})
	return chunks


# ---------------------------------------------------------------- helpers

func _cycle(x: float) -> int:
	return -1 if x < 0.0 else int(floorf(x / LOOP))


func _cycle_n(x: float, period: float) -> int:
	return -1 if x < 0.0 else int(floorf(x / period))


func _cycle12(t: float) -> int:
	return -1 if t < BOOM_EVERY else int(floorf(t / BOOM_EVERY))


func _hash(x: float) -> float:
	var s := sin(x * 12.9898) * 43758.5453
	return s - floorf(s)


func _smooth_noise(x: float) -> float:
	var i := floorf(x)
	var f := x - i
	f = f * f * (3.0 - 2.0 * f)
	return lerpf(_hash(i), _hash(i + 1.0), f)


# Corsair engines: uneven, with coughs where they nearly cut out.
func _sputter(t: float) -> float:
	var s := 0.6 + 0.4 * _smooth_noise(t * 5.0)
	if _hash(floorf(t * 6.0)) < 0.18:
		s *= 0.2
	return s


func _fire(p: GPUParticles3D) -> void:
	p.restart(fixed_seed)
	p.emitting = true


func _fire_at(p: GPUParticles3D, at: Vector3) -> void:
	p.position = at
	_fire(p)


func _v3(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)


func _basis_y(n: Vector3) -> Basis:
	var y := n.normalized()
	var ref := Vector3.UP if absf(y.y) < 0.95 else Vector3(1, 0, 0)
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)


func _ribbon_xf(origin: Vector3, dir: Vector3, length: float) -> Transform3D:
	var d := dir.normalized()
	var ref := Vector3.UP if absf(d.y) < 0.95 else Vector3(1, 0, 0)
	var y := (ref - d * ref.dot(d)).normalized()
	return Transform3D(Basis(d * length, y, d.cross(y)), origin)


func _shader(code: String) -> Shader:
	var s := Shader.new()
	s.code = code
	return s


func _mat(s: Shader) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = s
	return m


func _ribbon(parent: Node, params: Dictionary, reach: float) -> MeshInstance3D:
	var m := _mat(_sh["ribbon"])
	for key in params:
		m.set_shader_parameter(key, params[key])
	var n := MeshInstance3D.new()
	n.mesh = _strip
	n.material_override = m
	n.custom_aabb = AABB(Vector3(-0.1, -reach, -reach), Vector3(1.2, reach * 2.0, reach * 2.0))
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.visible = false
	parent.add_child(n)
	return n


func _sprite(parent: Node, col: Color, energy: float, at: Vector3, size: float, hot := 1.0) -> MeshInstance3D:
	var m := _mat(_sh["sprite"])
	m.set_shader_parameter("tint", _v3(col))
	m.set_shader_parameter("energy", energy)
	m.set_shader_parameter("hot", hot)
	var n := MeshInstance3D.new()
	n.mesh = _quad
	n.material_override = m
	n.position = at
	n.scale = Vector3.ONE * size
	n.custom_aabb = AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.visible = false
	parent.add_child(n)
	return n


func _omni(parent: Node, col: Color, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.omni_range = rng
	l.light_energy = 0.0
	l.light_specular = 1.0
	l.shadow_enabled = false
	l.visible = false
	parent.add_child(l)
	return l


func _particles(parent: Node, pmat: ParticleProcessMaterial, amount: int, life: float, mesh: Mesh, mat: Material, at: Vector3,
		one_shot := true) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.one_shot = one_shot
	p.explosiveness = 1.0 if one_shot else 0.0
	p.emitting = false
	p.local_coords = false
	p.fixed_fps = 0
	p.interpolate = false
	p.process_material = pmat
	p.draw_pass_1 = mesh
	p.material_override = mat
	p.visibility_aabb = BIG_AABB
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.use_fixed_seed = fixed_seed
	p.seed = _seed
	_seed += 7919
	p.position = at
	parent.add_child(p)
	return p


func _ramp(stops: Array) -> GradientTexture1D:
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for s in stops:
		offs.append(s[0])
		cols.append(s[1])
	var g := Gradient.new()
	g.offsets = offs
	g.colors = cols
	var t := GradientTexture1D.new()
	t.gradient = g
	t.use_hdr = true
	return t


func _curve(points: Array, maxv := 2.0) -> CurveTexture:
	var c := Curve.new()
	c.max_value = maxv
	for p in points:
		c.add_point(Vector2(p[0], p[1]))
	var t := CurveTexture.new()
	t.curve = c
	return t


func _ppm(dir: Vector3, spread: float, vmin: float, vmax: float, damp: float, smin: float, smax: float, radius: float,
		life_rand: float) -> ParticleProcessMaterial:
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = radius
	m.direction = dir
	m.spread = spread
	m.initial_velocity_min = vmin
	m.initial_velocity_max = vmax
	m.gravity = Vector3.ZERO
	m.damping_min = damp
	m.damping_max = damp * 1.4
	m.scale_min = smin
	m.scale_max = smax
	m.lifetime_randomness = life_rand
	return m


func _billboard_spin(m: ParticleProcessMaterial) -> void:
	m.angle_min = 0.0
	m.angle_max = 360.0
	m.angular_velocity_min = -40.0
	m.angular_velocity_max = 40.0


func _tumble(m: ParticleProcessMaterial) -> void:
	m.particle_flag_rotate_y = true
	m.angle_min = 0.0
	m.angle_max = 360.0
	m.angular_velocity_min = -360.0
	m.angular_velocity_max = 360.0


func _build_process_materials() -> void:
	var fire_ramp := [[0.0, Color(1.0, 0.92, 0.7, 1.0)], [0.2, Color(1.0, 0.55, 0.15, 1.0)],
		[0.6, Color(0.7, 0.18, 0.04, 0.7)], [1.0, Color(0.2, 0.05, 0.02, 0.0)]]
	var spark_ramp := [[0.0, Color(1.0, 0.95, 0.8, 1.0)], [0.4, Color(1.0, 0.6, 0.2, 1.0)], [1.0, Color(0.8, 0.2, 0.05, 0.0)]]
	var smoke_ramp := [[0.0, Color(0.20, 0.19, 0.18, 0.0)], [0.12, Color(0.22, 0.21, 0.20, 0.75)],
		[0.6, Color(0.16, 0.155, 0.15, 0.5)], [1.0, Color(0.12, 0.12, 0.12, 0.0)]]
	# broadside impact
	var isp := _ppm(Vector3(0, 0, -1), 70.0, 12.0, 28.0, 20.0, 0.6, 1.1, 0.3, 0.4)
	isp.particle_flag_align_y = true
	isp.color_ramp = _ramp(spark_ramp)
	_pm["impact_sparks"] = isp
	var idb := _ppm(Vector3(0, 0, 1), 180.0, 3.0, 8.0, 1.0, 0.06, 0.18, 0.3, 0.3)
	_tumble(idb)
	idb.scale_curve = _curve([[0.0, 1.0], [0.8, 1.0], [1.0, 0.0]], 1.0)
	_pm["impact_debris"] = idb
	# muzzle smoke (local +y is out of the gun)
	var msm := _ppm(Vector3.UP, 25.0, 2.0, 5.0, 2.5, 1.0, 1.8, 0.3, 0.25)
	_billboard_spin(msm)
	msm.scale_curve = _curve([[0.0, 0.5], [1.0, 2.2]], 3.0)
	msm.color_ramp = _ramp(smoke_ramp)
	_pm["muzzle_smoke"] = msm
	# beam impact fountain
	var fnt := _ppm(Vector3(-1, 0.3, 0), 55.0, 10.0, 24.0, 8.0, 0.5, 1.0, 0.6, 0.4)
	fnt.particle_flag_align_y = true
	fnt.color_ramp = _ramp(spark_ramp)
	_pm["fountain"] = fnt
	# hull hit (Chorus, Deathless): local +y is out of the hull
	var hs := _ppm(Vector3.UP, 55.0, 9.0, 22.0, 12.0, 0.5, 1.0, 0.3, 0.4)
	hs.particle_flag_align_y = true
	hs.color_ramp = _ramp([[0.0, Color(1.0, 0.8, 0.4, 1.0)], [0.4, Color(1.0, 0.45, 0.1, 1.0)], [1.0, Color(0.6, 0.12, 0.02, 0.0)]])
	_pm["hit_sparks"] = hs
	var hd := _ppm(Vector3.UP, 50.0, 4.0, 10.0, 1.5, 0.15, 0.4, 0.3, 0.3)
	_tumble(hd)
	hd.scale_curve = _curve([[0.0, 1.0], [0.8, 1.0], [1.0, 0.0]], 1.0)
	_pm["hit_debris"] = hd
	var hp := _ppm(Vector3.UP, 60.0, 1.0, 3.0, 2.0, 1.2, 2.0, 0.4, 0.3)
	_billboard_spin(hp)
	hp.scale_curve = _curve([[0.0, 0.5], [1.0, 1.2]])
	hp.color_ramp = _ramp(fire_ramp)
	_pm["puff"] = hp
	# breach: local +y is out of the hull
	var gas := _ppm(Vector3.UP, 9.0, 7.0, 11.0, 2.0, 0.5, 0.9, 0.25, 0.2)
	_billboard_spin(gas)
	gas.scale_curve = _curve([[0.0, 0.6], [1.0, 3.0]], 3.0)
	gas.color_ramp = _ramp([[0.0, Color(0.85, 0.88, 0.92, 0.0)], [0.08, Color(0.85, 0.88, 0.92, 0.45)],
		[0.5, Color(0.75, 0.78, 0.82, 0.22)], [1.0, Color(0.7, 0.72, 0.75, 0.0)]])
	_pm["gas"] = gas
	var bf := _ppm(Vector3.UP, 28.0, 1.5, 3.5, 2.0, 0.6, 1.2, 0.5, 0.3)
	_billboard_spin(bf)
	bf.scale_curve = _curve([[0.0, 0.6], [0.3, 1.0], [1.0, 0.3]], 1.0)
	bf.color_ramp = _ramp(fire_ramp)
	_pm["breach_fire"] = bf
	var bd := _ppm(Vector3.UP, 35.0, 1.5, 3.5, 0.0, 0.1, 0.28, 0.4, 0.3)
	_tumble(bd)
	bd.scale_curve = _curve([[0.0, 1.0], [0.85, 1.0], [1.0, 0.0]], 1.0)
	_pm["breach_debris"] = bd
	var bs := _ppm(Vector3.UP, 50.0, 6.0, 15.0, 10.0, 0.4, 0.8, 0.3, 0.4)
	bs.particle_flag_align_y = true
	bs.color_ramp = _ramp(spark_ramp)
	_pm["breach_sparks"] = bs
	var pop := _ppm(Vector3.UP, 70.0, 3.0, 6.5, 5.0, 1.0, 1.9, 0.4, 0.3)
	_billboard_spin(pop)
	pop.scale_curve = _curve([[0.0, 0.5], [0.3, 1.2], [1.0, 1.4]])
	pop.color_ramp = _ramp(fire_ramp)
	_pm["pop"] = pop
	# Corsair soot (the emitter is not rotated: the stern is -x)
	var soot := _ppm(Vector3(-1, 0.15, 0), 20.0, 4.0, 7.0, 0.5, 0.8, 1.4, 0.6, 0.3)
	_billboard_spin(soot)
	soot.scale_curve = _curve([[0.0, 0.6], [1.0, 3.0]], 3.0)
	soot.color_ramp = _ramp([[0.0, Color(0.06, 0.055, 0.05, 0.0)], [0.1, Color(0.07, 0.065, 0.06, 0.7)],
		[1.0, Color(0.09, 0.09, 0.09, 0.0)]])
	_pm["soot"] = soot
	# destruction event
	var fb := _ppm(Vector3.UP, 180.0, 4.0, 11.0, 4.0, 5.0, 8.0, 3.0, 0.35)
	_billboard_spin(fb)
	fb.scale_curve = _curve([[0.0, 0.4], [0.25, 1.0], [1.0, 1.6]])
	fb.color_ramp = _ramp([[0.0, Color(1.0, 0.95, 0.8, 1.0)], [0.15, Color(1.0, 0.6, 0.18, 1.0)],
		[0.55, Color(0.75, 0.2, 0.05, 0.8)], [1.0, Color(0.15, 0.04, 0.02, 0.0)]])
	_pm["fireball"] = fb
	var bsm := _ppm(Vector3.UP, 180.0, 2.0, 6.0, 0.6, 7.0, 12.0, 4.0, 0.2)
	_billboard_spin(bsm)
	bsm.scale_curve = _curve([[0.0, 0.5], [1.0, 1.8]])
	bsm.color_ramp = _ramp([[0.0, Color(0.10, 0.09, 0.085, 0.0)], [0.15, Color(0.12, 0.11, 0.10, 0.8)],
		[0.6, Color(0.10, 0.095, 0.09, 0.55)], [1.0, Color(0.08, 0.08, 0.08, 0.0)]])
	_pm["big_smoke"] = bsm
	var emb := _ppm(Vector3.UP, 180.0, 10.0, 30.0, 3.0, 0.25, 0.5, 2.0, 0.5)
	emb.color_ramp = _ramp([[0.0, Color(1.0, 0.85, 0.5, 1.0)], [0.5, Color(1.0, 0.45, 0.1, 1.0)], [1.0, Color(0.6, 0.1, 0.02, 0.0)]])
	_pm["embers"] = emb
	var bdb := _ppm(Vector3.UP, 180.0, 6.0, 18.0, 0.3, 0.2, 0.9, 2.0, 0.3)
	_tumble(bdb)
	bdb.scale_curve = _curve([[0.0, 1.0], [0.9, 1.0], [1.0, 0.0]], 1.0)
	_pm["big_debris"] = bdb
	var psq := _ppm(Vector3.UP, 180.0, 1.0, 3.0, 2.0, 1.0, 2.2, 1.0, 0.3)
	psq.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	psq.color_ramp = _ramp(fire_ramp)
	_pm["pre_squib"] = psq
	var ef := _ppm(Vector3.UP, 180.0, 0.5, 2.0, 1.0, 1.0, 2.0, 0.5, 0.3)
	ef.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_billboard_spin(ef)
	ef.scale_curve = _curve([[0.0, 0.5], [0.3, 1.0], [1.0, 0.4]], 1.0)
	ef.color_ramp = _ramp(fire_ramp)
	_pm["edge_fire"] = ef
	var es := _ppm(Vector3.UP, 180.0, 0.5, 1.5, 0.2, 1.5, 3.0, 0.5, 0.2)
	es.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_billboard_spin(es)
	es.scale_curve = _curve([[0.0, 0.5], [1.0, 2.0]])
	es.color_ramp = _ramp(smoke_ramp)
	_pm["edge_smoke"] = es
	var eq := _ppm(Vector3.UP, 180.0, 0.0, 0.5, 0.0, 1.2, 2.4, 0.5, 0.2)
	eq.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	eq.color_ramp = _ramp([[0.0, Color(1.0, 0.95, 0.8, 1.0)], [1.0, Color(1.0, 0.5, 0.1, 0.0)]])
	_pm["edge_squib"] = eq


# Breach decal textures, made once at start (128 x 128): a jagged black hole in a scorched ring, a glowing torn edge
# with short hot cracks, and a bowl normal map so the hole reads as a recess.
func _breach_textures() -> Dictionary:
	var sz := 128
	var alb := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var emi := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var nrm := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var nz := FastNoiseLite.new()
	nz.seed = 77
	nz.frequency = 0.06
	for y in sz:
		for x in sz:
			var px := (x + 0.5) / sz * 2.0 - 1.0
			var py := (y + 0.5) / sz * 2.0 - 1.0
			var r := sqrt(px * px + py * py)
			var ang := atan2(py, px)
			var jag := 0.3 + 0.07 * nz.get_noise_2d(cos(ang) * 40.0, sin(ang) * 40.0) + 0.04 * sin(ang * 13.0)
			var n2 := nz.get_noise_2d(x * 1.7, y * 1.7)
			var hole := 1.0 - smoothstep(jag - 0.015, jag + 0.015, r)
			var scorch := (1.0 - smoothstep(0.35, 0.95, r + n2 * 0.18)) * (1.0 - hole)
			var a := clampf(hole + scorch * 0.95, 0.0, 1.0)
			var base := Color(0.02, 0.015, 0.012).lerp(Color(0.10, 0.075, 0.06), clampf((r - jag) * 2.0 + n2 * 0.3, 0.0, 1.0))
			alb.set_pixel(x, y, Color(base.r, base.g, base.b, a))
			var edge := exp(-pow((r - jag) / 0.03, 2.0))
			var crack := 0.0
			var cr := absf(sin(ang * 7.0 + n2 * 3.0))
			if r > jag and r < jag + 0.22:
				crack = smoothstep(0.96, 1.0, cr) * (1.0 - (r - jag) / 0.22)
			var inner := hole * 0.25 * (1.0 - r / maxf(jag, 0.01))
			var heat := clampf(edge + crack * 0.8 + inner, 0.0, 1.0)
			emi.set_pixel(x, y, Color(heat, 0.42 * heat * heat, 0.08 * heat * heat * heat, 1.0))
			var nx := 0.0
			var ny := 0.0
			if r < jag + 0.04:
				var depth := clampf(r / maxf(jag, 0.01), 0.0, 1.0)
				nx = -px / maxf(r, 0.001) * depth * 0.7
				ny = py / maxf(r, 0.001) * depth * 0.7
			var nzv := sqrt(maxf(0.0, 1.0 - nx * nx - ny * ny))
			nrm.set_pixel(x, y, Color(nx * 0.5 + 0.5, ny * 0.5 + 0.5, nzv * 0.5 + 0.5, 1.0))
	for img in [alb, emi, nrm]:
		img.generate_mipmaps()
	return {"alb": ImageTexture.create_from_image(alb), "emi": ImageTexture.create_from_image(emi), "nrm": ImageTexture.create_from_image(nrm)}
