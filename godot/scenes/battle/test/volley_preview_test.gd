extends SceneTree

const API := preload("res://rules/battle_api.gd")
const Battle := preload("res://scenes/battle/battle.gd")
const SAMPLES := 128
const ROUTING_SAMPLES := 1024

var failures := 0


func _initialize() -> void:
	var api := API.new()
	var error := api.load_rules()
	if error != "":
		printerr("FAIL: ", error)
		quit(1)
		return
	for guns in [1, 2, 3]:
		_case(api, guns, 0.0, false)
		_case(api, guns, 8.0, false)
	_case(api, 3, 36.0, true)
	_routing_case(api)
	if failures == 0:
		print("PASS: target preview matches seeded 1-, 2- and 3-gun volleys (bare, shielded and planned) and low-odds routing")
	quit(0 if failures == 0 else 1)


func _case(api: API, guns: int, pool: float, planned: bool) -> void:
	var label := "%d guns, pool %s, planned %s" % [guns, str(pool), str(planned)]
	var scene := Battle.new()
	scene.api = api
	var preview := Vector2.ZERO
	var sum := Vector2.ZERO
	var squares := Vector2.ZERO
	for sample in SAMPLES:
		api.new_battle_scenario("s1")
		var ship: Dictionary = api.R.alive("player")[1]
		var foe: Dictionary = api.R.alive("enemy")[0]
		ship.merge({"q": 2, "r": 6, "facing": 0, "crit": -100}, true)
		foe.merge({"q": 5, "r": 6, "facing": 3, "hp": 500, "maxHp": 500,
			"ev": 0, "armor": 0.2, "shMax": pool, "shp": pool, "sh": [0, 0, 0, 0],
			"cov": [0.6, 0.35, 0.25, 0.35], "route": [0, 0, 0, 0]}, true)
		api.R.syncShields(foe)
		api.R.B["terrain"].clear()
		var gun: Dictionary = ship["weapons"][0].duplicate()
		ship["weapons"] = []
		for i in guns:
			var w := gun.duplicate()
			w.merge({"arc": "F", "r": 2 if planned else 4, "opt": 4, "acc": 85,
				"shots": 2 if planned and i == 0 else 1, "dmg": 12 + i * 2,
				"ion": 1.5 if i == 1 else 0.0, "pierce": 0.25 if i == 2 else 0.0}, true)
			ship["weapons"].append(w)
		var sid: String = ship["id"]
		var tid: String = foe["id"]
		if sample == 0:
			scene.V = api.view()
			scene._index_view()
			scene.sel = sid
			scene.target = tid
			if planned:
				for state in api.reach(sid):
					if state.q == 3 and state.r == 6 and state.f == 0:
						scene.plan = state
						break
			var before := API.JSM.canon([ship, foe])
			var rng: int = scene.api.R.rng.rng_s
			var target := scene._target_info()
			if (planned and scene.plan == null) or target.get("bearing") != guns or scene.api.R.rng.rng_s != rng or API.JSM.canon([ship, foe]) != before:
				_fail(label + ": preview used the wrong guns or touched the battle")
				scene.free()
				return
			preview = Vector2(target.exp_shields, target.exp_hull)
		if planned and not api.move(sid, scene.plan):
			_fail(label + ": planned move did not execute")
			scene.free()
			return
		api.R.rng.rnd_seed((sample + 1) * 7919)
		api.take_events()
		for i in guns:
			if not api.fire(sid, i, tid):
				_fail(label + ": gun %d did not fire" % i)
				scene.free()
				return
		var damage := Vector2.ZERO
		for event in api.take_events():
			if event.t == "hit" and event.unit == sid and event.target == tid:
				damage += Vector2(event.shield, event.hull)
		sum += damage
		squares += damage * damage
	scene.free()
	var mean := sum / SAMPLES
	var variance := squares / SAMPLES - mean * mean
	# Allow half a point for HUD rounding, half per shot for the rules' integer hit
	# records, and three standard errors from the fixed sample of dice rolls.
	var rounding := 0.5 + 0.5 * (guns + int(planned))
	var tolerance := Vector2(rounding, rounding) + Vector2(sqrt(maxf(0.0, variance.x)), sqrt(maxf(0.0, variance.y))) * (3.0 / sqrt(SAMPLES))
	var delta := (mean - preview).abs()
	if delta.x > tolerance.x or delta.y > tolerance.y:
		_fail("%s: preview %s, actual mean %s, tolerance %s (shield/hull)" % [label, preview, mean, tolerance])


