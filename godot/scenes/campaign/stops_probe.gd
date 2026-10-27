extends Node
# Test helper (G3, R51 round 2): close-up shots of every kind of stop on the 3D sector map, and of the Hollow Sun, at
# fixed camera angles, for before and after sets. Works with any version of ui/campaign/map3d.gd that has cam, vp,
# overlay and _nodes ({n, pos, top}). Plays seeded runs until every stop kind has been seen (or 10 seeds).
#   godot --path godot res://scenes/campaign/stops_probe.tscn -- <out dir>
const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const BattleAPI = preload("res://rules/battle_api.gd")
const JSM = BattleAPI.JSM

# kind -> how to recognise it: [node type, map place or ""]
const KINDS := [["planet", "battle", "planet"], ["station", "battle", "station"], ["belt", "battle", "belt"], ["wreck", "battle", "graveyard"],
	["nebula", "battle", "storm"], ["shipyard", "shipyard", ""], ["drydock", "drydock", ""], ["field", "field", ""], ["event", "event", ""], ["flagship", "boss", ""]]

func _ready() -> void:
	var out = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://stops"
	DirAccess.make_dir_recursive_absolute(out)
	var C = CampaignScript.new(); C.load_tables()
	var ui = UIScript.new(); add_child(ui); ui.bind(C)
	var done = {}
	for seed in [4242, 7, 11, 23, 31, 47, 59, 71, 83, 97]:
		JSM.rnd_seed(seed); C.titleScreen(); C.act("newRunScreen"); C.act("startRun"); C.act("pickAspect", C.W["aspOffer"][0]); C.act("closeModal")
		for i in 20: await get_tree().process_frame
		await get_tree().create_timer(2.0).timeout
		var m = ui.map3d
		if not done.has("sun"):   # the Hollow Sun: whichever node holds it in this version
			var s = m.vp.find_child("HollowSun", true, false)
			if s == null: s = m.vp.find_child("DeadStar", true, false)
			if s != null:
				await _shoot(m, ui, s.global_position, 42.0 if s.name == "HollowSun" else 120.0, out.path_join("s_sun.png"), 0.0); done["sun"] = true
		for k in KINDS:
			if done.has(k[0]): continue
			for id in m._nodes:
				var n = m._nodes[id]["n"]
				if n["type"] == k[1] and (k[2] == "" or str(n.get("map", "")) == k[2]):
					var d = 22.0 if k[0] == "flagship" else 12.0
					await _shoot(m, ui, m._nodes[id]["pos"] + Vector3(0, float(m._nodes[id]["top"]) * 0.42, 0), d, out.path_join("s_%s.png" % k[0]), float(m._nodes[id]["top"]))
					print("stop ", k[0], " seed ", seed, " node ", id); done[k[0]] = true
					break
		m.set_process(true); m.overlay.visible = true; ui.page_box.visible = true
		if done.size() >= KINDS.size() + 1: break
	print("stops shot: ", done.keys())
	get_tree().quit()

func _shoot(m, ui, at: Vector3, dist: float, path: String, top: float) -> void:
	m.set_process(false); m.overlay.visible = false; m.card.visible = false; ui.page_box.visible = false
	var dir = Vector3(0.38, 0.5, 0.78).normalized()
	m.cam.position = at + dir * dist; m.cam.look_at(at, Vector3.UP)
	for i in 6: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
