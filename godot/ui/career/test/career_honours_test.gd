extends SceneTree
# CR4: open the real screen through Story, exercise every tab without writing a profile,
# and prove that a fourth served admiral joins a second hero row. Optional GPU captures:
# --shots DIR writes the full roster, the 12-admiral reference, fourth served and every tab.

const Story := preload("res://story/story.gd")
const Career := preload("res://story/career.gd")
var fails := 0
var shots := ""


class CampaignState:
	extends RefCounted
	var RUN := {"admiral": "vex", "fleet": [{"name": "Wrath of Vesper"}], "sector": 2}
	var META := {"renown": 53, "wins": 2}


static func profile(fourth := false) -> Dictionary:
	var p := Career.default_profile()
	# A legacy snapshot can have lifetime totals beyond the named records (CR4's evidence).
	p.totals = {"runs": 4, "wins": 2, "battles": 27, "kills": 135, "flag_kills": 9, "captures": 9, "lost": 3}
	for id in ["vex", "kassar", "grax"]:
		var vex: bool = id == "vex"
		var title: String = "marksman" if vex else ("gunline" if id == "kassar" else "brawler")
		p.admirals[id] = {"runs": 1, "wins": 0 if vex else 1, "best": 1 if vex else 3,
			"battles": 3 if vex else 9, "kills": 15 if vex else 45, "lost": 0 if vex else 1,
			"titles": {title: 1}, "last_title": title,
			"flagships": [{"vex": "Wrath of Vesper", "kassar": "Order Forty-One", "grax": "Rust Bucket"}[id]]}
	p.arc_rewards.hegemony = {"title": "Holder of the Anchorage", "admirals": ["kassar"]}
	p.paint_on.hegemony = true
	if fourth:
		p.admirals.aelith = {"runs": 1, "wins": 0, "best": 2, "battles": 6, "kills": 30, "lost": 1, "titles": {}, "flagships": ["Glasswing"]}
	return p


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--shots"):
		shots = args[args.find("--shots") + 1]
	_run.call_deferred()


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok:
		fails += 1


func settle() -> void:
	for i in 5:
		await process_frame


func descendants(n: Node, kind: String) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c.is_class(kind):
			out.append(c)
		out.append_array(descendants(c, kind))
	return out


func capture(name: String) -> void:
	if shots.is_empty():
		return
	await settle()
	await RenderingServer.frame_post_draw
	check(preload("res://tools/picture_provenance.gd").save_png(root.get_texture().get_image(), shots.path_join(name + ".png")) == OK, "captured " + name)


func geometry(scr: Control, tag: String) -> void:
	var overflow: Array = []
	var last_tab_end := -1.0
	for button: Button in scr.tab_row.get_children():
		var rect := button.get_global_rect()
		if rect.position.x < last_tab_end or rect.size.x < scr.px(50):
			overflow.append("tab overlap: " + button.name)
		last_tab_end = rect.end.x
		for word: Label in descendants(button, "Label"):
			if not rect.encloses(word.get_global_rect()):
				overflow.append("tab word outside button: " + word.text)
	for l: Label in descendants(scr, "Label"):
		if not l.is_visible_in_tree():
			continue
		if l.get_global_rect().end.x > scr.size.x + 1 or l.get_global_rect().position.x < -1:
			overflow.append(l.text)
		if not l.autowrap_mode and l.get_minimum_size().x > l.size.x + 1:
			overflow.append(l.text)
		if l.get_minimum_size().y > l.size.y + 1:
			overflow.append("height: " + l.text)
		if l.get_theme_font_size("font_size") < scr.px(17):
			overflow.append("small: " + l.text)
	check(overflow.is_empty(), tag + ": no horizontal clipping and text at least 17 px: " + str(overflow))
	check(scr.scroll.get_h_scroll_bar().max_value <= scr.scroll.size.x + 1, tag + ": no horizontal scroll")


