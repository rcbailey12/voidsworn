# MN8 debrief mock (issue #231, contrib/opus/briefs/debrief_spec.md): the run debrief as the spec lays it out, built from
# the campaign UI's own parts (fonts, colours, panels, buttons, the shared scale law) over a real run end, next to the
# shipped end page for the same run. A mock for Ryan's review round, not the build: #92 builds the screen.
#   godot --path godot --script res://campaign/test/debrief_mock_shots.gd -- <out dir> [WxH]
# The project boots maximised, so --resolution alone gives the monitor's size: pass WxH (1920x1080) to get a window of
# that size; leave it out to shoot at the maximised window (Ryan's 4K monitor).
# Shots: today_top, today_bottom (the shipped end page, scrolled to the top and the bottom), mock_top, mock_bottom (the
# spec's layout for the same run), mock_first_top (the same run as a first-ever loss: kicker and teaching block).
# The run: Sunward Crusade, Admiral Roderic Vex, lost in sector II after 6 battles (one elite, one sector flagship), the
# Nemesis met and beaten once, Oath-Captain Malek Draven named heir. Rows whose per-run data is not recorded yet (the
# Nemesis lesson log, #24 and #122) show the spec's line shapes filled from the run's own Nemesis.
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const BattleAPI = preload("res://rules/battle_api.gd")
var C
var ui
var dir := ""
var layer: CanvasLayer

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	dir = a[0] if a.size() > 0 else "user://debrief_mock_shots"
	DirAccess.make_dir_recursive_absolute(dir)
	if a.size() > 1 and DisplayServer.get_name() != "headless":
		var wh = a[1].split("x")
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(int(wh[0]), int(wh[1])))
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "":
		printerr(err); quit(1); return
	C.save_path = "user://debrief_mock_save.json"
	C.persist_on = false
	ui = UIScript.new(); root.add_child(ui); ui.bind(C)
	_run()

func _frames(n: int) -> void:
	for i in range(n): await process_frame

func _shot(name: String) -> void:
	await _frames(8)
	if DisplayServer.get_name() == "headless":
		print("built ", name); return
	await RenderingServer.frame_post_draw
	var img = root.get_texture().get_image()
	img.save_png(dir.path_join(name + ".png")); print("shot ", name)

func _scroll_of(n: Node) -> ScrollContainer:
	if n is ScrollContainer: return n
	for ch in n.get_children():
		var r = _scroll_of(ch)
		if r != null: return r
	return null

func _scroll(host: Node, bottom: bool) -> void:
	var sc = _scroll_of(host)
	if sc == null: return
	await _frames(3)
	sc.scroll_vertical = int(sc.get_v_scroll_bar().max_value) if bottom else 0
	await _frames(3)

func _run() -> void:
	await _frames(4)
	var want = OS.get_cmdline_user_args()
	if want.size() > 1 and DisplayServer.get_name() != "headless":   # the start-up maximise can land a frame later: apply until it holds
		var wh = want[1].split("x")
		for i in range(3):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED); DisplayServer.window_set_size(Vector2i(int(wh[0]), int(wh[1])))
			await _frames(2)
	print("window ", DisplayServer.window_get_size(), " viewport ", root.get_visible_rect().size, " k ", ui.k)
	BattleAPI.JSM.rnd_seed(4242)
	C.playtest_default = false
	C.META = C.migrateMeta(C.defaultMeta())
	C.META["opts"]["playtestAll"] = false   # the real game after the playtest phase: renown buys things
	C.META["renown"] = 34
	C.META["heirs"]["voidsworn"] = "malek"
	C.META["stats"]["finishedRuns"] = 3; C.META["stats"]["losses"] = 2; C.META["stats"]["best"] = 2
	C.newRun("vex", "voidsworn")
	var R = C.RUN
	R["sector"] = 2
	R["stats"]["battles"] = 6; R["stats"]["elites"] = 1; R["stats"]["bosses"] = 1; R["stats"]["kills"] = 24; R["stats"]["lost"] = 4
	R["t0"] = C.now_ms() - 47 * 60000
	var fl = R["fleet"]
	for i in range(fl.size()):
		fl[i]["car"] = {"dealt": [612, 344, 188, 90, 40][i % 5], "kills": [7, 4, 2, 1, 0][i % 5], "battles": 6}
	for i in range(1, fl.size()): fl[i]["hp"] = 0   # one hull limps home
	R["fallen"] = [{"name": "Captain Ilse Marrow"}, {"name": "Commander Tobin Reyes"}, {"name": "Lieutenant Aster Vale"}]
	var N = C.nemActive(); N["met"] = 1; N["beaten"] = 1   # this run's hunter (#120 commander registry)
	if N["weak"].size() > 0 and not N["revealed"].has(N["weak"][0]): N["revealed"].append(N["weak"][0])
	var nem = {"full": C.nemFull(), "weak": str(C.NEM_WEAK[N["weak"][0]]["n"]) if N["weak"].size() > 0 else "", "fac": str(N["fac"])}
	var patrons = C.PATRONS.keys()
	R["coreSync"] = {patrons[0]: 9.0}; C.META["favour"][patrons[0]] = 13.0   # a core that ticked across Synced this run
	C.endRun(false)
	await _frames(6)
	var d = C.page.get("data", C.page)
	await _scroll(ui.page_box, false); await _shot("today_top")
	await _scroll(ui.page_box, true); await _shot("today_bottom")
	layer = CanvasLayer.new(); layer.layer = 50; root.add_child(layer)
	_show(_mock(d, nem, false))
	await _scroll(layer, false); await _shot("mock_top")
	await _scroll(layer, true); await _shot("mock_bottom")
	_show(_mock(d, nem, true))
	await _scroll(layer, false); await _shot("mock_first_top")
	print("debrief mock shots done")
	quit(0)

