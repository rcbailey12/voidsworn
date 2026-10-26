extends Node
# Test helper (G3): shows only the 3D sector map for a scripted run and prints what the camera sees. Run with a renderer:
#   godot --path godot res://scenes/campaign/map3d_probe.tscn -- <out.png>
const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const BattleAPI = preload("res://rules/battle_api.gd")   # the rules are reached only through the battle API (rules/API.md)
const JSM = BattleAPI.JSM   # the shared JS maths and the one PRNG the rules and the campaign both draw from

func _ready() -> void:
	var C = CampaignScript.new(); C.load_tables()
	var ui = UIScript.new(); add_child(ui); ui.bind(C)
	JSM.rnd_seed(4242); C.titleScreen(); C.act("newRunScreen"); C.act("startRun"); C.act("pickAspect", C.W["aspOffer"][0]); C.act("closeModal")
	for i in 30: await get_tree().process_frame
	await get_tree().create_timer(2.2).timeout   # the arrival camera settles over the whole chart
	var m = ui.map3d
	print("map3d size ", m.size, " vp ", m.vp.size, " cam ", m.cam.global_position, " current ", m.cam.current, " nodes ", m._nodes.size())
	for id in m._nodes.keys().slice(0, 3): print("  node ", id, " world ", m._nodes[id]["pos"], " screen ", m.cam.unproject_position(m._nodes[id]["pos"]))
	await RenderingServer.frame_post_draw
	var a = OS.get_cmdline_user_args()
	if a.size() > 0: get_viewport().get_texture().get_image().save_png(a[0])
	var mid = C.RUN["map"]["cols"][3][0]["id"]
	get_viewport().warp_mouse(m._screen(m._nodes[mid]["pos"]))   # exactly on the node, so the motion event keeps it hot
	for i in 3: await get_tree().process_frame
	m._set_hot(mid)
	for i in 8: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if a.size() > 0: get_viewport().get_texture().get_image().save_png(a[0].replace(".png", "_route.png"))
	print("routes through ", mid, ": ", m._routes.map(func(r): return [r["name"], r["path"], r["st"]["fights"], r["st"]["worst_name"]]))
	var av = C.page["data"]["avail"]
	m._set_hot("")
	m.fly_to(av[0])
	for i in 20: await get_tree().process_frame
	if a.size() > 0: get_viewport().get_texture().get_image().save_png(a[0].replace(".png", "_flying.png"))
	await get_tree().create_timer(1.2).timeout
	print("after the jump: page ", C.page["kind"], " pos ", C.RUN["pos"])
	get_tree().quit()
