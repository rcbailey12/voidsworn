extends SceneTree
# Run with --headless, or pass -- <screenshot directory> with a renderer.
const Campaign = preload("res://campaign/campaign.gd")
const UI = preload("res://ui/campaign/campaign_ui.gd")
var fails := 0
var screenshot_dir := ""

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		printerr("FAIL: " + message)

func text_of(node: Node) -> String:
	var text := ""
	if node is Label or node is RichTextLabel: text += node.text + "\n"
	for child in node.get_children(): text += text_of(child)
	return text

func shot(name_: String) -> void:
	if screenshot_dir == "": return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(screenshot_dir.path_join(name_ + ".png"))

func settle() -> void:
	for i in range(4): await process_frame

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: screenshot_dir = args[0]
	if screenshot_dir != "": DirAccess.make_dir_recursive_absolute(screenshot_dir)
	var c = Campaign.new()
	check(c.load_tables() == "", "campaign tables load")
	c.persist_on = false
	var ui = UI.new()
	ui.use_3d_map = false  # Text screen checks do not need sector models.
	root.add_child(ui)
	ui.bind(c)
	await process_frame
	for fac in c.RUN_FACTIONS:
		var row: Dictionary = c.TB.STORY_BEAT3[fac]
		var count := 0
		for id in c.ADMIRALS:
			if c.ADMIRALS[id]["fac"] != fac: continue
			count += 1
			c.newRun(id, fac); c.RUN["sector"] = 3
			c.mapScreen()
			check(c.showBeat3(), str(id) + " opens decision")
			await settle()
			var text := text_of(ui)
			check(text.contains(row["spotlights"][id]), str(id) + " spotlight renders")
			for line in row["lines"]: check(text.contains(line), str(id) + " spoken line renders")
			check(not text.contains("{rival}") and not text.contains("undefined"), str(id) + " no placeholder")
			if count == 1: await shot(str(fac) + "_decision")
		check(count == 4, str(fac) + " four admirals")
		for i in range(2):
			var id = row["spotlights"].keys()[0]
			c.newRun(id, fac); c.RUN["sector"] = 3; c.mapScreen(); c.showBeat3()
			c.act("eventChoice", str(i))
			check(c.RUN["flags"].get(row["id"]) == str(i), str(fac) + " shipped choice id")
			c.RUN = c.clone(c.SAVED_RUN)
			check(c.beat3Card().is_empty(), str(fac) + " saved choice does not replay")
			check(c.beat3Debrief() == row["debrief"], str(fac) + " battle debrief text")
			await settle()
			check(text_of(ui).contains(c.beat3Text(row["o"][i]["tx"])), str(fac) + " result text renders")
			if i == 0: await shot(str(fac) + "_result")
			c.rewardFlow({"cfg": {"kind": "battle", "fac": "hegemony"}, "kills": 2, "rounds": 4, "lost": [], "xp": []})
			await settle()
			check(text_of(ui).contains(row["debrief"]), str(fac) + " battle debrief renders")
			if i == 0: await shot(str(fac) + "_battle_debrief")
		for won in [false, true]:
			c.newRun(row["spotlights"].keys()[0], fac); c.RUN["sector"] = 3
			c.endRun(won)
			await settle()
			check(text_of(ui).contains(row["learning"]), str(fac) + " learning renders after " + str(won))
			await shot(str(fac) + ("_win" if won else "_loss"))
	ui.queue_free()
	print("PASS: beat 3, six factions, 24 spotlights, both results, saved decisions and win/loss debrief screens." if fails == 0 else "FAIL: %d checks" % fails)
	quit(0 if fails == 0 else 1)
