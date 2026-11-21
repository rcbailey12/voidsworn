extends SceneTree
# Motion review clips, Nov 21 2026 (Ryan: "what is in the play test seems way faster and like sliding on ice than I
# remember"). Adapted from contrib/opus/reviews/movement_capture/capture_521.gd (the issue 521 capture): the production
# battle scene, scenario s1 (warden, penitent, ascendant on a belt, seed 487), the battle camera at 170, the rules choose
# a legal move of each kind and the production move command flies it at Normal speed, Cinematic movement, no hurry key.
# Kinds: straight, turn, final, side, back (battle._maneuver_score, the issue 505 moves) and long (the most sidesteps:
# a several-hex diagonal or sideways run, the case Ryan called skating in R195).
# Run at a fixed 30 fps so frames are true time: godot --fixed-fps 30 --path godot --script <this> -- --out <dir> --kind <k>
# [--every 2] [--allow-placeholder] (numbers only: lets the cloud run without the built hulls).
# Writes <dir>/<Class>/<frame>.jpg every --every frames and <dir>/motion.json (per-frame pose, drive and jets).
var battle
var out := ""
var kind := ""
var every := 2
const KINDS := ["straight", "turn", "final", "side", "back", "long", "kill_frigate", "kill_enemy", "kill_cruiser", "kill_capital"]
var allow_placeholder := false


func _init() -> void:
	# PC run 1121N (Nov 21): the kind read from the command line came back as "OK.txt", so every class was "unavailable"
	# and the run still printed done with 0 frames. The bat now also passes MOTION_OUT and MOTION_KIND in the
	# environment, which win; the command line is the fallback. Anything unread or unknown fails the run.
	var a := OS.get_cmdline_user_args()
	print("MOTION_ARGS ", a, " env kind '", OS.get_environment("MOTION_KIND"), "' env out '", OS.get_environment("MOTION_OUT"), "'")
	out = OS.get_environment("MOTION_OUT")
	kind = OS.get_environment("MOTION_KIND")
	if out == "" and a.find("--out") >= 0 and a.find("--out") + 1 < a.size():
		out = a[a.find("--out") + 1]
	if kind == "" and a.find("--kind") >= 0 and a.find("--kind") + 1 < a.size():
		kind = a[a.find("--kind") + 1]
	every = int(a[a.find("--every") + 1]) if a.has("--every") and a.find("--every") + 1 < a.size() else 2
	allow_placeholder = a.has("--allow-placeholder")
	if out == "" or not (kind in KINDS):
		print("MOTION_FAILED bad arguments: out '%s', kind '%s' (want one of %s)" % [out, kind, str(KINDS)])
		quit(1)
		return
	# Artoo on PR 1523: a reused folder could pass old frames off as new; refuse anything but a fresh one
	if DirAccess.dir_exists_absolute(out) and (not DirAccess.get_files_at(out).is_empty() or not DirAccess.get_directories_at(out).is_empty()):
		print("MOTION_FAILED output folder is not fresh: ", out)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out)
	run.call_deferred()


var save_errors: Array = []
var expected: Dictionary = {}   # folder -> frames saved


func _save(folder: String, name: String) -> void:
	var path := folder.path_join(name)
	var err := root.get_texture().get_image().save_jpg(path, 0.9)
	if err != OK or not FileAccess.file_exists(path):
		save_errors.append("%s (error %d)" % [path, err])
	expected[folder] = int(expected.get(folder, 0)) + 1


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
	if n < 2 or slips < 2:
		return -1e9
	# the most sidesteps first (the case Ryan saw skating), then the longest straight-line distance
	var a: Vector3 = battle_.board.hex_world(battle_.VU[id]["q"], battle_.VU[id]["r"])
	var b: Vector3 = battle_.board.hex_world(path[-1]["q"], path[-1]["r"])
	return slips * 1000.0 + a.distance_to(b)


