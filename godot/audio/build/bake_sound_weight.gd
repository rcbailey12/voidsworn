extends SceneTree
# Issue 771: bake the listening page renders for docs/shots/sound_weight/.
# Runs the real cue path through the Master bus (with its compressor and limiter) and captures it, so the wav the player opens is the
# game's own mix. Two passes per event: before (legacy, the dry sound on main) and after (the issue
# 771 weight). Headless:
#   godot --headless --path godot --script res://audio/build/bake_sound_weight.gd
const Sfx := preload("res://audio/sfx.gd")
const FXDeath := preload("res://fx/fx_death.gd")
var fails := 0

func _init() -> void:
	call_deferred("_run")

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

func _until(t0: float, t: float) -> void:
	var d := t0 + t - _now()
	if d > 0.0:
		await create_timer(d).timeout

func _run() -> void:
	var s := Sfx.new()
	root.add_child(s)
	await process_frame
	var cap := AudioEffectCapture.new()
	cap.buffer_length = 60.0
	AudioServer.add_bus_effect(0, cap)
	var out := ProjectSettings.globalize_path("res://").path_join("..").path_join("docs/shots/sound_weight")
	for sub in ["before", "after"]:
		DirAccess.make_dir_recursive_absolute(out.path_join(sub))
	await _death(s, cap, out, "cruiser_death", false)
	await _death(s, cap, out, "cruiser_death", true)
	await _death(s, cap, out, "capital_death", false, true)
	await _death(s, cap, out, "capital_death", true, true)
	await _lance(s, cap, out, false)
	await _lance(s, cap, out, true)
	await _shield(s, cap, out, false)
	await _shield(s, cap, out, true)
	s.free()
	print("SOUND WEIGHT BAKE ", "PASS" if fails == 0 else "FAIL (%d)" % fails, " -> ", out)
	quit(0 if fails == 0 else 1)

func _capture(cap: AudioEffectCapture, path: String) -> void:
	var frames := cap.get_frames_available()
	if frames <= 0:
		fails += 1
		print("  FAIL no captured frames for ", path)
		return
	var buf := cap.get_buffer(frames)
	var step := 2
	var m := int(frames / step)
	var data := PackedByteArray()
	data.resize(m * 2)
	for i in m:
		var v := (buf[i * step].x + buf[i * step].y) * 0.5
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 22050
	w.stereo = false
	w.data = data
	w.save_to_wav(path)
	print("  ", path.get_file(), " ", snappedf(float(frames) / AudioServer.get_mix_rate(), 0.01), " s")

# A cruiser or capital death, in the real cues and timings from the death beats.
func _death(s: Node, cap: AudioEffectCapture, out: String, name: String, after: bool, capital := false) -> void:
	var tl = FXDeath.DeathTimeline.new(true, 2 if capital else 1, "capital" if capital else "cruiser", "blast")
	var span := float(tl.cut) + float(tl.cool)
	var fac := "hegemony"
	s.legacy = not after
	s.stop_all()
	await process_frame
	cap.clear_buffer()
	var t0 := _now()
	s.play("death_powerdown")
	if after:
		s.death_bed(span)
	await _until(t0, 0.25)
	s.play("death_vent")
	await _until(t0, 0.4)
	s.play("death_crack", {"variant": fac})
	await _until(t0, float(tl.cut))
	s.play("boom_l", {"death": true})
	await _until(t0, float(tl.cut) + float(tl.core_delay))
	s.play("bass_drop", {"death": true})
	if after:
		s.mix_duck(-9.0, 0.6)
	await _until(t0, float(tl.cut) + 0.35)
	if after:
		s.death_tail()
	await _until(t0, float(tl.cut) + 0.7)
	s.play("wreck", {"death": true})
	if after and capital:
		await _until(t0, float(tl.cut) + float(tl.core_delay) + 0.9)
		s.quiet(-26.0, 0.35)
	await _until(t0, span + 0.4)
	_capture(cap, out.path_join("after" if after else "before").path_join(name + ".wav"))
	s.stop_all()
	await create_timer(0.2).timeout

func _lance(s: Node, cap: AudioEffectCapture, out: String, after: bool) -> void:
	s.legacy = not after
	s.stop_all()
	await process_frame
	cap.clear_buffer()
	s.lance(false, "hegemony")
	await create_timer(2.2).timeout
	_capture(cap, out.path_join("after" if after else "before").path_join("lance_shot.wav"))
	s.stop_all()
	await create_timer(0.2).timeout

func _shield(s: Node, cap: AudioEffectCapture, out: String, after: bool) -> void:
	s.legacy = not after
	s.stop_all()
	await process_frame
	cap.clear_buffer()
	s.play("shield_break")
	await create_timer(2.8).timeout
	_capture(cap, out.path_join("after" if after else "before").path_join("shield_break.wav"))
	s.stop_all()
	await create_timer(0.2).timeout
