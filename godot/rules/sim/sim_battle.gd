extends "res://rules/rules.gd"
## The legacy activation schedule and sim-only measurements around live battle rules.

const Bot = preload("res://rules/sim/sim_bot.gd")
const MAX_ROUNDS := 30
const MAX_ACTIVATION_PAIRS := 40
const MOVE_PER := {"voidsworn": 1.25, "hegemony": 0.75, "corsair": 0.85, "chorus": 1.1, "ithar": 1.0, "deathless": 0.6}
const SHIP_LENGTH := {"Frigate": 6.5, "Destroyer": 9.5, "Cruiser": 14.5, "Carrier": 16.5, "Battleship": 21, "Dreadnought": 27, "Super-dreadnought": 31, "Transport": 11, "Battle-barge": 26}

var timed := false
var matrix := false
var clock: Dictionary
var tempo: Dictionary
var categories: Dictionary
var matrix_stats := {"rounds": 0, "n": 0, "timeout": 0, "rams": {"player": 0, "enemy": 0},
	"boards": {"player": 0, "enemy": 0}, "overrun": 0, "caps": 0}
var hulls := {}
var weapons := {}
var abilities := {}
var _player_launches := 0
var _identity := {}
var _speed := 1.0
var _enemy_animation := false
var _rotating := false


func reset_timing() -> void:
	clock = {"old": 0.0, "neu": 0.0, "real": 0.0, "rounds": 0, "max_round": 0.0}
	tempo = {"player": 0, "enemy": 0, "fire": 0, "first_loss": 0, "first_count": 0}
	categories = {}


func startBattle(cfg: Dictionary, pick_skills := false) -> void:
	_player_launches = 0
	super.startBattle(cfg, pick_skills)


func launchWing(u, h, kind) -> void:
	super.launchWing(u, h, kind)
	# Replacement wings use this path without calling useAbility. Initial wings use makeWing.
	if u.side == "player":
		_player_launches += 1


func player_abilities_fired() -> Dictionary:
	var fired: Dictionary = B.usage.ab.duplicate()
	if _player_launches > 0:
		fired["launch"] = _player_launches
	return fired


func fight(bot: Bot, alternating: bool) -> void:
	B.alt = alternating
	if not alternating:
		_classic_fight(bot)
		return
	_reset_activations()
	startSideTurn("enemy")
	flush_deferred()
	var saw_loss := false
	for round_index in range(MAX_ROUNDS):
		if jt(B.over):
			break
		var round_start := 0.0
		if timed:
			saw_loss = _begin_timed_round(saw_loss)
			round_start = clock.real
			_speed = PACE.swarm * _enemy_pace()
		swarmPhase("player")
		swarmPhase("enemy")
		_speed = 1.0
		for pair_index in range(MAX_ACTIVATION_PAIRS):
			if jt(B.over):
				break
			var players := _pending("player")
			var enemies := _pending("enemy")
			if players.is_empty() and enemies.is_empty():
				break
			if not players.is_empty():
				if timed:
					tempo.player += 1
				bot.bot_unit(players[0])
				players[0].activated = true
				if jt(B.over):
					break
			var player_has_ships := not _pending("player").is_empty()
			# Campaign plays the unspent enemy wings first. Fmatrix only runs its opening swarm phase.
			var batch := [] if matrix else alive("enemy").filter(func(u): return u.isSq and not jt(u.get("activated")))
			if not player_has_ships:
				batch.append_array(enemies)
			elif not enemies.is_empty():
				batch.append(aiPickActivation(enemies))
			_enemy_batch(batch, player_has_ships)
		_finish_timed_round(round_start)
		if jt(B.over):
			break
		B.round += 1
		_reset_activations()
		roundStartBoth()


func _reset_activations() -> void:
	for unit in B.units:
		unit.activated = false


func _pending(side: String) -> Array:
	return caps(side).filter(func(u): return not jt(u.get("activated")))


