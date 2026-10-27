extends Node3D
# The battle world (G4, API in godot/fx/API.md section 9): sky and nebula per enemy faction, one backdrop planet at most,
# the dead star with gravitational lensing and an accretion disc (R2, R24: the board stays; the paintings are only mood,
# R25), faceted asteroid blockers on rock hexes, sparse dressing off the board, debris and nebula hexes.
#
# BACKLOG section 3 oddities, and how this build avoids them: rocks never sit in front of the planet (dressing keeps out
# of its direction); never two identical moons (one planet, chosen per battle); no "distant traffic" ships at all; no rim
# wall (the board edge gets a sparse scatter of separate rocks below the board plane, not a slab).

const WS := preload("res://world/world_shaders.gd")

# nebula colours per enemy faction (the browser game's BIOMES, scene3d.js) come from the faction look data
# (fx/faction_looks.json, field nebula)
const FLOOK := preload("res://fx/faction_look.gd")
# rock kinds (battle.js ROCK_KINDS): base albedo (linear), shader kind
const ROCKS := {
	# r10: darker, warmer regolith (real asteroids are dark; r9's lighter values read as pale cream under the key light,
	# where G3's map rocks are dark brown)
	"stone": [Vector3(0.085, 0.068, 0.055), 0], "ice": [Vector3(0.2, 0.24, 0.29), 1], "iron": [Vector3(0.11, 0.09, 0.078), 2],
	"carbon": [Vector3(0.045, 0.04, 0.036), 3], "crystal": [Vector3(0.075, 0.085, 0.085), 4],
}
# backdrop planets (biome.planet 0..7): [colour a, colour b, atmosphere, gas giant]
const PLANETS := [
	[Vector3(0.55, 0.42, 0.3), Vector3(0.25, 0.17, 0.12), Vector3(0.9, 0.6, 0.35), 1.0],
	[Vector3(0.3, 0.45, 0.6), Vector3(0.12, 0.2, 0.32), Vector3(0.4, 0.65, 1.0), 1.0],
	[Vector3(0.45, 0.35, 0.55), Vector3(0.18, 0.12, 0.25), Vector3(0.7, 0.5, 1.0), 1.0],
	[Vector3(0.25, 0.4, 0.22), Vector3(0.12, 0.18, 0.3), Vector3(0.45, 0.7, 1.0), 0.0],
	[Vector3(0.5, 0.3, 0.2), Vector3(0.22, 0.12, 0.08), Vector3(1.0, 0.5, 0.3), 0.0],
	[Vector3(0.35, 0.33, 0.32), Vector3(0.15, 0.14, 0.14), Vector3(0.6, 0.6, 0.7), 0.0],
	[Vector3(0.6, 0.6, 0.65), Vector3(0.3, 0.35, 0.45), Vector3(0.6, 0.8, 1.0), 0.0],
	[Vector3(0.2, 0.5, 0.45), Vector3(0.08, 0.2, 0.25), Vector3(0.3, 1.0, 0.8), 1.0],
]

var quality := "max"
var notes: PackedStringArray = []
var _spin: Array = []        # [node, axis, rate]
var _well := Vector3.INF
var _rng := RandomNumberGenerator.new()
var _mesh_lib := {}
var _planet_dir := Vector3.ZERO
var disc_tilt := -12.0       # degrees; the board view looks down about 55 degrees, so a small tilt reads


func well_position() -> Vector3:
	return _well


func _process(delta: float) -> void:
	pass


func step(dt: float) -> void:
	for s in _spin:
		var n: Node3D = s[0]
		if is_instance_valid(n):
			n.rotate(s[1], float(s[2]) * dt)


# ---------------------------------------------------------------- battle build (API.md 9)

