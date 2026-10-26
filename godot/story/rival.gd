extends RefCounted
# The Nemesis's voice (R42): picks his lines from data/rival_lines.json by his faction, his personality, his scars and how
# you beat him last time, so each run's Nemesis sounds different. Presentation only: lines are picked with a hash of his
# name, the moment and a seed (never the rules PRNG).
#
# The Nemesis dictionary it reads is the campaign's RUN.nem (the battle's B.nem carries the same fields):
#   name, title, fac                 (B4, today)
#   scars, beaten                    (B4, today: times his flagship broke and he escaped; times you beat him)
#   adapt, seen                      (B4, today: what he adapted to; what he saw you use this sector)
#   persona                          (R42, stream B, data.js NEM_PERSONA: cunning, zealous, cruel, patient, proud, greedy,
#                                     methodical, ravenous; four per faction; `personality` is read too, as a fallback)
#   beat                             (R42, stream B: how you beat him last time, a NEM_BEAT_WORD key; `last_beat` too)
#   epithet                          (R42, stream B: the name his scars earned him; part of his full name)
# How you beat him maps onto the memory lines lance, torp, sq, ram, board, battery, evasive (broad to battery, ion to
# lance, evaded to evasive); with no `beat`, it is read from adapt and seen.

const Tokens := preload("res://story/tokens.gd")

var D: Dictionary = {}

const ADAPT_TO_MEMORY := {"shields": "lance", "pd": "torp", "armor": "ram", "evasion": "battery", "aim": "evasive"}
const SEEN_TO_MEMORY := {"lance": "lance", "ion": "lance", "torp": "torp", "sq": "sq", "ram": "ram", "board": "board", "battery": "battery", "broad": "battery", "evaded": "evasive"}
const TIMES := ["never", "once", "twice", "three times", "four times", "five times"]


func _init() -> void:
	var f := FileAccess.open("res://story/data/rival_lines.json", FileAccess.READ)
	if f != null:
		var d = JSON.parse_string(f.get_as_text())
		D = d if d is Dictionary else {}


static func full_name(nem) -> String:
	return Tokens.full_name(nem)


# stream B's field is `persona` (R42); `personality` was this stream's earlier proposal
static func persona_of(nem) -> String:
	if not (nem is Dictionary):
		return ""
	var p = nem.get("persona", nem.get("personality", ""))
	return str(p) if p != null else ""


static func _h(s: String) -> int:
	# a small stable string hash (FNV-1a, 31 bits), the same on every machine
	var h := 2166136261
	for i in s.length():
		h = ((h ^ s.unicode_at(i)) * 16777619) & 0x7fffffff
	# final mix: FNV's low bits follow the characters' parity, so "pick one of two" needs the high bits stirred in
	h ^= h >> 13
	h = (h * 0x5bd1e995) & 0x7fffffff
	h ^= h >> 15
	return h


func _pick(pool, nem, key: String, seed: int) -> String:
	if pool is String:
		return pool
	if not (pool is Array) or pool.is_empty():
		return ""
	return str(pool[_h(str(nem.get("name", "")) + "|" + key + "|" + str(seed)) % pool.size()])


func _fac(nem) -> Dictionary:
	return D.get(str(nem.get("fac", "")), {}) if nem is Dictionary else {}


# How you beat him last time, as a memory key (or "" when he has nothing to remember).
static func memory_key(nem) -> String:
	if not (nem is Dictionary):
		return ""
	var lb := str(nem.get("beat", nem.get("last_beat", "")))
	if lb != "" and lb != "<null>":
		return SEEN_TO_MEMORY.get(lb, lb)
	var ad = nem.get("adapt", [])
	if ad is Array and ad.size() > 0 and ADAPT_TO_MEMORY.has(str(ad[ad.size() - 1])):
		return ADAPT_TO_MEMORY[str(ad[ad.size() - 1])]
	var seen = nem.get("seen", {})
	var best := ""
	var top := 0.0
	if seen is Dictionary:
		for k in seen:
			if SEEN_TO_MEMORY.has(str(k)) and float(seen[k]) > top:
				top = float(seen[k])
				best = SEEN_TO_MEMORY[str(k)]
	return best


