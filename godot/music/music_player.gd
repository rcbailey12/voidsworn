extends Node
# Adaptive music for Voidsworn (owner: music and portraits helper; R37 direction, R40 free licensed tracks).
# Brass and tactical percussion in battle, a synth drone on the map, organ and machine sounds only as faction flavour.
#
# How G2 uses it (one node for the whole game, e.g. a child of Main):
#   var music = preload("res://music/music_player.gd").new(); add_child(music)
#   music.set_volume(settings.music_volume); music.set_on(settings.music)    # settings screen hooks
#   music.play_title()                                # title screen
#   music.play_map(sector)                            # campaign map (sector 1..3)
#   music.play_battle(player_fac, enemy_fac)          # battle start: calm layer, intense layer muted, faction flavour
#   music.set_intensity(x)                            # 0..1, any time in battle (or music.feed(stats) once per activation)
#   music.victory() / music.defeat()                  # stings; the battle layers fade out under them
#   music.stop(2.0)
# Everything is data in music.json (tracks, gains, which faction gets which flavour); tracks live in godot/music/tracks/.
# Missing files are skipped quietly, so the game runs with no music at all.

signal sting_finished(kind: String)

const MANIFEST := "res://music/music.json"
const BUS := "music"
const SMOOTH := 1.6          # seconds, time constant of the intensity follower
const FADE_IN := 2.5
const XFADE := 3.0           # seconds for a map or title change
const LO := 0.38             # intensity band where the calm layer hands over to the intense one
const HI := 0.62

var man := {}
var vol := 0.7
var on := true
var intensity := 0.0         # target, set by the game
var _ival := 0.0             # smoothed
var _streams := {}           # track id -> AudioStream (cache)
var _mode := ""              # "", title, map, battle, sting
var _single: AudioStreamPlayer      # title / map loop (current)
var _old: Array = []                # players fading out: [{p, from, t, dur}]
var _calm: AudioStreamPlayer
var _hot: AudioStreamPlayer
var _bed: AudioStreamPlayer
var _sting: AudioStreamPlayer
var _bed_db := -14.0
var _battle_gain := 0.0             # 0..1 master fade for the battle group
var _battle_target := 0.0
var _single_gain := 0.0
var _single_target := 0.0
var _single_db := 0.0
var _calm_db := 0.0
var _hot_db := 0.0
var _after_sting := ""
var _boss := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "Music"
	process_mode = Node.PROCESS_MODE_ALWAYS     # keeps playing under a paused menu
	_rng.randomize()
	_bus()
	if FileAccess.file_exists(MANIFEST):
		var m = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		if m is Dictionary:
			man = m
	_calm = _player()
	_hot = _player()
	_bed = _player()
	_sting = _player()
	_sting.finished.connect(_on_sting_done)
	set_volume(vol)


func _bus() -> void:
	if AudioServer.get_bus_index(BUS) >= 0:
		return
	var i := AudioServer.bus_count
	AudioServer.add_bus(i)
	AudioServer.set_bus_name(i, BUS)
	AudioServer.set_bus_send(i, "Master")


func _player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = BUS
	p.volume_db = -80.0
	add_child(p)
	return p


# ---------- settings ----------

func set_volume(v: float) -> void:
	vol = clampf(v, 0.0, 1.0)
	_apply_bus()


func set_on(v: bool) -> void:
	on = v
	_apply_bus()


func _apply_bus() -> void:
	var i := AudioServer.get_bus_index(BUS)
	if i < 0:
		return
	var g := pow(vol, 1.6) if on else 0.0
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(g, 1e-5)))
	AudioServer.set_bus_mute(i, not on or vol <= 0.001)


# ---------- tracks ----------

func _track(id: String) -> Dictionary:
	var all: Dictionary = man.get("tracks", {})
	var t = all.get(id, {})
	return t if t is Dictionary else {}


func _stream(id: String, loop: bool) -> AudioStream:
	if id == "":
		return null
	if _streams.has(id):
		return _streams[id]
	var t := _track(id)
	if t.is_empty():
		return null
	var p := "res://music/tracks/" + String(t.get("file", ""))
	var s: AudioStream = null
	if _imported_ok(p):
		var r = load(p)
		if r is AudioStream:
			s = r
	if s == null and FileAccess.file_exists(p):
		s = AudioStreamOggVorbis.load_from_file(p)
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = loop
		(s as AudioStreamOggVorbis).loop_offset = float(t.get("loop_from", 0.0))
	_streams[id] = s
	return s