func build(view: Dictionary, opts: Dictionary) -> void:
	quality = String(opts.get("quality", "max"))
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		quality = "low"
	var biome: Dictionary = opts.get("biome", {})
	var fac := String(opts.get("fac", "voidsworn"))
	var hw: Callable = opts["hex_world"]
	_rng.seed = int(opts.get("seed", hash(str(view.get("round", 0)) + fac)))
	var env: Environment = opts.get("environment", null)
	if env != null:
		sky(env, fac, opts.get("pano", null), int(_rng.randi()))
	var rock_kind := String(biome.get("rock", "stone"))
	var map: Dictionary = view.get("map", {})
	var terrain: Dictionary = view.get("terrain", {})
	# board bounds from the hexes in play
	var lo := Vector3(1e9, 0, 1e9)
	var hi := Vector3(-1e9, 0, -1e9)
	for k in terrain.keys():
		var qr := String(k).split(",")
		var p: Vector3 = hw.call(int(qr[0]), int(qr[1]))
		lo = lo.min(p)
		hi = hi.max(p)
	for u in view.get("units", []):
		var p: Vector3 = hw.call(int(u["q"]), int(u["r"]))
		lo = lo.min(p)
		hi = hi.max(p)
	if lo.x > hi.x:
		lo = Vector3(-150, 0, -100)
		hi = Vector3(150, 0, 100)
	var center := (lo + hi) * 0.5
	if biome.has("planet") and not map.has("deadstar"):
		planet(int(biome["planet"]), center)
	if map.has("deadstar") and map["deadstar"] != null:
		var ds: Dictionary = map["deadstar"]
		dead_star(hw.call(int(ds["q"]), int(ds["r"])) + Vector3(0, -10, 0), 1.0)
		if opts.has("fx") and opts["fx"] != null:
			opts["fx"].well = _well
	for k in terrain.keys():
		var qr := String(k).split(",")
		var p: Vector3 = hw.call(int(qr[0]), int(qr[1]))
		match String(terrain[k]):
			"rock": blocker(p, rock_kind)
			"debris": debris_field(p, rock_kind)
			"neb": nebula_hex(p, fac)
	dressing(lo, hi, rock_kind, 70)


func build_gallery(env: Environment, cam: Camera3D, opts: Dictionary) -> void:
	quality = String(opts.get("quality", "max"))
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		quality = "low"
	_rng.seed = 7
	sky(env, "corsair", null, 3)
	disc_tilt = -24.0
	dead_star(opts.get("deadstar", Vector3(0, -20, -150)), 1.0)
	for i in 3:
		blocker(Vector3(-40 + i * 70, -2, -95 + (i % 2) * 20), ["stone", "ice", "crystal"][i])
	dressing(Vector3(-120, 0, -70), Vector3(120, 0, 70), "carbon", 40)


# ---------------------------------------------------------------- sky and planet

func sky(env: Environment, fac: String, pano: Texture2D, seed_v: int) -> void:
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = WS.SKY
	m.shader = sh
	var b: Array = FLOOK.of(fac).get("nebula", FLOOK.of("voidsworn")["nebula"])
	m.set_shader_parameter("c1", b[0])
	m.set_shader_parameter("c2", b[1])
	m.set_shader_parameter("c3", b[2])
	m.set_shader_parameter("seed", float(seed_v % 97))
	if pano == null and env.sky != null and env.sky.sky_material is PanoramaSkyMaterial:
		pano = (env.sky.sky_material as PanoramaSkyMaterial).panorama
	if pano == null and env.sky != null and env.sky.sky_material is ShaderMaterial:
		var t = (env.sky.sky_material as ShaderMaterial).get_shader_parameter("pano")
		if t is Texture2D:
			pano = t
	if pano != null:
		m.set_shader_parameter("pano", pano)
		m.set_shader_parameter("has_pano", 1.0)
	m.set_shader_parameter("sun_dir", Vector3(0.45, 0.70, 0.55).normalized())
	var s := Sky.new()
	s.sky_material = m
	s.radiance_size = Sky.RADIANCE_SIZE_256
	s.process_mode = Sky.PROCESS_MODE_QUALITY
	env.sky = s
	env.background_mode = Environment.BG_SKY
	notes.append("sky: nebula tinted for %s%s" % [fac, ", over the painted starfield" if pano != null else ""])


