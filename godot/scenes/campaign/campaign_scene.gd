extends Node
# The campaign on its own (G3): title to the end of a run with test battles, for playing and checking the campaign screens
# before the battle scene is wired in. The game shell (godot/main/) builds the same two objects and handles the battle page.
#
# Command-line modes (after "--"):
#   shots <dir>     plays a scripted run and saves a screenshot of every campaign screen into <dir> (needs a real renderer)
#   bot <runs>      plays <runs> whole runs through the screens with the parity bot and quits; exit code 1 on any problem

const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const JSM = preload("res://rules/jsm.gd")

var C
var ui

func _ready() -> void:
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "":
		push_error(err); get_tree().quit(1); return
	ui = UIScript.new(); add_child(ui); ui.bind(C)
	var a := OS.get_cmdline_user_args()
	if a.size() >= 2 and a[0] == "shots":
		C.save_path = "user://campaign_shots_save.json"; _shots(a[1]); return
	if a.size() >= 2 and a[0] == "bot":
		C.save_path = "user://campaign_bot_save.json"; _bot(int(a[1])); return
	JSM.rnd_seed(int(Time.get_unix_time_from_system()) & 0xFFFFFFFF)   # the browser seeds its PRNG at random on load
	C.persist_on = true; C.persist_load()
	C.titleScreen()

func _frames(n: int = 3) -> void:
	for i in range(n): await get_tree().process_frame
func _shot(dir: String, name: String) -> void:
	await _frames(4)
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	img.save_png(dir.path_join(name + ".png")); print("shot ", name)

# A scripted run that visits every screen kind once and saves a picture of each.
func _shots(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	JSM.rnd_seed(4242)
	var M = C.META
	M["renown"] = 95; M["stats"]["runs"] = 6; M["stats"]["best"] = 3; M["stats"]["wins"] = 1; M["stats"]["wonFacs"] = ["voidsworn"]
	M["mastery"]["vex"] = 34; M["favour"]["iron"] = 13; M["favour"]["storm"] = 5
	M["fallen"] = [{"name": "Ordo Halvar", "rank": 2, "fac": "voidsworn", "ship": "Saint Ignatius", "sector": 2}]
	C.titleScreen(); await _shot(dir, "01_title")
	C.act("legacy"); await _shot(dir, "02_progression")
	C.act("progTab", "favour"); await _shot(dir, "03_progression_favour")
	C.act("title"); C.act("newRunScreen"); await _shot(dir, "04_admiral")
	C.act("optHeat", "h_flag"); C.act("startRun"); await _shot(dir, "05_aspect")
	C.act("pickAspect", C.W["aspOffer"][0]); await _shot(dir, "06_intro")
	C.act("closeModal"); await _shot(dir, "07_map")
	var seen = {}; var steps = 0
	while not C.ended and steps < 400:
		steps += 1
		var kind = C.modal_d["kind"] if C.modal_d != null else C.page["kind"]
		if not seen.has(kind):
			seen[kind] = true; await _shot(dir, "%02d_%s" % [7 + seen.size(), kind])
		var acts = C.screen_acts().filter(func(x): return x[2] == 1)
		var pick = _shots_pick(kind, acts, seen)
		if pick == null: break
		C.act(pick[0], pick[1]); await _frames(1)
	await _shot(dir, "99_end")
	get_tree().quit(0)
func _shots_pick(kind: String, acts: Array, seen: Dictionary):
	for x in acts:
		if kind == "map":
			if not seen.has("fleet") and x[0] == "fleetScreen": return x
			if x[0] == "enterNode": return x
		elif kind == "fleet":
			if x[0] == "equip": return x
			if x[0] == "backMap" or x[0] == "backShipyard": return x
		elif kind == "shipyard":
			if x[0] == "buyMod" or x[0] == "repairAll": return x
			if x[0] == "leaveYard": return x
		elif kind == "battle":
			if not seen.has("retreat") and x[0] == "c3retreat": return x
			var sec = int(C.RUN["sector"])
			if x[0] == "battle" and x[1] == ("loss" if (sec >= 2 and seen.has("sector")) else "win"): return x
		elif kind == "retreat":
			if x[0] == "c3retreatNo": return x
		elif kind == "prize":
			if x[0] == "prizeConfirm": return x
		else:
			return x
	return acts[0] if acts.size() > 0 else null

# Whole runs through the screens with the parity bot (the UI renders every step), for script errors and dead ends.
func _bot(runs: int) -> void:
	const STAY = ["closeModal", "buyHull", "buyMod", "repair", "repairAll", "upgradeMk", "sellShip", "sellConfirm", "yardFleet", "equip", "unequip", "promote", "fleetScreen", "pickFaction", "pickAdmiral", "optAlt", "optCmd", "optHeat", "progTab", "buyVariant", "c3retreat", "c3retreatNo"]
	var bad = 0
	for r in range(runs):
		var seed = 1000 + r
		JSM.rnd_seed(seed); C.META = C.defaultMeta(); C.SAVED_RUN = null; C.ended = false
		var s = seed; var streak = 0
		C.titleScreen()
		var steps = 0
		while not C.ended and steps < 4000:
			steps += 1
			var acts = C.screen_acts().filter(func(x): return x[2] == 1 and not (x[0] in ["legacy", "help", "saveQuit", "title", "abandonRun"]))
			if streak >= 8:
				var go = acts.filter(func(x): return not (x[0] in STAY))
				if go.size() > 0: acts = go
			if acts.is_empty(): break
			s = (s * 1103515245 + 12345) % 2147483648
			var x = acts[(s >> 16) % acts.size()]
			if x[0] == "battle": x = ["battle", "loss" if (s >> 16) % 25 == 0 else "win", 1]
			streak = streak + 1 if x[0] in STAY else 0
			C.act(x[0], x[1])
			if steps % 20 == 0: await _frames(1)
		print("run %d: %d steps, %s" % [r + 1, steps, "ended" if C.ended else "DID NOT END"])
		if not C.ended: bad += 1
	get_tree().quit(1 if bad > 0 else 0)
