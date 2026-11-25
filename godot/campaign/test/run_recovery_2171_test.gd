extends SceneTree
# Issue 2171: exercise Continue and the save on disk, including both copies after abandoning.
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


func _init() -> void:
	var path := "user://recovery_2171_%d.json" % OS.get_process_id()
	var c = campaign(path)
	c.ACT_newRunScreen()
	c.act("startRun")
	var offer: Array = c.W["aspOffer"].duplicate()
	var d = campaign(path)
	d.persist_load()
	d.titleScreen()
	d.act("continueRun")
	check(d.page.get("kind") == "aspect" and d.W.get("aspOffer") == offer,
		"Continue before the aspect pick shows the same offer, not the map")
	if d.page.get("kind") == "aspect":
		d.act("pickAspect", offer[0])
		check(d.modal_d is Dictionary and d.modal_d.get("kind") == "intro",
			"the resumed pick opens the intro that triggers the rename")
		d.act("saveQuit")
		d.act("continueRun")
		check(d.page.get("kind") == "map" and not d.modal_d is Dictionary, "a completed pick resumes on the map")

	c.act("pickAspect", offer[0])
	c.RUN["stats"]["battles"] = 2
	c.saveRun()
	c.titleScreen()
	c.act("newRunScreen")
	var before: Dictionary = c.META.duplicate(true)
	var save: String = c.save_path
	c.save_path = save.path_join("no_such_folder/save.json")
	c.act("abandonRun")
	check(c.SAVED_RUN != null and c.META == before and c.modal_d is Dictionary and c.modal_d.get("kind") == "abandon",
		"a failed abandon write keeps the checkpoint, the confirmation and the unchanged profile")
	c.save_path = save
	c.act("abandonRun")
	check(c.SAVED_RUN == null and c.page.get("kind") == "end" and c.META["renown"] == before["renown"] + 4,
		"a successful abandon clears the run and pays its earned renown once")
	var backup = campaign(path + ".bak")
	backup.persist_load()
	check(backup.SAVED_RUN == null and backup.META["renown"] == c.META["renown"],
		"backup recovery cannot resurrect the abandoned checkpoint or lose its earnings")

	var broken = campaign(path)
	broken.newRun("vex", "voidsworn")
	var entry: Dictionary = JSON.parse_string(broken.save_text())
	entry["meta"]["renown"] = 37
	entry["run"]["fleet"] = []
	broken.load_save_text(JSON.stringify(entry))
	broken.titleScreen()
	broken.act("continueRun")
	check(broken.modal_d is Dictionary and broken.modal_d.get("kind") == "brokenRun",
		"Continue on an unusable run opens the recovery confirmation")
	if broken.modal_d is Dictionary and broken.modal_d.get("kind") == "brokenRun":
		var stats: Dictionary = broken.META["stats"].duplicate(true)
		broken.act("discardBrokenRun")
		var fresh = campaign(path)
		fresh.persist_load()
		check(fresh.SAVED_RUN == null and not Campaign.has_saved_run(path) and fresh.META["renown"] == 37
			and fresh.META["stats"] == stats, "discard clears only the broken run and keeps profile progress")
		check(broken.page.get("kind") == "admiral", "discard returns to new-run setup without a debrief")
	quit(0 if failures == 0 else 1)
