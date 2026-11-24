extends SceneTree
# Issue 1990: every faction's beat 3 card (STORY_BEAT3, the outlines.md choices) reads the beat 1 and 2 story flags.
# This walks every beat 1 and beat 2 path of each faction (godot/story/outlines.md) into beat 3 and checks:
#   - the card offers exactly the choices the outline allows on that path (no choice whose earlier choice was not made),
#   - every card offers at least two choices and at least one can be taken (the fallback when an earlier choice is missing),
#   - an earlier-choice option is drawn blue with its requirement, a locked one names what closed it,
#   - at most two callback lines show and each one fits the path, and no placeholder is left,
#   - every offered choice can be taken: it applies, writes its own flag, and the card does not replay.
# Flags arrive the way arc cards write them (campaign.gd eventFlags, an fl counter per story flag, arc.gd).
# Run: godot --headless --path godot --script res://campaign/test/beat3_paths_test.gd
const Campaign = preload("res://campaign/campaign.gd")
var fails := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		printerr("FAIL: " + message)

# Beat 1 flags, beat 2 flags with the beat 1 flag a blue beat 2 option needs ("" for none), from outlines.md.
const PATHS := {
	"voidsworn": {"b1": ["vs_hand", "vs_sold"], "b2": [["vs_code", ""], ["vs_strike", ""], ["vs_rang", "vs_hand"], ["vs_pilgrims", "vs_sold"]]},
	"hegemony": {"b1": ["hg_offbook", "hg_orders"], "b2": [["hg_broke", ""], ["hg_left", ""], ["hg_broke", "hg_offbook"], ["hg_split", "hg_orders"]]},
	"corsair": {"b1": ["cs_rigged", "cs_party"], "b2": [["cs_stole", ""], ["cs_paid", ""], ["cs_mott", "cs_party"], ["cs_feared", "cs_rigged"]]},
	"chorus": {"b1": ["ch_ate", "ch_smell"], "b2": [["ch_dove", ""], ["ch_spawn", ""], ["ch_hunted", "ch_smell"], ["ch_hunger", "ch_ate"]]},
	"ithar": {"b1": ["it_song", "it_mercy"], "b2": [["it_lament", ""], ["it_dark", ""], ["it_spent", "it_song"], ["it_path", "it_mercy"]]},
	"deathless": {"b1": ["dd_writ", "dd_patient"], "b2": [["dd_broke", ""], ["dd_lawful", ""], ["dd_flaw", "dd_patient"]]},
}

# The beat 3 choices outlines.md allows after beat 1 flag a and beat 2 flag b ("" when that beat did not play).
# Each entry is [key, state]: "open", "blue" (needs an earlier choice, met) or "locked" (shown, closed by an earlier choice).
func expected(fac: String, a: String, b: String) -> Array:
	match fac:
		"voidsworn":
			var o := []
			if a == "vs_hand" and b != "vs_rang": o.append(["vs_lit_saint", "blue"])   # needs the shard intact
			o.append(["vs_lit_reactor", "open"])
			if a == "vs_sold": o.append(["vs_bought", "blue"])
			if a != "vs_sold" and (a != "vs_hand" or b == "vs_rang"): o.append(["vs_clean", "open"])   # fallback: no shard, no sale
			return o
		"hegemony":
			var o := [["hg_names", "open"], ["hg_duty", "open"]]
			if b == "hg_broke": o.append(["hg_lt", "blue"])
			if a == "hg_orders" and b != "hg_split": o.append(["hg_support", "blue"])   # bonus unspent
			return o
		"corsair":
			var o := [["cs_double", "open"], ["cs_through", "open"]]
			if a == "cs_party": o.append(["cs_mottspeech", "blue"])
			return o
		"chorus":
			var o := [["ch_end_hunger", "open"], ["ch_end_memory", "locked" if b == "ch_hunger" else "open"]]
			if b == "ch_spawn": o.append(["ch_end_spawn", "blue"])
			return o
		"ithar":
			var o := [["it_end_archive", "open"], ["it_end_fleet", "open"]]
			if a == "it_song" and b != "it_spent": o.append(["it_end_buoy", "blue"])
			if a == "it_mercy": o.append(["it_end_mercy", "blue"])
			return o
		"deathless":
			var o := [["dd_erase", "open"], ["dd_summons", "open"]]
			if b == "dd_lawful": o.append(["dd_guard", "blue"])
			return o
	return []

# Callback phrases that must not show on a path (a line about a choice that was not made).
const NEVER := {
	"vs_rang": ["demanding Seren's casing"], "vs_sold": ["demanding Seren's casing", "sector-wide surge"],
	"hg_offbook": [], "hg_left": ["reprimand", "port bow"], "hg_broke": ["lost freighters", "eleven lost"],
	"ch_ate": ["acid scars"], "it_spent": ["light is still aboard"], "it_song": ["spared buoy's beacon"],
	"dd_broke": ["request clearance"], "dd_lawful": ["refusing to align"],
}

func start(c, fac: String, flags: Array) -> void:
	var id: String = c.TB.STORY_BEAT3[fac]["spotlights"].keys()[0]
	c.META["admirals"][id] = true  # the harness owns the admiral it flies
	c.newRun(id, fac); c.RUN["sector"] = 3
	c.RUN["credits"] = 300.0
	c.RUN["relics"] = [c.RELICS.keys()[0]]   # stands in for the ember shard the Crusade beat 1 gives
	for i in range(flags.size()):   # the way an arc card writes its story flag (arc.gd: flag -> fl counter -> eventFlags)
		c.eventFlags({"id": "arc_" + fac + "_" + str(i + 1) + "a"}, {"k": "a", "fl": {flags[i]: 1}}, 0)
	c.mapScreen()

