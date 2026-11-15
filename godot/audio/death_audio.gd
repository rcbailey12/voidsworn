extends Node
# Observe the FX clock and its actual break-up result without changing visuals.
# A late fracture worker can delay the split. Never let its boom go off early.
# Issue 771: a big death carries a bed for the length of its picture, a tail, the sub-bass under the
# core flash, a mix duck under that flash, and (capital or flagship) a short beat of near-silence.
var sfx: Node
var fx: Node
var deaths: Array = []
var serial := 0
const CORE_DUCK_DB := -9.0
const CORE_DUCK_S := 0.6
const QUIET_DB := -26.0
const QUIET_S := 0.35


func watch(id: String, pos: Vector3) -> void:
	if fx == null or not fx.ships.has(id):
		return
	var ship = fx.ships[id]
	serial += 1
	var d := {"ship": ship, "pos": pos, "tag": "death_run_%d" % serial,
		"vent": false, "crack": false, "split": -1.0, "bass": false,
		"core": -1.0, "core_delay": 0.28, "tail": false, "wreck": false,
		"duck": false, "quiet": false, "quiet_at": -1.0, "capital": false, "cleanup": -1.0}
	if bool(ship.get_meta("death_hulk", false)):
		sfx.play("hulk_vent", {"pos": pos})
		return
	if ship.death_big:
		sfx.play("death_powerdown", {"pos": pos})
		var span := 0.0
		var capital := str(ship.get("death_tier")) == "capital"
		if ship.get("flagship"):
			capital = true
		if ship.has_meta("death_timeline"):
			var tl = ship.get_meta("death_timeline")
			span = float(tl.cut) + float(tl.cool)
			d.core_delay = float(tl.core_delay)
			capital = capital or str(tl.tier) == "capital"
		if span <= 0.0:
			span = 3.0 if str(ship.faction) == "chorus" else (16.0 if capital else 10.0)
		d.capital = capital
		sfx.death_bed(span, pos)
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
			d.core = d.split + float(d.core_delay)
			d.quiet_at = d.core + 0.9
			d.cleanup = d.split + 2.6
			sfx.stop_tag(d.tag)
			sfx.play("boom_l" if ship.death_big else "boom_s", {"pos": d.pos, "death": true})
			if not ship.death_big:
				sfx.play("chunk_cool", {"pos": d.pos, "delay": 0.12})
				deaths.erase(d)
		if ship.death_big and d.split >= 0.0:
			# The one capital core flash follows the actual split by .28 FX seconds.
			# Waiting for the beat to release also keeps the low end out of the dip.
			if not d.bass and fx.now >= d.core and float(fx.get("_death_slow_left")) <= 0.0:
				d.bass = true
				if not fx.reduce_flashing:
					sfx.play("bass_drop", {"pos": d.pos, "death": true})
			# The rest of the mix ducks under the core flash; the death bus stays out of it.
			if not d.duck and fx.now >= d.core:
				d.duck = true
				if not fx.reduce_flashing:
					sfx.mix_duck(CORE_DUCK_DB, CORE_DUCK_S)
			if not d.tail and fx.now >= d.split + 0.35:
				d.tail = true
				sfx.death_tail(d.pos)
			if not d.wreck and fx.now >= d.split + 0.7:
				d.wreck = true
				sfx.play("wreck", {"pos": d.pos, "death": true})
			if not d.quiet and d.capital and fx.now >= d.quiet_at:
				d.quiet = true
				sfx.quiet(QUIET_DB, QUIET_S)
			if d.wreck and fx.now >= d.cleanup:
				deaths.erase(d)


func _exit_tree() -> void:
	if is_instance_valid(sfx):
		sfx.death_beat(false)
