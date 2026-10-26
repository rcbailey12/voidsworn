extends SceneTree
# Headless smoke test of the effects library: builds two box ships per faction, fires every weapon look at shields and
# hulls, walks the damage ladder, breaks shields, kills ships with every cause, and steps the clock. Fails on any script
# error (run: godot --headless --path godot --script res://fx/test/fx_smoke.gd).

const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")

var fx
var errors := 0


func _box_ship(name: String, pos: Vector3, L: float) -> Node3D:
	var root := Node3D.new()
	root.name = name
	var model := Node3D.new()
	model.scale = Vector3(1, 1, -1)   # G2 mirrors hulls in z under the root
	root.add_child(model)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(L, L * 0.18, L * 0.3)
	mi.mesh = bm
	model.add_child(mi)
	root.position = pos
	return root


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.position = Vector3(0, 80, 120)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max"})
	var facs := ["voidsworn", "hegemony", "corsair", "chorus", "ithar", "deathless"]
	var x := -60.0
	for f in facs:
		for side in 2:
			var id := "%s_%d" % [f, side]
			var r := _box_ship(id, Vector3(x, 0, -30.0 if side == 0 else 30.0), 14.0 if side == 0 else 24.0)
			world.add_child(r)
			fx.add_ship(id, r, {"faction": f, "cls": "Cruiser", "size": 0.8 if side == 0 else 1.2, "flagship": side == 1})
		x += 24.0
	for i in 30:
		fx.step(1.0 / 60.0)
	var ids: Array = fx.ships.keys()
	var wids := ["battery", "hbattery", "autocannon", "turret", "laser", "turbo", "hturbo", "scatter", "shard", "lance", "ion",
		"pulsar", "doom", "torp", "htorp", "startorp", "flak", "spores", "gsentry", "bioplasma", "tendril", "gauss", "guns", "bombs", "sporeb"]
	var kinds := {"battery": "battery", "hbattery": "battery", "autocannon": "battery", "turret": "battery", "laser": "battery",
		"turbo": "battery", "hturbo": "battery", "scatter": "battery", "shard": "battery", "lance": "lance", "ion": "lance",
		"pulsar": "lance", "doom": "lance", "torp": "torp", "htorp": "torp", "startorp": "torp", "flak": "flak", "spores": "flak",
		"gsentry": "flak", "bioplasma": "bio", "tendril": "bio", "gauss": "gauss", "guns": "sq", "bombs": "sq", "sporeb": "sq"}
	var n := 0
	for wid in wids:
		var a: String = ids[n % ids.size()]
		var t: String = ids[(n + 7) % ids.size()]
		var r: Dictionary = fx.volley(a, kinds[wid], t, {"weapon_id": wid, "shots": [true, false, true],
			"hits": [{"shield": 5, "hull": 0, "section": "mid", "crit": false}, {"shield": 0, "hull": 8, "section": "prow", "crit": true}],
			"quad": n % 4, "pd": 1 if wid == "torp" else 0})
		if r["impacts"].size() != 3:
			push_error("volley %s returned %s" % [wid, r])
			errors += 1
		n += 1
		for i in 6:
			fx.step(1.0 / 60.0)
	for i in 240:
		fx.step(1.0 / 60.0)
	# damage ladder
	for st in 5:
		var hp: float = [1.0, 0.7, 0.5, 0.3, 0.1][st]
		fx.sync_ship("hegemony_1", {"hp": 100.0 * hp, "maxHp": 100, "sec": {"prow": {"hp": 30.0 * hp, "max": 30}, "mid": {"hp": 40.0 * hp, "max": 40},
			"eng": {"hp": 30.0 * hp, "max": 30, "broken": st == 4}}, "sh": [5, 5, 5, 5], "burning": st >= 3})
		for i in 60:
			fx.step(1.0 / 60.0)
	fx.sync_ship("hegemony_1", {"hp": 10, "maxHp": 100, "sh": [10, 10, 10, 10]})
	for q in 4:
		fx.shield_break(["voidsworn_0", "hegemony_0", "corsair_0", "ithar_0"][q], q)
	fx.tick("chorus_0", "acid")
	fx.tick("voidsworn_1", "fire")
	fx.ability("ithar_1", "blink")
	fx.launch("voidsworn_1", "hegemony_0")
	var hpt: Dictionary = fx.hull_point("voidsworn_1", "prow", Vector3(0, 0, 200))
	if hpt.is_empty():
		errors += 1
	for i in 120:
		fx.step(1.0 / 60.0)
	var causes := ["cut", "big", "flay", "melt", "dark", "tidal", "blast"]
	var k := 0
	for id in ["voidsworn_0", "hegemony_0", "corsair_1", "chorus_1", "ithar_0", "deathless_1", "hegemony_1"]:
		var d: float = fx.death(id, causes[k])
		if d <= 0.0:
			push_error("death %s returned %f" % [id, d])
			errors += 1
		k += 1
		for i in 20:
			fx.step(1.0 / 60.0)
	fx.jump_out("ithar_1")
	for i in 600:
		fx.step(1.0 / 60.0)
	fx.reduce_flashing = true
	fx.volley("voidsworn_1", "torp", "chorus_0", {"weapon_id": "torp"})
	for i in 200:
		fx.step(1.0 / 60.0)
	fx.clear_wreck("hegemony_0")
	fx.remove_ship("corsair_0")
	print("FX_SMOKE particles=%d lights=%d wrecks=%d errors=%d" % [fx.particles_emitted(), fx.active_lights(), fx.dstate["wrecks"].size(), errors])
	quit(1 if errors > 0 else 0)
