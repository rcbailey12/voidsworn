# Issue 1175: pictures of the map's orders rail, with no ship drawn (so a checkout without godot/gen can take them):
#   N1175_nemesis_col4  the fleet one jump before column 4: a shipyard there carries the Nemesis meeting
#   N1175_boss_stop     the fleet at the rest stop: the flagship stop says its objective and board before the jump
#   godot --path godot --resolution 1920x1080 --script res://campaign/test/nem_col4_shots.gd -- <out dir>
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
const CampaignUI = preload("res://ui/campaign/campaign_ui.gd")
const JSM = preload("res://rules/battle_api.gd").JSM
const View = preload("res://campaign/campaign_view.gd")
const Intel = preload("res://ui/campaign/map_intel.gd")
var dir := ""

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var a := OS.get_cmdline_user_args()
	dir = a[0] if a.size() > 0 else "user://nem_col4_shots"
	DirAccess.make_dir_recursive_absolute(dir)
	var C = CampaignScript.new(); C.load_tables(); C.fixed_clock = true; C.persist_on = false
	C.rng.rnd_seed(1175)
	C.newRun("vex", "voidsworn")
	var ui := CampaignUI.new(); root.add_child(ui); ui.set_process(false); ui.C = C
	var cols: Array = C.RUN["map"]["cols"]
	# shot 1: a shipyard in column 4, reached from the column 3 stop the fleet holds
	var c4: Array = cols[cols.size() - 3]; var yard = c4[0]; yard["type"] = "shipyard"
	for k in ["enc", "shape", "arch", "mod", "rw", "seed"]: yard.erase(k)
	var from = cols[cols.size() - 4][0]
	if not C.RUN["map"]["edges"].any(func(e): return e[0] == from["id"] and e[1] == yard["id"]): C.RUN["map"]["edges"].append([from["id"], yard["id"]])
	C.RUN["pos"] = from["id"]; from["done"] = true
	C.ensureNemesis()["met"] = 0; C.RUN["nemStrike"] = false
	C.mapScreen(); ui.picked = str(yard["id"])
	await _shot(ui, "N1175_nemesis_col4", "rev 2, in-game rail (cloud, no ships drawn)")
	# shot 2: the rest stop before the flagship
	var rest = cols[cols.size() - 2][0]
	C.RUN["pos"] = rest["id"]; rest["done"] = true
	C.nemActive()["met"] = C.RUN["sector"]
	C.mapScreen(); ui.picked = str(cols[cols.size() - 1][0]["id"])
	await _shot(ui, "N1175_boss_stop", "rev 2, in-game rail (cloud, no ships drawn)")
	quit(0)

func _shot(ui, code: String, stage: String) -> void:
	var intel = Intel.new(ui.C)   # the map's own danger estimate, built without the 3D map
	ui._routes = View.routes(ui.C)
	for r in ui._routes: r["danger"] = intel.danger(ui.C.findNode(r["id"]))
	var rail: Control = ui._briefing_column()
	var vp := SubViewport.new(); vp.size = Vector2i(560, 1080); vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var bg := ColorRect.new(); bg.color = Color(0.06, 0.07, 0.1); bg.size = Vector2(vp.size); vp.add_child(bg)
	rail.size = Vector2(vp.size); vp.add_child(rail)
	var tag := Label.new(); tag.text = code + "  " + stage; tag.position = Vector2(12, 8); tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", Color(1, 0.85, 0.4)); vp.add_child(tag)
	root.add_child(vp)
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name() == "headless":
		print("built ", code); vp.queue_free(); return
	var img := vp.get_texture().get_image()
	if img.get_height() > 720: img.resize(int(img.get_width() * 720.0 / img.get_height()), 720, Image.INTERPOLATE_LANCZOS)
	preload("res://tools/picture_provenance.gd").save_png(img, dir.path_join(code + ".png"), "installed in game")
	print("shot ", code)
	vp.queue_free()