func _run() -> void:
	for sz in [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]:
		root.size = sz
		root.content_scale_size = Vector2i.ZERO
		await settle()
		var tag := "%dx%d" % [sz.x, sz.y]
		var s := Story.new()
		root.add_child(s)
		s.C = CampaignState.new()
		s.career.persist = true
		s.career.save_path = OS.get_environment("TEMP").path_join("career869_readonly_%d_%s.json" % [OS.get_process_id(), tag])
		for scenario in ["empty", "three", "four", "all", "long"]:
			s.career.P = Career.default_profile() if scenario == "empty" else profile(scenario == "four")
			if scenario == "all":
				for id in s.ADM:
					s.career.P.admirals[id] = profile().admirals.vex.duplicate(true)
			if scenario == "long":
				s.ADM.vex.n = "Admiral Roderic Vex Keeper of Every Oath Across the Hollow Sun"
				s.career.P.admirals.vex.flagships = ["Wrath of Vesper and the Unbroken Oath of the Last Anchorage", "Second Oath", "Third Oath"]
				s.career.P.admirals.vex.kills = 1234567
			var before := var_to_bytes(s.career.P)
			var run_before := var_to_bytes(s.C.RUN)
			var meta_before := var_to_bytes(s.C.META)
			var scr = s.open_career()
			await settle()
			check(scr != null, "%s %s: opens through Story.open_career" % [tag, scenario])
			if scr == null:
				continue
			var heroes: GridContainer = scr.body.get_node("Heroes")
			var count := 0 if scenario == "empty" else (4 if scenario == "four" else (s.ADM.size() if scenario == "all" else 3))
			check(heroes.get_child_count() == count, "%s %s: %d heroes" % [tag, scenario, count])
			for hero in heroes.get_children():
				var stats: GridContainer = hero.get_node("Figures")
				var record: Dictionary = s.career.P.admirals[hero.get_meta("admiral")]
				var values := [str(record.runs), str(record.wins), scr.ROMAN[clampi(int(record.best), 0, 5)], str(record.battles), str(record.kills), str(record.lost)]
				var labels := ["RUNS", "WON", "BEST SECTOR", "BATTLES", "KILLS", "SHIPS LOST"]
				check(stats.get_child_count() == 6, tag + ": six figures for " + hero.name)
				check(hero.has_node("PictureBand"), tag + ": picture band for " + hero.name)
				for i in stats.get_child_count():
					var group := stats.get_child(i)
					check(group.get_child(0).text == values[i] and group.get_child(1).text == labels[i], tag + ": saved figure has the correct label and value")
					check(group.get_child(0).get_global_rect().end.y <= group.get_child(1).get_global_rect().position.y + 1, tag + ": figure clears its label")
			if scenario == "three":
				var roster: GridContainer = scr.body.get_node("Unserved")
				check(roster.get_child_count() == 6, tag + ": all six factions remain reachable")
				var unserved := 0
				var crests := 0
				for row in descendants(roster, "HBoxContainer"):
					if row.has_meta("admiral"):
						unserved += 1
						if row.has_node("Crest"):
							crests += 1
				check(unserved == s.ADM.size() - 3 and crests == 3, tag + ": all unserved entries, just three Sunward crests")
				if sz.y != 1440:
					await capture("CR4_roster_" + tag)
					if not shots.is_empty():
						scr.scroll.scroll_vertical = int(scr.body.size.y)
						await capture("CR4_roster_lower_" + tag)
						scr.scroll.scroll_vertical = 0
			if scenario == "four":
				check(heroes.get_child(3).position.y >= heroes.get_child(0).position.y + heroes.get_child(0).size.y, tag + ": fourth served starts second row")
				if sz.y != 1440:
					await capture("CR4_four_top_" + tag)
					scr.scroll.scroll_vertical = int(heroes.get_child(3).position.y)
					await capture("CR4_four_second_row_" + tag)
			geometry(scr, tag + " " + scenario)
			var boxes := 0
			for button: Button in descendants(scr, "Button"):
				var style := button.get_theme_stylebox("normal") as StyleBoxFlat
				if style != null and style.border_width_left > 0 and style.border_width_right > 0:
					boxes += 1
			check(boxes == 1, tag + ": Close is the one action box")
			if scenario == "empty" and sz.y == 1080:
				await capture("CR4_empty_" + tag)
			if scenario == "long" and sz.y == 1080:
				await capture("CR4_long_" + tag)
			if scenario == "three" and sz.y == 1080:
				var close: Button = scr.find_child("Close", true, false)
				if not shots.is_empty():
					Input.warp_mouse(close.get_global_rect().get_center())
				await capture("CR4_close_hover_" + tag)
				if not shots.is_empty():
					Input.warp_mouse(Vector2(root.size.x - 4, root.size.y - 4))
			if scenario == "three" or scenario == "empty":
				for i in scr.TABS.size():
					var key := InputEventKey.new()
					key.pressed = true
					key.keycode = KEY_1 + i
					scr._unhandled_input(key)
					await settle()
					check(scr.tab == scr.TABS[i][0], tag + ": tab key " + str(i + 1))
					if scenario == "three" and scr.tab == "chronicle":
						check(descendants(scr.body, "Label").any(func(l): return "Holder of the Anchorage" in l.text)
							and not descendants(scr.body, "Button").any(func(b): return b.text in ["Flying it", "Not flying it"]),
							tag + ": earned arc title remains visible and saved paint has no toggle")
					geometry(scr, tag + " " + scr.tab)
					if scenario == "three" and sz.y == 1080 and i > 0:
						await capture("CR4_" + scr.tab + "_" + tag)
			check(var_to_bytes(s.career.P) == before and var_to_bytes(s.C.RUN) == run_before and var_to_bytes(s.C.META) == meta_before, tag + ": opening and browsing leaves profile, run and meta unchanged")
			check(not FileAccess.file_exists(s.career.save_path), tag + ": drawing never writes a save")
			var closed := [false]
			scr.closed.connect(func(): closed[0] = true)
			scr._close()
			await settle()
			check(closed[0] and not is_instance_valid(scr), tag + ": Close emits and frees")
		# The exact CR4 mockup roster, using real data names for its two unknown Ashfall rows.
		s.ADM.vex.n = "Admiral Roderic Vex"
		s.ADM = s.ADM.duplicate()
		for id in s.ADM.keys():
			if s.admiral_fac(id) not in ["voidsworn", "hegemony", "corsair"]:
				s.ADM.erase(id)
		s.career.P = profile()
		var reference = s.open_career()
		await settle()
		if sz.y != 1440:
			await capture("CR4_reference_" + tag)
		print("CR4 layout: body=", reference.body.size, " available=", reference.scroll.size, " heroes=", reference.body.get_node("Heroes").size, " unserved=", reference.body.get_node("Unserved").size)
		check(reference.scroll.get_v_scroll_bar().max_value <= reference.scroll.size.y + 1, tag + ": twelve-admiral CR4 profile fits without scrolling")
		reference._close()
		s.queue_free()
		await settle()
	print("career honours: %d checks failed" % fails)
	quit(1 if fails else 0)
