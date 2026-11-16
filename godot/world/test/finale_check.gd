extends SceneTree
# Issue 44: preserve the actual battle baseline and keep the dawn light out of ordinary bosses.
const WORLD := preload("res://world/world.gd")
const BATTLE := preload("res://scenes/battle/battle.gd")
const API := preload("res://rules/battle_api.gd")
var failed := 0

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func check(ok: bool, why: String) -> void:
	if not ok:
		failed += 1
		printerr("finale check: FAIL ", why)

func _run() -> void:
	var api = API.new()
	check(api.load_rules() == "", "rules load")
	api.new_battle_scenario({"seed": 4110, "sector": 3, "admiral": "vex", "fleet": ["warden"],
		"fac": "deathless", "kind": "boss", "obj": "rout", "shape": "deadstar", "map": "open", "dep": "line"}, 4110)
	var battle = BATTLE.new()
	battle.api = api
	check(not battle._api_battle_finale(), "ordinary sector 3 boss must stay dark")
	battle.args["finale"] = true
	check(battle._api_battle_finale(), "run 5 final boss gets dawn")
	api.R.RUN["sector"] = 2
	check(not battle._api_battle_finale(), "run 5 earlier boss must stay dark")
	battle.free()
	var world = WORLD.new()
	root.add_child(world)
	var env := Environment.new()
	env.ambient_light_energy = 0.37
	env.ambient_light_color = Color(0.7, 0.8, 0.9)
	var hw := func(q: int, r: int) -> Vector3: return Vector3(q * 17.3205 + r * 8.66025, 0, r * 15.0)
	world.build(api.view(), {"hex_world": hw, "quality": "low", "seed": 4110})
	var original_children := world.get_child_count()
	check(world._finale_sun == null, "normal world builds no dawn light")
	world._build_dawn(env)
	check(world.get_child_count() == original_children + 1, "dawn adds only a light, never a floor or grid")
	check(world._finale_sun.light_energy == 0.0, "round 1 adds no light")
	check(is_equal_approx(env.ambient_light_energy, 0.37), "round 1 preserves supplied ambient")
	check(env.ambient_light_color == Color(0.7, 0.8, 0.9), "round 1 preserves ambient colour")
	for i in 6:
		world.finale_for_round(i + 1)
		check(world._finale_stage == i, "round advances exactly one stage")
	world.finale_for_round(90)
	check(world._finale_stage == 5, "late rounds hold full dawn")
	world.finale_for_round(1)
	check(world._finale_sun.light_energy == 0.0 and is_equal_approx(env.ambient_light_energy, 0.37), "revisiting round 1 restores baseline")
	print("finale check: ", "PASS" if failed == 0 else "FAIL", " (", failed, " failures)")
	quit(0 if failed == 0 else 1)
