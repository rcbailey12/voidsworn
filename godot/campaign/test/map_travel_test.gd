extends SceneTree
# Presentation regression checks, without models, saves, or world bakes:
# godot --headless --path godot --script res://campaign/test/map_travel_test.gd
const Map = preload("res://ui/campaign/map3d.gd")
const System = preload("res://ui/campaign/map3d_system.gd")

class CampaignProbe extends RefCounted:
	var RUN = {"pos": "a", "fac": "voidsworn", "map": {"cols": [[{"id": "a"}]], "edges": [
		["a", "b"], ["a", "c"], ["b", "d"], ["c", "e"], ["d", "f"], ["e", "f"]]}}
	var page = {"kind": "map", "data": {"avail": ["b", "c"]}}
	var modal_d = null
	var acts: Array = []
	func availableNodes() -> Array:
		if RUN["pos"] == null: return RUN["map"]["cols"][0].map(func(n): return n["id"])
		var next: Array = []
		for e in RUN["map"]["edges"]:
			if e[0] == RUN["pos"]: next.append(e[1])
		return next
	func jt(v) -> bool: return bool(v) if v != null else false
	func act(action, id):
		acts.append([action, id]); RUN["pos"] = id

class UIProbe extends RefCounted:
	var C = CampaignProbe.new()
	var k := 1.0
	var picked := ""
	func pick_route(id): picked = str(id)

class MapProbe extends Map:
	var arrivals := 0
	func _ready(): focus_mode = Control.FOCUS_ALL
	func _process(_delta): pass
	func _arrive(_new_sector): arrivals += 1
	func _refresh(): pass

var failures := 0
func check(ok: bool, message: String):
	if not ok: failures += 1; printerr("FAIL: ", message)