func planet(idx: int, center: Vector3) -> void:
	var pp: Array = PLANETS[posmod(idx, PLANETS.size())]
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 96
	sm.rings = 48
	mi.mesh = sm
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = WS.PLANET
	m.shader = sh
	m.set_shader_parameter("col_a", pp[0])
	m.set_shader_parameter("col_b", pp[1])
	m.set_shader_parameter("atmo", pp[2])
	m.set_shader_parameter("gas", pp[3])
	m.set_shader_parameter("seed", float(idx) * 3.7)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# behind the battle and a little above the board plane: the board camera looks down through the transparent board,
	# so a planet below the plane showed as a huge disc right under the fleet (G2, scenario s3)
	_planet_dir = Vector3(-0.42, 0.16, -0.89).normalized()
	mi.position = center + _planet_dir * 2400.0
	mi.scale = Vector3.ONE * 520.0
	add_child(mi)
	_spin.append([mi, Vector3.UP, 0.004])


# ---------------------------------------------------------------- the dead star

func dead_star(c: Vector3, s: float) -> void:
	_well = c
	var root := Node3D.new()
	root.name = "DeadStar"
	root.position = c
	add_child(root)
	var Rsh := 15.0 * s
	# the black core (writes depth: ships behind it are hidden, as they would be)
	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = Rsh
	sm.height = Rsh * 2.0
	core.mesh = sm
	var cm := StandardMaterial3D.new()
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.albedo_color = Color.BLACK
	core.material_override = cm
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(core)
	# the accretion disc, tilted, turning (opaque where dense, so the lens bends its far side over the shadow)
	var tilt := Node3D.new()
	tilt.rotation = Vector3(deg_to_rad(disc_tilt), 0.0, deg_to_rad(6.0))
	root.add_child(tilt)
	var disc := MeshInstance3D.new()
	disc.mesh = _annulus(Rsh * 1.2, Rsh * 3.8, 192, 16)
	var dm := ShaderMaterial.new()
	var dsh := Shader.new()
	dsh.code = WS.DISC
	dm.shader = dsh
	dm.set_shader_parameter("r_in", Rsh * 1.2)
	dm.set_shader_parameter("r_out", Rsh * 3.8)
	dm.set_shader_parameter("spin", 0.35)
	dm.set_shader_parameter("gain", 1.0)
	disc.material_override = dm
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tilt.add_child(disc)
	# the lens over everything behind the hole (max and high)
	if quality != "low":
		var lens := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1, 1)
		lens.mesh = qm
		var lm := ShaderMaterial.new()
		var lsh := Shader.new()
		lsh.code = WS.LENS
		lm.shader = lsh
		var half := Rsh * 5.0
		lm.set_shader_parameter("r_shadow", Rsh * 1.0 / half)
		lm.set_shader_parameter("r_einstein", Rsh * 1.6 / half)
		# the disc's lensed arcs and Doppler beaming are drawn in the lens (matching G3's map); it needs the disc's frame
		lm.set_shader_parameter("disc_basis", tilt.global_transform.basis.orthonormalized() if tilt.is_inside_tree() else Basis.from_euler(tilt.rotation))
		lm.set_shader_parameter("disc_r_mid", Rsh * 2.2)
		lm.set_shader_parameter("disc_reach", Rsh * 4.2)
		lm.set_shader_parameter("spin", 0.35)
		lm.render_priority = -30   # drawn first among the see-through things: it copies the opaque picture, so later effects (beams, trails in front of it) draw over it, not under it
		lens.material_override = lm
		lens.scale = Vector3.ONE * half
		lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lens.extra_cull_margin = half * 4.0
		root.add_child(lens)
	# the disc's warm light (the lit gas): an omni light, no shadows. r10 lighting pass: it reaches further and falls off
	# more steeply, so ships near the well take a warm side light from the disc (the rocks' rim matches it) while the
	# far side of the board keeps the plain key light
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.3)
	l.light_energy = 1.6
	l.omni_range = Rsh * 14.0
	l.omni_attenuation = 1.6
	l.shadow_enabled = false
	root.add_child(l)
	notes.append("dead star: core, lensing %s, accretion disc" % ("on" if quality != "low" else "off"))


