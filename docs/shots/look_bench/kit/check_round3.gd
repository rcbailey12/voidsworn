extends SceneTree
# R271 production-path regression: shields never create gas, hulls still do,
# and each null discharge adds exactly one ballistic head/history particle.
const FX := preload("res://fx/fx.gd")
const W := preload("res://fx/fx_weapons.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func gas_nodes(n: Node) -> int:
	var count := 1 if String(n.name).begins_with("fx_weapon_") else 0
	for child in n.get_children():
		count += gas_nodes(child)
	return count

func run() -> void:
	var cases := 0
	for quality in ["max", "low"]:
		for calm in [false, true]:
			for faction in ["voidsworn", "hegemony", "ithar", "corsair"]:
				var world := Node3D.new()
				root.add_child(world)
				var fx = FX.new()
				world.add_child(fx)
				fx.setup({"quality": quality, "reduce_flashing": calm})
				fx.manual = true
				var hull := Node3D.new()
				world.add_child(hull)
				var mi := MeshInstance3D.new()
				mi.mesh = BoxMesh.new()
				hull.add_child(mi)
				fx.add_ship("T", hull, {"faction": faction, "cls": "Cruiser", "meshes": [mi]})
				var target = fx.ship("T")
				check(target.shielded and target._shield_mat != null, "Missing real shield: " + faction)
				for look in ["torp", "doom", "gauss", "plasma", "macro", "spine", "gflak"]:
					var smoky: int = fx.pools["smk"].emitted
					var gas := gas_nodes(world)
					var pos := Vector3(0, 1, 0)
					var tg := {"p": pos, "n": Vector3.UP, "local": pos, "shield": true, "miss": false}
					# Isolate the actual shield branch from braking jets caused by hit_react.
					W._shield_impact(fx, look, 3, target, tg, fx.now, Vector3.RIGHT, 1.0, 0.65,
						look == "torp", look == "doom", look == "spine", look == "gflak")
					for frame in 60:
						fx.step(1.0 / 60.0)
					check(fx.pools["smk"].emitted == smoky, "%s/%s: smoky particle on stopped shield hit" % [faction, look])
					check(gas_nodes(world) == gas, "%s/%s: baked gas on stopped shield hit" % [faction, look])
					cases += 1
				# Control: a hull hit still throws real smoke and gas.
				var smoky: int = fx.pools["smk"].emitted
				var gas := gas_nodes(world)
				W._impact(fx, "macro", 3, null, {"p": Vector3.ZERO, "n": Vector3.UP}, fx.now,
					Color(1,0.6,0.2), Vector3.DOWN, {}, 1.0, 0.0)
				fx.step(1.0 / 60.0)
				check(gas_nodes(world) > gas, "Hull gas was removed")
				if quality != "low":
					check(fx.pools["smk"].emitted > smoky, "Hull smoke was removed")
				var count: int = fx.pools["null"].emitted
				W._gauss_wake(fx, Vector3.ZERO, Vector3(65,0,0), fx.now, Color(0.72,0.55,1.0), 1.0)
				check(fx.pools["null"].emitted == count + 1, "Null cannon adds more than one slug")
				fx.release()
				world.queue_free()
				await process_frame
	FX.clear_static()
	print("ROUND3_RECIPE_CHECK cases=%d failures=%d" % [cases, failures])
	quit(1 if failures else 0)