func _show(c: Control) -> void:
	for ch in layer.get_children():
		layer.remove_child(ch); ch.queue_free()
	var host = Control.new(); host.set_anchors_preset(Control.PRESET_FULL_RECT); host.theme = ui.theme_main
	var bg = ColorRect.new(); bg.set_anchors_preset(Control.PRESET_FULL_RECT); bg.color = Color("#0b111e"); host.add_child(bg)
	host.add_child(c); layer.add_child(host)

# ---------------------------------------------------------------- the spec's layout (debrief_spec.md section 2)
func _rule() -> Control:
	var r = ColorRect.new(); r.color = UIScript.IRON3; r.custom_minimum_size = Vector2(0, max(1, ui.px(1))); return r

func _row_head(v: VBoxContainer, t: String) -> void:
	v.add_child(ui.caps(t, 13, UIScript.GILT))

func _btn(t: String, primary := false) -> Button:
	var b = Button.new(); b.text = t; b.focus_mode = Control.FOCUS_ALL
	if primary:
		b.add_theme_stylebox_override("normal", ui._sb(UIScript.GILT, UIScript.GILT)); b.add_theme_color_override("font_color", Color("#1c1405")); b.add_theme_font_override("font", ui.font_semi)
	return b

func _bar(f: float) -> Control:
	var bg = ColorRect.new(); bg.color = UIScript.IRON3; bg.custom_minimum_size = Vector2(0, ui.px(6)); bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fg = ColorRect.new(); fg.color = UIScript.GILT; fg.anchor_bottom = 1.0; fg.anchor_right = clamp(f, 0.0, 1.0); bg.add_child(fg)
	return bg