func _annulus(r0: float, r1: float, seg: int, rings: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in rings:
		var a0 := r0 + (r1 - r0) * float(j) / rings
		var a1 := r0 + (r1 - r0) * float(j + 1) / rings
		for i in seg:
			var t0 := TAU * i / seg
			var t1 := TAU * (i + 1) / seg
			var p00 := Vector3(cos(t0) * a0, 0, sin(t0) * a0)
			var p01 := Vector3(cos(t1) * a0, 0, sin(t1) * a0)
			var p10 := Vector3(cos(t0) * a1, 0, sin(t0) * a1)
			var p11 := Vector3(cos(t1) * a1, 0, sin(t1) * a1)
			for v in [p00, p10, p11, p00, p11, p01]:
				st.set_normal(Vector3.UP)
				st.add_vertex(v)
	return st.commit()


# ---------------------------------------------------------------- asteroids

# An asteroid like G3's campaign map rocks (map3d_props.gd, r8, Opus: battle rocks must match the map): a fine
# icosphere pushed by layered noise into a lumpy, elongated body, pocked by impact craters with bowls and raised rims,
# shaded smooth. COLOR.r carries the crater depth (darker, dustier floors in the shader), COLOR.g the rim (brighter,
# worn). r6-r7 cut flat fracture planes into it, which read as grey low-poly faceted lumps on the board.
func rock_mesh(r: RandomNumberGenerator, elong: Vector3, sub: int) -> ArrayMesh:
	var verts: Array = []
	var t := (1.0 + sqrt(5.0)) / 2.0
	for v in [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0), Vector3(0, -1, t), Vector3(0, 1, t),
			Vector3(0, -1, -t), Vector3(0, 1, -t), Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]:
		verts.append(v.normalized())
	var faces := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	for it in sub:
		var mid := {}
		var nf: Array = []
		for f in faces:
			var m := []
			for e in 3:
				var a: int = f[e]
				var b: int = f[(e + 1) % 3]
				var key := Vector2i(mini(a, b), maxi(a, b))
				if not mid.has(key):
					verts.append(((verts[a] as Vector3) + (verts[b] as Vector3)).normalized())
					mid[key] = verts.size() - 1
				m.append(mid[key])
			nf.append([f[0], m[0], m[2]])
			nf.append([f[1], m[1], m[0]])
			nf.append([f[2], m[2], m[1]])
			nf.append([m[0], m[1], m[2]])
		faces = nf
	var nz := FastNoiseLite.new()
	nz.seed = r.randi()
	nz.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	nz.frequency = 1.1
	nz.fractal_type = FastNoiseLite.FRACTAL_FBM
	nz.fractal_octaves = 5
	var craters: Array = []
	for c in r.randi_range(5, 11):
		craters.append([Vector3(r.randfn(), r.randfn(), r.randfn()).normalized(), r.randf_range(0.18, 0.5), r.randf_range(0.05, 0.14)])
	# a couple of small fresh craters too, for scale
	for c in r.randi_range(4, 8):
		craters.append([Vector3(r.randfn(), r.randfn(), r.randfn()).normalized(), r.randf_range(0.07, 0.14), r.randf_range(0.02, 0.04)])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v0 in verts:
		var v: Vector3 = v0
		var k := 1.0 + nz.get_noise_3dv(v * 1.3) * 0.32 + nz.get_noise_3dv(v * 4.0 + Vector3(9, 1, 3)) * 0.07
		var dep := 0.0
		var rim := 0.0
		for cr in craters:
			var u: float = acos(clampf(v.dot(cr[0]), -1.0, 1.0)) / float(cr[1])
			if u < 1.35:
				var bowl := (1.0 - u * u) if u < 1.0 else 0.0
				var rr := exp(-pow((u - 1.0) / 0.18, 2.0))
				k += (-bowl + rr * 0.22) * float(cr[2])
				dep = maxf(dep, bowl)
				rim = maxf(rim, rr)
		st.set_color(Color(dep, rim, 0.0))
		st.add_vertex(v * k * elong)
	for f in faces:
		st.add_index(f[0])
		st.add_index(f[2])
		st.add_index(f[1])
	st.generate_normals()
	return st.commit()