func walk(c, fac: String, a: String, b: String) -> void:
	var flags := [a, b].filter(func(f): return f != "")
	var label := fac + " [" + ", ".join(PackedStringArray(flags)) + "]"
	start(c, fac, flags)
	var card: Dictionary = c.beat3Card()
	check(not card.is_empty(), label + ": beat 3 card opens")
	if card.is_empty(): return
	var want := expected(fac, a, b)
	var got := []
	for o in card["o"]:
		var state := "open"
		if c.jt(o.get("need")): state = "locked" if c.jt(o["need"].get("lock")) else "blue"
		got.append([str(o["k"]), state])
	check(got == want, label + ": offers " + str(want) + ", got " + str(got))
	check(card["o"].size() >= 2, label + ": at least two choices on the card")
	check(card["o"].any(func(o): return c.eventOptOk(o)), label + ": at least one choice can be taken")
	for o in card["o"]:
		var locked: bool = c.jt(o.get("need")) and c.jt(o["need"].get("lock"))
		check(c.eventOptOk(o) != locked, label + ": " + str(o["k"]) + (" is closed" if locked else " can be taken"))
		if c.jt(o.get("need")):
			var tag: String = c.needText(o["need"])
			check(tag.begins_with("Needs ") and tag != "Needs an earlier choice", label + ": " + str(o["k"]) + " names what it needs (" + tag + ")")
		for k in ["l", "s"]:
			check(str(o[k]) != "" and not str(o[k]).contains("{"), label + ": " + str(o["k"]) + " " + k + " text")
		check(str(card["outs"][o["k"]]) != "" and not str(card["outs"][o["k"]]).contains("{"), label + ": " + str(o["k"]) + " outcome text")
	var body: String = card["b"]
	check(not body.contains("{"), label + ": no placeholder left in the card")
	var shown := 0
	for cb in c.TB.STORY_BEAT3[fac].get("callbacks", []):
		if body.contains(c.beat3Text(cb["t"])):
			shown += 1
			check(c.beat3Cond(cb.get("if")), label + ": callback fits the path: " + str(cb["t"]))
	check(shown <= c.BEAT3_CALLBACKS, label + ": at most two callback lines")
	for f in flags:
		for phrase in NEVER.get(f, []):
			check(not body.contains(phrase), label + ": no line about a choice not made (" + phrase + ")")
	if fac == "hegemony":
		var names: Dictionary = card["o"][0]
		check(str(names["s"]).contains("M-14") == (a == "hg_offbook"), label + ": the M-14 list is read only with the black box")
	# every offered choice can be taken on this path
	for i in range(card["o"].size()):
		var o: Dictionary = card["o"][i]
		if not c.eventOptOk(o): continue
		start(c, fac, flags)
		check(c.showBeat3(), label + ": " + str(o["k"]) + " decision opens")
		c.act("eventChoice", str(i))
		if c.modal_d != null and c.modal_d["kind"] == "relic_pick": c.act("eventChoice", str(i) + ":0")
		check(c.RUN["flags"].get(c.TB.STORY_BEAT3[fac]["id"]) == o["k"], label + ": " + str(o["k"]) + " writes its choice")
		check(c.modal_d != null and c.modal_d["kind"] == "event_result", label + ": " + str(o["k"]) + " shows its result")
		check(c.beat3Card().is_empty(), label + ": " + str(o["k"]) + " the card does not replay")

func _initialize() -> void:
	var c = Campaign.new()
	check(c.load_tables() == "", "campaign tables load")
	c.persist_on = false
	var paths := 0
	for fac in c.RUN_FACTIONS:
		check(PATHS.has(fac), fac + ": has beat 1 and 2 paths in this test")
		if not PATHS.has(fac): continue
		walk(c, fac, "", ""); paths += 1   # beats 1 and 2 did not play (arcs off): the fallback card
		for a in PATHS[fac]["b1"]:
			walk(c, fac, a, ""); paths += 1
			for pair in PATHS[fac]["b2"]:
				if pair[1] != "" and pair[1] != a: continue   # that beat 2 option was not offered after a
				walk(c, fac, a, pair[0]); paths += 1
	# a locked or blue option stays shut when the requirement is not met by resources (credits, the shard spent)
	start(c, "voidsworn", ["vs_hand"]); c.RUN["relics"] = []
	var card: Dictionary = c.beat3Card()
	check(card["o"].size() == 2 and not c.eventOptOk(card["o"][0]) and c.eventOptOk(card["o"][1]), "voidsworn: a spent shard leaves its choice shown but closed")
	start(c, "voidsworn", ["vs_sold"]); c.RUN["credits"] = 10.0
	check(c.showBeat3(), "voidsworn: decision opens with 10 credits")
	card = c.cur_event
	check(str(card["o"][1]["k"]) == "vs_bought" and not c.eventOptOk(card["o"][1]), "voidsworn: buying back standing needs 60 credits")
	c.act("eventChoice", "1")
	check(c.RUN["flags"].get(c.TB.STORY_BEAT3["voidsworn"]["id"]) == null, "voidsworn: a closed choice cannot be taken")
	print("beat 3 paths: " + ("PASS (%d paths across six factions)" % paths if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)
