extends RefCounted
# Boarding is one effect family. The boarding faction chooses the crossing motion and cutter.

const PATHS := preload("res://fx/fx_event_paths.gd")
const TUBE := preload("res://render/fx_conduit.gd")
const SKINS := {
	"voidsworn": {"look": "assault", "lines": 3, "width": 0.31, "lift": 0.21, "style": 0},
	"hegemony": {"look": "precision", "lines": 3, "width": 0.23, "lift": 0.095, "style": 0},
	"corsair": {"look": "salvage", "lines": 3, "width": 0.43, "lift": 0.16, "style": 0},
	"deathless": {"look": "phase", "lines": 2, "width": 0.44, "lift": 0.065, "style": 1},
	"ithar": {"look": "prism", "lines": 3, "width": 0.37, "lift": 0.14, "style": 2},
	"chorus": {"look": "umbilical", "lines": 2, "width": 0.68, "lift": 0.19, "style": 3},
}
const PODS := {
	"assault": [Vector2(-1.7, 0.46), Vector2(-1.05, 0.70), Vector2(0.5, 0.70), Vector2(1.45, 0.07)],
	"precision": [Vector2(-1.95, 0.38), Vector2(-1.20, 0.50), Vector2(0.65, 0.47), Vector2(1.9, 0.04)],
	"salvage": [Vector2(-1.35, 0.36), Vector2(-0.85, 0.66), Vector2(0.15, 0.66), Vector2(0.85, 0.79), Vector2(1.45, 0.49)],
}


static func skin(ship) -> Dictionary:
	var recipe: Dictionary = SKINS.get(ship.faction, SKINS["voidsworn"])
	var tint: Color = ship.fac.weapon
	var core := tint.lerp(Color.WHITE, 0.55)
	match recipe.look:
		"assault":
			core = ship.fac.accent
		"precision":
			tint = ship.fac.shield
		"salvage":
			tint = ship.fac.accent
		"phase":
			tint = ship.fac.weapon_core
			core = ship.fac.weapon.lerp(Color.WHITE, 0.32)
	return recipe.merged({"tint": tint, "core": core})


static func crossing(fx, attacker, launch: Vector3, target, landings: Array[Vector3], hold: float, recipe: Dictionary) -> void:
	var from: Vector3 = attacker.to_world(launch)
	var look: String = recipe.look
	var first := PATHS.anchor(attacker, launch)
	for i in landings.size():
		var landing := landings[i]
		var to: Vector3 = target.to_world(landing)
		var distance := from.distance_to(to)
		if distance < 0.15:
			continue
		var side := (to - from).cross(Vector3.UP).normalized()
		var rank := float(i) - (landings.size() - 1) * 0.5
		var path := PackedVector3Array()
		var radii := PackedFloat32Array()
		for j in 17:
			var u := j / 16.0
			var arc := sin(u * PI)
			var lift: float = distance * (recipe.lift + i * 0.027)
			var bend := arc * rank * 1.4
			if look == "salvage":
				bend += sin(u * TAU) * 1.05
			elif look == "umbilical":
				bend += arc * sin(u * TAU * 1.5 + i * PI) * 1.9
			elif look == "prism":
				bend += (1.0 - absf(u * 2.0 - 1.0)) * rank * 0.88
			path.append(from.lerp(to, u) + Vector3.UP * lift * arc + side * bend)
			radii.append(recipe.width * (0.52 + 0.48 * arc))
		var start: float = fx.now + hold * i * 0.115
		var row: Dictionary = fx.event_paths.add(fx, "board_" + look, path, radii, recipe.tint, recipe.core,
			recipe.style, 2.4 if PODS.has(look) else 3.8, start, fx.now + hold, first, PATHS.anchor(target, landing))
		if row.is_empty() or not PODS.has(look):
			continue
		var form := PackedVector3Array()
		var thickness := PackedFloat32Array()
		for ring: Vector2 in PODS[look]:
			form.append(Vector3(ring.x, 0.0, 0.0))
			thickness.append(ring.y)
		var pod := TUBE.make(fx, form, thickness, recipe.tint, recipe.core, 5, 5.2, 8)
		pod.name = "fx_boarding_pod"
		row.node.add_child(pod)
		pod.hide()
		row.pod = pod


static func breach(fx, target, hit: Dictionary, t: float, recipe: Dictionary) -> void:
	var p: Vector3 = target.to_world(hit.p)
	var n: Vector3 = target.dir_world(hit.n)
	var k: float = target.scale_k()
	var own_glow: bool = target.faction in ["ithar", "chorus", "deathless", "hegemony"]
	var tint: Color = target.fac.damage_glow if own_glow else recipe.tint
	var core: Color = tint.lerp(Color.WHITE, 0.55) if own_glow else recipe.core
	var organic: bool = recipe.look == "umbilical" or target.faction == "chorus"
	var across := n.cross(Vector3.UP).normalized()
	if across.length_squared() < 0.01:
		across = n.cross(Vector3.RIGHT).normalized()
	var up := n.cross(across)
	# An uneven cutter ring in the plane of the hatch. Violet phase and pale prism cut without orange flame.
	var path := PackedVector3Array()
	var radii := PackedFloat32Array()
	for j in 21:
		var a := j * TAU / 20.0
		var radius := (1.55 + 0.17 * sin(a * 3.0 + 1.0)) * k
		path.append(p + (n * 0.25 + across * cos(a) * radius + up * sin(a) * radius * 0.72))
		radii.append((0.22 + 0.09 * sin(a * 2.0)) * k)
	var first := PATHS.anchor(target, target.xf().affine_inverse() * path[0])
	fx.event_paths.add(fx, "board_cutter", path, radii, tint, core, recipe.style, 3.5, t, t + 0.63, first, first)
	fx.ring(p + n * 0.17, n, t, 0.55, tint, 1.25, 1.0 * k, 3.4 * k, 2, 0.0, 0.0, 42.0)
	fx.sprx(26.0, p + n * 0.40, t, 0.39, core, 2.25, 0.85 * k, 1.65 * k, 18)
	var glass: bool = target.faction == "ithar"
	var vent_kind := 16 if glass else (20 if organic else 7)
	var vent_col := tint * 0.55 if glass else tint.lerp(Color(0.21, 0.22, 0.27), 0.45)
	for i in 10:
		var drift: Vector3 = fx.rcone(n, 0.34) * (4.5 * k)
		fx.sprx(15.0, p + n * 0.24, t + 0.12 + i * 0.16, 0.95, vent_col,
			0.52, 0.43 * k, 2.3 * k, vent_kind, drift, 0.95)
	fx.light(p + n * 0.9, t, 2.15, 3.8, tint, 1, 15.0 * k)
