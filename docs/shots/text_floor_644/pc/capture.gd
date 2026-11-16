extends SceneTree
# Issue 671 capture harness only. No game files or player saves are changed.
# godot --path godot --script <absolute capture.gd> -- <temp-output> <height> <fleet> <sky|campaign>
# sky: frontier, nebula, world, boneyard, deep, storm. Raw PNGs and measurements stay in TEMP.
const PG = preload("res://render/placeholder_guard.gd")
const SKY = preload("res://world/world_sky.gd")
const SV = preload("res://render/ship_view.gd")
var out: String
var height: int
var fleet: int
var kind: String
var rows: Array = []
var hidden: Array = []
var ledger
var data := {}

func _initialize() -> void:
	var a = OS.get_cmdline_user_args()
	out = a[0]; height = int(a[1]); fleet = int(a[2]); kind = a[3]
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()

func frames(n: int) -> void:
	for i in n: await process_frame

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(height * 16 / 9, height)
	root.content_scale_size = Vector2i.ZERO
	AudioServer.set_bus_mute(0, true)
	await frames(8)
	root.warp_mouse(Vector2(root.size.x - 4, root.size.y / 2))
	if kind == "campaign": await campaign()
	else: await battle()
	SV.clear_static()
	PG.finish(0)

func battle() -> void:
	var b = load("res://scenes/battle/battle.tscn").instantiate()
	b.external = true
	root.add_child(b)
	b.tips_off = true
	b.shake_scale = 0.0
	var biomes = {"frontier": {"rock":"stone","planet":4}, "nebula":{"rock":"crystal","planet":2}, "world":{"rock":"stone","planet":3}, "boneyard":{"rock":"iron","planet":5}, "deep":{"rock":"carbon","planet":6}, "storm":{"rock":"ice","planet":7}}
	b.args["sector_setting"] = SKY.setting(biomes[kind], "hegemony", "storm" if kind == "storm" else "open", false, 7)
	var f: Array = []
	for i in fleet: f.append(["penitent", "harrow", "warden"][i % 3])
	b.start_scenario({"seed":7, "sector":1, "admiral":"vex", "fleet":f, "fac":"hegemony", "obj":"ambush", "shape":"open", "map":"storm" if kind == "storm" else "open", "dep":"ambush", "kind":"battle", "nemesis":{"name":"Petra Valk", "title":"Fleet Marshal", "fac":"hegemony", "weak":["anchor","flank"], "adapt":["formation","pd"], "scars":0, "persona":"methodical", "traits":["artillery","gunnery"], "g":"f", "revealed":["flank"]}, "heat":["h_hunted","h_flag"]})
	var start = Time.get_ticks_msec()
	while b.api == null or b.warming or b.opening or b.busy or b.sel == "":
		await process_frame
		if Time.get_ticks_msec() - start > 120000:
			printerr("CAPTURE_TIMEOUT warm/open/selection"); quit(2); return
	await frames(90)
	# The same click handler as play: target an enemy, with no shot fired.
	for u in b.V["units"]:
		if u["side"] == "enemy" and not u["dead"] and not u["squadron"] and not b._firing_set(u["id"]).is_empty():
			b.hover = Vector2i(u["q"], u["r"])
			b._on_click()
			break
	b.hud.show_tip("", Vector2.ZERO)
	b.hud.hide_tipcard()
	b.hover = Vector2i(999,999)
	b.board.set_hover(999,999)
	b.cam.r = 170.0
	b.cam.snap()
	await frames(90)
	if PG.stop_if_any(): return
	data = {"sky":kind, "fleet_requested":fleet, "viewport":[root.size.x,root.size.y], "camera":b.cam.r, "units":[], "placeholder_count":PG.count}
	for id in b.views:
		var v = b.views[id]
		data["units"].append({"id":id,"code":v.code,"a4_kit":v.a4,"representation":"procedural wing" if "|" in v.code else "PC built hull","side":v.u["side"]})
	ledger = b.hud.ledger
	ledger.layout()
	data["fleet_fit"] = ledger.fleet_fit.duplicate(true)
	b.process_mode = Node.PROCESS_MODE_DISABLED
	await shot("battle_%d_%d_%s" % [height,fleet,kind], b.hud)
	b.queue_free()
	await frames(4)

