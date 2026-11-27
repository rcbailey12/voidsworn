# Issue 1451 picture SAVE-1: the battle menu in a campaign battle, with its Save and quit to title row.
#   godot --path godot --rendering-driver vulkan --resolution 1280x720 --script res://campaign/test/save_menu_shot.gd -- <out.png>
# Sets up a Sector I campaign fight through the campaign and the rules API (round saves on, as campaign_host.gd does), plays it
# in the battle scene, waits for the round 1 save, opens the menu and saves the frame. Prints whether the row is there.
extends SceneTree
@warning_ignore_start("untyped_declaration", "unsafe_method_access", "unsafe_call_argument", "inference_on_variant", "unsafe_property_access")
const API = preload("res://rules/battle_api.gd")
const Campaign = preload("res://campaign/campaign.gd")
var api = null
var saves := 0

func _setup(run: Dictionary, cfg: Dictionary) -> Dictionary:
	api = API.new(); api.load_rules(); api.set_ai_level("veteran"); api.round_saves = true
	api.new_battle(run, cfg)
	return api.R.B

func _init() -> void:
	_go.call_deferred()

func _go() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp/save1.png"
	var C = Campaign.new(); C.load_tables(); C.persist_on = false; C.fixed_clock = true
	C.battle_mode = "external"; C.battle_setup = _setup
	C.rng.rnd_seed(11); C.META = C.defaultMeta()
	C.newRun("vex", "voidsworn", {})
	var node = null
	for n in C.RUN["map"]["cols"][0]:
		if node == null and n["type"] == "battle": node = n
	if node == null: node = C.RUN["map"]["cols"][0][0]
	C.RUN["pos"] = node["id"]; C.RUN["curNode"] = node["id"]; C.saveRun()
	C._enter_battle_node(node)
	var b = load("res://scenes/battle/battle.tscn").instantiate()
	b.external = true; b.in_campaign = true; b.args["no-tips"] = true
	b.round_save_cb = func() -> bool:   # as campaign_host.gd _save_round: true only when the save was written
		saves += 1
		return C.save_battle_round(api.take_round_snapshot())
	root.add_child(b)
	b.begin_with(api)
	var t0 := Time.get_ticks_msec()
	while (b.round_saved == 0 or b.busy or b.warming) and Time.get_ticks_msec() - t0 < 240000:
		await process_frame
	for i in 30: await process_frame
	b._open_menu()
	for i in 20: await process_frame
	var img := root.get_viewport().get_texture().get_image()
	var werr: Error = preload("res://tools/picture_provenance.gd").save_png(img, out, preload("res://tools/picture_provenance.gd").capture_stage())   # stage: installed in game (the game's own battle menu)
	var items: Array = b.hud._last.get("show_menu", ["", []])[1]
	var has_row := items.any(func(x): return x[1] == "save_quit")
	print("SAVE-1: round %d saved %d time(s), menu row 'Save and quit to title' %s, battle save in campaign: %s -> %s" % [int(api.round_snap_round), saves, "PRESENT" if has_row else "MISSING", str(C.saved_battle != null), out])
	if werr != OK or not FileAccess.file_exists(out): print("SAVE-1: the picture was not written (error %d)" % werr)
	quit(0 if has_row and werr == OK and FileAccess.file_exists(out) else 1)
