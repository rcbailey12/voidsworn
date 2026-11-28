extends SceneTree
# Headless checks route real volleys and step their effect clock. Visibility at
# the two battle cameras is a separate look-bench check, not a dummy-render claim.
const GUARD := preload("res://tools/ci/check_guard.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const SH := preload("res://fx/fx_shaders.gd")
const FLOOK := preload("res://fx/faction_look.gd")
var failures := 0


class RecordFX extends "res://fx/fx.gd":
	var streaks: Array = []
	var streak_cols: Array = []
	var spark_times: Array[float] = []
	var sprites: Array = []
	var rings: Array = []
	var flashes: Array = []

	func flight_streak(p: Vector3, t: float, life: float, col: Color, i: float, length: float, w: float, kind: int, vel: Vector3,
			drag := 0.0, acc := 0.0, wpx := 0.0, lpx := 0.0) -> void:
		streaks.append(kind)
		streak_cols.append({"kind": kind, "col": col})
		super.flight_streak(p, t, life, col, i, length, w, kind, vel, drag, acc, wpx, lpx)

	func spark(p: Vector3, t: float, life: float, faction: String, intensity: float, shutter: float, width: float,
			vel: Vector3, drag := 0.0, wpx := 0.0, lpx := 0.0, role := SparkRole.HULL, tint := Color.TRANSPARENT) -> void:
		var before: int = pools["stk"].emitted
		super.spark(p, t, life, faction, intensity, shutter, width, vel, drag, wpx, lpx, role, tint)
		if pools["stk"].emitted > before:
			spark_times.append(t)

	func _emit_spr(p: Vector3, t: float, life: float, col: Color, i: float, s0: float, s1: float, kind: int, vel := Vector3.ZERO,
			drag := 0.0, spin := 0.0, acc := 0.0, px := 0.0) -> void:
		var before: int = pools["smk"].emitted
		super._emit_spr(p, t, life, col, i, s0, s1, kind, vel, drag, spin, acc, px)
		sprites.append({"kind": kind, "life": life, "col": col, "smoke": pools["smk"].emitted > before})

	func flash_at(p: Vector3, t: float, size: float, px := 0.0, life := FLASH_WINDOW, yield_last := false) -> bool:
		var allowed := super.flash_at(p, t, size, px, life, yield_last)
		flashes.append([p, allowed, life])
		return allowed

	func ring(p: Vector3, n: Vector3, t: float, life: float, col: Color, i: float, s0: float, s1: float, kind: int,
			speed := 0.0, drag := 0.0, px := 0.0, seed_override := -1.0) -> void:
		rings.append([p, kind])
		super.ring(p, n, t, life, col, i, s0, s1, kind, speed, drag, px, seed_override)


func _init() -> void:
	GUARD.arm(self, "weapon_layers_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _fx(calm := false) -> RecordFX:
	var fx := RecordFX.new()
	root.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "reduce_flashing": calm})
	fx.rng.seed = 23
	# issue 2194: a nonzero start proves no check leans on the clock beginning at zero
	fx.now = 5.0
	return fx


func _volley(fx: RecordFX, kind: String, id: String, faction: String, pd := false, distance := 68.0) -> Dictionary:
	return WEAP.volley_points(fx, Vector3.ZERO, kind, Vector3(distance, 0, 0),
		{"weapon_id": id, "faction": faction, "shots": [not pd], "pd": int(pd)})


func _sprites(fx: RecordFX, kind: int) -> Array:
	return fx.sprites.filter(func(row: Dictionary) -> bool: return row["kind"] == kind)


func _same_hue(col: Color, palette: Color) -> bool:
	return col.b > 0.0 and palette.b > 0.0 and is_equal_approx(col.r / col.b, palette.r / palette.b) \
		and is_equal_approx(col.g / col.b, palette.g / palette.b)


func _advance(fx: RecordFX, target: float) -> void:
	while fx.now + 0.00001 < target:
		fx.step(1.0 / 60.0)


