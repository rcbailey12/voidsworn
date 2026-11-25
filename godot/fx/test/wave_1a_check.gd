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
	# R412 rule 4 (Neon on PR 1699): a shield block is quiet: an absorbed ion, lance or crit neither stutters the engine
	# nor browns out the hull; the same shots on the hull do
	_impact(ion, "ion", 2, 3, 0)
	_check(ion._stutter_until < fx.now and ion._power_dip == 0.0, "a shield-absorbed ion is quiet: no stutter, no brownout")
	_impact(lance, "lance", 3, 3, 0)
	_check(lance._stutter_until < fx.now and lance._power_dip == 0.0, "a shield-absorbed lance is quiet")
	var crit_s := _ship("crit_shield", "hegemony", Vector3.ZERO, true)
	_impact(crit_s, "macro", 3, 3, 0, true)
	_check(crit_s._stutter_until < fx.now and crit_s._power_dip == 0.0, "a shield-absorbed crit is quiet")
	var ion_h := _ship("ion_hull", "hegemony", Vector3.ZERO, true)
	_impact(ion_h, "ion", 2, 0, 3)
	var lance_h := _ship("lance_hull", "hegemony", Vector3.ZERO, true)
	_impact(lance_h, "lance", 3, 0, 3)
	_check(ion_h._stutter_until > fx.now and ion_h._power_dip >= 0.40, "an ion that reaches the hull stutters and browns out")
	_check(lance_h._stutter_until > fx.now and lance_h._power_dip >= 0.40, "a lance on the hull browns out")
	shield.shield_break(fx, 1)
	_check(shield._stutter_until > fx.now, "a shield break also stutters the engine")
	# Neon on PR 1699 item c: one brownout path. A fresh hull gets its damage surfaces (no painted copies), the dip rides
	# on fx_flick, and fx_power keeps the wear's steady value.
	var bright := _ship("paint", "voidsworn", Vector3.ZERO, true)
	_check(bright._damage_surfaces.is_empty(), "a fresh hull has no damage surfaces before its first felt hit")
	_impact(bright, "ion", 2, 0, 3)
	_check(not bright._damage_surfaces.is_empty() and bright.meshes[0].get_active_material(0) is ShaderMaterial,
		"an ion hull hit gives a fresh hull its damage surfaces")
	_check(not "_dip_materials" in bright and not bright.has_method("power_dip") and not bright.has_method("_dim_paint"),
		"the painted-copy dip and the separate crawl dip are gone")
	_advance(0.08)
	var lo := _flick_range(bright)
	_check(lo.x < 0.6, "the brownout reaches the hull as fx_flick (lowest %.2f)" % lo.x)
	_check(lo.y == 1.0, "fx_power keeps the wear's steady value under the brownout (%.2f)" % lo.y)
	_advance(1.0)
	lo = _flick_range(bright)
	_check(bright._power_dip == 0.0 and lo.x == 1.0 and lo.y == 1.0, "the hull's lights recover their full brightness")
	_ion_hull("fresh", false)
	_ion_hull("wounded", true)


# The lowest mesh flicker and surface wear power (1.0 when the hull has neither).
func _flick_range(s) -> Vector2:
	var out := Vector2.ONE
	for mi: MeshInstance3D in s.meshes:
		var fl = mi.get_instance_shader_parameter(&"fx_flick")
		if fl != null: out.x = minf(out.x, float(fl))
	for key in s._damage_surfaces:
		var e: Array = s._damage_surfaces[key]
		if e.size() > 1 and e[1] is ShaderMaterial:
			var pw = (e[1] as ShaderMaterial).get_shader_parameter("fx_power")
			out.y = minf(out.y, 1.0 if pw == null else float(pw))
	return out


