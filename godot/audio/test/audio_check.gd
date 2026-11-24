extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Data, real player starts, variants, and independent SFX/music mute.
const Sfx := preload("res://audio/sfx.gd")
const Music := preload("res://music/music_player.gd")
const DeathAudio := preload("res://audio/death_audio.gd")
const API := preload("res://rules/battle_api.gd")
const Kit := preload("res://ui/theme/orders_kit.gd")
const Campaign := preload("res://campaign/campaign.gd")
const CampaignUI := preload("res://ui/campaign/campaign_ui.gd")
const ChoiceScript := preload("res://ui/campaign/choice_button.gd")
const StoryScript := preload("res://story/story.gd")
const Career := preload("res://story/career.gd")
const JSM := preload("res://rules/jsm.gd")
const PlayerPath := preload("res://main/player_path.gd")
# RULEBOOK 8.4 and the sound playbook: count cues by family, never by one exact table total. Each family below lists the
# takes it has now and is a floor: adding a cue to a family passes, removing one fails. A new cue id with no family fails.
const CUE_FAMILIES := {
	"guns": ["gun_shell", "gun_flak", "gun_sq", "gun_las", "gun_plasma", "gun_tracer", "gun_spine", "gun_needle", "gun_rail", "gun_glob"],
	"weapon_tails": ["salvo_tail", "shot_pass_by"],
	"lances": ["lance", "lance_ion", "lance_dark", "lance_choir"],
	"torpedoes": ["torp", "torp_rocket", "torp_sac", "torp_star", "torp_heavy"],
	"charges": ["lance_charge", "torp_charge", "gauss_charge"],
	"hits": ["hit", "hit_heavy", "hit_las", "hit_plasma", "hit_rail", "hit_wet", "hit_glass", "hit_ion", "hit_obsidian", "hit_acid"],
	"shields": ["shield", "shield_break", "shield_sputter"],
	"patterns": ["patter_hull", "patter_shield"],
	"explosions": ["pop", "boom_s", "boom_m", "boom_l"],
	"ship": ["phase", "launch", "engine", "cough", "puff", "charge", "acid_sizzle"],
	"ui": ["ui_click", "ui_confirm", "ui_cancel", "ui_round", "ui_your", "ui_enemy", "ui_select", "ui_panel", "ui_reward", "ui_alert", "ui_boss"],
	"stings": ["sting_win", "sting_loss"],
	"fleet": ["arrive_jump"],
	"death": ["death_powerdown", "death_vent", "death_crack", "death_run", "chunk_cool", "hulk_vent", "bass_drop", "wreck", "death_bed", "death_tail", "death_magazine"],
	"damage": ["dmg_breach_vent", "dmg_breach_shear", "dmg_turret_knockout", "dmg_engine_fail", "dmg_shield_burnout"],
	"orders": ["board_grapple", "brace_lock", "adapt_shift"],
}
var fails: Array = []
var heard: Array = []

class QuietBattle extends "res://scenes/battle/battle.gd":
	func _ready() -> void:
		pass
	func wait(_ms: float, _skippable_cut := false) -> void:
		pass
	func _flash(_p: Vector3, _size: float, _col: Color, _dur := 0.35, _delay := 0.0, _light := true) -> void:
		pass
	func _log(_m: String, _c: String) -> void:
		pass
	func _apply_hit(_h: Dictionary, _show := true) -> void:
		pass
	func _impact(_t, _h: Dictionary, _col: Color) -> void:
		pass
	func _float_hit(_id, _sh: float, _hull: float, _crit) -> void:
		pass
	func _play_fire(_e: Dictionary, _grp: Array) -> void:
		pass

# issue 1448: the ui cue sink (OrdersKit.sound) and a music player that records what the battle asked of it
class UiEar extends Node:
	var heard: Array = []
	func play(n: String, _o := {}) -> void:
		heard.append(n)

class MusicEar extends Node:
	var plays := true
	var fed: Array = []
	var stings: Array = []
	func feed(d: Dictionary) -> float:
		fed.append(d)
		return 0.0
	func victory(_boss := false) -> bool:
		stings.append("victory")
		return plays
	func defeat() -> bool:
		stings.append("defeat")
		return plays