func _bolts() -> void:
	var rows := [
		["battery", "hbattery", "voidsworn", WEAP.BOLT_SHELL, true],
		["battery", "autocannon", "hegemony", WEAP.BOLT_SHELL, true],
		["battery", "turret", "corsair", WEAP.BOLT_SCRAP, true],
		["battery", "scatter", "corsair", WEAP.BOLT_SCRAP, true],
		["battery", "turret", "voidsworn", WEAP.BOLT_ENERGY, true],
		["battery", "shard", "ithar", WEAP.BOLT_CRYSTAL, true],
		["battery", "laser", "hegemony", WEAP.BOLT_PLASMA, false],
		["battery", "turbo", "deathless", WEAP.BOLT_PLASMA, false],
		["flak", "flak", "corsair", WEAP.BOLT_SHELL, true],
		["flak", "flak", "hegemony", WEAP.BOLT_ENERGY, true],
		["flak", "flak", "ithar", WEAP.BOLT_CRYSTAL, true],
		["flak", "gsentry", "deathless", WEAP.BOLT_ENERGY, true],
		["flak", "spores", "chorus", WEAP.BOLT_BIO, false],
		["bio", "bioplasma", "chorus", WEAP.BOLT_BIO, false],
		["sq", "guns", "voidsworn", WEAP.BOLT_SHELL, true],
		["sq", "bombs", "voidsworn", WEAP.BOLT_BOMB, false],
		["sq", "sporeb", "chorus", WEAP.BOLT_BIO, false],
	]
	for row in rows:
		var fx := _fx()
		var res := _volley(fx, row[0], row[1], row[2])
		var shots := [] if row[4] else _sprites(fx, row[3])
		var expected: bool = fx.streaks.has(row[3]) if row[4] else not shots.is_empty()
		_check(expected and res.get("impacts", []).size() == 1, "%s %s emits its layered projectile" % [row[2], row[1]])
		if row[4]:
			var streak_rows: Array = fx.streak_cols.filter(func(r: Dictionary) -> bool: return int(r["kind"]) == int(row[3]))
			_check(not streak_rows.is_empty() and _same_hue(streak_rows[0]["col"], FLOOK.weapon(row[2])),
				"%s %s keeps its tracer tint" % [row[2], row[1]])
		if not shots.is_empty():
			var palette := WEAP.PLASMA_COL if row[3] == WEAP.BOLT_PLASMA else FLOOK.weapon(row[2])
			_check(_same_hue(shots[0]["col"], palette), "%s %s keeps its bolt tint" % [row[2], row[1]])
		if row[1] == "bombs":
			_check(_sprites(fx, 23).is_empty(), "bomb is not the craft silhouette sprite")
		fx.free()


func _plasma_palette() -> void:
	# R46 applies to both weapons, even for factions whose own energy is orange or violet.
	for faction in ["voidsworn", "deathless"]:
		for weapon in ["laser", "turbo"]:
			var fx := _fx()
			var res := _volley(fx, "battery", weapon, faction)
			var label := "%s %s" % [faction, weapon]
			for profile in [WEAP.BOLT_PLASMA, WEAP.MUZZLE_ENERGY]:
				var layers := _sprites(fx, profile)
				_check(not layers.is_empty() and _same_hue(layers[0]["col"], WEAP.PLASMA_COL),
					"%s uses light blue for sprite %d" % [label, profile])
			var fire: float = fx.now + float(res["fires"][0])
			var lights: Array = fx._lev.filter(func(light: Array) -> bool: return is_equal_approx(light[1], fire))
			_check(lights.size() == (2 if weapon == "turbo" else 1) and lights.all(
				func(light: Array) -> bool: return _same_hue(light[4], WEAP.PLASMA_COL)), "%s has light-blue firing lights" % label)
			if weapon == "turbo":
				var shimmer := _sprites(fx, 18)
				_check(shimmer.size() == 3 and shimmer.all(func(layer: Dictionary) -> bool: return _same_hue(layer["col"], WEAP.PLASMA_COL)),
					"%s has light-blue heat shimmer" % label)
			fx.free()


func _muzzles() -> void:
	for row in [["battery", "turret", "voidsworn", WEAP.MUZZLE_ENERGY], ["battery", "shard", "ithar", WEAP.MUZZLE_CRYSTAL],
			["battery", "turbo", "deathless", WEAP.MUZZLE_ENERGY], ["battery", "autocannon", "corsair", WEAP.MUZZLE_BALLISTIC],
			["flak", "flak", "corsair", WEAP.MUZZLE_BALLISTIC], ["bio", "bioplasma", "chorus", WEAP.MUZZLE_BIO]]:
		var fx := _fx(true)
		var res := _volley(fx, row[0], row[1], row[2], false, 108.0)
		var fire: float = fx.now + float(res["fires"][0])
		_advance(fx, fire + 0.09)
		var layers := _sprites(fx, row[3])
		_check(not layers.is_empty() and float(layers[0]["life"]) <= 0.25, "%s has a short muzzle sheath" % row[1])
		var vent := false
		for child in fx.get_children():
			vent = vent or child.name.begins_with("fx_weapon_vent") or child.name.begins_with("fx_weapon_muzzle")
		if row[3] != WEAP.MUZZLE_BALLISTIC:
			_check(not vent and not fx.spark_times.any(func(t: float) -> bool: return t <= fx.now),
				"%s muzzle throws no ballistic vent or metal sparks" % row[1])
		if row[3] != WEAP.MUZZLE_BIO:
			_check(fx.flashes.is_empty(), "%s muzzle core asks for no flash budget" % row[1])
		fx.free()


