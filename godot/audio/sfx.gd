extends Node
signal cue_started(name: String, options: Dictionary)
const HUDRes := preload("res://ui/battle/hud.gd")
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
var _bed: AudioStreamPlayer
const BED_GAIN := 0.0411      # render_ambient_bed.py prints it: the browser's bed level (0.065) over the file's normalising
var cam: Camera3D
var _pending_generation := 0
var _cancelled_tags := {}
var _loop_copies := {}   # issue 1237: source clip -> its looping copy
var _beat := false
var _ambient_duck_until := 0.0
var _ambient_duck := 0.0
# Issue 771: the mix ducks under a core flash and can hold a beat of near-silence after a capital death.
# legacy = the old dry/unducked behavior, used only by the listening-page bake to render the before pass.
var legacy := false
# Issue 1217: main.gd's front-end sound node loads only the cues whose names start with this ("ui_"), and only their
# clips, so the title and setup screens get their sounds without loading the battle's.
var only := ""
# The decorative battle can opt out before entering the tree. It leaves the shared audio buses alone.
var silent := false
static var _catalogs := {}    # not GPU: cue data and AudioStreams, shared without playback state
static var _cue_data: Dictionary    # not GPU: parsed cue table
static var _clip_index: Dictionary    # not GPU: clip names and paths
static var _streams := {}    # not GPU: path -> AudioStream (or null for a missing asset)
var _base_sfx_db := 0.0
var _duck_db := 0.0
var _duck_until := 0.0
var _quiet_db := 0.0
var _quiet_until := 0.0
# Cues changed in issue 771, so the bake's legacy pass can render the old (main) sound:
# the late tail layers and the small death pitch variation are left out.
const PASS_BY_CUE := {
	"g": 0.17, "pri": 0, "max": 2, "gap": 0.12, "defer": 0.0, "bus": "weapons",
	"salvo": null, "duck": 0.0, "spj": 0.08, "synth": [],
	# Issue 1752 Gate 2: the mastered pass-by (evt_pass_by_slug), level-matched to the old whoosh
	"layers": [{"s": "evt_pass_by_slug", "d": 0.0, "g": 1.322, "r": 1.0, "pj": null}],
}
const LEGACY_TAIL_CUES := ["hit_heavy", "shield_break"]
const LEGACY_PITCH_CUES := ["death_powerdown", "death_vent", "death_crack", "death_run", "chunk_cool", "hulk_vent"]


func _ready() -> void:
	if silent:
		set_process(false)
		return
	_buses()
	var catalog: Array = _catalogs.get(only, [])
	if catalog.is_empty():
		catalog = _load_catalog(only)
		_catalogs[only] = catalog
	cues = catalog[0]
	clips = catalog[1]
	synth = catalog[2]
	set_volume(vol)


static func _load_catalog(prefix: String) -> Array:
	var t0 := Time.get_ticks_msec()
	if _cue_data.is_empty():
		_cue_data = _read_catalog_json("res://audio/cues.json")
		_cue_data["shot_pass_by"] = PASS_BY_CUE
		_clip_index = _read_catalog_json("res://audio/clips/index.json")
	var catalog_cues := _cue_data.duplicate()
	var catalog_clips := {}
	var catalog_synth := {}
	var want := {}
	if prefix != "":
		for k in _cue_data:
			if not str(k).begins_with(prefix):
				catalog_cues.erase(k)
				continue
			for L in _cue_data[k]["layers"]:
				if L.has("s"):
					want[L["s"]] = true
	for k in _clip_index:
		if prefix != "" and not want.has(k):
			continue
		var a := _load_takes("res://audio/clips/", _clip_index[k])
		if not a.is_empty():
			catalog_clips[k] = a
	for k in catalog_cues:
		var cue: Dictionary = catalog_cues[k]
		catalog_synth[k] = _load_takes("res://audio/synth/", cue["synth"])
		for variant in cue.get("variants", {}):
			catalog_synth[k + ":" + variant] = _load_takes("res://audio/synth/", cue["variants"][variant].get("synth", []))
	for catalog in [catalog_cues, catalog_clips, catalog_synth]:
		catalog.make_read_only()
	print("[sfx] %d cues, %d clip sets, loaded in %d ms" % [catalog_cues.size(), catalog_clips.size(), Time.get_ticks_msec() - t0])
	return [catalog_cues, catalog_clips, catalog_synth]


