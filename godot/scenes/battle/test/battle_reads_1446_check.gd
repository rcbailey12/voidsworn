extends SceneTree
# Issue 1446 (Neon player audit Nov 21, findings 2 and 3): three battle reads the board and the sheet never showed.
# Test battle s1 in the real battle scene, at the player's turn:
#   ARC-0:   the load cover draws one firing arc outline in view, using the same material and format as the live arcs.
#   ROUTE-1: an enemy whose shield power the rules routed (R246: a struck side catches more and drains the pool 30%
#            faster) shows it: the view exports route and cov, the ship tip and the attack tip say so, the KEEL readout
#            names the routed side, and that ship's bubble stays up with a rim pulse on that side only;
#   ARC-1:   an inspected enemy draws its gun arcs (the guns ready in its next turn) under it in the quiet arc line, and
#            its own reach for next turn comes from the threat worker (threat_map only_id), never the main thread;
#   REINF-1: while a reinforcement warning is up, the board marks the strip at the edge where they will come in, the hex
#            the rules would pick (edgeHex) among it; the strip goes when the warning is not up.
# Rules untouched: the test sets rules state directly (route, an event) only to stage each case.
# Prints PASS or FAIL lines; exit 0 when all pass. Pictures: -- --shots DIR (needs a window: xvfb-run with opengl3 in the
# cloud, where the hulls are placeholders and the writer refuses the picture; the PC job has the built hulls), one per item
# at camera 170 with its code name on it, stamped with the capture stage.
# Run: godot --headless --path godot --script res://scenes/battle/test/battle_reads_1446_check.gd
const BattleScene = preload("res://scenes/battle/battle.tscn")
const Prov = preload("res://tools/picture_provenance.gd")
var b
var fails := 0
var shots := ""
var label: Label
var warm_arc: WeakRef
var warm_arc_key: Array = []


func _init() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _arc_draw_key(arc: MeshInstance3D) -> Array:
	var mesh := arc.mesh as ArrayMesh
	return [arc.material_override.get_instance_id(), mesh.surface_get_format(0),
		mesh.surface_get_primitive_type(0), arc.cast_shadow]


func _note_warm_arc(node: Node) -> void:
	if node.get_parent() != b or node.name != &"WarmFiringArc":
		return
	var arc := node as MeshInstance3D
	warm_arc = weakref(arc)
	warm_arc_key = _arc_draw_key(arc)
	_check(b.warming and arc.is_visible_in_tree() and b.cam.is_position_in_frustum(arc.global_position),
		"ARC-0: the warm outline is in the camera's view under the load cover")


func _idle() -> bool:
	return b.api != null and not b.warming and not b.busy and not b.thinking and b.batches.is_empty() and b.api.phase == "player" \
		and not b._threat_busy


