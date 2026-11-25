extends SceneTree
## Issue 2079. Restore the recorded seed-10 Battle 2 round-3 formation into the real
## battle scene. Check actual plate bounds and visible meshes. No GPU or captures.

const BattleScene = preload("res://scenes/battle/battle.tscn")
const API = preload("res://rules/battle_api.gd")
const ShipView = preload("res://render/ship_view.gd")
const Sections = preload("res://ui/battle/ship_section_state.gd")
const PlateLayer = preload("res://ui/battle/ship_plate_layer.gd")
const Plate = preload("res://ui/battle/ship_plate.gd")

var fails := 0
const TRACE := "docs/shots/player_path_1119/seed-10.jsonl"


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		fails += 1


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	create_timer(45.0, true, false, true).timeout.connect(func() -> void:
		printerr("FAIL ship plates did not finish")
		quit(1))
	var replay := _recorded_formation()
	if replay.is_empty():
		printerr("FAIL missing seed-10 Battle 2 round-3 relay trace")
		quit(1)
		return
	var api := API.new()
	var error := api.load_rules()
	if error != "":
		printerr("FAIL ", error)
		quit(1)
		return
	api.new_battle_scenario({"seed": replay["seed"], "sector": 1, "admiral": "vex",
		"fleet": ["penitent", "warden"], "fac": "corsair", "enemies": ["c_reaver", "c_raider"],
		"col": 1, "kind": "battle", "obj": "hold", "shape": "open", "map": "open", "dep": "line"})
	# Only the formation is restored. The recording does not serialize fields like weapon
	# damage or section HP, so the ship templates and later loss checks use the live rules.
	var units: Array = api.R.B["units"]
	var recorded: Array = replay["units"]
	_check(units.size() == recorded.size(), "all four recorded ships are in the relay fixture")
	for i in mini(units.size(), recorded.size()):
		var row: Array = recorded[i]
		var u: Dictionary = units[i]
		_check(u["side"] == row[1] and (u["side"] == "player" or u["t"]["n"] == row[0]), "matched recorded ship " + str(row[0]))
		u.merge({"name": row[0], "q": int(row[2]), "r": int(row[3]), "hp": float(row[4])}, true)
	api.R.B["round"] = 3
	var b = BattleScene.instantiate()
	b.external = true
	b.tips_off = true
	b.threat_on = false
	b.danger_on = false
	root.add_child(b)
	await b.begin_with(api)
	while b.warming or b.opening or b.busy:
		await process_frame
	b.select(str(units[0]["id"]))
	_round_three(b)


func _recorded_formation() -> Dictionary:
	var repo := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var file := repo.path_join(TRACE)
	var trace := FileAccess.get_file_as_string(file) if FileAccess.file_exists(file) else ""
	if trace.is_empty():
		# The PC code lanes omit docs/shots from their working trees.
		var lines := []
		if OS.execute("git", ["-C", repo, "show", "HEAD:" + TRACE], lines, true) != 0 or lines.is_empty():
			return {}
		trace = str(lines[0])
	var seed := -1
	for line in trace.split("\n", false):
		var row = JSON.parse_string(line)
		if not row is Dictionary or int(row.get("battle", 0)) != 2:
			continue
		if row["kind"] == "battle_start" and row["objective"] == "hold" and int(row["teaching_battle"]) == 2:
			seed = int(row["seed"])
		elif row["kind"] == "round" and int(row["round"]) == 3 and seed >= 0:
			return {"seed": seed, "units": row["units"]}
	return {}


func _pick_close_pair(b) -> Array[String]:
	var ids: Array[String] = []
	for id in b.views:
		var sv: ShipView = b.views[id]
		if sv.dead or not sv.visible or sv.marker == null or b.VU[id]["squadron"]:
			continue
		for other in ids:
			var ov: ShipView = b.views[other]
			if _crosses(sv, false, ov, false):
				return [id, other]
		ids.append(id)
	return []


func _crosses(a: ShipView, highlight_a: bool, b: ShipView, highlight_b: bool) -> bool:
	var ap := (a.ring if highlight_a else a.marker).global_position
	var bp := (b.ring if highlight_b else b.marker).global_position
	return Vector2(ap.x - bp.x, ap.z - bp.z).length() < a.mark_radius(highlight_a) + b.mark_radius(highlight_b) - 0.001


func _visible_crossings(b) -> int:
	var drawn: Array[ShipView] = []
	var crossings := 0
	for sv: ShipView in b.views.values():
		if sv.marker == null or not sv.is_visible_in_tree() or not (sv.marker.visible or sv.ring.visible):
			continue
		for ov in drawn:
			crossings += int(_crosses(sv, sv.ring.visible, ov, ov.ring.visible))
		drawn.append(sv)
	return crossings


