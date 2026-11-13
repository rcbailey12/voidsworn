extends SceneTree
# Issue 652: the first-visit tip card on the campaign screens, where it sat on top of things on main: the sector map with
# the Map key slide-over open, and the shipyard (its "Fleet fully repaired" bar). Builds the real campaign UI and the
# real teaching card, captures each screen at 1920 by 1080 and prints one TIPCARD line per screen saying whether the card
# overlaps the slide-over or the repair bar.
#   godot --path godot --resolution 1920x1080 --script res://campaign/test/tipcard_place_shots.gd -- <out dir> capture
#   godot --path godot --resolution 1920x1080 --script res://campaign/test/tipcard_place_shots.gd -- <out dir> compose <before dir> <after dir>
# compose puts each before and after pair side by side in one picture no taller than 720 px, named on the picture.
# The card's profile file is user://battle_opts.json: the run saves it first and puts it back before quitting; pointing
# APPDATA (Windows) at a scratch folder keeps the player's profile out of it altogether.
const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const Teaching = preload("res://ui/campaign/campaign_tips.gd")
const BattleAPI = preload("res://rules/battle_api.gd")
const SHOTS := [["tipcard_map", "The sector map: c_map card"], ["tipcard_map_key", "The sector map, Map key open: c_map card"],
	["tipcard_shipyard", "The shipyard: c_shipyard card"]]

var dir := ""
var C
var ui
var fails := 0
var old_opts = null    # the profile's tip settings before the run, put back at the end


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	dir = a[0] if a.size() > 0 else "user://tipcard_place_shots"
	DirAccess.make_dir_recursive_absolute(dir)
	if a.size() > 3 and a[1] == "compose":
		_compose.call_deferred(a[2], a[3], a[4].split(",") if a.size() > 4 else PackedStringArray())
	else:
		_run.call_deferred()


func _frames(n: int) -> void:
	for i in range(n): await process_frame


func _window(sz: Vector2i) -> void:
	var win := get_root()
	win.mode = Window.MODE_WINDOWED
	await _frames(2)
	win.size = sz
	root.content_scale_size = sz
	await _frames(6)


func _shot(name: String) -> void:
	await _frames(8)
	if DisplayServer.get_name() == "headless":
		return
	var t0 := Time.get_ticks_msec()   # the map draws under the "Preparing the sector" cover (main/load_screen.gd)
	while _covered(root) and Time.get_ticks_msec() - t0 < 300000: await process_frame
	await _frames(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join(name + ".png"))
	print("shot ", name)


func _covered(n: Node) -> bool:
	if n.get_script() != null and str(n.get_script().resource_path).ends_with("load_screen.gd"): return true
	for ch in n.get_children():
		if _covered(ch): return true
	return false


func _all(n: Node, out: Array) -> Array:
	out.append(n)
	for c in n.get_children(): _all(c, out)
	return out


func _card_rect() -> Rect2:
	var t = ui.teaching
	if t.hud == null or t.hud.tipcard == null or not t.hud.tipcard.is_visible_in_tree(): return Rect2()
	return t.hud.tipcard.get_global_rect()


# the Map key slide-over: the panel at the right edge of the screen, as tall as the screen
func _key_rect() -> Rect2:
	var vs: Vector2 = root.get_visible_rect().size
	for n in _all(ui.page_box, []):
		if n is PanelContainer and n.is_visible_in_tree():
			var r: Rect2 = n.get_global_rect()
			if absf(r.end.x - vs.x) < 2.0 and r.size.y > vs.y * 0.9 and r.size.x < vs.x * 0.5: return r
	return Rect2()


func _repair_rect() -> Rect2:
	for n in _all(ui.page_box, []):
		if n is Button and n.is_visible_in_tree() and (n.text.begins_with("Repair entire fleet") or n.text == "Fleet fully repaired"):
			return n.get_global_rect()
	return Rect2()


