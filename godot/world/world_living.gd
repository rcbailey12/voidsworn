extends Node3D
# B "living terrain" for the board look trial (world/board_look.gd): each kind of special hex becomes a thing in space
# rather than a tinted hex (the board draws only a faint edge round it).
#   nebula      soft gas: billboards that sample one continuous 3D noise field in world space, so neighbouring puffs read
#               as one body; lit on the sun's side, dense cores glowing, soft where they meet hulls and rocks. Step 2:
#               shaped by a soft footprint of its own hexes (_mask) worn by the noise, so it has no hex outline and no
#               hex-shaped blobs, and never spills out of its hexes
#   ion storm   the same gas, darker than the sky behind it with violet-lit cores, and lightning: jagged bolts that flash
#               now and then, each with a light that catches the ships, rocks and the gas round it (never the fog)
#   debris      dense rock and wreck clusters: many more rocks of mixed size, wreckage (torn hull plates with their
#               frames, snapped hull frames, broken truss spars, gutted hull sections; some torn edges still hot, every
#               piece tumbling slowly), and a haze of fine dust
#   gravity well  the space round the dead star bends: a ring of lensing and slow twist out to the pull range, with faint
#               ripples running inward
# Built once, the first time a look needs it; the world shows or hides it. Nothing here changes the rules.

const WR := preload("res://world/world_rocks.gd")
const WS := preload("res://world/world_shaders.gd")
const FLOOK := preload("res://fx/faction_look.gd")

var W = null                 # the world (world.gd)
var rng := RandomNumberGenerator.new()
var gas_mats: Array = []     # [ShaderMaterial, base alpha gain]
var storm_mat: ShaderMaterial = null
var bolts: Array = []        # {mi, light, pos, next, start}
var clock := 0.0

const GAS_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + "%NOISE%" + """
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
// step 2: where the gas may be. Each texel holds (r) a soft round field summed over this terrain's hexes (1 near a hex
// centre, falling to about a fifth at its edge; neighbours merge into one body) and (g) the distance to the nearest
// hex's middle (hex metric: 1 at its flat edge), a hard stop so the gas never spills out of its hexes. The noise wears
// the round field into soft, irregular shapes: no hex outline and no hex-shaped blobs
uniform sampler2D mask_tex : filter_linear, repeat_disable;
uniform vec4 mask_box = vec4(0.0, 0.0, 1.0, 1.0);   // xz of the texture's corner, 1 / its size
uniform vec3 c_dark = vec3(0.10, 0.06, 0.20);
uniform vec3 c_lit = vec3(0.60, 0.40, 0.90);
uniform vec3 c_glow = vec3(0.80, 0.60, 1.00);
uniform vec3 sun_v = vec3(0.45, 0.70, 0.55);
uniform float dens = 0.7;
uniform float glow_from = 0.56;   // how dense the field must be before its core glows
uniform float gain_a = 1.0;
uniform float storm = 0.0;
uniform vec3 bolt = vec3(0.70, 0.80, 1.00);
uniform vec4 flashes[4];
varying vec4 vI;
varying vec2 vQ;
varying vec3 vW;
void vertex() {
	vI = INSTANCE_CUSTOM;   // x size, y spin seed, z density, w phase
	vec4 c = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	float a = vI.y * 6.2831;
	vec2 q = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * VERTEX.xy;
	vQ = VERTEX.xy * 2.0;
	c.xy += q * vI.x;
	vW = (INV_VIEW_MATRIX * c).xyz;
	POSITION = PROJECTION_MATRIX * c;
}
vec2 foot_at(vec2 xz) { return texture(mask_tex, (xz - mask_box.xy) * mask_box.zw).rg; }
void fragment() {
	float r = length(vQ);
	if (r > 1.0) { discard; }
	// the patch's footprint first (one texture read), so most of a puff that hangs outside costs nothing
	float hd = foot_at(vW.xz).g;
	if (hd > 1.0) { discard; }
	vec3 p = vW * 0.075 + vec3(TIME * 0.012, TIME * 0.004, TIME * 0.007);
	float w = wfbm3(p * 0.55 + 4.0);
	float n = wfbm3(p + vec3(w) * 0.9);
	// the footprint read again through a slow warp, so its edge bends and frays instead of following the hexes
	vec2 wv = vec2(w - 0.5, wfbm3(p * 0.4 - 7.0) - 0.5) * 9.0;
	float fw = foot_at(vW.xz + wv).r;
	// the noise lowers or raises the bar the round field must clear, so the edge wanders well inside the hexes
	float bar = 0.62 - 0.55 * smoothstep(0.3, 0.75, n);
	float foot = smoothstep(bar, bar + 0.3, fw) * (1.0 - smoothstep(0.8, 1.0, hd));
	// thinner near the top and bottom of the layer, so it reads as a body of gas, not a slab
	float layer = smoothstep(-6.5, -2.5, vW.y) * (1.0 - smoothstep(3.0, 8.5, vW.y));
	// a broad, flat-topped puff: the overlap of many hides each puff's own round edge, the field and footprint give the shape
	float shape = 1.0 - smoothstep(0.4, 1.0, r);
	float d = shape * foot * layer * smoothstep(0.30, 0.70, n) * vI.z;
	// soft where the gas meets a hull or a rock (no hard cut lines)
	float dz = texture(depth_tex, SCREEN_UV).r;
	vec4 vv = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, dz, 1.0);
	float scene_d = -vv.z / vv.w;
	d *= clamp((scene_d + VERTEX.z) / 5.0, 0.0, 1.0);
	if (d <= 0.002) { discard; }
	// lit from the sun's side: the field thinner toward the sun means light gets in
	float n2 = wfbm3(p + normalize(sun_v) * 0.22 + vec3(w) * 0.9);
	float lit = clamp(0.5 + (n - n2) * 5.0, 0.0, 1.0);
	vec3 col = mix(c_dark, c_lit, lit);
	// dense cores glow; the thin fringe stays dark so the shape reads against the sky
	col += c_glow * pow(max(n - glow_from, 0.0), 1.4) * 2.2 * foot;
	float a = d * dens;
	if (storm > 0.5) {
		// a faint flicker deep inside now and then (r2: kept low, it made the gas pale)
		float ph = fract(TIME * (0.09 + vI.w * 0.06) + vI.w * 13.0);
		float fl = smoothstep(0.0, 0.01, ph) * smoothstep(0.07, 0.02, ph);
		col += bolt * fl * 0.25 * shape * foot;
		for (int i = 0; i < 4; i++) {
			vec4 f = flashes[i];
			if (f.w > 0.001) {
				vec3 dd = vW - f.xyz;
				float g = exp(-dot(dd, dd) / 260.0) * f.w;
				// the flash lights the gas round the bolt; it never whitens it (step 2: no white blob)
				// (r1 on the PC: at 0.9 the whole storm read lavender most of the time, some bolt is nearly always lit)
				col += bolt * g * 0.32 * smoothstep(0.4, 0.75, n);
			}
		}
		col = min(col, vec3(0.5, 0.5, 0.8));
	}
	ALBEDO = col;
	ALPHA = clamp(a * gain_a, 0.0, 0.85);
}
"""

