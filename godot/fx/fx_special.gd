extends RefCounted
# Build D: the FX clock owns charge, rift and pulse layers. Callers still own rules positions and damage.

const LOOK := preload("res://fx/faction_look.gd")
const BAKE := preload("res://fx/fx_death.gd")
const NOVA_CHARGE := 0.50
const NOVA_FLIGHT := 0.35
const NOVA_STYLES := ["ember_hammer", "crown_lance"]
const RIFT_SHAPES := {"arch": 5, "scan": 6, "vent": 7, "bloom": 8, "facet": 9, "fold": 10}
const GHOST := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled, fog_disabled;
global uniform float scene_t;
uniform vec3 tint;
uniform float start;
uniform float life = 0.4;
void fragment() {
	float t = clamp((scene_t - start) / max(life, 0.001), 0.0, 1.0);
	float edge = 1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
	float band = 0.68 + 0.32 * sin(VERTEX.y * 9.0 + t * 4.0);
	ALBEDO = tint * (0.18 + 1.1 * edge * edge) * band;
	ALPHA = smoothstep(0.0, 0.20, t) * (1.0 - smoothstep(0.28, 1.0, t)) * 0.55;
}
"""


static func nova(fx, ship, target: Vector3, pace: float, style: String) -> float:
	var start: float = fx.now
	var fire := start + NOVA_CHARGE * pace
	var impact := fire + NOVA_FLIGHT * pace
	var flight := NOVA_FLIGHT * pace
	var core: Vector3 = ship.to_world(ship.hull.core)
	var legacy_from := core + Vector3.UP * 2.0
	if ship.root.has_method("visual_position"):
		legacy_from = ship.root.visual_position() + Vector3.UP * 2.0
	if not NOVA_STYLES.has(style):
		var shell := Color(1.0, 0.8, 0.5) if ship.faction == "voidsworn" else LOOK.weapon(ship.faction)
		var blast := Color(1.0, 0.7, 0.4) if ship.faction == "voidsworn" else shell
		ship.legacy_pulse(fx)
		fx.spr(legacy_from, fire, flight, shell, 4.0, 6.6, 6.6, 34, (target - legacy_from) / flight)
		fx.later(impact, func nova_legacy_land() -> void:
			fx.pop(target, impact, blast, 30.0, 3.0, Vector3.UP, 0.4)
			fx.light(target, impact, 0.8, 2.0, blast))
		return impact

	# Nova is a spinal weapon, not one of the ordinary turret slots. Use the fitted bow surface.
	var muzzle: Vector3 = ship.to_world(ship.hull.bow)
	var dv := target - muzzle
	var axis := _axis(dv, ship.dir_world(Vector3.RIGHT))
	var crown := style == "crown_lance"
	var ember := LOOK.weapon(ship.faction)
	var pale: Color = ship.fac["accent"] if ship.faction == "voidsworn" else ember.lerp(Color.WHITE, 0.32)
	var trim := pale if crown else ember
	var k: float = ship.scale_k()
	var size := 4.0 * k
	var charge := NOVA_CHARGE * pace
	var width := size * (1.2 if crown else 0.86)
	for j in range(4 if crown else 3):
		var t := start + charge * j * 0.15
		var lead := k * (2.0 + j * 1.7)
		fx.ring(muzzle + axis * lead, -axis, t, fire - t, trim, 1.6, width * 2.5, width * 0.32,
			RIFT_SHAPES["arch"] if crown else 2, lead / (fire - t))
	fx.sprx(13.0, muzzle, start, charge, trim, 1.45, size * 0.2, size * 1.25, 12)
	fx.light(muzzle, start, charge, 3.0, trim, 2, size * 5.0)

	fx.later(fire, func nova_fire() -> void:
		if fx.ship(ship.id) == ship and not ship.dead and not ship.gone:
			ship.hit_react(fx, 0.8, ship.hull.bow, Vector3.LEFT, "recoil")
		fx.ring(muzzle, axis, fire, 0.42, trim, 2.0, width * 0.5, width * 2.8, 2, 5.0, 2.0, 36.0)
		fx.pop(muzzle, fire, trim, size, 3.0, axis, 0.11, 18.0))
	var v := dv / flight
	fx.sprx(12.0, muzzle, fire, flight, trim, 1.65, size * 1.12, size * 1.12, 17 if crown else 14, v)
	fx.stk(muzzle, fire, flight, ember, 1.35, size * (3.4 if crown else 4.8), size * 0.54, 0, v, 0.0, 0.0, 6.0, 33.0)
	var rail := _axis(axis.cross(Vector3.UP), Vector3.FORWARD)
	for j in range(1, 9):
		var u := float(j) / 9.0
		var t := fire + u * flight
		var p := muzzle.lerp(target, u)
		fx.dst(p, t, 0.16, size * 0.7, size * 1.9, 1, 0.28 if crown else 0.17)
		if crown:
			for side in [-1.0, 1.0]:
				fx.spr(p + rail * side * width * 0.45, t, 0.23, pale, 0.72, size * 0.18, size * 0.06, 18, axis * 4.0)
		else:
			fx.spr(p, t, 0.28, ember, 0.42, size * 0.22, size * 0.83, 8, -axis * 4.0, 1.0)

	fx.later(impact, func nova_land() -> void:
		# Only pop/light can submit a bright flash. All later layers have slow envelopes and lower peaks.
		fx.pop(target, impact, Color.WHITE.lerp(trim, 0.14), 12.0, 3.2, Vector3.UP, 0.17, 54.0)
		# Reuse the baked hot gas in a Nova-only picture pool, without calling the kill flash.
		var heat := BAKE.flipbook(fx, target, Vector3.UP, 13.0 if crown else 19.0, "flash", 0.42,
			Vector3.UP * 2.0, 0.95, "cruiser", null, false, false, null, "nova") as MeshInstance3D
		var mat := heat.material_override as ShaderMaterial
		var hot := trim.lerp(Color.WHITE, 0.72)
		mat.set_shader_parameter("fac_fire", Color(hot.r, hot.g, hot.b, 1.0))
		mat.set_shader_parameter("fac_mid", trim)
		mat.set_shader_parameter("min_pixels", 42.0)
		mat.set_shader_parameter("soft_flash", 1.0)
		mat.set_shader_parameter("calm_intensity", 0.4)
		fx.light(target, impact, 0.39, 6.0, trim, 0, 32.0)
		fx.ring(target, Vector3.UP, impact, 0.65, trim, 1.9, 5.0, 37.0, 1 if ship.faction == "voidsworn" else _shape(ship), 0.0, 0.0, 94.0)
		fx.dst(target, impact, 0.48, 6.0, 40.0, 0, 0.62)
		if crown:
			fx.ring(target + Vector3.UP * 0.6, Vector3.UP, impact + 0.15, 0.69, pale, 1.65, 5.5, 43.0, _shape(ship), 0.0, 0.0, 90.0)
		for j in 7:
			var arm := TAU * float(j) / 7.0
			var dir := Vector3(cos(arm), 0.1 + fx.rng.randf() * 0.3, sin(arm))
			var t := impact + 0.05 + j * 0.018
			fx.spr(target + dir * 2.2, t, 0.54 - j * 0.031, trim, 0.58 if crown else 0.95, 3.6, 6.8, 26, dir * 13.0, 1.8)
			fx.spr(target + dir * 3.5, t + 0.18, 1.05, ember.lerp(Color(0.12, 0.12, 0.14), 0.68), 0.36, 2.5, 11.0, 8, dir * 6.0, 1.0))
	return impact


static func _axis(v: Vector3, fallback: Vector3) -> Vector3:
	return v.normalized() if v.length_squared() > 0.00001 else fallback


static func _shape(ship) -> int:
	return RIFT_SHAPES.get(ship.fac.get("rift_shape", "arch"), RIFT_SHAPES["arch"])


static func _rift(fx, ship, p: Vector3, axis: Vector3, t: float, beat: float, entering: bool) -> void:
	var c := LOOK.weapon(ship.faction)
	var shape := _shape(ship)
	var size: float = maxf(ship.hull.W * 1.55, ship.hull.L * 0.54)
	var peak := t + beat
	# Main tear, moving edge, quiet lens and wake. No sparks or shield surfaces.
	fx.ring(p, axis, t, beat + 0.31, c, 2.15, size * 0.13, size, shape, 0.0, 0.0, 43.0)
	fx.ring(p, Vector3.UP, peak - beat * 0.4, 0.58, c, 0.8, size * 0.27, size * 1.32, shape)
	fx.ring(p + axis * size * 0.1, axis, peak - beat * 0.44, beat + 0.36, c, 1.32, size, size * 0.19,
		shape, size * (0.73 if entering else -0.53), 1.8)
	fx.dst(p, t, beat + 0.34, size * 0.23, size * 1.25, 1, 0.8 if shape == RIFT_SHAPES["fold"] else 0.52)
	fx.sprx(19.0, p, peak - beat * 0.3, 0.47, c, 1.45, size * 0.3, size * 0.75, 18)
	fx.light(p, peak - beat * 0.46, 0.60, 3.2, c, 1, size * 2.15)
	var right := _axis(axis.cross(Vector3.UP), Vector3.FORWARD)
	for j in 5:
		var angle := TAU * float(j) / 5.0
		var off := right * cos(angle) + Vector3.UP * sin(angle) * 0.72
		var signed_axis := axis if entering else -axis
		var origin := p + off * size * 0.26 - signed_axis * size * 0.55
		var dir := (signed_axis - off * 0.43).normalized()
		var life := 0.38 + j * 0.021
		fx.rib(origin, dir, size * 0.73, peak - beat * 0.25 + j * 0.027, life, c, 0.55, size * 0.10, size * 0.024, 1)


static func arrive(fx, ship, pace: float, delay: float, risen: bool) -> float:
	var t: float = fx.now + delay
	var opening := (0.20 if risen else 0.35) * pace
	var reveal := (0.33 if risen else 0.40) * pace
	var p: Vector3 = ship.to_world(ship.hull.core)
	var bow: Vector3 = ship.dir_world(Vector3.RIGHT)
	_rift(fx, ship, p, bow, t, opening, true)
	# Read at the apex, then hand the hull back to the normal movement and hit-reaction pose.
	fx.ring(p, bow, t + opening, reveal + 0.20, LOOK.weapon(ship.faction), 1.12,
		ship.hull.L * 0.44, ship.hull.L * 0.37, _shape(ship), ship.hull.L * 1.35, 1.1)
	ship.start_rift_pose(t + opening, reveal, true, fx.reduce_motion)
	return t + opening + reveal


static func _ghost(fx, ship, at: float, life: float) -> void:
	if fx.reduce_motion:
		return
	var ghost := Node3D.new()
	ghost.name = "fx_warp_echo"
	fx.add_child(ghost)
	var m: ShaderMaterial = fx.mat(GHOST, -2)
	var c := LOOK.weapon(ship.faction)
	m.set_shader_parameter("tint", Vector3(c.r, c.g, c.b))
	m.set_shader_parameter("start", at)
	m.set_shader_parameter("life", life)
	var candidates: Array = ship.meshes.filter(func(part): return is_instance_valid(part) and part.mesh != null and part.is_visible_in_tree())
	# Instanced meshes share the real hull's resources and LODs. Bound part count on very large multipart imports.
	if candidates.size() > 16:
		candidates.sort_custom(func(a: MeshInstance3D, b: MeshInstance3D) -> bool:
			return (a.global_basis.get_scale().abs() * a.get_aabb().size).length_squared() > (b.global_basis.get_scale().abs() * b.get_aabb().size).length_squared())
	for part: MeshInstance3D in candidates.slice(0, 16):
		var echo := MeshInstance3D.new()
		echo.mesh = part.mesh
		echo.material_override = m
		echo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		echo.lod_bias = 0.3
		ghost.add_child(echo)
		echo.global_transform = part.global_transform
	fx.later(at + life, fx.free_effect.bind(weakref(ghost)))


static func fold(fx, ship, pace: float, transfer: Callable) -> float:
	var t: float = fx.now
	var blink := transfer.is_valid()
	var depart := (0.25 if blink else 0.20) * pace
	var reveal := (0.25 if blink else 0.20) * pace
	var p: Vector3 = ship.to_world(ship.hull.core)
	var bow: Vector3 = ship.dir_world(Vector3.RIGHT)
	_rift(fx, ship, p, bow, t, depart, false)
	_ghost(fx, ship, t, depart + 0.23)
	ship.start_rift_pose(t, depart, false, fx.reduce_motion)
	fx.later(t + depart, func fold_release() -> void:
		if fx.ship(ship.id) != ship or ship.dead or ship.gone or not is_instance_valid(ship.root):
			return
		ship.clear_rift_pose()
		if blink:
			transfer.call()
		var dest: Vector3 = ship.to_world(ship.hull.core)
		_rift(fx, ship, dest, bow, t + depart, reveal * 0.30, true)
		ship.start_rift_pose(t + depart, reveal, true, fx.reduce_motion))
	return t + depart + reveal


static func jump(fx, ship, pace: float) -> float:
	var t: float = fx.now
	var depart := 0.40 * pace
	var spool := depart * 0.5
	var bow: Vector3 = ship.dir_world(Vector3.RIGHT)
	var c := LOOK.engine(ship.faction)
	var k: float = ship.scale_k()
	_rift(fx, ship, ship.to_world(ship.hull.core), bow, t, depart, false)
	for nozzle in ship.hull.nozzles:
		var p: Vector3 = ship.to_world(nozzle["p"])
		fx.rib(p, _axis(ship.dir_world(nozzle.get("d", Vector3.LEFT)), -bow), 5.0 * k, t, depart + 0.17, c, 1.05, 1.9 * k, 0.3 * k, 0)
	ship.start_rift_pose(t + spool, depart - spool, false, fx.reduce_motion)
	fx.later(t + depart, func escape() -> void:
		if fx.ship(ship.id) == ship and not ship.dead and not ship.gone and is_instance_valid(ship.root):
			ship.clear_rift_pose()
			ship.hide_live_hull()
			ship.teardown(fx, false))
	return t + depart


static func pulse(fx, ship, command: bool) -> void:
	var anchor: Dictionary = ship.hull.core_point()
	if anchor.is_empty():
		return
	var p: Vector3 = ship.to_world(anchor["p"])
	var up: Vector3 = ship.dir_world(Vector3.UP)
	var bow: Vector3 = ship.dir_world(Vector3.RIGHT)
	var c := LOOK.weapon(ship.faction)
	var shape := _shape(ship)
	var size: float = ship.hull.L * (0.9 if command else 0.70)
	var t: float = fx.now
	var plane := bow if shape in [RIFT_SHAPES["arch"], RIFT_SHAPES["fold"]] else up
	fx.ring(p, plane, t, 0.63, c, 1.75, size * 0.20, size, shape, 0.0, 0.0, 40.0)
	fx.ring(p + up * 0.45, up, t + 0.12, 0.57, c, 1.10, size * 0.23, size * 0.85, shape, 1.6)
	if command:
		fx.ring(p, plane, t + 0.27, 0.56, c, 1.55, size * 0.38, size * 1.22, shape, 0.0, 0.0, 48.0)
	if shape == RIFT_SHAPES["fold"]:
		fx.dst(p, t, 0.5, size * 0.25, size, 1, 0.45)
	elif shape in [RIFT_SHAPES["vent"], RIFT_SHAPES["bloom"]]:
		for side in [-1.0, 0.0, 1.0]:
			fx.spr(p + bow * side * size * 0.11, t + absf(side) * 0.10, 0.61, c, 0.6, size * 0.07, size * 0.34,
				20 if shape == RIFT_SHAPES["bloom"] else 27, (up + side * bow * 0.5) * 4.3, 1.4)
	else:
		fx.rib(p, up, size * (0.88 if shape == RIFT_SHAPES["arch"] else 0.34), t, 0.52, c, 0.68, size * 0.13, size * 0.03, 1)
	fx.sprx(13.0, p, t + 0.03, 0.57, c, 0.85, size * 0.22, size * 0.49, 18)
	fx.light(p, t, 0.64, 3.0, c, 1, size * 2.2)


static func bay(fx, ship, mouth: Vector3, normal: Vector3, toward: Vector3, t: float) -> void:
	var c := LOOK.engine(ship.faction)
	var k: float = ship.scale_k()
	var axis := _axis(toward, normal)
	var side := _axis(axis.cross(Vector3.UP), Vector3.FORWARD)
	fx.ring(mouth, normal, t, 0.65, c, 1.55, k * 1.0, k * 4.8, _shape(ship), 1.2, 1.0, 26.0)
	fx.rib(mouth, axis, k * 6.2, t + 0.11, 0.52, c, 0.8, k * 2.0, k * 0.24, 1)
	for rail in [-1.0, 1.0]:
		var lip: Vector3 = mouth + normal * k * 0.14 + side * rail * 0.65 * k
		fx.stk(lip, t + 0.18, 0.39, c, 1.3, k * 4.9, k * 0.42, 0, axis * 5.0, 0.0, 0.0, 3.0, 18.0)
		fx.spr(lip, t + 0.2, 0.65, c, 0.43, k * 0.6, k * 3.2, 20 if ship.faction == "chorus" else 27, axis * 3.1 + side * rail, 1.8)
	fx.light(mouth, t, 0.75, 2.8, c, 1, 9.0 * k)


static func bay_ignite(fx, faction: String, p: Vector3, axis: Vector3, t: float, k: float) -> void:
	var c := LOOK.engine(faction)
	fx.sprx(6.0, p, t, 0.18, c, 1.0, k * 1.25, k * 0.15, 18, axis * 12.0)