static func _read_catalog_json(path: String) -> Dictionary:
	var data = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	return data if data is Dictionary else {}


static func _load_takes(folder: String, files: Array) -> Array:
	var takes: Array = []
	for file in files:
		var stream := _load(folder + file)
		if stream != null:
			takes.append(stream)
	takes.make_read_only()
	return takes


static func _load(p: String) -> AudioStream:
	if not _streams.has(p):
		_streams[p] = _read_stream(p)
	return _streams[p]


static func _read_stream(p: String) -> AudioStream:
	# the imported stream when the project has been imported or exported, else the raw Ogg file
	if HUDRes.imported_ok(p):
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
	# SFX volume must not change or mute the music on Master.
	AudioServer.add_bus(1)
	AudioServer.set_bus_name(1, "music_duck")
	AudioServer.set_bus_send(1, "Master")
	for k in ["sfx", "battle_sfx", "death"]:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, k)
		AudioServer.set_bus_send(i, "sfx" if k in ["battle_sfx", "death"] else "Master")
	var music := AudioServer.get_bus_index("music")
	if music >= 0:
		AudioServer.set_bus_send(music, "music_duck")
	for k in BUSES:
		var i := AudioServer.bus_count
		AudioServer.add_bus(i)
		AudioServer.set_bus_name(i, k)
		AudioServer.set_bus_send(i, "sfx" if k == "ui" else "battle_sfx")
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
	if not is_finite(v):
		return
	vol = clampf(v, 0.0, 1.0)
	if silent:
		return
	var g := 0.62 * pow(vol, 1.6) if on else 0.0
	_base_sfx_db = linear_to_db(maxf(g, 1e-5)) + 2.0
	var i := AudioServer.get_bus_index("sfx")
	if i >= 0:
		AudioServer.set_bus_mute(i, not on or vol <= 0.001)
	_apply_mix()


func set_on(v: bool) -> void:
	on = v
	set_volume(vol)


# Issue 771. The beat, the core-flash duck and the near-silence hold are layers on the same buses, so the
# lowest one wins. The death bus stays out of the beat and the core duck; the near-silence rides the parent
# sfx bus so it takes the death too. All values are dB; zero means no duck.
func _apply_mix() -> void:
	if silent:
		return
	var now := _now()
	if now >= _duck_until:
		_duck_db = 0.0
	if now >= _quiet_until:
		_quiet_db = 0.0
	var beat_db := -6.0 if _beat else 0.0
	var mix := minf(beat_db, _duck_db)
	for b in ["battle_sfx", "music_duck"]:
		var i := AudioServer.get_bus_index(b)
		if i >= 0:
			# The near-silence hold must take the music too; the music bus is not under sfx.
			AudioServer.set_bus_volume_db(i, minf(mix, _quiet_db) if b == "music_duck" else mix)
	var si := AudioServer.get_bus_index("sfx")
	if si >= 0:
		AudioServer.set_bus_volume_db(si, _base_sfx_db + _quiet_db)


func mix_duck(db: float, seconds: float) -> void:
	if legacy or db >= 0.0:
		return
	var now := _now()
	_duck_db = minf(_duck_db, db) if now < _duck_until else db
	_duck_until = maxf(_duck_until, now + seconds)
	_apply_mix()


func quiet(db: float, seconds: float) -> void:
	if legacy or db >= 0.0:
		return
	var now := _now()
	_quiet_db = minf(_quiet_db, db) if now < _quiet_until else db
	_quiet_until = maxf(_quiet_until, now + seconds)
	_apply_mix()


func mix_level() -> float:
	return _duck_db if _now() < _duck_until else 0.0


func _pick(arr: Array, key: String):
	if arr.size() < 2:
		return arr[0]
	var ix := randi() % arr.size()
	if rr.get(key, -1) == ix:
		ix = (ix + 1) % arr.size()
	rr[key] = ix
	return arr[ix]