# Artoo's worked case (PR 1162): four independent 30 percent shots, each strong
# enough to fill the facing, into a 60 point pool with 25 percent coverage. Shield
# routing follows only a landed hit, so the pool survives a miss and the preview
# must branch on each shot instead of draining the pool by the odds.
func _routing_case(api: API) -> void:
	var label := "low odds, pool 60, coverage 25%"
	var scene := Battle.new()
	scene.api = api
	var preview := Vector2.ZERO
	var sum := Vector2.ZERO
	var squares := Vector2.ZERO
	for sample in ROUTING_SAMPLES:
		api.new_battle_scenario("s1")
		var ship: Dictionary = api.R.alive("player")[1]
		var foe: Dictionary = api.R.alive("enemy")[0]
		ship.merge({"q": 2, "r": 6, "facing": 0, "crit": -100}, true)
		foe.merge({"q": 5, "r": 6, "facing": 3, "hp": 500, "maxHp": 500,
			"ev": 0, "armor": 0.2, "shMax": 60.0, "shp": 60.0, "sh": [0, 0, 0, 0],
			"cov": [0.25, 0.25, 0.25, 0.25], "route": [0, 0, 0, 0]}, true)
		api.R.syncShields(foe)
		api.R.B["terrain"].clear()
		var gun: Dictionary = ship["weapons"][0].duplicate()
		ship["weapons"] = []
		# The target is still, so its 10 point still bonus turns 20 aim into the 30 percent case.
		gun.merge({"arc": "F", "r": 4, "opt": 4, "acc": 20, "shots": 4, "dmg": 100,
			"ion": 0.0, "pierce": 0.0}, true)
		ship["weapons"].append(gun)
		var sid: String = ship["id"]
		var tid: String = foe["id"]
		if sample == 0:
			scene.V = api.view()
			scene._index_view()
			scene.sel = sid
			scene.target = tid
			var before := API.JSM.canon([ship, foe])
			var rng: int = scene.api.R.rng.rng_s
			var target := scene._target_info()
			if target.get("bearing") != 1 or int(target.get("hit", 0)) != 30 or scene.api.R.rng.rng_s != rng or API.JSM.canon([ship, foe]) != before:
				_fail(label + ": preview used the wrong gun or odds, or touched the battle")
				scene.free()
				return
			preview = Vector2(target.exp_shields, target.exp_hull)
		api.R.rng.rnd_seed((sample + 1) * 7919)
		api.take_events()
		if not api.fire(sid, 0, tid):
			_fail(label + ": gun did not fire")
			scene.free()
			return
		var damage := Vector2.ZERO
		for event in api.take_events():
			if event.t == "hit" and event.unit == sid and event.target == tid:
				damage += Vector2(event.shield, event.hull)
		sum += damage
		squares += damage * damage
	scene.free()
	var mean := sum / ROUTING_SAMPLES
	var variance := squares / ROUTING_SAMPLES - mean * mean
	# Shield events are whole points, so half a point covers the integer card. Hull
	# carries the damage roll and its own whole-point record, then three standard
	# errors from the fixed sample of dice rolls.
	var rounding := Vector2(0.5, 2.5)
	var tolerance := rounding + Vector2(sqrt(maxf(0.0, variance.x)), sqrt(maxf(0.0, variance.y))) * (3.0 / sqrt(ROUTING_SAMPLES))
	var delta := (mean - preview).abs()
	if delta.x > tolerance.x or delta.y > tolerance.y:
		_fail("%s: preview %s, actual mean %s, tolerance %s (shield/hull)" % [label, preview, mean, tolerance])


func _fail(message: String) -> void:
	failures += 1
	printerr("FAIL: ", message)
