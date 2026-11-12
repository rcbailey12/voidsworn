extends SceneTree
# Issue 234 S-B wreck-cap probe: stages a worst-case wipe and logs the visual wreck list
# against the 24 cap. Built on destruction_fleet_probe.gd's ship/death setup.
# Output: WRECKPROBE_JSON=<path> or PROBE_OUT/wrecks.json

const FX := preload("res://fx/fx.gd")
const PG := preload("res://render/placeholder_guard.gd")
const CAP := 24

var out_path := ""

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	out_path = OS.get_environment("WRECKPROBE_JSON")
	if out_path == "":
		var d := OS.get_environment("PROBE_OUT")
		if d != "": out_path = d.path_join("wrecks.json")
	if out_path == "": out_path = "wrecks.json"
	DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	var vp := SubViewport.new()
	vp.size = Vector2i(640, 360)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.03, 0.045)
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60, -30, 0)
	world.add_child(light)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.look_at_from_position(Vector3(0, 100, 135), Vector3.ZERO)
	cam.current = true
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max", "shake": 0.0})
	var ships := 30
	for i in ships:
		var ship := Node3D.new()
		world.add_child(ship)
		ship.position = Vector3((i % 6 - 2.5) * 26, 0, (i / 6 - 2.0) * 24)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(18, 4, 6)
		bm.subdivide_width = 24
		bm.subdivide_height = 6
		bm.subdivide_depth = 8
		mi.mesh = bm
		ship.add_child(mi)
		var cls := "Cruiser" if i % 3 == 0 else ("Battleship" if i % 3 == 1 else "Frigate")
		var sz := 1.0 if i % 3 == 1 else (0.8 if i % 3 == 0 else 0.55)
		fx.add_ship(str(i), ship, {"faction": "corsair", "cls": cls, "size": sz, "meshes": [mi]})
	await fx.warmup(cam)
	if PG.stop_if_any():
		return
	for frame in 540:
		fx.step(1.0 / 60.0)
		await process_frame
	var counts: Array = []
	var ids_at_cap: Array = []
	var evicted: Array = []
	var max_count := 0
	for k in ships:
		fx.death(str(k), "blast")
		var ids: Array = []
		for frame in 120:
			fx.step(1.0 / 60.0)
			await process_frame
			ids = []
			for w in fx.dstate["wrecks"]: ids.append(w.get("id", "?"))
			if ids.has(str(k)): break
		var ws: Array = fx.dstate["wrecks"]
		counts.append(ws.size())
		max_count = maxi(max_count, ws.size())
		if ws.size() >= CAP:
			ids_at_cap = ids.duplicate()
	for frame in 120:
		fx.step(1.0 / 60.0)
		await process_frame
	var final_ids: Array = []
	for w in fx.dstate["wrecks"]: final_ids.append(w.get("id", "?"))
	var payload := {"deaths": ships, "cap": CAP, "counts_after_each_death": counts,
		"max_count": max_count, "cap_hit": max_count >= CAP,
		"ids_when_cap_first_reached": ids_at_cap, "final_count": final_ids.size(),
		"final_ids": final_ids,
		"note": "fx.dstate wrecks only; set-piece (terrain hulk) wrecks are world blocker visuals and never enter this list"}
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "  "))
		f.close()
	print("WRECKPROBE deaths=%d cap=%d max=%d final=%d counts=%s" % [ships, CAP, max_count, final_ids.size(), str(counts)])
	print("WRECKPROBE wrote %s" % out_path)
	fx.release()
	PG.finish(0)

func _clip(s: String, n: int) -> String:
	return s if s.length() <= n else s.substr(0, n)