func _muzzle_budget() -> void:
	# issue 2194: the light-gun core is bright on purpose, but its pulse must not book a flash. Before this, each
	# autocannon and flak pulse sat at 4.2, over FLASH_I 4.0, and crowded out the impact and death flashes.
	for row in [["battery", "autocannon", "corsair"], ["battery", "autocannon", "hegemony"],
			["flak", "flak", "corsair"], ["flak", "flak", "hegemony"], ["flak", "flak", "ithar"]]:
		var fx := _fx()
		var before: int = fx.flash_log.size()
		var res := _volley(fx, row[0], row[1], row[2], false, 108.0)
		_advance(fx, fx.now + float(res["fires"][0]) + 0.09)
		_check(fx.flash_log.size() == before, "%s muzzle pulses spend no flash budget" % row[1])
		fx.free()


func _ordnance() -> void:
	var saved := WEAP._old_casing
	for variant in [["startorp", "ithar", false], ["htorp", "corsair", false], ["torp", "voidsworn", true],
			["htorp", "corsair", true]]:
		var fx := _fx()
		WEAP._old_casing = variant[2]
		_volley(fx, "torp", variant[0], variant[1])
		WEAP._old_casing = saved
		var p: Dictionary = fx.dstate["proj"][0]
		var body: Node3D = p["mesh"]
		var corona := body.get_node_or_null("corona") as MeshInstance3D
		_advance(fx, lerpf(p["lt"], p["t0"], 0.5))
		if variant[0] == "startorp":
			_check(corona != null and not corona.visible and body.visible, "star corona is off during the launch slide")
		if variant[2]:
			_check(not body.has_meta("kit") and body.has_meta("exhaust"), "%s reaches the procedural fallback body" % variant[0])
		elif variant[0] == "htorp":
			_check(body.has_meta("kit"), "the kit rocket takes the same smoke route as the fallback")
		_advance(fx, float(p["t0"]) + 0.22)
		if variant[0] == "startorp":
			_check(corona != null and corona.visible and corona.global_position.is_equal_approx(body.global_position),
				"ignited star corona stays on the existing body")
		else:
			_check(p.has("trail") and (p["trail"]["hist"] as Array).size() >= 2 and (p["trail"]["mi"] as MeshInstance3D).visible,
				"%s has a live nozzle wake (fallback %s)" % [variant[0], variant[2]])
		if variant[0] == "htorp":
			var smoke := _sprites(fx, SH.ROCKET_SMOKE)
			var soot := Color(0.30, 0.27, 0.25)   # a Hullbreaker rocket's cold, sooty second layer
			_check(smoke.size() >= 3 and smoke[0]["smoke"] and float(smoke[0]["life"]) <= 0.35
				and (smoke[0]["col"] as Color).is_equal_approx(soot),
				"rockets emit a short, cold, soot-tinted smoke layer (fallback %s)" % variant[2])
		_advance(fx, float(p["t1"]) + 0.55)
		_check(fx.dstate["proj"].is_empty() and fx.dstate.get("ptrails", []).is_empty(), "%s clears its flight layers" % variant[0])
		fx.free()
	for variant in [["torp", "voidsworn"], ["htorp", "corsair"], ["startorp", "ithar"]]:
		var fx := _fx()
		_volley(fx, "torp", variant[0], variant[1], true)
		var p: Dictionary = fx.dstate["proj"][0]
		_advance(fx, float(p["dead_at"]) + 0.03)
		var point := WEAP._down_point(p)
		var ring_at := fx.rings.any(func(r: Array) -> bool: return r[0].is_equal_approx(point) and r[1] == 3)
		var flash_at_intercept := fx.flashes.any(func(r: Array) -> bool: return r[0].is_equal_approx(point))
		var star: Node3D = (p["mesh"] as Node3D).get_node_or_null("corona")
		_check(fx.streaks.has(WEAP.BOLT_ENERGY) and ring_at and flash_at_intercept and p.has("down")
			and (star == null or not star.visible), "%s intercept has a layered tracer, counted core and ring before the target" % variant[0])
		fx.free()


func _run() -> void:
	_bolts()
	_plasma_palette()
	_muzzles()
	_muzzle_budget()
	_ordnance()
	print("PASS shared weapon layers" if failures == 0 else "FAIL shared weapon layers: %d" % failures)
	quit(0 if failures == 0 else 1)
