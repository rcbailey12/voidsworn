extends SceneTree
# Headless check of world.build() on a battle view: dead star, rock, debris and nebula hexes, a planet biome, fx.well set.
# run: godot --headless --path godot --script res://world/test_world.gd

const WORLD := preload("res://world/world.gd")
const FX := preload("res://fx/fx.gd")


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var w3d := Node3D.new()
	root.add_child(w3d)
	var env := Environment.new()
	var fx = FX.new()
	w3d.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "max"})
	var hs := 10.0
	var hw := func(q: int, r: int) -> Vector3: return Vector3(hs * sqrt(3.0) * (q + r * 0.5), 0.0, 1.5 * hs * r)
	var terrain := {}
	for q in range(-6, 7):
		for r in range(-4, 5):
			terrain["%d,%d" % [q, r]] = ""
	terrain["2,1"] = "rock"
	terrain["-3,2"] = "rock"
	terrain["1,-2"] = "debris"
	terrain["-1,-3"] = "neb"
	var errs := 0
	for case in [{"map": {"deadstar": {"q": 0, "r": 0}}, "biome": {"rock": "ice", "planet": 3}},
			{"map": {}, "biome": {"rock": "crystal", "planet": 6}}, {"map": {"deadstar": null}, "biome": {}}]:
		var w = WORLD.new()
		w3d.add_child(w)
		w.build({"terrain": terrain, "map": case["map"], "units": [{"q": 3, "r": 2}, {"q": -4, "r": -1}]},
			{"biome": case["biome"], "fac": "chorus", "hex_world": hw, "environment": env, "quality": "max", "fx": fx})
		w.step(0.1)
		print("WORLD case notes: ", "; ".join(w.notes), " children=", w.get_child_count(), " well=", fx.well)
		if w.get_child_count() == 0:
			errs += 1
		w.queue_free()
		fx.well = Vector3.INF
	print("WORLD_TEST errors=%d" % errs)
	quit(errs)
