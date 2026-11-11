extends SceneTree
# Read-only observer of the production battle. Run with --path godot --script <absolute path>.
var battle
var out := ""
var tag := ""
var frame := 0
var samples: Array = []
var cues: Array = []
var last_capture := -1.0

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[a.find("--out") + 1]
	tag = a[a.find("--tag") + 1]
	DirAccess.make_dir_recursive_absolute(out)
	run.call_deferred()

func run() -> void:
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.external = true
	battle.bot = false
	root.add_child(battle)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	battle.sfx.cue_started.connect(func(n, opts):
		var clips := []
		var voices: Array = battle.sfx.by_cue.get(n, [])
		if not voices.is_empty():
			for player in voices[-1].players:
				clips.append({"resource": player.stream.resource_path, "pitch": player.pitch_scale})
		cues.append({"t": battle.game_t, "cue": n, "options": opts, "clips": clips}))
	var sc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://rules/test/scenarios.json"))["s1"].duplicate(true)
	if tag == "large":
		sc["fleet"] = ["ascendant", "cathedral", "penitent", "reliquary", "harrow", "harrow", "warden", "warden", "warden", "warden"]
		sc["enemies"] = ["c_boss", "c_raider", "h_interdictor", "h_picket", "b_spitter", "b_drone", "i_blade", "i_wisp", "d_harvester", "d_jackal"]
		sc["map"] = "belt"
		sc["sector"] = 3
		sc["seed"] = 487
	elif tag.begins_with("motion"):
		sc["fleet"] = ["warden", "penitent", "ascendant"]
		sc["map"] = "belt"
		sc["seed"] = 487
	else:
		sc["seed"] = 1001
	if tag == "motion_obstacle":
		# Controlled starting terrain, then the unchanged rules choose legal routes.
		var api = load("res://rules/battle_api.gd").new()
		api.load_rules()
		api.new_battle_scenario(sc, 487)
		for u in api.R.B["units"]:
			if u["side"] == "player":
				api.R.B["terrain"][str(int(u.q) + 1) + "," + str(int(u.r) - 1)] = "rock"
		api._queue.clear()
		battle._begin(api)
	else:
		battle.start_scenario(sc)
	while battle.warming or battle.busy:
		await process_frame
	if tag.begins_with("motion"):
		await create_timer(2.5).timeout
		while battle.opening or battle.busy: await process_frame
	# Fail loudly rather than provide pictures of missing hulls.
	var guard = load("res://render/placeholder_guard.gd")
	if guard.stop_if_any():
			push_error("Missing real hull")
			quit(3)
			return
	battle.tips_off = true
	battle.hud.hide_tipcard()
	battle.follow = false
	battle.cam.r = 170.0
	battle.cam.t = Vector3.ZERO
	battle.cam.snap()
	if tag.begins_with("motion"):
		await motion(tag.trim_prefix("motion_"))
		return
	if tag == "large":
		battle.hud.visible = false
		var center := Vector3.ZERO
		for id in battle.views: center += battle.views[id].position
		battle.cam.t = center / battle.views.size()
		battle.cam.r = 240.0
		battle.cam.snap()
	battle.bot = true
	var start: float = battle.game_t
	while battle.game_t - start < 180.0 and not battle.ended:
		await process_frame
		var t: float = battle.game_t - start
		var ships := []
		for id in battle.views:
			var sv = battle.views[id]
			ships.append({"id": id, "cls": battle.VU.get(id, {}).get("cls", ""), "p": [sv.position.x, sv.position.y, sv.position.z], "rot": [sv.rotation.x, sv.rotation.y, sv.rotation.z], "thrust": sv.thrust, "v": sv._vel.length(), "moving": sv.burning(), "dead": sv.dead, "screen": [battle.cam.unproject_position(sv.position).x, battle.cam.unproject_position(sv.position).y]})
		samples.append({"frame": frame, "t": t, "game_t": battle.game_t, "round": battle.V.get("round", 0), "phase": battle.api.phase, "ships": ships})
		if t - last_capture >= 0.099:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg(out.path_join("%06d.jpg" % frame), 0.88)
			last_capture = t
		frame += 1
	var f := FileAccess.open(out.path_join("telemetry.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"tag": tag, "samples": samples, "cues": cues, "scenario": sc, "ended": battle.ended}, ""))
	f.close()
	print("CAPTURE_DONE ", tag, " frames ", frame, " samples ", samples.size())
	battle._quit()

func motion(kind: String) -> void:
	battle.hud.visible = false
	var result := []
	for cls in ["Frigate", "Cruiser", "Dreadnought"]:
		var id := ""
		for u in battle.V["units"]:
			if u["side"] == "player" and u["cls"] == cls:
				id = u["id"]
		if id == "": continue
		var best = null
		var score := -1e9
		for st in battle.api.reach(id):
			var path: Array = st.path
			var value := -1e9
			if kind in ["straight", "turn"]:
				value = battle._maneuver_score(path, kind)
			elif kind == "final":
				if path.size() > 1 and path[-1].get("rot", false):
					value = float(path.size())
			elif kind == "obstacle":
				var over := false
				for step in path:
					if step.get("over") != null and float(step["over"]) != 0: over = true
				value = float(path.size()) + (100.0 if over else 0.0)
			if value > score:
				score = value
				best = st
		if best == null:
			result.append({"cls": cls, "unavailable": kind})
			continue
		var sv = battle.views[id]
		var initial_yaw: float = sv.rotation.y
		var startpos: Vector3 = sv.position
		var endpos: Vector3 = battle.board.hex_world(best.q, best.r)
		battle.cam.t = (startpos + endpos) * 0.5
		battle.cam.r = 170.0
		battle.cam.snap()
		battle._path_dots(battle.VU[id], best)
		var route := []
		for step in best.path:
			var pt: Vector3 = battle.board.hex_world(step.q, step.r)
			var screen: Vector2 = battle.cam.unproject_position(pt)
			route.append({"p": [pt.x, pt.y, pt.z], "screen": [screen.x, screen.y], "rot": step.get("rot", false)})
		var folder := out.path_join(cls)
		DirAccess.make_dir_recursive_absolute(folder)
		var telemetry := []
		var start: float = battle.game_t
		var state = best
		var sid := id
		battle._cmd(func(): return battle.api.move(sid, state))
		var n := 0
		while battle.busy or sv.burning() or battle.game_t - start < 1.0:
			await process_frame
			battle.path_line.visible = true
			telemetry.append({"t": battle.game_t - start, "p": [sv.position.x, sv.position.y, sv.position.z], "rot": [sv.rotation.x, sv.rotation.y, sv.rotation.z], "thrust": sv.thrust, "v": sv._vel.length(), "moving": sv.burning(), "screen": [battle.cam.unproject_position(sv.position).x, battle.cam.unproject_position(sv.position).y]})
			if n % 6 == 0:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_jpg(folder.path_join("%05d.jpg" % n), 0.9)
			n += 1
		for k in 30: await process_frame
		result.append({"cls": cls, "kind": kind, "id": id, "path": best.path, "route": route, "initial_yaw": initial_yaw, "final_facing": best.f, "score": score, "telemetry": telemetry})
		battle._cmd(func(): battle.api.end_activation(sid); return true)
		while battle.busy: await process_frame
	var f := FileAccess.open(out.path_join("motion.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(result))
	f.close()
	print("MOTION_DONE ", kind)
	battle._quit()


