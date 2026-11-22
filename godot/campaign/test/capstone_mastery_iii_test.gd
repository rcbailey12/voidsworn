extends SceneTree
# Issue 1650 (Part A of build variety 1453): every capstone has one Mastery III signature with a handler in the rules,
# every admiral has one Mastery I doctrine row, the text fits its slots, and a run carries exactly the chosen capstone's
# mastery through a save, a respec to the other capstone and a reload (never both signatures, never neither).
#   godot --headless --path godot --script res://campaign/test/capstone_mastery_iii_test.gd
const Campaign = preload("res://campaign/campaign.gd")
var failures := 0

func check(value, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func pickCap(c, id: String, cap: int) -> void:
	if not (c.META.get("lineage") is Dictionary): c.META["lineage"] = {}
	c.META["lineage"][id] = {"picks": ["A:0:0", "B:0:0", "C:0:0"], "capstone": cap, "respecs": 0}

func _init() -> void:
	var c = Campaign.new()
	var error = c.load_tables()
	if error != "":
		printerr(error); quit(1); return
	c.fixed_clock = true
	var rt = JSON.parse_string(FileAccess.get_file_as_string("res://rules/data/tables.json"))["tables"]
	var src = FileAccess.get_file_as_string("res://rules/rules.gd")

	# key coverage: 48 capstones, one signature row each in both table files, one capM3 handler each
	var keys = []
	for id in c.LINEAGE_TREES.keys():
		var caps = c.LINEAGE_TREES[id].get("capstones", [])
		check(caps.size() == 2, id + " has two capstones")
		for i in range(caps.size()): keys.append("%s:cap:%d" % [id, i])
	check(keys.size() == 48, "48 capstone keys (got %d)" % keys.size())
	check(c.CAPSTONE_MASTERY_FX.size() == 48 and rt["CAPSTONE_MASTERY_FX"].size() == 48, "48 Mastery III rows in each table file, no extras")
	for k in keys:
		var row = c.CAPSTONE_MASTERY_FX.get(k)
		check(row != null and rt["CAPSTONE_MASTERY_FX"].get(k) == row, k + " has the same Mastery III row in both table files")
		if row == null: continue
		check(str(row["n"]).length() > 0 and str(row["n"]).length() <= 32, k + " name fits 32 characters")
		check(str(row["d"]).length() > 0 and str(row["d"]).length() <= 140, k + " line fits 140 characters")
		var fx = rt["TREE_FX"].get(k)
		check(fx != null and fx.get("k") != null, k + " has a tree effect key")
		if fx != null: check(src.contains('capM3("%s")' % fx["k"]), k + " (" + str(fx["k"]) + ") has a Mastery III handler in rules.gd")

	# Mastery I: one doctrine row per admiral, under the admiral who owns it
	check(c.MASTERY_I_FX.size() == c.ADMIRALS.size() and rt["MASTERY_I_FX"].size() == c.ADMIRALS.size(), "one Mastery I row per admiral in each table file")
	for a in c.ADMIRALS.keys():
		check(c.MASTERY_I_FX.has(a) and str(c.MASTERY_I_FX[a]).length() > 0, a + " has a Mastery I doctrine row")
	check(c.CAPSTONE_MASTERY_PERKS.size() == 3, "three mastery step titles")
	for p in c.CAPSTONE_MASTERY_PERKS:
		check(str(p["n"]).length() <= 24 and str(p["d"]).length() <= 120, str(p["n"]) + " fits its slots")

	# earn, run, save, respec to the other capstone, reload: only the chosen capstone's signature is ever active
	var id = "vaelen"
	c.META = c.migrateMeta(c.defaultMeta()); c.META["admirals"][id] = true; c.META["mastery"][id] = 600.0; pickCap(c, id, 0)
	c.newRun(id, str(c.ADMIRALS[id]["fac"]))
	check(c.RUN != null and c.RUN["lineage"]["capstone"] == 0 and int(c.RUN["lineage"]["mastery"]) == 3, "a run at 600 XP carries Mastery III of capstone 0")
	check(c.capstoneSignature(id) == c.CAPSTONE_MASTERY_FX[id + ":cap:0"], "the lineage screen names capstone 0's signature")
	c.load_save_text(c.save_text())
	check(c.RUN != null and int(c.RUN["lineage"]["mastery"]) == 3 and c.RUN["lineage"]["capstone"] == 0, "the run's mastery survives a save and reload")
	c.RUN = null; c.SAVED_RUN = null; c.META["renown"] = 1000   # the run ended: a line resets only between runs
	check(c.lineageRespec(id), "the line resets between runs")
	check(c.capstoneSignature(id) == null and c.capstoneMasteryLevel(id) == 0, "a reset line has no signature and no mastery")
	pickCap(c, id, 1)
	c.load_save_text(c.save_text())
	check(c.capstoneMasteryLevel(id) == 3, "the other capstone earns Mastery III from the same XP after a reload")
	check(c.capstoneSignature(id) == c.CAPSTONE_MASTERY_FX[id + ":cap:1"], "the lineage screen now names capstone 1's signature, not capstone 0's")
	c.newRun(id, str(c.ADMIRALS[id]["fac"]))
	check(c.RUN != null and c.RUN["lineage"]["capstone"] == 1 and int(c.RUN["lineage"]["mastery"]) == 3, "the next run carries only capstone 1 at Mastery III")
	# below the first step, a capstone run carries mastery 0
	c.RUN = null; c.META["mastery"][id] = 300.0
	c.newRun(id, str(c.ADMIRALS[id]["fac"]))
	check(c.RUN != null and int(c.RUN["lineage"]["mastery"]) == 0, "a capstone run under 320 XP carries no mastery")

	print("PASS: 48 Mastery III signatures with handlers, 24 Mastery I rows, and only the chosen capstone's mastery reaches a run." if failures == 0 else "FAIL: %d checks" % failures)
	quit(0 if failures == 0 else 1)
