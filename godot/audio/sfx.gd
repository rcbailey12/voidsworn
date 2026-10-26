extends Node
# The game's sound (sfx.js) in Godot: the same cue table (cues.json, rendered from sfx.js by build/render_synth.js), the
# same recorded clips (clips/, converted from sfx_data.js) and the same synth takes (synth/, rendered offline from the
# game's own synth code). A cue plays its recorded layers (round robin, pitch jitter, rate and delay per layer) plus its
# synth take when listed, exactly as SFX._layers and SFX.play do, with the voice caps, gaps, salvo thinning and buses.
# Panning comes from the ship's place on screen (3D players heard from the camera).

const BUSES := {"weapons": 0.8, "impacts": 0.8, "explosions": 1.0, "ui": 1.0, "ambient": 0.5}
const SENDS := {"weapons": 0.22, "impacts": 0.2, "explosions": 0.3, "ui": 0.06}

var cues := {}
var clips := {}            # clip key -> [AudioStream]
var synth := {}            # cue -> [AudioStream]
var last := {}             # cue -> time of last start
var active: Array = []     # [{name, players, end, pri}]
var by_cue := {}
var salvo := {}
var tail_t := -9.0
var rr := {}
var vol := 0.8
var on := true
var max_voices := 34
var _amb: AudioStreamPlayer
var cam: Camera3D


func _ready() -> void:
	_buses()
	var t0 := Time.get_ticks_msec()
	if FileAccess.file_exists("res://audio/cues.json"):
		cues = JSON.parse_string(FileAccess.get_file_as_string("res://audio/cues.json"))
	var idx = JSON.parse_string(FileAccess.get_file_as_string("res://audio/clips/index.json")) if FileAccess.file_exists("res://audio/clips/index.json") else {}
	for k in idx:
		var a: Array = []
		for f in idx[k]:
			var s := _load("res://audio/clips/" + f)
			if s != null:
				a.append(s)
		if not a.is_empty():
			clips[k] = a
	for k in cues:
		var a: Array = []
		for f in cues[k]["synth"]:
			var s := _load("res://audio/synth/" + f)
			if s != null:
				a.append(s)
		synth[k] = a
	print("[sfx] %d cues, %d clip sets, loaded in %d ms" % [cues.size(), clips.size(), Time.get_ticks_msec() - t0])
	set_volume(vol)


func _load(p: String) -> AudioStream:
	# the imported stream when the project has been imported or exported, else the raw Ogg file
	if FileAccess.file_exists(p + ".import"):
		var r = load(p)
		if r is AudioStream:
			return r
	if not FileAccess.file_exists(p):
		return null
	return AudioStreamOggVorbis.load_from_file(p)


func _buses() -> void:
	if AudioServer.get_bus_index("weapons") >= 0:
		return
	# master chain as in the game: gentle compressor, then a brickwall limiter
	var m := 0
	var comp := AudioEffectCompressor.new()
	comp.threshold = -22.0
	comp.ratio = 2.6
	comp.attack_us = 14000.0
	comp.release_ms = 300.0
	AudioServer.add_bus_effect(m, comp)
	var lim := AudioEffectHardLimiter.new()
	lim.ceiling_db = -1.0
	AudioServer.add_bus_effect(m, lim)
	for k in BUSES:
		var i := AudioServer.bus_count
		AudioServer.add_bus(i)
		AudioServer.set_bus_name(i, k)
		AudioServer.set_bus_send(i, "Master")
		AudioServer.set_bus_volume_db(i, linear_to_db(BUSES[k]))
		if SENDS.has(k):
			# the game's short dark reverb send
			var rv := AudioEffectReverb.new()
			rv.room_size = 0.35
			rv.damping = 0.75
			rv.wet = SENDS[k] * 0.9
			rv.dry = 1.0
			rv.predelay_msec = 12.0
			AudioServer.add_bus_effect(i, rv)