func campaign() -> void:
	var C = load("res://campaign/campaign.gd").new()
	var err = C.load_tables()
	if err != "": printerr(err); quit(2); return
	C.persist_on = false
	var ui = load("res://ui/campaign/campaign_ui.gd").new()
	root.add_child(ui); ui.bind(C)
	await frames(4)
	load("res://rules/battle_api.gd").JSM.rnd_seed(644)
	C.UID = 1; C.RUN = null; C.B = null; C.SAVED_RUN = null; C.META = C.defaultMeta(); C.picked_admiral = "vex"; C.picked_faction = "voidsworn"
	C.run_opt = {"alt":false,"cmdAlt":false,"heat":[]}; C.ended = false
	C.titleScreen(); C.act("newRunScreen"); C.act("startRun")
	if C.page.get("kind") == "aspect": C.act("pickAspect", C.W["aspOffer"][0])
	C.act("closeModal")
	await frames(4)
	var start = Time.get_ticks_msec()
	while ui.map3d != null and ui.map3d.loading:
		await process_frame
		if Time.get_ticks_msec() - start > 180000:
			printerr("CAPTURE_TIMEOUT campaign world"); quit(2); return
	await frames(120)
	data = {"viewport":[root.size.x,root.size.y],"fleet":C.RUN["fleet"].size(),"persist_on":C.persist_on}
	await shot("campaign_map_1440", ui)
	C.act("fleetScreen", "")
	await frames(30)
	data = {"viewport":[root.size.x,root.size.y],"fleet":C.RUN["fleet"].size(),"persist_on":C.persist_on}
	await shot("campaign_fleet_1440", ui)
	ui.queue_free(); await frames(4)

func add_word(t: String, r: Rect2, fs: float, col: Color, source: String) -> void:
	if t.strip_edges() == "" or not r.intersects(Rect2(Vector2.ZERO,Vector2(root.size))): return
	rows.append({"text":t,"rect":[r.position.x,r.position.y,r.size.x,r.size.y],"px":fs,"color":[col.r,col.g,col.b,col.a],"source":source})

func collect(n: Node) -> void:
	if n is CanvasItem and not n.is_visible_in_tree(): return
	if n is Control and n.modulate.a < 0.05: return
	if n is Label or n is Button or n is RichTextLabel:
		var txt: String = n.get_parsed_text() if n is RichTextLabel else n.text
		if txt.strip_edges() != "" and n.size.x > 0 and n.size.y > 0:
			var r: Rect2 = n.get_global_rect()
			var col: Color = n.get_theme_color("default_color" if n is RichTextLabel else ("font_disabled_color" if n is Button and n.disabled else "font_color"))
			var fs: int = n.get_theme_font_size("normal_font_size" if n is RichTextLabel else "font_size")
			if n is Label:
				var tw: float = minf(r.size.x, n.get_minimum_size().x)
				if n.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT: r.position.x += r.size.x - tw
				elif n.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER: r.position.x += (r.size.x - tw) * 0.5
				r.size.x = tw
			var p = n.get_parent()
			while p != null:
				if p is Control and p.clip_contents: r = r.intersection(p.get_global_rect())
				p = p.get_parent()
			if r.size.x > 1 and r.size.y > 1:
				add_word(txt, r, fs, col, str(n.get_path()))
				if n is RichTextLabel:
					rows[-1]["bbcode"] = n.text
				rows[-1]["outline_size"] = n.get_theme_constant("outline_size")
				if n is Label or n is Button:
					# Keep the nameplate's black halo: it is the actual backing behind its fill.
					for key in ["font_color", "font_disabled_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
						hidden.append([n,key,n.has_theme_color_override(key),n.get_theme_color(key)])
						n.add_theme_color_override(key,Color(0,0,0,0))
				else:
					hidden.append([n,n.self_modulate]); n.self_modulate = Color(1,1,1,0)
	if n is Control and n.has_meta("sheet_parts"):
		var parts: Array = n.get_meta("sheet_parts")
		var k: float = height / 1080.0
		var x := 0.0
		for p in parts:
			if p.size() == 1: x += round(p[0] * k); continue
			var fs: int = round(p[2] * k)
			var w: float = ceil(p[1].get_string_size(p[0],HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x)
			add_word(p[0],Rect2(n.global_position+Vector2(x,0),Vector2(w,n.size.y)),fs,p[3],str(n.get_path()))
			x += w
		hidden.append([n,n.self_modulate]); n.self_modulate = Color(1,1,1,0)
	for ch in n.get_children(): collect(ch)

func shot(tag: String, top: Node) -> void:
	if PG.stop_if_any(): return
	await frames(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(tag+".png"))
	rows = []; hidden = []
	if ledger != null:
		for it in ledger.items:
			add_word(it["t"],ledger.item_rect(it),ledger.px(it["size"]),it["col"],"ledger")
	collect(top)
	if ledger != null:
		for it in ledger.items: it["col"] = Color(0,0,0,0)
		ledger.queue_redraw()
	await frames(2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(tag+"_background.png"))
	for h in hidden:
		if h.size() == 2: h[0].self_modulate = h[1]
		elif h[2]: h[0].add_theme_color_override(h[1],h[3])
		else: h[0].remove_theme_color_override(h[1])
	if ledger != null: ledger.mark()
	data["text"] = rows
	var f = FileAccess.open(out.path_join(tag+".json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"\t"))
	print("CAPTURE_DONE ",tag," viewport=",root.size," words=",rows.size())
