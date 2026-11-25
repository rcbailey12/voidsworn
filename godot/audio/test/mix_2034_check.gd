extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 2034 (AAA item 8, the sound mix): Effects and Tactical cues volume channels, voice stealing by audibility, sustained
# sounds that follow the camera, the 20-ship salvo soak with node counts (and the churn trace that decides pooling), and the
# music's objective urgency. Everything runs on the real Sfx node and the real music player; no new sound files.
const Sfx := preload("res://audio/sfx.gd")
const Music := preload("res://music/music_player.gd")
const MainScript := preload("res://main/main.gd")
const Title := preload("res://main/title.gd")
var fails: Array = []
var s: Node
var cam: Camera3D

func _init() -> void:
	GUARD.arm(self, "mix_2034_check")
	call_deferred("_run")

func _ok(c: bool, message: String) -> void:
	if not c:
		fails.append(message)
		print("  FAIL ", message)

func _db(bus: String) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))

func _muted(bus: String) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus))

func _fresh() -> void:
	s.stop_all()
	s.last.clear()
	s.salvo.clear()
	s.rr.clear()
	s.focus_fn = Callable()
	seed(2034)

func _run() -> void:
	cam = Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(0, 120, 0)
	s = Sfx.new()
	root.add_child(s)
	s.cam = cam
	await process_frame
	await _settings()
	await _stealing()
	await _follow()
	await _soak()
	_music()
	s.stop_all()
	await create_timer(0.2).timeout
	s.free()
	cam.free()
	await create_timer(0.15).timeout
	print("MIX 2034 CHECK ", "PASS" if fails.is_empty() else "FAIL (%d)" % fails.size())
	quit(0 if fails.is_empty() else 1)

# ---- item 1: the two new volume channels ----
func _settings() -> void:
	var main := MainScript.new()
	_ok(float(main.settings["effects_volume"]) == 1.0 and float(main.settings["tactical_volume"]) == 1.0, "1: both channels default to 1.0, the mix as it was")
	# an old settings file has neither key: the defaults stay (the loader only overwrites keys the file has)
	var old_file: Dictionary = {"volume": 0.5, "music_volume": 0.3}
	for k in old_file:
		main.settings[k] = old_file[k]
	_ok(float(main.settings["effects_volume"]) == 1.0 and float(main.settings["volume"]) == 0.5, "1: a settings file written before the sliders keeps both at 1.0")
	main.free()
	var listed := []
	for sec in Title.SETTINGS_LAYOUT:
		for item in sec[2]:
			listed.append(str(item[1]) + "|" + str(item[2]) + "|" + str(item[0]))
	_ok("Effects volume|effects_volume|slider" in listed and "Tactical cues volume|tactical_volume|slider" in listed, "1: Settings lists Effects volume and Tactical cues volume as sliders under Sound and music")
	_ok(float(Title.SLIDER_DEFAULTS["effects_volume"]) == 1.0 and float(Title.SLIDER_DEFAULTS["tactical_volume"]) == 1.0, "1: a missing key shows a full slider, not 0.7")
	s.set_effects_volume(1.0)
	s.set_tactical_volume(1.0)
	await process_frame
	var e1 := _db("battle_sfx")
	var d1 := _db("death")
	var u1 := _db("ui")
	_ok(absf(d1) < 0.01, "1: at 1.0 the death bus sits at 0 dB (%.2f)" % d1)
	_ok(absf(u1 - linear_to_db(1.0)) < 0.01, "1: at 1.0 the ui bus keeps its base level (%.2f)" % u1)
	s.set_effects_volume(0.5)
	s.set_tactical_volume(0.5)
	await process_frame
	var want := linear_to_db(Sfx.channel_gain(0.5))
	_ok(absf(_db("battle_sfx") - e1 - want) < 0.05 and absf(_db("death") - want) < 0.05, "1: Effects at 0.5 lowers the battle and death buses by %.1f dB (%.2f, %.2f)" % [want, _db("battle_sfx") - e1, _db("death")])
	_ok(absf(_db("ui") - u1 - want) < 0.05, "1: Tactical cues at 0.5 lowers the ui bus by %.1f dB (%.2f)" % [want, _db("ui") - u1])
	_ok(absf(_db("sfx") - (linear_to_db(maxf(0.62 * pow(s.vol, 1.6), 1e-5)) + 2.0)) < 0.05, "1: the master Volume's sfx bus is untouched by the channels")
	s.set_effects_volume(0.0)
	s.set_tactical_volume(1.0)
	await process_frame
	_ok(_muted("battle_sfx") and _muted("death") and not _muted("ui"), "1: Effects at 0 mutes the battle and death buses and leaves the ui bus on")
	s.set_effects_volume(1.0)
	s.set_tactical_volume(0.0)
	await process_frame
	_ok(not _muted("battle_sfx") and not _muted("death") and _muted("ui"), "1: Tactical cues at 0 mutes the ui bus and leaves the battle buses on")
	s.set_effects_volume(NAN)
	s.set_tactical_volume(INF)
	_ok(s.effects_vol == 1.0 and s.tactical_vol == 0.0, "1: a non-finite value changes nothing")
	s.set_effects_volume(1.0)
	s.set_tactical_volume(1.0)
	await process_frame
	_ok(not _muted("ui") and not _muted("battle_sfx") and absf(_db("ui") - u1) < 0.01 and absf(_db("battle_sfx") - e1) < 0.01, "1: both channels back at 1.0 give the original mix")

