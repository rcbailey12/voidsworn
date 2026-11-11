extends RefCounted
# Ship deaths, drifting wrecks and the physics behind them, plus the shared hull decorations (scorch decals, breach
# holes, bent plates, venting plumes, debris bodies). Static functions; the state lives in fx.dstate.
#
# Four death beats: power loss, directional vent, staged cuts, drift and cooling.
# Mantaflow flipbooks replace fire volumes. Small hulls have a short pop, no ribbon.
# Triangle buckets and recessed boundary caps are prepared on a worker before death;
# the wrecks drift, tumble and cool. No worker wait blocks a death frame.

const SH := preload("res://fx/fx_shaders.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const HULL := preload("res://fx/fx_hull.gd")

const HULL_LAYER := 1
const DEBRIS_LAYER := 2
const DEBRIS_CAP := 360
const DEBRIS_VARIANTS := 4
const WRECK_COOL := 14.0

# Issue 462 (docs/playbooks/deaths_and_hits.md, "A death in three beats"): times are seconds from the killing blow.
# A cruiser: the tell to 1.38 (lights die, engines flare and go black, a tear opens from the hit side with three chain
# blasts walking along it), the break at 1.38, the core flash 0.28 later at the torn face, then ten secondaries on the
# two halves and cooling faces. A capital: the tell to 2.0 with five chain blasts and a shudder, three pieces, a bigger
# core, ten secondaries and 14 s of coals. Small hulls keep their short pop (issue 366c).
class DeathTimeline:
	var vent: float
	var cut: float
	var end: float
	var cuts: int
	var spacing: float
	var beats: Array
	var tier := ""
	var chain: Array = []     # chain blast times along the tear
	var tear_open := 0.3
	var tear_full := 0.0
	var core_delay := 0.0     # the core flash, after the break
	var secondaries := 0
	var sec_from := 0.0       # the secondaries' window, after the break
	var sec_to := 0.0
	var cool := 14.0          # how long the torn faces take to go dark
	func _init(big: bool, cut_count: int, tier_name := "", cause := "blast") -> void:
		tier = tier_name if big else ""
		cuts = cut_count if big else 1
		if not big:
			vent = 0.12
			cut = 0.55
			end = 1.15
			spacing = 0.0
		elif tier == "capital":
			vent = 0.46
			cut = 2.0
			chain = [0.5, 0.85, 1.2, 1.55, 1.9]
			spacing = 0.30
			core_delay = 0.28
			secondaries = 10
			sec_from = 0.75
			sec_to = 4.2
			cool = 14.0
		else:
			vent = 0.46
			cut = 1.38
			chain = [0.5, 0.8, 1.1]
			spacing = 0.0
			core_delay = 0.28
			secondaries = 10
			sec_from = 0.72
			sec_to = 3.52
			cool = 8.6
		if big:
			end = cut + 0.67
			# A lance cut: the tear is the beam's straight line, drawn fast; its faces glow longest.
			tear_full = 0.62 if cause == "cut" else cut - 0.05
			if cause == "cut": cool *= 1.4
		beats = [{"name": "power_loss", "at": 0.0}, {"name": "vent", "at": vent}]
		for t in chain: beats.append({"name": "chain_blast", "at": t})
		beats.append({"name": "structural_break", "at": cut})
		if big:
			beats.append({"name": "core_flash", "at": cut + core_delay})
			beats.append({"name": "secondaries", "at": cut + sec_from})
		beats.append({"name": "drift_and_cool", "at": cut + (sec_from if big else 0.3)})

const ATLAS_DIR := "res://fx/atlases/death/"
# One pixel at the staging camera (r 170, vertical FOV 45, 1080 lines). The floor holds distant events readable;
# the world extent lets them grow naturally as the player zooms in.
const STAGING_UNITS_PER_PIXEL := 2.0 * 170.0 * tan(PI / 8.0) / 1080.0

# Issue 354: where the visible gas starts inside the baked vent picture. Measured on today's pictures
# (godot/fx/atlases/death/{small,cruiser,capital}/vent_color.png): in frame 0 the gas runs down to row 0.90 of the crop,
# and the crop is rows 0.40 to 0.84 of the cell, so its lower edge (the root the gas vents from) sits 0.40 of the crop
# height from the picture centre. The directional flip puts that lower edge at the +up end of the quad, so a picture
# whose root is on the plating has its centre 0.40 of its height along the surface normal from that plating. The old
# fixed share of the ship's length (0.42 of 0.85 L) offset the picture centre, and the gas root was another 0.40 of the
# picture height further out, so the gas floated off the hull. P3-16 (issue 365) rebakes these pictures and must redo
# this number.
const VENT_ROOT_FRAC := 0.40

const SLAG := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
global uniform float fx_gain;
uniform float heat = 1.0;
uniform bool organic = false;
uniform float section_scale = 1.0;
uniform float face_glow = 0.0;
varying vec3 slag_p;
varying vec2 slag_band;
void vertex() { slag_p = VERTEX; slag_band = COLOR.rg; }
float grain(vec3 p) { return fract(sin(dot(floor(p), vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
void fragment() {
	vec3 p = slag_p / max(section_scale, 0.001);
	float n = grain(p * 160.0);
	float coarse = 0.5 + 0.25 * sin(dot(p, vec3(38.7, 13.1, 26.3))) * sin(dot(p, vec3(12.3, 52.1, 24.7)));
	float band = clamp(slag_band.x, 0.0, 1.0);
	bool rib = band > 0.4 && band < 0.6;
	vec3 base = mix(vec3(0.045, 0.032, 0.026), vec3(0.014, 0.011, 0.012), band);
	if (rib) { base = vec3(0.068, 0.056, 0.048); }
	if (organic) {
		float fibre = pow(abs(sin(dot(p, vec3(41.0, 67.0, 29.0)) + coarse * 8.0)), 6.0);
		base = mix(vec3(0.025, 0.005, 0.013), vec3(0.085, 0.018, 0.031), coarse * 0.7 + fibre * 0.3);
		if (rib) { base = vec3(0.20, 0.15, 0.085) * (0.65 + coarse * 0.35); }
	}
	base *= 0.65 + coarse * 0.55 + n * 0.2;
	float rim = clamp(slag_band.y, 0.0, 1.0) * smoothstep(0.25, 0.75, n);
	float hot = clamp(heat, 0.0, 1.0);
	float temperature = hot * hot;
	vec3 metal = mix(vec3(0.38, 0.035, 0.018), vec3(0.95, 0.40, 0.09), smoothstep(0.2, 0.65, temperature));
	metal = mix(metal, vec3(0.94, 0.84, 0.64), smoothstep(0.65, 1.0, temperature));
	// Issue 462: with face_glow on (a big hull's death) the torn face glows as it cools: white, orange, dull red, dark.
	// Issue 484 (the Board, Nov 11: a capital's middle piece showed a big flat tan grid face, a clean slab again): the face
	// is charred black and the heat sits in its cracks and seams, never as an even bright panel.
	float vein = pow(1.0 - abs(sin(dot(p, vec3(23.1, 9.7, 17.3)) + coarse * 7.0)), 10.0)
		+ pow(1.0 - abs(sin(dot(p, vec3(-7.9, 29.3, 11.1)) + n * 1.5)), 14.0) * 0.6;
	float face = face_glow * (rib ? 0.45 : vein * 1.4) * smoothstep(0.0, 0.08, temperature);
	ALBEDO = base + (organic ? vec3(0.0) : metal * (rim * 3.2 + face) * temperature * fx_gain);
}
"""

const DEBRIS_BODY := """
shader_type spatial;
render_mode cull_disabled;
global uniform float scene_t;
global uniform float fx_gain;
instance uniform float spawn_t = -100.0;
varying vec3 lp;
float eh(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float en(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(eh(i), eh(i + vec3(1.0, 0.0, 0.0)), f.x), mix(eh(i + vec3(0.0, 1.0, 0.0)), eh(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(eh(i + vec3(0.0, 0.0, 1.0)), eh(i + vec3(1.0, 0.0, 1.0)), f.x), mix(eh(i + vec3(0.0, 1.0, 1.0)), eh(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}
varying float rim;
void vertex() { lp = VERTEX; rim = COLOR.r; }
void fragment() {
	// torn plate: sooty bare metal with a little grain; only parts of its torn rim glow, briefly (r3 verdict: no ember
	// speckle over the whole face; r5: a rim glowing all the way round outlined every plate like a cartoon, and a
	// mirror-smooth face caught the sky, so the glow now breaks along the edge and the face is rough and sooty)
	float g = en(lp * 9.0);
	float soot = smoothstep(0.3, 0.7, en(lp * 3.0 + 7.0));
	ALBEDO = mix(vec3(0.11, 0.105, 0.1), vec3(0.025, 0.023, 0.021), soot) * (0.8 + 0.4 * g);
	METALLIC = mix(0.5, 0.2, soot);
	ROUGHNESS = mix(0.62, 0.92, soot);
	float warm = exp(-max(scene_t - spawn_t, 0.0) / 0.55);
	float seg = smoothstep(0.5, 0.7, en(lp * 5.0 + 3.0));
	float edge = smoothstep(0.85, 1.0, rim) * seg * (0.6 + 0.4 * g);
	EMISSION = vec3(1.0, 0.34, 0.05) * edge * warm * 1.3 * fx_gain;
}
"""


# ---------------------------------------------------------------- setup

static func setup_physics(fx) -> void:
	var st: Dictionary = fx.dstate
	st["bounce"] = PhysicsMaterial.new()
	(st["bounce"] as PhysicsMaterial).bounce = 0.4
	(st["bounce"] as PhysicsMaterial).friction = 0.4
	var sh = Shader.new()
	sh.code = DEBRIS_BODY
	var m = ShaderMaterial.new()
	m.shader = sh
	st["debris_mat"] = m
	# Issue 462: the tear's shader is made here, at battle load, not on the first death frame (a 63 ms first death on
	# the fleet probe before this).
	st["tear_mat"] = fx.mat(SH.TEAR, 1)
	st["debris_shapes"] = []
	st["debris_meshes"] = []
	var r = RandomNumberGenerator.new()
	r.seed = 77
	# three sizes, four torn shapes each (r5: three meshes in all made every plate the same hexagon)
	for sz in [0.45, 0.8, 1.2]:
		var shapes: Array = []
		var meshes: Array = []
		for v in DEBRIS_VARIANTS:
			var sm = shard_mesh(r, sz)
			shapes.append(safe_convex(sm[1]))
			meshes.append(sm[0])
		st["debris_shapes"].append(shapes)
		st["debris_meshes"].append(meshes)
	st["debris"] = []
	st["debris_next"] = 0
	st["wrecks"] = []
	st["physics_on"] = fx.quality != "low"


# ---------------------------------------------------------------- hull decorations

static func atlas_band(length: float) -> String:
	return "small" if length < 18.0 else ("cruiser" if length < 30.0 else "capital")


# Load once per FX session. No image decode or shader compilation on a death frame.
static func flipbook_material(fx, kind: String, band := "capital") -> ShaderMaterial:
	var rel := "death/" + band + "/" + kind + "_"
	if route_texture(fx, rel + "color.png") != null:
		return route_material(fx, SH.DEATH_FLIPBOOK, rel)
	var m: ShaderMaterial = fx.mat(SH.DEATH_FLIPBOOK, 2, "#define COMPAT\n" if fx.compat else "")
	for key in ["color", "flow", "thickness"]:
		var path: String = ATLAS_DIR + band + "/" + kind + "_" + key + ".png"
		var textures: Dictionary = fx.dstate.get("death_atlases", {})
		if not textures.has(path): textures[path] = load(path)
		fx.dstate["death_atlases"] = textures
		m.set_shader_parameter({"color": "atlas", "flow": "motion", "thickness": "thickness"}[key], textures[path])
	return m


# Production seeds load imported resources. The optional comparison folder loads external PNGs and returns null
# for missing kinds. Production callers never depend on VS_FX_ATLAS.
static func route_texture(fx, rel: String, seed_index := -1) -> Texture2D:
	if seed_index >= 0:
		var path := "res://fx/atlases/rebake/s%d/" % seed_index + rel
		var textures: Dictionary = fx.dstate.get("production_atlases", {})
		if not textures.has(path): textures[path] = load(path)
		fx.dstate["production_atlases"] = textures
		return textures[path]
	if String(fx.fx_atlas) == "":
		return null
	var path := String(fx.fx_atlas).path_join(rel)
	var cache: Dictionary = fx.dstate.get("route_atlases", {})
	if not cache.has(path):
		var img: Image = Image.load_from_file(path) if FileAccess.file_exists(path) else null
		cache[path] = ImageTexture.create_from_image(img) if img != null else null
		fx.dstate["route_atlases"] = cache
	return cache[path]


# Three maps with baked colour and heat. The meta tells callers to sample the whole cell and keep the shader define.
static func route_material(fx, code: String, rel: String, production := false, seed_index := -1) -> ShaderMaterial:
	var m: ShaderMaterial = fx.mat(code, 2, ("#define COMPAT\n" if fx.compat else "") + "#define ROUTE_BAKED\n")
	if production and seed_index < 0: seed_index = fx.rng.randi_range(0, 2)
	for key in ["color", "flow", "thickness"]:
		m.set_shader_parameter({"color": "atlas", "flow": "motion", "thickness": "thickness"}[key], route_texture(fx, rel + key + ".png", seed_index))
	m.set_meta("route", true)
	return m


static func flipbook(fx, p: Vector3, n: Vector3, size: float, kind: String, life: float, velocity := Vector3.ZERO, strength := 1.0, band := "capital", src = null, root_on_surface := false, staged := false, frame = null) -> Node3D:
	var mi := MeshInstance3D.new()
	mi.name = "fx_baked_" + kind
	mi.set_meta("fx_picture_kind", kind)
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	mi.mesh = quad
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = size * 3.0 + velocity.length() * life
	var m := flipbook_material(fx, kind, band)
	if staged:
		# Issue 461 (carried from issue 484, Board comment on 507): the core flash always uses the lopsided baked seed
		# (s0), turned at random. Two of the three seeds are the round "flower" of equal puffs, which read as a ring of
		# identical puffs at about 2.3 s on a capital death ("a little too even and weird", Ryan, Nov 11).
		m = route_material(fx, SH.DEATH_FLIPBOOK, "death/" + band + "/flash_", true, 0)
		m.set_shader_parameter("pic_spin", fx.rng.randf() * TAU)
		m.set_shader_parameter("size_divisor", 0.80)
		mi.extra_cull_margin = 100.0
	m.set_shader_parameter("born", fx.now)
	m.set_shader_parameter("lifetime", life)
	m.set_shader_parameter("extent", size)
	m.set_shader_parameter("intensity", strength)
	m.set_shader_parameter("plasma", 1.0 if kind == "flash" else 0.0)
	m.set_shader_parameter("directional", 1.0 if kind == "vent" else 0.0)
	# The simulation occupies only about a fifth of each baked cell. Sampling
	# its padded cell made a nominal 70-pixel core just 13 pixels wide.
	m.set_shader_parameter("atlas_rect", Vector4(0.36, 0.40, 0.28, 0.44) if kind == "vent" else Vector4(0.38, 0.38, 0.24, 0.24))
	if m.has_meta("route"):
		m.set_shader_parameter("atlas_rect", Vector4(0.0, 0.0, 1.0, 1.0))
	# A death vent is rooted on the real plating: the gas leaves the ship outward, so the picture is turned to put its
	# measured root on the hull and its plume along +n. Weapons keep the old tip-on-the-surface offset.
	var up: Vector3 = -n if (root_on_surface and kind == "vent") else n
	m.set_shader_parameter("tear_normal", up)
	m.set_shader_parameter("velocity", velocity)
	m.set_shader_parameter("min_pixels", 70.0 if kind == "flash" else 0.0)
	mi.material_override = m
	fx.add_child(mi)
	if root_on_surface and kind == "vent":
		mi.global_position = p + n * size * VENT_ROOT_FRAC
		mi.set_meta("gas_root", p)
	else:
		mi.global_position = p + (n * size * 0.42 if kind == "vent" else Vector3.ZERO)
		mi.set_meta("gas_root", mi.global_position)
	fx.later(fx.now + life + 0.1, fx.free_effect.bind(weakref(mi)))
	# Every picture the death spawns is entered in the stray puff guard. The root is the point the gas leaves, not the
	# picture centre, so a floating picture cannot pass just because its frame happens to be near the hull.
	if frame is Transform3D: mi.set_meta("spawn_frame", frame)
	if src != null and frame is Transform3D:
		fx.record_spawn(src, mi.get_meta("gas_root"), false, frame)
	elif src != null:
		fx.record_spawn(src, mi.get_meta("gas_root"))
	return mi


# Two bounded GPU emitters. Each particle is born in world space, with zero drag,
# zero acceleration and a cone centred on the sampled thermal-tear normal.
static func tear_particles(fx, p: Vector3, n: Vector3, L: float, inherited: Vector3, sparks_only := false) -> void:
	if fx.quality == "low" or DisplayServer.get_name() == "headless": return
	for sparks in ([true] if sparks_only else [false, true]):
		var emitter := GPUParticles3D.new()
		emitter.name = "fx_tear_sparks" if sparks else "fx_vent_cone"
		emitter.amount = 32 if sparks else 12
		emitter.lifetime = 0.65 if sparks else 0.45
		emitter.one_shot = true
		emitter.explosiveness = 0.95
		emitter.local_coords = false
		emitter.visibility_aabb = AABB(Vector3.ONE * -L, Vector3.ONE * L * 2.0)
		var proc: ShaderMaterial = fx.mat(SH.DEATH_PARTICLES)
		proc.set_shader_parameter("axis", n)
		proc.set_shader_parameter("seed_value", fx.rng.randf() * 100.0)
		proc.set_shader_parameter("inherited", inherited)
		proc.set_shader_parameter("spread", 0.38 if sparks else 0.20)
		proc.set_shader_parameter("speed", L * (0.6 if sparks else 0.25))
		proc.set_shader_parameter("size", L * (0.003 if sparks else 0.009))
		proc.set_shader_parameter("tint", Color(0.93, 0.63, 0.26, 0.9) if sparks else Color(0.53, 0.46, 0.64, 0.2))
		emitter.process_material = proc
		var mesh_key := "death_spark_mesh" if sparks else "death_cone_mesh"
		if not fx.dstate.has(mesh_key):
			var mesh := QuadMesh.new(); mesh.size = Vector2(0.28, 1.2) if sparks else Vector2.ONE
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.vertex_color_use_as_albedo = true
			mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			if not fx.dstate.has("tear_falloff"):
				var gradient := Gradient.new()
				gradient.set_color(0, Color(0.95, 0.95, 0.95, 0.95))
				gradient.set_color(1, Color(0.95, 0.95, 0.95, 0.0))
				var texture := GradientTexture2D.new()
				texture.gradient = gradient
				texture.fill = GradientTexture2D.FILL_RADIAL
				texture.fill_from = Vector2(0.5, 0.5)
				texture.fill_to = Vector2(0.5, 1.0)
				fx.dstate["tear_falloff"] = texture
			mat.albedo_texture = fx.dstate["tear_falloff"]
			mat.albedo_color = Color(0.9, 0.75, 0.48) if sparks else Color(0.4, 0.34, 0.5, 0.3)
			mesh.material = mat
			fx.dstate[mesh_key] = mesh
		emitter.draw_pass_1 = fx.dstate[mesh_key]
		fx.add_child(emitter); emitter.global_position = p
		fx.later(fx.now + 0.9, fx.free_effect.bind(weakref(emitter)))


# ---------------------------------------------------------------- debris bodies (Jolt)

static func shard_mesh(rng: RandomNumberGenerator, size: float) -> Array:
	# a torn plate: a ragged outline (notches and teeth, stretched along one axis), creased once so it reads bent
	var n = rng.randi_range(9, 13)
	var ring_pts: Array = []
	var angs: Array = []
	for i in n:
		angs.append(TAU * (i + rng.randf_range(-0.35, 0.35)) / n)
	angs.sort()
	var stretch := rng.randf_range(1.2, 1.9)
	for i in angs.size():
		var a: float = angs[i]
		var r = size * rng.randf_range(0.3, 0.6) * (0.62 if (i % 3 == 1 and rng.randf() < 0.7) else 1.0)
		ring_pts.append(Vector2(cos(a) * r * stretch, sin(a) * r))
	var th = size * rng.randf_range(0.05, 0.1)
	var crease := rng.randf_range(-0.2, 0.25) * size
	var bend := rng.randf_range(0.3, 0.9) * (1.0 if rng.randf() < 0.5 else -1.0)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts = PackedVector3Array()
	for side in [1.0, -1.0]:
		var y: float = th * 0.5 * side
		for i in n:
			var a2: Vector2 = ring_pts[i]
			var b2: Vector2 = ring_pts[(i + 1) % n]
			var tri = [Vector3(0, y, 0), Vector3(a2.x, y, a2.y), Vector3(b2.x, y, b2.y)]
			if side < 0.0:
				tri = [tri[0], tri[2], tri[1]]
			for k in 3:
				# vertex colour: 0 at the plate's middle, 1 on its torn rim (the debris shader glows only the rim)
				st.set_color(Color.BLACK if tri[k].x == 0.0 and tri[k].z == 0.0 else Color.WHITE)
				st.add_vertex(_fold(tri[k], crease, bend))
		for v in ring_pts:
			pts.append(_fold(Vector3(v.x, y, v.y), crease, bend))
	for i in n:
		var a3: Vector2 = ring_pts[i]
		var b3: Vector2 = ring_pts[(i + 1) % n]
		var q = [Vector3(a3.x, th * 0.5, a3.y), Vector3(b3.x, th * 0.5, b3.y), Vector3(b3.x, -th * 0.5, b3.y), Vector3(a3.x, -th * 0.5, a3.y)]
		for tri in [[q[0], q[2], q[1]], [q[0], q[3], q[2]]]:
			for v in tri:
				st.set_color(Color.WHITE)
				st.add_vertex(_fold(v, crease, bend))
	st.generate_normals()
	return [st.commit(), pts]


# Bend a plate along the line x = crease (the part past it lifts by `bend` per unit), as torn plating folds.
static func _fold(v: Vector3, crease: float, bend: float) -> Vector3:
	var d := v.x - crease
	if d <= 0.0:
		return v
	var c := cos(bend)
	var s := sin(bend)
	return Vector3(crease + d * c - v.y * s, d * s + v.y * c, v.z)


static func spawn_debris(fx, pos: Vector3, vel: Vector3, count: int, size: float) -> void:
	var t0 := Time.get_ticks_usec()
	_spawn_debris_inner(fx, pos, vel, count, size)
	fx.pend("debris", t0)


static func _spawn_debris_inner(fx, pos: Vector3, vel: Vector3, count: int, size: float) -> void:
	var st: Dictionary = fx.dstate
	if not bool(st.get("physics_on", false)) or count <= 0:
		return
	var pool: Array = st["debris"]
	var sc = 0 if size < 0.3 * fx.unit else (1 if size < 0.6 * fx.unit else 2)
	for i in count:
		var b: RigidBody3D
		if pool.size() < DEBRIS_CAP:
			b = RigidBody3D.new()
			b.gravity_scale = 0.0
			b.axis_lock_linear_y = true
			b.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
			b.mass = 0.3 + 0.4 * sc
			b.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
			b.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
			b.angular_damp = 0.0
			b.linear_damp = 0.0
			b.collision_layer = DEBRIS_LAYER
			b.collision_mask = HULL_LAYER | DEBRIS_LAYER
			b.physics_material_override = st["bounce"]
			var vi: int = fx.rng.randi() % DEBRIS_VARIANTS
			var cs = CollisionShape3D.new()
			cs.shape = st["debris_shapes"][sc][vi]
			b.add_child(cs)
			var mi = MeshInstance3D.new()
			mi.name = "mesh"
			mi.mesh = st["debris_meshes"][sc][vi]
			mi.material_override = st["debris_mat"]
			b.add_child(mi)
			fx.phys_root.add_child(b)
			pool.append(b)
		else:
			b = pool[int(st["debris_next"])]
			st["debris_next"] = (int(st["debris_next"]) + 1) % DEBRIS_CAP
		var d: Vector3 = fx.rdir()
		d.y = 0.0
		d = d.normalized()
		b.global_transform = Transform3D(Basis(d, fx.rng.randf() * TAU), pos + d * 0.3 * fx.unit)
		b.linear_velocity = vel + d * (2.0 + fx.rng.randf() * 4.0) * fx.unit
		b.linear_velocity.y = 0.0
		b.angular_velocity = Vector3(fx.rng.randf_range(-6, 6), fx.rng.randf_range(-6, 6), fx.rng.randf_range(-6, 6))
		b.sleeping = false
		b.visible = true
		var mesh := b.get_node("mesh") as MeshInstance3D
		# Headless uses the dummy server even though the configured method still says forward_plus.
		if DisplayServer.get_name() != "headless" and RenderingServer.get_current_rendering_method() != "dummy" and mesh.material_override != null:
			mesh.set_instance_shader_parameter("spawn_t", fx.now)


# A convex collider Jolt can always build (G2 bot runs: a 900-point hull failed and logged an error). The point cloud is
# cleaned (no NaN or infinite points), cut down to the extreme points along 50 fixed directions (at most 50 points, the
# hull's shape kept), and checked for flat or tiny input; anything degenerate gets its (thickened) bounding box instead.
const _HULL_DIRS := 50
static var _dirs: PackedVector3Array = PackedVector3Array()


# F3 perf: each piece's centre and its collider points (at most _HULL_DIRS extreme points), worked out on the cut's
# worker thread; the break-up used to do this in GDScript on the main thread for every vertex of every piece.
static func _piece_hulls(pieces: Array) -> void:
	for pc in pieces:
		var pts: PackedVector3Array = pc["pts"]
		var cen := Vector3.ZERO
		for p in pts:
			cen += p
		cen /= maxf(pts.size(), 1)
		pc["cen"] = cen
		var hp := _extreme_points(pts)
		for i in hp.size():
			hp[i] -= cen
		pc["hull"] = hp


static func _init_dirs() -> void:
	if not _dirs.is_empty():
		return
	# Fibonacci sphere: evenly spread directions
	var d := PackedVector3Array()
	for i in _HULL_DIRS:
		var y := 1.0 - 2.0 * (float(i) + 0.5) / _HULL_DIRS
		var rr := sqrt(maxf(0.0, 1.0 - y * y))
		var a := float(i) * 2.399963
		d.append(Vector3(cos(a) * rr, y, sin(a) * rr))
	_dirs = d


# The finite points of src that are extreme along any of the fixed directions (thread-safe once _init_dirs has run).
static func _extreme_points(src: PackedVector3Array) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for p in src:
		if is_finite(p.x) and is_finite(p.y) and is_finite(p.z):
			pts.append(p)
	if pts.size() <= 4:
		return pts
	var keep := {}
	for d in _dirs:
		var bi := 0
		var bd := -INF
		for i in pts.size():
			var k := pts[i].dot(d)
			if k > bd:
				bd = k
				bi = i
		keep[bi] = true
	var out := PackedVector3Array()
	for i in keep:
		out.append(pts[i])
	return out


static func safe_convex(src: PackedVector3Array) -> Shape3D:
	_init_dirs()
	var out := _extreme_points(src)
	if out.is_empty():
		var b0 := BoxShape3D.new()
		b0.size = Vector3.ONE * 0.1
		return b0
	var lo := out[0]
	var hi := out[0]
	for p in out:
		lo = lo.min(p)
		hi = hi.max(p)
	var ext := hi - lo
	var size := maxf(ext.x, maxf(ext.y, ext.z))
	# degenerate (a point, a line or a flat sheet): a box from the bounds, never thinner than 2% of the largest side
	var flat := out.size() < 4 or size < 1e-4
	if not flat:
		var a0 := out[0]
		var a1 := a0
		for p in out:
			if p.distance_squared_to(a0) > a1.distance_squared_to(a0):
				a1 = p
		var ax := (a1 - a0).normalized()
		var a2 := a0
		var bd2 := 0.0
		for p in out:
			var w := p - a0
			var dl := (w - ax * w.dot(ax)).length_squared()
			if dl > bd2:
				bd2 = dl
				a2 = p
		var nrm := (a1 - a0).cross(a2 - a0)
		if nrm.length_squared() < 1e-12 or sqrt(bd2) < size * 0.01:
			flat = true
		else:
			nrm = nrm.normalized()
			var off := 0.0
			for p in out:
				off = maxf(off, absf((p - a0).dot(nrm)))
			flat = off < size * 0.01
	if flat:
		# the bounds as an eight-corner hull, so it sits where the points are (a BoxShape3D is centred on the origin)
		var t := (ext.max(Vector3.ONE * maxf(size * 0.02, 0.05)) - ext) * 0.5
		var l2 := lo - t
		var h2 := hi + t
		var bx := ConvexPolygonShape3D.new()
		bx.points = PackedVector3Array([Vector3(l2.x, l2.y, l2.z), Vector3(h2.x, l2.y, l2.z), Vector3(l2.x, h2.y, l2.z), Vector3(h2.x, h2.y, l2.z),
			Vector3(l2.x, l2.y, h2.z), Vector3(h2.x, l2.y, h2.z), Vector3(l2.x, h2.y, h2.z), Vector3(h2.x, h2.y, h2.z)])
		return bx
	var cs := ConvexPolygonShape3D.new()
	cs.points = out
	return cs


# One convex collider per live ship (from its visible hull samples) riding the root, so debris bounces off hulls.
static func add_collider(fx, s) -> void:
	if not bool(fx.dstate.get("physics_on", false)) or s.hull.sp.size() < 8:
		return
	var shape: Shape3D = safe_convex(s.hull.sp)
	var body = AnimatableBody3D.new()
	body.name = "fx_collider"
	body.sync_to_physics = false
	body.collision_layer = HULL_LAYER
	body.collision_mask = 0
	body.physics_material_override = fx.dstate["bounce"]
	var cs = CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	s.root.add_child(body)
	s.set_meta("collider", body)


# ---------------------------------------------------------------- cutting the hull (worker thread)

# Seeds along the length (ship frame); cut: two pieces either side of a slanted plane.
static func seeds_for(s, cause: String, r: RandomNumberGenerator) -> PackedVector3Array:
	var h = s.hull
	var n = [1, 2, 3, 4, 5][clampi(s.weight, 0, 4)]
	if cause == "rupture":
		n = maxi(4, s.weight + 2)
	if cause == "big" or cause == "flay":
		n = mini(n + 1, 7)
	if cause == "melt" or cause == "dark":
		n = maxi(2, n - 1)
	var out = PackedVector3Array()
	if cause == "cut":
		var count: int = int(s.get_meta("death_cut_count", 2)) + 1
		var axis := Vector3(1.0, r.randf_range(-0.12, 0.12), r.randf_range(-0.15, 0.15))
		for i in count:
			out.append(h.c + axis * ((float(i) + 0.5) / count - 0.5) * h.L)
		return out
	for i in n:
		var u = (i + 0.5) / n + (r.randf() - 0.5) * 0.5 / n
		out.append(Vector3(h.box.position.x + u * h.L, h.c.y + (r.randf() - 0.5) * h.H * 0.6, h.c.z + (r.randf() - 0.5) * h.W * 0.6))
	return out


# ---------------------------------------------------------------- issue 484: blown apart, not sliced
# Owner, Nov 11: "the wreckage comes out looking too clean at the end. It's like straight lines and even halves." The
# old cut gave each triangle to its nearest seed, so a cruiser broke on one flat plane square to its length into two
# near-equal halves that would fit back together. The fracture plan below replaces that for big hulls:
# - uneven pieces: a cruiser parts about a third from one end, a capital into roughly a half, a third and a fifth, in a
#   per-ship order (seeded by the ship's id, so a replay breaks the same way);
# - no straight line: each break is tilted well off square (yaw and pitch), kinked into a V across the beam (two planes
#   meeting at an angle) and torn by a sum of waves (teeth about a twentieth of the length deep);
# - a bite: where the core goes off (on the break, on the side last hit), an ellipsoid of hull, its rim torn by waves,
#   is cut out as four to six separate fragments that the core flash throws out tumbling;
# - chips: a few small wedges along each break, thrown out with the bite.
# Everything is a plain function of the triangle's centre, so the worker labels triangles exactly as before (no
# triangle splitting): the break's raggedness comes from the waves and the hull's own triangles.

# A few random plane waves: [direction * wave number, phase, amplitude]. Mostly across the hull (small x part), so the
# teeth run along the break.
static func _waves(r: RandomNumberGenerator, L: float, amp: float, count: int) -> Array:
	var out: Array = []
	var lam := L * 0.16
	var a := amp
	for i in count:
		var d := Vector3(r.randf_range(-0.35, 0.35), r.randf_range(-1.0, 1.0), r.randf_range(-1.0, 1.0)).normalized()
		out.append([d * (TAU / maxf(lam, 0.0001)), r.randf() * TAU, a])
		lam *= 0.5
		a *= 0.55
	return out


static func _wave_sum(waves: Array, q: Vector3) -> float:
	var v := 0.0
	for w in waves:
		v += sin((w[0] as Vector3).dot(q) + float(w[1])) * float(w[2])
	return v


# The signed distance (roughly) to one break: positive on its +x side.
static func _break_f(b: Dictionary, q: Vector3) -> float:
	var d: Vector3 = q - (b["at"] as Vector3)
	return d.dot(b["n"]) - float(b["k"]) * absf(d.dot(b["side"]) - float(b["zk"])) + _wave_sum(b["waves"], q)


# The main piece a point belongs to (0 at the hull's low x end), ignoring the bite and the chips.
static func _plan_main(plan: Dictionary, q: Vector3) -> int:
	var i := 0
	for b in plan["breaks"]:
		if _break_f(b, q) > 0.0: i += 1
	return i


# The piece a triangle centre belongs to: a bite fragment, a chip, or a main piece.
static func _plan_assign(plan: Dictionary, q: Vector3) -> int:
	var bite: Dictionary = plan["bite"]
	if not bite.is_empty():
		var d: Vector3 = q - (bite["c"] as Vector3)
		var e := Vector2(d.x / float(bite["rx"]), Vector2(d.y, d.z).length() / float(bite["ry"])).length_squared()
		if e + _wave_sum(bite["waves"], q) < 1.0:
			var subs: PackedVector3Array = bite["subs"]
			var best := 0
			var bd := INF
			for j in subs.size():
				var dd := q.distance_squared_to(subs[j])
				if dd < bd:
					bd = dd
					best = j
			return int(bite["first"]) + best
	var chips: Dictionary = plan["chips"]
	var breaks: Array = plan["breaks"]
	var main := 0
	for bi in breaks.size():
		var f := _break_f(breaks[bi], q)
		if f > 0.0: main += 1
		if not chips.is_empty() and absf(f) < float(chips["band"]):
			var seeds: PackedVector3Array = chips["seeds"]
			var best := -1
			var bd := INF
			for j in range(bi * int(chips["per"]), (bi + 1) * int(chips["per"])):
				var dd := q.distance_squared_to(seeds[j])
				if dd < bd:
					bd = dd
					best = j
			if best >= 0 and bd < float(chips["reach"]) * float(chips["reach"]): return int(chips["first"]) + best
	return main


static func fracture_plan(fx, s, r: RandomNumberGenerator) -> Dictionary:
	var h = s.hull
	var L: float = h.L
	var W: float = maxf(h.W, L * 0.06)
	var H: float = maxf(h.H, L * 0.04)
	var x0: float = h.box.position.x
	var capital: bool = s.death_tier == "capital" or int(s.get_meta("death_cut_count", 1)) >= 2
	# 1. uneven pieces, in order along x
	var sizes: Array = []
	if capital:
		sizes = [0.50 + r.randf_range(-0.02, 0.02), 0.30 + r.randf_range(-0.02, 0.02)]
		sizes.append(1.0 - float(sizes[0]) - float(sizes[1]))
		for i in range(sizes.size() - 1, 0, -1):
			var j := r.randi_range(0, i)
			var t = sizes[i]
			sizes[i] = sizes[j]
			sizes[j] = t
	else:
		var small := r.randf_range(0.31, 0.37)
		sizes = [small, 1.0 - small] if r.randf() < 0.5 else [1.0 - small, small]
	# the side that was hit (the bite and the scorch sit there); with no recent hit, a per-ship side
	var zs := 1.0 if r.randf() < 0.5 else -1.0
	var last = s.get_meta("last_hit", [])
	if last is Array and last.size() >= 3 and fx.now - float(last[2]) < 6.0:
		var lz: float = ((last[0] as Vector3) - h.c).z
		if absf(lz) > W * 0.05: zs = signf(lz)
	# Issue 461 (carried from 484): a lance kill cuts clean on the beam's own line (deaths_and_hits.md, "What killed it":
	# the tear is the cut, two clean halves). The beam's point and direction (hull space) are set by _lance_recut on the
	# death frame; the break nearest the beam lies on it, square-ish to the beam, with no kink and almost no teeth.
	var lance = s.get_meta("lance_line", [])
	var lance_on: bool = lance is Array and lance.size() >= 2
	var lance_b := -1
	if lance_on:
		var lx: float = ((lance[0] as Vector3).x - x0) / L
		if sizes.size() == 2:
			var lu := clampf(lx, 0.3, 0.7)
			sizes = [lu, 1.0 - lu]
			lance_b = 0
		else:
			var acc := 0.0
			var bd := INF
			for i in sizes.size() - 1:
				acc += float(sizes[i])
				if absf(acc - lx) < bd:
					bd = absf(acc - lx)
					lance_b = i
	# 2. the breaks: tilted, kinked, torn
	var breaks: Array = []
	var u := 0.0
	var seeds := PackedVector3Array()
	for i in sizes.size():
		seeds.append(Vector3(x0 + (u + float(sizes[i]) * 0.5) * L, h.c.y, h.c.z))
		u += float(sizes[i])
		if i == sizes.size() - 1: break
		var room: float = 0.45 * minf(float(sizes[i]), float(sizes[i + 1])) * L
		var yaw := deg_to_rad(r.randf_range(20.0, 34.0)) * (1.0 if r.randf() < 0.5 else -1.0)
		var pitch := deg_to_rad(r.randf_range(10.0, 22.0)) * (1.0 if r.randf() < 0.5 else -1.0)
		var k := r.randf_range(0.45, 0.8) * (1.0 if r.randf() < 0.5 else -1.0)
		var amp := L * 0.03
		if i == lance_b:
			# the plane holds the beam's line: its normal is across the beam, kept within 34 degrees of square to the hull
			var pn: Vector3 = (lance[1] as Vector3).cross(Vector3.UP)
			pn = pn.normalized() if pn.length() > 0.05 else Vector3.RIGHT
			if pn.x < 0.0: pn = -pn
			yaw = clampf(atan2(pn.z, pn.x), -deg_to_rad(34.0), deg_to_rad(34.0))
			pitch = 0.0
			k = 0.0
			amp = L * 0.004
		# keep each break inside its two pieces: the tilt, the kink and the teeth together reach at most `room`
		var reach: float = absf(tan(yaw)) * W * 0.5 + absf(tan(pitch)) * H * 0.5 + absf(k) * W * 0.5 + amp * 1.6
		var fit := minf(1.0, room / maxf(reach, 0.0001))
		yaw = atan(tan(yaw) * fit)
		pitch = atan(tan(pitch) * fit)
		k *= fit
		amp *= maxf(fit, 0.5)
		var n := Vector3(cos(yaw), 0.0, sin(yaw)).rotated(Vector3(-sin(yaw), 0.0, cos(yaw)), pitch).normalized()
		var side := Vector3(-n.z, 0.0, n.x).normalized()
		var zk := r.randf_range(-0.25, 0.25) * W
		# the V kink moves the break's mean line along the hull by k times the mean distance from its crease; move the
		# break back by that much so the pieces keep their planned sizes
		var mean_off := k * (W * 0.25 + zk * zk / W) / maxf(n.x, 0.2)
		breaks.append({"at": Vector3(x0 + u * L - mean_off, h.c.y, h.c.z), "n": n, "side": side,
			"zk": zk, "k": k, "waves": _waves(r, L, amp, 3)})
	# 3. the bite: on the core's break (a capital: the break beside its biggest piece), on the side that was hit
	var bi := 0
	if breaks.size() > 1:
		bi = 0 if float(sizes[0]) + float(sizes[1]) >= float(sizes[1]) + float(sizes[2]) else 1
	var rx: float = L * (0.09 if capital else 0.12) * (0.6 if lance_on else 1.0)
	# centred a little into the bigger of the two pieces, so the bite eats mostly into it and the small one stays small
	var bat: Vector3 = (breaks[bi]["at"] as Vector3) + Vector3.RIGHT * rx * 0.5 * (-1.0 if float(sizes[bi]) > float(sizes[bi + 1]) else 1.0)
	var out_dir := Vector3(0.0, 0.3, zs).normalized()
	# the bite's centre is a real hull sample: the one furthest out to the hit side near the break (bench round 3: a ray
	# toward the hull could hit a mast tip with no plating round it, and the core flash then floated off the hull)
	var bc: Vector3 = bat + Vector3(0.0, H * 0.3, zs * W * 0.4)
	var best := -INF
	for i in h.sp.size():
		var q: Vector3 = h.sp[i]
		if absf(q.x - bat.x) > rx * 0.6: continue
		var score: float = (q - bat).dot(out_dir) - absf(q.x - bat.x) * 0.5
		if score > best:
			best = score
			bc = q
	if best == -INF:
		var hit: Dictionary = h.ray(bat + out_dir * L * 2.0, -out_dir)
		bc = hit.get("p", bc)
	var ry: float = maxf(W, H) * (0.48 if capital else 0.55)
	var subs := PackedVector3Array()
	var nsub := 6 if capital else 4
	for j in nsub:
		var a := TAU * (float(j) + r.randf_range(-0.3, 0.3)) / float(nsub)
		subs.append(bc + Vector3(cos(a) * rx * 0.6, 0.0, 0.0) + (Vector3(0.0, sin(a), 0.0) - out_dir * r.randf_range(0.1, 0.6)) * ry * 0.6)
	var n_main := sizes.size()
	# a torn rim, but one bite: two long waves (round 1's three waves holed a capital's deck like lace)
	var bite := {"c": bc, "rx": rx, "ry": ry, "waves": _waves(r, L, 0.22, 2), "subs": subs, "first": n_main,
		"out": out_dir}
	# 4. chips along each break
	var per := 2
	var chip_seeds := PackedVector3Array()
	for b in breaks:
		for j in per:
			chip_seeds.append((b["at"] as Vector3) + (b["side"] as Vector3) * W * r.randf_range(-0.5, 0.5) * (-zs if j == 0 else zs) + Vector3.UP * H * r.randf_range(-0.4, 0.4))
	var chips := {"seeds": chip_seeds, "per": per, "band": L * 0.03, "reach": minf(maxf(W, H) * 0.25, L * 0.05), "first": n_main + nsub}
	# 5. scorch on the plating round the wound: the bite and both sides of each break, fading over about a hull width
	var scorch: Array = [Vector4(bc.x, bc.y, bc.z, rx + minf(W, L * 0.12) * 0.6)]
	for b in breaks:
		for side in [-1.0, 1.0]:
			var p: Vector3 = (b["at"] as Vector3) + (b["side"] as Vector3) * W * 0.3 * side + Vector3.UP * H * 0.2
			scorch.append(Vector4(p.x, p.y, p.z, minf(W, L * 0.12) * 0.5))
	return {"L": L, "seeds": seeds, "sizes": sizes, "breaks": breaks, "bite": bite, "chips": chips, "n_main": n_main,
		"n_frag": nsub + chip_seeds.size(), "bite_break": bi, "scorch": scorch}


# Issue 461 (carried from 484: "the cut is prepared before the killing weapon is known"). A lance kill re-cuts the hull on
# the death frame along the beam's line (fracture_plan reads "lance_line"). The cut runs on a worker during the tell
# (1.38 s on a cruiser, 2.0 s on a capital); if it is not done by the break, the ship breaks along the cut it already had
# (cut_prev), never stalls. Only big hulls killed by a lance pay for it.
static func _lance_recut(fx, s) -> void:
	if not is_instance_valid(s.root):
		return
	if s.has_meta("cut_task"):
		# a damage refresh of the cut is still running (bench round 1: a damaged ship nearly always has one): leave it to
		# finish on its own and start the lance cut beside it. If the refresh had not finished, the ship breaks along the
		# last finished cut (cut_prev) only if the lance cut is late; otherwise it waits for the lance cut.
		_collect_later(fx, int(s.get_meta("cut_task")))
		s.remove_meta("cut_task")
	var h = s.hull
	# with no recent hit on record, a per-ship point a little off the middle (an even split reads as sliced, Ryan, Nov 11)
	var lp: Vector3 = h.c + Vector3(h.L * (0.12 if hash(str(s.id)) % 2 == 0 else -0.12), 0.0, 0.0)
	var ld: Vector3 = Vector3(0.0, 0.0, -float(h.stb_z))
	var last = s.get_meta("last_hit", [])
	if last is Array and last.size() >= 3 and fx.now - float(last[2]) < 2.0:
		lp = last[0]
		ld = last[1]
	s.set_meta("lance_line", [lp, ld])
	if s.has_meta("cut_job"):
		var old: Dictionary = s.get_meta("cut_job")
		if old.get("out") != null:
			s.set_meta("cut_prev", old)
		s.remove_meta("cut_job")
	var t0 := Time.get_ticks_usec()
	precompute(fx, s, "cut")
	fx.notes.append("lance recut %s" % str(s.id))
	fx.pend("lance_recut", t0)


# Gather the hull's surfaces on the main thread (mesh arrays come from the rendering server), then cut on a worker.
static func precompute(fx, s, cause := "blast") -> void:
	if s.weight <= 0 or s.has_meta("cut_task") or s.has_meta("cut_job"):
		return
	if not is_instance_valid(s.root) or not s.root.is_inside_tree():
		return   # F3: the ship's node was freed before its staggered cut came round
	if s.faction == "chorus":
		cause = "rupture"
	elif s.death_big:
		cause = "cut"  # two prepared halves, and the vents/crack use this same bisector
	var r = RandomNumberGenerator.new()
	r.seed = hash(s.id) + 3
	var seeds = seeds_for(s, cause, r)
	# Issue 484: a big hull is blown apart, not sliced. Its pieces follow a fracture plan (uneven pieces, kinked and
	# torn breaks, a bite of hull gone where the core goes off, chips along the break); the seeds stay one per main
	# piece for the older readers.
	var plan := {}
	if s.death_big and s.faction != "chorus":
		plan = fracture_plan(fx, s, r)
		seeds = plan["seeds"]
	var inv: Transform3D = s.root.global_transform.affine_inverse()
	var surfs: Array = []
	for m in s.meshes:
		var mi = m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf = inv * mi.global_transform
		for si in mi.mesh.get_surface_count():
			var mat: Material = mi.get_active_material(si)
			surfs.append({"arrays": s.current_arrays(mi, si), "xf": xf, "mat": mat, "fmt": (mi.mesh as ArrayMesh).surface_get_format(si) if mi.mesh is ArrayMesh else 0})
	var job = {"seeds": seeds, "surfs": surfs, "cause": cause, "organic": s.faction == "chorus", "out": null,
		"mesh_on_worker": DisplayServer.get_name() != "headless", "plan": plan,
		"ragged": s.death_big, "warp": _waves(r, s.hull.L, s.hull.L * 0.05, 3) if s.faction == "chorus" else [],
		"sites": s.death_big and s.faction != "chorus", "sp": s.hull.sp, "sn": s.hull.sn}
	s.set_meta("cut_job", job)
	_init_dirs()
	var tid = WorkerThreadPool.add_task(func() -> void:
		var pieces := _cut(job)
		_piece_hulls(pieces)
		if bool(job.get("sites", false)):
			var n_main: int = int(job["plan"]["n_main"]) if not (job["plan"] as Dictionary).is_empty() else pieces.size()
			for i in mini(n_main, pieces.size()):
				pieces[i]["sec_sites"] = _piece_sites_in(job["sp"], job["sn"], job["seeds"], pieces[i]["cen"], 5, job["plan"], i)
		# issue 220: the pieces' geometry is uploaded here on the worker (as the hull rebuild's meshes are, fx_breach
		# compute): on the main thread it cost 20 to 85 ms frames in battle, once per ship and after every cut refresh.
		# Materials stay on the main thread (_prebuild). A headless run builds it all in _prebuild instead.
		if bool(job["mesh_on_worker"]):
			var geo: Array = []
			for pc in pieces:
				geo.append(_piece_geometry(pc))
			job["geo"] = geo
		job["out"] = pieces)
	s.set_meta("cut_task", tid)
	fx.later(fx.now + 0.5, func l_prebuild() -> void: _prebuild(fx, s))


static func _collect_later(fx, tid: int) -> void:
	if WorkerThreadPool.is_task_completed(tid):
		WorkerThreadPool.wait_for_task_completion(tid)
		return
	fx.later(fx.now + 0.25, func l_collect() -> void: _collect_later(fx, tid))


# When the cut is done, upload the pieces' meshes while the battle is quiet, so the break-up itself only shows them
# (the first break-up cost a 35 ms frame when it built them on the spot).
static func _prebuild(fx, s) -> void:
	if not s.has_meta("cut_task") or s.has_meta("death_hidden"):
		return
	var tid: int = s.get_meta("cut_task")
	if not WorkerThreadPool.is_task_completed(tid):
		fx.later(fx.now + 0.5, func l_prebuild() -> void: _prebuild(fx, s))
		return
	WorkerThreadPool.wait_for_task_completion(tid)
	s.remove_meta("cut_task")
	var job: Dictionary = s.get_meta("cut_job", {})
	var t0 := Time.get_ticks_usec()
	var meshes: Array = []
	var geo: Array = job.get("geo", [])
	var pieces: Array = job.get("out", []) if job.get("out") != null else []
	for i in pieces.size():
		var pc: Dictionary = pieces[i]
		meshes.append(_piece_materials(geo[i], pc) if i < geo.size() else _piece_mesh(pc))
		if pc.has("hull"): pc["shape"] = safe_convex(pc["hull"])
	job["meshes"] = meshes
	fx.pend("piece_meshes", t0)


# Hull attributes keep their vertex format; private damage materials add burnt backs.
# The opaque slag surface is built here with the piece, before death when possible.
static func _piece_mesh(pc: Dictionary, weathered := false) -> ArrayMesh:
	return _piece_materials(_piece_geometry(pc), pc, weathered)


# The piece's surfaces, no materials (safe on a worker thread: no shaders or static caches are touched).
static func _piece_geometry(pc: Dictionary) -> ArrayMesh:
	var am = ArrayMesh.new()
	for sd in pc["surfs"]:
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, sd["arrays"], [], {}, int(sd.get("fmt", 0)) & Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)
	if pc.has("cap"):
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, pc["cap"])
	return am


# The piece's materials, in surface order (main thread).
static func _piece_materials(am: ArrayMesh, pc: Dictionary, weathered := false) -> ArrayMesh:
	var si := 0
	for sd in pc["surfs"]:
		var hull_mat := HULL.damage_material(sd["mat"], Transform3D.IDENTITY, {}, float(pc.get("section_scale", 1.0)), bool(pc.get("organic", false)))
		hull_mat.set_shader_parameter("fx_power", 0.0)
		hull_mat.set_shader_parameter("fx_weather", 0.8 if weathered else 0.0)
		# issue 484: blackened, heat-stained plating round the wound (fx_hull.gd DAMAGE_UNIFORMS, fx_scorch)
		var scorch: Array = pc.get("scorch", [])
		if not scorch.is_empty():
			hull_mat.set_shader_parameter("fx_scorch_count", mini(scorch.size(), 8))
			hull_mat.set_shader_parameter("fx_scorch", scorch.slice(0, 8))
			hull_mat.set_shader_parameter("fx_scorch_heat", 0.0)
			var hm: Array = pc.get("hull_mats", [])
			hm.append(hull_mat)
			pc["hull_mats"] = hm
		if si < am.get_surface_count():
			am.surface_set_material(si, hull_mat)
		si += 1
	if pc.has("cap"):
		var mat := ShaderMaterial.new()
		mat.shader = HULL.shared_shader(SLAG)
		mat.set_shader_parameter("organic", pc.get("organic", false))
		mat.set_shader_parameter("section_scale", pc.get("section_scale", 1.0))
		am.surface_set_material(mini(si, am.get_surface_count() - 1), mat)
		pc["cap_mat"] = mat
	return am


static func _cut(job: Dictionary) -> Array:
	var seeds: PackedVector3Array = job["seeds"]
	var plan: Dictionary = job.get("plan", {})
	var warp: Array = job.get("warp", [])
	var ns = seeds.size()
	var n_main = ns
	if not plan.is_empty():
		n_main = int(plan["n_main"])
		ns = n_main + int(plan["n_frag"])
	var pieces: Array = []
	for c in ns:
		pieces.append({"surfs": [], "pts": PackedVector3Array(), "edge": PackedVector3Array(), "n": 0, "organic": job.get("organic", false),
			"ragged": bool(job.get("ragged", false)), "frag": c >= n_main, "scorch": plan.get("scorch", []), "plan": plan})
	for sd in job["surfs"]:
		var arr: Array = sd["arrays"]
		var xf: Transform3D = sd["xf"]
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var vl = xf * v
		# a mirrored hull (negative determinant) turns its triangles inside out: flip the winding back
		var flip = xf.basis.determinant() < 0.0
		var idx = PackedInt32Array()
		if arr[Mesh.ARRAY_INDEX] != null and (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() > 0:
			idx = arr[Mesh.ARRAY_INDEX]
		else:
			idx.resize(v.size())
			for i in v.size():
				idx[i] = i
		var buckets: Array = []
		for c in ns:
			buckets.append(PackedInt32Array())
		for t in range(0, idx.size() - 2, 3):
			var a = idx[t]
			var b = idx[t + 1]
			var cc = idx[t + 2]
			var q = (vl[a] + vl[b] + vl[cc]) / 3.0
			var best = 0
			var bd = 1e18
			var bd2 = 1e18
			if not plan.is_empty():
				best = _plan_assign(plan, q)
			else:
				# issue 484: a Chorus rupture tears along warped lines, not flat Voronoi planes
				var qw: Vector3 = q
				if not warp.is_empty(): qw = q + Vector3(1.0, 0.4, 0.6) * _wave_sum(warp, q)
				for c in ns:
					var dd = qw.distance_squared_to(seeds[c])
					if dd < bd:
						bd2 = bd
						bd = dd
						best = c
					elif dd < bd2:
						bd2 = dd
			buckets[best].append(a)
			buckets[best].append(cc if flip else b)
			buckets[best].append(b if flip else cc)
			var pc: Dictionary = pieces[best]
			if plan.is_empty() and (pc["edge"] as PackedVector3Array).size() < 64 and sqrt(bd2) - sqrt(bd) < 0.6:
				var edge: PackedVector3Array = pc["edge"]
				edge.append(q)
				pc["edge"] = edge
		for c in ns:
			var tri: PackedInt32Array = buckets[c]
			if tri.is_empty():
				continue
			var remap = PackedInt32Array()
			remap.resize(v.size())
			remap.fill(-1)
			var order = PackedInt32Array()
			var nidx = PackedInt32Array()
			nidx.resize(tri.size())
			for i in tri.size():
				var o = tri[i]
				var m = remap[o]
				if m < 0:
					m = order.size()
					remap[o] = m
					order.append(o)
				nidx[i] = m
			var na = []
			na.resize(Mesh.ARRAY_MAX)
			var pv = PackedVector3Array()
			pv.resize(order.size())
			for i in order.size():
				pv[i] = vl[order[i]]
			na[Mesh.ARRAY_VERTEX] = pv
			if arr[Mesh.ARRAY_NORMAL] != null and (arr[Mesh.ARRAY_NORMAL] as PackedVector3Array).size() == v.size():
				var src: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
				var dn = PackedVector3Array()
				dn.resize(order.size())
				for i in order.size():
					dn[i] = (xf.basis * src[order[i]]).normalized()
				na[Mesh.ARRAY_NORMAL] = dn
			if arr[Mesh.ARRAY_TANGENT] != null and (arr[Mesh.ARRAY_TANGENT] as PackedFloat32Array).size() == v.size() * 4:
				var src4: PackedFloat32Array = arr[Mesh.ARRAY_TANGENT]
				var dt = PackedFloat32Array()
				dt.resize(order.size() * 4)
				for i in order.size():
					var o4 = order[i] * 4
					var tv = (xf.basis * Vector3(src4[o4], src4[o4 + 1], src4[o4 + 2])).normalized()
					dt[i * 4] = tv.x
					dt[i * 4 + 1] = tv.y
					dt[i * 4 + 2] = tv.z
					dt[i * 4 + 3] = src4[o4 + 3]
				na[Mesh.ARRAY_TANGENT] = dt
			for key in [Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2]:
				if arr[key] != null and (arr[key] as PackedVector2Array).size() == v.size():
					var s2: PackedVector2Array = arr[key]
					var d2 = PackedVector2Array()
					d2.resize(order.size())
					for i in order.size():
						d2[i] = s2[order[i]]
					na[key] = d2
			if arr[Mesh.ARRAY_COLOR] != null and (arr[Mesh.ARRAY_COLOR] as PackedColorArray).size() == v.size():
				var sc: PackedColorArray = arr[Mesh.ARRAY_COLOR]
				var dc = PackedColorArray()
				dc.resize(order.size())
				for i in order.size():
					dc[i] = sc[order[i]]
				na[Mesh.ARRAY_COLOR] = dc
			na[Mesh.ARRAY_INDEX] = nidx
			var pc: Dictionary = pieces[c]
			pc["surfs"].append({"arrays": na, "mat": sd["mat"], "fmt": int(sd.get("fmt", 0))})
			pc["n"] = int(pc["n"]) + order.size()
			var step = maxi(1, order.size() / 120)
			var points: PackedVector3Array = pc["pts"]
			for i in range(0, order.size(), step):
				points.append(pv[i])
			pc["pts"] = points
	for pc in pieces:
		_seal_piece(pc)
	return pieces


# Trace the actual welded boundary loops. Ear clipping uses boundary vertices only:
# no centre vertex, radial bands or centre-point ribs can show through as spokes.
static func _seal_piece(pc: Dictionary) -> void:
	var all_edges := {}
	var welds := {}
	var positions := PackedVector3Array()
	var bounds := AABB()
	var first := true
	for sd in pc["surfs"]:
		for p in sd["arrays"][Mesh.ARRAY_VERTEX]:
			if not (p as Vector3).is_finite(): continue
			if first:
				bounds = AABB(p, Vector3.ZERO)
				first = false
			else: bounds = bounds.expand(p)
	if first: return
	pc["section_scale"] = bounds.size.length()
	var quantum := maxf(bounds.size.length() * 0.000001, 0.000001)
	for sd in pc["surfs"]:
		var pts: PackedVector3Array = sd["arrays"][Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = sd["arrays"][Mesh.ARRAY_INDEX]
		var ids := PackedInt32Array()
		ids.resize(pts.size())
		ids.fill(-1)
		for i in pts.size():
			if not pts[i].is_finite(): continue
			var key := Vector3i((pts[i] / quantum).round())
			if not welds.has(key):
				welds[key] = positions.size()
				positions.append(pts[i])
			ids[i] = int(welds[key])
		for t in range(0, idx.size() - 2, 3):
			for j in 3:
				var ka := ids[idx[t + j]]
				var kb := ids[idx[t + (j + 1) % 3]]
				if ka < 0 or kb < 0 or ka == kb: continue
				var key := Vector2i(mini(ka, kb), maxi(ka, kb))
				if all_edges.has(key): all_edges.erase(key)
				else: all_edges[key] = true
	pc["boundary_edges"] = all_edges.size()
	var adj := {}
	for key in all_edges:
		for j in 2:
			if not adj.has(key[j]): adj[key[j]] = []
			adj[key[j]].append(key[1 - j])
	var remaining := all_edges.duplicate()
	var cap := {"v": PackedVector3Array(), "n": PackedVector3Array(), "c": PackedColorArray()}
	pc["cap_loops"] = 0
	pc["cap_fallbacks"] = 0
	for start in adj:
		var walk: Array = [start]
		while not walk.is_empty():
			var at: int = walk.back()
			var next := -1
			for other in adj[at]:
				var edge := Vector2i(mini(at, other), maxi(at, other))
				if remaining.has(edge):
					remaining.erase(edge)
					next = other
					break
			if next < 0:
				walk.pop_back()
				continue
			var seen := walk.find(next)
			if seen >= 0:
				var outline := PackedVector3Array()
				for j in range(seen, walk.size()): outline.append(positions[walk[j]])
				if outline.size() >= 3:
					_cap_outline(cap, outline, bounds, quantum, pc)
				walk.resize(seen + 1)
			else: walk.append(next)
	if not (cap["v"] as PackedVector3Array).is_empty():
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = cap["v"]
		arr[Mesh.ARRAY_NORMAL] = cap["n"]
		arr[Mesh.ARRAY_COLOR] = cap["c"]
		pc["cap"] = arr


static func _cap_outline(cap: Dictionary, outline: PackedVector3Array, bounds: AABB, quantum: float, pc: Dictionary) -> void:
	var centre := Vector3.ZERO
	for p in outline: centre += p
	centre /= outline.size()
	var normal := Vector3.ZERO
	var radius := 0.0
	for i in outline.size():
		normal += (outline[i] - centre).cross(outline[(i + 1) % outline.size()] - centre)
		radius = maxf(radius, outline[i].distance_to(centre))
	if normal.length_squared() < 1e-16:
		for i in range(1, outline.size() - 1):
			var n := (outline[i] - outline[0]).cross(outline[i + 1] - outline[0])
			if n.length_squared() > normal.length_squared(): normal = n
	if normal.length_squared() < 1e-20: return
	normal = normal.normalized()
	var inward := normal if normal.dot(bounds.get_center() - centre) >= 0.0 else -normal
	var x := normal.cross(Vector3.UP if absf(normal.y) < 0.9 else Vector3.RIGHT).normalized()
	var y := normal.cross(x)
	var polygon := PackedVector2Array()
	var inset := PackedVector3Array()
	var depth := minf(radius * 0.075, bounds.size.length() * 0.035)
	for p in outline:
		polygon.append(Vector2((p - centre).dot(x), (p - centre).dot(y)))
		# Only the narrow torn lip slopes. The whole face has one material band.
		var rough := sin(p.dot(Vector3(3.1, 5.7, 2.3))) * sin(p.dot(Vector3(8.3, 2.1, 4.7)))
		inset.append(p + (centre - p) * 0.018 + inward * depth * (1.0 + rough * 0.12))
	var indices := Geometry2D.triangulate_polygon(polygon)
	if indices.is_empty():
		# Imported non-planar/self-overlapping loops can fail 2D ear clipping.
		# A boundary-only zipper still seals them without a hub or radial spokes.
		pc["cap_fallbacks"] = int(pc["cap_fallbacks"]) + 1
		var lo := 0
		var hi := outline.size() - 1
		while hi - lo > 1:
			indices.append_array(PackedInt32Array([lo, lo + 1, hi]))
			lo += 1
			if hi - lo > 1:
				indices.append_array(PackedInt32Array([lo, hi - 1, hi]))
				hi -= 1
	for i in range(0, indices.size(), 3):
		_cap_tri(cap, inset[indices[i]], inset[indices[i + 1]], inset[indices[i + 2]], Color(0.9, 0.015, 0, 1))
	for i in outline.size():
		var j := (i + 1) % outline.size()
		_cap_tri(cap, outline[i], outline[j], inset[j], Color(0.25, 1.0, 0, 1))
		_cap_tri(cap, outline[i], inset[j], inset[i], Color(0.25, 1.0, 0, 1))
		# Sparse short, offset spars. Never connect them all to a common centre.
		if i % maxi(1, outline.size() / 4) == 0 and outline[i].distance_to(outline[j]) > quantum * 3.0:
			var a := outline[i].lerp(outline[j], 0.42) + inward * depth * 0.45
			var tangent := (outline[j] - outline[i]).normalized()
			_cap_rib(cap, a, a + tangent * radius * 0.12 + inward * depth * 0.35, -inward, maxf(radius * 0.012, quantum * 2.0))
	# Short cross members sit on the solid face. Clip each one to the real
	# outline so decks and bone ribs cannot stick outside a narrow fragment.
	# Bench round 2: the hull's own open edges (kit parts, old holes) are capped too; only loops on the new break or the
	# bite get the torn rim, or every kit seam sprouted petals.
	var ragged := bool(pc.get("ragged", false)) and _loop_torn(pc.get("plan", {}), outline)
	if ragged:
		# issue 484: the real torn rim, for the flash and fire sites (the cap also holds petals and long ribs that stick
		# out past the hull, and a site there floats beside the wreck)
		var lip: PackedVector3Array = pc.get("lip", PackedVector3Array())
		for i in range(0, outline.size(), maxi(1, outline.size() / 48)):
			if lip.size() < 512: lip.append(inset[i])
		pc["lip"] = lip
		_section_structure(cap, polygon, centre, x, y, inward, depth, radius, bool(pc.get("organic", false)), ragged)
	# Issue 484: a torn rim, not a clean outline: plating peeled outward in bent petals, some still glowing.
	if ragged and outline.size() >= 6 and radius > bounds.size.length() * 0.05:
		_cap_petals(cap, outline, centre, inward, radius, quantum, bool(pc.get("organic", false)), bounds.size.length())
	pc["cap_loops"] = int(pc["cap_loops"]) + 1


# True when a cap loop lies on the fracture plan's breaks or bite (a quarter of its points or more); with no plan
# (a Chorus rupture) every loop is a tear.
static func _loop_torn(plan: Dictionary, outline: PackedVector3Array) -> bool:
	if plan.is_empty(): return true
	var L: float = float(plan.get("L", 1.0))
	var bite: Dictionary = plan["bite"]
	var hits := 0
	var tried := 0
	for i in range(0, outline.size(), maxi(1, outline.size() / 16)):
		var q := outline[i]
		tried += 1
		var on := false
		for b in plan["breaks"]:
			if absf(_break_f(b, q)) < L * 0.06: on = true
		if not on and not bite.is_empty():
			var d: Vector3 = q - (bite["c"] as Vector3)
			on = Vector2(d.x / float(bite["rx"]), Vector2(d.y, d.z).length() / float(bite["ry"])).length_squared() < 2.2
		if on: hits += 1
	return hits * 4 >= tried


# A repeatable 0..1 value for a point (the same hull breaks the same way in a replay).
static func _rand01(p: Vector3, k: float) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719)) + k * 17.31) * 43758.5453, 1.0)


# Bent plates peeled out from the torn rim: each spans a stretch of the outline, leans out of the face and away from
# its middle, and ends in a torn tooth. Half keep a hot rim (the slag rim glow), half are scorched dark plate. A Chorus
# rim gets torn flaps of skin instead (the organic slag colour).
static func _cap_petals(cap: Dictionary, outline: PackedVector3Array, centre: Vector3, inward: Vector3, radius: float, quantum: float, organic: bool, span_len: float) -> void:
	var m := outline.size()
	var step := maxi(1, m / 26)
	var i := 0
	var made := 0
	while i < m and made < 28:
		var span := step * (1 + int(_rand01(outline[i], 1.0) * 2.0))
		var j := (i + span) % m
		var a := outline[i]
		var b := outline[j]
		if a.distance_to(b) > quantum * 3.0 and _rand01(a, 2.0) < 0.62:
			var mid := (a + b) * 0.5
			var radial := mid - centre
			radial -= inward * radial.dot(inward)
			radial = radial.normalized() if radial.length() > 1e-6 else Vector3.ZERO
			var out := (radial * lerpf(0.4, 0.9, _rand01(mid, 3.0)) - inward * lerpf(0.5, 1.0, _rand01(mid, 4.0))).normalized()
			# bench round 1: long petals on a capital's big faces read as white lace; keep them short plates
			var reach := minf(minf(radius * lerpf(0.06, 0.18, _rand01(b, 5.0)), a.distance_to(b) * 1.6 + radius * 0.03), span_len * 0.025)
			# under a pixel and a half at the battle camera nobody sees it: skip the geometry
			if reach < STAGING_UNITS_PER_PIXEL * 1.5:
				i += maxi(span, 1)
				continue
			var along := b - a
			var a2 := a + out * reach * lerpf(0.55, 1.0, _rand01(a, 6.0)) + along * 0.12
			var b2 := b + out * reach * lerpf(0.35, 0.85, _rand01(b, 7.0)) - along * 0.18
			var tooth := (a2 + b2) * 0.5 + out * reach * lerpf(0.15, 0.45, _rand01(mid, 8.0)) + along * (_rand01(mid, 9.0) - 0.5) * 0.4
			var col := Color(0.3, 1.0 if _rand01(mid, 10.0) < 0.3 else 0.2, 0, 1)
			if organic: col = Color(0.3, 0.0, 0, 1)
			_cap_tri(cap, a, b, b2, col)
			_cap_tri(cap, a, b2, a2, col)
			_cap_tri(cap, a2, b2, tooth, col)
			made += 1
		i += maxi(span, 1)


static func _section_structure(cap: Dictionary, polygon: PackedVector2Array, centre: Vector3, x: Vector3, y: Vector3, inward: Vector3, depth: float, radius: float, organic: bool, ragged := false) -> void:
	var lo := polygon[0]
	var hi := lo
	for p in polygon:
		lo = lo.min(p); hi = hi.max(p)
	for vertical in ([false] if organic else [false, true]):
		for row in 3:
			var level := lerpf(lo.x if vertical else lo.y, hi.x if vertical else hi.y, float(row + 1) / 4.0)
			var hits: Array[float] = []
			for i in polygon.size():
				var a := polygon[i]
				var b := polygon[(i + 1) % polygon.size()]
				var av := a.x if vertical else a.y
				var bv := b.x if vertical else b.y
				if (av <= level and bv > level) or (bv <= level and av > level):
					var p := a.lerp(b, (level - av) / (bv - av))
					hits.append(p.y if vertical else p.x)
			hits.sort()
			for i in range(0, hits.size() - 1, 2):
				var a := Vector2(level, hits[i]) if vertical else Vector2(hits[i], level)
				var b := Vector2(level, hits[i + 1]) if vertical else Vector2(hits[i + 1], level)
				a = a.lerp(b, 0.08); b = b.lerp(a, 0.08)
				var pa := centre + x * a.x * 0.982 + y * a.y * 0.982 + inward * depth * 0.72
				var pb := centre + x * b.x * 0.982 + y * b.y * 0.982 + inward * depth * 0.72
				var width := minf(radius * 0.018, a.distance_to(b) * 0.045)
				if ragged:
					# issue 484: some decks and ribs run long, bent out past the torn skin
					var r1 := _rand01(pa, 11.0)
					if r1 < 0.55:
						var dir := (pb - pa).normalized()
						var ext := radius * lerpf(0.10, 0.28, _rand01(pb, 12.0))
						if ext < STAGING_UNITS_PER_PIXEL * 1.5: ext = 0.0
						if r1 < 0.27: pb += dir * ext - inward * ext * 0.55
						else: pa += -dir * ext - inward * ext * 0.55
				if organic:
					var mid := pa.lerp(pb, 0.5) - inward * radius * 0.035
					_cap_bone(cap, pa, mid, -inward, width, width * 1.3)
					_cap_bone(cap, mid, pb, -inward, width * 1.3, width * 0.65)
				else: _cap_rib(cap, pa, pb, -inward, width)


static func _cap_tri(cap: Dictionary, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var n := (b - a).cross(c - a)
	if not a.is_finite() or not b.is_finite() or not c.is_finite() or n.length_squared() < 1e-20: return
	n = n.normalized()
	cap["v"].append_array(PackedVector3Array([a, b, c]))
	cap["n"].append_array(PackedVector3Array([n, n, n]))
	cap["c"].append_array(PackedColorArray([color, color, color]))


static func _cap_rib(cap: Dictionary, a: Vector3, b: Vector3, n: Vector3, width: float) -> void:
	var along := b - a
	if along.length_squared() < 1e-12: return
	var side := along.normalized().cross(n) * width
	var lift := n * width * 1.8
	var p := [a - side, a + side, b + side, b - side, a - side + lift, a + side + lift, b + side + lift, b - side + lift]
	for f in [[0, 1, 2, 3], [4, 7, 6, 5], [0, 4, 5, 1], [1, 5, 6, 2], [2, 6, 7, 3], [3, 7, 4, 0]]:
		_cap_tri(cap, p[f[0]], p[f[1]], p[f[2]], Color(0.45, 0.1, 0, 1))
		_cap_tri(cap, p[f[0]], p[f[2]], p[f[3]], Color(0.45, 0.1, 0, 1))


static func _cap_bone(cap: Dictionary, a: Vector3, b: Vector3, n: Vector3, wa: float, wb: float) -> void:
	if a.distance_squared_to(b) < 1e-12: return
	var side := (b - a).normalized().cross(n).normalized()
	var up := side.cross((b - a).normalized())
	var ra := PackedVector3Array()
	var rb := PackedVector3Array()
	var col := Color(0.45, 0.0, 0.0, 1.0)
	for i in 6:
		var radial := side * cos(TAU * i / 6.0) + up * sin(TAU * i / 6.0)
		ra.append(a + radial * wa)
		rb.append(b + radial * wb)
	for i in 6:
		var j := (i + 1) % 6
		_cap_tri(cap, ra[i], ra[j], rb[j], col)
		_cap_tri(cap, ra[i], rb[j], rb[i], col)
	for i in range(1, 5):
		_cap_tri(cap, ra[0], ra[i + 1], ra[i], col)
		_cap_tri(cap, rb[0], rb[i], rb[i + 1], col)


# ---------------------------------------------------------------- the death

static func death(fx, s, cause: String) -> float:
	var t0 := Time.get_ticks_usec()
	var r = _death_inner(fx, s, cause)
	fx.pend("death", t0)
	return r


static func _death_inner(fx, s, cause: String) -> float:
	if s.dead: return 0.0
	s.dead = true
	var T: float = fx.now
	if s.has_meta("collider"):
		var cb: Node = s.get_meta("collider")
		if is_instance_valid(cb): cb.queue_free()
	var tint := Color(0.95, 0.34, 0.08) if cause != "melt" else Color(0.55, 0.65, 0.12)
	_power_down(s)
	s.set_meta("death_start", T)
	s.engine_level = 0.0
	if s.death_big:
		# The tell starts inside the ship: the drive flares about a third brighter for two frames, then goes black.
		s._eng_cur = maxf(s._eng_cur, 1.0) * 1.33
		s.set_meta("death_flare_until", T + 2.0 / 60.0)
	if s.faction == "chorus":
		# The skin ruptures under pressure and spills real hull fragments and spores.
		s.set_meta("death_organic", true)
		s.set_meta("death_hulk", false)
		s.set_meta("death_split", T + 0.35)
		s.set_meta("death_spore_next", T)
		if "_vel" in s.root: s.set_meta("death_velocity", s.root.get("_vel"))
		if not s.has_meta("cut_task") and not s.has_meta("cut_job"):
			precompute(fx, s, "rupture")
		fx.later(T + 0.35, func l_break_up() -> void: _break_up_when_ready(fx, s, "rupture", s.fac.damage_glow, T + 2.85))
		return 0.95
	# Explicit burn-outs retain their cold hulk. Ordinary kills always break up.
	var hulk := cause == "dark" or cause == "hulk"
	s.set_meta("death_hulk", hulk)
	if hulk:
		s.set_meta("death_split", T + 0.72)
		fx.later(T + 0.72, func l_hulk() -> void: _hulk(fx, s))
		return 1.32
	var timeline := DeathTimeline.new(s.death_big, int(s.get_meta("death_cut_count", 2)), s.death_tier, cause)
	s.set_meta("death_timeline", timeline)
	s.set_meta("death_split", T + timeline.cut)
	var inherited := Vector3.ZERO
	if "_vel" in s.root: inherited = s.root.get("_vel")
	s.set_meta("death_velocity", inherited)
	if cause == "cut" and s.death_big and s.faction != "chorus":
		_lance_recut(fx, s)
	if not s.has_meta("cut_task") and not s.has_meta("cut_job"):
		precompute(fx, s, cause)
	var job: Dictionary = s.get_meta("cut_job", {})
	var seeds: PackedVector3Array = job.get("seeds", PackedVector3Array())
	var at: Vector3 = (seeds[0] + seeds[1]) * 0.5 if seeds.size() >= 2 else s.hull.c
	var axis: Vector3 = (seeds[1] - seeds[0]).normalized() if seeds.size() >= 2 else Vector3.RIGHT
	var lines := _break_lines(job)
	if not lines.is_empty():
		at = lines[0][0]
		axis = lines[0][1]
	if s.death_big:
		_tell(fx, s, T, timeline, cause, seeds, lines)
	else:
		_cracks(fx, s, T + 0.06, timeline.vent + 0.10, Color(0.62, 0.73, 0.91), at, axis)
	var hit: Dictionary = s.hull.ray(at + Vector3.UP * s.hull.L, Vector3.DOWN)
	var lp: Vector3 = hit.get("p", at)
	var ln: Vector3 = hit.get("n", Vector3.UP)
	s.set_meta("death_tear", [lp, ln])
	fx.later(T + timeline.vent, func l_split_vent() -> void: _split_vent(fx, s, lp, ln))
	fx.later(T + timeline.cut, func l_break_up() -> void: _break_up_when_ready(fx, s, cause, tint, T + timeline.end))
	return timeline.end


# Death-only variation of the existing surface adapter. No R80 surface state changes.
# The running lights go out band by band: death_axis and death_span pick the direction (a cruiser bow to stern, a
# capital deck by deck from the top), death_steps holds (bands, delay per band, fade).
static func power_material(mat: ShaderMaterial) -> ShaderMaterial:
	var code: String = mat.shader.code
	code = code.replace("uniform float fx_power = 1.0;", "uniform float fx_power = 1.0;\nuniform float death_age = 0.0;\nuniform float death_start = 0.0;\nuniform vec2 death_span = vec2(0.0, 1.0);\nuniform vec3 death_axis = vec3(1.0, 0.0, 0.0);\nuniform vec3 death_steps = vec3(3.0, 0.055, 0.18);")
	var band := "floor(clamp((dot(fx_hull_p, death_axis) - death_span.x) / death_span.y, 0.0, 0.999) * death_steps.x) * death_steps.y"
	code = code.replace("clamp(fx_power, 0.0, 1.0)", "(1.0 - smoothstep(" + band + ", " + band + " + death_steps.z, death_age))")
	mat.shader = HULL.shared_shader(code)
	return mat


static func _power_down(s) -> void:
	var mats: Array = []
	var poses: Array = []
	var inv: Transform3D = s.root.global_transform.affine_inverse()
	for mesh in s.meshes:
		var mi := mesh as MeshInstance3D
		if not is_instance_valid(mi) or mi.mesh == null: continue
		poses.append({"mi": mi, "pose": inv * mi.global_transform})
		var prepared: Array = []
		for i in mi.mesh.get_surface_count():
			var source: Material = mi.get_active_material(i)
			var mat: ShaderMaterial
			if source is ShaderMaterial and source.has_meta("fx_hull_source"):
				mat = source.duplicate()
			else:
				mat = HULL.damage_material(source, inv * mi.global_transform, {}, s.hull.L, s.faction == "chorus")
			mat = power_material(mat)
			var box: AABB = s.hull.box
			if s.death_tier == "capital":
				# deck by deck, top to bottom
				mat.set_shader_parameter("death_axis", Vector3.DOWN)
				mat.set_shader_parameter("death_span", Vector2(-(box.position.y + box.size.y), maxf(box.size.y, 0.01)))
				mat.set_shader_parameter("death_steps", Vector3(5.0, 0.12, 0.15))
			elif s.death_tier == "cruiser":
				# bow (+X) to stern
				mat.set_shader_parameter("death_axis", Vector3.LEFT)
				mat.set_shader_parameter("death_span", Vector2(-(box.position.x + box.size.x), maxf(box.size.x, 0.01)))
				mat.set_shader_parameter("death_steps", Vector3(4.0, 0.06, 0.12))
			else:
				mat.set_shader_parameter("death_span", Vector2(box.position.x, s.hull.L))
			prepared.append(mat)
			mats.append(mat)
		mi.material_override = null
		for i in prepared.size(): mi.set_surface_override_material(i, prepared[i])
	s.set_meta("death_power", mats)
	s.set_meta("death_poses", poses)
	s._reacting = false
	s._shield_until = -1.0


static func _split_vent(fx, s, lp: Vector3, ln: Vector3) -> void:
	if not is_instance_valid(s.root) or s.has_meta("death_hidden") or fx.quality == "low": return
	# Issue 354: the gas root is the real plating, found the same way as the braking puffs since PR 327: cast from
	# outside, a further L along the tear normal, back toward the hull. A ray that misses has no plating behind it, so
	# skip the vent rather than float it beside the ship.
	var hit: Dictionary = s.hull.ray(lp + ln * s.hull.L, -ln)
	if hit.is_empty(): return
	if s.death_big:
		# issue 484: no pale vent puff beside a big hull (the issue 462 report); its first chain blast follows at once
		# and the tear's sparks stay.
		var pose_b: Transform3D = s.xf() * s.get_meta("death_motion", Transform3D.IDENTITY)
		tear_particles(fx, pose_b * (hit["p"] as Vector3), (pose_b.basis * (hit["n"] as Vector3)).normalized(), s.hull.L, s.get_meta("death_velocity", Vector3.ZERO), true)
		return
	var pose: Transform3D = s.xf() * s.get_meta("death_motion", Transform3D.IDENTITY)
	var p: Vector3 = pose * (hit["p"] as Vector3)
	var n: Vector3 = (pose.basis * (hit["n"] as Vector3)).normalized()
	var inherited: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
	var jet := flipbook(fx, p, n, s.hull.L * (0.35 if s.death_big else 0.85), "vent", 0.65 if s.death_big else 0.30, inherited + n * s.hull.L * 0.12, 1.3, atlas_band(s.hull.L), s, true)
	# The ignition and its light share one booking. Calm mode keeps dark gas. On a big hull the vent opens 0.04 s
	# before the first chain blast, so the two are one counted flash (FLASH_WINDOW).
	if fx.flash_ok(fx.now):
		(jet.material_override as ShaderMaterial).set_shader_parameter("ignition", 1.0)
		fx.light(p, fx.now, 0.10, 5.0, Color(0.7, 0.81, 1.0), 0)
	tear_particles(fx, p, n, s.hull.L, inherited)


static func _update_dying(fx, s) -> void:
	if not s.dead or s.has_meta("death_hidden") or not s.has_meta("death_start") or not is_instance_valid(s.root): return
	var age: float = maxf(fx.now - float(s.get_meta("death_start")), 0.0)
	var mats: Array = s.get_meta("death_power", [])
	for i in mats.size():
		var delay := float(i % 3) * 0.055
		(mats[i] as ShaderMaterial).set_shader_parameter("fx_power", 1.0 - smoothstep(delay, delay + 0.18, age))
		(mats[i] as ShaderMaterial).set_shader_parameter("death_age", age)
	if bool(s.get_meta("death_organic", false)):
		if fx.now >= float(s.get_meta("death_spore_next", INF)):
			s.set_meta("death_spore_next", fx.now + 0.06)
			var point: Dictionary = s.hull.random_sample(-1, 2.0)
			fx.spr(s.to_world(point.p), fx.now, 2.5, s.fac.damage_glow * Color(0.4, 0.5, 0.3), 0.35,
				s.hull.L * 0.015, s.hull.L * 0.13, 20, s.dir_world(point.n) * s.hull.L * 0.1, 0.65)
		return
	if bool(s.get_meta("death_hulk", false)): return
	var velocity: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
	var rot := Basis.IDENTITY if s.death_big else Basis.from_euler(Vector3(age * 0.22, age * 0.12, age * 0.18))
	var motion := Transform3D(rot, s.root.global_basis.inverse() * velocity * age + s.hull.c - rot * s.hull.c)
	if s.death_tier == "capital":
		# The capital's hull shudders through its tell (the ship itself, never the camera), harder after each blast.
		var tl: DeathTimeline = s.get_meta("death_timeline", null)
		if tl != null and age < tl.cut:
			var jolt: float = exp(-maxf(fx.now - float(s.get_meta("death_jolt", -10.0)), 0.0) / 0.12)
			var amp: float = s.hull.L * (0.0016 * smoothstep(0.2, 1.8, age) + 0.0035 * jolt)
			motion.origin += Vector3(sin(age * 57.0), sin(age * 71.0 + 1.3) * 0.5, sin(age * 63.0 + 2.1)) * amp
	s.set_meta("death_motion", motion)
	for pose in s.get_meta("death_poses", []):
		if is_instance_valid(pose["mi"]): (pose["mi"] as Node3D).global_transform = s.root.global_transform * motion * (pose["pose"] as Transform3D)


# An unfinished worker never blocks the death frame, even past its nominal split time.
# A previous completed cut is usable immediately; otherwise hold the dark dying hull.
static func _break_up_when_ready(fx, s, cause: String, tint: Color, deadline: float) -> void:
	if not is_instance_valid(s.root) or fx.ships.get(s.id) != s:
		return
	if s.has_meta("cut_task") and not s.has_meta("cut_prev"):
		if not WorkerThreadPool.is_task_completed(int(s.get_meta("cut_task"))):
			fx.later(fx.now + 0.05, func l_break_up() -> void: _break_up_when_ready(fx, s, cause, tint, deadline))
			return
	_break_up(fx, s, cause, tint)


# One thermal tear in ship coordinates, on the same bisector as the prepared halves.
static func _cracks(fx, s, t0: float, dur: float, tint: Color, at: Vector3, axis: Vector3) -> void:
	var m: ShaderMaterial = fx.mat(SH.CRACKS, 1)
	m.set_shader_parameter("t0", t0)
	m.set_shader_parameter("dur", maxf(dur, 0.3))
	m.set_shader_parameter("cut_at", at)
	m.set_shader_parameter("cut_axis", axis)
	m.set_shader_parameter("width", maxf(s.hull.L * 0.009, 0.01))
	m.set_shader_parameter("glow", Vector3(tint.r, tint.g, tint.b))
	for mm in s.meshes:
		if is_instance_valid(mm):
			var mi := mm as MeshInstance3D
			var local: ShaderMaterial = m.duplicate()
			local.set_shader_parameter("frame", s.root.global_transform.affine_inverse() * mi.global_transform)
			mi.material_overlay = local


# ---------------------------------------------------------------- issue 462: the tell, chain blasts, the aftermath

# The direction the tear grows in (hull space, across the break plane): from the side that was hit to the far side.
# The last hit is read from fx_ship.hit_react; with none (or an old one) it grows from starboard.
static func _grow_dir(fx, s, axis: Vector3) -> Vector3:
	var h = s.hull
	var side := Vector3(0.0, 0.0, float(h.stb_z))
	var last = s.get_meta("last_hit", [])
	if last is Array and last.size() >= 3 and fx.now - float(last[2]) < 2.0:
		side = (last[0] as Vector3) - h.c
	side -= axis * side.dot(axis)
	side.y *= 0.35   # the tear runs across the beam more than over the top
	if side.length() < 1e-3: side = Vector3(0.0, 0.0, 1.0)
	return -side.normalized()


# Beat 1. A glowing tear on the hull's break line(s), growing from the hit side, white-hot at its tip and ember behind;
# chain blasts walk along it behind the tip; a capital shudders. Older hulls have no authored break lines, so the line
# is the game's own cut plane (the bisector of the prepared pieces, issue 167's fallback).
static func _tell(fx, s, T: float, tl: DeathTimeline, cause: String, seeds: PackedVector3Array, lines: Array = []) -> void:
	var h = s.hull
	var at: Vector3 = (seeds[0] + seeds[1]) * 0.5 if seeds.size() >= 2 else h.c
	var axis: Vector3 = (seeds[1] - seeds[0]).normalized() if seeds.size() >= 2 else Vector3.RIGHT
	if not lines.is_empty():
		# issue 484: the tear runs on the fracture plan's tilted breaks (the bite's break first)
		at = lines[0][0]
		axis = lines[0][1]
	var g := _grow_dir(fx, s, axis)
	var half: float = absf(g.y) * h.H * 0.5 + absf(g.z) * h.W * 0.5 + absf(g.x) * h.L * 0.5 + 0.05
	s.set_meta("death_grow", [g, half, at, axis])
	var m: ShaderMaterial = (fx.dstate["tear_mat"] as ShaderMaterial).duplicate() if fx.dstate.has("tear_mat") else fx.mat(SH.TEAR, 1)
	m.set_shader_parameter("open_a", Vector2(T + tl.tear_open, T + tl.tear_full))
	m.set_shader_parameter("cut_at", at)
	m.set_shader_parameter("cut_axis", axis)
	if seeds.size() >= 3:
		# the second line of a capital opens a little later and finishes with the first
		var at_b: Vector3 = (seeds[1] + seeds[2]) * 0.5
		var axis_b: Vector3 = (seeds[2] - seeds[1]).normalized()
		if lines.size() >= 2:
			at_b = lines[1][0]
			axis_b = lines[1][1]
		m.set_shader_parameter("open_b", Vector2(T + tl.tear_open + 0.35, T + tl.tear_full))
		m.set_shader_parameter("cut_at_b", at_b)
		m.set_shader_parameter("cut_axis_b", axis_b)
		s.set_meta("death_line_b", [at_b, axis_b])
	m.set_shader_parameter("grow", g)
	m.set_shader_parameter("half_span", half)
	m.set_shader_parameter("width", maxf(h.L * 0.010, 0.02))
	if cause == "cut":
		m.set_shader_parameter("straight", 1.0)
		m.set_shader_parameter("ember", Vector3(1.0, 0.72, 0.45))
	elif cause == "melt":
		m.set_shader_parameter("tip", Vector3(0.62, 0.85, 0.18))
		m.set_shader_parameter("ember", Vector3(0.45, 0.62, 0.10))
	for mm in s.meshes:
		if is_instance_valid(mm):
			var mi := mm as MeshInstance3D
			var local: ShaderMaterial = m.duplicate()
			local.set_shader_parameter("frame", s.root.global_transform.affine_inverse() * mi.global_transform)
			mi.material_overlay = local
	for i in tl.chain.size():
		fx.later(T + float(tl.chain[i]), _chain_blast.bind(fx, s, i, tl, cause, T))


# The fracture plan's breaks as [at, normal] lines, the bite's break first; empty for the old seed cut.
static func _break_lines(job: Dictionary) -> Array:
	var plan: Dictionary = job.get("plan", {})
	if plan.is_empty(): return []
	var brs: Array = plan["breaks"]
	var out: Array = []
	var first := int(plan["bite_break"])
	if first < brs.size(): out.append([brs[first]["at"], brs[first]["n"]])
	for i in brs.size():
		if i != first: out.append([brs[i]["at"], brs[i]["n"]])
	return out


# Where a point of the tear sits on the plating: on line A (or B for a capital's odd blasts), at s_frac across.
static func _tear_point(s, s_frac: float, line_b: bool) -> Dictionary:
	var gm: Array = s.get_meta("death_grow", [])
	if gm.size() < 4: return {}
	var g: Vector3 = gm[0]
	var half: float = gm[1]
	var at: Vector3 = gm[2]
	var axis: Vector3 = gm[3]
	if line_b and s.has_meta("death_line_b"):
		at = s.get_meta("death_line_b")[0]
		axis = s.get_meta("death_line_b")[1]
	var q: Vector3 = at + g * half * s_frac
	var L: float = s.hull.L
	var hit: Dictionary = s.hull.ray(q + Vector3.UP * L, Vector3.DOWN)
	if hit.is_empty():
		hit = s.hull.ray(q - g * L, g)
	if hit.is_empty(): return {}
	# keep it on the line even where the ray met a tower to one side of it
	if absf(((hit["p"] as Vector3) - at).dot(axis)) > L * 0.08: return {}
	return hit


static func _chain_blast(fx, s, i: int, tl: DeathTimeline, cause: String, T: float) -> void:
	if not is_instance_valid(s.root) or s.has_meta("death_hidden") or fx.ships.get(s.id) != s: return
	var n_chain := tl.chain.size()
	var line_b: bool = s.has_meta("death_line_b") and i % 2 == 1
	# Behind the tear's tip (it moves from -1.15 to 1.15 of the half span between tear_open and tear_full); a lance cut
	# is drawn at once, so its blasts simply walk the line.
	var u: float = (float(tl.chain[i]) - tl.tear_open) / maxf(tl.tear_full - tl.tear_open, 0.01)
	var frac: float = clampf(-1.15 + 2.3 * u - 0.2, -0.85, 0.85)
	if cause == "cut" or line_b:
		frac = lerpf(-0.7, 0.7, (float(i) + 0.5) / float(n_chain))
	var hit := _tear_point(s, frac, line_b)
	if hit.is_empty():
		hit = _tear_point(s, frac * 0.5, line_b)
	if hit.is_empty(): return
	var pose: Transform3D = s.xf() * s.get_meta("death_motion", Transform3D.IDENTITY)
	var p: Vector3 = pose * (hit["p"] as Vector3)
	var n: Vector3 = (pose.basis * (hit["n"] as Vector3)).normalized()
	var melt := cause == "melt"
	# issue 484: the cruiser's chain blasts measured 24 to 57 px on the strip against a 75 px floor; drawn at 100 now
	_blast(fx, s, p, n, 100.0 if s.death_tier == "cruiser" else 84.0, Color(0.55, 0.65, 0.12) if melt else Color(1.0, 0.62, 0.28), pose, melt)
	# a narrow jet of fire, then gas, from the opened plating
	if fx.quality != "low":
		var inherited: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
		fx.spr(p + n * s.hull.L * 0.02, fx.now, 0.55, Color(0.95, 0.5, 0.18), 2.5, s.hull.L * 0.012, s.hull.L * 0.06, 20, inherited + n * s.hull.L * 0.25, 1.2)
	if s.death_tier == "capital":
		s.set_meta("death_jolt", fx.now)


# One staged picture from the route B pictures (the rebake of issue 426), sized in pixels at the battle camera. `frame`
# maps the source ship's own space to the world where the picture is born (a drifting wreck piece), for the stray guard.
static func _pic(fx, src, p: Vector3, rel: String, px: float, life: float, divisor: float, intensity: float, soft: bool, kind: String, frame = null, velocity := Vector3.ZERO, look := {}) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "fx_beat_" + kind
	mi.set_meta("fx_picture_kind", kind)
	mi.set_meta("gas_root", p)
	if frame is Transform3D: mi.set_meta("spawn_frame", frame)
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	mi.mesh = quad
	mi.extra_cull_margin = 100.0
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := route_material(fx, SH.DEATH_FLIPBOOK, rel, true, int(look.get("seed", -1)))
	mat.set_shader_parameter("pic_spin", float(look.get("spin", 0.0)))
	mat.set_shader_parameter("pic_shape", look.get("shape", Vector2.ONE))
	mat.set_shader_parameter("smoke_tone", float(look.get("tone", 1.0)))
	mat.set_shader_parameter("born", fx.now)
	mat.set_shader_parameter("lifetime", life)
	mat.set_shader_parameter("extent", px * STAGING_UNITS_PER_PIXEL)
	mat.set_shader_parameter("min_pixels", px)
	mat.set_shader_parameter("size_divisor", divisor)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("soft_flash", 1.0 if soft else 0.0)
	mat.set_shader_parameter("velocity", velocity)
	mi.material_override = mat
	fx.add_child(mi)
	mi.global_position = p
	fx.record_spawn(src, p, false, frame)
	fx.later(fx.now + life + 0.1, fx.free_effect.bind(weakref(mi)))
	return mi


# A chain blast or a secondary: a flash with a hot core (the torpedo flash picture, scaled to its row), fire seen through
# gas behind it, a light on the hull it sits on and a few sparks off the plating. A refused or reduce-flashing flash
# draws its softened twin at the same size (0.50 s rise and fall, no full-heat hold). `pale`: the melt look, no hard
# white (always the softened picture).
static func _blast(fx, src, p: Vector3, n: Vector3, px: float, tint: Color, frame = null, pale := false) -> void:
	if not p.is_finite(): return
	var soft: bool = pale or fx.reduce_flashing or not fx.flash_at(p, fx.now, px * STAGING_UNITS_PER_PIXEL, px, 0.16)
	_pic(fx, src, p, "weapons/impact/flash_", px, 0.50 if soft else 0.16, 0.97 if soft else 3.0, 1.25 if soft else 5.2, soft, "flash", frame)
	_smoke_clump(fx, src, p, n, px * 0.9, 0.70, frame, 0.06, 2, 3)
	fx.light(p + n * 0.6, fx.now, 0.40 if soft else 0.25, 5.0, tint, 0)
	if fx.quality != "low":
		var k: float = px * STAGING_UNITS_PER_PIXEL / 10.0
		for j in 5:
			fx.stk(p + n * 0.1, fx.now, 0.35 + fx.rng.randf() * 0.25, tint.lerp(Color(1, 0.9, 0.6), 0.4), 5.0, 0.05, 0.10, 1, fx.rcone(n, 0.7) * (8.0 + fx.rng.randf() * 10.0) * k, 2.0)


# Issue 484 (owner, Nov 11, on the secondaries: "the secondary explosion smoke looks a little too even and weird"). One
# body picture per blast drew the same round puff, the same size, born together round the hull. Now each blast's smoke
# is a small clump: two to four pictures, one large and the rest a third to two thirds of it, born at staggered times,
# all on the blast point (rule 4: it starts on the ship) but drifting at different speeds into one side of the blast,
# turned and stretched differently, some darker. The asymmetric baked seed (s0, "shards") is preferred; the round seeds
# are stretched when used. Seeded per ship, so a replay matches. Fire stays inside the cap: lives only shrink.
static func _death_rng(s) -> RandomNumberGenerator:
	if s == null or not (s is Object) or not s.has_method("set_meta"):
		return RandomNumberGenerator.new()
	if not s.has_meta("death_rng"):
		var r := RandomNumberGenerator.new()
		r.seed = hash(str(s.id)) + 101
		s.set_meta("death_rng", r)
	return s.get_meta("death_rng")


static func _smoke_clump(fx, src, p: Vector3, n: Vector3, px: float, life: float, frame, delay: float, lo: int, hi: int) -> void:
	if not p.is_finite(): return
	var r := _death_rng(src)
	var count := r.randi_range(lo, hi)
	var side := Vector3(r.randf_range(-1.0, 1.0), 0.0, r.randf_range(-1.0, 1.0))
	if side.length() < 0.1: side = Vector3.RIGHT
	side = (side - n * side.dot(n)).normalized()
	var units: float = px * STAGING_UNITS_PER_PIXEL
	for j in count:
		var size: float = px * (r.randf_range(0.85, 1.05) if j == 0 else r.randf_range(0.32, 0.68))
		var dir: Vector3 = (n * r.randf_range(0.3, 1.0) + side * r.randf_range(0.2, 1.1) + fx.rdir() * 0.25).normalized()
		var vel: Vector3 = dir * units * r.randf_range(0.10, 0.45) / maxf(life, 0.3)
		# the round baked seeds (s1, s2) read as a flower of equal puffs: the big picture is always the lopsided s0, and
		# only a small one may use a round seed, stretched
		var seed_i: int = 0 if (j == 0 or r.randf() < 0.75) else r.randi_range(1, 2)
		var look := {"seed": seed_i, "spin": r.randf() * TAU, "tone": r.randf_range(0.5, 1.3),
			"shape": Vector2(r.randf_range(1.2, 1.6), r.randf_range(0.6, 0.85)) if seed_i != 0 else Vector2(r.randf_range(0.85, 1.25), r.randf_range(0.85, 1.25))}
		var t: float = delay + (0.0 if j == 0 else r.randf_range(0.04, 0.32))
		var l: float = life * r.randf_range(0.75, 1.0)
		fx.later(fx.now + t, _smoke_one.bind(fx, src, p, size, l, frame, vel, look))


static func _smoke_one(fx, src, p: Vector3, px: float, life: float, frame, vel: Vector3, look: Dictionary) -> void:
	_pic(fx, src, p, "weapons/impact/impact_", px, life, 0.80, 2.0, false, "impact", frame, vel, look)


# Beat 2's flash: 0.28 s after the break, on the lip of the torn face. The core (route B, the tier's own row), the body
# (fire seen through gas, at most 0.70 s of fire, then gas that thins and drifts), shrapnel streamers along the plane of
# the break (a torpedo or ram: in a cone away from the impact) and, behind a switch, the capital's scene dim.
static func _big_core(fx, s, node_ref: WeakRef, local: Vector3, R: float, tint: Color, cause: String, tl: DeathTimeline) -> void:
	var node := node_ref.get_ref() as Node3D
	if not is_instance_valid(node) or node.is_queued_for_deletion(): return
	var p: Vector3 = node.to_global(local)
	var frame: Transform3D = node.global_transform * Transform3D(Basis.IDENTITY, -(node.get_meta("piece_cen", Vector3.ZERO) as Vector3))
	var capital := tl.tier == "capital"
	_core_flash(fx, p, R, 70.0, tint, null, Vector3.ZERO, s, tl.tier, frame)
	var body_px := 380.0 if capital else 260.0
	# light first, then matter: the body is born as the core's full heat ends, so its smoke never covers the flash
	var away_l: Vector3 = (s.get_meta("death_grow", [Vector3.UP])[0] as Vector3)
	var away_w: Vector3 = (s.xf().basis * away_l).normalized() if away_l.length() > 0.01 else Vector3.UP
	_smoke_clump(fx, s, p, (away_w + Vector3.UP * 0.5).normalized(), body_px, 2.0 if capital else 1.6, frame, 0.12, 3, 3)
	if fx.quality != "low":
		var gas := flipbook(fx, p, Vector3.UP, s.hull.L * (0.8 if capital else 0.7), "cool", 3.6 if capital else 3.0, s.get_meta("death_velocity", Vector3.ZERO) * 0.5, 0.38, atlas_band(s.hull.L), null)
		(gas.material_override as ShaderMaterial).set_shader_parameter("born", fx.now + 0.45)
		gas.set_meta("spawn_frame", frame)
		fx.record_spawn(s, p, false, frame)
		var gm: Array = s.get_meta("death_grow", [])
		var axis_w: Vector3 = (s.xf().basis * (gm[3] as Vector3)).normalized() if gm.size() >= 4 else s.xf().basis.x
		var away: Vector3 = (s.xf().basis * (gm[0] as Vector3)).normalized() if gm.size() >= 4 else Vector3.FORWARD
		var L: float = s.hull.L
		for j in (22 if capital else 16):
			var d: Vector3
			if cause == "big":
				d = fx.rcone(away, 0.55)
			else:
				d = fx.rdir()
				d = (d - axis_w * d.dot(axis_w)).normalized()
			fx.stk(p, fx.now + fx.rng.randf() * 0.05, 0.6 + fx.rng.randf() * 0.5, Color(1.0, 0.62, 0.3), 6.0, 0.06, maxf(L * 0.004, 0.05), 1, d * L * fx.rng.randf_range(0.6, 1.3), 0.8, 0.0, 2.0, 10.0)
	if capital:
		fx.dim_scene(fx.now + 0.20)


# Beat 3: secondaries on each piece, each lighting its own piece. They go off in groups, one per piece, 0.05 s apart,
# so a group counts as one flash (FLASH_WINDOW) and the budget keeps them bright; any the budget turns down draw soft.
static func _schedule_secondaries(fx, s, wreck: Dictionary, pieces: Array, seeds: PackedVector3Array, T: float, tl: DeathTimeline) -> void:
	var nodes: Array = wreck["nodes"]
	if nodes.is_empty() or tl.secondaries <= 0: return
	var h = s.hull
	var per: int = ceili(float(tl.secondaries) / float(nodes.size()))
	var groups: int = maxi(per, 1)
	var made := 0
	for j in nodes.size():
		var node: Node3D = nodes[j]
		var sites: PackedVector3Array = node.get_meta("sec_sites", PackedVector3Array())
		if sites.is_empty(): continue
		for k in groups:
			if made >= tl.secondaries: break
			# issue 484: not an even beat; each group lands up to 40 percent of a step early or late (seeded per ship)
			var step_t: float = (tl.sec_to - tl.sec_from) / maxf(groups - 1, 1)
			var jit: float = _death_rng(s).randf_range(-0.4, 0.4) * step_t if k > 0 else _death_rng(s).randf_range(0.0, 0.3) * step_t
			var t := T + tl.sec_from + step_t * k + jit + j * 0.05
			fx.later(t, _secondary_on.bind(fx, s, weakref(node), sites[k % sites.size()]))
			made += 1


# Up to five sites on one piece's own plating, facing up toward the battle camera, spread apart.
static func _piece_sites(h, seeds: PackedVector3Array, cen: Vector3, count: int, plan := {}, index := -1) -> PackedVector3Array:
	return _piece_sites_in(h.sp, h.sn, seeds, cen, count, plan, index)


# The same on plain arrays, so the worker cut can do it ahead of the death (issue 484 profiling: 2.4 ms per big break on
# the death frame in the sandbox).
static func _piece_sites_in(sp: PackedVector3Array, sn: PackedVector3Array, seeds: PackedVector3Array, cen: Vector3, count: int, plan := {}, index := -1) -> PackedVector3Array:
	var own := 0
	var best := INF
	for i in seeds.size():
		var d := cen.distance_to(seeds[i])
		if d < best:
			best = d
			own = i
	if not plan.is_empty() and index >= 0: own = index
	var cand := PackedVector3Array()
	for i in range(0, sp.size(), maxi(1, sp.size() / 400)):
		var q: Vector3 = sp[i]
		if sn[i].y < 0.25: continue
		var mine := 0
		if not plan.is_empty():
			# issue 484: the plan's own pieces; never a site in the bite (that plating is gone)
			if _plan_assign(plan, q) != _plan_main(plan, q): continue
			mine = _plan_main(plan, q)
		else:
			var bd := INF
			for k in seeds.size():
				var d := q.distance_to(seeds[k])
				if d < bd:
					bd = d
					mine = k
		if mine == own or seeds.size() < 2: cand.append(q)
	var out := PackedVector3Array()
	if cand.is_empty(): return out
	if plan.is_empty():
		out.append(cand[cand.size() / 2])
		while out.size() < count and out.size() < cand.size():
			var far := cand[0]
			var fd := -1.0
			for q in cand:
				var nd := INF
				for o in out: nd = minf(nd, q.distance_to(o))
				if nd > fd:
					fd = nd
					far = q
			out.append(far)
		return out
	# issue 484: not spread as far apart as possible (that made an even ring of blasts); random plating, seeded by the
	# piece, so blasts come in clumps and gaps
	var r := RandomNumberGenerator.new()
	r.seed = hash(Vector3i((cen * 100.0).round())) + index
	while out.size() < count:
		out.append(cand[r.randi_range(0, cand.size() - 1)])
	return out


static func _secondary_on(fx, s, node_ref: WeakRef, ship_p: Vector3) -> void:
	var node := node_ref.get_ref() as Node3D
	if not is_instance_valid(node) or node.is_queued_for_deletion(): return
	var frame: Transform3D = node.global_transform * Transform3D(Basis.IDENTITY, -(node.get_meta("piece_cen", Vector3.ZERO) as Vector3))
	var p: Vector3 = frame * ship_p
	# issue 484: secondaries vary plainly in size (the playbook floor is 75 px)
	_blast(fx, s, p, frame.basis.y.normalized(), _death_rng(s).randf_range(76.0, 140.0), Color(1.0, 0.6, 0.26), frame)


static func _hide_ship(s) -> void:
	s.set_meta("death_hidden", true)
	s.remove_meta("death_power")
	s.remove_meta("death_poses")
	for m in s.meshes:
		if is_instance_valid(m):
			(m as Node3D).visible = false
	if is_instance_valid(s._eng_node):
		s._eng_node.visible = false
	if is_instance_valid(s._dmg_root):
		s._dmg_root.visible = false
	for sec in 3:
		s._clear_lights(sec)
	for l in s._hole_lights:
		l["on"] = false
	s._hole_lights = []
	for t in s._trails:
		if is_instance_valid(t["mi"]):
			(t["mi"] as Node3D).visible = false


# One independent copy of the damaged hull, no fracture upload, fire or lights.
# G2 may release its live ship root as soon as death()'s returned time expires.
static func _hulk(fx, s) -> void:
	if not is_instance_valid(s.root) or fx.ships.get(s.id) != s or s.has_meta("death_hidden"): return
	var node := Node3D.new()
	node.name = "fx_hulk_" + s.id
	fx.phys_root.add_child(node)
	node.global_transform = s.xf()
	for source in s.meshes:
		var original := source as MeshInstance3D
		if not is_instance_valid(original) or original.mesh == null: continue
		var copy := MeshInstance3D.new()
		copy.mesh = original.mesh
		node.add_child(copy)
		copy.global_transform = original.global_transform
		for i in original.mesh.get_surface_count():
			var mat: ShaderMaterial = original.get_active_material(i).duplicate()
			mat.set_shader_parameter("fx_power", 0.0)
			copy.set_surface_override_material(i, mat)
	# Keep the opaque wound backs and rims after the live ship is released.
	# Do not copy pooled lights, sparks or the live ship's other emitters.
	for child in s._dmg_root.get_children():
		if child is MeshInstance3D and child.name in ["fx_damage_inside", "fx_damage_marks"]:
			var copy := MeshInstance3D.new()
			copy.name = child.name
			copy.mesh = child.mesh
			copy.material_override = child.material_override
			copy.cast_shadow = child.cast_shadow
			node.add_child(copy)
			copy.global_transform = child.global_transform
	_hide_ship(s)
	var drift := node.basis.x * 0.45
	drift.y = 0.0
	var wreck := {"id": s.id, "t0": fx.now, "nodes": [node], "mats": [], "lights": [],
		"fires": [{"node": node, "vel": drift, "ang": Vector3(0.01, 0.035, 0.015)}], "speed": 1.0, "hulk": true}
	var hit: Dictionary = s.hull.ray(s.hull.c + Vector3.UP * maxf(s.hull.L, 1.0), Vector3.DOWN)
	var p: Vector3 = hit.get("p", s.hull.c + Vector3.UP * s.hull.H * 0.5)
	var n: Vector3 = hit.get("n", Vector3.UP)
	var b := POOLS.Batch.new()
	var size: float = maxf(s.hull.L * 0.025, 0.06)
	for j in 9:
		var v := n * size * 8.0
		b.add(POOLS.quad_shape(), POOLS.pack(Vector4(p.x, p.y, p.z, fx.now + j * 0.13),
			Vector4(v.x, v.y, v.z, 1.7), Vector4(0.22, 0.32, 0.06, 0.3) if s.faction == "chorus" else Vector4(0.42, 0.46, 0.5, 0.5),
			Vector4(size * 0.4, size * 3.2, 20 if s.faction == "chorus" else 7, 16.3), Vector4(0, 0, 0.5, 0)))
	b.build(fx.mat(SH.SPRITE, 1), node, "fx_hulk_vent")
	fx.dstate["wrecks"].append(wreck)
	_cap_wrecks(fx)


static func _break_up(fx, s, cause: String, tint: Color) -> void:
	var t0 := Time.get_ticks_usec()
	_break_up_inner(fx, s, cause, tint)
	fx.pend("break_up", t0)


static func _break_up_inner(fx, s, cause: String, tint: Color) -> void:
	var T: float = fx.now
	var h = s.hull
	var w: int = s.weight
	var k: float = s.scale_k()
	var organic: bool = s.faction == "chorus"
	var center: Vector3 = s.to_world(h.c)
	var job: Dictionary = s.get_meta("cut_job", {})
	if s.has_meta("cut_task"):
		var tid: int = int(s.get_meta("cut_task"))
		if not WorkerThreadPool.is_task_completed(tid) and s.has_meta("cut_prev"):
			# r18: a fresher cut is still running; break up along the last finished one (a little out of date, never a
			# stall) and collect the running task when it is done
			job = s.get_meta("cut_prev")
			_collect_later(fx, tid)
		else:
			WorkerThreadPool.wait_for_task_completion(tid)
		s.remove_meta("cut_task")
	var pieces: Array = job.get("out", []) if job.get("out") != null else []
	var seeds: PackedVector3Array = job.get("seeds", PackedVector3Array())
	var plan: Dictionary = job.get("plan", {})
	var n_main: int = int(plan["n_main"]) if not plan.is_empty() else pieces.size()
	n_main = mini(n_main, pieces.size())
	var xf: Transform3D = s.xf() * s.get_meta("death_motion", Transform3D.IDENTITY)
	center = xf * h.c
	_hide_ship(s)
	var R: float = h.L * 0.16
	var inherited: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
	if organic:
		_organic_spill(fx, center, h.L, tint)
	else:
		spawn_debris(fx, center, inherited, 4 + w * 3, h.L * 0.025)
	fx.punch(T, 0.018 if s.death_big else 0.006, center)
	fx.shake(T, 0.45 if s.death_big else 0.18, center)
	# the pieces: real parts of the hull, as rigid bodies that drift and burn
	var wreck = {"id": s.id, "t0": T, "nodes": [], "mats": [], "lights": [], "fires": [], "speed": 1.0, "organic": organic, "heat_births": {}, "cut_events": []}
	var main_i = -1
	var main_n = -1
	for i in n_main:
		if int(pieces[i]["n"]) > main_n:
			main_n = int(pieces[i]["n"])
			main_i = i
	var phys = bool(fx.dstate.get("physics_on", false))
	wreck["frags"] = []
	wreck["scorch_mats"] = []
	for i in n_main:
		var pc: Dictionary = pieces[i]
		if (pc["surfs"] as Array).is_empty():
			continue
		var pre: Array = job.get("meshes", [])
		var geo: Array = job.get("geo", [])
		var am: ArrayMesh = pre[i] if i < pre.size() else (_piece_materials(geo[i], pc) if i < geo.size() else _piece_mesh(pc))
		var cen: Vector3 = pc["cen"] if pc.has("cen") else Vector3.ZERO
		if not pc.has("cen"):
			for p in (pc["pts"] as PackedVector3Array):
				cen += p
			cen /= maxf((pc["pts"] as PackedVector3Array).size(), 1)
		var node: Node3D
		var is_main = i == main_i
		if phys:
			var rb = RigidBody3D.new()
			rb.gravity_scale = 0.0
			rb.axis_lock_linear_y = true
			# Lock altitude at the chosen piece centre while its uneven shape tumbles.
			rb.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
			rb.mass = maxf(float(pc["n"]) / 400.0, 5.0)
			rb.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
			rb.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
			rb.linear_damp = 0.0
			rb.angular_damp = 0.0
			rb.freeze = s.death_big and not organic
			rb.collision_layer = DEBRIS_LAYER
			rb.collision_mask = HULL_LAYER | DEBRIS_LAYER
			rb.physics_material_override = fx.dstate["bounce"]
			var pts: PackedVector3Array = pc["hull"] if pc.has("hull") else PackedVector3Array()
			if not pc.has("hull"):
				for p in (pc["pts"] as PackedVector3Array):
					pts.append(p - cen)
			if pts.size() >= 4:
				var cs = CollisionShape3D.new()
				cs.shape = pc["shape"] if pc.has("shape") else safe_convex(pts)
				rb.add_child(cs)
			node = rb
		else:
			node = Node3D.new()
		node.name = "fx_wreck_%s_%d" % [s.id, i]
		fx.phys_root.add_child(node)
		node.global_transform = Transform3D(xf.basis, xf * cen)
		node.set_meta("piece_cen", cen)
		if s.death_big and not organic:
			node.set_meta("sec_sites", pc["sec_sites"] if pc.has("sec_sites") else _piece_sites(h, seeds, cen, 5, plan, i))
		wreck["scorch_mats"].append_array(pc.get("hull_mats", []))
		if not plan.is_empty() and not (plan["breaks"] as Array).is_empty():
			# issue 484: the seam this piece's torn face belongs to (the bite's break where it has one)
			var brs: Array = plan["breaks"]
			var seam_b: int = clampi(int(plan["bite_break"]) if i in [int(plan["bite_break"]), int(plan["bite_break"]) + 1] else mini(i, brs.size() - 1), 0, brs.size() - 1)
			pc["split_at"] = brs[seam_b]["at"]
			pc["split_axis"] = brs[seam_b]["n"]
			pc["split_width"] = h.L * 0.12
		elif s.death_big and not organic and seeds.size() >= 2:
			var seam := mini(i, seeds.size() - 2)
			pc["split_at"] = (seeds[seam] + seeds[seam + 1]) * 0.5
			pc["split_axis"] = (seeds[seam + 1] - seeds[seam]).normalized()
			pc["split_width"] = h.L * 0.04
		var mi = MeshInstance3D.new()
		mi.mesh = am
		mi.position = -cen
		node.add_child(mi)
		var piece_mats: Array = []
		if pc.has("cap_mat"):
			(pc["cap_mat"] as ShaderMaterial).set_shader_parameter("heat", 0.0)
			# Issue 462: a big hull's torn face shows its decks glowing, not only the rim.
			(pc["cap_mat"] as ShaderMaterial).set_shader_parameter("face_glow", 1.0 if s.death_big and not organic else 0.0)
			if fx.quality != "low" and not organic: piece_mats.append(pc["cap_mat"])
		wreck["mats"].append_array(piece_mats)
		wreck["nodes"].append(node)
		var face_view := Vector3(0, 1, 1).normalized()
		if is_instance_valid(fx.camera): face_view = node.to_local(fx.camera.global_position).normalized()
		node.set_meta("tear_site", _edge_sites(pc, cen, face_view, 1)[0] + face_view * h.L * 0.02)
		# Separate on the board plane while allowing each piece to tumble freely.
		var out: Vector3 = cen - h.c
		out.y = 0.0
		out = out.normalized() if out.length() > 0.01 else Vector3.RIGHT
		if organic:
			# Alternating lateral jets open the body as well as separating its length.
			out = (out + Vector3(0, 0, 0.9 if i % 2 == 0 else -0.9)).normalized()
		var spd: float = (3.5 if organic else ((1.6 if s.death_tier == "capital" else 2.8) if s.death_big else (0.7 if is_main else 2.1))) * maxf(k, 0.5)
		var vel: Vector3 = inherited + xf.basis * (out * spd) + fx.rdir() * 0.3 * k
		if cause == "tidal" and fx.well != Vector3.INF:
			vel += (fx.well - center).normalized() * 3.0 * k
		vel.y = 0.0
		# issue 484: the biggest piece of a big hull turns slowly, so it stays readable as the ship's main wreck
		var ang: Vector3 = fx.rdir() * ((0.14 if is_main else 0.35) if s.death_big else (1.1 if is_main else 1.6))
		if s.death_big and not organic:
			# Issue 461 (Board, on 484's cruiser at 6.0 s: "the big bow piece reads dim"): the main pieces tumbled on a
			# random axis and by 6 s showed the key light their dark bellies. They now turn mostly about the vertical, with
			# a slight roll and pitch, so their plated tops stay lit while they drift and turn.
			ang = Vector3(ang.x * 0.25, signf(ang.y + 0.001) * maxf(absf(ang.y), 0.08), ang.z * 0.25)
		var release_delay := 0.0
		if s.death_big and not organic:
			var timeline: DeathTimeline = s.get_meta("death_timeline")
			release_delay = mini(i, n_main - 2) * timeline.spacing
		var release_t := T + release_delay
		if node is RigidBody3D:
			if release_delay <= 0.0:
				_release_section(fx, wreck, node, vel, ang, piece_mats, h.L, s.death_big, i, s)
			else:
				wreck["fires"].append({"node": node, "vel": inherited, "ang": Vector3.ZERO, "until": release_t})
				fx.later(release_t, _release_section.bind(fx, wreck, node, vel, ang, piece_mats, h.L, true, i, s))
		else:
			wreck["fires"].append({"node": node, "vel": inherited, "ang": Vector3.ZERO, "until": release_t})
			fx.later(release_t, _release_section.bind(fx, wreck, node, vel, ang, piece_mats, h.L, s.death_big, i, s))
		if organic:
			if pc.has("cap_mat"):
				(pc["cap_mat"] as ShaderMaterial).set_shader_parameter("heat", 0.0)
			# Spores spill from the torn faces without metal sparks or burning plates.
			var sites := _edge_sites(pc, cen, Vector3(0, 1, 1).normalized(), 2)
			for site in sites:
				_organic_spill(fx, node.to_global(site), h.L * 0.35, tint)

	if s.death_big and not organic and s.has_meta("death_timeline"):
		wreck["cool"] = (s.get_meta("death_timeline") as DeathTimeline).cool
	fx.dstate["wrecks"].append(wreck)
	_cap_wrecks(fx)
	if organic:
		return
	if s.death_big and s.has_meta("death_timeline") and not wreck["nodes"].is_empty():
		# Beat 2: the core flash comes 0.28 s after the halves part, at the lip of the torn face; then beat 3.
		var tl: DeathTimeline = s.get_meta("death_timeline")
		var lip: Node3D = wreck["nodes"][0]
		var local: Vector3 = lip.get_meta("tear_site", Vector3.ZERO)
		if not plan.is_empty():
			# issue 484: the core goes off in the bite, on the piece nearest it; the bite's fragments and a cloud of
			# plates fly out from there.
			var bc: Vector3 = plan["bite"]["c"]
			var bd := INF
			for nd in wreck["nodes"]:
				var dd: float = (nd.get_meta("piece_cen", Vector3.ZERO) as Vector3).distance_to(bc)
				if dd < bd:
					bd = dd
					lip = nd
			local = bc - (lip.get_meta("piece_cen", Vector3.ZERO) as Vector3)
			_make_frags(fx, s, wreck, pieces, n_main, xf, inherited, T, T + tl.core_delay)
			fx.later(T + tl.core_delay, _throw_frags.bind(fx, s, wreck, plan, weakref(lip), tl))
		fx.later(T + tl.core_delay, _big_core.bind(fx, s, weakref(lip), local, R, tint, cause, tl))
		_schedule_secondaries(fx, s, wreck, pieces, seeds, T, tl)
		return
	var flash_site := center
	if not wreck["nodes"].is_empty():
		var lip: Node3D = wreck["nodes"][0]
		flash_site = lip.to_global(lip.get_meta("tear_site", Vector3.ZERO))
	_core_flash(fx, flash_site, R, 70.0, tint, null, Vector3.ZERO, s)
	if pieces.is_empty():
		# Craft have no pre-cut job. Keep one pooled physical shard plus a visible ember.
		spawn_debris(fx, center, xf.basis.x * 2.0, 1, maxf(h.L * 0.15, 0.3))
		fx.spr(center, T, 5.0, tint, 1.2, R * 0.3, R * 0.05, 19, xf.basis.x * 2.0, 0.25, 0.0, 0.0, 12.0)


# Issue 484: the bite's fragments and the chips along the break, as real pieces of the hull (capped, glowing faces,
# scorched plating). They ride with the wreck until the core flash, then fly out from the bite, tumbling fast. They
# are kinematic (no physics bodies): the 20-death fleet probe keeps its collider count.
static func _make_frags(fx, s, wreck: Dictionary, pieces: Array, n_main: int, xf: Transform3D, inherited: Vector3, T: float, hold_until: float) -> void:
	var job: Dictionary = s.get_meta("cut_job", {})
	var pre: Array = job.get("meshes", [])
	var geo: Array = job.get("geo", [])
	for i in range(n_main, pieces.size()):
		var pc: Dictionary = pieces[i]
		if (pc["surfs"] as Array).is_empty(): continue
		var am: ArrayMesh = pre[i] if i < pre.size() else (_piece_materials(geo[i], pc) if i < geo.size() else _piece_mesh(pc))
		var cen: Vector3 = pc["cen"] if pc.has("cen") else Vector3.ZERO
		var node := Node3D.new()
		node.name = "fx_wreck_frag_%s_%d" % [s.id, i]
		fx.phys_root.add_child(node)
		node.global_transform = Transform3D(xf.basis, xf * cen)
		node.set_meta("piece_cen", cen)
		node.set_meta("chip", i >= n_main + int(job.get("plan", {}).get("bite", {}).get("subs", PackedVector3Array()).size()))
		var mi := MeshInstance3D.new()
		mi.mesh = am
		mi.position = -cen
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(mi)
		if pc.has("cap_mat"):
			var cm := pc["cap_mat"] as ShaderMaterial
			cm.set_shader_parameter("heat", 0.0)
			cm.set_shader_parameter("face_glow", 0.5)
			if fx.quality != "low":
				wreck["mats"].append(cm)
				# small fragments start past white heat and go dark in about half the big pieces' time
				wreck["heat_births"][cm] = T - float(wreck.get("cool", WRECK_COOL)) * 0.35
		wreck["scorch_mats"].append_array(pc.get("hull_mats", []))
		wreck["frags"].append(node)
		wreck["fires"].append({"node": node, "vel": inherited, "ang": Vector3.ZERO, "until": hold_until})


static func _throw_frags(fx, s, wreck: Dictionary, plan: Dictionary, lip_ref: WeakRef, tl: DeathTimeline) -> void:
	var lip := lip_ref.get_ref() as Node3D
	if not is_instance_valid(lip) or lip.is_queued_for_deletion(): return
	var frame: Transform3D = lip.global_transform * Transform3D(Basis.IDENTITY, -(lip.get_meta("piece_cen", Vector3.ZERO) as Vector3))
	var bite: Dictionary = plan["bite"]
	var bc: Vector3 = bite["c"]
	var out_l: Vector3 = bite["out"]
	var L: float = s.hull.L
	var inherited: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
	for nd in wreck["frags"]:
		if not is_instance_valid(nd): continue
		var cen: Vector3 = nd.get_meta("piece_cen", Vector3.ZERO)
		var chip: bool = nd.get_meta("chip", false)
		var d: Vector3 = (cen - bc).normalized() * 0.6 + out_l * (0.5 if chip else 1.0)
		d += Vector3(fx.rng.randf_range(-0.3, 0.3), 0.0, fx.rng.randf_range(-0.3, 0.3))
		var dw: Vector3 = (frame.basis * d).normalized()
		dw.y *= 0.25
		var v: Vector3 = inherited + dw.normalized() * L * fx.rng.randf_range(0.16, 0.34) * (0.7 if chip else 1.0)
		# they fly for 8 s (a few hull lengths, well spread), then rest, so a long battle does not move them forever
		wreck["fires"].append({"node": nd, "vel": v, "ang": fx.rdir() * fx.rng.randf_range(1.2, 3.0), "until": fx.now + 8.0, "frag": true})
	# a cloud of torn plates of several sizes, spreading and thinning between the pieces; born just outside the bite, so
	# the plates (physics bodies) never start inside a wreck piece's collider and kick it into a spin
	var p: Vector3 = frame * (bc + out_l * float(bite["ry"]) * 1.2)
	var big := tl.tier == "capital"
	# Issue 484 profiling: each plate is a physics body; keep the cloud lean (it adds to the plates at the break)
	spawn_debris(fx, p, inherited, 10 if big else 7, L * 0.012)
	spawn_debris(fx, p, inherited, 4 if big else 3, L * 0.03)


# A fast radial spill of luminous spores and darker membrane clots, near the board.
static func _organic_spill(fx, p: Vector3, L: float, tint: Color) -> void:
	for i in 16:
		var angle: float = TAU * (i + fx.rng.randf() * 0.5) / 16.0
		var dir := Vector3(cos(angle), fx.rng.randf_range(0.0, 0.12), sin(angle))
		var speed: float = L * fx.rng.randf_range(0.2, 0.45)
		fx.spr(p, fx.now, 1.0 + fx.rng.randf() * 0.8, tint, 1.5,
			L * 0.018, L * 0.006, 19, dir * speed, 0.5, 0.0, 0.0, 6.0)
		if i % 2 == 0:
			fx.spr(p, fx.now, 1.4, tint * Color(0.24, 0.3, 0.18), 0.65,
				L * 0.025, L * 0.06, 20, dir * speed * 0.65, 0.7)
	fx.spr(p, fx.now, 0.45, tint, 1.8, L * 0.025, L * 0.16, 20, Vector3.ZERO, 0.0, 0.0, 0.0, 28.0)


# Issue 461: how far a death's core flash lights the hulls round it (world units; hexes are 17.3 across).
const CORE_LIGHT_REACH := {"small": 26.0, "cruiser": 35.0, "capital": 52.0}


static func _core_flash(fx, p: Vector3, R: float, px: float, tint: Color, node: Node3D = null, local_p := Vector3.ZERO, src = null, band_override := "", frame = null) -> void:
	if is_instance_valid(node): p = node.to_global(local_p)
	if not p.is_finite() or R <= 0.0: return
	# Main core flashes use the approved row. Issue 462: a cruiser or capital death uses its class's row
	# (band_override), whatever its drawn length.
	var staged: bool = px >= 70.0 and (src == null or not src.squadron)
	var band := atlas_band(float(src.hull.L) if src != null else R / 0.16)
	if band_override != "": band = band_override
	# Pixel targets, normal/soft life, then normal/soft size calibration including the battle look's bloom.
	var row: Array = {"small": [216.0, 0.18, 0.55, 2.45, 0.96], "cruiser": [302.0, 0.20, 0.60, 1.97, 0.96], "capital": [423.0, 0.22, 0.65, 1.37, 0.96]}[band]
	if staged: px = float(row[0])
	var allowed: bool = fx.flash_ok(fx.now, p, px * STAGING_UNITS_PER_PIXEL if staged else R * 3.0, px, float(row[1]))
	if staged:
		var soft: bool = fx.reduce_flashing or not allowed
		var life: float = float(row[2] if soft else row[1])
		var flash := flipbook(fx, p, Vector3.UP, 0.0, "flash", life, Vector3.ZERO, 1.25 if soft else 6.0, band, src, false, true, frame)
		var mat := flash.material_override as ShaderMaterial
		mat.set_shader_parameter("min_pixels", px)
		mat.set_shader_parameter("extent", px * STAGING_UNITS_PER_PIXEL)
		mat.set_shader_parameter("size_divisor", float(row[4] if soft else row[3]))
		mat.set_shader_parameter("soft_flash", 1.0 if soft else 0.0)
		# Issue 461 (audit item 11): the core flash lights the hulls round it, about two hexes for a cruiser and three for
		# a capital, for the length of the flash (deaths_and_hits.md, beat 2)
		if not fx.reduce_flashing: fx.light(p, fx.now, float(row[1]), 9.0, Color(0.65, 0.75, 0.91), 0, CORE_LIGHT_REACH[band])
		return
	# Only this booking can produce a bright baked flash or its event light.
	if allowed:
		var flash := flipbook(fx, p, Vector3.UP, R * 3.0, "flash", 0.20, Vector3.ZERO, 6.0, atlas_band(R / 0.16), src)
		(flash.material_override as ShaderMaterial).set_shader_parameter("min_pixels", px)
		fx.light(p, fx.now, 0.12, 9.0, Color(0.65, 0.75, 0.91), 0, CORE_LIGHT_REACH[band])
	else:
		flipbook(fx, p, Vector3.UP, R * 2.8, "cool", 0.65, Vector3.ZERO, 0.5, atlas_band(R / 0.16), src)


# A released section has its own cooling clock. Neighbouring sections remain
# attached until their cut beat. The last cut releases the final pair together.
static func _release_section(fx, wreck: Dictionary, node: Node3D, vel: Vector3, ang: Vector3, mats: Array, L: float, big: bool, index: int, src = null) -> void:
	if not is_instance_valid(node) or node.is_queued_for_deletion(): return
	if node is RigidBody3D:
		node.freeze = false
		node.linear_velocity = vel * fx.anim_speed()
		node.angular_velocity = ang * fx.anim_speed()
	else:
		wreck["fires"].append({"node": node, "vel": vel, "ang": ang})
	for mat in mats: wreck["heat_births"][mat] = fx.now
	wreck["cut_events"].append({"section": index, "t": fx.now})
	if wreck.get("organic", false): return
	if fx.quality != "low":
		flipbook(fx, node.to_global(node.get_meta("tear_site", Vector3.ZERO)), vel.normalized(), L * (0.35 if big else 0.5), "cool", 1.1, vel * 0.65, 0.4 if big else 0.7, atlas_band(L), src)
	# Big hulls' secondaries are scheduled once per kill (_schedule_secondaries), never a per-piece fire loop.


# Bounded samples from the actual cut, biased to its visible lip. No geometry work
# or unbounded hull scan is added to a death frame.
static func _edge_sites(pc: Dictionary, cen: Vector3, view: Vector3, count: int) -> PackedVector3Array:
	var src: PackedVector3Array = pc.get("edge", PackedVector3Array())
	if pc.has("lip"): src = pc["lip"]
	elif pc.has("cap"): src = pc["cap"][Mesh.ARRAY_VERTEX]
	if src.is_empty(): src = pc.get("pts", PackedVector3Array())
	var candidates := PackedVector3Array()
	for i in range(0, src.size(), maxi(1, src.size() / 128)):
		if src[i].is_finite(): candidates.append(src[i] - cen)
	if pc.has("split_at") and not candidates.is_empty():
		# A damaged hull's cap also contains old breach outlines. Keep only the
		# new split's band, or a top-facing breach can steal the core/fire sites.
		var axis: Vector3 = pc["split_axis"]
		var at: Vector3 = pc["split_at"] - cen
		var nearest := INF
		for p in candidates: nearest = minf(nearest, absf((p - at).dot(axis)))
		var seam := PackedVector3Array()
		for p in candidates:
			if absf((p - at).dot(axis)) <= nearest + maxf(float(pc["split_width"]), 0.001): seam.append(p)
		candidates = seam
	var sites := PackedVector3Array()
	if candidates.is_empty():
		sites.resize(count)
		return sites
	for j in count:
		var best := candidates[0]
		var score := -INF
		for p in candidates:
			var spread := INF
			for other in sites: spread = minf(spread, p.distance_to(other))
			var rank := p.dot(view) * (1.0 if j == 0 else 0.35) + (0.0 if j == 0 else spread)
			if rank > score:
				score = rank
				best = p
		sites.append(best)
	return sites


static func _cap_wrecks(fx) -> void:
	var ws: Array = fx.dstate["wrecks"]
	while ws.size() > 24:
		var w: Dictionary = ws.pop_front()
		_free_wreck(w)


static func _free_wreck(w: Dictionary) -> void:
	for l in w["lights"]:
		l["on"] = false
	for n in w.get("frags", []):
		if is_instance_valid(n):
			(n as Node).queue_free()
	for n in w["nodes"]:
		if is_instance_valid(n):
			(n as Node).queue_free()


static func clear_wreck(fx, id: String) -> void:
	var ws: Array = fx.dstate["wrecks"]
	var keep: Array = []
	for w in ws:
		if w["id"] == id:
			_free_wreck(w)
		else:
			keep.append(w)
	fx.dstate["wrecks"] = keep


static func update(fx, dt: float) -> void:
	if not fx.dstate.has("wrecks"):
		return
	for ship in fx.ships.values(): _update_dying(fx, ship)
	for w in fx.dstate["wrecks"]:
		var speed: float = maxf(fx.anim_speed(), 0.01)
		var prev: float = float(w.get("speed", 1.0))
		for nd in w["nodes"]:
			if is_instance_valid(nd) and nd is RigidBody3D:
				(nd as RigidBody3D).linear_velocity *= speed / prev
				(nd as RigidBody3D).angular_velocity *= speed / prev
		w["speed"] = speed
		var age: float = fx.now - float(w["t0"])
		# Heat fades over a few seconds. The cold opaque cap remains.
		# Issue 484 profiling: a wreck now has up to a dozen glowing faces and its scorched plating. Heat falls by about a
		# tenth a second, so faces are set 15 times a second, not every frame, and a wreck that has gone cold is never
		# visited again (material updates also cost the renderer).
		var cool_t: float = float(w.get("cool", WRECK_COOL))
		if not bool(w.get("cold", false)) and fx.now >= float(w.get("heat_next", -INF)):
			w["heat_next"] = fx.now + 1.0 / 15.0
			var births: Dictionary = w.get("heat_births", {})
			var any_warm := false
			for m in w["mats"]:
				var birth: float = births.get(m, INF)
				var heat := 0.0 if birth == INF else clampf(1.0 - (fx.now - birth) / cool_t, 0.0, 1.0)
				(m as ShaderMaterial).set_shader_parameter("heat", heat)
				if heat > 0.0 or birth == INF: any_warm = true
			var scorch_heat := clampf(1.0 - age / cool_t, 0.0, 1.0)
			for m in w.get("scorch_mats", []):
				(m as ShaderMaterial).set_shader_parameter("fx_scorch_heat", scorch_heat)
			# cold for good once every face has cooled and nothing is still waiting for its release
			if not any_warm and scorch_heat == 0.0 and age > 1.0: w["cold"] = true
		var gate = exp(-maxf(age, 0.0) / 3.5)
		for f in w["fires"]:
			if f.has("mat"):
				(f["mat"] as ShaderMaterial).set_shader_parameter("gate", exp(-maxf(age, 0.0) / maxf(float(f.get("cool", 3.5)), 0.01)))
			elif f.has("node") and is_instance_valid(f["node"]) and fx.now < float(f.get("until", INF)):
				# Kinematic tiers retain the same constant momentum as physics tiers.
				var n: Node3D = f["node"]
				var v: Vector3 = f["vel"]
				n.global_position += v * dt
				var a: Vector3 = f["ang"]
				if a.length() > 1e-5:
					n.global_rotate(a.normalized(), a.length() * dt)
		for l in w["lights"]:
			l["base"] = 0.7 * gate
