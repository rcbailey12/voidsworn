extends SceneTree
# Issue 2217: a readable primary with a valid run but no profile must take the profile from the backup
# of the same save, and must never borrow a profile from a different save.
# Headless:
#   godot --headless --path godot --script res://campaign/test/profile_recovery_2217_test.gd
const Campaign := preload("res://campaign/campaign.gd")
var failures := 0


func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok: failures += 1


func campaign(path: String):
	var c = Campaign.new()
	assert(c.load_tables() == "")
	c.save_path = path
	c.persist_on = true
	c.fixed_clock = true
	return c


func read_json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func write_json(path: String, data) -> void:
	var f = FileAccess.open(path, FileAccess.WRITE)
	assert(f != null)
	f.store_string(JSON.stringify(data))
	f.close()


func drop_meta(path: String) -> void:
	var entry := read_json(path)
	entry.erase("meta")
	write_json(path, entry)


func _init() -> void:
	var tag := str(OS.get_process_id())

	# 1. Same run: the backup is one save behind the primary, so both copies carry this run.
	var same_run_path := "user://profile_recovery_2217_run_%s.json" % tag
	var a = campaign(same_run_path)
	a.META["renown"] = 271
	a.META["stats"]["wins"] = 3
	a.newRun("vex", "voidsworn")
	a.SAVED_RUN["stats"]["battles"] = 1
	a.persist_save()
	drop_meta(same_run_path)
	var first = campaign(same_run_path)
	first.persist_load()
	check(first.SAVED_RUN != null and int(first.SAVED_RUN["stats"]["battles"]) == 1,
		"a valid primary run survives when the primary lost its profile")
	check(int(first.META.get("renown", 0)) == 271 and int(first.META["stats"].get("wins", 0)) == 3,
		"the same-run backup supplies the missing renown and stats")

	# 2. Profile-only backup: the save written before this run started belongs to the same save too.
	var profile_path := "user://profile_recovery_2217_profile_%s.json" % tag
	var b = campaign(profile_path)
	b.META["renown"] = 314
	b.META["stats"]["wins"] = 5
	b.persist_save(true)
	b.newRun("vex", "voidsworn")
	drop_meta(profile_path)
	var second = campaign(profile_path)
	second.persist_load()
	check(second.SAVED_RUN != null and int(second.SAVED_RUN["fac"].length()) > 0,
		"a valid primary run survives when the backup is profile-only")
	check(int(second.META.get("renown", 0)) == 314 and int(second.META["stats"].get("wins", 0)) == 5,
		"a profile-only backup of the same save supplies the missing renown and stats")

	# 3. Different save: the backup carries another run, so its profile must never be borrowed.
	var diff_path := "user://profile_recovery_2217_diff_%s.json" % tag
	var c = campaign(diff_path)
	c.META["renown"] = 271
	c.newRun("vex", "voidsworn")
	c.persist_save()
	var good := read_json(diff_path)
	var primary := good.duplicate(true)
	primary.erase("meta")
	var backup := good.duplicate(true)
	backup["meta"]["renown"] = 9999
	backup["meta"]["stats"]["wins"] = 99
	backup["run"]["t0"] = float(good["run"]["t0"]) + 5000.0
	write_json(diff_path, primary)
	write_json(diff_path + ".bak", backup)
	var third = campaign(diff_path)
	third.persist_load()
	check(third.SAVED_RUN != null, "a primary run survives beside a backup from a different save")
	check(int(third.META.get("renown", 0)) != 9999 and int(third.META["stats"].get("wins", 0)) != 99,
		"a backup from a different save never lends its renown or stats")

	print("profile recovery: " + ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)
