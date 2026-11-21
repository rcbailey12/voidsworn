extends SceneTree
# godot --headless --path godot --script res://fx/test/approved_effects_check.gd
# Battle effects audit (Ryan, Nov 21 2026: "make sure all of the damage, death, hit effects, etc are being appropriately
# brought in and used"). Approved looks had been built and then not shown: a default left off, or an fx call that
# battle.gd never makes. This check fails on both, from fx/test/approved_effects.json:
# 1. Defaults: every approved look is what the game plays with no option or environment switch set.
# 2. Wiring: every fx call in fx/API.md section 11 ("Rules events to fx calls") is made when battle.gd plays that event.
#    The real battle scene (test battle s1) plays one of each simple event (shield_down, tick, ability, command, ram,
#    board, fled) through its own _play_event with a recording fx stand-in, so the call must come from that event, not
#    from anywhere in the file (Artoo on PR 1523). A call that names a weapon_id must pass it. Rows the scene cannot play
#    alone (battle start, move, fire, death, batch end) keep a source inventory: gfx.<call>( somewhere in battle.gd.
#    A missing call fails unless the registry's "unwired" list names it with its job; a listed call that is made now also
#    fails, so the list cannot go stale.
# 3. Prints the approved looks still waiting on an open pull request.

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const BattleScene := preload("res://scenes/battle/battle.tscn")
const SHIP := preload("res://fx/fx_ship.gd")
const REG := "res://fx/test/approved_effects.json"
const ENV := ["VS_DEATH_STORY", "VS_DEATH_DIM", "VS_SHIELD_FAILURE", "VS_SHIELD_FAILURE_Q", "VS_SHIELD_CLOSE", "VS_SHIELD_SHAPE"]
var failures := 0


