extends "res://world/world_shots.gd"
# Issue 1359: can a player tell passable debris (cover) from impassable rock, hulk and station hexes at the normal
# battle camera (cine, r 170) without Z? Same battle, same camera, one frame per edge option, then Z for reference.
# Presentation only: ships are moved for the picture, no rule state changes.
#   godot --path godot --resolution 1280x720 res://world/blocker_read_capture.tscn -- --out DIR --only boneyard
const OPTIONS := [
	["0_today", 0.0, 0.0],
	["A_solid_rim", 0.35, 0.0],
	["B_solid_and_cover", 0.35, 0.18],
	["C_solid_strong", 0.6, 0.0],
]
const SOLID := ["rock", "hulk", "station"]


func _looks(b, name: String, home: Dictionary) -> void:
	var cam = b.cam
	var T: Dictionary = b.V.get("terrain", {})
	var solid := {}
	for k in T:
		if SOLID.has(str(T[k])): solid[k] = true
	var meta = b.V.get("map", {})
	for hole in (meta.get("holes", []) if meta is Dictionary else []):
		for cell in hole.get("cells", []): solid["%d,%d" % [int(cell[0]), int(cell[1])]] = true
	# focus: the debris hex with the most solid hexes within two steps (both kinds share the frame)
	var focus := ""
	var best := -1
	for k in T:
		if str(T[k]) != "debris": continue
		var qr: PackedStringArray = str(k).split(",")
		var n := 0
		for s in solid:
			var sq: PackedStringArray = str(s).split(",")
			if b.board._hdist(int(qr[0]), int(qr[1]), int(sq[0]), int(sq[1])) <= 2: n += 1
		if n > best:
			best = n
			focus = k
	if focus == "":
		push_error("1359: no debris hex on this map")
		return
	var fq: PackedStringArray = focus.split(",")
	var fc: Vector3 = b.board.hex_world(int(fq[0]), int(fq[1]))
	# one ship of each class on open hexes around the focus, the nearest first
	var open: Array = []
	for h in b.board.cells:
		var k := "%d,%d" % [h.q, h.r]
		if T.has(k) or solid.has(k): continue
		var d: int = b.board._hdist(h.q, h.r, int(fq[0]), int(fq[1]))
		if d >= 1 and d <= 3: open.append([d, k])
	open.sort_custom(func(x, y): return x[0] < y[0] or (x[0] == y[0] and str(x[1]) < str(y[1])))
	var classes := {}
	for id in b.views:
		var view = b.views[id]
		view.set_process(false)
		var cls := str(view.u.cls)
		if classes.has(cls) or open.is_empty():
			view.visible = false
			continue
		classes[cls] = true
		var at: PackedStringArray = str(open.pop_front()[1]).split(",")
		view.position = b.board.hex_world(int(at[0]), int(at[1]))
	# The cloud copy has no built hulls (godot/gen lives on the PC): hide the ships there rather than draw grey blocks.
	if OS.get_environment("VS_1359_HIDE_SHIPS") == "1":
		for id in b.views: b.views[id].visible = false
		PG.count = 0
		PG.codes.clear()
	print("[1359] %s: focus debris %s with %d solid hexes near; classes %s" % [name, focus, best, ", ".join(classes.keys())])
	BL.set_look("cine", false)
	for opt in OPTIONS + [["Z_tactical", 0.0, 0.0]]:
		BL.tactical = opt[0] == "Z_tactical"
		b.board.apply_look(false)
		if not BL.tactical:
			for pair in [[b.board.solid_edges, opt[1]], [b.board.cover_edges, opt[2]]]:
				if pair[0] == null: continue
				(pair[0].material_override as ShaderMaterial).set_shader_parameter("gain", pair[1])
			b.board._solid_edge_gain = opt[1]
			b.board._cover_edge_gain = opt[2]
		cam.a = home["a"]
		cam.b = home["b"]
		cam.r = 170.0
		cam.t = fc
		cam.snap()
		await _settle()
		await _snap("%s_1359_%s_c170" % [name, opt[0]])
	BL.tactical = false