# ---- item 2: voice stealing ----
func _voice_at(name: String, pos: Vector3) -> Dictionary:
	for v in s.by_cue.get(name, []):
		if v.pos is Vector3 and (v.pos as Vector3).is_equal_approx(pos):
			return v
	return {}

func _stealing() -> void:
	# a cue at its cap: the oldest voice is no longer the one that goes
	_fresh()
	var cap := int(s.cues["hit"].max)
	var near := Vector3(0, 0, 0)       # 120 from the camera
	var far := Vector3(900, 0, 900)
	s.play("hit", {"pos": near})
	await create_timer(0.02).timeout
	for i in range(cap - 1):
		s.last.clear()
		s.play("hit", {"pos": far + Vector3(i * 3.0, 0, 0)})
		await create_timer(0.02).timeout
	_ok(s.by_cue["hit"].size() == cap, "2: the cue is full (%d of %d)" % [s.by_cue["hit"].size(), cap])
	s.last.clear()
	s.play("hit", {"pos": far + Vector3(50, 0, 0)})
	await create_timer(0.02).timeout
	_ok(not _voice_at("hit", near).is_empty(), "2: the near ship's hit (the oldest voice) is kept when the cue is full")
	_ok(s.by_cue["hit"].size() == cap, "2: the cap still holds after a steal (%d)" % s.by_cue["hit"].size())
	# a far sound arriving at a full cue of near sounds is dropped, not allowed to push a near one out
	_fresh()
	for i in cap:
		s.last.clear()
		s.play("hit", {"pos": near + Vector3(i * 2.0, 0, 0)})
		await create_timer(0.02).timeout
	var before: Array = s.by_cue["hit"].duplicate()
	s.last.clear()
	s.play("hit", {"pos": far})
	await create_timer(0.02).timeout
	_ok(s.by_cue["hit"] == before, "2: a far sound is dropped when every voice held is nearer")
	# the selected ship's voice is kept over a nearer unselected one
	_fresh()
	var sel_pos := Vector3(700, 0, 700)
	s.focus_fn = func() -> Variant: return sel_pos
	s.play("hit", {"pos": sel_pos})
	await create_timer(0.02).timeout
	for i in range(cap - 1):
		s.last.clear()
		s.play("hit", {"pos": near + Vector3(i * 2.0, 0, 0)})
		await create_timer(0.02).timeout
	s.last.clear()
	s.play("hit", {"pos": near + Vector3(40, 0, 0)})
	await create_timer(0.02).timeout
	_ok(not _voice_at("hit", sel_pos).is_empty(), "2: the selected ship's voice is kept although it is far and the oldest")
	# no places at all (ui cues): the oldest still goes, as before
	_fresh()
	var ucap := int(s.cues["ui_click"].max)
	var firsts: Array = []
	for i in ucap + 1:
		s.last.clear()
		s.play("ui_click")
		await create_timer(0.02).timeout
		if i == 0:
			firsts.append(s.by_cue["ui_click"][0])
	_ok(s.by_cue["ui_click"].size() == ucap and not s.by_cue["ui_click"].has(firsts[0]), "2: with no places the oldest voice is the one stolen, as before")
	# the global cap: a lower priority voice goes first, and among equals the least audible one
	_fresh()
	s.max_voices = 6
	var keep := Vector3(10, 0, 0)
	s.play("gun_shell", {"pos": keep})
	await create_timer(0.02).timeout
	for i in 5:
		s.last.clear()
		s.play("gun_las", {"pos": far + Vector3(i * 5.0, 0, 0)})
		await create_timer(0.02).timeout
	_ok(s.active.size() == 6, "2: six voices fill the global cap (%d)" % s.active.size())
	s.last.clear()
	s.play("hit", {"pos": near})
	await create_timer(0.02).timeout
	_ok(s.active.size() <= 6, "2: the global cap holds (%d)" % s.active.size())
	_ok(not _voice_at("gun_shell", keep).is_empty(), "2: the nearest voice survives the global steal (the oldest, equal priority)")
	s.max_voices = 34
	_fresh()