func _mock(d: Dictionary, nem: Dictionary, first: bool) -> Control:
	var R = d["run"]; var s = R["stats"]; var cy = R["carry"]; var rc = cy["inheritance"]; var flown = rc["flown"]
	var GILT = UIScript.GILT; var BONE = UIScript.BONE; var BONE2 = UIScript.BONE2; var BONE3 = UIScript.BONE3; var BLOOD = UIScript.BLOOD
	var cc = CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sc = ScrollContainer.new(); sc.custom_minimum_size = Vector2(ui.px(1000), min(ui.px(1000), get_root().get_visible_rect().size.y - ui.px(40))); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v = ui.vbox(10); v.custom_minimum_size.x = ui.px(960); sc.add_child(v); cc.add_child(sc)
	var tag = ui.caps("Mock for review (issue 231): the debrief spec's layout", 12, BONE3); tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; v.add_child(tag)
	# 1. headline
	if first:
		var k = ui.caps("THE FIRST CRUSADE FALLS. THE CHALK REMEMBERS.", 12, GILT); k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(k)
	var h = ui.lbl("The fleet is lost", 62, BONE, ui.font_goth); h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(h)
	var sub = "The last hull goes dark in sector " + C.roman(R["sector"]) + ". The survivors will tell it differently" + (", and the next crusade will read it in chalk before it chooses." if first else ".")
	var sl = ui.lbl(sub, 20, BONE2); sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(sl)
	# 2. first-loss teaching block
	if first:
		var tp = ui.panel(GILT, Color(0.82, 0.65, 0.29, 0.07), 14); var tv = ui.vbox(4); tp.add_child(tv)
		tv.add_child(ui.lbl("No crusade wins the first dark. That is the oath working, not failing. What this run bought is already written: renown in the vault, mastery in the bloodline, and the weakness the enemy showed you at cost. The next crusade stands at this same dark and reads what you chose. Do not mourn the fleet. Read the record.", 17, BONE))
		v.add_child(tp)
	# 3. the inheritance panel: five rows
	var ip = ui.panel(GILT, Color(0.37, 0.7, 0.65, 0.08), 14); var iv = ui.vbox(10); ip.add_child(iv)
	iv.add_child(ui.caps("WHAT THIS RUN BOUGHT", 16, GILT))
	iv.add_child(ui.lbl("What this death bought:", 17, BONE2))
	# row 1: doctrine and renown
	var r1 = ui.vbox(4); _row_head(r1, "Doctrine and renown")
	r1.add_child(ui.rich("[b]" + ui.c("Renown: +" + C.numstr(cy["ren"]) + " earned.", GILT) + "[/b] " + C.numstr(rc["balance"]) + " in the vault.", 17))
	var parts = [str(int(s["battles"]) * 2) + " from battles", str(int(s["elites"]) * 4) + " from the elite", str(int(s["bosses"]) * 15) + " from the flagship", str(int(floor(float(s["kills"]) / 4.0))) + " from kills", str((int(R["sector"]) - 1) * 5) + " for reaching sector " + C.roman(R["sector"])]
	r1.add_child(ui.lbl(", ".join(PackedStringArray(parts)) + ".", 15, BONE3))
	var aff = rc["affordable"].filter(func(u): return u["fresh"])
	aff.sort_custom(func(a, b): return float(a["cost"]) < float(b["cost"]))
	if aff.size() > 0:
		r1.add_child(ui.lbl("Now affordable: " + str(aff[0]["n"]) + ", " + C.numstr(aff[0]["cost"]) + " renown" + ((", and " + str(aff.size() - 1) + " more within reach.") if aff.size() > 1 else "."), 17, GILT))
	else:
		r1.add_child(ui.lbl("Next: the cheapest unowned reward is still out of reach. Your renown stays saved.", 17, BONE2))
	var b1 = ui.hbox(8); b1.add_child(_btn("Spend renown")); r1.add_child(b1)
	iv.add_child(r1); iv.add_child(_rule())
	# row 2: lineage and tree progress, shadow XP as sub-lines
	var r2 = ui.vbox(4); _row_head(r2, "Lineage")
	r2.add_child(ui.rich("[b]" + C.ADMIRALS[flown["id"]]["n"] + "[/b]: +" + C.numstr(snapped(float(cy["mxGain"]), 0.01)) + " XP. Level " + str(flown["level"]) + ".", 17))
	var nxt = flown["next"]
	r2.add_child(_bar(1.0 if nxt == null else float(flown["xp"]) / max(1.0, float(nxt))))
	if nxt == null: r2.add_child(ui.lbl(C.numstr(flown["xp"]) + " XP. This line is at its current cap; further XP goes to shadow learning.", 15, BONE3))
	else: r2.add_child(ui.lbl(C.numstr(flown["xp"]) + " of " + C.numstr(nxt) + " XP. " + C.numstr(flown["remaining"]) + " to level " + str(int(flown["level"]) + 1) + ": " + str(C.masteryPerk(int(flown["level"]) + 1)["n"]) + ".", 15, BONE3))
	for row in rc["shadow"]:
		var heir = C.META["heirs"].get(R["fac"]) == row["id"]
		r2.add_child(ui.lbl(str(C.ADMIRALS[row["id"]]["n"]) + ": +" + C.numstr(snapped(float(row["xp"]), 0.01)) + " shadow XP (level " + C.numstr(row["level"]) + ")." + (" Heir: double rate." if heir else ""), 15, GILT if heir else BONE2))
	iv.add_child(r2); iv.add_child(_rule())
	# row 3: core sync (ticked cores only)
	var r3 = ui.vbox(4); _row_head(r3, "Core sync")
	if rc["cores"].is_empty(): r3.add_child(ui.lbl("No protocols taken this run.", 15, BONE3))
	for row in rc["cores"]:
		var P = C.PATRONS[row["id"]]; var col = Color(P["col"])
		if row["tierUp"]: r3.add_child(ui.lbl(str(P["n"]) + ": crossed into " + str(C.FAVOUR_TIERS[row["tier"]]["n"]) + " this run at " + C.numstr(row["total"]) + " protocols.", 17, col))
		if row["next"] != null: r3.add_child(ui.lbl(str(P["n"]) + ": " + C.numstr(row["total"]) + " of " + C.numstr(row["next"]) + " to " + str(C.FAVOUR_TIERS[int(row["tier"]) + 1]["n"]) + ".", 15, BONE3))
	iv.add_child(r3); iv.add_child(_rule())
	# row 4: Nemesis lesson
	var r4 = ui.vbox(4); _row_head(r4, "Nemesis lesson")
	r4.add_child(ui.rich("You broke " + ui.c("[b]" + ui.esc(nem["full"]) + "[/b]", BLOOD) + ". Weakness found: " + ui.c(ui.esc(nem["weak"]), GILT) + ".", 17))
	iv.add_child(r4); iv.add_child(_rule())
	# row 5: story payoff
	var r5 = ui.vbox(4); _row_head(r5, "The record")
	r5.add_child(ui.lbl(C.TB.STORY_BEAT3[R["fac"]]["learning"], 17, BONE))
	iv.add_child(r5)
	v.add_child(ip)
	# 4. heir block
	var hp = ui.panel(UIScript.IRON3, UIScript.IRON, 14); var hv = ui.vbox(6); hp.add_child(hv)
	hv.add_child(ui.caps("Heir to the line", 13, GILT))
	var hid = C.META["heirs"].get(R["fac"])
	hv.add_child(ui.lbl((str(C.ADMIRALS[hid]["n"]) + " is the current heir. The heir's line earns double shadow XP from the next run.") if hid != null else "No heir named.", 16, BONE))
	var hb = ui.hbox(8); hb.add_child(_btn("Change heir")); hv.add_child(hb)
	v.add_child(hp)
	# 5. recap
	var tiles = ui.flow(8)
	var tl = [[s["battles"], "battles won"], [s["bosses"], "flagships destroyed"], [s["kills"], "enemy ships destroyed"], [C.z0(s.get("lost")), "ships lost"]]
	if d.get("mins") != null: tl.append([C.numstr(d["mins"]) + "m", "played"])
	for t in tl:
		var p = ui.panel(UIScript.IRON3, UIScript.GLASS, 8); p.custom_minimum_size.x = ui.px(150); var tv2 = ui.vbox(0)
		var a = ui.lbl(str(t[0]) if t[0] is String else C.numstr(t[0]), 26, GILT, ui.font_semi); a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tv2.add_child(a)
		var b = ui.lbl(t[1], 13, BONE2); b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tv2.add_child(b); p.add_child(tv2); tiles.add_child(p)
	v.add_child(tiles)
	var alive = R["fleet"].filter(func(x): return float(x["hp"]) > 0)
	if alive.size() > 0:
		var best = alive[0]
		v.add_child(ui.rich("Standout ship: [b]" + ui.c(ui.esc(best["name"]), GILT) + "[/b], " + C.numstr(best["car"]["kills"]) + " kills and " + C.numstr(best["car"]["dealt"]) + " damage across " + C.numstr(best["car"]["battles"]) + " battles.", 17))
		v.add_child(ui.lbl("Still flying", 20, GILT, ui.font_semi))
		for x in alive:
			var p = ui.panel(GILT, UIScript.GLASS, 8); var r = ui.hbox()
			r.add_child(ui.rich("[b]" + ui.esc(x["name"]) + "[/b] " + ui.c(ui.esc(C.HULLS[x["tpl"]]["n"]), BONE3) + "\n" + ui.c(ui.esc(C.rankName(x["cap"])) + " " + ui.esc(x["cap"]["name"]), BONE3), 15))
			r.add_child(ui.rich("[right]" + C.numstr(x["car"]["kills"]) + " kills\n" + ui.c(C.numstr(x["car"]["dealt"]) + " dmg", BONE3) + "[/right]", 15)); p.add_child(r); v.add_child(p)
	var nm = []
	for f in R["fallen"]: nm.append(f["name"])
	if nm.size() > 0: v.add_child(ui.lbl("Captains lost this run: " + ", ".join(PackedStringArray(nm)) + ".", 16, BONE2))
	v.add_child(ui.lbl("Best so far: sector " + C.roman(min(3, float(C.META["stats"]["best"]))), 20, GILT))
	# 7. exits, last; keyboard focus starts on the primary exit
	var ex = ui.hbox(10); ex.alignment = BoxContainer.ALIGNMENT_CENTER
	var nb = _btn("New run", true); ex.add_child(nb); ex.add_child(_btn("Title screen")); v.add_child(ex)
	nb.grab_focus.call_deferred()
	return cc
