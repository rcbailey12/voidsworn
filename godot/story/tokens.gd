extends RefCounted
# Story text tokens and conditional lines (the plumbing for the revised outlines, godot/story/outlines.md).
#
# fill(text, ctx) replaces:
#   {rival} {rival_short}            the Nemesis's full name / name without title
#   {he} {him} {his} {He} {Him} {His} his pronouns: he, she, or it (a Chorus mind), from pronouns(nem)
#   {rival_deed}                     his beat 1 calling card (rival_lines.json deed, by faction and personality)
#   {rival_line}                     ctx.rival_line (the beat decides which of his lines; see arc.gd)
#   {scars}                          once, twice, three times
#   {first_lost} {best_captain} {fallen_name} {prior_flagship} {flagship} {you}   run and career facts from ctx
# A token with no value falls back to a neutral phrase, so a card never shows a raw {token}.
#
# Conditional segments are written in data as {"t": "...", "if": "<condition>"} (see arc.gd for conditions).

const TIMES := ["never", "once", "twice", "three times", "four times", "five times"]

# Pronouns when stream B's Nemesis carries no gender field yet: feminine first names in the game's captain pools
# (data.js CAPTAINS and CAP_FIRST). Stream B is asked to add nem.g = "m" | "f" | "n"; this list is only the fallback.
const FEMININE := ["Ilse", "Vera", "Odile", "Sabine", "Helka", "Rosalind", "Margery", "Thessaly", "Elsbeth", "Yara", "Ninette", "Clemence", "Calla", "Mathilde",
	"Marit", "Mara", "Rhea", "Lena", "Petra", "Sanne", "Ines", "Katrin",
	"Margit", "Ida", "Hedda", "Agathe", "Edda",
	"Tamsa", "Ilvy", "Ressa", "Nell", "Sefa", "Orra",
	"Desmae", "Imra", "Rhosse", "Altheve"]
# Nemesis names are built from parts (data.js NEM_FAC pre + post); a name that starts with one of these feminine fronts is "she"
# (the same fronts as NEM_FAC[fac].fem, used by campaign_run.js nemGender).
const FEMININE_FRONTS := ["Marit", "Petra", "Katrin", "Sanne", "Margit", "Ida", "Hedda", "Agathe", "Edda", "Ves", "Ish", "Ny", "Dre", "Ess", "Kae", "Iv"]

const FALLBACK := {"first_lost": "a ship of the line", "best_captain": "your senior captain", "fallen_name": "a captain long gone", "prior_flagship": "a flagship you once knew",
	"flagship": "the flagship", "you": "the admiral", "rival": "the enemy commander", "rival_short": "the enemy commander", "rival_line": "", "rival_deed": ""}


static func pronouns(nem) -> Dictionary:
	var g := ""
	if nem is Dictionary:
		g = str(nem.get("g", nem.get("gender", "")))
		if g == "" and str(nem.get("fac", "")) == "chorus":
			g = "n"
		if g == "":
			var first := str(nem.get("name", "")).split(" ")[0]
			g = "f" if FEMININE.has(first) or _fem_front(first) else "m"
	match g:
		"f", "she":
			return {"he": "she", "him": "her", "his": "her"}
		"n", "it":
			return {"he": "it", "him": "it", "his": "its"}
	return {"he": "he", "him": "him", "his": "his"}


static func _fem_front(first: String) -> bool:
	for p in FEMININE_FRONTS:
		if first.begins_with(p):
			return true
	return false


# His full name as the campaign shows it (campaign_run.js nemFull): title, name, and the epithet his scars earned.
static func full_name(nem) -> String:
	if not (nem is Dictionary):
		return ""
	var ep = nem.get("epithet")
	var e := (" " + str(ep)) if ep != null and str(ep) != "" else ""
	return ("%s %s%s" % [str(nem.get("title", "")), str(nem.get("name", "")), e]).strip_edges()


static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1) if s != "" else s


# Replace every token in t. ctx: {nem, rival_line, rival_deed, first_lost, best_captain, fallen_name, prior_flagship, flagship, you}
static func fill(t: String, ctx: Dictionary) -> String:
	var nem = ctx.get("nem")
	var pr := pronouns(nem)
	var vals := {}
	for k in FALLBACK:
		vals[k] = str(ctx.get(k, "")) if str(ctx.get(k, "")) != "" else str(FALLBACK[k])
	if nem is Dictionary:
		vals["rival"] = full_name(nem)
		vals["rival_short"] = str(nem.get("name", vals["rival_short"]))
		vals["scars"] = TIMES[clampi(int(nem.get("scars", 0)), 0, TIMES.size() - 1)]
	else:
		vals["scars"] = "never"
	# the deed and the rival line carry pronoun tokens of their own: fill those first
	for k in ["rival_deed", "rival_line"]:
		vals[k] = _pron(str(vals[k]), pr)
	var out := t
	for k in vals:
		out = out.replace("{" + k + "}", str(vals[k]))
	out = _pron(out, pr)
	# tidy: an empty slot leaves a double space
	while out.contains("  "):
		out = out.replace("  ", " ")
	return out.strip_edges()


static func _pron(t: String, pr: Dictionary) -> String:
	for k in ["he", "him", "his"]:
		t = t.replace("{" + k + "}", pr[k]).replace("{" + _cap(k) + "}", _cap(pr[k]))
	return t