func _enemy_batch(batch: Array, player_has_ships: bool) -> void:
	if timed:
		_speed = (PACE.enemy if player_has_ships else PACE.tail) * _enemy_pace()
		_enemy_animation = true
	for unit in batch:
		if jt(B.over):
			break
		if timed and not unit.isSq:
			tempo.enemy += 1
		aiUnit(unit)
		unit.activated = true
		if timed:
			if not unit.isSq and unit.weapons.any(func(w): return jt(w.get("fired"))):
				tempo.fire += 1
			clock.old += 0.28
			clock.neu += 0.099
			_wait("aigap", PACE.aiGap / 1000.0 * _speed)
	if timed:
		if not batch.is_empty():
			_wait("aiend", PACE.aiEnd / 1000.0 * _speed)
		clock.old += 0.25
		clock.neu += 0.12
		_enemy_animation = false
		_speed = 1.0


func _classic_fight(bot: Bot) -> void:
	var saw_loss := false
	for round_index in range(MAX_ROUNDS):
		if jt(B.over):
			break
		var round_start := 0.0
		if timed:
			saw_loss = _begin_timed_round(saw_loss)
			round_start = clock.real
		var activations := bot.bot_turn()
		if timed:
			tempo.player += activations
		if not jt(B.over):
			B.side = "enemy"
			turnStart("enemy")
			_classic_enemy_turn()
		_finish_timed_round(round_start)
		if jt(B.over):
			break
		B.round += 1
		B.side = "player"
		turnStart("player")


func _classic_enemy_turn() -> void:
	var order := JSM.ssort(alive("enemy"), func(a, b): return b.speed - a.speed)
	_enemy_batch(order.filter(func(u): return u.isSq), false)
	var ships := order.filter(func(u): return not u.isSq and not u.dead)
	while not ships.is_empty() and not jt(B.over):
		var ship = aiPickActivation(ships)
		ships.remove_at(JSM.index_same(ships, ship))
		_enemy_batch([ship], false)
		ships = ships.filter(func(u): return not u.dead)


func _finish_timed_round(start: float) -> void:
	if timed:
		clock.old += 1.02
		clock.neu += 0.66
		_wait("banner", (PACE.banner + 140.0) / 1000.0)
		clock.max_round = maxf(clock.max_round, clock.real - start)


func _begin_timed_round(saw_loss: bool) -> bool:
	clock.rounds += 1
	if not saw_loss and B.units.any(func(u): return u.side == "player" and jt(u.get("ship")) and u.dead):
		tempo.first_loss += B.round
		tempo.first_count += 1
		return true
	return saw_loss


func _enemy_pace() -> float:
	return clampf(sqrt(PACE.bigRef / maxf(1.0, caps("enemy").size())), PACE.bigMin, 1.0)


func _wait(category: String, seconds: float, unit = null) -> void:
	clock.real += seconds
	if unit != null:
		category += ":p" if unit.side == "player" else ":e"
		if unit.isSq:
			category += "sq"
	categories[category] = categories.get(category, 0.0) + seconds


func _move_time(unit: Dictionary, path: Array, charge: bool) -> void:
	var old_scale := 0.65 if _enemy_animation else 1.0
	var large: bool = unit.size > 0.8
	var turns := path.filter(func(point): return jt(point.get("rot"))).size()
	var hexes := path.size() - turns
	clock.old += turns * (0.42 if large else 0.28) + hexes * (0.11 if unit.isSq else (0.30 if large else 0.22))
	# The legacy new-clock thresholds multiply ship size by enemy pace.
	clock.neu += turns * (0.26 if old_scale * unit.size > 0.8 else 0.19)
	clock.neu += hexes * (0.07 if unit.isSq else (0.19 if large else 0.15))
	if _rotating:
		return
	var steps: float = hexes + turns * (0.3 if unit.isSq else PACE.rot)
	var per := 110.0 if unit.isSq else (430.0 if large else (350.0 if unit.size > 0.6 else 280.0))
	if not unit.isSq:
		per *= MOVE_PER.get(unit.fac, 1.0)
	var ms := per * steps + (60.0 if unit.isSq else 260.0)
	ms *= 0.72 if charge else 1.0
	ms *= 1.0 if unit.isSq else float(PACE.move)
	_wait("move", minf(ms, 900.0 if unit.isSq else 3600.0) / 1000.0 * _speed, unit)


