extends SceneTree
# Issue 441: repeatable captures of the real screen, with named stress fixtures after the real run.
# godot --path godot --script res://ui/campaign/rail_orders_shots.gd -- OUTPUT --win 1920x1080 --no-tips
const Scene = preload("res://scenes/campaign/campaign_scene.gd")
class Driver extends Scene:
	var evidence: Array = []
	var failures: Array = []
	func _ready():
		_ro_dir = OS.get_cmdline_user_args()[0]; DirAccess.make_dir_recursive_absolute(_ro_dir)
		C = CampaignScript.new(); var err = C.load_tables()
		if err != "": push_error(err); get_tree().quit(1); return
		C.persist_on = false; ui = UIScript.new(); add_child(ui); ui.bind(C); _run()
	func _fresh(seed: int):
		C.UID = 1; C.RUN = null; C.B = null; C.SAVED_RUN = null; C.META = C.defaultMeta(); C.picked_admiral = "vex"; C.picked_faction = "voidsworn"
		C.run_opt = {"alt": false, "cmdAlt": false, "heat": []}; C.ended = false; JSM.rnd_seed(seed)
		C.titleScreen(); C.act("newRunScreen"); C.act("startRun")
		if C.page.get("kind") == "aspect": C.act("pickAspect", C.W["aspOffer"][0])
		C.act("closeModal"); _ro_seen = {"fleet": true, "retreat": true}
	func _run():
		await _ro_window(); DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		_fresh(344)
		for sector in [1, 2, 3]:
			if not await _br_play(func(): return C.modal_d == null and C.page.get("kind") == "map" and C.RUN["sector"] == sector and C.RUN.get("pos") != null and int(C.findNode(C.RUN["pos"])["col"]) == 0, 700):
				failures.append("Cannot reach sector " + str(sector)); break
			await shot("sector_" + str(sector), true)
			if sector == 1:
				for r in ui._routes.duplicate():
					ui.pick_route(str(r["id"])); await _frames(4); await shot("route_" + str(r["num"]))
				ui.pick_route(str(ui._routes[0]["id"])); await _frames(4)
				var hover = InputEventMouseMotion.new(); hover.position = ui._jump_btn.get_global_rect().get_center(); hover.global_position = hover.position
				get_viewport().warp_mouse(hover.position); Input.parse_input_event(hover); await _frames(4)
				print("ACTION_HOVER ", ui._jump_btn.is_hovered()); await shot("action_hover")
				get_viewport().warp_mouse(Vector2(550, 1000)); ui._jump_btn.grab_focus(); await shot("action_focus"); ui.map3d.grab_focus()
				ui._open_overlay("dossier"); await _ro_shot("dossier"); ui._open_overlay("key"); await _ro_shot("map_key"); ui._close_overlay(); await _frames(4)
				C.act("fleetScreen", ""); await _ro_shot("fleet_purchase"); C.act("backMap", "")
		# Find an actual generated four-route fork, then reach it through the same campaign actions.
		var found = false
		for seed in range(1, 100):
			_fresh(seed)
			if C.RUN["map"]["cols"][1].size() == 4:
				found = true; print("FOUR_ROUTE_SEED ", seed); break
		if not found or not await _br_play(func(): return C.modal_d == null and C.page.get("kind") == "map" and C.RUN.get("pos") != null, 100): failures.append("No four-route fork")
		else:
			await shot("four_routes")
			for r in ui._routes.duplicate():
				ui.pick_route(str(r["id"])); await _frames(4); await shot("four_route_" + str(r["num"]))
		# Stress fixture: real longest strings, twelve ships, damaged hulls. No state is saved.
		var f = ui.GS.sheet_name(); var region = ""; var rw = -1.0
		for id in C.REGIONS:
			var w = f.get_string_size(C.REGIONS[id]["n"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 70).x
			if w > rw: rw = w; region = id
		C.RUN["map"]["region"] = region
		var longest = ""; var nw = -1.0
		for fac in C.NEM_FAC:
			var d = C.NEM_FAC[fac]
			for title in d["titles"]:
				for pre in d["pre"]:
					for post in d["post"]:
						for epithet in d["scars"]:
							var name_t = title + " " + pre + (" " if post.substr(0, 1) == post.substr(0, 1).to_upper() else "") + post + " " + epithet
							var w = f.get_string_size(name_t.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x
							if w > nw: nw = w; longest = name_t
		var hunter = C.nemRead(); hunter["title"] = ""; hunter["name"] = longest.strip_edges(); hunter["epithet"] = ""
		var ships: Array = []; _strings(C.SHIP_NAMES, ships); _strings(C.MORE_SHIP_NAMES, ships)
		ships.sort_custom(func(a, b): return f.get_string_size(a.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x > f.get_string_size(b.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x)
		var template = C.RUN["fleet"][0].duplicate(true); var original = C.RUN["fleet"].duplicate(true)
		for count in [7, 12]:
			C.RUN["fleet"] = original.duplicate(true)
			while C.RUN["fleet"].size() < count:
				var ship = template.duplicate(true); ship["uid"] = "rail-stress-" + str(C.RUN["fleet"].size()); C.RUN["fleet"].append(ship)
			for i in C.RUN["fleet"].size():
				C.RUN["fleet"][i]["name"] = ships[i % ships.size()]; C.RUN["fleet"][i]["hp"] = 98 if i == 0 else maxf(1, floor(float(template["hp"]) * 0.3))
			C.mapScreen(); await _frames(4)
			# Longest route and service names measured in the actual display face.
			var names: Array = ["Sector flagship"]
			for enc in C.ENCOUNTERS.values(): names.append(enc["n"])
			for info in C.NODE_INFO.values(): names.append(info["n"])
			names.sort_custom(func(a, b): return f.get_string_size(a.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 54).x > f.get_string_size(b.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 54).x)
			ui._routes[0]["name"] = names[0]; ui.pick_route(str(ui._routes[0]["id"])); ui._show_pick(); await _frames(5)
			await shot("long_names_fleet_" + str(count))
			if count == 12:
				var scroll = ui._rail_host.find_child("FleetScroll", true, false); scroll.scroll_vertical = 10000; await shot("fleet_overflow_scrolled")
			print("LONG_CASE ", JSON.stringify({"region": C.REGIONS[region]["n"], "nemesis": longest, "route": names[0], "ship": ships[0], "fleet": count}))
		_fresh(344)
		var first = C.RUN["fleet"][0].duplicate(true)
		while C.RUN["fleet"].size() < 7:
			var ship = first.duplicate(true); ship["uid"] = "seven-lines-" + str(C.RUN["fleet"].size()); C.RUN["fleet"].append(ship)
		for i in C.RUN["fleet"].size(): C.RUN["fleet"][i]["name"] = ships[i]
		C.mapScreen(); await _frames(5); await shot("fleet_seven_lines")
		var file = FileAccess.open(_ro_dir.path_join("readability.json"), FileAccess.WRITE); file.store_string(JSON.stringify({"states": evidence, "failures": failures}, "\t")); file.close()
		print("RAIL_CAPTURE ", "PASS" if failures.is_empty() else str(failures)); get_tree().quit(0 if failures.is_empty() else 1)
	func _strings(value, out: Array):
		if value is String: out.append(value)
		elif value is Array:
			for item in value: _strings(item, out)
		elif value is Dictionary:
			for item in value.values(): _strings(item, out)
	func shot(name: String, background := false):
		get_viewport().warp_mouse(Vector2(550, 1000)) if not name.begins_with("action_") else null
		await _ro_shot(name)
		if DisplayServer.get_name() != "headless" and not FileAccess.file_exists(_ro_dir.path_join(name + ".png")):
			push_error("Capture was not saved: " + name); get_tree().quit(1); return
		var words: Array = []; _words(ui._rail_host, words)
		var overlaps: Array = []
		for i in words.size():
			for j in range(i + 1, words.size()):
				var a = words[i]["rect"]; var b = words[j]["rect"]
				if Rect2(a[0], a[1], a[2], a[3]).grow(-1).intersects(Rect2(b[0], b[1], b[2], b[3]).grow(-1)): overlaps.append([words[i]["text"], words[j]["text"]])
		if not overlaps.is_empty(): failures.append(name + ": overlapping text " + str(overlaps))
		var fleet_scroll = ui._rail_host.find_child("FleetScroll", true, false)
		evidence.append({"fleet_visible_rows": int(round(fleet_scroll.size.y / ui.px(36))), "name": name, "scale": ui.k, "words": words, "overlaps": overlaps, "fleet_lines": C.RUN["fleet"].size()})
		if background:
			ui.page_box.hide(); await _frames(3); await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(_ro_dir.path_join(name + "_background.png")); ui.page_box.show()
	func _words(node: Node, out: Array):
		if node is Control and node.is_visible_in_tree():
			var rect = node.get_global_rect()
			var parent = node.get_parent()
			while parent != null:
				if parent is Control and parent.clip_contents: rect = rect.intersection(parent.get_global_rect())
				parent = parent.get_parent()
			if not rect.has_area(): return
			if node is Label and node.text != "":
				var fs = node.get_theme_font_size("font_size")
				out.append({"text": node.text, "size": fs / ui.k, "color": node.get_theme_color("font_color").to_html(false), "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]})
			elif node.has_meta("sheet_parts"):
				var text = ""; var colors: Array = []; var sizes: Array = []
				for p in node.get_meta("sheet_parts"):
					if p.size() > 1: text += p[0]; colors.append(p[3].to_html(false)); sizes.append(p[2])
				out.append({"text": text, "size": sizes.min(), "colors": colors, "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]})
		for child in node.get_children(): _words(child, out)
func _initialize(): root.add_child.call_deferred(Driver.new())
