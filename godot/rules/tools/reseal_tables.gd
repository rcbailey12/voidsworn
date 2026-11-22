# Issue 1654 (R405): Godot is the only rules source, so the two table files are edited by hand now, not exported from
# the browser files. After an edit, reseal their checksums (the ports refuse a table file whose checksum differs):
#   godot --headless --path godot --script res://rules/tools/reseal_tables.gd            (writes both files)
#   godot --headless --path godot --script res://rules/tools/reseal_tables.gd -- check   (changes nothing; exit 1 if stale)
# Only the "sha256" field changes; the tables and the required list stay byte for byte as written.
extends SceneTree
const RulesScript = preload("res://rules/rules.gd")
const CampaignScript = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")
const FILES = {"res://rules/data/tables.json": RulesScript, "res://campaign/data/campaign_tables.json": CampaignScript}

func _init() -> void:
	var check_only := OS.get_cmdline_user_args().has("check")
	var bad := 0
	for path in FILES:
		var txt := FileAccess.get_file_as_string(path)
		var j = JSON.parse_string(txt)
		if not (j is Dictionary) or not (j.get("tables") is Dictionary) or not j.has("sha256"):
			printerr("FAIL: cannot read ", path); bad += 1; continue
		var port = FILES[path].new()
		var sum: String = JSM.sha256(JSM.canon(port._dec(j["tables"]), "t", {}, true))
		var old := str(j["sha256"])
		if sum == old:
			print("  ", path, ": checksum current"); continue
		if check_only:
			printerr("FAIL: ", path, " checksum is stale (run reseal_tables.gd without 'check')"); bad += 1; continue
		var at := txt.find(old)
		if at < 0 or txt.find(old, at + 1) >= 0:
			printerr("FAIL: ", path, ": cannot find the one old checksum to replace"); bad += 1; continue
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(txt.substr(0, at) + sum + txt.substr(at + old.length()))
		f.close()
		print("  ", path, ": resealed ", old.substr(0, 12), " -> ", sum.substr(0, 12))
	print("FAIL: reseal tables" if bad else "PASS: reseal tables")
	quit(1 if bad else 0)
