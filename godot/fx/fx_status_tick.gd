extends RefCounted
# Turn-start beats only. The persistent acid mist and ion lock live in FxShip.

const DEATH := preload("res://fx/fx_death.gd")
const PATHS := preload("res://fx/fx_event_paths.gd")
const SH := preload("res://fx/fx_shaders.gd")
const FIRE_LIFE := 0.62
const STORM_LIFE := 0.45
const STORM_COLOUR := Color(0.30, 0.74, 1.0)
const TIDAL_COLOUR := Color(0.57, 0.35, 1.0)


static func play(fx, ship, kind: String, hit: Dictionary) -> void:
	var p: Vector3 = ship.to_world(hit.p)
	var n: Vector3 = ship.dir_world(hit.n)
	var k: float = ship.scale_k()
	match kind:
		"acid": _acid(fx, ship, p, n, k)
		"tidal": _tidal(fx, ship, hit.p, p, n, k)
		"storm": _storm(fx, ship, hit)
		"fire": _fire(fx, ship, p, n, k)


static func _fire(fx, ship, p: Vector3, n: Vector3, k: float) -> void:
	var t: float = fx.now
	var col: Color = ship.fac.weapon if ship.faction == "hegemony" else ship.fac.damage_glow
	var hot := col.lerp(Color.WHITE, 0.48)
	# Reuse the directional baked vent (colour, flow and thickness), with its hot pass enabled.
	# The plume stays below the intensity that counts as a flash and is in its own picture pool.
	var plume := DEATH.flipbook(fx, p, n, 4.6 * k, "vent", FIRE_LIFE, n * 1.2 * k,
		2.1, "small", ship, true, false, null, "status_fire") as MeshInstance3D
	plume.name = "fx_tick_flame"
	var mat := plume.material_override as ShaderMaterial
	mat.set_shader_parameter("plasma", 1.0)
	mat.set_shader_parameter("min_pixels", 31.0)
	mat.set_shader_parameter("fac_fire", hot)
	mat.set_shader_parameter("fac_mid", col)
	var sooty: bool = ship.faction not in ["ithar", "chorus"]
	mat.set_shader_parameter("fac_smoke", 0.12 if sooty else 0.0)
	mat.set_shader_parameter("calm_intensity", 1.2)
	if sooty:
		for i in 5:
			var flow: Vector3 = fx.rcone(n, 0.38)
			fx.sprx(16.0, p, t + i * 0.07, 0.9 + i * 0.10, Color(0.17, 0.16, 0.20), 0.69,
				0.55 * k, 3.1 * k, 8, flow * (2.4 * k), 0.75)
	for i in 9:
		fx.sprx(4.0, p, t + i * 0.037, 0.48 + i * 0.046, col, 2.3,
			0.16 * k, 0.055 * k, SH.TICK_EMBER, fx.rcone(n, 0.70) * (3.5 * k), 1.3)
	fx.light(p + n * k, t, 0.58, 2.7, col, 1, 11.0 * k)


static func _acid(fx, ship, p: Vector3, n: Vector3, k: float) -> void:
	var t: float = fx.now
	var col: Color = ship._acid_colour()
	var pale := col.lerp(Color.WHITE, 0.38)
	# A wet etch lies along the damaged plate. Droplets move out of it, vapour follows late.
	fx.ring(p + n * 0.11 * k, n, t, 0.49, pale, 1.8, 0.36 * k, 1.85 * k, 2, 0.0, 0.0, 28.0)
	fx.sprx(18.0, p + n * 0.19 * k, t, 0.43, col, 1.55, 0.8 * k, 1.1 * k, 18)
	for i in 11:
		var spray: Vector3 = fx.rcone(n, 1.01)
		fx.sprx(4.0, p + n * 0.15 * k, t + i * 0.019, 0.32 + (i % 4) * 0.075, pale, 1.6,
			0.18 * k, 0.09 * k, SH.TICK_DROPLET, spray * (2.0 + (i % 5) * 1.3) * k, 1.3)
	for i in 5:
		fx.sprx(12.0, p + n * 0.21 * k, t + 0.12 + i * 0.065, 0.9, col, 0.5,
			0.53 * k, 2.5 * k, 20, fx.rcone(n, 0.50) * (1.7 * k), 0.6)
	fx.light(p + n * 0.9 * k, t, 0.43, 1.5, col, 1, 8.0 * k)


