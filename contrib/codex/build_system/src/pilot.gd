extends RefCounted
const KEYS = ["adm.vaelen.A1.0", "adm.vaelen.A1.1"]
static func snapshot(meta: Dictionary, id: String) -> Variant:
	if id != "vaelen" or not (meta.get("opts") is Dictionary) or meta["opts"].get("lineagePilot") != true: return null
	var state = meta.get("lineageV1")
	if not (state is Dictionary) or state.get("version") != 1 or not (state.get("lines") is Dictionary): return null
	var line = state["lines"].get("vaelen")
	if not (line is Dictionary): return null
	var q = line.get("xpQ"); var picks = line.get("picks")
	if not (q is int or q is float) or not is_finite(q) or floor(q) != q or q < 0 or q > 2400 or not (picks is Array) or picks.size() > 1 or not line.has("capstone") or line["capstone"] != "": return null
	if picks.size() > 0 and (q < 300 or not KEYS.has(picks[0])): return null
	return {"version": 1, "admiral": id, "xpQ": q, "picks": picks.duplicate()}
static func mode(run: Variant, side: String, c: Dictionary) -> Variant:
	if side != "player" or not (run is Dictionary) or run.get("admiral") != "vaelen" or run.get("cmdOverride") != null or c.get("id") != "barrage": return null
	var s = run.get("lineagePilot")
	if not (s is Dictionary) or s.get("version") != 1 or s.get("admiral") != "vaelen": return null
	var q = s.get("xpQ"); var picks = s.get("picks")
	if not (q is int or q is float) or not is_finite(q) or floor(q) != q or q < 300 or q > 2400 or not (picks is Array) or picks.size() != 1: return null
	return picks[0] if KEYS.has(picks[0]) else null
static func intent(run: Variant, side: String, c: Dictionary, battle: Dictionary) -> Dictionary:
	var selected = mode(run, side, c); var raw = battle.get("lineageIntent")
	if selected != KEYS[1] or raw == null: return {"ok": true, "mode": selected, "weapons": {}}
	if not (raw is Dictionary): return {"ok": false}
	var weapons = {}
	for id in raw:
		var unit = null; var index = raw[id]
		for u in battle["units"]:
			if u.get("id") == id and u.get("side") == "player" and not u.get("dead", false) and not u.get("isSq", false): unit = u; break
		if unit == null: return {"ok": false}
		if index != null and (not (index is int or index is float) or not is_finite(index) or floor(index) != index or index < 0 or index >= unit["weapons"].size()): return {"ok": false}
		if index != null and (unit["weapons"][int(index)].get("k") == "flak" or unit["weapons"][int(index)].get("off", 0) > 0): return {"ok": false}
		weapons[id] = index
	return {"ok": true, "mode": selected, "weapons": weapons}
static func allows(context: Dictionary, u: Dictionary, index: int) -> bool:
	return context["mode"] != KEYS[1] or context["weapons"].get(u["id"]) == null or context["weapons"][u["id"]] == index
static func factor(context: Dictionary, u: Dictionary, w: Dictionary, _target: Dictionary, distance: float) -> float:
	if context["mode"] == KEYS[0]: return 1.2 if distance > float(w["r"]) / 2.0 else 1.0
	if context["mode"] == KEYS[1] and context["weapons"].get(u["id"]) != null: return 1.25
	return 1.0
