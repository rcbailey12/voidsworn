extends RefCounted
## Player policy from sim3d.js. All actions and evaluations go through the live rules.

const Rules = preload("res://rules/rules.gd")

var rules: Rules
var command_enabled := true
var brace_enabled := true


func _init(battle_rules: Rules) -> void:
	rules = battle_rules


func bot_turn() -> int:
	var activations := 0
	rules.swarmPhase("player")
	for ship in rules.caps("player"):
		if rules.B.over or ship.dead:
			continue
		activations += 1
		_use_ability(ship, true)
		if not _move(ship, true):
			break
		_fire(ship)
		if rules.B.over:
			break
	return activations


func bot_unit(ship: Dictionary) -> void:
	if rules.B.over or ship.dead:
		return
	if rules.canStance(ship):
		rules.aiStance(ship)
	bot_command()
	if rules.B.over or ship.dead:
		return
	_use_ability(ship, false)
	if not ship.isSq:
		rules.tacticRam(ship)
	if rules.B.over or ship.dead or not _move(ship, false):
		return
	if not ship.isSq and rules.tacticBoard(ship):
		ship.activated = true
		return
	_fire(ship)
	if rules.B.over or ship.dead or ship.isSq:
		return
	if brace_enabled and ship.hp < ship.maxHp * 0.5 and not ship.weapons.any(_fired):
		if rules.canOrder(ship, "brace") and rules.evalThreat(ship, rules.alive("enemy")) > 10:
			rules.giveOrder(ship, "brace")
	if rules.canFade(ship):
		rules.fadeMove(ship)
	ship.activated = true


func bot_command() -> void:
	if not command_enabled or not rules.canCommand("player"):
		return
	var command: Dictionary = rules.commandFor("player")
	var players := rules.caps("player")
	var enemies := rules.caps("enemy")
	if players.is_empty() or enemies.is_empty():
		return
	var near := 0
	var hp := 0.0
	var max_hp := 0.0
	var hurt := false
	for enemy in enemies:
		if players.any(func(ship): return rules.hdist(ship, enemy) <= 8):
			near += 1
	for ship in players:
		hp += ship.hp
		max_hp += ship.maxHp
		hurt = hurt or ship.hp < ship.maxHp * 0.5
	var id: String = command.id
	var offensive := id in ["barrage", "hunt", "scramble", "surge"]
	if (offensive and (near >= 2 or rules.B.round >= 4)) or (id == "restore" and hp < max_hp * 0.6) or (id == "iron" and (hurt or near >= 2)) or rules.B.round >= 6:
		rules.useCommand("player")


func _use_ability(ship: Dictionary, classic: bool) -> void:
	if not rules.jt(ship.get("ab")) or not rules.canAbility(ship):
		return
	match ship.ab:
		"launch":
			var hexes := rules.launchHexes(ship)
			if not hexes.is_empty():
				var kind: String
				if classic or ship.fac == "voidsworn":
					kind = "fighter" if rules.rnd() < 0.5 else "bomber"
				else:
					kind = rules.wingKind(ship)
				rules.useAbility(ship, {"hex": hexes[0], "kind": kind})
		"nova":
			var enemies := rules.alive("enemy")
			var players := rules.alive("player")
			for hex in rules.novaTargets(ship):
				if enemies.any(func(enemy): return rules.hdist(enemy, hex) <= 1) and not players.any(func(player): return rules.hdist(player, hex) <= 1):
					rules.useAbility(ship, {"hex": hex})
					break
		_:
			rules.useAbility(ship)


func _move(ship: Dictionary, classic: bool) -> bool:
	var foes := rules.alive("enemy")
	if foes.is_empty():
		return false
	var ready: Array = ship.weapons.filter(rules.weaponReady)
	var field := rules.pathField(foes.filter(func(foe): return not foe.isSq)) if classic else {}
	var states: Array = rules.computeReach(ship, true).states
	var best: Dictionary = {}
	var best_score := -INF
	rules.eval_begin()
	for state in states:
		var view := rules.stateView(ship, state)
		var offense := rules.evalOffense(view, ready, foes)
		var threat := rules.evalThreat(view, foes)
		var distance := _nearest(view, foes)
		if classic:
			distance = maxf(distance, rules.fieldDist(field, view, distance))
		var approach_cost := distance * 3.0 if offense <= 0 else 0.0
		var score := offense - threat * 0.3 - approach_cost - _objective_cost(view, foes) - rules.syncPull(ship, view) * 1.5
		if score > best_score:
			best_score = score
			best = state
	rules.eval_end()
	if not best.is_empty() and not best.path.is_empty():
		rules.moveUnit(ship, best)
	return true


func _nearest(view: Dictionary, ships: Array) -> float:
	var distance := INF
	for ship in ships:
		distance = minf(distance, rules.hdist(view, ship))
	return distance


func _objective_cost(view: Dictionary, enemies: Array) -> float:
	var objective = rules.B.get("obj")
	if objective == null:
		return 0.0
	match objective.type:
		"hold":
			return rules.hdist(view, objective.hex) * 1.6
		"break":
			return maxf(0.0, objective.exitC - view.q - floorf(view.r / 2.0)) * 6.0
		"defend":
			return maxf(0.0, rules.hdist(view, objective.hex) - 3.0) * 1.2
		"intercept":
			var transports := enemies.filter(func(enemy): return rules.jt(enemy.get("transport")))
			return 0.0 if transports.is_empty() else _nearest(view, transports) * 2.5
		"hunt":
			for enemy in enemies:
				if rules.jt(enemy.get("flagship")):
					return rules.hdist(view, enemy) * 2.5
	return 0.0


func _fire(ship: Dictionary) -> void:
	for i in range(ship.weapons.size()):
		var weapon: Dictionary = ship.weapons[i]
		var best: Dictionary = {}
		var best_value := 0.0
		for target in rules.alive("enemy"):
			if not rules.canFire(ship, weapon, target):
				continue
			var hit := rules.expectedVs(ship, weapon, target)
			var value: float = hit.hull + hit.shield * 0.3 + (20.0 if hit.hull >= target.hp else 0.0)
			if value > best_value:
				best = target
				best_value = value
		if not best.is_empty():
			rules.fireWeapon(ship, i, best)
		if rules.B.over:
			return


func _fired(weapon: Dictionary) -> bool:
	return rules.jt(weapon.get("fired"))