# ---- item 3: sustained sounds follow the camera ----
func _follow() -> void:
	_fresh()
	cam.global_position = Vector3(0, 120, 0)
	var pos := Vector3(0, 0, 0)
	s.play("death_bed", {"pos": pos, "duration": 4.0, "death": true})
	await create_timer(0.03).timeout
	var v: Dictionary = s.by_cue["death_bed"][0]
	_ok(bool(v.follow), "3: a 4 s positional voice follows the camera")
	var p: AudioStreamPlayer3D = v.players[0]
	var db0 := p.volume_db
	cam.global_position = Vector3(0, 900, 0)   # the camera pulls far back
	await create_timer(0.5).timeout
	var db1 := p.volume_db
	_ok(db1 < db0 - 0.3, "3: pulling the camera back makes the sustained sound softer (%.2f to %.2f dB)" % [db0, db1])
	var lin0 := db_to_linear(db0)
	var lin1 := db_to_linear(db1)
	# the factor may move at most FOLLOW_RATE per second (0.3 over 0.5 s, plus a frame of slack)
	_ok(lin0 - lin1 <= lin0 * (Sfx.FOLLOW_RATE * 0.62 + 0.05), "3: it moves gently, not in one jump (%.3f to %.3f)" % [lin0, lin1])
	await create_timer(2.2).timeout
	var db2 := p.volume_db
	var floor_lin := db_to_linear(db0) * (_near_start(900.0) / _near_start(120.0))
	_ok(db2 < db1 and absf(db_to_linear(db2) - floor_lin) < floor_lin * 0.1 + 0.002, "3: it settles at the far level, never below half (%.2f dB, wanted %.4f got %.4f)" % [db2, floor_lin, db_to_linear(db2)])
	# a short shot does not follow
	_fresh()
	s.play("hit", {"pos": pos})
	await create_timer(0.03).timeout
	_ok(not bool(s.by_cue["hit"][0].follow), "3: a short impact does not follow the camera")
	# a voice in its own fade-out is left alone
	_fresh()
	cam.global_position = Vector3(0, 120, 0)
	s.play("death_bed", {"pos": pos, "duration": 1.2, "death": true})
	await create_timer(0.03).timeout
	var v2: Dictionary = s.by_cue["death_bed"][0]
	_ok(float(v2.fade_at) < float(v2.end) and float(v2.fade_at) > float(v2.start), "3: a timed voice records where its own fade-out begins")
	_fresh()
	cam.global_position = Vector3(0, 120, 0)

func _near_start(dist: float) -> float:
	return clampf(sqrt(Sfx.DIST_REF / maxf(1.0, dist)), 0.5, 1.0)

# ---- item 4 and the soak: a 20-ship salvo, node counts, and the churn trace ----
var _adds := 0
var _removes := 0
func _on_add(_n: Node) -> void:
	_adds += 1
func _on_remove(_n: Node) -> void:
	_removes += 1

