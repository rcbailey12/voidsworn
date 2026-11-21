extends SceneTree
## Issue 1203. Run with --headless --path godot --script res://render/test/parked_thrusters_check.gd
const GUARD := preload("res://tools/ci/check_guard.gd")
const SHIP := preload("res://render/ship_view.gd")
const MAP := preload("res://ui/campaign/map3d.gd")
const SYSTEM := preload("res://ui/campaign/map3d_system.gd")
const DT := 1.0 / 60.0
const PARKED_FRAMES := 30 * 60
const MAX_BATTLE_PUFFS := 6  # at most three pairs in 30 seconds
const HULL_FIXTURE := "res://render/test/fixtures/parked_thrusters_hull.tscn"

class CampaignProbe extends RefCounted:
	var RUN := {"fac": "hegemony", "fleet": [{"uid": "lead", "tpl": "lead"}, {"uid": "escort", "tpl": "escort"}]}
	var HULLS := {"lead": {"cls": "Cruiser", "cp": 4}, "escort": {"cls": "Frigate", "cp": 2}}
	func flagshipOf() -> Dictionary: return RUN["fleet"][0]
	func ssort(items: Array, less: Callable) -> Array:
		items.sort_custom(less)
		return items
	func or_(value, fallback): return fallback if value == null else value
	func act(_action, _id) -> void: pass

class MapProbe extends MAP:
	var campaign := CampaignProbe.new()
	func _C(): return campaign
	func _ready() -> void: set_process(false)
	func _arrive(_new_sector: bool) -> void: pass
	func _refresh() -> void: pass

var failures := 0

func _init() -> void:
	GUARD.arm(self, "parked_thrusters_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", description)

func _run() -> void:
	# A cached packed hull keeps setup and the map's real token construction in the test without installed assets.
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.0, 0.25, 0.35)
	var model := MeshInstance3D.new()
	model.mesh = mesh
	var fixture := PackedScene.new()
	fixture.pack(model)
	model.free()
	fixture.take_over_path(HULL_FIXTURE)
	SHIP._manifest = {"ships": {"H9_23": {"res": HULL_FIXTURE}, "H7_23": {"res": HULL_FIXTURE}}}

	var lead = _battle_ship(1.0)
	var wing = _battle_ship(9.0)
	var battle_ships := [lead, wing]
	var first := [-1, -1]
	var battle_pilot := true
	for frame in PARKED_FRAMES:
		for i in battle_ships.size():
			var ship = battle_ships[i]
			ship._process(DT)
			battle_pilot = battle_pilot and is_equal_approx(ship.engines[0].modulate.a, 0.3)
			if first[i] < 0 and ship.jet_count > 0:
				first[i] = frame
	_check(battle_pilot, "battle fallback drive stays at pilot glow through 30 seconds of drift")
	_check(lead.jet_count <= MAX_BATTLE_PUFFS and wing.jet_count <= MAX_BATTLE_PUFFS, "each parked battle hull fires at most six puffs in 30 seconds")
	_check(first[0] >= 8 * 60 - 1 and first[1] > first[0], "the two seeded hulls wait and fire at different times")
	print("Battle parked for 30 s: puffs %d and %d, fallback glow %.2f" % [lead.jet_count, wing.jet_count, lead.engines[0].modulate.a])

	var prior_jets: int = lead.jet_count
	lead.play_glide([{"kind": "move", "p": Vector3(40.0, 0.0, 0.0), "w": 1.0}], 0.6, {"cap": 3.0})
	var peak := 0.0
	for frame in 4 * 60:
		lead._process(DT)
		peak = maxf(peak, lead.engines[0].modulate.a)
	_check(peak > 0.6 and lead.jet_count > prior_jets, "the battle ship still drives and fires movement jets along a path")
	_check(not lead.burning() and is_equal_approx(lead.engines[0].modulate.a, 0.3), "the battle drive returns to pilot after flight")

	var chart := MapProbe.new()
	root.add_child(chart)
	chart.root3 = Node3D.new()
	chart.add_child(chart.root3)
	chart.cam = Camera3D.new()
	chart.cam.position = Vector3(0.0, 60.0, 70.0)
	chart.root3.add_child(chart.cam)
	chart.sys = SYSTEM.new()
	chart.token = chart._make_token()
	chart.root3.add_child(chart.token)
	chart._make_wake()
	var map_ships := [chart.token.get_child(0).get_child(0), chart.token.get_child(1).get_child(0)]
	for frame in PARKED_FRAMES:
		chart._t += DT
		for ship in map_ships:
			if ship.is_processing():
				ship._process(DT)
		chart._update_wake()
	var parked_puffs: int = map_ships[0].jet_count + map_ships[1].jet_count
	_check(parked_puffs == 0 and chart._wake_mesh.get_surface_count() == 0, "parked map fleet emits no puffs or wake over 30 seconds")
	_check(not chart._token_glow.visible and is_zero_approx(chart._token_light.light_energy), "parked map fleet has no burn halo or cast light")
	for ship in map_ships:
		_check(is_equal_approx(ship.engines[0].modulate.a, 0.3), "every parked map engine starts at pilot glow")
	print("Map parked for 30 s: puffs %d, glow %.2f" % [parked_puffs, map_ships[0].engines[0].modulate.a])

	chart._flying = true
	chart._flight_curve = SYSTEM.route_curve(Vector3.ZERO, Vector3(40.0, 0.0, -20.0))
	for frame in 60:
		chart._t += DT
		chart._advance_flight(DT)
		chart._update_wake()
	_check(chart._token_glow.visible and chart._wake_mesh.get_surface_count() > 0, "a travelling map fleet still draws its drive and wake")
	for ship in map_ships:
		_check(is_equal_approx(ship.engines[0].modulate.a, 1.0), "every travelling map engine reaches full glow")
	for frame in 2 * 60:
		chart._t += DT
		if chart._flying:
			chart._advance_flight(DT)
		chart._update_wake()
		if not chart._flying:
			break
	chart._t += 0.21
	chart._update_wake()
	_check(not chart._flying and not chart._token_glow.visible and chart._wake_mesh.get_surface_count() == 0, "arrival cuts the drive and clears the wake within 0.21 seconds")
	for ship in map_ships:
		_check(is_equal_approx(ship.engines[0].modulate.a, 0.3), "every map engine returns to pilot glow")

	chart.free()
	lead.free()
	wing.free()
	SHIP.clear_static()
	if failures == 0:
		print("PASS: parked map and battle thrusters, pilot glow, travel and arrival")
	quit(0 if failures == 0 else 1)

func _battle_ship(phase: float):
	var ship := SHIP.new()
	root.add_child(ship)
	ship.set_process(false)
	ship.setup({"fac": "hegemony", "cls": "Cruiser", "facing": 0}, Vector3.ZERO)
	ship.bob_seed = phase
	return ship
