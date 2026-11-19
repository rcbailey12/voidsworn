extends SceneTree
# Issue 368. Deterministic CPU bake; no rendering and no external assets.
# godot --headless --path godot --script res://world/nebula_noise_bake.gd
# Add -- --gas-lattice to bake the High card hash instead of the Max fog noise.
const SHADERS := preload("res://world/world_shaders.gd")
const SIDE := 128

func _initialize() -> void:
	if "--gas-lattice" in OS.get_cmdline_user_args():
		_bake_gas_lattice()
		return
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


func _bake_gas_lattice() -> void:
	const LATTICE_SIDE := 96
	const ORIGIN := Vector3(-48, -32, -48)
	var scale := _f32(float(SHADERS.HASH_SCALE))
	var bias := Vector3.ONE * float(SHADERS.HASH_BIAS)
	var volume = load("res://world/nebula_noise_data.gd").new()
	volume.side = LATTICE_SIDE
	volume.origin = ORIGIN
	for z in LATTICE_SIDE:
		var bytes := PackedByteArray()
		bytes.resize(LATTICE_SIDE * LATTICE_SIDE * 4)
		for y in LATTICE_SIDE:
			for x in LATTICE_SIDE:
				var p := (ORIGIN + Vector3(x, y, z)) * scale
				p -= p.floor()
				var q := Vector3(p.z, p.y, p.x) + bias
				# Round each step to shader precision, fusing multiply and add.
				var offset := _f32(p.z * q.z)
				offset = _f32(p.y * q.y + offset)
				offset = _f32(p.x * q.x + offset)
				p += Vector3.ONE * offset
				var value := _f32(_f32(p.x + p.y) * p.z)
				bytes.encode_float((y * LATTICE_SIDE + x) * 4, value - floorf(value))
		volume.slices.append(Image.create_from_data(LATTICE_SIDE, LATTICE_SIDE, false, Image.FORMAT_RF, bytes))
	var error := ResourceSaver.save(volume, "res://world/gas_hash_lattice.res", ResourceSaver.FLAG_COMPRESS)
	print("GAS_HASH_LATTICE 96x96x96 RF result ", error)
	quit(0 if error == OK else 1)


func _f32(value: float) -> float:
	return Vector2(value, 0.0).x
