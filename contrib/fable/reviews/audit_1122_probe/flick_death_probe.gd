extends SceneTree
# Fable audit probe (not part of the repo): does a hull that dies while its lights are dipped keep the dip on its death materials?
const FX := preload("res://fx/fx.gd")
var fx
var world: Node3D

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _box(size: Vector3, sub: int) -> ArrayMesh:
	var bm := BoxMesh.new()
	bm.size = size
	bm.subdivide_width = sub
	bm.subdivide_depth = maxi(sub / 3, 1)
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bm.get_mesh_arrays())
	return am

func _ship(sid: String, faction: String, pos: Vector3):
	var body := Node3D.new()
	world.add_child(body)
	body.position = pos
	var hull := MeshInstance3D.new()
	hull.name = "hull"
	hull.mesh = _box(Vector3(24, 5, 8), 17)
	body.add_child(hull)
	fx.add_ship(sid, body, {"faction": faction, "cls": "Cruiser", "size": 0.8, "meshes": [hull], "shielded": false})
	var s = fx.ship(sid)
	for i in 3:
		s._anchors["a%d" % i] = {"p": Vector3((i - 1) * 7, 2.5, 0), "n": Vector3.UP, "t": {}}
	return [s, hull]

func _state(eng: float, mid: float, prow: float) -> Dictionary:
	return {"hp": (eng + mid + prow) / 3.0, "maxHp": 100.0, "sec": {"eng": {"hp": eng, "max": 100}, "mid": {"hp": mid, "max": 100}, "prow": {"hp": prow, "max": 100}}}

func _live_flick(s) -> float:
	var lo := 1.0
	for key in s._damage_surfaces:
		var fl = (s._damage_surfaces[key][1] as ShaderMaterial).get_shader_parameter("fx_flick")
		if fl != null: lo = minf(lo, float(fl))
	return lo

func _mesh_flick(hull: MeshInstance3D) -> String:
	var out := []
	for i in hull.mesh.get_surface_count():
		var m = hull.get_surface_override_material(i)
		if m is ShaderMaterial:
			out.append("%s (uses fx_flick: %s)" % [str(m.get_shader_parameter("fx_flick")), str("fx_flick" in m.shader.code)])
		else:
			out.append("no shader material")
	return ", ".join(out)

func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})
	fx.reduce_flashing = false
	for i in 20: fx.step(0.05)
	# case A: the kill lands during a hit brownout
	for faction in ["hegemony", "voidsworn"]:
		var r: Array = _ship("a_" + faction, faction, Vector3(0, 0, 0) if faction == "hegemony" else Vector3(80, 0, 0))
		var s = r[0]
		s.sync(fx, _state(100, 100, 100))
		for i in 20: fx.step(0.05)
		s.hit_power(fx, true, 0.70, 0.6)
		fx.step(0.05)
		print("A %s: live fx_flick just before the kill = %.3f" % [faction, _live_flick(s)])
		fx.death("a_" + faction, "blast")
		for k in 12:
			fx.step(0.05)
			if k in [0, 5, 11]:
				print("A %s: %.2f s into the death, mesh material fx_flick = %s" % [faction, (k + 1) * 0.05, _mesh_flick(r[1])])
	# case B: the kill lands while a wounded hull's lights flicker
	var rb: Array = _ship("b_wounded", "hegemony", Vector3(160, 0, 0))
	var sb = rb[0]
	sb.sync(fx, _state(100, 100, 100))
	for i in 10: fx.step(0.05)
	sb.sync(fx, _state(100, 25, 25))
	for i in 10:
		if sb._dmg_task >= 0: sb.flush_damage(fx)
		fx.step(0.01)
	print("B: stages = %s" % str(sb.stage))
	var tries := 0
	while _live_flick(sb) > 0.8 and tries < 400:
		fx.step(1.0 / 60.0)
		tries += 1
	print("B: live fx_flick just before the kill = %.3f (after %d frames)" % [_live_flick(sb), tries])
	fx.death("b_wounded", "blast")
	for k in 12:
		fx.step(0.05)
		if k in [0, 5, 11]:
			print("B: %.2f s into the death, mesh material fx_flick = %s" % [(k + 1) * 0.05, _mesh_flick(rb[1])])
	quit(0)
