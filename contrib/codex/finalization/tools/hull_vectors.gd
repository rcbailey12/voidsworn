extends SceneTree
const Campaign = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")
func _init() -> void:
	var args = OS.get_cmdline_user_args()
	if args.size() != 1: printerr("output path required"); quit(2); return
	var c = Campaign.new()
	var err = c.load_tables()
	if err != "": printerr(err); quit(1); return
	c.RUN = null
	var out = FileAccess.open(args[0], FileAccess.WRITE)
	if out == null: printerr("cannot open output"); quit(2); return
	var ids = c.HULLS.keys(); ids.sort()
	var mods = c.MODULES.keys(); mods.sort()
	var count = 0
	for id in ids:
		var h = c.HULLS[id].duplicate(true); h.erase("n")
		out.store_line(JSON.stringify({"id": id + ":hull", "state": JSM.canon(h, "", {}, true)})); count += 1
		for mod in mods:
			out.store_line(JSON.stringify({"id": id + ":fit:" + mod, "allowed": c.canFitModule({"tpl": id, "mods": []}, mod)})); count += 1
		for mk in [1, 3]:
			var s = {"uid": "fixture", "tpl": id, "name": "fixture", "mk": mk, "hp": 1, "mods": [], "cap": {"perks": []}}
			var d = c.derive(s)
			for w in d["weapons"]: w.erase("n")
			out.store_line(JSON.stringify({"id": id + ":derive:" + str(mk), "state": JSM.canon(d, "", {}, true)})); count += 1
	out.close(); print(count, " native hull/fitting/derived records"); quit()