func _wait_idle(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while not _idle() and Time.get_ticks_msec() - t0 < ms:
		await process_frame
	for k in 6:
		await process_frame


func _frames(n: int) -> void:
	for i in n:
		await process_frame


# the rules moved under the scene: bump the version, take the new view and redraw
func _resync() -> void:
	b.api.version += 1
	b._sync(b.api.view())
	b._refresh_ui()
	b._overlay()


func _shot(code: String, what: String, at: Vector3, dist := 170.0) -> void:
	if shots == "":
		return
	b.cam.t = at
	b.cam.r = dist
	b.cam.snap()
	label.text = "%s  %s  c%d  %s" % [code, what, int(dist), Prov.capture_stage()]
	await _frames(12)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	if img.get_height() > 720:
		img.resize(roundi(img.get_width() * 720.0 / img.get_height()), 720, Image.INTERPOLATE_LANCZOS)
	var err: int = preload("res://tools/picture_provenance.gd").save_png(img, shots.path_join(code + ".png"), Prov.capture_stage())
	_check(err == OK, "shot %s saved with its stamp (error %d)" % [code, err])


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--shots":
		shots = args[1]
		DirAccess.make_dir_recursive_absolute(shots)
		DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
	b = BattleScene.instantiate()
	b.tips_off = true
	b.external = true
	root.add_child(b)
	b.args["scenario"] = "s1"
	b.args["seed"] = 1001
	node_added.connect(_note_warm_arc)
	b.start_default()
	await _wait_idle(120000)
	node_added.disconnect(_note_warm_arc)
	if not _idle():
		_check(false, "the battle reached the player's turn")
		quit(1)
		return
	_check(warm_arc != null and warm_arc.get_ref() == null, "ARC-0: the warm outline is removed before play")
	var layer := CanvasLayer.new()
	layer.layer = 60
	label = Label.new()
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_constant_override("outline_size", 6)
	label.position = Vector2(24, 140)
	layer.add_child(label)
	root.add_child(layer)
	var R = b.api.R
	# a shielded enemy and the first player ship
	var foe := ""
	var mine := ""
	for u in b.V["units"]:
		if u["side"] == "enemy" and not u["dead"] and not u["squadron"] and float(u["shMax"]) > 0 and foe == "":
			foe = str(u["id"])
		if u["side"] == "player" and not u["dead"] and not u["squadron"] and mine == "":
			mine = str(u["id"])
	_check(foe != "" and mine != "", "s1 has a shielded enemy (%s) and a ship of yours (%s)" % [foe, mine])
	if foe == "" or mine == "":
		quit(1)
		return
	_check(b.VU[foe].get("route") is Array and b.VU[foe].get("cov") is Array, "ROUTE-1: the view exports route and cov")

	# ---- ROUTE-1: route the enemy's power to every side it could be struck on, then put it in reach of your ship
	var ru = b.api.unit(mine)
	var fu = b.api.unit(foe)
	var placed := false
	for h in R.boardHexes():
		if R.hdist(h, ru) < 2 or R.hdist(h, ru) > 4 or R.blocks(R.terr(h.q, h.r)) or (R.unitAt(h.q, h.r) != null and R.unitAt(h.q, h.r) != fu):
			continue
		var q0 = fu["q"]
		var r0 = fu["r"]
		fu["q"] = h.q
		fu["r"] = h.r
		var can := false
		for wi in ru["weapons"].size():
			if R.canFire(ru, ru["weapons"][wi], fu):
				can = true
		if can:
			placed = true
			break
		fu["q"] = q0
		fu["r"] = r0
	_check(placed, "ROUTE-1: the enemy stands where your ship's guns reach it")
	fu["route"] = [1, 1, 1, 1]
	R.syncShields(fu)
	_resync()
	await _frames(3)
	b.select(mine, "pick")
	b._target(foe)
	await _frames(3)
	var ti: Dictionary = b._target_info()
	_check(bool(ti.get("struck_routed", false)) and int(ti.get("quad", -1)) >= 0, "ROUTE-1: the target sheet knows the struck side is routed (quad %d)" % int(ti.get("quad", -1)))
	b.hud.ledger.target = ti
	var tt: String = b.hud.ledger._target_tip()
	_check(tt.contains("(routed)") and tt.contains("drains the pool 30% faster"), "ROUTE-1: the attack tip names the routed side and its cost")
	var gun_tip: String = b._attack_tip(foe) if b.has_method("_attack_tip") else ""
	if gun_tip != "":
		_check(gun_tip.contains("routed to this side"), "ROUTE-1: the per-gun attack tip says the struck side is routed")
	# the ship tip and the KEEL readout, for the inspected enemy
	b.target = ""
	b.sel = ""
	b.inspect = foe
	fu["route"] = [0, 1, 0, 0]
	R.syncShields(fu)
	_resync()
	await _frames(3)
	var pi: Dictionary = b._panel_info()
	_check(str(pi.get("stats", "")).contains("Shields routed to the starboard side"), "ROUTE-1: the ship tip says which side is routed")
	_check(b.hud.ledger._routed_tag(pi.get("routed", [])) == "stbd routed", "ROUTE-1: the KEEL shield readout names the routed side")
	var fxs = b.gfx.ships.get(foe) if b.gfx != null else null
	_check(fxs != null and fxs._route_on == Vector4(0, 1, 0, 0), "ROUTE-1: the bubble pulses on the starboard side only (%s)" % (str(fxs._route_on) if fxs != null else "no fx"))
	await _frames(4)
	_check(fxs != null and fxs._shield_mi != null and fxs._shield_mi.visible, "ROUTE-1: the routed bubble stays up between hits")
	await _shot("ROUTE-1", "the routed starboard shield pulses at its rim; the sheet says stbd routed", b._pos(foe), 110.0)
	# a drained pool routes nothing
	var keep = fu["shp"]
	fu["shp"] = 0
	R.syncShields(fu)
	_resync()
	await _frames(4)
	_check(fxs != null and fxs._route_on == Vector4.ZERO and b._routed_sides(b.VU[foe]).is_empty(), "ROUTE-1: an empty pool shows no routed side")
	fu["shp"] = keep
	fu["route"] = [0, 0, 0, 0]
	R.syncShields(fu)
	_resync()

	# ---- ARC-1: the inspected enemy's arcs and its own reach next turn. Both fleet overlays off (threat map, danger
	# bands): the worker computes this one enemy's map only, never the fleet-wide scan (Artoo on PR 1622)
	b.threat_on = false
	b.danger_on = false
	b.api.version += 1
	b.inspect = foe
	b._overlay()
	await _frames(2)
	var want := {}
	for w in b.VU[foe]["weapons"]:
		if b._ready_next(w) and str(w["kind"]) != "flak" and b.ARC_SPAN.has(str(w["arc"])):
			want["%s%d" % [str(w["arc"]), int(float(w["range"]) * b.board.HW + 0.5)]] = true
	var n_arcs: int = b.efan_root.get_child_count() if b.efan_root != null and is_instance_valid(b.efan_root) else 0
	_check(n_arcs > 0 and n_arcs == want.size() and b.efan_root.get_parent() == b.views[foe], "ARC-1: the inspected enemy draws one quiet fan per gun arc and range under it (%d of %d)" % [n_arcs, want.size()])
	_check(n_arcs > 0 and warm_arc_key == _arc_draw_key(b.efan_root.get_child(0)),
		"ARC-0: the warm outline and the live arc share the material, vertex format and draw flags")
	var t0 := Time.get_ticks_msec()
	while not b._one_current() and Time.get_ticks_msec() - t0 < 30000:
		b._overlay()
		await process_frame
	_check(b._one_current() and not b._threat_one.is_empty(), "ARC-1: its own reach for next turn came from the threat worker (%d hexes)" % b._threat_one.size())
	_check(not b._threat_current() and not b._threat_next.has("dmg"), "ARC-1: with both fleet overlays off, inspecting one enemy runs no fleet-wide scan")
	b._overlay()
	_check(is_instance_valid(b.board.reach_edge), "ARC-1: its reach next turn shows as one outline round the area, not a fill")
	await _shot("ARC-1", "the inspected enemy's gun arcs and its reach next turn", b._pos(foe))
	b.inspect = ""
	b._overlay()
	await _frames(2)
	_check(b.efan_root == null, "ARC-1: the fans go when nothing is inspected")
	_check(b.board.reach_edge == null, "ARC-1: the reach outline goes when nothing is inspected")

	# ---- REINF-1: a reinforcement wave warned for round 3
	var rnd := int(R.B["round"])
	R.B["event"] = {"k": "reinf_enemy", "warnR": rnd, "r": rnd + 2}
	_resync()
	await _frames(3)
	var strip: Dictionary = b.api.arrival_strip()
	var h = R.edgeHex("enemy")
	var has_pick := false
	for c in strip.get("hexes", []):
		if h != null and int(c["q"]) == int(h.q) and int(c["r"]) == int(h.r):
			has_pick = true
	_check(str(strip.get("side", "")) == "enemy" and has_pick, "REINF-1: the strip holds the hex the rules would bring them in on (%d hexes)" % (strip.get("hexes", []) as Array).size())
	_check(b.board.arrival_edge != null and is_instance_valid(b.board.arrival_edge) and b.board.arrival_edge.mesh != null, "REINF-1: the board draws the arrival strip during the warning")
	if h != null:
		await _shot("REINF-1", "the coral strip on the edge: enemy reinforcements arrive here in round %d" % (rnd + 2), b.board.hex_world(int(h.q), int(h.r)))
	R.B["event"] = {"k": "reinf_enemy", "warnR": rnd + 1, "r": rnd + 2}
	_resync()
	await _frames(3)
	_check(b.board.arrival_edge == null, "REINF-1: no strip before the warning round")
	R.B["event"] = null
	_resync()
	print("BATTLE_READS_1446 fails=%d" % fails)
	quit(1 if fails else 0)
