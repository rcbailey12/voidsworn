extends SceneTree
# Issue 1262: cheaper 4K battles on Max. Max skips SSIL like High; the board's underlay plane is hidden while a look
# draws it at zero and shown again for the tactical grid; Max storm cards use High's bounded cards. Limiting ring-rock
# shadows was measured on the PC (RUN1262D), saved nothing and was dropped. VS_1262_OLD brings each old way back.

const GUARD := preload("res://tools/ci/check_guard.gd")
const LOOK := preload("res://render/look.gd")
const BL := preload("res://world/board_look.gd")

class LookBench extends "res://bench/look_bench.gd":
	func _ready() -> void:
		pass

	func _grid() -> void:
		pass

var failures := 0


func _init() -> void:
	GUARD.arm(self, "max_4k_cost_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if ok: print("  ok: ", message)
	else:
		failures += 1
		print("FAIL: ", message)


func _run() -> void:
	OS.set_environment("VS_1262_OLD", "")
	var env := Environment.new()
	LOOK.apply(env, null, null, {"quality": "max"})
	_check(env.ssao_enabled and not env.ssil_enabled, "Max keeps SSAO and skips SSIL")
	OS.set_environment("VS_1262_OLD", "ssil")
	LOOK.apply(env, null, null, {"quality": "max"})
	_check(env.ssil_enabled, "VS_1262_OLD=ssil brings SSIL back for the before timing")
	OS.set_environment("VS_1262_OLD", "")

	BL.set_look("cine", false)
	BL.tactical = false
	var look := LookBench.new()
	root.add_child(look)
	look._setup_view()
	var terrain := {}
	for key in LookBench.STORM_HEXES:
		terrain[key] = "storm"
	terrain["0,-4"] = "rock"
	terrain["-5,3"] = "rock"
	await look._world({"rock": "stone", "planet": 4}, terrain, [{"q": 0, "r": 0}])
	var w = look.wld
	_check(w._under_mi != null and not w._under_mi.visible, "the cine look's zero underlay is not drawn")
	BL.tactical = true
	w.set_look()
	_check(w._under_mi.visible, "the tactical grid (underlay 0.45) shows the underlay again")
	BL.tactical = false
	w.set_look()
	_check(not w._under_mi.visible, "leaving the tactical grid hides it again")

	var storms: Array = w.find_children("Storm", "MultiMeshInstance3D", true, false)
	var bounded := 0
	for s in storms:
		var m := (s as MultiMeshInstance3D).material_override as ShaderMaterial
		if m != null and m.shader.code.contains("#define HIGH_GAS_CARDS"): bounded += 1
	_check(not storms.is_empty() and bounded == storms.size(), "Max storm cards use the bounded High cards (%d of %d)" % [bounded, storms.size()])

	look.free()
	if failures == 0: print("PASS: cheaper 4K Max (issue 1262)")
	else: print("FAIL: %d cheaper 4K Max checks" % failures)
	quit(1 if failures else 0)
