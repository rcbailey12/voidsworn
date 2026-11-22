extends Node
# Observe the FX clock and its actual break-up result without changing visuals.
# A late fracture worker can delay the split. Never let its boom go off early.
# Issue 771: a big death carries a bed for the length of its picture, a tail, the sub-bass under the
# core flash, a mix duck under that flash, and (capital or flagship) a short beat of near-silence.
# Issue 1238 (F5.1, F5.4): every death cue carries the dying ship's faction, so a cue with a faction variant in
# cues.json plays that faction's own sound (Chorus wet and breathing, Glasswright glass and tone) instead of steel.
# A Chorus hull's skin tears just before it ruptures, not at a fixed .4 s. Issue 1385: the bed and the sub-drop carry
# the faction too (no variants yet; a later faction sound lands in cues.json alone).
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
	var fac := str(ship.faction)
	var d := {"ship": ship, "pos": pos, "tag": "death_run_%d" % serial, "fac": fac, "crack_at": 0.4,
		"vent": false, "crack": false, "split": -1.0, "bass": false,
		"core": -1.0, "core_delay": 0.28, "tail": false, "wreck": false,
		"duck": false, "quiet": false, "quiet_at": -1.0, "capital": false, "cleanup": -1.0}
	if bool(ship.get_meta("death_hulk", false)):
		sfx.play("hulk_vent", {"pos": pos, "variant": fac})
		return
	if ship.death_big:
		sfx.play("death_powerdown", {"pos": pos, "variant": fac})
		var span := 0.0
		var capital := str(ship.get("death_tier")) == "capital"
		if ship.get("flagship"):
			capital = true
		if ship.has_meta("death_timeline"):
			var tl = ship.get_meta("death_timeline")
			span = float(tl.cut) + float(tl.cool)
			d.core_delay = float(tl.core_delay)
			capital = capital or str(tl.tier) == "capital"
			if bool(ship.get_meta("death_organic", false)):
				d.crack_at = maxf(0.4, float(tl.cut) - 0.3)
				span = float(tl.cut) + 3.0   # a Chorus wreck has no hot faces to cool: the bed ends with the spill
		if span <= 0.0:
			span = 3.0 if str(ship.faction) == "chorus" else (16.0 if capital else 10.0)
		d.capital = capital
		sfx.death_bed(span, pos, fac)
	else:
		sfx.play("death_run", {"pos": pos, "tag": d.tag, "variant": fac})
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
				sfx.play("death_vent", {"pos": d.pos, "variant": d.fac})
			if age >= float(d.crack_at) and not d.crack and d.split < 0.0:
				d.crack = true
				sfx.play("death_crack", {"pos": d.pos, "variant": d.fac})
		if d.split < 0.0 and bool(ship.get_meta("death_hidden", false)):
			d.split = fx.now
			d.core = d.split + float(d.core_delay)
			d.quiet_at = d.core + 0.9
			d.cleanup = d.split + 2.6
			sfx.stop_tag(d.tag)
			sfx.play("boom_l" if ship.death_big else "boom_s", {"pos": d.pos, "death": true, "variant": d.fac})
			if not ship.death_big:
				sfx.play("chunk_cool", {"pos": d.pos, "delay": 0.12, "variant": d.fac})
				deaths.erase(d)
		if ship.death_big and d.split >= 0.0:
			# The one capital core flash follows the actual split by .28 FX seconds.
			# Waiting for the beat to release also keeps the low end out of the dip.
			if not d.bass and fx.now >= d.core and float(fx.get("_death_slow_left")) <= 0.0:
				d.bass = true
				if not fx.reduce_flashing:
					sfx.play("bass_drop", {"pos": d.pos, "death": true, "variant": d.fac})
			# The rest of the mix ducks under the core flash; the death bus stays out of it.
			if not d.duck and fx.now >= d.core:
				d.duck = true
				if not fx.reduce_flashing:
					sfx.mix_duck(CORE_DUCK_DB, CORE_DUCK_S)
			if not d.tail and fx.now >= d.split + 0.35:
				d.tail = true
				sfx.death_tail(d.pos, d.fac)
			if not d.wreck and fx.now >= d.split + 0.7:
				d.wreck = true
				sfx.play("wreck", {"pos": d.pos, "death": true, "variant": d.fac})
			if not d.quiet and d.capital and fx.now >= d.quiet_at:
				d.quiet = true
				sfx.quiet(QUIET_DB, QUIET_S)
			if d.wreck and fx.now >= d.cleanup:
				deaths.erase(d)


func _exit_tree() -> void:
	if is_instance_valid(sfx):
		sfx.death_beat(false)