static func _tidal(fx, ship, local: Vector3, p: Vector3, n: Vector3, k: float) -> void:
	if not fx.well.is_finite():
		return
	var t: float = fx.now
	var pull: Vector3 = fx.well - p
	if pull.length_squared() < 0.01:
		return
	var inward := pull.normalized()
	var reach := minf(pull.length(), 21.0 * k)
	var across := inward.cross(Vector3.UP).normalized()
	var at_hull := PATHS.anchor(ship, local)
	for lane in 3:
		var pts := PackedVector3Array()
		var widths := PackedFloat32Array()
		for i in 11:
			var u := i / 10.0
			var bow := sin(u * PI)
			pts.append(p + inward * (u * reach) + bow * (n * 2.4 + across * (lane - 1) * 1.8) * k)
			widths.append((0.14 + 0.32 * bow) * k)
		fx.event_paths.add(fx, "tidal_stream", pts, widths, TIDAL_COLOUR, TIDAL_COLOUR.lerp(Color.WHITE, 0.42),
			4, 2.5, t + lane * 0.045, t + 0.76, at_hull)
	# Soft stress on the plating, not a shield ring or an extra shield pool.
	fx.ring(p + n * 0.12 * k, n, t, 0.69, TIDAL_COLOUR, 1.35, 0.5 * k, 2.3 * k, 2, 0.0, 0.0, 35.0)
	for i in 8:
		fx.sprx(4.0, p + n * 0.16 * k, t + i * 0.045, 0.5, TIDAL_COLOUR, 2.0,
			0.22 * k, 0.10 * k, SH.TICK_EMBER, (inward * 16.0 + n * 4.0 + fx.rdir() * 1.8) * k, 0.6)


static func _storm(fx, ship, sample: Dictionary) -> void:
	# Storm ticks are delivered only on storm hexes: the upper cloud bank is over that hex.
	# This is the ship strike, not the terrain's independent, baked cloud-to-cloud bolts.
	var centre: Vector3 = ship.root.global_position
	var cloud := centre + Vector3(-5.5, 13.0, -3.5)
	var inv: Transform3D = ship.xf().affine_inverse()
	var local_cloud := inv * cloud
	var face: Dictionary = ship.hull.surface(ship.hull.core, (local_cloud - ship.hull.core).normalized())
	var contact: Dictionary = face if not face.is_empty() else sample
	var p: Vector3 = ship.to_world(contact.p)
	var n: Vector3 = ship.dir_world(contact.n)
	var local: Vector3 = contact.p
	var t: float = fx.now
	# A negative fraction means no pool snapshot yet, not an empty shield.
	if ship._shield_mat != null and (ship._shield_fraction > 0.0 or (ship._shield_fraction < 0.0 and ship.shielded)):
		var shield: Dictionary = ship.shield_point(cloud)
		p = shield.p
		n = shield.n
		local = inv * p
		ship.shield_hit(fx, shield.local, t, 0.55, 14.0, STORM_LIFE, 1.0)
	var colour: Color = ship.fac.damage_glow if ship.faction == "deathless" else STORM_COLOUR
	var core := colour.lerp(Color.WHITE, 0.61)
	var k: float = ship.scale_k()
	var path := PackedVector3Array([cloud])
	var widths := PackedFloat32Array([0.18])
	# Fixed zig-zag stations with local RNG jitter. The silhouette is stable while light chases through it.
	var side := (p - cloud).cross(Vector3.UP).normalized()
	for i in range(1, 8):
		var u := i / 8.0
		var jog: float = (1.0 if i % 2 else -1.0) * fx.rng.randf_range(0.62, 1.65)
		path.append(cloud.lerp(p, u) + side * jog + Vector3.FORWARD * fx.rng.randf_range(-0.66, 0.66))
		widths.append(0.41 - u * 0.10)
	path.append(p)
	widths.append(0.20)
	fx.event_paths.add(fx, "storm_arc", path, widths, colour, core, 4, 4.5, t, t + STORM_LIFE, Callable(), PATHS.anchor(ship, local))
	for i in 2:
		var fork: Vector3 = path[2 + i * 2]
		var branch := PackedVector3Array([fork, fork.lerp(p, 0.22) + side * (2.0 - i * 4.0),
			fork.lerp(p, 0.52) + side * (3.75 - i * 7.5)])
		fx.event_paths.add(fx, "storm_fork", branch, PackedFloat32Array([0.20, 0.19, 0.025]),
			colour, core, 4, 2.4, t + 0.016 + i * 0.028, t + 0.32)
	fx.sprx(15.0, p + n * 0.15, t, 0.29, core, 2.3, 0.55 * k, 1.25 * k, 18)
	fx.light(p + n * 0.7, t, STORM_LIFE, 2.0, colour, 1, 11.0 * k)
