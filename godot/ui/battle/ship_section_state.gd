extends RefCounted
## Projects the battle's own section and offline system state for both plate and KEEL.

const KEYS := ["prow", "mid", "eng"]
const NAMES := ["Prow", "Mid", "Engines"]
const CELLS := ["PROW", "MID", "ENG"]


static func read(unit: Dictionary) -> Array[Dictionary]:
	var sections: Array[Dictionary] = []
	var source = unit.get("sec")
	if not source is Dictionary:
		return sections   # Wings have hull but no ship sections.
	for i in KEYS.size():
		var part: Dictionary = source[KEYS[i]]
		var fraction := clampf(float(part["hp"]) / maxf(1.0, float(part["max"])), 0.0, 1.0)
		var lost := bool(part.get("broken", false))
		var disabled_systems := PackedStringArray()
		var short := ""
		if lost:
			# The current view exposes actual offline slots, not a separate disabled_systems field.
			# Count permanent section outages only, not a reload or temporary critical hit.
			for w in unit["weapons"]:
				if w.get("off") == null or int(w["off"]) < 99:
					continue
				if not ((i == 0 and w["arc"] == "F") or (i == 1 and w["arc"] in ["P", "S"])):
					continue
				if short.is_empty():
					short = {"lance": "LANCE", "torp": "TORP", "torpedo": "TORP", "missile": "MISSILE"}.get(w["kind"], "GUN")
				disabled_systems.append(str(w["name"]) if w.get("name") != null else str(w["kind"]).capitalize())
			if i == 1 and unit["shieldOff"] and float(unit["shMax"]) > 0.0:
				disabled_systems.append("shield generator")
				if short.is_empty():
					short = "SHLD GEN"
			if not short.is_empty():
				var extra := disabled_systems.size() - 1
				short += " +%d OFF" % extra if extra > 0 else " OFF"
		var line := ""
		if lost:
			if i == 2:
				# The rules leave steerage speed and one turn. Do not claim thrust is zero.
				disabled_systems.append("full thrust")
				disabled_systems.append("evasion")
				short = "DRIVE HIT"
				line = "Engines lost: full thrust and evasion disabled."
			elif not disabled_systems.is_empty():
				line = "%s lost: %s disabled." % [NAMES[i], ", ".join(disabled_systems)]
			else:
				short = CELLS[i] + " LOST"
				line = "%s lost." % NAMES[i]
		sections.append({"fraction": fraction, "lost": lost, "cell": short if lost else CELLS[i],
			"disabled_systems": disabled_systems, "loss": line})
	return sections


static func losses(sections: Array[Dictionary]) -> PackedStringArray:
	var lines := PackedStringArray()
	for part in sections:
		if not part["loss"].is_empty():
			lines.append(part["loss"])
	return lines
