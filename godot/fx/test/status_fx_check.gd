extends SceneTree

const API := preload("res://rules/battle_api.gd")
const FX := preload("res://fx/fx.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
const SFX := preload("res://audio/sfx.gd")
const SHIP := preload("res://fx/fx_ship.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const SH := preload("res://fx/fx_shaders.gd")

var failures := 0
var fx: FX
var sounds: Array[String] = []
var sizzles: Array[Dictionary] = []


func _init() -> void:
	GUARD.arm(self, "status_fx_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS ", message)


func _run() -> void:
	var api := API.new()
	check(api.load_rules() == "", "rules load")
	api.new_battle_scenario("s1", 1693)
	var target: Dictionary = api.R.alive("player")[0]
	var attacker: Dictionary = api.R.alive("enemy")[0]
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 4, 18)
	var sfx := SFX.new()
	world.add_child(sfx)
	sfx.cue_started.connect(func(cue: String, opts: Dictionary) -> void:
		sounds.append(cue)
		if cue == "acid_sizzle":
			sizzles.append(opts))
	fx = FX.new()
	fx.manual = true
	world.add_child(fx)
	fx.setup({"quality": "low", "sfx": sfx, "camera": camera, "shake": 0.0})
	var box := BoxMesh.new()
	box.size = Vector3(18, 4, 7)
	for unit in [target, attacker]:
		var body := Node3D.new()
		world.add_child(body)
		var mesh := MeshInstance3D.new()
		mesh.mesh = box
		body.add_child(mesh)
		if unit.id == attacker.id: body.position = Vector3(-32, 4, 1)
		fx.add_ship(unit.id, body, {"faction": "deathless" if unit.id == attacker.id else "hegemony",
			"meshes": [mesh], "shielded": unit.id == target.id})
	var s: SHIP = fx.ship(target.id)
	target.st.acid = 2
	target.regenLock = 1
	target.shp = float(target.shMax) * 0.5
	api.R.syncShields(target)
	var u: Dictionary = api.view().units.filter(func(v): return v.id == target.id)[0]
	var empty := u.duplicate()
	empty["shp"] = 0.0
	empty["sh"] = [0, 0, 0, 0]
	var inactive := u.merged({"st": {"acid": 0}}, true)
	# An in-flight shot can delay mist until after the status has already expired.
	s.busy_until = fx.now + 1.0
	fx.sync_ship(s.id, u)
	fx.step(0.05)
	check(s._acid_mist == null and s._acid_next > fx.now, "an in-flight shot delays the first acid puff")
	fx.sync_ship(s.id, inactive)
	fx.step(0.05)
	check(s._acid_next == 0.0 and s._acid_mist_start < 0.0 and s._acid_fallback.is_empty() and s._sizzle_count == 0 and s._sizzle_next == 0.0,
		"acid expiry resets the episode even when no mist spawned")
	s.busy_until = fx.now
	# Start with a restored view, then let an actual bio hull hit supply a new local source.
	fx.sync_ship(s.id, u)
	fx.step(0.05)
	check(s._acid_mist != null and s._acid_mist.emitted == 2 and not s._acid_fallback.is_empty(),
		"an idle restored metal ship emits two acid puffs from real plating without a recorded impact")
	check((s._acid_fallback.get("n", Vector3.ZERO) as Vector3).dot(Vector3.BACK) > 0.9,
		"restored mist starts on the plating facing the camera")
	check(sizzles.size() == 1 and float(sizzles[0].get("gain", 1.0)) <= 0.25, "the first acid sizzle is attenuated")
	check(s._shield_mi.visible and (s._shield_mat.get_shader_parameter("ion_arc") as Vector2).x >= 0.0,
		"the battle view starts a shield arc on the idle ion-locked ship at half shields")
	var partial := u.duplicate()
	partial.erase("shp")
	partial.erase("shMax")
	fx.sync_ship(s.id, partial)
	fx.step(0.05)
	check(s._shield_fraction == 0.5 and (s._shield_mat.get_shader_parameter("ion_arc") as Vector2).x >= 0.0,
		"a partial sync keeps the last known shield fraction and the ion arc")
	var pulse_end := s._ion_until
	fx.sync_ship(s.id, u)
	fx.step(pulse_end - fx.now + 0.01)
	check(not s._shield_mi.visible, "the locked shield goes dark between flickers across repeated syncs")
	fx.step(s._ion_next - fx.now + 0.01)
	check(s._shield_mi.visible and s._ion_until > pulse_end, "the lock produces another idle arc")
	fx.sync_ship(s.id, empty)
	fx.step(0.05)
	check(not s._shield_mi.visible and (s._shield_mat.get_shader_parameter("ion_arc") as Vector2).x < 0.0,
		"draining a shield clears an arc already in progress")
	for i in 8:
		fx.sync_ship(s.id, empty)
		fx.step(0.25)
		if s._shield_mi.visible:
			break
	check(not s._shield_mi.visible, "the empty shield stays dark across repeated ion lock syncs")
	fx.sync_ship(s.id, u)
	fx.step(0.05)
	check((s._shield_mat.get_shader_parameter("ion_arc") as Vector2).x >= 0.0, "an ion lock can flicker again once shields return")
	s.shield_break(fx, 0)
	fx.step(0.05)
	check(s._shield_mi.visible and (s._shield_mat.get_shader_parameter("ion_arc") as Vector2).x < 0.0,
		"a shield break clears the ion arc before the next sync while the collapse still plays")
	fx.volley(attacker.id, "bio", s.id, {"weapon_id": "bioplasma", "shots": [true], "hits": [{"shield": 0, "hull": 2}]})
	for i in 90: fx.step(0.05)
	var spots: Array = s.get_meta("acid_spots", [])
	check(not spots.is_empty(), "a bio volley supplies a recorded hull impact")
	if not spots.is_empty():
		s.root.position += Vector3(13, 0, 5)
		# Start a fresh acid episode on the moved hull. The mixer spaces cues on the wall clock.
		fx.sync_ship(s.id, empty.merged({"st": {"acid": 0}}, true))
		fx.step(0.05)
		sizzles.clear()
		sfx.last.erase("acid_sizzle")
		fx.sync_ship(s.id, empty)
		fx.step(0.05)
		check(sizzles.size() == 1 and sizzles[0].get("pos") == s.to_world(spots.back()[0]),
			"the sizzle rearms and follows the recorded spot on a moved hull")
	var settled_count := 0
	for i in 40:
		sfx.last.erase("acid_sizzle")
		fx.sync_ship(s.id, empty)
		fx.step(0.30)
		if i == 6 and s._acid_mist != null:
			settled_count = s._acid_mist.emitted
	check(sizzles.size() == 2 and float(sizzles[1].get("gain", 1.0)) < float(sizzles[0].get("gain", 1.0)),
		"a long acid episode plays just two sizzles, with the second quieter")
	check(s._acid_mist != null and settled_count > 2 and s._acid_mist.emitted == settled_count
		and s._acid_mist.mi.get_parent() == s._dmg_root,
		"the attached mist settles by two seconds even if acid stays active across syncs")
	var next_hit := fx.volley(attacker.id, "bio", s.id, {"weapon_id": "bioplasma", "shots": [true], "hits": [{"shield": 0, "hull": 2}]})
	if next_hit.impacts.size() == 1:
		fx.step(float(next_hit.impacts[0]) + 0.05)
		fx.step(0.30)
	check(s._acid_mist != null and s._acid_mist.emitted > settled_count and sizzles.size() == 2,
		"another hull hit renews the mist without rearming the sizzles")
	fx.sync_ship(s.id, {"st": {"acid": 0}, "regenLock": false})
	fx.step(0.05)
	check(s._acid_mist == null and not s._shield_mi.visible, "both effects stop when their status expires")

	# Each impact sees its actual remaining pool, even when routing and a later shot change it again.
	target.shp = 30.0
	target.shMax = 100.0
	target.route = [0, 0, 0, 0]
	api.R.syncShields(target)
	api.take_events()
	var hits: Array = []
	for damage in [5.0, 2.0]:
		api.R.applyHit(attacker, {"crit": 0, "pierce": 0}, target, damage, 0)
		hits.append_array(api.take_events().filter(func(e): return e.t == "hit"))
	check(hits.size() == 2 and hits[0].get("shieldFraction") == 0.25 and hits[1].get("shieldFraction") == target.shp / target.shMax,
		"the first hit leaves exactly 25 percent and the second reports its routed pool")
	fx.volley(attacker.id, "battery", s.id, {"shots": [true, true], "hits": hits})
	var strained := 0
	for w in s._hitw:
		if w.w > 0.0: strained += 1
	check(strained == 1, "only the below-quarter hit books a strained ripple")
	check(not sounds.has("shield_sputter"), "the sputter waits for the hit")
	for i in 80: fx.step(0.05)
	check(sounds.count("shield_sputter") == 1, "one sputter plays for the strained hit")
	s.shield_hit(fx, Vector3.RIGHT, fx.now, 1.0, 5.0, 0.5, 0.0)
	check(s._hitw[s._hit_i].w == 0.0, "an empty pool leaves the collapse unstrained")
	_check_bio_palettes(fx.ship(attacker.id), s, world, box)
	world.free()
	print("status_fx_check: %d failures" % failures)
	quit(1 if failures else 0)


func _add_test_hull(id: String, faction: String, at: Vector3, world: Node3D, box: BoxMesh) -> SHIP:
	var body := Node3D.new()
	world.add_child(body)
	body.position = at
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	body.add_child(mesh)
	fx.add_ship(id, body, {"faction": faction, "meshes": [mesh]})
	return fx.ship(id)


func _check_bio_palettes(eclipse: SHIP, control: SHIP, world: Node3D, box: BoxMesh) -> void:
	_add_test_hull("chorus", "chorus", Vector3(-70, 4, 1), world, box)
	var targets: Array[SHIP] = [eclipse, control]
	for faction in ["chorus", "voidsworn", "corsair", "ithar"]:
		targets.append(_add_test_hull(faction + "_target", faction, Vector3(8, 4, targets.size() * 14), world, box))
	fx.quality = "max" # Low skips the impact fume.
	var violet: Color = eclipse.fac.damage_glow
	var green: Color = fx.faction_info("chorus").weapon
	check(eclipse.acid_colour() == violet and violet.b > maxf(violet.r, violet.g), "Eclipse idle and tick acid use its violet damage glow")
	check(SH.BIO_CONTACT_GLOB == 29, "the bio contact glob uses kind 29, clear of the thrust sprite")
	for ship in targets:
		var expected := ship.acid_colour()
		var flash: Color = eclipse.fac.accent if ship == eclipse else expected
		var flash_rgb := Vector3(flash.r, flash.g, flash.b)
		if ship != eclipse:
			var no_lime := expected.g < 0.14 and expected.r < 0.14 and expected.b < 0.14
			var local_colour := expected.g > expected.r if ship.faction == "chorus" else expected.g <= expected.r
			check(no_lime and local_colour, "only Chorus uses dark bile on contact, checked on " + ship.faction)
		var smoke: POOLS.Pool = fx.pools["smk"]
		var streaks: POOLS.Pool = fx.pools["stk"]
		smoke.flush()
		streaks.flush()
		fx.spr_kinds = {}
		var volley := fx.volley("chorus", "bio", ship.id, {"weapon_id": "bioplasma", "shots": [true], "hits": [{"shield": 0, "hull": 2}]})
		if volley.impacts.size() != 1:
			check(false, "Chorus volley hits " + ship.faction)
			continue
		var impact_at: float = fx.now + float(volley.impacts[0])
		var contact := Vector3(expected.r, expected.g, expected.b)
		var drops := 0
		var fumes := 0
		var glob_ok := false
		var colours_ok := true
		var short_lived := true
		var dim := true
		for offset in range(0, smoke.pending.size(), POOLS.STRIDE * smoke.vpp):
			# Read the submitted vertices, one per sprite. The flight glob precedes the impact.
			var rgb := Vector3(smoke.pending[offset + 12], smoke.pending[offset + 13], smoke.pending[offset + 14])
			var kind := int(smoke.pending[offset + 18])
			if smoke.pending[offset + 7] < impact_at - 0.0001:
				if kind == 15:
					glob_ok = _same_hue(rgb, Vector3(green.r, green.g, green.b))
				continue
			if kind == 20:
				fumes += 1
				dim = dim and smoke.pending[offset + 15] < 0.25
			elif kind == SH.BIO_CONTACT_GLOB:
				drops += 1
				dim = dim and smoke.pending[offset + 15] < 1.0 and maxf(maxf(rgb.x, rgb.y), rgb.z) <= 0.25
			else:
				colours_ok = false
			colours_ok = colours_ok and _same_hue(rgb, contact)
			short_lived = short_lived and smoke.pending[offset + 7] + smoke.pending[offset + 11] <= impact_at + 2.0
		check(glob_ok, "Chorus retains its green flight glob toward " + ship.faction)
		check(drops == 8 and fumes > 0 and colours_ok, "bioplasma droplets and fume use the contact palette on " + ship.faction)
		check(dim and short_lived, "contact droplets and fume are dim and gone within two seconds on " + ship.faction)
		var contact_streaks := 0
		for offset in range(0, streaks.pending.size(), POOLS.STRIDE * streaks.vpp):
			if streaks.pending[offset + 7] >= impact_at - 0.0001:
				contact_streaks += 1
		check(not fx.spr_kinds.has(19) and contact_streaks == 0, "bioplasma contact emits no warm vent sparks on " + ship.faction)
		var light: Color = fx._lev.back()[4]
		check(_same_hue(Vector3(light.r, light.g, light.b), flash_rgb), "bioplasma impact light uses the hull's flash palette on " + ship.faction)
		fx.step(float(volley.impacts[0]) + 0.15)
		var heat_pools: Dictionary = fx.dstate.get("heat_pools", {})
		check(not heat_pools.has(ship.id) and not fx.spr_kinds.has(21), "bioplasma leaves no orange heat spot on " + ship.faction)
		ship.flush_damage(fx)
		var splash := fx.get_node_or_null("fx_weapon_flash") as MeshInstance3D
		check(splash != null and _same_hue(splash.material_override.get_shader_parameter("weapon_tint"), flash_rgb),
			"bioplasma splash uses the hull's flash palette on " + ship.faction)
		var vent := fx.get_node_or_null("fx_weapon_vent") as MeshInstance3D
		check(vent != null and _same_hue(vent.material_override.get_shader_parameter("weapon_tint"), contact),
			"bioplasma pressure puff uses the contact palette on " + ship.faction)
		if ship == eclipse:
			check(not eclipse._marks.is_empty() and eclipse._marks.back().wound_kind == 3,
				"the lingering bioplasma scar uses the Eclipse wound kind")
		_check_mist_submission(ship, contact)


func _check_mist_submission(ship: SHIP, expected: Vector3) -> void:
	# Emit through the status path and inspect the submitted particles before the frame flush.
	ship._emit_acid(fx)
	var mist := ship._acid_mist
	var eclipse: bool = ship.faction == "deathless"
	var expected_count := 1 if eclipse else 2
	check(mist != null and mist.n_pending == expected_count, "status mist produces its local puffs on " + ship.faction)
	if mist == null: return
	var ok := true
	for offset in range(0, mist.pending.size(), POOLS.STRIDE * mist.vpp):
		var rgb := Vector3(mist.pending[offset + 12], mist.pending[offset + 13], mist.pending[offset + 14])
		ok = ok and _same_hue(rgb, expected) and mist.pending[offset + 7] + mist.pending[offset + 11] <= fx.now + 2.0
		if not eclipse:
			ok = ok and int(mist.pending[offset + 18]) == 7 and mist.pending[offset + 15] < 0.18
	check(ok, "status mist uses the local palette and a short fade, with no non-Eclipse emission on " + ship.faction)
	mist.flush()


func _same_hue(rgb: Vector3, expected: Vector3) -> bool:
	# Volley power can scale all three channels together.
	return rgb.normalized().is_equal_approx(expected.normalized())