static func _imported_ok(p: String) -> bool:
	var ip := p + ".import"
	if not FileAccess.file_exists(ip):
		return false
	for line in FileAccess.get_file_as_string(ip).split("\n"):
		if line.begins_with("path=") or line.begins_with("path."):
			var q := line.substr(line.find("\"") + 1)
			q = q.substr(0, q.find("\""))
			return q != "" and FileAccess.file_exists(q)
	return false


func _gain(id: String) -> float:
	return float(_track(id).get("gain_db", 0.0))


func _pick(key) -> String:
	# a manifest slot is a track id or a list of ids (one is picked at random)
	if key is Array:
		var a: Array = key
		return String(a[_rng.randi() % a.size()]) if not a.is_empty() else ""
	return String(key) if key != null else ""


func _slot(path: Array) -> String:
	var v = man
	for k in path:
		if not (v is Dictionary) or not v.has(k):
			return ""
		v = v[k]
	return _pick(v)


# ---------- title and map ----------

func play_title() -> void:
	_play_single(_slot(["title"]), "title")


func play_map(sector := 1) -> void:
	var id := _slot(["map", str(sector)])
	if id == "":
		id = _slot(["map", "default"])
	_play_single(id, "map")


func _play_single(id: String, mode: String) -> void:
	if _single != null and _single.playing and _single.get_meta("id", "") == id:
		_mode = mode
		_single_target = 1.0
		_battle_target = 0.0
		return
	_fade_out_single(XFADE)
	_battle_target = 0.0
	_mode = mode
	var s := _stream(id, true)
	if s == null:
		return
	_single = _player()
	_single.stream = s
	_single.set_meta("id", id)
	_single_db = _gain(id)
	_single_gain = 0.0
	_single_target = 1.0
	_single.play()


func _fade_out_single(dur: float) -> void:
	if _single != null:
		_old.append({"p": _single, "from": _single.volume_db, "t": 0.0, "dur": dur})
		_single = null


# ---------- battle ----------

func play_battle(player_fac := "", enemy_fac := "", boss := false) -> void:
	_fade_out_single(FADE_IN)
	_mode = "battle"
	intensity = 0.0
	_ival = 0.0
	# faction flavour: the enemy's colour wins (you hear who you are fighting); your own faction is the fallback
	var fl := _flavour(enemy_fac)
	if fl.is_empty():
		fl = _flavour(player_fac)
	var calm_id := _pick(fl.get("calm")) if fl.has("calm") else ""
	if calm_id == "":
		calm_id = _slot(["battle", "calm"])
	var hot_id := _pick(fl.get("intense")) if fl.has("intense") else ""
	if hot_id == "":
		hot_id = _slot(["battle", "intense"])
	if boss and _slot(["battle", "boss"]) != "":
		hot_id = _slot(["battle", "boss"])      # sector flagship and finale fights: the boss theme is the intense layer
	_boss = boss
	var bed_id := _pick(fl.get("bed")) if fl.has("bed") else ""
	_bed_db = float(fl.get("bed_db", -14.0))
	_start(_calm, calm_id)
	_start(_hot, hot_id)
	_start(_bed, bed_id)
	_calm_db = _gain(calm_id)
	_hot_db = _gain(hot_id)
	_bed_db += _gain(bed_id)
	_battle_gain = 0.0
	_battle_target = 1.0


func _flavour(fac: String) -> Dictionary:
	if fac == "":
		return {}
	var all: Dictionary = man.get("factions", {})
	var f = all.get(fac, {})
	return f if f is Dictionary else {}


func _start(p: AudioStreamPlayer, id: String) -> void:
	p.stop()
	p.stream = _stream(id, true)
	p.volume_db = -80.0
	if p.stream != null:
		p.play()


func set_intensity(x: float) -> void:
	intensity = clampf(x, 0.0, 1.0)


