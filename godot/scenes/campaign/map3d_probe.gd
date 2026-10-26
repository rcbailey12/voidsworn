extends Node
# Test helper (G3): shows only the 3D sector map for a scripted run and prints what the camera sees. Run with a renderer:
#   godot --path godot res://scenes/campaign/map3d_probe.tscn -- <out.png>
const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const JSM = preload("res://rules/jsm.gd")

func _ready() -> void:
	var C = CampaignScript.new(); C.load_tables()
	var ui = UIScript.new(); add_child(ui); ui.bind(C)
	JSM.rnd_seed(4242); C.titleScreen(); C.act("newRunScreen"); C.act("startRun"); C.act("pickAspect", C.W["aspOffer"][0]); C.act("closeModal")
	for i in 30: await get_tree().process_frame
	var m = ui.map3d
	print("map3d size ", m.size, " vp ", m.vp.size, " cam ", m.cam.global_position, " current ", m.cam.current, " nodes ", m._nodes.size())
	for id in m._nodes.keys().slice(0, 3): print("  node ", id, " world ", m._nodes[id]["pos"], " screen ", m.cam.unproject_position(m._nodes[id]["pos"]))
	await RenderingServer.frame_post_draw
	var a = OS.get_cmdline_user_args()
	if a.size() > 0: get_viewport().get_texture().get_image().save_png(a[0])
	var av = C.page["data"]["avail"]
	m.fly_to(av[0])
	for i in 20: await get_tree().process_frame
	if a.size() > 0: get_viewport().get_texture().get_image().save_png(a[0].replace(".png", "_flying.png"))
	await get_tree().create_timer(1.2).timeout
	print("after the jump: page ", C.page["kind"], " pos ", C.RUN["pos"])
	get_tree().quit()