func _soak() -> void:
	_fresh()
	cam.global_position = Vector3(0, 220, 120)
	await create_timer(0.3).timeout
	var base_kids := s.get_child_count()
	var orphans0 := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	s.child_entered_tree.connect(_on_add)
	s.child_exiting_tree.connect(_on_remove)
	var ships: Array = []
	for i in 20:
		ships.append(Vector3(-150.0 + (i % 5) * 70.0, 0, -90.0 + (i / 5) * 60.0))
	var rows: Array = []
	var peak_kids := 0
	var peak_active := 0
	var total_adds := 0
	var total_removes := 0
	var call_us_max := 0
	var call_us_sum := 0
	var calls := 0
	var t_prev := Time.get_ticks_usec()
	# two volleys 0.9 s apart: every ship fires its twin gun, 3 ships take a hit and a shield pop, 2 explode
	var frame := 0
	var fired := [false, false]
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 4500:
		_adds = 0
		_removes = 0
		var el := Time.get_ticks_msec() - t0
		var us0 := Time.get_ticks_usec()
		for round in 2:
			if not fired[round] and el >= round * 900:
				fired[round] = true
				for i in ships.size():
					s.gun("gun", false, "twin", ships[i], float(i) * 0.012)
					s.gun("las", false, "las", ships[(i + 7) % 20], float(i) * 0.01)
					calls += 3
				for i in range(0, 20, 3):
					s.hit(ships[i], i % 2 == 0)
					s.shield(ships[(i + 1) % 20], false)
					calls += 2
				s.boom(1.2, ships[3])
				s.boom(0.5, ships[11])
				s.death_bed(1.5, ships[3])
				s.hit(ships[0], false)
		var call_us := Time.get_ticks_usec() - us0
		call_us_max = maxi(call_us_max, call_us)
		call_us_sum += call_us
		await process_frame
		frame += 1
		var now_us := Time.get_ticks_usec()
		var kids := s.get_child_count()
		peak_kids = maxi(peak_kids, kids)
		peak_active = maxi(peak_active, s.active.size())
		total_adds += _adds
		total_removes += _removes
		rows.append({"f": frame, "ms": float(now_us - t_prev) / 1000.0, "adds": _adds, "rem": _removes, "kids": kids, "act": s.active.size()})
		t_prev = now_us
		if s.active.size() > s.max_voices:
			_ok(false, "soak: the voice cap broke (%d)" % s.active.size())
	s.child_entered_tree.disconnect(_on_add)
	s.child_exiting_tree.disconnect(_on_remove)
	# the trace: the slowest frames and what they did to the node tree
	var by_ms := rows.duplicate()
	by_ms.sort_custom(func(a, b): return float(a.ms) > float(b.ms))
	print("  SOAK TRACE 20 ships, 2 volleys: %d frames, %d players added, %d freed, peak %d children (%d at rest), peak %d voices" % [rows.size(), total_adds, total_removes, peak_kids, base_kids, peak_active])
	var churn_frames := 0
	for r in rows:
		if int(r.adds) + int(r.rem) > 0:
			churn_frames += 1
	print("  SOAK TRACE: play calls on the volley frames took at most %.2f ms, %d play requests" % [float(call_us_max) / 1000.0, calls])
	print("  SOAK TRACE slowest 6 frames (frame, ms, players added, freed, children, voices):")
	for i in mini(6, by_ms.size()):
		var r: Dictionary = by_ms[i]
		print("    f%d %.2f ms +%d -%d kids %d voices %d" % [r.f, r.ms, r.adds, r.rem, r.kids, r.act])
	var slow_adds := 0
	var slow_n := 0
	for r in rows:
		if float(r.ms) > 8.0:
			slow_n += 1
			slow_adds += int(r.adds) + int(r.rem)
	print("  SOAK TRACE: %d frames over 8 ms carried %d add/free events; %d of %d frames had any churn" % [slow_n, slow_adds, churn_frames, rows.size()])
	# settle and compare with the start
	await create_timer(2.5).timeout
	var orphans1 := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_ok(total_adds > 0, "soak: the salvo made sounds (%d players)" % total_adds)
	_ok(peak_kids <= base_kids + s.max_voices * 4, "soak: node count stayed bounded by the voice cap (peak %d)" % peak_kids)
	_ok(peak_active <= s.max_voices, "soak: the global voice cap held (peak %d)" % peak_active)
	_ok(s.active.is_empty() and s.by_cue.values().all(func(a): return a.is_empty()), "soak: every voice ended (%d left)" % s.active.size())
	_ok(s.get_child_count() == base_kids, "soak: the node count came back to %d (now %d)" % [base_kids, s.get_child_count()])
	_ok(orphans1 <= orphans0, "soak: no orphan nodes left behind (%d before, %d after)" % [orphans0, orphans1])
	_ok(total_adds == total_removes or s.get_child_count() == base_kids, "soak: every added player was freed (%d added, %d freed)" % [total_adds, total_removes])

