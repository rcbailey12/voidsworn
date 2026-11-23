extends SceneTree

const API := preload("res://rules/battle_api.gd")
const FX := preload("res://fx/fx.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
const SFX := preload("res://audio/sfx.gd")
const SHIP := preload("res://fx/fx_ship.gd")

var failures := 0
var fx: FX
var sounds: Array = []


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
	var sfx := SFX.new()
	world.add_child(sfx)
	sfx.cue_started.connect(func(cue: String, opts: Dictionary) -> void: sounds.append([cue, opts.get("pos")]))
	fx = FX.new()
	fx.manual = true
	world.add_child(fx)
	fx.setup({"quality": "low", "sfx": sfx, "shake": 0.0})
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
	var u: Dictionary = api.view().units.filter(func(v): return v.id == target.id)[0]
	# Start with a restored view, then let an actual bio hull hit supply a new local source.
	fx.sync_ship(s.id, u)
	fx.step(0.05)
	check(s._acid_mist != null and s._acid_mist.emitted == 1 and not s._acid_fallback.is_empty(),
		"an idle restored acid ship emits from real plating without a recorded impact")
	check(s._shield_mi.visible and (s._shield_mat.get_shader_parameter("ion_arc") as Vector2).x >= 0.0,
		"the battle view starts a shield arc on the idle ion-locked ship")
	var pulse_end := s._ion_until
	fx.sync_ship(s.id, u)
	fx.step(pulse_end - fx.now + 0.01)
	check(not s._shield_mi.visible, "the locked shield goes dark between flickers across repeated syncs")
	fx.step(s._ion_next - fx.now + 0.01)
	check(s._shield_mi.visible and s._ion_until > pulse_end, "the lock produces another idle arc")
	fx.volley(attacker.id, "bio", s.id, {"weapon_id": "bioplasma", "shots": [true], "hits": [{"shield": 0, "hull": 2}]})
	for i in 90: fx.step(0.05)
	var spots: Array = s.get_meta("acid_spots", [])
	check(not spots.is_empty(), "a bio volley supplies a recorded hull impact")
	if not spots.is_empty():
		s.root.position += Vector3(13, 0, 5)
		# Start a fresh audio window. The mixer spaces cues on the wall clock while this test advances effect time.
		sfx.last.erase("acid_sizzle")
		fx.step(maxf(0.0, s._sizzle_next - fx.now) + 0.31)
		check(sounds.has(["acid_sizzle", s.to_world(spots.back()[0])]), "the sizzle follows the recorded spot on a moved hull")
	check(s._acid_mist != null and s._acid_mist.emitted > 2 and s._acid_mist.mi.get_parent() == s._dmg_root,
		"one hull-attached mist pool keeps emitting while idle")
	fx.sync_ship(s.id, {"st": {"acid": 0}, "regenLock": false})
	fx.step(0.05)
	check(s._acid_mist == null and not s._shield_mi.visible, "both effects stop when their status expires")
	var eclipse: SHIP = fx.ship(attacker.id)
	check(eclipse._acid_colour() == eclipse.fac.damage_glow and eclipse._acid_colour().b > eclipse._acid_colour().g, "Eclipse acid uses its violet damage glow")

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
	check(sounds.all(func(row): return row[0] != "shield_sputter"), "the sputter waits for the hit")
	for i in 80: fx.step(0.05)
	check(sounds.filter(func(row): return row[0] == "shield_sputter").size() == 1, "one sputter plays for the strained hit")
	s.shield_hit(fx, Vector3.RIGHT, fx.now, 1.0, 5.0, 0.5, 0.0)
	check(s._hitw[s._hit_i].w == 0.0, "an empty pool leaves the collapse unstrained")
	world.free()
	print("status_fx_check: %d failures" % failures)
	quit(1 if failures else 0)
