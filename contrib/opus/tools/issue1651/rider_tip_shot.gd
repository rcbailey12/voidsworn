# Issue 1651: a picture of the Command order and its hover tip with the rider line, from the real battle HUD (hud.gd and
# ledger.gd) and the real rules text (battle_api.command_info), on a plain dark board. HUD only: no ships are drawn.
#   VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver vulkan \
#     --path godot --resolution 1920x1080 --script res://../contrib/opus/tools/issue1651/rider_tip_shot.gd -- <admiral> <fac> <out.png>
extends SceneTree
const API = preload("res://rules/battle_api.gd")
const HUD = preload("res://ui/battle/hud.gd")
const Battle = preload("res://scenes/battle/battle.gd")

func _initialize() -> void:
	_run()

func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var adm := a[0] if a.size() > 0 else "anuket"; var fac := a[1] if a.size() > 1 else "deathless"; var out := a[2] if a.size() > 2 else "/tmp/rider_tip.png"
	var api = API.new(); api.load_rules()
	var start = api.R.ADMIRALS[adm]["start"]
	api.new_battle_scenario({"seed": 7, "admiral": adm, "fac_player": fac, "fleet": start, "fac": "hegemony", "enemies": ["h_picket", "h_picket"],
		"obj": "rout", "shape": "open", "map": "open", "dep": "line", "kind": "battle", "sector": 1})
	var data: Dictionary = api.command_info()
	var bg := ColorRect.new(); bg.color = Color("#10141a"); bg.size = Vector2(1920, 1080); root.add_child(bg)
	var h = HUD.new(); root.add_child(h)
	for i in range(4): await process_frame
	h.set_top(1, "Your turn", "Objective: break their fleet", "End turn", true, false, false)
	h.set_command(str(data["label"]), true, true, false, Battle._command_tip(data))
	for i in range(4): await process_frame
	h.ledger.ensure_layout()
	var hit = null
	for x in h.ledger.hits:
		if x.get("act") == "command": hit = x
	if hit == null:
		printerr("no Command order on the sheet"); quit(1); return
	h.ledger._hover = h.ledger.hits.find(hit); h.ledger.queue_redraw()
	h.show_tip(str(hit["tip"]), Rect2(hit["r"]).position)
	for i in range(6): await process_frame
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("saved ", out, " tip: ", str(hit["tip"]).replace("\n", " | "))
	quit(0)