class HudEar extends CanvasLayer:
	func set_phase(_a, _b) -> void:
		pass
	func banner(_t, _c = null, _d = 0.0) -> void:
		pass

class QuietHost extends "res://main/campaign_host.gd":
	func _play_battle() -> void:
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
	GUARD.arm(self, "audio_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	call_deferred("_run")

func _ok(c: bool, message: String) -> void:
	if not c:
		fails.append(message)
		print("  FAIL ", message)

# Issue 1752 Gate 2: every recorded weapon sound is a "faction.weapon_id" variant on the cue the battle really plays for
# that faction's weapon (battle._wfam, then sfx.gd's own cue choice), so no wired sound sits on a cue nobody reaches;
# every layer of every cue and variant names a clip set the game loaded.
func _wired_1752(s) -> void:
	var tables: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://rules/data/tables.json"))["tables"]
	var W: Dictionary = tables["W"]
	var b = load("res://scenes/battle/battle.gd").new()
	var wired := 0
	for cue in s.cues:
		for L in s.cues[cue]["layers"]:
			if L.has("s"):
				_ok(s.clips.has(L["s"]), "%s layer %s has its clips" % [cue, L["s"]])
		for v in s.cues[cue].get("variants", {}):
			for L in s.cues[cue]["variants"][v].get("layers", []):
				if L.has("s"):
					_ok(s.clips.has(L["s"]), "%s:%s layer %s has its clips" % [cue, v, L["s"]])
			if not str(v).contains("."):
				continue
			var fac := str(v).split(".")[0]
			var wid := str(v).split(".")[1]
			_ok(W.has(wid) and (tables["FAC_WPOOL"][fac] as Array).has(wid), "%s:%s is a real %s weapon" % [cue, v, fac])
			if not W.has(wid):
				continue
			var fam: String = b._wfam({"fac": fac, "squadron": str(W[wid]["k"]) == "sq"}, {"kind": W[wid]["k"], "weapon_id": wid})
			var want := ""
			if fam in ["lance", "ion"]:
				want = "lance_dark" if fac == "deathless" else "lance_choir" if fac == "ithar" else "lance_ion" if fam == "ion" else "lance"
				if cue == "lance_charge":
					want = "lance_charge"
			elif fam == "torp":
				want = {"corsair": "torp_rocket", "chorus": "torp_sac", "ithar": "torp_star", "voidsworn": "torp_heavy"}.get(fac, "torp")
				if cue == "torp_charge":
					want = "torp_charge"
			elif fam == "sq":
				want = "gun_sq"
			elif str(W[wid]["k"]) == "flak":
				want = "gun_flak"
			else:
				var style = fam if fam in ["spine", "glob", "plasma", "las", "tracer", "needle", "rail"] else "shell"
				want = "gun_" + str(style)
			_ok(cue == want, "%s's %s plays %s, so its sound sits there, not on %s" % [fac, wid, want, cue])
			_ok(s.weapon_variant(cue, fac, wid) == v, "%s picks variant %s" % [cue, v])
			wired += 1
	b.free()
	# Artoo, PR 1932: a charge must not outlast the picture's own charge, or its tail runs over the shot. The Doom
	# corona is 0.35 s (fx_weapons.gd "doom"); every lance charge variant starts no earlier and ends by the beam.
	for v in s.cues["lance_charge"].get("variants", {}):
		var vd: Dictionary = s.cues["lance_charge"]["variants"][v]
		var lead := float(vd.get("lead", s.CHARGE_LEAD["lance_charge"]))
		_ok(lead <= 0.35 + 0.001, "lance_charge:%s leads by %.2f s, inside the 0.35 s corona" % [v, lead])
		_ok(float(vd.get("duration", 9.0)) <= lead + 0.06, "lance_charge:%s fades out by its beam" % v)
	_ok(wired >= 30, "issue 1752: the recorded weapon sounds are wired (%d)" % wired)
	_ok(s.weapon_variant("gun_sq", "hegemony", "guns") == "guns", "any faction's interceptor guns use the craft sound")
	_ok(s.weapon_variant("gun_shell", "voidsworn", "battery") == "", "a weapon with no recorded sound keeps the base cue")


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
	# RULEBOOK 8.4: count by family. Every family is present with at least the takes it has today; a new cue may be
	# added without moving a total, but a family that loses a take fails. No exact total of 67 is enforced.
	var listed := {}
	for fam in CUE_FAMILIES:
		var missing: Array = []
		for n in CUE_FAMILIES[fam]:
			if not s.cues.has(n): missing.append(n)
			listed[n] = true
		_ok(missing.is_empty(), fam + " family keeps its takes (%d present%s)" % [CUE_FAMILIES[fam].size() - missing.size(),
			"" if missing.is_empty() else ", missing " + ", ".join(missing)])
	for n in s.cues:
		_ok(listed.has(n), str(n) + " belongs to a cue family (add it to CUE_FAMILIES)")
	# A cue heard often never plays the same take twice in a row (RULEBOOK 8.4). _pick is the real round robin.
	var takes := ["a", "b", "c", "d"]
	var prev := ""
	var repeats := 0
	for i in 32:
		var pick := str(s._pick(takes, "audio-check"))
		if pick == prev: repeats += 1
		prev = pick
	_ok(repeats == 0, "a cue never plays the same take twice in a row (RULEBOOK 8.4)")
	print("AUDIO FAMILIES " + ", ".join(CUE_FAMILIES.keys().map(func(f): return "%s=%d" % [f, CUE_FAMILIES[f].size()])))
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
			if bool(vc.get("replace", false)):
				# issue 1238: a replace variant is the faction's whole sound, none of the base cue's clips under it
				var base_clips := {}
				for l in c.layers:
					if l.has("s"): base_clips[l.s] = true
				var own: Array = s._layers(name, c, variant)
				_ok(not own.is_empty(), name + " " + variant + " replace variant is playable")
				var mixed := false
				for l in vc.layers:
					_ok(s.clips.has(l.s), name + " " + variant + " variant clip exists: " + l.s)
				for st in own.map(func(x): return x.st):
					for k in base_clips:
						if not vc.layers.any(func(vl): return vl.s == k) and (s.clips.get(k, []) as Array).has(st):
							mixed = true
				_ok(not mixed, name + " " + variant + " plays no base-cue clip")
			else:
				_ok(s._layers(name, c, variant).size() > s._layers(name, c).size(), name + " adds its variant")
		for l in c.layers:
			if l.has("s"):
				_ok(s.clips.has(l.s), name + " clip exists: " + l.s)
	# issue 1238 (F5.4): Chorus and Glasswright deaths have their own sound at every step, with no steel layer
	var steel := ["scrape", "hullHitBig", "crackSettle", "wreckSettle", "heavyPlate", "debris", "boomBig", "ionCharge"]
	for fac in ["chorus", "ithar"]:
		for cue in ["death_powerdown", "death_vent", "death_run", "death_crack", "hulk_vent", "boom_l", "boom_s", "chunk_cool", "death_tail", "wreck", "hit_heavy"]:
			var v: Dictionary = s.cues[cue].get("variants", {}).get(fac, {})
			_ok(bool(v.get("replace", false)), cue + " has a " + fac + " sound of its own")
			for l in v.get("layers", []):
				_ok(not steel.has(l.s), cue + " " + fac + " has no steel layer: " + l.s)
	_ok(s.impact_cue("las", "hegemony") == "hit_las", "a las hit plays hit_las, not hit")
	_ok(s.impact_cue("lance", "hegemony") == "hit_las", "a lance hit plays hit_las")
	_ok(s.impact_cue("plasma", "hegemony") == "hit_plasma", "a plasma hit plays hit_plasma")
	_ok(s.impact_cue("rail", "hegemony") == "hit_rail", "a rail hit plays hit_rail")
	_ok(s.impact_cue("gauss", "hegemony") == "hit_rail", "a gauss hit plays hit_rail")
	_ok(s.impact_cue("ion", "hegemony") == "hit_ion", "an ion hit plays hit_ion")
	_ok(s.impact_cue("shell", "hegemony") == "hit", "a shell hit keeps hit")
	_ok(s.impact_cue("las", "chorus") == "hit_wet", "a hit on Chorus plays hit_wet")
	_ok(s.impact_cue("las", "ithar") == "hit_glass", "a hit on Glasswright plays hit_glass")
	_ok(s.impact_cue("las", "hegemony", true) == "hit_heavy", "a critical keeps hit_heavy")
	_ok(s.impact_cue("las", "hegemony", false, "chorus") == "hit_acid", "a Chorus shot on a metal hull plays hit_acid (issue 1752)")
	_ok(s.impact_cue("las", "hegemony", true, "chorus") == "hit_heavy", "a Chorus critical keeps hit_heavy")
	for tf in ["chorus", "ithar", "deathless"]:
		_ok(s.impact_cue("las", tf, false, "chorus") == str(s.HIT_BY_TARGET[tf]), "a Chorus shot on " + tf + " keeps its material cue")
	_ok(s.impact_cue("las", "deathless") == "hit_obsidian", "a hit on Eclipse plays hit_obsidian (issue 1752)")
	_wired_1752(s)
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
	# The death playbook keeps one core beat per capital death (the break, the core flash, then the wreck tail), so the
	# once-only death cues stay. Only the exact cue-table total above is retired (RULEBOOK 8.4, sound playbook item 4).
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
	await _issue_1448(s, m)
	s.free()
	m.free()
	# Let the audio server release the playback objects before shutdown.
	await create_timer(0.15).timeout
	print("AUDIO CHECK ", "PASS" if fails.is_empty() else "FAIL (%d)" % fails.size())
	quit(0 if fails.is_empty() else 1)


# ---------------------------------------------------------------- issue 1448: wiring, no new sounds
# Campaign screens click (one shared hook, OrdersKit.watch_sound), the built ui_reward and ui_boss cues play, a battle
# ends on one sound, and the battle music hears gunfire (shots) and counts close enemies by true hex distance.
func _press(c: Control) -> void:
	c.emit_signal("pressed")

func _pressables(under: Node) -> Array:
	var out: Array = []
	for n in under.find_children("*", "Control", true, false):
		if (n is BaseButton or (n.has_signal("pressed") and "disabled" in n)) and (n as Control).is_visible_in_tree():
			out.append(n)
	return out

func _unwired(under: Node) -> Array:
	return _pressables(under).filter(func(n): return not n.has_meta("kit_sound") and not n.has_meta("kit_silent")).map(func(n): return str(n.get("text")) if "text" in n else n.get_class())

func _issue_1448(sfx_node: Node, real_music: Node) -> void:
	var ear := UiEar.new()
	root.add_child(ear)
	var old_sound = Kit.sound
	Kit.sound = ear
	# 1. the hook itself: a plain button and a choice well added under a watched root click and hover; a maker's own
	# role sticks; kit_silent opts out; a button outside the root is left alone
	var host := Control.new()
	root.add_child(host)
	Kit.watch_sound(host)
	var plain := Button.new()
	host.add_child(plain)
	var well := ChoiceScript.new()
	host.add_child(well)
	var ruled := Button.new()
	Kit.wire_sound(ruled, "reward")
	host.add_child(ruled)
	var quiet := Button.new()
	quiet.set_meta("kit_silent", true)
	host.add_child(quiet)
	var outside := Button.new()
	root.add_child(outside)
	ear.heard.clear()
	_press(plain); plain.mouse_entered.emit(); _press(well); _press(ruled); _press(quiet); _press(outside)
	_ok(ear.heard == ["ui_click", "ui_select", "ui_click", "ui_reward"], "1448 the shared hook: a plain button clicks and hovers, a choice well clicks, a reward confirm chimes, opted-out and outside buttons stay silent (%s)" % str(ear.heard))
	host.free(); outside.free()
	# 2. the real campaign screens: every button and choice is wired, and a press plays its cue
	root.size = Vector2i(1920, 1080)
	var C = Campaign.new()
	_ok(C.load_tables() == "", "1448 campaign tables load")
	C.persist_on = false; C.fixed_clock = true; C.teaching_tips = false
	var ui = CampaignUI.new()
	root.add_child(ui); ui.bind(C); ui.use_3d_map = false
	await process_frame
	JSM.rnd_seed(868)
	var adm := ""
	for id in C.ADMIRALS:
		if str(C.ADMIRALS[id].get("fac", "")) == "voidsworn": adm = str(id); break
	C.newRun(adm, "voidsworn"); C.modal_d = null
	var screens := {}
	C.mapScreen(); await _frames(4)
	screens["map"] = [_pressables(ui).size(), _unwired(ui)]
	ear.heard.clear()
	var route = ui._routes[0]["id"] if not ui._routes.is_empty() else ""
	var rb: Array = ui.find_children("Route*", "Button", true, false)
	if not rb.is_empty(): _press(rb[0])
	var jb: Array = ui.find_children("JumpAction", "Button", true, false)
	_ok(not rb.is_empty() and ear.heard.has("ui_click") and not jb.is_empty() and str(jb[0].get_meta("kit_sound", "")) == "primary", "1448 map: a route row clicks and the jump button confirms (%s, route %s)" % [str(ear.heard), str(route)])
	C.fleetScreen("map"); await _frames(4)
	screens["fleet"] = [_pressables(ui).size(), _unwired(ui)]
	ear.heard.clear()
	var fl: Array = _pressables(ui.fleet_manifest) if is_instance_valid(ui.fleet_manifest) else []
	if not fl.is_empty(): _press(fl[0])
	_ok(not fl.is_empty() and not ear.heard.is_empty() and str(ear.heard[0]).begins_with("ui_"), "1448 fleet: a fleet page button plays a ui cue (%s)" % str(ear.heard))
	var yard = null
	for col in C.RUN["map"]["cols"]:
		for n in col:
			if yard == null and str(n.get("type", "")) == "shipyard": yard = n
	if yard != null:
		C.RUN["credits"] = 5000
		C.shipyardScreen(yard); await _frames(4)
		screens["shipyard"] = [_pressables(ui).size(), _unwired(ui)]
		var buys: Array = _pressables(ui).filter(func(n): return str(n.get_meta("kit_sound", "")) == "reward" and not bool(n.get("disabled")))
		ear.heard.clear()
		if not buys.is_empty(): _press(buys[0])
		_ok(not buys.is_empty() and ear.heard.has("ui_reward") and not ear.heard.has("ui_confirm"), "1448 shipyard: buying a hull chimes ui_reward, not the plain confirm (%d buy buttons, %s)" % [buys.size(), str(ear.heard)])
	else:
		_ok(false, "1448 a shipyard stop exists on the first map")
	C.mapScreen(); await _frames(2)
	C.act("enterNode", "0-0"); C.act("battle", "win"); await _frames(4)
	var prize_ok := C.modal_d != null and str(C.modal_d["kind"]) == "prize"
	screens["reward"] = [_pressables(ui).size(), _unwired(ui)]
	var takes: Array = _pressables(ui).filter(func(n): return str(n.get_meta("kit_sound", "")) == "reward" and not bool(n.get("disabled")))
	ear.heard.clear()
	if not takes.is_empty(): _press(takes[0])
	_ok(prize_ok and not takes.is_empty() and ear.heard.has("ui_reward") and not ear.heard.has("ui_confirm"), "1448 reward: confirming the prize chimes ui_reward, not the plain confirm (%s)" % str(ear.heard))
	# number keys in a dialog sound like the button they press
	var picked := false
	for k in 6:
		await _frames(3)
		if C.modal_d == null: break
		var on = (C.modal_d["acts"] as Array).filter(func(a): return a[2] == 1)
		var ri := -1
		for i in mini(9, on.size()):
			if str(on[i][0]) in CampaignUI.REWARD_ACTS: ri = i; break
		if ri < 0: break
		ear.heard.clear()
		var e := InputEventKey.new(); e.keycode = KEY_1 + ri; e.pressed = true
		ui._unhandled_input(e)
		picked = ear.heard.has("ui_reward")
		break
	_ok(picked or C.modal_d == null, "1448 a number key that takes a reward chimes too (%s)" % str(ear.heard))
	# the player-path recorder presses the real button for a campaign choice, so its recordings carry the cue (SND1C's
	# reward picks were silent: the recorder called the action under the button)
	var rec := ""
	for k in 6:
		await _frames(3)
		if C.modal_d == null: break
		var ra = (C.modal_d["acts"] as Array).filter(func(a): return a[2] == 1 and str(a[0]) in CampaignUI.REWARD_ACTS)
		if ra.is_empty(): break
		ear.heard.clear()
		var pressed := PlayerPath.press_act(ui, str(ra[0][0]), str(ra[0][1]))
		rec = "%s %s pressed=%s heard=%s" % [ra[0][0], ra[0][1], pressed, str(ear.heard)]
		_ok(pressed and ear.heard.has("ui_reward"), "1448 the recorder presses the reward button and the recording hears ui_reward (%s)" % rec)
		break
	_ok(rec != "", "1448 a reward choice is left for the recorder check")
	_ok(not PlayerPath.press_act(ui, "noSuchAct", ""), "1448 the recorder falls back when no button carries the action")
	var bad := []
	for sc in screens:
		if screens[sc][0] == 0 or not (screens[sc][1] as Array).is_empty(): bad.append("%s: %d pressable, unwired %s" % [sc, screens[sc][0], str(screens[sc][1])])
	_ok(bad.is_empty(), "1448 map, fleet, shipyard and reward: every button and choice plays a ui cue (%s)" % str(bad))
	print("AUDIO 1448 SCREENS " + ", ".join(screens.keys().map(func(k): return "%s=%d" % [k, screens[k][0]])))
	ui.free()
	# 3. the Career screen
	var S = StoryScript.new()
	root.add_child(S)
	S.career.persist = false
	S.career.P = Career.default_profile()
	var scr = S.open_career()
	await _frames(3)
	var cu: Array = _unwired(scr) if scr != null else ["no screen"]
	var close_role := ""
	if scr != null:
		for b in scr.find_children("Close", "Button", true, false): close_role = str(b.get_meta("kit_sound", ""))
	_ok(scr != null and _pressables(scr).size() > 0 and cu.is_empty() and close_role == "back", "1448 Career: every tab and button plays a ui cue, Close plays back (%s, close %s)" % [str(cu), close_role])
	S.free()
	# 4. ui_boss when a boss or Nemesis fight is entered, not for an ordinary fight
	var hostc := QuietHost.new()
	root.add_child(hostc)
	hostc.C = Campaign.new()
	var boss_heard := []
	for cfg in [{"kind": "boss"}, {"kind": "elite", "nemesis": {"name": "x"}}, {"kind": "battle"}]:
		ear.heard.clear(); hostc.in_battle = false; hostc.C.pending_battle = cfg
		hostc._on_battle()
		boss_heard.append(ear.heard.has("ui_boss"))
	_ok(boss_heard == [true, true, false], "1448 ui_boss plays on entering a boss or Nemesis fight, not an ordinary one (%s)" % str(boss_heard))
	hostc.free()
	# 5. one end sound: the music fanfare, or the synth sting only when the music cannot play
	var b := QuietBattle.new()
	b.sfx = sfx_node
	var hud_ear := HudEar.new()
	root.add_child(hud_ear)
	b.hud = hud_ear
	var me := MusicEar.new()
	root.add_child(me)
	b.music = me
	heard.clear()
	var r1: String = b._end_sound(true)
	await create_timer(0.05).timeout
	_ok(r1 == "music" and me.stings == ["victory"] and not heard.has("sting_win"), "1448 a won battle with music on plays the fanfare only, no synth sting (%s, %s)" % [r1, str(heard)])
	me.plays = false; heard.clear()
	var r2: String = b._end_sound(false)
	await create_timer(0.05).timeout
	_ok(r2 == "sting" and heard.has("sting_loss"), "1448 with the music unable to play, the synth sting stands in (%s, %s)" % [r2, str(heard)])
	real_music.set_on(false)
	_ok(not real_music.victory(false), "1448 the real music player reports no fanfare while music is off")
	real_music.set_on(true)
	# 6. the music hears gunfire: hits this round go in as shots, a new round clears them; close is true hex distance
	b.V = {"round": 1, "units": [
		{"id": "p", "side": "player", "dead": false, "squadron": false, "flagship": true, "hp": 100, "maxHp": 100, "q": 0, "r": 0},
		{"id": "e1", "side": "enemy", "dead": false, "squadron": false, "flagship": false, "hp": 100, "maxHp": 100, "q": 3, "r": -3},
		{"id": "e2", "side": "enemy", "dead": false, "squadron": false, "flagship": false, "hp": 100, "maxHp": 100, "q": 2, "r": 2},
		{"id": "e3", "side": "enemy", "dead": false, "squadron": false, "flagship": false, "hp": 100, "maxHp": 100, "q": -3, "r": 3}]}
	for i in 5:
		await b._play_event({"t": "hit", "unit": "e1", "target": null, "shield": 0, "hull": 3, "crit": false})
	b._music_feed()
	var f1: Dictionary = me.fed[-1]
	b.bot = true   # the round banner waits on the battle's pacing table, which a headless battle never loads
	await b._play_event({"t": "round", "round": 1})
	b._music_feed()
	var f2: Dictionary = me.fed[-1]
	_ok(int(f1.get("shots", -1)) == 5 and int(f2.get("shots", -1)) == 0, "1448 music gets this round's hits as shots, cleared each round (%s then %s)" % [str(f1.get("shots")), str(f2.get("shots"))])
	# a real grouped volley through _play_batch (Artoo, PR 1478): the fire event takes its hits with it, so they are
	# counted there; then a round reset in the next batch clears them before that round's own volley
	b.music_hits = 0
	var hit := {"t": "hit", "unit": "p", "target": "e1", "shield": 0, "hull": 3, "crit": false}
	var view: Dictionary = b.V
	await b._play_batch({"events": [{"t": "fire", "unit": "p", "target": "e1", "kind": "volley"}, hit, hit, {"t": "system", "unit": "e1", "target": "e1"}, hit], "view": view})
	b._music_feed()
	var g1: Dictionary = me.fed[-1]
	await b._play_batch({"events": [{"t": "round", "round": 1}, {"t": "fire", "unit": "p", "target": "e1", "kind": "volley"}, hit], "view": view})
	b._music_feed()
	var g2: Dictionary = me.fed[-1]
	_ok(int(g1.get("shots", -1)) == 3 and int(g2.get("shots", -1)) == 1, "1448 a grouped volley's hits reach the music once each, and a new round starts the tally again (%s then %s)" % [str(g1.get("shots")), str(g2.get("shots"))])
	# e1 and e3 are 3 hex steps away (the old |dq|+|dr| read 6 and missed them); e2 is 4 away (the old sum read 4, close)
	_ok(int(f1.get("close", -1)) == 2, "1448 close counts the two enemies 3 hexes away and not the one 4 away (%s)" % str(f1.get("close")))
	var lift: float = real_music.feed(f1)
	var flat: float = real_music.feed({"close": f1["close"], "shots": 0, "hull": f1["hull"], "flagship": f1["flagship"], "mine": f1["mine"], "enemy": f1["enemy"]})
	_ok(lift > flat + 0.05, "1448 gunfire lifts the real music intensity (%.2f with fire, %.2f without)" % [lift, flat])
	b.free(); me.free(); hud_ear.free()
	Kit.sound = old_sound
	ear.free()

func _frames(n := 3) -> void:
	for i in n:
		await process_frame