# ---- item 5: the music hears the objective ----
func _music() -> void:
	var m = Music.new()
	var units_far := [
		{"side": "enemy", "dead": false, "fled": false, "squadron": false, "weapons": [], "r": 3, "mp": 3},
		{"side": "enemy", "dead": false, "fled": false, "squadron": false, "weapons": [{"i": 0}], "r": 21, "mp": 4}]
	var units_near := [
		{"side": "enemy", "dead": false, "fled": false, "squadron": false, "weapons": [], "r": 19, "mp": 3},
		{"side": "enemy", "dead": false, "fled": false, "squadron": false, "weapons": [{"i": 0}], "r": 2, "mp": 4}]
	var gunship_at_edge := [{"side": "enemy", "dead": false, "fled": false, "squadron": false, "weapons": [{"i": 0}], "r": 21, "mp": 4}]
	var ic := {"type": "intercept", "exitR": 21, "total": 3, "need": 2, "esc": 0, "kill": 0}
	_ok(m.objective_urgency(ic, units_far) == 0.0, "5: a transport three moves from the exit gives no urgency")
	_ok(m.objective_urgency(ic, units_near) == 0.7, "5: a transport one move from the exit gives 0.7 (%s)" % str(m.objective_urgency(ic, units_near)))
	_ok(m.objective_urgency(ic, gunship_at_edge) == 0.0, "5: an escort by the exit is not a transport")
	var ic2 := ic.duplicate()
	ic2["esc"] = 1
	_ok(m.objective_urgency(ic2, units_near) == 1.0, "5: the transport that would end the fight gives 1.0")
	var dead := [{"side": "enemy", "dead": true, "fled": false, "squadron": false, "weapons": [], "r": 20, "mp": 3}]
	_ok(m.objective_urgency(ic, dead) == 0.0, "5: a destroyed transport gives none")
	_ok(m.objective_urgency({"type": "hold", "score": 0, "escore": 0}, []) == 0.0, "5: a quiet relay gives none")
	_ok(m.objective_urgency({"type": "hold", "score": 1, "escore": 0}, []) == 0.35, "5: a relay one tick in gives 0.35")
	_ok(m.objective_urgency({"type": "hold", "score": 0, "escore": 2}, []) == 1.0, "5: a relay the enemy is one tick from taking gives 1.0")
	_ok(m.objective_urgency({"type": "hold", "score": 2, "escore": 0}, []) == 1.0, "5: a relay the player is one tick from holding gives 1.0")
	_ok(m.objective_urgency(null, []) == 0.0 and m.objective_urgency({"type": "rout"}, []) == 0.0 and m.objective_urgency({"type": "defend", "hp": 1}, []) == 0.0, "5: no objective, a rout and a defend give none")
	var base := {"close": 1, "shots": 2, "hull": 1.0, "flagship": 1.0, "mine": 5, "enemy": 5}
	var calm: float = m.feed(base)
	var tense: float = m.feed(base.merged({"urgency": 1.0}))
	var half: float = m.feed(base.merged({"urgency": 0.5}))
	_ok(absf((tense - calm) - Music.URGENCY_LIFT) < 0.001 and half > calm and half < tense, "5: full urgency lifts the battle intensity by %.2f, half by half of it (%.2f, %.2f, %.2f)" % [Music.URGENCY_LIFT, calm, half, tense])
	_ok(m.feed(base) == calm, "5: a feed with no urgency key is the intensity it always was")
	var ending: float = m.feed({"mine": 3, "enemy": 0, "urgency": 1.0})
	_ok(ending == 0.3, "5: the ending ease-off still wins over urgency (%.2f)" % ending)
	m.free()
