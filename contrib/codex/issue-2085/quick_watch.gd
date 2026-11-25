extends "res://main/test/quick_battle_shots_check.gd"
# Run the unchanged windowed check. The worker sees only the last text published
# by the main thread, so it can keep logging if the scene tree stops.

class Heartbeat extends RefCounted:
	var lock := Mutex.new()
	var sample := "waiting for first frame"
	var step := "init"
	var at := 0
	var stop := false

	func run() -> void:
		var next := Time.get_ticks_msec()
		while true:
			lock.lock()
			var done := stop
			var text := sample
			var stage := step
			var last := at
			lock.unlock()
			if done:
				return
			var now := Time.get_ticks_msec()
			if now >= next:
				print("[quick-watch] %d ms unchanged=%d ms step=%s %s" % [now, now - last, stage, text])
				next = now + 1000
			OS.delay_msec(50)


var _heartbeat := Heartbeat.new()
var _thread := Thread.new()


func _init() -> void:
	if _thread.start(_heartbeat.run) != OK:
		_fail("could not start the quick battle watchdog")
		return
	process_frame.connect(_sample)
	RenderingServer.frame_pre_draw.connect(_draw_stage.bind("pre_draw"))
	RenderingServer.frame_post_draw.connect(_draw_stage.bind("post_draw"))
	super._init()


func _sample() -> void:
	var main := current_scene
	var text := "frame=%d waiting for battle" % Engine.get_process_frames()
	if is_instance_valid(main) and is_instance_valid(main.battle):
		var b = main.battle
		text = "frame=%d load=%s round=%s phase=%s busy=%s thinking=%s ended=%s result=%s fx=%s shot=%d quitting=%s" % [
			Engine.get_process_frames(), b.load_phase, b.V.get("round", "-"), b.V.get("phase", "-"),
			b.busy, b._think_tid, b.ended, b.result.get("result", "-"),
			b.gfx.get("now") if is_instance_valid(b.gfx) else "-", b.shot_n, main.quitting]
	_heartbeat.lock.lock()
	_heartbeat.sample = text
	_heartbeat.at = Time.get_ticks_msec()
	_heartbeat.step = "process_frame"
	_heartbeat.lock.unlock()


func _draw_stage(stage: String) -> void:
	_heartbeat.lock.lock()
	_heartbeat.step = stage
	_heartbeat.lock.unlock()


func _finalize() -> void:
	if _thread.is_started():
		_heartbeat.lock.lock()
		_heartbeat.stop = true
		_heartbeat.lock.unlock()
		_thread.wait_to_finish()
