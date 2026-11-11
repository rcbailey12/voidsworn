extends SceneTree
# Issue 521 captures (adapted from contrib/opus/reviews/movement_capture/capture.gd, issue 505): the production battle
# scene, scenario s1 (warden, penitent, ascendant on a belt, seed 487), camera 170.
#   --kind long   : each class flies the longest, most diagonal legal move it has. The capture gives every player ship 8
#                   movement points first (both before and after, so a several-hex diagonal exists for each class; a
#                   dreadnought has 2 in the scenario). The rules choose the route; the production move command plays it.
#   --kind turn | straight : the issue 505 moves (battle._maneuver_score), for the carried timings.
#   --kind kill_cruiser | kill_capital : the battle's own death playback (_play_death) for the cruiser (penitent) or the
#                   dreadnought (ascendant), credited to an enemy ship, with cut-ins on "Key moments". Records whether the
#                   cut-in holds, the effect clock speed (slow motion) and the core flash time.
# Run with: godot --path godot --script <this file> -- --out <dir> --kind <kind>
# Writes <dir>/<Class>/<frame>.jpg and <dir>/motion.json.
var battle
var out := ""
var kind := ""


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[a.find("--out") + 1]
	kind = a[a.find("--kind") + 1]
	DirAccess.make_dir_recursive_absolute(out)
	run.call_deferred()


func _f(o, k: String) -> float:
	var v = o.get(k) if o != null else null
	return float(v) if v != null else 0.0


func _long_score(battle_, id: String, path: Array) -> float:
	var n := 0
	var slips := 0
	for st in path:
		if bool(st.get("rot", false)):
			return -1e9   # a pure run: the rules' heading holds, so on main every slip is a slide
		if st.get("over") != null and float(st.get("over")) != 0.0:
			return -1e9
		n += 1
		slips += 1 if bool(st.get("slip", false)) else 0
	if n < 2 or slips == 0:
		return -1e9
	return n * 100.0 + slips * 10.0


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
	if kind.begins_with("kill_"):
		result = await _kill()
	else:
		result = await _moves()
	var f := FileAccess.open(out.path_join("motion.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(result))
	f.close()
	print("MOTION_DONE ", kind)
	battle._quit()


func _moves() -> Array:
	var result := []
	if kind == "long":
		for u in battle.api.R.B["units"]:
			if u["side"] == "player":
				u["mp"] = 8
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
			var value: float = _long_score(battle, id, st.path) if kind == "long" else battle._maneuver_score(st.path, kind)
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
		battle.cam.r = 170.0 if kind != "long" else clampf(startpos.distance_to(endpos) * 1.6 + 110.0, 170.0, 260.0)
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
			if n % 4 == 0:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_jpg(folder.path_join("%05d.jpg" % n), 0.9)
				us = Time.get_ticks_usec()
				shot = true
			n += 1
		for k in 30:
			await process_frame
		result.append({"cls": cls, "kind": kind, "id": id, "path": best.path, "final_facing": best.f, "q": best.q, "r": best.r, "cam_r": battle.cam.r, "telemetry": tel})
		battle._cmd(func(): battle.api.end_activation(sid); return true)
		while battle.busy:
			await process_frame
	return result


func _kill() -> Array:
	var cls := "Cruiser" if kind == "kill_cruiser" else "Dreadnought"
	var tid := ""
	var by := ""
	for u in battle.V["units"]:
		if u["side"] == "player" and u["cls"] == cls:
			tid = u["id"]
		if u["side"] == "enemy" and not u["dead"] and by == "":
			by = u["id"]
	if tid == "" or by == "":
		return [{"cls": cls, "unavailable": kind}]
	battle.cine = "key"
	var sv = battle.views[tid]
	battle.cam.t = sv.position
	battle.cam.r = 170.0
	battle.cam.snap()
	await create_timer(0.5).timeout
	var folder := out.path_join(cls)
	DirAccess.make_dir_recursive_absolute(folder)
	var gfx = battle.gfx
	var t0: float = battle.game_t
	var fx0: float = float(gfx.now) if gfx != null else 0.0
	battle._play_death({"unit": tid, "by": by, "cause": "blast"})
	var core_at: float = float(gfx.death_core_at(tid)) - fx0 if gfx != null and gfx.has_method("death_core_at") and float(gfx.death_core_at(tid)) >= 0.0 else -1.0
	var tel := []
	var n := 0
	while battle.game_t - t0 < 4.4:
		await process_frame
		tel.append({"t": battle.game_t - t0, "fx_t": (float(gfx.now) - fx0) if gfx != null else 0.0,
			"fx_speed": _f(gfx, "_speed"), "slow_left": _f(gfx, "_death_slow_left"), "cut_in": not (battle.cine_saved as Dictionary).is_empty(), "frame": n})
		if n % 3 == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg(folder.path_join("%05d.jpg" % n), 0.9)
		n += 1
	return [{"cls": cls, "kind": kind, "target": tid, "by": by, "core_flash_fx_s": core_at, "telemetry": tel}]
