extends SceneTree
# godot --headless --path godot --script res://fx/test/approved_effects_check.gd
# Battle effects audit (Ryan, Nov 21 2026: "make sure all of the damage, death, hit effects, etc are being appropriately
# brought in and used"). Approved looks had been built and then not shown: a default left off, or an fx call that
# battle.gd never makes. This check fails on both, from fx/test/approved_effects.json:
# 1. Defaults: every approved look is what the game plays with no option or environment switch set.
# 2. Wiring: every fx call in fx/API.md section 11 ("Rules events to fx calls") is made by battle.gd as gfx.<call>(,
#    and a call that names a weapon_id passes that id. A missing call fails unless the registry's "unwired" list names it
#    with its job; a listed call that battle.gd now makes also fails, so the list cannot go stale.
# 3. Prints the approved looks still waiting on an open pull request.

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
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
		"scene_dim":
			return fx.scene_dim
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
	var seen := {}
	for row in rows:
		var needs: Array = []
		for c in row["calls"]:
			needs.append([str(c), "gfx.%s(" % c])
		for w in row["ids"]:
			needs.append(["volley weapon_id " + str(w), '"weapon_id": "%s"' % w])
		for n in needs:
			var key := str(row["event"]) + "|" + str(n[0])
			var wired := battle.contains(str(n[1]))
			seen[key] = true
			if listed.has(key):
				_check(not wired, "%s -> %s is still unwired (job %s); delete its registry row once wired" % [row["event"], n[0], str(listed[key]["job"])])
				if not wired:
					print("INFO not shown in battle yet: %s" % str(listed[key]["what"]))
			else:
				_check(wired, "%s -> battle.gd calls %s" % [row["event"], str(n[1])])
	for key in listed:
		_check(seen.has(key), "registry unwired row %s matches an API.md row" % key)

	print("-- 3. approved looks waiting on an open pull request")
	for w in reg.get("waiting", []):
		print("INFO waiting%s: %s" % [(" on PR %d" % int(w["pr"])) if int(w.get("pr", 0)) > 0 else "", str(w["what"])])

	fx.release()
	print("APPROVED_EFFECTS %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