const BOLT_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
instance uniform float flash = 0.0;
uniform vec3 col = vec3(0.66, 0.66, 1.0);
varying vec4 vc;
void vertex() { vc = COLOR; }
// step 2: a thinner, dimmer glow and a capped core, so a strike seen end-on or stacked never blows out to a white blob
void fragment() { ALBEDO = min(col * vc.a * flash * 1.5, vec3(1.1)); }
"""

const DUST_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 col = vec3(0.6, 0.56, 0.5);
uniform float gain_a = 1.0;
varying vec2 vQ;
varying float vA;
void vertex() {
	vec4 c = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	float depth = max(-c.z, 1.0);
	float s = max(INSTANCE_CUSTOM.x, depth * 0.0011);
	vA = INSTANCE_CUSTOM.y * clamp(INSTANCE_CUSTOM.x / s, 0.25, 1.0);
	vQ = VERTEX.xy * 2.0;
	c.xy += VERTEX.xy * s;
	POSITION = PROJECTION_MATRIX * c;
}
void fragment() {
	float r = length(vQ);
	ALBEDO = col * exp(-r * r * 4.0) * vA * gain_a;
}
"""

const WELL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec3 well = vec3(0.0);
uniform float r_in = 60.0;
uniform float r_out = 120.0;
uniform float k = 1.0;
varying vec3 vW;
varying vec4 vWell;
void vertex() {
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vWell = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(well, 1.0));
}
void fragment() {
	float d = distance(vW.xz, well.xz);
	float w = smoothstep(r_in, r_in + 22.0, d) * (1.0 - smoothstep(r_out - 34.0, r_out, d));
	if (w <= 0.001) { discard; }
	vec2 cs = vWell.xy / vWell.w * 0.5 + 0.5;
	vec2 dv = SCREEN_UV - cs;
	// pushed outward like a lens, and dragged slowly round
	float s = 0.075 * w * (r_in + 22.0) / max(d, 1.0);
	float an = 0.06 * w + 0.04 * w * sin(TIME * 0.17);
	mat2 R = mat2(vec2(cos(an), sin(an)), vec2(-sin(an), cos(an)));
	vec2 suv = clamp(cs + R * dv * (1.0 - s), vec2(0.001), vec2(0.999));
	// never pull in something that stands in front of this layer (a ship above it): keep the plain view there
	float dsrc = texture(depth_tex, suv).r;
	vec4 vs = INV_PROJECTION_MATRIX * vec4(suv * 2.0 - 1.0, dsrc, 1.0);
	if (-vs.z / vs.w < -VERTEX.z - 0.5) { suv = SCREEN_UV; }
	vec3 c = textureLod(screen_tex, suv, 0.0).rgb;
	float rip = 0.5 + 0.5 * sin(d * 0.42 + TIME * 1.5);
	c *= 1.0 + 0.12 * w * rip;
	c += vec3(0.035, 0.02, 0.07) * w * (0.4 + 0.6 * rip);
	ALBEDO = c;
	ALPHA = w * k;
}
"""


func build(world) -> void:
	W = world
	rng.seed = int(W.setting.get("seed", 7)) * 31 + 991
	var pts: Dictionary = W._terr_pts
	if not (pts["neb"] as Array).is_empty():
		_gas(pts["neb"], false)
	if not (pts["storm"] as Array).is_empty():
		_gas(pts["storm"], true)
		_bolts(pts["storm"])
	if not (pts["debris"] as Array).is_empty():
		_debris(pts["debris"])
	if W._well != Vector3.INF:
		_well(W._well)


func set_gas_k(k: float) -> void:
	for g in gas_mats:
		(g[0] as ShaderMaterial).set_shader_parameter("gain_a", float(g[1]) * k)


func _quad_mm(n: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	mm.mesh = qm
	mm.instance_count = n
	return mm


# ---------------------------------------------------------------- nebula and storm gas

func _gas(ps: Array, storm: bool) -> void:
	var low: bool = W.quality == "low"
	# step 2: fewer, broader, softer puffs; their shape comes from one noise field and the patch's footprint (_mask), so
	# the patch reads as one body of gas, not a row of cotton balls on hex tiles
	var per := 3 if low else 5
	var n_big := ps.size() / 3
	var mm := _quad_mm(ps.size() * per + n_big)
	var i := 0
	for p in ps:
		for k in per:
			var a := rng.randf() * TAU
			var rr := sqrt(rng.randf()) * 6.0
			# most of the gas low, round the ships' feet; a thin veil over them
			var y := lerpf(-4.0, 5.5, pow(rng.randf(), 1.4))
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, (p as Vector3) + Vector3(cos(a) * rr, y, sin(a) * rr)))
			mm.set_instance_custom_data(i, Color(rng.randf_range(24.0, 34.0), rng.randf(), rng.randf_range(0.55, 0.85), rng.randf()))
			i += 1
	# a few broad, thin puffs that tie the patch together
	for k in n_big:
		var p: Vector3 = ps[rng.randi() % ps.size()]
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p + Vector3(rng.randf_range(-4, 4), rng.randf_range(-2, 1), rng.randf_range(-4, 4))))
		mm.set_instance_custom_data(i, Color(rng.randf_range(36.0, 46.0), rng.randf(), rng.randf_range(0.3, 0.4), rng.randf()))
		i += 1
	var mi := MultiMeshInstance3D.new()
	mi.name = "Storm" if storm else "Nebula"
	mi.multimesh = mm
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = GAS_SHADER.replace("%NOISE%", WS.NOISE)
	m.shader = sh
	m.set_shader_parameter("sun_v", Vector3(0.45, 0.70, 0.55))   # world.gd SUN
	var mk: Array = _mask(ps)
	m.set_shader_parameter("mask_tex", mk[0])
	m.set_shader_parameter("mask_box", mk[1])
	var g := 1.0
	if storm:
		# a dark, heavy mass (it must stand out from bright blue skies) that the lightning lights from inside
		# step 2: a body darker than the sky behind it (r3 on the PC: a dark violet still read pale and lavender over the
		# near-black skies, because it was lighter than them), lit violet only in its dense cores and on its sun side
		m.set_shader_parameter("c_dark", Vector3(0.003, 0.003, 0.006))
		m.set_shader_parameter("c_lit", Vector3(0.035, 0.028, 0.06))
		m.set_shader_parameter("c_glow", Vector3(0.3, 0.17, 0.62))
		m.set_shader_parameter("bolt", Vector3(0.66, 0.6, 1.0))
		m.set_shader_parameter("storm", 1.0)
		m.set_shader_parameter("dens", 1.0)
		m.set_shader_parameter("glow_from", 0.5)
		storm_mat = m
		_set_flashes([])
	else:
		var b: Array = FLOOK.of(W._fac).get("nebula", FLOOK.of("voidsworn")["nebula"])
		# the setting's own nebula colours, pulled toward the violet every nebula hex carries (its edge, its tactical fill)
		var vio := Vector3(0.62, 0.42, 1.0)
		var c1: Vector3 = (b[1] as Vector3).lerp(vio * (b[1] as Vector3).length() / vio.length(), 0.5)
		var c2: Vector3 = (b[2] as Vector3).lerp(vio * (b[2] as Vector3).length() / vio.length(), 0.45)
		m.set_shader_parameter("c_dark", c1 * 0.18)
		m.set_shader_parameter("c_lit", c1.lerp(c2, 0.4) * 0.9)
		m.set_shader_parameter("c_glow", c2 * 0.8)
		m.set_shader_parameter("dens", 0.5)
	# drawn before the board's own fills, so a move hex inside the gas still shows on top
	m.render_priority = -5
	gas_mats.append([m, g])
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 30.0
	add_child(mi)


# the patch's footprint as a small two-channel float texture over its hexes (one texel per world unit): r the soft
# round field (a Gaussian round each hex centre, summed), g the hex distance to the nearest hex centre (0 at a centre, 1
# at its flat edge, 2 and more outside); returns [texture, Vector4(x0, z0, 1/w, 1/h)]
func _mask(ps: Array) -> Array:
	const HIN := 8.660254          # a hex's inner radius (corner radius 10, board.gd HS)
	const STEP := 1.0
	const SIG2 := 42.0             # the round field's spread (squared): about a fifth of a hex centre's strength at its edge
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for p in ps:
		lo = lo.min(Vector2((p as Vector3).x, (p as Vector3).z))
		hi = hi.max(Vector2((p as Vector3).x, (p as Vector3).z))
	lo -= Vector2(24, 24)
	hi += Vector2(24, 24)
	var w := int(ceil((hi.x - lo.x) / STEP)) + 1
	var h := int(ceil((hi.y - lo.y) / STEP)) + 1
	var f := PackedFloat32Array()
	f.resize(w * h * 2)
	for j in w * h:
		f[j * 2] = 0.0
		f[j * 2 + 1] = 2.0
	for p in ps:
		var c := Vector2((p as Vector3).x, (p as Vector3).z)
		var x0 := int((c.x - 14.0 - lo.x) / STEP)
		var z0 := int((c.y - 14.0 - lo.y) / STEP)
		for zi in range(maxi(z0, 0), mini(z0 + int(28.0 / STEP) + 2, h)):
			var dz := absf(lo.y + zi * STEP - c.y)
			for xi in range(maxi(x0, 0), mini(x0 + int(28.0 / STEP) + 2, w)):
				var dx := absf(lo.x + xi * STEP - c.x)
				var j := (zi * w + xi) * 2
				f[j] += exp(-(dx * dx + dz * dz) / SIG2)
				var d := maxf(dx, 0.5 * dx + 0.8660254 * dz) / HIN
				if d < f[j + 1]:
					f[j + 1] = d
	var img := Image.create_from_data(w, h, false, Image.FORMAT_RGF, f.to_byte_array())
	return [ImageTexture.create_from_image(img), Vector4(lo.x - 0.5 * STEP, lo.y - 0.5 * STEP, 1.0 / (w * STEP), 1.0 / (h * STEP))]


func _set_flashes(fs: Array) -> void:
	if storm_mat == null:
		return
	var arr: Array = []
	for k in 4:
		arr.append(fs[k] if k < fs.size() else Vector4.ZERO)
	storm_mat.set_shader_parameter("flashes", arr)


# lightning: one bolt for about every two storm hexes (at most six), each a jagged line with a branch or two between two
# points inside the storm, flashing every few seconds; the first four carry a light
func _bolts(ps: Array) -> void:
	var n := clampi(ps.size() / 2, 1, 6)
	var bm := ShaderMaterial.new()
	var bsh := Shader.new()
	bsh.code = BOLT_SHADER
	bm.shader = bsh
	for b in n:
		# a short strike inside one storm hex and its neighbour (r1: bolts between far hexes drew long white wires)
		var a: Vector3 = ps[rng.randi() % ps.size()]
		var near: Array = []
		for q in ps:
			if (q as Vector3).distance_to(a) < 19.0 and (q as Vector3).distance_to(a) > 1.0:
				near.append(q)
		var z: Vector3 = near[rng.randi() % near.size()] if not near.is_empty() else a + Vector3(rng.randf_range(-8, 8), 0, rng.randf_range(-8, 8))
		a += Vector3(rng.randf_range(-3, 3), rng.randf_range(2.0, 5.0), rng.randf_range(-3, 3))
		z += Vector3(rng.randf_range(-3, 3), rng.randf_range(-3.0, 0.5), rng.randf_range(-3, 3))
		if a.distance_to(z) > 18.0:
			z = a + (z - a).normalized() * 18.0
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var path := _jag(a, z, 9, 0.09)
		_ribbon(st, path, 0.1, 0.75)
		for k in rng.randi_range(1, 2):
			var j := rng.randi_range(2, path.size() - 3)
			var from: Vector3 = path[j]
			var to := from + (z - a).normalized().rotated(Vector3.UP, rng.randf_range(-1.2, 1.2)) * rng.randf_range(3.0, 6.0) + Vector3(0, rng.randf_range(-2, 1), 0)
			_ribbon(st, _jag(from, to, 5, 0.12), 0.07, 0.5)
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = bm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.set_instance_shader_parameter("flash", 0.0)
		add_child(mi)
		var light: OmniLight3D = null
		if b < 4:
			light = OmniLight3D.new()
			light.light_color = Color(0.7, 0.66, 1.0)
			light.omni_range = 40.0
			light.omni_attenuation = 1.4
			light.shadow_enabled = false
			# step 2: the strike lights ships, rocks and the gas, never the scene's thin volumetric fog (r1 and r2 on the PC:
			# the fog's cells lit up round each bolt as pale, square lavender blocks, the "pale blue storm" of the trial)
			light.light_volumetric_fog_energy = 0.0
			light.light_energy = 0.0
			light.position = (a + z) * 0.5
			add_child(light)
		bolts.append({"mi": mi, "light": light, "pos": (a + z) * 0.5, "next": rng.randf_range(0.3, 3.5), "start": -10.0})


func _jag(a: Vector3, z: Vector3, n: int, amp: float) -> Array:
	var out: Array = [a]
	var len := a.distance_to(z)
	for i in range(1, n):
		var t := float(i) / n
		out.append(a.lerp(z, t) + Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * len * amp)
	out.append(z)
	return out


# a bolt as two crossed ribbons (so it reads from any angle): a bright core and a soft glow either side of it
func _ribbon(st: SurfaceTool, path: Array, w_core: float, w_glow: float) -> void:
	for i in path.size() - 1:
		var p0: Vector3 = path[i]
		var p1: Vector3 = path[i + 1]
		var d := (p1 - p0).normalized()
		var s1 := d.cross(Vector3.UP)
		if s1.length() < 0.1:
			s1 = d.cross(Vector3.RIGHT)
		s1 = s1.normalized()
		var s2 := d.cross(s1).normalized()
		for s in [s1, s2]:
			_quad(st, p0, p1, s * w_core, 1.0, 1.0)
			_quad(st, p0, p1, s * w_glow, 0.14, 0.0)


func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, side: Vector3, a_mid: float, a_edge: float) -> void:
	var cm := Color(1, 1, 1, a_mid)
	var ce := Color(1, 1, 1, a_edge)
	for sgn in [1.0, -1.0]:
		var e0: Vector3 = p0 + side * sgn
		var e1: Vector3 = p1 + side * sgn
		for v in [[p0, cm], [p1, cm], [e1, ce], [p0, cm], [e1, ce], [e0, ce]]:
			st.set_color(v[1])
			st.add_vertex(v[0])


# a flash: a bright strike, a dip, a second strike and a fade (about a third of a second)
static func _flash(t: float) -> float:
	if t < 0.0 or t > 0.42:
		return 0.0
	if t < 0.05:
		return 1.0
	if t < 0.09:
		return 0.15
	if t < 0.15:
		return 0.85
	return 0.6 * (1.0 - (t - 0.15) / 0.27)


func _process(dt: float) -> void:
	if bolts.is_empty() or not visible:
		return
	clock += dt
	var fs: Array = []
	for b in bolts:
		if clock >= float(b["next"]):
			b["start"] = clock
			b["next"] = clock + rng.randf_range(2.2, 6.5)
		var v := _flash(clock - float(b["start"]))
		(b["mi"] as MeshInstance3D).set_instance_shader_parameter("flash", v)
		if b["light"] != null:
			(b["light"] as OmniLight3D).light_energy = v * 3.2
		if v > 0.0 and fs.size() < 4:
			var p: Vector3 = b["pos"]
			fs.append(Vector4(p.x, p.y, p.z, v))
	_set_flashes(fs)


# ---------------------------------------------------------------- debris: dense rock and wreck clusters

func _debris(ps: Array) -> void:
	var kind: String = W._rock_kind
	var mat: Material = W._mat(kind)
	var batch = WR.Batch.new()
	var low: bool = W.quality == "low"
	var shard_meshes := _shard_meshes()
	var wsh := Shader.new()
	wsh.code = WRECK_SHADER.replace("%NOISE%", WS.NOISE)
	var metal := ShaderMaterial.new()
	metal.shader = wsh
	var hot := ShaderMaterial.new()
	hot.shader = wsh
	hot.set_shader_parameter("hot", 1.0)
	var shards := {}     # "mesh|mat" -> [Transform3D]
	var n_dust := 0
	for p in ps:
		for i in (rng.randi_range(8, 12) if low else rng.randi_range(15, 22)):
			var a := rng.randf() * TAU
			var rr := sqrt(rng.randf()) * 8.6
			var s := 0.3 + 2.5 * pow(rng.randf(), 2.4)
			var nm: String = W._pick(kind, rng)
			if nm == "":
				break
			batch.add(nm + "_lo" if s < 1.2 else nm, mat, s > 1.8, Transform3D(W._rand_basis(rng).scaled(Vector3.ONE * s), (p as Vector3) + Vector3(cos(a) * rr, rng.randf_range(-3.5, 4.0), sin(a) * rr)),
				W._rand_axis(rng), rng.randf_range(0.05, 0.3), rng.randf())
		# step 2: wreckage that reads as wreckage: mostly mid-size pieces, and often one big one that carries the patch's
		# silhouette at battle distance
		for i in rng.randi_range(3, 5) + (1 if rng.randf() < 0.55 else 0):
			var a := rng.randf() * TAU
			var rr := sqrt(rng.randf()) * 7.0
			var mk := rng.randi() % shard_meshes.size()
			var mt := 1 if rng.randf() < 0.22 else 0
			var key := "%d|%d" % [mk, mt]
			if not shards.has(key):
				shards[key] = []
			var sc := rng.randf_range(1.3, 2.6) if i > 0 else rng.randf_range(2.6, 3.8)
			var b := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)).scaled(Vector3.ONE * sc)
			shards[key].append(Transform3D(b, (p as Vector3) + Vector3(cos(a) * rr, rng.randf_range(-2.5, 3.0), sin(a) * rr)))
		n_dust += 0 if low else 48
	var n := batch.build(self, Callable(WR, "mesh"))
	for key in shards:
		var parts: PackedStringArray = str(key).split("|")
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = shard_meshes[int(parts[0])]
		var xs: Array = shards[key]
		mm.instance_count = xs.size()
		for i in xs.size():
			mm.set_instance_transform(i, xs[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = hot if parts[1] == "1" else metal
		mmi.extra_cull_margin = 8.0     # the shader tumbles each piece about its middle
		add_child(mmi)
		n += xs.size()
	if n_dust > 0:
		var mm := _quad_mm(n_dust)
		var i := 0
		for p in ps:
			for k in 48:
				var a := rng.randf() * TAU
				var rr := sqrt(rng.randf()) * 9.0
				mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, (p as Vector3) + Vector3(cos(a) * rr, rng.randf_range(-3.0, 4.5), sin(a) * rr)))
				mm.set_instance_custom_data(i, Color(rng.randf_range(0.08, 0.25), rng.randf_range(0.3, 0.9), 0, 0))
				i += 1
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		var m := ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = DUST_SHADER
		m.shader = sh
		m.set_shader_parameter("col", Vector3(0.62, 0.57, 0.5))
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.extra_cull_margin = 10.0
		add_child(mi)
	W.notes.append("living debris: %d rocks and wreck pieces on %d hexes" % [n, ps.size()])


# step 2 (Ryan's note on plain wreck pieces): real wreckage, built once per battle from the battle's seed. Four kinds,
# two of each, about two units across before scaling:
#   hull fragment   a curved piece of outer hull, torn at both ends, with frames and a stringer on its inside
#   broken frame    a hull frame (a ring rib) snapped part way round, one end bent, a spoke and a scrap of plate on it
#   truss           a three-sided lattice spar, one chord snapped short, the end bent
#   hull section    a deck, a bulkhead and one wall still standing, the other wall torn down to stubs
# Vertex colour: rgb the paint (outer hull lighter, insides darker, torn edges scorched); alpha how hot the torn metal
# is, which only the "hot" material shows.
const WRECK_SHADER := """
shader_type spatial;
render_mode cull_disabled;
""" + "%NOISE%" + """
uniform float hot = 0.0;
uniform vec3 hot_col = vec3(1.0, 0.42, 0.12);
varying vec3 lp;
varying float tumble;
void vertex() {
	// a slow tumble, each piece its own axis and speed, about the piece's own middle
	float h = fract(sin(float(INSTANCE_ID) * 12.9898) * 43758.5453);
	float h2 = fract(h * 91.7 + 0.31);
	vec3 ax = normalize(vec3(h - 0.5, 0.6, h2 - 0.5));
	float an = TIME * mix(0.02, 0.07, h2) * (h > 0.5 ? 1.0 : -1.0) + h * 6.2831;
	float c = cos(an);
	float s = sin(an);
	mat3 R = mat3(vec3(c + ax.x * ax.x * (1.0 - c), ax.y * ax.x * (1.0 - c) + ax.z * s, ax.z * ax.x * (1.0 - c) - ax.y * s),
		vec3(ax.x * ax.y * (1.0 - c) - ax.z * s, c + ax.y * ax.y * (1.0 - c), ax.z * ax.y * (1.0 - c) + ax.x * s),
		vec3(ax.x * ax.z * (1.0 - c) + ax.y * s, ax.y * ax.z * (1.0 - c) - ax.x * s, c + ax.z * ax.z * (1.0 - c)));
	lp = VERTEX;
	VERTEX = R * VERTEX;
	NORMAL = R * NORMAL;
}
void fragment() {
	if (!FRONT_FACING) { NORMAL = -NORMAL; }
	float g = wfbm3(lp * 2.3);
	// panel seams on the plates, and grime and wear
	vec3 q = abs(fract(lp * vec3(1.6, 1.25, 1.6)) - 0.5);
	float seam = 1.0 - 0.38 * (1.0 - smoothstep(0.0, 0.035, 0.5 - max(max(q.x, q.y), q.z)));
	ALBEDO = COLOR.rgb * mix(0.55, 1.2, g) * seam;
	METALLIC = 0.6;
	ROUGHNESS = clamp(0.42 + 0.4 * g, 0.0, 1.0);
	EMISSION = hot_col * COLOR.a * hot * (0.5 + 0.9 * g) * 2.2;
}
"""

const C_HULL := Color(0.3, 0.295, 0.285, 0.0)
const C_IN := Color(0.13, 0.13, 0.135, 0.0)
const C_FRAME := Color(0.2, 0.19, 0.18, 0.0)
const C_TORN := Color(0.07, 0.06, 0.055, 1.0)


func _shard_meshes() -> Array:
	var out: Array = []
	for v in 2:
		out.append(_w_hull_fragment())
		out.append(_w_frame())
		out.append(_w_truss())
		out.append(_w_section())
	return out


func _w_commit(st: SurfaceTool) -> ArrayMesh:
	st.generate_normals()
	return st.commit()


# a triangle with flat shading (generate_normals with no smoothing groups gives each face its own normal)
func _w_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	st.set_smooth_group(0xFFFFFFFF)
	st.set_color(ca)
	st.add_vertex(a)
	st.set_color(cb)
	st.add_vertex(b)
	st.set_color(cc)
	st.add_vertex(c)


func _w_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ca: Color, cb := Color(-1, 0, 0), cc := Color(-1, 0, 0), cd := Color(-1, 0, 0)) -> void:
	var b2 := ca if cb.r < 0.0 else cb
	var c2 := ca if cc.r < 0.0 else cc
	var d2 := ca if cd.r < 0.0 else cd
	_w_tri(st, a, b, c, ca, b2, c2)
	_w_tri(st, a, c, d, ca, c2, d2)


# a beam of square-ish section from p0 to p1 (w wide, t deep; up gives its roll)
func _w_beam(st: SurfaceTool, p0: Vector3, p1: Vector3, w: float, t: float, col: Color, up := Vector3.UP) -> void:
	var d := (p1 - p0).normalized()
	var sx := d.cross(up)
	if sx.length() < 0.05:
		sx = d.cross(Vector3.RIGHT)
	sx = sx.normalized() * w * 0.5
	var sy := sx.cross(d).normalized() * t * 0.5
	var c := [p0 - sx - sy, p0 + sx - sy, p0 + sx + sy, p0 - sx + sy]
	var e := [p1 - sx - sy, p1 + sx - sy, p1 + sx + sy, p1 - sx + sy]
	for i in 4:
		_w_quad(st, c[i], c[(i + 1) % 4], e[(i + 1) % 4], e[i], col)
	_w_quad(st, c[3], c[2], c[1], c[0], C_TORN)
	_w_quad(st, e[0], e[1], e[2], e[3], C_TORN)


func _w_hull_fragment() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var R := rng.randf_range(1.1, 1.6)
	var span := rng.randf_range(1.2, 1.9)       # radians round the hull
	var L := rng.randf_range(1.8, 2.4)
	var th := 0.07
	var n := 9
	var z0: Array = []
	var z1: Array = []
	for i in n + 1:
		# both ends torn: each column of the plate ends at its own length
		z0.append(rng.randf_range(0.0, 0.35) * (1.0 if i % 2 == 0 else 0.6))
		z1.append(L - rng.randf_range(0.0, 0.55) * (1.0 if rng.randf() < 0.7 else 0.2))
	var pt := func(i: int, z: float, r: float) -> Vector3:
		var an := -span * 0.5 + span * float(i) / n
		return Vector3(sin(an) * r, cos(an) * r - R, z - L * 0.5)
	for i in n:
		var a0: Vector3 = pt.call(i, z0[i], R)
		var b0: Vector3 = pt.call(i + 1, z0[i + 1], R)
		var b1: Vector3 = pt.call(i + 1, z1[i + 1], R)
		var a1: Vector3 = pt.call(i, z1[i], R)
		_w_quad(st, a0, b0, b1, a1, C_HULL)
		var ia0: Vector3 = pt.call(i, z0[i], R - th)
		var ib0: Vector3 = pt.call(i + 1, z0[i + 1], R - th)
		var ib1: Vector3 = pt.call(i + 1, z1[i + 1], R - th)
		var ia1: Vector3 = pt.call(i, z1[i], R - th)
		_w_quad(st, ia1, ib1, ib0, ia0, C_IN)
		# the torn ends: scorched and, on hot pieces, still glowing
		_w_quad(st, a1, b1, ib1, ia1, C_TORN)
		_w_quad(st, ia0, ib0, b0, a0, C_TORN)
	# the long edges
	_w_quad(st, pt.call(0, z0[0], R), pt.call(0, z1[0], R), pt.call(0, z1[0], R - th), pt.call(0, z0[0], R - th), C_TORN)
	_w_quad(st, pt.call(n, z0[n], R - th), pt.call(n, z1[n], R - th), pt.call(n, z1[n], R), pt.call(n, z0[n], R), C_TORN)
	# frames inside, across the plate, each stopping where the plate is torn away
	var fz := rng.randf_range(0.45, 0.7)
	while fz < L - 0.3:
		for i in n:
			if fz > float(z0[i]) + 0.05 and fz < float(z1[i]) - 0.05 and fz > float(z0[i + 1]) + 0.05 and fz < float(z1[i + 1]) - 0.05:
				_w_beam(st, pt.call(i, fz, R - th - 0.07), pt.call(i + 1, fz, R - th - 0.07), 0.06, 0.15, C_FRAME, Vector3(0, 0, 1))
		fz += rng.randf_range(0.55, 0.75)
	# a stringer along it
	var si := rng.randi_range(2, n - 2)
	_w_beam(st, pt.call(si, maxf(z0[si], 0.1) + 0.05, R - th - 0.05), pt.call(si, float(z1[si]) - 0.05, R - th - 0.05), 0.08, 0.1, C_FRAME)
	return _w_commit(st)


func _w_frame() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var R := rng.randf_range(1.0, 1.3)
	var a0 := rng.randf_range(-0.4, 0.4)
	var a1 := a0 + rng.randf_range(2.4, 3.6)
	var n := 12
	var pts: Array = []
	for i in n + 1:
		var an := lerpf(a0, a1, float(i) / n)
		pts.append(Vector3(cos(an) * R, sin(an) * R, 0.0))
	# the last stretch snapped and bent out of the ring
	var kink: Vector3 = pts[n - 3]
	for i in range(n - 2, n + 1):
		var off := (pts[i] as Vector3) - kink
		pts[i] = kink + off.rotated(Vector3(0.3, 1.0, 0.2).normalized(), 0.7) * 0.9
	for i in n:
		_w_beam(st, pts[i], pts[i + 1], 0.16, 0.24, C_FRAME, Vector3(0, 0, 1))
	# a spoke toward the middle, broken short, and a second stub
	var sp: Vector3 = pts[n / 3]
	_w_beam(st, sp, sp * 0.35, 0.1, 0.1, C_FRAME)
	var sp2: Vector3 = pts[n / 2 + 1]
	_w_beam(st, sp2, sp2 * 0.75, 0.09, 0.09, C_FRAME)
	# a scrap of hull plate still riveted to the outside
	for i in range(1, 5):
		var p0: Vector3 = (pts[i] as Vector3) * 1.09
		var p1: Vector3 = (pts[i + 1] as Vector3) * 1.09
		var w0 := rng.randf_range(0.25, 0.6)
		var w1 := rng.randf_range(0.25, 0.6)
		_w_quad(st, p0 + Vector3(0, 0, -w0), p1 + Vector3(0, 0, -w1), p1 + Vector3(0, 0, w1 * 0.7), p0 + Vector3(0, 0, w0 * 0.7), C_HULL)
		_w_quad(st, p0 * 0.985 + Vector3(0, 0, w0 * 0.7), p1 * 0.985 + Vector3(0, 0, w1 * 0.7), p1 * 0.985 + Vector3(0, 0, -w1), p0 * 0.985 + Vector3(0, 0, -w0), C_IN)
	var mid: Vector3 = pts[n / 2]
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	st2.append_from(_w_commit(st), 0, Transform3D(Basis.IDENTITY, -mid * 0.5))
	return st2.commit()


func _w_truss() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var L := rng.randf_range(2.2, 2.8)
	var r := 0.26
	var ch: Array = []
	for k in 3:
		var an := TAU * k / 3.0
		ch.append(Vector3(0, cos(an) * r, sin(an) * r))
	var ends := [L, L * rng.randf_range(0.55, 0.75), L * rng.randf_range(0.8, 0.95)]
	for k in 3:
		var e: float = ends[k]
		var p0: Vector3 = ch[k] + Vector3(-L * 0.5, 0, 0)
		var p1: Vector3 = ch[k] + Vector3(-L * 0.5 + e, 0, 0)
		if k == 2:
			# this chord bent away where it broke
			var pm: Vector3 = ch[k] + Vector3(-L * 0.5 + e * 0.7, 0, 0)
			_w_beam(st, p0, pm, 0.07, 0.07, C_FRAME)
			_w_beam(st, pm, pm + Vector3(e * 0.3, 0.25, 0.3), 0.07, 0.07, C_FRAME)
		else:
			_w_beam(st, p0, p1, 0.07, 0.07, C_FRAME)
	# cross bracing between the chords, only where both still stand
	var x := 0.0
	var step := 0.42
	var flip := false
	while x + step < L:
		for k in 3:
			var k2 := (k + 1) % 3
			if x + step < float(ends[k]) * (0.7 if k == 2 else 1.0) and x + step < float(ends[k2]) * (0.7 if k2 == 2 else 1.0):
				var a: Vector3 = ch[k] + Vector3(-L * 0.5 + (x if not flip else x + step), 0, 0)
				var b: Vector3 = ch[k2] + Vector3(-L * 0.5 + (x + step if not flip else x), 0, 0)
				_w_beam(st, a, b, 0.035, 0.035, C_FRAME)
		flip = not flip
		x += step
	# end plate (a triangle frame) at the root
	for k in 3:
		_w_beam(st, ch[k] + Vector3(-L * 0.5, 0, 0), ch[(k + 1) % 3] + Vector3(-L * 0.5, 0, 0), 0.06, 0.06, C_FRAME)
	return _w_commit(st)


func _w_section() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var L := rng.randf_range(1.8, 2.3)
	var W := rng.randf_range(1.1, 1.4)
	var H := rng.randf_range(0.6, 0.85)
	var t := 0.06
	# the deck, torn ragged at the far end
	var n := 6
	for i in n:
		var x0 := -W * 0.5 + W * i / n
		var x1 := -W * 0.5 + W * (i + 1) / n
		var e0 := L * 0.5 - rng.randf_range(0.0, 0.5)
		var e1 := L * 0.5 - rng.randf_range(0.0, 0.5)
		_w_quad(st, Vector3(x0, 0, -L * 0.5), Vector3(x1, 0, -L * 0.5), Vector3(x1, 0, e1), Vector3(x0, 0, e0), C_IN)
		_w_quad(st, Vector3(x0, -t, e0), Vector3(x1, -t, e1), Vector3(x1, -t, -L * 0.5), Vector3(x0, -t, -L * 0.5), C_HULL)
		_w_quad(st, Vector3(x0, 0, e0), Vector3(x1, 0, e1), Vector3(x1, -t, e1), Vector3(x0, -t, e0), C_TORN)
	# the bulkhead at the near end, with a doorway
	var bz := -L * 0.5
	_w_beam(st, Vector3(-W * 0.5, H * 0.5, bz), Vector3(-W * 0.18, H * 0.5, bz), H, 0.06, C_FRAME, Vector3(0, 0, 1))
	_w_beam(st, Vector3(W * 0.18, H * 0.5, bz), Vector3(W * 0.5, H * 0.5, bz), H, 0.06, C_FRAME, Vector3(0, 0, 1))
	_w_beam(st, Vector3(-W * 0.18, H * 0.85, bz), Vector3(W * 0.18, H * 0.85, bz), H * 0.3, 0.06, C_FRAME, Vector3(0, 0, 1))
	# one wall standing, with its frames
	var m := 7
	for i in m:
		var z0 := -L * 0.5 + L * 0.85 * i / m
		var z1 := -L * 0.5 + L * 0.85 * (i + 1) / m
		var h0 := H * (1.0 if i < m - 2 else rng.randf_range(0.4, 0.9))
		var h1 := H * (1.0 if i < m - 3 else rng.randf_range(0.3, 0.8))
		var xw := -W * 0.5
		_w_quad(st, Vector3(xw, 0, z0), Vector3(xw, 0, z1), Vector3(xw, h1, z1), Vector3(xw, h0, z0), C_IN)
		_w_quad(st, Vector3(xw - t, h0, z0), Vector3(xw - t, h1, z1), Vector3(xw - t, 0, z1), Vector3(xw - t, 0, z0), C_HULL)
		_w_quad(st, Vector3(xw, h0, z0), Vector3(xw, h1, z1), Vector3(xw - t, h1, z1), Vector3(xw - t, h0, z0), C_TORN)
		if i % 2 == 0:
			_w_beam(st, Vector3(xw + 0.05, 0, z0), Vector3(xw + 0.05, h0 * 0.95, z0), 0.07, 0.1, C_FRAME, Vector3(1, 0, 0))
	# the other wall torn down to stubs
	for i in 4:
		var z := -L * 0.5 + 0.15 + i * L * 0.2
		var h := rng.randf_range(0.12, 0.45) * H
		_w_beam(st, Vector3(W * 0.5, 0, z), Vector3(W * 0.5 + rng.randf_range(-0.05, 0.12), h, z + rng.randf_range(-0.1, 0.1)), 0.08, 0.1, C_FRAME, Vector3(1, 0, 0))
	# a pipe run along the deck
	_w_beam(st, Vector3(-W * 0.3, 0.1, -L * 0.45), Vector3(-W * 0.3, 0.1, L * 0.3), 0.08, 0.08, C_FRAME)
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	st2.append_from(_w_commit(st), 0, Transform3D(Basis.IDENTITY, Vector3(0, -H * 0.4, 0)))
	return st2.commit()


# ---------------------------------------------------------------- the gravity well

func _well(c: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(250, 250)
	mi.mesh = pm
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = WELL_SHADER
	m.shader = sh
	m.set_shader_parameter("well", c)
	# the pull reaches five hexes (about 87 units); the dead star's own lens and disc fill the middle
	m.set_shader_parameter("r_in", 58.0)
	m.set_shader_parameter("r_out", 118.0)
	# after the dead star's lens (-30), before the dark floor (-20) and the disc, so the disc stays on top
	m.render_priority = -25
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(c.x, -1.5, c.z)
	add_child(mi)
