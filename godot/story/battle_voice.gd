extends RefCounted
# Admiral lines in battle (R37 step 1). The battle scene makes one per battle and feeds it the rules' events; it answers
# with lines for the existing text boxes (the battle log, and the end card). Presentation only: it reads the event stream
# and view() copies, never rules state, and never draws from the rules PRNG (the opening line is picked from the seed).
#
#   var voice = load("res://story/battle_voice.gd").new()
#   voice.setup_from_rules(api.R, api.view())          # or voice.setup(view, info) with the info fields below
#   for l in voice.opening(): hud.add_log(l.text, l.kind)
#   ...for each event e the scene plays: for l in voice.on_event(e): hud.add_log(l.text, l.kind)
#   var end_line: String = voice.closing(win)           # one line for the end card body
#
# Each line: {text, kind, who, moment}. kind is a battle-log colour class ("s" gilt for your admiral, "e" red for the
# enemy), so the existing log colours it with no change.

var V: Dictionary = {}          # voices.json
var info := {}                  # admiral, fac, kind, enemy_fac, sector, seed, nem {name, title, fac} or null
var units := {}                 # id -> {side, flagship, squadron, nemesis, hp, maxHp, name}
var said := {}                  # moment -> true (each big moment speaks once per battle)
var flag_id := ""               # your flagship's unit id


func _init() -> void:
	var f := FileAccess.open("res://story/data/voices.json", FileAccess.READ)
	if f != null:
		var d = JSON.parse_string(f.get_as_text())
		V = d if d is Dictionary else {}


# Reads what it needs from the rules object (godot/rules/rules.gd) without changing it.
func setup_from_rules(R, view: Dictionary) -> void:
	var run = R.RUN if "RUN" in R else null
	var B = R.B if "B" in R else null
	var cfg: Dictionary = B.get("cfg", {}) if B is Dictionary and B.get("cfg") is Dictionary else {}
	var nem = B.get("nem") if B is Dictionary else null
	var adm := str(run.get("admiral", "")) if run is Dictionary else ""
	var ADM = R.ADMIRALS if "ADMIRALS" in R else {}
	var FAC = R.FACTIONS if "FACTIONS" in R else {}
	setup(view, {
		"admiral": adm,
		"admiral_name": str(ADM.get(adm, {}).get("n", adm)) if ADM is Dictionary else adm,
		"enemy_name": str(FAC.get(str(cfg.get("fac", "")), {}).get("n", "the enemy")) if FAC is Dictionary else "the enemy",
		"fac": str(run.get("fac", "")) if run is Dictionary else "",
		"sector": int(run.get("sector", 1)) if run is Dictionary else 1,
		"kind": str(cfg.get("kind", "")),
		"enemy_fac": str(cfg.get("fac", "")),
		"seed": int(B.get("seed", cfg.get("seed", 0))) if B is Dictionary and (B.get("seed") != null or cfg.get("seed") != null) else 0,
		"nem": nem if nem is Dictionary else null,
		"flagship_name": "",
	})


func setup(view: Dictionary, inf: Dictionary) -> void:
	info = inf
	units.clear()
	said.clear()
	flag_id = ""
	for u in view.get("units", []):
		units[str(u["id"])] = {"side": str(u.get("side", "")), "flagship": bool(u.get("flagship", false)), "squadron": bool(u.get("squadron", false)),
			"nemesis": bool(u.get("nemesis", false)), "hp": float(u.get("hp", 0)), "maxHp": float(u.get("maxHp", 1)), "name": str(u.get("name", ""))}
		if units[str(u["id"])]["side"] == "player" and units[str(u["id"])]["flagship"] and flag_id == "":
			flag_id = str(u["id"])
			if str(info.get("flagship_name", "")) == "":
				info["flagship_name"] = str(u.get("name", ""))


# ---------------------------------------------------------------- lines

func admiral_name() -> String:
	var a: String = str(info.get("admiral", ""))
	return str(info.get("admiral_name", a))


func _fill(t: String) -> String:
	var nem = info.get("nem")
	var rival := ""
	if nem is Dictionary:
		rival = ("%s %s" % [str(nem.get("title", "")), str(nem.get("name", ""))]).strip_edges()
	return t.replace("{flagship}", str(info.get("flagship_name", "the flagship"))).replace("{rival}", rival if rival != "" else "the enemy commander").replace("{enemy}", str(info.get("enemy_name", "the enemy")))


func adm_text(moment: String) -> String:
	var A: Dictionary = V.get("admirals", {}).get(str(info.get("admiral", "")), {})
	var t = A.get(moment)
	if t is Array:
		if t.is_empty():
			return ""
		t = t[absi(int(info.get("seed", 0))) % t.size()]
	return _fill(str(t)) if t != null else ""


func _adm_line(moment: String) -> Array:
	var t := adm_text(moment)
	if t == "":
		return []
	return [{"text": "%s: \"%s\"" % [admiral_name(), t], "kind": "s", "who": "admiral", "moment": moment}]


