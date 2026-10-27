extends SceneTree
# Probe (headless): what the hull rebuild costs on the worker for one real ship (G2 ShipView), per weapon mark on its
# own and for every section at a damage stage at once. Runs BREACH.compute on this thread, so the numbers are the
# worker's time alone. PROBE_FAC, PROBE_CLS, PROBE_SIZE, PROBE_STAGE (default 4). Prints COST lines.

const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const BREACH := preload("res://fx/fx_breach.gd")
const LOOKS := [["lance", 3], ["plasma", 2], ["macro", 3], ["gauss", 3], ["torp", 3], ["flak", 2], ["spine", 2], ["ion", 2], ["board", 2], ["ram", 3]]


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _env(k: String, d: String) -> String:
	var v := OS.get_environment(k)
	return v if v != "" else d


func _job(s, ents: Array) -> Dictionary:
	if s._orig.is_empty():
		s._orig = BREACH.gather(s)
	var h = s.hull
	return {"surfs": s._orig, "ents": ents, "q": h.L * 2e-4, "cell": h.L / 16.0, "ovl": h.L * 0.0006, "out": {}, "hull": h}


func _tris(res: Dictionary) -> int:
	var n := 0
	for a in res.get("surfs", []):
		if a != null:
			n += (a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return n


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var sv: Node3D = SV.new()
	world.add_child(sv)
	var pf := _env("PROBE_FAC", "corsair")
	var pc := _env("PROBE_CLS", "Battle-barge")
	sv.setup({"id": "C", "fac": pf, "cls": pc, "facing": 0}, Vector3.ZERO)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": null, "quality": "max"})
	fx.add_ship("C", sv, {"faction": pf, "cls": pc, "size": float(_env("PROBE_SIZE", "1.3")), "meshes": sv.meshes, "shielded": false})
	var s = fx.ship("C")
	var h = s.hull
	print("COST hull %s %s L=%.2f tris=%d" % [pf, pc, h.L, h.tri_count])
	# the first gather and grid build, once per ship
	# the first rebuild also reads the arrays back and builds each surface's grid (once per ship): a light mark everywhere
	var t0 := Time.get_ticks_msec()
	var warm: Array = []
	for k in 6:
		var hw: Dictionary = h.random_sample(k % 3, 2.5)
		warm.append(BREACH.surface(hw["p"], hw["n"], h.L * 0.02, 9.0 + k, BREACH.S_SCORCH))
	BREACH.compute(_job(s, warm))
	print("COST first rebuild (arrays, grids) %d ms" % (Time.get_ticks_msec() - t0))
	for j in LOOKS.size():
		var hit: Dictionary = h.hit_point(h.c + Vector3(0, h.H, h.W) * 3.0, 1)
		var es: Array = BREACH.marks_for(h, LOOKS[j][0], LOOKS[j][1], hit["p"], hit["n"], -(hit["n"] as Vector3), 1.3 + j)
		# best of three (the machine may be busy with other work)
		var best := 1e9
		var res: Dictionary = {}
		for rep in 3:
			var t := Time.get_ticks_usec()
			res = BREACH.compute(_job(s, es))
			best = minf(best, (Time.get_ticks_usec() - t) / 1000.0)
		print("COST mark %s %.0f ms (tris after %d) phases %s" % [LOOKS[j][0], best, _tris(res), str(res.get("phases", []))])
	var st := int(_env("PROBE_STAGE", "4"))
	var ents: Array = []
	for i in 3:
		ents.append_array(s._plan(fx, i, st))
	var best2 := 1e9
	var res2: Dictionary = {}
	for rep in 2:
		var t2 := Time.get_ticks_usec()
		res2 = BREACH.compute(_job(s, ents))
		best2 = minf(best2, (Time.get_ticks_usec() - t2) / 1000.0)
	print("COST stage %d all sections (%d entries) %.0f ms, tris after %d, phases %s" % [st, ents.size(), best2, _tris(res2), str(res2.get("phases", []))])
	quit()
