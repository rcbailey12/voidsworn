extends SceneTree
# Issue 1518 (Artoo on PR 1445, 6784b6b1): writes a valid, resumable campaign run into this launch's user:// so the PC
# harness (contrib/opus/pc/1434/load1434_runs.ps1) can launch the title cold with a saved run (its first button
# "Continue run"). The same steps as main/test/title_continue_test.gd. It refuses unless user:// sits inside a
# load10 close profile, so it never writes over a real profile.
const Campaign := preload("res://campaign/campaign.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var ud := ProjectSettings.globalize_path("user://").replace("\\", "/")
	if not ud.contains("/load10/close_"):
		printerr("[save1434] FAIL: refusing to write a campaign save outside a load10 close profile (%s)" % ud)
		quit(1)
		return
	var c := Campaign.new()
	var error := c.load_tables()
	if error != "":
		printerr("[save1434] FAIL: ", error)
		quit(1)
		return
	c.persist_on = true
	c.fixed_clock = true
	preload("res://rules/jsm.gd").rnd_seed(1124)
	c.titleScreen()
	c.act("newRunScreen")
	c.act("startRun")
	if c.modal_d != null and c.modal_d.get("kind") == "aspect":
		c.act("pickAspect", c.W["aspOffer"][0])
	c.act("saveQuit")
	var ok: bool = Campaign.has_saved_run(c.save_path)
	print("[save1434] %s: a resumable run %s at %s" % ["PASS" if ok else "FAIL", "saved" if ok else "was not saved", ProjectSettings.globalize_path(c.save_path)])
	quit(0 if ok else 1)
