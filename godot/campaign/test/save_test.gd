# G3: the campaign save is atomic and keeps a backup. Headless:
#   godot --headless --path godot --script res://campaign/test/save_test.gd
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
func _init() -> void:
	var fails := 0
	var C = CampaignScript.new()
	var err = C.load_tables()
	if err != "": printerr(err); quit(1); return
	C.save_path = "user://save_test.json"; C.persist_on = true
	for p in [C.save_path, C.save_path + ".bak", C.save_path + ".tmp", C.save_path + ".bak.tmp"]:
		if FileAccess.file_exists(p): DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	C.META["renown"] = 11; C.persist_save(true)
	C.META["renown"] = 22; C.persist_save(true)
	C.META["renown"] = 33; C.persist_save(true)
	var cur = JSON.parse_string(FileAccess.get_file_as_string(C.save_path)); var bak = JSON.parse_string(FileAccess.get_file_as_string(C.save_path + ".bak"))
	if cur == null or int(cur["meta"]["renown"]) != 33: fails += 1; printerr("FAIL: the save holds the latest profile")
	if bak == null or int(bak["meta"]["renown"]) != 22: fails += 1; printerr("FAIL: the backup holds the save before it")
	if FileAccess.file_exists(C.save_path + ".tmp") or FileAccess.file_exists(C.save_path + ".bak.tmp"): fails += 1; printerr("FAIL: no temp file is left behind")
	# a damaged save falls back to the backup
	var f = FileAccess.open(C.save_path, FileAccess.WRITE); f.store_string("{\"meta\": {\"renown\": 4"); f.close()
	var D = CampaignScript.new(); D.load_tables(); D.save_path = C.save_path; D.persist_on = true; D.persist_load()
	if int(D.META.get("renown", -1)) != 22: fails += 1; printerr("FAIL: a damaged save loads the backup (got %s)" % str(D.META.get("renown")))
	print("save: " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails > 0 else 0)
