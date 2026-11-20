extends SceneTree
# Headless by default. With a renderer, --shots DIR captures the real modal at 1080p and 4K.
# --base-ref REV compares the fixed-seed run with the actual campaign and UI sources at REV.

const Campaign = preload("res://campaign/campaign.gd")
const CampaignUI = preload("res://ui/campaign/campaign_ui.gd")
const JSM = Campaign.JSM
var fails := 0
var viewport: SubViewport


func _initialize() -> void:
	_run.call_deferred()


func _ok(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok: fails += 1


func _base_script(rev: String, path: String) -> GDScript:
	var repo := ProjectSettings.globalize_path("res://../")
	var child := OS.execute_with_pipe("git", ["-C", repo, "show", rev + ":godot/" + path], true)
	if child.is_empty(): return null
	var stream: FileAccess = child["stdio"]
	var bytes := PackedByteArray()
	while true:
		var chunk := stream.get_buffer(16384)
		if chunk.is_empty(): break
		bytes.append_array(chunk)
	if bytes.is_empty(): return null
	var script := GDScript.new()
	script.source_code = bytes.get_string_from_utf8()
	return script if script.reload() == OK else null


func _campaign(script: GDScript = Campaign):
	var c = script.new()
	var err: String = c.load_tables()
	if err != "":
		_ok(false, err)
		return null
	c.fixed_clock = true
	c.playtest_default = true
	return c


func _attach_ui(c, script: GDScript = CampaignUI):
	var ui = script.new()
	ui.use_3d_map = false
	viewport.add_child(ui)
	ui.bind(c)
	return ui


func _settle() -> void:
	for i in 5: await process_frame


func _labels(n: Node) -> Array[Label]:
	var result: Array[Label] = []
	for child in n.get_children():
		if child is Label: result.append(child)
		result.append_array(_labels(child))
	return result


func _details(ui, c) -> Array[String]:
	var labels := _labels(ui.modal_box)
	var result: Array[String] = []
	for entry in c.modal_d["data"]["offer"]:
		var description: String = c.BOON_D[entry.id][int(entry.r)]
		for label in labels:
			if label.text.begins_with(description):
				result.append(label.text)
				break
	return result


func _set_fleet(c, rows: Array) -> void:
	c.RUN["fleet"] = []
	for row in rows:
		var ship: Dictionary = c.newShip(row[0])
		ship["name"] = row[1]
		c.RUN["fleet"].append(ship)
	c.ensureFlagship()


func _seeded_reward(seed: int, campaign_script: GDScript, ui_script: GDScript) -> Dictionary:
	var c = _campaign(campaign_script)
	if c == null: return {}
	JSM.rnd_seed(seed)
	c.newRun("vex", "voidsworn")
	_set_fleet(c, [["penitent", "Oath"], ["harrow", "Spark"], ["reliquary", "Hearth"]])
	c.RUN["patrons"] = ["star", "storm", "iron", "ember"]
	c.RUN["boons"] = [{"id": "a_aim", "r": 0}, {"id": "a_crit", "r": 1}, {"id": "s_ion", "r": 0}]
	c.mapScreen() # Prepare the map and its rewards as on the way to a battle.
	c.RUN["reward"] = {"kind": "elite", "stage": "pick", "rw": {"k": "boon", "p": "star", "min": 1}}
	c.show_page("battle", {}, [])
	var ui = _attach_ui(c, ui_script) if ui_script != null else null
	var pool := JSON.stringify([c.boonOfferPool("star"), c.boonOfferDuos("star"), c.boonOfferCan("star", 1)])
	c.resumeReward()
	var save: String = c.save_text()
	var offer: String = JSON.stringify(c.modal_d)
	var run: String = JSON.stringify(c._enc(c.RUN))
	if ui != null: await _settle()
	var read_only: bool = (c.save_text() == save and JSON.stringify(c.modal_d) == offer and JSON.stringify(c._enc(c.RUN)) == run)
	var first_pick_count: int = c.modal_d["data"]["offer"].size()
	var has_details := ui == null or _details(ui, c).size() == first_pick_count
	c.act("boonReroll", "star:1")
	if ui != null:
		await _settle()
		ui.free()
	return {"pool": pool, "offer": offer, "save": save, "reroll": JSON.stringify(c.modal_d),
		"rerolled_save": c.save_text(), "next_random": JSM.rnd(), "read_only": read_only,
		"first_pick_count": first_pick_count, "has_details": has_details}


func _reopen(save: String) -> void:
	var c = _campaign()
	if c == null: return
	c.load_save_text(save)
	var before: String = c.save_text()
	var saved_offers: Array = JSON.parse_string(save)["run"]["reward"]["boonOffer"]
	JSM.rnd_seed(78)
	c.act("continueRun")
	# Exercise the real Continue path but draw just its offer over the same blank
	# battle backdrop as the other checks, so there are no ship assets to load.
	c.page["kind"] = "battle"
	var ui = _attach_ui(c)
	await _settle()
	_ok(saved_offers.size() == 3 and c.modal_d["kind"] == "boon" and c.modal_d["data"]["offer"] == saved_offers
		and _details(ui, c).size() == 3 and JSM.rng_u32() == 78 and c.save_text() == before,
		"Continue restores all three saved cards without drawing again or rewriting the save")
	ui.free()


func _capture(shots: String, name: String, size: Vector2i) -> void:
	viewport.gui_release_focus()
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	if image == null or image.get_size() != size:
		_ok(false, name + ": wrong capture size")
		return
	# Keep room below the modal for the provenance strip even when a hint wraps.
	var crop := size * 3 / 4
	image = image.get_region(Rect2i((size - crop) / 2, crop))
	image.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	_ok(preload("res://tools/picture_provenance.gd").save_jpg(image, shots.path_join(name)) == OK, "captured " + name)


func _show_cases(shots: String, base: String, before_ui: GDScript) -> void:
	var c = _campaign()
	if c == null: return
	var ui = _attach_ui(c)
	JSM.rnd_seed(1075)
	c.newRun("malek", "voidsworn")
	# Include a weapon cap, a stacked effect cap, an aspect wing and a hold-only fit.
	# No shipped refit grants a squadron to a hull without a hangar: use a local trial
	# refit to exercise the forward-compatible hold path without changing shipped tables.
	c.MODULES["test_deck"] = {"n": "Auxiliary flight deck", "fx": {"hive": 1}}
	var cases := [
		["RE-NONE", [["warden", "Oath"]], "a_lance", 0, "No ship with lances now; could use later on a fitting hull."],
		["RE-ONE", [["penitent", "Oath"], ["harrow", "Spark"]], "a_lance", 1, "Affects 1 ship with lances: Oath"],
		["RE-MANY", [["penitent", "Oath"], ["cathedral", "Sear"], ["penitent", "Vow"], ["penitent", "Brand"], ["penitent", "Flame"]], "a_lance", 2, "Affects 5 ships with lances: Oath, Sear, Vow and 2 more"],
		["RE-CAPPED", [["harrow", "Spark"]], "e_reload", 0, "No added benefit: ships with torpedoes are already at the limit."],
		["RE-HOLD", [["warden", "Oath"]], "h_wings", 0, "No ship with squadrons now; could use later with the Auxiliary flight deck refit in your hold."],
	]
	for s in [Vector2i(1920, 1080), Vector2i(3840, 2160)]:
		viewport.size = s
		for entry in cases:
			var code: String = entry[0]
			_set_fleet(c, entry[1])
			c.RUN["inventory"] = ["test_deck"] if code == "RE-HOLD" else []
			var picks := [{"id": entry[2], "r": entry[3]}, {"id": "a_aim", "r": 0}, {"id": "s_ion", "r": 1}]
			# Load already selected cards to stage also the no-match cases the normal pool filters.
			c.RUN["reward"] = {"kind": "elite", "stage": "pick", "rw": {"k": "boon", "p": c.BOONS[entry[2]]["p"]}, "boonOffer": picks}
			c.show_page("battle", {}, [])
			c.resumeReward()
			c.toasts.clear()
			var before: String = JSON.stringify(c._enc(c.RUN))
			await _settle()
			var detail: Array[String] = _details(ui, c)
			var first: String = c.BOON_D[entry[2]][entry[3]]
			var label_fit := true
			for label in _labels(ui.modal_box):
				if label.text == first + "\n" + entry[4]:
					label_fit = label.get_visible_line_count() == label.get_line_count() and label.get_theme_font_size("font_size") >= 17 * s.y / 1080
			_ok(detail == [first + "\n" + entry[4], c.BOON_D["a_aim"][0], c.BOON_D["s_ion"][1]] and label_fit
				and JSON.stringify(c._enc(c.RUN)) == before,
				"%s at %dp: relevance fits the real card; fleet-wide cards have no new line" % [code, s.y])
			if not shots.is_empty():
				await _capture(shots, "%s-%dp.jpg" % [code, s.y], s)
				if before_ui != null and code == "RE-ONE" and s.y == 1080:
					ui.hide()
					var old_ui = _attach_ui(c, before_ui)
					await _settle()
					_ok(_details(old_ui, c) == [first, c.BOON_D["a_aim"][0], c.BOON_D["s_ion"][1]], "base screen shows the same cards with their original descriptions")
					await _capture(shots, "RE-ONE-BASE-%s-1080p.jpg" % base.left(8), s)
					old_ui.free()
					ui.show()
	_ok(ui._boon_fleet_line("not_in_BOON_NEED", 0) == "", "unknown need makes no claim")
	_set_fleet(c, [["warden", "Oath"], ["harrow", "Spark"]])
	_ok(ui._boon_fleet_line("i_still", 0) == "Affects 2 ships with broadside guns or batteries that have not moved: Oath, Spark", "Anchored Volley names its hold-position condition")
	c.RUN["aspect"] = "hive"
	var flagship: String = c.flagshipOf()["name"]
	_ok(ui._boon_fleet_line("h_wings", 0).ends_with(": " + flagship) and not ui._boon_fleet_line("h_hatch", 0).begins_with("Affects"),
		"an aspect wing counts for squadron effects but does not make its ship a carrier")
	c.RUN["boons"] = [{"id": "L_storm", "r": 3}]
	_ok(ui._boon_fleet_line("s_regen", 0).contains("already at the limit") and ui._boon_fleet_line("e_reload", 2).ends_with(": Spark"),
		"a stacked cap can erase an effect; the reload floor does not erase Epic torpedo damage")
	c.RUN["aspect"] = null
	_set_fleet(c, [["warden", "Oath"]])
	c.RUN["fleet"][0]["mods"] = ["prow"]
	_ok(not ui._boon_fleet_line("h_wings", 0).contains("in your hold"), "a refit cannot qualify a ship without a free slot")
	c.RUN["fac"] = "corsair"
	_ok(ui._boon_fleet_line("a_lance", 0) == "No current ship with lances.", "a future hull must pass the faction's equipment gate")
	c.newRun("aelith", "ithar")
	c.RUN["patrons"] = ["iron", "storm"]
	c.RUN["boons"] = [{"id": "s_cap", "r": 0}]
	_set_fleet(c, [["i_wisp", "Still Light"], ["i_blade", "Far Focus"]])
	var brace_offers := [{"id": "d_bastion", "r": 0}, {"id": "i_brace", "r": 0}, {"id": "i_wall", "r": 0}]
	c.RUN["reward"] = {"kind": "elite", "stage": "pick", "rw": {"k": "boon", "p": "iron"}, "boonOffer": brace_offers}
	c.show_page("battle", {}, [])
	var pool: Array = c.boonOfferPool("iron")
	var duos: Array = c.boonOfferDuos("iron")
	JSM.rnd_seed(75)
	c.resumeReward()
	var saved: String = c.save_text()
	await _settle()
	var lines := _details(ui, c)
	_ok(lines.size() == 3 and lines.all(func(line): return line.ends_with("No effect on this fleet: none of its ships can Brace.")),
		"all three Brace offers show no effect on the real Glasswright reward screen")
	_ok(pool.has("i_brace") and pool.has("i_wall") and duos.has("d_bastion") and c.modal_d["data"]["offer"] == brace_offers
		and JSM.rng_u32() == 75 and c.save_text() == saved, "Brace explanations do not change the Glasswright pool, saved offer, or RNG")
	var captured: Dictionary = c.newShip("warden"); captured["name"] = "Added Escort"; c.RUN["fleet"].append(captured)
	_ok(brace_offers.all(func(entry): return ui._boon_fleet_line(entry.id, 0) == "Affects 1 ship that can Brace: Added Escort"),
		"a captured ship can benefit from Brace protocols in a Glasswright fleet")
	ui.free()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var shots := args[args.find("--shots") + 1] if args.has("--shots") else ""
	var base := args[args.find("--base-ref") + 1] if args.has("--base-ref") else ""
	if shots != "" and DisplayServer.get_name() == "headless":
		_ok(false, "--shots needs a renderer")
		quit(1)
		return
	var before_campaign := Campaign if base == "" else _base_script(base, "campaign/campaign.gd")
	var before_ui := null if base == "" else _base_script(base, "ui/campaign/campaign_ui.gd")
	if before_campaign == null or (base != "" and before_ui == null):
		_ok(false, "cannot load sources at " + base)
		quit(1)
		return
	viewport = SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var saved := ""
	for seed in [1075, 2075, 3075]:
		var before := await _seeded_reward(seed, before_campaign, before_ui)
		var after := await _seeded_reward(seed, Campaign, CampaignUI)
		_ok(not before.is_empty() and before == after and after.first_pick_count == 3 and after.read_only and after.has_details
			and after.offer != after.reroll, "seed %d: pool, draws, reroll, next RNG and save bytes match%s" % [seed, " base" if base != "" else " without the UI"])
		if saved.is_empty(): saved = before.get("save", "")
	if not saved.is_empty(): await _reopen(saved)
	await _show_cases(shots, base, before_ui)
	quit(1 if fails > 0 else 0)
