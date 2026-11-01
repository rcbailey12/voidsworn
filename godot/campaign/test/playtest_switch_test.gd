# R1 (Ryan, Nov 1): the playtest switch. godot --headless --path godot --script res://campaign/test/playtest_switch_test.gd
# Off by default in campaign.gd (the parity harnesses), on when the game UI binds; the player's choice overrides; META underneath is untouched.
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
func _initialize() -> void:
	var C = CampaignScript.new()
	var err = C.load_tables()
	if err != "":
		printerr(err); quit(1); return
	C.META = C.defaultMeta()
	var bad = []
	if C.playtestAll() or C.admiralOwned("malek") or C.legacyHullOn("u_carrier") or C.variantOwned("vs_harrow_t"): bad.append("default must be off in campaign.gd")
	if not C.admiralOwned("kassar"): bad.append("free first admirals stay owned with the switch off")
	C.playtest_default = true
	if not (C.playtestAll() and C.admiralOwned("malek") and C.admiralOwned("khepra") and C.legacyHullOn("u_carrier") and C.legacyHullOn("u_dread") and C.variantOwned("vs_penitent_l")): bad.append("on: every admiral, hull unlock and variant owned")
	if C.legacyHullOn("chest1"): bad.append("on: only the hull unlocks, not war chests")
	C.set_playtest_all(false)
	if C.playtestAll() or C.admiralOwned("malek"): bad.append("the player's off choice must override the default")
	if C.META["admirals"].size() != 1 or C.META["unlocked"].size() != 0 or float(C.META["renown"]) != 0.0: bad.append("META underneath must be untouched")
	print("playtest switch: " + ("PASS" if bad.is_empty() else "FAIL " + "; ".join(PackedStringArray(bad))))
	quit(0 if bad.is_empty() else 1)
