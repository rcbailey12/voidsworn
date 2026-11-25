extends RefCounted
## Plain battle data, separate from the scene's hit floats and the legacy XP inputs.


static func source(att, weapon: Dictionary, hazard := "") -> Dictionary:
	return {
		"attacker_ship_id": str(att.get("id", "")) if att is Dictionary else "",
		"attacker_name": str(att.get("name", "")) if att is Dictionary else "",
		"attacker_class": ("Squadron" if att.get("isSq") else str(att.get("cls", ""))) if att is Dictionary else "",
		"attacker_side": str(att.get("side", "")) if att is Dictionary else "",
		"weapon_id": str(weapon.get("id", "")), "weapon_name": str(weapon.get("n", "")), "hazard_name": hazard,
	}


static func ship_rollup(battle: Dictionary, id: String) -> Dictionary:
	if not battle.has("ship_rollups"): battle["ship_rollups"] = {}
	var rows: Dictionary = battle["ship_rollups"]
	if not rows.has(id): rows[id] = {"kills": 0, "damage_dealt": 0.0, "damage_taken": 0.0, "captain_xp": 0}
	return rows[id]


static func rollups(battle: Dictionary) -> Dictionary:
	var rows := {}
	var totals: Dictionary = battle.get("ship_rollups", {})
	for unit in battle["units"]:
		if unit.get("isSq"): continue
		var row: Dictionary = totals.get(unit["id"], {"kills": 0, "damage_dealt": 0.0, "damage_taken": 0.0, "captain_xp": 0}).duplicate()
		var ship = unit.get("ship")
		row.merge({"ship_uid": ship["uid"] if ship is Dictionary else "", "ship_name": unit["name"],
			"ship_class": unit.get("cls"), "ship_template": unit["tpl"], "side": unit["side"],
			"hull_remaining": maxf(0.0, float(unit["hp"])), "lost": unit.get("dead") and not unit.get("fled"),
			"captain": ship["cap"].duplicate(true) if ship is Dictionary else null})
		rows[unit["id"]] = row
	return rows


static func hit(battle: Dictionary, origin: Dictionary, target: Dictionary, shield: float, hull: float) -> Dictionary:
	if not battle.has("combat_events"): battle["combat_events"] = []
	var events: Array = battle["combat_events"]
	var event := origin.duplicate()
	event.merge({"target_ship_id": target["id"], "target_side": target["side"],
		"shield_applied": shield, "hull_applied": hull, "damage_applied": shield + hull,
		"is_killing_blow": false, "round": battle["round"], "timestamp": events.size() + 1})
	events.append(event)
	ship_rollup(battle, target["id"])["damage_taken"] += event["damage_applied"]
	if not event["attacker_ship_id"].is_empty():
		ship_rollup(battle, event["attacker_ship_id"])["damage_dealt"] += event["damage_applied"]
	return event


static func kill(battle: Dictionary, run, target: Dictionary, fatal: Dictionary) -> void:
	if fatal.is_empty(): return
	fatal["is_killing_blow"] = true
	var killer: String = fatal["attacker_ship_id"]
	if not killer.is_empty(): ship_rollup(battle, killer)["kills"] += 1
	if not (target.get("ship") is Dictionary and run is Dictionary and run.get("timeline") is Array): return
	var named := {}
	var total := 0.0
	for event in battle["combat_events"]:
		if event["target_ship_id"] != target["id"]: continue
		var applied: float = event["damage_applied"]
		total += applied
		var id: String = event["attacker_ship_id"]
		if id.is_empty() or id == killer or event["attacker_side"] == event["target_side"] or applied <= 0: continue
		if not named.has(id):
			named[id] = {"ship_id": id, "ship_name": event["attacker_name"], "ship_class": event["attacker_class"], "damage_applied": 0.0}
		named[id]["damage_applied"] += applied
	var assists: Array = named.values()
	assists.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["damage_applied"] == b["damage_applied"]: return a["ship_id"] < b["ship_id"]
		return a["damage_applied"] > b["damage_applied"])
	assists = assists.slice(0, 2)
	for assist in assists: assist["damage_share"] = assist["damage_applied"] / total
	var ship: Dictionary = target["ship"]
	var record := {
		"kind": "lost_ship", "ship_id": ship["uid"], "battle_unit_id": target["id"],
		"ship_name": target["name"], "ship_class": target["cls"],
		"ship_template": target["tpl"], "captain": ship["cap"].duplicate(true),
		"killer_ship_id": killer, "killer_ship_name": fatal["attacker_name"], "killer_ship_class": fatal["attacker_class"],
		"weapon_id": fatal["weapon_id"], "weapon_name": fatal["weapon_name"], "hazard_name": fatal["hazard_name"],
		"round": fatal["round"], "battle": int(run.get("stats", {}).get("battles", 0)) + 1,
		"battle_seed": battle["seed"], "battle_node": battle.get("cfg", {}).get("node"), "sector": run["sector"],
		"final_damage": fatal["damage_applied"], "fatal_event": fatal.duplicate(true), "assists": assists,
	}
	run["timeline"].append(record)
	if not battle.has("lost_ship_records"): battle["lost_ship_records"] = []
	battle["lost_ship_records"].append(record.duplicate(true))


static func ship_returned(battle: Dictionary, run: Dictionary, id: String) -> void:
	if not battle.has("lost_ship_records"): return
	var losses: Array = battle["lost_ship_records"]
	for i in range(losses.size() - 1, -1, -1):
		var record: Dictionary = losses[i]
		if record["battle_unit_id"] != id: continue
		# A successful Eclipse reassembly removes the pending fleet loss, not the hit or kill.
		run["timeline"].erase(record)
		losses.remove_at(i)
		return
