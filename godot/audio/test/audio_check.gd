extends SceneTree
# Data, real player starts, variants, and independent SFX/music mute.
const Sfx := preload("res://audio/sfx.gd")
const Music := preload("res://music/music_player.gd")
const DeathAudio := preload("res://audio/death_audio.gd")
const API := preload("res://rules/battle_api.gd")
var fails: Array = []
var heard: Array = []

class QuietBattle extends "res://scenes/battle/battle.gd":
	func _ready() -> void:
		pass
	func wait(_ms: float) -> void:
		pass
	func _flash(_p: Vector3, _size: float, _col: Color, _dur := 0.35, _delay := 0.0, _light := true) -> void:
		pass
	func _log(_m: String, _c: String) -> void:
		pass

class FakeShip extends RefCounted:
	var id := "test"
	var root := Node3D.new()
	var death_big := true
	var faction := "ithar"

class FakeFX extends Node:
	var now := 0.0
	var ships := {}
	var _death_slow_left := 0.0
	var reduce_flashing := false

func _init() -> void:
	call_deferred("_run")

func _ok(c: bool, message: String) -> void:
	if not c:
		fails.append(message)
		print("  FAIL ", message)

func _run() -> void:
	# Parsing battle.gd also checks the semantic dispatch integration.
	_ok(load("res://scenes/battle/battle.gd") != null, "battle script compiles")
	var m := Music.new()
	root.add_child(m)
	var s := Sfx.new()
	root.add_child(s)
	await process_frame
	s.cue_started.connect(func(n, _o): heard.append(n))
	var battle := QuietBattle.new()
	battle.sfx = s
	battle.VU = {"p": {"fac": "chorus", "side": "player", "name": "player"}, "e": {"fac": "hegemony", "side": "enemy", "name": "enemy"}}
	# Use the real branches, with the visual methods stubbed for headless testing.
	await battle._play_event({"t": "order", "order": "brace", "unit": "p"})
	await battle._play_event({"t": "order", "order": "brace", "unit": "e"})
	await battle._play_event({"t": "board", "unit": "p", "target": "e", "result": "repel", "kill": 0, "loss": 0})
	await battle._play_event({"t": "board", "unit": "e", "target": "p", "result": "repel", "kill": 0, "loss": 0})
	await battle._play_event({"t": "adaptation", "source": "nemesis"})
	await battle._play_event({"t": "adaptation", "source": "carrier_report"})
	await create_timer(0.3).timeout
	_ok(heard.count("brace_lock") == 2, "brace dispatches for both sides")
	_ok(heard.count("board_grapple") == 2, "boarding dispatches for both sides")
	_ok(heard.count("adapt_shift") == 1, "adaptation dispatches once per battle")
	battle.free()
	var api := API.new()
	_ok(api.load_rules() == "", "rules data loads")
	for scenario in ["s7", "s29"]:
		api.new_battle_scenario(scenario)
		var events: Array = api.take_events()
		_ok(events.any(func(e): return e.t == "adaptation"), scenario + " emits a semantic adaptation report")
	s.stop_all()
	heard.clear()
	_ok(s.cues.size() == 67, "57 existing cues plus 10 new ids (ui_plan is an override)")
	for name in s.cues:
		var c: Dictionary = s.cues[name]
		_ok(AudioServer.get_bus_index(c.bus) >= 0, name + " bus exists")
		_ok(not s._layers(name, c).is_empty(), name + " has playable layers")
		for f in c.synth:
			_ok(FileAccess.file_exists("res://audio/synth/" + f), name + " synth exists: " + f)
		for variant in c.get("variants", {}):
			var vc: Dictionary = c.variants[variant]
			for f in vc.get("synth", []):
				_ok(FileAccess.file_exists("res://audio/synth/" + f), name + " variant synth exists")
			_ok(s._layers(name, c, variant).size() > s._layers(name, c).size(), name + " adds its variant")
		for l in c.layers:
			if l.has("s"):
				_ok(s.clips.has(l.s), name + " clip exists: " + l.s)
	var mi := AudioServer.get_bus_index("music")
	var si := AudioServer.get_bus_index("sfx")
	m.set_volume(0.7)
	s.set_volume(0.0)
	_ok(AudioServer.is_bus_mute(si), "zero truly mutes SFX")
	_ok(not AudioServer.is_bus_mute(mi) and not AudioServer.is_bus_mute(0), "SFX mute leaves music and Master alone")
	s.set_volume(0.8)
	_ok(not AudioServer.is_bus_mute(si), "raising volume unmutes")
	s.set_on(false)
	_ok(AudioServer.is_bus_mute(si), "sound off mutes")
	s.set_on(true)
	s.set_volume(NAN)
	_ok(is_finite(AudioServer.get_bus_volume_db(si)), "NaN volume cannot poison bus")
	s.death_beat(true)
	_ok(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("battle_sfx")), -6.0), "R73 ordinary cues dip 6 dB")
	_ok(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("music_duck")), -6.0), "R73 music dips 6 dB")
	_ok(is_zero_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("death"))), "death stages exempt from beat dip")
	s.death_beat(false)
	_ok(is_zero_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("music_duck"))), "beat restores music")

	# Exercise the real observer with controlled FX results, including a late split.
	var fx := FakeFX.new()
	root.add_child(fx)
	var d := DeathAudio.new()
	d.sfx = s
	d.fx = fx
	d.set_process(false)
	root.add_child(d)
	var ship := FakeShip.new()
	fx.ships[ship.id] = ship
	ship.set_meta("death_start", 0.0)
	d.watch(ship.id, Vector3.ZERO)
	fx.now = 0.25
	d._process(0.0)
	fx.now = 0.4
	d._process(0.0)
	await create_timer(0.02).timeout
	_ok(heard.has("death_powerdown") and heard.has("death_vent") and heard.has("death_crack"), "three capital stages start")
	fx.now = 1.6
	fx._death_slow_left = 0.4
	d._process(0.0)
	_ok(not heard.has("boom_l"), "late fracture never booms before actual split")
	ship.set_meta("death_hidden", true)
	d._process(0.0)
	fx.now = 1.9
	d._process(0.0)
	_ok(not heard.has("bass_drop"), "bass waits for slow motion release")
	fx._death_slow_left = 0.0
	d._process(0.0)
	fx.now = 2.31
	d._process(0.0)
	await create_timer(0.02).timeout
	for n in ["boom_l", "bass_drop", "wreck"]:
		_ok(heard.count(n) == 1, n + " starts once")
	s.stop_all()
	heard.clear()
	ship.remove_meta("death_hidden")
	ship.set_meta("death_hulk", true)
	d.watch(ship.id, Vector3.ZERO)
	await create_timer(0.02).timeout
	_ok(heard == ["hulk_vent"], "hulk gets no boom, bass or run")
	s.stop_all()
	heard.clear()
	ship.set_meta("death_hulk", false)
	ship.death_big = false
	ship.set_meta("death_start", fx.now)
	d.watch(ship.id, Vector3.ZERO)
	await create_timer(0.02).timeout
	ship.set_meta("death_hidden", true)
	d._process(0.0)
	await create_timer(0.2).timeout
	_ok(heard == ["death_run", "boom_s", "chunk_cool"], "small run, burst, cooling sequence")
	_ok(s.by_cue.get("death_run", []).is_empty(), "run stops dead at burst")
	s.stop_all()
	heard.clear()
	ship.death_big = true
	fx.reduce_flashing = true
	ship.remove_meta("death_hidden")
	ship.set_meta("death_start", fx.now)
	d.watch(ship.id, Vector3.ZERO)
	ship.set_meta("death_hidden", true)
	d._process(0.0)
	fx.now += 0.3
	d._process(0.0)
	await create_timer(0.02).timeout
	_ok(not heard.has("bass_drop"), "reduce flashing skips the core sting")
	ship.root.free()
	d.free()
	fx.free()
	s.free()
	m.free()
	# Let the audio server release the playback objects before shutdown.
	await create_timer(0.15).timeout
	print("AUDIO CHECK ", "PASS" if fails.is_empty() else "FAIL (%d)" % fails.size())
	quit(0 if fails.is_empty() else 1)