func _initialize(): _run.call_deferred()
func _run():
	var m = MapProbe.new(); m.ui = UIProbe.new(); root.add_child(m)
	var C = m.ui.C
	m.root3 = Node3D.new(); m.add_child(m.root3)
	m.token = Node3D.new(); m.root3.add_child(m.token)
	m.cam = Camera3D.new(); m.cam.position = Vector3(0, 60, 70); m.root3.add_child(m.cam)
	m.card = PanelContainer.new(); m.add_child(m.card)
	m.sys = System.new(); m._engine_mounts.assign([Vector3(-4.4, 0, 0)])
	m._make_wake()
	for id in ["a", "b", "c", "d", "e", "f"]:
		m._nodes[id] = {"n": {"done": false, "type": "battle"}, "pos": Vector3(10, 0, -30), "top": 3.0}
	for e in C.RUN["map"]["edges"]:
		m._lanes[e[0] + ">" + e[1]] = {"a": e[0], "b": e[1], "mat": m.sys.mat("LANE_FLAT")}

	# A fork's whole abandoned branch goes dim, but a later merge stays lit.
	m._find_reachable()
	check(m._reachable.size() == 5, "both initial choices and all their descendants are reachable")
	C.RUN["pos"] = "b"; C.page["data"]["avail"] = ["d"]
	m._nodes["a"]["n"]["done"] = true; m._nodes["b"]["n"]["done"] = true
	m._find_reachable(); m._paint_lanes()
	check(m._reachable.has("d") and m._reachable.has("f") and not m._reachable.has("e"), "fork dimming preserves a shared destination")
	var ghost = m._lanes["e>f"]["mat"]
	var ahead = m._lanes["d>f"]["mat"]
	var next = m._lanes["b>d"]["mat"]
	# the Briefing build (FINDINGS R165): a next jump is the lime line, wider; a route ahead one thin pale line; a cut-off one fainter
	check(ghost.get_shader_parameter("col").a < 0.1 and ghost.get_shader_parameter("px") < 1.0, "unreachable lanes are the faintest thin line")
	check(ahead.get_shader_parameter("col").a > ghost.get_shader_parameter("col").a and ahead.get_shader_parameter("col").a < 0.3 and ahead.get_shader_parameter("px") < 1.0, "future routes stay drawn as one thin pale line, stronger than a cut-off one")
	check(next.get_shader_parameter("col").a == 1.0 and next.get_shader_parameter("px") > 1.0 and next.get_shader_parameter("col").g > next.get_shader_parameter("col").b + 0.3, "next choices are the lime line, wider")
	C.RUN["pos"] = null; m._find_reachable()
	check(m._reachable.size() == 6, "entry reaches every connected stop")

	# The rendered ribbon and flight use one finite outward curve.
	var a := Vector3(-35, 0, -12); var b := Vector3(10, 0, -30)
	var curve := System.route_curve(a, b)
	check(curve.sample_baked(0).is_equal_approx(a) and curve.sample_baked(curve.get_baked_length()).is_equal_approx(b), "curve endpoints match the stops")
	check(curve.sample_baked(curve.get_baked_length() * 0.5).distance_to(a.lerp(b, 0.5)) > 0.5, "route bends visibly")
	for quality in [0.0, 1.0]:
		m.sys.q = quality
		var ribbon: ArrayMesh = m.sys.route_ribbon(curve, 1.3, 2.4, 2.4)
		for vertex in ribbon.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]: check(vertex.is_finite(), "ribbon vertices are finite at both qualities")
	check(absf(Map._flight_distance(0.01)) < 0.0001 and absf(1.0 - Map._flight_distance(0.99)) < 0.0001, "flight accelerates and brakes from rest")
	# Every sector's visible lane and flight bend together. In the well the flagship is the closest stop to the star.
	var old_cols = C.RUN["map"]["cols"]
	C.RUN["map"]["cols"] = [[], [], [], [], [], [], []]
	for sector in [1, 2, 3]:
		C.RUN["sector"] = sector; m.sys.set_sector(sector)
		var graph_before = JSON.stringify(C.RUN["map"])
		var points: Array = []
		for col in 7: points.append(m._pos({"col": col, "y": 0.5}))
		check(JSON.stringify(C.RUN["map"]) == graph_before, "sector framing leaves the route graph unchanged")
		if sector == 3:
			for i in 6:
				for y in [0.0, 0.5, 1.0]: check(points[6].distance_to(m.sys.sun_pos) < m._pos({"col": i, "y": y}).distance_to(m.sys.sun_pos), "the last stop in the well is nearest the star at every lane height")
		C.RUN["pos"] = "a"; C.page["data"]["avail"] = ["b"]
		m.token.position = a + Map.TOKEN_OFF
		var expected = m.sys.lane_curve(a, m._nodes["b"]["pos"] + Vector3(0, 3, 0))
		m.fly_to("b")
		check(m._flight_curve.sample_baked(m._flight_curve.get_baked_length() * 0.5).is_equal_approx(expected.sample_baked(expected.get_baked_length() * 0.5)), "sector %d flight follows the rendered lane" % sector)
		m._finish_flight()
	C.RUN["map"]["cols"] = old_cols

	for fps in [30, 60, 144]:
		C.acts.clear(); C.RUN["pos"] = "a"; C.page["data"]["avail"] = ["b"]
		m.token.position = a + Map.TOKEN_OFF + Vector3(0, 3, 0)
		m.token.quaternion = Quaternion(Vector3.UP, 0.7)
		var start: Vector3 = m.token.position
		m.fly_to("b")
		check(m.token.position == start and C.acts.is_empty(), "launch has no position snap or early campaign action")
		var previous := start
		var elapsed := 0.0
		while m._flying and elapsed < 3.0:
			m._t += 1.0 / fps; elapsed += 1.0 / fps
			m._advance_flight(1.0 / fps); m._update_wake()
			check(m.token.position.distance_to(previous) < 3.0, "flight has no jump at %d fps" % fps)
			check(m.token.basis.is_finite(), "flight orientation stays finite")
			previous = m.token.position
		check(absf(elapsed - Map.FLIGHT_SECONDS) <= 1.1 / fps, "hop lasts 2.4 seconds at %d fps" % fps)
		check(C.acts == [["enterNode", "b"]], "normal arrival enters the stop once")
		check(m.token.position.distance_to(b + Map.TOKEN_OFF + Vector3(0, 3, 0)) < 0.001, "arrival ends exactly at the stop")
		m._finish_flight()
		check(C.acts.size() == 1, "arrival cannot repeat")

	for key_skip in [false, true]:
		C.acts.clear(); C.RUN["pos"] = "a"
		m.token.position = a + Map.TOKEN_OFF
		m.fly_to("b"); m._advance_flight(0.5)
		var event: InputEvent
		if key_skip:
			var key := InputEventKey.new(); key.keycode = KEY_SPACE; key.pressed = true; event = key
		else:
			var click := InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true; event = click
		m._input(event); m._finish_flight()
		check(not m._flying and C.acts == [["enterNode", "b"]], "click and keyboard skips each enter once")
	C.acts.clear(); m.fly_to("e")
	check(not m._flying and C.acts.is_empty(), "bypassed stops cannot start travel")
	var repeat := InputEventKey.new(); repeat.keycode = KEY_SPACE; repeat.pressed = true; repeat.echo = true
	m._gui_input(repeat)
	check(not m._flying, "holding skip cannot launch another hop")
	C.modal_d = {}; m.fly_to("b")
	check(not m._flying, "a modal blocks launch")
	print("PASS: map reachability, lane states, curves, flight at 30/60/144 fps, arrival and skips" if failures == 0 else "FAIL: %d map travel checks" % failures)
	m.queue_free(); await process_frame
	quit(0 if failures == 0 else 1)