func _layers(name: String, cue: Dictionary, variant := "") -> Array:
	var out: Array = []
	var sampled := false
	var sl = null
	var base := name.split(":")[0]
	for L in cue["layers"]:
		if L.has("s"):
			var d := float(L["d"])
			if legacy and LEGACY_TAIL_CUES.has(base) and d > 0.02:
				continue
			var pj := float(L["pj"]) if L["pj"] != null else float(cue["spj"])
			if legacy and LEGACY_PITCH_CUES.has(base):
				pj = 0.0
			var a: Array = clips.get(L["s"], [])
			if not a.is_empty():
				out.append({"st": _pick(a, L["s"]), "g": float(L["g"]), "r": float(L["r"]), "d": d, "pj": pj})
				sampled = true
				if L.has("end_rate"):
					out[-1]["end_rate"] = L["end_rate"]
		elif L.has("syn"):
			sl = L
	var sy: Array = synth.get(name, [])
	if not sy.is_empty() and (not sampled or sl != null):
		out.append({"st": _pick(sy, name), "g": float(sl["g"]) if sampled else 1.0, "r": 1.0, "d": 0.0, "pj": 0.0 if legacy else float(cue["pj"])})
	if cue.get("variants", {}).has(variant):
		var vd: Dictionary = cue["variants"][variant]
		var vc: Dictionary = cue.duplicate()
		vc.merge(vd, true)
		vc.erase("variants")
		vc.erase("replace")
		var vl := _layers(name + ":" + variant, vc)
		# Issue 1238 (F5.4): a variant marked "replace" is the faction's whole sound (no steel groan under the glass);
		# otherwise it adds its layers to the base cue. A replace variant with nothing playable falls back to the base.
		if bool(vd.get("replace", false)) and not vl.is_empty():
			return vl
		out.append_array(vl)
	return out


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


# o: {pos: Vector3, gain, rate, delay}
func play(name: String, o := {}) -> void:
	if silent or not on or not cues.has(name):
		return
	var cue: Dictionary = cues[name]
	var variant := str(o.get("variant", ""))
	var lay := _layers(name, cue, variant)
	if lay.is_empty():
		return
	# a faction variant may set its own voice length (its clips differ from the base cue's)
	if variant != "" and not o.has("duration") and cue.get("variants", {}).get(variant, {}).has("duration"):
		o = o.duplicate()
		o["duration"] = float(cue["variants"][variant]["duration"])
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
	# Reserve the stagger now, but enforce voice caps only when it is due.
	# Otherwise later ships steal delayed players before they have ever started.
	var generation := _pending_generation
	var start := t - now
	if start <= 0.01:
		_start(name, o, lay)
	else:
		get_tree().create_timer(start, false, false, true).timeout.connect(_start_pending.bind(generation, name, o, lay))


func _start_pending(generation: int, name: String, o: Dictionary, lay: Array) -> void:
	if generation == _pending_generation:
		_start(name, o, lay)


func _start(name: String, o: Dictionary, lay: Array) -> void:
	if not on or _cancelled_tags.has(o.get("tag", "")):
		return
	var cue: Dictionary = cues[name]
	var now := _now()
	var t := now
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
			if int(active[i].pri) <= pri and (vi < 0 or int(active[i].pri) < int(active[vi].pri)):
				vi = i
		if vi < 0:
			return
		_steal(active[vi])
	var u := randf() * 2.0 - 1.0
	var v := {"name": name, "players": [], "start": t, "end": t, "pri": int(cue["pri"]), "tag": o.get("tag", "")}
	var dur := 0.0
	# A bed sets the whole voice length (issue 771), so a short looped clip can last the death picture.
	var limit := float(o.get("duration", cue.get("duration", 0.0)))
	for L in lay:
		var rate := maxf(0.25, float(o.get("rate", 1.0)) * float(L.r) * (1.0 + u * float(L.pj)))
		var st: AudioStream = L.st
		if bool(cue.get("loop", false)) and st is AudioStreamOggVorbis:
			# Issue 1237 (Neon F7.5): one looping copy per clip, made once, not a new copy on every death bed.
			if not _loop_copies.has(st):
				var dup: AudioStreamOggVorbis = (st as AudioStreamOggVorbis).duplicate()
				dup.loop = true
				_loop_copies[st] = dup
			st = _loop_copies[st]
		var p: Node
		if pos is Vector3:
			var p3 := AudioStreamPlayer3D.new()
			p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
			p3.panning_strength = 0.72
			p3.position = pos
			p3.stream = st
			p3.pitch_scale = rate
			p3.volume_db = linear_to_db(maxf(gain * float(L.g), 1e-5))
			p3.bus = "death" if o.get("death", false) else cue["bus"]
			p = p3
		else:
			var p2 := AudioStreamPlayer.new()
			p2.stream = st
			p2.pitch_scale = rate
			p2.volume_db = linear_to_db(maxf(gain * float(L.g), 1e-5))
			p2.bus = "death" if o.get("death", false) else cue["bus"]
			p = p2
		add_child(p)
		if limit > 0.0:
			var envelope := p.create_tween()
			envelope.tween_interval(maxf(0.0, limit - 0.06))
			envelope.tween_property(p, "volume_db", -80.0, 0.06)
			if L.has("end_rate"):
				p.create_tween().tween_property(p, "pitch_scale", float(L.end_rate), limit)
		var start := t + float(L.d) - now
		if start <= 0.01:
			p.call("play")
		else:
			# Voice caps can free a player before its stagger expires. A weak reference
			# avoids a freed lambda capture, which errors before its body can guard it.
			get_tree().create_timer(start, false, false, true).timeout.connect(_play_pending.bind(weakref(p), v))
		v.players.append(p)
		dur = maxf(dur, float(L.d) + st.get_length() / rate)
	if limit > 0.0:
		dur = limit
	v.end = t + dur + 0.05
	list.append(v)
	by_cue[name] = list
	active.append(v)
	if float(cue["duck"]) > 0.0:
		_ambient_duck = maxf(_ambient_duck, float(cue["duck"]))
		_ambient_duck_until = now + 0.5
	cue_started.emit(name, o)


