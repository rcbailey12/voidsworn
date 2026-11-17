extends SceneTree
# Issue 932: a hull figure reads as a whole number rounded up, so a live ship never reads 0; numstr is unchanged.
const Campaign = preload("res://campaign/campaign.gd")
var fails := 0

func check(ok: bool, message: String) -> void:
	if ok: print("PASS: " + message)
	else: fails += 1; printerr("FAIL: " + message)

func _initialize() -> void:
	var C = Campaign.new()
	check(Campaign.hull_text(25.5) + " / " + Campaign.hull_text(40) == "26 / 40", "25.5 / 40 reads 26 / 40")
	check(Campaign.hull_text(0.5) + " / " + Campaign.hull_text(40) == "1 / 40", "0.5 / 40 reads 1 / 40")
	check(Campaign.hull_text(0) == "0" and Campaign.hull_text(-3) == "0", "a dead hull still reads 0")
	check(Campaign.hull_text(40) == "40", "a whole hull reads unchanged")
	check(C.numstr(25.5) == "25.5", "numstr still prints the browser's 25.5, unchanged")
	print("Hull text: " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)
