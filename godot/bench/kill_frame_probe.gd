extends SceneTree
## Replays the Corsair seed 7 battle with the torpedo timing tags and no image readbacks.
## Run through the kill_frame_1829 or round_2_compile_1843 PC job on the Board's GPU queue.


class TimedBattle extends "res://scenes/battle/battle.gd":
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

	func _ready() -> void:
		super._ready()
		# The salvo logger is enabled after _ready reads its capture options, so
		# the original torpedo windows run with the screenshot directory empty.
		args["torp-shots"] = true
		args["torp-ft"] = true
		RenderingServer.frame_pre_draw.connect(_mark_draw_round)

	func _mark_draw_round() -> void:
		_draw_round = int(V.get("round", 0))

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
		if wall_ms < 1000.0 / 60.0 and events.is_empty() and not round_2_compile:
			return
		var row := {"frame": Engine.get_process_frames(), "round": round_no, "draw_round": drawn_round, "salvo": frame_tag,
			"wall_ms": wall_ms, "process_delta_ms": dt * 1000.0, "draw_and_specialization_pipelines": pipes,
			"battle_process_usec": _last_battle_usec, "bot_step_usec": _last_bot_usec, "bot_rules_usec": _last_bot_rules_usec,
			"engine_process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			"engine_physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			"fx_usec": profile, "deaths": events}
		if not events.is_empty():
			_events.append(row)
		if wall_ms >= 1000.0 / 60.0:
			_spikes.append(row)
		if round_2_compile:
			_round_2_compile_frames.append(row)

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
			"round_2_compile_frames": _round_2_compile_frames,
			"late_shaders": gfx.late_shader_names()}
		output.store_string(JSON.stringify(report, "  ") + "\n")
		output.close()
		print("KILL_FRAME deaths=%d long_frames=%d" % [_events.size(), _spikes.size()])
		print("KILL_FRAME round_2_frames=%d compile_frames=%d" % [_round_2_frames, _round_2_compile_frames.size()])
		if args.has("require-no-round-2-compiles"):
			if DisplayServer.get_name() == "headless" or report["renderer"] != "forward_plus":
				push_error("KILL_FRAME round 2 check needs a windowed Forward+ replay")
				_quit(1)
				return
			if not _round_2_compile_frames.is_empty():
				push_error("KILL_FRAME round 2 compiled pipelines after the load cover")
				_quit(1)
				return
		super._quit_report()


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var battle := TimedBattle.new()
	battle.name = "Battle"
	root.add_child(battle)
