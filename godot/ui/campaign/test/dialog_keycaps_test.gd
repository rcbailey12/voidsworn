extends SceneTree
# Issue 1559 items 7 and 26 (menus audit): in a campaign dialog the number keys 1 to 9 pick its enabled actions in order, so every
# one of those actions must show its key cap. The boon offer ran Reroll on 4 and Decline on 5 with no cap shown, and Decline
# cannot be taken back. Opens the boon offer (as boon_fleet_test stages it) and checks, for each number key the dialog takes,
# that a control in the dialog for that action carries a cap with that number. Then presses the Reroll key and checks it
# rerolled (the key matches the cap).
# Prints PASS or FAIL lines; exit 0 when all pass.
# Pictures: add -- --shots DIR, with a renderer.
# Run: godot --headless --path godot --script res://ui/campaign/test/dialog_keycaps_test.gd
const Campaign = preload("res://campaign/campaign.gd")
const CampaignUI = preload("res://ui/campaign/campaign_ui.gd")
const JSM = Campaign.JSM
var fails := 0


func _initialize() -> void:
	_run.call_deferred()


func _ok(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: fails += 1


func _frames(n := 5) -> void:
	for i in n: await process_frame


# every control in the dialog tagged for this action, with the key caps drawn inside it
func _caps_for(n: Node, act: String, arg: String, out: Array) -> void:
	for ch in n.get_children(true):
		if ch.has_meta("press_act") and str(ch.get_meta("press_act")) == act and str(ch.get_meta("press_arg")) == arg:
			for l in _labels(ch):
				out.append(l.text)
		_caps_for(ch, act, arg, out)


func _labels(n: Node) -> Array:
	var r := []
	for ch in n.get_children(true):
		if ch is Label and (ch as Label).has_theme_stylebox_override("normal"):
			r.append(ch)
		r.append_array(_labels(ch))
	return r


func _key(code: int) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		root.push_input(e)
		await process_frame


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var c = Campaign.new()
	var err: String = c.load_tables()
	if err != "":
		_ok(false, err)
		quit(1)
		return
	c.fixed_clock = true
	c.playtest_default = true
	c.persist_on = false
	JSM.rnd_seed(1075)
	c.newRun("vex", "voidsworn")
	c.RUN["fleet"] = []
	for row in [["penitent", "Oath"], ["harrow", "Spark"], ["reliquary", "Hearth"]]:
		var ship: Dictionary = c.newShip(row[0])
		ship["name"] = row[1]
		c.RUN["fleet"].append(ship)
	c.ensureFlagship()
	c.RUN["patrons"] = ["star", "storm", "iron", "ember"]
	c.mapScreen()
	c.RUN["credits"] = 999
	c.RUN["reward"] = {"kind": "elite", "stage": "pick", "rw": {"k": "boon", "p": "star", "min": 1}}
	c.show_page("battle", {}, [])
	var ui = CampaignUI.new()
	ui.use_3d_map = false
	root.add_child(ui)
	ui.bind(c)
	c.resumeReward()
	await _frames()
	_ok(c.modal_d != null and str(c.modal_d.get("kind", "")) == "boon", "the boon offer is open")
	if c.modal_d == null:
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	if args.has("--shots"):   # -- --shots DIR: the dialog's picture (needs a window: xvfb-run with opengl3 in the cloud)
		await RenderingServer.frame_post_draw
		var shot_err: int = preload("res://tools/picture_provenance.gd").save_png(root.get_texture().get_image(), args[args.find("--shots") + 1].path_join("I1559_boon_keycaps.png"), "cloud direction check")
		_ok(shot_err == OK, "shot I1559_boon_keycaps saved with its stamp (error %d; the stage arrives with #1606)" % shot_err)
	var on: Array = c.modal_d["acts"].filter(func(a): return a[2] == 1)
	var reroll_key := -1
	for i in range(mini(9, on.size())):
		var caps := []
		_caps_for(ui.modal_box, str(on[i][0]), str(on[i][1]), caps)
		_ok(caps.has(str(i + 1)), "key %d (%s) shows its cap in the dialog (caps %s)" % [i + 1, on[i][0], str(caps)])
		if on[i][0] == "boonReroll":
			reroll_key = i
	_ok(reroll_key >= 0, "Reroll is offered")
	if reroll_key >= 0:
		var before := JSON.stringify(c.modal_d["data"]["offer"])
		await _key(KEY_KP_1 + reroll_key)   # item 26: the keypad's digits work in a dialog too
		await _frames()
		_ok(c.modal_d != null and str(c.modal_d.get("kind", "")) == "boon" and JSON.stringify(c.modal_d["data"]["offer"]) != before, "pressing Reroll's key (on the keypad) rerolls the offer")
	# item 26: Esc on the relic pick goes Back to the event
	var relics: Array = c.RELICS.keys().slice(0, 2)
	c.RUN["relics"] = relics
	c.cur_event = {"id": "t1559", "t": "A trade", "b": "A trader wants a piece of salvage.", "o": [{"l": "Trade", "s": "Give one piece.", "r": {"payRelic": true}}]}
	c.relic_pick_modal(0)
	await _frames()
	_ok(c.modal_d != null and str(c.modal_d.get("kind", "")) == "relic_pick", "the relic pick is open")
	await _key(KEY_ESCAPE)
	await _frames()
	_ok(c.modal_d != null and str(c.modal_d.get("kind", "")) == "event", "item 26: Esc on the relic pick goes Back to the event (%s)" % str(c.modal_d.get("kind", "") if c.modal_d != null else "none"))
	# item 25: with the Dossier open, Jump on the rail still flies (it shuts the slide-over first)
	c.modal_d = null
	c.mapScreen()
	await _frames()
	ui._open_overlay("dossier")
	await _frames()
	var picked := str(ui.picked)
	_ok(str(c.page.get("kind", "")) == "map" and picked != "" and str(c.RUN.get("pos", "")) != picked and ui._overlay == "dossier", "item 25: the map is up with the Dossier open and a route picked (%s)" % picked)
	ui._jump()
	await _frames()
	_ok(ui._overlay == "" and str(c.RUN.get("pos", "")) == picked, "item 25: Jump with the Dossier open shuts it and goes to the pick (pos %s)" % str(c.RUN.get("pos", "")))
	print("DIALOG_KEYCAPS fails=%d" % fails)
	quit(1 if fails else 0)