func _rock_mat(kind: String, seed_v: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	var sh: Shader = _mesh_lib.get("rock_shader")
	if sh == null:
		sh = Shader.new()
		sh.code = WS.ROCK
		_mesh_lib["rock_shader"] = sh
	m.shader = sh
	var rk: Array = ROCKS.get(kind, ROCKS["stone"])
	m.set_shader_parameter("base", rk[0])
	m.set_shader_parameter("kind", rk[1])
	m.set_shader_parameter("seed", seed_v)
	m.set_shader_parameter("q", 1.0 if quality == "max" else 0.0)
	# the dead star's disc rims the rocks near it in its own warm light (r8)
	if _well != Vector3.INF:
		m.set_shader_parameter("rim_pos", _well)
		m.set_shader_parameter("rim_k", 1.6)
	return m


func _lib(kind: String) -> Array:
	if _mesh_lib.has(kind):
		return _mesh_lib[kind]
	var r := RandomNumberGenerator.new()
	r.seed = hash(kind) + 11
	var out: Array = []
	for i in 10:
		var el := Vector3(r.randf_range(0.75, 1.45), r.randf_range(0.6, 1.0), r.randf_range(0.75, 1.15))
		out.append(rock_mesh(r, el, 4 if quality == "max" else 3))
	_mesh_lib[kind] = out
	return out


# A blocker on a rock hex: a tall, sharp main rock with smaller fragments round its foot, clearly an obstacle.
func blocker(p: Vector3, kind: String) -> void:
	var lib := _lib(kind)
	var root := Node3D.new()
	root.name = "Blocker"
	root.position = p
	add_child(root)
	var main := MeshInstance3D.new()
	main.mesh = lib[_rng.randi() % lib.size()]
	main.material_override = _rock_mat(kind, _rng.randf() * 10.0)
	var h := _rng.randf_range(7.0, 10.0)
	main.scale = Vector3(_rng.randf_range(5.0, 6.5), h, _rng.randf_range(5.0, 6.5))
	main.rotation = Vector3(_rng.randf_range(-0.25, 0.25), _rng.randf() * TAU, _rng.randf_range(-0.25, 0.25))
	main.position = Vector3(0, h * 0.35, 0)
	root.add_child(main)
	for i in _rng.randi_range(2, 4):
		var f := MeshInstance3D.new()
		f.mesh = lib[_rng.randi() % lib.size()]
		f.material_override = main.material_override
		var s := _rng.randf_range(1.4, 3.0)
		f.scale = Vector3.ONE * s
		var a := _rng.randf() * TAU
		f.position = Vector3(cos(a) * 6.5, _rng.randf_range(-1.0, 2.0), sin(a) * 6.5)
		f.rotation = Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU)
		root.add_child(f)
		_spin.append([f, Vector3(_rng.randf(), _rng.randf(), _rng.randf()).normalized(), _rng.randf_range(0.02, 0.08)])
	if kind == "crystal":
		for i in 4:
			var cr := MeshInstance3D.new()
			var pm := PrismMesh.new()
			pm.size = Vector3(1.2, _rng.randf_range(4.0, 8.0), 1.2)
			cr.mesh = pm
			var cm := ShaderMaterial.new()
			var csh := Shader.new()
			csh.code = WS.CRYSTAL
			cm.shader = csh
			cr.material_override = cm
			var a := _rng.randf() * TAU
			cr.position = Vector3(cos(a) * 3.0, h * 0.6, sin(a) * 3.0)
			cr.rotation = Vector3(_rng.randf_range(-0.6, 0.6), a, _rng.randf_range(-0.6, 0.6))
			root.add_child(cr)


