extends SceneTree
# Force the smoke-test hazards without depending on exported hull assets.
const FX := preload("res://fx/fx.gd")
var errors := 0

class ErrorLog extends Logger:
	var n := 0
	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type != Logger.ERROR_TYPE_WARNING: n += 1

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var a := OS.get_cmdline_user_args()
	# Optional original scripts let this same test prove the failure before the fix.
	var sound = load(a[0] if a.size() > 0 else "res://audio/sfx.gd")
	var death = load(a[1] if a.size() > 1 else "res://fx/fx_death.gd")
	var logger := ErrorLog.new()
	OS.add_logger(logger)
	var s = sound.new()
	root.add_child(s)
	s.set_process(false)
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 8000
	var samples := PackedByteArray(); samples.resize(16000); wave.data = samples
	# Three staggered players are cancelled before any of their timers fire.
	for i in 3:
		var tag := "cancelled_%d" % i
		s._start("death_run", {"tag": tag}, [{"st": wave, "r": 1.0, "pj": 0.0, "g": 1.0, "d": 0.12}])
		s.stop_tag(tag)
	await create_timer(0.2, true, false, true).timeout
	# A pending start must also die with the SFX node itself.
	s.last["death_run"] = s._now() + 0.05
	s.play("death_run")
	s.free()
	await create_timer(0.2, true, false, true).timeout
	var fx := FX.new()
	root.add_child(fx)
	fx.set_process(false)
	FX.register_globals()
	fx.phys_root = Node3D.new(); fx.add_child(fx.phys_root)
	death.setup_physics(fx)
	# Exercise real debris with both a shader override and a missing override.
	death.spawn_debris(fx, Vector3.ZERO, Vector3.ZERO, 1, 0.1)
	fx.dstate["debris_mat"] = null
	death.spawn_debris(fx, Vector3.ZERO, Vector3.ZERO, 1, 0.1)
	# An early-cleared fireball must not leave a freed node in the FX queue.
	death.fireball(fx, Vector3.ZERO, 1.0, 0.0, 0.1, Color.WHITE)
	for child in fx.get_children():
		if child.name == "fx_fireball": child.free()
	fx.now = 1.0; fx._run_later()
	fx.free()
	await process_frame
	errors = logger.n
	OS.remove_logger(logger)
	print("SMOKE LIFETIME %s: %d engine/script errors" % ["PASS" if errors == 0 else "FAIL", errors])
	quit(0 if errors == 0 else 1)
