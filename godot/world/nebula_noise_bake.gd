extends SceneTree
# Issue 368. Deterministic CPU bake; no rendering and no external assets.
# godot --headless --path godot --script res://world/nebula_noise_bake.gd
const SIDE := 128

func _initialize() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 368
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.045
	noise.fractal_octaves = 4
	var slices: Array[Image] = []
	for z in SIDE:
		var data := PackedByteArray()
		data.resize(SIDE * SIDE)
		for y in SIDE:
			for x in SIDE:
				# Blend across opposite faces, so the baked field tiles in all three axes.
				var value := 0.0
				var p := Vector3(x, y, z)
				var t := p / float(SIDE)
				for corner in 8:
					var c := Vector3(corner & 1, (corner >> 1) & 1, (corner >> 2) & 1)
					var weight := Vector3.ONE - t
					if c.x > 0: weight.x = t.x
					if c.y > 0: weight.y = t.y
					if c.z > 0: weight.z = t.z
					var q := p - c * SIDE
					value += noise.get_noise_3dv(q) * weight.x * weight.y * weight.z
				data[y * SIDE + x] = clampi(roundi((value * 0.5 + 0.5) * 255.0), 0, 255)
		slices.append(Image.create_from_data(SIDE, SIDE, false, Image.FORMAT_R8, data))
	var volume = load("res://world/nebula_noise_data.gd").new()
	volume.slices = slices
	var error := ResourceSaver.save(volume, "res://world/nebula_noise.res", ResourceSaver.FLAG_COMPRESS)
	print("NEBULA_NOISE 128x128x128 R8 seed 368 result ", error)
	quit(0 if error == OK else 1)
