extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 771: prove the sound weight build on the real cue path (cue, start, length, duck level).
# Deaths get a tail, the sub-bass and a bed for the length of the death picture; the mix ducks under
# the core flash; a capital leaves a beat of near-silence; capital hits and shield breaks get a tail;
# the lance and the torpedo charge briefly before the shot; death cues vary a little in pitch; guns stay dry.
const Sfx := preload("res://audio/sfx.gd")
const DeathAudio := preload("res://audio/death_audio.gd")
const FXDeath := preload("res://fx/fx_death.gd")
var fails: Array = []
var heard: Array = []
var heard_at: Dictionary = {}
var s: Node

class FakeShip extends RefCounted:
	var id := "dead"
	var root := Node3D.new()
	var death_big := true
	var faction := "hegemony"
	var death_tier := "capital"
	var flagship := false

class FakeFX extends Node:
	var now := 0.0
	var ships := {}
	var _death_slow_left := 0.0
	var reduce_flashing := false

func _init() -> void:
	GUARD.arm(self, "sound_weight_check")
	call_deferred("_run")

func _ok(c: bool, message: String) -> void:
	if not c:
		fails.append(message)
		print("  FAIL ", message)

func _voice(name: String) -> Dictionary:
	var a: Array = s.by_cue.get(name, [])
	return a[-1] if not a.is_empty() else {}

# Full scheduled length of the last voice of a cue, in seconds.
func _len(name: String) -> float:
	var v := _voice(name)
	if v.is_empty() or not v.has("start"):
		return -1.0
	return float(v.end) - float(v.start) - 0.05

func _bus_db(name: String) -> float:
	var i := AudioServer.get_bus_index(name)
	return AudioServer.get_bus_volume_db(i) if i >= 0 else 0.0