func run() -> void:
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.external = true
	battle.bot = false
	root.add_child(battle)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
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
	if not allow_placeholder and guard.stop_if_any():
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
	# every frame saved and on disk, counted per folder, before the json and the done line
	for folder in expected:
		var n_jpg := 0
		for fn in DirAccess.get_files_at(folder):
			n_jpg += 1 if fn.ends_with(".jpg") else 0
		if n_jpg != int(expected[folder]):
			save_errors.append("%s holds %d frames, %d saved" % [folder, n_jpg, int(expected[folder])])
	var recorded := 0
	for r in result:
		recorded += 0 if (r as Dictionary).has("unavailable") else 1
	if recorded == 0:
		save_errors.append("no class could fly a %s move: nothing recorded" % kind)
	if not allow_placeholder and expected.is_empty():
		save_errors.append("0 frames saved")
	if not save_errors.is_empty():
		for e in save_errors:
			print("MOTION_SAVE_ERROR ", e)
		print("MOTION_FAILED ", kind)
		quit(1)
		return
	var f := FileAccess.open(out.path_join("motion.json"), FileAccess.WRITE)
	if f == null:
		print("MOTION_FAILED cannot write motion.json")
		quit(1)
		return
	f.store_string(JSON.stringify(result))
	f.close()
	print("MOTION_DONE ", kind, " frames ", expected.values().reduce(func(a, b): return a + b, 0))
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
			var value: float = -1e9
			if kind == "long":
				value = _long_score(battle, id, st.path)
			elif kind == "final":
				# battle._maneuver_score has no "final" case (PC run 1121O: every class unavailable); the issue 505
				# capture's own rule: a move that runs first and ends on a turn into its final facing
				var path: Array = st.path
				if path.size() > 1 and battle._jt(path[-1].get("rot")) and not battle._jt(path[0].get("rot")):
					value = float(path.size())
			else:
				value = battle._maneuver_score(st.path, kind)
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
		var saved := 0
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
			if every > 0 and n % every == 0 and not allow_placeholder:
				await RenderingServer.frame_post_draw
				_save(folder, "%05d.jpg" % saved)   # consecutive, for ffmpeg
				saved += 1
				us = Time.get_ticks_usec()
				shot = true
			n += 1
		for k in 30:
			await process_frame
		result.append({"user_speed": battle.user_speed, "movement": battle.movement, "cls": cls, "kind": kind, "id": id, "path": best.path, "final_facing": best.f, "q": best.q, "r": best.r, "cam_r": battle.cam.r, "telemetry": tel})
		battle._cmd(func(): battle.api.end_activation(sid); return true)
		while battle.busy:
			await process_frame
	return result


func _kill() -> Array:
	# kill_frigate (Ryan Nov 21: small-ship deaths fly apart) kills the player's Sunward frigate; kill_enemy kills the
	# first living enemy (a Hegemony ship in s1) by the player's frigate, so a second faction's small death is on file
	var cls := {"kill_frigate": "Frigate", "kill_cruiser": "Cruiser", "kill_capital": "Dreadnought"}.get(kind, "Enemy")
	var tid := ""
	var by := ""
	for u in battle.V["units"]:
		if kind == "kill_enemy":
			if u["side"] == "enemy" and not u["dead"] and tid == "":
				tid = u["id"]
			if u["side"] == "player" and u["cls"] == "Frigate":
				by = u["id"]
			continue
		if u["side"] == "player" and u["cls"] == cls:
			tid = u["id"]
		if u["side"] == "enemy" and not u["dead"] and by == "":
			by = u["id"]
	if tid == "" or by == "":
		return [{"cls": cls, "unavailable": kind}]
	# MOTION_CAM_R and MOTION_CINE (run R, Nov 21): a close look at a small death. Run Q at the battle camera (170) drew
	# the frigate's death a few pixels wide, and the player's kill cut-in turned the camera off the dying ship.
	battle.cine = OS.get_environment("MOTION_CINE") if OS.get_environment("MOTION_CINE") != "" else "key"
	var sv = battle.views[tid]
	battle.cam.t = sv.position
	battle.cam.r = float(OS.get_environment("MOTION_CAM_R")) if OS.get_environment("MOTION_CAM_R") != "" else 170.0
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
	var saved := 0
	while battle.game_t - t0 < 4.4:
		await process_frame
		tel.append({"t": battle.game_t - t0, "fx_t": (float(gfx.now) - fx0) if gfx != null else 0.0,
			"fx_speed": _f(gfx, "_speed"), "slow_left": _f(gfx, "_death_slow_left"), "cut_in": not (battle.cine_saved as Dictionary).is_empty(), "frame": n, "cam_r": float(battle.cam._cr),
			"screen": [battle.cam.unproject_position(sv.position + Vector3(0, 2, 0)).x, battle.cam.unproject_position(sv.position + Vector3(0, 2, 0)).y]})
		if every > 0 and n % every == 0 and not allow_placeholder:
			await RenderingServer.frame_post_draw
			_save(folder, "%05d.jpg" % saved)   # consecutive, for ffmpeg
			saved += 1
		n += 1
	return [{"cls": cls, "kind": kind, "target": tid, "by": by, "hull_L": float(sv.L), "core_flash_fx_s": core_at, "telemetry": tel}]
