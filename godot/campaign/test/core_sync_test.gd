extends SceneTree
# Run with browser fixtures from core_sync_tests.js. Optional second arg saves UI shots.
const Campaign = preload("res://campaign/campaign.gd")
const UI = preload("res://ui/campaign/campaign_ui.gd")
const JSM = preload("res://rules/jsm.gd")
var failures := 0
var c
var ui

func check(value, message: String) -> void:
	if not value: failures += 1; printerr("FAIL: " + message)

func _initialize() -> void:
	c = Campaign.new(); var error = c.load_tables()
	if error != "": printerr(error); quit(1); return
	c.fixed_clock = true
	_run()

func shot(dir: String, name: String) -> void:
	for i in range(8): await process_frame
	if name.begins_with("core_sync_debrief"):
		for toast in ui.toast_box.get_children(): toast.queue_free()
		for label in ui.page_box.find_children("*", "Label", true, false):
			if label.text == "CORE SYNC":
				for scroll in ui.page_box.find_children("*", "ScrollContainer", true, false): scroll.ensure_control_visible(label)
		for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(dir.path_join(name + ".png")) == OK, "save " + name)

func _run() -> void:
	var args = OS.get_cmdline_user_args()
	if args.is_empty(): printerr("Expected browser fixture path"); quit(1); return
	var shots = args.size() > 1 and DisplayServer.get_name() != "headless"
	if shots:
		DirAccess.make_dir_recursive_absolute(args[1])
		ui = UI.new(); root.add_child(ui); ui.bind(c)
		ui.use_3d_map = false
	var fixtures = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	for f in fixtures:
		c.META = c.migrateMeta(f["meta"].duplicate(true)); c.SAVED_RUN = null; c.newRun("vex", "voidsworn"); c.toasts.clear()
		var notices = []
		for i in range(f["picks"].size()):
			var o = f["picks"][i]; var b = c.BOONS[o["id"]]; var p = b.get("p", b.get("duo", [""])[0])
			c.RUN["reward"] = {"kind": "story", "rw": {"k": "boon", "p": p}, "stage": "pick"}; c.W["boonOffer"] = [o]
			c.ACT_takeBoon("0")
			for msg in c.toasts:
				if msg.begins_with("Core sync: "): notices.append(msg)
			if shots and f["name"] == "tier 4":
				c.fleetScreen("map")
				await shot(args[1], "core_sync_tier_up")
			c.toasts.clear()
			if f.get("resume", false) and i == 0:
				var baseline = c.RUN["coreSync"].duplicate(true)
				c.load_save_text(c.save_text()); c.RUN = c.SAVED_RUN.duplicate(true)
				check(c.RUN["coreSync"] == baseline, "baseline survives reopening")
		c.endRun(f.get("victory", false), f.get("abandoned", false))
		var cores = c.page["data"]["run"]["carry"]["inheritance"]["cores"]
		check(JSM.canon(cores) == JSM.canon(f["cores"]), f["name"] + ": exact debrief parity")
		check(notices == f["notices"], f["name"] + ": exact announcement parity")
		if shots and f["name"] in ["tier 4", "duo tiers", "past full sync"]:
			await shot(args[1], "core_sync_debrief_" + str(f["name"]).replace(" ", "_"))
	print("PASS: core sync announcements and inheritance match browser fixtures." if failures == 0 else "FAIL: %d checks" % failures)
	quit(0 if failures == 0 else 1)
