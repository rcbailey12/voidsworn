extends SceneTree
# Exercise ShipView and FX together, as battle.gd does when it marks a view dead.
const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const DEATH := preload("res://fx/fx_death.gd")
var failures := 0

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	for quality in ["high", "low"]:
		for spec in [["voidsworn", "Cruiser", 0.8, "blast"], ["voidsworn", "Frigate", 0.55, "big"],
			["voidsworn", "Squadron", 0.1, "big"], ["chorus", "Bio-titan", 1.25, "big"],
			["chorus", "Frigate", 0.55, "blast"], ["voidsworn", "Cruiser", 0.8, "dark"]]:
			var world := Node3D.new()
			root.add_child(world)
			var sv := SV.new()
			world.add_child(sv)
			sv.set_process(false)
			sv.hull = Node3D.new()
			sv.add_child(sv.hull)
			sv.ring = MeshInstance3D.new()
			sv.add_child(sv.ring)
			var mesh := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(12, 3, 4)
			box.subdivide_width = 15
			box.subdivide_height = 3
			box.subdivide_depth = 4
			mesh.mesh = box
			sv.hull.add_child(mesh)
			sv.meshes = [mesh]
			sv.position = Vector3(3, 0, 4)
			var fx = FX.new()
			world.add_child(fx)
			fx.manual = true
			fx.setup({"quality": quality, "shake": 0.0})
			fx.add_ship("plane", sv, {"faction": spec[0], "cls": spec[1], "size": spec[2], "meshes": [mesh]})
			var s = fx.ship("plane")
			DEATH.precompute(fx, s)
			for frame in 30:
				fx.step(1.0 / 60.0)
				await process_frame
			fx.death("plane", spec[3])
			sv.dead = true
			# Cover death during the older movement path as well as a parked ship.
			sv.path_dur = 2.0
			var heights := {}
			for frame in 240:
				sv._process(1.0 / 60.0)
				fx.step(1.0 / 60.0)
				await process_frame
				_check(sv.position.is_equal_approx(Vector3(3, 0, 4)), "dying view stays at its battle position")
				_check(mesh.transparency == 0.0 and sv.visible, "view never fades ahead of FX replacement")
				if spec[0] == "chorus" and not s.has_meta("death_hidden"):
					_check(mesh.scale.is_equal_approx(Vector3.ONE), "Chorus skin does not deflate")
				for wreck in fx.dstate.wrecks:
					for node in wreck.nodes:
						if not heights.has(node): heights[node] = node.global_position.y
						_check(absf(node.global_position.y - float(heights[node])) < 0.01, "wreck centre stays at its split altitude")
						if node is RigidBody3D:
							_check(node.axis_lock_linear_y, "physics cannot push wrecks below the board")
			_check(s.has_meta("death_hidden"), "FX replaces the live hull")
			_check(fx.dstate.wrecks.size() == 1, "one independent aftermath per ship")
			if not fx.dstate.wrecks.is_empty():
				var w: Dictionary = fx.dstate.wrecks[0]
				if spec[0] == "chorus":
					_check(w.nodes.size() >= 4 and w.get("organic", false), "Chorus spills several real skin fragments")
					_check(w.lights.is_empty() and fx.flash_log.is_empty() and fx.dstate.debris.is_empty(), "Chorus spill has no metal fire, core flash or plates")
				elif spec[1] == "Cruiser" and spec[3] == "blast":
					# issue 462 (deaths_and_hits.md): a cruiser parts into two capped halves
					_check(w.nodes.size() == 2, "ordinary cruiser blast has two sealed halves")
				fx.remove_ship("plane")
				sv.die(false)
				_check(not sv.visible and sv.position.y == 0.0, "fallback death hides in place")
				sv.revive()
				_check(sv.visible and not sv.dead and mesh.visible, "revive restores the view after death")
				sv.die(true)
				_check(sv.visible and sv.wreck and sv.position.y == 0.0, "blocking wreck remains on the board")
				sv.queue_free()
				await process_frame
				for node in w.nodes: _check(is_instance_valid(node), "wreck survives removal of its live view")
			print("DEATH_PLANE quality=%s faction=%s class=%s cause=%s" % [quality, spec[0], spec[1], spec[3]])
			fx.release()
			world.queue_free()
			await process_frame
	SV.clear_static()
	FX.clear_static()
	print("DEATH_PLANE failures=%d" % failures)
	quit(1 if failures else 0)
