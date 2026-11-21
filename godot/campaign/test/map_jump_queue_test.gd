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
	var _jump_lbl := Label.new()
	func pick_route(id): picked = str(id)
	func px(v): return int(v * k)

class MapProbe extends Map:
	func _ready(): focus_mode = Control.FOCUS_ALL
	func _process(_delta): pass
	func _arrive(_new_sector): pass
	func _refresh(): pass

var failures := 0
func check(ok: bool, message: String):
	if not ok: failures += 1; printerr("FAIL: ", message)

func _initialize(): _run.call_deferred()
func _run():
	var m = MapProbe.new(); m.ui = UIProbe.new(); root.add_child(m)
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

	m.loading = true
	m.fly_to("b")   # what the Jump button calls (campaign_ui.gd _jump)
	check(not m._flying, "no flight starts under the loading cover")
	check(m._queued_jump == "b", "the jump pressed during loading is remembered")
	check(m.ui._jump_lbl.text == "JUMPING WHEN READY", "the Jump button says it will jump when ready")
	await process_frame
	check(not m._flying, "still no flight while loading stays on")

	m.loading = false
	await process_frame
	check(m._flying and m._flight_id == "b", "the remembered jump starts as soon as loading clears")
	check(m._queued_jump == "", "the remembered jump is used once")
	m._finish_flight()
	check(m.ui.C.acts == [["enterNode", "b"]], "the jump enters the stop once")

	# A cancelled load (run ended under the cover) drops the remembered jump.
	m.ui.C.RUN["pos"] = "a"; m.ui.C.acts.clear(); m.token.position = Vector3(10, 3, -30) + Map.TOKEN_OFF
	m.loading = true
	m.fly_to("c")
	m._queued_jump = ""; m.loading = false   # what _cancel_sector_load does
	await process_frame
	check(not m._flying and m.ui.C.acts.is_empty(), "a cancelled load forgets the jump")

	# Outside loading, Jump still flies at once.
	m.fly_to("c")
	check(m._flying and m._flight_id == "c", "a jump with no cover flies at once")
	m._finish_flight()

	print("MAP JUMP QUEUE: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	m.ui._jump_lbl.free()
	m.queue_free(); await process_frame
	quit(0 if failures == 0 else 1)