func _round_three(b) -> void:
	var pair: Array[String] = _pick_close_pair(b)
	_check(not pair.is_empty() and int(b.V["round"]) == 3, "the seed-10 relay has a real round-3 footprint crossing")
	if pair.is_empty():
		quit(1)
		return
	# Freeze only the camera and inspect the same 3D views. Neither ships nor rules are repositioned.
	var lo := Vector3.INF
	var hi := -Vector3.INF
	var ships := 0
	for sv: ShipView in b.views.values():
		if not sv.dead and sv.visible:
			lo = lo.min(sv.global_position)
			hi = hi.max(sv.global_position)
			ships += 1
	var center := (lo + hi) * 0.5
	b.cam.t = center
	b.cam.r = 170.0
	b.cam.snap()
	var vs := root.get_visible_rect().size
	b._ship_plates(vs, Vector2(-10, -10), true)
	b._board_marks(true)
	var layer: PlateLayer = b.hud.plates_root
	var shown := 0
	for id in layer.plates:
		shown += int(layer.plates[id].visible)
	_check(shown == ships and layer.hidden_count == 0, "packed fleet places all %d recorded ships' plates" % shown)
	_check(layer.overlap_count() == 0 and b.hud.plate_names_under_panels() == 0, "camera 170 has no plate or HUD intersections")
	_check(_visible_crossings(b) == 0, "adjacent ships %s no longer have crossing visible marks" % str(pair))
	var selected: Plate = layer.plates.get(b.sel)
	if selected != null and selected.visible:
		_check(selected.expanded, "the selected plate is expanded")
		_check((b.views[b.sel] as ShipView).ring.visible, "the selected ship keeps its highlight")
		var normal_width := selected.size.x
		b.cam.t = (b.views[b.sel] as ShipView).visual_position()
		b.cam.r = 26.0
		b.cam.snap()
		b._ship_plates(vs, Vector2(-10, -10), true)
		_check(selected.visible and selected.size.x <= normal_width * 0.73, "camera 26 scales the selected plate toward 70 percent")
		b.cam.t = center
		b.cam.r = 235.0
		b.cam.snap()
		b._ship_plates(vs, Vector2(-10, -10), true)
		_check(not selected.collapsed and selected.expanded, "the selected plate stays expanded past camera 220")
		var standing: Plate
		for id in layer.plates:
			var p: Plate = layer.plates[id]
			if p != selected and p.visible and p.collapsed:
				standing = p
				break
		_check(standing != null, "a standing plate folds its cells into the hull strip past camera 220")
		if standing != null:
			var point := standing.get_rect().get_center()
			b._ship_plates(vs, point, true)
			_check(standing.expanded and not standing.collapsed and layer.overlap_count() == 0,
				"pointing at the actual plate expands it without overlap")
	else:
		_check(false, "round 3 has a visible selected plate")
	for id in b.views:
		var u: Dictionary = b.VU[id]
		if u["side"] == "enemy" and u["tpl"] == "c_reaver":
			b.target = id
			b.cam.r = 170
			b.cam.snap()
			b._ship_plates(vs, Vector2(-10, -10), true)
			b._board_marks(true)
			_check(layer._target.has_area() and not (b.views[id] as ShipView).marker.visible, "the targeted destroyer has brackets in place of its footprint")
			b.target = ""
			break
	_check_rail(layer, vs)
	_check_losses(b)
	quit(1 if fails else 0)


func _check_rail(layer: PlateLayer, vs: Vector2) -> void:
	# Fence off the center's entire local search area to force the rail in the real placement pass.
	var blocker := Rect2(vs.x * 0.22, 0, vs.x * 0.56, vs.y)
	var data: Dictionary = layer.plates.values()[0].state
	var anchor := vs * 0.5
	layer.set_ship("rail-probe", anchor, data, false, 170.0, 1.0, 3)
	layer.place([blocker], vs, 1.0)
	var p: Plate = layer.plates["rail-probe"]
	_check(p.visible and p.on_rail and not p.get_rect().intersects(blocker), "a plate with no local room takes an edge slot")
	layer.remove_ship("rail-probe")


func _check_losses(b) -> void:
	# Break a real ship's mid and engines through the rules. No invented HP or disabled weapon list.
	var id: String = b.sel
	var unit = b.api.unit(id)
	if unit == null or not unit.get("sec") is Dictionary:
		_check(false, "a selected ship exists for the loss check")
		return
	for key in ["mid", "eng"]:
		b.api.R.damageSection(unit, key, unit["sec"][key]["max"], null)
	b._sync(b.api.view())
	var parts: Array[Dictionary] = b._plate_state[id]["sections"]
	var losses := Sections.losses(parts)
	_check(parts[1]["lost"] and parts[2]["lost"] and losses.size() == 2, "two actual lost sections produce loss cells and sentences")
	_check(not losses.is_empty() and b._panel_info()["section_losses"] == losses, "KEEL uses the same full loss sentences as the plate")
	b._refresh_ui()
	b.hud.ledger.ensure_layout()
	var drawn: Array = b.hud.ledger.items
	_check(drawn.any(func(item): return str(item["t"]).begins_with("Mid lost")),
		"the KEEL loss is drawn standing, not only in a tip")
