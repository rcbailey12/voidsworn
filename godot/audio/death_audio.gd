extends Node
# Observe the FX clock and its actual break-up result without changing visuals.
# A late fracture worker can delay the split. Never let its boom go off early.
var sfx: Node
var fx: Node
var deaths: Array = []
var serial := 0


func watch(id: String, pos: Vector3) -> void:
	if fx == null or not fx.ships.has(id):
		return
	var ship = fx.ships[id]
	serial += 1
	var d := {"ship": ship, "pos": pos, "tag": "death_run_%d" % serial,
		"vent": false, "crack": false, "split": -1.0, "bass": false}
	if bool(ship.get_meta("death_hulk", false)):
		sfx.play("hulk_vent", {"pos": pos})
		return
	if ship.death_big:
		sfx.play("death_powerdown", {"pos": pos})
	else:
		sfx.play("death_run", {"pos": pos, "tag": d.tag})
	deaths.append(d)


func _process(_delta: float) -> void:
	if not is_instance_valid(fx) or not is_instance_valid(sfx):
		return
	# FX sets this only for class-qualified R73 deaths, and clears it on hurry.
	sfx.death_beat(float(fx.get("_death_slow_left")) > 0.0)
	for d in deaths.duplicate():
		var ship = d.ship
		if fx.ships.get(ship.id) != ship or not is_instance_valid(ship.root):
			sfx.stop_tag(d.tag)
			deaths.erase(d)
			continue
		var age: float = fx.now - float(ship.get_meta("death_start", fx.now))
		if ship.death_big:
			if age >= 0.25 and not d.vent:
				d.vent = true
				sfx.play("death_vent", {"pos": d.pos})
			if age >= 0.4 and not d.crack:
				d.crack = true
				sfx.play("death_crack", {"pos": d.pos, "variant": ship.faction})
		if d.split < 0.0 and bool(ship.get_meta("death_hidden", false)):
			d.split = fx.now
			sfx.stop_tag(d.tag)
			sfx.play("boom_l" if ship.death_big else "boom_s", {"pos": d.pos, "death": true})
			if not ship.death_big:
				sfx.play("chunk_cool", {"pos": d.pos, "delay": 0.12})
				deaths.erase(d)
		if ship.death_big and d.split >= 0.0:
			# The one capital core flash follows the actual split by .28 FX seconds.
			# Waiting for the beat to release also keeps the low end out of the dip.
			if not d.bass and fx.now >= d.split + 0.28 and float(fx.get("_death_slow_left")) <= 0.0:
				d.bass = true
				if not fx.reduce_flashing:
					sfx.play("bass_drop", {"pos": d.pos, "death": true})
			if fx.now >= d.split + 0.7:
				sfx.play("wreck", {"pos": d.pos, "death": true})
				deaths.erase(d)


func _exit_tree() -> void:
	if is_instance_valid(sfx):
		sfx.death_beat(false)