func _play_pending(player: WeakRef, voice: Dictionary) -> void:
	var p = player.get_ref()
	if is_instance_valid(p) and active.has(voice):
		p.call("play")


func _process(_delta: float) -> void:
	_reap(_now())
	_apply_mix()
	if _now() >= _ambient_duck_until:
		_ambient_duck = 0.0
	var i := AudioServer.get_bus_index("ambient")
	if i >= 0:
		AudioServer.set_bus_volume_db(i, linear_to_db(BUSES["ambient"] * (1.0 - _ambient_duck)))


# R73 hook. The picture owns its clock; audio remains at normal pitch/speed.
func death_beat(enabled: bool) -> void:
	if silent:
		return
	_beat = enabled
	_apply_mix()
	# Music can be created after SFX, so connect its send when the beat is sampled.
	var music := AudioServer.get_bus_index("music")
	if music >= 0:
		AudioServer.set_bus_send(music, "music_duck")


func stop_tag(tag: String) -> void:
	_cancelled_tags[tag] = true
	for v in active.duplicate():
		if v.get("tag") == tag:
			_drop(v)
			for p in v.players:
				if is_instance_valid(p):
					p.stop()
					p.queue_free()


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
	_pending_generation += 1
	last.clear()
	_duck_db = 0.0
	_duck_until = 0.0
	_quiet_db = 0.0
	_quiet_until = 0.0
	death_beat(false)
	_cancelled_tags.clear()   # issue 1237 (Neon F7.5): the battle's cancelled death tags no longer pile up
	for v in active.duplicate():
		_steal(v)


# ---- the game's cue helpers (sfx.js) ----

# Issue 1752 Gate 2: a weapon's own recorded sound is a variant of the cue its family plays, named "faction.weapon_id"
# (or the bare weapon_id for strike craft any faction flies). No such variant: the cue's base sound, as before.
func weapon_variant(name: String, fac: String, wid: String) -> String:
	var vs: Dictionary = cues.get(name, {}).get("variants", {})
	if vs.has(fac + "." + wid):
		return fac + "." + wid
	if wid != "" and vs.has(wid):
		return wid
	return ""


func gun(k: String, sq: bool, style, pos = null, delay := 0.0, fac := "", wid := "") -> void:
	if sq:
		play("gun_sq", {"pos": pos, "delay": delay, "variant": weapon_variant("gun_sq", fac, wid)})
		return
	if k == "flak":
		play("gun_flak", {"pos": pos, "delay": delay, "variant": weapon_variant("gun_flak", fac, wid)})
		return
	if style == "twin":
		play("gun_shell", {"pos": pos, "gain": 0.8, "delay": delay})
		play("gun_shell", {"pos": pos, "gain": 0.6, "delay": delay + 0.05})
		return
	var n := "gun_" + (str(style) if style != null else "shell")
	n = n if cues.has(n) else "gun_shell"
	play(n, {"pos": pos, "delay": delay, "variant": weapon_variant(n, fac, wid)})


