extends SceneTree
# Issue 420: real campaign actions, the same jump in all three sectors, uncapped frame timings.
# godot --path godot --script res://campaign/test/map_approach_shots.gd -- <output> --no-tips
const Scene = preload("res://scenes/campaign/campaign_scene.gd")

class Driver extends Scene:
	const Guard = preload("res://render/placeholder_guard.gd")
	var target_col := -1
	var results: Array = []
	func _ready():
		_ro_dir = OS.get_cmdline_user_args()[0]
		DirAccess.make_dir_recursive_absolute(_ro_dir)
		C = CampaignScript.new()
		var err = C.load_tables()
		if err != "": push_error(err); get_tree().quit(1); return
		C.persist_on = false
		ui = UIScript.new(); add_child(ui); ui.bind(C)
		_run()
	func _run():
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Vector2i(1920, 1080)
		get_window().position = Vector2i.ZERO
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
		await _frames(15)
		JSM.rnd_seed(344)
		_ro_seen = {"fleet": true, "retreat": true}
		C.titleScreen(); C.act("newRunScreen"); C.act("startRun")
		if C.page.get("kind") == "aspect": C.act("pickAspect", C.W["aspOffer"][0])
		C.act("closeModal")
		for sector in [1, 2, 3]:
			var reached = await _br_play(func():
				if C.modal_d != null or C.page.get("kind") != "map" or int(C.RUN["sector"]) != sector or C.RUN.get("pos") == null: return false
				var col = int(C.findNode(C.RUN["pos"])["col"])
				return C.page["data"]["avail"].size() == 3 if target_col < 0 else col == target_col, 700)
			if not reached: push_error("Cannot reach sector %d at matched jump" % sector); get_tree().quit(1); return
			if target_col < 0: target_col = int(C.findNode(C.RUN["pos"])["col"])
			await _frames(4)
			var load_start = Time.get_ticks_msec()
			while ui.map3d.loading and Time.get_ticks_msec() - load_start < 60000: await get_tree().process_frame
			if ui.map3d.loading or ui.map3d._nodes.is_empty():
				push_error("Sector did not build for capture"); get_tree().quit(1); return
			if Guard.stop_if_any(): return
			await _ro_shot("sector_%d" % sector)
			get_viewport().warp_mouse(Vector2(485, 1000)); ui.map3d._set_hot("")
			await _frames(90)
			var samples: Array = []
			for i in 240:
				var t = Time.get_ticks_usec()
				await RenderingServer.frame_post_draw
				await get_tree().process_frame
				samples.append(float(Time.get_ticks_usec() - t) / 1000.0)
			samples.sort()
			var result = {"sector": sector, "jump_col": target_col, "next_jumps": C.page["data"]["avail"].size(), "p50_ms": samples[120], "p95_ms": samples[228], "frames": samples.size()}
			results.append(result); print("MAP_FRAME ", JSON.stringify(result))
			if sector == 1:
				ui._open_overlay("key"); await _ro_shot("map_key"); ui._close_overlay()
				if await _br_play(func(): return C.modal_d == null and C.page.get("kind") == "map" and C.RUN.get("pos") != null and int(C.findNode(C.RUN["pos"])["col"]) >= 2, 120):
					await _ro_shot("sector_1_mid_run")
			if sector == 3:
				var m = ui.map3d
				for id in m._kb_order:
					if m._reachable.has(id) and not C.page["data"]["avail"].has(id) and C.RUN["pos"] != id:
						await _br_hover(id); await _ro_shot("sector_3_far_tip"); break
		var file = FileAccess.open(_ro_dir.path_join("frames.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify({"seed": 344, "resolution": str(get_viewport().get_visible_rect().size), "renderer": RenderingServer.get_current_rendering_method(), "vsync": "off", "sectors": results}, "\t")); file.close()
		for name in ["sector_1", "sector_2", "sector_3", "sector_1_mid_run", "sector_3_far_tip", "map_key"]:
			var img = Image.load_from_file(_ro_dir.path_join(name + ".png"))
			if img == null or img.get_size() != Vector2i(1920, 1080):
				push_error("Missing 1080 capture: " + name); get_tree().quit(1); return
		get_tree().quit(0)

func _initialize(): root.add_child.call_deferred(Driver.new())