# One call per activation or round with whatever the battle knows; returns the intensity it set.
# d keys (all optional): mine, enemy (ships alive), mine0, enemy0 (ships at start), hull (your fleet hull left, 0..1),
# flagship (your flagship hull left, 0..1), shots (hits this round), close (enemy ships within 3 hexes of yours), boss (bool)
func feed(d: Dictionary) -> float:
	var x := 0.15
	var close := float(d.get("close", 0))
	x += minf(close / 6.0, 1.0) * 0.35                               # contact
	x += minf(float(d.get("shots", 0)) / 12.0, 1.0) * 0.2            # exchange of fire
	var hull := float(d.get("hull", 1.0))
	x += (1.0 - clampf(hull, 0.0, 1.0)) * 0.25                       # damage taken
	if float(d.get("flagship", 1.0)) < 0.5:
		x += 0.15                                                    # flagship in danger
	if bool(d.get("boss", false)):
		x += 0.15
	var mine := float(d.get("mine", 1))
	var enemy := float(d.get("enemy", 1))
	if enemy <= 0.0 or mine <= 0.0:
		x = 0.3                                                      # battle is ending, ease off before the sting
	set_intensity(x)
	return intensity


# ---------- stings ----------

func victory(boss := false) -> void:
	# a boss win (or any win in a battle started with boss = true) gets the champion fanfare when one is listed
	# (sting_finished still reports "victory")
	_sting_play("victory", "victory_boss" if (boss or _boss) and _slot(["stings", "victory_boss"]) != "" else "victory")


func defeat() -> void:
	_sting_play("defeat")


func _sting_play(kind: String, slot := "") -> void:
	_battle_target = 0.0
	_fade_out_single(1.2)
	_mode = "sting"
	var id := _slot(["stings", slot if slot != "" else kind])
	var s := _stream(id, false)
	if s == null:
		sting_finished.emit(kind)
		return
	_sting.stop()
	_sting.stream = s
	_sting.volume_db = _gain(id)
	_sting.set_meta("kind", kind)
	_sting.play()


func _on_sting_done() -> void:
	sting_finished.emit(String(_sting.get_meta("kind", "")))


func stop(dur := 2.0) -> void:
	_fade_out_single(dur)
	_battle_target = 0.0
	_mode = ""


# ---------- per frame: volumes ----------

func _process(dt: float) -> void:
	# intensity follower: rises faster than it falls, so a burst of fire lands quickly and the calm returns slowly
	var k := dt / (SMOOTH if intensity > _ival else SMOOTH * 2.5)
	_ival += (intensity - _ival) * clampf(k, 0.0, 1.0)
	_battle_gain = _approach(_battle_gain, _battle_target, dt / FADE_IN)
	var hot := smoothstep(LO, HI, _ival)
	var calm := 1.0 - 0.85 * hot                       # the calm layer never drops fully: it keeps the pulse under the brass
	_calm.volume_db = _db(calm * _battle_gain) + _calm_db
	_hot.volume_db = _db(hot * _battle_gain) + _hot_db
	_bed.volume_db = _db(_battle_gain * (1.0 - 0.4 * hot)) + _bed_db
	if _battle_gain <= 0.0 and _battle_target <= 0.0:
		for p in [_calm, _hot, _bed]:
			if p.playing:
				p.stop()
	_single_gain = _approach(_single_gain, _single_target, dt / XFADE)
	if _single != null:
		_single.volume_db = _db(_single_gain) + _single_db
	for i in range(_old.size() - 1, -1, -1):
		var o: Dictionary = _old[i]
		o["t"] = float(o["t"]) + dt
		var f := 1.0 - clampf(float(o["t"]) / float(o["dur"]), 0.0, 1.0)
		var p: AudioStreamPlayer = o["p"]
		p.volume_db = float(o["from"]) + _db(f)
		if f <= 0.0:
			p.queue_free()
			_old.remove_at(i)


static func _approach(v: float, target: float, step: float) -> float:
	return minf(v + step, target) if v < target else maxf(v - step, target)


static func _db(g: float) -> float:
	return linear_to_db(maxf(g, 1e-4)) if g > 1e-4 else -80.0


# for tests and the settings screen
func state() -> Dictionary:
	return {"mode": _mode, "intensity": intensity, "smoothed": _ival, "calm_db": _calm.volume_db, "hot_db": _hot.volume_db,
		"bed_db": _bed.volume_db, "single": _single.get_meta("id", "") if _single != null else "", "tracks": (man.get("tracks", {}) as Dictionary).size()}
