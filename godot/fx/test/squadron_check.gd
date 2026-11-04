extends SceneTree
const API := preload("res://rules/battle_api.gd")
const SV := preload("res://render/ship_view.gd")
const MODELS := preload("res://render/squadron_models.gd")
const FX := preload("res://fx/fx.gd")
var failures := 0

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	seed(6701)
	var world := Node3D.new()
	root.add_child(world)
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})
	var api := API.new()
	check(api.load_rules() == "", "rules load")
	var factions := {"voidsworn": "reliquary", "hegemony": "h_vanguard", "corsair": "c_hulk", "chorus": "b_brood", "ithar": "i_carrier", "deathless": "d_harvester"}
	var matrix: Array = []
	for fac in factions:
		var scenario := {"seed": 6701, "sector": 1, "admiral": "vex", "fleet": ["reliquary", "warden"], "fac": fac, "enemies": [factions[fac]], "obj": "rout", "shape": "open", "map": "open", "dep": "line", "kind": "battle"}
		api.new_battle_scenario(scenario)
		var count := 0
		for u in api.view().units:
			if not u.squadron or u.side != "enemy": continue
			count += 1
			var expected: String = api.R.FACTIONS[fac].get("sq", "fighter")
			check(u.tpl in ["fighter", "bomber"] if fac == "voidsworn" else u.tpl == expected, fac + " launches the FACTIONS sq template")
			check(api.R.HULLS[u.tpl].cls == "Squadron", "launched hull is a squadron")
			matrix.append({"fac": fac, "tpl": u.tpl, "weapon": u.weapons[0].id})
			_exercise(world, fx, u)
		check(count == 0 if fac == "deathless" else count > 0, fac + " launch availability")
	# Both fighter and bomber remain distinct on factions that can launch either.
	for fac in ["voidsworn", "hegemony", "ithar"]:
		for tpl in ["fighter", "bomber"]:
			_exercise(world, fx, {"id": fac + tpl, "fac": fac, "cls": "Squadron", "tpl": tpl, "facing": 0})
	# A partial event or stale mechanical tpl must never produce a Chorus fighter.
	check(MODELS.kind_for("chorus", "fighter") == "spore", "Chorus launch fallback is organic")
	# Detail primitives are indexed. The pointed fuselage must still be drawn
	# after those parts are appended, not merely present in the vertex buffer.
	var mesh := MODELS.mesh_for("hegemony", "fighter")
	var arrays := mesh.surface_get_arrays(0)
	var nose_drawn := false
	for idx in arrays[Mesh.ARRAY_INDEX]:
		var v: Vector3 = arrays[Mesh.ARRAY_VERTEX][idx]
		if v.x > 0.49: nose_drawn = true
	check(nose_drawn, "fuselage triangles survive indexed detail assembly")
	print("SQUADRON_MATRIX " + JSON.stringify(matrix))
	print("SQUADRON_CHECK failures=%d" % failures)
	fx.release()
	world.queue_free()
	await process_frame
	SV.clear_static()
	FX.clear_static()
	quit(1 if failures else 0)

func _exercise(world: Node3D, fx, u: Dictionary) -> void:
	var sv := SV.new()
	world.add_child(sv)
	sv.setup(u, Vector3.ZERO)
	sv.set_process(false)
	var vis = sv.squad_visual
	check(not sv.meshes.has(vis.trails), "exhaust is excluded from hull analysis and death debris")
	var initial: Transform3D = sv.transform
	var first: Transform3D = vis.craft[0].node.transform
	var second: Transform3D = vis.craft[1].node.transform
	var bank_spread := 0.0
	for i in 45:
		sv._process(1.0 / 60.0)
		bank_spread = maxf(bank_spread, absf(vis.craft[0].node.rotation.x - vis.craft[1].node.rotation.x))
	check(sv.transform == initial, "idle animation leaves the rules position/facing fixed")
	check(vis.craft[0].node.transform != first and vis.craft[1].node.transform != second, "leader and wingmates fly at idle")
	check(bank_spread > 0.05, "craft bank independently over time")
	check(vis.trails.mesh != null, "live craft leave exhaust ribbons")
	var prior: Vector3 = vis.history[0][0].p
	sv.rotation.y += 0.7
	sv.position += Vector3(3, 1, 2)
	vis.step(0.01, false)
	check(vis.history[0][0].p == prior, "turning and translating preserve old exhaust in world space")
	var sid: String = u.id
	fx.add_ship(sid, sv, {"faction": u.fac, "cls": "Squadron", "size": 0.34, "meshes": sv.meshes})
	check(fx.ship(sid)._eng_node == null and fx.ship(sid)._trails.is_empty(), "FX adds no aggregate wing engine")
	var origin := Vector3(-20, 0, 0)
	sv.squadron_launch(origin)
	check(vis.craft[0].node.global_position.distance_to(origin) < 0.01, "launch starts at the carrier bay")
	check(not vis.craft[-1].node.visible, "launch departures are staggered")
	for i in 150: vis.step(1.0 / 60.0, false)
	check(vis.craft[-1].node.visible and vis.craft[0].node.position.length() < 10.0, "launched wing forms up")
	sv.die(false)
	sv._process(0.1)
	check(vis.trails.mesh == null, "death removes engine trails")
	fx.remove_ship(sid)
	sv.free()