func _init() -> void:
	GUARD.arm(self, "approved_effects_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_as_text() if f != null else ""


func _probe(name: String, fx) -> Variant:
	match name:
		"death_story":
			return fx.death_story
		"eclipse_only_dim":
			# R389: no general scene dim; the Eclipse (peel) death still dims. dim_scene(t) without force must not dim,
			# with force it must, and fx_death.gd must force it for the peel style only.
			var cam := Camera3D.new()
			root.add_child(cam)
			fx.camera = cam
			fx.dim_scene(fx.now)
			var general: bool = fx._dim_t0 >= 0.0
			fx.dim_scene(fx.now, true)
			var eclipse: bool = fx._dim_t0 >= 0.0
			var wired := _text("res://fx/fx_death.gd").contains('fx.dim_scene(fx.now + 0.20, style == "peel")')
			fx.camera = null
			cam.queue_free()
			return "general %s, eclipse %s, peel only %s" % [general, eclipse, wired]
		"shield_failure":
			return SHIP.FAIL_LOOKS[SHIP.fail_look_setting()]
		"shield_close":
			return snappedf(SHIP.collapse_close_setting(), 0.001)
		"shield_shape":
			# fx_ship.gd reads the setting with its code default; both must give the approved shape
			var src := _text("res://fx/fx_ship.gd")
			var m := RegEx.create_from_string('"rendering/effects/shield_shape", "([a-z]+)"').search(src)
			var code_default := m.get_string(1) if m != null else "?"
			return str(ProjectSettings.get_setting("rendering/effects/shield_shape", code_default))
		"kill_slowmo_wired":
			return _text("res://scenes/battle/battle.gd").contains("gfx.kill_slowmo = not reduce_motion")
	return null


func _faction_deaths() -> Dictionary:
	var looks = JSON.parse_string(_text("res://fx/faction_looks.json"))
	return looks if looks is Dictionary else {}


# fx/API.md section 11: [{event, calls: [name], ids: [weapon ids]}]
func _api_rows() -> Array:
	var md := _text("res://fx/API.md")
	var i := md.find("## 11.")
	var j := md.find("\n## ", i + 5)
	var sec := md.substr(i, j - i) if i >= 0 else ""
	var out: Array = []
	var tick := RegEx.create_from_string("`([^`]+)`")
	var call := RegEx.create_from_string("(^|[^.a-z_])([a-z_]+)\\(")
	var wid := RegEx.create_from_string('weapon_id: "([a-z_]+)"')
	for line in sec.split("\n"):
		if not line.begins_with("| ") or line.begins_with("| Event") or line.begins_with("|---"):
			continue
		var cols := line.split("|")
		if cols.size() < 3:
			continue
		var row := {"event": cols[1].replace("`", "").strip_edges(), "calls": [], "ids": []}
		for t in tick.search_all(cols[2]):
			var code := t.get_string(1)
			if code.begins_with("world."):
				continue   # the world's own call (world.gd), not fx
			for c in call.search_all(code):
				if not (c.get_string(2) in row["calls"]):
					row["calls"].append(c.get_string(2))
			for w in wid.search_all(code):
				row["ids"].append(w.get_string(1))
		out.append(row)
	return out


func _run() -> void:
	for k in ENV:
		OS.set_environment(k, "")
	var reg = JSON.parse_string(_text(REG))
	_check(reg is Dictionary, "the registry %s parses" % REG)
	if not (reg is Dictionary):
		quit(1)
		return
	var fx = FX.new()
	root.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high"})
	var looks := _faction_deaths()

	print("-- 1. approved looks are the default")
	for d in reg.get("defaults", []):
		var tag := "%s (%s)" % [str(d["ruling"]), str(d["what"])]
		match str(d["probe"]):
			"faction_death":
				for fac in (d["want"] as Dictionary):
					var got := str(looks.get(fac, {}).get("death", {}).get("style", "none"))
					_check(got == str(d["want"][fac]), "%s: %s dies as %s (got %s)" % [tag, fac, str(d["want"][fac]), got])
			"death_smoke":
				for fac in (d["want"] as Dictionary):
					var got := float(looks.get(fac, {}).get("death", {}).get("smoke", -1.0))
					_check(is_equal_approx(got, float(d["want"][fac])), "%s: %s smoke %.2f (got %.2f)" % [tag, fac, float(d["want"][fac]), got])
			_:
				var got = _probe(str(d["probe"]), fx)
				var want = d["want"]
				var ok: bool = (is_equal_approx(float(got), float(want)) if want is float else str(got) == str(want)) if got != null else false
				_check(ok, "%s: %s is %s (got %s)" % [tag, str(d["probe"]), str(want), str(got)])

	print("-- 2. battle.gd makes every fx call in API.md section 11")
	var battle := _text("res://scenes/battle/battle.gd")
	var listed := {}
	for u in reg.get("unwired", []):
		_check(str(u.get("job", "")) != "", "unwired %s names its job" % str(u["event"]))
		listed[str(u["event"]) + "|" + str(u["call"])] = u
	var rows := _api_rows()
	_check(rows.size() >= 10, "API.md section 11 has its mapping table (%d rows)" % rows.size())
	var played: Dictionary = await _play_events()
	var seen := {}
	for row in rows:
		var ev := str(row["event"])
		var live: bool = played.has(ev)
		var needs: Array = []
		for c in row["calls"]:
			if str(c) == "volley" and not (row["ids"] as Array).is_empty():
				continue   # the weapon_id need below is the stricter form of this call
			needs.append([str(c), str(c), ""])
		for w in row["ids"]:
			needs.append(["volley weapon_id " + str(w), "volley", str(w)])
		for n in needs:
			var key := ev + "|" + str(n[0])
			var wired: bool
			var how: String
			if live:
				wired = _recorded(played[ev], str(n[1]), str(n[2]))
				how = "playing %s in the battle scene calls %s" % [ev, n[0]]
			else:
				wired = battle.contains("gfx.%s(" % n[1]) and (n[2] == "" or battle.contains('"weapon_id": "%s"' % n[2]))
				how = "battle.gd calls gfx.%s( (source only)" % n[0]
			seen[key] = true
			if listed.has(key):
				_check(not wired, "%s -> %s is still unwired (job %s); delete its registry row once wired" % [ev, n[0], str(listed[key]["job"])])
				if not wired:
					print("INFO not shown in battle yet: %s" % str(listed[key]["what"]))
			else:
				_check(wired, "%s -> %s" % [ev, how])
	for key in listed:
		_check(seen.has(key), "registry unwired row %s matches an API.md row" % key)

	print("-- 3. approved looks waiting on an open pull request")
	for w in reg.get("waiting", []):
		print("INFO waiting%s: %s" % [(" on PR %d" % int(w["pr"])) if int(w.get("pr", 0)) > 0 else "", str(w["what"])])

	fx.release()
	print("APPROVED_EFFECTS %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)


# The fx stand-in: records every call battle.gd makes on gfx while the events play (variadic, Godot 4.5+).
class Rec extends Node:
	var calls: Array = []
	var now := 0.0
	var reduce_flashing := false
	var kill_slowmo := false
	var shake_scale := 1.0
	func _r(n: String, a: Array) -> void:
		calls.append([n, a])
	func pop(...a: Array) -> void: _r("pop", a)
	func light(...a: Array) -> void: _r("light", a)
	func shield_break(...a: Array) -> void: _r("shield_break", a)
	func tick(...a: Array) -> void: _r("tick", a)
	func ability(...a: Array) -> void: _r("ability", a)
	func command(...a: Array) -> void: _r("command", a)
	func jump_out(...a: Array) -> void: _r("jump_out", a)
	func set_engine(...a: Array) -> void: _r("set_engine", a)
	func sync_ship(...a: Array) -> void: _r("sync_ship", a)
	func hull_mark(...a: Array) -> void: _r("hull_mark", a)
	func volley(...a: Array) -> Dictionary:
		_r("volley", a)
		return {"done": 0.0}
	func board(...a: Array) -> float:
		_r("board", a)
		return 0.0


func _recorded(calls: Array, name: String, weapon: String) -> bool:
	for c in calls:
		if str(c[0]) != name:
			continue
		if weapon == "":
			return true
		for x in (c[1] as Array):
			if x is Dictionary and str(x.get("weapon_id", "")) == weapon:
				return true
	return false


# Plays one of each simple rules event through the live battle scene's own _play_event; returns {API row: calls}.
func _play_events() -> Dictionary:
	var out := {}
	var b = BattleScene.instantiate()
	b.tips_off = true
	b.external = true
	root.add_child(b)
	b.args["scenario"] = "s1"
	b.args["seed"] = 1001
	b.start_default()
	var t0 := Time.get_ticks_msec()
	while (b.api == null or b.warming or b.busy or b.api.phase != "player") and Time.get_ticks_msec() - t0 < 120000:
		await process_frame
	_check(b.api != null and b.api.phase == "player", "the battle scene reached the player's turn")
	if b.api == null:
		return out
	var mine := ""
	var foe := ""
	for u in b.V["units"]:
		if u["dead"] or u["squadron"]:
			continue
		if u["side"] == "player" and mine == "":
			mine = str(u["id"])
		elif u["side"] == "enemy" and foe == "":
			foe = str(u["id"])
	_check(mine != "" and foe != "", "test battle s1 has a player ship and an enemy ship")
	var ab := ""
	for k in (b.TBL.get("ABILITIES", {}) as Dictionary):
		if not (str(k) in ["blink", "nova", "launch"]):
			ab = str(k)
			break
	var cmd := ""
	var cs = b.TBL.get("COMMANDS", {})
	for c in (cs.values() if cs is Dictionary else cs):
		if c is Dictionary and c.has("id"):
			cmd = str(c["id"])
			break
	var real = b.gfx
	var rec := Rec.new()
	root.add_child(rec)
	b.gfx = rec
	b.speed = 0.05
	var u0: Dictionary = b.VU.get(mine, {})
	var here := {"q": int(u0.get("q", 0)), "r": int(u0.get("r", 0)), "f": int(u0.get("facing", 0))}
	var events := [
		["shield_down", {"t": "shield_down", "unit": foe, "quad": 0}],
		["section_down, system, burning, tick", {"t": "tick", "unit": foe, "kind": "fire", "hull": 1}],
		["ability, command", {"t": "ability", "unit": mine, "ab": ab}],
		["ability, command", {"t": "command", "unit": mine, "id": cmd, "side": "player"}],
		["ram", {"t": "ram", "unit": mine, "target": foe, "path": [here], "dmg": 1, "section": "mid", "recoil": 1}],
		["board", {"t": "board", "unit": mine, "target": foe, "result": "repelled", "kill": 1, "loss": 1}],
		["fled", {"t": "fled", "unit": foe}],
	]
	for pair in events:
		rec.calls.clear()
		await b._play_event(pair[1])
		var got: Array = out.get(pair[0], [])
		got.append_array(rec.calls)
		out[pair[0]] = got
		var names: Array = []
		for c in rec.calls:
			names.append(c[0])
		print("INFO %s played, fx calls: %s" % [str(pair[1]["t"]), ", ".join(names) if not names.is_empty() else "none"])
	b.gfx = real
	return out
