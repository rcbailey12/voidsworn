extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1410 (R368): render/hull_age.gd tells a NEW ship layout from an old Nov 1 one by reading the tracked manifest
# (assets/ships/manifest.json), and its guard refuses old hulls in reference runs unless ALLOW_OLD_HULLS=1.
#   godot --headless --path godot --script res://render/test/hull_age_check.gd
# Prints HULL_AGE_CHECK PASS or FAIL; exit 0 only on PASS.

const HullAge := preload("res://render/hull_age.gd")
const SV := preload("res://render/ship_view.gd")

var fails := 0


func _init() -> void:
	GUARD.arm(self, "hull_age_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _run() -> void:
	check(HullAge.layout("V14_23") == "NEW", "V14_23 is NEW")
	check(HullAge.layout("H7_23") == "OLD", "H7_23 is OLD")
	check(HullAge.layout("ZZ1410_NOPE") == "UNLISTED", "an unknown code is UNLISTED")
	check(HullAge.label("V14_23") == "V14_23 NEW", "label of a new hull")
	check(HullAge.label("H7_23") == "H7_23 OLD hull", "label of an old hull")
	check(HullAge.label("ZZ1410_NOPE") == "ZZ1410_NOPE UNLISTED", "label of an unknown code")
	var kept := OS.get_environment("ALLOW_OLD_HULLS")   # the check sets it itself, then puts it back
	OS.unset_environment("ALLOW_OLD_HULLS")
	check(HullAge.guard(["V14_23", "O1_37"]) == "", "guard passes a new hull and the teaching station O1_37")
	var msg := HullAge.guard(["H7_23"])
	check(msg.contains("H7_23"), "guard names H7_23: " + msg)
	check(HullAge.guard(["V14_23", "H7_23", "ZZ1410_NOPE"]).contains("ZZ1410_NOPE"), "guard names an unlisted code too")
	OS.set_environment("ALLOW_OLD_HULLS", "1")
	check(HullAge.guard(["H7_23"]) == "", "ALLOW_OLD_HULLS=1 lets H7_23 through")
	OS.unset_environment("ALLOW_OLD_HULLS")
	check(HullAge.guard(["H7_23"]) != "", "the guard is back on once ALLOW_OLD_HULLS is unset")
	if kept != "":
		OS.set_environment("ALLOW_OLD_HULLS", kept)

	# a ShipView for a code the cache does not know draws the placeholder block (headless has no gen folder)
	var sv := SV.new()
	root.add_child(sv)
	sv.setup({"id": "hull_age_zz", "fac": "hegemony", "cls": "Frigate", "code": "ZZ1410_NOPE", "facing": 0}, Vector3.ZERO)
	var r: Dictionary = HullAge.resolved(sv)
	check(r.get("code") == "ZZ1410_NOPE" and r.get("source") == "placeholder" and r.get("res") == "",
		"resolved() on an unknown code reports placeholder: %s" % str(r))
	sv.queue_free()
	await process_frame
	SV.clear_static()
	print("HULL_AGE_CHECK " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)
