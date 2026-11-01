extends Node3D
# B "living terrain" for the board look trial (world/board_look.gd): each kind of special hex becomes a thing in space
# rather than a tinted hex (the board draws only a faint edge round it).
#   nebula      soft gas: billboards that sample one continuous 3D noise field in world space, so neighbouring puffs read
#               as one body; lit on the sun's side, dense cores glowing, soft where they meet hulls and rocks
#   ion storm   darker gas with lightning: jagged bolts that flash now and then, each with a real light that catches the
#               ships, rocks and the gas round it
#   debris      dense rock and wreck clusters: many more rocks of mixed size, broken hull plates and girders (some still
#               hot), and a haze of fine dust
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
uniform vec3 c_dark = vec3(0.10, 0.06, 0.20);
uniform vec3 c_lit = vec3(0.60, 0.40, 0.90);
uniform vec3 c_glow = vec3(0.80, 0.60, 1.00);
uniform vec3 sun_v = vec3(0.45, 0.70, 0.55);
uniform float dens = 0.7;
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
void fragment() {
	float r = length(vQ);
	if (r > 1.0) { discard; }
	vec3 p = vW * 0.075 + vec3(TIME * 0.012, TIME * 0.004, TIME * 0.007);
	float n = wfbm3(p + vec3(wfbm3(p * 0.55 + 4.0)) * 0.9);
	float shape = smoothstep(1.0, 0.2, r);
	float d = shape * smoothstep(0.34, 0.74, n) * vI.z;
	// soft where the gas meets a hull or a rock (no hard cut lines)
	float dz = texture(depth_tex, SCREEN_UV).r;
	vec4 vv = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, dz, 1.0);
	float scene_d = -vv.z / vv.w;
	d *= clamp((scene_d + VERTEX.z) / 5.0, 0.0, 1.0);
	if (d <= 0.002) { discard; }
	// lit from the sun's side: the field thinner toward the sun means light gets in
	float n2 = wfbm3(p + normalize(sun_v) * 0.22 + vec3(wfbm3(p * 0.55 + 4.0)) * 0.9);
	float lit = clamp(0.5 + (n - n2) * 5.0, 0.0, 1.0);
	vec3 col = mix(c_dark, c_lit, lit);
	col += c_glow * pow(max(n - 0.56, 0.0), 1.4) * 2.2;
	float a = d * dens;
	if (storm > 0.5) {
		float ph = fract(TIME * (0.09 + vI.w * 0.06) + vI.w * 13.0);
		float fl = smoothstep(0.0, 0.01, ph) * smoothstep(0.07, 0.02, ph);
		col += bolt * fl * 0.7 * shape;
		for (int i = 0; i < 4; i++) {
			vec4 f = flashes[i];
			if (f.w > 0.001) {
				vec3 dd = vW - f.xyz;
				float g = exp(-dot(dd, dd) / 320.0) * f.w;
				col += bolt * g * 2.4;
				a += g * 0.25 * shape;
			}
		}
	}
	ALBEDO = col;
	ALPHA = clamp(a * gain_a, 0.0, 0.85);
}
"""

const BOLT_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
instance uniform float flash = 0.0;
uniform vec3 col = vec3(0.62, 0.74, 1.0);
varying vec4 vc;
void vertex() { vc = COLOR; }
void fragment() { ALBEDO = col * vc.a * flash * 2.6; }
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
	var per := 4 if low else 9
	var n_big := ps.size() / 2
	var mm := _quad_mm(ps.size() * per + n_big)
	var i := 0
	for p in ps:
		for k in per:
			var a := rng.randf() * TAU
			var rr := sqrt(rng.randf()) * 8.0
			# most of the gas low, round the ships' feet; a thin veil over them
			var y := lerpf(-4.5, 6.0, pow(rng.randf(), 1.6))
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, (p as Vector3) + Vector3(cos(a) * rr, y, sin(a) * rr)))
			mm.set_instance_custom_data(i, Color(rng.randf_range(8.0, 15.0), rng.randf(), rng.randf_range(0.65, 1.0), rng.randf()))
			i += 1
	# a few broad, thin puffs that tie the patch together
	for k in n_big:
		var p: Vector3 = ps[rng.randi() % ps.size()]
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p + Vector3(rng.randf_range(-4, 4), rng.randf_range(-3, 1), rng.randf_range(-4, 4))))
		mm.set_instance_custom_data(i, Color(rng.randf_range(20.0, 28.0), rng.randf(), rng.randf_range(0.3, 0.45), rng.randf()))
		i += 1
	var mi := MultiMeshInstance3D.new()
	mi.name = "Storm" if storm else "Nebula"
	mi.multimesh = mm
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = GAS_SHADER.replace("%NOISE%", WS.NOISE)
	m.shader = sh
	m.set_shader_parameter("sun_v", Vector3(0.45, 0.70, 0.55))   # world.gd SUN
	var g := 1.0
	if storm:
		# a dark, heavy mass (it must stand out from bright blue skies) that the lightning lights from inside
		m.set_shader_parameter("c_dark", Vector3(0.012, 0.014, 0.03))
		m.set_shader_parameter("c_lit", Vector3(0.10, 0.12, 0.24))
		m.set_shader_parameter("c_glow", Vector3(0.22, 0.3, 0.75))
		m.set_shader_parameter("storm", 1.0)
		m.set_shader_parameter("dens", 0.95)
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
		m.set_shader_parameter("c_glow", c2)
		m.set_shader_parameter("dens", 0.65)
	# drawn before the board's own fills, so a move hex inside the gas still shows on top
	m.render_priority = -5
	gas_mats.append([m, g])
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 30.0
	add_child(mi)


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
		_ribbon(st, path, 0.12, 1.3)
		for k in rng.randi_range(1, 2):
			var j := rng.randi_range(2, path.size() - 3)
			var from: Vector3 = path[j]
			var to := from + (z - a).normalized().rotated(Vector3.UP, rng.randf_range(-1.2, 1.2)) * rng.randf_range(3.0, 6.0) + Vector3(0, rng.randf_range(-2, 1), 0)
			_ribbon(st, _jag(from, to, 5, 0.12), 0.08, 0.9)
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = bm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.set_instance_shader_parameter("flash", 0.0)
		add_child(mi)
		var light: OmniLight3D = null
		if b < 4:
			light = OmniLight3D.new()
			light.light_color = Color(0.66, 0.76, 1.0)
			light.omni_range = 48.0
			light.omni_attenuation = 1.4
			light.shadow_enabled = false
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
			_quad(st, p0, p1, s * w_glow, 0.22, 0.0)


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
			(b["light"] as OmniLight3D).light_energy = v * 7.0
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
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.2, 0.19, 0.18)
	metal.metallic = 0.7
	metal.roughness = 0.5
	var hot := StandardMaterial3D.new()
	hot.albedo_color = Color(0.09, 0.08, 0.075)
	hot.metallic = 0.5
	hot.roughness = 0.6
	hot.emission_enabled = true
	hot.emission = Color(0.95, 0.36, 0.1)
	hot.emission_energy_multiplier = 0.7
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
		for i in rng.randi_range(3, 6):
			var a := rng.randf() * TAU
			var rr := sqrt(rng.randf()) * 7.5
			var mk := rng.randi() % shard_meshes.size()
			var mt := 1 if rng.randf() < 0.22 else 0
			var key := "%d|%d" % [mk, mt]
			if not shards.has(key):
				shards[key] = []
			var b := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)).scaled(Vector3.ONE * rng.randf_range(1.4, 3.4))
			shards[key].append(Transform3D(b, (p as Vector3) + Vector3(cos(a) * rr, rng.randf_range(-2.5, 3.5), sin(a) * rr)))
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


# three kinds of broken hull: a bent plate, a girder (an I-beam with a strut), a ribbed panel; about a unit across
func _shard_meshes() -> Array:
	var out: Array = []
	var specs := [
		[[Vector3(1.0, 0.06, 0.62), Transform3D.IDENTITY], [Vector3(0.62, 0.06, 0.62), Transform3D(Basis(Vector3.BACK, 0.6), Vector3(0.75, 0.17, 0))]],
		[[Vector3(1.7, 0.26, 0.05), Transform3D.IDENTITY], [Vector3(1.7, 0.035, 0.2), Transform3D(Basis(), Vector3(0, 0.13, 0))],
			[Vector3(1.7, 0.035, 0.2), Transform3D(Basis(), Vector3(0, -0.13, 0))], [Vector3(0.05, 0.05, 0.7), Transform3D(Basis(Vector3.UP, 0.7), Vector3(0.5, 0.0, 0.2))]],
		[[Vector3(0.95, 0.04, 0.9), Transform3D.IDENTITY], [Vector3(0.06, 0.13, 0.9), Transform3D(Basis(), Vector3(-0.3, 0.07, 0))],
			[Vector3(0.06, 0.13, 0.9), Transform3D(Basis(), Vector3(0.0, 0.07, 0))], [Vector3(0.06, 0.13, 0.7), Transform3D(Basis(), Vector3(0.3, 0.07, -0.1))]],
	]
	for sp in specs:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part in sp:
			var bx := BoxMesh.new()
			bx.size = part[0]
			st.append_from(bx, 0, part[1])
		st.generate_normals()
		out.append(st.commit())
	return out


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
