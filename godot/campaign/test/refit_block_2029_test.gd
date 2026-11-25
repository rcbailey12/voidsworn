# Issue 2029 item 8: a refit that cannot be fitted says what is in the way, not "Needs a free compatible slot".
#   godot --headless --path godot --script res://campaign/test/refit_block_2029_test.gd
# C.fitBlock(ship, module) is "" when the refit fits (exactly when canFitModule says so) and otherwise a sentence that names the
# item filling the slot, or says the class has no slot or no part of the kind the refit needs.
extends SceneTree
@warning_ignore_start("untyped_declaration", "unsafe_method_access", "unsafe_call_argument", "inference_on_variant", "unsafe_property_access")
const Campaign = preload("res://campaign/campaign.gd")
var fails := 0

func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok: fails += 1

func _cls(C, h: String) -> String:   # "The Unsetting" stays one article
	var n: String = str(C.HULLS[h]["n"])
	return n if n.begins_with("The ") else "The " + n

func _run() -> void:
	var C = Campaign.new(); C.load_tables(); C.fixed_clock = true
	C.RUN = {"fac": "voidsworn", "fleet": [], "inventory": []}
	var mismatch := 0; var empty := 0; var stale := 0; var dash := 0; var shown := 0
	for h in C.HULLS.keys():
		for m in C.MODULES.keys():
			for fill in [0, 1, 2, 3]:
				var sh := {"uid": "x", "name": "Test", "tpl": h, "mods": []}
				for i in fill: sh["mods"].append("prow" if C.MODULES.has("prow") else C.MODULES.keys()[0])
				var ok: bool = C.canFitModule(sh, m); var why: String = C.fitBlock(sh, m)
				if ok != (why == ""): mismatch += 1
				if not ok:
					shown += 1
					if why.strip_edges() == "": empty += 1
					if why.contains("free compatible slot"): stale += 1
					if why.contains("\u2014") or why.contains("\u2013"): dash += 1
	_check(shown > 0 and mismatch == 0, "fitBlock is empty exactly when canFitModule is true, over every hull, refit and fill (%d blocked cases, %d mismatches)" % [shown, mismatch])
	_check(empty == 0 and stale == 0 and dash == 0, "every blocked case has a sentence, none the old wording or with a dash (%d empty, %d old, %d dashes)" % [empty, stale, dash])
	# slot full: the item that fills it is named
	var hull := ""
	for h in C.HULLS.keys():
		if int(C.HULLS[h].get("slots", 0)) == 1 and C.canFitModule({"tpl": h, "mods": []}, "locker"): hull = h
	_check(hull != "", "test setup: a one-slot hull that takes the locker")
	var full := {"uid": "a", "name": "A", "tpl": hull, "mods": ["prow"]}
	_check(C.fitBlock(full, "locker") == "Slot taken by " + C.modName("prow") + ".", "full slot: names the item (%s)" % C.fitBlock(full, "locker"))
	var two := ""
	for h in C.HULLS.keys():
		if int(C.HULLS[h].get("slots", 0)) == 2 and C.canFitModule({"tpl": h, "mods": []}, "locker"): two = h
	if two != "":
		var f2 := {"uid": "b", "name": "B", "tpl": two, "mods": ["prow", "locker"]}
		var w2: String = C.fitBlock(f2, "locker")
		_check(w2.begins_with("Slots taken by ") and w2.contains(C.modName("prow")) and w2.contains(C.modName("locker")), "two full slots: names both items (%s)" % w2)
	# no slot of that kind: a hull with no lance cannot take the crystal, whatever is fitted
	var no_lance := ""
	for h in C.HULLS.keys():
		if int(C.HULLS[h].get("slots", 0)) >= 1 and not C.canFitModule({"tpl": h, "mods": []}, "crystal"): no_lance = h
	if no_lance != "":
		var w3: String = C.fitBlock({"uid": "c", "name": "C", "tpl": no_lance, "mods": []}, "crystal")
		_check(w3 == _cls(C, no_lance) + " has no lance for this refit.", "no part of that kind: says so (%s)" % w3)
		_check(not w3.contains("taken by"), "an empty hull that cannot take it never says a slot is taken")
	# a hull with no slots
	var none := ""
	for h in C.HULLS.keys():
		if int(C.HULLS[h].get("slots", 0)) == 0: none = h
	if none != "":
		var w4: String = C.fitBlock({"uid": "d", "name": "D", "tpl": none, "mods": []}, "locker")
		_check(w4 == _cls(C, none) + " has no refit slot.", "a hull with no slots says so (%s)" % w4)
	# junk in, no crash
	_check(C.fitBlock(null, "locker") != "" and C.fitBlock({"tpl": hull, "mods": []}, "no-such-refit") != "", "unknown ship or refit gives a plain sentence, no error")
	print("refit_block_2029_test: %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)
