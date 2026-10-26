# Screenshots of the Career screen and the rename dialog with sample data (for Ryan's phone review). Needs a window:
#   godot --path godot --rendering-method gl_compatibility --resolution 1600x900 --script res://story/test/career_shots.gd -- <out_dir>
# Writes career_<tab>.png and rename.png. Sample data only; it never touches the real career file.
extends SceneTree

const Career = preload("res://story/career.gd")
const StoryScript = preload("res://story/story.gd")


func _B(kind: String, lost: int, kills: int, us: Dictionary) -> Dictionary:
	var units: Array = []
	for i in 4:
		units.append({"id": "p%d" % i, "side": "player", "dead": i < lost, "name": ["Oathkeeper", "Ashen Vigil", "Cinder Psalm", "Grave Tithe"][i]})
	for i in 6:
		units.append({"id": "e%d" % i, "side": "enemy", "dead": i < kills, "boss": kind == "boss" and i == 0})
	return {"cfg": {"kind": kind}, "units": units, "usage": us, "round": 5, "over": "win", "finished": true}


func _initialize() -> void:
	var out := "user://career_shots"
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	var S = StoryScript.new()
	root.add_child(S)
	await process_frame
	var c = S.career
	c.P = Career.default_profile()
	var runs := [
		{"t0": 1, "admiral": "grax", "fac": "corsair", "sector": 3, "won": true, "us": {"kind": {"battery": 20, "torp": 6}, "ram": 3, "board": 2, "cap": 1}, "flag": "Rust Bucket"},
		{"t0": 2, "admiral": "aelith", "fac": "ithar", "sector": 2, "won": false, "us": {"kind": {"sq": 30, "lance": 10}}, "flag": "Glasswing"},
		{"t0": 3, "admiral": "kassar", "fac": "hegemony", "sector": 3, "won": true, "us": {"kind": {"battery": 40}, "fire": {"Port broadside": 20, "Starboard broadside": 18, "Prow": 5}}, "flag": "Order Forty-One"},
		{"t0": 4, "admiral": "vex", "fac": "voidsworn", "sector": 1, "won": false, "us": {"kind": {"lance": 20, "battery": 15}, "aim": 9}, "flag": "Saint Vesper's Wrath"}]
	for r in runs:
		var run := {"t0": r["t0"], "admiral": r["admiral"], "fac": r["fac"], "sector": 1, "flagUid": "f", "fleet": [{"uid": "f", "name": r["flag"]}], "heat": []}
		for s in range(1, int(r["sector"]) + 1):
			run["sector"] = s
			for b in 3:
				c.record_battle(run, _B("boss" if b == 2 else "battle", 1 if (b == 1 and s == 2) else 0, 5, r["us"]), "win")
		c.record_run_end(run, bool(r["won"]), S.admiral_name(str(r["admiral"])))
	c.record_arc_end("hegemony", "kassar", "Justiciar Halvane the Unpardoning", {"1": "offbook", "2": "broke", "3": "names"}, true)
	c.record_arc_end("ithar", "aelith", "Warlord Bones Sharkey", {"1": "song"}, false)
	var scr = S.open_career()
	for t in ["records", "medals", "titles", "history", "chronicle"]:
		scr.set_tab(t)
		await _settle()
		_save(out.path_join("career_%s.png" % t))
	scr.queue_free()
	await _settle()
	# the rename dialog needs a campaign run; a stand-in object with the fields it reads is enough for a picture
	var d = load("res://ui/career/rename_dialog.gd").new()
	S._layer().add_child(d)
	S.C = FakeCampaign.new()
	d.open(S)
	await _settle()
	_save(out.path_join("rename.png"))
	print("career_shots: wrote ", out)
	quit(0)


func _settle() -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw


func _save(p: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(p)


class FakeCampaign:
	extends RefCounted
	signal changed
	var RUN := {"fac": "voidsworn", "flagUid": "f", "fleet": [{"uid": "f", "name": "Saint Vesper's Wrath"}]}
	func flagshipOf():
		return RUN["fleet"][0]
	func saveRun() -> void:
		pass
	func persist_save(_m := false) -> void:
		pass