func _enemy_line(who: String, moment: String, text: String) -> Array:
	if text == "":
		return []
	return [{"text": "%s: \"%s\"" % [who, _fill(text)], "kind": "e", "who": "enemy", "moment": moment}]


var rival = preload("res://story/rival.gd").new()


func _ctx() -> Dictionary:
	return {"you": admiral_name(), "flagship": str(info.get("flagship_name", "your flagship"))}


# The Nemesis's line for a moment (godot/story/rival.gd: pools by his faction, personality, scars and memory).
func _nem_text(k: String) -> String:
	var nem = info.get("nem")
	if not (nem is Dictionary):
		return ""
	if k == "open":
		return rival.opening(nem, int(info.get("sector", 1)), int(info.get("seed", 0)), _ctx())
	return rival.line(k, nem, int(info.get("seed", 0)), _ctx())


func _nem_name() -> String:
	var nem = info.get("nem")
	if not (nem is Dictionary):
		return ""
	return ("%s %s" % [str(nem.get("title", "")), str(nem.get("name", ""))]).strip_edges()


func _boss_name() -> String:
	for id in units:
		if units[id]["side"] == "enemy" and units[id]["flagship"]:
			return str(units[id]["name"])
	return "The enemy flagship"


# The battle's opening lines: the enemy's hail first (a Nemesis or a sector flagship), then your admiral.
func opening() -> Array:
	var out: Array = []
	if info.get("nem") is Dictionary:
		out += _enemy_line(_nem_name(), "nem_hail", _nem_text("open"))
		out += _adm_line("nemesis")
	elif str(info.get("kind", "")) == "boss":
		out += _enemy_line(_boss_name(), "boss_hail", str(V.get("factions", {}).get(str(info.get("enemy_fac", "")), {}).get("boss_hail", "")))
		out += _adm_line("boss")
	else:
		out += _adm_line("start")
	return out


# One rules event (godot/rules/API.md, "The event stream"). Returns the lines it earns, often none.
func on_event(e: Dictionary) -> Array:
	var out: Array = []
	match str(e.get("t", "")):
		"hit":
			var id := str(e.get("target", ""))
			if units.has(id):
				units[id]["hp"] = float(units[id]["hp"]) - float(e.get("hull", 0))
				if id == flag_id and not said.has("flag_hurt") and float(units[id]["hp"]) > 0 and float(units[id]["hp"]) < 0.4 * float(units[id]["maxHp"]):
					said["flag_hurt"] = true
					out += _adm_line("flag_hurt")
		"death":
			var id := str(e.get("unit", ""))
			var u: Dictionary = units.get(id, {})
			if u.is_empty() or bool(u.get("squadron", false)):
				return out
			u["hp"] = 0.0
			if u["side"] == "enemy" and (bool(u.get("nemesis", false)) and info.get("nem") is Dictionary):
				if not said.has("nem_down"):
					said["nem_down"] = true
					out += _enemy_line(str(u["name"]), "nem_down", _nem_text("death" if int(info.get("sector", 1)) >= 3 else "beaten"))
					out += _adm_line("kill_flag")
			elif u["side"] == "enemy" and bool(u.get("flagship", false)):
				if not said.has("flag_down"):
					said["flag_down"] = true
					out += _enemy_line(str(u["name"]), "boss_down", str(V.get("factions", {}).get(str(info.get("enemy_fac", "")), {}).get("boss_down", "")))
					out += _adm_line("kill_flag")
			elif u["side"] == "player" and not said.has("lost"):
				said["lost"] = true
				if info.get("nem") is Dictionary:
					out += _enemy_line(_nem_name(), "nem_kill", _nem_text("kill"))
				out += _adm_line("lost")
		"nem_signature", "nem_act":
			# stream B's faction behaviour for the Nemesis (R42: a Corsair raids and flees, the Deathless one returns once,
			# an Ithar duels and withdraws, the Chorus feeds on your losses, Hegemony reinforcements, a Voidsworn challenge);
			# whichever event name stream B gives it, it speaks once per battle
			if info.get("nem") is Dictionary and not said.has("nem_signature"):
				said["nem_signature"] = true
				out += _enemy_line(_nem_name(), "nem_signature", _nem_text("signature"))
		"command":
			if str(e.get("side", "")) == "player" and not said.has("command"):
				said["command"] = true
				out += _adm_line("command")
		"board":
			# a boarded ship changes side in the rules; keep the side here in step so later deaths speak for the right fleet
			if str(e.get("result", "")) == "capture":
				var t := str(e.get("target", ""))
				var a := str(e.get("unit", ""))
				if units.has(t) and units.has(a):
					units[t]["side"] = units[a]["side"]
	return out


# One line for the end card (your admiral's win or loss line; against the Nemesis on a loss, his gloat).
func closing(win: bool) -> String:
	if not win and info.get("nem") is Dictionary and _nem_text("gloat") != "":
		return "%s: \"%s\"" % [_nem_name(), _nem_text("gloat")]
	var t := adm_text("win" if win else "loss")
	return "%s: \"%s\"" % [admiral_name(), t] if t != "" else ""