func _run() -> void:
	s = Sfx.new()
	root.add_child(s)
	await process_frame
	s.cue_started.connect(func(n, _o):
		heard.append(n)
		heard_at[n] = s._now())

	# (6) weapon shots stay dry: no gun cue gains a delayed tail layer.
	var dry := true
	for name in s.cues:
		if not name.begins_with("gun_"):
			continue
		for L in s.cues[name].layers:
			if float(L.get("d", 0.0)) > 0.001:
				dry = false
	_ok(dry, "weapon shots stay dry (no gun cue has a delayed tail layer)")

	# (3) capital hits and shield breaks get a tail: their real scheduled length grows.
	s.stop_all()
	s.last.clear()
	s.play("shield_break")
	await create_timer(0.03).timeout
	var sl := _len("shield_break")
	_ok(sl >= 1.8, "shield break carries a tail (length %.2f s, needs 1.8)" % sl)
	s.stop_all()
	s.last.clear()
	s.play("hit_heavy")
	await create_timer(0.03).timeout
	var hl := _len("hit_heavy")
	_ok(hl >= 2.4, "capital (heavy) hull hit carries a tail (length %.2f s, needs 2.4)" % hl)

	# (5) death cues vary a little in pitch each time, reproducibly under a seed.
	s.stop_all()
	seed(9182)
	var ratios: Array = []
	for i in 10:
		s.stop_all()
		s.play("death_crack")
		await create_timer(0.012).timeout
		var v := _voice("death_crack")
		if not v.is_empty() and not v.players.is_empty() and is_instance_valid(v.players[0]):
			ratios.append(float(v.players[0].pitch_scale) / float(s.cues["death_crack"]["layers"][0]["r"]))
	var distinct := {}
	var lo := 9.0
	var hi := 0.0
	for r in ratios:
		distinct[snappedf(r, 0.0005)] = true
		lo = minf(lo, float(r))
		hi = maxf(hi, float(r))
	_ok(distinct.size() >= 4, "death cue pitch varies each time (distinct %d of %d starts)" % [distinct.size(), ratios.size()])
	_ok(hi - lo <= 0.06, "death cue pitch variation stays small (spread %.3f)" % (hi - lo))

	# (4) the lance and the torpedo charge briefly before the shot.
	await _charge_check("lance_charge", "lance", func(): s.lance(false, "hegemony"))
	await _charge_check("torp_charge", "torp", func(): s.torp("hegemony"))

	# (1) and (2): the real observer on a capital death.
	var fx := FakeFX.new()
	root.add_child(fx)
	var d := DeathAudio.new()
	d.sfx = s
	d.fx = fx
	d.set_process(false)
	root.add_child(d)
	var ship := FakeShip.new()
	ship.flagship = true
	ship.death_tier = "capital"
	fx.ships[ship.id] = ship
	var tl = FXDeath.DeathTimeline.new(true, 2, "capital", "blast")
	ship.set_meta("death_timeline", tl)
	ship.set_meta("death_start", 0.0)
	s.stop_all()
	heard.clear()
	seed(5)
	d.watch(ship.id, Vector3.ZERO)
	await create_timer(0.04).timeout
	var want := float(tl.cut) + float(tl.cool)
	var bl := _len("death_bed")
	_ok(not _voice("death_bed").is_empty(), "a capital death starts a bed")
	_ok(absf(bl - want) <= 0.2, "the bed lasts the death picture (%.2f s, picture %.2f s)" % [bl, want])
	var bass_clip := false
	for L in s.cues.get("bass_drop", {}).get("layers", []):
		if str(L.get("s", "")) == "death_bass_drop":
			bass_clip = true
	_ok(bass_clip, "the sub-bass uses the approved Wave F bass drop")
	ship.set_meta("death_hidden", true)
	fx.now = float(tl.cut)
	d._process(0.0)
	await create_timer(0.03).timeout
	_ok(heard.has("boom_l"), "a capital death breaks with boom_l")
	fx.now = float(tl.cut) + float(tl.core_delay)
	d._process(0.0)
	await create_timer(0.03).timeout
	_ok(heard.has("bass_drop"), "the sub-bass lands with the core flash")
	var duck := _bus_db("battle_sfx")
	var death_db := _bus_db("death")
	_ok(duck <= -6.0, "the rest of the mix ducks under the core flash (%.1f dB)" % duck)
	_ok(is_zero_approx(death_db), "the death itself is not ducked under the core flash (%.1f dB)" % death_db)
	fx.now = float(tl.cut) + 0.4
	d._process(0.0)
	await create_timer(0.03).timeout
	_ok(heard.has("death_tail"), "the death tail starts after the break")
	fx.now = float(tl.cut) + float(tl.core_delay) + 0.95
	d._process(0.0)
	await create_timer(0.03).timeout
	_ok(_bus_db("sfx") <= -20.0, "a capital death leaves a beat of near-silence (sfx %.1f dB)" % _bus_db("sfx"))

	# A cruiser gets the bed but no quiet beat (only a capital or flagship does).
	s.stop_all()
	heard.clear()
	var ship2 := FakeShip.new()
	ship2.death_tier = "cruiser"
	ship2.id = "dead2"
	ship2.set_meta("death_timeline", FXDeath.DeathTimeline.new(true, 1, "cruiser", "blast"))
	ship2.set_meta("death_start", 0.0)
	fx.ships[ship2.id] = ship2
	var tl2 = ship2.get_meta("death_timeline")
	d.watch(ship2.id, Vector3.ZERO)
	await create_timer(0.04).timeout
	var bl2 := _len("death_bed")
	var want2 := float(tl2.cut) + float(tl2.cool)
	_ok(absf(bl2 - want2) <= 0.2, "a cruiser bed lasts its death picture (%.2f s, picture %.2f s)" % [bl2, want2])
	ship2.set_meta("death_hidden", true)
	fx.now = float(tl2.cut) + float(tl2.core_delay) + 0.95
	d._process(0.0)
	await create_timer(0.03).timeout
	_ok(_bus_db("sfx") > -20.0, "a cruiser death leaves no near-silence beat (sfx %.1f dB)" % _bus_db("sfx"))

	# Let the playback objects go before shutdown.
	s.stop_all()
	ship.root.free()
	ship2.root.free()
	d.free()
	fx.free()
	s.free()
	await create_timer(0.15).timeout
	print("SOUND WEIGHT CHECK ", "PASS" if fails.is_empty() else "FAIL (%d)" % fails.size())
	quit(0 if fails.is_empty() else 1)

# The charge cue starts first, then the shot after a short lead.
func _charge_check(charge: String, shot: String, fire: Callable) -> void:
	s.stop_all()
	heard.clear()
	heard_at.clear()
	fire.call()
	await create_timer(0.06).timeout
	_ok(heard.has(charge), shot + " starts a short charge cue")
	_ok(not heard.has(shot), shot + " shot waits for its charge")
	await create_timer(0.4).timeout
	_ok(heard.has(shot), shot + " shot follows its charge")
	if heard_at.has(charge) and heard_at.has(shot):
		var lead := float(heard_at[shot]) - float(heard_at[charge])
		_ok(lead >= 0.15, "%s charge leads the shot by %.2f s" % [shot, lead])
	else:
		_ok(false, shot + " charge and shot both have a real start time")
