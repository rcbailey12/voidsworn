extends RefCounted
# F1 play log (feel pass brief, "Play log"): one entry per player activation, so the next playtest gives real data.
# Presentation only: nothing here reads or changes the rules. battle.gd opens an entry when a ship is handed over or
# picked, notes what the player does with it, and closes it when the ship's activation ends.
#
# An entry: {r (round), ship (id), name, tpl, cls, how (auto: the game handed it over; pick: clicked on the board;
# roster: picked in the fleet list; tab: Next ship), think_ms (hand-over to the first action), dur_ms (hand-over to the
# end), acts: [{k, at (ms after the hand-over), ...}] (move, attack_move, fire, brace, ability, ram, board, rotate,
# stance, command), plans (move previews placed), targets (enemies targeted), inspects (enemies or ships looked at),
# cancels (a planned move or target dropped with Esc or a click elsewhere), end (space, button, nothing_left (the game
# ended it: nothing left to do), rules (the rules ended it: no movement and no gun left, or braced), died, switched (the
# player picked another ship before acting), battle_end)}

var tips: Array = []
var acts: Array = []
var cur: Dictionary = {}
var hurries := 0              # Enter or Space presses that hurried the enemy's turn
var t0_battle := 0


func _init() -> void:
	t0_battle = Time.get_ticks_msec()


func teaching(kind: String, id: String, round_n: int, activation: String, why := "") -> void:
	tips.append({"k": kind, "id": id, "r": round_n, "activation": activation, "why": why, "at": Time.get_ticks_msec() - t0_battle})


func is_open() -> bool:
	return not cur.is_empty()


func open_for() -> String:
	return str(cur.get("ship", ""))


func open(u: Dictionary, round_n: int, how: String) -> void:
	if not cur.is_empty():
		if str(cur["ship"]) == str(u.get("id", "")):
			return
		close("switched")
	cur = {"r": round_n, "ship": str(u.get("id", "")), "name": str(u.get("name", "")), "tpl": str(u.get("tpl", "")), "cls": str(u.get("cls", "")),
		"how": how, "t0": Time.get_ticks_msec(), "acts": [], "plans": 0, "targets": 0, "inspects": 0, "cancels": 0}


func act(kind: String, d := {}) -> void:
	if cur.is_empty():
		return
	var at := Time.get_ticks_msec() - int(cur["t0"])
	if not cur.has("think_ms"):
		cur["think_ms"] = at
	var e := d.duplicate()
	e["k"] = kind
	e["at"] = at
	(cur["acts"] as Array).append(e)


func note(field: String) -> void:
	if cur.is_empty():
		return
	cur[field] = int(cur.get(field, 0)) + 1


func has_acted() -> bool:
	return not cur.is_empty() and not (cur["acts"] as Array).is_empty()


func close(end: String) -> void:
	if cur.is_empty():
		return
	var dur := Time.get_ticks_msec() - int(cur["t0"])
	cur["dur_ms"] = dur
	if not cur.has("think_ms"):
		cur["think_ms"] = dur
	cur["end"] = end
	cur.erase("t0")
	acts.append(cur)
	cur = {}


# the whole battle's log: the activations, the enemy's time per round (the player's wait) and the hurries
func summary(result: String, rounds: int, enemy_s: Dictionary) -> Dictionary:
	close("battle_end")
	var es := {}
	for k in enemy_s:
		es[str(k)] = snappedf(float(enemy_s[k]), 0.01)
	return {"v": 1, "result": result, "rounds": rounds, "secs": snappedf((Time.get_ticks_msec() - t0_battle) / 1000.0, 0.1), "hurries": hurries, "enemy_s": es, "acts": acts, "tips": tips}
