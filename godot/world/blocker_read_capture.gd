extends "res://world/world_shots.gd"
# Issue 1359: can a player tell passable debris (cover) from impassable rock, hulk and station hexes at the normal
# battle camera (cine, r 170) without Z? Same battle, same camera: no hover, hover on solid, hover on debris, then Z.
# Presentation only: ships are moved for the picture, no rule state changes.
#   godot --path godot --resolution 1280x720 res://world/blocker_read_capture.tscn -- --out DIR --only boneyard
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
	if OS.get_environment("VS_1359_PROBE") == "1":
		b.board.apply_look(false)
		cam.a = home["a"]; cam.b = home["b"]; cam.r = 170.0; cam.t = fc
		cam.snap()
		await _probe(Rect2i(900, 150, 380, 220))
		return
	# Ryan's pick (Nov 20): B, shown in the normal view only on hover, always with Z
	var near_solid := ""
	var nd := 99
	for k in solid:
		var sq: PackedStringArray = str(k).split(",")
		var d: int = b.board._hdist(int(sq[0]), int(sq[1]), int(fq[0]), int(fq[1]))
		if d < nd:
			nd = d
			near_solid = k
	for shot in [["1_cine_no_hover", "", false], ["2_cine_hover_solid", near_solid, false], ["3_cine_hover_debris", focus, false], ["4_Z_grid", "", true]]:
		BL.tactical = shot[2]
		b.board.apply_look(false)
		var hq: PackedStringArray = (str(shot[1]) if shot[1] != "" else "200,200").split(",")
		b.hover = Vector2i(int(hq[0]), int(hq[1]))
		b.board.set_hover(int(hq[0]), int(hq[1]))
		cam.a = home["a"]
		cam.b = home["b"]
		cam.r = 170.0
		cam.t = fc
		cam.snap()
		await _settle()
		b.board.set_hover(int(hq[0]), int(hq[1]))
		await _snap("%s_1359_%s_c170" % [name, shot[0]])
	BL.tactical = false


# VS_1359_PROBE=1: which node draws the far lattice (Ryan, Nov 20: "random grid lines ... in the distance")? Hide each
# visible GeometryInstance3D in turn and print the ones whose hiding changes the lattice box the most.
func _probe(box: Rect2i) -> void:
	await _settle()
	await RenderingServer.frame_post_draw
	var base := get_viewport().get_texture().get_image().get_region(box)
	var rows: Array = []
	for node in get_tree().root.find_children("*", "GeometryInstance3D", true, false):
		if not (node as Node3D).is_visible_in_tree(): continue
		node.visible = false
		for k in 3: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image().get_region(box)
		node.visible = true
		var diff := 0.0
		for y in range(0, box.size.y, 4):
			for x in range(0, box.size.x, 4):
				var a := base.get_pixel(x, y)
				var c := img.get_pixel(x, y)
				diff += absf(a.r - c.r) + absf(a.g - c.g) + absf(a.b - c.b)
		if diff > 1.0: rows.append([diff, str(node.get_path()), node.get_class()])
	rows.sort_custom(func(x, y): return x[0] > y[0])
	for r in rows.slice(0, 15): print("[1359 probe] %.1f %s %s" % r)
