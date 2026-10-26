extends SceneTree
# Headless check of the music player and its tracks (PC):
#   godot --headless --path godot --script res://music/test/music_check.gd
# Loads music.json, opens every track, then walks title -> map -> battle (intensity ramp up and down) -> victory,
# checking the layer volumes move the right way. Prints MUSIC CHECK PASS or FAIL with the reasons.

const Player := preload("res://music/music_player.gd")

var fails: Array = []


func _init() -> void:
	call_deferred("_run")


func _ok(c: bool, msg: String) -> void:
	if not c:
		fails.append(msg)
		print("  FAIL ", msg)


func _step(m: Node, secs: float) -> void:
	var t := 0.0
	while t < secs:
		m.call("_process", 0.05)
		t += 0.05


func _run() -> void:
	var m: Node = Player.new()
	root.add_child(m)
	await process_frame
	var man: Dictionary = m.get("man")
	var tracks: Dictionary = man.get("tracks", {})
	_ok(tracks.size() > 0, "music.json has no tracks")
	var total := 0
	for id in tracks:
		var t: Dictionary = tracks[id]
		var p := "res://music/tracks/" + String(t.get("file", ""))
		_ok(FileAccess.file_exists(p), "missing file " + p)
		var s = m.call("_stream", id, true)
		_ok(s != null, "cannot open " + id)
		if s is AudioStream:
			var len := (s as AudioStream).get_length()
			_ok(len > 1.0, "%s is only %.1f s" % [id, len])
			print("  %-22s %6.1f s  %s" % [id, len, t.get("file", "")])
		if FileAccess.file_exists(p):
			total += FileAccess.get_file_as_bytes(p).size()
	print("  total music %.1f MB" % (total / 1048576.0))
	_ok(total < 150 * 1048576, "music over 150 MB")
	m.call("play_title")
	_step(m, 4.0)
	_ok(String(m.call("state")["mode"]) == "title", "title mode")
	m.call("play_map", 1)
	_step(m, 4.0)
	var st: Dictionary = m.call("state")
	_ok(st["mode"] == "map" and st["single"] != "", "map loop playing")
	for fac in ["", "voidsworn", "hegemony", "corsair", "chorus", "ithar", "deathless"]:
		m.call("play_battle", "voidsworn", fac)
		_step(m, 3.0)
		var a: Dictionary = m.call("state")
		_ok(float(a["calm_db"]) > -20.0, "calm layer audible at battle start (%s): %.1f dB" % [fac, a["calm_db"]])
		_ok(float(a["hot_db"]) < -30.0, "intense layer quiet at battle start (%s): %.1f dB" % [fac, a["hot_db"]])
		m.call("feed", {"close": 6, "shots": 14, "hull": 0.5, "flagship": 0.4, "mine": 5, "enemy": 6})
		_step(m, 8.0)
		var b: Dictionary = m.call("state")
		_ok(float(b["hot_db"]) > -12.0, "intense layer up under heavy fire (%s): %.1f dB" % [fac, b["hot_db"]])
		_ok(float(b["calm_db"]) < float(a["calm_db"]), "calm layer down under heavy fire (%s)" % fac)
		m.call("set_intensity", 0.0)
		_step(m, 25.0)
		var c: Dictionary = m.call("state")
		_ok(float(c["hot_db"]) < -30.0, "intense layer back down when quiet (%s): %.1f dB" % [fac, c["hot_db"]])
	m.call("victory")
	_step(m, 3.0)
	_ok(String(m.call("state")["mode"]) == "sting", "victory sting")
	# boss fight: the boss theme is the intense layer, and a boss win plays the champion sting
	var boss_id := String(man.get("battle", {}).get("boss", ""))
	m.call("play_battle", "voidsworn", "hegemony", true)
	_step(m, 3.0)
	if boss_id != "":
		var hot: AudioStreamPlayer = m.get("_hot")
		_ok(hot.stream == m.call("_stream", boss_id, true), "boss battle uses the boss theme as the intense layer")
	m.call("feed", {"close": 6, "shots": 14, "hull": 0.5, "flagship": 0.4, "mine": 5, "enemy": 6, "boss": true})
	_step(m, 8.0)
	_ok(float(m.call("state")["hot_db"]) > -12.0, "boss intense layer up under heavy fire")
	m.call("victory")
	_step(m, 1.0)
	var vb := String(man.get("stings", {}).get("victory_boss", ""))
	if vb != "":
		var sp: AudioStreamPlayer = m.get("_sting")
		_ok(sp.stream == m.call("_stream", vb, false), "boss victory plays the champion sting")
	m.call("play_map", 2)
	_step(m, 4.0)
	_ok(String(m.call("state")["mode"]) == "map", "back to the map after a sting")
	m.call("set_volume", 0.0)
	_ok(AudioServer.is_bus_mute(AudioServer.get_bus_index("music")), "volume 0 mutes the music bus")
	m.call("set_volume", 0.7)
	m.call("set_on", false)
	_ok(AudioServer.is_bus_mute(AudioServer.get_bus_index("music")), "music off mutes the bus")
	m.free()
	print("MUSIC CHECK ", "PASS" if fails.is_empty() else "FAIL (%d)" % fails.size())
	quit(0 if fails.is_empty() else 1)
