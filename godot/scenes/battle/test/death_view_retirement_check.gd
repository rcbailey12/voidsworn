extends SceneTree
# Issue 2198: test the battle's death and rise paths with its real HUD and FX clock.
const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const WING := preload("res://render/squadron_wing.gd")
var failures := 0


class PhaseFixture extends RefCounted:
	var phase := "player"


class BattleFixture extends "res://scenes/battle/battle.gd":
	func _ready() -> void:
		set_process(false)
		cine = "off"
		cam = CamRig.new()
		add_child(cam)
		cam.set_process(false)
		cam.position = Vector3(0, 8, 40)
		cam.look_at(Vector3.ZERO)
		board = Board.new()
		add_child(board)
		hud = HUD.new()
		add_child(hud)
		sfx = Sfx.new()
		sfx.silent = true
		add_child(sfx)
		death_audio = DeathAudio.new()
		death_audio.sfx = sfx
		add_child(death_audio)
		api = PhaseFixture.new()
		TBL = {"LEGION_HP": 0.35}


func _initialize() -> void:
	GUARD.arm(self, "death_view_retirement_check")
	_run.call_deferred()


func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)


func _ship(battle: BattleFixture, id: String, faction: String, wing := false) -> SV:
	var sv := SV.new()
	battle.add_child(sv)
	sv._ring()
	if wing:
		var craft := WING.new()
		sv.squad_kind = "fighter"
		sv.hull = craft
		sv.add_child(craft)
		craft.setup(faction, sv.squad_kind, 2.0, 2)
	else:
		sv.hull = Node3D.new()
		sv.add_child(sv.hull)
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(8, 2, 3)
		mesh.mesh = box
		mesh.material_override = StandardMaterial3D.new()
		sv.meshes = [mesh]
		sv.hull.add_child(mesh)
		sv._remember_live_hull()
	var unit := {"id": id, "name": id, "fac": faction, "side": "enemy", "cls": "Squadron" if wing else "Frigate",
		"size": 0.1 if wing else 0.55, "squadron": wing, "flagship": false, "active": false,
		"hp": 100.0, "maxHp": 100.0, "sh": [0.0, 0.0, 0.0, 0.0], "shMax": 0.0, "q": 0, "r": 0, "facing": 0, "dead": false}
	battle.views[id] = sv
	battle.VU[id] = unit
	battle._register_fx_ship(unit, sv)
	return sv


func _step_ship(fx: FX, sv: SV, dt: float) -> void:
	fx.step(dt)
	if sv.is_processing(): sv._process(dt)


func _run() -> void:
	var battle := BattleFixture.new()
	root.add_child(battle)
	var fx := FX.new()
	fx.manual = true
	battle.add_child(fx)
	fx.setup({"quality": "low"})
	fx.defer_initial_cuts = true
	battle.gfx = fx
	var wing := _ship(battle, "wing", "hegemony", true)
	var scout := _ship(battle, "scout", "hegemony")
	var anchor := _ship(battle, "anchor", "hegemony")
	var eclipse := _ship(battle, "eclipse", "deathless")
	battle.wrecked["anchor"] = Vector2i.ZERO
	battle.hud.set_plate("never-made", Vector2.ZERO, false, "", true, false, 0, 1, 0, 0)
	_check(not battle.hud.plates.has("never-made"), "F2: hiding an absent HUD plate does not allocate it")
	battle._process(0.016)
	_check(battle.hud.plates.has_all(["wing", "scout", "anchor", "eclipse"]), "F2: fixture has live nameplates")
	for i in 5: _step_ship(fx, wing, 0.06)
	_check(wing.hull.trails[0].hist.size() >= 2, "F2: detailed wing has a trail to drain")
	await battle._play_death({"unit": "wing"})
	_step_ship(fx, wing, 0.15)
	_check(fx.ship("wing") != null and wing.is_processing(), "F2: keep the wing while its trail is visible")
	await process_frame
	for i in 12: _step_ship(fx, wing, 0.06)
	_check(fx.ship("wing") == null and not wing.is_processing() and not wing.hull.is_processing(),
		"F2: dead detailed wing leaves FX and neither view nor craft steps again")
	var wing_clock: float = wing.hull.clock
	await process_frame
	await process_frame
	_check(wing.hull.clock == wing_clock, "F2: removing the FX clock must not restart the dead wing's clock")

	var prior: Dictionary = battle.VU["eclipse"]
	var falling := prior.duplicate()
	falling.merge({"dead": true, "rising": 2, "hp": 0.0}, true)
	await battle._play_death({"unit": "scout", "cause": "dark"})
	await battle._play_death({"unit": "anchor", "cause": "dark"})
	await battle._play_death({"unit": "eclipse", "cause": "dark"}, {"units": [falling]})
	var eclipse_fx = fx.ship("eclipse")
	for i in 6: battle._process(0.016)
	_check(battle.hud.plates.is_empty() and eclipse.has_meta("plate_off"), "F2: frames after death do not recreate deleted nameplates")
	fx.step(0.80)
	_check(fx.ship("scout") != null and scout.is_processing(), "F2: non-wreck stays registered until death's returned duration passes")
	for i in 20: fx.step(0.08)
	_check(fx.ship("scout") == null and not scout.is_processing(), "F2: non-wreck ship retires from FX and ShipView after its tell")
	_check(fx.ship("anchor") != null and not anchor.is_processing() and fx.ship("eclipse") == eclipse_fx and not eclipse.is_processing(),
		"F2: blocking wreck and Eclipse rise candidate stay registered, with their dead views parked")
	battle._reassemble({"unit": "eclipse", "q": 0, "r": 0}, {"units": [prior]})
	battle._process(0.016)
	var fresh_fx = fx.ship("eclipse")
	_check(eclipse.is_processing() and not eclipse.dead and not eclipse.has_meta("plate_off") and battle.hud.plates.has("eclipse"),
		"F2: Risen Eclipse ship regains its update and nameplate")
	_check(fresh_fx != null and fresh_fx != eclipse_fx and not fresh_fx.dead and is_equal_approx(fresh_fx.section_fraction[1], 0.35),
		"F2: Risen Eclipse ship has fresh live FX at restored health")
	if fresh_fx != null:
		var pos: Vector3 = fresh_fx._last_pos
		eclipse.position.x += 2.0
		fx.step(0.06)
		_check(fresh_fx._last_pos != pos, "F2: the Risen ship runs its live FX update")
	battle.queue_free()
	await process_frame
	print("%s F2 retired views, plates and Eclipse rise" % ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures > 0 else 0)
