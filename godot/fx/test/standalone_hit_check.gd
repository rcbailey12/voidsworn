extends SceneTree
## Issue 1974: standalone battle hits use the same shield and hull reactions as volleys.

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const FLOOK := preload("res://fx/faction_look.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const SV := preload("res://render/ship_view.gd")

var failures := 0

class BattleFixture extends "res://scenes/battle/battle.gd":
	var generic_pops := 0

	func _ready() -> void:
		set_process(false)

	func _flash(_p: Vector3, _size: float, _col: Color, _dur := 0.35, _delay := 0.0, _light := true) -> void:
		generic_pops += 1

	func _float(_id, _text: String, _col: Color, _dy := 0.0) -> void:
		pass

	func _tip_completed(_e: Dictionary) -> void:
		pass

class RecordingSfx extends Node:
	var hull_hits: Array[bool] = []
	var shield_hits: Array = []

	func hit(_p = null, heavy := false) -> void:
		hull_hits.append(heavy)

	func shield(_p = null, big := false, fac := "") -> void:
		shield_hits.append([big, fac])


func _init() -> void:
	GUARD.arm(self, "standalone_hit_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	for faction in ["ithar", "chorus", "deathless"]:
		await _check_faction(faction)
	print("standalone_hit_check: %d failures" % failures)
	quit(1 if failures else 0)


func _check_faction(faction: String) -> void:
	var battle := BattleFixture.new()
	root.add_child(battle)
	battle.user_speed = 0.01
	var sfx := RecordingSfx.new()
	battle.sfx = sfx
	battle.add_child(sfx)
	var fx := FX.new()
	battle.gfx = fx
	battle.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low"})
	fx.dstate["hit_logging"] = true
	var sv := SV.new()
	battle.add_child(sv)
	sv.set_process(false)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(24, 4, 6)
	mesh.mesh = box
	sv.add_child(mesh)
	fx.add_ship("target", sv, {"faction": faction, "cls": "Cruiser", "size": 1.0, "meshes": [mesh]})
	var ship := fx.ship("target")
	battle.views["target"] = sv
	battle.VU["target"] = {"fac": faction}
	battle.disp["target"] = {"hp": 40.0, "sh": [8.0, 8.0, 8.0, 8.0]}

	var hit := {"t": "hit", "unit": null, "target": "target", "quad": 1, "section": "mid",
		"shield": 3.0, "hull": 0.0, "crit": true, "regenLock": true}
	await battle._play_batch({"events": [hit], "view": {}})
	fx.step(0.02)
	var reactions: Array = fx.dstate.get("hit_log", [])
	_check(reactions.any(func(note): return note.what == "ripple" and note.fam == "shield")
		and battle.disp["target"]["sh"][1] == 5.0, faction + " shield ripples and takes the hit")
	_check(battle.generic_pops == 0 and fx.get_node_or_null("fx_staged_flash") == null and ship._marks.is_empty(),
		faction + " shield block makes no hull pop")
	_check(ship._stutter_until < fx.now and ship._dip_peak == 0.0, faction + " shield blocks crit and ion reactions")
	_check(sfx.shield_hits == [[false, faction]] and sfx.hull_hits.is_empty(), faction + " shield block plays only the shield cue")

	await battle._play_batch({"events": [hit, {"t": "shield_down", "unit": "target", "quad": 1}], "view": {}})
	fx.step(0.02)
	_check(ship._stutter_until > fx.now and ship._dip_peak > 0.0, faction + " shield break lets the ion crit reaction through")
	_check(battle.generic_pops == 0 and fx.get_node_or_null("fx_staged_flash") == null and ship._marks.is_empty(),
		faction + " shield break with zero hull damage makes no hull pop")

	var hull_hit := {"t": "hit", "unit": null, "target": "target", "quad": 1, "section": null,
		"shield": 0.0, "hull": 5.0, "crit": false, "float": false}
	await battle._play_batch({"events": [hull_hit], "view": {}})
	fx.step(0.02)
	var flash := fx.get_node_or_null("fx_staged_flash") as MeshInstance3D
	_check(battle.generic_pops == 0 and flash != null, faction + " hull impact uses the weapon FX")
	_check(not ship._marks.is_empty(), faction + " hull impact leaves a mark")
	if flash != null:
		var tint: Color = FLOOK.of(faction).damage_glow
		if faction == "ithar":
			tint = WEAP.IMPACT_RESPONSE.glass.tint
		elif faction == "chorus":
			tint = WEAP.IMPACT_RESPONSE.bio.tint
		var mat := flash.material_override as ShaderMaterial
		var actual: Vector3 = mat.get_shader_parameter("impact_tint")
		_check(actual.is_equal_approx(Vector3(tint.r, tint.g, tint.b)), faction + " hull flash carries its own tint")
	_check(battle.disp["target"]["hp"] == 35.0 and battle.music_hits == 3, faction + " hull damage and hit count still apply")
	var expected_shield_cues := [[false, faction], [false, faction], [true, faction]]
	_check(sfx.shield_hits == expected_shield_cues and sfx.hull_hits == [false], faction + " shield breaks and hull hits keep their cues")

	var marks_before: int = ship._marks.size()
	var notes_before := reactions.size()
	var stutter_before: float = ship._stutter_until
	var dip_before: float = ship._dip_start
	var no_damage := {"t": "hit", "unit": null, "target": "target", "quad": 1, "section": "mid",
		"shield": 0.0, "hull": 0.0, "crit": true, "float": false}
	await battle._play_batch({"events": [no_damage], "view": {}})
	fx.step(0.02)
	_check(ship._marks.size() == marks_before, faction + " zero-damage crit leaves no hull mark")
	_check(reactions.size() == notes_before and ship._stutter_until == stutter_before and ship._dip_start == dip_before,
		faction + " zero-damage crit makes no impact reaction")
	_check(sfx.hull_hits == [false] and sfx.shield_hits == expected_shield_cues, faction + " zero-damage crit plays no impact cue")

	no_damage["crit"] = false
	no_damage["regenLock"] = true
	notes_before = reactions.size()
	await battle._play_batch({"events": [no_damage], "view": {}})
	fx.step(0.02)
	_check(ship._marks.size() == marks_before, faction + " zero-damage ion hit leaves no hull mark")
	var ion_reactions := reactions.slice(notes_before)
	_check(ion_reactions.size() == 1 and ion_reactions[0].what == "flash" and ion_reactions[0].fam == "lance",
		faction + " zero-damage ion hit makes only its flash")
	_check(ship._stutter_until == stutter_before and ship._dip_start == dip_before,
		faction + " zero-damage ion hit leaves drive and power alone")
	fx.release()
	battle.queue_free()
	await process_frame