# Issue 771: the lance and the torpedo charge briefly before the shot. Guns stay dry.
const CHARGE_LEAD := {"lance_charge": 0.26, "torp_charge": 0.30}


# Issue 1211: with `sched` (a Callable(seconds, Callable), the battle's effect-clock scheduler) the shot cue lands on the
# effect's own fire time fire_at and the charge leads it by its usual lead (from now at the earliest), both on that clock,
# so hit pause and the kill beat delay them with the picture. Without it: the charge now, the shot after the fixed lead.
# Issue 1752: fac and wid pick the weapon's own variant of the shot and the charge; a charge variant may set its own
# "lead" in cues.json (a longer pull-in starts earlier so it still ends on the shot).
func _charge_lead(charge: String, cv: String) -> float:
	return float(cues.get(charge, {}).get("variants", {}).get(cv, {}).get("lead", CHARGE_LEAD.get(charge, 0.0)))


func _charged(shot: String, charge: String, pos, fire_at := -1.0, sched := Callable(), fac := "", wid := "") -> void:
	var has_charge := not legacy and cues.has(charge)
	var sv := weapon_variant(shot, fac, wid)
	var cv := weapon_variant(charge, fac, wid)
	var lead := _charge_lead(charge, cv)
	if fire_at >= 0.0 and sched.is_valid():
		if has_charge:
			sched.call(maxf(fire_at - lead, 0.0), func() -> void: play(charge, {"pos": pos, "variant": cv}))
		sched.call(fire_at, func() -> void: play(shot, {"pos": pos, "variant": sv}))
		return
	if not has_charge:
		play(shot, {"pos": pos, "variant": sv})
		return
	play(charge, {"pos": pos, "variant": cv})
	play(shot, {"pos": pos, "delay": lead, "variant": sv})


func lance(ion: bool, fac: String, pos = null, fire_at := -1.0, sched := Callable(), fires := [], wid := "") -> void:
	var shot := "lance_dark" if fac == "deathless" else "lance_choir" if fac == "ithar" else "lance_ion" if ion else "lance"
	if fires.is_empty():
		_charged(shot, "lance_charge", pos, fire_at, sched, fac, wid)
		return
	# one shot cue per fire time (the null lance), the charge leading the first; on the effect clock when sched is given
	var sv := weapon_variant(shot, fac, wid)
	var cv := weapon_variant("lance_charge", fac, wid)
	var lead := _charge_lead("lance_charge", cv)
	if sched.is_valid():
		if not legacy:
			sched.call(maxf(float(fires.min()) - lead, 0.0), func() -> void: play("lance_charge", {"pos": pos, "variant": cv}))
		for t in fires:
			sched.call(float(t), func() -> void: play(shot, {"pos": pos, "variant": sv}))
		return
	if not legacy:
		play("lance_charge", {"pos": pos, "delay": maxf(float(fires.min()) - lead, 0.0), "variant": cv})
	for t in fires:
		play(shot, {"pos": pos, "delay": float(t), "variant": sv})


# Issue 1752: the Eclipse null cannon's capacitor charge, once per volley, ending on its first shot (its cue's "lead"
# fits the picture's capacitor wind-up in fx_weapons.gd "gauss").
func gauss_charge(pos, fire_at: float, sched := Callable()) -> void:
	if legacy or not cues.has("gauss_charge"):
		return
	var lead := float(cues["gauss_charge"].get("lead", 0.25))
	if sched.is_valid():
		sched.call(maxf(fire_at - lead, 0.0), func() -> void: play("gauss_charge", {"pos": pos}))
	else:
		play("gauss_charge", {"pos": pos, "delay": maxf(fire_at - lead, 0.0)})


func torp(fac: String, pos = null, fire_at := -1.0, sched := Callable(), wid := "") -> void:
	var m := {"corsair": "torp_rocket", "chorus": "torp_sac", "ithar": "torp_star", "voidsworn": "torp_heavy"}
	_charged(m.get(fac, "torp"), "torp_charge", pos, fire_at, sched, fac, wid if wid != "" else "torp")


