extends SceneTree

const FX := preload("res://fx/fx.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const SHIP := preload("res://fx/fx_ship.gd")
const VIEW := preload("res://render/ship_view.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const SFX := preload("res://audio/sfx.gd")

var failures := 0
var fx: FX
var world: Node3D
var cues: Array[String] = []


func _init() -> void:
	GUARD.arm(self, "wave_1a_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _ship(id: String, faction: String, at := Vector3.ZERO, shield := false) -> SHIP:
	var view := VIEW.new()
	view.fac = faction
	view.position = at
	world.add_child(view)
	view.set_process(false)
	view.hull_pivot = Node3D.new()
	view.hull_pivot.name = "hull_pivot"
	view.add_child(view.hull_pivot)
	view.hull = Node3D.new()
	view.hull_pivot.add_child(view.hull)
	var box := BoxMesh.new()
	box.size = Vector3(24, 5, 8)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	var paint := StandardMaterial3D.new()
	paint.emission_enabled = true
	paint.emission_energy_multiplier = 2.0
	mesh.surface_set_material(0, paint)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	view.hull.add_child(mi)
	view.meshes.append(mi)
	view._ring()
	view.set_marker(false)
	fx.add_ship(id, view, {"faction": faction, "meshes": [mi], "shielded": shield})
	return fx.ship(id)


func _advance(seconds: float) -> void:
	for i in ceili(seconds * 120.0):
		fx.step(1.0 / 120.0)


func _motion() -> void:
	var s := _ship("motion", "hegemony")
	var view: VIEW = s.root
	view.rotation.y = 0.72
	var marker := view.marker.global_transform
	var ring := view.ring.global_transform
	var body := view.global_transform
	s._set_wear(fx, 0.20)
	_advance(0.8)
	var list_before: float = view.hull_pivot.rotation.x
	for height in [-0.3, 0.3]:
		var before := s._kick_v.x
		s.hit_react(fx, 3.0, Vector3(2, height, 4), Vector3.FORWARD)
		_check(s._kick_v.x < before, "midship broadside heels the same way at y=%s" % height)
	_advance(0.17)
	_check(absf(view.hull_pivot.rotation.x - list_before) > 0.006, "hit heels the listing hull")
	_check(view.global_transform.is_equal_approx(body) and view.marker.global_transform.is_equal_approx(marker)
		and view.ring.global_transform.is_equal_approx(ring), "heading, hex marker and selection ring stay on the board")
	_check(view.hull_pivot.global_position.is_equal_approx(body * s._pd), "drift follows base heading during yaw")
	_advance(4.0)
	_check(absf(view.hull_pivot.rotation.x - s.list_target) < 0.002 and view.hull_pivot.position.length() < 0.02,
		"hull recovers to its crippled list and returns to station")
	var heavy := _ship("heavy", "hegemony")
	heavy.weight = 3
	heavy.hit_react(fx, 3.0, Vector3(2, 0, 4), Vector3.FORWARD)
	var full_slide: float = 3.0 * heavy.hull.L * 0.0095 / SHIP.REACT_MASS[3]
	_check(is_equal_approx(heavy._kick_p.length(), full_slide * 0.5), "heavy hull takes half the linear kick")
	_check(SHIP.REACT_SHUDDER_HZ.min() == 3.5 and SHIP.REACT_SHUDDER_HZ.max() == 6.0
		and heavy._shudder_at(fx.now + 0.22) < heavy._shud * 0.06, "tremor stays between 3.5 and 6 Hz and dies down in 0.22 seconds")
	fx.hit_pause(fx.now, 3)
	fx.step(0.0)
	view._process(0.0)
	var before := view._bob_time
	fx.step(0.025)
	view._process(0.025)
	_check(is_equal_approx(view._bob_time, fx.now) and view._bob_time - before < 0.02, "idle bob uses the slowed effect clock")


func _jets() -> void:
	for faction in ["voidsworn", "hegemony", "corsair", "ithar", "deathless", "chorus"]:
		var s := _ship("jets_" + faction, faction)
		s._rv.x = 0.07
		var sprites: int = fx.pools["spr"].emitted + fx.pools["smk"].emitted
		var rings: int = fx.pools["rng"].emitted
		var glow: POOLS.Pool = fx.pools["spr"]
		var smoke: POOLS.Pool = fx.pools["smk"]
		var glow_start := glow.pending.size()
		var smoke_start := smoke.pending.size()
		s._rcs(fx)
		var added: int = fx.pools["spr"].emitted + fx.pools["smk"].emitted - sprites
		var ring_count: int = fx.pools["rng"].emitted - rings
		var jets := 0 if faction in ["deathless", "chorus"] else (2 if faction == "ithar" else 4)
		_check(added == jets and ring_count == (2 if faction == "deathless" else 0), faction + " uses its own correction effect")
		if faction in ["ithar", "chorus"]:
			var gas := false
			for data in [[glow, glow_start], [smoke, smoke_start]]:
				var pool: POOLS.Pool = data[0]
				for i in range(int(data[1]), pool.pending.size(), POOLS.STRIDE * pool.vpp):
					gas = gas or int(pool.pending[i + 14]) == 7
			_check(not gas, faction + " emits no correction gas")


func _impact(s: SHIP, look: String, weight: int, shield: float, hull: float, critical := false) -> void:
	var from := Vector3(0, 0, 100)
	var hit := {"shield": shield, "hull": hull, "section": "mid", "crit": critical}
	var at := WEAP._target(fx, s, s.to_world(s.hull.c), from, true, hit, 1, 1.0)
	WEAP._impact(fx, look, weight, s, at, fx.now, Color.SKY_BLUE, Vector3.FORWARD, hit, 1.0, 0.0)


func _power() -> void:
	var shield := _ship("absorbed", "hegemony", Vector3.ZERO, true)
	var hull := _ship("damaged", "hegemony")
	var ion := _ship("ion", "hegemony", Vector3.ZERO, true)
	var lance := _ship("lance", "hegemony", Vector3.ZERO, true)
	var shell_before: Material = hull.meshes[0].get_active_material(0)
	var pauses := fx._pauses.size()
	_impact(shield, "torp", 3, 20, 0)
	_check(fx._pauses.size() == pauses and not shield._show_rcs and shield._stutter_until < fx.now
		and shield._power_dip == 0.0, "absorbed torpedo has no hit pause, jets, stutter or brownout")
	_impact(hull, "torp", 3, 0, 20)
	_check(is_equal_approx(shield._kick_p.length(), hull._kick_p.length() * 0.12), "the shield absorbs 88% of torpedo impulse")
	_check(hull._stutter_until > fx.now and hull._power_dip >= 0.40, "torpedo hull damage stutters the engine and dims deck lights")
	_impact(ion, "ion", 2, 3, 0)
	_check(ion._stutter_until > fx.now and ion._power_dip >= 0.40, "ion induces stutter and brownout through shields")
	_impact(lance, "lance", 3, 3, 0)
	_check(lance._stutter_until < fx.now and lance._power_dip >= 0.40, "a shielded lance dims the lights without engine stutter")
	shield.shield_break(fx, 1)
	_check(shield._stutter_until > fx.now, "a shield break also stutters the engine")
	var bright := _ship("paint", "voidsworn", Vector3.ZERO, true)
	var original: BaseMaterial3D = bright.meshes[0].get_active_material(0)
	_impact(bright, "ion", 2, 3, 0)
	var dim: BaseMaterial3D = bright.meshes[0].get_active_material(0)
	_check(dim.emission_energy_multiplier < original.emission_energy_multiplier * 0.6, "ion dims emissive paint before hull damage exists")
	var damage := hull.damage_surface(fx, hull.meshes[0], 0, shell_before)
	_advance(0.08)
	_check(float(damage.get_shader_parameter("fx_power")) < 0.8, "damage shader shares the transient power dip")
	_advance(1.0)
	_check(bright.meshes[0].get_active_material(0) == original and float(damage.get_shader_parameter("fx_power")) == 1.0,
		"paint and damage shader recover their original brightness")


func _recoil() -> void:
	var shooter := _ship("shooter", "corsair")
	var target := _ship("recoil_target", "hegemony", Vector3(100, 0, 0))
	var turret := Node3D.new()
	turret.name = "turret_0"
	turret.position.y = 5.0
	shooter.root.get_node("hull_pivot").add_child(turret)
	var barrel := Node3D.new()
	barrel.name = "turret_0_turn"
	turret.add_child(barrel)
	var muzzle := Node3D.new()
	muzzle.name = "hp_w0_hbattery_F_0"
	muzzle.position.z = -2.0
	turret.add_child(muzzle)
	shooter.hull.analyse(shooter.root, shooter.meshes, 71)
	var volleys := {"weapon_id": "hbattery", "slot": 0, "shots": [true]}
	var r := fx.volley(shooter.id, "battery", target.id, volleys)
	_check(not r.fires.is_empty() and int(r.muzzles[0].tur) == 0, "the broadside fires from the turret on the shot clock")
	if r.fires.is_empty():
		return
	_advance(float(r.fires[0]) - 0.02)
	_check(shooter.hull_pivot.position.is_zero_approx() and barrel.position.is_zero_approx(), "recoil waits for the shot")
	_advance(0.065)
	_check(shooter.hull_pivot.position.x < 0.0 and shooter.root.position.is_zero_approx()
		and not shooter.has_meta("last_hit") and shooter._stutter_until < fx.now, "shooter kicks opposite the shot on its hull pivot")
	_check(barrel.position.z > 0.05 and muzzle.position.z > -1.95 and turret.position.y == 5.0, "barrel and muzzle retract along the barrel axis")
	_advance(0.19)
	_check(barrel.position.is_zero_approx() and is_equal_approx(muzzle.position.z, -2.0), "barrel and muzzle return to battery")


func _miss() -> void:
	var s := _ship("graze", "hegemony", Vector3(0, 0, 140), true)
	var centre := s.to_world(s.hull.shield_centre())
	var rim := s.shield_point(centre + Vector3.RIGHT * 200.0)
	var point: Vector3 = rim["p"]
	var from := point + Vector3.FORWARD * 60.0
	var exit := point + Vector3.BACK * 18.0
	var aimed := WEAP._target(fx, s, centre, from, false, {}, 0, 1.0)
	_check((aimed.p as Vector3).z > centre.z and s.hull.ray(s.xf().affine_inverse() * from,
		s.xf().basis.inverse() * ((aimed.p as Vector3) - from)).is_empty(), "a miss clears the hull and extends beyond the target plane")
	fx._later.clear()
	var sprites: int = fx.pools["spr"].emitted
	var streaks: int = fx.pools["stk"].emitted
	var n := cues.size()
	var end := WEAP._miss_fade(fx, "macro", s, {"p": exit, "pass": point}, from, fx.now, fx.now + 0.50, Color.WHITE, Vector3.BACK, 1.0)
	_check(fx.pools["stk"].emitted == streaks + 1 and end > fx.now + 0.50, "miss adds a cooling streak beyond the exit")
	fx.now += 0.30
	fx._run_later()
	_check(cues.size() == n and fx.pools["spr"].emitted == sprites, "pass-by cue and graze wait for the projectile")
	fx.now += 0.12
	fx._run_later()
	_check(cues.size() == n + 1 and cues[-1] == "shot_pass_by", "pass-by cue plays at the target plane")
	_check(fx.pools["spr"].emitted == sprites + 1 and s._hit_i == 0, "close shield graze sparks without triggering shield damage FX")


func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	var sfx := SFX.new()
	world.add_child(sfx)
	sfx.cue_started.connect(func(cue: String, _options: Dictionary) -> void: cues.append(cue))
	fx = FX.new()
	fx.manual = true
	fx.defer_initial_cuts = true
	world.add_child(fx)
	fx.setup({"quality": "high", "shake": 0.0, "sfx": sfx})
	_motion()
	_jets()
	_power()
	_recoil()
	_miss()
	world.free()
	print("PASS wave_1a_check" if failures == 0 else "FAIL wave_1a_check: %d" % failures)
	quit(0 if failures == 0 else 1)
