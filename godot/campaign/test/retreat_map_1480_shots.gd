extends SceneTree
# Issue 1480, picture RET-1: the campaign map after a retreat. The fleet is back on the stop it jumped from and the fight it
# left is still on the map, ready to take again. Real campaign actions: play to a stop, enter a fight, press Retreat.
# godot --path godot --resolution 1920x1080 --script res://campaign/test/retreat_map_1480_shots.gd -- <output> --no-tips
const Scene = preload("res://scenes/campaign/campaign_scene.gd")
class Driver extends Scene:
	var failed := false
	func _ready():
		_ro_dir = OS.get_cmdline_user_args()[0]; DirAccess.make_dir_recursive_absolute(_ro_dir)
		C = CampaignScript.new(); var err = C.load_tables()
		if err != "": push_error(err); get_tree().quit(1); return
		C.persist_on = false; ui = UIScript.new(); add_child(ui); ui.bind(C); _run()
	func _run():
		get_window().mode = Window.MODE_WINDOWED; get_window().size = Vector2i(1920, 1080); get_window().position = Vector2i.ZERO
		await _frames(15)
		C.UID = 1; C.RUN = null; C.B = null; C.SAVED_RUN = null; C.META = C.defaultMeta()
		C.picked_admiral = "vex"; C.picked_faction = "voidsworn"; C.run_opt = {"alt": false, "cmdAlt": false, "heat": []}; C.ended = false
		JSM.rnd_seed(1480); C.titleScreen(); C.act("newRunScreen"); C.act("startRun")
		if C.page.get("kind") == "aspect": C.act("pickAspect", C.W["aspOffer"][0])
		C.act("closeModal"); _ro_seen = {"fleet": true, "retreat": true}
		# play until the fleet stands on a stop with a plain fight one jump ahead
		var ok = await _br_play(func(): return C.modal_d == null and C.page.get("kind") == "map" and C.RUN.get("pos") != null and _next_fight() != null, 200)
		if not ok: push_error("RET-1: no stop with a fight ahead"); get_tree().quit(1); return
		var from = str(C.RUN["pos"]); var fight = _next_fight()
		C.act("enterNode", str(fight["id"])); await _frames(5)
		if C.page.get("kind") != "battle": push_error("RET-1: the fight did not open (%s)" % C.page.get("kind")); get_tree().quit(1); return
		C.act("c3retreat"); C.act("c3retreatYes"); await _frames(5)
		if C.modal_d != null: C.act("closeModal")
		var back = str(C.RUN.get("pos")) == from and C.RUN.get("curNode") == null and not C.findNode(fight["id"]).get("done", false)
		print("RET1_STATE ", JSON.stringify({"from": from, "pos": C.RUN.get("pos"), "fight": fight["id"], "fight_done": C.findNode(fight["id"]).get("done", false), "page": C.page.get("kind")}))
		if not back: push_error("RET-1: the fleet is not back on its stop with the fight open"); failed = true
		if C.page.get("kind") != "map": C.mapScreen()
		ui.pick_route(str(fight["id"])); await _frames(5)
		get_viewport().warp_mouse(Vector2(550, 1000))
		await _ro_shot("RET-1_map_after_retreat")
		if preload("res://render/placeholder_guard.gd").stop_if_any(): return
		get_tree().quit(1 if failed else 0)
	func _next_fight():
		if C.RUN == null or C.RUN.get("pos") == null: return null
		for e in C.RUN["map"]["edges"]:
			if str(e[0]) != str(C.RUN["pos"]): continue
			var n = C.findNode(e[1])
			if n != null and n["type"] == "battle" and not C.nemNodeIs(n) and not n.get("done", false): return n
		return null
func _initialize(): root.add_child.call_deferred(Driver.new())