# The death bed: a looped low rumble held for the whole death picture. Its length comes from the death beats.
func death_bed(seconds: float, pos = null, variant := "") -> void:
	if legacy or seconds <= 0.0:
		return
	play("death_bed", {"pos": pos, "duration": seconds, "death": true, "variant": variant})


func death_tail(pos = null, variant := "") -> void:
	play("death_tail", {"pos": pos, "death": true, "variant": variant})


func hit(pos = null, heavy := false) -> void:
	play("hit_heavy" if heavy else "hit", {"pos": pos})


# The struck material takes priority over the weapon family. Glass and tissue
# retain their contact cue on a critical, with a quieter heavy tail under it.
const HIT_BY_WEAPON := {
	"las": "hit_las", "lance": "hit_las", "plasma": "hit_plasma",
	"rail": "hit_rail", "gauss": "hit_rail", "ion": "hit_ion",
}
const HIT_BY_TARGET := {"chorus": "hit_wet", "ithar": "hit_glass", "deathless": "hit_obsidian"}
const CRIT_BEAT := preload("res://fx/fx_weapons.gd").CRIT_BEAT


# Issue 1752: shooter is the firing ship's faction. A Chorus shot on a metal hull (no target material cue) is acid.
func impact_cue(fam: String, target_fac: String, heavy := false, shooter := "") -> String:
	if HIT_BY_TARGET.has(target_fac):
		return str(HIT_BY_TARGET[target_fac])
	if heavy:
		return "hit_heavy"
	# Issue 1752: a Chorus shot on a metal hull eats in (a critical keeps hit_heavy)
	if shooter == "chorus" and cues.has("hit_acid"):
		return "hit_acid"
	return str(HIT_BY_WEAPON.get(fam, "hit"))


func impact(fam: String, target_fac: String, pos, heavy: bool, sched: Callable, shooter := "") -> void:
	play(impact_cue(fam, target_fac, heavy, shooter), {"pos": pos})
	if heavy and HIT_BY_TARGET.has(target_fac):
		# Issue 1238 (F5.4): the heavy tail under a Chorus or Glasswright hit keeps the target's material (its variant)
		sched.call(CRIT_BEAT, func() -> void: play("hit_heavy", {"pos": pos, "gain": 0.55, "variant": target_fac}))


# Issue 1752: fac is the shielded ship's faction (the Glasswright prismatic barrier has its own break).
func shield(pos = null, big := false, fac := "") -> void:
	play("shield_break" if big else "shield", {"pos": pos, "variant": fac})


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


# the ambient bed as the browser plays it (sfx.js ambient and _ambSample): a low evolving synth bed (rumble, two beating
# drones and a fifth, a breath of air, rendered offline into a seamless 120 s loop) with the recorded room tone over it;
# both fade in over a few seconds and sit on the ambient bus, which explosions duck
func ambient_start() -> void:
	if silent:
		return
	if _bed == null:
		var bs := _load("res://audio/synth/ambient_bed.ogg")
		if bs is AudioStreamOggVorbis:
			var ob := bs.duplicate() as AudioStreamOggVorbis
			ob.loop = true
			ob.loop_offset = 1.0   # the file is [1 s of tail][the 120 s loop][1 s of head]; loop 121 s -> 1 s
			ob.bpm = 60.0
			ob.beat_count = 121
			_bed = AudioStreamPlayer.new()
			_bed.stream = ob
			_bed.bus = "ambient"
			add_child(_bed)
			_bed.volume_db = -60.0
			_bed.play(1.0 + randf() * 119.0)
			create_tween().tween_property(_bed, "volume_db", linear_to_db(BED_GAIN), 4.0)
	if _amb != null or not clips.has("ambient"):
		return
	_amb = AudioStreamPlayer.new()
	var st: AudioStream = clips["ambient"][0]
	if st is AudioStreamOggVorbis:
		st = st.duplicate()
		(st as AudioStreamOggVorbis).loop = true
	_amb.stream = st
	_amb.bus = "ambient"
	add_child(_amb)
	_amb.volume_db = -60.0
	_amb.play(randf() * st.get_length() * 0.5)
	# Issue 1752: the bridge bed (amb_bridge_bed) replaces the room tone; 0.113 matches the old 0.032 tone's level
	create_tween().tween_property(_amb, "volume_db", linear_to_db(0.113), 5.0)