func _report(name: String, other: String, o: Rect2) -> void:
	var cr := _card_rect()
	var hits: Array = []
	if o.size.x > 0.0 and cr.intersects(o): hits.append(other)
	for n in _all(ui, []):
		if n is Button and n.is_visible_in_tree() and n.text != "" and cr.intersects(n.get_global_rect()):
			var inside := false
			var p = n.get_parent()
			while p != null:
				if p == ui.teaching.hud.tipcard: inside = true; break
				p = p.get_parent()
			if not inside: hits.append("button '%s' %s" % [n.text, str(n.get_global_rect())])
	var ok := cr.size.x > 0.0 and hits.is_empty()
	if not ok: fails += 1
	print("TIPCARD %s %s card=%s hits=%s" % [name, "PASS" if ok else "FAIL", str(cr), str(hits)])


func _run() -> void:
	await _window(Vector2i(1920, 1080))
	if FileAccess.file_exists(Teaching.OPTS): old_opts = FileAccess.get_file_as_string(Teaching.OPTS)
	var f := FileAccess.open(Teaching.OPTS, FileAccess.WRITE)
	f.store_string('{"tips":{},"tipsOff":false}')
	f.close()
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "":
		printerr(err); _restore(); quit(1); return
	C.save_path = "user://tipcard_place_shots_save.json"
	ui = UIScript.new(); root.add_child(ui); ui.use_3d_map = false; ui.bind(C)
	await _frames(4)
	BattleAPI.JSM.rnd_seed(4242)
	C.titleScreen(); C.act("newRunScreen"); C.act("pickFaction", "voidsworn")
	C.act("startRun"); C.act("pickAspect", C.W["aspOffer"][0]); C.act("closeModal")
	await _frames(6)
	await _shot("tipcard_map")
	_report("tipcard_map", "none", Rect2())
	ui._open_overlay("key")
	await _frames(6)
	await _shot("tipcard_map_key")
	_report("tipcard_map_key", "map_key", _key_rect())
	ui._close_overlay()
	await _frames(4)
	ui.teaching._action("tip_ok", "c_map")    # the clock card follows the map card
	await _frames(2)
	ui.teaching._action("tip_ok", "c_clock")
	await _frames(2)
	C.shipyardScreen({"id": "t652y", "type": "shipyard", "col": 3, "row": 0})
	await _frames(6)
	await _shot("tipcard_shipyard")
	_report("tipcard_shipyard", "repair_bar", _repair_rect())
	print("TIPCARD " + ("PASS" if fails == 0 else "FAIL: %d" % fails))
	_restore()
	quit(0 if fails == 0 else 1)


# puts the profile's tip settings back as they were (or removes the file this run made)
func _restore() -> void:
	if old_opts == null:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Teaching.OPTS))
		return
	var f := FileAccess.open(Teaching.OPTS, FileAccess.WRITE)
	f.store_string(old_opts)
	f.close()


# each before and after pair side by side at half size (960 by 540 each), the code name and the side over each half
func _compose(before: String, after: String, names: PackedStringArray) -> void:
	await _window(Vector2i(1940, 600))
	var list: Array = SHOTS
	if not names.is_empty():
		list = []
		for nm in names: list.append([nm, "battle HUD, same frame"])
	for s in list:
		var host := Control.new(); host.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(host)
		var bg := ColorRect.new(); bg.color = Color("#0b0a09"); bg.set_anchors_preset(Control.PRESET_FULL_RECT); host.add_child(bg)
		var i := 0
		for side in [["BEFORE (main)", before], ["AFTER (issue 652)", after]]:
			var img := Image.load_from_file(str(side[1]).path_join(s[0] + ".png"))
			if img == null or img.is_empty():
				printerr("missing " + str(side[1]).path_join(s[0] + ".png")); fails += 1; continue
			var tr := TextureRect.new(); tr.texture = ImageTexture.create_from_image(img)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			tr.position = Vector2(i * 980, 52); tr.size = Vector2(960, 540); host.add_child(tr)
			var l := Label.new(); l.text = "%s   %s   %s" % [s[0], side[0], s[1]]; l.position = Vector2(i * 980 + 4, 12)
			l.add_theme_font_size_override("font_size", 22); host.add_child(l)
			i += 1
		await _frames(6)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(dir.path_join(s[0] + "_before_after.png"))
			print("composed ", s[0])
		host.queue_free()
		await _frames(2)
	quit(0 if fails == 0 else 1)