func set_volume(v: float) -> void:
	vol = clampf(v, 0.0, 1.0)
	var g := 0.62 * pow(vol, 1.6) if on else 0.0
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(g, 1e-5)) + 2.0)


func set_on(v: bool) -> void:
	on = v
	set_volume(vol)


func _pick(arr: Array, key: String):
	if arr.size() < 2:
		return arr[0]
	var ix := randi() % arr.size()
	if rr.get(key, -1) == ix:
		ix = (ix + 1) % arr.size()
	rr[key] = ix
	return arr[ix]


func _layers(name: String, cue: Dictionary) -> Array:
	var out: Array = []
	var sampled := false
	var sl = null
	for L in cue["layers"]:
		if L.has("s"):
			var a: Array = clips.get(L["s"], [])
			if not a.is_empty():
				out.append({"st": _pick(a, L["s"]), "g": float(L["g"]), "r": float(L["r"]), "d": float(L["d"]), "pj": float(L["pj"]) if L["pj"] != null else float(cue["spj"])})
				sampled = true
		elif L.has("syn"):
			sl = L
	var sy: Array = synth.get(name, [])
	if not sy.is_empty() and (not sampled or sl != null):
		out.append({"st": _pick(sy, name), "g": float(sl["g"]) if sampled else 1.0, "r": 1.0, "d": 0.0, "pj": float(cue["pj"])})
	return out


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


# o: {pos: Vector3, gain, rate, delay}
func play(name: String, o := {}) -> void:
	if not on or not cues.has(name):
		return
	var cue: Dictionary = cues[name]
	var lay := _layers(name, cue)
	if lay.is_empty():
		return
	var now := _now()
	var t := now + float(o.get("delay", 0.0)) + 0.004
	var gap := float(cue["gap"])
	var lt := float(last.get(name, -99.0))
	if gap > 0.0 and t < lt + gap:
		var nt := lt + gap * (1.0 + randf() * 0.6)
		if nt - now > float(cue["defer"]):
			return
		t = nt
	last[name] = t
	var gain := float(cue["g"]) * float(o.get("gain", 1.0))
	if cue["salvo"] != null:
		var sv: Dictionary = salvo.get(cue["salvo"], {"t": 0.0, "n": 0})
		sv.n = sv.n + 1 if now - sv.t < 0.45 else 1
		sv.t = now
		salvo[cue["salvo"]] = sv
		gain *= maxf(0.42, 1.0 / sqrt(1.0 + 0.3 * (sv.n - 1)))
		if sv.n == 4 and now - tail_t > 1.1:
			tail_t = now
			play("salvo_tail", {"gain": float(cue["tail"]), "delay": 0.06, "pos": o.get("pos")})
	var pos = o.get("pos")
	if pos is Vector3 and cam != null:
		var dist := cam.global_position.distance_to(pos)
		gain *= clampf(sqrt(230.0 / maxf(1.0, dist)), 0.5, 1.0)
	_reap(now)
	var list: Array = by_cue.get(name, [])
	while list.size() >= int(cue["max"]):
		_steal(list[0])
	if active.size() >= max_voices:
		var pri := int(cue["pri"])
		var vi := -1
		for i in active.size():
			if int(active[i].pri) <= pri:
				vi = i
				break
		if vi < 0:
			return
		_steal(active[vi])
	var u := randf() * 2.0 - 1.0
	var v := {"name": name, "players": [], "end": t, "pri": int(cue["pri"])}
	var dur := 0.0
	for L in lay:
		var rate := maxf(0.25, float(o.get("rate", 1.0)) * float(L.r) * (1.0 + u * float(L.pj)))
		var p: Node
		if pos is Vector3:
			var p3 := AudioStreamPlayer3D.new()
			p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
			p3.panning_strength = 0.72
			p3.position = pos
			p3.stream = L.st
			p3.pitch_scale = rate
			p3.volume_db = linear_to_db(maxf(gain * float(L.g), 1e-5))
			p3.bus = cue["bus"]
			p = p3
		else:
			var p2 := AudioStreamPlayer.new()
			p2.stream = L.st
			p2.pitch_scale = rate
			p2.volume_db = linear_to_db(maxf(gain * float(L.g), 1e-5))
			p2.bus = cue["bus"]
			p = p2
		add_child(p)
		var start := t + float(L.d) - now
		if start <= 0.01:
			p.call("play")
		else:
			get_tree().create_timer(start).timeout.connect(func() -> void:
				if is_instance_valid(p):
					p.call("play"))
		v.players.append(p)
		dur = maxf(dur, float(L.d) + (L.st as AudioStream).get_length() / rate)
	v.end = t + dur + 0.05
	list.append(v)
	by_cue[name] = list
	active.append(v)


