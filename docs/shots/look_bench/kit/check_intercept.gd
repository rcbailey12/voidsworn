extends SceneTree
# Exercise the same volley options the real battle passes. The standing
# bench supplies the actual ShipViews, meshes and attach service.
class Fixture extends "res://bench/look_bench.gd":
	var failures := 0

	func _clear() -> void:
		if fx != null:
			for sh in fx.ships.values():
				sh.wait_damage()
				if sh.has_meta("cut_task"):
					WorkerThreadPool.wait_for_task_completion(int(sh.get_meta("cut_task")))
					sh.remove_meta("cut_task")
				if sh.has_meta("cut_job"):
					sh.remove_meta("cut_job")
		super._clear()

	func expect(value: bool, message: String) -> void:
		if not value:
			failures += 1
			push_error(message)

	func _run() -> void:
		_setup_view()
		for faction in ["voidsworn", "corsair", "ithar"]:
			var weapon := "startorp" if faction == "ithar" else "torp"
			var expected := 4 if faction == "corsair" else 1
			for mode in ["intercept", "miss", "hit"]:
				_clear()
				_make_fx()
				A = _ship("A", faction, "Cruiser", Vector3(-34, 0, 0), 0)
				T = _ship("T", "hegemony", "Cruiser", Vector3(34, 0, 0), 2)
				fx.volley("A", "torp", "T", {"weapon_id": weapon, "shots": [mode == "hit"], "pd": 0 if mode == "miss" else 1})
				var projectiles: Array = fx.dstate.get("proj", [])
				expect(projectiles.size() == expected, faction + " projectile group count")
				var nodes: Array = []
				var check_at := 0.0
				for projectile in projectiles:
					nodes.append(weakref(projectile["mesh"]))
					if mode == "intercept":
						expect(is_finite(float(projectile["dead_at"])), faction + " interception not routed from options")
						check_at = maxf(check_at, float(projectile["dead_at"]) + 0.02)
					else:
						expect(not is_finite(float(projectile["dead_at"])), faction + " normal shot incorrectly intercepted")
						check_at = maxf(check_at, lerpf(float(projectile["t0"]), float(projectile["t1"]), 0.7))
				if not is_finite(check_at):
					check_at = 1.0
				# Real update frees intercepted meshes and leaves a normal miss
				# and a rolled hit flying. Nothing edits the projectile state.
				while fx.now < check_at:
					fx.step(1.0 / 60.0)
					await get_tree().process_frame
				await get_tree().process_frame
				for ref in nodes:
					if mode == "intercept":
						expect(ref.get_ref() == null, faction + " intercepted body still exists")
					else:
						expect(ref.get_ref() != null and ref.get_ref().visible, faction + " live body disappeared")
				var gone := 0
				for ref in nodes:
					if ref.get_ref() == null:
						gone += 1
				print("INTERCEPT_BODY %s %s at %.3f: freed=%d still_alive=%d" % [faction, mode, check_at, gone, nodes.size() - gone])
		_clear()
		FX.clear_static()
		SV.clear_static()
		vp.queue_free()
		await get_tree().process_frame
		print("INTERCEPT_CHECK failures=%d" % failures)
		get_tree().quit(1 if failures else 0)

func _initialize() -> void:
	root.add_child(Fixture.new())
