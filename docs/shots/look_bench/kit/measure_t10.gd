extends SceneTree
# Inspect the real broadside's submitted particles before their frame flush.
# T10_MEASURE_OUT names the output JSON, outside the checkout for scratch runs.
class Fixture extends "res://bench/look_bench.gd":
	func _run() -> void:
		_setup_view()
		A = _ship("A", "voidsworn", "Cruiser", Vector3(-34, 0, 0), 0)
		T = _ship("T", "hegemony", "Cruiser", Vector3(-18, 0, 40), 2)
		if A == null or T == null:
			return
		fx.rng.seed = 11
		var source := OS.get_environment("T10_WEAPON_SCRIPT")
		if source.is_empty():
			source = "res://fx/fx_weapons.gd"
		var r: Dictionary = load(source).volley(fx, "A", "battery", "T", {"weapon_id": "hbattery",
			"shots": [true, true, true, true, true, true, true, true], "hits": _hits(8, false, false)})
		var pool = fx.pools["stk"]
		var data: PackedFloat32Array = pool.pending
		var strokes: Array = []
		for at in range(0, data.size(), 20 * pool.vpp):
			var speed := Vector3(data[at+8], data[at+9], data[at+10]).length()
			if absf(speed - 160.0 * fx.unit) < 0.01:
				strokes.append({"t": data[at+7], "width": data[at+17], "intensity": data[at+15], "width_px": data[at+2]})
		r["strokes"] = strokes
		r["source_sha256"] = FileAccess.get_sha256(source)
		var f := FileAccess.open(OS.get_environment("T10_MEASURE_OUT"), FileAccess.WRITE)
		f.store_string(JSON.stringify(r, " "))
		f.close()
		_clear()
		FX.clear_static()
		SV.clear_static()
		vp.queue_free()
		await get_tree().process_frame
		print("T10_MEASURE strokes=%d" % strokes.size())
		get_tree().quit(0 if strokes.size() == 8 else 1)

func _initialize() -> void:
	root.add_child(Fixture.new())