func _fire_time(unit: Dictionary, event: Dictionary) -> void:
	var shots: int = event.shots.size()
	var old_scale := 0.65 if _enemy_animation else 1.0
	var volley := 1.0
	if not unit.isSq:
		for i in range(unit.weapons.size()):
			# Immediate torpedoes animate with a copy of the weapon, so the fired tube counts.
			if (i != event.weapon or event.kind == "torp") and jt(unit.weapons[i].get("fired")):
				volley = PACE.volley
				break
	var seconds := 0.0
	match event.kind:
		"lance":
			clock.old += 0.48 + shots * 0.34 + 0.22
			clock.neu += old_scale * 0.32 + shots * 0.25 + 0.15
			seconds = 0.64 + shots * 0.25 + 0.15
		"torp":
			clock.old += 0.48 + shots * 0.17 + 1.07
			clock.neu += old_scale * 0.32 + shots * 0.12 + 0.84
			seconds = 0.64 + shots * 0.12 + 0.84
		_:
			clock.old += (0.0 if unit.isSq else 0.48) + shots * 0.095 + 0.59
			clock.neu += old_scale * shots * 0.07 + 0.49
			seconds = shots * 0.07 + 0.49 + (0.16 if event.arc == "T" and not unit.isSq else 0.0)
	_wait("fire", seconds * volley * _speed, unit)


func _death_time(unit: Dictionary) -> void:
	clock.old += 0.25 if unit.isSq else 1.2
	clock.neu += 0.25 if unit.isSq else 0.68
	var speed := _speed
	if unit.side == "enemy" and not unit.isSq and not jt(unit.t.get("boss")):
		speed *= _enemy_pace()
	var length: float = SHIP_LENGTH.get(unit.get("cls"), 6.0 + unit.size * 14.0)
	var seconds := 0.25 * speed if unit.isSq else (0.7 + 0.014 * length) * maxf(0.4, speed) + 0.35 * speed
	_wait("explode", seconds, unit)


func emit(event: Dictionary) -> void:
	# Keep the rules' battle log and observe only events the report needs.
	if not timed and not matrix:
		return
	if event.t not in ["move", "fire", "death", "ram", "board"]:
		return
	var unit = _event_unit(event.unit)
	if unit == null:
		return
	if timed:
		match event.t:
			"move": _move_time(unit, event.path, false)
			"ram": _move_time(unit, event.path, true)
			"fire": _fire_time(unit, event)
			"death": _death_time(unit)
	if matrix:
		if event.t == "ram":
			matrix_stats.rams[unit.side] += 1
		elif event.t == "board":
			match event.result:
				"raid": matrix_stats.boards[unit.side] += 1
				"overrun": matrix_stats.overrun += 1
				"capture":
					if unit.side == "player":
						matrix_stats.caps += 1


func _event_unit(id):
	for unit in B.units:
		if unit.id == id:
			return unit
	return null


func rotateUnit(u, dir) -> void:
	_rotating = true
	super.rotateUnit(u, dir)
	_rotating = false


func fireWeapon(u, wi: int, t, opts: Dictionary = {}) -> bool:
	if not matrix:
		return super.fireWeapon(u, wi, t, opts)
	var weapon: Dictionary = u.weapons[wi]
	var intercept := jt(opts.get("intercept"))
	if not u.isSq and not intercept and canFire(u, weapon, t):
		var faction := _faction(u.fac)
		faction.fires += 1
		faction.range += hdist(u, t)
	var hp: float = t.hp
	var shield := _shield_total(t)
	var fired := super.fireWeapon(u, wi, t, opts)
	if fired:
		var key: String = ("sq:" if u.isSq else "") + weapon.id + ("(intercept)" if intercept else "")
		var stats: Dictionary = weapons.get_or_add(key, {"dmg": 0.0, "shots": 0})
		stats.dmg += maxf(0.0, hp - maxf(0.0, t.hp)) + maxf(0.0, shield - _shield_total(t))
		stats.shots += 1
	return fired