func _drop(v: Dictionary) -> void:
	var l: Array = by_cue.get(v.name, [])
	l.erase(v)
	active.erase(v)


func _steal(v: Dictionary) -> void:
	_drop(v)
	for p in v.players:
		if is_instance_valid(p):
			var tw := create_tween()
			tw.tween_property(p, "volume_db", -60.0, 0.06)
			tw.tween_callback(p.queue_free)


func _reap(now: float) -> void:
	for i in range(active.size() - 1, -1, -1):
		var v: Dictionary = active[i]
		if v.end < now:
			_drop(v)
			for p in v.players:
				if is_instance_valid(p):
					p.queue_free()


func stop_all() -> void:
	for v in active.duplicate():
		_steal(v)


# ---- the game's cue helpers (sfx.js) ----

func gun(k: String, sq: bool, style, pos = null) -> void:
	if sq:
		play("gun_sq", {"pos": pos})
		return
	if k == "flak":
		play("gun_flak", {"pos": pos})
		return
	if style == "twin":
		play("gun_shell", {"pos": pos, "gain": 0.8})
		play("gun_shell", {"pos": pos, "gain": 0.6, "delay": 0.05})
		return
	var n := "gun_" + (str(style) if style != null else "shell")
	play(n if cues.has(n) else "gun_shell", {"pos": pos})


func lance(ion: bool, fac: String, pos = null) -> void:
	play("lance_dark" if fac == "deathless" else "lance_choir" if fac == "ithar" else "lance_ion" if ion else "lance", {"pos": pos})


func torp(fac: String, pos = null) -> void:
	var m := {"corsair": "torp_rocket", "chorus": "torp_sac", "ithar": "torp_star", "voidsworn": "torp_heavy"}
	play(m.get(fac, "torp"), {"pos": pos})


func hit(pos = null, heavy := false) -> void:
	play("hit_heavy" if heavy else "hit", {"pos": pos})


func shield(pos = null, big := false) -> void:
	play("shield_break" if big else "shield", {"pos": pos})


func boom(s := 1.0, pos = null) -> void:
	s = maxf(0.05, s)
	var n := "boom_s" if s < 0.35 else "boom_m" if s < 0.95 else "boom_l"
	var top := 0.35 if s < 0.35 else 0.95 if s < 0.95 else 1.5
	play(n, {"pos": pos, "gain": minf(1.15, 0.45 + 0.6 * s / top), "rate": 0.9 if s > 1.25 else 1.0})
	if s >= 1.1:
		play("bass_drop", {"pos": pos, "gain": minf(1.0, s / 1.5)})
	if s >= 1.0:
		play("wreck", {"pos": pos, "delay": 0.7, "gain": minf(1.0, s / 1.4)})


func turn(kind: String) -> void:
	play("ui_your" if kind == "player" else "ui_enemy" if kind == "enemy" else "ui_round")


func sting(win: bool) -> void:
	play("sting_win" if win else "sting_loss")


func ambient_start() -> void:
	if _amb != null or not clips.has("ambient"):
		return
	_amb = AudioStreamPlayer.new()
	var st: AudioStream = clips["ambient"][0]
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	_amb.stream = st
	_amb.bus = "ambient"
	_amb.volume_db = linear_to_db(0.065)
	add_child(_amb)
	_amb.play(randf() * st.get_length() * 0.5)
