extends SceneTree
# Run: copy to godot/tmp_calm_trace.gd in a checkout, then godot --headless --path godot --script res://tmp_calm_trace.gd
# on main and on the branch; the calm=true hash must match (issue 504: reduce flashing behaves exactly as on main).
# opus504 sandbox probe: under reduce flashing, trace everything the effects system makes in the worst-second staging
# (particles emitted per frame, every event light, every flipbook node's shader settings) and print one hash.
const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)
func _ship(world, fx, id, cls, size, at):
	var r := Node3D.new(); world.add_child(r); r.position = at
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(12, 3, 4); bm.subdivide_width = 11; bm.subdivide_height = 2; bm.subdivide_depth = 3; mi.mesh = bm; r.add_child(mi)
	fx.add_ship(id, r, {"faction": "voidsworn", "cls": cls, "size": size, "meshes": [mi]})
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	for calm in [true, false]:
		var world := Node3D.new(); root.add_child(world)
		var cam := Camera3D.new(); cam.fov = 45.0; world.add_child(cam); cam.position = Vector3(0, 150, 80); cam.look_at(Vector3.ZERO, Vector3.UP)
		var fx = FX.new(); world.add_child(fx); fx.manual = true
		fx.setup({"camera": cam, "quality": "high", "reduce_flashing": calm, "shake": 0.0, "unit": 1.0})
		_ship(world, fx, "CAP", "Battleship", 1.0, Vector3.ZERO)
		_ship(world, fx, "CRU", "Cruiser", 0.6, Vector3(14, 0, 6))
		for i in 72:
			fx.step(1.0 / 60.0); await process_frame
		var t0: float = fx.now
		fx.death("CAP", "big")
		var trace := PackedStringArray()
		var cru := false; var tor := false
		while fx.now < t0 + 6.0:
			if not cru and fx.now >= t0 + 0.6: cru = true; fx.death("CRU", "big")
			if not tor and fx.now >= t0 + 1.75:
				tor = true
				var Tg = fx.ship("CAP")
				WEAP._big_hit(fx, Tg, {"p": Tg.to_world(Tg.hull.c) + Vector3(0, 2, 0), "n": Vector3.UP}, fx.now, Tg.scale_k(), Color(1, 0.6, 0.3), false)
			fx.step(1.0 / 60.0)
			await process_frame
			var line := "%.4f p=%d" % [fx.now - t0, fx.particles_emitted()]
			for e in fx._lev:
				line += " L(%.3f,%.3f,%.3f,%d)" % [float(e[1]) - t0, float(e[2]), float(e[3]), int(e[5])]
			for c in fx.get_children():
				if c is MeshInstance3D and (c as MeshInstance3D).material_override is ShaderMaterial:
					var m: ShaderMaterial = c.material_override
					line += " M(%s,%s,%s,%s)" % [str(m.get_shader_parameter("lifetime")), str(m.get_shader_parameter("intensity")), str(m.get_shader_parameter("soft_flash")), str(m.get_shader_parameter("size_divisor"))]
			trace.append(line)
		var h := "\n".join(trace).md5_text()
		print("CALM_TRACE calm=%s frames=%d flashes=%d refused=%d particles=%d hash=%s" % [calm, trace.size(), fx.flash_log.size(), fx._refused.size(), fx.particles_emitted(), h])
		fx.release(); world.queue_free(); await process_frame
	quit(0)