func fill(t: String, nem, ctx: Dictionary = {}) -> String:
	var c := ctx.duplicate()
	c["nem"] = nem
	return Tokens.fill(t, c)


# His beat 1 calling card ({rival_deed}): by his faction and personality; without a personality, one picked by his name.
func deed(nem, seed := 0) -> String:
	var F := _fac(nem)
	var D2: Dictionary = F.get("deed", {})
	if D2.is_empty():
		return ""
	var pers := persona_of(nem)
	if not D2.has(pers):
		var ks: Array = D2.keys()
		ks.sort()
		pers = ks[_h(str(nem.get("name", "")) + "|deed|" + str(seed)) % ks.size()]
	return str(D2[pers])


# Which way the run's choices leaned, from the shared event counters (RUN.flags mercy, greed, loud): "mercy",
# "ruthless" or "" (even, or no choices yet).
static func lean(flags) -> String:
	if not (flags is Dictionary):
		return ""
	var m := float(flags.get("mercy", 0))
	var r := float(flags.get("greed", 0)) + float(flags.get("loud", 0))
	if m > r:
		return "mercy"
	if r > m:
		return "ruthless"
	return ""


# His beat 3 hail (outlines.md Table B): remembers (you beat him before, or he carries scars), then the run's lean
# (mercy or ruthless), else what the Hollow Sun means to him.
func final_hail(nem, flags = {}, seed := 0, ctx: Dictionary = {}) -> String:
	var F := _fac(nem)
	var fb: Dictionary = F.get("final_by", {})
	if fb.is_empty():
		return line("final", nem, seed, ctx)
	var k := "sun"
	if nem is Dictionary and (int(nem.get("beaten", 0)) > 0 or int(nem.get("scars", 0)) > 0):
		k = "remembers"
	elif lean(flags) != "":
		k = lean(flags)
	return fill(str(fb.get(k, fb.get("sun", ""))), nem, ctx)


# One line for a moment: beaten, death, gloat, kill, signature (and hail, again, final, scar).
func line(moment: String, nem, seed := 0, ctx: Dictionary = {}) -> String:
	var F := _fac(nem)
	var pers := persona_of(nem)
	# a personality line for beaten and hail when he has one (half the time, so the faction pool still shows)
	if pers != "" and moment in ["hail", "beaten"] and F.get("personality", {}).has(pers) and _h(str(nem.get("name", "")) + moment + str(seed)) % 2 == 0:
		var pl := str(F["personality"][pers].get(moment, ""))
		if pl != "":
			return fill(pl, nem, ctx)
	return fill(_pick(F.get(moment), nem, moment, seed), nem, ctx)


# His opening line for a battle against his fleet.
#   sector III: his final line (the arc's beat 3 line);
#   a later meeting: what he remembers (how you beat him), his scars, or a rematch line;
#   the first meeting: a hail (his personality's or the faction's).
func opening(nem, sector: int, seed := 0, ctx: Dictionary = {}) -> String:
	if not (nem is Dictionary):
		return ""
	var F := _fac(nem)
	if sector >= 3:
		return fill(_pick(F.get("final"), nem, "final", seed), nem, ctx)
	var met := int(nem.get("beaten", 0)) > 0 or int(nem.get("scars", 0)) > 0
	if met:
		var opts: Array = ["again"]
		var mk := memory_key(nem)
		if mk != "" and F.get("memory", {}).has(mk):
			opts.append("memory")
			opts.append("memory")
		if int(nem.get("scars", 0)) > 0:
			opts.append("scar")
		var o: String = opts[_h(str(nem.get("name", "")) + "open" + str(seed)) % opts.size()]
		if o == "memory":
			return fill(str(F["memory"][mk]), nem, ctx)
		return fill(_pick(F.get(o), nem, o, seed), nem, ctx)
	return line("hail", nem, seed, ctx)