func debris_field(p: Vector3, kind: String) -> void:
	var lib := _lib(kind)
	var mat := _rock_mat(kind, _rng.randf() * 10.0)
	for i in 6:
		var m := MeshInstance3D.new()
		m.mesh = lib[_rng.randi() % lib.size()]
		m.material_override = mat
		m.scale = Vector3.ONE * _rng.randf_range(0.5, 1.4)
		m.position = p + Vector3(_rng.randf_range(-7, 7), _rng.randf_range(-3, 2), _rng.randf_range(-7, 7))
		add_child(m)
		_spin.append([m, Vector3(_rng.randf(), _rng.randf(), _rng.randf()).normalized(), _rng.randf_range(0.05, 0.3)])


func nebula_hex(p: Vector3, fac: String) -> void:
	# a soft glowing cloud: a few large additive sprites (cheap), tinted by the sector's nebula colours
	var b: Array = FLOOK.of(fac).get("nebula", FLOOK.of("voidsworn")["nebula"])
	for i in 5:
		var s := Sprite3D.new()
		s.texture = _soft_tex()
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.shaded = false
		s.transparent = true
		var c: Vector3 = b[i % 2]
		s.modulate = Color(c.x, c.y, c.z, 0.18)
		s.pixel_size = _rng.randf_range(10.0, 16.0) / 64.0
		s.position = p + Vector3(_rng.randf_range(-5, 5), _rng.randf_range(-2, 3), _rng.randf_range(-5, 5))
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(s)


var _soft: Texture2D = null


func _soft_tex() -> Texture2D:
	if _soft != null:
		return _soft
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5).length() / 31.5
			img.set_pixel(x, y, Color(1, 1, 1, clampf(exp(-d * d * 3.0) - 0.05, 0.0, 1.0)))
	_soft = ImageTexture.create_from_image(img)
	return _soft


# Sparse rocks round the board, below its plane, never in front of the planet, never a wall.
func dressing(lo: Vector3, hi: Vector3, kind: String, n: int) -> void:
	var lib := _lib(kind)
	var mats: Array = []
	for i in 3:
		mats.append(_rock_mat(kind, float(i) * 3.3))
	var groups := {}
	var c := (lo + hi) * 0.5
	var ext := (hi - lo) * 0.5 + Vector3(40, 0, 40)
	var placed := 0
	var tries := 0
	while placed < n and tries < n * 6:
		tries += 1
		var a := _rng.randf() * TAU
		var rr := _rng.randf_range(1.0, 1.9)
		var p := c + Vector3(cos(a) * ext.x * rr, _rng.randf_range(-70.0, -18.0), sin(a) * ext.z * rr)
		if _planet_dir != Vector3.ZERO and (p - c).normalized().dot(_planet_dir) > 0.8:
			continue
		if _well != Vector3.INF and p.distance_to(_well) < 80.0:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = lib[_rng.randi() % lib.size()]
		mi.material_override = mats[placed % 3]
		mi.scale = Vector3.ONE * _rng.randf_range(1.0, 5.0) * (1.0 + 2.0 * pow(_rng.randf(), 4.0))
		mi.position = p
		mi.rotation = Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU)
		add_child(mi)
		_spin.append([mi, Vector3(_rng.randf(), _rng.randf(), _rng.randf()).normalized(), _rng.randf_range(0.01, 0.06)])
		placed += 1
	notes.append("world: %d dressing rocks (%s)" % [placed, kind])
