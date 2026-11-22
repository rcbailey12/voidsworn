extends SceneTree
# Issue 1448: a Jump pressed while the map's loading cover is up is kept and flies once loading clears.
# godot --headless --path godot --script res://campaign/test/map_jump_queue_test.gd
const Map = preload("res://ui/campaign/map3d.gd")
const System = preload("res://ui/campaign/map3d_system.gd")

class LayoutSystem extends System:
	func sky_direction(_cam: Camera3D, _env: Environment) -> void: pass

class CampaignProbe extends RefCounted:
	var RUN = {"pos": "a", "fac": "voidsworn", "map": {"cols": [[{"id": "a"}]], "edges": [["a", "b"], ["a", "c"]]}}
	var page = {"kind": "map", "data": {"avail": ["b", "c"]}}
	var modal_d = null
	var acts: Array = []
	func availableNodes() -> Array:
		var next: Array = []
		for e in RUN["map"]["edges"]:
			if e[0] == RUN["pos"]: next.append(e[1])
		return next
	func jt(v) -> bool: return bool(v) if v != null else false
	func act(action, id): acts.append([action, id]); RUN["pos"] = id

class UIProbe extends RefCounted:
	var C = CampaignProbe.new()
	var k := 1.0
	var picked := ""
	var _overlay := ""
	var map3d = null
	var _jump_lbl := Label.new()
	var rebuilds := 0
	func pick_route(id): picked = str(id); _show_pick()
	func _show_pick(): rebuilds += 1; _jump_lbl.text = "JUMPING WHEN READY" if map3d != null and map3d._queued_jump else "JUMP TO " + picked.to_upper()
	# campaign_ui.gd _jump: its guards, then the map flies the current pick
	func _jump():
		if picked == "" or C.modal_d != null or _overlay != "" or not C.availableNodes().has(picked): return
		map3d.fly_to(picked)
	func px(v): return int(v * k)

class MapProbe extends Map:
	func _ready(): focus_mode = Control.FOCUS_ALL
	func _process(_delta): pass
	func _arrive(_new_sector): pass
	func _refresh(): pass

var failures := 0
var reset := func(m):
	m.ui.C.RUN["pos"] = "a"; m.ui.C.acts.clear(); m.token.position = Vector3(10, 3, -30) + Map.TOKEN_OFF
	m.ui.picked = "b"; m.ui._jump_lbl.text = "JUMP TO B"
func check(ok: bool, message: String):
	if not ok: failures += 1; printerr("FAIL: ", message)

func _initialize(): _run.call_deferred()
func _run():
	var m = MapProbe.new(); m.ui = UIProbe.new(); m.ui.map3d = m; root.add_child(m)
	m.root3 = Node3D.new(); m.add_child(m.root3)
	m.token = Node3D.new(); m.root3.add_child(m.token)
	m.cam = Camera3D.new(); m.cam.fov = 36.0; m.cam.position = Vector3(0, 60, 70); m.root3.add_child(m.cam)
	m.card = PanelContainer.new(); m.add_child(m.card)
	m.sys = LayoutSystem.new(); m._engine_mounts.assign([Vector3(-4.4, 0, 0)])
	m._make_wake()
	for id in ["a", "b", "c"]:
		m._nodes[id] = {"n": {"done": false, "type": "battle", "col": 0 if id == "a" else 1}, "pos": Vector3(10, 0, -30) if id == "a" else Vector3(26, 0, -30 if id == "b" else -14), "top": 3.0}
	for e in m.ui.C.RUN["map"]["edges"]:
		m._lanes[e[0] + ">" + e[1]] = {"a": e[0], "b": e[1], "mat": m.sys.mat("LANE_FLAT"), "mi": Node3D.new()}
		m.root3.add_child(m._lanes[e[0] + ">" + e[1]]["mi"])
	m.token.position = Vector3(10, 3, -30) + Map.TOKEN_OFF
	m.ui._jump_lbl.text = "JUMP TO B"

	m.ui.picked = "b"
	m.loading = true
	m.ui._jump()   # the Jump button
	check(not m._flying, "no flight starts under the loading cover")
	check(m._queued_jump, "the jump pressed during loading is remembered")
	check(m.ui._jump_lbl.text == "JUMPING WHEN READY", "the Jump button says it will jump when ready")
	await process_frame
	check(not m._flying, "still no flight while loading stays on")

	m.loading = false
	await process_frame
	check(m._flying and m._flight_id == "b", "the remembered jump starts as soon as loading clears")
	check(not m._queued_jump, "the remembered jump is used once")
	m._finish_flight()
	check(m.ui.C.acts == [["enterNode", "b"]], "the jump enters the stop once")

	# A pick changed while queued: the jump goes to the new pick.
	reset.call(m)
	m.ui.picked = "b"
	m.loading = true
	m.ui._jump()
	m.ui.pick_route("c")
	check(m.ui._jump_lbl.text == "JUMPING WHEN READY", "a rail rebuilt while queued still says jumping when ready")
	m.loading = false
	await process_frame
	check(m._flying and m._flight_id == "c", "a pick changed while queued flies to the new pick")
	m._finish_flight()
	check(m.ui.C.acts == [["enterNode", "c"]], "only the new pick is entered")

	# A modal opened while queued drops the jump and puts the label back.
	reset.call(m)
	m.ui.picked = "b"
	m.loading = true
	m.ui._jump()
	m.ui.C.modal_d = {"title": "event"}
	m.loading = false
	await process_frame
	check(not m._flying and m.ui.C.acts.is_empty(), "a modal opened while queued drops the jump")
	check(not m._queued_jump, "the dropped jump is forgotten")
	check(m.ui._jump_lbl.text == "JUMP TO B", "the dropped jump resets the Jump label")
	m.ui.C.modal_d = null

	# An overlay opened while queued drops it too (fly_to alone skips that check).
	reset.call(m)
	m.loading = true
	m.ui._jump()
	m.ui._overlay = "dossier"
	m.loading = false
	await process_frame
	check(not m._flying and m.ui.C.acts.is_empty(), "an overlay opened while queued drops the jump")
	check(m.ui._jump_lbl.text == "JUMP TO B", "the overlay-dropped jump resets the Jump label")
	m.ui._overlay = ""

	# A cancelled load (run ended under the cover) forgets the jump and resets the label.
	reset.call(m)
	m.loading = true
	m.ui._jump()
	var cover := CanvasLayer.new(); m.add_child(cover)
	var saved_run = m.ui.C.RUN; m.ui.C.RUN = null
	check(m._cancel_sector_load(cover), "the load cancels once the run is gone")
	m.ui.C.RUN = saved_run
	await process_frame
	check(not m._flying and m.ui.C.acts.is_empty(), "a cancelled load forgets the jump")
	check(not m._queued_jump and m.ui._jump_lbl.text == "JUMP TO B", "a cancelled load resets the Jump label")

	# Outside loading, Jump still flies at once.
	m.fly_to("c")
	check(m._flying and m._flight_id == "c", "a jump with no cover flies at once")
	m._finish_flight()

	print("MAP JUMP QUEUE: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	m.ui._jump_lbl.free()
	m.queue_free(); await process_frame
	quit(0 if failures == 0 else 1)
