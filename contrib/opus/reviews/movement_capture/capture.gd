extends SceneTree
# Issue 505 motion capture (adapted from contrib/codex/reviews/cinematic_capture/capture.gd, issue 487): the production
# battle scene, the same scenario and seed Codex filmed (s1 with warden, penitent, ascendant on a belt, seed 487),
# camera 170, the unchanged rules choosing a legal move of each kind, the production move command and playback.
# Run with: godot --path godot --script <this file> -- --out <dir> --kind straight|turn|final|side|back
# Writes <dir>/<Class>/<frame>.jpg every sixth frame and <dir>/motion.json (per-frame pose, drive, jets, live puffs and
# frame time). Works on main's ship_view too (no jet fields there: they read 0).
var battle
var out := ""
var kind := ""


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[a.find("--out") + 1]
	kind = a[a.find("--kind") + 1]
	DirAccess.make_dir_recursive_absolute(out)
	run.call_deferred()


func _f(sv, k: String) -> float:
	var v = sv.get(k)
	return float(v) if v != null else 0.0


func run() -> void:
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.external = true
	battle.bot = false
	root.add_child(battle)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var sc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://rules/test/scenarios.json"))["s1"].duplicate(true)
	sc["fleet"] = ["warden", "penitent", "ascendant"]
	sc["map"] = "belt"
	sc["seed"] = 487
	battle.start_scenario(sc)
	while battle.warming or battle.busy:
		await process_frame
	await create_timer(2.5).timeout
	while battle.opening or battle.busy:
		await process_frame
	var guard = load("res://render/placeholder_guard.gd")
	if guard.stop_if_any():
		push_error("Missing real hull")
		quit(3)
		return
	battle.tips_off = true
	battle.hud.hide_tipcard()
	battle.hud.visible = false
	battle.follow = false
	var result := []
	for cls in ["Frigate", "Cruiser", "Dreadnought"]:
		var id := ""
		for u in battle.V["units"]:
			if u["side"] == "player" and u["cls"] == cls:
				id = u["id"]
		if id == "":
			continue
		var best = null
		var score := -1e9
		for st in battle.api.reach(id):
			var path: Array = st.path
			var value := -1e9
			if kind in ["straight", "turn", "side", "back"]:
				value = battle._maneuver_score(path, kind)
			elif kind == "final":
				if path.size() > 1 and bool(path[-1].get("rot", false)) and not bool(path[0].get("rot", false)):
					value = float(path.size())
			if value > score:
				score = value
				best = st
		if best == null or score <= -1e8:
			result.append({"cls": cls, "unavailable": kind})
			continue
		var sv = battle.views[id]
		var startpos: Vector3 = sv.position
		var endpos: Vector3 = battle.board.hex_world(best.q, best.r)
		battle.cam.t = (startpos + endpos) * 0.5
		battle.cam.r = 170.0
		battle.cam.snap()
		battle._path_dots(battle.VU[id], best)
		await create_timer(0.3).timeout
		var folder := out.path_join(cls)
		DirAccess.make_dir_recursive_absolute(folder)
		var tel := []
		var start: float = battle.game_t
		var state = best
		var sid := id
		battle._cmd(func(): return battle.api.move(sid, state))
		var n := 0
		var us := Time.get_ticks_usec()
		var shot := false
		while battle.busy or sv.burning() or battle.game_t - start < 1.0:
			await process_frame
			var now := Time.get_ticks_usec()
			battle.path_line.visible = true
			var sp: Vector2 = battle.cam.unproject_position(sv.position)
			tel.append({"t": battle.game_t - start, "p": [sv.position.x, sv.position.y, sv.position.z], "rot": [sv.rotation.x, sv.rotation.y, sv.rotation.z],
				"drive": float(sv.thrust), "retro": _f(sv, "jet_retro"), "side": _f(sv, "jet_side"), "aft": _f(sv, "jet_aft"), "turn": _f(sv, "jet_turn"),
				"puffs": (sv.puffs as Array).size(), "moving": sv.burning(), "screen": [sp.x, sp.y], "frame_ms": (now - us) / 1000.0, "after_shot": shot})
			us = now
			shot = false
			if n % 6 == 0:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_jpg(folder.path_join("%05d.jpg" % n), 0.9)
				us = Time.get_ticks_usec()
				shot = true
			n += 1
		for k in 30:
			await process_frame
		result.append({"cls": cls, "kind": kind, "id": id, "path": best.path, "final_facing": best.f, "q": best.q, "r": best.r, "telemetry": tel})
		battle._cmd(func(): battle.api.end_activation(sid); return true)
		while battle.busy:
			await process_frame
	var f := FileAccess.open(out.path_join("motion.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(result))
	f.close()
	print("MOTION_DONE ", kind)
	battle._quit()
