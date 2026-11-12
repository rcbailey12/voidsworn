extends SceneTree
# Issue 238, PL12: cold planet bake timing across seeds. Report only.
# For each seed it clears the shared bake cache, points VS_WORLD_CACHE at a fresh temporary folder, and bakes the two
# planet passes (albedo + ocean, then clouds, lights, relief and lava) at the shipped 4096 by 2048 max size, exactly as
# world.gd's _load_planet calls them. Prints one PL12 line per seed and writes the JSON named on the command line.
#
#   godot --path godot --script <this file> -- --out FILE [--seeds 1,2,3]
#
# Run it without --headless: the headless display has no local RenderingDevice, so world_bake.gd falls back to the slow
# raster path. The non-headless run uses the same GPU compute bake the game uses at max quality.

const BAKER := preload("res://world/world_bake.gd")
const PL := preload("res://world/world_planet.gd")
const SKY := preload("res://world/world_sky.gd")

var out := "user://planet_bake_timings.json"
var seeds: Array = [4101, 4102, 4103, 4104, 4105, 4106, 4107, 4108]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		var k := a[i]
		if k.begins_with("--"):
			k = k.substr(2)
			if i + 1 < a.size() and not a[i + 1].begins_with("--"):
				if k == "out": out = a[i + 1]
				elif k == "seeds":
					seeds = []
					for s in str(a[i + 1]).split(",", false): seeds.append(int(s))
				i += 1
		i += 1

	var svc = BAKER.service(self)
	var code: String = PL.bake_code()
	var size := Vector2i(4096, 2048)
	var rows: Array = []
	for n in seeds.size():
		var seed := int(seeds[n])
		var planet: Dictionary = SKY.PLANETS[posmod(seed, SKY.PLANETS.size())]
		var folder := OS.get_temp_dir().path_join("vs238_bake_%d_%d" % [Time.get_ticks_usec(), seed])
		DirAccess.make_dir_recursive_absolute(folder)
		OS.set_environment("VS_WORLD_CACHE", folder)
		BAKER.clear_static()
		var params := {"seed": float(seed % 997) * 0.71, "kind": int(planet["kind"]),
			"ca": planet["a"], "cb": planet["b"], "cc": planet["c"], "pass_id": 0}
		var t0 := Time.get_ticks_msec()
		var a_img: Image = await svc.bake("audit_planet_a", code, params, size, 16)
		var ta := Time.get_ticks_msec() - t0
		params["pass_id"] = 1
		t0 = Time.get_ticks_msec()
		var b_img: Image = await svc.bake("audit_planet_b", code, params, size, 16)
		var tb := Time.get_ticks_msec() - t0
		var row := {"seed": seed, "planet_index": posmod(seed, SKY.PLANETS.size()), "kind": int(planet["kind"]),
			"size": [size.x, size.y], "pass_a_ms": ta, "pass_b_ms": tb, "total_ms": ta + tb,
			"pass_a_ok": a_img != null and not a_img.is_empty(), "pass_b_ok": b_img != null and not b_img.is_empty(),
			"cache": folder}
		rows.append(row)
		print("PL12 seed=%d kind=%d pass_a_ms=%d pass_b_ms=%d total_ms=%d ok=%s" % [seed, int(planet["kind"]), ta, tb, ta + tb, str(row["pass_a_ok"] and row["pass_b_ok"])])
		DirAccess.remove_absolute(folder.path_join("audit_planet_a.png"))
		DirAccess.remove_absolute(folder.path_join("audit_planet_b.png"))
		DirAccess.remove_absolute(folder)
	var report := {"renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(),
		"cold": true, "cache_max": BAKER.CACHE_MAX, "wait_cap_ms": 20000, "rows": rows}
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ") + "\n")
	f.close()
	BAKER.clear_static()
	svc.queue_free()
	await process_frame
	print("PL12_DONE rows=%d out=%s" % [rows.size(), out])
	quit(0)
