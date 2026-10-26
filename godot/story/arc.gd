extends RefCounted
# Faction arc engine (plumbing for step 3; the arc text itself waits for Ryan's approval of outlines.md).
#
# An arc file (res://story/data/arcs/<faction>.json) holds:
#   {fac, arc, charge, prior_loss, prior_win,
#    beats: {"1": {"A": beat, "B": beat}, "2": {...}, "3": {...}},
#    win: [segment, ...], loss: [segment, ...]}
# A beat:
#   {id, title, rival_line: "" | "open" | "final", skim,
#    text: [segment, ...],
#    options: [{k, l, s, out, r, fl?, flag?, need?, if?}]}
# A segment is a string, or {"t": text, "if": condition} shown only when the condition holds (at most MAX_COND per card).
# Conditions: terms joined by "&", each optionally negated with "!":
#   flag:<name>    the run has that flag (RUN.flags, written by earlier choices)
#   lost           a ship has been lost this run
#   prior_loss     the last run with this faction was lost   prior_win   the last run with this faction was won
#   beaten         the Nemesis has been beaten before          scarred     the Nemesis carries scars
# Options: r is the event outcome (the campaign's applyOutcome keys), fl the counters it adds, flag a story flag it sets
# (written as an fl counter, so the existing eventFlags stores it in RUN.flags), need a blue requirement (the event
# system's need), if a condition that hides the option entirely, out the one-sentence result shown after the click.
#
# render(beat_no, ctx) returns an event-shaped dictionary the campaign's event screen already draws:
#   {id, t, b, skim, skim_first, o: [{k, l, s, r, fl, need}], outs: {k: out}, variant}

const Tokens := preload("res://story/tokens.gd")
const Rival := preload("res://story/rival.gd")
const MAX_COND := 2
const SKIM_AFTER := 2      # finished arcs of this faction before cards open on their skim version

var A: Dictionary = {}
var rival = Rival.new()


func load_arc(fac: String, path: String = "") -> bool:
	var p := path if path != "" else "res://story/data/arcs/%s.json" % fac
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return false
	var d = JSON.parse_string(f.get_as_text())
	A = d if d is Dictionary else {}
	return not A.is_empty()


# ---------------------------------------------------------------- conditions

static func cond(c: String, ctx: Dictionary) -> bool:
	if c == "":
		return true
	for term in c.split("&"):
		var t := term.strip_edges()
		var neg := t.begins_with("!")
		if neg:
			t = t.substr(1)
		var v := false
		var flags: Dictionary = ctx.get("flags", {}) if ctx.get("flags") is Dictionary else {}
		var nem = ctx.get("nem")
		if t.begins_with("flag:"):
			v = flags.has(t.substr(5)) and flags[t.substr(5)] != null
		elif t == "lost":
			v = str(ctx.get("first_lost", "")) != ""
		elif t == "prior_loss":
			v = bool(ctx.get("prior_loss", false))
		elif t == "prior_win":
			v = bool(ctx.get("prior_win", false))
		elif t == "beaten":
			v = nem is Dictionary and int(nem.get("beaten", 0)) > 0
		elif t == "scarred":
			v = nem is Dictionary and int(nem.get("scars", 0)) > 0
		if v == neg:
			return false
	return true


func segments(list: Array, ctx: Dictionary) -> String:
	var out: Array = []
	var shown := 0
	for s in list:
		if s is String:
			out.append(s)
		elif s is Dictionary:
			if shown < MAX_COND and cond(str(s.get("if", "")), ctx):
				out.append(str(s.get("t", "")))
				shown += 1
	return Tokens.fill(" ".join(PackedStringArray(out)), ctx)


# ---------------------------------------------------------------- variants

# Which version of a beat to show: the one this profile has seen less; a tie goes by the run's seed.
static func pick_variant(versions: Dictionary, seen: Dictionary, beat_id_prefix: String, seed: int) -> String:
	var ks: Array = versions.keys()
	ks.sort()
	if ks.is_empty():
		return ""
	var best: Array = []
	var low := 1 << 30
	for k in ks:
		var n := int(seen.get(beat_id_prefix + str(k), 0))
		if n < low:
			low = n
			best = [k]
		elif n == low:
			best.append(k)
	return str(best[absi(seed) % best.size()])


# ---------------------------------------------------------------- rendering

func _rival_line(kind: String, ctx: Dictionary) -> String:
	var nem = ctx.get("nem")
	if not (nem is Dictionary) or kind == "":
		return ""
	var seed := int(ctx.get("seed", 0))
	var t := ""
	if kind == "final":
		t = rival.final_hail(nem, ctx.get("flags", {}), seed, ctx)
	else:
		t = rival.opening(nem, 1, seed, ctx)
	return "%s: \"%s\"" % [Tokens.full_name(nem), t] if t != "" else ""


func render(beat_no: int, ctx: Dictionary) -> Dictionary:
	var vers: Dictionary = A.get("beats", {}).get(str(beat_no), {})
	if vers.is_empty():
		return {}
	var prefix := "arc_%s_%d" % [str(A.get("fac", "")), beat_no]
	var v := pick_variant(vers, ctx.get("seen", {}), prefix, int(ctx.get("seed", 0)))
	var beat: Dictionary = vers[v]
	var c := ctx.duplicate()
	c["rival_deed"] = rival.deed(ctx.get("nem"), int(ctx.get("seed", 0))) if ctx.get("nem") is Dictionary else ""
	c["rival_line"] = _rival_line(str(beat.get("rival_line", "")), ctx)
	var text: Array = beat.get("text", []).duplicate()
	if beat_no == 1:
		if bool(ctx.get("prior_win", false)) and str(A.get("prior_win", "")) != "":
			text.insert(1, {"t": str(A["prior_win"]), "if": "prior_win"})
		elif bool(ctx.get("prior_loss", false)) and str(A.get("prior_loss", "")) != "":
			text.insert(1, {"t": str(A["prior_loss"]), "if": "prior_loss"})
	var opts: Array = []
	var outs := {}
	for o in beat.get("options", []):
		if not cond(str(o.get("if", "")), c):
			continue
		var fl: Dictionary = (o.get("fl", {}) as Dictionary).duplicate() if o.get("fl") is Dictionary else {}
		if str(o.get("flag", "")) != "":
			fl[str(o["flag"])] = 1
		var e := {"k": str(o.get("k", "")), "l": Tokens.fill(str(o.get("l", "")), c), "s": Tokens.fill(str(o.get("s", "")), c), "r": o.get("r", {}), "fl": fl}
		if o.get("need") is Dictionary:
			e["need"] = o["need"]
		opts.append(e)
		outs[e["k"]] = Tokens.fill(str(o.get("out", "")), c)
	var fin: int = int(ctx.get("arcs_finished", 0))
	return {"id": "%s%s" % [prefix, v], "t": Tokens.fill(str(beat.get("title", "")), c), "b": segments(text, c), "skim": Tokens.fill(str(beat.get("skim", "")), c),
		"skim_first": fin >= SKIM_AFTER, "o": opts, "outs": outs, "variant": v, "charge": str(A.get("charge", "")) if beat_no == 1 else "", "arc": true}


# The win or loss text, with the lines the run's choices earned.
func ending(won: bool, ctx: Dictionary) -> String:
	return segments(A.get("win" if won else "loss", []), ctx)
