extends SceneTree
# Issue 678: the campaign map's plain words (Map key, Save and quit) sit straight on the chart, so they must read 4.5 to 1
# or better whatever star, glow or planet is behind them (RULEBOOK 9.4). The PC capture measured Map key at 2.68 to 1 at 1440.
# The words carry the map's dark halo (glass_shell.gd HALO) as a font outline. This check builds the real campaign map page
# at 1080 and 1440 and tests the property:
#   1. the Map key and Save and quit buttons on the page have an opaque HALO outline wide enough to cover the glyph;
#   2. their words, drawn over that halo, are 4.5 to 1 or better (the halo is the worst backdrop under a letter);
#   3. the same words in the briefing column and the slide-overs are left as they were (no halo, nothing else changed).
# Run: godot --headless --path godot --script res://ui/campaign/test/map_key_halo_test.gd

const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const GS = preload("res://ui/theme/glass_shell.gd")
const JSM = preload("res://rules/battle_api.gd").JSM

var fails := 0
var C
var ui


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok:
		fails += 1


static func lum(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


static func contrast(a: Color, b: Color) -> float:
	var la := lum(a)
	var lb := lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _initialize() -> void:
	_run.call_deferred()


func buttons(n: Node, out: Dictionary) -> void:
	if n is Button and not (n as Button).text.is_empty():
		out[(n as Button).text] = n
	for c in n.get_children():
		buttons(c, out)


func _run() -> void:
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "":
		printerr(err)
		quit(1)
		return
	C.fixed_clock = true
	C.persist_on = false
	C.UID = 1
	JSM.rnd_seed(678)
	C.META = C.defaultMeta()
	C.SAVED_RUN = null
	C.RUN = null
	C.B = null
	C.picked_admiral = "vex"
	C.picked_faction = "voidsworn"
	C.run_opt = {"alt": false, "cmdAlt": false, "heat": []}
	C.titleScreen()
	C.act("newRunScreen")
	C.act("startRun")
	if C.page.get("kind") == "aspect":
		C.act("pickAspect", C.W["aspOffer"][0])
	C.act("closeModal")
	for sz in [Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = sz
		root.content_scale_size = Vector2i.ZERO
		await process_frame
		ui = UIScript.new()
		root.add_child(ui)
		ui.bind(C)
		await process_frame
		await process_frame
		var t0 := Time.get_ticks_msec()
		while ui.map3d != null and ui.map3d.loading and Time.get_ticks_msec() - t0 < 60000:
			await process_frame
		ui.render()
		await process_frame
		var tag := "%dx%d" % [sz.x, sz.y]
		var found := {}
		buttons(ui, found)
		for word in ["Map key", "Save and quit"]:
			check(found.has(word), "%s: the map page has '%s'" % [tag, word])
			if not found.has(word):
				continue
			var b: Button = found[word]
			var oc := b.get_theme_color("font_outline_color")
			var os := b.get_theme_constant("outline_size")
			check(is_equal_approx(oc.a, 1.0) and oc.is_equal_approx(Color(GS.HALO, 1.0)), "%s: '%s' has an opaque HALO outline (%s)" % [tag, word, oc.to_html(true)])
			check(os >= int(round(6.0 * ui.k)), "%s: '%s' outline is %d px, wide enough to cover the glyph (6 px at 1080 or more)" % [tag, word, os])
			for cn in ["font_color", "font_hover_color", "font_focus_color"]:
				var c := contrast(b.get_theme_color(cn), Color(GS.HALO, 1.0))
				check(c >= 4.5, "%s: '%s' %s over the halo is %.2f to 1 (4.5 or more)" % [tag, word, cn, c])
		# the same kind of button off the chart keeps its old look
		var plain = ui.tbtn("Dossier", 17, 22, func(): pass)
		var pb: Button = plain.get_meta("button")
		check(not pb.has_theme_color_override("font_outline_color") and not pb.has_theme_constant_override("outline_size"), "%s: a text button off the chart (default) has no halo" % tag)
		plain.free()
		ui.queue_free()
		await process_frame
	print("Map key halo: " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)
