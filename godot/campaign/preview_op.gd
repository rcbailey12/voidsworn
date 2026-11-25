extends RefCounted
## Build an action plan from current yard state. Only campaign.gd applies the plan.

const STATS := {"hp": "hull", "maxHp": "max_hull", "shMax": "shield_pool", "regen": "shield_regen",
	"armor": "armor", "speed": "speed", "turns": "turns", "ev": "evasion", "aim": "aim", "crit": "crit",
	"dmg": "weapon_damage_multiplier", "hangar": "hangar", "hullRegen": "hull_regen"}


static func plan(c, action: String, key: String, slot: int) -> Dictionary:
	var p := {"action": action, "key": key, "ship": {}, "entries": [], "rows": [], "price": 0.0,
		"purse": "", "reason": "", "hold_index": slot, "captured": false}
	if c.RUN == null:
		p["reason"] = "No active fleet."
		return _finish(p)
	var run: Dictionary = c.RUN
	var stock: Dictionary = c.yard_node.get("stock", {}) if c.yard_node is Dictionary else {}
	var ship = c._ship(key)
	match action:
		"repair", "repairAll":
			p["purse"] = c.hullKey()
			var ships: Array = run["fleet"] if action == "repairAll" else ([] if ship == null else [ship])
			var missing := 0.0
			for sh in ships:
				var after: Dictionary = sh.duplicate(true)
				var full: float = c.derive(sh)["maxHp"]
				missing += full - float(sh["hp"])
				after["hp"] = full
				_entry(p, c, sh, after)
			p["price"] = ceil(maxf(0.0, missing) / 2.0 * c.priceMult())
			if ships.is_empty(): p["reason"] = "No ship to repair."
			elif missing <= 0: p["reason"] = "Hull already full."
		"upgradeMk", "refit":
			if ship == null:
				p["reason"] = "Select a ship."
				return _finish(p)
			var after: Dictionary = ship.duplicate(true)
			if action == "upgradeMk":
				p["purse"] = c.hullKey()
				p["price"] = c.mkCost(ship)
				if float(ship["mk"]) >= 3: p["reason"] = "Maximum Mark reached."
				else: after["mk"] = float(after["mk"]) + 1
			else:
				p["purse"] = "hold"
				if slot < 0 or slot >= run["inventory"].size(): p["reason"] = "Refit unavailable."
				elif not c.canFitModule(ship, run["inventory"][slot]): p["reason"] = "This ship cannot fit that refit."
				else:
					p["price"] = 1.0
					after["mods"].append(run["inventory"][slot])
			if p["reason"].is_empty(): c.adjustHull(after, c.derive(ship)["maxHp"], c.derive(after)["maxHp"])
			_entry(p, c, ship, after)
		"buyHull":
			if not c.HULLS.has(key):
				p["reason"] = "Unknown hull."
				return _finish(p)
			var captured: Array = stock["cap"] if stock.get("cap") is Array else []
			var t: Dictionary = c.HULLS[key]
			p["captured"] = captured.has(key)
			p["purse"] = c.hullKey()
			p["price"] = c.capturedHullPrice(t) if p["captured"] else c.jsround(float(t["cost"]) * c.priceMult())
			var after: Dictionary = c.incoming_ship(key, p["captured"])
			_entry(p, c, {}, after)
			if not (p["captured"] or stock.get("hulls", []).has(key)): p["reason"] = "This yard does not sell that hull."
			elif not p["captured"] and c.jt(t.get("unique")) and run["fleet"].any(func(s): return s["tpl"] == key):
				p["reason"] = "That unique hull is already in the fleet."
			elif c.fleetCP() + float(t["cp"]) > float(run["cpCap"]): p["reason"] = "Not enough command points."
		"buyMod":
			var mods: Array = stock.get("mods", [])
			if slot < 0 or slot >= mods.size():
				p["reason"] = "Refit unavailable."
				return _finish(p)
			p["key"] = mods[slot]
			p["price"] = c.jsround(float(c.MODULES[p["key"]]["cost"]) * c.priceMult())
			p["purse"] = c.shopKey(p["price"])
			if c._has_num(stock["sold"], slot): p["reason"] = "Refit already sold."
			_row(p, "refits_in_hold", run["inventory"].size(), run["inventory"].size() + 1)
		_:
			p["reason"] = "Unknown shipyard action."
	if p["reason"].is_empty() and p["purse"] in ["credits", "bio"] and float(run.get(p["purse"], 0)) < p["price"]:
		p["reason"] = "Not enough biomass." if p["purse"] == "bio" else "Not enough credits."
	return _finish(p)


static func _entry(p: Dictionary, c, before: Dictionary, after: Dictionary) -> void:
	p["ship"] = after
	p["entries"].append({"before": before, "after": after})
	var old := _stats(c, before) if not before.is_empty() else {}
	var new := _stats(c, after)
	if p["action"] == "repairAll":
		_row(p, "hull", old["hull"], new["hull"], after["uid"])
		return
	for key in new:
		_row(p, key, old.get(key, 0.0), new[key], after["uid"], key == "command_points" or key.ends_with(".reload"))


static func _stats(c, ship: Dictionary) -> Dictionary:
	var d: Dictionary = c.derive(ship)
	var out := {"hull": ship["hp"], "mark": ship["mk"], "refit_count": ship["mods"].size(),
		"command_points": c.HULLS[ship["tpl"]]["cp"]}
	for field in STATS:
		if field != "hp": out[STATS[field]] = d[field]
	for i in range(d["weapons"].size()):
		var w: Dictionary = d["weapons"][i]
		for pair in [["dmg", "damage"], ["shots", "shots"], ["r", "range"], ["opt", "optimal_range"], ["cd", "reload"]]:
			out["weapon.%d.%s" % [i, pair[1]]] = w.get(pair[0], 0) * (float(d["dmg"]) if pair[0] == "dmg" else 1.0)
	return out


static func _row(p: Dictionary, key: String, old: float, new: float, uid := "", lower_is_better := false) -> void:
	var delta := new - old
	p["rows"].append({"stat_key": key, "old": old, "new": new, "delta": delta,
		"is_better": (delta < 0 if lower_is_better else delta > 0), "ship_uid": uid})


static func _finish(p: Dictionary) -> Dictionary:
	if p["rows"].is_empty(): _row(p, "action", 0.0, 0.0)
	for row in p["rows"]:
		row["cost"] = p["price"]
		row["currency"] = p["purse"]
		row["disabled_reason"] = p["reason"]
	return p
