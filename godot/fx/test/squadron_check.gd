extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
const API := preload("res://rules/battle_api.gd")
const SV := preload("res://render/ship_view.gd")
const CRAFT := preload("res://render/squadron_craft.gd")
const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
var failures := 0
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _init() -> void:
	GUARD.arm(self, "squadron_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	var api := API.new()
	check(api.load_rules() == "", "rules load")
	api.new_battle_scenario("s1")
	var world := Node3D.new()
	root.add_child(world)
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "shake": 0.0})
	var carriers := 0
	for tpl in api.R.HULLS:
		var h: Dictionary = api.R.HULLS[tpl]
		if not h.has("hangar"): continue
		var faction: String = api.R.factionOfTpl(tpl)
		var carrier: Dictionary = api.R.makeUnit("enemy", tpl, {"fac": faction})
		var kind: String = api.R.wingKind(carrier)
		var wing: Dictionary = api.R.makeUnit("enemy", kind, {"fac": faction})
		var view := {"id": tpl, "fac": faction, "tpl": wing.tpl, "cls": "Squadron", "facing": 0}
		check(CRAFT.kind_for(view) == kind, "%s launches %s" % [tpl, kind])
		check(kind == api.R.FACTIONS[faction].get("sq") if api.R.FACTIONS[faction].has("sq") else kind in ["fighter", "bomber"], "%s matches faction sq or Crusade adaptive role" % tpl)
		carriers += 1
	check(carriers > 5, "all launch hull entries covered")
	check(api.R.FACTIONS.deathless.sq == null, "Eclipse has no craft")
	var builder := CRAFT.new()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.groups = [surface]
	builder._blade(Vector3.ZERO, Vector3.ONE, 0)
	var blade_arrays: Array = surface.commit_to_arrays()
	check(blade_arrays[Mesh.ARRAY_INDEX].size() == 24, "all faceted faces are indexed")
	for j in blade_arrays[Mesh.ARRAY_VERTEX].size():
		check(blade_arrays[Mesh.ARRAY_NORMAL][j].dot(blade_arrays[Mesh.ARRAY_VERTEX][j]) > 0.0, "faceted normals face outward")
	for faction in api.R.FACTIONS:
		if faction == "deathless": continue
		for kind in ["fighter", "bomber", "spore"]:
			var unit := {"id": faction + kind, "fac": faction, "tpl": kind, "cls": "Squadron", "facing": 0}
			var sv := SV.new()
			world.add_child(sv)
			sv.setup(unit, Vector3.ZERO)
			sv.set_process(false)
			sv.hull.set_process(false)
			check(sv.squad_kind == ("spore" if faction == "chorus" else kind), "explicit template preserved " + faction + kind)
			check(sv.meshes.size() == (6 if faction == "chorus" else 4), "complete detailed formation")
			check(sv.meshes[0].mesh.get_surface_count() >= 3, "real mesh surfaces")
			var drawn_bow := -INF
			for surface_index in sv.meshes[0].mesh.get_surface_count():
				var arrays: Array = sv.meshes[0].mesh.surface_get_arrays(surface_index)
				for index in arrays[Mesh.ARRAY_INDEX]:
					drawn_bow = maxf(drawn_bow, arrays[Mesh.ARRAY_VERTEX][index].x)
			check(drawn_bow > 0.48, "merged mesh actually draws the faceted prow")
			var anchor := sv.position
			var start: Transform3D = sv.hull.craft[0].transform
			for frame in 60: sv.hull.step(1.0 / 60.0)
			check(not sv.hull.craft[0].transform.is_equal_approx(start), "idle craft weave and bank")
			check(sv.position == anchor, "visual motion does not move the rules anchor")
			check(not sv.hull.craft[0].rotation.is_equal_approx(sv.hull.craft[1].rotation), "formation members stagger")
			for tr in sv.hull.trails:
				check(tr.hist.size() > 2 and tr.hist.size() <= 20, "bounded stern history")
				check(tr.node.mesh.get_surface_count() == 1, "each craft has a ribbon")
			sv.position = Vector3(100, 0, 10)
			sv.rotation.y = PI / 2.0
			sv.hull.step(1.0 / 30.0)
			check(sv.hull.trails[0].hist.size() == 1, "teleport clears old trail")
			fx.add_ship(unit.id, sv, {"faction": faction, "squadron": true, "meshes": sv.meshes})
			var s = fx.ship(unit.id)
			fx._later.clear()
			check(s._eng_node == null and s._trails.is_empty(), "no formation-sized engine")
			WEAP._craft_run(fx, faction, sv.squad_kind, Vector3.ZERO, Vector3(20, 0, 0), fx.now + 0.1, 0.5, 2.4)
			fx.step(0.2)
			check(fx.dstate.craft_runs[0].node.visible, "launch craft visible on fx clock")
			fx.step(1.1)
			check(fx.dstate.craft_runs.is_empty(), "launch craft released")
			fx.launch(unit.id, unit.id)
			check(fx.dstate.craft_runs.size() == 6, "launch event streams six faction craft")
			check(fx.dstate.craft_runs[0].node.faction == faction, "launch keeps carrier faction")
			fx.step(4.0)
			var weapon := "sporeb" if faction == "chorus" or kind == "spore" else ("bombs" if kind == "bomber" else "guns")
			fx.volley_at(Vector3.ZERO, "sq", Vector3(40, 0, 0), {"faction": faction, "weapon_id": weapon, "shots": [false]})
			check(fx.dstate.craft_runs.size() == 3, "weapon pass uses three model craft")
			check(fx.dstate.craft_runs[0].node.faction == faction, "weapon pass keeps point-volley faction")
			check(fx.dstate.craft_runs[0].node.craft[0].name == faction + "_" + ("spore" if weapon == "sporeb" else kind), "weapon pass uses correct template")
			fx.step(3.0)
			check(fx.dstate.craft_runs.is_empty(), "weapon craft released")
			sv.dead = true
			sv._process(0.01)
			var stopped: Transform3D = sv.hull.craft[0].transform
			for frame in 60: sv.hull.step(1.0 / 60.0)
			check(sv.hull.craft[0].transform.is_equal_approx(stopped), "dead craft stop flying")
			check(sv.hull.trails[0].hist.is_empty(), "dead trails expire")
			fx.remove_ship(unit.id)
			sv.queue_free()
			await process_frame
	check(CRAFT.kind_for({"fac": "chorus"}) == "spore", "missing tpl cannot turn Chorus into fighters")
	check(CRAFT.kind_for({"fac": "corsair"}) == "bomber", "missing tpl respects faction default")
	print("SQUADRON_CHECK %d checks, %d failures; %d carrier hulls" % [checks, failures, carriers])
	fx.release()
	world.queue_free()
	await process_frame
	SV.clear_static()
	FX.clear_static()
	quit(0 if failures == 0 else 1)
