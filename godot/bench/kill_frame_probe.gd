extends SceneTree
## Replays the Corsair seed 7 battle with the torpedo timing tags and no image readbacks.
## With --blink-frame-report, measures a single Glasswright Blink after the normal battle load.
## Run through the kill_frame_1829 or round_2_compile_1843 PC job on the Board's GPU queue.


class TimedBattle extends "res://scenes/battle/battle.gd":
	const FRAME_BUDGET_MS := 1000.0 / 60.0
	const CONTROL_HITCH_MS := 100.0   # Allow variation around the original 150 to 190 ms, not a small frame-budget miss.
	const VERDICT_FAILED := 3   # The Board's batch keeps measuring after a valid replay misses its gate.

	var _last_frame := 0
	var _last_pipes := 0
	var _last_battle_usec := 0
	var _last_bot_usec := 0
	var _last_bot_rules_usec := 0
	var _in_bot_step := false
	var _last_tag := ""
	var _events: Array[Dictionary] = []
	var _spikes: Array[Dictionary] = []
	var _round_2_compile_frames: Array[Dictionary] = []
	var _round_2_frames := 0
	var _draw_round := 0
	var _known_stage := {}
	var _tag_max := {}
	var _blink_active := false
	var _blink_frames := 0
	var _blink_echo_frames := 0
	var _blink_echo_drawn := false
	var _blink_compiles: Array[Dictionary] = []

	func _ready() -> void:
		external = "--blink-frame-report" in OS.get_cmdline_user_args()
		super._ready()
		RenderingServer.frame_pre_draw.connect(_mark_draw_round)
		if external:
			_run_blink.call_deferred()
			return
		# The salvo logger is enabled after _ready reads its capture options, so
		# the original torpedo windows run with the screenshot directory empty.
		args["torp-shots"] = true
		args["torp-ft"] = true
		RenderingServer.frame_pre_draw.connect(_mark_draw_round)

	func _mark_draw_round() -> void:
		_draw_round = int(V.get("round", 0))
		_blink_echo_drawn = false
		if _blink_active:
			var echo: Node3D = gfx.get_node_or_null("fx_warp_echo")
			if echo != null:
				for part in echo.get_children():
					var mesh := part as MeshInstance3D
					if mesh != null and mesh.mesh is ArrayMesh and mesh.is_visible_in_tree() \
							and (mesh.layers & cam.cull_mask) != 0 and cam.is_position_in_frustum(mesh.global_position):
						_blink_echo_drawn = true
						break


	func _run_blink() -> void:
		var a := API.new()
		if a.load_rules() != "":
			_blink_failed("could not load rules")
			return
		# No bot, deployment screen or other attacks: measure the first Blink on a live Sliver.
		a.new_battle_scenario({"seed": 7, "sector": 1, "admiral": "aelith", "fac_player": "ithar",
			"fleet": ["i_wisp"], "fac": "corsair", "enemies": ["c_raider"],
			"obj": "ambush", "shape": "open", "dep": "ambush", "kind": "battle", "map": "open"})
		begin_with(a)
		var deadline := Time.get_ticks_msec() + 180000
		while warming or busy or not batches.is_empty() or a.phase != "player":
			if Time.get_ticks_msec() >= deadline or not errors.is_empty():
				_blink_failed("did not reach the player's turn")
				return
			await get_tree().process_frame
		var id := ""
		for u in V.get("units", []):
			if u["side"] == "player" and u["fac"] == "ithar" and a.unit(str(u["id"])).get("ab") == "blink":
				id = str(u["id"])
				break
		var view: ShipView = views.get(id)
		if view == null or view.hull_res.is_empty() or gfx == null:
			_blink_failed("missing imported Glasswright hull or effects")
			return
		var targets: Array = a.ui_info(id).get("ability", {}).get("hexes", [])
		if targets.is_empty():
			_blink_failed("no legal Blink destination")
			return
		var hex: Dictionary = targets[0]
		var dst: Vector3 = board.hex_world(int(hex["q"]), int(hex["r"]))
		cam.t = view.visual_position()
		cam.snap()
		for i in 6:
			await get_tree().process_frame
		_blink_active = true
		if not _cmd(func() -> bool: return a.ability(id, {"hex": hex})):
			_blink_failed("rules refused the legal Blink")
			return
		deadline = Time.get_ticks_msec() + 10000
		while busy and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
		for i in 3:
			await get_tree().process_frame
		_blink_active = false
		if busy or not errors.is_empty() or not view.position.is_equal_approx(dst) or _blink_echo_frames == 0:
			_blink_failed("Blink did not finish with a visible imported echo")
			return
		var renderer := RenderingServer.get_current_rendering_method()
		if DisplayServer.get_name() == "headless" or renderer != "forward_plus":
			_blink_failed("measurement needs windowed Forward+")
			return
		var out := FileAccess.open(str(args["blink-frame-report"]), FileAccess.WRITE)
		if out == null:
			_blink_failed("could not open the report")
			return
		out.store_string(JSON.stringify({"hull": view.code, "hull_resource": view.hull_res,
			"adapter": RenderingServer.get_video_adapter_name(), "renderer": renderer,
			"blink_frames": _blink_frames, "imported_echo_frames": _blink_echo_frames,
			"blink_compile_frames": _blink_compiles}, "  ") + "\n")
		out.close()
		print("KILL_FRAME blink_frames=%d imported_echo_frames=%d compile_frames=%d" % [
			_blink_frames, _blink_echo_frames, _blink_compiles.size()])
		_quit()


	func _blink_failed(reason: String) -> void:
		_blink_active = false
		push_error("KILL_FRAME Blink: " + reason)
		_quit(1)

	func _process(dt: float) -> void:
		var stamp := Time.get_ticks_usec()
		if warming or gfx == null or not gfx.has_method("prof_take"):
			_last_frame = 0
		else:
			var profile: Dictionary = gfx.prof_take()
			var pipes := _pipe_count()
			if _last_frame > 0:
				_sample(float(stamp - _last_frame) / 1000.0, dt, profile, pipes - _last_pipes)
			_last_frame = stamp
			_last_pipes = pipes
		_last_bot_usec = 0
		_last_bot_rules_usec = 0
		var battle_start := Time.get_ticks_usec()
		super._process(dt)
		_last_battle_usec = Time.get_ticks_usec() - battle_start

	func _bot_step() -> void:
		var started := Time.get_ticks_usec()
		_in_bot_step = true
		super._bot_step()
		_in_bot_step = false
		_last_bot_usec = Time.get_ticks_usec() - started

	func _cmd(action: Callable) -> bool:
		if not _in_bot_step:
			return super._cmd(action)
		return super._cmd(func():
			var started := Time.get_ticks_usec()
			var ok = action.call()
			_last_bot_rules_usec += Time.get_ticks_usec() - started
			return ok)

	func _sample(wall_ms: float, dt: float, profile: Dictionary, pipes: int) -> void:
		if args.has("blink-frame-report"):
			if _blink_active:
				_blink_frames += 1
				if _blink_echo_drawn:
					_blink_echo_frames += 1
				if pipes > 0:
					_blink_compiles.append({"frame": Engine.get_process_frames(), "wall_ms": wall_ms,
						"draw_and_specialization_pipelines": pipes, "imported_echo_in_view": _blink_echo_drawn})
			return
		var round_no := int(V.get("round", 0))
		# The sample reads the previous draw. The rules view can advance between that draw and this process step.
		var drawn_round := _draw_round if _draw_round > 0 else round_no
		var round_2_compile := drawn_round == 2 and pipes > 0
		if drawn_round == 2:
			_round_2_frames += 1
		var tag := str(torp_ft.get("tag", ""))
		var frame_tag := tag if tag != "" else _last_tag
		_last_tag = tag
		if frame_tag != "":
			_tag_max[frame_tag] = maxf(wall_ms, float(_tag_max.get(frame_tag, 0.0)))
		var events: Array[Dictionary] = []
		for ship in gfx.ships.values():
			if not ship.dead:
				_known_stage.erase(ship.id)
				continue
			var stage := "split" if ship.has_meta("death_hidden") else "kill"
			if _known_stage.get(ship.id) == stage:
				continue
			_known_stage[ship.id] = stage
			events.append({"ship": ship.id, "hull": ship.hull.code, "stage": stage,
				"cause": ship.get_meta("death_cause", ""), "cut_built": ship.get_meta("cut_job", {}).get("built", false)})
		if wall_ms < FRAME_BUDGET_MS and events.is_empty() and not round_2_compile:
			return
		var row := {"frame": Engine.get_process_frames(), "round": round_no, "draw_round": drawn_round, "salvo": frame_tag,
			"wall_ms": wall_ms, "process_delta_ms": dt * 1000.0, "draw_and_specialization_pipelines": pipes,
			"battle_process_usec": _last_battle_usec, "bot_step_usec": _last_bot_usec, "bot_rules_usec": _last_bot_rules_usec,
			"engine_process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			"engine_physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			"fx_usec": profile, "deaths": events}
		if not events.is_empty():
			_events.append(row)
		if wall_ms >= FRAME_BUDGET_MS:
			_spikes.append(row)
		if round_2_compile:
			_round_2_compile_frames.append(row)

	func _has_round_2_hitch() -> bool:
		return _round_2_compile_frames.any(func(row: Dictionary) -> bool: return row["wall_ms"] >= CONTROL_HITCH_MS)

	func _quit_report() -> void:
		var output := FileAccess.open(str(args.get("kill-frame-report", "")), FileAccess.WRITE)
		var x09 := _tag_max.keys().any(func(tag: String) -> bool: return tag.ends_with("_x09"))
		if output == null or result.is_empty() or _events.is_empty() or _tag_max.is_empty() or _round_2_frames == 0 or not errors.is_empty():
			push_error("KILL_FRAME incomplete replay, missing timings or deaths, or battle errors")
			_quit(1)
			return
		var report := {"adapter": RenderingServer.get_video_adapter_name(),
			"renderer": RenderingServer.get_current_rendering_method(), "godot": Engine.get_version_info().string,
			"resolution": DisplayServer.window_get_size(), "vsync": DisplayServer.window_get_vsync_mode(),
			"fps_cap": Engine.max_fps, "x09_present": x09, "max_ms_by_salvo": _tag_max, "death_frames": _events,
			"frames_over_16_7_ms": _spikes, "round_2_frames": _round_2_frames,
			"round_2_compile_frames": _round_2_compile_frames, "control_hitch_threshold_ms": CONTROL_HITCH_MS,
			"late_shaders": gfx.late_shader_names()}
		output.store_string(JSON.stringify(report, "  ") + "\n")
		output.close()
		print("KILL_FRAME deaths=%d long_frames=%d" % [_events.size(), _spikes.size()])
		print("KILL_FRAME round_2_frames=%d compile_frames=%d" % [_round_2_frames, _round_2_compile_frames.size()])
		var expect_hitch := args.has("require-round-2-hitch")
		var expect_no_compiles := args.has("require-no-round-2-compiles")
		if expect_hitch or expect_no_compiles:
			if DisplayServer.get_name() == "headless" or report["renderer"] != "forward_plus":
				push_error("KILL_FRAME round 2 check needs a windowed Forward+ replay")
				_quit(1)
				return
		if expect_hitch and not _has_round_2_hitch():
			push_error("KILL_FRAME control did not reproduce a round 2 compile hitch of at least %.0f ms" % CONTROL_HITCH_MS)
			_quit(VERDICT_FAILED)
			return
		if expect_no_compiles and not _round_2_compile_frames.is_empty():
			push_error("KILL_FRAME round 2 compiled pipelines after the load cover")
			_quit(VERDICT_FAILED)
			return
		super._quit_report()


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var battle := TimedBattle.new()
	battle.name = "Battle"
	root.add_child(battle)