func _shield_total(unit: Dictionary) -> float:
	var total := 0.0
	for shield in unit.sh:
		total += shield
	return total


func applyHit(att, w, t, dmg: float, quad: int) -> Dictionary:
	if not matrix or t.isSq:
		return super.applyHit(att, w, t, dmg, quad)
	var absorbed := minf(dmg * (1.0 - z0(w.get("pierce"))), t.sh[quad] / ionOf(att, w))
	var result := super.applyHit(att, w, t, dmg, quad)
	var faction := _faction(t.fac)
	faction.raw += dmg
	faction.shield += absorbed
	faction.hull += result.hull
	return result


func useAbility(u, arg = null) -> bool:
	if matrix:
		var key: String = u.side + ":" + str(u.ab)
		abilities[key] = abilities.get(key, 0) + 1
	return super.useAbility(u, arg)


func startSideTurn(side) -> int:
	if not matrix:
		return super.startSideTurn(side)
	var ships := caps(side)
	var hp_before := ships.map(func(ship): return ship.hp)
	var deaths := super.startSideTurn(side)
	for i in range(ships.size()):
		var ship: Dictionary = ships[i]
		if not ship.dead and ship.hp > hp_before[i]:
			_faction(ship.fac).regen += ship.hp - hp_before[i]
	return deaths


func _faction(id: String) -> Dictionary:
	return _identity.get_or_add(id, {"fires": 0, "range": 0.0, "raw": 0.0, "shield": 0.0, "hull": 0.0,
		"regen": 0.0, "fielded": 0, "died": 0, "battles": 0, "dealt": 0.0})


func collect_matrix() -> void:
	matrix_stats.n += 1
	matrix_stats.rounds += B.round
	if not jt(B.over):
		matrix_stats.timeout += 1
	var seen := {}
	var by_id := {}
	for unit in B.units:
		by_id[unit.id] = unit
		if unit.isSq:
			continue
		seen[unit.fac] = true
		var cp: float = z0(HULLS[unit.tpl].get("cp"))
		var stats: Dictionary = hulls.get_or_add(unit.tpl, {"n": 0, "dealt": 0.0, "died": 0, "cp": cp if cp > 0 else 1})
		stats.n += 1
		stats.dealt += unit.dealt
		stats.died += int(unit.dead)
		if not jt(unit.get("transport")) and not jt(unit.get("reinf")):
			var faction := _faction(unit.fac)
			faction.fielded += 1
			faction.died += int(unit.dead and not jt(unit.get("fled")))
			faction.dealt += unit.dealt
	for unit in B.units:
		var parent = by_id.get(unit.get("parent"))
		if parent != null and not parent.isSq:
			hulls[parent.tpl].dealt += unit.dealt
	for id in seen:
		_faction(id).battles += 1
	for id in B.get("fstat", {}):
		var faction := _faction(id)
		for key in B.fstat[id]:
			faction[key] = faction.get(key, 0) + B.fstat[id][key]


func faction_report() -> Dictionary:
	var report := {}
	for id in _identity:
		var f: Dictionary = _identity[id]
		var raw := maxf(1.0, f.raw)
		var fielded := maxf(1.0, f.fielded)
		var row := {
			"range": snappedf(f.range / maxf(1.0, f.fires), 0.01),
			"shieldPct": JSM.jsround(f.shield / raw * 100),
			"cutPct": JSM.jsround(maxf(0.0, raw - f.shield - f.hull) / raw * 100),
			"hullPct": JSM.jsround(f.hull / raw * 100),
			"regenPerShip": JSM.jsround(f.regen / fielded),
			"lossPct": JSM.jsround(f.died / fielded * 100),
			"dealtPerShip": JSM.jsround(f.dealt / fielded),
		}
		for key in ["shots", "syncShots", "braces", "feed", "charge", "fade", "torpLaunch", "torpHit", "torpDodge", "torpGone", "revive"]:
			if jt(f.get(key)):
				row[key] = JSM.jsround(f[key] / maxf(1.0, f.battles) * 10) / 10.0
		report[id] = row
	return report
