extends "res://world/world_shots.gd"
# Issue 1374 (R362): one shared line style. Same battle, same cameras, before and after: the normal view (cine) with a
# ship's move hexes, the hovered move hex, a target ring, a blocked-shot outline and the terrain and hazard edges, at the
# close (r 26), middle (r 100) and battle (r 170) cameras, then Z (the tactical grid) at r 170 and zoomed out (r 320).
# Presentation only: no rule state changes. The overlay is set straight on the board (what battle.gd's _overlay draws).
#   godot --path godot --resolution 1280x720 res://world/line_style_capture.tscn -- --out DIR --only nebula_storm --tag after
# VS_1374_HIDE_SHIPS=1 hides the ships (the cloud copy has no built hulls).


func _looks(b, name: String, home: Dictionary) -> void:
	var cam = b.cam
	var board = b.board
	var T: Dictionary = b.V.get("terrain", {})
	# focus: the open hex with the most different terrain kinds within three steps (so the edges share the frame)
	var focus := ""
	var best := -1
	for h in board.cells:
		var k := "%d,%d" % [h.q, h.r]
		if T.has(k): continue
		var kinds := {}
		for t in T:
			var tq: PackedStringArray = str(t).split(",")
			if board._hdist(h.q, h.r, int(tq[0]), int(tq[1])) <= 3: kinds[str(T[t])] = true
		var score: int = kinds.size() * 10 - board._hdist(h.q, h.r, 0, 0) / 4
		if score > best:
			best = score
			focus = k
	var fq: PackedStringArray = focus.split(",")
	var f := Vector2i(int(fq[0]), int(fq[1]))
	var fc: Vector3 = board.hex_world(f.x, f.y)
	if OS.get_environment("VS_1374_HIDE_SHIPS") == "1":
		for id in b.views: b.views[id].visible = false
		PG.count = 0
		PG.codes.clear()
	for id in b.views: b.views[id].set_process(false)
	# a ship's reach: open hexes within three steps of the focus; the planned hex two steps out; a target ring four out
	var fills := {}
	var rings := {}
	var styles := {}
	var plan := ""
	var tgt := ""
	var blocked: Array = []
	for h in board.cells:
		var k := "%d,%d" % [h.q, h.r]
		var d: int = board._hdist(h.q, h.r, f.x, f.y)
		if d >= 1 and d <= 3 and not T.has(k):
			fills[k] = board.REACH_FILL
			rings[k] = board.REACH_RING
			styles[k] = 1
			if d == 2 and plan == "": plan = k
		if d == 5 and tgt == "" and not T.has(k): tgt = k
		if d == 4 and T.has(k) and str(T[k]) in ["rock", "hulk", "station"] and blocked.size() < 2: blocked.append({"q": h.q, "r": h.r})
	if plan != "":
		fills[plan] = board.REACH_HOT
		styles[plan] = 2
	if tgt != "": rings[tgt] = b.TARGET_RING
	print("[1374] %s: focus %s, plan %s, target %s, blocked %d" % [name, focus, plan, tgt, blocked.size()])
	# the planned move's path line (battle.gd _path_dots), from the focus through the hex between to the planned hex
	if plan != "":
		var u: Dictionary = {}
		for e in b.V["units"]:
			if str(e.get("side", "")) == "player" and b.views.has(e["id"]):
				u = e.duplicate()
				break
		if not u.is_empty():
			u["q"] = f.x
			u["r"] = f.y
			var pq0: PackedStringArray = plan.split(",")
			var mid: Vector2i = board.world_hex((fc + board.hex_world(int(pq0[0]), int(pq0[1]))) * 0.5)
			b._path_dots(u, {"path": [{"q": mid.x, "r": mid.y}, {"q": int(pq0[0]), "r": int(pq0[1])}]})
	var tag := str(args.get("tag", "now"))
	BL.set_look("cine", false)
	for shot in [["1_cine", false, 26.0], ["2_cine", false, 100.0], ["3_cine", false, 170.0], ["4_Z", true, 170.0], ["5_Z", true, 320.0]]:
		BL.tactical = shot[1]
		board.apply_look(false)
		board.set_overlay(fills, rings, styles)
		board.show_blockers(blocked)
		board.set_focus(fc)
		var pq: PackedStringArray = (plan if plan != "" else focus).split(",")
		board.set_hover(int(pq[0]), int(pq[1]))
		cam.a = home["a"]
		cam.b = home["b"]
		cam.r = float(shot[2])
		cam.t = fc if shot[2] > 30.0 else board.hex_world(int(pq[0]), int(pq[1]))
		cam.snap()
		await _settle()
		await _snap("%s_1374_%s_%s_c%d" % [name, tag, shot[0], int(shot[2])])
	BL.tactical = false