# Artoo on PR 1699: an ion HULL hit (the beam's impact and its crawl, as fx_weapons plays them) brownouts once: the hit's
# own dip (hit_power), never a second crawl dip multiplied on top; on a fresh hull and on a wounded one,
# whose ordinary wound flicker keeps running.
func _ion_hull(tag: String, wounded: bool) -> void:
	var s := _ship("ion_hull_" + tag, "hegemony")
	s.wound_log_on = true
	if wounded:
		fx.sync_ship(s.id, {"hp": 40.0, "maxHp": 100.0, "burning": false, "sh": [0, 0, 0, 0],
			"sec": {"eng": {"hp": 100, "max": 100}, "mid": {"hp": 10, "max": 100}, "prow": {"hp": 100, "max": 100}}})
		_advance(0.5)
	var p: Vector3 = s.to_world(s.hull.c + Vector3(0, s.hull.H * 0.5, 0))
	_impact(s, "ion", 2, 0, 6)
	WEAP._ion_crawl(fx, s, p, Vector3.UP, fx.now, Color.SKY_BLUE, 1.0)
	_advance(0.08)
	_check(s._dip_peak >= 0.60 and s._power_dip > 0.0, "%s hull: an ion hull hit dims its lights once (peak %.2f, now %.2f)" % [tag, s._dip_peak, s._power_dip])
	var dips := 0
	for e in s.wound_log:
		dips += 1 if e[0] == "power_dip" else 0
	_check(dips == 1, "%s hull: the ion crawl adds no second dip (%d dips)" % [tag, dips])
	_check(s.power_flicker(fx.now) >= 0.5, "%s hull: only the wound flicker rides on the hit's dip (%.2f)" % [tag, s.power_flicker(fx.now)])
	_advance(1.2)
	_check(s._power_dip == 0.0, "%s hull: the dip recovers" % tag)


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
	var barrel_peak := barrel.position.z
	_advance(0.19)
	_check(barrel.position.is_zero_approx() and is_equal_approx(muzzle.position.z, -2.0), "barrel and muzzle return to battery")
	# Neon on PR 1699: a light turreted gun (autocannon, not in SHOOTER_RECOIL) kicks too, with a shorter stroke, and a
	# turret whose barrel mesh has its own name still moves (the mesh fallback)
	var light_s := _ship("light_shooter", "hegemony", Vector3(0, 0, -60))
	var lt := Node3D.new()
	lt.name = "turret_0"
	lt.position.y = 5.0
	light_s.root.get_node("hull_pivot").add_child(lt)
	var gun_mesh := MeshInstance3D.new()
	gun_mesh.name = "gun_barrels"
	gun_mesh.mesh = BoxMesh.new()
	lt.add_child(gun_mesh)
	var lm := Node3D.new()
	lm.name = "hp_w0_autocannon_F_0"
	lm.position.z = -2.0
	lt.add_child(lm)
	light_s.hull.analyse(light_s.root, light_s.meshes, 71)
	var lr := fx.volley(light_s.id, "battery", target.id, {"weapon_id": "autocannon", "slot": 0, "shots": [true]})
	_check(not lr.fires.is_empty() and int(lr.muzzles[0].tur) == 0, "the autocannon fires from its turret")
	if lr.fires.is_empty():
		return
	_advance(float(lr.fires[0]) + 0.045)
	var kick := gun_mesh.position.z
	_check(kick > 0.02 and kick < barrel_peak, "the light gun's own-named barrel mesh kicks back, shorter (%.3f, heavy %.3f)" % [kick, barrel_peak])
	_check(is_equal_approx(lm.position.z, -2.0), "the light kick leaves its muzzle socket still, so the next shot leaves the turned muzzle (%.3f)" % lm.position.z)
	_advance(0.25)
	_check(gun_mesh.position.is_zero_approx(), "and returns to battery")


func _last_stk() -> PackedFloat32Array:
	var pool = fx.pools["stk"]
	var pend: PackedFloat32Array = pool.pending
	return pend.slice(pend.size() - 20) if pend.size() >= 20 else PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, -1])


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
	# Neon on PR 1699: a world-length streak (4 units at scale 1, not divided by the speed) in the weapon's own kind
	var row := _last_stk()
	_check(absf(row[16] - 4.0) < 1e-3 and int(row[19]) == 0, "a shell miss streaks %.2f units long, kind %d (4, 0)" % [row[16], int(row[19])])
	WEAP._miss_fade(fx, "las", s, {"p": exit}, from, fx.now, fx.now + 0.50, Color.WHITE, Vector3.BACK, 1.0)
	row = _last_stk()
	_check(int(row[19]) == 4, "a laser miss streaks in the laser kind (%d)" % int(row[19]))
	fx.now += 0.30
	fx._run_later()
	_check(cues.size() == n and fx.pools["spr"].emitted == sprites, "pass-by cue and graze wait for the projectile")
	fx.now += 0.12
	fx._run_later()
	_check(cues.size() == n + 1 and cues[-1] == "shot_pass_by", "pass-by cue plays at the target plane")
	_check(fx.pools["spr"].emitted == sprites + 1 and s._hit_i == 0, "close shield graze sparks without triggering shield damage FX")


# Artoo on PR 1699: the battle sets up its effects before it builds its Sfx node, so fx.setup sees no sound; a miss's
# pass-by cue must still find the battle's Sfx once it exists (fx.sound() reads the host's sfx field at play time).
class _Host extends Node3D:
	var sfx = null


class _Ear extends Node:   # stands in for the battle's Sfx (the real one spaces repeats of a cue, see _miss)
	var got: Array = []
	func play(cue: String, _o := {}) -> void:
		got.append(cue)


func _late_sfx(_sfx) -> void:
	var host := _Host.new()
	world.add_child(host)
	var fx2 := FX.new()
	fx2.manual = true
	host.add_child(fx2)
	fx2.setup({"quality": "low", "shake": 0.0})
	_check(fx2.sound() == null, "an effects node set up before the battle's Sfx has no sound yet")
	var ear := _Ear.new()
	host.add_child(ear)
	host.sfx = ear
	fx2.shot_pass_by(fx2.now, Vector3.ZERO)
	for i in 3:
		fx2.step(1.0 / 60.0)
	_check(fx2.sound() == ear and ear.got.has("shot_pass_by"), "the pass-by cue finds the Sfx built after setup (%s)" % str(ear.got))


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
	_late_sfx(sfx)
	world.free()
	print("PASS wave_1a_check" if failures == 0 else "FAIL wave_1a_check: %d" % failures)
	quit(0 if failures == 0 else 1)
